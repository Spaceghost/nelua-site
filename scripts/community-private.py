#!/usr/bin/env python3
"""Measure consented private source in memory; publish only owner-level totals.

Only the admitted default-branch Actions workflow can obtain scan tasks. The API
mints one-hour installation tokens restricted to the selected repositories.
Private source, metadata and tokens are never cached, logged or written to disk.
"""
import base64
import concurrent.futures
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import posixpath
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

ROOT = 'https://spacegho.st/nelua/community'
spec = importlib.util.spec_from_file_location('public_counter', Path(__file__).with_name('community-update.py'))
counter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(counter)


def read_json(request, maximum=4 * 1024 * 1024):
    with urllib.request.urlopen(request, timeout=40) as response:
        raw = response.read(maximum + 1)
    if len(raw) > maximum:
        raise RuntimeError('response too large')
    return json.loads(raw)


def oidc():
    url = os.environ['ACTIONS_ID_TOKEN_REQUEST_URL']
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != 'https' or not (parsed.hostname or '').endswith('.actions.githubusercontent.com'):
        raise RuntimeError('invalid Actions identity endpoint')
    url += ('&' if '?' in url else '?') + urllib.parse.urlencode({'audience': ROOT})
    request = urllib.request.Request(url, headers={'Authorization': 'Bearer ' + os.environ['ACTIONS_ID_TOKEN_REQUEST_TOKEN']})
    return read_json(request)['value']


def api(path, body=None):
    headers = {'Authorization': 'Bearer ' + oidc(), 'User-Agent': 'Mozilla/5.0 Nelua-Builders/1.0'}
    if body is not None:
        headers['Content-Type'] = 'application/json'
    request = urllib.request.Request(ROOT + '/api/refresh/' + path, headers=headers,
                                     data=json.dumps(body).encode() if body is not None else None)
    return read_json(request)


def github_client(token):
    environment = {**os.environ, 'GH_TOKEN': token, 'GH_HOST': 'github.com'}
    environment.pop('GH_DEBUG', None)
    def get(endpoint):
        result = subprocess.run(['gh', 'api', endpoint], env=environment,
                                capture_output=True, text=True, timeout=60)
        if result.returncode:
            # Command errors may contain private repository names. Never echo them.
            raise RuntimeError('private GitHub request failed')
        return json.loads(result.stdout)
    return get


def count_private(task, excluded, get):
    repos = []
    for identifier in task['repositories']:
        meta = get('repositories/' + str(identifier))
        if str(meta['owner']['id']) != task['owner']:
            raise RuntimeError('repository ownership changed')
        if not meta['private'] or meta['fork'] or meta['owner']['type'] != 'User':
            continue
        name = meta['full_name']
        branch = get('repos/' + name + '/branches/' + urllib.parse.quote(meta['default_branch'], safe=''))
        tree = get('repos/' + name + '/git/trees/' + branch['commit']['sha'] + '?recursive=1')
        if tree.get('truncated'):
            raise RuntimeError('incomplete tree')
        files = [f for f in tree.get('tree', []) if f['type'] == 'blob'
                 and f['path'].lower().endswith('.nelua')
                 and not any(part.lower() in counter.EXCLUDED_DIRS for part in f['path'].split('/')[:-1])]
        build = [f for f in tree.get('tree', []) if f['type'] == 'blob'
                 and posixpath.basename(f['path']).lower() in ('makefile', 'gnumakefile')
                 and not any(part.lower() in counter.EXCLUDED_DIRS for part in f['path'].split('/')[:-1])]
        repos.append({'name': name, 'createdAt': meta['created_at'], 'files': files, 'buildFiles': build})

    # This cache exists only inside this function and is discarded after this owner.
    memory = {}
    def blob(repo, entry, unused):
        sha = entry['sha']
        if sha not in memory:
            value = get('repos/' + repo['name'] + '/git/blobs/' + sha)
            if value.get('encoding') != 'base64' or value.get('size', 0) > 8 * 1024 * 1024:
                raise RuntimeError('unsupported source blob')
            raw = base64.b64decode(value['content'])
            actual = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
            if actual != sha:
                raise RuntimeError('source hash mismatch')
            memory[sha] = raw
        return memory[sha]
    previous_reader = counter.read_blob
    counter.read_blob = blob
    try:
        generated = set()
        for repo in repos:
            _, outputs, error = counter.find_generated(repo, None)
            if error:
                raise RuntimeError('generation evidence unavailable')
            generated.update(f['sha'] for f in repo['files'] if f['path'] in outputs)
        seen = set(excluded) | generated
        retained = set()
        totals = {'lines': 0, 'bytes': 0, 'files': 0, 'repositories': 0}
        for repo in sorted(repos, key=lambda r: (r['createdAt'], r['name'].lower())):
            has_source = False
            for entry in sorted(repo['files'], key=lambda f: f['path']):
                if entry['sha'] in seen:
                    continue
                measured = counter.source_blob(repo, entry, None)
                seen.add(entry['sha'])
                if measured.get('excluded') or measured['lines'] == 0:
                    continue
                retained.add(entry['sha'])
                for field in ('lines', 'bytes'):
                    totals[field] += measured[field]
                totals['files'] += 1
                has_source = True
            totals['repositories'] += int(has_source)
        return totals, retained
    finally:
        counter.read_blob = previous_reader
        memory.clear()


def main():
    if (os.environ.get('GITHUB_ACTIONS') != 'true'
            or os.environ.get('GITHUB_REPOSITORY') != 'Spaceghost/nelua-site'
            or os.environ.get('GITHUB_REF') != 'refs/heads/main'):
        raise RuntimeError('private counting requires the admitted Actions workflow')
    owners = api('owners')['owners']
    if not owners:
        print('No opted-in private accounts to refresh.')
        return
    snapshot = read_json(urllib.request.Request(ROOT + '/data.json?run=' + os.environ['GITHUB_RUN_ID'],
        headers={'User-Agent': 'Mozilla/5.0 Chrome/131.0.0.0 Safari/537.36'}))
    excluded = {f['blob'] for p in snapshot['people'] for r in p['repositories'] for f in r['sourceFiles']}
    excluded.update(snapshot.get('excludedGeneratedBlobs', []))
    updated = failed = 0
    # Stable owner order deduplicates private copies without revealing identities.
    for owner in owners:
        try:
            task = api('task/' + str(owner))
            totals, retained = count_private(task, excluded, github_client(task['token']))
            result = api('result', {'task': task['task'], **totals})
            if result['published']:
                excluded.update(retained)
                updated += 1
            task.clear()
        except Exception:
            failed += 1
    print(f'Private refresh: {updated} accounts updated; {failed} unavailable. No private source retained.')
    if failed:
        raise RuntimeError('one or more private collections failed; incomplete totals were not published')


if __name__ == '__main__':
    try:
        main()
    except Exception:
        print('Private refresh failed. Private source, repository names and credentials are not logged.', file=sys.stderr)
        sys.exit(1)

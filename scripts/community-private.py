#!/usr/bin/env python3
"""Measure consented private source in memory; publish only owner-level totals.

Only the admitted default-branch Actions workflow can obtain scan tasks. The API
mints one-hour installation tokens restricted to the selected repositories.
Private source, metadata and tokens are never cached, logged or written to disk.
"""
import base64
import concurrent.futures
import datetime as dt
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import posixpath
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

from community_refresh_api import ROOT, api, read_json

METRIC = 'current-authored-nelua-v1'
spec = importlib.util.spec_from_file_location('public_counter', Path(__file__).with_name('community-update.py'))
counter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(counter)


def github_client(token):
    environment = {**os.environ, 'GH_TOKEN': token, 'GH_HOST': 'github.com'}
    environment.pop('GH_DEBUG', None)
    def get(endpoint):
        for attempt in range(3):
            result = subprocess.run(['gh', 'api', endpoint], env=environment,
                                    capture_output=True, text=True, timeout=60)
            if not result.returncode:
                return json.loads(result.stdout)
            if attempt < 2 and any(code in result.stderr for code in ('502', '503', '504', 'timeout')):
                time.sleep(attempt + 1)
                continue
            # Command errors may contain private repository names. Never echo them.
            match = re.search(r'HTTP (\d+)', result.stderr)
            raise RuntimeError('private GitHub request failed' + (' (' + match.group(1) + ')' if match else ''))
    return get


def graphql_client(token):
    environment = {**os.environ, 'GH_TOKEN': token, 'GH_HOST': 'github.com'}
    environment.pop('GH_DEBUG', None)
    def blame(repo, entry):
        owner, name = repo['name'].split('/', 1)
        query = '''query($owner:String!,$name:String!,$oid:GitObjectID!,$path:String!){
          repository(owner:$owner,name:$name){object(oid:$oid){... on Commit{
            blame(path:$path){ranges{startingLine endingLine commit{oid author{user{databaseId}}}}}
          }}}
        }'''
        payload = {'query': query, 'variables': {'owner': owner, 'name': name, 'oid': repo['sha'], 'path': entry['path']}}
        for attempt in range(3):
            result = subprocess.run(['gh', 'api', 'graphql', '--input', '-'], input=json.dumps(payload),
                                    env=environment, capture_output=True, text=True, timeout=90)
            if not result.returncode:
                break
            if attempt < 2 and any(code in result.stderr for code in ('502', '503', '504', 'timeout')):
                time.sleep(attempt + 1)
                continue
            raise RuntimeError('private blame request failed')
        response = json.loads(result.stdout)
        if response.get('errors'):
            raise RuntimeError('private blame response incomplete')
        return response['data']['repository']['object']['blame']['ranges']
    return blame


def authored_source(raw, ranges, owner):
    """Count current code attributed to the owner's author ID, never committer."""
    physical = raw.split(b'\n')
    physical_count = len(physical) - int(raw.endswith(b'\n')) if raw else 0
    code = set(counter.code_line_numbers(raw.decode('utf-8-sig')))
    authored = set()
    physical_authored = set()
    unmapped = set()
    commits = set()
    next_line = 1
    for entry in ranges:
        first, last = entry['startingLine'], entry['endingLine']
        if first != next_line or last < first or last > physical_count:
            raise RuntimeError('private blame ranges incomplete')
        next_line = last + 1
        commit = entry['commit']
        user = (commit.get('author') or {}).get('user')
        if user and str(user.get('databaseId')) == str(owner):
            physical_authored.update(range(first, last + 1))
            selected = code.intersection(range(first, last + 1))
            if selected:
                authored.update(selected)
                commits.add(commit['oid'])
        elif not user:
            unmapped.update(code.intersection(range(first, last + 1)))
    if next_line != physical_count + 1:
        raise RuntimeError('private blame coverage incomplete')
    size = sum(len(physical[line - 1]) + int(line < len(physical)) for line in physical_authored)
    return {'lines': len(authored), 'bytes': size, 'unmappedLines': len(unmapped)}, commits


def count_private(task, excluded, get, blame, audit=None):
    def inspect(identifier):
        meta = get('repositories/' + str(identifier))
        if str(meta['owner']['id']) != task['owner']:
            raise RuntimeError('repository ownership changed')
        if not meta['private'] or meta['fork'] or meta['owner']['type'] != 'User':
            return None
        name = meta['full_name']
        try:
            branch = get('repos/' + name + '/branches/' + urllib.parse.quote(meta['default_branch'], safe=''))
        except RuntimeError as error:
            if meta.get('size') == 0 and str(error).endswith('(404)'):
                # An empty repository has no default branch and no source to count.
                refs = get('repos/' + name + '/branches?per_page=1')
                if not refs:
                    return None
            raise
        commit = branch['commit']
        tree_sha = commit.get('commit', {}).get('tree', {}).get('sha')
        if not tree_sha:
            tree_sha = get('repos/' + name + '/git/commits/' + commit['sha'])['tree']['sha']
        # GitHub returns 404 for the canonical empty tree, even with a valid
        # branch commit. Its object identity proves that it contains no files.
        tree = ({'tree': []} if tree_sha == hashlib.sha1(b'tree 0\0').hexdigest()
                else get('repos/' + name + '/git/trees/' + tree_sha + '?recursive=1'))
        if tree.get('truncated'):
            raise RuntimeError('incomplete tree')
        files = [f for f in tree.get('tree', []) if f['type'] == 'blob'
                 and f['path'].lower().endswith('.nelua')
                 and not any(part.lower() in counter.EXCLUDED_DIRS for part in f['path'].split('/')[:-1])]
        build = [f for f in tree.get('tree', []) if f['type'] == 'blob'
                 and posixpath.basename(f['path']).lower() in ('makefile', 'gnumakefile')
                 and any(entry['path'].startswith(posixpath.dirname(f['path']) + '/') or not posixpath.dirname(f['path']) for entry in files)
                 and not any(part.lower() in counter.EXCLUDED_DIRS for part in f['path'].split('/')[:-1])]
        return {'name': name, 'sha': branch['commit']['sha'], 'createdAt': meta['created_at'], 'files': files, 'buildFiles': build}

    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        repos = [repo for repo in pool.map(inspect, task['repositories']) if repo is not None]
    if audit is not None:
        audit['repositoriesChecked'] = len(task['repositories'])
        audit['repositoriesWithEligibleNeluaPaths'] = sum(bool(repo['files']) for repo in repos)
        print(f"Checked {len(task['repositories'])} private repositories; {audit['repositoriesWithEligibleNeluaPaths']} contain eligible Nelua paths.", flush=True)

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
        unique = {}
        for repo in repos:
            for entry in repo['files']:
                if entry['sha'] not in seen:
                    unique.setdefault(entry['sha'], (repo, entry))
        if audit is not None:
            print(f'Reading {len(unique)} unique candidate blobs in memory.', flush=True)
        with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
            for _ in pool.map(lambda pair: blob(*pair, None), unique.values()):
                pass
        retained = set()
        totals = {'lines': 0, 'bytes': 0, 'files': 0, 'repositories': 0}
        candidates = []
        candidate_lines = 0
        for repo in sorted(repos, key=lambda r: (r['createdAt'], r['name'].lower())):
            for entry in sorted(repo['files'], key=lambda f: f['path']):
                if entry['sha'] in seen:
                    continue
                measured = counter.source_blob(repo, entry, None)
                seen.add(entry['sha'])
                if measured.get('excluded') or measured['lines'] == 0:
                    continue
                candidates.append((repo, entry))
                candidate_lines += measured['lines']
        if audit is not None:
            audit['eligibleOriginalFiles'] = len(candidates)
            audit['eligibleOriginalLines'] = candidate_lines
            print(f"Attributing {len(candidates)} unique original Nelua files to their commit authors.", flush=True)
        def ownership(pair):
            repo, entry = pair
            return authored_source(memory[entry['sha']], blame(repo, entry), task['owner'])
        counted_repos = set()
        authored_commits = set()
        unmapped_lines = 0
        with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
            for (repo, entry), (measured, commits) in zip(candidates, pool.map(ownership, candidates)):
                unmapped_lines += measured['unmappedLines']
                if not measured['lines']:
                    continue
                authored_commits.update(commits)
                retained.add(entry['sha'])
                for field in ('lines', 'bytes'):
                    totals[field] += measured[field]
                totals['files'] += 1
                counted_repos.add(repo['name'])
        totals['repositories'] = len(counted_repos)
        if audit is not None:
            audit['authoredCommitsRepresented'] = len(authored_commits)
            audit['unmappedAuthorLinesExcluded'] = unmapped_lines
            audit['otherAuthorLinesExcluded'] = candidate_lines - totals['lines'] - unmapped_lines
        return totals, retained
    finally:
        counter.read_blob = previous_reader
        memory.clear()


def audit_owned():
    """Owner-requested, in-memory check; does not publish or change consent."""
    credential = subprocess.run(['gh', 'auth', 'token'], capture_output=True, text=True, timeout=30)
    if credential.returncode or not credential.stdout.strip():
        raise RuntimeError('authenticated GitHub account required')
    token = credential.stdout.strip()
    get = github_client(token)
    user = get('user')
    repositories = []
    metadata = {}
    for page in range(1, 101):
        part = get(f'user/repos?affiliation=owner&visibility=private&per_page=100&page={page}')
        for repo in part:
            if repo['private'] and str(repo['owner']['id']) == str(user['id']) and not repo['fork']:
                repositories.append(repo['id'])
                metadata['repositories/' + str(repo['id'])] = repo
        if len(part) < 100:
            break
    else:
        raise RuntimeError('private repository inventory incomplete')
    snapshot = read_json(urllib.request.Request(ROOT + '/data.json', headers={'User-Agent': 'Mozilla/5.0 Nelua-Builders/1.0'}))
    excluded = {entry['blob'] for person in snapshot['people'] for repo in person['repositories'] for entry in repo['sourceFiles']}
    excluded.update(snapshot.get('excludedGeneratedBlobs', []))
    def cached_get(endpoint):
        return metadata[endpoint] if endpoint in metadata else get(endpoint)
    audit = {'owner': str(user['id']), 'login': user['login'],
             'metric': 'current-default-branch-code-lines-by-commit-author', 'published': False}
    totals, _ = count_private({'owner': str(user['id']), 'repositories': repositories}, excluded,
                              cached_get, graphql_client(token), audit)
    audit.update(totals)
    audit['checkedAt'] = dt.datetime.now(dt.timezone.utc).isoformat()
    print(json.dumps(audit, sort_keys=True))


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
            totals, retained = count_private(task, excluded, github_client(task['token']), graphql_client(task['token']))
            result = api('result', {'task': task['task'], 'metric': METRIC, **totals})
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
        if sys.argv[1:] == ['--audit-owned']:
            audit_owned()
        elif sys.argv[1:]:
            raise RuntimeError('unsupported arguments')
        else:
            main()
    except Exception:
        print('Private refresh failed. Private source, repository names and credentials are not logged.', file=sys.stderr)
        sys.exit(1)

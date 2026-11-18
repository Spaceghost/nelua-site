#!/usr/bin/env python3
"""Measure public default-branch Nelua source; Python stdlib plus authenticated gh.

Example:
  python3 scripts/update-data.py --candidates scripts/candidates.json \
    --output dist/data.json --cache-dir "$TMPDIR/nelua-source-cache"

The cache contains only public source blobs. Metadata and branch heads are always
refreshed. GitHub credentials stay inside the gh subprocess and are never written.
"""
import argparse
import concurrent.futures as futures
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import posixpath
import re
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request

EXCLUDED_DIRS = {
    'vendor', 'vendors', 'vendored', 'third_party', 'third-party', 'thirdparty',
    'external', 'externals', 'dependencies', 'deps', '_deps', 'node_modules',
    'cache', '.cache', '__pycache__', 'build', 'builds', 'dist', 'target',
    'generated', 'autogen', 'reference', 'references', '.git', '.venv', 'venv',
}
GENERATED = re.compile(
    r'^(?:(?:this )?(?:file|module) (?:is |was |has been )?)?'
    r'(?:auto[- ]?generated|automatically generated|generated (?:by(?!\s+hand)|using|from))\b', re.I)
GENERATED_OUTPUT = re.compile(r'(?<!>)>\s*[\'"]?([\w./+@-]+\.nelua)\b')
LONG_OPEN = re.compile(r'\[(=*)\[')


def api(endpoint):
    for attempt in range(3):
        p = subprocess.run(['gh', 'api', endpoint], capture_output=True, text=True)
        if p.returncode == 0:
            return json.loads(p.stdout)
        if attempt < 2 and any(s in p.stderr for s in ('502', '503', '504', 'timeout')):
            time.sleep(attempt + 1)
            continue
        # Do not echo arbitrary command errors or credential-related output.
        match = re.search(r'HTTP (\d+)', p.stderr)
        raise RuntimeError('GitHub API ' + (match.group(1) if match else 'request failed'))


def sloc(source):
    """Nonblank physical code lines, respecting Lua/Nelua strings and comments."""
    total = 0
    block_comment = None
    long_string = None
    quote = None
    escaped = False
    for line in source.splitlines():
        code = False
        i = 0
        while i < len(line):
            if block_comment is not None:
                end = line.find(block_comment, i)
                if end < 0:
                    break
                i = end + len(block_comment)
                block_comment = None
            elif long_string is not None:
                if line[i:].strip():
                    code = True
                end = line.find(long_string, i)
                if end < 0:
                    break
                i = end + len(long_string)
                long_string = None
            elif quote:
                code = True
                ch = line[i]
                i += 1
                if escaped:
                    escaped = False
                elif ch == '\\':
                    escaped = True
                elif ch == quote:
                    quote = None
            elif line.startswith('--', i):
                match = LONG_OPEN.match(line, i + 2)
                if not match:
                    break
                block_comment = ']' + match.group(1) + ']'
                i = match.end()
            elif line[i].isspace():
                i += 1
            elif line[i] in ('"', "'"):
                code = True
                quote = line[i]
                i += 1
            elif line.startswith('##', i) and LONG_OPEN.match(line, i + 2):
                # Nelua's ##[[ Lua metaprogram ]] is executable source, not
                # a long string: comments inside it remain comments.
                code = True
                i = LONG_OPEN.match(line, i + 2).end()
            else:
                code = True
                match = LONG_OPEN.match(line, i)
                if match:
                    long_string = ']' + match.group(1) + ']'
                    i = match.end()
                else:
                    i += 1
        total += int(code)
        # A backslash immediately before newline escapes that newline only.
        escaped = False
    return total


def inspect_repo(name):
    try:
        meta = api('repos/' + name)
        if meta.get('private') or meta.get('visibility') != 'public':
            return {'name': name, 'status': 'excluded', 'reason': 'non-public repository'}
        if meta.get('fork'):
            return {'name': name, 'status': 'excluded', 'reason': 'fork'}
        if meta['owner']['type'] == 'Bot' or meta['owner']['login'].endswith('[bot]'):
            return {'name': name, 'status': 'excluded', 'reason': 'bot owner'}
        branch = meta['default_branch']
        ref = api('repos/' + meta['full_name'] + '/branches/' + urllib.parse.quote(branch, safe=''))
        sha = ref['commit']['sha']
        tree = api('repos/' + meta['full_name'] + '/git/trees/' + sha + '?recursive=1')
        if tree.get('truncated'):
            raise RuntimeError('recursive Git tree truncated; no partial count published')
        files = []
        excluded_paths = 0
        for f in tree.get('tree', []):
            path = f['path']
            if f['type'] != 'blob' or not path.lower().endswith('.nelua'):
                continue
            if any(part.lower() in EXCLUDED_DIRS for part in path.split('/')[:-1]):
                excluded_paths += 1
                continue
            files.append({'path': path, 'blob': f['sha'], 'size': f.get('size')})
        return {'name': meta['full_name'], 'status': 'scanned', 'url': meta['html_url'],
                'owner': meta['owner'], 'branch': branch, 'sha': sha,
                'createdAt': meta['created_at'], 'files': files,
                'buildFiles': [f for f in tree.get('tree', [])
                               if f['type'] == 'blob' and posixpath.basename(f['path']).lower() in ('makefile', 'gnumakefile')
                               and any(n['path'].startswith(posixpath.dirname(f['path']) + '/') or not posixpath.dirname(f['path']) for n in files)
                               and not any(part.lower() in EXCLUDED_DIRS for part in f['path'].split('/')[:-1])],
                'excludedPathFiles': excluded_paths, 'public': True, 'fork': False}
    except Exception as error:
        return {'name': name, 'status': 'failed', 'reason': str(error)}


def read_blob(repo, entry, cache_dir):
    blob = entry.get('blob', entry.get('sha'))
    blob_path = cache_dir / blob
    if blob_path.exists():
        raw = blob_path.read_bytes()
    else:
        path = urllib.parse.quote(entry['path'], safe='/')
        url = 'https://raw.githubusercontent.com/' + repo['name'] + '/' + repo['sha'] + '/' + path
        for attempt in range(3):
            try:
                req = urllib.request.Request(url, headers={'User-Agent': 'nelua-community-source-counter/1.0'})
                with urllib.request.urlopen(req, timeout=35) as response:
                    raw = response.read()
                break
            except (OSError, urllib.error.HTTPError):
                if attempt == 2:
                    raise RuntimeError('public raw source request failed: ' + entry['path'])
                time.sleep(attempt + 1)
        expected = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
        if expected != blob:
            raise RuntimeError('Git blob hash verification failed: ' + entry['path'])
        temp = blob_path.with_suffix('.' + str(os.getpid()) + '.' + str(threading.get_ident()) + '.tmp')
        temp.write_bytes(raw)
        temp.replace(blob_path)
    # Verify cached data too, so an interrupted or edited cache cannot alter totals.
    actual = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
    if actual != blob:
        raise RuntimeError('cached Git blob hash verification failed: ' + entry['path'])
    return raw


def find_generated(repo, cache_dir):
    outputs = {}
    try:
        for makefile in repo['buildFiles']:
            source = read_blob(repo, makefile, cache_dir).decode('utf-8-sig')
            # Resolve simple assignments without executing make or shell syntax.
            variables = dict(re.findall(r'(?m)^([A-Za-z_]\w*)\s*[:?+]?=\s*([^\n]*)', source))
            for _ in range(10):
                expanded = re.sub(r'\$\(([A-Za-z_]\w*)\)|\$\{([A-Za-z_]\w*)\}',
                                  lambda m: variables.get(m.group(1) or m.group(2), m.group(0)), source)
                if expanded == source:
                    break
                source = expanded
            for match in GENERATED_OUTPUT.finditer(source):
                path = posixpath.normpath(posixpath.join(posixpath.dirname(makefile['path']), match.group(1)))
                outputs[path] = makefile['path']
        return repo['name'], outputs, None
    except Exception as error:
        return repo['name'], {}, str(error)


def source_blob(repo, entry, cache_dir):
    raw = read_blob(repo, entry, cache_dir)
    source = raw.decode('utf-8-sig')
    for line in source.splitlines()[:100]:
        if line.lstrip().startswith('--'):
            comment = re.sub(r'^[-#\[=\s]+', '', line)
            if GENERATED.search(comment) or re.search(r'\b(?:do not|don.t) edit\b', comment, re.I):
                return {'excluded': 'generated notice', 'lines': 0, 'bytes': 0}
    return {'lines': sloc(source), 'bytes': len(raw)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidates', type=Path, default=Path(__file__).with_name('candidates.json'))
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--cache-dir', type=Path, required=True)
    parser.add_argument('--workers', type=int, default=16)
    args = parser.parse_args()
    args.cache_dir.mkdir(parents=True, exist_ok=True)
    candidates = json.loads(args.candidates.read_text())
    names = sorted(set(c if isinstance(c, str) else c['repo'] for c in candidates), key=str.lower)
    print(f'Inspecting {len(names)} public repository candidates', flush=True)
    with futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        repos = list(pool.map(inspect_repo, names))
    scanned = [r for r in repos if r['status'] == 'scanned']
    failures = [{'repository': r['name'], 'reason': r['reason']} for r in repos if r['status'] == 'failed']
    generated_outputs = {}
    with futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        for name, outputs, error in pool.map(lambda r: find_generated(r, args.cache_dir), scanned):
            generated_outputs[name] = outputs
            if error:
                failures.append({'repository': name, 'reason': 'generation evidence: ' + error})
    generated_blobs = {f['blob'] for r in scanned for f in r['files']
                       if f['path'] in generated_outputs.get(r['name'], {})}
    # A single fetch per content-addressed blob; copies count once across the index.
    locations = {}
    for repo in sorted(scanned, key=lambda r: (r['createdAt'], r['name'].lower())):
        for entry in sorted(repo['files'], key=lambda e: e['path']):
            locations.setdefault(entry['blob'], []).append((repo, entry))
    print(f'{len(scanned)} scanned; fetching {len(locations)} distinct candidate blobs', flush=True)
    measured = {}
    def fetch(pair):
        blob, copies = pair
        repo, entry = copies[0]
        try:
            if blob in generated_blobs:
                return blob, {'excluded': 'Makefile generation output', 'lines': 0, 'bytes': 0}, None
            return blob, source_blob(repo, entry, args.cache_dir), None
        except Exception as error:
            return blob, None, str(error)
    with futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        for count, (blob, result, error) in enumerate(pool.map(fetch, locations.items()), 1):
            if error:
                for repo, entry in locations[blob]:
                    failures.append({'repository': repo['name'], 'path': entry['path'], 'reason': error})
            else:
                measured[blob] = result
            if count % 250 == 0:
                print(f'Measured {count}/{len(locations)} blobs', flush=True)
    failed_names = {f['repository'] for f in failures}
    people = {}
    stats = {'excludedPathFiles': sum(r['excludedPathFiles'] for r in scanned),
             'excludedGeneratedFiles': 0, 'excludedDuplicateFiles': 0,
             'excludedEmptyFiles': 0}
    audit = []
    for repo in sorted(scanned, key=lambda r: (r['createdAt'], r['name'].lower())):
        retained = []
        generated = duplicates = empty = 0
        for entry in repo['files']:
            result = measured.get(entry['blob'])
            if result is None:
                continue
            if result.get('excluded'):
                generated += 1
                continue
            canonical_repo, canonical_file = next(
                ((r, f) for r, f in locations[entry['blob']] if r['name'] not in failed_names),
                (None, None))
            if canonical_repo is None or repo['name'] != canonical_repo['name'] or entry['path'] != canonical_file['path']:
                duplicates += 1
                continue
            if result['lines'] == 0:
                empty += 1
                continue
            retained.append({'path': entry['path'], 'blob': entry['blob'],
                             'lines': result['lines'], 'bytes': result['bytes']})
        stats['excludedGeneratedFiles'] += generated
        stats['excludedDuplicateFiles'] += duplicates
        stats['excludedEmptyFiles'] += empty
        lines = sum(f['lines'] for f in retained)
        size = sum(f['bytes'] for f in retained)
        record = {k: repo[k] for k in ('name', 'url', 'branch', 'sha', 'public', 'fork')}
        record.update({'lines': lines, 'bytes': size, 'files': len(retained),
                       'excludedPathFiles': repo['excludedPathFiles'],
                       'excludedGeneratedFiles': generated, 'excludedDuplicateFiles': duplicates,
                       'status': 'failed' if repo['name'] in failed_names else 'measured'})
        if record['status'] == 'failed':
            record.update({'lines': 0, 'bytes': 0, 'files': 0})
        audit.append(record)
        if lines == 0 or repo['name'] in failed_names:
            continue
        owner = repo['owner']
        person = people.setdefault(owner['login'], {'login': owner['login'], 'name': owner['login'],
            'ownerType': owner['type'], 'avatarUrl': owner['avatar_url'],
            'url': owner['html_url'], 'lines': 0, 'bytes': 0, 'files': 0, 'repositories': []})
        record['sourceFiles'] = retained
        person['repositories'].append(record)
        for key in ('lines', 'bytes', 'files'):
            person[key] += record[key]
    ranked = sorted(people.values(), key=lambda p: (-p['lines'], p['login'].lower()))
    for person in ranked:
        person['repositories'].sort(key=lambda r: (-r['lines'], r['name'].lower()))
    output = {
        'generatedAt': dt.datetime.now(dt.timezone.utc).isoformat().replace('+00:00', 'Z'),
        'metric': 'Current original .nelua SLOC',
        'methodology': [
            'A bounded index of candidate GitHub repositories; this is not a complete census of all Nelua code or developers.',
            'Current public, non-fork repositories on their default branches only; each commit SHA is pinned when measured. All time means no activity-date cutoff; deleted code and other branches do not count.',
            'Rank by nonblank, non-comment physical .nelua source lines, using a lexer that respects Lua/Nelua quoted strings, long strings and line/block comments. Bytes are raw UTF-8 source bytes of retained files.',
            'Repository totals are attributed to the repository owner, including organizations. Ownership is not a claim of individual authorship or contribution.',
            'Exclude bot-owned repositories and directory components: ' + ', '.join(sorted(EXCLUDED_DIRS)) + '.',
            'Exclude files whose first 100 lines contain a generated-file or do-not-edit comment notice. Also exclude .nelua output paths explicitly redirected to by a Makefile and exact copies of those generated blobs. Heuristics cannot prove that every remaining line was originally authored in that repository.',
            'Deduplicate exact Git blobs within and across repositories. A blob is retained once, in the earliest-created successfully measured repository, breaking ties by repository name then path; this deterministic rule does not establish provenance.',
            'Fetch immutable public raw files and verify their Git blob hashes. Exclude an entire repository from the ranking if any eligible source file fails; failures are reported.',
        ],
        'coverage': {
            'candidateRepositories': len(names), 'scannedRepositories': len(scanned),
            'qualifyingRepositories': sum(len(p['repositories']) for p in ranked),
            'failedRepositories': len(failed_names),
            'excludedRepositories': sum(r['status'] == 'excluded' for r in repos),
            'measuredRepositories': sum(r['status'] == 'measured' for r in audit),
            'owners': len(ranked), 'people': sum(p['ownerType'] == 'User' for p in ranked),
            'organizations': sum(p['ownerType'] == 'Organization' for p in ranked),
            'lines': sum(p['lines'] for p in ranked), 'bytes': sum(p['bytes'] for p in ranked),
            'files': sum(p['files'] for p in ranked), 'distinctCandidateBlobs': len(locations),
            **stats,
        },
        'people': ranked, 'failures': failures,
        'excludedGeneratedBlobs': sorted(blob for blob, result in measured.items() if result.get('excluded')),
        'excludedRepositories': [{'repository': r['name'], 'reason': r['reason']} for r in repos if r['status'] == 'excluded'],
        'repositoryAudit': sorted(audit, key=lambda r: r['name'].lower()),
        'generatedOutputEvidence': [
            {'repository': name, 'path': path, 'makefile': makefile}
            for name, outputs in sorted(generated_outputs.items()) for path, makefile in sorted(outputs.items())],
        'sources': [{'title': 'GitHub candidate repositories', 'url': 'https://github.com/search?q=nelua&type=repositories'},
                    {'title': 'Nelua language source', 'url': 'https://github.com/edubart/nelua-lang'}],
    }
    for key in ('lines', 'bytes', 'files'):
        assert output['coverage'][key] == sum(p[key] for p in ranked)
        assert all(p[key] == sum(r[key] for r in p['repositories']) for p in ranked)
    blobs = [f['blob'] for p in ranked for r in p['repositories'] for f in r['sourceFiles']]
    assert len(blobs) == len(set(blobs))
    assert all(r['public'] and not r['fork'] for p in ranked for r in p['repositories'])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, indent=2) + '\n')
    print(json.dumps(output['coverage'], indent=2), flush=True)


if __name__ == '__main__':
    main()

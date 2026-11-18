#!/usr/bin/env python3
"""Reject incomplete community refreshes before replacing the published snapshot."""
import argparse
import datetime as dt
import json
from pathlib import Path
import re


def require(condition, message):
    if not condition:
        raise ValueError(message)


def validate(previous, current, assets=None):
    coverage = current['coverage']
    people = current['people']
    repositories = [r for p in people for r in p['repositories']]
    files = [f for r in repositories for f in r['sourceFiles']]
    require(bool(people) and bool(files), 'Empty community snapshot')
    require(len({p['login'].lower() for p in people}) == len(people), 'Repeated owner')
    require(len({r['name'].lower() for r in repositories}) == len(repositories), 'Repeated repository')
    require(len({f['blob'] for f in files}) == len(files), 'Repeated source blob')
    require(all(r['public'] and not r['fork'] and r['status'] == 'measured'
                for r in repositories), 'Non-public, forked or incomplete repository')
    require(all(re.fullmatch(r'[0-9a-f]{40}', r['sha']) for r in repositories), 'Unpinned commit')
    for field in ('lines', 'bytes', 'files'):
        require(coverage[field] == sum(p[field] for p in people), f'Invalid total {field}')
        for person in people:
            require(person[field] == sum(r[field] for r in person['repositories']), f'Invalid owner {field}')
        for repo in repositories:
            total = len(repo['sourceFiles']) if field == 'files' else sum(f[field] for f in repo['sourceFiles'])
            require(repo[field] == total, f'Invalid repository {field}')
    require(coverage['owners'] == len(people), 'Invalid owner count')
    require(coverage['qualifyingRepositories'] == len(repositories), 'Invalid repository count')
    require(coverage['people'] == sum(p['ownerType'] == 'User' for p in people), 'Invalid people count')
    require(coverage['organizations'] == sum(p['ownerType'] == 'Organization' for p in people), 'Invalid team count')
    timestamp = dt.datetime.fromisoformat(current['generatedAt'].replace('Z', '+00:00'))
    age = (dt.datetime.now(dt.timezone.utc) - timestamp).total_seconds()
    require(-300 <= age <= 6 * 3600, 'Snapshot timestamp is stale or in the future')
    for field in ('candidateRepositories', 'measuredRepositories', 'qualifyingRepositories'):
        require(coverage[field] >= previous['coverage'][field] * 0.8, f'Collection lost more than 20% of {field}')
    require(coverage['lines'] >= previous['coverage']['lines'] * 0.6, 'Source total dropped more than 40%; review required')
    failure_limit = max(previous['coverage']['failedRepositories'] + 2,
                        int(coverage['candidateRepositories'] * 0.05))
    require(coverage['failedRepositories'] <= failure_limit, 'Too many repository collection failures')
    if assets is not None:
        for person in people:
            avatar = person.get('localAvatarUrl', '')
            require(bool(re.fullmatch(r'avatars/[a-z0-9-]+\.(?:png|jpg|webp)', avatar)), 'Invalid local avatar path')
            path = assets / avatar
            require(path.is_file() and path.stat().st_size > 0, 'Missing local avatar')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--previous', type=Path, required=True)
    parser.add_argument('--snapshot', type=Path, required=True)
    parser.add_argument('--assets', type=Path)
    args = parser.parse_args()
    current = json.loads(args.snapshot.read_text())
    validate(json.loads(args.previous.read_text()), current, args.assets)
    print(f"Validated {current['coverage']['qualifyingRepositories']} repositories, "
          f"{current['coverage']['lines']:,} source lines")


if __name__ == '__main__':
    main()

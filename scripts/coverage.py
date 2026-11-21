#!/usr/bin/env python3
"""Generate explorer data from a measured comparison, or refresh the legacy CSV view."""
import argparse
import csv
from datetime import date
from functools import lru_cache
import hashlib
import json
from pathlib import Path
import re
import subprocess

ASSETS = Path(__file__).resolve().parents[1] / 'public/nelua/assets'
PROFILE_LABELS = {'glibc': 'glibc', 'musl': 'musl / Zig', 'cosmopolitan': 'Cosmopolitan'}
IDENTIFIER = re.compile(r'[A-Za-z_][A-Za-z_0-9]*\Z')


def save(path, value):
    path.write_text(json.dumps(value, separators=(',', ':'), ensure_ascii=False) + '\n')


def measured_data(root, comparison, public_census, reference):
    manifest = json.loads((comparison / 'manifest.json').read_text())
    census = json.loads((comparison / 'coverage.json').read_text())
    revision = subprocess.check_output(['git', '-C', root, 'rev-parse', 'HEAD'], text=True).strip()
    if revision != manifest['source_base']:
        raise ValueError('The Nelibc checkout and comparison use different revisions')
    source = 'docs/musl-1.2.5-api-coverage.csv'
    expected = manifest.get('source_files', {}).get(source)
    if not expected:
        raise ValueError('The raw comparison manifest must identify the musl reference CSV')
    if hashlib.sha256((root / source).read_bytes()).hexdigest() != expected:
        raise ValueError('The musl reference CSV differs from the measured source')
    if not re.fullmatch(r'/nelua/assets/comparison-[\w-]+/coverage\.json', public_census):
        raise ValueError('Expected a same-site comparison coverage.json URL')
    hashes = {Path(name).resolve(): item['sha256']
              for name, item in manifest['runtime_census_libraries'].items()}
    for profile, info in manifest['profiles'].items():
        hashes[(root / info['archive']).resolve()] = manifest['archive_sha256'][profile]

    @lru_cache(maxsize=None)
    def read_archive(path):
        with path.open('rb') as stream:
            if stream.read(8) != b'!<arch>\n':
                # Debian libm.a is a GNU ld GROUP of real archives.
                members = re.findall(r'(/[^\s()]+\.a)', path.read_text())
                if not members:
                    raise ValueError(f'Unrecognized linker script {path}')
                return union(read_archive(Path(p).resolve()) for p in members)
            stream.seek(0)
            if hashlib.file_digest(stream, 'sha256').hexdigest() != hashes.get(path):
                raise ValueError(f'Archive does not match the measured SHA-256: {path}')
        output = subprocess.check_output(['readelf', '--wide', '--syms', path], text=True)
        defined, functions = set(), set()
        for line in output.splitlines():
            fields = line.split()
            if len(fields) != 8 or not fields[0][:-1].isdigit():
                continue
            _, _, _, kind, binding, visibility, section, raw_name = fields
            name = raw_name.split('@')[0]
            if section == 'UND' or binding not in ('GLOBAL', 'WEAK', 'UNIQUE') or not IDENTIFIER.fullmatch(name):
                continue
            defined.add(name)
            if kind in ('FUNC', 'IFUNC') and visibility in ('DEFAULT', 'PROTECTED'):
                functions.add(name)
        return defined, functions

    def union(pairs):
        defined, functions = set(), set()
        for names, callable_names in pairs:
            defined.update(names)
            functions.update(callable_names)
        return defined, functions

    musl_headers = {r['api']: r['musl_headers'] for r in reference}
    symbols = set(musl_headers)
    inventories = [('musl-1.2.5', 'musl 1.2.5 headers',
                    'Function names from the pinned musl 1.2.5 header inventory.', set(musl_headers))]
    profiles = []
    for profile, config in manifest['profiles'].items():
        label = config.get('label', PROFILE_LABELS.get(profile, profile))
        info = census[profile]
        archive = root / config['archive']
        owned, _ = read_archive(archive.resolve())
        runtime, functions = union(read_archive(Path(p).resolve()) for p in info['runtime_archives'])
        if (owned & musl_headers.keys() != set(info['exports'])
                or len(musl_headers.keys() & runtime) != info['baseline_runtime_exports']
                or len(musl_headers.keys() & (runtime | owned)) != info['combined_runtime_exports']):
            raise ValueError(f'{profile} symbol names disagree with the published census')
        version = config['version']
        version_label = {'glibc': version, 'musl': 'Zig musl'}.get(profile, f'{label} {version}')
        inventories.append((profile, f'{version_label} archive functions',
                            'Visible global and weak ELF function symbols with C identifier names in the measured runtime archives. Includes aliases and internal runtime functions.', functions))
        profiles.append((profile, label, owned, runtime))
        symbols.update(functions)

    names = sorted(symbols)
    index = {name: i for i, name in enumerate(names)}

    def indices(selected):
        return sorted(index[name] for name in selected if name in index)

    return {
        'generated': manifest['date_utc'][:10],
        'source_commit': manifest['source_base'],
        'comparison': public_census,
        'rows': [[name, musl_headers.get(name, '')] for name in names],
        'inventories': [dict(id=k, label=label, description=description, indices=indices(group))
                        for k, label, description, group in inventories],
        'profiles': [dict(id=k, label=label, owned=indices(owned), runtime=indices(runtime))
                     for k, label, owned, runtime in profiles],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('root', nargs='?', type=Path, default=Path('../nelibc'))
    parser.add_argument('--comparison', type=Path, help='Raw run directory after the runtime census')
    parser.add_argument('--public-census', help='Public URL path for the matching coverage.json')
    parser.add_argument('--out', type=Path)
    args = parser.parse_args()
    with (args.root / 'docs/musl-1.2.5-api-coverage.csv').open(newline='') as stream:
        reference = list(csv.DictReader(stream))
    if args.comparison:
        if not args.public_census:
            parser.error('--comparison requires --public-census')
        data = measured_data(args.root, args.comparison, args.public_census, reference)
        save(args.out or ASSETS / 'nelibc-coverage-profiles.json', data)
        print(', '.join(f'{group["label"]}: {len(group["indices"])}' for group in data['inventories']))
    else:
        rows = [[r['api'], r['musl_headers'], r['status'], r['nelibc_exports']] for r in reference]
        save(args.out or ASSETS / 'nelibc-coverage.json',
             {'source': 'Spaceghost/nelibc docs/musl-1.2.5-api-coverage.csv',
              'generated': date.today().isoformat(), 'rows': rows})
        print(f'{len(rows)} symbols in the legacy CSV view')


if __name__ == '__main__':
    main()

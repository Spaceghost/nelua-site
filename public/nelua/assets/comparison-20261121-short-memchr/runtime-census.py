#!/usr/bin/env python3
"""Record the runtimes used by the linked consumers and their musl-reference coverage."""
import argparse
import csv
from functools import lru_cache
import hashlib
import json
from pathlib import Path
import re
import shlex
import subprocess


def zig_archives(command, output, root):
    """Replay the recorded link with -v to identify the actual Zig runtime inputs."""
    command = list(command)
    command[command.index('-o') + 1] = str(output)
    command.insert(2, '-v')
    run = subprocess.run(command, cwd=root, capture_output=True, text=True, check=True)
    wanted = {'libc.a', 'libzigc.a', 'libcompiler_rt.a'}
    for line in (run.stderr + '\n' + run.stdout).splitlines():
        if 'libcompiler_rt.a' not in line:
            continue
        paths = [Path(word).resolve() for word in shlex.split(line)
                 if Path(word).is_absolute() and Path(word).name in wanted]
        if len(paths) == len(wanted) and {p.name for p in paths} == wanted:
            return sorted(paths)
    raise ValueError('Zig did not report all three linked runtime archives')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--results', type=Path, required=True)
    parser.add_argument('--cosmo-library', type=Path, required=True)
    args = parser.parse_args()
    root, results = args.root.resolve(), args.results.resolve()
    manifest = json.loads((results / 'manifest.json').read_text())
    coverage = json.loads((results / 'coverage.json').read_text())
    with (root / 'docs/musl-1.2.5-api-coverage.csv').open() as source:
        reference = {row['api'] for row in csv.DictReader(source)}
    libraries = {}

    @lru_cache(maxsize=None)
    def names(path):
        with path.open('rb') as stream:
            if stream.read(8) != b'!<arch>\n':
                members = re.findall(r'(/[^\s()]+\.a)', path.read_text())
                if not members:
                    raise ValueError(f'Unrecognized linker script {path}')
                return set().union(*(names(Path(p).resolve()) for p in members))
            stream.seek(0)
            digest = hashlib.file_digest(stream, 'sha256').hexdigest()
        command = ['nm', '-g', '--defined-only', str(path)]
        symbols = subprocess.run(command, capture_output=True, text=True, check=True).stdout
        libraries[str(path)] = {'sha256': digest, 'command': command}
        return {line.split()[-1].split('@')[0] for line in symbols.splitlines()
                if len(line.split()) >= 3} & reference

    zig_commands = [cmd for cmd in manifest['commands'] if cmd[1:2] == ['cc'] and
                    'x86_64-linux-musl' in cmd]
    if not zig_commands:
        raise ValueError('No matched Zig/musl consumer links found')
    zig = [zig_archives(cmd, results / 'census-link', root) for cmd in zig_commands]
    if any(paths != zig[0] for paths in zig[1:]):
        raise ValueError('The Zig/musl consumers linked different runtime archives')
    (results / 'census-link').unlink()
    gcc = manifest['profiles']['glibc']['cc']
    glibc = [Path(subprocess.check_output([*gcc, '-print-file-name=' + name],
                                          text=True).strip()).resolve()
             for name in ('libc.a', 'libm.a')]
    for profile, paths in [('glibc', glibc), ('musl', zig[0]),
                           ('cosmopolitan', [args.cosmo_library.resolve()])]:
        native = set().union(*(names(path) for path in paths))
        owned = set(coverage[profile]['exports'])
        coverage[profile].update(
            runtime_archives=list(map(str, paths)),
            baseline_runtime_exports=len(native),
            combined_runtime_exports=len(native | owned),
            added_runtime_exports=sorted(owned - native),
            runtime_census_scope='Defined global names in libc and its math/runtime companion archives.',
        )
        print(f'{profile}: {len(native)} native, {len(native | owned)} combined, {len(owned)} owned')
    manifest['runtime_census_libraries'] = libraries
    manifest['runtime_census_script_sha256'] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    for name, value in [('coverage', coverage), ('manifest', manifest)]:
        (results / f'{name}.json').write_text(json.dumps(value, indent=2) + '\n')


if __name__ == '__main__':
    main()

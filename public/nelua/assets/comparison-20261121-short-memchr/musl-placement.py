#!/usr/bin/env python3
"""Repeat memory cases in the measured musl consumer with matching 4 KiB page offsets."""
import argparse
import csv
import hashlib
import io
import json
import os
from pathlib import Path
import re
import statistics
import subprocess
import time

def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def offsets(binary):
    names = {'a', 'b', 'text', 'out'}
    symbols = subprocess.check_output(['nm', '-an', binary], text=True)
    found = {}
    for line in symbols.splitlines():
        fields = line.split()
        if len(fields) == 3 and fields[1] in ('b', 'B') and fields[2] in names:
            found[fields[2]] = int(fields[0], 16) % 4096
    if set(found) != names:
        raise ValueError('Cannot identify the four buffers in the recorded consumer')
    return found

def consumer(original, layout):
    start = original.index('static unsigned char a[131074]')
    end = original.index('static volatile uintptr_t sink;', start)
    declarations = []
    macros = []
    for name in ('a', 'b', 'text', 'out'):
        byte_type = 'unsigned char' if name in ('a', 'b') else 'char'
        pad = f'unsigned char prefix[{layout[name]}]; ' if layout[name] else ''
        declarations.append(f'static _Alignas(4096) struct {{ {pad}{byte_type} data[131074]; }} storage_{name};')
        macros.append(f'#define {name} (storage_{name}.data)')
    body = original[:start] + '\n'.join(declarations) + '\n' + original[end:]
    anchor = body.index('static uintptr_t run(unsigned op')
    body = body[:anchor] + '\n'.join(macros) + '\n' + body[anchor:]
    main = body.index('int main(int argc,char **argv)')
    checks = ' || '.join(f'((uintptr_t){name} % 4096) != {offset}' for name, offset in layout.items())
    return body[:main] + f'''int main(int argc, char **argv) {{
  if ({checks}) return 2;
  if (argc > 1 && strcmp(argv[1], "--check") == 0) return check();
  puts("case,family,bytes,ns_per_op,iterations");
  const size_t sizes[] = {{8, 32, 128, 1024}};
  for (size_t i = 0; i < sizeof sizes / sizeof sizes[0]; ++i) {{
    bench("memcpy", "memory", 0, sizes[i]);
    bench("memmove-overlap", "memory", 1, sizes[i]);
    bench("memchr-absent", "memory", 4, sizes[i]);
    bench("strlen", "strings", 5, sizes[i]);
  }}
  return sink == UINTPTR_MAX;
}}
'''

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root', required=True, type=Path)
    p.add_argument('--comparison', required=True, type=Path)
    p.add_argument('--out', required=True, type=Path)
    args = p.parse_args()
    run = json.loads((args.comparison / 'manifest.json').read_text())
    source = args.root / 'benchmarks/comparison/consumer.c'
    if digest(source) != run['benchmark_sha256']:
        raise ValueError('Benchmark source differs from the recorded run')
    os.sched_setaffinity(0, {run['cpu']})
    output = args.out.resolve()
    output.mkdir()
    variants = ('baseline', 'previous', 'nelibc')
    placements = {v: offsets(args.comparison / ('musl-' + v)) for v in ('previous','nelibc')}
    binaries, checks = {}, {}
    for layout, positions in placements.items():
        fixture = output / f'{layout}.c'
        fixture.write_text(consumer(source.read_text(), positions))
        for v in variants:
            original_binary = args.comparison / ('musl-' + v)
            cmd, = [c.copy() for c in run['commands'] if c[-1] == str(original_binary)]
            if v != 'baseline':
                archive, = [Path(x) for x in cmd if x.endswith('libnelibc-zig-musl.a')]
                hashes = run['archive_sha256' if v == 'nelibc' else 'previous_archive_sha256']
                if digest(archive) != hashes['musl']:
                    raise ValueError('Musl archive differs from the comparison')
            cmd[cmd.index(str(source))] = str(fixture)
            cmd[-1] = str(output / f'{layout}-{v}')
            subprocess.run(cmd, cwd=args.root, check=True, capture_output=True)
            binaries[layout,v] = cmd[-1]
            check = json.loads(subprocess.check_output([cmd[-1], '--check'], text=True))
            if check['failures'] or not check['checks']:
                raise ValueError(check)
            checks[layout+'-'+v] = check
    raw = []
    count = run['pairs']
    started = time.strftime('%FT%TZ',time.gmtime())
    for i in range(count):
        order = variants[i % 3:] + variants[:i % 3]
        for layout in placements if i % 2 == 0 else reversed(placements):
            for v in order if i % 2 == 0 else reversed(order):
                text = subprocess.check_output([binaries[layout,v]], text=True)
                for row in csv.DictReader(io.StringIO(text)):
                    raw.append(dict(layout=layout, implementation=v, pair=i+1, **row))
    def write_csv(name, rows):
        with (output/name).open('w', newline='') as stream:
            w=csv.DictWriter(stream, fieldnames=rows[0])
            w.writeheader()
            w.writerows(rows)
    write_csv('musl-placement-raw.csv', raw)
    groups = {}
    for row in raw:
        groups.setdefault((row['layout'],row['case'],int(row['bytes'])), {}).setdefault(
            row['implementation'], {})[row['pair']] = float(row['ns_per_op'])
    summary=[]
    for (layout, case, size), samples in groups.items():
        expected=set(range(1,count+1))
        assert all(set(samples[v])==expected for v in variants)
        ratios=[samples['previous'][i]/samples['nelibc'][i] for i in sorted(expected)]
        summary.append(dict(layout=layout,case=case,bytes=size,
            **{v+'_ns':statistics.median(samples[v].values()) for v in variants},
            previous_over_current=statistics.median(ratios),ratio_min=min(ratios),ratio_max=max(ratios)))
    write_csv('musl-placement.csv',summary)
    meta=dict(cpu=run['cpu'],pairs=count,started_utc=started,reference_offsets=placements,
              buffers='a is the copy source, b is the copy and move destination, text is the strlen input.',
              source_sha256=digest(source),driver_sha256=digest(Path(__file__)),checks=checks,
              candidate_sha256=run['archive_sha256']['musl'],previous_sha256=run['previous_archive_sha256']['musl'])
    (output/'musl-placement-manifest.json').write_text(json.dumps(meta,indent=2)+'\n')

if __name__=='__main__':
    main()

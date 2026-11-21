"""Repeat the published compiler phases for two SDKs using the 19 November fixtures."""
import argparse
import csv
import hashlib
import os
from pathlib import Path
import random
import statistics
import struct
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser(description=__doc__)
for name in ('necc', 'previous_sdk', 'updated_sdk', 'fixtures', 'output'):
    parser.add_argument(name, type=Path)
parser.add_argument('--cpu', type=int, required=True)
parser.add_argument('--rounds', type=int, default=25)
args = parser.parse_args()
if args.rounds < 2:
    parser.error('at least two measured rounds are required')
os.sched_setaffinity(0, {args.cpu})
fixtures = args.fixtures.resolve()
out = args.output.resolve()
out.mkdir(parents=True, exist_ok=True)
flags = ['-DNEBENCH_SAMPLE=42']
reference = {}
probes = {}
rows = []
load_before = os.getloadavg()

def run(probe):
    command, output, source_input, env = probe
    output.unlink(missing_ok=True)
    with (source_input or Path(os.devnull)).open('rb') as stdin:
        start = time.perf_counter_ns()
        subprocess.run(command, stdin=stdin, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       env=env, check=True, timeout=15)
        elapsed = time.perf_counter_ns() - start
    data = output.read_bytes()
    if not data:
        raise ValueError('empty output from ' + str(command))
    return elapsed, hashlib.sha256(data).hexdigest()

def write_csv(name, header, values):
    with (out / name).open('w', newline='') as stream:
        writer = csv.writer(stream, lineterminator='\n')
        writer.writerow(header)
        writer.writerows(values)

with tempfile.TemporaryDirectory(dir=os.environ.get('TMPDIR')) as scratch:
    for name, sdk in [('previous', args.previous_sdk), ('updated', args.updated_sdk)]:
        sdk = sdk.resolve()
        tmp = Path(scratch)/name
        tmp.mkdir()
        env = dict(os.environ, TMPDIR=str(tmp), TMP=str(tmp), TEMP=str(tmp), NECC_SYSROOT=str(sdk))
        tcc = [sdk/'tcc/tcc', '-B'+str(sdk/'tcc')]
        cpp = ['-nostdinc', '-std=c11', '-DNELIBC_STANDALONE', *flags,
               '-I'+str(sdk/'include'), '-I'+str(sdk/'tcc/include'), '-I'+str(sdk/'uapi')]
        for case in ('tiny', '128-functions'):
            source = fixtures/(case+'.c')
            pre, asm = tmp/(case+'.i'), tmp/(case+'.s')
            stages = [
                ('preprocess', [*tcc, *cpp, '-E', '-o', pre, source], pre, None),
                ('frontend', [args.necc, '--cc1', pre, asm], asm, None),
                ('public-S', [args.necc, '-S', pre, '-o', tmp/(case+'-public.s')], tmp/(case+'-public.s'), None),
                ('assemble', [*tcc, '-x', 'assembler', '-c', '-', '-o', tmp/(case+'.o')], tmp/(case+'.o'), asm),
                ('necc-full', [args.necc, *flags, '-c', source, '-o', tmp/(case+'-necc.o')], tmp/(case+'-necc.o'), None),
                ('TinyCC-full', [*tcc, *flags, '-c', source, '-o', tmp/(case+'-tcc.o')], tmp/(case+'-tcc.o'), None),
            ]
            for phase, command, dest, stdin in stages:
                probe = (command, dest, stdin, env)
                _, digest = run(probe)
                if digest != reference.setdefault((case, phase), digest):
                    raise ValueError(f'SDK output mismatch: {case} {phase}')
                probes[name, case, phase] = probe
                if phase in ('assemble', 'necc-full', 'TinyCC-full'):
                    program = tmp/'check'
                    subprocess.run(['ld.bfd', '-static', '-e', '_start', '-o', program, fixtures/'driver.o', dest], check=True)
                    value = 42
                    if case == '128-functions':
                        value = 19
                        for i in range(128):
                            value = ((value * 33 + i + 7) ^ (i + 17)) & 1048575
                    if subprocess.check_output([program]) != struct.pack('<q', value):
                        raise ValueError(f'Incorrect executable result: {name} {case} {phase}')
            if reference[case,'frontend'] != reference[case,'public-S'] or reference[case,'assemble'] != reference[case,'necc-full']:
                raise ValueError('Separate compiler phases differ from the public driver')

    rng = random.Random(747)
    for index in range(args.rounds+1):
        order = list(probes)
        rng.shuffle(order)
        for name, case, phase in order:
            elapsed, digest = run(probes[name, case, phase])
            if digest != reference[case, phase]:
                raise ValueError(f'Output changed at round {index}: {name} {case} {phase}')
            if index:
                rows.append((index, name, case, phase, elapsed))

write_csv('phase-samples.csv', ['round','sdk','case','phase','wall_ns'], rows)
summary = []
for name, case, phase in probes:
    values = [ns/1e6 for _, n, c, p, ns in rows if (n,c,p)==(name,case,phase)]
    q1, _, q3 = statistics.quantiles(values, n=4, method='inclusive')
    summary.append((case,phase,name,len(values),f'{statistics.median(values):.4f}',f'{q1:.4f}',f'{q3:.4f}'))
write_csv('phase-summary.csv', ['case','phase','sdk','n','median_ms','q1_ms','q3_ms'], summary)
write_csv('phase-outputs.csv', ['case','phase','sha256'], ((c,p,h) for (c,p),h in reference.items()))
print('Load averages before and after:', load_before, os.getloadavg())

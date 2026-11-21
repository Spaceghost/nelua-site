#!/usr/bin/env python3
"""Run the three matching GCC/glibc short-needle consumers on one Linux CPU."""
import argparse
import csv
import hashlib
import io
import itertools
import json
import os
from pathlib import Path
import platform
from statistics import median
import subprocess
import time

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--executables', type=Path, required=True)
p.add_argument('--source', type=Path, required=True)
p.add_argument('--previous-archive', type=Path, required=True)
p.add_argument('--cpu', type=int, required=True)
p.add_argument('--out', type=Path, required=True)
a = p.parse_args()
a.out.mkdir(exist_ok=False)
def sha(path):
    with path.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()
def write_json(name, obj):
    (a.out / name).write_text(json.dumps(obj, indent=2)+'\n')
def utc():
    return time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
versions = {'previous':'e98cae6a8d998cfc91c14a0d268c1f510fcf1461',
            'candidate':'190ad4e2c6ac8abcd19ae1ce7d0f3335dc62708f'}
assert subprocess.check_output(['git','-C',str(a.source),'rev-parse','HEAD'],text=True).strip() == versions['candidate']
assert not subprocess.check_output(['git','-C',str(a.source),'diff','--name-only','HEAD','--'])
variants = ('baseline','previous','candidate')
workloads = ('first-dense-then-sparse','first-sparse-then-dense','equal-frequency')
inputs_sha = sha(a.source/'tools/strstr_bench.c')
assert inputs_sha == 'dba74602a398c50d969b64bcb3f4c66d22f352d10644babed99b5089484e941f'
original_binaries = dict(zip(variants, ('75630d4b6bd5e35b63f24e122e71770f26f310578b758fd931d10acdd3c447ff',
    '830c355508750656e6a701c71e858c061c412b57bf6b5c3f94a1e927c695b672',
    'b578ccb1d791cc679d2288356642570ff522f005c0b9b653153a06dd15a84dce')))
actual_binaries = {v:sha(a.executables/v) for v in variants}
assert actual_binaries == original_binaries
cpu_model = next(l.split(':',1)[1].strip() for l in Path('/proc/cpuinfo').read_text().splitlines() if l.startswith('model name'))
assert os.geteuid() != 0 and a.cpu in os.sched_getaffinity(0)
os.sched_setaffinity(0,{a.cpu})
orders = list(itertools.permutations(variants))
orders += list(reversed(orders))
conditions = {'started_utc':utc(),'cpu':a.cpu,'cpu_model':cpu_model,'host_kernel':platform.release(),
              'glibc':os.confstr('CS_GNU_LIBC_VERSION'),'gcc':subprocess.check_output(['gcc','-dumpfullversion'],text=True).strip(),
              'load_start':list(os.getloadavg()),'method':'Each unmodified --anchor-controls process checks random and guarded inputs before timing, and reports the median of seven 256-call timed loops. All six variant orderings run once and then in reverse order. Only the 64 KiB rows are in the compact CSV.',
              'source_commit':versions,'source_sha256':inputs_sha,'driver_sha256':sha(Path(__file__)),
              'binary_sha256':actual_binaries,'archive_sha256':{'previous':sha(a.previous_archive),'candidate':sha(a.source/'build/libnelibc-gcc.a')},
              'rounds':len(orders),'observed_affinities':[], 'all_sizes_bytes':[64,4096,65536], 'needle':'abaa'}
all_rows=[]
for rnd, order in enumerate(orders,1):
    for pos,v in enumerate(order,1):
        assert os.sched_getaffinity(0)=={a.cpu}
        proc = subprocess.Popen([str(a.executables/v),'--anchor-controls'],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
        affinities=set()
        while True:
            try:
                affinities.add(tuple(sorted(os.sched_getaffinity(proc.pid))))
            except ProcessLookupError:
                pass
            try:
                stdout,stderr=proc.communicate(timeout=0.10)
                break
            except subprocess.TimeoutExpired:
                pass
        assert proc.returncode==0 and not stderr, (v,proc.returncode,stderr)
        assert affinities=={(a.cpu,)} and os.sched_getaffinity(0)=={a.cpu}
        conditions['observed_affinities'].append({'round':rnd,'position':pos,'implementation':v,'cpu':a.cpu})
        rows=list(csv.DictReader(io.StringIO(stdout)))
        assert len(rows)==9 and {(r['case'],int(r['haystack_bytes'])) for r in rows}==set(itertools.product(workloads,(64,4096,65536)))
        for row in rows:
            assert (row['implementation'],row['compiler'],row['libc'],row['needle_bytes'],row['iterations'])==(v,'gcc','glibc','4','256')
            assert float(row['median_ns_per_call'])>0
            all_rows.append({'round':rnd,'position':pos,'order':'/'.join(order),**row})
conditions.update(finished_utc=utc(),load_end=list(os.getloadavg()))
write_json('strstr-repeat-manifest.json',conditions)
for name,obs in [('strstr-repeat-all.csv',all_rows),('strstr-repeat-64k.csv',[r for r in all_rows if r['haystack_bytes']=='65536'])]:
    with (a.out/name).open('w',newline='') as f:
        w=csv.DictWriter(f,list(obs[0]),lineterminator='\n');w.writeheader();w.writerows(obs)
summary={}
for case in workloads:
    times={v:{r['round']:float(r['median_ns_per_call']) for r in all_rows if r['haystack_bytes']=='65536' and r['case']==case and r['implementation']==v} for v in variants}
    stats={'median_ns':{v:median(times[v].values()) for v in variants}}
    for name in ('baseline','previous'):
        ratios=[times[name][i]/times['candidate'][i] for i in range(1,len(orders)+1)]
        stats[name+'_over_candidate']={'median':median(ratios),'min':min(ratios),'max':max(ratios)}
    summary[case]=stats
write_json('strstr-repeat-summary.json', summary)

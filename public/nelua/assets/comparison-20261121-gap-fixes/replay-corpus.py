"""Repeat both built Cosmopolitan libc-test runs with the same native supervisor."""
import argparse
from collections import Counter
import hashlib
import json
import os
from pathlib import Path
import statistics
import subprocess
import time

def warm(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        while chunk := f.read(1048576):
            h.update(chunk)
    return h.hexdigest()

p=argparse.ArgumentParser()
p.add_argument('conformance',type=Path)
p.add_argument('--ape-loader',required=True,type=Path)
p.add_argument('--out',required=True,type=Path)
p.add_argument('--cpu',type=int,required=True)
a=p.parse_args()
a.conformance=a.conformance.resolve()
a.out.mkdir(parents=True, exist_ok=True)
initial=json.loads((a.conformance/'results.json').read_text())
supervisor=a.conformance/'supervisor/src/common/runtest.exe'
profiles=['cosmopolitan-baseline','cosmopolitan-nelibc']
data=initial['tests']
names=sorted(data[profiles[0]])
assert set(names)==set(data[profiles[1]]) and len(names)==343
os.sched_setaffinity(0,{a.cpu})
metadata={'date_utc':time.strftime('%FT%TZ',time.gmtime()),'cpu':a.cpu,'load_start':os.getloadavg(),
          'supervisor_sha256':warm(supervisor),'ape_sha256':warm(a.ape_loader),'executables_sha256':{}}
for i,name in enumerate(names):
    for profile in profiles if i%2==0 else reversed(profiles):
        assert os.sched_getaffinity(0)=={a.cpu}
        directory=a.conformance/profile
        binary='src/'+name+'.exe'
        if not (directory/binary).is_file():
            assert data[profile][name]['status'] in ('build_failure','link_failure')
            continue
        metadata['executables_sha256'][profile+'/'+name]=warm(directory/binary)
        result=subprocess.run([str(supervisor),'-w',str(a.ape_loader),binary],
                              cwd=directory, text=True, errors='replace', capture_output=True)
        msg=result.stdout
        if 'FAIL ' in msg: status='timeout' if 'timed out' in msg else 'runtime_failure'
        elif result.returncode: raise RuntimeError(f'supervisor exited {result.returncode}: {name}')
        else: status='pass'
        data[profile][name]={'status':status,'output':msg[:3000]}
    if (i+1)%50==0: print('paired cases completed',i+1,flush=True)
for profile in profiles:
    observed=Counter(v['status'] for v in data[profile].values())
    prior=initial['profiles'][profile]['counts']
    initial['profiles'][profile]['counts']={k:observed[k] for k in prior}
initial['method']+='; Cosmopolitan pair repeated after a sequential read of each executable, with alternating case order across implementations'
deltas={}
for profile in ['glibc','musl','cosmopolitan']:
    base=data[profile+'-baseline']
    nel=data[profile+'-nelibc']
    deltas[profile]={'regressions':[n for n in base if base[n]['status']=='pass' and nel[n]['status']!='pass'],
                    'improvements':[n for n in base if base[n]['status']!='pass' and nel[n]['status']=='pass']}
metadata['load_end']=os.getloadavg()
for name,obj in [('results',initial),('deltas',deltas),('conditions',metadata)]:
    (a.out/(name+'.json')).write_text(json.dumps(obj,indent=2)+'\n')

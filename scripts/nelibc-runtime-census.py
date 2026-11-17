#!/usr/bin/env python3
"""Add a symbol-only fallback/runtime census to a recorded Nelibc comparison.

Run on the same build host, after run.py, before rendering the site. This reads
archives; it does not compile or execute code. Zig's musl target also links
libzigc and compiler_rt: excluding those would falsely count math as missing.
"""
import argparse,csv,hashlib,json,re,subprocess
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--root',required=True,type=Path);p.add_argument('--results',required=True,type=Path)
p.add_argument('--zig-cache',required=True,type=Path);p.add_argument('--cosmo-library',required=True,type=Path)
a=p.parse_args();meta=json.loads((a.results/'manifest.json').read_text());cov=json.loads((a.results/'coverage.json').read_text())
inv={r['api'] for r in csv.DictReader((a.root/'docs/musl-1.2.5-api-coverage.csv').open())}
meta['runtime_census_libraries']={}
def names(path):
 path=Path(path).resolve()
 with path.open('rb') as f:magic=f.read(8)
 if magic!=b'!<arch>\n':
  paths=re.findall(r'(/[^\s()]+\.a)',path.read_text());assert paths,f'Unknown linker-script format: {path}'
  return set().union(*(names(x) for x in paths))
 r=subprocess.run(['nm','-g','--defined-only',str(path)],capture_output=True,text=True,check=True)
 meta['runtime_census_libraries'][str(path)]={'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'command':['nm','-g','--defined-only',str(path)]}
 return {line.split()[-1].split('@')[0] for line in r.stdout.splitlines() if len(line.split())>=3}&inv
libs={'glibc':[subprocess.check_output(['gcc','-print-file-name='+x],text=True).strip() for x in ['libc.a','libm.a']], 'cosmopolitan':[a.cosmo_library]}
musl=[]
for lib in ['libc.a','libzigc.a','libcompiler_rt.a']:
 paths=list(a.zig_cache.glob('o/*/'+lib));assert paths,f'Missing {lib}'
 variants=[names(x) for x in paths]
 assert all(x==variants[0] for x in variants),f'{lib} variants have different tracked exports; select the actual link inputs'
 musl+=paths
libs['musl']=musl
for profile,paths in libs.items():
 base=set().union(*(names(x) for x in paths));nel=set(cov[profile]['exports'])
 cov[profile].update({'runtime_archives':list(map(str,paths)),'baseline_runtime_exports':len(base),'combined_runtime_exports':len(base|nel),'added_runtime_exports':sorted(nel-base),'runtime_census_scope':'defined global names in the selected libc + math/runtime companion archives; symbol presence only, not per-symbol linkability or behavioral conformance'})
 print(profile,len(base),'->',len(base|nel),'owned by Nelibc:',len(nel))
meta['runtime_census_script_sha256']=hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
(a.results/'coverage.json').write_text(json.dumps(cov,indent=2)+'\n');(a.results/'manifest.json').write_text(json.dumps(meta,indent=2)+'\n')

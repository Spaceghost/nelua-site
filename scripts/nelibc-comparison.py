#!/usr/bin/env python3
"""Render both Nelua pages from a recorded, same-origin Nelibc comparison.

Usage: python3 scripts/nelibc-comparison.py public/nelua/assets/comparison-YYYYMMDD
The input directory must contain manifest/checks/coverage/summary.json,
conformance.json and deltas.json. Run the Nelibc comparison harness first;
this generator never substitutes old results for a missing measurement.
"""
import html, json, re, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
data=Path(sys.argv[1]).resolve()
def load(name):return json.loads((data/name).read_text())
meta=load('manifest.json');rows=load('summary.json');coverage=load('coverage.json');checks=load('checks.json');conf=load('conformance.json');deltas=load('deltas.json')
url='/'+str(data.relative_to(ROOT/'public')).replace('\\','/')
date=meta['date_utc'][:10]+' UTC';labels={'glibc':'glibc','musl':'musl / Zig','cosmopolitan':'Cosmopolitan'}
def esc(s):return html.escape(str(s))
def table(caption,headers,body):
 return '<div class="table-wrap"><table><caption>'+esc(caption)+'</caption><thead><tr>'+''.join('<th scope="col">'+esc(h)+'</th>' for h in headers)+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+str(c)+'</td>' for c in row)+'</tr>' for row in body)+'</tbody></table></div>'
def speed(x):return f'{x:.2f}' if x>=0.1 else f'{x:.3g}'
def ratio(row):
 label='delegated' if row['ownership']=='delegated' else ('mixed workload' if row['ownership']=='mixed workload' else '')
 status='st-implemented' if row['ratio_min']>1 else ('st-not-declared' if row['ratio_max']<1 else '')
 return f'<span class="{status}">{speed(row["speedup"])}×</span>'+ (f' <small class="muted">{label}</small>' if label else '')
def find(profile,case,size=0):return next(r for r in rows if r['profile']==profile and r['case']==case and r['bytes']==size)
completion=[]
for profile in labels:
 c=coverage[profile];completion.append([labels[profile],f'{c["baseline_runtime_exports"]:,} / {c["inventory_total"]:,}',f'{c["combined_runtime_exports"]:,} / {c["inventory_total"]:,}',f'{c["nelibc_exports"]:,} ({100*c["nelibc_exports"]/c["inventory_total"]:.1f}%)'])
block=f'''<!-- nelibc-comparison:start -->
<h2 class="section" id="completion">Completion: whose implementation is it?</h2>
<p class="lead">Fresh archive-symbol census, {date}. The denominator is the same pinned musl 1.2.5 inventory for every profile. Runtime-alone and combined columns count defined names in the libc and its math/runtime companion archives: glibc libc/libm, musl plus Zig libzigc/compiler_rt, and Cosmopolitan libcosmo. Owned counts name the implementations Nelibc exports. This is symbol presence, not a test of every individual link or standards conformance. A name absent from Nelibc may still be supplied by the fallback libc.</p>
'''+table('Symbol census against the same 1,471-name inventory', ['Profile','Runtime alone','Runtime + Nelibc','Owned by Nelibc'],completion)+f'''
<p class="note">Cosmopolitan is the default hybrid build in the captured source snapshot and intentionally owns more of its runtime. The snapshot includes the new profile; it is not a claim that these changes have landed on upstream main. Its narrower Nelibc count does not mean the executable cannot call the delegated APIs. The combined count is a union, so replacing an existing function does not add another API name. These are per-profile counts; the older coverage explorer below is a separate historical inventory snapshot.</p>
<h2 class="section" id="conformance">Conformance: the same tests, with and without Nelibc</h2>
<p class="lead">musl libc-test <code>{esc(conf['libc_test_commit'][:12])}</code>, functional, regression and math corpus, run {date}. Both halves of each pair use the same libc-owned headers. Every result is shown; no expected-failure list turns a failing test into a pass.</p>
'''
conform_rows=[]
for profile in labels:
 for implementation in ['baseline','nelibc']:
  c=conf['profiles'][profile+'-'+implementation];n=c['counts']
  conform_rows.append([labels[profile]+(' + Nelibc' if implementation=='nelibc' else ' alone'),str(c['planned']),str(n['pass']),str(n['build_failure']),str(n['link_failure']),str(n['runtime_failure']),str(n['timeout']),str(n['not_run'])])
block+=table('Independent libc-test outcomes; counts are tests, not assertions', ['Build','Planned','Pass','Build fail','Link fail','Runtime fail','Timeout','Not run'],conform_rows)
block+='<p>Changes relative to each baseline: '+ '; '.join(f'{labels[p]}: <strong>{len(deltas[p]["improvements"])} newly passing</strong>, <strong>{len(deltas[p]["regressions"])} new non-passes</strong>' for p in labels)+'. Build and link failures count as non-passes in these deltas.</p>'
check_counts=sorted(set(v['result']['checks'] for v in checks.values()))
assert all(v['exit']==0 and v['result']['failures']==0 for v in checks.values())
block+=f'''<p class="note">All {len(checks)} benchmark consumers also passed {", ".join(str(n) for n in check_counts)} targeted assertions each before timing. Those assertions cover the benchmarked operations and are separate from libc-test. The independent corpus uses libc-test's native supervisor, a 100 KiB stack limit and five-second per-test timeout. Cosmopolitan executables use its native APE loader in both halves of the pair. The corpus includes musl-specific, platform and extension expectations; a non-pass is not by itself proof of a standards violation. This is measured test coverage, not certification of all C or POSIX behavior. Historical Nelibc-header and standalone gates are listed separately below.</p>
<details><summary>Tests newly failing or newly passing in each pair</summary>'''
for profile in labels:
 block+='<h3>'+labels[profile]+'</h3>'
 for field,title in [('regressions','New non-passes'),('improvements','New passes')]:
  block+='<p><strong>'+title+':</strong> '+(', '.join('<code>'+esc(x)+'</code>' for x in deltas[profile][field]) or 'none')+'</p>'
block+='</details>'
block+=f'''
<h2 class="section" id="performance">Performance: each libc against itself</h2>
<p class="lead">Goal: make the most important libc operations faster while preserving their behavior. These are measurements toward that goal. The same C consumer is compiled with and without each production Nelibc archive; each ratio compares only the two builds in that profile.</p>
<p><strong>Speedup = baseline time ÷ Nelibc time.</strong> Above 1.00× means the Nelibc-linked build was faster; below 1.00× means it was slower. Delegated rows measure the surrounding linked program and are not credited as Nelibc implementation wins.</p>
'''
selected=[('memcpy',4096),('memmove-overlap',128),('memset',4096),('memcmp-equal',128),('memchr-absent',128),('strlen',128),('strcmp-equal',128),('strstr-tail',128),('strtol-decimal',0),('strtod-decimal',0),('sin',0),('sqrt',0),('malloc-free',64),('snprintf-mixed',0),('qsort-128-integers',0),('parse-record',0)]
performance=[]
for case,size in selected:
 performance.append([esc(case)+(f' · {size:,} B' if size else ''),*[ratio(find(p,case,size)) for p in labels]])
if any('previous_ns' in r for r in rows):
 block+='<h3 id="gap-reduction">Optimization follow-up: the previous candidate versus this one</h3><p>The previous production archives were saved before changing the implementations. Each profile now rotates three builds of the same consumer: libc alone, the previous Nelibc candidate, and the new candidate. This table uses GCC/glibc only. These are concurrent measurements, not a comparison with historical timings.</p>'
 improvements=[]
 for case,size in [('memcpy',128),('memcpy',1024),('memset',1024),('memcmp-equal',8),('memchr-absent',1024),('strlen',1024),('strcmp-equal',32)]:
  r=find('glibc',case,size)
  improvements.append([esc(case)+' · '+str(size)+' B',f'{r["previous_ns"]:.2f}',f'{r["nelibc_ns"]:.2f}',f'{r["baseline_ns"]:.2f}',f'{r["speedup_vs_previous"]:.2f}×'])
 block+=table('GCC/glibc, seven rotating process triplets; nanoseconds per operation',['Case','Previous Nelibc','New Nelibc','glibc alone','Gain vs previous'],improvements)
 block+='<p>Changes: bounded head/tail copies and fills, runtime AVX2 paths for mid-size buffers and long strings, word-sized tiny comparisons, and fewer page checks on short strings. Read-only queries carry C purity metadata; operations that write memory or errno retain their effects. The timed wrappers keep calls observable, so these gains measure the implementations. Slower cases and all raw samples remain below.</p>'
 for case,size in [('memset',8),('memchr-absent',8)]:
  r=find('glibc',case,size)
  block+=f'<p class="small muted">Tradeoff: {esc(case)}({size}) measured {r["previous_ns"]:.2f} → {r["nelibc_ns"]:.2f} ns; glibc alone {r["baseline_ns"]:.2f} ns.</p>'
 if (data/'strcmp-distribution.json').exists():
  r=next(r for r in load('strcmp-distribution.json') if r['bytes']==65536 and r['left_offset']==r['right_offset']==0 and r['case']=='equal')
  ns=r['median_ns']
  block+=f'<p class="small muted">The separate alignment consumer measured equal 64 KiB strcmp at offsets (0,0): previous {ns["previous"]:.2f}, new {ns["candidate"]:.2f}, glibc {ns["baseline"]:.2f} ns. Long-string results differ between consumers; the headline gains do not mean every case improved.</p>'
 block+=f'<p><a href="{url}/optimization-notes.md">Optimization notes and verification</a> · <a href="{url}/strcmp-distribution.json">String alignment/mismatch results</a> · <a href="{url}/memory-distribution.json">Memory alignment results</a> · <a href="{url}/previous-source.tar.gz">Previous candidate source</a></p>'
 block+='<p><a href="/nelua/assets/comparison-20261117/manifest.json">Original comparison manifest</a>. The new source is still an unmerged candidate; the repository’s full integration gate remains separate from these focused checks and the independent corpus.</p>'
block+=table('Representative cases, median of seven paired speedups', ['Case','glibc → +Nelibc','musl/Zig → +Nelibc','Cosmopolitan → +Nelibc'],performance)
block+=f'''<p class="small muted">{esc(meta['cpu_model'])}; {esc(meta['platform'])}; CPU {meta['cpu']} pinned; {meta['pairs']} process rounds ({'rotating triplets with the previous candidate' if 'previous_archive_sha256' in meta else 'alternating pairs'}), rotating profile order. Each timed loop runs for at least 5 ms after calibration. Consumer flags include <code>-O2 -fno-builtin</code>; volatile pointers to noinline direct-call wrappers stop pure-function calls being hoisted out of the loop. The same wrappers are used in every profile. Taking the address of Cosmopolitan 4.0.2’s strstr IFUNC failed in this toolchain; direct calls passed, so this measures the direct-call path and does not establish function-pointer ABI conformance. Loop, pointer-call and checksum overhead is included equally, not subtracted. Buffers are hot and aligned; this is not a DRAM bandwidth, cold-cache, multicore or application throughput result. The record parser is a synthetic combined workload; qsort includes initializing its input, and malloc/free includes writing the first and last byte. Other jobs shared the host; affinity does not reserve a CPU. Start/end load averages: {esc(meta['load_start'])} / {esc(meta['load_end'])}.</p>
<details><summary>All sizes, absolute times and observed pair ranges</summary>
<p>Times are median nanoseconds per operation. Ranges are the minimum and maximum paired speedup observed, not confidence intervals. Cross-profile absolute rankings mix different compilers and runtimes.</p>'''
for profile in labels:
 body=[]
 for r in rows:
  if r['profile']!=profile:continue
  body.append([esc(r['case']),str(r['bytes']),f'{r["baseline_ns"]:.2f}',f'{r["nelibc_ns"]:.2f}',ratio(r),f'{speed(r["ratio_min"])}–{speed(r["ratio_max"])}×',esc(r['ownership'])])
 block+='<h3>'+labels[profile]+'</h3>'+table(labels[profile]+' complete measured cases',['Case','Bytes','Alone ns/op','+Nelibc ns/op','Speedup','Observed range','Owner'],body)
block+='</details>'
# Rank implemented losses on the broadly used operations before choosing new
# optimization work. Keep all results above, including gains and regressions.
priorities=[]
for case in ['memcpy','memmove-overlap','memset','memcmp-equal','memchr-absent','strlen','strcmp-equal','strstr-tail','strtod-decimal','snprintf-mixed','qsort-128-integers']:
 candidates=[r for r in rows if r['case']==case and r['ownership']=='Nelibc export' and r['ratio_max']<1]
 if candidates:
  worst=min(candidates,key=lambda r:r['speedup']);priorities.append(worst)
priorities.sort(key=lambda r:r['speedup'])
block+='<h2 class="section" id="priorities">What to optimize next</h2><p>Start with measured losses in frequently used operations, retain the winning cases, and require correctness before promoting a faster path. This ordering reflects this corpus; it is not a claim about every application\'s CPU profile.</p><ol>'
for r in priorities[:3]:
 block+=f'<li><strong>{esc(r["case"])}</strong>: {labels[r["profile"]]} + Nelibc measured {r["speedup"]:.2f}× baseline speed'+(f' at {r["bytes"]:,} bytes' if r['bytes'] else '')+'. Keep this case in the comparison while testing short, long, aligned and unaligned inputs.</li>'
block+='</ol>'
regressions=[labels[p]+': '+', '.join(deltas[p]['regressions']) for p in labels if deltas[p]['regressions']]
if regressions:block+='<p class="note"><strong>Correctness first:</strong> investigate or document the newly failing corpus cases before promoting optimizations: '+esc('; '.join(regressions))+'.</p>'
block+='<p>Next evidence: application profiles to weight the cases; more CPUs and working-set sizes; allocator contention and I/O workloads. A single-host microbenchmark cannot establish a globally fastest libc.</p>'
block+='<h2 class="section" id="evidence">Download and reproduce</h2><p>Run recorded '+date+'. Compiler versions: '+ '; '.join(labels[p]+': <code>'+esc(meta['compiler_versions'][p])+'</code>' for p in labels)+'. The musl pair uses Zig\'s bundled musl; the Cosmopolitan toolchain is 4.0.2. glibc version: '+esc(meta['profiles']['glibc']['version'])+'.</p>'
block+=f'<p>Nelibc base <code>{esc(meta["source_base"][:12])}</code> plus the captured Cosmopolitan, optimization and comparison changes. The source archive and manifest preserve the exact inputs, compiler commands and archive hashes; these results do not claim to be from unchanged upstream main.</p>'
block+='<p>Test diagnostics retain per-test build and runtime logs; the conformance JSON records both halves of each pair with the APE loader for Cosmopolitan. <a href="https://git.musl-libc.org/cgit/libc-test/tree/?id='+esc(conf['libc_test_commit'])+'">Pinned upstream test source</a>.</p>'
block+='<div class="actions">'+''.join(f'<a class="button button-ghost" href="{url}/{file}">{label}</a>' for file,label in [('summary.csv','Performance CSV'),('raw.csv','Raw paired runs'),('conformance.json','Conformance results'),('conformance-logs.tar.gz','Test diagnostics'),('deltas.json','Conformance deltas'),('coverage.json','Export census'),('manifest.json','Run manifest'),('source.tar.gz','Exact source + harness')])+'</div>'
size_rows=[]
for profile in labels:
 size_rows.append([labels[profile],f'{meta["binary_bytes"][profile]["baseline"]:,}',f'{meta["binary_bytes"][profile]["nelibc"]:,}','Dynamic system libc' if profile=='glibc' else 'Static'])
block+='<details><summary>Built consumer file sizes</summary>'+table('Unnormalized executable file bytes, as built',['Profile','Alone bytes','+Nelibc bytes','Link mode'],size_rows)+'<p>These are not normalized release sizes. The dynamic glibc executable excludes its shared libraries; symbols, debug information, archive granularity and static runtimes affect these files. No footprint winner is claimed.</p></details>\n<!-- nelibc-comparison:end -->\n'
page=ROOT/'public/nelua/nelibc/index.html';s=page.read_text()
start='<!-- nelibc-comparison:start -->';end='<!-- nelibc-comparison:end -->'
if start in s:s=s[:s.index(start)]+block+s[s.index(end)+len(end):]
else:s=s.replace('<h2 class="section">What works today</h2>',block+'\n<h2 class="section">What works today</h2>',1)
a=s.index('  <p class="stats">');b=s.index('</p>',a)+4
s=s[:a]+'  <p class="stats">'+''.join(f'<span><strong>{coverage[p]["nelibc_exports"]:,} / {coverage[p]["inventory_total"]:,}</strong> exports · {labels[p]}</span>' for p in labels)+f'<span>comparison {date}</span></p>'+s[b:]
s=s.replace('<h2 class="section">Build and gate</h2>','<h2 class="section">Build and historical gates</h2>')
s=s.replace('31 (gcc) and 35 (zig) on main now','31 (gcc) and 35 (zig) in the recorded 2026-11-07 run')
s=s.replace('<dt>Requirements</dt><dd>Nelua, Zig (<code>zig cc</code>).', '<dt>Requirements</dt><dd>Nelua and the Cosmopolitan compiler wrapper for the default hybrid build; Zig (<code>zig cc</code>) for the older profiles.')
s=s.replace('<dt>First build</dt><dd><code>make dogfood-zig</code>', '<dt>Captured-source build</dt><dd>Download the exact source snapshot above and extract it into a new directory. In that snapshot, <code>make smoke-cosmo</code> uses <code>x86_64-unknown-cosmo-cc</code> from Cosmopolitan 4.0.2, checks the full archive link and rejects a glibc dependency. Supply <code>COSMOCC=/path/to/cosmocc/bin/x86_64-unknown-cosmo-cc</code>. Compile consumers with Cosmopolitan headers, without <code>-Iinclude</code>.</dd>\n  <dt>Older hybrid example</dt><dd><code>make dogfood-zig</code>')
s=s.replace('Coverage data 2026-11-05; gate and conformance 2026-11-07.',f'Export census and matched comparison {date}; historical explorer 2026-11-05 and gates 2026-11-07.')
s=s.replace('All 1,471 function symbols musl 1.2.5 declares, with Nelibc\'s status in the pinned hybrid comparison.', 'Historical reference: 1,471 function symbols musl 1.2.5 declares, with Nelibc\'s status in the 2026-11-05 hybrid inventory. The fresh per-profile export census is above.')
page.write_text(s)
page=ROOT/'public/nelua/index.html';s=page.read_text();start='<!-- nelibc-overview:start -->';end='<!-- nelibc-overview:end -->'
parser='; '.join(labels[p]+f' {find(p,"parse-record")["speedup"]:.2f}×' for p in labels)
overview=f'''<!-- nelibc-overview:start -->
<h2 class="section" id="libc-comparison">How much is ours, how correct is it, and how fast?</h2>
<p class="lead">The goal is the fastest correct implementation of the libc operations programs use most. The current evidence compares glibc, musl and Cosmopolitan, each alone and with Nelibc, on the same host and consumer.</p>
<div class="grid grid-3">
<article class="card card-core"><h3>Completion</h3><p>{'; '.join(labels[p]+': <strong>'+str(coverage[p]['nelibc_exports'])+'</strong>' for p in labels)} of {next(iter(coverage.values()))['inventory_total']:,} tracked names exported by Nelibc. These count owned implementations, not standards compliance. Cosmopolitan deliberately delegates more stateful services.</p></article>
<article class="card card-core"><h3>Conformance</h3><p>{'; '.join(labels[p]+': <strong>'+str(conf['profiles'][p+'-baseline']['counts']['pass'])+' → '+str(conf['profiles'][p+'-nelibc']['counts']['pass'])+'</strong> passes' for p in labels)} in the matched functional, regression and math corpus. Build failures, runtime failures and newly failing tests are all reported.</p></article>
<article class="card card-core"><h3>Performance</h3><p>Synthetic record parser, baseline time ÷ Nelibc time: {parser}. Above 1× is faster. The detailed results include memory, strings, conversion, math, allocation, formatting and sorting, including slower cases and delegated calls.</p></article>
</div>
<p class="small muted">Measured {date}; {esc(meta['cpu_model'])}; {meta['pairs']} process rounds, one pinned CPU on a shared host. Consumer checks passed before timing. Single-host microbenchmarks do not establish a globally fastest libc.</p>
<div class="actions"><a class="button" href="/nelua/nelibc/#performance">Inspect the matched results</a><a class="button button-ghost" href="/nelua/nelibc/#profiles">See the five runtime arrangements</a></div>
<!-- nelibc-overview:end -->
'''
if any('previous_ns' in r for r in rows):
 gains='; '.join(case+'('+str(size)+') '+f'{find("glibc",case,size)["speedup_vs_previous"]:.2f}×' for case,size in [('memcpy',1024),('memset',1024),('strlen',1024)])
 overview=overview.replace('<div class="actions">','<p><strong>Optimization follow-up:</strong> '+gains+' faster than the previous candidate in the concurrent GCC/glibc comparison. Slower cases and alignment results are included on the <a href="/nelua/nelibc/#gap-reduction">detailed page</a>.</p><div class="actions">',1)
if start in s:s=s[:s.index(start)]+overview+s[s.index(end)+len(end):]
else:s=s.replace('<h2 class="section">Three rings</h2>',overview+'\n<h2 class="section">Three rings</h2>',1)
s=re.sub(r'<span><strong>[0-9,]+ / [0-9,]+</strong> (?:musl symbols in nelibc|tracked exports · glibc hybrid \([^<]*\))</span>', '<span><strong>'+str(coverage['glibc']['nelibc_exports'])+' / '+f"{coverage['glibc']['inventory_total']:,}"+'</strong> tracked exports · glibc hybrid ('+date+')</span>', s)
s=s.replace('<span>updated 2026-11-07</span>','<span>compiler reference 2026-11-07; nebox reference 2026-11-08</span>')
s=s.replace('<strong>97 applets</strong>','<strong>104 applets</strong>').replace('97 applets including','104 applets including').replace('about 1.5 MB','3,013,304 bytes (recorded 2026-11-08)')
page.write_text(s)
print('Updated both pages from',data)

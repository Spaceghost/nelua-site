#!/usr/bin/env python3
"""Render both Nelua pages from a recorded, same-origin Nelibc comparison.

Usage: python3 scripts/nelibc-comparison.py public/nelua/assets/comparison-YYYYMMDD
The input directory must contain manifest/checks/coverage/summary.json,
conformance.json and deltas.json. Run the Nelibc comparison harness first;
this generator never substitutes old results for a missing measurement.
"""
import html, json, re, sys
from pathlib import Path
from nelibc_results import phase_headline, render_results, verify_timings
ROOT=Path(__file__).resolve().parents[1]
data=Path(sys.argv[1]).resolve()
def load(name):return json.loads((data/name).read_text())
meta=load('manifest.json');rows=load('summary.json');coverage=load('coverage.json');checks=load('checks.json');conf=load('conformance.json');deltas=load('deltas.json')
verify_timings(data, rows)
url='/'+str(data.relative_to(ROOT/'public')).replace('\\','/')
followup=load('optimization.json') if (data/'optimization.json').exists() else {}
source_commit=meta.get('source_commit')
if source_commit:
 assert re.fullmatch('[0-9a-f]{40}',source_commit) and source_commit==meta['source_base']
 assert re.fullmatch('[0-9a-f]{40}',meta['previous_commit'])
gate_path=ROOT/'public/nelua/assets/integration-20261117/gate.json'
gate=json.loads(gate_path.read_text()) if gate_path.exists() else None
if gate and gate['comparison_directory']!=data.name:gate=None
gate_url='/nelua/assets/integration-20261117'
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
gate_note=''
current_gate = load('gate-summary.json') if (data/'gate-summary.json').is_file() else None
if current_gate:
 assert current_gate['source_commit']==source_commit
 results=current_gate['results']
 assert len(results)==len({row['target'] for row in results}) and results
 assert all(isinstance(row['exit'],int) and row['seconds']>=0 for row in results)
 pass_count=sum(row['exit']==0 for row in results)
 gate_note=f'<p><strong>{pass_count} of {len(results)} integration targets passed.</strong> <a href="/nelua/nelibc/#integration-gate">See individual targets and expected failures</a>.</p>'
if gate:
 assert gate['passed'] and len(gate['results'])==14 and all(r['exit']==0 for r in gate['results'])
 commit=gate['source_commit'];assert re.fullmatch('[0-9a-f]{40}',commit)
 gate_note='<p><strong>Builds verified.</strong> The glibc, musl and Cosmopolitan builds pass integration checks. Standalone builds and Bend’s worker pool pass too. <a href="/nelua/nelibc/#integration-gate">Test results and known gaps</a>.</p>'
completion=[]
for profile in labels:
 c=coverage[profile];completion.append([labels[profile],f'{c["baseline_runtime_exports"]:,} / {c["inventory_total"]:,}',f'{c["combined_runtime_exports"]:,} / {c["inventory_total"]:,}',f'{c["nelibc_exports"]:,} ({100*c["nelibc_exports"]/c["inventory_total"]:.1f}%)'])
block=f'''<h2 class="section" id="completion">Completion: whose implementation is it?</h2>
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
if (data/'initial-conformance.json').is_file():
 initial=load('initial-conformance.json')
 first_counts=[initial['profiles']['cosmopolitan-'+v]['counts']['pass'] for v in ('baseline','nelibc')]
 original=[initial['profiles']['cosmopolitan-'+name]['counts']['timeout'] for name in ('baseline','nelibc')]
 block+=f'<p>In the first conformance run on this revision, Cosmopolitan alone passed {first_counts[0]} tests and Cosmopolitan with Nelibc passed {first_counts[1]}. Their timeout counts were {original[0]} and {original[1]}, respectively. Both sets of compiled tests were then repeated in the same guest. Each executable was read into the page cache before the original supervisor started its five-second timer. The table uses the repeated pair. <a href="{url}/initial-conformance.json">Initial per-test results</a> · <a href="{url}/replay-conditions.json">Repeat conditions</a> · <a href="{url}/corpus-build.json">Corpus build identities</a>.</p>'
 changes=[]
 for variant in ('baseline','nelibc'):
  profile='cosmopolitan-'+variant
  for test,outcome in conf['tests'][profile].items():
   first=initial['tests'][profile][test]['status']
   later=outcome['status']
   if first!=later:
    label='Cosmopolitan alone' if variant=='baseline' else 'Cosmopolitan with Nelibc'
    first=first.replace('_',' ')
    later=later.replace('_',' ')
    changes.append(f'{label} changed from {esc(first)} to {esc(later)} on <code>{esc(test)}</code>')
 if changes:
  block+='<p>'+'. '.join(changes)+'.</p>'
check_counts=sorted(set(v['result']['checks'] for v in checks.values()))
assert all(v['exit']==0 and v['result']['failures']==0 for v in checks.values())
block+=f'''<p class="note">All {len(checks)} benchmark consumers also passed {", ".join(str(n) for n in check_counts)} targeted assertions each before timing. Those assertions cover the benchmarked operations and are separate from libc-test. The independent corpus uses libc-test's native supervisor, a 100 KiB stack limit and five-second per-test timeout. Cosmopolitan executables use its native APE loader in both halves of the pair. The corpus includes musl-specific, platform and extension expectations; a non-pass is not by itself proof of a standards violation. This is measured test coverage, not certification of all C or POSIX behavior. Historical Nelibc-header and standalone gates are listed separately below.</p>
<details><summary>Tests newly failing or newly passing in each pair</summary>'''
for profile in labels:
 block+='<h3>'+labels[profile]+'</h3>'
 for field,title in [('regressions','New non-passes'),('improvements','New passes')]:
  block+='<p><strong>'+title+':</strong> '+(', '.join('<code>'+esc(x)+'</code>' for x in deltas[profile][field]) or 'none')+'</p>'
block+='</details>'
if gate:
 block+='<h3 id="integration-gate">Build status</h3><p>The glibc, musl and Cosmopolitan builds pass integration checks. Standalone builds and Bend’s worker pool pass too. Remaining conformance failures are shown in the results above.</p>'
 block+=f'<details><summary>Test details and known gaps</summary><p>Verified {esc(gate["date_utc"][:10])} on Linux x86-64: all 14 build and integration checks passed. The libc-test checks use recorded expected-failure lists; individual failures remain in the test results.</p><p><a href="https://github.com/Spaceghost/nelibc/commit/{commit}">Tested source ({commit[:7]})</a> · <a href="{gate_url}/report.md">Results and reproduction</a> · <a href="{gate_url}/gate.json">Run manifest</a> · <a href="{gate_url}/logs.tar.gz">Logs</a></p>'+table('Build and integration checks',['Check','Exit','Seconds'],[[esc(r['target']),str(r['exit']),str(r['seconds'])] for r in gate['results']])+'</details>'
if current_gate:
 block+='<h3 id="integration-gate">Build and integration checks</h3>'
 block+=f'<p>On {esc(current_gate["date_utc"][:10])} the measured revision passed {pass_count} of {len(results)} Makefile targets as an unprivileged user in the x86-64 Linux build guest. Four libc-test targets compare failures with the project’s existing expected-failure lists. The independent corpus above counts each test result directly. <a href="{url}/gate-summary.json">Download the per-target results</a>.</p>'
 block+=table('Build and integration checks',['Target','Exit','Seconds'],[[esc(r['target']),str(r['exit']),str(r['seconds'])] for r in results])
 if (data/'host-ci.json').is_file():
  ci=load('host-ci.json')
  assert ci['measured_revision']==source_commit and re.fullmatch('[0-9a-f]{40}',ci['tested_revision'])
  assert ci['conclusion']=='success' and ci['checks'] and all(step['conclusion']=='success' for step in ci['checks'])
  block+=(f'<p>On {esc(ci["completed_utc"][:10])}, CI on {esc(ci["platform"])} passed the host, Bend, standalone, '
          f'freestanding and generated-C checks at <code>{esc(ci["tested_revision"][:8])}</code>. '
          f'The library source matches the benchmark revision. <a href="{url}/host-ci.json">Fedora check results</a>.</p>')
repeat_name=followup.get('frequency_repeat')
if repeat_name:
 assert re.fullmatch(r'strstr-repeat-[0-9]{8}(?:-[a-z0-9-]+)?', repeat_name)
 repeat_url=url.rsplit('/',1)[0]+'/'+repeat_name
 repeat_dir=data.parent/repeat_name
 manifest=json.loads((repeat_dir/'strstr-repeat-manifest.json').read_text())
 assert manifest['source_commit']=={'previous':meta['previous_commit'],'candidate':source_commit}
 repeat_summary=json.loads((repeat_dir/'strstr-repeat-summary.json').read_text())
block+=f'<div class="performance-summary"><h2 class="section" id="performance">Performance</h2><p class="eyebrow">{date} · Linux x86-64</p>'
if followup.get('headline_case')=='first-sparse-then-dense':
 measured=repeat_summary['first-sparse-then-dense']
 times=measured['median_ns']
 gain=measured['previous_over_candidate']['median']
 block+=(f'<p class="lead">On the 64 KiB substring search that previously favored glibc, Nelibc fell from '
         f'<strong>{times["previous"]/1000:.2f} to {times["candidate"]/1000:.2f} µs</strong> per call. '
         f'Native glibc took {times["baseline"]/1000:.2f} µs. The median paired speedup over the previous Nelibc was {gain:.1f}×.</p>'
         '<p>The input starts with 16 <code>b</code> bytes followed by <code>a</code> bytes and contains no <code>abaa</code>. '
         '<a href="#substring-repeat">Compare all three 64 KiB inputs.</a></p>')
else:
 block+=phase_headline(data, rows)
block+=f'<p>Each profile compares the same consumer with and without Nelibc. Speedups above 1× favor Nelibc. <a href="#all-results">Browse {len(rows)} results across {len(labels)} profiles.</a></p></div>'
block+=render_results(rows, labels, url)
if repeat_name:
 distro_inputs={'first-dense-then-sparse':'16 a bytes, then b bytes', 'first-sparse-then-dense':'16 b bytes, then a bytes','equal-frequency':'Alternating a and b bytes'}
 repeat_rows=[]
 for case,description in distro_inputs.items():
  measured=repeat_summary[case]
  times=measured['median_ns']
  ratio_change=measured['previous_over_candidate']
  repeat_rows.append([description,*[f'{times[k]/1000:.2f}' for k in ('baseline','previous','candidate')],
                      f'{ratio_change["median"]:.2f}×',f'{ratio_change["min"]:.2f}–{ratio_change["max"]:.2f}×'])
 block+='<h3 id="substring-repeat">When the substring is missing</h3>'
 block+=(f'<p>In a separate {manifest["rounds"]}-round repeat, GCC/glibc consumers searched 64 KiB for <code>{esc(manifest["needle"])}</code>. '
         'Each process checked its answers before timing. Each executable ran first, second and third equally often.</p>')
 block+=table('Median microseconds per search · GCC and glibc', ['Input','glibc','Previous Nelibc','Current Nelibc','Previous ÷ current','Observed range'], repeat_rows)
 block+=(f'<p><a href="{repeat_url}/strstr-repeat-64k.csv">Raw 64 KiB samples</a> · '
         f'<a href="{repeat_url}/strstr-repeat-all.csv">All tested sizes</a> · '
         f'<a href="{repeat_url}/reproduce.md">Repeat the measurement</a> · '
         f'<a href="{repeat_url}/strstr-repeat-manifest.json">Run manifest</a></p>')
selected=[('memcpy',4096),('memmove-overlap',128),('memset',4096),('memcmp-equal',128),('memchr-absent',128),('strlen',128),('strcmp-equal',128),('strstr-tail',128),('strtol-decimal',0),('strtod-decimal',0),('sin',0),('sqrt',0),('malloc-free',64),('snprintf-mixed',0),('qsort-128-integers',0),('parse-record',0)]
performance=[]
for case,size in selected:
 performance.append([esc(case)+(f' · {size:,} B' if size else ''),*[ratio(find(p,case,size)) for p in labels]])
if any('previous_ns' in r for r in rows):
 block+='<h3 id="gap-reduction">Optimization follow-up: the previous revision and the measured revision</h3><p>The previous production archives were saved before changing the implementations. Each profile now rotates three builds of the same consumer: libc alone, the previous Nelibc candidate, and the new candidate. This table uses GCC/glibc only. The three builds run in rotating order on the same CPU.</p>'
 improvements=[]
 for case,size in followup.get('cases',[('memcpy',128),('memcpy',1024),('memset',1024),('memcmp-equal',8),('memchr-absent',1024),('strlen',1024),('strcmp-equal',32)]):
  r=find('glibc',case,size)
  improvements.append([esc(case)+(f' · {size} B' if size else ''),f'{r["previous_ns"]:.2f}',f'{r["nelibc_ns"]:.2f}',f'{r["baseline_ns"]:.2f}',f'{r["speedup_vs_previous"]:.2f}×'])
 block+=table('GCC/glibc, seven rotating process triplets; nanoseconds per operation',['Case','Previous Nelibc','New Nelibc','glibc alone','Gain vs previous'],improvements)
 block+='<p>'+esc(followup.get('changes','Changes: bounded head/tail copies and fills, runtime AVX2 paths for mid-size buffers and long strings, word-sized tiny comparisons, and fewer page checks on short strings. Read-only queries carry C purity metadata; operations that write memory or errno retain their effects.'))+' The timed wrappers keep calls observable, so these gains measure the implementations. Slower cases and all raw samples remain below.</p>'
 for case,size in followup.get('tradeoffs', [('memset',8),('memchr-absent',8)]):
  r=find('glibc',case,size)
  block+=f'<p class="small muted">Tradeoff: {esc(case)}({size}) measured {r["previous_ns"]:.2f} → {r["nelibc_ns"]:.2f} ns; glibc alone {r["baseline_ns"]:.2f} ns.</p>'
 if (data/'strcmp-distribution.json').exists():
  r=next(r for r in load('strcmp-distribution.json') if r['bytes']==65536 and r['left_offset']==r['right_offset']==0 and r['case']=='equal')
  ns=r['median_ns']
  block+=f'<p class="small muted">The separate alignment consumer measured equal 64 KiB strcmp at offsets (0,0): previous {ns["previous"]:.2f}, new {ns["candidate"]:.2f}, glibc {ns["baseline"]:.2f} ns. Long-string results differ between consumers; the headline gains do not mean every case improved.</p>'
 evidence_links=[('validation.json','Independent numerical and guard-page checks'),('optimization-notes.md','Optimization notes and verification'),('strcmp-distribution.json','String alignment/mismatch results'),('memory-distribution.json','Memory alignment results'),('scan-distribution.json','Length/search alignment and match positions'),('previous-source.tar.gz','Previous candidate source'),('strstr-distribution.csv','Substring input distributions'),('strstr-phase-controls.csv','Changing-byte-frequency controls'),('before-summary.csv','Pre-change run on the build host'),('before-raw.csv','Pre-change raw pairs'),('before-manifest.json','Pre-change build manifest'),('reproduce.md','Reproduce this comparison'),('preliminary-conformance.json','Earlier candidate under I/O load')]
 block+='<p>'+' · '.join(f'<a href="{url}/{file}">{label}</a>' for file,label in evidence_links if (data/file).exists())+'</p>'
 if source_commit:
  block+=f'<p>Measured revisions: <code>{esc(meta["previous_commit"][:12])}</code> before the change and <code>{esc(source_commit[:12])}</code> after it. The manifest identifies each linked archive by SHA-256.</p>'
 else:
  block+='<p><a href="/nelua/assets/comparison-20261117/manifest.json">Original comparison manifest</a>. '+('The dated comparison snapshots remain the exact sources measured; the integrated tree also includes the build, test and benchmark fixes recorded in the full gate above.' if gate else 'The new source is still an unmerged candidate; the repository’s full integration gate remains separate from these focused checks and the independent corpus.')+'</p>'
block+=table('Representative cases, median of seven paired speedups', ['Case','glibc → +Nelibc','musl/Zig → +Nelibc','Cosmopolitan → +Nelibc'],performance)
block+=f'''<p class="small muted">{meta['pairs']} comparison rounds ({'rotating triplets with the previous candidate' if 'previous_archive_sha256' in meta else 'alternating pairs'}), rotating profile order. Each timed loop runs for at least 5 ms after calibration. Consumer flags include <code>-O2 -fno-builtin</code>; volatile pointers to noinline direct-call wrappers stop pure-function calls being hoisted out of the loop. The same wrappers are used in every profile. Taking the address of Cosmopolitan 4.0.2’s strstr IFUNC failed in this toolchain; direct calls passed, so this measures the direct-call path and does not establish function-pointer ABI conformance. Loop, pointer-call and checksum overhead is included equally, not subtracted. Buffers are hot and aligned; this is not a DRAM bandwidth, cold-cache, multicore or application throughput result. The record parser is a synthetic combined workload; qsort includes initializing its input, and malloc/free includes writing the first and last byte.</p>
'''
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
if source_commit:
 block+=f'<p>Tested Nelibc commit <code>{esc(source_commit)}</code> on {esc(meta["cpu_model"])} with CPU {meta["cpu"]} affinity. The public data include raw samples, linked archive hashes and reproduction commands.</p>'
else:
 block+=f'<p>Nelibc base <code>{esc(meta["source_base"][:12])}</code> plus the captured Cosmopolitan, optimization and comparison changes. The source archive and manifest preserve the exact inputs, compiler commands and archive hashes; these results do not claim to be from unchanged upstream main.</p>'
block+='<p>The conformance data record every planned public corpus test for both halves of each pair. Cosmopolitan executables use the APE loader. <a href="https://repo.or.cz/libc-test.git/tree/'+esc(conf['libc_test_commit'])+'">Pinned upstream test source</a>.</p>'
block+='<div class="actions">'+''.join(f'<a class="button button-ghost" href="{url}/{file}">{label}</a>' for file,label in [('summary.csv','Performance CSV'),('raw.csv','Raw paired runs'),('checks.json','Consumer correctness checks'),('conformance.json','Conformance results'),('conformance-logs.tar.gz','Test diagnostics'),('deltas.json','Conformance deltas'),('coverage.json','Export census'),('manifest.json','Run manifest'),('source.tar.gz','Exact source + harness'),('reproduce.md','Reproduction instructions')] if (data/file).is_file())+'</div>'
size_rows=[]
for profile in labels:
 size_rows.append([labels[profile],f'{meta["binary_bytes"][profile]["baseline"]:,}',f'{meta["binary_bytes"][profile]["nelibc"]:,}','Dynamic system libc' if profile=='glibc' else 'Static'])
block+='<details><summary>Built consumer file sizes</summary>'+table('Unnormalized executable file bytes, as built',['Profile','Alone bytes','+Nelibc bytes','Link mode'],size_rows)+'<p>These are not normalized release sizes. The dynamic glibc executable excludes its shared libraries; symbols, debug information, archive granularity and static runtimes affect these files. No footprint winner is claimed.</p></details>\n'
if gate:block=block.replace('The snapshot includes the new profile; it is not a claim that these changes have landed on upstream main.', 'The new profile and measured optimizations are now integrated on main; the dated source archive below preserves the exact comparison snapshot.')
if source_commit:
 block=block.replace("Cosmopolitan is the default hybrid build in the captured source snapshot and intentionally owns more of its runtime. The snapshot includes the new profile; it is not a claim that these changes have landed on upstream main. Its narrower Nelibc count does not mean the executable cannot call the delegated APIs.", "Cosmopolitan is the default hybrid build at the measured revision. Its archive supplies many APIs directly. The table shows which symbols Nelibc supplies when added to each runtime.")
content = ROOT / 'src/content'
(content / 'nelibc-comparison.html').write_text(block.rstrip() + '\n')
stats = ''.join(f'<span><strong>{coverage[p]["nelibc_exports"]:,} / {coverage[p]["inventory_total"]:,}</strong> exports · {labels[p]}</span>' for p in labels)
(content / 'nelibc-stats.html').write_text(stats + f'<span>comparison {date}</span>\n')
parser='; '.join(labels[p]+f' {find(p,"parse-record")["speedup"]:.2f}×' for p in labels)
overview=f'''<h2 class="section" id="libc-comparison">Nelibc benchmarks</h2>
<p class="lead">The goal is the fastest correct implementation of the libc operations programs use most. The current evidence compares glibc, musl and Cosmopolitan, each alone and with Nelibc, on the same host and consumer.</p>
<div class="grid grid-3">
<article class="card card-core"><h3>Completion</h3><p>{'; '.join(labels[p]+': <strong>'+str(coverage[p]['nelibc_exports'])+'</strong>' for p in labels)} of {next(iter(coverage.values()))['inventory_total']:,} tracked names exported by Nelibc. These count owned implementations, not standards compliance. Cosmopolitan deliberately delegates more stateful services.</p></article>
<article class="card card-core"><h3>Conformance</h3><p>{'; '.join(labels[p]+': <strong>'+str(conf['profiles'][p+'-baseline']['counts']['pass'])+' → '+str(conf['profiles'][p+'-nelibc']['counts']['pass'])+'</strong> passes' for p in labels)} in the matched functional, regression and math corpus. Build failures, runtime failures and newly failing tests are all reported.</p></article>
<article class="card card-core"><h3>Performance</h3><p>Synthetic record parser, baseline time ÷ Nelibc time: {parser}. Above 1× is faster. The detailed results include memory, strings, conversion, math, allocation, formatting and sorting, including slower cases and delegated calls.</p></article>
</div>
<p class="small muted">Measured {date} over {meta['pairs']} comparison rounds. Consumer correctness checks passed before timing.</p>
<div class="actions"><a class="button" href="/nelua/nelibc/#performance">Inspect the matched results</a><a class="button button-ghost" href="/nelua/nelibc/#profiles">See the five runtime arrangements</a></div>
'''
if any('previous_ns' in r for r in rows):
 gains='; '.join(case+(('('+str(size)+')') if size else '')+' '+f'{find("glibc",case,size)["speedup_vs_previous"]:.2f}×' for case,size in followup.get('overview_cases',[('memcpy',1024),('memset',1024),('strlen',1024)]))
 overview=overview.replace('<div class="actions">','<p><strong>Optimization follow-up:</strong> '+gains+' compared with the previous Nelibc build in the paired GCC/glibc run. The complete results and input distributions are on the <a href="/nelua/nelibc/#gap-reduction">detailed page</a>.</p><div class="actions">',1)
if followup.get('overview_scope'):
 overview=overview.replace('The complete results and input distributions', esc(followup['overview_scope'])+' The complete results and input distributions')
if gate or current_gate:overview=overview.replace('<div class="actions">',gate_note+'<div class="actions">',1)
(content / 'nelibc-overview.html').write_text(overview.rstrip() + '\n')
print('Refreshed Nelibc comparison fragments from', data)

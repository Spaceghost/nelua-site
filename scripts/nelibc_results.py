"""Verify matched timing rows, then render the searchable benchmark index."""
from collections import defaultdict
import csv
from html import escape
from math import isclose
from statistics import median


def verify_timings(data, rows):
    samples = defaultdict(dict)
    with (data / 'raw.csv').open() as raw:
        for item in csv.DictReader(raw):
            key = (item['profile'], item['case'], int(item['bytes']), int(item['pair']))
            name = item['implementation']
            if name in samples[key]:
                raise ValueError(f'Duplicate sample {key}, {name}')
            samples[key][name] = float(item['ns_per_op'])

    for row in rows:
        group = (row['profile'], row['case'], row['bytes'])
        pairs = [samples.pop((*group, n)) for n in range(1, row['pairs'] + 1)]
        def verify(field, expected):
            if not isclose(row[field], expected, rel_tol=1e-12):
                raise ValueError(f'{group}: {field} disagrees with raw samples')
        verify('nelibc_ns', median(p['nelibc'] for p in pairs))
        references = [('baseline', 'speedup', 'ratio_min', 'ratio_max')]
        if 'previous_ns' in row:
            references.append(('previous', 'speedup_vs_previous', 'previous_ratio_min', 'previous_ratio_max'))
        for name, middle, low, high in references:
            ratios = [p[name] / p['nelibc'] for p in pairs]
            verify(name + '_ns', median(p[name] for p in pairs))
            verify(middle, median(ratios))
            verify(low, min(ratios))
            verify(high, max(ratios))
    if samples:
        raise ValueError('Unreported samples in raw.csv')


def outcome(row):
    if row['ratio_min'] > 1:
        return 'faster'
    if row['ratio_max'] < 1:
        return 'slower'
    return 'overlap'


def phase_headline(data, rows):
    source = data / 'strstr-phase-controls.csv'
    if not source.exists():
        return ''
    tail = next(r for r in rows if (r['profile'], r['case'], r['bytes']) == ('glibc', 'strstr-tail', 65536))
    controls = defaultdict(dict)
    with source.open() as handle:
        for row in csv.DictReader(handle):
            if (row['compiler'], row['libc'], row['case'], row['haystack_bytes'], row['needle_bytes']) != (
                    'gcc', 'glibc', 'first-sparse-then-dense', '65536', '4'):
                continue
            sample = controls[int(row['round'])]
            name = row['implementation']
            if name in sample:
                raise ValueError('Duplicate phase-control sample')
            sample[name] = float(row['median_ns_per_call'])
    if set(controls) != {1, 2, 3, 4}:
        raise ValueError('Missing phase-control round')
    changed = median(p['candidate'] for p in controls.values()) / 1000
    native = median(p['baseline'] for p in controls.values()) / 1000
    return (f'<p class="lead"><strong>The revised substring search was {tail["speedup_vs_previous"]:.2f}× faster '
            f'than previous Nelibc</strong> when <code>aaaaz</code> matched at the end of a 64 KiB buffer '
            f'filled with <code>a</code> bytes and one final <code>z</code>. The GCC/glibc median fell from {tail["previous_ns"]/1000:,.2f} to '
            f'{tail["nelibc_ns"]/1000:,.2f} µs per call.</p>'
            f'<p>On a 64 KiB miss, searching for <code>abaa</code> through 16 <code>b</code> bytes followed by '
            f'<code>a</code> bytes took <strong>{changed:,.2f} µs with Nelibc and {native:,.2f} µs with glibc '
            f'alone</strong>. The frequency of the bytes in the input changes the cost of finding a match.</p>')


def render_results(rows, labels, url):
    total = len(rows)
    rounds = {r['pairs'] for r in rows}
    if len(rounds) != 1:
        raise ValueError('Expected the same number of pairs for each case')
    count = rounds.pop()
    owned = [r for r in rows if r['ownership'] == 'Nelibc export']
    wins = sum(outcome(r) == 'faster' for r in owned)
    losses = sum(outcome(r) == 'slower' for r in owned)
    chunks = [f'<section class="explorer" id="benchmark-results" aria-labelledby="all-results">'
              f'<h3 id="all-results">All {total} benchmark results</h3>'
              f'<p>Of {len(owned)} cases that called a Nelibc export, {wins} ran faster than their native libc '
              f'in all {count} rounds, {losses} ran slower in every round, and {len(owned)-wins-losses} had an '
              f'observed range that included 1×. Each case has equal weight here.</p>'
              f'<p>Times are median nanoseconds per call. Speedup is the median of the paired native time divided '
              f'by the Nelibc time. The range shows the smallest and largest paired ratios. '
              f'<a href="{url}/summary.csv">Download the results (CSV)</a> · '
              f'<a href="{url}/raw.csv">Raw matched samples</a></p>']
    options = ''.join(f'<option value="{escape(key)}">{escape(name)}</option>' for key, name in labels.items())
    chunks.append('<div class="controls" id="benchmark-filters" hidden>'
                  '<label>Case <input type="search" id="benchmark-query" placeholder="e.g. strstr"></label>'
                  '<label>Profile <select id="benchmark-profile"><option value="">All profiles</option>'
                  + options + '</select></label><label>Outcome <select id="benchmark-outcome">'
                  '<option value="">All outcomes</option><option value="faster">Faster in every round</option>'
                  '<option value="slower">Slower in every round</option><option value="overlap">Range includes 1×</option>'
                  '</select></label><button class="button button-ghost" type="button" id="benchmark-clear">Clear</button>'
                  '</div><p id="benchmark-count" role="status" hidden></p>')
    for profile, label in labels.items():
        subset = [r for r in rows if r['profile'] == profile]
        chunks.append(f'<details data-benchmark-profile="{escape(profile)}"><summary>{escape(label)} · '
                      f'<span data-count>{len(subset)}</span> results</summary>'
                      f'<div class="table-wrap" tabindex="0" role="region" aria-label="{escape(label)} timings">'
                      f'<table><caption>{escape(label)} with and without Nelibc</caption><thead><tr>')
        for col in ('Case', 'Input bytes', 'Native ns/op', '+ Nelibc ns/op', 'Speedup', 'Observed range', 'Implementation'):
            chunks.append(f'<th scope="col">{col}</th>')
        chunks.append('</tr></thead><tbody>')
        for r in subset:
            size = f'{r["bytes"]:,}' if r['bytes'] else '—'
            chunks.append(f'<tr data-case="{escape(r["case"])}" data-outcome="{outcome(r)}">'
                          f'<th scope="row">{escape(r["case"])}</th><td>{size}</td>'
                          f'<td>{r["baseline_ns"]:,.2f}</td><td>{r["nelibc_ns"]:,.2f}</td>'
                          f'<td>{r["speedup"]:.3g}×</td>'
                          f'<td>{r["ratio_min"]:.3g}–{r["ratio_max"]:.3g}×</td><td>{escape(r["ownership"])}</td></tr>')
        chunks.append('</tbody></table></div></details>')
    chunks.append('</section>')
    return ''.join(chunks)

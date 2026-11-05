#!/usr/bin/env python3
"""Regenerate public/nelua/assets/nelibc-coverage.json from a nelibc checkout.

Usage: python3 scripts/coverage.py [path/to/nelibc]   (default: ../nelibc)
"""
import csv, json, sys, datetime, collections
root = sys.argv[1] if len(sys.argv) > 1 else '../nelibc'
rows = list(csv.DictReader(open(f'{root}/docs/musl-1.2.5-api-coverage.csv', newline='')))
out = [[r['api'], r['musl_headers'], r['status'], r['nelibc_exports']] for r in rows]
json.dump({'source': 'Spaceghost/nelibc docs/musl-1.2.5-api-coverage.csv',
           'generated': datetime.date.today().isoformat(), 'rows': out},
          open('public/nelua/assets/nelibc-coverage.json', 'w'), separators=(',', ':'))
counts = collections.Counter(r[2] for r in out)
print(len(out), dict(counts))
print('update the summary numbers in public/nelua/nelibc/index.html and index.html if they changed')

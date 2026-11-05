# Nelua field notes

A compact, interactive guide to Nelua in working systems. Nelibc leads; Atlas firmware and Atlas Webware show two more places where Nelua owns real native logic.

## Local preview

Serve `dist/` with any static HTTP server. The site has no package install or build step.

```sh
python3 -m http.server 8080 --directory dist
```

Open `http://localhost:8080/`. The Nelibc page is at `/nelibc/`.

## Coverage data

`dist/assets/api-coverage.json` is generated from the pinned musl 1.2.5 symbol inventory in `Spaceghost/nelibc`. Refresh it from a current checkout with:

```sh
python3 - <<'PY'
import csv, json
with open('../nelibc/docs/musl-1.2.5-api-coverage.csv', newline='') as source:
    rows = csv.DictReader(source)
    data = [{'api': r['api'], 'status': r['status'], 'exports': r['nelibc_exports']} for r in rows]
with open('dist/assets/api-coverage.json', 'w') as output:
    json.dump(data, output, separators=(',', ':'))
PY
```

## Domain path

`edge/spacegho-st-router.js` is the Cloudflare Worker source for the narrow `spacegho.st/langs/nelua*` route. It forwards that path to the public Sites deployment and redirects the former `/lang/nelua*` path to its new location. Other host paths keep their existing routes.

## Design

The visual direction adapts the warm-black, kinpaku-gold and verdigris-patina palette from [Impeccable](https://github.com/pbakaus/impeccable), under its Apache-2.0 license. The page is buildless HTML, CSS, and JavaScript.

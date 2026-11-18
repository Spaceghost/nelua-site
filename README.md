# nelua-site

The pages at [spacegho.st/nelua](https://spacegho.st/nelua/): the Nelua core
ecosystem (the compiler fork, nelibc, nebox), the workshop libraries built on
it, and the wider Nelua world.

## Layout

```
public/nelua/            the site, served as-is (index, compiler/, nelibc/, nebox/, 404)
public/nelua/assets/     site.css, icon.svg, explorer.js (built), nelibc-coverage.json (generated)
public/_headers          caching and security headers for the asset route
src/explorer.imba        the nelibc coverage explorer (Imba), the coverage explorer script
scripts/coverage.py      regenerates nelibc-coverage.json from a nelibc checkout
scripts/place.mjs        copies the Imba bundle to its fixed public path
legacy/                  the earlier field-notes site that lived under /langs/nelua
```

Everything is static. The Worker has no script: `wrangler.toml` declares only
the assets directory and the two `spacegho.st/nelua*` routes, so page views are
static-asset requests on the free tier.

## Work on it

```sh
npm install
npm run build          # src/explorer.imba -> public/nelua/assets/explorer.js
npm run guide -- ../nelua-lang/docs/pages/syntax-extensions.md  # refresh the static syntax guide
python3 -m http.server 8080 --directory public   # http://localhost:8080/nelua/
```

## Refresh the numbers

- Coverage: `python3 scripts/coverage.py ../nelibc`, then update the three
  summary counts in `public/nelua/nelibc/index.html` and the hero line in
  `public/nelua/index.html`.
- nebox: applet list, case count and binary size come from the last recorded
  container run in the nebox repository's commit messages.
- Compiler: the additions list mirrors "Fork additions" in the fork's README.

The syntax guide at `public/nelua/compiler/syntax-extensions/` is generated from
the compiler's `docs/pages/syntax-extensions.md` with `npm run guide`. The generated
HTML is committed, so normal site builds need no compiler checkout. Refresh it
when the canonical guide changes; the renderer adds the contents navigation and
uses the shared static stylesheet.

## Deploy

```sh
npm run deploy         # wrangler deploy, needs a wrangler login
```

## Design

Same ink/gold family as the rest of spacegho.st (see the melodica minisite):
system fonts only, nothing fetched from another origin, no inline styles, a
light scheme under `prefers-color-scheme: light`.

## Refresh the matched libc comparison

Build and run `benchmarks/comparison/run.py` and `conformance.py` from Nelibc
on its prescribed Bak container. Preserve each libc-only baseline alongside
its Nelibc-linked consumer; do not convert expected failures into passes.
Copy the recorded results into a new dated `public/nelua/assets/comparison-*`
directory, with the exact source snapshot and commands, then run:

```sh
python3 scripts/nelibc-comparison.py public/nelua/assets/comparison-YYYYMMDD
npm run build
npm run check
npm run deploy
```

The renderer updates completion, conformance and performance on both the
landing page and the Nelibc page. Historical coverage and standalone gates
remain labelled with their original dates. `summary.json` is the per-case
performance summary; `raw.csv` retains alternating pairs. `conformance.json`
retains every planned test, including build/link failures, runtime failures,
timeouts and new regressions. Keep the methodology and any loader/toolchain
limitations beside the numbers. Delegated calls are not Nelibc speed wins.

Before copying the result files, run `scripts/nelibc-runtime-census.py` on the
build host with `--root` pointing to Nelibc, `--results` to the comparison
output, `--zig-cache` to that run's Zig cache and `--cosmo-library` to its
x86-64 `libcosmo.a`. It adds the baseline/combined runtime name census and
records library hashes. Include Zig's `libzigc.a` and `libcompiler_rt.a`;
counting only its musl `libc.a` would falsely report math APIs as missing.
The table counts symbol presence, not independent linkability or conformance.


## Community source index

[spacegho.st/nelua/community](https://spacegho.st/nelua/community/) ranks indexed
public repository owners by current original `.nelua` source lines. The dated
snapshot includes pinned commits, per-file blob identities, generated/vendor
exclusions, exact deduplication, source totals and failed collection requests.

The page and its profile thumbnails are same-origin static assets. It uses the
site's system-font policy and existing strict CSP; no external browser fetches
or inline styles/scripts are needed. Source attribution is to repository owners,
not individual line authors. Refresh with a task-specific cache directory:

```sh
python3 scripts/community-update.py --candidates scripts/community-candidates.json --output public/nelua/community/data.json --cache-dir "$COMMUNITY_CACHE_DIR"
python3 scripts/community-assets.py --directory public/nelua/community --no-fonts
```

The snapshot is a current indexed sample, not an exhaustive GitHub census.
Numbers and snapshot date travel together in `data.json`. No scheduled refresh
is configured.

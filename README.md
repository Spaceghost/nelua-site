# nelua-site

The pages at [spacegho.st/nelua](https://spacegho.st/nelua/) cover the Nelua
compiler fork, nelibc, nebox, necc, nelinker, nebuild, and neboot. Workshop
covers projects built on Core, including Theseus Init and Cascadia's developer
image. World covers the wider Nelua community.

## Layout

```
src/site.imba            shared page layout and static HTML renderer
src/pages/               Imba source for every public page
src/content/             generated syntax-guide and benchmark fragments
src/community/           community index and account controls in Imba
src/explorer.imba        Nelibc coverage explorer
src/*.css                shared and community styles
public/nelua/            committed HTML, CSS, JavaScript and recorded data
public/_headers          caching and security headers for the asset route
legacy/                  earlier field-notes site, outside the served directory
```

Cloudflare serves the committed files from `public/` as static assets. The
separate community API is documented below.

## Work on it

```sh
npm ci
npm run build
python3 -m http.server 8080 --directory public   # http://localhost:8080/nelua/
```

Edit pages and browser behavior under `src/`. Run `npm run build` and commit
the source and generated changes together. `npm run render` is enough for
page, style and content-only edits once the browser bundles exist.

## Refresh the numbers

- Coverage: `python3 scripts/coverage.py ../nelibc` refreshes the explorer data.
  Update the pinned summary in `src/pages/nelibc.imba` if its source run changes.
- nebox: applet list, case count and binary size come from the last recorded
  container run in the nebox repository's commit messages.
- Compiler: the additions list mirrors "Fork additions" in the fork's README.

To refresh the syntax guide and its table of contents from the canonical
compiler checkout, run the following commands and commit both sets of outputs:

```sh
npm run guide -- ../nelua-lang/docs/pages/syntax-extensions.md
npm run render
```

## Theseus browser demo

Use `npx wrangler dev` to preview `/nelua/init/`. QEMU's WebAssembly
threads require the cross-origin isolation headers in `public/_headers`.
The emulator, firmware, kernel and initramfs load when the visitor starts
the VM. The guest has no network device.

The demo controller is in `src/theseus-demo.imba`. The boot assets under
`public/nelua/init/vm/` are served directly, with source and license
references in `NOTICES.txt`. To refresh the guest, build Nebox with Theseus
enabled, package the binary alone with `write_initramfs` from Nebox's
`tests/theseus_boot.py`, then compress the archive with `gzip -n`. Test the
new image by running the mount example from the browser console.

## Deploy

Deploy from a checkout containing the committed static assets:

```sh
npm run check
npm run deploy
```

Wrangler uploads `public/` directly using the existing Cloudflare login.

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

The comparison script refreshes the evidence fragments in `src/content/`.
The Imba build incorporates them into the overview and Nelibc pages. Historical coverage and standalone gates
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
or inline styles/scripts are needed. Public source attribution is to repository
owners. Refresh with a task-specific cache directory:

```sh
python3 scripts/community-update.py --candidates scripts/community-candidates.json --output public/nelua/community/data.json --cache-dir "$COMMUNITY_CACHE_DIR"
python3 scripts/community-assets.py --directory public/nelua/community --no-fonts
```

The snapshot is a current indexed sample, not an exhaustive GitHub census.
Numbers and snapshot date travel together in `data.json`.

### Daily refresh

[GitHub Actions](https://github.com/Spaceghost/nelua-site/actions/workflows/community.yml)
refreshes the index daily at **07:17 America/Los_Angeles**, including daylight
saving time. `workflow_dispatch` also provides a Run workflow button. The job
uses the existing admitted `fedora-std` self-hosted pool, with the `nelua-site`
repository label, owner-only actor admission, no fork events, serialized runs,
and no hosted fallback. The former Bak cron entry is removed during migration;
its launcher remains available for attended public-only maintenance.

Refreshes run once daily. A prominent notice above the repository choices
states the 7:17 a.m. Pacific schedule; new projects and saved changes join the
next daily scan. Saving choices does not start a separate refresh. The browser
does not poll for pending totals. Consent changes and opt-out still take effect
immediately.

The workflow validates consent boundaries, collects current public default
branches, checks coverage and deduplication, pushes the dated public snapshot
normally to `main`, deploys static assets, and checks the live JSON hash. Failed
public collection or validation keeps the previous published snapshot. A
concurrent source change stops the run. Private counting follows public
publication. Seven-day Actions artifacts contain only the **public** report,
log and snapshot. The job token supplies repository access; the existing
Cloudflare deploy credential is encrypted in `CLOUDFLARE_API_TOKEN`.

### GitHub sign-in and private project consent

The public site remains assets-only. `community-api/` is a separate Worker at
`/nelua/community/api/*`, with its own D1 database. Sign-in uses the existing
`spaceghost-auth` GitHub provider, PKCE, a one-use state and nonce, signed
ES256 tokens and an audience-specific immutable GitHub ID. Community session
cookies are Secure, HttpOnly and SameSite=Lax; writes require same-origin CSRF
checks. Other shared-auth clients retain their existing token contract.
URL-bearing invocation logs and automatic trace sampling are disabled because
OAuth callback URLs contain one-use codes. Structured errors omit queries,
private metadata and credentials.

The owner signs in and chooses **Enable private repository access** once to
create the read-only GitHub App using GitHub's manifest approval form. App keys
and webhook secrets stay encrypted in D1 with the Worker's `ENCRYPTION_KEY`
secret. Each person installs it on selected repositories, then explicitly
chooses which owned private, non-fork projects may contribute aggregate totals.
Private organizations are not included by this personal-account opt-in.

Expired installation callbacks offer a same-origin, CSRF-protected confirmation
to finish the existing GitHub installation. The App API verifies its numeric
owner before linking it. Reopening a completed callback preserves saved choices
and consent. GitHub requests use manual redirect handling: Workers does not
support `redirect: "error"`, and redirects must not forward App credentials.

Only the admitted default-branch Actions workflow can request private scan
tasks, using a verified GitHub OIDC identity pinned to the repository ID, owner,
workflow file, branch, event and self-hosted environment. Each task gets a
one-hour, read-only installation token restricted to the selected repository
IDs. The Python collector holds private source in memory: no disk cache,
repository names, paths, source, tokens or blob IDs enter public snapshots,
logs or artifacts. Source hashes, the public lexer, generated/vendor exclusions
and exact deduplication apply. Public blobs count first; private copies are
assigned in stable GitHub account-ID order and then repository creation order.
This deduplication rule does not establish provenance.

Private totals count only current default-branch code lines attributed by
GitHub blame to commits whose **author's immutable GitHub ID** matches the
participating owner. Committers and pushers do not receive author credit.
Other authors and unlinked identities are excluded. The lexer counts nonblank,
non-comment `.nelua` lines at their physical Git line numbers; byte totals cover
the owner's attributed physical source lines, including their comments. Blame
uses the same pinned commit as the verified source and credits each line's
most recent author, rather than proving its original creator. Missing or incomplete
attribution fails the whole account's refresh. The API accepts and displays
only `current-authored-nelua-v1` results, so older repository-size totals cannot
appear as authored counts. This measures surviving code, not historical churn
or every commit ever made.

For an owner-requested personal check of all private, non-fork repositories,
run `python3 scripts/community-private.py --audit-owned` with the owner's
existing `gh` authentication. It scans repository trees regardless of their
primary language, holds all private material in memory, and prints aggregate
coverage and authored totals only. It neither publishes those results nor
changes site consent or repository selections.

The public API returns only opted-in owner identities and combined totals,
which the page labels as private. The downloadable public audit stays separate.
Revoking consent or deleting a community account removes its private totals
immediately. Signed GitHub installation/access-change webhooks invalidate
consent and counts; a version check prevents a scan already in flight from
restoring revoked totals. Private counts expire from display after 36 hours
without a successful refresh. Signing out keeps saved counting preferences.

Validate with `node --test community-api/tests/security.test.mjs` and
`python3 scripts/test-community-private.py`. Deploy API source separately with
`wrangler deploy --config community-api/wrangler.jsonc --strict --keep-vars`;
apply its D1 migrations first when the schema changes. Generate binding types
with `wrangler types --config community-api/wrangler.jsonc` after binding changes.
Never rotate `ENCRYPTION_KEY` without migrating its encrypted records.

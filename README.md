# nelua-site

The pages at [spacegho.st/nelua](https://spacegho.st/nelua/): the Nelua core
ecosystem (the compiler fork, nelibc, nebox), the workshop libraries built on
it, and the wider Nelua world.

## Layout

```
public/nelua/            the site, served as-is (index, compiler/, nelibc/, nebox/, 404)
public/nelua/assets/     site.css, icon.svg, explorer.js (built), nelibc-coverage.json (generated)
public/_headers          caching and security headers for the asset route
src/explorer.imba        the nelibc coverage explorer (Imba), the only script on the site
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

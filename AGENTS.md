# Agent notes

- Static site only. Do not add a Worker script, D1, KV or external fetches;
  the point is to stay on static assets.
- Every number on the pages must trace to a recorded run (nelibc gate, nebox
  container run, fork README). Update the number and its date together, or
  leave both alone.
- No inline styles or scripts: the CSP in `public/_headers` forbids them.
- Keep the three-ring split: Core covers the compiler, nelibc, nebox, necc,
  nelinker, nebuild, and this site's documentation. Workshop covers projects
  built on Core, including Theseus Init. World covers upstream and community.
- `legacy/` is the previous site kept for reference; it is not served.

- Owner-authorized exception, 2026-11-18: `community-api/` is the separate
  sign-in and private-project consent Worker, routed only at
  `/nelua/community/api/*`. The main `nelua-site` Worker stays assets-only.
  Private names, paths, source, tokens and per-file identifiers must never enter
  public snapshots, logs or Actions artifacts. Private source is measured only
  by the admitted default-branch Actions workflow, with explicit per-user consent.
  Owner-requested personal audits may also use the owner's existing GitHub
  authentication in memory. They report aggregates only and do not publish
  results or change anyone's repository selection or consent.

# Agent notes

- Static site only. Do not add a Worker script, D1, KV or external fetches;
  the point is to stay on static assets.
- Every number on the pages must trace to a recorded run (nelibc gate, nebox
  container run, fork README). Update the number and its date together, or
  leave both alone.
- No inline styles or scripts: the CSP in `public/_headers` forbids them.
- Keep the three-ring split: core (compiler, nelibc, nebox) depends on nothing
  outside itself; workshop depends on core; world is upstream and community.
- `legacy/` is the previous site kept for reference; it is not served.

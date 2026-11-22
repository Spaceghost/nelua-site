# Browser Life

Imba paints the board. Its Step button calls the Nelua WebAssembly export
`next_row` for each row. Each call invokes Bend’s JavaScript export
`survives` once for each of the row’s 16 cells.

## Build

Use the Spaceghost Nelua fork at 874acdd1049a35bc5d8d631d9ddb573d127fc32b
(with nelua.bend2lower), Bend 2.0.40, Zig 0.17.0, Node.js and Imba
2.0.0-alpha.253. The fork requires repository access. Build on Linux with
the tools on PATH, or set NELUA and NELUA_BEND to absolute executable paths.
From the site root, install the locked dependencies with npm ci and run:

    examples/browser-life/build.sh
    npm run render

For the standalone starter, extract starter.tar.gz into an empty directory
and run these commands there:

    npm install --save-exact imba@2.0.0-alpha.253
    examples/browser-life/build.sh
    python3 -m http.server --directory public/nelua/examples/life 8000

Open http://localhost:8000/. The standalone build uses the included index.html
and the same compiler inputs as the live board.

## Use the bridge in another project

Load the file-local syntax module with `#syntax 'syntax.bendjs'` and add its
parent directory to the compiler search path with -L. In one bendjs block,
list the functions the Wasm guest calls. Their bodies use the existing
Bend2 Nelua subset (pure uint32 functions). Calls become C imports;
Bend compiles the lowered functions into an ES module. Unsigned 32-bit values
cross the Wasm JavaScript boundary as i32 bit patterns. Normalize incoming JS
arguments with >>> 0 before calling Bend for values above 0x7fffffff.

The script sets NELUA_BENDJS_SOURCE to a fresh staging file, checks the
generated module’s import list and tests every three-by-three neighborhood
before copying the browser artifacts. See board.imba for instantiation and
the outputs life.c, rule.bend and rule.mjs for each compiler stage.

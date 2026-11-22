# Example workbench

From the site root, run `examples/workshop/build.sh`, then `npm run render`.
Use the same Nelua fork, Bend, Zig and Imba versions as the browser-life
starter. The build fetches the pinned upstream inputs listed in the script.
It compiles the targets in a fresh directory and executes the resulting
modules before updating the committed static assets.

* Drift’s opcode declarations come from c970832. The browser demonstration
  looks up those constants in Wasm and packs the four instruction-header
  bytes using a Bend-generated ES module. It does not execute driver code.
* The arena is linked from the original Melodica extension source at
  8b5750b, with only the four allocator entry points exposed.
* The three standalone programs use Zig’s WASI libc. The small host in
  wasi.mjs implements the argument and console operations those programs use.
* The Theseus C excerpt is generated for Linux using the original source at
  72095fd and a call-site harness. The live system uses the site's existing VM.

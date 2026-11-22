#!/bin/sh
# Generate and verify first, then publish the artifacts consumed by npm run render.
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
stage=$(mktemp -d "${TMPDIR:-/tmp}/nelua-workshop.XXXXXXXX")
trap 'rm -rf "$stage"' EXIT
cd "$stage"
mkdir snippets
nelua=${NELUA:-nelua}
app="$root/examples/workshop"
dest="$root/public/nelua/examples/workshop"
source_url=https://raw.githubusercontent.com/Spaceghost
fetch() { curl -fsSL --retry 2 "$1" -o "$2"; }
theseus=72095fd70e77da93fada45686459985cee5429d3
melodica=8b5750bd67d9fcd54d6c33a85686b95bdfa60fbd
fetch "$source_url/theseus-init/$theseus/src/theseus/earlyboot.nelua" earlyboot.nelua
# Reference the entry point so the C generator retains it. This harness only emits C.
printf '\ntheseus_boot.init({})\n' >> earlyboot.nelua
"$nelua" -c --cache-dir cache -o earlyboot.c earlyboot.nelua
sed -n '/^  unsigned long flags = ((MS_NODEV/,/starting console shell/p' earlyboot.c > snippets/boot.c
for file in melodica_core pi_hex; do
  fetch "$source_url/melodica.h/$melodica/apps/melodica-extension/core/$file.nelua" "$file.nelua"
done
"$nelua" -c --target wasm32-freestanding --cc 'zig cc' --cache-dir cache -o arena.c melodica_core.nelua
zig cc -target wasm32-freestanding -Oz -fwrapv -fno-strict-aliasing -c arena.c -o arena.o
zig build-exe arena.o -target wasm32-freestanding -O ReleaseSmall -fno-entry --export=mx_alloc --export=mx_reset --export=mx_arena_used --export=mx_arena_capacity -femit-bin=arena.wasm
sed -n '/^nluint8_arr0_ptr mx_alloc(.*) {$/,/^}$/p' arena.c > snippets/arena.c
for name in c-call comptime point; do
  cp "$root/public/nelua/examples/$name.nelua" .
  "$nelua" --cc 'zig cc' --target wasm32-wasi -c --cache-dir cache -o "$name.c" "$name.nelua"
  zig cc -target wasm32-wasi -Oz -s "$name.c" -o "$name.wasm"
done
sed -n '/^int nelua_main(.*) {$/,/^}$/p' c-call.c > snippets/c-call.c
sed -n '/^int nelua_main(.*) {$/,/^}$/p' point.c > snippets/point.c
sed -n '/^static int64_t comptime_tiles = /p;/^int nelua_main(.*) {$/,/^}$/p' comptime.c > snippets/comptime.c
"$root/examples/browser-life/compile-web.sh" "$app/opcode.nelua" "$stage" encode
sed -n '/^static .*opcode_codes = /p;/^uint32_t encode(.*) {$/,/^}$/p' opcode.c > snippets/assembler.c
for file in snippets/*.c; do test -s "$file"; done
node "$app/check.mjs" "$stage"
(cd "$root" && node_modules/.bin/imba build examples/workshop/workshop.imba --web --production --bundle --minify --no-sourcemap --outdir "$stage/ui")
entry=$(node -p "require('./ui/manifest.json').main")
cp ui/"$entry" "$dest/workshop.js"
cp arena.wasm c-call.wasm comptime.wasm point.wasm opcode.wasm opcode.c rule.bend rule.mjs "$dest/"
cp snippets/*.c "$root/src/content/showcase/"

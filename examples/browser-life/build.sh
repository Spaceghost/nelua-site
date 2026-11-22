#!/bin/sh
# Run from any directory. NELUA selects the Spaceghost fork executable.
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
src="$root/examples/browser-life"
dest="$root/public/nelua/examples/life"
stage=$(mktemp -d "${TMPDIR:-/tmp}/browser-life.XXXXXXXX")
trap 'rm -rf "$stage"' EXIT
cd "$stage"
export NELUA_BENDJS_SOURCE="$stage/rule.bend"
cp "$src/life.nelua" .
"${NELUA:-nelua}" -L "$src" --cc 'zig cc' --target wasm32-freestanding --cache-dir "$stage/cache" -c -o life.c life.nelua
"${NELUA_BEND:-bend}" rule.bend -o rule.mjs
zig cc -target wasm32-freestanding -Oz -fwrapv -fno-strict-aliasing -c life.c -o life.o
zig build-exe life.o -target wasm32-freestanding -O ReleaseSmall -fno-entry --export=next_row --import-symbols -femit-bin=life.wasm
node "$src/check.mjs" "$stage"
(cd "$root" && node_modules/.bin/imba build examples/browser-life/board.imba --web --production --bundle --minify --no-sourcemap --outdir "$stage/ui")
entry=$(node -p "require('./ui/manifest.json').main")
mkdir -p "$dest"
cp life.wasm life.c rule.bend rule.mjs "$dest/"
cp "ui/$entry" "$dest/board.js"
if [ ! -f "$root/src/site.imba" ]; then cp "$src/standalone.html" "$dest/index.html"; fi
tar -C "$root" --sort=name --mtime=@0 --owner=0 --group=0 -czf "$dest/starter.tar.gz" examples/browser-life

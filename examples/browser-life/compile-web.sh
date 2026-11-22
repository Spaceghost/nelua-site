#!/bin/sh
# compile-web.sh INPUT.nelua STAGING_DIRECTORY WASM_EXPORT [WASM_EXPORT...]
set -eu
[ "$#" -ge 3 ] || { echo 'Expected a Nelua input, staging directory and Wasm exports' >&2; exit 2; }
syntax=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
source_dir=$(CDPATH= cd -- "$(dirname "$1")" && pwd)
file=$(basename "$1")
name=${file%.nelua}
cd "$2"
shift 2
export NELUA_BENDJS_SOURCE="$PWD/rule.bend"
cp "$source_dir/$file" .
"${NELUA:-nelua}" -L "$syntax" -L "$source_dir" --cc 'zig cc' --target wasm32-freestanding --cache-dir "$PWD/cache" -c -o "$name.c" "$file"
"${NELUA_BEND:-bend}" rule.bend -o rule.mjs
zig cc -target wasm32-freestanding -Oz -fwrapv -fno-strict-aliasing -c "$name.c" -o "$name.o"
for symbol do
  shift
  set -- "$@" "--export=$symbol"
done
zig build-exe "$name.o" -target wasm32-freestanding -O ReleaseSmall -fno-entry "$@" --import-symbols "-femit-bin=$name.wasm"

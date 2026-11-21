#!/usr/bin/env bash
set -euo pipefail

# Portable GCC/glibc strtod comparison driver. Set repository, tool, and archive
# paths through environment variables; only the fixture and this script are
# needed in the published bundle.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SRC=${SRC:-"$SCRIPT_DIR/strtod-controls.c"}
OUT=${OUT:-strtod-controls-output}
CC=${CC:-gcc}
CPU=${CPU:-3}
TARGET_MS=${TARGET_MS:-3}
OLD_ARCHIVE=${OLD_ARCHIVE:?set OLD_ARCHIVE}
NEW_ARCHIVE=${NEW_ARCHIVE:?set NEW_ARCHIVE}
OLD_LABEL=${OLD_LABEL:-84267ab9185f25c88eca4cd10366207a5028ecc7}
NEW_LABEL=${NEW_LABEL:-eef2cefc548e6e25760c653ef31154f460bf7690}
MODE=${1:---check-only}
COMMON_CFLAGS=(-O2 -std=c11 -Wall -Wextra -fno-builtin)

mkdir -p "$OUT"
"$CC" "${COMMON_CFLAGS[@]}" "$SRC" -Wl,-Map,"$OUT/glibc-gcc.map" \
  -o "$OUT/strtod-glibc-gcc"
"$CC" "${COMMON_CFLAGS[@]}" "$SRC" "$OLD_ARCHIVE" \
  -Wl,-Map,"$OUT/previous-gcc.map" -o "$OUT/strtod-previous-gcc"
"$CC" "${COMMON_CFLAGS[@]}" "$SRC" "$NEW_ARCHIVE" \
  -Wl,-Map,"$OUT/final-gcc.map" -o "$OUT/strtod-final-gcc"

nm -D "$OUT/strtod-glibc-gcc" > "$OUT/glibc-gcc.nm"
nm "$OUT/strtod-previous-gcc" > "$OUT/previous-gcc.nm"
nm "$OUT/strtod-final-gcc" > "$OUT/final-gcc.nm"
grep -Eq ' U strtod(@|$)' "$OUT/glibc-gcc.nm"
grep -Eq ' [Tt] strtod$' "$OUT/previous-gcc.nm"
grep -Eq ' [Tt] strtod$' "$OUT/final-gcc.nm"
grep -q 'libnelibc-gcc.a(stdlib-float-gcc.o)' "$OUT/previous-gcc.map"
grep -q 'libnelibc-gcc.a(stdlib-float-gcc.o)' "$OUT/final-gcc.map"

: > "$OUT/checks.log"
run_check() {
  local name=$1 exe=$2
  taskset -c "$CPU" "$exe" --profile "$name" --check >> "$OUT/checks.log"
}
run_check glibc-gcc "$OUT/strtod-glibc-gcc"
run_check "$OLD_LABEL" "$OUT/strtod-previous-gcc"
run_check "$NEW_LABEL" "$OUT/strtod-final-gcc"

if [[ "$MODE" == "--check-only" ]]; then
  cat "$OUT/checks.log"
  echo "checks complete; no timing performed"
  exit 0
fi
if [[ "$MODE" != "--bench" ]]; then
  echo "usage: $0 [--check-only|--bench]" >&2
  exit 2
fi

raw_csv="$OUT/strtod-controls-raw.csv"
summary_csv="$OUT/strtod-controls.csv"
gzip_csv="$OUT/strtod-controls-raw.csv.gz"
echo "profile,round,case,offset,iterations,elapsed_ns,ns_per_call,bits,end_offset,errno,cpu_before,cpu_after" > "$raw_csv"
: > "$OUT/bench.log"

run_profile() {
  local name=$1 exe=$2 round=$3
  taskset -c "$CPU" "$exe" --profile "$name" --round "$round" --bench-ms "$TARGET_MS" \
    2>> "$OUT/bench.log" | tail -n +2 >> "$raw_csv"
}

# Seven process triplets rotate through execution orders to spread drift.
orders=(
  "glibc previous final"
  "previous final glibc"
  "final glibc previous"
  "glibc final previous"
  "final previous glibc"
  "previous glibc final"
  "glibc previous final"
)
for round_index in "${!orders[@]}"; do
  round=$((round_index + 1))
  for name in ${orders[$round_index]}; do
    case "$name" in
      glibc) run_profile glibc-gcc "$OUT/strtod-glibc-gcc" "$round" ;;
      previous) run_profile "$OLD_LABEL" "$OUT/strtod-previous-gcc" "$round" ;;
      final) run_profile "$NEW_LABEL" "$OUT/strtod-final-gcc" "$round" ;;
    esac
  done
done

python3 - "$raw_csv" "$summary_csv" "$OLD_LABEL" "$NEW_LABEL" <<'PY'
import csv
import statistics
import sys
from collections import defaultdict

source, target, old_label, new_label = sys.argv[1:]
groups = defaultdict(dict)
with open(source, newline="") as f:
    for row in csv.DictReader(f):
        key = row["case"], int(row["offset"])
        groups[key].setdefault(row["profile"], {})[int(row["round"])] = float(row["ns_per_call"])
profiles = {"glibc": "glibc-gcc", "previous": old_label, "final": new_label}
header = [
    "case", "offset", "paired_rounds",
    "glibc_median_ns", "glibc_min_ns", "glibc_max_ns",
    f"previous_{old_label}_median_ns", f"previous_{old_label}_min_ns", f"previous_{old_label}_max_ns",
    f"final_{new_label}_median_ns", f"final_{new_label}_min_ns", f"final_{new_label}_max_ns",
    "native_over_final_median", "native_over_final_min", "native_over_final_max",
    "previous_over_final_median", "previous_over_final_min", "previous_over_final_max"
]
with open(target, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(header)
    for (case, offset), samples in sorted(groups.items()):
        series = {key: samples.get(profile, {}) for key, profile in profiles.items()}
        if any(set(values) != set(range(1, 8)) for values in series.values()):
            raise SystemExit(f"expected seven paired samples for {case} offset {offset}")
        native_ratio = [series["glibc"][i] / series["final"][i] for i in range(1, 8)]
        previous_ratio = [series["previous"][i] / series["final"][i] for i in range(1, 8)]
        def stats(values):
            return (f"{statistics.median(values):.3f}", f"{min(values):.3f}", f"{max(values):.3f}")
        writer.writerow((case, offset, 7,
                         *stats(list(series["glibc"].values())),
                         *stats(list(series["previous"].values())),
                         *stats(list(series["final"].values())),
                         *stats(native_ratio), *stats(previous_ratio)))
PY

gzip -n -c "$raw_csv" > "$gzip_csv"
python3 - "$SRC" "$0" "$OLD_ARCHIVE" "$NEW_ARCHIVE" "$OUT" "$CC" "$CPU" "$TARGET_MS" "$OLD_LABEL" "$NEW_LABEL" <<'PY'
import csv
import gzip
import hashlib
import json
import subprocess
import sys
from pathlib import Path

src, driver, old_archive, new_archive, out, cc, cpu, target_ms, old_label, new_label = sys.argv[1:]
out = Path(out)
def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()
with gzip.open(out / "strtod-controls-raw.csv.gz", "rt", newline="") as f:
    rows = list(csv.DictReader(f))
manifest = {
    "schema": "nelibc.strtod.controls.v1",
    "status": "complete",
    "source_sha256": sha(src),
    "driver_sha256": sha(driver),
    "compiler": subprocess.check_output([cc, "--version"], text=True).splitlines()[0],
    "compile_flags": ["-O2", "-std=c11", "-Wall", "-Wextra", "-fno-builtin"],
    "cpu": int(cpu),
    "target_ms_per_case_offset": int(target_ms),
    "process_triplets": 7,
    "raw_rows": len(rows),
    "cases": 13,
    "offsets": [0, 1, 7, 15, 31],
    "correctness": {"status": "pass", "checks_per_profile": 65},
    "strtod_ownership": {
        "glibc-gcc": "dynamic glibc strtod",
        old_label: "libnelibc-gcc.a(stdlib-float-gcc.o)",
        new_label: "libnelibc-gcc.a(stdlib-float-gcc.o)"
    },
    "revisions": {"previous": old_label, "final": new_label},
    "archives": {old_label: sha(old_archive), new_label: sha(new_archive)},
    "outputs": {
        "summary_csv_sha256": sha(out / "strtod-controls.csv"),
        "raw_csv_gzip_sha256": sha(out / "strtod-controls-raw.csv.gz")
    }
}
with open(out / "strtod-controls-manifest.json", "w") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")
PY

cat "$OUT/checks.log"
cat "$OUT/strtod-controls-manifest.json"
echo "summary CSV: $summary_csv"
echo "raw CSV gzip: $gzip_csv"

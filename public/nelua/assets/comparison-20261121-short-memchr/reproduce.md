# Reproduce the short memchr measurements

The previous Nelibc revision is `84267ab9185f25c88eca4cd10366207a5028ecc7`. The measured revision is `eef2cefc548e6e25760c653ef31154f460bf7690`. The [manifest](manifest.json) records the three archive hashes for each revision, compiler versions, flags, CPU and run order. Both archive sets were built from clean checkouts. The [earlier gap-fix results](../comparison-20261121-gap-fixes/manifest.json) preserve the measurements that motivated the change. The [substring measurements](../ecosystem-20261121/substring.csv) cover the intervening change at the previous revision.

## Build and time the production archives

Use an x86-64 Linux guest with Nelua `dabbd9ef`, GCC 12.2, glibc 2.36, the Zig and Cosmopolitan compilers in the manifest, and an unprivileged build user. Set `NELUA`, `ZIG` and `COSMOCC` to those tool paths. Set `RUN` to an empty scratch directory. The recorded run pinned all three consumers to logical CPU 3 on an Intel Core i5-10400.

```sh
git worktree add --detach "$RUN/old" 84267ab9185f25c88eca4cd10366207a5028ecc7
git worktree add --detach "$RUN/new" eef2cefc548e6e25760c653ef31154f460bf7690
for tree in old new; do
  make -C "$RUN/$tree" NELUA="$NELUA" ZIG="$ZIG" COSMOCC="$COSMOCC" \
    lib-gcc lib-zig-musl lib-cosmo
done
cd "$RUN/new"
taskset -c 3 python3 benchmarks/comparison/run.py --out "$RUN/final" \
  --cosmocc "$COSMOCC" --zig "$ZIG" --pairs 7 --cpu 3 \
  --previous-dir "$RUN/old/build"
```

Each of the nine executables checks its answers before timing. The [raw CSV](raw.csv) records every profile, case, implementation and round. For each case, divide the native time by the candidate time in the same round, then take the median. Use the previous Nelibc time as the numerator to reproduce gains across revisions. Absolute times in the [summary](summary.csv) are the medians of the seven timings for each implementation.

## Vary the length, alignment and match position

The separate scan fixture starts its buffer on a 64-byte boundary. It covers five offsets and sizes from zero through 65,536 bytes, including every length from 8 through 16. It tests misses and first, middle and last-byte matches, alongside a string-length control. The loop and dispatch overhead are included in all three builds. The [control results](memchr-controls.csv) use this fixture, which has a different caller and layout from the main corpus.

```sh
cd "$RUN/new"
taskset -c 3 python3 tools/strcmp_bench.py --profile cosmopolitan \
  --cc "$COSMOCC" --source tools/scan_bench.c --pairs 7 --cpu 3 \
  --old-archive "$RUN/old/build/libnelibc-cosmo.a" --out "$RUN/scan-cosmopolitan"
taskset -c 3 python3 tools/strcmp_bench.py --profile glibc \
  --cc gcc --source tools/scan_bench.c --pairs 7 --cpu 3 \
  --old-archive "$RUN/old/build/libnelibc-gcc.a" --out "$RUN/scan-glibc"
```

## Hold page placement constant in the musl consumer

The broad static executables place their four arrays at different offsets within a 4 KiB page. The [placement driver](musl-placement.py) reads those offsets from the two binaries, rebuilds the same benchmark loops for both layouts in all three implementations, and verifies the buffer addresses and correctness before timing. The [per-layout summary](musl-placement.csv), [raw samples](musl-placement-raw.csv) and [manifest](musl-placement-manifest.json) preserve the original offsets and each paired result.

```sh
python3 musl-placement.py --root "$RUN/new" --comparison "$RUN/final" --out "$RUN/musl-placement"
```

## Check decimal conversions across alignments

Place the [decimal fixture](strtod-controls.c) and its [driver](strtod-controls-run.sh) in the same directory. Each GCC executable uses the same system headers, flags and C source. The driver checks the linked `strtod` and the expected binary64 bits, end pointer and `errno` for 13 inputs at offsets 0, 1, 7, 15 and 31 within a 64-byte-aligned buffer. The [summary](strtod-controls.csv) preserves each offset separately. The [raw timings](strtod-controls-raw.csv.gz) record the observed conversions. The [run metadata](strtod-controls-manifest.json) identify the exact source, driver and linked archives.

```sh
export OLD_ARCHIVE="$RUN/old/build/libnelibc-gcc.a"
export NEW_ARCHIVE="$RUN/new/build/libnelibc-gcc.a"
export OLD_LABEL=84267ab9185f25c88eca4cd10366207a5028ecc7
export NEW_LABEL=eef2cefc548e6e25760c653ef31154f460bf7690
CPU=3 OUT="$RUN/decimal" bash strtod-controls-run.sh --bench
```

## Check behavior

The short-search regression in `tools/memory_diff.c` places an unreadable page after the input. It checks lengths 8 through 15 with one to seven readable bytes ending in a match, duplicate matches in a complete range, conversion of the integer needle to an unsigned byte, and zero length. The [guard-page results](validation.json) record the archive identities and outcomes. The [integration results](gate-summary.json) record the Make targets run on the measured revision.

The independent native-header experiment uses libc-test commit `63e36e934e8f2bedf645303a90b64098e2af6c8f`. Set `APE_LOADER` to the native loader from the measured Cosmopolitan compiler. The [corpus build record](corpus-build.json) identifies the test executables. The [conformance results](conformance.json) retain each test's observed status. The [deltas](deltas.json) compare each runtime with and without Nelibc.

```sh
git clone https://repo.or.cz/libc-test.git "$RUN/libc-test"
git -C "$RUN/libc-test" checkout --detach 63e36e934e8f2bedf645303a90b64098e2af6c8f
cd "$RUN/new"
python3 benchmarks/comparison/conformance.py --source "$RUN/libc-test" \
  --out "$RUN/corpus" --zig "$ZIG" --cosmocc "$COSMOCC" --ape-loader "$APE_LOADER"
```

The [replay driver](../comparison-20261121-gap-fixes/replay-corpus.py) repeats the Cosmopolitan pair in alternating order, reading each executable into the guest page cache first. Use the replay CPU from the [recorded conditions](replay-conditions.json). The counts for glibc and musl come from the initial run.

```sh
python3 replay-corpus.py "$RUN/corpus" --ape-loader "$APE_LOADER" \
  --out "$RUN/warmed-corpus" --cpu "$CORPUS_CPU"
```

## Recreate the coverage comparison

The [runtime census](coverage.json) uses the same 1,471 musl header names for every profile. The [census driver](runtime-census.py) replays the recorded Zig link commands with verbose output, checks that all three consumers used the same runtime archives, and reads those exact files. Set `ZIG_GLOBAL_CACHE_DIR` to the build cache and `COSMO_LIBRARY` to the measured runtime archive. The [coverage explorer](/nelua/nelibc/#coverage) also shows each runtime’s archive-function inventory.

```sh
python3 runtime-census.py --root "$RUN/new" --results "$RUN/final" \
  --cosmo-library "$COSMO_LIBRARY"
```

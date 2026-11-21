# Reproduce the matched Nelibc comparison

The performance CSV contains 57 case and size combinations for each of three x86-64 profiles. Each record in the raw CSV identifies the profile, case, size, implementation, rotation, operation count and elapsed nanoseconds per operation. For each profile and case, divide the libc-only time in a round by the candidate time in that same round. The headline ratio is the median of the seven ratios. Divide the previous Nelibc time by the candidate time for the before-and-after ratio. The observed range gives the minimum and maximum paired ratios.

The six conformance builds each plan 343 functional, regression and math tests from upstream libc-test revision `63e36e934e8f2bedf645303a90b64098e2af6c8f`. Count the per-test status values in `conformance.json` to reproduce each column. The public results identify the tests by their upstream names. The [corpus build record](corpus-build.json) binds the fresh links and their outcomes to this revision. The complete earlier corpus was archived before relinking.

## Rerun from source

Use Linux x86-64, GCC 12.2 with glibc 2.36, Zig 0.17.0 with its musl target, the x86-64 Cosmopolitan 4.0.2 compiler and loader, and Nelua revision `dabbd9ef`. The manifest contains exact revisions, archive hashes and consumer link commands. The benchmark consumer and its two Python drivers match those in the [previously published harness snapshot](../comparison-20261117-easy-first/source.tar.gz) byte for byte.

From an existing Nelibc checkout, set `RUN` to a fresh working directory and supply the full paths to the two compilers, the Nelua driver and the Cosmopolitan APE loader. Build the previous archives first, then the current archives. Run tests as an unprivileged user. Set `BENCH_CPU` to the CPU in the manifest, and `CORPUS_CPU` to the CPU in the corpus replay conditions. Each selected CPU must be in the process’s permitted affinity.

```sh
git worktree add --detach "$RUN/previous-src" e98cae6a8d998cfc91c14a0d268c1f510fcf1461
git worktree add --detach "$RUN/nelibc" 190ad4e2c6ac8abcd19ae1ce7d0f3335dc62708f
for tree in previous-src nelibc; do
  make -C "$RUN/$tree" NELUA="$NELUA" ZIG="$ZIG" COSMOCC="$COSMOCC" \
    lib-gcc lib-zig-musl lib-cosmo
done
cd "$RUN/nelibc"
python3 benchmarks/comparison/run.py --zig "$ZIG" --cosmocc "$COSMOCC" \
  --previous-dir "$RUN/previous-src/build" --out "$RUN/timings" --pairs 7 --cpu "$BENCH_CPU"
git clone https://repo.or.cz/libc-test.git "$RUN/libc-test"
git -C "$RUN/libc-test" checkout --detach 63e36e934e8f2bedf645303a90b64098e2af6c8f
python3 benchmarks/comparison/conformance.py --source "$RUN/libc-test" \
  --zig "$ZIG" --cosmocc "$COSMOCC" --ape-loader "$APE_LOADER" --out "$RUN/conformance"
```

For the repeated Cosmopolitan pair, the build guest reread each executable into its page cache immediately before launching the same upstream supervisor. Both link variants ran for every successfully built test. Their order alternated between test cases. The original unmodified harness results remain available as [the initial corpus run](initial-conformance.json). To produce the repeated records, run the [recorded corpus driver](replay-corpus.py) in the build guest.

```sh
python3 replay-corpus.py "$RUN/conformance" --ape-loader "$APE_LOADER" \
  --out "$RUN/warm-conformance" --cpu "$CORPUS_CPU"
```

The additional GCC/glibc string distribution compiles `tools/strstr_bench.c` with `gcc -O2 -fno-builtin` against each of the three link arrangements. It first checks random inputs and page boundaries, then measures tail matches and periodic misses. Each row contains the consumer’s median of seven inner samples. Three process rounds rotate the order of the three executables. The phase-change control uses the same consumer with `--anchor-controls`. Four process rounds rotate the native, previous, first candidate and final builds. The first candidate is `add53bf69303415c75fb099ad822bf046a1d6b45`. These diagnostics have their own inputs and timing loops.

Build the first candidate archive and use the current test source for every variant. The commands below recreate the exact variant labels and the four-way rotation. The ordinary three-way sweep uses the same binaries without flags and rotates `baseline previous candidate`, `previous candidate baseline`, and `candidate baseline previous`.

```sh
git worktree add --detach "$RUN/first-src" add53bf69303415c75fb099ad822bf046a1d6b45
make -C "$RUN/first-src" NELUA="$NELUA" lib-gcc
mkdir -p "$RUN/diagnostics"
for variant in baseline previous first-candidate candidate; do
  case "$variant" in
    baseline) set -- ;;
    previous) set -- "$RUN/previous-src/build/libnelibc-gcc.a" ;;
    first-candidate) set -- "$RUN/first-src/build/libnelibc-gcc.a" ;;
    candidate) set -- "$RUN/nelibc/build/libnelibc-gcc.a" ;;
  esac
  gcc -O2 -fno-builtin '-DBENCH_COMPILER="gcc"' '-DBENCH_LIBC="glibc"' \
    "-DBENCH_IMPLEMENTATION=\"$variant\"" "$RUN/nelibc/tools/strstr_bench.c" \
    "$@" -lm -pthread -o "$RUN/diagnostics/$variant"
done
set -- baseline previous first-candidate candidate
for round in 1 2 3 4; do
  for variant in "$@"; do
    taskset -c "$BENCH_CPU" "$RUN/diagnostics/$variant" --anchor-controls \
      > "$RUN/diagnostics/$variant-phase-$round.csv"
  done
  first=$1
  shift
  set -- "$@" "$first"
done
```

The separate baseline files record the unmodified revision paired with each native libc before the change. The published before-and-after ratios use the previous and current builds measured together in the final triplets.

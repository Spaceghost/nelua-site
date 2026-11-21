# Reproduce the matched Nelibc gap-fix measurements

The measured candidate is `70bcd89457f2b1433916747df715ea8546e54ffb` and the preceding release is `f9ae990711f50a3e2b5cec670cd56d1867969ef7`. The previous revision changed CI configuration after `190ad4e`; its production sources and Makefile are the same. The preserved GCC, Zig/musl and Cosmopolitan archives match the [previously published archive hashes](../comparison-20261121/manifest.json). The [new manifest](manifest.json) identifies every archive in this comparison. Every timing row here comes from a new run.

The x86-64 build guest used Nelua `dabbd9ef`, GCC 12.2, glibc 2.36, Zig 0.17.0’s musl target, Cosmopolitan 4.0.2 and its APE loader. The broad timing harness, consumer and native-header corpus driver match those in the [public harness snapshot](../comparison-20261117-easy-first/source.tar.gz). Run the software as an unprivileged user. Inside a checkout, set `RUN` to a new working directory and `NELUA`, `ZIG`, `COSMOCC`, and `APE_LOADER` to the corresponding tool paths. Set `CPU` from the performance manifest and `CORPUS_CPU` from the replay conditions; both must be available in the guest.

```sh
git worktree add --detach "$RUN/old" f9ae990711f50a3e2b5cec670cd56d1867969ef7
git worktree add --detach "$RUN/new" 70bcd89457f2b1433916747df715ea8546e54ffb
for tree in old new; do
  make -C "$RUN/$tree" NELUA="$NELUA" ZIG="$ZIG" COSMOCC="$COSMOCC" \
    lib-gcc lib-zig-musl lib-cosmo
done
cd "$RUN/new"
python3 benchmarks/comparison/run.py --out "$RUN/timings" --cosmocc "$COSMOCC" \
  --zig "$ZIG" --previous-dir "$RUN/old/build" --pairs 7 --cpu "$CPU"
```

The [raw timing CSV](raw.csv) records 57 operations and sizes, three runtime profiles, seven rounds and the native/previous/current rotation. Divide each native time by its current time in the same round, then take the median of those seven ratios. Use the previous time in the numerator to reproduce the change from the last release. Absolute ns/op are the medians of each variant’s seven observations. The [optimization notes](optimization-notes.md) include the measured changes on short musl memchr and Cosmopolitan memcmp inputs. The range is the minimum and maximum paired ratio.

## Native-header conformance

Six fresh trees each build the same 343 upstream tests. Native and Nelibc-linked pairs use the same runtime headers. The [build identities](corpus-build.json) bind source revisions and archive hashes to the new compile/link logs, executable set, supervisor and case set. Each failed build or link has an associated fresh diagnostic. For the second Cosmopolitan measurement the original unprivileged supervisor ran each executable after it had been read into the guest’s page cache. The order alternated between the two builds. Both [initial results](initial-conformance.json) and [replayed results](conformance.json) retain all planned tests. The [repeat conditions](replay-conditions.json) identify the APE loader and executable set.

```sh
git clone https://repo.or.cz/libc-test.git "$RUN/libc-test"
git -C "$RUN/libc-test" checkout --detach 63e36e934e8f2bedf645303a90b64098e2af6c8f
python3 benchmarks/comparison/conformance.py --source "$RUN/libc-test" \
  --out "$RUN/corpus" --zig "$ZIG" --cosmocc "$COSMOCC" --ape-loader "$APE_LOADER"
python3 replay-corpus.py "$RUN/corpus" --ape-loader "$APE_LOADER" \
  --out "$RUN/warmed-corpus" --cpu "$CORPUS_CPU"
```

The [additional guard-page, numeric and CPU-dispatch checks](validation.json) identify the archive and executable used for each set of assertions.

The [coverage census](coverage.json) counts symbols against the same 1,471-name musl 1.2.5 inventory across all three profiles. The [census driver](runtime-census.py) requires the exact Zig runtime cache used by the compilation and the Cosmopolitan static runtime archive. Set `ZIG_GLOBAL_CACHE_DIR` and `COSMO_LIBRARY` to those inputs.

```sh
python3 runtime-census.py --root "$RUN/new" --results "$RUN/timings" \
  --zig-cache "$ZIG_GLOBAL_CACHE_DIR" --cosmo-library "$COSMO_LIBRARY"
```

## Changing-frequency substring controls

[The focused driver](../strstr-repeat-20261121-gap-fixes/repeat.py) builds all three GCC/glibc inputs from the same current C source, runs guard and differential checks, and measures seven inner loops of 256 calls for each input. The 12 process rounds contain all six possible execution orders twice. The [compact CSV](../strstr-repeat-20261121-gap-fixes/strstr-repeat-64k.csv) retains all observations for the three 65,536-byte controls; the [full CSV](../strstr-repeat-20261121-gap-fixes/strstr-repeat-all.csv) includes 64 and 4,096 bytes as well. The needle is `abaa`. The inputs begin with 16 `a` bytes then `b` bytes, 16 `b` bytes then `a` bytes, or alternating `a` and `b`.

```sh
python3 repeat.py --previous-commit f9ae990711f50a3e2b5cec670cd56d1867969ef7 \
  --revision 70bcd89457f2b1433916747df715ea8546e54ffb --source "$RUN/new" \
  --previous-archive "$RUN/old/build/libnelibc-gcc.a" --cpu "$CPU" --out "$RUN/repeat"
```

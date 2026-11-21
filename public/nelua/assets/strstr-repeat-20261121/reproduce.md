# Repeat of the short-needle frequency controls

These measurements use the same previously built GCC/glibc executables and `tools/strstr_bench.c` as the [initial frequency-control experiment](../comparison-20261121/strstr-phase-controls.csv). The manifest records the benchmark source, executable and archive digests, selected CPU, software versions, timings and placement checks.

The needle is `abaa`. In the first absent-match input, 16 `a` bytes precede a run of `b` bytes. The inverse starts with 16 `b` bytes before a run of `a`. The equal-frequency input alternates `a` and `b`. Each process verifies random and guard-page cases before timing all nine combinations of distribution and size. Each observation is the consumer’s median ns/call from seven loops of 256 calls. The compact CSV preserves every 65,536-byte observation. The all-size CSV also records the 64-byte and 4,096-byte inputs.

The three variants are native glibc (`baseline`), Nelibc at `e98cae6a8d998cfc91c14a0d268c1f510fcf1461` (`previous`), and Nelibc at `190ad4e2c6ac8abcd19ae1ce7d0f3335dc62708f` (`candidate`). The first six rounds exhaust all six possible orderings. The next six run them in reverse order. Every variant occupies each position four times. Median ns/call is the median across the 12 process observations for that case and variant. For before/after speedup, divide the previous observation by the current observation in the same round, then take the median of the 12 ratios. Reported ranges are their observed minimum and maximum.

Download the [repeat driver](repeat.py) and the [run manifest](strstr-repeat-manifest.json). For a repeat with the exact original binaries, place the `baseline`, `previous` and `candidate` executables in one directory. Supply the current Nelibc working tree and prior GCC archive. Run as an unprivileged user inside the designated Linux x86-64 build guest. The original experiment used logical CPU 3.

```sh
python3 repeat.py --executables "$CONTROL_BINARIES" --source "$NELIBC_SOURCE" \
  --previous-archive "$PREVIOUS_GCC_ARCHIVE" --cpu 3 --out new-results
```

For an independent rebuild, use the GCC control compilation commands and pinned sources in the [original reproduction instructions](../comparison-20261121/reproduce.md). The driver’s executable-digest check identifies the exact three measured binaries. Independently rebuilt binaries may differ if compiler paths or dependencies change.

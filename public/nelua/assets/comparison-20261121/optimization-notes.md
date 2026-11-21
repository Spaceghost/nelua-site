# Short-needle substring search

2026-11-21, Intel(R) Core(TM) i5-10400 CPU @ 2.90GHz, logical CPU 3.

The production comparison rotates the native library, previous Nelibc and revised Nelibc consumer within each profile. The GCC/glibc rows below search for “aaaaz” in a run of “a” bytes that ends with a single “z”. Every speedup and observed range uses the seven matched rounds. The published table includes all 57 case and size combinations for each of the three runtime profiles.

| Haystack bytes | glibc ns/op | Previous Nelibc ns/op | Revised Nelibc ns/op | Previous ÷ revised, median [range] |
|---:|---:|---:|---:|---:|
| 8 | 11.71 | 21.84 | 10.22 | 2.13× [2.08–3.17] |
| 32 | 71.14 | 101.13 | 23.16 | 4.56× [4.20–7.54] |
| 128 | 365.12 | 362.73 | 27.64 | 13.06× [11.71–20.79] |
| 1024 | 3400.17 | 2695.49 | 42.61 | 63.13× [62.16–80.20] |
| 4096 | 15285.15 | 10465.05 | 83.64 | 126.81× [121.16–159.75] |
| 65536 | 249914.94 | 166870.34 | 1340.73 | 123.50× [120.24–152.64] |

## Inputs whose byte frequencies change

These missing-match cases search for `abaa`. The first group starts with 16 `a` bytes followed by `b` bytes. The second interchanges the two runs. The third alternates `a` and `b`. Four rounds rotate all four implementations. Each entry is the median of the four reported per-process times, in nanoseconds per call. The first candidate is `add53bf693034`.

| Input | Haystack bytes | glibc | Previous Nelibc | Initial optimization | Bounded retry | Previous ÷ bounded [range] |
|---|---:|---:|---:|---:|---:|---:|
| equal-frequency | 64 | 70.31 | 114.47 | 115.42 | 48.40 | 2.37× [2.31–2.44] |
| equal-frequency | 4,096 | 3,559.55 | 6,432.82 | 6,752.92 | 2,342.47 | 2.75× [2.69–2.88] |
| equal-frequency | 65,536 | 57,125.64 | 107,908.17 | 108,707.83 | 36,251.85 | 2.99× [2.96–3.04] |
| first-dense-then-sparse | 64 | 9.14 | 63.42 | 243.06 | 53.10 | 1.20× [1.18–1.21] |
| first-dense-then-sparse | 4,096 | 132.62 | 3,122.88 | 28,140.84 | 119.66 | 26.10× [25.64–26.71] |
| first-dense-then-sparse | 65,536 | 2,357.40 | 47,470.55 | 460,005.22 | 1,351.00 | 34.99× [34.35–35.70] |
| first-sparse-then-dense | 64 | 8.41 | 217.53 | 239.55 | 102.15 | 2.13× [2.11–2.16] |
| first-sparse-then-dense | 4,096 | 132.13 | 25,290.52 | 27,599.20 | 6,291.07 | 4.01× [3.94–4.16] |
| first-sparse-then-dense | 65,536 | 2,391.27 | 422,441.98 | 456,141.28 | 99,967.92 | 4.23× [3.52–4.23] |

On the 64 KiB input that begins with 16 “b” bytes and continues with “a”, the revised search still takes 99.97 µs per call. Native glibc takes 2.39 µs.

The bounded revision was slower than the previous release on none of these nine input groups.

Before timing, the consumer differential-checks search results against a scalar reference and puts the ends of strings next to inaccessible pages. The checks include an absent interior search byte, a misleading hit at the last possible start, and the earliest of two real matches after byte frequencies change.

Use the raw rows to inspect subcases and the observed spread. These are hot-buffer calls in one process on one x86-64 system. The record parser on the overview is a separate synthetic multi-operation benchmark.

[Production samples](raw.csv) · [Distribution sweep](strstr-distribution.csv) · [Frequency controls](strstr-phase-controls.csv) · [Revision and archive hashes](manifest.json) · [Reproduction instructions](reproduce.md)

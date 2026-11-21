# Matched measurements for the gap-fix release

Measured 2026-11-21 on Intel(R) Core(TM) i5-10400 CPU @ 2.90GHz, logical CPU 3. The production candidate is `70bcd89457f2b1433916747df715ea8546e54ffb`; the previous revision is `f9ae990711f50a3e2b5cec670cd56d1867969ef7`.

## Changing byte frequency in substring search

The 64 KiB control searches for the missing four-byte needle `abaa`. A cluster of false candidates now switches the search to the byte that failed verification. The search falls back to direct comparison if the replacement byte also gives too many false candidates. All three executables checked randomly generated strings and guarded page boundaries before timing.

| Haystack | Native glibc µs | Previous Nelibc µs | Current Nelibc µs | Previous ÷ current, median [range] |
|---|---:|---:|---:|---:|
| 16 b, then a | 2.511 | 102.50 | 1.395 | 73.42× [70.71–76.32] |
| 16 a, then b | 2.476 | 1.394 | 1.374 | 1.02× [0.95–1.17] |
| Alternating a and b | 58.61 | 39.93 | 40.02 | 1.00× [0.98–1.03] |

[All 12 matched rounds](../strstr-repeat-20261121-gap-fixes/strstr-repeat-64k.csv) · [Control conditions and executable hashes](../strstr-repeat-20261121-gap-fixes/strstr-repeat-manifest.json)

## Production operations and small inputs

The broad harness uses seven rotating process triplets per runtime. The record parser combines several operations. The memchr and memcmp rows include hot equal or absent cases with fixed buffer sizes. Every listed range is the minimum and maximum of the matched prior/current ratios.

| Runtime | Case | Bytes | Native ns | Previous Nelibc ns | Current Nelibc ns | Previous ÷ current, median [range] |
|---|---|---:|---:|---:|---:|---:|
| GCC/glibc | parse-record | — | 192.62 | 250.38 | 172.31 | 1.46× [1.40–1.63] |
| GCC/glibc | strtod-decimal | — | 105.87 | 181.71 | 111.98 | 1.63× [1.59–1.63] |
| GCC/glibc | memcmp-equal | 4096 | 38.98 | 47.73 | 34.52 | 1.38× [1.37–1.41] |
| GCC/glibc | strlen | 128 | 2.81 | 5.21 | 2.79 | 1.83× [1.25–1.97] |
| GCC/glibc | strlen | 4096 | 22.10 | 27.94 | 21.24 | 1.32× [1.29–1.79] |
| GCC/glibc | strstr-tail | 65536 | 255468.91 | 1370.75 | 1323.54 | 1.01× [0.59–1.17] |
| Zig/musl | memchr-absent | 32 | 19.78 | 2.53 | 2.83 | 0.89× [0.72–0.93] |
| Cosmopolitan | memcmp-equal | 8 | 2.03 | 2.30 | 2.53 | 0.91× [0.90–0.94] |

The short musl memchr and Cosmopolitan memcmp rows remain visible because the revised whole-program builds took longer on these inputs. These timings characterize the linked consumers and their specific input sizes.

[All 171 rows](summary.csv) · [All 3,591 observations](raw.csv) · [Build and reproduction instructions](reproduce.md)

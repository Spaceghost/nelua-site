# Short memory searches in Nelibc

Seven rotating rounds compared the native runtime, Nelibc at `84267ab`, and Nelibc at `eef2cef` on one x86-64 Linux host. Each native/previous/current triplet used the same compiler and benchmark source. The [raw samples](raw.csv) and [run manifest](manifest.json) identify the inputs.

## Eight-byte searches

On Cosmopolitan, the eight-byte miss went from 3.975 to 2.772 ns per call. Native Cosmopolitan took 2.241 ns. The median paired speedup over previous Nelibc was 1.45×, ranging from 1.41× to 1.48×. On Zig/musl, the same miss moved from 2.950 to 2.779 ns. The glibc-linked archive retained the same allocated code and data as the preceding revision.

The Cosmopolitan path handles its one eight-byte group in Nelua before scanning the tail. The Clang x86-64 path reads one word only when the whole word fits in the current page, then uses the first matching byte or continues in order. The [memory checks](validation.json) exercise a match in the last readable byte, repeated matches, byte conversion of the needle and zero length.

In the [independent scan fixture](memchr-controls.csv), the eight-byte Cosmopolitan miss was 1.08–1.12× faster than previous Nelibc across five offsets. An aligned first-byte hit moved from 1.73 to 2.00 ns, against native Cosmopolitan at 2.26 ns. Middle and last-byte hits improved. At 128 bytes, paired miss ratios across offsets ranged from 0.99× to 1.02×. At 65,536 bytes they ranged from 1.00× to 1.03×.

## What buffer placement changed

The broad musl run showed slower short copies, overlapping moves and string lengths. Linking the new archive put the string 16 bytes before a page boundary. The old executable placed it 272 bytes before that boundary. The [placement control](musl-placement.csv) reproduced both layouts in each implementation. At the old offsets, 128-byte copies took 3.26 ns with previous Nelibc and 3.22 ns with current Nelibc. At the new offsets they both took 6.09 ns. The original broad numbers and the same-placement comparisons are both available.

## Decimal conversion

The original decimal input, `3.141592653589793`, took 101.72 ns on native glibc and 109.49 ns with current Nelibc in the broad consumer. All three GCC builds passed the [decimal fixture](strtod-controls.c) at five offsets, including nearest-even rounding, maximum finite binary64, invalid input, trailing text, overflow and underflow. Each case checks the exact bits, end pointer and errno.

The most pronounced losses in these additional inputs were large exponents. At offset zero, `1e9999` took 143.13 µs with Nelibc and 15.28 ns on glibc. For `1e-9999` the medians were 147.90 µs and 14.92 ns. The [per-input, per-offset summary](strtod-controls.csv) retains these cases separately from the ordinary decimal benchmark. These measurements give a concrete next target for range handling. How much it matters in an application depends on the inputs that application parses.

## Independent conformance

Each runtime and overlay build attempted 343 upstream libc-test cases. The initial and warmed runs both recorded a new non-pass against native Cosmopolitan in `functional/popen`. The child exited on signal 13. A [2,000-triplet replay](validation.json) reproduced that exit with native Cosmopolitan twice, previous Nelibc once and current Nelibc four times. All other trials passed. The current test executable matched the full-corpus executable byte for byte. The same failure can occur with all three builds. The corpus totals retain its observed status. The musl overlay also failed `regression/sigprocmask-internal`, which failed in the [preceding published corpus](../comparison-20261121-gap-fixes/conformance.json).

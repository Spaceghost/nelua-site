Nelua performance shootout, 22 November 2026 Pacific (23 November UTC)

All medians exclude the warm-up. The compiler-field and linker-field samples
already omit warm-up rows. The archive contains measurements and source only.

Nelua release builds (release-pair.csv)
  Intel Core i5-10400, Alpine, GCC 15.2.0, logical CPU 3, 15 measured rounds.
  Control 0f29b8f, candidate c95493e, upstream a584505. Each used the same
  nelua-lua binary, --cc /usr/bin/gcc and the same control example as input.
  Each sample ran nelua -C -r -b --cache-dir DIR -o PROGRAM SOURCE, then
  separately timed PROGRAM. The harness checked stdout against the first run.
  ownership.csv isolates the analyzer patch using tools/bench-frontend.py from
  Spaceghost/nelua and the same standard library in both trees. compiler-release.csv
  records the earlier i7-11700F comparison (nanoseconds, seven measured pairs).

LZ4 (lz4-copy.csv)
  necc 7ed048c, i7-11700F, CPU 5. Both necc rows used the same compiler.
  ordinary selects LZ4's default memcpy; builtin adds -DLZ4_memcpy=__builtin_memcpy.
  Build in ms; encode/decode in ms per operation; each invocation repeats nine
  times and verifies the decoded corpus. The lz4 folder contains the common
  driver and a standalone two-way replay with instructions in replay.py.
  GCC and Clang used -O2. SDK TinyCC used the same SDK headers as necc.

necc/summary.csv and samples.csv cover 23 measurements per tool/workload on
  i7-11700F CPU 5 in Debian 12. necc-base = 22180f5, necc-next = 7ed048c.
  status.json records qualification, metadata.json the commands, digests and
  versions. phase-* compares the previous and updated SDK with fixed necc
  7ed048c, 25 warm rounds per stage. VM comparison in vm.csv, frontend-vm.csv
  and necc-three.csv uses necc = e1eab18 and candidate = 22180f5. The Lua VM
  study replaces only lvm.o. The workload checksum is 793207.

nelinker/ contains 23 shuffled rounds on i7-11700F CPU 5 for each admitted
  configuration. nelinker-native and nelinker-distro use a349c2a compiled
  with the native necc backend and the SDK TinyCC backend respectively. The
  six exclusions are from the whole-SDK allocator. The remaining 93 pairs
  produced executables returning 42. The previously published linker-20261121
  replay kit supplies the same input bytes. linker-current.csv and
  linker-vm-current.csv measure wall time and peak RSS in separate runs.

build-archive.csv and build-incremental.csv use CPU 5 on i5-10400 and GNU
  binutils, make and Ninja. nebuild-repeat.csv repeats the graph test on an
  i7-11700F. nebuild revisions 0441e93 and 60d1200. Use the previously
  published build-tools-20261121/bench.py to rebuild the fixtures.

nelibc/ contains the seven-triplet canonical comparison for eef2cef versus
  84267ab and each native libc. Run the source's benchmarks/comparison/run.py
  with --pairs 7 and --cpu 0. The manifest identifies compilers, archives and
  inputs. substring-current.csv compares 70bcd89, eef2cef and glibc 2.36 in
  a separate nine-round run using the published substring-rounds.sh.
  All 1,995 consumer checks passed for each of the nine canonical binaries.

boot.csv and efi.csv use QEMU 10.2.2, TCG and verified release kernel/initrd
  from Spaceghost/cascadia tag core-dev-2026.11.20. boot.csv uses its
  docs/assets/core-serial-timing/time-boot.py at revision 3fa30c5, CPU 8.
  efi.csv uses the neboot b8c56a8 Core menu compiled by c95493e, 7ed048c
  and a349c2a, host OVMF, and the published efi.py with CPU 2. Both studies
  include all observations including slow boots. Use workload-specific sample
  counts and compare configurations within a host.

wc.csv and shell.csv repeat line counting and the shell catalog with the same
  verified workload and GNU wc/dash references on i5-10400 logical CPU 0.
  Nebox versions 94fac62 and 339eae3. The public ecosystem-20261121 wc.py and
  shell.py scripts include the expected counts and output checks.

life.csv contains 11 measured pairs per tool, i7-11700F CPU 5, checksum
2658672284. necc 7ed048c, TinyCC 0.9.27, GCC and Clang -O2, Node and
Chromium 159.0.8154.6. The life-20261122 replay contains both kernels.

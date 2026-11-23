"""Compare the two LZ4 copy paths. Pass the LZ4 1.10.0 and Nelua Git trees.
Set NECC to necc 7ed048c, NECC_SYSROOT to its SDK and TMPDIR to scratch.
Example: taskset -c 5 python3 replay.py /src/lz4 /src/nelua > samples.csv
"""
import argparse
import csv
import hashlib
import os
from pathlib import Path
import random
import shutil
import subprocess
import sys
import tempfile
import time

args = argparse.ArgumentParser(description=__doc__)
args.add_argument("lz4", type=Path)
args.add_argument("nelua", type=Path)
opts = args.parse_args()
codec = opts.lz4.resolve() / "lib"
repo = opts.nelua.resolve()
driver = Path(__file__).resolve().with_name("driver.c")
necc = shutil.which(os.environ.get("NECC", "necc"))
if not necc:
    args.error("set NECC to the compiler executable")
necc = str(Path(necc).resolve())
digests = {1: "5ca29de59a7ccf8e50f0be7db9baa02ba928850af44c1740ea792915def21859",
           4: "cd38faed7106a177c3eac63dc755a4cfa4e625a11d7893be81f018306c0e439f"}
with tempfile.TemporaryDirectory() as scratch:
    os.chdir(scratch)
    shutil.copy(codec / "lz4.h", ".")
    lines = (codec / "lz4.c").read_text().splitlines()
    at, = [i for i, line in enumerate(lines) if line.startswith("#define LZ4_STATIC_ASSERT(c)")]
    lines[at] = "#define LZ4_STATIC_ASSERT(c) { typedef char size_check[(c) ? 1 : -1]; }"
    Path("lz4.c").write_text("\n".join(lines) + "\n")
    git = ["git", "-C", str(repo)]
    names = subprocess.check_output([*git, "ls-tree", "-r", "--name-only", "0f29b8f", "lualib/nelua"]).decode().splitlines()
    with open("corpus", "wb") as corpus:
        for name in names:
            if name.endswith(".lua"):
                subprocess.run([*git, "show", "0f29b8f:" + name], stdout=corpus, check=True)
    assert Path("corpus").stat().st_size == 1141485
    subprocess.run(["gcc", "-O2", "-I.", "-c", driver, "-o", "driver.o"], check=True)
    rng = random.Random(336)
    w = csv.writer(sys.stdout)
    w.writerow(["round", "copy", "acceleration", "build_ms", "encode_ms", "decode_ms", "bytes", "sha256"])
    for rnd in range(12):
        modes = ["ordinary", "builtin"]
        rng.shuffle(modes)
        for mode in modes:
            flags = ["-DLZ4_memcpy=__builtin_memcpy"] if mode == "builtin" else []
            start = time.perf_counter_ns()
            subprocess.run([necc, *flags, "-DLZ4_FORCE_MEMORY_ACCESS=0", "-c", "lz4.c", "-o", "codec.o"], check=True)
            build = (time.perf_counter_ns() - start) / 1e6
            subprocess.run(["gcc", "-no-pie", "driver.o", "codec.o", "-o", "bench"], check=True)
            for acceleration, expected in digests.items():
                size, encode, decode = subprocess.check_output(
                    ["./bench", "corpus", str(acceleration), "9", "output"], text=True).split()
                assert hashlib.sha256(Path("output").read_bytes()).hexdigest() == expected
                w.writerow([rnd, mode, acceleration, build, encode, decode, size, expected])

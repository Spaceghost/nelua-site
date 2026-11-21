"""Compare line counts over Nelibc's concatenated, tracked Nelua sources."""
import csv
import os
from pathlib import Path
import subprocess
import sys
import time

p = Path.cwd()
data = (p / "corpus.nelua").read_bytes()
tools = {"before": [p / "previous/nebox", "wc"], "GNU": ["wc"]}
if (p / "updated/nebox").is_file():
    tools["after"] = [p / "updated/nebox", "wc"]
os.sched_setaffinity(0, {min(os.sched_getaffinity(0))})
writer = csv.writer(sys.stdout)
writer.writerow(["round", "tool", "options", "elapsed_ns", "count"])
for r in range(16):
    names = list(tools)
    for name in names[r % len(names):] + names[:r % len(names)]:
        for flag in ["-l", "-lc", "-w"]:
            start = time.monotonic_ns()
            result = subprocess.check_output([*tools[name], flag, "corpus.nelua"])
            elapsed = time.monotonic_ns() - start
            counts = [int(word) for word in result.split()[:-1]]
            expected = {"-l": [data.count(b"\n")], "-lc": [data.count(b"\n"), len(data)],
                        "-w": [len(data.split())]}
            assert counts == expected[flag], (name, flag, counts)
            writer.writerow([r, name, flag, elapsed, " ".join(map(str, counts))])
            sys.stdout.flush()

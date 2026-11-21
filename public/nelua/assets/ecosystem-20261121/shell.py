"""Run alongside previous/nebox, updated/nebox and the Nebox source in nebox/."""
import csv
import os
from pathlib import Path
import subprocess
import sys
import time

catalog = Path("nebox/tests/data/applets/busybox-1.38.0.txt")
expected = sum(line.startswith(b"sha") for line in catalog.read_bytes().splitlines())
commands = {"launch": "printf '%s\\n' 42",
            "catalog": 'n=0; while IFS= read -r name; do case "$name" in sha*) n=$((n+1));; esac; done < "$1"; printf "%s\\n" "$n"'}
programs = {"previous": ["previous/nebox","sh"], "updated":["updated/nebox","sh"], "dash":["/bin/dash"]}
os.sched_setaffinity(0, {min(os.sched_getaffinity(0))})
w = csv.writer(sys.stdout)
w.writerow(["round","shell","workload","elapsed_ns","output"])
for r in range(13):
    order = list(programs)
    for name in order[r%3:] + order[:r%3]:
        for kind, script in commands.items():
            start = time.monotonic_ns()
            res = subprocess.check_output([*programs[name], "-c", script, "sh", catalog])
            elapsed = time.monotonic_ns()-start
            assert int(res) == (expected if kind=="catalog" else 42)
            w.writerow([r,name,kind,elapsed,int(res)])

"""Paired x86-64 Linux measurements for deterministic archives and unchanged build targets."""
import argparse
import csv
import hashlib
import json
import os
import platform
import random
import resource
import shutil
import statistics
import subprocess
import tempfile
import time
from pathlib import Path


def run(cmd, **kwargs):
    return subprocess.run(cmd, check=True, capture_output=True, **kwargs).stdout


def cpu_time():
    child = resource.getrusage(resource.RUSAGE_CHILDREN)
    return child.ru_utime + child.ru_stime


def measure(case, commands, check, reset=lambda: None):
    rng = random.Random(47236)
    for round_id in range(-3, args.rounds):
        order = list(commands)
        rng.shuffle(order)
        for name in order:
            reset()
            cpu = cpu_time()
            start = time.monotonic_ns()
            out = run(commands[name])
            elapsed = (time.monotonic_ns() - start) / 1e6
            cpu_ms = (cpu_time() - cpu) * 1000
            size = check(name, out)
            if round_id >= 0:
                rows.append([case, name, round_id + 1, round(elapsed, 5), round(cpu_ms, 5), size])


def archive():
    # 256 independently assembled symbols. Only the last member provides answer.
    names = [f"m{i:03d}.o" for i in range(256)]
    for i, name in enumerate(names):
        sym = "answer" if i == 255 else f"member{i}"
        source = f".text\n.globl {sym}\n{sym}: mov $42,%eax\n ret\n"
        run(["as", "--64", "-o", name, "-"], input=source.encode())
    run(["as", "--64", "-o", "start.o", "-"], input=b".text\n.globl _start\n_start:\n call answer\n mov %eax,%edi\n mov $60,%eax\n syscall\n")
    output = Path("candidate.a")
    def check(name, stdout):
        assert run(["ar", "t", output]).decode().splitlines() == names
        data = output.read_bytes()
        if name not in hashes:
            shutil.copyfile(output, name + ".a")
            for cmd in ([args.after], ["ld", "-m", "elf_x86_64"]):
                run([*cmd, "-o", "demo", "start.o", output])
                assert subprocess.run(["./demo"]).returncode == 42
            indexes = run(["nm", "--print-armap", output]).decode().partition("Archive index:\n")[2].partition("\n\n")[0].splitlines()
            assert len(indexes) == 256 and indexes[-1] == "answer in m255.o"
            hashes[name] = hashlib.sha256(data).digest()
        assert hashlib.sha256(data).digest() == hashes[name]
        return len(data)
    hashes = {}
    measure("write-256-members", {
        "before": [args.before, "--archive", "-o", output, *names],
        "after": [args.after, "--archive", "-o", output, *names],
        "GNU ar": ["ar", "rcsD", output, *names],
    }, check, lambda: output.unlink(missing_ok=True))
    def check_link(name, stdout):
        assert subprocess.run(["./demo"]).returncode == 42
        return Path("demo").stat().st_size
    # Fixed linker isolates the cost of the different archive layouts.
    measure("link-one-from-256", {name: [args.after, "-o", "demo", "start.o", name + ".a"] for name in hashes}, check_link)


def incremental():
    for count in (256, 2048):
        with tempfile.TemporaryDirectory(dir=".") as case_dir:
            os.chdir(case_dir)
            Path("src").mkdir()
            Path("out").mkdir()
            Path("src/input").write_text("ok\n")
            command = "cp src/input out/t0"
            ne_rules, make_rules = [], []
            ninja_rules = ["rule copy\n  command = cp $in $out\n"]
            for i in range(count):
                output = f"out/t{i}"
                recipe = f"cp src/input {output}"
                ne_rules.append(f"build {output} src/input\n\t{recipe}\n")
                ninja_rules.append(f"build {output}: copy src/input\n")
                make_rules.append(f"{output}: src/input\n\t{recipe}\n")
            Path("build.ne").write_text("".join(ne_rules))
            Path("Makefile").write_text("".join(make_rules))
            Path("build.ninja").write_text("".join(ninja_rules))
            target = Path("out/t0")
            assert run([args.before, "build.ne", target]).decode().strip() == command
            assert run([args.after, "build.ne", target]) == b""
            run(["ninja", "-f", "build.ninja", target])  # prime the command log
            initial = target.stat().st_mtime_ns
            def check(name, stdout):
                assert stdout.strip().endswith(b"no work to do.") if name == "Ninja" else not stdout
                assert target.stat().st_mtime_ns == initial and target.read_text() == "ok\n"
                return target.stat().st_size
            measure(f"unchanged-target-{count}-rules", {
                "before": [args.before, "build.ne", target],
                "after": [args.after, "build.ne", target],
                "Ninja": ["ninja", "-f", "build.ninja", target],
                "GNU make": ["make", "-rsR", "-f", "Makefile", target],
            }, check)
            os.chdir("..")


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("mode", choices=("archive", "incremental"))
parser.add_argument("before", type=lambda p: str(Path(p).resolve(strict=True)))
parser.add_argument("after", type=lambda p: str(Path(p).resolve(strict=True)))
parser.add_argument("--rounds", type=int, default=31)
parser.add_argument("--cpu", type=int, required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
os.sched_setaffinity(0, {args.cpu})
outdir = args.output.resolve()
outdir.mkdir(exist_ok=True, parents=True)
compiler = "ar" if args.mode == "archive" else "make"
manifest = {"host": platform.machine(), "kernel": platform.release(), "cpu": args.cpu,
            "load_start": os.getloadavg(), "rounds": args.rounds, "warmups": 3,
            "comparator": run([compiler, "--version"]).decode().splitlines()[0],
            "binary_sha256": {k: hashlib.sha256(Path(getattr(args, k)).read_bytes()).hexdigest()
                              for k in ("before", "after")}}
if args.mode == "incremental":
    manifest["ninja"] = run(["ninja", "--version"]).decode().strip()
rows = []
with tempfile.TemporaryDirectory(dir=os.environ.get("TMPDIR")) as directory:
    previous = Path.cwd()
    os.chdir(directory)
    (archive if args.mode == "archive" else incremental)()
    os.chdir(previous)
manifest["load_end"] = os.getloadavg()
prefix = outdir / args.mode
prefix.with_suffix(".json").write_text(json.dumps(manifest, indent=2) + "\n")
with prefix.with_suffix(".csv").open("w") as f:
    w = csv.writer(f, lineterminator="\n")
    w.writerow(("case", "tool", "round", "wall_ms", "child_cpu_ms", "output_bytes"))
    w.writerows(rows)
for case, tool in dict.fromkeys((r[0], r[1]) for r in rows):
    group = [r for r in rows if r[0] == case and r[1] == tool]
    print(case, tool, *(round(statistics.median(r[i] for r in group), 3) for i in (3, 4)), group[0][5])

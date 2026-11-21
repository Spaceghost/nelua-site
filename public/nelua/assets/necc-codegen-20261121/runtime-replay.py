#!/usr/bin/env python3
"""Compile the Nelua site arithmetic fixture and compare its static Linux x86-64 executables."""
import argparse
import csv
from hashlib import sha256
import os
from pathlib import Path
import random
import shutil
from statistics import median
import subprocess
import sys
import tempfile
import time


KERNEL = """long kernel(long n, long x) {
    long i = 0;
    while (i < n) {
        x = (x * 33 + i + 17) & 1048575;
        i += 1;
    }
    return x;
}
"""

ENTRY = """.text
.globl _start
_start:
 mov $6000000,%edi
 mov $19,%esi
 call kernel
 push %rax
 mov $1,%edi
 mov %rsp,%rsi
 mov $8,%edx
 mov $1,%eax
 syscall
 cmp $8,%rax
 setne %dil
 movzbl %dil,%edi
 mov $60,%eax
 syscall
.section .note.GNU-stack,"",@progbits
"""


def executable(name):
    found = shutil.which(name)
    if not found:
        raise argparse.ArgumentTypeError("cannot find executable " + name)
    return str(Path(found).resolve())


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--before", required=True, type=executable)
    ap.add_argument("--after", required=True, type=executable)
    ap.add_argument("--zig", required=True, type=executable)
    ap.add_argument("--cpu", required=True, type=int)
    ap.add_argument("--rounds", type=int, default=31)
    args = ap.parse_args()
    if args.rounds < 1:
        ap.error("--rounds must be positive")
    os.sched_setaffinity(0, {args.cpu})
    with tempfile.TemporaryDirectory(prefix="necc-arithmetic-") as tmp:
        root = Path(tmp)
        src, asm, entry = root/"arithmetic.c", root/"driver.s", root/"driver.o"
        src.write_text(KERNEL)
        asm.write_text(ENTRY)
        subprocess.run(["as", "--64", asm, "-o", entry], check=True)
        commands = {"necc-before": [args.before], "necc-after": [args.after],
                    "Zig-O2": [args.zig, "cc", "-O2", "-mcpu=x86_64", "-g0", "-fno-sanitize=all"]}
        programs = {}
        for name, cmd in commands.items():
            obj, elf = root/(name+".o"), root/(name+".elf")
            subprocess.run([*cmd, "-DNEBENCH_SAMPLE=0", "-c", src, "-o", obj], check=True)
            subprocess.run(["ld.bfd", "-static", "-e", "_start", "-o", elf, entry, obj], check=True)
            programs[name] = elf
            print(name, "ELF sha256", sha256(elf.read_bytes()).hexdigest(), file=sys.stderr)
        value = 19
        for i in range(6000000):
            value = (33 * value + i + 17) & 1048575
        expected = value.to_bytes(8, "little")
        order = random.Random(60491)
        results = {name: [] for name in commands}
        writer = csv.writer(sys.stdout, lineterminator="\n")
        writer.writerow(["round", "program", "elapsed_ns"])
        for rep in range(args.rounds + 1):
            names = list(programs)
            order.shuffle(names)
            for name in names:
                start = time.perf_counter_ns()
                with subprocess.Popen([programs[name]], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                      process_group=0) as child:
                    stdout, stderr = child.communicate(timeout=60)
                    elapsed = time.perf_counter_ns() - start
                    if child.returncode or stdout != expected or stderr:
                        raise RuntimeError(f"{name}: output verification failed")
                if rep:
                    writer.writerow([rep, name, elapsed])
                    results[name].append(elapsed / 1e6)
        for name, times in results.items():
            print(name, "median ms", round(median(times), 4), file=sys.stderr)


if __name__ == "__main__":
    main()

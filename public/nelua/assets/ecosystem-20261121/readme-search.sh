#!/bin/sh
set -eu
# Run from a scratch directory containing both readme-search files.
# Pass absolute paths to clean-built previous and updated GCC hybrid trees.
for t in baseline candidate reference; do
 case "$t" in baseline) archive="$1/build/libnelibc-gcc.a";; candidate) archive="$2/build/libnelibc-gcc.a";; reference) archive=;; esac
 gcc -O2 -fno-builtin readme-search.c ${archive:+"$archive"} -pthread -lm -o "$t"
done
cpu=$(python3 -c 'import os;print(min(os.sched_getaffinity(0)))')
echo round,tool,function,term,first_offset,ns_per_call
for i in 0 1 2 3 4 5 6; do
 case $((i%3)) in 0) order="baseline candidate reference";;1) order="candidate reference baseline";;2) order="reference baseline candidate";;esac
 for t in $order; do
  taskset -c "$cpu" "./$t" "$2/README.md" > samples
  sed "s/^/$i,$t,/" samples
 done
done

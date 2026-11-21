#!/bin/sh
# INPUT is substring_cases.c from the updated revision.
set -eu
: "${INPUT:?}" "${BEFORE:?}" "${AFTER:?}" "${CPU:?}"
for tool in baseline candidate reference; do
    case $tool in
        baseline) set -- "$BEFORE";;
        candidate) set -- "$AFTER";;
        reference) set -- ;;
    esac
    gcc -O2 -fno-builtin "$INPUT" "$@" -o "./$tool"
done
echo 'round,tool,function,case,position,first_offset,ns_per_call'
for round in 0 1 2 3 4 5 6 7 8 9; do
    case $((round % 3)) in
        1) order='baseline reference candidate';;
        2) order='reference candidate baseline';;
        0) order='candidate baseline reference';;
    esac
    for tool in $order; do
        taskset -c "$CPU" "./$tool" > "$tool.$round.csv"
        sed "s/^/$round,$tool,/" "$tool.$round.csv"
    done
done

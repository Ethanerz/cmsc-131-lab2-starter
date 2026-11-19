<!--no-pdf-->
# CMSC 131 Lab 2 Starter

[![lab2-checks](https://github.com/WhiteLicorice/cmsc-131-lab2-starter/actions/workflows/test.yml/badge.svg)](https://github.com/WhiteLicorice/cmsc-131-lab2-starter/actions/workflows/test.yml)

A C-callable library of sort, search, and utility routines in assembly. The manual is the assignment. This file is the repository's own notes.

## Layout

```text
Makefile       platform preamble and build rules
bench.c        provided: file I/O, timing, the C-side comparison, the hostile caller
cdecl.h        provided: the calling-convention macros
LICENSE        provided
sort.asm       yours
search.asm     yours
util.asm       yours
run_tests.sh   provided: the correctness gate
tests/         provided: the test corpus
```

## What to Run

On Windows, run these commands in Git Bash, the shell from Block 1. In that
shell, `make` is your alias for `mingw32-make`. On Linux, use your terminal.

```bash
make
make check
```

`make` builds `bench`. `make check` builds, then runs `./run_tests.sh`,
which reports each check and exits nonzero when any of them fail. Each run
is captured first. Its exit status is read before its text is examined,
so a program that prints the right line and then crashes still fails.

## Reading a First Run

The assembly files ship as stubs that assemble and link as-is, so the build
works before you write any code. Right now they do nothing useful, and 19
of the 36 checks fail. The seventeen that pass prove little. Four are files
that arrive empty, single-element, or already sorted. `gcd(0, 0)` expects 0.
The hostile caller cannot be upset by a stub that touches no register. The
rest are argument and file refusals that the harness performs before any
assembly runs. That red run is the correct starting state for a starter. The
badge stays red until you implement the routines.

The provided files are fixtures. The grader compares your fork against the
starter. An edit to `bench.c`, `Makefile`, `run_tests.sh`, or a `tests/`
file appears as a diff in the open.

## Documentation

The three sections at the end of this file are yours. Complete Design Notes
and Subsystem Ownership before the Week 1 progress report. Complete Quirks
and Issues before the Week 3 progress report. Each section says what it
needs. Leave the rest of this file as it is.

---

## Design Notes

Complete this section before the Week 1 progress report and finish it by
Week 3. The syllabus asks for problem analysis, a solution architecture,
and an estimated timeline. The manual's Deliverables section lists what
this activity adds. Keep each part short. Update it when the plan changes.

### Problem analysis

The four routines `bench.c` expects and what each one returns. Which
registers you preserve and why.

### Solution architecture

#### Sort (`sort.asm`)

`qsort_asm(arr, n)` is the only sort routine C calls. It returns at once
when n is 0 or 1. Otherwise it calls `qsort_inner(arr, 0, n - 1)` and
removes the three arguments with `add esp, 12`.

`qsort_inner` and `partition` are internal, but they follow the same
rules as cdecl: arguments start at `[ebp+8]`, the result comes back in
`eax`, and `ebx`, `esi` and `edi` are restored before returning. Using
one convention for all three routines means there is only one stack
layout to read.

`qsort_inner` keeps `arr` in `esi`, `lo` in `ebx` and `hi` in `edi`.
`partition` returns the pivot index `p` in `eax`, which the next call
is free to overwrite, so `p` is pushed before the first recursive call
and popped after it.

Frame of one `qsort_inner` call while its first recursive call runs:

```
[ebp+16]  hi
[ebp+12]  lo
[ebp+8]   arr
[ebp+4]   return address
[ebp]     saved ebp          (enter 0,0)
[ebp-4]   caller's ebx
[ebp-8]   caller's esi
[ebp-12]  caller's edi
[ebp-16]  p                  <- esp
          the next call's arr, lo, hi are pushed below this
```

The manual requires the sort to be recursive, and the algorithm needs
it: every call has its own `lo`, `hi` and `p`. Each call gets a fresh
frame, so the outer call's values are still in place when the inner
call returns.

The library is split into `sort.asm`, `search.asm` and `util.asm`.
NASM assembles each into its own object file, and the Makefile links
the three with `bench.c`. That meets the multi-module requirement, and
each owner works in a separate file.

### Measurements

The ratio `bench` reports on `random1000.txt`, `sorted1000.txt`,
`reverse1000.txt`, `duplicates.txt`, and `identical.txt`. Your worst case
and its cause. One improvement and its estimated effect.

| File | Ratio |
|---|---|
| `random1000.txt` | |
| `sorted1000.txt` | |
| `reverse1000.txt` | |
| `duplicates.txt` | |
| `identical.txt` | |

### Timeline

One line per week. Name the subsystem each week finishes and the member
who owns it.

| Week | Goal | Owner |
|---|---|---|
| 1 | | |
| 2 | | |
| 3 | | |
| 4 | Defense | |

## Subsystem Ownership

Complete this section before the Week 1 progress report. The manual lists
the three subsystems. Each member owns one. In a group of four, two members
share one. The commit history must agree with this table.

| Subsystem | Owner |
|---|---|
| Sorting (`qsort_asm` and its partition) | Lunele Iven Moscoso |
| Searching (`bsearch_asm`, `gcd_asm`) | Ethan Gapulan |
| Convention and measurement (`sum_range_asm`, the benchmarks) | Marc Raven Sian |

## Quirks and Issues

Complete this section before the Week 3 progress report. The syllabus asks
for documentation of quirks and issues with the complete implementation.
One entry per item. State what happens, what causes it, and what the group
did about it.

### Known issues

- 

### Quirks

- 

#!/bin/bash
#
# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# gate.sh: the golden gate. Runs the //toolchain/testing:file_test binary
# ($FILE_TEST_BIN, linked by author A's build.sh) the way `bazel test` does:
# cwd $RUNFILES_ROOT/_main, RUNFILES_DIR/TEST_SRCDIR at the runfiles tree that
# runfiles.py lays out over the install and the repository, TEST_TMPDIR under
# BUILD_DIR, the cc_env() variables from env.sh when author A provides it.
#
#   gate.sh                      whole manifest (2047 tests on cb726a230)
#   gate.sh --filter SUBSTR      only tests whose repo path contains SUBSTR
#                                (becomes --file_tests=*SUBSTR*, a gtest_filter
#                                wildcard; testing/file_test/file_test_base.cpp:337-348)
#   gate.sh --threads N          passed through (0 = auto)
#   gate.sh --check              build the runfiles tree and verify every path
#                                the binary opens; do not run it
#   gate.sh -- ARGS...           extra arguments for the binary (e.g. --gtest_brief=0)
#
# Prints the gtest summary and one final line
#   GATE <sha>: <passed> passed, <failed> failed
# and exits non-zero on any failure (or when the binary did not print a gtest
# summary). Logs: $LOGS/gate-<sha>-<timestamp>.log.
set -u
set -o pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=paths.sh
. "$HERE/paths.sh"

MODE_CHECK=0
FILTER=""
THREADS=""
AUTOUPDATE="${GATE_AUTOUPDATE:-0}"
EXTRA=()
while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE_CHECK=1; shift ;;
    --filter) FILTER="$2"; shift 2 ;;
    --filter=*) FILTER="${1#--filter=}"; shift ;;
    --threads) THREADS="$2"; shift 2 ;;
    --threads=*) THREADS="${1#--threads=}"; shift ;;
    --autoupdate) AUTOUPDATE=1; shift ;;   # used by autoupdate.sh
    --) shift; EXTRA=("$@"); break ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "gate.sh: unknown argument $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$LOGS" "$TEST_TMP" "$CACHE_HOME"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
KIND=gate
if [ "$AUTOUPDATE" = 1 ]; then KIND=autoupdate; fi
LOG="$LOGS/$KIND-$SHA-$STAMP.log"

# 1. The runfiles tree (built idempotently, then verified).
if ! python3 -I "$HERE/runfiles.py" --quiet; then
  echo "$KIND: runfiles tree at $RUNFILES_ROOT does not verify; see above" >&2
  exit 1
fi
if [ "$MODE_CHECK" = 1 ]; then
  if [ -x "$FILE_TEST_BIN" ]; then
    echo "$KIND --check: ok; binary $FILE_TEST_BIN present"
  else
    echo "$KIND --check: ok; PENDING binary $FILE_TEST_BIN (author A's build.sh)"
  fi
  exit 0
fi
if [ ! -x "$FILE_TEST_BIN" ]; then
  echo "$KIND: $FILE_TEST_BIN is not an executable; run build.sh first" >&2
  exit 1
fi
if [ ! -f "$INSTALL_DIR/lib/carbon/carbon-busybox" ] || [ ! -f "$INSTALL_DIR/lib/carbon/install_digest.txt" ]; then
  echo "$KIND: the install at $INSTALL_DIR is incomplete (busybox or digest missing); run install.py" >&2
  exit 1
fi

# 2. Bazel's test environment.
export RUNFILES_DIR="$RUNFILES_ROOT"
export TEST_SRCDIR="$RUNFILES_ROOT"
export TEST_WORKSPACE=_main
export TEST_TMPDIR="$TEST_TMP"
export XDG_CACHE_HOME="$CACHE_HOME"
unset BUILD_WORKING_DIRECTORY RUNFILES_MANIFEST_FILE
# cc_env() of bazel/cc_toolchains/defs.bzl (LLVM_SYMBOLIZER_PATH, UBSAN_OPTIONS,
# ...), written by author A's build.
if [ -f "$HERE/env.sh" ]; then
  # shellcheck source=/dev/null
  . "$HERE/env.sh"
fi
# Fresh TEST_TMPDIR for this run (only ever a directory under ARB).
case "$(realpath -m "$TEST_TMP")" in
  "$(realpath -m "$ARB")"/*) find "$TEST_TMP" -mindepth 1 -delete 2>/dev/null || true ;;
  *) echo "$KIND: TEST_TMP=$TEST_TMP is not under ARB; not cleaning it" >&2 ;;
esac
mkdir -p "$TEST_TMP"

ARGS=()
if [ -n "$FILTER" ]; then ARGS+=("--file_tests=*${FILTER}*"); fi
if [ -n "$THREADS" ]; then ARGS+=("--threads=$THREADS"); fi
if [ "$AUTOUPDATE" = 1 ]; then ARGS+=("--autoupdate"); fi
ARGS+=("${EXTRA[@]}")

echo "$KIND $SHA: $FILE_TEST_BIN ${ARGS[*]} (cwd $RUNFILES_ROOT/_main; log $LOG)"
cd "$RUNFILES_ROOT/_main" || exit 1
"$FILE_TEST_BIN" "${ARGS[@]}" 2>&1 | tee "$LOG"
RC=${PIPESTATUS[0]}

# Source patches compiled into the binary (gen_ninja.py apply_source_patches,
# fold after review 1 R1-B1): the measurement is of REPO at SHA plus these.
PATCHES_APPLIED="$BUILD_DIR/src-patches.applied"
if [ -s "$PATCHES_APPLIED" ]; then
  echo "$KIND $SHA: source patches in $FILE_TEST_BIN (SRC_PATCHES=${SRC_PATCHES:-unset}): $(tr '\n' ';' < "$PATCHES_APPLIED")" | tee -a "$LOG"
fi

if [ "$AUTOUPDATE" = 1 ]; then
  echo "autoupdate $SHA: binary exit $RC (log $LOG)"
  exit "$RC"
fi

# 3. Summary. With --gtest_brief=1 (the binary's default) gtest prints
# `[  PASSED  ] N tests.` and, on failures, `[  FAILED  ] N tests, listed below:`
# followed by one `[  FAILED  ] Suite.name` line per test.
PASSED=$(grep -E '^\[  PASSED  \] [0-9]+ tests?' "$LOG" | tail -1 | sed -E 's/^\[  PASSED  \] ([0-9]+) .*/\1/')
FAILED=$(grep -E '^\[  FAILED  \] [0-9]+ tests?, listed below' "$LOG" | tail -1 | sed -E 's/^\[  FAILED  \] ([0-9]+) .*/\1/')
PASSED=${PASSED:-0}
FAILED=${FAILED:-0}
grep -E '^\[  FAILED  \] [A-Za-z]' "$LOG" | sed 's/^/  /' | head -50
grep -E '^Ran [0-9]+ tests in' "$LOG" | tail -1
if ! grep -qE '^\[  PASSED  \] [0-9]+ tests?' "$LOG"; then
  echo "GATE $SHA: $PASSED passed, $FAILED failed (NO GTEST SUMMARY; binary exit $RC)"
  exit 1
fi
echo "GATE $SHA: $PASSED passed, $FAILED failed"
if [ "$FAILED" != 0 ] || [ "$RC" != 0 ]; then
  exit 1
fi
exit 0

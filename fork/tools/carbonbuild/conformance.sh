#!/bin/bash
#
# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# conformance.sh: run the execution-conformance harness
# (fork/conformance/runner.py, see fork/conformance/README.md) against the
# installed busybox:
#
#   cd $REPO && XDG_CACHE_HOME=$CACHE_HOME python3 -I fork/conformance/runner.py \
#       --toolchain $INSTALL_DIR/lib/carbon/carbon-busybox --out $CONFORMANCE_OUT [--filter X]
#
# The runner compiles, links and runs every program under
# fork/conformance/programs; `carbon link` builds the runtimes (compiler-rt
# builtins, libc++, the prelude objects) on demand into the runtimes cache
# under $XDG_CACHE_HOME (toolchain/driver/runtimes_cache.cpp:142-163), so the
# FIRST link after a fresh install takes minutes (the runner's default
# --link-timeout is 1800 s); later links hit the cache, keyed on the install's
# install_digest.txt.
#
#   conformance.sh                 run in the foreground; prints the runner's
#                                  totals and `CONFORMANCE <sha>: PASS n / FAIL m / SKIP k ...`
#   conformance.sh --filter X      only programs whose path contains X
#   conformance.sh --background    start it under nohup and return at once;
#                                  wait with `until [ -f $CONFORMANCE_OUT/.done ]; do sleep 20; done`
#                                  (the marker holds the exit code) and read the log
#   conformance.sh --check         verify the inputs (busybox, runner, its
#                                  --self-test, writable cache); run no program
#   conformance.sh -- ARGS...      extra runner arguments
#
# Log: $LOGS/conformance-<sha>.log (overwritten per run). Exit: the runner's
# (1 if any non-SKIP program fails).
set -u
set -o pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=paths.sh
. "$HERE/paths.sh"

MODE_CHECK=0
BACKGROUND=0
FILTER=""
EXTRA=()
ORIG_ARGS=("$@")
while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE_CHECK=1; shift ;;
    --background) BACKGROUND=1; shift ;;
    --filter) FILTER="$2"; shift 2 ;;
    --filter=*) FILTER="${1#--filter=}"; shift ;;
    --) shift; EXTRA=("$@"); break ;;
    -h|--help) sed -n '2,32p' "$0"; exit 0 ;;
    *) echo "conformance.sh: unknown argument $1" >&2; exit 2 ;;
  esac
done

BUSYBOX="$INSTALL_DIR/lib/carbon/carbon-busybox"
RUNNER="$REPO/fork/conformance/runner.py"
LOG="$LOGS/conformance-$SHA.log"
DONE="$CONFORMANCE_OUT/.done"
mkdir -p "$LOGS" "$CACHE_HOME" "$CONFORMANCE_OUT"
# The runner imports fork/evaluator/check_samples.py and fork/designdocs/
# check_samples.py from REPO; `-B` keeps python from writing __pycache__ there
# (`-I` ignores PYTHONDONTWRITEBYTECODE, so the flag is needed).
PY=(python3 -I -B)

if [ ! -f "$RUNNER" ]; then
  echo "conformance: $RUNNER does not exist" >&2
  exit 1
fi

if [ "$MODE_CHECK" = 1 ]; then
  RC=0
  if [ -x "$BUSYBOX" ]; then
    echo "ok: busybox $BUSYBOX"
  else
    echo "PENDING: busybox $BUSYBOX (install.py after author A's build.sh)"
  fi
  if [ -f "$INSTALL_DIR/lib/carbon/install_digest.txt" ]; then
    echo "ok: install_digest.txt (runtimes cache key)"
  else
    echo "PENDING: $INSTALL_DIR/lib/carbon/install_digest.txt"
  fi
  if [ -L "$INSTALL_DIR/lib/carbon/llvm/bin/clang++" ]; then
    echo "ok: llvm/bin/clang++ symlink (runner.py find_clangxx)"
  else
    echo "ERROR: $INSTALL_DIR/lib/carbon/llvm/bin/clang++ missing"; RC=1
  fi
  if [ -w "$CACHE_HOME" ]; then
    echo "ok: XDG_CACHE_HOME=$CACHE_HOME writable"
  else
    echo "ERROR: $CACHE_HOME not writable"; RC=1
  fi
  echo "--- runner --self-test (program headers and bullet names; no toolchain needed)"
  if (cd "$REPO" && "${PY[@]}" "$RUNNER" --self-test --out "$CONFORMANCE_OUT" > "$LOGS/conformance-$SHA-selftest.log" 2>&1); then
    tail -3 "$LOGS/conformance-$SHA-selftest.log"
    echo "ok: runner --self-test"
  else
    tail -20 "$LOGS/conformance-$SHA-selftest.log"
    echo "ERROR: runner --self-test failed (log $LOGS/conformance-$SHA-selftest.log)"; RC=1
  fi
  echo "conformance --check: $([ "$RC" = 0 ] && echo ok || echo FAILED)"
  exit "$RC"
fi

if [ "$BACKGROUND" = 1 ]; then
  rm -f "$DONE"
  FG_ARGS=()
  for a in "${ORIG_ARGS[@]}"; do
    if [ "$a" != "--background" ]; then FG_ARGS+=("$a"); fi
  done
  nohup "$0" "${FG_ARGS[@]}" > "$LOG.nohup" 2>&1 &
  echo "conformance $SHA: started in the background (pid $!); log $LOG, marker $DONE"
  exit 0
fi

if [ ! -x "$BUSYBOX" ]; then
  echo "conformance: $BUSYBOX is not an executable; run build.sh and install.py first" >&2
  exit 1
fi

rm -f "$DONE"
ARGS=(--toolchain "$BUSYBOX" --out "$CONFORMANCE_OUT")
if [ -n "$FILTER" ]; then ARGS+=(--filter "$FILTER"); fi
ARGS+=("${EXTRA[@]}")
export XDG_CACHE_HOME="$CACHE_HOME"
unset BUILD_WORKING_DIRECTORY
echo "conformance $SHA: python3 -I fork/conformance/runner.py ${ARGS[*]} (cwd $REPO; log $LOG)"
(cd "$REPO" && "${PY[@]}" "$RUNNER" "${ARGS[@]}") > "$LOG" 2>&1
RC=$?
echo "$RC" > "$DONE"

# The runner's totals block ("=== totals ===": one `  <STATUS> <n>` line per
# status and a `  bullets: ...` line) and its final scoreboard path.
sed -n '/^=== totals ===/,$p' "$LOG"
PASS_N=$(grep -E '^  PASS +[0-9]+$' "$LOG" | awk '{print $2}' | tail -1)
SKIP_N=$(grep -E '^  SKIP +[0-9]+$' "$LOG" | awk '{print $2}' | tail -1)
FAIL_N=$(grep -E '^  (COMPILE-FAIL|LINK-FAIL|RUN-FAIL|OUTPUT-MISMATCH|DIFF-MISMATCH) +[0-9]+$' "$LOG" | awk '{s+=$2} END {print s+0}')
TOTAL=$(grep -cE '^\[[A-Z-]+\] ' "$LOG")
BULLETS=$(grep -E '^  bullets: ' "$LOG" | tail -1 | sed 's/^  bullets: //')
echo "CONFORMANCE $SHA: PASS ${PASS_N:-?} / FAIL ${FAIL_N:-?} / SKIP ${SKIP_N:-?} over $TOTAL programs; bullets ${BULLETS:-?} (runner exit $RC)"
exit "$RC"

#!/bin/bash
#
# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# autoupdate.sh: run the file_test binary with --autoupdate (the same runfiles
# tree, environment and cwd as gate.sh; testing/file_test/file_test_base.cpp:62
# `--autoupdate`), then show which goldens changed. This is the ONE script
# whose documented job is to write into REPO: the test files are reached
# through the runfiles symlinks toolchain/<component>/testdata -> $REPO/...,
# and the autoupdater writes std::filesystem::absolute(test_name)
# (file_test_base.cpp:215-230, autoupdate.cpp).
#
#   autoupdate.sh                  whole manifest
#   autoupdate.sh --filter SUBSTR  only tests whose repo path contains SUBSTR
#   autoupdate.sh --threads N
#   autoupdate.sh --check          verify the runfiles tree, that every testdata
#                                  link points into REPO and that REPO is a git
#                                  work tree whose status can be read; run nothing
#
# Prints `git -C $REPO status --porcelain` at the end (empty = no golden
# changed) and a final line `AUTOUPDATE <sha>: <n> file(s) changed`.
# Exit: the binary's exit code, or 1 when the checks fail.
set -u
set -o pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=paths.sh
. "$HERE/paths.sh"

MODE_CHECK=0
PASS=()
for a in "$@"; do
  case "$a" in
    --check) MODE_CHECK=1 ;;
    -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
    *) PASS+=("$a") ;;
  esac
done

if ! git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "autoupdate: REPO=$REPO is not a git work tree" >&2
  exit 1
fi
BEFORE="$(git -C "$REPO" status --porcelain)"
if [ -n "$BEFORE" ]; then
  echo "autoupdate: note: REPO already has local changes:" >&2
  echo "$BEFORE" | sed 's/^/  /' >&2
fi

if [ "$MODE_CHECK" = 1 ]; then
  # gate.sh --check builds and verifies the runfiles tree (runfiles.py checks
  # that each toolchain/<component>/testdata link resolves into REPO).
  "$HERE/gate.sh" --check || exit 1
  # Prove write-through: the autoupdater's absolute path of a test file is a
  # path under the runfiles tree whose realpath is the golden in REPO.
  SAMPLE="$(find "$REPO/toolchain/check/testdata" -name '*.carbon' | head -1)"
  REL="${SAMPLE#"$REPO"/}"
  REAL="$(realpath "$RUNFILES_ROOT/_main/$REL")"
  if [ "$REAL" != "$(realpath "$SAMPLE")" ]; then
    echo "autoupdate --check: $RUNFILES_ROOT/_main/$REL resolves to $REAL, not to the golden $SAMPLE" >&2
    exit 1
  fi
  echo "autoupdate --check: ok; $RUNFILES_ROOT/_main/$REL -> $REAL (write-through into REPO)"
  echo "AUTOUPDATE $SHA: check only, 0 file(s) changed"
  exit 0
fi

GATE_AUTOUPDATE=1 "$HERE/gate.sh" --autoupdate "${PASS[@]}"
RC=$?
echo "--- git -C $REPO status --porcelain"
AFTER="$(git -C "$REPO" status --porcelain)"
if [ -n "$AFTER" ]; then echo "$AFTER"; fi
CHANGED=0
if [ -n "$AFTER" ]; then CHANGED=$(echo "$AFTER" | wc -l); fi
echo "AUTOUPDATE $SHA: $CHANGED file(s) changed (binary exit $RC)"
exit "$RC"

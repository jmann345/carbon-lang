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
# Prints `git -C $REPO status --porcelain` at the end (empty = no local
# change), the paths this run changed, and a final line
#   AUTOUPDATE <sha>: <n> file(s) changed by this run; <m> pre-existing local change(s) untouched
# where <n> counts the paths whose content this run changed (compared by hash
# before and after, so an uncommitted fill from an earlier pass is not counted
# again: a fixpoint pass prints 0) and <m> the local changes it left as they
# were. Exit: the binary's exit code, or 1 when the checks fail.
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
    -h|--help) sed -n '2,28p' "$0"; exit 0 ;;
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

# A content snapshot of REPO's local changes: one sorted `<sha256> <path>` line
# per path of `git status --porcelain` (an untracked directory is hashed over
# its files, a missing path as `deleted`). Two snapshots, before and after the
# run, tell which paths THIS run changed (ARB-3, 2026-11-16: the count used to
# be the porcelain line count against HEAD, so an uncommitted fill from an
# earlier pass was counted again on a no-op pass).
snapshot() {
  git -C "$REPO" status --porcelain -z | while IFS= read -r -d '' entry; do
    p="${entry:3}"
    case "${entry:0:2}" in
      R?|C?) IFS= read -r -d '' _src ;;   # the rename source follows
    esac
    if [ -d "$REPO/$p" ]; then
      h=$( (cd "$REPO" && find "$p" -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) | sha256sum | cut -c1-64)
    elif [ -e "$REPO/$p" ]; then
      h=$(sha256sum "$REPO/$p" | cut -c1-64)
    else
      h=deleted
    fi
    echo "$h $p"
  done | LC_ALL=C sort
}

BEFORE_SNAP="$(snapshot)"
GATE_AUTOUPDATE=1 "$HERE/gate.sh" --autoupdate "${PASS[@]}"
RC=$?
AFTER_SNAP="$(snapshot)"
echo "--- git -C $REPO status --porcelain"
AFTER="$(git -C "$REPO" status --porcelain)"
if [ -n "$AFTER" ]; then echo "$AFTER"; fi
# A `<hash> <path>` line present in both snapshots is a pre-existing local
# change this run left untouched; every other path of either snapshot (newly
# modified or untracked, modified differently, or written back to HEAD) is one
# this run changed.
UNTOUCHED=$(LC_ALL=C comm -12 <(echo "$BEFORE_SNAP") <(echo "$AFTER_SNAP") | sed '/^$/d' | wc -l)
CHANGED_PATHS=$(LC_ALL=C comm -3 <(echo "$BEFORE_SNAP") <(echo "$AFTER_SNAP") | sed 's/^\t//; /^$/d' | cut -d' ' -f2- | LC_ALL=C sort -u)
CHANGED=0
if [ -n "$CHANGED_PATHS" ]; then
  CHANGED=$(echo "$CHANGED_PATHS" | wc -l)
  echo "--- changed by this run"
  echo "$CHANGED_PATHS" | sed 's/^/  /'
fi
echo "AUTOUPDATE $SHA: $CHANGED file(s) changed by this run; $UNTOUCHED pre-existing local change(s) untouched (binary exit $RC)"
exit "$RC"

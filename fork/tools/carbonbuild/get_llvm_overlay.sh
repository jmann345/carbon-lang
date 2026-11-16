#!/bin/bash
#
# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# get_llvm_overlay.sh: make the patched copy of LLVM's Bazel overlay that
# gen_ninja.py / install.py evaluate for the runtimes file groups.
#
# Carbon's MODULE.bazel applies bazel/llvm_project/*.patch to llvm-project before
# the Bazel overlay (utils/bazel/llvm-project-overlay) is used. This script reads
# the patches of the directory LLVM_PATCHES (default: $REPO/bazel/llvm_project)
# and applies, in name order, those whose `+++ b/` paths all lie under
# utils/bazel/ (the overlay BUILD.bazel and .bzl files); a patch touching only
# sources (0001, llvm/lib/Support, which only matters for a Bazel-built LLVM) is
# skipped, and one touching both stops the script. At Carbon's old pin
# 6ec87e7ec4b3 (trunk's tree) that is 0002 0004 0005 0006 0012; at the tip's pin
# c744694c6ae1 (upstream 7a3608bab's tree) 0012 0013, the overlay there holding
# the libcxx/libcxxabi/libunwind filegroups and the fuzzer target itself. The
# patches must be the ones of the tree whose MODULE.bazel pins LLVM_SRC's
# commit: to make the tip pin's overlay from a tree written against the old pin,
# pass LLVM_PATCHES=<a directory holding that tree's patches> (ARB-4).
#
# The copy lives at the parent of $LLVM_OVERLAY, which paths.sh defines as
# <root>/utils/bazel/llvm-project-overlay (default root $DEPS/llvm-overlay;
# $DEPS/llvm-overlay-c744694 for the tip pin). $LLVM_SRC itself is never
# modified. Re-runnable: a root holding PATCHED is left as it is; a root without
# it (an interrupted run) must be removed by hand first.
set -euo pipefail
. "$(dirname "$(readlink -f "$0")")/paths.sh"

case "$LLVM_OVERLAY" in
  */utils/bazel/llvm-project-overlay)
    ROOT="${LLVM_OVERLAY%/utils/bazel/llvm-project-overlay}" ;;
  *)
    echo "get_llvm_overlay.sh: LLVM_OVERLAY=$LLVM_OVERLAY does not end in /utils/bazel/llvm-project-overlay" >&2
    exit 1 ;;
esac
if [ -f "$ROOT/PATCHED" ]; then
  echo "get_llvm_overlay.sh: $ROOT already patched ($(cat "$ROOT/PATCHED"))"
  exit 0
fi
if [ -e "$ROOT" ]; then
  echo "get_llvm_overlay.sh: $ROOT exists without PATCHED (an interrupted run); remove it first" >&2
  exit 1
fi
LLVM_PATCHES="${LLVM_PATCHES:-$REPO/bazel/llvm_project}"
if [ ! -d "$LLVM_PATCHES" ]; then
  echo "get_llvm_overlay.sh: LLVM_PATCHES=$LLVM_PATCHES is not a directory" >&2
  exit 1
fi
if [ ! -d "$LLVM_SRC/utils/bazel/llvm-project-overlay" ]; then
  echo "get_llvm_overlay.sh: $LLVM_SRC/utils/bazel/llvm-project-overlay is missing" >&2
  exit 1
fi

# Classify the patches by the files they touch (`+++ b/<path>` lines, -p1).
apply=()
applied=""
skipped=""
for f in "$LLVM_PATCHES"/*.patch; do
  [ -e "$f" ] || { echo "get_llvm_overlay.sh: no *.patch in $LLVM_PATCHES" >&2; exit 1; }
  name="$(basename "$f")"
  overlay=$(grep -c '^+++ b/utils/bazel/' "$f" || true)
  other=$(grep '^+++ b/' "$f" | grep -vc '^+++ b/utils/bazel/' || true)
  if [ "$overlay" -eq 0 ] && [ "$other" -eq 0 ]; then
    echo "get_llvm_overlay.sh: $f has no \`+++ b/<path>\` line (not a -p1 git-style patch)" >&2
    exit 1
  elif [ "$overlay" -gt 0 ] && [ "$other" -gt 0 ]; then
    echo "get_llvm_overlay.sh: $f touches both the overlay and sources; not supported" >&2
    exit 1
  elif [ "$overlay" -gt 0 ]; then
    apply+=("$f")
    applied="$applied ${name%%_*}"
  else
    skipped="$skipped ${name%%_*}"
  fi
done
if [ "${#apply[@]}" -eq 0 ]; then
  echo "get_llvm_overlay.sh: no overlay patch in $LLVM_PATCHES" >&2
  exit 1
fi

mkdir -p "$ROOT/utils/bazel"
cp -r "$LLVM_SRC/utils/bazel/llvm-project-overlay" "$ROOT/utils/bazel/"
cp "$LLVM_SRC/utils/bazel/configure.bzl" "$ROOT/utils/bazel/"
for f in "${apply[@]}"; do
  echo "applying $f"
  patch -p1 -N -d "$ROOT" -i "$f"
done
commit="$(git -C "$LLVM_SRC" rev-parse HEAD 2>/dev/null || echo unknown)"
echo "patches:${applied} from $LLVM_PATCHES (source patches skipped:${skipped:- none}); overlay from llvm-project $commit at $LLVM_SRC" > "$ROOT/PATCHED"
echo "get_llvm_overlay.sh: done ($(cat "$ROOT/PATCHED"))"

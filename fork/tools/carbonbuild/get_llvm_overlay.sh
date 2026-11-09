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
# the Bazel overlay (utils/bazel/llvm-project-overlay) is used. Patches 0002,
# 0004, 0005, 0006 and 0012 add/alter overlay BUILD.bazel and .bzl files
# (compiler-rt fuzzer, libunwind/libcxx/libcxxabi source-exporting filegroups,
# libc math excludes, libc deps). Patch 0001 touches llvm/lib/Support (a source
# file, not the overlay) and is not applied: it only matters for Bazel-built LLVM.
#
# The copy lives at $DEPS/llvm-overlay/utils/bazel/llvm-project-overlay
# ($LLVM_OVERLAY in paths.sh). $LLVM_SRC itself is never modified. Re-runnable.
set -euo pipefail
. "$(dirname "$(readlink -f "$0")")/paths.sh"

ROOT="$DEPS/llvm-overlay"
if [ -f "$ROOT/PATCHED" ]; then
  echo "get_llvm_overlay.sh: $ROOT already patched"
  exit 0
fi
mkdir -p "$ROOT/utils/bazel"
cp -r "$LLVM_SRC/utils/bazel/llvm-project-overlay" "$ROOT/utils/bazel/"
cp "$LLVM_SRC/utils/bazel/configure.bzl" "$ROOT/utils/bazel/"
for p in 0002 0004 0005 0006 0012; do
  f=$(ls "$REPO"/bazel/llvm_project/${p}_*.patch)
  echo "applying $f"
  patch -p1 -N -d "$ROOT" -i "$f"
done
echo "patches: 0002 0004 0005 0006 0012 from $REPO/bazel/llvm_project (0001 is a source patch, skipped)" > "$ROOT/PATCHED"
echo "get_llvm_overlay.sh: done"

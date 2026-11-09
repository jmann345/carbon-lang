#!/bin/bash
#
# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# build.sh: build the Carbon toolchain binaries without Bazel.
#
#   build.sh [ninja targets...]        default: all (the three binaries). A target is
#     all, a binary name (file_test, carbon-busybox, make-installation-digest), its
#     bin/<name> form, or an absolute output path from build.ninja (its real outputs
#     are absolute; the short names are phony aliases, REVIEW-1 R1-N2).
#
# Steps: source paths.sh; make sure the compiler (get_clang.sh) and the patched
# LLVM overlay (get_llvm_overlay.sh) are present; regenerate $BUILD_DIR/build.ninja
# from the Bazel BUILD graph (gen_ninja.py, seconds); run ninja. Outputs:
#   $BUILD_DIR/bin/carbon-busybox, bin/file_test, bin/make-installation-digest
# Log: $ARB/logs/build-$SHA.log (ninja's output is appended).
#
# Environment: JOBS (default: 2 while an `ninja -j4` LLVM build is running, else
# nproc), CXX, CARBON_BUILD_MODE (opt|fastbuild), REPO/SHA/... (see paths.sh).
set -euo pipefail
CB_DIR="$(dirname "$(readlink -f "$0")")"
. "$CB_DIR/paths.sh"

mkdir -p "$BUILD_DIR" "$ARB/logs"
LOG="$ARB/logs/build-$SHA.log"

if [ ! -x "$CXX" ] && [ "$CXX" = "$DEPS/llvm21/bin/clang++" ]; then
  "$CB_DIR/get_clang.sh"
fi
"$CB_DIR/get_llvm_overlay.sh"
if [ ! -f "$DEPS/deps.env" ]; then
  echo "build.sh: $DEPS/deps.env is missing; run $CB_DIR/deps.sh first" >&2
  exit 1
fi

if [ -z "${JOBS:-}" ]; then
  if pgrep -f 'ninja -j4' > /dev/null 2>&1; then
    JOBS=2
  else
    JOBS="$(nproc)"
  fi
fi

{
  echo "=== build.sh $(date -u +%Y-%m-%dT%H:%M:%SZ) REPO=$REPO SHA=$SHA MODE=$CARBON_BUILD_MODE CXX=$CXX JOBS=$JOBS"
  python3 -I "$CB_DIR/gen_ninja.py"
} 2>&1 | tee -a "$LOG"

ninja -C "$BUILD_DIR" -j"$JOBS" "$@" 2>&1 | tee -a "$LOG"
status=${PIPESTATUS[0]}
echo "=== build.sh done status=$status $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$LOG"
exit "$status"

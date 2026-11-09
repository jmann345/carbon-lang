#!/bin/bash
#
# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# deps.sh: fetch and build the third-party dependencies that Carbon's Bazel
# build normally gets from the Bazel Central Registry, without Bazel, into
# $DEPS, and describe them in $DEPS/deps.env for gen_ninja.py and the other
# scripts. See NOTES-B.md for the reasoning behind every choice.
#
# Usage:
#   deps.sh                      # all steps, in dependency order
#   deps.sh absl re2 googletest  # only the named steps, in the order given
# Steps: absl re2 googletest boost runfiles env validate smoke
#   (re2 needs absl installed; googletest needs absl and re2; env needs all.)
#
# Configuration: paths.sh next to this script (DEPS and CB are used).
#   DEPS_CC, DEPS_CXX  the compilers for the dependencies (default: the system
#                 clang/clang++, 18.1.3 here). These are deps.sh's OWN variables:
#                 paths.sh's CXX (the clang >= 21 that gen_ninja.py uses for the
#                 Carbon sources, installed later by get_clang.sh) is deliberately
#                 not consulted, so deps.sh works on a fresh container before
#                 get_clang.sh has run (REVIEW-1 R1-M1). To build the deps with
#                 the same clang as Carbon: DEPS_CXX=$DEPS/llvm21/bin/clang++
#                 DEPS_CC=$DEPS/llvm21/bin/clang deps.sh (the stamps record the
#                 compiler, so a different one rebuilds every compiled dep).
#   JOBS=N        parallelism (default: 2 while an LLVM 'ninja -j4' is running
#                 in this container, else nproc)
#   FETCH_ONLY=1  clone the sources only, build nothing
#
# Re-runnable: a dependency is skipped when <prefix>/.deps-installed records the
# pinned tag, commit and the compiler's --version line; delete that file to
# force a rebuild. Writes only under $DEPS. Never touches REPO.

set -euo pipefail

CB="${CB:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck source=paths.sh
. "$CB/paths.sh"

# ---- pinned versions: MODULE.bazel and .bazelversion of the repo -------------
ABSL_TAG=20260107.1;  ABSL_URL=https://github.com/abseil/abseil-cpp
GTEST_TAG=v1.17.0;    GTEST_URL=https://github.com/google/googletest
RE2_TAG=2025-11-05;   RE2_URL=https://github.com/google/re2
RULES_CC_TAG=0.2.25;  RULES_CC_URL=https://github.com/bazelbuild/rules_cc
# .bazelversion; source of the @bazel_tools//tools/cpp/runfiles forwarding header.
BAZEL_TAG=8.6.0
BOOST_TAG=boost-1.90.0
# boost.unordered 1.90.0.bcr.1 plus the transitive closure of its BCR module
# dependencies (each module's MODULE.bazel in bazel-central-registry; the
# umbrella module "boost" and rules_cc excluded).
BOOST_MODULES="unordered assert config container_hash core describe mp11 predef throw_exception"

# ---- toolchain flags -----------------------------------------------------------
# deps.sh-private compiler variables (see the header). Not CC/CXX: paths.sh sets
# CXX to the Carbon compiler, which need not exist yet when deps.sh runs.
DEPS_CC="${DEPS_CC:-clang}"
DEPS_CXX="${DEPS_CXX:-clang++}"
# cxx_id: the first line of `$DEPS_CXX --version`, recorded in every stamp of a
# compiled dependency and in deps.env, so that the archives are always described
# by (and rebuilt for) the compiler that produced them.
cxx_id() {
  command -v "$DEPS_CXX" >/dev/null 2>&1 || die "DEPS_CXX=$DEPS_CXX is not an executable compiler"
  "$DEPS_CXX" --version 2>/dev/null | head -1
}
# Carbon's cc toolchain applies -std=c++20 -fno-exceptions -fno-rtti
# -ffunction-sections -fdata-sections -fPIC to every C++ compile action,
# external repositories included (bazel/cc_toolchains/cc_toolchain_cpp_features.bzl,
# feature "clang", enabled unconditionally); .bazelrc adds -w for external
# sources and --dynamic_mode=off (static libraries only).
DEP_CXX_FLAGS="-fno-exceptions -fno-rtti -ffunction-sections -fdata-sections -w"
DEP_C_FLAGS="-ffunction-sections -fdata-sections -w"
DEP_OPT_FLAGS="-O2 -DNDEBUG"

SRC="$DEPS/src"
LOGS="$DEPS/logs"

if [ -z "${JOBS:-}" ]; then
  if pgrep -f 'ninja -j4' >/dev/null 2>&1; then JOBS=2; else JOBS="$(nproc)"; fi
fi

log() { printf '[deps.sh] %s\n' "$*"; }
die() { printf '[deps.sh] ERROR: %s\n' "$*" >&2; exit 1; }

# fetch_git URL TAG DIR: shallow clone at TAG unless DIR already is a checkout.
fetch_git() {
  local url="$1" tag="$2" dir="$3"
  if [ -d "$dir/.git" ]; then
    log "fetch: $dir present ($(git -C "$dir" describe --tags --always 2>/dev/null))"
    return 0
  fi
  log "fetch: $url @ $tag -> $dir"
  mkdir -p "$(dirname "$dir")"
  git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$tag" "$url" "$dir"
}

commit_of() { git -C "$1" rev-parse HEAD; }

# marker_ok PREFIX STAMP: true when PREFIX/.deps-installed holds exactly STAMP.
marker_ok() {
  [ -f "$1/.deps-installed" ] && [ "$(cat "$1/.deps-installed")" = "$2" ]
}

need_installed() {
  [ -f "$DEPS/$1/.deps-installed" ] || die "$2 needs $1 installed first: run deps.sh $1"
}

# cmake_build_install NAME SRCDIR PREFIX [extra cmake args...]
cmake_build_install() {
  local name="$1" srcdir="$2" prefix="$3"; shift 3
  local builddir="$DEPS/build/$name" logf="$LOGS/$name.log"
  mkdir -p "$builddir" "$LOGS"
  log "$name: configure (log: $logf)"
  cmake -S "$srcdir" -B "$builddir" -G Ninja \
    -DCMAKE_C_COMPILER="$DEPS_CC" -DCMAKE_CXX_COMPILER="$DEPS_CXX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=20 -DCMAKE_CXX_STANDARD_REQUIRED=ON -DCMAKE_CXX_EXTENSIONS=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="$DEP_C_FLAGS" -DCMAKE_CXX_FLAGS="$DEP_CXX_FLAGS" \
    -DCMAKE_C_FLAGS_RELEASE="$DEP_OPT_FLAGS" -DCMAKE_CXX_FLAGS_RELEASE="$DEP_OPT_FLAGS" \
    -DCMAKE_INSTALL_PREFIX="$prefix" -DCMAKE_INSTALL_LIBDIR=lib \
    "$@" > "$logf" 2>&1 || die "$name: cmake configure failed; see $logf"
  log "$name: build (ninja -j$JOBS)"
  ninja -C "$builddir" -j "$JOBS" >> "$logf" 2>&1 || die "$name: build failed; see $logf"
  log "$name: install -> $prefix"
  ninja -C "$builddir" install >> "$logf" 2>&1 || die "$name: install failed; see $logf"
}

# ---- abseil-cpp ------------------------------------------------------------------
dep_absl() {
  local src="$SRC/abseil-cpp" prefix="$DEPS/absl"
  fetch_git "$ABSL_URL" "$ABSL_TAG" "$src"
  if [ -n "${FETCH_ONLY:-}" ]; then return 0; fi
  local stamp="abseil-cpp $ABSL_TAG $(commit_of "$src") cxx=$(cxx_id)"
  if marker_ok "$prefix" "$stamp"; then log "absl: installed ($stamp)"; return 0; fi
  cmake_build_install absl "$src" "$prefix" \
    -DABSL_PROPAGATE_CXX_STD=ON \
    -DABSL_ENABLE_INSTALL=ON \
    -DABSL_BUILD_TESTING=OFF \
    -DABSL_BUILD_TEST_HELPERS=OFF \
    -DABSL_USE_EXTERNAL_GOOGLETEST=OFF
  echo "$stamp" > "$prefix/.deps-installed"
}

# ---- re2 (needs absl) --------------------------------------------------------------
dep_re2() {
  local src="$SRC/re2" prefix="$DEPS/re2"
  fetch_git "$RE2_URL" "$RE2_TAG" "$src"
  if [ -n "${FETCH_ONLY:-}" ]; then return 0; fi
  need_installed absl re2
  local stamp="re2 $RE2_TAG $(commit_of "$src") cxx=$(cxx_id) on $(cat "$DEPS/absl/.deps-installed")"
  if marker_ok "$prefix" "$stamp"; then log "re2: installed ($stamp)"; return 0; fi
  cmake_build_install re2 "$src" "$prefix" \
    -DRE2_BUILD_TESTING=OFF -DRE2_TEST=OFF -DRE2_BENCHMARK=OFF \
    -DCMAKE_PREFIX_PATH="$DEPS/absl"
  echo "$stamp" > "$prefix/.deps-installed"
}

# ---- googletest (needs absl and re2: Carbon builds it with --define=absl=1) -------
# Compiled directly, not with googletest's CMake: that CMake appends -fexceptions
# to every gtest target (googletest/cmake/internal_utils.cmake, cxx_default), which
# would override -fno-exceptions and diverge from the Bazel build, where Carbon's
# toolchain flags apply to googletest like to every other repository. Mirrors
# googletest's BUILD.bazel target "gtest" (googletest/src + googlemock/src,
# defines GTEST_HAS_ABSL=1, -pthread, deps on absl and re2) as the two amalgamated
# units gtest-all.cc and gmock-all.cc -> libgtest.a and libgmock.a.
dep_googletest() {
  local src="$SRC/googletest" prefix="$DEPS/googletest"
  fetch_git "$GTEST_URL" "$GTEST_TAG" "$src"
  if [ -n "${FETCH_ONLY:-}" ]; then return 0; fi
  need_installed absl googletest
  need_installed re2 googletest
  local stamp="googletest $GTEST_TAG $(commit_of "$src") direct GTEST_HAS_ABSL=1 cxx=$(cxx_id) on $(cut -d' ' -f1-3 "$DEPS/absl/.deps-installed"); $(cut -d' ' -f1-3 "$DEPS/re2/.deps-installed")"
  if marker_ok "$prefix" "$stamp"; then log "googletest: installed ($stamp)"; return 0; fi
  local build="$DEPS/build/googletest" logf="$LOGS/googletest.log"
  mkdir -p "$build" "$prefix/lib" "$prefix/include" "$LOGS"
  : > "$logf"
  local inc=(-I"$src/googletest/include" -I"$src/googletest"
             -I"$src/googlemock/include" -I"$src/googlemock"
             -I"$DEPS/absl/include" -I"$DEPS/re2/include")
  local unit
  for unit in googletest/src/gtest-all.cc googlemock/src/gmock-all.cc; do
    log "googletest: compile $unit"
    # shellcheck disable=SC2086
    "$DEPS_CXX" -std=c++20 $DEP_CXX_FLAGS $DEP_OPT_FLAGS -fPIC -pthread -DGTEST_HAS_ABSL=1 \
      "${inc[@]}" -c "$src/$unit" -o "$build/$(basename "$unit" .cc).o" >> "$logf" 2>&1 \
      || die "googletest: compile of $unit failed; see $logf"
  done
  rm -f "$prefix/lib/libgtest.a" "$prefix/lib/libgmock.a"
  ar rcs "$prefix/lib/libgtest.a" "$build/gtest-all.o"
  ar rcs "$prefix/lib/libgmock.a" "$build/gmock-all.o"
  log "googletest: install headers -> $prefix/include"
  cp -R "$src/googletest/include/." "$prefix/include/"
  cp -R "$src/googlemock/include/." "$prefix/include/"
  echo "$stamp" > "$prefix/.deps-installed"
}

# ---- boost.unordered (header-only; one assembled include root) --------------------
dep_boost() {
  local m prefix="$DEPS/boost"
  for m in $BOOST_MODULES; do
    fetch_git "https://github.com/boostorg/$m" "$BOOST_TAG" "$SRC/boost/$m"
  done
  if [ -n "${FETCH_ONLY:-}" ]; then return 0; fi
  local stamp="boost $BOOST_TAG"
  for m in $BOOST_MODULES; do
    stamp="$stamp $m=$(git -C "$SRC/boost/$m" rev-parse --short=12 HEAD)"
  done
  if marker_ok "$prefix" "$stamp"; then log "boost: assembled ($stamp)"; return 0; fi
  mkdir -p "$prefix/include"
  for m in $BOOST_MODULES; do
    log "boost: merge $m/include"
    cp -R "$SRC/boost/$m/include/." "$prefix/include/"
  done
  echo "$stamp" > "$prefix/.deps-installed"
}

# ---- runfiles: @bazel_tools//tools/cpp/runfiles -> @rules_cc//cc/runfiles --------
# Carbon includes "tools/cpp/runfiles/runfiles.h" and names
# bazel::tools::cpp::runfiles::Runfiles (toolchain/base/install_paths.cpp).
# In Bazel 8.6.0 that target is a forwarding header (tools/cpp/runfiles/BUILD.tools:
# hdrs = ["runfiles.h"], deps = ["@rules_cc//cc/runfiles"]) whose runfiles.h
# includes "rules_cc/cc/runfiles/runfiles.h" and typedefs the class. The real
# implementation is rules_cc 0.2.25's cc/runfiles/runfiles.{h,cc}.
write_runfiles_shim() {
  cat > "$1" <<'SHIM_EOF'
// Copyright 2018 The Bazel Authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Deprecated forwarder for the rules_cc runfiles library.
//
// Depend on @rules_cc//cc/runfiles instead and refer to its header file:
// https://github.com/bazelbuild/rules_cc/blob/main/cc/runfiles/runfiles.h

#ifndef TOOLS_CPP_RUNFILES_RUNFILES_H_
#define TOOLS_CPP_RUNFILES_RUNFILES_H_ 1

#include "rules_cc/cc/runfiles/runfiles.h"

namespace bazel {
namespace tools {
namespace cpp {
namespace runfiles {

typedef ::rules_cc::cc::runfiles::Runfiles Runfiles;

}  // namespace runfiles
}  // namespace cpp
}  // namespace tools
}  // namespace bazel

#endif  // TOOLS_CPP_RUNFILES_RUNFILES_H_
SHIM_EOF
}

dep_runfiles() {
  local src="$SRC/rules_cc" prefix="$DEPS/runfiles"
  fetch_git "$RULES_CC_URL" "$RULES_CC_TAG" "$src"
  if [ -n "${FETCH_ONLY:-}" ]; then return 0; fi
  local stamp="rules_cc $RULES_CC_TAG $(commit_of "$src") + bazel $BAZEL_TAG tools/cpp/runfiles/runfiles.h cxx=$(cxx_id)"
  if marker_ok "$prefix" "$stamp"; then log "runfiles: installed ($stamp)"; return 0; fi
  mkdir -p "$prefix/include/rules_cc/cc/runfiles" "$prefix/include/tools/cpp/runfiles" \
    "$prefix/src" "$prefix/lib" "$LOGS"
  cp "$src/cc/runfiles/runfiles.h" "$prefix/include/rules_cc/cc/runfiles/runfiles.h"
  cp "$src/cc/runfiles/runfiles.cc" "$prefix/src/runfiles.cc"
  # sha256 of bazel 8.6.0's tools/cpp/runfiles/runfiles.h (verified 2026-11-09).
  local shim="$prefix/include/tools/cpp/runfiles/runfiles.h"
  local shim_sha=80cbdbdb3662b12de206f854bb35184396de328620ea3d6a4c1578bde5836900
  local got_sha=
  if curl -sSf -m 120 -o "$shim.tmp" \
       "https://raw.githubusercontent.com/bazelbuild/bazel/$BAZEL_TAG/tools/cpp/runfiles/runfiles.h" 2>>"$LOGS/runfiles.log"; then
    got_sha="$(sha256sum "$shim.tmp" | cut -d' ' -f1)"
  fi
  if [ "$got_sha" = "$shim_sha" ]; then
    log "runfiles: fetched bazel $BAZEL_TAG tools/cpp/runfiles/runfiles.h (sha256 ok)"
  else
    log "runfiles: raw.githubusercontent.com fetch failed or differed; writing the equivalent forwarding header"
    write_runfiles_shim "$shim.tmp"
  fi
  mv "$shim.tmp" "$shim"
  # A static library for consumers that prefer linking to compiling RUNFILES_SRC.
  log "runfiles: compile librunfiles.a"
  # shellcheck disable=SC2086
  "$DEPS_CXX" -std=c++20 $DEP_CXX_FLAGS $DEP_OPT_FLAGS -fPIC -I"$prefix/include" \
    -c "$prefix/src/runfiles.cc" -o "$prefix/lib/runfiles.o" >> "$LOGS/runfiles.log" 2>&1 \
    || die "runfiles: compile failed; see $LOGS/runfiles.log"
  rm -f "$prefix/lib/librunfiles.a"
  ar rcs "$prefix/lib/librunfiles.a" "$prefix/lib/runfiles.o"
  echo "$stamp" > "$prefix/.deps-installed"
}

# ---- deps.env -----------------------------------------------------------------------
write_env() {
  local d
  for d in absl re2 googletest boost runfiles; do need_installed "$d" deps.env; done
  local env="$DEPS/deps.env"
  log "env: absl link order -> $DEPS/absl_libs.rsp"
  python3 -I "$CB/absl_link_order.py" "$DEPS/absl/lib/cmake/absl" "$DEPS/absl/lib" \
    > "$DEPS/absl_libs.rsp.tmp"
  mv "$DEPS/absl_libs.rsp.tmp" "$DEPS/absl_libs.rsp"
  # Everything a test binary links beyond LLVM, in order: gmock gtest re2 absl.
  {
    echo "$DEPS/googletest/lib/libgmock.a"
    echo "$DEPS/googletest/lib/libgtest.a"
    echo "$DEPS/re2/lib/libre2.a"
    cat "$DEPS/absl_libs.rsp"
  } > "$DEPS/test_link_libs.rsp"
  log "env: write $env"
  cat > "$env" <<EOF
# Generated by $CB/deps.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ). Do not edit; re-run deps.sh env.
# Shell variables with absolute paths; also parsed line-by-line by python scripts.
#
# Versions (MODULE.bazel and .bazelversion of the repo; tag then commit):
#   $(cut -d' ' -f1-3 "$DEPS/absl/.deps-installed")
#   $(cut -d' ' -f1-3 "$DEPS/re2/.deps-installed")   (built against the absl above)
#   $(cut -d' ' -f1-3 "$DEPS/googletest/.deps-installed")   (GTEST_HAS_ABSL=1, against the absl and re2 above)
#   $(cat "$DEPS/boost/.deps-installed")
#   $(cat "$DEPS/runfiles/.deps-installed")
#
# The libraries were built with (matching Carbon's cc toolchain for external code):
#   $DEPS_CXX ($(cxx_id)) -std=c++20 $DEP_CXX_FLAGS $DEP_OPT_FLAGS -fPIC, static archives only,
#   C++ standard library libstdc++ (the system clang's default; libc++ is not
#   installed in this container, Carbon's Bazel build would use libc++).
# Consumers must use the same compiler, -std=c++20, -fno-exceptions, -fno-rtti and
# standard library; -w and the optimization level are the libraries' own business.
DEPS=$DEPS
DEPS_CC=$DEPS_CC
DEPS_CXX=$DEPS_CXX
DEPS_CXX_VERSION="$(cxx_id)"
DEPS_CXX_STDLIB=libstdc++
DEPS_BUILT_WITH_CXX_FLAGS="-std=c++20 $DEP_CXX_FLAGS $DEP_OPT_FLAGS -fPIC"

# abseil-cpp. ABSL_LIBS is a response file (pass it to the linker as @\$ABSL_LIBS):
# one absolute libabsl_*.a path per line, every installed archive exactly once, in
# topological link order (dependents before dependencies), so a single pass over
# the archives resolves everything without --start-group.
ABSL_INCLUDE=$DEPS/absl/include
ABSL_LIB_DIR=$DEPS/absl/lib
ABSL_LIBS=$DEPS/absl_libs.rsp

# re2 (depends on absl: link RE2_LIB before @\$ABSL_LIBS).
RE2_INCLUDE=$DEPS/re2/include
RE2_LIB=$DEPS/re2/lib/libre2.a

# googletest built WITH abseil (GTEST_HAS_ABSL=1, like Carbon's --define=absl=1):
# every translation unit that includes gtest/gmock headers MUST be compiled with
# GTEST_DEFINES, or gtest's flags (FLAGS_gtest_filter etc., absl::Flag objects that
# testing/file_test/file_test_base.cpp sets with absl::SetFlag) do not match the
# library. gtest_main is NOT provided on purpose: Carbon has //testing/base:gtest_main
# and file_test has its own main. Link order: GTEST_LIBS, RE2_LIB, @ABSL_LIBS.
GTEST_INCLUDE=$DEPS/googletest/include
GTEST_LIBS="$DEPS/googletest/lib/libgmock.a $DEPS/googletest/lib/libgtest.a"
GTEST_DEFINES="-DGTEST_HAS_ABSL=1"

# Everything a Carbon test binary links beyond LLVM and the system libs, in order.
TEST_LINK_LIBS=$DEPS/test_link_libs.rsp

# boost.unordered 1.90.0 and its header dependencies, one include root.
BOOST_INCLUDE=$DEPS/boost/include

# Runfiles: include root where "tools/cpp/runfiles/runfiles.h" (Bazel 8.6.0 forwarder)
# and "rules_cc/cc/runfiles/runfiles.h" (rules_cc 0.2.25) resolve. Compile RUNFILES_SRC
# into the binary or link RUNFILES_LIB (same object, built with DEPS_BUILT_WITH_CXX_FLAGS).
RUNFILES_INCLUDE=$DEPS/runfiles/include
RUNFILES_SRC=$DEPS/runfiles/src/runfiles.cc
RUNFILES_LIB=$DEPS/runfiles/lib/librunfiles.a

# System libraries the dependencies need at link time.
DEPS_SYS_LIBS="-lpthread -lm"
EOF
  log "env: done"
}

# ---- validate: every path named in deps.env exists --------------------------------
validate_env() {
  local env="$DEPS/deps.env" missing=0 f
  [ -f "$env" ] || die "validate: $env missing; run deps.sh env"
  # shellcheck source=/dev/null
  . "$env"
  check() { if [ -e "$1" ]; then log "ok      $1"; else log "MISSING $1"; missing=$((missing+1)); fi; }
  check "$ABSL_INCLUDE/absl/base/config.h"
  check "$ABSL_INCLUDE/absl/container/flat_hash_map.h"
  check "$ABSL_LIBS"
  while IFS= read -r f; do [ -z "$f" ] || check "$f"; done < "$ABSL_LIBS"
  check "$RE2_INCLUDE/re2/re2.h"
  check "$RE2_LIB"
  check "$GTEST_INCLUDE/gtest/gtest.h"
  check "$GTEST_INCLUDE/gmock/gmock.h"
  for f in $GTEST_LIBS; do check "$f"; done
  check "$TEST_LINK_LIBS"
  check "$BOOST_INCLUDE/boost/unordered/unordered_flat_map.hpp"
  check "$RUNFILES_INCLUDE/tools/cpp/runfiles/runfiles.h"
  check "$RUNFILES_INCLUDE/rules_cc/cc/runfiles/runfiles.h"
  check "$RUNFILES_SRC"
  check "$RUNFILES_LIB"
  [ "$missing" -eq 0 ] || die "validate: $missing path(s) missing"
  log "validate: all paths in $env exist"
}

# ---- smoke: one program per dependency, compiled and linked against the install ---
smoke() {
  local env="$DEPS/deps.env" out="$DEPS/smoke" results
  [ -f "$env" ] || die "smoke: $env missing; run deps.sh env"
  # shellcheck source=/dev/null
  . "$env"
  mkdir -p "$out"
  log "smoke: compiler $DEPS_CXX (${DEPS_CXX_VERSION:-version not recorded}; from $env)"
  results="$out/RESULTS.txt"
  : > "$results"
  local base_flags="-std=c++20 -fno-exceptions -fno-rtti -O2 -DNDEBUG -fPIC"
  local rc=0 name
  run_smoke() {
    # run_smoke NAME [compile+link args...]: compile $CB/deps_smoke/NAME.cpp, run it.
    name="$1"; shift
    local logf="$out/$name.log"
    # shellcheck disable=SC2086
    if "$DEPS_CXX" $base_flags -o "$out/$name" "$CB/deps_smoke/$name.cpp" "$@" > "$logf" 2>&1 \
       && env -u RUNFILES_DIR -u RUNFILES_MANIFEST_FILE "$out/$name" >> "$logf" 2>&1; then
      printf 'PASS %s: %s\n' "$name" "$(tail -1 "$logf")" | tee -a "$results"
    else
      printf 'FAIL %s (see %s)\n' "$name" "$logf" | tee -a "$results"
      rc=1
    fi
  }
  # shellcheck disable=SC2086
  run_smoke absl_smoke -I"$ABSL_INCLUDE" "@$ABSL_LIBS" $DEPS_SYS_LIBS
  # shellcheck disable=SC2086
  run_smoke re2_smoke -I"$RE2_INCLUDE" -I"$ABSL_INCLUDE" "$RE2_LIB" "@$ABSL_LIBS" $DEPS_SYS_LIBS
  # shellcheck disable=SC2086
  run_smoke gtest_smoke $GTEST_DEFINES -I"$GTEST_INCLUDE" -I"$ABSL_INCLUDE" -I"$RE2_INCLUDE" \
    "@$TEST_LINK_LIBS" $DEPS_SYS_LIBS
  run_smoke boost_smoke -I"$BOOST_INCLUDE"
  # A fake runfiles tree next to each binary so Runfiles::Create(argv0) succeeds.
  for name in runfiles_smoke runfiles_lib_smoke; do
    mkdir -p "$out/$name.runfiles/carbon/toolchain/install"
    : > "$out/$name.runfiles/carbon/toolchain/install/carbon_install.txt"
  done
  run_smoke runfiles_smoke -I"$RUNFILES_INCLUDE" "$RUNFILES_SRC"
  run_smoke runfiles_lib_smoke -I"$RUNFILES_INCLUDE" "$RUNFILES_LIB"
  [ "$rc" -eq 0 ] || die "smoke: failures recorded in $results"
  log "smoke: all passed ($results)"
}

# ---- main ------------------------------------------------------------------------------
main() {
  mkdir -p "$DEPS" "$SRC" "$LOGS"
  log "DEPS=$DEPS JOBS=$JOBS DEPS_CC=$DEPS_CC DEPS_CXX=$DEPS_CXX${FETCH_ONLY:+ FETCH_ONLY}"
  local steps=("$@")
  if [ "${#steps[@]}" -eq 0 ]; then
    steps=(absl re2 googletest boost runfiles)
    if [ -z "${FETCH_ONLY:-}" ]; then steps+=(env validate smoke); fi
  fi
  local s
  for s in "${steps[@]}"; do
    case "$s" in
      absl) dep_absl ;;
      re2) dep_re2 ;;
      googletest|gtest) dep_googletest ;;
      boost) dep_boost ;;
      runfiles) dep_runfiles ;;
      env) write_env ;;
      validate) validate_env ;;
      smoke) smoke ;;
      *) die "unknown step '$s' (absl re2 googletest boost runfiles env validate smoke)" ;;
    esac
  done
  log "done: ${steps[*]}"
}

main "$@"

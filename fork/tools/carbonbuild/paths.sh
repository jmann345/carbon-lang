# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# paths.sh: the one shared configuration file. Every script in this directory
# sources it (python scripts parse it: one `NAME="${NAME:-default}"` line per
# variable, defaults may reference earlier variables as $NAME). Override a value
# by exporting it before running a script, e.g.
#   REPO=/home/user/carbon-ehc SHA=1234567 /home/user/arb/carbonbuild/build.sh
#
# Scripts never write into REPO, except autoupdate.sh whose documented job is
# to update goldens. Everything else lives under ARB.

ARB="${ARB:-/home/user/arb}"
# The Carbon checkout (a git worktree) to build; read-only for the scripts.
REPO="${REPO:-/home/user/carbon-trunk}"
# The commit being built; names the build and install directories.
SHA="${SHA:-cb726a230}"
# llvm-project at the pin the Carbon tree builds against (MODULE.bazel's
# git_override for llvm-raw). Two pins exist in the container (ARB-4), selected
# by LLVM_SRC, LLVM_BUILD and LLVM_OVERLAY together (README, "The LLVM build"):
#   old pin 6ec87e7ec4b3 (trunk's tree; the defaults)
#     LLVM_SRC=/home/user/llvm-project LLVM_BUILD=/home/user/llvm-build
#     LLVM_OVERLAY=/home/user/arb/deps/llvm-overlay/utils/bazel/llvm-project-overlay
#   tip pin c744694c6ae1 (upstream 7a3608bab's tree, the one UA-3 merges)
#     LLVM_SRC=/home/user/llvm-project-c744694 LLVM_BUILD=/home/user/llvm-build-c744694
#     LLVM_OVERLAY=/home/user/arb/deps/llvm-overlay-c744694/utils/bazel/llvm-project-overlay
LLVM_SRC="${LLVM_SRC:-/home/user/llvm-project}"
# CMake build of LLVM_SRC (Release; clang+lld; static libs under lib/).
LLVM_BUILD="${LLVM_BUILD:-/home/user/llvm-build}"
# Third-party dependencies (deps.sh builds them; deps.env describes them).
DEPS="${DEPS:-$ARB/deps}"
# Carbon build directory and install root for SHA.
BUILD_DIR="${BUILD_DIR:-$ARB/build/$SHA}"
INSTALL_DIR="${INSTALL_DIR:-$ARB/install/$SHA}"
# This scripts directory.
CB="${CB:-$ARB/carbonbuild}"

# --- Added by author A (gen_ninja.py / build.sh); same `NAME="${NAME:-default}"` form.
# Patched copy of LLVM's Bazel overlay: LLVM_SRC's utils/bazel/llvm-project-overlay
# with the overlay-touching patches of the Carbon tree's bazel/llvm_project applied
# (get_llvm_overlay.sh: 0002 0004 0005 0006 0012 at the old pin, 0012 0013 at the
# tip pin); gen_ninja.py and install.py evaluate compiler-rt/libcxx/libcxxabi/
# libunwind/libc/clang-tools-extra BUILD.bazel from it. Must be LLVM_SRC's pin.
LLVM_OVERLAY="${LLVM_OVERLAY:-$DEPS/llvm-overlay/utils/bazel/llvm-project-overlay}"
# C++ compiler for the Carbon sources. Carbon requires clang >= 21
# (docs/project/contribution_tools.md); the system clang 18 rejects the sources
# (NOTES-A.md D1). get_clang.sh installs the LLVM 21.1.8 release clang here.
# gen_ninja.py falls back to /usr/bin/clang++ if this path does not exist.
CXX="${CXX:-$DEPS/llvm21/bin/clang++}"
# Build mode: opt (-O3 -DNDEBUG -march=x86-64-v2, Carbon's `-c opt`) or fastbuild
# (-O0 -gmlt, no NDEBUG; Carbon's default). opt is the default for test speed.
CARBON_BUILD_MODE="${CARBON_BUILD_MODE:-opt}"
# Generated sources root (Bazel's bazel-out/<cfg>/bin equivalent) and object root.
GEN_DIR="${GEN_DIR:-$BUILD_DIR/gen}"
# Source patches (fold after review 1, R1-B1): unified diffs with git-style
# `a/<repo path>` / `b/<repo path>` names in SRC_PATCHES. gen_ninja.py applies
# them to COPIES of the touched REPO files under SRC_OVERLAY and compiles those
# copies instead; REPO itself is never written. A patch whose change is already
# in REPO is skipped (`landed`); one that does not apply stops the build loudly.
# $BUILD_DIR/src-patches.applied records the result and gate.sh prints it.
# SRC_PATCHES=none disables patching.
SRC_PATCHES="${SRC_PATCHES:-$CB/src-patches}"
SRC_OVERLAY="${SRC_OVERLAY:-$BUILD_DIR/src}"

# --- Added by author C (install.py / runfiles.py / gate.sh / autoupdate.sh /
# conformance.sh); same `NAME="${NAME:-default}"` form.
# The three binaries build.sh (author A) links under $BUILD_DIR/bin with these
# fixed names; install.py copies BUSYBOX_BIN into the install and runs
# DIGEST_BIN, gate.sh and autoupdate.sh run FILE_TEST_BIN.
FILE_TEST_BIN="${FILE_TEST_BIN:-$BUILD_DIR/bin/file_test}"
BUSYBOX_BIN="${BUSYBOX_BIN:-$BUILD_DIR/bin/carbon-busybox}"
DIGEST_BIN="${DIGEST_BIN:-$BUILD_DIR/bin/make-installation-digest}"
# Bazel-shaped runfiles tree for file_test (runfiles.py builds it): RUNFILES_DIR
# points here, `carbon` and `_main` are the workspace directory, and the test
# binary runs with cwd $RUNFILES_ROOT/_main.
RUNFILES_ROOT="${RUNFILES_ROOT:-$BUILD_DIR/runfiles}"
# Harness logs (gate-*.log, autoupdate-*.log, conformance-*.log).
LOGS="${LOGS:-$ARB/logs}"
# XDG_CACHE_HOME for the busybox's runtimes cache (toolchain/driver/runtimes_cache.cpp
# reads $XDG_CACHE_HOME, falling back to $HOME/.cache); the first `carbon link`
# builds the runtimes here and takes minutes.
CACHE_HOME="${CACHE_HOME:-$ARB/cache}"
# TEST_TMPDIR for file_test (`%t` in test ARGS, common/filesystem.cpp MakeTmpDir).
TEST_TMP="${TEST_TMP:-$BUILD_DIR/test_tmp}"
# Output directory of the conformance runner (scoreboard.json, logs/, obj/, bin/).
CONFORMANCE_OUT="${CONFORMANCE_OUT:-$ARB/conformance/$SHA}"

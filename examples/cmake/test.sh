#!/usr/bin/env bash
#
# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# Builds and runs this example project three ways — CMake with the Unix
# Makefiles generator, CMake with the Ninja generator (when `ninja` is on
# PATH), and the checked-in Makefile with GNU make — and requires the three
# builds' program outputs to be byte-identical. This is the arbiter script the
# conformance runner drives through its `// BUILD-SCRIPT:` directive
# (fork/conformance/README.md); it is also the quickest way to check a
# toolchain against the example by hand.
#
# Usage:
#   test.sh [--build-dir DIR] [--only TARGET]... [--no-ninja] [--no-make]
#
# The toolchain directory (the unpacked tarball, the parent of bin/carbon)
# comes from CARBON_TOOLCHAIN, else from CARBON (a path to bin/carbon; the
# directory is its parent's parent, as the Makefile derives it), else from
# `carbon` on PATH (resolved through its symlink). Every variant then gets
# that one directory: the CMake builds take it as -DCARBON_TOOLCHAIN and the
# Makefile as both CARBON_TOOLCHAIN= and CARBON=, so an exported CARBON
# pointing elsewhere cannot leak into any build. The build directory comes
# from --build-dir, else CARBON_BUILD_DIR, else a fresh temporary directory;
# it is left in place on exit, and each run reconfigures its CMake variants
# from scratch (`cmake --fresh`), so a reused directory never keeps an earlier
# run's toolchain. Nothing is written inside examples/cmake/.
#
# stdout carries exactly the Unix Makefiles build's concatenated program
# output (the programs run in the order hello, widget_main, mixed, or the
# --only targets in the order given); all configure and build chatter goes to
# stderr. Exit codes:
#   0   success
#   2   configure or compile failed
#   3   link failed
#   4   a program exited non-zero or did not run
#   5   the variants' outputs differ
#   64  usage error
#   66  toolchain not found

set -euo pipefail

SRC_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ALL_TARGETS=(hello widget_main mixed)

usage() {
  cat >&2 <<USAGE
usage: test.sh [--build-dir DIR] [--only TARGET]... [--no-ninja] [--no-make]
  TARGET is one of: ${ALL_TARGETS[*]}
USAGE
}

note() { echo "test.sh: $*" >&2; }

build_dir=""
targets=()
want_ninja=1
want_make=1
while [ $# -gt 0 ]; do
  case "$1" in
    --build-dir)
      [ $# -ge 2 ] || { usage; exit 64; }
      build_dir=$2
      shift 2
      ;;
    --build-dir=*)
      build_dir=${1#--build-dir=}
      shift
      ;;
    --only)
      [ $# -ge 2 ] || { usage; exit 64; }
      targets+=("$2")
      shift 2
      ;;
    --only=*)
      targets+=("${1#--only=}")
      shift
      ;;
    --no-ninja) want_ninja=0; shift ;;
    --no-make) want_make=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 64 ;;
  esac
done
if [ ${#targets[@]} -eq 0 ]; then
  targets=("${ALL_TARGETS[@]}")
fi
for t in "${targets[@]}"; do
  case " ${ALL_TARGETS[*]} " in
    *" $t "*) ;;
    *) note "unknown target '$t'"; usage; exit 64 ;;
  esac
done

# --- Toolchain directory ---
if [ -n "${CARBON_TOOLCHAIN:-}" ]; then
  toolchain=$CARBON_TOOLCHAIN
elif [ -n "${CARBON:-}" ]; then
  toolchain=$(cd "$(dirname "$CARBON")/.." 2>/dev/null && pwd) || toolchain=""
elif command -v carbon >/dev/null 2>&1; then
  # bin/carbon -> lib/carbon/carbon-busybox: three steps up from the real
  # path reach the toolchain directory.
  busybox=$(readlink -f "$(command -v carbon)")
  toolchain=$(dirname "$(dirname "$(dirname "$busybox")")")
else
  note "no toolchain: set CARBON_TOOLCHAIN=<toolchain directory>," \
    "CARBON=<path to bin/carbon>, or put bin/carbon on PATH"
  exit 66
fi
if [ ! -x "$toolchain/bin/carbon" ] \
  || [ ! -x "$toolchain/lib/carbon/llvm/bin/clang++" ]; then
  note "toolchain directory '$toolchain' has no bin/carbon or" \
    "lib/carbon/llvm/bin/clang++"
  exit 66
fi
toolchain=$(cd "$toolchain" && pwd)

# --- Build directory ---
if [ -z "$build_dir" ]; then
  build_dir=${CARBON_BUILD_DIR:-}
fi
if [ -z "$build_dir" ]; then
  build_dir=$(mktemp -d)
fi
mkdir -p "$build_dir"
build_dir=$(cd "$build_dir" && pwd)
note "toolchain $toolchain"
note "build directory $build_dir"

# Fails with the compile/link exit code a CMake build log implies: the
# `--build` step cannot tell the stages apart, so the log is searched for the
# linker's own signatures.
fail_from_log() {
  local log=$1
  cat "$log" >&2
  if grep -q -e 'ld.lld: error' -e 'linker command failed' "$log"; then
    note "link failed (see above)"
    exit 3
  fi
  note "configure or compile failed (see above)"
  exit 2
}

# cmake_variant NAME GENERATOR: configures and builds $build_dir/NAME.
cmake_variant() {
  local name=$1 generator=$2
  local dir=$build_dir/$name log=$build_dir/$name.log
  note "[$name] cmake --fresh -S $SRC_DIR -B $dir -G \"$generator\""
  : >"$log"
  if ! cmake --fresh -S "$SRC_DIR" -B "$dir" -G "$generator" \
    "-DCARBON_TOOLCHAIN=$toolchain" >>"$log" 2>&1; then
    cat "$log" >&2
    note "[$name] configure failed"
    exit 2
  fi
  note "[$name] cmake --build $dir --target ${targets[*]}"
  if ! cmake --build "$dir" --target "${targets[@]}" >>"$log" 2>&1; then
    fail_from_log "$log"
  fi
}

# run_programs NAME BINDIR OUTFILE: runs the selected programs from BINDIR
# in order, appending their stdout to OUTFILE; any non-zero exit is fatal.
run_programs() {
  local name=$1 bindir=$2 out=$3 t rc
  : >"$out"
  for t in "${targets[@]}"; do
    if [ ! -x "$bindir/$t" ]; then
      note "[$name] $bindir/$t was not built"
      exit 4
    fi
    rc=0
    "$bindir/$t" >>"$out" 2>>"$build_dir/$name.run.log" || rc=$?
    if [ "$rc" -ne 0 ]; then
      note "[$name] $t exited with $rc"
      exit 4
    fi
  done
}

# --- Variant 1: CMake, Unix Makefiles (always) ---
cmake_variant make-gen "Unix Makefiles"
run_programs make-gen "$build_dir/make-gen" "$build_dir/make-gen.out"
variants=(make-gen)

# --- Variant 2: CMake, Ninja (when available) ---
if [ "$want_ninja" -eq 1 ]; then
  if command -v ninja >/dev/null 2>&1; then
    cmake_variant ninja Ninja
    run_programs ninja "$build_dir/ninja" "$build_dir/ninja.out"
    variants+=(ninja)
  else
    note "ninja not on PATH; skipping the Ninja generator"
  fi
fi

# --- Variant 3: the checked-in Makefile with GNU make ---
if [ "$want_make" -eq 1 ]; then
  log=$build_dir/make.log
  : >"$log"
  # CARBON= is pinned too: the Makefile derives it from CARBON_TOOLCHAIN, but
  # a command-line value is the one setting nothing in the environment beats.
  make_vars=("CARBON_TOOLCHAIN=$toolchain" "CARBON=$toolchain/bin/carbon"
    "O=$build_dir/make")
  note "[make] make -C $SRC_DIR ${make_vars[*]}"
  if ! make -C "$SRC_DIR" "${make_vars[@]}" objects >>"$log" 2>&1; then
    cat "$log" >&2
    note "[make] compile failed"
    exit 2
  fi
  if ! make -C "$SRC_DIR" "${make_vars[@]}" link >>"$log" 2>&1; then
    cat "$log" >&2
    note "[make] link failed"
    exit 3
  fi
  run_programs make "$build_dir/make" "$build_dir/make.out"
  variants+=(make)
fi

# --- The variants must agree byte for byte ---
for v in "${variants[@]}"; do
  if ! cmp -s "$build_dir/make-gen.out" "$build_dir/$v.out"; then
    note "outputs differ between make-gen and $v:"
    diff "$build_dir/make-gen.out" "$build_dir/$v.out" >&2 || true
    exit 5
  fi
done
note "variants agree: ${variants[*]}"

cat "$build_dir/make-gen.out"

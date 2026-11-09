#!/bin/bash
#
# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# get_clang.sh: install the compiler that builds Carbon's C++ sources.
#
# Carbon requires clang >= 21 (docs/project/contribution_tools.md). The system
# clang 18.1.3 cannot compile the sources (see NOTES-A.md, decision D1), and the
# LLVM build under $LLVM_BUILD was configured with CLANG_BUILD_TOOLS=OFF, so it
# produces no clang binary. This script fetches the LLVM 21.1.8 release tarball
# from GitHub and extracts only the clang driver, lld, llvm-ar, llvm-symbolizer
# and clang's resource directory into $DEPS/llvm21 (about 500 MB). Re-runnable:
# each step is skipped when its result exists.
#
# Steps are separate commands (download, then extract, then verify).
set -euo pipefail
. "$(dirname "$(readlink -f "$0")")/paths.sh"

VERSION="${LLVM_RELEASE:-21.1.8}"
NAME="LLVM-$VERSION-Linux-X64"
URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-$VERSION/$NAME.tar.xz"
DL_DIR="$DEPS/llvm21-dl"
DEST="$DEPS/llvm21"
TARBALL="$DL_DIR/$NAME.tar.xz"
MAJOR="${VERSION%%.*}"

mkdir -p "$DL_DIR" "$DEST" "$ARB/logs"

if [ -x "$DEST/bin/clang++" ] && [ -d "$DEST/lib/clang/$MAJOR/include" ]; then
  echo "get_clang.sh: $DEST already present: $("$DEST/bin/clang++" --version | head -1)"
  exit 0
fi

if [ ! -s "$TARBALL" ]; then
  echo "get_clang.sh: downloading $URL (about 2 GB)"
  curl -sSL --retry 3 --retry-delay 10 -o "$TARBALL.part" "$URL"
  mv "$TARBALL.part" "$TARBALL"
fi

echo "get_clang.sh: extracting the compiler subset into $DEST"
tar -xJf "$TARBALL" -C "$DEST" --strip-components=1 \
  "$NAME/bin/clang-$MAJOR" "$NAME/bin/clang" "$NAME/bin/clang++" \
  "$NAME/bin/ld.lld" "$NAME/bin/lld" "$NAME/bin/llvm-symbolizer" "$NAME/bin/llvm-ar" \
  "$NAME/lib/clang/$MAJOR/include" "$NAME/lib/clang/$MAJOR/lib"

"$DEST/bin/clang++" --version | head -1
echo "get_clang.sh: done. The tarball at $TARBALL may be deleted to reclaim 2 GB."

#!/usr/bin/env bash
#
# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# Builds and runs the "Linking your own C++ library" sample of
# docs/guides/tutorial.md with that section's commands, for the conformance
# runner's BUILD-SCRIPT channel (fork/conformance/README.md). It runs from
# this directory, because `import Cpp library "rectangle.h"` resolves the
# quoted header against the working directory, and writes only into
# CARBON_BUILD_DIR. stdout is the program's output; build messages go to
# stderr. Exit codes: 2 compile failed, 3 link failed, otherwise the
# program's own.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
carbon="${CARBON:-carbon}"
out="${CARBON_BUILD_DIR:?CARBON_BUILD_DIR is not set}"
mkdir -p "$out"

"$carbon" clang -- -c rectangle.cpp -o "$out/rectangle.o" >&2 || exit 2
"$carbon" compile --output="$out/main.o" main.carbon >&2 || exit 2
"$carbon" link --output="$out/main" "$out/main.o" "$out/rectangle.o" >&2 ||
  exit 3
exec "$out/main"

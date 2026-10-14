// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/aliases.md, "Aliases in the 0.1 toolchain", block
// EXPECT-ERROR: `alias` declaration cannot have parameters

alias Ptr(T: type) = T*;

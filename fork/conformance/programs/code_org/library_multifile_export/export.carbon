// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// The name-export middle library: imports "geo" and re-exports the class
// by name — the `export C;` spelling of
// toolchain/check/testdata/packages/export_name.carbon (its export.carbon
// subfile, whose library is also literally named "export"). Only the
// CLASS is exported: `export x;` of a runtime `let` is the known W-074
// crash shape (import_ref.cpp:4483, minted at the W69a round) and is
// deliberately not exercised here.

library "export";

import library "geo";

export Rect;

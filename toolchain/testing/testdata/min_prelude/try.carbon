// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// EXTRA-ARGS: --custom-core --exclude-dump-file-prefix=min_prelude/
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/parts/int.carbon
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/parts/try.carbon
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/parts/uint.carbon

// --- min_prelude/try.carbon

// A minimal prelude for testing the postfix `?` operator's pre-flight
// diagnostics: `Core.Try` and `Core.ControlFlow` exist, and `i32` is
// available for operand and return types. The load-bearing arbitration is
// that NO `Try` impl exists in this prelude at all, so every pre-flight
// rejection demonstrably fires before the desugar's first impl lookup (the
// Branch call) could succeed. As a secondary backstop, `EqWith` is also
// omitted, so a desugar that somehow got past the pre-flight would still
// fail at its discriminant test. Positive `?` tests use the full prelude,
// the way the `match` choice tests do.
package Core library "prelude";

export import library "prelude/parts/int";
export import library "prelude/parts/try";
export import library "prelude/parts/uint";

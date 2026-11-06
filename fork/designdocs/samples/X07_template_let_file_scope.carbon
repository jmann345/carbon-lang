// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: semantics TODO: ``let` compile time binding outside function or interface`
// QUOTE: semantics TODO: ``let` compile time binding outside function or interface`
// Pins the page's limit on template `let` bindings at file scope: proposal
// 2200's own example in its "Syntax" section, with `:!` written `:` and the
// array type `[u8; N]` written `array(u8, N)`, is rejected at the binding (fork
// work item W-031), and the array bound then is not a constant. The
// function-body form is R14, on metaprogramming.md.

let template N: i64 = 4;
var my_array: array(u8, N) = (255, 128, 64, 255);

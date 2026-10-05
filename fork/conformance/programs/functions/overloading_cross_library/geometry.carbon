// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// The API unit of the OV-2 cross-library arbiter (fork/overload/plan.md
// §5.B.2): declares a closed `overload fn` set whose members are DEFINED in
// geometry.impl.carbon and CALLED from main.carbon. No directives here — they
// live in main.carbon per the multi-unit convention
// (fork/conformance/README.md).

library "geometry";

overload fn Dist(a: i32, b: i32) -> i32;
overload fn Dist(a: i64, b: i64) -> i32;

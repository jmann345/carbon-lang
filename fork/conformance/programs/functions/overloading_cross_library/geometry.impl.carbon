// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// The implementation unit of the OV-2 cross-library arbiter: each definition
// merges into its API-declared member through the implicit API import
// (fork/overload/plan.md §1.B.2). An implementation file may only define
// members, never add one (`OverloadSetFrozen`). The `i64` member returns
// twice the absolute difference so that the selected member is observable.

impl library "geometry";

overload fn Dist(a: i32, b: i32) -> i32 {
  if (a < b) { return b - a; }
  return a - b;
}

overload fn Dist(a: i64, b: i64) -> i32 {
  if (a < b) { return ((b - a) * 2) as i32; }
  return ((a - b) * 2) as i32;
}

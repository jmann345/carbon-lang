// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

impl package Geometry;

// The implementation file: it sees the API file's declarations implicitly.

fn Area(r: Rect) -> i32 {
  return r.width * r.height;
}

fn Perimeter(r: Rect) -> i32 {
  return 2 * (r.width + r.height);
}

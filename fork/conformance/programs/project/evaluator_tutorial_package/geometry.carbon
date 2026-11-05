// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

package Geometry;

// The API file: the declarations that importers of `Geometry` can use.

class Rect {
  var width: i32;
  var height: i32;
}

fn Area(r: Rect) -> i32;
fn Perimeter(r: Rect) -> i32;

// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// The api unit of the named library under test: defines a class and
// DECLARES two functions whose bodies live only in the paired impl unit
// (geo.impl.carbon), so every value main.carbon prints is computed by a
// cross-unit definition. No directives here — they live in main.carbon
// per the multi-unit convention (fork/conformance/README.md).

library "geo";

class Rect {
  var w: i32;
  var h: i32;
}

// Declared here, defined in geo.impl.carbon — the api/impl runtime shape
// manually verified in the widget pair recorded in
// impl_files_impl_defined_fn.carbon's header (2026-07-19), and the same
// split core/io.carbon + core/io.impl.carbon use.
fn RuntimeSeed(x: i32) -> i32;
fn Area(r: Rect) -> i32;

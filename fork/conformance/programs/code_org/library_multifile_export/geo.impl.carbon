// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// The impl unit of library "geo": defines the functions the api unit only
// declares. The impl file implicitly imports its own api (Rect is visible
// with no import declaration); the pairing's fail sides are pinned by
// toolchain/check/testdata/packages/fail_api_not_found.carbon and
// fail_duplicate_api.carbon. The bodies existing ONLY in this unit is
// what makes the printed values arbitrate the split at runtime.

impl library "geo";

// The R16d seed convention: RuntimeSeed(x) = x + 20.
fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Area(r: Rect) -> i32 { return r.w * r.h; }

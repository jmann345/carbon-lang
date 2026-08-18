// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// The defining library unit of the W-069 split-file runtime arbiter: binds
// file-scope `let`s to RUNTIME values (scalar AND choice-typed) that
// main.carbon imports and consumes. No directives here — they live in
// main.carbon per the multi-unit convention (fork/conformance/README.md).

library "seeds";

choice IntOption {
  Some(value: i32),
  Nothing
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

// Scalar runtime binding: exported through the promoted store/load global
// (the W69a arm). RuntimeSeed(3) = 23.
let scalar_from_lib: i32 = RuntimeSeed(3);

// Choice-typed runtime binding: exported through the promoted
// object-representation global + ctor memcpy (the W69b pointer-value-rep
// arm). Payload RuntimeSeed(4) = 24.
let opt_from_lib: IntOption = IntOption.Some(RuntimeSeed(4));

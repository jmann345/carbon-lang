// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// ARGS: compile --optimize=size foo.carbon --target=x86_64-unknown-linux-gnu --phase=lower --dump-llvm-ir --exclude-dump-file-prefix=%{core}
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/driver/testdata/compile/optimize/optimize_size.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/driver/testdata/compile/optimize/optimize_size.carbon
// CHECK:STDERR: {{.*}}/prelude/types/optional.carbon:71:42: error: cannot access member of interface `Destroy` in type `T` that does not implement that interface
// CHECK:STDERR:       return ControlFlow(T, ()).Continue(self.Get());
// CHECK:STDERR:                                          ^~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/optional.carbon:71:42: error: cannot access member of interface `Destroy` in type `T` that does not implement that interface
// CHECK:STDERR:       return ControlFlow(T, ()).Continue(self.Get());
// CHECK:STDERR:                                          ^~~~~~~~~~
// CHECK:STDERR:

// --- foo.carbon
fn Rand() -> i32;

fn NoInlineWithOz() -> i32 {
  return Rand() + Rand();
}

fn CallNoInlineWithOptSize() -> i32 {
  // Should not be inlined with --optimize=size, because the body is larger than the call.
  return NoInlineWithOz();
}

fn VectorizedWithOptSpeed(a: array(i32, 65536)*) {
  // Should be vectorized with --optimize=speed, but not in other modes.
  var n: i32 = 0;
  while (n < 65536) {
    (*a)[n] *= 2;
    ++n;
  }
}


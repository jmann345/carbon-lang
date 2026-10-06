// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/builtins/failstop.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/builtins/failstop.carbon

// Fork (SL-1, fork/slices/plan.md §4.A, risk R-1): `fail_stop` lowers to a
// load of the `str` value, `call i64 @write(i32 2, ptr, i64)`, then
// `call void @abort()` with `abort` declared `noreturn`; no terminator follows
// the call, so the ordinary `ret void` of `F` ends the block. A positive lower
// golden, so the file is named without the `fail_` prefix.

fn Stop(message: str) = "fail_stop";

fn F() {
  Stop("boom\n");
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'failstop.carbon'
// CHECK:STDOUT: source_filename = "failstop.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [6 x i8] c"boom\0A\00", align 1
// CHECK:STDOUT: @String.val.String.val = internal constant { ptr, i64 } { ptr @0, i64 5 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CF.Main() #0 !dbg !10 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Stop.call.fail_stop.load = load { ptr, i64 }, ptr @String.val.String.val, align 8, !dbg !11
// CHECK:STDOUT:   %Stop.call.fail_stop.ptr = extractvalue { ptr, i64 } %Stop.call.fail_stop.load, 0, !dbg !11
// CHECK:STDOUT:   %Stop.call.fail_stop.size = extractvalue { ptr, i64 } %Stop.call.fail_stop.load, 1, !dbg !11
// CHECK:STDOUT:   %Stop.call = call i64 @write(i32 2, ptr %Stop.call.fail_stop.ptr, i64 %Stop.call.fail_stop.size), !dbg !11
// CHECK:STDOUT:   call void @abort(), !dbg !11
// CHECK:STDOUT:   ret void, !dbg !12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noreturn
// CHECK:STDOUT: declare void @abort() #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { noreturn }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "failstop.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !8 = !{null}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !4, line: 21, type: !9, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !11 = !DILocation(line: 22, column: 3, scope: !10)
// CHECK:STDOUT: !12 = !DILocation(line: 21, column: 1, scope: !10)
// CHECK:STDOUT:

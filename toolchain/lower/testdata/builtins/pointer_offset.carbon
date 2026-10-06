// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/builtins/pointer_offset.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/builtins/pointer_offset.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): `pointer.offset` lowers to
// `getelementptr inbounds <elem>, ptr %p, i64 %n`.

fn Offset[T: type](p: T*, n: i64) -> T* = "pointer.offset";

fn F(p: i32*, n: i64) -> i32* {
  return Offset(p, n);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'pointer_offset.carbon'
// CHECK:STDOUT: source_filename = "pointer_offset.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define ptr @_CF.Main(ptr %p, i64 %n) #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Offset.call.ptr.offset = getelementptr inbounds i32, ptr %p, i64 %n, !dbg !34
// CHECK:STDOUT:   ret ptr %Offset.call.ptr.offset, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!19}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !18 = !DIFile(filename: "pointer_offset.carbon", directory: "")
// CHECK:STDOUT: !19 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !18, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !22 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !23 = !{!22, !22, !20}
// CHECK:STDOUT: !24 = !DISubroutineType(types: !23)
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !18, line: 18, type: !24, spFlags: DISPFlagDefinition, unit: !19, retainedNodes: !36)
// CHECK:STDOUT: !26 = !DILocalVariable(arg: 1, scope: !25, type: !22)
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 2, scope: !25, type: !20)
// CHECK:STDOUT: !34 = !DILocation(line: 19, column: 10, scope: !25)
// CHECK:STDOUT: !35 = !DILocation(line: 19, column: 3, scope: !25)
// CHECK:STDOUT: !36 = !{!26, !27}
// CHECK:STDOUT:

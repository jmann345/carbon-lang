// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/bool_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/bool_scrutinee.carbon

// The W-076 exhaustive bool dispatch shape (design's `IsTrue` example,
// docs/design/pattern_matching.md): each arm's condition lowers through
// the pre-existing builtin `bool.eq` lane (an `icmp eq i1`, which trivial
// optimization folds to the scrutinee itself), and the arm bodies
// converge on the resumption block — dynamically dead after the last
// arm's else edge when the arms are exhaustive.

fn IsTrue(b: bool) -> i32 {
  match (b) {
    case false => { return 0; }
    case true => { return 1; }
  }
  return -1;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'bool_scrutinee.carbon'
// CHECK:STDOUT: source_filename = "bool_scrutinee.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CIsTrue.Main(i1 %b) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc22 = icmp eq i1 false, %b, !dbg !11
// CHECK:STDOUT:   br i1 %bool.as.EqWith.impl.Equal.call.loc22, label %match.case.then.loc22, label %match.case.else.loc22, !dbg !11
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc22:                            ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !12
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc22:                            ; preds = %entry
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc23 = icmp eq i1 true, %b, !dbg !13
// CHECK:STDOUT:   br i1 %bool.as.EqWith.impl.Equal.call.loc23, label %match.case.then.loc23, label %match.done, !dbg !13
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc23:                            ; preds = %match.case.else.loc22
// CHECK:STDOUT:   ret i32 1, !dbg !14
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc22
// CHECK:STDOUT:   ret i32 -1, !dbg !15
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "bool_scrutinee.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "IsTrue", linkageName: "_CIsTrue.Main", scope: null, file: !1, line: 20, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 22, column: 5, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 22, column: 21, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 23, column: 5, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 23, column: 20, scope: !4)
// CHECK:STDOUT: !15 = !DILocation(line: 25, column: 3, scope: !4)
// CHECK:STDOUT:

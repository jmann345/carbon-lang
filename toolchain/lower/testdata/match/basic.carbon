// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// TODO: Extend the "int" min_prelude to support basic integer operations, so we
// can use it here.
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/basic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/basic.carbon

fn A() {}
fn B() {}
fn C() {}
fn D() {}

fn F(n: i32) {
  match (n) {
    case 1 => { A(); }
    case 2 => { B(); }
    default => { C(); }
  }
  D();
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'basic.carbon'
// CHECK:STDOUT: source_filename = "basic.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CA.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !7
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CB.Main() #0 !dbg !8 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CC.Main() #0 !dbg !10 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CD.Main() #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !13
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CF.Main(i32 %n) #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc22 = icmp eq i32 1, %n, !dbg !20
// CHECK:STDOUT:   br i1 %T.as_type.as.EqWith.impl.Equal.call.loc22, label %match.case.then.loc22, label %match.case.else.loc22, !dbg !20
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc22:                            ; preds = %entry
// CHECK:STDOUT:   call void @_CA.Main(), !dbg !21
// CHECK:STDOUT:   br label %match.done, !dbg !22
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc22:                            ; preds = %entry
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc23 = icmp eq i32 2, %n, !dbg !23
// CHECK:STDOUT:   br i1 %T.as_type.as.EqWith.impl.Equal.call.loc23, label %match.case.then.loc23, label %match.case.else.loc23, !dbg !23
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc23:                            ; preds = %match.case.else.loc22
// CHECK:STDOUT:   call void @_CB.Main(), !dbg !24
// CHECK:STDOUT:   br label %match.done, !dbg !22
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc23:                            ; preds = %match.case.else.loc22
// CHECK:STDOUT:   call void @_CC.Main(), !dbg !25
// CHECK:STDOUT:   br label %match.done, !dbg !22
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc23, %match.case.then.loc23, %match.case.then.loc22
// CHECK:STDOUT:   call void @_CD.Main(), !dbg !26
// CHECK:STDOUT:   ret void, !dbg !27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "basic.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "A", linkageName: "_CA.Main", scope: null, file: !1, line: 15, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{null}
// CHECK:STDOUT: !7 = !DILocation(line: 15, column: 1, scope: !4)
// CHECK:STDOUT: !8 = distinct !DISubprogram(name: "B", linkageName: "_CB.Main", scope: null, file: !1, line: 16, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !9 = !DILocation(line: 16, column: 1, scope: !8)
// CHECK:STDOUT: !10 = distinct !DISubprogram(name: "C", linkageName: "_CC.Main", scope: null, file: !1, line: 17, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !11 = !DILocation(line: 17, column: 1, scope: !10)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "D", linkageName: "_CD.Main", scope: null, file: !1, line: 18, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !13 = !DILocation(line: 18, column: 1, scope: !12)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !1, line: 20, type: !15, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !18)
// CHECK:STDOUT: !15 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !16 = !{null, !17}
// CHECK:STDOUT: !17 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !18 = !{!19}
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 1, scope: !14, type: !17)
// CHECK:STDOUT: !20 = !DILocation(line: 22, column: 5, scope: !14)
// CHECK:STDOUT: !21 = !DILocation(line: 22, column: 17, scope: !14)
// CHECK:STDOUT: !22 = !DILocation(line: 21, column: 3, scope: !14)
// CHECK:STDOUT: !23 = !DILocation(line: 23, column: 5, scope: !14)
// CHECK:STDOUT: !24 = !DILocation(line: 23, column: 17, scope: !14)
// CHECK:STDOUT: !25 = !DILocation(line: 24, column: 18, scope: !14)
// CHECK:STDOUT: !26 = !DILocation(line: 26, column: 3, scope: !14)
// CHECK:STDOUT: !27 = !DILocation(line: 20, column: 1, scope: !14)
// CHECK:STDOUT:

// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/tuple_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/tuple_pattern.carbon

// Tuple case patterns must lower to elementwise compares folded into one
// arm condition (the `and`-shape block_arg chain), with the arm's bindings
// re-extracted in the arm's body block. Both the design's nested mixed
// shape on a by-value parameter and a mixed pattern on a `var` (non-literal)
// scrutinee are covered.

fn Nested(p: (i32, (i32, i32))) -> i32 {
  match (p) {
    case (42, (x: i32, y: i32)) => { return x + y; }
    case (n: i32, (1, 2)) => { return n; }
    default => { return -1; }
  }
  return -2;
}

fn VarScrutinee() -> i32 {
  var t: (i32, i32) = (1, 2);
  match (t) {
    case (1, b: i32) => { return b; }
    default => { return -1; }
  }
  return -2;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'tuple_pattern.carbon'
// CHECK:STDOUT: source_filename = "tuple_pattern.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @tuple.102.loc29_3 = internal constant { i32, i32 } { i32 1, i32 2 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CNested.Main(ptr %p) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.loc20_10.1.tuple.elem = getelementptr inbounds nuw { i32, ptr }, ptr %p, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %tuple.elem0.loc20_10.1.tuple.elem.load = load i32, ptr %tuple.elem0.loc20_10.1.tuple.elem, align 4, !dbg !11
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc21 = icmp eq i32 42, %tuple.elem0.loc20_10.1.tuple.elem.load, !dbg !12
// CHECK:STDOUT:   br i1 %T.as_type.as.EqWith.impl.Equal.call.loc21, label %match.case.then.loc21, label %match.case.else.loc21, !dbg !12
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc21:                            ; preds = %entry
// CHECK:STDOUT:   %tuple.elem1.loc20_10.1.tuple.elem = getelementptr inbounds nuw { i32, ptr }, ptr %p, i32 0, i32 1, !dbg !11
// CHECK:STDOUT:   %tuple.elem1.loc20_10.1.tuple.elem.load = load ptr, ptr %tuple.elem1.loc20_10.1.tuple.elem, align 8, !dbg !11
// CHECK:STDOUT:   %tuple.elem0.loc20_10.2.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.elem1.loc20_10.1.tuple.elem.load, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %tuple.elem0.loc20_10.2.tuple.elem.load = load i32, ptr %tuple.elem0.loc20_10.2.tuple.elem, align 4, !dbg !11
// CHECK:STDOUT:   %tuple.elem1.loc20_10.2.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.elem1.loc20_10.1.tuple.elem.load, i32 0, i32 1, !dbg !11
// CHECK:STDOUT:   %tuple.elem1.loc20_10.2.tuple.elem.load = load i32, ptr %tuple.elem1.loc20_10.2.tuple.elem, align 4, !dbg !11
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %tuple.elem0.loc20_10.2.tuple.elem.load, %tuple.elem1.loc20_10.2.tuple.elem.load, !dbg !13
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !14
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc21:                            ; preds = %entry
// CHECK:STDOUT:   %tuple.elem1.loc20_10.3.tuple.elem = getelementptr inbounds nuw { i32, ptr }, ptr %p, i32 0, i32 1, !dbg !11
// CHECK:STDOUT:   %tuple.elem1.loc20_10.3.tuple.elem.load = load ptr, ptr %tuple.elem1.loc20_10.3.tuple.elem, align 8, !dbg !11
// CHECK:STDOUT:   %tuple.elem0.loc20_10.3.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.elem1.loc20_10.3.tuple.elem.load, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %tuple.elem0.loc20_10.3.tuple.elem.load = load i32, ptr %tuple.elem0.loc20_10.3.tuple.elem, align 4, !dbg !11
// CHECK:STDOUT:   %tuple.elem1.loc20_10.4.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.elem1.loc20_10.3.tuple.elem.load, i32 0, i32 1, !dbg !11
// CHECK:STDOUT:   %tuple.elem1.loc20_10.4.tuple.elem.load = load i32, ptr %tuple.elem1.loc20_10.4.tuple.elem, align 4, !dbg !11
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc22_27.1 = icmp eq i32 1, %tuple.elem0.loc20_10.3.tuple.elem.load, !dbg !15
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc22_27.2 = icmp eq i32 2, %tuple.elem1.loc20_10.4.tuple.elem.load, !dbg !15
// CHECK:STDOUT:   br i1 %T.as_type.as.EqWith.impl.Equal.call.loc22_27.1, label %match.case.then.loc22_27.1, label %"match.<unexpected BranchWithArg>", !dbg !15
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc22_27.1:                       ; preds = %match.case.else.loc21
// CHECK:STDOUT:   br label %"match.<unexpected BranchWithArg>", !dbg !15
// CHECK:STDOUT:
// CHECK:STDOUT: "match.<unexpected BranchWithArg>":               ; preds = %match.case.then.loc22_27.1, %match.case.else.loc21
// CHECK:STDOUT:   %0 = phi i1 [ false, %match.case.else.loc21 ], [ %T.as_type.as.EqWith.impl.Equal.call.loc22_27.2, %match.case.then.loc22_27.1 ]
// CHECK:STDOUT:   br i1 %0, label %match.case.then.loc22_27.2, label %match.case.else.loc22, !dbg !15
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc22_27.2:                       ; preds = %"match.<unexpected BranchWithArg>"
// CHECK:STDOUT:   %tuple.elem0.loc20_10.4.tuple.elem = getelementptr inbounds nuw { i32, ptr }, ptr %p, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %tuple.elem0.loc20_10.4.tuple.elem.load = load i32, ptr %tuple.elem0.loc20_10.4.tuple.elem, align 4, !dbg !11
// CHECK:STDOUT:   ret i32 %tuple.elem0.loc20_10.4.tuple.elem.load, !dbg !16
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc22:                            ; preds = %"match.<unexpected BranchWithArg>"
// CHECK:STDOUT:   ret i32 -1, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CVarScrutinee.Main() #0 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %t.var = alloca { i32, i32 }, align 4, !dbg !21
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %t.var), !dbg !21
// CHECK:STDOUT:   %tuple.elem0.loc29.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %t.var, i32 0, i32 0, !dbg !22
// CHECK:STDOUT:   %tuple.elem1.loc29.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %t.var, i32 0, i32 1, !dbg !22
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %t.var, ptr align 4 @tuple.102.loc29_3, i64 8, i1 false), !dbg !21
// CHECK:STDOUT:   %tuple.elem0.loc30.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %t.var, i32 0, i32 0, !dbg !23
// CHECK:STDOUT:   %.loc30_10.1 = load i32, ptr %tuple.elem0.loc30.tuple.elem, align 4, !dbg !23
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call = icmp eq i32 1, %.loc30_10.1, !dbg !24
// CHECK:STDOUT:   br i1 %T.as_type.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !24
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   %tuple.elem1.loc30.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %t.var, i32 0, i32 1, !dbg !23
// CHECK:STDOUT:   %.loc30_10.2 = load i32, ptr %tuple.elem1.loc30.tuple.elem, align 4, !dbg !23
// CHECK:STDOUT:   call void @"_COp.7ebc50e8bd9eb2f1:core.Destroy.Core"(ptr %t.var), !dbg !21
// CHECK:STDOUT:   ret i32 %.loc30_10.2, !dbg !25
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   call void @"_COp.7ebc50e8bd9eb2f1:core.Destroy.Core"(ptr %t.var), !dbg !21
// CHECK:STDOUT:   ret i32 -1, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.7ebc50e8bd9eb2f1:core.Destroy.Core"(ptr %self) #0 !dbg !33 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_COp.7ebc50e8bd9eb2f1:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "tuple_pattern.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Nested", linkageName: "_CNested.Main", scope: null, file: !1, line: 19, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 20, column: 10, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 21, column: 5, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 21, column: 45, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 21, column: 38, scope: !4)
// CHECK:STDOUT: !15 = !DILocation(line: 22, column: 5, scope: !4)
// CHECK:STDOUT: !16 = !DILocation(line: 22, column: 32, scope: !4)
// CHECK:STDOUT: !17 = !DILocation(line: 23, column: 18, scope: !4)
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "VarScrutinee", linkageName: "_CVarScrutinee.Main", scope: null, file: !1, line: 28, type: !19, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !19 = !DISubroutineType(types: !20)
// CHECK:STDOUT: !20 = !{!7}
// CHECK:STDOUT: !21 = !DILocation(line: 29, column: 3, scope: !18)
// CHECK:STDOUT: !22 = !DILocation(line: 29, column: 23, scope: !18)
// CHECK:STDOUT: !23 = !DILocation(line: 30, column: 10, scope: !18)
// CHECK:STDOUT: !24 = !DILocation(line: 31, column: 5, scope: !18)
// CHECK:STDOUT: !25 = !DILocation(line: 31, column: 27, scope: !18)
// CHECK:STDOUT: !26 = !DILocation(line: 32, column: 18, scope: !18)
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 29, type: !28, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !30)
// CHECK:STDOUT: !28 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !29 = !{null, !7}
// CHECK:STDOUT: !30 = !{!31}
// CHECK:STDOUT: !31 = !DILocalVariable(arg: 1, scope: !27, type: !7)
// CHECK:STDOUT: !32 = !DILocation(line: 29, column: 3, scope: !27)
// CHECK:STDOUT: !33 = distinct !DISubprogram(name: "Op", linkageName: "_COp.7ebc50e8bd9eb2f1:core.Destroy.Core", scope: null, file: !1, line: 29, type: !34, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !36)
// CHECK:STDOUT: !34 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !35 = !{null, !8}
// CHECK:STDOUT: !36 = !{!37}
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !33, type: !8)
// CHECK:STDOUT: !38 = !DILocation(line: 29, column: 3, scope: !33)
// CHECK:STDOUT:

// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/var_binding.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/var_binding.carbon

// `var` case bindings must lower to one alloca per arm, initialized by
// copy from the scrutinee in the arm's body block — storage is NOT aliased
// across arms (docs/design/pattern_matching.md, "Pattern match control
// flow") — and writes through the binding must hit the arm's own storage,
// never the scrutinee. `ref` bindings are the opposite pin: no alloca, no
// copy, writes hit the scrutinee's storage.

fn TwoVarArms(x: i32) -> i32 {
  match (x) {
    case var a: i32 if (a > 9) => { a = a + 1; return a; }
    case var b: i32 => { b = b + 2; return b; }
  }
  return -2;
}

fn VarTuple(p: (i32, i32)) -> i32 {
  match (p) {
    case var (a: i32, b: i32) => { a = a + b; return a; }
  }
  return -2;
}

fn RefAlias() -> i32 {
  var x: i32 = 5;
  match (x) {
    case ref a: i32 => { a = 7; }
  }
  return x;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'var_binding.carbon'
// CHECK:STDOUT: source_filename = "var_binding.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CTwoVarArms.Main(i32 %x) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.var = alloca i32, align 4, !dbg !10
// CHECK:STDOUT:   %b.var = alloca i32, align 4, !dbg !11
// CHECK:STDOUT:   br i1 true, label %.loc22_21.1, label %.loc22_21.2, !dbg !12
// CHECK:STDOUT:
// CHECK:STDOUT: .loc22_21.1:                                      ; preds = %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a.var), !dbg !10
// CHECK:STDOUT:   store i32 %x, ptr %a.var, align 4, !dbg !10
// CHECK:STDOUT:   %.loc22_25 = load i32, ptr %a.var, align 4, !dbg !13
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call = icmp sgt i32 %.loc22_25, 9, !dbg !13
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Greater.call, label %.loc22_30.1, label %.loc22_30.2, !dbg !12
// CHECK:STDOUT:
// CHECK:STDOUT: .loc22_30.2:                                      ; preds = %.loc22_21.1
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %a.var), !dbg !10
// CHECK:STDOUT:   br label %.loc22_21.2, !dbg !12
// CHECK:STDOUT:
// CHECK:STDOUT: .loc22_30.1:                                      ; preds = %.loc22_21.1
// CHECK:STDOUT:   %.loc22_41 = load i32, ptr %a.var, align 4, !dbg !14
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc22 = add i32 %.loc22_41, 1, !dbg !14
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call.loc22, ptr %a.var, align 4, !dbg !15
// CHECK:STDOUT:   %.loc22_55 = load i32, ptr %a.var, align 4, !dbg !16
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %a.var), !dbg !10
// CHECK:STDOUT:   ret i32 %.loc22_55, !dbg !17
// CHECK:STDOUT:
// CHECK:STDOUT: .loc22_21.2:                                      ; preds = %.loc22_30.2, %entry
// CHECK:STDOUT:   br i1 true, label %match.case.then, label %match.done, !dbg !18
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %.loc22_21.2
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !11
// CHECK:STDOUT:   store i32 %x, ptr %b.var, align 4, !dbg !11
// CHECK:STDOUT:   %.loc23_30 = load i32, ptr %b.var, align 4, !dbg !19
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc23 = add i32 %.loc23_30, 2, !dbg !19
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call.loc23, ptr %b.var, align 4, !dbg !20
// CHECK:STDOUT:   %.loc23_44 = load i32, ptr %b.var, align 4, !dbg !21
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %b.var), !dbg !11
// CHECK:STDOUT:   ret i32 %.loc23_44, !dbg !22
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %.loc22_21.2
// CHECK:STDOUT:   ret i32 -2, !dbg !23
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !24 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !29
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CVarTuple.Main(ptr %p) #0 !dbg !30 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.var = alloca { i32, i32 }, align 4, !dbg !36
// CHECK:STDOUT:   br i1 true, label %match.case.then, label %match.done, !dbg !37
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.var), !dbg !36
// CHECK:STDOUT:   %tuple.elem0.loc29_10.1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %p, i32 0, i32 0, !dbg !38
// CHECK:STDOUT:   %tuple.elem0.loc29_10.1.tuple.elem.load = load i32, ptr %tuple.elem0.loc29_10.1.tuple.elem, align 4, !dbg !38
// CHECK:STDOUT:   %tuple.elem0.loc29_10.2.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.var, i32 0, i32 0, !dbg !38
// CHECK:STDOUT:   store i32 %tuple.elem0.loc29_10.1.tuple.elem.load, ptr %tuple.elem0.loc29_10.2.tuple.elem, align 4, !dbg !38
// CHECK:STDOUT:   %tuple.elem1.loc29_10.1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %p, i32 0, i32 1, !dbg !38
// CHECK:STDOUT:   %tuple.elem1.loc29_10.1.tuple.elem.load = load i32, ptr %tuple.elem1.loc29_10.1.tuple.elem, align 4, !dbg !38
// CHECK:STDOUT:   %tuple.elem1.loc29_10.2.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.var, i32 0, i32 1, !dbg !38
// CHECK:STDOUT:   store i32 %tuple.elem1.loc29_10.1.tuple.elem.load, ptr %tuple.elem1.loc29_10.2.tuple.elem, align 4, !dbg !38
// CHECK:STDOUT:   %tuple.elem0.loc30.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.var, i32 0, i32 0, !dbg !36
// CHECK:STDOUT:   %tuple.elem1.loc30.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.var, i32 0, i32 1, !dbg !36
// CHECK:STDOUT:   %.loc30_40 = load i32, ptr %tuple.elem0.loc30.tuple.elem, align 4, !dbg !39
// CHECK:STDOUT:   %.loc30_44 = load i32, ptr %tuple.elem1.loc30.tuple.elem, align 4, !dbg !40
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc30_40, %.loc30_44, !dbg !39
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %tuple.elem0.loc30.tuple.elem, align 4, !dbg !41
// CHECK:STDOUT:   %.loc30_54 = load i32, ptr %tuple.elem0.loc30.tuple.elem, align 4, !dbg !42
// CHECK:STDOUT:   call void @"_COp.7ebc50e8bd9eb2f1:core.Destroy.Core"(ptr %.var), !dbg !36
// CHECK:STDOUT:   ret i32 %.loc30_54, !dbg !43
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %entry
// CHECK:STDOUT:   ret i32 -2, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.7ebc50e8bd9eb2f1:core.Destroy.Core"(ptr %self) #0 !dbg !45 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !50
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CRefAlias.Main() #0 !dbg !51 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.var = alloca i32, align 4, !dbg !54
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %x.var), !dbg !54
// CHECK:STDOUT:   store i32 5, ptr %x.var, align 4, !dbg !54
// CHECK:STDOUT:   br i1 true, label %match.case.then, label %match.case.else, !dbg !55
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   store i32 7, ptr %x.var, align 4, !dbg !56
// CHECK:STDOUT:   br label %match.done, !dbg !57
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   br label %match.done, !dbg !57
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else, %match.case.then
// CHECK:STDOUT:   %.loc40 = load i32, ptr %x.var, align 4, !dbg !58
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %x.var), !dbg !54
// CHECK:STDOUT:   ret i32 %.loc40, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_COp.70db2d92ffddbef7:core.Destroy.Core", { 0, 3, 2, 1 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 3, 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "var_binding.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "TwoVarArms", linkageName: "_CTwoVarArms.Main", scope: null, file: !1, line: 20, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{!9}
// CHECK:STDOUT: !9 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !10 = !DILocation(line: 22, column: 10, scope: !4)
// CHECK:STDOUT: !11 = !DILocation(line: 23, column: 10, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 22, column: 21, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 22, column: 25, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 22, column: 41, scope: !4)
// CHECK:STDOUT: !15 = !DILocation(line: 22, column: 37, scope: !4)
// CHECK:STDOUT: !16 = !DILocation(line: 22, column: 55, scope: !4)
// CHECK:STDOUT: !17 = !DILocation(line: 22, column: 48, scope: !4)
// CHECK:STDOUT: !18 = !DILocation(line: 23, column: 5, scope: !4)
// CHECK:STDOUT: !19 = !DILocation(line: 23, column: 30, scope: !4)
// CHECK:STDOUT: !20 = !DILocation(line: 23, column: 26, scope: !4)
// CHECK:STDOUT: !21 = !DILocation(line: 23, column: 44, scope: !4)
// CHECK:STDOUT: !22 = !DILocation(line: 23, column: 37, scope: !4)
// CHECK:STDOUT: !23 = !DILocation(line: 25, column: 3, scope: !4)
// CHECK:STDOUT: !24 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 22, type: !25, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !27)
// CHECK:STDOUT: !25 = !DISubroutineType(types: !26)
// CHECK:STDOUT: !26 = !{null, !7}
// CHECK:STDOUT: !27 = !{!28}
// CHECK:STDOUT: !28 = !DILocalVariable(arg: 1, scope: !24, type: !7)
// CHECK:STDOUT: !29 = !DILocation(line: 22, column: 10, scope: !24)
// CHECK:STDOUT: !30 = distinct !DISubprogram(name: "VarTuple", linkageName: "_CVarTuple.Main", scope: null, file: !1, line: 28, type: !31, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !34)
// CHECK:STDOUT: !31 = !DISubroutineType(types: !32)
// CHECK:STDOUT: !32 = !{!7, !33}
// CHECK:STDOUT: !33 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !34 = !{!35}
// CHECK:STDOUT: !35 = !DILocalVariable(arg: 1, scope: !30, type: !33)
// CHECK:STDOUT: !36 = !DILocation(line: 30, column: 10, scope: !30)
// CHECK:STDOUT: !37 = !DILocation(line: 30, column: 5, scope: !30)
// CHECK:STDOUT: !38 = !DILocation(line: 29, column: 10, scope: !30)
// CHECK:STDOUT: !39 = !DILocation(line: 30, column: 40, scope: !30)
// CHECK:STDOUT: !40 = !DILocation(line: 30, column: 44, scope: !30)
// CHECK:STDOUT: !41 = !DILocation(line: 30, column: 36, scope: !30)
// CHECK:STDOUT: !42 = !DILocation(line: 30, column: 54, scope: !30)
// CHECK:STDOUT: !43 = !DILocation(line: 30, column: 47, scope: !30)
// CHECK:STDOUT: !44 = !DILocation(line: 32, column: 3, scope: !30)
// CHECK:STDOUT: !45 = distinct !DISubprogram(name: "Op", linkageName: "_COp.7ebc50e8bd9eb2f1:core.Destroy.Core", scope: null, file: !1, line: 30, type: !46, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !48)
// CHECK:STDOUT: !46 = !DISubroutineType(types: !47)
// CHECK:STDOUT: !47 = !{null, !33}
// CHECK:STDOUT: !48 = !{!49}
// CHECK:STDOUT: !49 = !DILocalVariable(arg: 1, scope: !45, type: !33)
// CHECK:STDOUT: !50 = !DILocation(line: 30, column: 10, scope: !45)
// CHECK:STDOUT: !51 = distinct !DISubprogram(name: "RefAlias", linkageName: "_CRefAlias.Main", scope: null, file: !1, line: 35, type: !52, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !52 = !DISubroutineType(types: !53)
// CHECK:STDOUT: !53 = !{!7}
// CHECK:STDOUT: !54 = !DILocation(line: 36, column: 3, scope: !51)
// CHECK:STDOUT: !55 = !DILocation(line: 38, column: 5, scope: !51)
// CHECK:STDOUT: !56 = !DILocation(line: 38, column: 26, scope: !51)
// CHECK:STDOUT: !57 = !DILocation(line: 37, column: 3, scope: !51)
// CHECK:STDOUT: !58 = !DILocation(line: 40, column: 10, scope: !51)
// CHECK:STDOUT: !59 = !DILocation(line: 40, column: 3, scope: !51)
// CHECK:STDOUT:

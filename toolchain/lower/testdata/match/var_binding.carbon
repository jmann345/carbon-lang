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
// CHECK:STDOUT: define i32 @_CTwoVarArms.Main(i32 %x) #0 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.var = alloca i32, align 4, !dbg !25
// CHECK:STDOUT:   %b.var = alloca i32, align 4, !dbg !33
// CHECK:STDOUT:   br i1 true, label %.loc22_21.1, label %.loc22_21.2, !dbg !24
// CHECK:STDOUT:
// CHECK:STDOUT: .loc22_21.1:                                      ; preds = %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a.var), !dbg !25
// CHECK:STDOUT:   store i32 %x, ptr %a.var, align 4, !dbg !25
// CHECK:STDOUT:   %.loc22_25 = load i32, ptr %a.var, align 4, !dbg !27
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call = icmp sgt i32 %.loc22_25, 9, !dbg !27
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Greater.call, label %.loc22_30.1, label %.loc22_30.2, !dbg !24
// CHECK:STDOUT:
// CHECK:STDOUT: .loc22_30.2:                                      ; preds = %.loc22_21.1
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %a.var), !dbg !25
// CHECK:STDOUT:   br label %.loc22_21.2, !dbg !24
// CHECK:STDOUT:
// CHECK:STDOUT: .loc22_30.1:                                      ; preds = %.loc22_21.1
// CHECK:STDOUT:   %.loc22_41 = load i32, ptr %a.var, align 4, !dbg !29
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc22 = add i32 %.loc22_41, 1, !dbg !29
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call.loc22, ptr %a.var, align 4, !dbg !28
// CHECK:STDOUT:   %.loc22_55 = load i32, ptr %a.var, align 4, !dbg !30
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %a.var), !dbg !25
// CHECK:STDOUT:   ret i32 %.loc22_55, !dbg !31
// CHECK:STDOUT:
// CHECK:STDOUT: .loc22_21.2:                                      ; preds = %.loc22_30.2, %entry
// CHECK:STDOUT:   br i1 true, label %match.case.then, label %match.done, !dbg !32
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %.loc22_21.2
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !33
// CHECK:STDOUT:   store i32 %x, ptr %b.var, align 4, !dbg !33
// CHECK:STDOUT:   %.loc23_30 = load i32, ptr %b.var, align 4, !dbg !36
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc23 = add i32 %.loc23_30, 2, !dbg !36
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call.loc23, ptr %b.var, align 4, !dbg !35
// CHECK:STDOUT:   %.loc23_44 = load i32, ptr %b.var, align 4, !dbg !37
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %b.var), !dbg !33
// CHECK:STDOUT:   ret i32 %.loc23_44, !dbg !38
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %.loc22_21.2
// CHECK:STDOUT:   ret i32 -2, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CVarTuple.Main(ptr %p) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.var = alloca { i32, i32 }, align 4, !dbg !53
// CHECK:STDOUT:   br i1 true, label %match.case.then, label %match.done, !dbg !52
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.var), !dbg !53
// CHECK:STDOUT:   %tuple.elem0.loc29_10.1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %p, i32 0, i32 0, !dbg !51
// CHECK:STDOUT:   %tuple.elem0.loc29_10.1.tuple.elem.load = load i32, ptr %tuple.elem0.loc29_10.1.tuple.elem, align 4, !dbg !51
// CHECK:STDOUT:   %tuple.elem0.loc29_10.2.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.var, i32 0, i32 0, !dbg !51
// CHECK:STDOUT:   store i32 %tuple.elem0.loc29_10.1.tuple.elem.load, ptr %tuple.elem0.loc29_10.2.tuple.elem, align 4, !dbg !51
// CHECK:STDOUT:   %tuple.elem1.loc29_10.1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %p, i32 0, i32 1, !dbg !51
// CHECK:STDOUT:   %tuple.elem1.loc29_10.1.tuple.elem.load = load i32, ptr %tuple.elem1.loc29_10.1.tuple.elem, align 4, !dbg !51
// CHECK:STDOUT:   %tuple.elem1.loc29_10.2.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.var, i32 0, i32 1, !dbg !51
// CHECK:STDOUT:   store i32 %tuple.elem1.loc29_10.1.tuple.elem.load, ptr %tuple.elem1.loc29_10.2.tuple.elem, align 4, !dbg !51
// CHECK:STDOUT:   %tuple.elem0.loc30.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.var, i32 0, i32 0, !dbg !53
// CHECK:STDOUT:   %tuple.elem1.loc30.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.var, i32 0, i32 1, !dbg !53
// CHECK:STDOUT:   %.loc30_40 = load i32, ptr %tuple.elem0.loc30.tuple.elem, align 4, !dbg !57
// CHECK:STDOUT:   %.loc30_44 = load i32, ptr %tuple.elem1.loc30.tuple.elem, align 4, !dbg !58
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc30_40, %.loc30_44, !dbg !57
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %tuple.elem0.loc30.tuple.elem, align 4, !dbg !56
// CHECK:STDOUT:   %.loc30_54 = load i32, ptr %tuple.elem0.loc30.tuple.elem, align 4, !dbg !59
// CHECK:STDOUT:   call void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %.var), !dbg !53
// CHECK:STDOUT:   ret i32 %.loc30_54, !dbg !60
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %entry
// CHECK:STDOUT:   ret i32 -2, !dbg !62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !64 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !66
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !66
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !66
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !66
// CHECK:STDOUT:   ret void, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !68 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self), !dbg !70
// CHECK:STDOUT:   ret void, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CRefAlias.Main() #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.var = alloca i32, align 4, !dbg !75
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %x.var), !dbg !75
// CHECK:STDOUT:   store i32 5, ptr %x.var, align 4, !dbg !75
// CHECK:STDOUT:   br i1 true, label %match.case.then, label %match.case.else, !dbg !78
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   store i32 7, ptr %x.var, align 4, !dbg !80
// CHECK:STDOUT:   br label %match.done, !dbg !81
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   br label %match.done, !dbg !81
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else, %match.case.then
// CHECK:STDOUT:   %.loc40 = load i32, ptr %x.var, align 4, !dbg !82
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %x.var), !dbg !75
// CHECK:STDOUT:   ret i32 %.loc40, !dbg !83
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core", { 0, 1, 2, 5, 4, 3 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 3, 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "var_binding.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !{null, !6}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !12 = !{!6, !11}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{null, !11}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !16 = !{!6}
// CHECK:STDOUT: !17 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "TwoVarArms", linkageName: "_CTwoVarArms.Main", scope: null, file: !4, line: 20, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !41)
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 1, scope: !18, type: !6)
// CHECK:STDOUT: !24 = !DILocation(line: 22, column: 21, scope: !18)
// CHECK:STDOUT: !25 = !DILocation(line: 22, column: 10, scope: !18)
// CHECK:STDOUT: !27 = !DILocation(line: 22, column: 25, scope: !18)
// CHECK:STDOUT: !28 = !DILocation(line: 22, column: 37, scope: !18)
// CHECK:STDOUT: !29 = !DILocation(line: 22, column: 41, scope: !18)
// CHECK:STDOUT: !30 = !DILocation(line: 22, column: 55, scope: !18)
// CHECK:STDOUT: !31 = !DILocation(line: 22, column: 48, scope: !18)
// CHECK:STDOUT: !32 = !DILocation(line: 23, column: 5, scope: !18)
// CHECK:STDOUT: !33 = !DILocation(line: 23, column: 10, scope: !18)
// CHECK:STDOUT: !35 = !DILocation(line: 23, column: 26, scope: !18)
// CHECK:STDOUT: !36 = !DILocation(line: 23, column: 30, scope: !18)
// CHECK:STDOUT: !37 = !DILocation(line: 23, column: 44, scope: !18)
// CHECK:STDOUT: !38 = !DILocation(line: 23, column: 37, scope: !18)
// CHECK:STDOUT: !40 = !DILocation(line: 25, column: 3, scope: !18)
// CHECK:STDOUT: !41 = !{!19}
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 22, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !45)
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !42, type: !6)
// CHECK:STDOUT: !44 = !DILocation(line: 22, column: 10, scope: !42)
// CHECK:STDOUT: !45 = !{!43}
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "VarTuple", linkageName: "_CVarTuple.Main", scope: null, file: !4, line: 28, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !63)
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !46, type: !11)
// CHECK:STDOUT: !51 = !DILocation(line: 29, column: 10, scope: !46)
// CHECK:STDOUT: !52 = !DILocation(line: 30, column: 5, scope: !46)
// CHECK:STDOUT: !53 = !DILocation(line: 30, column: 10, scope: !46)
// CHECK:STDOUT: !56 = !DILocation(line: 30, column: 36, scope: !46)
// CHECK:STDOUT: !57 = !DILocation(line: 30, column: 40, scope: !46)
// CHECK:STDOUT: !58 = !DILocation(line: 30, column: 44, scope: !46)
// CHECK:STDOUT: !59 = !DILocation(line: 30, column: 54, scope: !46)
// CHECK:STDOUT: !60 = !DILocation(line: 30, column: 47, scope: !46)
// CHECK:STDOUT: !62 = !DILocation(line: 32, column: 3, scope: !46)
// CHECK:STDOUT: !63 = !{!47}
// CHECK:STDOUT: !64 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !4, line: 30, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !67)
// CHECK:STDOUT: !65 = !DILocalVariable(arg: 1, scope: !64, type: !11)
// CHECK:STDOUT: !66 = !DILocation(line: 30, column: 10, scope: !64)
// CHECK:STDOUT: !67 = !{!65}
// CHECK:STDOUT: !68 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !4, line: 30, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !71)
// CHECK:STDOUT: !69 = !DILocalVariable(arg: 1, scope: !68, type: !11)
// CHECK:STDOUT: !70 = !DILocation(line: 30, column: 10, scope: !68)
// CHECK:STDOUT: !71 = !{!69}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "RefAlias", linkageName: "_CRefAlias.Main", scope: null, file: !4, line: 35, type: !17, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !75 = !DILocation(line: 36, column: 3, scope: !72)
// CHECK:STDOUT: !78 = !DILocation(line: 38, column: 5, scope: !72)
// CHECK:STDOUT: !80 = !DILocation(line: 38, column: 26, scope: !72)
// CHECK:STDOUT: !81 = !DILocation(line: 37, column: 3, scope: !72)
// CHECK:STDOUT: !82 = !DILocation(line: 40, column: 10, scope: !72)
// CHECK:STDOUT: !83 = !DILocation(line: 40, column: 3, scope: !72)
// CHECK:STDOUT:

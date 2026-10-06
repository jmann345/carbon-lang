// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/struct_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/struct_pattern.carbon

// Struct case patterns lower with ZERO lower-side code (W-077): the check
// layer desugars an arm to `struct_access` field reads (already lowered),
// `icmp` compares folded into one arm condition, and the landed dispatch
// CFG, with the arm's bindings re-extracted in the arm's body block. A
// subset+`_` arm reads only the fields it names; the trailing all-binding
// arm discharges exhaustiveness, so `Dispatch` needs no `default`.

fn Dispatch(p: {.tag: i32, .value: i32}) -> i32 {
  match (p) {
    case {.tag = 1, _} => { return 100; }
    case {.tag = 2, .value = v: i32} => { return v; }
    case {tag: i32, value: i32} => { return tag + value; }
  }
  return -2;
}

fn VarScrutinee() -> i32 {
  var s: {.a: i32, .b: i32} = {.a = 1, .b = 2};
  match (s) {
    case {.a = 1, b: i32} => { return b; }
    default => { return -1; }
  }
  return -2;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'struct_pattern.carbon'
// CHECK:STDOUT: source_filename = "struct_pattern.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @struct.631.loc30_3 = internal constant { i32, i32 } { i32 1, i32 2 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CDispatch.Main(ptr %p) #0 !dbg !16 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc21_10.1.tag = getelementptr inbounds nuw { i32, i32 }, ptr %p, i32 0, i32 0, !dbg !21
// CHECK:STDOUT:   %.loc21_10.1.tag.load = load i32, ptr %.loc21_10.1.tag, align 4, !dbg !21
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc22 = icmp eq i32 1, %.loc21_10.1.tag.load, !dbg !22
// CHECK:STDOUT:   br i1 %T.as_type.as.EqWith.impl.Equal.call.loc22, label %match.case.then.loc22, label %match.case.else.loc22, !dbg !22
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc22:                            ; preds = %entry
// CHECK:STDOUT:   ret i32 100, !dbg !23
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc22:                            ; preds = %entry
// CHECK:STDOUT:   %.loc21_10.2.tag = getelementptr inbounds nuw { i32, i32 }, ptr %p, i32 0, i32 0, !dbg !21
// CHECK:STDOUT:   %.loc21_10.2.tag.load = load i32, ptr %.loc21_10.2.tag, align 4, !dbg !21
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc23 = icmp eq i32 2, %.loc21_10.2.tag.load, !dbg !24
// CHECK:STDOUT:   br i1 %T.as_type.as.EqWith.impl.Equal.call.loc23, label %match.case.then.loc23, label %match.case.else.loc23, !dbg !24
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc23:                            ; preds = %match.case.else.loc22
// CHECK:STDOUT:   %.loc21_10.3.value = getelementptr inbounds nuw { i32, i32 }, ptr %p, i32 0, i32 1, !dbg !21
// CHECK:STDOUT:   %.loc21_10.3.value.load = load i32, ptr %.loc21_10.3.value, align 4, !dbg !21
// CHECK:STDOUT:   ret i32 %.loc21_10.3.value.load, !dbg !27
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc23:                            ; preds = %match.case.else.loc22
// CHECK:STDOUT:   br i1 true, label %match.case.then.loc24, label %match.done, !dbg !28
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc24:                            ; preds = %match.case.else.loc23
// CHECK:STDOUT:   %.loc21_10.4.tag = getelementptr inbounds nuw { i32, i32 }, ptr %p, i32 0, i32 0, !dbg !21
// CHECK:STDOUT:   %.loc21_10.4.tag.load = load i32, ptr %.loc21_10.4.tag, align 4, !dbg !21
// CHECK:STDOUT:   %.loc21_10.5.value = getelementptr inbounds nuw { i32, i32 }, ptr %p, i32 0, i32 1, !dbg !21
// CHECK:STDOUT:   %.loc21_10.5.value.load = load i32, ptr %.loc21_10.5.value, align 4, !dbg !21
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc21_10.4.tag.load, %.loc21_10.5.value.load, !dbg !31
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !33
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc23
// CHECK:STDOUT:   ret i32 -2, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CVarScrutinee.Main() #0 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %s.var = alloca { i32, i32 }, align 4, !dbg !40
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %s.var), !dbg !40
// CHECK:STDOUT:   %.loc30_46.3.a = getelementptr inbounds nuw { i32, i32 }, ptr %s.var, i32 0, i32 0, !dbg !41
// CHECK:STDOUT:   %.loc30_46.6.b = getelementptr inbounds nuw { i32, i32 }, ptr %s.var, i32 0, i32 1, !dbg !41
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %s.var, ptr align 4 @struct.631.loc30_3, i64 8, i1 false), !dbg !40
// CHECK:STDOUT:   %.loc31_10.1.a = getelementptr inbounds nuw { i32, i32 }, ptr %s.var, i32 0, i32 0, !dbg !43
// CHECK:STDOUT:   %.loc31_10.2 = load i32, ptr %.loc31_10.1.a, align 4, !dbg !43
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call = icmp eq i32 1, %.loc31_10.2, !dbg !44
// CHECK:STDOUT:   br i1 %T.as_type.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !44
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   %.loc31_10.3.b = getelementptr inbounds nuw { i32, i32 }, ptr %s.var, i32 0, i32 1, !dbg !43
// CHECK:STDOUT:   %.loc31_10.4 = load i32, ptr %.loc31_10.3.b, align 4, !dbg !43
// CHECK:STDOUT:   call void @"_CSelfDestruct.b4c762864cd9a02b:core.Destroy.Core"(ptr %s.var), !dbg !40
// CHECK:STDOUT:   ret i32 %.loc31_10.4, !dbg !47
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   call void @"_CSelfDestruct.b4c762864cd9a02b:core.Destroy.Core"(ptr %s.var), !dbg !40
// CHECK:STDOUT:   ret i32 -1, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !49 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b4c762864cd9a02b:core.Destroy.Core"(ptr %self) #0 !dbg !53 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc30_3.1.b = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !55
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc30_3.1.b), !dbg !55
// CHECK:STDOUT:   %.loc30_3.2.a = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !55
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc30_3.2.a), !dbg !55
// CHECK:STDOUT:   ret void, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b4c762864cd9a02b:core.Destroy.Core"(ptr %self) #0 !dbg !57 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b4c762864cd9a02b:core.Destroy.Core"(ptr %self), !dbg !59
// CHECK:STDOUT:   ret void, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.b4c762864cd9a02b:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "struct_pattern.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!6, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{!6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{null, !7}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !16 = distinct !DISubprogram(name: "Dispatch", linkageName: "_CDispatch.Main", scope: null, file: !4, line: 20, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !36)
// CHECK:STDOUT: !17 = !DILocalVariable(arg: 1, scope: !16, type: !7)
// CHECK:STDOUT: !21 = !DILocation(line: 21, column: 10, scope: !16)
// CHECK:STDOUT: !22 = !DILocation(line: 22, column: 5, scope: !16)
// CHECK:STDOUT: !23 = !DILocation(line: 22, column: 29, scope: !16)
// CHECK:STDOUT: !24 = !DILocation(line: 23, column: 5, scope: !16)
// CHECK:STDOUT: !27 = !DILocation(line: 23, column: 43, scope: !16)
// CHECK:STDOUT: !28 = !DILocation(line: 24, column: 5, scope: !16)
// CHECK:STDOUT: !31 = !DILocation(line: 24, column: 45, scope: !16)
// CHECK:STDOUT: !33 = !DILocation(line: 24, column: 38, scope: !16)
// CHECK:STDOUT: !35 = !DILocation(line: 26, column: 3, scope: !16)
// CHECK:STDOUT: !36 = !{!17}
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "VarScrutinee", linkageName: "_CVarScrutinee.Main", scope: null, file: !4, line: 29, type: !11, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !40 = !DILocation(line: 30, column: 3, scope: !37)
// CHECK:STDOUT: !41 = !DILocation(line: 30, column: 31, scope: !37)
// CHECK:STDOUT: !43 = !DILocation(line: 31, column: 10, scope: !37)
// CHECK:STDOUT: !44 = !DILocation(line: 32, column: 5, scope: !37)
// CHECK:STDOUT: !47 = !DILocation(line: 32, column: 32, scope: !37)
// CHECK:STDOUT: !48 = !DILocation(line: 33, column: 18, scope: !37)
// CHECK:STDOUT: !49 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 30, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !52)
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !49, type: !6)
// CHECK:STDOUT: !51 = !DILocation(line: 30, column: 3, scope: !49)
// CHECK:STDOUT: !52 = !{!50}
// CHECK:STDOUT: !53 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b4c762864cd9a02b:core.Destroy.Core", scope: null, file: !4, line: 30, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !56)
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !53, type: !7)
// CHECK:STDOUT: !55 = !DILocation(line: 30, column: 3, scope: !53)
// CHECK:STDOUT: !56 = !{!54}
// CHECK:STDOUT: !57 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b4c762864cd9a02b:core.Destroy.Core", scope: null, file: !4, line: 30, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !60)
// CHECK:STDOUT: !58 = !DILocalVariable(arg: 1, scope: !57, type: !7)
// CHECK:STDOUT: !59 = !DILocation(line: 30, column: 3, scope: !57)
// CHECK:STDOUT: !60 = !{!58}
// CHECK:STDOUT:

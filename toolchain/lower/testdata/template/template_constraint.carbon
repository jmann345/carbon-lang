// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/template/template_constraint.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/template/template_constraint.carbon

// A dependent method call through a `template constraint` binding lowers as an
// ordinary call to the type's own method: a satisfied conversion adds no
// witnesses, so nothing under toolchain/lower/ changes (fork decision F-010 /
// SC-1, fork/structural/plan.md §1.E; the merging.carbon `InitAndCallF`
// precedent).

// --- call_method.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class StructuralOnly {
  fn Get(unused self) -> i32 { return 42; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Run() -> i32 {
  let s: StructuralOnly = {};
  return CallGet(s);
}

// --- compound_nongeneric.carbon
library "[[@TEST_NAME]]";

// Compound access through a requirement in a non-generic function is not
// template-dependent and lowers to a call of the type's own method (D-SC-20;
// fill round 1, fix 2; fill round 2, review finding F3).
template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn Get(unused self) -> i32 { return 42; }
}

fn Run() -> i32 {
  let c: C = {};
  return c.(HasGet.Get)();
}


// --- impl_member_alias.carbon
library "[[@TEST_NAME]]";

// An impl member named through a satisfying type, `(C as HasGet).Get`, is the
// type's own method, so the impl needs no thunk and lowers like an alias of
// `C.Get`. Spelled as the requirement itself, `HasGet.Get`, it is rejected at
// the impl (fill round 3, review finding BLOCKER-1: that spelling passed check
// and crashed in the mangler; check/testdata/named_constraint/
// fail_template_constraint_requirement_call.carbon, `fail_impl_member_alias`).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  fn F(self) -> i32;
}

class C {
  fn Get(unused self) -> i32 { return 4; }
}

impl C as I {
  alias F = (C as HasGet).Get;
}

fn Run() -> i32 {
  let c: C = {};
  return c.(I.F)();
}

// --- requirement_through_type_as_value.carbon
library "[[@TEST_NAME]]";

// A requirement named through a type that satisfies it is that type's own
// member (D-SC-4), a value like any function: `Take(C.(HasN.N))` lowers as
// `Take(C.N)`, in a template too. Named with no such type, it is rejected (fill
// round 4, review finding BLOCKER-1; check/testdata/named_constraint/
// fail_template_constraint_requirement_call.carbon, `fail_requirement_as_value`).
template constraint HasN {
  fn N() -> i32;
}

class C {
  fn N() -> i32 { return 5; }
}

fn Take[T: type](unused f: T) -> i32 { return 1; }

fn Dependent[template T: HasN](unused x: T) -> i32 { return Take(T.N); }

fn Run() -> i32 {
  let c: C = {};
  return Take(C.(HasN.N)) + Take((C as HasN).N) + Dependent(c);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'call_method.carbon'
// CHECK:STDOUT: source_filename = "call_method.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @StructuralOnly.val = internal constant {} zeroinitializer
// CHECK:STDOUT: @StructuralOnly.val.loc14_28.6 = internal constant {} zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CGet.StructuralOnly.Main(ptr %self) #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 42, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !21 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14_28.2.temp = alloca {}, align 1, !dbg !24
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc14_28.2.temp), !dbg !24
// CHECK:STDOUT:   %CallGet.call = call i32 @_CCallGet.Main.f62a2c791da98824(ptr @StructuralOnly.val.loc14_28.6), !dbg !28
// CHECK:STDOUT:   call void @"_CSelfDestruct.5f34240af69d1bb5:core.Destroy.Core"(ptr @StructuralOnly.val), !dbg !24
// CHECK:STDOUT:   ret i32 %CallGet.call, !dbg !29
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.cb8adced19392b99:core.Destroy.Core"(ptr %self) #0 !dbg !30 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5f34240af69d1bb5:core.Destroy.Core"(ptr %self) #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CCallGet.Main.f62a2c791da98824(ptr %x) #0 !dbg !38 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %StructuralOnly.Get.call = call i32 @_CGet.StructuralOnly.Main(ptr %x), !dbg !43
// CHECK:STDOUT:   ret i32 %StructuralOnly.Get.call, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "call_method.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!6, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{!6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.StructuralOnly.Main", scope: null, file: !4, line: 8, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !20)
// CHECK:STDOUT: !15 = !DILocalVariable(arg: 1, scope: !14, type: !7)
// CHECK:STDOUT: !19 = !DILocation(line: 8, column: 32, scope: !14)
// CHECK:STDOUT: !20 = !{!15}
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !4, line: 13, type: !11, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !24 = !DILocation(line: 14, column: 27, scope: !21)
// CHECK:STDOUT: !28 = !DILocation(line: 15, column: 10, scope: !21)
// CHECK:STDOUT: !29 = !DILocation(line: 15, column: 3, scope: !21)
// CHECK:STDOUT: !30 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.cb8adced19392b99:core.Destroy.Core", scope: null, file: !4, line: 14, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !33)
// CHECK:STDOUT: !31 = !DILocalVariable(arg: 1, scope: !30, type: !7)
// CHECK:STDOUT: !32 = !DILocation(line: 14, column: 27, scope: !30)
// CHECK:STDOUT: !33 = !{!31}
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5f34240af69d1bb5:core.Destroy.Core", scope: null, file: !4, line: 14, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !37)
// CHECK:STDOUT: !35 = !DILocalVariable(arg: 1, scope: !34, type: !7)
// CHECK:STDOUT: !36 = !DILocation(line: 14, column: 27, scope: !34)
// CHECK:STDOUT: !37 = !{!35}
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "CallGet", linkageName: "_CCallGet.Main.f62a2c791da98824", scope: null, file: !4, line: 11, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !45)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !38, type: !7)
// CHECK:STDOUT: !43 = !DILocation(line: 11, column: 54, scope: !38)
// CHECK:STDOUT: !44 = !DILocation(line: 11, column: 47, scope: !38)
// CHECK:STDOUT: !45 = !{!39}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'compound_nongeneric.carbon'
// CHECK:STDOUT: source_filename = "compound_nongeneric.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @C.val = internal constant {} zeroinitializer
// CHECK:STDOUT: @C.val.loc15_15.6 = internal constant {} zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CGet.C.Main(ptr %self) #0 !dbg !48 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 42, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !55 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc15_15.2.temp = alloca {}, align 1, !dbg !58
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc15_15.2.temp), !dbg !58
// CHECK:STDOUT:   %C.Get.call = call i32 @_CGet.C.Main(ptr @C.val.loc15_15.6), !dbg !61
// CHECK:STDOUT:   call void @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core"(ptr @C.val), !dbg !58
// CHECK:STDOUT:   ret i32 %C.Get.call, !dbg !62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.cb8adced19392b99:core.Destroy.Core"(ptr %self) #0 !dbg !63 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core"(ptr %self) #0 !dbg !67 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!47}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!6, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{!6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !46 = !DIFile(filename: "compound_nongeneric.carbon", directory: "")
// CHECK:STDOUT: !47 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !46, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.C.Main", scope: null, file: !46, line: 11, type: !9, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !54)
// CHECK:STDOUT: !49 = !DILocalVariable(arg: 1, scope: !48, type: !7)
// CHECK:STDOUT: !53 = !DILocation(line: 11, column: 32, scope: !48)
// CHECK:STDOUT: !54 = !{!49}
// CHECK:STDOUT: !55 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !46, line: 14, type: !11, spFlags: DISPFlagDefinition, unit: !47)
// CHECK:STDOUT: !58 = !DILocation(line: 15, column: 14, scope: !55)
// CHECK:STDOUT: !61 = !DILocation(line: 16, column: 10, scope: !55)
// CHECK:STDOUT: !62 = !DILocation(line: 16, column: 3, scope: !55)
// CHECK:STDOUT: !63 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.cb8adced19392b99:core.Destroy.Core", scope: null, file: !46, line: 15, type: !13, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !66)
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !63, type: !7)
// CHECK:STDOUT: !65 = !DILocation(line: 15, column: 14, scope: !63)
// CHECK:STDOUT: !66 = !{!64}
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core", scope: null, file: !46, line: 15, type: !13, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !70)
// CHECK:STDOUT: !68 = !DILocalVariable(arg: 1, scope: !67, type: !7)
// CHECK:STDOUT: !69 = !DILocation(line: 15, column: 14, scope: !67)
// CHECK:STDOUT: !70 = !{!68}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'impl_member_alias.carbon'
// CHECK:STDOUT: source_filename = "impl_member_alias.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @C.val = internal constant {} zeroinitializer
// CHECK:STDOUT: @C.val.loc26_15.6 = internal constant {} zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CGet.C.Main(ptr %self) #0 !dbg !73 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 4, !dbg !78
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !80 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc26_15.2.temp = alloca {}, align 1, !dbg !83
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc26_15.2.temp), !dbg !83
// CHECK:STDOUT:   %C.Get.call = call i32 @_CGet.C.Main(ptr @C.val.loc26_15.6), !dbg !86
// CHECK:STDOUT:   call void @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core"(ptr @C.val), !dbg !83
// CHECK:STDOUT:   ret i32 %C.Get.call, !dbg !87
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.cb8adced19392b99:core.Destroy.Core"(ptr %self) #0 !dbg !88 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !90
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core"(ptr %self) #0 !dbg !92 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!72}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!6, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{!6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !71 = !DIFile(filename: "impl_member_alias.carbon", directory: "")
// CHECK:STDOUT: !72 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !71, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !73 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.C.Main", scope: null, file: !71, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !72, retainedNodes: !79)
// CHECK:STDOUT: !74 = !DILocalVariable(arg: 1, scope: !73, type: !7)
// CHECK:STDOUT: !78 = !DILocation(line: 18, column: 32, scope: !73)
// CHECK:STDOUT: !79 = !{!74}
// CHECK:STDOUT: !80 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !71, line: 25, type: !11, spFlags: DISPFlagDefinition, unit: !72)
// CHECK:STDOUT: !83 = !DILocation(line: 26, column: 14, scope: !80)
// CHECK:STDOUT: !86 = !DILocation(line: 27, column: 10, scope: !80)
// CHECK:STDOUT: !87 = !DILocation(line: 27, column: 3, scope: !80)
// CHECK:STDOUT: !88 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.cb8adced19392b99:core.Destroy.Core", scope: null, file: !71, line: 26, type: !13, spFlags: DISPFlagDefinition, unit: !72, retainedNodes: !91)
// CHECK:STDOUT: !89 = !DILocalVariable(arg: 1, scope: !88, type: !7)
// CHECK:STDOUT: !90 = !DILocation(line: 26, column: 14, scope: !88)
// CHECK:STDOUT: !91 = !{!89}
// CHECK:STDOUT: !92 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core", scope: null, file: !71, line: 26, type: !13, spFlags: DISPFlagDefinition, unit: !72, retainedNodes: !95)
// CHECK:STDOUT: !93 = !DILocalVariable(arg: 1, scope: !92, type: !7)
// CHECK:STDOUT: !94 = !DILocation(line: 26, column: 14, scope: !92)
// CHECK:STDOUT: !95 = !{!93}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'requirement_through_type_as_value.carbon'
// CHECK:STDOUT: source_filename = "requirement_through_type_as_value.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @C.val = internal constant {} zeroinitializer
// CHECK:STDOUT: @C.val.loc21_15.6 = internal constant {} zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CN.C.Main() #0 !dbg !98 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 5, !dbg !101
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !102 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc21_15.2.temp = alloca {}, align 1, !dbg !105
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc21_15.2.temp), !dbg !105
// CHECK:STDOUT:   %Take.call.loc22_25 = call i32 @_CTake.Main.46f278d30c60e682(), !dbg !108
// CHECK:STDOUT:   %Take.call.loc22_47 = call i32 @_CTake.Main.46f278d30c60e682(), !dbg !109
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc22_27 = add i32 %Take.call.loc22_25, %Take.call.loc22_47, !dbg !108
// CHECK:STDOUT:   %Dependent.call = call i32 @_CDependent.Main.2eb69dd0c58be63c(ptr @C.val.loc21_15.6), !dbg !111
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc22_49 = add i32 %Int.as.AddWith.impl.Op.call.loc22_27, %Dependent.call, !dbg !108
// CHECK:STDOUT:   call void @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core"(ptr @C.val), !dbg !105
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call.loc22_49, !dbg !112
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.cb8adced19392b99:core.Destroy.Core"(ptr %self) #0 !dbg !113 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !115
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core"(ptr %self) #0 !dbg !117 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !119
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CTake.Main.46f278d30c60e682() #0 !dbg !121 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !125
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CDependent.Main.2eb69dd0c58be63c(ptr %x) #0 !dbg !126 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Take.call = call i32 @_CTake.Main.46f278d30c60e682(), !dbg !131
// CHECK:STDOUT:   ret i32 %Take.call, !dbg !132
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CTake.Main.46f278d30c60e682, { 0, 2, 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!97}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!6, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{!6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !96 = !DIFile(filename: "requirement_through_type_as_value.carbon", directory: "")
// CHECK:STDOUT: !97 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !96, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !98 = distinct !DISubprogram(name: "N", linkageName: "_CN.C.Main", scope: null, file: !96, line: 13, type: !11, spFlags: DISPFlagDefinition, unit: !97)
// CHECK:STDOUT: !101 = !DILocation(line: 13, column: 19, scope: !98)
// CHECK:STDOUT: !102 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !96, line: 20, type: !11, spFlags: DISPFlagDefinition, unit: !97)
// CHECK:STDOUT: !105 = !DILocation(line: 21, column: 14, scope: !102)
// CHECK:STDOUT: !108 = !DILocation(line: 22, column: 10, scope: !102)
// CHECK:STDOUT: !109 = !DILocation(line: 22, column: 29, scope: !102)
// CHECK:STDOUT: !111 = !DILocation(line: 22, column: 51, scope: !102)
// CHECK:STDOUT: !112 = !DILocation(line: 22, column: 3, scope: !102)
// CHECK:STDOUT: !113 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.cb8adced19392b99:core.Destroy.Core", scope: null, file: !96, line: 21, type: !13, spFlags: DISPFlagDefinition, unit: !97, retainedNodes: !116)
// CHECK:STDOUT: !114 = !DILocalVariable(arg: 1, scope: !113, type: !7)
// CHECK:STDOUT: !115 = !DILocation(line: 21, column: 14, scope: !113)
// CHECK:STDOUT: !116 = !{!114}
// CHECK:STDOUT: !117 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core", scope: null, file: !96, line: 21, type: !13, spFlags: DISPFlagDefinition, unit: !97, retainedNodes: !120)
// CHECK:STDOUT: !118 = !DILocalVariable(arg: 1, scope: !117, type: !7)
// CHECK:STDOUT: !119 = !DILocation(line: 21, column: 14, scope: !117)
// CHECK:STDOUT: !120 = !{!118}
// CHECK:STDOUT: !121 = distinct !DISubprogram(name: "Take", linkageName: "_CTake.Main.46f278d30c60e682", scope: null, file: !96, line: 16, type: !11, spFlags: DISPFlagDefinition, unit: !97)
// CHECK:STDOUT: !125 = !DILocation(line: 16, column: 40, scope: !121)
// CHECK:STDOUT: !126 = distinct !DISubprogram(name: "Dependent", linkageName: "_CDependent.Main.2eb69dd0c58be63c", scope: null, file: !96, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !97, retainedNodes: !133)
// CHECK:STDOUT: !127 = !DILocalVariable(arg: 1, scope: !126, type: !7)
// CHECK:STDOUT: !131 = !DILocation(line: 18, column: 61, scope: !126)
// CHECK:STDOUT: !132 = !DILocation(line: 18, column: 54, scope: !126)
// CHECK:STDOUT: !133 = !{!127}
// CHECK:STDOUT:

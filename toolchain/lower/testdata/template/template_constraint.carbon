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


// --- requirement_through_template_instantiation.carbon
library "[[@TEST_NAME]]";

// The templates of requirement-call
// `fail_requirement_through_template_instantiation`, instantiated with a class
// that satisfies the constraints: `T.N` and `T.Get` are the class's own
// functions (D-SC-4), values like any function (fill round 5, review 1 finding
// BLOCKER-1). `Nested` and `IfTuple` are left out: with any function value,
// `Take(((C.N, 1), 2))` fails LLVM's module verifier (lower/lower.cpp:48) and
// `Take(if true then (C.N, 1) else (C.N, 2))` aborts in `BranchWithArg`, on
// trunk 0bdce60a5 too.
template constraint HasN {
  fn N() -> i32;
}

template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn N() -> i32 { return 5; }
  fn Get(unused self) -> i32 { return 6; }
}

fn Take[T: type](unused f: T) -> i32 { return 1; }

fn Tuple(template T: type) -> i32 { return Take((T.N, 1)); }

fn Struct(template T: type) -> i32 { return Take({.f = T.N}); }

fn LetTuple(template T: type) -> i32 {
  let t: (typeof(T.N), i32) = (T.N, 1);
  return Take(t);
}

fn MethodTuple(template T: type) -> i32 { return Take((T.Get, 1)); }

fn Discard(template T: type) -> i32 {
  T.N;
  (T.N, 1);
  {.a = T.N};
  return 0;
}

class Box(template FT: type) {
  fn F() -> i32 { return Take((FT.N, 1)); }
}

fn Run() -> i32 {
  return Tuple(C) + Struct(C) + LetTuple(C) + MethodTuple(C) + Discard(C) +
         Box(C).F();
}

// --- requirement_typeof.carbon
library "[[@TEST_NAME]]";

// `typeof` of a requirement named with no self type is a concrete type with no
// values, lowered as an empty struct (D-SC-20 as amended at fill round 5,
// review 1 finding BLOCKER-2 and review 2 finding BLOCKER-1: a parameter of
// the `.Self`-symbolic type aborted lowering), as upstream's `typeof(I.F)` is.
// `typeof(C.(HasN.N))` is `C.N`'s own function type (D-SC-4).
template constraint HasN {
  fn N() -> i32;
}

template constraint Has(X: type) {
  fn N() -> X;
}

interface Z {
  fn F() -> i32;
}

interface I {
  fn F();
}

class C {
  fn N() -> i32 { return 2; }
}

class W {
  var f: typeof(HasN.N);
}

impl typeof(HasN.N) as Z {
  fn F() -> i32 { return 9; }
}

fn Pointer(unused p: typeof(HasN.N)*) -> i32 { return 3; }

fn Wrapped(unused w: W) {}

fn Generic[T: type](unused x: T) -> i32 {
  var unused a: array(typeof(Has(T).N), 0) = ();
  return 4;
}

fn Upstream(unused f: typeof(I.F)) {}

fn Satisfied(unused f: typeof(C.(HasN.N))) -> i32 { return 1; }

fn Run() -> i32 {
  Upstream(I.F);
  return typeof(HasN.N).(Z.F)() + Generic(1) + Satisfied(C.(HasN.N));
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
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'requirement_through_template_instantiation.carbon'
// CHECK:STDOUT: source_filename = "requirement_through_template_instantiation.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @tuple.6f2.tuple.6f2 = internal constant { {}, {} } zeroinitializer
// CHECK:STDOUT: @tuple.7fd.loc31_38.5 = internal constant { {}, i32 } { {} zeroinitializer, i32 1 }
// CHECK:STDOUT: @tuple.799.tuple.799 = internal constant { {}, {} } zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CN.C.Main() #0 !dbg !136 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 5, !dbg !139
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CGet.C.Main(ptr %self) #0 !dbg !140 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 6, !dbg !145
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !147 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Tuple.call = call i32 @_CTuple.Main.9522ff908e97e267(), !dbg !150
// CHECK:STDOUT:   %Struct.call = call i32 @_CStruct.Main.9522ff908e97e267(), !dbg !151
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc49_19 = add i32 %Tuple.call, %Struct.call, !dbg !150
// CHECK:STDOUT:   %LetTuple.call = call i32 @_CLetTuple.Main.9522ff908e97e267(), !dbg !152
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc49_31 = add i32 %Int.as.AddWith.impl.Op.call.loc49_19, %LetTuple.call, !dbg !150
// CHECK:STDOUT:   %MethodTuple.call = call i32 @_CMethodTuple.Main.9522ff908e97e267(), !dbg !153
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc49_45 = add i32 %Int.as.AddWith.impl.Op.call.loc49_31, %MethodTuple.call, !dbg !150
// CHECK:STDOUT:   %Discard.call = call i32 @_CDiscard.Main.9522ff908e97e267(), !dbg !154
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc49_62 = add i32 %Int.as.AddWith.impl.Op.call.loc49_45, %Discard.call, !dbg !150
// CHECK:STDOUT:   %Box.F.call = call i32 @_CF.Box.Main.9522ff908e97e267(), !dbg !155
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc49_75 = add i32 %Int.as.AddWith.impl.Op.call.loc49_62, %Box.F.call, !dbg !150
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call.loc49_75, !dbg !156
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CTuple.Main.9522ff908e97e267() #0 !dbg !157 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Take.call.3e46d0.2 = call i32 @_CTake.Main.1f03bbe8d00cdc13(ptr @tuple.6f2.tuple.6f2), !dbg !160
// CHECK:STDOUT:   ret i32 %Take.call.3e46d0.2, !dbg !161
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CStruct.Main.9522ff908e97e267() #0 !dbg !162 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Take.call.146 = call i32 @_CTake.Main.eab0bcee34c43f4b({ {} } zeroinitializer), !dbg !165
// CHECK:STDOUT:   ret i32 %Take.call.146, !dbg !166
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CLetTuple.Main.9522ff908e97e267() #0 !dbg !167 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Take.call.e07 = call i32 @_CTake.Main.1f03bbe8d00cdc13(ptr @tuple.7fd.loc31_38.5), !dbg !173
// CHECK:STDOUT:   ret i32 %Take.call.e07, !dbg !174
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CMethodTuple.Main.9522ff908e97e267() #0 !dbg !175 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Take.call.6c2 = call i32 @_CTake.Main.1f03bbe8d00cdc13(ptr @tuple.799.tuple.799), !dbg !178
// CHECK:STDOUT:   ret i32 %Take.call.6c2, !dbg !179
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CDiscard.Main.9522ff908e97e267() #0 !dbg !180 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 0, !dbg !183
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CF.Box.Main.9522ff908e97e267() #0 !dbg !184 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Take.call.3e46d0.1 = call i32 @_CTake.Main.1f03bbe8d00cdc13(ptr @tuple.6f2.tuple.6f2), !dbg !187
// CHECK:STDOUT:   ret i32 %Take.call.3e46d0.1, !dbg !188
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CTake.Main.1f03bbe8d00cdc13(ptr %f) #0 !dbg !189 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !194
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CTake.Main.eab0bcee34c43f4b({ {} } %f) #0 !dbg !196 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !201
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CTake.Main.1f03bbe8d00cdc13, { 3, 1, 0, 2 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!135}
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
// CHECK:STDOUT: !134 = !DIFile(filename: "requirement_through_template_instantiation.carbon", directory: "")
// CHECK:STDOUT: !135 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !134, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !136 = distinct !DISubprogram(name: "N", linkageName: "_CN.C.Main", scope: null, file: !134, line: 20, type: !11, spFlags: DISPFlagDefinition, unit: !135)
// CHECK:STDOUT: !139 = !DILocation(line: 20, column: 19, scope: !136)
// CHECK:STDOUT: !140 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.C.Main", scope: null, file: !134, line: 21, type: !9, spFlags: DISPFlagDefinition, unit: !135, retainedNodes: !146)
// CHECK:STDOUT: !141 = !DILocalVariable(arg: 1, scope: !140, type: !7)
// CHECK:STDOUT: !145 = !DILocation(line: 21, column: 32, scope: !140)
// CHECK:STDOUT: !146 = !{!141}
// CHECK:STDOUT: !147 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !134, line: 48, type: !11, spFlags: DISPFlagDefinition, unit: !135)
// CHECK:STDOUT: !150 = !DILocation(line: 49, column: 10, scope: !147)
// CHECK:STDOUT: !151 = !DILocation(line: 49, column: 21, scope: !147)
// CHECK:STDOUT: !152 = !DILocation(line: 49, column: 33, scope: !147)
// CHECK:STDOUT: !153 = !DILocation(line: 49, column: 47, scope: !147)
// CHECK:STDOUT: !154 = !DILocation(line: 49, column: 64, scope: !147)
// CHECK:STDOUT: !155 = !DILocation(line: 50, column: 10, scope: !147)
// CHECK:STDOUT: !156 = !DILocation(line: 49, column: 3, scope: !147)
// CHECK:STDOUT: !157 = distinct !DISubprogram(name: "Tuple", linkageName: "_CTuple.Main.9522ff908e97e267", scope: null, file: !134, line: 26, type: !11, spFlags: DISPFlagDefinition, unit: !135)
// CHECK:STDOUT: !160 = !DILocation(line: 26, column: 44, scope: !157)
// CHECK:STDOUT: !161 = !DILocation(line: 26, column: 37, scope: !157)
// CHECK:STDOUT: !162 = distinct !DISubprogram(name: "Struct", linkageName: "_CStruct.Main.9522ff908e97e267", scope: null, file: !134, line: 28, type: !11, spFlags: DISPFlagDefinition, unit: !135)
// CHECK:STDOUT: !165 = !DILocation(line: 28, column: 45, scope: !162)
// CHECK:STDOUT: !166 = !DILocation(line: 28, column: 38, scope: !162)
// CHECK:STDOUT: !167 = distinct !DISubprogram(name: "LetTuple", linkageName: "_CLetTuple.Main.9522ff908e97e267", scope: null, file: !134, line: 30, type: !11, spFlags: DISPFlagDefinition, unit: !135)
// CHECK:STDOUT: !173 = !DILocation(line: 32, column: 10, scope: !167)
// CHECK:STDOUT: !174 = !DILocation(line: 32, column: 3, scope: !167)
// CHECK:STDOUT: !175 = distinct !DISubprogram(name: "MethodTuple", linkageName: "_CMethodTuple.Main.9522ff908e97e267", scope: null, file: !134, line: 35, type: !11, spFlags: DISPFlagDefinition, unit: !135)
// CHECK:STDOUT: !178 = !DILocation(line: 35, column: 50, scope: !175)
// CHECK:STDOUT: !179 = !DILocation(line: 35, column: 43, scope: !175)
// CHECK:STDOUT: !180 = distinct !DISubprogram(name: "Discard", linkageName: "_CDiscard.Main.9522ff908e97e267", scope: null, file: !134, line: 37, type: !11, spFlags: DISPFlagDefinition, unit: !135)
// CHECK:STDOUT: !183 = !DILocation(line: 41, column: 3, scope: !180)
// CHECK:STDOUT: !184 = distinct !DISubprogram(name: "F", linkageName: "_CF.Box.Main.9522ff908e97e267", scope: null, file: !134, line: 45, type: !11, spFlags: DISPFlagDefinition, unit: !135)
// CHECK:STDOUT: !187 = !DILocation(line: 45, column: 26, scope: !184)
// CHECK:STDOUT: !188 = !DILocation(line: 45, column: 19, scope: !184)
// CHECK:STDOUT: !189 = distinct !DISubprogram(name: "Take", linkageName: "_CTake.Main.1f03bbe8d00cdc13", scope: null, file: !134, line: 24, type: !9, spFlags: DISPFlagDefinition, unit: !135, retainedNodes: !195)
// CHECK:STDOUT: !190 = !DILocalVariable(arg: 1, scope: !189, type: !7)
// CHECK:STDOUT: !194 = !DILocation(line: 24, column: 40, scope: !189)
// CHECK:STDOUT: !195 = !{!190}
// CHECK:STDOUT: !196 = distinct !DISubprogram(name: "Take", linkageName: "_CTake.Main.eab0bcee34c43f4b", scope: null, file: !134, line: 24, type: !9, spFlags: DISPFlagDefinition, unit: !135, retainedNodes: !202)
// CHECK:STDOUT: !197 = !DILocalVariable(arg: 1, scope: !196, type: !7)
// CHECK:STDOUT: !201 = !DILocation(line: 24, column: 40, scope: !196)
// CHECK:STDOUT: !202 = !{!197}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'requirement_typeof.carbon'
// CHECK:STDOUT: source_filename = "requirement_typeof.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @array.199.loc41_3.1 = internal constant [0 x {}] zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CN.C.Main() #0 !dbg !221 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !224
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF.59ea7ce8a2779236:Z.Main"() #0 !dbg !225 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 9, !dbg !228
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CPointer.Main(ptr %p) #0 !dbg !229 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 3, !dbg !234
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CWrapped.Main(ptr %w) #0 !dbg !236 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !239
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUpstream.Main() #0 !dbg !241 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !243
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CSatisfied.Main() #0 !dbg !244 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !248
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !249 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CUpstream.Main(), !dbg !252
// CHECK:STDOUT:   %HasN.WithSelf.N.requirement.type.as.Z.impl.F.call = call i32 @"_CF.59ea7ce8a2779236:Z.Main"(), !dbg !253
// CHECK:STDOUT:   %Generic.call = call i32 @_CGeneric.Main.084a2801e0f5d754({} zeroinitializer), !dbg !254
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc51_33 = add i32 %HasN.WithSelf.N.requirement.type.as.Z.impl.F.call, %Generic.call, !dbg !253
// CHECK:STDOUT:   %Satisfied.call = call i32 @_CSatisfied.Main(), !dbg !255
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc51_46 = add i32 %Int.as.AddWith.impl.Op.call.loc51_33, %Satisfied.call, !dbg !253
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call.loc51_46, !dbg !256
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.bb9ac398e22f0ba9:core.Destroy.Core"(ptr %self) #0 !dbg !257 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !259
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGeneric.Main.084a2801e0f5d754({} %x) #0 !dbg !261 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.var = alloca [0 x {}], align 1, !dbg !266
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a.var), !dbg !266
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %a.var, ptr align 1 @array.199.loc41_3.1, i64 0, i1 false), !dbg !266
// CHECK:STDOUT:   call void @"_CSelfDestruct.bb9ac398e22f0ba9:core.Destroy.Core"(ptr %a.var), !dbg !266
// CHECK:STDOUT:   ret i32 4, !dbg !268
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!218}
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
// CHECK:STDOUT: !217 = !DIFile(filename: "requirement_typeof.carbon", directory: "")
// CHECK:STDOUT: !218 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !217, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !219 = !{null}
// CHECK:STDOUT: !220 = !DISubroutineType(types: !219)
// CHECK:STDOUT: !221 = distinct !DISubprogram(name: "N", linkageName: "_CN.C.Main", scope: null, file: !217, line: 25, type: !11, spFlags: DISPFlagDefinition, unit: !218)
// CHECK:STDOUT: !224 = !DILocation(line: 25, column: 19, scope: !221)
// CHECK:STDOUT: !225 = distinct !DISubprogram(name: "F", linkageName: "_CF.59ea7ce8a2779236:Z.Main", scope: null, file: !217, line: 33, type: !11, spFlags: DISPFlagDefinition, unit: !218)
// CHECK:STDOUT: !228 = !DILocation(line: 33, column: 19, scope: !225)
// CHECK:STDOUT: !229 = distinct !DISubprogram(name: "Pointer", linkageName: "_CPointer.Main", scope: null, file: !217, line: 36, type: !9, spFlags: DISPFlagDefinition, unit: !218, retainedNodes: !235)
// CHECK:STDOUT: !230 = !DILocalVariable(arg: 1, scope: !229, type: !7)
// CHECK:STDOUT: !234 = !DILocation(line: 36, column: 48, scope: !229)
// CHECK:STDOUT: !235 = !{!230}
// CHECK:STDOUT: !236 = distinct !DISubprogram(name: "Wrapped", linkageName: "_CWrapped.Main", scope: null, file: !217, line: 38, type: !13, spFlags: DISPFlagDefinition, unit: !218, retainedNodes: !240)
// CHECK:STDOUT: !237 = !DILocalVariable(arg: 1, scope: !236, type: !7)
// CHECK:STDOUT: !239 = !DILocation(line: 38, column: 1, scope: !236)
// CHECK:STDOUT: !240 = !{!237}
// CHECK:STDOUT: !241 = distinct !DISubprogram(name: "Upstream", linkageName: "_CUpstream.Main", scope: null, file: !217, line: 45, type: !220, spFlags: DISPFlagDefinition, unit: !218)
// CHECK:STDOUT: !243 = !DILocation(line: 45, column: 1, scope: !241)
// CHECK:STDOUT: !244 = distinct !DISubprogram(name: "Satisfied", linkageName: "_CSatisfied.Main", scope: null, file: !217, line: 47, type: !11, spFlags: DISPFlagDefinition, unit: !218)
// CHECK:STDOUT: !248 = !DILocation(line: 47, column: 53, scope: !244)
// CHECK:STDOUT: !249 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !217, line: 49, type: !11, spFlags: DISPFlagDefinition, unit: !218)
// CHECK:STDOUT: !252 = !DILocation(line: 50, column: 3, scope: !249)
// CHECK:STDOUT: !253 = !DILocation(line: 51, column: 10, scope: !249)
// CHECK:STDOUT: !254 = !DILocation(line: 51, column: 35, scope: !249)
// CHECK:STDOUT: !255 = !DILocation(line: 51, column: 48, scope: !249)
// CHECK:STDOUT: !256 = !DILocation(line: 51, column: 3, scope: !249)
// CHECK:STDOUT: !257 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.bb9ac398e22f0ba9:core.Destroy.Core", scope: null, file: !217, line: 41, type: !13, spFlags: DISPFlagDefinition, unit: !218, retainedNodes: !260)
// CHECK:STDOUT: !258 = !DILocalVariable(arg: 1, scope: !257, type: !7)
// CHECK:STDOUT: !259 = !DILocation(line: 41, column: 3, scope: !257)
// CHECK:STDOUT: !260 = !{!258}
// CHECK:STDOUT: !261 = distinct !DISubprogram(name: "Generic", linkageName: "_CGeneric.Main.084a2801e0f5d754", scope: null, file: !217, line: 40, type: !9, spFlags: DISPFlagDefinition, unit: !218, retainedNodes: !269)
// CHECK:STDOUT: !262 = !DILocalVariable(arg: 1, scope: !261, type: !7)
// CHECK:STDOUT: !266 = !DILocation(line: 41, column: 3, scope: !261)
// CHECK:STDOUT: !268 = !DILocation(line: 42, column: 3, scope: !261)
// CHECK:STDOUT: !269 = !{!262}
// CHECK:STDOUT:

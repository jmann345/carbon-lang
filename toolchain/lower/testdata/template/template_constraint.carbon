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

// --- requirement_typeof_object.carbon
library "[[@TEST_NAME]]";

// An object whose type is or holds a requirement's type: a class field, an
// element of a tuple, struct or array field, a generic class's field. It is
// destroyed by binding its synthesized `Destroy.Op`'s `ref self` to each
// element, which reads no value, so it is not refused (D-SC-20 as amended at
// fill round 6, both reviews' finding MAJOR-1: each use of `W` was refused with
// a dozen copies of `StructuralRequirementUsed`). A `ref` parameter, a `ref
// self` method, a discarded reference and the compound access `C.(w.f)` bind
// or name such an object the same way; reading it as a value is refused
// (requirement-call `fail_requirement_typeof_value`). A value typed by a type
// parameter bound to the requirement's type is an empty value, accepted in a
// checked generic and in a template (`Pass`, `LetValue`; review 1 finding
// MINOR-1).
template constraint HasN {
  fn N() -> i32;
}

template constraint Has(X: type) {
  fn N() -> X;
}

interface Z {
  fn M(ref self) -> i32;
}

impl typeof(HasN.N) as Z {
  fn M(unused ref self) -> i32 { return 4; }
}

class C {
  fn N() -> i32 { return 5; }
}

class W {
  var f: typeof(HasN.N);
  var t: (typeof(HasN.N), i32);
  var s: {.f: typeof(Has(i32).N), .x: i32};
  var a: array(typeof(HasN.N), 2);
  var x: i32;
}

impl W as Core.UnformedInit {}

class Box(T: type) {
  var v: T;
  var k: i32;
}

impl forall [T: type] Box(T) as Core.UnformedInit {}

fn MakeW() -> W {
  returned var w: W;
  w.x = 3;
  return var;
}

fn D[T: Core.Destroy](unused p: T*) -> i32 { return 1; }

fn Ref(unused ref f: typeof(HasN.N)) -> i32 { return 2; }

fn Take[T: type](unused f: T) -> i32 { return 1; }

fn Pass[T: type](p: T*) -> i32 { return Take(*p); }

fn LetValue[template T: type](p: T*) {
  let unused v: T = *p;
}

fn Run() -> i32 {
  var w: W;
  w.x = 3;
  w.f;
  MakeW();
  var b: Box(typeof(HasN.N));
  b.k = MakeW().x;
  LetValue(&w.f);
  return w.x + b.k + D(&w) + Ref(ref w.f) + w.f.(Z.M)() + w.t.0.(Z.M)() +
         Pass(&w.f) + C.(w.f)();
}

// --- require_self_argument.carbon
library "[[@TEST_NAME]]";

// A `require` whose facet type takes `Self` as an argument, accepted since fill
// round 7's checked-phase `Self`, adds nothing to lowering: the calls are to
// the type's own methods and to its impl's (D-SC-10 as amended at fill round 8,
// round 7's review 2 finding MAJOR-2; the check split of the same name in
// named_constraint/template_constraint_require.carbon).
interface Conv(T: type) {
  fn Do(self) -> T;
}

template constraint Has(X: type) {
  fn Get(self) -> X;
}

template constraint ConvSelf {
  require Self impls Conv(Self);
  fn V(self) -> i32;
}

template constraint HasSelf {
  require impls Has(Self);
  fn V(self) -> i32;
}

class C {
  var v: i32;
  fn Get(self) -> C { return {.v = self.v + 1}; }
  fn V(self) -> i32 { return self.v; }
}

impl C as Conv(C) {
  fn Do(self) -> C { return {.v = self.v + 2}; }
}

fn CallDo[template T: ConvSelf](x: T) -> i32 { return x.(Conv(T).Do)().V(); }

fn CallGet[template T: HasSelf](x: T) -> i32 { return x.Get().V(); }

fn Run() -> i32 {
  let c: C = {.v = 1};
  return CallDo(c) + CallGet(c);
}

// --- overload_probe_require.carbon
library "[[@TEST_NAME]]";

// A member of an overload set constrained by a template constraint whose
// requirement signature names `Box(Self)`, with `require impls J`, is probed
// without diagnostics: `C` selects it and `D`, which does not implement `J`,
// selects the next member, so `Run` returns 10 * 2 + 20 - 40 = 0, where the
// swapped selection would return 20 * 2 + 10 - 40 = 10 (D-SC-12; fill round 9,
// round 8's review 1 finding MINOR-2; asymmetric since fill round 10, round 9's
// review 1 finding MINOR-4; the check split `self_facet_in_signature_required`
// in named_constraint/template_constraint.carbon).
interface J {
  fn K(self) -> i32;
}

class Box(T: J) {
  var k: i32;
}

template constraint HasWrap {
  require impls J;
  fn Wrap(self) -> Box(Self);
  fn V(self) -> i32;
}

class C {
  var v: i32;
  impl as J {
    fn K(self) -> i32 { return self.v; }
  }
  fn Wrap(self) -> Box(C) { return {.k = self.v}; }
  fn V(self) -> i32 { return self.v; }
}

class D {
  var v: i32;
  fn Wrap(self) -> i32 { return self.v; }
  fn V(self) -> i32 { return self.v; }
}

overload fn P[template T: HasWrap](unused x: T) -> i32 { return 10; }
overload fn P[T: type](unused x: T) -> i32 { return 20; }

fn Run() -> i32 {
  let c: C = {.v = 3};
  let d: D = {.v = 3};
  return P(c) * 2 + P(d) - 40;
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
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'requirement_typeof_object.carbon'
// CHECK:STDOUT: source_filename = "requirement_typeof_object.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CM.59ea7ce8a2779236:Z.Main"(ptr %self) #0 !dbg !276 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 4, !dbg !281
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CN.C.Main() #0 !dbg !283 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 5, !dbg !286
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeW.Main(ptr sret({ {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }) %return) #0 !dbg !287 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc54_4.x = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %return, i32 0, i32 4, !dbg !293
// CHECK:STDOUT:   store i32 3, ptr %.loc54_4.x, align 4, !dbg !293
// CHECK:STDOUT:   ret void, !dbg !294
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CRef.Main(ptr %f) #0 !dbg !295 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !300
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !302 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %w.var = alloca { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, align 4, !dbg !305
// CHECK:STDOUT:   %.loc74_9.1.temp = alloca { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, align 4, !dbg !309
// CHECK:STDOUT:   %b.var = alloca { {}, i32 }, align 4, !dbg !310
// CHECK:STDOUT:   %.loc76_15.1.temp = alloca { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, align 4, !dbg !313
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %w.var), !dbg !305
// CHECK:STDOUT:   %.loc72_4.x = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %w.var, i32 0, i32 4, !dbg !307
// CHECK:STDOUT:   store i32 3, ptr %.loc72_4.x, align 4, !dbg !307
// CHECK:STDOUT:   %.loc73.f = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %w.var, i32 0, i32 0, !dbg !308
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc74_9.1.temp), !dbg !309
// CHECK:STDOUT:   call void @_CMakeW.Main(ptr %.loc74_9.1.temp), !dbg !309
// CHECK:STDOUT:   call void @"_CSelfDestruct.6d881cddc537b10e:core.Destroy.Core"(ptr %.loc74_9.1.temp), !dbg !309
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !310
// CHECK:STDOUT:   %.loc76_4.k = getelementptr inbounds nuw { {}, i32 }, ptr %b.var, i32 0, i32 1, !dbg !312
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc76_15.1.temp), !dbg !313
// CHECK:STDOUT:   call void @_CMakeW.Main(ptr %.loc76_15.1.temp), !dbg !313
// CHECK:STDOUT:   %.loc76_16.1.x = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %.loc76_15.1.temp, i32 0, i32 4, !dbg !313
// CHECK:STDOUT:   %.loc76_16.2 = load i32, ptr %.loc76_16.1.x, align 4, !dbg !313
// CHECK:STDOUT:   store i32 %.loc76_16.2, ptr %.loc76_4.k, align 4, !dbg !312
// CHECK:STDOUT:   call void @"_CSelfDestruct.6d881cddc537b10e:core.Destroy.Core"(ptr %.loc76_15.1.temp), !dbg !313
// CHECK:STDOUT:   %.loc77.f = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %w.var, i32 0, i32 0, !dbg !314
// CHECK:STDOUT:   call void @_CLetValue.Main.872926826cba281b(ptr %.loc77.f), !dbg !316
// CHECK:STDOUT:   %.loc78_11.1.x = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %w.var, i32 0, i32 4, !dbg !317
// CHECK:STDOUT:   %.loc78_17.1.k = getelementptr inbounds nuw { {}, i32 }, ptr %b.var, i32 0, i32 1, !dbg !318
// CHECK:STDOUT:   %.loc78_11.2 = load i32, ptr %.loc78_11.1.x, align 4, !dbg !317
// CHECK:STDOUT:   %.loc78_17.2 = load i32, ptr %.loc78_17.1.k, align 4, !dbg !318
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc78_14 = add i32 %.loc78_11.2, %.loc78_17.2, !dbg !317
// CHECK:STDOUT:   %D.call = call i32 @_CD.Main.7e71be57df841073(ptr %w.var), !dbg !321
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc78_20 = add i32 %Int.as.AddWith.impl.Op.call.loc78_14, %D.call, !dbg !317
// CHECK:STDOUT:   %.loc78_39.f = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %w.var, i32 0, i32 0, !dbg !322
// CHECK:STDOUT:   %Ref.call = call i32 @_CRef.Main(ptr %.loc78_39.f), !dbg !324
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc78_28 = add i32 %Int.as.AddWith.impl.Op.call.loc78_20, %Ref.call, !dbg !317
// CHECK:STDOUT:   %.loc78_46.f = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %w.var, i32 0, i32 0, !dbg !325
// CHECK:STDOUT:   %HasN.WithSelf.N.requirement.type.as.Z.impl.M.call.loc78_55 = call i32 @"_CM.59ea7ce8a2779236:Z.Main"(ptr %.loc78_46.f), !dbg !325
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc78_43 = add i32 %Int.as.AddWith.impl.Op.call.loc78_28, %HasN.WithSelf.N.requirement.type.as.Z.impl.M.call.loc78_55, !dbg !317
// CHECK:STDOUT:   %.loc78_60.t = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %w.var, i32 0, i32 1, !dbg !326
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { {}, i32 }, ptr %.loc78_60.t, i32 0, i32 0, !dbg !326
// CHECK:STDOUT:   %HasN.WithSelf.N.requirement.type.as.Z.impl.M.call.loc78_71 = call i32 @"_CM.59ea7ce8a2779236:Z.Main"(ptr %tuple.elem0.tuple.elem), !dbg !326
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc78_57 = add i32 %Int.as.AddWith.impl.Op.call.loc78_43, %HasN.WithSelf.N.requirement.type.as.Z.impl.M.call.loc78_71, !dbg !317
// CHECK:STDOUT:   %.loc79_17.f = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %w.var, i32 0, i32 0, !dbg !327
// CHECK:STDOUT:   %Pass.call = call i32 @_CPass.Main.872926826cba281b(ptr %.loc79_17.f), !dbg !329
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc78_73 = add i32 %Int.as.AddWith.impl.Op.call.loc78_57, %Pass.call, !dbg !317
// CHECK:STDOUT:   %.loc79_27.f = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %w.var, i32 0, i32 0, !dbg !330
// CHECK:STDOUT:   %C.N.call = call i32 @_CN.C.Main(), !dbg !331
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc79 = add i32 %Int.as.AddWith.impl.Op.call.loc78_73, %C.N.call, !dbg !317
// CHECK:STDOUT:   call void @"_CSelfDestruct.9e6fabd72fd42f58:core.Destroy.Core"(ptr %b.var), !dbg !310
// CHECK:STDOUT:   call void @"_CSelfDestruct.6d881cddc537b10e:core.Destroy.Core"(ptr %w.var), !dbg !305
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call.loc79, !dbg !332
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.59ea7ce8a2779236:core.Destroy.Core"(ptr %self) #0 !dbg !333 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !335
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !337 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !339
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.16e8bc600c0f50dd:core.Destroy.Core"(ptr %self) #0 !dbg !341 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { {}, i32 }, ptr %self, i32 0, i32 1, !dbg !343
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !343
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { {}, i32 }, ptr %self, i32 0, i32 0, !dbg !343
// CHECK:STDOUT:   call void @"_CSelfDestruct.59ea7ce8a2779236:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !343
// CHECK:STDOUT:   ret void, !dbg !343
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.16e8bc600c0f50dd:core.Destroy.Core"(ptr %self) #0 !dbg !345 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.16e8bc600c0f50dd:core.Destroy.Core"(ptr %self), !dbg !347
// CHECK:STDOUT:   ret void, !dbg !347
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.3cdd22f3e746a6c5:core.Destroy.Core"(ptr %self) #0 !dbg !349 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !351
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.2e19025fb88c1158:core.Destroy.Core"(ptr %self) #0 !dbg !353 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc74_9.1.x = getelementptr inbounds nuw { {}, i32 }, ptr %self, i32 0, i32 1, !dbg !355
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc74_9.1.x), !dbg !355
// CHECK:STDOUT:   %.loc74_9.2.f = getelementptr inbounds nuw { {}, i32 }, ptr %self, i32 0, i32 0, !dbg !355
// CHECK:STDOUT:   call void @"_CSelfDestruct.3cdd22f3e746a6c5:core.Destroy.Core"(ptr %.loc74_9.2.f), !dbg !355
// CHECK:STDOUT:   ret void, !dbg !355
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.2e19025fb88c1158:core.Destroy.Core"(ptr %self) #0 !dbg !357 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.2e19025fb88c1158:core.Destroy.Core"(ptr %self), !dbg !359
// CHECK:STDOUT:   ret void, !dbg !359
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.153848eb63135ac5:core.Destroy.Core"(ptr %self) #0 !dbg !361 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !363
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.41c73cc8ea6e45a6:core.Destroy.Core"(ptr %self) #0 !dbg !365 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc74_9.1.x = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %self, i32 0, i32 4, !dbg !367
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc74_9.1.x), !dbg !367
// CHECK:STDOUT:   %.loc74_9.2.a = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %self, i32 0, i32 3, !dbg !367
// CHECK:STDOUT:   call void @"_CSelfDestruct.153848eb63135ac5:core.Destroy.Core"(ptr %.loc74_9.2.a), !dbg !367
// CHECK:STDOUT:   %.loc74_9.3.s = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %self, i32 0, i32 2, !dbg !367
// CHECK:STDOUT:   call void @"_CSelfDestruct.2e19025fb88c1158:core.Destroy.Core"(ptr %.loc74_9.3.s), !dbg !367
// CHECK:STDOUT:   %.loc74_9.4.t = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %self, i32 0, i32 1, !dbg !367
// CHECK:STDOUT:   call void @"_CSelfDestruct.16e8bc600c0f50dd:core.Destroy.Core"(ptr %.loc74_9.4.t), !dbg !367
// CHECK:STDOUT:   %.loc74_9.5.f = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %self, i32 0, i32 0, !dbg !367
// CHECK:STDOUT:   call void @"_CSelfDestruct.59ea7ce8a2779236:core.Destroy.Core"(ptr %.loc74_9.5.f), !dbg !367
// CHECK:STDOUT:   ret void, !dbg !367
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.41c73cc8ea6e45a6:core.Destroy.Core"(ptr %self) #0 !dbg !369 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.41c73cc8ea6e45a6:core.Destroy.Core"(ptr %self), !dbg !371
// CHECK:STDOUT:   ret void, !dbg !371
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.6d881cddc537b10e:core.Destroy.Core"(ptr %self) #0 !dbg !373 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc74_9.1.x = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %self, i32 0, i32 4, !dbg !375
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc74_9.1.x), !dbg !375
// CHECK:STDOUT:   %.loc74_9.2.a = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %self, i32 0, i32 3, !dbg !375
// CHECK:STDOUT:   call void @"_CSelfDestruct.153848eb63135ac5:core.Destroy.Core"(ptr %.loc74_9.2.a), !dbg !375
// CHECK:STDOUT:   %.loc74_9.3.s = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %self, i32 0, i32 2, !dbg !375
// CHECK:STDOUT:   call void @"_CSelfDestruct.2e19025fb88c1158:core.Destroy.Core"(ptr %.loc74_9.3.s), !dbg !375
// CHECK:STDOUT:   %.loc74_9.4.t = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %self, i32 0, i32 1, !dbg !375
// CHECK:STDOUT:   call void @"_CSelfDestruct.16e8bc600c0f50dd:core.Destroy.Core"(ptr %.loc74_9.4.t), !dbg !375
// CHECK:STDOUT:   %.loc74_9.5.f = getelementptr inbounds nuw { {}, { {}, i32 }, { {}, i32 }, [2 x {}], i32 }, ptr %self, i32 0, i32 0, !dbg !375
// CHECK:STDOUT:   call void @"_CSelfDestruct.59ea7ce8a2779236:core.Destroy.Core"(ptr %.loc74_9.5.f), !dbg !375
// CHECK:STDOUT:   ret void, !dbg !375
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.6d881cddc537b10e:core.Destroy.Core"(ptr %self) #0 !dbg !377 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.6d881cddc537b10e:core.Destroy.Core"(ptr %self), !dbg !379
// CHECK:STDOUT:   ret void, !dbg !379
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.0d425a7548a17174:core.Destroy.Core"(ptr %self) #0 !dbg !381 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc75_3.1.k = getelementptr inbounds nuw { {}, i32 }, ptr %self, i32 0, i32 1, !dbg !383
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc75_3.1.k), !dbg !383
// CHECK:STDOUT:   %.loc75_3.2.v = getelementptr inbounds nuw { {}, i32 }, ptr %self, i32 0, i32 0, !dbg !383
// CHECK:STDOUT:   call void @"_CSelfDestruct.59ea7ce8a2779236:core.Destroy.Core"(ptr %.loc75_3.2.v), !dbg !383
// CHECK:STDOUT:   ret void, !dbg !383
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0d425a7548a17174:core.Destroy.Core"(ptr %self) #0 !dbg !385 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.0d425a7548a17174:core.Destroy.Core"(ptr %self), !dbg !387
// CHECK:STDOUT:   ret void, !dbg !387
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.9e6fabd72fd42f58:core.Destroy.Core"(ptr %self) #0 !dbg !389 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc75_3.1.k = getelementptr inbounds nuw { {}, i32 }, ptr %self, i32 0, i32 1, !dbg !391
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc75_3.1.k), !dbg !391
// CHECK:STDOUT:   %.loc75_3.2.v = getelementptr inbounds nuw { {}, i32 }, ptr %self, i32 0, i32 0, !dbg !391
// CHECK:STDOUT:   call void @"_CSelfDestruct.59ea7ce8a2779236:core.Destroy.Core"(ptr %.loc75_3.2.v), !dbg !391
// CHECK:STDOUT:   ret void, !dbg !391
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.9e6fabd72fd42f58:core.Destroy.Core"(ptr %self) #0 !dbg !393 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.9e6fabd72fd42f58:core.Destroy.Core"(ptr %self), !dbg !395
// CHECK:STDOUT:   ret void, !dbg !395
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CLetValue.Main.872926826cba281b(ptr %p) #0 !dbg !397 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !404
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CD.Main.7e71be57df841073(ptr %p) #0 !dbg !406 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !411
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CPass.Main.872926826cba281b(ptr %p) #0 !dbg !413 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Take.call = call i32 @_CTake.Main.872926826cba281b(), !dbg !420
// CHECK:STDOUT:   ret i32 %Take.call, !dbg !421
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CTake.Main.872926826cba281b() #0 !dbg !423 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !427
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.6d881cddc537b10e:core.Destroy.Core", { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 3, 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!271}
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
// CHECK:STDOUT: !270 = !DIFile(filename: "requirement_typeof_object.carbon", directory: "")
// CHECK:STDOUT: !271 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !270, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !272 = !{!7}
// CHECK:STDOUT: !273 = !DISubroutineType(types: !272)
// CHECK:STDOUT: !274 = !{null, !6}
// CHECK:STDOUT: !275 = !DISubroutineType(types: !274)
// CHECK:STDOUT: !276 = distinct !DISubprogram(name: "M", linkageName: "_CM.59ea7ce8a2779236:Z.Main", scope: null, file: !270, line: 28, type: !9, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !282)
// CHECK:STDOUT: !277 = !DILocalVariable(arg: 1, scope: !276, type: !7)
// CHECK:STDOUT: !281 = !DILocation(line: 28, column: 34, scope: !276)
// CHECK:STDOUT: !282 = !{!277}
// CHECK:STDOUT: !283 = distinct !DISubprogram(name: "N", linkageName: "_CN.C.Main", scope: null, file: !270, line: 32, type: !11, spFlags: DISPFlagDefinition, unit: !271)
// CHECK:STDOUT: !286 = !DILocation(line: 32, column: 19, scope: !283)
// CHECK:STDOUT: !287 = distinct !DISubprogram(name: "MakeW", linkageName: "_CMakeW.Main", scope: null, file: !270, line: 52, type: !273, spFlags: DISPFlagDefinition, unit: !271)
// CHECK:STDOUT: !293 = !DILocation(line: 54, column: 3, scope: !287)
// CHECK:STDOUT: !294 = !DILocation(line: 55, column: 3, scope: !287)
// CHECK:STDOUT: !295 = distinct !DISubprogram(name: "Ref", linkageName: "_CRef.Main", scope: null, file: !270, line: 60, type: !9, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !301)
// CHECK:STDOUT: !296 = !DILocalVariable(arg: 1, scope: !295, type: !7)
// CHECK:STDOUT: !300 = !DILocation(line: 60, column: 47, scope: !295)
// CHECK:STDOUT: !301 = !{!296}
// CHECK:STDOUT: !302 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !270, line: 70, type: !11, spFlags: DISPFlagDefinition, unit: !271)
// CHECK:STDOUT: !305 = !DILocation(line: 71, column: 3, scope: !302)
// CHECK:STDOUT: !307 = !DILocation(line: 72, column: 3, scope: !302)
// CHECK:STDOUT: !308 = !DILocation(line: 73, column: 3, scope: !302)
// CHECK:STDOUT: !309 = !DILocation(line: 74, column: 3, scope: !302)
// CHECK:STDOUT: !310 = !DILocation(line: 75, column: 3, scope: !302)
// CHECK:STDOUT: !312 = !DILocation(line: 76, column: 3, scope: !302)
// CHECK:STDOUT: !313 = !DILocation(line: 76, column: 9, scope: !302)
// CHECK:STDOUT: !314 = !DILocation(line: 77, column: 13, scope: !302)
// CHECK:STDOUT: !316 = !DILocation(line: 77, column: 3, scope: !302)
// CHECK:STDOUT: !317 = !DILocation(line: 78, column: 10, scope: !302)
// CHECK:STDOUT: !318 = !DILocation(line: 78, column: 16, scope: !302)
// CHECK:STDOUT: !321 = !DILocation(line: 78, column: 22, scope: !302)
// CHECK:STDOUT: !322 = !DILocation(line: 78, column: 38, scope: !302)
// CHECK:STDOUT: !324 = !DILocation(line: 78, column: 30, scope: !302)
// CHECK:STDOUT: !325 = !DILocation(line: 78, column: 45, scope: !302)
// CHECK:STDOUT: !326 = !DILocation(line: 78, column: 59, scope: !302)
// CHECK:STDOUT: !327 = !DILocation(line: 79, column: 16, scope: !302)
// CHECK:STDOUT: !329 = !DILocation(line: 79, column: 10, scope: !302)
// CHECK:STDOUT: !330 = !DILocation(line: 79, column: 26, scope: !302)
// CHECK:STDOUT: !331 = !DILocation(line: 79, column: 23, scope: !302)
// CHECK:STDOUT: !332 = !DILocation(line: 78, column: 3, scope: !302)
// CHECK:STDOUT: !333 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.59ea7ce8a2779236:core.Destroy.Core", scope: null, file: !270, line: 74, type: !13, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !336)
// CHECK:STDOUT: !334 = !DILocalVariable(arg: 1, scope: !333, type: !7)
// CHECK:STDOUT: !335 = !DILocation(line: 74, column: 3, scope: !333)
// CHECK:STDOUT: !336 = !{!334}
// CHECK:STDOUT: !337 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !270, line: 74, type: !275, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !340)
// CHECK:STDOUT: !338 = !DILocalVariable(arg: 1, scope: !337, type: !6)
// CHECK:STDOUT: !339 = !DILocation(line: 74, column: 3, scope: !337)
// CHECK:STDOUT: !340 = !{!338}
// CHECK:STDOUT: !341 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.16e8bc600c0f50dd:core.Destroy.Core", scope: null, file: !270, line: 74, type: !13, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !344)
// CHECK:STDOUT: !342 = !DILocalVariable(arg: 1, scope: !341, type: !7)
// CHECK:STDOUT: !343 = !DILocation(line: 74, column: 3, scope: !341)
// CHECK:STDOUT: !344 = !{!342}
// CHECK:STDOUT: !345 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.16e8bc600c0f50dd:core.Destroy.Core", scope: null, file: !270, line: 74, type: !13, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !348)
// CHECK:STDOUT: !346 = !DILocalVariable(arg: 1, scope: !345, type: !7)
// CHECK:STDOUT: !347 = !DILocation(line: 74, column: 3, scope: !345)
// CHECK:STDOUT: !348 = !{!346}
// CHECK:STDOUT: !349 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.3cdd22f3e746a6c5:core.Destroy.Core", scope: null, file: !270, line: 74, type: !13, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !352)
// CHECK:STDOUT: !350 = !DILocalVariable(arg: 1, scope: !349, type: !7)
// CHECK:STDOUT: !351 = !DILocation(line: 74, column: 3, scope: !349)
// CHECK:STDOUT: !352 = !{!350}
// CHECK:STDOUT: !353 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.2e19025fb88c1158:core.Destroy.Core", scope: null, file: !270, line: 74, type: !13, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !356)
// CHECK:STDOUT: !354 = !DILocalVariable(arg: 1, scope: !353, type: !7)
// CHECK:STDOUT: !355 = !DILocation(line: 74, column: 3, scope: !353)
// CHECK:STDOUT: !356 = !{!354}
// CHECK:STDOUT: !357 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.2e19025fb88c1158:core.Destroy.Core", scope: null, file: !270, line: 74, type: !13, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !360)
// CHECK:STDOUT: !358 = !DILocalVariable(arg: 1, scope: !357, type: !7)
// CHECK:STDOUT: !359 = !DILocation(line: 74, column: 3, scope: !357)
// CHECK:STDOUT: !360 = !{!358}
// CHECK:STDOUT: !361 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.153848eb63135ac5:core.Destroy.Core", scope: null, file: !270, line: 74, type: !13, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !364)
// CHECK:STDOUT: !362 = !DILocalVariable(arg: 1, scope: !361, type: !7)
// CHECK:STDOUT: !363 = !DILocation(line: 74, column: 3, scope: !361)
// CHECK:STDOUT: !364 = !{!362}
// CHECK:STDOUT: !365 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.41c73cc8ea6e45a6:core.Destroy.Core", scope: null, file: !270, line: 74, type: !13, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !368)
// CHECK:STDOUT: !366 = !DILocalVariable(arg: 1, scope: !365, type: !7)
// CHECK:STDOUT: !367 = !DILocation(line: 74, column: 3, scope: !365)
// CHECK:STDOUT: !368 = !{!366}
// CHECK:STDOUT: !369 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.41c73cc8ea6e45a6:core.Destroy.Core", scope: null, file: !270, line: 74, type: !13, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !372)
// CHECK:STDOUT: !370 = !DILocalVariable(arg: 1, scope: !369, type: !7)
// CHECK:STDOUT: !371 = !DILocation(line: 74, column: 3, scope: !369)
// CHECK:STDOUT: !372 = !{!370}
// CHECK:STDOUT: !373 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.6d881cddc537b10e:core.Destroy.Core", scope: null, file: !270, line: 74, type: !13, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !376)
// CHECK:STDOUT: !374 = !DILocalVariable(arg: 1, scope: !373, type: !7)
// CHECK:STDOUT: !375 = !DILocation(line: 74, column: 3, scope: !373)
// CHECK:STDOUT: !376 = !{!374}
// CHECK:STDOUT: !377 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.6d881cddc537b10e:core.Destroy.Core", scope: null, file: !270, line: 74, type: !13, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !380)
// CHECK:STDOUT: !378 = !DILocalVariable(arg: 1, scope: !377, type: !7)
// CHECK:STDOUT: !379 = !DILocation(line: 74, column: 3, scope: !377)
// CHECK:STDOUT: !380 = !{!378}
// CHECK:STDOUT: !381 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.0d425a7548a17174:core.Destroy.Core", scope: null, file: !270, line: 75, type: !13, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !384)
// CHECK:STDOUT: !382 = !DILocalVariable(arg: 1, scope: !381, type: !7)
// CHECK:STDOUT: !383 = !DILocation(line: 75, column: 3, scope: !381)
// CHECK:STDOUT: !384 = !{!382}
// CHECK:STDOUT: !385 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0d425a7548a17174:core.Destroy.Core", scope: null, file: !270, line: 75, type: !13, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !388)
// CHECK:STDOUT: !386 = !DILocalVariable(arg: 1, scope: !385, type: !7)
// CHECK:STDOUT: !387 = !DILocation(line: 75, column: 3, scope: !385)
// CHECK:STDOUT: !388 = !{!386}
// CHECK:STDOUT: !389 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.9e6fabd72fd42f58:core.Destroy.Core", scope: null, file: !270, line: 75, type: !13, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !392)
// CHECK:STDOUT: !390 = !DILocalVariable(arg: 1, scope: !389, type: !7)
// CHECK:STDOUT: !391 = !DILocation(line: 75, column: 3, scope: !389)
// CHECK:STDOUT: !392 = !{!390}
// CHECK:STDOUT: !393 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.9e6fabd72fd42f58:core.Destroy.Core", scope: null, file: !270, line: 75, type: !13, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !396)
// CHECK:STDOUT: !394 = !DILocalVariable(arg: 1, scope: !393, type: !7)
// CHECK:STDOUT: !395 = !DILocation(line: 75, column: 3, scope: !393)
// CHECK:STDOUT: !396 = !{!394}
// CHECK:STDOUT: !397 = distinct !DISubprogram(name: "LetValue", linkageName: "_CLetValue.Main.872926826cba281b", scope: null, file: !270, line: 66, type: !13, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !405)
// CHECK:STDOUT: !398 = !DILocalVariable(arg: 1, scope: !397, type: !7)
// CHECK:STDOUT: !404 = !DILocation(line: 66, column: 1, scope: !397)
// CHECK:STDOUT: !405 = !{!398}
// CHECK:STDOUT: !406 = distinct !DISubprogram(name: "D", linkageName: "_CD.Main.7e71be57df841073", scope: null, file: !270, line: 58, type: !9, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !412)
// CHECK:STDOUT: !407 = !DILocalVariable(arg: 1, scope: !406, type: !7)
// CHECK:STDOUT: !411 = !DILocation(line: 58, column: 46, scope: !406)
// CHECK:STDOUT: !412 = !{!407}
// CHECK:STDOUT: !413 = distinct !DISubprogram(name: "Pass", linkageName: "_CPass.Main.872926826cba281b", scope: null, file: !270, line: 64, type: !9, spFlags: DISPFlagDefinition, unit: !271, retainedNodes: !422)
// CHECK:STDOUT: !414 = !DILocalVariable(arg: 1, scope: !413, type: !7)
// CHECK:STDOUT: !420 = !DILocation(line: 64, column: 41, scope: !413)
// CHECK:STDOUT: !421 = !DILocation(line: 64, column: 34, scope: !413)
// CHECK:STDOUT: !422 = !{!414}
// CHECK:STDOUT: !423 = distinct !DISubprogram(name: "Take", linkageName: "_CTake.Main.872926826cba281b", scope: null, file: !270, line: 62, type: !11, spFlags: DISPFlagDefinition, unit: !271)
// CHECK:STDOUT: !427 = !DILocation(line: 62, column: 40, scope: !423)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'require_self_argument.carbon'
// CHECK:STDOUT: source_filename = "require_self_argument.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @C.val = internal constant { i32 } { i32 1 }
// CHECK:STDOUT: @C.val.loc41_21.9 = internal constant { i32 } { i32 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CGet.C.Main(ptr sret({ i32 }) %return, ptr %self) #0 !dbg !432 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc28_40.1.v = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !437
// CHECK:STDOUT:   %.loc28_40.2 = load i32, ptr %.loc28_40.1.v, align 4, !dbg !437
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc28_40.2, 1, !dbg !437
// CHECK:STDOUT:   %.loc28_46.2.v = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !438
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %.loc28_46.2.v, align 4, !dbg !438
// CHECK:STDOUT:   ret void, !dbg !439
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CV.C.Main(ptr %self) #0 !dbg !441 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc29_34.1.v = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !446
// CHECK:STDOUT:   %.loc29_34.2 = load i32, ptr %.loc29_34.1.v, align 4, !dbg !446
// CHECK:STDOUT:   ret i32 %.loc29_34.2, !dbg !447
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CDo.C.Main:Conv.9522ff908e97e267.Main"(ptr sret({ i32 }) %return, ptr %self) #0 !dbg !449 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc33_39.1.v = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !454
// CHECK:STDOUT:   %.loc33_39.2 = load i32, ptr %.loc33_39.1.v, align 4, !dbg !454
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc33_39.2, 2, !dbg !454
// CHECK:STDOUT:   %.loc33_45.2.v = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !455
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %.loc33_45.2.v, align 4, !dbg !455
// CHECK:STDOUT:   ret void, !dbg !456
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !458 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc41_21.3.temp = alloca { i32 }, align 4, !dbg !461
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc41_21.3.temp), !dbg !461
// CHECK:STDOUT:   %.loc41_21.4.v = getelementptr inbounds nuw { i32 }, ptr %.loc41_21.3.temp, i32 0, i32 0, !dbg !461
// CHECK:STDOUT:   %CallDo.call = call i32 @_CCallDo.Main.7192bcf8d5bc8990(ptr @C.val.loc41_21.9), !dbg !465
// CHECK:STDOUT:   %CallGet.call = call i32 @_CCallGet.Main.2eb69dd0c58be63c(ptr @C.val.loc41_21.9), !dbg !467
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %CallDo.call, %CallGet.call, !dbg !465
// CHECK:STDOUT:   call void @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core"(ptr @C.val), !dbg !461
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !468
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !469 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !471
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.92afc3a45a31c789:core.Destroy.Core"(ptr %self) #0 !dbg !473 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc41.v = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !475
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc41.v), !dbg !475
// CHECK:STDOUT:   ret void, !dbg !475
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.92afc3a45a31c789:core.Destroy.Core"(ptr %self) #0 !dbg !477 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.92afc3a45a31c789:core.Destroy.Core"(ptr %self), !dbg !479
// CHECK:STDOUT:   ret void, !dbg !479
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.08d9e38b928ba575:core.Destroy.Core"(ptr %self) #0 !dbg !481 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc41.v = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !483
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc41.v), !dbg !483
// CHECK:STDOUT:   ret void, !dbg !483
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core"(ptr %self) #0 !dbg !485 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.08d9e38b928ba575:core.Destroy.Core"(ptr %self), !dbg !487
// CHECK:STDOUT:   ret void, !dbg !487
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CCallDo.Main.7192bcf8d5bc8990(ptr %x) #0 !dbg !489 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.29d69a.2.temp = alloca { i32 }, align 4, !dbg !494
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.29d69a.2.temp), !dbg !494
// CHECK:STDOUT:   call void @"_CDo.C.Main:Conv.9522ff908e97e267.Main"(ptr %.29d69a.2.temp, ptr %x), !dbg !494
// CHECK:STDOUT:   %C.V.call.69b = call i32 @_CV.C.Main(ptr %.29d69a.2.temp), !dbg !494
// CHECK:STDOUT:   ret i32 %C.V.call.69b, !dbg !495
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CCallGet.Main.2eb69dd0c58be63c(ptr %x) #0 !dbg !497 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.29d69a.1.temp = alloca { i32 }, align 4, !dbg !502
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.29d69a.1.temp), !dbg !502
// CHECK:STDOUT:   call void @_CGet.C.Main(ptr %.29d69a.1.temp, ptr %x), !dbg !502
// CHECK:STDOUT:   %C.V.call.52e = call i32 @_CV.C.Main(ptr %.29d69a.1.temp), !dbg !502
// CHECK:STDOUT:   ret i32 %C.V.call.52e, !dbg !503
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!429}
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
// CHECK:STDOUT: !274 = !{null, !6}
// CHECK:STDOUT: !275 = !DISubroutineType(types: !274)
// CHECK:STDOUT: !428 = !DIFile(filename: "require_self_argument.carbon", directory: "")
// CHECK:STDOUT: !429 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !428, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !430 = !{!7, !7}
// CHECK:STDOUT: !431 = !DISubroutineType(types: !430)
// CHECK:STDOUT: !432 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.C.Main", scope: null, file: !428, line: 28, type: !431, spFlags: DISPFlagDefinition, unit: !429, retainedNodes: !440)
// CHECK:STDOUT: !433 = !DILocalVariable(arg: 1, scope: !432, type: !7)
// CHECK:STDOUT: !437 = !DILocation(line: 28, column: 36, scope: !432)
// CHECK:STDOUT: !438 = !DILocation(line: 28, column: 30, scope: !432)
// CHECK:STDOUT: !439 = !DILocation(line: 28, column: 23, scope: !432)
// CHECK:STDOUT: !440 = !{!433}
// CHECK:STDOUT: !441 = distinct !DISubprogram(name: "V", linkageName: "_CV.C.Main", scope: null, file: !428, line: 29, type: !9, spFlags: DISPFlagDefinition, unit: !429, retainedNodes: !448)
// CHECK:STDOUT: !442 = !DILocalVariable(arg: 1, scope: !441, type: !7)
// CHECK:STDOUT: !446 = !DILocation(line: 29, column: 30, scope: !441)
// CHECK:STDOUT: !447 = !DILocation(line: 29, column: 23, scope: !441)
// CHECK:STDOUT: !448 = !{!442}
// CHECK:STDOUT: !449 = distinct !DISubprogram(name: "Do", linkageName: "_CDo.C.Main:Conv.9522ff908e97e267.Main", scope: null, file: !428, line: 33, type: !431, spFlags: DISPFlagDefinition, unit: !429, retainedNodes: !457)
// CHECK:STDOUT: !450 = !DILocalVariable(arg: 1, scope: !449, type: !7)
// CHECK:STDOUT: !454 = !DILocation(line: 33, column: 35, scope: !449)
// CHECK:STDOUT: !455 = !DILocation(line: 33, column: 29, scope: !449)
// CHECK:STDOUT: !456 = !DILocation(line: 33, column: 22, scope: !449)
// CHECK:STDOUT: !457 = !{!450}
// CHECK:STDOUT: !458 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !428, line: 40, type: !11, spFlags: DISPFlagDefinition, unit: !429)
// CHECK:STDOUT: !461 = !DILocation(line: 41, column: 14, scope: !458)
// CHECK:STDOUT: !465 = !DILocation(line: 42, column: 10, scope: !458)
// CHECK:STDOUT: !467 = !DILocation(line: 42, column: 22, scope: !458)
// CHECK:STDOUT: !468 = !DILocation(line: 42, column: 3, scope: !458)
// CHECK:STDOUT: !469 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !428, line: 41, type: !275, spFlags: DISPFlagDefinition, unit: !429, retainedNodes: !472)
// CHECK:STDOUT: !470 = !DILocalVariable(arg: 1, scope: !469, type: !6)
// CHECK:STDOUT: !471 = !DILocation(line: 41, column: 14, scope: !469)
// CHECK:STDOUT: !472 = !{!470}
// CHECK:STDOUT: !473 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.92afc3a45a31c789:core.Destroy.Core", scope: null, file: !428, line: 41, type: !13, spFlags: DISPFlagDefinition, unit: !429, retainedNodes: !476)
// CHECK:STDOUT: !474 = !DILocalVariable(arg: 1, scope: !473, type: !7)
// CHECK:STDOUT: !475 = !DILocation(line: 41, column: 14, scope: !473)
// CHECK:STDOUT: !476 = !{!474}
// CHECK:STDOUT: !477 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.92afc3a45a31c789:core.Destroy.Core", scope: null, file: !428, line: 41, type: !13, spFlags: DISPFlagDefinition, unit: !429, retainedNodes: !480)
// CHECK:STDOUT: !478 = !DILocalVariable(arg: 1, scope: !477, type: !7)
// CHECK:STDOUT: !479 = !DILocation(line: 41, column: 14, scope: !477)
// CHECK:STDOUT: !480 = !{!478}
// CHECK:STDOUT: !481 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.08d9e38b928ba575:core.Destroy.Core", scope: null, file: !428, line: 41, type: !13, spFlags: DISPFlagDefinition, unit: !429, retainedNodes: !484)
// CHECK:STDOUT: !482 = !DILocalVariable(arg: 1, scope: !481, type: !7)
// CHECK:STDOUT: !483 = !DILocation(line: 41, column: 14, scope: !481)
// CHECK:STDOUT: !484 = !{!482}
// CHECK:STDOUT: !485 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core", scope: null, file: !428, line: 41, type: !13, spFlags: DISPFlagDefinition, unit: !429, retainedNodes: !488)
// CHECK:STDOUT: !486 = !DILocalVariable(arg: 1, scope: !485, type: !7)
// CHECK:STDOUT: !487 = !DILocation(line: 41, column: 14, scope: !485)
// CHECK:STDOUT: !488 = !{!486}
// CHECK:STDOUT: !489 = distinct !DISubprogram(name: "CallDo", linkageName: "_CCallDo.Main.7192bcf8d5bc8990", scope: null, file: !428, line: 36, type: !9, spFlags: DISPFlagDefinition, unit: !429, retainedNodes: !496)
// CHECK:STDOUT: !490 = !DILocalVariable(arg: 1, scope: !489, type: !7)
// CHECK:STDOUT: !494 = !DILocation(line: 36, column: 55, scope: !489)
// CHECK:STDOUT: !495 = !DILocation(line: 36, column: 48, scope: !489)
// CHECK:STDOUT: !496 = !{!490}
// CHECK:STDOUT: !497 = distinct !DISubprogram(name: "CallGet", linkageName: "_CCallGet.Main.2eb69dd0c58be63c", scope: null, file: !428, line: 38, type: !9, spFlags: DISPFlagDefinition, unit: !429, retainedNodes: !504)
// CHECK:STDOUT: !498 = !DILocalVariable(arg: 1, scope: !497, type: !7)
// CHECK:STDOUT: !502 = !DILocation(line: 38, column: 55, scope: !497)
// CHECK:STDOUT: !503 = !DILocation(line: 38, column: 48, scope: !497)
// CHECK:STDOUT: !504 = !{!498}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'overload_probe_require.carbon'
// CHECK:STDOUT: source_filename = "overload_probe_require.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @C.val = internal constant { i32 } { i32 3 }
// CHECK:STDOUT: @D.val = internal constant { i32 } { i32 3 }
// CHECK:STDOUT: @C.val.loc44_21.9 = internal constant { i32 } { i32 3 }
// CHECK:STDOUT: @D.val.loc45_21.9 = internal constant { i32 } { i32 3 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CK.C.Main:J.Main"(ptr %self) #0 !dbg !507 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc28_36.1.v = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !512
// CHECK:STDOUT:   %.loc28_36.2 = load i32, ptr %.loc28_36.1.v, align 4, !dbg !512
// CHECK:STDOUT:   ret i32 %.loc28_36.2, !dbg !513
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CWrap.C.Main(ptr sret({ i32 }) %return, ptr %self) #0 !dbg !515 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc30_46.1.v = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !520
// CHECK:STDOUT:   %.loc30_46.2 = load i32, ptr %.loc30_46.1.v, align 4, !dbg !520
// CHECK:STDOUT:   %.loc30_48.2.k = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !521
// CHECK:STDOUT:   store i32 %.loc30_46.2, ptr %.loc30_48.2.k, align 4, !dbg !521
// CHECK:STDOUT:   ret void, !dbg !522
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CV.C.Main(ptr %self) #0 !dbg !524 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc31_34.1.v = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !529
// CHECK:STDOUT:   %.loc31_34.2 = load i32, ptr %.loc31_34.1.v, align 4, !dbg !529
// CHECK:STDOUT:   ret i32 %.loc31_34.2, !dbg !530
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CWrap.D.Main(ptr %self) #0 !dbg !532 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc36_37.1.v = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !537
// CHECK:STDOUT:   %.loc36_37.2 = load i32, ptr %.loc36_37.1.v, align 4, !dbg !537
// CHECK:STDOUT:   ret i32 %.loc36_37.2, !dbg !538
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CV.D.Main(ptr %self) #0 !dbg !540 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc37_34.1.v = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !545
// CHECK:STDOUT:   %.loc37_34.2 = load i32, ptr %.loc37_34.1.v, align 4, !dbg !545
// CHECK:STDOUT:   ret i32 %.loc37_34.2, !dbg !546
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !548 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc44_21.3.temp = alloca { i32 }, align 4, !dbg !551
// CHECK:STDOUT:   %.loc45_21.3.temp = alloca { i32 }, align 4, !dbg !554
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc44_21.3.temp), !dbg !551
// CHECK:STDOUT:   %.loc44_21.4.v = getelementptr inbounds nuw { i32 }, ptr %.loc44_21.3.temp, i32 0, i32 0, !dbg !551
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc45_21.3.temp), !dbg !554
// CHECK:STDOUT:   %.loc45_21.4.v = getelementptr inbounds nuw { i32 }, ptr %.loc45_21.3.temp, i32 0, i32 0, !dbg !554
// CHECK:STDOUT:   %P.call.loc46_13 = call i32 @"_CP:overload0.Main.867fc9b303a9d4e5"(ptr @C.val.loc44_21.9), !dbg !558
// CHECK:STDOUT:   %Int.as.MulWith.impl.Op.call = mul i32 %P.call.loc46_13, 2, !dbg !558
// CHECK:STDOUT:   %P.call.loc46_24 = call i32 @"_CP:overload1.Main.931317eeae6ffe17"(ptr @D.val.loc45_21.9), !dbg !560
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Int.as.MulWith.impl.Op.call, %P.call.loc46_24, !dbg !558
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call = sub i32 %Int.as.AddWith.impl.Op.call, 40, !dbg !558
// CHECK:STDOUT:   call void @"_CSelfDestruct.a50fd899f969e609:core.Destroy.Core"(ptr @D.val), !dbg !554
// CHECK:STDOUT:   call void @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core"(ptr @C.val), !dbg !551
// CHECK:STDOUT:   ret i32 %Int.as.SubWith.impl.Op.call, !dbg !561
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !562 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !564
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.92afc3a45a31c789:core.Destroy.Core"(ptr %self) #0 !dbg !566 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc45.v = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !568
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc45.v), !dbg !568
// CHECK:STDOUT:   ret void, !dbg !568
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.92afc3a45a31c789:core.Destroy.Core"(ptr %self) #0 !dbg !570 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.92afc3a45a31c789:core.Destroy.Core"(ptr %self), !dbg !572
// CHECK:STDOUT:   ret void, !dbg !572
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a50fd899f969e609:core.Destroy.Core"(ptr %self) #0 !dbg !574 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc45.v = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !576
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc45.v), !dbg !576
// CHECK:STDOUT:   ret void, !dbg !576
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a50fd899f969e609:core.Destroy.Core"(ptr %self) #0 !dbg !578 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a50fd899f969e609:core.Destroy.Core"(ptr %self), !dbg !580
// CHECK:STDOUT:   ret void, !dbg !580
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.08d9e38b928ba575:core.Destroy.Core"(ptr %self) #0 !dbg !582 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc44.v = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !584
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc44.v), !dbg !584
// CHECK:STDOUT:   ret void, !dbg !584
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core"(ptr %self) #0 !dbg !586 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.08d9e38b928ba575:core.Destroy.Core"(ptr %self), !dbg !588
// CHECK:STDOUT:   ret void, !dbg !588
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CP:overload0.Main.867fc9b303a9d4e5"(ptr %x) #0 !dbg !590 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 10, !dbg !595
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CP:overload1.Main.931317eeae6ffe17"(ptr %x) #0 !dbg !597 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 20, !dbg !602
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!506}
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
// CHECK:STDOUT: !274 = !{null, !6}
// CHECK:STDOUT: !275 = !DISubroutineType(types: !274)
// CHECK:STDOUT: !430 = !{!7, !7}
// CHECK:STDOUT: !431 = !DISubroutineType(types: !430)
// CHECK:STDOUT: !505 = !DIFile(filename: "overload_probe_require.carbon", directory: "")
// CHECK:STDOUT: !506 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !505, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !507 = distinct !DISubprogram(name: "K", linkageName: "_CK.C.Main:J.Main", scope: null, file: !505, line: 28, type: !9, spFlags: DISPFlagDefinition, unit: !506, retainedNodes: !514)
// CHECK:STDOUT: !508 = !DILocalVariable(arg: 1, scope: !507, type: !7)
// CHECK:STDOUT: !512 = !DILocation(line: 28, column: 32, scope: !507)
// CHECK:STDOUT: !513 = !DILocation(line: 28, column: 25, scope: !507)
// CHECK:STDOUT: !514 = !{!508}
// CHECK:STDOUT: !515 = distinct !DISubprogram(name: "Wrap", linkageName: "_CWrap.C.Main", scope: null, file: !505, line: 30, type: !431, spFlags: DISPFlagDefinition, unit: !506, retainedNodes: !523)
// CHECK:STDOUT: !516 = !DILocalVariable(arg: 1, scope: !515, type: !7)
// CHECK:STDOUT: !520 = !DILocation(line: 30, column: 42, scope: !515)
// CHECK:STDOUT: !521 = !DILocation(line: 30, column: 36, scope: !515)
// CHECK:STDOUT: !522 = !DILocation(line: 30, column: 29, scope: !515)
// CHECK:STDOUT: !523 = !{!516}
// CHECK:STDOUT: !524 = distinct !DISubprogram(name: "V", linkageName: "_CV.C.Main", scope: null, file: !505, line: 31, type: !9, spFlags: DISPFlagDefinition, unit: !506, retainedNodes: !531)
// CHECK:STDOUT: !525 = !DILocalVariable(arg: 1, scope: !524, type: !7)
// CHECK:STDOUT: !529 = !DILocation(line: 31, column: 30, scope: !524)
// CHECK:STDOUT: !530 = !DILocation(line: 31, column: 23, scope: !524)
// CHECK:STDOUT: !531 = !{!525}
// CHECK:STDOUT: !532 = distinct !DISubprogram(name: "Wrap", linkageName: "_CWrap.D.Main", scope: null, file: !505, line: 36, type: !9, spFlags: DISPFlagDefinition, unit: !506, retainedNodes: !539)
// CHECK:STDOUT: !533 = !DILocalVariable(arg: 1, scope: !532, type: !7)
// CHECK:STDOUT: !537 = !DILocation(line: 36, column: 33, scope: !532)
// CHECK:STDOUT: !538 = !DILocation(line: 36, column: 26, scope: !532)
// CHECK:STDOUT: !539 = !{!533}
// CHECK:STDOUT: !540 = distinct !DISubprogram(name: "V", linkageName: "_CV.D.Main", scope: null, file: !505, line: 37, type: !9, spFlags: DISPFlagDefinition, unit: !506, retainedNodes: !547)
// CHECK:STDOUT: !541 = !DILocalVariable(arg: 1, scope: !540, type: !7)
// CHECK:STDOUT: !545 = !DILocation(line: 37, column: 30, scope: !540)
// CHECK:STDOUT: !546 = !DILocation(line: 37, column: 23, scope: !540)
// CHECK:STDOUT: !547 = !{!541}
// CHECK:STDOUT: !548 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !505, line: 43, type: !11, spFlags: DISPFlagDefinition, unit: !506)
// CHECK:STDOUT: !551 = !DILocation(line: 44, column: 14, scope: !548)
// CHECK:STDOUT: !554 = !DILocation(line: 45, column: 14, scope: !548)
// CHECK:STDOUT: !558 = !DILocation(line: 46, column: 10, scope: !548)
// CHECK:STDOUT: !560 = !DILocation(line: 46, column: 21, scope: !548)
// CHECK:STDOUT: !561 = !DILocation(line: 46, column: 3, scope: !548)
// CHECK:STDOUT: !562 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !505, line: 45, type: !275, spFlags: DISPFlagDefinition, unit: !506, retainedNodes: !565)
// CHECK:STDOUT: !563 = !DILocalVariable(arg: 1, scope: !562, type: !6)
// CHECK:STDOUT: !564 = !DILocation(line: 45, column: 14, scope: !562)
// CHECK:STDOUT: !565 = !{!563}
// CHECK:STDOUT: !566 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.92afc3a45a31c789:core.Destroy.Core", scope: null, file: !505, line: 45, type: !13, spFlags: DISPFlagDefinition, unit: !506, retainedNodes: !569)
// CHECK:STDOUT: !567 = !DILocalVariable(arg: 1, scope: !566, type: !7)
// CHECK:STDOUT: !568 = !DILocation(line: 45, column: 14, scope: !566)
// CHECK:STDOUT: !569 = !{!567}
// CHECK:STDOUT: !570 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.92afc3a45a31c789:core.Destroy.Core", scope: null, file: !505, line: 45, type: !13, spFlags: DISPFlagDefinition, unit: !506, retainedNodes: !573)
// CHECK:STDOUT: !571 = !DILocalVariable(arg: 1, scope: !570, type: !7)
// CHECK:STDOUT: !572 = !DILocation(line: 45, column: 14, scope: !570)
// CHECK:STDOUT: !573 = !{!571}
// CHECK:STDOUT: !574 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a50fd899f969e609:core.Destroy.Core", scope: null, file: !505, line: 45, type: !13, spFlags: DISPFlagDefinition, unit: !506, retainedNodes: !577)
// CHECK:STDOUT: !575 = !DILocalVariable(arg: 1, scope: !574, type: !7)
// CHECK:STDOUT: !576 = !DILocation(line: 45, column: 14, scope: !574)
// CHECK:STDOUT: !577 = !{!575}
// CHECK:STDOUT: !578 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a50fd899f969e609:core.Destroy.Core", scope: null, file: !505, line: 45, type: !13, spFlags: DISPFlagDefinition, unit: !506, retainedNodes: !581)
// CHECK:STDOUT: !579 = !DILocalVariable(arg: 1, scope: !578, type: !7)
// CHECK:STDOUT: !580 = !DILocation(line: 45, column: 14, scope: !578)
// CHECK:STDOUT: !581 = !{!579}
// CHECK:STDOUT: !582 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.08d9e38b928ba575:core.Destroy.Core", scope: null, file: !505, line: 44, type: !13, spFlags: DISPFlagDefinition, unit: !506, retainedNodes: !585)
// CHECK:STDOUT: !583 = !DILocalVariable(arg: 1, scope: !582, type: !7)
// CHECK:STDOUT: !584 = !DILocation(line: 44, column: 14, scope: !582)
// CHECK:STDOUT: !585 = !{!583}
// CHECK:STDOUT: !586 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core", scope: null, file: !505, line: 44, type: !13, spFlags: DISPFlagDefinition, unit: !506, retainedNodes: !589)
// CHECK:STDOUT: !587 = !DILocalVariable(arg: 1, scope: !586, type: !7)
// CHECK:STDOUT: !588 = !DILocation(line: 44, column: 14, scope: !586)
// CHECK:STDOUT: !589 = !{!587}
// CHECK:STDOUT: !590 = distinct !DISubprogram(name: "P", linkageName: "_CP:overload0.Main.867fc9b303a9d4e5", scope: null, file: !505, line: 40, type: !9, spFlags: DISPFlagDefinition, unit: !506, retainedNodes: !596)
// CHECK:STDOUT: !591 = !DILocalVariable(arg: 1, scope: !590, type: !7)
// CHECK:STDOUT: !595 = !DILocation(line: 40, column: 58, scope: !590)
// CHECK:STDOUT: !596 = !{!591}
// CHECK:STDOUT: !597 = distinct !DISubprogram(name: "P", linkageName: "_CP:overload1.Main.931317eeae6ffe17", scope: null, file: !505, line: 41, type: !9, spFlags: DISPFlagDefinition, unit: !506, retainedNodes: !603)
// CHECK:STDOUT: !598 = !DILocalVariable(arg: 1, scope: !597, type: !7)
// CHECK:STDOUT: !602 = !DILocation(line: 41, column: 46, scope: !597)
// CHECK:STDOUT: !603 = !{!598}
// CHECK:STDOUT:

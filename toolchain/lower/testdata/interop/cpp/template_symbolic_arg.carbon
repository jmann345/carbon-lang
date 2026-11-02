// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/template_symbolic_arg.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/template_symbolic_arg.carbon

// C++ templates used with symbolic Carbon arguments, lowered for each
// specific: two specifics form two specializations, a narrow scalar returned
// through a template-dependent `return` has no return slot, and a class
// returned that way keeps its in-place storage.

// --- templates.h

inline int destroyed = 0;
template<typename T> struct Loud {
  T value;
  ~Loud() { ++destroyed; }
};
template<typename T> struct Box {
  T value;
};
template<typename T> Box<T> MakeBox(T v) { Box<T> b; b.value = v; return b; }
template<typename T> T Twice(T x) { return x + x; }
template<typename T> T Id(T x) { return x; }
template<typename T> int Plain = sizeof(T) + 1;

// --- two_specifics.carbon

library "[[@TEST_NAME]]";

import Cpp library "templates.h";

class Point {
  var x: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.x = self.x}; }
  }
}

fn Keep[T: type](v: T) -> T {
  var l: Cpp.Loud(T);
  l.value = v;
  return l.value;
}

fn Use() -> i32 {
  let p: Point = Keep({.x = 2} as Point);
  return Keep(5 as i32) + p.x;
}

// --- narrow_return_template.carbon

library "[[@TEST_NAME]]";

import Cpp library "templates.h";

fn Template[template T: type](v: T) -> T {
  return Cpp.Twice(v);
}

fn Use() -> i16 {
  return Template(8 as i16);
}

// --- narrow_return_checked.carbon

library "[[@TEST_NAME]]";

import Cpp library "templates.h";

fn Checked[T: type](v: T) -> T {
  return Cpp.Twice(v);
}

fn Use() -> i16 {
  return Checked(7 as i16);
}

// --- class_return.carbon

library "[[@TEST_NAME]]";

import Cpp library "templates.h";

fn Make[T: type](v: T) -> Cpp.Box(T) {
  return Cpp.MakeBox(v);
}

fn Use() -> i32 {
  return Make(11 as i32).value;
}

// --- alias_of_member_type.carbon

library "[[@TEST_NAME]]";

class X {
  alias Inner = i32;
}

// A class template's alias of a type its parameter names, used in a member
// function's body and signature, is formed for each specific of the class.
class C(template T: type) {
  alias B = T.Inner;
  fn Make(v: B) -> B {
    var b: B;
    b = v;
    return b;
  }
}

fn Use() -> i32 {
  return C(X).Make(5);
}

// --- generic_class_field.carbon

library "[[@TEST_NAME]]";

import Cpp library "templates.h";

class Holder(T: type) {
  var b: Cpp.Box(T);
}

fn Get[T: type](h: Holder(T)) -> T {
  return h.b.value;
}

fn Use() -> i32 {
  var h: Holder(i32) = {.b = Cpp.MakeBox(60 as i32)};
  return Get(h);
}

// --- var_template.carbon

library "[[@TEST_NAME]]";

import Cpp library "templates.h";

fn PlainOf[T: type](unused v: T) -> i32 {
  return Cpp.Plain(T);
}

fn Use() -> i32 {
  return Cpp.Plain(i32) + PlainOf(1 as i64);
}

// --- exported_class_argument.carbon

library "[[@TEST_NAME]]";

import Cpp library "templates.h";

class Point {
  var x: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.x = self.x}; }
  }
}

fn Use() -> i32 {
  return Cpp.Id({.x = 6} as Point).x;
}

// --- loud.h

inline int destroyed = 0;
template<typename T> struct Loud {
  T value;
  ~Loud() { ++destroyed; }
};
template<typename T> Loud<T> MakeLoud(T v) { return {v}; }

// --- todo_discarded_temporary_not_destroyed.carbon

library "[[@TEST_NAME]]";

import Cpp library "loud.h";

// TODO: a temporary that a C++ call deferred to the specific returns is not
// destroyed when discarded, `let`-bound, read for a member or passed by value:
// the specific of `DiscardDeferred` calls no destructor of `Loud<int>`.
fn DiscardDeferred[T: type](v: T) {
  Cpp.MakeLoud(v);
}

fn DiscardConcrete(v: i32) {
  Cpp.MakeLoud(v);
}

fn Use() {
  DiscardDeferred(1 as i32);
  DiscardConcrete(2);
}

// --- store_generic_call_result.carbon

library "[[@TEST_NAME]]";

import Cpp library "templates.h";

fn Mk[T: Core.Copy](x: T) -> T { return x; }

interface Container {
  let Elem: type;
  fn First(self) -> Elem;
}

class IntBox {
  var x: i32;
  impl as Container where .Elem = i32 {
    fn First(self) -> i32 { return self.x; }
  }
}

// A Carbon call's result of a symbolic type stored into a member of a
// specialization, for a checked `T` and for an associated type: the call's
// storage has the specific's type.
fn StoreT[T: Core.Copy](x: T) -> T {
  var b: Cpp.Box(T);
  b.value = Mk(x);
  return b.value;
}

fn StoreElem[C: Container](c: C) -> C.Elem {
  var b: Cpp.Box(C.Elem);
  b.value = c.First();
  return b.value;
}

fn Use() -> i32 {
  return StoreT(9 as i32) + StoreElem({.x = 4} as IntBox);
}

// --- nested_alias_through_specific.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
template<typename T> struct Traits { static constexpr int size = sizeof(T); };
''';

class Inner(T: type) {
  alias Size = Cpp.Traits(T).size;
}

class InnerTemplate(template T: type) {
  alias Size = Cpp.Traits(T).size;
}

// An alias of another class's alias of a template-dependent C++ constant,
// named through a concrete specific from a function that is not generic, is
// lowered as the outer specific's constant: the load of `Traits<long>::size`
// and of `Traits<short>::size`.
class Outer(T: type) {
  alias Size = Inner(T).Size;
}

class OuterOfTemplate(T: type) {
  alias Size = InnerTemplate(T).Size;
}

fn Take(n: i32) -> i32 { return n; }

fn Use() -> i32 {
  let a: i32 = Outer(i64).Size;
  return Take(OuterOfTemplate(i16).Size) + a;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'two_specifics.carbon'
// CHECK:STDOUT: source_filename = "two_specifics.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZN4LoudIN6Carbon5PointEED2Ev = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZN4LoudIiED2Ev = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $destroyed = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @Point.val = internal constant { i32 } { i32 2 }
// CHECK:STDOUT: @Point.val.loc20_32.3 = internal constant { i32 } { i32 2 }
// CHECK:STDOUT: @destroyed = linkonce_odr dso_local global i32 0, comdat, align 4
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.Point.Main:Copy.Core"(ptr sret({ i32 }) %return, ptr %self) #0 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_44.1.x = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !23
// CHECK:STDOUT:   %.loc9_44.2 = load i32, ptr %.loc9_44.1.x, align 4, !dbg !23
// CHECK:STDOUT:   %.loc9_46.2.x = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !24
// CHECK:STDOUT:   store i32 %.loc9_44.2, ptr %.loc9_46.2.x, align 4, !dbg !24
// CHECK:STDOUT:   ret void, !dbg !25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc20_30.3.temp = alloca { i32 }, align 4, !dbg !30
// CHECK:STDOUT:   %.loc20_40.1.temp = alloca { i32 }, align 4, !dbg !31
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc20_30.3.temp), !dbg !30
// CHECK:STDOUT:   %.loc20_30.4.x = getelementptr inbounds nuw { i32 }, ptr %.loc20_30.3.temp, i32 0, i32 0, !dbg !30
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc20_40.1.temp), !dbg !31
// CHECK:STDOUT:   call void @_CKeep.Main.78700dd46f19f8ff(ptr %.loc20_40.1.temp, ptr @Point.val.loc20_32.3), !dbg !31
// CHECK:STDOUT:   %Keep.call.loc21 = call i32 @_CKeep.Main.84588f41d61dafba(i32 5), !dbg !34
// CHECK:STDOUT:   %.loc21_28.1.x = getelementptr inbounds nuw { i32 }, ptr %.loc20_40.1.temp, i32 0, i32 0, !dbg !37
// CHECK:STDOUT:   %.loc21_28.2 = load i32, ptr %.loc21_28.1.x, align 4, !dbg !37
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Keep.call.loc21, %.loc21_28.2, !dbg !34
// CHECK:STDOUT:   call void @"_CSelfDestruct.187891c9c3c64ff5:core.Destroy.Core"(ptr %.loc20_40.1.temp), !dbg !31
// CHECK:STDOUT:   call void @"_CSelfDestruct.187891c9c3c64ff5:core.Destroy.Core"(ptr @Point.val), !dbg !30
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a15077f50f3020c3:core.Destroy.Core"(ptr %self) #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc20.x = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !45
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc20.x), !dbg !45
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a15077f50f3020c3:core.Destroy.Core"(ptr %self) #0 !dbg !47 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a15077f50f3020c3:core.Destroy.Core"(ptr %self), !dbg !49
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.187891c9c3c64ff5:core.Destroy.Core"(ptr %self) #0 !dbg !51 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc20.x = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !53
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc20.x), !dbg !53
// CHECK:STDOUT:   ret void, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.187891c9c3c64ff5:core.Destroy.Core"(ptr %self) #0 !dbg !55 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.187891c9c3c64ff5:core.Destroy.Core"(ptr %self), !dbg !57
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN4LoudIN6Carbon5PointEEC1Ev.carbon_thunk.(ptr noundef %return) #1 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !111
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !111
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_COp:thunk:Default.802e9245aae4d159.Core:Loud.Cpp"(ptr sret([4 x i8]) %return) #2 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN4LoudIN6Carbon5PointEEC1Ev.carbon_thunk.(ptr %return), !dbg !61
// CHECK:STDOUT:   ret void, !dbg !61
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local void @_ZN4LoudIN6Carbon5PointEED2Ev(ptr noundef nonnull align 4 dead_on_return(4) dereferenceable(4) %this) unnamed_addr #3 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !111
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %0 = load i32, ptr @destroyed, align 4, !tbaa !113
// CHECK:STDOUT:   %inc = add nsw i32 %0, 1
// CHECK:STDOUT:   store i32 %inc, ptr @destroyed, align 4, !tbaa !113
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.06480f8a5bb30432:core.Destroy.Core"(ptr %self) #0 !dbg !62 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN4LoudIN6Carbon5PointEED2Ev(ptr %self), !dbg !64
// CHECK:STDOUT:   ret void, !dbg !64
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN4LoudIiEC1Ev.carbon_thunk.(ptr noundef %return) #1 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !115
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !115
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_COp:thunk:Default.872e68d4e0df05b3.Core:Loud.Cpp"(ptr sret([4 x i8]) %return) #2 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN4LoudIiEC1Ev.carbon_thunk.(ptr %return), !dbg !67
// CHECK:STDOUT:   ret void, !dbg !67
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local void @_ZN4LoudIiED2Ev(ptr noundef nonnull align 4 dead_on_return(4) dereferenceable(4) %this) unnamed_addr #3 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !115
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %0 = load i32, ptr @destroyed, align 4, !tbaa !113
// CHECK:STDOUT:   %inc = add nsw i32 %0, 1
// CHECK:STDOUT:   store i32 %inc, ptr @destroyed, align 4, !tbaa !113
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f059966b21c1e6ea:core.Destroy.Core"(ptr %self) #0 !dbg !68 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN4LoudIiED2Ev(ptr %self), !dbg !70
// CHECK:STDOUT:   ret void, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #4
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CKeep.Main.78700dd46f19f8ff(ptr sret({ i32 }) %return, ptr %v) #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %l.var = alloca [4 x i8], align 4, !dbg !77
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %l.var), !dbg !77
// CHECK:STDOUT:   call void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.15e287cc23093f7b"(ptr %l.var), !dbg !77
// CHECK:STDOUT:   %.9b356c.2.value = getelementptr inbounds nuw [4 x i8], ptr %l.var, i32 0, i32 0, !dbg !79
// CHECK:STDOUT:   call void @"_COp.Point.Main:Copy.Core"(ptr %.9b356c.2.value, ptr %v), !dbg !80
// CHECK:STDOUT:   %.9b356c.1.value = getelementptr inbounds nuw [4 x i8], ptr %l.var, i32 0, i32 0, !dbg !81
// CHECK:STDOUT:   call void @"_COp.Point.Main:Copy.Core"(ptr %return, ptr %.9b356c.1.value), !dbg !81
// CHECK:STDOUT:   call void @"_CSelfDestruct.06480f8a5bb30432:core.Destroy.Core"(ptr %l.var), !dbg !77
// CHECK:STDOUT:   ret void, !dbg !82
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CKeep.Main.84588f41d61dafba(i32 %v) #0 !dbg !84 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %l.var = alloca [4 x i8], align 4, !dbg !89
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %l.var), !dbg !89
// CHECK:STDOUT:   call void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.818ed79d5054e1d5"(ptr %l.var), !dbg !89
// CHECK:STDOUT:   %.a3d37c.2.value = getelementptr inbounds nuw [4 x i8], ptr %l.var, i32 0, i32 0, !dbg !91
// CHECK:STDOUT:   store i32 %v, ptr %.a3d37c.2.value, align 4, !dbg !91
// CHECK:STDOUT:   %.a3d37c.1.value = getelementptr inbounds nuw [4 x i8], ptr %l.var, i32 0, i32 0, !dbg !93
// CHECK:STDOUT:   %.fd7 = load i32, ptr %.a3d37c.1.value, align 4, !dbg !93
// CHECK:STDOUT:   call void @"_CSelfDestruct.f059966b21c1e6ea:core.Destroy.Core"(ptr %l.var), !dbg !89
// CHECK:STDOUT:   ret i32 %.fd7, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.15e287cc23093f7b"(ptr sret([4 x i8]) %return) #0 !dbg !97 {
// CHECK:STDOUT:   call void @"_COp:thunk:Default.802e9245aae4d159.Core:Loud.Cpp"(ptr %return), !dbg !100
// CHECK:STDOUT:   ret void, !dbg !101
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.818ed79d5054e1d5"(ptr sret([4 x i8]) %return) #0 !dbg !102 {
// CHECK:STDOUT:   call void @"_COp:thunk:Default.872e68d4e0df05b3.Core:Loud.Cpp"(ptr %return), !dbg !105
// CHECK:STDOUT:   ret void, !dbg !106
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.187891c9c3c64ff5:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 0, 1, 3, 2 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { alwaysinline nounwind }
// CHECK:STDOUT: attributes #3 = { mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!116, !117, !118, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!120}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "two_specifics.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{!6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{null, !7}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !16 = !{!7}
// CHECK:STDOUT: !17 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Point.Main:Copy.Core", scope: null, file: !4, line: 9, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !26)
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 1, scope: !18, type: !7)
// CHECK:STDOUT: !23 = !DILocation(line: 9, column: 40, scope: !18)
// CHECK:STDOUT: !24 = !DILocation(line: 9, column: 34, scope: !18)
// CHECK:STDOUT: !25 = !DILocation(line: 9, column: 27, scope: !18)
// CHECK:STDOUT: !26 = !{!19}
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !4, line: 19, type: !11, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !30 = !DILocation(line: 20, column: 23, scope: !27)
// CHECK:STDOUT: !31 = !DILocation(line: 20, column: 18, scope: !27)
// CHECK:STDOUT: !34 = !DILocation(line: 21, column: 10, scope: !27)
// CHECK:STDOUT: !35 = !{!6, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !37 = !DILocation(line: 21, column: 27, scope: !27)
// CHECK:STDOUT: !38 = !DILocation(line: 21, column: 3, scope: !27)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 20, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !42)
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !39, type: !6)
// CHECK:STDOUT: !41 = !DILocation(line: 20, column: 18, scope: !39)
// CHECK:STDOUT: !42 = !{!40}
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a15077f50f3020c3:core.Destroy.Core", scope: null, file: !4, line: 20, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !46)
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !43, type: !7)
// CHECK:STDOUT: !45 = !DILocation(line: 20, column: 18, scope: !43)
// CHECK:STDOUT: !46 = !{!44}
// CHECK:STDOUT: !47 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a15077f50f3020c3:core.Destroy.Core", scope: null, file: !4, line: 20, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !50)
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !47, type: !7)
// CHECK:STDOUT: !49 = !DILocation(line: 20, column: 18, scope: !47)
// CHECK:STDOUT: !50 = !{!48}
// CHECK:STDOUT: !51 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.187891c9c3c64ff5:core.Destroy.Core", scope: null, file: !4, line: 20, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !54)
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !51, type: !7)
// CHECK:STDOUT: !53 = !DILocation(line: 20, column: 18, scope: !51)
// CHECK:STDOUT: !54 = !{!52}
// CHECK:STDOUT: !55 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.187891c9c3c64ff5:core.Destroy.Core", scope: null, file: !4, line: 20, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !58)
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !55, type: !7)
// CHECK:STDOUT: !57 = !DILocation(line: 20, column: 18, scope: !55)
// CHECK:STDOUT: !58 = !{!56}
// CHECK:STDOUT: !59 = !DIFile(filename: "./templates.h", directory: "")
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:Default.802e9245aae4d159.Core:Loud.Cpp", scope: null, file: !59, line: 3, type: !17, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !61 = !DILocation(line: 3, column: 29, scope: !60)
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.06480f8a5bb30432:core.Destroy.Core", scope: null, file: !4, line: 14, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !65)
// CHECK:STDOUT: !63 = !DILocalVariable(arg: 1, scope: !62, type: !7)
// CHECK:STDOUT: !64 = !DILocation(line: 14, column: 3, scope: !62)
// CHECK:STDOUT: !65 = !{!63}
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:Default.872e68d4e0df05b3.Core:Loud.Cpp", scope: null, file: !59, line: 3, type: !17, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !67 = !DILocation(line: 3, column: 29, scope: !66)
// CHECK:STDOUT: !68 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f059966b21c1e6ea:core.Destroy.Core", scope: null, file: !4, line: 14, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !71)
// CHECK:STDOUT: !69 = !DILocalVariable(arg: 1, scope: !68, type: !7)
// CHECK:STDOUT: !70 = !DILocation(line: 14, column: 3, scope: !68)
// CHECK:STDOUT: !71 = !{!69}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "Keep", linkageName: "_CKeep.Main.78700dd46f19f8ff", scope: null, file: !4, line: 13, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !83)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !7)
// CHECK:STDOUT: !77 = !DILocation(line: 14, column: 3, scope: !72)
// CHECK:STDOUT: !79 = !DILocation(line: 15, column: 3, scope: !72)
// CHECK:STDOUT: !80 = !DILocation(line: 15, column: 13, scope: !72)
// CHECK:STDOUT: !81 = !DILocation(line: 16, column: 10, scope: !72)
// CHECK:STDOUT: !82 = !DILocation(line: 16, column: 3, scope: !72)
// CHECK:STDOUT: !83 = !{!73}
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "Keep", linkageName: "_CKeep.Main.84588f41d61dafba", scope: null, file: !4, line: 13, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !95)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !84, type: !6)
// CHECK:STDOUT: !89 = !DILocation(line: 14, column: 3, scope: !84)
// CHECK:STDOUT: !91 = !DILocation(line: 15, column: 3, scope: !84)
// CHECK:STDOUT: !93 = !DILocation(line: 16, column: 10, scope: !84)
// CHECK:STDOUT: !94 = !DILocation(line: 16, column: 3, scope: !84)
// CHECK:STDOUT: !95 = !{!85}
// CHECK:STDOUT: !96 = !DIFile(filename: "{{.*}}/prelude/default.carbon", directory: "")
// CHECK:STDOUT: !97 = distinct !DISubprogram(name: "Op", linkageName: "_COp.51f3fb62cb986374:DefaultOrUnformed.Core.15e287cc23093f7b", scope: null, file: !96, line: 47, type: !17, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !100 = !DILocation(line: 48, column: 12, scope: !97)
// CHECK:STDOUT: !101 = !DILocation(line: 48, column: 5, scope: !97)
// CHECK:STDOUT: !102 = distinct !DISubprogram(name: "Op", linkageName: "_COp.51f3fb62cb986374:DefaultOrUnformed.Core.818ed79d5054e1d5", scope: null, file: !96, line: 47, type: !17, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !105 = !DILocation(line: 48, column: 12, scope: !102)
// CHECK:STDOUT: !106 = !DILocation(line: 48, column: 5, scope: !102)
// CHECK:STDOUT: !107 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !108 = !{!"omnipotent char", !107, i64 0}
// CHECK:STDOUT: !109 = !{!"any pointer", !108, i64 0}
// CHECK:STDOUT: !110 = !{!"p1 _ZTS4LoudIN6Carbon5PointEE", !109, i64 0}
// CHECK:STDOUT: !111 = !{!110, !110, i64 0}
// CHECK:STDOUT: !112 = !{!"int", !108, i64 0}
// CHECK:STDOUT: !113 = !{!112, !112, i64 0}
// CHECK:STDOUT: !114 = !{!"p1 _ZTS4LoudIiE", !109, i64 0}
// CHECK:STDOUT: !115 = !{!114, !114, i64 0}
// CHECK:STDOUT: !116 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !117 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !118 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !119 = !{!"__libc_errno", !112, i64 0}
// CHECK:STDOUT: !120 = !{!119, !112, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'narrow_return_template.carbon'
// CHECK:STDOUT: source_filename = "narrow_return_template.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z5TwiceIsET_S0_ = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [72 x i8] c"carbon: C++ exception escaped into Carbon through `Twice`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i16 @_CUse.Main() #0 !dbg !128 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Template.call = call i16 @_CTemplate.Main.e98bf0a6f63409ba(i16 8), !dbg !131
// CHECK:STDOUT:   ret i16 %Template.call, !dbg !134
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z5TwiceIsET_S0_.carbon_thunk._(ptr noundef %x, ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.addr = alloca ptr, align 8
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %x, ptr %x.addr, align 8, !tbaa !146
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !146
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !146
// CHECK:STDOUT:   %1 = load ptr, ptr %x.addr, align 8, !tbaa !146
// CHECK:STDOUT:   %2 = load i16, ptr %1, align 2, !tbaa !147
// CHECK:STDOUT:   %call = invoke noundef signext i16 @_Z5TwiceIsET_S0_(i16 noundef signext %2)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   store i16 %call, ptr %0, align 2, !tbaa !147
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %3 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %3, 0
// CHECK:STDOUT:   store ptr %4, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %3, 1
// CHECK:STDOUT:   store i32 %5, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %6 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 71) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %7 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %8 = extractvalue { ptr, i32 } %7, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %8) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i16 @_CTemplate.Main.e98bf0a6f63409ba(i16 %v) #0 !dbg !135 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.3ec6a3.1.temp = alloca i16, align 2, !dbg !140
// CHECK:STDOUT:   %.3ec6a3.2.temp = alloca i16, align 2, !dbg !141
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.3ec6a3.1.temp), !dbg !140
// CHECK:STDOUT:   store i16 %v, ptr %.3ec6a3.1.temp, align 2, !dbg !140
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.3ec6a3.2.temp), !dbg !141
// CHECK:STDOUT:   call void @_Z5TwiceIsET_S0_.carbon_thunk._(ptr %.3ec6a3.1.temp, ptr %.3ec6a3.2.temp), !dbg !141
// CHECK:STDOUT:   %0 = load i16, ptr %.3ec6a3.2.temp, align 2, !dbg !142
// CHECK:STDOUT:   ret i16 %0, !dbg !142
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef signext i16 @_Z5TwiceIsET_S0_(i16 noundef signext %x) #3 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.addr = alloca i16, align 2
// CHECK:STDOUT:   store i16 %x, ptr %x.addr, align 2, !tbaa !147
// CHECK:STDOUT:   %0 = load i16, ptr %x.addr, align 2, !tbaa !147
// CHECK:STDOUT:   %conv = sext i16 %0 to i32
// CHECK:STDOUT:   %1 = load i16, ptr %x.addr, align 2, !tbaa !147
// CHECK:STDOUT:   %conv1 = sext i16 %1 to i32
// CHECK:STDOUT:   %add = add nsw i32 %conv, %conv1
// CHECK:STDOUT:   %conv2 = trunc i32 %add to i16
// CHECK:STDOUT:   ret i16 %conv2
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #4
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #5 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!122}
// CHECK:STDOUT: !llvm.module.flags = !{!116, !117, !118, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!120}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !107 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !108 = !{!"omnipotent char", !107, i64 0}
// CHECK:STDOUT: !109 = !{!"any pointer", !108, i64 0}
// CHECK:STDOUT: !112 = !{!"int", !108, i64 0}
// CHECK:STDOUT: !116 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !117 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !118 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !119 = !{!"__libc_errno", !112, i64 0}
// CHECK:STDOUT: !120 = !{!119, !112, i64 0}
// CHECK:STDOUT: !121 = !DIFile(filename: "narrow_return_template.carbon", directory: "")
// CHECK:STDOUT: !122 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !121, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !123 = !DIBasicType(name: "int", size: 16, encoding: DW_ATE_signed)
// CHECK:STDOUT: !124 = !{!123}
// CHECK:STDOUT: !125 = !DISubroutineType(types: !124)
// CHECK:STDOUT: !128 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !121, line: 10, type: !125, spFlags: DISPFlagDefinition, unit: !122)
// CHECK:STDOUT: !131 = !DILocation(line: 11, column: 10, scope: !128)
// CHECK:STDOUT: !132 = !{!123, !123}
// CHECK:STDOUT: !133 = !DISubroutineType(types: !132)
// CHECK:STDOUT: !134 = !DILocation(line: 11, column: 3, scope: !128)
// CHECK:STDOUT: !135 = distinct !DISubprogram(name: "Template", linkageName: "_CTemplate.Main.e98bf0a6f63409ba", scope: null, file: !121, line: 6, type: !133, spFlags: DISPFlagDefinition, unit: !122, retainedNodes: !143)
// CHECK:STDOUT: !136 = !DILocalVariable(arg: 1, scope: !135, type: !123)
// CHECK:STDOUT: !140 = !DILocation(line: 7, column: 20, scope: !135)
// CHECK:STDOUT: !141 = !DILocation(line: 7, column: 10, scope: !135)
// CHECK:STDOUT: !142 = !DILocation(line: 7, column: 3, scope: !135)
// CHECK:STDOUT: !143 = !{!136}
// CHECK:STDOUT: !144 = !{!"short", !108, i64 0}
// CHECK:STDOUT: !145 = !{!"p1 short", !109, i64 0}
// CHECK:STDOUT: !146 = !{!145, !145, i64 0}
// CHECK:STDOUT: !147 = !{!144, !144, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'narrow_return_checked.carbon'
// CHECK:STDOUT: source_filename = "narrow_return_checked.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z5TwiceIsET_S0_ = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [72 x i8] c"carbon: C++ exception escaped into Carbon through `Twice`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i16 @_CUse.Main() #0 !dbg !150 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Checked.call = call i16 @_CChecked.Main.e98bf0a6f63409ba(i16 7), !dbg !153
// CHECK:STDOUT:   ret i16 %Checked.call, !dbg !154
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z5TwiceIsET_S0_.carbon_thunk._(ptr noundef %x, ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.addr = alloca ptr, align 8
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %x, ptr %x.addr, align 8, !tbaa !146
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !146
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !146
// CHECK:STDOUT:   %1 = load ptr, ptr %x.addr, align 8, !tbaa !146
// CHECK:STDOUT:   %2 = load i16, ptr %1, align 2, !tbaa !147
// CHECK:STDOUT:   %call = invoke noundef signext i16 @_Z5TwiceIsET_S0_(i16 noundef signext %2)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   store i16 %call, ptr %0, align 2, !tbaa !147
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %3 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %3, 0
// CHECK:STDOUT:   store ptr %4, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %3, 1
// CHECK:STDOUT:   store i32 %5, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %6 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 71) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %7 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %8 = extractvalue { ptr, i32 } %7, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %8) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i16 @_CChecked.Main.e98bf0a6f63409ba(i16 %v) #0 !dbg !155 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.3ec6a3.1.temp = alloca i16, align 2, !dbg !160
// CHECK:STDOUT:   %.3ec6a3.2.temp = alloca i16, align 2, !dbg !161
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.3ec6a3.1.temp), !dbg !160
// CHECK:STDOUT:   store i16 %v, ptr %.3ec6a3.1.temp, align 2, !dbg !160
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.3ec6a3.2.temp), !dbg !161
// CHECK:STDOUT:   call void @_Z5TwiceIsET_S0_.carbon_thunk._(ptr %.3ec6a3.1.temp, ptr %.3ec6a3.2.temp), !dbg !161
// CHECK:STDOUT:   %0 = load i16, ptr %.3ec6a3.2.temp, align 2, !dbg !162
// CHECK:STDOUT:   ret i16 %0, !dbg !162
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef signext i16 @_Z5TwiceIsET_S0_(i16 noundef signext %x) #3 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.addr = alloca i16, align 2
// CHECK:STDOUT:   store i16 %x, ptr %x.addr, align 2, !tbaa !147
// CHECK:STDOUT:   %0 = load i16, ptr %x.addr, align 2, !tbaa !147
// CHECK:STDOUT:   %conv = sext i16 %0 to i32
// CHECK:STDOUT:   %1 = load i16, ptr %x.addr, align 2, !tbaa !147
// CHECK:STDOUT:   %conv1 = sext i16 %1 to i32
// CHECK:STDOUT:   %add = add nsw i32 %conv, %conv1
// CHECK:STDOUT:   %conv2 = trunc i32 %add to i16
// CHECK:STDOUT:   ret i16 %conv2
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #4
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #5 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!149}
// CHECK:STDOUT: !llvm.module.flags = !{!116, !117, !118, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!120}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !107 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !108 = !{!"omnipotent char", !107, i64 0}
// CHECK:STDOUT: !109 = !{!"any pointer", !108, i64 0}
// CHECK:STDOUT: !112 = !{!"int", !108, i64 0}
// CHECK:STDOUT: !116 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !117 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !118 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !119 = !{!"__libc_errno", !112, i64 0}
// CHECK:STDOUT: !120 = !{!119, !112, i64 0}
// CHECK:STDOUT: !123 = !DIBasicType(name: "int", size: 16, encoding: DW_ATE_signed)
// CHECK:STDOUT: !124 = !{!123}
// CHECK:STDOUT: !125 = !DISubroutineType(types: !124)
// CHECK:STDOUT: !132 = !{!123, !123}
// CHECK:STDOUT: !133 = !DISubroutineType(types: !132)
// CHECK:STDOUT: !144 = !{!"short", !108, i64 0}
// CHECK:STDOUT: !145 = !{!"p1 short", !109, i64 0}
// CHECK:STDOUT: !146 = !{!145, !145, i64 0}
// CHECK:STDOUT: !147 = !{!144, !144, i64 0}
// CHECK:STDOUT: !148 = !DIFile(filename: "narrow_return_checked.carbon", directory: "")
// CHECK:STDOUT: !149 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !148, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !150 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !148, line: 10, type: !125, spFlags: DISPFlagDefinition, unit: !149)
// CHECK:STDOUT: !153 = !DILocation(line: 11, column: 10, scope: !150)
// CHECK:STDOUT: !154 = !DILocation(line: 11, column: 3, scope: !150)
// CHECK:STDOUT: !155 = distinct !DISubprogram(name: "Checked", linkageName: "_CChecked.Main.e98bf0a6f63409ba", scope: null, file: !148, line: 6, type: !133, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !163)
// CHECK:STDOUT: !156 = !DILocalVariable(arg: 1, scope: !155, type: !123)
// CHECK:STDOUT: !160 = !DILocation(line: 7, column: 20, scope: !155)
// CHECK:STDOUT: !161 = !DILocation(line: 7, column: 10, scope: !155)
// CHECK:STDOUT: !162 = !DILocation(line: 7, column: 3, scope: !155)
// CHECK:STDOUT: !163 = !{!156}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'class_return.carbon'
// CHECK:STDOUT: source_filename = "class_return.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %struct.Box = type { i32 }
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z7MakeBoxIiE3BoxIT_ES1_ = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [74 x i8] c"carbon: C++ exception escaped into Carbon through `MakeBox`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !168 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc11_24.1.temp = alloca [4 x i8], align 4, !dbg !171
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc11_24.1.temp), !dbg !171
// CHECK:STDOUT:   call void @_CMake.Main.84588f41d61dafba(ptr %.loc11_24.1.temp, i32 11), !dbg !171
// CHECK:STDOUT:   %.loc11_25.1.value = getelementptr inbounds nuw [4 x i8], ptr %.loc11_24.1.temp, i32 0, i32 0, !dbg !171
// CHECK:STDOUT:   %.loc11_25.2 = load i32, ptr %.loc11_25.1.value, align 4, !dbg !171
// CHECK:STDOUT:   call void @"_CSelfDestruct.195193979e0bd7ed:core.Destroy.Core"(ptr %.loc11_24.1.temp), !dbg !171
// CHECK:STDOUT:   ret i32 %.loc11_25.2, !dbg !174
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.195193979e0bd7ed:core.Destroy.Core"(ptr %self) #0 !dbg !175 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !177
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z7MakeBoxIiE3BoxIT_ES1_.carbon_thunk._(i32 noundef %v, ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.addr = alloca i32, align 4
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store i32 %v, ptr %v.addr, align 4, !tbaa !113
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !189
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !189
// CHECK:STDOUT:   %1 = load i32, ptr %v.addr, align 4, !tbaa !113
// CHECK:STDOUT:   %call = invoke i32 @_Z7MakeBoxIiE3BoxIT_ES1_(i32 noundef %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   %coerce.dive = getelementptr inbounds nuw %struct.Box, ptr %0, i32 0, i32 0
// CHECK:STDOUT:   store i32 %call, ptr %coerce.dive, align 4
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %2 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %2, 0
// CHECK:STDOUT:   store ptr %3, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %2, 1
// CHECK:STDOUT:   store i32 %4, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 73) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %7) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CMake.Main.84588f41d61dafba(ptr sret([4 x i8]) %return, i32 %v) #0 !dbg !179 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_Z7MakeBoxIiE3BoxIT_ES1_.carbon_thunk._(i32 %v, ptr %return), !dbg !185
// CHECK:STDOUT:   ret void, !dbg !186
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local i32 @_Z7MakeBoxIiE3BoxIT_ES1_(i32 noundef %v) #3 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca %struct.Box, align 4
// CHECK:STDOUT:   %v.addr = alloca i32, align 4
// CHECK:STDOUT:   store i32 %v, ptr %v.addr, align 4, !tbaa !113
// CHECK:STDOUT:   %0 = load i32, ptr %v.addr, align 4, !tbaa !113
// CHECK:STDOUT:   %value = getelementptr inbounds nuw %struct.Box, ptr %retval, i32 0, i32 0
// CHECK:STDOUT:   store i32 %0, ptr %value, align 4, !tbaa !191
// CHECK:STDOUT:   %coerce.dive = getelementptr inbounds nuw %struct.Box, ptr %retval, i32 0, i32 0
// CHECK:STDOUT:   %1 = load i32, ptr %coerce.dive, align 4
// CHECK:STDOUT:   ret i32 %1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #4
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #5 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!165}
// CHECK:STDOUT: !llvm.module.flags = !{!116, !117, !118, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!120}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !14 = !{null, !7}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !107 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !108 = !{!"omnipotent char", !107, i64 0}
// CHECK:STDOUT: !109 = !{!"any pointer", !108, i64 0}
// CHECK:STDOUT: !112 = !{!"int", !108, i64 0}
// CHECK:STDOUT: !113 = !{!112, !112, i64 0}
// CHECK:STDOUT: !116 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !117 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !118 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !119 = !{!"__libc_errno", !112, i64 0}
// CHECK:STDOUT: !120 = !{!119, !112, i64 0}
// CHECK:STDOUT: !164 = !DIFile(filename: "class_return.carbon", directory: "")
// CHECK:STDOUT: !165 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !164, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !168 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !164, line: 10, type: !11, spFlags: DISPFlagDefinition, unit: !165)
// CHECK:STDOUT: !171 = !DILocation(line: 11, column: 10, scope: !168)
// CHECK:STDOUT: !172 = !{!7, !6}
// CHECK:STDOUT: !173 = !DISubroutineType(types: !172)
// CHECK:STDOUT: !174 = !DILocation(line: 11, column: 3, scope: !168)
// CHECK:STDOUT: !175 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.195193979e0bd7ed:core.Destroy.Core", scope: null, file: !164, line: 11, type: !15, spFlags: DISPFlagDefinition, unit: !165, retainedNodes: !178)
// CHECK:STDOUT: !176 = !DILocalVariable(arg: 1, scope: !175, type: !7)
// CHECK:STDOUT: !177 = !DILocation(line: 11, column: 10, scope: !175)
// CHECK:STDOUT: !178 = !{!176}
// CHECK:STDOUT: !179 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.Main.84588f41d61dafba", scope: null, file: !164, line: 6, type: !173, spFlags: DISPFlagDefinition, unit: !165, retainedNodes: !187)
// CHECK:STDOUT: !180 = !DILocalVariable(arg: 1, scope: !179, type: !6)
// CHECK:STDOUT: !185 = !DILocation(line: 7, column: 10, scope: !179)
// CHECK:STDOUT: !186 = !DILocation(line: 7, column: 3, scope: !179)
// CHECK:STDOUT: !187 = !{!180}
// CHECK:STDOUT: !188 = !{!"p1 _ZTS3BoxIiE", !109, i64 0}
// CHECK:STDOUT: !189 = !{!188, !188, i64 0}
// CHECK:STDOUT: !190 = !{!"_ZTS3BoxIiE", !112, i64 0}
// CHECK:STDOUT: !191 = !{!190, !112, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'alias_of_member_type.carbon'
// CHECK:STDOUT: source_filename = "alias_of_member_type.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !194 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %C.Make.call = call i32 @_CMake.C.Main.9eb1010069919743(i32 5), !dbg !197
// CHECK:STDOUT:   ret i32 %C.Make.call, !dbg !198
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !199 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !201
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CMake.C.Main.9eb1010069919743(i32 %v) #0 !dbg !203 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %b.var = alloca i32, align 4, !dbg !208
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !208
// CHECK:STDOUT:   store i32 poison, ptr %b.var, align 4, !dbg !208
// CHECK:STDOUT:   store i32 %v, ptr %b.var, align 4, !dbg !210
// CHECK:STDOUT:   %.628 = load i32, ptr %b.var, align 4, !dbg !212
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %b.var), !dbg !208
// CHECK:STDOUT:   ret i32 %.628, !dbg !213
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!193}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !10 = !{!6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !35 = !{!6, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !192 = !DIFile(filename: "alias_of_member_type.carbon", directory: "")
// CHECK:STDOUT: !193 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !192, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !194 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !192, line: 19, type: !11, spFlags: DISPFlagDefinition, unit: !193)
// CHECK:STDOUT: !197 = !DILocation(line: 20, column: 10, scope: !194)
// CHECK:STDOUT: !198 = !DILocation(line: 20, column: 3, scope: !194)
// CHECK:STDOUT: !199 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !192, line: 13, type: !13, spFlags: DISPFlagDefinition, unit: !193, retainedNodes: !202)
// CHECK:STDOUT: !200 = !DILocalVariable(arg: 1, scope: !199, type: !6)
// CHECK:STDOUT: !201 = !DILocation(line: 13, column: 5, scope: !199)
// CHECK:STDOUT: !202 = !{!200}
// CHECK:STDOUT: !203 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.C.Main.9eb1010069919743", scope: null, file: !192, line: 12, type: !36, spFlags: DISPFlagDefinition, unit: !193, retainedNodes: !214)
// CHECK:STDOUT: !204 = !DILocalVariable(arg: 1, scope: !203, type: !6)
// CHECK:STDOUT: !208 = !DILocation(line: 13, column: 5, scope: !203)
// CHECK:STDOUT: !210 = !DILocation(line: 14, column: 5, scope: !203)
// CHECK:STDOUT: !212 = !DILocation(line: 15, column: 12, scope: !203)
// CHECK:STDOUT: !213 = !DILocation(line: 15, column: 5, scope: !203)
// CHECK:STDOUT: !214 = !{!204}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'generic_class_field.carbon'
// CHECK:STDOUT: source_filename = "generic_class_field.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %struct.Box.13 = type { i32 }
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z7MakeBoxIiE3BoxIT_ES1_ = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [74 x i8] c"carbon: C++ exception escaped into Carbon through `MakeBox`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !217 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %h.var = alloca { [4 x i8] }, align 4, !dbg !220
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %h.var), !dbg !220
// CHECK:STDOUT:   %.loc15_52.1.b = getelementptr inbounds nuw { [4 x i8] }, ptr %h.var, i32 0, i32 0, !dbg !221
// CHECK:STDOUT:   call void @_Z7MakeBoxIiE3BoxIT_ES1_.carbon_thunk._(i32 60, ptr %.loc15_52.1.b), !dbg !222
// CHECK:STDOUT:   %Get.call = call i32 @_CGet.Main.84588f41d61dafba(ptr %h.var), !dbg !225
// CHECK:STDOUT:   call void @"_CSelfDestruct.cdff7e2d24e00bd0:core.Destroy.Core"(ptr %h.var), !dbg !220
// CHECK:STDOUT:   ret i32 %Get.call, !dbg !228
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z7MakeBoxIiE3BoxIT_ES1_.carbon_thunk._(i32 noundef %v, ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.addr = alloca i32, align 4
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store i32 %v, ptr %v.addr, align 4, !tbaa !113
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !189
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !189
// CHECK:STDOUT:   %1 = load i32, ptr %v.addr, align 4, !tbaa !113
// CHECK:STDOUT:   %call = invoke i32 @_Z7MakeBoxIiE3BoxIT_ES1_(i32 noundef %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   %coerce.dive = getelementptr inbounds nuw %struct.Box.13, ptr %0, i32 0, i32 0
// CHECK:STDOUT:   store i32 %call, ptr %coerce.dive, align 4
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %2 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %2, 0
// CHECK:STDOUT:   store ptr %3, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %2, 1
// CHECK:STDOUT:   store i32 %4, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 73) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %7) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.195193979e0bd7ed:core.Destroy.Core"(ptr %self) #0 !dbg !229 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !231
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.21f7819eefb2b4ab:core.Destroy.Core"(ptr %self) #0 !dbg !233 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc15.b = getelementptr inbounds nuw { [4 x i8] }, ptr %self, i32 0, i32 0, !dbg !235
// CHECK:STDOUT:   call void @"_CSelfDestruct.195193979e0bd7ed:core.Destroy.Core"(ptr %.loc15.b), !dbg !235
// CHECK:STDOUT:   ret void, !dbg !235
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.21f7819eefb2b4ab:core.Destroy.Core"(ptr %self) #0 !dbg !237 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.21f7819eefb2b4ab:core.Destroy.Core"(ptr %self), !dbg !239
// CHECK:STDOUT:   ret void, !dbg !239
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.cdff7e2d24e00bd0:core.Destroy.Core"(ptr %self) #0 !dbg !241 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc15.b = getelementptr inbounds nuw { [4 x i8] }, ptr %self, i32 0, i32 0, !dbg !243
// CHECK:STDOUT:   call void @"_CSelfDestruct.195193979e0bd7ed:core.Destroy.Core"(ptr %.loc15.b), !dbg !243
// CHECK:STDOUT:   ret void, !dbg !243
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.cdff7e2d24e00bd0:core.Destroy.Core"(ptr %self) #0 !dbg !245 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.cdff7e2d24e00bd0:core.Destroy.Core"(ptr %self), !dbg !247
// CHECK:STDOUT:   ret void, !dbg !247
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Main.84588f41d61dafba(ptr %h) #0 !dbg !249 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc11_11.1.b = getelementptr inbounds nuw { [4 x i8] }, ptr %h, i32 0, i32 0, !dbg !254
// CHECK:STDOUT:   %.087.value = getelementptr inbounds nuw [4 x i8], ptr %.loc11_11.1.b, i32 0, i32 0, !dbg !254
// CHECK:STDOUT:   %.b25 = load i32, ptr %.087.value, align 4, !dbg !254
// CHECK:STDOUT:   ret i32 %.b25, !dbg !255
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local i32 @_Z7MakeBoxIiE3BoxIT_ES1_(i32 noundef %v) #3 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca %struct.Box.13, align 4
// CHECK:STDOUT:   %v.addr = alloca i32, align 4
// CHECK:STDOUT:   store i32 %v, ptr %v.addr, align 4, !tbaa !113
// CHECK:STDOUT:   %0 = load i32, ptr %v.addr, align 4, !tbaa !113
// CHECK:STDOUT:   %value = getelementptr inbounds nuw %struct.Box.13, ptr %retval, i32 0, i32 0
// CHECK:STDOUT:   store i32 %0, ptr %value, align 4, !tbaa !191
// CHECK:STDOUT:   %coerce.dive = getelementptr inbounds nuw %struct.Box.13, ptr %retval, i32 0, i32 0
// CHECK:STDOUT:   %1 = load i32, ptr %coerce.dive, align 4
// CHECK:STDOUT:   ret i32 %1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #4
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #5 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!216}
// CHECK:STDOUT: !llvm.module.flags = !{!116, !117, !118, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!120}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !14 = !{null, !7}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !107 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !108 = !{!"omnipotent char", !107, i64 0}
// CHECK:STDOUT: !109 = !{!"any pointer", !108, i64 0}
// CHECK:STDOUT: !112 = !{!"int", !108, i64 0}
// CHECK:STDOUT: !113 = !{!112, !112, i64 0}
// CHECK:STDOUT: !116 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !117 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !118 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !119 = !{!"__libc_errno", !112, i64 0}
// CHECK:STDOUT: !120 = !{!119, !112, i64 0}
// CHECK:STDOUT: !188 = !{!"p1 _ZTS3BoxIiE", !109, i64 0}
// CHECK:STDOUT: !189 = !{!188, !188, i64 0}
// CHECK:STDOUT: !190 = !{!"_ZTS3BoxIiE", !112, i64 0}
// CHECK:STDOUT: !191 = !{!190, !112, i64 0}
// CHECK:STDOUT: !215 = !DIFile(filename: "generic_class_field.carbon", directory: "")
// CHECK:STDOUT: !216 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !215, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !217 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !215, line: 14, type: !11, spFlags: DISPFlagDefinition, unit: !216)
// CHECK:STDOUT: !220 = !DILocation(line: 15, column: 3, scope: !217)
// CHECK:STDOUT: !221 = !DILocation(line: 15, column: 24, scope: !217)
// CHECK:STDOUT: !222 = !DILocation(line: 15, column: 30, scope: !217)
// CHECK:STDOUT: !225 = !DILocation(line: 16, column: 10, scope: !217)
// CHECK:STDOUT: !226 = !{!6, !7}
// CHECK:STDOUT: !227 = !DISubroutineType(types: !226)
// CHECK:STDOUT: !228 = !DILocation(line: 16, column: 3, scope: !217)
// CHECK:STDOUT: !229 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.195193979e0bd7ed:core.Destroy.Core", scope: null, file: !215, line: 15, type: !15, spFlags: DISPFlagDefinition, unit: !216, retainedNodes: !232)
// CHECK:STDOUT: !230 = !DILocalVariable(arg: 1, scope: !229, type: !7)
// CHECK:STDOUT: !231 = !DILocation(line: 15, column: 3, scope: !229)
// CHECK:STDOUT: !232 = !{!230}
// CHECK:STDOUT: !233 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.21f7819eefb2b4ab:core.Destroy.Core", scope: null, file: !215, line: 15, type: !15, spFlags: DISPFlagDefinition, unit: !216, retainedNodes: !236)
// CHECK:STDOUT: !234 = !DILocalVariable(arg: 1, scope: !233, type: !7)
// CHECK:STDOUT: !235 = !DILocation(line: 15, column: 3, scope: !233)
// CHECK:STDOUT: !236 = !{!234}
// CHECK:STDOUT: !237 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.21f7819eefb2b4ab:core.Destroy.Core", scope: null, file: !215, line: 15, type: !15, spFlags: DISPFlagDefinition, unit: !216, retainedNodes: !240)
// CHECK:STDOUT: !238 = !DILocalVariable(arg: 1, scope: !237, type: !7)
// CHECK:STDOUT: !239 = !DILocation(line: 15, column: 3, scope: !237)
// CHECK:STDOUT: !240 = !{!238}
// CHECK:STDOUT: !241 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.cdff7e2d24e00bd0:core.Destroy.Core", scope: null, file: !215, line: 15, type: !15, spFlags: DISPFlagDefinition, unit: !216, retainedNodes: !244)
// CHECK:STDOUT: !242 = !DILocalVariable(arg: 1, scope: !241, type: !7)
// CHECK:STDOUT: !243 = !DILocation(line: 15, column: 3, scope: !241)
// CHECK:STDOUT: !244 = !{!242}
// CHECK:STDOUT: !245 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.cdff7e2d24e00bd0:core.Destroy.Core", scope: null, file: !215, line: 15, type: !15, spFlags: DISPFlagDefinition, unit: !216, retainedNodes: !248)
// CHECK:STDOUT: !246 = !DILocalVariable(arg: 1, scope: !245, type: !7)
// CHECK:STDOUT: !247 = !DILocation(line: 15, column: 3, scope: !245)
// CHECK:STDOUT: !248 = !{!246}
// CHECK:STDOUT: !249 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Main.84588f41d61dafba", scope: null, file: !215, line: 10, type: !227, spFlags: DISPFlagDefinition, unit: !216, retainedNodes: !256)
// CHECK:STDOUT: !250 = !DILocalVariable(arg: 1, scope: !249, type: !7)
// CHECK:STDOUT: !254 = !DILocation(line: 11, column: 10, scope: !249)
// CHECK:STDOUT: !255 = !DILocation(line: 11, column: 3, scope: !249)
// CHECK:STDOUT: !256 = !{!250}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'var_template.carbon'
// CHECK:STDOUT: source_filename = "var_template.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z5PlainIiE = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z5PlainIlE = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @_Z5PlainIiE = linkonce_odr dso_local global i32 5, comdat, align 4
// CHECK:STDOUT: @_Z5PlainIlE = linkonce_odr dso_local global i32 9, comdat, align 4
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !260 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %PlainOf.call = call i32 @_CPlainOf.Main.f249b435619a5146(i64 1), !dbg !263
// CHECK:STDOUT:   %.loc11_23 = load i32, ptr @_Z5PlainIiE, align 4, !dbg !266
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc11_23, %PlainOf.call, !dbg !266
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !267
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CPlainOf.Main.f249b435619a5146(i64 %v) #0 !dbg !268 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.1a6 = load i32, ptr @_Z5PlainIlE, align 4, !dbg !274
// CHECK:STDOUT:   ret i32 %.1a6, !dbg !273
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!258}
// CHECK:STDOUT: !llvm.module.flags = !{!116, !117, !118, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!120}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !10 = !{!6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !107 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !108 = !{!"omnipotent char", !107, i64 0}
// CHECK:STDOUT: !112 = !{!"int", !108, i64 0}
// CHECK:STDOUT: !116 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !117 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !118 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !119 = !{!"__libc_errno", !112, i64 0}
// CHECK:STDOUT: !120 = !{!119, !112, i64 0}
// CHECK:STDOUT: !257 = !DIFile(filename: "var_template.carbon", directory: "")
// CHECK:STDOUT: !258 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !257, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !259 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !260 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !257, line: 10, type: !11, spFlags: DISPFlagDefinition, unit: !258)
// CHECK:STDOUT: !263 = !DILocation(line: 11, column: 27, scope: !260)
// CHECK:STDOUT: !264 = !{!6, !259}
// CHECK:STDOUT: !265 = !DISubroutineType(types: !264)
// CHECK:STDOUT: !266 = !DILocation(line: 11, column: 10, scope: !260)
// CHECK:STDOUT: !267 = !DILocation(line: 11, column: 3, scope: !260)
// CHECK:STDOUT: !268 = distinct !DISubprogram(name: "PlainOf", linkageName: "_CPlainOf.Main.f249b435619a5146", scope: null, file: !257, line: 6, type: !265, spFlags: DISPFlagDefinition, unit: !258, retainedNodes: !275)
// CHECK:STDOUT: !269 = !DILocalVariable(arg: 1, scope: !268, type: !259)
// CHECK:STDOUT: !273 = !DILocation(line: 7, column: 3, scope: !268)
// CHECK:STDOUT: !274 = !DILocation(line: 7, column: 10, scope: !268)
// CHECK:STDOUT: !275 = !{!269}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'exported_class_argument.carbon'
// CHECK:STDOUT: source_filename = "exported_class_argument.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %"class.Carbon::Point.18" = type { i32 }
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z2IdIN6Carbon5PointEET_S2_ = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @Point.val = internal constant { i32 } { i32 6 }
// CHECK:STDOUT: @Point.val.loc14_26.3 = internal constant { i32 } { i32 6 }
// CHECK:STDOUT: @.str = private unnamed_addr constant [69 x i8] c"carbon: C++ exception escaped into Carbon through `Id`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.Point.Main:Copy.Core"(ptr sret({ i32 }) %return, ptr %self) #0 !dbg !278 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_44.1.x = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !283
// CHECK:STDOUT:   %.loc9_44.2 = load i32, ptr %.loc9_44.1.x, align 4, !dbg !283
// CHECK:STDOUT:   %.loc9_46.2.x = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !284
// CHECK:STDOUT:   store i32 %.loc9_44.2, ptr %.loc9_46.2.x, align 4, !dbg !284
// CHECK:STDOUT:   ret void, !dbg !285
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !287 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14_24.3.temp = alloca { i32 }, align 4, !dbg !290
// CHECK:STDOUT:   %.loc14_34.1.temp = alloca { i32 }, align 4, !dbg !291
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc14_24.3.temp), !dbg !290
// CHECK:STDOUT:   %.loc14_24.4.x = getelementptr inbounds nuw { i32 }, ptr %.loc14_24.3.temp, i32 0, i32 0, !dbg !290
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc14_34.1.temp), !dbg !291
// CHECK:STDOUT:   call void @_Z2IdIN6Carbon5PointEET_S2_.carbon_thunk._(ptr @Point.val.loc14_26.3, ptr %.loc14_34.1.temp), !dbg !291
// CHECK:STDOUT:   %.loc14_35.1.x = getelementptr inbounds nuw { i32 }, ptr %.loc14_34.1.temp, i32 0, i32 0, !dbg !291
// CHECK:STDOUT:   %.loc14_35.2 = load i32, ptr %.loc14_35.1.x, align 4, !dbg !291
// CHECK:STDOUT:   call void @"_CSelfDestruct.187891c9c3c64ff5:core.Destroy.Core"(ptr %.loc14_34.1.temp), !dbg !291
// CHECK:STDOUT:   call void @"_CSelfDestruct.187891c9c3c64ff5:core.Destroy.Core"(ptr @Point.val), !dbg !290
// CHECK:STDOUT:   ret i32 %.loc14_35.2, !dbg !292
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z2IdIN6Carbon5PointEET_S2_.carbon_thunk._(ptr noundef %x, ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.addr = alloca ptr, align 8
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %agg.tmp = alloca %"class.Carbon::Point.18", align 4
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %x, ptr %x.addr, align 8, !tbaa !314
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !314
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !314
// CHECK:STDOUT:   %1 = load ptr, ptr %x.addr, align 8, !tbaa !314
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %agg.tmp, ptr align 4 %1, i64 4, i1 false), !tbaa.struct !316
// CHECK:STDOUT:   %coerce.dive = getelementptr inbounds nuw %"class.Carbon::Point.18", ptr %agg.tmp, i32 0, i32 0
// CHECK:STDOUT:   %2 = load i32, ptr %coerce.dive, align 4
// CHECK:STDOUT:   %call = invoke i32 @_Z2IdIN6Carbon5PointEET_S2_(i32 %2)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   %coerce.dive1 = getelementptr inbounds nuw %"class.Carbon::Point.18", ptr %0, i32 0, i32 0
// CHECK:STDOUT:   store i32 %call, ptr %coerce.dive1, align 4
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %3 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %3, 0
// CHECK:STDOUT:   store ptr %4, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %3, 1
// CHECK:STDOUT:   store i32 %5, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %6 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call2 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 68) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %7 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %8 = extractvalue { ptr, i32 } %7, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %8) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !293 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !295
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a15077f50f3020c3:core.Destroy.Core"(ptr %self) #0 !dbg !297 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14.x = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !299
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc14.x), !dbg !299
// CHECK:STDOUT:   ret void, !dbg !299
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a15077f50f3020c3:core.Destroy.Core"(ptr %self) #0 !dbg !301 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a15077f50f3020c3:core.Destroy.Core"(ptr %self), !dbg !303
// CHECK:STDOUT:   ret void, !dbg !303
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.187891c9c3c64ff5:core.Destroy.Core"(ptr %self) #0 !dbg !305 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14.x = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !307
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc14.x), !dbg !307
// CHECK:STDOUT:   ret void, !dbg !307
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.187891c9c3c64ff5:core.Destroy.Core"(ptr %self) #0 !dbg !309 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.187891c9c3c64ff5:core.Destroy.Core"(ptr %self), !dbg !311
// CHECK:STDOUT:   ret void, !dbg !311
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local i32 @_Z2IdIN6Carbon5PointEET_S2_(i32 %x.coerce) #3 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca %"class.Carbon::Point.18", align 4
// CHECK:STDOUT:   %x = alloca %"class.Carbon::Point.18", align 4
// CHECK:STDOUT:   %coerce.dive = getelementptr inbounds nuw %"class.Carbon::Point.18", ptr %x, i32 0, i32 0
// CHECK:STDOUT:   store i32 %x.coerce, ptr %coerce.dive, align 4
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %retval, ptr align 4 %x, i64 4, i1 false), !tbaa.struct !316
// CHECK:STDOUT:   %coerce.dive1 = getelementptr inbounds nuw %"class.Carbon::Point.18", ptr %retval, i32 0, i32 0
// CHECK:STDOUT:   %0 = load i32, ptr %coerce.dive1, align 4
// CHECK:STDOUT:   ret i32 %0
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #2
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #4
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #5 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.187891c9c3c64ff5:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!277}
// CHECK:STDOUT: !llvm.module.flags = !{!116, !117, !118, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!120}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{!6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{null, !7}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !107 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !108 = !{!"omnipotent char", !107, i64 0}
// CHECK:STDOUT: !109 = !{!"any pointer", !108, i64 0}
// CHECK:STDOUT: !112 = !{!"int", !108, i64 0}
// CHECK:STDOUT: !113 = !{!112, !112, i64 0}
// CHECK:STDOUT: !116 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !117 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !118 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !119 = !{!"__libc_errno", !112, i64 0}
// CHECK:STDOUT: !120 = !{!119, !112, i64 0}
// CHECK:STDOUT: !276 = !DIFile(filename: "exported_class_argument.carbon", directory: "")
// CHECK:STDOUT: !277 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !276, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !278 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Point.Main:Copy.Core", scope: null, file: !276, line: 9, type: !9, spFlags: DISPFlagDefinition, unit: !277, retainedNodes: !286)
// CHECK:STDOUT: !279 = !DILocalVariable(arg: 1, scope: !278, type: !7)
// CHECK:STDOUT: !283 = !DILocation(line: 9, column: 40, scope: !278)
// CHECK:STDOUT: !284 = !DILocation(line: 9, column: 34, scope: !278)
// CHECK:STDOUT: !285 = !DILocation(line: 9, column: 27, scope: !278)
// CHECK:STDOUT: !286 = !{!279}
// CHECK:STDOUT: !287 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !276, line: 13, type: !11, spFlags: DISPFlagDefinition, unit: !277)
// CHECK:STDOUT: !290 = !DILocation(line: 14, column: 17, scope: !287)
// CHECK:STDOUT: !291 = !DILocation(line: 14, column: 10, scope: !287)
// CHECK:STDOUT: !292 = !DILocation(line: 14, column: 3, scope: !287)
// CHECK:STDOUT: !293 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !276, line: 14, type: !13, spFlags: DISPFlagDefinition, unit: !277, retainedNodes: !296)
// CHECK:STDOUT: !294 = !DILocalVariable(arg: 1, scope: !293, type: !6)
// CHECK:STDOUT: !295 = !DILocation(line: 14, column: 10, scope: !293)
// CHECK:STDOUT: !296 = !{!294}
// CHECK:STDOUT: !297 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a15077f50f3020c3:core.Destroy.Core", scope: null, file: !276, line: 14, type: !15, spFlags: DISPFlagDefinition, unit: !277, retainedNodes: !300)
// CHECK:STDOUT: !298 = !DILocalVariable(arg: 1, scope: !297, type: !7)
// CHECK:STDOUT: !299 = !DILocation(line: 14, column: 10, scope: !297)
// CHECK:STDOUT: !300 = !{!298}
// CHECK:STDOUT: !301 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a15077f50f3020c3:core.Destroy.Core", scope: null, file: !276, line: 14, type: !15, spFlags: DISPFlagDefinition, unit: !277, retainedNodes: !304)
// CHECK:STDOUT: !302 = !DILocalVariable(arg: 1, scope: !301, type: !7)
// CHECK:STDOUT: !303 = !DILocation(line: 14, column: 10, scope: !301)
// CHECK:STDOUT: !304 = !{!302}
// CHECK:STDOUT: !305 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.187891c9c3c64ff5:core.Destroy.Core", scope: null, file: !276, line: 14, type: !15, spFlags: DISPFlagDefinition, unit: !277, retainedNodes: !308)
// CHECK:STDOUT: !306 = !DILocalVariable(arg: 1, scope: !305, type: !7)
// CHECK:STDOUT: !307 = !DILocation(line: 14, column: 10, scope: !305)
// CHECK:STDOUT: !308 = !{!306}
// CHECK:STDOUT: !309 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.187891c9c3c64ff5:core.Destroy.Core", scope: null, file: !276, line: 14, type: !15, spFlags: DISPFlagDefinition, unit: !277, retainedNodes: !312)
// CHECK:STDOUT: !310 = !DILocalVariable(arg: 1, scope: !309, type: !7)
// CHECK:STDOUT: !311 = !DILocation(line: 14, column: 10, scope: !309)
// CHECK:STDOUT: !312 = !{!310}
// CHECK:STDOUT: !313 = !{!"p1 _ZTSN6Carbon5PointE", !109, i64 0}
// CHECK:STDOUT: !314 = !{!313, !313, i64 0}
// CHECK:STDOUT: !316 = !{i64 0, i64 4, !113}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'todo_discarded_temporary_not_destroyed.carbon'
// CHECK:STDOUT: source_filename = "todo_discarded_temporary_not_destroyed.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %struct.Loud.21 = type { i32 }
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZN4LoudIiED2Ev = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z8MakeLoudIiE4LoudIT_ES1_ = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $destroyed = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [75 x i8] c"carbon: C++ exception escaped into Carbon through `MakeLoud`; terminating\0A\00", align 1
// CHECK:STDOUT: @destroyed = linkonce_odr dso_local global i32 0, comdat, align 4
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CDiscardConcrete.Main(i32 %v) #0 !dbg !321 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14_17.1.temp = alloca [4 x i8], align 4, !dbg !325
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc14_17.1.temp), !dbg !325
// CHECK:STDOUT:   call void @_Z8MakeLoudIiE4LoudIT_ES1_.carbon_thunk._(i32 %v, ptr %.loc14_17.1.temp), !dbg !325
// CHECK:STDOUT:   call void @"_CSelfDestruct.f059966b21c1e6ea:core.Destroy.Core"(ptr %.loc14_17.1.temp), !dbg !325
// CHECK:STDOUT:   ret void, !dbg !326
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z8MakeLoudIiE4LoudIT_ES1_.carbon_thunk._(i32 noundef %v, ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.addr = alloca i32, align 4
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store i32 %v, ptr %v.addr, align 4, !tbaa !113
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !115
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !115
// CHECK:STDOUT:   %1 = load i32, ptr %v.addr, align 4, !tbaa !113
// CHECK:STDOUT:   invoke void @_Z8MakeLoudIiE4LoudIT_ES1_(ptr dead_on_unwind writable sret(%struct.Loud.21) align 4 %0, i32 noundef %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %2 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %2, 0
// CHECK:STDOUT:   store ptr %3, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %2, 1
// CHECK:STDOUT:   store i32 %4, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 74) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %7) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local void @_ZN4LoudIiED2Ev(ptr noundef nonnull align 4 dead_on_return(4) dereferenceable(4) %this) unnamed_addr #2 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !115
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %0 = load i32, ptr @destroyed, align 4, !tbaa !113
// CHECK:STDOUT:   %inc = add nsw i32 %0, 1
// CHECK:STDOUT:   store i32 %inc, ptr @destroyed, align 4, !tbaa !113
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f059966b21c1e6ea:core.Destroy.Core"(ptr %self) #0 !dbg !328 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN4LoudIiED2Ev(ptr %self), !dbg !330
// CHECK:STDOUT:   ret void, !dbg !330
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main() #0 !dbg !332 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiscardDeferred.Main.84588f41d61dafba(i32 1), !dbg !333
// CHECK:STDOUT:   call void @_CDiscardConcrete.Main(i32 2), !dbg !334
// CHECK:STDOUT:   ret void, !dbg !335
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #3
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiscardDeferred.Main.84588f41d61dafba(i32 %v) #0 !dbg !336 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.bc2.temp = alloca [4 x i8], align 4, !dbg !340
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.bc2.temp), !dbg !340
// CHECK:STDOUT:   call void @_Z8MakeLoudIiE4LoudIT_ES1_.carbon_thunk._(i32 %v, ptr %.bc2.temp), !dbg !340
// CHECK:STDOUT:   ret void, !dbg !341
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local void @_Z8MakeLoudIiE4LoudIT_ES1_(ptr dead_on_unwind noalias writable sret(%struct.Loud.21) align 4 %agg.result, i32 noundef %v) #2 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %result.ptr = alloca ptr, align 8
// CHECK:STDOUT:   %v.addr = alloca i32, align 4
// CHECK:STDOUT:   store ptr %agg.result, ptr %result.ptr, align 8
// CHECK:STDOUT:   store i32 %v, ptr %v.addr, align 4, !tbaa !113
// CHECK:STDOUT:   %value = getelementptr inbounds nuw %struct.Loud.21, ptr %agg.result, i32 0, i32 0
// CHECK:STDOUT:   %0 = load i32, ptr %v.addr, align 4, !tbaa !113
// CHECK:STDOUT:   store i32 %0, ptr %value, align 4, !tbaa !344
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #4
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #5 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #3 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!318}
// CHECK:STDOUT: !llvm.module.flags = !{!116, !117, !118, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!120}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !12 = !{null, !6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{null, !7}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !107 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !108 = !{!"omnipotent char", !107, i64 0}
// CHECK:STDOUT: !109 = !{!"any pointer", !108, i64 0}
// CHECK:STDOUT: !112 = !{!"int", !108, i64 0}
// CHECK:STDOUT: !113 = !{!112, !112, i64 0}
// CHECK:STDOUT: !114 = !{!"p1 _ZTS4LoudIiE", !109, i64 0}
// CHECK:STDOUT: !115 = !{!114, !114, i64 0}
// CHECK:STDOUT: !116 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !117 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !118 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !119 = !{!"__libc_errno", !112, i64 0}
// CHECK:STDOUT: !120 = !{!119, !112, i64 0}
// CHECK:STDOUT: !317 = !DIFile(filename: "todo_discarded_temporary_not_destroyed.carbon", directory: "")
// CHECK:STDOUT: !318 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !317, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !319 = !{null}
// CHECK:STDOUT: !320 = !DISubroutineType(types: !319)
// CHECK:STDOUT: !321 = distinct !DISubprogram(name: "DiscardConcrete", linkageName: "_CDiscardConcrete.Main", scope: null, file: !317, line: 13, type: !13, spFlags: DISPFlagDefinition, unit: !318, retainedNodes: !327)
// CHECK:STDOUT: !322 = !DILocalVariable(arg: 1, scope: !321, type: !6)
// CHECK:STDOUT: !325 = !DILocation(line: 14, column: 3, scope: !321)
// CHECK:STDOUT: !326 = !DILocation(line: 13, column: 1, scope: !321)
// CHECK:STDOUT: !327 = !{!322}
// CHECK:STDOUT: !328 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f059966b21c1e6ea:core.Destroy.Core", scope: null, file: !317, line: 14, type: !15, spFlags: DISPFlagDefinition, unit: !318, retainedNodes: !331)
// CHECK:STDOUT: !329 = !DILocalVariable(arg: 1, scope: !328, type: !7)
// CHECK:STDOUT: !330 = !DILocation(line: 14, column: 3, scope: !328)
// CHECK:STDOUT: !331 = !{!329}
// CHECK:STDOUT: !332 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !317, line: 17, type: !320, spFlags: DISPFlagDefinition, unit: !318)
// CHECK:STDOUT: !333 = !DILocation(line: 18, column: 3, scope: !332)
// CHECK:STDOUT: !334 = !DILocation(line: 19, column: 3, scope: !332)
// CHECK:STDOUT: !335 = !DILocation(line: 17, column: 1, scope: !332)
// CHECK:STDOUT: !336 = distinct !DISubprogram(name: "DiscardDeferred", linkageName: "_CDiscardDeferred.Main.84588f41d61dafba", scope: null, file: !317, line: 9, type: !13, spFlags: DISPFlagDefinition, unit: !318, retainedNodes: !342)
// CHECK:STDOUT: !337 = !DILocalVariable(arg: 1, scope: !336, type: !6)
// CHECK:STDOUT: !340 = !DILocation(line: 10, column: 3, scope: !336)
// CHECK:STDOUT: !341 = !DILocation(line: 9, column: 1, scope: !336)
// CHECK:STDOUT: !342 = !{!337}
// CHECK:STDOUT: !343 = !{!"_ZTS4LoudIiE", !112, i64 0}
// CHECK:STDOUT: !344 = !{!343, !112, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'store_generic_call_result.carbon'
// CHECK:STDOUT: source_filename = "store_generic_call_result.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: @IntBox.val = internal constant { i32 } { i32 4 }
// CHECK:STDOUT: @IntBox.val.loc36_48.3 = internal constant { i32 } { i32 4 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CFirst.IntBox.Main:Container.Main"(ptr %self) #0 !dbg !347 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_40.1.x = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !352
// CHECK:STDOUT:   %.loc16_40.2 = load i32, ptr %.loc16_40.1.x, align 4, !dbg !352
// CHECK:STDOUT:   ret i32 %.loc16_40.2, !dbg !353
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !355 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc36_46.3.temp = alloca { i32 }, align 4, !dbg !359
// CHECK:STDOUT:   %StoreT.call = call i32 @_CStoreT.Main.4d6ceefeb7f772f4(i32 9), !dbg !358
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc36_46.3.temp), !dbg !359
// CHECK:STDOUT:   %.loc36_46.4.x = getelementptr inbounds nuw { i32 }, ptr %.loc36_46.3.temp, i32 0, i32 0, !dbg !359
// CHECK:STDOUT:   %StoreElem.call = call i32 @_CStoreElem.Main.876e6c5c61dc84e2(ptr @IntBox.val.loc36_48.3), !dbg !360
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %StoreT.call, %StoreElem.call, !dbg !358
// CHECK:STDOUT:   call void @"_CSelfDestruct.050fc244b7b40945:core.Destroy.Core"(ptr @IntBox.val), !dbg !359
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !361
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !362 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !364
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a15077f50f3020c3:core.Destroy.Core"(ptr %self) #0 !dbg !366 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc36.x = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !368
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc36.x), !dbg !368
// CHECK:STDOUT:   ret void, !dbg !368
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a15077f50f3020c3:core.Destroy.Core"(ptr %self) #0 !dbg !370 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a15077f50f3020c3:core.Destroy.Core"(ptr %self), !dbg !372
// CHECK:STDOUT:   ret void, !dbg !372
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.050fc244b7b40945:core.Destroy.Core"(ptr %self) #0 !dbg !374 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc36.x = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !376
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc36.x), !dbg !376
// CHECK:STDOUT:   ret void, !dbg !376
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.050fc244b7b40945:core.Destroy.Core"(ptr %self) #0 !dbg !378 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.050fc244b7b40945:core.Destroy.Core"(ptr %self), !dbg !380
// CHECK:STDOUT:   ret void, !dbg !380
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN3BoxIiEC1Ev.carbon_thunk.(ptr noundef %return) #1 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !189
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !189
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_COp:thunk:Default.9d4aa446d9154817.Core:Box.Cpp"(ptr sret([4 x i8]) %return) #2 !dbg !382 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN3BoxIiEC1Ev.carbon_thunk.(ptr %return), !dbg !383
// CHECK:STDOUT:   ret void, !dbg !383
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.195193979e0bd7ed:core.Destroy.Core"(ptr %self) #0 !dbg !384 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !386
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CStoreT.Main.4d6ceefeb7f772f4(i32 %x) #0 !dbg !388 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %b.var = alloca [4 x i8], align 4, !dbg !393
// CHECK:STDOUT:   %.62595d.1.temp = alloca i32, align 4, !dbg !395
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !393
// CHECK:STDOUT:   call void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.0e44c8e509b492f6"(ptr %b.var), !dbg !393
// CHECK:STDOUT:   %.b6e15a.2.value = getelementptr inbounds nuw [4 x i8], ptr %b.var, i32 0, i32 0, !dbg !395
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.62595d.1.temp), !dbg !395
// CHECK:STDOUT:   %Mk.call = call i32 @_CMk.Main.4d6ceefeb7f772f4(i32 %x), !dbg !397
// CHECK:STDOUT:   store i32 %Mk.call, ptr %.b6e15a.2.value, align 4, !dbg !395
// CHECK:STDOUT:   %.b6e15a.1.value = getelementptr inbounds nuw [4 x i8], ptr %b.var, i32 0, i32 0, !dbg !398
// CHECK:STDOUT:   %.d5e = load i32, ptr %.b6e15a.1.value, align 4, !dbg !398
// CHECK:STDOUT:   call void @"_CSelfDestruct.195193979e0bd7ed:core.Destroy.Core"(ptr %b.var), !dbg !393
// CHECK:STDOUT:   ret i32 %.d5e, !dbg !399
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #3
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CStoreElem.Main.876e6c5c61dc84e2(ptr %c) #0 !dbg !401 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %b.var = alloca [4 x i8], align 4, !dbg !406
// CHECK:STDOUT:   %.62595d.2.temp = alloca i32, align 4, !dbg !408
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !406
// CHECK:STDOUT:   call void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.0e44c8e509b492f6"(ptr %b.var), !dbg !406
// CHECK:STDOUT:   %.6adc39.2.value = getelementptr inbounds nuw [4 x i8], ptr %b.var, i32 0, i32 0, !dbg !408
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.62595d.2.temp), !dbg !408
// CHECK:STDOUT:   %Container.WithSelf.First.call = call i32 @"_CFirst.IntBox.Main:Container.Main"(ptr %c), !dbg !409
// CHECK:STDOUT:   store i32 %Container.WithSelf.First.call, ptr %.6adc39.2.value, align 4, !dbg !408
// CHECK:STDOUT:   %.6adc39.1.value = getelementptr inbounds nuw [4 x i8], ptr %b.var, i32 0, i32 0, !dbg !410
// CHECK:STDOUT:   %.bb8 = load i32, ptr %.6adc39.1.value, align 4, !dbg !410
// CHECK:STDOUT:   call void @"_CSelfDestruct.195193979e0bd7ed:core.Destroy.Core"(ptr %b.var), !dbg !406
// CHECK:STDOUT:   ret i32 %.bb8, !dbg !411
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.0e44c8e509b492f6"(ptr sret([4 x i8]) %return) #0 !dbg !413 {
// CHECK:STDOUT:   call void @"_COp:thunk:Default.9d4aa446d9154817.Core:Box.Cpp"(ptr %return), !dbg !416
// CHECK:STDOUT:   ret void, !dbg !417
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CMk.Main.4d6ceefeb7f772f4(i32 %x) #0 !dbg !418 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 %x, !dbg !424
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 0, 1, 4, 3, 2 }
// CHECK:STDOUT: uselistorder ptr @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.0e44c8e509b492f6", { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { alwaysinline nounwind }
// CHECK:STDOUT: attributes #3 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!346}
// CHECK:STDOUT: !llvm.module.flags = !{!116, !117, !118, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!120}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{null, !7}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !16 = !{!7}
// CHECK:STDOUT: !17 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !35 = !{!6, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !59 = !DIFile(filename: "./templates.h", directory: "")
// CHECK:STDOUT: !96 = !DIFile(filename: "{{.*}}/prelude/default.carbon", directory: "")
// CHECK:STDOUT: !107 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !108 = !{!"omnipotent char", !107, i64 0}
// CHECK:STDOUT: !109 = !{!"any pointer", !108, i64 0}
// CHECK:STDOUT: !112 = !{!"int", !108, i64 0}
// CHECK:STDOUT: !116 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !117 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !118 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !119 = !{!"__libc_errno", !112, i64 0}
// CHECK:STDOUT: !120 = !{!119, !112, i64 0}
// CHECK:STDOUT: !188 = !{!"p1 _ZTS3BoxIiE", !109, i64 0}
// CHECK:STDOUT: !189 = !{!188, !188, i64 0}
// CHECK:STDOUT: !226 = !{!6, !7}
// CHECK:STDOUT: !227 = !DISubroutineType(types: !226)
// CHECK:STDOUT: !345 = !DIFile(filename: "store_generic_call_result.carbon", directory: "")
// CHECK:STDOUT: !346 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !345, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !347 = distinct !DISubprogram(name: "First", linkageName: "_CFirst.IntBox.Main:Container.Main", scope: null, file: !345, line: 16, type: !227, spFlags: DISPFlagDefinition, unit: !346, retainedNodes: !354)
// CHECK:STDOUT: !348 = !DILocalVariable(arg: 1, scope: !347, type: !7)
// CHECK:STDOUT: !352 = !DILocation(line: 16, column: 36, scope: !347)
// CHECK:STDOUT: !353 = !DILocation(line: 16, column: 29, scope: !347)
// CHECK:STDOUT: !354 = !{!348}
// CHECK:STDOUT: !355 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !345, line: 35, type: !11, spFlags: DISPFlagDefinition, unit: !346)
// CHECK:STDOUT: !358 = !DILocation(line: 36, column: 10, scope: !355)
// CHECK:STDOUT: !359 = !DILocation(line: 36, column: 39, scope: !355)
// CHECK:STDOUT: !360 = !DILocation(line: 36, column: 29, scope: !355)
// CHECK:STDOUT: !361 = !DILocation(line: 36, column: 3, scope: !355)
// CHECK:STDOUT: !362 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !345, line: 36, type: !13, spFlags: DISPFlagDefinition, unit: !346, retainedNodes: !365)
// CHECK:STDOUT: !363 = !DILocalVariable(arg: 1, scope: !362, type: !6)
// CHECK:STDOUT: !364 = !DILocation(line: 36, column: 39, scope: !362)
// CHECK:STDOUT: !365 = !{!363}
// CHECK:STDOUT: !366 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a15077f50f3020c3:core.Destroy.Core", scope: null, file: !345, line: 36, type: !15, spFlags: DISPFlagDefinition, unit: !346, retainedNodes: !369)
// CHECK:STDOUT: !367 = !DILocalVariable(arg: 1, scope: !366, type: !7)
// CHECK:STDOUT: !368 = !DILocation(line: 36, column: 39, scope: !366)
// CHECK:STDOUT: !369 = !{!367}
// CHECK:STDOUT: !370 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a15077f50f3020c3:core.Destroy.Core", scope: null, file: !345, line: 36, type: !15, spFlags: DISPFlagDefinition, unit: !346, retainedNodes: !373)
// CHECK:STDOUT: !371 = !DILocalVariable(arg: 1, scope: !370, type: !7)
// CHECK:STDOUT: !372 = !DILocation(line: 36, column: 39, scope: !370)
// CHECK:STDOUT: !373 = !{!371}
// CHECK:STDOUT: !374 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.050fc244b7b40945:core.Destroy.Core", scope: null, file: !345, line: 36, type: !15, spFlags: DISPFlagDefinition, unit: !346, retainedNodes: !377)
// CHECK:STDOUT: !375 = !DILocalVariable(arg: 1, scope: !374, type: !7)
// CHECK:STDOUT: !376 = !DILocation(line: 36, column: 39, scope: !374)
// CHECK:STDOUT: !377 = !{!375}
// CHECK:STDOUT: !378 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.050fc244b7b40945:core.Destroy.Core", scope: null, file: !345, line: 36, type: !15, spFlags: DISPFlagDefinition, unit: !346, retainedNodes: !381)
// CHECK:STDOUT: !379 = !DILocalVariable(arg: 1, scope: !378, type: !7)
// CHECK:STDOUT: !380 = !DILocation(line: 36, column: 39, scope: !378)
// CHECK:STDOUT: !381 = !{!379}
// CHECK:STDOUT: !382 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:Default.9d4aa446d9154817.Core:Box.Cpp", scope: null, file: !59, line: 7, type: !17, spFlags: DISPFlagDefinition, unit: !346)
// CHECK:STDOUT: !383 = !DILocation(line: 7, column: 29, scope: !382)
// CHECK:STDOUT: !384 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.195193979e0bd7ed:core.Destroy.Core", scope: null, file: !345, line: 24, type: !15, spFlags: DISPFlagDefinition, unit: !346, retainedNodes: !387)
// CHECK:STDOUT: !385 = !DILocalVariable(arg: 1, scope: !384, type: !7)
// CHECK:STDOUT: !386 = !DILocation(line: 24, column: 3, scope: !384)
// CHECK:STDOUT: !387 = !{!385}
// CHECK:STDOUT: !388 = distinct !DISubprogram(name: "StoreT", linkageName: "_CStoreT.Main.4d6ceefeb7f772f4", scope: null, file: !345, line: 23, type: !36, spFlags: DISPFlagDefinition, unit: !346, retainedNodes: !400)
// CHECK:STDOUT: !389 = !DILocalVariable(arg: 1, scope: !388, type: !6)
// CHECK:STDOUT: !393 = !DILocation(line: 24, column: 3, scope: !388)
// CHECK:STDOUT: !395 = !DILocation(line: 25, column: 3, scope: !388)
// CHECK:STDOUT: !397 = !DILocation(line: 25, column: 13, scope: !388)
// CHECK:STDOUT: !398 = !DILocation(line: 26, column: 10, scope: !388)
// CHECK:STDOUT: !399 = !DILocation(line: 26, column: 3, scope: !388)
// CHECK:STDOUT: !400 = !{!389}
// CHECK:STDOUT: !401 = distinct !DISubprogram(name: "StoreElem", linkageName: "_CStoreElem.Main.876e6c5c61dc84e2", scope: null, file: !345, line: 29, type: !227, spFlags: DISPFlagDefinition, unit: !346, retainedNodes: !412)
// CHECK:STDOUT: !402 = !DILocalVariable(arg: 1, scope: !401, type: !7)
// CHECK:STDOUT: !406 = !DILocation(line: 30, column: 3, scope: !401)
// CHECK:STDOUT: !408 = !DILocation(line: 31, column: 3, scope: !401)
// CHECK:STDOUT: !409 = !DILocation(line: 31, column: 13, scope: !401)
// CHECK:STDOUT: !410 = !DILocation(line: 32, column: 10, scope: !401)
// CHECK:STDOUT: !411 = !DILocation(line: 32, column: 3, scope: !401)
// CHECK:STDOUT: !412 = !{!402}
// CHECK:STDOUT: !413 = distinct !DISubprogram(name: "Op", linkageName: "_COp.51f3fb62cb986374:DefaultOrUnformed.Core.0e44c8e509b492f6", scope: null, file: !96, line: 47, type: !17, spFlags: DISPFlagDefinition, unit: !346)
// CHECK:STDOUT: !416 = !DILocation(line: 48, column: 12, scope: !413)
// CHECK:STDOUT: !417 = !DILocation(line: 48, column: 5, scope: !413)
// CHECK:STDOUT: !418 = distinct !DISubprogram(name: "Mk", linkageName: "_CMk.Main.4d6ceefeb7f772f4", scope: null, file: !345, line: 6, type: !36, spFlags: DISPFlagDefinition, unit: !346, retainedNodes: !425)
// CHECK:STDOUT: !419 = !DILocalVariable(arg: 1, scope: !418, type: !6)
// CHECK:STDOUT: !424 = !DILocation(line: 6, column: 34, scope: !418)
// CHECK:STDOUT: !425 = !{!419}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'nested_alias_through_specific.carbon'
// CHECK:STDOUT: source_filename = "nested_alias_through_specific.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZN6TraitsIlE4sizeE = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZN6TraitsIsE4sizeE = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @_ZN6TraitsIlE4sizeE = linkonce_odr dso_local constant i32 8, comdat, align 4
// CHECK:STDOUT: @_ZN6TraitsIsE4sizeE = linkonce_odr dso_local constant i32 2, comdat, align 4
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CTake.Main(i32 %n) #0 !dbg !428 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 %n, !dbg !434
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !436 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Take.call = call i32 @_CTake.Main(i32 2), !dbg !441
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Take.call, 8, !dbg !441
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !443
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!427}
// CHECK:STDOUT: !llvm.module.flags = !{!116, !117, !118, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!120}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !10 = !{!6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !35 = !{!6, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !107 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !108 = !{!"omnipotent char", !107, i64 0}
// CHECK:STDOUT: !112 = !{!"int", !108, i64 0}
// CHECK:STDOUT: !116 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !117 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !118 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !119 = !{!"__libc_errno", !112, i64 0}
// CHECK:STDOUT: !120 = !{!119, !112, i64 0}
// CHECK:STDOUT: !426 = !DIFile(filename: "nested_alias_through_specific.carbon", directory: "")
// CHECK:STDOUT: !427 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !426, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !428 = distinct !DISubprogram(name: "Take", linkageName: "_CTake.Main", scope: null, file: !426, line: 28, type: !36, spFlags: DISPFlagDefinition, unit: !427, retainedNodes: !435)
// CHECK:STDOUT: !429 = !DILocalVariable(arg: 1, scope: !428, type: !6)
// CHECK:STDOUT: !434 = !DILocation(line: 28, column: 26, scope: !428)
// CHECK:STDOUT: !435 = !{!429}
// CHECK:STDOUT: !436 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !426, line: 30, type: !11, spFlags: DISPFlagDefinition, unit: !427)
// CHECK:STDOUT: !441 = !DILocation(line: 32, column: 10, scope: !436)
// CHECK:STDOUT: !443 = !DILocation(line: 32, column: 3, scope: !436)
// CHECK:STDOUT:

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
// CHECK:STDOUT: ; ModuleID = 'alias_of_member_type.carbon'
// CHECK:STDOUT: source_filename = "alias_of_member_type.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !150 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %C.Make.call = call i32 @_CMake.C.Main.9eb1010069919743(i32 5), !dbg !153
// CHECK:STDOUT:   ret i32 %C.Make.call, !dbg !154
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !155 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !157
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CMake.C.Main.9eb1010069919743(i32 %v) #0 !dbg !159 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %b.var = alloca i32, align 4, !dbg !164
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !164
// CHECK:STDOUT:   store i32 poison, ptr %b.var, align 4, !dbg !164
// CHECK:STDOUT:   store i32 %v, ptr %b.var, align 4, !dbg !166
// CHECK:STDOUT:   %.628 = load i32, ptr %b.var, align 4, !dbg !168
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %b.var), !dbg !164
// CHECK:STDOUT:   ret i32 %.628, !dbg !169
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!149}
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
// CHECK:STDOUT: !148 = !DIFile(filename: "alias_of_member_type.carbon", directory: "")
// CHECK:STDOUT: !149 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !148, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !150 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !148, line: 19, type: !11, spFlags: DISPFlagDefinition, unit: !149)
// CHECK:STDOUT: !153 = !DILocation(line: 20, column: 10, scope: !150)
// CHECK:STDOUT: !154 = !DILocation(line: 20, column: 3, scope: !150)
// CHECK:STDOUT: !155 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !148, line: 13, type: !13, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !158)
// CHECK:STDOUT: !156 = !DILocalVariable(arg: 1, scope: !155, type: !6)
// CHECK:STDOUT: !157 = !DILocation(line: 13, column: 5, scope: !155)
// CHECK:STDOUT: !158 = !{!156}
// CHECK:STDOUT: !159 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.C.Main.9eb1010069919743", scope: null, file: !148, line: 12, type: !36, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !170)
// CHECK:STDOUT: !160 = !DILocalVariable(arg: 1, scope: !159, type: !6)
// CHECK:STDOUT: !164 = !DILocation(line: 13, column: 5, scope: !159)
// CHECK:STDOUT: !166 = !DILocation(line: 14, column: 5, scope: !159)
// CHECK:STDOUT: !168 = !DILocation(line: 15, column: 12, scope: !159)
// CHECK:STDOUT: !169 = !DILocation(line: 15, column: 5, scope: !159)
// CHECK:STDOUT: !170 = !{!160}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'generic_class_field.carbon'
// CHECK:STDOUT: source_filename = "generic_class_field.carbon"
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
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !175 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %h.var = alloca { [4 x i8] }, align 4, !dbg !178
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %h.var), !dbg !178
// CHECK:STDOUT:   %.loc15_52.1.b = getelementptr inbounds nuw { [4 x i8] }, ptr %h.var, i32 0, i32 0, !dbg !179
// CHECK:STDOUT:   call void @_Z7MakeBoxIiE3BoxIT_ES1_.carbon_thunk._(i32 60, ptr %.loc15_52.1.b), !dbg !180
// CHECK:STDOUT:   %Get.call = call i32 @_CGet.Main.84588f41d61dafba(ptr %h.var), !dbg !183
// CHECK:STDOUT:   call void @"_CSelfDestruct.cdff7e2d24e00bd0:core.Destroy.Core"(ptr %h.var), !dbg !178
// CHECK:STDOUT:   ret i32 %Get.call, !dbg !186
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
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !216
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !216
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
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.195193979e0bd7ed:core.Destroy.Core"(ptr %self) #0 !dbg !187 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !189
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.21f7819eefb2b4ab:core.Destroy.Core"(ptr %self) #0 !dbg !191 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc15.b = getelementptr inbounds nuw { [4 x i8] }, ptr %self, i32 0, i32 0, !dbg !193
// CHECK:STDOUT:   call void @"_CSelfDestruct.195193979e0bd7ed:core.Destroy.Core"(ptr %.loc15.b), !dbg !193
// CHECK:STDOUT:   ret void, !dbg !193
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.21f7819eefb2b4ab:core.Destroy.Core"(ptr %self) #0 !dbg !195 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.21f7819eefb2b4ab:core.Destroy.Core"(ptr %self), !dbg !197
// CHECK:STDOUT:   ret void, !dbg !197
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.cdff7e2d24e00bd0:core.Destroy.Core"(ptr %self) #0 !dbg !199 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc15.b = getelementptr inbounds nuw { [4 x i8] }, ptr %self, i32 0, i32 0, !dbg !201
// CHECK:STDOUT:   call void @"_CSelfDestruct.195193979e0bd7ed:core.Destroy.Core"(ptr %.loc15.b), !dbg !201
// CHECK:STDOUT:   ret void, !dbg !201
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.cdff7e2d24e00bd0:core.Destroy.Core"(ptr %self) #0 !dbg !203 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.cdff7e2d24e00bd0:core.Destroy.Core"(ptr %self), !dbg !205
// CHECK:STDOUT:   ret void, !dbg !205
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Main.84588f41d61dafba(ptr %h) #0 !dbg !207 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc11_11.1.b = getelementptr inbounds nuw { [4 x i8] }, ptr %h, i32 0, i32 0, !dbg !212
// CHECK:STDOUT:   %.087.value = getelementptr inbounds nuw [4 x i8], ptr %.loc11_11.1.b, i32 0, i32 0, !dbg !212
// CHECK:STDOUT:   %.b25 = load i32, ptr %.087.value, align 4, !dbg !212
// CHECK:STDOUT:   ret i32 %.b25, !dbg !213
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
// CHECK:STDOUT:   store i32 %0, ptr %value, align 4, !tbaa !218
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!172}
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
// CHECK:STDOUT: !171 = !DIFile(filename: "generic_class_field.carbon", directory: "")
// CHECK:STDOUT: !172 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !171, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !175 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !171, line: 14, type: !11, spFlags: DISPFlagDefinition, unit: !172)
// CHECK:STDOUT: !178 = !DILocation(line: 15, column: 3, scope: !175)
// CHECK:STDOUT: !179 = !DILocation(line: 15, column: 24, scope: !175)
// CHECK:STDOUT: !180 = !DILocation(line: 15, column: 30, scope: !175)
// CHECK:STDOUT: !183 = !DILocation(line: 16, column: 10, scope: !175)
// CHECK:STDOUT: !184 = !{!6, !7}
// CHECK:STDOUT: !185 = !DISubroutineType(types: !184)
// CHECK:STDOUT: !186 = !DILocation(line: 16, column: 3, scope: !175)
// CHECK:STDOUT: !187 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.195193979e0bd7ed:core.Destroy.Core", scope: null, file: !171, line: 15, type: !15, spFlags: DISPFlagDefinition, unit: !172, retainedNodes: !190)
// CHECK:STDOUT: !188 = !DILocalVariable(arg: 1, scope: !187, type: !7)
// CHECK:STDOUT: !189 = !DILocation(line: 15, column: 3, scope: !187)
// CHECK:STDOUT: !190 = !{!188}
// CHECK:STDOUT: !191 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.21f7819eefb2b4ab:core.Destroy.Core", scope: null, file: !171, line: 15, type: !15, spFlags: DISPFlagDefinition, unit: !172, retainedNodes: !194)
// CHECK:STDOUT: !192 = !DILocalVariable(arg: 1, scope: !191, type: !7)
// CHECK:STDOUT: !193 = !DILocation(line: 15, column: 3, scope: !191)
// CHECK:STDOUT: !194 = !{!192}
// CHECK:STDOUT: !195 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.21f7819eefb2b4ab:core.Destroy.Core", scope: null, file: !171, line: 15, type: !15, spFlags: DISPFlagDefinition, unit: !172, retainedNodes: !198)
// CHECK:STDOUT: !196 = !DILocalVariable(arg: 1, scope: !195, type: !7)
// CHECK:STDOUT: !197 = !DILocation(line: 15, column: 3, scope: !195)
// CHECK:STDOUT: !198 = !{!196}
// CHECK:STDOUT: !199 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.cdff7e2d24e00bd0:core.Destroy.Core", scope: null, file: !171, line: 15, type: !15, spFlags: DISPFlagDefinition, unit: !172, retainedNodes: !202)
// CHECK:STDOUT: !200 = !DILocalVariable(arg: 1, scope: !199, type: !7)
// CHECK:STDOUT: !201 = !DILocation(line: 15, column: 3, scope: !199)
// CHECK:STDOUT: !202 = !{!200}
// CHECK:STDOUT: !203 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.cdff7e2d24e00bd0:core.Destroy.Core", scope: null, file: !171, line: 15, type: !15, spFlags: DISPFlagDefinition, unit: !172, retainedNodes: !206)
// CHECK:STDOUT: !204 = !DILocalVariable(arg: 1, scope: !203, type: !7)
// CHECK:STDOUT: !205 = !DILocation(line: 15, column: 3, scope: !203)
// CHECK:STDOUT: !206 = !{!204}
// CHECK:STDOUT: !207 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Main.84588f41d61dafba", scope: null, file: !171, line: 10, type: !185, spFlags: DISPFlagDefinition, unit: !172, retainedNodes: !214)
// CHECK:STDOUT: !208 = !DILocalVariable(arg: 1, scope: !207, type: !7)
// CHECK:STDOUT: !212 = !DILocation(line: 11, column: 10, scope: !207)
// CHECK:STDOUT: !213 = !DILocation(line: 11, column: 3, scope: !207)
// CHECK:STDOUT: !214 = !{!208}
// CHECK:STDOUT: !215 = !{!"p1 _ZTS3BoxIiE", !109, i64 0}
// CHECK:STDOUT: !216 = !{!215, !215, i64 0}
// CHECK:STDOUT: !217 = !{!"_ZTS3BoxIiE", !112, i64 0}
// CHECK:STDOUT: !218 = !{!217, !112, i64 0}
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
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !222 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %PlainOf.call = call i32 @_CPlainOf.Main.f249b435619a5146(i64 1), !dbg !225
// CHECK:STDOUT:   %.loc11_23 = load i32, ptr @_Z5PlainIiE, align 4, !dbg !228
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc11_23, %PlainOf.call, !dbg !228
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !229
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CPlainOf.Main.f249b435619a5146(i64 %v) #0 !dbg !230 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.1a6 = load i32, ptr @_Z5PlainIlE, align 4, !dbg !236
// CHECK:STDOUT:   ret i32 %.1a6, !dbg !235
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!220}
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
// CHECK:STDOUT: !219 = !DIFile(filename: "var_template.carbon", directory: "")
// CHECK:STDOUT: !220 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !219, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !221 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !222 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !219, line: 10, type: !11, spFlags: DISPFlagDefinition, unit: !220)
// CHECK:STDOUT: !225 = !DILocation(line: 11, column: 27, scope: !222)
// CHECK:STDOUT: !226 = !{!6, !221}
// CHECK:STDOUT: !227 = !DISubroutineType(types: !226)
// CHECK:STDOUT: !228 = !DILocation(line: 11, column: 10, scope: !222)
// CHECK:STDOUT: !229 = !DILocation(line: 11, column: 3, scope: !222)
// CHECK:STDOUT: !230 = distinct !DISubprogram(name: "PlainOf", linkageName: "_CPlainOf.Main.f249b435619a5146", scope: null, file: !219, line: 6, type: !227, spFlags: DISPFlagDefinition, unit: !220, retainedNodes: !237)
// CHECK:STDOUT: !231 = !DILocalVariable(arg: 1, scope: !230, type: !221)
// CHECK:STDOUT: !235 = !DILocation(line: 7, column: 3, scope: !230)
// CHECK:STDOUT: !236 = !DILocation(line: 7, column: 10, scope: !230)
// CHECK:STDOUT: !237 = !{!231}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'exported_class_argument.carbon'
// CHECK:STDOUT: source_filename = "exported_class_argument.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %"class.Carbon::Point.13" = type { i32 }
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
// CHECK:STDOUT: define void @"_COp.Point.Main:Copy.Core"(ptr sret({ i32 }) %return, ptr %self) #0 !dbg !240 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_44.1.x = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !245
// CHECK:STDOUT:   %.loc9_44.2 = load i32, ptr %.loc9_44.1.x, align 4, !dbg !245
// CHECK:STDOUT:   %.loc9_46.2.x = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !246
// CHECK:STDOUT:   store i32 %.loc9_44.2, ptr %.loc9_46.2.x, align 4, !dbg !246
// CHECK:STDOUT:   ret void, !dbg !247
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !249 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14_24.3.temp = alloca { i32 }, align 4, !dbg !252
// CHECK:STDOUT:   %.loc14_34.1.temp = alloca { i32 }, align 4, !dbg !253
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc14_24.3.temp), !dbg !252
// CHECK:STDOUT:   %.loc14_24.4.x = getelementptr inbounds nuw { i32 }, ptr %.loc14_24.3.temp, i32 0, i32 0, !dbg !252
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc14_34.1.temp), !dbg !253
// CHECK:STDOUT:   call void @_Z2IdIN6Carbon5PointEET_S2_.carbon_thunk._(ptr @Point.val.loc14_26.3, ptr %.loc14_34.1.temp), !dbg !253
// CHECK:STDOUT:   %.loc14_35.1.x = getelementptr inbounds nuw { i32 }, ptr %.loc14_34.1.temp, i32 0, i32 0, !dbg !253
// CHECK:STDOUT:   %.loc14_35.2 = load i32, ptr %.loc14_35.1.x, align 4, !dbg !253
// CHECK:STDOUT:   call void @"_CSelfDestruct.187891c9c3c64ff5:core.Destroy.Core"(ptr %.loc14_34.1.temp), !dbg !253
// CHECK:STDOUT:   call void @"_CSelfDestruct.187891c9c3c64ff5:core.Destroy.Core"(ptr @Point.val), !dbg !252
// CHECK:STDOUT:   ret i32 %.loc14_35.2, !dbg !254
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z2IdIN6Carbon5PointEET_S2_.carbon_thunk._(ptr noundef %x, ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.addr = alloca ptr, align 8
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %agg.tmp = alloca %"class.Carbon::Point.13", align 4
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %x, ptr %x.addr, align 8, !tbaa !276
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !276
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !276
// CHECK:STDOUT:   %1 = load ptr, ptr %x.addr, align 8, !tbaa !276
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %agg.tmp, ptr align 4 %1, i64 4, i1 false), !tbaa.struct !278
// CHECK:STDOUT:   %coerce.dive = getelementptr inbounds nuw %"class.Carbon::Point.13", ptr %agg.tmp, i32 0, i32 0
// CHECK:STDOUT:   %2 = load i32, ptr %coerce.dive, align 4
// CHECK:STDOUT:   %call = invoke i32 @_Z2IdIN6Carbon5PointEET_S2_(i32 %2)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   %coerce.dive1 = getelementptr inbounds nuw %"class.Carbon::Point.13", ptr %0, i32 0, i32 0
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
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !255 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !257
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a15077f50f3020c3:core.Destroy.Core"(ptr %self) #0 !dbg !259 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14.x = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !261
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc14.x), !dbg !261
// CHECK:STDOUT:   ret void, !dbg !261
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a15077f50f3020c3:core.Destroy.Core"(ptr %self) #0 !dbg !263 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a15077f50f3020c3:core.Destroy.Core"(ptr %self), !dbg !265
// CHECK:STDOUT:   ret void, !dbg !265
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.187891c9c3c64ff5:core.Destroy.Core"(ptr %self) #0 !dbg !267 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14.x = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !269
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc14.x), !dbg !269
// CHECK:STDOUT:   ret void, !dbg !269
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.187891c9c3c64ff5:core.Destroy.Core"(ptr %self) #0 !dbg !271 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.187891c9c3c64ff5:core.Destroy.Core"(ptr %self), !dbg !273
// CHECK:STDOUT:   ret void, !dbg !273
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local i32 @_Z2IdIN6Carbon5PointEET_S2_(i32 %x.coerce) #3 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca %"class.Carbon::Point.13", align 4
// CHECK:STDOUT:   %x = alloca %"class.Carbon::Point.13", align 4
// CHECK:STDOUT:   %coerce.dive = getelementptr inbounds nuw %"class.Carbon::Point.13", ptr %x, i32 0, i32 0
// CHECK:STDOUT:   store i32 %x.coerce, ptr %coerce.dive, align 4
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %retval, ptr align 4 %x, i64 4, i1 false), !tbaa.struct !278
// CHECK:STDOUT:   %coerce.dive1 = getelementptr inbounds nuw %"class.Carbon::Point.13", ptr %retval, i32 0, i32 0
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!239}
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
// CHECK:STDOUT: !238 = !DIFile(filename: "exported_class_argument.carbon", directory: "")
// CHECK:STDOUT: !239 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !238, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !240 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Point.Main:Copy.Core", scope: null, file: !238, line: 9, type: !9, spFlags: DISPFlagDefinition, unit: !239, retainedNodes: !248)
// CHECK:STDOUT: !241 = !DILocalVariable(arg: 1, scope: !240, type: !7)
// CHECK:STDOUT: !245 = !DILocation(line: 9, column: 40, scope: !240)
// CHECK:STDOUT: !246 = !DILocation(line: 9, column: 34, scope: !240)
// CHECK:STDOUT: !247 = !DILocation(line: 9, column: 27, scope: !240)
// CHECK:STDOUT: !248 = !{!241}
// CHECK:STDOUT: !249 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !238, line: 13, type: !11, spFlags: DISPFlagDefinition, unit: !239)
// CHECK:STDOUT: !252 = !DILocation(line: 14, column: 17, scope: !249)
// CHECK:STDOUT: !253 = !DILocation(line: 14, column: 10, scope: !249)
// CHECK:STDOUT: !254 = !DILocation(line: 14, column: 3, scope: !249)
// CHECK:STDOUT: !255 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !238, line: 14, type: !13, spFlags: DISPFlagDefinition, unit: !239, retainedNodes: !258)
// CHECK:STDOUT: !256 = !DILocalVariable(arg: 1, scope: !255, type: !6)
// CHECK:STDOUT: !257 = !DILocation(line: 14, column: 10, scope: !255)
// CHECK:STDOUT: !258 = !{!256}
// CHECK:STDOUT: !259 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a15077f50f3020c3:core.Destroy.Core", scope: null, file: !238, line: 14, type: !15, spFlags: DISPFlagDefinition, unit: !239, retainedNodes: !262)
// CHECK:STDOUT: !260 = !DILocalVariable(arg: 1, scope: !259, type: !7)
// CHECK:STDOUT: !261 = !DILocation(line: 14, column: 10, scope: !259)
// CHECK:STDOUT: !262 = !{!260}
// CHECK:STDOUT: !263 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a15077f50f3020c3:core.Destroy.Core", scope: null, file: !238, line: 14, type: !15, spFlags: DISPFlagDefinition, unit: !239, retainedNodes: !266)
// CHECK:STDOUT: !264 = !DILocalVariable(arg: 1, scope: !263, type: !7)
// CHECK:STDOUT: !265 = !DILocation(line: 14, column: 10, scope: !263)
// CHECK:STDOUT: !266 = !{!264}
// CHECK:STDOUT: !267 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.187891c9c3c64ff5:core.Destroy.Core", scope: null, file: !238, line: 14, type: !15, spFlags: DISPFlagDefinition, unit: !239, retainedNodes: !270)
// CHECK:STDOUT: !268 = !DILocalVariable(arg: 1, scope: !267, type: !7)
// CHECK:STDOUT: !269 = !DILocation(line: 14, column: 10, scope: !267)
// CHECK:STDOUT: !270 = !{!268}
// CHECK:STDOUT: !271 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.187891c9c3c64ff5:core.Destroy.Core", scope: null, file: !238, line: 14, type: !15, spFlags: DISPFlagDefinition, unit: !239, retainedNodes: !274)
// CHECK:STDOUT: !272 = !DILocalVariable(arg: 1, scope: !271, type: !7)
// CHECK:STDOUT: !273 = !DILocation(line: 14, column: 10, scope: !271)
// CHECK:STDOUT: !274 = !{!272}
// CHECK:STDOUT: !275 = !{!"p1 _ZTSN6Carbon5PointE", !109, i64 0}
// CHECK:STDOUT: !276 = !{!275, !275, i64 0}
// CHECK:STDOUT: !278 = !{i64 0, i64 4, !113}
// CHECK:STDOUT:

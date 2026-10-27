// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/tuple_segment.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/tuple_segment.carbon

// --- make_tuple.carbon
library "[[@TEST_NAME]]";

fn MakeTuple[... each T: Core.Copy](... each x: each T) -> (... each T) {
  return (... each x);
}

fn Call() -> (i64, bool, i32) {
  return MakeTuple(1 as i64, true, 2 as i32);
}

// --- let.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Code {
  fn Get(self) -> i64;
}

impl i64 as Code {
  fn Get(self) -> i64 { return self; }
}

fn Sum[... each T: Code](t: (... each T)) -> i64 {
  let (... each x: each T) = t;
  var total: i64 = 0;
  ... total = Add(total, each x.Get());
  return total;
}

fn Call(t: (i64, i64, i64)) -> i64 {
  return Sum(t);
}

// --- impl.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Code {
  fn Get(self) -> i64;
}

impl i64 as Code {
  fn Get(self) -> i64 { return self; }
}

impl forall [... each T: Code] (... each T) as Code {
  fn Get(self) -> i64 {
    let (... each x: each T) = self;
    var total: i64 = 0;
    ... total = Add(total, each x.Get());
    return total;
  }
}

fn Call(t: (i64, (i64, i64))) -> i64 {
  return t.(Code.Get)();
}

// --- one_tuple.carbon
library "[[@TEST_NAME]]";

fn MakeTuple[... each T: Core.Copy](... each x: each T) -> (... each T) {
  return (... each x);
}

fn Call() -> (i64,) {
  return MakeTuple(5 as i64);
}

// --- self_return.carbon
library "[[@TEST_NAME]]";

interface Cp {
  fn Op(self) -> Self;
}

fn Make[T: type](x: T) -> T {
  return Make(x);
}

impl forall [... each T: type] (... each T) as Cp {
  fn Op(self) -> Self { return Make(self); }
}

fn Call(t: (i64, i64, i64, i64)) -> (i64, i64, i64, i64) {
  return t.(Cp.Op)();
}

// --- impl_body.carbon
library "[[@TEST_NAME]]";

interface HasN {
  let N: i64;
}
impl i64 as HasN where .N = 3 {}
impl bool as HasN where .N = 40 {}

interface Sum {
  fn Get(self) -> i64;
}

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

impl forall [... each T: HasN] (... each T) as Sum {
  fn Get(unused self) -> i64 {
    var s: i64 = 0;
    ... s = Add(s, (each T).N);
    return s;
  }
}

fn Call(t: (i64, bool, i64)) -> i64 {
  return t.(Sum.Get)();
}

// --- impl_lib.carbon
library "[[@TEST_NAME]]";

interface HasN {
  let N: i64;
}
impl i64 as HasN where .N = 3 {}
impl bool as HasN where .N = 40 {}

interface Sum {
  fn Get(self) -> i64;
}

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

impl forall [... each T: HasN] (... each T) as Sum {
  fn Get(unused self) -> i64 {
    var s: i64 = 0;
    ... s = Add(s, (each T).N);
    return s;
  }
}

// --- impl_use.carbon
library "[[@TEST_NAME]]";

import library "impl_lib";

fn Call(t: (i64, bool, i64)) -> i64 {
  return t.(Sum.Get)();
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'make_tuple.carbon'
// CHECK:STDOUT: source_filename = "make_tuple.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @.373.loc8_22.5 = internal constant { i64, i1, i32 } { i64 1, i1 true, i32 2 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr sret({ i64, i1, i32 }) %return) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CMakeTuple.Main.6f19dc6a4aa7bfb4(ptr %return, ptr @.373.loc8_22.5), !dbg !43
// CHECK:STDOUT:   ret void, !dbg !46
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CMakeTuple.Main.6f19dc6a4aa7bfb4(ptr sret({ i64, i1, i32 }) %return, ptr %x) #0 !dbg !47 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc4_21.7.pack.elem = getelementptr inbounds { i64, i1, i32 }, ptr %x, i32 0, i32 0, !dbg !53
// CHECK:STDOUT:   %.loc4_21.7.pack.elem.load = load i64, ptr %.loc4_21.7.pack.elem, align 8, !dbg !53
// CHECK:STDOUT:   %.loc4_21.13.tuple.elem = getelementptr inbounds nuw { i64, i1, i32 }, ptr %return, i32 0, i32 0, !dbg !53
// CHECK:STDOUT:   store i64 %.loc4_21.7.pack.elem.load, ptr %.loc4_21.13.tuple.elem, align 8, !dbg !53
// CHECK:STDOUT:   %.loc4_21.7.pack.elem1 = getelementptr inbounds { i64, i1, i32 }, ptr %x, i32 0, i32 1, !dbg !53
// CHECK:STDOUT:   %.loc4_21.7.pack.elem.load2 = load i8, ptr %.loc4_21.7.pack.elem1, align 1, !dbg !53
// CHECK:STDOUT:   %.loc4_21.7 = trunc i8 %.loc4_21.7.pack.elem.load2 to i1, !dbg !53
// CHECK:STDOUT:   %.loc4_21.13.tuple.elem3 = getelementptr inbounds nuw { i64, i1, i32 }, ptr %return, i32 0, i32 1, !dbg !53
// CHECK:STDOUT:   %.loc4_21.14 = zext i1 %.loc4_21.7 to i8, !dbg !53
// CHECK:STDOUT:   store i8 %.loc4_21.14, ptr %.loc4_21.13.tuple.elem3, align 1, !dbg !53
// CHECK:STDOUT:   %.loc4_21.7.pack.elem4 = getelementptr inbounds { i64, i1, i32 }, ptr %x, i32 0, i32 2, !dbg !53
// CHECK:STDOUT:   %.loc4_21.7.pack.elem.load5 = load i32, ptr %.loc4_21.7.pack.elem4, align 4, !dbg !53
// CHECK:STDOUT:   %.loc4_21.13.tuple.elem6 = getelementptr inbounds nuw { i64, i1, i32 }, ptr %return, i32 0, i32 2, !dbg !53
// CHECK:STDOUT:   store i32 %.loc4_21.7.pack.elem.load5, ptr %.loc4_21.13.tuple.elem6, align 4, !dbg !53
// CHECK:STDOUT:   ret void, !dbg !54
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!33}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !32 = !DIFile(filename: "make_tuple.carbon", directory: "")
// CHECK:STDOUT: !33 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !32, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !36 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !37 = !{!36}
// CHECK:STDOUT: !38 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !32, line: 7, type: !38, spFlags: DISPFlagDefinition, unit: !33)
// CHECK:STDOUT: !43 = !DILocation(line: 8, column: 10, scope: !39)
// CHECK:STDOUT: !44 = !{!36, !36}
// CHECK:STDOUT: !45 = !DISubroutineType(types: !44)
// CHECK:STDOUT: !46 = !DILocation(line: 8, column: 3, scope: !39)
// CHECK:STDOUT: !47 = distinct !DISubprogram(name: "MakeTuple", linkageName: "_CMakeTuple.Main.6f19dc6a4aa7bfb4", scope: null, file: !32, line: 3, type: !45, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !55)
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !47, type: !36)
// CHECK:STDOUT: !53 = !DILocation(line: 4, column: 10, scope: !47)
// CHECK:STDOUT: !54 = !DILocation(line: 4, column: 3, scope: !47)
// CHECK:STDOUT: !55 = !{!48}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'let.carbon'
// CHECK:STDOUT: source_filename = "let.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @"_CGet.Int.9025b11fc94ef1f2.Core:Code.Main"(i64 %self) #0 !dbg !64 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i64 %self, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CCall.Main(ptr %t) #0 !dbg !76 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Sum.call = call i64 @_CSum.Main.a9e5af255b2ab841(ptr %t), !dbg !82
// CHECK:STDOUT:   ret i64 %Sum.call, !dbg !83
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CSum.Main.a9e5af255b2ab841(ptr %t) #0 !dbg !85 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.var = alloca i64, align 8, !dbg !94
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %total.var), !dbg !94
// CHECK:STDOUT:   store i64 0, ptr %total.var, align 8, !dbg !94
// CHECK:STDOUT:   %.loc16_26.5.pack.elem = getelementptr inbounds { i64, i64, i64 }, ptr %t, i32 0, i32 0, !dbg !99
// CHECK:STDOUT:   %.loc16_26.5.pack.elem.load = load i64, ptr %.loc16_26.5.pack.elem, align 8, !dbg !99
// CHECK:STDOUT:   %Code.WithSelf.Get.call = call i64 @"_CGet.Int.9025b11fc94ef1f2.Core:Code.Main"(i64 %.loc16_26.5.pack.elem.load), !dbg !99
// CHECK:STDOUT:   %.loc16_19 = load i64, ptr %total.var, align 8, !dbg !98
// CHECK:STDOUT:   %Add.call = add i64 %.loc16_19, %Code.WithSelf.Get.call, !dbg !100
// CHECK:STDOUT:   store i64 %Add.call, ptr %total.var, align 8, !dbg !97
// CHECK:STDOUT:   %.loc16_26.5.pack.elem1 = getelementptr inbounds { i64, i64, i64 }, ptr %t, i32 0, i32 1, !dbg !99
// CHECK:STDOUT:   %.loc16_26.5.pack.elem.load2 = load i64, ptr %.loc16_26.5.pack.elem1, align 8, !dbg !99
// CHECK:STDOUT:   %Code.WithSelf.Get.call3 = call i64 @"_CGet.Int.9025b11fc94ef1f2.Core:Code.Main"(i64 %.loc16_26.5.pack.elem.load2), !dbg !99
// CHECK:STDOUT:   %.loc16_194 = load i64, ptr %total.var, align 8, !dbg !98
// CHECK:STDOUT:   %Add.call5 = add i64 %.loc16_194, %Code.WithSelf.Get.call3, !dbg !100
// CHECK:STDOUT:   store i64 %Add.call5, ptr %total.var, align 8, !dbg !97
// CHECK:STDOUT:   %.loc16_26.5.pack.elem6 = getelementptr inbounds { i64, i64, i64 }, ptr %t, i32 0, i32 2, !dbg !99
// CHECK:STDOUT:   %.loc16_26.5.pack.elem.load7 = load i64, ptr %.loc16_26.5.pack.elem6, align 8, !dbg !99
// CHECK:STDOUT:   %Code.WithSelf.Get.call8 = call i64 @"_CGet.Int.9025b11fc94ef1f2.Core:Code.Main"(i64 %.loc16_26.5.pack.elem.load7), !dbg !99
// CHECK:STDOUT:   %.loc16_199 = load i64, ptr %total.var, align 8, !dbg !98
// CHECK:STDOUT:   %Add.call10 = add i64 %.loc16_199, %Code.WithSelf.Get.call8, !dbg !100
// CHECK:STDOUT:   store i64 %Add.call10, ptr %total.var, align 8, !dbg !97
// CHECK:STDOUT:   %.loc17 = load i64, ptr %total.var, align 8, !dbg !101
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %total.var), !dbg !94
// CHECK:STDOUT:   ret i64 %.loc17, !dbg !102
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!57}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !35 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !36 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !56 = !DIFile(filename: "let.carbon", directory: "")
// CHECK:STDOUT: !57 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !56, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !58 = !{!35, !35}
// CHECK:STDOUT: !59 = !DISubroutineType(types: !58)
// CHECK:STDOUT: !60 = !{null, !35}
// CHECK:STDOUT: !61 = !DISubroutineType(types: !60)
// CHECK:STDOUT: !62 = !{!35, !36}
// CHECK:STDOUT: !63 = !DISubroutineType(types: !62)
// CHECK:STDOUT: !64 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Int.9025b11fc94ef1f2.Core:Code.Main", scope: null, file: !56, line: 10, type: !59, spFlags: DISPFlagDefinition, unit: !57, retainedNodes: !71)
// CHECK:STDOUT: !65 = !DILocalVariable(arg: 1, scope: !64, type: !35)
// CHECK:STDOUT: !70 = !DILocation(line: 10, column: 25, scope: !64)
// CHECK:STDOUT: !71 = !{!65}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !56, line: 15, type: !61, spFlags: DISPFlagDefinition, unit: !57, retainedNodes: !75)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !35)
// CHECK:STDOUT: !74 = !DILocation(line: 15, column: 3, scope: !72)
// CHECK:STDOUT: !75 = !{!73}
// CHECK:STDOUT: !76 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !56, line: 20, type: !63, spFlags: DISPFlagDefinition, unit: !57, retainedNodes: !84)
// CHECK:STDOUT: !77 = !DILocalVariable(arg: 1, scope: !76, type: !36)
// CHECK:STDOUT: !82 = !DILocation(line: 21, column: 10, scope: !76)
// CHECK:STDOUT: !83 = !DILocation(line: 21, column: 3, scope: !76)
// CHECK:STDOUT: !84 = !{!77}
// CHECK:STDOUT: !85 = distinct !DISubprogram(name: "Sum", linkageName: "_CSum.Main.a9e5af255b2ab841", scope: null, file: !56, line: 13, type: !63, spFlags: DISPFlagDefinition, unit: !57, retainedNodes: !103)
// CHECK:STDOUT: !86 = !DILocalVariable(arg: 1, scope: !85, type: !36)
// CHECK:STDOUT: !94 = !DILocation(line: 15, column: 3, scope: !85)
// CHECK:STDOUT: !97 = !DILocation(line: 16, column: 7, scope: !85)
// CHECK:STDOUT: !98 = !DILocation(line: 16, column: 19, scope: !85)
// CHECK:STDOUT: !99 = !DILocation(line: 16, column: 26, scope: !85)
// CHECK:STDOUT: !100 = !DILocation(line: 16, column: 15, scope: !85)
// CHECK:STDOUT: !101 = !DILocation(line: 17, column: 10, scope: !85)
// CHECK:STDOUT: !102 = !DILocation(line: 17, column: 3, scope: !85)
// CHECK:STDOUT: !103 = !{!86}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'impl.carbon'
// CHECK:STDOUT: source_filename = "impl.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @"_CGet.Int.9025b11fc94ef1f2.Core:Code.Main"(i64 %self) #0 !dbg !106 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i64 %self, !dbg !112
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !114 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !116
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CCall.Main(ptr %t) #0 !dbg !118 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get.call = call i64 @"_CGet.95020fcee389aab0:Code.Main.b2bd9f44fc9c07bd"(ptr %t), !dbg !123
// CHECK:STDOUT:   ret i64 %tuple.type.as.Code.impl.Get.call, !dbg !124
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CGet.95020fcee389aab0:Code.Main.b2bd9f44fc9c07bd"(ptr %self) #0 !dbg !126 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.var = alloca i64, align 8, !dbg !135
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %total.var), !dbg !135
// CHECK:STDOUT:   store i64 0, ptr %total.var, align 8, !dbg !135
// CHECK:STDOUT:   %.loc17_28.5.pack.elem = getelementptr inbounds { i64, ptr }, ptr %self, i32 0, i32 0, !dbg !140
// CHECK:STDOUT:   %.loc17_28.5.pack.elem.load = load i64, ptr %.loc17_28.5.pack.elem, align 8, !dbg !140
// CHECK:STDOUT:   %Code.WithSelf.Get.call = call i64 @"_CGet.Int.9025b11fc94ef1f2.Core:Code.Main"(i64 %.loc17_28.5.pack.elem.load), !dbg !140
// CHECK:STDOUT:   %.loc17_21 = load i64, ptr %total.var, align 8, !dbg !139
// CHECK:STDOUT:   %Add.call = add i64 %.loc17_21, %Code.WithSelf.Get.call, !dbg !141
// CHECK:STDOUT:   store i64 %Add.call, ptr %total.var, align 8, !dbg !138
// CHECK:STDOUT:   %.loc17_28.5.pack.elem1 = getelementptr inbounds { i64, ptr }, ptr %self, i32 0, i32 1, !dbg !140
// CHECK:STDOUT:   %.loc17_28.5.pack.elem.load2 = load ptr, ptr %.loc17_28.5.pack.elem1, align 8, !dbg !140
// CHECK:STDOUT:   %Code.WithSelf.Get.call3 = call i64 @"_CGet.95020fcee389aab0:Code.Main.b0706e9fb0f30c6e"(ptr %.loc17_28.5.pack.elem.load2), !dbg !140
// CHECK:STDOUT:   %.loc17_214 = load i64, ptr %total.var, align 8, !dbg !139
// CHECK:STDOUT:   %Add.call5 = add i64 %.loc17_214, %Code.WithSelf.Get.call3, !dbg !141
// CHECK:STDOUT:   store i64 %Add.call5, ptr %total.var, align 8, !dbg !138
// CHECK:STDOUT:   %.loc18 = load i64, ptr %total.var, align 8, !dbg !142
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %total.var), !dbg !135
// CHECK:STDOUT:   ret i64 %.loc18, !dbg !143
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CGet.95020fcee389aab0:Code.Main.b0706e9fb0f30c6e"(ptr %self) #0 !dbg !145 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.var = alloca i64, align 8, !dbg !154
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %total.var), !dbg !154
// CHECK:STDOUT:   store i64 0, ptr %total.var, align 8, !dbg !154
// CHECK:STDOUT:   %.loc17_28.5.pack.elem = getelementptr inbounds { i64, i64 }, ptr %self, i32 0, i32 0, !dbg !159
// CHECK:STDOUT:   %.loc17_28.5.pack.elem.load = load i64, ptr %.loc17_28.5.pack.elem, align 8, !dbg !159
// CHECK:STDOUT:   %Code.WithSelf.Get.call = call i64 @"_CGet.Int.9025b11fc94ef1f2.Core:Code.Main"(i64 %.loc17_28.5.pack.elem.load), !dbg !159
// CHECK:STDOUT:   %.loc17_21 = load i64, ptr %total.var, align 8, !dbg !158
// CHECK:STDOUT:   %Add.call = add i64 %.loc17_21, %Code.WithSelf.Get.call, !dbg !160
// CHECK:STDOUT:   store i64 %Add.call, ptr %total.var, align 8, !dbg !157
// CHECK:STDOUT:   %.loc17_28.5.pack.elem1 = getelementptr inbounds { i64, i64 }, ptr %self, i32 0, i32 1, !dbg !159
// CHECK:STDOUT:   %.loc17_28.5.pack.elem.load2 = load i64, ptr %.loc17_28.5.pack.elem1, align 8, !dbg !159
// CHECK:STDOUT:   %Code.WithSelf.Get.call3 = call i64 @"_CGet.Int.9025b11fc94ef1f2.Core:Code.Main"(i64 %.loc17_28.5.pack.elem.load2), !dbg !159
// CHECK:STDOUT:   %.loc17_214 = load i64, ptr %total.var, align 8, !dbg !158
// CHECK:STDOUT:   %Add.call5 = add i64 %.loc17_214, %Code.WithSelf.Get.call3, !dbg !160
// CHECK:STDOUT:   store i64 %Add.call5, ptr %total.var, align 8, !dbg !157
// CHECK:STDOUT:   %.loc18 = load i64, ptr %total.var, align 8, !dbg !161
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %total.var), !dbg !154
// CHECK:STDOUT:   ret i64 %.loc18, !dbg !162
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!105}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !35 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !36 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !58 = !{!35, !35}
// CHECK:STDOUT: !59 = !DISubroutineType(types: !58)
// CHECK:STDOUT: !60 = !{null, !35}
// CHECK:STDOUT: !61 = !DISubroutineType(types: !60)
// CHECK:STDOUT: !62 = !{!35, !36}
// CHECK:STDOUT: !63 = !DISubroutineType(types: !62)
// CHECK:STDOUT: !104 = !DIFile(filename: "impl.carbon", directory: "")
// CHECK:STDOUT: !105 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !104, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !106 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Int.9025b11fc94ef1f2.Core:Code.Main", scope: null, file: !104, line: 10, type: !59, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !113)
// CHECK:STDOUT: !107 = !DILocalVariable(arg: 1, scope: !106, type: !35)
// CHECK:STDOUT: !112 = !DILocation(line: 10, column: 25, scope: !106)
// CHECK:STDOUT: !113 = !{!107}
// CHECK:STDOUT: !114 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !104, line: 16, type: !61, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !117)
// CHECK:STDOUT: !115 = !DILocalVariable(arg: 1, scope: !114, type: !35)
// CHECK:STDOUT: !116 = !DILocation(line: 16, column: 5, scope: !114)
// CHECK:STDOUT: !117 = !{!115}
// CHECK:STDOUT: !118 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !104, line: 22, type: !63, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !125)
// CHECK:STDOUT: !119 = !DILocalVariable(arg: 1, scope: !118, type: !36)
// CHECK:STDOUT: !123 = !DILocation(line: 23, column: 10, scope: !118)
// CHECK:STDOUT: !124 = !DILocation(line: 23, column: 3, scope: !118)
// CHECK:STDOUT: !125 = !{!119}
// CHECK:STDOUT: !126 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.95020fcee389aab0:Code.Main.b2bd9f44fc9c07bd", scope: null, file: !104, line: 14, type: !63, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !144)
// CHECK:STDOUT: !127 = !DILocalVariable(arg: 1, scope: !126, type: !36)
// CHECK:STDOUT: !135 = !DILocation(line: 16, column: 5, scope: !126)
// CHECK:STDOUT: !138 = !DILocation(line: 17, column: 9, scope: !126)
// CHECK:STDOUT: !139 = !DILocation(line: 17, column: 21, scope: !126)
// CHECK:STDOUT: !140 = !DILocation(line: 17, column: 28, scope: !126)
// CHECK:STDOUT: !141 = !DILocation(line: 17, column: 17, scope: !126)
// CHECK:STDOUT: !142 = !DILocation(line: 18, column: 12, scope: !126)
// CHECK:STDOUT: !143 = !DILocation(line: 18, column: 5, scope: !126)
// CHECK:STDOUT: !144 = !{!127}
// CHECK:STDOUT: !145 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.95020fcee389aab0:Code.Main.b0706e9fb0f30c6e", scope: null, file: !104, line: 14, type: !63, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !163)
// CHECK:STDOUT: !146 = !DILocalVariable(arg: 1, scope: !145, type: !36)
// CHECK:STDOUT: !154 = !DILocation(line: 16, column: 5, scope: !145)
// CHECK:STDOUT: !157 = !DILocation(line: 17, column: 9, scope: !145)
// CHECK:STDOUT: !158 = !DILocation(line: 17, column: 21, scope: !145)
// CHECK:STDOUT: !159 = !DILocation(line: 17, column: 28, scope: !145)
// CHECK:STDOUT: !160 = !DILocation(line: 17, column: 17, scope: !145)
// CHECK:STDOUT: !161 = !DILocation(line: 18, column: 12, scope: !145)
// CHECK:STDOUT: !162 = !DILocation(line: 18, column: 5, scope: !145)
// CHECK:STDOUT: !163 = !{!146}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'one_tuple.carbon'
// CHECK:STDOUT: source_filename = "one_tuple.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @.8ff.loc8_22.5 = internal constant { i64 } { i64 5 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define { i64 } @_CCall.Main() #0 !dbg !166 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %MakeTuple.call = call { i64 } @_CMakeTuple.Main.a77bdf6eb669a8dc(ptr @.8ff.loc8_22.5), !dbg !170
// CHECK:STDOUT:   ret { i64 } %MakeTuple.call, !dbg !171
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr { i64 } @_CMakeTuple.Main.a77bdf6eb669a8dc(ptr %x) #0 !dbg !172 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc4_21.2.tuple.init = alloca { i64 }, align 8, !dbg !178
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc4_21.2.tuple.init), !dbg !178
// CHECK:STDOUT:   %.loc4_21.7.pack.elem = getelementptr inbounds { i64 }, ptr %x, i32 0, i32 0, !dbg !178
// CHECK:STDOUT:   %.loc4_21.7.pack.elem.load = load i64, ptr %.loc4_21.7.pack.elem, align 8, !dbg !178
// CHECK:STDOUT:   %.loc4_21.13.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc4_21.2.tuple.init, i32 0, i32 0, !dbg !178
// CHECK:STDOUT:   store i64 %.loc4_21.7.pack.elem.load, ptr %.loc4_21.13.tuple.elem, align 8, !dbg !178
// CHECK:STDOUT:   %tuple.init = load { i64 }, ptr %.loc4_21.2.tuple.init, align 8
// CHECK:STDOUT:   ret { i64 } %tuple.init, !dbg !179
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!165}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !36 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !37 = !{!36}
// CHECK:STDOUT: !38 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !44 = !{!36, !36}
// CHECK:STDOUT: !45 = !DISubroutineType(types: !44)
// CHECK:STDOUT: !164 = !DIFile(filename: "one_tuple.carbon", directory: "")
// CHECK:STDOUT: !165 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !164, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !166 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !164, line: 7, type: !38, spFlags: DISPFlagDefinition, unit: !165)
// CHECK:STDOUT: !170 = !DILocation(line: 8, column: 10, scope: !166)
// CHECK:STDOUT: !171 = !DILocation(line: 8, column: 3, scope: !166)
// CHECK:STDOUT: !172 = distinct !DISubprogram(name: "MakeTuple", linkageName: "_CMakeTuple.Main.a77bdf6eb669a8dc", scope: null, file: !164, line: 3, type: !45, spFlags: DISPFlagDefinition, unit: !165, retainedNodes: !180)
// CHECK:STDOUT: !173 = !DILocalVariable(arg: 1, scope: !172, type: !36)
// CHECK:STDOUT: !178 = !DILocation(line: 4, column: 10, scope: !172)
// CHECK:STDOUT: !179 = !DILocation(line: 4, column: 3, scope: !172)
// CHECK:STDOUT: !180 = !{!173}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'self_return.carbon'
// CHECK:STDOUT: source_filename = "self_return.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr sret({ i64, i64, i64, i64 }) %return, ptr %t) #0 !dbg !183 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_COp.4239cb399c0b0701:Cp.Main.500924e50a4e3bf6"(ptr %return, ptr %t), !dbg !188
// CHECK:STDOUT:   ret void, !dbg !189
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.4239cb399c0b0701:Cp.Main.500924e50a4e3bf6"(ptr sret({ i64, i64, i64, i64 }) %return, ptr %self) #0 !dbg !191 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CMake.Main.6bc147f143599f5d(ptr %return, ptr %self), !dbg !197
// CHECK:STDOUT:   ret void, !dbg !198
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CMake.Main.6bc147f143599f5d(ptr sret({ i64, i64, i64, i64 }) %return, ptr %x) #0 !dbg !200 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CMake.Main.6bc147f143599f5d(ptr %return, ptr %x), !dbg !206
// CHECK:STDOUT:   ret void, !dbg !207
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!182}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !36 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !44 = !{!36, !36}
// CHECK:STDOUT: !45 = !DISubroutineType(types: !44)
// CHECK:STDOUT: !181 = !DIFile(filename: "self_return.carbon", directory: "")
// CHECK:STDOUT: !182 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !181, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !183 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !181, line: 15, type: !45, spFlags: DISPFlagDefinition, unit: !182, retainedNodes: !190)
// CHECK:STDOUT: !184 = !DILocalVariable(arg: 1, scope: !183, type: !36)
// CHECK:STDOUT: !188 = !DILocation(line: 16, column: 10, scope: !183)
// CHECK:STDOUT: !189 = !DILocation(line: 16, column: 3, scope: !183)
// CHECK:STDOUT: !190 = !{!184}
// CHECK:STDOUT: !191 = distinct !DISubprogram(name: "Op", linkageName: "_COp.4239cb399c0b0701:Cp.Main.500924e50a4e3bf6", scope: null, file: !181, line: 12, type: !45, spFlags: DISPFlagDefinition, unit: !182, retainedNodes: !199)
// CHECK:STDOUT: !192 = !DILocalVariable(arg: 1, scope: !191, type: !36)
// CHECK:STDOUT: !197 = !DILocation(line: 12, column: 32, scope: !191)
// CHECK:STDOUT: !198 = !DILocation(line: 12, column: 25, scope: !191)
// CHECK:STDOUT: !199 = !{!192}
// CHECK:STDOUT: !200 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.Main.6bc147f143599f5d", scope: null, file: !181, line: 7, type: !45, spFlags: DISPFlagDefinition, unit: !182, retainedNodes: !208)
// CHECK:STDOUT: !201 = !DILocalVariable(arg: 1, scope: !200, type: !36)
// CHECK:STDOUT: !206 = !DILocation(line: 8, column: 10, scope: !200)
// CHECK:STDOUT: !207 = !DILocation(line: 8, column: 3, scope: !200)
// CHECK:STDOUT: !208 = !{!201}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'impl_body.carbon'
// CHECK:STDOUT: source_filename = "impl_body.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !211 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !213
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CCall.Main(ptr %t) #0 !dbg !215 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.type.as.Sum.impl.Get.call = call i64 @"_CGet.57a8d7c35f6d6d1d:Sum.Main.1bf341b7cd4cd259"(ptr %t), !dbg !220
// CHECK:STDOUT:   ret i64 %tuple.type.as.Sum.impl.Get.call, !dbg !221
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CGet.57a8d7c35f6d6d1d:Sum.Main.1bf341b7cd4cd259"(ptr %self) #0 !dbg !223 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %s.var = alloca i64, align 8, !dbg !228
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %s.var), !dbg !228
// CHECK:STDOUT:   store i64 0, ptr %s.var, align 8, !dbg !228
// CHECK:STDOUT:   %.loc18_17 = load i64, ptr %s.var, align 8, !dbg !232
// CHECK:STDOUT:   %Add.call = add i64 %.loc18_17, 3, !dbg !233
// CHECK:STDOUT:   store i64 %Add.call, ptr %s.var, align 8, !dbg !231
// CHECK:STDOUT:   %.loc18_171 = load i64, ptr %s.var, align 8, !dbg !232
// CHECK:STDOUT:   %Add.call2 = add i64 %.loc18_171, 40, !dbg !233
// CHECK:STDOUT:   store i64 %Add.call2, ptr %s.var, align 8, !dbg !231
// CHECK:STDOUT:   %.loc18_173 = load i64, ptr %s.var, align 8, !dbg !232
// CHECK:STDOUT:   %Add.call4 = add i64 %.loc18_173, 3, !dbg !233
// CHECK:STDOUT:   store i64 %Add.call4, ptr %s.var, align 8, !dbg !231
// CHECK:STDOUT:   %.loc19 = load i64, ptr %s.var, align 8, !dbg !234
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %s.var), !dbg !228
// CHECK:STDOUT:   ret i64 %.loc19, !dbg !235
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!210}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !35 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !36 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !60 = !{null, !35}
// CHECK:STDOUT: !61 = !DISubroutineType(types: !60)
// CHECK:STDOUT: !62 = !{!35, !36}
// CHECK:STDOUT: !63 = !DISubroutineType(types: !62)
// CHECK:STDOUT: !209 = !DIFile(filename: "impl_body.carbon", directory: "")
// CHECK:STDOUT: !210 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !209, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !211 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !209, line: 17, type: !61, spFlags: DISPFlagDefinition, unit: !210, retainedNodes: !214)
// CHECK:STDOUT: !212 = !DILocalVariable(arg: 1, scope: !211, type: !35)
// CHECK:STDOUT: !213 = !DILocation(line: 17, column: 5, scope: !211)
// CHECK:STDOUT: !214 = !{!212}
// CHECK:STDOUT: !215 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !209, line: 23, type: !63, spFlags: DISPFlagDefinition, unit: !210, retainedNodes: !222)
// CHECK:STDOUT: !216 = !DILocalVariable(arg: 1, scope: !215, type: !36)
// CHECK:STDOUT: !220 = !DILocation(line: 24, column: 10, scope: !215)
// CHECK:STDOUT: !221 = !DILocation(line: 24, column: 3, scope: !215)
// CHECK:STDOUT: !222 = !{!216}
// CHECK:STDOUT: !223 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.57a8d7c35f6d6d1d:Sum.Main.1bf341b7cd4cd259", scope: null, file: !209, line: 16, type: !63, spFlags: DISPFlagDefinition, unit: !210, retainedNodes: !236)
// CHECK:STDOUT: !224 = !DILocalVariable(arg: 1, scope: !223, type: !36)
// CHECK:STDOUT: !228 = !DILocation(line: 17, column: 5, scope: !223)
// CHECK:STDOUT: !231 = !DILocation(line: 18, column: 9, scope: !223)
// CHECK:STDOUT: !232 = !DILocation(line: 18, column: 17, scope: !223)
// CHECK:STDOUT: !233 = !DILocation(line: 18, column: 13, scope: !223)
// CHECK:STDOUT: !234 = !DILocation(line: 19, column: 12, scope: !223)
// CHECK:STDOUT: !235 = !DILocation(line: 19, column: 5, scope: !223)
// CHECK:STDOUT: !236 = !{!224}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'impl_lib.carbon'
// CHECK:STDOUT: source_filename = "impl_lib.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !239 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !241
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!238}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !35 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !60 = !{null, !35}
// CHECK:STDOUT: !61 = !DISubroutineType(types: !60)
// CHECK:STDOUT: !237 = !DIFile(filename: "impl_lib.carbon", directory: "")
// CHECK:STDOUT: !238 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !237, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !239 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !237, line: 17, type: !61, spFlags: DISPFlagDefinition, unit: !238, retainedNodes: !242)
// CHECK:STDOUT: !240 = !DILocalVariable(arg: 1, scope: !239, type: !35)
// CHECK:STDOUT: !241 = !DILocation(line: 17, column: 5, scope: !239)
// CHECK:STDOUT: !242 = !{!240}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'impl_use.carbon'
// CHECK:STDOUT: source_filename = "impl_use.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CCall.Main(ptr %t) #0 !dbg !245 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.type.as.Sum.impl.Get.call = call i64 @"_CGet.57a8d7c35f6d6d1d:Sum.Main.4bb124689ef0bcf9"(ptr %t), !dbg !250
// CHECK:STDOUT:   ret i64 %tuple.type.as.Sum.impl.Get.call, !dbg !251
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CGet.57a8d7c35f6d6d1d:Sum.Main.4bb124689ef0bcf9"(ptr %self) #0 !dbg !253 {
// CHECK:STDOUT:   %1 = alloca i64, align 8, !dbg !258
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !258
// CHECK:STDOUT:   store i64 0, ptr %1, align 8, !dbg !258
// CHECK:STDOUT:   %2 = load i64, ptr %1, align 8, !dbg !262
// CHECK:STDOUT:   %3 = add i64 %2, 3, !dbg !263
// CHECK:STDOUT:   store i64 %3, ptr %1, align 8, !dbg !261
// CHECK:STDOUT:   %4 = load i64, ptr %1, align 8, !dbg !262
// CHECK:STDOUT:   %5 = add i64 %4, 40, !dbg !263
// CHECK:STDOUT:   store i64 %5, ptr %1, align 8, !dbg !261
// CHECK:STDOUT:   %6 = load i64, ptr %1, align 8, !dbg !262
// CHECK:STDOUT:   %7 = add i64 %6, 3, !dbg !263
// CHECK:STDOUT:   store i64 %7, ptr %1, align 8, !dbg !261
// CHECK:STDOUT:   %8 = load i64, ptr %1, align 8, !dbg !264
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %1), !dbg !258
// CHECK:STDOUT:   ret i64 %8, !dbg !265
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!244}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !35 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !36 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !62 = !{!35, !36}
// CHECK:STDOUT: !63 = !DISubroutineType(types: !62)
// CHECK:STDOUT: !237 = !DIFile(filename: "impl_lib.carbon", directory: "")
// CHECK:STDOUT: !243 = !DIFile(filename: "impl_use.carbon", directory: "")
// CHECK:STDOUT: !244 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !243, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !245 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !243, line: 5, type: !63, spFlags: DISPFlagDefinition, unit: !244, retainedNodes: !252)
// CHECK:STDOUT: !246 = !DILocalVariable(arg: 1, scope: !245, type: !36)
// CHECK:STDOUT: !250 = !DILocation(line: 6, column: 10, scope: !245)
// CHECK:STDOUT: !251 = !DILocation(line: 6, column: 3, scope: !245)
// CHECK:STDOUT: !252 = !{!246}
// CHECK:STDOUT: !253 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.57a8d7c35f6d6d1d:Sum.Main.4bb124689ef0bcf9", scope: null, file: !237, line: 16, type: !63, spFlags: DISPFlagDefinition, unit: !244, retainedNodes: !266)
// CHECK:STDOUT: !254 = !DILocalVariable(arg: 1, scope: !253, type: !36)
// CHECK:STDOUT: !258 = !DILocation(line: 17, column: 5, scope: !253)
// CHECK:STDOUT: !261 = !DILocation(line: 18, column: 9, scope: !253)
// CHECK:STDOUT: !262 = !DILocation(line: 18, column: 17, scope: !253)
// CHECK:STDOUT: !263 = !DILocation(line: 18, column: 13, scope: !253)
// CHECK:STDOUT: !264 = !DILocation(line: 19, column: 12, scope: !253)
// CHECK:STDOUT: !265 = !DILocation(line: 19, column: 5, scope: !253)
// CHECK:STDOUT: !266 = !{!254}
// CHECK:STDOUT:

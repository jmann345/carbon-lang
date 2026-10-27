// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/hetero_pack.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/hetero_pack.carbon

// --- call.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class B {}
impl B as Code {
  fn Get(unused self) -> i64 { return 2; }
}

fn Consume(x: i64);

fn ForEach[... each T: Code](... each x: each T) {
  ... Consume(each x.Get());
}

fn Call(a: A, b: B) {
  ForEach(a, b, a);
  ForEach();
}

// --- layout.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn One[V: type](unused v: V) -> i64 { return 1; }

fn Count[... each T: type](... each x: each T) -> i64 {
  var n: i64 = 0;
  ... n = Add(n, One(each x));
  return n;
}

fn Call() -> i64 {
  return Count(1 as i64, true, 2 as i32);
}

// --- forward.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class B {}
impl B as Code {
  fn Get(unused self) -> i64 { return 2; }
}

fn Consume(x: i64);

fn ForEach[... each T: Code](... each x: each T) {
  ... Consume(each x.Get());
}

fn Forward[... each U: Code](... each y: each U) {
  ForEach(... each y);
}

fn Call(a: A, b: B) {
  Forward(a, b);
}

// --- lib.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class B {}
impl B as Code {
  fn Get(unused self) -> i64 { return 2; }
}

fn Consume(x: i64);

fn ForEach[... each T: Code](... each x: each T) {
  ... Consume(each x.Get());
}

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn One[V: type](unused v: V) -> i64 { return 1; }

fn Count[... each T: type](... each x: each T) -> i64 {
  var n: i64 = 0;
  ... n = Add(n, One(each x));
  return n;
}

// --- use.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Call(a: A, b: B) -> i64 {
  ForEach(a, b, a);
  return Count(1 as i64, true, 2 as i32);
}

// --- generic_caller.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class B {}
impl B as Code {
  fn Get(unused self) -> i64 { return 2; }
}

fn Consume(x: i64);

fn ForEach[... each T: Code](... each x: each T) {
  ... Consume(each x.Get());
}

fn Caller[T: Code, U: Code](x: T, y: U) {
  ForEach(x, y, x);
}

fn Call(a: A, b: B) {
  Caller(a, b);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'call.carbon'
// CHECK:STDOUT: source_filename = "call.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @.610.loc25_11.7 = internal constant {} zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @"_CGet.A.Main:Code.Main"(ptr %self) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i64 1, !dbg !47
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @"_CGet.B.Main:Code.Main"(ptr %self) #0 !dbg !49 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i64 2, !dbg !54
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CConsume.Main(i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr %a, ptr %b) #0 !dbg !56 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc24_11.3.pack = alloca { ptr, ptr, ptr }, align 8, !dbg !61
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc24_11.3.pack), !dbg !61
// CHECK:STDOUT:   %.loc24_11.3.pack.elem = getelementptr inbounds { ptr, ptr, ptr }, ptr %.loc24_11.3.pack, i32 0, i32 0, !dbg !61
// CHECK:STDOUT:   store ptr %a, ptr %.loc24_11.3.pack.elem, align 8, !dbg !61
// CHECK:STDOUT:   %.loc24_11.3.pack.elem1 = getelementptr inbounds { ptr, ptr, ptr }, ptr %.loc24_11.3.pack, i32 0, i32 1, !dbg !61
// CHECK:STDOUT:   store ptr %b, ptr %.loc24_11.3.pack.elem1, align 8, !dbg !61
// CHECK:STDOUT:   %.loc24_11.3.pack.elem2 = getelementptr inbounds { ptr, ptr, ptr }, ptr %.loc24_11.3.pack, i32 0, i32 2, !dbg !61
// CHECK:STDOUT:   store ptr %a, ptr %.loc24_11.3.pack.elem2, align 8, !dbg !61
// CHECK:STDOUT:   call void @_CForEach.Main.a68351f87c3c8f6d(ptr %.loc24_11.3.pack), !dbg !64
// CHECK:STDOUT:   call void @_CForEach.Main.898fb224e7835977(ptr @.610.loc25_11.7), !dbg !67
// CHECK:STDOUT:   ret void, !dbg !68
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CForEach.Main.a68351f87c3c8f6d(ptr %x) #0 !dbg !70 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc20_15.5.pack.elem = getelementptr inbounds { ptr, ptr, ptr }, ptr %x, i32 0, i32 0, !dbg !74
// CHECK:STDOUT:   %.loc20_15.5.pack.elem.load = load ptr, ptr %.loc20_15.5.pack.elem, align 8, !dbg !74
// CHECK:STDOUT:   %Code.WithSelf.Get.call = call i64 @"_CGet.A.Main:Code.Main"(ptr %.loc20_15.5.pack.elem.load), !dbg !74
// CHECK:STDOUT:   call void @_CConsume.Main(i64 %Code.WithSelf.Get.call), !dbg !75
// CHECK:STDOUT:   %.loc20_15.5.pack.elem1 = getelementptr inbounds { ptr, ptr, ptr }, ptr %x, i32 0, i32 1, !dbg !74
// CHECK:STDOUT:   %.loc20_15.5.pack.elem.load2 = load ptr, ptr %.loc20_15.5.pack.elem1, align 8, !dbg !74
// CHECK:STDOUT:   %Code.WithSelf.Get.call3 = call i64 @"_CGet.B.Main:Code.Main"(ptr %.loc20_15.5.pack.elem.load2), !dbg !74
// CHECK:STDOUT:   call void @_CConsume.Main(i64 %Code.WithSelf.Get.call3), !dbg !75
// CHECK:STDOUT:   %.loc20_15.5.pack.elem4 = getelementptr inbounds { ptr, ptr, ptr }, ptr %x, i32 0, i32 2, !dbg !74
// CHECK:STDOUT:   %.loc20_15.5.pack.elem.load5 = load ptr, ptr %.loc20_15.5.pack.elem4, align 8, !dbg !74
// CHECK:STDOUT:   %Code.WithSelf.Get.call6 = call i64 @"_CGet.A.Main:Code.Main"(ptr %.loc20_15.5.pack.elem.load5), !dbg !74
// CHECK:STDOUT:   call void @_CConsume.Main(i64 %Code.WithSelf.Get.call6), !dbg !75
// CHECK:STDOUT:   ret void, !dbg !76
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CForEach.Main.898fb224e7835977(ptr %x) #0 !dbg !78 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !82
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!33}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !32 = !DIFile(filename: "call.carbon", directory: "")
// CHECK:STDOUT: !33 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !32, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !34 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !35 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !36 = !{!34, !35}
// CHECK:STDOUT: !37 = !DISubroutineType(types: !36)
// CHECK:STDOUT: !40 = !{null, !35, !35}
// CHECK:STDOUT: !41 = !DISubroutineType(types: !40)
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.A.Main:Code.Main", scope: null, file: !32, line: 9, type: !37, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !48)
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !42, type: !35)
// CHECK:STDOUT: !47 = !DILocation(line: 9, column: 32, scope: !42)
// CHECK:STDOUT: !48 = !{!43}
// CHECK:STDOUT: !49 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.B.Main:Code.Main", scope: null, file: !32, line: 14, type: !37, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !55)
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !49, type: !35)
// CHECK:STDOUT: !54 = !DILocation(line: 14, column: 32, scope: !49)
// CHECK:STDOUT: !55 = !{!50}
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !32, line: 23, type: !41, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !69)
// CHECK:STDOUT: !57 = !DILocalVariable(arg: 1, scope: !56, type: !35)
// CHECK:STDOUT: !58 = !DILocalVariable(arg: 2, scope: !56, type: !35)
// CHECK:STDOUT: !61 = !DILocation(line: 24, column: 11, scope: !56)
// CHECK:STDOUT: !64 = !DILocation(line: 24, column: 3, scope: !56)
// CHECK:STDOUT: !65 = !{null, !35}
// CHECK:STDOUT: !66 = !DISubroutineType(types: !65)
// CHECK:STDOUT: !67 = !DILocation(line: 25, column: 3, scope: !56)
// CHECK:STDOUT: !68 = !DILocation(line: 23, column: 1, scope: !56)
// CHECK:STDOUT: !69 = !{!57, !58}
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "ForEach", linkageName: "_CForEach.Main.a68351f87c3c8f6d", scope: null, file: !32, line: 19, type: !66, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !77)
// CHECK:STDOUT: !71 = !DILocalVariable(arg: 1, scope: !70, type: !35)
// CHECK:STDOUT: !74 = !DILocation(line: 20, column: 15, scope: !70)
// CHECK:STDOUT: !75 = !DILocation(line: 20, column: 7, scope: !70)
// CHECK:STDOUT: !76 = !DILocation(line: 19, column: 1, scope: !70)
// CHECK:STDOUT: !77 = !{!71}
// CHECK:STDOUT: !78 = distinct !DISubprogram(name: "ForEach", linkageName: "_CForEach.Main.898fb224e7835977", scope: null, file: !32, line: 19, type: !66, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !83)
// CHECK:STDOUT: !79 = !DILocalVariable(arg: 1, scope: !78, type: !35)
// CHECK:STDOUT: !82 = !DILocation(line: 19, column: 1, scope: !78)
// CHECK:STDOUT: !83 = !{!79}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'layout.carbon'
// CHECK:STDOUT: source_filename = "layout.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @.7fc.loc14_18.5 = internal constant { i64, i1, i32 } { i64 1, i1 true, i32 2 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !89 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CCall.Main() #0 !dbg !93 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Count.call = call i64 @_CCount.Main.fe218f8d6a5eeccd(ptr @.7fc.loc14_18.5), !dbg !97
// CHECK:STDOUT:   ret i64 %Count.call, !dbg !98
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CCount.Main.fe218f8d6a5eeccd(ptr %x) #0 !dbg !99 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %n.var = alloca i64, align 8, !dbg !104
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %n.var), !dbg !104
// CHECK:STDOUT:   store i64 0, ptr %n.var, align 8, !dbg !104
// CHECK:STDOUT:   %.loc9_22.4.pack.elem = getelementptr inbounds { i64, i1, i32 }, ptr %x, i32 0, i32 0, !dbg !109
// CHECK:STDOUT:   %.loc9_22.4.pack.elem.load = load i64, ptr %.loc9_22.4.pack.elem, align 8, !dbg !109
// CHECK:STDOUT:   %One.call = call i64 @_COne.Main.f249b435619a5146(i64 %.loc9_22.4.pack.elem.load), !dbg !110
// CHECK:STDOUT:   %.loc9_15 = load i64, ptr %n.var, align 8, !dbg !108
// CHECK:STDOUT:   %Add.call = add i64 %.loc9_15, %One.call, !dbg !113
// CHECK:STDOUT:   store i64 %Add.call, ptr %n.var, align 8, !dbg !107
// CHECK:STDOUT:   %.loc9_22.4.pack.elem1 = getelementptr inbounds { i64, i1, i32 }, ptr %x, i32 0, i32 1, !dbg !109
// CHECK:STDOUT:   %.loc9_22.4.pack.elem.load2 = load i8, ptr %.loc9_22.4.pack.elem1, align 1, !dbg !109
// CHECK:STDOUT:   %.loc9_22.4 = trunc i8 %.loc9_22.4.pack.elem.load2 to i1, !dbg !109
// CHECK:STDOUT:   %One.call3 = call i64 @_COne.Main.a4c7fafe8a72cac4(i1 %.loc9_22.4), !dbg !110
// CHECK:STDOUT:   %.loc9_154 = load i64, ptr %n.var, align 8, !dbg !108
// CHECK:STDOUT:   %Add.call5 = add i64 %.loc9_154, %One.call3, !dbg !113
// CHECK:STDOUT:   store i64 %Add.call5, ptr %n.var, align 8, !dbg !107
// CHECK:STDOUT:   %.loc9_22.4.pack.elem6 = getelementptr inbounds { i64, i1, i32 }, ptr %x, i32 0, i32 2, !dbg !109
// CHECK:STDOUT:   %.loc9_22.4.pack.elem.load7 = load i32, ptr %.loc9_22.4.pack.elem6, align 4, !dbg !109
// CHECK:STDOUT:   %One.call8 = call i64 @_COne.Main.84588f41d61dafba(i32 %.loc9_22.4.pack.elem.load7), !dbg !110
// CHECK:STDOUT:   %.loc9_159 = load i64, ptr %n.var, align 8, !dbg !108
// CHECK:STDOUT:   %Add.call10 = add i64 %.loc9_159, %One.call8, !dbg !113
// CHECK:STDOUT:   store i64 %Add.call10, ptr %n.var, align 8, !dbg !107
// CHECK:STDOUT:   %.loc10 = load i64, ptr %n.var, align 8, !dbg !116
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %n.var), !dbg !104
// CHECK:STDOUT:   ret i64 %.loc10, !dbg !117
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_COne.Main.f249b435619a5146(i64 %v) #0 !dbg !119 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i64 1, !dbg !124
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_COne.Main.a4c7fafe8a72cac4(i1 %v) #0 !dbg !126 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i64 1, !dbg !131
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_COne.Main.84588f41d61dafba(i32 %v) #0 !dbg !133 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i64 1, !dbg !138
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!85}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !34 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !35 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !36 = !{!34, !35}
// CHECK:STDOUT: !37 = !DISubroutineType(types: !36)
// CHECK:STDOUT: !38 = !{null, !34}
// CHECK:STDOUT: !39 = !DISubroutineType(types: !38)
// CHECK:STDOUT: !84 = !DIFile(filename: "layout.carbon", directory: "")
// CHECK:STDOUT: !85 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !84, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !86 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !87 = !{!34}
// CHECK:STDOUT: !88 = !DISubroutineType(types: !87)
// CHECK:STDOUT: !89 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !84, line: 8, type: !39, spFlags: DISPFlagDefinition, unit: !85, retainedNodes: !92)
// CHECK:STDOUT: !90 = !DILocalVariable(arg: 1, scope: !89, type: !34)
// CHECK:STDOUT: !91 = !DILocation(line: 8, column: 3, scope: !89)
// CHECK:STDOUT: !92 = !{!90}
// CHECK:STDOUT: !93 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !84, line: 13, type: !88, spFlags: DISPFlagDefinition, unit: !85)
// CHECK:STDOUT: !97 = !DILocation(line: 14, column: 10, scope: !93)
// CHECK:STDOUT: !98 = !DILocation(line: 14, column: 3, scope: !93)
// CHECK:STDOUT: !99 = distinct !DISubprogram(name: "Count", linkageName: "_CCount.Main.fe218f8d6a5eeccd", scope: null, file: !84, line: 7, type: !37, spFlags: DISPFlagDefinition, unit: !85, retainedNodes: !118)
// CHECK:STDOUT: !100 = !DILocalVariable(arg: 1, scope: !99, type: !35)
// CHECK:STDOUT: !104 = !DILocation(line: 8, column: 3, scope: !99)
// CHECK:STDOUT: !107 = !DILocation(line: 9, column: 7, scope: !99)
// CHECK:STDOUT: !108 = !DILocation(line: 9, column: 15, scope: !99)
// CHECK:STDOUT: !109 = !DILocation(line: 9, column: 22, scope: !99)
// CHECK:STDOUT: !110 = !DILocation(line: 9, column: 18, scope: !99)
// CHECK:STDOUT: !111 = !{!34, !34}
// CHECK:STDOUT: !112 = !DISubroutineType(types: !111)
// CHECK:STDOUT: !113 = !DILocation(line: 9, column: 11, scope: !99)
// CHECK:STDOUT: !114 = !{!34, !86}
// CHECK:STDOUT: !115 = !DISubroutineType(types: !114)
// CHECK:STDOUT: !116 = !DILocation(line: 10, column: 10, scope: !99)
// CHECK:STDOUT: !117 = !DILocation(line: 10, column: 3, scope: !99)
// CHECK:STDOUT: !118 = !{!100}
// CHECK:STDOUT: !119 = distinct !DISubprogram(name: "One", linkageName: "_COne.Main.f249b435619a5146", scope: null, file: !84, line: 5, type: !112, spFlags: DISPFlagDefinition, unit: !85, retainedNodes: !125)
// CHECK:STDOUT: !120 = !DILocalVariable(arg: 1, scope: !119, type: !34)
// CHECK:STDOUT: !124 = !DILocation(line: 5, column: 39, scope: !119)
// CHECK:STDOUT: !125 = !{!120}
// CHECK:STDOUT: !126 = distinct !DISubprogram(name: "One", linkageName: "_COne.Main.a4c7fafe8a72cac4", scope: null, file: !84, line: 5, type: !37, spFlags: DISPFlagDefinition, unit: !85, retainedNodes: !132)
// CHECK:STDOUT: !127 = !DILocalVariable(arg: 1, scope: !126, type: !35)
// CHECK:STDOUT: !131 = !DILocation(line: 5, column: 39, scope: !126)
// CHECK:STDOUT: !132 = !{!127}
// CHECK:STDOUT: !133 = distinct !DISubprogram(name: "One", linkageName: "_COne.Main.84588f41d61dafba", scope: null, file: !84, line: 5, type: !115, spFlags: DISPFlagDefinition, unit: !85, retainedNodes: !139)
// CHECK:STDOUT: !134 = !DILocalVariable(arg: 1, scope: !133, type: !86)
// CHECK:STDOUT: !138 = !DILocation(line: 5, column: 39, scope: !133)
// CHECK:STDOUT: !139 = !{!134}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'forward.carbon'
// CHECK:STDOUT: source_filename = "forward.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @"_CGet.A.Main:Code.Main"(ptr %self) #0 !dbg !142 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i64 1, !dbg !147
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @"_CGet.B.Main:Code.Main"(ptr %self) #0 !dbg !149 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i64 2, !dbg !154
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CConsume.Main(i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr %a, ptr %b) #0 !dbg !156 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc28_11.3.pack = alloca { ptr, ptr }, align 8, !dbg !161
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc28_11.3.pack), !dbg !161
// CHECK:STDOUT:   %.loc28_11.3.pack.elem = getelementptr inbounds { ptr, ptr }, ptr %.loc28_11.3.pack, i32 0, i32 0, !dbg !161
// CHECK:STDOUT:   store ptr %a, ptr %.loc28_11.3.pack.elem, align 8, !dbg !161
// CHECK:STDOUT:   %.loc28_11.3.pack.elem1 = getelementptr inbounds { ptr, ptr }, ptr %.loc28_11.3.pack, i32 0, i32 1, !dbg !161
// CHECK:STDOUT:   store ptr %b, ptr %.loc28_11.3.pack.elem1, align 8, !dbg !161
// CHECK:STDOUT:   call void @_CForward.Main.c476c7ad775aab97(ptr %.loc28_11.3.pack), !dbg !163
// CHECK:STDOUT:   ret void, !dbg !164
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CForward.Main.c476c7ad775aab97(ptr %y) #0 !dbg !166 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc24_11.pack = alloca { ptr, ptr }, align 8, !dbg !169
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc24_11.pack), !dbg !169
// CHECK:STDOUT:   %.loc24_15.5.pack.elem = getelementptr inbounds { ptr, ptr }, ptr %y, i32 0, i32 0, !dbg !170
// CHECK:STDOUT:   %.loc24_15.5.pack.elem.load = load ptr, ptr %.loc24_15.5.pack.elem, align 8, !dbg !170
// CHECK:STDOUT:   %pack.elem = getelementptr inbounds { ptr, ptr }, ptr %.loc24_11.pack, i32 0, i32 0
// CHECK:STDOUT:   store ptr %.loc24_15.5.pack.elem.load, ptr %pack.elem, align 8
// CHECK:STDOUT:   %.loc24_15.5.pack.elem1 = getelementptr inbounds { ptr, ptr }, ptr %y, i32 0, i32 1, !dbg !170
// CHECK:STDOUT:   %.loc24_15.5.pack.elem.load2 = load ptr, ptr %.loc24_15.5.pack.elem1, align 8, !dbg !170
// CHECK:STDOUT:   %pack.elem3 = getelementptr inbounds { ptr, ptr }, ptr %.loc24_11.pack, i32 0, i32 1
// CHECK:STDOUT:   store ptr %.loc24_15.5.pack.elem.load2, ptr %pack.elem3, align 8
// CHECK:STDOUT:   call void @_CForEach.Main.c476c7ad775aab97(ptr %.loc24_11.pack), !dbg !171
// CHECK:STDOUT:   ret void, !dbg !172
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CForEach.Main.c476c7ad775aab97(ptr %x) #0 !dbg !174 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc20_15.5.pack.elem = getelementptr inbounds { ptr, ptr }, ptr %x, i32 0, i32 0, !dbg !178
// CHECK:STDOUT:   %.loc20_15.5.pack.elem.load = load ptr, ptr %.loc20_15.5.pack.elem, align 8, !dbg !178
// CHECK:STDOUT:   %Code.WithSelf.Get.call = call i64 @"_CGet.A.Main:Code.Main"(ptr %.loc20_15.5.pack.elem.load), !dbg !178
// CHECK:STDOUT:   call void @_CConsume.Main(i64 %Code.WithSelf.Get.call), !dbg !179
// CHECK:STDOUT:   %.loc20_15.5.pack.elem1 = getelementptr inbounds { ptr, ptr }, ptr %x, i32 0, i32 1, !dbg !178
// CHECK:STDOUT:   %.loc20_15.5.pack.elem.load2 = load ptr, ptr %.loc20_15.5.pack.elem1, align 8, !dbg !178
// CHECK:STDOUT:   %Code.WithSelf.Get.call3 = call i64 @"_CGet.B.Main:Code.Main"(ptr %.loc20_15.5.pack.elem.load2), !dbg !178
// CHECK:STDOUT:   call void @_CConsume.Main(i64 %Code.WithSelf.Get.call3), !dbg !179
// CHECK:STDOUT:   ret void, !dbg !180
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!141}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !34 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !35 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !36 = !{!34, !35}
// CHECK:STDOUT: !37 = !DISubroutineType(types: !36)
// CHECK:STDOUT: !40 = !{null, !35, !35}
// CHECK:STDOUT: !41 = !DISubroutineType(types: !40)
// CHECK:STDOUT: !65 = !{null, !35}
// CHECK:STDOUT: !66 = !DISubroutineType(types: !65)
// CHECK:STDOUT: !140 = !DIFile(filename: "forward.carbon", directory: "")
// CHECK:STDOUT: !141 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !140, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !142 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.A.Main:Code.Main", scope: null, file: !140, line: 9, type: !37, spFlags: DISPFlagDefinition, unit: !141, retainedNodes: !148)
// CHECK:STDOUT: !143 = !DILocalVariable(arg: 1, scope: !142, type: !35)
// CHECK:STDOUT: !147 = !DILocation(line: 9, column: 32, scope: !142)
// CHECK:STDOUT: !148 = !{!143}
// CHECK:STDOUT: !149 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.B.Main:Code.Main", scope: null, file: !140, line: 14, type: !37, spFlags: DISPFlagDefinition, unit: !141, retainedNodes: !155)
// CHECK:STDOUT: !150 = !DILocalVariable(arg: 1, scope: !149, type: !35)
// CHECK:STDOUT: !154 = !DILocation(line: 14, column: 32, scope: !149)
// CHECK:STDOUT: !155 = !{!150}
// CHECK:STDOUT: !156 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !140, line: 27, type: !41, spFlags: DISPFlagDefinition, unit: !141, retainedNodes: !165)
// CHECK:STDOUT: !157 = !DILocalVariable(arg: 1, scope: !156, type: !35)
// CHECK:STDOUT: !158 = !DILocalVariable(arg: 2, scope: !156, type: !35)
// CHECK:STDOUT: !161 = !DILocation(line: 28, column: 11, scope: !156)
// CHECK:STDOUT: !163 = !DILocation(line: 28, column: 3, scope: !156)
// CHECK:STDOUT: !164 = !DILocation(line: 27, column: 1, scope: !156)
// CHECK:STDOUT: !165 = !{!157, !158}
// CHECK:STDOUT: !166 = distinct !DISubprogram(name: "Forward", linkageName: "_CForward.Main.c476c7ad775aab97", scope: null, file: !140, line: 23, type: !66, spFlags: DISPFlagDefinition, unit: !141, retainedNodes: !173)
// CHECK:STDOUT: !167 = !DILocalVariable(arg: 1, scope: !166, type: !35)
// CHECK:STDOUT: !169 = !DILocation(line: 24, column: 11, scope: !166)
// CHECK:STDOUT: !170 = !DILocation(line: 24, column: 15, scope: !166)
// CHECK:STDOUT: !171 = !DILocation(line: 24, column: 3, scope: !166)
// CHECK:STDOUT: !172 = !DILocation(line: 23, column: 1, scope: !166)
// CHECK:STDOUT: !173 = !{!167}
// CHECK:STDOUT: !174 = distinct !DISubprogram(name: "ForEach", linkageName: "_CForEach.Main.c476c7ad775aab97", scope: null, file: !140, line: 19, type: !66, spFlags: DISPFlagDefinition, unit: !141, retainedNodes: !181)
// CHECK:STDOUT: !175 = !DILocalVariable(arg: 1, scope: !174, type: !35)
// CHECK:STDOUT: !178 = !DILocation(line: 20, column: 15, scope: !174)
// CHECK:STDOUT: !179 = !DILocation(line: 20, column: 7, scope: !174)
// CHECK:STDOUT: !180 = !DILocation(line: 19, column: 1, scope: !174)
// CHECK:STDOUT: !181 = !{!175}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'lib.carbon'
// CHECK:STDOUT: source_filename = "lib.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @"_CGet.A.Main:Code.Main"(ptr %self) #0 !dbg !184 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i64 1, !dbg !189
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @"_CGet.B.Main:Code.Main"(ptr %self) #0 !dbg !191 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i64 2, !dbg !196
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CConsume.Main(i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !198 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !200
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!183}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !34 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !35 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !36 = !{!34, !35}
// CHECK:STDOUT: !37 = !DISubroutineType(types: !36)
// CHECK:STDOUT: !38 = !{null, !34}
// CHECK:STDOUT: !39 = !DISubroutineType(types: !38)
// CHECK:STDOUT: !182 = !DIFile(filename: "lib.carbon", directory: "")
// CHECK:STDOUT: !183 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !182, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !184 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.A.Main:Code.Main", scope: null, file: !182, line: 9, type: !37, spFlags: DISPFlagDefinition, unit: !183, retainedNodes: !190)
// CHECK:STDOUT: !185 = !DILocalVariable(arg: 1, scope: !184, type: !35)
// CHECK:STDOUT: !189 = !DILocation(line: 9, column: 32, scope: !184)
// CHECK:STDOUT: !190 = !{!185}
// CHECK:STDOUT: !191 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.B.Main:Code.Main", scope: null, file: !182, line: 14, type: !37, spFlags: DISPFlagDefinition, unit: !183, retainedNodes: !197)
// CHECK:STDOUT: !192 = !DILocalVariable(arg: 1, scope: !191, type: !35)
// CHECK:STDOUT: !196 = !DILocation(line: 14, column: 32, scope: !191)
// CHECK:STDOUT: !197 = !{!192}
// CHECK:STDOUT: !198 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !182, line: 28, type: !39, spFlags: DISPFlagDefinition, unit: !183, retainedNodes: !201)
// CHECK:STDOUT: !199 = !DILocalVariable(arg: 1, scope: !198, type: !34)
// CHECK:STDOUT: !200 = !DILocation(line: 28, column: 3, scope: !198)
// CHECK:STDOUT: !201 = !{!199}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'use.carbon'
// CHECK:STDOUT: source_filename = "use.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @.7fc.loc7_18.5 = internal constant { i64, i1, i32 } { i64 1, i1 true, i32 2 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CCall.Main(ptr %a, ptr %b) #0 !dbg !206 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_11.3.pack = alloca { ptr, ptr, ptr }, align 8, !dbg !213
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc6_11.3.pack), !dbg !213
// CHECK:STDOUT:   %.loc6_11.3.pack.elem = getelementptr inbounds { ptr, ptr, ptr }, ptr %.loc6_11.3.pack, i32 0, i32 0, !dbg !213
// CHECK:STDOUT:   store ptr %a, ptr %.loc6_11.3.pack.elem, align 8, !dbg !213
// CHECK:STDOUT:   %.loc6_11.3.pack.elem1 = getelementptr inbounds { ptr, ptr, ptr }, ptr %.loc6_11.3.pack, i32 0, i32 1, !dbg !213
// CHECK:STDOUT:   store ptr %b, ptr %.loc6_11.3.pack.elem1, align 8, !dbg !213
// CHECK:STDOUT:   %.loc6_11.3.pack.elem2 = getelementptr inbounds { ptr, ptr, ptr }, ptr %.loc6_11.3.pack, i32 0, i32 2, !dbg !213
// CHECK:STDOUT:   store ptr %a, ptr %.loc6_11.3.pack.elem2, align 8, !dbg !213
// CHECK:STDOUT:   call void @_CForEach.Main.5fd020f59c727035(ptr %.loc6_11.3.pack), !dbg !216
// CHECK:STDOUT:   %Count.call = call i64 @_CCount.Main.fe218f8d6a5eeccd(ptr @.7fc.loc7_18.5), !dbg !218
// CHECK:STDOUT:   ret i64 %Count.call, !dbg !219
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @"_CGet.A.Main:Code.Main"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @"_CGet.B.Main:Code.Main"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CForEach.Main.5fd020f59c727035(ptr %x) #0 !dbg !221 {
// CHECK:STDOUT:   %pack.elem = getelementptr inbounds { ptr, ptr, ptr }, ptr %x, i32 0, i32 0, !dbg !225
// CHECK:STDOUT:   %pack.elem.load = load ptr, ptr %pack.elem, align 8, !dbg !225
// CHECK:STDOUT:   %1 = call i64 @"_CGet.A.Main:Code.Main"(ptr %pack.elem.load), !dbg !225
// CHECK:STDOUT:   call void @_CConsume.Main(i64 %1), !dbg !226
// CHECK:STDOUT:   %pack.elem1 = getelementptr inbounds { ptr, ptr, ptr }, ptr %x, i32 0, i32 1, !dbg !225
// CHECK:STDOUT:   %pack.elem.load2 = load ptr, ptr %pack.elem1, align 8, !dbg !225
// CHECK:STDOUT:   %2 = call i64 @"_CGet.B.Main:Code.Main"(ptr %pack.elem.load2), !dbg !225
// CHECK:STDOUT:   call void @_CConsume.Main(i64 %2), !dbg !226
// CHECK:STDOUT:   %pack.elem3 = getelementptr inbounds { ptr, ptr, ptr }, ptr %x, i32 0, i32 2, !dbg !225
// CHECK:STDOUT:   %pack.elem.load4 = load ptr, ptr %pack.elem3, align 8, !dbg !225
// CHECK:STDOUT:   %3 = call i64 @"_CGet.A.Main:Code.Main"(ptr %pack.elem.load4), !dbg !225
// CHECK:STDOUT:   call void @_CConsume.Main(i64 %3), !dbg !226
// CHECK:STDOUT:   ret void, !dbg !227
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CCount.Main.fe218f8d6a5eeccd(ptr %x) #0 !dbg !229 {
// CHECK:STDOUT:   %1 = alloca i64, align 8, !dbg !234
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !234
// CHECK:STDOUT:   store i64 0, ptr %1, align 8, !dbg !234
// CHECK:STDOUT:   %pack.elem = getelementptr inbounds { i64, i1, i32 }, ptr %x, i32 0, i32 0, !dbg !239
// CHECK:STDOUT:   %pack.elem.load = load i64, ptr %pack.elem, align 8, !dbg !239
// CHECK:STDOUT:   %2 = call i64 @_COne.Main.f249b435619a5146(i64 %pack.elem.load), !dbg !240
// CHECK:STDOUT:   %3 = load i64, ptr %1, align 8, !dbg !238
// CHECK:STDOUT:   %4 = add i64 %3, %2, !dbg !241
// CHECK:STDOUT:   store i64 %4, ptr %1, align 8, !dbg !237
// CHECK:STDOUT:   %pack.elem1 = getelementptr inbounds { i64, i1, i32 }, ptr %x, i32 0, i32 1, !dbg !239
// CHECK:STDOUT:   %pack.elem.load2 = load i8, ptr %pack.elem1, align 1, !dbg !239
// CHECK:STDOUT:   %5 = trunc i8 %pack.elem.load2 to i1, !dbg !239
// CHECK:STDOUT:   %6 = call i64 @_COne.Main.a4c7fafe8a72cac4(i1 %5), !dbg !240
// CHECK:STDOUT:   %7 = load i64, ptr %1, align 8, !dbg !238
// CHECK:STDOUT:   %8 = add i64 %7, %6, !dbg !241
// CHECK:STDOUT:   store i64 %8, ptr %1, align 8, !dbg !237
// CHECK:STDOUT:   %pack.elem3 = getelementptr inbounds { i64, i1, i32 }, ptr %x, i32 0, i32 2, !dbg !239
// CHECK:STDOUT:   %pack.elem.load4 = load i32, ptr %pack.elem3, align 4, !dbg !239
// CHECK:STDOUT:   %9 = call i64 @_COne.Main.84588f41d61dafba(i32 %pack.elem.load4), !dbg !240
// CHECK:STDOUT:   %10 = load i64, ptr %1, align 8, !dbg !238
// CHECK:STDOUT:   %11 = add i64 %10, %9, !dbg !241
// CHECK:STDOUT:   store i64 %11, ptr %1, align 8, !dbg !237
// CHECK:STDOUT:   %12 = load i64, ptr %1, align 8, !dbg !242
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %1), !dbg !234
// CHECK:STDOUT:   ret i64 %12, !dbg !243
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CConsume.Main(i64)
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_COne.Main.f249b435619a5146(i64 %v) #0 !dbg !245 {
// CHECK:STDOUT:   ret i64 1, !dbg !250
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_COne.Main.a4c7fafe8a72cac4(i1 %v) #0 !dbg !252 {
// CHECK:STDOUT:   ret i64 1, !dbg !257
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_COne.Main.84588f41d61dafba(i32 %v) #0 !dbg !259 {
// CHECK:STDOUT:   ret i64 1, !dbg !264
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CConsume.Main, { 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!203}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !34 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !35 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !36 = !{!34, !35}
// CHECK:STDOUT: !37 = !DISubroutineType(types: !36)
// CHECK:STDOUT: !65 = !{null, !35}
// CHECK:STDOUT: !66 = !DISubroutineType(types: !65)
// CHECK:STDOUT: !86 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !111 = !{!34, !34}
// CHECK:STDOUT: !112 = !DISubroutineType(types: !111)
// CHECK:STDOUT: !114 = !{!34, !86}
// CHECK:STDOUT: !115 = !DISubroutineType(types: !114)
// CHECK:STDOUT: !182 = !DIFile(filename: "lib.carbon", directory: "")
// CHECK:STDOUT: !202 = !DIFile(filename: "use.carbon", directory: "")
// CHECK:STDOUT: !203 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !202, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !204 = !{!34, !35, !35}
// CHECK:STDOUT: !205 = !DISubroutineType(types: !204)
// CHECK:STDOUT: !206 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !202, line: 5, type: !205, spFlags: DISPFlagDefinition, unit: !203, retainedNodes: !220)
// CHECK:STDOUT: !207 = !DILocalVariable(arg: 1, scope: !206, type: !35)
// CHECK:STDOUT: !208 = !DILocalVariable(arg: 2, scope: !206, type: !35)
// CHECK:STDOUT: !213 = !DILocation(line: 6, column: 11, scope: !206)
// CHECK:STDOUT: !216 = !DILocation(line: 6, column: 3, scope: !206)
// CHECK:STDOUT: !218 = !DILocation(line: 7, column: 10, scope: !206)
// CHECK:STDOUT: !219 = !DILocation(line: 7, column: 3, scope: !206)
// CHECK:STDOUT: !220 = !{!207, !208}
// CHECK:STDOUT: !221 = distinct !DISubprogram(name: "ForEach", linkageName: "_CForEach.Main.5fd020f59c727035", scope: null, file: !182, line: 19, type: !66, spFlags: DISPFlagDefinition, unit: !203, retainedNodes: !228)
// CHECK:STDOUT: !222 = !DILocalVariable(arg: 1, scope: !221, type: !35)
// CHECK:STDOUT: !225 = !DILocation(line: 20, column: 15, scope: !221)
// CHECK:STDOUT: !226 = !DILocation(line: 20, column: 7, scope: !221)
// CHECK:STDOUT: !227 = !DILocation(line: 19, column: 1, scope: !221)
// CHECK:STDOUT: !228 = !{!222}
// CHECK:STDOUT: !229 = distinct !DISubprogram(name: "Count", linkageName: "_CCount.Main.fe218f8d6a5eeccd", scope: null, file: !182, line: 27, type: !37, spFlags: DISPFlagDefinition, unit: !203, retainedNodes: !244)
// CHECK:STDOUT: !230 = !DILocalVariable(arg: 1, scope: !229, type: !35)
// CHECK:STDOUT: !234 = !DILocation(line: 28, column: 3, scope: !229)
// CHECK:STDOUT: !237 = !DILocation(line: 29, column: 7, scope: !229)
// CHECK:STDOUT: !238 = !DILocation(line: 29, column: 15, scope: !229)
// CHECK:STDOUT: !239 = !DILocation(line: 29, column: 22, scope: !229)
// CHECK:STDOUT: !240 = !DILocation(line: 29, column: 18, scope: !229)
// CHECK:STDOUT: !241 = !DILocation(line: 29, column: 11, scope: !229)
// CHECK:STDOUT: !242 = !DILocation(line: 30, column: 10, scope: !229)
// CHECK:STDOUT: !243 = !DILocation(line: 30, column: 3, scope: !229)
// CHECK:STDOUT: !244 = !{!230}
// CHECK:STDOUT: !245 = distinct !DISubprogram(name: "One", linkageName: "_COne.Main.f249b435619a5146", scope: null, file: !182, line: 25, type: !112, spFlags: DISPFlagDefinition, unit: !203, retainedNodes: !251)
// CHECK:STDOUT: !246 = !DILocalVariable(arg: 1, scope: !245, type: !34)
// CHECK:STDOUT: !250 = !DILocation(line: 25, column: 39, scope: !245)
// CHECK:STDOUT: !251 = !{!246}
// CHECK:STDOUT: !252 = distinct !DISubprogram(name: "One", linkageName: "_COne.Main.a4c7fafe8a72cac4", scope: null, file: !182, line: 25, type: !37, spFlags: DISPFlagDefinition, unit: !203, retainedNodes: !258)
// CHECK:STDOUT: !253 = !DILocalVariable(arg: 1, scope: !252, type: !35)
// CHECK:STDOUT: !257 = !DILocation(line: 25, column: 39, scope: !252)
// CHECK:STDOUT: !258 = !{!253}
// CHECK:STDOUT: !259 = distinct !DISubprogram(name: "One", linkageName: "_COne.Main.84588f41d61dafba", scope: null, file: !182, line: 25, type: !115, spFlags: DISPFlagDefinition, unit: !203, retainedNodes: !265)
// CHECK:STDOUT: !260 = !DILocalVariable(arg: 1, scope: !259, type: !86)
// CHECK:STDOUT: !264 = !DILocation(line: 25, column: 39, scope: !259)
// CHECK:STDOUT: !265 = !{!260}
// CHECK:STDOUT:

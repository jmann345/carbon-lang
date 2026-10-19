// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/template/initialize.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/template/initialize.carbon

// --- return_param_tuple.carbon
library "[[@TEST_NAME]]";

fn Id[template T: type](p: T) -> T {
  return p;
}

fn Use(t: (i32, i32)) -> (i32, i32) {
  return Id(t);
}

// --- return_tuple.carbon
library "[[@TEST_NAME]]";

fn Dup[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn Use() -> (i32, i32) {
  return Dup(4 as i32);
}

// --- class_method_return_tuple.carbon
library "[[@TEST_NAME]]";

class H(template T: type) {
  var a: T;
  fn Both(self) -> (T, T) { return (self.a, self.a); }
}

fn Use(h: H(i32)) -> (i32, i32) {
  return h.Both();
}

// --- return_tuple_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> ((T, T), i32) {
  return (Pair(x), 1);
}

fn Use() -> ((i32, i32), i32) {
  return G(3 as i32);
}

// --- let_class_value_of_call.carbon
library "[[@TEST_NAME]]";

class C {
  var a: (i32, i32);
  var b: i32;
}

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> i32 {
  let c: C = {.a = Pair(x), .b = 1};
  return c.a.0 + c.a.1 + c.b;
}

fn Use() -> i32 {
  return G(3 as i32);
}

// --- return_struct_convert.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> {.a: i64} {
  return x;
}

fn Use(s: {.a: i32}) -> {.a: i64} {
  return F(s);
}

// --- var_with_destructor.carbon
library "[[@TEST_NAME]]";

class D {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n + 10}; }
  }
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

fn F[template T: type](x: T) -> i32 {
  var unused y: T = x;
  return 0;
}

fn Use(d: D) -> i32 {
  return F(d);
}

// --- destructure_param.carbon
library "[[@TEST_NAME]]";

fn Sum[template T: type](p: T) -> i32 {
  let (a: i32, b: i32) = p;
  return a + b;
}

fn Use(t: (i32, i32)) -> i32 {
  return Sum(t);
}

// --- return_tuple_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> (T, T) {
  return (x, 1);
}

fn Use() -> (i32, i32) {
  return M(4 as i32);
}

// --- return_struct_constant_field.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> {.a: T, .b: T} {
  return {.a = x, .b = 2};
}

fn Use() -> {.a: i32, .b: i32} {
  return M(4 as i32);
}

// --- return_array_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> array(T, 2) {
  return (x, 3);
}

fn Use() -> array(i32, 2) {
  return M(4 as i32);
}

// --- var_tuple_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> (T, T) {
  var p: (T, T) = (x, 1);
  return p;
}

fn Use() -> (i32, i32) {
  return M(4 as i32);
}

// --- assign_tuple_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T, y: T) -> (T, T) {
  var t: (T, T) = (x, y);
  t = (x, 1);
  return t;
}

fn Use() -> (i32, i32) {
  return M(4 as i32, 9 as i32);
}

// --- return_nested_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> ((T, T), T) {
  return ((x, 2), 3);
}

fn Use() -> ((i32, i32), i32) {
  return M(4 as i32);
}

// --- template_value_element.carbon
library "[[@TEST_NAME]]";

fn M(template N: i32, x: i32) -> (i32, i32) {
  return (N, x);
}

fn Use() -> (i32, i32) {
  return M(3, 4);
}

// --- return_class_constant_field.carbon
library "[[@TEST_NAME]]";

class P(T: type) {
  var a: T;
  var b: T;
}

fn M[template T: type](x: T) -> P(T) {
  return {.a = x, .b = 1};
}

fn Use() -> P(i32) {
  return M(4 as i32);
}

// --- var_class_constant_field.carbon
library "[[@TEST_NAME]]";

class P(T: type) {
  var a: T;
  var b: T;
}

fn M[template T: type](x: T) -> T {
  var p: P(T) = {.a = x, .b = 2};
  return p.b;
}

fn Use() -> i32 {
  return M(4 as i32);
}

// --- return_tuple_of_associated_type.carbon
library "[[@TEST_NAME]]";

interface Container {
  let Elem: type;
  fn Get(self) -> Elem;
}

class Ints {
  var n: i32;
  impl as Container where .Elem = i32 {
    fn Get(self) -> i32 { return self.n; }
  }
}

fn F[template T: Container](x: T) -> (T.Elem, i32) {
  return (x.Get(), 5);
}

fn Use(n: Ints) -> (i32, i32) {
  return F(n);
}

// --- var_tuple_of_associated_type.carbon
library "[[@TEST_NAME]]";

interface Container {
  let Elem: type;
}

class Ints {
  impl as Container where .Elem = i32 {}
}

fn G[template T: Container](unused x: T) -> i32 {
  var t: (T.Elem, i32) = (4, 5);
  return t.1;
}

fn Use(n: Ints) -> i32 {
  return G(n);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'return_param_tuple.carbon'
// CHECK:STDOUT: source_filename = "return_param_tuple.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(ptr sret({ i32, i32 }) %return, ptr %t) #0 !dbg !10 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CId.Main.00f31208999b670d(ptr %return, ptr %t), !dbg !16
// CHECK:STDOUT:   ret void, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CId.Main.00f31208999b670d(ptr sret({ i32, i32 }) %return, ptr %p) #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.ccc.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %p, i32 0, i32 0, !dbg !24
// CHECK:STDOUT:   %tuple.elem0.ccc.tuple.elem.load = load i32, ptr %tuple.elem0.ccc.tuple.elem, align 4, !dbg !24
// CHECK:STDOUT:   %tuple.elem0.ac2.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !24
// CHECK:STDOUT:   store i32 %tuple.elem0.ccc.tuple.elem.load, ptr %tuple.elem0.ac2.tuple.elem, align 4, !dbg !24
// CHECK:STDOUT:   %tuple.elem1.b60.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %p, i32 0, i32 1, !dbg !24
// CHECK:STDOUT:   %tuple.elem1.b60.tuple.elem.load = load i32, ptr %tuple.elem1.b60.tuple.elem, align 4, !dbg !24
// CHECK:STDOUT:   %tuple.elem1.3d1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !24
// CHECK:STDOUT:   store i32 %tuple.elem1.b60.tuple.elem.load, ptr %tuple.elem1.3d1.tuple.elem, align 4, !dbg !24
// CHECK:STDOUT:   ret void, !dbg !25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "return_param_tuple.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !4, line: 7, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !18)
// CHECK:STDOUT: !11 = !DILocalVariable(arg: 1, scope: !10, type: !7)
// CHECK:STDOUT: !16 = !DILocation(line: 8, column: 10, scope: !10)
// CHECK:STDOUT: !17 = !DILocation(line: 8, column: 3, scope: !10)
// CHECK:STDOUT: !18 = !{!11}
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "Id", linkageName: "_CId.Main.00f31208999b670d", scope: null, file: !4, line: 3, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !26)
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !19, type: !7)
// CHECK:STDOUT: !24 = !DILocation(line: 4, column: 10, scope: !19)
// CHECK:STDOUT: !25 = !DILocation(line: 4, column: 3, scope: !19)
// CHECK:STDOUT: !26 = !{!20}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'return_tuple.carbon'
// CHECK:STDOUT: source_filename = "return_tuple.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(ptr sret({ i32, i32 }) %return) #0 !dbg !31 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDup.Main.84588f41d61dafba(ptr %return, i32 4), !dbg !34
// CHECK:STDOUT:   ret void, !dbg !37
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDup.Main.84588f41d61dafba(ptr sret({ i32, i32 }) %return, i32 %x) #0 !dbg !38 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !45
// CHECK:STDOUT:   store i32 %x, ptr %tuple.elem0.tuple.elem, align 4, !dbg !45
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !45
// CHECK:STDOUT:   store i32 %x, ptr %tuple.elem1.tuple.elem, align 4, !dbg !45
// CHECK:STDOUT:   ret void, !dbg !46
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!28}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !27 = !DIFile(filename: "return_tuple.carbon", directory: "")
// CHECK:STDOUT: !28 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !27, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !29 = !{!7}
// CHECK:STDOUT: !30 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !31 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !27, line: 7, type: !30, spFlags: DISPFlagDefinition, unit: !28)
// CHECK:STDOUT: !34 = !DILocation(line: 8, column: 10, scope: !31)
// CHECK:STDOUT: !35 = !{!7, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !37 = !DILocation(line: 8, column: 3, scope: !31)
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "Dup", linkageName: "_CDup.Main.84588f41d61dafba", scope: null, file: !27, line: 3, type: !36, spFlags: DISPFlagDefinition, unit: !28, retainedNodes: !47)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !38, type: !6)
// CHECK:STDOUT: !45 = !DILocation(line: 4, column: 10, scope: !38)
// CHECK:STDOUT: !46 = !DILocation(line: 4, column: 3, scope: !38)
// CHECK:STDOUT: !47 = !{!39}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'class_method_return_tuple.carbon'
// CHECK:STDOUT: source_filename = "class_method_return_tuple.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(ptr sret({ i32, i32 }) %return, ptr %h) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CBoth.H.Main.84588f41d61dafba(ptr %return, ptr %h), !dbg !55
// CHECK:STDOUT:   ret void, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBoth.H.Main.84588f41d61dafba(ptr sret({ i32, i32 }) %return, ptr %self) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.c4e747.2.a = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !63
// CHECK:STDOUT:   %.ac8354.2 = load i32, ptr %.c4e747.2.a, align 4, !dbg !63
// CHECK:STDOUT:   %.c4e747.1.a = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   %.ac8354.1 = load i32, ptr %.c4e747.1.a, align 4, !dbg !64
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !65
// CHECK:STDOUT:   store i32 %.ac8354.2, ptr %tuple.elem0.tuple.elem, align 4, !dbg !65
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !65
// CHECK:STDOUT:   store i32 %.ac8354.1, ptr %tuple.elem1.tuple.elem, align 4, !dbg !65
// CHECK:STDOUT:   ret void, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!49}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !48 = !DIFile(filename: "class_method_return_tuple.carbon", directory: "")
// CHECK:STDOUT: !49 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !48, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !48, line: 8, type: !9, spFlags: DISPFlagDefinition, unit: !49, retainedNodes: !57)
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 1, scope: !50, type: !7)
// CHECK:STDOUT: !55 = !DILocation(line: 9, column: 10, scope: !50)
// CHECK:STDOUT: !56 = !DILocation(line: 9, column: 3, scope: !50)
// CHECK:STDOUT: !57 = !{!51}
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "Both", linkageName: "_CBoth.H.Main.84588f41d61dafba", scope: null, file: !48, line: 5, type: !9, spFlags: DISPFlagDefinition, unit: !49, retainedNodes: !67)
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !58, type: !7)
// CHECK:STDOUT: !63 = !DILocation(line: 5, column: 37, scope: !58)
// CHECK:STDOUT: !64 = !DILocation(line: 5, column: 45, scope: !58)
// CHECK:STDOUT: !65 = !DILocation(line: 5, column: 36, scope: !58)
// CHECK:STDOUT: !66 = !DILocation(line: 5, column: 29, scope: !58)
// CHECK:STDOUT: !67 = !{!59}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'return_tuple_of_call.carbon'
// CHECK:STDOUT: source_filename = "return_tuple_of_call.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(ptr sret({ { i32, i32 }, i32 }) %return) #0 !dbg !70 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CG.Main.84588f41d61dafba(ptr %return, i32 3), !dbg !73
// CHECK:STDOUT:   ret void, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CG.Main.84588f41d61dafba(ptr sret({ { i32, i32 }, i32 }) %return, i32 %x) #0 !dbg !75 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.e8e.tuple.elem = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %return, i32 0, i32 0, !dbg !82
// CHECK:STDOUT:   call void @_CPair.Main.84588f41d61dafba(ptr %tuple.elem0.e8e.tuple.elem, i32 %x), !dbg !81
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %return, i32 0, i32 1, !dbg !82
// CHECK:STDOUT:   store i32 1, ptr %tuple.elem1.tuple.elem, align 4, !dbg !82
// CHECK:STDOUT:   ret void, !dbg !83
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CPair.Main.84588f41d61dafba(ptr sret({ i32, i32 }) %return, i32 %x) #0 !dbg !85 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.a32.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !92
// CHECK:STDOUT:   store i32 %x, ptr %tuple.elem0.a32.tuple.elem, align 4, !dbg !92
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !92
// CHECK:STDOUT:   store i32 %x, ptr %tuple.elem1.tuple.elem, align 4, !dbg !92
// CHECK:STDOUT:   ret void, !dbg !93
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!69}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !29 = !{!7}
// CHECK:STDOUT: !30 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !35 = !{!7, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !68 = !DIFile(filename: "return_tuple_of_call.carbon", directory: "")
// CHECK:STDOUT: !69 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !68, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !68, line: 11, type: !30, spFlags: DISPFlagDefinition, unit: !69)
// CHECK:STDOUT: !73 = !DILocation(line: 12, column: 10, scope: !70)
// CHECK:STDOUT: !74 = !DILocation(line: 12, column: 3, scope: !70)
// CHECK:STDOUT: !75 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.84588f41d61dafba", scope: null, file: !68, line: 7, type: !36, spFlags: DISPFlagDefinition, unit: !69, retainedNodes: !84)
// CHECK:STDOUT: !76 = !DILocalVariable(arg: 1, scope: !75, type: !6)
// CHECK:STDOUT: !81 = !DILocation(line: 8, column: 11, scope: !75)
// CHECK:STDOUT: !82 = !DILocation(line: 8, column: 10, scope: !75)
// CHECK:STDOUT: !83 = !DILocation(line: 8, column: 3, scope: !75)
// CHECK:STDOUT: !84 = !{!76}
// CHECK:STDOUT: !85 = distinct !DISubprogram(name: "Pair", linkageName: "_CPair.Main.84588f41d61dafba", scope: null, file: !68, line: 3, type: !36, spFlags: DISPFlagDefinition, unit: !69, retainedNodes: !94)
// CHECK:STDOUT: !86 = !DILocalVariable(arg: 1, scope: !85, type: !6)
// CHECK:STDOUT: !92 = !DILocation(line: 4, column: 10, scope: !85)
// CHECK:STDOUT: !93 = !DILocation(line: 4, column: 3, scope: !85)
// CHECK:STDOUT: !94 = !{!86}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'let_class_value_of_call.carbon'
// CHECK:STDOUT: source_filename = "let_class_value_of_call.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !99 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call i32 @_CG.Main.84588f41d61dafba(i32 3), !dbg !102
// CHECK:STDOUT:   ret i32 %G.call, !dbg !105
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CG.Main.84588f41d61dafba(i32 %x) #0 !dbg !106 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.29d.temp = alloca { { i32, i32 }, i32 }, align 4, !dbg !113
// CHECK:STDOUT:   %tuple.loc14_11 = alloca { i32, i32 }, align 4, !dbg !116
// CHECK:STDOUT:   %tuple.loc14_19 = alloca { i32, i32 }, align 4, !dbg !117
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.29d.temp), !dbg !113
// CHECK:STDOUT:   %.863.a = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %.29d.temp, i32 0, i32 0, !dbg !113
// CHECK:STDOUT:   call void @_CPair.Main.84588f41d61dafba(ptr %.863.a, i32 %x), !dbg !112
// CHECK:STDOUT:   %.e5a.b = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %.29d.temp, i32 0, i32 1, !dbg !113
// CHECK:STDOUT:   store i32 1, ptr %.e5a.b, align 4, !dbg !113
// CHECK:STDOUT:   %.loc14_11.1.a = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %.29d.temp, i32 0, i32 0, !dbg !116
// CHECK:STDOUT:   %tuple.elem0.loc14_11.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc14_11.1.a, i32 0, i32 0, !dbg !116
// CHECK:STDOUT:   %.loc14_11.2 = load i32, ptr %tuple.elem0.loc14_11.tuple.elem, align 4, !dbg !116
// CHECK:STDOUT:   %tuple.elem1.loc14_11.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc14_11.1.a, i32 0, i32 1, !dbg !116
// CHECK:STDOUT:   %.loc14_11.3 = load i32, ptr %tuple.elem1.loc14_11.tuple.elem, align 4, !dbg !116
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %tuple.loc14_11), !dbg !116
// CHECK:STDOUT:   %tuple.loc14_111 = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.loc14_11, i32 0, i32 0, !dbg !116
// CHECK:STDOUT:   store i32 %.loc14_11.2, ptr %tuple.loc14_111, align 4, !dbg !116
// CHECK:STDOUT:   %tuple.loc14_112 = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.loc14_11, i32 0, i32 1, !dbg !116
// CHECK:STDOUT:   store i32 %.loc14_11.3, ptr %tuple.loc14_112, align 4, !dbg !116
// CHECK:STDOUT:   %tuple.elem0.loc14_13.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.loc14_11, i32 0, i32 0, !dbg !116
// CHECK:STDOUT:   %tuple.elem0.loc14_13.tuple.elem.load = load i32, ptr %tuple.elem0.loc14_13.tuple.elem, align 4, !dbg !116
// CHECK:STDOUT:   %.loc14_19.1.a = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %.29d.temp, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %tuple.elem0.loc14_19.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc14_19.1.a, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %.loc14_19.2 = load i32, ptr %tuple.elem0.loc14_19.tuple.elem, align 4, !dbg !117
// CHECK:STDOUT:   %tuple.elem1.loc14_19.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc14_19.1.a, i32 0, i32 1, !dbg !117
// CHECK:STDOUT:   %.loc14_19.3 = load i32, ptr %tuple.elem1.loc14_19.tuple.elem, align 4, !dbg !117
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %tuple.loc14_19), !dbg !117
// CHECK:STDOUT:   %tuple.loc14_193 = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.loc14_19, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   store i32 %.loc14_19.2, ptr %tuple.loc14_193, align 4, !dbg !117
// CHECK:STDOUT:   %tuple.loc14_194 = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.loc14_19, i32 0, i32 1, !dbg !117
// CHECK:STDOUT:   store i32 %.loc14_19.3, ptr %tuple.loc14_194, align 4, !dbg !117
// CHECK:STDOUT:   %tuple.elem1.loc14_21.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.loc14_19, i32 0, i32 1, !dbg !117
// CHECK:STDOUT:   %tuple.elem1.loc14_21.tuple.elem.load = load i32, ptr %tuple.elem1.loc14_21.tuple.elem, align 4, !dbg !117
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc14_16 = add i32 %tuple.elem0.loc14_13.tuple.elem.load, %tuple.elem1.loc14_21.tuple.elem.load, !dbg !116
// CHECK:STDOUT:   %.loc14_27.1.b = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %.29d.temp, i32 0, i32 1, !dbg !118
// CHECK:STDOUT:   %.loc14_27.2 = load i32, ptr %.loc14_27.1.b, align 4, !dbg !118
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc14_24 = add i32 %Int.as.AddWith.impl.Op.call.loc14_16, %.loc14_27.2, !dbg !116
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call.loc14_24, !dbg !119
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CPair.Main.84588f41d61dafba(ptr sret({ i32, i32 }) %return, i32 %x) #0 !dbg !121 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !128
// CHECK:STDOUT:   store i32 %x, ptr %tuple.elem0.tuple.elem, align 4, !dbg !128
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !128
// CHECK:STDOUT:   store i32 %x, ptr %tuple.elem1.tuple.elem, align 4, !dbg !128
// CHECK:STDOUT:   ret void, !dbg !129
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!96}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !35 = !{!7, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !95 = !DIFile(filename: "let_class_value_of_call.carbon", directory: "")
// CHECK:STDOUT: !96 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !95, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !97 = !{!6}
// CHECK:STDOUT: !98 = !DISubroutineType(types: !97)
// CHECK:STDOUT: !99 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !95, line: 17, type: !98, spFlags: DISPFlagDefinition, unit: !96)
// CHECK:STDOUT: !102 = !DILocation(line: 18, column: 10, scope: !99)
// CHECK:STDOUT: !103 = !{!6, !6}
// CHECK:STDOUT: !104 = !DISubroutineType(types: !103)
// CHECK:STDOUT: !105 = !DILocation(line: 18, column: 3, scope: !99)
// CHECK:STDOUT: !106 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.84588f41d61dafba", scope: null, file: !95, line: 12, type: !104, spFlags: DISPFlagDefinition, unit: !96, retainedNodes: !120)
// CHECK:STDOUT: !107 = !DILocalVariable(arg: 1, scope: !106, type: !6)
// CHECK:STDOUT: !112 = !DILocation(line: 13, column: 20, scope: !106)
// CHECK:STDOUT: !113 = !DILocation(line: 13, column: 14, scope: !106)
// CHECK:STDOUT: !116 = !DILocation(line: 14, column: 10, scope: !106)
// CHECK:STDOUT: !117 = !DILocation(line: 14, column: 18, scope: !106)
// CHECK:STDOUT: !118 = !DILocation(line: 14, column: 26, scope: !106)
// CHECK:STDOUT: !119 = !DILocation(line: 14, column: 3, scope: !106)
// CHECK:STDOUT: !120 = !{!107}
// CHECK:STDOUT: !121 = distinct !DISubprogram(name: "Pair", linkageName: "_CPair.Main.84588f41d61dafba", scope: null, file: !95, line: 8, type: !36, spFlags: DISPFlagDefinition, unit: !96, retainedNodes: !130)
// CHECK:STDOUT: !122 = !DILocalVariable(arg: 1, scope: !121, type: !6)
// CHECK:STDOUT: !128 = !DILocation(line: 9, column: 10, scope: !121)
// CHECK:STDOUT: !129 = !DILocation(line: 9, column: 3, scope: !121)
// CHECK:STDOUT: !130 = !{!122}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'return_struct_convert.carbon'
// CHECK:STDOUT: source_filename = "return_struct_convert.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define { i64 } @_CUse.Main({ i32 } %s) #0 !dbg !134 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %F.call = call { i64 } @_CF.Main.c458dc7284a9296f({ i32 } %s), !dbg !140
// CHECK:STDOUT:   ret { i64 } %F.call, !dbg !141
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr { i64 } @_CF.Main.c458dc7284a9296f({ i32 } %x) #0 !dbg !143 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.f21.a = extractvalue { i32 } %x, 0, !dbg !148
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.call = call i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.f4e5d9509bf46ebe"(i32 %.f21.a), !dbg !148
// CHECK:STDOUT:   %.121.struct.init = insertvalue { i64 } poison, i64 %From.as_type.as.ImplicitAs.impl.Convert.call, 0, !dbg !148
// CHECK:STDOUT:   ret { i64 } %.121.struct.init, !dbg !149
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.f4e5d9509bf46ebe"(i32 %self) #0 !dbg !154 {
// CHECK:STDOUT:   %1 = call i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self), !dbg !159
// CHECK:STDOUT:   %2 = sext i32 %1 to i64, !dbg !160
// CHECK:STDOUT:   ret i64 %2, !dbg !161
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self) #0 !dbg !163 {
// CHECK:STDOUT:   ret i32 %self, !dbg !169
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!132}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !103 = !{!6, !6}
// CHECK:STDOUT: !104 = !DISubroutineType(types: !103)
// CHECK:STDOUT: !131 = !DIFile(filename: "return_struct_convert.carbon", directory: "")
// CHECK:STDOUT: !132 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !131, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !133 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !134 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !131, line: 7, type: !9, spFlags: DISPFlagDefinition, unit: !132, retainedNodes: !142)
// CHECK:STDOUT: !135 = !DILocalVariable(arg: 1, scope: !134, type: !7)
// CHECK:STDOUT: !140 = !DILocation(line: 8, column: 10, scope: !134)
// CHECK:STDOUT: !141 = !DILocation(line: 8, column: 3, scope: !134)
// CHECK:STDOUT: !142 = !{!135}
// CHECK:STDOUT: !143 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.c458dc7284a9296f", scope: null, file: !131, line: 3, type: !9, spFlags: DISPFlagDefinition, unit: !132, retainedNodes: !152)
// CHECK:STDOUT: !144 = !DILocalVariable(arg: 1, scope: !143, type: !7)
// CHECK:STDOUT: !148 = !DILocation(line: 4, column: 10, scope: !143)
// CHECK:STDOUT: !149 = !DILocation(line: 4, column: 3, scope: !143)
// CHECK:STDOUT: !150 = !{!133, !6}
// CHECK:STDOUT: !151 = !DISubroutineType(types: !150)
// CHECK:STDOUT: !152 = !{!144}
// CHECK:STDOUT: !153 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !154 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.f4e5d9509bf46ebe", scope: null, file: !153, line: 64, type: !151, spFlags: DISPFlagDefinition, unit: !132, retainedNodes: !162)
// CHECK:STDOUT: !155 = !DILocalVariable(arg: 1, scope: !154, type: !6)
// CHECK:STDOUT: !159 = !DILocation(line: 66, column: 17, scope: !154)
// CHECK:STDOUT: !160 = !DILocation(line: 66, column: 12, scope: !154)
// CHECK:STDOUT: !161 = !DILocation(line: 66, column: 5, scope: !154)
// CHECK:STDOUT: !162 = !{!155}
// CHECK:STDOUT: !163 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8", scope: null, file: !153, line: 59, type: !104, spFlags: DISPFlagDefinition, unit: !132, retainedNodes: !170)
// CHECK:STDOUT: !164 = !DILocalVariable(arg: 1, scope: !163, type: !6)
// CHECK:STDOUT: !169 = !DILocation(line: 59, column: 28, scope: !163)
// CHECK:STDOUT: !170 = !{!164}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'var_with_destructor.carbon'
// CHECK:STDOUT: source_filename = "var_with_destructor.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.D.Main:Copy.Core"(ptr sret({ i32 }) %return, ptr %self) #0 !dbg !177 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_44.1.n = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !182
// CHECK:STDOUT:   %.loc6_44.2 = load i32, ptr %.loc6_44.1.n, align 4, !dbg !182
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc6_44.2, 10, !dbg !182
// CHECK:STDOUT:   %.loc6_51.2.n = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !183
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %.loc6_51.2.n, align 4, !dbg !183
// CHECK:STDOUT:   ret void, !dbg !184
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.D.Main:Destroy.Core"(ptr %self) #0 !dbg !186 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !189
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main(ptr %d) #0 !dbg !191 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %F.call = call i32 @_CF.Main.931317eeae6ffe17(ptr %d), !dbg !197
// CHECK:STDOUT:   ret i32 %F.call, !dbg !198
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CF.Main.931317eeae6ffe17(ptr %x) #0 !dbg !200 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %y.var = alloca { i32 }, align 4, !dbg !205
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %y.var), !dbg !205
// CHECK:STDOUT:   call void @"_COp.D.Main:Copy.Core"(ptr %y.var, ptr %x), !dbg !206
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.5613f446ca4e6e1f(ptr %y.var), !dbg !205
// CHECK:STDOUT:   ret i32 0, !dbg !208
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.5613f446ca4e6e1f(ptr %self) #0 !dbg !211 {
// CHECK:STDOUT:   call void @"_COp.D.Main:Destroy.Core"(ptr %self), !dbg !214
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.5613f446ca4e6e1f(ptr %self), !dbg !215
// CHECK:STDOUT:   ret void, !dbg !216
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.5613f446ca4e6e1f(ptr %self) #0 !dbg !218 {
// CHECK:STDOUT:   ret void, !dbg !221
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!172}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !171 = !DIFile(filename: "var_with_destructor.carbon", directory: "")
// CHECK:STDOUT: !172 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !171, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !173 = !{null, !7}
// CHECK:STDOUT: !174 = !DISubroutineType(types: !173)
// CHECK:STDOUT: !175 = !{!6, !7}
// CHECK:STDOUT: !176 = !DISubroutineType(types: !175)
// CHECK:STDOUT: !177 = distinct !DISubprogram(name: "Op", linkageName: "_COp.D.Main:Copy.Core", scope: null, file: !171, line: 6, type: !9, spFlags: DISPFlagDefinition, unit: !172, retainedNodes: !185)
// CHECK:STDOUT: !178 = !DILocalVariable(arg: 1, scope: !177, type: !7)
// CHECK:STDOUT: !182 = !DILocation(line: 6, column: 40, scope: !177)
// CHECK:STDOUT: !183 = !DILocation(line: 6, column: 34, scope: !177)
// CHECK:STDOUT: !184 = !DILocation(line: 6, column: 27, scope: !177)
// CHECK:STDOUT: !185 = !{!178}
// CHECK:STDOUT: !186 = distinct !DISubprogram(name: "Op", linkageName: "_COp.D.Main:Destroy.Core", scope: null, file: !171, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !172, retainedNodes: !190)
// CHECK:STDOUT: !187 = !DILocalVariable(arg: 1, scope: !186, type: !7)
// CHECK:STDOUT: !189 = !DILocation(line: 9, column: 5, scope: !186)
// CHECK:STDOUT: !190 = !{!187}
// CHECK:STDOUT: !191 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !171, line: 18, type: !176, spFlags: DISPFlagDefinition, unit: !172, retainedNodes: !199)
// CHECK:STDOUT: !192 = !DILocalVariable(arg: 1, scope: !191, type: !7)
// CHECK:STDOUT: !197 = !DILocation(line: 19, column: 10, scope: !191)
// CHECK:STDOUT: !198 = !DILocation(line: 19, column: 3, scope: !191)
// CHECK:STDOUT: !199 = !{!192}
// CHECK:STDOUT: !200 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.931317eeae6ffe17", scope: null, file: !171, line: 13, type: !176, spFlags: DISPFlagDefinition, unit: !172, retainedNodes: !209)
// CHECK:STDOUT: !201 = !DILocalVariable(arg: 1, scope: !200, type: !7)
// CHECK:STDOUT: !205 = !DILocation(line: 14, column: 3, scope: !200)
// CHECK:STDOUT: !206 = !DILocation(line: 14, column: 21, scope: !200)
// CHECK:STDOUT: !208 = !DILocation(line: 15, column: 3, scope: !200)
// CHECK:STDOUT: !209 = !{!201}
// CHECK:STDOUT: !210 = !DIFile(filename: "{{.*}}/prelude/destroy.carbon", directory: "")
// CHECK:STDOUT: !211 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.5613f446ca4e6e1f", scope: null, file: !210, line: 26, type: !174, spFlags: DISPFlagDefinition, unit: !172, retainedNodes: !217)
// CHECK:STDOUT: !212 = !DILocalVariable(arg: 1, scope: !211, type: !7)
// CHECK:STDOUT: !214 = !DILocation(line: 27, column: 5, scope: !211)
// CHECK:STDOUT: !215 = !DILocation(line: 28, column: 5, scope: !211)
// CHECK:STDOUT: !216 = !DILocation(line: 26, column: 3, scope: !211)
// CHECK:STDOUT: !217 = !{!212}
// CHECK:STDOUT: !218 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.5613f446ca4e6e1f", scope: null, file: !210, line: 19, type: !174, spFlags: DISPFlagDefinition, unit: !172, retainedNodes: !222)
// CHECK:STDOUT: !219 = !DILocalVariable(arg: 1, scope: !218, type: !7)
// CHECK:STDOUT: !221 = !DILocation(line: 19, column: 3, scope: !218)
// CHECK:STDOUT: !222 = !{!219}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'destructure_param.carbon'
// CHECK:STDOUT: source_filename = "destructure_param.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main(ptr %t) #0 !dbg !225 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Sum.call = call i32 @_CSum.Main.00f31208999b670d(ptr %t), !dbg !231
// CHECK:STDOUT:   ret i32 %Sum.call, !dbg !232
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CSum.Main.00f31208999b670d(ptr %p) #0 !dbg !234 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.loc4_26.1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %p, i32 0, i32 0, !dbg !239
// CHECK:STDOUT:   %tuple.elem0.loc4_26.1.tuple.elem.load = load i32, ptr %tuple.elem0.loc4_26.1.tuple.elem, align 4, !dbg !239
// CHECK:STDOUT:   %tuple.elem1.loc4_26.1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %p, i32 0, i32 1, !dbg !239
// CHECK:STDOUT:   %tuple.elem1.loc4_26.1.tuple.elem.load = load i32, ptr %tuple.elem1.loc4_26.1.tuple.elem, align 4, !dbg !239
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %tuple.elem0.loc4_26.1.tuple.elem.load, %tuple.elem1.loc4_26.1.tuple.elem.load, !dbg !244
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !246
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!224}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !175 = !{!6, !7}
// CHECK:STDOUT: !176 = !DISubroutineType(types: !175)
// CHECK:STDOUT: !223 = !DIFile(filename: "destructure_param.carbon", directory: "")
// CHECK:STDOUT: !224 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !223, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !225 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !223, line: 8, type: !176, spFlags: DISPFlagDefinition, unit: !224, retainedNodes: !233)
// CHECK:STDOUT: !226 = !DILocalVariable(arg: 1, scope: !225, type: !7)
// CHECK:STDOUT: !231 = !DILocation(line: 9, column: 10, scope: !225)
// CHECK:STDOUT: !232 = !DILocation(line: 9, column: 3, scope: !225)
// CHECK:STDOUT: !233 = !{!226}
// CHECK:STDOUT: !234 = distinct !DISubprogram(name: "Sum", linkageName: "_CSum.Main.00f31208999b670d", scope: null, file: !223, line: 3, type: !176, spFlags: DISPFlagDefinition, unit: !224, retainedNodes: !247)
// CHECK:STDOUT: !235 = !DILocalVariable(arg: 1, scope: !234, type: !7)
// CHECK:STDOUT: !239 = !DILocation(line: 4, column: 26, scope: !234)
// CHECK:STDOUT: !244 = !DILocation(line: 5, column: 10, scope: !234)
// CHECK:STDOUT: !246 = !DILocation(line: 5, column: 3, scope: !234)
// CHECK:STDOUT: !247 = !{!235}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'return_tuple_constant_element.carbon'
// CHECK:STDOUT: source_filename = "return_tuple_constant_element.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(ptr sret({ i32, i32 }) %return) #0 !dbg !250 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CM.Main.84588f41d61dafba(ptr %return, i32 4), !dbg !253
// CHECK:STDOUT:   ret void, !dbg !254
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CM.Main.84588f41d61dafba(ptr sret({ i32, i32 }) %return, i32 %x) #0 !dbg !255 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !261
// CHECK:STDOUT:   store i32 %x, ptr %tuple.elem0.tuple.elem, align 4, !dbg !261
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !261
// CHECK:STDOUT:   store i32 1, ptr %tuple.elem1.tuple.elem, align 4, !dbg !261
// CHECK:STDOUT:   ret void, !dbg !262
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!249}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !29 = !{!7}
// CHECK:STDOUT: !30 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !35 = !{!7, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !248 = !DIFile(filename: "return_tuple_constant_element.carbon", directory: "")
// CHECK:STDOUT: !249 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !248, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !250 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !248, line: 7, type: !30, spFlags: DISPFlagDefinition, unit: !249)
// CHECK:STDOUT: !253 = !DILocation(line: 8, column: 10, scope: !250)
// CHECK:STDOUT: !254 = !DILocation(line: 8, column: 3, scope: !250)
// CHECK:STDOUT: !255 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main.84588f41d61dafba", scope: null, file: !248, line: 3, type: !36, spFlags: DISPFlagDefinition, unit: !249, retainedNodes: !263)
// CHECK:STDOUT: !256 = !DILocalVariable(arg: 1, scope: !255, type: !6)
// CHECK:STDOUT: !261 = !DILocation(line: 4, column: 10, scope: !255)
// CHECK:STDOUT: !262 = !DILocation(line: 4, column: 3, scope: !255)
// CHECK:STDOUT: !263 = !{!256}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'return_struct_constant_field.carbon'
// CHECK:STDOUT: source_filename = "return_struct_constant_field.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(ptr sret({ i32, i32 }) %return) #0 !dbg !266 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CM.Main.84588f41d61dafba(ptr %return, i32 4), !dbg !269
// CHECK:STDOUT:   ret void, !dbg !270
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CM.Main.84588f41d61dafba(ptr sret({ i32, i32 }) %return, i32 %x) #0 !dbg !271 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.c27.a = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !277
// CHECK:STDOUT:   store i32 %x, ptr %.c27.a, align 4, !dbg !277
// CHECK:STDOUT:   %.ed7.b = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !277
// CHECK:STDOUT:   store i32 2, ptr %.ed7.b, align 4, !dbg !277
// CHECK:STDOUT:   ret void, !dbg !278
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!265}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !29 = !{!7}
// CHECK:STDOUT: !30 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !35 = !{!7, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !264 = !DIFile(filename: "return_struct_constant_field.carbon", directory: "")
// CHECK:STDOUT: !265 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !264, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !266 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !264, line: 7, type: !30, spFlags: DISPFlagDefinition, unit: !265)
// CHECK:STDOUT: !269 = !DILocation(line: 8, column: 10, scope: !266)
// CHECK:STDOUT: !270 = !DILocation(line: 8, column: 3, scope: !266)
// CHECK:STDOUT: !271 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main.84588f41d61dafba", scope: null, file: !264, line: 3, type: !36, spFlags: DISPFlagDefinition, unit: !265, retainedNodes: !279)
// CHECK:STDOUT: !272 = !DILocalVariable(arg: 1, scope: !271, type: !6)
// CHECK:STDOUT: !277 = !DILocation(line: 4, column: 10, scope: !271)
// CHECK:STDOUT: !278 = !DILocation(line: 4, column: 3, scope: !271)
// CHECK:STDOUT: !279 = !{!272}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'return_array_constant_element.carbon'
// CHECK:STDOUT: source_filename = "return_array_constant_element.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(ptr sret([2 x i32]) %return) #0 !dbg !282 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CM.Main.84588f41d61dafba(ptr %return, i32 4), !dbg !285
// CHECK:STDOUT:   ret void, !dbg !286
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CM.Main.84588f41d61dafba(ptr sret([2 x i32]) %return, i32 %x) #0 !dbg !287 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.f16.array.index = getelementptr inbounds [2 x i32], ptr %return, i32 0, i64 0, !dbg !293
// CHECK:STDOUT:   store i32 %x, ptr %.f16.array.index, align 4, !dbg !293
// CHECK:STDOUT:   %.69e.array.index = getelementptr inbounds [2 x i32], ptr %return, i32 0, i64 1, !dbg !293
// CHECK:STDOUT:   store i32 3, ptr %.69e.array.index, align 4, !dbg !293
// CHECK:STDOUT:   ret void, !dbg !294
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!281}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !29 = !{!7}
// CHECK:STDOUT: !30 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !35 = !{!7, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !280 = !DIFile(filename: "return_array_constant_element.carbon", directory: "")
// CHECK:STDOUT: !281 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !280, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !282 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !280, line: 7, type: !30, spFlags: DISPFlagDefinition, unit: !281)
// CHECK:STDOUT: !285 = !DILocation(line: 8, column: 10, scope: !282)
// CHECK:STDOUT: !286 = !DILocation(line: 8, column: 3, scope: !282)
// CHECK:STDOUT: !287 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main.84588f41d61dafba", scope: null, file: !280, line: 3, type: !36, spFlags: DISPFlagDefinition, unit: !281, retainedNodes: !295)
// CHECK:STDOUT: !288 = !DILocalVariable(arg: 1, scope: !287, type: !6)
// CHECK:STDOUT: !293 = !DILocation(line: 4, column: 10, scope: !287)
// CHECK:STDOUT: !294 = !DILocation(line: 4, column: 3, scope: !287)
// CHECK:STDOUT: !295 = !{!288}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'var_tuple_constant_element.carbon'
// CHECK:STDOUT: source_filename = "var_tuple_constant_element.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(ptr sret({ i32, i32 }) %return) #0 !dbg !300 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CM.Main.84588f41d61dafba(ptr %return, i32 4), !dbg !303
// CHECK:STDOUT:   ret void, !dbg !304
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !305 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !307
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !309 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !311
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !311
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !311
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !311
// CHECK:STDOUT:   ret void, !dbg !311
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !313 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self), !dbg !315
// CHECK:STDOUT:   ret void, !dbg !315
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CM.Main.84588f41d61dafba(ptr sret({ i32, i32 }) %return, i32 %x) #0 !dbg !317 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %p.var = alloca { i32, i32 }, align 4, !dbg !322
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %p.var), !dbg !322
// CHECK:STDOUT:   %tuple.elem0.ca6.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %p.var, i32 0, i32 0, !dbg !324
// CHECK:STDOUT:   store i32 %x, ptr %tuple.elem0.ca6.tuple.elem, align 4, !dbg !324
// CHECK:STDOUT:   %tuple.elem1.4b9.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %p.var, i32 0, i32 1, !dbg !324
// CHECK:STDOUT:   store i32 1, ptr %tuple.elem1.4b9.tuple.elem, align 4, !dbg !324
// CHECK:STDOUT:   %tuple.elem0.loc5_10.1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %p.var, i32 0, i32 0, !dbg !326
// CHECK:STDOUT:   %.ed5 = load i32, ptr %tuple.elem0.loc5_10.1.tuple.elem, align 4, !dbg !326
// CHECK:STDOUT:   %tuple.elem0.a32.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !326
// CHECK:STDOUT:   store i32 %.ed5, ptr %tuple.elem0.a32.tuple.elem, align 4, !dbg !326
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %p.var, i32 0, i32 1, !dbg !326
// CHECK:STDOUT:   %.17a = load i32, ptr %tuple.elem1.tuple.elem, align 4, !dbg !326
// CHECK:STDOUT:   %tuple.elem1.0ab.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !326
// CHECK:STDOUT:   store i32 %.17a, ptr %tuple.elem1.0ab.tuple.elem, align 4, !dbg !326
// CHECK:STDOUT:   call void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %p.var), !dbg !322
// CHECK:STDOUT:   ret void, !dbg !327
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!297}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !29 = !{!7}
// CHECK:STDOUT: !30 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !35 = !{!7, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !173 = !{null, !7}
// CHECK:STDOUT: !174 = !DISubroutineType(types: !173)
// CHECK:STDOUT: !296 = !DIFile(filename: "var_tuple_constant_element.carbon", directory: "")
// CHECK:STDOUT: !297 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !296, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !298 = !{null, !6}
// CHECK:STDOUT: !299 = !DISubroutineType(types: !298)
// CHECK:STDOUT: !300 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !296, line: 8, type: !30, spFlags: DISPFlagDefinition, unit: !297)
// CHECK:STDOUT: !303 = !DILocation(line: 9, column: 10, scope: !300)
// CHECK:STDOUT: !304 = !DILocation(line: 9, column: 3, scope: !300)
// CHECK:STDOUT: !305 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !296, line: 4, type: !299, spFlags: DISPFlagDefinition, unit: !297, retainedNodes: !308)
// CHECK:STDOUT: !306 = !DILocalVariable(arg: 1, scope: !305, type: !6)
// CHECK:STDOUT: !307 = !DILocation(line: 4, column: 3, scope: !305)
// CHECK:STDOUT: !308 = !{!306}
// CHECK:STDOUT: !309 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !296, line: 4, type: !174, spFlags: DISPFlagDefinition, unit: !297, retainedNodes: !312)
// CHECK:STDOUT: !310 = !DILocalVariable(arg: 1, scope: !309, type: !7)
// CHECK:STDOUT: !311 = !DILocation(line: 4, column: 3, scope: !309)
// CHECK:STDOUT: !312 = !{!310}
// CHECK:STDOUT: !313 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !296, line: 4, type: !174, spFlags: DISPFlagDefinition, unit: !297, retainedNodes: !316)
// CHECK:STDOUT: !314 = !DILocalVariable(arg: 1, scope: !313, type: !7)
// CHECK:STDOUT: !315 = !DILocation(line: 4, column: 3, scope: !313)
// CHECK:STDOUT: !316 = !{!314}
// CHECK:STDOUT: !317 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main.84588f41d61dafba", scope: null, file: !296, line: 3, type: !36, spFlags: DISPFlagDefinition, unit: !297, retainedNodes: !328)
// CHECK:STDOUT: !318 = !DILocalVariable(arg: 1, scope: !317, type: !6)
// CHECK:STDOUT: !322 = !DILocation(line: 4, column: 3, scope: !317)
// CHECK:STDOUT: !324 = !DILocation(line: 4, column: 19, scope: !317)
// CHECK:STDOUT: !326 = !DILocation(line: 5, column: 10, scope: !317)
// CHECK:STDOUT: !327 = !DILocation(line: 5, column: 3, scope: !317)
// CHECK:STDOUT: !328 = !{!318}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'assign_tuple_constant_element.carbon'
// CHECK:STDOUT: source_filename = "assign_tuple_constant_element.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(ptr sret({ i32, i32 }) %return) #0 !dbg !331 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CM.Main.84588f41d61dafba(ptr %return, i32 4, i32 9), !dbg !334
// CHECK:STDOUT:   ret void, !dbg !337
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !338 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !340
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !342 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !344
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !344
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !344
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !344
// CHECK:STDOUT:   ret void, !dbg !344
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !346 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self), !dbg !348
// CHECK:STDOUT:   ret void, !dbg !348
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CM.Main.84588f41d61dafba(ptr sret({ i32, i32 }) %return, i32 %x, i32 %y) #0 !dbg !350 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %t.var = alloca { i32, i32 }, align 4, !dbg !357
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %t.var), !dbg !357
// CHECK:STDOUT:   %tuple.elem0.cc5.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %t.var, i32 0, i32 0, !dbg !360
// CHECK:STDOUT:   store i32 %x, ptr %tuple.elem0.cc5.tuple.elem, align 4, !dbg !360
// CHECK:STDOUT:   %tuple.elem1.8ed.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %t.var, i32 0, i32 1, !dbg !360
// CHECK:STDOUT:   store i32 %y, ptr %tuple.elem1.8ed.tuple.elem, align 4, !dbg !360
// CHECK:STDOUT:   %tuple.elem0.8ca.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %t.var, i32 0, i32 0, !dbg !364
// CHECK:STDOUT:   store i32 %x, ptr %tuple.elem0.8ca.tuple.elem, align 4, !dbg !364
// CHECK:STDOUT:   %tuple.elem1.a10.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %t.var, i32 0, i32 1, !dbg !364
// CHECK:STDOUT:   store i32 1, ptr %tuple.elem1.a10.tuple.elem, align 4, !dbg !364
// CHECK:STDOUT:   %tuple.elem0.loc6_10.1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %t.var, i32 0, i32 0, !dbg !365
// CHECK:STDOUT:   %.0bf = load i32, ptr %tuple.elem0.loc6_10.1.tuple.elem, align 4, !dbg !365
// CHECK:STDOUT:   %tuple.elem0.e45.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !365
// CHECK:STDOUT:   store i32 %.0bf, ptr %tuple.elem0.e45.tuple.elem, align 4, !dbg !365
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %t.var, i32 0, i32 1, !dbg !365
// CHECK:STDOUT:   %.1f6 = load i32, ptr %tuple.elem1.tuple.elem, align 4, !dbg !365
// CHECK:STDOUT:   %tuple.elem1.537.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !365
// CHECK:STDOUT:   store i32 %.1f6, ptr %tuple.elem1.537.tuple.elem, align 4, !dbg !365
// CHECK:STDOUT:   call void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %t.var), !dbg !357
// CHECK:STDOUT:   ret void, !dbg !366
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!330}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !29 = !{!7}
// CHECK:STDOUT: !30 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !173 = !{null, !7}
// CHECK:STDOUT: !174 = !DISubroutineType(types: !173)
// CHECK:STDOUT: !298 = !{null, !6}
// CHECK:STDOUT: !299 = !DISubroutineType(types: !298)
// CHECK:STDOUT: !329 = !DIFile(filename: "assign_tuple_constant_element.carbon", directory: "")
// CHECK:STDOUT: !330 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !329, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !331 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !329, line: 9, type: !30, spFlags: DISPFlagDefinition, unit: !330)
// CHECK:STDOUT: !334 = !DILocation(line: 10, column: 10, scope: !331)
// CHECK:STDOUT: !335 = !{!7, !6, !6}
// CHECK:STDOUT: !336 = !DISubroutineType(types: !335)
// CHECK:STDOUT: !337 = !DILocation(line: 10, column: 3, scope: !331)
// CHECK:STDOUT: !338 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !329, line: 4, type: !299, spFlags: DISPFlagDefinition, unit: !330, retainedNodes: !341)
// CHECK:STDOUT: !339 = !DILocalVariable(arg: 1, scope: !338, type: !6)
// CHECK:STDOUT: !340 = !DILocation(line: 4, column: 3, scope: !338)
// CHECK:STDOUT: !341 = !{!339}
// CHECK:STDOUT: !342 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !329, line: 4, type: !174, spFlags: DISPFlagDefinition, unit: !330, retainedNodes: !345)
// CHECK:STDOUT: !343 = !DILocalVariable(arg: 1, scope: !342, type: !7)
// CHECK:STDOUT: !344 = !DILocation(line: 4, column: 3, scope: !342)
// CHECK:STDOUT: !345 = !{!343}
// CHECK:STDOUT: !346 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !329, line: 4, type: !174, spFlags: DISPFlagDefinition, unit: !330, retainedNodes: !349)
// CHECK:STDOUT: !347 = !DILocalVariable(arg: 1, scope: !346, type: !7)
// CHECK:STDOUT: !348 = !DILocation(line: 4, column: 3, scope: !346)
// CHECK:STDOUT: !349 = !{!347}
// CHECK:STDOUT: !350 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main.84588f41d61dafba", scope: null, file: !329, line: 3, type: !336, spFlags: DISPFlagDefinition, unit: !330, retainedNodes: !367)
// CHECK:STDOUT: !351 = !DILocalVariable(arg: 1, scope: !350, type: !6)
// CHECK:STDOUT: !352 = !DILocalVariable(arg: 2, scope: !350, type: !6)
// CHECK:STDOUT: !357 = !DILocation(line: 4, column: 3, scope: !350)
// CHECK:STDOUT: !360 = !DILocation(line: 4, column: 19, scope: !350)
// CHECK:STDOUT: !364 = !DILocation(line: 5, column: 7, scope: !350)
// CHECK:STDOUT: !365 = !DILocation(line: 6, column: 10, scope: !350)
// CHECK:STDOUT: !366 = !DILocation(line: 6, column: 3, scope: !350)
// CHECK:STDOUT: !367 = !{!351, !352}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'return_nested_constant_element.carbon'
// CHECK:STDOUT: source_filename = "return_nested_constant_element.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(ptr sret({ { i32, i32 }, i32 }) %return) #0 !dbg !370 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CM.Main.84588f41d61dafba(ptr %return, i32 4), !dbg !373
// CHECK:STDOUT:   ret void, !dbg !374
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CM.Main.84588f41d61dafba(ptr sret({ { i32, i32 }, i32 }) %return, i32 %x) #0 !dbg !375 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.9660ab.2.tuple.elem = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %return, i32 0, i32 0, !dbg !382
// CHECK:STDOUT:   %tuple.elem0.18b.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.elem0.9660ab.2.tuple.elem, i32 0, i32 0, !dbg !381
// CHECK:STDOUT:   store i32 %x, ptr %tuple.elem0.18b.tuple.elem, align 4, !dbg !381
// CHECK:STDOUT:   %tuple.elem0.9660ab.1.tuple.elem = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %return, i32 0, i32 0, !dbg !382
// CHECK:STDOUT:   %tuple.elem1.f67.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.elem0.9660ab.1.tuple.elem, i32 0, i32 1, !dbg !381
// CHECK:STDOUT:   %tuple.elem0.loc4_20.1.tuple.elem = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %return, i32 0, i32 0, !dbg !382
// CHECK:STDOUT:   store i32 2, ptr %tuple.elem1.f67.tuple.elem, align 4, !dbg !381
// CHECK:STDOUT:   %tuple.elem1.5d7.tuple.elem = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %return, i32 0, i32 1, !dbg !382
// CHECK:STDOUT:   store i32 3, ptr %tuple.elem1.5d7.tuple.elem, align 4, !dbg !382
// CHECK:STDOUT:   ret void, !dbg !383
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!369}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !29 = !{!7}
// CHECK:STDOUT: !30 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !35 = !{!7, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !368 = !DIFile(filename: "return_nested_constant_element.carbon", directory: "")
// CHECK:STDOUT: !369 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !368, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !370 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !368, line: 7, type: !30, spFlags: DISPFlagDefinition, unit: !369)
// CHECK:STDOUT: !373 = !DILocation(line: 8, column: 10, scope: !370)
// CHECK:STDOUT: !374 = !DILocation(line: 8, column: 3, scope: !370)
// CHECK:STDOUT: !375 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main.84588f41d61dafba", scope: null, file: !368, line: 3, type: !36, spFlags: DISPFlagDefinition, unit: !369, retainedNodes: !384)
// CHECK:STDOUT: !376 = !DILocalVariable(arg: 1, scope: !375, type: !6)
// CHECK:STDOUT: !381 = !DILocation(line: 4, column: 11, scope: !375)
// CHECK:STDOUT: !382 = !DILocation(line: 4, column: 10, scope: !375)
// CHECK:STDOUT: !383 = !DILocation(line: 4, column: 3, scope: !375)
// CHECK:STDOUT: !384 = !{!376}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'template_value_element.carbon'
// CHECK:STDOUT: source_filename = "template_value_element.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(ptr sret({ i32, i32 }) %return) #0 !dbg !387 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CM.Main.e384f2fa3c05f2f5(ptr %return, i32 4), !dbg !390
// CHECK:STDOUT:   ret void, !dbg !391
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CM.Main.e384f2fa3c05f2f5(ptr sret({ i32, i32 }) %return, i32 %x) #0 !dbg !392 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !398
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !398
// CHECK:STDOUT:   store i32 %x, ptr %tuple.elem1.tuple.elem, align 4, !dbg !398
// CHECK:STDOUT:   store i32 3, ptr %tuple.elem0.tuple.elem, align 4, !dbg !398
// CHECK:STDOUT:   ret void, !dbg !399
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!386}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !29 = !{!7}
// CHECK:STDOUT: !30 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !35 = !{!7, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !385 = !DIFile(filename: "template_value_element.carbon", directory: "")
// CHECK:STDOUT: !386 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !385, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !387 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !385, line: 7, type: !30, spFlags: DISPFlagDefinition, unit: !386)
// CHECK:STDOUT: !390 = !DILocation(line: 8, column: 10, scope: !387)
// CHECK:STDOUT: !391 = !DILocation(line: 8, column: 3, scope: !387)
// CHECK:STDOUT: !392 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main.e384f2fa3c05f2f5", scope: null, file: !385, line: 3, type: !36, spFlags: DISPFlagDefinition, unit: !386, retainedNodes: !400)
// CHECK:STDOUT: !393 = !DILocalVariable(arg: 1, scope: !392, type: !6)
// CHECK:STDOUT: !398 = !DILocation(line: 4, column: 10, scope: !392)
// CHECK:STDOUT: !399 = !DILocation(line: 4, column: 3, scope: !392)
// CHECK:STDOUT: !400 = !{!393}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'return_class_constant_field.carbon'
// CHECK:STDOUT: source_filename = "return_class_constant_field.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(ptr sret({ i32, i32 }) %return) #0 !dbg !403 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CM.Main.84588f41d61dafba(ptr %return, i32 4), !dbg !406
// CHECK:STDOUT:   ret void, !dbg !407
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CM.Main.84588f41d61dafba(ptr sret({ i32, i32 }) %return, i32 %x) #0 !dbg !408 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.dc0.a = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !414
// CHECK:STDOUT:   store i32 %x, ptr %.dc0.a, align 4, !dbg !414
// CHECK:STDOUT:   %.f76.b = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !414
// CHECK:STDOUT:   store i32 1, ptr %.f76.b, align 4, !dbg !414
// CHECK:STDOUT:   ret void, !dbg !415
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!402}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !29 = !{!7}
// CHECK:STDOUT: !30 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !35 = !{!7, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !401 = !DIFile(filename: "return_class_constant_field.carbon", directory: "")
// CHECK:STDOUT: !402 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !401, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !403 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !401, line: 12, type: !30, spFlags: DISPFlagDefinition, unit: !402)
// CHECK:STDOUT: !406 = !DILocation(line: 13, column: 10, scope: !403)
// CHECK:STDOUT: !407 = !DILocation(line: 13, column: 3, scope: !403)
// CHECK:STDOUT: !408 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main.84588f41d61dafba", scope: null, file: !401, line: 8, type: !36, spFlags: DISPFlagDefinition, unit: !402, retainedNodes: !416)
// CHECK:STDOUT: !409 = !DILocalVariable(arg: 1, scope: !408, type: !6)
// CHECK:STDOUT: !414 = !DILocation(line: 9, column: 10, scope: !408)
// CHECK:STDOUT: !415 = !DILocation(line: 9, column: 3, scope: !408)
// CHECK:STDOUT: !416 = !{!409}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'var_class_constant_field.carbon'
// CHECK:STDOUT: source_filename = "var_class_constant_field.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !419 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %M.call = call i32 @_CM.Main.84588f41d61dafba(i32 4), !dbg !422
// CHECK:STDOUT:   ret i32 %M.call, !dbg !423
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !424 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !426
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b4c762864cd9a02b:core.Destroy.Core"(ptr %self) #0 !dbg !428 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.b = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !430
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.1.b), !dbg !430
// CHECK:STDOUT:   %.loc9_3.2.a = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !430
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.2.a), !dbg !430
// CHECK:STDOUT:   ret void, !dbg !430
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b4c762864cd9a02b:core.Destroy.Core"(ptr %self) #0 !dbg !432 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b4c762864cd9a02b:core.Destroy.Core"(ptr %self), !dbg !434
// CHECK:STDOUT:   ret void, !dbg !434
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b38dfa1b7a987e33:core.Destroy.Core"(ptr %self) #0 !dbg !436 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.b = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !438
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.1.b), !dbg !438
// CHECK:STDOUT:   %.loc9_3.2.a = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !438
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.2.a), !dbg !438
// CHECK:STDOUT:   ret void, !dbg !438
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b38dfa1b7a987e33:core.Destroy.Core"(ptr %self) #0 !dbg !440 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b38dfa1b7a987e33:core.Destroy.Core"(ptr %self), !dbg !442
// CHECK:STDOUT:   ret void, !dbg !442
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CM.Main.84588f41d61dafba(i32 %x) #0 !dbg !444 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %p.var = alloca { i32, i32 }, align 4, !dbg !449
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %p.var), !dbg !449
// CHECK:STDOUT:   %.8e4.a = getelementptr inbounds nuw { i32, i32 }, ptr %p.var, i32 0, i32 0, !dbg !451
// CHECK:STDOUT:   store i32 %x, ptr %.8e4.a, align 4, !dbg !451
// CHECK:STDOUT:   %.122.b = getelementptr inbounds nuw { i32, i32 }, ptr %p.var, i32 0, i32 1, !dbg !451
// CHECK:STDOUT:   store i32 2, ptr %.122.b, align 4, !dbg !451
// CHECK:STDOUT:   %.ebc.b = getelementptr inbounds nuw { i32, i32 }, ptr %p.var, i32 0, i32 1, !dbg !453
// CHECK:STDOUT:   %.71a = load i32, ptr %.ebc.b, align 4, !dbg !453
// CHECK:STDOUT:   call void @"_CSelfDestruct.b38dfa1b7a987e33:core.Destroy.Core"(ptr %p.var), !dbg !449
// CHECK:STDOUT:   ret i32 %.71a, !dbg !454
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!418}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !97 = !{!6}
// CHECK:STDOUT: !98 = !DISubroutineType(types: !97)
// CHECK:STDOUT: !103 = !{!6, !6}
// CHECK:STDOUT: !104 = !DISubroutineType(types: !103)
// CHECK:STDOUT: !173 = !{null, !7}
// CHECK:STDOUT: !174 = !DISubroutineType(types: !173)
// CHECK:STDOUT: !298 = !{null, !6}
// CHECK:STDOUT: !299 = !DISubroutineType(types: !298)
// CHECK:STDOUT: !417 = !DIFile(filename: "var_class_constant_field.carbon", directory: "")
// CHECK:STDOUT: !418 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !417, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !419 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !417, line: 13, type: !98, spFlags: DISPFlagDefinition, unit: !418)
// CHECK:STDOUT: !422 = !DILocation(line: 14, column: 10, scope: !419)
// CHECK:STDOUT: !423 = !DILocation(line: 14, column: 3, scope: !419)
// CHECK:STDOUT: !424 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !417, line: 9, type: !299, spFlags: DISPFlagDefinition, unit: !418, retainedNodes: !427)
// CHECK:STDOUT: !425 = !DILocalVariable(arg: 1, scope: !424, type: !6)
// CHECK:STDOUT: !426 = !DILocation(line: 9, column: 3, scope: !424)
// CHECK:STDOUT: !427 = !{!425}
// CHECK:STDOUT: !428 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b4c762864cd9a02b:core.Destroy.Core", scope: null, file: !417, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !418, retainedNodes: !431)
// CHECK:STDOUT: !429 = !DILocalVariable(arg: 1, scope: !428, type: !7)
// CHECK:STDOUT: !430 = !DILocation(line: 9, column: 3, scope: !428)
// CHECK:STDOUT: !431 = !{!429}
// CHECK:STDOUT: !432 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b4c762864cd9a02b:core.Destroy.Core", scope: null, file: !417, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !418, retainedNodes: !435)
// CHECK:STDOUT: !433 = !DILocalVariable(arg: 1, scope: !432, type: !7)
// CHECK:STDOUT: !434 = !DILocation(line: 9, column: 3, scope: !432)
// CHECK:STDOUT: !435 = !{!433}
// CHECK:STDOUT: !436 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b38dfa1b7a987e33:core.Destroy.Core", scope: null, file: !417, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !418, retainedNodes: !439)
// CHECK:STDOUT: !437 = !DILocalVariable(arg: 1, scope: !436, type: !7)
// CHECK:STDOUT: !438 = !DILocation(line: 9, column: 3, scope: !436)
// CHECK:STDOUT: !439 = !{!437}
// CHECK:STDOUT: !440 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b38dfa1b7a987e33:core.Destroy.Core", scope: null, file: !417, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !418, retainedNodes: !443)
// CHECK:STDOUT: !441 = !DILocalVariable(arg: 1, scope: !440, type: !7)
// CHECK:STDOUT: !442 = !DILocation(line: 9, column: 3, scope: !440)
// CHECK:STDOUT: !443 = !{!441}
// CHECK:STDOUT: !444 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main.84588f41d61dafba", scope: null, file: !417, line: 8, type: !104, spFlags: DISPFlagDefinition, unit: !418, retainedNodes: !455)
// CHECK:STDOUT: !445 = !DILocalVariable(arg: 1, scope: !444, type: !6)
// CHECK:STDOUT: !449 = !DILocation(line: 9, column: 3, scope: !444)
// CHECK:STDOUT: !451 = !DILocation(line: 9, column: 17, scope: !444)
// CHECK:STDOUT: !453 = !DILocation(line: 10, column: 10, scope: !444)
// CHECK:STDOUT: !454 = !DILocation(line: 10, column: 3, scope: !444)
// CHECK:STDOUT: !455 = !{!445}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'return_tuple_of_associated_type.carbon'
// CHECK:STDOUT: source_filename = "return_tuple_of_associated_type.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CGet.Ints.Main:Container.Main"(ptr %self) #0 !dbg !458 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc11_38.1.n = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !463
// CHECK:STDOUT:   %.loc11_38.2 = load i32, ptr %.loc11_38.1.n, align 4, !dbg !463
// CHECK:STDOUT:   ret i32 %.loc11_38.2, !dbg !464
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(ptr sret({ i32, i32 }) %return, ptr %n) #0 !dbg !466 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CF.Main.bd99b4c472800820(ptr %return, ptr %n), !dbg !472
// CHECK:STDOUT:   ret void, !dbg !473
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CF.Main.bd99b4c472800820(ptr sret({ i32, i32 }) %return, ptr %x) #0 !dbg !475 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Ints.as.Container.impl.Get.call = call i32 @"_CGet.Ints.Main:Container.Main"(ptr %x), !dbg !480
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !481
// CHECK:STDOUT:   store i32 %Ints.as.Container.impl.Get.call, ptr %tuple.elem0.tuple.elem, align 4, !dbg !481
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !481
// CHECK:STDOUT:   store i32 5, ptr %tuple.elem1.tuple.elem, align 4, !dbg !481
// CHECK:STDOUT:   ret void, !dbg !482
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!457}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !175 = !{!6, !7}
// CHECK:STDOUT: !176 = !DISubroutineType(types: !175)
// CHECK:STDOUT: !456 = !DIFile(filename: "return_tuple_of_associated_type.carbon", directory: "")
// CHECK:STDOUT: !457 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !456, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !458 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Ints.Main:Container.Main", scope: null, file: !456, line: 11, type: !176, spFlags: DISPFlagDefinition, unit: !457, retainedNodes: !465)
// CHECK:STDOUT: !459 = !DILocalVariable(arg: 1, scope: !458, type: !7)
// CHECK:STDOUT: !463 = !DILocation(line: 11, column: 34, scope: !458)
// CHECK:STDOUT: !464 = !DILocation(line: 11, column: 27, scope: !458)
// CHECK:STDOUT: !465 = !{!459}
// CHECK:STDOUT: !466 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !456, line: 19, type: !9, spFlags: DISPFlagDefinition, unit: !457, retainedNodes: !474)
// CHECK:STDOUT: !467 = !DILocalVariable(arg: 1, scope: !466, type: !7)
// CHECK:STDOUT: !472 = !DILocation(line: 20, column: 10, scope: !466)
// CHECK:STDOUT: !473 = !DILocation(line: 20, column: 3, scope: !466)
// CHECK:STDOUT: !474 = !{!467}
// CHECK:STDOUT: !475 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.bd99b4c472800820", scope: null, file: !456, line: 15, type: !9, spFlags: DISPFlagDefinition, unit: !457, retainedNodes: !483)
// CHECK:STDOUT: !476 = !DILocalVariable(arg: 1, scope: !475, type: !7)
// CHECK:STDOUT: !480 = !DILocation(line: 16, column: 11, scope: !475)
// CHECK:STDOUT: !481 = !DILocation(line: 16, column: 10, scope: !475)
// CHECK:STDOUT: !482 = !DILocation(line: 16, column: 3, scope: !475)
// CHECK:STDOUT: !483 = !{!476}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'var_tuple_of_associated_type.carbon'
// CHECK:STDOUT: source_filename = "var_tuple_of_associated_type.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @tuple.8a1.loc12_3.1 = internal constant { i32, i32 } { i32 4, i32 5 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main(ptr %n) #0 !dbg !486 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call i32 @_CG.Main.bd99b4c472800820(ptr %n), !dbg !492
// CHECK:STDOUT:   ret i32 %G.call, !dbg !493
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !495 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !497
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !499 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !501
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !501
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !501
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !501
// CHECK:STDOUT:   ret void, !dbg !501
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !503 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self), !dbg !505
// CHECK:STDOUT:   ret void, !dbg !505
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CG.Main.bd99b4c472800820(ptr %x) #0 !dbg !507 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %t.var = alloca { i32, i32 }, align 4, !dbg !512
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %t.var), !dbg !512
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %t.var, i32 0, i32 0, !dbg !513
// CHECK:STDOUT:   %tuple.elem1.loc12.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %t.var, i32 0, i32 1, !dbg !513
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %t.var, ptr align 4 @tuple.8a1.loc12_3.1, i64 8, i1 false), !dbg !512
// CHECK:STDOUT:   %tuple.elem1.loc13.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %t.var, i32 0, i32 1, !dbg !515
// CHECK:STDOUT:   %.loc13 = load i32, ptr %tuple.elem1.loc13.tuple.elem, align 4, !dbg !515
// CHECK:STDOUT:   call void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %t.var), !dbg !512
// CHECK:STDOUT:   ret i32 %.loc13, !dbg !516
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!485}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !173 = !{null, !7}
// CHECK:STDOUT: !174 = !DISubroutineType(types: !173)
// CHECK:STDOUT: !175 = !{!6, !7}
// CHECK:STDOUT: !176 = !DISubroutineType(types: !175)
// CHECK:STDOUT: !298 = !{null, !6}
// CHECK:STDOUT: !299 = !DISubroutineType(types: !298)
// CHECK:STDOUT: !484 = !DIFile(filename: "var_tuple_of_associated_type.carbon", directory: "")
// CHECK:STDOUT: !485 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !484, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !486 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !484, line: 16, type: !176, spFlags: DISPFlagDefinition, unit: !485, retainedNodes: !494)
// CHECK:STDOUT: !487 = !DILocalVariable(arg: 1, scope: !486, type: !7)
// CHECK:STDOUT: !492 = !DILocation(line: 17, column: 10, scope: !486)
// CHECK:STDOUT: !493 = !DILocation(line: 17, column: 3, scope: !486)
// CHECK:STDOUT: !494 = !{!487}
// CHECK:STDOUT: !495 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !484, line: 12, type: !299, spFlags: DISPFlagDefinition, unit: !485, retainedNodes: !498)
// CHECK:STDOUT: !496 = !DILocalVariable(arg: 1, scope: !495, type: !6)
// CHECK:STDOUT: !497 = !DILocation(line: 12, column: 3, scope: !495)
// CHECK:STDOUT: !498 = !{!496}
// CHECK:STDOUT: !499 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !484, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !485, retainedNodes: !502)
// CHECK:STDOUT: !500 = !DILocalVariable(arg: 1, scope: !499, type: !7)
// CHECK:STDOUT: !501 = !DILocation(line: 12, column: 3, scope: !499)
// CHECK:STDOUT: !502 = !{!500}
// CHECK:STDOUT: !503 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !484, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !485, retainedNodes: !506)
// CHECK:STDOUT: !504 = !DILocalVariable(arg: 1, scope: !503, type: !7)
// CHECK:STDOUT: !505 = !DILocation(line: 12, column: 3, scope: !503)
// CHECK:STDOUT: !506 = !{!504}
// CHECK:STDOUT: !507 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.bd99b4c472800820", scope: null, file: !484, line: 11, type: !176, spFlags: DISPFlagDefinition, unit: !485, retainedNodes: !517)
// CHECK:STDOUT: !508 = !DILocalVariable(arg: 1, scope: !507, type: !7)
// CHECK:STDOUT: !512 = !DILocation(line: 12, column: 3, scope: !507)
// CHECK:STDOUT: !513 = !DILocation(line: 12, column: 26, scope: !507)
// CHECK:STDOUT: !515 = !DILocation(line: 13, column: 10, scope: !507)
// CHECK:STDOUT: !516 = !DILocation(line: 13, column: 3, scope: !507)
// CHECK:STDOUT: !517 = !{!508}
// CHECK:STDOUT:

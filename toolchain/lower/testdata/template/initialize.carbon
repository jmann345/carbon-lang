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

// --- var_class_with_dependent_array_bound.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn M(template N: i32, x: i32) -> i32 {
  var c: Arr(N) = {.a = (x, 2, 3), .n = N};
  return c.n;
}

fn Use() -> i32 {
  return M(3, 1);
}

// --- return_class_with_dependent_array_bound.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn M(template N: i32, x: i32) -> Arr(N) {
  return {.a = (4, x, 6), .n = N};
}

fn Use() -> Arr(3) {
  return M(3, 5);
}

// --- var_struct_of_class_with_dependent_array_bound.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn M(template N: i32, x: i32) -> i32 {
  var s: {.c: Arr(N), .d: i32} = {.c = {.a = (x, 2, 3), .n = N}, .d = x};
  return s.d;
}

fn Use() -> i32 {
  return M(3, 1);
}

// --- var_tuple_of_class_with_dependent_array_bound.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn M(template N: i32, x: i32) -> i32 {
  var t: (Arr(N), i32) = ({.a = (1, 2, x), .n = N}, x);
  return t.1;
}

fn Use() -> i32 {
  return M(3, 1);
}

// --- var_array_of_class_with_dependent_array_bound.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn M(template N: i32, x: i32) -> i32 {
  var v: array(Arr(N), 2) = ({.a = (x, 2, 3), .n = N}, {.a = (4, 5, 6), .n = x});
  return v[1].n;
}

fn Use() -> i32 {
  return M(3, 1);
}

// --- let_class_value_with_template_value_field.carbon
library "[[@TEST_NAME]]";

class P(template N: i32) {
  var a: i32;
  var b: i32;
}

fn M(template N: i32, x: i32) -> i32 {
  let p: P(N) = {.a = x, .b = N};
  return p.a;
}

fn Use() -> i32 {
  return M(3, 1);
}

// --- var_class_template_associated_field.carbon
library "[[@TEST_NAME]]";

interface HasItem {
  let Item: type;
}

class Holder {
  impl as HasItem where .Item = i32 {}
}

class Box(template T: HasItem) {
  var item: T.Item;
  var n: i32;
}

fn G[template T: HasItem](unused x: T) -> i32 {
  var b: Box(T) = {.item = 4, .n = 5};
  return b.n;
}

fn Use(h: Holder) -> i32 {
  return G(h);
}

// --- return_class_template_associated_field.carbon
library "[[@TEST_NAME]]";

interface HasItem {
  let Item: type;
}

class Holder {
  impl as HasItem where .Item = i32 {}
}

class Box(template T: HasItem) {
  var item: T.Item;
  var n: i32;
}

fn G[template T: HasItem](unused x: T, y: i32) -> Box(T) {
  return {.item = y, .n = 5};
}

fn Use(h: Holder) -> Box(Holder) {
  return G(h, 4);
}

// --- class_template_factory_associated_field.carbon
library "[[@TEST_NAME]]";

interface HasItem {
  let Item: type;
}

class Holder {
  impl as HasItem where .Item = i32 {}
}

class Box(template T: HasItem) {
  var item: T.Item;
  var n: i32;

  fn Make(item: T.Item) -> Box(T) {
    return {.item = item, .n = 5};
  }
}

fn Use() -> Box(Holder) {
  return Box(Holder).Make(4);
}

// --- class_template_associated_pointer_field.carbon
library "[[@TEST_NAME]]";

interface HasItem {
  let Item: type;
}

class Holder {
  impl as HasItem where .Item = i32 {}
}

class PtrBox(template T: HasItem) {
  var p: T.Item*;
  var n: i32;
}

fn G[template T: HasItem](unused x: T, p: T.Item*) -> i32 {
  var b: PtrBox(T) = {.p = p, .n = 5};
  return b.n;
}

fn Use(h: Holder, p: i32*) -> i32 {
  return G(h, p);
}

// --- nested_class_template_computed_argument.carbon
library "[[@TEST_NAME]]";

class Inner(template N: i32) {
  var a: i32;
}

class Outer(template M: i32) {
  var c: Inner(M + 1);
}

fn G(template M: i32) -> i32 {
  var o: Outer(M) = {.c = {.a = 4}};
  return o.c.a;
}

fn Use() -> i32 {
  return G(2);
}

// --- assign_nested_class_template_computed_argument.carbon
library "[[@TEST_NAME]]";

class Inner(template N: i32) {
  var a: i32;
}

class Outer(template M: i32) {
  var c: Inner(M + 1);
}

fn G(template M: i32, x: i32) -> i32 {
  var o: Outer(M) = {.c = {.a = 4}};
  o = {.c = {.a = x}};
  return o.c.a;
}

fn Use() -> i32 {
  return G(2, 6);
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
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'var_class_with_dependent_array_bound.carbon'
// CHECK:STDOUT: source_filename = "var_class_with_dependent_array_bound.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !520 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %M.call = call i32 @_CM.Main.e384f2fa3c05f2f5(i32 1), !dbg !523
// CHECK:STDOUT:   ret i32 %M.call, !dbg !524
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !525 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !527
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.dc7dedd104b837b2:core.Destroy.Core"(ptr %self) #0 !dbg !529 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.array.index = getelementptr inbounds [3 x i32], ptr %self, i32 0, i64 2, !dbg !531
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.1.array.index), !dbg !531
// CHECK:STDOUT:   %.loc9_3.2.array.index = getelementptr inbounds [3 x i32], ptr %self, i32 0, i64 1, !dbg !531
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.2.array.index), !dbg !531
// CHECK:STDOUT:   %.loc9_3.3.array.index = getelementptr inbounds [3 x i32], ptr %self, i32 0, i64 0, !dbg !531
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.3.array.index), !dbg !531
// CHECK:STDOUT:   ret void, !dbg !531
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core"(ptr %self) #0 !dbg !533 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.dc7dedd104b837b2:core.Destroy.Core"(ptr %self), !dbg !535
// CHECK:STDOUT:   ret void, !dbg !535
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.d78496a987f075bd:core.Destroy.Core"(ptr %self) #0 !dbg !537 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.n = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %self, i32 0, i32 1, !dbg !539
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.1.n), !dbg !539
// CHECK:STDOUT:   %.loc9_3.2.a = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %self, i32 0, i32 0, !dbg !539
// CHECK:STDOUT:   call void @"_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core"(ptr %.loc9_3.2.a), !dbg !539
// CHECK:STDOUT:   ret void, !dbg !539
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d78496a987f075bd:core.Destroy.Core"(ptr %self) #0 !dbg !541 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.d78496a987f075bd:core.Destroy.Core"(ptr %self), !dbg !543
// CHECK:STDOUT:   ret void, !dbg !543
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.5e11dbc35420cea5:core.Destroy.Core"(ptr %self) #0 !dbg !545 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.n = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %self, i32 0, i32 1, !dbg !547
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.1.n), !dbg !547
// CHECK:STDOUT:   %.loc9_3.2.a = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %self, i32 0, i32 0, !dbg !547
// CHECK:STDOUT:   call void @"_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core"(ptr %.loc9_3.2.a), !dbg !547
// CHECK:STDOUT:   ret void, !dbg !547
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5e11dbc35420cea5:core.Destroy.Core"(ptr %self) #0 !dbg !549 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.5e11dbc35420cea5:core.Destroy.Core"(ptr %self), !dbg !551
// CHECK:STDOUT:   ret void, !dbg !551
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CM.Main.e384f2fa3c05f2f5(i32 %x) #0 !dbg !553 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %c.var = alloca { [3 x i32], i32 }, align 4, !dbg !558
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %c.var), !dbg !558
// CHECK:STDOUT:   %.f2a.a = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %c.var, i32 0, i32 0, !dbg !561
// CHECK:STDOUT:   %.50e.array.index = getelementptr inbounds [3 x i32], ptr %.f2a.a, i32 0, i64 0, !dbg !560
// CHECK:STDOUT:   store i32 %x, ptr %.50e.array.index, align 4, !dbg !560
// CHECK:STDOUT:   %.41b.array.index = getelementptr inbounds [3 x i32], ptr %.f2a.a, i32 0, i64 1, !dbg !560
// CHECK:STDOUT:   %.76d.array.index = getelementptr inbounds [3 x i32], ptr %.f2a.a, i32 0, i64 2, !dbg !560
// CHECK:STDOUT:   store i32 2, ptr %.41b.array.index, align 4, !dbg !560
// CHECK:STDOUT:   store i32 3, ptr %.76d.array.index, align 4, !dbg !560
// CHECK:STDOUT:   %.1d2.n = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %c.var, i32 0, i32 1, !dbg !561
// CHECK:STDOUT:   store i32 3, ptr %.1d2.n, align 4, !dbg !561
// CHECK:STDOUT:   %.4ba.n = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %c.var, i32 0, i32 1, !dbg !563
// CHECK:STDOUT:   %.629 = load i32, ptr %.4ba.n, align 4, !dbg !563
// CHECK:STDOUT:   call void @"_CSelfDestruct.5e11dbc35420cea5:core.Destroy.Core"(ptr %c.var), !dbg !558
// CHECK:STDOUT:   ret i32 %.629, !dbg !564
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!519}
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
// CHECK:STDOUT: !518 = !DIFile(filename: "var_class_with_dependent_array_bound.carbon", directory: "")
// CHECK:STDOUT: !519 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !518, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !520 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !518, line: 13, type: !98, spFlags: DISPFlagDefinition, unit: !519)
// CHECK:STDOUT: !523 = !DILocation(line: 14, column: 10, scope: !520)
// CHECK:STDOUT: !524 = !DILocation(line: 14, column: 3, scope: !520)
// CHECK:STDOUT: !525 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !518, line: 9, type: !299, spFlags: DISPFlagDefinition, unit: !519, retainedNodes: !528)
// CHECK:STDOUT: !526 = !DILocalVariable(arg: 1, scope: !525, type: !6)
// CHECK:STDOUT: !527 = !DILocation(line: 9, column: 3, scope: !525)
// CHECK:STDOUT: !528 = !{!526}
// CHECK:STDOUT: !529 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.dc7dedd104b837b2:core.Destroy.Core", scope: null, file: !518, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !519, retainedNodes: !532)
// CHECK:STDOUT: !530 = !DILocalVariable(arg: 1, scope: !529, type: !7)
// CHECK:STDOUT: !531 = !DILocation(line: 9, column: 3, scope: !529)
// CHECK:STDOUT: !532 = !{!530}
// CHECK:STDOUT: !533 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core", scope: null, file: !518, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !519, retainedNodes: !536)
// CHECK:STDOUT: !534 = !DILocalVariable(arg: 1, scope: !533, type: !7)
// CHECK:STDOUT: !535 = !DILocation(line: 9, column: 3, scope: !533)
// CHECK:STDOUT: !536 = !{!534}
// CHECK:STDOUT: !537 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.d78496a987f075bd:core.Destroy.Core", scope: null, file: !518, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !519, retainedNodes: !540)
// CHECK:STDOUT: !538 = !DILocalVariable(arg: 1, scope: !537, type: !7)
// CHECK:STDOUT: !539 = !DILocation(line: 9, column: 3, scope: !537)
// CHECK:STDOUT: !540 = !{!538}
// CHECK:STDOUT: !541 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d78496a987f075bd:core.Destroy.Core", scope: null, file: !518, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !519, retainedNodes: !544)
// CHECK:STDOUT: !542 = !DILocalVariable(arg: 1, scope: !541, type: !7)
// CHECK:STDOUT: !543 = !DILocation(line: 9, column: 3, scope: !541)
// CHECK:STDOUT: !544 = !{!542}
// CHECK:STDOUT: !545 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.5e11dbc35420cea5:core.Destroy.Core", scope: null, file: !518, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !519, retainedNodes: !548)
// CHECK:STDOUT: !546 = !DILocalVariable(arg: 1, scope: !545, type: !7)
// CHECK:STDOUT: !547 = !DILocation(line: 9, column: 3, scope: !545)
// CHECK:STDOUT: !548 = !{!546}
// CHECK:STDOUT: !549 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5e11dbc35420cea5:core.Destroy.Core", scope: null, file: !518, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !519, retainedNodes: !552)
// CHECK:STDOUT: !550 = !DILocalVariable(arg: 1, scope: !549, type: !7)
// CHECK:STDOUT: !551 = !DILocation(line: 9, column: 3, scope: !549)
// CHECK:STDOUT: !552 = !{!550}
// CHECK:STDOUT: !553 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main.e384f2fa3c05f2f5", scope: null, file: !518, line: 8, type: !104, spFlags: DISPFlagDefinition, unit: !519, retainedNodes: !565)
// CHECK:STDOUT: !554 = !DILocalVariable(arg: 1, scope: !553, type: !6)
// CHECK:STDOUT: !558 = !DILocation(line: 9, column: 3, scope: !553)
// CHECK:STDOUT: !560 = !DILocation(line: 9, column: 25, scope: !553)
// CHECK:STDOUT: !561 = !DILocation(line: 9, column: 19, scope: !553)
// CHECK:STDOUT: !563 = !DILocation(line: 10, column: 10, scope: !553)
// CHECK:STDOUT: !564 = !DILocation(line: 10, column: 3, scope: !553)
// CHECK:STDOUT: !565 = !{!554}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'return_class_with_dependent_array_bound.carbon'
// CHECK:STDOUT: source_filename = "return_class_with_dependent_array_bound.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(ptr sret({ [3 x i32], i32 }) %return) #0 !dbg !568 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CM.Main.e384f2fa3c05f2f5(ptr %return, i32 5), !dbg !571
// CHECK:STDOUT:   ret void, !dbg !572
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CM.Main.e384f2fa3c05f2f5(ptr sret({ [3 x i32], i32 }) %return, i32 %x) #0 !dbg !573 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.12e.a = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %return, i32 0, i32 0, !dbg !580
// CHECK:STDOUT:   %.8a9.array.index = getelementptr inbounds [3 x i32], ptr %.12e.a, i32 0, i64 0, !dbg !579
// CHECK:STDOUT:   %.c66.array.index = getelementptr inbounds [3 x i32], ptr %.12e.a, i32 0, i64 1, !dbg !579
// CHECK:STDOUT:   store i32 %x, ptr %.c66.array.index, align 4, !dbg !579
// CHECK:STDOUT:   %.b42.array.index = getelementptr inbounds [3 x i32], ptr %.12e.a, i32 0, i64 2, !dbg !579
// CHECK:STDOUT:   store i32 4, ptr %.8a9.array.index, align 4, !dbg !579
// CHECK:STDOUT:   store i32 6, ptr %.b42.array.index, align 4, !dbg !579
// CHECK:STDOUT:   %.ff4.n = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %return, i32 0, i32 1, !dbg !580
// CHECK:STDOUT:   store i32 3, ptr %.ff4.n, align 4, !dbg !580
// CHECK:STDOUT:   ret void, !dbg !581
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!567}
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
// CHECK:STDOUT: !566 = !DIFile(filename: "return_class_with_dependent_array_bound.carbon", directory: "")
// CHECK:STDOUT: !567 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !566, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !568 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !566, line: 12, type: !30, spFlags: DISPFlagDefinition, unit: !567)
// CHECK:STDOUT: !571 = !DILocation(line: 13, column: 10, scope: !568)
// CHECK:STDOUT: !572 = !DILocation(line: 13, column: 3, scope: !568)
// CHECK:STDOUT: !573 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main.e384f2fa3c05f2f5", scope: null, file: !566, line: 8, type: !36, spFlags: DISPFlagDefinition, unit: !567, retainedNodes: !582)
// CHECK:STDOUT: !574 = !DILocalVariable(arg: 1, scope: !573, type: !6)
// CHECK:STDOUT: !579 = !DILocation(line: 9, column: 16, scope: !573)
// CHECK:STDOUT: !580 = !DILocation(line: 9, column: 10, scope: !573)
// CHECK:STDOUT: !581 = !DILocation(line: 9, column: 3, scope: !573)
// CHECK:STDOUT: !582 = !{!574}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'var_struct_of_class_with_dependent_array_bound.carbon'
// CHECK:STDOUT: source_filename = "var_struct_of_class_with_dependent_array_bound.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !585 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %M.call = call i32 @_CM.Main.e384f2fa3c05f2f5(i32 1), !dbg !588
// CHECK:STDOUT:   ret i32 %M.call, !dbg !589
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !590 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !592
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.dc7dedd104b837b2:core.Destroy.Core"(ptr %self) #0 !dbg !594 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.array.index = getelementptr inbounds [3 x i32], ptr %self, i32 0, i64 2, !dbg !596
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.1.array.index), !dbg !596
// CHECK:STDOUT:   %.loc9_3.2.array.index = getelementptr inbounds [3 x i32], ptr %self, i32 0, i64 1, !dbg !596
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.2.array.index), !dbg !596
// CHECK:STDOUT:   %.loc9_3.3.array.index = getelementptr inbounds [3 x i32], ptr %self, i32 0, i64 0, !dbg !596
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.3.array.index), !dbg !596
// CHECK:STDOUT:   ret void, !dbg !596
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core"(ptr %self) #0 !dbg !598 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.dc7dedd104b837b2:core.Destroy.Core"(ptr %self), !dbg !600
// CHECK:STDOUT:   ret void, !dbg !600
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.d78496a987f075bd:core.Destroy.Core"(ptr %self) #0 !dbg !602 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.n = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %self, i32 0, i32 1, !dbg !604
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.1.n), !dbg !604
// CHECK:STDOUT:   %.loc9_3.2.a = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %self, i32 0, i32 0, !dbg !604
// CHECK:STDOUT:   call void @"_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core"(ptr %.loc9_3.2.a), !dbg !604
// CHECK:STDOUT:   ret void, !dbg !604
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d78496a987f075bd:core.Destroy.Core"(ptr %self) #0 !dbg !606 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.d78496a987f075bd:core.Destroy.Core"(ptr %self), !dbg !608
// CHECK:STDOUT:   ret void, !dbg !608
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.5e11dbc35420cea5:core.Destroy.Core"(ptr %self) #0 !dbg !610 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.n = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %self, i32 0, i32 1, !dbg !612
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.1.n), !dbg !612
// CHECK:STDOUT:   %.loc9_3.2.a = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %self, i32 0, i32 0, !dbg !612
// CHECK:STDOUT:   call void @"_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core"(ptr %.loc9_3.2.a), !dbg !612
// CHECK:STDOUT:   ret void, !dbg !612
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5e11dbc35420cea5:core.Destroy.Core"(ptr %self) #0 !dbg !614 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.5e11dbc35420cea5:core.Destroy.Core"(ptr %self), !dbg !616
// CHECK:STDOUT:   ret void, !dbg !616
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.8042ddc02d19e591:core.Destroy.Core"(ptr %self) #0 !dbg !618 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.d = getelementptr inbounds nuw { { [3 x i32], i32 }, i32 }, ptr %self, i32 0, i32 1, !dbg !620
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.1.d), !dbg !620
// CHECK:STDOUT:   %.loc9_3.2.c = getelementptr inbounds nuw { { [3 x i32], i32 }, i32 }, ptr %self, i32 0, i32 0, !dbg !620
// CHECK:STDOUT:   call void @"_CSelfDestruct.5e11dbc35420cea5:core.Destroy.Core"(ptr %.loc9_3.2.c), !dbg !620
// CHECK:STDOUT:   ret void, !dbg !620
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.8042ddc02d19e591:core.Destroy.Core"(ptr %self) #0 !dbg !622 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.8042ddc02d19e591:core.Destroy.Core"(ptr %self), !dbg !624
// CHECK:STDOUT:   ret void, !dbg !624
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CM.Main.e384f2fa3c05f2f5(i32 %x) #0 !dbg !626 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %s.var = alloca { { [3 x i32], i32 }, i32 }, align 4, !dbg !631
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %s.var), !dbg !631
// CHECK:STDOUT:   %.9cc.c = getelementptr inbounds nuw { { [3 x i32], i32 }, i32 }, ptr %s.var, i32 0, i32 0, !dbg !636
// CHECK:STDOUT:   %.174.a = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %.9cc.c, i32 0, i32 0, !dbg !634
// CHECK:STDOUT:   %.644.array.index = getelementptr inbounds [3 x i32], ptr %.174.a, i32 0, i64 0, !dbg !633
// CHECK:STDOUT:   store i32 %x, ptr %.644.array.index, align 4, !dbg !633
// CHECK:STDOUT:   %.173.array.index = getelementptr inbounds [3 x i32], ptr %.174.a, i32 0, i64 1, !dbg !633
// CHECK:STDOUT:   %.a8a.array.index = getelementptr inbounds [3 x i32], ptr %.174.a, i32 0, i64 2, !dbg !633
// CHECK:STDOUT:   store i32 2, ptr %.173.array.index, align 4, !dbg !633
// CHECK:STDOUT:   store i32 3, ptr %.a8a.array.index, align 4, !dbg !633
// CHECK:STDOUT:   %.c99.n = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %.9cc.c, i32 0, i32 1, !dbg !634
// CHECK:STDOUT:   store i32 3, ptr %.c99.n, align 4, !dbg !634
// CHECK:STDOUT:   %.loc9_72.3.d = getelementptr inbounds nuw { { [3 x i32], i32 }, i32 }, ptr %s.var, i32 0, i32 1, !dbg !636
// CHECK:STDOUT:   store i32 %x, ptr %.loc9_72.3.d, align 4, !dbg !636
// CHECK:STDOUT:   %.a29.d = getelementptr inbounds nuw { { [3 x i32], i32 }, i32 }, ptr %s.var, i32 0, i32 1, !dbg !638
// CHECK:STDOUT:   %.53b = load i32, ptr %.a29.d, align 4, !dbg !638
// CHECK:STDOUT:   call void @"_CSelfDestruct.8042ddc02d19e591:core.Destroy.Core"(ptr %s.var), !dbg !631
// CHECK:STDOUT:   ret i32 %.53b, !dbg !639
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!584}
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
// CHECK:STDOUT: !583 = !DIFile(filename: "var_struct_of_class_with_dependent_array_bound.carbon", directory: "")
// CHECK:STDOUT: !584 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !583, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !585 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !583, line: 13, type: !98, spFlags: DISPFlagDefinition, unit: !584)
// CHECK:STDOUT: !588 = !DILocation(line: 14, column: 10, scope: !585)
// CHECK:STDOUT: !589 = !DILocation(line: 14, column: 3, scope: !585)
// CHECK:STDOUT: !590 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !583, line: 9, type: !299, spFlags: DISPFlagDefinition, unit: !584, retainedNodes: !593)
// CHECK:STDOUT: !591 = !DILocalVariable(arg: 1, scope: !590, type: !6)
// CHECK:STDOUT: !592 = !DILocation(line: 9, column: 3, scope: !590)
// CHECK:STDOUT: !593 = !{!591}
// CHECK:STDOUT: !594 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.dc7dedd104b837b2:core.Destroy.Core", scope: null, file: !583, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !584, retainedNodes: !597)
// CHECK:STDOUT: !595 = !DILocalVariable(arg: 1, scope: !594, type: !7)
// CHECK:STDOUT: !596 = !DILocation(line: 9, column: 3, scope: !594)
// CHECK:STDOUT: !597 = !{!595}
// CHECK:STDOUT: !598 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core", scope: null, file: !583, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !584, retainedNodes: !601)
// CHECK:STDOUT: !599 = !DILocalVariable(arg: 1, scope: !598, type: !7)
// CHECK:STDOUT: !600 = !DILocation(line: 9, column: 3, scope: !598)
// CHECK:STDOUT: !601 = !{!599}
// CHECK:STDOUT: !602 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.d78496a987f075bd:core.Destroy.Core", scope: null, file: !583, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !584, retainedNodes: !605)
// CHECK:STDOUT: !603 = !DILocalVariable(arg: 1, scope: !602, type: !7)
// CHECK:STDOUT: !604 = !DILocation(line: 9, column: 3, scope: !602)
// CHECK:STDOUT: !605 = !{!603}
// CHECK:STDOUT: !606 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d78496a987f075bd:core.Destroy.Core", scope: null, file: !583, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !584, retainedNodes: !609)
// CHECK:STDOUT: !607 = !DILocalVariable(arg: 1, scope: !606, type: !7)
// CHECK:STDOUT: !608 = !DILocation(line: 9, column: 3, scope: !606)
// CHECK:STDOUT: !609 = !{!607}
// CHECK:STDOUT: !610 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.5e11dbc35420cea5:core.Destroy.Core", scope: null, file: !583, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !584, retainedNodes: !613)
// CHECK:STDOUT: !611 = !DILocalVariable(arg: 1, scope: !610, type: !7)
// CHECK:STDOUT: !612 = !DILocation(line: 9, column: 3, scope: !610)
// CHECK:STDOUT: !613 = !{!611}
// CHECK:STDOUT: !614 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5e11dbc35420cea5:core.Destroy.Core", scope: null, file: !583, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !584, retainedNodes: !617)
// CHECK:STDOUT: !615 = !DILocalVariable(arg: 1, scope: !614, type: !7)
// CHECK:STDOUT: !616 = !DILocation(line: 9, column: 3, scope: !614)
// CHECK:STDOUT: !617 = !{!615}
// CHECK:STDOUT: !618 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.8042ddc02d19e591:core.Destroy.Core", scope: null, file: !583, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !584, retainedNodes: !621)
// CHECK:STDOUT: !619 = !DILocalVariable(arg: 1, scope: !618, type: !7)
// CHECK:STDOUT: !620 = !DILocation(line: 9, column: 3, scope: !618)
// CHECK:STDOUT: !621 = !{!619}
// CHECK:STDOUT: !622 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.8042ddc02d19e591:core.Destroy.Core", scope: null, file: !583, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !584, retainedNodes: !625)
// CHECK:STDOUT: !623 = !DILocalVariable(arg: 1, scope: !622, type: !7)
// CHECK:STDOUT: !624 = !DILocation(line: 9, column: 3, scope: !622)
// CHECK:STDOUT: !625 = !{!623}
// CHECK:STDOUT: !626 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main.e384f2fa3c05f2f5", scope: null, file: !583, line: 8, type: !104, spFlags: DISPFlagDefinition, unit: !584, retainedNodes: !640)
// CHECK:STDOUT: !627 = !DILocalVariable(arg: 1, scope: !626, type: !6)
// CHECK:STDOUT: !631 = !DILocation(line: 9, column: 3, scope: !626)
// CHECK:STDOUT: !633 = !DILocation(line: 9, column: 46, scope: !626)
// CHECK:STDOUT: !634 = !DILocation(line: 9, column: 40, scope: !626)
// CHECK:STDOUT: !636 = !DILocation(line: 9, column: 34, scope: !626)
// CHECK:STDOUT: !638 = !DILocation(line: 10, column: 10, scope: !626)
// CHECK:STDOUT: !639 = !DILocation(line: 10, column: 3, scope: !626)
// CHECK:STDOUT: !640 = !{!627}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'var_tuple_of_class_with_dependent_array_bound.carbon'
// CHECK:STDOUT: source_filename = "var_tuple_of_class_with_dependent_array_bound.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !643 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %M.call = call i32 @_CM.Main.e384f2fa3c05f2f5(i32 1), !dbg !646
// CHECK:STDOUT:   ret i32 %M.call, !dbg !647
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !648 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !650
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.dc7dedd104b837b2:core.Destroy.Core"(ptr %self) #0 !dbg !652 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.array.index = getelementptr inbounds [3 x i32], ptr %self, i32 0, i64 2, !dbg !654
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.1.array.index), !dbg !654
// CHECK:STDOUT:   %.loc9_3.2.array.index = getelementptr inbounds [3 x i32], ptr %self, i32 0, i64 1, !dbg !654
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.2.array.index), !dbg !654
// CHECK:STDOUT:   %.loc9_3.3.array.index = getelementptr inbounds [3 x i32], ptr %self, i32 0, i64 0, !dbg !654
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.3.array.index), !dbg !654
// CHECK:STDOUT:   ret void, !dbg !654
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core"(ptr %self) #0 !dbg !656 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.dc7dedd104b837b2:core.Destroy.Core"(ptr %self), !dbg !658
// CHECK:STDOUT:   ret void, !dbg !658
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.d78496a987f075bd:core.Destroy.Core"(ptr %self) #0 !dbg !660 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.n = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %self, i32 0, i32 1, !dbg !662
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.1.n), !dbg !662
// CHECK:STDOUT:   %.loc9_3.2.a = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %self, i32 0, i32 0, !dbg !662
// CHECK:STDOUT:   call void @"_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core"(ptr %.loc9_3.2.a), !dbg !662
// CHECK:STDOUT:   ret void, !dbg !662
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d78496a987f075bd:core.Destroy.Core"(ptr %self) #0 !dbg !664 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.d78496a987f075bd:core.Destroy.Core"(ptr %self), !dbg !666
// CHECK:STDOUT:   ret void, !dbg !666
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.5e11dbc35420cea5:core.Destroy.Core"(ptr %self) #0 !dbg !668 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.n = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %self, i32 0, i32 1, !dbg !670
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.1.n), !dbg !670
// CHECK:STDOUT:   %.loc9_3.2.a = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %self, i32 0, i32 0, !dbg !670
// CHECK:STDOUT:   call void @"_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core"(ptr %.loc9_3.2.a), !dbg !670
// CHECK:STDOUT:   ret void, !dbg !670
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5e11dbc35420cea5:core.Destroy.Core"(ptr %self) #0 !dbg !672 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.5e11dbc35420cea5:core.Destroy.Core"(ptr %self), !dbg !674
// CHECK:STDOUT:   ret void, !dbg !674
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.ee4273acb03b174f:core.Destroy.Core"(ptr %self) #0 !dbg !676 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { { [3 x i32], i32 }, i32 }, ptr %self, i32 0, i32 1, !dbg !678
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !678
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { { [3 x i32], i32 }, i32 }, ptr %self, i32 0, i32 0, !dbg !678
// CHECK:STDOUT:   call void @"_CSelfDestruct.5e11dbc35420cea5:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !678
// CHECK:STDOUT:   ret void, !dbg !678
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.ee4273acb03b174f:core.Destroy.Core"(ptr %self) #0 !dbg !680 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.ee4273acb03b174f:core.Destroy.Core"(ptr %self), !dbg !682
// CHECK:STDOUT:   ret void, !dbg !682
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CM.Main.e384f2fa3c05f2f5(i32 %x) #0 !dbg !684 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %t.var = alloca { { [3 x i32], i32 }, i32 }, align 4, !dbg !689
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %t.var), !dbg !689
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { { [3 x i32], i32 }, i32 }, ptr %t.var, i32 0, i32 0, !dbg !694
// CHECK:STDOUT:   %.1cd.a = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %tuple.elem0.tuple.elem, i32 0, i32 0, !dbg !692
// CHECK:STDOUT:   %.759.array.index = getelementptr inbounds [3 x i32], ptr %.1cd.a, i32 0, i64 0, !dbg !691
// CHECK:STDOUT:   %.842.array.index = getelementptr inbounds [3 x i32], ptr %.1cd.a, i32 0, i64 1, !dbg !691
// CHECK:STDOUT:   %.aa8.array.index = getelementptr inbounds [3 x i32], ptr %.1cd.a, i32 0, i64 2, !dbg !691
// CHECK:STDOUT:   store i32 %x, ptr %.aa8.array.index, align 4, !dbg !691
// CHECK:STDOUT:   store i32 1, ptr %.759.array.index, align 4, !dbg !691
// CHECK:STDOUT:   store i32 2, ptr %.842.array.index, align 4, !dbg !691
// CHECK:STDOUT:   %.547.n = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %tuple.elem0.tuple.elem, i32 0, i32 1, !dbg !692
// CHECK:STDOUT:   store i32 3, ptr %.547.n, align 4, !dbg !692
// CHECK:STDOUT:   %tuple.elem1.loc9.tuple.elem = getelementptr inbounds nuw { { [3 x i32], i32 }, i32 }, ptr %t.var, i32 0, i32 1, !dbg !694
// CHECK:STDOUT:   store i32 %x, ptr %tuple.elem1.loc9.tuple.elem, align 4, !dbg !694
// CHECK:STDOUT:   %tuple.elem1.loc10.tuple.elem = getelementptr inbounds nuw { { [3 x i32], i32 }, i32 }, ptr %t.var, i32 0, i32 1, !dbg !696
// CHECK:STDOUT:   %.loc10 = load i32, ptr %tuple.elem1.loc10.tuple.elem, align 4, !dbg !696
// CHECK:STDOUT:   call void @"_CSelfDestruct.ee4273acb03b174f:core.Destroy.Core"(ptr %t.var), !dbg !689
// CHECK:STDOUT:   ret i32 %.loc10, !dbg !697
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!642}
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
// CHECK:STDOUT: !641 = !DIFile(filename: "var_tuple_of_class_with_dependent_array_bound.carbon", directory: "")
// CHECK:STDOUT: !642 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !641, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !643 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !641, line: 13, type: !98, spFlags: DISPFlagDefinition, unit: !642)
// CHECK:STDOUT: !646 = !DILocation(line: 14, column: 10, scope: !643)
// CHECK:STDOUT: !647 = !DILocation(line: 14, column: 3, scope: !643)
// CHECK:STDOUT: !648 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !641, line: 9, type: !299, spFlags: DISPFlagDefinition, unit: !642, retainedNodes: !651)
// CHECK:STDOUT: !649 = !DILocalVariable(arg: 1, scope: !648, type: !6)
// CHECK:STDOUT: !650 = !DILocation(line: 9, column: 3, scope: !648)
// CHECK:STDOUT: !651 = !{!649}
// CHECK:STDOUT: !652 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.dc7dedd104b837b2:core.Destroy.Core", scope: null, file: !641, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !642, retainedNodes: !655)
// CHECK:STDOUT: !653 = !DILocalVariable(arg: 1, scope: !652, type: !7)
// CHECK:STDOUT: !654 = !DILocation(line: 9, column: 3, scope: !652)
// CHECK:STDOUT: !655 = !{!653}
// CHECK:STDOUT: !656 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core", scope: null, file: !641, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !642, retainedNodes: !659)
// CHECK:STDOUT: !657 = !DILocalVariable(arg: 1, scope: !656, type: !7)
// CHECK:STDOUT: !658 = !DILocation(line: 9, column: 3, scope: !656)
// CHECK:STDOUT: !659 = !{!657}
// CHECK:STDOUT: !660 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.d78496a987f075bd:core.Destroy.Core", scope: null, file: !641, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !642, retainedNodes: !663)
// CHECK:STDOUT: !661 = !DILocalVariable(arg: 1, scope: !660, type: !7)
// CHECK:STDOUT: !662 = !DILocation(line: 9, column: 3, scope: !660)
// CHECK:STDOUT: !663 = !{!661}
// CHECK:STDOUT: !664 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d78496a987f075bd:core.Destroy.Core", scope: null, file: !641, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !642, retainedNodes: !667)
// CHECK:STDOUT: !665 = !DILocalVariable(arg: 1, scope: !664, type: !7)
// CHECK:STDOUT: !666 = !DILocation(line: 9, column: 3, scope: !664)
// CHECK:STDOUT: !667 = !{!665}
// CHECK:STDOUT: !668 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.5e11dbc35420cea5:core.Destroy.Core", scope: null, file: !641, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !642, retainedNodes: !671)
// CHECK:STDOUT: !669 = !DILocalVariable(arg: 1, scope: !668, type: !7)
// CHECK:STDOUT: !670 = !DILocation(line: 9, column: 3, scope: !668)
// CHECK:STDOUT: !671 = !{!669}
// CHECK:STDOUT: !672 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5e11dbc35420cea5:core.Destroy.Core", scope: null, file: !641, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !642, retainedNodes: !675)
// CHECK:STDOUT: !673 = !DILocalVariable(arg: 1, scope: !672, type: !7)
// CHECK:STDOUT: !674 = !DILocation(line: 9, column: 3, scope: !672)
// CHECK:STDOUT: !675 = !{!673}
// CHECK:STDOUT: !676 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.ee4273acb03b174f:core.Destroy.Core", scope: null, file: !641, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !642, retainedNodes: !679)
// CHECK:STDOUT: !677 = !DILocalVariable(arg: 1, scope: !676, type: !7)
// CHECK:STDOUT: !678 = !DILocation(line: 9, column: 3, scope: !676)
// CHECK:STDOUT: !679 = !{!677}
// CHECK:STDOUT: !680 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.ee4273acb03b174f:core.Destroy.Core", scope: null, file: !641, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !642, retainedNodes: !683)
// CHECK:STDOUT: !681 = !DILocalVariable(arg: 1, scope: !680, type: !7)
// CHECK:STDOUT: !682 = !DILocation(line: 9, column: 3, scope: !680)
// CHECK:STDOUT: !683 = !{!681}
// CHECK:STDOUT: !684 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main.e384f2fa3c05f2f5", scope: null, file: !641, line: 8, type: !104, spFlags: DISPFlagDefinition, unit: !642, retainedNodes: !698)
// CHECK:STDOUT: !685 = !DILocalVariable(arg: 1, scope: !684, type: !6)
// CHECK:STDOUT: !689 = !DILocation(line: 9, column: 3, scope: !684)
// CHECK:STDOUT: !691 = !DILocation(line: 9, column: 33, scope: !684)
// CHECK:STDOUT: !692 = !DILocation(line: 9, column: 27, scope: !684)
// CHECK:STDOUT: !694 = !DILocation(line: 9, column: 26, scope: !684)
// CHECK:STDOUT: !696 = !DILocation(line: 10, column: 10, scope: !684)
// CHECK:STDOUT: !697 = !DILocation(line: 10, column: 3, scope: !684)
// CHECK:STDOUT: !698 = !{!685}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'var_array_of_class_with_dependent_array_bound.carbon'
// CHECK:STDOUT: source_filename = "var_array_of_class_with_dependent_array_bound.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @array.dca.7dd = internal constant [3 x i32] [i32 4, i32 5, i32 6]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !701 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %M.call = call i32 @_CM.Main.e384f2fa3c05f2f5(i32 1), !dbg !704
// CHECK:STDOUT:   ret i32 %M.call, !dbg !705
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !706 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !708
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.dc7dedd104b837b2:core.Destroy.Core"(ptr %self) #0 !dbg !710 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.array.index = getelementptr inbounds [3 x i32], ptr %self, i32 0, i64 2, !dbg !712
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.1.array.index), !dbg !712
// CHECK:STDOUT:   %.loc9_3.2.array.index = getelementptr inbounds [3 x i32], ptr %self, i32 0, i64 1, !dbg !712
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.2.array.index), !dbg !712
// CHECK:STDOUT:   %.loc9_3.3.array.index = getelementptr inbounds [3 x i32], ptr %self, i32 0, i64 0, !dbg !712
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.3.array.index), !dbg !712
// CHECK:STDOUT:   ret void, !dbg !712
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core"(ptr %self) #0 !dbg !714 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.dc7dedd104b837b2:core.Destroy.Core"(ptr %self), !dbg !716
// CHECK:STDOUT:   ret void, !dbg !716
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.d78496a987f075bd:core.Destroy.Core"(ptr %self) #0 !dbg !718 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.n = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %self, i32 0, i32 1, !dbg !720
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.1.n), !dbg !720
// CHECK:STDOUT:   %.loc9_3.2.a = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %self, i32 0, i32 0, !dbg !720
// CHECK:STDOUT:   call void @"_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core"(ptr %.loc9_3.2.a), !dbg !720
// CHECK:STDOUT:   ret void, !dbg !720
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d78496a987f075bd:core.Destroy.Core"(ptr %self) #0 !dbg !722 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.d78496a987f075bd:core.Destroy.Core"(ptr %self), !dbg !724
// CHECK:STDOUT:   ret void, !dbg !724
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.5e11dbc35420cea5:core.Destroy.Core"(ptr %self) #0 !dbg !726 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.n = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %self, i32 0, i32 1, !dbg !728
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.1.n), !dbg !728
// CHECK:STDOUT:   %.loc9_3.2.a = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %self, i32 0, i32 0, !dbg !728
// CHECK:STDOUT:   call void @"_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core"(ptr %.loc9_3.2.a), !dbg !728
// CHECK:STDOUT:   ret void, !dbg !728
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5e11dbc35420cea5:core.Destroy.Core"(ptr %self) #0 !dbg !730 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.5e11dbc35420cea5:core.Destroy.Core"(ptr %self), !dbg !732
// CHECK:STDOUT:   ret void, !dbg !732
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a13b4521b2e02aea:core.Destroy.Core"(ptr %self) #0 !dbg !734 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.array.index = getelementptr inbounds [2 x { [3 x i32], i32 }], ptr %self, i32 0, i64 1, !dbg !736
// CHECK:STDOUT:   call void @"_CSelfDestruct.5e11dbc35420cea5:core.Destroy.Core"(ptr %.loc9_3.1.array.index), !dbg !736
// CHECK:STDOUT:   %.loc9_3.2.array.index = getelementptr inbounds [2 x { [3 x i32], i32 }], ptr %self, i32 0, i64 0, !dbg !736
// CHECK:STDOUT:   call void @"_CSelfDestruct.5e11dbc35420cea5:core.Destroy.Core"(ptr %.loc9_3.2.array.index), !dbg !736
// CHECK:STDOUT:   ret void, !dbg !736
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a13b4521b2e02aea:core.Destroy.Core"(ptr %self) #0 !dbg !738 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a13b4521b2e02aea:core.Destroy.Core"(ptr %self), !dbg !740
// CHECK:STDOUT:   ret void, !dbg !740
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CM.Main.e384f2fa3c05f2f5(i32 %x) #0 !dbg !742 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.var = alloca [2 x { [3 x i32], i32 }], align 4, !dbg !747
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %v.var), !dbg !747
// CHECK:STDOUT:   %.4bc.array.index = getelementptr inbounds [2 x { [3 x i32], i32 }], ptr %v.var, i32 0, i64 0, !dbg !753
// CHECK:STDOUT:   %.9ea.a = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %.4bc.array.index, i32 0, i32 0, !dbg !750
// CHECK:STDOUT:   %.af6.array.index = getelementptr inbounds [3 x i32], ptr %.9ea.a, i32 0, i64 0, !dbg !749
// CHECK:STDOUT:   store i32 %x, ptr %.af6.array.index, align 4, !dbg !749
// CHECK:STDOUT:   %.36b.array.index = getelementptr inbounds [3 x i32], ptr %.9ea.a, i32 0, i64 1, !dbg !749
// CHECK:STDOUT:   %.9c9.array.index = getelementptr inbounds [3 x i32], ptr %.9ea.a, i32 0, i64 2, !dbg !749
// CHECK:STDOUT:   store i32 2, ptr %.36b.array.index, align 4, !dbg !749
// CHECK:STDOUT:   store i32 3, ptr %.9c9.array.index, align 4, !dbg !749
// CHECK:STDOUT:   %.d3b.n = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %.4bc.array.index, i32 0, i32 1, !dbg !750
// CHECK:STDOUT:   store i32 3, ptr %.d3b.n, align 4, !dbg !750
// CHECK:STDOUT:   %.6d9.array.index = getelementptr inbounds [2 x { [3 x i32], i32 }], ptr %v.var, i32 0, i64 1, !dbg !753
// CHECK:STDOUT:   %.87a.a = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %.6d9.array.index, i32 0, i32 0, !dbg !752
// CHECK:STDOUT:   %.87f.array.index = getelementptr inbounds [3 x i32], ptr %.87a.a, i32 0, i64 0, !dbg !754
// CHECK:STDOUT:   %.956.array.index = getelementptr inbounds [3 x i32], ptr %.87a.a, i32 0, i64 1, !dbg !754
// CHECK:STDOUT:   %.3e1.array.index = getelementptr inbounds [3 x i32], ptr %.87a.a, i32 0, i64 2, !dbg !754
// CHECK:STDOUT:   %.c54.n = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %.6d9.array.index, i32 0, i32 1, !dbg !752
// CHECK:STDOUT:   store i32 %x, ptr %.c54.n, align 4, !dbg !752
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %.87a.a, ptr align 4 @array.dca.7dd, i64 12, i1 false), !dbg !752
// CHECK:STDOUT:   %.loc10_13.array.index = getelementptr inbounds [2 x { [3 x i32], i32 }], ptr %v.var, i32 0, i32 1, !dbg !756
// CHECK:STDOUT:   %.0d8.n = getelementptr inbounds nuw { [3 x i32], i32 }, ptr %.loc10_13.array.index, i32 0, i32 1, !dbg !756
// CHECK:STDOUT:   %.950 = load i32, ptr %.0d8.n, align 4, !dbg !756
// CHECK:STDOUT:   call void @"_CSelfDestruct.a13b4521b2e02aea:core.Destroy.Core"(ptr %v.var), !dbg !747
// CHECK:STDOUT:   ret i32 %.950, !dbg !757
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!700}
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
// CHECK:STDOUT: !699 = !DIFile(filename: "var_array_of_class_with_dependent_array_bound.carbon", directory: "")
// CHECK:STDOUT: !700 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !699, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !701 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !699, line: 13, type: !98, spFlags: DISPFlagDefinition, unit: !700)
// CHECK:STDOUT: !704 = !DILocation(line: 14, column: 10, scope: !701)
// CHECK:STDOUT: !705 = !DILocation(line: 14, column: 3, scope: !701)
// CHECK:STDOUT: !706 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !699, line: 9, type: !299, spFlags: DISPFlagDefinition, unit: !700, retainedNodes: !709)
// CHECK:STDOUT: !707 = !DILocalVariable(arg: 1, scope: !706, type: !6)
// CHECK:STDOUT: !708 = !DILocation(line: 9, column: 3, scope: !706)
// CHECK:STDOUT: !709 = !{!707}
// CHECK:STDOUT: !710 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.dc7dedd104b837b2:core.Destroy.Core", scope: null, file: !699, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !700, retainedNodes: !713)
// CHECK:STDOUT: !711 = !DILocalVariable(arg: 1, scope: !710, type: !7)
// CHECK:STDOUT: !712 = !DILocation(line: 9, column: 3, scope: !710)
// CHECK:STDOUT: !713 = !{!711}
// CHECK:STDOUT: !714 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core", scope: null, file: !699, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !700, retainedNodes: !717)
// CHECK:STDOUT: !715 = !DILocalVariable(arg: 1, scope: !714, type: !7)
// CHECK:STDOUT: !716 = !DILocation(line: 9, column: 3, scope: !714)
// CHECK:STDOUT: !717 = !{!715}
// CHECK:STDOUT: !718 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.d78496a987f075bd:core.Destroy.Core", scope: null, file: !699, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !700, retainedNodes: !721)
// CHECK:STDOUT: !719 = !DILocalVariable(arg: 1, scope: !718, type: !7)
// CHECK:STDOUT: !720 = !DILocation(line: 9, column: 3, scope: !718)
// CHECK:STDOUT: !721 = !{!719}
// CHECK:STDOUT: !722 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d78496a987f075bd:core.Destroy.Core", scope: null, file: !699, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !700, retainedNodes: !725)
// CHECK:STDOUT: !723 = !DILocalVariable(arg: 1, scope: !722, type: !7)
// CHECK:STDOUT: !724 = !DILocation(line: 9, column: 3, scope: !722)
// CHECK:STDOUT: !725 = !{!723}
// CHECK:STDOUT: !726 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.5e11dbc35420cea5:core.Destroy.Core", scope: null, file: !699, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !700, retainedNodes: !729)
// CHECK:STDOUT: !727 = !DILocalVariable(arg: 1, scope: !726, type: !7)
// CHECK:STDOUT: !728 = !DILocation(line: 9, column: 3, scope: !726)
// CHECK:STDOUT: !729 = !{!727}
// CHECK:STDOUT: !730 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5e11dbc35420cea5:core.Destroy.Core", scope: null, file: !699, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !700, retainedNodes: !733)
// CHECK:STDOUT: !731 = !DILocalVariable(arg: 1, scope: !730, type: !7)
// CHECK:STDOUT: !732 = !DILocation(line: 9, column: 3, scope: !730)
// CHECK:STDOUT: !733 = !{!731}
// CHECK:STDOUT: !734 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a13b4521b2e02aea:core.Destroy.Core", scope: null, file: !699, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !700, retainedNodes: !737)
// CHECK:STDOUT: !735 = !DILocalVariable(arg: 1, scope: !734, type: !7)
// CHECK:STDOUT: !736 = !DILocation(line: 9, column: 3, scope: !734)
// CHECK:STDOUT: !737 = !{!735}
// CHECK:STDOUT: !738 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a13b4521b2e02aea:core.Destroy.Core", scope: null, file: !699, line: 9, type: !174, spFlags: DISPFlagDefinition, unit: !700, retainedNodes: !741)
// CHECK:STDOUT: !739 = !DILocalVariable(arg: 1, scope: !738, type: !7)
// CHECK:STDOUT: !740 = !DILocation(line: 9, column: 3, scope: !738)
// CHECK:STDOUT: !741 = !{!739}
// CHECK:STDOUT: !742 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main.e384f2fa3c05f2f5", scope: null, file: !699, line: 8, type: !104, spFlags: DISPFlagDefinition, unit: !700, retainedNodes: !758)
// CHECK:STDOUT: !743 = !DILocalVariable(arg: 1, scope: !742, type: !6)
// CHECK:STDOUT: !747 = !DILocation(line: 9, column: 3, scope: !742)
// CHECK:STDOUT: !749 = !DILocation(line: 9, column: 36, scope: !742)
// CHECK:STDOUT: !750 = !DILocation(line: 9, column: 30, scope: !742)
// CHECK:STDOUT: !752 = !DILocation(line: 9, column: 56, scope: !742)
// CHECK:STDOUT: !753 = !DILocation(line: 9, column: 29, scope: !742)
// CHECK:STDOUT: !754 = !DILocation(line: 9, column: 62, scope: !742)
// CHECK:STDOUT: !756 = !DILocation(line: 10, column: 10, scope: !742)
// CHECK:STDOUT: !757 = !DILocation(line: 10, column: 3, scope: !742)
// CHECK:STDOUT: !758 = !{!743}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'let_class_value_with_template_value_field.carbon'
// CHECK:STDOUT: source_filename = "let_class_value_with_template_value_field.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !761 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %M.call = call i32 @_CM.Main.e384f2fa3c05f2f5(i32 1), !dbg !764
// CHECK:STDOUT:   ret i32 %M.call, !dbg !765
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CM.Main.e384f2fa3c05f2f5(i32 %x) #0 !dbg !766 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.a02.temp = alloca { i32, i32 }, align 4, !dbg !772
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.a02.temp), !dbg !772
// CHECK:STDOUT:   %.003.a = getelementptr inbounds nuw { i32, i32 }, ptr %.a02.temp, i32 0, i32 0, !dbg !772
// CHECK:STDOUT:   store i32 %x, ptr %.003.a, align 4, !dbg !772
// CHECK:STDOUT:   %.e57.b = getelementptr inbounds nuw { i32, i32 }, ptr %.a02.temp, i32 0, i32 1, !dbg !772
// CHECK:STDOUT:   store i32 3, ptr %.e57.b, align 4, !dbg !772
// CHECK:STDOUT:   %.8df.a = getelementptr inbounds nuw { i32, i32 }, ptr %.a02.temp, i32 0, i32 0, !dbg !775
// CHECK:STDOUT:   %.eb8 = load i32, ptr %.8df.a, align 4, !dbg !775
// CHECK:STDOUT:   ret i32 %.eb8, !dbg !776
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!760}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !97 = !{!6}
// CHECK:STDOUT: !98 = !DISubroutineType(types: !97)
// CHECK:STDOUT: !103 = !{!6, !6}
// CHECK:STDOUT: !104 = !DISubroutineType(types: !103)
// CHECK:STDOUT: !759 = !DIFile(filename: "let_class_value_with_template_value_field.carbon", directory: "")
// CHECK:STDOUT: !760 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !759, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !761 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !759, line: 13, type: !98, spFlags: DISPFlagDefinition, unit: !760)
// CHECK:STDOUT: !764 = !DILocation(line: 14, column: 10, scope: !761)
// CHECK:STDOUT: !765 = !DILocation(line: 14, column: 3, scope: !761)
// CHECK:STDOUT: !766 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main.e384f2fa3c05f2f5", scope: null, file: !759, line: 8, type: !104, spFlags: DISPFlagDefinition, unit: !760, retainedNodes: !777)
// CHECK:STDOUT: !767 = !DILocalVariable(arg: 1, scope: !766, type: !6)
// CHECK:STDOUT: !772 = !DILocation(line: 9, column: 17, scope: !766)
// CHECK:STDOUT: !775 = !DILocation(line: 10, column: 10, scope: !766)
// CHECK:STDOUT: !776 = !DILocation(line: 10, column: 3, scope: !766)
// CHECK:STDOUT: !777 = !{!767}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'var_class_template_associated_field.carbon'
// CHECK:STDOUT: source_filename = "var_class_template_associated_field.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Box.val.loc17_3.1 = internal constant { i32, i32 } { i32 4, i32 5 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main(ptr %h) #0 !dbg !780 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call i32 @_CG.Main.882856c67732e28b(ptr %h), !dbg !786
// CHECK:STDOUT:   ret i32 %G.call, !dbg !787
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !789 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !791
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b8e09e9dedb8cd22:core.Destroy.Core"(ptr %self) #0 !dbg !793 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_3.1.n = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !795
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc17_3.1.n), !dbg !795
// CHECK:STDOUT:   %.loc17_3.2.item = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !795
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc17_3.2.item), !dbg !795
// CHECK:STDOUT:   ret void, !dbg !795
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b8e09e9dedb8cd22:core.Destroy.Core"(ptr %self) #0 !dbg !797 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b8e09e9dedb8cd22:core.Destroy.Core"(ptr %self), !dbg !799
// CHECK:STDOUT:   ret void, !dbg !799
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.385283f6f902f4be:core.Destroy.Core"(ptr %self) #0 !dbg !801 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_3.1.n = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !803
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc17_3.1.n), !dbg !803
// CHECK:STDOUT:   %.loc17_3.2.item = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !803
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc17_3.2.item), !dbg !803
// CHECK:STDOUT:   ret void, !dbg !803
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.385283f6f902f4be:core.Destroy.Core"(ptr %self) #0 !dbg !805 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.385283f6f902f4be:core.Destroy.Core"(ptr %self), !dbg !807
// CHECK:STDOUT:   ret void, !dbg !807
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CG.Main.882856c67732e28b(ptr %x) #0 !dbg !809 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %b.var = alloca { i32, i32 }, align 4, !dbg !814
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !814
// CHECK:STDOUT:   %.4d2.item = getelementptr inbounds nuw { i32, i32 }, ptr %b.var, i32 0, i32 0, !dbg !815
// CHECK:STDOUT:   %.c57.n = getelementptr inbounds nuw { i32, i32 }, ptr %b.var, i32 0, i32 1, !dbg !815
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %b.var, ptr align 4 @Box.val.loc17_3.1, i64 8, i1 false), !dbg !814
// CHECK:STDOUT:   %.db1.n = getelementptr inbounds nuw { i32, i32 }, ptr %b.var, i32 0, i32 1, !dbg !817
// CHECK:STDOUT:   %.490 = load i32, ptr %.db1.n, align 4, !dbg !817
// CHECK:STDOUT:   call void @"_CSelfDestruct.385283f6f902f4be:core.Destroy.Core"(ptr %b.var), !dbg !814
// CHECK:STDOUT:   ret i32 %.490, !dbg !818
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!779}
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
// CHECK:STDOUT: !778 = !DIFile(filename: "var_class_template_associated_field.carbon", directory: "")
// CHECK:STDOUT: !779 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !778, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !780 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !778, line: 21, type: !176, spFlags: DISPFlagDefinition, unit: !779, retainedNodes: !788)
// CHECK:STDOUT: !781 = !DILocalVariable(arg: 1, scope: !780, type: !7)
// CHECK:STDOUT: !786 = !DILocation(line: 22, column: 10, scope: !780)
// CHECK:STDOUT: !787 = !DILocation(line: 22, column: 3, scope: !780)
// CHECK:STDOUT: !788 = !{!781}
// CHECK:STDOUT: !789 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !778, line: 17, type: !299, spFlags: DISPFlagDefinition, unit: !779, retainedNodes: !792)
// CHECK:STDOUT: !790 = !DILocalVariable(arg: 1, scope: !789, type: !6)
// CHECK:STDOUT: !791 = !DILocation(line: 17, column: 3, scope: !789)
// CHECK:STDOUT: !792 = !{!790}
// CHECK:STDOUT: !793 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b8e09e9dedb8cd22:core.Destroy.Core", scope: null, file: !778, line: 17, type: !174, spFlags: DISPFlagDefinition, unit: !779, retainedNodes: !796)
// CHECK:STDOUT: !794 = !DILocalVariable(arg: 1, scope: !793, type: !7)
// CHECK:STDOUT: !795 = !DILocation(line: 17, column: 3, scope: !793)
// CHECK:STDOUT: !796 = !{!794}
// CHECK:STDOUT: !797 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b8e09e9dedb8cd22:core.Destroy.Core", scope: null, file: !778, line: 17, type: !174, spFlags: DISPFlagDefinition, unit: !779, retainedNodes: !800)
// CHECK:STDOUT: !798 = !DILocalVariable(arg: 1, scope: !797, type: !7)
// CHECK:STDOUT: !799 = !DILocation(line: 17, column: 3, scope: !797)
// CHECK:STDOUT: !800 = !{!798}
// CHECK:STDOUT: !801 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.385283f6f902f4be:core.Destroy.Core", scope: null, file: !778, line: 17, type: !174, spFlags: DISPFlagDefinition, unit: !779, retainedNodes: !804)
// CHECK:STDOUT: !802 = !DILocalVariable(arg: 1, scope: !801, type: !7)
// CHECK:STDOUT: !803 = !DILocation(line: 17, column: 3, scope: !801)
// CHECK:STDOUT: !804 = !{!802}
// CHECK:STDOUT: !805 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.385283f6f902f4be:core.Destroy.Core", scope: null, file: !778, line: 17, type: !174, spFlags: DISPFlagDefinition, unit: !779, retainedNodes: !808)
// CHECK:STDOUT: !806 = !DILocalVariable(arg: 1, scope: !805, type: !7)
// CHECK:STDOUT: !807 = !DILocation(line: 17, column: 3, scope: !805)
// CHECK:STDOUT: !808 = !{!806}
// CHECK:STDOUT: !809 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.882856c67732e28b", scope: null, file: !778, line: 16, type: !176, spFlags: DISPFlagDefinition, unit: !779, retainedNodes: !819)
// CHECK:STDOUT: !810 = !DILocalVariable(arg: 1, scope: !809, type: !7)
// CHECK:STDOUT: !814 = !DILocation(line: 17, column: 3, scope: !809)
// CHECK:STDOUT: !815 = !DILocation(line: 0, scope: !809)
// CHECK:STDOUT: !817 = !DILocation(line: 18, column: 10, scope: !809)
// CHECK:STDOUT: !818 = !DILocation(line: 18, column: 3, scope: !809)
// CHECK:STDOUT: !819 = !{!810}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'return_class_template_associated_field.carbon'
// CHECK:STDOUT: source_filename = "return_class_template_associated_field.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(ptr sret({ i32, i32 }) %return, ptr %h) #0 !dbg !822 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CG.Main.882856c67732e28b(ptr %return, ptr %h, i32 4), !dbg !828
// CHECK:STDOUT:   ret void, !dbg !831
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CG.Main.882856c67732e28b(ptr sret({ i32, i32 }) %return, ptr %x, i32 %y) #0 !dbg !833 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.919.item = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !841
// CHECK:STDOUT:   store i32 %y, ptr %.919.item, align 4, !dbg !841
// CHECK:STDOUT:   %.626.n = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !841
// CHECK:STDOUT:   store i32 5, ptr %.626.n, align 4, !dbg !841
// CHECK:STDOUT:   ret void, !dbg !842
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!821}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !820 = !DIFile(filename: "return_class_template_associated_field.carbon", directory: "")
// CHECK:STDOUT: !821 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !820, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !822 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !820, line: 20, type: !9, spFlags: DISPFlagDefinition, unit: !821, retainedNodes: !832)
// CHECK:STDOUT: !823 = !DILocalVariable(arg: 1, scope: !822, type: !7)
// CHECK:STDOUT: !828 = !DILocation(line: 21, column: 10, scope: !822)
// CHECK:STDOUT: !829 = !{!7, !7, !6}
// CHECK:STDOUT: !830 = !DISubroutineType(types: !829)
// CHECK:STDOUT: !831 = !DILocation(line: 21, column: 3, scope: !822)
// CHECK:STDOUT: !832 = !{!823}
// CHECK:STDOUT: !833 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.882856c67732e28b", scope: null, file: !820, line: 16, type: !830, spFlags: DISPFlagDefinition, unit: !821, retainedNodes: !843)
// CHECK:STDOUT: !834 = !DILocalVariable(arg: 1, scope: !833, type: !7)
// CHECK:STDOUT: !835 = !DILocalVariable(arg: 2, scope: !833, type: !6)
// CHECK:STDOUT: !841 = !DILocation(line: 17, column: 10, scope: !833)
// CHECK:STDOUT: !842 = !DILocation(line: 17, column: 3, scope: !833)
// CHECK:STDOUT: !843 = !{!834, !835}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'class_template_factory_associated_field.carbon'
// CHECK:STDOUT: source_filename = "class_template_factory_associated_field.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(ptr sret({ i32, i32 }) %return) #0 !dbg !846 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CMake.Box.Main.882856c67732e28b(ptr %return, i32 4), !dbg !849
// CHECK:STDOUT:   ret void, !dbg !850
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CMake.Box.Main.882856c67732e28b(ptr sret({ i32, i32 }) %return, i32 %item) #0 !dbg !851 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.5b6.item = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !857
// CHECK:STDOUT:   store i32 %item, ptr %.5b6.item, align 4, !dbg !857
// CHECK:STDOUT:   %.60c.n = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !857
// CHECK:STDOUT:   store i32 5, ptr %.60c.n, align 4, !dbg !857
// CHECK:STDOUT:   ret void, !dbg !858
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!845}
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
// CHECK:STDOUT: !844 = !DIFile(filename: "class_template_factory_associated_field.carbon", directory: "")
// CHECK:STDOUT: !845 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !844, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !846 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !844, line: 20, type: !30, spFlags: DISPFlagDefinition, unit: !845)
// CHECK:STDOUT: !849 = !DILocation(line: 21, column: 10, scope: !846)
// CHECK:STDOUT: !850 = !DILocation(line: 21, column: 3, scope: !846)
// CHECK:STDOUT: !851 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.Box.Main.882856c67732e28b", scope: null, file: !844, line: 15, type: !36, spFlags: DISPFlagDefinition, unit: !845, retainedNodes: !859)
// CHECK:STDOUT: !852 = !DILocalVariable(arg: 1, scope: !851, type: !6)
// CHECK:STDOUT: !857 = !DILocation(line: 16, column: 12, scope: !851)
// CHECK:STDOUT: !858 = !DILocation(line: 16, column: 5, scope: !851)
// CHECK:STDOUT: !859 = !{!852}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'class_template_associated_pointer_field.carbon'
// CHECK:STDOUT: source_filename = "class_template_associated_pointer_field.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main(ptr %h, ptr %p) #0 !dbg !864 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call i32 @_CG.Main.882856c67732e28b(ptr %h, ptr %p), !dbg !873
// CHECK:STDOUT:   ret i32 %G.call, !dbg !874
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %self) #0 !dbg !876 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !878
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !880 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !882
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.91b33a339e28ee0d:core.Destroy.Core"(ptr %self) #0 !dbg !884 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_3.1.n = getelementptr inbounds nuw <{ ptr, i32 }>, ptr %self, i32 0, i32 1, !dbg !886
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc17_3.1.n), !dbg !886
// CHECK:STDOUT:   %.loc17_3.2.p = getelementptr inbounds nuw <{ ptr, i32 }>, ptr %self, i32 0, i32 0, !dbg !886
// CHECK:STDOUT:   call void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %.loc17_3.2.p), !dbg !886
// CHECK:STDOUT:   ret void, !dbg !886
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.91b33a339e28ee0d:core.Destroy.Core"(ptr %self) #0 !dbg !888 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.91b33a339e28ee0d:core.Destroy.Core"(ptr %self), !dbg !890
// CHECK:STDOUT:   ret void, !dbg !890
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b6882a50fb2195da:core.Destroy.Core"(ptr %self) #0 !dbg !892 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_3.1.n = getelementptr inbounds nuw <{ ptr, i32 }>, ptr %self, i32 0, i32 1, !dbg !894
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc17_3.1.n), !dbg !894
// CHECK:STDOUT:   %.loc17_3.2.p = getelementptr inbounds nuw <{ ptr, i32 }>, ptr %self, i32 0, i32 0, !dbg !894
// CHECK:STDOUT:   call void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %.loc17_3.2.p), !dbg !894
// CHECK:STDOUT:   ret void, !dbg !894
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b6882a50fb2195da:core.Destroy.Core"(ptr %self) #0 !dbg !896 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b6882a50fb2195da:core.Destroy.Core"(ptr %self), !dbg !898
// CHECK:STDOUT:   ret void, !dbg !898
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CG.Main.882856c67732e28b(ptr %x, ptr %p) #0 !dbg !900 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %b.var = alloca <{ ptr, i32 }>, align 8, !dbg !907
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !907
// CHECK:STDOUT:   %.14f.p = getelementptr inbounds nuw <{ ptr, i32 }>, ptr %b.var, i32 0, i32 0, !dbg !909
// CHECK:STDOUT:   store ptr %p, ptr %.14f.p, align 8, !dbg !909
// CHECK:STDOUT:   %.d3d.n = getelementptr inbounds nuw <{ ptr, i32 }>, ptr %b.var, i32 0, i32 1, !dbg !909
// CHECK:STDOUT:   store i32 5, ptr %.d3d.n, align 4, !dbg !909
// CHECK:STDOUT:   %.665.n = getelementptr inbounds nuw <{ ptr, i32 }>, ptr %b.var, i32 0, i32 1, !dbg !911
// CHECK:STDOUT:   %.cef = load i32, ptr %.665.n, align 4, !dbg !911
// CHECK:STDOUT:   call void @"_CSelfDestruct.b6882a50fb2195da:core.Destroy.Core"(ptr %b.var), !dbg !907
// CHECK:STDOUT:   ret i32 %.cef, !dbg !912
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!861}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !173 = !{null, !7}
// CHECK:STDOUT: !174 = !DISubroutineType(types: !173)
// CHECK:STDOUT: !298 = !{null, !6}
// CHECK:STDOUT: !299 = !DISubroutineType(types: !298)
// CHECK:STDOUT: !860 = !DIFile(filename: "class_template_associated_pointer_field.carbon", directory: "")
// CHECK:STDOUT: !861 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !860, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !862 = !{!6, !7, !7}
// CHECK:STDOUT: !863 = !DISubroutineType(types: !862)
// CHECK:STDOUT: !864 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !860, line: 21, type: !863, spFlags: DISPFlagDefinition, unit: !861, retainedNodes: !875)
// CHECK:STDOUT: !865 = !DILocalVariable(arg: 1, scope: !864, type: !7)
// CHECK:STDOUT: !866 = !DILocalVariable(arg: 2, scope: !864, type: !7)
// CHECK:STDOUT: !873 = !DILocation(line: 22, column: 10, scope: !864)
// CHECK:STDOUT: !874 = !DILocation(line: 22, column: 3, scope: !864)
// CHECK:STDOUT: !875 = !{!865, !866}
// CHECK:STDOUT: !876 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d088c7eb746488be:core.Destroy.Core", scope: null, file: !860, line: 17, type: !174, spFlags: DISPFlagDefinition, unit: !861, retainedNodes: !879)
// CHECK:STDOUT: !877 = !DILocalVariable(arg: 1, scope: !876, type: !7)
// CHECK:STDOUT: !878 = !DILocation(line: 17, column: 3, scope: !876)
// CHECK:STDOUT: !879 = !{!877}
// CHECK:STDOUT: !880 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !860, line: 17, type: !299, spFlags: DISPFlagDefinition, unit: !861, retainedNodes: !883)
// CHECK:STDOUT: !881 = !DILocalVariable(arg: 1, scope: !880, type: !6)
// CHECK:STDOUT: !882 = !DILocation(line: 17, column: 3, scope: !880)
// CHECK:STDOUT: !883 = !{!881}
// CHECK:STDOUT: !884 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.91b33a339e28ee0d:core.Destroy.Core", scope: null, file: !860, line: 17, type: !174, spFlags: DISPFlagDefinition, unit: !861, retainedNodes: !887)
// CHECK:STDOUT: !885 = !DILocalVariable(arg: 1, scope: !884, type: !7)
// CHECK:STDOUT: !886 = !DILocation(line: 17, column: 3, scope: !884)
// CHECK:STDOUT: !887 = !{!885}
// CHECK:STDOUT: !888 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.91b33a339e28ee0d:core.Destroy.Core", scope: null, file: !860, line: 17, type: !174, spFlags: DISPFlagDefinition, unit: !861, retainedNodes: !891)
// CHECK:STDOUT: !889 = !DILocalVariable(arg: 1, scope: !888, type: !7)
// CHECK:STDOUT: !890 = !DILocation(line: 17, column: 3, scope: !888)
// CHECK:STDOUT: !891 = !{!889}
// CHECK:STDOUT: !892 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b6882a50fb2195da:core.Destroy.Core", scope: null, file: !860, line: 17, type: !174, spFlags: DISPFlagDefinition, unit: !861, retainedNodes: !895)
// CHECK:STDOUT: !893 = !DILocalVariable(arg: 1, scope: !892, type: !7)
// CHECK:STDOUT: !894 = !DILocation(line: 17, column: 3, scope: !892)
// CHECK:STDOUT: !895 = !{!893}
// CHECK:STDOUT: !896 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b6882a50fb2195da:core.Destroy.Core", scope: null, file: !860, line: 17, type: !174, spFlags: DISPFlagDefinition, unit: !861, retainedNodes: !899)
// CHECK:STDOUT: !897 = !DILocalVariable(arg: 1, scope: !896, type: !7)
// CHECK:STDOUT: !898 = !DILocation(line: 17, column: 3, scope: !896)
// CHECK:STDOUT: !899 = !{!897}
// CHECK:STDOUT: !900 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.882856c67732e28b", scope: null, file: !860, line: 16, type: !863, spFlags: DISPFlagDefinition, unit: !861, retainedNodes: !913)
// CHECK:STDOUT: !901 = !DILocalVariable(arg: 1, scope: !900, type: !7)
// CHECK:STDOUT: !902 = !DILocalVariable(arg: 2, scope: !900, type: !7)
// CHECK:STDOUT: !907 = !DILocation(line: 17, column: 3, scope: !900)
// CHECK:STDOUT: !909 = !DILocation(line: 17, column: 22, scope: !900)
// CHECK:STDOUT: !911 = !DILocation(line: 18, column: 10, scope: !900)
// CHECK:STDOUT: !912 = !DILocation(line: 18, column: 3, scope: !900)
// CHECK:STDOUT: !913 = !{!901, !902}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'nested_class_template_computed_argument.carbon'
// CHECK:STDOUT: source_filename = "nested_class_template_computed_argument.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Outer.val.loc12_3.1 = internal constant { { i32 } } { { i32 } { i32 4 } }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !916 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call i32 @_CG.Main.ab91bdd0280f46ae(), !dbg !919
// CHECK:STDOUT:   ret i32 %G.call, !dbg !920
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !921 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !923
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a9280e8bea6fc5f9:core.Destroy.Core"(ptr %self) #0 !dbg !925 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12.a = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !927
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc12.a), !dbg !927
// CHECK:STDOUT:   ret void, !dbg !927
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a9280e8bea6fc5f9:core.Destroy.Core"(ptr %self) #0 !dbg !929 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a9280e8bea6fc5f9:core.Destroy.Core"(ptr %self), !dbg !931
// CHECK:STDOUT:   ret void, !dbg !931
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.53dac1980bfe8777:core.Destroy.Core"(ptr %self) #0 !dbg !933 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12.a = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !935
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc12.a), !dbg !935
// CHECK:STDOUT:   ret void, !dbg !935
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.53dac1980bfe8777:core.Destroy.Core"(ptr %self) #0 !dbg !937 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.53dac1980bfe8777:core.Destroy.Core"(ptr %self), !dbg !939
// CHECK:STDOUT:   ret void, !dbg !939
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a843c95eae9f9356:core.Destroy.Core"(ptr %self) #0 !dbg !941 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12.c = getelementptr inbounds nuw { { i32 } }, ptr %self, i32 0, i32 0, !dbg !943
// CHECK:STDOUT:   call void @"_CSelfDestruct.53dac1980bfe8777:core.Destroy.Core"(ptr %.loc12.c), !dbg !943
// CHECK:STDOUT:   ret void, !dbg !943
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a843c95eae9f9356:core.Destroy.Core"(ptr %self) #0 !dbg !945 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a843c95eae9f9356:core.Destroy.Core"(ptr %self), !dbg !947
// CHECK:STDOUT:   ret void, !dbg !947
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b15b2f79ab5ce932:core.Destroy.Core"(ptr %self) #0 !dbg !949 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12.c = getelementptr inbounds nuw { { i32 } }, ptr %self, i32 0, i32 0, !dbg !951
// CHECK:STDOUT:   call void @"_CSelfDestruct.53dac1980bfe8777:core.Destroy.Core"(ptr %.loc12.c), !dbg !951
// CHECK:STDOUT:   ret void, !dbg !951
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b15b2f79ab5ce932:core.Destroy.Core"(ptr %self) #0 !dbg !953 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b15b2f79ab5ce932:core.Destroy.Core"(ptr %self), !dbg !955
// CHECK:STDOUT:   ret void, !dbg !955
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CG.Main.ab91bdd0280f46ae() #0 !dbg !957 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %o.var = alloca { { i32 } }, align 4, !dbg !960
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %o.var), !dbg !960
// CHECK:STDOUT:   %.c69.c = getelementptr inbounds nuw { { i32 } }, ptr %o.var, i32 0, i32 0, !dbg !961
// CHECK:STDOUT:   %.72e.a = getelementptr inbounds nuw { i32 }, ptr %.c69.c, i32 0, i32 0, !dbg !961
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %o.var, ptr align 4 @Outer.val.loc12_3.1, i64 4, i1 false), !dbg !960
// CHECK:STDOUT:   %.bc6.c = getelementptr inbounds nuw { { i32 } }, ptr %o.var, i32 0, i32 0, !dbg !963
// CHECK:STDOUT:   %.c0b.a = getelementptr inbounds nuw { i32 }, ptr %.bc6.c, i32 0, i32 0, !dbg !963
// CHECK:STDOUT:   %.43b = load i32, ptr %.c0b.a, align 4, !dbg !963
// CHECK:STDOUT:   call void @"_CSelfDestruct.b15b2f79ab5ce932:core.Destroy.Core"(ptr %o.var), !dbg !960
// CHECK:STDOUT:   ret i32 %.43b, !dbg !964
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!915}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !97 = !{!6}
// CHECK:STDOUT: !98 = !DISubroutineType(types: !97)
// CHECK:STDOUT: !173 = !{null, !7}
// CHECK:STDOUT: !174 = !DISubroutineType(types: !173)
// CHECK:STDOUT: !298 = !{null, !6}
// CHECK:STDOUT: !299 = !DISubroutineType(types: !298)
// CHECK:STDOUT: !914 = !DIFile(filename: "nested_class_template_computed_argument.carbon", directory: "")
// CHECK:STDOUT: !915 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !914, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !916 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !914, line: 16, type: !98, spFlags: DISPFlagDefinition, unit: !915)
// CHECK:STDOUT: !919 = !DILocation(line: 17, column: 10, scope: !916)
// CHECK:STDOUT: !920 = !DILocation(line: 17, column: 3, scope: !916)
// CHECK:STDOUT: !921 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !914, line: 12, type: !299, spFlags: DISPFlagDefinition, unit: !915, retainedNodes: !924)
// CHECK:STDOUT: !922 = !DILocalVariable(arg: 1, scope: !921, type: !6)
// CHECK:STDOUT: !923 = !DILocation(line: 12, column: 3, scope: !921)
// CHECK:STDOUT: !924 = !{!922}
// CHECK:STDOUT: !925 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a9280e8bea6fc5f9:core.Destroy.Core", scope: null, file: !914, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !915, retainedNodes: !928)
// CHECK:STDOUT: !926 = !DILocalVariable(arg: 1, scope: !925, type: !7)
// CHECK:STDOUT: !927 = !DILocation(line: 12, column: 3, scope: !925)
// CHECK:STDOUT: !928 = !{!926}
// CHECK:STDOUT: !929 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a9280e8bea6fc5f9:core.Destroy.Core", scope: null, file: !914, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !915, retainedNodes: !932)
// CHECK:STDOUT: !930 = !DILocalVariable(arg: 1, scope: !929, type: !7)
// CHECK:STDOUT: !931 = !DILocation(line: 12, column: 3, scope: !929)
// CHECK:STDOUT: !932 = !{!930}
// CHECK:STDOUT: !933 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.53dac1980bfe8777:core.Destroy.Core", scope: null, file: !914, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !915, retainedNodes: !936)
// CHECK:STDOUT: !934 = !DILocalVariable(arg: 1, scope: !933, type: !7)
// CHECK:STDOUT: !935 = !DILocation(line: 12, column: 3, scope: !933)
// CHECK:STDOUT: !936 = !{!934}
// CHECK:STDOUT: !937 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.53dac1980bfe8777:core.Destroy.Core", scope: null, file: !914, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !915, retainedNodes: !940)
// CHECK:STDOUT: !938 = !DILocalVariable(arg: 1, scope: !937, type: !7)
// CHECK:STDOUT: !939 = !DILocation(line: 12, column: 3, scope: !937)
// CHECK:STDOUT: !940 = !{!938}
// CHECK:STDOUT: !941 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a843c95eae9f9356:core.Destroy.Core", scope: null, file: !914, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !915, retainedNodes: !944)
// CHECK:STDOUT: !942 = !DILocalVariable(arg: 1, scope: !941, type: !7)
// CHECK:STDOUT: !943 = !DILocation(line: 12, column: 3, scope: !941)
// CHECK:STDOUT: !944 = !{!942}
// CHECK:STDOUT: !945 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a843c95eae9f9356:core.Destroy.Core", scope: null, file: !914, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !915, retainedNodes: !948)
// CHECK:STDOUT: !946 = !DILocalVariable(arg: 1, scope: !945, type: !7)
// CHECK:STDOUT: !947 = !DILocation(line: 12, column: 3, scope: !945)
// CHECK:STDOUT: !948 = !{!946}
// CHECK:STDOUT: !949 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b15b2f79ab5ce932:core.Destroy.Core", scope: null, file: !914, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !915, retainedNodes: !952)
// CHECK:STDOUT: !950 = !DILocalVariable(arg: 1, scope: !949, type: !7)
// CHECK:STDOUT: !951 = !DILocation(line: 12, column: 3, scope: !949)
// CHECK:STDOUT: !952 = !{!950}
// CHECK:STDOUT: !953 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b15b2f79ab5ce932:core.Destroy.Core", scope: null, file: !914, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !915, retainedNodes: !956)
// CHECK:STDOUT: !954 = !DILocalVariable(arg: 1, scope: !953, type: !7)
// CHECK:STDOUT: !955 = !DILocation(line: 12, column: 3, scope: !953)
// CHECK:STDOUT: !956 = !{!954}
// CHECK:STDOUT: !957 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.ab91bdd0280f46ae", scope: null, file: !914, line: 11, type: !98, spFlags: DISPFlagDefinition, unit: !915)
// CHECK:STDOUT: !960 = !DILocation(line: 12, column: 3, scope: !957)
// CHECK:STDOUT: !961 = !DILocation(line: 0, scope: !957)
// CHECK:STDOUT: !963 = !DILocation(line: 13, column: 10, scope: !957)
// CHECK:STDOUT: !964 = !DILocation(line: 13, column: 3, scope: !957)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'assign_nested_class_template_computed_argument.carbon'
// CHECK:STDOUT: source_filename = "assign_nested_class_template_computed_argument.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Outer.val.loc12_3.1 = internal constant { { i32 } } { { i32 } { i32 4 } }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !967 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call i32 @_CG.Main.ab91bdd0280f46ae(i32 6), !dbg !970
// CHECK:STDOUT:   ret i32 %G.call, !dbg !971
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !972 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !974
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a9280e8bea6fc5f9:core.Destroy.Core"(ptr %self) #0 !dbg !976 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12.a = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !978
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc12.a), !dbg !978
// CHECK:STDOUT:   ret void, !dbg !978
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a9280e8bea6fc5f9:core.Destroy.Core"(ptr %self) #0 !dbg !980 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a9280e8bea6fc5f9:core.Destroy.Core"(ptr %self), !dbg !982
// CHECK:STDOUT:   ret void, !dbg !982
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.53dac1980bfe8777:core.Destroy.Core"(ptr %self) #0 !dbg !984 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12.a = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !986
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc12.a), !dbg !986
// CHECK:STDOUT:   ret void, !dbg !986
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.53dac1980bfe8777:core.Destroy.Core"(ptr %self) #0 !dbg !988 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.53dac1980bfe8777:core.Destroy.Core"(ptr %self), !dbg !990
// CHECK:STDOUT:   ret void, !dbg !990
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a843c95eae9f9356:core.Destroy.Core"(ptr %self) #0 !dbg !992 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12.c = getelementptr inbounds nuw { { i32 } }, ptr %self, i32 0, i32 0, !dbg !994
// CHECK:STDOUT:   call void @"_CSelfDestruct.53dac1980bfe8777:core.Destroy.Core"(ptr %.loc12.c), !dbg !994
// CHECK:STDOUT:   ret void, !dbg !994
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a843c95eae9f9356:core.Destroy.Core"(ptr %self) #0 !dbg !996 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a843c95eae9f9356:core.Destroy.Core"(ptr %self), !dbg !998
// CHECK:STDOUT:   ret void, !dbg !998
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b15b2f79ab5ce932:core.Destroy.Core"(ptr %self) #0 !dbg !1000 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12.c = getelementptr inbounds nuw { { i32 } }, ptr %self, i32 0, i32 0, !dbg !1002
// CHECK:STDOUT:   call void @"_CSelfDestruct.53dac1980bfe8777:core.Destroy.Core"(ptr %.loc12.c), !dbg !1002
// CHECK:STDOUT:   ret void, !dbg !1002
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b15b2f79ab5ce932:core.Destroy.Core"(ptr %self) #0 !dbg !1004 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b15b2f79ab5ce932:core.Destroy.Core"(ptr %self), !dbg !1006
// CHECK:STDOUT:   ret void, !dbg !1006
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CG.Main.ab91bdd0280f46ae(i32 %x) #0 !dbg !1008 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %o.var = alloca { { i32 } }, align 4, !dbg !1013
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %o.var), !dbg !1013
// CHECK:STDOUT:   %.c69.c = getelementptr inbounds nuw { { i32 } }, ptr %o.var, i32 0, i32 0, !dbg !1014
// CHECK:STDOUT:   %.72e.a = getelementptr inbounds nuw { i32 }, ptr %.c69.c, i32 0, i32 0, !dbg !1014
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %o.var, ptr align 4 @Outer.val.loc12_3.1, i64 4, i1 false), !dbg !1013
// CHECK:STDOUT:   %.bc6aab.2.c = getelementptr inbounds nuw { { i32 } }, ptr %o.var, i32 0, i32 0, !dbg !1019
// CHECK:STDOUT:   %.55d.a = getelementptr inbounds nuw { i32 }, ptr %.bc6aab.2.c, i32 0, i32 0, !dbg !1018
// CHECK:STDOUT:   store i32 %x, ptr %.55d.a, align 4, !dbg !1018
// CHECK:STDOUT:   %.bc6aab.1.c = getelementptr inbounds nuw { { i32 } }, ptr %o.var, i32 0, i32 0, !dbg !1020
// CHECK:STDOUT:   %.c0b.a = getelementptr inbounds nuw { i32 }, ptr %.bc6aab.1.c, i32 0, i32 0, !dbg !1020
// CHECK:STDOUT:   %.43b = load i32, ptr %.c0b.a, align 4, !dbg !1020
// CHECK:STDOUT:   call void @"_CSelfDestruct.b15b2f79ab5ce932:core.Destroy.Core"(ptr %o.var), !dbg !1013
// CHECK:STDOUT:   ret i32 %.43b, !dbg !1021
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!966}
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
// CHECK:STDOUT: !965 = !DIFile(filename: "assign_nested_class_template_computed_argument.carbon", directory: "")
// CHECK:STDOUT: !966 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !965, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !967 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !965, line: 17, type: !98, spFlags: DISPFlagDefinition, unit: !966)
// CHECK:STDOUT: !970 = !DILocation(line: 18, column: 10, scope: !967)
// CHECK:STDOUT: !971 = !DILocation(line: 18, column: 3, scope: !967)
// CHECK:STDOUT: !972 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !965, line: 12, type: !299, spFlags: DISPFlagDefinition, unit: !966, retainedNodes: !975)
// CHECK:STDOUT: !973 = !DILocalVariable(arg: 1, scope: !972, type: !6)
// CHECK:STDOUT: !974 = !DILocation(line: 12, column: 3, scope: !972)
// CHECK:STDOUT: !975 = !{!973}
// CHECK:STDOUT: !976 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a9280e8bea6fc5f9:core.Destroy.Core", scope: null, file: !965, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !966, retainedNodes: !979)
// CHECK:STDOUT: !977 = !DILocalVariable(arg: 1, scope: !976, type: !7)
// CHECK:STDOUT: !978 = !DILocation(line: 12, column: 3, scope: !976)
// CHECK:STDOUT: !979 = !{!977}
// CHECK:STDOUT: !980 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a9280e8bea6fc5f9:core.Destroy.Core", scope: null, file: !965, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !966, retainedNodes: !983)
// CHECK:STDOUT: !981 = !DILocalVariable(arg: 1, scope: !980, type: !7)
// CHECK:STDOUT: !982 = !DILocation(line: 12, column: 3, scope: !980)
// CHECK:STDOUT: !983 = !{!981}
// CHECK:STDOUT: !984 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.53dac1980bfe8777:core.Destroy.Core", scope: null, file: !965, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !966, retainedNodes: !987)
// CHECK:STDOUT: !985 = !DILocalVariable(arg: 1, scope: !984, type: !7)
// CHECK:STDOUT: !986 = !DILocation(line: 12, column: 3, scope: !984)
// CHECK:STDOUT: !987 = !{!985}
// CHECK:STDOUT: !988 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.53dac1980bfe8777:core.Destroy.Core", scope: null, file: !965, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !966, retainedNodes: !991)
// CHECK:STDOUT: !989 = !DILocalVariable(arg: 1, scope: !988, type: !7)
// CHECK:STDOUT: !990 = !DILocation(line: 12, column: 3, scope: !988)
// CHECK:STDOUT: !991 = !{!989}
// CHECK:STDOUT: !992 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a843c95eae9f9356:core.Destroy.Core", scope: null, file: !965, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !966, retainedNodes: !995)
// CHECK:STDOUT: !993 = !DILocalVariable(arg: 1, scope: !992, type: !7)
// CHECK:STDOUT: !994 = !DILocation(line: 12, column: 3, scope: !992)
// CHECK:STDOUT: !995 = !{!993}
// CHECK:STDOUT: !996 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a843c95eae9f9356:core.Destroy.Core", scope: null, file: !965, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !966, retainedNodes: !999)
// CHECK:STDOUT: !997 = !DILocalVariable(arg: 1, scope: !996, type: !7)
// CHECK:STDOUT: !998 = !DILocation(line: 12, column: 3, scope: !996)
// CHECK:STDOUT: !999 = !{!997}
// CHECK:STDOUT: !1000 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b15b2f79ab5ce932:core.Destroy.Core", scope: null, file: !965, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !966, retainedNodes: !1003)
// CHECK:STDOUT: !1001 = !DILocalVariable(arg: 1, scope: !1000, type: !7)
// CHECK:STDOUT: !1002 = !DILocation(line: 12, column: 3, scope: !1000)
// CHECK:STDOUT: !1003 = !{!1001}
// CHECK:STDOUT: !1004 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b15b2f79ab5ce932:core.Destroy.Core", scope: null, file: !965, line: 12, type: !174, spFlags: DISPFlagDefinition, unit: !966, retainedNodes: !1007)
// CHECK:STDOUT: !1005 = !DILocalVariable(arg: 1, scope: !1004, type: !7)
// CHECK:STDOUT: !1006 = !DILocation(line: 12, column: 3, scope: !1004)
// CHECK:STDOUT: !1007 = !{!1005}
// CHECK:STDOUT: !1008 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.ab91bdd0280f46ae", scope: null, file: !965, line: 11, type: !104, spFlags: DISPFlagDefinition, unit: !966, retainedNodes: !1022)
// CHECK:STDOUT: !1009 = !DILocalVariable(arg: 1, scope: !1008, type: !6)
// CHECK:STDOUT: !1013 = !DILocation(line: 12, column: 3, scope: !1008)
// CHECK:STDOUT: !1014 = !DILocation(line: 0, scope: !1008)
// CHECK:STDOUT: !1018 = !DILocation(line: 13, column: 13, scope: !1008)
// CHECK:STDOUT: !1019 = !DILocation(line: 13, column: 7, scope: !1008)
// CHECK:STDOUT: !1020 = !DILocation(line: 14, column: 10, scope: !1008)
// CHECK:STDOUT: !1021 = !DILocation(line: 14, column: 3, scope: !1008)
// CHECK:STDOUT: !1022 = !{!1009}
// CHECK:STDOUT:

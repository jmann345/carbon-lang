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

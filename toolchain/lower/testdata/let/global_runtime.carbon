// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/let/global_runtime.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/let/global_runtime.carbon

// File-scope `let` bindings bound to RUNTIME values (W-069 half (a)): the
// bound value's copy-of-object-representation (scalar) value is promoted to a
// named backing global — `_C<name>.<package>` — that `__global_init` stores
// once, mirroring how `var` exports `VarStorage` globals
// (lower/testdata/var/import.carbon). Same-file cross-function references and
// importing files both load from that one symbol. The slice's PR-diff audit
// obligation: every OTHER existing `let` golden stays byte-identical —
// constant-bound `let`s keep riding the constant path, never these globals.

// --- scalar.carbon

library "[[@TEST_NAME]]";

fn Seed() -> i32 { return 42; }

let x: i32 = Seed();

fn Use() -> i32 { return x; }

// --- import_scalar.carbon

library "[[@TEST_NAME]]";

import library "scalar";

fn UseImported() -> i32 { return x; }

// --- reexport.carbon

library "[[@TEST_NAME]]";

export import library "scalar";

// --- import_reexport.carbon

library "[[@TEST_NAME]]";

import library "reexport";

// A defines the runtime `let`, B re-exports it, this file imports B: the
// canonical resolution (SemIR::GetCanonicalFileAndInstId) must land on A's
// defining binding — ONE `_Cx.Main` symbol across the whole chain, never a
// symbol mangled against B's IR.
fn UseReexported() -> i32 { return x; }

// --- tuple_pattern.carbon

library "[[@TEST_NAME]]";

fn MakePair() -> (i32, i32) { return (1, 2); }

// Both bindings are promoted independently (per-binding globals), fed from
// one tuple temporary in `__global_init`.
let (a: i32, b: i32) = MakePair();

fn UseA() -> i32 { return a; }

// --- import_tuple_pattern.carbon

library "[[@TEST_NAME]]";

import library "tuple_pattern";

fn UseB() -> i32 { return b; }

// --- empty.carbon

library "[[@TEST_NAME]]";

fn MakeEmpty() -> () { return (); }

// Empty value representation: NO `_Ce` global may appear. The bound value is
// concrete at check time, so references ride the constant path (W69a fill).
let e: () = MakeEmpty();

fn UseE() -> () { return e; }

// --- let_ref.carbon

library "[[@TEST_NAME]]";

var v: i32 = 1;

// A `let ref` is a reference-category binding: excluded from promotion — no
// `_Cr` global may appear; the reference rides the variable's own storage.
let ref r: i32 = v;

fn UseR() -> i32 { return r; }

// --- export_name.carbon

library "[[@TEST_NAME]]";

import library "scalar";

// B exports A's runtime `let` BY NAME (`export x;`, not `export import`):
// the W-074 shape, checkable since the W74a import_ref.cpp fix (see
// check/testdata/let/export_runtime.carbon). This subfile's own module
// carries no `_Cx` symbol — the export mints no storage.
export x;

// --- import_export_name.carbon

library "[[@TEST_NAME]]";

import library "export_name";

// Main imports B and reads `x` through B's `ExportDecl`: the canonical
// resolution (SemIR::GetCanonicalFileAndInstId's ExportDecl arm, reached
// via TryEmitGlobalLetValue — implemented at W69a, first pinned here) must
// land on A's defining binding — ONE `_Cx.Main` external symbol, the same
// name the defining file owns, never a symbol mangled against B's IR.
fn UseExportName() -> i32 { return x; }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'scalar.carbon'
// CHECK:STDOUT: source_filename = "scalar.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Cx.Main = global i32 0
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CSeed.Main() #0 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 42, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.ref = load i32, ptr @_Cx.Main, align 4, !dbg !30
// CHECK:STDOUT:   ret i32 %x.ref, !dbg !31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Seed.call = call i32 @_CSeed.Main(), !dbg !35
// CHECK:STDOUT:   store i32 %Seed.call, ptr @_Cx.Main, align 4
// CHECK:STDOUT:   ret void, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!19}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !18 = !DIFile(filename: "scalar.carbon", directory: "")
// CHECK:STDOUT: !19 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !18, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "Seed", linkageName: "_CSeed.Main", scope: null, file: !18, line: 4, type: !22, spFlags: DISPFlagDefinition, unit: !19)
// CHECK:STDOUT: !26 = !DILocation(line: 4, column: 20, scope: !23)
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !18, line: 8, type: !22, spFlags: DISPFlagDefinition, unit: !19)
// CHECK:STDOUT: !30 = !DILocation(line: 8, column: 26, scope: !27)
// CHECK:STDOUT: !31 = !DILocation(line: 8, column: 19, scope: !27)
// CHECK:STDOUT: !32 = !{null}
// CHECK:STDOUT: !33 = !DISubroutineType(types: !32)
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !18, type: !33, spFlags: DISPFlagDefinition, unit: !19)
// CHECK:STDOUT: !35 = !DILocation(line: 6, column: 14, scope: !34)
// CHECK:STDOUT: !36 = !DILocation(line: 0, scope: !34)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_scalar.carbon'
// CHECK:STDOUT: source_filename = "import_scalar.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Cx.Main = external global i32
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseImported.Main() #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.ref = load i32, ptr @_Cx.Main, align 4, !dbg !42
// CHECK:STDOUT:   ret i32 %x.ref, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CSeed.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CUse.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!38}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !37 = !DIFile(filename: "import_scalar.carbon", directory: "")
// CHECK:STDOUT: !38 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !37, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "UseImported", linkageName: "_CUseImported.Main", scope: null, file: !37, line: 6, type: !22, spFlags: DISPFlagDefinition, unit: !38)
// CHECK:STDOUT: !42 = !DILocation(line: 6, column: 34, scope: !39)
// CHECK:STDOUT: !43 = !DILocation(line: 6, column: 27, scope: !39)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'reexport.carbon'
// CHECK:STDOUT: source_filename = "reexport.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!45}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !44 = !DIFile(filename: "reexport.carbon", directory: "")
// CHECK:STDOUT: !45 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !44, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_reexport.carbon'
// CHECK:STDOUT: source_filename = "import_reexport.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Cx.Main = external global i32
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseReexported.Main() #0 !dbg !48 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.ref = load i32, ptr @_Cx.Main, align 4, !dbg !51
// CHECK:STDOUT:   ret i32 %x.ref, !dbg !52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CSeed.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CUse.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!47}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !46 = !DIFile(filename: "import_reexport.carbon", directory: "")
// CHECK:STDOUT: !47 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !46, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "UseReexported", linkageName: "_CUseReexported.Main", scope: null, file: !46, line: 10, type: !22, spFlags: DISPFlagDefinition, unit: !47)
// CHECK:STDOUT: !51 = !DILocation(line: 10, column: 36, scope: !48)
// CHECK:STDOUT: !52 = !DILocation(line: 10, column: 29, scope: !48)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'tuple_pattern.carbon'
// CHECK:STDOUT: source_filename = "tuple_pattern.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Ca.Main = global i32 0
// CHECK:STDOUT: @_Cb.Main = global i32 0
// CHECK:STDOUT: @tuple.102.loc4_44 = internal constant { i32, i32 } { i32 1, i32 2 }
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakePair.Main(ptr sret({ i32, i32 }) %return) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !61
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !61
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @tuple.102.loc4_44, i64 8, i1 false), !dbg !62
// CHECK:STDOUT:   ret void, !dbg !62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseA.Main() #0 !dbg !63 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.ref = load i32, ptr @_Ca.Main, align 4, !dbg !66
// CHECK:STDOUT:   ret i32 %a.ref, !dbg !67
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !68 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8.temp = alloca { i32, i32 }, align 4, !dbg !69
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc8.temp), !dbg !69
// CHECK:STDOUT:   call void @_CMakePair.Main(ptr %.loc8.temp), !dbg !69
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc8.temp, i32 0, i32 0, !dbg !69
// CHECK:STDOUT:   %.loc8_33.2 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !69
// CHECK:STDOUT:   store i32 %.loc8_33.2, ptr @_Ca.Main, align 4
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc8.temp, i32 0, i32 1, !dbg !69
// CHECK:STDOUT:   %.loc8_33.3 = load i32, ptr %tuple.elem1.tuple.elem, align 4, !dbg !69
// CHECK:STDOUT:   store i32 %.loc8_33.3, ptr @_Cb.Main, align 4
// CHECK:STDOUT:   ret void, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!54}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !32 = !{null}
// CHECK:STDOUT: !33 = !DISubroutineType(types: !32)
// CHECK:STDOUT: !53 = !DIFile(filename: "tuple_pattern.carbon", directory: "")
// CHECK:STDOUT: !54 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !53, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !55 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !56 = !{!55}
// CHECK:STDOUT: !57 = !DISubroutineType(types: !56)
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "MakePair", linkageName: "_CMakePair.Main", scope: null, file: !53, line: 4, type: !57, spFlags: DISPFlagDefinition, unit: !54)
// CHECK:STDOUT: !61 = !DILocation(line: 4, column: 38, scope: !58)
// CHECK:STDOUT: !62 = !DILocation(line: 4, column: 31, scope: !58)
// CHECK:STDOUT: !63 = distinct !DISubprogram(name: "UseA", linkageName: "_CUseA.Main", scope: null, file: !53, line: 10, type: !22, spFlags: DISPFlagDefinition, unit: !54)
// CHECK:STDOUT: !66 = !DILocation(line: 10, column: 27, scope: !63)
// CHECK:STDOUT: !67 = !DILocation(line: 10, column: 20, scope: !63)
// CHECK:STDOUT: !68 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !53, type: !33, spFlags: DISPFlagDefinition, unit: !54)
// CHECK:STDOUT: !69 = !DILocation(line: 8, column: 24, scope: !68)
// CHECK:STDOUT: !70 = !DILocation(line: 0, scope: !68)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_tuple_pattern.carbon'
// CHECK:STDOUT: source_filename = "import_tuple_pattern.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Cb.Main = external global i32
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseB.Main() #0 !dbg !73 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %b.ref = load i32, ptr @_Cb.Main, align 4, !dbg !76
// CHECK:STDOUT:   ret i32 %b.ref, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CMakePair.Main(ptr sret({ i32, i32 }))
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CUseA.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!72}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !71 = !DIFile(filename: "import_tuple_pattern.carbon", directory: "")
// CHECK:STDOUT: !72 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !71, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !73 = distinct !DISubprogram(name: "UseB", linkageName: "_CUseB.Main", scope: null, file: !71, line: 6, type: !22, spFlags: DISPFlagDefinition, unit: !72)
// CHECK:STDOUT: !76 = !DILocation(line: 6, column: 27, scope: !73)
// CHECK:STDOUT: !77 = !DILocation(line: 6, column: 20, scope: !73)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'empty.carbon'
// CHECK:STDOUT: source_filename = "empty.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeEmpty.Main() #0 !dbg !80 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !83
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUseE.Main() #0 !dbg !84 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !88
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !89 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CMakeEmpty.Main(), !dbg !90
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!79}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !32 = !{null}
// CHECK:STDOUT: !33 = !DISubroutineType(types: !32)
// CHECK:STDOUT: !78 = !DIFile(filename: "empty.carbon", directory: "")
// CHECK:STDOUT: !79 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !78, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !80 = distinct !DISubprogram(name: "MakeEmpty", linkageName: "_CMakeEmpty.Main", scope: null, file: !78, line: 4, type: !33, spFlags: DISPFlagDefinition, unit: !79)
// CHECK:STDOUT: !83 = !DILocation(line: 4, column: 24, scope: !80)
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "UseE", linkageName: "_CUseE.Main", scope: null, file: !78, line: 10, type: !33, spFlags: DISPFlagDefinition, unit: !79)
// CHECK:STDOUT: !88 = !DILocation(line: 10, column: 19, scope: !84)
// CHECK:STDOUT: !89 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !78, type: !33, spFlags: DISPFlagDefinition, unit: !79)
// CHECK:STDOUT: !90 = !DILocation(line: 8, column: 13, scope: !89)
// CHECK:STDOUT: !91 = !DILocation(line: 0, scope: !89)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'let_ref.carbon'
// CHECK:STDOUT: source_filename = "let_ref.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Cv.Main = global i32 0
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseR.Main() #0 !dbg !94 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_27 = load i32, ptr @_Cv.Main, align 4, !dbg !97
// CHECK:STDOUT:   ret i32 %.loc10_27, !dbg !98
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !99 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   store i32 1, ptr @_Cv.Main, align 4, !dbg !100
// CHECK:STDOUT:   ret void, !dbg !101
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!93}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !32 = !{null}
// CHECK:STDOUT: !33 = !DISubroutineType(types: !32)
// CHECK:STDOUT: !92 = !DIFile(filename: "let_ref.carbon", directory: "")
// CHECK:STDOUT: !93 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !92, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !94 = distinct !DISubprogram(name: "UseR", linkageName: "_CUseR.Main", scope: null, file: !92, line: 10, type: !22, spFlags: DISPFlagDefinition, unit: !93)
// CHECK:STDOUT: !97 = !DILocation(line: 10, column: 27, scope: !94)
// CHECK:STDOUT: !98 = !DILocation(line: 10, column: 20, scope: !94)
// CHECK:STDOUT: !99 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !92, type: !33, spFlags: DISPFlagDefinition, unit: !93)
// CHECK:STDOUT: !100 = !DILocation(line: 4, column: 1, scope: !99)
// CHECK:STDOUT: !101 = !DILocation(line: 0, scope: !99)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'export_name.carbon'
// CHECK:STDOUT: source_filename = "export_name.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!103}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !102 = !DIFile(filename: "export_name.carbon", directory: "")
// CHECK:STDOUT: !103 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !102, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_export_name.carbon'
// CHECK:STDOUT: source_filename = "import_export_name.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Cx.Main = external global i32
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseExportName.Main() #0 !dbg !106 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.ref = load i32, ptr @_Cx.Main, align 4, !dbg !109
// CHECK:STDOUT:   ret i32 %x.ref, !dbg !110
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CSeed.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CUse.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!105}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !104 = !DIFile(filename: "import_export_name.carbon", directory: "")
// CHECK:STDOUT: !105 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !104, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !106 = distinct !DISubprogram(name: "UseExportName", linkageName: "_CUseExportName.Main", scope: null, file: !104, line: 11, type: !22, spFlags: DISPFlagDefinition, unit: !105)
// CHECK:STDOUT: !109 = !DILocation(line: 11, column: 36, scope: !106)
// CHECK:STDOUT: !110 = !DILocation(line: 11, column: 29, scope: !106)
// CHECK:STDOUT:

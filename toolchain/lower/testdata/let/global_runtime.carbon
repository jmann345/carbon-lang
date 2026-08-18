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
// CHECK:STDOUT: define i32 @_CSeed.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 42, !dbg !8
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !9 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.ref = load i32, ptr @_Cx.Main, align 4, !dbg !10
// CHECK:STDOUT:   ret i32 %x.ref, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Seed.call = call i32 @_CSeed.Main(), !dbg !15
// CHECK:STDOUT:   store i32 %Seed.call, ptr @_Cx.Main, align 4
// CHECK:STDOUT:   ret void, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "scalar.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Seed", linkageName: "_CSeed.Main", scope: null, file: !1, line: 4, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 4, column: 20, scope: !4)
// CHECK:STDOUT: !9 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 8, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !10 = !DILocation(line: 8, column: 26, scope: !9)
// CHECK:STDOUT: !11 = !DILocation(line: 8, column: 19, scope: !9)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !1, type: !13, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{null}
// CHECK:STDOUT: !15 = !DILocation(line: 6, column: 14, scope: !12)
// CHECK:STDOUT: !16 = !DILocation(line: 0, scope: !12)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_scalar.carbon'
// CHECK:STDOUT: source_filename = "import_scalar.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Cx.Main = external global i32
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseImported.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.ref = load i32, ptr @_Cx.Main, align 4, !dbg !8
// CHECK:STDOUT:   ret i32 %x.ref, !dbg !9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CSeed.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CUse.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "import_scalar.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "UseImported", linkageName: "_CUseImported.Main", scope: null, file: !1, line: 6, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 6, column: 34, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 6, column: 27, scope: !4)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'reexport.carbon'
// CHECK:STDOUT: source_filename = "reexport.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "reexport.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_reexport.carbon'
// CHECK:STDOUT: source_filename = "import_reexport.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Cx.Main = external global i32
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseReexported.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.ref = load i32, ptr @_Cx.Main, align 4, !dbg !8
// CHECK:STDOUT:   ret i32 %x.ref, !dbg !9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CSeed.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CUse.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "import_reexport.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "UseReexported", linkageName: "_CUseReexported.Main", scope: null, file: !1, line: 10, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 10, column: 36, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 10, column: 29, scope: !4)
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
// CHECK:STDOUT: define void @_CMakePair.Main(ptr sret({ i32, i32 }) %return) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !8
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !8
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @tuple.102.loc4_44, i64 8, i1 false), !dbg !9
// CHECK:STDOUT:   ret void, !dbg !9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseA.Main() #0 !dbg !10 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.ref = load i32, ptr @_Ca.Main, align 4, !dbg !14
// CHECK:STDOUT:   ret i32 %a.ref, !dbg !15
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !16 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8.temp = alloca { i32, i32 }, align 4, !dbg !19
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc8.temp), !dbg !19
// CHECK:STDOUT:   call void @_CMakePair.Main(ptr %.loc8.temp), !dbg !19
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc8.temp, i32 0, i32 0, !dbg !19
// CHECK:STDOUT:   %.loc8_33.2 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !19
// CHECK:STDOUT:   store i32 %.loc8_33.2, ptr @_Ca.Main, align 4
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc8.temp, i32 0, i32 1, !dbg !19
// CHECK:STDOUT:   %.loc8_33.3 = load i32, ptr %tuple.elem1.tuple.elem, align 4, !dbg !19
// CHECK:STDOUT:   store i32 %.loc8_33.3, ptr @_Cb.Main, align 4
// CHECK:STDOUT:   ret void, !dbg !20
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "tuple_pattern.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "MakePair", linkageName: "_CMakePair.Main", scope: null, file: !1, line: 4, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !DILocation(line: 4, column: 38, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 4, column: 31, scope: !4)
// CHECK:STDOUT: !10 = distinct !DISubprogram(name: "UseA", linkageName: "_CUseA.Main", scope: null, file: !1, line: 10, type: !11, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !11 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !12 = !{!13}
// CHECK:STDOUT: !13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !14 = !DILocation(line: 10, column: 27, scope: !10)
// CHECK:STDOUT: !15 = !DILocation(line: 10, column: 20, scope: !10)
// CHECK:STDOUT: !16 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !1, type: !17, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !17 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !18 = !{null}
// CHECK:STDOUT: !19 = !DILocation(line: 8, column: 24, scope: !16)
// CHECK:STDOUT: !20 = !DILocation(line: 0, scope: !16)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_tuple_pattern.carbon'
// CHECK:STDOUT: source_filename = "import_tuple_pattern.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Cb.Main = external global i32
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseB.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %b.ref = load i32, ptr @_Cb.Main, align 4, !dbg !8
// CHECK:STDOUT:   ret i32 %b.ref, !dbg !9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CMakePair.Main(ptr sret({ i32, i32 }))
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CUseA.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "import_tuple_pattern.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "UseB", linkageName: "_CUseB.Main", scope: null, file: !1, line: 6, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 6, column: 27, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 6, column: 20, scope: !4)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'empty.carbon'
// CHECK:STDOUT: source_filename = "empty.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeEmpty.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !7
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUseE.Main() #0 !dbg !8 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !10 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CMakeEmpty.Main(), !dbg !11
// CHECK:STDOUT:   ret void, !dbg !12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "empty.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "MakeEmpty", linkageName: "_CMakeEmpty.Main", scope: null, file: !1, line: 4, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{null}
// CHECK:STDOUT: !7 = !DILocation(line: 4, column: 24, scope: !4)
// CHECK:STDOUT: !8 = distinct !DISubprogram(name: "UseE", linkageName: "_CUseE.Main", scope: null, file: !1, line: 10, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !9 = !DILocation(line: 10, column: 19, scope: !8)
// CHECK:STDOUT: !10 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !1, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !11 = !DILocation(line: 8, column: 13, scope: !10)
// CHECK:STDOUT: !12 = !DILocation(line: 0, scope: !10)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'let_ref.carbon'
// CHECK:STDOUT: source_filename = "let_ref.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Cv.Main = global i32 0
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseR.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_27 = load i32, ptr @_Cv.Main, align 4, !dbg !8
// CHECK:STDOUT:   ret i32 %.loc10_27, !dbg !9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !10 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   store i32 1, ptr @_Cv.Main, align 4, !dbg !13
// CHECK:STDOUT:   ret void, !dbg !14
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "let_ref.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "UseR", linkageName: "_CUseR.Main", scope: null, file: !1, line: 10, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 10, column: 27, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 10, column: 20, scope: !4)
// CHECK:STDOUT: !10 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !1, type: !11, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !11 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !12 = !{null}
// CHECK:STDOUT: !13 = !DILocation(line: 4, column: 1, scope: !10)
// CHECK:STDOUT: !14 = !DILocation(line: 0, scope: !10)
// CHECK:STDOUT:

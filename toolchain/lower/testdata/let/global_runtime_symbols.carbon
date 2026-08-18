// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/let/global_runtime_symbols.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/let/global_runtime_symbols.carbon

// Symbol-identity falsifier for promoted file-scope runtime `let` bindings
// (W-069 risk R-1, the F8c `.N`-rename lesson): one defining file whose
// global is reached repeatedly (definition pass plus two same-file uses), two
// importing files, and a private-to-library binding taking the fingerprint
// suffix. Any `.N`-suffixed `_C...` symbol in the regenerated golden means a
// get-before-create miss silently split the initializing store from the
// loads — the same failure mode as the `_Ctotal.Main.2` incident this file
// is named after.

// --- def.carbon

library "[[@TEST_NAME]]";

fn Seed() -> i32 { return 7; }

let total: i32 = Seed();

// Two same-file readers: both loads and the ctor store must name one
// `_Ctotal.Main` global.
fn First() -> i32 { return total; }

fn Second() -> i32 { return total; }

// --- import_one.carbon

library "[[@TEST_NAME]]";

import library "def";

fn ImportedOnceA() -> i32 { return total; }

fn ImportedOnceB() -> i32 { return total; }

// --- import_two.carbon

library "[[@TEST_NAME]]";

import library "def";

fn ImportedTwice() -> i32 { return total; }

// --- private.carbon

library "[[@TEST_NAME]]";

fn PrivateSeed() -> i32 { return 9; }

// Private to this library: the mangled name takes the fingerprint suffix,
// exactly as `Mangler::MangleGlobalVariable` fingerprints private `var`s.
private let hidden: i32 = PrivateSeed();

fn UseHidden() -> i32 { return hidden; }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'def.carbon'
// CHECK:STDOUT: source_filename = "def.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Ctotal.Main = global i32 0
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CSeed.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 7, !dbg !8
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CFirst.Main() #0 !dbg !9 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.ref = load i32, ptr @_Ctotal.Main, align 4, !dbg !10
// CHECK:STDOUT:   ret i32 %total.ref, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CSecond.Main() #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.ref = load i32, ptr @_Ctotal.Main, align 4, !dbg !13
// CHECK:STDOUT:   ret i32 %total.ref, !dbg !14
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !15 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Seed.call = call i32 @_CSeed.Main(), !dbg !18
// CHECK:STDOUT:   store i32 %Seed.call, ptr @_Ctotal.Main, align 4
// CHECK:STDOUT:   ret void, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "def.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Seed", linkageName: "_CSeed.Main", scope: null, file: !1, line: 4, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 4, column: 20, scope: !4)
// CHECK:STDOUT: !9 = distinct !DISubprogram(name: "First", linkageName: "_CFirst.Main", scope: null, file: !1, line: 10, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !10 = !DILocation(line: 10, column: 28, scope: !9)
// CHECK:STDOUT: !11 = !DILocation(line: 10, column: 21, scope: !9)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "Second", linkageName: "_CSecond.Main", scope: null, file: !1, line: 12, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !13 = !DILocation(line: 12, column: 29, scope: !12)
// CHECK:STDOUT: !14 = !DILocation(line: 12, column: 22, scope: !12)
// CHECK:STDOUT: !15 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !1, type: !16, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !16 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !17 = !{null}
// CHECK:STDOUT: !18 = !DILocation(line: 6, column: 18, scope: !15)
// CHECK:STDOUT: !19 = !DILocation(line: 0, scope: !15)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_one.carbon'
// CHECK:STDOUT: source_filename = "import_one.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Ctotal.Main = external global i32
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CImportedOnceA.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.ref = load i32, ptr @_Ctotal.Main, align 4, !dbg !8
// CHECK:STDOUT:   ret i32 %total.ref, !dbg !9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CImportedOnceB.Main() #0 !dbg !10 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.ref = load i32, ptr @_Ctotal.Main, align 4, !dbg !11
// CHECK:STDOUT:   ret i32 %total.ref, !dbg !12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CSeed.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CFirst.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CSecond.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "import_one.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "ImportedOnceA", linkageName: "_CImportedOnceA.Main", scope: null, file: !1, line: 6, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 6, column: 36, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 6, column: 29, scope: !4)
// CHECK:STDOUT: !10 = distinct !DISubprogram(name: "ImportedOnceB", linkageName: "_CImportedOnceB.Main", scope: null, file: !1, line: 8, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !11 = !DILocation(line: 8, column: 36, scope: !10)
// CHECK:STDOUT: !12 = !DILocation(line: 8, column: 29, scope: !10)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_two.carbon'
// CHECK:STDOUT: source_filename = "import_two.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Ctotal.Main = external global i32
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CImportedTwice.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.ref = load i32, ptr @_Ctotal.Main, align 4, !dbg !8
// CHECK:STDOUT:   ret i32 %total.ref, !dbg !9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CSeed.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CFirst.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CSecond.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "import_two.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "ImportedTwice", linkageName: "_CImportedTwice.Main", scope: null, file: !1, line: 6, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 6, column: 36, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 6, column: 29, scope: !4)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'private.carbon'
// CHECK:STDOUT: source_filename = "private.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Chidden.Main.b2b5bfc054bc42f8 = global i32 0
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CPrivateSeed.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 9, !dbg !8
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseHidden.Main() #0 !dbg !9 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %hidden.ref = load i32, ptr @_Chidden.Main.b2b5bfc054bc42f8, align 4, !dbg !10
// CHECK:STDOUT:   ret i32 %hidden.ref, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %PrivateSeed.call = call i32 @_CPrivateSeed.Main(), !dbg !15
// CHECK:STDOUT:   store i32 %PrivateSeed.call, ptr @_Chidden.Main.b2b5bfc054bc42f8, align 4
// CHECK:STDOUT:   ret void, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "private.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "PrivateSeed", linkageName: "_CPrivateSeed.Main", scope: null, file: !1, line: 4, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 4, column: 27, scope: !4)
// CHECK:STDOUT: !9 = distinct !DISubprogram(name: "UseHidden", linkageName: "_CUseHidden.Main", scope: null, file: !1, line: 10, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !10 = !DILocation(line: 10, column: 32, scope: !9)
// CHECK:STDOUT: !11 = !DILocation(line: 10, column: 25, scope: !9)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !1, type: !13, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{null}
// CHECK:STDOUT: !15 = !DILocation(line: 8, column: 27, scope: !12)
// CHECK:STDOUT: !16 = !DILocation(line: 0, scope: !12)
// CHECK:STDOUT:

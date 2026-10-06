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
// CHECK:STDOUT: define i32 @_CSeed.Main() #0 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 7, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CFirst.Main() #0 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.ref = load i32, ptr @_Ctotal.Main, align 4, !dbg !30
// CHECK:STDOUT:   ret i32 %total.ref, !dbg !31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CSecond.Main() #0 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.ref = load i32, ptr @_Ctotal.Main, align 4, !dbg !35
// CHECK:STDOUT:   ret i32 %total.ref, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Seed.call = call i32 @_CSeed.Main(), !dbg !40
// CHECK:STDOUT:   store i32 %Seed.call, ptr @_Ctotal.Main, align 4
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!19}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !18 = !DIFile(filename: "def.carbon", directory: "")
// CHECK:STDOUT: !19 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !18, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "Seed", linkageName: "_CSeed.Main", scope: null, file: !18, line: 4, type: !22, spFlags: DISPFlagDefinition, unit: !19)
// CHECK:STDOUT: !26 = !DILocation(line: 4, column: 20, scope: !23)
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "First", linkageName: "_CFirst.Main", scope: null, file: !18, line: 10, type: !22, spFlags: DISPFlagDefinition, unit: !19)
// CHECK:STDOUT: !30 = !DILocation(line: 10, column: 28, scope: !27)
// CHECK:STDOUT: !31 = !DILocation(line: 10, column: 21, scope: !27)
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "Second", linkageName: "_CSecond.Main", scope: null, file: !18, line: 12, type: !22, spFlags: DISPFlagDefinition, unit: !19)
// CHECK:STDOUT: !35 = !DILocation(line: 12, column: 29, scope: !32)
// CHECK:STDOUT: !36 = !DILocation(line: 12, column: 22, scope: !32)
// CHECK:STDOUT: !37 = !{null}
// CHECK:STDOUT: !38 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !18, type: !38, spFlags: DISPFlagDefinition, unit: !19)
// CHECK:STDOUT: !40 = !DILocation(line: 6, column: 18, scope: !39)
// CHECK:STDOUT: !41 = !DILocation(line: 0, scope: !39)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_one.carbon'
// CHECK:STDOUT: source_filename = "import_one.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Ctotal.Main = external global i32
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CImportedOnceA.Main() #0 !dbg !44 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.ref = load i32, ptr @_Ctotal.Main, align 4, !dbg !47
// CHECK:STDOUT:   ret i32 %total.ref, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CImportedOnceB.Main() #0 !dbg !49 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.ref = load i32, ptr @_Ctotal.Main, align 4, !dbg !52
// CHECK:STDOUT:   ret i32 %total.ref, !dbg !53
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!43}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !42 = !DIFile(filename: "import_one.carbon", directory: "")
// CHECK:STDOUT: !43 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !42, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !44 = distinct !DISubprogram(name: "ImportedOnceA", linkageName: "_CImportedOnceA.Main", scope: null, file: !42, line: 6, type: !22, spFlags: DISPFlagDefinition, unit: !43)
// CHECK:STDOUT: !47 = !DILocation(line: 6, column: 36, scope: !44)
// CHECK:STDOUT: !48 = !DILocation(line: 6, column: 29, scope: !44)
// CHECK:STDOUT: !49 = distinct !DISubprogram(name: "ImportedOnceB", linkageName: "_CImportedOnceB.Main", scope: null, file: !42, line: 8, type: !22, spFlags: DISPFlagDefinition, unit: !43)
// CHECK:STDOUT: !52 = !DILocation(line: 8, column: 36, scope: !49)
// CHECK:STDOUT: !53 = !DILocation(line: 8, column: 29, scope: !49)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_two.carbon'
// CHECK:STDOUT: source_filename = "import_two.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Ctotal.Main = external global i32
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CImportedTwice.Main() #0 !dbg !56 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.ref = load i32, ptr @_Ctotal.Main, align 4, !dbg !59
// CHECK:STDOUT:   ret i32 %total.ref, !dbg !60
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!55}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !54 = !DIFile(filename: "import_two.carbon", directory: "")
// CHECK:STDOUT: !55 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !54, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "ImportedTwice", linkageName: "_CImportedTwice.Main", scope: null, file: !54, line: 6, type: !22, spFlags: DISPFlagDefinition, unit: !55)
// CHECK:STDOUT: !59 = !DILocation(line: 6, column: 36, scope: !56)
// CHECK:STDOUT: !60 = !DILocation(line: 6, column: 29, scope: !56)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'private.carbon'
// CHECK:STDOUT: source_filename = "private.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Chidden.Main.b2b5bfc054bc42f8 = global i32 0
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CPrivateSeed.Main() #0 !dbg !63 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 9, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseHidden.Main() #0 !dbg !67 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %hidden.ref = load i32, ptr @_Chidden.Main.b2b5bfc054bc42f8, align 4, !dbg !70
// CHECK:STDOUT:   ret i32 %hidden.ref, !dbg !71
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %PrivateSeed.call = call i32 @_CPrivateSeed.Main(), !dbg !73
// CHECK:STDOUT:   store i32 %PrivateSeed.call, ptr @_Chidden.Main.b2b5bfc054bc42f8, align 4
// CHECK:STDOUT:   ret void, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!62}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !37 = !{null}
// CHECK:STDOUT: !38 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !61 = !DIFile(filename: "private.carbon", directory: "")
// CHECK:STDOUT: !62 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !61, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !63 = distinct !DISubprogram(name: "PrivateSeed", linkageName: "_CPrivateSeed.Main", scope: null, file: !61, line: 4, type: !22, spFlags: DISPFlagDefinition, unit: !62)
// CHECK:STDOUT: !66 = !DILocation(line: 4, column: 27, scope: !63)
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "UseHidden", linkageName: "_CUseHidden.Main", scope: null, file: !61, line: 10, type: !22, spFlags: DISPFlagDefinition, unit: !62)
// CHECK:STDOUT: !70 = !DILocation(line: 10, column: 32, scope: !67)
// CHECK:STDOUT: !71 = !DILocation(line: 10, column: 25, scope: !67)
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !61, type: !38, spFlags: DISPFlagDefinition, unit: !62)
// CHECK:STDOUT: !73 = !DILocation(line: 8, column: 27, scope: !72)
// CHECK:STDOUT: !74 = !DILocation(line: 0, scope: !72)
// CHECK:STDOUT:

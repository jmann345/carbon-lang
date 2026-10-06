// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/let/global_runtime_specifics.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/let/global_runtime_specifics.carbon

// The W-069 risk R-2 falsifier (specific coalescing vs promoted-let
// globals), in its nearest EXPRESSIBLE form [W69b deviation record, see the
// plan]: the literal R-2 shape — two specifics of ONE generic each reading a
// DIFFERENT imported runtime `let` — is structurally inexpressible, because
// a file-scope name reference in a generic body resolves statically to one
// binding, so every specific of a generic references the SAME `let` set
// (the only specific-dependent value channel in `GetValue` is the constant
// path, and a runtime `let` is NotConstant by definition). Pinned instead:
// (1) `G`'s two specifics reach DIFFERENT imported runtime lets through
// per-type impl readers — if `CoalesceEquivalentSpecifics` merged them, one
// `_CG` specific symbol would serve both call sites and one binding's value
// would leak to the other's reader: THAT coalesced output is the alarm;
// (2) `H`'s two specifics read the SAME imported runtime let directly —
// the direct promoted-global load inside specific-function lowering, the
// path whose `AddGlobalToCurrentFingerprint` call R-2 mandates; these two
// bodies are identical, so the coalescer may legitimately merge them, and
// this golden records what the tree does.

// --- def.carbon

library "[[@TEST_NAME]]";

fn SeedA() -> i32 { return 3; }

fn SeedB() -> i32 { return 4; }

let la: i32 = SeedA();

let lb: i32 = SeedB();

// --- use.carbon

library "[[@TEST_NAME]]";

import library "def";

interface Reader {
  fn Get() -> i32;
}

class UseA {}
impl UseA as Reader {
  fn Get() -> i32 { return la; }
}

class UseB {}
impl UseB as Reader {
  fn Get() -> i32 { return lb; }
}

// Two specifics of ONE generic whose witness calls reach different promoted
// lets: must NOT coalesce.
fn G(generic T: Reader) -> i32 { return T.Get(); }

fn CallA() -> i32 { return G(UseA); }

fn CallB() -> i32 { return G(UseB); }

// Two specifics of ONE generic reading the SAME promoted let directly: the
// promoted-global load lands in each specific's fingerprint.
// CHECK:STDERR: use.carbon:[[@LINE+4]]:14: warning: binding `T` unused [UnusedBinding]
// CHECK:STDERR: fn H(generic T: type) -> i32 { return la; }
// CHECK:STDERR:              ^~~~~~~
// CHECK:STDERR:
fn H(generic T: type) -> i32 { return la; }

fn CallHA() -> i32 { return H(bool); }

fn CallHB() -> i32 { return H(i32); }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'def.carbon'
// CHECK:STDOUT: source_filename = "def.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Cla.Main = global i32 0
// CHECK:STDOUT: @_Clb.Main = global i32 0
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CSeedA.Main() #0 !dbg !9 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 3, !dbg !12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CSeedB.Main() #0 !dbg !13 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 4, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %SeedA.call = call i32 @_CSeedA.Main(), !dbg !20
// CHECK:STDOUT:   store i32 %SeedA.call, ptr @_Cla.Main, align 4
// CHECK:STDOUT:   %SeedB.call = call i32 @_CSeedB.Main(), !dbg !21
// CHECK:STDOUT:   store i32 %SeedB.call, ptr @_Clb.Main, align 4
// CHECK:STDOUT:   ret void, !dbg !22
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "def.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = distinct !DISubprogram(name: "SeedA", linkageName: "_CSeedA.Main", scope: null, file: !4, line: 4, type: !8, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !12 = !DILocation(line: 4, column: 21, scope: !9)
// CHECK:STDOUT: !13 = distinct !DISubprogram(name: "SeedB", linkageName: "_CSeedB.Main", scope: null, file: !4, line: 6, type: !8, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !16 = !DILocation(line: 6, column: 21, scope: !13)
// CHECK:STDOUT: !17 = !{null}
// CHECK:STDOUT: !18 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !4, type: !18, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !20 = !DILocation(line: 8, column: 15, scope: !19)
// CHECK:STDOUT: !21 = !DILocation(line: 10, column: 15, scope: !19)
// CHECK:STDOUT: !22 = !DILocation(line: 0, scope: !19)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'use.carbon'
// CHECK:STDOUT: source_filename = "use.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Cla.Main = external global i32
// CHECK:STDOUT: @_Clb.Main = external global i32
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CGet.UseA.Main:Reader.Main"() #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %la.ref = load i32, ptr @_Cla.Main, align 4, !dbg !28
// CHECK:STDOUT:   ret i32 %la.ref, !dbg !29
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CGet.UseB.Main:Reader.Main"() #0 !dbg !30 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %lb.ref = load i32, ptr @_Clb.Main, align 4, !dbg !33
// CHECK:STDOUT:   ret i32 %lb.ref, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CCallA.Main() #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call i32 @_CG.Main.b5567028e227e792(), !dbg !38
// CHECK:STDOUT:   ret i32 %G.call, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CCallB.Main() #0 !dbg !40 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call i32 @_CG.Main.37564afe55274bd3(), !dbg !43
// CHECK:STDOUT:   ret i32 %G.call, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CCallHA.Main() #0 !dbg !45 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %H.call = call i32 @_CH.Main.a4c7fafe8a72cac4(), !dbg !48
// CHECK:STDOUT:   ret i32 %H.call, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CCallHB.Main() #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %H.call = call i32 @_CH.Main.a4c7fafe8a72cac4(), !dbg !53
// CHECK:STDOUT:   ret i32 %H.call, !dbg !54
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CSeedA.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CSeedB.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CG.Main.b5567028e227e792() #0 !dbg !55 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Reader.WithSelf.Get.call = call i32 @"_CGet.UseA.Main:Reader.Main"(), !dbg !58
// CHECK:STDOUT:   ret i32 %Reader.WithSelf.Get.call, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CG.Main.37564afe55274bd3() #0 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Reader.WithSelf.Get.call = call i32 @"_CGet.UseB.Main:Reader.Main"(), !dbg !63
// CHECK:STDOUT:   ret i32 %Reader.WithSelf.Get.call, !dbg !64
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CH.Main.a4c7fafe8a72cac4() #0 !dbg !65 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %la.ref = load i32, ptr @_Cla.Main, align 4, !dbg !68
// CHECK:STDOUT:   ret i32 %la.ref, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CH.Main.a4c7fafe8a72cac4, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!24}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !23 = !DIFile(filename: "use.carbon", directory: "")
// CHECK:STDOUT: !24 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !23, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.UseA.Main:Reader.Main", scope: null, file: !23, line: 12, type: !8, spFlags: DISPFlagDefinition, unit: !24)
// CHECK:STDOUT: !28 = !DILocation(line: 12, column: 28, scope: !25)
// CHECK:STDOUT: !29 = !DILocation(line: 12, column: 21, scope: !25)
// CHECK:STDOUT: !30 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.UseB.Main:Reader.Main", scope: null, file: !23, line: 17, type: !8, spFlags: DISPFlagDefinition, unit: !24)
// CHECK:STDOUT: !33 = !DILocation(line: 17, column: 28, scope: !30)
// CHECK:STDOUT: !34 = !DILocation(line: 17, column: 21, scope: !30)
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "CallA", linkageName: "_CCallA.Main", scope: null, file: !23, line: 24, type: !8, spFlags: DISPFlagDefinition, unit: !24)
// CHECK:STDOUT: !38 = !DILocation(line: 24, column: 28, scope: !35)
// CHECK:STDOUT: !39 = !DILocation(line: 24, column: 21, scope: !35)
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "CallB", linkageName: "_CCallB.Main", scope: null, file: !23, line: 26, type: !8, spFlags: DISPFlagDefinition, unit: !24)
// CHECK:STDOUT: !43 = !DILocation(line: 26, column: 28, scope: !40)
// CHECK:STDOUT: !44 = !DILocation(line: 26, column: 21, scope: !40)
// CHECK:STDOUT: !45 = distinct !DISubprogram(name: "CallHA", linkageName: "_CCallHA.Main", scope: null, file: !23, line: 36, type: !8, spFlags: DISPFlagDefinition, unit: !24)
// CHECK:STDOUT: !48 = !DILocation(line: 36, column: 29, scope: !45)
// CHECK:STDOUT: !49 = !DILocation(line: 36, column: 22, scope: !45)
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "CallHB", linkageName: "_CCallHB.Main", scope: null, file: !23, line: 38, type: !8, spFlags: DISPFlagDefinition, unit: !24)
// CHECK:STDOUT: !53 = !DILocation(line: 38, column: 29, scope: !50)
// CHECK:STDOUT: !54 = !DILocation(line: 38, column: 22, scope: !50)
// CHECK:STDOUT: !55 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.b5567028e227e792", scope: null, file: !23, line: 22, type: !8, spFlags: DISPFlagDefinition, unit: !24)
// CHECK:STDOUT: !58 = !DILocation(line: 22, column: 41, scope: !55)
// CHECK:STDOUT: !59 = !DILocation(line: 22, column: 34, scope: !55)
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.37564afe55274bd3", scope: null, file: !23, line: 22, type: !8, spFlags: DISPFlagDefinition, unit: !24)
// CHECK:STDOUT: !63 = !DILocation(line: 22, column: 41, scope: !60)
// CHECK:STDOUT: !64 = !DILocation(line: 22, column: 34, scope: !60)
// CHECK:STDOUT: !65 = distinct !DISubprogram(name: "H", linkageName: "_CH.Main.a4c7fafe8a72cac4", scope: null, file: !23, line: 34, type: !8, spFlags: DISPFlagDefinition, unit: !24)
// CHECK:STDOUT: !68 = !DILocation(line: 34, column: 39, scope: !65)
// CHECK:STDOUT: !69 = !DILocation(line: 34, column: 32, scope: !65)
// CHECK:STDOUT:

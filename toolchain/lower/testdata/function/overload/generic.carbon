// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/generic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/generic.carbon

// A generic member of an `overload fn` set lowers per specific, and the
// specific's mangled name carries both the set-relative marker and the
// specific fingerprint (`_CKind:overload1.Main.<16 hex>`) beside the
// non-generic member's `_CKind:overload0.Main` (D-OV-5).

// --- kind.carbon

library "[[@TEST_NAME]]";

overload fn Kind(unused x: i32) -> i32 { return 1; }
overload fn Kind[T: type](unused x: T) -> i32 { return 2; }

fn Use() -> i32 { return Kind(5) + Kind(true); }

// --- discard_probe_constants.carbon

library "[[@TEST_NAME]]";

// Member 0 is a generic member that deduction ACCEPTS (`T = bool`) and the
// conversion probe then REJECTS (`false` does not convert to `i32`), so the
// call commits to member 1. The specific `Mixed(bool)` was minted by the
// rejected probe and is a persistent side effect (fork/overload/plan.md D-OV-4
// step 2(e)(a)): an extra `define` for it MAY appear here alongside the call
// to member 1 — predicted, not forbidden. The pin is the call: `Use` calls
// `_CMixed:overload1.Main`, never a specific of member 0.
overload fn Mixed[T: type](unused x: T, unused y: i32) -> i32 { return 1; }
overload fn Mixed(unused a: bool, unused b: bool) -> i32 { return 2; }

fn Use() -> i32 { return Mixed(true, false); }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'kind.carbon'
// CHECK:STDOUT: source_filename = "kind.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CKind:overload0.Main"(i32 %x) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !10
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !11 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Kind.call.loc7_32 = call i32 @"_CKind:overload0.Main"(i32 5), !dbg !14
// CHECK:STDOUT:   %Kind.call.loc7_45 = call i32 @"_CKind:overload1.Main.a4c7fafe8a72cac4"(i1 true), !dbg !15
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Kind.call.loc7_32, %Kind.call.loc7_45, !dbg !14
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CKind:overload1.Main.a4c7fafe8a72cac4"(i1 %x) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !23
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "kind.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Kind", linkageName: "_CKind:overload0.Main", scope: null, file: !1, line: 4, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{!9}
// CHECK:STDOUT: !9 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !10 = !DILocation(line: 4, column: 42, scope: !4)
// CHECK:STDOUT: !11 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 7, type: !12, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !12 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !13 = !{!7}
// CHECK:STDOUT: !14 = !DILocation(line: 7, column: 26, scope: !11)
// CHECK:STDOUT: !15 = !DILocation(line: 7, column: 36, scope: !11)
// CHECK:STDOUT: !16 = !DILocation(line: 7, column: 19, scope: !11)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "Kind", linkageName: "_CKind:overload1.Main.a4c7fafe8a72cac4", scope: null, file: !1, line: 5, type: !18, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !21)
// CHECK:STDOUT: !18 = !DISubroutineType(types: !19)
// CHECK:STDOUT: !19 = !{!7, !20}
// CHECK:STDOUT: !20 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !21 = !{!22}
// CHECK:STDOUT: !22 = !DILocalVariable(arg: 1, scope: !17, type: !20)
// CHECK:STDOUT: !23 = !DILocation(line: 5, column: 49, scope: !17)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'discard_probe_constants.carbon'
// CHECK:STDOUT: source_filename = "discard_probe_constants.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CMixed:overload1.Main"(i1 %a, i1 %b) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !13 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Mixed.call = call i32 @"_CMixed:overload1.Main"(i1 true, i1 false), !dbg !16
// CHECK:STDOUT:   ret i32 %Mixed.call, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "discard_probe_constants.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Mixed", linkageName: "_CMixed:overload1.Main", scope: null, file: !1, line: 12, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10, !11}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocalVariable(arg: 2, scope: !4, type: !8)
// CHECK:STDOUT: !12 = !DILocation(line: 12, column: 60, scope: !4)
// CHECK:STDOUT: !13 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 14, type: !14, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !14 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !15 = !{!7}
// CHECK:STDOUT: !16 = !DILocation(line: 14, column: 26, scope: !13)
// CHECK:STDOUT: !17 = !DILocation(line: 14, column: 19, scope: !13)
// CHECK:STDOUT:

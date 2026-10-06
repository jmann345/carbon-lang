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
// CHECK:STDOUT: define i32 @"_CKind:overload0.Main"(i32 %x) #0 !dbg !11 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Kind.call.loc7_32 = call i32 @"_CKind:overload0.Main"(i32 5), !dbg !21
// CHECK:STDOUT:   %Kind.call.loc7_45 = call i32 @"_CKind:overload1.Main.a4c7fafe8a72cac4"(i1 true), !dbg !22
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Kind.call.loc7_32, %Kind.call.loc7_45, !dbg !21
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CKind:overload1.Main.a4c7fafe8a72cac4"(i1 %x) #0 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "kind.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !{!6}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = distinct !DISubprogram(name: "Kind", linkageName: "_CKind:overload0.Main", scope: null, file: !4, line: 4, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !17)
// CHECK:STDOUT: !12 = !DILocalVariable(arg: 1, scope: !11, type: !6)
// CHECK:STDOUT: !16 = !DILocation(line: 4, column: 42, scope: !11)
// CHECK:STDOUT: !17 = !{!12}
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !4, line: 7, type: !10, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !21 = !DILocation(line: 7, column: 26, scope: !18)
// CHECK:STDOUT: !22 = !DILocation(line: 7, column: 36, scope: !18)
// CHECK:STDOUT: !23 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !24 = !{!6, !23}
// CHECK:STDOUT: !25 = !DISubroutineType(types: !24)
// CHECK:STDOUT: !26 = !DILocation(line: 7, column: 19, scope: !18)
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "Kind", linkageName: "_CKind:overload1.Main.a4c7fafe8a72cac4", scope: null, file: !4, line: 5, type: !25, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !33)
// CHECK:STDOUT: !28 = !DILocalVariable(arg: 1, scope: !27, type: !23)
// CHECK:STDOUT: !32 = !DILocation(line: 5, column: 49, scope: !27)
// CHECK:STDOUT: !33 = !{!28}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'discard_probe_constants.carbon'
// CHECK:STDOUT: source_filename = "discard_probe_constants.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CMixed:overload1.Main"(i1 %a, i1 %b) #0 !dbg !38 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !47 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Mixed.call = call i32 @"_CMixed:overload1.Main"(i1 true, i1 false), !dbg !50
// CHECK:STDOUT:   ret i32 %Mixed.call, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!35}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!6}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !23 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !34 = !DIFile(filename: "discard_probe_constants.carbon", directory: "")
// CHECK:STDOUT: !35 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !34, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !36 = !{!6, !23, !23}
// CHECK:STDOUT: !37 = !DISubroutineType(types: !36)
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "Mixed", linkageName: "_CMixed:overload1.Main", scope: null, file: !34, line: 12, type: !37, spFlags: DISPFlagDefinition, unit: !35, retainedNodes: !46)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !38, type: !23)
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 2, scope: !38, type: !23)
// CHECK:STDOUT: !45 = !DILocation(line: 12, column: 60, scope: !38)
// CHECK:STDOUT: !46 = !{!39, !40}
// CHECK:STDOUT: !47 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !34, line: 14, type: !10, spFlags: DISPFlagDefinition, unit: !35)
// CHECK:STDOUT: !50 = !DILocation(line: 14, column: 26, scope: !47)
// CHECK:STDOUT: !51 = !DILocation(line: 14, column: 19, scope: !47)
// CHECK:STDOUT:

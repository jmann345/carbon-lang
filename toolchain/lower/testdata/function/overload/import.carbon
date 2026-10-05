// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/import.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/import.carbon

// A member of an imported `overload fn` set is called by the same
// `:overload<N>` symbol that defines it (D-OV-5's stability pin): the index is
// the member's position in the set, mirrored on import, never a fingerprint of
// any instruction. The defining file's `define`s and the using file's `call`s
// name identical symbols; an api/impl pair defines each member once, in the
// implementation file, under the API-declared index. The two-file `extern`
// owner shape (fork/overload/plan.md §1.B.3) defines each member in the owning
// library's implementation file after an owning declaration in its API file,
// into a member localized from the set's `extern library` declaration;
// lowering reads neither `is_extern` nor `extern_library_id`, so the `define`s
// are emitted under the same symbols.

// --- lib.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// --- use.carbon

library "[[@TEST_NAME]]";

import library "lib";

fn Use() -> i32 { return F(7) + F(true); }

// --- api_impl.carbon

library "[[@TEST_NAME]]";

overload fn G(x: i32) -> i32;
overload fn G(b: bool) -> i32;

// --- api_impl.impl.carbon

impl library "[[@TEST_NAME]]";

overload fn G(x: i32) -> i32 { return x; }
overload fn G(b: bool) -> i32 { if (b) { return 1; } return 0; }

fn Use() -> i32 { return G(3) + G(true); }

// --- extern_two_file_lib.carbon

library "[[@TEST_NAME]]";

extern library "extern_two_file" overload fn D(x: i32) -> i32;
extern library "extern_two_file" overload fn D(b: bool) -> i32;

// --- extern_two_file.carbon

library "[[@TEST_NAME]]";

import library "extern_two_file_lib";

extern overload fn D(x: i32) -> i32;
extern overload fn D(b: bool) -> i32;

// --- extern_two_file.impl.carbon

impl library "[[@TEST_NAME]]";

extern overload fn D(x: i32) -> i32 { return x; }
extern overload fn D(b: bool) -> i32 { if (b) { return 1; } return 0; }

fn Use() -> i32 { return D(1) + D(true); }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'lib.carbon'
// CHECK:STDOUT: source_filename = "lib.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload0.Main"(i32 %x) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !10
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload1.Main"(i1 %b) #0 !dbg !11 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "lib.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload0.Main", scope: null, file: !1, line: 4, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{!9}
// CHECK:STDOUT: !9 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !10 = !DILocation(line: 4, column: 39, scope: !4)
// CHECK:STDOUT: !11 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload1.Main", scope: null, file: !1, line: 5, type: !12, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !15)
// CHECK:STDOUT: !12 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !13 = !{!7, !14}
// CHECK:STDOUT: !14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !15 = !{!16}
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 1, scope: !11, type: !14)
// CHECK:STDOUT: !17 = !DILocation(line: 5, column: 40, scope: !11)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'use.carbon'
// CHECK:STDOUT: source_filename = "use.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %F.call.loc6_29 = call i32 @"_CF:overload0.Main"(i32 7), !dbg !8
// CHECK:STDOUT:   %F.call.loc6_39 = call i32 @"_CF:overload1.Main"(i1 true), !dbg !9
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %F.call.loc6_29, %F.call.loc6_39, !dbg !8
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !10
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @"_CF:overload1.Main"(i1)
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @"_CF:overload0.Main"(i32)
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "use.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 6, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 6, column: 26, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 6, column: 33, scope: !4)
// CHECK:STDOUT: !10 = !DILocation(line: 6, column: 19, scope: !4)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'api_impl.carbon'
// CHECK:STDOUT: source_filename = "api_impl.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CG:overload0.Main"()
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CG:overload1.Main"()
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "api_impl.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'api_impl.impl.carbon'
// CHECK:STDOUT: source_filename = "api_impl.impl.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CG:overload1.Main"(i1 %b) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 %b, label %if.then, label %if.else, !dbg !11
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !12
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !13
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CG:overload0.Main"(i32 %x) #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 %x, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !20 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call.loc7_29 = call i32 @"_CG:overload0.Main"(i32 3), !dbg !23
// CHECK:STDOUT:   %G.call.loc7_39 = call i32 @"_CG:overload1.Main"(i1 true), !dbg !24
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %G.call.loc7_29, %G.call.loc7_39, !dbg !23
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "api_impl.impl.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "G", linkageName: "_CG:overload1.Main", scope: null, file: !1, line: 5, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 5, column: 36, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 5, column: 42, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 5, column: 54, scope: !4)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "G", linkageName: "_CG:overload0.Main", scope: null, file: !1, line: 4, type: !15, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !17)
// CHECK:STDOUT: !15 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !16 = !{!7, !7}
// CHECK:STDOUT: !17 = !{!18}
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !14, type: !7)
// CHECK:STDOUT: !19 = !DILocation(line: 4, column: 32, scope: !14)
// CHECK:STDOUT: !20 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 7, type: !21, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !21 = !DISubroutineType(types: !22)
// CHECK:STDOUT: !22 = !{!7}
// CHECK:STDOUT: !23 = !DILocation(line: 7, column: 26, scope: !20)
// CHECK:STDOUT: !24 = !DILocation(line: 7, column: 33, scope: !20)
// CHECK:STDOUT: !25 = !DILocation(line: 7, column: 19, scope: !20)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'extern_two_file_lib.carbon'
// CHECK:STDOUT: source_filename = "extern_two_file_lib.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CD:overload0.Main"()
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CD:overload1.Main"()
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "extern_two_file_lib.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'extern_two_file.carbon'
// CHECK:STDOUT: source_filename = "extern_two_file.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CD:overload1.Main"()
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CD:overload0.Main"()
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "extern_two_file.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'extern_two_file.impl.carbon'
// CHECK:STDOUT: source_filename = "extern_two_file.impl.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CD:overload1.Main"(i1 %b) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 %b, label %if.then, label %if.else, !dbg !11
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !12
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !13
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CD:overload0.Main"(i32 %x) #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 %x, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !20 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %D.call.loc7_29 = call i32 @"_CD:overload0.Main"(i32 1), !dbg !23
// CHECK:STDOUT:   %D.call.loc7_39 = call i32 @"_CD:overload1.Main"(i1 true), !dbg !24
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %D.call.loc7_29, %D.call.loc7_39, !dbg !23
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "extern_two_file.impl.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "D", linkageName: "_CD:overload1.Main", scope: null, file: !1, line: 5, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 5, column: 43, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 5, column: 49, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 5, column: 61, scope: !4)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "D", linkageName: "_CD:overload0.Main", scope: null, file: !1, line: 4, type: !15, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !17)
// CHECK:STDOUT: !15 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !16 = !{!7, !7}
// CHECK:STDOUT: !17 = !{!18}
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !14, type: !7)
// CHECK:STDOUT: !19 = !DILocation(line: 4, column: 39, scope: !14)
// CHECK:STDOUT: !20 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 7, type: !21, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !21 = !DISubroutineType(types: !22)
// CHECK:STDOUT: !22 = !{!7}
// CHECK:STDOUT: !23 = !DILocation(line: 7, column: 26, scope: !20)
// CHECK:STDOUT: !24 = !DILocation(line: 7, column: 33, scope: !20)
// CHECK:STDOUT: !25 = !DILocation(line: 7, column: 19, scope: !20)
// CHECK:STDOUT:

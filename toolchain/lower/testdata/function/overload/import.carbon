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
// CHECK:STDOUT: define i32 @"_CF:overload0.Main"(i32 %x) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload1.Main"(i1 %b) #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "lib.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!6, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload0.Main", scope: null, file: !4, line: 4, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !18)
// CHECK:STDOUT: !13 = !DILocalVariable(arg: 1, scope: !12, type: !6)
// CHECK:STDOUT: !17 = !DILocation(line: 4, column: 39, scope: !12)
// CHECK:STDOUT: !18 = !{!13}
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload1.Main", scope: null, file: !4, line: 5, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !25)
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !19, type: !9)
// CHECK:STDOUT: !24 = !DILocation(line: 5, column: 40, scope: !19)
// CHECK:STDOUT: !25 = !{!20}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'use.carbon'
// CHECK:STDOUT: source_filename = "use.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !30 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %F.call.loc6_29 = call i32 @"_CF:overload0.Main"(i32 7), !dbg !33
// CHECK:STDOUT:   %F.call.loc6_39 = call i32 @"_CF:overload1.Main"(i1 true), !dbg !34
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %F.call.loc6_29, %F.call.loc6_39, !dbg !33
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @"_CF:overload1.Main"(i1)
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @"_CF:overload0.Main"(i32)
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!27}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !26 = !DIFile(filename: "use.carbon", directory: "")
// CHECK:STDOUT: !27 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !26, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !28 = !{!6}
// CHECK:STDOUT: !29 = !DISubroutineType(types: !28)
// CHECK:STDOUT: !30 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !26, line: 6, type: !29, spFlags: DISPFlagDefinition, unit: !27)
// CHECK:STDOUT: !33 = !DILocation(line: 6, column: 26, scope: !30)
// CHECK:STDOUT: !34 = !DILocation(line: 6, column: 33, scope: !30)
// CHECK:STDOUT: !35 = !DILocation(line: 6, column: 19, scope: !30)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'api_impl.carbon'
// CHECK:STDOUT: source_filename = "api_impl.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CG:overload0.Main"()
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CG:overload1.Main"()
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!37}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !36 = !DIFile(filename: "api_impl.carbon", directory: "")
// CHECK:STDOUT: !37 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !36, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'api_impl.impl.carbon'
// CHECK:STDOUT: source_filename = "api_impl.impl.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CG:overload1.Main"(i1 %b) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 %b, label %if.then, label %if.else, !dbg !48
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !49
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !50
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CG:overload0.Main"(i32 %x) #0 !dbg !52 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 %x, !dbg !58
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call.loc7_29 = call i32 @"_CG:overload0.Main"(i32 3), !dbg !63
// CHECK:STDOUT:   %G.call.loc7_39 = call i32 @"_CG:overload1.Main"(i1 true), !dbg !64
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %G.call.loc7_29, %G.call.loc7_39, !dbg !63
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!41}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!6, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !28 = !{!6}
// CHECK:STDOUT: !29 = !DISubroutineType(types: !28)
// CHECK:STDOUT: !40 = !DIFile(filename: "api_impl.impl.carbon", directory: "")
// CHECK:STDOUT: !41 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !40, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "G", linkageName: "_CG:overload1.Main", scope: null, file: !40, line: 5, type: !11, spFlags: DISPFlagDefinition, unit: !41, retainedNodes: !51)
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !42, type: !9)
// CHECK:STDOUT: !48 = !DILocation(line: 5, column: 36, scope: !42)
// CHECK:STDOUT: !49 = !DILocation(line: 5, column: 42, scope: !42)
// CHECK:STDOUT: !50 = !DILocation(line: 5, column: 54, scope: !42)
// CHECK:STDOUT: !51 = !{!43}
// CHECK:STDOUT: !52 = distinct !DISubprogram(name: "G", linkageName: "_CG:overload0.Main", scope: null, file: !40, line: 4, type: !8, spFlags: DISPFlagDefinition, unit: !41, retainedNodes: !59)
// CHECK:STDOUT: !53 = !DILocalVariable(arg: 1, scope: !52, type: !6)
// CHECK:STDOUT: !58 = !DILocation(line: 4, column: 32, scope: !52)
// CHECK:STDOUT: !59 = !{!53}
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !40, line: 7, type: !29, spFlags: DISPFlagDefinition, unit: !41)
// CHECK:STDOUT: !63 = !DILocation(line: 7, column: 26, scope: !60)
// CHECK:STDOUT: !64 = !DILocation(line: 7, column: 33, scope: !60)
// CHECK:STDOUT: !65 = !DILocation(line: 7, column: 19, scope: !60)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'extern_two_file_lib.carbon'
// CHECK:STDOUT: source_filename = "extern_two_file_lib.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CD:overload0.Main"()
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CD:overload1.Main"()
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!67}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !66 = !DIFile(filename: "extern_two_file_lib.carbon", directory: "")
// CHECK:STDOUT: !67 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !66, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'extern_two_file.carbon'
// CHECK:STDOUT: source_filename = "extern_two_file.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CD:overload1.Main"()
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CD:overload0.Main"()
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!69}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !68 = !DIFile(filename: "extern_two_file.carbon", directory: "")
// CHECK:STDOUT: !69 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !68, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'extern_two_file.impl.carbon'
// CHECK:STDOUT: source_filename = "extern_two_file.impl.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CD:overload1.Main"(i1 %b) #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 %b, label %if.then, label %if.else, !dbg !78
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !79
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !80
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CD:overload0.Main"(i32 %x) #0 !dbg !82 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 %x, !dbg !88
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !90 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %D.call.loc7_29 = call i32 @"_CD:overload0.Main"(i32 1), !dbg !93
// CHECK:STDOUT:   %D.call.loc7_39 = call i32 @"_CD:overload1.Main"(i1 true), !dbg !94
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %D.call.loc7_29, %D.call.loc7_39, !dbg !93
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !95
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!71}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!6, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !28 = !{!6}
// CHECK:STDOUT: !29 = !DISubroutineType(types: !28)
// CHECK:STDOUT: !70 = !DIFile(filename: "extern_two_file.impl.carbon", directory: "")
// CHECK:STDOUT: !71 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !70, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "D", linkageName: "_CD:overload1.Main", scope: null, file: !70, line: 5, type: !11, spFlags: DISPFlagDefinition, unit: !71, retainedNodes: !81)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !9)
// CHECK:STDOUT: !78 = !DILocation(line: 5, column: 43, scope: !72)
// CHECK:STDOUT: !79 = !DILocation(line: 5, column: 49, scope: !72)
// CHECK:STDOUT: !80 = !DILocation(line: 5, column: 61, scope: !72)
// CHECK:STDOUT: !81 = !{!73}
// CHECK:STDOUT: !82 = distinct !DISubprogram(name: "D", linkageName: "_CD:overload0.Main", scope: null, file: !70, line: 4, type: !8, spFlags: DISPFlagDefinition, unit: !71, retainedNodes: !89)
// CHECK:STDOUT: !83 = !DILocalVariable(arg: 1, scope: !82, type: !6)
// CHECK:STDOUT: !88 = !DILocation(line: 4, column: 39, scope: !82)
// CHECK:STDOUT: !89 = !{!83}
// CHECK:STDOUT: !90 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !70, line: 7, type: !29, spFlags: DISPFlagDefinition, unit: !71)
// CHECK:STDOUT: !93 = !DILocation(line: 7, column: 26, scope: !90)
// CHECK:STDOUT: !94 = !DILocation(line: 7, column: 33, scope: !90)
// CHECK:STDOUT: !95 = !DILocation(line: 7, column: 19, scope: !90)
// CHECK:STDOUT:

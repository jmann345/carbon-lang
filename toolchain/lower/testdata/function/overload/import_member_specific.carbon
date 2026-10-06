// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/import_member_specific.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/import_member_specific.carbon

// The specific `Gen(i16)` is lowered in the importing file; its call to the
// member selected inside `Gen`'s body must name that member's own symbol,
// `_CP:overload0.Main` — the member's set-relative index is mirrored on
// import (D-OV-5), so the two members never collapse onto one declaration. An
// un-indexed `_CP.Main` here would be the falsifier.

// --- lib.carbon

library "[[@TEST_NAME]]";

overload fn P(unused x: i32) -> i32 { return 1; }
overload fn P(unused b: bool) -> i32 { return 2; }

fn Gen[T: Core.ImplicitAs(i32)](x: T) -> i32 { return P(x); }

// --- use_lib.carbon

library "[[@TEST_NAME]]";

import library "lib";

fn Use() -> i32 { return Gen(7 as i16); }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'lib.carbon'
// CHECK:STDOUT: source_filename = "lib.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CP:overload0.Main"(i32 %x) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CP:overload1.Main"(i1 %b) #0 !dbg !19 {
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
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "P", linkageName: "_CP:overload0.Main", scope: null, file: !4, line: 4, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !18)
// CHECK:STDOUT: !13 = !DILocalVariable(arg: 1, scope: !12, type: !6)
// CHECK:STDOUT: !17 = !DILocation(line: 4, column: 39, scope: !12)
// CHECK:STDOUT: !18 = !{!13}
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "P", linkageName: "_CP:overload1.Main", scope: null, file: !4, line: 5, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !25)
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !19, type: !9)
// CHECK:STDOUT: !24 = !DILocation(line: 5, column: 40, scope: !19)
// CHECK:STDOUT: !25 = !{!20}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'use_lib.carbon'
// CHECK:STDOUT: source_filename = "use_lib.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !31 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Gen.call = call i32 @_CGen.Main.98ea571c96480402(i16 7), !dbg !34
// CHECK:STDOUT:   ret i32 %Gen.call, !dbg !37
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGen.Main.98ea571c96480402(i16 %x) #0 !dbg !38 {
// CHECK:STDOUT:   %1 = call i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.e49b19ea36cc6fd2"(i16 %x), !dbg !43
// CHECK:STDOUT:   %2 = call i32 @"_CP:overload0.Main"(i32 %1), !dbg !44
// CHECK:STDOUT:   ret i32 %2, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @"_CP:overload0.Main"(i32)
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @"_CP:overload1.Main"(i1)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.e49b19ea36cc6fd2"(i16 %self) #0 !dbg !48 {
// CHECK:STDOUT:   %1 = call i16 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.cc6a1d911f1c2d3f"(i16 %self), !dbg !53
// CHECK:STDOUT:   %2 = sext i16 %1 to i32, !dbg !56
// CHECK:STDOUT:   ret i32 %2, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i16 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.cc6a1d911f1c2d3f"(i16 %self) #0 !dbg !59 {
// CHECK:STDOUT:   ret i16 %self, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!27}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "lib.carbon", directory: "")
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !26 = !DIFile(filename: "use_lib.carbon", directory: "")
// CHECK:STDOUT: !27 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !26, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !28 = !DIBasicType(name: "int", size: 16, encoding: DW_ATE_signed)
// CHECK:STDOUT: !29 = !{!6}
// CHECK:STDOUT: !30 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !31 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !26, line: 6, type: !30, spFlags: DISPFlagDefinition, unit: !27)
// CHECK:STDOUT: !34 = !DILocation(line: 6, column: 26, scope: !31)
// CHECK:STDOUT: !35 = !{!6, !28}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !37 = !DILocation(line: 6, column: 19, scope: !31)
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "Gen", linkageName: "_CGen.Main.98ea571c96480402", scope: null, file: !4, line: 7, type: !36, spFlags: DISPFlagDefinition, unit: !27, retainedNodes: !46)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !38, type: !28)
// CHECK:STDOUT: !43 = !DILocation(line: 7, column: 57, scope: !38)
// CHECK:STDOUT: !44 = !DILocation(line: 7, column: 55, scope: !38)
// CHECK:STDOUT: !45 = !DILocation(line: 7, column: 48, scope: !38)
// CHECK:STDOUT: !46 = !{!39}
// CHECK:STDOUT: !47 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.e49b19ea36cc6fd2", scope: null, file: !47, line: 64, type: !36, spFlags: DISPFlagDefinition, unit: !27, retainedNodes: !58)
// CHECK:STDOUT: !49 = !DILocalVariable(arg: 1, scope: !48, type: !28)
// CHECK:STDOUT: !53 = !DILocation(line: 66, column: 17, scope: !48)
// CHECK:STDOUT: !54 = !{!28, !28}
// CHECK:STDOUT: !55 = !DISubroutineType(types: !54)
// CHECK:STDOUT: !56 = !DILocation(line: 66, column: 12, scope: !48)
// CHECK:STDOUT: !57 = !DILocation(line: 66, column: 5, scope: !48)
// CHECK:STDOUT: !58 = !{!49}
// CHECK:STDOUT: !59 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.cc6a1d911f1c2d3f", scope: null, file: !47, line: 59, type: !55, spFlags: DISPFlagDefinition, unit: !27, retainedNodes: !66)
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !59, type: !28)
// CHECK:STDOUT: !65 = !DILocation(line: 59, column: 28, scope: !59)
// CHECK:STDOUT: !66 = !{!60}
// CHECK:STDOUT:

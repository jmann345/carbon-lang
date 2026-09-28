// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// EXTRA-ARGS: --mangle-string-fingerprint
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/mangle_string.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/mangle_string.carbon

// Members are mangled by set-relative index, not by a fingerprint (D-OV-5), so
// the string-fingerprint mode changes nothing about the `:overload<N>` names.

// --- first_match_order.carbon

library "[[@TEST_NAME]]";

overload fn Pick(unused x: i64) -> i32 { return 1; }
overload fn Pick(unused x: i32) -> i32 { return 2; }

fn Use(n: i32) -> i32 { return Pick(n); }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'first_match_order.carbon'
// CHECK:STDOUT: source_filename = "first_match_order.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CPick:overload0.Main"(i64 %x) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CPick:overload1.Main"(i32 %x) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main(i32 %n) #0 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.call = call i64 @"_CConvert.{facet_access_type,{symbolic_binding,{facet_type,2,IntFitsIn,Core,<package root>,{interface_decl,{generic_interface_type,IntFitsIn,Core,<package root>,!invalid},IntFitsIn,Core,<package root>},1,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{symbolic_binding,{Core.IntLiteral},0,!invalid,!invalid}},AnyInt,Core,<package root>,!invalid,0,0,0},1,!invalid,!invalid}}:ImplicitAs.{1,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{symbolic_binding,{Core.IntLiteral},0,!invalid,!invalid}}}.Core.{2,{int_value,{Core.IntLiteral},64},{facet_value,{facet_type,2,IntFitsIn,Core,<package root>,{interface_decl,{generic_interface_type,IntFitsIn,Core,<package root>,!invalid},IntFitsIn,Core,<package root>},1,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{int_value,{Core.IntLiteral},64}},AnyInt,Core,<package root>,!invalid,0,0,0},{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{int_value,{Core.IntLiteral},32}},2,{custom_witness,{<witness>},0,IntFitsIn,Core,<package root>,{interface_decl,{generic_interface_type,IntFitsIn,Core,<package root>,!invalid},IntFitsIn,Core,<package root>},1,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{int_value,{Core.IntLiteral},64}}},{impl_witness,{<witness>},{impl_witness_table,!invalid,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{symbolic_binding,{Core.IntLiteral},0,!invalid,!invalid}},{facet_type,1,AnyInt,Core,<package root>,!invalid,0,0,0},!invalid},{impl_decl,!invalid,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{symbolic_binding,{Core.IntLiteral},0,!invalid,!invalid}},{facet_type,1,AnyInt,Core,<package root>,!invalid,0,0,0},!invalid},1,{int_value,{Core.IntLiteral},32}}}}"(i32 %n), !dbg !21
// CHECK:STDOUT:   %Pick.call = call i32 @"_CPick:overload0.Main"(i64 %From.as_type.as.ImplicitAs.impl.Convert.call), !dbg !22
// CHECK:STDOUT:   ret i32 %Pick.call, !dbg !23
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CConvert.{facet_access_type,{symbolic_binding,{facet_type,2,IntFitsIn,Core,<package root>,{interface_decl,{generic_interface_type,IntFitsIn,Core,<package root>,!invalid},IntFitsIn,Core,<package root>},1,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{symbolic_binding,{Core.IntLiteral},0,!invalid,!invalid}},AnyInt,Core,<package root>,!invalid,0,0,0},1,!invalid,!invalid}}:ImplicitAs.{1,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{symbolic_binding,{Core.IntLiteral},0,!invalid,!invalid}}}.Core.{2,{int_value,{Core.IntLiteral},64},{facet_value,{facet_type,2,IntFitsIn,Core,<package root>,{interface_decl,{generic_interface_type,IntFitsIn,Core,<package root>,!invalid},IntFitsIn,Core,<package root>},1,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{int_value,{Core.IntLiteral},64}},AnyInt,Core,<package root>,!invalid,0,0,0},{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{int_value,{Core.IntLiteral},32}},2,{custom_witness,{<witness>},0,IntFitsIn,Core,<package root>,{interface_decl,{generic_interface_type,IntFitsIn,Core,<package root>,!invalid},IntFitsIn,Core,<package root>},1,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{int_value,{Core.IntLiteral},64}}},{impl_witness,{<witness>},{impl_witness_table,!invalid,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{symbolic_binding,{Core.IntLiteral},0,!invalid,!invalid}},{facet_type,1,AnyInt,Core,<package root>,!invalid,0,0,0},!invalid},{impl_decl,!invalid,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{symbolic_binding,{Core.IntLiteral},0,!invalid,!invalid}},{facet_type,1,AnyInt,Core,<package root>,!invalid,0,0,0},!invalid},1,{int_value,{Core.IntLiteral},32}}}}"(i32 %self) #0 !dbg !24 {
// CHECK:STDOUT:   %1 = call i32 @"_CAsInt.Int.{1,{symbolic_binding,{Core.IntLiteral},0,!invalid,!invalid}}.Core:AnyInt.Core.{1,{int_value,{Core.IntLiteral},32}}"(i32 %self), !dbg !30
// CHECK:STDOUT:   %2 = sext i32 %1 to i64, !dbg !31
// CHECK:STDOUT:   ret i64 %2, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CAsInt.Int.{1,{symbolic_binding,{Core.IntLiteral},0,!invalid,!invalid}}.Core:AnyInt.Core.{1,{int_value,{Core.IntLiteral},32}}"(i32 %self) #0 !dbg !33 {
// CHECK:STDOUT:   ret i32 %self, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "first_match_order.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Pick", linkageName: "_CPick:overload0.Main", scope: null, file: !1, line: 4, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 4, column: 42, scope: !4)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "Pick", linkageName: "_CPick:overload1.Main", scope: null, file: !1, line: 5, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !15)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{!7, !7}
// CHECK:STDOUT: !15 = !{!16}
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 1, scope: !12, type: !7)
// CHECK:STDOUT: !17 = !DILocation(line: 5, column: 42, scope: !12)
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 7, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !19)
// CHECK:STDOUT: !19 = !{!20}
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !18, type: !7)
// CHECK:STDOUT: !21 = !DILocation(line: 7, column: 37, scope: !18)
// CHECK:STDOUT: !22 = !DILocation(line: 7, column: 32, scope: !18)
// CHECK:STDOUT: !23 = !DILocation(line: 7, column: 25, scope: !18)
// CHECK:STDOUT: !24 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.{facet_access_type,{symbolic_binding,{facet_type,2,IntFitsIn,Core,<package root>,{interface_decl,{generic_interface_type,IntFitsIn,Core,<package root>,!invalid},IntFitsIn,Core,<package root>},1,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{symbolic_binding,{Core.IntLiteral},0,!invalid,!invalid}},AnyInt,Core,<package root>,!invalid,0,0,0},1,!invalid,!invalid}}:ImplicitAs.{1,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{symbolic_binding,{Core.IntLiteral},0,!invalid,!invalid}}}.Core.{2,{int_value,{Core.IntLiteral},64},{facet_value,{facet_type,2,IntFitsIn,Core,<package root>,{interface_decl,{generic_interface_type,IntFitsIn,Core,<package root>,!invalid},IntFitsIn,Core,<package root>},1,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{int_value,{Core.IntLiteral},64}},AnyInt,Core,<package root>,!invalid,0,0,0},{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{int_value,{Core.IntLiteral},32}},2,{custom_witness,{<witness>},0,IntFitsIn,Core,<package root>,{interface_decl,{generic_interface_type,IntFitsIn,Core,<package root>,!invalid},IntFitsIn,Core,<package root>},1,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{int_value,{Core.IntLiteral},64}}},{impl_witness,{<witness>},{impl_witness_table,!invalid,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{symbolic_binding,{Core.IntLiteral},0,!invalid,!invalid}},{facet_type,1,AnyInt,Core,<package root>,!invalid,0,0,0},!invalid},{impl_decl,!invalid,{class_type,Int,Core,<package root>,!invalid,{class_decl,{generic_class_type,Int,Core,<package root>,!invalid,!invalid},Int,Core,<package root>,!invalid},1,{symbolic_binding,{Core.IntLiteral},0,!invalid,!invalid}},{facet_type,1,AnyInt,Core,<package root>,!invalid,0,0,0},!invalid},1,{int_value,{Core.IntLiteral},32}}}}", scope: null, file: !25, line: 64, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !28)
// CHECK:STDOUT: !25 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !26 = !DISubroutineType(types: !27)
// CHECK:STDOUT: !27 = !{!8, !7}
// CHECK:STDOUT: !28 = !{!29}
// CHECK:STDOUT: !29 = !DILocalVariable(arg: 1, scope: !24, type: !7)
// CHECK:STDOUT: !30 = !DILocation(line: 66, column: 17, scope: !24)
// CHECK:STDOUT: !31 = !DILocation(line: 66, column: 12, scope: !24)
// CHECK:STDOUT: !32 = !DILocation(line: 66, column: 5, scope: !24)
// CHECK:STDOUT: !33 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.{1,{symbolic_binding,{Core.IntLiteral},0,!invalid,!invalid}}.Core:AnyInt.Core.{1,{int_value,{Core.IntLiteral},32}}", scope: null, file: !25, line: 59, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !34)
// CHECK:STDOUT: !34 = !{!35}
// CHECK:STDOUT: !35 = !DILocalVariable(arg: 1, scope: !33, type: !7)
// CHECK:STDOUT: !36 = !DILocation(line: 59, column: 28, scope: !33)
// CHECK:STDOUT:

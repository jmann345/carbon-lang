// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/string/subscript.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/string/subscript.carbon

// Fork (ST-1, fork/string/plan.md §4): `str` subscripts convert to `i64`
// before "string.at" (D-ST-9): a literal subscript on a runtime `str` is an
// `i64` constant index, and a `u8` subscript is zero-extended.

fn Literal(s: str) -> char { return s[0]; }
fn Unsigned(s: str, i: u8) -> char { return s[i]; }
fn Signed(s: str, i: i64) -> char { return s[i]; }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'subscript.carbon'
// CHECK:STDOUT: source_filename = "subscript.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i8 @_CLiteral.Main(ptr %s) #0 !dbg !15 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.call.string.load = load { ptr, i64 }, ptr %s, align 8, !dbg !20
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.call.string.ptr = extractvalue { ptr, i64 } %str.as.IndexWith.impl.At.call.string.load, 0, !dbg !20
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.call.string.char_ptr = getelementptr inbounds i8, ptr %str.as.IndexWith.impl.At.call.string.ptr, i64 0, !dbg !20
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.call.string.char = load i8, ptr %str.as.IndexWith.impl.At.call.string.char_ptr, align 1, !dbg !20
// CHECK:STDOUT:   ret i8 %str.as.IndexWith.impl.At.call.string.char, !dbg !21
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i8 @_CUnsigned.Main(ptr %s, i8 %i) #0 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %UInt.as.ImplicitAs.impl.Convert.call = call i64 @"_CConvert.UInt.9452f4c51951679b.Core:ImplicitAs.f48df0d8add56b17.Core.28ad8c0e3712175a"(i8 %i), !dbg !31
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.call.string.load = load { ptr, i64 }, ptr %s, align 8, !dbg !30
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.call.string.ptr = extractvalue { ptr, i64 } %str.as.IndexWith.impl.At.call.string.load, 0, !dbg !30
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.call.string.char_ptr = getelementptr inbounds i8, ptr %str.as.IndexWith.impl.At.call.string.ptr, i64 %UInt.as.ImplicitAs.impl.Convert.call, !dbg !30
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.call.string.char = load i8, ptr %str.as.IndexWith.impl.At.call.string.char_ptr, align 1, !dbg !30
// CHECK:STDOUT:   ret i8 %str.as.IndexWith.impl.At.call.string.char, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i8 @_CSigned.Main(ptr %s, i64 %i) #0 !dbg !36 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.call.string.load = load { ptr, i64 }, ptr %s, align 8, !dbg !43
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.call.string.ptr = extractvalue { ptr, i64 } %str.as.IndexWith.impl.At.call.string.load, 0, !dbg !43
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.call.string.char_ptr = getelementptr inbounds i8, ptr %str.as.IndexWith.impl.At.call.string.ptr, i64 %i, !dbg !43
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.call.string.char = load i8, ptr %str.as.IndexWith.impl.At.call.string.char_ptr, align 1, !dbg !43
// CHECK:STDOUT:   ret i8 %str.as.IndexWith.impl.At.call.string.char, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CConvert.UInt.9452f4c51951679b.Core:ImplicitAs.f48df0d8add56b17.Core.28ad8c0e3712175a"(i8 %self) #0 !dbg !48 {
// CHECK:STDOUT:   %1 = call i64 @"_CConvert.Int.9452f4c51951679b.Core:FromUInt.94db85caea4a44af.Core.60d2bb209e06e693"(i8 %self), !dbg !54
// CHECK:STDOUT:   ret i64 %1, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CConvert.Int.9452f4c51951679b.Core:FromUInt.94db85caea4a44af.Core.60d2bb209e06e693"(i8 %from) #0 !dbg !57 {
// CHECK:STDOUT:   %1 = call i8 @"_CAsUInt.UInt.9452f4c51951679b.Core:AnyUInt.Core.ca1ac10d3fc7c1a8"(i8 %from), !dbg !62
// CHECK:STDOUT:   %2 = zext i8 %1 to i64, !dbg !65
// CHECK:STDOUT:   ret i64 %2, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i8 @"_CAsUInt.UInt.9452f4c51951679b.Core:AnyUInt.Core.ca1ac10d3fc7c1a8"(i8 %self) #0 !dbg !68 {
// CHECK:STDOUT:   ret i8 %self, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "subscript.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!7, !8}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = !{!7, !8, !7}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{!7, !8, !6}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = distinct !DISubprogram(name: "Literal", linkageName: "_CLiteral.Main", scope: null, file: !4, line: 17, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !22)
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 1, scope: !15, type: !8)
// CHECK:STDOUT: !20 = !DILocation(line: 17, column: 37, scope: !15)
// CHECK:STDOUT: !21 = !DILocation(line: 17, column: 30, scope: !15)
// CHECK:STDOUT: !22 = !{!16}
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "Unsigned", linkageName: "_CUnsigned.Main", scope: null, file: !4, line: 18, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !35)
// CHECK:STDOUT: !24 = !DILocalVariable(arg: 1, scope: !23, type: !8)
// CHECK:STDOUT: !25 = !DILocalVariable(arg: 2, scope: !23, type: !7)
// CHECK:STDOUT: !30 = !DILocation(line: 18, column: 45, scope: !23)
// CHECK:STDOUT: !31 = !DILocation(line: 18, column: 47, scope: !23)
// CHECK:STDOUT: !32 = !{!6, !7}
// CHECK:STDOUT: !33 = !DISubroutineType(types: !32)
// CHECK:STDOUT: !34 = !DILocation(line: 18, column: 38, scope: !23)
// CHECK:STDOUT: !35 = !{!24, !25}
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "Signed", linkageName: "_CSigned.Main", scope: null, file: !4, line: 19, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !46)
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !36, type: !8)
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 2, scope: !36, type: !6)
// CHECK:STDOUT: !43 = !DILocation(line: 19, column: 44, scope: !36)
// CHECK:STDOUT: !45 = !DILocation(line: 19, column: 37, scope: !36)
// CHECK:STDOUT: !46 = !{!37, !38}
// CHECK:STDOUT: !47 = !DIFile(filename: "{{.*}}/prelude/types/uint.carbon", directory: "")
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.UInt.9452f4c51951679b.Core:ImplicitAs.f48df0d8add56b17.Core.28ad8c0e3712175a", scope: null, file: !47, line: 88, type: !33, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !56)
// CHECK:STDOUT: !49 = !DILocalVariable(arg: 1, scope: !48, type: !7)
// CHECK:STDOUT: !54 = !DILocation(line: 89, column: 12, scope: !48)
// CHECK:STDOUT: !55 = !DILocation(line: 89, column: 5, scope: !48)
// CHECK:STDOUT: !56 = !{!49}
// CHECK:STDOUT: !57 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.Int.9452f4c51951679b.Core:FromUInt.94db85caea4a44af.Core.60d2bb209e06e693", scope: null, file: !47, line: 80, type: !33, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !67)
// CHECK:STDOUT: !58 = !DILocalVariable(arg: 1, scope: !57, type: !7)
// CHECK:STDOUT: !62 = !DILocation(line: 82, column: 17, scope: !57)
// CHECK:STDOUT: !63 = !{!7, !7}
// CHECK:STDOUT: !64 = !DISubroutineType(types: !63)
// CHECK:STDOUT: !65 = !DILocation(line: 82, column: 12, scope: !57)
// CHECK:STDOUT: !66 = !DILocation(line: 82, column: 5, scope: !57)
// CHECK:STDOUT: !67 = !{!58}
// CHECK:STDOUT: !68 = distinct !DISubprogram(name: "AsUInt", linkageName: "_CAsUInt.UInt.9452f4c51951679b.Core:AnyUInt.Core.ca1ac10d3fc7c1a8", scope: null, file: !47, line: 60, type: !64, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !75)
// CHECK:STDOUT: !69 = !DILocalVariable(arg: 1, scope: !68, type: !7)
// CHECK:STDOUT: !74 = !DILocation(line: 60, column: 29, scope: !68)
// CHECK:STDOUT: !75 = !{!69}
// CHECK:STDOUT:

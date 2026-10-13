// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/string/compare.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/string/compare.carbon

// Fork (ST-1, fork/string/plan.md §4): comparisons call the prelude's impl
// functions, whose bodies are in the prelude object.

fn Eq(a: str, b: str) -> bool { return a == b; }
fn Lt(a: str, b: str) -> bool { return a < b; }
fn EqBufStr(a: Core.StringBuf, b: str) -> bool { return a == b; }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'compare.carbon'
// CHECK:STDOUT: source_filename = "compare.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i1 @_CEq.Main(ptr %a, ptr %b) #0 !dbg !10 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %str.as.EqWith.impl.Equal.call = call i1 @"_CEqual.String.Core:EqWith.031c1d1c7540fb09.Core"(ptr %a, ptr %b), !dbg !17
// CHECK:STDOUT:   ret i1 %str.as.EqWith.impl.Equal.call, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i1 @"_CEqual.String.Core:EqWith.031c1d1c7540fb09.Core"(ptr, ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i1 @_CLt.Main(ptr %a, ptr %b) #0 !dbg !21 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %str.as.OrderedWith.impl.Less.call = call i1 @"_CLess.String.Core:OrderedWith.031c1d1c7540fb09.Core"(ptr %a, ptr %b), !dbg !28
// CHECK:STDOUT:   ret i1 %str.as.OrderedWith.impl.Less.call, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i1 @"_CLess.String.Core:OrderedWith.031c1d1c7540fb09.Core"(ptr, ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i1 @_CEqBufStr.Main(ptr %a, ptr %b) #0 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %StringBuf.as.EqWith.impl.Equal.call = call i1 @"_CEqual.StringBuf.Core:EqWith.031c1d1c7540fb09.Core"(ptr %a, ptr %b), !dbg !39
// CHECK:STDOUT:   ret i1 %StringBuf.as.EqWith.impl.Equal.call, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i1 @"_CEqual.StringBuf.Core:EqWith.031c1d1c7540fb09.Core"(ptr, ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "compare.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = distinct !DISubprogram(name: "Eq", linkageName: "_CEq.Main", scope: null, file: !4, line: 16, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !20)
// CHECK:STDOUT: !11 = !DILocalVariable(arg: 1, scope: !10, type: !7)
// CHECK:STDOUT: !12 = !DILocalVariable(arg: 2, scope: !10, type: !7)
// CHECK:STDOUT: !17 = !DILocation(line: 16, column: 40, scope: !10)
// CHECK:STDOUT: !19 = !DILocation(line: 16, column: 33, scope: !10)
// CHECK:STDOUT: !20 = !{!11, !12}
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "Lt", linkageName: "_CLt.Main", scope: null, file: !4, line: 17, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !31)
// CHECK:STDOUT: !22 = !DILocalVariable(arg: 1, scope: !21, type: !7)
// CHECK:STDOUT: !23 = !DILocalVariable(arg: 2, scope: !21, type: !7)
// CHECK:STDOUT: !28 = !DILocation(line: 17, column: 40, scope: !21)
// CHECK:STDOUT: !30 = !DILocation(line: 17, column: 33, scope: !21)
// CHECK:STDOUT: !31 = !{!22, !23}
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "EqBufStr", linkageName: "_CEqBufStr.Main", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !42)
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !32, type: !7)
// CHECK:STDOUT: !34 = !DILocalVariable(arg: 2, scope: !32, type: !7)
// CHECK:STDOUT: !39 = !DILocation(line: 18, column: 57, scope: !32)
// CHECK:STDOUT: !41 = !DILocation(line: 18, column: 50, scope: !32)
// CHECK:STDOUT: !42 = !{!33, !34}
// CHECK:STDOUT:

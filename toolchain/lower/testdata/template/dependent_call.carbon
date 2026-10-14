// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/template/dependent_call.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/template/dependent_call.carbon

// --- call_function_typed_value.carbon
library "[[@TEST_NAME]]";

fn Apply[template G: type](h: G, x: i32) -> i32 {
  return h(x);
}

fn Twice(x: i32) -> i32 {
  return 2 * x;
}

fn Use() -> i32 {
  return Apply(Twice, 4);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'call_function_typed_value.carbon'
// CHECK:STDOUT: source_filename = "call_function_typed_value.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CTwice.Main(i32 %x) #0 !dbg !11 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %T.as_type.as.MulWith.impl.Op.call = mul i32 2, %x, !dbg !17
// CHECK:STDOUT:   ret i32 %T.as_type.as.MulWith.impl.Op.call, !dbg !18
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !20 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Apply.call = call i32 @_CApply.Main.50eb2843f462a993(i32 4), !dbg !23
// CHECK:STDOUT:   ret i32 %Apply.call, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CApply.Main.50eb2843f462a993(i32 %x) #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Twice.call = call i32 @_CTwice.Main(i32 %x), !dbg !31
// CHECK:STDOUT:   ret i32 %Twice.call, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "call_function_typed_value.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !{!6}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = distinct !DISubprogram(name: "Twice", linkageName: "_CTwice.Main", scope: null, file: !4, line: 7, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !19)
// CHECK:STDOUT: !12 = !DILocalVariable(arg: 1, scope: !11, type: !6)
// CHECK:STDOUT: !17 = !DILocation(line: 8, column: 10, scope: !11)
// CHECK:STDOUT: !18 = !DILocation(line: 8, column: 3, scope: !11)
// CHECK:STDOUT: !19 = !{!12}
// CHECK:STDOUT: !20 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !4, line: 11, type: !10, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !23 = !DILocation(line: 12, column: 10, scope: !20)
// CHECK:STDOUT: !24 = !DILocation(line: 12, column: 3, scope: !20)
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "Apply", linkageName: "_CApply.Main.50eb2843f462a993", scope: null, file: !4, line: 3, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !34)
// CHECK:STDOUT: !26 = !DILocalVariable(arg: 1, scope: !25, type: !6)
// CHECK:STDOUT: !31 = !DILocation(line: 4, column: 10, scope: !25)
// CHECK:STDOUT: !33 = !DILocation(line: 4, column: 3, scope: !25)
// CHECK:STDOUT: !34 = !{!26}
// CHECK:STDOUT:

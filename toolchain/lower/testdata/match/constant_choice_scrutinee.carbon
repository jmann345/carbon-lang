// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/constant_choice_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/constant_choice_scrutinee.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md D-SV-9): a `match` directly on a
// constant choice value with a payload arm. The payload access folds to the
// payload region's constant, which lowering now gives an address (a private
// constant global) before indexing into it; trunk built a load from a
// non-pointer constant and failed LLVM verification.

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Sink(unused n: i32) {}

fn F() -> i32 {
  match (Opt(i32).None) {
    case .Some(v: i32) => {
      Sink(v);
      return v;
    }
    case .None => {
      return -1;
    }
  }
  return -2;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'constant_choice_scrutinee.carbon'
// CHECK:STDOUT: source_filename = "constant_choice_scrutinee.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Opt.val.b51 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @uninit.060.anon = internal constant [4 x i8] zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CSink.Main(i32 %n) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !15
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CF.Main() #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 false, label %match.case.then.loc28, label %match.case.else.loc28, !dbg !20
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc28:                            ; preds = %entry
// CHECK:STDOUT:   %.loc28_24.9 = load i32, ptr @uninit.060.anon, align 4, !dbg !20
// CHECK:STDOUT:   call void @_CSink.Main(i32 %.loc28_24.9), !dbg !23
// CHECK:STDOUT:   ret i32 %.loc28_24.9, !dbg !25
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc28:                            ; preds = %entry
// CHECK:STDOUT:   br i1 true, label %match.case.then.loc32, label %match.done, !dbg !26
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc32:                            ; preds = %match.case.else.loc28
// CHECK:STDOUT:   ret i32 -1, !dbg !27
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc28
// CHECK:STDOUT:   ret i32 -2, !dbg !29
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "constant_choice_scrutinee.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{null, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{!7}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "Sink", linkageName: "_CSink.Main", scope: null, file: !4, line: 24, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !16)
// CHECK:STDOUT: !13 = !DILocalVariable(arg: 1, scope: !12, type: !7)
// CHECK:STDOUT: !15 = !DILocation(line: 24, column: 1, scope: !12)
// CHECK:STDOUT: !16 = !{!13}
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !4, line: 26, type: !11, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !20 = !DILocation(line: 28, column: 5, scope: !17)
// CHECK:STDOUT: !23 = !DILocation(line: 29, column: 7, scope: !17)
// CHECK:STDOUT: !25 = !DILocation(line: 30, column: 7, scope: !17)
// CHECK:STDOUT: !26 = !DILocation(line: 32, column: 5, scope: !17)
// CHECK:STDOUT: !27 = !DILocation(line: 33, column: 7, scope: !17)
// CHECK:STDOUT: !29 = !DILocation(line: 36, column: 3, scope: !17)
// CHECK:STDOUT:

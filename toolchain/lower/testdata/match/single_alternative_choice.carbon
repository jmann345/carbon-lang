// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/single_alternative_choice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/single_alternative_choice.carbon

// The W-068 dispatch shape at lowering: a single-alternative choice has no
// integer discriminant, so — unlike choice_payload.carbon's
// compare-and-branch chain — the arm's condition is a constant true (no
// discriminant load, no icmp), while the payload access stays real: the
// arm's body reads the payload tuple element through the payload region
// field of the `{(), payload}` representation, exactly as in the
// multi-alternative lowering.

choice OneShot {
  Only(x: i32)
}

fn Get(o: OneShot) -> i32 {
  match (o) {
    case .Only(v: i32) => { return v; }
  }
  return -1;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'single_alternative_choice.carbon'
// CHECK:STDOUT: source_filename = "single_alternative_choice.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_COnly.OneShot.Main(ptr sret({ {}, [4 x i8] }) %return, i32 %_) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc21_16.1.discriminant = getelementptr inbounds nuw { {}, [4 x i8] }, ptr %return, i32 0, i32 0, !dbg !14
// CHECK:STDOUT:   %.loc21_16.4.payload = getelementptr inbounds nuw { {}, [4 x i8] }, ptr %return, i32 0, i32 1, !dbg !14
// CHECK:STDOUT:   %.loc21_16.5.Only = getelementptr inbounds nuw [4 x i8], ptr %.loc21_16.4.payload, i32 0, i32 0, !dbg !14
// CHECK:STDOUT:   %.loc23_1.4.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !14
// CHECK:STDOUT:   store { i32 } %.loc23_1.4.tuple.init, ptr %.loc21_16.5.Only, align 4, !dbg !14
// CHECK:STDOUT:   ret void, !dbg !14
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CGet.Main(ptr %o) #0 !dbg !16 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 true, label %match.case.then, label %match.done, !dbg !22
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   %.loc27_24.1.payload = getelementptr inbounds nuw { {}, [4 x i8] }, ptr %o, i32 0, i32 1, !dbg !22
// CHECK:STDOUT:   %.loc27_24.2.Only = getelementptr inbounds nuw [4 x i8], ptr %.loc27_24.1.payload, i32 0, i32 0, !dbg !22
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc27_24.2.Only, i32 0, i32 0, !dbg !22
// CHECK:STDOUT:   %.loc27_24.3 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !22
// CHECK:STDOUT:   ret i32 %.loc27_24.3, !dbg !25
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %entry
// CHECK:STDOUT:   ret i32 -1, !dbg !27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "single_alternative_choice.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !6}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{!6, !7}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "Only", linkageName: "_COnly.OneShot.Main", scope: null, file: !4, line: 21, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !15)
// CHECK:STDOUT: !13 = !DILocalVariable(arg: 1, scope: !12, type: !6)
// CHECK:STDOUT: !14 = !DILocation(line: 21, column: 1, scope: !12)
// CHECK:STDOUT: !15 = !{!13}
// CHECK:STDOUT: !16 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Main", scope: null, file: !4, line: 25, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !28)
// CHECK:STDOUT: !17 = !DILocalVariable(arg: 1, scope: !16, type: !7)
// CHECK:STDOUT: !22 = !DILocation(line: 27, column: 5, scope: !16)
// CHECK:STDOUT: !25 = !DILocation(line: 27, column: 29, scope: !16)
// CHECK:STDOUT: !27 = !DILocation(line: 29, column: 3, scope: !16)
// CHECK:STDOUT: !28 = !{!17}
// CHECK:STDOUT:

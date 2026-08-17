// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/choice_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/choice_payload.carbon

// Payload destructuring must lower to real payload accesses (plan risk R-9:
// this golden discriminates the payload GEPs): the discriminant load feeds
// the arm's compare-and-branch chain, and the matched arm's body reads the
// payload tuple element through the payload region field at offset zero of
// the choice's `{discriminant, payload}` representation.

choice IntResult {
  Ok(value: i32),
  Err
}

fn Consume(r: IntResult) -> i32 {
  match (r) {
    case .Ok(value: i32) => { return value; }
    case .Err => { return -1; }
    default => { return -2; }
  }
  return -3;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'choice_payload.carbon'
// CHECK:STDOUT: source_filename = "choice_payload.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @IntResult.val = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] poison }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @IntResult.val.loc22_1.13 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] poison }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_COk.IntResult.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_18.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc19_18.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !11
// CHECK:STDOUT:   %.loc19_18.5.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc19_18.4.payload, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc20_17.2.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !12
// CHECK:STDOUT:   store { i32 } %.loc20_17.2.tuple.init, ptr %.loc19_18.5.Ok, align 4, !dbg !11
// CHECK:STDOUT:   store i8 0, ptr %.loc19_18.1.discriminant, align 1, !dbg !11
// CHECK:STDOUT:   ret void, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CConsume.Main(ptr %r) #0 !dbg !13 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc26_26.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %r, i32 0, i32 0, !dbg !18
// CHECK:STDOUT:   %.loc26_26.4 = load i8, ptr %.loc26_26.3.discriminant, align 1, !dbg !18
// CHECK:STDOUT:   %.loc26_26.41 = trunc i8 %.loc26_26.4 to i1, !dbg !18
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc26 = icmp eq i1 false, %.loc26_26.41, !dbg !18
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc26, label %match.case.then.loc26, label %match.case.else.loc26, !dbg !18
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc26:                            ; preds = %entry
// CHECK:STDOUT:   %.loc26_26.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %r, i32 0, i32 1, !dbg !18
// CHECK:STDOUT:   %.loc26_26.8.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc26_26.7.payload, i32 0, i32 0, !dbg !18
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc26_26.8.Ok, i32 0, i32 0, !dbg !18
// CHECK:STDOUT:   %.loc26_26.9 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !18
// CHECK:STDOUT:   ret i32 %.loc26_26.9, !dbg !19
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc26:                            ; preds = %entry
// CHECK:STDOUT:   %.loc27_15.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %r, i32 0, i32 0, !dbg !20
// CHECK:STDOUT:   %.loc27_15.4 = load i8, ptr %.loc27_15.3.discriminant, align 1, !dbg !20
// CHECK:STDOUT:   %.loc27_15.42 = trunc i8 %.loc27_15.4 to i1, !dbg !20
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc27 = icmp eq i1 true, %.loc27_15.42, !dbg !20
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc27, label %match.case.then.loc27, label %match.case.else.loc27, !dbg !20
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc27:                            ; preds = %match.case.else.loc26
// CHECK:STDOUT:   ret i32 -1, !dbg !21
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc27:                            ; preds = %match.case.else.loc26
// CHECK:STDOUT:   ret i32 -2, !dbg !22
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "choice_payload.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.IntResult.Main", scope: null, file: !1, line: 19, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 19, column: 1, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 20, column: 17, scope: !4)
// CHECK:STDOUT: !13 = distinct !DISubprogram(name: "Consume", linkageName: "_CConsume.Main", scope: null, file: !1, line: 24, type: !14, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !16)
// CHECK:STDOUT: !14 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !15 = !{!8, !7}
// CHECK:STDOUT: !16 = !{!17}
// CHECK:STDOUT: !17 = !DILocalVariable(arg: 1, scope: !13, type: !7)
// CHECK:STDOUT: !18 = !DILocation(line: 26, column: 5, scope: !13)
// CHECK:STDOUT: !19 = !DILocation(line: 26, column: 31, scope: !13)
// CHECK:STDOUT: !20 = !DILocation(line: 27, column: 5, scope: !13)
// CHECK:STDOUT: !21 = !DILocation(line: 27, column: 20, scope: !13)
// CHECK:STDOUT: !22 = !DILocation(line: 28, column: 18, scope: !13)
// CHECK:STDOUT:

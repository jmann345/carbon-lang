// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/choice_generic_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/choice_generic_scrutinee.carbon

// Discriminant dispatch on a specific of a payload-free generic choice
// (W5-S3a): the specific's object representation supplies the integer
// discriminant the arms compare against, and constructing an alternative
// constant through the specific stores the same discriminant the dispatch
// reads back.

choice P(T: type) {
  A,
  B
}

fn Classify(p: P(i32)) -> i32 {
  match (p) {
    case .A => { return 0; }
    case .B => { return 1; }
  }
  return -1;
}

fn Run() -> i32 {
  // `let` binds the alternative constant's value directly (choices have no
  // `Copy` impl, so return/`var` initialization from the constant is out);
  // the lowered constant carries the discriminant the dispatch reads back.
  let b: P(i32) = P(i32).B;
  return Classify(b);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'choice_generic_scrutinee.carbon'
// CHECK:STDOUT: source_filename = "choice_generic_scrutinee.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @P.val.0e9 = internal constant { i1 } zeroinitializer
// CHECK:STDOUT: @P.val.61e = internal constant { i1 } { i1 true }
// CHECK:STDOUT: @P.val.61e.B.ref = internal constant { i1 } { i1 true }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CClassify.Main(ptr %p) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc26_13.3.discriminant = getelementptr inbounds nuw { i1 }, ptr %p, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc26_13.4 = load i8, ptr %.loc26_13.3.discriminant, align 1, !dbg !11
// CHECK:STDOUT:   %.loc26_13.41 = trunc i8 %.loc26_13.4 to i1, !dbg !11
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc26 = icmp eq i1 false, %.loc26_13.41, !dbg !11
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc26, label %match.case.then.loc26, label %match.case.else.loc26, !dbg !11
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc26:                            ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !12
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc26:                            ; preds = %entry
// CHECK:STDOUT:   %.loc27_13.3.discriminant = getelementptr inbounds nuw { i1 }, ptr %p, i32 0, i32 0, !dbg !13
// CHECK:STDOUT:   %.loc27_13.4 = load i8, ptr %.loc27_13.3.discriminant, align 1, !dbg !13
// CHECK:STDOUT:   %.loc27_13.42 = trunc i8 %.loc27_13.4 to i1, !dbg !13
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc27 = icmp eq i1 true, %.loc27_13.42, !dbg !13
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc27, label %match.case.then.loc27, label %match.done, !dbg !13
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc27:                            ; preds = %match.case.else.loc26
// CHECK:STDOUT:   ret i32 1, !dbg !14
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc26
// CHECK:STDOUT:   ret i32 -1, !dbg !15
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !16 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Classify.call = call i32 @_CClassify.Main(ptr @P.val.61e.B.ref), !dbg !19
// CHECK:STDOUT:   ret i32 %Classify.call, !dbg !20
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "choice_generic_scrutinee.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Classify", linkageName: "_CClassify.Main", scope: null, file: !1, line: 24, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 26, column: 5, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 26, column: 18, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 27, column: 5, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 27, column: 18, scope: !4)
// CHECK:STDOUT: !15 = !DILocation(line: 29, column: 3, scope: !4)
// CHECK:STDOUT: !16 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !1, line: 32, type: !17, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !17 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !18 = !{!7}
// CHECK:STDOUT: !19 = !DILocation(line: 37, column: 10, scope: !16)
// CHECK:STDOUT: !20 = !DILocation(line: 37, column: 3, scope: !16)
// CHECK:STDOUT:

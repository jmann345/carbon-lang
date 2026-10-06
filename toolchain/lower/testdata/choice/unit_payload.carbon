// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/choice/unit_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/choice/unit_payload.carbon

// The zero-sized `()` payload, lowered (W-070 option (a), fork/eh/plan.md
// D-EH-2, risk R-3). Two construction regimes are pinned, and they differ:
//
// - `U.A(())` on the NON-GENERIC `U`: the payload tuple `((),)` has exactly
//   one value, so inside `@U.A` the parameter's conversion folds to a
//   constant and the constructor's `class_init` folds to the `StructValue`
//   `%U.val = struct_value (%int_0, %tuple)` whose payload element carries
//   the TUPLE type `((),)` (LLVM `{ {} }`), not the region type `[4 x i8]`
//   (check/testdata/choice/unit_payload.carbon:123). Lowering emits it as
//   the template `@U.val = internal constant <{ <{ i1, [3 x i8] }>,
//   [4 x i8] }>` with a zero-filled region (constant.cpp `PadToType`'s
//   zero-sized-in-byte-region arm) and `@U.A` memcpys the template into the
//   return slot -- the `alternative_copy.carbon` `@Flag.val` shape. R-3's
//   falsifier FIRED on the first fill (run 36301651448: `PadToType`'s
//   CHECK, `{ {} }` against `[4 x i8]`); this file is the regression pin.
// - `Core.ControlFlow(i32, ()).Break(())` on the GENERIC prelude choice: the
//   payload is symbolic in the constructor, so it takes handle_choice.cpp's
//   cover-then-update path and the `((),)` reaches the region through a
//   runtime zero-size `store { {} }` at offset 0 -- no folded constant. The
//   region's size is the max over the OTHER payloads: `<{ <{ i1, [3 x i8] }>,
//   [4 x i8] }>` (discriminant sub-struct padded to the `i32` payload's
//   alignment).
//
// The `multi_unit_payload.carbon` subfile pins the second folding shape,
// `((), ())`: a two-element all-zero-sized payload tuple (LLVM `{ {}, {} }`)
// folds the same way and takes the same arm. `U.B(n)` / `V.D(n)` pin that a
// non-zero-sized payload never folds (it depends on the parameter) and is
// unaffected. The D-EH-2 break condition's falsifier remains a lowering
// crash or a non-zero-size region for the `()` arm.

// --- unit_payload.carbon
library "[[@TEST_NAME]]";

fn Sink(unused u: ()) {}

choice U {
  A(x: ()),
  B(y: i32)
}

fn MakeA() -> U { return U.A(()); }
fn MakeB(n: i32) -> U { return U.B(n); }

fn Classify(u: U) -> i32 {
  match (u) {
    case .A(x: ()) => {
      Sink(x);
      return 0;
    }
    case .B(y: i32) => { return y; }
  }
  // Unreachable trailing return: reachability doesn't consult match
  // exhaustiveness.
  return -1;
}

// --- control_flow_unit.carbon
library "[[@TEST_NAME]]";

fn Sink(unused u: ()) {}

fn MakeBreak() -> Core.ControlFlow(i32, ()) {
  return Core.ControlFlow(i32, ()).Break(());
}

fn MakeContinue(n: i32) -> Core.ControlFlow(i32, ()) {
  return Core.ControlFlow(i32, ()).Continue(n);
}

fn Classify(c: Core.ControlFlow(i32, ())) -> i32 {
  match (c) {
    case .Continue(v: i32) => { return v; }
    case .Break(b: ()) => {
      Sink(b);
      return -1;
    }
  }
  // Unreachable trailing return: reachability doesn't consult match
  // exhaustiveness.
  return -2;
}

// --- multi_unit_payload.carbon
library "[[@TEST_NAME]]";

fn Sink(unused u: ()) {}

choice V {
  C(x: (), y: ()),
  D(z: i32)
}

fn MakeC() -> V { return V.C((), ()); }
fn MakeD(n: i32) -> V { return V.D(n); }

fn Classify(v: V) -> i32 {
  match (v) {
    case .C(x: (), y: ()) => {
      Sink(x);
      Sink(y);
      return 0;
    }
    case .D(z: i32) => { return z; }
  }
  // Unreachable trailing return: reachability doesn't consult match
  // exhaustiveness.
  return -1;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'unit_payload.carbon'
// CHECK:STDOUT: source_filename = "unit_payload.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @U.val.loc5_10.9 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CSink.Main() #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CA.U.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !20 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc5_10.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !21
// CHECK:STDOUT:   %.loc5_10.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !21
// CHECK:STDOUT:   %.loc5_10.5.A = getelementptr inbounds nuw [4 x i8], ptr %.loc5_10.4.payload, i32 0, i32 0, !dbg !21
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { {} }, ptr %.loc5_10.5.A, i32 0, i32 0, !dbg !22
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @U.val.loc5_10.9, i64 8, i1 false), !dbg !21
// CHECK:STDOUT:   ret void, !dbg !21
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CB.U.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc5_10.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !25
// CHECK:STDOUT:   %.loc5_10.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !25
// CHECK:STDOUT:   %.loc5_10.5.B = getelementptr inbounds nuw [4 x i8], ptr %.loc5_10.4.payload, i32 0, i32 0, !dbg !25
// CHECK:STDOUT:   %.loc8_1.2.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !25
// CHECK:STDOUT:   store { i32 } %.loc8_1.2.tuple.init, ptr %.loc5_10.5.B, align 4, !dbg !25
// CHECK:STDOUT:   store i8 1, ptr %.loc5_10.1.discriminant, align 1, !dbg !25
// CHECK:STDOUT:   ret void, !dbg !25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeA.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CA.U.Main(ptr %return), !dbg !30
// CHECK:STDOUT:   ret void, !dbg !31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeB.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CB.U.Main(ptr %return, i32 %n), !dbg !38
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CClassify.Main(ptr %u) #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc15_20.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %u, i32 0, i32 0, !dbg !47
// CHECK:STDOUT:   %.loc15_20.4 = load i8, ptr %.loc15_20.3.discriminant, align 1, !dbg !47
// CHECK:STDOUT:   %.loc15_20.41 = trunc i8 %.loc15_20.4 to i1, !dbg !47
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15 = icmp eq i1 false, %.loc15_20.41, !dbg !47
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc15, label %match.case.then.loc15, label %match.case.else.loc15, !dbg !47
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc15:                            ; preds = %entry
// CHECK:STDOUT:   %.loc15_20.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %u, i32 0, i32 1, !dbg !47
// CHECK:STDOUT:   %.loc15_20.8.A = getelementptr inbounds nuw [4 x i8], ptr %.loc15_20.7.payload, i32 0, i32 0, !dbg !47
// CHECK:STDOUT:   %tuple.elem0.loc15.tuple.elem = getelementptr inbounds nuw { {} }, ptr %.loc15_20.8.A, i32 0, i32 0, !dbg !47
// CHECK:STDOUT:   call void @_CSink.Main(), !dbg !50
// CHECK:STDOUT:   ret i32 0, !dbg !51
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc15:                            ; preds = %entry
// CHECK:STDOUT:   %.loc19_21.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %u, i32 0, i32 0, !dbg !52
// CHECK:STDOUT:   %.loc19_21.4 = load i8, ptr %.loc19_21.3.discriminant, align 1, !dbg !52
// CHECK:STDOUT:   %.loc19_21.42 = trunc i8 %.loc19_21.4 to i1, !dbg !52
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc19 = icmp eq i1 true, %.loc19_21.42, !dbg !52
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc19, label %match.case.then.loc19, label %match.done, !dbg !52
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc19:                            ; preds = %match.case.else.loc15
// CHECK:STDOUT:   %.loc19_21.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %u, i32 0, i32 1, !dbg !52
// CHECK:STDOUT:   %.loc19_21.8.B = getelementptr inbounds nuw [4 x i8], ptr %.loc19_21.7.payload, i32 0, i32 0, !dbg !52
// CHECK:STDOUT:   %tuple.elem0.loc19.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc19_21.8.B, i32 0, i32 0, !dbg !52
// CHECK:STDOUT:   %.loc19_21.9 = load i32, ptr %tuple.elem0.loc19.tuple.elem, align 4, !dbg !52
// CHECK:STDOUT:   ret i32 %.loc19_21.9, !dbg !55
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc15
// CHECK:STDOUT:   ret i32 -1, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "unit_payload.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{null}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !11 = !{!10}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{!10, !6}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{!6, !10}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "Sink", linkageName: "_CSink.Main", scope: null, file: !4, line: 3, type: !9, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !19 = !DILocation(line: 3, column: 1, scope: !17)
// CHECK:STDOUT: !20 = distinct !DISubprogram(name: "A", linkageName: "_CA.U.Main", scope: null, file: !4, line: 5, type: !12, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !21 = !DILocation(line: 5, column: 1, scope: !20)
// CHECK:STDOUT: !22 = !DILocation(line: 6, column: 11, scope: !20)
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "B", linkageName: "_CB.U.Main", scope: null, file: !4, line: 5, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !26)
// CHECK:STDOUT: !24 = !DILocalVariable(arg: 1, scope: !23, type: !6)
// CHECK:STDOUT: !25 = !DILocation(line: 5, column: 1, scope: !23)
// CHECK:STDOUT: !26 = !{!24}
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "MakeA", linkageName: "_CMakeA.Main", scope: null, file: !4, line: 10, type: !12, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !30 = !DILocation(line: 10, column: 26, scope: !27)
// CHECK:STDOUT: !31 = !DILocation(line: 10, column: 19, scope: !27)
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "MakeB", linkageName: "_CMakeB.Main", scope: null, file: !4, line: 11, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !40)
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !32, type: !6)
// CHECK:STDOUT: !38 = !DILocation(line: 11, column: 32, scope: !32)
// CHECK:STDOUT: !39 = !DILocation(line: 11, column: 25, scope: !32)
// CHECK:STDOUT: !40 = !{!33}
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "Classify", linkageName: "_CClassify.Main", scope: null, file: !4, line: 13, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !58)
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !41, type: !10)
// CHECK:STDOUT: !47 = !DILocation(line: 15, column: 5, scope: !41)
// CHECK:STDOUT: !50 = !DILocation(line: 16, column: 7, scope: !41)
// CHECK:STDOUT: !51 = !DILocation(line: 17, column: 7, scope: !41)
// CHECK:STDOUT: !52 = !DILocation(line: 19, column: 5, scope: !41)
// CHECK:STDOUT: !55 = !DILocation(line: 19, column: 26, scope: !41)
// CHECK:STDOUT: !57 = !DILocation(line: 23, column: 3, scope: !41)
// CHECK:STDOUT: !58 = !{!42}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'control_flow_unit.carbon'
// CHECK:STDOUT: source_filename = "control_flow_unit.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @ControlFlow.val.b51.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @ControlFlow.val.e88.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CSink.Main() #0 !dbg !61 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !63
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeBreak.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !64 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.43b6561684039966(ptr %return), !dbg !67
// CHECK:STDOUT:   ret void, !dbg !68
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeContinue.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !69 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.43b6561684039966(ptr %return, i32 %n), !dbg !75
// CHECK:STDOUT:   ret void, !dbg !76
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CClassify.Main(ptr %c) #0 !dbg !78 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc15_28.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %c, i32 0, i32 0, !dbg !84
// CHECK:STDOUT:   %.loc15_28.4 = load i8, ptr %.loc15_28.3.discriminant, align 1, !dbg !84
// CHECK:STDOUT:   %.loc15_28.41 = trunc i8 %.loc15_28.4 to i1, !dbg !84
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15 = icmp eq i1 false, %.loc15_28.41, !dbg !84
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc15, label %match.case.then.loc15, label %match.case.else.loc15, !dbg !84
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc15:                            ; preds = %entry
// CHECK:STDOUT:   %.loc15_28.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %c, i32 0, i32 1, !dbg !84
// CHECK:STDOUT:   %.loc15_28.8.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc15_28.7.payload, i32 0, i32 0, !dbg !84
// CHECK:STDOUT:   %tuple.elem0.loc15.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc15_28.8.Continue, i32 0, i32 0, !dbg !84
// CHECK:STDOUT:   %.loc15_28.9 = load i32, ptr %tuple.elem0.loc15.tuple.elem, align 4, !dbg !84
// CHECK:STDOUT:   ret i32 %.loc15_28.9, !dbg !87
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc15:                            ; preds = %entry
// CHECK:STDOUT:   %.loc16_24.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %c, i32 0, i32 0, !dbg !88
// CHECK:STDOUT:   %.loc16_24.4 = load i8, ptr %.loc16_24.3.discriminant, align 1, !dbg !88
// CHECK:STDOUT:   %.loc16_24.42 = trunc i8 %.loc16_24.4 to i1, !dbg !88
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc16 = icmp eq i1 true, %.loc16_24.42, !dbg !88
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc16, label %match.case.then.loc16, label %match.done, !dbg !88
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc16:                            ; preds = %match.case.else.loc15
// CHECK:STDOUT:   %.loc16_24.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %c, i32 0, i32 1, !dbg !88
// CHECK:STDOUT:   %.loc16_24.8.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc16_24.7.payload, i32 0, i32 0, !dbg !88
// CHECK:STDOUT:   %tuple.elem0.loc16.tuple.elem = getelementptr inbounds nuw { {} }, ptr %.loc16_24.8.Break, i32 0, i32 0, !dbg !88
// CHECK:STDOUT:   call void @_CSink.Main(), !dbg !91
// CHECK:STDOUT:   ret i32 -1, !dbg !92
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc15
// CHECK:STDOUT:   ret i32 -2, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.43b6561684039966(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !97 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !98
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !98
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !98
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.b51.anon, i64 8, i1 false), !dbg !98
// CHECK:STDOUT:   store { {} } poison, ptr %Break, align 1, !dbg !98
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Break, i32 0, i32 0, !dbg !98
// CHECK:STDOUT:   ret void, !dbg !98
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.43b6561684039966(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !99 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !101
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !101
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !101
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !102
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.e88.anon, i64 8, i1 false), !dbg !101
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !101
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !102
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !102
// CHECK:STDOUT:   ret void, !dbg !101
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!60}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{null}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !11 = !{!10}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{!10, !6}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{!6, !10}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !59 = !DIFile(filename: "control_flow_unit.carbon", directory: "")
// CHECK:STDOUT: !60 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !59, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !61 = distinct !DISubprogram(name: "Sink", linkageName: "_CSink.Main", scope: null, file: !59, line: 3, type: !9, spFlags: DISPFlagDefinition, unit: !60)
// CHECK:STDOUT: !63 = !DILocation(line: 3, column: 1, scope: !61)
// CHECK:STDOUT: !64 = distinct !DISubprogram(name: "MakeBreak", linkageName: "_CMakeBreak.Main", scope: null, file: !59, line: 5, type: !12, spFlags: DISPFlagDefinition, unit: !60)
// CHECK:STDOUT: !67 = !DILocation(line: 6, column: 10, scope: !64)
// CHECK:STDOUT: !68 = !DILocation(line: 6, column: 3, scope: !64)
// CHECK:STDOUT: !69 = distinct !DISubprogram(name: "MakeContinue", linkageName: "_CMakeContinue.Main", scope: null, file: !59, line: 9, type: !14, spFlags: DISPFlagDefinition, unit: !60, retainedNodes: !77)
// CHECK:STDOUT: !70 = !DILocalVariable(arg: 1, scope: !69, type: !6)
// CHECK:STDOUT: !75 = !DILocation(line: 10, column: 10, scope: !69)
// CHECK:STDOUT: !76 = !DILocation(line: 10, column: 3, scope: !69)
// CHECK:STDOUT: !77 = !{!70}
// CHECK:STDOUT: !78 = distinct !DISubprogram(name: "Classify", linkageName: "_CClassify.Main", scope: null, file: !59, line: 13, type: !16, spFlags: DISPFlagDefinition, unit: !60, retainedNodes: !95)
// CHECK:STDOUT: !79 = !DILocalVariable(arg: 1, scope: !78, type: !10)
// CHECK:STDOUT: !84 = !DILocation(line: 15, column: 5, scope: !78)
// CHECK:STDOUT: !87 = !DILocation(line: 15, column: 33, scope: !78)
// CHECK:STDOUT: !88 = !DILocation(line: 16, column: 5, scope: !78)
// CHECK:STDOUT: !91 = !DILocation(line: 17, column: 7, scope: !78)
// CHECK:STDOUT: !92 = !DILocation(line: 18, column: 7, scope: !78)
// CHECK:STDOUT: !94 = !DILocation(line: 23, column: 3, scope: !78)
// CHECK:STDOUT: !95 = !{!79}
// CHECK:STDOUT: !96 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !97 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.43b6561684039966", scope: null, file: !96, line: 21, type: !12, spFlags: DISPFlagDefinition, unit: !60)
// CHECK:STDOUT: !98 = !DILocation(line: 21, column: 1, scope: !97)
// CHECK:STDOUT: !99 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.43b6561684039966", scope: null, file: !96, line: 21, type: !14, spFlags: DISPFlagDefinition, unit: !60, retainedNodes: !103)
// CHECK:STDOUT: !100 = !DILocalVariable(arg: 1, scope: !99, type: !6)
// CHECK:STDOUT: !101 = !DILocation(line: 21, column: 1, scope: !99)
// CHECK:STDOUT: !102 = !DILocation(line: 22, column: 21, scope: !99)
// CHECK:STDOUT: !103 = !{!100}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'multi_unit_payload.carbon'
// CHECK:STDOUT: source_filename = "multi_unit_payload.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @V.val.loc5_10.9 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CSink.Main() #0 !dbg !106 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !108
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CC.V.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !109 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc5_10.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !110
// CHECK:STDOUT:   %.loc5_10.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !110
// CHECK:STDOUT:   %.loc5_10.5.C = getelementptr inbounds nuw [4 x i8], ptr %.loc5_10.4.payload, i32 0, i32 0, !dbg !110
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { {}, {} }, ptr %.loc5_10.5.C, i32 0, i32 0, !dbg !111
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { {}, {} }, ptr %.loc5_10.5.C, i32 0, i32 1, !dbg !111
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @V.val.loc5_10.9, i64 8, i1 false), !dbg !110
// CHECK:STDOUT:   ret void, !dbg !110
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CD.V.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !112 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc5_10.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !114
// CHECK:STDOUT:   %.loc5_10.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !114
// CHECK:STDOUT:   %.loc5_10.5.D = getelementptr inbounds nuw [4 x i8], ptr %.loc5_10.4.payload, i32 0, i32 0, !dbg !114
// CHECK:STDOUT:   %.loc8_1.2.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !114
// CHECK:STDOUT:   store { i32 } %.loc8_1.2.tuple.init, ptr %.loc5_10.5.D, align 4, !dbg !114
// CHECK:STDOUT:   store i8 1, ptr %.loc5_10.1.discriminant, align 1, !dbg !114
// CHECK:STDOUT:   ret void, !dbg !114
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeC.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !116 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CC.V.Main(ptr %return), !dbg !119
// CHECK:STDOUT:   ret void, !dbg !120
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeD.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !121 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CD.V.Main(ptr %return, i32 %n), !dbg !127
// CHECK:STDOUT:   ret void, !dbg !128
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CClassify.Main(ptr %v) #0 !dbg !130 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc15_27.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %v, i32 0, i32 0, !dbg !136
// CHECK:STDOUT:   %.loc15_27.4 = load i8, ptr %.loc15_27.3.discriminant, align 1, !dbg !136
// CHECK:STDOUT:   %.loc15_27.41 = trunc i8 %.loc15_27.4 to i1, !dbg !136
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15 = icmp eq i1 false, %.loc15_27.41, !dbg !136
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc15, label %match.case.then.loc15, label %match.case.else.loc15, !dbg !136
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc15:                            ; preds = %entry
// CHECK:STDOUT:   %.loc15_27.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %v, i32 0, i32 1, !dbg !136
// CHECK:STDOUT:   %.loc15_27.8.C = getelementptr inbounds nuw [4 x i8], ptr %.loc15_27.7.payload, i32 0, i32 0, !dbg !136
// CHECK:STDOUT:   %tuple.elem0.loc15.tuple.elem = getelementptr inbounds nuw { {}, {} }, ptr %.loc15_27.8.C, i32 0, i32 0, !dbg !136
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { {}, {} }, ptr %.loc15_27.8.C, i32 0, i32 1, !dbg !136
// CHECK:STDOUT:   call void @_CSink.Main(), !dbg !140
// CHECK:STDOUT:   call void @_CSink.Main(), !dbg !142
// CHECK:STDOUT:   ret i32 0, !dbg !143
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc15:                            ; preds = %entry
// CHECK:STDOUT:   %.loc20_21.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %v, i32 0, i32 0, !dbg !144
// CHECK:STDOUT:   %.loc20_21.4 = load i8, ptr %.loc20_21.3.discriminant, align 1, !dbg !144
// CHECK:STDOUT:   %.loc20_21.42 = trunc i8 %.loc20_21.4 to i1, !dbg !144
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc20 = icmp eq i1 true, %.loc20_21.42, !dbg !144
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc20, label %match.case.then.loc20, label %match.done, !dbg !144
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc20:                            ; preds = %match.case.else.loc15
// CHECK:STDOUT:   %.loc20_21.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %v, i32 0, i32 1, !dbg !144
// CHECK:STDOUT:   %.loc20_21.8.D = getelementptr inbounds nuw [4 x i8], ptr %.loc20_21.7.payload, i32 0, i32 0, !dbg !144
// CHECK:STDOUT:   %tuple.elem0.loc20.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc20_21.8.D, i32 0, i32 0, !dbg !144
// CHECK:STDOUT:   %.loc20_21.9 = load i32, ptr %tuple.elem0.loc20.tuple.elem, align 4, !dbg !144
// CHECK:STDOUT:   ret i32 %.loc20_21.9, !dbg !147
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc15
// CHECK:STDOUT:   ret i32 -1, !dbg !149
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!105}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{null}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !11 = !{!10}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{!10, !6}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{!6, !10}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !104 = !DIFile(filename: "multi_unit_payload.carbon", directory: "")
// CHECK:STDOUT: !105 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !104, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !106 = distinct !DISubprogram(name: "Sink", linkageName: "_CSink.Main", scope: null, file: !104, line: 3, type: !9, spFlags: DISPFlagDefinition, unit: !105)
// CHECK:STDOUT: !108 = !DILocation(line: 3, column: 1, scope: !106)
// CHECK:STDOUT: !109 = distinct !DISubprogram(name: "C", linkageName: "_CC.V.Main", scope: null, file: !104, line: 5, type: !12, spFlags: DISPFlagDefinition, unit: !105)
// CHECK:STDOUT: !110 = !DILocation(line: 5, column: 1, scope: !109)
// CHECK:STDOUT: !111 = !DILocation(line: 6, column: 18, scope: !109)
// CHECK:STDOUT: !112 = distinct !DISubprogram(name: "D", linkageName: "_CD.V.Main", scope: null, file: !104, line: 5, type: !14, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !115)
// CHECK:STDOUT: !113 = !DILocalVariable(arg: 1, scope: !112, type: !6)
// CHECK:STDOUT: !114 = !DILocation(line: 5, column: 1, scope: !112)
// CHECK:STDOUT: !115 = !{!113}
// CHECK:STDOUT: !116 = distinct !DISubprogram(name: "MakeC", linkageName: "_CMakeC.Main", scope: null, file: !104, line: 10, type: !12, spFlags: DISPFlagDefinition, unit: !105)
// CHECK:STDOUT: !119 = !DILocation(line: 10, column: 26, scope: !116)
// CHECK:STDOUT: !120 = !DILocation(line: 10, column: 19, scope: !116)
// CHECK:STDOUT: !121 = distinct !DISubprogram(name: "MakeD", linkageName: "_CMakeD.Main", scope: null, file: !104, line: 11, type: !14, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !129)
// CHECK:STDOUT: !122 = !DILocalVariable(arg: 1, scope: !121, type: !6)
// CHECK:STDOUT: !127 = !DILocation(line: 11, column: 32, scope: !121)
// CHECK:STDOUT: !128 = !DILocation(line: 11, column: 25, scope: !121)
// CHECK:STDOUT: !129 = !{!122}
// CHECK:STDOUT: !130 = distinct !DISubprogram(name: "Classify", linkageName: "_CClassify.Main", scope: null, file: !104, line: 13, type: !16, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !150)
// CHECK:STDOUT: !131 = !DILocalVariable(arg: 1, scope: !130, type: !10)
// CHECK:STDOUT: !136 = !DILocation(line: 15, column: 5, scope: !130)
// CHECK:STDOUT: !140 = !DILocation(line: 16, column: 7, scope: !130)
// CHECK:STDOUT: !142 = !DILocation(line: 17, column: 7, scope: !130)
// CHECK:STDOUT: !143 = !DILocation(line: 18, column: 7, scope: !130)
// CHECK:STDOUT: !144 = !DILocation(line: 20, column: 5, scope: !130)
// CHECK:STDOUT: !147 = !DILocation(line: 20, column: 26, scope: !130)
// CHECK:STDOUT: !149 = !DILocation(line: 24, column: 3, scope: !130)
// CHECK:STDOUT: !150 = !{!131}
// CHECK:STDOUT:

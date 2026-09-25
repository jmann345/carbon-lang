// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/operators/question_generic_final.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/operators/question_generic_final.carbon

// The W72a instantiated-THREADING lower golden (fork/w072/plan.md §3, W72a
// exit criteria): the generic `?` chain under the `final impl` spelling,
// monomorphized at a concrete argument. What this pins: the monomorphized
// continue value FLOWS — the first `?`'s continue value is the second
// `Step` call's argument, and the second's is the final `Ok`
// construction's payload — falsified by a `Discard`-shaped dead value or
// absent flow. Contrast question_generic.carbon and
// question_generic_crossfile.carbon, whose continue values go through the
// deduced `Discard` sink (the non-final idiom's only spelling — the
// permanent negative pins). The destroy-call shape must stay the SAME
// no-op shape as the B2a baseline (question_generic.carbon's falsification
// triad: no non-empty destroy body, no user `Destroy` impl on the
// propagation path, no absent destroy call where the baseline has one) —
// nothing in the destroy path keys on finality (plan §2.2, risk R-4).

// --- thread.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// Returns a value of any type by never returning — the unreachable
// trailing-return helper for generic match-reconstruct bodies
// (fork/b1/plan.md §2.6, dated correction).
fn Diverge(generic T2: type) -> T2 { return Diverge(T2); }

// The doc's own `final` spelling (docs/design/error_handling.md sketches;
// fork/w072/plan.md §0.1 candidate (d)) — what licenses the `: T`
// bindings in `Chain` below.
final impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6).
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

// A generic step: passes `x` through, or fails with the given tag.
fn Step[T: type](x: T, fail: bool, tag: i32) -> MyResult(T, i32) {
  if (fail) { return MyResult(T, i32).Err(tag); }
  return MyResult(T, i32).Ok(x);
}

// The threading chain: each step's input is the PREVIOUS step's threaded
// continue value bound `: T` — the shape the non-final idiom could not
// spell (W-072; the W72b runtime pair arbitrates the same shape with
// payload arithmetic).
fn Chain[T: type](x: T, failA: bool, failB: bool) -> MyResult(T, i32) {
  let a: T = Step(x, failA, 101)?;
  let b: T = Step(a, failB, 202)?;
  return MyResult(T, i32).Ok(b);
}

// The concrete instantiation that lowers the specific's CFG: discriminant
// tests, payload accesses, the threaded value's flow into the second call
// and the `Ok` construction, `FromBreak` calls and early `ret`s on the
// break edges.
fn Call(x: i32, failA: bool, failB: bool) -> MyResult(i32, i32) {
  return Chain(x, failA, failB);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'thread.carbon'
// CHECK:STDOUT: source_filename = "thread.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @MyResult.val.30e.loc3_35.7 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @MyResult.val.df1.loc3_35.7 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @ControlFlow.val.f6c.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @ControlFlow.val.493.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %x, i1 %failA, i1 %failB) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CChain.Main.84588f41d61dafba(ptr %return, i32 %x, i1 %failA, i1 %failB), !dbg !13
// CHECK:STDOUT:   ret void, !dbg !14
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.945345cbed56cb88:core.Destroy.Core"(ptr %self) #0 !dbg !15 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !21
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !22 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.216a6481b641f07b:core.Destroy.Core"(ptr %self) #0 !dbg !28 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.39976c684c12c16f:core.Destroy.Core"(ptr %self) #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !37
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.6f70ad92790b7b3d:core.Destroy.Core"(ptr %self) #0 !dbg !38 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %self) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5716d9c282b70019:core.Destroy.Core"(ptr %self) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.c9ead255f32e7c59:core.Destroy.Core"(ptr %self) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.a214566110020819:core.Destroy.Core"(ptr %self) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CChain.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %x, i1 %failA, i1 %failB) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc40_32.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !63
// CHECK:STDOUT:   %.loc40_33.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !63
// CHECK:STDOUT:   %.loc41_32.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !64
// CHECK:STDOUT:   %.loc41_33.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !64
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc40_32.1.temp), !dbg !63
// CHECK:STDOUT:   call void @_CStep.Main.84588f41d61dafba(ptr %.loc40_32.1.temp, i32 %x, i1 %failA, i32 101), !dbg !63
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc40_33.1.temp), !dbg !63
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %.loc40_33.1.temp, ptr %.loc40_32.1.temp), !dbg !63
// CHECK:STDOUT:   %.loc40_33.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc40_33.1.temp, i32 0, i32 0, !dbg !63
// CHECK:STDOUT:   %.loc40_33.6 = load i8, ptr %.loc40_33.5.discriminant, align 1, !dbg !63
// CHECK:STDOUT:   %.loc40_33.61 = trunc i8 %.loc40_33.6 to i1, !dbg !63
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc40 = icmp eq i1 true, %.loc40_33.61, !dbg !63
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc40, label %.loc40_33.1, label %.loc40_33.2, !dbg !63
// CHECK:STDOUT:
// CHECK:STDOUT: .loc40_33.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc40_33.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc40_33.1.temp, i32 0, i32 1, !dbg !63
// CHECK:STDOUT:   %.loc40_33.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc40_33.9.payload, i32 0, i32 0, !dbg !63
// CHECK:STDOUT:   %tuple.elem0.loc40_33.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc40_33.10.Break, i32 0, i32 0, !dbg !63
// CHECK:STDOUT:   %.loc40_33.11 = load i32, ptr %tuple.elem0.loc40_33.1.tuple.elem, align 4, !dbg !63
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %.loc40_33.11), !dbg !63
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc40_33.1.temp), !dbg !63
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %.loc40_32.1.temp), !dbg !63
// CHECK:STDOUT:   ret void, !dbg !63
// CHECK:STDOUT:
// CHECK:STDOUT: .loc40_33.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc40_33.15.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc40_33.1.temp, i32 0, i32 1, !dbg !63
// CHECK:STDOUT:   %.loc40_33.16.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc40_33.15.payload, i32 0, i32 0, !dbg !63
// CHECK:STDOUT:   %tuple.elem0.loc40_33.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc40_33.16.Continue, i32 0, i32 0, !dbg !63
// CHECK:STDOUT:   %.loc40_33.17 = load i32, ptr %tuple.elem0.loc40_33.2.tuple.elem, align 4, !dbg !63
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc41_32.1.temp), !dbg !64
// CHECK:STDOUT:   call void @_CStep.Main.84588f41d61dafba(ptr %.loc41_32.1.temp, i32 %.loc40_33.17, i1 %failB, i32 202), !dbg !64
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc41_33.1.temp), !dbg !64
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %.loc41_33.1.temp, ptr %.loc41_32.1.temp), !dbg !64
// CHECK:STDOUT:   %.loc41_33.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc41_33.1.temp, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   %.loc41_33.6 = load i8, ptr %.loc41_33.5.discriminant, align 1, !dbg !64
// CHECK:STDOUT:   %.loc41_33.62 = trunc i8 %.loc41_33.6 to i1, !dbg !64
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc41 = icmp eq i1 true, %.loc41_33.62, !dbg !64
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc41, label %.loc41_33.1, label %.loc41_33.2, !dbg !64
// CHECK:STDOUT:
// CHECK:STDOUT: .loc41_33.1:                                      ; preds = %.loc40_33.2
// CHECK:STDOUT:   %.loc41_33.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc41_33.1.temp, i32 0, i32 1, !dbg !64
// CHECK:STDOUT:   %.loc41_33.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc41_33.9.payload, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   %tuple.elem0.loc41_33.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc41_33.10.Break, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   %.loc41_33.11 = load i32, ptr %tuple.elem0.loc41_33.1.tuple.elem, align 4, !dbg !64
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %.loc41_33.11), !dbg !64
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc41_33.1.temp), !dbg !64
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %.loc41_32.1.temp), !dbg !64
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc40_33.1.temp), !dbg !63
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %.loc40_32.1.temp), !dbg !63
// CHECK:STDOUT:   ret void, !dbg !64
// CHECK:STDOUT:
// CHECK:STDOUT: .loc41_33.2:                                      ; preds = %.loc40_33.2
// CHECK:STDOUT:   %.loc41_33.15.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc41_33.1.temp, i32 0, i32 1, !dbg !64
// CHECK:STDOUT:   %.loc41_33.16.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc41_33.15.payload, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   %tuple.elem0.loc41_33.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc41_33.16.Continue, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   %.loc41_33.17 = load i32, ptr %tuple.elem0.loc41_33.2.tuple.elem, align 4, !dbg !64
// CHECK:STDOUT:   call void @_COk.MyResult.Main.8122a03446648385(ptr %return, i32 %.loc41_33.17), !dbg !65
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc41_33.1.temp), !dbg !64
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %.loc41_32.1.temp), !dbg !64
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc40_33.1.temp), !dbg !63
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %.loc40_32.1.temp), !dbg !63
// CHECK:STDOUT:   ret void, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CStep.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %x, i1 %fail, i32 %tag) #0 !dbg !67 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 %fail, label %if.then, label %if.else, !dbg !74
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %tag), !dbg !75
// CHECK:STDOUT:   ret void, !dbg !76
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_COk.MyResult.Main.8122a03446648385(ptr %return, i32 %x), !dbg !77
// CHECK:STDOUT:   ret void, !dbg !78
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !79 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc20_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !84
// CHECK:STDOUT:   %.loc20_22.4 = load i8, ptr %.loc20_22.3.discriminant, align 1, !dbg !84
// CHECK:STDOUT:   %.loc20_22.41 = trunc i8 %.loc20_22.4 to i1, !dbg !84
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc20 = icmp eq i1 false, %.loc20_22.41, !dbg !84
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc20, label %match.case.then.loc20, label %match.case.else.loc20, !dbg !84
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc20:                            ; preds = %entry
// CHECK:STDOUT:   %.loc20_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !84
// CHECK:STDOUT:   %.loc20_22.8.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc20_22.7.payload, i32 0, i32 0, !dbg !84
// CHECK:STDOUT:   %tuple.elem0.loc20.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc20_22.8.Ok, i32 0, i32 0, !dbg !84
// CHECK:STDOUT:   %.loc20_22.9 = load i32, ptr %tuple.elem0.loc20.tuple.elem, align 4, !dbg !84
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc20_22.9), !dbg !85
// CHECK:STDOUT:   ret void, !dbg !86
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc20:                            ; preds = %entry
// CHECK:STDOUT:   %.loc21_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !87
// CHECK:STDOUT:   %.loc21_23.4 = load i8, ptr %.loc21_23.3.discriminant, align 1, !dbg !87
// CHECK:STDOUT:   %.loc21_23.42 = trunc i8 %.loc21_23.4 to i1, !dbg !87
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc21 = icmp eq i1 true, %.loc21_23.42, !dbg !87
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc21, label %match.case.then.loc21, label %match.done, !dbg !87
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc21:                            ; preds = %match.case.else.loc20
// CHECK:STDOUT:   %.loc21_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !87
// CHECK:STDOUT:   %.loc21_23.8.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc21_23.7.payload, i32 0, i32 0, !dbg !87
// CHECK:STDOUT:   %tuple.elem0.loc21.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc21_23.8.Err, i32 0, i32 0, !dbg !87
// CHECK:STDOUT:   %.loc21_23.9 = load i32, ptr %tuple.elem0.loc21.tuple.elem, align 4, !dbg !87
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc21_23.9), !dbg !88
// CHECK:STDOUT:   ret void, !dbg !89
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc20
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !90
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %e) #0 !dbg !92 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %e), !dbg !97
// CHECK:STDOUT:   ret void, !dbg !98
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !99 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !102
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !102
// CHECK:STDOUT:   %.loc3_35.5.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !102
// CHECK:STDOUT:   %.loc4_11.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !103
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.30e.loc3_35.7, i64 8, i1 false), !dbg !102
// CHECK:STDOUT:   store { i32 } %.loc4_11.1.tuple.init, ptr %.loc3_35.5.Ok, align 4, !dbg !102
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Ok, i32 0, i32 0, !dbg !103
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !103
// CHECK:STDOUT:   ret void, !dbg !102
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !104 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !107
// CHECK:STDOUT:   %.loc3_35.5.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   %.loc6_1.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !107
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.df1.loc3_35.7, i64 8, i1 false), !dbg !107
// CHECK:STDOUT:   store { i32 } %.loc6_1.1.tuple.init, ptr %.loc3_35.5.Err, align 4, !dbg !107
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Err, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !107
// CHECK:STDOUT:   ret void, !dbg !107
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !108 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !112
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !112
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !112
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !113
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.f6c.anon, i64 8, i1 false), !dbg !112
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !112
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !113
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !113
// CHECK:STDOUT:   ret void, !dbg !112
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !114 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !117
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !117
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.493.anon, i64 8, i1 false), !dbg !117
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !117
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !117
// CHECK:STDOUT:   ret void, !dbg !117
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.9bba81283511934f(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !118 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !121
// CHECK:STDOUT:   ret void, !dbg !122
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CStep.Main.84588f41d61dafba, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_COk.MyResult.Main.8122a03446648385, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CErr.MyResult.Main.8122a03446648385, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 3, 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "thread.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !1, line: 49, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8, !7, !7}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10, !11, !12}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocalVariable(arg: 2, scope: !4, type: !7)
// CHECK:STDOUT: !12 = !DILocalVariable(arg: 3, scope: !4, type: !7)
// CHECK:STDOUT: !13 = !DILocation(line: 50, column: 10, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 50, column: 3, scope: !4)
// CHECK:STDOUT: !15 = distinct !DISubprogram(name: "Op", linkageName: "_COp.945345cbed56cb88:core.Destroy.Core", scope: null, file: !1, line: 40, type: !16, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !19)
// CHECK:STDOUT: !16 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !17 = !{null, !18}
// CHECK:STDOUT: !18 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !19 = !{!20}
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !15, type: !18)
// CHECK:STDOUT: !21 = !DILocation(line: 40, column: 14, scope: !15)
// CHECK:STDOUT: !22 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 40, type: !23, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !25)
// CHECK:STDOUT: !23 = !DISubroutineType(types: !24)
// CHECK:STDOUT: !24 = !{null, !8}
// CHECK:STDOUT: !25 = !{!26}
// CHECK:STDOUT: !26 = !DILocalVariable(arg: 1, scope: !22, type: !8)
// CHECK:STDOUT: !27 = !DILocation(line: 40, column: 14, scope: !22)
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "Op", linkageName: "_COp.216a6481b641f07b:core.Destroy.Core", scope: null, file: !1, line: 40, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !31)
// CHECK:STDOUT: !29 = !DISubroutineType(types: !30)
// CHECK:STDOUT: !30 = !{null, !7}
// CHECK:STDOUT: !31 = !{!32}
// CHECK:STDOUT: !32 = !DILocalVariable(arg: 1, scope: !28, type: !7)
// CHECK:STDOUT: !33 = !DILocation(line: 40, column: 14, scope: !28)
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "Op", linkageName: "_COp.39976c684c12c16f:core.Destroy.Core", scope: null, file: !1, line: 40, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !35)
// CHECK:STDOUT: !35 = !{!36}
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !34, type: !7)
// CHECK:STDOUT: !37 = !DILocation(line: 40, column: 14, scope: !34)
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "Op", linkageName: "_COp.6f70ad92790b7b3d:core.Destroy.Core", scope: null, file: !1, line: 40, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !39)
// CHECK:STDOUT: !39 = !{!40}
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !38, type: !7)
// CHECK:STDOUT: !41 = !DILocation(line: 40, column: 14, scope: !38)
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "Op", linkageName: "_COp.51939fc15d8db062:core.Destroy.Core", scope: null, file: !1, line: 40, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !43)
// CHECK:STDOUT: !43 = !{!44}
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !42, type: !7)
// CHECK:STDOUT: !45 = !DILocation(line: 40, column: 14, scope: !42)
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5716d9c282b70019:core.Destroy.Core", scope: null, file: !1, line: 40, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !47)
// CHECK:STDOUT: !47 = !{!48}
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !46, type: !7)
// CHECK:STDOUT: !49 = !DILocation(line: 40, column: 14, scope: !46)
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "Op", linkageName: "_COp.c9ead255f32e7c59:core.Destroy.Core", scope: null, file: !1, line: 40, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !51)
// CHECK:STDOUT: !51 = !{!52}
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !50, type: !7)
// CHECK:STDOUT: !53 = !DILocation(line: 40, column: 14, scope: !50)
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "Op", linkageName: "_COp.a214566110020819:core.Destroy.Core", scope: null, file: !1, line: 40, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !55)
// CHECK:STDOUT: !55 = !{!56}
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !54, type: !7)
// CHECK:STDOUT: !57 = !DILocation(line: 40, column: 14, scope: !54)
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "Chain", linkageName: "_CChain.Main.84588f41d61dafba", scope: null, file: !1, line: 39, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !59)
// CHECK:STDOUT: !59 = !{!60, !61, !62}
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !58, type: !8)
// CHECK:STDOUT: !61 = !DILocalVariable(arg: 2, scope: !58, type: !7)
// CHECK:STDOUT: !62 = !DILocalVariable(arg: 3, scope: !58, type: !7)
// CHECK:STDOUT: !63 = !DILocation(line: 40, column: 14, scope: !58)
// CHECK:STDOUT: !64 = !DILocation(line: 41, column: 14, scope: !58)
// CHECK:STDOUT: !65 = !DILocation(line: 42, column: 10, scope: !58)
// CHECK:STDOUT: !66 = !DILocation(line: 42, column: 3, scope: !58)
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "Step", linkageName: "_CStep.Main.84588f41d61dafba", scope: null, file: !1, line: 30, type: !68, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !70)
// CHECK:STDOUT: !68 = !DISubroutineType(types: !69)
// CHECK:STDOUT: !69 = !{!7, !8, !7, !8}
// CHECK:STDOUT: !70 = !{!71, !72, !73}
// CHECK:STDOUT: !71 = !DILocalVariable(arg: 1, scope: !67, type: !8)
// CHECK:STDOUT: !72 = !DILocalVariable(arg: 2, scope: !67, type: !7)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 3, scope: !67, type: !8)
// CHECK:STDOUT: !74 = !DILocation(line: 31, column: 6, scope: !67)
// CHECK:STDOUT: !75 = !DILocation(line: 31, column: 22, scope: !67)
// CHECK:STDOUT: !76 = !DILocation(line: 31, column: 15, scope: !67)
// CHECK:STDOUT: !77 = !DILocation(line: 32, column: 10, scope: !67)
// CHECK:STDOUT: !78 = !DILocation(line: 32, column: 3, scope: !67)
// CHECK:STDOUT: !79 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !1, line: 18, type: !80, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !82)
// CHECK:STDOUT: !80 = !DISubroutineType(types: !81)
// CHECK:STDOUT: !81 = !{!7, !7}
// CHECK:STDOUT: !82 = !{!83}
// CHECK:STDOUT: !83 = !DILocalVariable(arg: 1, scope: !79, type: !7)
// CHECK:STDOUT: !84 = !DILocation(line: 20, column: 7, scope: !79)
// CHECK:STDOUT: !85 = !DILocation(line: 20, column: 34, scope: !79)
// CHECK:STDOUT: !86 = !DILocation(line: 20, column: 27, scope: !79)
// CHECK:STDOUT: !87 = !DILocation(line: 21, column: 7, scope: !79)
// CHECK:STDOUT: !88 = !DILocation(line: 21, column: 35, scope: !79)
// CHECK:STDOUT: !89 = !DILocation(line: 21, column: 28, scope: !79)
// CHECK:STDOUT: !90 = !DILocation(line: 24, column: 12, scope: !79)
// CHECK:STDOUT: !91 = !DILocation(line: 24, column: 5, scope: !79)
// CHECK:STDOUT: !92 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !1, line: 26, type: !93, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !95)
// CHECK:STDOUT: !93 = !DISubroutineType(types: !94)
// CHECK:STDOUT: !94 = !{!7, !8}
// CHECK:STDOUT: !95 = !{!96}
// CHECK:STDOUT: !96 = !DILocalVariable(arg: 1, scope: !92, type: !8)
// CHECK:STDOUT: !97 = !DILocation(line: 26, column: 39, scope: !92)
// CHECK:STDOUT: !98 = !DILocation(line: 26, column: 32, scope: !92)
// CHECK:STDOUT: !99 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.MyResult.Main.8122a03446648385", scope: null, file: !1, line: 3, type: !93, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !100)
// CHECK:STDOUT: !100 = !{!101}
// CHECK:STDOUT: !101 = !DILocalVariable(arg: 1, scope: !99, type: !8)
// CHECK:STDOUT: !102 = !DILocation(line: 3, column: 1, scope: !99)
// CHECK:STDOUT: !103 = !DILocation(line: 4, column: 11, scope: !99)
// CHECK:STDOUT: !104 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.8122a03446648385", scope: null, file: !1, line: 3, type: !93, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !105)
// CHECK:STDOUT: !105 = !{!106}
// CHECK:STDOUT: !106 = !DILocalVariable(arg: 1, scope: !104, type: !8)
// CHECK:STDOUT: !107 = !DILocation(line: 3, column: 1, scope: !104)
// CHECK:STDOUT: !108 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.8122a03446648385", scope: null, file: !109, line: 21, type: !93, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !110)
// CHECK:STDOUT: !109 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !110 = !{!111}
// CHECK:STDOUT: !111 = !DILocalVariable(arg: 1, scope: !108, type: !8)
// CHECK:STDOUT: !112 = !DILocation(line: 21, column: 1, scope: !108)
// CHECK:STDOUT: !113 = !DILocation(line: 22, column: 21, scope: !108)
// CHECK:STDOUT: !114 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.8122a03446648385", scope: null, file: !109, line: 21, type: !93, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !115)
// CHECK:STDOUT: !115 = !{!116}
// CHECK:STDOUT: !116 = !DILocalVariable(arg: 1, scope: !114, type: !8)
// CHECK:STDOUT: !117 = !DILocation(line: 21, column: 1, scope: !114)
// CHECK:STDOUT: !118 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.9bba81283511934f", scope: null, file: !1, line: 11, type: !119, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !119 = !DISubroutineType(types: !120)
// CHECK:STDOUT: !120 = !{!7}
// CHECK:STDOUT: !121 = !DILocation(line: 11, column: 45, scope: !118)
// CHECK:STDOUT: !122 = !DILocation(line: 11, column: 38, scope: !118)
// CHECK:STDOUT:

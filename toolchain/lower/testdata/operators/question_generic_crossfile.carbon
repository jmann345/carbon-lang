// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/operators/question_generic_crossfile.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/operators/question_generic_crossfile.carbon

// The CROSS-FILE mixed-width instantiated-generic `?` golden: the generic
// chain lives in an imported library while BOTH width instantiations —
// narrow (i32) first, then wide (i64) — happen in the importing file, and
// every `?` operand is a CALL-RESULT temporary (`Step(x, ...)?` through
// the proven `Discard` sink), the two properties that separate the
// question_generic_diff conformance program from the single-file golden
// (question_generic_mixed.carbon). What this pins, in use.carbon's module:
// every function of the chain (Chain, Step, the Try impl's
// Branch/FromBreak, the Err/Ok constructors, the ControlFlow constructors)
// must have TWO distinct lowered defines with correct per-width shapes —
// the i64 leg's carrier and result objects 16 bytes
// (`<{ <{ i1, [7 x i8] }>, [8 x i8] }>`, payload at byte 8, covering
// copies of 16), the i32 leg's 8 bytes — and every wide call site
// (Call64's chain, MakeErr64, ReadErr64) must address only wide defines.
// History: authored as the round-2 H-ZERO probe (the hypothesis that the
// specific coalescer's per-file fingerprint stores read absent slots as
// the all-zero default, wrongly coalescing cross-width specifics). Its own
// regen showed per-width-CORRECT lowering — two defines per function,
// correct shapes — helping refute H-ZERO as the runtime cause. The actual
// root cause of the question_generic_diff divergence was the poison filler
// in covering-copied constant templates (fork/b2/mixed-width-diagnosis.md),
// fixed in lower/constant.cpp.

// --- lib.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// Returns a value of any type by never returning — the unreachable
// trailing-return helper for generic match-reconstruct bodies
// (fork/b1/plan.md §2.6, dated correction).
fn Diverge(generic T2: type) -> T2 { return Diverge(T2); }

impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6, dated
    // correction).
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

// A generic step: passes `x` through, or fails with the given tag — the
// maker whose call results are the `?` operand temporaries below.
fn Step[T: type](x: T, fail: bool, tag: i32) -> MyResult(T, i32) {
  if (fail) { return MyResult(T, i32).Err(tag); }
  return MyResult(T, i32).Ok(x);
}

// Payload sink — the check golden's proven deduced-sink shape
// (toolchain/check/testdata/operators/question.carbon `Discard`).
fn Discard[U: type](_: U) {}

// The generic `?` chain with CALL-RESULT-temporary operands (the failing
// conformance program's shape, fork/conformance/programs/error_handling/
// question_generic_diff.carbon `Chain`).
fn Chain[T: type](x: T, failA: bool, failB: bool) -> MyResult(T, i32) {
  Discard(Step(x, failA, 101)?);
  Discard(Step(x, failB, 202)?);
  return MyResult(T, i32).Ok(x);
}

// The library's own narrow instantiation: the narrow specifics' LLVM
// functions exist in lib's module under their canonical mangled names, so
// the importing file's references to the SAME specifics take the
// already-created path.
fn LibCall32(x: i32, failA: bool, failB: bool) -> MyResult(i32, i32) {
  return Chain(x, failA, failB);
}

// --- use.carbon
library "[[@TEST_NAME]]";

import library "lib";

// Narrow first, wide second — the failing program's instantiation order.
fn Call32(x: i32, failA: bool, failB: bool) -> MyResult(i32, i32) {
  return Chain(x, failA, failB);
}

fn Call64(x: i64, failA: bool, failB: bool) -> MyResult(i64, i32) {
  return Chain(x, failA, failB);
}

// Concrete narrow-alternative writer for the wide specific: the `Err`
// constructor call whose covering copy and element stores this golden
// pins.
fn MakeErr64(tag: i32) -> MyResult(i64, i32) {
  return MyResult(i64, i32).Err(tag);
}

// Concrete reader: the payload load must address the same 16-byte object
// the writer initialized.
fn ReadErr64(r: MyResult(i64, i32)) -> i32 {
  match (r) {
    // CHECK:STDERR: use.carbon:[[@LINE+4]]:14: warning: binding `v` unused [UnusedBinding]
    // CHECK:STDERR:     case .Ok(v: i64) => { return 0; }
    // CHECK:STDERR:              ^~~~~~
    // CHECK:STDERR:
    case .Ok(v: i64) => { return 0; }
    case .Err(e: i32) => { return e; }
  }
  // Unreachable: every arm returns.
  return -1;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'lib.carbon'
// CHECK:STDOUT: source_filename = "lib.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @MyResult.val.30e.loc3_35.7 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @MyResult.val.df1.loc3_35.7 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @ControlFlow.val.f6c.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @ControlFlow.val.493.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CLibCall32.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %x, i1 %failA, i1 %failB) #0 !dbg !4 {
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
// CHECK:STDOUT:   %.loc42_29.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !63
// CHECK:STDOUT:   %.loc42_30.3.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !63
// CHECK:STDOUT:   %.loc43_29.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !64
// CHECK:STDOUT:   %.loc43_30.3.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !64
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc42_29.1.temp), !dbg !63
// CHECK:STDOUT:   call void @_CStep.Main.84588f41d61dafba(ptr %.loc42_29.1.temp, i32 %x, i1 %failA, i32 101), !dbg !63
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc42_30.3.temp), !dbg !63
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %.loc42_30.3.temp, ptr %.loc42_29.1.temp), !dbg !63
// CHECK:STDOUT:   %.loc42_30.7.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc42_30.3.temp, i32 0, i32 0, !dbg !63
// CHECK:STDOUT:   %.loc42_30.8 = load i8, ptr %.loc42_30.7.discriminant, align 1, !dbg !63
// CHECK:STDOUT:   %.loc42_30.81 = trunc i8 %.loc42_30.8 to i1, !dbg !63
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc42 = icmp eq i1 true, %.loc42_30.81, !dbg !63
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc42, label %.loc42_30.1, label %.loc42_30.2, !dbg !63
// CHECK:STDOUT:
// CHECK:STDOUT: .loc42_30.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc42_30.11.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc42_30.3.temp, i32 0, i32 1, !dbg !63
// CHECK:STDOUT:   %.loc42_30.12.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc42_30.11.payload, i32 0, i32 0, !dbg !63
// CHECK:STDOUT:   %tuple.elem0.loc42_30.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc42_30.12.Break, i32 0, i32 0, !dbg !63
// CHECK:STDOUT:   %.loc42_30.13 = load i32, ptr %tuple.elem0.loc42_30.1.tuple.elem, align 4, !dbg !63
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %.loc42_30.13), !dbg !63
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc42_30.3.temp), !dbg !63
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %.loc42_29.1.temp), !dbg !63
// CHECK:STDOUT:   ret void, !dbg !63
// CHECK:STDOUT:
// CHECK:STDOUT: .loc42_30.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc42_30.17.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc42_30.3.temp, i32 0, i32 1, !dbg !63
// CHECK:STDOUT:   %.loc42_30.18.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc42_30.17.payload, i32 0, i32 0, !dbg !63
// CHECK:STDOUT:   %tuple.elem0.loc42_30.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc42_30.18.Continue, i32 0, i32 0, !dbg !63
// CHECK:STDOUT:   %.loc42_30.19 = load i32, ptr %tuple.elem0.loc42_30.2.tuple.elem, align 4, !dbg !63
// CHECK:STDOUT:   call void @_CDiscard.Main.84588f41d61dafba(i32 %.loc42_30.19), !dbg !65
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc42_30.3.temp), !dbg !63
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %.loc42_29.1.temp), !dbg !63
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc43_29.1.temp), !dbg !64
// CHECK:STDOUT:   call void @_CStep.Main.84588f41d61dafba(ptr %.loc43_29.1.temp, i32 %x, i1 %failB, i32 202), !dbg !64
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc43_30.3.temp), !dbg !64
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %.loc43_30.3.temp, ptr %.loc43_29.1.temp), !dbg !64
// CHECK:STDOUT:   %.loc43_30.7.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc43_30.3.temp, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   %.loc43_30.8 = load i8, ptr %.loc43_30.7.discriminant, align 1, !dbg !64
// CHECK:STDOUT:   %.loc43_30.82 = trunc i8 %.loc43_30.8 to i1, !dbg !64
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc43 = icmp eq i1 true, %.loc43_30.82, !dbg !64
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc43, label %.loc43_30.1, label %.loc43_30.2, !dbg !64
// CHECK:STDOUT:
// CHECK:STDOUT: .loc43_30.1:                                      ; preds = %.loc42_30.2
// CHECK:STDOUT:   %.loc43_30.11.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc43_30.3.temp, i32 0, i32 1, !dbg !64
// CHECK:STDOUT:   %.loc43_30.12.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc43_30.11.payload, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   %tuple.elem0.loc43_30.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc43_30.12.Break, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   %.loc43_30.13 = load i32, ptr %tuple.elem0.loc43_30.1.tuple.elem, align 4, !dbg !64
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %.loc43_30.13), !dbg !64
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc43_30.3.temp), !dbg !64
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %.loc43_29.1.temp), !dbg !64
// CHECK:STDOUT:   ret void, !dbg !64
// CHECK:STDOUT:
// CHECK:STDOUT: .loc43_30.2:                                      ; preds = %.loc42_30.2
// CHECK:STDOUT:   %.loc43_30.17.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc43_30.3.temp, i32 0, i32 1, !dbg !64
// CHECK:STDOUT:   %.loc43_30.18.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc43_30.17.payload, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   %tuple.elem0.loc43_30.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc43_30.18.Continue, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   %.loc43_30.19 = load i32, ptr %tuple.elem0.loc43_30.2.tuple.elem, align 4, !dbg !64
// CHECK:STDOUT:   call void @_CDiscard.Main.84588f41d61dafba(i32 %.loc43_30.19), !dbg !66
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc43_30.3.temp), !dbg !64
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %.loc43_29.1.temp), !dbg !64
// CHECK:STDOUT:   call void @_COk.MyResult.Main.8122a03446648385(ptr %return, i32 %x), !dbg !67
// CHECK:STDOUT:   ret void, !dbg !68
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CStep.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %x, i1 %fail, i32 %tag) #0 !dbg !69 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 %fail, label %if.then, label %if.else, !dbg !76
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %tag), !dbg !77
// CHECK:STDOUT:   ret void, !dbg !78
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_COk.MyResult.Main.8122a03446648385(ptr %return, i32 %x), !dbg !79
// CHECK:STDOUT:   ret void, !dbg !80
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !81 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !86
// CHECK:STDOUT:   %.loc17_22.4 = load i8, ptr %.loc17_22.3.discriminant, align 1, !dbg !86
// CHECK:STDOUT:   %.loc17_22.41 = trunc i8 %.loc17_22.4 to i1, !dbg !86
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc17 = icmp eq i1 false, %.loc17_22.41, !dbg !86
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc17, label %match.case.then.loc17, label %match.case.else.loc17, !dbg !86
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc17_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !86
// CHECK:STDOUT:   %.loc17_22.8.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc17_22.7.payload, i32 0, i32 0, !dbg !86
// CHECK:STDOUT:   %tuple.elem0.loc17.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc17_22.8.Ok, i32 0, i32 0, !dbg !86
// CHECK:STDOUT:   %.loc17_22.9 = load i32, ptr %tuple.elem0.loc17.tuple.elem, align 4, !dbg !86
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc17_22.9), !dbg !87
// CHECK:STDOUT:   ret void, !dbg !88
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc18_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !89
// CHECK:STDOUT:   %.loc18_23.4 = load i8, ptr %.loc18_23.3.discriminant, align 1, !dbg !89
// CHECK:STDOUT:   %.loc18_23.42 = trunc i8 %.loc18_23.4 to i1, !dbg !89
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc18 = icmp eq i1 true, %.loc18_23.42, !dbg !89
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc18, label %match.case.then.loc18, label %match.done, !dbg !89
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc18:                            ; preds = %match.case.else.loc17
// CHECK:STDOUT:   %.loc18_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !89
// CHECK:STDOUT:   %.loc18_23.8.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc18_23.7.payload, i32 0, i32 0, !dbg !89
// CHECK:STDOUT:   %tuple.elem0.loc18.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc18_23.8.Err, i32 0, i32 0, !dbg !89
// CHECK:STDOUT:   %.loc18_23.9 = load i32, ptr %tuple.elem0.loc18.tuple.elem, align 4, !dbg !89
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc18_23.9), !dbg !90
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc17
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !92
// CHECK:STDOUT:   ret void, !dbg !93
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %e) #0 !dbg !94 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %e), !dbg !99
// CHECK:STDOUT:   ret void, !dbg !100
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiscard.Main.84588f41d61dafba(i32 %_) #0 !dbg !101 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !104
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !105 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !108
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !108
// CHECK:STDOUT:   %.loc3_35.5.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !108
// CHECK:STDOUT:   %.loc4_11.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !109
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.30e.loc3_35.7, i64 8, i1 false), !dbg !108
// CHECK:STDOUT:   store { i32 } %.loc4_11.1.tuple.init, ptr %.loc3_35.5.Ok, align 4, !dbg !108
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Ok, i32 0, i32 0, !dbg !109
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !109
// CHECK:STDOUT:   ret void, !dbg !108
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !110 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !113
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !113
// CHECK:STDOUT:   %.loc3_35.5.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !113
// CHECK:STDOUT:   %.loc6_1.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !113
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.df1.loc3_35.7, i64 8, i1 false), !dbg !113
// CHECK:STDOUT:   store { i32 } %.loc6_1.1.tuple.init, ptr %.loc3_35.5.Err, align 4, !dbg !113
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Err, i32 0, i32 0, !dbg !113
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !113
// CHECK:STDOUT:   ret void, !dbg !113
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !114 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !118
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !119
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.f6c.anon, i64 8, i1 false), !dbg !118
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !118
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !119
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !119
// CHECK:STDOUT:   ret void, !dbg !118
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !120 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !123
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !123
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !123
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !123
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.493.anon, i64 8, i1 false), !dbg !123
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !123
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !123
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !123
// CHECK:STDOUT:   ret void, !dbg !123
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.9bba81283511934f(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !124 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !127
// CHECK:STDOUT:   ret void, !dbg !128
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
// CHECK:STDOUT: uselistorder ptr @_CDiscard.Main.84588f41d61dafba, { 1, 0 }
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
// CHECK:STDOUT: !1 = !DIFile(filename: "lib.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "LibCall32", linkageName: "_CLibCall32.Main", scope: null, file: !1, line: 51, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8, !7, !7}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10, !11, !12}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocalVariable(arg: 2, scope: !4, type: !7)
// CHECK:STDOUT: !12 = !DILocalVariable(arg: 3, scope: !4, type: !7)
// CHECK:STDOUT: !13 = !DILocation(line: 52, column: 10, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 52, column: 3, scope: !4)
// CHECK:STDOUT: !15 = distinct !DISubprogram(name: "Op", linkageName: "_COp.945345cbed56cb88:core.Destroy.Core", scope: null, file: !1, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !19)
// CHECK:STDOUT: !16 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !17 = !{null, !18}
// CHECK:STDOUT: !18 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !19 = !{!20}
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !15, type: !18)
// CHECK:STDOUT: !21 = !DILocation(line: 42, column: 11, scope: !15)
// CHECK:STDOUT: !22 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 42, type: !23, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !25)
// CHECK:STDOUT: !23 = !DISubroutineType(types: !24)
// CHECK:STDOUT: !24 = !{null, !8}
// CHECK:STDOUT: !25 = !{!26}
// CHECK:STDOUT: !26 = !DILocalVariable(arg: 1, scope: !22, type: !8)
// CHECK:STDOUT: !27 = !DILocation(line: 42, column: 11, scope: !22)
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "Op", linkageName: "_COp.216a6481b641f07b:core.Destroy.Core", scope: null, file: !1, line: 42, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !31)
// CHECK:STDOUT: !29 = !DISubroutineType(types: !30)
// CHECK:STDOUT: !30 = !{null, !7}
// CHECK:STDOUT: !31 = !{!32}
// CHECK:STDOUT: !32 = !DILocalVariable(arg: 1, scope: !28, type: !7)
// CHECK:STDOUT: !33 = !DILocation(line: 42, column: 11, scope: !28)
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "Op", linkageName: "_COp.39976c684c12c16f:core.Destroy.Core", scope: null, file: !1, line: 42, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !35)
// CHECK:STDOUT: !35 = !{!36}
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !34, type: !7)
// CHECK:STDOUT: !37 = !DILocation(line: 42, column: 11, scope: !34)
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "Op", linkageName: "_COp.6f70ad92790b7b3d:core.Destroy.Core", scope: null, file: !1, line: 42, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !39)
// CHECK:STDOUT: !39 = !{!40}
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !38, type: !7)
// CHECK:STDOUT: !41 = !DILocation(line: 42, column: 11, scope: !38)
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "Op", linkageName: "_COp.51939fc15d8db062:core.Destroy.Core", scope: null, file: !1, line: 42, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !43)
// CHECK:STDOUT: !43 = !{!44}
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !42, type: !7)
// CHECK:STDOUT: !45 = !DILocation(line: 42, column: 11, scope: !42)
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5716d9c282b70019:core.Destroy.Core", scope: null, file: !1, line: 42, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !47)
// CHECK:STDOUT: !47 = !{!48}
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !46, type: !7)
// CHECK:STDOUT: !49 = !DILocation(line: 42, column: 11, scope: !46)
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "Op", linkageName: "_COp.c9ead255f32e7c59:core.Destroy.Core", scope: null, file: !1, line: 42, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !51)
// CHECK:STDOUT: !51 = !{!52}
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !50, type: !7)
// CHECK:STDOUT: !53 = !DILocation(line: 42, column: 11, scope: !50)
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "Op", linkageName: "_COp.a214566110020819:core.Destroy.Core", scope: null, file: !1, line: 42, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !55)
// CHECK:STDOUT: !55 = !{!56}
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !54, type: !7)
// CHECK:STDOUT: !57 = !DILocation(line: 42, column: 11, scope: !54)
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "Chain", linkageName: "_CChain.Main.84588f41d61dafba", scope: null, file: !1, line: 41, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !59)
// CHECK:STDOUT: !59 = !{!60, !61, !62}
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !58, type: !8)
// CHECK:STDOUT: !61 = !DILocalVariable(arg: 2, scope: !58, type: !7)
// CHECK:STDOUT: !62 = !DILocalVariable(arg: 3, scope: !58, type: !7)
// CHECK:STDOUT: !63 = !DILocation(line: 42, column: 11, scope: !58)
// CHECK:STDOUT: !64 = !DILocation(line: 43, column: 11, scope: !58)
// CHECK:STDOUT: !65 = !DILocation(line: 42, column: 3, scope: !58)
// CHECK:STDOUT: !66 = !DILocation(line: 43, column: 3, scope: !58)
// CHECK:STDOUT: !67 = !DILocation(line: 44, column: 10, scope: !58)
// CHECK:STDOUT: !68 = !DILocation(line: 44, column: 3, scope: !58)
// CHECK:STDOUT: !69 = distinct !DISubprogram(name: "Step", linkageName: "_CStep.Main.84588f41d61dafba", scope: null, file: !1, line: 29, type: !70, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !72)
// CHECK:STDOUT: !70 = !DISubroutineType(types: !71)
// CHECK:STDOUT: !71 = !{!7, !8, !7, !8}
// CHECK:STDOUT: !72 = !{!73, !74, !75}
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !69, type: !8)
// CHECK:STDOUT: !74 = !DILocalVariable(arg: 2, scope: !69, type: !7)
// CHECK:STDOUT: !75 = !DILocalVariable(arg: 3, scope: !69, type: !8)
// CHECK:STDOUT: !76 = !DILocation(line: 30, column: 6, scope: !69)
// CHECK:STDOUT: !77 = !DILocation(line: 30, column: 22, scope: !69)
// CHECK:STDOUT: !78 = !DILocation(line: 30, column: 15, scope: !69)
// CHECK:STDOUT: !79 = !DILocation(line: 31, column: 10, scope: !69)
// CHECK:STDOUT: !80 = !DILocation(line: 31, column: 3, scope: !69)
// CHECK:STDOUT: !81 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !1, line: 15, type: !82, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !84)
// CHECK:STDOUT: !82 = !DISubroutineType(types: !83)
// CHECK:STDOUT: !83 = !{!7, !7}
// CHECK:STDOUT: !84 = !{!85}
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !81, type: !7)
// CHECK:STDOUT: !86 = !DILocation(line: 17, column: 7, scope: !81)
// CHECK:STDOUT: !87 = !DILocation(line: 17, column: 34, scope: !81)
// CHECK:STDOUT: !88 = !DILocation(line: 17, column: 27, scope: !81)
// CHECK:STDOUT: !89 = !DILocation(line: 18, column: 7, scope: !81)
// CHECK:STDOUT: !90 = !DILocation(line: 18, column: 35, scope: !81)
// CHECK:STDOUT: !91 = !DILocation(line: 18, column: 28, scope: !81)
// CHECK:STDOUT: !92 = !DILocation(line: 22, column: 12, scope: !81)
// CHECK:STDOUT: !93 = !DILocation(line: 22, column: 5, scope: !81)
// CHECK:STDOUT: !94 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !1, line: 24, type: !95, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !97)
// CHECK:STDOUT: !95 = !DISubroutineType(types: !96)
// CHECK:STDOUT: !96 = !{!7, !8}
// CHECK:STDOUT: !97 = !{!98}
// CHECK:STDOUT: !98 = !DILocalVariable(arg: 1, scope: !94, type: !8)
// CHECK:STDOUT: !99 = !DILocation(line: 24, column: 39, scope: !94)
// CHECK:STDOUT: !100 = !DILocation(line: 24, column: 32, scope: !94)
// CHECK:STDOUT: !101 = distinct !DISubprogram(name: "Discard", linkageName: "_CDiscard.Main.84588f41d61dafba", scope: null, file: !1, line: 36, type: !23, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !102)
// CHECK:STDOUT: !102 = !{!103}
// CHECK:STDOUT: !103 = !DILocalVariable(arg: 1, scope: !101, type: !8)
// CHECK:STDOUT: !104 = !DILocation(line: 36, column: 1, scope: !101)
// CHECK:STDOUT: !105 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.MyResult.Main.8122a03446648385", scope: null, file: !1, line: 3, type: !95, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !106)
// CHECK:STDOUT: !106 = !{!107}
// CHECK:STDOUT: !107 = !DILocalVariable(arg: 1, scope: !105, type: !8)
// CHECK:STDOUT: !108 = !DILocation(line: 3, column: 1, scope: !105)
// CHECK:STDOUT: !109 = !DILocation(line: 4, column: 11, scope: !105)
// CHECK:STDOUT: !110 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.8122a03446648385", scope: null, file: !1, line: 3, type: !95, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !111)
// CHECK:STDOUT: !111 = !{!112}
// CHECK:STDOUT: !112 = !DILocalVariable(arg: 1, scope: !110, type: !8)
// CHECK:STDOUT: !113 = !DILocation(line: 3, column: 1, scope: !110)
// CHECK:STDOUT: !114 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.8122a03446648385", scope: null, file: !115, line: 21, type: !95, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !116)
// CHECK:STDOUT: !115 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !116 = !{!117}
// CHECK:STDOUT: !117 = !DILocalVariable(arg: 1, scope: !114, type: !8)
// CHECK:STDOUT: !118 = !DILocation(line: 21, column: 1, scope: !114)
// CHECK:STDOUT: !119 = !DILocation(line: 22, column: 21, scope: !114)
// CHECK:STDOUT: !120 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.8122a03446648385", scope: null, file: !115, line: 21, type: !95, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !121)
// CHECK:STDOUT: !121 = !{!122}
// CHECK:STDOUT: !122 = !DILocalVariable(arg: 1, scope: !120, type: !8)
// CHECK:STDOUT: !123 = !DILocation(line: 21, column: 1, scope: !120)
// CHECK:STDOUT: !124 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.9bba81283511934f", scope: null, file: !1, line: 11, type: !125, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !125 = !DISubroutineType(types: !126)
// CHECK:STDOUT: !126 = !{!7}
// CHECK:STDOUT: !127 = !DILocation(line: 11, column: 45, scope: !124)
// CHECK:STDOUT: !128 = !DILocation(line: 11, column: 38, scope: !124)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'use.carbon'
// CHECK:STDOUT: source_filename = "use.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @MyResult.val.142.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @MyResult.val.30e.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @MyResult.val.9f4.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> zeroinitializer
// CHECK:STDOUT: @MyResult.val.df1.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @ControlFlow.val.f6c.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @ControlFlow.val.493.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @ControlFlow.val.fa9.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> zeroinitializer
// CHECK:STDOUT: @ControlFlow.val.d01.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall32.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %x, i1 %failA, i1 %failB) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CChain.Main.84588f41d61dafba(ptr %return, i32 %x, i1 %failA, i1 %failB), !dbg !13
// CHECK:STDOUT:   ret void, !dbg !14
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall64.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %x, i1 %failA, i1 %failB) #0 !dbg !15 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CChain.Main.f249b435619a5146(ptr %return, i64 %x, i1 %failA, i1 %failB), !dbg !23
// CHECK:STDOUT:   ret void, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeErr64.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %tag) #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.b7dd877894074427(ptr %return, i32 %tag), !dbg !30
// CHECK:STDOUT:   ret void, !dbg !31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CReadErr64.Main(ptr %r) #0 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc29_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %r, i32 0, i32 0, !dbg !37
// CHECK:STDOUT:   %.loc29_22.4 = load i8, ptr %.loc29_22.3.discriminant, align 1, !dbg !37
// CHECK:STDOUT:   %.loc29_22.41 = trunc i8 %.loc29_22.4 to i1, !dbg !37
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc29 = icmp eq i1 false, %.loc29_22.41, !dbg !37
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc29, label %match.case.then.loc29, label %match.case.else.loc29, !dbg !37
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc29:                            ; preds = %entry
// CHECK:STDOUT:   %.loc29_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %r, i32 0, i32 1, !dbg !37
// CHECK:STDOUT:   %.loc29_22.8.Ok = getelementptr inbounds nuw [8 x i8], ptr %.loc29_22.7.payload, i32 0, i32 0, !dbg !37
// CHECK:STDOUT:   %tuple.elem0.loc29.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc29_22.8.Ok, i32 0, i32 0, !dbg !37
// CHECK:STDOUT:   %.loc29_22.9 = load i64, ptr %tuple.elem0.loc29.tuple.elem, align 8, !dbg !37
// CHECK:STDOUT:   ret i32 0, !dbg !38
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc29:                            ; preds = %entry
// CHECK:STDOUT:   %.loc30_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %r, i32 0, i32 0, !dbg !39
// CHECK:STDOUT:   %.loc30_23.4 = load i8, ptr %.loc30_23.3.discriminant, align 1, !dbg !39
// CHECK:STDOUT:   %.loc30_23.42 = trunc i8 %.loc30_23.4 to i1, !dbg !39
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc30 = icmp eq i1 true, %.loc30_23.42, !dbg !39
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc30, label %match.case.then.loc30, label %match.done, !dbg !39
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc30:                            ; preds = %match.case.else.loc29
// CHECK:STDOUT:   %.loc30_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %r, i32 0, i32 1, !dbg !39
// CHECK:STDOUT:   %.loc30_23.8.Err = getelementptr inbounds nuw [8 x i8], ptr %.loc30_23.7.payload, i32 0, i32 0, !dbg !39
// CHECK:STDOUT:   %tuple.elem0.loc30.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc30_23.8.Err, i32 0, i32 0, !dbg !39
// CHECK:STDOUT:   %.loc30_23.9 = load i32, ptr %tuple.elem0.loc30.tuple.elem, align 4, !dbg !39
// CHECK:STDOUT:   ret i32 %.loc30_23.9, !dbg !40
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc29
// CHECK:STDOUT:   ret i32 -1, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.945345cbed56cb88:core.Destroy.Core"(ptr %self) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.216a6481b641f07b:core.Destroy.Core"(ptr %self) #0 !dbg !56 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !61
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.39976c684c12c16f:core.Destroy.Core"(ptr %self) #0 !dbg !62 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.6f70ad92790b7b3d:core.Destroy.Core"(ptr %self) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %self) #0 !dbg !70 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !73
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5716d9c282b70019:core.Destroy.Core"(ptr %self) #0 !dbg !74 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.c9ead255f32e7c59:core.Destroy.Core"(ptr %self) #0 !dbg !78 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !81
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.a214566110020819:core.Destroy.Core"(ptr %self) #0 !dbg !82 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !85
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5f42013854821c52:core.Destroy.Core"(ptr %self) #0 !dbg !86 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.62437d0fc7766a41:core.Destroy.Core"(ptr %self) #0 !dbg !92 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !95
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.4a128e99f244da38:core.Destroy.Core"(ptr %self) #0 !dbg !96 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !99
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.37ea992d2bcf2c08:core.Destroy.Core"(ptr %self) #0 !dbg !100 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !103
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.e292046f58666a75:core.Destroy.Core"(ptr %self) #0 !dbg !104 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !107
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.c41c2132e4b94059:core.Destroy.Core"(ptr %self) #0 !dbg !108 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !111
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.4b7b55811680dccf:core.Destroy.Core"(ptr %self) #0 !dbg !112 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !115
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.bea179675fd68487:core.Destroy.Core"(ptr %self) #0 !dbg !116 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !119
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CChain.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %x, i1 %failA, i1 %failB) #0 !dbg !120 {
// CHECK:STDOUT:   %temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !125
// CHECK:STDOUT:   %temp1 = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !125
// CHECK:STDOUT:   %temp4 = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !126
// CHECK:STDOUT:   %temp5 = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !126
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !125
// CHECK:STDOUT:   call void @_CStep.Main.84588f41d61dafba(ptr %temp, i32 %x, i1 %failA, i32 101), !dbg !125
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !125
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %temp1, ptr %temp), !dbg !125
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %temp1, i32 0, i32 0, !dbg !125
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !125
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !125
// CHECK:STDOUT:   %3 = icmp eq i1 true, %2, !dbg !125
// CHECK:STDOUT:   br i1 %3, label %4, label %6, !dbg !125
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %temp1, i32 0, i32 1, !dbg !125
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !125
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !125
// CHECK:STDOUT:   %5 = load i32, ptr %tuple.elem, align 4, !dbg !125
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %5), !dbg !125
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %temp1), !dbg !125
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %temp), !dbg !125
// CHECK:STDOUT:   ret void, !dbg !125
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %0
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %temp1, i32 0, i32 1, !dbg !125
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload2, i32 0, i32 0, !dbg !125
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !125
// CHECK:STDOUT:   %7 = load i32, ptr %tuple.elem3, align 4, !dbg !125
// CHECK:STDOUT:   call void @_CDiscard.Main.84588f41d61dafba(i32 %7), !dbg !127
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %temp1), !dbg !125
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %temp), !dbg !125
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp4), !dbg !126
// CHECK:STDOUT:   call void @_CStep.Main.84588f41d61dafba(ptr %temp4, i32 %x, i1 %failB, i32 202), !dbg !126
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp5), !dbg !126
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %temp5, ptr %temp4), !dbg !126
// CHECK:STDOUT:   %discriminant6 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %temp5, i32 0, i32 0, !dbg !126
// CHECK:STDOUT:   %8 = load i8, ptr %discriminant6, align 1, !dbg !126
// CHECK:STDOUT:   %9 = trunc i8 %8 to i1, !dbg !126
// CHECK:STDOUT:   %10 = icmp eq i1 true, %9, !dbg !126
// CHECK:STDOUT:   br i1 %10, label %11, label %13, !dbg !126
// CHECK:STDOUT:
// CHECK:STDOUT: 11:                                               ; preds = %6
// CHECK:STDOUT:   %payload7 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %temp5, i32 0, i32 1, !dbg !126
// CHECK:STDOUT:   %Break8 = getelementptr inbounds nuw [4 x i8], ptr %payload7, i32 0, i32 0, !dbg !126
// CHECK:STDOUT:   %tuple.elem9 = getelementptr inbounds nuw { i32 }, ptr %Break8, i32 0, i32 0, !dbg !126
// CHECK:STDOUT:   %12 = load i32, ptr %tuple.elem9, align 4, !dbg !126
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %12), !dbg !126
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %temp5), !dbg !126
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %temp4), !dbg !126
// CHECK:STDOUT:   ret void, !dbg !126
// CHECK:STDOUT:
// CHECK:STDOUT: 13:                                               ; preds = %6
// CHECK:STDOUT:   %payload10 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %temp5, i32 0, i32 1, !dbg !126
// CHECK:STDOUT:   %Continue11 = getelementptr inbounds nuw [4 x i8], ptr %payload10, i32 0, i32 0, !dbg !126
// CHECK:STDOUT:   %tuple.elem12 = getelementptr inbounds nuw { i32 }, ptr %Continue11, i32 0, i32 0, !dbg !126
// CHECK:STDOUT:   %14 = load i32, ptr %tuple.elem12, align 4, !dbg !126
// CHECK:STDOUT:   call void @_CDiscard.Main.84588f41d61dafba(i32 %14), !dbg !128
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %temp5), !dbg !126
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %temp4), !dbg !126
// CHECK:STDOUT:   call void @_COk.MyResult.Main.8122a03446648385(ptr %return, i32 %x), !dbg !129
// CHECK:STDOUT:   ret void, !dbg !130
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CChain.Main.f249b435619a5146(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %x, i1 %failA, i1 %failB) #0 !dbg !131 {
// CHECK:STDOUT:   %temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !136
// CHECK:STDOUT:   %temp1 = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !136
// CHECK:STDOUT:   %temp4 = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !137
// CHECK:STDOUT:   %temp5 = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !137
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !136
// CHECK:STDOUT:   call void @_CStep.Main.f249b435619a5146(ptr %temp, i64 %x, i1 %failA, i32 101), !dbg !136
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !136
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %temp1, ptr %temp), !dbg !136
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %temp1, i32 0, i32 0, !dbg !136
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !136
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !136
// CHECK:STDOUT:   %3 = icmp eq i1 true, %2, !dbg !136
// CHECK:STDOUT:   br i1 %3, label %4, label %6, !dbg !136
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %temp1, i32 0, i32 1, !dbg !136
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !136
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !136
// CHECK:STDOUT:   %5 = load i32, ptr %tuple.elem, align 4, !dbg !136
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %return, i32 %5), !dbg !136
// CHECK:STDOUT:   call void @"_COp.e292046f58666a75:core.Destroy.Core"(ptr %temp1), !dbg !136
// CHECK:STDOUT:   call void @"_COp.bea179675fd68487:core.Destroy.Core"(ptr %temp), !dbg !136
// CHECK:STDOUT:   ret void, !dbg !136
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %0
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %temp1, i32 0, i32 1, !dbg !136
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [8 x i8], ptr %payload2, i32 0, i32 0, !dbg !136
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { i64 }, ptr %Continue, i32 0, i32 0, !dbg !136
// CHECK:STDOUT:   %7 = load i64, ptr %tuple.elem3, align 8, !dbg !136
// CHECK:STDOUT:   call void @_CDiscard.Main.f249b435619a5146(i64 %7), !dbg !138
// CHECK:STDOUT:   call void @"_COp.e292046f58666a75:core.Destroy.Core"(ptr %temp1), !dbg !136
// CHECK:STDOUT:   call void @"_COp.bea179675fd68487:core.Destroy.Core"(ptr %temp), !dbg !136
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp4), !dbg !137
// CHECK:STDOUT:   call void @_CStep.Main.f249b435619a5146(ptr %temp4, i64 %x, i1 %failB, i32 202), !dbg !137
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp5), !dbg !137
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %temp5, ptr %temp4), !dbg !137
// CHECK:STDOUT:   %discriminant6 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %temp5, i32 0, i32 0, !dbg !137
// CHECK:STDOUT:   %8 = load i8, ptr %discriminant6, align 1, !dbg !137
// CHECK:STDOUT:   %9 = trunc i8 %8 to i1, !dbg !137
// CHECK:STDOUT:   %10 = icmp eq i1 true, %9, !dbg !137
// CHECK:STDOUT:   br i1 %10, label %11, label %13, !dbg !137
// CHECK:STDOUT:
// CHECK:STDOUT: 11:                                               ; preds = %6
// CHECK:STDOUT:   %payload7 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %temp5, i32 0, i32 1, !dbg !137
// CHECK:STDOUT:   %Break8 = getelementptr inbounds nuw [8 x i8], ptr %payload7, i32 0, i32 0, !dbg !137
// CHECK:STDOUT:   %tuple.elem9 = getelementptr inbounds nuw { i32 }, ptr %Break8, i32 0, i32 0, !dbg !137
// CHECK:STDOUT:   %12 = load i32, ptr %tuple.elem9, align 4, !dbg !137
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %return, i32 %12), !dbg !137
// CHECK:STDOUT:   call void @"_COp.e292046f58666a75:core.Destroy.Core"(ptr %temp5), !dbg !137
// CHECK:STDOUT:   call void @"_COp.bea179675fd68487:core.Destroy.Core"(ptr %temp4), !dbg !137
// CHECK:STDOUT:   ret void, !dbg !137
// CHECK:STDOUT:
// CHECK:STDOUT: 13:                                               ; preds = %6
// CHECK:STDOUT:   %payload10 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %temp5, i32 0, i32 1, !dbg !137
// CHECK:STDOUT:   %Continue11 = getelementptr inbounds nuw [8 x i8], ptr %payload10, i32 0, i32 0, !dbg !137
// CHECK:STDOUT:   %tuple.elem12 = getelementptr inbounds nuw { i64 }, ptr %Continue11, i32 0, i32 0, !dbg !137
// CHECK:STDOUT:   %14 = load i64, ptr %tuple.elem12, align 8, !dbg !137
// CHECK:STDOUT:   call void @_CDiscard.Main.f249b435619a5146(i64 %14), !dbg !139
// CHECK:STDOUT:   call void @"_COp.e292046f58666a75:core.Destroy.Core"(ptr %temp5), !dbg !137
// CHECK:STDOUT:   call void @"_COp.bea179675fd68487:core.Destroy.Core"(ptr %temp4), !dbg !137
// CHECK:STDOUT:   call void @_COk.MyResult.Main.b7dd877894074427(ptr %return, i64 %x), !dbg !140
// CHECK:STDOUT:   ret void, !dbg !141
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !142 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !145
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !145
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !145
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !145
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @MyResult.val.142.anon, i64 16, i1 false), !dbg !145
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Err, align 4, !dbg !145
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !145
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !145
// CHECK:STDOUT:   ret void, !dbg !145
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CLibCall32.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>), i32, i1, i1)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CStep.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %x, i1 %fail, i32 %tag) #0 !dbg !146 {
// CHECK:STDOUT:   br i1 %fail, label %1, label %2, !dbg !153
// CHECK:STDOUT:
// CHECK:STDOUT: 1:                                                ; preds = %0
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %tag), !dbg !154
// CHECK:STDOUT:   ret void, !dbg !155
// CHECK:STDOUT:
// CHECK:STDOUT: 2:                                                ; preds = %0
// CHECK:STDOUT:   call void @_COk.MyResult.Main.8122a03446648385(ptr %return, i32 %x), !dbg !156
// CHECK:STDOUT:   ret void, !dbg !157
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !158 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !163
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !163
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !163
// CHECK:STDOUT:   %3 = icmp eq i1 false, %2, !dbg !163
// CHECK:STDOUT:   br i1 %3, label %4, label %6, !dbg !163
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !163
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !163
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Ok, i32 0, i32 0, !dbg !163
// CHECK:STDOUT:   %5 = load i32, ptr %tuple.elem, align 4, !dbg !163
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.8122a03446648385(ptr %return, i32 %5), !dbg !164
// CHECK:STDOUT:   ret void, !dbg !165
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %0
// CHECK:STDOUT:   %discriminant1 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !166
// CHECK:STDOUT:   %7 = load i8, ptr %discriminant1, align 1, !dbg !166
// CHECK:STDOUT:   %8 = trunc i8 %7 to i1, !dbg !166
// CHECK:STDOUT:   %9 = icmp eq i1 true, %8, !dbg !166
// CHECK:STDOUT:   br i1 %9, label %10, label %12, !dbg !166
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %6
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !166
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload2, i32 0, i32 0, !dbg !166
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !166
// CHECK:STDOUT:   %11 = load i32, ptr %tuple.elem3, align 4, !dbg !166
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.8122a03446648385(ptr %return, i32 %11), !dbg !167
// CHECK:STDOUT:   ret void, !dbg !168
// CHECK:STDOUT:
// CHECK:STDOUT: 12:                                               ; preds = %6
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !169
// CHECK:STDOUT:   ret void, !dbg !170
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %e) #0 !dbg !171 {
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %e), !dbg !174
// CHECK:STDOUT:   ret void, !dbg !175
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiscard.Main.84588f41d61dafba(i32 %_) #0 !dbg !176 {
// CHECK:STDOUT:   ret void, !dbg !179
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !180 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !183
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !183
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !183
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !184
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.30e.anon, i64 8, i1 false), !dbg !183
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Ok, align 4, !dbg !183
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Ok, i32 0, i32 0, !dbg !184
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !184
// CHECK:STDOUT:   ret void, !dbg !183
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CStep.Main.f249b435619a5146(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %x, i1 %fail, i32 %tag) #0 !dbg !185 {
// CHECK:STDOUT:   br i1 %fail, label %1, label %2, !dbg !192
// CHECK:STDOUT:
// CHECK:STDOUT: 1:                                                ; preds = %0
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.b7dd877894074427(ptr %return, i32 %tag), !dbg !193
// CHECK:STDOUT:   ret void, !dbg !194
// CHECK:STDOUT:
// CHECK:STDOUT: 2:                                                ; preds = %0
// CHECK:STDOUT:   call void @_COk.MyResult.Main.b7dd877894074427(ptr %return, i64 %x), !dbg !195
// CHECK:STDOUT:   ret void, !dbg !196
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %self) #0 !dbg !197 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !200
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !200
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !200
// CHECK:STDOUT:   %3 = icmp eq i1 false, %2, !dbg !200
// CHECK:STDOUT:   br i1 %3, label %4, label %6, !dbg !200
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !200
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !200
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i64 }, ptr %Ok, i32 0, i32 0, !dbg !200
// CHECK:STDOUT:   %5 = load i64, ptr %tuple.elem, align 8, !dbg !200
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.b7dd877894074427(ptr %return, i64 %5), !dbg !201
// CHECK:STDOUT:   ret void, !dbg !202
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %0
// CHECK:STDOUT:   %discriminant1 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !203
// CHECK:STDOUT:   %7 = load i8, ptr %discriminant1, align 1, !dbg !203
// CHECK:STDOUT:   %8 = trunc i8 %7 to i1, !dbg !203
// CHECK:STDOUT:   %9 = icmp eq i1 true, %8, !dbg !203
// CHECK:STDOUT:   br i1 %9, label %10, label %12, !dbg !203
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %6
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !203
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [8 x i8], ptr %payload2, i32 0, i32 0, !dbg !203
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !203
// CHECK:STDOUT:   %11 = load i32, ptr %tuple.elem3, align 4, !dbg !203
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.b7dd877894074427(ptr %return, i32 %11), !dbg !204
// CHECK:STDOUT:   ret void, !dbg !205
// CHECK:STDOUT:
// CHECK:STDOUT: 12:                                               ; preds = %6
// CHECK:STDOUT:   call void @_CDiverge.Main.fc3567e4618671b9(ptr %return), !dbg !206
// CHECK:STDOUT:   ret void, !dbg !207
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %e) #0 !dbg !208 {
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.b7dd877894074427(ptr %return, i32 %e), !dbg !211
// CHECK:STDOUT:   ret void, !dbg !212
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiscard.Main.f249b435619a5146(i64 %_) #0 !dbg !213 {
// CHECK:STDOUT:   ret void, !dbg !216
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.MyResult.Main.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %_) #0 !dbg !217 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !222
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !222
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !222
// CHECK:STDOUT:   %tuple.init = insertvalue { i64 } poison, i64 %_, 0, !dbg !223
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @MyResult.val.9f4.anon, i64 16, i1 false), !dbg !222
// CHECK:STDOUT:   store { i64 } %tuple.init, ptr %Ok, align 8, !dbg !222
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i64 }, ptr %Ok, i32 0, i32 0, !dbg !223
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem, align 8, !dbg !223
// CHECK:STDOUT:   ret void, !dbg !222
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !224 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !227
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !227
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !227
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !227
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.df1.anon, i64 8, i1 false), !dbg !227
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Err, align 4, !dbg !227
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !227
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !227
// CHECK:STDOUT:   ret void, !dbg !227
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !228 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !232
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !232
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !232
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !233
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.f6c.anon, i64 8, i1 false), !dbg !232
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !232
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !233
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !233
// CHECK:STDOUT:   ret void, !dbg !232
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !234 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !237
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !237
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !237
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !237
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.493.anon, i64 8, i1 false), !dbg !237
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !237
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !237
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !237
// CHECK:STDOUT:   ret void, !dbg !237
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.9bba81283511934f(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !238 {
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !241
// CHECK:STDOUT:   ret void, !dbg !242
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %_) #0 !dbg !243 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !246
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !246
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !246
// CHECK:STDOUT:   %tuple.init = insertvalue { i64 } poison, i64 %_, 0, !dbg !247
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.fa9.anon, i64 16, i1 false), !dbg !246
// CHECK:STDOUT:   store { i64 } %tuple.init, ptr %Continue, align 8, !dbg !246
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i64 }, ptr %Continue, i32 0, i32 0, !dbg !247
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem, align 8, !dbg !247
// CHECK:STDOUT:   ret void, !dbg !246
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !248 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !251
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !251
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !251
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !251
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.d01.anon, i64 16, i1 false), !dbg !251
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !251
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !251
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !251
// CHECK:STDOUT:   ret void, !dbg !251
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.fc3567e4618671b9(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return) #0 !dbg !252 {
// CHECK:STDOUT:   call void @_CDiverge.Main.fc3567e4618671b9(ptr %return), !dbg !253
// CHECK:STDOUT:   ret void, !dbg !254
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 7, 6, 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CStep.Main.84588f41d61dafba, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CDiscard.Main.84588f41d61dafba, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_COk.MyResult.Main.8122a03446648385, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CStep.Main.f249b435619a5146, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CDiscard.Main.f249b435619a5146, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_COk.MyResult.Main.b7dd877894074427, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 0, 1, 2, 3, 4, 7, 6, 5 }
// CHECK:STDOUT: uselistorder ptr @_CErr.MyResult.Main.8122a03446648385, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "use.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Call32", linkageName: "_CCall32.Main", scope: null, file: !1, line: 6, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8, !7, !7}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10, !11, !12}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocalVariable(arg: 2, scope: !4, type: !7)
// CHECK:STDOUT: !12 = !DILocalVariable(arg: 3, scope: !4, type: !7)
// CHECK:STDOUT: !13 = !DILocation(line: 7, column: 10, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 7, column: 3, scope: !4)
// CHECK:STDOUT: !15 = distinct !DISubprogram(name: "Call64", linkageName: "_CCall64.Main", scope: null, file: !1, line: 10, type: !16, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !19)
// CHECK:STDOUT: !16 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !17 = !{!7, !18, !7, !7}
// CHECK:STDOUT: !18 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !19 = !{!20, !21, !22}
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !15, type: !18)
// CHECK:STDOUT: !21 = !DILocalVariable(arg: 2, scope: !15, type: !7)
// CHECK:STDOUT: !22 = !DILocalVariable(arg: 3, scope: !15, type: !7)
// CHECK:STDOUT: !23 = !DILocation(line: 11, column: 10, scope: !15)
// CHECK:STDOUT: !24 = !DILocation(line: 11, column: 3, scope: !15)
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "MakeErr64", linkageName: "_CMakeErr64.Main", scope: null, file: !1, line: 17, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !28)
// CHECK:STDOUT: !26 = !DISubroutineType(types: !27)
// CHECK:STDOUT: !27 = !{!7, !8}
// CHECK:STDOUT: !28 = !{!29}
// CHECK:STDOUT: !29 = !DILocalVariable(arg: 1, scope: !25, type: !8)
// CHECK:STDOUT: !30 = !DILocation(line: 18, column: 10, scope: !25)
// CHECK:STDOUT: !31 = !DILocation(line: 18, column: 3, scope: !25)
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "ReadErr64", linkageName: "_CReadErr64.Main", scope: null, file: !1, line: 23, type: !33, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !35)
// CHECK:STDOUT: !33 = !DISubroutineType(types: !34)
// CHECK:STDOUT: !34 = !{!8, !7}
// CHECK:STDOUT: !35 = !{!36}
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !32, type: !7)
// CHECK:STDOUT: !37 = !DILocation(line: 29, column: 5, scope: !32)
// CHECK:STDOUT: !38 = !DILocation(line: 29, column: 27, scope: !32)
// CHECK:STDOUT: !39 = !DILocation(line: 30, column: 5, scope: !32)
// CHECK:STDOUT: !40 = !DILocation(line: 30, column: 28, scope: !32)
// CHECK:STDOUT: !41 = !DILocation(line: 33, column: 3, scope: !32)
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "Op", linkageName: "_COp.945345cbed56cb88:core.Destroy.Core", scope: null, file: !43, line: 42, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !47)
// CHECK:STDOUT: !43 = !DIFile(filename: "lib.carbon", directory: "")
// CHECK:STDOUT: !44 = !DISubroutineType(types: !45)
// CHECK:STDOUT: !45 = !{null, !46}
// CHECK:STDOUT: !46 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !47 = !{!48}
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !42, type: !46)
// CHECK:STDOUT: !49 = !DILocation(line: 42, column: 11, scope: !42)
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !43, line: 42, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !53)
// CHECK:STDOUT: !51 = !DISubroutineType(types: !52)
// CHECK:STDOUT: !52 = !{null, !8}
// CHECK:STDOUT: !53 = !{!54}
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !50, type: !8)
// CHECK:STDOUT: !55 = !DILocation(line: 42, column: 11, scope: !50)
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "Op", linkageName: "_COp.216a6481b641f07b:core.Destroy.Core", scope: null, file: !43, line: 42, type: !57, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !59)
// CHECK:STDOUT: !57 = !DISubroutineType(types: !58)
// CHECK:STDOUT: !58 = !{null, !7}
// CHECK:STDOUT: !59 = !{!60}
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !56, type: !7)
// CHECK:STDOUT: !61 = !DILocation(line: 42, column: 11, scope: !56)
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "Op", linkageName: "_COp.39976c684c12c16f:core.Destroy.Core", scope: null, file: !43, line: 42, type: !57, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !63)
// CHECK:STDOUT: !63 = !{!64}
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !62, type: !7)
// CHECK:STDOUT: !65 = !DILocation(line: 42, column: 11, scope: !62)
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "Op", linkageName: "_COp.6f70ad92790b7b3d:core.Destroy.Core", scope: null, file: !43, line: 42, type: !57, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !67)
// CHECK:STDOUT: !67 = !{!68}
// CHECK:STDOUT: !68 = !DILocalVariable(arg: 1, scope: !66, type: !7)
// CHECK:STDOUT: !69 = !DILocation(line: 42, column: 11, scope: !66)
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "Op", linkageName: "_COp.51939fc15d8db062:core.Destroy.Core", scope: null, file: !43, line: 42, type: !57, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !71)
// CHECK:STDOUT: !71 = !{!72}
// CHECK:STDOUT: !72 = !DILocalVariable(arg: 1, scope: !70, type: !7)
// CHECK:STDOUT: !73 = !DILocation(line: 42, column: 11, scope: !70)
// CHECK:STDOUT: !74 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5716d9c282b70019:core.Destroy.Core", scope: null, file: !43, line: 42, type: !57, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !75)
// CHECK:STDOUT: !75 = !{!76}
// CHECK:STDOUT: !76 = !DILocalVariable(arg: 1, scope: !74, type: !7)
// CHECK:STDOUT: !77 = !DILocation(line: 42, column: 11, scope: !74)
// CHECK:STDOUT: !78 = distinct !DISubprogram(name: "Op", linkageName: "_COp.c9ead255f32e7c59:core.Destroy.Core", scope: null, file: !43, line: 42, type: !57, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !79)
// CHECK:STDOUT: !79 = !{!80}
// CHECK:STDOUT: !80 = !DILocalVariable(arg: 1, scope: !78, type: !7)
// CHECK:STDOUT: !81 = !DILocation(line: 42, column: 11, scope: !78)
// CHECK:STDOUT: !82 = distinct !DISubprogram(name: "Op", linkageName: "_COp.a214566110020819:core.Destroy.Core", scope: null, file: !43, line: 42, type: !57, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !83)
// CHECK:STDOUT: !83 = !{!84}
// CHECK:STDOUT: !84 = !DILocalVariable(arg: 1, scope: !82, type: !7)
// CHECK:STDOUT: !85 = !DILocation(line: 42, column: 11, scope: !82)
// CHECK:STDOUT: !86 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5f42013854821c52:core.Destroy.Core", scope: null, file: !43, line: 42, type: !87, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !89)
// CHECK:STDOUT: !87 = !DISubroutineType(types: !88)
// CHECK:STDOUT: !88 = !{null, !18}
// CHECK:STDOUT: !89 = !{!90}
// CHECK:STDOUT: !90 = !DILocalVariable(arg: 1, scope: !86, type: !18)
// CHECK:STDOUT: !91 = !DILocation(line: 42, column: 11, scope: !86)
// CHECK:STDOUT: !92 = distinct !DISubprogram(name: "Op", linkageName: "_COp.62437d0fc7766a41:core.Destroy.Core", scope: null, file: !43, line: 42, type: !57, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !93)
// CHECK:STDOUT: !93 = !{!94}
// CHECK:STDOUT: !94 = !DILocalVariable(arg: 1, scope: !92, type: !7)
// CHECK:STDOUT: !95 = !DILocation(line: 42, column: 11, scope: !92)
// CHECK:STDOUT: !96 = distinct !DISubprogram(name: "Op", linkageName: "_COp.4a128e99f244da38:core.Destroy.Core", scope: null, file: !43, line: 42, type: !57, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !97)
// CHECK:STDOUT: !97 = !{!98}
// CHECK:STDOUT: !98 = !DILocalVariable(arg: 1, scope: !96, type: !7)
// CHECK:STDOUT: !99 = !DILocation(line: 42, column: 11, scope: !96)
// CHECK:STDOUT: !100 = distinct !DISubprogram(name: "Op", linkageName: "_COp.37ea992d2bcf2c08:core.Destroy.Core", scope: null, file: !43, line: 42, type: !57, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !101)
// CHECK:STDOUT: !101 = !{!102}
// CHECK:STDOUT: !102 = !DILocalVariable(arg: 1, scope: !100, type: !7)
// CHECK:STDOUT: !103 = !DILocation(line: 42, column: 11, scope: !100)
// CHECK:STDOUT: !104 = distinct !DISubprogram(name: "Op", linkageName: "_COp.e292046f58666a75:core.Destroy.Core", scope: null, file: !43, line: 42, type: !57, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !105)
// CHECK:STDOUT: !105 = !{!106}
// CHECK:STDOUT: !106 = !DILocalVariable(arg: 1, scope: !104, type: !7)
// CHECK:STDOUT: !107 = !DILocation(line: 42, column: 11, scope: !104)
// CHECK:STDOUT: !108 = distinct !DISubprogram(name: "Op", linkageName: "_COp.c41c2132e4b94059:core.Destroy.Core", scope: null, file: !43, line: 42, type: !57, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !109)
// CHECK:STDOUT: !109 = !{!110}
// CHECK:STDOUT: !110 = !DILocalVariable(arg: 1, scope: !108, type: !7)
// CHECK:STDOUT: !111 = !DILocation(line: 42, column: 11, scope: !108)
// CHECK:STDOUT: !112 = distinct !DISubprogram(name: "Op", linkageName: "_COp.4b7b55811680dccf:core.Destroy.Core", scope: null, file: !43, line: 42, type: !57, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !113)
// CHECK:STDOUT: !113 = !{!114}
// CHECK:STDOUT: !114 = !DILocalVariable(arg: 1, scope: !112, type: !7)
// CHECK:STDOUT: !115 = !DILocation(line: 42, column: 11, scope: !112)
// CHECK:STDOUT: !116 = distinct !DISubprogram(name: "Op", linkageName: "_COp.bea179675fd68487:core.Destroy.Core", scope: null, file: !43, line: 42, type: !57, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !117)
// CHECK:STDOUT: !117 = !{!118}
// CHECK:STDOUT: !118 = !DILocalVariable(arg: 1, scope: !116, type: !7)
// CHECK:STDOUT: !119 = !DILocation(line: 42, column: 11, scope: !116)
// CHECK:STDOUT: !120 = distinct !DISubprogram(name: "Chain", linkageName: "_CChain.Main.84588f41d61dafba", scope: null, file: !43, line: 41, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !121)
// CHECK:STDOUT: !121 = !{!122, !123, !124}
// CHECK:STDOUT: !122 = !DILocalVariable(arg: 1, scope: !120, type: !8)
// CHECK:STDOUT: !123 = !DILocalVariable(arg: 2, scope: !120, type: !7)
// CHECK:STDOUT: !124 = !DILocalVariable(arg: 3, scope: !120, type: !7)
// CHECK:STDOUT: !125 = !DILocation(line: 42, column: 11, scope: !120)
// CHECK:STDOUT: !126 = !DILocation(line: 43, column: 11, scope: !120)
// CHECK:STDOUT: !127 = !DILocation(line: 42, column: 3, scope: !120)
// CHECK:STDOUT: !128 = !DILocation(line: 43, column: 3, scope: !120)
// CHECK:STDOUT: !129 = !DILocation(line: 44, column: 10, scope: !120)
// CHECK:STDOUT: !130 = !DILocation(line: 44, column: 3, scope: !120)
// CHECK:STDOUT: !131 = distinct !DISubprogram(name: "Chain", linkageName: "_CChain.Main.f249b435619a5146", scope: null, file: !43, line: 41, type: !16, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !132)
// CHECK:STDOUT: !132 = !{!133, !134, !135}
// CHECK:STDOUT: !133 = !DILocalVariable(arg: 1, scope: !131, type: !18)
// CHECK:STDOUT: !134 = !DILocalVariable(arg: 2, scope: !131, type: !7)
// CHECK:STDOUT: !135 = !DILocalVariable(arg: 3, scope: !131, type: !7)
// CHECK:STDOUT: !136 = !DILocation(line: 42, column: 11, scope: !131)
// CHECK:STDOUT: !137 = !DILocation(line: 43, column: 11, scope: !131)
// CHECK:STDOUT: !138 = !DILocation(line: 42, column: 3, scope: !131)
// CHECK:STDOUT: !139 = !DILocation(line: 43, column: 3, scope: !131)
// CHECK:STDOUT: !140 = !DILocation(line: 44, column: 10, scope: !131)
// CHECK:STDOUT: !141 = !DILocation(line: 44, column: 3, scope: !131)
// CHECK:STDOUT: !142 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.b7dd877894074427", scope: null, file: !43, line: 3, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !143)
// CHECK:STDOUT: !143 = !{!144}
// CHECK:STDOUT: !144 = !DILocalVariable(arg: 1, scope: !142, type: !8)
// CHECK:STDOUT: !145 = !DILocation(line: 3, column: 1, scope: !142)
// CHECK:STDOUT: !146 = distinct !DISubprogram(name: "Step", linkageName: "_CStep.Main.84588f41d61dafba", scope: null, file: !43, line: 29, type: !147, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !149)
// CHECK:STDOUT: !147 = !DISubroutineType(types: !148)
// CHECK:STDOUT: !148 = !{!7, !8, !7, !8}
// CHECK:STDOUT: !149 = !{!150, !151, !152}
// CHECK:STDOUT: !150 = !DILocalVariable(arg: 1, scope: !146, type: !8)
// CHECK:STDOUT: !151 = !DILocalVariable(arg: 2, scope: !146, type: !7)
// CHECK:STDOUT: !152 = !DILocalVariable(arg: 3, scope: !146, type: !8)
// CHECK:STDOUT: !153 = !DILocation(line: 30, column: 6, scope: !146)
// CHECK:STDOUT: !154 = !DILocation(line: 30, column: 22, scope: !146)
// CHECK:STDOUT: !155 = !DILocation(line: 30, column: 15, scope: !146)
// CHECK:STDOUT: !156 = !DILocation(line: 31, column: 10, scope: !146)
// CHECK:STDOUT: !157 = !DILocation(line: 31, column: 3, scope: !146)
// CHECK:STDOUT: !158 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !43, line: 15, type: !159, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !161)
// CHECK:STDOUT: !159 = !DISubroutineType(types: !160)
// CHECK:STDOUT: !160 = !{!7, !7}
// CHECK:STDOUT: !161 = !{!162}
// CHECK:STDOUT: !162 = !DILocalVariable(arg: 1, scope: !158, type: !7)
// CHECK:STDOUT: !163 = !DILocation(line: 17, column: 7, scope: !158)
// CHECK:STDOUT: !164 = !DILocation(line: 17, column: 34, scope: !158)
// CHECK:STDOUT: !165 = !DILocation(line: 17, column: 27, scope: !158)
// CHECK:STDOUT: !166 = !DILocation(line: 18, column: 7, scope: !158)
// CHECK:STDOUT: !167 = !DILocation(line: 18, column: 35, scope: !158)
// CHECK:STDOUT: !168 = !DILocation(line: 18, column: 28, scope: !158)
// CHECK:STDOUT: !169 = !DILocation(line: 22, column: 12, scope: !158)
// CHECK:STDOUT: !170 = !DILocation(line: 22, column: 5, scope: !158)
// CHECK:STDOUT: !171 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !43, line: 24, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !172)
// CHECK:STDOUT: !172 = !{!173}
// CHECK:STDOUT: !173 = !DILocalVariable(arg: 1, scope: !171, type: !8)
// CHECK:STDOUT: !174 = !DILocation(line: 24, column: 39, scope: !171)
// CHECK:STDOUT: !175 = !DILocation(line: 24, column: 32, scope: !171)
// CHECK:STDOUT: !176 = distinct !DISubprogram(name: "Discard", linkageName: "_CDiscard.Main.84588f41d61dafba", scope: null, file: !43, line: 36, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !177)
// CHECK:STDOUT: !177 = !{!178}
// CHECK:STDOUT: !178 = !DILocalVariable(arg: 1, scope: !176, type: !8)
// CHECK:STDOUT: !179 = !DILocation(line: 36, column: 1, scope: !176)
// CHECK:STDOUT: !180 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.MyResult.Main.8122a03446648385", scope: null, file: !43, line: 3, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !181)
// CHECK:STDOUT: !181 = !{!182}
// CHECK:STDOUT: !182 = !DILocalVariable(arg: 1, scope: !180, type: !8)
// CHECK:STDOUT: !183 = !DILocation(line: 3, column: 1, scope: !180)
// CHECK:STDOUT: !184 = !DILocation(line: 4, column: 11, scope: !180)
// CHECK:STDOUT: !185 = distinct !DISubprogram(name: "Step", linkageName: "_CStep.Main.f249b435619a5146", scope: null, file: !43, line: 29, type: !186, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !188)
// CHECK:STDOUT: !186 = !DISubroutineType(types: !187)
// CHECK:STDOUT: !187 = !{!7, !18, !7, !8}
// CHECK:STDOUT: !188 = !{!189, !190, !191}
// CHECK:STDOUT: !189 = !DILocalVariable(arg: 1, scope: !185, type: !18)
// CHECK:STDOUT: !190 = !DILocalVariable(arg: 2, scope: !185, type: !7)
// CHECK:STDOUT: !191 = !DILocalVariable(arg: 3, scope: !185, type: !8)
// CHECK:STDOUT: !192 = !DILocation(line: 30, column: 6, scope: !185)
// CHECK:STDOUT: !193 = !DILocation(line: 30, column: 22, scope: !185)
// CHECK:STDOUT: !194 = !DILocation(line: 30, column: 15, scope: !185)
// CHECK:STDOUT: !195 = !DILocation(line: 31, column: 10, scope: !185)
// CHECK:STDOUT: !196 = !DILocation(line: 31, column: 3, scope: !185)
// CHECK:STDOUT: !197 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427", scope: null, file: !43, line: 15, type: !159, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !198)
// CHECK:STDOUT: !198 = !{!199}
// CHECK:STDOUT: !199 = !DILocalVariable(arg: 1, scope: !197, type: !7)
// CHECK:STDOUT: !200 = !DILocation(line: 17, column: 7, scope: !197)
// CHECK:STDOUT: !201 = !DILocation(line: 17, column: 34, scope: !197)
// CHECK:STDOUT: !202 = !DILocation(line: 17, column: 27, scope: !197)
// CHECK:STDOUT: !203 = !DILocation(line: 18, column: 7, scope: !197)
// CHECK:STDOUT: !204 = !DILocation(line: 18, column: 35, scope: !197)
// CHECK:STDOUT: !205 = !DILocation(line: 18, column: 28, scope: !197)
// CHECK:STDOUT: !206 = !DILocation(line: 22, column: 12, scope: !197)
// CHECK:STDOUT: !207 = !DILocation(line: 22, column: 5, scope: !197)
// CHECK:STDOUT: !208 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427", scope: null, file: !43, line: 24, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !209)
// CHECK:STDOUT: !209 = !{!210}
// CHECK:STDOUT: !210 = !DILocalVariable(arg: 1, scope: !208, type: !8)
// CHECK:STDOUT: !211 = !DILocation(line: 24, column: 39, scope: !208)
// CHECK:STDOUT: !212 = !DILocation(line: 24, column: 32, scope: !208)
// CHECK:STDOUT: !213 = distinct !DISubprogram(name: "Discard", linkageName: "_CDiscard.Main.f249b435619a5146", scope: null, file: !43, line: 36, type: !87, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !214)
// CHECK:STDOUT: !214 = !{!215}
// CHECK:STDOUT: !215 = !DILocalVariable(arg: 1, scope: !213, type: !18)
// CHECK:STDOUT: !216 = !DILocation(line: 36, column: 1, scope: !213)
// CHECK:STDOUT: !217 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.MyResult.Main.b7dd877894074427", scope: null, file: !43, line: 3, type: !218, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !220)
// CHECK:STDOUT: !218 = !DISubroutineType(types: !219)
// CHECK:STDOUT: !219 = !{!7, !18}
// CHECK:STDOUT: !220 = !{!221}
// CHECK:STDOUT: !221 = !DILocalVariable(arg: 1, scope: !217, type: !18)
// CHECK:STDOUT: !222 = !DILocation(line: 3, column: 1, scope: !217)
// CHECK:STDOUT: !223 = !DILocation(line: 4, column: 11, scope: !217)
// CHECK:STDOUT: !224 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.8122a03446648385", scope: null, file: !43, line: 3, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !225)
// CHECK:STDOUT: !225 = !{!226}
// CHECK:STDOUT: !226 = !DILocalVariable(arg: 1, scope: !224, type: !8)
// CHECK:STDOUT: !227 = !DILocation(line: 3, column: 1, scope: !224)
// CHECK:STDOUT: !228 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.8122a03446648385", scope: null, file: !229, line: 21, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !230)
// CHECK:STDOUT: !229 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !230 = !{!231}
// CHECK:STDOUT: !231 = !DILocalVariable(arg: 1, scope: !228, type: !8)
// CHECK:STDOUT: !232 = !DILocation(line: 21, column: 1, scope: !228)
// CHECK:STDOUT: !233 = !DILocation(line: 22, column: 21, scope: !228)
// CHECK:STDOUT: !234 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.8122a03446648385", scope: null, file: !229, line: 21, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !235)
// CHECK:STDOUT: !235 = !{!236}
// CHECK:STDOUT: !236 = !DILocalVariable(arg: 1, scope: !234, type: !8)
// CHECK:STDOUT: !237 = !DILocation(line: 21, column: 1, scope: !234)
// CHECK:STDOUT: !238 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.9bba81283511934f", scope: null, file: !43, line: 11, type: !239, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !239 = !DISubroutineType(types: !240)
// CHECK:STDOUT: !240 = !{!7}
// CHECK:STDOUT: !241 = !DILocation(line: 11, column: 45, scope: !238)
// CHECK:STDOUT: !242 = !DILocation(line: 11, column: 38, scope: !238)
// CHECK:STDOUT: !243 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.b7dd877894074427", scope: null, file: !229, line: 21, type: !218, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !244)
// CHECK:STDOUT: !244 = !{!245}
// CHECK:STDOUT: !245 = !DILocalVariable(arg: 1, scope: !243, type: !18)
// CHECK:STDOUT: !246 = !DILocation(line: 21, column: 1, scope: !243)
// CHECK:STDOUT: !247 = !DILocation(line: 22, column: 21, scope: !243)
// CHECK:STDOUT: !248 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.b7dd877894074427", scope: null, file: !229, line: 21, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !249)
// CHECK:STDOUT: !249 = !{!250}
// CHECK:STDOUT: !250 = !DILocalVariable(arg: 1, scope: !248, type: !8)
// CHECK:STDOUT: !251 = !DILocation(line: 21, column: 1, scope: !248)
// CHECK:STDOUT: !252 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.fc3567e4618671b9", scope: null, file: !43, line: 11, type: !239, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !253 = !DILocation(line: 11, column: 45, scope: !252)
// CHECK:STDOUT: !254 = !DILocation(line: 11, column: 38, scope: !252)
// CHECK:STDOUT:

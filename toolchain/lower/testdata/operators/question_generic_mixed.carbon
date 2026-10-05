// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/operators/question_generic_mixed.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/operators/question_generic_mixed.carbon

// The mixed-width instantiated-generic `?` golden (the
// question_generic_diff runtime divergence, 2026-08-09): one generic `?`
// body monomorphized at BOTH `MyResult(i32, i32)` and `MyResult(i64, i32)`
// in one module, so the narrow (i32) `Err` payload lowers inside the WIDE
// max-of-fields region of the i64 specific (F-007k). What this pins:
// every writer and reader of `MyResult(i64, i32)`'s `Err` payload — the
// `Err` constructor's whole-object covering copy plus element stores, the
// desugar's Break-arm extraction, and the concrete `match` read — must
// address the SAME 16-byte object (`[8 x i8]` payload region at byte
// offset 8, covering copy of 16). Falsification: any i64-specific
// Err-path store or load through a NARROW object shape (the round-1 W2
// hypothesis — per-specific layout reuse in instantiated bodies, which
// is ORDER-dependent: Call32 below deliberately precedes Call64), a
// covering memcpy shorter than the specific's object size, or a
// cross-width pair resolving to ONE lowered body. Payload-touching
// bodies fingerprint width-distinct types, so only forwarder-shaped
// pairs (`Diverge`) could coalesce cross-width pre-gate; the sret type
// gate pins that split. History: this golden's own regen showed
// per-width-correct lowering, helping refute the W1/W2 layout-reuse
// hypotheses as the runtime cause; the divergence's actual root cause
// was the poison filler in covering-copied constant templates
// (fork/b2/mixed-width-diagnosis.md), fixed in lower/constant.cpp and
// confirmed by the conformance arbiter.

// --- mixed.carbon
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

// The proven generic `?` body shape (lower/testdata/operators/
// question_generic.carbon): carrier `Core.ControlFlow(R.ContinueType, i32)`,
// symbolic at check time, concrete per instantiation below.
fn PropagateOnly[R: Core.Try where .BreakType = i32](r: R) -> R {
  let unused c: R.ContinueType = r?;
  return R.FromBreak(0);
}

// Both widths instantiated side by side: distinct specifics, distinct
// layouts, one module.
fn Call32(r: MyResult(i32, i32)) -> MyResult(i32, i32) {
  return PropagateOnly(r);
}

fn Call64(r: MyResult(i64, i32)) -> MyResult(i64, i32) {
  return PropagateOnly(r);
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
    // CHECK:STDERR: mixed.carbon:[[@LINE+4]]:14: warning: binding `v` unused [UnusedBinding]
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
// CHECK:STDOUT: ; ModuleID = 'mixed.carbon'
// CHECK:STDOUT: source_filename = "mixed.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @MyResult.val.142.loc3_35.7 = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @ControlFlow.val.f6c.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @ControlFlow.val.493.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @MyResult.val.df1.loc3_35.7 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @ControlFlow.val.fa9.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> zeroinitializer
// CHECK:STDOUT: @ControlFlow.val.d01.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall32.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %r) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CPropagateOnly.Main.74e35ed26b9760b3(ptr %return, ptr %r), !dbg !10
// CHECK:STDOUT:   ret void, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall64.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %r) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CPropagateOnly.Main.17ddbbf3e70b6f1d(ptr %return, ptr %r), !dbg !15
// CHECK:STDOUT:   ret void, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeErr64.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %tag) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.b7dd877894074427(ptr %return, i32 %tag), !dbg !23
// CHECK:STDOUT:   ret void, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CReadErr64.Main(ptr %r) #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc60_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %r, i32 0, i32 0, !dbg !30
// CHECK:STDOUT:   %.loc60_22.4 = load i8, ptr %.loc60_22.3.discriminant, align 1, !dbg !30
// CHECK:STDOUT:   %.loc60_22.41 = trunc i8 %.loc60_22.4 to i1, !dbg !30
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc60 = icmp eq i1 false, %.loc60_22.41, !dbg !30
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc60, label %match.case.then.loc60, label %match.case.else.loc60, !dbg !30
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc60:                            ; preds = %entry
// CHECK:STDOUT:   %.loc60_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %r, i32 0, i32 1, !dbg !30
// CHECK:STDOUT:   %.loc60_22.8.Ok = getelementptr inbounds nuw [8 x i8], ptr %.loc60_22.7.payload, i32 0, i32 0, !dbg !30
// CHECK:STDOUT:   %tuple.elem0.loc60.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc60_22.8.Ok, i32 0, i32 0, !dbg !30
// CHECK:STDOUT:   %.loc60_22.9 = load i64, ptr %tuple.elem0.loc60.tuple.elem, align 8, !dbg !30
// CHECK:STDOUT:   ret i32 0, !dbg !31
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc60:                            ; preds = %entry
// CHECK:STDOUT:   %.loc61_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %r, i32 0, i32 0, !dbg !32
// CHECK:STDOUT:   %.loc61_23.4 = load i8, ptr %.loc61_23.3.discriminant, align 1, !dbg !32
// CHECK:STDOUT:   %.loc61_23.42 = trunc i8 %.loc61_23.4 to i1, !dbg !32
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc61 = icmp eq i1 true, %.loc61_23.42, !dbg !32
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc61, label %match.case.then.loc61, label %match.done, !dbg !32
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc61:                            ; preds = %match.case.else.loc60
// CHECK:STDOUT:   %.loc61_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %r, i32 0, i32 1, !dbg !32
// CHECK:STDOUT:   %.loc61_23.8.Err = getelementptr inbounds nuw [8 x i8], ptr %.loc61_23.7.payload, i32 0, i32 0, !dbg !32
// CHECK:STDOUT:   %tuple.elem0.loc61.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc61_23.8.Err, i32 0, i32 0, !dbg !32
// CHECK:STDOUT:   %.loc61_23.9 = load i32, ptr %tuple.elem0.loc61.tuple.elem, align 4, !dbg !32
// CHECK:STDOUT:   ret i32 %.loc61_23.9, !dbg !33
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc60
// CHECK:STDOUT:   ret i32 -1, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.945345cbed56cb88:core.Destroy.Core"(ptr %self) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !47
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.216a6481b641f07b:core.Destroy.Core"(ptr %self) #0 !dbg !48 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.39976c684c12c16f:core.Destroy.Core"(ptr %self) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.6f70ad92790b7b3d:core.Destroy.Core"(ptr %self) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !61
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %self) #0 !dbg !62 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5f42013854821c52:core.Destroy.Core"(ptr %self) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !72
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.62437d0fc7766a41:core.Destroy.Core"(ptr %self) #0 !dbg !73 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !76
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.4a128e99f244da38:core.Destroy.Core"(ptr %self) #0 !dbg !77 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !80
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.37ea992d2bcf2c08:core.Destroy.Core"(ptr %self) #0 !dbg !81 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !84
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.e292046f58666a75:core.Destroy.Core"(ptr %self) #0 !dbg !85 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !88
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CPropagateOnly.Main.74e35ed26b9760b3(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %r) #0 !dbg !89 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc31_35.3.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !92
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc31_35.3.temp), !dbg !92
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %.loc31_35.3.temp, ptr %r), !dbg !92
// CHECK:STDOUT:   %.loc31_35.7.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc31_35.3.temp, i32 0, i32 0, !dbg !92
// CHECK:STDOUT:   %.loc31_35.8 = load i8, ptr %.loc31_35.7.discriminant, align 1, !dbg !92
// CHECK:STDOUT:   %.loc31_35.81 = trunc i8 %.loc31_35.8 to i1, !dbg !92
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc31_35.81, !dbg !92
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc31_35.1, label %.loc31_35.2, !dbg !92
// CHECK:STDOUT:
// CHECK:STDOUT: .loc31_35.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc31_35.11.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc31_35.3.temp, i32 0, i32 1, !dbg !92
// CHECK:STDOUT:   %.loc31_35.12.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc31_35.11.payload, i32 0, i32 0, !dbg !92
// CHECK:STDOUT:   %tuple.elem0.loc31_35.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc31_35.12.Break, i32 0, i32 0, !dbg !92
// CHECK:STDOUT:   %.loc31_35.13 = load i32, ptr %tuple.elem0.loc31_35.1.tuple.elem, align 4, !dbg !92
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %.loc31_35.13), !dbg !92
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc31_35.3.temp), !dbg !92
// CHECK:STDOUT:   ret void, !dbg !92
// CHECK:STDOUT:
// CHECK:STDOUT: .loc31_35.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc31_35.17.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc31_35.3.temp, i32 0, i32 1, !dbg !92
// CHECK:STDOUT:   %.loc31_35.18.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc31_35.17.payload, i32 0, i32 0, !dbg !92
// CHECK:STDOUT:   %tuple.elem0.loc31_35.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc31_35.18.Continue, i32 0, i32 0, !dbg !92
// CHECK:STDOUT:   %.loc31_35.19 = load i32, ptr %tuple.elem0.loc31_35.2.tuple.elem, align 4, !dbg !92
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 0), !dbg !93
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc31_35.3.temp), !dbg !92
// CHECK:STDOUT:   ret void, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CPropagateOnly.Main.17ddbbf3e70b6f1d(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %r) #0 !dbg !95 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc31_35.3.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !98
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc31_35.3.temp), !dbg !98
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %.loc31_35.3.temp, ptr %r), !dbg !98
// CHECK:STDOUT:   %.loc31_35.7.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc31_35.3.temp, i32 0, i32 0, !dbg !98
// CHECK:STDOUT:   %.loc31_35.8 = load i8, ptr %.loc31_35.7.discriminant, align 1, !dbg !98
// CHECK:STDOUT:   %.loc31_35.81 = trunc i8 %.loc31_35.8 to i1, !dbg !98
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc31_35.81, !dbg !98
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc31_35.1, label %.loc31_35.2, !dbg !98
// CHECK:STDOUT:
// CHECK:STDOUT: .loc31_35.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc31_35.11.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc31_35.3.temp, i32 0, i32 1, !dbg !98
// CHECK:STDOUT:   %.loc31_35.12.Break = getelementptr inbounds nuw [8 x i8], ptr %.loc31_35.11.payload, i32 0, i32 0, !dbg !98
// CHECK:STDOUT:   %tuple.elem0.loc31_35.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc31_35.12.Break, i32 0, i32 0, !dbg !98
// CHECK:STDOUT:   %.loc31_35.13 = load i32, ptr %tuple.elem0.loc31_35.1.tuple.elem, align 4, !dbg !98
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %return, i32 %.loc31_35.13), !dbg !98
// CHECK:STDOUT:   call void @"_COp.e292046f58666a75:core.Destroy.Core"(ptr %.loc31_35.3.temp), !dbg !98
// CHECK:STDOUT:   ret void, !dbg !98
// CHECK:STDOUT:
// CHECK:STDOUT: .loc31_35.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc31_35.17.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc31_35.3.temp, i32 0, i32 1, !dbg !98
// CHECK:STDOUT:   %.loc31_35.18.Continue = getelementptr inbounds nuw [8 x i8], ptr %.loc31_35.17.payload, i32 0, i32 0, !dbg !98
// CHECK:STDOUT:   %tuple.elem0.loc31_35.2.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc31_35.18.Continue, i32 0, i32 0, !dbg !98
// CHECK:STDOUT:   %.loc31_35.19 = load i64, ptr %tuple.elem0.loc31_35.2.tuple.elem, align 8, !dbg !98
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %return, i32 0), !dbg !99
// CHECK:STDOUT:   call void @"_COp.e292046f58666a75:core.Destroy.Core"(ptr %.loc31_35.3.temp), !dbg !98
// CHECK:STDOUT:   ret void, !dbg !100
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !101 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !104
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !104
// CHECK:STDOUT:   %.loc3_35.5.Err = getelementptr inbounds nuw [8 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !104
// CHECK:STDOUT:   %.loc6_1.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !104
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @MyResult.val.142.loc3_35.7, i64 16, i1 false), !dbg !104
// CHECK:STDOUT:   store { i32 } %.loc6_1.1.tuple.init, ptr %.loc3_35.5.Err, align 4, !dbg !104
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Err, i32 0, i32 0, !dbg !104
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !104
// CHECK:STDOUT:   ret void, !dbg !104
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !105 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !108
// CHECK:STDOUT:   %.loc17_22.4 = load i8, ptr %.loc17_22.3.discriminant, align 1, !dbg !108
// CHECK:STDOUT:   %.loc17_22.41 = trunc i8 %.loc17_22.4 to i1, !dbg !108
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc17 = icmp eq i1 false, %.loc17_22.41, !dbg !108
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc17, label %match.case.then.loc17, label %match.case.else.loc17, !dbg !108
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc17_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !108
// CHECK:STDOUT:   %.loc17_22.8.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc17_22.7.payload, i32 0, i32 0, !dbg !108
// CHECK:STDOUT:   %tuple.elem0.loc17.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc17_22.8.Ok, i32 0, i32 0, !dbg !108
// CHECK:STDOUT:   %.loc17_22.9 = load i32, ptr %tuple.elem0.loc17.tuple.elem, align 4, !dbg !108
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc17_22.9), !dbg !109
// CHECK:STDOUT:   ret void, !dbg !110
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc18_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !111
// CHECK:STDOUT:   %.loc18_23.4 = load i8, ptr %.loc18_23.3.discriminant, align 1, !dbg !111
// CHECK:STDOUT:   %.loc18_23.42 = trunc i8 %.loc18_23.4 to i1, !dbg !111
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc18 = icmp eq i1 true, %.loc18_23.42, !dbg !111
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc18, label %match.case.then.loc18, label %match.done, !dbg !111
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc18:                            ; preds = %match.case.else.loc17
// CHECK:STDOUT:   %.loc18_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !111
// CHECK:STDOUT:   %.loc18_23.8.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc18_23.7.payload, i32 0, i32 0, !dbg !111
// CHECK:STDOUT:   %tuple.elem0.loc18.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc18_23.8.Err, i32 0, i32 0, !dbg !111
// CHECK:STDOUT:   %.loc18_23.9 = load i32, ptr %tuple.elem0.loc18.tuple.elem, align 4, !dbg !111
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc18_23.9), !dbg !112
// CHECK:STDOUT:   ret void, !dbg !113
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc17
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !114
// CHECK:STDOUT:   ret void, !dbg !115
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %e) #0 !dbg !116 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %e), !dbg !119
// CHECK:STDOUT:   ret void, !dbg !120
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %self) #0 !dbg !121 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !124
// CHECK:STDOUT:   %.loc17_22.4 = load i8, ptr %.loc17_22.3.discriminant, align 1, !dbg !124
// CHECK:STDOUT:   %.loc17_22.41 = trunc i8 %.loc17_22.4 to i1, !dbg !124
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc17 = icmp eq i1 false, %.loc17_22.41, !dbg !124
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc17, label %match.case.then.loc17, label %match.case.else.loc17, !dbg !124
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc17_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !124
// CHECK:STDOUT:   %.loc17_22.8.Ok = getelementptr inbounds nuw [8 x i8], ptr %.loc17_22.7.payload, i32 0, i32 0, !dbg !124
// CHECK:STDOUT:   %tuple.elem0.loc17.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc17_22.8.Ok, i32 0, i32 0, !dbg !124
// CHECK:STDOUT:   %.loc17_22.9 = load i64, ptr %tuple.elem0.loc17.tuple.elem, align 8, !dbg !124
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.b7dd877894074427(ptr %return, i64 %.loc17_22.9), !dbg !125
// CHECK:STDOUT:   ret void, !dbg !126
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc18_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !127
// CHECK:STDOUT:   %.loc18_23.4 = load i8, ptr %.loc18_23.3.discriminant, align 1, !dbg !127
// CHECK:STDOUT:   %.loc18_23.42 = trunc i8 %.loc18_23.4 to i1, !dbg !127
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc18 = icmp eq i1 true, %.loc18_23.42, !dbg !127
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc18, label %match.case.then.loc18, label %match.done, !dbg !127
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc18:                            ; preds = %match.case.else.loc17
// CHECK:STDOUT:   %.loc18_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !127
// CHECK:STDOUT:   %.loc18_23.8.Err = getelementptr inbounds nuw [8 x i8], ptr %.loc18_23.7.payload, i32 0, i32 0, !dbg !127
// CHECK:STDOUT:   %tuple.elem0.loc18.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc18_23.8.Err, i32 0, i32 0, !dbg !127
// CHECK:STDOUT:   %.loc18_23.9 = load i32, ptr %tuple.elem0.loc18.tuple.elem, align 4, !dbg !127
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.b7dd877894074427(ptr %return, i32 %.loc18_23.9), !dbg !128
// CHECK:STDOUT:   ret void, !dbg !129
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc17
// CHECK:STDOUT:   call void @_CDiverge.Main.fc3567e4618671b9(ptr %return), !dbg !130
// CHECK:STDOUT:   ret void, !dbg !131
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %e) #0 !dbg !132 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.b7dd877894074427(ptr %return, i32 %e), !dbg !135
// CHECK:STDOUT:   ret void, !dbg !136
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !137 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !141
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !141
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !141
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !142
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.f6c.anon, i64 8, i1 false), !dbg !141
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !141
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !142
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !142
// CHECK:STDOUT:   ret void, !dbg !141
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !143 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !146
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !146
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !146
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !146
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.493.anon, i64 8, i1 false), !dbg !146
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !146
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !146
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !146
// CHECK:STDOUT:   ret void, !dbg !146
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.9bba81283511934f(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !147 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !150
// CHECK:STDOUT:   ret void, !dbg !151
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !152 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !155
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !155
// CHECK:STDOUT:   %.loc3_35.5.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !155
// CHECK:STDOUT:   %.loc6_1.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !155
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.df1.loc3_35.7, i64 8, i1 false), !dbg !155
// CHECK:STDOUT:   store { i32 } %.loc6_1.1.tuple.init, ptr %.loc3_35.5.Err, align 4, !dbg !155
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Err, i32 0, i32 0, !dbg !155
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !155
// CHECK:STDOUT:   ret void, !dbg !155
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %_) #0 !dbg !156 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !161
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !161
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !161
// CHECK:STDOUT:   %tuple.init = insertvalue { i64 } poison, i64 %_, 0, !dbg !162
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.fa9.anon, i64 16, i1 false), !dbg !161
// CHECK:STDOUT:   store { i64 } %tuple.init, ptr %Continue, align 8, !dbg !161
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i64 }, ptr %Continue, i32 0, i32 0, !dbg !162
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem, align 8, !dbg !162
// CHECK:STDOUT:   ret void, !dbg !161
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !163 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !166
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !166
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !166
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !166
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.d01.anon, i64 16, i1 false), !dbg !166
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !166
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !166
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !166
// CHECK:STDOUT:   ret void, !dbg !166
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.fc3567e4618671b9(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return) #0 !dbg !167 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiverge.Main.fc3567e4618671b9(ptr %return), !dbg !168
// CHECK:STDOUT:   ret void, !dbg !169
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427", { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "mixed.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Call32", linkageName: "_CCall32.Main", scope: null, file: !1, line: 37, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !7}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!9}
// CHECK:STDOUT: !9 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !10 = !DILocation(line: 38, column: 10, scope: !4)
// CHECK:STDOUT: !11 = !DILocation(line: 38, column: 3, scope: !4)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "Call64", linkageName: "_CCall64.Main", scope: null, file: !1, line: 41, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !13)
// CHECK:STDOUT: !13 = !{!14}
// CHECK:STDOUT: !14 = !DILocalVariable(arg: 1, scope: !12, type: !7)
// CHECK:STDOUT: !15 = !DILocation(line: 42, column: 10, scope: !12)
// CHECK:STDOUT: !16 = !DILocation(line: 42, column: 3, scope: !12)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "MakeErr64", linkageName: "_CMakeErr64.Main", scope: null, file: !1, line: 48, type: !18, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !21)
// CHECK:STDOUT: !18 = !DISubroutineType(types: !19)
// CHECK:STDOUT: !19 = !{!7, !20}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!22}
// CHECK:STDOUT: !22 = !DILocalVariable(arg: 1, scope: !17, type: !20)
// CHECK:STDOUT: !23 = !DILocation(line: 49, column: 10, scope: !17)
// CHECK:STDOUT: !24 = !DILocation(line: 49, column: 3, scope: !17)
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "ReadErr64", linkageName: "_CReadErr64.Main", scope: null, file: !1, line: 54, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !28)
// CHECK:STDOUT: !26 = !DISubroutineType(types: !27)
// CHECK:STDOUT: !27 = !{!20, !7}
// CHECK:STDOUT: !28 = !{!29}
// CHECK:STDOUT: !29 = !DILocalVariable(arg: 1, scope: !25, type: !7)
// CHECK:STDOUT: !30 = !DILocation(line: 60, column: 5, scope: !25)
// CHECK:STDOUT: !31 = !DILocation(line: 60, column: 27, scope: !25)
// CHECK:STDOUT: !32 = !DILocation(line: 61, column: 5, scope: !25)
// CHECK:STDOUT: !33 = !DILocation(line: 61, column: 28, scope: !25)
// CHECK:STDOUT: !34 = !DILocation(line: 64, column: 3, scope: !25)
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "Op", linkageName: "_COp.945345cbed56cb88:core.Destroy.Core", scope: null, file: !1, line: 31, type: !36, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !39)
// CHECK:STDOUT: !36 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !37 = !{null, !38}
// CHECK:STDOUT: !38 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !39 = !{!40}
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !35, type: !38)
// CHECK:STDOUT: !41 = !DILocation(line: 31, column: 34, scope: !35)
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 31, type: !43, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !45)
// CHECK:STDOUT: !43 = !DISubroutineType(types: !44)
// CHECK:STDOUT: !44 = !{null, !20}
// CHECK:STDOUT: !45 = !{!46}
// CHECK:STDOUT: !46 = !DILocalVariable(arg: 1, scope: !42, type: !20)
// CHECK:STDOUT: !47 = !DILocation(line: 31, column: 34, scope: !42)
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "Op", linkageName: "_COp.216a6481b641f07b:core.Destroy.Core", scope: null, file: !1, line: 31, type: !49, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !51)
// CHECK:STDOUT: !49 = !DISubroutineType(types: !50)
// CHECK:STDOUT: !50 = !{null, !7}
// CHECK:STDOUT: !51 = !{!52}
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !48, type: !7)
// CHECK:STDOUT: !53 = !DILocation(line: 31, column: 34, scope: !48)
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "Op", linkageName: "_COp.39976c684c12c16f:core.Destroy.Core", scope: null, file: !1, line: 31, type: !49, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !55)
// CHECK:STDOUT: !55 = !{!56}
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !54, type: !7)
// CHECK:STDOUT: !57 = !DILocation(line: 31, column: 34, scope: !54)
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "Op", linkageName: "_COp.6f70ad92790b7b3d:core.Destroy.Core", scope: null, file: !1, line: 31, type: !49, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !59)
// CHECK:STDOUT: !59 = !{!60}
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !58, type: !7)
// CHECK:STDOUT: !61 = !DILocation(line: 31, column: 34, scope: !58)
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "Op", linkageName: "_COp.51939fc15d8db062:core.Destroy.Core", scope: null, file: !1, line: 31, type: !49, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !63)
// CHECK:STDOUT: !63 = !{!64}
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !62, type: !7)
// CHECK:STDOUT: !65 = !DILocation(line: 31, column: 34, scope: !62)
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5f42013854821c52:core.Destroy.Core", scope: null, file: !1, line: 31, type: !67, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !70)
// CHECK:STDOUT: !67 = !DISubroutineType(types: !68)
// CHECK:STDOUT: !68 = !{null, !69}
// CHECK:STDOUT: !69 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !70 = !{!71}
// CHECK:STDOUT: !71 = !DILocalVariable(arg: 1, scope: !66, type: !69)
// CHECK:STDOUT: !72 = !DILocation(line: 31, column: 34, scope: !66)
// CHECK:STDOUT: !73 = distinct !DISubprogram(name: "Op", linkageName: "_COp.62437d0fc7766a41:core.Destroy.Core", scope: null, file: !1, line: 31, type: !49, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !74)
// CHECK:STDOUT: !74 = !{!75}
// CHECK:STDOUT: !75 = !DILocalVariable(arg: 1, scope: !73, type: !7)
// CHECK:STDOUT: !76 = !DILocation(line: 31, column: 34, scope: !73)
// CHECK:STDOUT: !77 = distinct !DISubprogram(name: "Op", linkageName: "_COp.4a128e99f244da38:core.Destroy.Core", scope: null, file: !1, line: 31, type: !49, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !78)
// CHECK:STDOUT: !78 = !{!79}
// CHECK:STDOUT: !79 = !DILocalVariable(arg: 1, scope: !77, type: !7)
// CHECK:STDOUT: !80 = !DILocation(line: 31, column: 34, scope: !77)
// CHECK:STDOUT: !81 = distinct !DISubprogram(name: "Op", linkageName: "_COp.37ea992d2bcf2c08:core.Destroy.Core", scope: null, file: !1, line: 31, type: !49, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !82)
// CHECK:STDOUT: !82 = !{!83}
// CHECK:STDOUT: !83 = !DILocalVariable(arg: 1, scope: !81, type: !7)
// CHECK:STDOUT: !84 = !DILocation(line: 31, column: 34, scope: !81)
// CHECK:STDOUT: !85 = distinct !DISubprogram(name: "Op", linkageName: "_COp.e292046f58666a75:core.Destroy.Core", scope: null, file: !1, line: 31, type: !49, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !86)
// CHECK:STDOUT: !86 = !{!87}
// CHECK:STDOUT: !87 = !DILocalVariable(arg: 1, scope: !85, type: !7)
// CHECK:STDOUT: !88 = !DILocation(line: 31, column: 34, scope: !85)
// CHECK:STDOUT: !89 = distinct !DISubprogram(name: "PropagateOnly", linkageName: "_CPropagateOnly.Main.74e35ed26b9760b3", scope: null, file: !1, line: 30, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !90)
// CHECK:STDOUT: !90 = !{!91}
// CHECK:STDOUT: !91 = !DILocalVariable(arg: 1, scope: !89, type: !7)
// CHECK:STDOUT: !92 = !DILocation(line: 31, column: 34, scope: !89)
// CHECK:STDOUT: !93 = !DILocation(line: 32, column: 10, scope: !89)
// CHECK:STDOUT: !94 = !DILocation(line: 32, column: 3, scope: !89)
// CHECK:STDOUT: !95 = distinct !DISubprogram(name: "PropagateOnly", linkageName: "_CPropagateOnly.Main.17ddbbf3e70b6f1d", scope: null, file: !1, line: 30, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !96)
// CHECK:STDOUT: !96 = !{!97}
// CHECK:STDOUT: !97 = !DILocalVariable(arg: 1, scope: !95, type: !7)
// CHECK:STDOUT: !98 = !DILocation(line: 31, column: 34, scope: !95)
// CHECK:STDOUT: !99 = !DILocation(line: 32, column: 10, scope: !95)
// CHECK:STDOUT: !100 = !DILocation(line: 32, column: 3, scope: !95)
// CHECK:STDOUT: !101 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.b7dd877894074427", scope: null, file: !1, line: 3, type: !18, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !102)
// CHECK:STDOUT: !102 = !{!103}
// CHECK:STDOUT: !103 = !DILocalVariable(arg: 1, scope: !101, type: !20)
// CHECK:STDOUT: !104 = !DILocation(line: 3, column: 1, scope: !101)
// CHECK:STDOUT: !105 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !1, line: 15, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !106)
// CHECK:STDOUT: !106 = !{!107}
// CHECK:STDOUT: !107 = !DILocalVariable(arg: 1, scope: !105, type: !7)
// CHECK:STDOUT: !108 = !DILocation(line: 17, column: 7, scope: !105)
// CHECK:STDOUT: !109 = !DILocation(line: 17, column: 34, scope: !105)
// CHECK:STDOUT: !110 = !DILocation(line: 17, column: 27, scope: !105)
// CHECK:STDOUT: !111 = !DILocation(line: 18, column: 7, scope: !105)
// CHECK:STDOUT: !112 = !DILocation(line: 18, column: 35, scope: !105)
// CHECK:STDOUT: !113 = !DILocation(line: 18, column: 28, scope: !105)
// CHECK:STDOUT: !114 = !DILocation(line: 22, column: 12, scope: !105)
// CHECK:STDOUT: !115 = !DILocation(line: 22, column: 5, scope: !105)
// CHECK:STDOUT: !116 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !1, line: 24, type: !18, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !117)
// CHECK:STDOUT: !117 = !{!118}
// CHECK:STDOUT: !118 = !DILocalVariable(arg: 1, scope: !116, type: !20)
// CHECK:STDOUT: !119 = !DILocation(line: 24, column: 39, scope: !116)
// CHECK:STDOUT: !120 = !DILocation(line: 24, column: 32, scope: !116)
// CHECK:STDOUT: !121 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427", scope: null, file: !1, line: 15, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !122)
// CHECK:STDOUT: !122 = !{!123}
// CHECK:STDOUT: !123 = !DILocalVariable(arg: 1, scope: !121, type: !7)
// CHECK:STDOUT: !124 = !DILocation(line: 17, column: 7, scope: !121)
// CHECK:STDOUT: !125 = !DILocation(line: 17, column: 34, scope: !121)
// CHECK:STDOUT: !126 = !DILocation(line: 17, column: 27, scope: !121)
// CHECK:STDOUT: !127 = !DILocation(line: 18, column: 7, scope: !121)
// CHECK:STDOUT: !128 = !DILocation(line: 18, column: 35, scope: !121)
// CHECK:STDOUT: !129 = !DILocation(line: 18, column: 28, scope: !121)
// CHECK:STDOUT: !130 = !DILocation(line: 22, column: 12, scope: !121)
// CHECK:STDOUT: !131 = !DILocation(line: 22, column: 5, scope: !121)
// CHECK:STDOUT: !132 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427", scope: null, file: !1, line: 24, type: !18, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !133)
// CHECK:STDOUT: !133 = !{!134}
// CHECK:STDOUT: !134 = !DILocalVariable(arg: 1, scope: !132, type: !20)
// CHECK:STDOUT: !135 = !DILocation(line: 24, column: 39, scope: !132)
// CHECK:STDOUT: !136 = !DILocation(line: 24, column: 32, scope: !132)
// CHECK:STDOUT: !137 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.8122a03446648385", scope: null, file: !138, line: 21, type: !18, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !139)
// CHECK:STDOUT: !138 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !139 = !{!140}
// CHECK:STDOUT: !140 = !DILocalVariable(arg: 1, scope: !137, type: !20)
// CHECK:STDOUT: !141 = !DILocation(line: 21, column: 1, scope: !137)
// CHECK:STDOUT: !142 = !DILocation(line: 22, column: 21, scope: !137)
// CHECK:STDOUT: !143 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.8122a03446648385", scope: null, file: !138, line: 21, type: !18, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !144)
// CHECK:STDOUT: !144 = !{!145}
// CHECK:STDOUT: !145 = !DILocalVariable(arg: 1, scope: !143, type: !20)
// CHECK:STDOUT: !146 = !DILocation(line: 21, column: 1, scope: !143)
// CHECK:STDOUT: !147 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.9bba81283511934f", scope: null, file: !1, line: 11, type: !148, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !148 = !DISubroutineType(types: !149)
// CHECK:STDOUT: !149 = !{!7}
// CHECK:STDOUT: !150 = !DILocation(line: 11, column: 45, scope: !147)
// CHECK:STDOUT: !151 = !DILocation(line: 11, column: 38, scope: !147)
// CHECK:STDOUT: !152 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.8122a03446648385", scope: null, file: !1, line: 3, type: !18, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !153)
// CHECK:STDOUT: !153 = !{!154}
// CHECK:STDOUT: !154 = !DILocalVariable(arg: 1, scope: !152, type: !20)
// CHECK:STDOUT: !155 = !DILocation(line: 3, column: 1, scope: !152)
// CHECK:STDOUT: !156 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.b7dd877894074427", scope: null, file: !138, line: 21, type: !157, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !159)
// CHECK:STDOUT: !157 = !DISubroutineType(types: !158)
// CHECK:STDOUT: !158 = !{!7, !69}
// CHECK:STDOUT: !159 = !{!160}
// CHECK:STDOUT: !160 = !DILocalVariable(arg: 1, scope: !156, type: !69)
// CHECK:STDOUT: !161 = !DILocation(line: 21, column: 1, scope: !156)
// CHECK:STDOUT: !162 = !DILocation(line: 22, column: 21, scope: !156)
// CHECK:STDOUT: !163 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.b7dd877894074427", scope: null, file: !138, line: 21, type: !18, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !164)
// CHECK:STDOUT: !164 = !{!165}
// CHECK:STDOUT: !165 = !DILocalVariable(arg: 1, scope: !163, type: !20)
// CHECK:STDOUT: !166 = !DILocation(line: 21, column: 1, scope: !163)
// CHECK:STDOUT: !167 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.fc3567e4618671b9", scope: null, file: !1, line: 11, type: !148, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !168 = !DILocation(line: 11, column: 45, scope: !167)
// CHECK:STDOUT: !169 = !DILocation(line: 11, column: 38, scope: !167)
// CHECK:STDOUT:

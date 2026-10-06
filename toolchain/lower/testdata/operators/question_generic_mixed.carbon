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
// CHECK:STDOUT: define void @_CCall32.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %r) #0 !dbg !24 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CPropagateOnly.Main.74e35ed26b9760b3(ptr %return, ptr %r), !dbg !30
// CHECK:STDOUT:   ret void, !dbg !31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall64.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %r) #0 !dbg !33 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CPropagateOnly.Main.17ddbbf3e70b6f1d(ptr %return, ptr %r), !dbg !39
// CHECK:STDOUT:   ret void, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeErr64.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %tag) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.b7dd877894074427(ptr %return, i32 %tag), !dbg !48
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CReadErr64.Main(ptr %r) #0 !dbg !51 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc60_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %r, i32 0, i32 0, !dbg !57
// CHECK:STDOUT:   %.loc60_22.4 = load i8, ptr %.loc60_22.3.discriminant, align 1, !dbg !57
// CHECK:STDOUT:   %.loc60_22.41 = trunc i8 %.loc60_22.4 to i1, !dbg !57
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc60 = icmp eq i1 false, %.loc60_22.41, !dbg !57
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc60, label %match.case.then.loc60, label %match.case.else.loc60, !dbg !57
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc60:                            ; preds = %entry
// CHECK:STDOUT:   %.loc60_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %r, i32 0, i32 1, !dbg !57
// CHECK:STDOUT:   %.loc60_22.8.Ok = getelementptr inbounds nuw [8 x i8], ptr %.loc60_22.7.payload, i32 0, i32 0, !dbg !57
// CHECK:STDOUT:   %tuple.elem0.loc60.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc60_22.8.Ok, i32 0, i32 0, !dbg !57
// CHECK:STDOUT:   %.loc60_22.9 = load i64, ptr %tuple.elem0.loc60.tuple.elem, align 8, !dbg !57
// CHECK:STDOUT:   ret i32 0, !dbg !59
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc60:                            ; preds = %entry
// CHECK:STDOUT:   %.loc61_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %r, i32 0, i32 0, !dbg !60
// CHECK:STDOUT:   %.loc61_23.4 = load i8, ptr %.loc61_23.3.discriminant, align 1, !dbg !60
// CHECK:STDOUT:   %.loc61_23.42 = trunc i8 %.loc61_23.4 to i1, !dbg !60
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc61 = icmp eq i1 true, %.loc61_23.42, !dbg !60
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc61, label %match.case.then.loc61, label %match.done, !dbg !60
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc61:                            ; preds = %match.case.else.loc60
// CHECK:STDOUT:   %.loc61_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %r, i32 0, i32 1, !dbg !60
// CHECK:STDOUT:   %.loc61_23.8.Err = getelementptr inbounds nuw [8 x i8], ptr %.loc61_23.7.payload, i32 0, i32 0, !dbg !60
// CHECK:STDOUT:   %tuple.elem0.loc61.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc61_23.8.Err, i32 0, i32 0, !dbg !60
// CHECK:STDOUT:   %.loc61_23.9 = load i32, ptr %tuple.elem0.loc61.tuple.elem, align 4, !dbg !60
// CHECK:STDOUT:   ret i32 %.loc61_23.9, !dbg !63
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc60
// CHECK:STDOUT:   ret i32 -1, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !67 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !71 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !73
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !75 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !77
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !77
// CHECK:STDOUT:   ret void, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !79 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !81
// CHECK:STDOUT:   ret void, !dbg !81
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core"(ptr %self) #0 !dbg !83 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !85
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b63d267505e804f2:core.Destroy.Core"(ptr %self) #0 !dbg !87 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core"(ptr %self), !dbg !89
// CHECK:STDOUT:   ret void, !dbg !89
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.88b1683142354768:core.Destroy.Core"(ptr %self) #0 !dbg !91 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc31_35.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !93
// CHECK:STDOUT:   call void @"_CSelfDestruct.b63d267505e804f2:core.Destroy.Core"(ptr %.loc31_35.1.payload), !dbg !93
// CHECK:STDOUT:   %.loc31_35.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !93
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc31_35.2.discriminant), !dbg !93
// CHECK:STDOUT:   ret void, !dbg !93
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.88b1683142354768:core.Destroy.Core"(ptr %self) #0 !dbg !95 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.88b1683142354768:core.Destroy.Core"(ptr %self), !dbg !97
// CHECK:STDOUT:   ret void, !dbg !97
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core"(ptr %self) #0 !dbg !99 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !101
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %self) #0 !dbg !103 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core"(ptr %self), !dbg !105
// CHECK:STDOUT:   ret void, !dbg !105
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !107 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !109
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.f67381d184fb2c27:core.Destroy.Core"(ptr %self) #0 !dbg !111 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %self, i32 0, i32 0, !dbg !113
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !113
// CHECK:STDOUT:   ret void, !dbg !113
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f67381d184fb2c27:core.Destroy.Core"(ptr %self) #0 !dbg !115 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.f67381d184fb2c27:core.Destroy.Core"(ptr %self), !dbg !117
// CHECK:STDOUT:   ret void, !dbg !117
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.75fa817956543446:core.Destroy.Core"(ptr %self) #0 !dbg !119 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !121
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.75fa817956543446:core.Destroy.Core"(ptr %self) #0 !dbg !123 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.75fa817956543446:core.Destroy.Core"(ptr %self), !dbg !125
// CHECK:STDOUT:   ret void, !dbg !125
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.c1f61786be347789:core.Destroy.Core"(ptr %self) #0 !dbg !127 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc31_35.1.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !129
// CHECK:STDOUT:   call void @"_CSelfDestruct.75fa817956543446:core.Destroy.Core"(ptr %.loc31_35.1.payload), !dbg !129
// CHECK:STDOUT:   %.loc31_35.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !129
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc31_35.2.discriminant), !dbg !129
// CHECK:STDOUT:   ret void, !dbg !129
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.c1f61786be347789:core.Destroy.Core"(ptr %self) #0 !dbg !131 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.c1f61786be347789:core.Destroy.Core"(ptr %self), !dbg !133
// CHECK:STDOUT:   ret void, !dbg !133
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.3dff857b72298492:core.Destroy.Core"(ptr %self) #0 !dbg !135 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !137
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.3dff857b72298492:core.Destroy.Core"(ptr %self) #0 !dbg !139 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.3dff857b72298492:core.Destroy.Core"(ptr %self), !dbg !141
// CHECK:STDOUT:   ret void, !dbg !141
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CPropagateOnly.Main.74e35ed26b9760b3(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %r) #0 !dbg !143 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc31_35.3.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !148
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc31_35.3.temp), !dbg !148
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %.loc31_35.3.temp, ptr %r), !dbg !148
// CHECK:STDOUT:   %.loc31_35.7.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc31_35.3.temp, i32 0, i32 0, !dbg !148
// CHECK:STDOUT:   %.loc31_35.8 = load i8, ptr %.loc31_35.7.discriminant, align 1, !dbg !148
// CHECK:STDOUT:   %.loc31_35.81 = trunc i8 %.loc31_35.8 to i1, !dbg !148
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc31_35.81, !dbg !148
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc31_35.1, label %.loc31_35.2, !dbg !148
// CHECK:STDOUT:
// CHECK:STDOUT: .loc31_35.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc31_35.11.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc31_35.3.temp, i32 0, i32 1, !dbg !148
// CHECK:STDOUT:   %.loc31_35.12.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc31_35.11.payload, i32 0, i32 0, !dbg !148
// CHECK:STDOUT:   %tuple.elem0.loc31_35.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc31_35.12.Break, i32 0, i32 0, !dbg !148
// CHECK:STDOUT:   %.loc31_35.13 = load i32, ptr %tuple.elem0.loc31_35.1.tuple.elem, align 4, !dbg !148
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %.loc31_35.13), !dbg !148
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc31_35.3.temp), !dbg !148
// CHECK:STDOUT:   ret void, !dbg !148
// CHECK:STDOUT:
// CHECK:STDOUT: .loc31_35.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc31_35.17.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc31_35.3.temp, i32 0, i32 1, !dbg !148
// CHECK:STDOUT:   %.loc31_35.18.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc31_35.17.payload, i32 0, i32 0, !dbg !148
// CHECK:STDOUT:   %tuple.elem0.loc31_35.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc31_35.18.Continue, i32 0, i32 0, !dbg !148
// CHECK:STDOUT:   %.loc31_35.19 = load i32, ptr %tuple.elem0.loc31_35.2.tuple.elem, align 4, !dbg !148
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 0), !dbg !151
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc31_35.3.temp), !dbg !148
// CHECK:STDOUT:   ret void, !dbg !152
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CPropagateOnly.Main.17ddbbf3e70b6f1d(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %r) #0 !dbg !154 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc31_35.3.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !159
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc31_35.3.temp), !dbg !159
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %.loc31_35.3.temp, ptr %r), !dbg !159
// CHECK:STDOUT:   %.loc31_35.7.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc31_35.3.temp, i32 0, i32 0, !dbg !159
// CHECK:STDOUT:   %.loc31_35.8 = load i8, ptr %.loc31_35.7.discriminant, align 1, !dbg !159
// CHECK:STDOUT:   %.loc31_35.81 = trunc i8 %.loc31_35.8 to i1, !dbg !159
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc31_35.81, !dbg !159
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc31_35.1, label %.loc31_35.2, !dbg !159
// CHECK:STDOUT:
// CHECK:STDOUT: .loc31_35.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc31_35.11.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc31_35.3.temp, i32 0, i32 1, !dbg !159
// CHECK:STDOUT:   %.loc31_35.12.Break = getelementptr inbounds nuw [8 x i8], ptr %.loc31_35.11.payload, i32 0, i32 0, !dbg !159
// CHECK:STDOUT:   %tuple.elem0.loc31_35.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc31_35.12.Break, i32 0, i32 0, !dbg !159
// CHECK:STDOUT:   %.loc31_35.13 = load i32, ptr %tuple.elem0.loc31_35.1.tuple.elem, align 4, !dbg !159
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %return, i32 %.loc31_35.13), !dbg !159
// CHECK:STDOUT:   call void @"_CSelfDestruct.3dff857b72298492:core.Destroy.Core"(ptr %.loc31_35.3.temp), !dbg !159
// CHECK:STDOUT:   ret void, !dbg !159
// CHECK:STDOUT:
// CHECK:STDOUT: .loc31_35.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc31_35.17.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc31_35.3.temp, i32 0, i32 1, !dbg !159
// CHECK:STDOUT:   %.loc31_35.18.Continue = getelementptr inbounds nuw [8 x i8], ptr %.loc31_35.17.payload, i32 0, i32 0, !dbg !159
// CHECK:STDOUT:   %tuple.elem0.loc31_35.2.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc31_35.18.Continue, i32 0, i32 0, !dbg !159
// CHECK:STDOUT:   %.loc31_35.19 = load i64, ptr %tuple.elem0.loc31_35.2.tuple.elem, align 8, !dbg !159
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %return, i32 0), !dbg !162
// CHECK:STDOUT:   call void @"_CSelfDestruct.3dff857b72298492:core.Destroy.Core"(ptr %.loc31_35.3.temp), !dbg !159
// CHECK:STDOUT:   ret void, !dbg !163
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !165 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !167
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !167
// CHECK:STDOUT:   %.loc3_35.5.Err = getelementptr inbounds nuw [8 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !167
// CHECK:STDOUT:   %.loc6_1.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !167
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @MyResult.val.142.loc3_35.7, i64 16, i1 false), !dbg !167
// CHECK:STDOUT:   store { i32 } %.loc6_1.1.tuple.init, ptr %.loc3_35.5.Err, align 4, !dbg !167
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Err, i32 0, i32 0, !dbg !167
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !167
// CHECK:STDOUT:   ret void, !dbg !167
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !169 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !175
// CHECK:STDOUT:   %.loc17_22.4 = load i8, ptr %.loc17_22.3.discriminant, align 1, !dbg !175
// CHECK:STDOUT:   %.loc17_22.41 = trunc i8 %.loc17_22.4 to i1, !dbg !175
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc17 = icmp eq i1 false, %.loc17_22.41, !dbg !175
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc17, label %match.case.then.loc17, label %match.case.else.loc17, !dbg !175
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc17_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !175
// CHECK:STDOUT:   %.loc17_22.8.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc17_22.7.payload, i32 0, i32 0, !dbg !175
// CHECK:STDOUT:   %tuple.elem0.loc17.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc17_22.8.Ok, i32 0, i32 0, !dbg !175
// CHECK:STDOUT:   %.loc17_22.9 = load i32, ptr %tuple.elem0.loc17.tuple.elem, align 4, !dbg !175
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc17_22.9), !dbg !178
// CHECK:STDOUT:   ret void, !dbg !179
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc18_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !180
// CHECK:STDOUT:   %.loc18_23.4 = load i8, ptr %.loc18_23.3.discriminant, align 1, !dbg !180
// CHECK:STDOUT:   %.loc18_23.42 = trunc i8 %.loc18_23.4 to i1, !dbg !180
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc18 = icmp eq i1 true, %.loc18_23.42, !dbg !180
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc18, label %match.case.then.loc18, label %match.done, !dbg !180
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc18:                            ; preds = %match.case.else.loc17
// CHECK:STDOUT:   %.loc18_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !180
// CHECK:STDOUT:   %.loc18_23.8.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc18_23.7.payload, i32 0, i32 0, !dbg !180
// CHECK:STDOUT:   %tuple.elem0.loc18.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc18_23.8.Err, i32 0, i32 0, !dbg !180
// CHECK:STDOUT:   %.loc18_23.9 = load i32, ptr %tuple.elem0.loc18.tuple.elem, align 4, !dbg !180
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc18_23.9), !dbg !183
// CHECK:STDOUT:   ret void, !dbg !184
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc17
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !186
// CHECK:STDOUT:   ret void, !dbg !189
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %e) #0 !dbg !191 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %e), !dbg !197
// CHECK:STDOUT:   ret void, !dbg !198
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %self) #0 !dbg !200 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !206
// CHECK:STDOUT:   %.loc17_22.4 = load i8, ptr %.loc17_22.3.discriminant, align 1, !dbg !206
// CHECK:STDOUT:   %.loc17_22.41 = trunc i8 %.loc17_22.4 to i1, !dbg !206
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc17 = icmp eq i1 false, %.loc17_22.41, !dbg !206
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc17, label %match.case.then.loc17, label %match.case.else.loc17, !dbg !206
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc17_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !206
// CHECK:STDOUT:   %.loc17_22.8.Ok = getelementptr inbounds nuw [8 x i8], ptr %.loc17_22.7.payload, i32 0, i32 0, !dbg !206
// CHECK:STDOUT:   %tuple.elem0.loc17.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc17_22.8.Ok, i32 0, i32 0, !dbg !206
// CHECK:STDOUT:   %.loc17_22.9 = load i64, ptr %tuple.elem0.loc17.tuple.elem, align 8, !dbg !206
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.b7dd877894074427(ptr %return, i64 %.loc17_22.9), !dbg !209
// CHECK:STDOUT:   ret void, !dbg !212
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc18_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !213
// CHECK:STDOUT:   %.loc18_23.4 = load i8, ptr %.loc18_23.3.discriminant, align 1, !dbg !213
// CHECK:STDOUT:   %.loc18_23.42 = trunc i8 %.loc18_23.4 to i1, !dbg !213
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc18 = icmp eq i1 true, %.loc18_23.42, !dbg !213
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc18, label %match.case.then.loc18, label %match.done, !dbg !213
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc18:                            ; preds = %match.case.else.loc17
// CHECK:STDOUT:   %.loc18_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !213
// CHECK:STDOUT:   %.loc18_23.8.Err = getelementptr inbounds nuw [8 x i8], ptr %.loc18_23.7.payload, i32 0, i32 0, !dbg !213
// CHECK:STDOUT:   %tuple.elem0.loc18.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc18_23.8.Err, i32 0, i32 0, !dbg !213
// CHECK:STDOUT:   %.loc18_23.9 = load i32, ptr %tuple.elem0.loc18.tuple.elem, align 4, !dbg !213
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.b7dd877894074427(ptr %return, i32 %.loc18_23.9), !dbg !216
// CHECK:STDOUT:   ret void, !dbg !217
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc17
// CHECK:STDOUT:   call void @_CDiverge.Main.fc3567e4618671b9(ptr %return), !dbg !219
// CHECK:STDOUT:   ret void, !dbg !220
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %e) #0 !dbg !222 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.b7dd877894074427(ptr %return, i32 %e), !dbg !228
// CHECK:STDOUT:   ret void, !dbg !229
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !232 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !234
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !234
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !234
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !235
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.f6c.anon, i64 8, i1 false), !dbg !234
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !234
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !235
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !235
// CHECK:STDOUT:   ret void, !dbg !234
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !237 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !239
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !239
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !239
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !239
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.493.anon, i64 8, i1 false), !dbg !239
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !239
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !239
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !239
// CHECK:STDOUT:   ret void, !dbg !239
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.9bba81283511934f(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !241 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !244
// CHECK:STDOUT:   ret void, !dbg !245
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !246 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !248
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !248
// CHECK:STDOUT:   %.loc3_35.5.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !248
// CHECK:STDOUT:   %.loc6_1.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !248
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.df1.loc3_35.7, i64 8, i1 false), !dbg !248
// CHECK:STDOUT:   store { i32 } %.loc6_1.1.tuple.init, ptr %.loc3_35.5.Err, align 4, !dbg !248
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Err, i32 0, i32 0, !dbg !248
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !248
// CHECK:STDOUT:   ret void, !dbg !248
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %_) #0 !dbg !250 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !252
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !252
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !252
// CHECK:STDOUT:   %tuple.init = insertvalue { i64 } poison, i64 %_, 0, !dbg !253
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.fa9.anon, i64 16, i1 false), !dbg !252
// CHECK:STDOUT:   store { i64 } %tuple.init, ptr %Continue, align 8, !dbg !252
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i64 }, ptr %Continue, i32 0, i32 0, !dbg !253
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem, align 8, !dbg !253
// CHECK:STDOUT:   ret void, !dbg !252
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !255 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !257
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !257
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !257
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !257
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.d01.anon, i64 16, i1 false), !dbg !257
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !257
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !257
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !257
// CHECK:STDOUT:   ret void, !dbg !257
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.fc3567e4618671b9(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return) #0 !dbg !259 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiverge.Main.fc3567e4618671b9(ptr %return), !dbg !262
// CHECK:STDOUT:   ret void, !dbg !263
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "mixed.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!9, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!9, !7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{!7, !9}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !16 = !{null, !6}
// CHECK:STDOUT: !17 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !18 = !{null, !7}
// CHECK:STDOUT: !19 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !20 = !{null, !9}
// CHECK:STDOUT: !21 = !DISubroutineType(types: !20)
// CHECK:STDOUT: !22 = !{null, !8}
// CHECK:STDOUT: !23 = !DISubroutineType(types: !22)
// CHECK:STDOUT: !24 = distinct !DISubprogram(name: "Call32", linkageName: "_CCall32.Main", scope: null, file: !4, line: 37, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !32)
// CHECK:STDOUT: !25 = !DILocalVariable(arg: 1, scope: !24, type: !9)
// CHECK:STDOUT: !30 = !DILocation(line: 38, column: 10, scope: !24)
// CHECK:STDOUT: !31 = !DILocation(line: 38, column: 3, scope: !24)
// CHECK:STDOUT: !32 = !{!25}
// CHECK:STDOUT: !33 = distinct !DISubprogram(name: "Call64", linkageName: "_CCall64.Main", scope: null, file: !4, line: 41, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !41)
// CHECK:STDOUT: !34 = !DILocalVariable(arg: 1, scope: !33, type: !9)
// CHECK:STDOUT: !39 = !DILocation(line: 42, column: 10, scope: !33)
// CHECK:STDOUT: !40 = !DILocation(line: 42, column: 3, scope: !33)
// CHECK:STDOUT: !41 = !{!34}
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "MakeErr64", linkageName: "_CMakeErr64.Main", scope: null, file: !4, line: 48, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !50)
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !42, type: !7)
// CHECK:STDOUT: !48 = !DILocation(line: 49, column: 10, scope: !42)
// CHECK:STDOUT: !49 = !DILocation(line: 49, column: 3, scope: !42)
// CHECK:STDOUT: !50 = !{!43}
// CHECK:STDOUT: !51 = distinct !DISubprogram(name: "ReadErr64", linkageName: "_CReadErr64.Main", scope: null, file: !4, line: 54, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !66)
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !51, type: !9)
// CHECK:STDOUT: !57 = !DILocation(line: 60, column: 5, scope: !51)
// CHECK:STDOUT: !59 = !DILocation(line: 60, column: 27, scope: !51)
// CHECK:STDOUT: !60 = !DILocation(line: 61, column: 5, scope: !51)
// CHECK:STDOUT: !63 = !DILocation(line: 61, column: 28, scope: !51)
// CHECK:STDOUT: !65 = !DILocation(line: 64, column: 3, scope: !51)
// CHECK:STDOUT: !66 = !{!52}
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !4, line: 31, type: !17, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !70)
// CHECK:STDOUT: !68 = !DILocalVariable(arg: 1, scope: !67, type: !6)
// CHECK:STDOUT: !69 = !DILocation(line: 31, column: 34, scope: !67)
// CHECK:STDOUT: !70 = !{!68}
// CHECK:STDOUT: !71 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 31, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !74)
// CHECK:STDOUT: !72 = !DILocalVariable(arg: 1, scope: !71, type: !7)
// CHECK:STDOUT: !73 = !DILocation(line: 31, column: 34, scope: !71)
// CHECK:STDOUT: !74 = !{!72}
// CHECK:STDOUT: !75 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 31, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !78)
// CHECK:STDOUT: !76 = !DILocalVariable(arg: 1, scope: !75, type: !9)
// CHECK:STDOUT: !77 = !DILocation(line: 31, column: 34, scope: !75)
// CHECK:STDOUT: !78 = !{!76}
// CHECK:STDOUT: !79 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 31, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !82)
// CHECK:STDOUT: !80 = !DILocalVariable(arg: 1, scope: !79, type: !9)
// CHECK:STDOUT: !81 = !DILocation(line: 31, column: 34, scope: !79)
// CHECK:STDOUT: !82 = !{!80}
// CHECK:STDOUT: !83 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core", scope: null, file: !4, line: 31, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !86)
// CHECK:STDOUT: !84 = !DILocalVariable(arg: 1, scope: !83, type: !9)
// CHECK:STDOUT: !85 = !DILocation(line: 31, column: 34, scope: !83)
// CHECK:STDOUT: !86 = !{!84}
// CHECK:STDOUT: !87 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b63d267505e804f2:core.Destroy.Core", scope: null, file: !4, line: 31, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !90)
// CHECK:STDOUT: !88 = !DILocalVariable(arg: 1, scope: !87, type: !9)
// CHECK:STDOUT: !89 = !DILocation(line: 31, column: 34, scope: !87)
// CHECK:STDOUT: !90 = !{!88}
// CHECK:STDOUT: !91 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.88b1683142354768:core.Destroy.Core", scope: null, file: !4, line: 31, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !94)
// CHECK:STDOUT: !92 = !DILocalVariable(arg: 1, scope: !91, type: !9)
// CHECK:STDOUT: !93 = !DILocation(line: 31, column: 34, scope: !91)
// CHECK:STDOUT: !94 = !{!92}
// CHECK:STDOUT: !95 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.88b1683142354768:core.Destroy.Core", scope: null, file: !4, line: 31, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !98)
// CHECK:STDOUT: !96 = !DILocalVariable(arg: 1, scope: !95, type: !9)
// CHECK:STDOUT: !97 = !DILocation(line: 31, column: 34, scope: !95)
// CHECK:STDOUT: !98 = !{!96}
// CHECK:STDOUT: !99 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core", scope: null, file: !4, line: 31, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !102)
// CHECK:STDOUT: !100 = !DILocalVariable(arg: 1, scope: !99, type: !9)
// CHECK:STDOUT: !101 = !DILocation(line: 31, column: 34, scope: !99)
// CHECK:STDOUT: !102 = !{!100}
// CHECK:STDOUT: !103 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core", scope: null, file: !4, line: 31, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !106)
// CHECK:STDOUT: !104 = !DILocalVariable(arg: 1, scope: !103, type: !9)
// CHECK:STDOUT: !105 = !DILocation(line: 31, column: 34, scope: !103)
// CHECK:STDOUT: !106 = !{!104}
// CHECK:STDOUT: !107 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !4, line: 31, type: !23, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !110)
// CHECK:STDOUT: !108 = !DILocalVariable(arg: 1, scope: !107, type: !8)
// CHECK:STDOUT: !109 = !DILocation(line: 31, column: 34, scope: !107)
// CHECK:STDOUT: !110 = !{!108}
// CHECK:STDOUT: !111 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.f67381d184fb2c27:core.Destroy.Core", scope: null, file: !4, line: 31, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !114)
// CHECK:STDOUT: !112 = !DILocalVariable(arg: 1, scope: !111, type: !9)
// CHECK:STDOUT: !113 = !DILocation(line: 31, column: 34, scope: !111)
// CHECK:STDOUT: !114 = !{!112}
// CHECK:STDOUT: !115 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f67381d184fb2c27:core.Destroy.Core", scope: null, file: !4, line: 31, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !118)
// CHECK:STDOUT: !116 = !DILocalVariable(arg: 1, scope: !115, type: !9)
// CHECK:STDOUT: !117 = !DILocation(line: 31, column: 34, scope: !115)
// CHECK:STDOUT: !118 = !{!116}
// CHECK:STDOUT: !119 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.75fa817956543446:core.Destroy.Core", scope: null, file: !4, line: 31, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !122)
// CHECK:STDOUT: !120 = !DILocalVariable(arg: 1, scope: !119, type: !9)
// CHECK:STDOUT: !121 = !DILocation(line: 31, column: 34, scope: !119)
// CHECK:STDOUT: !122 = !{!120}
// CHECK:STDOUT: !123 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.75fa817956543446:core.Destroy.Core", scope: null, file: !4, line: 31, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !126)
// CHECK:STDOUT: !124 = !DILocalVariable(arg: 1, scope: !123, type: !9)
// CHECK:STDOUT: !125 = !DILocation(line: 31, column: 34, scope: !123)
// CHECK:STDOUT: !126 = !{!124}
// CHECK:STDOUT: !127 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.c1f61786be347789:core.Destroy.Core", scope: null, file: !4, line: 31, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !130)
// CHECK:STDOUT: !128 = !DILocalVariable(arg: 1, scope: !127, type: !9)
// CHECK:STDOUT: !129 = !DILocation(line: 31, column: 34, scope: !127)
// CHECK:STDOUT: !130 = !{!128}
// CHECK:STDOUT: !131 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.c1f61786be347789:core.Destroy.Core", scope: null, file: !4, line: 31, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !134)
// CHECK:STDOUT: !132 = !DILocalVariable(arg: 1, scope: !131, type: !9)
// CHECK:STDOUT: !133 = !DILocation(line: 31, column: 34, scope: !131)
// CHECK:STDOUT: !134 = !{!132}
// CHECK:STDOUT: !135 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.3dff857b72298492:core.Destroy.Core", scope: null, file: !4, line: 31, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !138)
// CHECK:STDOUT: !136 = !DILocalVariable(arg: 1, scope: !135, type: !9)
// CHECK:STDOUT: !137 = !DILocation(line: 31, column: 34, scope: !135)
// CHECK:STDOUT: !138 = !{!136}
// CHECK:STDOUT: !139 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.3dff857b72298492:core.Destroy.Core", scope: null, file: !4, line: 31, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !142)
// CHECK:STDOUT: !140 = !DILocalVariable(arg: 1, scope: !139, type: !9)
// CHECK:STDOUT: !141 = !DILocation(line: 31, column: 34, scope: !139)
// CHECK:STDOUT: !142 = !{!140}
// CHECK:STDOUT: !143 = distinct !DISubprogram(name: "PropagateOnly", linkageName: "_CPropagateOnly.Main.74e35ed26b9760b3", scope: null, file: !4, line: 30, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !153)
// CHECK:STDOUT: !144 = !DILocalVariable(arg: 1, scope: !143, type: !9)
// CHECK:STDOUT: !148 = !DILocation(line: 31, column: 34, scope: !143)
// CHECK:STDOUT: !151 = !DILocation(line: 32, column: 10, scope: !143)
// CHECK:STDOUT: !152 = !DILocation(line: 32, column: 3, scope: !143)
// CHECK:STDOUT: !153 = !{!144}
// CHECK:STDOUT: !154 = distinct !DISubprogram(name: "PropagateOnly", linkageName: "_CPropagateOnly.Main.17ddbbf3e70b6f1d", scope: null, file: !4, line: 30, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !164)
// CHECK:STDOUT: !155 = !DILocalVariable(arg: 1, scope: !154, type: !9)
// CHECK:STDOUT: !159 = !DILocation(line: 31, column: 34, scope: !154)
// CHECK:STDOUT: !162 = !DILocation(line: 32, column: 10, scope: !154)
// CHECK:STDOUT: !163 = !DILocation(line: 32, column: 3, scope: !154)
// CHECK:STDOUT: !164 = !{!155}
// CHECK:STDOUT: !165 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.b7dd877894074427", scope: null, file: !4, line: 3, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !168)
// CHECK:STDOUT: !166 = !DILocalVariable(arg: 1, scope: !165, type: !7)
// CHECK:STDOUT: !167 = !DILocation(line: 3, column: 1, scope: !165)
// CHECK:STDOUT: !168 = !{!166}
// CHECK:STDOUT: !169 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !4, line: 15, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !190)
// CHECK:STDOUT: !170 = !DILocalVariable(arg: 1, scope: !169, type: !9)
// CHECK:STDOUT: !175 = !DILocation(line: 17, column: 7, scope: !169)
// CHECK:STDOUT: !178 = !DILocation(line: 17, column: 34, scope: !169)
// CHECK:STDOUT: !179 = !DILocation(line: 17, column: 27, scope: !169)
// CHECK:STDOUT: !180 = !DILocation(line: 18, column: 7, scope: !169)
// CHECK:STDOUT: !183 = !DILocation(line: 18, column: 35, scope: !169)
// CHECK:STDOUT: !184 = !DILocation(line: 18, column: 28, scope: !169)
// CHECK:STDOUT: !186 = !DILocation(line: 22, column: 12, scope: !169)
// CHECK:STDOUT: !187 = !{!9}
// CHECK:STDOUT: !188 = !DISubroutineType(types: !187)
// CHECK:STDOUT: !189 = !DILocation(line: 22, column: 5, scope: !169)
// CHECK:STDOUT: !190 = !{!170}
// CHECK:STDOUT: !191 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !4, line: 24, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !199)
// CHECK:STDOUT: !192 = !DILocalVariable(arg: 1, scope: !191, type: !7)
// CHECK:STDOUT: !197 = !DILocation(line: 24, column: 39, scope: !191)
// CHECK:STDOUT: !198 = !DILocation(line: 24, column: 32, scope: !191)
// CHECK:STDOUT: !199 = !{!192}
// CHECK:STDOUT: !200 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427", scope: null, file: !4, line: 15, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !221)
// CHECK:STDOUT: !201 = !DILocalVariable(arg: 1, scope: !200, type: !9)
// CHECK:STDOUT: !206 = !DILocation(line: 17, column: 7, scope: !200)
// CHECK:STDOUT: !209 = !DILocation(line: 17, column: 34, scope: !200)
// CHECK:STDOUT: !210 = !{!9, !8}
// CHECK:STDOUT: !211 = !DISubroutineType(types: !210)
// CHECK:STDOUT: !212 = !DILocation(line: 17, column: 27, scope: !200)
// CHECK:STDOUT: !213 = !DILocation(line: 18, column: 7, scope: !200)
// CHECK:STDOUT: !216 = !DILocation(line: 18, column: 35, scope: !200)
// CHECK:STDOUT: !217 = !DILocation(line: 18, column: 28, scope: !200)
// CHECK:STDOUT: !219 = !DILocation(line: 22, column: 12, scope: !200)
// CHECK:STDOUT: !220 = !DILocation(line: 22, column: 5, scope: !200)
// CHECK:STDOUT: !221 = !{!201}
// CHECK:STDOUT: !222 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427", scope: null, file: !4, line: 24, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !230)
// CHECK:STDOUT: !223 = !DILocalVariable(arg: 1, scope: !222, type: !7)
// CHECK:STDOUT: !228 = !DILocation(line: 24, column: 39, scope: !222)
// CHECK:STDOUT: !229 = !DILocation(line: 24, column: 32, scope: !222)
// CHECK:STDOUT: !230 = !{!223}
// CHECK:STDOUT: !231 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !232 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.8122a03446648385", scope: null, file: !231, line: 21, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !236)
// CHECK:STDOUT: !233 = !DILocalVariable(arg: 1, scope: !232, type: !7)
// CHECK:STDOUT: !234 = !DILocation(line: 21, column: 1, scope: !232)
// CHECK:STDOUT: !235 = !DILocation(line: 22, column: 21, scope: !232)
// CHECK:STDOUT: !236 = !{!233}
// CHECK:STDOUT: !237 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.8122a03446648385", scope: null, file: !231, line: 21, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !240)
// CHECK:STDOUT: !238 = !DILocalVariable(arg: 1, scope: !237, type: !7)
// CHECK:STDOUT: !239 = !DILocation(line: 21, column: 1, scope: !237)
// CHECK:STDOUT: !240 = !{!238}
// CHECK:STDOUT: !241 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.9bba81283511934f", scope: null, file: !4, line: 11, type: !188, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !244 = !DILocation(line: 11, column: 45, scope: !241)
// CHECK:STDOUT: !245 = !DILocation(line: 11, column: 38, scope: !241)
// CHECK:STDOUT: !246 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.8122a03446648385", scope: null, file: !4, line: 3, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !249)
// CHECK:STDOUT: !247 = !DILocalVariable(arg: 1, scope: !246, type: !7)
// CHECK:STDOUT: !248 = !DILocation(line: 3, column: 1, scope: !246)
// CHECK:STDOUT: !249 = !{!247}
// CHECK:STDOUT: !250 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.b7dd877894074427", scope: null, file: !231, line: 21, type: !211, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !254)
// CHECK:STDOUT: !251 = !DILocalVariable(arg: 1, scope: !250, type: !8)
// CHECK:STDOUT: !252 = !DILocation(line: 21, column: 1, scope: !250)
// CHECK:STDOUT: !253 = !DILocation(line: 22, column: 21, scope: !250)
// CHECK:STDOUT: !254 = !{!251}
// CHECK:STDOUT: !255 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.b7dd877894074427", scope: null, file: !231, line: 21, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !258)
// CHECK:STDOUT: !256 = !DILocalVariable(arg: 1, scope: !255, type: !7)
// CHECK:STDOUT: !257 = !DILocation(line: 21, column: 1, scope: !255)
// CHECK:STDOUT: !258 = !{!256}
// CHECK:STDOUT: !259 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.fc3567e4618671b9", scope: null, file: !4, line: 11, type: !188, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !262 = !DILocation(line: 11, column: 45, scope: !259)
// CHECK:STDOUT: !263 = !DILocation(line: 11, column: 38, scope: !259)
// CHECK:STDOUT:

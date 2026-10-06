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
// CHECK:STDOUT: define void @_CLibCall32.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %x, i1 %failA, i1 %failB) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CChain.Main.84588f41d61dafba(ptr %return, i32 %x, i1 %failA, i1 %failB), !dbg !29
// CHECK:STDOUT:   ret void, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !36 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !40 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !42
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !42
// CHECK:STDOUT:   ret void, !dbg !42
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !44 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !46
// CHECK:STDOUT:   ret void, !dbg !46
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core"(ptr %self) #0 !dbg !48 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !50
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b63d267505e804f2:core.Destroy.Core"(ptr %self) #0 !dbg !52 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core"(ptr %self), !dbg !54
// CHECK:STDOUT:   ret void, !dbg !54
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.88b1683142354768:core.Destroy.Core"(ptr %self) #0 !dbg !56 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc42_30.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !58
// CHECK:STDOUT:   call void @"_CSelfDestruct.b63d267505e804f2:core.Destroy.Core"(ptr %.loc42_30.1.payload), !dbg !58
// CHECK:STDOUT:   %.loc42_30.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !58
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc42_30.2.discriminant), !dbg !58
// CHECK:STDOUT:   ret void, !dbg !58
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.88b1683142354768:core.Destroy.Core"(ptr %self) #0 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.88b1683142354768:core.Destroy.Core"(ptr %self), !dbg !62
// CHECK:STDOUT:   ret void, !dbg !62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core"(ptr %self) #0 !dbg !64 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %self) #0 !dbg !68 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core"(ptr %self), !dbg !70
// CHECK:STDOUT:   ret void, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %self) #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %self) #0 !dbg !76 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %self), !dbg !78
// CHECK:STDOUT:   ret void, !dbg !78
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.f269577697e84b3c:core.Destroy.Core"(ptr %self) #0 !dbg !80 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc42_29.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !82
// CHECK:STDOUT:   call void @"_CSelfDestruct.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %.loc42_29.1.payload), !dbg !82
// CHECK:STDOUT:   %.loc42_29.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !82
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc42_29.2.discriminant), !dbg !82
// CHECK:STDOUT:   ret void, !dbg !82
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f269577697e84b3c:core.Destroy.Core"(ptr %self) #0 !dbg !84 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.f269577697e84b3c:core.Destroy.Core"(ptr %self), !dbg !86
// CHECK:STDOUT:   ret void, !dbg !86
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.21e9b6df7c6352ff:core.Destroy.Core"(ptr %self) #0 !dbg !88 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !90
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %self) #0 !dbg !92 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.21e9b6df7c6352ff:core.Destroy.Core"(ptr %self), !dbg !94
// CHECK:STDOUT:   ret void, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CChain.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %x, i1 %failA, i1 %failB) #0 !dbg !96 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc42_29.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !107
// CHECK:STDOUT:   %.loc42_30.3.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !107
// CHECK:STDOUT:   %.loc43_29.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !117
// CHECK:STDOUT:   %.loc43_30.3.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !117
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc42_29.1.temp), !dbg !107
// CHECK:STDOUT:   call void @_CStep.Main.84588f41d61dafba(ptr %.loc42_29.1.temp, i32 %x, i1 %failA, i32 101), !dbg !107
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc42_30.3.temp), !dbg !107
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %.loc42_30.3.temp, ptr %.loc42_29.1.temp), !dbg !107
// CHECK:STDOUT:   %.loc42_30.7.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc42_30.3.temp, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   %.loc42_30.8 = load i8, ptr %.loc42_30.7.discriminant, align 1, !dbg !107
// CHECK:STDOUT:   %.loc42_30.81 = trunc i8 %.loc42_30.8 to i1, !dbg !107
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc42 = icmp eq i1 true, %.loc42_30.81, !dbg !107
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc42, label %.loc42_30.1, label %.loc42_30.2, !dbg !107
// CHECK:STDOUT:
// CHECK:STDOUT: .loc42_30.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc42_30.11.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc42_30.3.temp, i32 0, i32 1, !dbg !107
// CHECK:STDOUT:   %.loc42_30.12.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc42_30.11.payload, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   %tuple.elem0.loc42_30.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc42_30.12.Break, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   %.loc42_30.13 = load i32, ptr %tuple.elem0.loc42_30.1.tuple.elem, align 4, !dbg !107
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %.loc42_30.13), !dbg !107
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc42_30.3.temp), !dbg !107
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %.loc42_29.1.temp), !dbg !107
// CHECK:STDOUT:   ret void, !dbg !107
// CHECK:STDOUT:
// CHECK:STDOUT: .loc42_30.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc42_30.17.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc42_30.3.temp, i32 0, i32 1, !dbg !107
// CHECK:STDOUT:   %.loc42_30.18.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc42_30.17.payload, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   %tuple.elem0.loc42_30.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc42_30.18.Continue, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   %.loc42_30.19 = load i32, ptr %tuple.elem0.loc42_30.2.tuple.elem, align 4, !dbg !107
// CHECK:STDOUT:   call void @_CDiscard.Main.84588f41d61dafba(i32 %.loc42_30.19), !dbg !114
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc42_30.3.temp), !dbg !107
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %.loc42_29.1.temp), !dbg !107
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc43_29.1.temp), !dbg !117
// CHECK:STDOUT:   call void @_CStep.Main.84588f41d61dafba(ptr %.loc43_29.1.temp, i32 %x, i1 %failB, i32 202), !dbg !117
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc43_30.3.temp), !dbg !117
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %.loc43_30.3.temp, ptr %.loc43_29.1.temp), !dbg !117
// CHECK:STDOUT:   %.loc43_30.7.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc43_30.3.temp, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %.loc43_30.8 = load i8, ptr %.loc43_30.7.discriminant, align 1, !dbg !117
// CHECK:STDOUT:   %.loc43_30.82 = trunc i8 %.loc43_30.8 to i1, !dbg !117
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc43 = icmp eq i1 true, %.loc43_30.82, !dbg !117
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc43, label %.loc43_30.1, label %.loc43_30.2, !dbg !117
// CHECK:STDOUT:
// CHECK:STDOUT: .loc43_30.1:                                      ; preds = %.loc42_30.2
// CHECK:STDOUT:   %.loc43_30.11.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc43_30.3.temp, i32 0, i32 1, !dbg !117
// CHECK:STDOUT:   %.loc43_30.12.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc43_30.11.payload, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %tuple.elem0.loc43_30.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc43_30.12.Break, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %.loc43_30.13 = load i32, ptr %tuple.elem0.loc43_30.1.tuple.elem, align 4, !dbg !117
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %.loc43_30.13), !dbg !117
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc43_30.3.temp), !dbg !117
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %.loc43_29.1.temp), !dbg !117
// CHECK:STDOUT:   ret void, !dbg !117
// CHECK:STDOUT:
// CHECK:STDOUT: .loc43_30.2:                                      ; preds = %.loc42_30.2
// CHECK:STDOUT:   %.loc43_30.17.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc43_30.3.temp, i32 0, i32 1, !dbg !117
// CHECK:STDOUT:   %.loc43_30.18.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc43_30.17.payload, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %tuple.elem0.loc43_30.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc43_30.18.Continue, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %.loc43_30.19 = load i32, ptr %tuple.elem0.loc43_30.2.tuple.elem, align 4, !dbg !117
// CHECK:STDOUT:   call void @_CDiscard.Main.84588f41d61dafba(i32 %.loc43_30.19), !dbg !118
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc43_30.3.temp), !dbg !117
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %.loc43_29.1.temp), !dbg !117
// CHECK:STDOUT:   call void @_COk.MyResult.Main.8122a03446648385(ptr %return, i32 %x), !dbg !120
// CHECK:STDOUT:   ret void, !dbg !121
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CStep.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %x, i1 %fail, i32 %tag) #0 !dbg !123 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 %fail, label %if.then, label %if.else, !dbg !133
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %tag), !dbg !135
// CHECK:STDOUT:   ret void, !dbg !136
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_COk.MyResult.Main.8122a03446648385(ptr %return, i32 %x), !dbg !138
// CHECK:STDOUT:   ret void, !dbg !139
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !141 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !147
// CHECK:STDOUT:   %.loc17_22.4 = load i8, ptr %.loc17_22.3.discriminant, align 1, !dbg !147
// CHECK:STDOUT:   %.loc17_22.41 = trunc i8 %.loc17_22.4 to i1, !dbg !147
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc17 = icmp eq i1 false, %.loc17_22.41, !dbg !147
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc17, label %match.case.then.loc17, label %match.case.else.loc17, !dbg !147
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc17_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !147
// CHECK:STDOUT:   %.loc17_22.8.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc17_22.7.payload, i32 0, i32 0, !dbg !147
// CHECK:STDOUT:   %tuple.elem0.loc17.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc17_22.8.Ok, i32 0, i32 0, !dbg !147
// CHECK:STDOUT:   %.loc17_22.9 = load i32, ptr %tuple.elem0.loc17.tuple.elem, align 4, !dbg !147
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc17_22.9), !dbg !150
// CHECK:STDOUT:   ret void, !dbg !151
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc18_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !152
// CHECK:STDOUT:   %.loc18_23.4 = load i8, ptr %.loc18_23.3.discriminant, align 1, !dbg !152
// CHECK:STDOUT:   %.loc18_23.42 = trunc i8 %.loc18_23.4 to i1, !dbg !152
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc18 = icmp eq i1 true, %.loc18_23.42, !dbg !152
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc18, label %match.case.then.loc18, label %match.done, !dbg !152
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc18:                            ; preds = %match.case.else.loc17
// CHECK:STDOUT:   %.loc18_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !152
// CHECK:STDOUT:   %.loc18_23.8.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc18_23.7.payload, i32 0, i32 0, !dbg !152
// CHECK:STDOUT:   %tuple.elem0.loc18.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc18_23.8.Err, i32 0, i32 0, !dbg !152
// CHECK:STDOUT:   %.loc18_23.9 = load i32, ptr %tuple.elem0.loc18.tuple.elem, align 4, !dbg !152
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc18_23.9), !dbg !155
// CHECK:STDOUT:   ret void, !dbg !156
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc17
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !158
// CHECK:STDOUT:   ret void, !dbg !161
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %e) #0 !dbg !163 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %e), !dbg !169
// CHECK:STDOUT:   ret void, !dbg !170
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiscard.Main.84588f41d61dafba(i32 %_) #0 !dbg !172 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !175
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !177 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !179
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !179
// CHECK:STDOUT:   %.loc3_35.5.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !179
// CHECK:STDOUT:   %.loc4_11.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !180
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.30e.loc3_35.7, i64 8, i1 false), !dbg !179
// CHECK:STDOUT:   store { i32 } %.loc4_11.1.tuple.init, ptr %.loc3_35.5.Ok, align 4, !dbg !179
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Ok, i32 0, i32 0, !dbg !180
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !180
// CHECK:STDOUT:   ret void, !dbg !179
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !182 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !184
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !184
// CHECK:STDOUT:   %.loc3_35.5.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !184
// CHECK:STDOUT:   %.loc6_1.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !184
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.df1.loc3_35.7, i64 8, i1 false), !dbg !184
// CHECK:STDOUT:   store { i32 } %.loc6_1.1.tuple.init, ptr %.loc3_35.5.Err, align 4, !dbg !184
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Err, i32 0, i32 0, !dbg !184
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !184
// CHECK:STDOUT:   ret void, !dbg !184
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !187 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !189
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !189
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !189
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !190
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.f6c.anon, i64 8, i1 false), !dbg !189
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !189
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !190
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !190
// CHECK:STDOUT:   ret void, !dbg !189
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !192 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !194
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !194
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !194
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !194
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.493.anon, i64 8, i1 false), !dbg !194
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !194
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !194
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !194
// CHECK:STDOUT:   ret void, !dbg !194
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.9bba81283511934f(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !196 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !199
// CHECK:STDOUT:   ret void, !dbg !200
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "lib.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!8, !7, !8, !8}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = !{null, !6}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{null, !7}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{null, !8}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "LibCall32", linkageName: "_CLibCall32.Main", scope: null, file: !4, line: 51, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !31)
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !17, type: !7)
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 2, scope: !17, type: !8)
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 3, scope: !17, type: !8)
// CHECK:STDOUT: !29 = !DILocation(line: 52, column: 10, scope: !17)
// CHECK:STDOUT: !30 = !DILocation(line: 52, column: 3, scope: !17)
// CHECK:STDOUT: !31 = !{!18, !19, !20}
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !4, line: 42, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !35)
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !32, type: !6)
// CHECK:STDOUT: !34 = !DILocation(line: 42, column: 11, scope: !32)
// CHECK:STDOUT: !35 = !{!33}
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 42, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !39)
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !36, type: !7)
// CHECK:STDOUT: !38 = !DILocation(line: 42, column: 11, scope: !36)
// CHECK:STDOUT: !39 = !{!37}
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !43)
// CHECK:STDOUT: !41 = !DILocalVariable(arg: 1, scope: !40, type: !8)
// CHECK:STDOUT: !42 = !DILocation(line: 42, column: 11, scope: !40)
// CHECK:STDOUT: !43 = !{!41}
// CHECK:STDOUT: !44 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !47)
// CHECK:STDOUT: !45 = !DILocalVariable(arg: 1, scope: !44, type: !8)
// CHECK:STDOUT: !46 = !DILocation(line: 42, column: 11, scope: !44)
// CHECK:STDOUT: !47 = !{!45}
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !51)
// CHECK:STDOUT: !49 = !DILocalVariable(arg: 1, scope: !48, type: !8)
// CHECK:STDOUT: !50 = !DILocation(line: 42, column: 11, scope: !48)
// CHECK:STDOUT: !51 = !{!49}
// CHECK:STDOUT: !52 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b63d267505e804f2:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !55)
// CHECK:STDOUT: !53 = !DILocalVariable(arg: 1, scope: !52, type: !8)
// CHECK:STDOUT: !54 = !DILocation(line: 42, column: 11, scope: !52)
// CHECK:STDOUT: !55 = !{!53}
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.88b1683142354768:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !59)
// CHECK:STDOUT: !57 = !DILocalVariable(arg: 1, scope: !56, type: !8)
// CHECK:STDOUT: !58 = !DILocation(line: 42, column: 11, scope: !56)
// CHECK:STDOUT: !59 = !{!57}
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.88b1683142354768:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !63)
// CHECK:STDOUT: !61 = !DILocalVariable(arg: 1, scope: !60, type: !8)
// CHECK:STDOUT: !62 = !DILocation(line: 42, column: 11, scope: !60)
// CHECK:STDOUT: !63 = !{!61}
// CHECK:STDOUT: !64 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !67)
// CHECK:STDOUT: !65 = !DILocalVariable(arg: 1, scope: !64, type: !8)
// CHECK:STDOUT: !66 = !DILocation(line: 42, column: 11, scope: !64)
// CHECK:STDOUT: !67 = !{!65}
// CHECK:STDOUT: !68 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !71)
// CHECK:STDOUT: !69 = !DILocalVariable(arg: 1, scope: !68, type: !8)
// CHECK:STDOUT: !70 = !DILocation(line: 42, column: 11, scope: !68)
// CHECK:STDOUT: !71 = !{!69}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.bf4a066f5a5b60ea:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !75)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !8)
// CHECK:STDOUT: !74 = !DILocation(line: 42, column: 11, scope: !72)
// CHECK:STDOUT: !75 = !{!73}
// CHECK:STDOUT: !76 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.bf4a066f5a5b60ea:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !79)
// CHECK:STDOUT: !77 = !DILocalVariable(arg: 1, scope: !76, type: !8)
// CHECK:STDOUT: !78 = !DILocation(line: 42, column: 11, scope: !76)
// CHECK:STDOUT: !79 = !{!77}
// CHECK:STDOUT: !80 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.f269577697e84b3c:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !83)
// CHECK:STDOUT: !81 = !DILocalVariable(arg: 1, scope: !80, type: !8)
// CHECK:STDOUT: !82 = !DILocation(line: 42, column: 11, scope: !80)
// CHECK:STDOUT: !83 = !{!81}
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f269577697e84b3c:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !87)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !84, type: !8)
// CHECK:STDOUT: !86 = !DILocation(line: 42, column: 11, scope: !84)
// CHECK:STDOUT: !87 = !{!85}
// CHECK:STDOUT: !88 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.21e9b6df7c6352ff:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !91)
// CHECK:STDOUT: !89 = !DILocalVariable(arg: 1, scope: !88, type: !8)
// CHECK:STDOUT: !90 = !DILocation(line: 42, column: 11, scope: !88)
// CHECK:STDOUT: !91 = !{!89}
// CHECK:STDOUT: !92 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !95)
// CHECK:STDOUT: !93 = !DILocalVariable(arg: 1, scope: !92, type: !8)
// CHECK:STDOUT: !94 = !DILocation(line: 42, column: 11, scope: !92)
// CHECK:STDOUT: !95 = !{!93}
// CHECK:STDOUT: !96 = distinct !DISubprogram(name: "Chain", linkageName: "_CChain.Main.84588f41d61dafba", scope: null, file: !4, line: 41, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !122)
// CHECK:STDOUT: !97 = !DILocalVariable(arg: 1, scope: !96, type: !7)
// CHECK:STDOUT: !98 = !DILocalVariable(arg: 2, scope: !96, type: !8)
// CHECK:STDOUT: !99 = !DILocalVariable(arg: 3, scope: !96, type: !8)
// CHECK:STDOUT: !107 = !DILocation(line: 42, column: 11, scope: !96)
// CHECK:STDOUT: !108 = !{!8, !7, !8, !7}
// CHECK:STDOUT: !109 = !DISubroutineType(types: !108)
// CHECK:STDOUT: !110 = !{!8, !8}
// CHECK:STDOUT: !111 = !DISubroutineType(types: !110)
// CHECK:STDOUT: !112 = !{!8, !7}
// CHECK:STDOUT: !113 = !DISubroutineType(types: !112)
// CHECK:STDOUT: !114 = !DILocation(line: 42, column: 3, scope: !96)
// CHECK:STDOUT: !117 = !DILocation(line: 43, column: 11, scope: !96)
// CHECK:STDOUT: !118 = !DILocation(line: 43, column: 3, scope: !96)
// CHECK:STDOUT: !120 = !DILocation(line: 44, column: 10, scope: !96)
// CHECK:STDOUT: !121 = !DILocation(line: 44, column: 3, scope: !96)
// CHECK:STDOUT: !122 = !{!97, !98, !99}
// CHECK:STDOUT: !123 = distinct !DISubprogram(name: "Step", linkageName: "_CStep.Main.84588f41d61dafba", scope: null, file: !4, line: 29, type: !109, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !140)
// CHECK:STDOUT: !124 = !DILocalVariable(arg: 1, scope: !123, type: !7)
// CHECK:STDOUT: !125 = !DILocalVariable(arg: 2, scope: !123, type: !8)
// CHECK:STDOUT: !126 = !DILocalVariable(arg: 3, scope: !123, type: !7)
// CHECK:STDOUT: !133 = !DILocation(line: 30, column: 6, scope: !123)
// CHECK:STDOUT: !135 = !DILocation(line: 30, column: 22, scope: !123)
// CHECK:STDOUT: !136 = !DILocation(line: 30, column: 15, scope: !123)
// CHECK:STDOUT: !138 = !DILocation(line: 31, column: 10, scope: !123)
// CHECK:STDOUT: !139 = !DILocation(line: 31, column: 3, scope: !123)
// CHECK:STDOUT: !140 = !{!124, !125, !126}
// CHECK:STDOUT: !141 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !4, line: 15, type: !111, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !162)
// CHECK:STDOUT: !142 = !DILocalVariable(arg: 1, scope: !141, type: !8)
// CHECK:STDOUT: !147 = !DILocation(line: 17, column: 7, scope: !141)
// CHECK:STDOUT: !150 = !DILocation(line: 17, column: 34, scope: !141)
// CHECK:STDOUT: !151 = !DILocation(line: 17, column: 27, scope: !141)
// CHECK:STDOUT: !152 = !DILocation(line: 18, column: 7, scope: !141)
// CHECK:STDOUT: !155 = !DILocation(line: 18, column: 35, scope: !141)
// CHECK:STDOUT: !156 = !DILocation(line: 18, column: 28, scope: !141)
// CHECK:STDOUT: !158 = !DILocation(line: 22, column: 12, scope: !141)
// CHECK:STDOUT: !159 = !{!8}
// CHECK:STDOUT: !160 = !DISubroutineType(types: !159)
// CHECK:STDOUT: !161 = !DILocation(line: 22, column: 5, scope: !141)
// CHECK:STDOUT: !162 = !{!142}
// CHECK:STDOUT: !163 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !4, line: 24, type: !113, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !171)
// CHECK:STDOUT: !164 = !DILocalVariable(arg: 1, scope: !163, type: !7)
// CHECK:STDOUT: !169 = !DILocation(line: 24, column: 39, scope: !163)
// CHECK:STDOUT: !170 = !DILocation(line: 24, column: 32, scope: !163)
// CHECK:STDOUT: !171 = !{!164}
// CHECK:STDOUT: !172 = distinct !DISubprogram(name: "Discard", linkageName: "_CDiscard.Main.84588f41d61dafba", scope: null, file: !4, line: 36, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !176)
// CHECK:STDOUT: !173 = !DILocalVariable(arg: 1, scope: !172, type: !7)
// CHECK:STDOUT: !175 = !DILocation(line: 36, column: 1, scope: !172)
// CHECK:STDOUT: !176 = !{!173}
// CHECK:STDOUT: !177 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.MyResult.Main.8122a03446648385", scope: null, file: !4, line: 3, type: !113, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !181)
// CHECK:STDOUT: !178 = !DILocalVariable(arg: 1, scope: !177, type: !7)
// CHECK:STDOUT: !179 = !DILocation(line: 3, column: 1, scope: !177)
// CHECK:STDOUT: !180 = !DILocation(line: 4, column: 11, scope: !177)
// CHECK:STDOUT: !181 = !{!178}
// CHECK:STDOUT: !182 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.8122a03446648385", scope: null, file: !4, line: 3, type: !113, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !185)
// CHECK:STDOUT: !183 = !DILocalVariable(arg: 1, scope: !182, type: !7)
// CHECK:STDOUT: !184 = !DILocation(line: 3, column: 1, scope: !182)
// CHECK:STDOUT: !185 = !{!183}
// CHECK:STDOUT: !186 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !187 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.8122a03446648385", scope: null, file: !186, line: 21, type: !113, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !191)
// CHECK:STDOUT: !188 = !DILocalVariable(arg: 1, scope: !187, type: !7)
// CHECK:STDOUT: !189 = !DILocation(line: 21, column: 1, scope: !187)
// CHECK:STDOUT: !190 = !DILocation(line: 22, column: 21, scope: !187)
// CHECK:STDOUT: !191 = !{!188}
// CHECK:STDOUT: !192 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.8122a03446648385", scope: null, file: !186, line: 21, type: !113, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !195)
// CHECK:STDOUT: !193 = !DILocalVariable(arg: 1, scope: !192, type: !7)
// CHECK:STDOUT: !194 = !DILocation(line: 21, column: 1, scope: !192)
// CHECK:STDOUT: !195 = !{!193}
// CHECK:STDOUT: !196 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.9bba81283511934f", scope: null, file: !4, line: 11, type: !160, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !199 = !DILocation(line: 11, column: 45, scope: !196)
// CHECK:STDOUT: !200 = !DILocation(line: 11, column: 38, scope: !196)
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
// CHECK:STDOUT: define void @_CCall32.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %x, i1 %failA, i1 %failB) #0 !dbg !210 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CChain.Main.84588f41d61dafba(ptr %return, i32 %x, i1 %failA, i1 %failB), !dbg !222
// CHECK:STDOUT:   ret void, !dbg !223
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall64.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %x, i1 %failA, i1 %failB) #0 !dbg !225 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CChain.Main.f249b435619a5146(ptr %return, i64 %x, i1 %failA, i1 %failB), !dbg !237
// CHECK:STDOUT:   ret void, !dbg !238
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeErr64.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %tag) #0 !dbg !240 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.b7dd877894074427(ptr %return, i32 %tag), !dbg !246
// CHECK:STDOUT:   ret void, !dbg !247
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CReadErr64.Main(ptr %r) #0 !dbg !249 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc29_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %r, i32 0, i32 0, !dbg !255
// CHECK:STDOUT:   %.loc29_22.4 = load i8, ptr %.loc29_22.3.discriminant, align 1, !dbg !255
// CHECK:STDOUT:   %.loc29_22.41 = trunc i8 %.loc29_22.4 to i1, !dbg !255
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc29 = icmp eq i1 false, %.loc29_22.41, !dbg !255
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc29, label %match.case.then.loc29, label %match.case.else.loc29, !dbg !255
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc29:                            ; preds = %entry
// CHECK:STDOUT:   %.loc29_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %r, i32 0, i32 1, !dbg !255
// CHECK:STDOUT:   %.loc29_22.8.Ok = getelementptr inbounds nuw [8 x i8], ptr %.loc29_22.7.payload, i32 0, i32 0, !dbg !255
// CHECK:STDOUT:   %tuple.elem0.loc29.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc29_22.8.Ok, i32 0, i32 0, !dbg !255
// CHECK:STDOUT:   %.loc29_22.9 = load i64, ptr %tuple.elem0.loc29.tuple.elem, align 8, !dbg !255
// CHECK:STDOUT:   ret i32 0, !dbg !257
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc29:                            ; preds = %entry
// CHECK:STDOUT:   %.loc30_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %r, i32 0, i32 0, !dbg !258
// CHECK:STDOUT:   %.loc30_23.4 = load i8, ptr %.loc30_23.3.discriminant, align 1, !dbg !258
// CHECK:STDOUT:   %.loc30_23.42 = trunc i8 %.loc30_23.4 to i1, !dbg !258
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc30 = icmp eq i1 true, %.loc30_23.42, !dbg !258
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc30, label %match.case.then.loc30, label %match.done, !dbg !258
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc30:                            ; preds = %match.case.else.loc29
// CHECK:STDOUT:   %.loc30_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %r, i32 0, i32 1, !dbg !258
// CHECK:STDOUT:   %.loc30_23.8.Err = getelementptr inbounds nuw [8 x i8], ptr %.loc30_23.7.payload, i32 0, i32 0, !dbg !258
// CHECK:STDOUT:   %tuple.elem0.loc30.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc30_23.8.Err, i32 0, i32 0, !dbg !258
// CHECK:STDOUT:   %.loc30_23.9 = load i32, ptr %tuple.elem0.loc30.tuple.elem, align 4, !dbg !258
// CHECK:STDOUT:   ret i32 %.loc30_23.9, !dbg !261
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc29
// CHECK:STDOUT:   ret i32 -1, !dbg !263
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !265 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !267
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !269 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !271
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !273 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !275
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !275
// CHECK:STDOUT:   ret void, !dbg !275
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !277 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !279
// CHECK:STDOUT:   ret void, !dbg !279
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core"(ptr %self) #0 !dbg !281 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !283
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b63d267505e804f2:core.Destroy.Core"(ptr %self) #0 !dbg !285 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core"(ptr %self), !dbg !287
// CHECK:STDOUT:   ret void, !dbg !287
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.88b1683142354768:core.Destroy.Core"(ptr %self) #0 !dbg !289 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !291
// CHECK:STDOUT:   call void @"_CSelfDestruct.b63d267505e804f2:core.Destroy.Core"(ptr %.1.payload), !dbg !291
// CHECK:STDOUT:   %.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !291
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.2.discriminant), !dbg !291
// CHECK:STDOUT:   ret void, !dbg !291
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.88b1683142354768:core.Destroy.Core"(ptr %self) #0 !dbg !293 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.88b1683142354768:core.Destroy.Core"(ptr %self), !dbg !295
// CHECK:STDOUT:   ret void, !dbg !295
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core"(ptr %self) #0 !dbg !297 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !299
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %self) #0 !dbg !301 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core"(ptr %self), !dbg !303
// CHECK:STDOUT:   ret void, !dbg !303
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %self) #0 !dbg !305 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !307
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %self) #0 !dbg !309 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %self), !dbg !311
// CHECK:STDOUT:   ret void, !dbg !311
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.f269577697e84b3c:core.Destroy.Core"(ptr %self) #0 !dbg !313 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !315
// CHECK:STDOUT:   call void @"_CSelfDestruct.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %.1.payload), !dbg !315
// CHECK:STDOUT:   %.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !315
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.2.discriminant), !dbg !315
// CHECK:STDOUT:   ret void, !dbg !315
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f269577697e84b3c:core.Destroy.Core"(ptr %self) #0 !dbg !317 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.f269577697e84b3c:core.Destroy.Core"(ptr %self), !dbg !319
// CHECK:STDOUT:   ret void, !dbg !319
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.21e9b6df7c6352ff:core.Destroy.Core"(ptr %self) #0 !dbg !321 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !323
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %self) #0 !dbg !325 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.21e9b6df7c6352ff:core.Destroy.Core"(ptr %self), !dbg !327
// CHECK:STDOUT:   ret void, !dbg !327
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !329 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !331
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.f67381d184fb2c27:core.Destroy.Core"(ptr %self) #0 !dbg !333 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %self, i32 0, i32 0, !dbg !335
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !335
// CHECK:STDOUT:   ret void, !dbg !335
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f67381d184fb2c27:core.Destroy.Core"(ptr %self) #0 !dbg !337 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.f67381d184fb2c27:core.Destroy.Core"(ptr %self), !dbg !339
// CHECK:STDOUT:   ret void, !dbg !339
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.75fa817956543446:core.Destroy.Core"(ptr %self) #0 !dbg !341 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !343
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.75fa817956543446:core.Destroy.Core"(ptr %self) #0 !dbg !345 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.75fa817956543446:core.Destroy.Core"(ptr %self), !dbg !347
// CHECK:STDOUT:   ret void, !dbg !347
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.c1f61786be347789:core.Destroy.Core"(ptr %self) #0 !dbg !349 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.1.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !351
// CHECK:STDOUT:   call void @"_CSelfDestruct.75fa817956543446:core.Destroy.Core"(ptr %.1.payload), !dbg !351
// CHECK:STDOUT:   %.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !351
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.2.discriminant), !dbg !351
// CHECK:STDOUT:   ret void, !dbg !351
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.c1f61786be347789:core.Destroy.Core"(ptr %self) #0 !dbg !353 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.c1f61786be347789:core.Destroy.Core"(ptr %self), !dbg !355
// CHECK:STDOUT:   ret void, !dbg !355
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.3dff857b72298492:core.Destroy.Core"(ptr %self) #0 !dbg !357 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !359
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.3dff857b72298492:core.Destroy.Core"(ptr %self) #0 !dbg !361 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.3dff857b72298492:core.Destroy.Core"(ptr %self), !dbg !363
// CHECK:STDOUT:   ret void, !dbg !363
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.6d73c51926c0a20e:core.Destroy.Core"(ptr %self) #0 !dbg !365 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !367
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.6d73c51926c0a20e:core.Destroy.Core"(ptr %self) #0 !dbg !369 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.6d73c51926c0a20e:core.Destroy.Core"(ptr %self), !dbg !371
// CHECK:STDOUT:   ret void, !dbg !371
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.26b3932cce5effda:core.Destroy.Core"(ptr %self) #0 !dbg !373 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.1.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !375
// CHECK:STDOUT:   call void @"_CSelfDestruct.6d73c51926c0a20e:core.Destroy.Core"(ptr %.1.payload), !dbg !375
// CHECK:STDOUT:   %.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !375
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.2.discriminant), !dbg !375
// CHECK:STDOUT:   ret void, !dbg !375
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.26b3932cce5effda:core.Destroy.Core"(ptr %self) #0 !dbg !377 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.26b3932cce5effda:core.Destroy.Core"(ptr %self), !dbg !379
// CHECK:STDOUT:   ret void, !dbg !379
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.9644e7318f4a981d:core.Destroy.Core"(ptr %self) #0 !dbg !381 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !383
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.9644e7318f4a981d:core.Destroy.Core"(ptr %self) #0 !dbg !385 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.9644e7318f4a981d:core.Destroy.Core"(ptr %self), !dbg !387
// CHECK:STDOUT:   ret void, !dbg !387
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CChain.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %x, i1 %failA, i1 %failB) #0 !dbg !389 {
// CHECK:STDOUT:   %temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !400
// CHECK:STDOUT:   %temp1 = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !400
// CHECK:STDOUT:   %temp4 = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !404
// CHECK:STDOUT:   %temp5 = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !404
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !400
// CHECK:STDOUT:   call void @_CStep.Main.84588f41d61dafba(ptr %temp, i32 %x, i1 %failA, i32 101), !dbg !400
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !400
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %temp1, ptr %temp), !dbg !400
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %temp1, i32 0, i32 0, !dbg !400
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !400
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !400
// CHECK:STDOUT:   %3 = icmp eq i1 true, %2, !dbg !400
// CHECK:STDOUT:   br i1 %3, label %4, label %6, !dbg !400
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %temp1, i32 0, i32 1, !dbg !400
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !400
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !400
// CHECK:STDOUT:   %5 = load i32, ptr %tuple.elem, align 4, !dbg !400
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %5), !dbg !400
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %temp1), !dbg !400
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %temp), !dbg !400
// CHECK:STDOUT:   ret void, !dbg !400
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %0
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %temp1, i32 0, i32 1, !dbg !400
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload2, i32 0, i32 0, !dbg !400
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !400
// CHECK:STDOUT:   %7 = load i32, ptr %tuple.elem3, align 4, !dbg !400
// CHECK:STDOUT:   call void @_CDiscard.Main.84588f41d61dafba(i32 %7), !dbg !401
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %temp1), !dbg !400
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %temp), !dbg !400
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp4), !dbg !404
// CHECK:STDOUT:   call void @_CStep.Main.84588f41d61dafba(ptr %temp4, i32 %x, i1 %failB, i32 202), !dbg !404
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp5), !dbg !404
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %temp5, ptr %temp4), !dbg !404
// CHECK:STDOUT:   %discriminant6 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %temp5, i32 0, i32 0, !dbg !404
// CHECK:STDOUT:   %8 = load i8, ptr %discriminant6, align 1, !dbg !404
// CHECK:STDOUT:   %9 = trunc i8 %8 to i1, !dbg !404
// CHECK:STDOUT:   %10 = icmp eq i1 true, %9, !dbg !404
// CHECK:STDOUT:   br i1 %10, label %11, label %13, !dbg !404
// CHECK:STDOUT:
// CHECK:STDOUT: 11:                                               ; preds = %6
// CHECK:STDOUT:   %payload7 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %temp5, i32 0, i32 1, !dbg !404
// CHECK:STDOUT:   %Break8 = getelementptr inbounds nuw [4 x i8], ptr %payload7, i32 0, i32 0, !dbg !404
// CHECK:STDOUT:   %tuple.elem9 = getelementptr inbounds nuw { i32 }, ptr %Break8, i32 0, i32 0, !dbg !404
// CHECK:STDOUT:   %12 = load i32, ptr %tuple.elem9, align 4, !dbg !404
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %12), !dbg !404
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %temp5), !dbg !404
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %temp4), !dbg !404
// CHECK:STDOUT:   ret void, !dbg !404
// CHECK:STDOUT:
// CHECK:STDOUT: 13:                                               ; preds = %6
// CHECK:STDOUT:   %payload10 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %temp5, i32 0, i32 1, !dbg !404
// CHECK:STDOUT:   %Continue11 = getelementptr inbounds nuw [4 x i8], ptr %payload10, i32 0, i32 0, !dbg !404
// CHECK:STDOUT:   %tuple.elem12 = getelementptr inbounds nuw { i32 }, ptr %Continue11, i32 0, i32 0, !dbg !404
// CHECK:STDOUT:   %14 = load i32, ptr %tuple.elem12, align 4, !dbg !404
// CHECK:STDOUT:   call void @_CDiscard.Main.84588f41d61dafba(i32 %14), !dbg !405
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %temp5), !dbg !404
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %temp4), !dbg !404
// CHECK:STDOUT:   call void @_COk.MyResult.Main.8122a03446648385(ptr %return, i32 %x), !dbg !407
// CHECK:STDOUT:   ret void, !dbg !408
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CChain.Main.f249b435619a5146(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %x, i1 %failA, i1 %failB) #0 !dbg !410 {
// CHECK:STDOUT:   %temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !421
// CHECK:STDOUT:   %temp1 = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !421
// CHECK:STDOUT:   %temp4 = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !427
// CHECK:STDOUT:   %temp5 = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !427
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !421
// CHECK:STDOUT:   call void @_CStep.Main.f249b435619a5146(ptr %temp, i64 %x, i1 %failA, i32 101), !dbg !421
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !421
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %temp1, ptr %temp), !dbg !421
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %temp1, i32 0, i32 0, !dbg !421
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !421
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !421
// CHECK:STDOUT:   %3 = icmp eq i1 true, %2, !dbg !421
// CHECK:STDOUT:   br i1 %3, label %4, label %6, !dbg !421
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %temp1, i32 0, i32 1, !dbg !421
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !421
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !421
// CHECK:STDOUT:   %5 = load i32, ptr %tuple.elem, align 4, !dbg !421
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %return, i32 %5), !dbg !421
// CHECK:STDOUT:   call void @"_CSelfDestruct.3dff857b72298492:core.Destroy.Core"(ptr %temp1), !dbg !421
// CHECK:STDOUT:   call void @"_CSelfDestruct.9644e7318f4a981d:core.Destroy.Core"(ptr %temp), !dbg !421
// CHECK:STDOUT:   ret void, !dbg !421
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %0
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %temp1, i32 0, i32 1, !dbg !421
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [8 x i8], ptr %payload2, i32 0, i32 0, !dbg !421
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { i64 }, ptr %Continue, i32 0, i32 0, !dbg !421
// CHECK:STDOUT:   %7 = load i64, ptr %tuple.elem3, align 8, !dbg !421
// CHECK:STDOUT:   call void @_CDiscard.Main.f249b435619a5146(i64 %7), !dbg !424
// CHECK:STDOUT:   call void @"_CSelfDestruct.3dff857b72298492:core.Destroy.Core"(ptr %temp1), !dbg !421
// CHECK:STDOUT:   call void @"_CSelfDestruct.9644e7318f4a981d:core.Destroy.Core"(ptr %temp), !dbg !421
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp4), !dbg !427
// CHECK:STDOUT:   call void @_CStep.Main.f249b435619a5146(ptr %temp4, i64 %x, i1 %failB, i32 202), !dbg !427
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp5), !dbg !427
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %temp5, ptr %temp4), !dbg !427
// CHECK:STDOUT:   %discriminant6 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %temp5, i32 0, i32 0, !dbg !427
// CHECK:STDOUT:   %8 = load i8, ptr %discriminant6, align 1, !dbg !427
// CHECK:STDOUT:   %9 = trunc i8 %8 to i1, !dbg !427
// CHECK:STDOUT:   %10 = icmp eq i1 true, %9, !dbg !427
// CHECK:STDOUT:   br i1 %10, label %11, label %13, !dbg !427
// CHECK:STDOUT:
// CHECK:STDOUT: 11:                                               ; preds = %6
// CHECK:STDOUT:   %payload7 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %temp5, i32 0, i32 1, !dbg !427
// CHECK:STDOUT:   %Break8 = getelementptr inbounds nuw [8 x i8], ptr %payload7, i32 0, i32 0, !dbg !427
// CHECK:STDOUT:   %tuple.elem9 = getelementptr inbounds nuw { i32 }, ptr %Break8, i32 0, i32 0, !dbg !427
// CHECK:STDOUT:   %12 = load i32, ptr %tuple.elem9, align 4, !dbg !427
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %return, i32 %12), !dbg !427
// CHECK:STDOUT:   call void @"_CSelfDestruct.3dff857b72298492:core.Destroy.Core"(ptr %temp5), !dbg !427
// CHECK:STDOUT:   call void @"_CSelfDestruct.9644e7318f4a981d:core.Destroy.Core"(ptr %temp4), !dbg !427
// CHECK:STDOUT:   ret void, !dbg !427
// CHECK:STDOUT:
// CHECK:STDOUT: 13:                                               ; preds = %6
// CHECK:STDOUT:   %payload10 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %temp5, i32 0, i32 1, !dbg !427
// CHECK:STDOUT:   %Continue11 = getelementptr inbounds nuw [8 x i8], ptr %payload10, i32 0, i32 0, !dbg !427
// CHECK:STDOUT:   %tuple.elem12 = getelementptr inbounds nuw { i64 }, ptr %Continue11, i32 0, i32 0, !dbg !427
// CHECK:STDOUT:   %14 = load i64, ptr %tuple.elem12, align 8, !dbg !427
// CHECK:STDOUT:   call void @_CDiscard.Main.f249b435619a5146(i64 %14), !dbg !428
// CHECK:STDOUT:   call void @"_CSelfDestruct.3dff857b72298492:core.Destroy.Core"(ptr %temp5), !dbg !427
// CHECK:STDOUT:   call void @"_CSelfDestruct.9644e7318f4a981d:core.Destroy.Core"(ptr %temp4), !dbg !427
// CHECK:STDOUT:   call void @_COk.MyResult.Main.b7dd877894074427(ptr %return, i64 %x), !dbg !430
// CHECK:STDOUT:   ret void, !dbg !433
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !435 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !437
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !437
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !437
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !437
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @MyResult.val.142.anon, i64 16, i1 false), !dbg !437
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Err, align 4, !dbg !437
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !437
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !437
// CHECK:STDOUT:   ret void, !dbg !437
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CLibCall32.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>), i32, i1, i1)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CStep.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %x, i1 %fail, i32 %tag) #0 !dbg !439 {
// CHECK:STDOUT:   br i1 %fail, label %1, label %2, !dbg !449
// CHECK:STDOUT:
// CHECK:STDOUT: 1:                                                ; preds = %0
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %tag), !dbg !451
// CHECK:STDOUT:   ret void, !dbg !452
// CHECK:STDOUT:
// CHECK:STDOUT: 2:                                                ; preds = %0
// CHECK:STDOUT:   call void @_COk.MyResult.Main.8122a03446648385(ptr %return, i32 %x), !dbg !454
// CHECK:STDOUT:   ret void, !dbg !455
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !457 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !463
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !463
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !463
// CHECK:STDOUT:   %3 = icmp eq i1 false, %2, !dbg !463
// CHECK:STDOUT:   br i1 %3, label %4, label %6, !dbg !463
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !463
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !463
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Ok, i32 0, i32 0, !dbg !463
// CHECK:STDOUT:   %5 = load i32, ptr %tuple.elem, align 4, !dbg !463
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.8122a03446648385(ptr %return, i32 %5), !dbg !466
// CHECK:STDOUT:   ret void, !dbg !467
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %0
// CHECK:STDOUT:   %discriminant1 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !468
// CHECK:STDOUT:   %7 = load i8, ptr %discriminant1, align 1, !dbg !468
// CHECK:STDOUT:   %8 = trunc i8 %7 to i1, !dbg !468
// CHECK:STDOUT:   %9 = icmp eq i1 true, %8, !dbg !468
// CHECK:STDOUT:   br i1 %9, label %10, label %12, !dbg !468
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %6
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !468
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload2, i32 0, i32 0, !dbg !468
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !468
// CHECK:STDOUT:   %11 = load i32, ptr %tuple.elem3, align 4, !dbg !468
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.8122a03446648385(ptr %return, i32 %11), !dbg !471
// CHECK:STDOUT:   ret void, !dbg !472
// CHECK:STDOUT:
// CHECK:STDOUT: 12:                                               ; preds = %6
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !474
// CHECK:STDOUT:   ret void, !dbg !475
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %e) #0 !dbg !477 {
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %e), !dbg !483
// CHECK:STDOUT:   ret void, !dbg !484
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiscard.Main.84588f41d61dafba(i32 %_) #0 !dbg !486 {
// CHECK:STDOUT:   ret void, !dbg !489
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !491 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !493
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !493
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !493
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !494
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.30e.anon, i64 8, i1 false), !dbg !493
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Ok, align 4, !dbg !493
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Ok, i32 0, i32 0, !dbg !494
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !494
// CHECK:STDOUT:   ret void, !dbg !493
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CStep.Main.f249b435619a5146(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %x, i1 %fail, i32 %tag) #0 !dbg !496 {
// CHECK:STDOUT:   br i1 %fail, label %1, label %2, !dbg !506
// CHECK:STDOUT:
// CHECK:STDOUT: 1:                                                ; preds = %0
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.b7dd877894074427(ptr %return, i32 %tag), !dbg !508
// CHECK:STDOUT:   ret void, !dbg !509
// CHECK:STDOUT:
// CHECK:STDOUT: 2:                                                ; preds = %0
// CHECK:STDOUT:   call void @_COk.MyResult.Main.b7dd877894074427(ptr %return, i64 %x), !dbg !511
// CHECK:STDOUT:   ret void, !dbg !512
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %self) #0 !dbg !514 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !520
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !520
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !520
// CHECK:STDOUT:   %3 = icmp eq i1 false, %2, !dbg !520
// CHECK:STDOUT:   br i1 %3, label %4, label %6, !dbg !520
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !520
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !520
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i64 }, ptr %Ok, i32 0, i32 0, !dbg !520
// CHECK:STDOUT:   %5 = load i64, ptr %tuple.elem, align 8, !dbg !520
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.b7dd877894074427(ptr %return, i64 %5), !dbg !523
// CHECK:STDOUT:   ret void, !dbg !524
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %0
// CHECK:STDOUT:   %discriminant1 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !525
// CHECK:STDOUT:   %7 = load i8, ptr %discriminant1, align 1, !dbg !525
// CHECK:STDOUT:   %8 = trunc i8 %7 to i1, !dbg !525
// CHECK:STDOUT:   %9 = icmp eq i1 true, %8, !dbg !525
// CHECK:STDOUT:   br i1 %9, label %10, label %12, !dbg !525
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %6
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !525
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [8 x i8], ptr %payload2, i32 0, i32 0, !dbg !525
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !525
// CHECK:STDOUT:   %11 = load i32, ptr %tuple.elem3, align 4, !dbg !525
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.b7dd877894074427(ptr %return, i32 %11), !dbg !528
// CHECK:STDOUT:   ret void, !dbg !529
// CHECK:STDOUT:
// CHECK:STDOUT: 12:                                               ; preds = %6
// CHECK:STDOUT:   call void @_CDiverge.Main.fc3567e4618671b9(ptr %return), !dbg !531
// CHECK:STDOUT:   ret void, !dbg !532
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %e) #0 !dbg !534 {
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.b7dd877894074427(ptr %return, i32 %e), !dbg !540
// CHECK:STDOUT:   ret void, !dbg !541
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiscard.Main.f249b435619a5146(i64 %_) #0 !dbg !543 {
// CHECK:STDOUT:   ret void, !dbg !546
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.MyResult.Main.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %_) #0 !dbg !548 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !550
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !550
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !550
// CHECK:STDOUT:   %tuple.init = insertvalue { i64 } poison, i64 %_, 0, !dbg !551
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @MyResult.val.9f4.anon, i64 16, i1 false), !dbg !550
// CHECK:STDOUT:   store { i64 } %tuple.init, ptr %Ok, align 8, !dbg !550
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i64 }, ptr %Ok, i32 0, i32 0, !dbg !551
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem, align 8, !dbg !551
// CHECK:STDOUT:   ret void, !dbg !550
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !553 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !555
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !555
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !555
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !555
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.df1.anon, i64 8, i1 false), !dbg !555
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Err, align 4, !dbg !555
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !555
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !555
// CHECK:STDOUT:   ret void, !dbg !555
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !557 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !559
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !559
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !559
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !560
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.f6c.anon, i64 8, i1 false), !dbg !559
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !559
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !560
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !560
// CHECK:STDOUT:   ret void, !dbg !559
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !562 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !564
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !564
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !564
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !564
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.493.anon, i64 8, i1 false), !dbg !564
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !564
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !564
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !564
// CHECK:STDOUT:   ret void, !dbg !564
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.9bba81283511934f(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !566 {
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !569
// CHECK:STDOUT:   ret void, !dbg !570
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %_) #0 !dbg !571 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !573
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !573
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !573
// CHECK:STDOUT:   %tuple.init = insertvalue { i64 } poison, i64 %_, 0, !dbg !574
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.fa9.anon, i64 16, i1 false), !dbg !573
// CHECK:STDOUT:   store { i64 } %tuple.init, ptr %Continue, align 8, !dbg !573
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i64 }, ptr %Continue, i32 0, i32 0, !dbg !574
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem, align 8, !dbg !574
// CHECK:STDOUT:   ret void, !dbg !573
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !576 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !578
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !578
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !578
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !578
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.d01.anon, i64 16, i1 false), !dbg !578
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !578
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !578
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !578
// CHECK:STDOUT:   ret void, !dbg !578
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.fc3567e4618671b9(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return) #0 !dbg !580 {
// CHECK:STDOUT:   call void @_CDiverge.Main.fc3567e4618671b9(ptr %return), !dbg !583
// CHECK:STDOUT:   ret void, !dbg !584
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!202}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "lib.carbon", directory: "")
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!8, !7, !8, !8}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = !{null, !6}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{null, !7}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{null, !8}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !108 = !{!8, !7, !8, !7}
// CHECK:STDOUT: !109 = !DISubroutineType(types: !108)
// CHECK:STDOUT: !110 = !{!8, !8}
// CHECK:STDOUT: !111 = !DISubroutineType(types: !110)
// CHECK:STDOUT: !112 = !{!8, !7}
// CHECK:STDOUT: !113 = !DISubroutineType(types: !112)
// CHECK:STDOUT: !159 = !{!8}
// CHECK:STDOUT: !160 = !DISubroutineType(types: !159)
// CHECK:STDOUT: !186 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !201 = !DIFile(filename: "use.carbon", directory: "")
// CHECK:STDOUT: !202 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !201, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !203 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !204 = !{!8, !203, !8, !8}
// CHECK:STDOUT: !205 = !DISubroutineType(types: !204)
// CHECK:STDOUT: !206 = !{!7, !8}
// CHECK:STDOUT: !207 = !DISubroutineType(types: !206)
// CHECK:STDOUT: !208 = !{null, !203}
// CHECK:STDOUT: !209 = !DISubroutineType(types: !208)
// CHECK:STDOUT: !210 = distinct !DISubprogram(name: "Call32", linkageName: "_CCall32.Main", scope: null, file: !201, line: 6, type: !10, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !224)
// CHECK:STDOUT: !211 = !DILocalVariable(arg: 1, scope: !210, type: !7)
// CHECK:STDOUT: !212 = !DILocalVariable(arg: 2, scope: !210, type: !8)
// CHECK:STDOUT: !213 = !DILocalVariable(arg: 3, scope: !210, type: !8)
// CHECK:STDOUT: !222 = !DILocation(line: 7, column: 10, scope: !210)
// CHECK:STDOUT: !223 = !DILocation(line: 7, column: 3, scope: !210)
// CHECK:STDOUT: !224 = !{!211, !212, !213}
// CHECK:STDOUT: !225 = distinct !DISubprogram(name: "Call64", linkageName: "_CCall64.Main", scope: null, file: !201, line: 10, type: !205, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !239)
// CHECK:STDOUT: !226 = !DILocalVariable(arg: 1, scope: !225, type: !203)
// CHECK:STDOUT: !227 = !DILocalVariable(arg: 2, scope: !225, type: !8)
// CHECK:STDOUT: !228 = !DILocalVariable(arg: 3, scope: !225, type: !8)
// CHECK:STDOUT: !237 = !DILocation(line: 11, column: 10, scope: !225)
// CHECK:STDOUT: !238 = !DILocation(line: 11, column: 3, scope: !225)
// CHECK:STDOUT: !239 = !{!226, !227, !228}
// CHECK:STDOUT: !240 = distinct !DISubprogram(name: "MakeErr64", linkageName: "_CMakeErr64.Main", scope: null, file: !201, line: 17, type: !113, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !248)
// CHECK:STDOUT: !241 = !DILocalVariable(arg: 1, scope: !240, type: !7)
// CHECK:STDOUT: !246 = !DILocation(line: 18, column: 10, scope: !240)
// CHECK:STDOUT: !247 = !DILocation(line: 18, column: 3, scope: !240)
// CHECK:STDOUT: !248 = !{!241}
// CHECK:STDOUT: !249 = distinct !DISubprogram(name: "ReadErr64", linkageName: "_CReadErr64.Main", scope: null, file: !201, line: 23, type: !207, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !264)
// CHECK:STDOUT: !250 = !DILocalVariable(arg: 1, scope: !249, type: !8)
// CHECK:STDOUT: !255 = !DILocation(line: 29, column: 5, scope: !249)
// CHECK:STDOUT: !257 = !DILocation(line: 29, column: 27, scope: !249)
// CHECK:STDOUT: !258 = !DILocation(line: 30, column: 5, scope: !249)
// CHECK:STDOUT: !261 = !DILocation(line: 30, column: 28, scope: !249)
// CHECK:STDOUT: !263 = !DILocation(line: 33, column: 3, scope: !249)
// CHECK:STDOUT: !264 = !{!250}
// CHECK:STDOUT: !265 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !4, line: 42, type: !12, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !268)
// CHECK:STDOUT: !266 = !DILocalVariable(arg: 1, scope: !265, type: !6)
// CHECK:STDOUT: !267 = !DILocation(line: 42, column: 11, scope: !265)
// CHECK:STDOUT: !268 = !{!266}
// CHECK:STDOUT: !269 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 42, type: !14, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !272)
// CHECK:STDOUT: !270 = !DILocalVariable(arg: 1, scope: !269, type: !7)
// CHECK:STDOUT: !271 = !DILocation(line: 42, column: 11, scope: !269)
// CHECK:STDOUT: !272 = !{!270}
// CHECK:STDOUT: !273 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !276)
// CHECK:STDOUT: !274 = !DILocalVariable(arg: 1, scope: !273, type: !8)
// CHECK:STDOUT: !275 = !DILocation(line: 42, column: 11, scope: !273)
// CHECK:STDOUT: !276 = !{!274}
// CHECK:STDOUT: !277 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !280)
// CHECK:STDOUT: !278 = !DILocalVariable(arg: 1, scope: !277, type: !8)
// CHECK:STDOUT: !279 = !DILocation(line: 42, column: 11, scope: !277)
// CHECK:STDOUT: !280 = !{!278}
// CHECK:STDOUT: !281 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !284)
// CHECK:STDOUT: !282 = !DILocalVariable(arg: 1, scope: !281, type: !8)
// CHECK:STDOUT: !283 = !DILocation(line: 42, column: 11, scope: !281)
// CHECK:STDOUT: !284 = !{!282}
// CHECK:STDOUT: !285 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b63d267505e804f2:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !288)
// CHECK:STDOUT: !286 = !DILocalVariable(arg: 1, scope: !285, type: !8)
// CHECK:STDOUT: !287 = !DILocation(line: 42, column: 11, scope: !285)
// CHECK:STDOUT: !288 = !{!286}
// CHECK:STDOUT: !289 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.88b1683142354768:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !292)
// CHECK:STDOUT: !290 = !DILocalVariable(arg: 1, scope: !289, type: !8)
// CHECK:STDOUT: !291 = !DILocation(line: 42, column: 11, scope: !289)
// CHECK:STDOUT: !292 = !{!290}
// CHECK:STDOUT: !293 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.88b1683142354768:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !296)
// CHECK:STDOUT: !294 = !DILocalVariable(arg: 1, scope: !293, type: !8)
// CHECK:STDOUT: !295 = !DILocation(line: 42, column: 11, scope: !293)
// CHECK:STDOUT: !296 = !{!294}
// CHECK:STDOUT: !297 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !300)
// CHECK:STDOUT: !298 = !DILocalVariable(arg: 1, scope: !297, type: !8)
// CHECK:STDOUT: !299 = !DILocation(line: 42, column: 11, scope: !297)
// CHECK:STDOUT: !300 = !{!298}
// CHECK:STDOUT: !301 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !304)
// CHECK:STDOUT: !302 = !DILocalVariable(arg: 1, scope: !301, type: !8)
// CHECK:STDOUT: !303 = !DILocation(line: 42, column: 11, scope: !301)
// CHECK:STDOUT: !304 = !{!302}
// CHECK:STDOUT: !305 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.bf4a066f5a5b60ea:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !308)
// CHECK:STDOUT: !306 = !DILocalVariable(arg: 1, scope: !305, type: !8)
// CHECK:STDOUT: !307 = !DILocation(line: 42, column: 11, scope: !305)
// CHECK:STDOUT: !308 = !{!306}
// CHECK:STDOUT: !309 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.bf4a066f5a5b60ea:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !312)
// CHECK:STDOUT: !310 = !DILocalVariable(arg: 1, scope: !309, type: !8)
// CHECK:STDOUT: !311 = !DILocation(line: 42, column: 11, scope: !309)
// CHECK:STDOUT: !312 = !{!310}
// CHECK:STDOUT: !313 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.f269577697e84b3c:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !316)
// CHECK:STDOUT: !314 = !DILocalVariable(arg: 1, scope: !313, type: !8)
// CHECK:STDOUT: !315 = !DILocation(line: 42, column: 11, scope: !313)
// CHECK:STDOUT: !316 = !{!314}
// CHECK:STDOUT: !317 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f269577697e84b3c:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !320)
// CHECK:STDOUT: !318 = !DILocalVariable(arg: 1, scope: !317, type: !8)
// CHECK:STDOUT: !319 = !DILocation(line: 42, column: 11, scope: !317)
// CHECK:STDOUT: !320 = !{!318}
// CHECK:STDOUT: !321 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.21e9b6df7c6352ff:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !324)
// CHECK:STDOUT: !322 = !DILocalVariable(arg: 1, scope: !321, type: !8)
// CHECK:STDOUT: !323 = !DILocation(line: 42, column: 11, scope: !321)
// CHECK:STDOUT: !324 = !{!322}
// CHECK:STDOUT: !325 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !328)
// CHECK:STDOUT: !326 = !DILocalVariable(arg: 1, scope: !325, type: !8)
// CHECK:STDOUT: !327 = !DILocation(line: 42, column: 11, scope: !325)
// CHECK:STDOUT: !328 = !{!326}
// CHECK:STDOUT: !329 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !4, line: 42, type: !209, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !332)
// CHECK:STDOUT: !330 = !DILocalVariable(arg: 1, scope: !329, type: !203)
// CHECK:STDOUT: !331 = !DILocation(line: 42, column: 11, scope: !329)
// CHECK:STDOUT: !332 = !{!330}
// CHECK:STDOUT: !333 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.f67381d184fb2c27:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !336)
// CHECK:STDOUT: !334 = !DILocalVariable(arg: 1, scope: !333, type: !8)
// CHECK:STDOUT: !335 = !DILocation(line: 42, column: 11, scope: !333)
// CHECK:STDOUT: !336 = !{!334}
// CHECK:STDOUT: !337 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f67381d184fb2c27:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !340)
// CHECK:STDOUT: !338 = !DILocalVariable(arg: 1, scope: !337, type: !8)
// CHECK:STDOUT: !339 = !DILocation(line: 42, column: 11, scope: !337)
// CHECK:STDOUT: !340 = !{!338}
// CHECK:STDOUT: !341 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.75fa817956543446:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !344)
// CHECK:STDOUT: !342 = !DILocalVariable(arg: 1, scope: !341, type: !8)
// CHECK:STDOUT: !343 = !DILocation(line: 42, column: 11, scope: !341)
// CHECK:STDOUT: !344 = !{!342}
// CHECK:STDOUT: !345 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.75fa817956543446:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !348)
// CHECK:STDOUT: !346 = !DILocalVariable(arg: 1, scope: !345, type: !8)
// CHECK:STDOUT: !347 = !DILocation(line: 42, column: 11, scope: !345)
// CHECK:STDOUT: !348 = !{!346}
// CHECK:STDOUT: !349 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.c1f61786be347789:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !352)
// CHECK:STDOUT: !350 = !DILocalVariable(arg: 1, scope: !349, type: !8)
// CHECK:STDOUT: !351 = !DILocation(line: 42, column: 11, scope: !349)
// CHECK:STDOUT: !352 = !{!350}
// CHECK:STDOUT: !353 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.c1f61786be347789:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !356)
// CHECK:STDOUT: !354 = !DILocalVariable(arg: 1, scope: !353, type: !8)
// CHECK:STDOUT: !355 = !DILocation(line: 42, column: 11, scope: !353)
// CHECK:STDOUT: !356 = !{!354}
// CHECK:STDOUT: !357 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.3dff857b72298492:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !360)
// CHECK:STDOUT: !358 = !DILocalVariable(arg: 1, scope: !357, type: !8)
// CHECK:STDOUT: !359 = !DILocation(line: 42, column: 11, scope: !357)
// CHECK:STDOUT: !360 = !{!358}
// CHECK:STDOUT: !361 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.3dff857b72298492:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !364)
// CHECK:STDOUT: !362 = !DILocalVariable(arg: 1, scope: !361, type: !8)
// CHECK:STDOUT: !363 = !DILocation(line: 42, column: 11, scope: !361)
// CHECK:STDOUT: !364 = !{!362}
// CHECK:STDOUT: !365 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.6d73c51926c0a20e:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !368)
// CHECK:STDOUT: !366 = !DILocalVariable(arg: 1, scope: !365, type: !8)
// CHECK:STDOUT: !367 = !DILocation(line: 42, column: 11, scope: !365)
// CHECK:STDOUT: !368 = !{!366}
// CHECK:STDOUT: !369 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.6d73c51926c0a20e:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !372)
// CHECK:STDOUT: !370 = !DILocalVariable(arg: 1, scope: !369, type: !8)
// CHECK:STDOUT: !371 = !DILocation(line: 42, column: 11, scope: !369)
// CHECK:STDOUT: !372 = !{!370}
// CHECK:STDOUT: !373 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.26b3932cce5effda:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !376)
// CHECK:STDOUT: !374 = !DILocalVariable(arg: 1, scope: !373, type: !8)
// CHECK:STDOUT: !375 = !DILocation(line: 42, column: 11, scope: !373)
// CHECK:STDOUT: !376 = !{!374}
// CHECK:STDOUT: !377 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.26b3932cce5effda:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !380)
// CHECK:STDOUT: !378 = !DILocalVariable(arg: 1, scope: !377, type: !8)
// CHECK:STDOUT: !379 = !DILocation(line: 42, column: 11, scope: !377)
// CHECK:STDOUT: !380 = !{!378}
// CHECK:STDOUT: !381 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.9644e7318f4a981d:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !384)
// CHECK:STDOUT: !382 = !DILocalVariable(arg: 1, scope: !381, type: !8)
// CHECK:STDOUT: !383 = !DILocation(line: 42, column: 11, scope: !381)
// CHECK:STDOUT: !384 = !{!382}
// CHECK:STDOUT: !385 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.9644e7318f4a981d:core.Destroy.Core", scope: null, file: !4, line: 42, type: !16, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !388)
// CHECK:STDOUT: !386 = !DILocalVariable(arg: 1, scope: !385, type: !8)
// CHECK:STDOUT: !387 = !DILocation(line: 42, column: 11, scope: !385)
// CHECK:STDOUT: !388 = !{!386}
// CHECK:STDOUT: !389 = distinct !DISubprogram(name: "Chain", linkageName: "_CChain.Main.84588f41d61dafba", scope: null, file: !4, line: 41, type: !10, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !409)
// CHECK:STDOUT: !390 = !DILocalVariable(arg: 1, scope: !389, type: !7)
// CHECK:STDOUT: !391 = !DILocalVariable(arg: 2, scope: !389, type: !8)
// CHECK:STDOUT: !392 = !DILocalVariable(arg: 3, scope: !389, type: !8)
// CHECK:STDOUT: !400 = !DILocation(line: 42, column: 11, scope: !389)
// CHECK:STDOUT: !401 = !DILocation(line: 42, column: 3, scope: !389)
// CHECK:STDOUT: !404 = !DILocation(line: 43, column: 11, scope: !389)
// CHECK:STDOUT: !405 = !DILocation(line: 43, column: 3, scope: !389)
// CHECK:STDOUT: !407 = !DILocation(line: 44, column: 10, scope: !389)
// CHECK:STDOUT: !408 = !DILocation(line: 44, column: 3, scope: !389)
// CHECK:STDOUT: !409 = !{!390, !391, !392}
// CHECK:STDOUT: !410 = distinct !DISubprogram(name: "Chain", linkageName: "_CChain.Main.f249b435619a5146", scope: null, file: !4, line: 41, type: !205, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !434)
// CHECK:STDOUT: !411 = !DILocalVariable(arg: 1, scope: !410, type: !203)
// CHECK:STDOUT: !412 = !DILocalVariable(arg: 2, scope: !410, type: !8)
// CHECK:STDOUT: !413 = !DILocalVariable(arg: 3, scope: !410, type: !8)
// CHECK:STDOUT: !421 = !DILocation(line: 42, column: 11, scope: !410)
// CHECK:STDOUT: !422 = !{!8, !203, !8, !7}
// CHECK:STDOUT: !423 = !DISubroutineType(types: !422)
// CHECK:STDOUT: !424 = !DILocation(line: 42, column: 3, scope: !410)
// CHECK:STDOUT: !427 = !DILocation(line: 43, column: 11, scope: !410)
// CHECK:STDOUT: !428 = !DILocation(line: 43, column: 3, scope: !410)
// CHECK:STDOUT: !430 = !DILocation(line: 44, column: 10, scope: !410)
// CHECK:STDOUT: !431 = !{!8, !203}
// CHECK:STDOUT: !432 = !DISubroutineType(types: !431)
// CHECK:STDOUT: !433 = !DILocation(line: 44, column: 3, scope: !410)
// CHECK:STDOUT: !434 = !{!411, !412, !413}
// CHECK:STDOUT: !435 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.b7dd877894074427", scope: null, file: !4, line: 3, type: !113, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !438)
// CHECK:STDOUT: !436 = !DILocalVariable(arg: 1, scope: !435, type: !7)
// CHECK:STDOUT: !437 = !DILocation(line: 3, column: 1, scope: !435)
// CHECK:STDOUT: !438 = !{!436}
// CHECK:STDOUT: !439 = distinct !DISubprogram(name: "Step", linkageName: "_CStep.Main.84588f41d61dafba", scope: null, file: !4, line: 29, type: !109, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !456)
// CHECK:STDOUT: !440 = !DILocalVariable(arg: 1, scope: !439, type: !7)
// CHECK:STDOUT: !441 = !DILocalVariable(arg: 2, scope: !439, type: !8)
// CHECK:STDOUT: !442 = !DILocalVariable(arg: 3, scope: !439, type: !7)
// CHECK:STDOUT: !449 = !DILocation(line: 30, column: 6, scope: !439)
// CHECK:STDOUT: !451 = !DILocation(line: 30, column: 22, scope: !439)
// CHECK:STDOUT: !452 = !DILocation(line: 30, column: 15, scope: !439)
// CHECK:STDOUT: !454 = !DILocation(line: 31, column: 10, scope: !439)
// CHECK:STDOUT: !455 = !DILocation(line: 31, column: 3, scope: !439)
// CHECK:STDOUT: !456 = !{!440, !441, !442}
// CHECK:STDOUT: !457 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !4, line: 15, type: !111, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !476)
// CHECK:STDOUT: !458 = !DILocalVariable(arg: 1, scope: !457, type: !8)
// CHECK:STDOUT: !463 = !DILocation(line: 17, column: 7, scope: !457)
// CHECK:STDOUT: !466 = !DILocation(line: 17, column: 34, scope: !457)
// CHECK:STDOUT: !467 = !DILocation(line: 17, column: 27, scope: !457)
// CHECK:STDOUT: !468 = !DILocation(line: 18, column: 7, scope: !457)
// CHECK:STDOUT: !471 = !DILocation(line: 18, column: 35, scope: !457)
// CHECK:STDOUT: !472 = !DILocation(line: 18, column: 28, scope: !457)
// CHECK:STDOUT: !474 = !DILocation(line: 22, column: 12, scope: !457)
// CHECK:STDOUT: !475 = !DILocation(line: 22, column: 5, scope: !457)
// CHECK:STDOUT: !476 = !{!458}
// CHECK:STDOUT: !477 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !4, line: 24, type: !113, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !485)
// CHECK:STDOUT: !478 = !DILocalVariable(arg: 1, scope: !477, type: !7)
// CHECK:STDOUT: !483 = !DILocation(line: 24, column: 39, scope: !477)
// CHECK:STDOUT: !484 = !DILocation(line: 24, column: 32, scope: !477)
// CHECK:STDOUT: !485 = !{!478}
// CHECK:STDOUT: !486 = distinct !DISubprogram(name: "Discard", linkageName: "_CDiscard.Main.84588f41d61dafba", scope: null, file: !4, line: 36, type: !14, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !490)
// CHECK:STDOUT: !487 = !DILocalVariable(arg: 1, scope: !486, type: !7)
// CHECK:STDOUT: !489 = !DILocation(line: 36, column: 1, scope: !486)
// CHECK:STDOUT: !490 = !{!487}
// CHECK:STDOUT: !491 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.MyResult.Main.8122a03446648385", scope: null, file: !4, line: 3, type: !113, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !495)
// CHECK:STDOUT: !492 = !DILocalVariable(arg: 1, scope: !491, type: !7)
// CHECK:STDOUT: !493 = !DILocation(line: 3, column: 1, scope: !491)
// CHECK:STDOUT: !494 = !DILocation(line: 4, column: 11, scope: !491)
// CHECK:STDOUT: !495 = !{!492}
// CHECK:STDOUT: !496 = distinct !DISubprogram(name: "Step", linkageName: "_CStep.Main.f249b435619a5146", scope: null, file: !4, line: 29, type: !423, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !513)
// CHECK:STDOUT: !497 = !DILocalVariable(arg: 1, scope: !496, type: !203)
// CHECK:STDOUT: !498 = !DILocalVariable(arg: 2, scope: !496, type: !8)
// CHECK:STDOUT: !499 = !DILocalVariable(arg: 3, scope: !496, type: !7)
// CHECK:STDOUT: !506 = !DILocation(line: 30, column: 6, scope: !496)
// CHECK:STDOUT: !508 = !DILocation(line: 30, column: 22, scope: !496)
// CHECK:STDOUT: !509 = !DILocation(line: 30, column: 15, scope: !496)
// CHECK:STDOUT: !511 = !DILocation(line: 31, column: 10, scope: !496)
// CHECK:STDOUT: !512 = !DILocation(line: 31, column: 3, scope: !496)
// CHECK:STDOUT: !513 = !{!497, !498, !499}
// CHECK:STDOUT: !514 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427", scope: null, file: !4, line: 15, type: !111, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !533)
// CHECK:STDOUT: !515 = !DILocalVariable(arg: 1, scope: !514, type: !8)
// CHECK:STDOUT: !520 = !DILocation(line: 17, column: 7, scope: !514)
// CHECK:STDOUT: !523 = !DILocation(line: 17, column: 34, scope: !514)
// CHECK:STDOUT: !524 = !DILocation(line: 17, column: 27, scope: !514)
// CHECK:STDOUT: !525 = !DILocation(line: 18, column: 7, scope: !514)
// CHECK:STDOUT: !528 = !DILocation(line: 18, column: 35, scope: !514)
// CHECK:STDOUT: !529 = !DILocation(line: 18, column: 28, scope: !514)
// CHECK:STDOUT: !531 = !DILocation(line: 22, column: 12, scope: !514)
// CHECK:STDOUT: !532 = !DILocation(line: 22, column: 5, scope: !514)
// CHECK:STDOUT: !533 = !{!515}
// CHECK:STDOUT: !534 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427", scope: null, file: !4, line: 24, type: !113, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !542)
// CHECK:STDOUT: !535 = !DILocalVariable(arg: 1, scope: !534, type: !7)
// CHECK:STDOUT: !540 = !DILocation(line: 24, column: 39, scope: !534)
// CHECK:STDOUT: !541 = !DILocation(line: 24, column: 32, scope: !534)
// CHECK:STDOUT: !542 = !{!535}
// CHECK:STDOUT: !543 = distinct !DISubprogram(name: "Discard", linkageName: "_CDiscard.Main.f249b435619a5146", scope: null, file: !4, line: 36, type: !209, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !547)
// CHECK:STDOUT: !544 = !DILocalVariable(arg: 1, scope: !543, type: !203)
// CHECK:STDOUT: !546 = !DILocation(line: 36, column: 1, scope: !543)
// CHECK:STDOUT: !547 = !{!544}
// CHECK:STDOUT: !548 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.MyResult.Main.b7dd877894074427", scope: null, file: !4, line: 3, type: !432, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !552)
// CHECK:STDOUT: !549 = !DILocalVariable(arg: 1, scope: !548, type: !203)
// CHECK:STDOUT: !550 = !DILocation(line: 3, column: 1, scope: !548)
// CHECK:STDOUT: !551 = !DILocation(line: 4, column: 11, scope: !548)
// CHECK:STDOUT: !552 = !{!549}
// CHECK:STDOUT: !553 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.8122a03446648385", scope: null, file: !4, line: 3, type: !113, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !556)
// CHECK:STDOUT: !554 = !DILocalVariable(arg: 1, scope: !553, type: !7)
// CHECK:STDOUT: !555 = !DILocation(line: 3, column: 1, scope: !553)
// CHECK:STDOUT: !556 = !{!554}
// CHECK:STDOUT: !557 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.8122a03446648385", scope: null, file: !186, line: 21, type: !113, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !561)
// CHECK:STDOUT: !558 = !DILocalVariable(arg: 1, scope: !557, type: !7)
// CHECK:STDOUT: !559 = !DILocation(line: 21, column: 1, scope: !557)
// CHECK:STDOUT: !560 = !DILocation(line: 22, column: 21, scope: !557)
// CHECK:STDOUT: !561 = !{!558}
// CHECK:STDOUT: !562 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.8122a03446648385", scope: null, file: !186, line: 21, type: !113, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !565)
// CHECK:STDOUT: !563 = !DILocalVariable(arg: 1, scope: !562, type: !7)
// CHECK:STDOUT: !564 = !DILocation(line: 21, column: 1, scope: !562)
// CHECK:STDOUT: !565 = !{!563}
// CHECK:STDOUT: !566 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.9bba81283511934f", scope: null, file: !4, line: 11, type: !160, spFlags: DISPFlagDefinition, unit: !202)
// CHECK:STDOUT: !569 = !DILocation(line: 11, column: 45, scope: !566)
// CHECK:STDOUT: !570 = !DILocation(line: 11, column: 38, scope: !566)
// CHECK:STDOUT: !571 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.b7dd877894074427", scope: null, file: !186, line: 21, type: !432, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !575)
// CHECK:STDOUT: !572 = !DILocalVariable(arg: 1, scope: !571, type: !203)
// CHECK:STDOUT: !573 = !DILocation(line: 21, column: 1, scope: !571)
// CHECK:STDOUT: !574 = !DILocation(line: 22, column: 21, scope: !571)
// CHECK:STDOUT: !575 = !{!572}
// CHECK:STDOUT: !576 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.b7dd877894074427", scope: null, file: !186, line: 21, type: !113, spFlags: DISPFlagDefinition, unit: !202, retainedNodes: !579)
// CHECK:STDOUT: !577 = !DILocalVariable(arg: 1, scope: !576, type: !7)
// CHECK:STDOUT: !578 = !DILocation(line: 21, column: 1, scope: !576)
// CHECK:STDOUT: !579 = !{!577}
// CHECK:STDOUT: !580 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.fc3567e4618671b9", scope: null, file: !4, line: 11, type: !160, spFlags: DISPFlagDefinition, unit: !202)
// CHECK:STDOUT: !583 = !DILocation(line: 11, column: 45, scope: !580)
// CHECK:STDOUT: !584 = !DILocation(line: 11, column: 38, scope: !580)
// CHECK:STDOUT:

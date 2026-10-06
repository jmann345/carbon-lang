// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/operators/question_generic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/operators/question_generic.carbon

// The instantiated-generic `?` golden (fork/b2/plan.md §3, the B2a exit
// criterion as revised; risk R-1's falsifiers): a generic `?` body checked
// under §2.2's symbolic-choice destroy answer, monomorphized at concrete
// arguments. The specific's CFG must carry the concrete discriminant test,
// payload access, `FromBreak` call and early `ret` — and the SAME
// no-op-body destroy-call shape the concrete baseline pins
// (lower/testdata/operators/question.carbon `_CBasic.Main`): calls to empty
// `weak_odr` `_COp…core.Destroy.Core` definitions on BOTH exclusive paths.
// Falsification is a destroy call whose definition body is NON-EMPTY, a
// USER `Destroy` impl invoked on the propagation path, or destroy calls
// ABSENT where the concrete baseline has them. `adapter_payload.carbon` is
// the S1 admitted-exception probe: a payload adapter carrying a user
// `Core.Destroy` impl — the concrete re-derivation answers `NonTrivial`
// for the choice (which is why §2.2's symbolic answer is
// `NonTrivial`-deferred, never `Trivial`), and the choice's synthesized
// destroy op stays a placeholder no-op that runs no member destructor, so
// the user impl is never invoked on the propagation path. Since SL-1
// (fork/slices/plan.md R-12, amended 2026-10-05) the adapter's OWN destroy
// witness is its declared impl, not a synthesized one: no
// `_COp…core.Destroy.Core` definition for `Tag` is emitted any more.

// --- generic.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// Returns a value of any type by never returning — the unreachable
// trailing-return helper for generic match-reconstruct bodies
// (fork/b1/plan.md §2.6, dated correction). The explicit generic type
// param + self-recursion is the arbiter-verified
// function/generic/deduce.carbon `ExplicitGenericParam` shape.
fn Diverge(generic T2: type) -> T2 { return Diverge(T2); }

impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6, W-073 dated
    // amendment): reachability doesn't consult match exhaustiveness; no
    // generic `ControlFlow(T, E)` value is conjurable, and through this
    // NON-final impl the interface-recursive call does not type-collapse
    // (upstream specialization soundness keeps its projections unreduced;
    // under `final` it does — question_final.carbon), so use the helper.
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

// The restored W-071 discharge body (check golden
// check/testdata/operators/question.carbon, generic split): `?` on a
// facet-bound operand, carrier `Core.ControlFlow(R.ContinueType, i32)` —
// symbolic at check time, concrete in the instantiation below.
fn PropagateOnly[R: Core.Try where .BreakType = i32](r: R) -> R {
  let unused c: R.ContinueType = r?;
  return R.FromBreak(0);
}

// The concrete instantiation that lowers the specific: `R` deduced as
// `MyResult(i32, i32)` (param-to-param forwarding, the
// match/choice_generic_scrutinee.carbon `Classify`/`F` shape).
fn Call(r: MyResult(i32, i32)) -> MyResult(i32, i32) {
  return PropagateOnly(r);
}

// --- adapter_payload.carbon
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

// The S1 admitted-exception shape: an SF-6-admissible payload adapter (over
// `i32`) that carries a USER `Core.Destroy` impl. The payload allowlist does
// not query destroy witnesses, so this passes SF-6; the concrete destroy
// re-derivation of `MyResult(Tag, i32)` finds the user witness for `Tag`
// (through impl lookup — the destroy custom witness yields to a declared
// impl, custom_witness.cpp `CanDestroyClass`) and answers `NonTrivial`.
// While member destruction in destroy-op synthesis is a placeholder, the
// lowered destroy calls on the propagation path (on `MyResult`/`ControlFlow`
// temporaries, never on a `Tag` object) remain calls to EMPTY no-op bodies
// that never invoke `Tag.as.Destroy.impl.Op` — §2.2's revisit note carries
// the future obligation.
class Tag {
  adapt i32;
}

// The upstream user-impl shape (lower/testdata/var/destroy_control_flow.carbon
// `impl as Core.Destroy { fn Op(self); }`), with a defined no-op body so the
// golden can prove it is never called on the propagation path.
impl Tag as Core.Destroy {
  // CHECK:STDERR: adapter_payload.carbon:[[@LINE+4]]:9: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Op(self) {}
  // CHECK:STDERR:         ^~~~
  // CHECK:STDERR:
  fn Op(self) {}
}

fn PropagateOnly[R: Core.Try where .BreakType = i32](r: R) -> R {
  let unused c: R.ContinueType = r?;
  return R.FromBreak(0);
}

fn CallAdapter(r: MyResult(Tag, i32)) -> MyResult(Tag, i32) {
  return PropagateOnly(r);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'generic.carbon'
// CHECK:STDOUT: source_filename = "generic.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @ControlFlow.val.f6c.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @ControlFlow.val.493.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @MyResult.val.df1.loc3_35.7 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %r) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CPropagateOnly.Main.74e35ed26b9760b3(ptr %return, ptr %r), !dbg !23
// CHECK:STDOUT:   ret void, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !26 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !30 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !36
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !36
// CHECK:STDOUT:   ret void, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !38 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !40
// CHECK:STDOUT:   ret void, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core"(ptr %self) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b63d267505e804f2:core.Destroy.Core"(ptr %self) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core"(ptr %self), !dbg !48
// CHECK:STDOUT:   ret void, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.88b1683142354768:core.Destroy.Core"(ptr %self) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc38_35.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !52
// CHECK:STDOUT:   call void @"_CSelfDestruct.b63d267505e804f2:core.Destroy.Core"(ptr %.loc38_35.1.payload), !dbg !52
// CHECK:STDOUT:   %.loc38_35.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !52
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc38_35.2.discriminant), !dbg !52
// CHECK:STDOUT:   ret void, !dbg !52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.88b1683142354768:core.Destroy.Core"(ptr %self) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.88b1683142354768:core.Destroy.Core"(ptr %self), !dbg !56
// CHECK:STDOUT:   ret void, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core"(ptr %self) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !60
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %self) #0 !dbg !62 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core"(ptr %self), !dbg !64
// CHECK:STDOUT:   ret void, !dbg !64
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CPropagateOnly.Main.74e35ed26b9760b3(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %r) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc38_35.3.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !71
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc38_35.3.temp), !dbg !71
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %.loc38_35.3.temp, ptr %r), !dbg !71
// CHECK:STDOUT:   %.loc38_35.7.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc38_35.3.temp, i32 0, i32 0, !dbg !71
// CHECK:STDOUT:   %.loc38_35.8 = load i8, ptr %.loc38_35.7.discriminant, align 1, !dbg !71
// CHECK:STDOUT:   %.loc38_35.81 = trunc i8 %.loc38_35.8 to i1, !dbg !71
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc38_35.81, !dbg !71
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc38_35.1, label %.loc38_35.2, !dbg !71
// CHECK:STDOUT:
// CHECK:STDOUT: .loc38_35.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc38_35.11.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc38_35.3.temp, i32 0, i32 1, !dbg !71
// CHECK:STDOUT:   %.loc38_35.12.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc38_35.11.payload, i32 0, i32 0, !dbg !71
// CHECK:STDOUT:   %tuple.elem0.loc38_35.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc38_35.12.Break, i32 0, i32 0, !dbg !71
// CHECK:STDOUT:   %.loc38_35.13 = load i32, ptr %tuple.elem0.loc38_35.1.tuple.elem, align 4, !dbg !71
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %.loc38_35.13), !dbg !71
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc38_35.3.temp), !dbg !71
// CHECK:STDOUT:   ret void, !dbg !71
// CHECK:STDOUT:
// CHECK:STDOUT: .loc38_35.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc38_35.17.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc38_35.3.temp, i32 0, i32 1, !dbg !71
// CHECK:STDOUT:   %.loc38_35.18.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc38_35.17.payload, i32 0, i32 0, !dbg !71
// CHECK:STDOUT:   %tuple.elem0.loc38_35.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc38_35.18.Continue, i32 0, i32 0, !dbg !71
// CHECK:STDOUT:   %.loc38_35.19 = load i32, ptr %tuple.elem0.loc38_35.2.tuple.elem, align 4, !dbg !71
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 0), !dbg !76
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc38_35.3.temp), !dbg !71
// CHECK:STDOUT:   ret void, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !79 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !85
// CHECK:STDOUT:   %.loc19_22.4 = load i8, ptr %.loc19_22.3.discriminant, align 1, !dbg !85
// CHECK:STDOUT:   %.loc19_22.41 = trunc i8 %.loc19_22.4 to i1, !dbg !85
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc19 = icmp eq i1 false, %.loc19_22.41, !dbg !85
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc19, label %match.case.then.loc19, label %match.case.else.loc19, !dbg !85
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc19:                            ; preds = %entry
// CHECK:STDOUT:   %.loc19_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !85
// CHECK:STDOUT:   %.loc19_22.8.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc19_22.7.payload, i32 0, i32 0, !dbg !85
// CHECK:STDOUT:   %tuple.elem0.loc19.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc19_22.8.Ok, i32 0, i32 0, !dbg !85
// CHECK:STDOUT:   %.loc19_22.9 = load i32, ptr %tuple.elem0.loc19.tuple.elem, align 4, !dbg !85
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc19_22.9), !dbg !88
// CHECK:STDOUT:   ret void, !dbg !89
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc19:                            ; preds = %entry
// CHECK:STDOUT:   %.loc20_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !90
// CHECK:STDOUT:   %.loc20_23.4 = load i8, ptr %.loc20_23.3.discriminant, align 1, !dbg !90
// CHECK:STDOUT:   %.loc20_23.42 = trunc i8 %.loc20_23.4 to i1, !dbg !90
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc20 = icmp eq i1 true, %.loc20_23.42, !dbg !90
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc20, label %match.case.then.loc20, label %match.done, !dbg !90
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc20:                            ; preds = %match.case.else.loc19
// CHECK:STDOUT:   %.loc20_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !90
// CHECK:STDOUT:   %.loc20_23.8.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc20_23.7.payload, i32 0, i32 0, !dbg !90
// CHECK:STDOUT:   %tuple.elem0.loc20.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc20_23.8.Err, i32 0, i32 0, !dbg !90
// CHECK:STDOUT:   %.loc20_23.9 = load i32, ptr %tuple.elem0.loc20.tuple.elem, align 4, !dbg !90
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc20_23.9), !dbg !93
// CHECK:STDOUT:   ret void, !dbg !94
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc19
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !96
// CHECK:STDOUT:   ret void, !dbg !99
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %e) #0 !dbg !101 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %e), !dbg !107
// CHECK:STDOUT:   ret void, !dbg !108
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !111 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !113
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !113
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !113
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !114
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.f6c.anon, i64 8, i1 false), !dbg !113
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !113
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !114
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !114
// CHECK:STDOUT:   ret void, !dbg !113
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !116 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !118
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !118
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.493.anon, i64 8, i1 false), !dbg !118
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !118
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !118
// CHECK:STDOUT:   ret void, !dbg !118
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.9bba81283511934f(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !120 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !123
// CHECK:STDOUT:   ret void, !dbg !124
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !125 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !127
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !127
// CHECK:STDOUT:   %.loc3_35.5.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !127
// CHECK:STDOUT:   %.loc6_1.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !127
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.df1.loc3_35.7, i64 8, i1 false), !dbg !127
// CHECK:STDOUT:   store { i32 } %.loc6_1.1.tuple.init, ptr %.loc3_35.5.Err, align 4, !dbg !127
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Err, i32 0, i32 0, !dbg !127
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !127
// CHECK:STDOUT:   ret void, !dbg !127
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "generic.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!8, !8}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = !{null, !6}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{null, !7}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{null, !8}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !4, line: 45, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !25)
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !17, type: !8)
// CHECK:STDOUT: !23 = !DILocation(line: 46, column: 10, scope: !17)
// CHECK:STDOUT: !24 = !DILocation(line: 46, column: 3, scope: !17)
// CHECK:STDOUT: !25 = !{!18}
// CHECK:STDOUT: !26 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !4, line: 38, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !29)
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 1, scope: !26, type: !6)
// CHECK:STDOUT: !28 = !DILocation(line: 38, column: 34, scope: !26)
// CHECK:STDOUT: !29 = !{!27}
// CHECK:STDOUT: !30 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 38, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !33)
// CHECK:STDOUT: !31 = !DILocalVariable(arg: 1, scope: !30, type: !7)
// CHECK:STDOUT: !32 = !DILocation(line: 38, column: 34, scope: !30)
// CHECK:STDOUT: !33 = !{!31}
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 38, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !37)
// CHECK:STDOUT: !35 = !DILocalVariable(arg: 1, scope: !34, type: !8)
// CHECK:STDOUT: !36 = !DILocation(line: 38, column: 34, scope: !34)
// CHECK:STDOUT: !37 = !{!35}
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 38, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !41)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !38, type: !8)
// CHECK:STDOUT: !40 = !DILocation(line: 38, column: 34, scope: !38)
// CHECK:STDOUT: !41 = !{!39}
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core", scope: null, file: !4, line: 38, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !45)
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !42, type: !8)
// CHECK:STDOUT: !44 = !DILocation(line: 38, column: 34, scope: !42)
// CHECK:STDOUT: !45 = !{!43}
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b63d267505e804f2:core.Destroy.Core", scope: null, file: !4, line: 38, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !49)
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !46, type: !8)
// CHECK:STDOUT: !48 = !DILocation(line: 38, column: 34, scope: !46)
// CHECK:STDOUT: !49 = !{!47}
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.88b1683142354768:core.Destroy.Core", scope: null, file: !4, line: 38, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !53)
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 1, scope: !50, type: !8)
// CHECK:STDOUT: !52 = !DILocation(line: 38, column: 34, scope: !50)
// CHECK:STDOUT: !53 = !{!51}
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.88b1683142354768:core.Destroy.Core", scope: null, file: !4, line: 38, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !57)
// CHECK:STDOUT: !55 = !DILocalVariable(arg: 1, scope: !54, type: !8)
// CHECK:STDOUT: !56 = !DILocation(line: 38, column: 34, scope: !54)
// CHECK:STDOUT: !57 = !{!55}
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core", scope: null, file: !4, line: 38, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !61)
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !58, type: !8)
// CHECK:STDOUT: !60 = !DILocation(line: 38, column: 34, scope: !58)
// CHECK:STDOUT: !61 = !{!59}
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core", scope: null, file: !4, line: 38, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !65)
// CHECK:STDOUT: !63 = !DILocalVariable(arg: 1, scope: !62, type: !8)
// CHECK:STDOUT: !64 = !DILocation(line: 38, column: 34, scope: !62)
// CHECK:STDOUT: !65 = !{!63}
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "PropagateOnly", linkageName: "_CPropagateOnly.Main.74e35ed26b9760b3", scope: null, file: !4, line: 37, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !78)
// CHECK:STDOUT: !67 = !DILocalVariable(arg: 1, scope: !66, type: !8)
// CHECK:STDOUT: !71 = !DILocation(line: 38, column: 34, scope: !66)
// CHECK:STDOUT: !72 = !{!8, !7}
// CHECK:STDOUT: !73 = !DISubroutineType(types: !72)
// CHECK:STDOUT: !76 = !DILocation(line: 39, column: 10, scope: !66)
// CHECK:STDOUT: !77 = !DILocation(line: 39, column: 3, scope: !66)
// CHECK:STDOUT: !78 = !{!67}
// CHECK:STDOUT: !79 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !4, line: 17, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !100)
// CHECK:STDOUT: !80 = !DILocalVariable(arg: 1, scope: !79, type: !8)
// CHECK:STDOUT: !85 = !DILocation(line: 19, column: 7, scope: !79)
// CHECK:STDOUT: !88 = !DILocation(line: 19, column: 34, scope: !79)
// CHECK:STDOUT: !89 = !DILocation(line: 19, column: 27, scope: !79)
// CHECK:STDOUT: !90 = !DILocation(line: 20, column: 7, scope: !79)
// CHECK:STDOUT: !93 = !DILocation(line: 20, column: 35, scope: !79)
// CHECK:STDOUT: !94 = !DILocation(line: 20, column: 28, scope: !79)
// CHECK:STDOUT: !96 = !DILocation(line: 28, column: 12, scope: !79)
// CHECK:STDOUT: !97 = !{!8}
// CHECK:STDOUT: !98 = !DISubroutineType(types: !97)
// CHECK:STDOUT: !99 = !DILocation(line: 28, column: 5, scope: !79)
// CHECK:STDOUT: !100 = !{!80}
// CHECK:STDOUT: !101 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !4, line: 30, type: !73, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !109)
// CHECK:STDOUT: !102 = !DILocalVariable(arg: 1, scope: !101, type: !7)
// CHECK:STDOUT: !107 = !DILocation(line: 30, column: 39, scope: !101)
// CHECK:STDOUT: !108 = !DILocation(line: 30, column: 32, scope: !101)
// CHECK:STDOUT: !109 = !{!102}
// CHECK:STDOUT: !110 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !111 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.8122a03446648385", scope: null, file: !110, line: 21, type: !73, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !115)
// CHECK:STDOUT: !112 = !DILocalVariable(arg: 1, scope: !111, type: !7)
// CHECK:STDOUT: !113 = !DILocation(line: 21, column: 1, scope: !111)
// CHECK:STDOUT: !114 = !DILocation(line: 22, column: 21, scope: !111)
// CHECK:STDOUT: !115 = !{!112}
// CHECK:STDOUT: !116 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.8122a03446648385", scope: null, file: !110, line: 21, type: !73, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !119)
// CHECK:STDOUT: !117 = !DILocalVariable(arg: 1, scope: !116, type: !7)
// CHECK:STDOUT: !118 = !DILocation(line: 21, column: 1, scope: !116)
// CHECK:STDOUT: !119 = !{!117}
// CHECK:STDOUT: !120 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.9bba81283511934f", scope: null, file: !4, line: 13, type: !98, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !123 = !DILocation(line: 13, column: 45, scope: !120)
// CHECK:STDOUT: !124 = !DILocation(line: 13, column: 38, scope: !120)
// CHECK:STDOUT: !125 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.8122a03446648385", scope: null, file: !4, line: 3, type: !73, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !128)
// CHECK:STDOUT: !126 = !DILocalVariable(arg: 1, scope: !125, type: !7)
// CHECK:STDOUT: !127 = !DILocation(line: 3, column: 1, scope: !125)
// CHECK:STDOUT: !128 = !{!126}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'adapter_payload.carbon'
// CHECK:STDOUT: source_filename = "adapter_payload.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @ControlFlow.val.24e.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @ControlFlow.val.8af.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @MyResult.val.005.loc3_35.7 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.Tag.Main:Destroy.Core"(i32 %self) #0 !dbg !131 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !134
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_COp:thunk:Destroy.3d376358904aedc3.Core:Tag.Main:Destroy.Core"(ptr %self) #1 !dbg !136 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.2 = load i32, ptr %self, align 4, !dbg !138
// CHECK:STDOUT:   call void @"_COp.Tag.Main:Destroy.Core"(i32 %.2), !dbg !139
// CHECK:STDOUT:   ret void, !dbg !139
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCallAdapter.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %r) #0 !dbg !141 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CPropagateOnly.Main.20eb365082aa2002(ptr %return, ptr %r), !dbg !147
// CHECK:STDOUT:   ret void, !dbg !148
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !150 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !152
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.0fbd086e97a8a622:core.Destroy.Core"(ptr %self) #0 !dbg !154 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !156
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.3d376358904aedc3(ptr %tuple.elem0.tuple.elem), !dbg !156
// CHECK:STDOUT:   ret void, !dbg !156
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0fbd086e97a8a622:core.Destroy.Core"(ptr %self) #0 !dbg !158 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.0fbd086e97a8a622:core.Destroy.Core"(ptr %self), !dbg !160
// CHECK:STDOUT:   ret void, !dbg !160
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !162 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !164
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !166 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !168
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !168
// CHECK:STDOUT:   ret void, !dbg !168
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !170 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !172
// CHECK:STDOUT:   ret void, !dbg !172
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.ca2b2c3186bc8ef6:core.Destroy.Core"(ptr %self) #0 !dbg !174 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !176
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.ca2b2c3186bc8ef6:core.Destroy.Core"(ptr %self) #0 !dbg !178 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.ca2b2c3186bc8ef6:core.Destroy.Core"(ptr %self), !dbg !180
// CHECK:STDOUT:   ret void, !dbg !180
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.8109e94e73474999:core.Destroy.Core"(ptr %self) #0 !dbg !182 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc54_35.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !184
// CHECK:STDOUT:   call void @"_CSelfDestruct.ca2b2c3186bc8ef6:core.Destroy.Core"(ptr %.loc54_35.1.payload), !dbg !184
// CHECK:STDOUT:   %.loc54_35.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !184
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc54_35.2.discriminant), !dbg !184
// CHECK:STDOUT:   ret void, !dbg !184
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.8109e94e73474999:core.Destroy.Core"(ptr %self) #0 !dbg !186 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.8109e94e73474999:core.Destroy.Core"(ptr %self), !dbg !188
// CHECK:STDOUT:   ret void, !dbg !188
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.24eff58700437d79:core.Destroy.Core"(ptr %self) #0 !dbg !190 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !192
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.24eff58700437d79:core.Destroy.Core"(ptr %self) #0 !dbg !194 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.24eff58700437d79:core.Destroy.Core"(ptr %self), !dbg !196
// CHECK:STDOUT:   ret void, !dbg !196
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CPropagateOnly.Main.20eb365082aa2002(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %r) #0 !dbg !198 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc54_35.3.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !203
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc54_35.3.temp), !dbg !203
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.adf6da85a9ce6143"(ptr %.loc54_35.3.temp, ptr %r), !dbg !203
// CHECK:STDOUT:   %.loc54_35.7.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc54_35.3.temp, i32 0, i32 0, !dbg !203
// CHECK:STDOUT:   %.loc54_35.8 = load i8, ptr %.loc54_35.7.discriminant, align 1, !dbg !203
// CHECK:STDOUT:   %.loc54_35.81 = trunc i8 %.loc54_35.8 to i1, !dbg !203
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc54_35.81, !dbg !203
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc54_35.1, label %.loc54_35.2, !dbg !203
// CHECK:STDOUT:
// CHECK:STDOUT: .loc54_35.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc54_35.11.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc54_35.3.temp, i32 0, i32 1, !dbg !203
// CHECK:STDOUT:   %.loc54_35.12.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc54_35.11.payload, i32 0, i32 0, !dbg !203
// CHECK:STDOUT:   %tuple.elem0.loc54_35.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc54_35.12.Break, i32 0, i32 0, !dbg !203
// CHECK:STDOUT:   %.loc54_35.13 = load i32, ptr %tuple.elem0.loc54_35.1.tuple.elem, align 4, !dbg !203
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.adf6da85a9ce6143"(ptr %return, i32 %.loc54_35.13), !dbg !203
// CHECK:STDOUT:   call void @"_CSelfDestruct.24eff58700437d79:core.Destroy.Core"(ptr %.loc54_35.3.temp), !dbg !203
// CHECK:STDOUT:   ret void, !dbg !203
// CHECK:STDOUT:
// CHECK:STDOUT: .loc54_35.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc54_35.17.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc54_35.3.temp, i32 0, i32 1, !dbg !203
// CHECK:STDOUT:   %.loc54_35.18.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc54_35.17.payload, i32 0, i32 0, !dbg !203
// CHECK:STDOUT:   %tuple.elem0.loc54_35.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc54_35.18.Continue, i32 0, i32 0, !dbg !203
// CHECK:STDOUT:   %.loc54_35.19 = load i32, ptr %tuple.elem0.loc54_35.2.tuple.elem, align 4, !dbg !203
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.adf6da85a9ce6143"(ptr %return, i32 0), !dbg !206
// CHECK:STDOUT:   call void @"_CSelfDestruct.24eff58700437d79:core.Destroy.Core"(ptr %.loc54_35.3.temp), !dbg !203
// CHECK:STDOUT:   ret void, !dbg !207
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.3d376358904aedc3(ptr %self) #0 !dbg !210 {
// CHECK:STDOUT:   call void @"_COp:thunk:Destroy.3d376358904aedc3.Core:Tag.Main:Destroy.Core"(ptr %self), !dbg !213
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.3d376358904aedc3(ptr %self), !dbg !214
// CHECK:STDOUT:   ret void, !dbg !215
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.adf6da85a9ce6143"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !217 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !223
// CHECK:STDOUT:   %.loc17_22.4 = load i8, ptr %.loc17_22.3.discriminant, align 1, !dbg !223
// CHECK:STDOUT:   %.loc17_22.41 = trunc i8 %.loc17_22.4 to i1, !dbg !223
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc17 = icmp eq i1 false, %.loc17_22.41, !dbg !223
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc17, label %match.case.then.loc17, label %match.case.else.loc17, !dbg !223
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc17_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !223
// CHECK:STDOUT:   %.loc17_22.8.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc17_22.7.payload, i32 0, i32 0, !dbg !223
// CHECK:STDOUT:   %tuple.elem0.loc17.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc17_22.8.Ok, i32 0, i32 0, !dbg !223
// CHECK:STDOUT:   %.loc17_22.9 = load i32, ptr %tuple.elem0.loc17.tuple.elem, align 4, !dbg !223
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.adf6da85a9ce6143(ptr %return, i32 %.loc17_22.9), !dbg !226
// CHECK:STDOUT:   ret void, !dbg !227
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc18_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !228
// CHECK:STDOUT:   %.loc18_23.4 = load i8, ptr %.loc18_23.3.discriminant, align 1, !dbg !228
// CHECK:STDOUT:   %.loc18_23.42 = trunc i8 %.loc18_23.4 to i1, !dbg !228
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc18 = icmp eq i1 true, %.loc18_23.42, !dbg !228
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc18, label %match.case.then.loc18, label %match.done, !dbg !228
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc18:                            ; preds = %match.case.else.loc17
// CHECK:STDOUT:   %.loc18_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !228
// CHECK:STDOUT:   %.loc18_23.8.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc18_23.7.payload, i32 0, i32 0, !dbg !228
// CHECK:STDOUT:   %tuple.elem0.loc18.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc18_23.8.Err, i32 0, i32 0, !dbg !228
// CHECK:STDOUT:   %.loc18_23.9 = load i32, ptr %tuple.elem0.loc18.tuple.elem, align 4, !dbg !228
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.adf6da85a9ce6143(ptr %return, i32 %.loc18_23.9), !dbg !231
// CHECK:STDOUT:   ret void, !dbg !232
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc17
// CHECK:STDOUT:   call void @_CDiverge.Main.e2d64f994780358e(ptr %return), !dbg !234
// CHECK:STDOUT:   ret void, !dbg !235
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.adf6da85a9ce6143"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %e) #0 !dbg !237 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.adf6da85a9ce6143(ptr %return, i32 %e), !dbg !243
// CHECK:STDOUT:   ret void, !dbg !244
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.3d376358904aedc3(ptr %self) #0 !dbg !246 {
// CHECK:STDOUT:   ret void, !dbg !249
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.adf6da85a9ce6143(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !251 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !253
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !253
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !253
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !254
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.24e.anon, i64 8, i1 false), !dbg !253
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !253
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !254
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !254
// CHECK:STDOUT:   ret void, !dbg !253
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.adf6da85a9ce6143(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !256 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !258
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !258
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !258
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !258
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.8af.anon, i64 8, i1 false), !dbg !258
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !258
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !258
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !258
// CHECK:STDOUT:   ret void, !dbg !258
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.e2d64f994780358e(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !260 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiverge.Main.e2d64f994780358e(ptr %return), !dbg !263
// CHECK:STDOUT:   ret void, !dbg !264
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.adf6da85a9ce6143(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !265 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !267
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !267
// CHECK:STDOUT:   %.loc3_35.5.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !267
// CHECK:STDOUT:   %.loc6_1.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !267
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.005.loc3_35.7, i64 8, i1 false), !dbg !267
// CHECK:STDOUT:   store { i32 } %.loc6_1.1.tuple.init, ptr %.loc3_35.5.Err, align 4, !dbg !267
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Err, i32 0, i32 0, !dbg !267
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !267
// CHECK:STDOUT:   ret void, !dbg !267
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.adf6da85a9ce6143", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline nounwind }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!130}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!8, !8}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = !{null, !6}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{null, !7}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{null, !8}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !72 = !{!8, !7}
// CHECK:STDOUT: !73 = !DISubroutineType(types: !72)
// CHECK:STDOUT: !97 = !{!8}
// CHECK:STDOUT: !98 = !DISubroutineType(types: !97)
// CHECK:STDOUT: !110 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !129 = !DIFile(filename: "adapter_payload.carbon", directory: "")
// CHECK:STDOUT: !130 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !129, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !131 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Tag.Main:Destroy.Core", scope: null, file: !129, line: 50, type: !14, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !135)
// CHECK:STDOUT: !132 = !DILocalVariable(arg: 1, scope: !131, type: !7)
// CHECK:STDOUT: !134 = !DILocation(line: 50, column: 3, scope: !131)
// CHECK:STDOUT: !135 = !{!132}
// CHECK:STDOUT: !136 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:Destroy.3d376358904aedc3.Core:Tag.Main:Destroy.Core", scope: null, file: !129, line: 50, type: !14, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !140)
// CHECK:STDOUT: !137 = !DILocalVariable(arg: 1, scope: !136, type: !7)
// CHECK:STDOUT: !138 = !DILocation(line: 0, scope: !136)
// CHECK:STDOUT: !139 = !DILocation(line: 50, column: 3, scope: !136)
// CHECK:STDOUT: !140 = !{!137}
// CHECK:STDOUT: !141 = distinct !DISubprogram(name: "CallAdapter", linkageName: "_CCallAdapter.Main", scope: null, file: !129, line: 58, type: !10, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !149)
// CHECK:STDOUT: !142 = !DILocalVariable(arg: 1, scope: !141, type: !8)
// CHECK:STDOUT: !147 = !DILocation(line: 59, column: 10, scope: !141)
// CHECK:STDOUT: !148 = !DILocation(line: 59, column: 3, scope: !141)
// CHECK:STDOUT: !149 = !{!142}
// CHECK:STDOUT: !150 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !129, line: 54, type: !12, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !153)
// CHECK:STDOUT: !151 = !DILocalVariable(arg: 1, scope: !150, type: !6)
// CHECK:STDOUT: !152 = !DILocation(line: 54, column: 34, scope: !150)
// CHECK:STDOUT: !153 = !{!151}
// CHECK:STDOUT: !154 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.0fbd086e97a8a622:core.Destroy.Core", scope: null, file: !129, line: 54, type: !16, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !157)
// CHECK:STDOUT: !155 = !DILocalVariable(arg: 1, scope: !154, type: !8)
// CHECK:STDOUT: !156 = !DILocation(line: 54, column: 34, scope: !154)
// CHECK:STDOUT: !157 = !{!155}
// CHECK:STDOUT: !158 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0fbd086e97a8a622:core.Destroy.Core", scope: null, file: !129, line: 54, type: !16, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !161)
// CHECK:STDOUT: !159 = !DILocalVariable(arg: 1, scope: !158, type: !8)
// CHECK:STDOUT: !160 = !DILocation(line: 54, column: 34, scope: !158)
// CHECK:STDOUT: !161 = !{!159}
// CHECK:STDOUT: !162 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !129, line: 54, type: !14, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !165)
// CHECK:STDOUT: !163 = !DILocalVariable(arg: 1, scope: !162, type: !7)
// CHECK:STDOUT: !164 = !DILocation(line: 54, column: 34, scope: !162)
// CHECK:STDOUT: !165 = !{!163}
// CHECK:STDOUT: !166 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !129, line: 54, type: !16, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !169)
// CHECK:STDOUT: !167 = !DILocalVariable(arg: 1, scope: !166, type: !8)
// CHECK:STDOUT: !168 = !DILocation(line: 54, column: 34, scope: !166)
// CHECK:STDOUT: !169 = !{!167}
// CHECK:STDOUT: !170 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !129, line: 54, type: !16, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !173)
// CHECK:STDOUT: !171 = !DILocalVariable(arg: 1, scope: !170, type: !8)
// CHECK:STDOUT: !172 = !DILocation(line: 54, column: 34, scope: !170)
// CHECK:STDOUT: !173 = !{!171}
// CHECK:STDOUT: !174 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.ca2b2c3186bc8ef6:core.Destroy.Core", scope: null, file: !129, line: 54, type: !16, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !177)
// CHECK:STDOUT: !175 = !DILocalVariable(arg: 1, scope: !174, type: !8)
// CHECK:STDOUT: !176 = !DILocation(line: 54, column: 34, scope: !174)
// CHECK:STDOUT: !177 = !{!175}
// CHECK:STDOUT: !178 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.ca2b2c3186bc8ef6:core.Destroy.Core", scope: null, file: !129, line: 54, type: !16, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !181)
// CHECK:STDOUT: !179 = !DILocalVariable(arg: 1, scope: !178, type: !8)
// CHECK:STDOUT: !180 = !DILocation(line: 54, column: 34, scope: !178)
// CHECK:STDOUT: !181 = !{!179}
// CHECK:STDOUT: !182 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.8109e94e73474999:core.Destroy.Core", scope: null, file: !129, line: 54, type: !16, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !185)
// CHECK:STDOUT: !183 = !DILocalVariable(arg: 1, scope: !182, type: !8)
// CHECK:STDOUT: !184 = !DILocation(line: 54, column: 34, scope: !182)
// CHECK:STDOUT: !185 = !{!183}
// CHECK:STDOUT: !186 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.8109e94e73474999:core.Destroy.Core", scope: null, file: !129, line: 54, type: !16, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !189)
// CHECK:STDOUT: !187 = !DILocalVariable(arg: 1, scope: !186, type: !8)
// CHECK:STDOUT: !188 = !DILocation(line: 54, column: 34, scope: !186)
// CHECK:STDOUT: !189 = !{!187}
// CHECK:STDOUT: !190 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.24eff58700437d79:core.Destroy.Core", scope: null, file: !129, line: 54, type: !16, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !193)
// CHECK:STDOUT: !191 = !DILocalVariable(arg: 1, scope: !190, type: !8)
// CHECK:STDOUT: !192 = !DILocation(line: 54, column: 34, scope: !190)
// CHECK:STDOUT: !193 = !{!191}
// CHECK:STDOUT: !194 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.24eff58700437d79:core.Destroy.Core", scope: null, file: !129, line: 54, type: !16, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !197)
// CHECK:STDOUT: !195 = !DILocalVariable(arg: 1, scope: !194, type: !8)
// CHECK:STDOUT: !196 = !DILocation(line: 54, column: 34, scope: !194)
// CHECK:STDOUT: !197 = !{!195}
// CHECK:STDOUT: !198 = distinct !DISubprogram(name: "PropagateOnly", linkageName: "_CPropagateOnly.Main.20eb365082aa2002", scope: null, file: !129, line: 53, type: !10, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !208)
// CHECK:STDOUT: !199 = !DILocalVariable(arg: 1, scope: !198, type: !8)
// CHECK:STDOUT: !203 = !DILocation(line: 54, column: 34, scope: !198)
// CHECK:STDOUT: !206 = !DILocation(line: 55, column: 10, scope: !198)
// CHECK:STDOUT: !207 = !DILocation(line: 55, column: 3, scope: !198)
// CHECK:STDOUT: !208 = !{!199}
// CHECK:STDOUT: !209 = !DIFile(filename: "{{.*}}/prelude/destroy.carbon", directory: "")
// CHECK:STDOUT: !210 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.3d376358904aedc3", scope: null, file: !209, line: 26, type: !14, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !216)
// CHECK:STDOUT: !211 = !DILocalVariable(arg: 1, scope: !210, type: !7)
// CHECK:STDOUT: !213 = !DILocation(line: 27, column: 5, scope: !210)
// CHECK:STDOUT: !214 = !DILocation(line: 28, column: 5, scope: !210)
// CHECK:STDOUT: !215 = !DILocation(line: 26, column: 3, scope: !210)
// CHECK:STDOUT: !216 = !{!211}
// CHECK:STDOUT: !217 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.adf6da85a9ce6143", scope: null, file: !129, line: 15, type: !10, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !236)
// CHECK:STDOUT: !218 = !DILocalVariable(arg: 1, scope: !217, type: !8)
// CHECK:STDOUT: !223 = !DILocation(line: 17, column: 7, scope: !217)
// CHECK:STDOUT: !226 = !DILocation(line: 17, column: 34, scope: !217)
// CHECK:STDOUT: !227 = !DILocation(line: 17, column: 27, scope: !217)
// CHECK:STDOUT: !228 = !DILocation(line: 18, column: 7, scope: !217)
// CHECK:STDOUT: !231 = !DILocation(line: 18, column: 35, scope: !217)
// CHECK:STDOUT: !232 = !DILocation(line: 18, column: 28, scope: !217)
// CHECK:STDOUT: !234 = !DILocation(line: 22, column: 12, scope: !217)
// CHECK:STDOUT: !235 = !DILocation(line: 22, column: 5, scope: !217)
// CHECK:STDOUT: !236 = !{!218}
// CHECK:STDOUT: !237 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.adf6da85a9ce6143", scope: null, file: !129, line: 24, type: !73, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !245)
// CHECK:STDOUT: !238 = !DILocalVariable(arg: 1, scope: !237, type: !7)
// CHECK:STDOUT: !243 = !DILocation(line: 24, column: 39, scope: !237)
// CHECK:STDOUT: !244 = !DILocation(line: 24, column: 32, scope: !237)
// CHECK:STDOUT: !245 = !{!238}
// CHECK:STDOUT: !246 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.3d376358904aedc3", scope: null, file: !209, line: 19, type: !14, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !250)
// CHECK:STDOUT: !247 = !DILocalVariable(arg: 1, scope: !246, type: !7)
// CHECK:STDOUT: !249 = !DILocation(line: 19, column: 3, scope: !246)
// CHECK:STDOUT: !250 = !{!247}
// CHECK:STDOUT: !251 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.adf6da85a9ce6143", scope: null, file: !110, line: 21, type: !73, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !255)
// CHECK:STDOUT: !252 = !DILocalVariable(arg: 1, scope: !251, type: !7)
// CHECK:STDOUT: !253 = !DILocation(line: 21, column: 1, scope: !251)
// CHECK:STDOUT: !254 = !DILocation(line: 22, column: 21, scope: !251)
// CHECK:STDOUT: !255 = !{!252}
// CHECK:STDOUT: !256 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.adf6da85a9ce6143", scope: null, file: !110, line: 21, type: !73, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !259)
// CHECK:STDOUT: !257 = !DILocalVariable(arg: 1, scope: !256, type: !7)
// CHECK:STDOUT: !258 = !DILocation(line: 21, column: 1, scope: !256)
// CHECK:STDOUT: !259 = !{!257}
// CHECK:STDOUT: !260 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.e2d64f994780358e", scope: null, file: !129, line: 11, type: !98, spFlags: DISPFlagDefinition, unit: !130)
// CHECK:STDOUT: !263 = !DILocation(line: 11, column: 45, scope: !260)
// CHECK:STDOUT: !264 = !DILocation(line: 11, column: 38, scope: !260)
// CHECK:STDOUT: !265 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.adf6da85a9ce6143", scope: null, file: !129, line: 3, type: !73, spFlags: DISPFlagDefinition, unit: !130, retainedNodes: !268)
// CHECK:STDOUT: !266 = !DILocalVariable(arg: 1, scope: !265, type: !7)
// CHECK:STDOUT: !267 = !DILocation(line: 3, column: 1, scope: !265)
// CHECK:STDOUT: !268 = !{!266}
// CHECK:STDOUT:

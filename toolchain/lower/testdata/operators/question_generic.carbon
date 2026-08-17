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
// `Core.Destroy` impl still behaves as today concretely — the concrete
// re-derivation answers `NonTrivial` (which is why §2.2's symbolic answer
// is `NonTrivial`-deferred, never `Trivial`), and the synthesized destroy
// ops stay placeholder no-ops that never invoke the user impl.

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
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6, dated
    // correction): reachability doesn't consult match exhaustiveness; no
    // generic `ControlFlow(T, E)` value is conjurable, and the
    // interface-recursive call does not type-collapse (its return type's
    // associated-constant projections are not reduced by this impl's own
    // `where` rewrites), so diverge through the helper.
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
// re-derivation finds the user witness and answers `NonTrivial`. While
// destroy-op synthesis is a placeholder, the lowered destroy calls on the
// propagation path must remain calls to EMPTY no-op bodies that never
// invoke `Tag.as.Destroy.impl.Op` — §2.2's revisit note carries the future
// obligation.
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
// CHECK:STDOUT: @ControlFlow.val.f6c.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 false, [3 x i8] poison }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @ControlFlow.val.493.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] poison }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @MyResult.val.df1.loc3_35.7 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] poison }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %r) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CPropagateOnly.Main.74e35ed26b9760b3(ptr %return, ptr %r), !dbg !10
// CHECK:STDOUT:   ret void, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.7512aa4144aeb8db:core.Destroy.Core"(ptr %self) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !18
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5e27612b9dd31a14:core.Destroy.Core"(ptr %self) #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.b56e66ed2f8c6490:core.Destroy.Core"(ptr %self) #0 !dbg !26 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.587ed27312a2a337:core.Destroy.Core"(ptr %self) #0 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.104a2f5359783f53:core.Destroy.Core"(ptr %self) #0 !dbg !36 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.95f7b1df2e915936:core.Destroy.Core"(ptr %self) #0 !dbg !40 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CPropagateOnly.Main.74e35ed26b9760b3(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %r) #0 !dbg !44 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc38_35.3.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !47
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc38_35.3.temp), !dbg !47
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %.loc38_35.3.temp, ptr %r), !dbg !47
// CHECK:STDOUT:   %.loc38_35.7.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc38_35.3.temp, i32 0, i32 0, !dbg !47
// CHECK:STDOUT:   %.loc38_35.8 = load i8, ptr %.loc38_35.7.discriminant, align 1, !dbg !47
// CHECK:STDOUT:   %.loc38_35.81 = trunc i8 %.loc38_35.8 to i1, !dbg !47
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc38_35.81, !dbg !47
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc38_35.1, label %.loc38_35.2, !dbg !47
// CHECK:STDOUT:
// CHECK:STDOUT: .loc38_35.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc38_35.11.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc38_35.3.temp, i32 0, i32 1, !dbg !47
// CHECK:STDOUT:   %.loc38_35.12.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc38_35.11.payload, i32 0, i32 0, !dbg !47
// CHECK:STDOUT:   %tuple.elem0.loc38_35.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc38_35.12.Break, i32 0, i32 0, !dbg !47
// CHECK:STDOUT:   %.loc38_35.13 = load i32, ptr %tuple.elem0.loc38_35.1.tuple.elem, align 4, !dbg !47
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %.loc38_35.13), !dbg !47
// CHECK:STDOUT:   call void @"_COp.95f7b1df2e915936:core.Destroy.Core"(ptr %.loc38_35.3.temp), !dbg !47
// CHECK:STDOUT:   ret void, !dbg !47
// CHECK:STDOUT:
// CHECK:STDOUT: .loc38_35.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc38_35.17.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc38_35.3.temp, i32 0, i32 1, !dbg !47
// CHECK:STDOUT:   %.loc38_35.18.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc38_35.17.payload, i32 0, i32 0, !dbg !47
// CHECK:STDOUT:   %tuple.elem0.loc38_35.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc38_35.18.Continue, i32 0, i32 0, !dbg !47
// CHECK:STDOUT:   %.loc38_35.19 = load i32, ptr %tuple.elem0.loc38_35.2.tuple.elem, align 4, !dbg !47
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 0), !dbg !48
// CHECK:STDOUT:   call void @"_COp.95f7b1df2e915936:core.Destroy.Core"(ptr %.loc38_35.3.temp), !dbg !47
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !53
// CHECK:STDOUT:   %.loc19_22.4 = load i8, ptr %.loc19_22.3.discriminant, align 1, !dbg !53
// CHECK:STDOUT:   %.loc19_22.41 = trunc i8 %.loc19_22.4 to i1, !dbg !53
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc19 = icmp eq i1 false, %.loc19_22.41, !dbg !53
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc19, label %match.case.then.loc19, label %match.case.else.loc19, !dbg !53
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc19:                            ; preds = %entry
// CHECK:STDOUT:   %.loc19_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !53
// CHECK:STDOUT:   %.loc19_22.8.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc19_22.7.payload, i32 0, i32 0, !dbg !53
// CHECK:STDOUT:   %tuple.elem0.loc19.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc19_22.8.Ok, i32 0, i32 0, !dbg !53
// CHECK:STDOUT:   %.loc19_22.9 = load i32, ptr %tuple.elem0.loc19.tuple.elem, align 4, !dbg !53
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc19_22.9), !dbg !54
// CHECK:STDOUT:   ret void, !dbg !55
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc19:                            ; preds = %entry
// CHECK:STDOUT:   %.loc20_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !56
// CHECK:STDOUT:   %.loc20_23.4 = load i8, ptr %.loc20_23.3.discriminant, align 1, !dbg !56
// CHECK:STDOUT:   %.loc20_23.42 = trunc i8 %.loc20_23.4 to i1, !dbg !56
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc20 = icmp eq i1 true, %.loc20_23.42, !dbg !56
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc20, label %match.case.then.loc20, label %match.done, !dbg !56
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc20:                            ; preds = %match.case.else.loc19
// CHECK:STDOUT:   %.loc20_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !56
// CHECK:STDOUT:   %.loc20_23.8.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc20_23.7.payload, i32 0, i32 0, !dbg !56
// CHECK:STDOUT:   %tuple.elem0.loc20.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc20_23.8.Err, i32 0, i32 0, !dbg !56
// CHECK:STDOUT:   %.loc20_23.9 = load i32, ptr %tuple.elem0.loc20.tuple.elem, align 4, !dbg !56
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc20_23.9), !dbg !57
// CHECK:STDOUT:   ret void, !dbg !58
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc19
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !59
// CHECK:STDOUT:   ret void, !dbg !60
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %e) #0 !dbg !61 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %e), !dbg !66
// CHECK:STDOUT:   ret void, !dbg !67
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !68 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !72
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !72
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !72
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !73
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.f6c.anon, i64 8, i1 false), !dbg !72
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !72
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !73
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !73
// CHECK:STDOUT:   ret void, !dbg !72
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !74 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !77
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !77
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !77
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !77
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.493.anon, i64 8, i1 false), !dbg !77
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !77
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !77
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !77
// CHECK:STDOUT:   ret void, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.9bba81283511934f(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !78 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !81
// CHECK:STDOUT:   ret void, !dbg !82
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !83 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !86
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !86
// CHECK:STDOUT:   %.loc3_35.5.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !86
// CHECK:STDOUT:   %.loc6_1.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !86
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.df1.loc3_35.7, i64 8, i1 false), !dbg !86
// CHECK:STDOUT:   store { i32 } %.loc6_1.1.tuple.init, ptr %.loc3_35.5.Err, align 4, !dbg !86
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Err, i32 0, i32 0, !dbg !86
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !86
// CHECK:STDOUT:   ret void, !dbg !86
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "generic.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !1, line: 45, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !7}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!9}
// CHECK:STDOUT: !9 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !10 = !DILocation(line: 46, column: 10, scope: !4)
// CHECK:STDOUT: !11 = !DILocation(line: 46, column: 3, scope: !4)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "Op", linkageName: "_COp.7512aa4144aeb8db:core.Destroy.Core", scope: null, file: !1, line: 38, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !16)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{null, !15}
// CHECK:STDOUT: !15 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !16 = !{!17}
// CHECK:STDOUT: !17 = !DILocalVariable(arg: 1, scope: !12, type: !15)
// CHECK:STDOUT: !18 = !DILocation(line: 38, column: 34, scope: !12)
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5e27612b9dd31a14:core.Destroy.Core", scope: null, file: !1, line: 38, type: !20, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !23)
// CHECK:STDOUT: !20 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !21 = !{null, !22}
// CHECK:STDOUT: !22 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !23 = !{!24}
// CHECK:STDOUT: !24 = !DILocalVariable(arg: 1, scope: !19, type: !22)
// CHECK:STDOUT: !25 = !DILocation(line: 38, column: 34, scope: !19)
// CHECK:STDOUT: !26 = distinct !DISubprogram(name: "Op", linkageName: "_COp.b56e66ed2f8c6490:core.Destroy.Core", scope: null, file: !1, line: 38, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !29)
// CHECK:STDOUT: !27 = !DISubroutineType(types: !28)
// CHECK:STDOUT: !28 = !{null, !7}
// CHECK:STDOUT: !29 = !{!30}
// CHECK:STDOUT: !30 = !DILocalVariable(arg: 1, scope: !26, type: !7)
// CHECK:STDOUT: !31 = !DILocation(line: 38, column: 34, scope: !26)
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "Op", linkageName: "_COp.587ed27312a2a337:core.Destroy.Core", scope: null, file: !1, line: 38, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !33)
// CHECK:STDOUT: !33 = !{!34}
// CHECK:STDOUT: !34 = !DILocalVariable(arg: 1, scope: !32, type: !7)
// CHECK:STDOUT: !35 = !DILocation(line: 38, column: 34, scope: !32)
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "Op", linkageName: "_COp.104a2f5359783f53:core.Destroy.Core", scope: null, file: !1, line: 38, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !37)
// CHECK:STDOUT: !37 = !{!38}
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !36, type: !7)
// CHECK:STDOUT: !39 = !DILocation(line: 38, column: 34, scope: !36)
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "Op", linkageName: "_COp.95f7b1df2e915936:core.Destroy.Core", scope: null, file: !1, line: 38, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !41)
// CHECK:STDOUT: !41 = !{!42}
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !40, type: !7)
// CHECK:STDOUT: !43 = !DILocation(line: 38, column: 34, scope: !40)
// CHECK:STDOUT: !44 = distinct !DISubprogram(name: "PropagateOnly", linkageName: "_CPropagateOnly.Main.74e35ed26b9760b3", scope: null, file: !1, line: 37, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !45)
// CHECK:STDOUT: !45 = !{!46}
// CHECK:STDOUT: !46 = !DILocalVariable(arg: 1, scope: !44, type: !7)
// CHECK:STDOUT: !47 = !DILocation(line: 38, column: 34, scope: !44)
// CHECK:STDOUT: !48 = !DILocation(line: 39, column: 10, scope: !44)
// CHECK:STDOUT: !49 = !DILocation(line: 39, column: 3, scope: !44)
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !1, line: 17, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !51)
// CHECK:STDOUT: !51 = !{!52}
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !50, type: !7)
// CHECK:STDOUT: !53 = !DILocation(line: 19, column: 7, scope: !50)
// CHECK:STDOUT: !54 = !DILocation(line: 19, column: 34, scope: !50)
// CHECK:STDOUT: !55 = !DILocation(line: 19, column: 27, scope: !50)
// CHECK:STDOUT: !56 = !DILocation(line: 20, column: 7, scope: !50)
// CHECK:STDOUT: !57 = !DILocation(line: 20, column: 35, scope: !50)
// CHECK:STDOUT: !58 = !DILocation(line: 20, column: 28, scope: !50)
// CHECK:STDOUT: !59 = !DILocation(line: 28, column: 12, scope: !50)
// CHECK:STDOUT: !60 = !DILocation(line: 28, column: 5, scope: !50)
// CHECK:STDOUT: !61 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !1, line: 30, type: !62, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !64)
// CHECK:STDOUT: !62 = !DISubroutineType(types: !63)
// CHECK:STDOUT: !63 = !{!7, !22}
// CHECK:STDOUT: !64 = !{!65}
// CHECK:STDOUT: !65 = !DILocalVariable(arg: 1, scope: !61, type: !22)
// CHECK:STDOUT: !66 = !DILocation(line: 30, column: 39, scope: !61)
// CHECK:STDOUT: !67 = !DILocation(line: 30, column: 32, scope: !61)
// CHECK:STDOUT: !68 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.8122a03446648385", scope: null, file: !69, line: 21, type: !62, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !70)
// CHECK:STDOUT: !69 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !70 = !{!71}
// CHECK:STDOUT: !71 = !DILocalVariable(arg: 1, scope: !68, type: !22)
// CHECK:STDOUT: !72 = !DILocation(line: 21, column: 1, scope: !68)
// CHECK:STDOUT: !73 = !DILocation(line: 22, column: 21, scope: !68)
// CHECK:STDOUT: !74 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.8122a03446648385", scope: null, file: !69, line: 21, type: !62, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !75)
// CHECK:STDOUT: !75 = !{!76}
// CHECK:STDOUT: !76 = !DILocalVariable(arg: 1, scope: !74, type: !22)
// CHECK:STDOUT: !77 = !DILocation(line: 21, column: 1, scope: !74)
// CHECK:STDOUT: !78 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.9bba81283511934f", scope: null, file: !1, line: 13, type: !79, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !79 = !DISubroutineType(types: !80)
// CHECK:STDOUT: !80 = !{!7}
// CHECK:STDOUT: !81 = !DILocation(line: 13, column: 45, scope: !78)
// CHECK:STDOUT: !82 = !DILocation(line: 13, column: 38, scope: !78)
// CHECK:STDOUT: !83 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.8122a03446648385", scope: null, file: !1, line: 3, type: !62, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !84)
// CHECK:STDOUT: !84 = !{!85}
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !83, type: !22)
// CHECK:STDOUT: !86 = !DILocation(line: 3, column: 1, scope: !83)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'adapter_payload.carbon'
// CHECK:STDOUT: source_filename = "adapter_payload.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @ControlFlow.val.24e.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 false, [3 x i8] poison }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @ControlFlow.val.8af.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] poison }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @MyResult.val.005.loc3_35.7 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] poison }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.Tag.Main:Destroy.Core"(i32 %self) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !10
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_COp:thunk:Destroy.3d376358904aedc3.Core:Tag.Main:Destroy.Core"(ptr %self) #1 !dbg !11 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.2 = load i32, ptr %self, align 4, !dbg !14
// CHECK:STDOUT:   call void @"_COp.Tag.Main:Destroy.Core"(i32 %.2), !dbg !15
// CHECK:STDOUT:   ret void, !dbg !15
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCallAdapter.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %r) #0 !dbg !16 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CPropagateOnly.Main.20eb365082aa2002(ptr %return, ptr %r), !dbg !22
// CHECK:STDOUT:   ret void, !dbg !23
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.7512aa4144aeb8db:core.Destroy.Core"(ptr %self) #0 !dbg !24 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5e27612b9dd31a14:core.Destroy.Core"(ptr %self) #0 !dbg !31 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.7ca742a7cec6ea43:core.Destroy.Core"(ptr %self) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.a0e51b57c8f10646:core.Destroy.Core"(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.b56e66ed2f8c6490:core.Destroy.Core"(ptr %self) #0 !dbg !45 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.f9e10282de036468:core.Destroy.Core"(ptr %self) #0 !dbg !49 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.df1f319f5299ff91:core.Destroy.Core"(ptr %self) #0 !dbg !53 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.f10e4bedf5f8286a:core.Destroy.Core"(ptr %self) #0 !dbg !57 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !60
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CPropagateOnly.Main.20eb365082aa2002(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %r) #0 !dbg !61 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc51_35.3.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !64
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc51_35.3.temp), !dbg !64
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.adf6da85a9ce6143"(ptr %.loc51_35.3.temp, ptr %r), !dbg !64
// CHECK:STDOUT:   %.loc51_35.7.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc51_35.3.temp, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   %.loc51_35.8 = load i8, ptr %.loc51_35.7.discriminant, align 1, !dbg !64
// CHECK:STDOUT:   %.loc51_35.81 = trunc i8 %.loc51_35.8 to i1, !dbg !64
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc51_35.81, !dbg !64
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc51_35.1, label %.loc51_35.2, !dbg !64
// CHECK:STDOUT:
// CHECK:STDOUT: .loc51_35.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc51_35.11.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc51_35.3.temp, i32 0, i32 1, !dbg !64
// CHECK:STDOUT:   %.loc51_35.12.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc51_35.11.payload, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   %tuple.elem0.loc51_35.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc51_35.12.Break, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   %.loc51_35.13 = load i32, ptr %tuple.elem0.loc51_35.1.tuple.elem, align 4, !dbg !64
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.adf6da85a9ce6143"(ptr %return, i32 %.loc51_35.13), !dbg !64
// CHECK:STDOUT:   call void @"_COp.f10e4bedf5f8286a:core.Destroy.Core"(ptr %.loc51_35.3.temp), !dbg !64
// CHECK:STDOUT:   ret void, !dbg !64
// CHECK:STDOUT:
// CHECK:STDOUT: .loc51_35.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc51_35.17.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc51_35.3.temp, i32 0, i32 1, !dbg !64
// CHECK:STDOUT:   %.loc51_35.18.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc51_35.17.payload, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   %tuple.elem0.loc51_35.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc51_35.18.Continue, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   %.loc51_35.19 = load i32, ptr %tuple.elem0.loc51_35.2.tuple.elem, align 4, !dbg !64
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.adf6da85a9ce6143"(ptr %return, i32 0), !dbg !65
// CHECK:STDOUT:   call void @"_COp.f10e4bedf5f8286a:core.Destroy.Core"(ptr %.loc51_35.3.temp), !dbg !64
// CHECK:STDOUT:   ret void, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.adf6da85a9ce6143"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !67 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !70
// CHECK:STDOUT:   %.loc17_22.4 = load i8, ptr %.loc17_22.3.discriminant, align 1, !dbg !70
// CHECK:STDOUT:   %.loc17_22.41 = trunc i8 %.loc17_22.4 to i1, !dbg !70
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc17 = icmp eq i1 false, %.loc17_22.41, !dbg !70
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc17, label %match.case.then.loc17, label %match.case.else.loc17, !dbg !70
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc17_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !70
// CHECK:STDOUT:   %.loc17_22.8.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc17_22.7.payload, i32 0, i32 0, !dbg !70
// CHECK:STDOUT:   %tuple.elem0.loc17.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc17_22.8.Ok, i32 0, i32 0, !dbg !70
// CHECK:STDOUT:   %.loc17_22.9 = load i32, ptr %tuple.elem0.loc17.tuple.elem, align 4, !dbg !70
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.adf6da85a9ce6143(ptr %return, i32 %.loc17_22.9), !dbg !71
// CHECK:STDOUT:   ret void, !dbg !72
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc18_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !73
// CHECK:STDOUT:   %.loc18_23.4 = load i8, ptr %.loc18_23.3.discriminant, align 1, !dbg !73
// CHECK:STDOUT:   %.loc18_23.42 = trunc i8 %.loc18_23.4 to i1, !dbg !73
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc18 = icmp eq i1 true, %.loc18_23.42, !dbg !73
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc18, label %match.case.then.loc18, label %match.done, !dbg !73
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc18:                            ; preds = %match.case.else.loc17
// CHECK:STDOUT:   %.loc18_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !73
// CHECK:STDOUT:   %.loc18_23.8.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc18_23.7.payload, i32 0, i32 0, !dbg !73
// CHECK:STDOUT:   %tuple.elem0.loc18.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc18_23.8.Err, i32 0, i32 0, !dbg !73
// CHECK:STDOUT:   %.loc18_23.9 = load i32, ptr %tuple.elem0.loc18.tuple.elem, align 4, !dbg !73
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.adf6da85a9ce6143(ptr %return, i32 %.loc18_23.9), !dbg !74
// CHECK:STDOUT:   ret void, !dbg !75
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc17
// CHECK:STDOUT:   call void @_CDiverge.Main.e2d64f994780358e(ptr %return), !dbg !76
// CHECK:STDOUT:   ret void, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.adf6da85a9ce6143"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %e) #0 !dbg !78 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.adf6da85a9ce6143(ptr %return, i32 %e), !dbg !83
// CHECK:STDOUT:   ret void, !dbg !84
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.adf6da85a9ce6143(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !85 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !89
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !89
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !89
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !90
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.24e.anon, i64 8, i1 false), !dbg !89
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !89
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !90
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !90
// CHECK:STDOUT:   ret void, !dbg !89
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.adf6da85a9ce6143(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !91 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !94
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !94
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !94
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !94
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.8af.anon, i64 8, i1 false), !dbg !94
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !94
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !94
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !94
// CHECK:STDOUT:   ret void, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.e2d64f994780358e(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !95 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiverge.Main.e2d64f994780358e(ptr %return), !dbg !98
// CHECK:STDOUT:   ret void, !dbg !99
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.adf6da85a9ce6143(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !100 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !103
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !103
// CHECK:STDOUT:   %.loc3_35.5.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !103
// CHECK:STDOUT:   %.loc6_1.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !103
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.005.loc3_35.7, i64 8, i1 false), !dbg !103
// CHECK:STDOUT:   store { i32 } %.loc6_1.1.tuple.init, ptr %.loc3_35.5.Err, align 4, !dbg !103
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Err, i32 0, i32 0, !dbg !103
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !103
// CHECK:STDOUT:   ret void, !dbg !103
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "adapter_payload.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Tag.Main:Destroy.Core", scope: null, file: !1, line: 47, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{null, !7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{!9}
// CHECK:STDOUT: !9 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !10 = !DILocation(line: 47, column: 3, scope: !4)
// CHECK:STDOUT: !11 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:Destroy.3d376358904aedc3.Core:Tag.Main:Destroy.Core", scope: null, file: !1, line: 47, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !12)
// CHECK:STDOUT: !12 = !{!13}
// CHECK:STDOUT: !13 = !DILocalVariable(arg: 1, scope: !11, type: !7)
// CHECK:STDOUT: !14 = !DILocation(line: 0, scope: !11)
// CHECK:STDOUT: !15 = !DILocation(line: 47, column: 3, scope: !11)
// CHECK:STDOUT: !16 = distinct !DISubprogram(name: "CallAdapter", linkageName: "_CCallAdapter.Main", scope: null, file: !1, line: 55, type: !17, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !20)
// CHECK:STDOUT: !17 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !18 = !{!19, !19}
// CHECK:STDOUT: !19 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !20 = !{!21}
// CHECK:STDOUT: !21 = !DILocalVariable(arg: 1, scope: !16, type: !19)
// CHECK:STDOUT: !22 = !DILocation(line: 56, column: 10, scope: !16)
// CHECK:STDOUT: !23 = !DILocation(line: 56, column: 3, scope: !16)
// CHECK:STDOUT: !24 = distinct !DISubprogram(name: "Op", linkageName: "_COp.7512aa4144aeb8db:core.Destroy.Core", scope: null, file: !1, line: 51, type: !25, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !28)
// CHECK:STDOUT: !25 = !DISubroutineType(types: !26)
// CHECK:STDOUT: !26 = !{null, !27}
// CHECK:STDOUT: !27 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !28 = !{!29}
// CHECK:STDOUT: !29 = !DILocalVariable(arg: 1, scope: !24, type: !27)
// CHECK:STDOUT: !30 = !DILocation(line: 51, column: 34, scope: !24)
// CHECK:STDOUT: !31 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5e27612b9dd31a14:core.Destroy.Core", scope: null, file: !1, line: 51, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !32)
// CHECK:STDOUT: !32 = !{!33}
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !31, type: !7)
// CHECK:STDOUT: !34 = !DILocation(line: 51, column: 34, scope: !31)
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "Op", linkageName: "_COp.7ca742a7cec6ea43:core.Destroy.Core", scope: null, file: !1, line: 51, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !36)
// CHECK:STDOUT: !36 = !{!37}
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !35, type: !7)
// CHECK:STDOUT: !38 = !DILocation(line: 51, column: 34, scope: !35)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "Op", linkageName: "_COp.a0e51b57c8f10646:core.Destroy.Core", scope: null, file: !1, line: 51, type: !40, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !42)
// CHECK:STDOUT: !40 = !DISubroutineType(types: !41)
// CHECK:STDOUT: !41 = !{null, !19}
// CHECK:STDOUT: !42 = !{!43}
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !39, type: !19)
// CHECK:STDOUT: !44 = !DILocation(line: 51, column: 34, scope: !39)
// CHECK:STDOUT: !45 = distinct !DISubprogram(name: "Op", linkageName: "_COp.b56e66ed2f8c6490:core.Destroy.Core", scope: null, file: !1, line: 51, type: !40, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !46)
// CHECK:STDOUT: !46 = !{!47}
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !45, type: !19)
// CHECK:STDOUT: !48 = !DILocation(line: 51, column: 34, scope: !45)
// CHECK:STDOUT: !49 = distinct !DISubprogram(name: "Op", linkageName: "_COp.f9e10282de036468:core.Destroy.Core", scope: null, file: !1, line: 51, type: !40, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !50)
// CHECK:STDOUT: !50 = !{!51}
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 1, scope: !49, type: !19)
// CHECK:STDOUT: !52 = !DILocation(line: 51, column: 34, scope: !49)
// CHECK:STDOUT: !53 = distinct !DISubprogram(name: "Op", linkageName: "_COp.df1f319f5299ff91:core.Destroy.Core", scope: null, file: !1, line: 51, type: !40, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !54)
// CHECK:STDOUT: !54 = !{!55}
// CHECK:STDOUT: !55 = !DILocalVariable(arg: 1, scope: !53, type: !19)
// CHECK:STDOUT: !56 = !DILocation(line: 51, column: 34, scope: !53)
// CHECK:STDOUT: !57 = distinct !DISubprogram(name: "Op", linkageName: "_COp.f10e4bedf5f8286a:core.Destroy.Core", scope: null, file: !1, line: 51, type: !40, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !58)
// CHECK:STDOUT: !58 = !{!59}
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !57, type: !19)
// CHECK:STDOUT: !60 = !DILocation(line: 51, column: 34, scope: !57)
// CHECK:STDOUT: !61 = distinct !DISubprogram(name: "PropagateOnly", linkageName: "_CPropagateOnly.Main.20eb365082aa2002", scope: null, file: !1, line: 50, type: !17, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !62)
// CHECK:STDOUT: !62 = !{!63}
// CHECK:STDOUT: !63 = !DILocalVariable(arg: 1, scope: !61, type: !19)
// CHECK:STDOUT: !64 = !DILocation(line: 51, column: 34, scope: !61)
// CHECK:STDOUT: !65 = !DILocation(line: 52, column: 10, scope: !61)
// CHECK:STDOUT: !66 = !DILocation(line: 52, column: 3, scope: !61)
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.adf6da85a9ce6143", scope: null, file: !1, line: 15, type: !17, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !68)
// CHECK:STDOUT: !68 = !{!69}
// CHECK:STDOUT: !69 = !DILocalVariable(arg: 1, scope: !67, type: !19)
// CHECK:STDOUT: !70 = !DILocation(line: 17, column: 7, scope: !67)
// CHECK:STDOUT: !71 = !DILocation(line: 17, column: 34, scope: !67)
// CHECK:STDOUT: !72 = !DILocation(line: 17, column: 27, scope: !67)
// CHECK:STDOUT: !73 = !DILocation(line: 18, column: 7, scope: !67)
// CHECK:STDOUT: !74 = !DILocation(line: 18, column: 35, scope: !67)
// CHECK:STDOUT: !75 = !DILocation(line: 18, column: 28, scope: !67)
// CHECK:STDOUT: !76 = !DILocation(line: 22, column: 12, scope: !67)
// CHECK:STDOUT: !77 = !DILocation(line: 22, column: 5, scope: !67)
// CHECK:STDOUT: !78 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.adf6da85a9ce6143", scope: null, file: !1, line: 24, type: !79, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !81)
// CHECK:STDOUT: !79 = !DISubroutineType(types: !80)
// CHECK:STDOUT: !80 = !{!19, !7}
// CHECK:STDOUT: !81 = !{!82}
// CHECK:STDOUT: !82 = !DILocalVariable(arg: 1, scope: !78, type: !7)
// CHECK:STDOUT: !83 = !DILocation(line: 24, column: 39, scope: !78)
// CHECK:STDOUT: !84 = !DILocation(line: 24, column: 32, scope: !78)
// CHECK:STDOUT: !85 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.adf6da85a9ce6143", scope: null, file: !86, line: 21, type: !79, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !87)
// CHECK:STDOUT: !86 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !87 = !{!88}
// CHECK:STDOUT: !88 = !DILocalVariable(arg: 1, scope: !85, type: !7)
// CHECK:STDOUT: !89 = !DILocation(line: 21, column: 1, scope: !85)
// CHECK:STDOUT: !90 = !DILocation(line: 22, column: 21, scope: !85)
// CHECK:STDOUT: !91 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.adf6da85a9ce6143", scope: null, file: !86, line: 21, type: !79, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !92)
// CHECK:STDOUT: !92 = !{!93}
// CHECK:STDOUT: !93 = !DILocalVariable(arg: 1, scope: !91, type: !7)
// CHECK:STDOUT: !94 = !DILocation(line: 21, column: 1, scope: !91)
// CHECK:STDOUT: !95 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.e2d64f994780358e", scope: null, file: !1, line: 11, type: !96, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !96 = !DISubroutineType(types: !97)
// CHECK:STDOUT: !97 = !{!19}
// CHECK:STDOUT: !98 = !DILocation(line: 11, column: 45, scope: !95)
// CHECK:STDOUT: !99 = !DILocation(line: 11, column: 38, scope: !95)
// CHECK:STDOUT: !100 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.adf6da85a9ce6143", scope: null, file: !1, line: 3, type: !79, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !101)
// CHECK:STDOUT: !101 = !{!102}
// CHECK:STDOUT: !102 = !DILocalVariable(arg: 1, scope: !100, type: !7)
// CHECK:STDOUT: !103 = !DILocation(line: 3, column: 1, scope: !100)
// CHECK:STDOUT:

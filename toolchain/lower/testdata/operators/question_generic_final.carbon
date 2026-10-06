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
// CHECK:STDOUT: define void @_CCall.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %x, i1 %failA, i1 %failB) #0 !dbg !17 {
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
// CHECK:STDOUT:   %.loc40_33.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !58
// CHECK:STDOUT:   call void @"_CSelfDestruct.b63d267505e804f2:core.Destroy.Core"(ptr %.loc40_33.1.payload), !dbg !58
// CHECK:STDOUT:   %.loc40_33.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !58
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc40_33.2.discriminant), !dbg !58
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
// CHECK:STDOUT:   %.loc40_32.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !82
// CHECK:STDOUT:   call void @"_CSelfDestruct.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %.loc40_32.1.payload), !dbg !82
// CHECK:STDOUT:   %.loc40_32.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !82
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc40_32.2.discriminant), !dbg !82
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
// CHECK:STDOUT:   %.loc40_32.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !107
// CHECK:STDOUT:   %.loc40_33.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !107
// CHECK:STDOUT:   %.loc41_32.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !118
// CHECK:STDOUT:   %.loc41_33.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !118
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc40_32.1.temp), !dbg !107
// CHECK:STDOUT:   call void @_CStep.Main.84588f41d61dafba(ptr %.loc40_32.1.temp, i32 %x, i1 %failA, i32 101), !dbg !107
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc40_33.1.temp), !dbg !107
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %.loc40_33.1.temp, ptr %.loc40_32.1.temp), !dbg !107
// CHECK:STDOUT:   %.loc40_33.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc40_33.1.temp, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   %.loc40_33.6 = load i8, ptr %.loc40_33.5.discriminant, align 1, !dbg !107
// CHECK:STDOUT:   %.loc40_33.61 = trunc i8 %.loc40_33.6 to i1, !dbg !107
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc40 = icmp eq i1 true, %.loc40_33.61, !dbg !107
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc40, label %.loc40_33.1, label %.loc40_33.2, !dbg !107
// CHECK:STDOUT:
// CHECK:STDOUT: .loc40_33.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc40_33.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc40_33.1.temp, i32 0, i32 1, !dbg !107
// CHECK:STDOUT:   %.loc40_33.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc40_33.9.payload, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   %tuple.elem0.loc40_33.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc40_33.10.Break, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   %.loc40_33.11 = load i32, ptr %tuple.elem0.loc40_33.1.tuple.elem, align 4, !dbg !107
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %.loc40_33.11), !dbg !107
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc40_33.1.temp), !dbg !107
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %.loc40_32.1.temp), !dbg !107
// CHECK:STDOUT:   ret void, !dbg !107
// CHECK:STDOUT:
// CHECK:STDOUT: .loc40_33.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc40_33.15.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc40_33.1.temp, i32 0, i32 1, !dbg !107
// CHECK:STDOUT:   %.loc40_33.16.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc40_33.15.payload, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   %tuple.elem0.loc40_33.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc40_33.16.Continue, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   %.loc40_33.17 = load i32, ptr %tuple.elem0.loc40_33.2.tuple.elem, align 4, !dbg !107
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc41_32.1.temp), !dbg !118
// CHECK:STDOUT:   call void @_CStep.Main.84588f41d61dafba(ptr %.loc41_32.1.temp, i32 %.loc40_33.17, i1 %failB, i32 202), !dbg !118
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc41_33.1.temp), !dbg !118
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %.loc41_33.1.temp, ptr %.loc41_32.1.temp), !dbg !118
// CHECK:STDOUT:   %.loc41_33.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc41_33.1.temp, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %.loc41_33.6 = load i8, ptr %.loc41_33.5.discriminant, align 1, !dbg !118
// CHECK:STDOUT:   %.loc41_33.62 = trunc i8 %.loc41_33.6 to i1, !dbg !118
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc41 = icmp eq i1 true, %.loc41_33.62, !dbg !118
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc41, label %.loc41_33.1, label %.loc41_33.2, !dbg !118
// CHECK:STDOUT:
// CHECK:STDOUT: .loc41_33.1:                                      ; preds = %.loc40_33.2
// CHECK:STDOUT:   %.loc41_33.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc41_33.1.temp, i32 0, i32 1, !dbg !118
// CHECK:STDOUT:   %.loc41_33.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc41_33.9.payload, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %tuple.elem0.loc41_33.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc41_33.10.Break, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %.loc41_33.11 = load i32, ptr %tuple.elem0.loc41_33.1.tuple.elem, align 4, !dbg !118
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %.loc41_33.11), !dbg !118
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc41_33.1.temp), !dbg !118
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %.loc41_32.1.temp), !dbg !118
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc40_33.1.temp), !dbg !107
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %.loc40_32.1.temp), !dbg !107
// CHECK:STDOUT:   ret void, !dbg !118
// CHECK:STDOUT:
// CHECK:STDOUT: .loc41_33.2:                                      ; preds = %.loc40_33.2
// CHECK:STDOUT:   %.loc41_33.15.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc41_33.1.temp, i32 0, i32 1, !dbg !118
// CHECK:STDOUT:   %.loc41_33.16.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc41_33.15.payload, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %tuple.elem0.loc41_33.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc41_33.16.Continue, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %.loc41_33.17 = load i32, ptr %tuple.elem0.loc41_33.2.tuple.elem, align 4, !dbg !118
// CHECK:STDOUT:   call void @_COk.MyResult.Main.8122a03446648385(ptr %return, i32 %.loc41_33.17), !dbg !122
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc41_33.1.temp), !dbg !118
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %.loc41_32.1.temp), !dbg !118
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc40_33.1.temp), !dbg !107
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %.loc40_32.1.temp), !dbg !107
// CHECK:STDOUT:   ret void, !dbg !123
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CStep.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %x, i1 %fail, i32 %tag) #0 !dbg !125 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 %fail, label %if.then, label %if.else, !dbg !135
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %tag), !dbg !137
// CHECK:STDOUT:   ret void, !dbg !138
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_COk.MyResult.Main.8122a03446648385(ptr %return, i32 %x), !dbg !140
// CHECK:STDOUT:   ret void, !dbg !141
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !143 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc20_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !149
// CHECK:STDOUT:   %.loc20_22.4 = load i8, ptr %.loc20_22.3.discriminant, align 1, !dbg !149
// CHECK:STDOUT:   %.loc20_22.41 = trunc i8 %.loc20_22.4 to i1, !dbg !149
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc20 = icmp eq i1 false, %.loc20_22.41, !dbg !149
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc20, label %match.case.then.loc20, label %match.case.else.loc20, !dbg !149
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc20:                            ; preds = %entry
// CHECK:STDOUT:   %.loc20_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !149
// CHECK:STDOUT:   %.loc20_22.8.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc20_22.7.payload, i32 0, i32 0, !dbg !149
// CHECK:STDOUT:   %tuple.elem0.loc20.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc20_22.8.Ok, i32 0, i32 0, !dbg !149
// CHECK:STDOUT:   %.loc20_22.9 = load i32, ptr %tuple.elem0.loc20.tuple.elem, align 4, !dbg !149
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc20_22.9), !dbg !152
// CHECK:STDOUT:   ret void, !dbg !153
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc20:                            ; preds = %entry
// CHECK:STDOUT:   %.loc21_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !154
// CHECK:STDOUT:   %.loc21_23.4 = load i8, ptr %.loc21_23.3.discriminant, align 1, !dbg !154
// CHECK:STDOUT:   %.loc21_23.42 = trunc i8 %.loc21_23.4 to i1, !dbg !154
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc21 = icmp eq i1 true, %.loc21_23.42, !dbg !154
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc21, label %match.case.then.loc21, label %match.done, !dbg !154
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc21:                            ; preds = %match.case.else.loc20
// CHECK:STDOUT:   %.loc21_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !154
// CHECK:STDOUT:   %.loc21_23.8.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc21_23.7.payload, i32 0, i32 0, !dbg !154
// CHECK:STDOUT:   %tuple.elem0.loc21.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc21_23.8.Err, i32 0, i32 0, !dbg !154
// CHECK:STDOUT:   %.loc21_23.9 = load i32, ptr %tuple.elem0.loc21.tuple.elem, align 4, !dbg !154
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc21_23.9), !dbg !157
// CHECK:STDOUT:   ret void, !dbg !158
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc20
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !160
// CHECK:STDOUT:   ret void, !dbg !163
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %e) #0 !dbg !165 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %e), !dbg !171
// CHECK:STDOUT:   ret void, !dbg !172
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !174 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !176
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !176
// CHECK:STDOUT:   %.loc3_35.5.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !176
// CHECK:STDOUT:   %.loc4_11.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !177
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.30e.loc3_35.7, i64 8, i1 false), !dbg !176
// CHECK:STDOUT:   store { i32 } %.loc4_11.1.tuple.init, ptr %.loc3_35.5.Ok, align 4, !dbg !176
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Ok, i32 0, i32 0, !dbg !177
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !177
// CHECK:STDOUT:   ret void, !dbg !176
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !179 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !181
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !181
// CHECK:STDOUT:   %.loc3_35.5.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !181
// CHECK:STDOUT:   %.loc6_1.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !181
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.df1.loc3_35.7, i64 8, i1 false), !dbg !181
// CHECK:STDOUT:   store { i32 } %.loc6_1.1.tuple.init, ptr %.loc3_35.5.Err, align 4, !dbg !181
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Err, i32 0, i32 0, !dbg !181
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !181
// CHECK:STDOUT:   ret void, !dbg !181
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !184 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !186
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !186
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !186
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !187
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.f6c.anon, i64 8, i1 false), !dbg !186
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !186
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !187
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !187
// CHECK:STDOUT:   ret void, !dbg !186
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !189 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !191
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !191
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !191
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !191
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.493.anon, i64 8, i1 false), !dbg !191
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !191
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !191
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !191
// CHECK:STDOUT:   ret void, !dbg !191
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.9bba81283511934f(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !193 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !196
// CHECK:STDOUT:   ret void, !dbg !197
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "thread.carbon", directory: "")
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
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !4, line: 49, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !31)
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !17, type: !7)
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 2, scope: !17, type: !8)
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 3, scope: !17, type: !8)
// CHECK:STDOUT: !29 = !DILocation(line: 50, column: 10, scope: !17)
// CHECK:STDOUT: !30 = !DILocation(line: 50, column: 3, scope: !17)
// CHECK:STDOUT: !31 = !{!18, !19, !20}
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !4, line: 40, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !35)
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !32, type: !6)
// CHECK:STDOUT: !34 = !DILocation(line: 40, column: 14, scope: !32)
// CHECK:STDOUT: !35 = !{!33}
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 40, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !39)
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !36, type: !7)
// CHECK:STDOUT: !38 = !DILocation(line: 40, column: 14, scope: !36)
// CHECK:STDOUT: !39 = !{!37}
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 40, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !43)
// CHECK:STDOUT: !41 = !DILocalVariable(arg: 1, scope: !40, type: !8)
// CHECK:STDOUT: !42 = !DILocation(line: 40, column: 14, scope: !40)
// CHECK:STDOUT: !43 = !{!41}
// CHECK:STDOUT: !44 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 40, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !47)
// CHECK:STDOUT: !45 = !DILocalVariable(arg: 1, scope: !44, type: !8)
// CHECK:STDOUT: !46 = !DILocation(line: 40, column: 14, scope: !44)
// CHECK:STDOUT: !47 = !{!45}
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core", scope: null, file: !4, line: 40, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !51)
// CHECK:STDOUT: !49 = !DILocalVariable(arg: 1, scope: !48, type: !8)
// CHECK:STDOUT: !50 = !DILocation(line: 40, column: 14, scope: !48)
// CHECK:STDOUT: !51 = !{!49}
// CHECK:STDOUT: !52 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b63d267505e804f2:core.Destroy.Core", scope: null, file: !4, line: 40, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !55)
// CHECK:STDOUT: !53 = !DILocalVariable(arg: 1, scope: !52, type: !8)
// CHECK:STDOUT: !54 = !DILocation(line: 40, column: 14, scope: !52)
// CHECK:STDOUT: !55 = !{!53}
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.88b1683142354768:core.Destroy.Core", scope: null, file: !4, line: 40, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !59)
// CHECK:STDOUT: !57 = !DILocalVariable(arg: 1, scope: !56, type: !8)
// CHECK:STDOUT: !58 = !DILocation(line: 40, column: 14, scope: !56)
// CHECK:STDOUT: !59 = !{!57}
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.88b1683142354768:core.Destroy.Core", scope: null, file: !4, line: 40, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !63)
// CHECK:STDOUT: !61 = !DILocalVariable(arg: 1, scope: !60, type: !8)
// CHECK:STDOUT: !62 = !DILocation(line: 40, column: 14, scope: !60)
// CHECK:STDOUT: !63 = !{!61}
// CHECK:STDOUT: !64 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core", scope: null, file: !4, line: 40, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !67)
// CHECK:STDOUT: !65 = !DILocalVariable(arg: 1, scope: !64, type: !8)
// CHECK:STDOUT: !66 = !DILocation(line: 40, column: 14, scope: !64)
// CHECK:STDOUT: !67 = !{!65}
// CHECK:STDOUT: !68 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core", scope: null, file: !4, line: 40, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !71)
// CHECK:STDOUT: !69 = !DILocalVariable(arg: 1, scope: !68, type: !8)
// CHECK:STDOUT: !70 = !DILocation(line: 40, column: 14, scope: !68)
// CHECK:STDOUT: !71 = !{!69}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.bf4a066f5a5b60ea:core.Destroy.Core", scope: null, file: !4, line: 40, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !75)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !8)
// CHECK:STDOUT: !74 = !DILocation(line: 40, column: 14, scope: !72)
// CHECK:STDOUT: !75 = !{!73}
// CHECK:STDOUT: !76 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.bf4a066f5a5b60ea:core.Destroy.Core", scope: null, file: !4, line: 40, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !79)
// CHECK:STDOUT: !77 = !DILocalVariable(arg: 1, scope: !76, type: !8)
// CHECK:STDOUT: !78 = !DILocation(line: 40, column: 14, scope: !76)
// CHECK:STDOUT: !79 = !{!77}
// CHECK:STDOUT: !80 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.f269577697e84b3c:core.Destroy.Core", scope: null, file: !4, line: 40, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !83)
// CHECK:STDOUT: !81 = !DILocalVariable(arg: 1, scope: !80, type: !8)
// CHECK:STDOUT: !82 = !DILocation(line: 40, column: 14, scope: !80)
// CHECK:STDOUT: !83 = !{!81}
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f269577697e84b3c:core.Destroy.Core", scope: null, file: !4, line: 40, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !87)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !84, type: !8)
// CHECK:STDOUT: !86 = !DILocation(line: 40, column: 14, scope: !84)
// CHECK:STDOUT: !87 = !{!85}
// CHECK:STDOUT: !88 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.21e9b6df7c6352ff:core.Destroy.Core", scope: null, file: !4, line: 40, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !91)
// CHECK:STDOUT: !89 = !DILocalVariable(arg: 1, scope: !88, type: !8)
// CHECK:STDOUT: !90 = !DILocation(line: 40, column: 14, scope: !88)
// CHECK:STDOUT: !91 = !{!89}
// CHECK:STDOUT: !92 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core", scope: null, file: !4, line: 40, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !95)
// CHECK:STDOUT: !93 = !DILocalVariable(arg: 1, scope: !92, type: !8)
// CHECK:STDOUT: !94 = !DILocation(line: 40, column: 14, scope: !92)
// CHECK:STDOUT: !95 = !{!93}
// CHECK:STDOUT: !96 = distinct !DISubprogram(name: "Chain", linkageName: "_CChain.Main.84588f41d61dafba", scope: null, file: !4, line: 39, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !124)
// CHECK:STDOUT: !97 = !DILocalVariable(arg: 1, scope: !96, type: !7)
// CHECK:STDOUT: !98 = !DILocalVariable(arg: 2, scope: !96, type: !8)
// CHECK:STDOUT: !99 = !DILocalVariable(arg: 3, scope: !96, type: !8)
// CHECK:STDOUT: !107 = !DILocation(line: 40, column: 14, scope: !96)
// CHECK:STDOUT: !108 = !{!8, !7, !8, !7}
// CHECK:STDOUT: !109 = !DISubroutineType(types: !108)
// CHECK:STDOUT: !110 = !{!8, !8}
// CHECK:STDOUT: !111 = !DISubroutineType(types: !110)
// CHECK:STDOUT: !112 = !{!8, !7}
// CHECK:STDOUT: !113 = !DISubroutineType(types: !112)
// CHECK:STDOUT: !118 = !DILocation(line: 41, column: 14, scope: !96)
// CHECK:STDOUT: !122 = !DILocation(line: 42, column: 10, scope: !96)
// CHECK:STDOUT: !123 = !DILocation(line: 42, column: 3, scope: !96)
// CHECK:STDOUT: !124 = !{!97, !98, !99}
// CHECK:STDOUT: !125 = distinct !DISubprogram(name: "Step", linkageName: "_CStep.Main.84588f41d61dafba", scope: null, file: !4, line: 30, type: !109, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !142)
// CHECK:STDOUT: !126 = !DILocalVariable(arg: 1, scope: !125, type: !7)
// CHECK:STDOUT: !127 = !DILocalVariable(arg: 2, scope: !125, type: !8)
// CHECK:STDOUT: !128 = !DILocalVariable(arg: 3, scope: !125, type: !7)
// CHECK:STDOUT: !135 = !DILocation(line: 31, column: 6, scope: !125)
// CHECK:STDOUT: !137 = !DILocation(line: 31, column: 22, scope: !125)
// CHECK:STDOUT: !138 = !DILocation(line: 31, column: 15, scope: !125)
// CHECK:STDOUT: !140 = !DILocation(line: 32, column: 10, scope: !125)
// CHECK:STDOUT: !141 = !DILocation(line: 32, column: 3, scope: !125)
// CHECK:STDOUT: !142 = !{!126, !127, !128}
// CHECK:STDOUT: !143 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !4, line: 18, type: !111, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !164)
// CHECK:STDOUT: !144 = !DILocalVariable(arg: 1, scope: !143, type: !8)
// CHECK:STDOUT: !149 = !DILocation(line: 20, column: 7, scope: !143)
// CHECK:STDOUT: !152 = !DILocation(line: 20, column: 34, scope: !143)
// CHECK:STDOUT: !153 = !DILocation(line: 20, column: 27, scope: !143)
// CHECK:STDOUT: !154 = !DILocation(line: 21, column: 7, scope: !143)
// CHECK:STDOUT: !157 = !DILocation(line: 21, column: 35, scope: !143)
// CHECK:STDOUT: !158 = !DILocation(line: 21, column: 28, scope: !143)
// CHECK:STDOUT: !160 = !DILocation(line: 24, column: 12, scope: !143)
// CHECK:STDOUT: !161 = !{!8}
// CHECK:STDOUT: !162 = !DISubroutineType(types: !161)
// CHECK:STDOUT: !163 = !DILocation(line: 24, column: 5, scope: !143)
// CHECK:STDOUT: !164 = !{!144}
// CHECK:STDOUT: !165 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !4, line: 26, type: !113, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !173)
// CHECK:STDOUT: !166 = !DILocalVariable(arg: 1, scope: !165, type: !7)
// CHECK:STDOUT: !171 = !DILocation(line: 26, column: 39, scope: !165)
// CHECK:STDOUT: !172 = !DILocation(line: 26, column: 32, scope: !165)
// CHECK:STDOUT: !173 = !{!166}
// CHECK:STDOUT: !174 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.MyResult.Main.8122a03446648385", scope: null, file: !4, line: 3, type: !113, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !178)
// CHECK:STDOUT: !175 = !DILocalVariable(arg: 1, scope: !174, type: !7)
// CHECK:STDOUT: !176 = !DILocation(line: 3, column: 1, scope: !174)
// CHECK:STDOUT: !177 = !DILocation(line: 4, column: 11, scope: !174)
// CHECK:STDOUT: !178 = !{!175}
// CHECK:STDOUT: !179 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.8122a03446648385", scope: null, file: !4, line: 3, type: !113, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !182)
// CHECK:STDOUT: !180 = !DILocalVariable(arg: 1, scope: !179, type: !7)
// CHECK:STDOUT: !181 = !DILocation(line: 3, column: 1, scope: !179)
// CHECK:STDOUT: !182 = !{!180}
// CHECK:STDOUT: !183 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !184 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.8122a03446648385", scope: null, file: !183, line: 21, type: !113, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !188)
// CHECK:STDOUT: !185 = !DILocalVariable(arg: 1, scope: !184, type: !7)
// CHECK:STDOUT: !186 = !DILocation(line: 21, column: 1, scope: !184)
// CHECK:STDOUT: !187 = !DILocation(line: 22, column: 21, scope: !184)
// CHECK:STDOUT: !188 = !{!185}
// CHECK:STDOUT: !189 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.8122a03446648385", scope: null, file: !183, line: 21, type: !113, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !192)
// CHECK:STDOUT: !190 = !DILocalVariable(arg: 1, scope: !189, type: !7)
// CHECK:STDOUT: !191 = !DILocation(line: 21, column: 1, scope: !189)
// CHECK:STDOUT: !192 = !{!190}
// CHECK:STDOUT: !193 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.9bba81283511934f", scope: null, file: !4, line: 11, type: !162, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !196 = !DILocation(line: 11, column: 45, scope: !193)
// CHECK:STDOUT: !197 = !DILocation(line: 11, column: 38, scope: !193)
// CHECK:STDOUT:

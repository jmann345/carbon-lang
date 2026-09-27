// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/operators/question.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/operators/question.carbon

// The postfix `?` desugar's CFG, lowered (fork/b1/plan.md §3 B1b): a Branch
// call materializing the `Core.ControlFlow` carrier, the discriminant load
// and compare against `Break`'s discriminant (1, fixed by the prelude's
// alternative order), a conditional branch, the break path's payload load +
// `FromBreak` call + early `ret` through the return slot, and the continue
// path's payload load as the expression's value. No new inst kinds lower
// here — branch/return/call/element-access only — and NO copy or memcpy
// exists on the propagation path beyond the in-place return-slot init (the
// §2.6 no-copy trace, risk R-5's falsifier). `Basic` and `Wide` must
// resolve DISTINCT `ControlFlow` specifics — `ControlFlow(i32, i32)` and
// `ControlFlow(i64, i32)` — with their own payload region layouts (risk
// R-3).

// --- propagate.carbon
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

fn Open(n: i32) -> MyResult(i32, i32) {
  if (n > 0) { return MyResult(i32, i32).Ok(n); }
  return MyResult(i32, i32).Err(n);
}

fn Wide(n: i64) -> MyResult(i64, i32) {
  if (n > 0) { return MyResult(i64, i32).Ok(n); }
  return MyResult(i64, i32).Err(0);
}

fn Basic(n: i32) -> MyResult(i32, i32) {
  var f: i32 = Open(n)?;
  return MyResult(i32, i32).Ok(f + 1);
}

fn Both(n: i32, m: i64) -> MyResult(i64, i32) {
  var x: i32 = Open(n)?;
  var y: i64 = Wide(m)?;
  return MyResult(i64, i32).Ok(y + (x as i64));
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'propagate.carbon'
// CHECK:STDOUT: source_filename = "propagate.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @MyResult.val.30e.loc3_35.7 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @MyResult.val.df1.loc3_35.7 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @MyResult.val.9f4.loc3_35.7 = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> zeroinitializer
// CHECK:STDOUT: @MyResult.val.142.loc3_35.7 = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @ControlFlow.val.f6c.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @ControlFlow.val.493.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @ControlFlow.val.fa9.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> zeroinitializer
// CHECK:STDOUT: @ControlFlow.val.d01.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_COpen.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call = icmp sgt i32 %n, 0, !dbg !11
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Greater.call, label %if.then, label %if.else, !dbg !12
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_COk.MyResult.Main.8122a03446648385(ptr %return, i32 %n), !dbg !13
// CHECK:STDOUT:   ret void, !dbg !14
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %n), !dbg !15
// CHECK:STDOUT:   ret void, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CWide.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %n) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call = icmp sgt i64 %n, 0, !dbg !23
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Greater.call, label %if.then, label %if.else, !dbg !24
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_COk.MyResult.Main.b7dd877894074427(ptr %return, i64 %n), !dbg !25
// CHECK:STDOUT:   ret void, !dbg !26
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.b7dd877894074427(ptr %return, i32 0), !dbg !27
// CHECK:STDOUT:   ret void, !dbg !28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CBasic.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !29 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %f.var = alloca i32, align 4, !dbg !32
// CHECK:STDOUT:   %.loc44_22.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !33
// CHECK:STDOUT:   %.loc44_23.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !33
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %f.var), !dbg !32
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc44_22.1.temp), !dbg !33
// CHECK:STDOUT:   call void @_COpen.Main(ptr %.loc44_22.1.temp, i32 %n), !dbg !33
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc44_23.1.temp), !dbg !33
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %.loc44_23.1.temp, ptr %.loc44_22.1.temp), !dbg !33
// CHECK:STDOUT:   %.loc44_23.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc44_23.1.temp, i32 0, i32 0, !dbg !33
// CHECK:STDOUT:   %.loc44_23.6 = load i8, ptr %.loc44_23.5.discriminant, align 1, !dbg !33
// CHECK:STDOUT:   %.loc44_23.61 = trunc i8 %.loc44_23.6 to i1, !dbg !33
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc44_23.61, !dbg !33
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc44_23.1, label %.loc44_23.2, !dbg !33
// CHECK:STDOUT:
// CHECK:STDOUT: .loc44_23.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc44_23.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc44_23.1.temp, i32 0, i32 1, !dbg !33
// CHECK:STDOUT:   %.loc44_23.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc44_23.9.payload, i32 0, i32 0, !dbg !33
// CHECK:STDOUT:   %tuple.elem0.loc44_23.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc44_23.10.Break, i32 0, i32 0, !dbg !33
// CHECK:STDOUT:   %.loc44_23.11 = load i32, ptr %tuple.elem0.loc44_23.1.tuple.elem, align 4, !dbg !33
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %.loc44_23.11), !dbg !33
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc44_23.1.temp), !dbg !33
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %.loc44_22.1.temp), !dbg !33
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %f.var), !dbg !32
// CHECK:STDOUT:   ret void, !dbg !33
// CHECK:STDOUT:
// CHECK:STDOUT: .loc44_23.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc44_23.13.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc44_23.1.temp, i32 0, i32 1, !dbg !33
// CHECK:STDOUT:   %.loc44_23.14.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc44_23.13.payload, i32 0, i32 0, !dbg !33
// CHECK:STDOUT:   %tuple.elem0.loc44_23.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc44_23.14.Continue, i32 0, i32 0, !dbg !33
// CHECK:STDOUT:   %.loc44_23.15 = load i32, ptr %tuple.elem0.loc44_23.2.tuple.elem, align 4, !dbg !33
// CHECK:STDOUT:   store i32 %.loc44_23.15, ptr %f.var, align 4, !dbg !32
// CHECK:STDOUT:   %.loc45_32 = load i32, ptr %f.var, align 4, !dbg !34
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc45_32, 1, !dbg !34
// CHECK:STDOUT:   call void @_COk.MyResult.Main.8122a03446648385(ptr %return, i32 %Int.as.AddWith.impl.Op.call), !dbg !35
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc44_23.1.temp), !dbg !33
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %.loc44_22.1.temp), !dbg !33
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %f.var), !dbg !32
// CHECK:STDOUT:   ret void, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.945345cbed56cb88:core.Destroy.Core"(ptr %self) #0 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !44 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.216a6481b641f07b:core.Destroy.Core"(ptr %self) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.39976c684c12c16f:core.Destroy.Core"(ptr %self) #0 !dbg !56 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.6f70ad92790b7b3d:core.Destroy.Core"(ptr %self) #0 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !63
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %self) #0 !dbg !64 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !67
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5716d9c282b70019:core.Destroy.Core"(ptr %self) #0 !dbg !68 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !71
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.c9ead255f32e7c59:core.Destroy.Core"(ptr %self) #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !75
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.a214566110020819:core.Destroy.Core"(ptr %self) #0 !dbg !76 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !79
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CBoth.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %n, i64 %m) #0 !dbg !80 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.var = alloca i32, align 4, !dbg !86
// CHECK:STDOUT:   %.loc49_22.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !87
// CHECK:STDOUT:   %.loc49_23.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !87
// CHECK:STDOUT:   %y.var = alloca i64, align 8, !dbg !88
// CHECK:STDOUT:   %.loc50_22.1.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !89
// CHECK:STDOUT:   %.loc50_23.1.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !89
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %x.var), !dbg !86
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc49_22.1.temp), !dbg !87
// CHECK:STDOUT:   call void @_COpen.Main(ptr %.loc49_22.1.temp, i32 %n), !dbg !87
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc49_23.1.temp), !dbg !87
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %.loc49_23.1.temp, ptr %.loc49_22.1.temp), !dbg !87
// CHECK:STDOUT:   %.loc49_23.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc49_23.1.temp, i32 0, i32 0, !dbg !87
// CHECK:STDOUT:   %.loc49_23.6 = load i8, ptr %.loc49_23.5.discriminant, align 1, !dbg !87
// CHECK:STDOUT:   %.loc49_23.61 = trunc i8 %.loc49_23.6 to i1, !dbg !87
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc49 = icmp eq i1 true, %.loc49_23.61, !dbg !87
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc49, label %.loc49_23.1, label %.loc49_23.2, !dbg !87
// CHECK:STDOUT:
// CHECK:STDOUT: .loc49_23.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc49_23.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc49_23.1.temp, i32 0, i32 1, !dbg !87
// CHECK:STDOUT:   %.loc49_23.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc49_23.9.payload, i32 0, i32 0, !dbg !87
// CHECK:STDOUT:   %tuple.elem0.loc49_23.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc49_23.10.Break, i32 0, i32 0, !dbg !87
// CHECK:STDOUT:   %.loc49_23.11 = load i32, ptr %tuple.elem0.loc49_23.1.tuple.elem, align 4, !dbg !87
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %return, i32 %.loc49_23.11), !dbg !87
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc49_23.1.temp), !dbg !87
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %.loc49_22.1.temp), !dbg !87
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %x.var), !dbg !86
// CHECK:STDOUT:   ret void, !dbg !87
// CHECK:STDOUT:
// CHECK:STDOUT: .loc49_23.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc49_23.13.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc49_23.1.temp, i32 0, i32 1, !dbg !87
// CHECK:STDOUT:   %.loc49_23.14.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc49_23.13.payload, i32 0, i32 0, !dbg !87
// CHECK:STDOUT:   %tuple.elem0.loc49_23.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc49_23.14.Continue, i32 0, i32 0, !dbg !87
// CHECK:STDOUT:   %.loc49_23.15 = load i32, ptr %tuple.elem0.loc49_23.2.tuple.elem, align 4, !dbg !87
// CHECK:STDOUT:   store i32 %.loc49_23.15, ptr %x.var, align 4, !dbg !86
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %y.var), !dbg !88
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc50_22.1.temp), !dbg !89
// CHECK:STDOUT:   call void @_CWide.Main(ptr %.loc50_22.1.temp, i64 %m), !dbg !89
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc50_23.1.temp), !dbg !89
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %.loc50_23.1.temp, ptr %.loc50_22.1.temp), !dbg !89
// CHECK:STDOUT:   %.loc50_23.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc50_23.1.temp, i32 0, i32 0, !dbg !89
// CHECK:STDOUT:   %.loc50_23.6 = load i8, ptr %.loc50_23.5.discriminant, align 1, !dbg !89
// CHECK:STDOUT:   %.loc50_23.62 = trunc i8 %.loc50_23.6 to i1, !dbg !89
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc50 = icmp eq i1 true, %.loc50_23.62, !dbg !89
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc50, label %.loc50_23.1, label %.loc50_23.2, !dbg !89
// CHECK:STDOUT:
// CHECK:STDOUT: .loc50_23.1:                                      ; preds = %.loc49_23.2
// CHECK:STDOUT:   %.loc50_23.9.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc50_23.1.temp, i32 0, i32 1, !dbg !89
// CHECK:STDOUT:   %.loc50_23.10.Break = getelementptr inbounds nuw [8 x i8], ptr %.loc50_23.9.payload, i32 0, i32 0, !dbg !89
// CHECK:STDOUT:   %tuple.elem0.loc50_23.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc50_23.10.Break, i32 0, i32 0, !dbg !89
// CHECK:STDOUT:   %.loc50_23.11 = load i32, ptr %tuple.elem0.loc50_23.1.tuple.elem, align 4, !dbg !89
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %return, i32 %.loc50_23.11), !dbg !89
// CHECK:STDOUT:   call void @"_COp.e292046f58666a75:core.Destroy.Core"(ptr %.loc50_23.1.temp), !dbg !89
// CHECK:STDOUT:   call void @"_COp.bea179675fd68487:core.Destroy.Core"(ptr %.loc50_22.1.temp), !dbg !89
// CHECK:STDOUT:   call void @"_COp.5f42013854821c52:core.Destroy.Core"(ptr %y.var), !dbg !88
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc49_23.1.temp), !dbg !87
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %.loc49_22.1.temp), !dbg !87
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %x.var), !dbg !86
// CHECK:STDOUT:   ret void, !dbg !89
// CHECK:STDOUT:
// CHECK:STDOUT: .loc50_23.2:                                      ; preds = %.loc49_23.2
// CHECK:STDOUT:   %.loc50_23.13.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc50_23.1.temp, i32 0, i32 1, !dbg !89
// CHECK:STDOUT:   %.loc50_23.14.Continue = getelementptr inbounds nuw [8 x i8], ptr %.loc50_23.13.payload, i32 0, i32 0, !dbg !89
// CHECK:STDOUT:   %tuple.elem0.loc50_23.2.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc50_23.14.Continue, i32 0, i32 0, !dbg !89
// CHECK:STDOUT:   %.loc50_23.15 = load i64, ptr %tuple.elem0.loc50_23.2.tuple.elem, align 8, !dbg !89
// CHECK:STDOUT:   store i64 %.loc50_23.15, ptr %y.var, align 8, !dbg !88
// CHECK:STDOUT:   %.loc51_37 = load i32, ptr %x.var, align 4, !dbg !90
// CHECK:STDOUT:   %Int.as.As.impl.Convert.call = sext i32 %.loc51_37 to i64, !dbg !90
// CHECK:STDOUT:   %.loc51_32 = load i64, ptr %y.var, align 8, !dbg !91
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i64 %.loc51_32, %Int.as.As.impl.Convert.call, !dbg !91
// CHECK:STDOUT:   call void @_COk.MyResult.Main.b7dd877894074427(ptr %return, i64 %Int.as.AddWith.impl.Op.call), !dbg !92
// CHECK:STDOUT:   call void @"_COp.e292046f58666a75:core.Destroy.Core"(ptr %.loc50_23.1.temp), !dbg !89
// CHECK:STDOUT:   call void @"_COp.bea179675fd68487:core.Destroy.Core"(ptr %.loc50_22.1.temp), !dbg !89
// CHECK:STDOUT:   call void @"_COp.5f42013854821c52:core.Destroy.Core"(ptr %y.var), !dbg !88
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc49_23.1.temp), !dbg !87
// CHECK:STDOUT:   call void @"_COp.a214566110020819:core.Destroy.Core"(ptr %.loc49_22.1.temp), !dbg !87
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %x.var), !dbg !86
// CHECK:STDOUT:   ret void, !dbg !93
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5f42013854821c52:core.Destroy.Core"(ptr %self) #0 !dbg !94 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !99
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.62437d0fc7766a41:core.Destroy.Core"(ptr %self) #0 !dbg !100 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !103
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.4a128e99f244da38:core.Destroy.Core"(ptr %self) #0 !dbg !104 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !107
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.37ea992d2bcf2c08:core.Destroy.Core"(ptr %self) #0 !dbg !108 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !111
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.e292046f58666a75:core.Destroy.Core"(ptr %self) #0 !dbg !112 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !115
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.c41c2132e4b94059:core.Destroy.Core"(ptr %self) #0 !dbg !116 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !119
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.4b7b55811680dccf:core.Destroy.Core"(ptr %self) #0 !dbg !120 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !123
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.bea179675fd68487:core.Destroy.Core"(ptr %self) #0 !dbg !124 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !127
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !128 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !131
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !131
// CHECK:STDOUT:   %.loc3_35.5.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !131
// CHECK:STDOUT:   %.loc4_11.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !132
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.30e.loc3_35.7, i64 8, i1 false), !dbg !131
// CHECK:STDOUT:   store { i32 } %.loc4_11.1.tuple.init, ptr %.loc3_35.5.Ok, align 4, !dbg !131
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Ok, i32 0, i32 0, !dbg !132
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !132
// CHECK:STDOUT:   ret void, !dbg !131
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !133 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !136
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !136
// CHECK:STDOUT:   %.loc3_35.5.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !136
// CHECK:STDOUT:   %.loc6_1.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !136
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.df1.loc3_35.7, i64 8, i1 false), !dbg !136
// CHECK:STDOUT:   store { i32 } %.loc6_1.1.tuple.init, ptr %.loc3_35.5.Err, align 4, !dbg !136
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Err, i32 0, i32 0, !dbg !136
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !136
// CHECK:STDOUT:   ret void, !dbg !136
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.MyResult.Main.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %_) #0 !dbg !137 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !140
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !140
// CHECK:STDOUT:   %.loc3_35.5.Ok = getelementptr inbounds nuw [8 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !140
// CHECK:STDOUT:   %.loc4_11.1.tuple.init = insertvalue { i64 } poison, i64 %_, 0, !dbg !141
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @MyResult.val.9f4.loc3_35.7, i64 16, i1 false), !dbg !140
// CHECK:STDOUT:   store { i64 } %.loc4_11.1.tuple.init, ptr %.loc3_35.5.Ok, align 8, !dbg !140
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc3_35.5.Ok, i32 0, i32 0, !dbg !141
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem0.tuple.elem, align 8, !dbg !141
// CHECK:STDOUT:   ret void, !dbg !140
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !142 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !145
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !145
// CHECK:STDOUT:   %.loc3_35.5.Err = getelementptr inbounds nuw [8 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !145
// CHECK:STDOUT:   %.loc6_1.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !145
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @MyResult.val.142.loc3_35.7, i64 16, i1 false), !dbg !145
// CHECK:STDOUT:   store { i32 } %.loc6_1.1.tuple.init, ptr %.loc3_35.5.Err, align 4, !dbg !145
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Err, i32 0, i32 0, !dbg !145
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !145
// CHECK:STDOUT:   ret void, !dbg !145
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !146 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !151
// CHECK:STDOUT:   %.loc19_22.4 = load i8, ptr %.loc19_22.3.discriminant, align 1, !dbg !151
// CHECK:STDOUT:   %.loc19_22.41 = trunc i8 %.loc19_22.4 to i1, !dbg !151
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc19 = icmp eq i1 false, %.loc19_22.41, !dbg !151
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc19, label %match.case.then.loc19, label %match.case.else.loc19, !dbg !151
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc19:                            ; preds = %entry
// CHECK:STDOUT:   %.loc19_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !151
// CHECK:STDOUT:   %.loc19_22.8.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc19_22.7.payload, i32 0, i32 0, !dbg !151
// CHECK:STDOUT:   %tuple.elem0.loc19.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc19_22.8.Ok, i32 0, i32 0, !dbg !151
// CHECK:STDOUT:   %.loc19_22.9 = load i32, ptr %tuple.elem0.loc19.tuple.elem, align 4, !dbg !151
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc19_22.9), !dbg !152
// CHECK:STDOUT:   ret void, !dbg !153
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc19:                            ; preds = %entry
// CHECK:STDOUT:   %.loc20_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !154
// CHECK:STDOUT:   %.loc20_23.4 = load i8, ptr %.loc20_23.3.discriminant, align 1, !dbg !154
// CHECK:STDOUT:   %.loc20_23.42 = trunc i8 %.loc20_23.4 to i1, !dbg !154
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc20 = icmp eq i1 true, %.loc20_23.42, !dbg !154
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc20, label %match.case.then.loc20, label %match.done, !dbg !154
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc20:                            ; preds = %match.case.else.loc19
// CHECK:STDOUT:   %.loc20_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !154
// CHECK:STDOUT:   %.loc20_23.8.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc20_23.7.payload, i32 0, i32 0, !dbg !154
// CHECK:STDOUT:   %tuple.elem0.loc20.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc20_23.8.Err, i32 0, i32 0, !dbg !154
// CHECK:STDOUT:   %.loc20_23.9 = load i32, ptr %tuple.elem0.loc20.tuple.elem, align 4, !dbg !154
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc20_23.9), !dbg !155
// CHECK:STDOUT:   ret void, !dbg !156
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc19
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !157
// CHECK:STDOUT:   ret void, !dbg !158
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %e) #0 !dbg !159 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %e), !dbg !162
// CHECK:STDOUT:   ret void, !dbg !163
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %e) #0 !dbg !164 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.b7dd877894074427(ptr %return, i32 %e), !dbg !167
// CHECK:STDOUT:   ret void, !dbg !168
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %self) #0 !dbg !169 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !172
// CHECK:STDOUT:   %.loc19_22.4 = load i8, ptr %.loc19_22.3.discriminant, align 1, !dbg !172
// CHECK:STDOUT:   %.loc19_22.41 = trunc i8 %.loc19_22.4 to i1, !dbg !172
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc19 = icmp eq i1 false, %.loc19_22.41, !dbg !172
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc19, label %match.case.then.loc19, label %match.case.else.loc19, !dbg !172
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc19:                            ; preds = %entry
// CHECK:STDOUT:   %.loc19_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !172
// CHECK:STDOUT:   %.loc19_22.8.Ok = getelementptr inbounds nuw [8 x i8], ptr %.loc19_22.7.payload, i32 0, i32 0, !dbg !172
// CHECK:STDOUT:   %tuple.elem0.loc19.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc19_22.8.Ok, i32 0, i32 0, !dbg !172
// CHECK:STDOUT:   %.loc19_22.9 = load i64, ptr %tuple.elem0.loc19.tuple.elem, align 8, !dbg !172
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.b7dd877894074427(ptr %return, i64 %.loc19_22.9), !dbg !173
// CHECK:STDOUT:   ret void, !dbg !174
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc19:                            ; preds = %entry
// CHECK:STDOUT:   %.loc20_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !175
// CHECK:STDOUT:   %.loc20_23.4 = load i8, ptr %.loc20_23.3.discriminant, align 1, !dbg !175
// CHECK:STDOUT:   %.loc20_23.42 = trunc i8 %.loc20_23.4 to i1, !dbg !175
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc20 = icmp eq i1 true, %.loc20_23.42, !dbg !175
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc20, label %match.case.then.loc20, label %match.done, !dbg !175
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc20:                            ; preds = %match.case.else.loc19
// CHECK:STDOUT:   %.loc20_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !175
// CHECK:STDOUT:   %.loc20_23.8.Err = getelementptr inbounds nuw [8 x i8], ptr %.loc20_23.7.payload, i32 0, i32 0, !dbg !175
// CHECK:STDOUT:   %tuple.elem0.loc20.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc20_23.8.Err, i32 0, i32 0, !dbg !175
// CHECK:STDOUT:   %.loc20_23.9 = load i32, ptr %tuple.elem0.loc20.tuple.elem, align 4, !dbg !175
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.b7dd877894074427(ptr %return, i32 %.loc20_23.9), !dbg !176
// CHECK:STDOUT:   ret void, !dbg !177
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc19
// CHECK:STDOUT:   call void @_CDiverge.Main.fc3567e4618671b9(ptr %return), !dbg !178
// CHECK:STDOUT:   ret void, !dbg !179
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !180 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !184
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !184
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !184
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !185
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.f6c.anon, i64 8, i1 false), !dbg !184
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !184
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !185
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !185
// CHECK:STDOUT:   ret void, !dbg !184
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !186 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !189
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !189
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !189
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !189
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.493.anon, i64 8, i1 false), !dbg !189
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !189
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !189
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !189
// CHECK:STDOUT:   ret void, !dbg !189
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.9bba81283511934f(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !190 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !193
// CHECK:STDOUT:   ret void, !dbg !194
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %_) #0 !dbg !195 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !198
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !198
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !198
// CHECK:STDOUT:   %tuple.init = insertvalue { i64 } poison, i64 %_, 0, !dbg !199
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.fa9.anon, i64 16, i1 false), !dbg !198
// CHECK:STDOUT:   store { i64 } %tuple.init, ptr %Continue, align 8, !dbg !198
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i64 }, ptr %Continue, i32 0, i32 0, !dbg !199
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem, align 8, !dbg !199
// CHECK:STDOUT:   ret void, !dbg !198
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !200 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !203
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !203
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !203
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !203
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.d01.anon, i64 16, i1 false), !dbg !203
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !203
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !203
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !203
// CHECK:STDOUT:   ret void, !dbg !203
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.fc3567e4618671b9(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return) #0 !dbg !204 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiverge.Main.fc3567e4618671b9(ptr %return), !dbg !205
// CHECK:STDOUT:   ret void, !dbg !206
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_COp.70db2d92ffddbef7:core.Destroy.Core", { 0, 1, 2, 4, 3 }
// CHECK:STDOUT: uselistorder ptr @"_COp.51939fc15d8db062:core.Destroy.Core", { 0, 1, 2, 4, 3 }
// CHECK:STDOUT: uselistorder ptr @"_COp.a214566110020819:core.Destroy.Core", { 0, 1, 2, 4, 3 }
// CHECK:STDOUT: uselistorder ptr @"_COp.5f42013854821c52:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_COp.e292046f58666a75:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_COp.bea179675fd68487:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_COk.MyResult.Main.8122a03446648385, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_COk.MyResult.Main.b7dd877894074427, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 8, 7, 6, 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 0, 1, 2, 3, 7, 6, 5, 4 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "propagate.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Open", linkageName: "_COpen.Main", scope: null, file: !1, line: 33, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 34, column: 7, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 34, column: 6, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 34, column: 23, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 34, column: 16, scope: !4)
// CHECK:STDOUT: !15 = !DILocation(line: 35, column: 10, scope: !4)
// CHECK:STDOUT: !16 = !DILocation(line: 35, column: 3, scope: !4)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "Wide", linkageName: "_CWide.Main", scope: null, file: !1, line: 38, type: !18, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !21)
// CHECK:STDOUT: !18 = !DISubroutineType(types: !19)
// CHECK:STDOUT: !19 = !{!7, !20}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!22}
// CHECK:STDOUT: !22 = !DILocalVariable(arg: 1, scope: !17, type: !20)
// CHECK:STDOUT: !23 = !DILocation(line: 39, column: 7, scope: !17)
// CHECK:STDOUT: !24 = !DILocation(line: 39, column: 6, scope: !17)
// CHECK:STDOUT: !25 = !DILocation(line: 39, column: 23, scope: !17)
// CHECK:STDOUT: !26 = !DILocation(line: 39, column: 16, scope: !17)
// CHECK:STDOUT: !27 = !DILocation(line: 40, column: 10, scope: !17)
// CHECK:STDOUT: !28 = !DILocation(line: 40, column: 3, scope: !17)
// CHECK:STDOUT: !29 = distinct !DISubprogram(name: "Basic", linkageName: "_CBasic.Main", scope: null, file: !1, line: 43, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !30)
// CHECK:STDOUT: !30 = !{!31}
// CHECK:STDOUT: !31 = !DILocalVariable(arg: 1, scope: !29, type: !8)
// CHECK:STDOUT: !32 = !DILocation(line: 44, column: 3, scope: !29)
// CHECK:STDOUT: !33 = !DILocation(line: 44, column: 16, scope: !29)
// CHECK:STDOUT: !34 = !DILocation(line: 45, column: 32, scope: !29)
// CHECK:STDOUT: !35 = !DILocation(line: 45, column: 10, scope: !29)
// CHECK:STDOUT: !36 = !DILocation(line: 45, column: 3, scope: !29)
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "Op", linkageName: "_COp.945345cbed56cb88:core.Destroy.Core", scope: null, file: !1, line: 44, type: !38, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !41)
// CHECK:STDOUT: !38 = !DISubroutineType(types: !39)
// CHECK:STDOUT: !39 = !{null, !40}
// CHECK:STDOUT: !40 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !41 = !{!42}
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !37, type: !40)
// CHECK:STDOUT: !43 = !DILocation(line: 44, column: 16, scope: !37)
// CHECK:STDOUT: !44 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 44, type: !45, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !47)
// CHECK:STDOUT: !45 = !DISubroutineType(types: !46)
// CHECK:STDOUT: !46 = !{null, !8}
// CHECK:STDOUT: !47 = !{!48}
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !44, type: !8)
// CHECK:STDOUT: !49 = !DILocation(line: 44, column: 16, scope: !44)
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "Op", linkageName: "_COp.216a6481b641f07b:core.Destroy.Core", scope: null, file: !1, line: 44, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !53)
// CHECK:STDOUT: !51 = !DISubroutineType(types: !52)
// CHECK:STDOUT: !52 = !{null, !7}
// CHECK:STDOUT: !53 = !{!54}
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !50, type: !7)
// CHECK:STDOUT: !55 = !DILocation(line: 44, column: 16, scope: !50)
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "Op", linkageName: "_COp.39976c684c12c16f:core.Destroy.Core", scope: null, file: !1, line: 44, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !57)
// CHECK:STDOUT: !57 = !{!58}
// CHECK:STDOUT: !58 = !DILocalVariable(arg: 1, scope: !56, type: !7)
// CHECK:STDOUT: !59 = !DILocation(line: 44, column: 16, scope: !56)
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "Op", linkageName: "_COp.6f70ad92790b7b3d:core.Destroy.Core", scope: null, file: !1, line: 44, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !61)
// CHECK:STDOUT: !61 = !{!62}
// CHECK:STDOUT: !62 = !DILocalVariable(arg: 1, scope: !60, type: !7)
// CHECK:STDOUT: !63 = !DILocation(line: 44, column: 16, scope: !60)
// CHECK:STDOUT: !64 = distinct !DISubprogram(name: "Op", linkageName: "_COp.51939fc15d8db062:core.Destroy.Core", scope: null, file: !1, line: 44, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !65)
// CHECK:STDOUT: !65 = !{!66}
// CHECK:STDOUT: !66 = !DILocalVariable(arg: 1, scope: !64, type: !7)
// CHECK:STDOUT: !67 = !DILocation(line: 44, column: 16, scope: !64)
// CHECK:STDOUT: !68 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5716d9c282b70019:core.Destroy.Core", scope: null, file: !1, line: 44, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !69)
// CHECK:STDOUT: !69 = !{!70}
// CHECK:STDOUT: !70 = !DILocalVariable(arg: 1, scope: !68, type: !7)
// CHECK:STDOUT: !71 = !DILocation(line: 44, column: 16, scope: !68)
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "Op", linkageName: "_COp.c9ead255f32e7c59:core.Destroy.Core", scope: null, file: !1, line: 44, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !73)
// CHECK:STDOUT: !73 = !{!74}
// CHECK:STDOUT: !74 = !DILocalVariable(arg: 1, scope: !72, type: !7)
// CHECK:STDOUT: !75 = !DILocation(line: 44, column: 16, scope: !72)
// CHECK:STDOUT: !76 = distinct !DISubprogram(name: "Op", linkageName: "_COp.a214566110020819:core.Destroy.Core", scope: null, file: !1, line: 44, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !77)
// CHECK:STDOUT: !77 = !{!78}
// CHECK:STDOUT: !78 = !DILocalVariable(arg: 1, scope: !76, type: !7)
// CHECK:STDOUT: !79 = !DILocation(line: 44, column: 16, scope: !76)
// CHECK:STDOUT: !80 = distinct !DISubprogram(name: "Both", linkageName: "_CBoth.Main", scope: null, file: !1, line: 48, type: !81, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !83)
// CHECK:STDOUT: !81 = !DISubroutineType(types: !82)
// CHECK:STDOUT: !82 = !{!7, !8, !20}
// CHECK:STDOUT: !83 = !{!84, !85}
// CHECK:STDOUT: !84 = !DILocalVariable(arg: 1, scope: !80, type: !8)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 2, scope: !80, type: !20)
// CHECK:STDOUT: !86 = !DILocation(line: 49, column: 3, scope: !80)
// CHECK:STDOUT: !87 = !DILocation(line: 49, column: 16, scope: !80)
// CHECK:STDOUT: !88 = !DILocation(line: 50, column: 3, scope: !80)
// CHECK:STDOUT: !89 = !DILocation(line: 50, column: 16, scope: !80)
// CHECK:STDOUT: !90 = !DILocation(line: 51, column: 37, scope: !80)
// CHECK:STDOUT: !91 = !DILocation(line: 51, column: 32, scope: !80)
// CHECK:STDOUT: !92 = !DILocation(line: 51, column: 10, scope: !80)
// CHECK:STDOUT: !93 = !DILocation(line: 51, column: 3, scope: !80)
// CHECK:STDOUT: !94 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5f42013854821c52:core.Destroy.Core", scope: null, file: !1, line: 50, type: !95, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !97)
// CHECK:STDOUT: !95 = !DISubroutineType(types: !96)
// CHECK:STDOUT: !96 = !{null, !20}
// CHECK:STDOUT: !97 = !{!98}
// CHECK:STDOUT: !98 = !DILocalVariable(arg: 1, scope: !94, type: !20)
// CHECK:STDOUT: !99 = !DILocation(line: 50, column: 16, scope: !94)
// CHECK:STDOUT: !100 = distinct !DISubprogram(name: "Op", linkageName: "_COp.62437d0fc7766a41:core.Destroy.Core", scope: null, file: !1, line: 50, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !101)
// CHECK:STDOUT: !101 = !{!102}
// CHECK:STDOUT: !102 = !DILocalVariable(arg: 1, scope: !100, type: !7)
// CHECK:STDOUT: !103 = !DILocation(line: 50, column: 16, scope: !100)
// CHECK:STDOUT: !104 = distinct !DISubprogram(name: "Op", linkageName: "_COp.4a128e99f244da38:core.Destroy.Core", scope: null, file: !1, line: 50, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !105)
// CHECK:STDOUT: !105 = !{!106}
// CHECK:STDOUT: !106 = !DILocalVariable(arg: 1, scope: !104, type: !7)
// CHECK:STDOUT: !107 = !DILocation(line: 50, column: 16, scope: !104)
// CHECK:STDOUT: !108 = distinct !DISubprogram(name: "Op", linkageName: "_COp.37ea992d2bcf2c08:core.Destroy.Core", scope: null, file: !1, line: 50, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !109)
// CHECK:STDOUT: !109 = !{!110}
// CHECK:STDOUT: !110 = !DILocalVariable(arg: 1, scope: !108, type: !7)
// CHECK:STDOUT: !111 = !DILocation(line: 50, column: 16, scope: !108)
// CHECK:STDOUT: !112 = distinct !DISubprogram(name: "Op", linkageName: "_COp.e292046f58666a75:core.Destroy.Core", scope: null, file: !1, line: 50, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !113)
// CHECK:STDOUT: !113 = !{!114}
// CHECK:STDOUT: !114 = !DILocalVariable(arg: 1, scope: !112, type: !7)
// CHECK:STDOUT: !115 = !DILocation(line: 50, column: 16, scope: !112)
// CHECK:STDOUT: !116 = distinct !DISubprogram(name: "Op", linkageName: "_COp.c41c2132e4b94059:core.Destroy.Core", scope: null, file: !1, line: 50, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !117)
// CHECK:STDOUT: !117 = !{!118}
// CHECK:STDOUT: !118 = !DILocalVariable(arg: 1, scope: !116, type: !7)
// CHECK:STDOUT: !119 = !DILocation(line: 50, column: 16, scope: !116)
// CHECK:STDOUT: !120 = distinct !DISubprogram(name: "Op", linkageName: "_COp.4b7b55811680dccf:core.Destroy.Core", scope: null, file: !1, line: 50, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !121)
// CHECK:STDOUT: !121 = !{!122}
// CHECK:STDOUT: !122 = !DILocalVariable(arg: 1, scope: !120, type: !7)
// CHECK:STDOUT: !123 = !DILocation(line: 50, column: 16, scope: !120)
// CHECK:STDOUT: !124 = distinct !DISubprogram(name: "Op", linkageName: "_COp.bea179675fd68487:core.Destroy.Core", scope: null, file: !1, line: 50, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !125)
// CHECK:STDOUT: !125 = !{!126}
// CHECK:STDOUT: !126 = !DILocalVariable(arg: 1, scope: !124, type: !7)
// CHECK:STDOUT: !127 = !DILocation(line: 50, column: 16, scope: !124)
// CHECK:STDOUT: !128 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.MyResult.Main.8122a03446648385", scope: null, file: !1, line: 3, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !129)
// CHECK:STDOUT: !129 = !{!130}
// CHECK:STDOUT: !130 = !DILocalVariable(arg: 1, scope: !128, type: !8)
// CHECK:STDOUT: !131 = !DILocation(line: 3, column: 1, scope: !128)
// CHECK:STDOUT: !132 = !DILocation(line: 4, column: 11, scope: !128)
// CHECK:STDOUT: !133 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.8122a03446648385", scope: null, file: !1, line: 3, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !134)
// CHECK:STDOUT: !134 = !{!135}
// CHECK:STDOUT: !135 = !DILocalVariable(arg: 1, scope: !133, type: !8)
// CHECK:STDOUT: !136 = !DILocation(line: 3, column: 1, scope: !133)
// CHECK:STDOUT: !137 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.MyResult.Main.b7dd877894074427", scope: null, file: !1, line: 3, type: !18, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !138)
// CHECK:STDOUT: !138 = !{!139}
// CHECK:STDOUT: !139 = !DILocalVariable(arg: 1, scope: !137, type: !20)
// CHECK:STDOUT: !140 = !DILocation(line: 3, column: 1, scope: !137)
// CHECK:STDOUT: !141 = !DILocation(line: 4, column: 11, scope: !137)
// CHECK:STDOUT: !142 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.b7dd877894074427", scope: null, file: !1, line: 3, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !143)
// CHECK:STDOUT: !143 = !{!144}
// CHECK:STDOUT: !144 = !DILocalVariable(arg: 1, scope: !142, type: !8)
// CHECK:STDOUT: !145 = !DILocation(line: 3, column: 1, scope: !142)
// CHECK:STDOUT: !146 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !1, line: 17, type: !147, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !149)
// CHECK:STDOUT: !147 = !DISubroutineType(types: !148)
// CHECK:STDOUT: !148 = !{!7, !7}
// CHECK:STDOUT: !149 = !{!150}
// CHECK:STDOUT: !150 = !DILocalVariable(arg: 1, scope: !146, type: !7)
// CHECK:STDOUT: !151 = !DILocation(line: 19, column: 7, scope: !146)
// CHECK:STDOUT: !152 = !DILocation(line: 19, column: 34, scope: !146)
// CHECK:STDOUT: !153 = !DILocation(line: 19, column: 27, scope: !146)
// CHECK:STDOUT: !154 = !DILocation(line: 20, column: 7, scope: !146)
// CHECK:STDOUT: !155 = !DILocation(line: 20, column: 35, scope: !146)
// CHECK:STDOUT: !156 = !DILocation(line: 20, column: 28, scope: !146)
// CHECK:STDOUT: !157 = !DILocation(line: 28, column: 12, scope: !146)
// CHECK:STDOUT: !158 = !DILocation(line: 28, column: 5, scope: !146)
// CHECK:STDOUT: !159 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !1, line: 30, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !160)
// CHECK:STDOUT: !160 = !{!161}
// CHECK:STDOUT: !161 = !DILocalVariable(arg: 1, scope: !159, type: !8)
// CHECK:STDOUT: !162 = !DILocation(line: 30, column: 39, scope: !159)
// CHECK:STDOUT: !163 = !DILocation(line: 30, column: 32, scope: !159)
// CHECK:STDOUT: !164 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427", scope: null, file: !1, line: 30, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !165)
// CHECK:STDOUT: !165 = !{!166}
// CHECK:STDOUT: !166 = !DILocalVariable(arg: 1, scope: !164, type: !8)
// CHECK:STDOUT: !167 = !DILocation(line: 30, column: 39, scope: !164)
// CHECK:STDOUT: !168 = !DILocation(line: 30, column: 32, scope: !164)
// CHECK:STDOUT: !169 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427", scope: null, file: !1, line: 17, type: !147, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !170)
// CHECK:STDOUT: !170 = !{!171}
// CHECK:STDOUT: !171 = !DILocalVariable(arg: 1, scope: !169, type: !7)
// CHECK:STDOUT: !172 = !DILocation(line: 19, column: 7, scope: !169)
// CHECK:STDOUT: !173 = !DILocation(line: 19, column: 34, scope: !169)
// CHECK:STDOUT: !174 = !DILocation(line: 19, column: 27, scope: !169)
// CHECK:STDOUT: !175 = !DILocation(line: 20, column: 7, scope: !169)
// CHECK:STDOUT: !176 = !DILocation(line: 20, column: 35, scope: !169)
// CHECK:STDOUT: !177 = !DILocation(line: 20, column: 28, scope: !169)
// CHECK:STDOUT: !178 = !DILocation(line: 28, column: 12, scope: !169)
// CHECK:STDOUT: !179 = !DILocation(line: 28, column: 5, scope: !169)
// CHECK:STDOUT: !180 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.8122a03446648385", scope: null, file: !181, line: 21, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !182)
// CHECK:STDOUT: !181 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !182 = !{!183}
// CHECK:STDOUT: !183 = !DILocalVariable(arg: 1, scope: !180, type: !8)
// CHECK:STDOUT: !184 = !DILocation(line: 21, column: 1, scope: !180)
// CHECK:STDOUT: !185 = !DILocation(line: 22, column: 21, scope: !180)
// CHECK:STDOUT: !186 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.8122a03446648385", scope: null, file: !181, line: 21, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !187)
// CHECK:STDOUT: !187 = !{!188}
// CHECK:STDOUT: !188 = !DILocalVariable(arg: 1, scope: !186, type: !8)
// CHECK:STDOUT: !189 = !DILocation(line: 21, column: 1, scope: !186)
// CHECK:STDOUT: !190 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.9bba81283511934f", scope: null, file: !1, line: 13, type: !191, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !191 = !DISubroutineType(types: !192)
// CHECK:STDOUT: !192 = !{!7}
// CHECK:STDOUT: !193 = !DILocation(line: 13, column: 45, scope: !190)
// CHECK:STDOUT: !194 = !DILocation(line: 13, column: 38, scope: !190)
// CHECK:STDOUT: !195 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.b7dd877894074427", scope: null, file: !181, line: 21, type: !18, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !196)
// CHECK:STDOUT: !196 = !{!197}
// CHECK:STDOUT: !197 = !DILocalVariable(arg: 1, scope: !195, type: !20)
// CHECK:STDOUT: !198 = !DILocation(line: 21, column: 1, scope: !195)
// CHECK:STDOUT: !199 = !DILocation(line: 22, column: 21, scope: !195)
// CHECK:STDOUT: !200 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.b7dd877894074427", scope: null, file: !181, line: 21, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !201)
// CHECK:STDOUT: !201 = !{!202}
// CHECK:STDOUT: !202 = !DILocalVariable(arg: 1, scope: !200, type: !8)
// CHECK:STDOUT: !203 = !DILocation(line: 21, column: 1, scope: !200)
// CHECK:STDOUT: !204 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.fc3567e4618671b9", scope: null, file: !1, line: 13, type: !191, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !205 = !DILocation(line: 13, column: 45, scope: !204)
// CHECK:STDOUT: !206 = !DILocation(line: 13, column: 38, scope: !204)
// CHECK:STDOUT:

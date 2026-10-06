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
// CHECK:STDOUT: define void @_COpen.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !24 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call = icmp sgt i32 %n, 0, !dbg !29
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Greater.call, label %if.then, label %if.else, !dbg !30
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_COk.MyResult.Main.8122a03446648385(ptr %return, i32 %n), !dbg !32
// CHECK:STDOUT:   ret void, !dbg !33
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %n), !dbg !35
// CHECK:STDOUT:   ret void, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CWide.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %n) #0 !dbg !38 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call = icmp sgt i64 %n, 0, !dbg !43
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Greater.call, label %if.then, label %if.else, !dbg !44
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_COk.MyResult.Main.b7dd877894074427(ptr %return, i64 %n), !dbg !46
// CHECK:STDOUT:   ret void, !dbg !47
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.b7dd877894074427(ptr %return, i32 0), !dbg !48
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CBasic.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !51 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %f.var = alloca i32, align 4, !dbg !56
// CHECK:STDOUT:   %.loc44_22.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !58
// CHECK:STDOUT:   %.loc44_23.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !58
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %f.var), !dbg !56
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc44_22.1.temp), !dbg !58
// CHECK:STDOUT:   call void @_COpen.Main(ptr %.loc44_22.1.temp, i32 %n), !dbg !58
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc44_23.1.temp), !dbg !58
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %.loc44_23.1.temp, ptr %.loc44_22.1.temp), !dbg !58
// CHECK:STDOUT:   %.loc44_23.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc44_23.1.temp, i32 0, i32 0, !dbg !58
// CHECK:STDOUT:   %.loc44_23.6 = load i8, ptr %.loc44_23.5.discriminant, align 1, !dbg !58
// CHECK:STDOUT:   %.loc44_23.61 = trunc i8 %.loc44_23.6 to i1, !dbg !58
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc44_23.61, !dbg !58
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc44_23.1, label %.loc44_23.2, !dbg !58
// CHECK:STDOUT:
// CHECK:STDOUT: .loc44_23.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc44_23.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc44_23.1.temp, i32 0, i32 1, !dbg !58
// CHECK:STDOUT:   %.loc44_23.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc44_23.9.payload, i32 0, i32 0, !dbg !58
// CHECK:STDOUT:   %tuple.elem0.loc44_23.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc44_23.10.Break, i32 0, i32 0, !dbg !58
// CHECK:STDOUT:   %.loc44_23.11 = load i32, ptr %tuple.elem0.loc44_23.1.tuple.elem, align 4, !dbg !58
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %return, i32 %.loc44_23.11), !dbg !58
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc44_23.1.temp), !dbg !58
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %.loc44_22.1.temp), !dbg !58
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %f.var), !dbg !56
// CHECK:STDOUT:   ret void, !dbg !58
// CHECK:STDOUT:
// CHECK:STDOUT: .loc44_23.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc44_23.13.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc44_23.1.temp, i32 0, i32 1, !dbg !58
// CHECK:STDOUT:   %.loc44_23.14.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc44_23.13.payload, i32 0, i32 0, !dbg !58
// CHECK:STDOUT:   %tuple.elem0.loc44_23.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc44_23.14.Continue, i32 0, i32 0, !dbg !58
// CHECK:STDOUT:   %.loc44_23.15 = load i32, ptr %tuple.elem0.loc44_23.2.tuple.elem, align 4, !dbg !58
// CHECK:STDOUT:   store i32 %.loc44_23.15, ptr %f.var, align 4, !dbg !56
// CHECK:STDOUT:   %.loc45_32 = load i32, ptr %f.var, align 4, !dbg !62
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc45_32, 1, !dbg !62
// CHECK:STDOUT:   call void @_COk.MyResult.Main.8122a03446648385(ptr %return, i32 %Int.as.AddWith.impl.Op.call), !dbg !63
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc44_23.1.temp), !dbg !58
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %.loc44_22.1.temp), !dbg !58
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %f.var), !dbg !56
// CHECK:STDOUT:   ret void, !dbg !64
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !68
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !70 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !72
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !74 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !76
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !76
// CHECK:STDOUT:   ret void, !dbg !76
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !78 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !80
// CHECK:STDOUT:   ret void, !dbg !80
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core"(ptr %self) #0 !dbg !82 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !84
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b63d267505e804f2:core.Destroy.Core"(ptr %self) #0 !dbg !86 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core"(ptr %self), !dbg !88
// CHECK:STDOUT:   ret void, !dbg !88
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.88b1683142354768:core.Destroy.Core"(ptr %self) #0 !dbg !90 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc44_23.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !92
// CHECK:STDOUT:   call void @"_CSelfDestruct.b63d267505e804f2:core.Destroy.Core"(ptr %.loc44_23.1.payload), !dbg !92
// CHECK:STDOUT:   %.loc44_23.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !92
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc44_23.2.discriminant), !dbg !92
// CHECK:STDOUT:   ret void, !dbg !92
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.88b1683142354768:core.Destroy.Core"(ptr %self) #0 !dbg !94 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.88b1683142354768:core.Destroy.Core"(ptr %self), !dbg !96
// CHECK:STDOUT:   ret void, !dbg !96
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core"(ptr %self) #0 !dbg !98 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !100
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %self) #0 !dbg !102 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core"(ptr %self), !dbg !104
// CHECK:STDOUT:   ret void, !dbg !104
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %self) #0 !dbg !106 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !108
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %self) #0 !dbg !110 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %self), !dbg !112
// CHECK:STDOUT:   ret void, !dbg !112
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.f269577697e84b3c:core.Destroy.Core"(ptr %self) #0 !dbg !114 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc44_22.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !116
// CHECK:STDOUT:   call void @"_CSelfDestruct.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %.loc44_22.1.payload), !dbg !116
// CHECK:STDOUT:   %.loc44_22.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !116
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc44_22.2.discriminant), !dbg !116
// CHECK:STDOUT:   ret void, !dbg !116
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f269577697e84b3c:core.Destroy.Core"(ptr %self) #0 !dbg !118 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.f269577697e84b3c:core.Destroy.Core"(ptr %self), !dbg !120
// CHECK:STDOUT:   ret void, !dbg !120
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.21e9b6df7c6352ff:core.Destroy.Core"(ptr %self) #0 !dbg !122 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !124
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %self) #0 !dbg !126 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.21e9b6df7c6352ff:core.Destroy.Core"(ptr %self), !dbg !128
// CHECK:STDOUT:   ret void, !dbg !128
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CBoth.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %n, i64 %m) #0 !dbg !130 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.var = alloca i32, align 4, !dbg !137
// CHECK:STDOUT:   %.loc49_22.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !139
// CHECK:STDOUT:   %.loc49_23.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !139
// CHECK:STDOUT:   %y.var = alloca i64, align 8, !dbg !141
// CHECK:STDOUT:   %.loc50_22.1.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !143
// CHECK:STDOUT:   %.loc50_23.1.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !143
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %x.var), !dbg !137
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc49_22.1.temp), !dbg !139
// CHECK:STDOUT:   call void @_COpen.Main(ptr %.loc49_22.1.temp, i32 %n), !dbg !139
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc49_23.1.temp), !dbg !139
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr %.loc49_23.1.temp, ptr %.loc49_22.1.temp), !dbg !139
// CHECK:STDOUT:   %.loc49_23.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc49_23.1.temp, i32 0, i32 0, !dbg !139
// CHECK:STDOUT:   %.loc49_23.6 = load i8, ptr %.loc49_23.5.discriminant, align 1, !dbg !139
// CHECK:STDOUT:   %.loc49_23.61 = trunc i8 %.loc49_23.6 to i1, !dbg !139
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc49 = icmp eq i1 true, %.loc49_23.61, !dbg !139
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc49, label %.loc49_23.1, label %.loc49_23.2, !dbg !139
// CHECK:STDOUT:
// CHECK:STDOUT: .loc49_23.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc49_23.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc49_23.1.temp, i32 0, i32 1, !dbg !139
// CHECK:STDOUT:   %.loc49_23.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc49_23.9.payload, i32 0, i32 0, !dbg !139
// CHECK:STDOUT:   %tuple.elem0.loc49_23.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc49_23.10.Break, i32 0, i32 0, !dbg !139
// CHECK:STDOUT:   %.loc49_23.11 = load i32, ptr %tuple.elem0.loc49_23.1.tuple.elem, align 4, !dbg !139
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %return, i32 %.loc49_23.11), !dbg !139
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc49_23.1.temp), !dbg !139
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %.loc49_22.1.temp), !dbg !139
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %x.var), !dbg !137
// CHECK:STDOUT:   ret void, !dbg !139
// CHECK:STDOUT:
// CHECK:STDOUT: .loc49_23.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc49_23.13.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc49_23.1.temp, i32 0, i32 1, !dbg !139
// CHECK:STDOUT:   %.loc49_23.14.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc49_23.13.payload, i32 0, i32 0, !dbg !139
// CHECK:STDOUT:   %tuple.elem0.loc49_23.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc49_23.14.Continue, i32 0, i32 0, !dbg !139
// CHECK:STDOUT:   %.loc49_23.15 = load i32, ptr %tuple.elem0.loc49_23.2.tuple.elem, align 4, !dbg !139
// CHECK:STDOUT:   store i32 %.loc49_23.15, ptr %x.var, align 4, !dbg !137
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %y.var), !dbg !141
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc50_22.1.temp), !dbg !143
// CHECK:STDOUT:   call void @_CWide.Main(ptr %.loc50_22.1.temp, i64 %m), !dbg !143
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc50_23.1.temp), !dbg !143
// CHECK:STDOUT:   call void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %.loc50_23.1.temp, ptr %.loc50_22.1.temp), !dbg !143
// CHECK:STDOUT:   %.loc50_23.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc50_23.1.temp, i32 0, i32 0, !dbg !143
// CHECK:STDOUT:   %.loc50_23.6 = load i8, ptr %.loc50_23.5.discriminant, align 1, !dbg !143
// CHECK:STDOUT:   %.loc50_23.62 = trunc i8 %.loc50_23.6 to i1, !dbg !143
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc50 = icmp eq i1 true, %.loc50_23.62, !dbg !143
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc50, label %.loc50_23.1, label %.loc50_23.2, !dbg !143
// CHECK:STDOUT:
// CHECK:STDOUT: .loc50_23.1:                                      ; preds = %.loc49_23.2
// CHECK:STDOUT:   %.loc50_23.9.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc50_23.1.temp, i32 0, i32 1, !dbg !143
// CHECK:STDOUT:   %.loc50_23.10.Break = getelementptr inbounds nuw [8 x i8], ptr %.loc50_23.9.payload, i32 0, i32 0, !dbg !143
// CHECK:STDOUT:   %tuple.elem0.loc50_23.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc50_23.10.Break, i32 0, i32 0, !dbg !143
// CHECK:STDOUT:   %.loc50_23.11 = load i32, ptr %tuple.elem0.loc50_23.1.tuple.elem, align 4, !dbg !143
// CHECK:STDOUT:   call void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr %return, i32 %.loc50_23.11), !dbg !143
// CHECK:STDOUT:   call void @"_CSelfDestruct.3dff857b72298492:core.Destroy.Core"(ptr %.loc50_23.1.temp), !dbg !143
// CHECK:STDOUT:   call void @"_CSelfDestruct.9644e7318f4a981d:core.Destroy.Core"(ptr %.loc50_22.1.temp), !dbg !143
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %y.var), !dbg !141
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc49_23.1.temp), !dbg !139
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %.loc49_22.1.temp), !dbg !139
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %x.var), !dbg !137
// CHECK:STDOUT:   ret void, !dbg !143
// CHECK:STDOUT:
// CHECK:STDOUT: .loc50_23.2:                                      ; preds = %.loc49_23.2
// CHECK:STDOUT:   %.loc50_23.13.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc50_23.1.temp, i32 0, i32 1, !dbg !143
// CHECK:STDOUT:   %.loc50_23.14.Continue = getelementptr inbounds nuw [8 x i8], ptr %.loc50_23.13.payload, i32 0, i32 0, !dbg !143
// CHECK:STDOUT:   %tuple.elem0.loc50_23.2.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc50_23.14.Continue, i32 0, i32 0, !dbg !143
// CHECK:STDOUT:   %.loc50_23.15 = load i64, ptr %tuple.elem0.loc50_23.2.tuple.elem, align 8, !dbg !143
// CHECK:STDOUT:   store i64 %.loc50_23.15, ptr %y.var, align 8, !dbg !141
// CHECK:STDOUT:   %.loc51_37 = load i32, ptr %x.var, align 4, !dbg !146
// CHECK:STDOUT:   %Int.as.As.impl.Convert.call = sext i32 %.loc51_37 to i64, !dbg !146
// CHECK:STDOUT:   %.loc51_32 = load i64, ptr %y.var, align 8, !dbg !145
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i64 %.loc51_32, %Int.as.As.impl.Convert.call, !dbg !145
// CHECK:STDOUT:   call void @_COk.MyResult.Main.b7dd877894074427(ptr %return, i64 %Int.as.AddWith.impl.Op.call), !dbg !147
// CHECK:STDOUT:   call void @"_CSelfDestruct.3dff857b72298492:core.Destroy.Core"(ptr %.loc50_23.1.temp), !dbg !143
// CHECK:STDOUT:   call void @"_CSelfDestruct.9644e7318f4a981d:core.Destroy.Core"(ptr %.loc50_22.1.temp), !dbg !143
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %y.var), !dbg !141
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc49_23.1.temp), !dbg !139
// CHECK:STDOUT:   call void @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core"(ptr %.loc49_22.1.temp), !dbg !139
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %x.var), !dbg !137
// CHECK:STDOUT:   ret void, !dbg !148
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !150 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !152
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.f67381d184fb2c27:core.Destroy.Core"(ptr %self) #0 !dbg !154 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %self, i32 0, i32 0, !dbg !156
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !156
// CHECK:STDOUT:   ret void, !dbg !156
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f67381d184fb2c27:core.Destroy.Core"(ptr %self) #0 !dbg !158 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.f67381d184fb2c27:core.Destroy.Core"(ptr %self), !dbg !160
// CHECK:STDOUT:   ret void, !dbg !160
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.75fa817956543446:core.Destroy.Core"(ptr %self) #0 !dbg !162 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !164
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.75fa817956543446:core.Destroy.Core"(ptr %self) #0 !dbg !166 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.75fa817956543446:core.Destroy.Core"(ptr %self), !dbg !168
// CHECK:STDOUT:   ret void, !dbg !168
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.c1f61786be347789:core.Destroy.Core"(ptr %self) #0 !dbg !170 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc50_23.1.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !172
// CHECK:STDOUT:   call void @"_CSelfDestruct.75fa817956543446:core.Destroy.Core"(ptr %.loc50_23.1.payload), !dbg !172
// CHECK:STDOUT:   %.loc50_23.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !172
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc50_23.2.discriminant), !dbg !172
// CHECK:STDOUT:   ret void, !dbg !172
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.c1f61786be347789:core.Destroy.Core"(ptr %self) #0 !dbg !174 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.c1f61786be347789:core.Destroy.Core"(ptr %self), !dbg !176
// CHECK:STDOUT:   ret void, !dbg !176
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.3dff857b72298492:core.Destroy.Core"(ptr %self) #0 !dbg !178 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !180
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.3dff857b72298492:core.Destroy.Core"(ptr %self) #0 !dbg !182 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.3dff857b72298492:core.Destroy.Core"(ptr %self), !dbg !184
// CHECK:STDOUT:   ret void, !dbg !184
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.6d73c51926c0a20e:core.Destroy.Core"(ptr %self) #0 !dbg !186 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !188
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.6d73c51926c0a20e:core.Destroy.Core"(ptr %self) #0 !dbg !190 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.6d73c51926c0a20e:core.Destroy.Core"(ptr %self), !dbg !192
// CHECK:STDOUT:   ret void, !dbg !192
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.26b3932cce5effda:core.Destroy.Core"(ptr %self) #0 !dbg !194 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc50_22.1.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !196
// CHECK:STDOUT:   call void @"_CSelfDestruct.6d73c51926c0a20e:core.Destroy.Core"(ptr %.loc50_22.1.payload), !dbg !196
// CHECK:STDOUT:   %.loc50_22.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !196
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc50_22.2.discriminant), !dbg !196
// CHECK:STDOUT:   ret void, !dbg !196
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.26b3932cce5effda:core.Destroy.Core"(ptr %self) #0 !dbg !198 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.26b3932cce5effda:core.Destroy.Core"(ptr %self), !dbg !200
// CHECK:STDOUT:   ret void, !dbg !200
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.9644e7318f4a981d:core.Destroy.Core"(ptr %self) #0 !dbg !202 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !204
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.9644e7318f4a981d:core.Destroy.Core"(ptr %self) #0 !dbg !206 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.9644e7318f4a981d:core.Destroy.Core"(ptr %self), !dbg !208
// CHECK:STDOUT:   ret void, !dbg !208
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !210 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !212
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !212
// CHECK:STDOUT:   %.loc3_35.5.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !212
// CHECK:STDOUT:   %.loc4_11.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !213
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.30e.loc3_35.7, i64 8, i1 false), !dbg !212
// CHECK:STDOUT:   store { i32 } %.loc4_11.1.tuple.init, ptr %.loc3_35.5.Ok, align 4, !dbg !212
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Ok, i32 0, i32 0, !dbg !213
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !213
// CHECK:STDOUT:   ret void, !dbg !212
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !215 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !217
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !217
// CHECK:STDOUT:   %.loc3_35.5.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !217
// CHECK:STDOUT:   %.loc6_1.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !217
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @MyResult.val.df1.loc3_35.7, i64 8, i1 false), !dbg !217
// CHECK:STDOUT:   store { i32 } %.loc6_1.1.tuple.init, ptr %.loc3_35.5.Err, align 4, !dbg !217
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Err, i32 0, i32 0, !dbg !217
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !217
// CHECK:STDOUT:   ret void, !dbg !217
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.MyResult.Main.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %_) #0 !dbg !219 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !221
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !221
// CHECK:STDOUT:   %.loc3_35.5.Ok = getelementptr inbounds nuw [8 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !221
// CHECK:STDOUT:   %.loc4_11.1.tuple.init = insertvalue { i64 } poison, i64 %_, 0, !dbg !222
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @MyResult.val.9f4.loc3_35.7, i64 16, i1 false), !dbg !221
// CHECK:STDOUT:   store { i64 } %.loc4_11.1.tuple.init, ptr %.loc3_35.5.Ok, align 8, !dbg !221
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc3_35.5.Ok, i32 0, i32 0, !dbg !222
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem0.tuple.elem, align 8, !dbg !222
// CHECK:STDOUT:   ret void, !dbg !221
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.MyResult.Main.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !224 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_35.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !226
// CHECK:STDOUT:   %.loc3_35.4.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !226
// CHECK:STDOUT:   %.loc3_35.5.Err = getelementptr inbounds nuw [8 x i8], ptr %.loc3_35.4.payload, i32 0, i32 0, !dbg !226
// CHECK:STDOUT:   %.loc6_1.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !226
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @MyResult.val.142.loc3_35.7, i64 16, i1 false), !dbg !226
// CHECK:STDOUT:   store { i32 } %.loc6_1.1.tuple.init, ptr %.loc3_35.5.Err, align 4, !dbg !226
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc3_35.5.Err, i32 0, i32 0, !dbg !226
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !226
// CHECK:STDOUT:   ret void, !dbg !226
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !228 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !234
// CHECK:STDOUT:   %.loc19_22.4 = load i8, ptr %.loc19_22.3.discriminant, align 1, !dbg !234
// CHECK:STDOUT:   %.loc19_22.41 = trunc i8 %.loc19_22.4 to i1, !dbg !234
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc19 = icmp eq i1 false, %.loc19_22.41, !dbg !234
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc19, label %match.case.then.loc19, label %match.case.else.loc19, !dbg !234
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc19:                            ; preds = %entry
// CHECK:STDOUT:   %.loc19_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !234
// CHECK:STDOUT:   %.loc19_22.8.Ok = getelementptr inbounds nuw [4 x i8], ptr %.loc19_22.7.payload, i32 0, i32 0, !dbg !234
// CHECK:STDOUT:   %tuple.elem0.loc19.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc19_22.8.Ok, i32 0, i32 0, !dbg !234
// CHECK:STDOUT:   %.loc19_22.9 = load i32, ptr %tuple.elem0.loc19.tuple.elem, align 4, !dbg !234
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc19_22.9), !dbg !237
// CHECK:STDOUT:   ret void, !dbg !238
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc19:                            ; preds = %entry
// CHECK:STDOUT:   %.loc20_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !239
// CHECK:STDOUT:   %.loc20_23.4 = load i8, ptr %.loc20_23.3.discriminant, align 1, !dbg !239
// CHECK:STDOUT:   %.loc20_23.42 = trunc i8 %.loc20_23.4 to i1, !dbg !239
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc20 = icmp eq i1 true, %.loc20_23.42, !dbg !239
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc20, label %match.case.then.loc20, label %match.done, !dbg !239
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc20:                            ; preds = %match.case.else.loc19
// CHECK:STDOUT:   %.loc20_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !239
// CHECK:STDOUT:   %.loc20_23.8.Err = getelementptr inbounds nuw [4 x i8], ptr %.loc20_23.7.payload, i32 0, i32 0, !dbg !239
// CHECK:STDOUT:   %tuple.elem0.loc20.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc20_23.8.Err, i32 0, i32 0, !dbg !239
// CHECK:STDOUT:   %.loc20_23.9 = load i32, ptr %tuple.elem0.loc20.tuple.elem, align 4, !dbg !239
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.8122a03446648385(ptr %return, i32 %.loc20_23.9), !dbg !242
// CHECK:STDOUT:   ret void, !dbg !243
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc19
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !245
// CHECK:STDOUT:   ret void, !dbg !248
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %e) #0 !dbg !250 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.8122a03446648385(ptr %return, i32 %e), !dbg !256
// CHECK:STDOUT:   ret void, !dbg !257
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %e) #0 !dbg !259 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.MyResult.Main.b7dd877894074427(ptr %return, i32 %e), !dbg !265
// CHECK:STDOUT:   ret void, !dbg !266
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %self) #0 !dbg !268 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !274
// CHECK:STDOUT:   %.loc19_22.4 = load i8, ptr %.loc19_22.3.discriminant, align 1, !dbg !274
// CHECK:STDOUT:   %.loc19_22.41 = trunc i8 %.loc19_22.4 to i1, !dbg !274
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc19 = icmp eq i1 false, %.loc19_22.41, !dbg !274
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc19, label %match.case.then.loc19, label %match.case.else.loc19, !dbg !274
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc19:                            ; preds = %entry
// CHECK:STDOUT:   %.loc19_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !274
// CHECK:STDOUT:   %.loc19_22.8.Ok = getelementptr inbounds nuw [8 x i8], ptr %.loc19_22.7.payload, i32 0, i32 0, !dbg !274
// CHECK:STDOUT:   %tuple.elem0.loc19.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc19_22.8.Ok, i32 0, i32 0, !dbg !274
// CHECK:STDOUT:   %.loc19_22.9 = load i64, ptr %tuple.elem0.loc19.tuple.elem, align 8, !dbg !274
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.b7dd877894074427(ptr %return, i64 %.loc19_22.9), !dbg !277
// CHECK:STDOUT:   ret void, !dbg !278
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc19:                            ; preds = %entry
// CHECK:STDOUT:   %.loc20_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !279
// CHECK:STDOUT:   %.loc20_23.4 = load i8, ptr %.loc20_23.3.discriminant, align 1, !dbg !279
// CHECK:STDOUT:   %.loc20_23.42 = trunc i8 %.loc20_23.4 to i1, !dbg !279
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc20 = icmp eq i1 true, %.loc20_23.42, !dbg !279
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc20, label %match.case.then.loc20, label %match.done, !dbg !279
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc20:                            ; preds = %match.case.else.loc19
// CHECK:STDOUT:   %.loc20_23.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !279
// CHECK:STDOUT:   %.loc20_23.8.Err = getelementptr inbounds nuw [8 x i8], ptr %.loc20_23.7.payload, i32 0, i32 0, !dbg !279
// CHECK:STDOUT:   %tuple.elem0.loc20.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc20_23.8.Err, i32 0, i32 0, !dbg !279
// CHECK:STDOUT:   %.loc20_23.9 = load i32, ptr %tuple.elem0.loc20.tuple.elem, align 4, !dbg !279
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.b7dd877894074427(ptr %return, i32 %.loc20_23.9), !dbg !282
// CHECK:STDOUT:   ret void, !dbg !283
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc19
// CHECK:STDOUT:   call void @_CDiverge.Main.fc3567e4618671b9(ptr %return), !dbg !285
// CHECK:STDOUT:   ret void, !dbg !286
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !289 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !291
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !291
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !291
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !292
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.f6c.anon, i64 8, i1 false), !dbg !291
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !291
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !292
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !292
// CHECK:STDOUT:   ret void, !dbg !291
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !294 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !296
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !296
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !296
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !296
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.493.anon, i64 8, i1 false), !dbg !296
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !296
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !296
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !296
// CHECK:STDOUT:   ret void, !dbg !296
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.9bba81283511934f(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !298 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiverge.Main.9bba81283511934f(ptr %return), !dbg !301
// CHECK:STDOUT:   ret void, !dbg !302
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i64 %_) #0 !dbg !303 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !305
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !305
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !305
// CHECK:STDOUT:   %tuple.init = insertvalue { i64 } poison, i64 %_, 0, !dbg !306
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.fa9.anon, i64 16, i1 false), !dbg !305
// CHECK:STDOUT:   store { i64 } %tuple.init, ptr %Continue, align 8, !dbg !305
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i64 }, ptr %Continue, i32 0, i32 0, !dbg !306
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem, align 8, !dbg !306
// CHECK:STDOUT:   ret void, !dbg !305
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.b7dd877894074427(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !308 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !310
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !310
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !310
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !310
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.d01.anon, i64 16, i1 false), !dbg !310
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !310
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !310
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !310
// CHECK:STDOUT:   ret void, !dbg !310
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiverge.Main.fc3567e4618671b9(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return) #0 !dbg !312 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDiverge.Main.fc3567e4618671b9(ptr %return), !dbg !315
// CHECK:STDOUT:   ret void, !dbg !316
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core", { 0, 1, 2, 3, 5, 4 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core", { 0, 1, 2, 4, 3 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core", { 0, 1, 2, 4, 3 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", { 0, 2, 1 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.3dff857b72298492:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.9644e7318f4a981d:core.Destroy.Core", { 1, 0 }
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "propagate.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!9, !7}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!9, !8}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{null, !6}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !16 = !{null, !7}
// CHECK:STDOUT: !17 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !18 = !{null, !9}
// CHECK:STDOUT: !19 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !20 = !{!9, !7, !8}
// CHECK:STDOUT: !21 = !DISubroutineType(types: !20)
// CHECK:STDOUT: !22 = !{null, !8}
// CHECK:STDOUT: !23 = !DISubroutineType(types: !22)
// CHECK:STDOUT: !24 = distinct !DISubprogram(name: "Open", linkageName: "_COpen.Main", scope: null, file: !4, line: 33, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !37)
// CHECK:STDOUT: !25 = !DILocalVariable(arg: 1, scope: !24, type: !7)
// CHECK:STDOUT: !29 = !DILocation(line: 34, column: 7, scope: !24)
// CHECK:STDOUT: !30 = !DILocation(line: 34, column: 6, scope: !24)
// CHECK:STDOUT: !32 = !DILocation(line: 34, column: 23, scope: !24)
// CHECK:STDOUT: !33 = !DILocation(line: 34, column: 16, scope: !24)
// CHECK:STDOUT: !35 = !DILocation(line: 35, column: 10, scope: !24)
// CHECK:STDOUT: !36 = !DILocation(line: 35, column: 3, scope: !24)
// CHECK:STDOUT: !37 = !{!25}
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "Wide", linkageName: "_CWide.Main", scope: null, file: !4, line: 38, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !50)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !38, type: !8)
// CHECK:STDOUT: !43 = !DILocation(line: 39, column: 7, scope: !38)
// CHECK:STDOUT: !44 = !DILocation(line: 39, column: 6, scope: !38)
// CHECK:STDOUT: !46 = !DILocation(line: 39, column: 23, scope: !38)
// CHECK:STDOUT: !47 = !DILocation(line: 39, column: 16, scope: !38)
// CHECK:STDOUT: !48 = !DILocation(line: 40, column: 10, scope: !38)
// CHECK:STDOUT: !49 = !DILocation(line: 40, column: 3, scope: !38)
// CHECK:STDOUT: !50 = !{!39}
// CHECK:STDOUT: !51 = distinct !DISubprogram(name: "Basic", linkageName: "_CBasic.Main", scope: null, file: !4, line: 43, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !65)
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !51, type: !7)
// CHECK:STDOUT: !56 = !DILocation(line: 44, column: 3, scope: !51)
// CHECK:STDOUT: !58 = !DILocation(line: 44, column: 16, scope: !51)
// CHECK:STDOUT: !59 = !{!9, !9}
// CHECK:STDOUT: !60 = !DISubroutineType(types: !59)
// CHECK:STDOUT: !62 = !DILocation(line: 45, column: 32, scope: !51)
// CHECK:STDOUT: !63 = !DILocation(line: 45, column: 10, scope: !51)
// CHECK:STDOUT: !64 = !DILocation(line: 45, column: 3, scope: !51)
// CHECK:STDOUT: !65 = !{!52}
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !4, line: 44, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !69)
// CHECK:STDOUT: !67 = !DILocalVariable(arg: 1, scope: !66, type: !6)
// CHECK:STDOUT: !68 = !DILocation(line: 44, column: 16, scope: !66)
// CHECK:STDOUT: !69 = !{!67}
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 44, type: !17, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !73)
// CHECK:STDOUT: !71 = !DILocalVariable(arg: 1, scope: !70, type: !7)
// CHECK:STDOUT: !72 = !DILocation(line: 44, column: 16, scope: !70)
// CHECK:STDOUT: !73 = !{!71}
// CHECK:STDOUT: !74 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 44, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !77)
// CHECK:STDOUT: !75 = !DILocalVariable(arg: 1, scope: !74, type: !9)
// CHECK:STDOUT: !76 = !DILocation(line: 44, column: 16, scope: !74)
// CHECK:STDOUT: !77 = !{!75}
// CHECK:STDOUT: !78 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 44, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !81)
// CHECK:STDOUT: !79 = !DILocalVariable(arg: 1, scope: !78, type: !9)
// CHECK:STDOUT: !80 = !DILocation(line: 44, column: 16, scope: !78)
// CHECK:STDOUT: !81 = !{!79}
// CHECK:STDOUT: !82 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core", scope: null, file: !4, line: 44, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !85)
// CHECK:STDOUT: !83 = !DILocalVariable(arg: 1, scope: !82, type: !9)
// CHECK:STDOUT: !84 = !DILocation(line: 44, column: 16, scope: !82)
// CHECK:STDOUT: !85 = !{!83}
// CHECK:STDOUT: !86 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b63d267505e804f2:core.Destroy.Core", scope: null, file: !4, line: 44, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !89)
// CHECK:STDOUT: !87 = !DILocalVariable(arg: 1, scope: !86, type: !9)
// CHECK:STDOUT: !88 = !DILocation(line: 44, column: 16, scope: !86)
// CHECK:STDOUT: !89 = !{!87}
// CHECK:STDOUT: !90 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.88b1683142354768:core.Destroy.Core", scope: null, file: !4, line: 44, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !93)
// CHECK:STDOUT: !91 = !DILocalVariable(arg: 1, scope: !90, type: !9)
// CHECK:STDOUT: !92 = !DILocation(line: 44, column: 16, scope: !90)
// CHECK:STDOUT: !93 = !{!91}
// CHECK:STDOUT: !94 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.88b1683142354768:core.Destroy.Core", scope: null, file: !4, line: 44, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !97)
// CHECK:STDOUT: !95 = !DILocalVariable(arg: 1, scope: !94, type: !9)
// CHECK:STDOUT: !96 = !DILocation(line: 44, column: 16, scope: !94)
// CHECK:STDOUT: !97 = !{!95}
// CHECK:STDOUT: !98 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core", scope: null, file: !4, line: 44, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !101)
// CHECK:STDOUT: !99 = !DILocalVariable(arg: 1, scope: !98, type: !9)
// CHECK:STDOUT: !100 = !DILocation(line: 44, column: 16, scope: !98)
// CHECK:STDOUT: !101 = !{!99}
// CHECK:STDOUT: !102 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core", scope: null, file: !4, line: 44, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !105)
// CHECK:STDOUT: !103 = !DILocalVariable(arg: 1, scope: !102, type: !9)
// CHECK:STDOUT: !104 = !DILocation(line: 44, column: 16, scope: !102)
// CHECK:STDOUT: !105 = !{!103}
// CHECK:STDOUT: !106 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.bf4a066f5a5b60ea:core.Destroy.Core", scope: null, file: !4, line: 44, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !109)
// CHECK:STDOUT: !107 = !DILocalVariable(arg: 1, scope: !106, type: !9)
// CHECK:STDOUT: !108 = !DILocation(line: 44, column: 16, scope: !106)
// CHECK:STDOUT: !109 = !{!107}
// CHECK:STDOUT: !110 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.bf4a066f5a5b60ea:core.Destroy.Core", scope: null, file: !4, line: 44, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !113)
// CHECK:STDOUT: !111 = !DILocalVariable(arg: 1, scope: !110, type: !9)
// CHECK:STDOUT: !112 = !DILocation(line: 44, column: 16, scope: !110)
// CHECK:STDOUT: !113 = !{!111}
// CHECK:STDOUT: !114 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.f269577697e84b3c:core.Destroy.Core", scope: null, file: !4, line: 44, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !117)
// CHECK:STDOUT: !115 = !DILocalVariable(arg: 1, scope: !114, type: !9)
// CHECK:STDOUT: !116 = !DILocation(line: 44, column: 16, scope: !114)
// CHECK:STDOUT: !117 = !{!115}
// CHECK:STDOUT: !118 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f269577697e84b3c:core.Destroy.Core", scope: null, file: !4, line: 44, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !121)
// CHECK:STDOUT: !119 = !DILocalVariable(arg: 1, scope: !118, type: !9)
// CHECK:STDOUT: !120 = !DILocation(line: 44, column: 16, scope: !118)
// CHECK:STDOUT: !121 = !{!119}
// CHECK:STDOUT: !122 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.21e9b6df7c6352ff:core.Destroy.Core", scope: null, file: !4, line: 44, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !125)
// CHECK:STDOUT: !123 = !DILocalVariable(arg: 1, scope: !122, type: !9)
// CHECK:STDOUT: !124 = !DILocation(line: 44, column: 16, scope: !122)
// CHECK:STDOUT: !125 = !{!123}
// CHECK:STDOUT: !126 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.21e9b6df7c6352ff:core.Destroy.Core", scope: null, file: !4, line: 44, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !129)
// CHECK:STDOUT: !127 = !DILocalVariable(arg: 1, scope: !126, type: !9)
// CHECK:STDOUT: !128 = !DILocation(line: 44, column: 16, scope: !126)
// CHECK:STDOUT: !129 = !{!127}
// CHECK:STDOUT: !130 = distinct !DISubprogram(name: "Both", linkageName: "_CBoth.Main", scope: null, file: !4, line: 48, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !149)
// CHECK:STDOUT: !131 = !DILocalVariable(arg: 1, scope: !130, type: !7)
// CHECK:STDOUT: !132 = !DILocalVariable(arg: 2, scope: !130, type: !8)
// CHECK:STDOUT: !137 = !DILocation(line: 49, column: 3, scope: !130)
// CHECK:STDOUT: !139 = !DILocation(line: 49, column: 16, scope: !130)
// CHECK:STDOUT: !141 = !DILocation(line: 50, column: 3, scope: !130)
// CHECK:STDOUT: !143 = !DILocation(line: 50, column: 16, scope: !130)
// CHECK:STDOUT: !145 = !DILocation(line: 51, column: 32, scope: !130)
// CHECK:STDOUT: !146 = !DILocation(line: 51, column: 37, scope: !130)
// CHECK:STDOUT: !147 = !DILocation(line: 51, column: 10, scope: !130)
// CHECK:STDOUT: !148 = !DILocation(line: 51, column: 3, scope: !130)
// CHECK:STDOUT: !149 = !{!131, !132}
// CHECK:STDOUT: !150 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !4, line: 50, type: !23, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !153)
// CHECK:STDOUT: !151 = !DILocalVariable(arg: 1, scope: !150, type: !8)
// CHECK:STDOUT: !152 = !DILocation(line: 50, column: 16, scope: !150)
// CHECK:STDOUT: !153 = !{!151}
// CHECK:STDOUT: !154 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.f67381d184fb2c27:core.Destroy.Core", scope: null, file: !4, line: 50, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !157)
// CHECK:STDOUT: !155 = !DILocalVariable(arg: 1, scope: !154, type: !9)
// CHECK:STDOUT: !156 = !DILocation(line: 50, column: 16, scope: !154)
// CHECK:STDOUT: !157 = !{!155}
// CHECK:STDOUT: !158 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f67381d184fb2c27:core.Destroy.Core", scope: null, file: !4, line: 50, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !161)
// CHECK:STDOUT: !159 = !DILocalVariable(arg: 1, scope: !158, type: !9)
// CHECK:STDOUT: !160 = !DILocation(line: 50, column: 16, scope: !158)
// CHECK:STDOUT: !161 = !{!159}
// CHECK:STDOUT: !162 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.75fa817956543446:core.Destroy.Core", scope: null, file: !4, line: 50, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !165)
// CHECK:STDOUT: !163 = !DILocalVariable(arg: 1, scope: !162, type: !9)
// CHECK:STDOUT: !164 = !DILocation(line: 50, column: 16, scope: !162)
// CHECK:STDOUT: !165 = !{!163}
// CHECK:STDOUT: !166 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.75fa817956543446:core.Destroy.Core", scope: null, file: !4, line: 50, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !169)
// CHECK:STDOUT: !167 = !DILocalVariable(arg: 1, scope: !166, type: !9)
// CHECK:STDOUT: !168 = !DILocation(line: 50, column: 16, scope: !166)
// CHECK:STDOUT: !169 = !{!167}
// CHECK:STDOUT: !170 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.c1f61786be347789:core.Destroy.Core", scope: null, file: !4, line: 50, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !173)
// CHECK:STDOUT: !171 = !DILocalVariable(arg: 1, scope: !170, type: !9)
// CHECK:STDOUT: !172 = !DILocation(line: 50, column: 16, scope: !170)
// CHECK:STDOUT: !173 = !{!171}
// CHECK:STDOUT: !174 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.c1f61786be347789:core.Destroy.Core", scope: null, file: !4, line: 50, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !177)
// CHECK:STDOUT: !175 = !DILocalVariable(arg: 1, scope: !174, type: !9)
// CHECK:STDOUT: !176 = !DILocation(line: 50, column: 16, scope: !174)
// CHECK:STDOUT: !177 = !{!175}
// CHECK:STDOUT: !178 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.3dff857b72298492:core.Destroy.Core", scope: null, file: !4, line: 50, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !181)
// CHECK:STDOUT: !179 = !DILocalVariable(arg: 1, scope: !178, type: !9)
// CHECK:STDOUT: !180 = !DILocation(line: 50, column: 16, scope: !178)
// CHECK:STDOUT: !181 = !{!179}
// CHECK:STDOUT: !182 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.3dff857b72298492:core.Destroy.Core", scope: null, file: !4, line: 50, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !185)
// CHECK:STDOUT: !183 = !DILocalVariable(arg: 1, scope: !182, type: !9)
// CHECK:STDOUT: !184 = !DILocation(line: 50, column: 16, scope: !182)
// CHECK:STDOUT: !185 = !{!183}
// CHECK:STDOUT: !186 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.6d73c51926c0a20e:core.Destroy.Core", scope: null, file: !4, line: 50, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !189)
// CHECK:STDOUT: !187 = !DILocalVariable(arg: 1, scope: !186, type: !9)
// CHECK:STDOUT: !188 = !DILocation(line: 50, column: 16, scope: !186)
// CHECK:STDOUT: !189 = !{!187}
// CHECK:STDOUT: !190 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.6d73c51926c0a20e:core.Destroy.Core", scope: null, file: !4, line: 50, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !193)
// CHECK:STDOUT: !191 = !DILocalVariable(arg: 1, scope: !190, type: !9)
// CHECK:STDOUT: !192 = !DILocation(line: 50, column: 16, scope: !190)
// CHECK:STDOUT: !193 = !{!191}
// CHECK:STDOUT: !194 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.26b3932cce5effda:core.Destroy.Core", scope: null, file: !4, line: 50, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !197)
// CHECK:STDOUT: !195 = !DILocalVariable(arg: 1, scope: !194, type: !9)
// CHECK:STDOUT: !196 = !DILocation(line: 50, column: 16, scope: !194)
// CHECK:STDOUT: !197 = !{!195}
// CHECK:STDOUT: !198 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.26b3932cce5effda:core.Destroy.Core", scope: null, file: !4, line: 50, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !201)
// CHECK:STDOUT: !199 = !DILocalVariable(arg: 1, scope: !198, type: !9)
// CHECK:STDOUT: !200 = !DILocation(line: 50, column: 16, scope: !198)
// CHECK:STDOUT: !201 = !{!199}
// CHECK:STDOUT: !202 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.9644e7318f4a981d:core.Destroy.Core", scope: null, file: !4, line: 50, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !205)
// CHECK:STDOUT: !203 = !DILocalVariable(arg: 1, scope: !202, type: !9)
// CHECK:STDOUT: !204 = !DILocation(line: 50, column: 16, scope: !202)
// CHECK:STDOUT: !205 = !{!203}
// CHECK:STDOUT: !206 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.9644e7318f4a981d:core.Destroy.Core", scope: null, file: !4, line: 50, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !209)
// CHECK:STDOUT: !207 = !DILocalVariable(arg: 1, scope: !206, type: !9)
// CHECK:STDOUT: !208 = !DILocation(line: 50, column: 16, scope: !206)
// CHECK:STDOUT: !209 = !{!207}
// CHECK:STDOUT: !210 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.MyResult.Main.8122a03446648385", scope: null, file: !4, line: 3, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !214)
// CHECK:STDOUT: !211 = !DILocalVariable(arg: 1, scope: !210, type: !7)
// CHECK:STDOUT: !212 = !DILocation(line: 3, column: 1, scope: !210)
// CHECK:STDOUT: !213 = !DILocation(line: 4, column: 11, scope: !210)
// CHECK:STDOUT: !214 = !{!211}
// CHECK:STDOUT: !215 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.8122a03446648385", scope: null, file: !4, line: 3, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !218)
// CHECK:STDOUT: !216 = !DILocalVariable(arg: 1, scope: !215, type: !7)
// CHECK:STDOUT: !217 = !DILocation(line: 3, column: 1, scope: !215)
// CHECK:STDOUT: !218 = !{!216}
// CHECK:STDOUT: !219 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.MyResult.Main.b7dd877894074427", scope: null, file: !4, line: 3, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !223)
// CHECK:STDOUT: !220 = !DILocalVariable(arg: 1, scope: !219, type: !8)
// CHECK:STDOUT: !221 = !DILocation(line: 3, column: 1, scope: !219)
// CHECK:STDOUT: !222 = !DILocation(line: 4, column: 11, scope: !219)
// CHECK:STDOUT: !223 = !{!220}
// CHECK:STDOUT: !224 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.MyResult.Main.b7dd877894074427", scope: null, file: !4, line: 3, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !227)
// CHECK:STDOUT: !225 = !DILocalVariable(arg: 1, scope: !224, type: !7)
// CHECK:STDOUT: !226 = !DILocation(line: 3, column: 1, scope: !224)
// CHECK:STDOUT: !227 = !{!225}
// CHECK:STDOUT: !228 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !4, line: 17, type: !60, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !249)
// CHECK:STDOUT: !229 = !DILocalVariable(arg: 1, scope: !228, type: !9)
// CHECK:STDOUT: !234 = !DILocation(line: 19, column: 7, scope: !228)
// CHECK:STDOUT: !237 = !DILocation(line: 19, column: 34, scope: !228)
// CHECK:STDOUT: !238 = !DILocation(line: 19, column: 27, scope: !228)
// CHECK:STDOUT: !239 = !DILocation(line: 20, column: 7, scope: !228)
// CHECK:STDOUT: !242 = !DILocation(line: 20, column: 35, scope: !228)
// CHECK:STDOUT: !243 = !DILocation(line: 20, column: 28, scope: !228)
// CHECK:STDOUT: !245 = !DILocation(line: 28, column: 12, scope: !228)
// CHECK:STDOUT: !246 = !{!9}
// CHECK:STDOUT: !247 = !DISubroutineType(types: !246)
// CHECK:STDOUT: !248 = !DILocation(line: 28, column: 5, scope: !228)
// CHECK:STDOUT: !249 = !{!229}
// CHECK:STDOUT: !250 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.8122a03446648385", scope: null, file: !4, line: 30, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !258)
// CHECK:STDOUT: !251 = !DILocalVariable(arg: 1, scope: !250, type: !7)
// CHECK:STDOUT: !256 = !DILocation(line: 30, column: 39, scope: !250)
// CHECK:STDOUT: !257 = !DILocation(line: 30, column: 32, scope: !250)
// CHECK:STDOUT: !258 = !{!251}
// CHECK:STDOUT: !259 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427", scope: null, file: !4, line: 30, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !267)
// CHECK:STDOUT: !260 = !DILocalVariable(arg: 1, scope: !259, type: !7)
// CHECK:STDOUT: !265 = !DILocation(line: 30, column: 39, scope: !259)
// CHECK:STDOUT: !266 = !DILocation(line: 30, column: 32, scope: !259)
// CHECK:STDOUT: !267 = !{!260}
// CHECK:STDOUT: !268 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.MyResult.f15b7207a8078ef6.Main:Try.Core.b7dd877894074427", scope: null, file: !4, line: 17, type: !60, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !287)
// CHECK:STDOUT: !269 = !DILocalVariable(arg: 1, scope: !268, type: !9)
// CHECK:STDOUT: !274 = !DILocation(line: 19, column: 7, scope: !268)
// CHECK:STDOUT: !277 = !DILocation(line: 19, column: 34, scope: !268)
// CHECK:STDOUT: !278 = !DILocation(line: 19, column: 27, scope: !268)
// CHECK:STDOUT: !279 = !DILocation(line: 20, column: 7, scope: !268)
// CHECK:STDOUT: !282 = !DILocation(line: 20, column: 35, scope: !268)
// CHECK:STDOUT: !283 = !DILocation(line: 20, column: 28, scope: !268)
// CHECK:STDOUT: !285 = !DILocation(line: 28, column: 12, scope: !268)
// CHECK:STDOUT: !286 = !DILocation(line: 28, column: 5, scope: !268)
// CHECK:STDOUT: !287 = !{!269}
// CHECK:STDOUT: !288 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !289 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.8122a03446648385", scope: null, file: !288, line: 21, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !293)
// CHECK:STDOUT: !290 = !DILocalVariable(arg: 1, scope: !289, type: !7)
// CHECK:STDOUT: !291 = !DILocation(line: 21, column: 1, scope: !289)
// CHECK:STDOUT: !292 = !DILocation(line: 22, column: 21, scope: !289)
// CHECK:STDOUT: !293 = !{!290}
// CHECK:STDOUT: !294 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.8122a03446648385", scope: null, file: !288, line: 21, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !297)
// CHECK:STDOUT: !295 = !DILocalVariable(arg: 1, scope: !294, type: !7)
// CHECK:STDOUT: !296 = !DILocation(line: 21, column: 1, scope: !294)
// CHECK:STDOUT: !297 = !{!295}
// CHECK:STDOUT: !298 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.9bba81283511934f", scope: null, file: !4, line: 13, type: !247, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !301 = !DILocation(line: 13, column: 45, scope: !298)
// CHECK:STDOUT: !302 = !DILocation(line: 13, column: 38, scope: !298)
// CHECK:STDOUT: !303 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.b7dd877894074427", scope: null, file: !288, line: 21, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !307)
// CHECK:STDOUT: !304 = !DILocalVariable(arg: 1, scope: !303, type: !8)
// CHECK:STDOUT: !305 = !DILocation(line: 21, column: 1, scope: !303)
// CHECK:STDOUT: !306 = !DILocation(line: 22, column: 21, scope: !303)
// CHECK:STDOUT: !307 = !{!304}
// CHECK:STDOUT: !308 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.b7dd877894074427", scope: null, file: !288, line: 21, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !311)
// CHECK:STDOUT: !309 = !DILocalVariable(arg: 1, scope: !308, type: !7)
// CHECK:STDOUT: !310 = !DILocation(line: 21, column: 1, scope: !308)
// CHECK:STDOUT: !311 = !{!309}
// CHECK:STDOUT: !312 = distinct !DISubprogram(name: "Diverge", linkageName: "_CDiverge.Main.fc3567e4618671b9", scope: null, file: !4, line: 13, type: !247, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !315 = !DILocation(line: 13, column: 45, scope: !312)
// CHECK:STDOUT: !316 = !DILocation(line: 13, column: 38, scope: !312)
// CHECK:STDOUT:

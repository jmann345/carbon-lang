// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/operators/question_result.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/operators/question_result.carbon

// The postfix `?` desugar over the prelude `Core.Result(T, E)`, lowered (the
// operators/question.carbon shape with the user `MyResult` replaced by the
// prelude choice and its `final impl ... as Try`): the prelude `Branch`
// call materializing the `Core.ControlFlow(i32, i32)` carrier, the `i8`
// discriminant load compared against `Break`'s discriminant (1), the
// conditional branch, the break path's payload load + prelude `FromBreak`
// call + early `ret` through the return slot, and the continue path's
// payload load as the expression's value. `Unit` additionally lowers a
// `Core.Result((), i32)` — the zero-sized `Ok(())` payload (D-EH-2).

// --- propagate.carbon
library "[[@TEST_NAME]]";

fn Open(n: i32) -> Core.Result(i32, i32) {
  if (n > 0) { return Core.Result(i32, i32).Ok(n); }
  return Core.Result(i32, i32).Err(n);
}

fn Basic(n: i32) -> Core.Result(i32, i32) {
  var f: i32 = Open(n)?;
  return Core.Result(i32, i32).Ok(f + 1);
}

fn Chain(n: i32) -> Core.Result(i32, i32) {
  var t: i32 = Open(Open(n)?)?;
  return Core.Result(i32, i32).Ok(t);
}

// --- unit.carbon
library "[[@TEST_NAME]]";

fn Check(n: i32) -> Core.Result((), i32) {
  if (n > 0) { return Core.Result((), i32).Ok(()); }
  return Core.Result((), i32).Err(n);
}

fn Unit(n: i32) -> Core.Result((), i32) {
  Check(n)?;
  return Core.Result((), i32).Ok(());
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'propagate.carbon'
// CHECK:STDOUT: source_filename = "propagate.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Result.val.ad4.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @Result.val.d4e.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @ControlFlow.val.f6c.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @ControlFlow.val.493.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_COpen.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call = icmp sgt i32 %n, 0, !dbg !22
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Greater.call, label %if.then, label %if.else, !dbg !23
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_COk.Result.Core.8122a03446648385(ptr %return, i32 %n), !dbg !25
// CHECK:STDOUT:   ret void, !dbg !26
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CErr.Result.Core.8122a03446648385(ptr %return, i32 %n), !dbg !28
// CHECK:STDOUT:   ret void, !dbg !29
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CBasic.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !31 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %f.var = alloca i32, align 4, !dbg !36
// CHECK:STDOUT:   %.loc9_22.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !38
// CHECK:STDOUT:   %.loc9_23.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !38
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %f.var), !dbg !36
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc9_22.1.temp), !dbg !38
// CHECK:STDOUT:   call void @_COpen.Main(ptr %.loc9_22.1.temp, i32 %n), !dbg !38
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc9_23.1.temp), !dbg !38
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr %.loc9_23.1.temp, ptr %.loc9_22.1.temp), !dbg !38
// CHECK:STDOUT:   %.loc9_23.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc9_23.1.temp, i32 0, i32 0, !dbg !38
// CHECK:STDOUT:   %.loc9_23.6 = load i8, ptr %.loc9_23.5.discriminant, align 1, !dbg !38
// CHECK:STDOUT:   %.loc9_23.61 = trunc i8 %.loc9_23.6 to i1, !dbg !38
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc9_23.61, !dbg !38
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc9_23.1, label %.loc9_23.2, !dbg !38
// CHECK:STDOUT:
// CHECK:STDOUT: .loc9_23.1:                                       ; preds = %entry
// CHECK:STDOUT:   %.loc9_23.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc9_23.1.temp, i32 0, i32 1, !dbg !38
// CHECK:STDOUT:   %.loc9_23.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc9_23.9.payload, i32 0, i32 0, !dbg !38
// CHECK:STDOUT:   %tuple.elem0.loc9_23.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc9_23.10.Break, i32 0, i32 0, !dbg !38
// CHECK:STDOUT:   %.loc9_23.11 = load i32, ptr %tuple.elem0.loc9_23.1.tuple.elem, align 4, !dbg !38
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr %return, i32 %.loc9_23.11), !dbg !38
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc9_23.1.temp), !dbg !38
// CHECK:STDOUT:   call void @"_CSelfDestruct.250f550470eb8844:core.Destroy.Core"(ptr %.loc9_22.1.temp), !dbg !38
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %f.var), !dbg !36
// CHECK:STDOUT:   ret void, !dbg !38
// CHECK:STDOUT:
// CHECK:STDOUT: .loc9_23.2:                                       ; preds = %entry
// CHECK:STDOUT:   %.loc9_23.13.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc9_23.1.temp, i32 0, i32 1, !dbg !38
// CHECK:STDOUT:   %.loc9_23.14.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc9_23.13.payload, i32 0, i32 0, !dbg !38
// CHECK:STDOUT:   %tuple.elem0.loc9_23.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc9_23.14.Continue, i32 0, i32 0, !dbg !38
// CHECK:STDOUT:   %.loc9_23.15 = load i32, ptr %tuple.elem0.loc9_23.2.tuple.elem, align 4, !dbg !38
// CHECK:STDOUT:   store i32 %.loc9_23.15, ptr %f.var, align 4, !dbg !36
// CHECK:STDOUT:   %.loc10_35 = load i32, ptr %f.var, align 4, !dbg !42
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc10_35, 1, !dbg !42
// CHECK:STDOUT:   call void @_COk.Result.Core.8122a03446648385(ptr %return, i32 %Int.as.AddWith.impl.Op.call), !dbg !43
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc9_23.1.temp), !dbg !38
// CHECK:STDOUT:   call void @"_CSelfDestruct.250f550470eb8844:core.Destroy.Core"(ptr %.loc9_22.1.temp), !dbg !38
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %f.var), !dbg !36
// CHECK:STDOUT:   ret void, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !56
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !56
// CHECK:STDOUT:   ret void, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !60
// CHECK:STDOUT:   ret void, !dbg !60
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core"(ptr %self) #0 !dbg !62 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !64
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b63d267505e804f2:core.Destroy.Core"(ptr %self) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core"(ptr %self), !dbg !68
// CHECK:STDOUT:   ret void, !dbg !68
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.88b1683142354768:core.Destroy.Core"(ptr %self) #0 !dbg !70 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_23.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !72
// CHECK:STDOUT:   call void @"_CSelfDestruct.b63d267505e804f2:core.Destroy.Core"(ptr %.loc9_23.1.payload), !dbg !72
// CHECK:STDOUT:   %.loc9_23.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !72
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc9_23.2.discriminant), !dbg !72
// CHECK:STDOUT:   ret void, !dbg !72
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.88b1683142354768:core.Destroy.Core"(ptr %self) #0 !dbg !74 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.88b1683142354768:core.Destroy.Core"(ptr %self), !dbg !76
// CHECK:STDOUT:   ret void, !dbg !76
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core"(ptr %self) #0 !dbg !78 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !80
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %self) #0 !dbg !82 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core"(ptr %self), !dbg !84
// CHECK:STDOUT:   ret void, !dbg !84
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %self) #0 !dbg !86 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !88
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %self) #0 !dbg !90 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %self), !dbg !92
// CHECK:STDOUT:   ret void, !dbg !92
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.f269577697e84b3c:core.Destroy.Core"(ptr %self) #0 !dbg !94 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_22.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !96
// CHECK:STDOUT:   call void @"_CSelfDestruct.bf4a066f5a5b60ea:core.Destroy.Core"(ptr %.loc9_22.1.payload), !dbg !96
// CHECK:STDOUT:   %.loc9_22.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !96
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc9_22.2.discriminant), !dbg !96
// CHECK:STDOUT:   ret void, !dbg !96
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f269577697e84b3c:core.Destroy.Core"(ptr %self) #0 !dbg !98 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.f269577697e84b3c:core.Destroy.Core"(ptr %self), !dbg !100
// CHECK:STDOUT:   ret void, !dbg !100
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.250f550470eb8844:core.Destroy.Core"(ptr %self) #0 !dbg !102 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !104
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.250f550470eb8844:core.Destroy.Core"(ptr %self) #0 !dbg !106 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.250f550470eb8844:core.Destroy.Core"(ptr %self), !dbg !108
// CHECK:STDOUT:   ret void, !dbg !108
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CChain.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !110 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %t.var = alloca i32, align 4, !dbg !115
// CHECK:STDOUT:   %.loc14_27.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !117
// CHECK:STDOUT:   %.loc14_28.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !117
// CHECK:STDOUT:   %.loc14_29.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !118
// CHECK:STDOUT:   %.loc14_30.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !118
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %t.var), !dbg !115
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc14_27.1.temp), !dbg !117
// CHECK:STDOUT:   call void @_COpen.Main(ptr %.loc14_27.1.temp, i32 %n), !dbg !117
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc14_28.1.temp), !dbg !117
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr %.loc14_28.1.temp, ptr %.loc14_27.1.temp), !dbg !117
// CHECK:STDOUT:   %.loc14_28.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc14_28.1.temp, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %.loc14_28.6 = load i8, ptr %.loc14_28.5.discriminant, align 1, !dbg !117
// CHECK:STDOUT:   %.loc14_28.61 = trunc i8 %.loc14_28.6 to i1, !dbg !117
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc14_28 = icmp eq i1 true, %.loc14_28.61, !dbg !117
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc14_28, label %.loc14_28.1, label %.loc14_28.2, !dbg !117
// CHECK:STDOUT:
// CHECK:STDOUT: .loc14_28.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc14_28.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc14_28.1.temp, i32 0, i32 1, !dbg !117
// CHECK:STDOUT:   %.loc14_28.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc14_28.9.payload, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %tuple.elem0.loc14_28.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc14_28.10.Break, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %.loc14_28.11 = load i32, ptr %tuple.elem0.loc14_28.1.tuple.elem, align 4, !dbg !117
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr %return, i32 %.loc14_28.11), !dbg !117
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc14_28.1.temp), !dbg !117
// CHECK:STDOUT:   call void @"_CSelfDestruct.250f550470eb8844:core.Destroy.Core"(ptr %.loc14_27.1.temp), !dbg !117
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %t.var), !dbg !115
// CHECK:STDOUT:   ret void, !dbg !117
// CHECK:STDOUT:
// CHECK:STDOUT: .loc14_28.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc14_28.13.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc14_28.1.temp, i32 0, i32 1, !dbg !117
// CHECK:STDOUT:   %.loc14_28.14.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc14_28.13.payload, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %tuple.elem0.loc14_28.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc14_28.14.Continue, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %.loc14_28.15 = load i32, ptr %tuple.elem0.loc14_28.2.tuple.elem, align 4, !dbg !117
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc14_29.1.temp), !dbg !118
// CHECK:STDOUT:   call void @_COpen.Main(ptr %.loc14_29.1.temp, i32 %.loc14_28.15), !dbg !118
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc14_30.1.temp), !dbg !118
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr %.loc14_30.1.temp, ptr %.loc14_29.1.temp), !dbg !118
// CHECK:STDOUT:   %.loc14_30.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc14_30.1.temp, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %.loc14_30.6 = load i8, ptr %.loc14_30.5.discriminant, align 1, !dbg !118
// CHECK:STDOUT:   %.loc14_30.62 = trunc i8 %.loc14_30.6 to i1, !dbg !118
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc14_30 = icmp eq i1 true, %.loc14_30.62, !dbg !118
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc14_30, label %.loc14_30.1, label %.loc14_30.2, !dbg !118
// CHECK:STDOUT:
// CHECK:STDOUT: .loc14_30.1:                                      ; preds = %.loc14_28.2
// CHECK:STDOUT:   %.loc14_30.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc14_30.1.temp, i32 0, i32 1, !dbg !118
// CHECK:STDOUT:   %.loc14_30.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc14_30.9.payload, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %tuple.elem0.loc14_30.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc14_30.10.Break, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %.loc14_30.11 = load i32, ptr %tuple.elem0.loc14_30.1.tuple.elem, align 4, !dbg !118
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr %return, i32 %.loc14_30.11), !dbg !118
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc14_30.1.temp), !dbg !118
// CHECK:STDOUT:   call void @"_CSelfDestruct.250f550470eb8844:core.Destroy.Core"(ptr %.loc14_29.1.temp), !dbg !118
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc14_28.1.temp), !dbg !117
// CHECK:STDOUT:   call void @"_CSelfDestruct.250f550470eb8844:core.Destroy.Core"(ptr %.loc14_27.1.temp), !dbg !117
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %t.var), !dbg !115
// CHECK:STDOUT:   ret void, !dbg !118
// CHECK:STDOUT:
// CHECK:STDOUT: .loc14_30.2:                                      ; preds = %.loc14_28.2
// CHECK:STDOUT:   %.loc14_30.13.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc14_30.1.temp, i32 0, i32 1, !dbg !118
// CHECK:STDOUT:   %.loc14_30.14.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc14_30.13.payload, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %tuple.elem0.loc14_30.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc14_30.14.Continue, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %.loc14_30.15 = load i32, ptr %tuple.elem0.loc14_30.2.tuple.elem, align 4, !dbg !118
// CHECK:STDOUT:   store i32 %.loc14_30.15, ptr %t.var, align 4, !dbg !115
// CHECK:STDOUT:   %.loc15_35 = load i32, ptr %t.var, align 4, !dbg !120
// CHECK:STDOUT:   call void @_COk.Result.Core.8122a03446648385(ptr %return, i32 %.loc15_35), !dbg !121
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc14_30.1.temp), !dbg !118
// CHECK:STDOUT:   call void @"_CSelfDestruct.250f550470eb8844:core.Destroy.Core"(ptr %.loc14_29.1.temp), !dbg !118
// CHECK:STDOUT:   call void @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core"(ptr %.loc14_28.1.temp), !dbg !117
// CHECK:STDOUT:   call void @"_CSelfDestruct.250f550470eb8844:core.Destroy.Core"(ptr %.loc14_27.1.temp), !dbg !117
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %t.var), !dbg !115
// CHECK:STDOUT:   ret void, !dbg !122
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.Result.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !125 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !127
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !127
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !127
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !128
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Result.val.ad4.anon, i64 8, i1 false), !dbg !127
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Ok, align 4, !dbg !127
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Ok, i32 0, i32 0, !dbg !128
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !128
// CHECK:STDOUT:   ret void, !dbg !127
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.Result.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !130 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !132
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !132
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !132
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !132
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Result.val.d4e.anon, i64 8, i1 false), !dbg !132
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Err, align 4, !dbg !132
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !132
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !132
// CHECK:STDOUT:   ret void, !dbg !132
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !134 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !140
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !140
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !140
// CHECK:STDOUT:   %3 = icmp eq i1 false, %2, !dbg !140
// CHECK:STDOUT:   br i1 %3, label %4, label %6, !dbg !140
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !140
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !140
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Ok, i32 0, i32 0, !dbg !140
// CHECK:STDOUT:   %5 = load i32, ptr %tuple.elem, align 4, !dbg !140
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.8122a03446648385(ptr %return, i32 %5), !dbg !143
// CHECK:STDOUT:   ret void, !dbg !144
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %0
// CHECK:STDOUT:   %discriminant1 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !145
// CHECK:STDOUT:   %7 = load i8, ptr %discriminant1, align 1, !dbg !145
// CHECK:STDOUT:   %8 = trunc i8 %7 to i1, !dbg !145
// CHECK:STDOUT:   %9 = icmp eq i1 true, %8, !dbg !145
// CHECK:STDOUT:   br i1 %9, label %10, label %12, !dbg !145
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %6
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !145
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload2, i32 0, i32 0, !dbg !145
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !145
// CHECK:STDOUT:   %11 = load i32, ptr %tuple.elem3, align 4, !dbg !145
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.8122a03446648385(ptr %return, i32 %11), !dbg !148
// CHECK:STDOUT:   ret void, !dbg !149
// CHECK:STDOUT:
// CHECK:STDOUT: 12:                                               ; preds = %6
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr %return, ptr %self), !dbg !151
// CHECK:STDOUT:   ret void, !dbg !152
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %b) #0 !dbg !154 {
// CHECK:STDOUT:   call void @_CErr.Result.Core.8122a03446648385(ptr %return, i32 %b), !dbg !160
// CHECK:STDOUT:   ret void, !dbg !161
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !164 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !166
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !166
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !166
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !167
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.f6c.anon, i64 8, i1 false), !dbg !166
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !166
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !167
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !167
// CHECK:STDOUT:   ret void, !dbg !166
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !169 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !171
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !171
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !171
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !171
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.493.anon, i64 8, i1 false), !dbg !171
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !171
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !171
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !171
// CHECK:STDOUT:   ret void, !dbg !171
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core", { 0, 1, 2, 3, 5, 4 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core", { 0, 1, 2, 3, 4, 6, 5 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.250f550470eb8844:core.Destroy.Core", { 0, 1, 2, 3, 4, 6, 5 }
// CHECK:STDOUT: uselistorder ptr @_COk.Result.Core.8122a03446648385, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 7, 6, 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385", { 0, 3, 2, 1 }
// CHECK:STDOUT: uselistorder ptr @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385", { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 0, 1, 3, 2 }
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
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!8, !6}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = !{null, !7}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{null, !6}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{null, !8}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "Open", linkageName: "_COpen.Main", scope: null, file: !4, line: 3, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !30)
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !17, type: !6)
// CHECK:STDOUT: !22 = !DILocation(line: 4, column: 7, scope: !17)
// CHECK:STDOUT: !23 = !DILocation(line: 4, column: 6, scope: !17)
// CHECK:STDOUT: !25 = !DILocation(line: 4, column: 23, scope: !17)
// CHECK:STDOUT: !26 = !DILocation(line: 4, column: 16, scope: !17)
// CHECK:STDOUT: !28 = !DILocation(line: 5, column: 10, scope: !17)
// CHECK:STDOUT: !29 = !DILocation(line: 5, column: 3, scope: !17)
// CHECK:STDOUT: !30 = !{!18}
// CHECK:STDOUT: !31 = distinct !DISubprogram(name: "Basic", linkageName: "_CBasic.Main", scope: null, file: !4, line: 8, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !45)
// CHECK:STDOUT: !32 = !DILocalVariable(arg: 1, scope: !31, type: !6)
// CHECK:STDOUT: !36 = !DILocation(line: 9, column: 3, scope: !31)
// CHECK:STDOUT: !38 = !DILocation(line: 9, column: 16, scope: !31)
// CHECK:STDOUT: !39 = !{!8, !8}
// CHECK:STDOUT: !40 = !DISubroutineType(types: !39)
// CHECK:STDOUT: !42 = !DILocation(line: 10, column: 35, scope: !31)
// CHECK:STDOUT: !43 = !DILocation(line: 10, column: 10, scope: !31)
// CHECK:STDOUT: !44 = !DILocation(line: 10, column: 3, scope: !31)
// CHECK:STDOUT: !45 = !{!32}
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !4, line: 9, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !49)
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !46, type: !7)
// CHECK:STDOUT: !48 = !DILocation(line: 9, column: 16, scope: !46)
// CHECK:STDOUT: !49 = !{!47}
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 9, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !53)
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 1, scope: !50, type: !6)
// CHECK:STDOUT: !52 = !DILocation(line: 9, column: 16, scope: !50)
// CHECK:STDOUT: !53 = !{!51}
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !57)
// CHECK:STDOUT: !55 = !DILocalVariable(arg: 1, scope: !54, type: !8)
// CHECK:STDOUT: !56 = !DILocation(line: 9, column: 16, scope: !54)
// CHECK:STDOUT: !57 = !{!55}
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !61)
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !58, type: !8)
// CHECK:STDOUT: !60 = !DILocation(line: 9, column: 16, scope: !58)
// CHECK:STDOUT: !61 = !{!59}
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b63d267505e804f2:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !65)
// CHECK:STDOUT: !63 = !DILocalVariable(arg: 1, scope: !62, type: !8)
// CHECK:STDOUT: !64 = !DILocation(line: 9, column: 16, scope: !62)
// CHECK:STDOUT: !65 = !{!63}
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b63d267505e804f2:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !69)
// CHECK:STDOUT: !67 = !DILocalVariable(arg: 1, scope: !66, type: !8)
// CHECK:STDOUT: !68 = !DILocation(line: 9, column: 16, scope: !66)
// CHECK:STDOUT: !69 = !{!67}
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.88b1683142354768:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !73)
// CHECK:STDOUT: !71 = !DILocalVariable(arg: 1, scope: !70, type: !8)
// CHECK:STDOUT: !72 = !DILocation(line: 9, column: 16, scope: !70)
// CHECK:STDOUT: !73 = !{!71}
// CHECK:STDOUT: !74 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.88b1683142354768:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !77)
// CHECK:STDOUT: !75 = !DILocalVariable(arg: 1, scope: !74, type: !8)
// CHECK:STDOUT: !76 = !DILocation(line: 9, column: 16, scope: !74)
// CHECK:STDOUT: !77 = !{!75}
// CHECK:STDOUT: !78 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.32a8d72f0893b152:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !81)
// CHECK:STDOUT: !79 = !DILocalVariable(arg: 1, scope: !78, type: !8)
// CHECK:STDOUT: !80 = !DILocation(line: 9, column: 16, scope: !78)
// CHECK:STDOUT: !81 = !{!79}
// CHECK:STDOUT: !82 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.32a8d72f0893b152:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !85)
// CHECK:STDOUT: !83 = !DILocalVariable(arg: 1, scope: !82, type: !8)
// CHECK:STDOUT: !84 = !DILocation(line: 9, column: 16, scope: !82)
// CHECK:STDOUT: !85 = !{!83}
// CHECK:STDOUT: !86 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.bf4a066f5a5b60ea:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !89)
// CHECK:STDOUT: !87 = !DILocalVariable(arg: 1, scope: !86, type: !8)
// CHECK:STDOUT: !88 = !DILocation(line: 9, column: 16, scope: !86)
// CHECK:STDOUT: !89 = !{!87}
// CHECK:STDOUT: !90 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.bf4a066f5a5b60ea:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !93)
// CHECK:STDOUT: !91 = !DILocalVariable(arg: 1, scope: !90, type: !8)
// CHECK:STDOUT: !92 = !DILocation(line: 9, column: 16, scope: !90)
// CHECK:STDOUT: !93 = !{!91}
// CHECK:STDOUT: !94 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.f269577697e84b3c:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !97)
// CHECK:STDOUT: !95 = !DILocalVariable(arg: 1, scope: !94, type: !8)
// CHECK:STDOUT: !96 = !DILocation(line: 9, column: 16, scope: !94)
// CHECK:STDOUT: !97 = !{!95}
// CHECK:STDOUT: !98 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f269577697e84b3c:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !101)
// CHECK:STDOUT: !99 = !DILocalVariable(arg: 1, scope: !98, type: !8)
// CHECK:STDOUT: !100 = !DILocation(line: 9, column: 16, scope: !98)
// CHECK:STDOUT: !101 = !{!99}
// CHECK:STDOUT: !102 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.250f550470eb8844:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !105)
// CHECK:STDOUT: !103 = !DILocalVariable(arg: 1, scope: !102, type: !8)
// CHECK:STDOUT: !104 = !DILocation(line: 9, column: 16, scope: !102)
// CHECK:STDOUT: !105 = !{!103}
// CHECK:STDOUT: !106 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.250f550470eb8844:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !109)
// CHECK:STDOUT: !107 = !DILocalVariable(arg: 1, scope: !106, type: !8)
// CHECK:STDOUT: !108 = !DILocation(line: 9, column: 16, scope: !106)
// CHECK:STDOUT: !109 = !{!107}
// CHECK:STDOUT: !110 = distinct !DISubprogram(name: "Chain", linkageName: "_CChain.Main", scope: null, file: !4, line: 13, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !123)
// CHECK:STDOUT: !111 = !DILocalVariable(arg: 1, scope: !110, type: !6)
// CHECK:STDOUT: !115 = !DILocation(line: 14, column: 3, scope: !110)
// CHECK:STDOUT: !117 = !DILocation(line: 14, column: 21, scope: !110)
// CHECK:STDOUT: !118 = !DILocation(line: 14, column: 16, scope: !110)
// CHECK:STDOUT: !120 = !DILocation(line: 15, column: 35, scope: !110)
// CHECK:STDOUT: !121 = !DILocation(line: 15, column: 10, scope: !110)
// CHECK:STDOUT: !122 = !DILocation(line: 15, column: 3, scope: !110)
// CHECK:STDOUT: !123 = !{!111}
// CHECK:STDOUT: !124 = !DIFile(filename: "{{.*}}/prelude/types/result.carbon", directory: "")
// CHECK:STDOUT: !125 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.Result.Core.8122a03446648385", scope: null, file: !124, line: 28, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !129)
// CHECK:STDOUT: !126 = !DILocalVariable(arg: 1, scope: !125, type: !6)
// CHECK:STDOUT: !127 = !DILocation(line: 28, column: 1, scope: !125)
// CHECK:STDOUT: !128 = !DILocation(line: 29, column: 15, scope: !125)
// CHECK:STDOUT: !129 = !{!126}
// CHECK:STDOUT: !130 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.Result.Core.8122a03446648385", scope: null, file: !124, line: 28, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !133)
// CHECK:STDOUT: !131 = !DILocalVariable(arg: 1, scope: !130, type: !6)
// CHECK:STDOUT: !132 = !DILocation(line: 28, column: 1, scope: !130)
// CHECK:STDOUT: !133 = !{!131}
// CHECK:STDOUT: !134 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385", scope: null, file: !124, line: 42, type: !40, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !153)
// CHECK:STDOUT: !135 = !DILocalVariable(arg: 1, scope: !134, type: !8)
// CHECK:STDOUT: !140 = !DILocation(line: 44, column: 7, scope: !134)
// CHECK:STDOUT: !143 = !DILocation(line: 44, column: 34, scope: !134)
// CHECK:STDOUT: !144 = !DILocation(line: 44, column: 27, scope: !134)
// CHECK:STDOUT: !145 = !DILocation(line: 45, column: 7, scope: !134)
// CHECK:STDOUT: !148 = !DILocation(line: 45, column: 35, scope: !134)
// CHECK:STDOUT: !149 = !DILocation(line: 45, column: 28, scope: !134)
// CHECK:STDOUT: !151 = !DILocation(line: 49, column: 12, scope: !134)
// CHECK:STDOUT: !152 = !DILocation(line: 49, column: 5, scope: !134)
// CHECK:STDOUT: !153 = !{!135}
// CHECK:STDOUT: !154 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385", scope: null, file: !124, line: 51, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !162)
// CHECK:STDOUT: !155 = !DILocalVariable(arg: 1, scope: !154, type: !6)
// CHECK:STDOUT: !160 = !DILocation(line: 51, column: 39, scope: !154)
// CHECK:STDOUT: !161 = !DILocation(line: 51, column: 32, scope: !154)
// CHECK:STDOUT: !162 = !{!155}
// CHECK:STDOUT: !163 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !164 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.8122a03446648385", scope: null, file: !163, line: 21, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !168)
// CHECK:STDOUT: !165 = !DILocalVariable(arg: 1, scope: !164, type: !6)
// CHECK:STDOUT: !166 = !DILocation(line: 21, column: 1, scope: !164)
// CHECK:STDOUT: !167 = !DILocation(line: 22, column: 21, scope: !164)
// CHECK:STDOUT: !168 = !{!165}
// CHECK:STDOUT: !169 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.8122a03446648385", scope: null, file: !163, line: 21, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !172)
// CHECK:STDOUT: !170 = !DILocalVariable(arg: 1, scope: !169, type: !6)
// CHECK:STDOUT: !171 = !DILocation(line: 21, column: 1, scope: !169)
// CHECK:STDOUT: !172 = !{!170}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'unit.carbon'
// CHECK:STDOUT: source_filename = "unit.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Result.val.5d3.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @Result.val.21e.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @ControlFlow.val.787.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @ControlFlow.val.a52.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCheck.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !175 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call = icmp sgt i32 %n, 0, !dbg !180
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Greater.call, label %if.then, label %if.else, !dbg !181
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_COk.Result.Core.4771966b48d8bcbb(ptr %return), !dbg !182
// CHECK:STDOUT:   ret void, !dbg !185
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CErr.Result.Core.4771966b48d8bcbb(ptr %return, i32 %n), !dbg !187
// CHECK:STDOUT:   ret void, !dbg !188
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUnit.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !190 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_10.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !196
// CHECK:STDOUT:   %.loc9_11.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !196
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc9_10.1.temp), !dbg !196
// CHECK:STDOUT:   call void @_CCheck.Main(ptr %.loc9_10.1.temp, i32 %n), !dbg !196
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc9_11.1.temp), !dbg !196
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr %.loc9_11.1.temp, ptr %.loc9_10.1.temp), !dbg !196
// CHECK:STDOUT:   %.loc9_11.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc9_11.1.temp, i32 0, i32 0, !dbg !196
// CHECK:STDOUT:   %.loc9_11.6 = load i8, ptr %.loc9_11.5.discriminant, align 1, !dbg !196
// CHECK:STDOUT:   %.loc9_11.61 = trunc i8 %.loc9_11.6 to i1, !dbg !196
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc9_11.61, !dbg !196
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc9_11.1, label %.loc9_11.2, !dbg !196
// CHECK:STDOUT:
// CHECK:STDOUT: .loc9_11.1:                                       ; preds = %entry
// CHECK:STDOUT:   %.loc9_11.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc9_11.1.temp, i32 0, i32 1, !dbg !196
// CHECK:STDOUT:   %.loc9_11.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc9_11.9.payload, i32 0, i32 0, !dbg !196
// CHECK:STDOUT:   %tuple.elem0.loc9_11.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc9_11.10.Break, i32 0, i32 0, !dbg !196
// CHECK:STDOUT:   %.loc9_11.11 = load i32, ptr %tuple.elem0.loc9_11.1.tuple.elem, align 4, !dbg !196
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr %return, i32 %.loc9_11.11), !dbg !196
// CHECK:STDOUT:   call void @"_CSelfDestruct.19f0acf56e98f684:core.Destroy.Core"(ptr %.loc9_11.1.temp), !dbg !196
// CHECK:STDOUT:   call void @"_CSelfDestruct.610f3d0bf7b525c5:core.Destroy.Core"(ptr %.loc9_10.1.temp), !dbg !196
// CHECK:STDOUT:   ret void, !dbg !196
// CHECK:STDOUT:
// CHECK:STDOUT: .loc9_11.2:                                       ; preds = %entry
// CHECK:STDOUT:   %.loc9_11.13.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc9_11.1.temp, i32 0, i32 1, !dbg !196
// CHECK:STDOUT:   %.loc9_11.14.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc9_11.13.payload, i32 0, i32 0, !dbg !196
// CHECK:STDOUT:   %tuple.elem0.loc9_11.2.tuple.elem = getelementptr inbounds nuw { {} }, ptr %.loc9_11.14.Continue, i32 0, i32 0, !dbg !196
// CHECK:STDOUT:   call void @"_CSelfDestruct.19f0acf56e98f684:core.Destroy.Core"(ptr %.loc9_11.1.temp), !dbg !196
// CHECK:STDOUT:   call void @"_CSelfDestruct.610f3d0bf7b525c5:core.Destroy.Core"(ptr %.loc9_10.1.temp), !dbg !196
// CHECK:STDOUT:   call void @_COk.Result.Core.4771966b48d8bcbb(ptr %return), !dbg !197
// CHECK:STDOUT:   ret void, !dbg !198
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !200 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !202
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.61ea2aba74ab3bf1:core.Destroy.Core"(ptr %self) #0 !dbg !204 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !206
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.9fb0584d149a4ffd:core.Destroy.Core"(ptr %self) #0 !dbg !208 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { {} }, ptr %self, i32 0, i32 0, !dbg !210
// CHECK:STDOUT:   call void @"_CSelfDestruct.61ea2aba74ab3bf1:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !210
// CHECK:STDOUT:   ret void, !dbg !210
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.9fb0584d149a4ffd:core.Destroy.Core"(ptr %self) #0 !dbg !212 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.9fb0584d149a4ffd:core.Destroy.Core"(ptr %self), !dbg !214
// CHECK:STDOUT:   ret void, !dbg !214
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !216 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !218
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !220 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !222
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !222
// CHECK:STDOUT:   ret void, !dbg !222
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !224 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !226
// CHECK:STDOUT:   ret void, !dbg !226
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e4ccab8f99f8d8b8:core.Destroy.Core"(ptr %self) #0 !dbg !228 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !230
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e4ccab8f99f8d8b8:core.Destroy.Core"(ptr %self) #0 !dbg !232 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e4ccab8f99f8d8b8:core.Destroy.Core"(ptr %self), !dbg !234
// CHECK:STDOUT:   ret void, !dbg !234
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.d20fd035dcb84633:core.Destroy.Core"(ptr %self) #0 !dbg !236 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_11.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !238
// CHECK:STDOUT:   call void @"_CSelfDestruct.e4ccab8f99f8d8b8:core.Destroy.Core"(ptr %.loc9_11.1.payload), !dbg !238
// CHECK:STDOUT:   %.loc9_11.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !238
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc9_11.2.discriminant), !dbg !238
// CHECK:STDOUT:   ret void, !dbg !238
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d20fd035dcb84633:core.Destroy.Core"(ptr %self) #0 !dbg !240 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.d20fd035dcb84633:core.Destroy.Core"(ptr %self), !dbg !242
// CHECK:STDOUT:   ret void, !dbg !242
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.19f0acf56e98f684:core.Destroy.Core"(ptr %self) #0 !dbg !244 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !246
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.19f0acf56e98f684:core.Destroy.Core"(ptr %self) #0 !dbg !248 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.19f0acf56e98f684:core.Destroy.Core"(ptr %self), !dbg !250
// CHECK:STDOUT:   ret void, !dbg !250
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e9811e1a8e50fe8e:core.Destroy.Core"(ptr %self) #0 !dbg !252 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !254
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e9811e1a8e50fe8e:core.Destroy.Core"(ptr %self) #0 !dbg !256 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e9811e1a8e50fe8e:core.Destroy.Core"(ptr %self), !dbg !258
// CHECK:STDOUT:   ret void, !dbg !258
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.11dedd8bd98866ca:core.Destroy.Core"(ptr %self) #0 !dbg !260 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_10.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !262
// CHECK:STDOUT:   call void @"_CSelfDestruct.e9811e1a8e50fe8e:core.Destroy.Core"(ptr %.loc9_10.1.payload), !dbg !262
// CHECK:STDOUT:   %.loc9_10.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !262
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc9_10.2.discriminant), !dbg !262
// CHECK:STDOUT:   ret void, !dbg !262
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.11dedd8bd98866ca:core.Destroy.Core"(ptr %self) #0 !dbg !264 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.11dedd8bd98866ca:core.Destroy.Core"(ptr %self), !dbg !266
// CHECK:STDOUT:   ret void, !dbg !266
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.610f3d0bf7b525c5:core.Destroy.Core"(ptr %self) #0 !dbg !268 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !270
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.610f3d0bf7b525c5:core.Destroy.Core"(ptr %self) #0 !dbg !272 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.610f3d0bf7b525c5:core.Destroy.Core"(ptr %self), !dbg !274
// CHECK:STDOUT:   ret void, !dbg !274
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.Result.Core.4771966b48d8bcbb(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !276 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !277
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !277
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !277
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Result.val.5d3.anon, i64 8, i1 false), !dbg !277
// CHECK:STDOUT:   store { {} } poison, ptr %Ok, align 1, !dbg !277
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Ok, i32 0, i32 0, !dbg !278
// CHECK:STDOUT:   ret void, !dbg !277
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.Result.Core.4771966b48d8bcbb(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !279 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !281
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !281
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !281
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !281
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Result.val.21e.anon, i64 8, i1 false), !dbg !281
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Err, align 4, !dbg !281
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !281
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !281
// CHECK:STDOUT:   ret void, !dbg !281
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !283 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !289
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !289
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !289
// CHECK:STDOUT:   %3 = icmp eq i1 false, %2, !dbg !289
// CHECK:STDOUT:   br i1 %3, label %4, label %5, !dbg !289
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !289
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !289
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Ok, i32 0, i32 0, !dbg !289
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.4771966b48d8bcbb(ptr %return), !dbg !292
// CHECK:STDOUT:   ret void, !dbg !293
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %0
// CHECK:STDOUT:   %discriminant1 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !294
// CHECK:STDOUT:   %6 = load i8, ptr %discriminant1, align 1, !dbg !294
// CHECK:STDOUT:   %7 = trunc i8 %6 to i1, !dbg !294
// CHECK:STDOUT:   %8 = icmp eq i1 true, %7, !dbg !294
// CHECK:STDOUT:   br i1 %8, label %9, label %11, !dbg !294
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %5
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !294
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload2, i32 0, i32 0, !dbg !294
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !294
// CHECK:STDOUT:   %10 = load i32, ptr %tuple.elem3, align 4, !dbg !294
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.4771966b48d8bcbb(ptr %return, i32 %10), !dbg !297
// CHECK:STDOUT:   ret void, !dbg !298
// CHECK:STDOUT:
// CHECK:STDOUT: 11:                                               ; preds = %5
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr %return, ptr %self), !dbg !300
// CHECK:STDOUT:   ret void, !dbg !301
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %b) #0 !dbg !303 {
// CHECK:STDOUT:   call void @_CErr.Result.Core.4771966b48d8bcbb(ptr %return, i32 %b), !dbg !309
// CHECK:STDOUT:   ret void, !dbg !310
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.4771966b48d8bcbb(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !312 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !313
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !313
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !313
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.787.anon, i64 8, i1 false), !dbg !313
// CHECK:STDOUT:   store { {} } poison, ptr %Continue, align 1, !dbg !313
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Continue, i32 0, i32 0, !dbg !314
// CHECK:STDOUT:   ret void, !dbg !313
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.4771966b48d8bcbb(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !315 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !317
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !317
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !317
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !317
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.a52.anon, i64 8, i1 false), !dbg !317
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !317
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !317
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !317
// CHECK:STDOUT:   ret void, !dbg !317
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.19f0acf56e98f684:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.610f3d0bf7b525c5:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_COk.Result.Core.4771966b48d8bcbb, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 0, 1, 3, 2 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!174}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!8, !6}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = !{null, !7}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{null, !6}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{null, !8}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !39 = !{!8, !8}
// CHECK:STDOUT: !40 = !DISubroutineType(types: !39)
// CHECK:STDOUT: !124 = !DIFile(filename: "{{.*}}/prelude/types/result.carbon", directory: "")
// CHECK:STDOUT: !163 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !173 = !DIFile(filename: "unit.carbon", directory: "")
// CHECK:STDOUT: !174 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !173, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !175 = distinct !DISubprogram(name: "Check", linkageName: "_CCheck.Main", scope: null, file: !173, line: 3, type: !10, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !189)
// CHECK:STDOUT: !176 = !DILocalVariable(arg: 1, scope: !175, type: !6)
// CHECK:STDOUT: !180 = !DILocation(line: 4, column: 7, scope: !175)
// CHECK:STDOUT: !181 = !DILocation(line: 4, column: 6, scope: !175)
// CHECK:STDOUT: !182 = !DILocation(line: 4, column: 23, scope: !175)
// CHECK:STDOUT: !183 = !{!8}
// CHECK:STDOUT: !184 = !DISubroutineType(types: !183)
// CHECK:STDOUT: !185 = !DILocation(line: 4, column: 16, scope: !175)
// CHECK:STDOUT: !187 = !DILocation(line: 5, column: 10, scope: !175)
// CHECK:STDOUT: !188 = !DILocation(line: 5, column: 3, scope: !175)
// CHECK:STDOUT: !189 = !{!176}
// CHECK:STDOUT: !190 = distinct !DISubprogram(name: "Unit", linkageName: "_CUnit.Main", scope: null, file: !173, line: 8, type: !10, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !199)
// CHECK:STDOUT: !191 = !DILocalVariable(arg: 1, scope: !190, type: !6)
// CHECK:STDOUT: !196 = !DILocation(line: 9, column: 3, scope: !190)
// CHECK:STDOUT: !197 = !DILocation(line: 10, column: 10, scope: !190)
// CHECK:STDOUT: !198 = !DILocation(line: 10, column: 3, scope: !190)
// CHECK:STDOUT: !199 = !{!191}
// CHECK:STDOUT: !200 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !173, line: 9, type: !12, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !203)
// CHECK:STDOUT: !201 = !DILocalVariable(arg: 1, scope: !200, type: !7)
// CHECK:STDOUT: !202 = !DILocation(line: 9, column: 3, scope: !200)
// CHECK:STDOUT: !203 = !{!201}
// CHECK:STDOUT: !204 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.61ea2aba74ab3bf1:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !207)
// CHECK:STDOUT: !205 = !DILocalVariable(arg: 1, scope: !204, type: !8)
// CHECK:STDOUT: !206 = !DILocation(line: 9, column: 3, scope: !204)
// CHECK:STDOUT: !207 = !{!205}
// CHECK:STDOUT: !208 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.9fb0584d149a4ffd:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !211)
// CHECK:STDOUT: !209 = !DILocalVariable(arg: 1, scope: !208, type: !8)
// CHECK:STDOUT: !210 = !DILocation(line: 9, column: 3, scope: !208)
// CHECK:STDOUT: !211 = !{!209}
// CHECK:STDOUT: !212 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.9fb0584d149a4ffd:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !215)
// CHECK:STDOUT: !213 = !DILocalVariable(arg: 1, scope: !212, type: !8)
// CHECK:STDOUT: !214 = !DILocation(line: 9, column: 3, scope: !212)
// CHECK:STDOUT: !215 = !{!213}
// CHECK:STDOUT: !216 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !173, line: 9, type: !14, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !219)
// CHECK:STDOUT: !217 = !DILocalVariable(arg: 1, scope: !216, type: !6)
// CHECK:STDOUT: !218 = !DILocation(line: 9, column: 3, scope: !216)
// CHECK:STDOUT: !219 = !{!217}
// CHECK:STDOUT: !220 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !223)
// CHECK:STDOUT: !221 = !DILocalVariable(arg: 1, scope: !220, type: !8)
// CHECK:STDOUT: !222 = !DILocation(line: 9, column: 3, scope: !220)
// CHECK:STDOUT: !223 = !{!221}
// CHECK:STDOUT: !224 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !227)
// CHECK:STDOUT: !225 = !DILocalVariable(arg: 1, scope: !224, type: !8)
// CHECK:STDOUT: !226 = !DILocation(line: 9, column: 3, scope: !224)
// CHECK:STDOUT: !227 = !{!225}
// CHECK:STDOUT: !228 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e4ccab8f99f8d8b8:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !231)
// CHECK:STDOUT: !229 = !DILocalVariable(arg: 1, scope: !228, type: !8)
// CHECK:STDOUT: !230 = !DILocation(line: 9, column: 3, scope: !228)
// CHECK:STDOUT: !231 = !{!229}
// CHECK:STDOUT: !232 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e4ccab8f99f8d8b8:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !235)
// CHECK:STDOUT: !233 = !DILocalVariable(arg: 1, scope: !232, type: !8)
// CHECK:STDOUT: !234 = !DILocation(line: 9, column: 3, scope: !232)
// CHECK:STDOUT: !235 = !{!233}
// CHECK:STDOUT: !236 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.d20fd035dcb84633:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !239)
// CHECK:STDOUT: !237 = !DILocalVariable(arg: 1, scope: !236, type: !8)
// CHECK:STDOUT: !238 = !DILocation(line: 9, column: 3, scope: !236)
// CHECK:STDOUT: !239 = !{!237}
// CHECK:STDOUT: !240 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d20fd035dcb84633:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !243)
// CHECK:STDOUT: !241 = !DILocalVariable(arg: 1, scope: !240, type: !8)
// CHECK:STDOUT: !242 = !DILocation(line: 9, column: 3, scope: !240)
// CHECK:STDOUT: !243 = !{!241}
// CHECK:STDOUT: !244 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.19f0acf56e98f684:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !247)
// CHECK:STDOUT: !245 = !DILocalVariable(arg: 1, scope: !244, type: !8)
// CHECK:STDOUT: !246 = !DILocation(line: 9, column: 3, scope: !244)
// CHECK:STDOUT: !247 = !{!245}
// CHECK:STDOUT: !248 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.19f0acf56e98f684:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !251)
// CHECK:STDOUT: !249 = !DILocalVariable(arg: 1, scope: !248, type: !8)
// CHECK:STDOUT: !250 = !DILocation(line: 9, column: 3, scope: !248)
// CHECK:STDOUT: !251 = !{!249}
// CHECK:STDOUT: !252 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e9811e1a8e50fe8e:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !255)
// CHECK:STDOUT: !253 = !DILocalVariable(arg: 1, scope: !252, type: !8)
// CHECK:STDOUT: !254 = !DILocation(line: 9, column: 3, scope: !252)
// CHECK:STDOUT: !255 = !{!253}
// CHECK:STDOUT: !256 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e9811e1a8e50fe8e:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !259)
// CHECK:STDOUT: !257 = !DILocalVariable(arg: 1, scope: !256, type: !8)
// CHECK:STDOUT: !258 = !DILocation(line: 9, column: 3, scope: !256)
// CHECK:STDOUT: !259 = !{!257}
// CHECK:STDOUT: !260 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.11dedd8bd98866ca:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !263)
// CHECK:STDOUT: !261 = !DILocalVariable(arg: 1, scope: !260, type: !8)
// CHECK:STDOUT: !262 = !DILocation(line: 9, column: 3, scope: !260)
// CHECK:STDOUT: !263 = !{!261}
// CHECK:STDOUT: !264 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.11dedd8bd98866ca:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !267)
// CHECK:STDOUT: !265 = !DILocalVariable(arg: 1, scope: !264, type: !8)
// CHECK:STDOUT: !266 = !DILocation(line: 9, column: 3, scope: !264)
// CHECK:STDOUT: !267 = !{!265}
// CHECK:STDOUT: !268 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.610f3d0bf7b525c5:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !271)
// CHECK:STDOUT: !269 = !DILocalVariable(arg: 1, scope: !268, type: !8)
// CHECK:STDOUT: !270 = !DILocation(line: 9, column: 3, scope: !268)
// CHECK:STDOUT: !271 = !{!269}
// CHECK:STDOUT: !272 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.610f3d0bf7b525c5:core.Destroy.Core", scope: null, file: !173, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !275)
// CHECK:STDOUT: !273 = !DILocalVariable(arg: 1, scope: !272, type: !8)
// CHECK:STDOUT: !274 = !DILocation(line: 9, column: 3, scope: !272)
// CHECK:STDOUT: !275 = !{!273}
// CHECK:STDOUT: !276 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.Result.Core.4771966b48d8bcbb", scope: null, file: !124, line: 28, type: !184, spFlags: DISPFlagDefinition, unit: !174)
// CHECK:STDOUT: !277 = !DILocation(line: 28, column: 1, scope: !276)
// CHECK:STDOUT: !278 = !DILocation(line: 29, column: 15, scope: !276)
// CHECK:STDOUT: !279 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.Result.Core.4771966b48d8bcbb", scope: null, file: !124, line: 28, type: !10, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !282)
// CHECK:STDOUT: !280 = !DILocalVariable(arg: 1, scope: !279, type: !6)
// CHECK:STDOUT: !281 = !DILocation(line: 28, column: 1, scope: !279)
// CHECK:STDOUT: !282 = !{!280}
// CHECK:STDOUT: !283 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb", scope: null, file: !124, line: 42, type: !40, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !302)
// CHECK:STDOUT: !284 = !DILocalVariable(arg: 1, scope: !283, type: !8)
// CHECK:STDOUT: !289 = !DILocation(line: 44, column: 7, scope: !283)
// CHECK:STDOUT: !292 = !DILocation(line: 44, column: 34, scope: !283)
// CHECK:STDOUT: !293 = !DILocation(line: 44, column: 27, scope: !283)
// CHECK:STDOUT: !294 = !DILocation(line: 45, column: 7, scope: !283)
// CHECK:STDOUT: !297 = !DILocation(line: 45, column: 35, scope: !283)
// CHECK:STDOUT: !298 = !DILocation(line: 45, column: 28, scope: !283)
// CHECK:STDOUT: !300 = !DILocation(line: 49, column: 12, scope: !283)
// CHECK:STDOUT: !301 = !DILocation(line: 49, column: 5, scope: !283)
// CHECK:STDOUT: !302 = !{!284}
// CHECK:STDOUT: !303 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb", scope: null, file: !124, line: 51, type: !10, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !311)
// CHECK:STDOUT: !304 = !DILocalVariable(arg: 1, scope: !303, type: !6)
// CHECK:STDOUT: !309 = !DILocation(line: 51, column: 39, scope: !303)
// CHECK:STDOUT: !310 = !DILocation(line: 51, column: 32, scope: !303)
// CHECK:STDOUT: !311 = !{!304}
// CHECK:STDOUT: !312 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.4771966b48d8bcbb", scope: null, file: !163, line: 21, type: !184, spFlags: DISPFlagDefinition, unit: !174)
// CHECK:STDOUT: !313 = !DILocation(line: 21, column: 1, scope: !312)
// CHECK:STDOUT: !314 = !DILocation(line: 22, column: 21, scope: !312)
// CHECK:STDOUT: !315 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.4771966b48d8bcbb", scope: null, file: !163, line: 21, type: !10, spFlags: DISPFlagDefinition, unit: !174, retainedNodes: !318)
// CHECK:STDOUT: !316 = !DILocalVariable(arg: 1, scope: !315, type: !6)
// CHECK:STDOUT: !317 = !DILocation(line: 21, column: 1, scope: !315)
// CHECK:STDOUT: !318 = !{!316}
// CHECK:STDOUT:

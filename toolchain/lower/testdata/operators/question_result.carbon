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
// CHECK:STDOUT: define void @_COpen.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call = icmp sgt i32 %n, 0, !dbg !11
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Greater.call, label %if.then, label %if.else, !dbg !12
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_COk.Result.Core.8122a03446648385(ptr %return, i32 %n), !dbg !13
// CHECK:STDOUT:   ret void, !dbg !14
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CErr.Result.Core.8122a03446648385(ptr %return, i32 %n), !dbg !15
// CHECK:STDOUT:   ret void, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CBasic.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %f.var = alloca i32, align 4, !dbg !20
// CHECK:STDOUT:   %.loc9_22.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !21
// CHECK:STDOUT:   %.loc9_23.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !21
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %f.var), !dbg !20
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc9_22.1.temp), !dbg !21
// CHECK:STDOUT:   call void @_COpen.Main(ptr %.loc9_22.1.temp, i32 %n), !dbg !21
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc9_23.1.temp), !dbg !21
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr %.loc9_23.1.temp, ptr %.loc9_22.1.temp), !dbg !21
// CHECK:STDOUT:   %.loc9_23.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc9_23.1.temp, i32 0, i32 0, !dbg !21
// CHECK:STDOUT:   %.loc9_23.6 = load i8, ptr %.loc9_23.5.discriminant, align 1, !dbg !21
// CHECK:STDOUT:   %.loc9_23.61 = trunc i8 %.loc9_23.6 to i1, !dbg !21
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc9_23.61, !dbg !21
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc9_23.1, label %.loc9_23.2, !dbg !21
// CHECK:STDOUT:
// CHECK:STDOUT: .loc9_23.1:                                       ; preds = %entry
// CHECK:STDOUT:   %.loc9_23.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc9_23.1.temp, i32 0, i32 1, !dbg !21
// CHECK:STDOUT:   %.loc9_23.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc9_23.9.payload, i32 0, i32 0, !dbg !21
// CHECK:STDOUT:   %tuple.elem0.loc9_23.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc9_23.10.Break, i32 0, i32 0, !dbg !21
// CHECK:STDOUT:   %.loc9_23.11 = load i32, ptr %tuple.elem0.loc9_23.1.tuple.elem, align 4, !dbg !21
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr %return, i32 %.loc9_23.11), !dbg !21
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc9_23.1.temp), !dbg !21
// CHECK:STDOUT:   call void @"_COp.a2d6f61a16c0bf26:core.Destroy.Core"(ptr %.loc9_22.1.temp), !dbg !21
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %f.var), !dbg !20
// CHECK:STDOUT:   ret void, !dbg !21
// CHECK:STDOUT:
// CHECK:STDOUT: .loc9_23.2:                                       ; preds = %entry
// CHECK:STDOUT:   %.loc9_23.13.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc9_23.1.temp, i32 0, i32 1, !dbg !21
// CHECK:STDOUT:   %.loc9_23.14.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc9_23.13.payload, i32 0, i32 0, !dbg !21
// CHECK:STDOUT:   %tuple.elem0.loc9_23.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc9_23.14.Continue, i32 0, i32 0, !dbg !21
// CHECK:STDOUT:   %.loc9_23.15 = load i32, ptr %tuple.elem0.loc9_23.2.tuple.elem, align 4, !dbg !21
// CHECK:STDOUT:   store i32 %.loc9_23.15, ptr %f.var, align 4, !dbg !20
// CHECK:STDOUT:   %.loc10_35 = load i32, ptr %f.var, align 4, !dbg !22
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc10_35, 1, !dbg !22
// CHECK:STDOUT:   call void @_COk.Result.Core.8122a03446648385(ptr %return, i32 %Int.as.AddWith.impl.Op.call), !dbg !23
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc9_23.1.temp), !dbg !21
// CHECK:STDOUT:   call void @"_COp.a2d6f61a16c0bf26:core.Destroy.Core"(ptr %.loc9_22.1.temp), !dbg !21
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %f.var), !dbg !20
// CHECK:STDOUT:   ret void, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.945345cbed56cb88:core.Destroy.Core"(ptr %self) #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !37
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.216a6481b641f07b:core.Destroy.Core"(ptr %self) #0 !dbg !38 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.39976c684c12c16f:core.Destroy.Core"(ptr %self) #0 !dbg !44 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !47
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.6f70ad92790b7b3d:core.Destroy.Core"(ptr %self) #0 !dbg !48 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %self) #0 !dbg !52 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5716d9c282b70019:core.Destroy.Core"(ptr %self) #0 !dbg !56 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.c9ead255f32e7c59:core.Destroy.Core"(ptr %self) #0 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !63
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.a2d6f61a16c0bf26:core.Destroy.Core"(ptr %self) #0 !dbg !64 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !67
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CChain.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !68 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %t.var = alloca i32, align 4, !dbg !71
// CHECK:STDOUT:   %.loc14_27.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !72
// CHECK:STDOUT:   %.loc14_28.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !72
// CHECK:STDOUT:   %.loc14_29.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !73
// CHECK:STDOUT:   %.loc14_30.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !73
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %t.var), !dbg !71
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc14_27.1.temp), !dbg !72
// CHECK:STDOUT:   call void @_COpen.Main(ptr %.loc14_27.1.temp, i32 %n), !dbg !72
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc14_28.1.temp), !dbg !72
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr %.loc14_28.1.temp, ptr %.loc14_27.1.temp), !dbg !72
// CHECK:STDOUT:   %.loc14_28.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc14_28.1.temp, i32 0, i32 0, !dbg !72
// CHECK:STDOUT:   %.loc14_28.6 = load i8, ptr %.loc14_28.5.discriminant, align 1, !dbg !72
// CHECK:STDOUT:   %.loc14_28.61 = trunc i8 %.loc14_28.6 to i1, !dbg !72
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc14_28 = icmp eq i1 true, %.loc14_28.61, !dbg !72
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc14_28, label %.loc14_28.1, label %.loc14_28.2, !dbg !72
// CHECK:STDOUT:
// CHECK:STDOUT: .loc14_28.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc14_28.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc14_28.1.temp, i32 0, i32 1, !dbg !72
// CHECK:STDOUT:   %.loc14_28.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc14_28.9.payload, i32 0, i32 0, !dbg !72
// CHECK:STDOUT:   %tuple.elem0.loc14_28.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc14_28.10.Break, i32 0, i32 0, !dbg !72
// CHECK:STDOUT:   %.loc14_28.11 = load i32, ptr %tuple.elem0.loc14_28.1.tuple.elem, align 4, !dbg !72
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr %return, i32 %.loc14_28.11), !dbg !72
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc14_28.1.temp), !dbg !72
// CHECK:STDOUT:   call void @"_COp.a2d6f61a16c0bf26:core.Destroy.Core"(ptr %.loc14_27.1.temp), !dbg !72
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %t.var), !dbg !71
// CHECK:STDOUT:   ret void, !dbg !72
// CHECK:STDOUT:
// CHECK:STDOUT: .loc14_28.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc14_28.13.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc14_28.1.temp, i32 0, i32 1, !dbg !72
// CHECK:STDOUT:   %.loc14_28.14.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc14_28.13.payload, i32 0, i32 0, !dbg !72
// CHECK:STDOUT:   %tuple.elem0.loc14_28.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc14_28.14.Continue, i32 0, i32 0, !dbg !72
// CHECK:STDOUT:   %.loc14_28.15 = load i32, ptr %tuple.elem0.loc14_28.2.tuple.elem, align 4, !dbg !72
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc14_29.1.temp), !dbg !73
// CHECK:STDOUT:   call void @_COpen.Main(ptr %.loc14_29.1.temp, i32 %.loc14_28.15), !dbg !73
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc14_30.1.temp), !dbg !73
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr %.loc14_30.1.temp, ptr %.loc14_29.1.temp), !dbg !73
// CHECK:STDOUT:   %.loc14_30.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc14_30.1.temp, i32 0, i32 0, !dbg !73
// CHECK:STDOUT:   %.loc14_30.6 = load i8, ptr %.loc14_30.5.discriminant, align 1, !dbg !73
// CHECK:STDOUT:   %.loc14_30.62 = trunc i8 %.loc14_30.6 to i1, !dbg !73
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc14_30 = icmp eq i1 true, %.loc14_30.62, !dbg !73
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc14_30, label %.loc14_30.1, label %.loc14_30.2, !dbg !73
// CHECK:STDOUT:
// CHECK:STDOUT: .loc14_30.1:                                      ; preds = %.loc14_28.2
// CHECK:STDOUT:   %.loc14_30.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc14_30.1.temp, i32 0, i32 1, !dbg !73
// CHECK:STDOUT:   %.loc14_30.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc14_30.9.payload, i32 0, i32 0, !dbg !73
// CHECK:STDOUT:   %tuple.elem0.loc14_30.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc14_30.10.Break, i32 0, i32 0, !dbg !73
// CHECK:STDOUT:   %.loc14_30.11 = load i32, ptr %tuple.elem0.loc14_30.1.tuple.elem, align 4, !dbg !73
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr %return, i32 %.loc14_30.11), !dbg !73
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc14_30.1.temp), !dbg !73
// CHECK:STDOUT:   call void @"_COp.a2d6f61a16c0bf26:core.Destroy.Core"(ptr %.loc14_29.1.temp), !dbg !73
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc14_28.1.temp), !dbg !72
// CHECK:STDOUT:   call void @"_COp.a2d6f61a16c0bf26:core.Destroy.Core"(ptr %.loc14_27.1.temp), !dbg !72
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %t.var), !dbg !71
// CHECK:STDOUT:   ret void, !dbg !73
// CHECK:STDOUT:
// CHECK:STDOUT: .loc14_30.2:                                      ; preds = %.loc14_28.2
// CHECK:STDOUT:   %.loc14_30.13.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc14_30.1.temp, i32 0, i32 1, !dbg !73
// CHECK:STDOUT:   %.loc14_30.14.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc14_30.13.payload, i32 0, i32 0, !dbg !73
// CHECK:STDOUT:   %tuple.elem0.loc14_30.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc14_30.14.Continue, i32 0, i32 0, !dbg !73
// CHECK:STDOUT:   %.loc14_30.15 = load i32, ptr %tuple.elem0.loc14_30.2.tuple.elem, align 4, !dbg !73
// CHECK:STDOUT:   store i32 %.loc14_30.15, ptr %t.var, align 4, !dbg !71
// CHECK:STDOUT:   %.loc15_35 = load i32, ptr %t.var, align 4, !dbg !74
// CHECK:STDOUT:   call void @_COk.Result.Core.8122a03446648385(ptr %return, i32 %.loc15_35), !dbg !75
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc14_30.1.temp), !dbg !73
// CHECK:STDOUT:   call void @"_COp.a2d6f61a16c0bf26:core.Destroy.Core"(ptr %.loc14_29.1.temp), !dbg !73
// CHECK:STDOUT:   call void @"_COp.51939fc15d8db062:core.Destroy.Core"(ptr %.loc14_28.1.temp), !dbg !72
// CHECK:STDOUT:   call void @"_COp.a2d6f61a16c0bf26:core.Destroy.Core"(ptr %.loc14_27.1.temp), !dbg !72
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %t.var), !dbg !71
// CHECK:STDOUT:   ret void, !dbg !76
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.Result.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !77 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !81
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !81
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !81
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !82
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Result.val.ad4.anon, i64 8, i1 false), !dbg !81
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Ok, align 4, !dbg !81
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Ok, i32 0, i32 0, !dbg !82
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !82
// CHECK:STDOUT:   ret void, !dbg !81
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.Result.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !83 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !86
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !86
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !86
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !86
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Result.val.d4e.anon, i64 8, i1 false), !dbg !86
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Err, align 4, !dbg !86
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !86
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !86
// CHECK:STDOUT:   ret void, !dbg !86
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !87 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !92
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !92
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !92
// CHECK:STDOUT:   %3 = icmp eq i1 false, %2, !dbg !92
// CHECK:STDOUT:   br i1 %3, label %4, label %6, !dbg !92
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !92
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !92
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Ok, i32 0, i32 0, !dbg !92
// CHECK:STDOUT:   %5 = load i32, ptr %tuple.elem, align 4, !dbg !92
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.8122a03446648385(ptr %return, i32 %5), !dbg !93
// CHECK:STDOUT:   ret void, !dbg !94
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %0
// CHECK:STDOUT:   %discriminant1 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !95
// CHECK:STDOUT:   %7 = load i8, ptr %discriminant1, align 1, !dbg !95
// CHECK:STDOUT:   %8 = trunc i8 %7 to i1, !dbg !95
// CHECK:STDOUT:   %9 = icmp eq i1 true, %8, !dbg !95
// CHECK:STDOUT:   br i1 %9, label %10, label %12, !dbg !95
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %6
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !95
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload2, i32 0, i32 0, !dbg !95
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !95
// CHECK:STDOUT:   %11 = load i32, ptr %tuple.elem3, align 4, !dbg !95
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.8122a03446648385(ptr %return, i32 %11), !dbg !96
// CHECK:STDOUT:   ret void, !dbg !97
// CHECK:STDOUT:
// CHECK:STDOUT: 12:                                               ; preds = %6
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr %return, ptr %self), !dbg !98
// CHECK:STDOUT:   ret void, !dbg !99
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %b) #0 !dbg !100 {
// CHECK:STDOUT:   call void @_CErr.Result.Core.8122a03446648385(ptr %return, i32 %b), !dbg !103
// CHECK:STDOUT:   ret void, !dbg !104
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !105 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !109
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !109
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !109
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !110
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.f6c.anon, i64 8, i1 false), !dbg !109
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !109
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !110
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !110
// CHECK:STDOUT:   ret void, !dbg !109
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !111 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !114
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !114
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !114
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !114
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.493.anon, i64 8, i1 false), !dbg !114
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !114
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !114
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !114
// CHECK:STDOUT:   ret void, !dbg !114
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_COp.70db2d92ffddbef7:core.Destroy.Core", { 0, 1, 2, 4, 3 }
// CHECK:STDOUT: uselistorder ptr @"_COp.51939fc15d8db062:core.Destroy.Core", { 0, 1, 2, 3, 4, 6, 5 }
// CHECK:STDOUT: uselistorder ptr @"_COp.a2d6f61a16c0bf26:core.Destroy.Core", { 0, 1, 2, 3, 4, 6, 5 }
// CHECK:STDOUT: uselistorder ptr @_COk.Result.Core.8122a03446648385, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 7, 6, 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385", { 0, 3, 2, 1 }
// CHECK:STDOUT: uselistorder ptr @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385", { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 0, 1, 3, 2 }
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
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Open", linkageName: "_COpen.Main", scope: null, file: !1, line: 3, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 4, column: 7, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 4, column: 6, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 4, column: 23, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 4, column: 16, scope: !4)
// CHECK:STDOUT: !15 = !DILocation(line: 5, column: 10, scope: !4)
// CHECK:STDOUT: !16 = !DILocation(line: 5, column: 3, scope: !4)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "Basic", linkageName: "_CBasic.Main", scope: null, file: !1, line: 8, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !18)
// CHECK:STDOUT: !18 = !{!19}
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 1, scope: !17, type: !8)
// CHECK:STDOUT: !20 = !DILocation(line: 9, column: 3, scope: !17)
// CHECK:STDOUT: !21 = !DILocation(line: 9, column: 16, scope: !17)
// CHECK:STDOUT: !22 = !DILocation(line: 10, column: 35, scope: !17)
// CHECK:STDOUT: !23 = !DILocation(line: 10, column: 10, scope: !17)
// CHECK:STDOUT: !24 = !DILocation(line: 10, column: 3, scope: !17)
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "Op", linkageName: "_COp.945345cbed56cb88:core.Destroy.Core", scope: null, file: !1, line: 9, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !29)
// CHECK:STDOUT: !26 = !DISubroutineType(types: !27)
// CHECK:STDOUT: !27 = !{null, !28}
// CHECK:STDOUT: !28 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !29 = !{!30}
// CHECK:STDOUT: !30 = !DILocalVariable(arg: 1, scope: !25, type: !28)
// CHECK:STDOUT: !31 = !DILocation(line: 9, column: 16, scope: !25)
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 9, type: !33, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !35)
// CHECK:STDOUT: !33 = !DISubroutineType(types: !34)
// CHECK:STDOUT: !34 = !{null, !8}
// CHECK:STDOUT: !35 = !{!36}
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !32, type: !8)
// CHECK:STDOUT: !37 = !DILocation(line: 9, column: 16, scope: !32)
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "Op", linkageName: "_COp.216a6481b641f07b:core.Destroy.Core", scope: null, file: !1, line: 9, type: !39, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !41)
// CHECK:STDOUT: !39 = !DISubroutineType(types: !40)
// CHECK:STDOUT: !40 = !{null, !7}
// CHECK:STDOUT: !41 = !{!42}
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !38, type: !7)
// CHECK:STDOUT: !43 = !DILocation(line: 9, column: 16, scope: !38)
// CHECK:STDOUT: !44 = distinct !DISubprogram(name: "Op", linkageName: "_COp.39976c684c12c16f:core.Destroy.Core", scope: null, file: !1, line: 9, type: !39, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !45)
// CHECK:STDOUT: !45 = !{!46}
// CHECK:STDOUT: !46 = !DILocalVariable(arg: 1, scope: !44, type: !7)
// CHECK:STDOUT: !47 = !DILocation(line: 9, column: 16, scope: !44)
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "Op", linkageName: "_COp.6f70ad92790b7b3d:core.Destroy.Core", scope: null, file: !1, line: 9, type: !39, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !49)
// CHECK:STDOUT: !49 = !{!50}
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !48, type: !7)
// CHECK:STDOUT: !51 = !DILocation(line: 9, column: 16, scope: !48)
// CHECK:STDOUT: !52 = distinct !DISubprogram(name: "Op", linkageName: "_COp.51939fc15d8db062:core.Destroy.Core", scope: null, file: !1, line: 9, type: !39, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !53)
// CHECK:STDOUT: !53 = !{!54}
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !52, type: !7)
// CHECK:STDOUT: !55 = !DILocation(line: 9, column: 16, scope: !52)
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5716d9c282b70019:core.Destroy.Core", scope: null, file: !1, line: 9, type: !39, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !57)
// CHECK:STDOUT: !57 = !{!58}
// CHECK:STDOUT: !58 = !DILocalVariable(arg: 1, scope: !56, type: !7)
// CHECK:STDOUT: !59 = !DILocation(line: 9, column: 16, scope: !56)
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "Op", linkageName: "_COp.c9ead255f32e7c59:core.Destroy.Core", scope: null, file: !1, line: 9, type: !39, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !61)
// CHECK:STDOUT: !61 = !{!62}
// CHECK:STDOUT: !62 = !DILocalVariable(arg: 1, scope: !60, type: !7)
// CHECK:STDOUT: !63 = !DILocation(line: 9, column: 16, scope: !60)
// CHECK:STDOUT: !64 = distinct !DISubprogram(name: "Op", linkageName: "_COp.a2d6f61a16c0bf26:core.Destroy.Core", scope: null, file: !1, line: 9, type: !39, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !65)
// CHECK:STDOUT: !65 = !{!66}
// CHECK:STDOUT: !66 = !DILocalVariable(arg: 1, scope: !64, type: !7)
// CHECK:STDOUT: !67 = !DILocation(line: 9, column: 16, scope: !64)
// CHECK:STDOUT: !68 = distinct !DISubprogram(name: "Chain", linkageName: "_CChain.Main", scope: null, file: !1, line: 13, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !69)
// CHECK:STDOUT: !69 = !{!70}
// CHECK:STDOUT: !70 = !DILocalVariable(arg: 1, scope: !68, type: !8)
// CHECK:STDOUT: !71 = !DILocation(line: 14, column: 3, scope: !68)
// CHECK:STDOUT: !72 = !DILocation(line: 14, column: 21, scope: !68)
// CHECK:STDOUT: !73 = !DILocation(line: 14, column: 16, scope: !68)
// CHECK:STDOUT: !74 = !DILocation(line: 15, column: 35, scope: !68)
// CHECK:STDOUT: !75 = !DILocation(line: 15, column: 10, scope: !68)
// CHECK:STDOUT: !76 = !DILocation(line: 15, column: 3, scope: !68)
// CHECK:STDOUT: !77 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.Result.Core.8122a03446648385", scope: null, file: !78, line: 28, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !79)
// CHECK:STDOUT: !78 = !DIFile(filename: "{{.*}}/prelude/types/result.carbon", directory: "")
// CHECK:STDOUT: !79 = !{!80}
// CHECK:STDOUT: !80 = !DILocalVariable(arg: 1, scope: !77, type: !8)
// CHECK:STDOUT: !81 = !DILocation(line: 28, column: 1, scope: !77)
// CHECK:STDOUT: !82 = !DILocation(line: 29, column: 15, scope: !77)
// CHECK:STDOUT: !83 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.Result.Core.8122a03446648385", scope: null, file: !78, line: 28, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !84)
// CHECK:STDOUT: !84 = !{!85}
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !83, type: !8)
// CHECK:STDOUT: !86 = !DILocation(line: 28, column: 1, scope: !83)
// CHECK:STDOUT: !87 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385", scope: null, file: !78, line: 42, type: !88, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !90)
// CHECK:STDOUT: !88 = !DISubroutineType(types: !89)
// CHECK:STDOUT: !89 = !{!7, !7}
// CHECK:STDOUT: !90 = !{!91}
// CHECK:STDOUT: !91 = !DILocalVariable(arg: 1, scope: !87, type: !7)
// CHECK:STDOUT: !92 = !DILocation(line: 44, column: 7, scope: !87)
// CHECK:STDOUT: !93 = !DILocation(line: 44, column: 34, scope: !87)
// CHECK:STDOUT: !94 = !DILocation(line: 44, column: 27, scope: !87)
// CHECK:STDOUT: !95 = !DILocation(line: 45, column: 7, scope: !87)
// CHECK:STDOUT: !96 = !DILocation(line: 45, column: 35, scope: !87)
// CHECK:STDOUT: !97 = !DILocation(line: 45, column: 28, scope: !87)
// CHECK:STDOUT: !98 = !DILocation(line: 49, column: 12, scope: !87)
// CHECK:STDOUT: !99 = !DILocation(line: 49, column: 5, scope: !87)
// CHECK:STDOUT: !100 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.8122a03446648385", scope: null, file: !78, line: 51, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !101)
// CHECK:STDOUT: !101 = !{!102}
// CHECK:STDOUT: !102 = !DILocalVariable(arg: 1, scope: !100, type: !8)
// CHECK:STDOUT: !103 = !DILocation(line: 51, column: 39, scope: !100)
// CHECK:STDOUT: !104 = !DILocation(line: 51, column: 32, scope: !100)
// CHECK:STDOUT: !105 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.8122a03446648385", scope: null, file: !106, line: 21, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !107)
// CHECK:STDOUT: !106 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !107 = !{!108}
// CHECK:STDOUT: !108 = !DILocalVariable(arg: 1, scope: !105, type: !8)
// CHECK:STDOUT: !109 = !DILocation(line: 21, column: 1, scope: !105)
// CHECK:STDOUT: !110 = !DILocation(line: 22, column: 21, scope: !105)
// CHECK:STDOUT: !111 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.8122a03446648385", scope: null, file: !106, line: 21, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !112)
// CHECK:STDOUT: !112 = !{!113}
// CHECK:STDOUT: !113 = !DILocalVariable(arg: 1, scope: !111, type: !8)
// CHECK:STDOUT: !114 = !DILocation(line: 21, column: 1, scope: !111)
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
// CHECK:STDOUT: define void @_CCheck.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call = icmp sgt i32 %n, 0, !dbg !11
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Greater.call, label %if.then, label %if.else, !dbg !12
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_COk.Result.Core.4771966b48d8bcbb(ptr %return), !dbg !13
// CHECK:STDOUT:   ret void, !dbg !14
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CErr.Result.Core.4771966b48d8bcbb(ptr %return, i32 %n), !dbg !15
// CHECK:STDOUT:   ret void, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUnit.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_10.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !20
// CHECK:STDOUT:   %.loc9_11.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !20
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc9_10.1.temp), !dbg !20
// CHECK:STDOUT:   call void @_CCheck.Main(ptr %.loc9_10.1.temp, i32 %n), !dbg !20
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc9_11.1.temp), !dbg !20
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr %.loc9_11.1.temp, ptr %.loc9_10.1.temp), !dbg !20
// CHECK:STDOUT:   %.loc9_11.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc9_11.1.temp, i32 0, i32 0, !dbg !20
// CHECK:STDOUT:   %.loc9_11.6 = load i8, ptr %.loc9_11.5.discriminant, align 1, !dbg !20
// CHECK:STDOUT:   %.loc9_11.61 = trunc i8 %.loc9_11.6 to i1, !dbg !20
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc9_11.61, !dbg !20
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc9_11.1, label %.loc9_11.2, !dbg !20
// CHECK:STDOUT:
// CHECK:STDOUT: .loc9_11.1:                                       ; preds = %entry
// CHECK:STDOUT:   %.loc9_11.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc9_11.1.temp, i32 0, i32 1, !dbg !20
// CHECK:STDOUT:   %.loc9_11.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc9_11.9.payload, i32 0, i32 0, !dbg !20
// CHECK:STDOUT:   %tuple.elem0.loc9_11.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc9_11.10.Break, i32 0, i32 0, !dbg !20
// CHECK:STDOUT:   %.loc9_11.11 = load i32, ptr %tuple.elem0.loc9_11.1.tuple.elem, align 4, !dbg !20
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr %return, i32 %.loc9_11.11), !dbg !20
// CHECK:STDOUT:   call void @"_COp.cbfeef25f2aaaced:core.Destroy.Core"(ptr %.loc9_11.1.temp), !dbg !20
// CHECK:STDOUT:   call void @"_COp.c75c755eb6492aed:core.Destroy.Core"(ptr %.loc9_10.1.temp), !dbg !20
// CHECK:STDOUT:   ret void, !dbg !20
// CHECK:STDOUT:
// CHECK:STDOUT: .loc9_11.2:                                       ; preds = %entry
// CHECK:STDOUT:   %.loc9_11.13.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc9_11.1.temp, i32 0, i32 1, !dbg !20
// CHECK:STDOUT:   %.loc9_11.14.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc9_11.13.payload, i32 0, i32 0, !dbg !20
// CHECK:STDOUT:   %tuple.elem0.loc9_11.2.tuple.elem = getelementptr inbounds nuw { {} }, ptr %.loc9_11.14.Continue, i32 0, i32 0, !dbg !20
// CHECK:STDOUT:   call void @"_COp.cbfeef25f2aaaced:core.Destroy.Core"(ptr %.loc9_11.1.temp), !dbg !20
// CHECK:STDOUT:   call void @"_COp.c75c755eb6492aed:core.Destroy.Core"(ptr %.loc9_10.1.temp), !dbg !20
// CHECK:STDOUT:   call void @_COk.Result.Core.4771966b48d8bcbb(ptr %return), !dbg !21
// CHECK:STDOUT:   ret void, !dbg !22
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.945345cbed56cb88:core.Destroy.Core"(ptr %self) #0 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !29
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.363f24f1872db271:core.Destroy.Core"(ptr %self) #0 !dbg !30 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !36 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.216a6481b641f07b:core.Destroy.Core"(ptr %self) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.e3703e0813ae48b0:core.Destroy.Core"(ptr %self) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.c7fba127f6dfa84f:core.Destroy.Core"(ptr %self) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.cbfeef25f2aaaced:core.Destroy.Core"(ptr %self) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.ba3a3ad441f2a17d:core.Destroy.Core"(ptr %self) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !61
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.28b19e8781fae927:core.Destroy.Core"(ptr %self) #0 !dbg !62 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.c75c755eb6492aed:core.Destroy.Core"(ptr %self) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.Result.Core.4771966b48d8bcbb(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !70 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !74
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !74
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !74
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Result.val.5d3.anon, i64 8, i1 false), !dbg !74
// CHECK:STDOUT:   store { {} } poison, ptr %Ok, align 1, !dbg !74
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Ok, i32 0, i32 0, !dbg !75
// CHECK:STDOUT:   ret void, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.Result.Core.4771966b48d8bcbb(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !76 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !79
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !79
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !79
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !79
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Result.val.21e.anon, i64 8, i1 false), !dbg !79
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Err, align 4, !dbg !79
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !79
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !79
// CHECK:STDOUT:   ret void, !dbg !79
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !80 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !85
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !85
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !85
// CHECK:STDOUT:   %3 = icmp eq i1 false, %2, !dbg !85
// CHECK:STDOUT:   br i1 %3, label %4, label %5, !dbg !85
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !85
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !85
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Ok, i32 0, i32 0, !dbg !85
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.4771966b48d8bcbb(ptr %return), !dbg !86
// CHECK:STDOUT:   ret void, !dbg !87
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %0
// CHECK:STDOUT:   %discriminant1 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !88
// CHECK:STDOUT:   %6 = load i8, ptr %discriminant1, align 1, !dbg !88
// CHECK:STDOUT:   %7 = trunc i8 %6 to i1, !dbg !88
// CHECK:STDOUT:   %8 = icmp eq i1 true, %7, !dbg !88
// CHECK:STDOUT:   br i1 %8, label %9, label %11, !dbg !88
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %5
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !88
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload2, i32 0, i32 0, !dbg !88
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !88
// CHECK:STDOUT:   %10 = load i32, ptr %tuple.elem3, align 4, !dbg !88
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.4771966b48d8bcbb(ptr %return, i32 %10), !dbg !89
// CHECK:STDOUT:   ret void, !dbg !90
// CHECK:STDOUT:
// CHECK:STDOUT: 11:                                               ; preds = %5
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr %return, ptr %self), !dbg !91
// CHECK:STDOUT:   ret void, !dbg !92
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %b) #0 !dbg !93 {
// CHECK:STDOUT:   call void @_CErr.Result.Core.4771966b48d8bcbb(ptr %return, i32 %b), !dbg !96
// CHECK:STDOUT:   ret void, !dbg !97
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.4771966b48d8bcbb(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !98 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !100
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !100
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !100
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.787.anon, i64 8, i1 false), !dbg !100
// CHECK:STDOUT:   store { {} } poison, ptr %Continue, align 1, !dbg !100
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Continue, i32 0, i32 0, !dbg !101
// CHECK:STDOUT:   ret void, !dbg !100
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.4771966b48d8bcbb(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !102 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !105
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !105
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !105
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !105
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.a52.anon, i64 8, i1 false), !dbg !105
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !105
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !105
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !105
// CHECK:STDOUT:   ret void, !dbg !105
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_COp.cbfeef25f2aaaced:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_COp.c75c755eb6492aed:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_COk.Result.Core.4771966b48d8bcbb, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 0, 1, 3, 2 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "unit.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Check", linkageName: "_CCheck.Main", scope: null, file: !1, line: 3, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 4, column: 7, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 4, column: 6, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 4, column: 23, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 4, column: 16, scope: !4)
// CHECK:STDOUT: !15 = !DILocation(line: 5, column: 10, scope: !4)
// CHECK:STDOUT: !16 = !DILocation(line: 5, column: 3, scope: !4)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "Unit", linkageName: "_CUnit.Main", scope: null, file: !1, line: 8, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !18)
// CHECK:STDOUT: !18 = !{!19}
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 1, scope: !17, type: !8)
// CHECK:STDOUT: !20 = !DILocation(line: 9, column: 3, scope: !17)
// CHECK:STDOUT: !21 = !DILocation(line: 10, column: 10, scope: !17)
// CHECK:STDOUT: !22 = !DILocation(line: 10, column: 3, scope: !17)
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "Op", linkageName: "_COp.945345cbed56cb88:core.Destroy.Core", scope: null, file: !1, line: 9, type: !24, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !27)
// CHECK:STDOUT: !24 = !DISubroutineType(types: !25)
// CHECK:STDOUT: !25 = !{null, !26}
// CHECK:STDOUT: !26 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !27 = !{!28}
// CHECK:STDOUT: !28 = !DILocalVariable(arg: 1, scope: !23, type: !26)
// CHECK:STDOUT: !29 = !DILocation(line: 9, column: 3, scope: !23)
// CHECK:STDOUT: !30 = distinct !DISubprogram(name: "Op", linkageName: "_COp.363f24f1872db271:core.Destroy.Core", scope: null, file: !1, line: 9, type: !31, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !33)
// CHECK:STDOUT: !31 = !DISubroutineType(types: !32)
// CHECK:STDOUT: !32 = !{null, !7}
// CHECK:STDOUT: !33 = !{!34}
// CHECK:STDOUT: !34 = !DILocalVariable(arg: 1, scope: !30, type: !7)
// CHECK:STDOUT: !35 = !DILocation(line: 9, column: 3, scope: !30)
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 9, type: !37, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !39)
// CHECK:STDOUT: !37 = !DISubroutineType(types: !38)
// CHECK:STDOUT: !38 = !{null, !8}
// CHECK:STDOUT: !39 = !{!40}
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !36, type: !8)
// CHECK:STDOUT: !41 = !DILocation(line: 9, column: 3, scope: !36)
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "Op", linkageName: "_COp.216a6481b641f07b:core.Destroy.Core", scope: null, file: !1, line: 9, type: !31, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !43)
// CHECK:STDOUT: !43 = !{!44}
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !42, type: !7)
// CHECK:STDOUT: !45 = !DILocation(line: 9, column: 3, scope: !42)
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "Op", linkageName: "_COp.e3703e0813ae48b0:core.Destroy.Core", scope: null, file: !1, line: 9, type: !31, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !47)
// CHECK:STDOUT: !47 = !{!48}
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !46, type: !7)
// CHECK:STDOUT: !49 = !DILocation(line: 9, column: 3, scope: !46)
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "Op", linkageName: "_COp.c7fba127f6dfa84f:core.Destroy.Core", scope: null, file: !1, line: 9, type: !31, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !51)
// CHECK:STDOUT: !51 = !{!52}
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !50, type: !7)
// CHECK:STDOUT: !53 = !DILocation(line: 9, column: 3, scope: !50)
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "Op", linkageName: "_COp.cbfeef25f2aaaced:core.Destroy.Core", scope: null, file: !1, line: 9, type: !31, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !55)
// CHECK:STDOUT: !55 = !{!56}
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !54, type: !7)
// CHECK:STDOUT: !57 = !DILocation(line: 9, column: 3, scope: !54)
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "Op", linkageName: "_COp.ba3a3ad441f2a17d:core.Destroy.Core", scope: null, file: !1, line: 9, type: !31, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !59)
// CHECK:STDOUT: !59 = !{!60}
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !58, type: !7)
// CHECK:STDOUT: !61 = !DILocation(line: 9, column: 3, scope: !58)
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "Op", linkageName: "_COp.28b19e8781fae927:core.Destroy.Core", scope: null, file: !1, line: 9, type: !31, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !63)
// CHECK:STDOUT: !63 = !{!64}
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !62, type: !7)
// CHECK:STDOUT: !65 = !DILocation(line: 9, column: 3, scope: !62)
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "Op", linkageName: "_COp.c75c755eb6492aed:core.Destroy.Core", scope: null, file: !1, line: 9, type: !31, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !67)
// CHECK:STDOUT: !67 = !{!68}
// CHECK:STDOUT: !68 = !DILocalVariable(arg: 1, scope: !66, type: !7)
// CHECK:STDOUT: !69 = !DILocation(line: 9, column: 3, scope: !66)
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.Result.Core.4771966b48d8bcbb", scope: null, file: !71, line: 28, type: !72, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !71 = !DIFile(filename: "{{.*}}/prelude/types/result.carbon", directory: "")
// CHECK:STDOUT: !72 = !DISubroutineType(types: !73)
// CHECK:STDOUT: !73 = !{!7}
// CHECK:STDOUT: !74 = !DILocation(line: 28, column: 1, scope: !70)
// CHECK:STDOUT: !75 = !DILocation(line: 29, column: 15, scope: !70)
// CHECK:STDOUT: !76 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.Result.Core.4771966b48d8bcbb", scope: null, file: !71, line: 28, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !77)
// CHECK:STDOUT: !77 = !{!78}
// CHECK:STDOUT: !78 = !DILocalVariable(arg: 1, scope: !76, type: !8)
// CHECK:STDOUT: !79 = !DILocation(line: 28, column: 1, scope: !76)
// CHECK:STDOUT: !80 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb", scope: null, file: !71, line: 42, type: !81, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !83)
// CHECK:STDOUT: !81 = !DISubroutineType(types: !82)
// CHECK:STDOUT: !82 = !{!7, !7}
// CHECK:STDOUT: !83 = !{!84}
// CHECK:STDOUT: !84 = !DILocalVariable(arg: 1, scope: !80, type: !7)
// CHECK:STDOUT: !85 = !DILocation(line: 44, column: 7, scope: !80)
// CHECK:STDOUT: !86 = !DILocation(line: 44, column: 34, scope: !80)
// CHECK:STDOUT: !87 = !DILocation(line: 44, column: 27, scope: !80)
// CHECK:STDOUT: !88 = !DILocation(line: 45, column: 7, scope: !80)
// CHECK:STDOUT: !89 = !DILocation(line: 45, column: 35, scope: !80)
// CHECK:STDOUT: !90 = !DILocation(line: 45, column: 28, scope: !80)
// CHECK:STDOUT: !91 = !DILocation(line: 49, column: 12, scope: !80)
// CHECK:STDOUT: !92 = !DILocation(line: 49, column: 5, scope: !80)
// CHECK:STDOUT: !93 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb", scope: null, file: !71, line: 51, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !94)
// CHECK:STDOUT: !94 = !{!95}
// CHECK:STDOUT: !95 = !DILocalVariable(arg: 1, scope: !93, type: !8)
// CHECK:STDOUT: !96 = !DILocation(line: 51, column: 39, scope: !93)
// CHECK:STDOUT: !97 = !DILocation(line: 51, column: 32, scope: !93)
// CHECK:STDOUT: !98 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.4771966b48d8bcbb", scope: null, file: !99, line: 21, type: !72, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !99 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !100 = !DILocation(line: 21, column: 1, scope: !98)
// CHECK:STDOUT: !101 = !DILocation(line: 22, column: 21, scope: !98)
// CHECK:STDOUT: !102 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.4771966b48d8bcbb", scope: null, file: !99, line: 21, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !103)
// CHECK:STDOUT: !103 = !{!104}
// CHECK:STDOUT: !104 = !DILocalVariable(arg: 1, scope: !102, type: !8)
// CHECK:STDOUT: !105 = !DILocation(line: 21, column: 1, scope: !102)
// CHECK:STDOUT:

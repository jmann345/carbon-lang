// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/main_run/return_result.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/main_run/return_result.carbon

// The `Result`-returning entry point, lowered (decision D10 of docs/design/
// error_handling.md, "Entry point"; fork/eh/plan.md §2.A.5): `define i32
// @main()` with ZERO parameters (no `sret`, no `ptr` — the SemIR return
// parameter is ignored, not lowered), the `Core.Result` return slot as a
// local `alloca` in the entry block, and at every `return` the epilogue:
// `load i8` of the discriminant, `icmp eq ... 0`, a branch to `run.result.ok`
// (`ret i32 0` for `Ok(())`, the `i32` payload load for `Ok(code)`) or
// `run.result.err` (`call i64 @write(i32 2, ptr @main.result.err.message,
// i64 <len>)` — `declare i64 @write(i32, ptr, i64)` — then `ret i32 1`). The
// `?` in `unit_ok` adds a second `return` sharing the one message global.

// --- unit_ok.carbon
library "[[@TEST_NAME]]";

fn Fails(n: i32) -> Core.Result((), i32) {
  return Core.Result((), i32).Err(n);
}

fn Run() -> Core.Result((), i32) {
  Fails(7)?;
  return Core.Result((), i32).Ok(());
}

// --- i32_ok.carbon
library "[[@TEST_NAME]]";

fn Run() -> Core.Result(i32, i32) {
  return Core.Result(i32, i32).Ok(3);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'unit_ok.carbon'
// CHECK:STDOUT: source_filename = "unit_ok.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @main.result.err.message = private unnamed_addr constant [71 x i8] c"carbon: `Main.Run` returned `.Err` of type `i32`; exiting with code 1\0A\00", align 1
// CHECK:STDOUT: @Result.val.21e.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @Result.val.5d3.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @ControlFlow.val.787.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @ControlFlow.val.a52.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CFails.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.Result.Core.4771966b48d8bcbb(ptr %return, i32 %n), !dbg !11
// CHECK:STDOUT:   ret void, !dbg !12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !13 {
// CHECK:STDOUT:   %return = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4
// CHECK:STDOUT:   %.loc8_10.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !16
// CHECK:STDOUT:   %.loc8_11.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !16
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %return)
// CHECK:STDOUT:   br label %entry
// CHECK:STDOUT:
// CHECK:STDOUT: entry:                                            ; preds = %0
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc8_10.1.temp), !dbg !16
// CHECK:STDOUT:   call void @_CFails.Main(ptr %.loc8_10.1.temp, i32 7), !dbg !16
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc8_11.1.temp), !dbg !16
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr %.loc8_11.1.temp, ptr %.loc8_10.1.temp), !dbg !16
// CHECK:STDOUT:   %.loc8_11.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc8_11.1.temp, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   %.loc8_11.6 = load i8, ptr %.loc8_11.5.discriminant, align 1, !dbg !16
// CHECK:STDOUT:   %.loc8_11.61 = trunc i8 %.loc8_11.6 to i1, !dbg !16
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc8_11.61, !dbg !16
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc8_11.1, label %.loc8_11.2, !dbg !16
// CHECK:STDOUT:
// CHECK:STDOUT: .loc8_11.1:                                       ; preds = %entry
// CHECK:STDOUT:   %.loc8_11.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc8_11.1.temp, i32 0, i32 1, !dbg !16
// CHECK:STDOUT:   %.loc8_11.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc8_11.9.payload, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   %tuple.elem0.loc8_11.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc8_11.10.Break, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   %.loc8_11.11 = load i32, ptr %tuple.elem0.loc8_11.1.tuple.elem, align 4, !dbg !16
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr %return, i32 %.loc8_11.11), !dbg !16
// CHECK:STDOUT:   call void @"_COp.cbfeef25f2aaaced:core.Destroy.Core"(ptr %.loc8_11.1.temp), !dbg !16
// CHECK:STDOUT:   call void @"_COp.c75c755eb6492aed:core.Destroy.Core"(ptr %.loc8_10.1.temp), !dbg !16
// CHECK:STDOUT:   %run.result.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   %run.result.disc = load i8, ptr %run.result.discriminant, align 1, !dbg !16
// CHECK:STDOUT:   %run.result.is_ok = icmp eq i8 %run.result.disc, 0, !dbg !16
// CHECK:STDOUT:   br i1 %run.result.is_ok, label %run.result.ok, label %run.result.err, !dbg !16
// CHECK:STDOUT:
// CHECK:STDOUT: run.result.ok:                                    ; preds = %.loc8_11.1
// CHECK:STDOUT:   ret i32 0, !dbg !16
// CHECK:STDOUT:
// CHECK:STDOUT: run.result.err:                                   ; preds = %.loc8_11.1
// CHECK:STDOUT:   %1 = call i64 @write(i32 2, ptr @main.result.err.message, i64 70), !dbg !16
// CHECK:STDOUT:   ret i32 1, !dbg !16
// CHECK:STDOUT:
// CHECK:STDOUT: .loc8_11.2:                                       ; preds = %entry
// CHECK:STDOUT:   %.loc8_11.13.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc8_11.1.temp, i32 0, i32 1, !dbg !16
// CHECK:STDOUT:   %.loc8_11.14.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc8_11.13.payload, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   %tuple.elem0.loc8_11.2.tuple.elem = getelementptr inbounds nuw { {} }, ptr %.loc8_11.14.Continue, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   call void @"_COp.cbfeef25f2aaaced:core.Destroy.Core"(ptr %.loc8_11.1.temp), !dbg !16
// CHECK:STDOUT:   call void @"_COp.c75c755eb6492aed:core.Destroy.Core"(ptr %.loc8_10.1.temp), !dbg !16
// CHECK:STDOUT:   call void @_COk.Result.Core.4771966b48d8bcbb(ptr %return), !dbg !17
// CHECK:STDOUT:   %run.result.discriminant2 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !18
// CHECK:STDOUT:   %run.result.disc3 = load i8, ptr %run.result.discriminant2, align 1, !dbg !18
// CHECK:STDOUT:   %run.result.is_ok4 = icmp eq i8 %run.result.disc3, 0, !dbg !18
// CHECK:STDOUT:   br i1 %run.result.is_ok4, label %run.result.ok5, label %run.result.err6, !dbg !18
// CHECK:STDOUT:
// CHECK:STDOUT: run.result.ok5:                                   ; preds = %.loc8_11.2
// CHECK:STDOUT:   ret i32 0, !dbg !18
// CHECK:STDOUT:
// CHECK:STDOUT: run.result.err6:                                  ; preds = %.loc8_11.2
// CHECK:STDOUT:   %2 = call i64 @write(i32 2, ptr @main.result.err.message, i64 70), !dbg !18
// CHECK:STDOUT:   ret i32 1, !dbg !18
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.945345cbed56cb88:core.Destroy.Core"(ptr %self) #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.363f24f1872db271:core.Destroy.Core"(ptr %self) #0 !dbg !26 {
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
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.e3703e0813ae48b0:core.Destroy.Core"(ptr %self) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.c7fba127f6dfa84f:core.Destroy.Core"(ptr %self) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.cbfeef25f2aaaced:core.Destroy.Core"(ptr %self) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.ba3a3ad441f2a17d:core.Destroy.Core"(ptr %self) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.28b19e8781fae927:core.Destroy.Core"(ptr %self) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !61
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.c75c755eb6492aed:core.Destroy.Core"(ptr %self) #0 !dbg !62 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.Result.Core.4771966b48d8bcbb(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !66 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !70
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !70
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !70
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !70
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Result.val.21e.anon, i64 8, i1 false), !dbg !70
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Err, align 4, !dbg !70
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !70
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !70
// CHECK:STDOUT:   ret void, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !71 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !76
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !76
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !76
// CHECK:STDOUT:   %3 = icmp eq i1 false, %2, !dbg !76
// CHECK:STDOUT:   br i1 %3, label %4, label %5, !dbg !76
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !76
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !76
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Ok, i32 0, i32 0, !dbg !76
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.4771966b48d8bcbb(ptr %return), !dbg !77
// CHECK:STDOUT:   ret void, !dbg !78
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %0
// CHECK:STDOUT:   %discriminant1 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !79
// CHECK:STDOUT:   %6 = load i8, ptr %discriminant1, align 1, !dbg !79
// CHECK:STDOUT:   %7 = trunc i8 %6 to i1, !dbg !79
// CHECK:STDOUT:   %8 = icmp eq i1 true, %7, !dbg !79
// CHECK:STDOUT:   br i1 %8, label %9, label %11, !dbg !79
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %5
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !79
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload2, i32 0, i32 0, !dbg !79
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !79
// CHECK:STDOUT:   %10 = load i32, ptr %tuple.elem3, align 4, !dbg !79
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.4771966b48d8bcbb(ptr %return, i32 %10), !dbg !80
// CHECK:STDOUT:   ret void, !dbg !81
// CHECK:STDOUT:
// CHECK:STDOUT: 11:                                               ; preds = %5
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr %return, ptr %self), !dbg !82
// CHECK:STDOUT:   ret void, !dbg !83
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %b) #0 !dbg !84 {
// CHECK:STDOUT:   call void @_CErr.Result.Core.4771966b48d8bcbb(ptr %return, i32 %b), !dbg !87
// CHECK:STDOUT:   ret void, !dbg !88
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.Result.Core.4771966b48d8bcbb(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !89 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !92
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !92
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !92
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Result.val.5d3.anon, i64 8, i1 false), !dbg !92
// CHECK:STDOUT:   store { {} } poison, ptr %Ok, align 1, !dbg !92
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Ok, i32 0, i32 0, !dbg !93
// CHECK:STDOUT:   ret void, !dbg !92
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.4771966b48d8bcbb(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !94 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !96
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !96
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !96
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.787.anon, i64 8, i1 false), !dbg !96
// CHECK:STDOUT:   store { {} } poison, ptr %Continue, align 1, !dbg !96
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Continue, i32 0, i32 0, !dbg !97
// CHECK:STDOUT:   ret void, !dbg !96
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.4771966b48d8bcbb(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !98 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !101
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !101
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !101
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !101
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.a52.anon, i64 8, i1 false), !dbg !101
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !101
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !101
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !101
// CHECK:STDOUT:   ret void, !dbg !101
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_COp.cbfeef25f2aaaced:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_COp.c75c755eb6492aed:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 0, 1, 3, 2 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "unit_ok.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Fails", linkageName: "_CFails.Main", scope: null, file: !1, line: 3, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 4, column: 10, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 4, column: 3, scope: !4)
// CHECK:STDOUT: !13 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !1, line: 7, type: !14, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !14 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !15 = !{!8}
// CHECK:STDOUT: !16 = !DILocation(line: 8, column: 3, scope: !13)
// CHECK:STDOUT: !17 = !DILocation(line: 9, column: 10, scope: !13)
// CHECK:STDOUT: !18 = !DILocation(line: 9, column: 3, scope: !13)
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "Op", linkageName: "_COp.945345cbed56cb88:core.Destroy.Core", scope: null, file: !1, line: 8, type: !20, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !23)
// CHECK:STDOUT: !20 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !21 = !{null, !22}
// CHECK:STDOUT: !22 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !23 = !{!24}
// CHECK:STDOUT: !24 = !DILocalVariable(arg: 1, scope: !19, type: !22)
// CHECK:STDOUT: !25 = !DILocation(line: 8, column: 3, scope: !19)
// CHECK:STDOUT: !26 = distinct !DISubprogram(name: "Op", linkageName: "_COp.363f24f1872db271:core.Destroy.Core", scope: null, file: !1, line: 8, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !29)
// CHECK:STDOUT: !27 = !DISubroutineType(types: !28)
// CHECK:STDOUT: !28 = !{null, !7}
// CHECK:STDOUT: !29 = !{!30}
// CHECK:STDOUT: !30 = !DILocalVariable(arg: 1, scope: !26, type: !7)
// CHECK:STDOUT: !31 = !DILocation(line: 8, column: 3, scope: !26)
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 8, type: !33, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !35)
// CHECK:STDOUT: !33 = !DISubroutineType(types: !34)
// CHECK:STDOUT: !34 = !{null, !8}
// CHECK:STDOUT: !35 = !{!36}
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !32, type: !8)
// CHECK:STDOUT: !37 = !DILocation(line: 8, column: 3, scope: !32)
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "Op", linkageName: "_COp.216a6481b641f07b:core.Destroy.Core", scope: null, file: !1, line: 8, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !39)
// CHECK:STDOUT: !39 = !{!40}
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !38, type: !7)
// CHECK:STDOUT: !41 = !DILocation(line: 8, column: 3, scope: !38)
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "Op", linkageName: "_COp.e3703e0813ae48b0:core.Destroy.Core", scope: null, file: !1, line: 8, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !43)
// CHECK:STDOUT: !43 = !{!44}
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !42, type: !7)
// CHECK:STDOUT: !45 = !DILocation(line: 8, column: 3, scope: !42)
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "Op", linkageName: "_COp.c7fba127f6dfa84f:core.Destroy.Core", scope: null, file: !1, line: 8, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !47)
// CHECK:STDOUT: !47 = !{!48}
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !46, type: !7)
// CHECK:STDOUT: !49 = !DILocation(line: 8, column: 3, scope: !46)
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "Op", linkageName: "_COp.cbfeef25f2aaaced:core.Destroy.Core", scope: null, file: !1, line: 8, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !51)
// CHECK:STDOUT: !51 = !{!52}
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !50, type: !7)
// CHECK:STDOUT: !53 = !DILocation(line: 8, column: 3, scope: !50)
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "Op", linkageName: "_COp.ba3a3ad441f2a17d:core.Destroy.Core", scope: null, file: !1, line: 8, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !55)
// CHECK:STDOUT: !55 = !{!56}
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !54, type: !7)
// CHECK:STDOUT: !57 = !DILocation(line: 8, column: 3, scope: !54)
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "Op", linkageName: "_COp.28b19e8781fae927:core.Destroy.Core", scope: null, file: !1, line: 8, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !59)
// CHECK:STDOUT: !59 = !{!60}
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !58, type: !7)
// CHECK:STDOUT: !61 = !DILocation(line: 8, column: 3, scope: !58)
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "Op", linkageName: "_COp.c75c755eb6492aed:core.Destroy.Core", scope: null, file: !1, line: 8, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !63)
// CHECK:STDOUT: !63 = !{!64}
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !62, type: !7)
// CHECK:STDOUT: !65 = !DILocation(line: 8, column: 3, scope: !62)
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.Result.Core.4771966b48d8bcbb", scope: null, file: !67, line: 28, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !68)
// CHECK:STDOUT: !67 = !DIFile(filename: "{{.*}}/prelude/types/result.carbon", directory: "")
// CHECK:STDOUT: !68 = !{!69}
// CHECK:STDOUT: !69 = !DILocalVariable(arg: 1, scope: !66, type: !8)
// CHECK:STDOUT: !70 = !DILocation(line: 28, column: 1, scope: !66)
// CHECK:STDOUT: !71 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb", scope: null, file: !67, line: 42, type: !72, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !74)
// CHECK:STDOUT: !72 = !DISubroutineType(types: !73)
// CHECK:STDOUT: !73 = !{!7, !7}
// CHECK:STDOUT: !74 = !{!75}
// CHECK:STDOUT: !75 = !DILocalVariable(arg: 1, scope: !71, type: !7)
// CHECK:STDOUT: !76 = !DILocation(line: 44, column: 7, scope: !71)
// CHECK:STDOUT: !77 = !DILocation(line: 44, column: 34, scope: !71)
// CHECK:STDOUT: !78 = !DILocation(line: 44, column: 27, scope: !71)
// CHECK:STDOUT: !79 = !DILocation(line: 45, column: 7, scope: !71)
// CHECK:STDOUT: !80 = !DILocation(line: 45, column: 35, scope: !71)
// CHECK:STDOUT: !81 = !DILocation(line: 45, column: 28, scope: !71)
// CHECK:STDOUT: !82 = !DILocation(line: 49, column: 12, scope: !71)
// CHECK:STDOUT: !83 = !DILocation(line: 49, column: 5, scope: !71)
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb", scope: null, file: !67, line: 51, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !85)
// CHECK:STDOUT: !85 = !{!86}
// CHECK:STDOUT: !86 = !DILocalVariable(arg: 1, scope: !84, type: !8)
// CHECK:STDOUT: !87 = !DILocation(line: 51, column: 39, scope: !84)
// CHECK:STDOUT: !88 = !DILocation(line: 51, column: 32, scope: !84)
// CHECK:STDOUT: !89 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.Result.Core.4771966b48d8bcbb", scope: null, file: !67, line: 28, type: !90, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !90 = !DISubroutineType(types: !91)
// CHECK:STDOUT: !91 = !{!7}
// CHECK:STDOUT: !92 = !DILocation(line: 28, column: 1, scope: !89)
// CHECK:STDOUT: !93 = !DILocation(line: 29, column: 15, scope: !89)
// CHECK:STDOUT: !94 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.4771966b48d8bcbb", scope: null, file: !95, line: 21, type: !90, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !95 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !96 = !DILocation(line: 21, column: 1, scope: !94)
// CHECK:STDOUT: !97 = !DILocation(line: 22, column: 21, scope: !94)
// CHECK:STDOUT: !98 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.4771966b48d8bcbb", scope: null, file: !95, line: 21, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !99)
// CHECK:STDOUT: !99 = !{!100}
// CHECK:STDOUT: !100 = !DILocalVariable(arg: 1, scope: !98, type: !8)
// CHECK:STDOUT: !101 = !DILocation(line: 21, column: 1, scope: !98)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'i32_ok.carbon'
// CHECK:STDOUT: source_filename = "i32_ok.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @main.result.err.message = private unnamed_addr constant [71 x i8] c"carbon: `Main.Run` returned `.Err` of type `i32`; exiting with code 1\0A\00", align 1
// CHECK:STDOUT: @Result.val.ad4.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !4 {
// CHECK:STDOUT:   %return = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %return)
// CHECK:STDOUT:   br label %entry
// CHECK:STDOUT:
// CHECK:STDOUT: entry:                                            ; preds = %0
// CHECK:STDOUT:   call void @_COk.Result.Core.8122a03446648385(ptr %return, i32 3), !dbg !8
// CHECK:STDOUT:   %run.result.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !9
// CHECK:STDOUT:   %run.result.disc = load i8, ptr %run.result.discriminant, align 1, !dbg !9
// CHECK:STDOUT:   %run.result.is_ok = icmp eq i8 %run.result.disc, 0, !dbg !9
// CHECK:STDOUT:   br i1 %run.result.is_ok, label %run.result.ok, label %run.result.err, !dbg !9
// CHECK:STDOUT:
// CHECK:STDOUT: run.result.ok:                                    ; preds = %entry
// CHECK:STDOUT:   %run.result.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !9
// CHECK:STDOUT:   %run.result.code = load i32, ptr %run.result.payload, align 4, !dbg !9
// CHECK:STDOUT:   ret i32 %run.result.code, !dbg !9
// CHECK:STDOUT:
// CHECK:STDOUT: run.result.err:                                   ; preds = %entry
// CHECK:STDOUT:   %1 = call i64 @write(i32 2, ptr @main.result.err.message, i64 70), !dbg !9
// CHECK:STDOUT:   ret i32 1, !dbg !9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.Result.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !10 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !17
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !17
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !17
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !18
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Result.val.ad4.anon, i64 8, i1 false), !dbg !17
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Ok, align 4, !dbg !17
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Ok, i32 0, i32 0, !dbg !18
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !18
// CHECK:STDOUT:   ret void, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "i32_ok.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !1, line: 3, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 4, column: 10, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 4, column: 3, scope: !4)
// CHECK:STDOUT: !10 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.Result.Core.8122a03446648385", scope: null, file: !11, line: 28, type: !12, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !15)
// CHECK:STDOUT: !11 = !DIFile(filename: "{{.*}}/prelude/types/result.carbon", directory: "")
// CHECK:STDOUT: !12 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !13 = !{!14, !7}
// CHECK:STDOUT: !14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !15 = !{!16}
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 1, scope: !10, type: !7)
// CHECK:STDOUT: !17 = !DILocation(line: 28, column: 1, scope: !10)
// CHECK:STDOUT: !18 = !DILocation(line: 29, column: 15, scope: !10)
// CHECK:STDOUT:

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
// CHECK:STDOUT: define void @_CFails.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CErr.Result.Core.4771966b48d8bcbb(ptr %return, i32 %n), !dbg !25
// CHECK:STDOUT:   ret void, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !28 {
// CHECK:STDOUT:   %return = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4
// CHECK:STDOUT:   %.loc8_10.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !31
// CHECK:STDOUT:   %.loc8_11.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !31
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %return)
// CHECK:STDOUT:   br label %entry
// CHECK:STDOUT:
// CHECK:STDOUT: entry:                                            ; preds = %0
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc8_10.1.temp), !dbg !31
// CHECK:STDOUT:   call void @_CFails.Main(ptr %.loc8_10.1.temp, i32 7), !dbg !31
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc8_11.1.temp), !dbg !31
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr %.loc8_11.1.temp, ptr %.loc8_10.1.temp), !dbg !31
// CHECK:STDOUT:   %.loc8_11.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc8_11.1.temp, i32 0, i32 0, !dbg !31
// CHECK:STDOUT:   %.loc8_11.6 = load i8, ptr %.loc8_11.5.discriminant, align 1, !dbg !31
// CHECK:STDOUT:   %.loc8_11.61 = trunc i8 %.loc8_11.6 to i1, !dbg !31
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc8_11.61, !dbg !31
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc8_11.1, label %.loc8_11.2, !dbg !31
// CHECK:STDOUT:
// CHECK:STDOUT: .loc8_11.1:                                       ; preds = %entry
// CHECK:STDOUT:   %.loc8_11.9.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc8_11.1.temp, i32 0, i32 1, !dbg !31
// CHECK:STDOUT:   %.loc8_11.10.Break = getelementptr inbounds nuw [4 x i8], ptr %.loc8_11.9.payload, i32 0, i32 0, !dbg !31
// CHECK:STDOUT:   %tuple.elem0.loc8_11.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc8_11.10.Break, i32 0, i32 0, !dbg !31
// CHECK:STDOUT:   %.loc8_11.11 = load i32, ptr %tuple.elem0.loc8_11.1.tuple.elem, align 4, !dbg !31
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr %return, i32 %.loc8_11.11), !dbg !31
// CHECK:STDOUT:   call void @"_CSelfDestruct.19f0acf56e98f684:core.Destroy.Core"(ptr %.loc8_11.1.temp), !dbg !31
// CHECK:STDOUT:   call void @"_CSelfDestruct.610f3d0bf7b525c5:core.Destroy.Core"(ptr %.loc8_10.1.temp), !dbg !31
// CHECK:STDOUT:   %run.result.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !31
// CHECK:STDOUT:   %run.result.disc = load i8, ptr %run.result.discriminant, align 1, !dbg !31
// CHECK:STDOUT:   %run.result.is_ok = icmp eq i8 %run.result.disc, 0, !dbg !31
// CHECK:STDOUT:   br i1 %run.result.is_ok, label %run.result.ok, label %run.result.err, !dbg !31
// CHECK:STDOUT:
// CHECK:STDOUT: run.result.ok:                                    ; preds = %.loc8_11.1
// CHECK:STDOUT:   ret i32 0, !dbg !31
// CHECK:STDOUT:
// CHECK:STDOUT: run.result.err:                                   ; preds = %.loc8_11.1
// CHECK:STDOUT:   %1 = call i64 @write(i32 2, ptr @main.result.err.message, i64 70), !dbg !31
// CHECK:STDOUT:   ret i32 1, !dbg !31
// CHECK:STDOUT:
// CHECK:STDOUT: .loc8_11.2:                                       ; preds = %entry
// CHECK:STDOUT:   %.loc8_11.13.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc8_11.1.temp, i32 0, i32 1, !dbg !31
// CHECK:STDOUT:   %.loc8_11.14.Continue = getelementptr inbounds nuw [4 x i8], ptr %.loc8_11.13.payload, i32 0, i32 0, !dbg !31
// CHECK:STDOUT:   %tuple.elem0.loc8_11.2.tuple.elem = getelementptr inbounds nuw { {} }, ptr %.loc8_11.14.Continue, i32 0, i32 0, !dbg !31
// CHECK:STDOUT:   call void @"_CSelfDestruct.19f0acf56e98f684:core.Destroy.Core"(ptr %.loc8_11.1.temp), !dbg !31
// CHECK:STDOUT:   call void @"_CSelfDestruct.610f3d0bf7b525c5:core.Destroy.Core"(ptr %.loc8_10.1.temp), !dbg !31
// CHECK:STDOUT:   call void @_COk.Result.Core.4771966b48d8bcbb(ptr %return), !dbg !34
// CHECK:STDOUT:   %run.result.discriminant2 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !37
// CHECK:STDOUT:   %run.result.disc3 = load i8, ptr %run.result.discriminant2, align 1, !dbg !37
// CHECK:STDOUT:   %run.result.is_ok4 = icmp eq i8 %run.result.disc3, 0, !dbg !37
// CHECK:STDOUT:   br i1 %run.result.is_ok4, label %run.result.ok5, label %run.result.err6, !dbg !37
// CHECK:STDOUT:
// CHECK:STDOUT: run.result.ok5:                                   ; preds = %.loc8_11.2
// CHECK:STDOUT:   ret i32 0, !dbg !37
// CHECK:STDOUT:
// CHECK:STDOUT: run.result.err6:                                  ; preds = %.loc8_11.2
// CHECK:STDOUT:   %2 = call i64 @write(i32 2, ptr @main.result.err.message, i64 70), !dbg !37
// CHECK:STDOUT:   ret i32 1, !dbg !37
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !38 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.61ea2aba74ab3bf1:core.Destroy.Core"(ptr %self) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.9fb0584d149a4ffd:core.Destroy.Core"(ptr %self) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { {} }, ptr %self, i32 0, i32 0, !dbg !48
// CHECK:STDOUT:   call void @"_CSelfDestruct.61ea2aba74ab3bf1:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !48
// CHECK:STDOUT:   ret void, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.9fb0584d149a4ffd:core.Destroy.Core"(ptr %self) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.9fb0584d149a4ffd:core.Destroy.Core"(ptr %self), !dbg !52
// CHECK:STDOUT:   ret void, !dbg !52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !60
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !60
// CHECK:STDOUT:   ret void, !dbg !60
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !62 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !64
// CHECK:STDOUT:   ret void, !dbg !64
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e4ccab8f99f8d8b8:core.Destroy.Core"(ptr %self) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !68
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e4ccab8f99f8d8b8:core.Destroy.Core"(ptr %self) #0 !dbg !70 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e4ccab8f99f8d8b8:core.Destroy.Core"(ptr %self), !dbg !72
// CHECK:STDOUT:   ret void, !dbg !72
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.d20fd035dcb84633:core.Destroy.Core"(ptr %self) #0 !dbg !74 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8_11.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !76
// CHECK:STDOUT:   call void @"_CSelfDestruct.e4ccab8f99f8d8b8:core.Destroy.Core"(ptr %.loc8_11.1.payload), !dbg !76
// CHECK:STDOUT:   %.loc8_11.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !76
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc8_11.2.discriminant), !dbg !76
// CHECK:STDOUT:   ret void, !dbg !76
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d20fd035dcb84633:core.Destroy.Core"(ptr %self) #0 !dbg !78 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.d20fd035dcb84633:core.Destroy.Core"(ptr %self), !dbg !80
// CHECK:STDOUT:   ret void, !dbg !80
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.19f0acf56e98f684:core.Destroy.Core"(ptr %self) #0 !dbg !82 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !84
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.19f0acf56e98f684:core.Destroy.Core"(ptr %self) #0 !dbg !86 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.19f0acf56e98f684:core.Destroy.Core"(ptr %self), !dbg !88
// CHECK:STDOUT:   ret void, !dbg !88
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e9811e1a8e50fe8e:core.Destroy.Core"(ptr %self) #0 !dbg !90 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !92
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e9811e1a8e50fe8e:core.Destroy.Core"(ptr %self) #0 !dbg !94 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e9811e1a8e50fe8e:core.Destroy.Core"(ptr %self), !dbg !96
// CHECK:STDOUT:   ret void, !dbg !96
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.11dedd8bd98866ca:core.Destroy.Core"(ptr %self) #0 !dbg !98 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8_10.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !100
// CHECK:STDOUT:   call void @"_CSelfDestruct.e9811e1a8e50fe8e:core.Destroy.Core"(ptr %.loc8_10.1.payload), !dbg !100
// CHECK:STDOUT:   %.loc8_10.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !100
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc8_10.2.discriminant), !dbg !100
// CHECK:STDOUT:   ret void, !dbg !100
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.11dedd8bd98866ca:core.Destroy.Core"(ptr %self) #0 !dbg !102 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.11dedd8bd98866ca:core.Destroy.Core"(ptr %self), !dbg !104
// CHECK:STDOUT:   ret void, !dbg !104
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.610f3d0bf7b525c5:core.Destroy.Core"(ptr %self) #0 !dbg !106 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !108
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.610f3d0bf7b525c5:core.Destroy.Core"(ptr %self) #0 !dbg !110 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.610f3d0bf7b525c5:core.Destroy.Core"(ptr %self), !dbg !112
// CHECK:STDOUT:   ret void, !dbg !112
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.Result.Core.4771966b48d8bcbb(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !115 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !117
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !117
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Result.val.21e.anon, i64 8, i1 false), !dbg !117
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Err, align 4, !dbg !117
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !117
// CHECK:STDOUT:   ret void, !dbg !117
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, ptr %self) #0 !dbg !119 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !125
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !125
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !125
// CHECK:STDOUT:   %3 = icmp eq i1 false, %2, !dbg !125
// CHECK:STDOUT:   br i1 %3, label %4, label %5, !dbg !125
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !125
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !125
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Ok, i32 0, i32 0, !dbg !125
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.4771966b48d8bcbb(ptr %return), !dbg !128
// CHECK:STDOUT:   ret void, !dbg !129
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %0
// CHECK:STDOUT:   %discriminant1 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !130
// CHECK:STDOUT:   %6 = load i8, ptr %discriminant1, align 1, !dbg !130
// CHECK:STDOUT:   %7 = trunc i8 %6 to i1, !dbg !130
// CHECK:STDOUT:   %8 = icmp eq i1 true, %7, !dbg !130
// CHECK:STDOUT:   br i1 %8, label %9, label %11, !dbg !130
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %5
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !130
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload2, i32 0, i32 0, !dbg !130
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !130
// CHECK:STDOUT:   %10 = load i32, ptr %tuple.elem3, align 4, !dbg !130
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.4771966b48d8bcbb(ptr %return, i32 %10), !dbg !133
// CHECK:STDOUT:   ret void, !dbg !134
// CHECK:STDOUT:
// CHECK:STDOUT: 11:                                               ; preds = %5
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr %return, ptr %self), !dbg !136
// CHECK:STDOUT:   ret void, !dbg !137
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb"(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %b) #0 !dbg !139 {
// CHECK:STDOUT:   call void @_CErr.Result.Core.4771966b48d8bcbb(ptr %return, i32 %b), !dbg !145
// CHECK:STDOUT:   ret void, !dbg !146
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.Result.Core.4771966b48d8bcbb(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !148 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !149
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !149
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !149
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Result.val.5d3.anon, i64 8, i1 false), !dbg !149
// CHECK:STDOUT:   store { {} } poison, ptr %Ok, align 1, !dbg !149
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Ok, i32 0, i32 0, !dbg !150
// CHECK:STDOUT:   ret void, !dbg !149
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.4771966b48d8bcbb(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return) #0 !dbg !152 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !153
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !153
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !153
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.787.anon, i64 8, i1 false), !dbg !153
// CHECK:STDOUT:   store { {} } poison, ptr %Continue, align 1, !dbg !153
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Continue, i32 0, i32 0, !dbg !154
// CHECK:STDOUT:   ret void, !dbg !153
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.4771966b48d8bcbb(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !155 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !157
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !157
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !157
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !157
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @ControlFlow.val.a52.anon, i64 8, i1 false), !dbg !157
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Break, align 4, !dbg !157
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Break, i32 0, i32 0, !dbg !157
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !157
// CHECK:STDOUT:   ret void, !dbg !157
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.19f0acf56e98f684:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.610f3d0bf7b525c5:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 1, 0 }
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
// CHECK:STDOUT: !4 = !DIFile(filename: "unit_ok.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!8, !6}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = !{!6}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{null, !7}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{null, !8}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = !{null, !6}
// CHECK:STDOUT: !18 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "Fails", linkageName: "_CFails.Main", scope: null, file: !4, line: 3, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !27)
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !19, type: !6)
// CHECK:STDOUT: !25 = !DILocation(line: 4, column: 10, scope: !19)
// CHECK:STDOUT: !26 = !DILocation(line: 4, column: 3, scope: !19)
// CHECK:STDOUT: !27 = !{!20}
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !4, line: 7, type: !12, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !31 = !DILocation(line: 8, column: 3, scope: !28)
// CHECK:STDOUT: !32 = !{!8, !8}
// CHECK:STDOUT: !33 = !DISubroutineType(types: !32)
// CHECK:STDOUT: !34 = !DILocation(line: 9, column: 10, scope: !28)
// CHECK:STDOUT: !35 = !{!8}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !37 = !DILocation(line: 9, column: 3, scope: !28)
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !4, line: 8, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !41)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !38, type: !7)
// CHECK:STDOUT: !40 = !DILocation(line: 8, column: 3, scope: !38)
// CHECK:STDOUT: !41 = !{!39}
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.61ea2aba74ab3bf1:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !45)
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !42, type: !8)
// CHECK:STDOUT: !44 = !DILocation(line: 8, column: 3, scope: !42)
// CHECK:STDOUT: !45 = !{!43}
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.9fb0584d149a4ffd:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !49)
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !46, type: !8)
// CHECK:STDOUT: !48 = !DILocation(line: 8, column: 3, scope: !46)
// CHECK:STDOUT: !49 = !{!47}
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.9fb0584d149a4ffd:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !53)
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 1, scope: !50, type: !8)
// CHECK:STDOUT: !52 = !DILocation(line: 8, column: 3, scope: !50)
// CHECK:STDOUT: !53 = !{!51}
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 8, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !57)
// CHECK:STDOUT: !55 = !DILocalVariable(arg: 1, scope: !54, type: !6)
// CHECK:STDOUT: !56 = !DILocation(line: 8, column: 3, scope: !54)
// CHECK:STDOUT: !57 = !{!55}
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !61)
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !58, type: !8)
// CHECK:STDOUT: !60 = !DILocation(line: 8, column: 3, scope: !58)
// CHECK:STDOUT: !61 = !{!59}
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !65)
// CHECK:STDOUT: !63 = !DILocalVariable(arg: 1, scope: !62, type: !8)
// CHECK:STDOUT: !64 = !DILocation(line: 8, column: 3, scope: !62)
// CHECK:STDOUT: !65 = !{!63}
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e4ccab8f99f8d8b8:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !69)
// CHECK:STDOUT: !67 = !DILocalVariable(arg: 1, scope: !66, type: !8)
// CHECK:STDOUT: !68 = !DILocation(line: 8, column: 3, scope: !66)
// CHECK:STDOUT: !69 = !{!67}
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e4ccab8f99f8d8b8:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !73)
// CHECK:STDOUT: !71 = !DILocalVariable(arg: 1, scope: !70, type: !8)
// CHECK:STDOUT: !72 = !DILocation(line: 8, column: 3, scope: !70)
// CHECK:STDOUT: !73 = !{!71}
// CHECK:STDOUT: !74 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.d20fd035dcb84633:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !77)
// CHECK:STDOUT: !75 = !DILocalVariable(arg: 1, scope: !74, type: !8)
// CHECK:STDOUT: !76 = !DILocation(line: 8, column: 3, scope: !74)
// CHECK:STDOUT: !77 = !{!75}
// CHECK:STDOUT: !78 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d20fd035dcb84633:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !81)
// CHECK:STDOUT: !79 = !DILocalVariable(arg: 1, scope: !78, type: !8)
// CHECK:STDOUT: !80 = !DILocation(line: 8, column: 3, scope: !78)
// CHECK:STDOUT: !81 = !{!79}
// CHECK:STDOUT: !82 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.19f0acf56e98f684:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !85)
// CHECK:STDOUT: !83 = !DILocalVariable(arg: 1, scope: !82, type: !8)
// CHECK:STDOUT: !84 = !DILocation(line: 8, column: 3, scope: !82)
// CHECK:STDOUT: !85 = !{!83}
// CHECK:STDOUT: !86 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.19f0acf56e98f684:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !89)
// CHECK:STDOUT: !87 = !DILocalVariable(arg: 1, scope: !86, type: !8)
// CHECK:STDOUT: !88 = !DILocation(line: 8, column: 3, scope: !86)
// CHECK:STDOUT: !89 = !{!87}
// CHECK:STDOUT: !90 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e9811e1a8e50fe8e:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !93)
// CHECK:STDOUT: !91 = !DILocalVariable(arg: 1, scope: !90, type: !8)
// CHECK:STDOUT: !92 = !DILocation(line: 8, column: 3, scope: !90)
// CHECK:STDOUT: !93 = !{!91}
// CHECK:STDOUT: !94 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e9811e1a8e50fe8e:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !97)
// CHECK:STDOUT: !95 = !DILocalVariable(arg: 1, scope: !94, type: !8)
// CHECK:STDOUT: !96 = !DILocation(line: 8, column: 3, scope: !94)
// CHECK:STDOUT: !97 = !{!95}
// CHECK:STDOUT: !98 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.11dedd8bd98866ca:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !101)
// CHECK:STDOUT: !99 = !DILocalVariable(arg: 1, scope: !98, type: !8)
// CHECK:STDOUT: !100 = !DILocation(line: 8, column: 3, scope: !98)
// CHECK:STDOUT: !101 = !{!99}
// CHECK:STDOUT: !102 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.11dedd8bd98866ca:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !105)
// CHECK:STDOUT: !103 = !DILocalVariable(arg: 1, scope: !102, type: !8)
// CHECK:STDOUT: !104 = !DILocation(line: 8, column: 3, scope: !102)
// CHECK:STDOUT: !105 = !{!103}
// CHECK:STDOUT: !106 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.610f3d0bf7b525c5:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !109)
// CHECK:STDOUT: !107 = !DILocalVariable(arg: 1, scope: !106, type: !8)
// CHECK:STDOUT: !108 = !DILocation(line: 8, column: 3, scope: !106)
// CHECK:STDOUT: !109 = !{!107}
// CHECK:STDOUT: !110 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.610f3d0bf7b525c5:core.Destroy.Core", scope: null, file: !4, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !113)
// CHECK:STDOUT: !111 = !DILocalVariable(arg: 1, scope: !110, type: !8)
// CHECK:STDOUT: !112 = !DILocation(line: 8, column: 3, scope: !110)
// CHECK:STDOUT: !113 = !{!111}
// CHECK:STDOUT: !114 = !DIFile(filename: "{{.*}}/prelude/types/result.carbon", directory: "")
// CHECK:STDOUT: !115 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.Result.Core.4771966b48d8bcbb", scope: null, file: !114, line: 28, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !118)
// CHECK:STDOUT: !116 = !DILocalVariable(arg: 1, scope: !115, type: !6)
// CHECK:STDOUT: !117 = !DILocation(line: 28, column: 1, scope: !115)
// CHECK:STDOUT: !118 = !{!116}
// CHECK:STDOUT: !119 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb", scope: null, file: !114, line: 42, type: !33, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !138)
// CHECK:STDOUT: !120 = !DILocalVariable(arg: 1, scope: !119, type: !8)
// CHECK:STDOUT: !125 = !DILocation(line: 44, column: 7, scope: !119)
// CHECK:STDOUT: !128 = !DILocation(line: 44, column: 34, scope: !119)
// CHECK:STDOUT: !129 = !DILocation(line: 44, column: 27, scope: !119)
// CHECK:STDOUT: !130 = !DILocation(line: 45, column: 7, scope: !119)
// CHECK:STDOUT: !133 = !DILocation(line: 45, column: 35, scope: !119)
// CHECK:STDOUT: !134 = !DILocation(line: 45, column: 28, scope: !119)
// CHECK:STDOUT: !136 = !DILocation(line: 49, column: 12, scope: !119)
// CHECK:STDOUT: !137 = !DILocation(line: 49, column: 5, scope: !119)
// CHECK:STDOUT: !138 = !{!120}
// CHECK:STDOUT: !139 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.4771966b48d8bcbb", scope: null, file: !114, line: 51, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !147)
// CHECK:STDOUT: !140 = !DILocalVariable(arg: 1, scope: !139, type: !6)
// CHECK:STDOUT: !145 = !DILocation(line: 51, column: 39, scope: !139)
// CHECK:STDOUT: !146 = !DILocation(line: 51, column: 32, scope: !139)
// CHECK:STDOUT: !147 = !{!140}
// CHECK:STDOUT: !148 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.Result.Core.4771966b48d8bcbb", scope: null, file: !114, line: 28, type: !36, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !149 = !DILocation(line: 28, column: 1, scope: !148)
// CHECK:STDOUT: !150 = !DILocation(line: 29, column: 15, scope: !148)
// CHECK:STDOUT: !151 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !152 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.4771966b48d8bcbb", scope: null, file: !151, line: 21, type: !36, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !153 = !DILocation(line: 21, column: 1, scope: !152)
// CHECK:STDOUT: !154 = !DILocation(line: 22, column: 21, scope: !152)
// CHECK:STDOUT: !155 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.4771966b48d8bcbb", scope: null, file: !151, line: 21, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !158)
// CHECK:STDOUT: !156 = !DILocalVariable(arg: 1, scope: !155, type: !6)
// CHECK:STDOUT: !157 = !DILocation(line: 21, column: 1, scope: !155)
// CHECK:STDOUT: !158 = !{!156}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'i32_ok.carbon'
// CHECK:STDOUT: source_filename = "i32_ok.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @main.result.err.message = private unnamed_addr constant [71 x i8] c"carbon: `Main.Run` returned `.Err` of type `i32`; exiting with code 1\0A\00", align 1
// CHECK:STDOUT: @Result.val.ad4.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !161 {
// CHECK:STDOUT:   %return = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %return)
// CHECK:STDOUT:   br label %entry
// CHECK:STDOUT:
// CHECK:STDOUT: entry:                                            ; preds = %0
// CHECK:STDOUT:   call void @_COk.Result.Core.8122a03446648385(ptr %return, i32 3), !dbg !164
// CHECK:STDOUT:   %run.result.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !165
// CHECK:STDOUT:   %run.result.disc = load i8, ptr %run.result.discriminant, align 1, !dbg !165
// CHECK:STDOUT:   %run.result.is_ok = icmp eq i8 %run.result.disc, 0, !dbg !165
// CHECK:STDOUT:   br i1 %run.result.is_ok, label %run.result.ok, label %run.result.err, !dbg !165
// CHECK:STDOUT:
// CHECK:STDOUT: run.result.ok:                                    ; preds = %entry
// CHECK:STDOUT:   %run.result.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !165
// CHECK:STDOUT:   %run.result.code = load i32, ptr %run.result.payload, align 4, !dbg !165
// CHECK:STDOUT:   ret i32 %run.result.code, !dbg !165
// CHECK:STDOUT:
// CHECK:STDOUT: run.result.err:                                   ; preds = %entry
// CHECK:STDOUT:   %1 = call i64 @write(i32 2, ptr @main.result.err.message, i64 70), !dbg !165
// CHECK:STDOUT:   ret i32 1, !dbg !165
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.Result.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !166 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !168
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !168
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !168
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !169
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Result.val.ad4.anon, i64 8, i1 false), !dbg !168
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Ok, align 4, !dbg !168
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Ok, i32 0, i32 0, !dbg !169
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !169
// CHECK:STDOUT:   ret void, !dbg !168
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!160}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!8, !6}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = !{!6}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !114 = !DIFile(filename: "{{.*}}/prelude/types/result.carbon", directory: "")
// CHECK:STDOUT: !159 = !DIFile(filename: "i32_ok.carbon", directory: "")
// CHECK:STDOUT: !160 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !159, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !161 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !159, line: 3, type: !12, spFlags: DISPFlagDefinition, unit: !160)
// CHECK:STDOUT: !164 = !DILocation(line: 4, column: 10, scope: !161)
// CHECK:STDOUT: !165 = !DILocation(line: 4, column: 3, scope: !161)
// CHECK:STDOUT: !166 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.Result.Core.8122a03446648385", scope: null, file: !114, line: 28, type: !10, spFlags: DISPFlagDefinition, unit: !160, retainedNodes: !170)
// CHECK:STDOUT: !167 = !DILocalVariable(arg: 1, scope: !166, type: !6)
// CHECK:STDOUT: !168 = !DILocation(line: 28, column: 1, scope: !166)
// CHECK:STDOUT: !169 = !DILocation(line: 29, column: 15, scope: !166)
// CHECK:STDOUT: !170 = !{!167}
// CHECK:STDOUT:

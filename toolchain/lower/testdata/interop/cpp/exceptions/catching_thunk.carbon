// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/exceptions/catching_thunk.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/exceptions/catching_thunk.carbon

// The catching thunk, lowered (docs/design/error_handling.md, "Catching
// imports"; fork/eh/plan.md §4.B): inside the still-`noexcept` thunk the
// callee is `invoke`d with a `landingpad ... catch ptr null` handler that
// stores `__cxa_current_primary_exception()` through the error out-pointer and
// returns the discriminant 1, while the success path stores the return value
// through the return out-pointer and returns 0; the Carbon caller compares
// the discriminant with 0 (`icmp`/`br`) and constructs the `Ok` or `Err`
// alternative of `Core.Result(i32, Cpp.Exception)` in each block into ONE
// shared `alloca` (no `phi`: both blocks store into the same slot, and the
// convergence block reads it). `G` is the
// `void` callee shape: no return out-pointer. `M` is the member-callee shape:
// the catching thunk takes the object (`const C&` / `C&`) as its first
// parameter and calls the method on it inside the `try`.

// --- catching_thunk.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
int may_throw_int();
void may_throw();
struct C {
  int get() const;
  int mutate();
};
''';

fn F() -> Core.Result(i32, Cpp.Exception) {
  return Core.Result(i32, Cpp.Exception).Ok(Cpp.may_throw_int()?);
}

fn G() -> Core.Result((), Cpp.Exception) {
  Cpp.may_throw()?;
  return Core.Result((), Cpp.Exception).Ok(());
}

fn M(c: Cpp.C, p: Cpp.C*) -> Core.Result(i32, Cpp.Exception) {
  var a: i32 = c.get()?;
  var b: i32 = p->mutate()?;
  return Core.Result(i32, Cpp.Exception).Ok(a + b);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'catching_thunk.carbon'
// CHECK:STDOUT: source_filename = "catching_thunk.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @Result.val.e39.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> zeroinitializer
// CHECK:STDOUT: @Result.val.207.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @Result.val.aa3.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> zeroinitializer
// CHECK:STDOUT: @Result.val.404.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @ControlFlow.val.908.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> zeroinitializer
// CHECK:STDOUT: @ControlFlow.val.401.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @ControlFlow.val.e34.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> zeroinitializer
// CHECK:STDOUT: @ControlFlow.val.98f.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @.str = private unnamed_addr constant [80 x i8] c"carbon: C++ exception escaped into Carbon through `may_throw_int`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [76 x i8] c"carbon: C++ exception escaped into Carbon through `may_throw`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.2 = private unnamed_addr constant [73 x i8] c"carbon: C++ exception escaped into Carbon through `C::get`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.3 = private unnamed_addr constant [76 x i8] c"carbon: C++ exception escaped into Carbon through `C::mutate`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CF.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_63.1.temp = alloca i32, align 4, !dbg !16
// CHECK:STDOUT:   %.loc16_63.2.temp = alloca ptr, align 8, !dbg !16
// CHECK:STDOUT:   %.loc16_63.9.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !16
// CHECK:STDOUT:   %.loc16_64.1.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !16
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc16_63.1.temp), !dbg !16
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc16_63.2.temp), !dbg !16
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk.call = call i32 @_Z13may_throw_intv.carbon_thunk_catch.(ptr %.loc16_63.1.temp, ptr %.loc16_63.2.temp), !dbg !16
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call = icmp eq i32 %may_throw_int__carbon_catching_thunk.call, 0, !dbg !16
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc16_63.9.temp), !dbg !16
// CHECK:STDOUT:   br i1 %Int.as.EqWith.impl.Equal.call, label %.loc16_63.1, label %.loc16_63.2, !dbg !16
// CHECK:STDOUT:
// CHECK:STDOUT: .loc16_63.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc16_63.10 = load i32, ptr %.loc16_63.1.temp, align 4, !dbg !16
// CHECK:STDOUT:   call void @_COk.Result.Core.f303d81b2fad85a0(ptr %.loc16_63.9.temp, i32 %.loc16_63.10), !dbg !16
// CHECK:STDOUT:   br label %.loc16_63.3, !dbg !16
// CHECK:STDOUT:
// CHECK:STDOUT: .loc16_63.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc16_63.13 = load ptr, ptr %.loc16_63.2.temp, align 8, !dbg !16
// CHECK:STDOUT:   call void @_CErr.Result.Core.f303d81b2fad85a0(ptr %.loc16_63.9.temp, ptr %.loc16_63.13), !dbg !16
// CHECK:STDOUT:   br label %.loc16_63.3, !dbg !16
// CHECK:STDOUT:
// CHECK:STDOUT: .loc16_63.3:                                      ; preds = %.loc16_63.2, %.loc16_63.1
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc16_64.1.temp), !dbg !16
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr %.loc16_64.1.temp, ptr %.loc16_63.9.temp), !dbg !16
// CHECK:STDOUT:   %.loc16_64.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc16_64.1.temp, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   %.loc16_64.6 = load i8, ptr %.loc16_64.5.discriminant, align 1, !dbg !16
// CHECK:STDOUT:   %.loc16_64.61 = trunc i8 %.loc16_64.6 to i1, !dbg !16
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc16_64.61, !dbg !16
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc16_64.1, label %.loc16_64.2, !dbg !16
// CHECK:STDOUT:
// CHECK:STDOUT: .loc16_64.1:                                      ; preds = %.loc16_63.3
// CHECK:STDOUT:   %.loc16_64.9.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc16_64.1.temp, i32 0, i32 1, !dbg !16
// CHECK:STDOUT:   %.loc16_64.10.Break = getelementptr inbounds nuw [8 x i8], ptr %.loc16_64.9.payload, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   %tuple.elem0.loc16_64.1.tuple.elem = getelementptr inbounds nuw { ptr }, ptr %.loc16_64.10.Break, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   %.loc16_64.11 = load ptr, ptr %tuple.elem0.loc16_64.1.tuple.elem, align 8, !dbg !16
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr %return, ptr %.loc16_64.11), !dbg !16
// CHECK:STDOUT:   call void @"_COp.fc07cbf55ebcafdd:core.Destroy.Core"(ptr %.loc16_64.1.temp), !dbg !16
// CHECK:STDOUT:   ret void, !dbg !16
// CHECK:STDOUT:
// CHECK:STDOUT: .loc16_64.2:                                      ; preds = %.loc16_63.3
// CHECK:STDOUT:   %.loc16_64.13.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc16_64.1.temp, i32 0, i32 1, !dbg !16
// CHECK:STDOUT:   %.loc16_64.14.Continue = getelementptr inbounds nuw [8 x i8], ptr %.loc16_64.13.payload, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   %tuple.elem0.loc16_64.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc16_64.14.Continue, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   %.loc16_64.15 = load i32, ptr %tuple.elem0.loc16_64.2.tuple.elem, align 4, !dbg !16
// CHECK:STDOUT:   call void @_COk.Result.Core.f303d81b2fad85a0(ptr %return, i32 %.loc16_64.15), !dbg !17
// CHECK:STDOUT:   call void @"_COp.fc07cbf55ebcafdd:core.Destroy.Core"(ptr %.loc16_64.1.temp), !dbg !16
// CHECK:STDOUT:   ret void, !dbg !18
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_Z13may_throw_intv.carbon_thunk.() #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   %call = invoke noundef i32 @_Z13may_throw_intv()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %0 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %1 = extractvalue { ptr, i32 } %0, 0
// CHECK:STDOUT:   store ptr %1, ptr %exn.slot, align 8
// CHECK:STDOUT:   %2 = extractvalue { ptr, i32 } %0, 1
// CHECK:STDOUT:   store i32 %2, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %3 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 79) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %4 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %4, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %5) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_Z13may_throw_intv.carbon_thunk_catch.(ptr noundef %return, ptr noundef %error) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca i32, align 4
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %error.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !19
// CHECK:STDOUT:   store ptr %error, ptr %error.addr, align 8, !tbaa !22
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !19
// CHECK:STDOUT:   %call = invoke noundef i32 @_Z13may_throw_intv()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   store i32 %call, ptr %0, align 4, !tbaa !24
// CHECK:STDOUT:   store i32 0, ptr %retval, align 4
// CHECK:STDOUT:   br label %return3
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %1 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %2 = extractvalue { ptr, i32 } %1, 0
// CHECK:STDOUT:   store ptr %2, ptr %exn.slot, align 8
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %1, 1
// CHECK:STDOUT:   store i32 %3, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call ptr @__cxa_current_primary_exception() #0
// CHECK:STDOUT:   %5 = load ptr, ptr %error.addr, align 8, !tbaa !22
// CHECK:STDOUT:   store ptr %call1, ptr %5, align 8, !tbaa !25
// CHECK:STDOUT:   store i32 1, ptr %retval, align 4
// CHECK:STDOUT:   invoke void @__cxa_end_catch()
// CHECK:STDOUT:           to label %invoke.cont2 unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont2:                                     ; preds = %catch
// CHECK:STDOUT:   br label %return3
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: return3:                                          ; preds = %invoke.cont2, %invoke.cont
// CHECK:STDOUT:   %6 = load i32, ptr %retval, align 4
// CHECK:STDOUT:   ret i32 %6
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %7 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %8 = extractvalue { ptr, i32 } %7, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %8) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.945345cbed56cb88:core.Destroy.Core"(ptr %self) #0 !dbg !26 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !33 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.216a6481b641f07b:core.Destroy.Core"(ptr %self) #0 !dbg !40 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.1416050363a44083:core.Destroy.Core"(ptr %self) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.ce83c848ce1f6610:core.Destroy.Core"(ptr %self) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.35df57743197bacd:core.Destroy.Core"(ptr %self) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5d21039fd7f08095:core.Destroy.Core"(ptr %self) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !61
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.fc07cbf55ebcafdd:core.Destroy.Core"(ptr %self) #0 !dbg !62 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CG.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc20_17.1.temp = alloca ptr, align 8, !dbg !67
// CHECK:STDOUT:   %.loc20_17.8.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !67
// CHECK:STDOUT:   %.loc20_18.1.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !67
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc20_17.1.temp), !dbg !67
// CHECK:STDOUT:   %may_throw__carbon_catching_thunk.call = call i32 @_Z9may_throwv.carbon_thunk_catch.(ptr %.loc20_17.1.temp), !dbg !67
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call = icmp eq i32 %may_throw__carbon_catching_thunk.call, 0, !dbg !67
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc20_17.8.temp), !dbg !67
// CHECK:STDOUT:   br i1 %Int.as.EqWith.impl.Equal.call, label %.loc20_17.1, label %.loc20_17.2, !dbg !67
// CHECK:STDOUT:
// CHECK:STDOUT: .loc20_17.1:                                      ; preds = %entry
// CHECK:STDOUT:   call void @_COk.Result.Core.ee51b1618614817f(ptr %.loc20_17.8.temp), !dbg !67
// CHECK:STDOUT:   br label %.loc20_17.3, !dbg !67
// CHECK:STDOUT:
// CHECK:STDOUT: .loc20_17.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc20_17.11 = load ptr, ptr %.loc20_17.1.temp, align 8, !dbg !67
// CHECK:STDOUT:   call void @_CErr.Result.Core.ee51b1618614817f(ptr %.loc20_17.8.temp, ptr %.loc20_17.11), !dbg !67
// CHECK:STDOUT:   br label %.loc20_17.3, !dbg !67
// CHECK:STDOUT:
// CHECK:STDOUT: .loc20_17.3:                                      ; preds = %.loc20_17.2, %.loc20_17.1
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc20_18.1.temp), !dbg !67
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.ee51b1618614817f"(ptr %.loc20_18.1.temp, ptr %.loc20_17.8.temp), !dbg !67
// CHECK:STDOUT:   %.loc20_18.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc20_18.1.temp, i32 0, i32 0, !dbg !67
// CHECK:STDOUT:   %.loc20_18.6 = load i8, ptr %.loc20_18.5.discriminant, align 1, !dbg !67
// CHECK:STDOUT:   %.loc20_18.61 = trunc i8 %.loc20_18.6 to i1, !dbg !67
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc20_18.61, !dbg !67
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc20_18.1, label %.loc20_18.2, !dbg !67
// CHECK:STDOUT:
// CHECK:STDOUT: .loc20_18.1:                                      ; preds = %.loc20_17.3
// CHECK:STDOUT:   %.loc20_18.9.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc20_18.1.temp, i32 0, i32 1, !dbg !67
// CHECK:STDOUT:   %.loc20_18.10.Break = getelementptr inbounds nuw [8 x i8], ptr %.loc20_18.9.payload, i32 0, i32 0, !dbg !67
// CHECK:STDOUT:   %tuple.elem0.loc20_18.1.tuple.elem = getelementptr inbounds nuw { ptr }, ptr %.loc20_18.10.Break, i32 0, i32 0, !dbg !67
// CHECK:STDOUT:   %.loc20_18.11 = load ptr, ptr %tuple.elem0.loc20_18.1.tuple.elem, align 8, !dbg !67
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.ee51b1618614817f"(ptr %return, ptr %.loc20_18.11), !dbg !67
// CHECK:STDOUT:   call void @"_COp.b62856d381b8196a:core.Destroy.Core"(ptr %.loc20_18.1.temp), !dbg !67
// CHECK:STDOUT:   ret void, !dbg !67
// CHECK:STDOUT:
// CHECK:STDOUT: .loc20_18.2:                                      ; preds = %.loc20_17.3
// CHECK:STDOUT:   %.loc20_18.13.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc20_18.1.temp, i32 0, i32 1, !dbg !67
// CHECK:STDOUT:   %.loc20_18.14.Continue = getelementptr inbounds nuw [8 x i8], ptr %.loc20_18.13.payload, i32 0, i32 0, !dbg !67
// CHECK:STDOUT:   %tuple.elem0.loc20_18.2.tuple.elem = getelementptr inbounds nuw { {} }, ptr %.loc20_18.14.Continue, i32 0, i32 0, !dbg !67
// CHECK:STDOUT:   call void @"_COp.b62856d381b8196a:core.Destroy.Core"(ptr %.loc20_18.1.temp), !dbg !67
// CHECK:STDOUT:   call void @_COk.Result.Core.ee51b1618614817f(ptr %return), !dbg !68
// CHECK:STDOUT:   ret void, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z9may_throwv.carbon_thunk.() #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   invoke void @_Z9may_throwv()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %0 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %1 = extractvalue { ptr, i32 } %0, 0
// CHECK:STDOUT:   store ptr %1, ptr %exn.slot, align 8
// CHECK:STDOUT:   %2 = extractvalue { ptr, i32 } %0, 1
// CHECK:STDOUT:   store i32 %2, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %3 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.1, i64 noundef 75) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %4 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %4, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %5) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_Z9may_throwv.carbon_thunk_catch.(ptr noundef %error) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca i32, align 4
// CHECK:STDOUT:   %error.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %error, ptr %error.addr, align 8, !tbaa !22
// CHECK:STDOUT:   invoke void @_Z9may_throwv()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   store i32 0, ptr %retval, align 4
// CHECK:STDOUT:   br label %return
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %0 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %1 = extractvalue { ptr, i32 } %0, 0
// CHECK:STDOUT:   store ptr %1, ptr %exn.slot, align 8
// CHECK:STDOUT:   %2 = extractvalue { ptr, i32 } %0, 1
// CHECK:STDOUT:   store i32 %2, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %3 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call ptr @__cxa_current_primary_exception() #0
// CHECK:STDOUT:   %4 = load ptr, ptr %error.addr, align 8, !tbaa !22
// CHECK:STDOUT:   store ptr %call, ptr %4, align 8, !tbaa !25
// CHECK:STDOUT:   store i32 1, ptr %retval, align 4
// CHECK:STDOUT:   invoke void @__cxa_end_catch()
// CHECK:STDOUT:           to label %invoke.cont1 unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont1:                                     ; preds = %catch
// CHECK:STDOUT:   br label %return
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: return:                                           ; preds = %invoke.cont1, %invoke.cont
// CHECK:STDOUT:   %5 = load i32, ptr %retval, align 4
// CHECK:STDOUT:   ret i32 %5
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %7) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.363f24f1872db271:core.Destroy.Core"(ptr %self) #0 !dbg !70 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !73
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.f92b0f887c91384f:core.Destroy.Core"(ptr %self) #0 !dbg !74 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.ce933ed805f9fd5c:core.Destroy.Core"(ptr %self) #0 !dbg !78 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !81
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.b62856d381b8196a:core.Destroy.Core"(ptr %self) #0 !dbg !82 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !85
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CM.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %c, ptr %p) #0 !dbg !86 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.var = alloca i32, align 4, !dbg !92
// CHECK:STDOUT:   %.loc25_22.1.temp = alloca i32, align 4, !dbg !93
// CHECK:STDOUT:   %.loc25_22.2.temp = alloca ptr, align 8, !dbg !93
// CHECK:STDOUT:   %.loc25_22.9.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !93
// CHECK:STDOUT:   %.loc25_23.1.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !93
// CHECK:STDOUT:   %b.var = alloca i32, align 4, !dbg !94
// CHECK:STDOUT:   %.loc26_26.1.temp = alloca i32, align 4, !dbg !95
// CHECK:STDOUT:   %.loc26_26.2.temp = alloca ptr, align 8, !dbg !95
// CHECK:STDOUT:   %.loc26_26.9.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !95
// CHECK:STDOUT:   %.loc26_27.1.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !95
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a.var), !dbg !92
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc25_22.1.temp), !dbg !93
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc25_22.2.temp), !dbg !93
// CHECK:STDOUT:   %get__carbon_catching_thunk.call = call i32 @_ZNK1C3getEv.carbon_thunk_catch._(ptr %c, ptr %.loc25_22.1.temp, ptr %.loc25_22.2.temp), !dbg !93
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call.loc25 = icmp eq i32 %get__carbon_catching_thunk.call, 0, !dbg !93
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc25_22.9.temp), !dbg !93
// CHECK:STDOUT:   br i1 %Int.as.EqWith.impl.Equal.call.loc25, label %.loc25_22.1, label %.loc25_22.2, !dbg !93
// CHECK:STDOUT:
// CHECK:STDOUT: .loc25_22.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc25_22.10 = load i32, ptr %.loc25_22.1.temp, align 4, !dbg !93
// CHECK:STDOUT:   call void @_COk.Result.Core.f303d81b2fad85a0(ptr %.loc25_22.9.temp, i32 %.loc25_22.10), !dbg !93
// CHECK:STDOUT:   br label %.loc25_22.3, !dbg !93
// CHECK:STDOUT:
// CHECK:STDOUT: .loc25_22.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc25_22.13 = load ptr, ptr %.loc25_22.2.temp, align 8, !dbg !93
// CHECK:STDOUT:   call void @_CErr.Result.Core.f303d81b2fad85a0(ptr %.loc25_22.9.temp, ptr %.loc25_22.13), !dbg !93
// CHECK:STDOUT:   br label %.loc25_22.3, !dbg !93
// CHECK:STDOUT:
// CHECK:STDOUT: .loc25_22.3:                                      ; preds = %.loc25_22.2, %.loc25_22.1
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc25_23.1.temp), !dbg !93
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr %.loc25_23.1.temp, ptr %.loc25_22.9.temp), !dbg !93
// CHECK:STDOUT:   %.loc25_23.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc25_23.1.temp, i32 0, i32 0, !dbg !93
// CHECK:STDOUT:   %.loc25_23.6 = load i8, ptr %.loc25_23.5.discriminant, align 1, !dbg !93
// CHECK:STDOUT:   %.loc25_23.61 = trunc i8 %.loc25_23.6 to i1, !dbg !93
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc25 = icmp eq i1 true, %.loc25_23.61, !dbg !93
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc25, label %.loc25_23.1, label %.loc25_23.2, !dbg !93
// CHECK:STDOUT:
// CHECK:STDOUT: .loc25_23.1:                                      ; preds = %.loc25_22.3
// CHECK:STDOUT:   %.loc25_23.9.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc25_23.1.temp, i32 0, i32 1, !dbg !93
// CHECK:STDOUT:   %.loc25_23.10.Break = getelementptr inbounds nuw [8 x i8], ptr %.loc25_23.9.payload, i32 0, i32 0, !dbg !93
// CHECK:STDOUT:   %tuple.elem0.loc25_23.1.tuple.elem = getelementptr inbounds nuw { ptr }, ptr %.loc25_23.10.Break, i32 0, i32 0, !dbg !93
// CHECK:STDOUT:   %.loc25_23.11 = load ptr, ptr %tuple.elem0.loc25_23.1.tuple.elem, align 8, !dbg !93
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr %return, ptr %.loc25_23.11), !dbg !93
// CHECK:STDOUT:   call void @"_COp.fc07cbf55ebcafdd:core.Destroy.Core"(ptr %.loc25_23.1.temp), !dbg !93
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %a.var), !dbg !92
// CHECK:STDOUT:   ret void, !dbg !93
// CHECK:STDOUT:
// CHECK:STDOUT: .loc25_23.2:                                      ; preds = %.loc25_22.3
// CHECK:STDOUT:   %.loc25_23.13.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc25_23.1.temp, i32 0, i32 1, !dbg !93
// CHECK:STDOUT:   %.loc25_23.14.Continue = getelementptr inbounds nuw [8 x i8], ptr %.loc25_23.13.payload, i32 0, i32 0, !dbg !93
// CHECK:STDOUT:   %tuple.elem0.loc25_23.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc25_23.14.Continue, i32 0, i32 0, !dbg !93
// CHECK:STDOUT:   %.loc25_23.15 = load i32, ptr %tuple.elem0.loc25_23.2.tuple.elem, align 4, !dbg !93
// CHECK:STDOUT:   store i32 %.loc25_23.15, ptr %a.var, align 4, !dbg !92
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !94
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc26_26.1.temp), !dbg !95
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc26_26.2.temp), !dbg !95
// CHECK:STDOUT:   %mutate__carbon_catching_thunk.call = call i32 @_ZN1C6mutateEv.carbon_thunk_catch.r(ptr %p, ptr %.loc26_26.1.temp, ptr %.loc26_26.2.temp), !dbg !95
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call.loc26 = icmp eq i32 %mutate__carbon_catching_thunk.call, 0, !dbg !95
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc26_26.9.temp), !dbg !95
// CHECK:STDOUT:   br i1 %Int.as.EqWith.impl.Equal.call.loc26, label %.loc26_26.1, label %.loc26_26.2, !dbg !95
// CHECK:STDOUT:
// CHECK:STDOUT: .loc26_26.1:                                      ; preds = %.loc25_23.2
// CHECK:STDOUT:   %.loc26_26.10 = load i32, ptr %.loc26_26.1.temp, align 4, !dbg !95
// CHECK:STDOUT:   call void @_COk.Result.Core.f303d81b2fad85a0(ptr %.loc26_26.9.temp, i32 %.loc26_26.10), !dbg !95
// CHECK:STDOUT:   br label %.loc26_26.3, !dbg !95
// CHECK:STDOUT:
// CHECK:STDOUT: .loc26_26.2:                                      ; preds = %.loc25_23.2
// CHECK:STDOUT:   %.loc26_26.13 = load ptr, ptr %.loc26_26.2.temp, align 8, !dbg !95
// CHECK:STDOUT:   call void @_CErr.Result.Core.f303d81b2fad85a0(ptr %.loc26_26.9.temp, ptr %.loc26_26.13), !dbg !95
// CHECK:STDOUT:   br label %.loc26_26.3, !dbg !95
// CHECK:STDOUT:
// CHECK:STDOUT: .loc26_26.3:                                      ; preds = %.loc26_26.2, %.loc26_26.1
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc26_27.1.temp), !dbg !95
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr %.loc26_27.1.temp, ptr %.loc26_26.9.temp), !dbg !95
// CHECK:STDOUT:   %.loc26_27.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc26_27.1.temp, i32 0, i32 0, !dbg !95
// CHECK:STDOUT:   %.loc26_27.6 = load i8, ptr %.loc26_27.5.discriminant, align 1, !dbg !95
// CHECK:STDOUT:   %.loc26_27.62 = trunc i8 %.loc26_27.6 to i1, !dbg !95
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc26 = icmp eq i1 true, %.loc26_27.62, !dbg !95
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc26, label %.loc26_27.1, label %.loc26_27.2, !dbg !95
// CHECK:STDOUT:
// CHECK:STDOUT: .loc26_27.1:                                      ; preds = %.loc26_26.3
// CHECK:STDOUT:   %.loc26_27.9.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc26_27.1.temp, i32 0, i32 1, !dbg !95
// CHECK:STDOUT:   %.loc26_27.10.Break = getelementptr inbounds nuw [8 x i8], ptr %.loc26_27.9.payload, i32 0, i32 0, !dbg !95
// CHECK:STDOUT:   %tuple.elem0.loc26_27.1.tuple.elem = getelementptr inbounds nuw { ptr }, ptr %.loc26_27.10.Break, i32 0, i32 0, !dbg !95
// CHECK:STDOUT:   %.loc26_27.11 = load ptr, ptr %tuple.elem0.loc26_27.1.tuple.elem, align 8, !dbg !95
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr %return, ptr %.loc26_27.11), !dbg !95
// CHECK:STDOUT:   call void @"_COp.fc07cbf55ebcafdd:core.Destroy.Core"(ptr %.loc26_27.1.temp), !dbg !95
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %b.var), !dbg !94
// CHECK:STDOUT:   call void @"_COp.fc07cbf55ebcafdd:core.Destroy.Core"(ptr %.loc25_23.1.temp), !dbg !93
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %a.var), !dbg !92
// CHECK:STDOUT:   ret void, !dbg !95
// CHECK:STDOUT:
// CHECK:STDOUT: .loc26_27.2:                                      ; preds = %.loc26_26.3
// CHECK:STDOUT:   %.loc26_27.13.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc26_27.1.temp, i32 0, i32 1, !dbg !95
// CHECK:STDOUT:   %.loc26_27.14.Continue = getelementptr inbounds nuw [8 x i8], ptr %.loc26_27.13.payload, i32 0, i32 0, !dbg !95
// CHECK:STDOUT:   %tuple.elem0.loc26_27.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc26_27.14.Continue, i32 0, i32 0, !dbg !95
// CHECK:STDOUT:   %.loc26_27.15 = load i32, ptr %tuple.elem0.loc26_27.2.tuple.elem, align 4, !dbg !95
// CHECK:STDOUT:   store i32 %.loc26_27.15, ptr %b.var, align 4, !dbg !94
// CHECK:STDOUT:   %.loc27_45 = load i32, ptr %a.var, align 4, !dbg !96
// CHECK:STDOUT:   %.loc27_49 = load i32, ptr %b.var, align 4, !dbg !97
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc27_45, %.loc27_49, !dbg !96
// CHECK:STDOUT:   call void @_COk.Result.Core.f303d81b2fad85a0(ptr %return, i32 %Int.as.AddWith.impl.Op.call), !dbg !98
// CHECK:STDOUT:   call void @"_COp.fc07cbf55ebcafdd:core.Destroy.Core"(ptr %.loc26_27.1.temp), !dbg !95
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %b.var), !dbg !94
// CHECK:STDOUT:   call void @"_COp.fc07cbf55ebcafdd:core.Destroy.Core"(ptr %.loc25_23.1.temp), !dbg !93
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %a.var), !dbg !92
// CHECK:STDOUT:   ret void, !dbg !99
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_ZNK1C3getEv.carbon_thunk._(ptr noundef nonnull align 1 dereferenceable(1) %this) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !100
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !100, !nonnull !102
// CHECK:STDOUT:   %call = invoke noundef i32 @_ZNK1C3getEv(ptr noundef nonnull align 1 dereferenceable(1) %0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %1 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %2 = extractvalue { ptr, i32 } %1, 0
// CHECK:STDOUT:   store ptr %2, ptr %exn.slot, align 8
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %1, 1
// CHECK:STDOUT:   store i32 %3, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.2, i64 noundef 72) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %6) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_ZNK1C3getEv.carbon_thunk_catch._(ptr noundef nonnull align 1 dereferenceable(1) %this, ptr noundef %return, ptr noundef %error) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca i32, align 4
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %error.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !100
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !19
// CHECK:STDOUT:   store ptr %error, ptr %error.addr, align 8, !tbaa !22
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !19
// CHECK:STDOUT:   %1 = load ptr, ptr %this.addr, align 8, !tbaa !100, !nonnull !102
// CHECK:STDOUT:   %call = invoke noundef i32 @_ZNK1C3getEv(ptr noundef nonnull align 1 dereferenceable(1) %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   store i32 %call, ptr %0, align 4, !tbaa !24
// CHECK:STDOUT:   store i32 0, ptr %retval, align 4
// CHECK:STDOUT:   br label %return3
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %2 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %2, 0
// CHECK:STDOUT:   store ptr %3, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %2, 1
// CHECK:STDOUT:   store i32 %4, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call ptr @__cxa_current_primary_exception() #0
// CHECK:STDOUT:   %6 = load ptr, ptr %error.addr, align 8, !tbaa !22
// CHECK:STDOUT:   store ptr %call1, ptr %6, align 8, !tbaa !25
// CHECK:STDOUT:   store i32 1, ptr %retval, align 4
// CHECK:STDOUT:   invoke void @__cxa_end_catch()
// CHECK:STDOUT:           to label %invoke.cont2 unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont2:                                     ; preds = %catch
// CHECK:STDOUT:   br label %return3
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: return3:                                          ; preds = %invoke.cont2, %invoke.cont
// CHECK:STDOUT:   %7 = load i32, ptr %retval, align 4
// CHECK:STDOUT:   ret i32 %7
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %8 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %9 = extractvalue { ptr, i32 } %8, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %9) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_ZN1C6mutateEv.carbon_thunk.r(ptr noundef nonnull align 1 dereferenceable(1) %this) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !100
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !100, !nonnull !102
// CHECK:STDOUT:   %call = invoke noundef i32 @_ZN1C6mutateEv(ptr noundef nonnull align 1 dereferenceable(1) %0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %1 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %2 = extractvalue { ptr, i32 } %1, 0
// CHECK:STDOUT:   store ptr %2, ptr %exn.slot, align 8
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %1, 1
// CHECK:STDOUT:   store i32 %3, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.3, i64 noundef 75) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %6) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_ZN1C6mutateEv.carbon_thunk_catch.r(ptr noundef nonnull align 1 dereferenceable(1) %this, ptr noundef %return, ptr noundef %error) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca i32, align 4
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %error.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !100
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !19
// CHECK:STDOUT:   store ptr %error, ptr %error.addr, align 8, !tbaa !22
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !19
// CHECK:STDOUT:   %1 = load ptr, ptr %this.addr, align 8, !tbaa !100, !nonnull !102
// CHECK:STDOUT:   %call = invoke noundef i32 @_ZN1C6mutateEv(ptr noundef nonnull align 1 dereferenceable(1) %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   store i32 %call, ptr %0, align 4, !tbaa !24
// CHECK:STDOUT:   store i32 0, ptr %retval, align 4
// CHECK:STDOUT:   br label %return3
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %2 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %2, 0
// CHECK:STDOUT:   store ptr %3, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %2, 1
// CHECK:STDOUT:   store i32 %4, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call ptr @__cxa_current_primary_exception() #0
// CHECK:STDOUT:   %6 = load ptr, ptr %error.addr, align 8, !tbaa !22
// CHECK:STDOUT:   store ptr %call1, ptr %6, align 8, !tbaa !25
// CHECK:STDOUT:   store i32 1, ptr %retval, align 4
// CHECK:STDOUT:   invoke void @__cxa_end_catch()
// CHECK:STDOUT:           to label %invoke.cont2 unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont2:                                     ; preds = %catch
// CHECK:STDOUT:   br label %return3
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: return3:                                          ; preds = %invoke.cont2, %invoke.cont
// CHECK:STDOUT:   %7 = load i32, ptr %retval, align 4
// CHECK:STDOUT:   ret i32 %7
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %8 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %9 = extractvalue { ptr, i32 } %8, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %9) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.Result.Core.f303d81b2fad85a0(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !103 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !109
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !109
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !109
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !110
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @Result.val.e39.anon, i64 16, i1 false), !dbg !109
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Ok, align 4, !dbg !109
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Ok, i32 0, i32 0, !dbg !110
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !110
// CHECK:STDOUT:   ret void, !dbg !109
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.Result.Core.f303d81b2fad85a0(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %_) #0 !dbg !111 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !116
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !116
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !116
// CHECK:STDOUT:   %tuple.init = insertvalue { ptr } poison, ptr %_, 0, !dbg !116
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @Result.val.207.anon, i64 16, i1 false), !dbg !116
// CHECK:STDOUT:   store { ptr } %tuple.init, ptr %Err, align 8, !dbg !116
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { ptr }, ptr %Err, i32 0, i32 0, !dbg !116
// CHECK:STDOUT:   store ptr %_, ptr %tuple.elem, align 8, !dbg !116
// CHECK:STDOUT:   ret void, !dbg !116
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %self) #0 !dbg !117 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !120
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !120
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !120
// CHECK:STDOUT:   %3 = icmp eq i1 false, %2, !dbg !120
// CHECK:STDOUT:   br i1 %3, label %4, label %6, !dbg !120
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !120
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !120
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Ok, i32 0, i32 0, !dbg !120
// CHECK:STDOUT:   %5 = load i32, ptr %tuple.elem, align 4, !dbg !120
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.f303d81b2fad85a0(ptr %return, i32 %5), !dbg !121
// CHECK:STDOUT:   ret void, !dbg !122
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %0
// CHECK:STDOUT:   %discriminant1 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !123
// CHECK:STDOUT:   %7 = load i8, ptr %discriminant1, align 1, !dbg !123
// CHECK:STDOUT:   %8 = trunc i8 %7 to i1, !dbg !123
// CHECK:STDOUT:   %9 = icmp eq i1 true, %8, !dbg !123
// CHECK:STDOUT:   br i1 %9, label %10, label %12, !dbg !123
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %6
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !123
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [8 x i8], ptr %payload2, i32 0, i32 0, !dbg !123
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { ptr }, ptr %Err, i32 0, i32 0, !dbg !123
// CHECK:STDOUT:   %11 = load ptr, ptr %tuple.elem3, align 8, !dbg !123
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.f303d81b2fad85a0(ptr %return, ptr %11), !dbg !124
// CHECK:STDOUT:   ret void, !dbg !125
// CHECK:STDOUT:
// CHECK:STDOUT: 12:                                               ; preds = %6
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr %return, ptr %self), !dbg !126
// CHECK:STDOUT:   ret void, !dbg !127
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %b) #0 !dbg !128 {
// CHECK:STDOUT:   call void @_CErr.Result.Core.f303d81b2fad85a0(ptr %return, ptr %b), !dbg !131
// CHECK:STDOUT:   ret void, !dbg !132
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.Result.Core.ee51b1618614817f(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return) #0 !dbg !133 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !134
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !134
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !134
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @Result.val.aa3.anon, i64 16, i1 false), !dbg !134
// CHECK:STDOUT:   store { {} } poison, ptr %Ok, align 1, !dbg !134
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Ok, i32 0, i32 0, !dbg !135
// CHECK:STDOUT:   ret void, !dbg !134
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.Result.Core.ee51b1618614817f(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %_) #0 !dbg !136 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !139
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !139
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !139
// CHECK:STDOUT:   %tuple.init = insertvalue { ptr } poison, ptr %_, 0, !dbg !139
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @Result.val.404.anon, i64 16, i1 false), !dbg !139
// CHECK:STDOUT:   store { ptr } %tuple.init, ptr %Err, align 8, !dbg !139
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { ptr }, ptr %Err, i32 0, i32 0, !dbg !139
// CHECK:STDOUT:   store ptr %_, ptr %tuple.elem, align 8, !dbg !139
// CHECK:STDOUT:   ret void, !dbg !139
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.ee51b1618614817f"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %self) #0 !dbg !140 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !143
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !143
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !143
// CHECK:STDOUT:   %3 = icmp eq i1 false, %2, !dbg !143
// CHECK:STDOUT:   br i1 %3, label %4, label %5, !dbg !143
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !143
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !143
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Ok, i32 0, i32 0, !dbg !143
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.ee51b1618614817f(ptr %return), !dbg !144
// CHECK:STDOUT:   ret void, !dbg !145
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %0
// CHECK:STDOUT:   %discriminant1 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !146
// CHECK:STDOUT:   %6 = load i8, ptr %discriminant1, align 1, !dbg !146
// CHECK:STDOUT:   %7 = trunc i8 %6 to i1, !dbg !146
// CHECK:STDOUT:   %8 = icmp eq i1 true, %7, !dbg !146
// CHECK:STDOUT:   br i1 %8, label %9, label %11, !dbg !146
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %5
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !146
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [8 x i8], ptr %payload2, i32 0, i32 0, !dbg !146
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { ptr }, ptr %Err, i32 0, i32 0, !dbg !146
// CHECK:STDOUT:   %10 = load ptr, ptr %tuple.elem3, align 8, !dbg !146
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.ee51b1618614817f(ptr %return, ptr %10), !dbg !147
// CHECK:STDOUT:   ret void, !dbg !148
// CHECK:STDOUT:
// CHECK:STDOUT: 11:                                               ; preds = %5
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.ee51b1618614817f"(ptr %return, ptr %self), !dbg !149
// CHECK:STDOUT:   ret void, !dbg !150
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.ee51b1618614817f"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %b) #0 !dbg !151 {
// CHECK:STDOUT:   call void @_CErr.Result.Core.ee51b1618614817f(ptr %return, ptr %b), !dbg !154
// CHECK:STDOUT:   ret void, !dbg !155
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.f303d81b2fad85a0(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !156 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !160
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !160
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !160
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !161
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.908.anon, i64 16, i1 false), !dbg !160
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !160
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !161
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !161
// CHECK:STDOUT:   ret void, !dbg !160
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.f303d81b2fad85a0(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %_) #0 !dbg !162 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !165
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !165
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !165
// CHECK:STDOUT:   %tuple.init = insertvalue { ptr } poison, ptr %_, 0, !dbg !165
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.401.anon, i64 16, i1 false), !dbg !165
// CHECK:STDOUT:   store { ptr } %tuple.init, ptr %Break, align 8, !dbg !165
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { ptr }, ptr %Break, i32 0, i32 0, !dbg !165
// CHECK:STDOUT:   store ptr %_, ptr %tuple.elem, align 8, !dbg !165
// CHECK:STDOUT:   ret void, !dbg !165
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.ee51b1618614817f(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return) #0 !dbg !166 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !167
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !167
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !167
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.e34.anon, i64 16, i1 false), !dbg !167
// CHECK:STDOUT:   store { {} } poison, ptr %Continue, align 1, !dbg !167
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Continue, i32 0, i32 0, !dbg !168
// CHECK:STDOUT:   ret void, !dbg !167
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.ee51b1618614817f(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %_) #0 !dbg !169 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !172
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !172
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !172
// CHECK:STDOUT:   %tuple.init = insertvalue { ptr } poison, ptr %_, 0, !dbg !172
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.98f.anon, i64 16, i1 false), !dbg !172
// CHECK:STDOUT:   store { ptr } %tuple.init, ptr %Break, align 8, !dbg !172
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { ptr }, ptr %Break, i32 0, i32 0, !dbg !172
// CHECK:STDOUT:   store ptr %_, ptr %tuple.elem, align 8, !dbg !172
// CHECK:STDOUT:   ret void, !dbg !172
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare noundef i32 @_Z13may_throw_intv() #3
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #4
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #5 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare ptr @__cxa_current_primary_exception() #4
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_end_catch()
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_Z9may_throwv() #3
// CHECK:STDOUT:
// CHECK:STDOUT: declare noundef i32 @_ZNK1C3getEv(ptr noundef nonnull align 1 dereferenceable(1)) #3
// CHECK:STDOUT:
// CHECK:STDOUT: declare noundef i32 @_ZN1C6mutateEv(ptr noundef nonnull align 1 dereferenceable(1)) #3
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_COp.fc07cbf55ebcafdd:core.Destroy.Core", { 0, 1, 2, 3, 4, 6, 5 }
// CHECK:STDOUT: uselistorder ptr @"_COp.b62856d381b8196a:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_COk.Result.Core.f303d81b2fad85a0, { 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CErr.Result.Core.f303d81b2fad85a0, { 0, 3, 2, 1 }
// CHECK:STDOUT: uselistorder ptr @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0", { 0, 3, 2, 1 }
// CHECK:STDOUT: uselistorder ptr @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0", { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_COk.Result.Core.ee51b1618614817f, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 0, 1, 2, 3, 7, 6, 5, 4 }
// CHECK:STDOUT: uselistorder ptr @_Z13may_throw_intv, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 7, 6, 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_begin_catch, { 7, 8, 6, 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_rethrow, { 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 7, 6, 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_current_primary_exception, { 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_end_catch, { 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_Z9may_throwv, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_ZNK1C3getEv, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_ZN1C6mutateEv, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3, !4, !5, !6}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!7}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "catching_thunk.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !3 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !4 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !5 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !6 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !7 = !{!8, !9, i64 0}
// CHECK:STDOUT: !8 = !{!"__libc_errno", !9, i64 0}
// CHECK:STDOUT: !9 = !{!"int", !10, i64 0}
// CHECK:STDOUT: !10 = !{!"omnipotent char", !11, i64 0}
// CHECK:STDOUT: !11 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !1, line: 15, type: !13, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{!15}
// CHECK:STDOUT: !15 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !16 = !DILocation(line: 16, column: 45, scope: !12)
// CHECK:STDOUT: !17 = !DILocation(line: 16, column: 10, scope: !12)
// CHECK:STDOUT: !18 = !DILocation(line: 16, column: 3, scope: !12)
// CHECK:STDOUT: !19 = !{!20, !20, i64 0}
// CHECK:STDOUT: !20 = !{!"p1 int", !21, i64 0}
// CHECK:STDOUT: !21 = !{!"any pointer", !10, i64 0}
// CHECK:STDOUT: !22 = !{!23, !23, i64 0}
// CHECK:STDOUT: !23 = !{!"any p2 pointer", !21, i64 0}
// CHECK:STDOUT: !24 = !{!9, !9, i64 0}
// CHECK:STDOUT: !25 = !{!21, !21, i64 0}
// CHECK:STDOUT: !26 = distinct !DISubprogram(name: "Op", linkageName: "_COp.945345cbed56cb88:core.Destroy.Core", scope: null, file: !1, line: 16, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !30)
// CHECK:STDOUT: !27 = !DISubroutineType(types: !28)
// CHECK:STDOUT: !28 = !{null, !29}
// CHECK:STDOUT: !29 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !30 = !{!31}
// CHECK:STDOUT: !31 = !DILocalVariable(arg: 1, scope: !26, type: !29)
// CHECK:STDOUT: !32 = !DILocation(line: 16, column: 45, scope: !26)
// CHECK:STDOUT: !33 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 16, type: !34, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !37)
// CHECK:STDOUT: !34 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !35 = !{null, !36}
// CHECK:STDOUT: !36 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !37 = !{!38}
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !33, type: !36)
// CHECK:STDOUT: !39 = !DILocation(line: 16, column: 45, scope: !33)
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "Op", linkageName: "_COp.216a6481b641f07b:core.Destroy.Core", scope: null, file: !1, line: 16, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !43)
// CHECK:STDOUT: !41 = !DISubroutineType(types: !42)
// CHECK:STDOUT: !42 = !{null, !15}
// CHECK:STDOUT: !43 = !{!44}
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !40, type: !15)
// CHECK:STDOUT: !45 = !DILocation(line: 16, column: 45, scope: !40)
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "Op", linkageName: "_COp.1416050363a44083:core.Destroy.Core", scope: null, file: !1, line: 16, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !47)
// CHECK:STDOUT: !47 = !{!48}
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !46, type: !15)
// CHECK:STDOUT: !49 = !DILocation(line: 16, column: 45, scope: !46)
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "Op", linkageName: "_COp.ce83c848ce1f6610:core.Destroy.Core", scope: null, file: !1, line: 16, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !51)
// CHECK:STDOUT: !51 = !{!52}
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !50, type: !15)
// CHECK:STDOUT: !53 = !DILocation(line: 16, column: 45, scope: !50)
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "Op", linkageName: "_COp.35df57743197bacd:core.Destroy.Core", scope: null, file: !1, line: 16, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !55)
// CHECK:STDOUT: !55 = !{!56}
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !54, type: !15)
// CHECK:STDOUT: !57 = !DILocation(line: 16, column: 45, scope: !54)
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5d21039fd7f08095:core.Destroy.Core", scope: null, file: !1, line: 16, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !59)
// CHECK:STDOUT: !59 = !{!60}
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !58, type: !15)
// CHECK:STDOUT: !61 = !DILocation(line: 16, column: 45, scope: !58)
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "Op", linkageName: "_COp.fc07cbf55ebcafdd:core.Destroy.Core", scope: null, file: !1, line: 16, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !63)
// CHECK:STDOUT: !63 = !{!64}
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !62, type: !15)
// CHECK:STDOUT: !65 = !DILocation(line: 16, column: 45, scope: !62)
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main", scope: null, file: !1, line: 19, type: !13, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !67 = !DILocation(line: 20, column: 3, scope: !66)
// CHECK:STDOUT: !68 = !DILocation(line: 21, column: 10, scope: !66)
// CHECK:STDOUT: !69 = !DILocation(line: 21, column: 3, scope: !66)
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "Op", linkageName: "_COp.363f24f1872db271:core.Destroy.Core", scope: null, file: !1, line: 20, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !71)
// CHECK:STDOUT: !71 = !{!72}
// CHECK:STDOUT: !72 = !DILocalVariable(arg: 1, scope: !70, type: !15)
// CHECK:STDOUT: !73 = !DILocation(line: 20, column: 3, scope: !70)
// CHECK:STDOUT: !74 = distinct !DISubprogram(name: "Op", linkageName: "_COp.f92b0f887c91384f:core.Destroy.Core", scope: null, file: !1, line: 20, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !75)
// CHECK:STDOUT: !75 = !{!76}
// CHECK:STDOUT: !76 = !DILocalVariable(arg: 1, scope: !74, type: !15)
// CHECK:STDOUT: !77 = !DILocation(line: 20, column: 3, scope: !74)
// CHECK:STDOUT: !78 = distinct !DISubprogram(name: "Op", linkageName: "_COp.ce933ed805f9fd5c:core.Destroy.Core", scope: null, file: !1, line: 20, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !79)
// CHECK:STDOUT: !79 = !{!80}
// CHECK:STDOUT: !80 = !DILocalVariable(arg: 1, scope: !78, type: !15)
// CHECK:STDOUT: !81 = !DILocation(line: 20, column: 3, scope: !78)
// CHECK:STDOUT: !82 = distinct !DISubprogram(name: "Op", linkageName: "_COp.b62856d381b8196a:core.Destroy.Core", scope: null, file: !1, line: 20, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !83)
// CHECK:STDOUT: !83 = !{!84}
// CHECK:STDOUT: !84 = !DILocalVariable(arg: 1, scope: !82, type: !15)
// CHECK:STDOUT: !85 = !DILocation(line: 20, column: 3, scope: !82)
// CHECK:STDOUT: !86 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main", scope: null, file: !1, line: 24, type: !87, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !89)
// CHECK:STDOUT: !87 = !DISubroutineType(types: !88)
// CHECK:STDOUT: !88 = !{!15, !15, !15}
// CHECK:STDOUT: !89 = !{!90, !91}
// CHECK:STDOUT: !90 = !DILocalVariable(arg: 1, scope: !86, type: !15)
// CHECK:STDOUT: !91 = !DILocalVariable(arg: 2, scope: !86, type: !15)
// CHECK:STDOUT: !92 = !DILocation(line: 25, column: 3, scope: !86)
// CHECK:STDOUT: !93 = !DILocation(line: 25, column: 16, scope: !86)
// CHECK:STDOUT: !94 = !DILocation(line: 26, column: 3, scope: !86)
// CHECK:STDOUT: !95 = !DILocation(line: 26, column: 16, scope: !86)
// CHECK:STDOUT: !96 = !DILocation(line: 27, column: 45, scope: !86)
// CHECK:STDOUT: !97 = !DILocation(line: 27, column: 49, scope: !86)
// CHECK:STDOUT: !98 = !DILocation(line: 27, column: 10, scope: !86)
// CHECK:STDOUT: !99 = !DILocation(line: 27, column: 3, scope: !86)
// CHECK:STDOUT: !100 = !{!101, !101, i64 0}
// CHECK:STDOUT: !101 = !{!"p1 _ZTS1C", !21, i64 0}
// CHECK:STDOUT: !102 = !{}
// CHECK:STDOUT: !103 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.Result.Core.f303d81b2fad85a0", scope: null, file: !104, line: 28, type: !105, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !107)
// CHECK:STDOUT: !104 = !DIFile(filename: "{{.*}}/prelude/types/result.carbon", directory: "")
// CHECK:STDOUT: !105 = !DISubroutineType(types: !106)
// CHECK:STDOUT: !106 = !{!15, !36}
// CHECK:STDOUT: !107 = !{!108}
// CHECK:STDOUT: !108 = !DILocalVariable(arg: 1, scope: !103, type: !36)
// CHECK:STDOUT: !109 = !DILocation(line: 28, column: 1, scope: !103)
// CHECK:STDOUT: !110 = !DILocation(line: 29, column: 15, scope: !103)
// CHECK:STDOUT: !111 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.Result.Core.f303d81b2fad85a0", scope: null, file: !104, line: 28, type: !112, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !114)
// CHECK:STDOUT: !112 = !DISubroutineType(types: !113)
// CHECK:STDOUT: !113 = !{!15, !15}
// CHECK:STDOUT: !114 = !{!115}
// CHECK:STDOUT: !115 = !DILocalVariable(arg: 1, scope: !111, type: !15)
// CHECK:STDOUT: !116 = !DILocation(line: 28, column: 1, scope: !111)
// CHECK:STDOUT: !117 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0", scope: null, file: !104, line: 42, type: !112, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !118)
// CHECK:STDOUT: !118 = !{!119}
// CHECK:STDOUT: !119 = !DILocalVariable(arg: 1, scope: !117, type: !15)
// CHECK:STDOUT: !120 = !DILocation(line: 44, column: 7, scope: !117)
// CHECK:STDOUT: !121 = !DILocation(line: 44, column: 34, scope: !117)
// CHECK:STDOUT: !122 = !DILocation(line: 44, column: 27, scope: !117)
// CHECK:STDOUT: !123 = !DILocation(line: 45, column: 7, scope: !117)
// CHECK:STDOUT: !124 = !DILocation(line: 45, column: 35, scope: !117)
// CHECK:STDOUT: !125 = !DILocation(line: 45, column: 28, scope: !117)
// CHECK:STDOUT: !126 = !DILocation(line: 49, column: 12, scope: !117)
// CHECK:STDOUT: !127 = !DILocation(line: 49, column: 5, scope: !117)
// CHECK:STDOUT: !128 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0", scope: null, file: !104, line: 51, type: !112, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !129)
// CHECK:STDOUT: !129 = !{!130}
// CHECK:STDOUT: !130 = !DILocalVariable(arg: 1, scope: !128, type: !15)
// CHECK:STDOUT: !131 = !DILocation(line: 51, column: 39, scope: !128)
// CHECK:STDOUT: !132 = !DILocation(line: 51, column: 32, scope: !128)
// CHECK:STDOUT: !133 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.Result.Core.ee51b1618614817f", scope: null, file: !104, line: 28, type: !13, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !134 = !DILocation(line: 28, column: 1, scope: !133)
// CHECK:STDOUT: !135 = !DILocation(line: 29, column: 15, scope: !133)
// CHECK:STDOUT: !136 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.Result.Core.ee51b1618614817f", scope: null, file: !104, line: 28, type: !112, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !137)
// CHECK:STDOUT: !137 = !{!138}
// CHECK:STDOUT: !138 = !DILocalVariable(arg: 1, scope: !136, type: !15)
// CHECK:STDOUT: !139 = !DILocation(line: 28, column: 1, scope: !136)
// CHECK:STDOUT: !140 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.ee51b1618614817f", scope: null, file: !104, line: 42, type: !112, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !141)
// CHECK:STDOUT: !141 = !{!142}
// CHECK:STDOUT: !142 = !DILocalVariable(arg: 1, scope: !140, type: !15)
// CHECK:STDOUT: !143 = !DILocation(line: 44, column: 7, scope: !140)
// CHECK:STDOUT: !144 = !DILocation(line: 44, column: 34, scope: !140)
// CHECK:STDOUT: !145 = !DILocation(line: 44, column: 27, scope: !140)
// CHECK:STDOUT: !146 = !DILocation(line: 45, column: 7, scope: !140)
// CHECK:STDOUT: !147 = !DILocation(line: 45, column: 35, scope: !140)
// CHECK:STDOUT: !148 = !DILocation(line: 45, column: 28, scope: !140)
// CHECK:STDOUT: !149 = !DILocation(line: 49, column: 12, scope: !140)
// CHECK:STDOUT: !150 = !DILocation(line: 49, column: 5, scope: !140)
// CHECK:STDOUT: !151 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.ee51b1618614817f", scope: null, file: !104, line: 51, type: !112, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !152)
// CHECK:STDOUT: !152 = !{!153}
// CHECK:STDOUT: !153 = !DILocalVariable(arg: 1, scope: !151, type: !15)
// CHECK:STDOUT: !154 = !DILocation(line: 51, column: 39, scope: !151)
// CHECK:STDOUT: !155 = !DILocation(line: 51, column: 32, scope: !151)
// CHECK:STDOUT: !156 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.f303d81b2fad85a0", scope: null, file: !157, line: 21, type: !105, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !158)
// CHECK:STDOUT: !157 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !158 = !{!159}
// CHECK:STDOUT: !159 = !DILocalVariable(arg: 1, scope: !156, type: !36)
// CHECK:STDOUT: !160 = !DILocation(line: 21, column: 1, scope: !156)
// CHECK:STDOUT: !161 = !DILocation(line: 22, column: 21, scope: !156)
// CHECK:STDOUT: !162 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.f303d81b2fad85a0", scope: null, file: !157, line: 21, type: !112, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !163)
// CHECK:STDOUT: !163 = !{!164}
// CHECK:STDOUT: !164 = !DILocalVariable(arg: 1, scope: !162, type: !15)
// CHECK:STDOUT: !165 = !DILocation(line: 21, column: 1, scope: !162)
// CHECK:STDOUT: !166 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.ee51b1618614817f", scope: null, file: !157, line: 21, type: !13, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !167 = !DILocation(line: 21, column: 1, scope: !166)
// CHECK:STDOUT: !168 = !DILocation(line: 22, column: 21, scope: !166)
// CHECK:STDOUT: !169 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.ee51b1618614817f", scope: null, file: !157, line: 21, type: !112, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !170)
// CHECK:STDOUT: !170 = !{!171}
// CHECK:STDOUT: !171 = !DILocalVariable(arg: 1, scope: !169, type: !15)
// CHECK:STDOUT: !172 = !DILocation(line: 21, column: 1, scope: !169)
// CHECK:STDOUT:

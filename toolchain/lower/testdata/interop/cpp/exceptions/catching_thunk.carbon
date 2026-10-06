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
// CHECK:STDOUT: define void @_CF.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return) #0 !dbg !29 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_63.1.temp = alloca i32, align 4, !dbg !32
// CHECK:STDOUT:   %.loc16_63.2.temp = alloca ptr, align 8, !dbg !32
// CHECK:STDOUT:   %.loc16_63.9.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !32
// CHECK:STDOUT:   %.loc16_64.1.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !32
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc16_63.1.temp), !dbg !32
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc16_63.2.temp), !dbg !32
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk.call = call i32 @_Z13may_throw_intv.carbon_thunk_catch.(ptr %.loc16_63.1.temp, ptr %.loc16_63.2.temp), !dbg !32
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call = icmp eq i32 %may_throw_int__carbon_catching_thunk.call, 0, !dbg !32
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc16_63.9.temp), !dbg !32
// CHECK:STDOUT:   br i1 %Int.as.EqWith.impl.Equal.call, label %.loc16_63.1, label %.loc16_63.2, !dbg !32
// CHECK:STDOUT:
// CHECK:STDOUT: .loc16_63.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc16_63.10 = load i32, ptr %.loc16_63.1.temp, align 4, !dbg !32
// CHECK:STDOUT:   call void @_COk.Result.Core.f303d81b2fad85a0(ptr %.loc16_63.9.temp, i32 %.loc16_63.10), !dbg !32
// CHECK:STDOUT:   br label %.loc16_63.3, !dbg !32
// CHECK:STDOUT:
// CHECK:STDOUT: .loc16_63.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc16_63.13 = load ptr, ptr %.loc16_63.2.temp, align 8, !dbg !32
// CHECK:STDOUT:   call void @_CErr.Result.Core.f303d81b2fad85a0(ptr %.loc16_63.9.temp, ptr %.loc16_63.13), !dbg !32
// CHECK:STDOUT:   br label %.loc16_63.3, !dbg !32
// CHECK:STDOUT:
// CHECK:STDOUT: .loc16_63.3:                                      ; preds = %.loc16_63.2, %.loc16_63.1
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc16_64.1.temp), !dbg !32
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr %.loc16_64.1.temp, ptr %.loc16_63.9.temp), !dbg !32
// CHECK:STDOUT:   %.loc16_64.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc16_64.1.temp, i32 0, i32 0, !dbg !32
// CHECK:STDOUT:   %.loc16_64.6 = load i8, ptr %.loc16_64.5.discriminant, align 1, !dbg !32
// CHECK:STDOUT:   %.loc16_64.61 = trunc i8 %.loc16_64.6 to i1, !dbg !32
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc16_64.61, !dbg !32
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc16_64.1, label %.loc16_64.2, !dbg !32
// CHECK:STDOUT:
// CHECK:STDOUT: .loc16_64.1:                                      ; preds = %.loc16_63.3
// CHECK:STDOUT:   %.loc16_64.9.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc16_64.1.temp, i32 0, i32 1, !dbg !32
// CHECK:STDOUT:   %.loc16_64.10.Break = getelementptr inbounds nuw [8 x i8], ptr %.loc16_64.9.payload, i32 0, i32 0, !dbg !32
// CHECK:STDOUT:   %tuple.elem0.loc16_64.1.tuple.elem = getelementptr inbounds nuw { ptr }, ptr %.loc16_64.10.Break, i32 0, i32 0, !dbg !32
// CHECK:STDOUT:   %.loc16_64.11 = load ptr, ptr %tuple.elem0.loc16_64.1.tuple.elem, align 8, !dbg !32
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr %return, ptr %.loc16_64.11), !dbg !32
// CHECK:STDOUT:   call void @"_CSelfDestruct.bd1d6a14735f733b:core.Destroy.Core"(ptr %.loc16_64.1.temp), !dbg !32
// CHECK:STDOUT:   ret void, !dbg !32
// CHECK:STDOUT:
// CHECK:STDOUT: .loc16_64.2:                                      ; preds = %.loc16_63.3
// CHECK:STDOUT:   %.loc16_64.13.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc16_64.1.temp, i32 0, i32 1, !dbg !32
// CHECK:STDOUT:   %.loc16_64.14.Continue = getelementptr inbounds nuw [8 x i8], ptr %.loc16_64.13.payload, i32 0, i32 0, !dbg !32
// CHECK:STDOUT:   %tuple.elem0.loc16_64.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc16_64.14.Continue, i32 0, i32 0, !dbg !32
// CHECK:STDOUT:   %.loc16_64.15 = load i32, ptr %tuple.elem0.loc16_64.2.tuple.elem, align 4, !dbg !32
// CHECK:STDOUT:   call void @_COk.Result.Core.f303d81b2fad85a0(ptr %return, i32 %.loc16_64.15), !dbg !37
// CHECK:STDOUT:   call void @"_CSelfDestruct.bd1d6a14735f733b:core.Destroy.Core"(ptr %.loc16_64.1.temp), !dbg !32
// CHECK:STDOUT:   ret void, !dbg !38
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
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !248
// CHECK:STDOUT:   store ptr %error, ptr %error.addr, align 8, !tbaa !250
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !248
// CHECK:STDOUT:   %call = invoke noundef i32 @_Z13may_throw_intv()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   store i32 %call, ptr %0, align 4, !tbaa !251
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
// CHECK:STDOUT:   %5 = load ptr, ptr %error.addr, align 8, !tbaa !250
// CHECK:STDOUT:   store ptr %call1, ptr %5, align 8, !tbaa !252
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
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !47 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !49
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !49
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !51 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !53
// CHECK:STDOUT:   ret void, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5d7acf31c713fc45:core.Destroy.Core"(ptr %self) #0 !dbg !55 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b42e053a7828cd54:core.Destroy.Core"(ptr %self) #0 !dbg !59 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { ptr }, ptr %self, i32 0, i32 0, !dbg !61
// CHECK:STDOUT:   call void @"_CSelfDestruct.5d7acf31c713fc45:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !61
// CHECK:STDOUT:   ret void, !dbg !61
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b42e053a7828cd54:core.Destroy.Core"(ptr %self) #0 !dbg !63 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b42e053a7828cd54:core.Destroy.Core"(ptr %self), !dbg !65
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.33752dc59fc8e439:core.Destroy.Core"(ptr %self) #0 !dbg !67 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.33752dc59fc8e439:core.Destroy.Core"(ptr %self) #0 !dbg !71 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.33752dc59fc8e439:core.Destroy.Core"(ptr %self), !dbg !73
// CHECK:STDOUT:   ret void, !dbg !73
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b51a1f024d507b46:core.Destroy.Core"(ptr %self) #0 !dbg !75 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_64.1.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !77
// CHECK:STDOUT:   call void @"_CSelfDestruct.33752dc59fc8e439:core.Destroy.Core"(ptr %.loc16_64.1.payload), !dbg !77
// CHECK:STDOUT:   %.loc16_64.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !77
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc16_64.2.discriminant), !dbg !77
// CHECK:STDOUT:   ret void, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b51a1f024d507b46:core.Destroy.Core"(ptr %self) #0 !dbg !79 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b51a1f024d507b46:core.Destroy.Core"(ptr %self), !dbg !81
// CHECK:STDOUT:   ret void, !dbg !81
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.bd1d6a14735f733b:core.Destroy.Core"(ptr %self) #0 !dbg !83 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !85
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.bd1d6a14735f733b:core.Destroy.Core"(ptr %self) #0 !dbg !87 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.bd1d6a14735f733b:core.Destroy.Core"(ptr %self), !dbg !89
// CHECK:STDOUT:   ret void, !dbg !89
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CG.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return) #0 !dbg !91 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc20_17.1.temp = alloca ptr, align 8, !dbg !94
// CHECK:STDOUT:   %.loc20_17.8.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !94
// CHECK:STDOUT:   %.loc20_18.1.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !94
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc20_17.1.temp), !dbg !94
// CHECK:STDOUT:   %may_throw__carbon_catching_thunk.call = call i32 @_Z9may_throwv.carbon_thunk_catch.(ptr %.loc20_17.1.temp), !dbg !94
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call = icmp eq i32 %may_throw__carbon_catching_thunk.call, 0, !dbg !94
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc20_17.8.temp), !dbg !94
// CHECK:STDOUT:   br i1 %Int.as.EqWith.impl.Equal.call, label %.loc20_17.1, label %.loc20_17.2, !dbg !94
// CHECK:STDOUT:
// CHECK:STDOUT: .loc20_17.1:                                      ; preds = %entry
// CHECK:STDOUT:   call void @_COk.Result.Core.ee51b1618614817f(ptr %.loc20_17.8.temp), !dbg !94
// CHECK:STDOUT:   br label %.loc20_17.3, !dbg !94
// CHECK:STDOUT:
// CHECK:STDOUT: .loc20_17.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc20_17.11 = load ptr, ptr %.loc20_17.1.temp, align 8, !dbg !94
// CHECK:STDOUT:   call void @_CErr.Result.Core.ee51b1618614817f(ptr %.loc20_17.8.temp, ptr %.loc20_17.11), !dbg !94
// CHECK:STDOUT:   br label %.loc20_17.3, !dbg !94
// CHECK:STDOUT:
// CHECK:STDOUT: .loc20_17.3:                                      ; preds = %.loc20_17.2, %.loc20_17.1
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc20_18.1.temp), !dbg !94
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.ee51b1618614817f"(ptr %.loc20_18.1.temp, ptr %.loc20_17.8.temp), !dbg !94
// CHECK:STDOUT:   %.loc20_18.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc20_18.1.temp, i32 0, i32 0, !dbg !94
// CHECK:STDOUT:   %.loc20_18.6 = load i8, ptr %.loc20_18.5.discriminant, align 1, !dbg !94
// CHECK:STDOUT:   %.loc20_18.61 = trunc i8 %.loc20_18.6 to i1, !dbg !94
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc20_18.61, !dbg !94
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc20_18.1, label %.loc20_18.2, !dbg !94
// CHECK:STDOUT:
// CHECK:STDOUT: .loc20_18.1:                                      ; preds = %.loc20_17.3
// CHECK:STDOUT:   %.loc20_18.9.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc20_18.1.temp, i32 0, i32 1, !dbg !94
// CHECK:STDOUT:   %.loc20_18.10.Break = getelementptr inbounds nuw [8 x i8], ptr %.loc20_18.9.payload, i32 0, i32 0, !dbg !94
// CHECK:STDOUT:   %tuple.elem0.loc20_18.1.tuple.elem = getelementptr inbounds nuw { ptr }, ptr %.loc20_18.10.Break, i32 0, i32 0, !dbg !94
// CHECK:STDOUT:   %.loc20_18.11 = load ptr, ptr %tuple.elem0.loc20_18.1.tuple.elem, align 8, !dbg !94
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.ee51b1618614817f"(ptr %return, ptr %.loc20_18.11), !dbg !94
// CHECK:STDOUT:   call void @"_CSelfDestruct.ba856e85e894bb1c:core.Destroy.Core"(ptr %.loc20_18.1.temp), !dbg !94
// CHECK:STDOUT:   ret void, !dbg !94
// CHECK:STDOUT:
// CHECK:STDOUT: .loc20_18.2:                                      ; preds = %.loc20_17.3
// CHECK:STDOUT:   %.loc20_18.13.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc20_18.1.temp, i32 0, i32 1, !dbg !94
// CHECK:STDOUT:   %.loc20_18.14.Continue = getelementptr inbounds nuw [8 x i8], ptr %.loc20_18.13.payload, i32 0, i32 0, !dbg !94
// CHECK:STDOUT:   %tuple.elem0.loc20_18.2.tuple.elem = getelementptr inbounds nuw { {} }, ptr %.loc20_18.14.Continue, i32 0, i32 0, !dbg !94
// CHECK:STDOUT:   call void @"_CSelfDestruct.ba856e85e894bb1c:core.Destroy.Core"(ptr %.loc20_18.1.temp), !dbg !94
// CHECK:STDOUT:   call void @_COk.Result.Core.ee51b1618614817f(ptr %return), !dbg !95
// CHECK:STDOUT:   ret void, !dbg !96
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
// CHECK:STDOUT:   store ptr %error, ptr %error.addr, align 8, !tbaa !250
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
// CHECK:STDOUT:   %4 = load ptr, ptr %error.addr, align 8, !tbaa !250
// CHECK:STDOUT:   store ptr %call, ptr %4, align 8, !tbaa !252
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
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.61ea2aba74ab3bf1:core.Destroy.Core"(ptr %self) #0 !dbg !97 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !99
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.9fb0584d149a4ffd:core.Destroy.Core"(ptr %self) #0 !dbg !101 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { {} }, ptr %self, i32 0, i32 0, !dbg !103
// CHECK:STDOUT:   call void @"_CSelfDestruct.61ea2aba74ab3bf1:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !103
// CHECK:STDOUT:   ret void, !dbg !103
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.9fb0584d149a4ffd:core.Destroy.Core"(ptr %self) #0 !dbg !105 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.9fb0584d149a4ffd:core.Destroy.Core"(ptr %self), !dbg !107
// CHECK:STDOUT:   ret void, !dbg !107
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.53b43632e8dfcd8c:core.Destroy.Core"(ptr %self) #0 !dbg !109 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !111
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.53b43632e8dfcd8c:core.Destroy.Core"(ptr %self) #0 !dbg !113 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.53b43632e8dfcd8c:core.Destroy.Core"(ptr %self), !dbg !115
// CHECK:STDOUT:   ret void, !dbg !115
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.50e45086fdc9f0ef:core.Destroy.Core"(ptr %self) #0 !dbg !117 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc20_18.1.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !119
// CHECK:STDOUT:   call void @"_CSelfDestruct.53b43632e8dfcd8c:core.Destroy.Core"(ptr %.loc20_18.1.payload), !dbg !119
// CHECK:STDOUT:   %.loc20_18.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !119
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc20_18.2.discriminant), !dbg !119
// CHECK:STDOUT:   ret void, !dbg !119
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.50e45086fdc9f0ef:core.Destroy.Core"(ptr %self) #0 !dbg !121 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.50e45086fdc9f0ef:core.Destroy.Core"(ptr %self), !dbg !123
// CHECK:STDOUT:   ret void, !dbg !123
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.ba856e85e894bb1c:core.Destroy.Core"(ptr %self) #0 !dbg !125 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !127
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.ba856e85e894bb1c:core.Destroy.Core"(ptr %self) #0 !dbg !129 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.ba856e85e894bb1c:core.Destroy.Core"(ptr %self), !dbg !131
// CHECK:STDOUT:   ret void, !dbg !131
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CM.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %c, ptr %p) #0 !dbg !133 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.var = alloca i32, align 4, !dbg !140
// CHECK:STDOUT:   %.loc25_22.1.temp = alloca i32, align 4, !dbg !141
// CHECK:STDOUT:   %.loc25_22.2.temp = alloca ptr, align 8, !dbg !141
// CHECK:STDOUT:   %.loc25_22.9.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !141
// CHECK:STDOUT:   %.loc25_23.1.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !141
// CHECK:STDOUT:   %b.var = alloca i32, align 4, !dbg !143
// CHECK:STDOUT:   %.loc26_26.1.temp = alloca i32, align 4, !dbg !144
// CHECK:STDOUT:   %.loc26_26.2.temp = alloca ptr, align 8, !dbg !144
// CHECK:STDOUT:   %.loc26_26.9.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !144
// CHECK:STDOUT:   %.loc26_27.1.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !144
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a.var), !dbg !140
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc25_22.1.temp), !dbg !141
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc25_22.2.temp), !dbg !141
// CHECK:STDOUT:   %get__carbon_catching_thunk.call = call i32 @_ZNK1C3getEv.carbon_thunk_catch._(ptr %c, ptr %.loc25_22.1.temp, ptr %.loc25_22.2.temp), !dbg !141
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call.loc25 = icmp eq i32 %get__carbon_catching_thunk.call, 0, !dbg !141
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc25_22.9.temp), !dbg !141
// CHECK:STDOUT:   br i1 %Int.as.EqWith.impl.Equal.call.loc25, label %.loc25_22.1, label %.loc25_22.2, !dbg !141
// CHECK:STDOUT:
// CHECK:STDOUT: .loc25_22.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc25_22.10 = load i32, ptr %.loc25_22.1.temp, align 4, !dbg !141
// CHECK:STDOUT:   call void @_COk.Result.Core.f303d81b2fad85a0(ptr %.loc25_22.9.temp, i32 %.loc25_22.10), !dbg !141
// CHECK:STDOUT:   br label %.loc25_22.3, !dbg !141
// CHECK:STDOUT:
// CHECK:STDOUT: .loc25_22.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc25_22.13 = load ptr, ptr %.loc25_22.2.temp, align 8, !dbg !141
// CHECK:STDOUT:   call void @_CErr.Result.Core.f303d81b2fad85a0(ptr %.loc25_22.9.temp, ptr %.loc25_22.13), !dbg !141
// CHECK:STDOUT:   br label %.loc25_22.3, !dbg !141
// CHECK:STDOUT:
// CHECK:STDOUT: .loc25_22.3:                                      ; preds = %.loc25_22.2, %.loc25_22.1
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc25_23.1.temp), !dbg !141
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr %.loc25_23.1.temp, ptr %.loc25_22.9.temp), !dbg !141
// CHECK:STDOUT:   %.loc25_23.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc25_23.1.temp, i32 0, i32 0, !dbg !141
// CHECK:STDOUT:   %.loc25_23.6 = load i8, ptr %.loc25_23.5.discriminant, align 1, !dbg !141
// CHECK:STDOUT:   %.loc25_23.61 = trunc i8 %.loc25_23.6 to i1, !dbg !141
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc25 = icmp eq i1 true, %.loc25_23.61, !dbg !141
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc25, label %.loc25_23.1, label %.loc25_23.2, !dbg !141
// CHECK:STDOUT:
// CHECK:STDOUT: .loc25_23.1:                                      ; preds = %.loc25_22.3
// CHECK:STDOUT:   %.loc25_23.9.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc25_23.1.temp, i32 0, i32 1, !dbg !141
// CHECK:STDOUT:   %.loc25_23.10.Break = getelementptr inbounds nuw [8 x i8], ptr %.loc25_23.9.payload, i32 0, i32 0, !dbg !141
// CHECK:STDOUT:   %tuple.elem0.loc25_23.1.tuple.elem = getelementptr inbounds nuw { ptr }, ptr %.loc25_23.10.Break, i32 0, i32 0, !dbg !141
// CHECK:STDOUT:   %.loc25_23.11 = load ptr, ptr %tuple.elem0.loc25_23.1.tuple.elem, align 8, !dbg !141
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr %return, ptr %.loc25_23.11), !dbg !141
// CHECK:STDOUT:   call void @"_CSelfDestruct.bd1d6a14735f733b:core.Destroy.Core"(ptr %.loc25_23.1.temp), !dbg !141
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %a.var), !dbg !140
// CHECK:STDOUT:   ret void, !dbg !141
// CHECK:STDOUT:
// CHECK:STDOUT: .loc25_23.2:                                      ; preds = %.loc25_22.3
// CHECK:STDOUT:   %.loc25_23.13.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc25_23.1.temp, i32 0, i32 1, !dbg !141
// CHECK:STDOUT:   %.loc25_23.14.Continue = getelementptr inbounds nuw [8 x i8], ptr %.loc25_23.13.payload, i32 0, i32 0, !dbg !141
// CHECK:STDOUT:   %tuple.elem0.loc25_23.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc25_23.14.Continue, i32 0, i32 0, !dbg !141
// CHECK:STDOUT:   %.loc25_23.15 = load i32, ptr %tuple.elem0.loc25_23.2.tuple.elem, align 4, !dbg !141
// CHECK:STDOUT:   store i32 %.loc25_23.15, ptr %a.var, align 4, !dbg !140
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !143
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc26_26.1.temp), !dbg !144
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc26_26.2.temp), !dbg !144
// CHECK:STDOUT:   %mutate__carbon_catching_thunk.call = call i32 @_ZN1C6mutateEv.carbon_thunk_catch.r(ptr %p, ptr %.loc26_26.1.temp, ptr %.loc26_26.2.temp), !dbg !144
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call.loc26 = icmp eq i32 %mutate__carbon_catching_thunk.call, 0, !dbg !144
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc26_26.9.temp), !dbg !144
// CHECK:STDOUT:   br i1 %Int.as.EqWith.impl.Equal.call.loc26, label %.loc26_26.1, label %.loc26_26.2, !dbg !144
// CHECK:STDOUT:
// CHECK:STDOUT: .loc26_26.1:                                      ; preds = %.loc25_23.2
// CHECK:STDOUT:   %.loc26_26.10 = load i32, ptr %.loc26_26.1.temp, align 4, !dbg !144
// CHECK:STDOUT:   call void @_COk.Result.Core.f303d81b2fad85a0(ptr %.loc26_26.9.temp, i32 %.loc26_26.10), !dbg !144
// CHECK:STDOUT:   br label %.loc26_26.3, !dbg !144
// CHECK:STDOUT:
// CHECK:STDOUT: .loc26_26.2:                                      ; preds = %.loc25_23.2
// CHECK:STDOUT:   %.loc26_26.13 = load ptr, ptr %.loc26_26.2.temp, align 8, !dbg !144
// CHECK:STDOUT:   call void @_CErr.Result.Core.f303d81b2fad85a0(ptr %.loc26_26.9.temp, ptr %.loc26_26.13), !dbg !144
// CHECK:STDOUT:   br label %.loc26_26.3, !dbg !144
// CHECK:STDOUT:
// CHECK:STDOUT: .loc26_26.3:                                      ; preds = %.loc26_26.2, %.loc26_26.1
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc26_27.1.temp), !dbg !144
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr %.loc26_27.1.temp, ptr %.loc26_26.9.temp), !dbg !144
// CHECK:STDOUT:   %.loc26_27.5.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc26_27.1.temp, i32 0, i32 0, !dbg !144
// CHECK:STDOUT:   %.loc26_27.6 = load i8, ptr %.loc26_27.5.discriminant, align 1, !dbg !144
// CHECK:STDOUT:   %.loc26_27.62 = trunc i8 %.loc26_27.6 to i1, !dbg !144
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc26 = icmp eq i1 true, %.loc26_27.62, !dbg !144
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc26, label %.loc26_27.1, label %.loc26_27.2, !dbg !144
// CHECK:STDOUT:
// CHECK:STDOUT: .loc26_27.1:                                      ; preds = %.loc26_26.3
// CHECK:STDOUT:   %.loc26_27.9.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc26_27.1.temp, i32 0, i32 1, !dbg !144
// CHECK:STDOUT:   %.loc26_27.10.Break = getelementptr inbounds nuw [8 x i8], ptr %.loc26_27.9.payload, i32 0, i32 0, !dbg !144
// CHECK:STDOUT:   %tuple.elem0.loc26_27.1.tuple.elem = getelementptr inbounds nuw { ptr }, ptr %.loc26_27.10.Break, i32 0, i32 0, !dbg !144
// CHECK:STDOUT:   %.loc26_27.11 = load ptr, ptr %tuple.elem0.loc26_27.1.tuple.elem, align 8, !dbg !144
// CHECK:STDOUT:   call void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr %return, ptr %.loc26_27.11), !dbg !144
// CHECK:STDOUT:   call void @"_CSelfDestruct.bd1d6a14735f733b:core.Destroy.Core"(ptr %.loc26_27.1.temp), !dbg !144
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %b.var), !dbg !143
// CHECK:STDOUT:   call void @"_CSelfDestruct.bd1d6a14735f733b:core.Destroy.Core"(ptr %.loc25_23.1.temp), !dbg !141
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %a.var), !dbg !140
// CHECK:STDOUT:   ret void, !dbg !144
// CHECK:STDOUT:
// CHECK:STDOUT: .loc26_27.2:                                      ; preds = %.loc26_26.3
// CHECK:STDOUT:   %.loc26_27.13.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc26_27.1.temp, i32 0, i32 1, !dbg !144
// CHECK:STDOUT:   %.loc26_27.14.Continue = getelementptr inbounds nuw [8 x i8], ptr %.loc26_27.13.payload, i32 0, i32 0, !dbg !144
// CHECK:STDOUT:   %tuple.elem0.loc26_27.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc26_27.14.Continue, i32 0, i32 0, !dbg !144
// CHECK:STDOUT:   %.loc26_27.15 = load i32, ptr %tuple.elem0.loc26_27.2.tuple.elem, align 4, !dbg !144
// CHECK:STDOUT:   store i32 %.loc26_27.15, ptr %b.var, align 4, !dbg !143
// CHECK:STDOUT:   %.loc27_45 = load i32, ptr %a.var, align 4, !dbg !146
// CHECK:STDOUT:   %.loc27_49 = load i32, ptr %b.var, align 4, !dbg !147
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc27_45, %.loc27_49, !dbg !146
// CHECK:STDOUT:   call void @_COk.Result.Core.f303d81b2fad85a0(ptr %return, i32 %Int.as.AddWith.impl.Op.call), !dbg !148
// CHECK:STDOUT:   call void @"_CSelfDestruct.bd1d6a14735f733b:core.Destroy.Core"(ptr %.loc26_27.1.temp), !dbg !144
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %b.var), !dbg !143
// CHECK:STDOUT:   call void @"_CSelfDestruct.bd1d6a14735f733b:core.Destroy.Core"(ptr %.loc25_23.1.temp), !dbg !141
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %a.var), !dbg !140
// CHECK:STDOUT:   ret void, !dbg !149
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_ZNK1C3getEv.carbon_thunk._(ptr noundef nonnull align 1 dereferenceable(1) %this) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !254
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !254, !nonnull !256
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
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !254
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !248
// CHECK:STDOUT:   store ptr %error, ptr %error.addr, align 8, !tbaa !250
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !248
// CHECK:STDOUT:   %1 = load ptr, ptr %this.addr, align 8, !tbaa !254, !nonnull !256
// CHECK:STDOUT:   %call = invoke noundef i32 @_ZNK1C3getEv(ptr noundef nonnull align 1 dereferenceable(1) %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   store i32 %call, ptr %0, align 4, !tbaa !251
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
// CHECK:STDOUT:   %6 = load ptr, ptr %error.addr, align 8, !tbaa !250
// CHECK:STDOUT:   store ptr %call1, ptr %6, align 8, !tbaa !252
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
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !254
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !254, !nonnull !256
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
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !254
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !248
// CHECK:STDOUT:   store ptr %error, ptr %error.addr, align 8, !tbaa !250
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !248
// CHECK:STDOUT:   %1 = load ptr, ptr %this.addr, align 8, !tbaa !254, !nonnull !256
// CHECK:STDOUT:   %call = invoke noundef i32 @_ZN1C6mutateEv(ptr noundef nonnull align 1 dereferenceable(1) %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   store i32 %call, ptr %0, align 4, !tbaa !251
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
// CHECK:STDOUT:   %6 = load ptr, ptr %error.addr, align 8, !tbaa !250
// CHECK:STDOUT:   store ptr %call1, ptr %6, align 8, !tbaa !252
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
// CHECK:STDOUT: define linkonce_odr void @_COk.Result.Core.f303d81b2fad85a0(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !152 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !154
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !154
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !154
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !155
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @Result.val.e39.anon, i64 16, i1 false), !dbg !154
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Ok, align 4, !dbg !154
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Ok, i32 0, i32 0, !dbg !155
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !155
// CHECK:STDOUT:   ret void, !dbg !154
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.Result.Core.f303d81b2fad85a0(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %_) #0 !dbg !157 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !159
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !159
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !159
// CHECK:STDOUT:   %tuple.init = insertvalue { ptr } poison, ptr %_, 0, !dbg !159
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @Result.val.207.anon, i64 16, i1 false), !dbg !159
// CHECK:STDOUT:   store { ptr } %tuple.init, ptr %Err, align 8, !dbg !159
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { ptr }, ptr %Err, i32 0, i32 0, !dbg !159
// CHECK:STDOUT:   store ptr %_, ptr %tuple.elem, align 8, !dbg !159
// CHECK:STDOUT:   ret void, !dbg !159
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %self) #0 !dbg !161 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !167
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !167
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !167
// CHECK:STDOUT:   %3 = icmp eq i1 false, %2, !dbg !167
// CHECK:STDOUT:   br i1 %3, label %4, label %6, !dbg !167
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !167
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !167
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Ok, i32 0, i32 0, !dbg !167
// CHECK:STDOUT:   %5 = load i32, ptr %tuple.elem, align 4, !dbg !167
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.f303d81b2fad85a0(ptr %return, i32 %5), !dbg !170
// CHECK:STDOUT:   ret void, !dbg !171
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %0
// CHECK:STDOUT:   %discriminant1 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !172
// CHECK:STDOUT:   %7 = load i8, ptr %discriminant1, align 1, !dbg !172
// CHECK:STDOUT:   %8 = trunc i8 %7 to i1, !dbg !172
// CHECK:STDOUT:   %9 = icmp eq i1 true, %8, !dbg !172
// CHECK:STDOUT:   br i1 %9, label %10, label %12, !dbg !172
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %6
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !172
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [8 x i8], ptr %payload2, i32 0, i32 0, !dbg !172
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { ptr }, ptr %Err, i32 0, i32 0, !dbg !172
// CHECK:STDOUT:   %11 = load ptr, ptr %tuple.elem3, align 8, !dbg !172
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.f303d81b2fad85a0(ptr %return, ptr %11), !dbg !175
// CHECK:STDOUT:   ret void, !dbg !176
// CHECK:STDOUT:
// CHECK:STDOUT: 12:                                               ; preds = %6
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr %return, ptr %self), !dbg !178
// CHECK:STDOUT:   ret void, !dbg !179
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %b) #0 !dbg !181 {
// CHECK:STDOUT:   call void @_CErr.Result.Core.f303d81b2fad85a0(ptr %return, ptr %b), !dbg !187
// CHECK:STDOUT:   ret void, !dbg !188
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.Result.Core.ee51b1618614817f(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return) #0 !dbg !190 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !191
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !191
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !191
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @Result.val.aa3.anon, i64 16, i1 false), !dbg !191
// CHECK:STDOUT:   store { {} } poison, ptr %Ok, align 1, !dbg !191
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Ok, i32 0, i32 0, !dbg !192
// CHECK:STDOUT:   ret void, !dbg !191
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.Result.Core.ee51b1618614817f(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %_) #0 !dbg !193 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !195
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !195
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !195
// CHECK:STDOUT:   %tuple.init = insertvalue { ptr } poison, ptr %_, 0, !dbg !195
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @Result.val.404.anon, i64 16, i1 false), !dbg !195
// CHECK:STDOUT:   store { ptr } %tuple.init, ptr %Err, align 8, !dbg !195
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { ptr }, ptr %Err, i32 0, i32 0, !dbg !195
// CHECK:STDOUT:   store ptr %_, ptr %tuple.elem, align 8, !dbg !195
// CHECK:STDOUT:   ret void, !dbg !195
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.ee51b1618614817f"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %self) #0 !dbg !197 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !203
// CHECK:STDOUT:   %1 = load i8, ptr %discriminant, align 1, !dbg !203
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !203
// CHECK:STDOUT:   %3 = icmp eq i1 false, %2, !dbg !203
// CHECK:STDOUT:   br i1 %3, label %4, label %5, !dbg !203
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !203
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !203
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Ok, i32 0, i32 0, !dbg !203
// CHECK:STDOUT:   call void @_CContinue.ControlFlow.Core.ee51b1618614817f(ptr %return), !dbg !206
// CHECK:STDOUT:   ret void, !dbg !207
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %0
// CHECK:STDOUT:   %discriminant1 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !208
// CHECK:STDOUT:   %6 = load i8, ptr %discriminant1, align 1, !dbg !208
// CHECK:STDOUT:   %7 = trunc i8 %6 to i1, !dbg !208
// CHECK:STDOUT:   %8 = icmp eq i1 true, %7, !dbg !208
// CHECK:STDOUT:   br i1 %8, label %9, label %11, !dbg !208
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %5
// CHECK:STDOUT:   %payload2 = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !208
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [8 x i8], ptr %payload2, i32 0, i32 0, !dbg !208
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { ptr }, ptr %Err, i32 0, i32 0, !dbg !208
// CHECK:STDOUT:   %10 = load ptr, ptr %tuple.elem3, align 8, !dbg !208
// CHECK:STDOUT:   call void @_CBreak.ControlFlow.Core.ee51b1618614817f(ptr %return, ptr %10), !dbg !211
// CHECK:STDOUT:   ret void, !dbg !212
// CHECK:STDOUT:
// CHECK:STDOUT: 11:                                               ; preds = %5
// CHECK:STDOUT:   call void @"_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.ee51b1618614817f"(ptr %return, ptr %self), !dbg !214
// CHECK:STDOUT:   ret void, !dbg !215
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.ee51b1618614817f"(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %b) #0 !dbg !217 {
// CHECK:STDOUT:   call void @_CErr.Result.Core.ee51b1618614817f(ptr %return, ptr %b), !dbg !223
// CHECK:STDOUT:   ret void, !dbg !224
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.f303d81b2fad85a0(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !227 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !229
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !229
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !229
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !230
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.908.anon, i64 16, i1 false), !dbg !229
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Continue, align 4, !dbg !229
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Continue, i32 0, i32 0, !dbg !230
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !230
// CHECK:STDOUT:   ret void, !dbg !229
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.f303d81b2fad85a0(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %_) #0 !dbg !232 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !234
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !234
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !234
// CHECK:STDOUT:   %tuple.init = insertvalue { ptr } poison, ptr %_, 0, !dbg !234
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.401.anon, i64 16, i1 false), !dbg !234
// CHECK:STDOUT:   store { ptr } %tuple.init, ptr %Break, align 8, !dbg !234
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { ptr }, ptr %Break, i32 0, i32 0, !dbg !234
// CHECK:STDOUT:   store ptr %_, ptr %tuple.elem, align 8, !dbg !234
// CHECK:STDOUT:   ret void, !dbg !234
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CContinue.ControlFlow.Core.ee51b1618614817f(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return) #0 !dbg !236 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !237
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !237
// CHECK:STDOUT:   %Continue = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !237
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.e34.anon, i64 16, i1 false), !dbg !237
// CHECK:STDOUT:   store { {} } poison, ptr %Continue, align 1, !dbg !237
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { {} }, ptr %Continue, i32 0, i32 0, !dbg !238
// CHECK:STDOUT:   ret void, !dbg !237
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBreak.ControlFlow.Core.ee51b1618614817f(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, ptr %_) #0 !dbg !239 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !241
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !241
// CHECK:STDOUT:   %Break = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !241
// CHECK:STDOUT:   %tuple.init = insertvalue { ptr } poison, ptr %_, 0, !dbg !241
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @ControlFlow.val.98f.anon, i64 16, i1 false), !dbg !241
// CHECK:STDOUT:   store { ptr } %tuple.init, ptr %Break, align 8, !dbg !241
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { ptr }, ptr %Break, i32 0, i32 0, !dbg !241
// CHECK:STDOUT:   store ptr %_, ptr %tuple.elem, align 8, !dbg !241
// CHECK:STDOUT:   ret void, !dbg !241
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
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.bd1d6a14735f733b:core.Destroy.Core", { 0, 1, 2, 3, 4, 6, 5 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.ba856e85e894bb1c:core.Destroy.Core", { 1, 0 }
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!257, !258, !259, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!261}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "catching_thunk.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!8}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !15 = !{null, !7}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = !{null, !6}
// CHECK:STDOUT: !18 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !19 = !{null, !8}
// CHECK:STDOUT: !20 = !DISubroutineType(types: !19)
// CHECK:STDOUT: !25 = !{!8, !8, !8}
// CHECK:STDOUT: !26 = !DISubroutineType(types: !25)
// CHECK:STDOUT: !29 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !4, line: 15, type: !10, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !32 = !DILocation(line: 16, column: 45, scope: !29)
// CHECK:STDOUT: !33 = !{!8, !6}
// CHECK:STDOUT: !34 = !DISubroutineType(types: !33)
// CHECK:STDOUT: !35 = !{!8, !8}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !37 = !DILocation(line: 16, column: 10, scope: !29)
// CHECK:STDOUT: !38 = !DILocation(line: 16, column: 3, scope: !29)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !4, line: 16, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !42)
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !39, type: !7)
// CHECK:STDOUT: !41 = !DILocation(line: 16, column: 45, scope: !39)
// CHECK:STDOUT: !42 = !{!40}
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 16, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !46)
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !43, type: !6)
// CHECK:STDOUT: !45 = !DILocation(line: 16, column: 45, scope: !43)
// CHECK:STDOUT: !46 = !{!44}
// CHECK:STDOUT: !47 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 16, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !50)
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !47, type: !8)
// CHECK:STDOUT: !49 = !DILocation(line: 16, column: 45, scope: !47)
// CHECK:STDOUT: !50 = !{!48}
// CHECK:STDOUT: !51 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 16, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !54)
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !51, type: !8)
// CHECK:STDOUT: !53 = !DILocation(line: 16, column: 45, scope: !51)
// CHECK:STDOUT: !54 = !{!52}
// CHECK:STDOUT: !55 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5d7acf31c713fc45:core.Destroy.Core", scope: null, file: !4, line: 16, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !58)
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !55, type: !8)
// CHECK:STDOUT: !57 = !DILocation(line: 16, column: 45, scope: !55)
// CHECK:STDOUT: !58 = !{!56}
// CHECK:STDOUT: !59 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b42e053a7828cd54:core.Destroy.Core", scope: null, file: !4, line: 16, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !62)
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !59, type: !8)
// CHECK:STDOUT: !61 = !DILocation(line: 16, column: 45, scope: !59)
// CHECK:STDOUT: !62 = !{!60}
// CHECK:STDOUT: !63 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b42e053a7828cd54:core.Destroy.Core", scope: null, file: !4, line: 16, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !66)
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !63, type: !8)
// CHECK:STDOUT: !65 = !DILocation(line: 16, column: 45, scope: !63)
// CHECK:STDOUT: !66 = !{!64}
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.33752dc59fc8e439:core.Destroy.Core", scope: null, file: !4, line: 16, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !70)
// CHECK:STDOUT: !68 = !DILocalVariable(arg: 1, scope: !67, type: !8)
// CHECK:STDOUT: !69 = !DILocation(line: 16, column: 45, scope: !67)
// CHECK:STDOUT: !70 = !{!68}
// CHECK:STDOUT: !71 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.33752dc59fc8e439:core.Destroy.Core", scope: null, file: !4, line: 16, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !74)
// CHECK:STDOUT: !72 = !DILocalVariable(arg: 1, scope: !71, type: !8)
// CHECK:STDOUT: !73 = !DILocation(line: 16, column: 45, scope: !71)
// CHECK:STDOUT: !74 = !{!72}
// CHECK:STDOUT: !75 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b51a1f024d507b46:core.Destroy.Core", scope: null, file: !4, line: 16, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !78)
// CHECK:STDOUT: !76 = !DILocalVariable(arg: 1, scope: !75, type: !8)
// CHECK:STDOUT: !77 = !DILocation(line: 16, column: 45, scope: !75)
// CHECK:STDOUT: !78 = !{!76}
// CHECK:STDOUT: !79 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b51a1f024d507b46:core.Destroy.Core", scope: null, file: !4, line: 16, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !82)
// CHECK:STDOUT: !80 = !DILocalVariable(arg: 1, scope: !79, type: !8)
// CHECK:STDOUT: !81 = !DILocation(line: 16, column: 45, scope: !79)
// CHECK:STDOUT: !82 = !{!80}
// CHECK:STDOUT: !83 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.bd1d6a14735f733b:core.Destroy.Core", scope: null, file: !4, line: 16, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !86)
// CHECK:STDOUT: !84 = !DILocalVariable(arg: 1, scope: !83, type: !8)
// CHECK:STDOUT: !85 = !DILocation(line: 16, column: 45, scope: !83)
// CHECK:STDOUT: !86 = !{!84}
// CHECK:STDOUT: !87 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.bd1d6a14735f733b:core.Destroy.Core", scope: null, file: !4, line: 16, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !90)
// CHECK:STDOUT: !88 = !DILocalVariable(arg: 1, scope: !87, type: !8)
// CHECK:STDOUT: !89 = !DILocation(line: 16, column: 45, scope: !87)
// CHECK:STDOUT: !90 = !{!88}
// CHECK:STDOUT: !91 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main", scope: null, file: !4, line: 19, type: !10, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !94 = !DILocation(line: 20, column: 3, scope: !91)
// CHECK:STDOUT: !95 = !DILocation(line: 21, column: 10, scope: !91)
// CHECK:STDOUT: !96 = !DILocation(line: 21, column: 3, scope: !91)
// CHECK:STDOUT: !97 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.61ea2aba74ab3bf1:core.Destroy.Core", scope: null, file: !4, line: 20, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !100)
// CHECK:STDOUT: !98 = !DILocalVariable(arg: 1, scope: !97, type: !8)
// CHECK:STDOUT: !99 = !DILocation(line: 20, column: 3, scope: !97)
// CHECK:STDOUT: !100 = !{!98}
// CHECK:STDOUT: !101 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.9fb0584d149a4ffd:core.Destroy.Core", scope: null, file: !4, line: 20, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !104)
// CHECK:STDOUT: !102 = !DILocalVariable(arg: 1, scope: !101, type: !8)
// CHECK:STDOUT: !103 = !DILocation(line: 20, column: 3, scope: !101)
// CHECK:STDOUT: !104 = !{!102}
// CHECK:STDOUT: !105 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.9fb0584d149a4ffd:core.Destroy.Core", scope: null, file: !4, line: 20, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !108)
// CHECK:STDOUT: !106 = !DILocalVariable(arg: 1, scope: !105, type: !8)
// CHECK:STDOUT: !107 = !DILocation(line: 20, column: 3, scope: !105)
// CHECK:STDOUT: !108 = !{!106}
// CHECK:STDOUT: !109 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.53b43632e8dfcd8c:core.Destroy.Core", scope: null, file: !4, line: 20, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !112)
// CHECK:STDOUT: !110 = !DILocalVariable(arg: 1, scope: !109, type: !8)
// CHECK:STDOUT: !111 = !DILocation(line: 20, column: 3, scope: !109)
// CHECK:STDOUT: !112 = !{!110}
// CHECK:STDOUT: !113 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.53b43632e8dfcd8c:core.Destroy.Core", scope: null, file: !4, line: 20, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !116)
// CHECK:STDOUT: !114 = !DILocalVariable(arg: 1, scope: !113, type: !8)
// CHECK:STDOUT: !115 = !DILocation(line: 20, column: 3, scope: !113)
// CHECK:STDOUT: !116 = !{!114}
// CHECK:STDOUT: !117 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.50e45086fdc9f0ef:core.Destroy.Core", scope: null, file: !4, line: 20, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !120)
// CHECK:STDOUT: !118 = !DILocalVariable(arg: 1, scope: !117, type: !8)
// CHECK:STDOUT: !119 = !DILocation(line: 20, column: 3, scope: !117)
// CHECK:STDOUT: !120 = !{!118}
// CHECK:STDOUT: !121 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.50e45086fdc9f0ef:core.Destroy.Core", scope: null, file: !4, line: 20, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !124)
// CHECK:STDOUT: !122 = !DILocalVariable(arg: 1, scope: !121, type: !8)
// CHECK:STDOUT: !123 = !DILocation(line: 20, column: 3, scope: !121)
// CHECK:STDOUT: !124 = !{!122}
// CHECK:STDOUT: !125 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.ba856e85e894bb1c:core.Destroy.Core", scope: null, file: !4, line: 20, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !128)
// CHECK:STDOUT: !126 = !DILocalVariable(arg: 1, scope: !125, type: !8)
// CHECK:STDOUT: !127 = !DILocation(line: 20, column: 3, scope: !125)
// CHECK:STDOUT: !128 = !{!126}
// CHECK:STDOUT: !129 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.ba856e85e894bb1c:core.Destroy.Core", scope: null, file: !4, line: 20, type: !20, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !132)
// CHECK:STDOUT: !130 = !DILocalVariable(arg: 1, scope: !129, type: !8)
// CHECK:STDOUT: !131 = !DILocation(line: 20, column: 3, scope: !129)
// CHECK:STDOUT: !132 = !{!130}
// CHECK:STDOUT: !133 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main", scope: null, file: !4, line: 24, type: !26, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !150)
// CHECK:STDOUT: !134 = !DILocalVariable(arg: 1, scope: !133, type: !8)
// CHECK:STDOUT: !135 = !DILocalVariable(arg: 2, scope: !133, type: !8)
// CHECK:STDOUT: !140 = !DILocation(line: 25, column: 3, scope: !133)
// CHECK:STDOUT: !141 = !DILocation(line: 25, column: 16, scope: !133)
// CHECK:STDOUT: !143 = !DILocation(line: 26, column: 3, scope: !133)
// CHECK:STDOUT: !144 = !DILocation(line: 26, column: 16, scope: !133)
// CHECK:STDOUT: !146 = !DILocation(line: 27, column: 45, scope: !133)
// CHECK:STDOUT: !147 = !DILocation(line: 27, column: 49, scope: !133)
// CHECK:STDOUT: !148 = !DILocation(line: 27, column: 10, scope: !133)
// CHECK:STDOUT: !149 = !DILocation(line: 27, column: 3, scope: !133)
// CHECK:STDOUT: !150 = !{!134, !135}
// CHECK:STDOUT: !151 = !DIFile(filename: "{{.*}}/prelude/types/result.carbon", directory: "")
// CHECK:STDOUT: !152 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.Result.Core.f303d81b2fad85a0", scope: null, file: !151, line: 28, type: !34, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !156)
// CHECK:STDOUT: !153 = !DILocalVariable(arg: 1, scope: !152, type: !6)
// CHECK:STDOUT: !154 = !DILocation(line: 28, column: 1, scope: !152)
// CHECK:STDOUT: !155 = !DILocation(line: 29, column: 15, scope: !152)
// CHECK:STDOUT: !156 = !{!153}
// CHECK:STDOUT: !157 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.Result.Core.f303d81b2fad85a0", scope: null, file: !151, line: 28, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !160)
// CHECK:STDOUT: !158 = !DILocalVariable(arg: 1, scope: !157, type: !8)
// CHECK:STDOUT: !159 = !DILocation(line: 28, column: 1, scope: !157)
// CHECK:STDOUT: !160 = !{!158}
// CHECK:STDOUT: !161 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0", scope: null, file: !151, line: 42, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !180)
// CHECK:STDOUT: !162 = !DILocalVariable(arg: 1, scope: !161, type: !8)
// CHECK:STDOUT: !167 = !DILocation(line: 44, column: 7, scope: !161)
// CHECK:STDOUT: !170 = !DILocation(line: 44, column: 34, scope: !161)
// CHECK:STDOUT: !171 = !DILocation(line: 44, column: 27, scope: !161)
// CHECK:STDOUT: !172 = !DILocation(line: 45, column: 7, scope: !161)
// CHECK:STDOUT: !175 = !DILocation(line: 45, column: 35, scope: !161)
// CHECK:STDOUT: !176 = !DILocation(line: 45, column: 28, scope: !161)
// CHECK:STDOUT: !178 = !DILocation(line: 49, column: 12, scope: !161)
// CHECK:STDOUT: !179 = !DILocation(line: 49, column: 5, scope: !161)
// CHECK:STDOUT: !180 = !{!162}
// CHECK:STDOUT: !181 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.f303d81b2fad85a0", scope: null, file: !151, line: 51, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !189)
// CHECK:STDOUT: !182 = !DILocalVariable(arg: 1, scope: !181, type: !8)
// CHECK:STDOUT: !187 = !DILocation(line: 51, column: 39, scope: !181)
// CHECK:STDOUT: !188 = !DILocation(line: 51, column: 32, scope: !181)
// CHECK:STDOUT: !189 = !{!182}
// CHECK:STDOUT: !190 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.Result.Core.ee51b1618614817f", scope: null, file: !151, line: 28, type: !10, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !191 = !DILocation(line: 28, column: 1, scope: !190)
// CHECK:STDOUT: !192 = !DILocation(line: 29, column: 15, scope: !190)
// CHECK:STDOUT: !193 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.Result.Core.ee51b1618614817f", scope: null, file: !151, line: 28, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !196)
// CHECK:STDOUT: !194 = !DILocalVariable(arg: 1, scope: !193, type: !8)
// CHECK:STDOUT: !195 = !DILocation(line: 28, column: 1, scope: !193)
// CHECK:STDOUT: !196 = !{!194}
// CHECK:STDOUT: !197 = distinct !DISubprogram(name: "Branch", linkageName: "_CBranch.Result.f15b7207a8078ef6.Core:Try.Core.ee51b1618614817f", scope: null, file: !151, line: 42, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !216)
// CHECK:STDOUT: !198 = !DILocalVariable(arg: 1, scope: !197, type: !8)
// CHECK:STDOUT: !203 = !DILocation(line: 44, column: 7, scope: !197)
// CHECK:STDOUT: !206 = !DILocation(line: 44, column: 34, scope: !197)
// CHECK:STDOUT: !207 = !DILocation(line: 44, column: 27, scope: !197)
// CHECK:STDOUT: !208 = !DILocation(line: 45, column: 7, scope: !197)
// CHECK:STDOUT: !211 = !DILocation(line: 45, column: 35, scope: !197)
// CHECK:STDOUT: !212 = !DILocation(line: 45, column: 28, scope: !197)
// CHECK:STDOUT: !214 = !DILocation(line: 49, column: 12, scope: !197)
// CHECK:STDOUT: !215 = !DILocation(line: 49, column: 5, scope: !197)
// CHECK:STDOUT: !216 = !{!198}
// CHECK:STDOUT: !217 = distinct !DISubprogram(name: "FromBreak", linkageName: "_CFromBreak.Result.f15b7207a8078ef6.Core:Try.Core.ee51b1618614817f", scope: null, file: !151, line: 51, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !225)
// CHECK:STDOUT: !218 = !DILocalVariable(arg: 1, scope: !217, type: !8)
// CHECK:STDOUT: !223 = !DILocation(line: 51, column: 39, scope: !217)
// CHECK:STDOUT: !224 = !DILocation(line: 51, column: 32, scope: !217)
// CHECK:STDOUT: !225 = !{!218}
// CHECK:STDOUT: !226 = !DIFile(filename: "{{.*}}/prelude/try.carbon", directory: "")
// CHECK:STDOUT: !227 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.f303d81b2fad85a0", scope: null, file: !226, line: 21, type: !34, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !231)
// CHECK:STDOUT: !228 = !DILocalVariable(arg: 1, scope: !227, type: !6)
// CHECK:STDOUT: !229 = !DILocation(line: 21, column: 1, scope: !227)
// CHECK:STDOUT: !230 = !DILocation(line: 22, column: 21, scope: !227)
// CHECK:STDOUT: !231 = !{!228}
// CHECK:STDOUT: !232 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.f303d81b2fad85a0", scope: null, file: !226, line: 21, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !235)
// CHECK:STDOUT: !233 = !DILocalVariable(arg: 1, scope: !232, type: !8)
// CHECK:STDOUT: !234 = !DILocation(line: 21, column: 1, scope: !232)
// CHECK:STDOUT: !235 = !{!233}
// CHECK:STDOUT: !236 = distinct !DISubprogram(name: "Continue", linkageName: "_CContinue.ControlFlow.Core.ee51b1618614817f", scope: null, file: !226, line: 21, type: !10, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !237 = !DILocation(line: 21, column: 1, scope: !236)
// CHECK:STDOUT: !238 = !DILocation(line: 22, column: 21, scope: !236)
// CHECK:STDOUT: !239 = distinct !DISubprogram(name: "Break", linkageName: "_CBreak.ControlFlow.Core.ee51b1618614817f", scope: null, file: !226, line: 21, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !242)
// CHECK:STDOUT: !240 = !DILocalVariable(arg: 1, scope: !239, type: !8)
// CHECK:STDOUT: !241 = !DILocation(line: 21, column: 1, scope: !239)
// CHECK:STDOUT: !242 = !{!240}
// CHECK:STDOUT: !243 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !244 = !{!"omnipotent char", !243, i64 0}
// CHECK:STDOUT: !245 = !{!"int", !244, i64 0}
// CHECK:STDOUT: !246 = !{!"any pointer", !244, i64 0}
// CHECK:STDOUT: !247 = !{!"p1 int", !246, i64 0}
// CHECK:STDOUT: !248 = !{!247, !247, i64 0}
// CHECK:STDOUT: !249 = !{!"any p2 pointer", !246, i64 0}
// CHECK:STDOUT: !250 = !{!249, !249, i64 0}
// CHECK:STDOUT: !251 = !{!245, !245, i64 0}
// CHECK:STDOUT: !252 = !{!246, !246, i64 0}
// CHECK:STDOUT: !253 = !{!"p1 _ZTS1C", !246, i64 0}
// CHECK:STDOUT: !254 = !{!253, !253, i64 0}
// CHECK:STDOUT: !256 = !{}
// CHECK:STDOUT: !257 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !258 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !259 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !260 = !{!"__libc_errno", !245, i64 0}
// CHECK:STDOUT: !261 = !{!260, !245, i64 0}
// CHECK:STDOUT:

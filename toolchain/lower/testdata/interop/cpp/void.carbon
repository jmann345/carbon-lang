// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/void.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/void.carbon

// --- void_ptr.h

void take_void_ptr(void *p);
void take_const_void_ptr(const void *p);
void *return_void_ptr();

// --- pass.carbon

library "[[@TEST_NAME]]";

import Cpp library "void_ptr.h";

fn PassVoidPtr(a: Cpp.void*) {
  Cpp.take_void_ptr(a);
}

fn PassIntPtr(a: Cpp.int*) {
  Cpp.take_void_ptr(a);
}

fn PassIntPtrToConstVoidPtr(a: Cpp.int*) {
  Cpp.take_const_void_ptr(a);
}

fn PassConstIntPtrToConstVoidPtr(a: const Cpp.int*) {
  Cpp.take_const_void_ptr(a);
}

// --- receive.carbon

library "[[@TEST_NAME]]";

import Cpp library "void_ptr.h";

fn ReceiveVoidPtr() -> Core.Optional(Cpp.void*) {
  return Cpp.return_void_ptr();
}

fn ConvertFromVoidPtr(p: Cpp.void*) -> i32* {
  return p unsafe as i32*;
}

fn ConvertFromConstVoidPtr(p: const Cpp.void*) -> const i32* {
  return p unsafe as const i32*;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'pass.carbon'
// CHECK:STDOUT: source_filename = "pass.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [80 x i8] c"carbon: C++ exception escaped into Carbon through `take_void_ptr`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [86 x i8] c"carbon: C++ exception escaped into Carbon through `take_const_void_ptr`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CPassVoidPtr.Main(ptr %a) #0 !dbg !10 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_21.2.temp = alloca ptr, align 8, !dbg !13
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.call = call ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.0532bac23645330a"(ptr %a), !dbg !13
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc7_21.2.temp), !dbg !13
// CHECK:STDOUT:   store ptr %U.as_type.as.ImplicitAs.impl.Convert.call, ptr %.loc7_21.2.temp, align 8, !dbg !13
// CHECK:STDOUT:   %.loc7_21.4 = load ptr, ptr %.loc7_21.2.temp, align 8, !dbg !13
// CHECK:STDOUT:   call void @_Z13take_void_ptrPv.carbon_thunk._(ptr %.loc7_21.4), !dbg !16
// CHECK:STDOUT:   call void @"_CSelfDestruct.14b4a412ddf73a96:core.Destroy.Core"(ptr %.loc7_21.2.temp), !dbg !13
// CHECK:STDOUT:   ret void, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.00ac8ef5084ea134:core.Destroy.Core"(ptr %self) #0 !dbg !20 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !22
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z13take_void_ptrPv.carbon_thunk._(ptr noundef %p) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %p.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %p, ptr %p.addr, align 8, !tbaa !206
// CHECK:STDOUT:   %0 = load ptr, ptr %p.addr, align 8, !tbaa !206
// CHECK:STDOUT:   invoke void @_Z13take_void_ptrPv(ptr noundef %0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
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
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 79) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #7
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %6) #8
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a7d1b77eb1279818:core.Destroy.Core"(ptr %self) #0 !dbg !24 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.174120d4d03791b0:core.Destroy.Core"(ptr %self) #0 !dbg !28 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.14b4a412ddf73a96:core.Destroy.Core"(ptr %self) #0 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CPassIntPtr.Main(ptr %a) #0 !dbg !36 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc11_21.2.temp = alloca ptr, align 8, !dbg !39
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.call = call ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.6031252d10ea5365"(ptr %a), !dbg !39
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc11_21.2.temp), !dbg !39
// CHECK:STDOUT:   store ptr %U.as_type.as.ImplicitAs.impl.Convert.call, ptr %.loc11_21.2.temp, align 8, !dbg !39
// CHECK:STDOUT:   %.loc11_21.4 = load ptr, ptr %.loc11_21.2.temp, align 8, !dbg !39
// CHECK:STDOUT:   call void @_Z13take_void_ptrPv.carbon_thunk._(ptr %.loc11_21.4), !dbg !40
// CHECK:STDOUT:   call void @"_CSelfDestruct.14b4a412ddf73a96:core.Destroy.Core"(ptr %.loc11_21.2.temp), !dbg !39
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %self) #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CPassIntPtrToConstVoidPtr.Main(ptr %a) #0 !dbg !47 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc15_27.2.temp = alloca ptr, align 8, !dbg !50
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.call = call ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.d72303bab6c7803c"(ptr %a), !dbg !50
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc15_27.2.temp), !dbg !50
// CHECK:STDOUT:   store ptr %U.as_type.as.ImplicitAs.impl.Convert.call, ptr %.loc15_27.2.temp, align 8, !dbg !50
// CHECK:STDOUT:   %.loc15_27.4 = load ptr, ptr %.loc15_27.2.temp, align 8, !dbg !50
// CHECK:STDOUT:   call void @_Z19take_const_void_ptrPKv.carbon_thunk._(ptr %.loc15_27.4), !dbg !51
// CHECK:STDOUT:   call void @"_CSelfDestruct.dfb26e502f641cc5:core.Destroy.Core"(ptr %.loc15_27.2.temp), !dbg !50
// CHECK:STDOUT:   ret void, !dbg !52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e9afb99fe676df82:core.Destroy.Core"(ptr %self) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z19take_const_void_ptrPKv.carbon_thunk._(ptr noundef %p) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %p.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %p, ptr %p.addr, align 8, !tbaa !206
// CHECK:STDOUT:   %0 = load ptr, ptr %p.addr, align 8, !tbaa !206
// CHECK:STDOUT:   invoke void @_Z19take_const_void_ptrPKv(ptr noundef %0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
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
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.1, i64 noundef 85) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #7
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %6) #8
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.8d3ff16138365f48:core.Destroy.Core"(ptr %self) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !60
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.4e1f0f3b7725eea2:core.Destroy.Core"(ptr %self) #0 !dbg !62 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !64
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.dfb26e502f641cc5:core.Destroy.Core"(ptr %self) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !68
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CPassConstIntPtrToConstVoidPtr.Main(ptr %a) #0 !dbg !70 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_27.2.temp = alloca ptr, align 8, !dbg !73
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.call = call ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.d72303bab6c7803c"(ptr %a), !dbg !73
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc19_27.2.temp), !dbg !73
// CHECK:STDOUT:   store ptr %U.as_type.as.ImplicitAs.impl.Convert.call, ptr %.loc19_27.2.temp, align 8, !dbg !73
// CHECK:STDOUT:   %.loc19_27.4 = load ptr, ptr %.loc19_27.2.temp, align 8, !dbg !73
// CHECK:STDOUT:   call void @_Z19take_const_void_ptrPKv.carbon_thunk._(ptr %.loc19_27.4), !dbg !74
// CHECK:STDOUT:   call void @"_CSelfDestruct.dfb26e502f641cc5:core.Destroy.Core"(ptr %.loc19_27.2.temp), !dbg !73
// CHECK:STDOUT:   ret void, !dbg !75
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.7742c7b82efb7924:core.Destroy.Core"(ptr %self) #0 !dbg !77 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !79
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.0532bac23645330a"(ptr %self) #0 !dbg !82 {
// CHECK:STDOUT:   %1 = call ptr @"_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.4201ec9a263c5642"(ptr %self), !dbg !87
// CHECK:STDOUT:   ret ptr %1, !dbg !88
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.6031252d10ea5365"(ptr %self) #0 !dbg !90 {
// CHECK:STDOUT:   %1 = call ptr @"_CConvert.d62727437df45535:OptionalAs.1dac4564233fecd1.Core.1e16d6a5a3286ade"(ptr %self), !dbg !95
// CHECK:STDOUT:   ret ptr %1, !dbg !96
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.d72303bab6c7803c"(ptr %self) #0 !dbg !98 {
// CHECK:STDOUT:   %1 = call ptr @"_CConvert.d62727437df45535:OptionalAs.1dac4564233fecd1.Core.ea6f599e1a77a7ea"(ptr %self), !dbg !103
// CHECK:STDOUT:   ret ptr %1, !dbg !104
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.4201ec9a263c5642"(ptr %self) #0 !dbg !114 {
// CHECK:STDOUT:   %1 = call ptr @_CSome.Optional.Core.4201ec9a263c5642(ptr %self), !dbg !120
// CHECK:STDOUT:   ret ptr %1, !dbg !121
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.d62727437df45535:OptionalAs.1dac4564233fecd1.Core.1e16d6a5a3286ade"(ptr %self) #0 !dbg !123 {
// CHECK:STDOUT:   %temp = alloca ptr, align 8, !dbg !128
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !128
// CHECK:STDOUT:   store ptr %self, ptr %temp, align 8, !dbg !128
// CHECK:STDOUT:   %1 = load ptr, ptr %temp, align 8, !dbg !128
// CHECK:STDOUT:   %2 = call ptr @_CSome.Optional.Core.4201ec9a263c5642(ptr %1), !dbg !129
// CHECK:STDOUT:   call void @"_CSelfDestruct.00ac8ef5084ea134:core.Destroy.Core"(ptr %temp), !dbg !128
// CHECK:STDOUT:   ret ptr %2, !dbg !130
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.d62727437df45535:OptionalAs.1dac4564233fecd1.Core.ea6f599e1a77a7ea"(ptr %self) #0 !dbg !132 {
// CHECK:STDOUT:   %temp = alloca ptr, align 8, !dbg !137
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !137
// CHECK:STDOUT:   %1 = call ptr @"_CConvert:thunk:ImplicitAs.a569d188b7ffe592.Core:e8f8f92d3d08d149:ImplicitAs.01c4a560c986e7d1.Core.84588f41d61dafba"(ptr %self), !dbg !137
// CHECK:STDOUT:   store ptr %1, ptr %temp, align 8, !dbg !137
// CHECK:STDOUT:   %2 = load ptr, ptr %temp, align 8, !dbg !137
// CHECK:STDOUT:   %3 = call ptr @_CSome.Optional.Core.e4523e01ac2590ba(ptr %2), !dbg !138
// CHECK:STDOUT:   call void @"_CSelfDestruct.e9afb99fe676df82:core.Destroy.Core"(ptr %temp), !dbg !137
// CHECK:STDOUT:   ret ptr %3, !dbg !139
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CSome.Optional.Core.4201ec9a263c5642(ptr %value) #0 !dbg !150 {
// CHECK:STDOUT:   %1 = call ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.7a595a06c724a271"(ptr %value), !dbg !155
// CHECK:STDOUT:   ret ptr %1, !dbg !156
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert:thunk:ImplicitAs.a569d188b7ffe592.Core:e8f8f92d3d08d149:ImplicitAs.01c4a560c986e7d1.Core.84588f41d61dafba"(ptr %self) #3 !dbg !159 {
// CHECK:STDOUT:   ret ptr %self, !dbg !162
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CSome.Optional.Core.e4523e01ac2590ba(ptr %value) #0 !dbg !164 {
// CHECK:STDOUT:   %1 = call ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.8f1054b47505c137"(ptr %value), !dbg !169
// CHECK:STDOUT:   ret ptr %1, !dbg !170
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.7a595a06c724a271"(ptr %self) #0 !dbg !177 {
// CHECK:STDOUT:   %1 = alloca ptr, align 8, !dbg !182
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !182
// CHECK:STDOUT:   store ptr poison, ptr %1, align 8, !dbg !182
// CHECK:STDOUT:   store ptr %self, ptr %1, align 8, !dbg !186
// CHECK:STDOUT:   %2 = load ptr, ptr %1, align 8, !dbg !184
// CHECK:STDOUT:   call void @"_CSelfDestruct.174120d4d03791b0:core.Destroy.Core"(ptr %1), !dbg !182
// CHECK:STDOUT:   ret ptr %2, !dbg !188
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.8f1054b47505c137"(ptr %self) #0 !dbg !190 {
// CHECK:STDOUT:   %1 = alloca ptr, align 8, !dbg !195
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !195
// CHECK:STDOUT:   store ptr poison, ptr %1, align 8, !dbg !195
// CHECK:STDOUT:   store ptr %self, ptr %1, align 8, !dbg !199
// CHECK:STDOUT:   %2 = load ptr, ptr %1, align 8, !dbg !197
// CHECK:STDOUT:   call void @"_CSelfDestruct.4e1f0f3b7725eea2:core.Destroy.Core"(ptr %1), !dbg !195
// CHECK:STDOUT:   ret ptr %2, !dbg !201
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_Z13take_void_ptrPv(ptr noundef) #4
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #5
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #6 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #8
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_Z19take_const_void_ptrPKv(ptr noundef) #4
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 0, 1, 2, 3, 7, 6, 5, 4 }
// CHECK:STDOUT: uselistorder ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.d72303bab6c7803c", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CSome.Optional.Core.4201ec9a263c5642, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_begin_catch, { 1, 2, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_rethrow, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { alwaysinline nounwind }
// CHECK:STDOUT: attributes #4 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #7 = { noreturn }
// CHECK:STDOUT: attributes #8 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!207, !208, !209, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!212}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "pass.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{null, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = distinct !DISubprogram(name: "PassVoidPtr", linkageName: "_CPassVoidPtr.Main", scope: null, file: !4, line: 6, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !18)
// CHECK:STDOUT: !11 = !DILocalVariable(arg: 1, scope: !10, type: !7)
// CHECK:STDOUT: !13 = !DILocation(line: 7, column: 21, scope: !10)
// CHECK:STDOUT: !14 = !{!7, !7}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !16 = !DILocation(line: 7, column: 3, scope: !10)
// CHECK:STDOUT: !17 = !DILocation(line: 6, column: 1, scope: !10)
// CHECK:STDOUT: !18 = !{!11}
// CHECK:STDOUT: !19 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !20 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.00ac8ef5084ea134:core.Destroy.Core", scope: null, file: !19, line: 189, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !23)
// CHECK:STDOUT: !21 = !DILocalVariable(arg: 1, scope: !20, type: !7)
// CHECK:STDOUT: !22 = !DILocation(line: 189, column: 19, scope: !20)
// CHECK:STDOUT: !23 = !{!21}
// CHECK:STDOUT: !24 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a7d1b77eb1279818:core.Destroy.Core", scope: null, file: !4, line: 7, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !27)
// CHECK:STDOUT: !25 = !DILocalVariable(arg: 1, scope: !24, type: !7)
// CHECK:STDOUT: !26 = !DILocation(line: 7, column: 21, scope: !24)
// CHECK:STDOUT: !27 = !{!25}
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.174120d4d03791b0:core.Destroy.Core", scope: null, file: !4, line: 7, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !31)
// CHECK:STDOUT: !29 = !DILocalVariable(arg: 1, scope: !28, type: !7)
// CHECK:STDOUT: !30 = !DILocation(line: 7, column: 21, scope: !28)
// CHECK:STDOUT: !31 = !{!29}
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.14b4a412ddf73a96:core.Destroy.Core", scope: null, file: !4, line: 7, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !35)
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !32, type: !7)
// CHECK:STDOUT: !34 = !DILocation(line: 7, column: 21, scope: !32)
// CHECK:STDOUT: !35 = !{!33}
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "PassIntPtr", linkageName: "_CPassIntPtr.Main", scope: null, file: !4, line: 10, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !42)
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !36, type: !7)
// CHECK:STDOUT: !39 = !DILocation(line: 11, column: 21, scope: !36)
// CHECK:STDOUT: !40 = !DILocation(line: 11, column: 3, scope: !36)
// CHECK:STDOUT: !41 = !DILocation(line: 10, column: 1, scope: !36)
// CHECK:STDOUT: !42 = !{!37}
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d088c7eb746488be:core.Destroy.Core", scope: null, file: !19, line: 189, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !46)
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !43, type: !7)
// CHECK:STDOUT: !45 = !DILocation(line: 189, column: 19, scope: !43)
// CHECK:STDOUT: !46 = !{!44}
// CHECK:STDOUT: !47 = distinct !DISubprogram(name: "PassIntPtrToConstVoidPtr", linkageName: "_CPassIntPtrToConstVoidPtr.Main", scope: null, file: !4, line: 14, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !53)
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !47, type: !7)
// CHECK:STDOUT: !50 = !DILocation(line: 15, column: 27, scope: !47)
// CHECK:STDOUT: !51 = !DILocation(line: 15, column: 3, scope: !47)
// CHECK:STDOUT: !52 = !DILocation(line: 14, column: 1, scope: !47)
// CHECK:STDOUT: !53 = !{!48}
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e9afb99fe676df82:core.Destroy.Core", scope: null, file: !19, line: 189, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !57)
// CHECK:STDOUT: !55 = !DILocalVariable(arg: 1, scope: !54, type: !7)
// CHECK:STDOUT: !56 = !DILocation(line: 189, column: 19, scope: !54)
// CHECK:STDOUT: !57 = !{!55}
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.8d3ff16138365f48:core.Destroy.Core", scope: null, file: !4, line: 15, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !61)
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !58, type: !7)
// CHECK:STDOUT: !60 = !DILocation(line: 15, column: 27, scope: !58)
// CHECK:STDOUT: !61 = !{!59}
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.4e1f0f3b7725eea2:core.Destroy.Core", scope: null, file: !4, line: 15, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !65)
// CHECK:STDOUT: !63 = !DILocalVariable(arg: 1, scope: !62, type: !7)
// CHECK:STDOUT: !64 = !DILocation(line: 15, column: 27, scope: !62)
// CHECK:STDOUT: !65 = !{!63}
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.dfb26e502f641cc5:core.Destroy.Core", scope: null, file: !4, line: 15, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !69)
// CHECK:STDOUT: !67 = !DILocalVariable(arg: 1, scope: !66, type: !7)
// CHECK:STDOUT: !68 = !DILocation(line: 15, column: 27, scope: !66)
// CHECK:STDOUT: !69 = !{!67}
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "PassConstIntPtrToConstVoidPtr", linkageName: "_CPassConstIntPtrToConstVoidPtr.Main", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !76)
// CHECK:STDOUT: !71 = !DILocalVariable(arg: 1, scope: !70, type: !7)
// CHECK:STDOUT: !73 = !DILocation(line: 19, column: 27, scope: !70)
// CHECK:STDOUT: !74 = !DILocation(line: 19, column: 3, scope: !70)
// CHECK:STDOUT: !75 = !DILocation(line: 18, column: 1, scope: !70)
// CHECK:STDOUT: !76 = !{!71}
// CHECK:STDOUT: !77 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.7742c7b82efb7924:core.Destroy.Core", scope: null, file: !19, line: 189, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !80)
// CHECK:STDOUT: !78 = !DILocalVariable(arg: 1, scope: !77, type: !7)
// CHECK:STDOUT: !79 = !DILocation(line: 189, column: 19, scope: !77)
// CHECK:STDOUT: !80 = !{!78}
// CHECK:STDOUT: !82 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.0532bac23645330a", scope: null, file: !19, line: 130, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !89)
// CHECK:STDOUT: !83 = !DILocalVariable(arg: 1, scope: !82, type: !7)
// CHECK:STDOUT: !87 = !DILocation(line: 131, column: 12, scope: !82)
// CHECK:STDOUT: !88 = !DILocation(line: 131, column: 5, scope: !82)
// CHECK:STDOUT: !89 = !{!83}
// CHECK:STDOUT: !90 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.6031252d10ea5365", scope: null, file: !19, line: 130, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !97)
// CHECK:STDOUT: !91 = !DILocalVariable(arg: 1, scope: !90, type: !7)
// CHECK:STDOUT: !95 = !DILocation(line: 131, column: 12, scope: !90)
// CHECK:STDOUT: !96 = !DILocation(line: 131, column: 5, scope: !90)
// CHECK:STDOUT: !97 = !{!91}
// CHECK:STDOUT: !98 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.d72303bab6c7803c", scope: null, file: !19, line: 130, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !105)
// CHECK:STDOUT: !99 = !DILocalVariable(arg: 1, scope: !98, type: !7)
// CHECK:STDOUT: !103 = !DILocation(line: 131, column: 12, scope: !98)
// CHECK:STDOUT: !104 = !DILocation(line: 131, column: 5, scope: !98)
// CHECK:STDOUT: !105 = !{!99}
// CHECK:STDOUT: !114 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.4201ec9a263c5642", scope: null, file: !19, line: 105, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !122)
// CHECK:STDOUT: !115 = !DILocalVariable(arg: 1, scope: !114, type: !7)
// CHECK:STDOUT: !120 = !DILocation(line: 106, column: 12, scope: !114)
// CHECK:STDOUT: !121 = !DILocation(line: 106, column: 5, scope: !114)
// CHECK:STDOUT: !122 = !{!115}
// CHECK:STDOUT: !123 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.d62727437df45535:OptionalAs.1dac4564233fecd1.Core.1e16d6a5a3286ade", scope: null, file: !19, line: 112, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !131)
// CHECK:STDOUT: !124 = !DILocalVariable(arg: 1, scope: !123, type: !7)
// CHECK:STDOUT: !128 = !DILocation(line: 113, column: 29, scope: !123)
// CHECK:STDOUT: !129 = !DILocation(line: 113, column: 12, scope: !123)
// CHECK:STDOUT: !130 = !DILocation(line: 113, column: 5, scope: !123)
// CHECK:STDOUT: !131 = !{!124}
// CHECK:STDOUT: !132 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.d62727437df45535:OptionalAs.1dac4564233fecd1.Core.ea6f599e1a77a7ea", scope: null, file: !19, line: 112, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !140)
// CHECK:STDOUT: !133 = !DILocalVariable(arg: 1, scope: !132, type: !7)
// CHECK:STDOUT: !137 = !DILocation(line: 113, column: 29, scope: !132)
// CHECK:STDOUT: !138 = !DILocation(line: 113, column: 12, scope: !132)
// CHECK:STDOUT: !139 = !DILocation(line: 113, column: 5, scope: !132)
// CHECK:STDOUT: !140 = !{!133}
// CHECK:STDOUT: !150 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.4201ec9a263c5642", scope: null, file: !19, line: 34, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !157)
// CHECK:STDOUT: !151 = !DILocalVariable(arg: 1, scope: !150, type: !7)
// CHECK:STDOUT: !155 = !DILocation(line: 35, column: 12, scope: !150)
// CHECK:STDOUT: !156 = !DILocation(line: 35, column: 5, scope: !150)
// CHECK:STDOUT: !157 = !{!151}
// CHECK:STDOUT: !158 = !DIFile(filename: "{{.*}}/prelude/types/cpp/void.carbon", directory: "")
// CHECK:STDOUT: !159 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert:thunk:ImplicitAs.a569d188b7ffe592.Core:e8f8f92d3d08d149:ImplicitAs.01c4a560c986e7d1.Core.84588f41d61dafba", scope: null, file: !158, line: 40, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !163)
// CHECK:STDOUT: !160 = !DILocalVariable(arg: 1, scope: !159, type: !7)
// CHECK:STDOUT: !162 = !DILocation(line: 40, column: 3, scope: !159)
// CHECK:STDOUT: !163 = !{!160}
// CHECK:STDOUT: !164 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.e4523e01ac2590ba", scope: null, file: !19, line: 34, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !171)
// CHECK:STDOUT: !165 = !DILocalVariable(arg: 1, scope: !164, type: !7)
// CHECK:STDOUT: !169 = !DILocation(line: 35, column: 12, scope: !164)
// CHECK:STDOUT: !170 = !DILocation(line: 35, column: 5, scope: !164)
// CHECK:STDOUT: !171 = !{!165}
// CHECK:STDOUT: !177 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.e8f8f92d3d08d149:OptionalStorage.Core.7a595a06c724a271", scope: null, file: !19, line: 191, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !189)
// CHECK:STDOUT: !178 = !DILocalVariable(arg: 1, scope: !177, type: !7)
// CHECK:STDOUT: !182 = !DILocation(line: 192, column: 14, scope: !177)
// CHECK:STDOUT: !184 = !DILocation(line: 192, column: 18, scope: !177)
// CHECK:STDOUT: !186 = !DILocation(line: 194, column: 5, scope: !177)
// CHECK:STDOUT: !188 = !DILocation(line: 195, column: 5, scope: !177)
// CHECK:STDOUT: !189 = !{!178}
// CHECK:STDOUT: !190 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.e8f8f92d3d08d149:OptionalStorage.Core.8f1054b47505c137", scope: null, file: !19, line: 191, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !202)
// CHECK:STDOUT: !191 = !DILocalVariable(arg: 1, scope: !190, type: !7)
// CHECK:STDOUT: !195 = !DILocation(line: 192, column: 14, scope: !190)
// CHECK:STDOUT: !197 = !DILocation(line: 192, column: 18, scope: !190)
// CHECK:STDOUT: !199 = !DILocation(line: 194, column: 5, scope: !190)
// CHECK:STDOUT: !201 = !DILocation(line: 195, column: 5, scope: !190)
// CHECK:STDOUT: !202 = !{!191}
// CHECK:STDOUT: !203 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !204 = !{!"omnipotent char", !203, i64 0}
// CHECK:STDOUT: !205 = !{!"any pointer", !204, i64 0}
// CHECK:STDOUT: !206 = !{!205, !205, i64 0}
// CHECK:STDOUT: !207 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !208 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !209 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !210 = !{!"int", !204, i64 0}
// CHECK:STDOUT: !211 = !{!"__libc_errno", !210, i64 0}
// CHECK:STDOUT: !212 = !{!211, !210, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'receive.carbon'
// CHECK:STDOUT: source_filename = "receive.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [82 x i8] c"carbon: C++ exception escaped into Carbon through `return_void_ptr`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.00ac8ef5084ea134:core.Destroy.Core"(ptr %self) #0 !dbg !217 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !219
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define ptr @_CReceiveVoidPtr.Main() #0 !dbg !221 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %return_void_ptr__carbon_thunk.call = call ptr @_Z15return_void_ptrv.carbon_thunk.(), !dbg !224
// CHECK:STDOUT:   ret ptr %return_void_ptr__carbon_thunk.call, !dbg !225
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef ptr @_Z15return_void_ptrv.carbon_thunk.() #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   %call = invoke noundef ptr @_Z15return_void_ptrv()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret ptr %call
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 81) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #5
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %4 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %4, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %5) #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define ptr @_CConvertFromVoidPtr.Main(ptr %p) #0 !dbg !226 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret ptr %p, !dbg !232
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define ptr @_CConvertFromConstVoidPtr.Main(ptr %p) #0 !dbg !234 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret ptr %p, !dbg !240
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare noundef ptr @_Z15return_void_ptrv() #2
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #3
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #4 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #3 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noreturn }
// CHECK:STDOUT: attributes #6 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!214}
// CHECK:STDOUT: !llvm.module.flags = !{!207, !208, !209, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!212}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{null, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !14 = !{!7, !7}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !19 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !203 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !204 = !{!"omnipotent char", !203, i64 0}
// CHECK:STDOUT: !207 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !208 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !209 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !210 = !{!"int", !204, i64 0}
// CHECK:STDOUT: !211 = !{!"__libc_errno", !210, i64 0}
// CHECK:STDOUT: !212 = !{!211, !210, i64 0}
// CHECK:STDOUT: !213 = !DIFile(filename: "receive.carbon", directory: "")
// CHECK:STDOUT: !214 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !213, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !215 = !{!7}
// CHECK:STDOUT: !216 = !DISubroutineType(types: !215)
// CHECK:STDOUT: !217 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.00ac8ef5084ea134:core.Destroy.Core", scope: null, file: !19, line: 189, type: !9, spFlags: DISPFlagDefinition, unit: !214, retainedNodes: !220)
// CHECK:STDOUT: !218 = !DILocalVariable(arg: 1, scope: !217, type: !7)
// CHECK:STDOUT: !219 = !DILocation(line: 189, column: 19, scope: !217)
// CHECK:STDOUT: !220 = !{!218}
// CHECK:STDOUT: !221 = distinct !DISubprogram(name: "ReceiveVoidPtr", linkageName: "_CReceiveVoidPtr.Main", scope: null, file: !213, line: 6, type: !216, spFlags: DISPFlagDefinition, unit: !214)
// CHECK:STDOUT: !224 = !DILocation(line: 7, column: 10, scope: !221)
// CHECK:STDOUT: !225 = !DILocation(line: 7, column: 3, scope: !221)
// CHECK:STDOUT: !226 = distinct !DISubprogram(name: "ConvertFromVoidPtr", linkageName: "_CConvertFromVoidPtr.Main", scope: null, file: !213, line: 10, type: !15, spFlags: DISPFlagDefinition, unit: !214, retainedNodes: !233)
// CHECK:STDOUT: !227 = !DILocalVariable(arg: 1, scope: !226, type: !7)
// CHECK:STDOUT: !232 = !DILocation(line: 11, column: 3, scope: !226)
// CHECK:STDOUT: !233 = !{!227}
// CHECK:STDOUT: !234 = distinct !DISubprogram(name: "ConvertFromConstVoidPtr", linkageName: "_CConvertFromConstVoidPtr.Main", scope: null, file: !213, line: 14, type: !15, spFlags: DISPFlagDefinition, unit: !214, retainedNodes: !241)
// CHECK:STDOUT: !235 = !DILocalVariable(arg: 1, scope: !234, type: !7)
// CHECK:STDOUT: !240 = !DILocation(line: 15, column: 3, scope: !234)
// CHECK:STDOUT: !241 = !{!235}
// CHECK:STDOUT:

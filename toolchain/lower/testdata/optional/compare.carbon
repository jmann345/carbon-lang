// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/optional/compare.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/optional/compare.carbon

// Fork (OP-1, fork/optional/plan.md §4): the comparison impls are generic, so
// the `Optional(i32)` specific of each impl function is emitted here, with its
// `HasValue()` tests before its `Get()` calls (D-OP-1, D-OP-2, D-OP-4).

fn IsEq(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a == b; }
fn IsNe(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a != b; }
fn IsLt(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a < b; }
fn IsLe(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a <= b; }
fn IsGt(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a > b; }
fn IsGe(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a >= b; }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'compare.carbon'
// CHECK:STDOUT: source_filename = "compare.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [58 x i8] c"carbon: Core.Optional.Get on an empty value; terminating\0A\00", align 1
// CHECK:STDOUT: @const.anon = internal constant { ptr, i64 } { ptr @0, i64 57 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !14
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i1 @_CIsEq.Main(ptr %a, ptr %b) #0 !dbg !16 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.call = call i1 @"_CEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9"(ptr %a, ptr %b), !dbg !23
// CHECK:STDOUT:   ret i1 %Optional.as.EqWith.impl.Equal.call, !dbg !25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i1 @_CIsNe.Main(ptr %a, ptr %b) #0 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Optional.as.EqWith.impl.NotEqual.call = call i1 @"_CNotEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9"(ptr %a, ptr %b), !dbg !34
// CHECK:STDOUT:   ret i1 %Optional.as.EqWith.impl.NotEqual.call, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i1 @_CIsLt.Main(ptr %a, ptr %b) #0 !dbg !38 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Less.call = call i1 @"_CLess.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %a, ptr %b), !dbg !45
// CHECK:STDOUT:   ret i1 %Optional.as.OrderedWith.impl.Less.call, !dbg !47
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i1 @_CIsLe.Main(ptr %a, ptr %b) #0 !dbg !49 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.LessOrEquivalent.call = call i1 @"_CLessOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %a, ptr %b), !dbg !56
// CHECK:STDOUT:   ret i1 %Optional.as.OrderedWith.impl.LessOrEquivalent.call, !dbg !58
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i1 @_CIsGt.Main(ptr %a, ptr %b) #0 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Greater.call = call i1 @"_CGreater.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %a, ptr %b), !dbg !67
// CHECK:STDOUT:   ret i1 %Optional.as.OrderedWith.impl.Greater.call, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i1 @_CIsGe.Main(ptr %a, ptr %b) #0 !dbg !71 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.GreaterOrEquivalent.call = call i1 @"_CGreaterOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %a, ptr %b), !dbg !78
// CHECK:STDOUT:   ret i1 %Optional.as.OrderedWith.impl.GreaterOrEquivalent.call, !dbg !80
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9"(ptr %self, ptr %other) #0 !dbg !88 {
// CHECK:STDOUT:   %temp = alloca i32, align 4, !dbg !105
// CHECK:STDOUT:   %temp1 = alloca i32, align 4, !dbg !108
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !95
// CHECK:STDOUT:   %2 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !98
// CHECK:STDOUT:   %3 = icmp ne i1 %1, %2, !dbg !95
// CHECK:STDOUT:   br i1 %3, label %4, label %5, !dbg !99
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 false, !dbg !100
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %0
// CHECK:STDOUT:   %6 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !101
// CHECK:STDOUT:   %7 = xor i1 %6, true, !dbg !102
// CHECK:STDOUT:   br i1 %7, label %8, label %9, !dbg !103
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %5
// CHECK:STDOUT:   ret i1 true, !dbg !104
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %5
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !105
// CHECK:STDOUT:   %10 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %self), !dbg !105
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !108
// CHECK:STDOUT:   %11 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %other), !dbg !108
// CHECK:STDOUT:   store i32 %10, ptr %temp, align 4, !dbg !105
// CHECK:STDOUT:   %12 = load i32, ptr %temp, align 4, !dbg !105
// CHECK:STDOUT:   store i32 %11, ptr %temp1, align 4, !dbg !108
// CHECK:STDOUT:   %13 = load i32, ptr %temp1, align 4, !dbg !108
// CHECK:STDOUT:   %14 = icmp eq i32 %12, %13, !dbg !105
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp1), !dbg !108
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp), !dbg !105
// CHECK:STDOUT:   ret i1 %14, !dbg !109
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CNotEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9"(ptr %self, ptr %other) #0 !dbg !111 {
// CHECK:STDOUT:   %temp = alloca i32, align 4, !dbg !126
// CHECK:STDOUT:   %temp1 = alloca i32, align 4, !dbg !127
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !118
// CHECK:STDOUT:   %2 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !119
// CHECK:STDOUT:   %3 = icmp ne i1 %1, %2, !dbg !118
// CHECK:STDOUT:   br i1 %3, label %4, label %5, !dbg !120
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 true, !dbg !121
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %0
// CHECK:STDOUT:   %6 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !122
// CHECK:STDOUT:   %7 = xor i1 %6, true, !dbg !123
// CHECK:STDOUT:   br i1 %7, label %8, label %9, !dbg !124
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %5
// CHECK:STDOUT:   ret i1 false, !dbg !125
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %5
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !126
// CHECK:STDOUT:   %10 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %self), !dbg !126
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !127
// CHECK:STDOUT:   %11 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %other), !dbg !127
// CHECK:STDOUT:   store i32 %10, ptr %temp, align 4, !dbg !126
// CHECK:STDOUT:   %12 = load i32, ptr %temp, align 4, !dbg !126
// CHECK:STDOUT:   store i32 %11, ptr %temp1, align 4, !dbg !127
// CHECK:STDOUT:   %13 = load i32, ptr %temp1, align 4, !dbg !127
// CHECK:STDOUT:   %14 = icmp ne i32 %12, %13, !dbg !126
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp1), !dbg !127
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp), !dbg !126
// CHECK:STDOUT:   ret i1 %14, !dbg !128
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CLess.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %self, ptr %other) #0 !dbg !130 {
// CHECK:STDOUT:   %temp = alloca i32, align 4, !dbg !145
// CHECK:STDOUT:   %temp1 = alloca i32, align 4, !dbg !146
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !137
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !138
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !139
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 false, !dbg !140
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %5 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !141
// CHECK:STDOUT:   %6 = xor i1 %5, true, !dbg !142
// CHECK:STDOUT:   br i1 %6, label %7, label %8, !dbg !143
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %4
// CHECK:STDOUT:   ret i1 true, !dbg !144
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %4
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !145
// CHECK:STDOUT:   %9 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %self), !dbg !145
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !146
// CHECK:STDOUT:   %10 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %other), !dbg !146
// CHECK:STDOUT:   store i32 %9, ptr %temp, align 4, !dbg !145
// CHECK:STDOUT:   %11 = load i32, ptr %temp, align 4, !dbg !145
// CHECK:STDOUT:   store i32 %10, ptr %temp1, align 4, !dbg !146
// CHECK:STDOUT:   %12 = load i32, ptr %temp1, align 4, !dbg !146
// CHECK:STDOUT:   %13 = icmp slt i32 %11, %12, !dbg !145
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp1), !dbg !146
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp), !dbg !145
// CHECK:STDOUT:   ret i1 %13, !dbg !147
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CLessOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %self, ptr %other) #0 !dbg !149 {
// CHECK:STDOUT:   %temp = alloca i32, align 4, !dbg !164
// CHECK:STDOUT:   %temp1 = alloca i32, align 4, !dbg !165
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !156
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !157
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !158
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 true, !dbg !159
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %5 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !160
// CHECK:STDOUT:   %6 = xor i1 %5, true, !dbg !161
// CHECK:STDOUT:   br i1 %6, label %7, label %8, !dbg !162
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %4
// CHECK:STDOUT:   ret i1 false, !dbg !163
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %4
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !164
// CHECK:STDOUT:   %9 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %self), !dbg !164
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !165
// CHECK:STDOUT:   %10 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %other), !dbg !165
// CHECK:STDOUT:   store i32 %9, ptr %temp, align 4, !dbg !164
// CHECK:STDOUT:   %11 = load i32, ptr %temp, align 4, !dbg !164
// CHECK:STDOUT:   store i32 %10, ptr %temp1, align 4, !dbg !165
// CHECK:STDOUT:   %12 = load i32, ptr %temp1, align 4, !dbg !165
// CHECK:STDOUT:   %13 = icmp sle i32 %11, %12, !dbg !164
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp1), !dbg !165
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp), !dbg !164
// CHECK:STDOUT:   ret i1 %13, !dbg !166
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CGreater.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %self, ptr %other) #0 !dbg !168 {
// CHECK:STDOUT:   %temp = alloca i32, align 4, !dbg !183
// CHECK:STDOUT:   %temp1 = alloca i32, align 4, !dbg !184
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !175
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !176
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !177
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 false, !dbg !178
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %5 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !179
// CHECK:STDOUT:   %6 = xor i1 %5, true, !dbg !180
// CHECK:STDOUT:   br i1 %6, label %7, label %8, !dbg !181
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %4
// CHECK:STDOUT:   ret i1 true, !dbg !182
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %4
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !183
// CHECK:STDOUT:   %9 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %self), !dbg !183
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !184
// CHECK:STDOUT:   %10 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %other), !dbg !184
// CHECK:STDOUT:   store i32 %9, ptr %temp, align 4, !dbg !183
// CHECK:STDOUT:   %11 = load i32, ptr %temp, align 4, !dbg !183
// CHECK:STDOUT:   store i32 %10, ptr %temp1, align 4, !dbg !184
// CHECK:STDOUT:   %12 = load i32, ptr %temp1, align 4, !dbg !184
// CHECK:STDOUT:   %13 = icmp sgt i32 %11, %12, !dbg !183
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp1), !dbg !184
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp), !dbg !183
// CHECK:STDOUT:   ret i1 %13, !dbg !185
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CGreaterOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %self, ptr %other) #0 !dbg !187 {
// CHECK:STDOUT:   %temp = alloca i32, align 4, !dbg !202
// CHECK:STDOUT:   %temp1 = alloca i32, align 4, !dbg !203
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !194
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !195
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !196
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 true, !dbg !197
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %5 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !198
// CHECK:STDOUT:   %6 = xor i1 %5, true, !dbg !199
// CHECK:STDOUT:   br i1 %6, label %7, label %8, !dbg !200
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %4
// CHECK:STDOUT:   ret i1 false, !dbg !201
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %4
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !202
// CHECK:STDOUT:   %9 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %self), !dbg !202
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !203
// CHECK:STDOUT:   %10 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %other), !dbg !203
// CHECK:STDOUT:   store i32 %9, ptr %temp, align 4, !dbg !202
// CHECK:STDOUT:   %11 = load i32, ptr %temp, align 4, !dbg !202
// CHECK:STDOUT:   store i32 %10, ptr %temp1, align 4, !dbg !203
// CHECK:STDOUT:   %12 = load i32, ptr %temp1, align 4, !dbg !203
// CHECK:STDOUT:   %13 = icmp sge i32 %11, %12, !dbg !202
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp1), !dbg !203
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp), !dbg !202
// CHECK:STDOUT:   ret i1 %13, !dbg !204
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self) #0 !dbg !206 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %self), !dbg !212
// CHECK:STDOUT:   ret i1 %1, !dbg !213
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %self) #0 !dbg !215 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !220
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !221
// CHECK:STDOUT:   br i1 %2, label %3, label %5, !dbg !222
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon, align 8, !dbg !223
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !223
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !223
// CHECK:STDOUT:   %4 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !223
// CHECK:STDOUT:   call void @abort(), !dbg !223
// CHECK:STDOUT:   br label %5, !dbg !224
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %3, %0
// CHECK:STDOUT:   %6 = call i32 @"_CGet.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %self), !dbg !226
// CHECK:STDOUT:   ret i32 %6, !dbg !227
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %value) #0 !dbg !229 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %value, i32 0, i32 1, !dbg !234
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !234
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !234
// CHECK:STDOUT:   ret i1 %2, !dbg !235
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noreturn
// CHECK:STDOUT: declare void @abort() #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CGet.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %value) #0 !dbg !237 {
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %value, i32 0, i32 0, !dbg !242
// CHECK:STDOUT:   %1 = load i32, ptr %value1, align 4, !dbg !242
// CHECK:STDOUT:   ret i32 %1, !dbg !243
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CHasValue.Optional.Core.3530343734a6ea27, { 0, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CGet.Optional.Core.3530343734a6ea27, { 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #2 = { noreturn }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "compare.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{null, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!9, !9, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 17, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !15)
// CHECK:STDOUT: !13 = !DILocalVariable(arg: 1, scope: !12, type: !6)
// CHECK:STDOUT: !14 = !DILocation(line: 17, column: 12, scope: !12)
// CHECK:STDOUT: !15 = !{!13}
// CHECK:STDOUT: !16 = distinct !DISubprogram(name: "IsEq", linkageName: "_CIsEq.Main", scope: null, file: !4, line: 17, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !26)
// CHECK:STDOUT: !17 = !DILocalVariable(arg: 1, scope: !16, type: !9)
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 2, scope: !16, type: !9)
// CHECK:STDOUT: !23 = !DILocation(line: 17, column: 72, scope: !16)
// CHECK:STDOUT: !25 = !DILocation(line: 17, column: 65, scope: !16)
// CHECK:STDOUT: !26 = !{!17, !18}
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "IsNe", linkageName: "_CIsNe.Main", scope: null, file: !4, line: 18, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !37)
// CHECK:STDOUT: !28 = !DILocalVariable(arg: 1, scope: !27, type: !9)
// CHECK:STDOUT: !29 = !DILocalVariable(arg: 2, scope: !27, type: !9)
// CHECK:STDOUT: !34 = !DILocation(line: 18, column: 72, scope: !27)
// CHECK:STDOUT: !36 = !DILocation(line: 18, column: 65, scope: !27)
// CHECK:STDOUT: !37 = !{!28, !29}
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "IsLt", linkageName: "_CIsLt.Main", scope: null, file: !4, line: 19, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !48)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !38, type: !9)
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 2, scope: !38, type: !9)
// CHECK:STDOUT: !45 = !DILocation(line: 19, column: 72, scope: !38)
// CHECK:STDOUT: !47 = !DILocation(line: 19, column: 65, scope: !38)
// CHECK:STDOUT: !48 = !{!39, !40}
// CHECK:STDOUT: !49 = distinct !DISubprogram(name: "IsLe", linkageName: "_CIsLe.Main", scope: null, file: !4, line: 20, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !59)
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !49, type: !9)
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 2, scope: !49, type: !9)
// CHECK:STDOUT: !56 = !DILocation(line: 20, column: 72, scope: !49)
// CHECK:STDOUT: !58 = !DILocation(line: 20, column: 65, scope: !49)
// CHECK:STDOUT: !59 = !{!50, !51}
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "IsGt", linkageName: "_CIsGt.Main", scope: null, file: !4, line: 21, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !70)
// CHECK:STDOUT: !61 = !DILocalVariable(arg: 1, scope: !60, type: !9)
// CHECK:STDOUT: !62 = !DILocalVariable(arg: 2, scope: !60, type: !9)
// CHECK:STDOUT: !67 = !DILocation(line: 21, column: 72, scope: !60)
// CHECK:STDOUT: !69 = !DILocation(line: 21, column: 65, scope: !60)
// CHECK:STDOUT: !70 = !{!61, !62}
// CHECK:STDOUT: !71 = distinct !DISubprogram(name: "IsGe", linkageName: "_CIsGe.Main", scope: null, file: !4, line: 22, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !81)
// CHECK:STDOUT: !72 = !DILocalVariable(arg: 1, scope: !71, type: !9)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 2, scope: !71, type: !9)
// CHECK:STDOUT: !78 = !DILocation(line: 22, column: 72, scope: !71)
// CHECK:STDOUT: !80 = !DILocation(line: 22, column: 65, scope: !71)
// CHECK:STDOUT: !81 = !{!72, !73}
// CHECK:STDOUT: !87 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !88 = distinct !DISubprogram(name: "Equal", linkageName: "_CEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9", scope: null, file: !87, line: 217, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !110)
// CHECK:STDOUT: !89 = !DILocalVariable(arg: 1, scope: !88, type: !9)
// CHECK:STDOUT: !90 = !DILocalVariable(arg: 2, scope: !88, type: !9)
// CHECK:STDOUT: !95 = !DILocation(line: 218, column: 9, scope: !88)
// CHECK:STDOUT: !96 = !{!9, !9}
// CHECK:STDOUT: !97 = !DISubroutineType(types: !96)
// CHECK:STDOUT: !98 = !DILocation(line: 218, column: 28, scope: !88)
// CHECK:STDOUT: !99 = !DILocation(line: 218, column: 8, scope: !88)
// CHECK:STDOUT: !100 = !DILocation(line: 219, column: 7, scope: !88)
// CHECK:STDOUT: !101 = !DILocation(line: 221, column: 13, scope: !88)
// CHECK:STDOUT: !102 = !DILocation(line: 221, column: 9, scope: !88)
// CHECK:STDOUT: !103 = !DILocation(line: 221, column: 8, scope: !88)
// CHECK:STDOUT: !104 = !DILocation(line: 222, column: 7, scope: !88)
// CHECK:STDOUT: !105 = !DILocation(line: 224, column: 12, scope: !88)
// CHECK:STDOUT: !106 = !{!6, !9}
// CHECK:STDOUT: !107 = !DISubroutineType(types: !106)
// CHECK:STDOUT: !108 = !DILocation(line: 224, column: 26, scope: !88)
// CHECK:STDOUT: !109 = !DILocation(line: 224, column: 5, scope: !88)
// CHECK:STDOUT: !110 = !{!89, !90}
// CHECK:STDOUT: !111 = distinct !DISubprogram(name: "NotEqual", linkageName: "_CNotEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9", scope: null, file: !87, line: 226, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !129)
// CHECK:STDOUT: !112 = !DILocalVariable(arg: 1, scope: !111, type: !9)
// CHECK:STDOUT: !113 = !DILocalVariable(arg: 2, scope: !111, type: !9)
// CHECK:STDOUT: !118 = !DILocation(line: 227, column: 9, scope: !111)
// CHECK:STDOUT: !119 = !DILocation(line: 227, column: 28, scope: !111)
// CHECK:STDOUT: !120 = !DILocation(line: 227, column: 8, scope: !111)
// CHECK:STDOUT: !121 = !DILocation(line: 228, column: 7, scope: !111)
// CHECK:STDOUT: !122 = !DILocation(line: 230, column: 13, scope: !111)
// CHECK:STDOUT: !123 = !DILocation(line: 230, column: 9, scope: !111)
// CHECK:STDOUT: !124 = !DILocation(line: 230, column: 8, scope: !111)
// CHECK:STDOUT: !125 = !DILocation(line: 231, column: 7, scope: !111)
// CHECK:STDOUT: !126 = !DILocation(line: 233, column: 12, scope: !111)
// CHECK:STDOUT: !127 = !DILocation(line: 233, column: 26, scope: !111)
// CHECK:STDOUT: !128 = !DILocation(line: 233, column: 5, scope: !111)
// CHECK:STDOUT: !129 = !{!112, !113}
// CHECK:STDOUT: !130 = distinct !DISubprogram(name: "Less", linkageName: "_CLess.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd", scope: null, file: !87, line: 239, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !148)
// CHECK:STDOUT: !131 = !DILocalVariable(arg: 1, scope: !130, type: !9)
// CHECK:STDOUT: !132 = !DILocalVariable(arg: 2, scope: !130, type: !9)
// CHECK:STDOUT: !137 = !DILocation(line: 240, column: 13, scope: !130)
// CHECK:STDOUT: !138 = !DILocation(line: 240, column: 9, scope: !130)
// CHECK:STDOUT: !139 = !DILocation(line: 240, column: 8, scope: !130)
// CHECK:STDOUT: !140 = !DILocation(line: 241, column: 7, scope: !130)
// CHECK:STDOUT: !141 = !DILocation(line: 243, column: 13, scope: !130)
// CHECK:STDOUT: !142 = !DILocation(line: 243, column: 9, scope: !130)
// CHECK:STDOUT: !143 = !DILocation(line: 243, column: 8, scope: !130)
// CHECK:STDOUT: !144 = !DILocation(line: 244, column: 7, scope: !130)
// CHECK:STDOUT: !145 = !DILocation(line: 246, column: 12, scope: !130)
// CHECK:STDOUT: !146 = !DILocation(line: 246, column: 25, scope: !130)
// CHECK:STDOUT: !147 = !DILocation(line: 246, column: 5, scope: !130)
// CHECK:STDOUT: !148 = !{!131, !132}
// CHECK:STDOUT: !149 = distinct !DISubprogram(name: "LessOrEquivalent", linkageName: "_CLessOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd", scope: null, file: !87, line: 248, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !167)
// CHECK:STDOUT: !150 = !DILocalVariable(arg: 1, scope: !149, type: !9)
// CHECK:STDOUT: !151 = !DILocalVariable(arg: 2, scope: !149, type: !9)
// CHECK:STDOUT: !156 = !DILocation(line: 249, column: 13, scope: !149)
// CHECK:STDOUT: !157 = !DILocation(line: 249, column: 9, scope: !149)
// CHECK:STDOUT: !158 = !DILocation(line: 249, column: 8, scope: !149)
// CHECK:STDOUT: !159 = !DILocation(line: 250, column: 7, scope: !149)
// CHECK:STDOUT: !160 = !DILocation(line: 252, column: 13, scope: !149)
// CHECK:STDOUT: !161 = !DILocation(line: 252, column: 9, scope: !149)
// CHECK:STDOUT: !162 = !DILocation(line: 252, column: 8, scope: !149)
// CHECK:STDOUT: !163 = !DILocation(line: 253, column: 7, scope: !149)
// CHECK:STDOUT: !164 = !DILocation(line: 255, column: 12, scope: !149)
// CHECK:STDOUT: !165 = !DILocation(line: 255, column: 26, scope: !149)
// CHECK:STDOUT: !166 = !DILocation(line: 255, column: 5, scope: !149)
// CHECK:STDOUT: !167 = !{!150, !151}
// CHECK:STDOUT: !168 = distinct !DISubprogram(name: "Greater", linkageName: "_CGreater.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd", scope: null, file: !87, line: 257, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !186)
// CHECK:STDOUT: !169 = !DILocalVariable(arg: 1, scope: !168, type: !9)
// CHECK:STDOUT: !170 = !DILocalVariable(arg: 2, scope: !168, type: !9)
// CHECK:STDOUT: !175 = !DILocation(line: 258, column: 13, scope: !168)
// CHECK:STDOUT: !176 = !DILocation(line: 258, column: 9, scope: !168)
// CHECK:STDOUT: !177 = !DILocation(line: 258, column: 8, scope: !168)
// CHECK:STDOUT: !178 = !DILocation(line: 259, column: 7, scope: !168)
// CHECK:STDOUT: !179 = !DILocation(line: 261, column: 13, scope: !168)
// CHECK:STDOUT: !180 = !DILocation(line: 261, column: 9, scope: !168)
// CHECK:STDOUT: !181 = !DILocation(line: 261, column: 8, scope: !168)
// CHECK:STDOUT: !182 = !DILocation(line: 262, column: 7, scope: !168)
// CHECK:STDOUT: !183 = !DILocation(line: 264, column: 12, scope: !168)
// CHECK:STDOUT: !184 = !DILocation(line: 264, column: 25, scope: !168)
// CHECK:STDOUT: !185 = !DILocation(line: 264, column: 5, scope: !168)
// CHECK:STDOUT: !186 = !{!169, !170}
// CHECK:STDOUT: !187 = distinct !DISubprogram(name: "GreaterOrEquivalent", linkageName: "_CGreaterOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd", scope: null, file: !87, line: 266, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !205)
// CHECK:STDOUT: !188 = !DILocalVariable(arg: 1, scope: !187, type: !9)
// CHECK:STDOUT: !189 = !DILocalVariable(arg: 2, scope: !187, type: !9)
// CHECK:STDOUT: !194 = !DILocation(line: 267, column: 13, scope: !187)
// CHECK:STDOUT: !195 = !DILocation(line: 267, column: 9, scope: !187)
// CHECK:STDOUT: !196 = !DILocation(line: 267, column: 8, scope: !187)
// CHECK:STDOUT: !197 = !DILocation(line: 268, column: 7, scope: !187)
// CHECK:STDOUT: !198 = !DILocation(line: 270, column: 13, scope: !187)
// CHECK:STDOUT: !199 = !DILocation(line: 270, column: 9, scope: !187)
// CHECK:STDOUT: !200 = !DILocation(line: 270, column: 8, scope: !187)
// CHECK:STDOUT: !201 = !DILocation(line: 271, column: 7, scope: !187)
// CHECK:STDOUT: !202 = !DILocation(line: 273, column: 12, scope: !187)
// CHECK:STDOUT: !203 = !DILocation(line: 273, column: 26, scope: !187)
// CHECK:STDOUT: !204 = !DILocation(line: 273, column: 5, scope: !187)
// CHECK:STDOUT: !205 = !{!188, !189}
// CHECK:STDOUT: !206 = distinct !DISubprogram(name: "HasValue", linkageName: "_CHasValue.Optional.Core.3530343734a6ea27", scope: null, file: !87, line: 37, type: !97, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !214)
// CHECK:STDOUT: !207 = !DILocalVariable(arg: 1, scope: !206, type: !9)
// CHECK:STDOUT: !212 = !DILocation(line: 38, column: 12, scope: !206)
// CHECK:STDOUT: !213 = !DILocation(line: 38, column: 5, scope: !206)
// CHECK:STDOUT: !214 = !{!207}
// CHECK:STDOUT: !215 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Optional.Core.3530343734a6ea27", scope: null, file: !87, line: 40, type: !107, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !228)
// CHECK:STDOUT: !216 = !DILocalVariable(arg: 1, scope: !215, type: !9)
// CHECK:STDOUT: !220 = !DILocation(line: 303, column: 11, scope: !215)
// CHECK:STDOUT: !221 = !DILocation(line: 303, column: 7, scope: !215)
// CHECK:STDOUT: !222 = !DILocation(line: 303, column: 6, scope: !215)
// CHECK:STDOUT: !223 = !DILocation(line: 304, column: 5, scope: !215)
// CHECK:STDOUT: !224 = !DILocation(line: 303, column: 3, scope: !215)
// CHECK:STDOUT: !226 = !DILocation(line: 306, column: 10, scope: !215)
// CHECK:STDOUT: !227 = !DILocation(line: 306, column: 3, scope: !215)
// CHECK:STDOUT: !228 = !{!216}
// CHECK:STDOUT: !229 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc", scope: null, file: !87, line: 166, type: !97, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !236)
// CHECK:STDOUT: !230 = !DILocalVariable(arg: 1, scope: !229, type: !9)
// CHECK:STDOUT: !234 = !DILocation(line: 167, column: 12, scope: !229)
// CHECK:STDOUT: !235 = !DILocation(line: 167, column: 5, scope: !229)
// CHECK:STDOUT: !236 = !{!230}
// CHECK:STDOUT: !237 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc", scope: null, file: !87, line: 169, type: !107, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !244)
// CHECK:STDOUT: !238 = !DILocalVariable(arg: 1, scope: !237, type: !9)
// CHECK:STDOUT: !242 = !DILocation(line: 170, column: 12, scope: !237)
// CHECK:STDOUT: !243 = !DILocation(line: 170, column: 5, scope: !237)
// CHECK:STDOUT: !244 = !{!238}
// CHECK:STDOUT:

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
// CHECK:STDOUT: define linkonce_odr i1 @"_CEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9"(ptr %self, ptr %other) #0 !dbg !84 {
// CHECK:STDOUT:   %temp = alloca i32, align 4, !dbg !101
// CHECK:STDOUT:   %temp1 = alloca i32, align 4, !dbg !104
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !91
// CHECK:STDOUT:   %2 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !94
// CHECK:STDOUT:   %3 = icmp ne i1 %1, %2, !dbg !91
// CHECK:STDOUT:   br i1 %3, label %4, label %5, !dbg !95
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 false, !dbg !96
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %0
// CHECK:STDOUT:   %6 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !97
// CHECK:STDOUT:   %7 = xor i1 %6, true, !dbg !98
// CHECK:STDOUT:   br i1 %7, label %8, label %9, !dbg !99
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %5
// CHECK:STDOUT:   ret i1 true, !dbg !100
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %5
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !101
// CHECK:STDOUT:   %10 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %self), !dbg !101
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !104
// CHECK:STDOUT:   %11 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %other), !dbg !104
// CHECK:STDOUT:   store i32 %10, ptr %temp, align 4, !dbg !101
// CHECK:STDOUT:   %12 = load i32, ptr %temp, align 4, !dbg !101
// CHECK:STDOUT:   store i32 %11, ptr %temp1, align 4, !dbg !104
// CHECK:STDOUT:   %13 = load i32, ptr %temp1, align 4, !dbg !104
// CHECK:STDOUT:   %14 = icmp eq i32 %12, %13, !dbg !101
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp1), !dbg !104
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp), !dbg !101
// CHECK:STDOUT:   ret i1 %14, !dbg !105
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CNotEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9"(ptr %self, ptr %other) #0 !dbg !107 {
// CHECK:STDOUT:   %temp = alloca i32, align 4, !dbg !122
// CHECK:STDOUT:   %temp1 = alloca i32, align 4, !dbg !123
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !114
// CHECK:STDOUT:   %2 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !115
// CHECK:STDOUT:   %3 = icmp ne i1 %1, %2, !dbg !114
// CHECK:STDOUT:   br i1 %3, label %4, label %5, !dbg !116
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 true, !dbg !117
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %0
// CHECK:STDOUT:   %6 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !118
// CHECK:STDOUT:   %7 = xor i1 %6, true, !dbg !119
// CHECK:STDOUT:   br i1 %7, label %8, label %9, !dbg !120
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %5
// CHECK:STDOUT:   ret i1 false, !dbg !121
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %5
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !122
// CHECK:STDOUT:   %10 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %self), !dbg !122
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !123
// CHECK:STDOUT:   %11 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %other), !dbg !123
// CHECK:STDOUT:   store i32 %10, ptr %temp, align 4, !dbg !122
// CHECK:STDOUT:   %12 = load i32, ptr %temp, align 4, !dbg !122
// CHECK:STDOUT:   store i32 %11, ptr %temp1, align 4, !dbg !123
// CHECK:STDOUT:   %13 = load i32, ptr %temp1, align 4, !dbg !123
// CHECK:STDOUT:   %14 = icmp ne i32 %12, %13, !dbg !122
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp1), !dbg !123
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp), !dbg !122
// CHECK:STDOUT:   ret i1 %14, !dbg !124
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CLess.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %self, ptr %other) #0 !dbg !126 {
// CHECK:STDOUT:   %temp = alloca i32, align 4, !dbg !141
// CHECK:STDOUT:   %temp1 = alloca i32, align 4, !dbg !142
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !133
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !134
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !135
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 false, !dbg !136
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %5 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !137
// CHECK:STDOUT:   %6 = xor i1 %5, true, !dbg !138
// CHECK:STDOUT:   br i1 %6, label %7, label %8, !dbg !139
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %4
// CHECK:STDOUT:   ret i1 true, !dbg !140
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %4
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !141
// CHECK:STDOUT:   %9 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %self), !dbg !141
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !142
// CHECK:STDOUT:   %10 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %other), !dbg !142
// CHECK:STDOUT:   store i32 %9, ptr %temp, align 4, !dbg !141
// CHECK:STDOUT:   %11 = load i32, ptr %temp, align 4, !dbg !141
// CHECK:STDOUT:   store i32 %10, ptr %temp1, align 4, !dbg !142
// CHECK:STDOUT:   %12 = load i32, ptr %temp1, align 4, !dbg !142
// CHECK:STDOUT:   %13 = icmp slt i32 %11, %12, !dbg !141
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp1), !dbg !142
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp), !dbg !141
// CHECK:STDOUT:   ret i1 %13, !dbg !143
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CLessOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %self, ptr %other) #0 !dbg !145 {
// CHECK:STDOUT:   %temp = alloca i32, align 4, !dbg !160
// CHECK:STDOUT:   %temp1 = alloca i32, align 4, !dbg !161
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !152
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !153
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !154
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 true, !dbg !155
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %5 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !156
// CHECK:STDOUT:   %6 = xor i1 %5, true, !dbg !157
// CHECK:STDOUT:   br i1 %6, label %7, label %8, !dbg !158
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %4
// CHECK:STDOUT:   ret i1 false, !dbg !159
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %4
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !160
// CHECK:STDOUT:   %9 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %self), !dbg !160
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !161
// CHECK:STDOUT:   %10 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %other), !dbg !161
// CHECK:STDOUT:   store i32 %9, ptr %temp, align 4, !dbg !160
// CHECK:STDOUT:   %11 = load i32, ptr %temp, align 4, !dbg !160
// CHECK:STDOUT:   store i32 %10, ptr %temp1, align 4, !dbg !161
// CHECK:STDOUT:   %12 = load i32, ptr %temp1, align 4, !dbg !161
// CHECK:STDOUT:   %13 = icmp sle i32 %11, %12, !dbg !160
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp1), !dbg !161
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp), !dbg !160
// CHECK:STDOUT:   ret i1 %13, !dbg !162
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CGreater.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %self, ptr %other) #0 !dbg !164 {
// CHECK:STDOUT:   %temp = alloca i32, align 4, !dbg !179
// CHECK:STDOUT:   %temp1 = alloca i32, align 4, !dbg !180
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !171
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !172
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !173
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 false, !dbg !174
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %5 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !175
// CHECK:STDOUT:   %6 = xor i1 %5, true, !dbg !176
// CHECK:STDOUT:   br i1 %6, label %7, label %8, !dbg !177
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %4
// CHECK:STDOUT:   ret i1 true, !dbg !178
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %4
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !179
// CHECK:STDOUT:   %9 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %self), !dbg !179
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !180
// CHECK:STDOUT:   %10 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %other), !dbg !180
// CHECK:STDOUT:   store i32 %9, ptr %temp, align 4, !dbg !179
// CHECK:STDOUT:   %11 = load i32, ptr %temp, align 4, !dbg !179
// CHECK:STDOUT:   store i32 %10, ptr %temp1, align 4, !dbg !180
// CHECK:STDOUT:   %12 = load i32, ptr %temp1, align 4, !dbg !180
// CHECK:STDOUT:   %13 = icmp sgt i32 %11, %12, !dbg !179
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp1), !dbg !180
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp), !dbg !179
// CHECK:STDOUT:   ret i1 %13, !dbg !181
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CGreaterOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %self, ptr %other) #0 !dbg !183 {
// CHECK:STDOUT:   %temp = alloca i32, align 4, !dbg !198
// CHECK:STDOUT:   %temp1 = alloca i32, align 4, !dbg !199
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !190
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !191
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !192
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 true, !dbg !193
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %5 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !194
// CHECK:STDOUT:   %6 = xor i1 %5, true, !dbg !195
// CHECK:STDOUT:   br i1 %6, label %7, label %8, !dbg !196
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %4
// CHECK:STDOUT:   ret i1 false, !dbg !197
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %4
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !198
// CHECK:STDOUT:   %9 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %self), !dbg !198
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !199
// CHECK:STDOUT:   %10 = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %other), !dbg !199
// CHECK:STDOUT:   store i32 %9, ptr %temp, align 4, !dbg !198
// CHECK:STDOUT:   %11 = load i32, ptr %temp, align 4, !dbg !198
// CHECK:STDOUT:   store i32 %10, ptr %temp1, align 4, !dbg !199
// CHECK:STDOUT:   %12 = load i32, ptr %temp1, align 4, !dbg !199
// CHECK:STDOUT:   %13 = icmp sge i32 %11, %12, !dbg !198
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp1), !dbg !199
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp), !dbg !198
// CHECK:STDOUT:   ret i1 %13, !dbg !200
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self) #0 !dbg !202 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %self), !dbg !208
// CHECK:STDOUT:   ret i1 %1, !dbg !209
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %self) #0 !dbg !211 {
// CHECK:STDOUT:   %1 = call i32 @"_CGet.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %self), !dbg !217
// CHECK:STDOUT:   ret i32 %1, !dbg !218
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %value) #0 !dbg !220 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %value, i32 0, i32 1, !dbg !225
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !225
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !225
// CHECK:STDOUT:   ret i1 %2, !dbg !226
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CGet.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %value) #0 !dbg !228 {
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %value, i32 0, i32 0, !dbg !233
// CHECK:STDOUT:   %1 = load i32, ptr %value1, align 4, !dbg !233
// CHECK:STDOUT:   ret i32 %1, !dbg !234
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CHasValue.Optional.Core.3530343734a6ea27, { 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CGet.Optional.Core.3530343734a6ea27, { 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
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
// CHECK:STDOUT: !83 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "Equal", linkageName: "_CEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9", scope: null, file: !83, line: 217, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !106)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !84, type: !9)
// CHECK:STDOUT: !86 = !DILocalVariable(arg: 2, scope: !84, type: !9)
// CHECK:STDOUT: !91 = !DILocation(line: 218, column: 9, scope: !84)
// CHECK:STDOUT: !92 = !{!9, !9}
// CHECK:STDOUT: !93 = !DISubroutineType(types: !92)
// CHECK:STDOUT: !94 = !DILocation(line: 218, column: 28, scope: !84)
// CHECK:STDOUT: !95 = !DILocation(line: 218, column: 8, scope: !84)
// CHECK:STDOUT: !96 = !DILocation(line: 219, column: 7, scope: !84)
// CHECK:STDOUT: !97 = !DILocation(line: 221, column: 13, scope: !84)
// CHECK:STDOUT: !98 = !DILocation(line: 221, column: 9, scope: !84)
// CHECK:STDOUT: !99 = !DILocation(line: 221, column: 8, scope: !84)
// CHECK:STDOUT: !100 = !DILocation(line: 222, column: 7, scope: !84)
// CHECK:STDOUT: !101 = !DILocation(line: 224, column: 12, scope: !84)
// CHECK:STDOUT: !102 = !{!6, !9}
// CHECK:STDOUT: !103 = !DISubroutineType(types: !102)
// CHECK:STDOUT: !104 = !DILocation(line: 224, column: 26, scope: !84)
// CHECK:STDOUT: !105 = !DILocation(line: 224, column: 5, scope: !84)
// CHECK:STDOUT: !106 = !{!85, !86}
// CHECK:STDOUT: !107 = distinct !DISubprogram(name: "NotEqual", linkageName: "_CNotEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9", scope: null, file: !83, line: 226, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !125)
// CHECK:STDOUT: !108 = !DILocalVariable(arg: 1, scope: !107, type: !9)
// CHECK:STDOUT: !109 = !DILocalVariable(arg: 2, scope: !107, type: !9)
// CHECK:STDOUT: !114 = !DILocation(line: 227, column: 9, scope: !107)
// CHECK:STDOUT: !115 = !DILocation(line: 227, column: 28, scope: !107)
// CHECK:STDOUT: !116 = !DILocation(line: 227, column: 8, scope: !107)
// CHECK:STDOUT: !117 = !DILocation(line: 228, column: 7, scope: !107)
// CHECK:STDOUT: !118 = !DILocation(line: 230, column: 13, scope: !107)
// CHECK:STDOUT: !119 = !DILocation(line: 230, column: 9, scope: !107)
// CHECK:STDOUT: !120 = !DILocation(line: 230, column: 8, scope: !107)
// CHECK:STDOUT: !121 = !DILocation(line: 231, column: 7, scope: !107)
// CHECK:STDOUT: !122 = !DILocation(line: 233, column: 12, scope: !107)
// CHECK:STDOUT: !123 = !DILocation(line: 233, column: 26, scope: !107)
// CHECK:STDOUT: !124 = !DILocation(line: 233, column: 5, scope: !107)
// CHECK:STDOUT: !125 = !{!108, !109}
// CHECK:STDOUT: !126 = distinct !DISubprogram(name: "Less", linkageName: "_CLess.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd", scope: null, file: !83, line: 239, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !144)
// CHECK:STDOUT: !127 = !DILocalVariable(arg: 1, scope: !126, type: !9)
// CHECK:STDOUT: !128 = !DILocalVariable(arg: 2, scope: !126, type: !9)
// CHECK:STDOUT: !133 = !DILocation(line: 240, column: 13, scope: !126)
// CHECK:STDOUT: !134 = !DILocation(line: 240, column: 9, scope: !126)
// CHECK:STDOUT: !135 = !DILocation(line: 240, column: 8, scope: !126)
// CHECK:STDOUT: !136 = !DILocation(line: 241, column: 7, scope: !126)
// CHECK:STDOUT: !137 = !DILocation(line: 243, column: 13, scope: !126)
// CHECK:STDOUT: !138 = !DILocation(line: 243, column: 9, scope: !126)
// CHECK:STDOUT: !139 = !DILocation(line: 243, column: 8, scope: !126)
// CHECK:STDOUT: !140 = !DILocation(line: 244, column: 7, scope: !126)
// CHECK:STDOUT: !141 = !DILocation(line: 246, column: 12, scope: !126)
// CHECK:STDOUT: !142 = !DILocation(line: 246, column: 25, scope: !126)
// CHECK:STDOUT: !143 = !DILocation(line: 246, column: 5, scope: !126)
// CHECK:STDOUT: !144 = !{!127, !128}
// CHECK:STDOUT: !145 = distinct !DISubprogram(name: "LessOrEquivalent", linkageName: "_CLessOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd", scope: null, file: !83, line: 248, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !163)
// CHECK:STDOUT: !146 = !DILocalVariable(arg: 1, scope: !145, type: !9)
// CHECK:STDOUT: !147 = !DILocalVariable(arg: 2, scope: !145, type: !9)
// CHECK:STDOUT: !152 = !DILocation(line: 249, column: 13, scope: !145)
// CHECK:STDOUT: !153 = !DILocation(line: 249, column: 9, scope: !145)
// CHECK:STDOUT: !154 = !DILocation(line: 249, column: 8, scope: !145)
// CHECK:STDOUT: !155 = !DILocation(line: 250, column: 7, scope: !145)
// CHECK:STDOUT: !156 = !DILocation(line: 252, column: 13, scope: !145)
// CHECK:STDOUT: !157 = !DILocation(line: 252, column: 9, scope: !145)
// CHECK:STDOUT: !158 = !DILocation(line: 252, column: 8, scope: !145)
// CHECK:STDOUT: !159 = !DILocation(line: 253, column: 7, scope: !145)
// CHECK:STDOUT: !160 = !DILocation(line: 255, column: 12, scope: !145)
// CHECK:STDOUT: !161 = !DILocation(line: 255, column: 26, scope: !145)
// CHECK:STDOUT: !162 = !DILocation(line: 255, column: 5, scope: !145)
// CHECK:STDOUT: !163 = !{!146, !147}
// CHECK:STDOUT: !164 = distinct !DISubprogram(name: "Greater", linkageName: "_CGreater.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd", scope: null, file: !83, line: 257, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !182)
// CHECK:STDOUT: !165 = !DILocalVariable(arg: 1, scope: !164, type: !9)
// CHECK:STDOUT: !166 = !DILocalVariable(arg: 2, scope: !164, type: !9)
// CHECK:STDOUT: !171 = !DILocation(line: 258, column: 13, scope: !164)
// CHECK:STDOUT: !172 = !DILocation(line: 258, column: 9, scope: !164)
// CHECK:STDOUT: !173 = !DILocation(line: 258, column: 8, scope: !164)
// CHECK:STDOUT: !174 = !DILocation(line: 259, column: 7, scope: !164)
// CHECK:STDOUT: !175 = !DILocation(line: 261, column: 13, scope: !164)
// CHECK:STDOUT: !176 = !DILocation(line: 261, column: 9, scope: !164)
// CHECK:STDOUT: !177 = !DILocation(line: 261, column: 8, scope: !164)
// CHECK:STDOUT: !178 = !DILocation(line: 262, column: 7, scope: !164)
// CHECK:STDOUT: !179 = !DILocation(line: 264, column: 12, scope: !164)
// CHECK:STDOUT: !180 = !DILocation(line: 264, column: 25, scope: !164)
// CHECK:STDOUT: !181 = !DILocation(line: 264, column: 5, scope: !164)
// CHECK:STDOUT: !182 = !{!165, !166}
// CHECK:STDOUT: !183 = distinct !DISubprogram(name: "GreaterOrEquivalent", linkageName: "_CGreaterOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd", scope: null, file: !83, line: 266, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !201)
// CHECK:STDOUT: !184 = !DILocalVariable(arg: 1, scope: !183, type: !9)
// CHECK:STDOUT: !185 = !DILocalVariable(arg: 2, scope: !183, type: !9)
// CHECK:STDOUT: !190 = !DILocation(line: 267, column: 13, scope: !183)
// CHECK:STDOUT: !191 = !DILocation(line: 267, column: 9, scope: !183)
// CHECK:STDOUT: !192 = !DILocation(line: 267, column: 8, scope: !183)
// CHECK:STDOUT: !193 = !DILocation(line: 268, column: 7, scope: !183)
// CHECK:STDOUT: !194 = !DILocation(line: 270, column: 13, scope: !183)
// CHECK:STDOUT: !195 = !DILocation(line: 270, column: 9, scope: !183)
// CHECK:STDOUT: !196 = !DILocation(line: 270, column: 8, scope: !183)
// CHECK:STDOUT: !197 = !DILocation(line: 271, column: 7, scope: !183)
// CHECK:STDOUT: !198 = !DILocation(line: 273, column: 12, scope: !183)
// CHECK:STDOUT: !199 = !DILocation(line: 273, column: 26, scope: !183)
// CHECK:STDOUT: !200 = !DILocation(line: 273, column: 5, scope: !183)
// CHECK:STDOUT: !201 = !{!184, !185}
// CHECK:STDOUT: !202 = distinct !DISubprogram(name: "HasValue", linkageName: "_CHasValue.Optional.Core.3530343734a6ea27", scope: null, file: !83, line: 37, type: !93, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !210)
// CHECK:STDOUT: !203 = !DILocalVariable(arg: 1, scope: !202, type: !9)
// CHECK:STDOUT: !208 = !DILocation(line: 38, column: 12, scope: !202)
// CHECK:STDOUT: !209 = !DILocation(line: 38, column: 5, scope: !202)
// CHECK:STDOUT: !210 = !{!203}
// CHECK:STDOUT: !211 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Optional.Core.3530343734a6ea27", scope: null, file: !83, line: 40, type: !103, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !219)
// CHECK:STDOUT: !212 = !DILocalVariable(arg: 1, scope: !211, type: !9)
// CHECK:STDOUT: !217 = !DILocation(line: 41, column: 12, scope: !211)
// CHECK:STDOUT: !218 = !DILocation(line: 41, column: 5, scope: !211)
// CHECK:STDOUT: !219 = !{!212}
// CHECK:STDOUT: !220 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc", scope: null, file: !83, line: 166, type: !93, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !227)
// CHECK:STDOUT: !221 = !DILocalVariable(arg: 1, scope: !220, type: !9)
// CHECK:STDOUT: !225 = !DILocation(line: 167, column: 12, scope: !220)
// CHECK:STDOUT: !226 = !DILocation(line: 167, column: 5, scope: !220)
// CHECK:STDOUT: !227 = !{!221}
// CHECK:STDOUT: !228 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc", scope: null, file: !83, line: 169, type: !103, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !235)
// CHECK:STDOUT: !229 = !DILocalVariable(arg: 1, scope: !228, type: !9)
// CHECK:STDOUT: !233 = !DILocation(line: 170, column: 12, scope: !228)
// CHECK:STDOUT: !234 = !DILocation(line: 170, column: 5, scope: !228)
// CHECK:STDOUT: !235 = !{!229}
// CHECK:STDOUT:

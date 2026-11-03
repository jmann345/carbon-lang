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
// the `Optional(i32)` specific of each impl function is emitted here; it tests
// `HasValue()`, then compares in place (D-OP-1, D-OP-2, D-OP-4, W-352).

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
// CHECK:STDOUT:   %10 = call i1 @"_CPayloadEqual.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageEq.517dd5c25edce734.Core.50c5af1cbe028675"(ptr %self, ptr %other), !dbg !107
// CHECK:STDOUT:   ret i1 %10, !dbg !108
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CNotEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9"(ptr %self, ptr %other) #0 !dbg !110 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !117
// CHECK:STDOUT:   %2 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !118
// CHECK:STDOUT:   %3 = icmp ne i1 %1, %2, !dbg !117
// CHECK:STDOUT:   br i1 %3, label %4, label %5, !dbg !119
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 true, !dbg !120
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %0
// CHECK:STDOUT:   %6 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !121
// CHECK:STDOUT:   %7 = xor i1 %6, true, !dbg !122
// CHECK:STDOUT:   br i1 %7, label %8, label %9, !dbg !123
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %5
// CHECK:STDOUT:   ret i1 false, !dbg !124
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %5
// CHECK:STDOUT:   %10 = call i1 @"_CPayloadNotEqual.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageEq.517dd5c25edce734.Core.50c5af1cbe028675"(ptr %self, ptr %other), !dbg !127
// CHECK:STDOUT:   ret i1 %10, !dbg !128
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CLess.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %self, ptr %other) #0 !dbg !130 {
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
// CHECK:STDOUT:   %9 = call i1 @"_CPayloadLess.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b"(ptr %self, ptr %other), !dbg !147
// CHECK:STDOUT:   ret i1 %9, !dbg !148
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CLessOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %self, ptr %other) #0 !dbg !150 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !157
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !158
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !159
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 true, !dbg !160
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %5 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !161
// CHECK:STDOUT:   %6 = xor i1 %5, true, !dbg !162
// CHECK:STDOUT:   br i1 %6, label %7, label %8, !dbg !163
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %4
// CHECK:STDOUT:   ret i1 false, !dbg !164
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %4
// CHECK:STDOUT:   %9 = call i1 @"_CPayloadLessOrEquivalent.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b"(ptr %self, ptr %other), !dbg !167
// CHECK:STDOUT:   ret i1 %9, !dbg !168
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CGreater.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %self, ptr %other) #0 !dbg !170 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !177
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !178
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !179
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 false, !dbg !180
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %5 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !181
// CHECK:STDOUT:   %6 = xor i1 %5, true, !dbg !182
// CHECK:STDOUT:   br i1 %6, label %7, label %8, !dbg !183
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %4
// CHECK:STDOUT:   ret i1 true, !dbg !184
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %4
// CHECK:STDOUT:   %9 = call i1 @"_CPayloadGreater.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b"(ptr %self, ptr %other), !dbg !187
// CHECK:STDOUT:   ret i1 %9, !dbg !188
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CGreaterOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %self, ptr %other) #0 !dbg !190 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !197
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !198
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !199
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 true, !dbg !200
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %5 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !201
// CHECK:STDOUT:   %6 = xor i1 %5, true, !dbg !202
// CHECK:STDOUT:   br i1 %6, label %7, label %8, !dbg !203
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %4
// CHECK:STDOUT:   ret i1 false, !dbg !204
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %4
// CHECK:STDOUT:   %9 = call i1 @"_CPayloadGreaterOrEquivalent.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b"(ptr %self, ptr %other), !dbg !207
// CHECK:STDOUT:   ret i1 %9, !dbg !208
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self) #0 !dbg !210 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %self), !dbg !216
// CHECK:STDOUT:   ret i1 %1, !dbg !217
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CPayloadEqual.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageEq.517dd5c25edce734.Core.50c5af1cbe028675"(ptr %a, ptr %b) #0 !dbg !219 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %a, i32 0, i32 0, !dbg !226
// CHECK:STDOUT:   %1 = load i32, ptr %value, align 4, !dbg !226
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %b, i32 0, i32 0, !dbg !227
// CHECK:STDOUT:   %2 = load i32, ptr %value1, align 4, !dbg !227
// CHECK:STDOUT:   %3 = icmp eq i32 %1, %2, !dbg !228
// CHECK:STDOUT:   ret i1 %3, !dbg !229
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CPayloadNotEqual.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageEq.517dd5c25edce734.Core.50c5af1cbe028675"(ptr %a, ptr %b) #0 !dbg !231 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %a, i32 0, i32 0, !dbg !238
// CHECK:STDOUT:   %1 = load i32, ptr %value, align 4, !dbg !238
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %b, i32 0, i32 0, !dbg !239
// CHECK:STDOUT:   %2 = load i32, ptr %value1, align 4, !dbg !239
// CHECK:STDOUT:   %3 = icmp ne i32 %1, %2, !dbg !240
// CHECK:STDOUT:   ret i1 %3, !dbg !241
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CPayloadLess.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b"(ptr %a, ptr %b) #0 !dbg !243 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %a, i32 0, i32 0, !dbg !250
// CHECK:STDOUT:   %1 = load i32, ptr %value, align 4, !dbg !250
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %b, i32 0, i32 0, !dbg !251
// CHECK:STDOUT:   %2 = load i32, ptr %value1, align 4, !dbg !251
// CHECK:STDOUT:   %3 = icmp slt i32 %1, %2, !dbg !252
// CHECK:STDOUT:   ret i1 %3, !dbg !253
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CPayloadLessOrEquivalent.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b"(ptr %a, ptr %b) #0 !dbg !255 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %a, i32 0, i32 0, !dbg !262
// CHECK:STDOUT:   %1 = load i32, ptr %value, align 4, !dbg !262
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %b, i32 0, i32 0, !dbg !263
// CHECK:STDOUT:   %2 = load i32, ptr %value1, align 4, !dbg !263
// CHECK:STDOUT:   %3 = icmp sle i32 %1, %2, !dbg !264
// CHECK:STDOUT:   ret i1 %3, !dbg !265
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CPayloadGreater.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b"(ptr %a, ptr %b) #0 !dbg !267 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %a, i32 0, i32 0, !dbg !274
// CHECK:STDOUT:   %1 = load i32, ptr %value, align 4, !dbg !274
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %b, i32 0, i32 0, !dbg !275
// CHECK:STDOUT:   %2 = load i32, ptr %value1, align 4, !dbg !275
// CHECK:STDOUT:   %3 = icmp sgt i32 %1, %2, !dbg !276
// CHECK:STDOUT:   ret i1 %3, !dbg !277
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CPayloadGreaterOrEquivalent.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b"(ptr %a, ptr %b) #0 !dbg !279 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %a, i32 0, i32 0, !dbg !286
// CHECK:STDOUT:   %1 = load i32, ptr %value, align 4, !dbg !286
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %b, i32 0, i32 0, !dbg !287
// CHECK:STDOUT:   %2 = load i32, ptr %value1, align 4, !dbg !287
// CHECK:STDOUT:   %3 = icmp sge i32 %1, %2, !dbg !288
// CHECK:STDOUT:   ret i1 %3, !dbg !289
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %value) #0 !dbg !291 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %value, i32 0, i32 1, !dbg !296
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !296
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !296
// CHECK:STDOUT:   ret i1 %2, !dbg !297
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CHasValue.Optional.Core.3530343734a6ea27, { 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
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
// CHECK:STDOUT: !88 = distinct !DISubprogram(name: "Equal", linkageName: "_CEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9", scope: null, file: !87, line: 282, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !109)
// CHECK:STDOUT: !89 = !DILocalVariable(arg: 1, scope: !88, type: !9)
// CHECK:STDOUT: !90 = !DILocalVariable(arg: 2, scope: !88, type: !9)
// CHECK:STDOUT: !95 = !DILocation(line: 283, column: 9, scope: !88)
// CHECK:STDOUT: !96 = !{!9, !9}
// CHECK:STDOUT: !97 = !DISubroutineType(types: !96)
// CHECK:STDOUT: !98 = !DILocation(line: 283, column: 28, scope: !88)
// CHECK:STDOUT: !99 = !DILocation(line: 283, column: 8, scope: !88)
// CHECK:STDOUT: !100 = !DILocation(line: 284, column: 7, scope: !88)
// CHECK:STDOUT: !101 = !DILocation(line: 286, column: 13, scope: !88)
// CHECK:STDOUT: !102 = !DILocation(line: 286, column: 9, scope: !88)
// CHECK:STDOUT: !103 = !DILocation(line: 286, column: 8, scope: !88)
// CHECK:STDOUT: !104 = !DILocation(line: 287, column: 7, scope: !88)
// CHECK:STDOUT: !107 = !DILocation(line: 289, column: 12, scope: !88)
// CHECK:STDOUT: !108 = !DILocation(line: 289, column: 5, scope: !88)
// CHECK:STDOUT: !109 = !{!89, !90}
// CHECK:STDOUT: !110 = distinct !DISubprogram(name: "NotEqual", linkageName: "_CNotEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9", scope: null, file: !87, line: 292, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !129)
// CHECK:STDOUT: !111 = !DILocalVariable(arg: 1, scope: !110, type: !9)
// CHECK:STDOUT: !112 = !DILocalVariable(arg: 2, scope: !110, type: !9)
// CHECK:STDOUT: !117 = !DILocation(line: 293, column: 9, scope: !110)
// CHECK:STDOUT: !118 = !DILocation(line: 293, column: 28, scope: !110)
// CHECK:STDOUT: !119 = !DILocation(line: 293, column: 8, scope: !110)
// CHECK:STDOUT: !120 = !DILocation(line: 294, column: 7, scope: !110)
// CHECK:STDOUT: !121 = !DILocation(line: 296, column: 13, scope: !110)
// CHECK:STDOUT: !122 = !DILocation(line: 296, column: 9, scope: !110)
// CHECK:STDOUT: !123 = !DILocation(line: 296, column: 8, scope: !110)
// CHECK:STDOUT: !124 = !DILocation(line: 297, column: 7, scope: !110)
// CHECK:STDOUT: !127 = !DILocation(line: 299, column: 12, scope: !110)
// CHECK:STDOUT: !128 = !DILocation(line: 299, column: 5, scope: !110)
// CHECK:STDOUT: !129 = !{!111, !112}
// CHECK:STDOUT: !130 = distinct !DISubprogram(name: "Less", linkageName: "_CLess.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd", scope: null, file: !87, line: 306, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !149)
// CHECK:STDOUT: !131 = !DILocalVariable(arg: 1, scope: !130, type: !9)
// CHECK:STDOUT: !132 = !DILocalVariable(arg: 2, scope: !130, type: !9)
// CHECK:STDOUT: !137 = !DILocation(line: 307, column: 13, scope: !130)
// CHECK:STDOUT: !138 = !DILocation(line: 307, column: 9, scope: !130)
// CHECK:STDOUT: !139 = !DILocation(line: 307, column: 8, scope: !130)
// CHECK:STDOUT: !140 = !DILocation(line: 308, column: 7, scope: !130)
// CHECK:STDOUT: !141 = !DILocation(line: 310, column: 13, scope: !130)
// CHECK:STDOUT: !142 = !DILocation(line: 310, column: 9, scope: !130)
// CHECK:STDOUT: !143 = !DILocation(line: 310, column: 8, scope: !130)
// CHECK:STDOUT: !144 = !DILocation(line: 311, column: 7, scope: !130)
// CHECK:STDOUT: !147 = !DILocation(line: 313, column: 12, scope: !130)
// CHECK:STDOUT: !148 = !DILocation(line: 313, column: 5, scope: !130)
// CHECK:STDOUT: !149 = !{!131, !132}
// CHECK:STDOUT: !150 = distinct !DISubprogram(name: "LessOrEquivalent", linkageName: "_CLessOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd", scope: null, file: !87, line: 316, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !169)
// CHECK:STDOUT: !151 = !DILocalVariable(arg: 1, scope: !150, type: !9)
// CHECK:STDOUT: !152 = !DILocalVariable(arg: 2, scope: !150, type: !9)
// CHECK:STDOUT: !157 = !DILocation(line: 317, column: 13, scope: !150)
// CHECK:STDOUT: !158 = !DILocation(line: 317, column: 9, scope: !150)
// CHECK:STDOUT: !159 = !DILocation(line: 317, column: 8, scope: !150)
// CHECK:STDOUT: !160 = !DILocation(line: 318, column: 7, scope: !150)
// CHECK:STDOUT: !161 = !DILocation(line: 320, column: 13, scope: !150)
// CHECK:STDOUT: !162 = !DILocation(line: 320, column: 9, scope: !150)
// CHECK:STDOUT: !163 = !DILocation(line: 320, column: 8, scope: !150)
// CHECK:STDOUT: !164 = !DILocation(line: 321, column: 7, scope: !150)
// CHECK:STDOUT: !167 = !DILocation(line: 323, column: 12, scope: !150)
// CHECK:STDOUT: !168 = !DILocation(line: 323, column: 5, scope: !150)
// CHECK:STDOUT: !169 = !{!151, !152}
// CHECK:STDOUT: !170 = distinct !DISubprogram(name: "Greater", linkageName: "_CGreater.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd", scope: null, file: !87, line: 326, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !189)
// CHECK:STDOUT: !171 = !DILocalVariable(arg: 1, scope: !170, type: !9)
// CHECK:STDOUT: !172 = !DILocalVariable(arg: 2, scope: !170, type: !9)
// CHECK:STDOUT: !177 = !DILocation(line: 327, column: 13, scope: !170)
// CHECK:STDOUT: !178 = !DILocation(line: 327, column: 9, scope: !170)
// CHECK:STDOUT: !179 = !DILocation(line: 327, column: 8, scope: !170)
// CHECK:STDOUT: !180 = !DILocation(line: 328, column: 7, scope: !170)
// CHECK:STDOUT: !181 = !DILocation(line: 330, column: 13, scope: !170)
// CHECK:STDOUT: !182 = !DILocation(line: 330, column: 9, scope: !170)
// CHECK:STDOUT: !183 = !DILocation(line: 330, column: 8, scope: !170)
// CHECK:STDOUT: !184 = !DILocation(line: 331, column: 7, scope: !170)
// CHECK:STDOUT: !187 = !DILocation(line: 333, column: 12, scope: !170)
// CHECK:STDOUT: !188 = !DILocation(line: 333, column: 5, scope: !170)
// CHECK:STDOUT: !189 = !{!171, !172}
// CHECK:STDOUT: !190 = distinct !DISubprogram(name: "GreaterOrEquivalent", linkageName: "_CGreaterOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd", scope: null, file: !87, line: 336, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !209)
// CHECK:STDOUT: !191 = !DILocalVariable(arg: 1, scope: !190, type: !9)
// CHECK:STDOUT: !192 = !DILocalVariable(arg: 2, scope: !190, type: !9)
// CHECK:STDOUT: !197 = !DILocation(line: 337, column: 13, scope: !190)
// CHECK:STDOUT: !198 = !DILocation(line: 337, column: 9, scope: !190)
// CHECK:STDOUT: !199 = !DILocation(line: 337, column: 8, scope: !190)
// CHECK:STDOUT: !200 = !DILocation(line: 338, column: 7, scope: !190)
// CHECK:STDOUT: !201 = !DILocation(line: 340, column: 13, scope: !190)
// CHECK:STDOUT: !202 = !DILocation(line: 340, column: 9, scope: !190)
// CHECK:STDOUT: !203 = !DILocation(line: 340, column: 8, scope: !190)
// CHECK:STDOUT: !204 = !DILocation(line: 341, column: 7, scope: !190)
// CHECK:STDOUT: !207 = !DILocation(line: 343, column: 12, scope: !190)
// CHECK:STDOUT: !208 = !DILocation(line: 343, column: 5, scope: !190)
// CHECK:STDOUT: !209 = !{!191, !192}
// CHECK:STDOUT: !210 = distinct !DISubprogram(name: "HasValue", linkageName: "_CHasValue.Optional.Core.3530343734a6ea27", scope: null, file: !87, line: 37, type: !97, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !218)
// CHECK:STDOUT: !211 = !DILocalVariable(arg: 1, scope: !210, type: !9)
// CHECK:STDOUT: !216 = !DILocation(line: 38, column: 12, scope: !210)
// CHECK:STDOUT: !217 = !DILocation(line: 38, column: 5, scope: !210)
// CHECK:STDOUT: !218 = !{!211}
// CHECK:STDOUT: !219 = distinct !DISubprogram(name: "PayloadEqual", linkageName: "_CPayloadEqual.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageEq.517dd5c25edce734.Core.50c5af1cbe028675", scope: null, file: !87, line: 236, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !230)
// CHECK:STDOUT: !220 = !DILocalVariable(arg: 1, scope: !219, type: !9)
// CHECK:STDOUT: !221 = !DILocalVariable(arg: 2, scope: !219, type: !9)
// CHECK:STDOUT: !226 = !DILocation(line: 237, column: 13, scope: !219)
// CHECK:STDOUT: !227 = !DILocation(line: 237, column: 38, scope: !219)
// CHECK:STDOUT: !228 = !DILocation(line: 237, column: 12, scope: !219)
// CHECK:STDOUT: !229 = !DILocation(line: 237, column: 5, scope: !219)
// CHECK:STDOUT: !230 = !{!220, !221}
// CHECK:STDOUT: !231 = distinct !DISubprogram(name: "PayloadNotEqual", linkageName: "_CPayloadNotEqual.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageEq.517dd5c25edce734.Core.50c5af1cbe028675", scope: null, file: !87, line: 239, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !242)
// CHECK:STDOUT: !232 = !DILocalVariable(arg: 1, scope: !231, type: !9)
// CHECK:STDOUT: !233 = !DILocalVariable(arg: 2, scope: !231, type: !9)
// CHECK:STDOUT: !238 = !DILocation(line: 240, column: 13, scope: !231)
// CHECK:STDOUT: !239 = !DILocation(line: 240, column: 38, scope: !231)
// CHECK:STDOUT: !240 = !DILocation(line: 240, column: 12, scope: !231)
// CHECK:STDOUT: !241 = !DILocation(line: 240, column: 5, scope: !231)
// CHECK:STDOUT: !242 = !{!232, !233}
// CHECK:STDOUT: !243 = distinct !DISubprogram(name: "PayloadLess", linkageName: "_CPayloadLess.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b", scope: null, file: !87, line: 266, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !254)
// CHECK:STDOUT: !244 = !DILocalVariable(arg: 1, scope: !243, type: !9)
// CHECK:STDOUT: !245 = !DILocalVariable(arg: 2, scope: !243, type: !9)
// CHECK:STDOUT: !250 = !DILocation(line: 267, column: 13, scope: !243)
// CHECK:STDOUT: !251 = !DILocation(line: 267, column: 37, scope: !243)
// CHECK:STDOUT: !252 = !DILocation(line: 267, column: 12, scope: !243)
// CHECK:STDOUT: !253 = !DILocation(line: 267, column: 5, scope: !243)
// CHECK:STDOUT: !254 = !{!244, !245}
// CHECK:STDOUT: !255 = distinct !DISubprogram(name: "PayloadLessOrEquivalent", linkageName: "_CPayloadLessOrEquivalent.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b", scope: null, file: !87, line: 269, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !266)
// CHECK:STDOUT: !256 = !DILocalVariable(arg: 1, scope: !255, type: !9)
// CHECK:STDOUT: !257 = !DILocalVariable(arg: 2, scope: !255, type: !9)
// CHECK:STDOUT: !262 = !DILocation(line: 270, column: 13, scope: !255)
// CHECK:STDOUT: !263 = !DILocation(line: 270, column: 38, scope: !255)
// CHECK:STDOUT: !264 = !DILocation(line: 270, column: 12, scope: !255)
// CHECK:STDOUT: !265 = !DILocation(line: 270, column: 5, scope: !255)
// CHECK:STDOUT: !266 = !{!256, !257}
// CHECK:STDOUT: !267 = distinct !DISubprogram(name: "PayloadGreater", linkageName: "_CPayloadGreater.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b", scope: null, file: !87, line: 272, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !278)
// CHECK:STDOUT: !268 = !DILocalVariable(arg: 1, scope: !267, type: !9)
// CHECK:STDOUT: !269 = !DILocalVariable(arg: 2, scope: !267, type: !9)
// CHECK:STDOUT: !274 = !DILocation(line: 273, column: 13, scope: !267)
// CHECK:STDOUT: !275 = !DILocation(line: 273, column: 37, scope: !267)
// CHECK:STDOUT: !276 = !DILocation(line: 273, column: 12, scope: !267)
// CHECK:STDOUT: !277 = !DILocation(line: 273, column: 5, scope: !267)
// CHECK:STDOUT: !278 = !{!268, !269}
// CHECK:STDOUT: !279 = distinct !DISubprogram(name: "PayloadGreaterOrEquivalent", linkageName: "_CPayloadGreaterOrEquivalent.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b", scope: null, file: !87, line: 275, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !290)
// CHECK:STDOUT: !280 = !DILocalVariable(arg: 1, scope: !279, type: !9)
// CHECK:STDOUT: !281 = !DILocalVariable(arg: 2, scope: !279, type: !9)
// CHECK:STDOUT: !286 = !DILocation(line: 276, column: 13, scope: !279)
// CHECK:STDOUT: !287 = !DILocation(line: 276, column: 38, scope: !279)
// CHECK:STDOUT: !288 = !DILocation(line: 276, column: 12, scope: !279)
// CHECK:STDOUT: !289 = !DILocation(line: 276, column: 5, scope: !279)
// CHECK:STDOUT: !290 = !{!280, !281}
// CHECK:STDOUT: !291 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc", scope: null, file: !87, line: 166, type: !97, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !298)
// CHECK:STDOUT: !292 = !DILocalVariable(arg: 1, scope: !291, type: !9)
// CHECK:STDOUT: !296 = !DILocation(line: 167, column: 12, scope: !291)
// CHECK:STDOUT: !297 = !DILocation(line: 167, column: 5, scope: !291)
// CHECK:STDOUT: !298 = !{!292}
// CHECK:STDOUT:

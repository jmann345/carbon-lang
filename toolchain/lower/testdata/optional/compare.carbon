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
// CHECK:STDOUT:   %10 = call i1 @"_CPayloadEqual.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageEq.517dd5c25edce734.Core.50c5af1cbe028675"(ptr %self, ptr %other), !dbg !103
// CHECK:STDOUT:   ret i1 %10, !dbg !104
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CNotEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9"(ptr %self, ptr %other) #0 !dbg !106 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !113
// CHECK:STDOUT:   %2 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !114
// CHECK:STDOUT:   %3 = icmp ne i1 %1, %2, !dbg !113
// CHECK:STDOUT:   br i1 %3, label %4, label %5, !dbg !115
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 true, !dbg !116
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %0
// CHECK:STDOUT:   %6 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !117
// CHECK:STDOUT:   %7 = xor i1 %6, true, !dbg !118
// CHECK:STDOUT:   br i1 %7, label %8, label %9, !dbg !119
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %5
// CHECK:STDOUT:   ret i1 false, !dbg !120
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %5
// CHECK:STDOUT:   %10 = call i1 @"_CPayloadNotEqual.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageEq.517dd5c25edce734.Core.50c5af1cbe028675"(ptr %self, ptr %other), !dbg !123
// CHECK:STDOUT:   ret i1 %10, !dbg !124
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CLess.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %self, ptr %other) #0 !dbg !126 {
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
// CHECK:STDOUT:   %9 = call i1 @"_CPayloadLess.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b"(ptr %self, ptr %other), !dbg !143
// CHECK:STDOUT:   ret i1 %9, !dbg !144
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CLessOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %self, ptr %other) #0 !dbg !146 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !153
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !154
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !155
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 true, !dbg !156
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %5 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !157
// CHECK:STDOUT:   %6 = xor i1 %5, true, !dbg !158
// CHECK:STDOUT:   br i1 %6, label %7, label %8, !dbg !159
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %4
// CHECK:STDOUT:   ret i1 false, !dbg !160
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %4
// CHECK:STDOUT:   %9 = call i1 @"_CPayloadLessOrEquivalent.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b"(ptr %self, ptr %other), !dbg !163
// CHECK:STDOUT:   ret i1 %9, !dbg !164
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CGreater.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %self, ptr %other) #0 !dbg !166 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !173
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !174
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !175
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 false, !dbg !176
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %5 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !177
// CHECK:STDOUT:   %6 = xor i1 %5, true, !dbg !178
// CHECK:STDOUT:   br i1 %6, label %7, label %8, !dbg !179
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %4
// CHECK:STDOUT:   ret i1 true, !dbg !180
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %4
// CHECK:STDOUT:   %9 = call i1 @"_CPayloadGreater.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b"(ptr %self, ptr %other), !dbg !183
// CHECK:STDOUT:   ret i1 %9, !dbg !184
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CGreaterOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd"(ptr %self, ptr %other) #0 !dbg !186 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %other), !dbg !193
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !194
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !195
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 true, !dbg !196
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %5 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !197
// CHECK:STDOUT:   %6 = xor i1 %5, true, !dbg !198
// CHECK:STDOUT:   br i1 %6, label %7, label %8, !dbg !199
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %4
// CHECK:STDOUT:   ret i1 false, !dbg !200
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %4
// CHECK:STDOUT:   %9 = call i1 @"_CPayloadGreaterOrEquivalent.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b"(ptr %self, ptr %other), !dbg !203
// CHECK:STDOUT:   ret i1 %9, !dbg !204
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self) #0 !dbg !206 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %self), !dbg !212
// CHECK:STDOUT:   ret i1 %1, !dbg !213
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CPayloadEqual.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageEq.517dd5c25edce734.Core.50c5af1cbe028675"(ptr %a, ptr %b) #0 !dbg !215 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %a, i32 0, i32 0, !dbg !222
// CHECK:STDOUT:   %1 = load i32, ptr %value, align 4, !dbg !222
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %b, i32 0, i32 0, !dbg !223
// CHECK:STDOUT:   %2 = load i32, ptr %value1, align 4, !dbg !223
// CHECK:STDOUT:   %3 = icmp eq i32 %1, %2, !dbg !224
// CHECK:STDOUT:   ret i1 %3, !dbg !225
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CPayloadNotEqual.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageEq.517dd5c25edce734.Core.50c5af1cbe028675"(ptr %a, ptr %b) #0 !dbg !227 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %a, i32 0, i32 0, !dbg !234
// CHECK:STDOUT:   %1 = load i32, ptr %value, align 4, !dbg !234
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %b, i32 0, i32 0, !dbg !235
// CHECK:STDOUT:   %2 = load i32, ptr %value1, align 4, !dbg !235
// CHECK:STDOUT:   %3 = icmp ne i32 %1, %2, !dbg !236
// CHECK:STDOUT:   ret i1 %3, !dbg !237
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CPayloadLess.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b"(ptr %a, ptr %b) #0 !dbg !239 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %a, i32 0, i32 0, !dbg !246
// CHECK:STDOUT:   %1 = load i32, ptr %value, align 4, !dbg !246
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %b, i32 0, i32 0, !dbg !247
// CHECK:STDOUT:   %2 = load i32, ptr %value1, align 4, !dbg !247
// CHECK:STDOUT:   %3 = icmp slt i32 %1, %2, !dbg !248
// CHECK:STDOUT:   ret i1 %3, !dbg !249
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CPayloadLessOrEquivalent.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b"(ptr %a, ptr %b) #0 !dbg !251 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %a, i32 0, i32 0, !dbg !258
// CHECK:STDOUT:   %1 = load i32, ptr %value, align 4, !dbg !258
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %b, i32 0, i32 0, !dbg !259
// CHECK:STDOUT:   %2 = load i32, ptr %value1, align 4, !dbg !259
// CHECK:STDOUT:   %3 = icmp sle i32 %1, %2, !dbg !260
// CHECK:STDOUT:   ret i1 %3, !dbg !261
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CPayloadGreater.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b"(ptr %a, ptr %b) #0 !dbg !263 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %a, i32 0, i32 0, !dbg !270
// CHECK:STDOUT:   %1 = load i32, ptr %value, align 4, !dbg !270
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %b, i32 0, i32 0, !dbg !271
// CHECK:STDOUT:   %2 = load i32, ptr %value1, align 4, !dbg !271
// CHECK:STDOUT:   %3 = icmp sgt i32 %1, %2, !dbg !272
// CHECK:STDOUT:   ret i1 %3, !dbg !273
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CPayloadGreaterOrEquivalent.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b"(ptr %a, ptr %b) #0 !dbg !275 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %a, i32 0, i32 0, !dbg !282
// CHECK:STDOUT:   %1 = load i32, ptr %value, align 4, !dbg !282
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %b, i32 0, i32 0, !dbg !283
// CHECK:STDOUT:   %2 = load i32, ptr %value1, align 4, !dbg !283
// CHECK:STDOUT:   %3 = icmp sge i32 %1, %2, !dbg !284
// CHECK:STDOUT:   ret i1 %3, !dbg !285
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %value) #0 !dbg !287 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %value, i32 0, i32 1, !dbg !292
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !292
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !292
// CHECK:STDOUT:   ret i1 %2, !dbg !293
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
// CHECK:STDOUT: !83 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "Equal", linkageName: "_CEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9", scope: null, file: !83, line: 282, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !105)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !84, type: !9)
// CHECK:STDOUT: !86 = !DILocalVariable(arg: 2, scope: !84, type: !9)
// CHECK:STDOUT: !91 = !DILocation(line: 283, column: 9, scope: !84)
// CHECK:STDOUT: !92 = !{!9, !9}
// CHECK:STDOUT: !93 = !DISubroutineType(types: !92)
// CHECK:STDOUT: !94 = !DILocation(line: 283, column: 28, scope: !84)
// CHECK:STDOUT: !95 = !DILocation(line: 283, column: 8, scope: !84)
// CHECK:STDOUT: !96 = !DILocation(line: 284, column: 7, scope: !84)
// CHECK:STDOUT: !97 = !DILocation(line: 286, column: 13, scope: !84)
// CHECK:STDOUT: !98 = !DILocation(line: 286, column: 9, scope: !84)
// CHECK:STDOUT: !99 = !DILocation(line: 286, column: 8, scope: !84)
// CHECK:STDOUT: !100 = !DILocation(line: 287, column: 7, scope: !84)
// CHECK:STDOUT: !103 = !DILocation(line: 289, column: 12, scope: !84)
// CHECK:STDOUT: !104 = !DILocation(line: 289, column: 5, scope: !84)
// CHECK:STDOUT: !105 = !{!85, !86}
// CHECK:STDOUT: !106 = distinct !DISubprogram(name: "NotEqual", linkageName: "_CNotEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9", scope: null, file: !83, line: 292, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !125)
// CHECK:STDOUT: !107 = !DILocalVariable(arg: 1, scope: !106, type: !9)
// CHECK:STDOUT: !108 = !DILocalVariable(arg: 2, scope: !106, type: !9)
// CHECK:STDOUT: !113 = !DILocation(line: 293, column: 9, scope: !106)
// CHECK:STDOUT: !114 = !DILocation(line: 293, column: 28, scope: !106)
// CHECK:STDOUT: !115 = !DILocation(line: 293, column: 8, scope: !106)
// CHECK:STDOUT: !116 = !DILocation(line: 294, column: 7, scope: !106)
// CHECK:STDOUT: !117 = !DILocation(line: 296, column: 13, scope: !106)
// CHECK:STDOUT: !118 = !DILocation(line: 296, column: 9, scope: !106)
// CHECK:STDOUT: !119 = !DILocation(line: 296, column: 8, scope: !106)
// CHECK:STDOUT: !120 = !DILocation(line: 297, column: 7, scope: !106)
// CHECK:STDOUT: !123 = !DILocation(line: 299, column: 12, scope: !106)
// CHECK:STDOUT: !124 = !DILocation(line: 299, column: 5, scope: !106)
// CHECK:STDOUT: !125 = !{!107, !108}
// CHECK:STDOUT: !126 = distinct !DISubprogram(name: "Less", linkageName: "_CLess.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd", scope: null, file: !83, line: 306, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !145)
// CHECK:STDOUT: !127 = !DILocalVariable(arg: 1, scope: !126, type: !9)
// CHECK:STDOUT: !128 = !DILocalVariable(arg: 2, scope: !126, type: !9)
// CHECK:STDOUT: !133 = !DILocation(line: 307, column: 13, scope: !126)
// CHECK:STDOUT: !134 = !DILocation(line: 307, column: 9, scope: !126)
// CHECK:STDOUT: !135 = !DILocation(line: 307, column: 8, scope: !126)
// CHECK:STDOUT: !136 = !DILocation(line: 308, column: 7, scope: !126)
// CHECK:STDOUT: !137 = !DILocation(line: 310, column: 13, scope: !126)
// CHECK:STDOUT: !138 = !DILocation(line: 310, column: 9, scope: !126)
// CHECK:STDOUT: !139 = !DILocation(line: 310, column: 8, scope: !126)
// CHECK:STDOUT: !140 = !DILocation(line: 311, column: 7, scope: !126)
// CHECK:STDOUT: !143 = !DILocation(line: 313, column: 12, scope: !126)
// CHECK:STDOUT: !144 = !DILocation(line: 313, column: 5, scope: !126)
// CHECK:STDOUT: !145 = !{!127, !128}
// CHECK:STDOUT: !146 = distinct !DISubprogram(name: "LessOrEquivalent", linkageName: "_CLessOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd", scope: null, file: !83, line: 316, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !165)
// CHECK:STDOUT: !147 = !DILocalVariable(arg: 1, scope: !146, type: !9)
// CHECK:STDOUT: !148 = !DILocalVariable(arg: 2, scope: !146, type: !9)
// CHECK:STDOUT: !153 = !DILocation(line: 317, column: 13, scope: !146)
// CHECK:STDOUT: !154 = !DILocation(line: 317, column: 9, scope: !146)
// CHECK:STDOUT: !155 = !DILocation(line: 317, column: 8, scope: !146)
// CHECK:STDOUT: !156 = !DILocation(line: 318, column: 7, scope: !146)
// CHECK:STDOUT: !157 = !DILocation(line: 320, column: 13, scope: !146)
// CHECK:STDOUT: !158 = !DILocation(line: 320, column: 9, scope: !146)
// CHECK:STDOUT: !159 = !DILocation(line: 320, column: 8, scope: !146)
// CHECK:STDOUT: !160 = !DILocation(line: 321, column: 7, scope: !146)
// CHECK:STDOUT: !163 = !DILocation(line: 323, column: 12, scope: !146)
// CHECK:STDOUT: !164 = !DILocation(line: 323, column: 5, scope: !146)
// CHECK:STDOUT: !165 = !{!147, !148}
// CHECK:STDOUT: !166 = distinct !DISubprogram(name: "Greater", linkageName: "_CGreater.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd", scope: null, file: !83, line: 326, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !185)
// CHECK:STDOUT: !167 = !DILocalVariable(arg: 1, scope: !166, type: !9)
// CHECK:STDOUT: !168 = !DILocalVariable(arg: 2, scope: !166, type: !9)
// CHECK:STDOUT: !173 = !DILocation(line: 327, column: 13, scope: !166)
// CHECK:STDOUT: !174 = !DILocation(line: 327, column: 9, scope: !166)
// CHECK:STDOUT: !175 = !DILocation(line: 327, column: 8, scope: !166)
// CHECK:STDOUT: !176 = !DILocation(line: 328, column: 7, scope: !166)
// CHECK:STDOUT: !177 = !DILocation(line: 330, column: 13, scope: !166)
// CHECK:STDOUT: !178 = !DILocation(line: 330, column: 9, scope: !166)
// CHECK:STDOUT: !179 = !DILocation(line: 330, column: 8, scope: !166)
// CHECK:STDOUT: !180 = !DILocation(line: 331, column: 7, scope: !166)
// CHECK:STDOUT: !183 = !DILocation(line: 333, column: 12, scope: !166)
// CHECK:STDOUT: !184 = !DILocation(line: 333, column: 5, scope: !166)
// CHECK:STDOUT: !185 = !{!167, !168}
// CHECK:STDOUT: !186 = distinct !DISubprogram(name: "GreaterOrEquivalent", linkageName: "_CGreaterOrEquivalent.Optional.1dac4564233fecd1.Core:OrderedWith.2e6a6153069d9679.Core.47846d4aa53442bd", scope: null, file: !83, line: 336, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !205)
// CHECK:STDOUT: !187 = !DILocalVariable(arg: 1, scope: !186, type: !9)
// CHECK:STDOUT: !188 = !DILocalVariable(arg: 2, scope: !186, type: !9)
// CHECK:STDOUT: !193 = !DILocation(line: 337, column: 13, scope: !186)
// CHECK:STDOUT: !194 = !DILocation(line: 337, column: 9, scope: !186)
// CHECK:STDOUT: !195 = !DILocation(line: 337, column: 8, scope: !186)
// CHECK:STDOUT: !196 = !DILocation(line: 338, column: 7, scope: !186)
// CHECK:STDOUT: !197 = !DILocation(line: 340, column: 13, scope: !186)
// CHECK:STDOUT: !198 = !DILocation(line: 340, column: 9, scope: !186)
// CHECK:STDOUT: !199 = !DILocation(line: 340, column: 8, scope: !186)
// CHECK:STDOUT: !200 = !DILocation(line: 341, column: 7, scope: !186)
// CHECK:STDOUT: !203 = !DILocation(line: 343, column: 12, scope: !186)
// CHECK:STDOUT: !204 = !DILocation(line: 343, column: 5, scope: !186)
// CHECK:STDOUT: !205 = !{!187, !188}
// CHECK:STDOUT: !206 = distinct !DISubprogram(name: "HasValue", linkageName: "_CHasValue.Optional.Core.3530343734a6ea27", scope: null, file: !83, line: 37, type: !93, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !214)
// CHECK:STDOUT: !207 = !DILocalVariable(arg: 1, scope: !206, type: !9)
// CHECK:STDOUT: !212 = !DILocation(line: 38, column: 12, scope: !206)
// CHECK:STDOUT: !213 = !DILocation(line: 38, column: 5, scope: !206)
// CHECK:STDOUT: !214 = !{!207}
// CHECK:STDOUT: !215 = distinct !DISubprogram(name: "PayloadEqual", linkageName: "_CPayloadEqual.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageEq.517dd5c25edce734.Core.50c5af1cbe028675", scope: null, file: !83, line: 236, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !226)
// CHECK:STDOUT: !216 = !DILocalVariable(arg: 1, scope: !215, type: !9)
// CHECK:STDOUT: !217 = !DILocalVariable(arg: 2, scope: !215, type: !9)
// CHECK:STDOUT: !222 = !DILocation(line: 237, column: 13, scope: !215)
// CHECK:STDOUT: !223 = !DILocation(line: 237, column: 38, scope: !215)
// CHECK:STDOUT: !224 = !DILocation(line: 237, column: 12, scope: !215)
// CHECK:STDOUT: !225 = !DILocation(line: 237, column: 5, scope: !215)
// CHECK:STDOUT: !226 = !{!216, !217}
// CHECK:STDOUT: !227 = distinct !DISubprogram(name: "PayloadNotEqual", linkageName: "_CPayloadNotEqual.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageEq.517dd5c25edce734.Core.50c5af1cbe028675", scope: null, file: !83, line: 239, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !238)
// CHECK:STDOUT: !228 = !DILocalVariable(arg: 1, scope: !227, type: !9)
// CHECK:STDOUT: !229 = !DILocalVariable(arg: 2, scope: !227, type: !9)
// CHECK:STDOUT: !234 = !DILocation(line: 240, column: 13, scope: !227)
// CHECK:STDOUT: !235 = !DILocation(line: 240, column: 38, scope: !227)
// CHECK:STDOUT: !236 = !DILocation(line: 240, column: 12, scope: !227)
// CHECK:STDOUT: !237 = !DILocation(line: 240, column: 5, scope: !227)
// CHECK:STDOUT: !238 = !{!228, !229}
// CHECK:STDOUT: !239 = distinct !DISubprogram(name: "PayloadLess", linkageName: "_CPayloadLess.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b", scope: null, file: !83, line: 266, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !250)
// CHECK:STDOUT: !240 = !DILocalVariable(arg: 1, scope: !239, type: !9)
// CHECK:STDOUT: !241 = !DILocalVariable(arg: 2, scope: !239, type: !9)
// CHECK:STDOUT: !246 = !DILocation(line: 267, column: 13, scope: !239)
// CHECK:STDOUT: !247 = !DILocation(line: 267, column: 37, scope: !239)
// CHECK:STDOUT: !248 = !DILocation(line: 267, column: 12, scope: !239)
// CHECK:STDOUT: !249 = !DILocation(line: 267, column: 5, scope: !239)
// CHECK:STDOUT: !250 = !{!240, !241}
// CHECK:STDOUT: !251 = distinct !DISubprogram(name: "PayloadLessOrEquivalent", linkageName: "_CPayloadLessOrEquivalent.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b", scope: null, file: !83, line: 269, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !262)
// CHECK:STDOUT: !252 = !DILocalVariable(arg: 1, scope: !251, type: !9)
// CHECK:STDOUT: !253 = !DILocalVariable(arg: 2, scope: !251, type: !9)
// CHECK:STDOUT: !258 = !DILocation(line: 270, column: 13, scope: !251)
// CHECK:STDOUT: !259 = !DILocation(line: 270, column: 38, scope: !251)
// CHECK:STDOUT: !260 = !DILocation(line: 270, column: 12, scope: !251)
// CHECK:STDOUT: !261 = !DILocation(line: 270, column: 5, scope: !251)
// CHECK:STDOUT: !262 = !{!252, !253}
// CHECK:STDOUT: !263 = distinct !DISubprogram(name: "PayloadGreater", linkageName: "_CPayloadGreater.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b", scope: null, file: !83, line: 272, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !274)
// CHECK:STDOUT: !264 = !DILocalVariable(arg: 1, scope: !263, type: !9)
// CHECK:STDOUT: !265 = !DILocalVariable(arg: 2, scope: !263, type: !9)
// CHECK:STDOUT: !270 = !DILocation(line: 273, column: 13, scope: !263)
// CHECK:STDOUT: !271 = !DILocation(line: 273, column: 37, scope: !263)
// CHECK:STDOUT: !272 = !DILocation(line: 273, column: 12, scope: !263)
// CHECK:STDOUT: !273 = !DILocation(line: 273, column: 5, scope: !263)
// CHECK:STDOUT: !274 = !{!264, !265}
// CHECK:STDOUT: !275 = distinct !DISubprogram(name: "PayloadGreaterOrEquivalent", linkageName: "_CPayloadGreaterOrEquivalent.DefaultOptionalStorage.76dfce1d0720ccdf.Core:OptionalStorageOrdered.e02cd5b2a71aebc6.Core.ff6a7eb445a8050b", scope: null, file: !83, line: 275, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !286)
// CHECK:STDOUT: !276 = !DILocalVariable(arg: 1, scope: !275, type: !9)
// CHECK:STDOUT: !277 = !DILocalVariable(arg: 2, scope: !275, type: !9)
// CHECK:STDOUT: !282 = !DILocation(line: 276, column: 13, scope: !275)
// CHECK:STDOUT: !283 = !DILocation(line: 276, column: 38, scope: !275)
// CHECK:STDOUT: !284 = !DILocation(line: 276, column: 12, scope: !275)
// CHECK:STDOUT: !285 = !DILocation(line: 276, column: 5, scope: !275)
// CHECK:STDOUT: !286 = !{!276, !277}
// CHECK:STDOUT: !287 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc", scope: null, file: !83, line: 166, type: !93, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !294)
// CHECK:STDOUT: !288 = !DILocalVariable(arg: 1, scope: !287, type: !9)
// CHECK:STDOUT: !292 = !DILocation(line: 167, column: 12, scope: !287)
// CHECK:STDOUT: !293 = !DILocation(line: 167, column: 5, scope: !287)
// CHECK:STDOUT: !294 = !{!288}
// CHECK:STDOUT:

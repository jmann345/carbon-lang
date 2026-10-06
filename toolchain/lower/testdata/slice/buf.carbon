// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/slice/buf.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/slice/buf.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): `Core.Buf(T)` over `malloc`/`free`.
// Predicted: `call ptr @malloc`, `icmp eq ptr ..., null` (`PointerIsNull`),
// the fill loop (`store i32 %fill`), and `call void @free(ptr ...)` inside the
// destroy specific called at `F`'s exit (risk R-12).

fn F(n: i64) -> i32 {
  var b: Core.Buf(i32) = Core.Buf(i32).Make(n, 7);
  b.Set(0, 9);
  return b[0] + b.Get(1);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'buf.carbon'
// CHECK:STDOUT: source_filename = "buf.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [48 x i8] c"carbon: Core.Buf size is negative; terminating\0A\00", align 1
// CHECK:STDOUT: @1 = private unnamed_addr constant [45 x i8] c"carbon: heap allocation failed; terminating\0A\00", align 1
// CHECK:STDOUT: @2 = private unnamed_addr constant [51 x i8] c"carbon: Core.Buf index out of bounds; terminating\0A\00", align 1
// CHECK:STDOUT: @const.anon = internal constant { ptr, i64 } { ptr @0, i64 47 }
// CHECK:STDOUT: @const.anon.1 = internal constant { ptr, i64 } { ptr @1, i64 44 }
// CHECK:STDOUT: @const.anon.2 = internal constant { ptr, i64 } { ptr @2, i64 50 }
// CHECK:STDOUT: @3 = private unnamed_addr constant [53 x i8] c"carbon: Core.Slice index out of bounds; terminating\0A\00", align 1
// CHECK:STDOUT: @4 = private unnamed_addr constant [62 x i8] c"carbon: Core.Slice.Subslice range out of bounds; terminating\0A\00", align 1
// CHECK:STDOUT: @const.anon.3 = internal constant { ptr, i64 } { ptr @3, i64 52 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CF.Main(i64 %n) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %b.var = alloca { ptr, i64 }, align 8, !dbg !22
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !22
// CHECK:STDOUT:   call void @_CMake.Buf.Core.4d9f279dbc2b9f6f(ptr %b.var, i64 %n, i32 7), !dbg !24
// CHECK:STDOUT:   call void @_CSet.Buf.Core.4d9f279dbc2b9f6f(ptr %b.var, i64 0, i32 9), !dbg !28
// CHECK:STDOUT:   %Buf.as.IndexWith.impl.At.call = call i32 @"_CAt.Buf.a081b942542726db.Core:IndexWith.f249b435619a5146.Core.4d9f279dbc2b9f6f"(ptr %b.var, i64 0), !dbg !31
// CHECK:STDOUT:   %Buf.Get.call = call i32 @_CGet.Buf.Core.4d9f279dbc2b9f6f(ptr %b.var, i64 1), !dbg !34
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Buf.as.IndexWith.impl.At.call, %Buf.Get.call, !dbg !31
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.3fc11083d97fac37(ptr %b.var), !dbg !22
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.7a92959e16736fc7:core.Destroy.Core"(ptr %self) #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %self) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0f866e2c9731ba7d:core.Destroy.Core"(ptr %self) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.729fca203337f92a:core.Destroy.Core"(ptr %self) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !60
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.0cc0bac3871fce6b:core.Destroy.Core"(ptr %self) #0 !dbg !62 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.1.size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !64
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.1.size), !dbg !64
// CHECK:STDOUT:   %.2.ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !64
// CHECK:STDOUT:   call void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %.2.ptr), !dbg !64
// CHECK:STDOUT:   ret void, !dbg !64
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0cc0bac3871fce6b:core.Destroy.Core"(ptr %self) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.0cc0bac3871fce6b:core.Destroy.Core"(ptr %self), !dbg !68
// CHECK:STDOUT:   ret void, !dbg !68
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.079d89ca1000ddb5:core.Destroy.Core"(ptr %self) #0 !dbg !70 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.1.size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !72
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.1.size), !dbg !72
// CHECK:STDOUT:   %.2.ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !72
// CHECK:STDOUT:   call void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %.2.ptr), !dbg !72
// CHECK:STDOUT:   ret void, !dbg !72
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.079d89ca1000ddb5:core.Destroy.Core"(ptr %self) #0 !dbg !74 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.079d89ca1000ddb5:core.Destroy.Core"(ptr %self), !dbg !76
// CHECK:STDOUT:   ret void, !dbg !76
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CMake.Buf.Core.4d9f279dbc2b9f6f(ptr sret({ ptr, i64 }) %return, i64 %size, i32 %fill) #0 !dbg !79 {
// CHECK:STDOUT:   %1 = alloca ptr, align 8, !dbg !90
// CHECK:STDOUT:   %2 = alloca i64, align 8, !dbg !102
// CHECK:STDOUT:   %3 = icmp slt i64 %size, 0, !dbg !86
// CHECK:STDOUT:   br i1 %3, label %4, label %6, !dbg !87
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon, align 8, !dbg !88
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !88
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !88
// CHECK:STDOUT:   %5 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !88
// CHECK:STDOUT:   call void @abort(), !dbg !88
// CHECK:STDOUT:   br label %6, !dbg !89
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %4, %0
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !90
// CHECK:STDOUT:   %heap.bytes.mul = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 %size, i64 4), !dbg !92
// CHECK:STDOUT:   %heap.bytes = extractvalue { i64, i1 } %heap.bytes.mul, 0, !dbg !92
// CHECK:STDOUT:   %heap.bytes.overflow = extractvalue { i64, i1 } %heap.bytes.mul, 1, !dbg !92
// CHECK:STDOUT:   %heap.bytes.is_zero = icmp eq i64 %heap.bytes, 0, !dbg !92
// CHECK:STDOUT:   %heap.bytes.nonzero = select i1 %heap.bytes.is_zero, i64 1, i64 %heap.bytes, !dbg !92
// CHECK:STDOUT:   %heap.block = call ptr @malloc(i64 %heap.bytes.nonzero), !dbg !92
// CHECK:STDOUT:   %heap.result = select i1 %heap.bytes.overflow, ptr null, ptr %heap.block, !dbg !92
// CHECK:STDOUT:   store ptr %heap.result, ptr %1, align 8, !dbg !90
// CHECK:STDOUT:   %7 = load ptr, ptr %1, align 8, !dbg !94
// CHECK:STDOUT:   %8 = icmp eq ptr %7, null, !dbg !95
// CHECK:STDOUT:   br i1 %8, label %9, label %11, !dbg !96
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %6
// CHECK:STDOUT:   %fail_stop.load1 = load { ptr, i64 }, ptr @const.anon.1, align 8, !dbg !97
// CHECK:STDOUT:   %fail_stop.ptr2 = extractvalue { ptr, i64 } %fail_stop.load1, 0, !dbg !97
// CHECK:STDOUT:   %fail_stop.size3 = extractvalue { ptr, i64 } %fail_stop.load1, 1, !dbg !97
// CHECK:STDOUT:   %10 = call i64 @write(i32 2, ptr %fail_stop.ptr2, i64 %fail_stop.size3), !dbg !97
// CHECK:STDOUT:   call void @abort(), !dbg !97
// CHECK:STDOUT:   br label %11, !dbg !98
// CHECK:STDOUT:
// CHECK:STDOUT: 11:                                               ; preds = %9, %6
// CHECK:STDOUT:   %12 = load ptr, ptr %1, align 8, !dbg !99
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %2), !dbg !102
// CHECK:STDOUT:   store i64 0, ptr %2, align 8, !dbg !102
// CHECK:STDOUT:   br label %13, !dbg !104
// CHECK:STDOUT:
// CHECK:STDOUT: 13:                                               ; preds = %16, %11
// CHECK:STDOUT:   %14 = load i64, ptr %2, align 8, !dbg !105
// CHECK:STDOUT:   %15 = icmp slt i64 %14, %size, !dbg !105
// CHECK:STDOUT:   br i1 %15, label %16, label %18, !dbg !104
// CHECK:STDOUT:
// CHECK:STDOUT: 16:                                               ; preds = %13
// CHECK:STDOUT:   %17 = load i64, ptr %2, align 8, !dbg !108
// CHECK:STDOUT:   %ptr.offset = getelementptr inbounds i32, ptr %12, i64 %17, !dbg !109
// CHECK:STDOUT:   store i32 %fill, ptr %ptr.offset, align 4, !dbg !110
// CHECK:STDOUT:   call void @"_COp.Int.9452f4c51951679b.Core:Inc.Core.9025b11fc94ef1f2"(ptr %2), !dbg !113
// CHECK:STDOUT:   br label %13, !dbg !114
// CHECK:STDOUT:
// CHECK:STDOUT: 18:                                               ; preds = %13
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   store ptr %12, ptr %ptr, align 8, !dbg !117
// CHECK:STDOUT:   %size4 = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 1, !dbg !117
// CHECK:STDOUT:   store i64 %size, ptr %size4, align 8, !dbg !117
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %2), !dbg !102
// CHECK:STDOUT:   call void @"_CSelfDestruct.729fca203337f92a:core.Destroy.Core"(ptr %1), !dbg !90
// CHECK:STDOUT:   ret void, !dbg !118
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSet.Buf.Core.4d9f279dbc2b9f6f(ptr %self, i64 %i, i32 %value) #0 !dbg !120 {
// CHECK:STDOUT:   %1 = icmp slt i64 %i, 0, !dbg !127
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !127
// CHECK:STDOUT:   br i1 %2, label %3, label %6, !dbg !127
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !129
// CHECK:STDOUT:   %4 = load i64, ptr %size, align 8, !dbg !129
// CHECK:STDOUT:   %5 = icmp sge i64 %i, %4, !dbg !128
// CHECK:STDOUT:   br label %6, !dbg !127
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %3, %0
// CHECK:STDOUT:   %7 = phi i1 [ true, %0 ], [ %5, %3 ]
// CHECK:STDOUT:   br i1 %7, label %8, label %10, !dbg !130
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %6
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon.2, align 8, !dbg !131
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !131
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !131
// CHECK:STDOUT:   %9 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !131
// CHECK:STDOUT:   call void @abort(), !dbg !131
// CHECK:STDOUT:   br label %10, !dbg !132
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %8, %6
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !133
// CHECK:STDOUT:   %11 = load ptr, ptr %ptr, align 8, !dbg !133
// CHECK:STDOUT:   %ptr.offset = getelementptr inbounds i32, ptr %11, i64 %i, !dbg !135
// CHECK:STDOUT:   store i32 %value, ptr %ptr.offset, align 4, !dbg !136
// CHECK:STDOUT:   ret void, !dbg !138
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CAt.Buf.a081b942542726db.Core:IndexWith.f249b435619a5146.Core.4d9f279dbc2b9f6f"(ptr %self, i64 %subscript) #0 !dbg !140 {
// CHECK:STDOUT:   %1 = call i32 @_CGet.Buf.Core.4d9f279dbc2b9f6f(ptr %self, i64 %subscript), !dbg !147
// CHECK:STDOUT:   ret i32 %1, !dbg !149
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Buf.Core.4d9f279dbc2b9f6f(ptr %self, i64 %i) #0 !dbg !151 {
// CHECK:STDOUT:   %temp = alloca { ptr, i64 }, align 8, !dbg !158
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !158
// CHECK:STDOUT:   call void @_CAsSlice.Buf.Core.4d9f279dbc2b9f6f(ptr %temp, ptr %self), !dbg !158
// CHECK:STDOUT:   %1 = call i32 @_CGet.Slice.Core.4d9f279dbc2b9f6f(ptr %temp, i64 %i), !dbg !158
// CHECK:STDOUT:   call void @"_CSelfDestruct.079d89ca1000ddb5:core.Destroy.Core"(ptr %temp), !dbg !158
// CHECK:STDOUT:   ret i32 %1, !dbg !162
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.3fc11083d97fac37(ptr %self) #0 !dbg !165 {
// CHECK:STDOUT:   call void @"_COp.Buf.a081b942542726db.Core:Destroy.Core.4d9f279dbc2b9f6f"(ptr %self), !dbg !168
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.3fc11083d97fac37(ptr %self), !dbg !169
// CHECK:STDOUT:   ret void, !dbg !170
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noreturn
// CHECK:STDOUT: declare void @abort() #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
// CHECK:STDOUT: declare { i64, i1 } @llvm.umul.with.overflow.i64(i64, i64) #3
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @malloc(i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.Int.9452f4c51951679b.Core:Inc.Core.9025b11fc94ef1f2"(ptr %self) #0 !dbg !173 {
// CHECK:STDOUT:   call void @"_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.542d41f9b830d5be"(ptr %self, i64 1), !dbg !176
// CHECK:STDOUT:   ret void, !dbg !179
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CAsSlice.Buf.Core.4d9f279dbc2b9f6f(ptr sret({ ptr, i64 }) %return, ptr %self) #0 !dbg !181 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !186
// CHECK:STDOUT:   %1 = load ptr, ptr %ptr, align 8, !dbg !186
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !187
// CHECK:STDOUT:   %2 = load i64, ptr %size, align 8, !dbg !187
// CHECK:STDOUT:   call void @_CUnsafeMake.Slice.Core.4d9f279dbc2b9f6f(ptr %return, ptr %1, i64 %2), !dbg !188
// CHECK:STDOUT:   ret void, !dbg !191
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Slice.Core.4d9f279dbc2b9f6f(ptr %self, i64 %i) #0 !dbg !194 {
// CHECK:STDOUT:   %1 = icmp slt i64 %i, 0, !dbg !201
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !201
// CHECK:STDOUT:   br i1 %2, label %3, label %6, !dbg !201
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !203
// CHECK:STDOUT:   %4 = load i64, ptr %size, align 8, !dbg !203
// CHECK:STDOUT:   %5 = icmp sge i64 %i, %4, !dbg !202
// CHECK:STDOUT:   br label %6, !dbg !201
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %3, %0
// CHECK:STDOUT:   %7 = phi i1 [ true, %0 ], [ %5, %3 ]
// CHECK:STDOUT:   br i1 %7, label %8, label %10, !dbg !204
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %6
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon.3, align 8, !dbg !205
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !205
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !205
// CHECK:STDOUT:   %9 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !205
// CHECK:STDOUT:   call void @abort(), !dbg !205
// CHECK:STDOUT:   br label %10, !dbg !206
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %8, %6
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !207
// CHECK:STDOUT:   %11 = load ptr, ptr %ptr, align 8, !dbg !207
// CHECK:STDOUT:   %ptr.offset = getelementptr inbounds i32, ptr %11, i64 %i, !dbg !209
// CHECK:STDOUT:   %12 = load i32, ptr %ptr.offset, align 4, !dbg !210
// CHECK:STDOUT:   ret i32 %12, !dbg !211
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.Buf.a081b942542726db.Core:Destroy.Core.4d9f279dbc2b9f6f"(ptr %self) #0 !dbg !213 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !216
// CHECK:STDOUT:   %1 = load ptr, ptr %ptr, align 8, !dbg !216
// CHECK:STDOUT:   call void @free(ptr %1), !dbg !217
// CHECK:STDOUT:   ret void, !dbg !218
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.3fc11083d97fac37(ptr %self) #0 !dbg !220 {
// CHECK:STDOUT:   ret void, !dbg !223
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.542d41f9b830d5be"(ptr %self, i64 %other) #4 !dbg !225 {
// CHECK:STDOUT:   %1 = call i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.458163fe052e064e"(i64 %other), !dbg !228
// CHECK:STDOUT:   %2 = load i64, ptr %self, align 8, !dbg !229
// CHECK:STDOUT:   %3 = add i64 %2, %1, !dbg !229
// CHECK:STDOUT:   store i64 %3, ptr %self, align 8, !dbg !229
// CHECK:STDOUT:   ret void, !dbg !229
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CUnsafeMake.Slice.Core.4d9f279dbc2b9f6f(ptr sret({ ptr, i64 }) %return, ptr %p, i64 %size) #0 !dbg !233 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 0, !dbg !242
// CHECK:STDOUT:   store ptr %p, ptr %ptr, align 8, !dbg !242
// CHECK:STDOUT:   %size1 = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 1, !dbg !242
// CHECK:STDOUT:   store i64 %size, ptr %size1, align 8, !dbg !242
// CHECK:STDOUT:   ret void, !dbg !243
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @free(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.458163fe052e064e"(i64 %self) #0 !dbg !245 {
// CHECK:STDOUT:   %1 = call i64 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.9025b11fc94ef1f2"(i64 %self), !dbg !250
// CHECK:STDOUT:   ret i64 %1, !dbg !252
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.9025b11fc94ef1f2"(i64 %self) #0 !dbg !254 {
// CHECK:STDOUT:   ret i64 %self, !dbg !260
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CGet.Buf.Core.4d9f279dbc2b9f6f, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 0, 3, 2, 1 }
// CHECK:STDOUT: uselistorder ptr @abort, { 0, 3, 2, 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #2 = { noreturn }
// CHECK:STDOUT: attributes #3 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
// CHECK:STDOUT: attributes #4 = { alwaysinline nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "buf.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{!7, !6}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{null, !7}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !13 = !{null, !12}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{null, !6}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !36)
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !17, type: !6)
// CHECK:STDOUT: !22 = !DILocation(line: 19, column: 3, scope: !17)
// CHECK:STDOUT: !24 = !DILocation(line: 19, column: 26, scope: !17)
// CHECK:STDOUT: !25 = !{!12, !6, !7}
// CHECK:STDOUT: !26 = !DISubroutineType(types: !25)
// CHECK:STDOUT: !28 = !DILocation(line: 20, column: 3, scope: !17)
// CHECK:STDOUT: !29 = !{null, !12, !6, !7}
// CHECK:STDOUT: !30 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !31 = !DILocation(line: 21, column: 10, scope: !17)
// CHECK:STDOUT: !32 = !{!7, !12, !6}
// CHECK:STDOUT: !33 = !DISubroutineType(types: !32)
// CHECK:STDOUT: !34 = !DILocation(line: 21, column: 17, scope: !17)
// CHECK:STDOUT: !35 = !DILocation(line: 21, column: 3, scope: !17)
// CHECK:STDOUT: !36 = !{!18}
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 19, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !40)
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !37, type: !7)
// CHECK:STDOUT: !39 = !DILocation(line: 19, column: 10, scope: !37)
// CHECK:STDOUT: !40 = !{!38}
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.7a92959e16736fc7:core.Destroy.Core", scope: null, file: !4, line: 19, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !44)
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !41, type: !12)
// CHECK:STDOUT: !43 = !DILocation(line: 19, column: 26, scope: !41)
// CHECK:STDOUT: !44 = !{!42}
// CHECK:STDOUT: !45 = !DIFile(filename: "{{.*}}/prelude/types/buf.carbon", directory: "")
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d088c7eb746488be:core.Destroy.Core", scope: null, file: !45, line: 32, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !49)
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !46, type: !12)
// CHECK:STDOUT: !48 = !DILocation(line: 32, column: 18, scope: !46)
// CHECK:STDOUT: !49 = !{!47}
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0f866e2c9731ba7d:core.Destroy.Core", scope: null, file: !45, line: 32, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !53)
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 1, scope: !50, type: !12)
// CHECK:STDOUT: !52 = !DILocation(line: 32, column: 5, scope: !50)
// CHECK:STDOUT: !53 = !{!51}
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.729fca203337f92a:core.Destroy.Core", scope: null, file: !45, line: 32, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !57)
// CHECK:STDOUT: !55 = !DILocalVariable(arg: 1, scope: !54, type: !12)
// CHECK:STDOUT: !56 = !DILocation(line: 32, column: 5, scope: !54)
// CHECK:STDOUT: !57 = !{!55}
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !45, line: 45, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !61)
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !58, type: !6)
// CHECK:STDOUT: !60 = !DILocation(line: 45, column: 38, scope: !58)
// CHECK:STDOUT: !61 = !{!59}
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.0cc0bac3871fce6b:core.Destroy.Core", scope: null, file: !45, line: 45, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !65)
// CHECK:STDOUT: !63 = !DILocalVariable(arg: 1, scope: !62, type: !12)
// CHECK:STDOUT: !64 = !DILocation(line: 45, column: 38, scope: !62)
// CHECK:STDOUT: !65 = !{!63}
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0cc0bac3871fce6b:core.Destroy.Core", scope: null, file: !45, line: 45, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !69)
// CHECK:STDOUT: !67 = !DILocalVariable(arg: 1, scope: !66, type: !12)
// CHECK:STDOUT: !68 = !DILocation(line: 45, column: 38, scope: !66)
// CHECK:STDOUT: !69 = !{!67}
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.079d89ca1000ddb5:core.Destroy.Core", scope: null, file: !45, line: 45, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !73)
// CHECK:STDOUT: !71 = !DILocalVariable(arg: 1, scope: !70, type: !12)
// CHECK:STDOUT: !72 = !DILocation(line: 45, column: 38, scope: !70)
// CHECK:STDOUT: !73 = !{!71}
// CHECK:STDOUT: !74 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.079d89ca1000ddb5:core.Destroy.Core", scope: null, file: !45, line: 45, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !77)
// CHECK:STDOUT: !75 = !DILocalVariable(arg: 1, scope: !74, type: !12)
// CHECK:STDOUT: !76 = !DILocation(line: 45, column: 38, scope: !74)
// CHECK:STDOUT: !77 = !{!75}
// CHECK:STDOUT: !79 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.Buf.Core.4d9f279dbc2b9f6f", scope: null, file: !45, line: 28, type: !26, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !119)
// CHECK:STDOUT: !80 = !DILocalVariable(arg: 1, scope: !79, type: !6)
// CHECK:STDOUT: !81 = !DILocalVariable(arg: 2, scope: !79, type: !7)
// CHECK:STDOUT: !86 = !DILocation(line: 29, column: 9, scope: !79)
// CHECK:STDOUT: !87 = !DILocation(line: 29, column: 8, scope: !79)
// CHECK:STDOUT: !88 = !DILocation(line: 30, column: 7, scope: !79)
// CHECK:STDOUT: !89 = !DILocation(line: 29, column: 5, scope: !79)
// CHECK:STDOUT: !90 = !DILocation(line: 32, column: 5, scope: !79)
// CHECK:STDOUT: !92 = !DILocation(line: 32, column: 38, scope: !79)
// CHECK:STDOUT: !94 = !DILocation(line: 33, column: 23, scope: !79)
// CHECK:STDOUT: !95 = !DILocation(line: 33, column: 9, scope: !79)
// CHECK:STDOUT: !96 = !DILocation(line: 33, column: 8, scope: !79)
// CHECK:STDOUT: !97 = !DILocation(line: 34, column: 7, scope: !79)
// CHECK:STDOUT: !98 = !DILocation(line: 33, column: 5, scope: !79)
// CHECK:STDOUT: !99 = !DILocation(line: 36, column: 19, scope: !79)
// CHECK:STDOUT: !102 = !DILocation(line: 37, column: 5, scope: !79)
// CHECK:STDOUT: !104 = !DILocation(line: 38, column: 11, scope: !79)
// CHECK:STDOUT: !105 = !DILocation(line: 38, column: 12, scope: !79)
// CHECK:STDOUT: !108 = !DILocation(line: 39, column: 27, scope: !79)
// CHECK:STDOUT: !109 = !DILocation(line: 39, column: 8, scope: !79)
// CHECK:STDOUT: !110 = !DILocation(line: 39, column: 7, scope: !79)
// CHECK:STDOUT: !113 = !DILocation(line: 40, column: 7, scope: !79)
// CHECK:STDOUT: !114 = !DILocation(line: 38, column: 5, scope: !79)
// CHECK:STDOUT: !117 = !DILocation(line: 42, column: 12, scope: !79)
// CHECK:STDOUT: !118 = !DILocation(line: 42, column: 5, scope: !79)
// CHECK:STDOUT: !119 = !{!80, !81}
// CHECK:STDOUT: !120 = distinct !DISubprogram(name: "Set", linkageName: "_CSet.Buf.Core.4d9f279dbc2b9f6f", scope: null, file: !45, line: 48, type: !30, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !139)
// CHECK:STDOUT: !121 = !DILocalVariable(arg: 1, scope: !120, type: !12)
// CHECK:STDOUT: !122 = !DILocalVariable(arg: 2, scope: !120, type: !6)
// CHECK:STDOUT: !123 = !DILocalVariable(arg: 3, scope: !120, type: !7)
// CHECK:STDOUT: !127 = !DILocation(line: 49, column: 9, scope: !120)
// CHECK:STDOUT: !128 = !DILocation(line: 49, column: 18, scope: !120)
// CHECK:STDOUT: !129 = !DILocation(line: 49, column: 23, scope: !120)
// CHECK:STDOUT: !130 = !DILocation(line: 49, column: 8, scope: !120)
// CHECK:STDOUT: !131 = !DILocation(line: 50, column: 7, scope: !120)
// CHECK:STDOUT: !132 = !DILocation(line: 49, column: 5, scope: !120)
// CHECK:STDOUT: !133 = !DILocation(line: 52, column: 20, scope: !120)
// CHECK:STDOUT: !135 = !DILocation(line: 52, column: 6, scope: !120)
// CHECK:STDOUT: !136 = !DILocation(line: 52, column: 5, scope: !120)
// CHECK:STDOUT: !138 = !DILocation(line: 48, column: 3, scope: !120)
// CHECK:STDOUT: !139 = !{!121, !122, !123}
// CHECK:STDOUT: !140 = distinct !DISubprogram(name: "At", linkageName: "_CAt.Buf.a081b942542726db.Core:IndexWith.f249b435619a5146.Core.4d9f279dbc2b9f6f", scope: null, file: !45, line: 74, type: !33, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !150)
// CHECK:STDOUT: !141 = !DILocalVariable(arg: 1, scope: !140, type: !12)
// CHECK:STDOUT: !142 = !DILocalVariable(arg: 2, scope: !140, type: !6)
// CHECK:STDOUT: !147 = !DILocation(line: 74, column: 45, scope: !140)
// CHECK:STDOUT: !149 = !DILocation(line: 74, column: 38, scope: !140)
// CHECK:STDOUT: !150 = !{!141, !142}
// CHECK:STDOUT: !151 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Buf.Core.4d9f279dbc2b9f6f", scope: null, file: !45, line: 45, type: !33, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !163)
// CHECK:STDOUT: !152 = !DILocalVariable(arg: 1, scope: !151, type: !12)
// CHECK:STDOUT: !153 = !DILocalVariable(arg: 2, scope: !151, type: !6)
// CHECK:STDOUT: !158 = !DILocation(line: 45, column: 38, scope: !151)
// CHECK:STDOUT: !159 = !{!12, !12}
// CHECK:STDOUT: !160 = !DISubroutineType(types: !159)
// CHECK:STDOUT: !162 = !DILocation(line: 45, column: 31, scope: !151)
// CHECK:STDOUT: !163 = !{!152, !153}
// CHECK:STDOUT: !164 = !DIFile(filename: "{{.*}}/prelude/destroy.carbon", directory: "")
// CHECK:STDOUT: !165 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.3fc11083d97fac37", scope: null, file: !164, line: 26, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !171)
// CHECK:STDOUT: !166 = !DILocalVariable(arg: 1, scope: !165, type: !12)
// CHECK:STDOUT: !168 = !DILocation(line: 27, column: 5, scope: !165)
// CHECK:STDOUT: !169 = !DILocation(line: 28, column: 5, scope: !165)
// CHECK:STDOUT: !170 = !DILocation(line: 26, column: 3, scope: !165)
// CHECK:STDOUT: !171 = !{!166}
// CHECK:STDOUT: !172 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !173 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Int.9452f4c51951679b.Core:Inc.Core.9025b11fc94ef1f2", scope: null, file: !172, line: 396, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !180)
// CHECK:STDOUT: !174 = !DILocalVariable(arg: 1, scope: !173, type: !6)
// CHECK:STDOUT: !176 = !DILocation(line: 398, column: 5, scope: !173)
// CHECK:STDOUT: !177 = !{null, !6, !6}
// CHECK:STDOUT: !178 = !DISubroutineType(types: !177)
// CHECK:STDOUT: !179 = !DILocation(line: 396, column: 3, scope: !173)
// CHECK:STDOUT: !180 = !{!174}
// CHECK:STDOUT: !181 = distinct !DISubprogram(name: "AsSlice", linkageName: "_CAsSlice.Buf.Core.4d9f279dbc2b9f6f", scope: null, file: !45, line: 54, type: !160, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !192)
// CHECK:STDOUT: !182 = !DILocalVariable(arg: 1, scope: !181, type: !12)
// CHECK:STDOUT: !186 = !DILocation(line: 55, column: 32, scope: !181)
// CHECK:STDOUT: !187 = !DILocation(line: 55, column: 42, scope: !181)
// CHECK:STDOUT: !188 = !DILocation(line: 55, column: 12, scope: !181)
// CHECK:STDOUT: !189 = !{!12, !12, !6}
// CHECK:STDOUT: !190 = !DISubroutineType(types: !189)
// CHECK:STDOUT: !191 = !DILocation(line: 55, column: 5, scope: !181)
// CHECK:STDOUT: !192 = !{!182}
// CHECK:STDOUT: !193 = !DIFile(filename: "{{.*}}/prelude/types/slice.carbon", directory: "")
// CHECK:STDOUT: !194 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Slice.Core.4d9f279dbc2b9f6f", scope: null, file: !193, line: 39, type: !33, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !212)
// CHECK:STDOUT: !195 = !DILocalVariable(arg: 1, scope: !194, type: !12)
// CHECK:STDOUT: !196 = !DILocalVariable(arg: 2, scope: !194, type: !6)
// CHECK:STDOUT: !201 = !DILocation(line: 40, column: 9, scope: !194)
// CHECK:STDOUT: !202 = !DILocation(line: 40, column: 18, scope: !194)
// CHECK:STDOUT: !203 = !DILocation(line: 40, column: 23, scope: !194)
// CHECK:STDOUT: !204 = !DILocation(line: 40, column: 8, scope: !194)
// CHECK:STDOUT: !205 = !DILocation(line: 41, column: 7, scope: !194)
// CHECK:STDOUT: !206 = !DILocation(line: 40, column: 5, scope: !194)
// CHECK:STDOUT: !207 = !DILocation(line: 43, column: 27, scope: !194)
// CHECK:STDOUT: !209 = !DILocation(line: 43, column: 13, scope: !194)
// CHECK:STDOUT: !210 = !DILocation(line: 43, column: 12, scope: !194)
// CHECK:STDOUT: !211 = !DILocation(line: 43, column: 5, scope: !194)
// CHECK:STDOUT: !212 = !{!195, !196}
// CHECK:STDOUT: !213 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Buf.a081b942542726db.Core:Destroy.Core.4d9f279dbc2b9f6f", scope: null, file: !45, line: 59, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !219)
// CHECK:STDOUT: !214 = !DILocalVariable(arg: 1, scope: !213, type: !12)
// CHECK:STDOUT: !216 = !DILocation(line: 59, column: 32, scope: !213)
// CHECK:STDOUT: !217 = !DILocation(line: 59, column: 23, scope: !213)
// CHECK:STDOUT: !218 = !DILocation(line: 59, column: 5, scope: !213)
// CHECK:STDOUT: !219 = !{!214}
// CHECK:STDOUT: !220 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.3fc11083d97fac37", scope: null, file: !164, line: 19, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !224)
// CHECK:STDOUT: !221 = !DILocalVariable(arg: 1, scope: !220, type: !12)
// CHECK:STDOUT: !223 = !DILocation(line: 19, column: 3, scope: !220)
// CHECK:STDOUT: !224 = !{!221}
// CHECK:STDOUT: !225 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.542d41f9b830d5be", scope: null, file: !172, line: 331, type: !178, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !232)
// CHECK:STDOUT: !226 = !DILocalVariable(arg: 1, scope: !225, type: !6)
// CHECK:STDOUT: !227 = !DILocalVariable(arg: 2, scope: !225, type: !6)
// CHECK:STDOUT: !228 = !DILocation(line: 0, scope: !225)
// CHECK:STDOUT: !229 = !DILocation(line: 331, column: 3, scope: !225)
// CHECK:STDOUT: !230 = !{!6, !6}
// CHECK:STDOUT: !231 = !DISubroutineType(types: !230)
// CHECK:STDOUT: !232 = !{!226, !227}
// CHECK:STDOUT: !233 = distinct !DISubprogram(name: "UnsafeMake", linkageName: "_CUnsafeMake.Slice.Core.4d9f279dbc2b9f6f", scope: null, file: !193, line: 31, type: !190, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !244)
// CHECK:STDOUT: !234 = !DILocalVariable(arg: 1, scope: !233, type: !12)
// CHECK:STDOUT: !235 = !DILocalVariable(arg: 2, scope: !233, type: !6)
// CHECK:STDOUT: !242 = !DILocation(line: 32, column: 12, scope: !233)
// CHECK:STDOUT: !243 = !DILocation(line: 32, column: 5, scope: !233)
// CHECK:STDOUT: !244 = !{!234, !235}
// CHECK:STDOUT: !245 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.458163fe052e064e", scope: null, file: !172, line: 64, type: !231, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !253)
// CHECK:STDOUT: !246 = !DILocalVariable(arg: 1, scope: !245, type: !6)
// CHECK:STDOUT: !250 = !DILocation(line: 66, column: 17, scope: !245)
// CHECK:STDOUT: !252 = !DILocation(line: 66, column: 5, scope: !245)
// CHECK:STDOUT: !253 = !{!246}
// CHECK:STDOUT: !254 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.9025b11fc94ef1f2", scope: null, file: !172, line: 59, type: !231, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !261)
// CHECK:STDOUT: !255 = !DILocalVariable(arg: 1, scope: !254, type: !6)
// CHECK:STDOUT: !260 = !DILocation(line: 59, column: 28, scope: !254)
// CHECK:STDOUT: !261 = !{!255}
// CHECK:STDOUT:

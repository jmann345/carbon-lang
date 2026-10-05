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
// CHECK:STDOUT: define i32 @_CF.Main(i64 %n) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %b.var = alloca { ptr, i64 }, align 8, !dbg !11
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !11
// CHECK:STDOUT:   call void @_CMake.Buf.Core.553a1f59d1dd8381(ptr %b.var, i64 %n, i32 7), !dbg !12
// CHECK:STDOUT:   call void @_CSet.Buf.Core.553a1f59d1dd8381(ptr %b.var, i64 0, i32 9), !dbg !13
// CHECK:STDOUT:   %Buf.as.IndexWith.impl.At.call = call i32 @"_CAt.Buf.a081b942542726db.Core:IndexWith.f249b435619a5146.Core.553a1f59d1dd8381"(ptr %b.var, i64 0), !dbg !14
// CHECK:STDOUT:   %Buf.Get.call = call i32 @_CGet.Buf.Core.553a1f59d1dd8381(ptr %b.var, i64 1), !dbg !15
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Buf.as.IndexWith.impl.At.call, %Buf.Get.call, !dbg !14
// CHECK:STDOUT:   call void @"_COp.Buf.a081b942542726db.Core:Destroy.Core.553a1f59d1dd8381"(ptr %b.var), !dbg !11
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !22
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.8da6098981b7fee3:core.Destroy.Core"(ptr %self) #0 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.59abebc75eab0036:core.Destroy.Core"(ptr %self) #0 !dbg !31 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5f42013854821c52:core.Destroy.Core"(ptr %self) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.600372e286a55e5e:core.Destroy.Core"(ptr %self) #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.d227e7aede92ee9e:core.Destroy.Core"(ptr %self) #0 !dbg !45 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CMake.Buf.Core.553a1f59d1dd8381(ptr sret({ ptr, i64 }) %return, i64 %size, i32 %fill) #0 !dbg !49 {
// CHECK:STDOUT:   %1 = alloca ptr, align 8, !dbg !55
// CHECK:STDOUT:   %2 = alloca i64, align 8, !dbg !56
// CHECK:STDOUT:   %3 = icmp slt i64 %size, 0, !dbg !57
// CHECK:STDOUT:   br i1 %3, label %4, label %6, !dbg !58
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon, align 8, !dbg !59
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !59
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !59
// CHECK:STDOUT:   %5 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !59
// CHECK:STDOUT:   call void @abort(), !dbg !59
// CHECK:STDOUT:   br label %6, !dbg !60
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %4, %0
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !55
// CHECK:STDOUT:   %heap.bytes.mul = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 %size, i64 4), !dbg !61
// CHECK:STDOUT:   %heap.bytes = extractvalue { i64, i1 } %heap.bytes.mul, 0, !dbg !61
// CHECK:STDOUT:   %heap.bytes.overflow = extractvalue { i64, i1 } %heap.bytes.mul, 1, !dbg !61
// CHECK:STDOUT:   %heap.bytes.is_zero = icmp eq i64 %heap.bytes, 0, !dbg !61
// CHECK:STDOUT:   %heap.bytes.nonzero = select i1 %heap.bytes.is_zero, i64 1, i64 %heap.bytes, !dbg !61
// CHECK:STDOUT:   %heap.block = call ptr @malloc(i64 %heap.bytes.nonzero), !dbg !61
// CHECK:STDOUT:   %heap.result = select i1 %heap.bytes.overflow, ptr null, ptr %heap.block, !dbg !61
// CHECK:STDOUT:   store ptr %heap.result, ptr %1, align 8, !dbg !55
// CHECK:STDOUT:   %7 = load ptr, ptr %1, align 8, !dbg !62
// CHECK:STDOUT:   %8 = icmp eq ptr %7, null, !dbg !63
// CHECK:STDOUT:   br i1 %8, label %9, label %11, !dbg !64
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %6
// CHECK:STDOUT:   %fail_stop.load1 = load { ptr, i64 }, ptr @const.anon.1, align 8, !dbg !65
// CHECK:STDOUT:   %fail_stop.ptr2 = extractvalue { ptr, i64 } %fail_stop.load1, 0, !dbg !65
// CHECK:STDOUT:   %fail_stop.size3 = extractvalue { ptr, i64 } %fail_stop.load1, 1, !dbg !65
// CHECK:STDOUT:   %10 = call i64 @write(i32 2, ptr %fail_stop.ptr2, i64 %fail_stop.size3), !dbg !65
// CHECK:STDOUT:   call void @abort(), !dbg !65
// CHECK:STDOUT:   br label %11, !dbg !66
// CHECK:STDOUT:
// CHECK:STDOUT: 11:                                               ; preds = %9, %6
// CHECK:STDOUT:   %12 = load ptr, ptr %1, align 8, !dbg !67
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %2), !dbg !56
// CHECK:STDOUT:   store i64 0, ptr %2, align 8, !dbg !56
// CHECK:STDOUT:   br label %13, !dbg !68
// CHECK:STDOUT:
// CHECK:STDOUT: 13:                                               ; preds = %16, %11
// CHECK:STDOUT:   %14 = load i64, ptr %2, align 8, !dbg !69
// CHECK:STDOUT:   %15 = icmp slt i64 %14, %size, !dbg !69
// CHECK:STDOUT:   br i1 %15, label %16, label %18, !dbg !68
// CHECK:STDOUT:
// CHECK:STDOUT: 16:                                               ; preds = %13
// CHECK:STDOUT:   %17 = load i64, ptr %2, align 8, !dbg !70
// CHECK:STDOUT:   %ptr.offset = getelementptr inbounds i32, ptr %12, i64 %17, !dbg !71
// CHECK:STDOUT:   store i32 %fill, ptr %ptr.offset, align 4, !dbg !72
// CHECK:STDOUT:   call void @"_COp.Int.9452f4c51951679b.Core:Inc.Core.9025b11fc94ef1f2"(ptr %2), !dbg !73
// CHECK:STDOUT:   br label %13, !dbg !74
// CHECK:STDOUT:
// CHECK:STDOUT: 18:                                               ; preds = %13
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 0, !dbg !75
// CHECK:STDOUT:   store ptr %12, ptr %ptr, align 8, !dbg !75
// CHECK:STDOUT:   %size4 = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 1, !dbg !75
// CHECK:STDOUT:   store i64 %size, ptr %size4, align 8, !dbg !75
// CHECK:STDOUT:   call void @"_COp.5f42013854821c52:core.Destroy.Core"(ptr %2), !dbg !56
// CHECK:STDOUT:   call void @"_COp.59abebc75eab0036:core.Destroy.Core"(ptr %1), !dbg !55
// CHECK:STDOUT:   ret void, !dbg !76
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSet.Buf.Core.553a1f59d1dd8381(ptr %self, i64 %i, i32 %value) #0 !dbg !77 {
// CHECK:STDOUT:   %1 = icmp slt i64 %i, 0, !dbg !84
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !84
// CHECK:STDOUT:   br i1 %2, label %3, label %6, !dbg !84
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !85
// CHECK:STDOUT:   %4 = load i64, ptr %size, align 8, !dbg !85
// CHECK:STDOUT:   %5 = icmp sge i64 %i, %4, !dbg !86
// CHECK:STDOUT:   br label %6, !dbg !84
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %3, %0
// CHECK:STDOUT:   %7 = phi i1 [ true, %0 ], [ %5, %3 ]
// CHECK:STDOUT:   br i1 %7, label %8, label %10, !dbg !87
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %6
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon.2, align 8, !dbg !88
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !88
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !88
// CHECK:STDOUT:   %9 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !88
// CHECK:STDOUT:   call void @abort(), !dbg !88
// CHECK:STDOUT:   br label %10, !dbg !89
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %8, %6
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !90
// CHECK:STDOUT:   %11 = load ptr, ptr %ptr, align 8, !dbg !90
// CHECK:STDOUT:   %ptr.offset = getelementptr inbounds i32, ptr %11, i64 %i, !dbg !91
// CHECK:STDOUT:   store i32 %value, ptr %ptr.offset, align 4, !dbg !92
// CHECK:STDOUT:   ret void, !dbg !93
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CAt.Buf.a081b942542726db.Core:IndexWith.f249b435619a5146.Core.553a1f59d1dd8381"(ptr %self, i64 %subscript) #0 !dbg !94 {
// CHECK:STDOUT:   %1 = call i32 @_CGet.Buf.Core.553a1f59d1dd8381(ptr %self, i64 %subscript), !dbg !100
// CHECK:STDOUT:   ret i32 %1, !dbg !101
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Buf.Core.553a1f59d1dd8381(ptr %self, i64 %i) #0 !dbg !102 {
// CHECK:STDOUT:   %temp = alloca { ptr, i64 }, align 8, !dbg !106
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !106
// CHECK:STDOUT:   call void @_CAsSlice.Buf.Core.553a1f59d1dd8381(ptr %temp, ptr %self), !dbg !106
// CHECK:STDOUT:   %1 = call i32 @_CGet.Slice.Core.553a1f59d1dd8381(ptr %temp, i64 %i), !dbg !106
// CHECK:STDOUT:   call void @"_COp.d227e7aede92ee9e:core.Destroy.Core"(ptr %temp), !dbg !106
// CHECK:STDOUT:   ret i32 %1, !dbg !107
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.Buf.a081b942542726db.Core:Destroy.Core.553a1f59d1dd8381"(ptr %self) #0 !dbg !108 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !111
// CHECK:STDOUT:   %1 = load ptr, ptr %ptr, align 8, !dbg !111
// CHECK:STDOUT:   call void @free(ptr %1), !dbg !112
// CHECK:STDOUT:   ret void, !dbg !113
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
// CHECK:STDOUT: define linkonce_odr void @"_COp.Int.9452f4c51951679b.Core:Inc.Core.9025b11fc94ef1f2"(ptr %self) #0 !dbg !114 {
// CHECK:STDOUT:   call void @"_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.542d41f9b830d5be"(ptr %self, i64 1), !dbg !118
// CHECK:STDOUT:   ret void, !dbg !119
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CAsSlice.Buf.Core.553a1f59d1dd8381(ptr sret({ ptr, i64 }) %return, ptr %self) #0 !dbg !120 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !125
// CHECK:STDOUT:   %1 = load ptr, ptr %ptr, align 8, !dbg !125
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !126
// CHECK:STDOUT:   %2 = load i64, ptr %size, align 8, !dbg !126
// CHECK:STDOUT:   call void @_CUnsafeMake.Slice.Core.553a1f59d1dd8381(ptr %return, ptr %1, i64 %2), !dbg !127
// CHECK:STDOUT:   ret void, !dbg !128
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Slice.Core.553a1f59d1dd8381(ptr %self, i64 %i) #0 !dbg !129 {
// CHECK:STDOUT:   %1 = icmp slt i64 %i, 0, !dbg !134
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !134
// CHECK:STDOUT:   br i1 %2, label %3, label %6, !dbg !134
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !135
// CHECK:STDOUT:   %4 = load i64, ptr %size, align 8, !dbg !135
// CHECK:STDOUT:   %5 = icmp sge i64 %i, %4, !dbg !136
// CHECK:STDOUT:   br label %6, !dbg !134
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %3, %0
// CHECK:STDOUT:   %7 = phi i1 [ true, %0 ], [ %5, %3 ]
// CHECK:STDOUT:   br i1 %7, label %8, label %10, !dbg !137
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %6
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon.3, align 8, !dbg !138
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !138
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !138
// CHECK:STDOUT:   %9 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !138
// CHECK:STDOUT:   call void @abort(), !dbg !138
// CHECK:STDOUT:   br label %10, !dbg !139
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %8, %6
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !140
// CHECK:STDOUT:   %11 = load ptr, ptr %ptr, align 8, !dbg !140
// CHECK:STDOUT:   %ptr.offset = getelementptr inbounds i32, ptr %11, i64 %i, !dbg !141
// CHECK:STDOUT:   %12 = load i32, ptr %ptr.offset, align 4, !dbg !142
// CHECK:STDOUT:   ret i32 %12, !dbg !143
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @free(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.542d41f9b830d5be"(ptr %self, i64 %other) #4 !dbg !144 {
// CHECK:STDOUT:   %1 = call i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.458163fe052e064e"(i64 %other), !dbg !150
// CHECK:STDOUT:   %2 = load i64, ptr %self, align 8, !dbg !151
// CHECK:STDOUT:   %3 = add i64 %2, %1, !dbg !151
// CHECK:STDOUT:   store i64 %3, ptr %self, align 8, !dbg !151
// CHECK:STDOUT:   ret void, !dbg !151
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CUnsafeMake.Slice.Core.553a1f59d1dd8381(ptr sret({ ptr, i64 }) %return, ptr %p, i64 %size) #0 !dbg !152 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 0, !dbg !158
// CHECK:STDOUT:   store ptr %p, ptr %ptr, align 8, !dbg !158
// CHECK:STDOUT:   %size1 = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 1, !dbg !158
// CHECK:STDOUT:   store i64 %size, ptr %size1, align 8, !dbg !158
// CHECK:STDOUT:   ret void, !dbg !159
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.458163fe052e064e"(i64 %self) #0 !dbg !160 {
// CHECK:STDOUT:   %1 = call i64 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.9025b11fc94ef1f2"(i64 %self), !dbg !165
// CHECK:STDOUT:   ret i64 %1, !dbg !166
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.9025b11fc94ef1f2"(i64 %self) #0 !dbg !167 {
// CHECK:STDOUT:   ret i64 %self, !dbg !170
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CGet.Buf.Core.553a1f59d1dd8381, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 0, 3, 2, 1 }
// CHECK:STDOUT: uselistorder ptr @abort, { 0, 3, 2, 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #2 = { noreturn }
// CHECK:STDOUT: attributes #3 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
// CHECK:STDOUT: attributes #4 = { alwaysinline nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "buf.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !1, line: 18, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 19, column: 3, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 19, column: 26, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 20, column: 3, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 21, column: 10, scope: !4)
// CHECK:STDOUT: !15 = !DILocation(line: 21, column: 17, scope: !4)
// CHECK:STDOUT: !16 = !DILocation(line: 21, column: 3, scope: !4)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !20)
// CHECK:STDOUT: !18 = !DISubroutineType(types: !19)
// CHECK:STDOUT: !19 = !{null, !7}
// CHECK:STDOUT: !20 = !{!21}
// CHECK:STDOUT: !21 = !DILocalVariable(arg: 1, scope: !17, type: !7)
// CHECK:STDOUT: !22 = !DILocation(line: 19, column: 10, scope: !17)
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "Op", linkageName: "_COp.8da6098981b7fee3:core.Destroy.Core", scope: null, file: !24, line: 32, type: !25, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !28)
// CHECK:STDOUT: !24 = !DIFile(filename: "{{.*}}/prelude/types/buf.carbon", directory: "")
// CHECK:STDOUT: !25 = !DISubroutineType(types: !26)
// CHECK:STDOUT: !26 = !{null, !27}
// CHECK:STDOUT: !27 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !28 = !{!29}
// CHECK:STDOUT: !29 = !DILocalVariable(arg: 1, scope: !23, type: !27)
// CHECK:STDOUT: !30 = !DILocation(line: 32, column: 5, scope: !23)
// CHECK:STDOUT: !31 = distinct !DISubprogram(name: "Op", linkageName: "_COp.59abebc75eab0036:core.Destroy.Core", scope: null, file: !24, line: 32, type: !25, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !32)
// CHECK:STDOUT: !32 = !{!33}
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !31, type: !27)
// CHECK:STDOUT: !34 = !DILocation(line: 32, column: 5, scope: !31)
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5f42013854821c52:core.Destroy.Core", scope: null, file: !24, line: 45, type: !36, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !38)
// CHECK:STDOUT: !36 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !37 = !{null, !8}
// CHECK:STDOUT: !38 = !{!39}
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !35, type: !8)
// CHECK:STDOUT: !40 = !DILocation(line: 45, column: 38, scope: !35)
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "Op", linkageName: "_COp.600372e286a55e5e:core.Destroy.Core", scope: null, file: !24, line: 45, type: !25, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !42)
// CHECK:STDOUT: !42 = !{!43}
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !41, type: !27)
// CHECK:STDOUT: !44 = !DILocation(line: 45, column: 38, scope: !41)
// CHECK:STDOUT: !45 = distinct !DISubprogram(name: "Op", linkageName: "_COp.d227e7aede92ee9e:core.Destroy.Core", scope: null, file: !24, line: 45, type: !25, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !46)
// CHECK:STDOUT: !46 = !{!47}
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !45, type: !27)
// CHECK:STDOUT: !48 = !DILocation(line: 45, column: 38, scope: !45)
// CHECK:STDOUT: !49 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.Buf.Core.553a1f59d1dd8381", scope: null, file: !24, line: 28, type: !50, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !52)
// CHECK:STDOUT: !50 = !DISubroutineType(types: !51)
// CHECK:STDOUT: !51 = !{!27, !8, !7}
// CHECK:STDOUT: !52 = !{!53, !54}
// CHECK:STDOUT: !53 = !DILocalVariable(arg: 1, scope: !49, type: !8)
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 2, scope: !49, type: !7)
// CHECK:STDOUT: !55 = !DILocation(line: 32, column: 5, scope: !49)
// CHECK:STDOUT: !56 = !DILocation(line: 37, column: 5, scope: !49)
// CHECK:STDOUT: !57 = !DILocation(line: 29, column: 9, scope: !49)
// CHECK:STDOUT: !58 = !DILocation(line: 29, column: 8, scope: !49)
// CHECK:STDOUT: !59 = !DILocation(line: 30, column: 7, scope: !49)
// CHECK:STDOUT: !60 = !DILocation(line: 29, column: 5, scope: !49)
// CHECK:STDOUT: !61 = !DILocation(line: 32, column: 38, scope: !49)
// CHECK:STDOUT: !62 = !DILocation(line: 33, column: 23, scope: !49)
// CHECK:STDOUT: !63 = !DILocation(line: 33, column: 9, scope: !49)
// CHECK:STDOUT: !64 = !DILocation(line: 33, column: 8, scope: !49)
// CHECK:STDOUT: !65 = !DILocation(line: 34, column: 7, scope: !49)
// CHECK:STDOUT: !66 = !DILocation(line: 33, column: 5, scope: !49)
// CHECK:STDOUT: !67 = !DILocation(line: 36, column: 19, scope: !49)
// CHECK:STDOUT: !68 = !DILocation(line: 38, column: 11, scope: !49)
// CHECK:STDOUT: !69 = !DILocation(line: 38, column: 12, scope: !49)
// CHECK:STDOUT: !70 = !DILocation(line: 39, column: 27, scope: !49)
// CHECK:STDOUT: !71 = !DILocation(line: 39, column: 8, scope: !49)
// CHECK:STDOUT: !72 = !DILocation(line: 39, column: 7, scope: !49)
// CHECK:STDOUT: !73 = !DILocation(line: 40, column: 7, scope: !49)
// CHECK:STDOUT: !74 = !DILocation(line: 38, column: 5, scope: !49)
// CHECK:STDOUT: !75 = !DILocation(line: 42, column: 12, scope: !49)
// CHECK:STDOUT: !76 = !DILocation(line: 42, column: 5, scope: !49)
// CHECK:STDOUT: !77 = distinct !DISubprogram(name: "Set", linkageName: "_CSet.Buf.Core.553a1f59d1dd8381", scope: null, file: !24, line: 48, type: !78, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !80)
// CHECK:STDOUT: !78 = !DISubroutineType(types: !79)
// CHECK:STDOUT: !79 = !{null, !27, !8, !7}
// CHECK:STDOUT: !80 = !{!81, !82, !83}
// CHECK:STDOUT: !81 = !DILocalVariable(arg: 1, scope: !77, type: !27)
// CHECK:STDOUT: !82 = !DILocalVariable(arg: 2, scope: !77, type: !8)
// CHECK:STDOUT: !83 = !DILocalVariable(arg: 3, scope: !77, type: !7)
// CHECK:STDOUT: !84 = !DILocation(line: 49, column: 9, scope: !77)
// CHECK:STDOUT: !85 = !DILocation(line: 49, column: 23, scope: !77)
// CHECK:STDOUT: !86 = !DILocation(line: 49, column: 18, scope: !77)
// CHECK:STDOUT: !87 = !DILocation(line: 49, column: 8, scope: !77)
// CHECK:STDOUT: !88 = !DILocation(line: 50, column: 7, scope: !77)
// CHECK:STDOUT: !89 = !DILocation(line: 49, column: 5, scope: !77)
// CHECK:STDOUT: !90 = !DILocation(line: 52, column: 20, scope: !77)
// CHECK:STDOUT: !91 = !DILocation(line: 52, column: 6, scope: !77)
// CHECK:STDOUT: !92 = !DILocation(line: 52, column: 5, scope: !77)
// CHECK:STDOUT: !93 = !DILocation(line: 48, column: 3, scope: !77)
// CHECK:STDOUT: !94 = distinct !DISubprogram(name: "At", linkageName: "_CAt.Buf.a081b942542726db.Core:IndexWith.f249b435619a5146.Core.553a1f59d1dd8381", scope: null, file: !24, line: 73, type: !95, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !97)
// CHECK:STDOUT: !95 = !DISubroutineType(types: !96)
// CHECK:STDOUT: !96 = !{!7, !27, !8}
// CHECK:STDOUT: !97 = !{!98, !99}
// CHECK:STDOUT: !98 = !DILocalVariable(arg: 1, scope: !94, type: !27)
// CHECK:STDOUT: !99 = !DILocalVariable(arg: 2, scope: !94, type: !8)
// CHECK:STDOUT: !100 = !DILocation(line: 73, column: 45, scope: !94)
// CHECK:STDOUT: !101 = !DILocation(line: 73, column: 38, scope: !94)
// CHECK:STDOUT: !102 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Buf.Core.553a1f59d1dd8381", scope: null, file: !24, line: 45, type: !95, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !103)
// CHECK:STDOUT: !103 = !{!104, !105}
// CHECK:STDOUT: !104 = !DILocalVariable(arg: 1, scope: !102, type: !27)
// CHECK:STDOUT: !105 = !DILocalVariable(arg: 2, scope: !102, type: !8)
// CHECK:STDOUT: !106 = !DILocation(line: 45, column: 38, scope: !102)
// CHECK:STDOUT: !107 = !DILocation(line: 45, column: 31, scope: !102)
// CHECK:STDOUT: !108 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Buf.a081b942542726db.Core:Destroy.Core.553a1f59d1dd8381", scope: null, file: !24, line: 59, type: !25, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !109)
// CHECK:STDOUT: !109 = !{!110}
// CHECK:STDOUT: !110 = !DILocalVariable(arg: 1, scope: !108, type: !27)
// CHECK:STDOUT: !111 = !DILocation(line: 59, column: 32, scope: !108)
// CHECK:STDOUT: !112 = !DILocation(line: 59, column: 23, scope: !108)
// CHECK:STDOUT: !113 = !DILocation(line: 59, column: 5, scope: !108)
// CHECK:STDOUT: !114 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Int.9452f4c51951679b.Core:Inc.Core.9025b11fc94ef1f2", scope: null, file: !115, line: 396, type: !36, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !116)
// CHECK:STDOUT: !115 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !116 = !{!117}
// CHECK:STDOUT: !117 = !DILocalVariable(arg: 1, scope: !114, type: !8)
// CHECK:STDOUT: !118 = !DILocation(line: 398, column: 5, scope: !114)
// CHECK:STDOUT: !119 = !DILocation(line: 396, column: 3, scope: !114)
// CHECK:STDOUT: !120 = distinct !DISubprogram(name: "AsSlice", linkageName: "_CAsSlice.Buf.Core.553a1f59d1dd8381", scope: null, file: !24, line: 54, type: !121, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !123)
// CHECK:STDOUT: !121 = !DISubroutineType(types: !122)
// CHECK:STDOUT: !122 = !{!27, !27}
// CHECK:STDOUT: !123 = !{!124}
// CHECK:STDOUT: !124 = !DILocalVariable(arg: 1, scope: !120, type: !27)
// CHECK:STDOUT: !125 = !DILocation(line: 55, column: 32, scope: !120)
// CHECK:STDOUT: !126 = !DILocation(line: 55, column: 42, scope: !120)
// CHECK:STDOUT: !127 = !DILocation(line: 55, column: 12, scope: !120)
// CHECK:STDOUT: !128 = !DILocation(line: 55, column: 5, scope: !120)
// CHECK:STDOUT: !129 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Slice.Core.553a1f59d1dd8381", scope: null, file: !130, line: 39, type: !95, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !131)
// CHECK:STDOUT: !130 = !DIFile(filename: "{{.*}}/prelude/types/slice.carbon", directory: "")
// CHECK:STDOUT: !131 = !{!132, !133}
// CHECK:STDOUT: !132 = !DILocalVariable(arg: 1, scope: !129, type: !27)
// CHECK:STDOUT: !133 = !DILocalVariable(arg: 2, scope: !129, type: !8)
// CHECK:STDOUT: !134 = !DILocation(line: 40, column: 9, scope: !129)
// CHECK:STDOUT: !135 = !DILocation(line: 40, column: 23, scope: !129)
// CHECK:STDOUT: !136 = !DILocation(line: 40, column: 18, scope: !129)
// CHECK:STDOUT: !137 = !DILocation(line: 40, column: 8, scope: !129)
// CHECK:STDOUT: !138 = !DILocation(line: 41, column: 7, scope: !129)
// CHECK:STDOUT: !139 = !DILocation(line: 40, column: 5, scope: !129)
// CHECK:STDOUT: !140 = !DILocation(line: 43, column: 27, scope: !129)
// CHECK:STDOUT: !141 = !DILocation(line: 43, column: 13, scope: !129)
// CHECK:STDOUT: !142 = !DILocation(line: 43, column: 12, scope: !129)
// CHECK:STDOUT: !143 = !DILocation(line: 43, column: 5, scope: !129)
// CHECK:STDOUT: !144 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.542d41f9b830d5be", scope: null, file: !115, line: 331, type: !145, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !147)
// CHECK:STDOUT: !145 = !DISubroutineType(types: !146)
// CHECK:STDOUT: !146 = !{null, !8, !8}
// CHECK:STDOUT: !147 = !{!148, !149}
// CHECK:STDOUT: !148 = !DILocalVariable(arg: 1, scope: !144, type: !8)
// CHECK:STDOUT: !149 = !DILocalVariable(arg: 2, scope: !144, type: !8)
// CHECK:STDOUT: !150 = !DILocation(line: 0, scope: !144)
// CHECK:STDOUT: !151 = !DILocation(line: 331, column: 3, scope: !144)
// CHECK:STDOUT: !152 = distinct !DISubprogram(name: "UnsafeMake", linkageName: "_CUnsafeMake.Slice.Core.553a1f59d1dd8381", scope: null, file: !130, line: 31, type: !153, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !155)
// CHECK:STDOUT: !153 = !DISubroutineType(types: !154)
// CHECK:STDOUT: !154 = !{!27, !27, !8}
// CHECK:STDOUT: !155 = !{!156, !157}
// CHECK:STDOUT: !156 = !DILocalVariable(arg: 1, scope: !152, type: !27)
// CHECK:STDOUT: !157 = !DILocalVariable(arg: 2, scope: !152, type: !8)
// CHECK:STDOUT: !158 = !DILocation(line: 32, column: 12, scope: !152)
// CHECK:STDOUT: !159 = !DILocation(line: 32, column: 5, scope: !152)
// CHECK:STDOUT: !160 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.458163fe052e064e", scope: null, file: !115, line: 64, type: !161, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !163)
// CHECK:STDOUT: !161 = !DISubroutineType(types: !162)
// CHECK:STDOUT: !162 = !{!8, !8}
// CHECK:STDOUT: !163 = !{!164}
// CHECK:STDOUT: !164 = !DILocalVariable(arg: 1, scope: !160, type: !8)
// CHECK:STDOUT: !165 = !DILocation(line: 66, column: 17, scope: !160)
// CHECK:STDOUT: !166 = !DILocation(line: 66, column: 5, scope: !160)
// CHECK:STDOUT: !167 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.9025b11fc94ef1f2", scope: null, file: !115, line: 59, type: !161, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !168)
// CHECK:STDOUT: !168 = !{!169}
// CHECK:STDOUT: !169 = !DILocalVariable(arg: 1, scope: !167, type: !8)
// CHECK:STDOUT: !170 = !DILocation(line: 59, column: 28, scope: !167)
// CHECK:STDOUT:

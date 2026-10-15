// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/slice/buf_field.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/slice/buf_field.carbon

// Fork (UA-2, fork/upstream/plan.md §0.6 W-108 row): a `Core.Buf(i32)` held
// in a class FIELD — the arbiter of W-108 ("A `Core.Buf` stored in a field is
// not freed", docs/design/slices.md, 0.1 limits). Whether `call void
// @free(ptr ...)` is reached from the owner's destroy sequence is decided by
// this golden's fill, never asserted (R-3).

// --- synthesized_owner.carbon

library "[[@TEST_NAME]]";

// `Owner` declares no `Destroy` impl. Predicted: at `F`'s exit a call to
// `Owner`'s synthesized `_CSelfDestruct.<hash>:core.Destroy.Core` on
// `%o.var`; its `_CSubobjectDestroy.<hash>:core.Destroy.Core` (upstream's
// field walk, PR 7840) calls `Buf(i32)`'s `_CSelfDestruct.Destroy.Core.<hash>`
// on the field, which calls the declared `_COp.Buf...:Destroy.Core...` whose
// body is `call void @free`. So `free` IS reached in this module — if the fill
// agrees, W-108 is discharged for the aggregate-without-impl shapes.
class Owner {
  var b: Core.Buf(i32);
}

fn F(n: i64) -> i32 {
  var o: Owner = {.b = Core.Buf(i32).Make(n, 7)};
  return o.b.Get(0);
}

// --- declared_owner.carbon

library "[[@TEST_NAME]]";

// `OwnerWithOp` declares its own `Destroy` impl (D-SL-16 selects it).
// Predicted: at `G`'s exit a call to `_CSelfDestruct.Destroy.Core.<hash>` (the
// interface's `final` `SelfDestruct` specialized to `OwnerWithOp`) on
// `%o.var`, which calls the declared `_COp.OwnerWithOp...:Destroy.Core...`
// (`ret void`) and the interface's `final` placeholder
// `_CSubobjectDestroy.Destroy.Core.<hash>` (`ret void`, upstream PR 7773's
// stated limit). So NO `free` in this module and no `_COp.Buf...` define:
// the block `malloc`ed by `Make` leaks — the W-108 limit that stays for owners
// with a user-declared impl.
class OwnerWithOp {
  var b: Core.Buf(i32);

  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

fn G(n: i64) -> i32 {
  var o: OwnerWithOp = {.b = Core.Buf(i32).Make(n, 7)};
  return o.b.Get(0);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'synthesized_owner.carbon'
// CHECK:STDOUT: source_filename = "synthesized_owner.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [48 x i8] c"carbon: Core.Buf size is negative; terminating\0A\00", align 1
// CHECK:STDOUT: @1 = private unnamed_addr constant [45 x i8] c"carbon: heap allocation failed; terminating\0A\00", align 1
// CHECK:STDOUT: @2 = private unnamed_addr constant [51 x i8] c"carbon: Core.Buf index out of bounds; terminating\0A\00", align 1
// CHECK:STDOUT: @const.anon = internal constant { ptr, i64 } { ptr @0, i64 47 }
// CHECK:STDOUT: @const.anon.1 = internal constant { ptr, i64 } { ptr @1, i64 44 }
// CHECK:STDOUT: @3 = private unnamed_addr constant [53 x i8] c"carbon: Core.Slice index out of bounds; terminating\0A\00", align 1
// CHECK:STDOUT: @4 = private unnamed_addr constant [62 x i8] c"carbon: Core.Slice.Subslice range out of bounds; terminating\0A\00", align 1
// CHECK:STDOUT: @const.anon.2 = internal constant { ptr, i64 } { ptr @3, i64 52 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CF.Main(i64 %n) #0 !dbg !21 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %o.var = alloca { { ptr, i64 } }, align 8, !dbg !26
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %o.var), !dbg !26
// CHECK:STDOUT:   %.loc16_48.1.b = getelementptr inbounds nuw { { ptr, i64 } }, ptr %o.var, i32 0, i32 0, !dbg !28
// CHECK:STDOUT:   call void @_CMake.Buf.Core.4d9f279dbc2b9f6f(ptr %.loc16_48.1.b, i64 %n, i32 7), !dbg !29
// CHECK:STDOUT:   %.loc17_11.1.b = getelementptr inbounds nuw { { ptr, i64 } }, ptr %o.var, i32 0, i32 0, !dbg !33
// CHECK:STDOUT:   %Buf.Get.call = call i32 @_CGet.Buf.Core.4d9f279dbc2b9f6f(ptr %.loc17_11.1.b, i64 0), !dbg !33
// CHECK:STDOUT:   call void @"_CSelfDestruct.a97b2b12de121bed:core.Destroy.Core"(ptr %o.var), !dbg !26
// CHECK:STDOUT:   ret i32 %Buf.Get.call, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.7a92959e16736fc7:core.Destroy.Core"(ptr %self) #0 !dbg !38 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.7490bb5cc2af3be6:core.Destroy.Core"(ptr %self) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_3.1.b = getelementptr inbounds nuw { { ptr, i64 } }, ptr %self, i32 0, i32 0, !dbg !44
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.3fc11083d97fac37(ptr %.loc16_3.1.b), !dbg !44
// CHECK:STDOUT:   ret void, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.7490bb5cc2af3be6:core.Destroy.Core"(ptr %self) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.7490bb5cc2af3be6:core.Destroy.Core"(ptr %self), !dbg !48
// CHECK:STDOUT:   ret void, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a97b2b12de121bed:core.Destroy.Core"(ptr %self) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_3.1.b = getelementptr inbounds nuw { { ptr, i64 } }, ptr %self, i32 0, i32 0, !dbg !52
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.3fc11083d97fac37(ptr %.loc16_3.1.b), !dbg !52
// CHECK:STDOUT:   ret void, !dbg !52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a97b2b12de121bed:core.Destroy.Core"(ptr %self) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a97b2b12de121bed:core.Destroy.Core"(ptr %self), !dbg !56
// CHECK:STDOUT:   ret void, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %self) #0 !dbg !59 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !61
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0f866e2c9731ba7d:core.Destroy.Core"(ptr %self) #0 !dbg !63 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.729fca203337f92a:core.Destroy.Core"(ptr %self) #0 !dbg !67 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !71 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !73
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.0cc0bac3871fce6b:core.Destroy.Core"(ptr %self) #0 !dbg !75 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.1.size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !77
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.1.size), !dbg !77
// CHECK:STDOUT:   %.2.ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !77
// CHECK:STDOUT:   call void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %.2.ptr), !dbg !77
// CHECK:STDOUT:   ret void, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0cc0bac3871fce6b:core.Destroy.Core"(ptr %self) #0 !dbg !79 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.0cc0bac3871fce6b:core.Destroy.Core"(ptr %self), !dbg !81
// CHECK:STDOUT:   ret void, !dbg !81
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.079d89ca1000ddb5:core.Destroy.Core"(ptr %self) #0 !dbg !83 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.1.size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !85
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.1.size), !dbg !85
// CHECK:STDOUT:   %.2.ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !85
// CHECK:STDOUT:   call void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %.2.ptr), !dbg !85
// CHECK:STDOUT:   ret void, !dbg !85
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.079d89ca1000ddb5:core.Destroy.Core"(ptr %self) #0 !dbg !87 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.079d89ca1000ddb5:core.Destroy.Core"(ptr %self), !dbg !89
// CHECK:STDOUT:   ret void, !dbg !89
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CMake.Buf.Core.4d9f279dbc2b9f6f(ptr sret({ ptr, i64 }) %return, i64 %size, i32 %fill) #0 !dbg !92 {
// CHECK:STDOUT:   %1 = alloca ptr, align 8, !dbg !103
// CHECK:STDOUT:   %2 = alloca i64, align 8, !dbg !115
// CHECK:STDOUT:   %3 = icmp slt i64 %size, 0, !dbg !99
// CHECK:STDOUT:   br i1 %3, label %4, label %6, !dbg !100
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon, align 8, !dbg !101
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !101
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !101
// CHECK:STDOUT:   %5 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !101
// CHECK:STDOUT:   call void @abort(), !dbg !101
// CHECK:STDOUT:   br label %6, !dbg !102
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %4, %0
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !103
// CHECK:STDOUT:   %heap.bytes.mul = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 %size, i64 4), !dbg !105
// CHECK:STDOUT:   %heap.bytes = extractvalue { i64, i1 } %heap.bytes.mul, 0, !dbg !105
// CHECK:STDOUT:   %heap.bytes.overflow = extractvalue { i64, i1 } %heap.bytes.mul, 1, !dbg !105
// CHECK:STDOUT:   %heap.bytes.is_zero = icmp eq i64 %heap.bytes, 0, !dbg !105
// CHECK:STDOUT:   %heap.bytes.nonzero = select i1 %heap.bytes.is_zero, i64 1, i64 %heap.bytes, !dbg !105
// CHECK:STDOUT:   %heap.block = call ptr @malloc(i64 %heap.bytes.nonzero), !dbg !105
// CHECK:STDOUT:   %heap.result = select i1 %heap.bytes.overflow, ptr null, ptr %heap.block, !dbg !105
// CHECK:STDOUT:   store ptr %heap.result, ptr %1, align 8, !dbg !103
// CHECK:STDOUT:   %7 = load ptr, ptr %1, align 8, !dbg !107
// CHECK:STDOUT:   %8 = icmp eq ptr %7, null, !dbg !108
// CHECK:STDOUT:   br i1 %8, label %9, label %11, !dbg !109
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %6
// CHECK:STDOUT:   %fail_stop.load1 = load { ptr, i64 }, ptr @const.anon.1, align 8, !dbg !110
// CHECK:STDOUT:   %fail_stop.ptr2 = extractvalue { ptr, i64 } %fail_stop.load1, 0, !dbg !110
// CHECK:STDOUT:   %fail_stop.size3 = extractvalue { ptr, i64 } %fail_stop.load1, 1, !dbg !110
// CHECK:STDOUT:   %10 = call i64 @write(i32 2, ptr %fail_stop.ptr2, i64 %fail_stop.size3), !dbg !110
// CHECK:STDOUT:   call void @abort(), !dbg !110
// CHECK:STDOUT:   br label %11, !dbg !111
// CHECK:STDOUT:
// CHECK:STDOUT: 11:                                               ; preds = %9, %6
// CHECK:STDOUT:   %12 = load ptr, ptr %1, align 8, !dbg !112
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %2), !dbg !115
// CHECK:STDOUT:   store i64 0, ptr %2, align 8, !dbg !115
// CHECK:STDOUT:   br label %13, !dbg !117
// CHECK:STDOUT:
// CHECK:STDOUT: 13:                                               ; preds = %16, %11
// CHECK:STDOUT:   %14 = load i64, ptr %2, align 8, !dbg !118
// CHECK:STDOUT:   %15 = icmp slt i64 %14, %size, !dbg !118
// CHECK:STDOUT:   br i1 %15, label %16, label %18, !dbg !117
// CHECK:STDOUT:
// CHECK:STDOUT: 16:                                               ; preds = %13
// CHECK:STDOUT:   %17 = load i64, ptr %2, align 8, !dbg !121
// CHECK:STDOUT:   %ptr.offset = getelementptr inbounds i32, ptr %12, i64 %17, !dbg !122
// CHECK:STDOUT:   store i32 %fill, ptr %ptr.offset, align 4, !dbg !123
// CHECK:STDOUT:   call void @"_COp.Int.9452f4c51951679b.Core:Inc.Core.9025b11fc94ef1f2"(ptr %2), !dbg !126
// CHECK:STDOUT:   br label %13, !dbg !127
// CHECK:STDOUT:
// CHECK:STDOUT: 18:                                               ; preds = %13
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 0, !dbg !130
// CHECK:STDOUT:   store ptr %12, ptr %ptr, align 8, !dbg !130
// CHECK:STDOUT:   %size4 = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 1, !dbg !130
// CHECK:STDOUT:   store i64 %size, ptr %size4, align 8, !dbg !130
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %2), !dbg !115
// CHECK:STDOUT:   call void @"_CSelfDestruct.729fca203337f92a:core.Destroy.Core"(ptr %1), !dbg !103
// CHECK:STDOUT:   ret void, !dbg !131
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Buf.Core.4d9f279dbc2b9f6f(ptr %self, i64 %i) #0 !dbg !133 {
// CHECK:STDOUT:   %temp = alloca { ptr, i64 }, align 8, !dbg !140
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !140
// CHECK:STDOUT:   call void @_CAsSlice.Buf.Core.4d9f279dbc2b9f6f(ptr %temp, ptr %self), !dbg !140
// CHECK:STDOUT:   %1 = call i32 @_CGet.Slice.Core.4d9f279dbc2b9f6f(ptr %temp, i64 %i), !dbg !140
// CHECK:STDOUT:   call void @"_CSelfDestruct.079d89ca1000ddb5:core.Destroy.Core"(ptr %temp), !dbg !140
// CHECK:STDOUT:   ret i32 %1, !dbg !144
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.3fc11083d97fac37(ptr %self) #0 !dbg !147 {
// CHECK:STDOUT:   call void @"_COp.Buf.a081b942542726db.Core:Destroy.Core.4d9f279dbc2b9f6f"(ptr %self), !dbg !150
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.3fc11083d97fac37(ptr %self), !dbg !151
// CHECK:STDOUT:   ret void, !dbg !152
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
// CHECK:STDOUT: define linkonce_odr void @"_COp.Int.9452f4c51951679b.Core:Inc.Core.9025b11fc94ef1f2"(ptr %self) #0 !dbg !155 {
// CHECK:STDOUT:   call void @"_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.542d41f9b830d5be"(ptr %self, i64 1), !dbg !158
// CHECK:STDOUT:   ret void, !dbg !161
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CAsSlice.Buf.Core.4d9f279dbc2b9f6f(ptr sret({ ptr, i64 }) %return, ptr %self) #0 !dbg !163 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !168
// CHECK:STDOUT:   %1 = load ptr, ptr %ptr, align 8, !dbg !168
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !169
// CHECK:STDOUT:   %2 = load i64, ptr %size, align 8, !dbg !169
// CHECK:STDOUT:   call void @_CUnsafeMake.Slice.Core.4d9f279dbc2b9f6f(ptr %return, ptr %1, i64 %2), !dbg !170
// CHECK:STDOUT:   ret void, !dbg !173
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Slice.Core.4d9f279dbc2b9f6f(ptr %self, i64 %i) #0 !dbg !176 {
// CHECK:STDOUT:   %1 = icmp slt i64 %i, 0, !dbg !183
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !183
// CHECK:STDOUT:   br i1 %2, label %3, label %6, !dbg !183
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !185
// CHECK:STDOUT:   %4 = load i64, ptr %size, align 8, !dbg !185
// CHECK:STDOUT:   %5 = icmp sge i64 %i, %4, !dbg !184
// CHECK:STDOUT:   br label %6, !dbg !183
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %3, %0
// CHECK:STDOUT:   %7 = phi i1 [ true, %0 ], [ %5, %3 ]
// CHECK:STDOUT:   br i1 %7, label %8, label %10, !dbg !186
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %6
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon.2, align 8, !dbg !187
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !187
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !187
// CHECK:STDOUT:   %9 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !187
// CHECK:STDOUT:   call void @abort(), !dbg !187
// CHECK:STDOUT:   br label %10, !dbg !188
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %8, %6
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !189
// CHECK:STDOUT:   %11 = load ptr, ptr %ptr, align 8, !dbg !189
// CHECK:STDOUT:   %ptr.offset = getelementptr inbounds i32, ptr %11, i64 %i, !dbg !191
// CHECK:STDOUT:   %12 = load i32, ptr %ptr.offset, align 4, !dbg !192
// CHECK:STDOUT:   ret i32 %12, !dbg !193
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.Buf.a081b942542726db.Core:Destroy.Core.4d9f279dbc2b9f6f"(ptr %self) #0 !dbg !195 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !198
// CHECK:STDOUT:   %1 = load ptr, ptr %ptr, align 8, !dbg !198
// CHECK:STDOUT:   call void @free(ptr %1), !dbg !199
// CHECK:STDOUT:   ret void, !dbg !200
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.3fc11083d97fac37(ptr %self) #0 !dbg !202 {
// CHECK:STDOUT:   ret void, !dbg !205
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.542d41f9b830d5be"(ptr %self, i64 %other) #4 !dbg !207 {
// CHECK:STDOUT:   %1 = call i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.458163fe052e064e"(i64 %other), !dbg !210
// CHECK:STDOUT:   %2 = load i64, ptr %self, align 8, !dbg !211
// CHECK:STDOUT:   %3 = add i64 %2, %1, !dbg !211
// CHECK:STDOUT:   store i64 %3, ptr %self, align 8, !dbg !211
// CHECK:STDOUT:   ret void, !dbg !211
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CUnsafeMake.Slice.Core.4d9f279dbc2b9f6f(ptr sret({ ptr, i64 }) %return, ptr %p, i64 %size) #0 !dbg !215 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 0, !dbg !224
// CHECK:STDOUT:   store ptr %p, ptr %ptr, align 8, !dbg !224
// CHECK:STDOUT:   %size1 = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 1, !dbg !224
// CHECK:STDOUT:   store i64 %size, ptr %size1, align 8, !dbg !224
// CHECK:STDOUT:   ret void, !dbg !225
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @free(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.458163fe052e064e"(i64 %self) #0 !dbg !227 {
// CHECK:STDOUT:   %1 = call i64 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.9025b11fc94ef1f2"(i64 %self), !dbg !232
// CHECK:STDOUT:   ret i64 %1, !dbg !234
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.9025b11fc94ef1f2"(i64 %self) #0 !dbg !236 {
// CHECK:STDOUT:   ret i64 %self, !dbg !242
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CSelfDestruct.Destroy.Core.3fc11083d97fac37, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 0, 2, 1 }
// CHECK:STDOUT: uselistorder ptr @abort, { 0, 2, 1 }
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
// CHECK:STDOUT: !4 = !DIFile(filename: "synthesized_owner.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{null, !6}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{!6, !7}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !13 = !{null, !12}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{null, !7}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 12, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !20)
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !17, type: !6)
// CHECK:STDOUT: !19 = !DILocation(line: 12, column: 10, scope: !17)
// CHECK:STDOUT: !20 = !{!18}
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !4, line: 15, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !37)
// CHECK:STDOUT: !22 = !DILocalVariable(arg: 1, scope: !21, type: !7)
// CHECK:STDOUT: !26 = !DILocation(line: 16, column: 3, scope: !21)
// CHECK:STDOUT: !28 = !DILocation(line: 16, column: 18, scope: !21)
// CHECK:STDOUT: !29 = !DILocation(line: 16, column: 24, scope: !21)
// CHECK:STDOUT: !30 = !{!12, !7, !6}
// CHECK:STDOUT: !31 = !DISubroutineType(types: !30)
// CHECK:STDOUT: !33 = !DILocation(line: 17, column: 10, scope: !21)
// CHECK:STDOUT: !34 = !{!6, !12, !7}
// CHECK:STDOUT: !35 = !DISubroutineType(types: !34)
// CHECK:STDOUT: !36 = !DILocation(line: 17, column: 3, scope: !21)
// CHECK:STDOUT: !37 = !{!22}
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.7a92959e16736fc7:core.Destroy.Core", scope: null, file: !4, line: 16, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !41)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !38, type: !12)
// CHECK:STDOUT: !40 = !DILocation(line: 16, column: 24, scope: !38)
// CHECK:STDOUT: !41 = !{!39}
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.7490bb5cc2af3be6:core.Destroy.Core", scope: null, file: !4, line: 16, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !45)
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !42, type: !12)
// CHECK:STDOUT: !44 = !DILocation(line: 16, column: 3, scope: !42)
// CHECK:STDOUT: !45 = !{!43}
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.7490bb5cc2af3be6:core.Destroy.Core", scope: null, file: !4, line: 16, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !49)
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !46, type: !12)
// CHECK:STDOUT: !48 = !DILocation(line: 16, column: 3, scope: !46)
// CHECK:STDOUT: !49 = !{!47}
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a97b2b12de121bed:core.Destroy.Core", scope: null, file: !4, line: 16, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !53)
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 1, scope: !50, type: !12)
// CHECK:STDOUT: !52 = !DILocation(line: 16, column: 3, scope: !50)
// CHECK:STDOUT: !53 = !{!51}
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a97b2b12de121bed:core.Destroy.Core", scope: null, file: !4, line: 16, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !57)
// CHECK:STDOUT: !55 = !DILocalVariable(arg: 1, scope: !54, type: !12)
// CHECK:STDOUT: !56 = !DILocation(line: 16, column: 3, scope: !54)
// CHECK:STDOUT: !57 = !{!55}
// CHECK:STDOUT: !58 = !DIFile(filename: "{{.*}}/prelude/types/buf.carbon", directory: "")
// CHECK:STDOUT: !59 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d088c7eb746488be:core.Destroy.Core", scope: null, file: !58, line: 32, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !62)
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !59, type: !12)
// CHECK:STDOUT: !61 = !DILocation(line: 32, column: 18, scope: !59)
// CHECK:STDOUT: !62 = !{!60}
// CHECK:STDOUT: !63 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0f866e2c9731ba7d:core.Destroy.Core", scope: null, file: !58, line: 32, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !66)
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !63, type: !12)
// CHECK:STDOUT: !65 = !DILocation(line: 32, column: 5, scope: !63)
// CHECK:STDOUT: !66 = !{!64}
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.729fca203337f92a:core.Destroy.Core", scope: null, file: !58, line: 32, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !70)
// CHECK:STDOUT: !68 = !DILocalVariable(arg: 1, scope: !67, type: !12)
// CHECK:STDOUT: !69 = !DILocation(line: 32, column: 5, scope: !67)
// CHECK:STDOUT: !70 = !{!68}
// CHECK:STDOUT: !71 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !58, line: 45, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !74)
// CHECK:STDOUT: !72 = !DILocalVariable(arg: 1, scope: !71, type: !7)
// CHECK:STDOUT: !73 = !DILocation(line: 45, column: 38, scope: !71)
// CHECK:STDOUT: !74 = !{!72}
// CHECK:STDOUT: !75 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.0cc0bac3871fce6b:core.Destroy.Core", scope: null, file: !58, line: 45, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !78)
// CHECK:STDOUT: !76 = !DILocalVariable(arg: 1, scope: !75, type: !12)
// CHECK:STDOUT: !77 = !DILocation(line: 45, column: 38, scope: !75)
// CHECK:STDOUT: !78 = !{!76}
// CHECK:STDOUT: !79 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0cc0bac3871fce6b:core.Destroy.Core", scope: null, file: !58, line: 45, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !82)
// CHECK:STDOUT: !80 = !DILocalVariable(arg: 1, scope: !79, type: !12)
// CHECK:STDOUT: !81 = !DILocation(line: 45, column: 38, scope: !79)
// CHECK:STDOUT: !82 = !{!80}
// CHECK:STDOUT: !83 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.079d89ca1000ddb5:core.Destroy.Core", scope: null, file: !58, line: 45, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !86)
// CHECK:STDOUT: !84 = !DILocalVariable(arg: 1, scope: !83, type: !12)
// CHECK:STDOUT: !85 = !DILocation(line: 45, column: 38, scope: !83)
// CHECK:STDOUT: !86 = !{!84}
// CHECK:STDOUT: !87 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.079d89ca1000ddb5:core.Destroy.Core", scope: null, file: !58, line: 45, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !90)
// CHECK:STDOUT: !88 = !DILocalVariable(arg: 1, scope: !87, type: !12)
// CHECK:STDOUT: !89 = !DILocation(line: 45, column: 38, scope: !87)
// CHECK:STDOUT: !90 = !{!88}
// CHECK:STDOUT: !92 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.Buf.Core.4d9f279dbc2b9f6f", scope: null, file: !58, line: 28, type: !31, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !132)
// CHECK:STDOUT: !93 = !DILocalVariable(arg: 1, scope: !92, type: !7)
// CHECK:STDOUT: !94 = !DILocalVariable(arg: 2, scope: !92, type: !6)
// CHECK:STDOUT: !99 = !DILocation(line: 29, column: 9, scope: !92)
// CHECK:STDOUT: !100 = !DILocation(line: 29, column: 8, scope: !92)
// CHECK:STDOUT: !101 = !DILocation(line: 30, column: 7, scope: !92)
// CHECK:STDOUT: !102 = !DILocation(line: 29, column: 5, scope: !92)
// CHECK:STDOUT: !103 = !DILocation(line: 32, column: 5, scope: !92)
// CHECK:STDOUT: !105 = !DILocation(line: 32, column: 38, scope: !92)
// CHECK:STDOUT: !107 = !DILocation(line: 33, column: 23, scope: !92)
// CHECK:STDOUT: !108 = !DILocation(line: 33, column: 9, scope: !92)
// CHECK:STDOUT: !109 = !DILocation(line: 33, column: 8, scope: !92)
// CHECK:STDOUT: !110 = !DILocation(line: 34, column: 7, scope: !92)
// CHECK:STDOUT: !111 = !DILocation(line: 33, column: 5, scope: !92)
// CHECK:STDOUT: !112 = !DILocation(line: 36, column: 19, scope: !92)
// CHECK:STDOUT: !115 = !DILocation(line: 37, column: 5, scope: !92)
// CHECK:STDOUT: !117 = !DILocation(line: 38, column: 11, scope: !92)
// CHECK:STDOUT: !118 = !DILocation(line: 38, column: 12, scope: !92)
// CHECK:STDOUT: !121 = !DILocation(line: 39, column: 27, scope: !92)
// CHECK:STDOUT: !122 = !DILocation(line: 39, column: 8, scope: !92)
// CHECK:STDOUT: !123 = !DILocation(line: 39, column: 7, scope: !92)
// CHECK:STDOUT: !126 = !DILocation(line: 40, column: 7, scope: !92)
// CHECK:STDOUT: !127 = !DILocation(line: 38, column: 5, scope: !92)
// CHECK:STDOUT: !130 = !DILocation(line: 42, column: 12, scope: !92)
// CHECK:STDOUT: !131 = !DILocation(line: 42, column: 5, scope: !92)
// CHECK:STDOUT: !132 = !{!93, !94}
// CHECK:STDOUT: !133 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Buf.Core.4d9f279dbc2b9f6f", scope: null, file: !58, line: 45, type: !35, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !145)
// CHECK:STDOUT: !134 = !DILocalVariable(arg: 1, scope: !133, type: !12)
// CHECK:STDOUT: !135 = !DILocalVariable(arg: 2, scope: !133, type: !7)
// CHECK:STDOUT: !140 = !DILocation(line: 45, column: 38, scope: !133)
// CHECK:STDOUT: !141 = !{!12, !12}
// CHECK:STDOUT: !142 = !DISubroutineType(types: !141)
// CHECK:STDOUT: !144 = !DILocation(line: 45, column: 31, scope: !133)
// CHECK:STDOUT: !145 = !{!134, !135}
// CHECK:STDOUT: !146 = !DIFile(filename: "{{.*}}/prelude/destroy.carbon", directory: "")
// CHECK:STDOUT: !147 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.3fc11083d97fac37", scope: null, file: !146, line: 26, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !153)
// CHECK:STDOUT: !148 = !DILocalVariable(arg: 1, scope: !147, type: !12)
// CHECK:STDOUT: !150 = !DILocation(line: 27, column: 5, scope: !147)
// CHECK:STDOUT: !151 = !DILocation(line: 28, column: 5, scope: !147)
// CHECK:STDOUT: !152 = !DILocation(line: 26, column: 3, scope: !147)
// CHECK:STDOUT: !153 = !{!148}
// CHECK:STDOUT: !154 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !155 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Int.9452f4c51951679b.Core:Inc.Core.9025b11fc94ef1f2", scope: null, file: !154, line: 396, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !162)
// CHECK:STDOUT: !156 = !DILocalVariable(arg: 1, scope: !155, type: !7)
// CHECK:STDOUT: !158 = !DILocation(line: 398, column: 5, scope: !155)
// CHECK:STDOUT: !159 = !{null, !7, !7}
// CHECK:STDOUT: !160 = !DISubroutineType(types: !159)
// CHECK:STDOUT: !161 = !DILocation(line: 396, column: 3, scope: !155)
// CHECK:STDOUT: !162 = !{!156}
// CHECK:STDOUT: !163 = distinct !DISubprogram(name: "AsSlice", linkageName: "_CAsSlice.Buf.Core.4d9f279dbc2b9f6f", scope: null, file: !58, line: 54, type: !142, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !174)
// CHECK:STDOUT: !164 = !DILocalVariable(arg: 1, scope: !163, type: !12)
// CHECK:STDOUT: !168 = !DILocation(line: 55, column: 32, scope: !163)
// CHECK:STDOUT: !169 = !DILocation(line: 55, column: 42, scope: !163)
// CHECK:STDOUT: !170 = !DILocation(line: 55, column: 12, scope: !163)
// CHECK:STDOUT: !171 = !{!12, !12, !7}
// CHECK:STDOUT: !172 = !DISubroutineType(types: !171)
// CHECK:STDOUT: !173 = !DILocation(line: 55, column: 5, scope: !163)
// CHECK:STDOUT: !174 = !{!164}
// CHECK:STDOUT: !175 = !DIFile(filename: "{{.*}}/prelude/types/slice.carbon", directory: "")
// CHECK:STDOUT: !176 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Slice.Core.4d9f279dbc2b9f6f", scope: null, file: !175, line: 39, type: !35, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !194)
// CHECK:STDOUT: !177 = !DILocalVariable(arg: 1, scope: !176, type: !12)
// CHECK:STDOUT: !178 = !DILocalVariable(arg: 2, scope: !176, type: !7)
// CHECK:STDOUT: !183 = !DILocation(line: 40, column: 9, scope: !176)
// CHECK:STDOUT: !184 = !DILocation(line: 40, column: 18, scope: !176)
// CHECK:STDOUT: !185 = !DILocation(line: 40, column: 23, scope: !176)
// CHECK:STDOUT: !186 = !DILocation(line: 40, column: 8, scope: !176)
// CHECK:STDOUT: !187 = !DILocation(line: 41, column: 7, scope: !176)
// CHECK:STDOUT: !188 = !DILocation(line: 40, column: 5, scope: !176)
// CHECK:STDOUT: !189 = !DILocation(line: 43, column: 27, scope: !176)
// CHECK:STDOUT: !191 = !DILocation(line: 43, column: 13, scope: !176)
// CHECK:STDOUT: !192 = !DILocation(line: 43, column: 12, scope: !176)
// CHECK:STDOUT: !193 = !DILocation(line: 43, column: 5, scope: !176)
// CHECK:STDOUT: !194 = !{!177, !178}
// CHECK:STDOUT: !195 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Buf.a081b942542726db.Core:Destroy.Core.4d9f279dbc2b9f6f", scope: null, file: !58, line: 59, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !201)
// CHECK:STDOUT: !196 = !DILocalVariable(arg: 1, scope: !195, type: !12)
// CHECK:STDOUT: !198 = !DILocation(line: 59, column: 32, scope: !195)
// CHECK:STDOUT: !199 = !DILocation(line: 59, column: 23, scope: !195)
// CHECK:STDOUT: !200 = !DILocation(line: 59, column: 5, scope: !195)
// CHECK:STDOUT: !201 = !{!196}
// CHECK:STDOUT: !202 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.3fc11083d97fac37", scope: null, file: !146, line: 19, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !206)
// CHECK:STDOUT: !203 = !DILocalVariable(arg: 1, scope: !202, type: !12)
// CHECK:STDOUT: !205 = !DILocation(line: 19, column: 3, scope: !202)
// CHECK:STDOUT: !206 = !{!203}
// CHECK:STDOUT: !207 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.542d41f9b830d5be", scope: null, file: !154, line: 331, type: !160, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !214)
// CHECK:STDOUT: !208 = !DILocalVariable(arg: 1, scope: !207, type: !7)
// CHECK:STDOUT: !209 = !DILocalVariable(arg: 2, scope: !207, type: !7)
// CHECK:STDOUT: !210 = !DILocation(line: 0, scope: !207)
// CHECK:STDOUT: !211 = !DILocation(line: 331, column: 3, scope: !207)
// CHECK:STDOUT: !212 = !{!7, !7}
// CHECK:STDOUT: !213 = !DISubroutineType(types: !212)
// CHECK:STDOUT: !214 = !{!208, !209}
// CHECK:STDOUT: !215 = distinct !DISubprogram(name: "UnsafeMake", linkageName: "_CUnsafeMake.Slice.Core.4d9f279dbc2b9f6f", scope: null, file: !175, line: 31, type: !172, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !226)
// CHECK:STDOUT: !216 = !DILocalVariable(arg: 1, scope: !215, type: !12)
// CHECK:STDOUT: !217 = !DILocalVariable(arg: 2, scope: !215, type: !7)
// CHECK:STDOUT: !224 = !DILocation(line: 32, column: 12, scope: !215)
// CHECK:STDOUT: !225 = !DILocation(line: 32, column: 5, scope: !215)
// CHECK:STDOUT: !226 = !{!216, !217}
// CHECK:STDOUT: !227 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.458163fe052e064e", scope: null, file: !154, line: 64, type: !213, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !235)
// CHECK:STDOUT: !228 = !DILocalVariable(arg: 1, scope: !227, type: !7)
// CHECK:STDOUT: !232 = !DILocation(line: 66, column: 17, scope: !227)
// CHECK:STDOUT: !234 = !DILocation(line: 66, column: 5, scope: !227)
// CHECK:STDOUT: !235 = !{!228}
// CHECK:STDOUT: !236 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.9025b11fc94ef1f2", scope: null, file: !154, line: 59, type: !213, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !243)
// CHECK:STDOUT: !237 = !DILocalVariable(arg: 1, scope: !236, type: !7)
// CHECK:STDOUT: !242 = !DILocation(line: 59, column: 28, scope: !236)
// CHECK:STDOUT: !243 = !{!237}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'declared_owner.carbon'
// CHECK:STDOUT: source_filename = "declared_owner.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [48 x i8] c"carbon: Core.Buf size is negative; terminating\0A\00", align 1
// CHECK:STDOUT: @1 = private unnamed_addr constant [45 x i8] c"carbon: heap allocation failed; terminating\0A\00", align 1
// CHECK:STDOUT: @2 = private unnamed_addr constant [51 x i8] c"carbon: Core.Buf index out of bounds; terminating\0A\00", align 1
// CHECK:STDOUT: @const.anon = internal constant { ptr, i64 } { ptr @0, i64 47 }
// CHECK:STDOUT: @const.anon.1 = internal constant { ptr, i64 } { ptr @1, i64 44 }
// CHECK:STDOUT: @3 = private unnamed_addr constant [53 x i8] c"carbon: Core.Slice index out of bounds; terminating\0A\00", align 1
// CHECK:STDOUT: @4 = private unnamed_addr constant [62 x i8] c"carbon: Core.Slice.Subslice range out of bounds; terminating\0A\00", align 1
// CHECK:STDOUT: @const.anon.2 = internal constant { ptr, i64 } { ptr @3, i64 52 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !246 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !248
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.OwnerWithOp.Main:Destroy.Core"(ptr %self) #0 !dbg !250 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !253
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CG.Main(i64 %n) #0 !dbg !255 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %o.var = alloca { { ptr, i64 } }, align 8, !dbg !260
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %o.var), !dbg !260
// CHECK:STDOUT:   %.loc22_54.1.b = getelementptr inbounds nuw { { ptr, i64 } }, ptr %o.var, i32 0, i32 0, !dbg !262
// CHECK:STDOUT:   call void @_CMake.Buf.Core.4d9f279dbc2b9f6f(ptr %.loc22_54.1.b, i64 %n, i32 7), !dbg !263
// CHECK:STDOUT:   %.loc23_11.1.b = getelementptr inbounds nuw { { ptr, i64 } }, ptr %o.var, i32 0, i32 0, !dbg !265
// CHECK:STDOUT:   %Buf.Get.call = call i32 @_CGet.Buf.Core.4d9f279dbc2b9f6f(ptr %.loc23_11.1.b, i64 0), !dbg !265
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.542dc673709d1757(ptr %o.var), !dbg !260
// CHECK:STDOUT:   ret i32 %Buf.Get.call, !dbg !266
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.7a92959e16736fc7:core.Destroy.Core"(ptr %self) #0 !dbg !268 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !270
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %self) #0 !dbg !272 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !274
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0f866e2c9731ba7d:core.Destroy.Core"(ptr %self) #0 !dbg !276 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !278
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.729fca203337f92a:core.Destroy.Core"(ptr %self) #0 !dbg !280 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !282
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !284 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !286
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.0cc0bac3871fce6b:core.Destroy.Core"(ptr %self) #0 !dbg !288 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.1.size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !290
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.1.size), !dbg !290
// CHECK:STDOUT:   %.2.ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !290
// CHECK:STDOUT:   call void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %.2.ptr), !dbg !290
// CHECK:STDOUT:   ret void, !dbg !290
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0cc0bac3871fce6b:core.Destroy.Core"(ptr %self) #0 !dbg !292 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.0cc0bac3871fce6b:core.Destroy.Core"(ptr %self), !dbg !294
// CHECK:STDOUT:   ret void, !dbg !294
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.079d89ca1000ddb5:core.Destroy.Core"(ptr %self) #0 !dbg !296 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.1.size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !298
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.1.size), !dbg !298
// CHECK:STDOUT:   %.2.ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !298
// CHECK:STDOUT:   call void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %.2.ptr), !dbg !298
// CHECK:STDOUT:   ret void, !dbg !298
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.079d89ca1000ddb5:core.Destroy.Core"(ptr %self) #0 !dbg !300 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.079d89ca1000ddb5:core.Destroy.Core"(ptr %self), !dbg !302
// CHECK:STDOUT:   ret void, !dbg !302
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CMake.Buf.Core.4d9f279dbc2b9f6f(ptr sret({ ptr, i64 }) %return, i64 %size, i32 %fill) #0 !dbg !304 {
// CHECK:STDOUT:   %1 = alloca ptr, align 8, !dbg !315
// CHECK:STDOUT:   %2 = alloca i64, align 8, !dbg !327
// CHECK:STDOUT:   %3 = icmp slt i64 %size, 0, !dbg !311
// CHECK:STDOUT:   br i1 %3, label %4, label %6, !dbg !312
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon, align 8, !dbg !313
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !313
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !313
// CHECK:STDOUT:   %5 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !313
// CHECK:STDOUT:   call void @abort(), !dbg !313
// CHECK:STDOUT:   br label %6, !dbg !314
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %4, %0
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !315
// CHECK:STDOUT:   %heap.bytes.mul = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 %size, i64 4), !dbg !317
// CHECK:STDOUT:   %heap.bytes = extractvalue { i64, i1 } %heap.bytes.mul, 0, !dbg !317
// CHECK:STDOUT:   %heap.bytes.overflow = extractvalue { i64, i1 } %heap.bytes.mul, 1, !dbg !317
// CHECK:STDOUT:   %heap.bytes.is_zero = icmp eq i64 %heap.bytes, 0, !dbg !317
// CHECK:STDOUT:   %heap.bytes.nonzero = select i1 %heap.bytes.is_zero, i64 1, i64 %heap.bytes, !dbg !317
// CHECK:STDOUT:   %heap.block = call ptr @malloc(i64 %heap.bytes.nonzero), !dbg !317
// CHECK:STDOUT:   %heap.result = select i1 %heap.bytes.overflow, ptr null, ptr %heap.block, !dbg !317
// CHECK:STDOUT:   store ptr %heap.result, ptr %1, align 8, !dbg !315
// CHECK:STDOUT:   %7 = load ptr, ptr %1, align 8, !dbg !319
// CHECK:STDOUT:   %8 = icmp eq ptr %7, null, !dbg !320
// CHECK:STDOUT:   br i1 %8, label %9, label %11, !dbg !321
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %6
// CHECK:STDOUT:   %fail_stop.load1 = load { ptr, i64 }, ptr @const.anon.1, align 8, !dbg !322
// CHECK:STDOUT:   %fail_stop.ptr2 = extractvalue { ptr, i64 } %fail_stop.load1, 0, !dbg !322
// CHECK:STDOUT:   %fail_stop.size3 = extractvalue { ptr, i64 } %fail_stop.load1, 1, !dbg !322
// CHECK:STDOUT:   %10 = call i64 @write(i32 2, ptr %fail_stop.ptr2, i64 %fail_stop.size3), !dbg !322
// CHECK:STDOUT:   call void @abort(), !dbg !322
// CHECK:STDOUT:   br label %11, !dbg !323
// CHECK:STDOUT:
// CHECK:STDOUT: 11:                                               ; preds = %9, %6
// CHECK:STDOUT:   %12 = load ptr, ptr %1, align 8, !dbg !324
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %2), !dbg !327
// CHECK:STDOUT:   store i64 0, ptr %2, align 8, !dbg !327
// CHECK:STDOUT:   br label %13, !dbg !329
// CHECK:STDOUT:
// CHECK:STDOUT: 13:                                               ; preds = %16, %11
// CHECK:STDOUT:   %14 = load i64, ptr %2, align 8, !dbg !330
// CHECK:STDOUT:   %15 = icmp slt i64 %14, %size, !dbg !330
// CHECK:STDOUT:   br i1 %15, label %16, label %18, !dbg !329
// CHECK:STDOUT:
// CHECK:STDOUT: 16:                                               ; preds = %13
// CHECK:STDOUT:   %17 = load i64, ptr %2, align 8, !dbg !333
// CHECK:STDOUT:   %ptr.offset = getelementptr inbounds i32, ptr %12, i64 %17, !dbg !334
// CHECK:STDOUT:   store i32 %fill, ptr %ptr.offset, align 4, !dbg !335
// CHECK:STDOUT:   call void @"_COp.Int.9452f4c51951679b.Core:Inc.Core.9025b11fc94ef1f2"(ptr %2), !dbg !338
// CHECK:STDOUT:   br label %13, !dbg !339
// CHECK:STDOUT:
// CHECK:STDOUT: 18:                                               ; preds = %13
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 0, !dbg !342
// CHECK:STDOUT:   store ptr %12, ptr %ptr, align 8, !dbg !342
// CHECK:STDOUT:   %size4 = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 1, !dbg !342
// CHECK:STDOUT:   store i64 %size, ptr %size4, align 8, !dbg !342
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %2), !dbg !327
// CHECK:STDOUT:   call void @"_CSelfDestruct.729fca203337f92a:core.Destroy.Core"(ptr %1), !dbg !315
// CHECK:STDOUT:   ret void, !dbg !343
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Buf.Core.4d9f279dbc2b9f6f(ptr %self, i64 %i) #0 !dbg !345 {
// CHECK:STDOUT:   %temp = alloca { ptr, i64 }, align 8, !dbg !352
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !352
// CHECK:STDOUT:   call void @_CAsSlice.Buf.Core.4d9f279dbc2b9f6f(ptr %temp, ptr %self), !dbg !352
// CHECK:STDOUT:   %1 = call i32 @_CGet.Slice.Core.4d9f279dbc2b9f6f(ptr %temp, i64 %i), !dbg !352
// CHECK:STDOUT:   call void @"_CSelfDestruct.079d89ca1000ddb5:core.Destroy.Core"(ptr %temp), !dbg !352
// CHECK:STDOUT:   ret i32 %1, !dbg !354
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.542dc673709d1757(ptr %self) #0 !dbg !356 {
// CHECK:STDOUT:   call void @"_COp.OwnerWithOp.Main:Destroy.Core"(ptr %self), !dbg !359
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.542dc673709d1757(ptr %self), !dbg !360
// CHECK:STDOUT:   ret void, !dbg !361
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
// CHECK:STDOUT: define linkonce_odr void @"_COp.Int.9452f4c51951679b.Core:Inc.Core.9025b11fc94ef1f2"(ptr %self) #0 !dbg !363 {
// CHECK:STDOUT:   call void @"_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.542d41f9b830d5be"(ptr %self, i64 1), !dbg !366
// CHECK:STDOUT:   ret void, !dbg !367
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CAsSlice.Buf.Core.4d9f279dbc2b9f6f(ptr sret({ ptr, i64 }) %return, ptr %self) #0 !dbg !369 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !374
// CHECK:STDOUT:   %1 = load ptr, ptr %ptr, align 8, !dbg !374
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !375
// CHECK:STDOUT:   %2 = load i64, ptr %size, align 8, !dbg !375
// CHECK:STDOUT:   call void @_CUnsafeMake.Slice.Core.4d9f279dbc2b9f6f(ptr %return, ptr %1, i64 %2), !dbg !376
// CHECK:STDOUT:   ret void, !dbg !377
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Slice.Core.4d9f279dbc2b9f6f(ptr %self, i64 %i) #0 !dbg !379 {
// CHECK:STDOUT:   %1 = icmp slt i64 %i, 0, !dbg !386
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !386
// CHECK:STDOUT:   br i1 %2, label %3, label %6, !dbg !386
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !388
// CHECK:STDOUT:   %4 = load i64, ptr %size, align 8, !dbg !388
// CHECK:STDOUT:   %5 = icmp sge i64 %i, %4, !dbg !387
// CHECK:STDOUT:   br label %6, !dbg !386
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %3, %0
// CHECK:STDOUT:   %7 = phi i1 [ true, %0 ], [ %5, %3 ]
// CHECK:STDOUT:   br i1 %7, label %8, label %10, !dbg !389
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %6
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon.2, align 8, !dbg !390
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !390
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !390
// CHECK:STDOUT:   %9 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !390
// CHECK:STDOUT:   call void @abort(), !dbg !390
// CHECK:STDOUT:   br label %10, !dbg !391
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %8, %6
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !392
// CHECK:STDOUT:   %11 = load ptr, ptr %ptr, align 8, !dbg !392
// CHECK:STDOUT:   %ptr.offset = getelementptr inbounds i32, ptr %11, i64 %i, !dbg !394
// CHECK:STDOUT:   %12 = load i32, ptr %ptr.offset, align 4, !dbg !395
// CHECK:STDOUT:   ret i32 %12, !dbg !396
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.542dc673709d1757(ptr %self) #0 !dbg !398 {
// CHECK:STDOUT:   ret void, !dbg !401
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.542d41f9b830d5be"(ptr %self, i64 %other) #4 !dbg !403 {
// CHECK:STDOUT:   %1 = call i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.458163fe052e064e"(i64 %other), !dbg !406
// CHECK:STDOUT:   %2 = load i64, ptr %self, align 8, !dbg !407
// CHECK:STDOUT:   %3 = add i64 %2, %1, !dbg !407
// CHECK:STDOUT:   store i64 %3, ptr %self, align 8, !dbg !407
// CHECK:STDOUT:   ret void, !dbg !407
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CUnsafeMake.Slice.Core.4d9f279dbc2b9f6f(ptr sret({ ptr, i64 }) %return, ptr %p, i64 %size) #0 !dbg !409 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 0, !dbg !418
// CHECK:STDOUT:   store ptr %p, ptr %ptr, align 8, !dbg !418
// CHECK:STDOUT:   %size1 = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 1, !dbg !418
// CHECK:STDOUT:   store i64 %size, ptr %size1, align 8, !dbg !418
// CHECK:STDOUT:   ret void, !dbg !419
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.458163fe052e064e"(i64 %self) #0 !dbg !421 {
// CHECK:STDOUT:   %1 = call i64 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.9025b11fc94ef1f2"(i64 %self), !dbg !426
// CHECK:STDOUT:   ret i64 %1, !dbg !428
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.9025b11fc94ef1f2"(i64 %self) #0 !dbg !430 {
// CHECK:STDOUT:   ret i64 %self, !dbg !436
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @write, { 0, 2, 1 }
// CHECK:STDOUT: uselistorder ptr @abort, { 0, 2, 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #2 = { noreturn }
// CHECK:STDOUT: attributes #3 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
// CHECK:STDOUT: attributes #4 = { alwaysinline nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!245}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{null, !6}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{!6, !7}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !13 = !{null, !12}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{null, !7}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !30 = !{!12, !7, !6}
// CHECK:STDOUT: !31 = !DISubroutineType(types: !30)
// CHECK:STDOUT: !34 = !{!6, !12, !7}
// CHECK:STDOUT: !35 = !DISubroutineType(types: !34)
// CHECK:STDOUT: !58 = !DIFile(filename: "{{.*}}/prelude/types/buf.carbon", directory: "")
// CHECK:STDOUT: !141 = !{!12, !12}
// CHECK:STDOUT: !142 = !DISubroutineType(types: !141)
// CHECK:STDOUT: !146 = !DIFile(filename: "{{.*}}/prelude/destroy.carbon", directory: "")
// CHECK:STDOUT: !154 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !159 = !{null, !7, !7}
// CHECK:STDOUT: !160 = !DISubroutineType(types: !159)
// CHECK:STDOUT: !171 = !{!12, !12, !7}
// CHECK:STDOUT: !172 = !DISubroutineType(types: !171)
// CHECK:STDOUT: !175 = !DIFile(filename: "{{.*}}/prelude/types/slice.carbon", directory: "")
// CHECK:STDOUT: !212 = !{!7, !7}
// CHECK:STDOUT: !213 = !DISubroutineType(types: !212)
// CHECK:STDOUT: !244 = !DIFile(filename: "declared_owner.carbon", directory: "")
// CHECK:STDOUT: !245 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !244, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !246 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !244, line: 14, type: !9, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !249)
// CHECK:STDOUT: !247 = !DILocalVariable(arg: 1, scope: !246, type: !6)
// CHECK:STDOUT: !248 = !DILocation(line: 14, column: 10, scope: !246)
// CHECK:STDOUT: !249 = !{!247}
// CHECK:STDOUT: !250 = distinct !DISubprogram(name: "Op", linkageName: "_COp.OwnerWithOp.Main:Destroy.Core", scope: null, file: !244, line: 17, type: !14, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !254)
// CHECK:STDOUT: !251 = !DILocalVariable(arg: 1, scope: !250, type: !12)
// CHECK:STDOUT: !253 = !DILocation(line: 17, column: 5, scope: !250)
// CHECK:STDOUT: !254 = !{!251}
// CHECK:STDOUT: !255 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main", scope: null, file: !244, line: 21, type: !11, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !267)
// CHECK:STDOUT: !256 = !DILocalVariable(arg: 1, scope: !255, type: !7)
// CHECK:STDOUT: !260 = !DILocation(line: 22, column: 3, scope: !255)
// CHECK:STDOUT: !262 = !DILocation(line: 22, column: 24, scope: !255)
// CHECK:STDOUT: !263 = !DILocation(line: 22, column: 30, scope: !255)
// CHECK:STDOUT: !265 = !DILocation(line: 23, column: 10, scope: !255)
// CHECK:STDOUT: !266 = !DILocation(line: 23, column: 3, scope: !255)
// CHECK:STDOUT: !267 = !{!256}
// CHECK:STDOUT: !268 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.7a92959e16736fc7:core.Destroy.Core", scope: null, file: !244, line: 22, type: !14, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !271)
// CHECK:STDOUT: !269 = !DILocalVariable(arg: 1, scope: !268, type: !12)
// CHECK:STDOUT: !270 = !DILocation(line: 22, column: 30, scope: !268)
// CHECK:STDOUT: !271 = !{!269}
// CHECK:STDOUT: !272 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d088c7eb746488be:core.Destroy.Core", scope: null, file: !58, line: 32, type: !14, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !275)
// CHECK:STDOUT: !273 = !DILocalVariable(arg: 1, scope: !272, type: !12)
// CHECK:STDOUT: !274 = !DILocation(line: 32, column: 18, scope: !272)
// CHECK:STDOUT: !275 = !{!273}
// CHECK:STDOUT: !276 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0f866e2c9731ba7d:core.Destroy.Core", scope: null, file: !58, line: 32, type: !14, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !279)
// CHECK:STDOUT: !277 = !DILocalVariable(arg: 1, scope: !276, type: !12)
// CHECK:STDOUT: !278 = !DILocation(line: 32, column: 5, scope: !276)
// CHECK:STDOUT: !279 = !{!277}
// CHECK:STDOUT: !280 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.729fca203337f92a:core.Destroy.Core", scope: null, file: !58, line: 32, type: !14, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !283)
// CHECK:STDOUT: !281 = !DILocalVariable(arg: 1, scope: !280, type: !12)
// CHECK:STDOUT: !282 = !DILocation(line: 32, column: 5, scope: !280)
// CHECK:STDOUT: !283 = !{!281}
// CHECK:STDOUT: !284 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !58, line: 45, type: !16, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !287)
// CHECK:STDOUT: !285 = !DILocalVariable(arg: 1, scope: !284, type: !7)
// CHECK:STDOUT: !286 = !DILocation(line: 45, column: 38, scope: !284)
// CHECK:STDOUT: !287 = !{!285}
// CHECK:STDOUT: !288 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.0cc0bac3871fce6b:core.Destroy.Core", scope: null, file: !58, line: 45, type: !14, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !291)
// CHECK:STDOUT: !289 = !DILocalVariable(arg: 1, scope: !288, type: !12)
// CHECK:STDOUT: !290 = !DILocation(line: 45, column: 38, scope: !288)
// CHECK:STDOUT: !291 = !{!289}
// CHECK:STDOUT: !292 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0cc0bac3871fce6b:core.Destroy.Core", scope: null, file: !58, line: 45, type: !14, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !295)
// CHECK:STDOUT: !293 = !DILocalVariable(arg: 1, scope: !292, type: !12)
// CHECK:STDOUT: !294 = !DILocation(line: 45, column: 38, scope: !292)
// CHECK:STDOUT: !295 = !{!293}
// CHECK:STDOUT: !296 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.079d89ca1000ddb5:core.Destroy.Core", scope: null, file: !58, line: 45, type: !14, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !299)
// CHECK:STDOUT: !297 = !DILocalVariable(arg: 1, scope: !296, type: !12)
// CHECK:STDOUT: !298 = !DILocation(line: 45, column: 38, scope: !296)
// CHECK:STDOUT: !299 = !{!297}
// CHECK:STDOUT: !300 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.079d89ca1000ddb5:core.Destroy.Core", scope: null, file: !58, line: 45, type: !14, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !303)
// CHECK:STDOUT: !301 = !DILocalVariable(arg: 1, scope: !300, type: !12)
// CHECK:STDOUT: !302 = !DILocation(line: 45, column: 38, scope: !300)
// CHECK:STDOUT: !303 = !{!301}
// CHECK:STDOUT: !304 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.Buf.Core.4d9f279dbc2b9f6f", scope: null, file: !58, line: 28, type: !31, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !344)
// CHECK:STDOUT: !305 = !DILocalVariable(arg: 1, scope: !304, type: !7)
// CHECK:STDOUT: !306 = !DILocalVariable(arg: 2, scope: !304, type: !6)
// CHECK:STDOUT: !311 = !DILocation(line: 29, column: 9, scope: !304)
// CHECK:STDOUT: !312 = !DILocation(line: 29, column: 8, scope: !304)
// CHECK:STDOUT: !313 = !DILocation(line: 30, column: 7, scope: !304)
// CHECK:STDOUT: !314 = !DILocation(line: 29, column: 5, scope: !304)
// CHECK:STDOUT: !315 = !DILocation(line: 32, column: 5, scope: !304)
// CHECK:STDOUT: !317 = !DILocation(line: 32, column: 38, scope: !304)
// CHECK:STDOUT: !319 = !DILocation(line: 33, column: 23, scope: !304)
// CHECK:STDOUT: !320 = !DILocation(line: 33, column: 9, scope: !304)
// CHECK:STDOUT: !321 = !DILocation(line: 33, column: 8, scope: !304)
// CHECK:STDOUT: !322 = !DILocation(line: 34, column: 7, scope: !304)
// CHECK:STDOUT: !323 = !DILocation(line: 33, column: 5, scope: !304)
// CHECK:STDOUT: !324 = !DILocation(line: 36, column: 19, scope: !304)
// CHECK:STDOUT: !327 = !DILocation(line: 37, column: 5, scope: !304)
// CHECK:STDOUT: !329 = !DILocation(line: 38, column: 11, scope: !304)
// CHECK:STDOUT: !330 = !DILocation(line: 38, column: 12, scope: !304)
// CHECK:STDOUT: !333 = !DILocation(line: 39, column: 27, scope: !304)
// CHECK:STDOUT: !334 = !DILocation(line: 39, column: 8, scope: !304)
// CHECK:STDOUT: !335 = !DILocation(line: 39, column: 7, scope: !304)
// CHECK:STDOUT: !338 = !DILocation(line: 40, column: 7, scope: !304)
// CHECK:STDOUT: !339 = !DILocation(line: 38, column: 5, scope: !304)
// CHECK:STDOUT: !342 = !DILocation(line: 42, column: 12, scope: !304)
// CHECK:STDOUT: !343 = !DILocation(line: 42, column: 5, scope: !304)
// CHECK:STDOUT: !344 = !{!305, !306}
// CHECK:STDOUT: !345 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Buf.Core.4d9f279dbc2b9f6f", scope: null, file: !58, line: 45, type: !35, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !355)
// CHECK:STDOUT: !346 = !DILocalVariable(arg: 1, scope: !345, type: !12)
// CHECK:STDOUT: !347 = !DILocalVariable(arg: 2, scope: !345, type: !7)
// CHECK:STDOUT: !352 = !DILocation(line: 45, column: 38, scope: !345)
// CHECK:STDOUT: !354 = !DILocation(line: 45, column: 31, scope: !345)
// CHECK:STDOUT: !355 = !{!346, !347}
// CHECK:STDOUT: !356 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.542dc673709d1757", scope: null, file: !146, line: 26, type: !14, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !362)
// CHECK:STDOUT: !357 = !DILocalVariable(arg: 1, scope: !356, type: !12)
// CHECK:STDOUT: !359 = !DILocation(line: 27, column: 5, scope: !356)
// CHECK:STDOUT: !360 = !DILocation(line: 28, column: 5, scope: !356)
// CHECK:STDOUT: !361 = !DILocation(line: 26, column: 3, scope: !356)
// CHECK:STDOUT: !362 = !{!357}
// CHECK:STDOUT: !363 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Int.9452f4c51951679b.Core:Inc.Core.9025b11fc94ef1f2", scope: null, file: !154, line: 396, type: !16, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !368)
// CHECK:STDOUT: !364 = !DILocalVariable(arg: 1, scope: !363, type: !7)
// CHECK:STDOUT: !366 = !DILocation(line: 398, column: 5, scope: !363)
// CHECK:STDOUT: !367 = !DILocation(line: 396, column: 3, scope: !363)
// CHECK:STDOUT: !368 = !{!364}
// CHECK:STDOUT: !369 = distinct !DISubprogram(name: "AsSlice", linkageName: "_CAsSlice.Buf.Core.4d9f279dbc2b9f6f", scope: null, file: !58, line: 54, type: !142, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !378)
// CHECK:STDOUT: !370 = !DILocalVariable(arg: 1, scope: !369, type: !12)
// CHECK:STDOUT: !374 = !DILocation(line: 55, column: 32, scope: !369)
// CHECK:STDOUT: !375 = !DILocation(line: 55, column: 42, scope: !369)
// CHECK:STDOUT: !376 = !DILocation(line: 55, column: 12, scope: !369)
// CHECK:STDOUT: !377 = !DILocation(line: 55, column: 5, scope: !369)
// CHECK:STDOUT: !378 = !{!370}
// CHECK:STDOUT: !379 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Slice.Core.4d9f279dbc2b9f6f", scope: null, file: !175, line: 39, type: !35, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !397)
// CHECK:STDOUT: !380 = !DILocalVariable(arg: 1, scope: !379, type: !12)
// CHECK:STDOUT: !381 = !DILocalVariable(arg: 2, scope: !379, type: !7)
// CHECK:STDOUT: !386 = !DILocation(line: 40, column: 9, scope: !379)
// CHECK:STDOUT: !387 = !DILocation(line: 40, column: 18, scope: !379)
// CHECK:STDOUT: !388 = !DILocation(line: 40, column: 23, scope: !379)
// CHECK:STDOUT: !389 = !DILocation(line: 40, column: 8, scope: !379)
// CHECK:STDOUT: !390 = !DILocation(line: 41, column: 7, scope: !379)
// CHECK:STDOUT: !391 = !DILocation(line: 40, column: 5, scope: !379)
// CHECK:STDOUT: !392 = !DILocation(line: 43, column: 27, scope: !379)
// CHECK:STDOUT: !394 = !DILocation(line: 43, column: 13, scope: !379)
// CHECK:STDOUT: !395 = !DILocation(line: 43, column: 12, scope: !379)
// CHECK:STDOUT: !396 = !DILocation(line: 43, column: 5, scope: !379)
// CHECK:STDOUT: !397 = !{!380, !381}
// CHECK:STDOUT: !398 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.542dc673709d1757", scope: null, file: !146, line: 19, type: !14, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !402)
// CHECK:STDOUT: !399 = !DILocalVariable(arg: 1, scope: !398, type: !12)
// CHECK:STDOUT: !401 = !DILocation(line: 19, column: 3, scope: !398)
// CHECK:STDOUT: !402 = !{!399}
// CHECK:STDOUT: !403 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.542d41f9b830d5be", scope: null, file: !154, line: 331, type: !160, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !408)
// CHECK:STDOUT: !404 = !DILocalVariable(arg: 1, scope: !403, type: !7)
// CHECK:STDOUT: !405 = !DILocalVariable(arg: 2, scope: !403, type: !7)
// CHECK:STDOUT: !406 = !DILocation(line: 0, scope: !403)
// CHECK:STDOUT: !407 = !DILocation(line: 331, column: 3, scope: !403)
// CHECK:STDOUT: !408 = !{!404, !405}
// CHECK:STDOUT: !409 = distinct !DISubprogram(name: "UnsafeMake", linkageName: "_CUnsafeMake.Slice.Core.4d9f279dbc2b9f6f", scope: null, file: !175, line: 31, type: !172, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !420)
// CHECK:STDOUT: !410 = !DILocalVariable(arg: 1, scope: !409, type: !12)
// CHECK:STDOUT: !411 = !DILocalVariable(arg: 2, scope: !409, type: !7)
// CHECK:STDOUT: !418 = !DILocation(line: 32, column: 12, scope: !409)
// CHECK:STDOUT: !419 = !DILocation(line: 32, column: 5, scope: !409)
// CHECK:STDOUT: !420 = !{!410, !411}
// CHECK:STDOUT: !421 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.458163fe052e064e", scope: null, file: !154, line: 64, type: !213, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !429)
// CHECK:STDOUT: !422 = !DILocalVariable(arg: 1, scope: !421, type: !7)
// CHECK:STDOUT: !426 = !DILocation(line: 66, column: 17, scope: !421)
// CHECK:STDOUT: !428 = !DILocation(line: 66, column: 5, scope: !421)
// CHECK:STDOUT: !429 = !{!422}
// CHECK:STDOUT: !430 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.9025b11fc94ef1f2", scope: null, file: !154, line: 59, type: !213, spFlags: DISPFlagDefinition, unit: !245, retainedNodes: !437)
// CHECK:STDOUT: !431 = !DILocalVariable(arg: 1, scope: !430, type: !7)
// CHECK:STDOUT: !436 = !DILocation(line: 59, column: 28, scope: !430)
// CHECK:STDOUT: !437 = !{!431}
// CHECK:STDOUT:

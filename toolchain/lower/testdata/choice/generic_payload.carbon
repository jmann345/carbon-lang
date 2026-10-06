// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/choice/generic_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/choice/generic_payload.carbon

// Per-specific payload layout (W5-S3b, risk R-1's derived numbers): each
// specific's payload region lowers as its own `[N x i8]` byte array from the
// RECOMPUTED layout — `Pair(i32)` is `[8 x i8]` ((i32, i32), align 4) and
// `Pair(i64)` is `[16 x i8]` ((i64, i64), align 8). Equal regions, `[0 x i8]`
// (a leaked sentinel), or numbers off the derivation falsify the eval-time
// recompute. Both constructors called from one function must produce two
// distinct specific function bodies (risk R-3), each storing through its own
// specific's region type at byte offset zero (F-007k).

// --- two_sizes.carbon
library "[[@TEST_NAME]]";

choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

fn Classify32(p: Pair(i32)) -> i32 {
  match (p) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

fn Classify64(p: Pair(i64)) -> i32 {
  match (p) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

fn Run() -> i32 {
  let a: Pair(i32) = Pair(i32).Both(1, 2);
  let b: Pair(i64) = Pair(i64).Both(3, 4);
  return Classify32(a) + Classify64(b) - 2;
}

// --- mixed.carbon
library "[[@TEST_NAME]]";

// The mixed-alternative max-of-fields flip: in `M(i8)` the concrete `(i32,)`
// payload is largest — `[4 x i8]` — and in `M(i64)` the substituted
// `(i64, i64)` payload is — `[16 x i8]`.
choice M(T: type) {
  Small(a: i32),
  Big(x: T, y: T),
  None
}

fn F8(m: M(i8)) -> i32 {
  match (m) {
    case .None => { return 0; }
    default => { return 1; }
  }
}

fn F64(m: M(i64)) -> i32 {
  match (m) {
    case .None => { return 0; }
    default => { return 1; }
  }
}

fn Run() -> i32 {
  let s: M(i8) = M(i8).Small(1);
  let b: M(i64) = M(i64).Big(3, 4);
  return F8(s) + F64(b) - 2;
}

// --- destructure.carbon
library "[[@TEST_NAME]]";

// The check-side destructure subfile's lower counterpart: `case .Some(v: i32)`
// on a concrete specific extracts the payload tuple from the `[4 x i8]`
// region at offset zero (F-007k) after the discriminant test.
choice Opt(T: type) {
  Some(value: T),
  None
}

fn Get(o: Opt(i32)) -> i32 {
  match (o) {
    case .Some(v: i32) => { return v; }
    case .None => { return -1; }
  }
  // Unreachable: every arm returns.
  return -2;
}

fn Run() -> i32 {
  let s: Opt(i32) = Opt(i32).Some(42);
  return Get(s) - 42;
}

// --- optional.carbon
library "[[@TEST_NAME]]";

// The doc's `Optional` shape: `.None` and `.Some(42)` constructed at runtime
// and dispatched by discriminant; the payload region is `[4 x i8]`.
choice Optional(T: type) {
  Some(value: T),
  None
}

fn IsPresent(o: Optional(i32)) -> i32 {
  match (o) {
    case .None => { return 0; }
    default => { return 1; }
  }
}

fn Run() -> i32 {
  let n: Optional(i32) = Optional(i32).None;
  if (IsPresent(n) != 0) {
    return 1;
  }
  let s: Optional(i32) = Optional(i32).Some(42);
  return IsPresent(s) - 1;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'two_sizes.carbon'
// CHECK:STDOUT: source_filename = "two_sizes.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Pair.val.6e7 = internal constant <{ <{ i1, [3 x i8] }>, [8 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @Pair.val.765 = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT: @Pair.val.cf1.loc3_22.7 = internal constant <{ <{ i1, [3 x i8] }>, [8 x i8] }> zeroinitializer
// CHECK:STDOUT: @Pair.val.790.loc3_22.7 = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CClassify32.Main(ptr %p) #0 !dbg !22 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_19.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %p, i32 0, i32 0, !dbg !28
// CHECK:STDOUT:   %.loc10_19.4 = load i8, ptr %.loc10_19.3.discriminant, align 1, !dbg !28
// CHECK:STDOUT:   %.loc10_19.41 = trunc i8 %.loc10_19.4 to i1, !dbg !28
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc10_19.41, !dbg !28
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !28
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !29
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CClassify64.Main(ptr %p) #0 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_19.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %p, i32 0, i32 0, !dbg !38
// CHECK:STDOUT:   %.loc17_19.4 = load i8, ptr %.loc17_19.3.discriminant, align 1, !dbg !38
// CHECK:STDOUT:   %.loc17_19.41 = trunc i8 %.loc17_19.4 to i1, !dbg !38
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc17_19.41, !dbg !38
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !38
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !39
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc23_41.1.temp = alloca <{ <{ i1, [3 x i8] }>, [8 x i8] }>, align 4, !dbg !45
// CHECK:STDOUT:   %.loc24_41.1.temp = alloca <{ <{ i1, [7 x i8] }>, [16 x i8] }>, align 8, !dbg !50
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc23_41.1.temp), !dbg !45
// CHECK:STDOUT:   call void @_CBoth.Pair.Main.84588f41d61dafba(ptr %.loc23_41.1.temp, i32 1, i32 2), !dbg !45
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc24_41.1.temp), !dbg !50
// CHECK:STDOUT:   call void @_CBoth.Pair.Main.f249b435619a5146(ptr %.loc24_41.1.temp, i64 3, i64 4), !dbg !50
// CHECK:STDOUT:   %Classify32.call = call i32 @_CClassify32.Main(ptr %.loc23_41.1.temp), !dbg !56
// CHECK:STDOUT:   %Classify64.call = call i32 @_CClassify64.Main(ptr %.loc24_41.1.temp), !dbg !58
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Classify32.call, %Classify64.call, !dbg !56
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call = sub i32 %Int.as.AddWith.impl.Op.call, 2, !dbg !56
// CHECK:STDOUT:   call void @"_CSelfDestruct.01ad5b36ba6d1c53:core.Destroy.Core"(ptr %.loc24_41.1.temp), !dbg !50
// CHECK:STDOUT:   call void @"_CSelfDestruct.1eef18dc43ad9a55:core.Destroy.Core"(ptr %.loc23_41.1.temp), !dbg !45
// CHECK:STDOUT:   ret i32 %Int.as.SubWith.impl.Op.call, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !64 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.1ac55aaed189338e:core.Destroy.Core"(ptr %self) #0 !dbg !68 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %self, i32 0, i32 1, !dbg !70
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !70
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %self, i32 0, i32 0, !dbg !70
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !70
// CHECK:STDOUT:   ret void, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.1ac55aaed189338e:core.Destroy.Core"(ptr %self) #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.1ac55aaed189338e:core.Destroy.Core"(ptr %self), !dbg !74
// CHECK:STDOUT:   ret void, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.58ec237e1038f3e7:core.Destroy.Core"(ptr %self) #0 !dbg !76 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !78
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.58ec237e1038f3e7:core.Destroy.Core"(ptr %self) #0 !dbg !80 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.58ec237e1038f3e7:core.Destroy.Core"(ptr %self), !dbg !82
// CHECK:STDOUT:   ret void, !dbg !82
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.8acada488d131cf2:core.Destroy.Core"(ptr %self) #0 !dbg !84 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc24_41.1.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %self, i32 0, i32 1, !dbg !86
// CHECK:STDOUT:   call void @"_CSelfDestruct.58ec237e1038f3e7:core.Destroy.Core"(ptr %.loc24_41.1.payload), !dbg !86
// CHECK:STDOUT:   %.loc24_41.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %self, i32 0, i32 0, !dbg !86
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc24_41.2.discriminant), !dbg !86
// CHECK:STDOUT:   ret void, !dbg !86
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.8acada488d131cf2:core.Destroy.Core"(ptr %self) #0 !dbg !88 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.8acada488d131cf2:core.Destroy.Core"(ptr %self), !dbg !90
// CHECK:STDOUT:   ret void, !dbg !90
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.01ad5b36ba6d1c53:core.Destroy.Core"(ptr %self) #0 !dbg !92 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.01ad5b36ba6d1c53:core.Destroy.Core"(ptr %self) #0 !dbg !96 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.01ad5b36ba6d1c53:core.Destroy.Core"(ptr %self), !dbg !98
// CHECK:STDOUT:   ret void, !dbg !98
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !100 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !102
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !104 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !106
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !106
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !106
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !106
// CHECK:STDOUT:   ret void, !dbg !106
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !108 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self), !dbg !110
// CHECK:STDOUT:   ret void, !dbg !110
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.20c1b1147da3b52d:core.Destroy.Core"(ptr %self) #0 !dbg !112 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !114
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.20c1b1147da3b52d:core.Destroy.Core"(ptr %self) #0 !dbg !116 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.20c1b1147da3b52d:core.Destroy.Core"(ptr %self), !dbg !118
// CHECK:STDOUT:   ret void, !dbg !118
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.92cfe67cb2f4b128:core.Destroy.Core"(ptr %self) #0 !dbg !120 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc23_41.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !122
// CHECK:STDOUT:   call void @"_CSelfDestruct.20c1b1147da3b52d:core.Destroy.Core"(ptr %.loc23_41.1.payload), !dbg !122
// CHECK:STDOUT:   %.loc23_41.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !122
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc23_41.2.discriminant), !dbg !122
// CHECK:STDOUT:   ret void, !dbg !122
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.92cfe67cb2f4b128:core.Destroy.Core"(ptr %self) #0 !dbg !124 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.92cfe67cb2f4b128:core.Destroy.Core"(ptr %self), !dbg !126
// CHECK:STDOUT:   ret void, !dbg !126
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.1eef18dc43ad9a55:core.Destroy.Core"(ptr %self) #0 !dbg !128 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !130
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.1eef18dc43ad9a55:core.Destroy.Core"(ptr %self) #0 !dbg !132 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.1eef18dc43ad9a55:core.Destroy.Core"(ptr %self), !dbg !134
// CHECK:STDOUT:   ret void, !dbg !134
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBoth.Pair.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [8 x i8] }>) %return, i32 %_, i32 %_1) #0 !dbg !136 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_22.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !139
// CHECK:STDOUT:   %.loc3_22.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !139
// CHECK:STDOUT:   %.loc3_22.5.Both = getelementptr inbounds nuw [8 x i8], ptr %.loc3_22.4.payload, i32 0, i32 0, !dbg !139
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Pair.val.cf1.loc3_22.7, i64 12, i1 false), !dbg !139
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc3_22.5.Both, i32 0, i32 0, !dbg !140
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !140
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc3_22.5.Both, i32 0, i32 1, !dbg !140
// CHECK:STDOUT:   store i32 %_1, ptr %tuple.elem1.tuple.elem, align 4, !dbg !140
// CHECK:STDOUT:   ret void, !dbg !139
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBoth.Pair.Main.f249b435619a5146(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>) %return, i64 %_, i64 %_1) #0 !dbg !142 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_22.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 0, !dbg !145
// CHECK:STDOUT:   %.loc3_22.4.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 1, !dbg !145
// CHECK:STDOUT:   %.loc3_22.5.Both = getelementptr inbounds nuw [16 x i8], ptr %.loc3_22.4.payload, i32 0, i32 0, !dbg !145
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @Pair.val.790.loc3_22.7, i64 24, i1 false), !dbg !145
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc3_22.5.Both, i32 0, i32 0, !dbg !146
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem0.tuple.elem, align 8, !dbg !146
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc3_22.5.Both, i32 0, i32 1, !dbg !146
// CHECK:STDOUT:   store i64 %_1, ptr %tuple.elem1.tuple.elem, align 8, !dbg !146
// CHECK:STDOUT:   ret void, !dbg !145
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "two_sizes.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!7, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{null, !6}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !16 = !{null, !8}
// CHECK:STDOUT: !17 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !18 = !{null, !9}
// CHECK:STDOUT: !19 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !20 = !{null, !7}
// CHECK:STDOUT: !21 = !DISubroutineType(types: !20)
// CHECK:STDOUT: !22 = distinct !DISubprogram(name: "Classify32", linkageName: "_CClassify32.Main", scope: null, file: !4, line: 8, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !31)
// CHECK:STDOUT: !23 = !DILocalVariable(arg: 1, scope: !22, type: !9)
// CHECK:STDOUT: !28 = !DILocation(line: 10, column: 5, scope: !22)
// CHECK:STDOUT: !29 = !DILocation(line: 10, column: 24, scope: !22)
// CHECK:STDOUT: !30 = !DILocation(line: 11, column: 18, scope: !22)
// CHECK:STDOUT: !31 = !{!23}
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "Classify64", linkageName: "_CClassify64.Main", scope: null, file: !4, line: 15, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !41)
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !32, type: !9)
// CHECK:STDOUT: !38 = !DILocation(line: 17, column: 5, scope: !32)
// CHECK:STDOUT: !39 = !DILocation(line: 17, column: 24, scope: !32)
// CHECK:STDOUT: !40 = !DILocation(line: 18, column: 18, scope: !32)
// CHECK:STDOUT: !41 = !{!33}
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !4, line: 22, type: !13, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !45 = !DILocation(line: 23, column: 22, scope: !42)
// CHECK:STDOUT: !46 = !{!9, !7, !7}
// CHECK:STDOUT: !47 = !DISubroutineType(types: !46)
// CHECK:STDOUT: !50 = !DILocation(line: 24, column: 22, scope: !42)
// CHECK:STDOUT: !51 = !{!9, !8, !8}
// CHECK:STDOUT: !52 = !DISubroutineType(types: !51)
// CHECK:STDOUT: !56 = !DILocation(line: 25, column: 10, scope: !42)
// CHECK:STDOUT: !58 = !DILocation(line: 25, column: 26, scope: !42)
// CHECK:STDOUT: !59 = !DILocation(line: 25, column: 3, scope: !42)
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !4, line: 24, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !63)
// CHECK:STDOUT: !61 = !DILocalVariable(arg: 1, scope: !60, type: !6)
// CHECK:STDOUT: !62 = !DILocation(line: 24, column: 22, scope: !60)
// CHECK:STDOUT: !63 = !{!61}
// CHECK:STDOUT: !64 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !4, line: 24, type: !17, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !67)
// CHECK:STDOUT: !65 = !DILocalVariable(arg: 1, scope: !64, type: !8)
// CHECK:STDOUT: !66 = !DILocation(line: 24, column: 22, scope: !64)
// CHECK:STDOUT: !67 = !{!65}
// CHECK:STDOUT: !68 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.1ac55aaed189338e:core.Destroy.Core", scope: null, file: !4, line: 24, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !71)
// CHECK:STDOUT: !69 = !DILocalVariable(arg: 1, scope: !68, type: !9)
// CHECK:STDOUT: !70 = !DILocation(line: 24, column: 22, scope: !68)
// CHECK:STDOUT: !71 = !{!69}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.1ac55aaed189338e:core.Destroy.Core", scope: null, file: !4, line: 24, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !75)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !9)
// CHECK:STDOUT: !74 = !DILocation(line: 24, column: 22, scope: !72)
// CHECK:STDOUT: !75 = !{!73}
// CHECK:STDOUT: !76 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.58ec237e1038f3e7:core.Destroy.Core", scope: null, file: !4, line: 24, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !79)
// CHECK:STDOUT: !77 = !DILocalVariable(arg: 1, scope: !76, type: !9)
// CHECK:STDOUT: !78 = !DILocation(line: 24, column: 22, scope: !76)
// CHECK:STDOUT: !79 = !{!77}
// CHECK:STDOUT: !80 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.58ec237e1038f3e7:core.Destroy.Core", scope: null, file: !4, line: 24, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !83)
// CHECK:STDOUT: !81 = !DILocalVariable(arg: 1, scope: !80, type: !9)
// CHECK:STDOUT: !82 = !DILocation(line: 24, column: 22, scope: !80)
// CHECK:STDOUT: !83 = !{!81}
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.8acada488d131cf2:core.Destroy.Core", scope: null, file: !4, line: 24, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !87)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !84, type: !9)
// CHECK:STDOUT: !86 = !DILocation(line: 24, column: 22, scope: !84)
// CHECK:STDOUT: !87 = !{!85}
// CHECK:STDOUT: !88 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.8acada488d131cf2:core.Destroy.Core", scope: null, file: !4, line: 24, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !91)
// CHECK:STDOUT: !89 = !DILocalVariable(arg: 1, scope: !88, type: !9)
// CHECK:STDOUT: !90 = !DILocation(line: 24, column: 22, scope: !88)
// CHECK:STDOUT: !91 = !{!89}
// CHECK:STDOUT: !92 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.01ad5b36ba6d1c53:core.Destroy.Core", scope: null, file: !4, line: 24, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !95)
// CHECK:STDOUT: !93 = !DILocalVariable(arg: 1, scope: !92, type: !9)
// CHECK:STDOUT: !94 = !DILocation(line: 24, column: 22, scope: !92)
// CHECK:STDOUT: !95 = !{!93}
// CHECK:STDOUT: !96 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.01ad5b36ba6d1c53:core.Destroy.Core", scope: null, file: !4, line: 24, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !99)
// CHECK:STDOUT: !97 = !DILocalVariable(arg: 1, scope: !96, type: !9)
// CHECK:STDOUT: !98 = !DILocation(line: 24, column: 22, scope: !96)
// CHECK:STDOUT: !99 = !{!97}
// CHECK:STDOUT: !100 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 23, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !103)
// CHECK:STDOUT: !101 = !DILocalVariable(arg: 1, scope: !100, type: !7)
// CHECK:STDOUT: !102 = !DILocation(line: 23, column: 22, scope: !100)
// CHECK:STDOUT: !103 = !{!101}
// CHECK:STDOUT: !104 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !4, line: 23, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !107)
// CHECK:STDOUT: !105 = !DILocalVariable(arg: 1, scope: !104, type: !9)
// CHECK:STDOUT: !106 = !DILocation(line: 23, column: 22, scope: !104)
// CHECK:STDOUT: !107 = !{!105}
// CHECK:STDOUT: !108 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !4, line: 23, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !111)
// CHECK:STDOUT: !109 = !DILocalVariable(arg: 1, scope: !108, type: !9)
// CHECK:STDOUT: !110 = !DILocation(line: 23, column: 22, scope: !108)
// CHECK:STDOUT: !111 = !{!109}
// CHECK:STDOUT: !112 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.20c1b1147da3b52d:core.Destroy.Core", scope: null, file: !4, line: 23, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !115)
// CHECK:STDOUT: !113 = !DILocalVariable(arg: 1, scope: !112, type: !9)
// CHECK:STDOUT: !114 = !DILocation(line: 23, column: 22, scope: !112)
// CHECK:STDOUT: !115 = !{!113}
// CHECK:STDOUT: !116 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.20c1b1147da3b52d:core.Destroy.Core", scope: null, file: !4, line: 23, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !119)
// CHECK:STDOUT: !117 = !DILocalVariable(arg: 1, scope: !116, type: !9)
// CHECK:STDOUT: !118 = !DILocation(line: 23, column: 22, scope: !116)
// CHECK:STDOUT: !119 = !{!117}
// CHECK:STDOUT: !120 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.92cfe67cb2f4b128:core.Destroy.Core", scope: null, file: !4, line: 23, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !123)
// CHECK:STDOUT: !121 = !DILocalVariable(arg: 1, scope: !120, type: !9)
// CHECK:STDOUT: !122 = !DILocation(line: 23, column: 22, scope: !120)
// CHECK:STDOUT: !123 = !{!121}
// CHECK:STDOUT: !124 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.92cfe67cb2f4b128:core.Destroy.Core", scope: null, file: !4, line: 23, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !127)
// CHECK:STDOUT: !125 = !DILocalVariable(arg: 1, scope: !124, type: !9)
// CHECK:STDOUT: !126 = !DILocation(line: 23, column: 22, scope: !124)
// CHECK:STDOUT: !127 = !{!125}
// CHECK:STDOUT: !128 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.1eef18dc43ad9a55:core.Destroy.Core", scope: null, file: !4, line: 23, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !131)
// CHECK:STDOUT: !129 = !DILocalVariable(arg: 1, scope: !128, type: !9)
// CHECK:STDOUT: !130 = !DILocation(line: 23, column: 22, scope: !128)
// CHECK:STDOUT: !131 = !{!129}
// CHECK:STDOUT: !132 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.1eef18dc43ad9a55:core.Destroy.Core", scope: null, file: !4, line: 23, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !135)
// CHECK:STDOUT: !133 = !DILocalVariable(arg: 1, scope: !132, type: !9)
// CHECK:STDOUT: !134 = !DILocation(line: 23, column: 22, scope: !132)
// CHECK:STDOUT: !135 = !{!133}
// CHECK:STDOUT: !136 = distinct !DISubprogram(name: "Both", linkageName: "_CBoth.Pair.Main.84588f41d61dafba", scope: null, file: !4, line: 3, type: !47, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !141)
// CHECK:STDOUT: !137 = !DILocalVariable(arg: 1, scope: !136, type: !7)
// CHECK:STDOUT: !138 = !DILocalVariable(arg: 2, scope: !136, type: !7)
// CHECK:STDOUT: !139 = !DILocation(line: 3, column: 1, scope: !136)
// CHECK:STDOUT: !140 = !DILocation(line: 4, column: 19, scope: !136)
// CHECK:STDOUT: !141 = !{!137, !138}
// CHECK:STDOUT: !142 = distinct !DISubprogram(name: "Both", linkageName: "_CBoth.Pair.Main.f249b435619a5146", scope: null, file: !4, line: 3, type: !52, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !147)
// CHECK:STDOUT: !143 = !DILocalVariable(arg: 1, scope: !142, type: !8)
// CHECK:STDOUT: !144 = !DILocalVariable(arg: 2, scope: !142, type: !8)
// CHECK:STDOUT: !145 = !DILocation(line: 3, column: 1, scope: !142)
// CHECK:STDOUT: !146 = !DILocation(line: 4, column: 19, scope: !142)
// CHECK:STDOUT: !147 = !{!143, !144}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'mixed.carbon'
// CHECK:STDOUT: source_filename = "mixed.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @M.val.de4 = internal constant <{ <{ i2, [3 x i8] }>, [4 x i8] }> <{ <{ i2, [3 x i8] }> <{ i2 -2, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @M.val.7cc = internal constant <{ <{ i2, [7 x i8] }>, [16 x i8] }> <{ <{ i2, [7 x i8] }> <{ i2 -2, [7 x i8] zeroinitializer }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT: @M.val.287.loc6_19.7 = internal constant <{ <{ i2, [7 x i8] }>, [16 x i8] }> <{ <{ i2, [7 x i8] }> <{ i2 1, [7 x i8] zeroinitializer }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CF8.Main(ptr %m) #0 !dbg !156 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14_16.3.discriminant = getelementptr inbounds nuw <{ <{ i2, [3 x i8] }>, [4 x i8] }>, ptr %m, i32 0, i32 0, !dbg !162
// CHECK:STDOUT:   %.loc14_16.4 = load i8, ptr %.loc14_16.3.discriminant, align 1, !dbg !162
// CHECK:STDOUT:   %.loc14_16.41 = trunc i8 %.loc14_16.4 to i2, !dbg !162
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i2 -2, %.loc14_16.41, !dbg !162
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !162
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !163
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !164
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CF64.Main(ptr %m) #0 !dbg !166 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc21_16.3.discriminant = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %m, i32 0, i32 0, !dbg !172
// CHECK:STDOUT:   %.loc21_16.4 = load i8, ptr %.loc21_16.3.discriminant, align 1, !dbg !172
// CHECK:STDOUT:   %.loc21_16.41 = trunc i8 %.loc21_16.4 to i2, !dbg !172
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i2 -2, %.loc21_16.41, !dbg !172
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !172
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !173
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !174
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !176 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc27_31.1.temp = alloca <{ <{ i2, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !179
// CHECK:STDOUT:   %.loc28_34.1.temp = alloca <{ <{ i2, [7 x i8] }>, [16 x i8] }>, align 8, !dbg !184
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc27_31.1.temp), !dbg !179
// CHECK:STDOUT:   call void @_CSmall.M.Main.1590cb8a669ddba5(ptr %.loc27_31.1.temp, i32 1), !dbg !179
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc28_34.1.temp), !dbg !184
// CHECK:STDOUT:   call void @_CBig.M.Main.f249b435619a5146(ptr %.loc28_34.1.temp, i64 3, i64 4), !dbg !184
// CHECK:STDOUT:   %F8.call = call i32 @_CF8.Main(ptr %.loc27_31.1.temp), !dbg !188
// CHECK:STDOUT:   %F64.call = call i32 @_CF64.Main(ptr %.loc28_34.1.temp), !dbg !190
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %F8.call, %F64.call, !dbg !188
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call = sub i32 %Int.as.AddWith.impl.Op.call, 2, !dbg !188
// CHECK:STDOUT:   call void @"_CSelfDestruct.6b7b73594cf25b91:core.Destroy.Core"(ptr %.loc28_34.1.temp), !dbg !184
// CHECK:STDOUT:   call void @"_CSelfDestruct.d7758db37d2121cc:core.Destroy.Core"(ptr %.loc27_31.1.temp), !dbg !179
// CHECK:STDOUT:   ret i32 %Int.as.SubWith.impl.Op.call, !dbg !191
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.94410a58f39d6747:core.Destroy.Core"(ptr %self) #0 !dbg !192 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !194
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !196 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !198
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !200 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !202
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !202
// CHECK:STDOUT:   ret void, !dbg !202
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !204 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !206
// CHECK:STDOUT:   ret void, !dbg !206
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !208 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !210
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.1ac55aaed189338e:core.Destroy.Core"(ptr %self) #0 !dbg !212 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %self, i32 0, i32 1, !dbg !214
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !214
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %self, i32 0, i32 0, !dbg !214
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !214
// CHECK:STDOUT:   ret void, !dbg !214
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.1ac55aaed189338e:core.Destroy.Core"(ptr %self) #0 !dbg !216 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.1ac55aaed189338e:core.Destroy.Core"(ptr %self), !dbg !218
// CHECK:STDOUT:   ret void, !dbg !218
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.05063557e8b66ee2:core.Destroy.Core"(ptr %self) #0 !dbg !220 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !222
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.05063557e8b66ee2:core.Destroy.Core"(ptr %self) #0 !dbg !224 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.05063557e8b66ee2:core.Destroy.Core"(ptr %self), !dbg !226
// CHECK:STDOUT:   ret void, !dbg !226
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.764b0de358750156:core.Destroy.Core"(ptr %self) #0 !dbg !228 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc28_34.1.payload = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %self, i32 0, i32 1, !dbg !230
// CHECK:STDOUT:   call void @"_CSelfDestruct.05063557e8b66ee2:core.Destroy.Core"(ptr %.loc28_34.1.payload), !dbg !230
// CHECK:STDOUT:   %.loc28_34.2.discriminant = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %self, i32 0, i32 0, !dbg !230
// CHECK:STDOUT:   call void @"_CSelfDestruct.94410a58f39d6747:core.Destroy.Core"(ptr %.loc28_34.2.discriminant), !dbg !230
// CHECK:STDOUT:   ret void, !dbg !230
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.764b0de358750156:core.Destroy.Core"(ptr %self) #0 !dbg !232 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.764b0de358750156:core.Destroy.Core"(ptr %self), !dbg !234
// CHECK:STDOUT:   ret void, !dbg !234
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.6b7b73594cf25b91:core.Destroy.Core"(ptr %self) #0 !dbg !236 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !238
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.6b7b73594cf25b91:core.Destroy.Core"(ptr %self) #0 !dbg !240 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.6b7b73594cf25b91:core.Destroy.Core"(ptr %self), !dbg !242
// CHECK:STDOUT:   ret void, !dbg !242
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %self) #0 !dbg !244 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !246
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.f887018d118513f7:core.Destroy.Core"(ptr %self) #0 !dbg !248 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i8, i8 }, ptr %self, i32 0, i32 1, !dbg !250
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !250
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i8, i8 }, ptr %self, i32 0, i32 0, !dbg !250
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !250
// CHECK:STDOUT:   ret void, !dbg !250
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f887018d118513f7:core.Destroy.Core"(ptr %self) #0 !dbg !252 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.f887018d118513f7:core.Destroy.Core"(ptr %self), !dbg !254
// CHECK:STDOUT:   ret void, !dbg !254
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.c87eb1504dcb0146:core.Destroy.Core"(ptr %self) #0 !dbg !256 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !258
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.c87eb1504dcb0146:core.Destroy.Core"(ptr %self) #0 !dbg !260 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.c87eb1504dcb0146:core.Destroy.Core"(ptr %self), !dbg !262
// CHECK:STDOUT:   ret void, !dbg !262
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.59d977d2f9a36c51:core.Destroy.Core"(ptr %self) #0 !dbg !264 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc27_31.1.payload = getelementptr inbounds nuw <{ <{ i2, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !266
// CHECK:STDOUT:   call void @"_CSelfDestruct.c87eb1504dcb0146:core.Destroy.Core"(ptr %.loc27_31.1.payload), !dbg !266
// CHECK:STDOUT:   %.loc27_31.2.discriminant = getelementptr inbounds nuw <{ <{ i2, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !266
// CHECK:STDOUT:   call void @"_CSelfDestruct.94410a58f39d6747:core.Destroy.Core"(ptr %.loc27_31.2.discriminant), !dbg !266
// CHECK:STDOUT:   ret void, !dbg !266
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.59d977d2f9a36c51:core.Destroy.Core"(ptr %self) #0 !dbg !268 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.59d977d2f9a36c51:core.Destroy.Core"(ptr %self), !dbg !270
// CHECK:STDOUT:   ret void, !dbg !270
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.d7758db37d2121cc:core.Destroy.Core"(ptr %self) #0 !dbg !272 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !274
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d7758db37d2121cc:core.Destroy.Core"(ptr %self) #0 !dbg !276 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.d7758db37d2121cc:core.Destroy.Core"(ptr %self), !dbg !278
// CHECK:STDOUT:   ret void, !dbg !278
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSmall.M.Main.1590cb8a669ddba5(ptr sret(<{ <{ i2, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !280 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_19.1.discriminant = getelementptr inbounds nuw <{ <{ i2, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !282
// CHECK:STDOUT:   %.loc6_19.4.payload = getelementptr inbounds nuw <{ <{ i2, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !282
// CHECK:STDOUT:   %.loc6_19.5.Small = getelementptr inbounds nuw [4 x i8], ptr %.loc6_19.4.payload, i32 0, i32 0, !dbg !282
// CHECK:STDOUT:   %.loc7_16.2.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !283
// CHECK:STDOUT:   store { i32 } %.loc7_16.2.tuple.init, ptr %.loc6_19.5.Small, align 4, !dbg !282
// CHECK:STDOUT:   store i8 0, ptr %.loc6_19.1.discriminant, align 1, !dbg !282
// CHECK:STDOUT:   ret void, !dbg !282
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBig.M.Main.f249b435619a5146(ptr sret(<{ <{ i2, [7 x i8] }>, [16 x i8] }>) %return, i64 %_, i64 %_1) #0 !dbg !285 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_19.1.discriminant = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 0, !dbg !288
// CHECK:STDOUT:   %.loc6_19.4.payload = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 1, !dbg !288
// CHECK:STDOUT:   %.loc6_19.5.Big = getelementptr inbounds nuw [16 x i8], ptr %.loc6_19.4.payload, i32 0, i32 0, !dbg !288
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @M.val.287.loc6_19.7, i64 24, i1 false), !dbg !288
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc6_19.5.Big, i32 0, i32 0, !dbg !289
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem0.tuple.elem, align 8, !dbg !289
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc6_19.5.Big, i32 0, i32 1, !dbg !289
// CHECK:STDOUT:   store i64 %_1, ptr %tuple.elem1.tuple.elem, align 8, !dbg !289
// CHECK:STDOUT:   ret void, !dbg !288
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!149}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!7, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !16 = !{null, !8}
// CHECK:STDOUT: !17 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !18 = !{null, !9}
// CHECK:STDOUT: !19 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !20 = !{null, !7}
// CHECK:STDOUT: !21 = !DISubroutineType(types: !20)
// CHECK:STDOUT: !51 = !{!9, !8, !8}
// CHECK:STDOUT: !52 = !DISubroutineType(types: !51)
// CHECK:STDOUT: !148 = !DIFile(filename: "mixed.carbon", directory: "")
// CHECK:STDOUT: !149 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !148, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !150 = !DIBasicType(name: "int", size: 2, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !151 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_signed)
// CHECK:STDOUT: !152 = !{null, !150}
// CHECK:STDOUT: !153 = !DISubroutineType(types: !152)
// CHECK:STDOUT: !154 = !{null, !151}
// CHECK:STDOUT: !155 = !DISubroutineType(types: !154)
// CHECK:STDOUT: !156 = distinct !DISubprogram(name: "F8", linkageName: "_CF8.Main", scope: null, file: !148, line: 12, type: !11, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !165)
// CHECK:STDOUT: !157 = !DILocalVariable(arg: 1, scope: !156, type: !9)
// CHECK:STDOUT: !162 = !DILocation(line: 14, column: 5, scope: !156)
// CHECK:STDOUT: !163 = !DILocation(line: 14, column: 21, scope: !156)
// CHECK:STDOUT: !164 = !DILocation(line: 15, column: 18, scope: !156)
// CHECK:STDOUT: !165 = !{!157}
// CHECK:STDOUT: !166 = distinct !DISubprogram(name: "F64", linkageName: "_CF64.Main", scope: null, file: !148, line: 19, type: !11, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !175)
// CHECK:STDOUT: !167 = !DILocalVariable(arg: 1, scope: !166, type: !9)
// CHECK:STDOUT: !172 = !DILocation(line: 21, column: 5, scope: !166)
// CHECK:STDOUT: !173 = !DILocation(line: 21, column: 21, scope: !166)
// CHECK:STDOUT: !174 = !DILocation(line: 22, column: 18, scope: !166)
// CHECK:STDOUT: !175 = !{!167}
// CHECK:STDOUT: !176 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !148, line: 26, type: !13, spFlags: DISPFlagDefinition, unit: !149)
// CHECK:STDOUT: !179 = !DILocation(line: 27, column: 18, scope: !176)
// CHECK:STDOUT: !180 = !{!9, !7}
// CHECK:STDOUT: !181 = !DISubroutineType(types: !180)
// CHECK:STDOUT: !184 = !DILocation(line: 28, column: 19, scope: !176)
// CHECK:STDOUT: !188 = !DILocation(line: 29, column: 10, scope: !176)
// CHECK:STDOUT: !190 = !DILocation(line: 29, column: 18, scope: !176)
// CHECK:STDOUT: !191 = !DILocation(line: 29, column: 3, scope: !176)
// CHECK:STDOUT: !192 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.94410a58f39d6747:core.Destroy.Core", scope: null, file: !148, line: 28, type: !153, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !195)
// CHECK:STDOUT: !193 = !DILocalVariable(arg: 1, scope: !192, type: !150)
// CHECK:STDOUT: !194 = !DILocation(line: 28, column: 19, scope: !192)
// CHECK:STDOUT: !195 = !{!193}
// CHECK:STDOUT: !196 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !148, line: 28, type: !21, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !199)
// CHECK:STDOUT: !197 = !DILocalVariable(arg: 1, scope: !196, type: !7)
// CHECK:STDOUT: !198 = !DILocation(line: 28, column: 19, scope: !196)
// CHECK:STDOUT: !199 = !{!197}
// CHECK:STDOUT: !200 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !148, line: 28, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !203)
// CHECK:STDOUT: !201 = !DILocalVariable(arg: 1, scope: !200, type: !9)
// CHECK:STDOUT: !202 = !DILocation(line: 28, column: 19, scope: !200)
// CHECK:STDOUT: !203 = !{!201}
// CHECK:STDOUT: !204 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !148, line: 28, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !207)
// CHECK:STDOUT: !205 = !DILocalVariable(arg: 1, scope: !204, type: !9)
// CHECK:STDOUT: !206 = !DILocation(line: 28, column: 19, scope: !204)
// CHECK:STDOUT: !207 = !{!205}
// CHECK:STDOUT: !208 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !148, line: 28, type: !17, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !211)
// CHECK:STDOUT: !209 = !DILocalVariable(arg: 1, scope: !208, type: !8)
// CHECK:STDOUT: !210 = !DILocation(line: 28, column: 19, scope: !208)
// CHECK:STDOUT: !211 = !{!209}
// CHECK:STDOUT: !212 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.1ac55aaed189338e:core.Destroy.Core", scope: null, file: !148, line: 28, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !215)
// CHECK:STDOUT: !213 = !DILocalVariable(arg: 1, scope: !212, type: !9)
// CHECK:STDOUT: !214 = !DILocation(line: 28, column: 19, scope: !212)
// CHECK:STDOUT: !215 = !{!213}
// CHECK:STDOUT: !216 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.1ac55aaed189338e:core.Destroy.Core", scope: null, file: !148, line: 28, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !219)
// CHECK:STDOUT: !217 = !DILocalVariable(arg: 1, scope: !216, type: !9)
// CHECK:STDOUT: !218 = !DILocation(line: 28, column: 19, scope: !216)
// CHECK:STDOUT: !219 = !{!217}
// CHECK:STDOUT: !220 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.05063557e8b66ee2:core.Destroy.Core", scope: null, file: !148, line: 28, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !223)
// CHECK:STDOUT: !221 = !DILocalVariable(arg: 1, scope: !220, type: !9)
// CHECK:STDOUT: !222 = !DILocation(line: 28, column: 19, scope: !220)
// CHECK:STDOUT: !223 = !{!221}
// CHECK:STDOUT: !224 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.05063557e8b66ee2:core.Destroy.Core", scope: null, file: !148, line: 28, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !227)
// CHECK:STDOUT: !225 = !DILocalVariable(arg: 1, scope: !224, type: !9)
// CHECK:STDOUT: !226 = !DILocation(line: 28, column: 19, scope: !224)
// CHECK:STDOUT: !227 = !{!225}
// CHECK:STDOUT: !228 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.764b0de358750156:core.Destroy.Core", scope: null, file: !148, line: 28, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !231)
// CHECK:STDOUT: !229 = !DILocalVariable(arg: 1, scope: !228, type: !9)
// CHECK:STDOUT: !230 = !DILocation(line: 28, column: 19, scope: !228)
// CHECK:STDOUT: !231 = !{!229}
// CHECK:STDOUT: !232 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.764b0de358750156:core.Destroy.Core", scope: null, file: !148, line: 28, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !235)
// CHECK:STDOUT: !233 = !DILocalVariable(arg: 1, scope: !232, type: !9)
// CHECK:STDOUT: !234 = !DILocation(line: 28, column: 19, scope: !232)
// CHECK:STDOUT: !235 = !{!233}
// CHECK:STDOUT: !236 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.6b7b73594cf25b91:core.Destroy.Core", scope: null, file: !148, line: 28, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !239)
// CHECK:STDOUT: !237 = !DILocalVariable(arg: 1, scope: !236, type: !9)
// CHECK:STDOUT: !238 = !DILocation(line: 28, column: 19, scope: !236)
// CHECK:STDOUT: !239 = !{!237}
// CHECK:STDOUT: !240 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.6b7b73594cf25b91:core.Destroy.Core", scope: null, file: !148, line: 28, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !243)
// CHECK:STDOUT: !241 = !DILocalVariable(arg: 1, scope: !240, type: !9)
// CHECK:STDOUT: !242 = !DILocation(line: 28, column: 19, scope: !240)
// CHECK:STDOUT: !243 = !{!241}
// CHECK:STDOUT: !244 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.4954785a8b134801:core.Destroy.Core", scope: null, file: !148, line: 27, type: !155, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !247)
// CHECK:STDOUT: !245 = !DILocalVariable(arg: 1, scope: !244, type: !151)
// CHECK:STDOUT: !246 = !DILocation(line: 27, column: 18, scope: !244)
// CHECK:STDOUT: !247 = !{!245}
// CHECK:STDOUT: !248 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.f887018d118513f7:core.Destroy.Core", scope: null, file: !148, line: 27, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !251)
// CHECK:STDOUT: !249 = !DILocalVariable(arg: 1, scope: !248, type: !9)
// CHECK:STDOUT: !250 = !DILocation(line: 27, column: 18, scope: !248)
// CHECK:STDOUT: !251 = !{!249}
// CHECK:STDOUT: !252 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f887018d118513f7:core.Destroy.Core", scope: null, file: !148, line: 27, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !255)
// CHECK:STDOUT: !253 = !DILocalVariable(arg: 1, scope: !252, type: !9)
// CHECK:STDOUT: !254 = !DILocation(line: 27, column: 18, scope: !252)
// CHECK:STDOUT: !255 = !{!253}
// CHECK:STDOUT: !256 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.c87eb1504dcb0146:core.Destroy.Core", scope: null, file: !148, line: 27, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !259)
// CHECK:STDOUT: !257 = !DILocalVariable(arg: 1, scope: !256, type: !9)
// CHECK:STDOUT: !258 = !DILocation(line: 27, column: 18, scope: !256)
// CHECK:STDOUT: !259 = !{!257}
// CHECK:STDOUT: !260 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.c87eb1504dcb0146:core.Destroy.Core", scope: null, file: !148, line: 27, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !263)
// CHECK:STDOUT: !261 = !DILocalVariable(arg: 1, scope: !260, type: !9)
// CHECK:STDOUT: !262 = !DILocation(line: 27, column: 18, scope: !260)
// CHECK:STDOUT: !263 = !{!261}
// CHECK:STDOUT: !264 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.59d977d2f9a36c51:core.Destroy.Core", scope: null, file: !148, line: 27, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !267)
// CHECK:STDOUT: !265 = !DILocalVariable(arg: 1, scope: !264, type: !9)
// CHECK:STDOUT: !266 = !DILocation(line: 27, column: 18, scope: !264)
// CHECK:STDOUT: !267 = !{!265}
// CHECK:STDOUT: !268 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.59d977d2f9a36c51:core.Destroy.Core", scope: null, file: !148, line: 27, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !271)
// CHECK:STDOUT: !269 = !DILocalVariable(arg: 1, scope: !268, type: !9)
// CHECK:STDOUT: !270 = !DILocation(line: 27, column: 18, scope: !268)
// CHECK:STDOUT: !271 = !{!269}
// CHECK:STDOUT: !272 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.d7758db37d2121cc:core.Destroy.Core", scope: null, file: !148, line: 27, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !275)
// CHECK:STDOUT: !273 = !DILocalVariable(arg: 1, scope: !272, type: !9)
// CHECK:STDOUT: !274 = !DILocation(line: 27, column: 18, scope: !272)
// CHECK:STDOUT: !275 = !{!273}
// CHECK:STDOUT: !276 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d7758db37d2121cc:core.Destroy.Core", scope: null, file: !148, line: 27, type: !19, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !279)
// CHECK:STDOUT: !277 = !DILocalVariable(arg: 1, scope: !276, type: !9)
// CHECK:STDOUT: !278 = !DILocation(line: 27, column: 18, scope: !276)
// CHECK:STDOUT: !279 = !{!277}
// CHECK:STDOUT: !280 = distinct !DISubprogram(name: "Small", linkageName: "_CSmall.M.Main.1590cb8a669ddba5", scope: null, file: !148, line: 6, type: !181, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !284)
// CHECK:STDOUT: !281 = !DILocalVariable(arg: 1, scope: !280, type: !7)
// CHECK:STDOUT: !282 = !DILocation(line: 6, column: 1, scope: !280)
// CHECK:STDOUT: !283 = !DILocation(line: 7, column: 16, scope: !280)
// CHECK:STDOUT: !284 = !{!281}
// CHECK:STDOUT: !285 = distinct !DISubprogram(name: "Big", linkageName: "_CBig.M.Main.f249b435619a5146", scope: null, file: !148, line: 6, type: !52, spFlags: DISPFlagDefinition, unit: !149, retainedNodes: !290)
// CHECK:STDOUT: !286 = !DILocalVariable(arg: 1, scope: !285, type: !8)
// CHECK:STDOUT: !287 = !DILocalVariable(arg: 2, scope: !285, type: !8)
// CHECK:STDOUT: !288 = !DILocation(line: 6, column: 1, scope: !285)
// CHECK:STDOUT: !289 = !DILocation(line: 8, column: 18, scope: !285)
// CHECK:STDOUT: !290 = !{!286, !287}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'destructure.carbon'
// CHECK:STDOUT: source_filename = "destructure.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Opt.val.b51 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @Opt.val.5b3.loc6_21.7 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CGet.Main(ptr %o) #0 !dbg !293 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc13_24.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 0, !dbg !299
// CHECK:STDOUT:   %.loc13_24.4 = load i8, ptr %.loc13_24.3.discriminant, align 1, !dbg !299
// CHECK:STDOUT:   %.loc13_24.41 = trunc i8 %.loc13_24.4 to i1, !dbg !299
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc13 = icmp eq i1 false, %.loc13_24.41, !dbg !299
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc13, label %match.case.then.loc13, label %match.case.else.loc13, !dbg !299
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc13:                            ; preds = %entry
// CHECK:STDOUT:   %.loc13_24.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 1, !dbg !299
// CHECK:STDOUT:   %.loc13_24.8.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc13_24.7.payload, i32 0, i32 0, !dbg !299
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc13_24.8.Some, i32 0, i32 0, !dbg !299
// CHECK:STDOUT:   %.loc13_24.9 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !299
// CHECK:STDOUT:   ret i32 %.loc13_24.9, !dbg !302
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc13:                            ; preds = %entry
// CHECK:STDOUT:   %.loc14_16.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 0, !dbg !303
// CHECK:STDOUT:   %.loc14_16.4 = load i8, ptr %.loc14_16.3.discriminant, align 1, !dbg !303
// CHECK:STDOUT:   %.loc14_16.42 = trunc i8 %.loc14_16.4 to i1, !dbg !303
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc14 = icmp eq i1 true, %.loc14_16.42, !dbg !303
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc14, label %match.case.then.loc14, label %match.done, !dbg !303
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc14:                            ; preds = %match.case.else.loc13
// CHECK:STDOUT:   ret i32 -1, !dbg !304
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc13
// CHECK:STDOUT:   ret i32 -2, !dbg !306
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !308 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc21_37.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !311
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc21_37.1.temp), !dbg !311
// CHECK:STDOUT:   call void @_CSome.Opt.Main.84588f41d61dafba(ptr %.loc21_37.1.temp, i32 42), !dbg !311
// CHECK:STDOUT:   %Get.call = call i32 @_CGet.Main(ptr %.loc21_37.1.temp), !dbg !315
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call = sub i32 %Get.call, 42, !dbg !315
// CHECK:STDOUT:   call void @"_CSelfDestruct.46d6ea173960381e:core.Destroy.Core"(ptr %.loc21_37.1.temp), !dbg !311
// CHECK:STDOUT:   ret i32 %Int.as.SubWith.impl.Op.call, !dbg !316
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !317 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !319
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !321 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !323
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !325 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !327
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !327
// CHECK:STDOUT:   ret void, !dbg !327
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !329 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !331
// CHECK:STDOUT:   ret void, !dbg !331
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e8ee17acba240768:core.Destroy.Core"(ptr %self) #0 !dbg !333 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !335
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e8ee17acba240768:core.Destroy.Core"(ptr %self) #0 !dbg !337 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e8ee17acba240768:core.Destroy.Core"(ptr %self), !dbg !339
// CHECK:STDOUT:   ret void, !dbg !339
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e994aeee33fac1a0:core.Destroy.Core"(ptr %self) #0 !dbg !341 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc21_37.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !343
// CHECK:STDOUT:   call void @"_CSelfDestruct.e8ee17acba240768:core.Destroy.Core"(ptr %.loc21_37.1.payload), !dbg !343
// CHECK:STDOUT:   %.loc21_37.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !343
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc21_37.2.discriminant), !dbg !343
// CHECK:STDOUT:   ret void, !dbg !343
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e994aeee33fac1a0:core.Destroy.Core"(ptr %self) #0 !dbg !345 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e994aeee33fac1a0:core.Destroy.Core"(ptr %self), !dbg !347
// CHECK:STDOUT:   ret void, !dbg !347
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.46d6ea173960381e:core.Destroy.Core"(ptr %self) #0 !dbg !349 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !351
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.46d6ea173960381e:core.Destroy.Core"(ptr %self) #0 !dbg !353 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.46d6ea173960381e:core.Destroy.Core"(ptr %self), !dbg !355
// CHECK:STDOUT:   ret void, !dbg !355
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSome.Opt.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !357 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_21.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !359
// CHECK:STDOUT:   %.loc6_21.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !359
// CHECK:STDOUT:   %.loc6_21.5.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc6_21.4.payload, i32 0, i32 0, !dbg !359
// CHECK:STDOUT:   %.loc7_17.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !360
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Opt.val.5b3.loc6_21.7, i64 8, i1 false), !dbg !359
// CHECK:STDOUT:   store { i32 } %.loc7_17.1.tuple.init, ptr %.loc6_21.5.Some, align 4, !dbg !359
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc6_21.5.Some, i32 0, i32 0, !dbg !360
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !360
// CHECK:STDOUT:   ret void, !dbg !359
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!292}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!7, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{null, !6}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !18 = !{null, !9}
// CHECK:STDOUT: !19 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !20 = !{null, !7}
// CHECK:STDOUT: !21 = !DISubroutineType(types: !20)
// CHECK:STDOUT: !180 = !{!9, !7}
// CHECK:STDOUT: !181 = !DISubroutineType(types: !180)
// CHECK:STDOUT: !291 = !DIFile(filename: "destructure.carbon", directory: "")
// CHECK:STDOUT: !292 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !291, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !293 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Main", scope: null, file: !291, line: 11, type: !11, spFlags: DISPFlagDefinition, unit: !292, retainedNodes: !307)
// CHECK:STDOUT: !294 = !DILocalVariable(arg: 1, scope: !293, type: !9)
// CHECK:STDOUT: !299 = !DILocation(line: 13, column: 5, scope: !293)
// CHECK:STDOUT: !302 = !DILocation(line: 13, column: 29, scope: !293)
// CHECK:STDOUT: !303 = !DILocation(line: 14, column: 5, scope: !293)
// CHECK:STDOUT: !304 = !DILocation(line: 14, column: 21, scope: !293)
// CHECK:STDOUT: !306 = !DILocation(line: 17, column: 3, scope: !293)
// CHECK:STDOUT: !307 = !{!294}
// CHECK:STDOUT: !308 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !291, line: 20, type: !13, spFlags: DISPFlagDefinition, unit: !292)
// CHECK:STDOUT: !311 = !DILocation(line: 21, column: 21, scope: !308)
// CHECK:STDOUT: !315 = !DILocation(line: 22, column: 10, scope: !308)
// CHECK:STDOUT: !316 = !DILocation(line: 22, column: 3, scope: !308)
// CHECK:STDOUT: !317 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !291, line: 21, type: !15, spFlags: DISPFlagDefinition, unit: !292, retainedNodes: !320)
// CHECK:STDOUT: !318 = !DILocalVariable(arg: 1, scope: !317, type: !6)
// CHECK:STDOUT: !319 = !DILocation(line: 21, column: 21, scope: !317)
// CHECK:STDOUT: !320 = !{!318}
// CHECK:STDOUT: !321 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !291, line: 21, type: !21, spFlags: DISPFlagDefinition, unit: !292, retainedNodes: !324)
// CHECK:STDOUT: !322 = !DILocalVariable(arg: 1, scope: !321, type: !7)
// CHECK:STDOUT: !323 = !DILocation(line: 21, column: 21, scope: !321)
// CHECK:STDOUT: !324 = !{!322}
// CHECK:STDOUT: !325 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !291, line: 21, type: !19, spFlags: DISPFlagDefinition, unit: !292, retainedNodes: !328)
// CHECK:STDOUT: !326 = !DILocalVariable(arg: 1, scope: !325, type: !9)
// CHECK:STDOUT: !327 = !DILocation(line: 21, column: 21, scope: !325)
// CHECK:STDOUT: !328 = !{!326}
// CHECK:STDOUT: !329 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !291, line: 21, type: !19, spFlags: DISPFlagDefinition, unit: !292, retainedNodes: !332)
// CHECK:STDOUT: !330 = !DILocalVariable(arg: 1, scope: !329, type: !9)
// CHECK:STDOUT: !331 = !DILocation(line: 21, column: 21, scope: !329)
// CHECK:STDOUT: !332 = !{!330}
// CHECK:STDOUT: !333 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e8ee17acba240768:core.Destroy.Core", scope: null, file: !291, line: 21, type: !19, spFlags: DISPFlagDefinition, unit: !292, retainedNodes: !336)
// CHECK:STDOUT: !334 = !DILocalVariable(arg: 1, scope: !333, type: !9)
// CHECK:STDOUT: !335 = !DILocation(line: 21, column: 21, scope: !333)
// CHECK:STDOUT: !336 = !{!334}
// CHECK:STDOUT: !337 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e8ee17acba240768:core.Destroy.Core", scope: null, file: !291, line: 21, type: !19, spFlags: DISPFlagDefinition, unit: !292, retainedNodes: !340)
// CHECK:STDOUT: !338 = !DILocalVariable(arg: 1, scope: !337, type: !9)
// CHECK:STDOUT: !339 = !DILocation(line: 21, column: 21, scope: !337)
// CHECK:STDOUT: !340 = !{!338}
// CHECK:STDOUT: !341 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e994aeee33fac1a0:core.Destroy.Core", scope: null, file: !291, line: 21, type: !19, spFlags: DISPFlagDefinition, unit: !292, retainedNodes: !344)
// CHECK:STDOUT: !342 = !DILocalVariable(arg: 1, scope: !341, type: !9)
// CHECK:STDOUT: !343 = !DILocation(line: 21, column: 21, scope: !341)
// CHECK:STDOUT: !344 = !{!342}
// CHECK:STDOUT: !345 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e994aeee33fac1a0:core.Destroy.Core", scope: null, file: !291, line: 21, type: !19, spFlags: DISPFlagDefinition, unit: !292, retainedNodes: !348)
// CHECK:STDOUT: !346 = !DILocalVariable(arg: 1, scope: !345, type: !9)
// CHECK:STDOUT: !347 = !DILocation(line: 21, column: 21, scope: !345)
// CHECK:STDOUT: !348 = !{!346}
// CHECK:STDOUT: !349 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.46d6ea173960381e:core.Destroy.Core", scope: null, file: !291, line: 21, type: !19, spFlags: DISPFlagDefinition, unit: !292, retainedNodes: !352)
// CHECK:STDOUT: !350 = !DILocalVariable(arg: 1, scope: !349, type: !9)
// CHECK:STDOUT: !351 = !DILocation(line: 21, column: 21, scope: !349)
// CHECK:STDOUT: !352 = !{!350}
// CHECK:STDOUT: !353 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.46d6ea173960381e:core.Destroy.Core", scope: null, file: !291, line: 21, type: !19, spFlags: DISPFlagDefinition, unit: !292, retainedNodes: !356)
// CHECK:STDOUT: !354 = !DILocalVariable(arg: 1, scope: !353, type: !9)
// CHECK:STDOUT: !355 = !DILocation(line: 21, column: 21, scope: !353)
// CHECK:STDOUT: !356 = !{!354}
// CHECK:STDOUT: !357 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Opt.Main.84588f41d61dafba", scope: null, file: !291, line: 6, type: !181, spFlags: DISPFlagDefinition, unit: !292, retainedNodes: !361)
// CHECK:STDOUT: !358 = !DILocalVariable(arg: 1, scope: !357, type: !7)
// CHECK:STDOUT: !359 = !DILocation(line: 6, column: 1, scope: !357)
// CHECK:STDOUT: !360 = !DILocation(line: 7, column: 17, scope: !357)
// CHECK:STDOUT: !361 = !{!358}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'optional.carbon'
// CHECK:STDOUT: source_filename = "optional.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Optional.val.dae = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @Optional.val.dae.None.ref = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @Optional.val.b3e.loc5_26.7 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CIsPresent.Main(ptr %o) #0 !dbg !364 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12_16.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 0, !dbg !370
// CHECK:STDOUT:   %.loc12_16.4 = load i8, ptr %.loc12_16.3.discriminant, align 1, !dbg !370
// CHECK:STDOUT:   %.loc12_16.41 = trunc i8 %.loc12_16.4 to i1, !dbg !370
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc12_16.41, !dbg !370
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !370
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !371
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !372
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !374 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc22_47.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !383
// CHECK:STDOUT:   %IsPresent.call.loc19 = call i32 @_CIsPresent.Main(ptr @Optional.val.dae.None.ref), !dbg !380
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.call = icmp ne i32 %IsPresent.call.loc19, 0, !dbg !380
// CHECK:STDOUT:   br i1 %Int.as.EqWith.impl.NotEqual.call, label %if.then, label %if.else, !dbg !381
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !382
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc22_47.1.temp), !dbg !383
// CHECK:STDOUT:   call void @_CSome.Optional.Main.84588f41d61dafba(ptr %.loc22_47.1.temp, i32 42), !dbg !383
// CHECK:STDOUT:   %IsPresent.call.loc23 = call i32 @_CIsPresent.Main(ptr %.loc22_47.1.temp), !dbg !387
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call = sub i32 %IsPresent.call.loc23, 1, !dbg !387
// CHECK:STDOUT:   call void @"_CSelfDestruct.d7e3fe607b19752d:core.Destroy.Core"(ptr %.loc22_47.1.temp), !dbg !383
// CHECK:STDOUT:   ret i32 %Int.as.SubWith.impl.Op.call, !dbg !388
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !389 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !391
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !393 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !395
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !397 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !399
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !399
// CHECK:STDOUT:   ret void, !dbg !399
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !401 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !403
// CHECK:STDOUT:   ret void, !dbg !403
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e8ee17acba240768:core.Destroy.Core"(ptr %self) #0 !dbg !405 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !407
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e8ee17acba240768:core.Destroy.Core"(ptr %self) #0 !dbg !409 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e8ee17acba240768:core.Destroy.Core"(ptr %self), !dbg !411
// CHECK:STDOUT:   ret void, !dbg !411
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e994aeee33fac1a0:core.Destroy.Core"(ptr %self) #0 !dbg !413 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc22_47.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !415
// CHECK:STDOUT:   call void @"_CSelfDestruct.e8ee17acba240768:core.Destroy.Core"(ptr %.loc22_47.1.payload), !dbg !415
// CHECK:STDOUT:   %.loc22_47.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !415
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc22_47.2.discriminant), !dbg !415
// CHECK:STDOUT:   ret void, !dbg !415
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e994aeee33fac1a0:core.Destroy.Core"(ptr %self) #0 !dbg !417 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e994aeee33fac1a0:core.Destroy.Core"(ptr %self), !dbg !419
// CHECK:STDOUT:   ret void, !dbg !419
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.d7e3fe607b19752d:core.Destroy.Core"(ptr %self) #0 !dbg !421 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !423
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d7e3fe607b19752d:core.Destroy.Core"(ptr %self) #0 !dbg !425 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.d7e3fe607b19752d:core.Destroy.Core"(ptr %self), !dbg !427
// CHECK:STDOUT:   ret void, !dbg !427
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSome.Optional.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !429 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc5_26.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !431
// CHECK:STDOUT:   %.loc5_26.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !431
// CHECK:STDOUT:   %.loc5_26.5.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc5_26.4.payload, i32 0, i32 0, !dbg !431
// CHECK:STDOUT:   %.loc6_17.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !432
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Optional.val.b3e.loc5_26.7, i64 8, i1 false), !dbg !431
// CHECK:STDOUT:   store { i32 } %.loc6_17.1.tuple.init, ptr %.loc5_26.5.Some, align 4, !dbg !431
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc5_26.5.Some, i32 0, i32 0, !dbg !432
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !432
// CHECK:STDOUT:   ret void, !dbg !431
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!363}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!7, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{null, !6}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !18 = !{null, !9}
// CHECK:STDOUT: !19 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !20 = !{null, !7}
// CHECK:STDOUT: !21 = !DISubroutineType(types: !20)
// CHECK:STDOUT: !180 = !{!9, !7}
// CHECK:STDOUT: !181 = !DISubroutineType(types: !180)
// CHECK:STDOUT: !362 = !DIFile(filename: "optional.carbon", directory: "")
// CHECK:STDOUT: !363 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !362, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !364 = distinct !DISubprogram(name: "IsPresent", linkageName: "_CIsPresent.Main", scope: null, file: !362, line: 10, type: !11, spFlags: DISPFlagDefinition, unit: !363, retainedNodes: !373)
// CHECK:STDOUT: !365 = !DILocalVariable(arg: 1, scope: !364, type: !9)
// CHECK:STDOUT: !370 = !DILocation(line: 12, column: 5, scope: !364)
// CHECK:STDOUT: !371 = !DILocation(line: 12, column: 21, scope: !364)
// CHECK:STDOUT: !372 = !DILocation(line: 13, column: 18, scope: !364)
// CHECK:STDOUT: !373 = !{!365}
// CHECK:STDOUT: !374 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !362, line: 17, type: !13, spFlags: DISPFlagDefinition, unit: !363)
// CHECK:STDOUT: !380 = !DILocation(line: 19, column: 7, scope: !374)
// CHECK:STDOUT: !381 = !DILocation(line: 19, column: 6, scope: !374)
// CHECK:STDOUT: !382 = !DILocation(line: 20, column: 5, scope: !374)
// CHECK:STDOUT: !383 = !DILocation(line: 22, column: 26, scope: !374)
// CHECK:STDOUT: !387 = !DILocation(line: 23, column: 10, scope: !374)
// CHECK:STDOUT: !388 = !DILocation(line: 23, column: 3, scope: !374)
// CHECK:STDOUT: !389 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !362, line: 22, type: !15, spFlags: DISPFlagDefinition, unit: !363, retainedNodes: !392)
// CHECK:STDOUT: !390 = !DILocalVariable(arg: 1, scope: !389, type: !6)
// CHECK:STDOUT: !391 = !DILocation(line: 22, column: 26, scope: !389)
// CHECK:STDOUT: !392 = !{!390}
// CHECK:STDOUT: !393 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !362, line: 22, type: !21, spFlags: DISPFlagDefinition, unit: !363, retainedNodes: !396)
// CHECK:STDOUT: !394 = !DILocalVariable(arg: 1, scope: !393, type: !7)
// CHECK:STDOUT: !395 = !DILocation(line: 22, column: 26, scope: !393)
// CHECK:STDOUT: !396 = !{!394}
// CHECK:STDOUT: !397 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !362, line: 22, type: !19, spFlags: DISPFlagDefinition, unit: !363, retainedNodes: !400)
// CHECK:STDOUT: !398 = !DILocalVariable(arg: 1, scope: !397, type: !9)
// CHECK:STDOUT: !399 = !DILocation(line: 22, column: 26, scope: !397)
// CHECK:STDOUT: !400 = !{!398}
// CHECK:STDOUT: !401 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !362, line: 22, type: !19, spFlags: DISPFlagDefinition, unit: !363, retainedNodes: !404)
// CHECK:STDOUT: !402 = !DILocalVariable(arg: 1, scope: !401, type: !9)
// CHECK:STDOUT: !403 = !DILocation(line: 22, column: 26, scope: !401)
// CHECK:STDOUT: !404 = !{!402}
// CHECK:STDOUT: !405 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e8ee17acba240768:core.Destroy.Core", scope: null, file: !362, line: 22, type: !19, spFlags: DISPFlagDefinition, unit: !363, retainedNodes: !408)
// CHECK:STDOUT: !406 = !DILocalVariable(arg: 1, scope: !405, type: !9)
// CHECK:STDOUT: !407 = !DILocation(line: 22, column: 26, scope: !405)
// CHECK:STDOUT: !408 = !{!406}
// CHECK:STDOUT: !409 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e8ee17acba240768:core.Destroy.Core", scope: null, file: !362, line: 22, type: !19, spFlags: DISPFlagDefinition, unit: !363, retainedNodes: !412)
// CHECK:STDOUT: !410 = !DILocalVariable(arg: 1, scope: !409, type: !9)
// CHECK:STDOUT: !411 = !DILocation(line: 22, column: 26, scope: !409)
// CHECK:STDOUT: !412 = !{!410}
// CHECK:STDOUT: !413 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e994aeee33fac1a0:core.Destroy.Core", scope: null, file: !362, line: 22, type: !19, spFlags: DISPFlagDefinition, unit: !363, retainedNodes: !416)
// CHECK:STDOUT: !414 = !DILocalVariable(arg: 1, scope: !413, type: !9)
// CHECK:STDOUT: !415 = !DILocation(line: 22, column: 26, scope: !413)
// CHECK:STDOUT: !416 = !{!414}
// CHECK:STDOUT: !417 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e994aeee33fac1a0:core.Destroy.Core", scope: null, file: !362, line: 22, type: !19, spFlags: DISPFlagDefinition, unit: !363, retainedNodes: !420)
// CHECK:STDOUT: !418 = !DILocalVariable(arg: 1, scope: !417, type: !9)
// CHECK:STDOUT: !419 = !DILocation(line: 22, column: 26, scope: !417)
// CHECK:STDOUT: !420 = !{!418}
// CHECK:STDOUT: !421 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.d7e3fe607b19752d:core.Destroy.Core", scope: null, file: !362, line: 22, type: !19, spFlags: DISPFlagDefinition, unit: !363, retainedNodes: !424)
// CHECK:STDOUT: !422 = !DILocalVariable(arg: 1, scope: !421, type: !9)
// CHECK:STDOUT: !423 = !DILocation(line: 22, column: 26, scope: !421)
// CHECK:STDOUT: !424 = !{!422}
// CHECK:STDOUT: !425 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d7e3fe607b19752d:core.Destroy.Core", scope: null, file: !362, line: 22, type: !19, spFlags: DISPFlagDefinition, unit: !363, retainedNodes: !428)
// CHECK:STDOUT: !426 = !DILocalVariable(arg: 1, scope: !425, type: !9)
// CHECK:STDOUT: !427 = !DILocation(line: 22, column: 26, scope: !425)
// CHECK:STDOUT: !428 = !{!426}
// CHECK:STDOUT: !429 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Main.84588f41d61dafba", scope: null, file: !362, line: 5, type: !181, spFlags: DISPFlagDefinition, unit: !363, retainedNodes: !433)
// CHECK:STDOUT: !430 = !DILocalVariable(arg: 1, scope: !429, type: !7)
// CHECK:STDOUT: !431 = !DILocation(line: 5, column: 1, scope: !429)
// CHECK:STDOUT: !432 = !DILocation(line: 6, column: 17, scope: !429)
// CHECK:STDOUT: !433 = !{!430}
// CHECK:STDOUT:

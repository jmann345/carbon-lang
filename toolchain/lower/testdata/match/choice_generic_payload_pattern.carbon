// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/choice_generic_payload_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/choice_generic_payload_pattern.carbon

// What this pins beyond the S3b lower goldens (W5-S3c): ELEMENT extraction
// from the payload region per specific. S3b's destructure subfile
// (lower/testdata/choice/generic_payload.carbon) extracts a single-element
// payload from one specific; here the same generic choice destructures in
// two specifics with multi-element payloads, so the second element's
// offset differs per specific — `Pair(i32)`'s `(i32, i32)` reads at byte
// offsets 0 and 4 inside `[8 x i8]`, and `Pair(i64)`'s `(i64, i64)` at 0
// and 8 inside `[16 x i8]` (F-007k; risk R-1's derived numbers). Equal
// offsets across the specifics, or extraction through a stale region
// type, falsify the per-specific resolution. The symbolic subfile pins the
// R-8 lowering shape: a generic BODY's destructure instantiated at a
// concrete specific extracts through the substituted layout.

// --- two_sizes_destructure.carbon
library "[[@TEST_NAME]]";

choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

fn Sum32(p: Pair(i32)) -> i32 {
  match (p) {
    case .Both(x: i32, y: i32) => { return x + y; }
    case .Neither => { return 0; }
  }
  // Unreachable: every arm returns.
  return -1;
}

fn Sum64(p: Pair(i64)) -> i64 {
  match (p) {
    case .Both(x: i64, y: i64) => { return x + y; }
    case .Neither => { return 0; }
  }
  // Unreachable: every arm returns.
  return -1;
}

fn Run() -> i32 {
  let a: Pair(i32) = Pair(i32).Both(1, 2);
  let b: Pair(i64) = Pair(i64).Both(3, 4);
  if (Sum64(b) != 7) {
    return 1;
  }
  return Sum32(a) - 3;
}

// --- symbolic.carbon
library "[[@TEST_NAME]]";

// The check-side symbolic subfile's lower counterpart
// (check/testdata/match/choice_generic_payload_pattern.carbon): the generic
// body's destructure is checked against the symbolic payload tuple, and
// `Call`'s `Classify(Pair-shaped P(i32))` instantiation lowers the element
// accesses through the specific's recomputed `[8 x i8]` region.
choice P(T: type) {
  Both(x: T, y: T),
  Neither
}

fn Discard[U: type](_: U, _: U) {}

fn Classify[T: type](p: P(T)) -> i32 {
  match (p) {
    case .Both(a: T, b: T) => {
      Discard(a, b);
      return 1;
    }
    case .Neither => { return 0; }
  }
  // Unreachable: every arm returns.
  return -1;
}

fn Call(p: P(i32)) -> i32 {
  return Classify(p);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'two_sizes_destructure.carbon'
// CHECK:STDOUT: source_filename = "two_sizes_destructure.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Pair.val.6e7 = internal constant <{ <{ i1, [3 x i8] }>, [8 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @Pair.val.765 = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT: @Pair.val.cf1.loc3_22.7 = internal constant <{ <{ i1, [3 x i8] }>, [8 x i8] }> zeroinitializer
// CHECK:STDOUT: @Pair.val.790.loc3_22.7 = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CSum32.Main(ptr %p) #0 !dbg !24 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_32.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %p, i32 0, i32 0, !dbg !30
// CHECK:STDOUT:   %.loc10_32.4 = load i8, ptr %.loc10_32.3.discriminant, align 1, !dbg !30
// CHECK:STDOUT:   %.loc10_32.41 = trunc i8 %.loc10_32.4 to i1, !dbg !30
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc10 = icmp eq i1 false, %.loc10_32.41, !dbg !30
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc10, label %match.case.then.loc10, label %match.case.else.loc10, !dbg !30
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc10:                            ; preds = %entry
// CHECK:STDOUT:   %.loc10_32.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %p, i32 0, i32 1, !dbg !30
// CHECK:STDOUT:   %.loc10_32.8.Both = getelementptr inbounds nuw [8 x i8], ptr %.loc10_32.7.payload, i32 0, i32 0, !dbg !30
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc10_32.8.Both, i32 0, i32 0, !dbg !30
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc10_32.8.Both, i32 0, i32 1, !dbg !30
// CHECK:STDOUT:   %.loc10_32.9 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !30
// CHECK:STDOUT:   %.loc10_32.10 = load i32, ptr %tuple.elem1.tuple.elem, align 4, !dbg !30
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc10_32.9, %.loc10_32.10, !dbg !33
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !35
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc10:                            ; preds = %entry
// CHECK:STDOUT:   %.loc11_19.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %p, i32 0, i32 0, !dbg !36
// CHECK:STDOUT:   %.loc11_19.4 = load i8, ptr %.loc11_19.3.discriminant, align 1, !dbg !36
// CHECK:STDOUT:   %.loc11_19.42 = trunc i8 %.loc11_19.4 to i1, !dbg !36
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc11 = icmp eq i1 true, %.loc11_19.42, !dbg !36
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc11, label %match.case.then.loc11, label %match.done, !dbg !36
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc11:                            ; preds = %match.case.else.loc10
// CHECK:STDOUT:   ret i32 0, !dbg !37
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc10
// CHECK:STDOUT:   ret i32 -1, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CSum64.Main(ptr %p) #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_32.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %p, i32 0, i32 0, !dbg !47
// CHECK:STDOUT:   %.loc19_32.4 = load i8, ptr %.loc19_32.3.discriminant, align 1, !dbg !47
// CHECK:STDOUT:   %.loc19_32.41 = trunc i8 %.loc19_32.4 to i1, !dbg !47
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc19 = icmp eq i1 false, %.loc19_32.41, !dbg !47
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc19, label %match.case.then.loc19, label %match.case.else.loc19, !dbg !47
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc19:                            ; preds = %entry
// CHECK:STDOUT:   %.loc19_32.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %p, i32 0, i32 1, !dbg !47
// CHECK:STDOUT:   %.loc19_32.8.Both = getelementptr inbounds nuw [16 x i8], ptr %.loc19_32.7.payload, i32 0, i32 0, !dbg !47
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc19_32.8.Both, i32 0, i32 0, !dbg !47
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc19_32.8.Both, i32 0, i32 1, !dbg !47
// CHECK:STDOUT:   %.loc19_32.9 = load i64, ptr %tuple.elem0.tuple.elem, align 8, !dbg !47
// CHECK:STDOUT:   %.loc19_32.10 = load i64, ptr %tuple.elem1.tuple.elem, align 8, !dbg !47
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i64 %.loc19_32.9, %.loc19_32.10, !dbg !50
// CHECK:STDOUT:   ret i64 %Int.as.AddWith.impl.Op.call, !dbg !52
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc19:                            ; preds = %entry
// CHECK:STDOUT:   %.loc20_19.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %p, i32 0, i32 0, !dbg !53
// CHECK:STDOUT:   %.loc20_19.4 = load i8, ptr %.loc20_19.3.discriminant, align 1, !dbg !53
// CHECK:STDOUT:   %.loc20_19.42 = trunc i8 %.loc20_19.4 to i1, !dbg !53
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc20 = icmp eq i1 true, %.loc20_19.42, !dbg !53
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc20, label %match.case.then.loc20, label %match.done, !dbg !53
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc20:                            ; preds = %match.case.else.loc19
// CHECK:STDOUT:   ret i64 0, !dbg !54
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc19
// CHECK:STDOUT:   ret i64 -1, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc27_41.1.temp = alloca <{ <{ i1, [3 x i8] }>, [8 x i8] }>, align 4, !dbg !61
// CHECK:STDOUT:   %.loc28_41.1.temp = alloca <{ <{ i1, [7 x i8] }>, [16 x i8] }>, align 8, !dbg !66
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc27_41.1.temp), !dbg !61
// CHECK:STDOUT:   call void @_CBoth.Pair.Main.84588f41d61dafba(ptr %.loc27_41.1.temp, i32 1, i32 2), !dbg !61
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc28_41.1.temp), !dbg !66
// CHECK:STDOUT:   call void @_CBoth.Pair.Main.f249b435619a5146(ptr %.loc28_41.1.temp, i64 3, i64 4), !dbg !66
// CHECK:STDOUT:   %Sum64.call = call i64 @_CSum64.Main(ptr %.loc28_41.1.temp), !dbg !72
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.call = icmp ne i64 %Sum64.call, 7, !dbg !72
// CHECK:STDOUT:   br i1 %Int.as.EqWith.impl.NotEqual.call, label %if.then, label %if.else, !dbg !73
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @"_CSelfDestruct.01ad5b36ba6d1c53:core.Destroy.Core"(ptr %.loc28_41.1.temp), !dbg !66
// CHECK:STDOUT:   call void @"_CSelfDestruct.1eef18dc43ad9a55:core.Destroy.Core"(ptr %.loc27_41.1.temp), !dbg !61
// CHECK:STDOUT:   ret i32 1, !dbg !74
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   %Sum32.call = call i32 @_CSum32.Main(ptr %.loc27_41.1.temp), !dbg !76
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call = sub i32 %Sum32.call, 3, !dbg !76
// CHECK:STDOUT:   call void @"_CSelfDestruct.01ad5b36ba6d1c53:core.Destroy.Core"(ptr %.loc28_41.1.temp), !dbg !66
// CHECK:STDOUT:   call void @"_CSelfDestruct.1eef18dc43ad9a55:core.Destroy.Core"(ptr %.loc27_41.1.temp), !dbg !61
// CHECK:STDOUT:   ret i32 %Int.as.SubWith.impl.Op.call, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !78 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !80
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !82 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !84
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.1ac55aaed189338e:core.Destroy.Core"(ptr %self) #0 !dbg !86 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %self, i32 0, i32 1, !dbg !88
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !88
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %self, i32 0, i32 0, !dbg !88
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !88
// CHECK:STDOUT:   ret void, !dbg !88
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.1ac55aaed189338e:core.Destroy.Core"(ptr %self) #0 !dbg !90 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.1ac55aaed189338e:core.Destroy.Core"(ptr %self), !dbg !92
// CHECK:STDOUT:   ret void, !dbg !92
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.58ec237e1038f3e7:core.Destroy.Core"(ptr %self) #0 !dbg !94 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !96
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.58ec237e1038f3e7:core.Destroy.Core"(ptr %self) #0 !dbg !98 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.58ec237e1038f3e7:core.Destroy.Core"(ptr %self), !dbg !100
// CHECK:STDOUT:   ret void, !dbg !100
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.8acada488d131cf2:core.Destroy.Core"(ptr %self) #0 !dbg !102 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc28_41.1.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %self, i32 0, i32 1, !dbg !104
// CHECK:STDOUT:   call void @"_CSelfDestruct.58ec237e1038f3e7:core.Destroy.Core"(ptr %.loc28_41.1.payload), !dbg !104
// CHECK:STDOUT:   %.loc28_41.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %self, i32 0, i32 0, !dbg !104
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc28_41.2.discriminant), !dbg !104
// CHECK:STDOUT:   ret void, !dbg !104
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.8acada488d131cf2:core.Destroy.Core"(ptr %self) #0 !dbg !106 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.8acada488d131cf2:core.Destroy.Core"(ptr %self), !dbg !108
// CHECK:STDOUT:   ret void, !dbg !108
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.01ad5b36ba6d1c53:core.Destroy.Core"(ptr %self) #0 !dbg !110 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !112
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.01ad5b36ba6d1c53:core.Destroy.Core"(ptr %self) #0 !dbg !114 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.01ad5b36ba6d1c53:core.Destroy.Core"(ptr %self), !dbg !116
// CHECK:STDOUT:   ret void, !dbg !116
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !118 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !120
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !122 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !124
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !124
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !124
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !124
// CHECK:STDOUT:   ret void, !dbg !124
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !126 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self), !dbg !128
// CHECK:STDOUT:   ret void, !dbg !128
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.20c1b1147da3b52d:core.Destroy.Core"(ptr %self) #0 !dbg !130 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !132
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.20c1b1147da3b52d:core.Destroy.Core"(ptr %self) #0 !dbg !134 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.20c1b1147da3b52d:core.Destroy.Core"(ptr %self), !dbg !136
// CHECK:STDOUT:   ret void, !dbg !136
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.92cfe67cb2f4b128:core.Destroy.Core"(ptr %self) #0 !dbg !138 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc27_41.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !140
// CHECK:STDOUT:   call void @"_CSelfDestruct.20c1b1147da3b52d:core.Destroy.Core"(ptr %.loc27_41.1.payload), !dbg !140
// CHECK:STDOUT:   %.loc27_41.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !140
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc27_41.2.discriminant), !dbg !140
// CHECK:STDOUT:   ret void, !dbg !140
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.92cfe67cb2f4b128:core.Destroy.Core"(ptr %self) #0 !dbg !142 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.92cfe67cb2f4b128:core.Destroy.Core"(ptr %self), !dbg !144
// CHECK:STDOUT:   ret void, !dbg !144
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.1eef18dc43ad9a55:core.Destroy.Core"(ptr %self) #0 !dbg !146 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !148
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.1eef18dc43ad9a55:core.Destroy.Core"(ptr %self) #0 !dbg !150 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.1eef18dc43ad9a55:core.Destroy.Core"(ptr %self), !dbg !152
// CHECK:STDOUT:   ret void, !dbg !152
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBoth.Pair.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [8 x i8] }>) %return, i32 %_, i32 %_1) #0 !dbg !154 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_22.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !157
// CHECK:STDOUT:   %.loc3_22.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !157
// CHECK:STDOUT:   %.loc3_22.5.Both = getelementptr inbounds nuw [8 x i8], ptr %.loc3_22.4.payload, i32 0, i32 0, !dbg !157
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Pair.val.cf1.loc3_22.7, i64 12, i1 false), !dbg !157
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc3_22.5.Both, i32 0, i32 0, !dbg !158
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !158
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc3_22.5.Both, i32 0, i32 1, !dbg !158
// CHECK:STDOUT:   store i32 %_1, ptr %tuple.elem1.tuple.elem, align 4, !dbg !158
// CHECK:STDOUT:   ret void, !dbg !157
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBoth.Pair.Main.f249b435619a5146(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>) %return, i64 %_, i64 %_1) #0 !dbg !160 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_22.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 0, !dbg !163
// CHECK:STDOUT:   %.loc3_22.4.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 1, !dbg !163
// CHECK:STDOUT:   %.loc3_22.5.Both = getelementptr inbounds nuw [16 x i8], ptr %.loc3_22.4.payload, i32 0, i32 0, !dbg !163
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @Pair.val.790.loc3_22.7, i64 24, i1 false), !dbg !163
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc3_22.5.Both, i32 0, i32 0, !dbg !164
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem0.tuple.elem, align 8, !dbg !164
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc3_22.5.Both, i32 0, i32 1, !dbg !164
// CHECK:STDOUT:   store i64 %_1, ptr %tuple.elem1.tuple.elem, align 8, !dbg !164
// CHECK:STDOUT:   ret void, !dbg !163
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.01ad5b36ba6d1c53:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.1eef18dc43ad9a55:core.Destroy.Core", { 1, 0 }
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
// CHECK:STDOUT: !4 = !DIFile(filename: "two_sizes_destructure.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!7, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!8, !9}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{!7}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !16 = !{null, !6}
// CHECK:STDOUT: !17 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !18 = !{null, !8}
// CHECK:STDOUT: !19 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !20 = !{null, !9}
// CHECK:STDOUT: !21 = !DISubroutineType(types: !20)
// CHECK:STDOUT: !22 = !{null, !7}
// CHECK:STDOUT: !23 = !DISubroutineType(types: !22)
// CHECK:STDOUT: !24 = distinct !DISubprogram(name: "Sum32", linkageName: "_CSum32.Main", scope: null, file: !4, line: 8, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !40)
// CHECK:STDOUT: !25 = !DILocalVariable(arg: 1, scope: !24, type: !9)
// CHECK:STDOUT: !30 = !DILocation(line: 10, column: 5, scope: !24)
// CHECK:STDOUT: !33 = !DILocation(line: 10, column: 44, scope: !24)
// CHECK:STDOUT: !35 = !DILocation(line: 10, column: 37, scope: !24)
// CHECK:STDOUT: !36 = !DILocation(line: 11, column: 5, scope: !24)
// CHECK:STDOUT: !37 = !DILocation(line: 11, column: 24, scope: !24)
// CHECK:STDOUT: !39 = !DILocation(line: 14, column: 3, scope: !24)
// CHECK:STDOUT: !40 = !{!25}
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "Sum64", linkageName: "_CSum64.Main", scope: null, file: !4, line: 17, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !57)
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !41, type: !9)
// CHECK:STDOUT: !47 = !DILocation(line: 19, column: 5, scope: !41)
// CHECK:STDOUT: !50 = !DILocation(line: 19, column: 44, scope: !41)
// CHECK:STDOUT: !52 = !DILocation(line: 19, column: 37, scope: !41)
// CHECK:STDOUT: !53 = !DILocation(line: 20, column: 5, scope: !41)
// CHECK:STDOUT: !54 = !DILocation(line: 20, column: 24, scope: !41)
// CHECK:STDOUT: !56 = !DILocation(line: 23, column: 3, scope: !41)
// CHECK:STDOUT: !57 = !{!42}
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !4, line: 26, type: !15, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !61 = !DILocation(line: 27, column: 22, scope: !58)
// CHECK:STDOUT: !62 = !{!9, !7, !7}
// CHECK:STDOUT: !63 = !DISubroutineType(types: !62)
// CHECK:STDOUT: !66 = !DILocation(line: 28, column: 22, scope: !58)
// CHECK:STDOUT: !67 = !{!9, !8, !8}
// CHECK:STDOUT: !68 = !DISubroutineType(types: !67)
// CHECK:STDOUT: !72 = !DILocation(line: 29, column: 7, scope: !58)
// CHECK:STDOUT: !73 = !DILocation(line: 29, column: 6, scope: !58)
// CHECK:STDOUT: !74 = !DILocation(line: 30, column: 5, scope: !58)
// CHECK:STDOUT: !76 = !DILocation(line: 32, column: 10, scope: !58)
// CHECK:STDOUT: !77 = !DILocation(line: 32, column: 3, scope: !58)
// CHECK:STDOUT: !78 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !4, line: 28, type: !17, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !81)
// CHECK:STDOUT: !79 = !DILocalVariable(arg: 1, scope: !78, type: !6)
// CHECK:STDOUT: !80 = !DILocation(line: 28, column: 22, scope: !78)
// CHECK:STDOUT: !81 = !{!79}
// CHECK:STDOUT: !82 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !4, line: 28, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !85)
// CHECK:STDOUT: !83 = !DILocalVariable(arg: 1, scope: !82, type: !8)
// CHECK:STDOUT: !84 = !DILocation(line: 28, column: 22, scope: !82)
// CHECK:STDOUT: !85 = !{!83}
// CHECK:STDOUT: !86 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.1ac55aaed189338e:core.Destroy.Core", scope: null, file: !4, line: 28, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !89)
// CHECK:STDOUT: !87 = !DILocalVariable(arg: 1, scope: !86, type: !9)
// CHECK:STDOUT: !88 = !DILocation(line: 28, column: 22, scope: !86)
// CHECK:STDOUT: !89 = !{!87}
// CHECK:STDOUT: !90 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.1ac55aaed189338e:core.Destroy.Core", scope: null, file: !4, line: 28, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !93)
// CHECK:STDOUT: !91 = !DILocalVariable(arg: 1, scope: !90, type: !9)
// CHECK:STDOUT: !92 = !DILocation(line: 28, column: 22, scope: !90)
// CHECK:STDOUT: !93 = !{!91}
// CHECK:STDOUT: !94 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.58ec237e1038f3e7:core.Destroy.Core", scope: null, file: !4, line: 28, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !97)
// CHECK:STDOUT: !95 = !DILocalVariable(arg: 1, scope: !94, type: !9)
// CHECK:STDOUT: !96 = !DILocation(line: 28, column: 22, scope: !94)
// CHECK:STDOUT: !97 = !{!95}
// CHECK:STDOUT: !98 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.58ec237e1038f3e7:core.Destroy.Core", scope: null, file: !4, line: 28, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !101)
// CHECK:STDOUT: !99 = !DILocalVariable(arg: 1, scope: !98, type: !9)
// CHECK:STDOUT: !100 = !DILocation(line: 28, column: 22, scope: !98)
// CHECK:STDOUT: !101 = !{!99}
// CHECK:STDOUT: !102 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.8acada488d131cf2:core.Destroy.Core", scope: null, file: !4, line: 28, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !105)
// CHECK:STDOUT: !103 = !DILocalVariable(arg: 1, scope: !102, type: !9)
// CHECK:STDOUT: !104 = !DILocation(line: 28, column: 22, scope: !102)
// CHECK:STDOUT: !105 = !{!103}
// CHECK:STDOUT: !106 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.8acada488d131cf2:core.Destroy.Core", scope: null, file: !4, line: 28, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !109)
// CHECK:STDOUT: !107 = !DILocalVariable(arg: 1, scope: !106, type: !9)
// CHECK:STDOUT: !108 = !DILocation(line: 28, column: 22, scope: !106)
// CHECK:STDOUT: !109 = !{!107}
// CHECK:STDOUT: !110 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.01ad5b36ba6d1c53:core.Destroy.Core", scope: null, file: !4, line: 28, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !113)
// CHECK:STDOUT: !111 = !DILocalVariable(arg: 1, scope: !110, type: !9)
// CHECK:STDOUT: !112 = !DILocation(line: 28, column: 22, scope: !110)
// CHECK:STDOUT: !113 = !{!111}
// CHECK:STDOUT: !114 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.01ad5b36ba6d1c53:core.Destroy.Core", scope: null, file: !4, line: 28, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !117)
// CHECK:STDOUT: !115 = !DILocalVariable(arg: 1, scope: !114, type: !9)
// CHECK:STDOUT: !116 = !DILocation(line: 28, column: 22, scope: !114)
// CHECK:STDOUT: !117 = !{!115}
// CHECK:STDOUT: !118 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 27, type: !23, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !121)
// CHECK:STDOUT: !119 = !DILocalVariable(arg: 1, scope: !118, type: !7)
// CHECK:STDOUT: !120 = !DILocation(line: 27, column: 22, scope: !118)
// CHECK:STDOUT: !121 = !{!119}
// CHECK:STDOUT: !122 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !4, line: 27, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !125)
// CHECK:STDOUT: !123 = !DILocalVariable(arg: 1, scope: !122, type: !9)
// CHECK:STDOUT: !124 = !DILocation(line: 27, column: 22, scope: !122)
// CHECK:STDOUT: !125 = !{!123}
// CHECK:STDOUT: !126 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !4, line: 27, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !129)
// CHECK:STDOUT: !127 = !DILocalVariable(arg: 1, scope: !126, type: !9)
// CHECK:STDOUT: !128 = !DILocation(line: 27, column: 22, scope: !126)
// CHECK:STDOUT: !129 = !{!127}
// CHECK:STDOUT: !130 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.20c1b1147da3b52d:core.Destroy.Core", scope: null, file: !4, line: 27, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !133)
// CHECK:STDOUT: !131 = !DILocalVariable(arg: 1, scope: !130, type: !9)
// CHECK:STDOUT: !132 = !DILocation(line: 27, column: 22, scope: !130)
// CHECK:STDOUT: !133 = !{!131}
// CHECK:STDOUT: !134 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.20c1b1147da3b52d:core.Destroy.Core", scope: null, file: !4, line: 27, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !137)
// CHECK:STDOUT: !135 = !DILocalVariable(arg: 1, scope: !134, type: !9)
// CHECK:STDOUT: !136 = !DILocation(line: 27, column: 22, scope: !134)
// CHECK:STDOUT: !137 = !{!135}
// CHECK:STDOUT: !138 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.92cfe67cb2f4b128:core.Destroy.Core", scope: null, file: !4, line: 27, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !141)
// CHECK:STDOUT: !139 = !DILocalVariable(arg: 1, scope: !138, type: !9)
// CHECK:STDOUT: !140 = !DILocation(line: 27, column: 22, scope: !138)
// CHECK:STDOUT: !141 = !{!139}
// CHECK:STDOUT: !142 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.92cfe67cb2f4b128:core.Destroy.Core", scope: null, file: !4, line: 27, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !145)
// CHECK:STDOUT: !143 = !DILocalVariable(arg: 1, scope: !142, type: !9)
// CHECK:STDOUT: !144 = !DILocation(line: 27, column: 22, scope: !142)
// CHECK:STDOUT: !145 = !{!143}
// CHECK:STDOUT: !146 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.1eef18dc43ad9a55:core.Destroy.Core", scope: null, file: !4, line: 27, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !149)
// CHECK:STDOUT: !147 = !DILocalVariable(arg: 1, scope: !146, type: !9)
// CHECK:STDOUT: !148 = !DILocation(line: 27, column: 22, scope: !146)
// CHECK:STDOUT: !149 = !{!147}
// CHECK:STDOUT: !150 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.1eef18dc43ad9a55:core.Destroy.Core", scope: null, file: !4, line: 27, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !153)
// CHECK:STDOUT: !151 = !DILocalVariable(arg: 1, scope: !150, type: !9)
// CHECK:STDOUT: !152 = !DILocation(line: 27, column: 22, scope: !150)
// CHECK:STDOUT: !153 = !{!151}
// CHECK:STDOUT: !154 = distinct !DISubprogram(name: "Both", linkageName: "_CBoth.Pair.Main.84588f41d61dafba", scope: null, file: !4, line: 3, type: !63, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !159)
// CHECK:STDOUT: !155 = !DILocalVariable(arg: 1, scope: !154, type: !7)
// CHECK:STDOUT: !156 = !DILocalVariable(arg: 2, scope: !154, type: !7)
// CHECK:STDOUT: !157 = !DILocation(line: 3, column: 1, scope: !154)
// CHECK:STDOUT: !158 = !DILocation(line: 4, column: 19, scope: !154)
// CHECK:STDOUT: !159 = !{!155, !156}
// CHECK:STDOUT: !160 = distinct !DISubprogram(name: "Both", linkageName: "_CBoth.Pair.Main.f249b435619a5146", scope: null, file: !4, line: 3, type: !68, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !165)
// CHECK:STDOUT: !161 = !DILocalVariable(arg: 1, scope: !160, type: !8)
// CHECK:STDOUT: !162 = !DILocalVariable(arg: 2, scope: !160, type: !8)
// CHECK:STDOUT: !163 = !DILocation(line: 3, column: 1, scope: !160)
// CHECK:STDOUT: !164 = !DILocation(line: 4, column: 19, scope: !160)
// CHECK:STDOUT: !165 = !{!161, !162}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'symbolic.carbon'
// CHECK:STDOUT: source_filename = "symbolic.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @P.val.3d1 = internal constant <{ <{ i1, [3 x i8] }>, [8 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CCall.Main(ptr %p) #0 !dbg !168 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Classify.call = call i32 @_CClassify.Main.84588f41d61dafba(ptr %p), !dbg !174
// CHECK:STDOUT:   ret i32 %Classify.call, !dbg !175
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CClassify.Main.84588f41d61dafba(ptr %p) #0 !dbg !177 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_28.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %p, i32 0, i32 0, !dbg !183
// CHECK:STDOUT:   %.loc17_28.4 = load i8, ptr %.loc17_28.3.discriminant, align 1, !dbg !183
// CHECK:STDOUT:   %.loc17_28.41 = trunc i8 %.loc17_28.4 to i1, !dbg !183
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc17 = icmp eq i1 false, %.loc17_28.41, !dbg !183
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc17, label %match.case.then.loc17, label %match.case.else.loc17, !dbg !183
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc17_28.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %p, i32 0, i32 1, !dbg !183
// CHECK:STDOUT:   %.loc17_28.8.Both = getelementptr inbounds nuw [8 x i8], ptr %.loc17_28.7.payload, i32 0, i32 0, !dbg !183
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc17_28.8.Both, i32 0, i32 0, !dbg !183
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc17_28.8.Both, i32 0, i32 1, !dbg !183
// CHECK:STDOUT:   %.loc17_28.9 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !183
// CHECK:STDOUT:   %.loc17_28.10 = load i32, ptr %tuple.elem1.tuple.elem, align 4, !dbg !183
// CHECK:STDOUT:   call void @_CDiscard.Main.84588f41d61dafba(i32 %.loc17_28.9, i32 %.loc17_28.10), !dbg !188
// CHECK:STDOUT:   ret i32 1, !dbg !191
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc21_19.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %p, i32 0, i32 0, !dbg !192
// CHECK:STDOUT:   %.loc21_19.4 = load i8, ptr %.loc21_19.3.discriminant, align 1, !dbg !192
// CHECK:STDOUT:   %.loc21_19.42 = trunc i8 %.loc21_19.4 to i1, !dbg !192
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc21 = icmp eq i1 true, %.loc21_19.42, !dbg !192
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc21, label %match.case.then.loc21, label %match.done, !dbg !192
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc21:                            ; preds = %match.case.else.loc17
// CHECK:STDOUT:   ret i32 0, !dbg !193
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc17
// CHECK:STDOUT:   ret i32 -1, !dbg !195
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiscard.Main.84588f41d61dafba(i32 %_, i32 %_1) #0 !dbg !197 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !202
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!167}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!7, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !166 = !DIFile(filename: "symbolic.carbon", directory: "")
// CHECK:STDOUT: !167 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !166, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !168 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !166, line: 27, type: !11, spFlags: DISPFlagDefinition, unit: !167, retainedNodes: !176)
// CHECK:STDOUT: !169 = !DILocalVariable(arg: 1, scope: !168, type: !9)
// CHECK:STDOUT: !174 = !DILocation(line: 28, column: 10, scope: !168)
// CHECK:STDOUT: !175 = !DILocation(line: 28, column: 3, scope: !168)
// CHECK:STDOUT: !176 = !{!169}
// CHECK:STDOUT: !177 = distinct !DISubprogram(name: "Classify", linkageName: "_CClassify.Main.84588f41d61dafba", scope: null, file: !166, line: 15, type: !11, spFlags: DISPFlagDefinition, unit: !167, retainedNodes: !196)
// CHECK:STDOUT: !178 = !DILocalVariable(arg: 1, scope: !177, type: !9)
// CHECK:STDOUT: !183 = !DILocation(line: 17, column: 5, scope: !177)
// CHECK:STDOUT: !188 = !DILocation(line: 18, column: 7, scope: !177)
// CHECK:STDOUT: !189 = !{null, !7, !7}
// CHECK:STDOUT: !190 = !DISubroutineType(types: !189)
// CHECK:STDOUT: !191 = !DILocation(line: 19, column: 7, scope: !177)
// CHECK:STDOUT: !192 = !DILocation(line: 21, column: 5, scope: !177)
// CHECK:STDOUT: !193 = !DILocation(line: 21, column: 24, scope: !177)
// CHECK:STDOUT: !195 = !DILocation(line: 24, column: 3, scope: !177)
// CHECK:STDOUT: !196 = !{!178}
// CHECK:STDOUT: !197 = distinct !DISubprogram(name: "Discard", linkageName: "_CDiscard.Main.84588f41d61dafba", scope: null, file: !166, line: 13, type: !190, spFlags: DISPFlagDefinition, unit: !167, retainedNodes: !203)
// CHECK:STDOUT: !198 = !DILocalVariable(arg: 1, scope: !197, type: !7)
// CHECK:STDOUT: !199 = !DILocalVariable(arg: 2, scope: !197, type: !7)
// CHECK:STDOUT: !202 = !DILocation(line: 13, column: 1, scope: !197)
// CHECK:STDOUT: !203 = !{!198, !199}
// CHECK:STDOUT:

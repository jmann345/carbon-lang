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
// CHECK:STDOUT: @Pair.val.6e7 = internal constant <{ <{ i1, [3 x i8] }>, [8 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] poison }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @Pair.val.765 = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] poison }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT: @Pair.val.cf1.loc3_22.7 = internal constant <{ <{ i1, [3 x i8] }>, [8 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 false, [3 x i8] poison }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @Pair.val.790.loc3_22.7 = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 false, [7 x i8] poison }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CSum32.Main(ptr %p) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_32.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %p, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc10_32.4 = load i8, ptr %.loc10_32.3.discriminant, align 1, !dbg !11
// CHECK:STDOUT:   %.loc10_32.41 = trunc i8 %.loc10_32.4 to i1, !dbg !11
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc10 = icmp eq i1 false, %.loc10_32.41, !dbg !11
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc10, label %match.case.then.loc10, label %match.case.else.loc10, !dbg !11
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc10:                            ; preds = %entry
// CHECK:STDOUT:   %.loc10_32.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %p, i32 0, i32 1, !dbg !11
// CHECK:STDOUT:   %.loc10_32.8.Both = getelementptr inbounds nuw [8 x i8], ptr %.loc10_32.7.payload, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc10_32.8.Both, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc10_32.8.Both, i32 0, i32 1, !dbg !11
// CHECK:STDOUT:   %.loc10_32.9 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !11
// CHECK:STDOUT:   %.loc10_32.10 = load i32, ptr %tuple.elem1.tuple.elem, align 4, !dbg !11
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc10_32.9, %.loc10_32.10, !dbg !12
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !13
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc10:                            ; preds = %entry
// CHECK:STDOUT:   %.loc11_19.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %p, i32 0, i32 0, !dbg !14
// CHECK:STDOUT:   %.loc11_19.4 = load i8, ptr %.loc11_19.3.discriminant, align 1, !dbg !14
// CHECK:STDOUT:   %.loc11_19.42 = trunc i8 %.loc11_19.4 to i1, !dbg !14
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc11 = icmp eq i1 true, %.loc11_19.42, !dbg !14
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc11, label %match.case.then.loc11, label %match.done, !dbg !14
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc11:                            ; preds = %match.case.else.loc10
// CHECK:STDOUT:   ret i32 0, !dbg !15
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc10
// CHECK:STDOUT:   ret i32 -1, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CSum64.Main(ptr %p) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_32.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %p, i32 0, i32 0, !dbg !23
// CHECK:STDOUT:   %.loc19_32.4 = load i8, ptr %.loc19_32.3.discriminant, align 1, !dbg !23
// CHECK:STDOUT:   %.loc19_32.41 = trunc i8 %.loc19_32.4 to i1, !dbg !23
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc19 = icmp eq i1 false, %.loc19_32.41, !dbg !23
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc19, label %match.case.then.loc19, label %match.case.else.loc19, !dbg !23
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc19:                            ; preds = %entry
// CHECK:STDOUT:   %.loc19_32.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %p, i32 0, i32 1, !dbg !23
// CHECK:STDOUT:   %.loc19_32.8.Both = getelementptr inbounds nuw [16 x i8], ptr %.loc19_32.7.payload, i32 0, i32 0, !dbg !23
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc19_32.8.Both, i32 0, i32 0, !dbg !23
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc19_32.8.Both, i32 0, i32 1, !dbg !23
// CHECK:STDOUT:   %.loc19_32.9 = load i64, ptr %tuple.elem0.tuple.elem, align 8, !dbg !23
// CHECK:STDOUT:   %.loc19_32.10 = load i64, ptr %tuple.elem1.tuple.elem, align 8, !dbg !23
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i64 %.loc19_32.9, %.loc19_32.10, !dbg !24
// CHECK:STDOUT:   ret i64 %Int.as.AddWith.impl.Op.call, !dbg !25
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc19:                            ; preds = %entry
// CHECK:STDOUT:   %.loc20_19.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %p, i32 0, i32 0, !dbg !26
// CHECK:STDOUT:   %.loc20_19.4 = load i8, ptr %.loc20_19.3.discriminant, align 1, !dbg !26
// CHECK:STDOUT:   %.loc20_19.42 = trunc i8 %.loc20_19.4 to i1, !dbg !26
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc20 = icmp eq i1 true, %.loc20_19.42, !dbg !26
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc20, label %match.case.then.loc20, label %match.done, !dbg !26
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc20:                            ; preds = %match.case.else.loc19
// CHECK:STDOUT:   ret i64 0, !dbg !27
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc19
// CHECK:STDOUT:   ret i64 -1, !dbg !28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !29 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc27_41.1.temp = alloca <{ <{ i1, [3 x i8] }>, [8 x i8] }>, align 4, !dbg !32
// CHECK:STDOUT:   %.loc28_41.1.temp = alloca <{ <{ i1, [7 x i8] }>, [16 x i8] }>, align 8, !dbg !33
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc27_41.1.temp), !dbg !32
// CHECK:STDOUT:   call void @_CBoth.Pair.Main.84588f41d61dafba(ptr %.loc27_41.1.temp, i32 1, i32 2), !dbg !32
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc28_41.1.temp), !dbg !33
// CHECK:STDOUT:   call void @_CBoth.Pair.Main.f249b435619a5146(ptr %.loc28_41.1.temp, i64 3, i64 4), !dbg !33
// CHECK:STDOUT:   %Sum64.call = call i64 @_CSum64.Main(ptr %.loc28_41.1.temp), !dbg !34
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.call = icmp ne i64 %Sum64.call, 7, !dbg !34
// CHECK:STDOUT:   br i1 %Int.as.EqWith.impl.NotEqual.call, label %if.then, label %if.else, !dbg !35
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @"_COp.0df87691dac8a76f:core.Destroy.Core"(ptr %.loc28_41.1.temp), !dbg !33
// CHECK:STDOUT:   call void @"_COp.0dc10ea24802c11a:core.Destroy.Core"(ptr %.loc27_41.1.temp), !dbg !32
// CHECK:STDOUT:   ret i32 1, !dbg !36
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   %Sum32.call = call i32 @_CSum32.Main(ptr %.loc27_41.1.temp), !dbg !37
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call = sub i32 %Sum32.call, 3, !dbg !37
// CHECK:STDOUT:   call void @"_COp.0df87691dac8a76f:core.Destroy.Core"(ptr %.loc28_41.1.temp), !dbg !33
// CHECK:STDOUT:   call void @"_COp.0dc10ea24802c11a:core.Destroy.Core"(ptr %.loc27_41.1.temp), !dbg !32
// CHECK:STDOUT:   ret i32 %Int.as.SubWith.impl.Op.call, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.7512aa4144aeb8db:core.Destroy.Core"(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.fbec46972c1998a0:core.Destroy.Core"(ptr %self) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.c27887f0ed0fe2f3:core.Destroy.Core"(ptr %self) #0 !dbg !52 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.b019cb9e777b2a83:core.Destroy.Core"(ptr %self) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !61
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.a58f92185972885e:core.Destroy.Core"(ptr %self) #0 !dbg !62 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.0df87691dac8a76f:core.Destroy.Core"(ptr %self) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5e27612b9dd31a14:core.Destroy.Core"(ptr %self) #0 !dbg !70 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !75
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.eff30dc40f4a53d2:core.Destroy.Core"(ptr %self) #0 !dbg !76 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !79
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.2431a7381b485f6b:core.Destroy.Core"(ptr %self) #0 !dbg !80 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !83
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.b4f88722ca47d5b8:core.Destroy.Core"(ptr %self) #0 !dbg !84 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !87
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.0dc10ea24802c11a:core.Destroy.Core"(ptr %self) #0 !dbg !88 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBoth.Pair.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [8 x i8] }>) %return, i32 %_, i32 %_1) #0 !dbg !92 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_22.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !98
// CHECK:STDOUT:   %.loc3_22.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !98
// CHECK:STDOUT:   %.loc3_22.5.Both = getelementptr inbounds nuw [8 x i8], ptr %.loc3_22.4.payload, i32 0, i32 0, !dbg !98
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Pair.val.cf1.loc3_22.7, i64 12, i1 false), !dbg !98
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc3_22.5.Both, i32 0, i32 0, !dbg !99
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !99
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc3_22.5.Both, i32 0, i32 1, !dbg !99
// CHECK:STDOUT:   store i32 %_1, ptr %tuple.elem1.tuple.elem, align 4, !dbg !99
// CHECK:STDOUT:   ret void, !dbg !98
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBoth.Pair.Main.f249b435619a5146(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>) %return, i64 %_, i64 %_1) #0 !dbg !100 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_22.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 0, !dbg !106
// CHECK:STDOUT:   %.loc3_22.4.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 1, !dbg !106
// CHECK:STDOUT:   %.loc3_22.5.Both = getelementptr inbounds nuw [16 x i8], ptr %.loc3_22.4.payload, i32 0, i32 0, !dbg !106
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @Pair.val.790.loc3_22.7, i64 24, i1 false), !dbg !106
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc3_22.5.Both, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem0.tuple.elem, align 8, !dbg !107
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc3_22.5.Both, i32 0, i32 1, !dbg !107
// CHECK:STDOUT:   store i64 %_1, ptr %tuple.elem1.tuple.elem, align 8, !dbg !107
// CHECK:STDOUT:   ret void, !dbg !106
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_COp.0df87691dac8a76f:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_COp.0dc10ea24802c11a:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "two_sizes_destructure.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Sum32", linkageName: "_CSum32.Main", scope: null, file: !1, line: 8, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 10, column: 5, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 10, column: 44, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 10, column: 37, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 11, column: 5, scope: !4)
// CHECK:STDOUT: !15 = !DILocation(line: 11, column: 24, scope: !4)
// CHECK:STDOUT: !16 = !DILocation(line: 14, column: 3, scope: !4)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "Sum64", linkageName: "_CSum64.Main", scope: null, file: !1, line: 17, type: !18, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !21)
// CHECK:STDOUT: !18 = !DISubroutineType(types: !19)
// CHECK:STDOUT: !19 = !{!20, !8}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!22}
// CHECK:STDOUT: !22 = !DILocalVariable(arg: 1, scope: !17, type: !8)
// CHECK:STDOUT: !23 = !DILocation(line: 19, column: 5, scope: !17)
// CHECK:STDOUT: !24 = !DILocation(line: 19, column: 44, scope: !17)
// CHECK:STDOUT: !25 = !DILocation(line: 19, column: 37, scope: !17)
// CHECK:STDOUT: !26 = !DILocation(line: 20, column: 5, scope: !17)
// CHECK:STDOUT: !27 = !DILocation(line: 20, column: 24, scope: !17)
// CHECK:STDOUT: !28 = !DILocation(line: 23, column: 3, scope: !17)
// CHECK:STDOUT: !29 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !1, line: 26, type: !30, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !30 = !DISubroutineType(types: !31)
// CHECK:STDOUT: !31 = !{!7}
// CHECK:STDOUT: !32 = !DILocation(line: 27, column: 22, scope: !29)
// CHECK:STDOUT: !33 = !DILocation(line: 28, column: 22, scope: !29)
// CHECK:STDOUT: !34 = !DILocation(line: 29, column: 7, scope: !29)
// CHECK:STDOUT: !35 = !DILocation(line: 29, column: 6, scope: !29)
// CHECK:STDOUT: !36 = !DILocation(line: 30, column: 5, scope: !29)
// CHECK:STDOUT: !37 = !DILocation(line: 32, column: 10, scope: !29)
// CHECK:STDOUT: !38 = !DILocation(line: 32, column: 3, scope: !29)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "Op", linkageName: "_COp.7512aa4144aeb8db:core.Destroy.Core", scope: null, file: !1, line: 28, type: !40, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !43)
// CHECK:STDOUT: !40 = !DISubroutineType(types: !41)
// CHECK:STDOUT: !41 = !{null, !42}
// CHECK:STDOUT: !42 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !43 = !{!44}
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !39, type: !42)
// CHECK:STDOUT: !45 = !DILocation(line: 28, column: 22, scope: !39)
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "Op", linkageName: "_COp.fbec46972c1998a0:core.Destroy.Core", scope: null, file: !1, line: 28, type: !47, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !49)
// CHECK:STDOUT: !47 = !DISubroutineType(types: !48)
// CHECK:STDOUT: !48 = !{null, !20}
// CHECK:STDOUT: !49 = !{!50}
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !46, type: !20)
// CHECK:STDOUT: !51 = !DILocation(line: 28, column: 22, scope: !46)
// CHECK:STDOUT: !52 = distinct !DISubprogram(name: "Op", linkageName: "_COp.c27887f0ed0fe2f3:core.Destroy.Core", scope: null, file: !1, line: 28, type: !53, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !55)
// CHECK:STDOUT: !53 = !DISubroutineType(types: !54)
// CHECK:STDOUT: !54 = !{null, !8}
// CHECK:STDOUT: !55 = !{!56}
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !52, type: !8)
// CHECK:STDOUT: !57 = !DILocation(line: 28, column: 22, scope: !52)
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "Op", linkageName: "_COp.b019cb9e777b2a83:core.Destroy.Core", scope: null, file: !1, line: 28, type: !53, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !59)
// CHECK:STDOUT: !59 = !{!60}
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !58, type: !8)
// CHECK:STDOUT: !61 = !DILocation(line: 28, column: 22, scope: !58)
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "Op", linkageName: "_COp.a58f92185972885e:core.Destroy.Core", scope: null, file: !1, line: 28, type: !53, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !63)
// CHECK:STDOUT: !63 = !{!64}
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !62, type: !8)
// CHECK:STDOUT: !65 = !DILocation(line: 28, column: 22, scope: !62)
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "Op", linkageName: "_COp.0df87691dac8a76f:core.Destroy.Core", scope: null, file: !1, line: 28, type: !53, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !67)
// CHECK:STDOUT: !67 = !{!68}
// CHECK:STDOUT: !68 = !DILocalVariable(arg: 1, scope: !66, type: !8)
// CHECK:STDOUT: !69 = !DILocation(line: 28, column: 22, scope: !66)
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5e27612b9dd31a14:core.Destroy.Core", scope: null, file: !1, line: 27, type: !71, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !73)
// CHECK:STDOUT: !71 = !DISubroutineType(types: !72)
// CHECK:STDOUT: !72 = !{null, !7}
// CHECK:STDOUT: !73 = !{!74}
// CHECK:STDOUT: !74 = !DILocalVariable(arg: 1, scope: !70, type: !7)
// CHECK:STDOUT: !75 = !DILocation(line: 27, column: 22, scope: !70)
// CHECK:STDOUT: !76 = distinct !DISubprogram(name: "Op", linkageName: "_COp.eff30dc40f4a53d2:core.Destroy.Core", scope: null, file: !1, line: 27, type: !53, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !77)
// CHECK:STDOUT: !77 = !{!78}
// CHECK:STDOUT: !78 = !DILocalVariable(arg: 1, scope: !76, type: !8)
// CHECK:STDOUT: !79 = !DILocation(line: 27, column: 22, scope: !76)
// CHECK:STDOUT: !80 = distinct !DISubprogram(name: "Op", linkageName: "_COp.2431a7381b485f6b:core.Destroy.Core", scope: null, file: !1, line: 27, type: !53, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !81)
// CHECK:STDOUT: !81 = !{!82}
// CHECK:STDOUT: !82 = !DILocalVariable(arg: 1, scope: !80, type: !8)
// CHECK:STDOUT: !83 = !DILocation(line: 27, column: 22, scope: !80)
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "Op", linkageName: "_COp.b4f88722ca47d5b8:core.Destroy.Core", scope: null, file: !1, line: 27, type: !53, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !85)
// CHECK:STDOUT: !85 = !{!86}
// CHECK:STDOUT: !86 = !DILocalVariable(arg: 1, scope: !84, type: !8)
// CHECK:STDOUT: !87 = !DILocation(line: 27, column: 22, scope: !84)
// CHECK:STDOUT: !88 = distinct !DISubprogram(name: "Op", linkageName: "_COp.0dc10ea24802c11a:core.Destroy.Core", scope: null, file: !1, line: 27, type: !53, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !89)
// CHECK:STDOUT: !89 = !{!90}
// CHECK:STDOUT: !90 = !DILocalVariable(arg: 1, scope: !88, type: !8)
// CHECK:STDOUT: !91 = !DILocation(line: 27, column: 22, scope: !88)
// CHECK:STDOUT: !92 = distinct !DISubprogram(name: "Both", linkageName: "_CBoth.Pair.Main.84588f41d61dafba", scope: null, file: !1, line: 3, type: !93, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !95)
// CHECK:STDOUT: !93 = !DISubroutineType(types: !94)
// CHECK:STDOUT: !94 = !{!8, !7, !7}
// CHECK:STDOUT: !95 = !{!96, !97}
// CHECK:STDOUT: !96 = !DILocalVariable(arg: 1, scope: !92, type: !7)
// CHECK:STDOUT: !97 = !DILocalVariable(arg: 2, scope: !92, type: !7)
// CHECK:STDOUT: !98 = !DILocation(line: 3, column: 1, scope: !92)
// CHECK:STDOUT: !99 = !DILocation(line: 4, column: 19, scope: !92)
// CHECK:STDOUT: !100 = distinct !DISubprogram(name: "Both", linkageName: "_CBoth.Pair.Main.f249b435619a5146", scope: null, file: !1, line: 3, type: !101, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !103)
// CHECK:STDOUT: !101 = !DISubroutineType(types: !102)
// CHECK:STDOUT: !102 = !{!8, !20, !20}
// CHECK:STDOUT: !103 = !{!104, !105}
// CHECK:STDOUT: !104 = !DILocalVariable(arg: 1, scope: !100, type: !20)
// CHECK:STDOUT: !105 = !DILocalVariable(arg: 2, scope: !100, type: !20)
// CHECK:STDOUT: !106 = !DILocation(line: 3, column: 1, scope: !100)
// CHECK:STDOUT: !107 = !DILocation(line: 4, column: 19, scope: !100)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'symbolic.carbon'
// CHECK:STDOUT: source_filename = "symbolic.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @P.val.3d1 = internal constant <{ <{ i1, [3 x i8] }>, [8 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] poison }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CCall.Main(ptr %p) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Classify.call = call i32 @_CClassify.Main.84588f41d61dafba(ptr %p), !dbg !11
// CHECK:STDOUT:   ret i32 %Classify.call, !dbg !12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CClassify.Main.84588f41d61dafba(ptr %p) #0 !dbg !13 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_28.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %p, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   %.loc17_28.4 = load i8, ptr %.loc17_28.3.discriminant, align 1, !dbg !16
// CHECK:STDOUT:   %.loc17_28.41 = trunc i8 %.loc17_28.4 to i1, !dbg !16
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc17 = icmp eq i1 false, %.loc17_28.41, !dbg !16
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc17, label %match.case.then.loc17, label %match.case.else.loc17, !dbg !16
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc17_28.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %p, i32 0, i32 1, !dbg !16
// CHECK:STDOUT:   %.loc17_28.8.Both = getelementptr inbounds nuw [8 x i8], ptr %.loc17_28.7.payload, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc17_28.8.Both, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc17_28.8.Both, i32 0, i32 1, !dbg !16
// CHECK:STDOUT:   %.loc17_28.9 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !16
// CHECK:STDOUT:   %.loc17_28.10 = load i32, ptr %tuple.elem1.tuple.elem, align 4, !dbg !16
// CHECK:STDOUT:   call void @_CDiscard.Main.84588f41d61dafba(i32 %.loc17_28.9, i32 %.loc17_28.10), !dbg !17
// CHECK:STDOUT:   ret i32 1, !dbg !18
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc17:                            ; preds = %entry
// CHECK:STDOUT:   %.loc21_19.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %p, i32 0, i32 0, !dbg !19
// CHECK:STDOUT:   %.loc21_19.4 = load i8, ptr %.loc21_19.3.discriminant, align 1, !dbg !19
// CHECK:STDOUT:   %.loc21_19.42 = trunc i8 %.loc21_19.4 to i1, !dbg !19
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc21 = icmp eq i1 true, %.loc21_19.42, !dbg !19
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc21, label %match.case.then.loc21, label %match.done, !dbg !19
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc21:                            ; preds = %match.case.else.loc17
// CHECK:STDOUT:   ret i32 0, !dbg !20
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc17
// CHECK:STDOUT:   ret i32 -1, !dbg !21
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDiscard.Main.84588f41d61dafba(i32 %_, i32 %_1) #0 !dbg !22 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "symbolic.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !1, line: 27, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 28, column: 10, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 28, column: 3, scope: !4)
// CHECK:STDOUT: !13 = distinct !DISubprogram(name: "Classify", linkageName: "_CClassify.Main.84588f41d61dafba", scope: null, file: !1, line: 15, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !14)
// CHECK:STDOUT: !14 = !{!15}
// CHECK:STDOUT: !15 = !DILocalVariable(arg: 1, scope: !13, type: !8)
// CHECK:STDOUT: !16 = !DILocation(line: 17, column: 5, scope: !13)
// CHECK:STDOUT: !17 = !DILocation(line: 18, column: 7, scope: !13)
// CHECK:STDOUT: !18 = !DILocation(line: 19, column: 7, scope: !13)
// CHECK:STDOUT: !19 = !DILocation(line: 21, column: 5, scope: !13)
// CHECK:STDOUT: !20 = !DILocation(line: 21, column: 24, scope: !13)
// CHECK:STDOUT: !21 = !DILocation(line: 24, column: 3, scope: !13)
// CHECK:STDOUT: !22 = distinct !DISubprogram(name: "Discard", linkageName: "_CDiscard.Main.84588f41d61dafba", scope: null, file: !1, line: 13, type: !23, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !25)
// CHECK:STDOUT: !23 = !DISubroutineType(types: !24)
// CHECK:STDOUT: !24 = !{null, !7, !7}
// CHECK:STDOUT: !25 = !{!26, !27}
// CHECK:STDOUT: !26 = !DILocalVariable(arg: 1, scope: !22, type: !7)
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 2, scope: !22, type: !7)
// CHECK:STDOUT: !28 = !DILocation(line: 13, column: 1, scope: !22)
// CHECK:STDOUT:

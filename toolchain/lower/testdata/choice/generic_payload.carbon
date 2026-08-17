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
// CHECK:STDOUT: @Pair.val.6e7 = internal constant <{ <{ i1, [3 x i8] }>, [8 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] poison }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @Pair.val.765 = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] poison }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT: @Pair.val.cf1.loc3_22.7 = internal constant <{ <{ i1, [3 x i8] }>, [8 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 false, [3 x i8] poison }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @Pair.val.790.loc3_22.7 = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 false, [7 x i8] poison }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CClassify32.Main(ptr %p) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_19.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %p, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc10_19.4 = load i8, ptr %.loc10_19.3.discriminant, align 1, !dbg !11
// CHECK:STDOUT:   %.loc10_19.41 = trunc i8 %.loc10_19.4 to i1, !dbg !11
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc10_19.41, !dbg !11
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !11
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !12
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !13
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CClassify64.Main(ptr %p) #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_19.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %p, i32 0, i32 0, !dbg !17
// CHECK:STDOUT:   %.loc17_19.4 = load i8, ptr %.loc17_19.3.discriminant, align 1, !dbg !17
// CHECK:STDOUT:   %.loc17_19.41 = trunc i8 %.loc17_19.4 to i1, !dbg !17
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc17_19.41, !dbg !17
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !17
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !18
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !20 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc23_41.1.temp = alloca <{ <{ i1, [3 x i8] }>, [8 x i8] }>, align 4, !dbg !23
// CHECK:STDOUT:   %.loc24_41.1.temp = alloca <{ <{ i1, [7 x i8] }>, [16 x i8] }>, align 8, !dbg !24
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc23_41.1.temp), !dbg !23
// CHECK:STDOUT:   call void @_CBoth.Pair.Main.84588f41d61dafba(ptr %.loc23_41.1.temp, i32 1, i32 2), !dbg !23
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc24_41.1.temp), !dbg !24
// CHECK:STDOUT:   call void @_CBoth.Pair.Main.f249b435619a5146(ptr %.loc24_41.1.temp, i64 3, i64 4), !dbg !24
// CHECK:STDOUT:   %Classify32.call = call i32 @_CClassify32.Main(ptr %.loc23_41.1.temp), !dbg !25
// CHECK:STDOUT:   %Classify64.call = call i32 @_CClassify64.Main(ptr %.loc24_41.1.temp), !dbg !26
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Classify32.call, %Classify64.call, !dbg !25
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call = sub i32 %Int.as.AddWith.impl.Op.call, 2, !dbg !25
// CHECK:STDOUT:   call void @"_COp.0df87691dac8a76f:core.Destroy.Core"(ptr %.loc24_41.1.temp), !dbg !24
// CHECK:STDOUT:   call void @"_COp.0dc10ea24802c11a:core.Destroy.Core"(ptr %.loc23_41.1.temp), !dbg !23
// CHECK:STDOUT:   ret i32 %Int.as.SubWith.impl.Op.call, !dbg !27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.7512aa4144aeb8db:core.Destroy.Core"(ptr %self) #0 !dbg !28 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.fbec46972c1998a0:core.Destroy.Core"(ptr %self) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.c27887f0ed0fe2f3:core.Destroy.Core"(ptr %self) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !47
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.b019cb9e777b2a83:core.Destroy.Core"(ptr %self) #0 !dbg !48 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.a58f92185972885e:core.Destroy.Core"(ptr %self) #0 !dbg !52 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.0df87691dac8a76f:core.Destroy.Core"(ptr %self) #0 !dbg !56 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5e27612b9dd31a14:core.Destroy.Core"(ptr %self) #0 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.eff30dc40f4a53d2:core.Destroy.Core"(ptr %self) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.2431a7381b485f6b:core.Destroy.Core"(ptr %self) #0 !dbg !70 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !73
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.b4f88722ca47d5b8:core.Destroy.Core"(ptr %self) #0 !dbg !74 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.0dc10ea24802c11a:core.Destroy.Core"(ptr %self) #0 !dbg !78 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !81
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBoth.Pair.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [8 x i8] }>) %return, i32 %_, i32 %_1) #0 !dbg !82 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_22.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !88
// CHECK:STDOUT:   %.loc3_22.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !88
// CHECK:STDOUT:   %.loc3_22.5.Both = getelementptr inbounds nuw [8 x i8], ptr %.loc3_22.4.payload, i32 0, i32 0, !dbg !88
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Pair.val.cf1.loc3_22.7, i64 12, i1 false), !dbg !88
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc3_22.5.Both, i32 0, i32 0, !dbg !89
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !89
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc3_22.5.Both, i32 0, i32 1, !dbg !89
// CHECK:STDOUT:   store i32 %_1, ptr %tuple.elem1.tuple.elem, align 4, !dbg !89
// CHECK:STDOUT:   ret void, !dbg !88
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBoth.Pair.Main.f249b435619a5146(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>) %return, i64 %_, i64 %_1) #0 !dbg !90 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc3_22.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 0, !dbg !96
// CHECK:STDOUT:   %.loc3_22.4.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 1, !dbg !96
// CHECK:STDOUT:   %.loc3_22.5.Both = getelementptr inbounds nuw [16 x i8], ptr %.loc3_22.4.payload, i32 0, i32 0, !dbg !96
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @Pair.val.790.loc3_22.7, i64 24, i1 false), !dbg !96
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc3_22.5.Both, i32 0, i32 0, !dbg !97
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem0.tuple.elem, align 8, !dbg !97
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc3_22.5.Both, i32 0, i32 1, !dbg !97
// CHECK:STDOUT:   store i64 %_1, ptr %tuple.elem1.tuple.elem, align 8, !dbg !97
// CHECK:STDOUT:   ret void, !dbg !96
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "two_sizes.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Classify32", linkageName: "_CClassify32.Main", scope: null, file: !1, line: 8, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 10, column: 5, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 10, column: 24, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 11, column: 18, scope: !4)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "Classify64", linkageName: "_CClassify64.Main", scope: null, file: !1, line: 15, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !15)
// CHECK:STDOUT: !15 = !{!16}
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 1, scope: !14, type: !8)
// CHECK:STDOUT: !17 = !DILocation(line: 17, column: 5, scope: !14)
// CHECK:STDOUT: !18 = !DILocation(line: 17, column: 24, scope: !14)
// CHECK:STDOUT: !19 = !DILocation(line: 18, column: 18, scope: !14)
// CHECK:STDOUT: !20 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !1, line: 22, type: !21, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !21 = !DISubroutineType(types: !22)
// CHECK:STDOUT: !22 = !{!7}
// CHECK:STDOUT: !23 = !DILocation(line: 23, column: 22, scope: !20)
// CHECK:STDOUT: !24 = !DILocation(line: 24, column: 22, scope: !20)
// CHECK:STDOUT: !25 = !DILocation(line: 25, column: 10, scope: !20)
// CHECK:STDOUT: !26 = !DILocation(line: 25, column: 26, scope: !20)
// CHECK:STDOUT: !27 = !DILocation(line: 25, column: 3, scope: !20)
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "Op", linkageName: "_COp.7512aa4144aeb8db:core.Destroy.Core", scope: null, file: !1, line: 24, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !32)
// CHECK:STDOUT: !29 = !DISubroutineType(types: !30)
// CHECK:STDOUT: !30 = !{null, !31}
// CHECK:STDOUT: !31 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !32 = !{!33}
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !28, type: !31)
// CHECK:STDOUT: !34 = !DILocation(line: 24, column: 22, scope: !28)
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "Op", linkageName: "_COp.fbec46972c1998a0:core.Destroy.Core", scope: null, file: !1, line: 24, type: !36, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !39)
// CHECK:STDOUT: !36 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !37 = !{null, !38}
// CHECK:STDOUT: !38 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !39 = !{!40}
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !35, type: !38)
// CHECK:STDOUT: !41 = !DILocation(line: 24, column: 22, scope: !35)
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "Op", linkageName: "_COp.c27887f0ed0fe2f3:core.Destroy.Core", scope: null, file: !1, line: 24, type: !43, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !45)
// CHECK:STDOUT: !43 = !DISubroutineType(types: !44)
// CHECK:STDOUT: !44 = !{null, !8}
// CHECK:STDOUT: !45 = !{!46}
// CHECK:STDOUT: !46 = !DILocalVariable(arg: 1, scope: !42, type: !8)
// CHECK:STDOUT: !47 = !DILocation(line: 24, column: 22, scope: !42)
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "Op", linkageName: "_COp.b019cb9e777b2a83:core.Destroy.Core", scope: null, file: !1, line: 24, type: !43, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !49)
// CHECK:STDOUT: !49 = !{!50}
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !48, type: !8)
// CHECK:STDOUT: !51 = !DILocation(line: 24, column: 22, scope: !48)
// CHECK:STDOUT: !52 = distinct !DISubprogram(name: "Op", linkageName: "_COp.a58f92185972885e:core.Destroy.Core", scope: null, file: !1, line: 24, type: !43, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !53)
// CHECK:STDOUT: !53 = !{!54}
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !52, type: !8)
// CHECK:STDOUT: !55 = !DILocation(line: 24, column: 22, scope: !52)
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "Op", linkageName: "_COp.0df87691dac8a76f:core.Destroy.Core", scope: null, file: !1, line: 24, type: !43, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !57)
// CHECK:STDOUT: !57 = !{!58}
// CHECK:STDOUT: !58 = !DILocalVariable(arg: 1, scope: !56, type: !8)
// CHECK:STDOUT: !59 = !DILocation(line: 24, column: 22, scope: !56)
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5e27612b9dd31a14:core.Destroy.Core", scope: null, file: !1, line: 23, type: !61, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !63)
// CHECK:STDOUT: !61 = !DISubroutineType(types: !62)
// CHECK:STDOUT: !62 = !{null, !7}
// CHECK:STDOUT: !63 = !{!64}
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !60, type: !7)
// CHECK:STDOUT: !65 = !DILocation(line: 23, column: 22, scope: !60)
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "Op", linkageName: "_COp.eff30dc40f4a53d2:core.Destroy.Core", scope: null, file: !1, line: 23, type: !43, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !67)
// CHECK:STDOUT: !67 = !{!68}
// CHECK:STDOUT: !68 = !DILocalVariable(arg: 1, scope: !66, type: !8)
// CHECK:STDOUT: !69 = !DILocation(line: 23, column: 22, scope: !66)
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "Op", linkageName: "_COp.2431a7381b485f6b:core.Destroy.Core", scope: null, file: !1, line: 23, type: !43, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !71)
// CHECK:STDOUT: !71 = !{!72}
// CHECK:STDOUT: !72 = !DILocalVariable(arg: 1, scope: !70, type: !8)
// CHECK:STDOUT: !73 = !DILocation(line: 23, column: 22, scope: !70)
// CHECK:STDOUT: !74 = distinct !DISubprogram(name: "Op", linkageName: "_COp.b4f88722ca47d5b8:core.Destroy.Core", scope: null, file: !1, line: 23, type: !43, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !75)
// CHECK:STDOUT: !75 = !{!76}
// CHECK:STDOUT: !76 = !DILocalVariable(arg: 1, scope: !74, type: !8)
// CHECK:STDOUT: !77 = !DILocation(line: 23, column: 22, scope: !74)
// CHECK:STDOUT: !78 = distinct !DISubprogram(name: "Op", linkageName: "_COp.0dc10ea24802c11a:core.Destroy.Core", scope: null, file: !1, line: 23, type: !43, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !79)
// CHECK:STDOUT: !79 = !{!80}
// CHECK:STDOUT: !80 = !DILocalVariable(arg: 1, scope: !78, type: !8)
// CHECK:STDOUT: !81 = !DILocation(line: 23, column: 22, scope: !78)
// CHECK:STDOUT: !82 = distinct !DISubprogram(name: "Both", linkageName: "_CBoth.Pair.Main.84588f41d61dafba", scope: null, file: !1, line: 3, type: !83, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !85)
// CHECK:STDOUT: !83 = !DISubroutineType(types: !84)
// CHECK:STDOUT: !84 = !{!8, !7, !7}
// CHECK:STDOUT: !85 = !{!86, !87}
// CHECK:STDOUT: !86 = !DILocalVariable(arg: 1, scope: !82, type: !7)
// CHECK:STDOUT: !87 = !DILocalVariable(arg: 2, scope: !82, type: !7)
// CHECK:STDOUT: !88 = !DILocation(line: 3, column: 1, scope: !82)
// CHECK:STDOUT: !89 = !DILocation(line: 4, column: 19, scope: !82)
// CHECK:STDOUT: !90 = distinct !DISubprogram(name: "Both", linkageName: "_CBoth.Pair.Main.f249b435619a5146", scope: null, file: !1, line: 3, type: !91, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !93)
// CHECK:STDOUT: !91 = !DISubroutineType(types: !92)
// CHECK:STDOUT: !92 = !{!8, !38, !38}
// CHECK:STDOUT: !93 = !{!94, !95}
// CHECK:STDOUT: !94 = !DILocalVariable(arg: 1, scope: !90, type: !38)
// CHECK:STDOUT: !95 = !DILocalVariable(arg: 2, scope: !90, type: !38)
// CHECK:STDOUT: !96 = !DILocation(line: 3, column: 1, scope: !90)
// CHECK:STDOUT: !97 = !DILocation(line: 4, column: 19, scope: !90)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'mixed.carbon'
// CHECK:STDOUT: source_filename = "mixed.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @M.val.de4 = internal constant <{ <{ i2, [3 x i8] }>, [4 x i8] }> <{ <{ i2, [3 x i8] }> <{ i2 -2, [3 x i8] poison }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @M.val.7cc = internal constant <{ <{ i2, [7 x i8] }>, [16 x i8] }> <{ <{ i2, [7 x i8] }> <{ i2 -2, [7 x i8] poison }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT: @M.val.287.loc6_19.7 = internal constant <{ <{ i2, [7 x i8] }>, [16 x i8] }> <{ <{ i2, [7 x i8] }> <{ i2 1, [7 x i8] poison }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CF8.Main(ptr %m) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14_16.3.discriminant = getelementptr inbounds nuw <{ <{ i2, [3 x i8] }>, [4 x i8] }>, ptr %m, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc14_16.4 = load i8, ptr %.loc14_16.3.discriminant, align 1, !dbg !11
// CHECK:STDOUT:   %.loc14_16.41 = trunc i8 %.loc14_16.4 to i2, !dbg !11
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i2 -2, %.loc14_16.41, !dbg !11
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !11
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !12
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !13
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CF64.Main(ptr %m) #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc21_16.3.discriminant = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %m, i32 0, i32 0, !dbg !17
// CHECK:STDOUT:   %.loc21_16.4 = load i8, ptr %.loc21_16.3.discriminant, align 1, !dbg !17
// CHECK:STDOUT:   %.loc21_16.41 = trunc i8 %.loc21_16.4 to i2, !dbg !17
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i2 -2, %.loc21_16.41, !dbg !17
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !17
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !18
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !20 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc27_31.1.temp = alloca <{ <{ i2, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !23
// CHECK:STDOUT:   %.loc28_34.1.temp = alloca <{ <{ i2, [7 x i8] }>, [16 x i8] }>, align 8, !dbg !24
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc27_31.1.temp), !dbg !23
// CHECK:STDOUT:   call void @_CSmall.M.Main.1590cb8a669ddba5(ptr %.loc27_31.1.temp, i32 1), !dbg !23
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc28_34.1.temp), !dbg !24
// CHECK:STDOUT:   call void @_CBig.M.Main.f249b435619a5146(ptr %.loc28_34.1.temp, i64 3, i64 4), !dbg !24
// CHECK:STDOUT:   %F8.call = call i32 @_CF8.Main(ptr %.loc27_31.1.temp), !dbg !25
// CHECK:STDOUT:   %F64.call = call i32 @_CF64.Main(ptr %.loc28_34.1.temp), !dbg !26
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %F8.call, %F64.call, !dbg !25
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call = sub i32 %Int.as.AddWith.impl.Op.call, 2, !dbg !25
// CHECK:STDOUT:   call void @"_COp.b1f8392e3c24c146:core.Destroy.Core"(ptr %.loc28_34.1.temp), !dbg !24
// CHECK:STDOUT:   call void @"_COp.5e12e22b25f7970a:core.Destroy.Core"(ptr %.loc27_31.1.temp), !dbg !23
// CHECK:STDOUT:   ret i32 %Int.as.SubWith.impl.Op.call, !dbg !27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5e806e42776f0241:core.Destroy.Core"(ptr %self) #0 !dbg !28 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5e27612b9dd31a14:core.Destroy.Core"(ptr %self) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.b56e66ed2f8c6490:core.Destroy.Core"(ptr %self) #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !46
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.fbec46972c1998a0:core.Destroy.Core"(ptr %self) #0 !dbg !47 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.c27887f0ed0fe2f3:core.Destroy.Core"(ptr %self) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.9f98b479147b45dc:core.Destroy.Core"(ptr %self) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !61
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.47e78847b7b1f8bb:core.Destroy.Core"(ptr %self) #0 !dbg !62 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.b1f8392e3c24c146:core.Destroy.Core"(ptr %self) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.578b3934f85dbca6:core.Destroy.Core"(ptr %self) #0 !dbg !70 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !76
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.a25d0ac60fb6784b:core.Destroy.Core"(ptr %self) #0 !dbg !77 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !80
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.720f3c0b1cf74638:core.Destroy.Core"(ptr %self) #0 !dbg !81 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !84
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.6f46c597140d2111:core.Destroy.Core"(ptr %self) #0 !dbg !85 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !88
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5e12e22b25f7970a:core.Destroy.Core"(ptr %self) #0 !dbg !89 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !92
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSmall.M.Main.1590cb8a669ddba5(ptr sret(<{ <{ i2, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !93 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_19.1.discriminant = getelementptr inbounds nuw <{ <{ i2, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !98
// CHECK:STDOUT:   %.loc6_19.4.payload = getelementptr inbounds nuw <{ <{ i2, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !98
// CHECK:STDOUT:   %.loc6_19.5.Small = getelementptr inbounds nuw [4 x i8], ptr %.loc6_19.4.payload, i32 0, i32 0, !dbg !98
// CHECK:STDOUT:   %.loc7_16.2.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !99
// CHECK:STDOUT:   store { i32 } %.loc7_16.2.tuple.init, ptr %.loc6_19.5.Small, align 4, !dbg !98
// CHECK:STDOUT:   store i8 0, ptr %.loc6_19.1.discriminant, align 1, !dbg !98
// CHECK:STDOUT:   ret void, !dbg !98
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBig.M.Main.f249b435619a5146(ptr sret(<{ <{ i2, [7 x i8] }>, [16 x i8] }>) %return, i64 %_, i64 %_1) #0 !dbg !100 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_19.1.discriminant = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 0, !dbg !106
// CHECK:STDOUT:   %.loc6_19.4.payload = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 1, !dbg !106
// CHECK:STDOUT:   %.loc6_19.5.Big = getelementptr inbounds nuw [16 x i8], ptr %.loc6_19.4.payload, i32 0, i32 0, !dbg !106
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @M.val.287.loc6_19.7, i64 24, i1 false), !dbg !106
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc6_19.5.Big, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem0.tuple.elem, align 8, !dbg !107
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc6_19.5.Big, i32 0, i32 1, !dbg !107
// CHECK:STDOUT:   store i64 %_1, ptr %tuple.elem1.tuple.elem, align 8, !dbg !107
// CHECK:STDOUT:   ret void, !dbg !106
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "mixed.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "F8", linkageName: "_CF8.Main", scope: null, file: !1, line: 12, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 14, column: 5, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 14, column: 21, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 15, column: 18, scope: !4)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "F64", linkageName: "_CF64.Main", scope: null, file: !1, line: 19, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !15)
// CHECK:STDOUT: !15 = !{!16}
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 1, scope: !14, type: !8)
// CHECK:STDOUT: !17 = !DILocation(line: 21, column: 5, scope: !14)
// CHECK:STDOUT: !18 = !DILocation(line: 21, column: 21, scope: !14)
// CHECK:STDOUT: !19 = !DILocation(line: 22, column: 18, scope: !14)
// CHECK:STDOUT: !20 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !1, line: 26, type: !21, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !21 = !DISubroutineType(types: !22)
// CHECK:STDOUT: !22 = !{!7}
// CHECK:STDOUT: !23 = !DILocation(line: 27, column: 18, scope: !20)
// CHECK:STDOUT: !24 = !DILocation(line: 28, column: 19, scope: !20)
// CHECK:STDOUT: !25 = !DILocation(line: 29, column: 10, scope: !20)
// CHECK:STDOUT: !26 = !DILocation(line: 29, column: 18, scope: !20)
// CHECK:STDOUT: !27 = !DILocation(line: 29, column: 3, scope: !20)
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5e806e42776f0241:core.Destroy.Core", scope: null, file: !1, line: 28, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !32)
// CHECK:STDOUT: !29 = !DISubroutineType(types: !30)
// CHECK:STDOUT: !30 = !{null, !31}
// CHECK:STDOUT: !31 = !DIBasicType(name: "int", size: 2, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !32 = !{!33}
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !28, type: !31)
// CHECK:STDOUT: !34 = !DILocation(line: 28, column: 19, scope: !28)
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5e27612b9dd31a14:core.Destroy.Core", scope: null, file: !1, line: 28, type: !36, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !38)
// CHECK:STDOUT: !36 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !37 = !{null, !7}
// CHECK:STDOUT: !38 = !{!39}
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !35, type: !7)
// CHECK:STDOUT: !40 = !DILocation(line: 28, column: 19, scope: !35)
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "Op", linkageName: "_COp.b56e66ed2f8c6490:core.Destroy.Core", scope: null, file: !1, line: 28, type: !42, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !44)
// CHECK:STDOUT: !42 = !DISubroutineType(types: !43)
// CHECK:STDOUT: !43 = !{null, !8}
// CHECK:STDOUT: !44 = !{!45}
// CHECK:STDOUT: !45 = !DILocalVariable(arg: 1, scope: !41, type: !8)
// CHECK:STDOUT: !46 = !DILocation(line: 28, column: 19, scope: !41)
// CHECK:STDOUT: !47 = distinct !DISubprogram(name: "Op", linkageName: "_COp.fbec46972c1998a0:core.Destroy.Core", scope: null, file: !1, line: 28, type: !48, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !51)
// CHECK:STDOUT: !48 = !DISubroutineType(types: !49)
// CHECK:STDOUT: !49 = !{null, !50}
// CHECK:STDOUT: !50 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !51 = !{!52}
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !47, type: !50)
// CHECK:STDOUT: !53 = !DILocation(line: 28, column: 19, scope: !47)
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "Op", linkageName: "_COp.c27887f0ed0fe2f3:core.Destroy.Core", scope: null, file: !1, line: 28, type: !42, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !55)
// CHECK:STDOUT: !55 = !{!56}
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !54, type: !8)
// CHECK:STDOUT: !57 = !DILocation(line: 28, column: 19, scope: !54)
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "Op", linkageName: "_COp.9f98b479147b45dc:core.Destroy.Core", scope: null, file: !1, line: 28, type: !42, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !59)
// CHECK:STDOUT: !59 = !{!60}
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !58, type: !8)
// CHECK:STDOUT: !61 = !DILocation(line: 28, column: 19, scope: !58)
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "Op", linkageName: "_COp.47e78847b7b1f8bb:core.Destroy.Core", scope: null, file: !1, line: 28, type: !42, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !63)
// CHECK:STDOUT: !63 = !{!64}
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !62, type: !8)
// CHECK:STDOUT: !65 = !DILocation(line: 28, column: 19, scope: !62)
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "Op", linkageName: "_COp.b1f8392e3c24c146:core.Destroy.Core", scope: null, file: !1, line: 28, type: !42, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !67)
// CHECK:STDOUT: !67 = !{!68}
// CHECK:STDOUT: !68 = !DILocalVariable(arg: 1, scope: !66, type: !8)
// CHECK:STDOUT: !69 = !DILocation(line: 28, column: 19, scope: !66)
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "Op", linkageName: "_COp.578b3934f85dbca6:core.Destroy.Core", scope: null, file: !1, line: 27, type: !71, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !74)
// CHECK:STDOUT: !71 = !DISubroutineType(types: !72)
// CHECK:STDOUT: !72 = !{null, !73}
// CHECK:STDOUT: !73 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_signed)
// CHECK:STDOUT: !74 = !{!75}
// CHECK:STDOUT: !75 = !DILocalVariable(arg: 1, scope: !70, type: !73)
// CHECK:STDOUT: !76 = !DILocation(line: 27, column: 18, scope: !70)
// CHECK:STDOUT: !77 = distinct !DISubprogram(name: "Op", linkageName: "_COp.a25d0ac60fb6784b:core.Destroy.Core", scope: null, file: !1, line: 27, type: !42, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !78)
// CHECK:STDOUT: !78 = !{!79}
// CHECK:STDOUT: !79 = !DILocalVariable(arg: 1, scope: !77, type: !8)
// CHECK:STDOUT: !80 = !DILocation(line: 27, column: 18, scope: !77)
// CHECK:STDOUT: !81 = distinct !DISubprogram(name: "Op", linkageName: "_COp.720f3c0b1cf74638:core.Destroy.Core", scope: null, file: !1, line: 27, type: !42, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !82)
// CHECK:STDOUT: !82 = !{!83}
// CHECK:STDOUT: !83 = !DILocalVariable(arg: 1, scope: !81, type: !8)
// CHECK:STDOUT: !84 = !DILocation(line: 27, column: 18, scope: !81)
// CHECK:STDOUT: !85 = distinct !DISubprogram(name: "Op", linkageName: "_COp.6f46c597140d2111:core.Destroy.Core", scope: null, file: !1, line: 27, type: !42, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !86)
// CHECK:STDOUT: !86 = !{!87}
// CHECK:STDOUT: !87 = !DILocalVariable(arg: 1, scope: !85, type: !8)
// CHECK:STDOUT: !88 = !DILocation(line: 27, column: 18, scope: !85)
// CHECK:STDOUT: !89 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5e12e22b25f7970a:core.Destroy.Core", scope: null, file: !1, line: 27, type: !42, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !90)
// CHECK:STDOUT: !90 = !{!91}
// CHECK:STDOUT: !91 = !DILocalVariable(arg: 1, scope: !89, type: !8)
// CHECK:STDOUT: !92 = !DILocation(line: 27, column: 18, scope: !89)
// CHECK:STDOUT: !93 = distinct !DISubprogram(name: "Small", linkageName: "_CSmall.M.Main.1590cb8a669ddba5", scope: null, file: !1, line: 6, type: !94, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !96)
// CHECK:STDOUT: !94 = !DISubroutineType(types: !95)
// CHECK:STDOUT: !95 = !{!8, !7}
// CHECK:STDOUT: !96 = !{!97}
// CHECK:STDOUT: !97 = !DILocalVariable(arg: 1, scope: !93, type: !7)
// CHECK:STDOUT: !98 = !DILocation(line: 6, column: 1, scope: !93)
// CHECK:STDOUT: !99 = !DILocation(line: 7, column: 16, scope: !93)
// CHECK:STDOUT: !100 = distinct !DISubprogram(name: "Big", linkageName: "_CBig.M.Main.f249b435619a5146", scope: null, file: !1, line: 6, type: !101, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !103)
// CHECK:STDOUT: !101 = !DISubroutineType(types: !102)
// CHECK:STDOUT: !102 = !{!8, !50, !50}
// CHECK:STDOUT: !103 = !{!104, !105}
// CHECK:STDOUT: !104 = !DILocalVariable(arg: 1, scope: !100, type: !50)
// CHECK:STDOUT: !105 = !DILocalVariable(arg: 2, scope: !100, type: !50)
// CHECK:STDOUT: !106 = !DILocation(line: 6, column: 1, scope: !100)
// CHECK:STDOUT: !107 = !DILocation(line: 8, column: 18, scope: !100)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'destructure.carbon'
// CHECK:STDOUT: source_filename = "destructure.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Opt.val.b51 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] poison }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @Opt.val.5b3.loc6_21.7 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 false, [3 x i8] poison }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CGet.Main(ptr %o) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc13_24.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc13_24.4 = load i8, ptr %.loc13_24.3.discriminant, align 1, !dbg !11
// CHECK:STDOUT:   %.loc13_24.41 = trunc i8 %.loc13_24.4 to i1, !dbg !11
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc13 = icmp eq i1 false, %.loc13_24.41, !dbg !11
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc13, label %match.case.then.loc13, label %match.case.else.loc13, !dbg !11
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc13:                            ; preds = %entry
// CHECK:STDOUT:   %.loc13_24.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 1, !dbg !11
// CHECK:STDOUT:   %.loc13_24.8.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc13_24.7.payload, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc13_24.8.Some, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc13_24.9 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !11
// CHECK:STDOUT:   ret i32 %.loc13_24.9, !dbg !12
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc13:                            ; preds = %entry
// CHECK:STDOUT:   %.loc14_16.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 0, !dbg !13
// CHECK:STDOUT:   %.loc14_16.4 = load i8, ptr %.loc14_16.3.discriminant, align 1, !dbg !13
// CHECK:STDOUT:   %.loc14_16.42 = trunc i8 %.loc14_16.4 to i1, !dbg !13
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc14 = icmp eq i1 true, %.loc14_16.42, !dbg !13
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc14, label %match.case.then.loc14, label %match.done, !dbg !13
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc14:                            ; preds = %match.case.else.loc13
// CHECK:STDOUT:   ret i32 -1, !dbg !14
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc13
// CHECK:STDOUT:   ret i32 -2, !dbg !15
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !16 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc21_37.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !19
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc21_37.1.temp), !dbg !19
// CHECK:STDOUT:   call void @_CSome.Opt.Main.84588f41d61dafba(ptr %.loc21_37.1.temp, i32 42), !dbg !19
// CHECK:STDOUT:   %Get.call = call i32 @_CGet.Main(ptr %.loc21_37.1.temp), !dbg !20
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call = sub i32 %Get.call, 42, !dbg !20
// CHECK:STDOUT:   call void @"_COp.6990259bb5e562c9:core.Destroy.Core"(ptr %.loc21_37.1.temp), !dbg !19
// CHECK:STDOUT:   ret i32 %Int.as.SubWith.impl.Op.call, !dbg !21
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.7512aa4144aeb8db:core.Destroy.Core"(ptr %self) #0 !dbg !22 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5e27612b9dd31a14:core.Destroy.Core"(ptr %self) #0 !dbg !29 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.b56e66ed2f8c6490:core.Destroy.Core"(ptr %self) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.f6fc5a90c56b9f17:core.Destroy.Core"(ptr %self) #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.cffe352dfb12b6f8:core.Destroy.Core"(ptr %self) #0 !dbg !45 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.6990259bb5e562c9:core.Destroy.Core"(ptr %self) #0 !dbg !49 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSome.Opt.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !53 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_21.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !58
// CHECK:STDOUT:   %.loc6_21.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !58
// CHECK:STDOUT:   %.loc6_21.5.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc6_21.4.payload, i32 0, i32 0, !dbg !58
// CHECK:STDOUT:   %.loc7_17.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !59
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Opt.val.5b3.loc6_21.7, i64 8, i1 false), !dbg !58
// CHECK:STDOUT:   store { i32 } %.loc7_17.1.tuple.init, ptr %.loc6_21.5.Some, align 4, !dbg !58
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc6_21.5.Some, i32 0, i32 0, !dbg !59
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !59
// CHECK:STDOUT:   ret void, !dbg !58
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "destructure.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Main", scope: null, file: !1, line: 11, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 13, column: 5, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 13, column: 29, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 14, column: 5, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 14, column: 21, scope: !4)
// CHECK:STDOUT: !15 = !DILocation(line: 17, column: 3, scope: !4)
// CHECK:STDOUT: !16 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !1, line: 20, type: !17, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !17 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !18 = !{!7}
// CHECK:STDOUT: !19 = !DILocation(line: 21, column: 21, scope: !16)
// CHECK:STDOUT: !20 = !DILocation(line: 22, column: 10, scope: !16)
// CHECK:STDOUT: !21 = !DILocation(line: 22, column: 3, scope: !16)
// CHECK:STDOUT: !22 = distinct !DISubprogram(name: "Op", linkageName: "_COp.7512aa4144aeb8db:core.Destroy.Core", scope: null, file: !1, line: 21, type: !23, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
// CHECK:STDOUT: !23 = !DISubroutineType(types: !24)
// CHECK:STDOUT: !24 = !{null, !25}
// CHECK:STDOUT: !25 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !26 = !{!27}
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 1, scope: !22, type: !25)
// CHECK:STDOUT: !28 = !DILocation(line: 21, column: 21, scope: !22)
// CHECK:STDOUT: !29 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5e27612b9dd31a14:core.Destroy.Core", scope: null, file: !1, line: 21, type: !30, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !32)
// CHECK:STDOUT: !30 = !DISubroutineType(types: !31)
// CHECK:STDOUT: !31 = !{null, !7}
// CHECK:STDOUT: !32 = !{!33}
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !29, type: !7)
// CHECK:STDOUT: !34 = !DILocation(line: 21, column: 21, scope: !29)
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "Op", linkageName: "_COp.b56e66ed2f8c6490:core.Destroy.Core", scope: null, file: !1, line: 21, type: !36, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !38)
// CHECK:STDOUT: !36 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !37 = !{null, !8}
// CHECK:STDOUT: !38 = !{!39}
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !35, type: !8)
// CHECK:STDOUT: !40 = !DILocation(line: 21, column: 21, scope: !35)
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "Op", linkageName: "_COp.f6fc5a90c56b9f17:core.Destroy.Core", scope: null, file: !1, line: 21, type: !36, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !42)
// CHECK:STDOUT: !42 = !{!43}
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !41, type: !8)
// CHECK:STDOUT: !44 = !DILocation(line: 21, column: 21, scope: !41)
// CHECK:STDOUT: !45 = distinct !DISubprogram(name: "Op", linkageName: "_COp.cffe352dfb12b6f8:core.Destroy.Core", scope: null, file: !1, line: 21, type: !36, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !46)
// CHECK:STDOUT: !46 = !{!47}
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !45, type: !8)
// CHECK:STDOUT: !48 = !DILocation(line: 21, column: 21, scope: !45)
// CHECK:STDOUT: !49 = distinct !DISubprogram(name: "Op", linkageName: "_COp.6990259bb5e562c9:core.Destroy.Core", scope: null, file: !1, line: 21, type: !36, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !50)
// CHECK:STDOUT: !50 = !{!51}
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 1, scope: !49, type: !8)
// CHECK:STDOUT: !52 = !DILocation(line: 21, column: 21, scope: !49)
// CHECK:STDOUT: !53 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Opt.Main.84588f41d61dafba", scope: null, file: !1, line: 6, type: !54, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !56)
// CHECK:STDOUT: !54 = !DISubroutineType(types: !55)
// CHECK:STDOUT: !55 = !{!8, !7}
// CHECK:STDOUT: !56 = !{!57}
// CHECK:STDOUT: !57 = !DILocalVariable(arg: 1, scope: !53, type: !7)
// CHECK:STDOUT: !58 = !DILocation(line: 6, column: 1, scope: !53)
// CHECK:STDOUT: !59 = !DILocation(line: 7, column: 17, scope: !53)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'optional.carbon'
// CHECK:STDOUT: source_filename = "optional.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Optional.val.dae = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] poison }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @Optional.val.dae.None.ref = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] poison }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @Optional.val.b3e.loc5_26.7 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 false, [3 x i8] poison }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CIsPresent.Main(ptr %o) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12_16.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc12_16.4 = load i8, ptr %.loc12_16.3.discriminant, align 1, !dbg !11
// CHECK:STDOUT:   %.loc12_16.41 = trunc i8 %.loc12_16.4 to i1, !dbg !11
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc12_16.41, !dbg !11
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !11
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !12
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !13
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc22_47.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !17
// CHECK:STDOUT:   %IsPresent.call.loc19 = call i32 @_CIsPresent.Main(ptr @Optional.val.dae.None.ref), !dbg !18
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.call = icmp ne i32 %IsPresent.call.loc19, 0, !dbg !18
// CHECK:STDOUT:   br i1 %Int.as.EqWith.impl.NotEqual.call, label %if.then, label %if.else, !dbg !19
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !20
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc22_47.1.temp), !dbg !17
// CHECK:STDOUT:   call void @_CSome.Optional.Main.84588f41d61dafba(ptr %.loc22_47.1.temp, i32 42), !dbg !17
// CHECK:STDOUT:   %IsPresent.call.loc23 = call i32 @_CIsPresent.Main(ptr %.loc22_47.1.temp), !dbg !21
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call = sub i32 %IsPresent.call.loc23, 1, !dbg !21
// CHECK:STDOUT:   call void @"_COp.f8760729dd138db5:core.Destroy.Core"(ptr %.loc22_47.1.temp), !dbg !17
// CHECK:STDOUT:   ret i32 %Int.as.SubWith.impl.Op.call, !dbg !22
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.7512aa4144aeb8db:core.Destroy.Core"(ptr %self) #0 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !29
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5e27612b9dd31a14:core.Destroy.Core"(ptr %self) #0 !dbg !30 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.b56e66ed2f8c6490:core.Destroy.Core"(ptr %self) #0 !dbg !36 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.f6fc5a90c56b9f17:core.Destroy.Core"(ptr %self) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.cffe352dfb12b6f8:core.Destroy.Core"(ptr %self) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.f8760729dd138db5:core.Destroy.Core"(ptr %self) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSome.Optional.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc5_26.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !59
// CHECK:STDOUT:   %.loc5_26.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !59
// CHECK:STDOUT:   %.loc5_26.5.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc5_26.4.payload, i32 0, i32 0, !dbg !59
// CHECK:STDOUT:   %.loc6_17.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !60
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Optional.val.b3e.loc5_26.7, i64 8, i1 false), !dbg !59
// CHECK:STDOUT:   store { i32 } %.loc6_17.1.tuple.init, ptr %.loc5_26.5.Some, align 4, !dbg !59
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc5_26.5.Some, i32 0, i32 0, !dbg !60
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !60
// CHECK:STDOUT:   ret void, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "optional.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "IsPresent", linkageName: "_CIsPresent.Main", scope: null, file: !1, line: 10, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 12, column: 5, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 12, column: 21, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 13, column: 18, scope: !4)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !1, line: 17, type: !15, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !15 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !16 = !{!7}
// CHECK:STDOUT: !17 = !DILocation(line: 22, column: 26, scope: !14)
// CHECK:STDOUT: !18 = !DILocation(line: 19, column: 7, scope: !14)
// CHECK:STDOUT: !19 = !DILocation(line: 19, column: 6, scope: !14)
// CHECK:STDOUT: !20 = !DILocation(line: 20, column: 5, scope: !14)
// CHECK:STDOUT: !21 = !DILocation(line: 23, column: 10, scope: !14)
// CHECK:STDOUT: !22 = !DILocation(line: 23, column: 3, scope: !14)
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "Op", linkageName: "_COp.7512aa4144aeb8db:core.Destroy.Core", scope: null, file: !1, line: 22, type: !24, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !27)
// CHECK:STDOUT: !24 = !DISubroutineType(types: !25)
// CHECK:STDOUT: !25 = !{null, !26}
// CHECK:STDOUT: !26 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !27 = !{!28}
// CHECK:STDOUT: !28 = !DILocalVariable(arg: 1, scope: !23, type: !26)
// CHECK:STDOUT: !29 = !DILocation(line: 22, column: 26, scope: !23)
// CHECK:STDOUT: !30 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5e27612b9dd31a14:core.Destroy.Core", scope: null, file: !1, line: 22, type: !31, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !33)
// CHECK:STDOUT: !31 = !DISubroutineType(types: !32)
// CHECK:STDOUT: !32 = !{null, !7}
// CHECK:STDOUT: !33 = !{!34}
// CHECK:STDOUT: !34 = !DILocalVariable(arg: 1, scope: !30, type: !7)
// CHECK:STDOUT: !35 = !DILocation(line: 22, column: 26, scope: !30)
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "Op", linkageName: "_COp.b56e66ed2f8c6490:core.Destroy.Core", scope: null, file: !1, line: 22, type: !37, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !39)
// CHECK:STDOUT: !37 = !DISubroutineType(types: !38)
// CHECK:STDOUT: !38 = !{null, !8}
// CHECK:STDOUT: !39 = !{!40}
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !36, type: !8)
// CHECK:STDOUT: !41 = !DILocation(line: 22, column: 26, scope: !36)
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "Op", linkageName: "_COp.f6fc5a90c56b9f17:core.Destroy.Core", scope: null, file: !1, line: 22, type: !37, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !43)
// CHECK:STDOUT: !43 = !{!44}
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !42, type: !8)
// CHECK:STDOUT: !45 = !DILocation(line: 22, column: 26, scope: !42)
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "Op", linkageName: "_COp.cffe352dfb12b6f8:core.Destroy.Core", scope: null, file: !1, line: 22, type: !37, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !47)
// CHECK:STDOUT: !47 = !{!48}
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !46, type: !8)
// CHECK:STDOUT: !49 = !DILocation(line: 22, column: 26, scope: !46)
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "Op", linkageName: "_COp.f8760729dd138db5:core.Destroy.Core", scope: null, file: !1, line: 22, type: !37, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !51)
// CHECK:STDOUT: !51 = !{!52}
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !50, type: !8)
// CHECK:STDOUT: !53 = !DILocation(line: 22, column: 26, scope: !50)
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Main.84588f41d61dafba", scope: null, file: !1, line: 5, type: !55, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !57)
// CHECK:STDOUT: !55 = !DISubroutineType(types: !56)
// CHECK:STDOUT: !56 = !{!8, !7}
// CHECK:STDOUT: !57 = !{!58}
// CHECK:STDOUT: !58 = !DILocalVariable(arg: 1, scope: !54, type: !7)
// CHECK:STDOUT: !59 = !DILocation(line: 5, column: 1, scope: !54)
// CHECK:STDOUT: !60 = !DILocation(line: 6, column: 17, scope: !54)
// CHECK:STDOUT:

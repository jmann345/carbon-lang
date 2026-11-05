// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/template/match_choice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/template/match_choice.carbon

// Refutable patterns on a template-dependent choice value (TP-1 round 10,
// X-1; check/testdata/generic/template/match_choice.carbon): each specific
// compares its own discriminant and reads its payload at its own offset, and
// an integer of a template-dependent width compares at its own width.

// --- designator_arm.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Get[template T: type](s: Opt(T), d: T) -> T {
  match (s) {
    case .None => { return d; }
    case .Some(n: T) => { return n; }
  }
  return d;
}

fn UseI8(s: Opt(i8), d: i8) -> i8 {
  return Get(s, d);
}

fn UseI64(s: Opt(i64), d: i64) -> i64 {
  return Get(s, d);
}

// --- class_template_choice.carbon
library "[[@TEST_NAME]]";

class Outer(template T: type) {
  choice C {
    A(n: T),
    B
  }

  fn Get(t: T, full: bool) -> i32 {
    var c: C = C.B;
    if (full) {
      c = C.A(t);
    }
    match (c) {
      case .B => { return 0; }
      case .A(_: T) => { return 1; }
    }
    return -1;
  }
}

fn Use(x: i32) -> i32 {
  return Outer(i32).Get(x, true);
}

// --- let_else_payload.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Unwrap[template T: type](s: Opt(T), d: T) -> T {
  let .Some(n: T) = s else { return d; }
  return n;
}

fn Use(s: Opt(i64), d: i64) -> i64 {
  return Unwrap(s, d);
}

// --- int_scrutinee.carbon
library "[[@TEST_NAME]]";

fn Kind[template N: Core.IntLiteral](x: Core.Int(N)) -> i32 {
  match (x) {
    case 1 => { return 1; }
    case -1 => { return 2; }
    default => { return 0; }
  }
}

fn UseI8(a: i8) -> i32 {
  return Kind(a);
}

fn UseI64(b: i64) -> i32 {
  return Kind(b);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'designator_arm.carbon'
// CHECK:STDOUT: source_filename = "designator_arm.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Opt.val.1ca = internal constant { i1, [1 x i8] } { i1 true, [1 x i8] zeroinitializer }
// CHECK:STDOUT: @Opt.val.9e6 = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i8 @_CUseI8.Main(ptr %s, i8 %d) #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Get.call = call i8 @_CGet.Main.1590cb8a669ddba5(ptr %s, i8 %d), !dbg !23
// CHECK:STDOUT:   ret i8 %Get.call, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CUseI64.Main(ptr %s, i64 %d) #0 !dbg !26 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Get.call = call i64 @_CGet.Main.f249b435619a5146(ptr %s, i64 %d), !dbg !35
// CHECK:STDOUT:   ret i64 %Get.call, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i8 @_CGet.Main.1590cb8a669ddba5(ptr %s, i8 %d) #0 !dbg !38 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_16.3.discriminant = getelementptr inbounds nuw { i1, [1 x i8] }, ptr %s, i32 0, i32 0, !dbg !46
// CHECK:STDOUT:   %.loc10_16.4 = load i8, ptr %.loc10_16.3.discriminant, align 1, !dbg !46
// CHECK:STDOUT:   %.loc10_16.41 = trunc i8 %.loc10_16.4 to i1, !dbg !46
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc10 = icmp eq i1 true, %.loc10_16.41, !dbg !46
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc10, label %match.case.then.loc10, label %match.case.else.loc10, !dbg !46
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc10:                            ; preds = %entry
// CHECK:STDOUT:   ret i8 %d, !dbg !48
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc10:                            ; preds = %entry
// CHECK:STDOUT:   %.loc11_22.3.discriminant = getelementptr inbounds nuw { i1, [1 x i8] }, ptr %s, i32 0, i32 0, !dbg !49
// CHECK:STDOUT:   %.loc11_22.4 = load i8, ptr %.loc11_22.3.discriminant, align 1, !dbg !49
// CHECK:STDOUT:   %.loc11_22.42 = trunc i8 %.loc11_22.4 to i1, !dbg !49
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc11 = icmp eq i1 false, %.loc11_22.42, !dbg !49
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc11, label %match.case.then.loc11, label %match.done, !dbg !49
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc11:                            ; preds = %match.case.else.loc10
// CHECK:STDOUT:   %.loc11_22.7.payload = getelementptr inbounds nuw { i1, [1 x i8] }, ptr %s, i32 0, i32 1, !dbg !49
// CHECK:STDOUT:   %.loc11_22.8.Some = getelementptr inbounds nuw [1 x i8], ptr %.loc11_22.7.payload, i32 0, i32 0, !dbg !49
// CHECK:STDOUT:   %tuple.elem0.loc11_22.tuple.elem = getelementptr inbounds nuw { i8 }, ptr %.loc11_22.8.Some, i32 0, i32 0, !dbg !49
// CHECK:STDOUT:   %.loc11_22.9 = load i8, ptr %tuple.elem0.loc11_22.tuple.elem, align 1, !dbg !49
// CHECK:STDOUT:   ret i8 %.loc11_22.9, !dbg !52
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc10
// CHECK:STDOUT:   ret i8 %d, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CGet.Main.f249b435619a5146(ptr %s, i64 %d) #0 !dbg !57 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_16.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %s, i32 0, i32 0, !dbg !65
// CHECK:STDOUT:   %.loc10_16.4 = load i8, ptr %.loc10_16.3.discriminant, align 1, !dbg !65
// CHECK:STDOUT:   %.loc10_16.41 = trunc i8 %.loc10_16.4 to i1, !dbg !65
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc10 = icmp eq i1 true, %.loc10_16.41, !dbg !65
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc10, label %match.case.then.loc10, label %match.case.else.loc10, !dbg !65
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc10:                            ; preds = %entry
// CHECK:STDOUT:   ret i64 %d, !dbg !67
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc10:                            ; preds = %entry
// CHECK:STDOUT:   %.loc11_22.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %s, i32 0, i32 0, !dbg !68
// CHECK:STDOUT:   %.loc11_22.4 = load i8, ptr %.loc11_22.3.discriminant, align 1, !dbg !68
// CHECK:STDOUT:   %.loc11_22.42 = trunc i8 %.loc11_22.4 to i1, !dbg !68
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc11 = icmp eq i1 false, %.loc11_22.42, !dbg !68
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc11, label %match.case.then.loc11, label %match.done, !dbg !68
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc11:                            ; preds = %match.case.else.loc10
// CHECK:STDOUT:   %.loc11_22.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %s, i32 0, i32 1, !dbg !68
// CHECK:STDOUT:   %.loc11_22.8.Some = getelementptr inbounds nuw [8 x i8], ptr %.loc11_22.7.payload, i32 0, i32 0, !dbg !68
// CHECK:STDOUT:   %tuple.elem0.loc11_22.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc11_22.8.Some, i32 0, i32 0, !dbg !68
// CHECK:STDOUT:   %.loc11_22.9 = load i64, ptr %tuple.elem0.loc11_22.tuple.elem, align 8, !dbg !68
// CHECK:STDOUT:   ret i64 %.loc11_22.9, !dbg !71
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc10
// CHECK:STDOUT:   ret i64 %d, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "designator_arm.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!7, !9, !7}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!8, !9, !8}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "UseI8", linkageName: "_CUseI8.Main", scope: null, file: !4, line: 16, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !25)
// CHECK:STDOUT: !15 = !DILocalVariable(arg: 1, scope: !14, type: !9)
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 2, scope: !14, type: !7)
// CHECK:STDOUT: !23 = !DILocation(line: 17, column: 10, scope: !14)
// CHECK:STDOUT: !24 = !DILocation(line: 17, column: 3, scope: !14)
// CHECK:STDOUT: !25 = !{!15, !16}
// CHECK:STDOUT: !26 = distinct !DISubprogram(name: "UseI64", linkageName: "_CUseI64.Main", scope: null, file: !4, line: 20, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !37)
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 1, scope: !26, type: !9)
// CHECK:STDOUT: !28 = !DILocalVariable(arg: 2, scope: !26, type: !8)
// CHECK:STDOUT: !35 = !DILocation(line: 21, column: 10, scope: !26)
// CHECK:STDOUT: !36 = !DILocation(line: 21, column: 3, scope: !26)
// CHECK:STDOUT: !37 = !{!27, !28}
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Main.1590cb8a669ddba5", scope: null, file: !4, line: 8, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !56)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !38, type: !9)
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 2, scope: !38, type: !7)
// CHECK:STDOUT: !46 = !DILocation(line: 10, column: 5, scope: !38)
// CHECK:STDOUT: !48 = !DILocation(line: 10, column: 21, scope: !38)
// CHECK:STDOUT: !49 = !DILocation(line: 11, column: 5, scope: !38)
// CHECK:STDOUT: !52 = !DILocation(line: 11, column: 27, scope: !38)
// CHECK:STDOUT: !55 = !DILocation(line: 13, column: 3, scope: !38)
// CHECK:STDOUT: !56 = !{!39, !40}
// CHECK:STDOUT: !57 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Main.f249b435619a5146", scope: null, file: !4, line: 8, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !75)
// CHECK:STDOUT: !58 = !DILocalVariable(arg: 1, scope: !57, type: !9)
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 2, scope: !57, type: !8)
// CHECK:STDOUT: !65 = !DILocation(line: 10, column: 5, scope: !57)
// CHECK:STDOUT: !67 = !DILocation(line: 10, column: 21, scope: !57)
// CHECK:STDOUT: !68 = !DILocation(line: 11, column: 5, scope: !57)
// CHECK:STDOUT: !71 = !DILocation(line: 11, column: 27, scope: !57)
// CHECK:STDOUT: !74 = !DILocation(line: 13, column: 3, scope: !57)
// CHECK:STDOUT: !75 = !{!58, !59}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'class_template_choice.carbon'
// CHECK:STDOUT: source_filename = "class_template_choice.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @C.val.375 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @C.val.375.loc10_5.1 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @C.val.0c0.loc4_12.7 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main(i32 %x) #0 !dbg !87 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Outer.Get.call = call i32 @_CGet.Outer.Main.84588f41d61dafba(i32 %x, i1 true), !dbg !93
// CHECK:STDOUT:   ret i32 %Outer.Get.call, !dbg !96
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !98 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !100
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !102 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !104
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !106 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !108
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !108
// CHECK:STDOUT:   ret void, !dbg !108
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !110 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !112
// CHECK:STDOUT:   ret void, !dbg !112
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.39a5d351f615ae94:core.Destroy.Core"(ptr %self) #0 !dbg !114 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !116
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.39a5d351f615ae94:core.Destroy.Core"(ptr %self) #0 !dbg !118 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.39a5d351f615ae94:core.Destroy.Core"(ptr %self), !dbg !120
// CHECK:STDOUT:   ret void, !dbg !120
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.913cee32058e1221:core.Destroy.Core"(ptr %self) #0 !dbg !122 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_5.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !124
// CHECK:STDOUT:   call void @"_CSelfDestruct.39a5d351f615ae94:core.Destroy.Core"(ptr %.loc10_5.1.payload), !dbg !124
// CHECK:STDOUT:   %.loc10_5.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !124
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc10_5.2.discriminant), !dbg !124
// CHECK:STDOUT:   ret void, !dbg !124
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.913cee32058e1221:core.Destroy.Core"(ptr %self) #0 !dbg !126 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.913cee32058e1221:core.Destroy.Core"(ptr %self), !dbg !128
// CHECK:STDOUT:   ret void, !dbg !128
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b7f1e1b560451d07:core.Destroy.Core"(ptr %self) #0 !dbg !130 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !132
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b7f1e1b560451d07:core.Destroy.Core"(ptr %self) #0 !dbg !134 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b7f1e1b560451d07:core.Destroy.Core"(ptr %self), !dbg !136
// CHECK:STDOUT:   ret void, !dbg !136
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Outer.Main.84588f41d61dafba(i32 %t, i1 %full) #0 !dbg !138 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %c.var = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !145
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %c.var), !dbg !145
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %c.var, ptr align 4 @C.val.375.loc10_5.1, i64 8, i1 false), !dbg !145
// CHECK:STDOUT:   br i1 %full, label %if.then, label %if.else, !dbg !148
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CA.C.Outer.Main.84588f41d61dafba(ptr %c.var, i32 %t), !dbg !151
// CHECK:STDOUT:   br label %if.else, !dbg !154
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %if.then, %entry
// CHECK:STDOUT:   %.loc15_15.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %c.var, i32 0, i32 0, !dbg !156
// CHECK:STDOUT:   %.loc15_15.4 = load i8, ptr %.loc15_15.3.discriminant, align 1, !dbg !156
// CHECK:STDOUT:   %.loc15_15.41 = trunc i8 %.loc15_15.4 to i1, !dbg !156
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15 = icmp eq i1 true, %.loc15_15.41, !dbg !156
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc15, label %match.case.then.loc15, label %match.case.else.loc15, !dbg !156
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc15:                            ; preds = %if.else
// CHECK:STDOUT:   call void @"_CSelfDestruct.b7f1e1b560451d07:core.Destroy.Core"(ptr %c.var), !dbg !145
// CHECK:STDOUT:   ret i32 0, !dbg !157
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc15:                            ; preds = %if.else
// CHECK:STDOUT:   %.loc16_21.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %c.var, i32 0, i32 0, !dbg !158
// CHECK:STDOUT:   %.loc16_21.4 = load i8, ptr %.loc16_21.3.discriminant, align 1, !dbg !158
// CHECK:STDOUT:   %.loc16_21.42 = trunc i8 %.loc16_21.4 to i1, !dbg !158
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc16 = icmp eq i1 false, %.loc16_21.42, !dbg !158
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc16, label %match.case.then.loc16, label %match.done, !dbg !158
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc16:                            ; preds = %match.case.else.loc15
// CHECK:STDOUT:   %.loc16_21.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %c.var, i32 0, i32 1, !dbg !158
// CHECK:STDOUT:   %.loc16_21.8.A = getelementptr inbounds nuw [4 x i8], ptr %.loc16_21.7.payload, i32 0, i32 0, !dbg !158
// CHECK:STDOUT:   %tuple.elem0.loc16.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc16_21.8.A, i32 0, i32 0, !dbg !158
// CHECK:STDOUT:   %.loc16_21.9 = load i32, ptr %tuple.elem0.loc16.tuple.elem, align 4, !dbg !158
// CHECK:STDOUT:   call void @"_CSelfDestruct.b7f1e1b560451d07:core.Destroy.Core"(ptr %c.var), !dbg !145
// CHECK:STDOUT:   ret i32 1, !dbg !160
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc15
// CHECK:STDOUT:   call void @"_CSelfDestruct.b7f1e1b560451d07:core.Destroy.Core"(ptr %c.var), !dbg !145
// CHECK:STDOUT:   ret i32 -1, !dbg !162
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CA.C.Outer.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !164 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc4_12.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !166
// CHECK:STDOUT:   %.loc4_12.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !166
// CHECK:STDOUT:   %.loc4_12.5.A = getelementptr inbounds nuw [4 x i8], ptr %.loc4_12.4.payload, i32 0, i32 0, !dbg !166
// CHECK:STDOUT:   %.loc5_12.1.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !167
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @C.val.0c0.loc4_12.7, i64 8, i1 false), !dbg !166
// CHECK:STDOUT:   store { i32 } %.loc5_12.1.tuple.init, ptr %.loc4_12.5.A, align 4, !dbg !166
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc4_12.5.A, i32 0, i32 0, !dbg !167
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem0.tuple.elem, align 4, !dbg !167
// CHECK:STDOUT:   ret void, !dbg !166
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!77}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !76 = !DIFile(filename: "class_template_choice.carbon", directory: "")
// CHECK:STDOUT: !77 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !76, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !78 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !79 = !{!78, !78}
// CHECK:STDOUT: !80 = !DISubroutineType(types: !79)
// CHECK:STDOUT: !81 = !{null, !6}
// CHECK:STDOUT: !82 = !DISubroutineType(types: !81)
// CHECK:STDOUT: !83 = !{null, !78}
// CHECK:STDOUT: !84 = !DISubroutineType(types: !83)
// CHECK:STDOUT: !85 = !{null, !9}
// CHECK:STDOUT: !86 = !DISubroutineType(types: !85)
// CHECK:STDOUT: !87 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !76, line: 22, type: !80, spFlags: DISPFlagDefinition, unit: !77, retainedNodes: !97)
// CHECK:STDOUT: !88 = !DILocalVariable(arg: 1, scope: !87, type: !78)
// CHECK:STDOUT: !93 = !DILocation(line: 23, column: 10, scope: !87)
// CHECK:STDOUT: !94 = !{!78, !78, !9}
// CHECK:STDOUT: !95 = !DISubroutineType(types: !94)
// CHECK:STDOUT: !96 = !DILocation(line: 23, column: 3, scope: !87)
// CHECK:STDOUT: !97 = !{!88}
// CHECK:STDOUT: !98 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !76, line: 10, type: !82, spFlags: DISPFlagDefinition, unit: !77, retainedNodes: !101)
// CHECK:STDOUT: !99 = !DILocalVariable(arg: 1, scope: !98, type: !6)
// CHECK:STDOUT: !100 = !DILocation(line: 10, column: 5, scope: !98)
// CHECK:STDOUT: !101 = !{!99}
// CHECK:STDOUT: !102 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !76, line: 10, type: !84, spFlags: DISPFlagDefinition, unit: !77, retainedNodes: !105)
// CHECK:STDOUT: !103 = !DILocalVariable(arg: 1, scope: !102, type: !78)
// CHECK:STDOUT: !104 = !DILocation(line: 10, column: 5, scope: !102)
// CHECK:STDOUT: !105 = !{!103}
// CHECK:STDOUT: !106 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !76, line: 10, type: !86, spFlags: DISPFlagDefinition, unit: !77, retainedNodes: !109)
// CHECK:STDOUT: !107 = !DILocalVariable(arg: 1, scope: !106, type: !9)
// CHECK:STDOUT: !108 = !DILocation(line: 10, column: 5, scope: !106)
// CHECK:STDOUT: !109 = !{!107}
// CHECK:STDOUT: !110 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !76, line: 10, type: !86, spFlags: DISPFlagDefinition, unit: !77, retainedNodes: !113)
// CHECK:STDOUT: !111 = !DILocalVariable(arg: 1, scope: !110, type: !9)
// CHECK:STDOUT: !112 = !DILocation(line: 10, column: 5, scope: !110)
// CHECK:STDOUT: !113 = !{!111}
// CHECK:STDOUT: !114 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.39a5d351f615ae94:core.Destroy.Core", scope: null, file: !76, line: 10, type: !86, spFlags: DISPFlagDefinition, unit: !77, retainedNodes: !117)
// CHECK:STDOUT: !115 = !DILocalVariable(arg: 1, scope: !114, type: !9)
// CHECK:STDOUT: !116 = !DILocation(line: 10, column: 5, scope: !114)
// CHECK:STDOUT: !117 = !{!115}
// CHECK:STDOUT: !118 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.39a5d351f615ae94:core.Destroy.Core", scope: null, file: !76, line: 10, type: !86, spFlags: DISPFlagDefinition, unit: !77, retainedNodes: !121)
// CHECK:STDOUT: !119 = !DILocalVariable(arg: 1, scope: !118, type: !9)
// CHECK:STDOUT: !120 = !DILocation(line: 10, column: 5, scope: !118)
// CHECK:STDOUT: !121 = !{!119}
// CHECK:STDOUT: !122 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.913cee32058e1221:core.Destroy.Core", scope: null, file: !76, line: 10, type: !86, spFlags: DISPFlagDefinition, unit: !77, retainedNodes: !125)
// CHECK:STDOUT: !123 = !DILocalVariable(arg: 1, scope: !122, type: !9)
// CHECK:STDOUT: !124 = !DILocation(line: 10, column: 5, scope: !122)
// CHECK:STDOUT: !125 = !{!123}
// CHECK:STDOUT: !126 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.913cee32058e1221:core.Destroy.Core", scope: null, file: !76, line: 10, type: !86, spFlags: DISPFlagDefinition, unit: !77, retainedNodes: !129)
// CHECK:STDOUT: !127 = !DILocalVariable(arg: 1, scope: !126, type: !9)
// CHECK:STDOUT: !128 = !DILocation(line: 10, column: 5, scope: !126)
// CHECK:STDOUT: !129 = !{!127}
// CHECK:STDOUT: !130 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b7f1e1b560451d07:core.Destroy.Core", scope: null, file: !76, line: 10, type: !86, spFlags: DISPFlagDefinition, unit: !77, retainedNodes: !133)
// CHECK:STDOUT: !131 = !DILocalVariable(arg: 1, scope: !130, type: !9)
// CHECK:STDOUT: !132 = !DILocation(line: 10, column: 5, scope: !130)
// CHECK:STDOUT: !133 = !{!131}
// CHECK:STDOUT: !134 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b7f1e1b560451d07:core.Destroy.Core", scope: null, file: !76, line: 10, type: !86, spFlags: DISPFlagDefinition, unit: !77, retainedNodes: !137)
// CHECK:STDOUT: !135 = !DILocalVariable(arg: 1, scope: !134, type: !9)
// CHECK:STDOUT: !136 = !DILocation(line: 10, column: 5, scope: !134)
// CHECK:STDOUT: !137 = !{!135}
// CHECK:STDOUT: !138 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Outer.Main.84588f41d61dafba", scope: null, file: !76, line: 9, type: !95, spFlags: DISPFlagDefinition, unit: !77, retainedNodes: !163)
// CHECK:STDOUT: !139 = !DILocalVariable(arg: 1, scope: !138, type: !78)
// CHECK:STDOUT: !140 = !DILocalVariable(arg: 2, scope: !138, type: !9)
// CHECK:STDOUT: !145 = !DILocation(line: 10, column: 5, scope: !138)
// CHECK:STDOUT: !148 = !DILocation(line: 11, column: 8, scope: !138)
// CHECK:STDOUT: !151 = !DILocation(line: 12, column: 11, scope: !138)
// CHECK:STDOUT: !152 = !{!9, !78}
// CHECK:STDOUT: !153 = !DISubroutineType(types: !152)
// CHECK:STDOUT: !154 = !DILocation(line: 11, column: 5, scope: !138)
// CHECK:STDOUT: !156 = !DILocation(line: 15, column: 7, scope: !138)
// CHECK:STDOUT: !157 = !DILocation(line: 15, column: 20, scope: !138)
// CHECK:STDOUT: !158 = !DILocation(line: 16, column: 7, scope: !138)
// CHECK:STDOUT: !160 = !DILocation(line: 16, column: 26, scope: !138)
// CHECK:STDOUT: !162 = !DILocation(line: 18, column: 5, scope: !138)
// CHECK:STDOUT: !163 = !{!139, !140}
// CHECK:STDOUT: !164 = distinct !DISubprogram(name: "A", linkageName: "_CA.C.Outer.Main.84588f41d61dafba", scope: null, file: !76, line: 4, type: !153, spFlags: DISPFlagDefinition, unit: !77, retainedNodes: !168)
// CHECK:STDOUT: !165 = !DILocalVariable(arg: 1, scope: !164, type: !78)
// CHECK:STDOUT: !166 = !DILocation(line: 4, column: 3, scope: !164)
// CHECK:STDOUT: !167 = !DILocation(line: 5, column: 12, scope: !164)
// CHECK:STDOUT: !168 = !{!165}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'let_else_payload.carbon'
// CHECK:STDOUT: source_filename = "let_else_payload.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Opt.val.9e6 = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CUse.Main(ptr %s, i64 %d) #0 !dbg !171 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Unwrap.call = call i64 @_CUnwrap.Main.f249b435619a5146(ptr %s, i64 %d), !dbg !180
// CHECK:STDOUT:   ret i64 %Unwrap.call, !dbg !181
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CUnwrap.Main.f249b435619a5146(ptr %s, i64 %d) #0 !dbg !183 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_23.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %s, i32 0, i32 0, !dbg !191
// CHECK:STDOUT:   %.loc9_23.4 = load i8, ptr %.loc9_23.3.discriminant, align 1, !dbg !191
// CHECK:STDOUT:   %.loc9_23.41 = trunc i8 %.loc9_23.4 to i1, !dbg !191
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 false, %.loc9_23.41, !dbg !191
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %let.then, label %let.else, !dbg !191
// CHECK:STDOUT:
// CHECK:STDOUT: let.else:                                         ; preds = %entry
// CHECK:STDOUT:   ret i64 %d, !dbg !193
// CHECK:STDOUT:
// CHECK:STDOUT: let.then:                                         ; preds = %entry
// CHECK:STDOUT:   %.loc9_3.1.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %s, i32 0, i32 1, !dbg !194
// CHECK:STDOUT:   %.loc9_3.2.Some = getelementptr inbounds nuw [8 x i8], ptr %.loc9_3.1.payload, i32 0, i32 0, !dbg !194
// CHECK:STDOUT:   %tuple.elem0.loc9_3.tuple.elem = getelementptr inbounds nuw { i64 }, ptr %.loc9_3.2.Some, i32 0, i32 0, !dbg !194
// CHECK:STDOUT:   %.loc9_3.3 = load i64, ptr %tuple.elem0.loc9_3.tuple.elem, align 8, !dbg !194
// CHECK:STDOUT:   ret i64 %.loc9_3.3, !dbg !197
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!170}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !12 = !{!8, !9, !8}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !169 = !DIFile(filename: "let_else_payload.carbon", directory: "")
// CHECK:STDOUT: !170 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !169, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !171 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !169, line: 13, type: !13, spFlags: DISPFlagDefinition, unit: !170, retainedNodes: !182)
// CHECK:STDOUT: !172 = !DILocalVariable(arg: 1, scope: !171, type: !9)
// CHECK:STDOUT: !173 = !DILocalVariable(arg: 2, scope: !171, type: !8)
// CHECK:STDOUT: !180 = !DILocation(line: 14, column: 10, scope: !171)
// CHECK:STDOUT: !181 = !DILocation(line: 14, column: 3, scope: !171)
// CHECK:STDOUT: !182 = !{!172, !173}
// CHECK:STDOUT: !183 = distinct !DISubprogram(name: "Unwrap", linkageName: "_CUnwrap.Main.f249b435619a5146", scope: null, file: !169, line: 8, type: !13, spFlags: DISPFlagDefinition, unit: !170, retainedNodes: !198)
// CHECK:STDOUT: !184 = !DILocalVariable(arg: 1, scope: !183, type: !9)
// CHECK:STDOUT: !185 = !DILocalVariable(arg: 2, scope: !183, type: !8)
// CHECK:STDOUT: !191 = !DILocation(line: 9, column: 23, scope: !183)
// CHECK:STDOUT: !193 = !DILocation(line: 9, column: 30, scope: !183)
// CHECK:STDOUT: !194 = !DILocation(line: 9, column: 3, scope: !183)
// CHECK:STDOUT: !197 = !DILocation(line: 10, column: 3, scope: !183)
// CHECK:STDOUT: !198 = !{!184, !185}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'int_scrutinee.carbon'
// CHECK:STDOUT: source_filename = "int_scrutinee.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseI8.Main(i8 %a) #0 !dbg !205 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Kind.call = call i32 @_CKind.Main.ca1ac10d3fc7c1a8(i8 %a), !dbg !211
// CHECK:STDOUT:   ret i32 %Kind.call, !dbg !212
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseI64.Main(i64 %b) #0 !dbg !214 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Kind.call = call i32 @_CKind.Main.9025b11fc94ef1f2(i64 %b), !dbg !220
// CHECK:STDOUT:   ret i32 %Kind.call, !dbg !221
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CKind.Main.ca1ac10d3fc7c1a8(i8 %x) #0 !dbg !223 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.a9d = icmp eq i8 1, %x, !dbg !229
// CHECK:STDOUT:   br i1 %T.as_type.as.EqWith.impl.Equal.call.a9d, label %match.case.then.loc5, label %match.case.else.loc5, !dbg !229
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc5:                             ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !230
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc5:                             ; preds = %entry
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.e98 = icmp eq i8 -1, %x, !dbg !231
// CHECK:STDOUT:   br i1 %T.as_type.as.EqWith.impl.Equal.call.e98, label %match.case.then.loc6, label %match.case.else.loc6, !dbg !231
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc6:                             ; preds = %match.case.else.loc5
// CHECK:STDOUT:   ret i32 2, !dbg !232
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc6:                             ; preds = %match.case.else.loc5
// CHECK:STDOUT:   ret i32 0, !dbg !233
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CKind.Main.9025b11fc94ef1f2(i64 %x) #0 !dbg !235 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.525 = icmp eq i64 1, %x, !dbg !241
// CHECK:STDOUT:   br i1 %T.as_type.as.EqWith.impl.Equal.call.525, label %match.case.then.loc5, label %match.case.else.loc5, !dbg !241
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc5:                             ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !242
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc5:                             ; preds = %entry
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.416 = icmp eq i64 -1, %x, !dbg !243
// CHECK:STDOUT:   br i1 %T.as_type.as.EqWith.impl.Equal.call.416, label %match.case.then.loc6, label %match.case.else.loc6, !dbg !243
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc6:                             ; preds = %match.case.else.loc5
// CHECK:STDOUT:   ret i32 2, !dbg !244
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc6:                             ; preds = %match.case.else.loc5
// CHECK:STDOUT:   ret i32 0, !dbg !245
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!200}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !78 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !199 = !DIFile(filename: "int_scrutinee.carbon", directory: "")
// CHECK:STDOUT: !200 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !199, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !201 = !{!78, !7}
// CHECK:STDOUT: !202 = !DISubroutineType(types: !201)
// CHECK:STDOUT: !203 = !{!78, !8}
// CHECK:STDOUT: !204 = !DISubroutineType(types: !203)
// CHECK:STDOUT: !205 = distinct !DISubprogram(name: "UseI8", linkageName: "_CUseI8.Main", scope: null, file: !199, line: 11, type: !202, spFlags: DISPFlagDefinition, unit: !200, retainedNodes: !213)
// CHECK:STDOUT: !206 = !DILocalVariable(arg: 1, scope: !205, type: !7)
// CHECK:STDOUT: !211 = !DILocation(line: 12, column: 10, scope: !205)
// CHECK:STDOUT: !212 = !DILocation(line: 12, column: 3, scope: !205)
// CHECK:STDOUT: !213 = !{!206}
// CHECK:STDOUT: !214 = distinct !DISubprogram(name: "UseI64", linkageName: "_CUseI64.Main", scope: null, file: !199, line: 15, type: !204, spFlags: DISPFlagDefinition, unit: !200, retainedNodes: !222)
// CHECK:STDOUT: !215 = !DILocalVariable(arg: 1, scope: !214, type: !8)
// CHECK:STDOUT: !220 = !DILocation(line: 16, column: 10, scope: !214)
// CHECK:STDOUT: !221 = !DILocation(line: 16, column: 3, scope: !214)
// CHECK:STDOUT: !222 = !{!215}
// CHECK:STDOUT: !223 = distinct !DISubprogram(name: "Kind", linkageName: "_CKind.Main.ca1ac10d3fc7c1a8", scope: null, file: !199, line: 3, type: !202, spFlags: DISPFlagDefinition, unit: !200, retainedNodes: !234)
// CHECK:STDOUT: !224 = !DILocalVariable(arg: 1, scope: !223, type: !7)
// CHECK:STDOUT: !229 = !DILocation(line: 5, column: 5, scope: !223)
// CHECK:STDOUT: !230 = !DILocation(line: 5, column: 17, scope: !223)
// CHECK:STDOUT: !231 = !DILocation(line: 6, column: 5, scope: !223)
// CHECK:STDOUT: !232 = !DILocation(line: 6, column: 18, scope: !223)
// CHECK:STDOUT: !233 = !DILocation(line: 7, column: 18, scope: !223)
// CHECK:STDOUT: !234 = !{!224}
// CHECK:STDOUT: !235 = distinct !DISubprogram(name: "Kind", linkageName: "_CKind.Main.9025b11fc94ef1f2", scope: null, file: !199, line: 3, type: !204, spFlags: DISPFlagDefinition, unit: !200, retainedNodes: !246)
// CHECK:STDOUT: !236 = !DILocalVariable(arg: 1, scope: !235, type: !8)
// CHECK:STDOUT: !241 = !DILocation(line: 5, column: 5, scope: !235)
// CHECK:STDOUT: !242 = !DILocation(line: 5, column: 17, scope: !235)
// CHECK:STDOUT: !243 = !DILocation(line: 6, column: 5, scope: !235)
// CHECK:STDOUT: !244 = !DILocation(line: 6, column: 18, scope: !235)
// CHECK:STDOUT: !245 = !DILocation(line: 7, column: 18, scope: !235)
// CHECK:STDOUT: !246 = !{!236}
// CHECK:STDOUT:

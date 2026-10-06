// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/var_alternative.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/var_alternative.carbon

// The var-alternative lane in a `case` (W-012 §1.1): one alloca per arm for
// the payload tuple, initialized by copy from the payload region in the
// arm's body block; writes through the binding hit the arm's own storage.

choice OptInt {
  Some(x: i32),
  None
}

fn RootVar(o: OptInt) -> i32 {
  match (o) {
    case var .Some(n: i32) => { n = n + 1; return n; }
    case .None => { return 0; }
  }
  return -1;
}

fn PayloadVar(o: OptInt) -> i32 {
  match (o) {
    case .Some(var n: i32) => { n = n + 2; return n; }
    case .None => { return 0; }
  }
  return -1;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'var_alternative.carbon'
// CHECK:STDOUT: source_filename = "var_alternative.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @OptInt.val = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @OptInt.val.loc20_1.13 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CSome.OptInt.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_15.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !19
// CHECK:STDOUT:   %.loc17_15.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !19
// CHECK:STDOUT:   %.loc17_15.5.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc17_15.4.payload, i32 0, i32 0, !dbg !19
// CHECK:STDOUT:   %.loc18_15.2.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !20
// CHECK:STDOUT:   store { i32 } %.loc18_15.2.tuple.init, ptr %.loc17_15.5.Some, align 4, !dbg !19
// CHECK:STDOUT:   store i8 0, ptr %.loc17_15.1.discriminant, align 1, !dbg !19
// CHECK:STDOUT:   ret void, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CRootVar.Main(ptr %o) #0 !dbg !22 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.var = alloca { i32 }, align 4, !dbg !29
// CHECK:STDOUT:   %.loc24_28.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 0, !dbg !28
// CHECK:STDOUT:   %.loc24_28.4 = load i8, ptr %.loc24_28.3.discriminant, align 1, !dbg !28
// CHECK:STDOUT:   %.loc24_28.41 = trunc i8 %.loc24_28.4 to i1, !dbg !28
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc24 = icmp eq i1 false, %.loc24_28.41, !dbg !28
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc24, label %match.case.then.loc24, label %match.case.else.loc24, !dbg !28
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc24:                            ; preds = %entry
// CHECK:STDOUT:   %.loc24_28.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 1, !dbg !28
// CHECK:STDOUT:   %.loc24_28.8.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc24_28.7.payload, i32 0, i32 0, !dbg !28
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.var), !dbg !29
// CHECK:STDOUT:   %tuple.elem0.loc24_28.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc24_28.8.Some, i32 0, i32 0, !dbg !28
// CHECK:STDOUT:   %.loc24_28.9 = load i32, ptr %tuple.elem0.loc24_28.tuple.elem, align 4, !dbg !28
// CHECK:STDOUT:   %.loc24_28.10.tuple.init = insertvalue { i32 } poison, i32 %.loc24_28.9, 0, !dbg !28
// CHECK:STDOUT:   store { i32 } %.loc24_28.10.tuple.init, ptr %.var, align 4, !dbg !29
// CHECK:STDOUT:   %tuple.elem0.loc24_10.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.var, i32 0, i32 0, !dbg !29
// CHECK:STDOUT:   %.loc24_37 = load i32, ptr %tuple.elem0.loc24_10.tuple.elem, align 4, !dbg !32
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc24_37, 1, !dbg !32
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %tuple.elem0.loc24_10.tuple.elem, align 4, !dbg !31
// CHECK:STDOUT:   %.loc24_51 = load i32, ptr %tuple.elem0.loc24_10.tuple.elem, align 4, !dbg !33
// CHECK:STDOUT:   call void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %.var), !dbg !29
// CHECK:STDOUT:   ret i32 %.loc24_51, !dbg !34
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc24:                            ; preds = %entry
// CHECK:STDOUT:   %.loc25_16.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 0, !dbg !35
// CHECK:STDOUT:   %.loc25_16.4 = load i8, ptr %.loc25_16.3.discriminant, align 1, !dbg !35
// CHECK:STDOUT:   %.loc25_16.42 = trunc i8 %.loc25_16.4 to i1, !dbg !35
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc25 = icmp eq i1 true, %.loc25_16.42, !dbg !35
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc25, label %match.case.then.loc25, label %match.done, !dbg !35
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc25:                            ; preds = %match.case.else.loc24
// CHECK:STDOUT:   ret i32 0, !dbg !37
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc24
// CHECK:STDOUT:   ret i32 -1, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !45 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !47
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !47
// CHECK:STDOUT:   ret void, !dbg !47
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !49 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !51
// CHECK:STDOUT:   ret void, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CPayloadVar.Main(ptr %o) #0 !dbg !53 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %n.var = alloca i32, align 4, !dbg !60
// CHECK:STDOUT:   %.loc32_28.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 0, !dbg !59
// CHECK:STDOUT:   %.loc32_28.4 = load i8, ptr %.loc32_28.3.discriminant, align 1, !dbg !59
// CHECK:STDOUT:   %.loc32_28.41 = trunc i8 %.loc32_28.4 to i1, !dbg !59
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc32 = icmp eq i1 false, %.loc32_28.41, !dbg !59
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc32, label %match.case.then.loc32, label %match.case.else.loc32, !dbg !59
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc32:                            ; preds = %entry
// CHECK:STDOUT:   %.loc32_28.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 1, !dbg !59
// CHECK:STDOUT:   %.loc32_28.8.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc32_28.7.payload, i32 0, i32 0, !dbg !59
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc32_28.8.Some, i32 0, i32 0, !dbg !59
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %n.var), !dbg !60
// CHECK:STDOUT:   %.loc32_28.9 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !59
// CHECK:STDOUT:   store i32 %.loc32_28.9, ptr %n.var, align 4, !dbg !60
// CHECK:STDOUT:   %.loc32_37 = load i32, ptr %n.var, align 4, !dbg !63
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc32_37, 2, !dbg !63
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %n.var, align 4, !dbg !62
// CHECK:STDOUT:   %.loc32_51 = load i32, ptr %n.var, align 4, !dbg !64
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %n.var), !dbg !60
// CHECK:STDOUT:   ret i32 %.loc32_51, !dbg !65
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc32:                            ; preds = %entry
// CHECK:STDOUT:   %.loc33_16.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 0, !dbg !66
// CHECK:STDOUT:   %.loc33_16.4 = load i8, ptr %.loc33_16.3.discriminant, align 1, !dbg !66
// CHECK:STDOUT:   %.loc33_16.42 = trunc i8 %.loc33_16.4 to i1, !dbg !66
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc33 = icmp eq i1 true, %.loc33_16.42, !dbg !66
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc33, label %match.case.then.loc33, label %match.done, !dbg !66
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc33:                            ; preds = %match.case.else.loc32
// CHECK:STDOUT:   ret i32 0, !dbg !68
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc32
// CHECK:STDOUT:   ret i32 -1, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "var_alternative.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!8, !6}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = !{!6, !8}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{null, !6}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{null, !8}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.OptInt.Main", scope: null, file: !4, line: 17, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !21)
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !17, type: !6)
// CHECK:STDOUT: !19 = !DILocation(line: 17, column: 1, scope: !17)
// CHECK:STDOUT: !20 = !DILocation(line: 18, column: 15, scope: !17)
// CHECK:STDOUT: !21 = !{!18}
// CHECK:STDOUT: !22 = distinct !DISubprogram(name: "RootVar", linkageName: "_CRootVar.Main", scope: null, file: !4, line: 22, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !40)
// CHECK:STDOUT: !23 = !DILocalVariable(arg: 1, scope: !22, type: !8)
// CHECK:STDOUT: !28 = !DILocation(line: 24, column: 5, scope: !22)
// CHECK:STDOUT: !29 = !DILocation(line: 24, column: 10, scope: !22)
// CHECK:STDOUT: !31 = !DILocation(line: 24, column: 33, scope: !22)
// CHECK:STDOUT: !32 = !DILocation(line: 24, column: 37, scope: !22)
// CHECK:STDOUT: !33 = !DILocation(line: 24, column: 51, scope: !22)
// CHECK:STDOUT: !34 = !DILocation(line: 24, column: 44, scope: !22)
// CHECK:STDOUT: !35 = !DILocation(line: 25, column: 5, scope: !22)
// CHECK:STDOUT: !37 = !DILocation(line: 25, column: 21, scope: !22)
// CHECK:STDOUT: !39 = !DILocation(line: 27, column: 3, scope: !22)
// CHECK:STDOUT: !40 = !{!23}
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 24, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !44)
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !41, type: !6)
// CHECK:STDOUT: !43 = !DILocation(line: 24, column: 10, scope: !41)
// CHECK:STDOUT: !44 = !{!42}
// CHECK:STDOUT: !45 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 24, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !48)
// CHECK:STDOUT: !46 = !DILocalVariable(arg: 1, scope: !45, type: !8)
// CHECK:STDOUT: !47 = !DILocation(line: 24, column: 10, scope: !45)
// CHECK:STDOUT: !48 = !{!46}
// CHECK:STDOUT: !49 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 24, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !52)
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !49, type: !8)
// CHECK:STDOUT: !51 = !DILocation(line: 24, column: 10, scope: !49)
// CHECK:STDOUT: !52 = !{!50}
// CHECK:STDOUT: !53 = distinct !DISubprogram(name: "PayloadVar", linkageName: "_CPayloadVar.Main", scope: null, file: !4, line: 30, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !71)
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !53, type: !8)
// CHECK:STDOUT: !59 = !DILocation(line: 32, column: 5, scope: !53)
// CHECK:STDOUT: !60 = !DILocation(line: 32, column: 16, scope: !53)
// CHECK:STDOUT: !62 = !DILocation(line: 32, column: 33, scope: !53)
// CHECK:STDOUT: !63 = !DILocation(line: 32, column: 37, scope: !53)
// CHECK:STDOUT: !64 = !DILocation(line: 32, column: 51, scope: !53)
// CHECK:STDOUT: !65 = !DILocation(line: 32, column: 44, scope: !53)
// CHECK:STDOUT: !66 = !DILocation(line: 33, column: 5, scope: !53)
// CHECK:STDOUT: !68 = !DILocation(line: 33, column: 21, scope: !53)
// CHECK:STDOUT: !70 = !DILocation(line: 35, column: 3, scope: !53)
// CHECK:STDOUT: !71 = !{!54}
// CHECK:STDOUT:

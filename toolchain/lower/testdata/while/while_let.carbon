// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/while/while_let.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/while/while_let.carbon

// while-let lowers with zero lowering changes (W-012): the loop header
// re-evaluates the initializer and branches on the discriminant compare
// into `while.body`/`while.done`; the payload is read in the body.

choice OptInt {
  Some(x: i32),
  None
}
fn Next(n: i32) -> OptInt {
  if (n > 0) {
    return OptInt.Some(n - 1);
  }
  return OptInt.None;
}

fn F(start: i32) -> i32 {
  var cur: i32 = start;
  while (let .Some(x: i32) = Next(cur)) {
    cur = x;
  }
  return cur;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'while_let.carbon'
// CHECK:STDOUT: source_filename = "while_let.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @OptInt.val = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @OptInt.val.loc20_1.13 = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CSome.OptInt.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_15.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !21
// CHECK:STDOUT:   %.loc17_15.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !21
// CHECK:STDOUT:   %.loc17_15.5.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc17_15.4.payload, i32 0, i32 0, !dbg !21
// CHECK:STDOUT:   %.loc18_15.2.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !22
// CHECK:STDOUT:   store { i32 } %.loc18_15.2.tuple.init, ptr %.loc17_15.5.Some, align 4, !dbg !21
// CHECK:STDOUT:   store i8 0, ptr %.loc17_15.1.discriminant, align 1, !dbg !21
// CHECK:STDOUT:   ret void, !dbg !21
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CNext.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !24 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call = icmp sgt i32 %n, 0, !dbg !29
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Greater.call, label %if.then, label %if.else, !dbg !30
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call = sub i32 %n, 1, !dbg !31
// CHECK:STDOUT:   call void @_CSome.OptInt.Main(ptr %return, i32 %Int.as.SubWith.impl.Op.call), !dbg !32
// CHECK:STDOUT:   ret void, !dbg !33
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @OptInt.val.loc20_1.13, i64 8, i1 false), !dbg !34
// CHECK:STDOUT:   ret void, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CF.Main(i32 %start) #0 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %cur.var = alloca i32, align 4, !dbg !42
// CHECK:STDOUT:   %.loc30_38.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !47
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %cur.var), !dbg !42
// CHECK:STDOUT:   store i32 %start, ptr %cur.var, align 4, !dbg !42
// CHECK:STDOUT:   br label %while.cond, !dbg !45
// CHECK:STDOUT:
// CHECK:STDOUT: while.cond:                                       ; preds = %while.body, %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc30_38.1.temp), !dbg !47
// CHECK:STDOUT:   %.loc30_35 = load i32, ptr %cur.var, align 4, !dbg !46
// CHECK:STDOUT:   call void @_CNext.Main(ptr %.loc30_38.1.temp, i32 %.loc30_35), !dbg !47
// CHECK:STDOUT:   call void @"_CSelfDestruct.7546ca99dc3d5ce1:core.Destroy.Core"(ptr %.loc30_38.1.temp), !dbg !47
// CHECK:STDOUT:   %.loc30_39.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc30_38.1.temp, i32 0, i32 0, !dbg !45
// CHECK:STDOUT:   %.loc30_39.4 = load i8, ptr %.loc30_39.3.discriminant, align 1, !dbg !45
// CHECK:STDOUT:   %.loc30_39.41 = trunc i8 %.loc30_39.4 to i1, !dbg !45
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 false, %.loc30_39.41, !dbg !45
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %while.body, label %while.done, !dbg !45
// CHECK:STDOUT:
// CHECK:STDOUT: while.body:                                       ; preds = %while.cond
// CHECK:STDOUT:   %.loc30_39.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc30_38.1.temp, i32 0, i32 1, !dbg !45
// CHECK:STDOUT:   %.loc30_39.8.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc30_39.7.payload, i32 0, i32 0, !dbg !45
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc30_39.8.Some, i32 0, i32 0, !dbg !45
// CHECK:STDOUT:   %.loc30_39.9 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !45
// CHECK:STDOUT:   store i32 %.loc30_39.9, ptr %cur.var, align 4, !dbg !49
// CHECK:STDOUT:   br label %while.cond, !dbg !51
// CHECK:STDOUT:
// CHECK:STDOUT: while.done:                                       ; preds = %while.cond
// CHECK:STDOUT:   %.loc33 = load i32, ptr %cur.var, align 4, !dbg !52
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %cur.var), !dbg !42
// CHECK:STDOUT:   ret i32 %.loc33, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !55 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !59 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !61
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !63 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !65
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !65
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !67 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !69
// CHECK:STDOUT:   ret void, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e8ee17acba240768:core.Destroy.Core"(ptr %self) #0 !dbg !71 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !73
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e8ee17acba240768:core.Destroy.Core"(ptr %self) #0 !dbg !75 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e8ee17acba240768:core.Destroy.Core"(ptr %self), !dbg !77
// CHECK:STDOUT:   ret void, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e994aeee33fac1a0:core.Destroy.Core"(ptr %self) #0 !dbg !79 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc30_38.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !81
// CHECK:STDOUT:   call void @"_CSelfDestruct.e8ee17acba240768:core.Destroy.Core"(ptr %.loc30_38.1.payload), !dbg !81
// CHECK:STDOUT:   %.loc30_38.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !81
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc30_38.2.discriminant), !dbg !81
// CHECK:STDOUT:   ret void, !dbg !81
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e994aeee33fac1a0:core.Destroy.Core"(ptr %self) #0 !dbg !83 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e994aeee33fac1a0:core.Destroy.Core"(ptr %self), !dbg !85
// CHECK:STDOUT:   ret void, !dbg !85
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.7546ca99dc3d5ce1:core.Destroy.Core"(ptr %self) #0 !dbg !87 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !89
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.7546ca99dc3d5ce1:core.Destroy.Core"(ptr %self) #0 !dbg !91 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.7546ca99dc3d5ce1:core.Destroy.Core"(ptr %self), !dbg !93
// CHECK:STDOUT:   ret void, !dbg !93
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
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
// CHECK:STDOUT: !4 = !DIFile(filename: "while_let.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!8, !6}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = !{!6, !6}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{null, !7}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{null, !6}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = !{null, !8}
// CHECK:STDOUT: !18 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.OptInt.Main", scope: null, file: !4, line: 17, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !23)
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !19, type: !6)
// CHECK:STDOUT: !21 = !DILocation(line: 17, column: 1, scope: !19)
// CHECK:STDOUT: !22 = !DILocation(line: 18, column: 15, scope: !19)
// CHECK:STDOUT: !23 = !{!20}
// CHECK:STDOUT: !24 = distinct !DISubprogram(name: "Next", linkageName: "_CNext.Main", scope: null, file: !4, line: 21, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !36)
// CHECK:STDOUT: !25 = !DILocalVariable(arg: 1, scope: !24, type: !6)
// CHECK:STDOUT: !29 = !DILocation(line: 22, column: 7, scope: !24)
// CHECK:STDOUT: !30 = !DILocation(line: 22, column: 6, scope: !24)
// CHECK:STDOUT: !31 = !DILocation(line: 23, column: 24, scope: !24)
// CHECK:STDOUT: !32 = !DILocation(line: 23, column: 12, scope: !24)
// CHECK:STDOUT: !33 = !DILocation(line: 23, column: 5, scope: !24)
// CHECK:STDOUT: !34 = !DILocation(line: 25, column: 10, scope: !24)
// CHECK:STDOUT: !35 = !DILocation(line: 25, column: 3, scope: !24)
// CHECK:STDOUT: !36 = !{!25}
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !4, line: 28, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !54)
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !37, type: !6)
// CHECK:STDOUT: !42 = !DILocation(line: 29, column: 3, scope: !37)
// CHECK:STDOUT: !45 = !DILocation(line: 30, column: 9, scope: !37)
// CHECK:STDOUT: !46 = !DILocation(line: 30, column: 35, scope: !37)
// CHECK:STDOUT: !47 = !DILocation(line: 30, column: 30, scope: !37)
// CHECK:STDOUT: !49 = !DILocation(line: 31, column: 5, scope: !37)
// CHECK:STDOUT: !51 = !DILocation(line: 30, column: 3, scope: !37)
// CHECK:STDOUT: !52 = !DILocation(line: 33, column: 10, scope: !37)
// CHECK:STDOUT: !53 = !DILocation(line: 33, column: 3, scope: !37)
// CHECK:STDOUT: !54 = !{!38}
// CHECK:STDOUT: !55 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !4, line: 30, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !58)
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !55, type: !7)
// CHECK:STDOUT: !57 = !DILocation(line: 30, column: 30, scope: !55)
// CHECK:STDOUT: !58 = !{!56}
// CHECK:STDOUT: !59 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 30, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !62)
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !59, type: !6)
// CHECK:STDOUT: !61 = !DILocation(line: 30, column: 30, scope: !59)
// CHECK:STDOUT: !62 = !{!60}
// CHECK:STDOUT: !63 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 30, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !66)
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !63, type: !8)
// CHECK:STDOUT: !65 = !DILocation(line: 30, column: 30, scope: !63)
// CHECK:STDOUT: !66 = !{!64}
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 30, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !70)
// CHECK:STDOUT: !68 = !DILocalVariable(arg: 1, scope: !67, type: !8)
// CHECK:STDOUT: !69 = !DILocation(line: 30, column: 30, scope: !67)
// CHECK:STDOUT: !70 = !{!68}
// CHECK:STDOUT: !71 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e8ee17acba240768:core.Destroy.Core", scope: null, file: !4, line: 30, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !74)
// CHECK:STDOUT: !72 = !DILocalVariable(arg: 1, scope: !71, type: !8)
// CHECK:STDOUT: !73 = !DILocation(line: 30, column: 30, scope: !71)
// CHECK:STDOUT: !74 = !{!72}
// CHECK:STDOUT: !75 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e8ee17acba240768:core.Destroy.Core", scope: null, file: !4, line: 30, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !78)
// CHECK:STDOUT: !76 = !DILocalVariable(arg: 1, scope: !75, type: !8)
// CHECK:STDOUT: !77 = !DILocation(line: 30, column: 30, scope: !75)
// CHECK:STDOUT: !78 = !{!76}
// CHECK:STDOUT: !79 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e994aeee33fac1a0:core.Destroy.Core", scope: null, file: !4, line: 30, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !82)
// CHECK:STDOUT: !80 = !DILocalVariable(arg: 1, scope: !79, type: !8)
// CHECK:STDOUT: !81 = !DILocation(line: 30, column: 30, scope: !79)
// CHECK:STDOUT: !82 = !{!80}
// CHECK:STDOUT: !83 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e994aeee33fac1a0:core.Destroy.Core", scope: null, file: !4, line: 30, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !86)
// CHECK:STDOUT: !84 = !DILocalVariable(arg: 1, scope: !83, type: !8)
// CHECK:STDOUT: !85 = !DILocation(line: 30, column: 30, scope: !83)
// CHECK:STDOUT: !86 = !{!84}
// CHECK:STDOUT: !87 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.7546ca99dc3d5ce1:core.Destroy.Core", scope: null, file: !4, line: 30, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !90)
// CHECK:STDOUT: !88 = !DILocalVariable(arg: 1, scope: !87, type: !8)
// CHECK:STDOUT: !89 = !DILocation(line: 30, column: 30, scope: !87)
// CHECK:STDOUT: !90 = !{!88}
// CHECK:STDOUT: !91 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.7546ca99dc3d5ce1:core.Destroy.Core", scope: null, file: !4, line: 30, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !94)
// CHECK:STDOUT: !92 = !DILocalVariable(arg: 1, scope: !91, type: !8)
// CHECK:STDOUT: !93 = !DILocation(line: 30, column: 30, scope: !91)
// CHECK:STDOUT: !94 = !{!92}
// CHECK:STDOUT:

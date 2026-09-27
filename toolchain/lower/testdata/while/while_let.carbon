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
// CHECK:STDOUT: define void @_CSome.OptInt.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_15.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc17_15.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !11
// CHECK:STDOUT:   %.loc17_15.5.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc17_15.4.payload, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc18_15.2.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !12
// CHECK:STDOUT:   store { i32 } %.loc18_15.2.tuple.init, ptr %.loc17_15.5.Some, align 4, !dbg !11
// CHECK:STDOUT:   store i8 0, ptr %.loc17_15.1.discriminant, align 1, !dbg !11
// CHECK:STDOUT:   ret void, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CNext.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !13 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call = icmp sgt i32 %n, 0, !dbg !16
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Greater.call, label %if.then, label %if.else, !dbg !17
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call = sub i32 %n, 1, !dbg !18
// CHECK:STDOUT:   call void @_CSome.OptInt.Main(ptr %return, i32 %Int.as.SubWith.impl.Op.call), !dbg !19
// CHECK:STDOUT:   ret void, !dbg !20
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @OptInt.val.loc20_1.13, i64 8, i1 false), !dbg !21
// CHECK:STDOUT:   ret void, !dbg !22
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CF.Main(i32 %start) #0 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %cur.var = alloca i32, align 4, !dbg !28
// CHECK:STDOUT:   %.loc30_38.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !29
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %cur.var), !dbg !28
// CHECK:STDOUT:   store i32 %start, ptr %cur.var, align 4, !dbg !28
// CHECK:STDOUT:   br label %while.cond, !dbg !30
// CHECK:STDOUT:
// CHECK:STDOUT: while.cond:                                       ; preds = %while.body, %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc30_38.1.temp), !dbg !29
// CHECK:STDOUT:   %.loc30_35 = load i32, ptr %cur.var, align 4, !dbg !31
// CHECK:STDOUT:   call void @_CNext.Main(ptr %.loc30_38.1.temp, i32 %.loc30_35), !dbg !29
// CHECK:STDOUT:   call void @"_COp.b87b6d3737141098:core.Destroy.Core"(ptr %.loc30_38.1.temp), !dbg !29
// CHECK:STDOUT:   %.loc30_39.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc30_38.1.temp, i32 0, i32 0, !dbg !30
// CHECK:STDOUT:   %.loc30_39.4 = load i8, ptr %.loc30_39.3.discriminant, align 1, !dbg !30
// CHECK:STDOUT:   %.loc30_39.41 = trunc i8 %.loc30_39.4 to i1, !dbg !30
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 false, %.loc30_39.41, !dbg !30
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %while.body, label %while.done, !dbg !30
// CHECK:STDOUT:
// CHECK:STDOUT: while.body:                                       ; preds = %while.cond
// CHECK:STDOUT:   %.loc30_39.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc30_38.1.temp, i32 0, i32 1, !dbg !30
// CHECK:STDOUT:   %.loc30_39.8.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc30_39.7.payload, i32 0, i32 0, !dbg !30
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc30_39.8.Some, i32 0, i32 0, !dbg !30
// CHECK:STDOUT:   %.loc30_39.9 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !30
// CHECK:STDOUT:   store i32 %.loc30_39.9, ptr %cur.var, align 4, !dbg !32
// CHECK:STDOUT:   br label %while.cond, !dbg !33
// CHECK:STDOUT:
// CHECK:STDOUT: while.done:                                       ; preds = %while.cond
// CHECK:STDOUT:   %.loc33 = load i32, ptr %cur.var, align 4, !dbg !34
// CHECK:STDOUT:   call void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %cur.var), !dbg !28
// CHECK:STDOUT:   ret i32 %.loc33, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.945345cbed56cb88:core.Destroy.Core"(ptr %self) #0 !dbg !36 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !42
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.216a6481b641f07b:core.Destroy.Core"(ptr %self) #0 !dbg !49 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !54
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.fd2a567691422da4:core.Destroy.Core"(ptr %self) #0 !dbg !55 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !58
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.1f0af22971a53afb:core.Destroy.Core"(ptr %self) #0 !dbg !59 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.b87b6d3737141098:core.Destroy.Core"(ptr %self) #0 !dbg !63 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !66
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "while_let.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.OptInt.Main", scope: null, file: !1, line: 17, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 17, column: 1, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 18, column: 15, scope: !4)
// CHECK:STDOUT: !13 = distinct !DISubprogram(name: "Next", linkageName: "_CNext.Main", scope: null, file: !1, line: 21, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !14)
// CHECK:STDOUT: !14 = !{!15}
// CHECK:STDOUT: !15 = !DILocalVariable(arg: 1, scope: !13, type: !8)
// CHECK:STDOUT: !16 = !DILocation(line: 22, column: 7, scope: !13)
// CHECK:STDOUT: !17 = !DILocation(line: 22, column: 6, scope: !13)
// CHECK:STDOUT: !18 = !DILocation(line: 23, column: 24, scope: !13)
// CHECK:STDOUT: !19 = !DILocation(line: 23, column: 12, scope: !13)
// CHECK:STDOUT: !20 = !DILocation(line: 23, column: 5, scope: !13)
// CHECK:STDOUT: !21 = !DILocation(line: 25, column: 10, scope: !13)
// CHECK:STDOUT: !22 = !DILocation(line: 25, column: 3, scope: !13)
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !1, line: 28, type: !24, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
// CHECK:STDOUT: !24 = !DISubroutineType(types: !25)
// CHECK:STDOUT: !25 = !{!8, !8}
// CHECK:STDOUT: !26 = !{!27}
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 1, scope: !23, type: !8)
// CHECK:STDOUT: !28 = !DILocation(line: 29, column: 3, scope: !23)
// CHECK:STDOUT: !29 = !DILocation(line: 30, column: 30, scope: !23)
// CHECK:STDOUT: !30 = !DILocation(line: 30, column: 9, scope: !23)
// CHECK:STDOUT: !31 = !DILocation(line: 30, column: 35, scope: !23)
// CHECK:STDOUT: !32 = !DILocation(line: 31, column: 5, scope: !23)
// CHECK:STDOUT: !33 = !DILocation(line: 30, column: 3, scope: !23)
// CHECK:STDOUT: !34 = !DILocation(line: 33, column: 10, scope: !23)
// CHECK:STDOUT: !35 = !DILocation(line: 33, column: 3, scope: !23)
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "Op", linkageName: "_COp.945345cbed56cb88:core.Destroy.Core", scope: null, file: !1, line: 30, type: !37, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !40)
// CHECK:STDOUT: !37 = !DISubroutineType(types: !38)
// CHECK:STDOUT: !38 = !{null, !39}
// CHECK:STDOUT: !39 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !40 = !{!41}
// CHECK:STDOUT: !41 = !DILocalVariable(arg: 1, scope: !36, type: !39)
// CHECK:STDOUT: !42 = !DILocation(line: 30, column: 30, scope: !36)
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 30, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !46)
// CHECK:STDOUT: !44 = !DISubroutineType(types: !45)
// CHECK:STDOUT: !45 = !{null, !8}
// CHECK:STDOUT: !46 = !{!47}
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !43, type: !8)
// CHECK:STDOUT: !48 = !DILocation(line: 30, column: 30, scope: !43)
// CHECK:STDOUT: !49 = distinct !DISubprogram(name: "Op", linkageName: "_COp.216a6481b641f07b:core.Destroy.Core", scope: null, file: !1, line: 30, type: !50, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !52)
// CHECK:STDOUT: !50 = !DISubroutineType(types: !51)
// CHECK:STDOUT: !51 = !{null, !7}
// CHECK:STDOUT: !52 = !{!53}
// CHECK:STDOUT: !53 = !DILocalVariable(arg: 1, scope: !49, type: !7)
// CHECK:STDOUT: !54 = !DILocation(line: 30, column: 30, scope: !49)
// CHECK:STDOUT: !55 = distinct !DISubprogram(name: "Op", linkageName: "_COp.fd2a567691422da4:core.Destroy.Core", scope: null, file: !1, line: 30, type: !50, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !56)
// CHECK:STDOUT: !56 = !{!57}
// CHECK:STDOUT: !57 = !DILocalVariable(arg: 1, scope: !55, type: !7)
// CHECK:STDOUT: !58 = !DILocation(line: 30, column: 30, scope: !55)
// CHECK:STDOUT: !59 = distinct !DISubprogram(name: "Op", linkageName: "_COp.1f0af22971a53afb:core.Destroy.Core", scope: null, file: !1, line: 30, type: !50, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !60)
// CHECK:STDOUT: !60 = !{!61}
// CHECK:STDOUT: !61 = !DILocalVariable(arg: 1, scope: !59, type: !7)
// CHECK:STDOUT: !62 = !DILocation(line: 30, column: 30, scope: !59)
// CHECK:STDOUT: !63 = distinct !DISubprogram(name: "Op", linkageName: "_COp.b87b6d3737141098:core.Destroy.Core", scope: null, file: !1, line: 30, type: !50, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !64)
// CHECK:STDOUT: !64 = !{!65}
// CHECK:STDOUT: !65 = !DILocalVariable(arg: 1, scope: !63, type: !7)
// CHECK:STDOUT: !66 = !DILocation(line: 30, column: 30, scope: !63)
// CHECK:STDOUT:

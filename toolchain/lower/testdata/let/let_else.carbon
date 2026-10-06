// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/let/let_else.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/let/let_else.carbon

// let-else lowers with zero lowering changes (W-012): the discriminant
// compare branches into `let.then`/`let.else`, the else block returns, and
// the success block reads the payload; the var-alternative lane's storage
// is an `alloca` hoisted to the entry block, initialized in `let.then`.

choice OptInt {
  Some(x: i32),
  None
}

fn F(o: OptInt) -> i32 {
  let .Some(n: i32) = o else { return -1; }
  return n;
}

fn VarAlternative(o: OptInt) -> i32 {
  var .Some(v: i32) = o else { return 0; }
  v = v + 1;
  return v;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'let_else.carbon'
// CHECK:STDOUT: source_filename = "let_else.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @OptInt.val = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CSome.OptInt.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc18_15.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !19
// CHECK:STDOUT:   %.loc18_15.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !19
// CHECK:STDOUT:   %.loc18_15.5.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc18_15.4.payload, i32 0, i32 0, !dbg !19
// CHECK:STDOUT:   %.loc19_15.2.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !20
// CHECK:STDOUT:   store { i32 } %.loc19_15.2.tuple.init, ptr %.loc18_15.5.Some, align 4, !dbg !19
// CHECK:STDOUT:   store i8 0, ptr %.loc18_15.1.discriminant, align 1, !dbg !19
// CHECK:STDOUT:   ret void, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CF.Main(ptr %o) #0 !dbg !22 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc24_25.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 0, !dbg !28
// CHECK:STDOUT:   %.loc24_25.4 = load i8, ptr %.loc24_25.3.discriminant, align 1, !dbg !28
// CHECK:STDOUT:   %.loc24_25.41 = trunc i8 %.loc24_25.4 to i1, !dbg !28
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 false, %.loc24_25.41, !dbg !28
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %let.then, label %let.else, !dbg !28
// CHECK:STDOUT:
// CHECK:STDOUT: let.else:                                         ; preds = %entry
// CHECK:STDOUT:   ret i32 -1, !dbg !29
// CHECK:STDOUT:
// CHECK:STDOUT: let.then:                                         ; preds = %entry
// CHECK:STDOUT:   %.loc24_3.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 1, !dbg !30
// CHECK:STDOUT:   %.loc24_3.2.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc24_3.1.payload, i32 0, i32 0, !dbg !30
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc24_3.2.Some, i32 0, i32 0, !dbg !30
// CHECK:STDOUT:   %.loc24_3.3 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !30
// CHECK:STDOUT:   ret i32 %.loc24_3.3, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CVarAlternative.Main(ptr %o) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.var = alloca { i32 }, align 4, !dbg !43
// CHECK:STDOUT:   %.loc29_25.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 0, !dbg !41
// CHECK:STDOUT:   %.loc29_25.4 = load i8, ptr %.loc29_25.3.discriminant, align 1, !dbg !41
// CHECK:STDOUT:   %.loc29_25.41 = trunc i8 %.loc29_25.4 to i1, !dbg !41
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 false, %.loc29_25.41, !dbg !41
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %let.then, label %let.else, !dbg !41
// CHECK:STDOUT:
// CHECK:STDOUT: let.else:                                         ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !42
// CHECK:STDOUT:
// CHECK:STDOUT: let.then:                                         ; preds = %entry
// CHECK:STDOUT:   %.loc29_3.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 1, !dbg !43
// CHECK:STDOUT:   %.loc29_3.2.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc29_3.1.payload, i32 0, i32 0, !dbg !43
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.var), !dbg !43
// CHECK:STDOUT:   %tuple.elem0.loc29_3.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc29_3.2.Some, i32 0, i32 0, !dbg !43
// CHECK:STDOUT:   %.loc29_3.3 = load i32, ptr %tuple.elem0.loc29_3.1.tuple.elem, align 4, !dbg !43
// CHECK:STDOUT:   %.loc29_3.4.tuple.init = insertvalue { i32 } poison, i32 %.loc29_3.3, 0, !dbg !43
// CHECK:STDOUT:   store { i32 } %.loc29_3.4.tuple.init, ptr %.var, align 4, !dbg !43
// CHECK:STDOUT:   %tuple.elem0.loc29_3.2.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.var, i32 0, i32 0, !dbg !43
// CHECK:STDOUT:   %.loc30_7 = load i32, ptr %tuple.elem0.loc29_3.2.tuple.elem, align 4, !dbg !46
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc30_7, 1, !dbg !46
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %tuple.elem0.loc29_3.2.tuple.elem, align 4, !dbg !45
// CHECK:STDOUT:   %.loc31 = load i32, ptr %tuple.elem0.loc29_3.2.tuple.elem, align 4, !dbg !47
// CHECK:STDOUT:   call void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %.var), !dbg !43
// CHECK:STDOUT:   ret i32 %.loc31, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !56
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !56
// CHECK:STDOUT:   ret void, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !60
// CHECK:STDOUT:   ret void, !dbg !60
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "let_else.carbon", directory: "")
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
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.OptInt.Main", scope: null, file: !4, line: 18, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !21)
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !17, type: !6)
// CHECK:STDOUT: !19 = !DILocation(line: 18, column: 1, scope: !17)
// CHECK:STDOUT: !20 = !DILocation(line: 19, column: 15, scope: !17)
// CHECK:STDOUT: !21 = !{!18}
// CHECK:STDOUT: !22 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !4, line: 23, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !34)
// CHECK:STDOUT: !23 = !DILocalVariable(arg: 1, scope: !22, type: !8)
// CHECK:STDOUT: !28 = !DILocation(line: 24, column: 25, scope: !22)
// CHECK:STDOUT: !29 = !DILocation(line: 24, column: 32, scope: !22)
// CHECK:STDOUT: !30 = !DILocation(line: 24, column: 3, scope: !22)
// CHECK:STDOUT: !33 = !DILocation(line: 25, column: 3, scope: !22)
// CHECK:STDOUT: !34 = !{!23}
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "VarAlternative", linkageName: "_CVarAlternative.Main", scope: null, file: !4, line: 28, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !49)
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !35, type: !8)
// CHECK:STDOUT: !41 = !DILocation(line: 29, column: 25, scope: !35)
// CHECK:STDOUT: !42 = !DILocation(line: 29, column: 32, scope: !35)
// CHECK:STDOUT: !43 = !DILocation(line: 29, column: 3, scope: !35)
// CHECK:STDOUT: !45 = !DILocation(line: 30, column: 3, scope: !35)
// CHECK:STDOUT: !46 = !DILocation(line: 30, column: 7, scope: !35)
// CHECK:STDOUT: !47 = !DILocation(line: 31, column: 10, scope: !35)
// CHECK:STDOUT: !48 = !DILocation(line: 31, column: 3, scope: !35)
// CHECK:STDOUT: !49 = !{!36}
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 29, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !53)
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 1, scope: !50, type: !6)
// CHECK:STDOUT: !52 = !DILocation(line: 29, column: 3, scope: !50)
// CHECK:STDOUT: !53 = !{!51}
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 29, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !57)
// CHECK:STDOUT: !55 = !DILocalVariable(arg: 1, scope: !54, type: !8)
// CHECK:STDOUT: !56 = !DILocation(line: 29, column: 3, scope: !54)
// CHECK:STDOUT: !57 = !{!55}
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 29, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !61)
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !58, type: !8)
// CHECK:STDOUT: !60 = !DILocation(line: 29, column: 3, scope: !58)
// CHECK:STDOUT: !61 = !{!59}
// CHECK:STDOUT:

// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/if/if_let.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/if/if_let.carbon

// if-let lowers with zero lowering changes (W-012): the discriminant load
// feeds an `icmp` and a `br` into `if.then`/`if.else`, the payload is read
// in `if.then` under the test, and the var-alternative lane's payload-tuple
// storage is an `alloca` hoisted to the entry block, with only its
// `llvm.lifetime.start` and initializing `store` in the then block.

choice OptInt {
  Some(x: i32),
  None
}

fn F(o: OptInt) -> i32 {
  if (let .Some(n: i32) = o) {
    return n;
  } else {
    return 0;
  }
}

fn VarAlternative(o: OptInt) -> i32 {
  if (var .Some(n: i32) = o) {
    n = n + 1;
    return n;
  }
  return 0;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'if_let.carbon'
// CHECK:STDOUT: source_filename = "if_let.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @OptInt.val = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CSome.OptInt.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_15.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc19_15.4.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !11
// CHECK:STDOUT:   %.loc19_15.5.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc19_15.4.payload, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc20_15.2.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !12
// CHECK:STDOUT:   store { i32 } %.loc20_15.2.tuple.init, ptr %.loc19_15.5.Some, align 4, !dbg !11
// CHECK:STDOUT:   store i8 0, ptr %.loc19_15.1.discriminant, align 1, !dbg !11
// CHECK:STDOUT:   ret void, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CF.Main(ptr %o) #0 !dbg !13 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc25_28.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 0, !dbg !18
// CHECK:STDOUT:   %.loc25_28.4 = load i8, ptr %.loc25_28.3.discriminant, align 1, !dbg !18
// CHECK:STDOUT:   %.loc25_28.41 = trunc i8 %.loc25_28.4 to i1, !dbg !18
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 false, %.loc25_28.41, !dbg !18
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %if.then, label %if.else, !dbg !18
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %.loc25_28.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 1, !dbg !18
// CHECK:STDOUT:   %.loc25_28.8.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc25_28.7.payload, i32 0, i32 0, !dbg !18
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc25_28.8.Some, i32 0, i32 0, !dbg !18
// CHECK:STDOUT:   %.loc25_28.9 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !18
// CHECK:STDOUT:   ret i32 %.loc25_28.9, !dbg !19
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !20
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CVarAlternative.Main(ptr %o) #0 !dbg !21 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.var = alloca { i32 }, align 4, !dbg !24
// CHECK:STDOUT:   %.loc33_28.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 0, !dbg !25
// CHECK:STDOUT:   %.loc33_28.4 = load i8, ptr %.loc33_28.3.discriminant, align 1, !dbg !25
// CHECK:STDOUT:   %.loc33_28.41 = trunc i8 %.loc33_28.4 to i1, !dbg !25
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 false, %.loc33_28.41, !dbg !25
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %if.then, label %if.else, !dbg !25
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %.loc33_28.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %o, i32 0, i32 1, !dbg !25
// CHECK:STDOUT:   %.loc33_28.8.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc33_28.7.payload, i32 0, i32 0, !dbg !25
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.var), !dbg !24
// CHECK:STDOUT:   %tuple.elem0.loc33_28.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc33_28.8.Some, i32 0, i32 0, !dbg !25
// CHECK:STDOUT:   %.loc33_28.9 = load i32, ptr %tuple.elem0.loc33_28.tuple.elem, align 4, !dbg !25
// CHECK:STDOUT:   %.loc33_28.10.tuple.init = insertvalue { i32 } poison, i32 %.loc33_28.9, 0, !dbg !25
// CHECK:STDOUT:   store { i32 } %.loc33_28.10.tuple.init, ptr %.var, align 4, !dbg !24
// CHECK:STDOUT:   %tuple.elem0.loc33_7.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.var, i32 0, i32 0, !dbg !24
// CHECK:STDOUT:   %.loc34_9 = load i32, ptr %tuple.elem0.loc33_7.tuple.elem, align 4, !dbg !26
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc34_9, 1, !dbg !26
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %tuple.elem0.loc33_7.tuple.elem, align 4, !dbg !27
// CHECK:STDOUT:   %.loc35 = load i32, ptr %tuple.elem0.loc33_7.tuple.elem, align 4, !dbg !28
// CHECK:STDOUT:   call void @"_COp.216a6481b641f07b:core.Destroy.Core"(ptr %.var), !dbg !24
// CHECK:STDOUT:   ret i32 %.loc35, !dbg !29
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !31 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.216a6481b641f07b:core.Destroy.Core"(ptr %self) #0 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !42
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "if_let.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.OptInt.Main", scope: null, file: !1, line: 19, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 19, column: 1, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 20, column: 15, scope: !4)
// CHECK:STDOUT: !13 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !1, line: 24, type: !14, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !16)
// CHECK:STDOUT: !14 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !15 = !{!8, !7}
// CHECK:STDOUT: !16 = !{!17}
// CHECK:STDOUT: !17 = !DILocalVariable(arg: 1, scope: !13, type: !7)
// CHECK:STDOUT: !18 = !DILocation(line: 25, column: 6, scope: !13)
// CHECK:STDOUT: !19 = !DILocation(line: 26, column: 5, scope: !13)
// CHECK:STDOUT: !20 = !DILocation(line: 28, column: 5, scope: !13)
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "VarAlternative", linkageName: "_CVarAlternative.Main", scope: null, file: !1, line: 32, type: !14, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !22)
// CHECK:STDOUT: !22 = !{!23}
// CHECK:STDOUT: !23 = !DILocalVariable(arg: 1, scope: !21, type: !7)
// CHECK:STDOUT: !24 = !DILocation(line: 33, column: 7, scope: !21)
// CHECK:STDOUT: !25 = !DILocation(line: 33, column: 6, scope: !21)
// CHECK:STDOUT: !26 = !DILocation(line: 34, column: 9, scope: !21)
// CHECK:STDOUT: !27 = !DILocation(line: 34, column: 5, scope: !21)
// CHECK:STDOUT: !28 = !DILocation(line: 35, column: 12, scope: !21)
// CHECK:STDOUT: !29 = !DILocation(line: 35, column: 5, scope: !21)
// CHECK:STDOUT: !30 = !DILocation(line: 37, column: 3, scope: !21)
// CHECK:STDOUT: !31 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 33, type: !32, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !34)
// CHECK:STDOUT: !32 = !DISubroutineType(types: !33)
// CHECK:STDOUT: !33 = !{null, !8}
// CHECK:STDOUT: !34 = !{!35}
// CHECK:STDOUT: !35 = !DILocalVariable(arg: 1, scope: !31, type: !8)
// CHECK:STDOUT: !36 = !DILocation(line: 33, column: 7, scope: !31)
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "Op", linkageName: "_COp.216a6481b641f07b:core.Destroy.Core", scope: null, file: !1, line: 33, type: !38, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !40)
// CHECK:STDOUT: !38 = !DISubroutineType(types: !39)
// CHECK:STDOUT: !39 = !{null, !7}
// CHECK:STDOUT: !40 = !{!41}
// CHECK:STDOUT: !41 = !DILocalVariable(arg: 1, scope: !37, type: !7)
// CHECK:STDOUT: !42 = !DILocation(line: 33, column: 7, scope: !37)
// CHECK:STDOUT:

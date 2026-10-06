// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/union/layout.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/union/layout.carbon

// The lowered storage and stores follow the layout rule: `Wide` is
// `[8 x i8]` aligned to 8 with both fields stored at offset 0; `Odd` is
// `[4 x i8]` aligned to 2.

// --- wide.carbon
library "[[@TEST_NAME]]";

union Wide {
  var lo: i32;
  var both: i64;
}

fn UseWide() -> i32 {
  var w: Wide;
  w.both = 5;
  w.lo = 7;
  return w.lo;
}

// --- odd.carbon
library "[[@TEST_NAME]]";

union Odd {
  var a: i8;
  var b: i16;
  var c: array(i8, 3);
}

fn UseOdd() -> i16 {
  var o: Odd;
  o.b = 3;
  return o.b;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'wide.carbon'
// CHECK:STDOUT: source_filename = "wide.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseWide.Main() #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %w.var = alloca [8 x i8], align 8, !dbg !20
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %w.var), !dbg !20
// CHECK:STDOUT:   %.loc10_4.both = getelementptr inbounds nuw [8 x i8], ptr %w.var, i32 0, i32 0, !dbg !22
// CHECK:STDOUT:   store i64 5, ptr %.loc10_4.both, align 8, !dbg !22
// CHECK:STDOUT:   %.loc11_4.lo = getelementptr inbounds nuw [8 x i8], ptr %w.var, i32 0, i32 0, !dbg !23
// CHECK:STDOUT:   store i32 7, ptr %.loc11_4.lo, align 4, !dbg !23
// CHECK:STDOUT:   %.loc12_11.1.lo = getelementptr inbounds nuw [8 x i8], ptr %w.var, i32 0, i32 0, !dbg !24
// CHECK:STDOUT:   %.loc12_11.2 = load i32, ptr %.loc12_11.1.lo, align 4, !dbg !24
// CHECK:STDOUT:   call void @"_CSelfDestruct.90d5c1783df5d1b7:core.Destroy.Core"(ptr %w.var), !dbg !20
// CHECK:STDOUT:   ret i32 %.loc12_11.2, !dbg !25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !26 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !30 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.54e625b7123b91de:core.Destroy.Core"(ptr %self) #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.54e625b7123b91de:core.Destroy.Core"(ptr %self) #0 !dbg !38 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.54e625b7123b91de:core.Destroy.Core"(ptr %self), !dbg !40
// CHECK:STDOUT:   ret void, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.90d5c1783df5d1b7:core.Destroy.Core"(ptr %self) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.both = getelementptr inbounds nuw [8 x i8], ptr %self, i32 0, i32 0, !dbg !44
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.loc9_3.1.both), !dbg !44
// CHECK:STDOUT:   %.loc9_3.2.lo = getelementptr inbounds nuw [8 x i8], ptr %self, i32 0, i32 0, !dbg !44
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.2.lo), !dbg !44
// CHECK:STDOUT:   ret void, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.90d5c1783df5d1b7:core.Destroy.Core"(ptr %self) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.90d5c1783df5d1b7:core.Destroy.Core"(ptr %self), !dbg !48
// CHECK:STDOUT:   ret void, !dbg !48
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
// CHECK:STDOUT: !4 = !DIFile(filename: "wide.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{!6}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{null, !6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !15 = !{null, !14}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "UseWide", linkageName: "_CUseWide.Main", scope: null, file: !4, line: 8, type: !9, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !20 = !DILocation(line: 9, column: 3, scope: !17)
// CHECK:STDOUT: !22 = !DILocation(line: 10, column: 3, scope: !17)
// CHECK:STDOUT: !23 = !DILocation(line: 11, column: 3, scope: !17)
// CHECK:STDOUT: !24 = !DILocation(line: 12, column: 10, scope: !17)
// CHECK:STDOUT: !25 = !DILocation(line: 12, column: 3, scope: !17)
// CHECK:STDOUT: !26 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 9, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !29)
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 1, scope: !26, type: !6)
// CHECK:STDOUT: !28 = !DILocation(line: 9, column: 3, scope: !26)
// CHECK:STDOUT: !29 = !{!27}
// CHECK:STDOUT: !30 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !4, line: 9, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !33)
// CHECK:STDOUT: !31 = !DILocalVariable(arg: 1, scope: !30, type: !7)
// CHECK:STDOUT: !32 = !DILocation(line: 9, column: 3, scope: !30)
// CHECK:STDOUT: !33 = !{!31}
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.54e625b7123b91de:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !37)
// CHECK:STDOUT: !35 = !DILocalVariable(arg: 1, scope: !34, type: !14)
// CHECK:STDOUT: !36 = !DILocation(line: 9, column: 3, scope: !34)
// CHECK:STDOUT: !37 = !{!35}
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.54e625b7123b91de:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !41)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !38, type: !14)
// CHECK:STDOUT: !40 = !DILocation(line: 9, column: 3, scope: !38)
// CHECK:STDOUT: !41 = !{!39}
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.90d5c1783df5d1b7:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !45)
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !42, type: !14)
// CHECK:STDOUT: !44 = !DILocation(line: 9, column: 3, scope: !42)
// CHECK:STDOUT: !45 = !{!43}
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.90d5c1783df5d1b7:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !49)
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !46, type: !14)
// CHECK:STDOUT: !48 = !DILocation(line: 9, column: 3, scope: !46)
// CHECK:STDOUT: !49 = !{!47}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'odd.carbon'
// CHECK:STDOUT: source_filename = "odd.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i16 @_CUseOdd.Main() #0 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %o.var = alloca [4 x i8], align 2, !dbg !63
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %o.var), !dbg !63
// CHECK:STDOUT:   %.loc11_4.b = getelementptr inbounds nuw [4 x i8], ptr %o.var, i32 0, i32 0, !dbg !65
// CHECK:STDOUT:   store i16 3, ptr %.loc11_4.b, align 2, !dbg !65
// CHECK:STDOUT:   %.loc12_11.1.b = getelementptr inbounds nuw [4 x i8], ptr %o.var, i32 0, i32 0, !dbg !66
// CHECK:STDOUT:   %.loc12_11.2 = load i16, ptr %.loc12_11.1.b, align 2, !dbg !66
// CHECK:STDOUT:   call void @"_CSelfDestruct.fba220aae9645a8a:core.Destroy.Core"(ptr %o.var), !dbg !63
// CHECK:STDOUT:   ret i16 %.loc12_11.2, !dbg !67
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %self) #0 !dbg !68 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d57cb32fcf12ec07:core.Destroy.Core"(ptr %self) #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.373ea94d3b995412:core.Destroy.Core"(ptr %self) #0 !dbg !76 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_3.1.array.index = getelementptr inbounds [3 x i8], ptr %self, i32 0, i64 2, !dbg !78
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc10_3.1.array.index), !dbg !78
// CHECK:STDOUT:   %.loc10_3.2.array.index = getelementptr inbounds [3 x i8], ptr %self, i32 0, i64 1, !dbg !78
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc10_3.2.array.index), !dbg !78
// CHECK:STDOUT:   %.loc10_3.3.array.index = getelementptr inbounds [3 x i8], ptr %self, i32 0, i64 0, !dbg !78
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc10_3.3.array.index), !dbg !78
// CHECK:STDOUT:   ret void, !dbg !78
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.373ea94d3b995412:core.Destroy.Core"(ptr %self) #0 !dbg !80 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.373ea94d3b995412:core.Destroy.Core"(ptr %self), !dbg !82
// CHECK:STDOUT:   ret void, !dbg !82
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.1bbe37c54d3faa5a:core.Destroy.Core"(ptr %self) #0 !dbg !84 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !86
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.1bbe37c54d3faa5a:core.Destroy.Core"(ptr %self) #0 !dbg !88 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.1bbe37c54d3faa5a:core.Destroy.Core"(ptr %self), !dbg !90
// CHECK:STDOUT:   ret void, !dbg !90
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.fba220aae9645a8a:core.Destroy.Core"(ptr %self) #0 !dbg !92 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_3.1.c = getelementptr inbounds nuw [4 x i8], ptr %self, i32 0, i32 0, !dbg !94
// CHECK:STDOUT:   call void @"_CSelfDestruct.373ea94d3b995412:core.Destroy.Core"(ptr %.loc10_3.1.c), !dbg !94
// CHECK:STDOUT:   %.loc10_3.2.b = getelementptr inbounds nuw [4 x i8], ptr %self, i32 0, i32 0, !dbg !94
// CHECK:STDOUT:   call void @"_CSelfDestruct.d57cb32fcf12ec07:core.Destroy.Core"(ptr %.loc10_3.2.b), !dbg !94
// CHECK:STDOUT:   %.loc10_3.3.a = getelementptr inbounds nuw [4 x i8], ptr %self, i32 0, i32 0, !dbg !94
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc10_3.3.a), !dbg !94
// CHECK:STDOUT:   ret void, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.fba220aae9645a8a:core.Destroy.Core"(ptr %self) #0 !dbg !96 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.fba220aae9645a8a:core.Destroy.Core"(ptr %self), !dbg !98
// CHECK:STDOUT:   ret void, !dbg !98
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!51}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !15 = !{null, !14}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !50 = !DIFile(filename: "odd.carbon", directory: "")
// CHECK:STDOUT: !51 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !50, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !52 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_signed)
// CHECK:STDOUT: !53 = !DIBasicType(name: "int", size: 16, encoding: DW_ATE_signed)
// CHECK:STDOUT: !54 = !{!53}
// CHECK:STDOUT: !55 = !DISubroutineType(types: !54)
// CHECK:STDOUT: !56 = !{null, !52}
// CHECK:STDOUT: !57 = !DISubroutineType(types: !56)
// CHECK:STDOUT: !58 = !{null, !53}
// CHECK:STDOUT: !59 = !DISubroutineType(types: !58)
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "UseOdd", linkageName: "_CUseOdd.Main", scope: null, file: !50, line: 9, type: !55, spFlags: DISPFlagDefinition, unit: !51)
// CHECK:STDOUT: !63 = !DILocation(line: 10, column: 3, scope: !60)
// CHECK:STDOUT: !65 = !DILocation(line: 11, column: 3, scope: !60)
// CHECK:STDOUT: !66 = !DILocation(line: 12, column: 10, scope: !60)
// CHECK:STDOUT: !67 = !DILocation(line: 12, column: 3, scope: !60)
// CHECK:STDOUT: !68 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.4954785a8b134801:core.Destroy.Core", scope: null, file: !50, line: 10, type: !57, spFlags: DISPFlagDefinition, unit: !51, retainedNodes: !71)
// CHECK:STDOUT: !69 = !DILocalVariable(arg: 1, scope: !68, type: !52)
// CHECK:STDOUT: !70 = !DILocation(line: 10, column: 3, scope: !68)
// CHECK:STDOUT: !71 = !{!69}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d57cb32fcf12ec07:core.Destroy.Core", scope: null, file: !50, line: 10, type: !59, spFlags: DISPFlagDefinition, unit: !51, retainedNodes: !75)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !53)
// CHECK:STDOUT: !74 = !DILocation(line: 10, column: 3, scope: !72)
// CHECK:STDOUT: !75 = !{!73}
// CHECK:STDOUT: !76 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.373ea94d3b995412:core.Destroy.Core", scope: null, file: !50, line: 10, type: !16, spFlags: DISPFlagDefinition, unit: !51, retainedNodes: !79)
// CHECK:STDOUT: !77 = !DILocalVariable(arg: 1, scope: !76, type: !14)
// CHECK:STDOUT: !78 = !DILocation(line: 10, column: 3, scope: !76)
// CHECK:STDOUT: !79 = !{!77}
// CHECK:STDOUT: !80 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.373ea94d3b995412:core.Destroy.Core", scope: null, file: !50, line: 10, type: !16, spFlags: DISPFlagDefinition, unit: !51, retainedNodes: !83)
// CHECK:STDOUT: !81 = !DILocalVariable(arg: 1, scope: !80, type: !14)
// CHECK:STDOUT: !82 = !DILocation(line: 10, column: 3, scope: !80)
// CHECK:STDOUT: !83 = !{!81}
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.1bbe37c54d3faa5a:core.Destroy.Core", scope: null, file: !50, line: 10, type: !16, spFlags: DISPFlagDefinition, unit: !51, retainedNodes: !87)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !84, type: !14)
// CHECK:STDOUT: !86 = !DILocation(line: 10, column: 3, scope: !84)
// CHECK:STDOUT: !87 = !{!85}
// CHECK:STDOUT: !88 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.1bbe37c54d3faa5a:core.Destroy.Core", scope: null, file: !50, line: 10, type: !16, spFlags: DISPFlagDefinition, unit: !51, retainedNodes: !91)
// CHECK:STDOUT: !89 = !DILocalVariable(arg: 1, scope: !88, type: !14)
// CHECK:STDOUT: !90 = !DILocation(line: 10, column: 3, scope: !88)
// CHECK:STDOUT: !91 = !{!89}
// CHECK:STDOUT: !92 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.fba220aae9645a8a:core.Destroy.Core", scope: null, file: !50, line: 10, type: !16, spFlags: DISPFlagDefinition, unit: !51, retainedNodes: !95)
// CHECK:STDOUT: !93 = !DILocalVariable(arg: 1, scope: !92, type: !14)
// CHECK:STDOUT: !94 = !DILocation(line: 10, column: 3, scope: !92)
// CHECK:STDOUT: !95 = !{!93}
// CHECK:STDOUT: !96 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.fba220aae9645a8a:core.Destroy.Core", scope: null, file: !50, line: 10, type: !16, spFlags: DISPFlagDefinition, unit: !51, retainedNodes: !99)
// CHECK:STDOUT: !97 = !DILocalVariable(arg: 1, scope: !96, type: !14)
// CHECK:STDOUT: !98 = !DILocation(line: 10, column: 3, scope: !96)
// CHECK:STDOUT: !99 = !{!97}
// CHECK:STDOUT:

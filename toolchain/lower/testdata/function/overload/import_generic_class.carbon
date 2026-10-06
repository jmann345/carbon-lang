// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/import_generic_class.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/import_generic_class.carbon

// The members of an imported generic class's `overload fn` set lower in the
// importing file once per specific it uses, under the set-relative marker THEN
// the specific fingerprint (`_CAdd:overload0.Box.Main.<16 hex>` and
// `_CAdd:overload1.Box.Main.<16 hex>`, as in generic_class.carbon for the
// declaring file): two `define`s for `Box(i64)`, and `Use` calls each once.

// --- lib.carbon

library "[[@TEST_NAME]]";

class Box(T: Core.Copy) {
  var tag: T;
  var total: i32;
  fn Make(x: i32, t: T) -> Box(T) { return {.tag = t, .total = x}; }
  overload fn Add(ref self, n: i32) { self.total = self.total + n; }
  overload fn Add(ref self, b: bool) { if (b) { self.total = self.total + 100; } }
  fn Get(self) -> i32 { return self.total; }
}

// --- use.carbon

library "[[@TEST_NAME]]";

import library "lib";

fn Use() -> i32 {
  var b: Box(i64) = Box(i64).Make(1, 0 as i64);
  b.Add(1);
  b.Add(true);
  return b.Get();
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'lib.carbon'
// CHECK:STDOUT: source_filename = "lib.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "lib.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'use.carbon'
// CHECK:STDOUT: source_filename = "use.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %b.var = alloca { i64, i32 }, align 8, !dbg !22
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !22
// CHECK:STDOUT:   call void @_CMake.Box.Main.5d388d3559e392d2(ptr %b.var, i32 1, i64 0), !dbg !23
// CHECK:STDOUT:   call void @"_CAdd:overload0.Box.Main.5d388d3559e392d2"(ptr %b.var, i32 1), !dbg !27
// CHECK:STDOUT:   call void @"_CAdd:overload1.Box.Main.5d388d3559e392d2"(ptr %b.var, i1 true), !dbg !30
// CHECK:STDOUT:   %Box.Get.call = call i32 @_CGet.Box.Main.5d388d3559e392d2(ptr %b.var), !dbg !33
// CHECK:STDOUT:   call void @"_CSelfDestruct.ecf3725c69d76d5c:core.Destroy.Core"(ptr %b.var), !dbg !22
// CHECK:STDOUT:   ret i32 %Box.Get.call, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.f3f5880296416fc9:core.Destroy.Core"(ptr %self) #0 !dbg !45 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_3.1.total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !47
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc7_3.1.total), !dbg !47
// CHECK:STDOUT:   %.loc7_3.2.tag = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 0, !dbg !47
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.loc7_3.2.tag), !dbg !47
// CHECK:STDOUT:   ret void, !dbg !47
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f3f5880296416fc9:core.Destroy.Core"(ptr %self) #0 !dbg !49 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.f3f5880296416fc9:core.Destroy.Core"(ptr %self), !dbg !51
// CHECK:STDOUT:   ret void, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.ecf3725c69d76d5c:core.Destroy.Core"(ptr %self) #0 !dbg !53 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_3.1.total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !55
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc7_3.1.total), !dbg !55
// CHECK:STDOUT:   %.loc7_3.2.tag = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 0, !dbg !55
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.loc7_3.2.tag), !dbg !55
// CHECK:STDOUT:   ret void, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.ecf3725c69d76d5c:core.Destroy.Core"(ptr %self) #0 !dbg !57 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.ecf3725c69d76d5c:core.Destroy.Core"(ptr %self), !dbg !59
// CHECK:STDOUT:   ret void, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CMake.Box.Main.5d388d3559e392d2(ptr sret({ i64, i32 }) %return, i32 %x, i64 %t) #0 !dbg !61 {
// CHECK:STDOUT:   %tag = getelementptr inbounds nuw { i64, i32 }, ptr %return, i32 0, i32 0, !dbg !70
// CHECK:STDOUT:   store i64 %t, ptr %tag, align 8, !dbg !70
// CHECK:STDOUT:   %total = getelementptr inbounds nuw { i64, i32 }, ptr %return, i32 0, i32 1, !dbg !70
// CHECK:STDOUT:   store i32 %x, ptr %total, align 4, !dbg !70
// CHECK:STDOUT:   ret void, !dbg !71
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CAdd:overload0.Box.Main.5d388d3559e392d2"(ptr %self, i32 %n) #0 !dbg !73 {
// CHECK:STDOUT:   %total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !78
// CHECK:STDOUT:   %total1 = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !79
// CHECK:STDOUT:   %1 = load i32, ptr %total1, align 4, !dbg !79
// CHECK:STDOUT:   %2 = add i32 %1, %n, !dbg !79
// CHECK:STDOUT:   store i32 %2, ptr %total, align 4, !dbg !78
// CHECK:STDOUT:   ret void, !dbg !81
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CAdd:overload1.Box.Main.5d388d3559e392d2"(ptr %self, i1 %b) #0 !dbg !83 {
// CHECK:STDOUT:   br i1 %b, label %1, label %4, !dbg !89
// CHECK:STDOUT:
// CHECK:STDOUT: 1:                                                ; preds = %0
// CHECK:STDOUT:   %total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !90
// CHECK:STDOUT:   %total1 = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !91
// CHECK:STDOUT:   %2 = load i32, ptr %total1, align 4, !dbg !91
// CHECK:STDOUT:   %3 = add i32 %2, 100, !dbg !91
// CHECK:STDOUT:   store i32 %3, ptr %total, align 4, !dbg !90
// CHECK:STDOUT:   br label %4, !dbg !92
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %1, %0
// CHECK:STDOUT:   ret void, !dbg !93
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Box.Main.5d388d3559e392d2(ptr %self) #0 !dbg !95 {
// CHECK:STDOUT:   %total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !100
// CHECK:STDOUT:   %1 = load i32, ptr %total, align 4, !dbg !100
// CHECK:STDOUT:   ret i32 %1, !dbg !101
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!8}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "lib.carbon", directory: "")
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIFile(filename: "use.carbon", directory: "")
// CHECK:STDOUT: !8 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !7, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !9 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !10 = !{!6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !9}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{null, !6}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !16 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !17 = !{null, !16}
// CHECK:STDOUT: !18 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !7, line: 6, type: !11, spFlags: DISPFlagDefinition, unit: !8)
// CHECK:STDOUT: !22 = !DILocation(line: 7, column: 3, scope: !19)
// CHECK:STDOUT: !23 = !DILocation(line: 7, column: 21, scope: !19)
// CHECK:STDOUT: !24 = !{!16, !6, !9}
// CHECK:STDOUT: !25 = !DISubroutineType(types: !24)
// CHECK:STDOUT: !27 = !DILocation(line: 8, column: 3, scope: !19)
// CHECK:STDOUT: !28 = !{null, !16, !6}
// CHECK:STDOUT: !29 = !DISubroutineType(types: !28)
// CHECK:STDOUT: !30 = !DILocation(line: 9, column: 3, scope: !19)
// CHECK:STDOUT: !31 = !{null, !16, !16}
// CHECK:STDOUT: !32 = !DISubroutineType(types: !31)
// CHECK:STDOUT: !33 = !DILocation(line: 10, column: 10, scope: !19)
// CHECK:STDOUT: !34 = !{!6, !16}
// CHECK:STDOUT: !35 = !DISubroutineType(types: !34)
// CHECK:STDOUT: !36 = !DILocation(line: 10, column: 3, scope: !19)
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !7, line: 7, type: !13, spFlags: DISPFlagDefinition, unit: !8, retainedNodes: !40)
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !37, type: !9)
// CHECK:STDOUT: !39 = !DILocation(line: 7, column: 3, scope: !37)
// CHECK:STDOUT: !40 = !{!38}
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !7, line: 7, type: !15, spFlags: DISPFlagDefinition, unit: !8, retainedNodes: !44)
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !41, type: !6)
// CHECK:STDOUT: !43 = !DILocation(line: 7, column: 3, scope: !41)
// CHECK:STDOUT: !44 = !{!42}
// CHECK:STDOUT: !45 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.f3f5880296416fc9:core.Destroy.Core", scope: null, file: !7, line: 7, type: !18, spFlags: DISPFlagDefinition, unit: !8, retainedNodes: !48)
// CHECK:STDOUT: !46 = !DILocalVariable(arg: 1, scope: !45, type: !16)
// CHECK:STDOUT: !47 = !DILocation(line: 7, column: 3, scope: !45)
// CHECK:STDOUT: !48 = !{!46}
// CHECK:STDOUT: !49 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f3f5880296416fc9:core.Destroy.Core", scope: null, file: !7, line: 7, type: !18, spFlags: DISPFlagDefinition, unit: !8, retainedNodes: !52)
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !49, type: !16)
// CHECK:STDOUT: !51 = !DILocation(line: 7, column: 3, scope: !49)
// CHECK:STDOUT: !52 = !{!50}
// CHECK:STDOUT: !53 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.ecf3725c69d76d5c:core.Destroy.Core", scope: null, file: !7, line: 7, type: !18, spFlags: DISPFlagDefinition, unit: !8, retainedNodes: !56)
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !53, type: !16)
// CHECK:STDOUT: !55 = !DILocation(line: 7, column: 3, scope: !53)
// CHECK:STDOUT: !56 = !{!54}
// CHECK:STDOUT: !57 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.ecf3725c69d76d5c:core.Destroy.Core", scope: null, file: !7, line: 7, type: !18, spFlags: DISPFlagDefinition, unit: !8, retainedNodes: !60)
// CHECK:STDOUT: !58 = !DILocalVariable(arg: 1, scope: !57, type: !16)
// CHECK:STDOUT: !59 = !DILocation(line: 7, column: 3, scope: !57)
// CHECK:STDOUT: !60 = !{!58}
// CHECK:STDOUT: !61 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.Box.Main.5d388d3559e392d2", scope: null, file: !4, line: 7, type: !25, spFlags: DISPFlagDefinition, unit: !8, retainedNodes: !72)
// CHECK:STDOUT: !62 = !DILocalVariable(arg: 1, scope: !61, type: !6)
// CHECK:STDOUT: !63 = !DILocalVariable(arg: 2, scope: !61, type: !9)
// CHECK:STDOUT: !70 = !DILocation(line: 7, column: 44, scope: !61)
// CHECK:STDOUT: !71 = !DILocation(line: 7, column: 37, scope: !61)
// CHECK:STDOUT: !72 = !{!62, !63}
// CHECK:STDOUT: !73 = distinct !DISubprogram(name: "Add", linkageName: "_CAdd:overload0.Box.Main.5d388d3559e392d2", scope: null, file: !4, line: 8, type: !29, spFlags: DISPFlagDefinition, unit: !8, retainedNodes: !82)
// CHECK:STDOUT: !74 = !DILocalVariable(arg: 1, scope: !73, type: !16)
// CHECK:STDOUT: !75 = !DILocalVariable(arg: 2, scope: !73, type: !6)
// CHECK:STDOUT: !78 = !DILocation(line: 8, column: 39, scope: !73)
// CHECK:STDOUT: !79 = !DILocation(line: 8, column: 52, scope: !73)
// CHECK:STDOUT: !81 = !DILocation(line: 8, column: 3, scope: !73)
// CHECK:STDOUT: !82 = !{!74, !75}
// CHECK:STDOUT: !83 = distinct !DISubprogram(name: "Add", linkageName: "_CAdd:overload1.Box.Main.5d388d3559e392d2", scope: null, file: !4, line: 9, type: !32, spFlags: DISPFlagDefinition, unit: !8, retainedNodes: !94)
// CHECK:STDOUT: !84 = !DILocalVariable(arg: 1, scope: !83, type: !16)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 2, scope: !83, type: !16)
// CHECK:STDOUT: !89 = !DILocation(line: 9, column: 43, scope: !83)
// CHECK:STDOUT: !90 = !DILocation(line: 9, column: 49, scope: !83)
// CHECK:STDOUT: !91 = !DILocation(line: 9, column: 62, scope: !83)
// CHECK:STDOUT: !92 = !DILocation(line: 9, column: 40, scope: !83)
// CHECK:STDOUT: !93 = !DILocation(line: 9, column: 3, scope: !83)
// CHECK:STDOUT: !94 = !{!84, !85}
// CHECK:STDOUT: !95 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Box.Main.5d388d3559e392d2", scope: null, file: !4, line: 10, type: !35, spFlags: DISPFlagDefinition, unit: !8, retainedNodes: !102)
// CHECK:STDOUT: !96 = !DILocalVariable(arg: 1, scope: !95, type: !16)
// CHECK:STDOUT: !100 = !DILocation(line: 10, column: 32, scope: !95)
// CHECK:STDOUT: !101 = !DILocation(line: 10, column: 25, scope: !95)
// CHECK:STDOUT: !102 = !{!96}
// CHECK:STDOUT:

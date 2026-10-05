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
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "lib.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'use.carbon'
// CHECK:STDOUT: source_filename = "use.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %b.var = alloca { i64, i32 }, align 8, !dbg !8
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !8
// CHECK:STDOUT:   call void @_CMake.Box.Main.5d388d3559e392d2(ptr %b.var, i32 1, i64 0), !dbg !9
// CHECK:STDOUT:   call void @"_CAdd:overload0.Box.Main.5d388d3559e392d2"(ptr %b.var, i32 1), !dbg !10
// CHECK:STDOUT:   call void @"_CAdd:overload1.Box.Main.5d388d3559e392d2"(ptr %b.var, i1 true), !dbg !11
// CHECK:STDOUT:   %Box.Get.call = call i32 @_CGet.Box.Main.5d388d3559e392d2(ptr %b.var), !dbg !12
// CHECK:STDOUT:   call void @"_COp.453d8528e360c9b1:core.Destroy.Core"(ptr %b.var), !dbg !8
// CHECK:STDOUT:   ret i32 %Box.Get.call, !dbg !13
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5f42013854821c52:core.Destroy.Core"(ptr %self) #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !20
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !21 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.54927c19f42fd0e9:core.Destroy.Core"(ptr %self) #0 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.453d8528e360c9b1:core.Destroy.Core"(ptr %self) #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !37
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CMake.Box.Main.5d388d3559e392d2(ptr sret({ i64, i32 }) %return, i32 %x, i64 %t) #0 !dbg !38 {
// CHECK:STDOUT:   %tag = getelementptr inbounds nuw { i64, i32 }, ptr %return, i32 0, i32 0, !dbg !45
// CHECK:STDOUT:   store i64 %t, ptr %tag, align 8, !dbg !45
// CHECK:STDOUT:   %total = getelementptr inbounds nuw { i64, i32 }, ptr %return, i32 0, i32 1, !dbg !45
// CHECK:STDOUT:   store i32 %x, ptr %total, align 4, !dbg !45
// CHECK:STDOUT:   ret void, !dbg !46
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CAdd:overload0.Box.Main.5d388d3559e392d2"(ptr %self, i32 %n) #0 !dbg !47 {
// CHECK:STDOUT:   %total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !53
// CHECK:STDOUT:   %total1 = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !54
// CHECK:STDOUT:   %1 = load i32, ptr %total1, align 4, !dbg !54
// CHECK:STDOUT:   %2 = add i32 %1, %n, !dbg !54
// CHECK:STDOUT:   store i32 %2, ptr %total, align 4, !dbg !53
// CHECK:STDOUT:   ret void, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CAdd:overload1.Box.Main.5d388d3559e392d2"(ptr %self, i1 %b) #0 !dbg !56 {
// CHECK:STDOUT:   br i1 %b, label %1, label %4, !dbg !62
// CHECK:STDOUT:
// CHECK:STDOUT: 1:                                                ; preds = %0
// CHECK:STDOUT:   %total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !63
// CHECK:STDOUT:   %total1 = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !64
// CHECK:STDOUT:   %2 = load i32, ptr %total1, align 4, !dbg !64
// CHECK:STDOUT:   %3 = add i32 %2, 100, !dbg !64
// CHECK:STDOUT:   store i32 %3, ptr %total, align 4, !dbg !63
// CHECK:STDOUT:   br label %4, !dbg !65
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %1, %0
// CHECK:STDOUT:   ret void, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Box.Main.5d388d3559e392d2(ptr %self) #0 !dbg !67 {
// CHECK:STDOUT:   %total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !72
// CHECK:STDOUT:   %1 = load i32, ptr %total, align 4, !dbg !72
// CHECK:STDOUT:   ret i32 %1, !dbg !73
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "use.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 6, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 7, column: 3, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 7, column: 21, scope: !4)
// CHECK:STDOUT: !10 = !DILocation(line: 8, column: 3, scope: !4)
// CHECK:STDOUT: !11 = !DILocation(line: 9, column: 3, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 10, column: 10, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 10, column: 3, scope: !4)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5f42013854821c52:core.Destroy.Core", scope: null, file: !1, line: 7, type: !15, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !18)
// CHECK:STDOUT: !15 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !16 = !{null, !17}
// CHECK:STDOUT: !17 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !18 = !{!19}
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 1, scope: !14, type: !17)
// CHECK:STDOUT: !20 = !DILocation(line: 7, column: 3, scope: !14)
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 7, type: !22, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !24)
// CHECK:STDOUT: !22 = !DISubroutineType(types: !23)
// CHECK:STDOUT: !23 = !{null, !7}
// CHECK:STDOUT: !24 = !{!25}
// CHECK:STDOUT: !25 = !DILocalVariable(arg: 1, scope: !21, type: !7)
// CHECK:STDOUT: !26 = !DILocation(line: 7, column: 3, scope: !21)
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "Op", linkageName: "_COp.54927c19f42fd0e9:core.Destroy.Core", scope: null, file: !1, line: 7, type: !28, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !31)
// CHECK:STDOUT: !28 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !29 = !{null, !30}
// CHECK:STDOUT: !30 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !31 = !{!32}
// CHECK:STDOUT: !32 = !DILocalVariable(arg: 1, scope: !27, type: !30)
// CHECK:STDOUT: !33 = !DILocation(line: 7, column: 3, scope: !27)
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "Op", linkageName: "_COp.453d8528e360c9b1:core.Destroy.Core", scope: null, file: !1, line: 7, type: !28, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !35)
// CHECK:STDOUT: !35 = !{!36}
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !34, type: !30)
// CHECK:STDOUT: !37 = !DILocation(line: 7, column: 3, scope: !34)
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.Box.Main.5d388d3559e392d2", scope: null, file: !39, line: 7, type: !40, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !42)
// CHECK:STDOUT: !39 = !DIFile(filename: "lib.carbon", directory: "")
// CHECK:STDOUT: !40 = !DISubroutineType(types: !41)
// CHECK:STDOUT: !41 = !{!30, !7, !17}
// CHECK:STDOUT: !42 = !{!43, !44}
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !38, type: !7)
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 2, scope: !38, type: !17)
// CHECK:STDOUT: !45 = !DILocation(line: 7, column: 44, scope: !38)
// CHECK:STDOUT: !46 = !DILocation(line: 7, column: 37, scope: !38)
// CHECK:STDOUT: !47 = distinct !DISubprogram(name: "Add", linkageName: "_CAdd:overload0.Box.Main.5d388d3559e392d2", scope: null, file: !39, line: 8, type: !48, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !50)
// CHECK:STDOUT: !48 = !DISubroutineType(types: !49)
// CHECK:STDOUT: !49 = !{null, !30, !7}
// CHECK:STDOUT: !50 = !{!51, !52}
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 1, scope: !47, type: !30)
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 2, scope: !47, type: !7)
// CHECK:STDOUT: !53 = !DILocation(line: 8, column: 39, scope: !47)
// CHECK:STDOUT: !54 = !DILocation(line: 8, column: 52, scope: !47)
// CHECK:STDOUT: !55 = !DILocation(line: 8, column: 3, scope: !47)
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "Add", linkageName: "_CAdd:overload1.Box.Main.5d388d3559e392d2", scope: null, file: !39, line: 9, type: !57, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !59)
// CHECK:STDOUT: !57 = !DISubroutineType(types: !58)
// CHECK:STDOUT: !58 = !{null, !30, !30}
// CHECK:STDOUT: !59 = !{!60, !61}
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !56, type: !30)
// CHECK:STDOUT: !61 = !DILocalVariable(arg: 2, scope: !56, type: !30)
// CHECK:STDOUT: !62 = !DILocation(line: 9, column: 43, scope: !56)
// CHECK:STDOUT: !63 = !DILocation(line: 9, column: 49, scope: !56)
// CHECK:STDOUT: !64 = !DILocation(line: 9, column: 62, scope: !56)
// CHECK:STDOUT: !65 = !DILocation(line: 9, column: 40, scope: !56)
// CHECK:STDOUT: !66 = !DILocation(line: 9, column: 3, scope: !56)
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Box.Main.5d388d3559e392d2", scope: null, file: !39, line: 10, type: !68, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !70)
// CHECK:STDOUT: !68 = !DISubroutineType(types: !69)
// CHECK:STDOUT: !69 = !{!7, !30}
// CHECK:STDOUT: !70 = !{!71}
// CHECK:STDOUT: !71 = !DILocalVariable(arg: 1, scope: !67, type: !30)
// CHECK:STDOUT: !72 = !DILocation(line: 10, column: 32, scope: !67)
// CHECK:STDOUT: !73 = !DILocation(line: 10, column: 25, scope: !67)
// CHECK:STDOUT:

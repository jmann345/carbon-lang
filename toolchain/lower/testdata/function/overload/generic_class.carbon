// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/generic_class.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/generic_class.carbon

// The members of an `overload fn` set declared in a generic class lower once
// per specific of the class, each under the set-relative marker THEN the
// specific fingerprint (`_CAdd:overload0.Box.Main.<16 hex>` and
// `_CAdd:overload1.Box.Main.<16 hex>`, the mangler's marker-before-specific
// order) — two `define`s per specific, and `Use` calls each once.

// --- generic_class.carbon

library "[[@TEST_NAME]]";

class Box(T: Core.Copy) {
  var tag: T;
  var total: i32;
  fn Make(x: i32, t: T) -> Box(T) { return {.tag = t, .total = x}; }
  overload fn Add(ref self, n: i32) { self.total = self.total + n; }
  overload fn Add(ref self, b: bool) { if (b) { self.total = self.total + 100; } }
  fn Get(self) -> i32 { return self.total; }
}

fn Use() -> i32 {
  var b: Box(i64) = Box(i64).Make(1, 0 as i64);
  b.Add(1);
  b.Add(true);
  return b.Get();
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'generic_class.carbon'
// CHECK:STDOUT: source_filename = "generic_class.carbon"
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
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_65.2.tag = getelementptr inbounds nuw { i64, i32 }, ptr %return, i32 0, i32 0, !dbg !44
// CHECK:STDOUT:   store i64 %t, ptr %.loc7_65.2.tag, align 8, !dbg !44
// CHECK:STDOUT:   %.loc7_65.4.total = getelementptr inbounds nuw { i64, i32 }, ptr %return, i32 0, i32 1, !dbg !44
// CHECK:STDOUT:   store i32 %x, ptr %.loc7_65.4.total, align 4, !dbg !44
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CAdd:overload0.Box.Main.5d388d3559e392d2"(ptr %self, i32 %n) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8_43.total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !52
// CHECK:STDOUT:   %.loc8_56.1.total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !53
// CHECK:STDOUT:   %.loc8_56.2 = load i32, ptr %.loc8_56.1.total, align 4, !dbg !53
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc8_56.2, %n, !dbg !53
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %.loc8_43.total, align 4, !dbg !52
// CHECK:STDOUT:   ret void, !dbg !54
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CAdd:overload1.Box.Main.5d388d3559e392d2"(ptr %self, i1 %b) #0 !dbg !55 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 %b, label %if.then, label %if.else, !dbg !61
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %.loc9_53.total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !62
// CHECK:STDOUT:   %.loc9_66.1.total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !63
// CHECK:STDOUT:   %.loc9_66.2 = load i32, ptr %.loc9_66.1.total, align 4, !dbg !63
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc9_66.2, 100, !dbg !63
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %.loc9_53.total, align 4, !dbg !62
// CHECK:STDOUT:   br label %if.else, !dbg !64
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %if.then, %entry
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Box.Main.5d388d3559e392d2(ptr %self) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_36.1.total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !71
// CHECK:STDOUT:   %.loc10_36.2 = load i32, ptr %.loc10_36.1.total, align 4, !dbg !71
// CHECK:STDOUT:   ret i32 %.loc10_36.2, !dbg !72
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "generic_class.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 13, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 14, column: 3, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 14, column: 21, scope: !4)
// CHECK:STDOUT: !10 = !DILocation(line: 15, column: 3, scope: !4)
// CHECK:STDOUT: !11 = !DILocation(line: 16, column: 3, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 17, column: 10, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 17, column: 3, scope: !4)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5f42013854821c52:core.Destroy.Core", scope: null, file: !1, line: 14, type: !15, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !18)
// CHECK:STDOUT: !15 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !16 = !{null, !17}
// CHECK:STDOUT: !17 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !18 = !{!19}
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 1, scope: !14, type: !17)
// CHECK:STDOUT: !20 = !DILocation(line: 14, column: 3, scope: !14)
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 14, type: !22, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !24)
// CHECK:STDOUT: !22 = !DISubroutineType(types: !23)
// CHECK:STDOUT: !23 = !{null, !7}
// CHECK:STDOUT: !24 = !{!25}
// CHECK:STDOUT: !25 = !DILocalVariable(arg: 1, scope: !21, type: !7)
// CHECK:STDOUT: !26 = !DILocation(line: 14, column: 3, scope: !21)
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "Op", linkageName: "_COp.54927c19f42fd0e9:core.Destroy.Core", scope: null, file: !1, line: 14, type: !28, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !31)
// CHECK:STDOUT: !28 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !29 = !{null, !30}
// CHECK:STDOUT: !30 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !31 = !{!32}
// CHECK:STDOUT: !32 = !DILocalVariable(arg: 1, scope: !27, type: !30)
// CHECK:STDOUT: !33 = !DILocation(line: 14, column: 3, scope: !27)
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "Op", linkageName: "_COp.453d8528e360c9b1:core.Destroy.Core", scope: null, file: !1, line: 14, type: !28, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !35)
// CHECK:STDOUT: !35 = !{!36}
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !34, type: !30)
// CHECK:STDOUT: !37 = !DILocation(line: 14, column: 3, scope: !34)
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.Box.Main.5d388d3559e392d2", scope: null, file: !1, line: 7, type: !39, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !41)
// CHECK:STDOUT: !39 = !DISubroutineType(types: !40)
// CHECK:STDOUT: !40 = !{!30, !7, !17}
// CHECK:STDOUT: !41 = !{!42, !43}
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !38, type: !7)
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 2, scope: !38, type: !17)
// CHECK:STDOUT: !44 = !DILocation(line: 7, column: 44, scope: !38)
// CHECK:STDOUT: !45 = !DILocation(line: 7, column: 37, scope: !38)
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "Add", linkageName: "_CAdd:overload0.Box.Main.5d388d3559e392d2", scope: null, file: !1, line: 8, type: !47, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !49)
// CHECK:STDOUT: !47 = !DISubroutineType(types: !48)
// CHECK:STDOUT: !48 = !{null, !30, !7}
// CHECK:STDOUT: !49 = !{!50, !51}
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !46, type: !30)
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 2, scope: !46, type: !7)
// CHECK:STDOUT: !52 = !DILocation(line: 8, column: 39, scope: !46)
// CHECK:STDOUT: !53 = !DILocation(line: 8, column: 52, scope: !46)
// CHECK:STDOUT: !54 = !DILocation(line: 8, column: 3, scope: !46)
// CHECK:STDOUT: !55 = distinct !DISubprogram(name: "Add", linkageName: "_CAdd:overload1.Box.Main.5d388d3559e392d2", scope: null, file: !1, line: 9, type: !56, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !58)
// CHECK:STDOUT: !56 = !DISubroutineType(types: !57)
// CHECK:STDOUT: !57 = !{null, !30, !30}
// CHECK:STDOUT: !58 = !{!59, !60}
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !55, type: !30)
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 2, scope: !55, type: !30)
// CHECK:STDOUT: !61 = !DILocation(line: 9, column: 43, scope: !55)
// CHECK:STDOUT: !62 = !DILocation(line: 9, column: 49, scope: !55)
// CHECK:STDOUT: !63 = !DILocation(line: 9, column: 62, scope: !55)
// CHECK:STDOUT: !64 = !DILocation(line: 9, column: 40, scope: !55)
// CHECK:STDOUT: !65 = !DILocation(line: 9, column: 3, scope: !55)
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Box.Main.5d388d3559e392d2", scope: null, file: !1, line: 10, type: !67, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !69)
// CHECK:STDOUT: !67 = !DISubroutineType(types: !68)
// CHECK:STDOUT: !68 = !{!7, !30}
// CHECK:STDOUT: !69 = !{!70}
// CHECK:STDOUT: !70 = !DILocalVariable(arg: 1, scope: !66, type: !30)
// CHECK:STDOUT: !71 = !DILocation(line: 10, column: 32, scope: !66)
// CHECK:STDOUT: !72 = !DILocation(line: 10, column: 25, scope: !66)
// CHECK:STDOUT:

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
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %b.var = alloca { i64, i32 }, align 8, !dbg !20
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !20
// CHECK:STDOUT:   call void @_CMake.Box.Main.5d388d3559e392d2(ptr %b.var, i32 1, i64 0), !dbg !21
// CHECK:STDOUT:   call void @"_CAdd:overload0.Box.Main.5d388d3559e392d2"(ptr %b.var, i32 1), !dbg !25
// CHECK:STDOUT:   call void @"_CAdd:overload1.Box.Main.5d388d3559e392d2"(ptr %b.var, i1 true), !dbg !28
// CHECK:STDOUT:   %Box.Get.call = call i32 @_CGet.Box.Main.5d388d3559e392d2(ptr %b.var), !dbg !31
// CHECK:STDOUT:   call void @"_CSelfDestruct.ecf3725c69d76d5c:core.Destroy.Core"(ptr %b.var), !dbg !20
// CHECK:STDOUT:   ret i32 %Box.Get.call, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !37
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.f3f5880296416fc9:core.Destroy.Core"(ptr %self) #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14_3.1.total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !45
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc14_3.1.total), !dbg !45
// CHECK:STDOUT:   %.loc14_3.2.tag = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 0, !dbg !45
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.loc14_3.2.tag), !dbg !45
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f3f5880296416fc9:core.Destroy.Core"(ptr %self) #0 !dbg !47 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.f3f5880296416fc9:core.Destroy.Core"(ptr %self), !dbg !49
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.ecf3725c69d76d5c:core.Destroy.Core"(ptr %self) #0 !dbg !51 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14_3.1.total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !53
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc14_3.1.total), !dbg !53
// CHECK:STDOUT:   %.loc14_3.2.tag = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 0, !dbg !53
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.loc14_3.2.tag), !dbg !53
// CHECK:STDOUT:   ret void, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.ecf3725c69d76d5c:core.Destroy.Core"(ptr %self) #0 !dbg !55 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.ecf3725c69d76d5c:core.Destroy.Core"(ptr %self), !dbg !57
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CMake.Box.Main.5d388d3559e392d2(ptr sret({ i64, i32 }) %return, i32 %x, i64 %t) #0 !dbg !59 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_65.2.tag = getelementptr inbounds nuw { i64, i32 }, ptr %return, i32 0, i32 0, !dbg !68
// CHECK:STDOUT:   store i64 %t, ptr %.loc7_65.2.tag, align 8, !dbg !68
// CHECK:STDOUT:   %.loc7_65.4.total = getelementptr inbounds nuw { i64, i32 }, ptr %return, i32 0, i32 1, !dbg !68
// CHECK:STDOUT:   store i32 %x, ptr %.loc7_65.4.total, align 4, !dbg !68
// CHECK:STDOUT:   ret void, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CAdd:overload0.Box.Main.5d388d3559e392d2"(ptr %self, i32 %n) #0 !dbg !71 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8_43.total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !76
// CHECK:STDOUT:   %.loc8_56.1.total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !77
// CHECK:STDOUT:   %.loc8_56.2 = load i32, ptr %.loc8_56.1.total, align 4, !dbg !77
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc8_56.2, %n, !dbg !77
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %.loc8_43.total, align 4, !dbg !76
// CHECK:STDOUT:   ret void, !dbg !79
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CAdd:overload1.Box.Main.5d388d3559e392d2"(ptr %self, i1 %b) #0 !dbg !81 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 %b, label %if.then, label %if.else, !dbg !87
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %.loc9_53.total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !88
// CHECK:STDOUT:   %.loc9_66.1.total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !89
// CHECK:STDOUT:   %.loc9_66.2 = load i32, ptr %.loc9_66.1.total, align 4, !dbg !89
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc9_66.2, 100, !dbg !89
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %.loc9_53.total, align 4, !dbg !88
// CHECK:STDOUT:   br label %if.else, !dbg !90
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %if.then, %entry
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Box.Main.5d388d3559e392d2(ptr %self) #0 !dbg !93 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_36.1.total = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !98
// CHECK:STDOUT:   %.loc10_36.2 = load i32, ptr %.loc10_36.1.total, align 4, !dbg !98
// CHECK:STDOUT:   ret i32 %.loc10_36.2, !dbg !99
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "generic_class.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{!6}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{null, !7}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !15 = !{null, !14}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !4, line: 13, type: !9, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !20 = !DILocation(line: 14, column: 3, scope: !17)
// CHECK:STDOUT: !21 = !DILocation(line: 14, column: 21, scope: !17)
// CHECK:STDOUT: !22 = !{!14, !6, !7}
// CHECK:STDOUT: !23 = !DISubroutineType(types: !22)
// CHECK:STDOUT: !25 = !DILocation(line: 15, column: 3, scope: !17)
// CHECK:STDOUT: !26 = !{null, !14, !6}
// CHECK:STDOUT: !27 = !DISubroutineType(types: !26)
// CHECK:STDOUT: !28 = !DILocation(line: 16, column: 3, scope: !17)
// CHECK:STDOUT: !29 = !{null, !14, !14}
// CHECK:STDOUT: !30 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !31 = !DILocation(line: 17, column: 10, scope: !17)
// CHECK:STDOUT: !32 = !{!6, !14}
// CHECK:STDOUT: !33 = !DISubroutineType(types: !32)
// CHECK:STDOUT: !34 = !DILocation(line: 17, column: 3, scope: !17)
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !4, line: 14, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !38)
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !35, type: !7)
// CHECK:STDOUT: !37 = !DILocation(line: 14, column: 3, scope: !35)
// CHECK:STDOUT: !38 = !{!36}
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 14, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !42)
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !39, type: !6)
// CHECK:STDOUT: !41 = !DILocation(line: 14, column: 3, scope: !39)
// CHECK:STDOUT: !42 = !{!40}
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.f3f5880296416fc9:core.Destroy.Core", scope: null, file: !4, line: 14, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !46)
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !43, type: !14)
// CHECK:STDOUT: !45 = !DILocation(line: 14, column: 3, scope: !43)
// CHECK:STDOUT: !46 = !{!44}
// CHECK:STDOUT: !47 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f3f5880296416fc9:core.Destroy.Core", scope: null, file: !4, line: 14, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !50)
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !47, type: !14)
// CHECK:STDOUT: !49 = !DILocation(line: 14, column: 3, scope: !47)
// CHECK:STDOUT: !50 = !{!48}
// CHECK:STDOUT: !51 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.ecf3725c69d76d5c:core.Destroy.Core", scope: null, file: !4, line: 14, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !54)
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !51, type: !14)
// CHECK:STDOUT: !53 = !DILocation(line: 14, column: 3, scope: !51)
// CHECK:STDOUT: !54 = !{!52}
// CHECK:STDOUT: !55 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.ecf3725c69d76d5c:core.Destroy.Core", scope: null, file: !4, line: 14, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !58)
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !55, type: !14)
// CHECK:STDOUT: !57 = !DILocation(line: 14, column: 3, scope: !55)
// CHECK:STDOUT: !58 = !{!56}
// CHECK:STDOUT: !59 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.Box.Main.5d388d3559e392d2", scope: null, file: !4, line: 7, type: !23, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !70)
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !59, type: !6)
// CHECK:STDOUT: !61 = !DILocalVariable(arg: 2, scope: !59, type: !7)
// CHECK:STDOUT: !68 = !DILocation(line: 7, column: 44, scope: !59)
// CHECK:STDOUT: !69 = !DILocation(line: 7, column: 37, scope: !59)
// CHECK:STDOUT: !70 = !{!60, !61}
// CHECK:STDOUT: !71 = distinct !DISubprogram(name: "Add", linkageName: "_CAdd:overload0.Box.Main.5d388d3559e392d2", scope: null, file: !4, line: 8, type: !27, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !80)
// CHECK:STDOUT: !72 = !DILocalVariable(arg: 1, scope: !71, type: !14)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 2, scope: !71, type: !6)
// CHECK:STDOUT: !76 = !DILocation(line: 8, column: 39, scope: !71)
// CHECK:STDOUT: !77 = !DILocation(line: 8, column: 52, scope: !71)
// CHECK:STDOUT: !79 = !DILocation(line: 8, column: 3, scope: !71)
// CHECK:STDOUT: !80 = !{!72, !73}
// CHECK:STDOUT: !81 = distinct !DISubprogram(name: "Add", linkageName: "_CAdd:overload1.Box.Main.5d388d3559e392d2", scope: null, file: !4, line: 9, type: !30, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !92)
// CHECK:STDOUT: !82 = !DILocalVariable(arg: 1, scope: !81, type: !14)
// CHECK:STDOUT: !83 = !DILocalVariable(arg: 2, scope: !81, type: !14)
// CHECK:STDOUT: !87 = !DILocation(line: 9, column: 43, scope: !81)
// CHECK:STDOUT: !88 = !DILocation(line: 9, column: 49, scope: !81)
// CHECK:STDOUT: !89 = !DILocation(line: 9, column: 62, scope: !81)
// CHECK:STDOUT: !90 = !DILocation(line: 9, column: 40, scope: !81)
// CHECK:STDOUT: !91 = !DILocation(line: 9, column: 3, scope: !81)
// CHECK:STDOUT: !92 = !{!82, !83}
// CHECK:STDOUT: !93 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Box.Main.5d388d3559e392d2", scope: null, file: !4, line: 10, type: !33, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !100)
// CHECK:STDOUT: !94 = !DILocalVariable(arg: 1, scope: !93, type: !14)
// CHECK:STDOUT: !98 = !DILocation(line: 10, column: 32, scope: !93)
// CHECK:STDOUT: !99 = !DILocation(line: 10, column: 25, scope: !93)
// CHECK:STDOUT: !100 = !{!94}
// CHECK:STDOUT:

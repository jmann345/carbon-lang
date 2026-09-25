// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/choice/single_payload_alternative.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/choice/single_payload_alternative.carbon

// The single-alternative composed constructor shape (review F-A1): with one
// alternative there are no discriminant bits, so the object representation
// is a zero-bit `()` discriminant plus the payload region, and the
// constructor's only visible store is the payload tuple at byte offset 0.

choice OneShot {
  Only(x: i32)
}

fn Make(n: i32) -> OneShot {
  return OneShot.Only(n);
}

fn Use(n: i32) {
  // Scope exit of a local exercises the destroy path for the payload region.
  // CHECK:STDERR: single_payload_alternative.carbon:[[@LINE+4]]:7: warning: binding `v` unused [UnusedBinding]
  // CHECK:STDERR:   var v: OneShot = Make(n);
  // CHECK:STDERR:       ^~~~~~~~~~
  // CHECK:STDERR:
  var v: OneShot = Make(n);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'single_payload_alternative.carbon'
// CHECK:STDOUT: source_filename = "single_payload_alternative.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_COnly.OneShot.Main(ptr sret({ {}, [4 x i8] }) %return, i32 %_) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc18_16.1.discriminant = getelementptr inbounds nuw { {}, [4 x i8] }, ptr %return, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc18_16.4.payload = getelementptr inbounds nuw { {}, [4 x i8] }, ptr %return, i32 0, i32 1, !dbg !11
// CHECK:STDOUT:   %.loc18_16.5.Only = getelementptr inbounds nuw [4 x i8], ptr %.loc18_16.4.payload, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc20_1.4.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !11
// CHECK:STDOUT:   store { i32 } %.loc20_1.4.tuple.init, ptr %.loc18_16.5.Only, align 4, !dbg !11
// CHECK:STDOUT:   ret void, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMake.Main(ptr sret({ {}, [4 x i8] }) %return, i32 %n) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_COnly.OneShot.Main(ptr %return, i32 %n), !dbg !15
// CHECK:STDOUT:   ret void, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(i32 %n) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.var = alloca { {}, [4 x i8] }, align 4, !dbg !22
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %v.var), !dbg !22
// CHECK:STDOUT:   call void @_CMake.Main(ptr %v.var, i32 %n), !dbg !23
// CHECK:STDOUT:   call void @"_COp.cd3bf14dd17b67dc:core.Destroy.Core"(ptr %v.var), !dbg !22
// CHECK:STDOUT:   ret void, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.216a6481b641f07b:core.Destroy.Core"(ptr %self) #0 !dbg !29 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.f96c250eff2d3ea4:core.Destroy.Core"(ptr %self) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.6bd68929b0ea070a:core.Destroy.Core"(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !42
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.cd3bf14dd17b67dc:core.Destroy.Core"(ptr %self) #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !46
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
// CHECK:STDOUT: !1 = !DIFile(filename: "single_payload_alternative.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Only", linkageName: "_COnly.OneShot.Main", scope: null, file: !1, line: 18, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 18, column: 1, scope: !4)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.Main", scope: null, file: !1, line: 22, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !13)
// CHECK:STDOUT: !13 = !{!14}
// CHECK:STDOUT: !14 = !DILocalVariable(arg: 1, scope: !12, type: !8)
// CHECK:STDOUT: !15 = !DILocation(line: 23, column: 10, scope: !12)
// CHECK:STDOUT: !16 = !DILocation(line: 23, column: 3, scope: !12)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 26, type: !18, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !20)
// CHECK:STDOUT: !18 = !DISubroutineType(types: !19)
// CHECK:STDOUT: !19 = !{null, !8}
// CHECK:STDOUT: !20 = !{!21}
// CHECK:STDOUT: !21 = !DILocalVariable(arg: 1, scope: !17, type: !8)
// CHECK:STDOUT: !22 = !DILocation(line: 32, column: 3, scope: !17)
// CHECK:STDOUT: !23 = !DILocation(line: 32, column: 20, scope: !17)
// CHECK:STDOUT: !24 = !DILocation(line: 26, column: 1, scope: !17)
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 32, type: !18, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
// CHECK:STDOUT: !26 = !{!27}
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 1, scope: !25, type: !8)
// CHECK:STDOUT: !28 = !DILocation(line: 32, column: 3, scope: !25)
// CHECK:STDOUT: !29 = distinct !DISubprogram(name: "Op", linkageName: "_COp.216a6481b641f07b:core.Destroy.Core", scope: null, file: !1, line: 32, type: !30, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !32)
// CHECK:STDOUT: !30 = !DISubroutineType(types: !31)
// CHECK:STDOUT: !31 = !{null, !7}
// CHECK:STDOUT: !32 = !{!33}
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !29, type: !7)
// CHECK:STDOUT: !34 = !DILocation(line: 32, column: 3, scope: !29)
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "Op", linkageName: "_COp.f96c250eff2d3ea4:core.Destroy.Core", scope: null, file: !1, line: 32, type: !30, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !36)
// CHECK:STDOUT: !36 = !{!37}
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !35, type: !7)
// CHECK:STDOUT: !38 = !DILocation(line: 32, column: 3, scope: !35)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "Op", linkageName: "_COp.6bd68929b0ea070a:core.Destroy.Core", scope: null, file: !1, line: 32, type: !30, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !40)
// CHECK:STDOUT: !40 = !{!41}
// CHECK:STDOUT: !41 = !DILocalVariable(arg: 1, scope: !39, type: !7)
// CHECK:STDOUT: !42 = !DILocation(line: 32, column: 3, scope: !39)
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "Op", linkageName: "_COp.cd3bf14dd17b67dc:core.Destroy.Core", scope: null, file: !1, line: 32, type: !30, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !44)
// CHECK:STDOUT: !44 = !{!45}
// CHECK:STDOUT: !45 = !DILocalVariable(arg: 1, scope: !43, type: !7)
// CHECK:STDOUT: !46 = !DILocation(line: 32, column: 3, scope: !43)
// CHECK:STDOUT:

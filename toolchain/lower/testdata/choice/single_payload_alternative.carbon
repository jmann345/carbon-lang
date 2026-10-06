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
// CHECK:STDOUT: define void @_COnly.OneShot.Main(ptr sret({ {}, [4 x i8] }) %return, i32 %_) #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc18_16.1.discriminant = getelementptr inbounds nuw { {}, [4 x i8] }, ptr %return, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   %.loc18_16.4.payload = getelementptr inbounds nuw { {}, [4 x i8] }, ptr %return, i32 0, i32 1, !dbg !16
// CHECK:STDOUT:   %.loc18_16.5.Only = getelementptr inbounds nuw [4 x i8], ptr %.loc18_16.4.payload, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   %.loc20_1.4.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !16
// CHECK:STDOUT:   store { i32 } %.loc20_1.4.tuple.init, ptr %.loc18_16.5.Only, align 4, !dbg !16
// CHECK:STDOUT:   ret void, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMake.Main(ptr sret({ {}, [4 x i8] }) %return, i32 %n) #0 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_COnly.OneShot.Main(ptr %return, i32 %n), !dbg !24
// CHECK:STDOUT:   ret void, !dbg !25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(i32 %n) #0 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.var = alloca { {}, [4 x i8] }, align 4, !dbg !30
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %v.var), !dbg !30
// CHECK:STDOUT:   call void @_CMake.Main(ptr %v.var, i32 %n), !dbg !32
// CHECK:STDOUT:   call void @"_CSelfDestruct.8fdccc310268139d:core.Destroy.Core"(ptr %v.var), !dbg !30
// CHECK:STDOUT:   ret void, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.61ea2aba74ab3bf1:core.Destroy.Core"(ptr %self) #0 !dbg !36 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !40 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !42
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !44 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !46
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !46
// CHECK:STDOUT:   ret void, !dbg !46
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !48 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !50
// CHECK:STDOUT:   ret void, !dbg !50
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e0f13123466858ce:core.Destroy.Core"(ptr %self) #0 !dbg !52 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !54
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e0f13123466858ce:core.Destroy.Core"(ptr %self) #0 !dbg !56 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e0f13123466858ce:core.Destroy.Core"(ptr %self), !dbg !58
// CHECK:STDOUT:   ret void, !dbg !58
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.3341df76f565ecb5:core.Destroy.Core"(ptr %self) #0 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc32_3.1.payload = getelementptr inbounds nuw { {}, [4 x i8] }, ptr %self, i32 0, i32 1, !dbg !62
// CHECK:STDOUT:   call void @"_CSelfDestruct.e0f13123466858ce:core.Destroy.Core"(ptr %.loc32_3.1.payload), !dbg !62
// CHECK:STDOUT:   %.loc32_3.2.discriminant = getelementptr inbounds nuw { {}, [4 x i8] }, ptr %self, i32 0, i32 0, !dbg !62
// CHECK:STDOUT:   call void @"_CSelfDestruct.61ea2aba74ab3bf1:core.Destroy.Core"(ptr %.loc32_3.2.discriminant), !dbg !62
// CHECK:STDOUT:   ret void, !dbg !62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.3341df76f565ecb5:core.Destroy.Core"(ptr %self) #0 !dbg !64 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.3341df76f565ecb5:core.Destroy.Core"(ptr %self), !dbg !66
// CHECK:STDOUT:   ret void, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.8fdccc310268139d:core.Destroy.Core"(ptr %self) #0 !dbg !68 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.8fdccc310268139d:core.Destroy.Core"(ptr %self) #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.8fdccc310268139d:core.Destroy.Core"(ptr %self), !dbg !74
// CHECK:STDOUT:   ret void, !dbg !74
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
// CHECK:STDOUT: !4 = !DIFile(filename: "single_payload_alternative.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !6}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{null, !6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "Only", linkageName: "_COnly.OneShot.Main", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !17)
// CHECK:STDOUT: !15 = !DILocalVariable(arg: 1, scope: !14, type: !6)
// CHECK:STDOUT: !16 = !DILocation(line: 18, column: 1, scope: !14)
// CHECK:STDOUT: !17 = !{!15}
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.Main", scope: null, file: !4, line: 22, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !26)
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 1, scope: !18, type: !6)
// CHECK:STDOUT: !24 = !DILocation(line: 23, column: 10, scope: !18)
// CHECK:STDOUT: !25 = !DILocation(line: 23, column: 3, scope: !18)
// CHECK:STDOUT: !26 = !{!19}
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !4, line: 26, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !35)
// CHECK:STDOUT: !28 = !DILocalVariable(arg: 1, scope: !27, type: !6)
// CHECK:STDOUT: !30 = !DILocation(line: 32, column: 3, scope: !27)
// CHECK:STDOUT: !32 = !DILocation(line: 32, column: 20, scope: !27)
// CHECK:STDOUT: !34 = !DILocation(line: 26, column: 1, scope: !27)
// CHECK:STDOUT: !35 = !{!28}
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.61ea2aba74ab3bf1:core.Destroy.Core", scope: null, file: !4, line: 32, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !39)
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !36, type: !7)
// CHECK:STDOUT: !38 = !DILocation(line: 32, column: 3, scope: !36)
// CHECK:STDOUT: !39 = !{!37}
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 32, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !43)
// CHECK:STDOUT: !41 = !DILocalVariable(arg: 1, scope: !40, type: !6)
// CHECK:STDOUT: !42 = !DILocation(line: 32, column: 3, scope: !40)
// CHECK:STDOUT: !43 = !{!41}
// CHECK:STDOUT: !44 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 32, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !47)
// CHECK:STDOUT: !45 = !DILocalVariable(arg: 1, scope: !44, type: !7)
// CHECK:STDOUT: !46 = !DILocation(line: 32, column: 3, scope: !44)
// CHECK:STDOUT: !47 = !{!45}
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 32, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !51)
// CHECK:STDOUT: !49 = !DILocalVariable(arg: 1, scope: !48, type: !7)
// CHECK:STDOUT: !50 = !DILocation(line: 32, column: 3, scope: !48)
// CHECK:STDOUT: !51 = !{!49}
// CHECK:STDOUT: !52 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e0f13123466858ce:core.Destroy.Core", scope: null, file: !4, line: 32, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !55)
// CHECK:STDOUT: !53 = !DILocalVariable(arg: 1, scope: !52, type: !7)
// CHECK:STDOUT: !54 = !DILocation(line: 32, column: 3, scope: !52)
// CHECK:STDOUT: !55 = !{!53}
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e0f13123466858ce:core.Destroy.Core", scope: null, file: !4, line: 32, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !59)
// CHECK:STDOUT: !57 = !DILocalVariable(arg: 1, scope: !56, type: !7)
// CHECK:STDOUT: !58 = !DILocation(line: 32, column: 3, scope: !56)
// CHECK:STDOUT: !59 = !{!57}
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.3341df76f565ecb5:core.Destroy.Core", scope: null, file: !4, line: 32, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !63)
// CHECK:STDOUT: !61 = !DILocalVariable(arg: 1, scope: !60, type: !7)
// CHECK:STDOUT: !62 = !DILocation(line: 32, column: 3, scope: !60)
// CHECK:STDOUT: !63 = !{!61}
// CHECK:STDOUT: !64 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.3341df76f565ecb5:core.Destroy.Core", scope: null, file: !4, line: 32, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !67)
// CHECK:STDOUT: !65 = !DILocalVariable(arg: 1, scope: !64, type: !7)
// CHECK:STDOUT: !66 = !DILocation(line: 32, column: 3, scope: !64)
// CHECK:STDOUT: !67 = !{!65}
// CHECK:STDOUT: !68 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.8fdccc310268139d:core.Destroy.Core", scope: null, file: !4, line: 32, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !71)
// CHECK:STDOUT: !69 = !DILocalVariable(arg: 1, scope: !68, type: !7)
// CHECK:STDOUT: !70 = !DILocation(line: 32, column: 3, scope: !68)
// CHECK:STDOUT: !71 = !{!69}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.8fdccc310268139d:core.Destroy.Core", scope: null, file: !4, line: 32, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !75)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !7)
// CHECK:STDOUT: !74 = !DILocation(line: 32, column: 3, scope: !72)
// CHECK:STDOUT: !75 = !{!73}
// CHECK:STDOUT:

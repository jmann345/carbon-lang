// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --output=%t --output-last-input-only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/choice/generic_payload_imported.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/choice/generic_payload_imported.carbon

// Risk R-4's falsifier as an artifact: the generic choice — and its
// dependent-layout sentinel — is declared in another library, and the
// specific is formed in THIS file, so the layout recompute must fire in the
// importing file: the payload region must lower as the recomputed `[8 x i8]`
// ((i32, i32), align 4). A stale import shows as a wrong region size here.

// --- plib.carbon
library "plib";

choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

// --- use_imported.carbon
library "[[@TEST_NAME]]";

import library "plib";

fn Classify(p: Pair(i32)) -> i32 {
  match (p) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

fn Run() -> i32 {
  let b: Pair(i32) = Pair(i32).Both(1, 2);
  return Classify(b);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'use_imported.carbon'
// CHECK:STDOUT: source_filename = "use_imported.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Pair.val.6e7 = internal constant <{ <{ i1, [3 x i8] }>, [8 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @Pair.val.cf1.anon = internal constant <{ <{ i1, [3 x i8] }>, [8 x i8] }> zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CClassify.Main(ptr %p) #0 !dbg !15 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_19.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %p, i32 0, i32 0, !dbg !21
// CHECK:STDOUT:   %.loc7_19.4 = load i8, ptr %.loc7_19.3.discriminant, align 1, !dbg !21
// CHECK:STDOUT:   %.loc7_19.41 = trunc i8 %.loc7_19.4 to i1, !dbg !21
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc7_19.41, !dbg !21
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !21
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !22
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !23
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc13_41.1.temp = alloca <{ <{ i1, [3 x i8] }>, [8 x i8] }>, align 4, !dbg !28
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc13_41.1.temp), !dbg !28
// CHECK:STDOUT:   call void @_CBoth.Pair.Main.84588f41d61dafba(ptr %.loc13_41.1.temp, i32 1, i32 2), !dbg !28
// CHECK:STDOUT:   %Classify.call = call i32 @_CClassify.Main(ptr %.loc13_41.1.temp), !dbg !34
// CHECK:STDOUT:   call void @"_CSelfDestruct.1eef18dc43ad9a55:core.Destroy.Core"(ptr %.loc13_41.1.temp), !dbg !28
// CHECK:STDOUT:   ret i32 %Classify.call, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !36 {
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
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !44 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !46
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !46
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !46
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !46
// CHECK:STDOUT:   ret void, !dbg !46
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !48 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self), !dbg !50
// CHECK:STDOUT:   ret void, !dbg !50
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.20c1b1147da3b52d:core.Destroy.Core"(ptr %self) #0 !dbg !52 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !54
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.20c1b1147da3b52d:core.Destroy.Core"(ptr %self) #0 !dbg !56 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.20c1b1147da3b52d:core.Destroy.Core"(ptr %self), !dbg !58
// CHECK:STDOUT:   ret void, !dbg !58
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.92cfe67cb2f4b128:core.Destroy.Core"(ptr %self) #0 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc13_41.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !62
// CHECK:STDOUT:   call void @"_CSelfDestruct.20c1b1147da3b52d:core.Destroy.Core"(ptr %.loc13_41.1.payload), !dbg !62
// CHECK:STDOUT:   %.loc13_41.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !62
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc13_41.2.discriminant), !dbg !62
// CHECK:STDOUT:   ret void, !dbg !62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.92cfe67cb2f4b128:core.Destroy.Core"(ptr %self) #0 !dbg !64 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.92cfe67cb2f4b128:core.Destroy.Core"(ptr %self), !dbg !66
// CHECK:STDOUT:   ret void, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.1eef18dc43ad9a55:core.Destroy.Core"(ptr %self) #0 !dbg !68 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.1eef18dc43ad9a55:core.Destroy.Core"(ptr %self) #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.1eef18dc43ad9a55:core.Destroy.Core"(ptr %self), !dbg !74
// CHECK:STDOUT:   ret void, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBoth.Pair.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [8 x i8] }>) %return, i32 %_, i32 %_1) #0 !dbg !77 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !80
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !80
// CHECK:STDOUT:   %Both = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !80
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Pair.val.cf1.anon, i64 12, i1 false), !dbg !80
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %Both, i32 0, i32 0, !dbg !81
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !81
// CHECK:STDOUT:   %tuple.elem2 = getelementptr inbounds nuw { i32, i32 }, ptr %Both, i32 0, i32 1, !dbg !81
// CHECK:STDOUT:   store i32 %_1, ptr %tuple.elem2, align 4, !dbg !81
// CHECK:STDOUT:   ret void, !dbg !80
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!1}
// CHECK:STDOUT: !llvm.module.flags = !{!83, !84}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = !DIFile(filename: "use_imported.carbon", directory: "")
// CHECK:STDOUT: !1 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !0, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !2 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !3 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !4 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !5 = !{!2, !4}
// CHECK:STDOUT: !6 = !DISubroutineType(types: !5)
// CHECK:STDOUT: !7 = !{!2}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !{null, !3}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = !{null, !2}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{null, !4}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = distinct !DISubprogram(name: "Classify", linkageName: "_CClassify.Main", scope: null, file: !0, line: 5, type: !6, spFlags: DISPFlagDefinition, unit: !1, retainedNodes: !24)
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 1, scope: !15, type: !4)
// CHECK:STDOUT: !21 = !DILocation(line: 7, column: 5, scope: !15)
// CHECK:STDOUT: !22 = !DILocation(line: 7, column: 24, scope: !15)
// CHECK:STDOUT: !23 = !DILocation(line: 8, column: 18, scope: !15)
// CHECK:STDOUT: !24 = !{!16}
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !0, line: 12, type: !8, spFlags: DISPFlagDefinition, unit: !1)
// CHECK:STDOUT: !28 = !DILocation(line: 13, column: 22, scope: !25)
// CHECK:STDOUT: !29 = !{!4, !2, !2}
// CHECK:STDOUT: !30 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !34 = !DILocation(line: 14, column: 10, scope: !25)
// CHECK:STDOUT: !35 = !DILocation(line: 14, column: 3, scope: !25)
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !0, line: 13, type: !10, spFlags: DISPFlagDefinition, unit: !1, retainedNodes: !39)
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !36, type: !3)
// CHECK:STDOUT: !38 = !DILocation(line: 13, column: 22, scope: !36)
// CHECK:STDOUT: !39 = !{!37}
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !0, line: 13, type: !12, spFlags: DISPFlagDefinition, unit: !1, retainedNodes: !43)
// CHECK:STDOUT: !41 = !DILocalVariable(arg: 1, scope: !40, type: !2)
// CHECK:STDOUT: !42 = !DILocation(line: 13, column: 22, scope: !40)
// CHECK:STDOUT: !43 = !{!41}
// CHECK:STDOUT: !44 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !0, line: 13, type: !14, spFlags: DISPFlagDefinition, unit: !1, retainedNodes: !47)
// CHECK:STDOUT: !45 = !DILocalVariable(arg: 1, scope: !44, type: !4)
// CHECK:STDOUT: !46 = !DILocation(line: 13, column: 22, scope: !44)
// CHECK:STDOUT: !47 = !{!45}
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !0, line: 13, type: !14, spFlags: DISPFlagDefinition, unit: !1, retainedNodes: !51)
// CHECK:STDOUT: !49 = !DILocalVariable(arg: 1, scope: !48, type: !4)
// CHECK:STDOUT: !50 = !DILocation(line: 13, column: 22, scope: !48)
// CHECK:STDOUT: !51 = !{!49}
// CHECK:STDOUT: !52 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.20c1b1147da3b52d:core.Destroy.Core", scope: null, file: !0, line: 13, type: !14, spFlags: DISPFlagDefinition, unit: !1, retainedNodes: !55)
// CHECK:STDOUT: !53 = !DILocalVariable(arg: 1, scope: !52, type: !4)
// CHECK:STDOUT: !54 = !DILocation(line: 13, column: 22, scope: !52)
// CHECK:STDOUT: !55 = !{!53}
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.20c1b1147da3b52d:core.Destroy.Core", scope: null, file: !0, line: 13, type: !14, spFlags: DISPFlagDefinition, unit: !1, retainedNodes: !59)
// CHECK:STDOUT: !57 = !DILocalVariable(arg: 1, scope: !56, type: !4)
// CHECK:STDOUT: !58 = !DILocation(line: 13, column: 22, scope: !56)
// CHECK:STDOUT: !59 = !{!57}
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.92cfe67cb2f4b128:core.Destroy.Core", scope: null, file: !0, line: 13, type: !14, spFlags: DISPFlagDefinition, unit: !1, retainedNodes: !63)
// CHECK:STDOUT: !61 = !DILocalVariable(arg: 1, scope: !60, type: !4)
// CHECK:STDOUT: !62 = !DILocation(line: 13, column: 22, scope: !60)
// CHECK:STDOUT: !63 = !{!61}
// CHECK:STDOUT: !64 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.92cfe67cb2f4b128:core.Destroy.Core", scope: null, file: !0, line: 13, type: !14, spFlags: DISPFlagDefinition, unit: !1, retainedNodes: !67)
// CHECK:STDOUT: !65 = !DILocalVariable(arg: 1, scope: !64, type: !4)
// CHECK:STDOUT: !66 = !DILocation(line: 13, column: 22, scope: !64)
// CHECK:STDOUT: !67 = !{!65}
// CHECK:STDOUT: !68 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.1eef18dc43ad9a55:core.Destroy.Core", scope: null, file: !0, line: 13, type: !14, spFlags: DISPFlagDefinition, unit: !1, retainedNodes: !71)
// CHECK:STDOUT: !69 = !DILocalVariable(arg: 1, scope: !68, type: !4)
// CHECK:STDOUT: !70 = !DILocation(line: 13, column: 22, scope: !68)
// CHECK:STDOUT: !71 = !{!69}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.1eef18dc43ad9a55:core.Destroy.Core", scope: null, file: !0, line: 13, type: !14, spFlags: DISPFlagDefinition, unit: !1, retainedNodes: !75)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !4)
// CHECK:STDOUT: !74 = !DILocation(line: 13, column: 22, scope: !72)
// CHECK:STDOUT: !75 = !{!73}
// CHECK:STDOUT: !76 = !DIFile(filename: "plib.carbon", directory: "")
// CHECK:STDOUT: !77 = distinct !DISubprogram(name: "Both", linkageName: "_CBoth.Pair.Main.84588f41d61dafba", scope: null, file: !76, line: 3, type: !30, spFlags: DISPFlagDefinition, unit: !1, retainedNodes: !82)
// CHECK:STDOUT: !78 = !DILocalVariable(arg: 1, scope: !77, type: !2)
// CHECK:STDOUT: !79 = !DILocalVariable(arg: 2, scope: !77, type: !2)
// CHECK:STDOUT: !80 = !DILocation(line: 3, column: 1, scope: !77)
// CHECK:STDOUT: !81 = !DILocation(line: 4, column: 19, scope: !77)
// CHECK:STDOUT: !82 = !{!78, !79}
// CHECK:STDOUT: !83 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !84 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT:

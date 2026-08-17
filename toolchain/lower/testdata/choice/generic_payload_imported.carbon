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
// CHECK:STDOUT: define i32 @_CClassify.Main(ptr %p) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_19.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %p, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc7_19.4 = load i8, ptr %.loc7_19.3.discriminant, align 1, !dbg !11
// CHECK:STDOUT:   %.loc7_19.41 = trunc i8 %.loc7_19.4 to i1, !dbg !11
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc7_19.41, !dbg !11
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !11
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !12
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !13
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc13_41.1.temp = alloca <{ <{ i1, [3 x i8] }>, [8 x i8] }>, align 4, !dbg !17
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc13_41.1.temp), !dbg !17
// CHECK:STDOUT:   call void @_CBoth.Pair.Main.84588f41d61dafba(ptr %.loc13_41.1.temp, i32 1, i32 2), !dbg !17
// CHECK:STDOUT:   %Classify.call = call i32 @_CClassify.Main(ptr %.loc13_41.1.temp), !dbg !18
// CHECK:STDOUT:   call void @"_COp.0dc10ea24802c11a:core.Destroy.Core"(ptr %.loc13_41.1.temp), !dbg !17
// CHECK:STDOUT:   ret i32 %Classify.call, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.7512aa4144aeb8db:core.Destroy.Core"(ptr %self) #0 !dbg !20 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5e27612b9dd31a14:core.Destroy.Core"(ptr %self) #0 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.eff30dc40f4a53d2:core.Destroy.Core"(ptr %self) #0 !dbg !33 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.2431a7381b485f6b:core.Destroy.Core"(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !42
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.b4f88722ca47d5b8:core.Destroy.Core"(ptr %self) #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !46
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.0dc10ea24802c11a:core.Destroy.Core"(ptr %self) #0 !dbg !47 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !50
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBoth.Pair.Main.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [8 x i8] }>) %return, i32 %_, i32 %_1) #0 !dbg !51 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !58
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !58
// CHECK:STDOUT:   %Both = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !58
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Pair.val.cf1.anon, i64 12, i1 false), !dbg !58
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %Both, i32 0, i32 0, !dbg !59
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !59
// CHECK:STDOUT:   %tuple.elem2 = getelementptr inbounds nuw { i32, i32 }, ptr %Both, i32 0, i32 1, !dbg !59
// CHECK:STDOUT:   store i32 %_1, ptr %tuple.elem2, align 4, !dbg !59
// CHECK:STDOUT:   ret void, !dbg !58
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "use_imported.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Classify", linkageName: "_CClassify.Main", scope: null, file: !1, line: 5, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 7, column: 5, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 7, column: 24, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 8, column: 18, scope: !4)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !1, line: 12, type: !15, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !15 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !16 = !{!7}
// CHECK:STDOUT: !17 = !DILocation(line: 13, column: 22, scope: !14)
// CHECK:STDOUT: !18 = !DILocation(line: 14, column: 10, scope: !14)
// CHECK:STDOUT: !19 = !DILocation(line: 14, column: 3, scope: !14)
// CHECK:STDOUT: !20 = distinct !DISubprogram(name: "Op", linkageName: "_COp.7512aa4144aeb8db:core.Destroy.Core", scope: null, file: !1, line: 13, type: !21, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !24)
// CHECK:STDOUT: !21 = !DISubroutineType(types: !22)
// CHECK:STDOUT: !22 = !{null, !23}
// CHECK:STDOUT: !23 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !24 = !{!25}
// CHECK:STDOUT: !25 = !DILocalVariable(arg: 1, scope: !20, type: !23)
// CHECK:STDOUT: !26 = !DILocation(line: 13, column: 22, scope: !20)
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5e27612b9dd31a14:core.Destroy.Core", scope: null, file: !1, line: 13, type: !28, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !30)
// CHECK:STDOUT: !28 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !29 = !{null, !7}
// CHECK:STDOUT: !30 = !{!31}
// CHECK:STDOUT: !31 = !DILocalVariable(arg: 1, scope: !27, type: !7)
// CHECK:STDOUT: !32 = !DILocation(line: 13, column: 22, scope: !27)
// CHECK:STDOUT: !33 = distinct !DISubprogram(name: "Op", linkageName: "_COp.eff30dc40f4a53d2:core.Destroy.Core", scope: null, file: !1, line: 13, type: !34, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !36)
// CHECK:STDOUT: !34 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !35 = !{null, !8}
// CHECK:STDOUT: !36 = !{!37}
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !33, type: !8)
// CHECK:STDOUT: !38 = !DILocation(line: 13, column: 22, scope: !33)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "Op", linkageName: "_COp.2431a7381b485f6b:core.Destroy.Core", scope: null, file: !1, line: 13, type: !34, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !40)
// CHECK:STDOUT: !40 = !{!41}
// CHECK:STDOUT: !41 = !DILocalVariable(arg: 1, scope: !39, type: !8)
// CHECK:STDOUT: !42 = !DILocation(line: 13, column: 22, scope: !39)
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "Op", linkageName: "_COp.b4f88722ca47d5b8:core.Destroy.Core", scope: null, file: !1, line: 13, type: !34, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !44)
// CHECK:STDOUT: !44 = !{!45}
// CHECK:STDOUT: !45 = !DILocalVariable(arg: 1, scope: !43, type: !8)
// CHECK:STDOUT: !46 = !DILocation(line: 13, column: 22, scope: !43)
// CHECK:STDOUT: !47 = distinct !DISubprogram(name: "Op", linkageName: "_COp.0dc10ea24802c11a:core.Destroy.Core", scope: null, file: !1, line: 13, type: !34, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !48)
// CHECK:STDOUT: !48 = !{!49}
// CHECK:STDOUT: !49 = !DILocalVariable(arg: 1, scope: !47, type: !8)
// CHECK:STDOUT: !50 = !DILocation(line: 13, column: 22, scope: !47)
// CHECK:STDOUT: !51 = distinct !DISubprogram(name: "Both", linkageName: "_CBoth.Pair.Main.84588f41d61dafba", scope: null, file: !52, line: 3, type: !53, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !55)
// CHECK:STDOUT: !52 = !DIFile(filename: "plib.carbon", directory: "")
// CHECK:STDOUT: !53 = !DISubroutineType(types: !54)
// CHECK:STDOUT: !54 = !{!8, !7, !7}
// CHECK:STDOUT: !55 = !{!56, !57}
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !51, type: !7)
// CHECK:STDOUT: !57 = !DILocalVariable(arg: 2, scope: !51, type: !7)
// CHECK:STDOUT: !58 = !DILocation(line: 3, column: 1, scope: !51)
// CHECK:STDOUT: !59 = !DILocation(line: 4, column: 19, scope: !51)
// CHECK:STDOUT:

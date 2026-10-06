// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --clang-arg=-fno-exceptions
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/class/export/union.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/class/export/union.carbon

// An exported Carbon union in lowering (fork/unions/plan.md UN-2, §4.B): the
// union's storage is `[8 x i8]`, the exported method thunk and the C++ `Use`
// both read `lo` at offset zero, and the designated initializer is a plain
// store through a byte-offset GEP.

// --- export.carbon
library "[[@TEST_NAME]]";

import Cpp;

union Wide {
  var lo: i32;
  var both: i64;
  fn Low(self) -> i32 { return self.lo; }
}

inline Cpp '''
int Use(Carbon::Wide* w) {
  w->lo = 3;
  return w->Low();
}
''';

fn CallUse() -> i32 {
  var w: Wide = {.both = 5};
  return Cpp.Use(&w);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'export.carbon'
// CHECK:STDOUT: source_filename = "export.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define dso_local noundef i32 @_Z3UsePN6Carbon4WideE(ptr noundef %w) #0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %w.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %w, ptr %w.addr, align 8, !tbaa !4
// CHECK:STDOUT:   %0 = load ptr, ptr %w.addr, align 8, !tbaa !4
// CHECK:STDOUT:   store i32 3, ptr %0, align 8, !tbaa !5
// CHECK:STDOUT:   %1 = load ptr, ptr %w.addr, align 8, !tbaa !4
// CHECK:STDOUT:   %call = call noundef i32 @_ZNK6Carbon4Wide3LowEv(ptr noundef nonnull align 8 dereferenceable(8) %1)
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_ZNK6Carbon4Wide3LowEv(ptr noundef nonnull align 8 dereferenceable(8) %this) #1 align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca i32, align 4
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !4
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   call void @_CLow__carbon_thunk.Wide.Main(ptr noundef nonnull align 8 dereferenceable(8) %this1, ptr noundef nonnull align 4 dereferenceable(4) %retval)
// CHECK:STDOUT:   %0 = load i32, ptr %retval, align 4
// CHECK:STDOUT:   ret i32 %0
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CLow.Wide.Main(ptr %self) #2 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8_36.1.lo = getelementptr inbounds nuw [8 x i8], ptr %self, i32 0, i32 0, !dbg !32
// CHECK:STDOUT:   %.loc8_36.2 = load i32, ptr %.loc8_36.1.lo, align 4, !dbg !32
// CHECK:STDOUT:   ret i32 %.loc8_36.2, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CLow__carbon_thunk.Wide.Main(ptr %self, ptr %_) #2 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Wide.Low.call = call i32 @_CLow.Wide.Main(ptr %self), !dbg !38
// CHECK:STDOUT:   store i32 %Wide.Low.call, ptr %_, align 4, !dbg !38
// CHECK:STDOUT:   ret void, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CCallUse.Main() #2 !dbg !40 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %w.var = alloca [8 x i8], align 8, !dbg !43
// CHECK:STDOUT:   %.loc20_18.2.temp = alloca ptr, align 8, !dbg !47
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %w.var), !dbg !43
// CHECK:STDOUT:   %.loc19_27.3.both = getelementptr inbounds nuw [8 x i8], ptr %w.var, i32 0, i32 0, !dbg !44
// CHECK:STDOUT:   store i64 5, ptr %.loc19_27.3.both, align 8, !dbg !44
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.call = call ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.2c0b89445d71ed73"(ptr %w.var), !dbg !47
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc20_18.2.temp), !dbg !47
// CHECK:STDOUT:   store ptr %U.as_type.as.ImplicitAs.impl.Convert.call, ptr %.loc20_18.2.temp, align 8, !dbg !47
// CHECK:STDOUT:   %.loc20_18.4 = load ptr, ptr %.loc20_18.2.temp, align 8, !dbg !47
// CHECK:STDOUT:   %Use.call = call i32 @_Z3UsePN6Carbon4WideE(ptr %.loc20_18.4), !dbg !50
// CHECK:STDOUT:   call void @"_CSelfDestruct.738d70b885195699:core.Destroy.Core"(ptr %.loc20_18.2.temp), !dbg !47
// CHECK:STDOUT:   call void @"_CSelfDestruct.90d5c1783df5d1b7:core.Destroy.Core"(ptr %w.var), !dbg !43
// CHECK:STDOUT:   ret i32 %Use.call, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.567e7ad6ec41bade:core.Destroy.Core"(ptr %self) #2 !dbg !53 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d0edc9738406119f:core.Destroy.Core"(ptr %self) #2 !dbg !57 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e5a82504891b586f:core.Destroy.Core"(ptr %self) #2 !dbg !61 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !63
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.738d70b885195699:core.Destroy.Core"(ptr %self) #2 !dbg !65 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !67
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #2 !dbg !69 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !71
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #2 !dbg !73 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !75
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.54e625b7123b91de:core.Destroy.Core"(ptr %self) #2 !dbg !77 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !79
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.54e625b7123b91de:core.Destroy.Core"(ptr %self) #2 !dbg !81 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.54e625b7123b91de:core.Destroy.Core"(ptr %self), !dbg !83
// CHECK:STDOUT:   ret void, !dbg !83
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.90d5c1783df5d1b7:core.Destroy.Core"(ptr %self) #2 !dbg !85 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_3.1.both = getelementptr inbounds nuw [8 x i8], ptr %self, i32 0, i32 0, !dbg !87
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.loc19_3.1.both), !dbg !87
// CHECK:STDOUT:   %.loc19_3.2.lo = getelementptr inbounds nuw [8 x i8], ptr %self, i32 0, i32 0, !dbg !87
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc19_3.2.lo), !dbg !87
// CHECK:STDOUT:   ret void, !dbg !87
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.90d5c1783df5d1b7:core.Destroy.Core"(ptr %self) #2 !dbg !89 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.90d5c1783df5d1b7:core.Destroy.Core"(ptr %self), !dbg !91
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #3
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.2c0b89445d71ed73"(ptr %self) #2 !dbg !94 {
// CHECK:STDOUT:   %1 = call ptr @"_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.03cfe8a5d5b2c998"(ptr %self), !dbg !99
// CHECK:STDOUT:   ret ptr %1, !dbg !100
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.03cfe8a5d5b2c998"(ptr %self) #2 !dbg !102 {
// CHECK:STDOUT:   %1 = call ptr @_CSome.Optional.Core.03cfe8a5d5b2c998(ptr %self), !dbg !108
// CHECK:STDOUT:   ret ptr %1, !dbg !109
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CSome.Optional.Core.03cfe8a5d5b2c998(ptr %value) #2 !dbg !111 {
// CHECK:STDOUT:   %1 = call ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.995c1960e4244e9e"(ptr %value), !dbg !116
// CHECK:STDOUT:   ret ptr %1, !dbg !117
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.995c1960e4244e9e"(ptr %self) #2 !dbg !119 {
// CHECK:STDOUT:   %1 = alloca ptr, align 8, !dbg !124
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !124
// CHECK:STDOUT:   store ptr poison, ptr %1, align 8, !dbg !124
// CHECK:STDOUT:   store ptr %self, ptr %1, align 8, !dbg !128
// CHECK:STDOUT:   %2 = load ptr, ptr %1, align 8, !dbg !126
// CHECK:STDOUT:   call void @"_CSelfDestruct.e5a82504891b586f:core.Destroy.Core"(ptr %1), !dbg !124
// CHECK:STDOUT:   ret ptr %2, !dbg !130
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 0, 2, 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nounwind }
// CHECK:STDOUT: attributes #3 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!11}
// CHECK:STDOUT: !llvm.module.flags = !{!133, !134, !135, !8, !9}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!137}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !1 = !{!"omnipotent char", !0, i64 0}
// CHECK:STDOUT: !2 = !{!"any pointer", !1, i64 0}
// CHECK:STDOUT: !3 = !{!"p1 _ZTSN6Carbon4WideE", !2, i64 0}
// CHECK:STDOUT: !4 = !{!3, !3, i64 0}
// CHECK:STDOUT: !5 = !{!1, !1, i64 0}
// CHECK:STDOUT: !8 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !9 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !10 = !DIFile(filename: "export.carbon", directory: "")
// CHECK:STDOUT: !11 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !10, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !12 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !13 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !15 = !{!12, !14}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = !{null, !14, !12}
// CHECK:STDOUT: !18 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !19 = !{!12}
// CHECK:STDOUT: !20 = !DISubroutineType(types: !19)
// CHECK:STDOUT: !21 = !{null, !14}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !23 = !{null, !12}
// CHECK:STDOUT: !24 = !DISubroutineType(types: !23)
// CHECK:STDOUT: !25 = !{null, !13}
// CHECK:STDOUT: !26 = !DISubroutineType(types: !25)
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "Low", linkageName: "_CLow.Wide.Main", scope: null, file: !10, line: 8, type: !16, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !34)
// CHECK:STDOUT: !28 = !DILocalVariable(arg: 1, scope: !27, type: !14)
// CHECK:STDOUT: !32 = !DILocation(line: 8, column: 32, scope: !27)
// CHECK:STDOUT: !33 = !DILocation(line: 8, column: 25, scope: !27)
// CHECK:STDOUT: !34 = !{!28}
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "Low__carbon_thunk", linkageName: "_CLow__carbon_thunk.Wide.Main", scope: null, file: !10, line: 8, type: !18, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !39)
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !35, type: !14)
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 2, scope: !35, type: !12)
// CHECK:STDOUT: !38 = !DILocation(line: 8, column: 3, scope: !35)
// CHECK:STDOUT: !39 = !{!36, !37}
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "CallUse", linkageName: "_CCallUse.Main", scope: null, file: !10, line: 18, type: !20, spFlags: DISPFlagDefinition, unit: !11)
// CHECK:STDOUT: !43 = !DILocation(line: 19, column: 3, scope: !40)
// CHECK:STDOUT: !44 = !DILocation(line: 19, column: 17, scope: !40)
// CHECK:STDOUT: !47 = !DILocation(line: 20, column: 18, scope: !40)
// CHECK:STDOUT: !48 = !{!14, !14}
// CHECK:STDOUT: !49 = !DISubroutineType(types: !48)
// CHECK:STDOUT: !50 = !DILocation(line: 20, column: 10, scope: !40)
// CHECK:STDOUT: !51 = !DILocation(line: 20, column: 3, scope: !40)
// CHECK:STDOUT: !52 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !53 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.567e7ad6ec41bade:core.Destroy.Core", scope: null, file: !52, line: 189, type: !22, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !56)
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !53, type: !14)
// CHECK:STDOUT: !55 = !DILocation(line: 189, column: 19, scope: !53)
// CHECK:STDOUT: !56 = !{!54}
// CHECK:STDOUT: !57 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d0edc9738406119f:core.Destroy.Core", scope: null, file: !10, line: 20, type: !22, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !60)
// CHECK:STDOUT: !58 = !DILocalVariable(arg: 1, scope: !57, type: !14)
// CHECK:STDOUT: !59 = !DILocation(line: 20, column: 18, scope: !57)
// CHECK:STDOUT: !60 = !{!58}
// CHECK:STDOUT: !61 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e5a82504891b586f:core.Destroy.Core", scope: null, file: !10, line: 20, type: !22, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !64)
// CHECK:STDOUT: !62 = !DILocalVariable(arg: 1, scope: !61, type: !14)
// CHECK:STDOUT: !63 = !DILocation(line: 20, column: 18, scope: !61)
// CHECK:STDOUT: !64 = !{!62}
// CHECK:STDOUT: !65 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.738d70b885195699:core.Destroy.Core", scope: null, file: !10, line: 20, type: !22, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !68)
// CHECK:STDOUT: !66 = !DILocalVariable(arg: 1, scope: !65, type: !14)
// CHECK:STDOUT: !67 = !DILocation(line: 20, column: 18, scope: !65)
// CHECK:STDOUT: !68 = !{!66}
// CHECK:STDOUT: !69 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !10, line: 19, type: !24, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !72)
// CHECK:STDOUT: !70 = !DILocalVariable(arg: 1, scope: !69, type: !12)
// CHECK:STDOUT: !71 = !DILocation(line: 19, column: 3, scope: !69)
// CHECK:STDOUT: !72 = !{!70}
// CHECK:STDOUT: !73 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !10, line: 19, type: !26, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !76)
// CHECK:STDOUT: !74 = !DILocalVariable(arg: 1, scope: !73, type: !13)
// CHECK:STDOUT: !75 = !DILocation(line: 19, column: 3, scope: !73)
// CHECK:STDOUT: !76 = !{!74}
// CHECK:STDOUT: !77 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.54e625b7123b91de:core.Destroy.Core", scope: null, file: !10, line: 19, type: !22, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !80)
// CHECK:STDOUT: !78 = !DILocalVariable(arg: 1, scope: !77, type: !14)
// CHECK:STDOUT: !79 = !DILocation(line: 19, column: 3, scope: !77)
// CHECK:STDOUT: !80 = !{!78}
// CHECK:STDOUT: !81 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.54e625b7123b91de:core.Destroy.Core", scope: null, file: !10, line: 19, type: !22, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !84)
// CHECK:STDOUT: !82 = !DILocalVariable(arg: 1, scope: !81, type: !14)
// CHECK:STDOUT: !83 = !DILocation(line: 19, column: 3, scope: !81)
// CHECK:STDOUT: !84 = !{!82}
// CHECK:STDOUT: !85 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.90d5c1783df5d1b7:core.Destroy.Core", scope: null, file: !10, line: 19, type: !22, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !88)
// CHECK:STDOUT: !86 = !DILocalVariable(arg: 1, scope: !85, type: !14)
// CHECK:STDOUT: !87 = !DILocation(line: 19, column: 3, scope: !85)
// CHECK:STDOUT: !88 = !{!86}
// CHECK:STDOUT: !89 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.90d5c1783df5d1b7:core.Destroy.Core", scope: null, file: !10, line: 19, type: !22, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !92)
// CHECK:STDOUT: !90 = !DILocalVariable(arg: 1, scope: !89, type: !14)
// CHECK:STDOUT: !91 = !DILocation(line: 19, column: 3, scope: !89)
// CHECK:STDOUT: !92 = !{!90}
// CHECK:STDOUT: !94 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.2c0b89445d71ed73", scope: null, file: !52, line: 130, type: !49, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !101)
// CHECK:STDOUT: !95 = !DILocalVariable(arg: 1, scope: !94, type: !14)
// CHECK:STDOUT: !99 = !DILocation(line: 131, column: 12, scope: !94)
// CHECK:STDOUT: !100 = !DILocation(line: 131, column: 5, scope: !94)
// CHECK:STDOUT: !101 = !{!95}
// CHECK:STDOUT: !102 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.03cfe8a5d5b2c998", scope: null, file: !52, line: 105, type: !49, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !110)
// CHECK:STDOUT: !103 = !DILocalVariable(arg: 1, scope: !102, type: !14)
// CHECK:STDOUT: !108 = !DILocation(line: 106, column: 12, scope: !102)
// CHECK:STDOUT: !109 = !DILocation(line: 106, column: 5, scope: !102)
// CHECK:STDOUT: !110 = !{!103}
// CHECK:STDOUT: !111 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.03cfe8a5d5b2c998", scope: null, file: !52, line: 34, type: !49, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !118)
// CHECK:STDOUT: !112 = !DILocalVariable(arg: 1, scope: !111, type: !14)
// CHECK:STDOUT: !116 = !DILocation(line: 35, column: 12, scope: !111)
// CHECK:STDOUT: !117 = !DILocation(line: 35, column: 5, scope: !111)
// CHECK:STDOUT: !118 = !{!112}
// CHECK:STDOUT: !119 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.e8f8f92d3d08d149:OptionalStorage.Core.995c1960e4244e9e", scope: null, file: !52, line: 191, type: !49, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !131)
// CHECK:STDOUT: !120 = !DILocalVariable(arg: 1, scope: !119, type: !14)
// CHECK:STDOUT: !124 = !DILocation(line: 192, column: 14, scope: !119)
// CHECK:STDOUT: !126 = !DILocation(line: 192, column: 18, scope: !119)
// CHECK:STDOUT: !128 = !DILocation(line: 194, column: 5, scope: !119)
// CHECK:STDOUT: !130 = !DILocation(line: 195, column: 5, scope: !119)
// CHECK:STDOUT: !131 = !{!120}
// CHECK:STDOUT: !132 = !{!"int", !1, i64 0}
// CHECK:STDOUT: !133 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !134 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !135 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !136 = !{!"__libc_errno", !132, i64 0}
// CHECK:STDOUT: !137 = !{!136, !132, i64 0}
// CHECK:STDOUT:

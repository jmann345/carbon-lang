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
// CHECK:STDOUT:   store ptr %w, ptr %w.addr, align 8, !tbaa !12
// CHECK:STDOUT:   %0 = load ptr, ptr %w.addr, align 8, !tbaa !12
// CHECK:STDOUT:   store i32 3, ptr %0, align 8, !tbaa !15
// CHECK:STDOUT:   %1 = load ptr, ptr %w.addr, align 8, !tbaa !12
// CHECK:STDOUT:   %call = call noundef i32 @_ZNK6Carbon4Wide3LowEv(ptr noundef nonnull align 8 dereferenceable(8) %1)
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_ZNK6Carbon4Wide3LowEv(ptr noundef nonnull align 8 dereferenceable(8) %this) #1 align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca i32, align 4
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !12
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   call void @_CLow__carbon_thunk.Wide.Main(ptr noundef nonnull align 8 dereferenceable(8) %this1, ptr noundef nonnull align 4 dereferenceable(4) %retval)
// CHECK:STDOUT:   %0 = load i32, ptr %retval, align 4
// CHECK:STDOUT:   ret i32 %0
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CLow.Wide.Main(ptr %self) #2 !dbg !16 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8_36.1.lo = getelementptr inbounds nuw [8 x i8], ptr %self, i32 0, i32 0, !dbg !23
// CHECK:STDOUT:   %.loc8_36.2 = load i32, ptr %.loc8_36.1.lo, align 4, !dbg !23
// CHECK:STDOUT:   ret i32 %.loc8_36.2, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CLow__carbon_thunk.Wide.Main(ptr %self, ptr %_) #2 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Wide.Low.call = call i32 @_CLow.Wide.Main(ptr %self), !dbg !31
// CHECK:STDOUT:   store i32 %Wide.Low.call, ptr %_, align 4, !dbg !31
// CHECK:STDOUT:   ret void, !dbg !31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CCallUse.Main() #2 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %w.var = alloca [8 x i8], align 8, !dbg !35
// CHECK:STDOUT:   %.loc20_18.2.temp = alloca ptr, align 8, !dbg !36
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %w.var), !dbg !35
// CHECK:STDOUT:   %.loc19_27.3.both = getelementptr inbounds nuw [8 x i8], ptr %w.var, i32 0, i32 0, !dbg !37
// CHECK:STDOUT:   store i64 5, ptr %.loc19_27.3.both, align 8, !dbg !37
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.call = call ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.2c0b89445d71ed73"(ptr %w.var), !dbg !36
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc20_18.2.temp), !dbg !36
// CHECK:STDOUT:   store ptr %U.as_type.as.ImplicitAs.impl.Convert.call, ptr %.loc20_18.2.temp, align 8, !dbg !36
// CHECK:STDOUT:   %.loc20_18.4 = load ptr, ptr %.loc20_18.2.temp, align 8, !dbg !36
// CHECK:STDOUT:   %Use.call = call i32 @_Z3UsePN6Carbon4WideE(ptr %.loc20_18.4), !dbg !38
// CHECK:STDOUT:   call void @"_COp.93f7ac8aab800abf:core.Destroy.Core"(ptr %.loc20_18.2.temp), !dbg !36
// CHECK:STDOUT:   call void @"_COp.72ca955f09bfd4f9:core.Destroy.Core"(ptr %w.var), !dbg !35
// CHECK:STDOUT:   ret i32 %Use.call, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.2f3ba963c13fdc02:core.Destroy.Core"(ptr %self) #2 !dbg !40 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.d4c8aa3acb16ff64:core.Destroy.Core"(ptr %self) #2 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.93f7ac8aab800abf:core.Destroy.Core"(ptr %self) #2 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #2 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5f42013854821c52:core.Destroy.Core"(ptr %self) #2 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5d98754f6e026e17:core.Destroy.Core"(ptr %self) #2 !dbg !67 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.72ca955f09bfd4f9:core.Destroy.Core"(ptr %self) #2 !dbg !71 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #3
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.2c0b89445d71ed73"(ptr %self) #2 !dbg !75 {
// CHECK:STDOUT:   %1 = call ptr @"_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.03cfe8a5d5b2c998"(ptr %self), !dbg !81
// CHECK:STDOUT:   ret ptr %1, !dbg !82
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.03cfe8a5d5b2c998"(ptr %self) #2 !dbg !83 {
// CHECK:STDOUT:   %1 = call ptr @_CSome.Optional.Core.03cfe8a5d5b2c998(ptr %self), !dbg !86
// CHECK:STDOUT:   ret ptr %1, !dbg !87
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CSome.Optional.Core.03cfe8a5d5b2c998(ptr %value) #2 !dbg !88 {
// CHECK:STDOUT:   %1 = call ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.995c1960e4244e9e"(ptr %value), !dbg !91
// CHECK:STDOUT:   ret ptr %1, !dbg !92
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.995c1960e4244e9e"(ptr %self) #2 !dbg !93 {
// CHECK:STDOUT:   %1 = alloca ptr, align 8, !dbg !96
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !96
// CHECK:STDOUT:   store ptr poison, ptr %1, align 8, !dbg !96
// CHECK:STDOUT:   store ptr %self, ptr %1, align 8, !dbg !97
// CHECK:STDOUT:   %2 = load ptr, ptr %1, align 8, !dbg !98
// CHECK:STDOUT:   call void @"_COp.d4c8aa3acb16ff64:core.Destroy.Core"(ptr %1), !dbg !96
// CHECK:STDOUT:   ret ptr %2, !dbg !99
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3, !4, !5, !6}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!7}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "export.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !3 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !4 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !5 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !6 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !7 = !{!8, !9, i64 0}
// CHECK:STDOUT: !8 = !{!"__libc_errno", !9, i64 0}
// CHECK:STDOUT: !9 = !{!"int", !10, i64 0}
// CHECK:STDOUT: !10 = !{!"omnipotent char", !11, i64 0}
// CHECK:STDOUT: !11 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !12 = !{!13, !13, i64 0}
// CHECK:STDOUT: !13 = !{!"p1 _ZTSN6Carbon4WideE", !14, i64 0}
// CHECK:STDOUT: !14 = !{!"any pointer", !10, i64 0}
// CHECK:STDOUT: !15 = !{!10, !10, i64 0}
// CHECK:STDOUT: !16 = distinct !DISubprogram(name: "Low", linkageName: "_CLow.Wide.Main", scope: null, file: !1, line: 8, type: !17, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !21)
// CHECK:STDOUT: !17 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !18 = !{!19, !20}
// CHECK:STDOUT: !19 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !20 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !21 = !{!22}
// CHECK:STDOUT: !22 = !DILocalVariable(arg: 1, scope: !16, type: !20)
// CHECK:STDOUT: !23 = !DILocation(line: 8, column: 32, scope: !16)
// CHECK:STDOUT: !24 = !DILocation(line: 8, column: 25, scope: !16)
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "Low__carbon_thunk", linkageName: "_CLow__carbon_thunk.Wide.Main", scope: null, file: !1, line: 8, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !28)
// CHECK:STDOUT: !26 = !DISubroutineType(types: !27)
// CHECK:STDOUT: !27 = !{null, !20, !19}
// CHECK:STDOUT: !28 = !{!29, !30}
// CHECK:STDOUT: !29 = !DILocalVariable(arg: 1, scope: !25, type: !20)
// CHECK:STDOUT: !30 = !DILocalVariable(arg: 2, scope: !25, type: !19)
// CHECK:STDOUT: !31 = !DILocation(line: 8, column: 3, scope: !25)
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "CallUse", linkageName: "_CCallUse.Main", scope: null, file: !1, line: 18, type: !33, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !33 = !DISubroutineType(types: !34)
// CHECK:STDOUT: !34 = !{!19}
// CHECK:STDOUT: !35 = !DILocation(line: 19, column: 3, scope: !32)
// CHECK:STDOUT: !36 = !DILocation(line: 20, column: 18, scope: !32)
// CHECK:STDOUT: !37 = !DILocation(line: 19, column: 17, scope: !32)
// CHECK:STDOUT: !38 = !DILocation(line: 20, column: 10, scope: !32)
// CHECK:STDOUT: !39 = !DILocation(line: 20, column: 3, scope: !32)
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "Op", linkageName: "_COp.2f3ba963c13fdc02:core.Destroy.Core", scope: null, file: !1, line: 20, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !43)
// CHECK:STDOUT: !41 = !DISubroutineType(types: !42)
// CHECK:STDOUT: !42 = !{null, !20}
// CHECK:STDOUT: !43 = !{!44}
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !40, type: !20)
// CHECK:STDOUT: !45 = !DILocation(line: 20, column: 18, scope: !40)
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "Op", linkageName: "_COp.d4c8aa3acb16ff64:core.Destroy.Core", scope: null, file: !1, line: 20, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !47)
// CHECK:STDOUT: !47 = !{!48}
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !46, type: !20)
// CHECK:STDOUT: !49 = !DILocation(line: 20, column: 18, scope: !46)
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "Op", linkageName: "_COp.93f7ac8aab800abf:core.Destroy.Core", scope: null, file: !1, line: 20, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !51)
// CHECK:STDOUT: !51 = !{!52}
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !50, type: !20)
// CHECK:STDOUT: !53 = !DILocation(line: 20, column: 18, scope: !50)
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 19, type: !55, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !57)
// CHECK:STDOUT: !55 = !DISubroutineType(types: !56)
// CHECK:STDOUT: !56 = !{null, !19}
// CHECK:STDOUT: !57 = !{!58}
// CHECK:STDOUT: !58 = !DILocalVariable(arg: 1, scope: !54, type: !19)
// CHECK:STDOUT: !59 = !DILocation(line: 19, column: 3, scope: !54)
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5f42013854821c52:core.Destroy.Core", scope: null, file: !1, line: 19, type: !61, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !64)
// CHECK:STDOUT: !61 = !DISubroutineType(types: !62)
// CHECK:STDOUT: !62 = !{null, !63}
// CHECK:STDOUT: !63 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !64 = !{!65}
// CHECK:STDOUT: !65 = !DILocalVariable(arg: 1, scope: !60, type: !63)
// CHECK:STDOUT: !66 = !DILocation(line: 19, column: 3, scope: !60)
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5d98754f6e026e17:core.Destroy.Core", scope: null, file: !1, line: 19, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !68)
// CHECK:STDOUT: !68 = !{!69}
// CHECK:STDOUT: !69 = !DILocalVariable(arg: 1, scope: !67, type: !20)
// CHECK:STDOUT: !70 = !DILocation(line: 19, column: 3, scope: !67)
// CHECK:STDOUT: !71 = distinct !DISubprogram(name: "Op", linkageName: "_COp.72ca955f09bfd4f9:core.Destroy.Core", scope: null, file: !1, line: 19, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !72)
// CHECK:STDOUT: !72 = !{!73}
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !71, type: !20)
// CHECK:STDOUT: !74 = !DILocation(line: 19, column: 3, scope: !71)
// CHECK:STDOUT: !75 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.2c0b89445d71ed73", scope: null, file: !76, line: 130, type: !77, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !79)
// CHECK:STDOUT: !76 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !77 = !DISubroutineType(types: !78)
// CHECK:STDOUT: !78 = !{!20, !20}
// CHECK:STDOUT: !79 = !{!80}
// CHECK:STDOUT: !80 = !DILocalVariable(arg: 1, scope: !75, type: !20)
// CHECK:STDOUT: !81 = !DILocation(line: 131, column: 12, scope: !75)
// CHECK:STDOUT: !82 = !DILocation(line: 131, column: 5, scope: !75)
// CHECK:STDOUT: !83 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.03cfe8a5d5b2c998", scope: null, file: !76, line: 105, type: !77, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !84)
// CHECK:STDOUT: !84 = !{!85}
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !83, type: !20)
// CHECK:STDOUT: !86 = !DILocation(line: 106, column: 12, scope: !83)
// CHECK:STDOUT: !87 = !DILocation(line: 106, column: 5, scope: !83)
// CHECK:STDOUT: !88 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.03cfe8a5d5b2c998", scope: null, file: !76, line: 34, type: !77, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !89)
// CHECK:STDOUT: !89 = !{!90}
// CHECK:STDOUT: !90 = !DILocalVariable(arg: 1, scope: !88, type: !20)
// CHECK:STDOUT: !91 = !DILocation(line: 35, column: 12, scope: !88)
// CHECK:STDOUT: !92 = !DILocation(line: 35, column: 5, scope: !88)
// CHECK:STDOUT: !93 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.e8f8f92d3d08d149:OptionalStorage.Core.995c1960e4244e9e", scope: null, file: !76, line: 191, type: !77, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !94)
// CHECK:STDOUT: !94 = !{!95}
// CHECK:STDOUT: !95 = !DILocalVariable(arg: 1, scope: !93, type: !20)
// CHECK:STDOUT: !96 = !DILocation(line: 192, column: 14, scope: !93)
// CHECK:STDOUT: !97 = !DILocation(line: 194, column: 5, scope: !93)
// CHECK:STDOUT: !98 = !DILocation(line: 192, column: 18, scope: !93)
// CHECK:STDOUT: !99 = !DILocation(line: 195, column: 5, scope: !93)
// CHECK:STDOUT:

// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/function/export/constructor.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/function/export/constructor.carbon

// --- call_constructor.carbon
library "[[@TEST_NAME]]";

import Cpp;

class OneArg {
  fn OneArg(i: i32) -> Self;
}

inline Cpp '''
void f() {
  Carbon::OneArg a(42);
}
''';

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'call_constructor.carbon'
// CHECK:STDOUT: source_filename = "call_constructor.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %"class.Carbon::OneArg" = type {}
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress uwtable
// CHECK:STDOUT: define dso_local void @_Z1fv() #0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a = alloca %"class.Carbon::OneArg", align 1
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a) #3
// CHECK:STDOUT:   call void @_ZN6Carbon6OneArgC2Ei(ptr noundef nonnull align 1 %a, i32 noundef 42)
// CHECK:STDOUT:   call void @llvm.lifetime.end.p0(ptr %a) #3
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN6Carbon6OneArgC2Ei(ptr noundef nonnull align 1 %this, i32 noundef %0) unnamed_addr #2 align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %.addr = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !22
// CHECK:STDOUT:   store i32 %0, ptr %.addr, align 4, !tbaa !24
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   call void @_COneArg__carbon_thunk.OneArg.Main(ptr noundef nonnull align 1 %this1, ptr noundef nonnull align 4 dereferenceable(4) %.addr)
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.end.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_COneArg.OneArg.Main(ptr sret({}), i32)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_COneArg__carbon_thunk.OneArg.Main(ptr %_, ptr %_1) #3 !dbg !13 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_28.2 = load i32, ptr %_1, align 4, !dbg !16
// CHECK:STDOUT:   call void @_COneArg.OneArg.Main(ptr %_, i32 %.loc6_28.2), !dbg !16
// CHECK:STDOUT:   ret void, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { mustprogress uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #2 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #3 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!6}
// CHECK:STDOUT: !llvm.module.flags = !{!25, !26, !27, !3, !4}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!29}
// CHECK:STDOUT:
// CHECK:STDOUT: !3 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !4 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !5 = !DIFile(filename: "call_constructor.carbon", directory: "")
// CHECK:STDOUT: !6 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !5, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !11 = !{null, !8, !7}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = distinct !DISubprogram(name: "OneArg__carbon_thunk", linkageName: "_COneArg__carbon_thunk.OneArg.Main", scope: null, file: !5, line: 6, type: !12, spFlags: DISPFlagDefinition, unit: !6, retainedNodes: !17)
// CHECK:STDOUT: !14 = !DILocalVariable(arg: 1, scope: !13, type: !8)
// CHECK:STDOUT: !15 = !DILocalVariable(arg: 2, scope: !13, type: !7)
// CHECK:STDOUT: !16 = !DILocation(line: 6, column: 3, scope: !13)
// CHECK:STDOUT: !17 = !{!14, !15}
// CHECK:STDOUT: !18 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !19 = !{!"omnipotent char", !18, i64 0}
// CHECK:STDOUT: !20 = !{!"any pointer", !19, i64 0}
// CHECK:STDOUT: !21 = !{!"p1 _ZTSN6Carbon6OneArgE", !20, i64 0}
// CHECK:STDOUT: !22 = !{!21, !21, i64 0}
// CHECK:STDOUT: !23 = !{!"int", !19, i64 0}
// CHECK:STDOUT: !24 = !{!23, !23, i64 0}
// CHECK:STDOUT: !25 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !26 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !27 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !28 = !{!"__libc_errno", !23, i64 0}
// CHECK:STDOUT: !29 = !{!28, !23, i64 0}
// CHECK:STDOUT:

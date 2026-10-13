// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/template/template_constraint.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/template/template_constraint.carbon

// A dependent method call through a `template constraint` binding lowers as an
// ordinary call to the type's own method: a satisfied conversion adds no
// witnesses, so nothing under toolchain/lower/ changes (fork decision F-010 /
// SC-1, fork/structural/plan.md §1.E; the merging.carbon `InitAndCallF`
// precedent).

// --- call_method.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class StructuralOnly {
  // CHECK:STDERR: call_method.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Get(self) -> i32 { return 42; }
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
  fn Get(unused self) -> i32 { return 42; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Run() -> i32 {
  let s: StructuralOnly = {};
  return CallGet(s);
}

// --- compound_nongeneric.carbon
library "[[@TEST_NAME]]";

// Compound access through a requirement in a non-generic function is not
// template-dependent and lowers to a call of the type's own method (D-SC-20;
// fill round 1, fix 2; fill round 2, review finding F3).
template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn Get(unused self) -> i32 { return 42; }
}

fn Run() -> i32 {
  let c: C = {};
  return c.(HasGet.Get)();
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'call_method.carbon'
// CHECK:STDOUT: source_filename = "call_method.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @StructuralOnly.val = internal constant {} zeroinitializer
// CHECK:STDOUT: @StructuralOnly.val.loc18_28.6 = internal constant {} zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CGet.StructuralOnly.Main(ptr %self) #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 42, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !21 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc18_28.2.temp = alloca {}, align 1, !dbg !24
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc18_28.2.temp), !dbg !24
// CHECK:STDOUT:   %CallGet.call = call i32 @_CCallGet.Main.f62a2c791da98824(ptr @StructuralOnly.val.loc18_28.6), !dbg !28
// CHECK:STDOUT:   call void @"_CSelfDestruct.5f34240af69d1bb5:core.Destroy.Core"(ptr @StructuralOnly.val), !dbg !24
// CHECK:STDOUT:   ret i32 %CallGet.call, !dbg !29
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.cb8adced19392b99:core.Destroy.Core"(ptr %self) #0 !dbg !30 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5f34240af69d1bb5:core.Destroy.Core"(ptr %self) #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CCallGet.Main.f62a2c791da98824(ptr %x) #0 !dbg !38 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %StructuralOnly.Get.call = call i32 @_CGet.StructuralOnly.Main(ptr %x), !dbg !43
// CHECK:STDOUT:   ret i32 %StructuralOnly.Get.call, !dbg !44
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
// CHECK:STDOUT: !4 = !DIFile(filename: "call_method.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!6, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{!6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.StructuralOnly.Main", scope: null, file: !4, line: 12, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !20)
// CHECK:STDOUT: !15 = !DILocalVariable(arg: 1, scope: !14, type: !7)
// CHECK:STDOUT: !19 = !DILocation(line: 12, column: 25, scope: !14)
// CHECK:STDOUT: !20 = !{!15}
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !4, line: 17, type: !11, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !24 = !DILocation(line: 18, column: 27, scope: !21)
// CHECK:STDOUT: !28 = !DILocation(line: 19, column: 10, scope: !21)
// CHECK:STDOUT: !29 = !DILocation(line: 19, column: 3, scope: !21)
// CHECK:STDOUT: !30 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.cb8adced19392b99:core.Destroy.Core", scope: null, file: !4, line: 18, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !33)
// CHECK:STDOUT: !31 = !DILocalVariable(arg: 1, scope: !30, type: !7)
// CHECK:STDOUT: !32 = !DILocation(line: 18, column: 27, scope: !30)
// CHECK:STDOUT: !33 = !{!31}
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5f34240af69d1bb5:core.Destroy.Core", scope: null, file: !4, line: 18, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !37)
// CHECK:STDOUT: !35 = !DILocalVariable(arg: 1, scope: !34, type: !7)
// CHECK:STDOUT: !36 = !DILocation(line: 18, column: 27, scope: !34)
// CHECK:STDOUT: !37 = !{!35}
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "CallGet", linkageName: "_CCallGet.Main.f62a2c791da98824", scope: null, file: !4, line: 15, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !45)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !38, type: !7)
// CHECK:STDOUT: !43 = !DILocation(line: 15, column: 54, scope: !38)
// CHECK:STDOUT: !44 = !DILocation(line: 15, column: 47, scope: !38)
// CHECK:STDOUT: !45 = !{!39}
// CHECK:STDOUT:

// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/globals_carbon_defined.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/globals_carbon_defined.carbon

// The F8a mechanism probe for defect TA-D3 (fork/f008/plan.md §2.1/§2.3):
// CARBON-defined file-scope globals of imported C++ class types — the
// SPECIALIZATION-typed shape that was measured to compile but link with
// `undefined symbol: _Cgcount.Main.1` (real `<atomic>`,
// fork/design-sprint/threading-atomics.md:103), next to the plain
// imported-class control that links fine (matrix row 14). The autoupdated
// IR dump shows, in a reviewed diff, whether `g`'s global is one defined
// object, a bare declaration missed by the definition walk, or a duplicate
// `.1`-suffixed pair — distinguishing fix-site hypotheses H1-H3. Dump-only:
// this golden never LINKS, so it cannot adjudicate H0 ("fixed upstream");
// H0 is settled by F8c's first-step runner run of the real-header pair
// cpp_atomic_global_counter_diff (plan §2.3, adjudication D). The imported
// direction (C++-owned globals, no Carbon-side definition emitted) is
// covered by globals.carbon and must not move (plan §5 R-5).

// --- box.h

template <typename T> struct Box {
  T value;
};

struct Plain {
  int n;
};

// --- carbon_defined_globals.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

// The defect shape: a file-scope Carbon var typed by an imported C++
// template specialization.
var g: Cpp.Box(i32);

// The control: a plain imported-class-typed Carbon global.
var m: Cpp.Plain;

fn ReadSpecialized() -> i32 {
  return g.value;
}

fn ReadPlain() -> i32 {
  return m.n;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'carbon_defined_globals.carbon'
// CHECK:STDOUT: source_filename = "carbon_defined_globals.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Cg.Main = global [4 x i8] zeroinitializer
// CHECK:STDOUT: @_Cm.Main = global [4 x i8] zeroinitializer
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN3BoxIiEC1Ev.carbon_thunk.(ptr noundef %return) #0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !12
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !12
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_COp:thunk:Default.9d4aa446d9154817.Core:Box.Cpp"(ptr sret([4 x i8]) %return) #1 !dbg !15 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN3BoxIiEC1Ev.carbon_thunk.(ptr %return), !dbg !20
// CHECK:STDOUT:   ret void, !dbg !20
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN5PlainC1Ev.carbon_thunk.(ptr noundef %return) #0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !21
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !21
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_COp:thunk:Default.c2877a28d52dd366.Core:Plain.Cpp"(ptr sret([4 x i8]) %return) #1 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN5PlainC1Ev.carbon_thunk.(ptr %return), !dbg !24
// CHECK:STDOUT:   ret void, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CReadSpecialized.Main() #2 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14_11.2 = load i32, ptr @_Cg.Main, align 4, !dbg !29
// CHECK:STDOUT:   ret i32 %.loc14_11.2, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CReadPlain.Main() #2 !dbg !31 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc18_11.2 = load i32, ptr @_Cm.Main, align 4, !dbg !32
// CHECK:STDOUT:   ret i32 %.loc18_11.2, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #2 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.0e44c8e509b492f6"(ptr @_Cg.Main), !dbg !37
// CHECK:STDOUT:   call void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.d0df4221f5d23f36"(ptr @_Cm.Main), !dbg !38
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.0e44c8e509b492f6"(ptr sret([4 x i8]) %return) #2 !dbg !40 {
// CHECK:STDOUT:   call void @"_COp:thunk:Default.9d4aa446d9154817.Core:Box.Cpp"(ptr %return), !dbg !42
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.d0df4221f5d23f36"(ptr sret([4 x i8]) %return) #2 !dbg !44 {
// CHECK:STDOUT:   call void @"_COp:thunk:Default.c2877a28d52dd366.Core:Plain.Cpp"(ptr %return), !dbg !45
// CHECK:STDOUT:   ret void, !dbg !46
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #1 = { alwaysinline nounwind }
// CHECK:STDOUT: attributes #2 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3, !4, !5, !6}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!7}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "carbon_defined_globals.carbon", directory: "")
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
// CHECK:STDOUT: !13 = !{!"p1 _ZTS3BoxIiE", !14, i64 0}
// CHECK:STDOUT: !14 = !{!"any pointer", !10, i64 0}
// CHECK:STDOUT: !15 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:Default.9d4aa446d9154817.Core:Box.Cpp", scope: null, file: !16, line: 2, type: !17, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !16 = !DIFile(filename: "./box.h", directory: "")
// CHECK:STDOUT: !17 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !18 = !{!19}
// CHECK:STDOUT: !19 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !20 = !DILocation(line: 2, column: 30, scope: !15)
// CHECK:STDOUT: !21 = !{!22, !22, i64 0}
// CHECK:STDOUT: !22 = !{!"p1 _ZTS5Plain", !14, i64 0}
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:Default.c2877a28d52dd366.Core:Plain.Cpp", scope: null, file: !16, line: 6, type: !17, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !24 = !DILocation(line: 6, column: 8, scope: !23)
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "ReadSpecialized", linkageName: "_CReadSpecialized.Main", scope: null, file: !1, line: 13, type: !26, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !26 = !DISubroutineType(types: !27)
// CHECK:STDOUT: !27 = !{!28}
// CHECK:STDOUT: !28 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !29 = !DILocation(line: 14, column: 10, scope: !25)
// CHECK:STDOUT: !30 = !DILocation(line: 14, column: 3, scope: !25)
// CHECK:STDOUT: !31 = distinct !DISubprogram(name: "ReadPlain", linkageName: "_CReadPlain.Main", scope: null, file: !1, line: 17, type: !26, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !32 = !DILocation(line: 18, column: 10, scope: !31)
// CHECK:STDOUT: !33 = !DILocation(line: 18, column: 3, scope: !31)
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !1, type: !35, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !35 = !DISubroutineType(types: !36)
// CHECK:STDOUT: !36 = !{null}
// CHECK:STDOUT: !37 = !DILocation(line: 8, column: 1, scope: !34)
// CHECK:STDOUT: !38 = !DILocation(line: 11, column: 1, scope: !34)
// CHECK:STDOUT: !39 = !DILocation(line: 0, scope: !34)
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "Op", linkageName: "_COp.51f3fb62cb986374:DefaultOrUnformed.Core.0e44c8e509b492f6", scope: null, file: !41, line: 9, type: !17, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !41 = !DIFile(filename: "min_prelude/parts/default.carbon", directory: "")
// CHECK:STDOUT: !42 = !DILocation(line: 9, column: 28, scope: !40)
// CHECK:STDOUT: !43 = !DILocation(line: 9, column: 21, scope: !40)
// CHECK:STDOUT: !44 = distinct !DISubprogram(name: "Op", linkageName: "_COp.51f3fb62cb986374:DefaultOrUnformed.Core.d0df4221f5d23f36", scope: null, file: !41, line: 9, type: !17, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !45 = !DILocation(line: 9, column: 28, scope: !44)
// CHECK:STDOUT: !46 = !DILocation(line: 9, column: 21, scope: !44)
// CHECK:STDOUT:

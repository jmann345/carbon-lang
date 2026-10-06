// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --clang-arg=-fno-exceptions
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/class/import/union_init.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/class/import/union_init.carbon

// Designated initialization of an imported C++ union (fork/unions/plan.md
// UN-2, §4.B): the same lowering as a native union — the union's byte-array
// storage, one `store i32` through a byte-offset GEP at offset zero, and a
// read of the other member through the same offset.

// --- pair.h

union Pair {
  int a;
  int b;
};

// --- designated_init.carbon

library "[[@TEST_NAME]]";

import Cpp library "pair.h";

fn F() -> i32 {
  var u: Cpp.Pair = {.a = 1};
  return u.b;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'designated_init.carbon'
// CHECK:STDOUT: source_filename = "designated_init.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CF.Main() #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %u.var = alloca [4 x i8], align 4, !dbg !15
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %u.var), !dbg !15
// CHECK:STDOUT:   %.loc7_28.3.a = getelementptr inbounds nuw [4 x i8], ptr %u.var, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   store i32 1, ptr %.loc7_28.3.a, align 4, !dbg !16
// CHECK:STDOUT:   %.loc8_11.1.b = getelementptr inbounds nuw [4 x i8], ptr %u.var, i32 0, i32 0, !dbg !18
// CHECK:STDOUT:   %.loc8_11.2 = load i32, ptr %.loc8_11.1.b, align 4, !dbg !18
// CHECK:STDOUT:   call void @"_CSelfDestruct.23657c20054f6653:core.Destroy.Core"(ptr %u.var), !dbg !15
// CHECK:STDOUT:   ret i32 %.loc8_11.2, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.23657c20054f6653:core.Destroy.Core"(ptr %self) #0 !dbg !20 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !22
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!24, !25, !26, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!31}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "designated_init.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{null, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !4, line: 6, type: !8, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !15 = !DILocation(line: 7, column: 3, scope: !12)
// CHECK:STDOUT: !16 = !DILocation(line: 7, column: 21, scope: !12)
// CHECK:STDOUT: !18 = !DILocation(line: 8, column: 10, scope: !12)
// CHECK:STDOUT: !19 = !DILocation(line: 8, column: 3, scope: !12)
// CHECK:STDOUT: !20 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.23657c20054f6653:core.Destroy.Core", scope: null, file: !4, line: 7, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !23)
// CHECK:STDOUT: !21 = !DILocalVariable(arg: 1, scope: !20, type: !9)
// CHECK:STDOUT: !22 = !DILocation(line: 7, column: 3, scope: !20)
// CHECK:STDOUT: !23 = !{!21}
// CHECK:STDOUT: !24 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !25 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !26 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !27 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !28 = !{!"omnipotent char", !27, i64 0}
// CHECK:STDOUT: !29 = !{!"int", !28, i64 0}
// CHECK:STDOUT: !30 = !{!"__libc_errno", !29, i64 0}
// CHECK:STDOUT: !31 = !{!30, !29, i64 0}
// CHECK:STDOUT:

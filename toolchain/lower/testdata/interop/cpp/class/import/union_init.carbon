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
// CHECK:STDOUT:   %u.var = alloca [4 x i8], align 4, !dbg !16
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %u.var), !dbg !16
// CHECK:STDOUT:   %.loc7_28.3.a = getelementptr inbounds nuw [4 x i8], ptr %u.var, i32 0, i32 0, !dbg !17
// CHECK:STDOUT:   store i32 1, ptr %.loc7_28.3.a, align 4, !dbg !17
// CHECK:STDOUT:   %.loc8_11.1.b = getelementptr inbounds nuw [4 x i8], ptr %u.var, i32 0, i32 0, !dbg !18
// CHECK:STDOUT:   %.loc8_11.2 = load i32, ptr %.loc8_11.1.b, align 4, !dbg !18
// CHECK:STDOUT:   ret i32 %.loc8_11.2, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3, !4, !5, !6}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!7}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "designated_init.carbon", directory: "")
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
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !1, line: 6, type: !13, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{!15}
// CHECK:STDOUT: !15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !16 = !DILocation(line: 7, column: 3, scope: !12)
// CHECK:STDOUT: !17 = !DILocation(line: 7, column: 21, scope: !12)
// CHECK:STDOUT: !18 = !DILocation(line: 8, column: 10, scope: !12)
// CHECK:STDOUT: !19 = !DILocation(line: 8, column: 3, scope: !12)
// CHECK:STDOUT:

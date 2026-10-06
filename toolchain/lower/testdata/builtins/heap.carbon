// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/builtins/heap.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/builtins/heap.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): `heap.allocate` lowers to
// `call { i64, i1 } @llvm.umul.with.overflow.i64(i64 %n, i64 4)` (the element
// size; the wrap bit is `extractvalue ..., 1`), a zero guard (`select`),
// `call ptr @malloc(i64 ...)`, and `select i1 %heap.bytes.overflow, ptr null,
// ptr %heap.block` so a wrapped byte count takes the null-`malloc` path;
// `heap.free` lowers to `call void @free(ptr %p)`.

fn Alloc(generic T: type, n: i64) -> Core.MaybeUnformed(T*) = "heap.allocate";
fn Free[T: type](p: T*) = "heap.free";

fn A(n: i64) -> Core.MaybeUnformed(i32*) {
  return Alloc(i32, n);
}

fn Fr(p: i32*) {
  Free(p);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'heap.carbon'
// CHECK:STDOUT: source_filename = "heap.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %self) #0 !dbg !13 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !15
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define ptr @_CA.Main(i64 %n) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Alloc.call.heap.bytes.mul = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 %n, i64 4), !dbg !23
// CHECK:STDOUT:   %Alloc.call.heap.bytes = extractvalue { i64, i1 } %Alloc.call.heap.bytes.mul, 0, !dbg !23
// CHECK:STDOUT:   %Alloc.call.heap.bytes.overflow = extractvalue { i64, i1 } %Alloc.call.heap.bytes.mul, 1, !dbg !23
// CHECK:STDOUT:   %Alloc.call.heap.bytes.is_zero = icmp eq i64 %Alloc.call.heap.bytes, 0, !dbg !23
// CHECK:STDOUT:   %Alloc.call.heap.bytes.nonzero = select i1 %Alloc.call.heap.bytes.is_zero, i64 1, i64 %Alloc.call.heap.bytes, !dbg !23
// CHECK:STDOUT:   %Alloc.call.heap.block = call ptr @malloc(i64 %Alloc.call.heap.bytes.nonzero), !dbg !23
// CHECK:STDOUT:   %Alloc.call.heap.result = select i1 %Alloc.call.heap.bytes.overflow, ptr null, ptr %Alloc.call.heap.block, !dbg !23
// CHECK:STDOUT:   ret ptr %Alloc.call.heap.result, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CFr.Main(ptr %p) #0 !dbg !26 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @free(ptr %p), !dbg !30
// CHECK:STDOUT:   ret void, !dbg !31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
// CHECK:STDOUT: declare { i64, i1 } @llvm.umul.with.overflow.i64(i64, i64) #1
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @malloc(i64)
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @free(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "heap.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{null, !8}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = !{!8, !6}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d088c7eb746488be:core.Destroy.Core", scope: null, file: !4, line: 23, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !16)
// CHECK:STDOUT: !14 = !DILocalVariable(arg: 1, scope: !13, type: !8)
// CHECK:STDOUT: !15 = !DILocation(line: 23, column: 17, scope: !13)
// CHECK:STDOUT: !16 = !{!14}
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "A", linkageName: "_CA.Main", scope: null, file: !4, line: 23, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !25)
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !17, type: !6)
// CHECK:STDOUT: !23 = !DILocation(line: 24, column: 10, scope: !17)
// CHECK:STDOUT: !24 = !DILocation(line: 24, column: 3, scope: !17)
// CHECK:STDOUT: !25 = !{!18}
// CHECK:STDOUT: !26 = distinct !DISubprogram(name: "Fr", linkageName: "_CFr.Main", scope: null, file: !4, line: 27, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !32)
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 1, scope: !26, type: !8)
// CHECK:STDOUT: !30 = !DILocation(line: 28, column: 3, scope: !26)
// CHECK:STDOUT: !31 = !DILocation(line: 27, column: 1, scope: !26)
// CHECK:STDOUT: !32 = !{!27}
// CHECK:STDOUT:

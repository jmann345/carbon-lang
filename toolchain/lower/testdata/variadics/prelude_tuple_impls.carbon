// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/prelude_tuple_impls.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/prelude_tuple_impls.carbon

// --- copy_op.carbon
library "[[@TEST_NAME]]";

fn Call(t: (i32, i32, i32, i32)) -> (i32, i32, i32, i32) {
  return t.(Core.Copy.Op)();
}

// --- eq.carbon
library "[[@TEST_NAME]]";

fn Call(a: (i32, i64), b: (i32, i64)) -> bool {
  return a == b;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'copy_op.carbon'
// CHECK:STDOUT: source_filename = "copy_op.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr sret({ i32, i32, i32, i32 }) %return, ptr %t) #0 !dbg !10 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_COp.e97d0ca1040339b6:Copy.Core.7f01fdff52cf28f6"(ptr %return, ptr %t), !dbg !15
// CHECK:STDOUT:   ret void, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.e97d0ca1040339b6:Copy.Core.7f01fdff52cf28f6"(ptr sret({ i32, i32, i32, i32 }) %return, ptr %self) #0 !dbg !19 {
// CHECK:STDOUT:   %pack.elem = getelementptr inbounds { i32, i32, i32, i32 }, ptr %self, i32 0, i32 0, !dbg !29
// CHECK:STDOUT:   %pack.elem.load = load i32, ptr %pack.elem, align 4, !dbg !29
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32, i32, i32, i32 }, ptr %return, i32 0, i32 0, !dbg !29
// CHECK:STDOUT:   store i32 %pack.elem.load, ptr %tuple.elem, align 4, !dbg !29
// CHECK:STDOUT:   %pack.elem1 = getelementptr inbounds { i32, i32, i32, i32 }, ptr %self, i32 0, i32 1, !dbg !29
// CHECK:STDOUT:   %pack.elem.load2 = load i32, ptr %pack.elem1, align 4, !dbg !29
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { i32, i32, i32, i32 }, ptr %return, i32 0, i32 1, !dbg !29
// CHECK:STDOUT:   store i32 %pack.elem.load2, ptr %tuple.elem3, align 4, !dbg !29
// CHECK:STDOUT:   %pack.elem4 = getelementptr inbounds { i32, i32, i32, i32 }, ptr %self, i32 0, i32 2, !dbg !29
// CHECK:STDOUT:   %pack.elem.load5 = load i32, ptr %pack.elem4, align 4, !dbg !29
// CHECK:STDOUT:   %tuple.elem6 = getelementptr inbounds nuw { i32, i32, i32, i32 }, ptr %return, i32 0, i32 2, !dbg !29
// CHECK:STDOUT:   store i32 %pack.elem.load5, ptr %tuple.elem6, align 4, !dbg !29
// CHECK:STDOUT:   %pack.elem7 = getelementptr inbounds { i32, i32, i32, i32 }, ptr %self, i32 0, i32 3, !dbg !29
// CHECK:STDOUT:   %pack.elem.load8 = load i32, ptr %pack.elem7, align 4, !dbg !29
// CHECK:STDOUT:   %tuple.elem9 = getelementptr inbounds nuw { i32, i32, i32, i32 }, ptr %return, i32 0, i32 3, !dbg !29
// CHECK:STDOUT:   store i32 %pack.elem.load8, ptr %tuple.elem9, align 4, !dbg !29
// CHECK:STDOUT:   ret void, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "copy_op.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !4, line: 3, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !17)
// CHECK:STDOUT: !11 = !DILocalVariable(arg: 1, scope: !10, type: !7)
// CHECK:STDOUT: !15 = !DILocation(line: 4, column: 10, scope: !10)
// CHECK:STDOUT: !16 = !DILocation(line: 4, column: 3, scope: !10)
// CHECK:STDOUT: !17 = !{!11}
// CHECK:STDOUT: !18 = !DIFile(filename: "{{.*}}/prelude/copy.carbon", directory: "")
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "Op", linkageName: "_COp.e97d0ca1040339b6:Copy.Core.7f01fdff52cf28f6", scope: null, file: !18, line: 51, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !31)
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !19, type: !7)
// CHECK:STDOUT: !29 = !DILocation(line: 53, column: 12, scope: !19)
// CHECK:STDOUT: !30 = !DILocation(line: 53, column: 5, scope: !19)
// CHECK:STDOUT: !31 = !{!20}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'eq.carbon'
// CHECK:STDOUT: source_filename = "eq.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i1 @_CCall.Main(ptr %a, ptr %b) #0 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.type.as.EqWith.impl.Equal.call = call i1 @"_CEqual.4239cb399c0b0701:EqWith.5008e993efea257a.Core.3048bfcf64822c8f"(ptr %a, ptr %b), !dbg !44
// CHECK:STDOUT:   ret i1 %tuple.type.as.EqWith.impl.Equal.call, !dbg !46
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CEqual.4239cb399c0b0701:EqWith.5008e993efea257a.Core.3048bfcf64822c8f"(ptr %self, ptr %other) #0 !dbg !49 {
// CHECK:STDOUT:   %pack.elem = getelementptr inbounds <{ <{ i32, [4 x i8] }>, i64 }>, ptr %self, i32 0, i32 0, !dbg !65
// CHECK:STDOUT:   %pack.elem.load = load i32, ptr %pack.elem, align 4, !dbg !65
// CHECK:STDOUT:   %pack.elem1 = getelementptr inbounds <{ <{ i32, [4 x i8] }>, i64 }>, ptr %other, i32 0, i32 0, !dbg !66
// CHECK:STDOUT:   %pack.elem.load2 = load i32, ptr %pack.elem1, align 4, !dbg !66
// CHECK:STDOUT:   %1 = icmp eq i32 %pack.elem.load, %pack.elem.load2, !dbg !65
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !67
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !68
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 false, !dbg !69
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %0
// CHECK:STDOUT:   br label %pack.next, !dbg !64
// CHECK:STDOUT:
// CHECK:STDOUT: pack.next:                                        ; preds = %4
// CHECK:STDOUT:   %pack.elem4 = getelementptr inbounds <{ <{ i32, [4 x i8] }>, i64 }>, ptr %self, i32 0, i32 1, !dbg !65
// CHECK:STDOUT:   %pack.elem.load5 = load i64, ptr %pack.elem4, align 8, !dbg !65
// CHECK:STDOUT:   %pack.elem6 = getelementptr inbounds <{ <{ i32, [4 x i8] }>, i64 }>, ptr %other, i32 0, i32 1, !dbg !66
// CHECK:STDOUT:   %pack.elem.load7 = load i64, ptr %pack.elem6, align 8, !dbg !66
// CHECK:STDOUT:   %5 = icmp eq i64 %pack.elem.load5, %pack.elem.load7, !dbg !65
// CHECK:STDOUT:   %6 = xor i1 %5, true, !dbg !67
// CHECK:STDOUT:   br i1 %6, label %7, label %8, !dbg !68
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %pack.next
// CHECK:STDOUT:   ret i1 false, !dbg !69
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %pack.next
// CHECK:STDOUT:   br label %pack.next3, !dbg !64
// CHECK:STDOUT:
// CHECK:STDOUT: pack.next3:                                       ; preds = %8
// CHECK:STDOUT:   ret i1 true, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!33}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !32 = !DIFile(filename: "eq.carbon", directory: "")
// CHECK:STDOUT: !33 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !32, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !35 = !{!7, !7, !7}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !32, line: 3, type: !36, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !47)
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !37, type: !7)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 2, scope: !37, type: !7)
// CHECK:STDOUT: !44 = !DILocation(line: 4, column: 10, scope: !37)
// CHECK:STDOUT: !46 = !DILocation(line: 4, column: 3, scope: !37)
// CHECK:STDOUT: !47 = !{!38, !39}
// CHECK:STDOUT: !48 = !DIFile(filename: "{{.*}}/prelude/operators/comparison.carbon", directory: "")
// CHECK:STDOUT: !49 = distinct !DISubprogram(name: "Equal", linkageName: "_CEqual.4239cb399c0b0701:EqWith.5008e993efea257a.Core.3048bfcf64822c8f", scope: null, file: !48, line: 68, type: !36, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !71)
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !49, type: !7)
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 2, scope: !49, type: !7)
// CHECK:STDOUT: !64 = !DILocation(line: 71, column: 5, scope: !49)
// CHECK:STDOUT: !65 = !DILocation(line: 71, column: 18, scope: !49)
// CHECK:STDOUT: !66 = !DILocation(line: 71, column: 28, scope: !49)
// CHECK:STDOUT: !67 = !DILocation(line: 71, column: 13, scope: !49)
// CHECK:STDOUT: !68 = !DILocation(line: 71, column: 12, scope: !49)
// CHECK:STDOUT: !69 = !DILocation(line: 72, column: 7, scope: !49)
// CHECK:STDOUT: !70 = !DILocation(line: 74, column: 5, scope: !49)
// CHECK:STDOUT: !71 = !{!50, !51}
// CHECK:STDOUT:

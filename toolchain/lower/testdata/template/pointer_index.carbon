// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/template/pointer_index.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/template/pointer_index.carbon

// --- deref_param.carbon
library "[[@TEST_NAME]]";

fn Deref[template T: type](p: T) -> i32 {
  return *p;
}

fn Use(n: i32*) -> i32 {
  return Deref(n);
}

// --- addr_of_member.carbon
library "[[@TEST_NAME]]";

class Counter {
  var n: i32;
}

fn Bump[template T: type](ref x: T) -> i32 {
  let q: i32* = &x.n;
  *q += 1;
  return x.n;
}

fn Use(ref c: Counter) -> i32 {
  return Bump(ref c);
}

// --- tuple_index_param.carbon
library "[[@TEST_NAME]]";

fn Second[template T: type](p: T) -> i32 {
  return p.1;
}

fn Use(t: (i32, i32)) -> i32 {
  return Second(t);
}

// --- array_index_param.carbon
library "[[@TEST_NAME]]";

fn At1[template T: type](a: T) -> i32 {
  return a[1];
}

fn Use(a: array(i32, 3)) -> i32 {
  return At1(a);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'deref_param.carbon'
// CHECK:STDOUT: source_filename = "deref_param.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main(ptr %n) #0 !dbg !10 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Deref.call = call i32 @_CDeref.Main.213fc045a4740497(ptr %n), !dbg !16
// CHECK:STDOUT:   ret i32 %Deref.call, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CDeref.Main.213fc045a4740497(ptr %p) #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.821 = load i32, ptr %p, align 4, !dbg !25
// CHECK:STDOUT:   ret i32 %.821, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "deref_param.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!6, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !4, line: 7, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !18)
// CHECK:STDOUT: !11 = !DILocalVariable(arg: 1, scope: !10, type: !7)
// CHECK:STDOUT: !16 = !DILocation(line: 8, column: 10, scope: !10)
// CHECK:STDOUT: !17 = !DILocation(line: 8, column: 3, scope: !10)
// CHECK:STDOUT: !18 = !{!11}
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "Deref", linkageName: "_CDeref.Main.213fc045a4740497", scope: null, file: !4, line: 3, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !27)
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !19, type: !7)
// CHECK:STDOUT: !25 = !DILocation(line: 4, column: 10, scope: !19)
// CHECK:STDOUT: !26 = !DILocation(line: 4, column: 3, scope: !19)
// CHECK:STDOUT: !27 = !{!20}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'addr_of_member.carbon'
// CHECK:STDOUT: source_filename = "addr_of_member.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main(ptr %c) #0 !dbg !30 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Bump.call = call i32 @_CBump.Main.c5b2f1608a26f4c6(ptr %c), !dbg !37
// CHECK:STDOUT:   ret i32 %Bump.call, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CBump.Main.c5b2f1608a26f4c6(ptr %x) #0 !dbg !40 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.f4166b.2.n = getelementptr inbounds nuw { i32 }, ptr %x, i32 0, i32 0, !dbg !45
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.call = load i32, ptr %.f4166b.2.n, align 4, !dbg !50
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.call1 = add i32 %Int.as.AddAssignWith.impl.Op.call, 1, !dbg !50
// CHECK:STDOUT:   store i32 %Int.as.AddAssignWith.impl.Op.call1, ptr %.f4166b.2.n, align 4, !dbg !50
// CHECK:STDOUT:   %.f4166b.1.n = getelementptr inbounds nuw { i32 }, ptr %x, i32 0, i32 0, !dbg !51
// CHECK:STDOUT:   %.eab = load i32, ptr %.f4166b.1.n, align 4, !dbg !51
// CHECK:STDOUT:   ret i32 %.eab, !dbg !52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!29}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!6, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !28 = !DIFile(filename: "addr_of_member.carbon", directory: "")
// CHECK:STDOUT: !29 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !28, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !30 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !28, line: 13, type: !9, spFlags: DISPFlagDefinition, unit: !29, retainedNodes: !39)
// CHECK:STDOUT: !31 = !DILocalVariable(arg: 1, scope: !30, type: !7)
// CHECK:STDOUT: !37 = !DILocation(line: 14, column: 10, scope: !30)
// CHECK:STDOUT: !38 = !DILocation(line: 14, column: 3, scope: !30)
// CHECK:STDOUT: !39 = !{!31}
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "Bump", linkageName: "_CBump.Main.c5b2f1608a26f4c6", scope: null, file: !28, line: 7, type: !9, spFlags: DISPFlagDefinition, unit: !29, retainedNodes: !53)
// CHECK:STDOUT: !41 = !DILocalVariable(arg: 1, scope: !40, type: !7)
// CHECK:STDOUT: !45 = !DILocation(line: 8, column: 18, scope: !40)
// CHECK:STDOUT: !50 = !DILocation(line: 9, column: 3, scope: !40)
// CHECK:STDOUT: !51 = !DILocation(line: 10, column: 10, scope: !40)
// CHECK:STDOUT: !52 = !DILocation(line: 10, column: 3, scope: !40)
// CHECK:STDOUT: !53 = !{!41}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'tuple_index_param.carbon'
// CHECK:STDOUT: source_filename = "tuple_index_param.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main(ptr %t) #0 !dbg !56 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Second.call = call i32 @_CSecond.Main.00f31208999b670d(ptr %t), !dbg !62
// CHECK:STDOUT:   ret i32 %Second.call, !dbg !63
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CSecond.Main.00f31208999b670d(ptr %p) #0 !dbg !65 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %p, i32 0, i32 1, !dbg !70
// CHECK:STDOUT:   %tuple.elem1.tuple.elem.load = load i32, ptr %tuple.elem1.tuple.elem, align 4, !dbg !70
// CHECK:STDOUT:   ret i32 %tuple.elem1.tuple.elem.load, !dbg !71
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!55}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!6, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !54 = !DIFile(filename: "tuple_index_param.carbon", directory: "")
// CHECK:STDOUT: !55 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !54, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !54, line: 7, type: !9, spFlags: DISPFlagDefinition, unit: !55, retainedNodes: !64)
// CHECK:STDOUT: !57 = !DILocalVariable(arg: 1, scope: !56, type: !7)
// CHECK:STDOUT: !62 = !DILocation(line: 8, column: 10, scope: !56)
// CHECK:STDOUT: !63 = !DILocation(line: 8, column: 3, scope: !56)
// CHECK:STDOUT: !64 = !{!57}
// CHECK:STDOUT: !65 = distinct !DISubprogram(name: "Second", linkageName: "_CSecond.Main.00f31208999b670d", scope: null, file: !54, line: 3, type: !9, spFlags: DISPFlagDefinition, unit: !55, retainedNodes: !72)
// CHECK:STDOUT: !66 = !DILocalVariable(arg: 1, scope: !65, type: !7)
// CHECK:STDOUT: !70 = !DILocation(line: 4, column: 10, scope: !65)
// CHECK:STDOUT: !71 = !DILocation(line: 4, column: 3, scope: !65)
// CHECK:STDOUT: !72 = !{!66}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'array_index_param.carbon'
// CHECK:STDOUT: source_filename = "array_index_param.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main(ptr %a) #0 !dbg !75 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %At1.call = call i32 @_CAt1.Main.d38040534c930e1d(ptr %a), !dbg !81
// CHECK:STDOUT:   ret i32 %At1.call, !dbg !82
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CAt1.Main.d38040534c930e1d(ptr %a) #0 !dbg !84 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.b34.array.index = getelementptr inbounds [3 x i32], ptr %a, i32 0, i32 1, !dbg !89
// CHECK:STDOUT:   %.85a = load i32, ptr %.b34.array.index, align 4, !dbg !89
// CHECK:STDOUT:   ret i32 %.85a, !dbg !90
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!74}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!6, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !73 = !DIFile(filename: "array_index_param.carbon", directory: "")
// CHECK:STDOUT: !74 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !73, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !75 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !73, line: 7, type: !9, spFlags: DISPFlagDefinition, unit: !74, retainedNodes: !83)
// CHECK:STDOUT: !76 = !DILocalVariable(arg: 1, scope: !75, type: !7)
// CHECK:STDOUT: !81 = !DILocation(line: 8, column: 10, scope: !75)
// CHECK:STDOUT: !82 = !DILocation(line: 8, column: 3, scope: !75)
// CHECK:STDOUT: !83 = !{!76}
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "At1", linkageName: "_CAt1.Main.d38040534c930e1d", scope: null, file: !73, line: 3, type: !9, spFlags: DISPFlagDefinition, unit: !74, retainedNodes: !91)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !84, type: !7)
// CHECK:STDOUT: !89 = !DILocation(line: 4, column: 10, scope: !84)
// CHECK:STDOUT: !90 = !DILocation(line: 4, column: 3, scope: !84)
// CHECK:STDOUT: !91 = !{!85}
// CHECK:STDOUT:

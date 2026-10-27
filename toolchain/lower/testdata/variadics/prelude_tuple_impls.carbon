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

// --- generic_elements.carbon
library "[[@TEST_NAME]]";

fn Dup[T: Core.Copy](x: T) -> (T, T) {
  let p: (T, T) = (x, x);
  return p.(Core.Copy.Op)();
}

fn Before[T: Core.Ordered, U: Core.Ordered](a: (T, U), b: (T, U)) -> bool {
  return a < b;
}

fn Call(a: (i32, i64), b: (i32, i64)) -> bool {
  return Before(Dup(a.0), Dup(b.0)) and Before(a, b);
}

// --- copy_class_element.carbon
library "[[@TEST_NAME]]";

fn Sink(n: i32);

class C {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self {
      Sink(self.n);
      return {.n = self.n};
    }
  }
}

fn Call(t: (C, i32)) -> (C, i32) {
  return t.(Core.Copy.Op)();
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
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'generic_elements.carbon'
// CHECK:STDOUT: source_filename = "generic_elements.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i1 @_CCall.Main(ptr %a, ptr %b) #0 !dbg !78 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc13_24.3.temp = alloca { i32, i32 }, align 4, !dbg !86
// CHECK:STDOUT:   %.loc13_34.3.temp = alloca { i32, i32 }, align 4, !dbg !90
// CHECK:STDOUT:   %tuple.loc13_24 = alloca { i32, i32 }, align 4, !dbg !86
// CHECK:STDOUT:   %tuple.loc13_34 = alloca { i32, i32 }, align 4, !dbg !90
// CHECK:STDOUT:   %tuple.elem0.loc13_22.tuple.elem = getelementptr inbounds nuw <{ <{ i32, [4 x i8] }>, i64 }>, ptr %a, i32 0, i32 0, !dbg !85
// CHECK:STDOUT:   %tuple.elem0.loc13_22.tuple.elem.load = load i32, ptr %tuple.elem0.loc13_22.tuple.elem, align 4, !dbg !85
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc13_24.3.temp), !dbg !86
// CHECK:STDOUT:   call void @_CDup.Main.4d6ceefeb7f772f4(ptr %.loc13_24.3.temp, i32 %tuple.elem0.loc13_22.tuple.elem.load), !dbg !86
// CHECK:STDOUT:   %tuple.elem0.loc13_32.tuple.elem = getelementptr inbounds nuw <{ <{ i32, [4 x i8] }>, i64 }>, ptr %b, i32 0, i32 0, !dbg !89
// CHECK:STDOUT:   %tuple.elem0.loc13_32.tuple.elem.load = load i32, ptr %tuple.elem0.loc13_32.tuple.elem, align 4, !dbg !89
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc13_34.3.temp), !dbg !90
// CHECK:STDOUT:   call void @_CDup.Main.4d6ceefeb7f772f4(ptr %.loc13_34.3.temp, i32 %tuple.elem0.loc13_32.tuple.elem.load), !dbg !90
// CHECK:STDOUT:   %tuple.elem0.loc13_24.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc13_24.3.temp, i32 0, i32 0, !dbg !86
// CHECK:STDOUT:   %.loc13_24.5 = load i32, ptr %tuple.elem0.loc13_24.tuple.elem, align 4, !dbg !86
// CHECK:STDOUT:   %tuple.elem1.loc13_24.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc13_24.3.temp, i32 0, i32 1, !dbg !86
// CHECK:STDOUT:   %.loc13_24.6 = load i32, ptr %tuple.elem1.loc13_24.tuple.elem, align 4, !dbg !86
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %tuple.loc13_24), !dbg !86
// CHECK:STDOUT:   %tuple.loc13_241 = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.loc13_24, i32 0, i32 0, !dbg !86
// CHECK:STDOUT:   store i32 %.loc13_24.5, ptr %tuple.loc13_241, align 4, !dbg !86
// CHECK:STDOUT:   %tuple.loc13_242 = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.loc13_24, i32 0, i32 1, !dbg !86
// CHECK:STDOUT:   store i32 %.loc13_24.6, ptr %tuple.loc13_242, align 4, !dbg !86
// CHECK:STDOUT:   %tuple.elem0.loc13_34.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc13_34.3.temp, i32 0, i32 0, !dbg !90
// CHECK:STDOUT:   %.loc13_34.5 = load i32, ptr %tuple.elem0.loc13_34.tuple.elem, align 4, !dbg !90
// CHECK:STDOUT:   %tuple.elem1.loc13_34.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc13_34.3.temp, i32 0, i32 1, !dbg !90
// CHECK:STDOUT:   %.loc13_34.6 = load i32, ptr %tuple.elem1.loc13_34.tuple.elem, align 4, !dbg !90
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %tuple.loc13_34), !dbg !90
// CHECK:STDOUT:   %tuple.loc13_343 = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.loc13_34, i32 0, i32 0, !dbg !90
// CHECK:STDOUT:   store i32 %.loc13_34.5, ptr %tuple.loc13_343, align 4, !dbg !90
// CHECK:STDOUT:   %tuple.loc13_344 = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.loc13_34, i32 0, i32 1, !dbg !90
// CHECK:STDOUT:   store i32 %.loc13_34.6, ptr %tuple.loc13_344, align 4, !dbg !90
// CHECK:STDOUT:   %Before.call.loc13_35 = call i1 @_CBefore.Main.e6f84856f77e581b(ptr %tuple.loc13_24, ptr %tuple.loc13_34), !dbg !91
// CHECK:STDOUT:   br i1 %Before.call.loc13_35, label %and.rhs, label %and.result, !dbg !91
// CHECK:STDOUT:
// CHECK:STDOUT: and.rhs:                                          ; preds = %entry
// CHECK:STDOUT:   %Before.call.loc13_52 = call i1 @_CBefore.Main.6b7f7013dcf996f6(ptr %a, ptr %b), !dbg !94
// CHECK:STDOUT:   br label %and.result, !dbg !91
// CHECK:STDOUT:
// CHECK:STDOUT: and.result:                                       ; preds = %and.rhs, %entry
// CHECK:STDOUT:   %0 = phi i1 [ false, %entry ], [ %Before.call.loc13_52, %and.rhs ]
// CHECK:STDOUT:   call void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %.loc13_34.3.temp), !dbg !90
// CHECK:STDOUT:   call void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %.loc13_24.3.temp), !dbg !86
// CHECK:STDOUT:   ret i1 %0, !dbg !95
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !97 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !99
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !101 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !103
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !103
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !103
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !103
// CHECK:STDOUT:   ret void, !dbg !103
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !105 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self), !dbg !107
// CHECK:STDOUT:   ret void, !dbg !107
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDup.Main.4d6ceefeb7f772f4(ptr sret({ i32, i32 }) %return, i32 %x) #0 !dbg !109 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.loc4 = alloca { i32, i32 }, align 4, !dbg !116
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %tuple.loc4), !dbg !116
// CHECK:STDOUT:   %tuple.loc41 = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.loc4, i32 0, i32 0, !dbg !116
// CHECK:STDOUT:   store i32 %x, ptr %tuple.loc41, align 4, !dbg !116
// CHECK:STDOUT:   %tuple.loc42 = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.loc4, i32 0, i32 1, !dbg !116
// CHECK:STDOUT:   store i32 %x, ptr %tuple.loc42, align 4, !dbg !116
// CHECK:STDOUT:   call void @"_COp.e97d0ca1040339b6:Copy.Core.bea97fa60d13c05e"(ptr %return, ptr %tuple.loc4), !dbg !119
// CHECK:STDOUT:   ret void, !dbg !120
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CBefore.Main.e6f84856f77e581b(ptr %a, ptr %b) #0 !dbg !122 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %OrderedWith.WithSelf.Less.call = call i1 @"_CLess.4239cb399c0b0701:OrderedWith.5008e993efea257a.Core.491927d3f0b989ad"(ptr %a, ptr %b), !dbg !129
// CHECK:STDOUT:   ret i1 %OrderedWith.WithSelf.Less.call, !dbg !131
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CBefore.Main.6b7f7013dcf996f6(ptr %a, ptr %b) #0 !dbg !133 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %OrderedWith.WithSelf.Less.call = call i1 @"_CLess.4239cb399c0b0701:OrderedWith.5008e993efea257a.Core.1f77fd894fb81aaf"(ptr %a, ptr %b), !dbg !140
// CHECK:STDOUT:   ret i1 %OrderedWith.WithSelf.Less.call, !dbg !142
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.e97d0ca1040339b6:Copy.Core.bea97fa60d13c05e"(ptr sret({ i32, i32 }) %return, ptr %self) #0 !dbg !144 {
// CHECK:STDOUT:   %pack.elem = getelementptr inbounds { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !154
// CHECK:STDOUT:   %pack.elem.load = load i32, ptr %pack.elem, align 4, !dbg !154
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !154
// CHECK:STDOUT:   store i32 %pack.elem.load, ptr %tuple.elem, align 4, !dbg !154
// CHECK:STDOUT:   %pack.elem1 = getelementptr inbounds { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !154
// CHECK:STDOUT:   %pack.elem.load2 = load i32, ptr %pack.elem1, align 4, !dbg !154
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !154
// CHECK:STDOUT:   store i32 %pack.elem.load2, ptr %tuple.elem3, align 4, !dbg !154
// CHECK:STDOUT:   ret void, !dbg !155
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CLess.4239cb399c0b0701:OrderedWith.5008e993efea257a.Core.491927d3f0b989ad"(ptr %self, ptr %other) #0 !dbg !157 {
// CHECK:STDOUT:   %pack.elem = getelementptr inbounds { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !173
// CHECK:STDOUT:   %pack.elem.load = load i32, ptr %pack.elem, align 4, !dbg !173
// CHECK:STDOUT:   %pack.elem1 = getelementptr inbounds { i32, i32 }, ptr %other, i32 0, i32 0, !dbg !174
// CHECK:STDOUT:   %pack.elem.load2 = load i32, ptr %pack.elem1, align 4, !dbg !174
// CHECK:STDOUT:   %1 = icmp slt i32 %pack.elem.load, %pack.elem.load2, !dbg !173
// CHECK:STDOUT:   br i1 %1, label %2, label %3, !dbg !175
// CHECK:STDOUT:
// CHECK:STDOUT: 2:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 true, !dbg !176
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %pack.elem3 = getelementptr inbounds { i32, i32 }, ptr %other, i32 0, i32 0, !dbg !177
// CHECK:STDOUT:   %pack.elem.load4 = load i32, ptr %pack.elem3, align 4, !dbg !177
// CHECK:STDOUT:   %pack.elem5 = getelementptr inbounds { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !178
// CHECK:STDOUT:   %pack.elem.load6 = load i32, ptr %pack.elem5, align 4, !dbg !178
// CHECK:STDOUT:   %4 = icmp slt i32 %pack.elem.load4, %pack.elem.load6, !dbg !177
// CHECK:STDOUT:   br i1 %4, label %5, label %6, !dbg !179
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %3
// CHECK:STDOUT:   ret i1 false, !dbg !180
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %3
// CHECK:STDOUT:   br label %pack.next, !dbg !172
// CHECK:STDOUT:
// CHECK:STDOUT: pack.next:                                        ; preds = %6
// CHECK:STDOUT:   %pack.elem8 = getelementptr inbounds { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !173
// CHECK:STDOUT:   %pack.elem.load9 = load i32, ptr %pack.elem8, align 4, !dbg !173
// CHECK:STDOUT:   %pack.elem10 = getelementptr inbounds { i32, i32 }, ptr %other, i32 0, i32 1, !dbg !174
// CHECK:STDOUT:   %pack.elem.load11 = load i32, ptr %pack.elem10, align 4, !dbg !174
// CHECK:STDOUT:   %7 = icmp slt i32 %pack.elem.load9, %pack.elem.load11, !dbg !173
// CHECK:STDOUT:   br i1 %7, label %8, label %9, !dbg !175
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %pack.next
// CHECK:STDOUT:   ret i1 true, !dbg !176
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %pack.next
// CHECK:STDOUT:   %pack.elem12 = getelementptr inbounds { i32, i32 }, ptr %other, i32 0, i32 1, !dbg !177
// CHECK:STDOUT:   %pack.elem.load13 = load i32, ptr %pack.elem12, align 4, !dbg !177
// CHECK:STDOUT:   %pack.elem14 = getelementptr inbounds { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !178
// CHECK:STDOUT:   %pack.elem.load15 = load i32, ptr %pack.elem14, align 4, !dbg !178
// CHECK:STDOUT:   %10 = icmp slt i32 %pack.elem.load13, %pack.elem.load15, !dbg !177
// CHECK:STDOUT:   br i1 %10, label %11, label %12, !dbg !179
// CHECK:STDOUT:
// CHECK:STDOUT: 11:                                               ; preds = %9
// CHECK:STDOUT:   ret i1 false, !dbg !180
// CHECK:STDOUT:
// CHECK:STDOUT: 12:                                               ; preds = %9
// CHECK:STDOUT:   br label %pack.next7, !dbg !172
// CHECK:STDOUT:
// CHECK:STDOUT: pack.next7:                                       ; preds = %12
// CHECK:STDOUT:   ret i1 false, !dbg !182
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CLess.4239cb399c0b0701:OrderedWith.5008e993efea257a.Core.1f77fd894fb81aaf"(ptr %self, ptr %other) #0 !dbg !184 {
// CHECK:STDOUT:   %pack.elem = getelementptr inbounds <{ <{ i32, [4 x i8] }>, i64 }>, ptr %self, i32 0, i32 0, !dbg !200
// CHECK:STDOUT:   %pack.elem.load = load i32, ptr %pack.elem, align 4, !dbg !200
// CHECK:STDOUT:   %pack.elem1 = getelementptr inbounds <{ <{ i32, [4 x i8] }>, i64 }>, ptr %other, i32 0, i32 0, !dbg !201
// CHECK:STDOUT:   %pack.elem.load2 = load i32, ptr %pack.elem1, align 4, !dbg !201
// CHECK:STDOUT:   %1 = icmp slt i32 %pack.elem.load, %pack.elem.load2, !dbg !200
// CHECK:STDOUT:   br i1 %1, label %2, label %3, !dbg !202
// CHECK:STDOUT:
// CHECK:STDOUT: 2:                                                ; preds = %0
// CHECK:STDOUT:   ret i1 true, !dbg !203
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %pack.elem3 = getelementptr inbounds <{ <{ i32, [4 x i8] }>, i64 }>, ptr %other, i32 0, i32 0, !dbg !204
// CHECK:STDOUT:   %pack.elem.load4 = load i32, ptr %pack.elem3, align 4, !dbg !204
// CHECK:STDOUT:   %pack.elem5 = getelementptr inbounds <{ <{ i32, [4 x i8] }>, i64 }>, ptr %self, i32 0, i32 0, !dbg !205
// CHECK:STDOUT:   %pack.elem.load6 = load i32, ptr %pack.elem5, align 4, !dbg !205
// CHECK:STDOUT:   %4 = icmp slt i32 %pack.elem.load4, %pack.elem.load6, !dbg !204
// CHECK:STDOUT:   br i1 %4, label %5, label %6, !dbg !206
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %3
// CHECK:STDOUT:   ret i1 false, !dbg !207
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %3
// CHECK:STDOUT:   br label %pack.next, !dbg !199
// CHECK:STDOUT:
// CHECK:STDOUT: pack.next:                                        ; preds = %6
// CHECK:STDOUT:   %pack.elem8 = getelementptr inbounds <{ <{ i32, [4 x i8] }>, i64 }>, ptr %self, i32 0, i32 1, !dbg !200
// CHECK:STDOUT:   %pack.elem.load9 = load i64, ptr %pack.elem8, align 8, !dbg !200
// CHECK:STDOUT:   %pack.elem10 = getelementptr inbounds <{ <{ i32, [4 x i8] }>, i64 }>, ptr %other, i32 0, i32 1, !dbg !201
// CHECK:STDOUT:   %pack.elem.load11 = load i64, ptr %pack.elem10, align 8, !dbg !201
// CHECK:STDOUT:   %7 = icmp slt i64 %pack.elem.load9, %pack.elem.load11, !dbg !200
// CHECK:STDOUT:   br i1 %7, label %8, label %9, !dbg !202
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %pack.next
// CHECK:STDOUT:   ret i1 true, !dbg !203
// CHECK:STDOUT:
// CHECK:STDOUT: 9:                                                ; preds = %pack.next
// CHECK:STDOUT:   %pack.elem12 = getelementptr inbounds <{ <{ i32, [4 x i8] }>, i64 }>, ptr %other, i32 0, i32 1, !dbg !204
// CHECK:STDOUT:   %pack.elem.load13 = load i64, ptr %pack.elem12, align 8, !dbg !204
// CHECK:STDOUT:   %pack.elem14 = getelementptr inbounds <{ <{ i32, [4 x i8] }>, i64 }>, ptr %self, i32 0, i32 1, !dbg !205
// CHECK:STDOUT:   %pack.elem.load15 = load i64, ptr %pack.elem14, align 8, !dbg !205
// CHECK:STDOUT:   %10 = icmp slt i64 %pack.elem.load13, %pack.elem.load15, !dbg !204
// CHECK:STDOUT:   br i1 %10, label %11, label %12, !dbg !206
// CHECK:STDOUT:
// CHECK:STDOUT: 11:                                               ; preds = %9
// CHECK:STDOUT:   ret i1 false, !dbg !207
// CHECK:STDOUT:
// CHECK:STDOUT: 12:                                               ; preds = %9
// CHECK:STDOUT:   br label %pack.next7, !dbg !199
// CHECK:STDOUT:
// CHECK:STDOUT: pack.next7:                                       ; preds = %12
// CHECK:STDOUT:   ret i1 false, !dbg !209
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 0, 4, 3, 2, 1 }
// CHECK:STDOUT: uselistorder ptr @_CDup.Main.4d6ceefeb7f772f4, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!73}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !18 = !DIFile(filename: "{{.*}}/prelude/copy.carbon", directory: "")
// CHECK:STDOUT: !35 = !{!7, !7, !7}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !48 = !DIFile(filename: "{{.*}}/prelude/operators/comparison.carbon", directory: "")
// CHECK:STDOUT: !72 = !DIFile(filename: "generic_elements.carbon", directory: "")
// CHECK:STDOUT: !73 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !72, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !74 = !{null, !6}
// CHECK:STDOUT: !75 = !DISubroutineType(types: !74)
// CHECK:STDOUT: !76 = !{null, !7}
// CHECK:STDOUT: !77 = !DISubroutineType(types: !76)
// CHECK:STDOUT: !78 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !72, line: 12, type: !36, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !96)
// CHECK:STDOUT: !79 = !DILocalVariable(arg: 1, scope: !78, type: !7)
// CHECK:STDOUT: !80 = !DILocalVariable(arg: 2, scope: !78, type: !7)
// CHECK:STDOUT: !85 = !DILocation(line: 13, column: 21, scope: !78)
// CHECK:STDOUT: !86 = !DILocation(line: 13, column: 17, scope: !78)
// CHECK:STDOUT: !87 = !{!7, !6}
// CHECK:STDOUT: !88 = !DISubroutineType(types: !87)
// CHECK:STDOUT: !89 = !DILocation(line: 13, column: 31, scope: !78)
// CHECK:STDOUT: !90 = !DILocation(line: 13, column: 27, scope: !78)
// CHECK:STDOUT: !91 = !DILocation(line: 13, column: 10, scope: !78)
// CHECK:STDOUT: !94 = !DILocation(line: 13, column: 41, scope: !78)
// CHECK:STDOUT: !95 = !DILocation(line: 13, column: 3, scope: !78)
// CHECK:STDOUT: !96 = !{!79, !80}
// CHECK:STDOUT: !97 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !72, line: 13, type: !75, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !100)
// CHECK:STDOUT: !98 = !DILocalVariable(arg: 1, scope: !97, type: !6)
// CHECK:STDOUT: !99 = !DILocation(line: 13, column: 27, scope: !97)
// CHECK:STDOUT: !100 = !{!98}
// CHECK:STDOUT: !101 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !72, line: 13, type: !77, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !104)
// CHECK:STDOUT: !102 = !DILocalVariable(arg: 1, scope: !101, type: !7)
// CHECK:STDOUT: !103 = !DILocation(line: 13, column: 27, scope: !101)
// CHECK:STDOUT: !104 = !{!102}
// CHECK:STDOUT: !105 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !72, line: 13, type: !77, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !108)
// CHECK:STDOUT: !106 = !DILocalVariable(arg: 1, scope: !105, type: !7)
// CHECK:STDOUT: !107 = !DILocation(line: 13, column: 27, scope: !105)
// CHECK:STDOUT: !108 = !{!106}
// CHECK:STDOUT: !109 = distinct !DISubprogram(name: "Dup", linkageName: "_CDup.Main.4d6ceefeb7f772f4", scope: null, file: !72, line: 3, type: !88, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !121)
// CHECK:STDOUT: !110 = !DILocalVariable(arg: 1, scope: !109, type: !6)
// CHECK:STDOUT: !116 = !DILocation(line: 4, column: 19, scope: !109)
// CHECK:STDOUT: !119 = !DILocation(line: 5, column: 10, scope: !109)
// CHECK:STDOUT: !120 = !DILocation(line: 5, column: 3, scope: !109)
// CHECK:STDOUT: !121 = !{!110}
// CHECK:STDOUT: !122 = distinct !DISubprogram(name: "Before", linkageName: "_CBefore.Main.e6f84856f77e581b", scope: null, file: !72, line: 8, type: !36, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !132)
// CHECK:STDOUT: !123 = !DILocalVariable(arg: 1, scope: !122, type: !7)
// CHECK:STDOUT: !124 = !DILocalVariable(arg: 2, scope: !122, type: !7)
// CHECK:STDOUT: !129 = !DILocation(line: 9, column: 10, scope: !122)
// CHECK:STDOUT: !131 = !DILocation(line: 9, column: 3, scope: !122)
// CHECK:STDOUT: !132 = !{!123, !124}
// CHECK:STDOUT: !133 = distinct !DISubprogram(name: "Before", linkageName: "_CBefore.Main.6b7f7013dcf996f6", scope: null, file: !72, line: 8, type: !36, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !143)
// CHECK:STDOUT: !134 = !DILocalVariable(arg: 1, scope: !133, type: !7)
// CHECK:STDOUT: !135 = !DILocalVariable(arg: 2, scope: !133, type: !7)
// CHECK:STDOUT: !140 = !DILocation(line: 9, column: 10, scope: !133)
// CHECK:STDOUT: !142 = !DILocation(line: 9, column: 3, scope: !133)
// CHECK:STDOUT: !143 = !{!134, !135}
// CHECK:STDOUT: !144 = distinct !DISubprogram(name: "Op", linkageName: "_COp.e97d0ca1040339b6:Copy.Core.bea97fa60d13c05e", scope: null, file: !18, line: 51, type: !9, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !156)
// CHECK:STDOUT: !145 = !DILocalVariable(arg: 1, scope: !144, type: !7)
// CHECK:STDOUT: !154 = !DILocation(line: 53, column: 12, scope: !144)
// CHECK:STDOUT: !155 = !DILocation(line: 53, column: 5, scope: !144)
// CHECK:STDOUT: !156 = !{!145}
// CHECK:STDOUT: !157 = distinct !DISubprogram(name: "Less", linkageName: "_CLess.4239cb399c0b0701:OrderedWith.5008e993efea257a.Core.491927d3f0b989ad", scope: null, file: !48, line: 87, type: !36, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !183)
// CHECK:STDOUT: !158 = !DILocalVariable(arg: 1, scope: !157, type: !7)
// CHECK:STDOUT: !159 = !DILocalVariable(arg: 2, scope: !157, type: !7)
// CHECK:STDOUT: !172 = !DILocation(line: 90, column: 5, scope: !157)
// CHECK:STDOUT: !173 = !DILocation(line: 90, column: 13, scope: !157)
// CHECK:STDOUT: !174 = !DILocation(line: 90, column: 22, scope: !157)
// CHECK:STDOUT: !175 = !DILocation(line: 90, column: 12, scope: !157)
// CHECK:STDOUT: !176 = !DILocation(line: 91, column: 7, scope: !157)
// CHECK:STDOUT: !177 = !DILocation(line: 92, column: 16, scope: !157)
// CHECK:STDOUT: !178 = !DILocation(line: 92, column: 25, scope: !157)
// CHECK:STDOUT: !179 = !DILocation(line: 92, column: 15, scope: !157)
// CHECK:STDOUT: !180 = !DILocation(line: 93, column: 7, scope: !157)
// CHECK:STDOUT: !182 = !DILocation(line: 95, column: 5, scope: !157)
// CHECK:STDOUT: !183 = !{!158, !159}
// CHECK:STDOUT: !184 = distinct !DISubprogram(name: "Less", linkageName: "_CLess.4239cb399c0b0701:OrderedWith.5008e993efea257a.Core.1f77fd894fb81aaf", scope: null, file: !48, line: 87, type: !36, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !210)
// CHECK:STDOUT: !185 = !DILocalVariable(arg: 1, scope: !184, type: !7)
// CHECK:STDOUT: !186 = !DILocalVariable(arg: 2, scope: !184, type: !7)
// CHECK:STDOUT: !199 = !DILocation(line: 90, column: 5, scope: !184)
// CHECK:STDOUT: !200 = !DILocation(line: 90, column: 13, scope: !184)
// CHECK:STDOUT: !201 = !DILocation(line: 90, column: 22, scope: !184)
// CHECK:STDOUT: !202 = !DILocation(line: 90, column: 12, scope: !184)
// CHECK:STDOUT: !203 = !DILocation(line: 91, column: 7, scope: !184)
// CHECK:STDOUT: !204 = !DILocation(line: 92, column: 16, scope: !184)
// CHECK:STDOUT: !205 = !DILocation(line: 92, column: 25, scope: !184)
// CHECK:STDOUT: !206 = !DILocation(line: 92, column: 15, scope: !184)
// CHECK:STDOUT: !207 = !DILocation(line: 93, column: 7, scope: !184)
// CHECK:STDOUT: !209 = !DILocation(line: 95, column: 5, scope: !184)
// CHECK:STDOUT: !210 = !{!185, !186}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'copy_class_element.carbon'
// CHECK:STDOUT: source_filename = "copy_class_element.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CSink.Main(i32)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.C.Main:Copy.Core"(ptr sret({ i32 }) %return, ptr %self) #0 !dbg !213 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_16.1.n = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !218
// CHECK:STDOUT:   %.loc9_16.2 = load i32, ptr %.loc9_16.1.n, align 4, !dbg !218
// CHECK:STDOUT:   call void @_CSink.Main(i32 %.loc9_16.2), !dbg !219
// CHECK:STDOUT:   %.loc10_24.1.n = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !220
// CHECK:STDOUT:   %.loc10_24.2 = load i32, ptr %.loc10_24.1.n, align 4, !dbg !220
// CHECK:STDOUT:   %.loc10_26.2.n = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !221
// CHECK:STDOUT:   store i32 %.loc10_24.2, ptr %.loc10_26.2.n, align 4, !dbg !221
// CHECK:STDOUT:   ret void, !dbg !222
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr sret({ { i32 }, i32 }) %return, ptr %t) #0 !dbg !224 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_COp.e97d0ca1040339b6:Copy.Core.d8ea542efd5f8687"(ptr %return, ptr %t), !dbg !229
// CHECK:STDOUT:   ret void, !dbg !230
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.e97d0ca1040339b6:Copy.Core.d8ea542efd5f8687"(ptr sret({ { i32 }, i32 }) %return, ptr %self) #0 !dbg !232 {
// CHECK:STDOUT:   %pack.elem = getelementptr inbounds <{ ptr, i32 }>, ptr %self, i32 0, i32 0, !dbg !242
// CHECK:STDOUT:   %pack.elem.load = load ptr, ptr %pack.elem, align 8, !dbg !242
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { { i32 }, i32 }, ptr %return, i32 0, i32 0, !dbg !242
// CHECK:STDOUT:   call void @"_COp.C.Main:Copy.Core"(ptr %tuple.elem, ptr %pack.elem.load), !dbg !242
// CHECK:STDOUT:   %pack.elem1 = getelementptr inbounds <{ ptr, i32 }>, ptr %self, i32 0, i32 1, !dbg !242
// CHECK:STDOUT:   %pack.elem.load2 = load i32, ptr %pack.elem1, align 4, !dbg !242
// CHECK:STDOUT:   %tuple.elem3 = getelementptr inbounds nuw { { i32 }, i32 }, ptr %return, i32 0, i32 1, !dbg !242
// CHECK:STDOUT:   store i32 %pack.elem.load2, ptr %tuple.elem3, align 4, !dbg !242
// CHECK:STDOUT:   ret void, !dbg !243
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!212}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !18 = !DIFile(filename: "{{.*}}/prelude/copy.carbon", directory: "")
// CHECK:STDOUT: !211 = !DIFile(filename: "copy_class_element.carbon", directory: "")
// CHECK:STDOUT: !212 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !211, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !213 = distinct !DISubprogram(name: "Op", linkageName: "_COp.C.Main:Copy.Core", scope: null, file: !211, line: 8, type: !9, spFlags: DISPFlagDefinition, unit: !212, retainedNodes: !223)
// CHECK:STDOUT: !214 = !DILocalVariable(arg: 1, scope: !213, type: !7)
// CHECK:STDOUT: !218 = !DILocation(line: 9, column: 12, scope: !213)
// CHECK:STDOUT: !219 = !DILocation(line: 9, column: 7, scope: !213)
// CHECK:STDOUT: !220 = !DILocation(line: 10, column: 20, scope: !213)
// CHECK:STDOUT: !221 = !DILocation(line: 10, column: 14, scope: !213)
// CHECK:STDOUT: !222 = !DILocation(line: 10, column: 7, scope: !213)
// CHECK:STDOUT: !223 = !{!214}
// CHECK:STDOUT: !224 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !211, line: 15, type: !9, spFlags: DISPFlagDefinition, unit: !212, retainedNodes: !231)
// CHECK:STDOUT: !225 = !DILocalVariable(arg: 1, scope: !224, type: !7)
// CHECK:STDOUT: !229 = !DILocation(line: 16, column: 10, scope: !224)
// CHECK:STDOUT: !230 = !DILocation(line: 16, column: 3, scope: !224)
// CHECK:STDOUT: !231 = !{!225}
// CHECK:STDOUT: !232 = distinct !DISubprogram(name: "Op", linkageName: "_COp.e97d0ca1040339b6:Copy.Core.d8ea542efd5f8687", scope: null, file: !18, line: 51, type: !9, spFlags: DISPFlagDefinition, unit: !212, retainedNodes: !244)
// CHECK:STDOUT: !233 = !DILocalVariable(arg: 1, scope: !232, type: !7)
// CHECK:STDOUT: !242 = !DILocation(line: 53, column: 12, scope: !232)
// CHECK:STDOUT: !243 = !DILocation(line: 53, column: 5, scope: !232)
// CHECK:STDOUT: !244 = !{!233}
// CHECK:STDOUT:

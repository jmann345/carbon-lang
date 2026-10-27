// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/tuple_segment_destroy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/tuple_segment_destroy.carbon

// --- var.carbon
library "[[@TEST_NAME]]";

fn Sink(n: i32);

class C {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n}; }
  }
  impl as Core.Destroy {
    fn Op(ref self) { Sink(self.n); }
  }
}

fn F[... each T: Core.Copy & Core.Destroy](t: (... each T)) {
  var unused u: (... each T) = t;
}

fn Call(c: C) {
  F((c, 1 as i32, c));
}

// --- let_from_call.carbon
library "[[@TEST_NAME]]";

fn Sink(n: i32);

class C {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n}; }
  }
  impl as Core.Destroy {
    fn Op(ref self) { Sink(self.n); }
  }
}

fn G[... each T: Core.Copy & Core.Destroy](t: (... each T)) -> (... each T) {
  return t;
}

fn F[... each T: Core.Copy & Core.Destroy](t: (... each T)) {
  let unused u: (... each T) = G(t);
}

fn Call(c: C) {
  F((c, 1 as i32));
}

// --- discarded_result.carbon
library "[[@TEST_NAME]]";

fn Sink(n: i32);

class C {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n}; }
  }
  impl as Core.Destroy {
    fn Op(ref self) { Sink(self.n); }
  }
}

fn G[... each T: Core.Copy & Core.Destroy](t: (... each T)) -> (... each T) {
  return t;
}

fn F[... each T: Core.Copy & Core.Destroy](t: (... each T)) {
  G(t);
}

fn Call(c: C) {
  F((1 as i32, c));
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'var.carbon'
// CHECK:STDOUT: source_filename = "var.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CSink.Main(i32)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.C.Main:Copy.Core"(ptr sret({ i32 }) %return, ptr %self) #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8_44.1.n = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !19
// CHECK:STDOUT:   %.loc8_44.2 = load i32, ptr %.loc8_44.1.n, align 4, !dbg !19
// CHECK:STDOUT:   %.loc8_46.2.n = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !20
// CHECK:STDOUT:   store i32 %.loc8_44.2, ptr %.loc8_46.2.n, align 4, !dbg !20
// CHECK:STDOUT:   ret void, !dbg !21
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.C.Main:Destroy.Core"(ptr %self) #0 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc11_32.1.n = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !26
// CHECK:STDOUT:   %.loc11_32.2 = load i32, ptr %.loc11_32.1.n, align 4, !dbg !26
// CHECK:STDOUT:   call void @_CSink.Main(i32 %.loc11_32.2), !dbg !27
// CHECK:STDOUT:   ret void, !dbg !28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr %c) #0 !dbg !30 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple = alloca { ptr, i32, ptr }, align 8, !dbg !35
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %tuple), !dbg !35
// CHECK:STDOUT:   %tuple1 = getelementptr inbounds nuw { ptr, i32, ptr }, ptr %tuple, i32 0, i32 0, !dbg !35
// CHECK:STDOUT:   store ptr %c, ptr %tuple1, align 8, !dbg !35
// CHECK:STDOUT:   %tuple2 = getelementptr inbounds nuw { ptr, i32, ptr }, ptr %tuple, i32 0, i32 1, !dbg !35
// CHECK:STDOUT:   store i32 1, ptr %tuple2, align 4, !dbg !35
// CHECK:STDOUT:   %tuple3 = getelementptr inbounds nuw { ptr, i32, ptr }, ptr %tuple, i32 0, i32 2, !dbg !35
// CHECK:STDOUT:   store ptr %c, ptr %tuple3, align 8, !dbg !35
// CHECK:STDOUT:   call void @_CF.Main.780f555b674ebad9(ptr %tuple), !dbg !36
// CHECK:STDOUT:   ret void, !dbg !37
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.da7ccbce89dd5557:core.Destroy.Core"(ptr %self) #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem2.tuple.elem = getelementptr inbounds nuw { { i32 }, i32, { i32 } }, ptr %self, i32 0, i32 2, !dbg !45
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.a9c4f3d083d897e6(ptr %tuple.elem2.tuple.elem), !dbg !45
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { { i32 }, i32, { i32 } }, ptr %self, i32 0, i32 1, !dbg !45
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !45
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { { i32 }, i32, { i32 } }, ptr %self, i32 0, i32 0, !dbg !45
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.a9c4f3d083d897e6(ptr %tuple.elem0.tuple.elem), !dbg !45
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.da7ccbce89dd5557:core.Destroy.Core"(ptr %self) #0 !dbg !47 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.da7ccbce89dd5557:core.Destroy.Core"(ptr %self), !dbg !49
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CF.Main.780f555b674ebad9(ptr %t) #0 !dbg !51 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %u.var = alloca { { i32 }, i32, { i32 } }, align 4, !dbg !54
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %u.var), !dbg !54
// CHECK:STDOUT:   %.loc16_32.6.tuple.elem = getelementptr inbounds nuw { ptr, i32, ptr }, ptr %t, i32 0, i32 0, !dbg !55
// CHECK:STDOUT:   %.loc16_32.6.tuple.elem.load = load ptr, ptr %.loc16_32.6.tuple.elem, align 8, !dbg !55
// CHECK:STDOUT:   %.loc16_32.12.tuple.elem = getelementptr inbounds nuw { { i32 }, i32, { i32 } }, ptr %u.var, i32 0, i32 0, !dbg !55
// CHECK:STDOUT:   call void @"_COp.C.Main:Copy.Core"(ptr %.loc16_32.12.tuple.elem, ptr %.loc16_32.6.tuple.elem.load), !dbg !55
// CHECK:STDOUT:   %.loc16_32.6.tuple.elem1 = getelementptr inbounds nuw { ptr, i32, ptr }, ptr %t, i32 0, i32 1, !dbg !55
// CHECK:STDOUT:   %.loc16_32.6.tuple.elem.load2 = load i32, ptr %.loc16_32.6.tuple.elem1, align 4, !dbg !55
// CHECK:STDOUT:   %.loc16_32.12.tuple.elem3 = getelementptr inbounds nuw { { i32 }, i32, { i32 } }, ptr %u.var, i32 0, i32 1, !dbg !55
// CHECK:STDOUT:   store i32 %.loc16_32.6.tuple.elem.load2, ptr %.loc16_32.12.tuple.elem3, align 4, !dbg !55
// CHECK:STDOUT:   %.loc16_32.6.tuple.elem4 = getelementptr inbounds nuw { ptr, i32, ptr }, ptr %t, i32 0, i32 2, !dbg !55
// CHECK:STDOUT:   %.loc16_32.6.tuple.elem.load5 = load ptr, ptr %.loc16_32.6.tuple.elem4, align 8, !dbg !55
// CHECK:STDOUT:   %.loc16_32.12.tuple.elem6 = getelementptr inbounds nuw { { i32 }, i32, { i32 } }, ptr %u.var, i32 0, i32 2, !dbg !55
// CHECK:STDOUT:   call void @"_COp.C.Main:Copy.Core"(ptr %.loc16_32.12.tuple.elem6, ptr %.loc16_32.6.tuple.elem.load5), !dbg !55
// CHECK:STDOUT:   call void @"_CSelfDestruct.da7ccbce89dd5557:core.Destroy.Core"(ptr %u.var), !dbg !54
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.a9c4f3d083d897e6(ptr %self) #0 !dbg !60 {
// CHECK:STDOUT:   call void @"_COp.C.Main:Destroy.Core"(ptr %self), !dbg !63
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.a9c4f3d083d897e6(ptr %self), !dbg !64
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.a9c4f3d083d897e6(ptr %self) #0 !dbg !67 {
// CHECK:STDOUT:   ret void, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CSelfDestruct.Destroy.Core.a9c4f3d083d897e6, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "var.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{null, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!9, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !9}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "Op", linkageName: "_COp.C.Main:Copy.Core", scope: null, file: !4, line: 8, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !22)
// CHECK:STDOUT: !15 = !DILocalVariable(arg: 1, scope: !14, type: !9)
// CHECK:STDOUT: !19 = !DILocation(line: 8, column: 40, scope: !14)
// CHECK:STDOUT: !20 = !DILocation(line: 8, column: 34, scope: !14)
// CHECK:STDOUT: !21 = !DILocation(line: 8, column: 27, scope: !14)
// CHECK:STDOUT: !22 = !{!15}
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "Op", linkageName: "_COp.C.Main:Destroy.Core", scope: null, file: !4, line: 11, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !29)
// CHECK:STDOUT: !24 = !DILocalVariable(arg: 1, scope: !23, type: !9)
// CHECK:STDOUT: !26 = !DILocation(line: 11, column: 28, scope: !23)
// CHECK:STDOUT: !27 = !DILocation(line: 11, column: 23, scope: !23)
// CHECK:STDOUT: !28 = !DILocation(line: 11, column: 5, scope: !23)
// CHECK:STDOUT: !29 = !{!24}
// CHECK:STDOUT: !30 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !4, line: 19, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !38)
// CHECK:STDOUT: !31 = !DILocalVariable(arg: 1, scope: !30, type: !9)
// CHECK:STDOUT: !35 = !DILocation(line: 20, column: 5, scope: !30)
// CHECK:STDOUT: !36 = !DILocation(line: 20, column: 3, scope: !30)
// CHECK:STDOUT: !37 = !DILocation(line: 19, column: 1, scope: !30)
// CHECK:STDOUT: !38 = !{!31}
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 20, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !42)
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !39, type: !6)
// CHECK:STDOUT: !41 = !DILocation(line: 20, column: 3, scope: !39)
// CHECK:STDOUT: !42 = !{!40}
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.da7ccbce89dd5557:core.Destroy.Core", scope: null, file: !4, line: 16, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !46)
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !43, type: !9)
// CHECK:STDOUT: !45 = !DILocation(line: 16, column: 3, scope: !43)
// CHECK:STDOUT: !46 = !{!44}
// CHECK:STDOUT: !47 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.da7ccbce89dd5557:core.Destroy.Core", scope: null, file: !4, line: 16, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !50)
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !47, type: !9)
// CHECK:STDOUT: !49 = !DILocation(line: 16, column: 3, scope: !47)
// CHECK:STDOUT: !50 = !{!48}
// CHECK:STDOUT: !51 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.780f555b674ebad9", scope: null, file: !4, line: 15, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !58)
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !51, type: !9)
// CHECK:STDOUT: !54 = !DILocation(line: 16, column: 3, scope: !51)
// CHECK:STDOUT: !55 = !DILocation(line: 16, column: 32, scope: !51)
// CHECK:STDOUT: !57 = !DILocation(line: 15, column: 1, scope: !51)
// CHECK:STDOUT: !58 = !{!52}
// CHECK:STDOUT: !59 = !DIFile(filename: "{{.*}}/prelude/destroy.carbon", directory: "")
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.a9c4f3d083d897e6", scope: null, file: !59, line: 26, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !66)
// CHECK:STDOUT: !61 = !DILocalVariable(arg: 1, scope: !60, type: !9)
// CHECK:STDOUT: !63 = !DILocation(line: 27, column: 5, scope: !60)
// CHECK:STDOUT: !64 = !DILocation(line: 28, column: 5, scope: !60)
// CHECK:STDOUT: !65 = !DILocation(line: 26, column: 3, scope: !60)
// CHECK:STDOUT: !66 = !{!61}
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.a9c4f3d083d897e6", scope: null, file: !59, line: 19, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !71)
// CHECK:STDOUT: !68 = !DILocalVariable(arg: 1, scope: !67, type: !9)
// CHECK:STDOUT: !70 = !DILocation(line: 19, column: 3, scope: !67)
// CHECK:STDOUT: !71 = !{!68}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'let_from_call.carbon'
// CHECK:STDOUT: source_filename = "let_from_call.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CSink.Main(i32)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.C.Main:Copy.Core"(ptr sret({ i32 }) %return, ptr %self) #0 !dbg !74 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8_44.1.n = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !79
// CHECK:STDOUT:   %.loc8_44.2 = load i32, ptr %.loc8_44.1.n, align 4, !dbg !79
// CHECK:STDOUT:   %.loc8_46.2.n = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !80
// CHECK:STDOUT:   store i32 %.loc8_44.2, ptr %.loc8_46.2.n, align 4, !dbg !80
// CHECK:STDOUT:   ret void, !dbg !81
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.C.Main:Destroy.Core"(ptr %self) #0 !dbg !83 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc11_32.1.n = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !86
// CHECK:STDOUT:   %.loc11_32.2 = load i32, ptr %.loc11_32.1.n, align 4, !dbg !86
// CHECK:STDOUT:   call void @_CSink.Main(i32 %.loc11_32.2), !dbg !87
// CHECK:STDOUT:   ret void, !dbg !88
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr %c) #0 !dbg !90 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple = alloca <{ ptr, i32 }>, align 8, !dbg !94
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %tuple), !dbg !94
// CHECK:STDOUT:   %tuple1 = getelementptr inbounds nuw <{ ptr, i32 }>, ptr %tuple, i32 0, i32 0, !dbg !94
// CHECK:STDOUT:   store ptr %c, ptr %tuple1, align 8, !dbg !94
// CHECK:STDOUT:   %tuple2 = getelementptr inbounds nuw <{ ptr, i32 }>, ptr %tuple, i32 0, i32 1, !dbg !94
// CHECK:STDOUT:   store i32 1, ptr %tuple2, align 4, !dbg !94
// CHECK:STDOUT:   call void @_CF.Main.e7aa0415fd1edd42(ptr %tuple), !dbg !95
// CHECK:STDOUT:   ret void, !dbg !96
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !98 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !100
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.7e65b11697e8b2b7:core.Destroy.Core"(ptr %self) #0 !dbg !102 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { { i32 }, i32 }, ptr %self, i32 0, i32 1, !dbg !104
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !104
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { { i32 }, i32 }, ptr %self, i32 0, i32 0, !dbg !104
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.a9c4f3d083d897e6(ptr %tuple.elem0.tuple.elem), !dbg !104
// CHECK:STDOUT:   ret void, !dbg !104
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.7e65b11697e8b2b7:core.Destroy.Core"(ptr %self) #0 !dbg !106 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.7e65b11697e8b2b7:core.Destroy.Core"(ptr %self), !dbg !108
// CHECK:STDOUT:   ret void, !dbg !108
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CF.Main.e7aa0415fd1edd42(ptr %t) #0 !dbg !110 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc20_35.1.temp = alloca { { i32 }, i32 }, align 4, !dbg !114
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc20_35.1.temp), !dbg !114
// CHECK:STDOUT:   call void @_CG.Main.e7aa0415fd1edd42(ptr %.loc20_35.1.temp, ptr %t), !dbg !114
// CHECK:STDOUT:   call void @"_CSelfDestruct.7e65b11697e8b2b7:core.Destroy.Core"(ptr %.loc20_35.1.temp), !dbg !114
// CHECK:STDOUT:   ret void, !dbg !117
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.a9c4f3d083d897e6(ptr %self) #0 !dbg !119 {
// CHECK:STDOUT:   call void @"_COp.C.Main:Destroy.Core"(ptr %self), !dbg !122
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.a9c4f3d083d897e6(ptr %self), !dbg !123
// CHECK:STDOUT:   ret void, !dbg !124
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CG.Main.e7aa0415fd1edd42(ptr sret({ { i32 }, i32 }) %return, ptr %t) #0 !dbg !126 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_10.6.tuple.elem = getelementptr inbounds nuw <{ ptr, i32 }>, ptr %t, i32 0, i32 0, !dbg !131
// CHECK:STDOUT:   %.loc16_10.6.tuple.elem.load = load ptr, ptr %.loc16_10.6.tuple.elem, align 8, !dbg !131
// CHECK:STDOUT:   %.loc16_10.12.tuple.elem = getelementptr inbounds nuw { { i32 }, i32 }, ptr %return, i32 0, i32 0, !dbg !131
// CHECK:STDOUT:   call void @"_COp.C.Main:Copy.Core"(ptr %.loc16_10.12.tuple.elem, ptr %.loc16_10.6.tuple.elem.load), !dbg !131
// CHECK:STDOUT:   %.loc16_10.6.tuple.elem1 = getelementptr inbounds nuw <{ ptr, i32 }>, ptr %t, i32 0, i32 1, !dbg !131
// CHECK:STDOUT:   %.loc16_10.6.tuple.elem.load2 = load i32, ptr %.loc16_10.6.tuple.elem1, align 4, !dbg !131
// CHECK:STDOUT:   %.loc16_10.12.tuple.elem3 = getelementptr inbounds nuw { { i32 }, i32 }, ptr %return, i32 0, i32 1, !dbg !131
// CHECK:STDOUT:   store i32 %.loc16_10.6.tuple.elem.load2, ptr %.loc16_10.12.tuple.elem3, align 4, !dbg !131
// CHECK:STDOUT:   ret void, !dbg !132
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.a9c4f3d083d897e6(ptr %self) #0 !dbg !134 {
// CHECK:STDOUT:   ret void, !dbg !137
// CHECK:STDOUT: }
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
// CHECK:STDOUT: !7 = !{null, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!9, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !9}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !59 = !DIFile(filename: "{{.*}}/prelude/destroy.carbon", directory: "")
// CHECK:STDOUT: !72 = !DIFile(filename: "let_from_call.carbon", directory: "")
// CHECK:STDOUT: !73 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !72, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !74 = distinct !DISubprogram(name: "Op", linkageName: "_COp.C.Main:Copy.Core", scope: null, file: !72, line: 8, type: !11, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !82)
// CHECK:STDOUT: !75 = !DILocalVariable(arg: 1, scope: !74, type: !9)
// CHECK:STDOUT: !79 = !DILocation(line: 8, column: 40, scope: !74)
// CHECK:STDOUT: !80 = !DILocation(line: 8, column: 34, scope: !74)
// CHECK:STDOUT: !81 = !DILocation(line: 8, column: 27, scope: !74)
// CHECK:STDOUT: !82 = !{!75}
// CHECK:STDOUT: !83 = distinct !DISubprogram(name: "Op", linkageName: "_COp.C.Main:Destroy.Core", scope: null, file: !72, line: 11, type: !13, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !89)
// CHECK:STDOUT: !84 = !DILocalVariable(arg: 1, scope: !83, type: !9)
// CHECK:STDOUT: !86 = !DILocation(line: 11, column: 28, scope: !83)
// CHECK:STDOUT: !87 = !DILocation(line: 11, column: 23, scope: !83)
// CHECK:STDOUT: !88 = !DILocation(line: 11, column: 5, scope: !83)
// CHECK:STDOUT: !89 = !{!84}
// CHECK:STDOUT: !90 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !72, line: 23, type: !13, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !97)
// CHECK:STDOUT: !91 = !DILocalVariable(arg: 1, scope: !90, type: !9)
// CHECK:STDOUT: !94 = !DILocation(line: 24, column: 5, scope: !90)
// CHECK:STDOUT: !95 = !DILocation(line: 24, column: 3, scope: !90)
// CHECK:STDOUT: !96 = !DILocation(line: 23, column: 1, scope: !90)
// CHECK:STDOUT: !97 = !{!91}
// CHECK:STDOUT: !98 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !72, line: 24, type: !8, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !101)
// CHECK:STDOUT: !99 = !DILocalVariable(arg: 1, scope: !98, type: !6)
// CHECK:STDOUT: !100 = !DILocation(line: 24, column: 3, scope: !98)
// CHECK:STDOUT: !101 = !{!99}
// CHECK:STDOUT: !102 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.7e65b11697e8b2b7:core.Destroy.Core", scope: null, file: !72, line: 20, type: !13, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !105)
// CHECK:STDOUT: !103 = !DILocalVariable(arg: 1, scope: !102, type: !9)
// CHECK:STDOUT: !104 = !DILocation(line: 20, column: 32, scope: !102)
// CHECK:STDOUT: !105 = !{!103}
// CHECK:STDOUT: !106 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.7e65b11697e8b2b7:core.Destroy.Core", scope: null, file: !72, line: 20, type: !13, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !109)
// CHECK:STDOUT: !107 = !DILocalVariable(arg: 1, scope: !106, type: !9)
// CHECK:STDOUT: !108 = !DILocation(line: 20, column: 32, scope: !106)
// CHECK:STDOUT: !109 = !{!107}
// CHECK:STDOUT: !110 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.e7aa0415fd1edd42", scope: null, file: !72, line: 19, type: !13, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !118)
// CHECK:STDOUT: !111 = !DILocalVariable(arg: 1, scope: !110, type: !9)
// CHECK:STDOUT: !114 = !DILocation(line: 20, column: 32, scope: !110)
// CHECK:STDOUT: !117 = !DILocation(line: 19, column: 1, scope: !110)
// CHECK:STDOUT: !118 = !{!111}
// CHECK:STDOUT: !119 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.a9c4f3d083d897e6", scope: null, file: !59, line: 26, type: !13, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !125)
// CHECK:STDOUT: !120 = !DILocalVariable(arg: 1, scope: !119, type: !9)
// CHECK:STDOUT: !122 = !DILocation(line: 27, column: 5, scope: !119)
// CHECK:STDOUT: !123 = !DILocation(line: 28, column: 5, scope: !119)
// CHECK:STDOUT: !124 = !DILocation(line: 26, column: 3, scope: !119)
// CHECK:STDOUT: !125 = !{!120}
// CHECK:STDOUT: !126 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.e7aa0415fd1edd42", scope: null, file: !72, line: 15, type: !11, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !133)
// CHECK:STDOUT: !127 = !DILocalVariable(arg: 1, scope: !126, type: !9)
// CHECK:STDOUT: !131 = !DILocation(line: 16, column: 10, scope: !126)
// CHECK:STDOUT: !132 = !DILocation(line: 16, column: 3, scope: !126)
// CHECK:STDOUT: !133 = !{!127}
// CHECK:STDOUT: !134 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.a9c4f3d083d897e6", scope: null, file: !59, line: 19, type: !13, spFlags: DISPFlagDefinition, unit: !73, retainedNodes: !138)
// CHECK:STDOUT: !135 = !DILocalVariable(arg: 1, scope: !134, type: !9)
// CHECK:STDOUT: !137 = !DILocation(line: 19, column: 3, scope: !134)
// CHECK:STDOUT: !138 = !{!135}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'discarded_result.carbon'
// CHECK:STDOUT: source_filename = "discarded_result.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CSink.Main(i32)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.C.Main:Copy.Core"(ptr sret({ i32 }) %return, ptr %self) #0 !dbg !141 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8_44.1.n = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !146
// CHECK:STDOUT:   %.loc8_44.2 = load i32, ptr %.loc8_44.1.n, align 4, !dbg !146
// CHECK:STDOUT:   %.loc8_46.2.n = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !147
// CHECK:STDOUT:   store i32 %.loc8_44.2, ptr %.loc8_46.2.n, align 4, !dbg !147
// CHECK:STDOUT:   ret void, !dbg !148
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.C.Main:Destroy.Core"(ptr %self) #0 !dbg !150 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc11_32.1.n = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !153
// CHECK:STDOUT:   %.loc11_32.2 = load i32, ptr %.loc11_32.1.n, align 4, !dbg !153
// CHECK:STDOUT:   call void @_CSink.Main(i32 %.loc11_32.2), !dbg !154
// CHECK:STDOUT:   ret void, !dbg !155
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr %c) #0 !dbg !157 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple = alloca { i32, ptr }, align 8, !dbg !161
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %tuple), !dbg !161
// CHECK:STDOUT:   %tuple1 = getelementptr inbounds nuw { i32, ptr }, ptr %tuple, i32 0, i32 0, !dbg !161
// CHECK:STDOUT:   store i32 1, ptr %tuple1, align 4, !dbg !161
// CHECK:STDOUT:   %tuple2 = getelementptr inbounds nuw { i32, ptr }, ptr %tuple, i32 0, i32 1, !dbg !161
// CHECK:STDOUT:   store ptr %c, ptr %tuple2, align 8, !dbg !161
// CHECK:STDOUT:   call void @_CF.Main.22eb7be94b93e3dc(ptr %tuple), !dbg !162
// CHECK:STDOUT:   ret void, !dbg !163
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !165 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !167
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.abff69de981d9ef5:core.Destroy.Core"(ptr %self) #0 !dbg !169 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, { i32 } }, ptr %self, i32 0, i32 1, !dbg !171
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.a9c4f3d083d897e6(ptr %tuple.elem1.tuple.elem), !dbg !171
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, { i32 } }, ptr %self, i32 0, i32 0, !dbg !171
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !171
// CHECK:STDOUT:   ret void, !dbg !171
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.abff69de981d9ef5:core.Destroy.Core"(ptr %self) #0 !dbg !173 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.abff69de981d9ef5:core.Destroy.Core"(ptr %self), !dbg !175
// CHECK:STDOUT:   ret void, !dbg !175
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CF.Main.22eb7be94b93e3dc(ptr %t) #0 !dbg !177 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc20_6.1.temp = alloca { i32, { i32 } }, align 4, !dbg !181
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc20_6.1.temp), !dbg !181
// CHECK:STDOUT:   call void @_CG.Main.22eb7be94b93e3dc(ptr %.loc20_6.1.temp, ptr %t), !dbg !181
// CHECK:STDOUT:   call void @"_CSelfDestruct.abff69de981d9ef5:core.Destroy.Core"(ptr %.loc20_6.1.temp), !dbg !181
// CHECK:STDOUT:   ret void, !dbg !182
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.a9c4f3d083d897e6(ptr %self) #0 !dbg !184 {
// CHECK:STDOUT:   call void @"_COp.C.Main:Destroy.Core"(ptr %self), !dbg !187
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.a9c4f3d083d897e6(ptr %self), !dbg !188
// CHECK:STDOUT:   ret void, !dbg !189
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CG.Main.22eb7be94b93e3dc(ptr sret({ i32, { i32 } }) %return, ptr %t) #0 !dbg !191 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_10.6.tuple.elem = getelementptr inbounds nuw { i32, ptr }, ptr %t, i32 0, i32 0, !dbg !196
// CHECK:STDOUT:   %.loc16_10.6.tuple.elem.load = load i32, ptr %.loc16_10.6.tuple.elem, align 4, !dbg !196
// CHECK:STDOUT:   %.loc16_10.12.tuple.elem = getelementptr inbounds nuw { i32, { i32 } }, ptr %return, i32 0, i32 0, !dbg !196
// CHECK:STDOUT:   store i32 %.loc16_10.6.tuple.elem.load, ptr %.loc16_10.12.tuple.elem, align 4, !dbg !196
// CHECK:STDOUT:   %.loc16_10.6.tuple.elem1 = getelementptr inbounds nuw { i32, ptr }, ptr %t, i32 0, i32 1, !dbg !196
// CHECK:STDOUT:   %.loc16_10.6.tuple.elem.load2 = load ptr, ptr %.loc16_10.6.tuple.elem1, align 8, !dbg !196
// CHECK:STDOUT:   %.loc16_10.12.tuple.elem3 = getelementptr inbounds nuw { i32, { i32 } }, ptr %return, i32 0, i32 1, !dbg !196
// CHECK:STDOUT:   call void @"_COp.C.Main:Copy.Core"(ptr %.loc16_10.12.tuple.elem3, ptr %.loc16_10.6.tuple.elem.load2), !dbg !196
// CHECK:STDOUT:   ret void, !dbg !197
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.a9c4f3d083d897e6(ptr %self) #0 !dbg !199 {
// CHECK:STDOUT:   ret void, !dbg !202
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!140}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{null, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!9, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !9}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !59 = !DIFile(filename: "{{.*}}/prelude/destroy.carbon", directory: "")
// CHECK:STDOUT: !139 = !DIFile(filename: "discarded_result.carbon", directory: "")
// CHECK:STDOUT: !140 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !139, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !141 = distinct !DISubprogram(name: "Op", linkageName: "_COp.C.Main:Copy.Core", scope: null, file: !139, line: 8, type: !11, spFlags: DISPFlagDefinition, unit: !140, retainedNodes: !149)
// CHECK:STDOUT: !142 = !DILocalVariable(arg: 1, scope: !141, type: !9)
// CHECK:STDOUT: !146 = !DILocation(line: 8, column: 40, scope: !141)
// CHECK:STDOUT: !147 = !DILocation(line: 8, column: 34, scope: !141)
// CHECK:STDOUT: !148 = !DILocation(line: 8, column: 27, scope: !141)
// CHECK:STDOUT: !149 = !{!142}
// CHECK:STDOUT: !150 = distinct !DISubprogram(name: "Op", linkageName: "_COp.C.Main:Destroy.Core", scope: null, file: !139, line: 11, type: !13, spFlags: DISPFlagDefinition, unit: !140, retainedNodes: !156)
// CHECK:STDOUT: !151 = !DILocalVariable(arg: 1, scope: !150, type: !9)
// CHECK:STDOUT: !153 = !DILocation(line: 11, column: 28, scope: !150)
// CHECK:STDOUT: !154 = !DILocation(line: 11, column: 23, scope: !150)
// CHECK:STDOUT: !155 = !DILocation(line: 11, column: 5, scope: !150)
// CHECK:STDOUT: !156 = !{!151}
// CHECK:STDOUT: !157 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !139, line: 23, type: !13, spFlags: DISPFlagDefinition, unit: !140, retainedNodes: !164)
// CHECK:STDOUT: !158 = !DILocalVariable(arg: 1, scope: !157, type: !9)
// CHECK:STDOUT: !161 = !DILocation(line: 24, column: 5, scope: !157)
// CHECK:STDOUT: !162 = !DILocation(line: 24, column: 3, scope: !157)
// CHECK:STDOUT: !163 = !DILocation(line: 23, column: 1, scope: !157)
// CHECK:STDOUT: !164 = !{!158}
// CHECK:STDOUT: !165 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !139, line: 24, type: !8, spFlags: DISPFlagDefinition, unit: !140, retainedNodes: !168)
// CHECK:STDOUT: !166 = !DILocalVariable(arg: 1, scope: !165, type: !6)
// CHECK:STDOUT: !167 = !DILocation(line: 24, column: 3, scope: !165)
// CHECK:STDOUT: !168 = !{!166}
// CHECK:STDOUT: !169 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.abff69de981d9ef5:core.Destroy.Core", scope: null, file: !139, line: 20, type: !13, spFlags: DISPFlagDefinition, unit: !140, retainedNodes: !172)
// CHECK:STDOUT: !170 = !DILocalVariable(arg: 1, scope: !169, type: !9)
// CHECK:STDOUT: !171 = !DILocation(line: 20, column: 3, scope: !169)
// CHECK:STDOUT: !172 = !{!170}
// CHECK:STDOUT: !173 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.abff69de981d9ef5:core.Destroy.Core", scope: null, file: !139, line: 20, type: !13, spFlags: DISPFlagDefinition, unit: !140, retainedNodes: !176)
// CHECK:STDOUT: !174 = !DILocalVariable(arg: 1, scope: !173, type: !9)
// CHECK:STDOUT: !175 = !DILocation(line: 20, column: 3, scope: !173)
// CHECK:STDOUT: !176 = !{!174}
// CHECK:STDOUT: !177 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.22eb7be94b93e3dc", scope: null, file: !139, line: 19, type: !13, spFlags: DISPFlagDefinition, unit: !140, retainedNodes: !183)
// CHECK:STDOUT: !178 = !DILocalVariable(arg: 1, scope: !177, type: !9)
// CHECK:STDOUT: !181 = !DILocation(line: 20, column: 3, scope: !177)
// CHECK:STDOUT: !182 = !DILocation(line: 19, column: 1, scope: !177)
// CHECK:STDOUT: !183 = !{!178}
// CHECK:STDOUT: !184 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.a9c4f3d083d897e6", scope: null, file: !59, line: 26, type: !13, spFlags: DISPFlagDefinition, unit: !140, retainedNodes: !190)
// CHECK:STDOUT: !185 = !DILocalVariable(arg: 1, scope: !184, type: !9)
// CHECK:STDOUT: !187 = !DILocation(line: 27, column: 5, scope: !184)
// CHECK:STDOUT: !188 = !DILocation(line: 28, column: 5, scope: !184)
// CHECK:STDOUT: !189 = !DILocation(line: 26, column: 3, scope: !184)
// CHECK:STDOUT: !190 = !{!185}
// CHECK:STDOUT: !191 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.22eb7be94b93e3dc", scope: null, file: !139, line: 15, type: !11, spFlags: DISPFlagDefinition, unit: !140, retainedNodes: !198)
// CHECK:STDOUT: !192 = !DILocalVariable(arg: 1, scope: !191, type: !9)
// CHECK:STDOUT: !196 = !DILocation(line: 16, column: 10, scope: !191)
// CHECK:STDOUT: !197 = !DILocation(line: 16, column: 3, scope: !191)
// CHECK:STDOUT: !198 = !{!192}
// CHECK:STDOUT: !199 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.a9c4f3d083d897e6", scope: null, file: !59, line: 19, type: !13, spFlags: DISPFlagDefinition, unit: !140, retainedNodes: !203)
// CHECK:STDOUT: !200 = !DILocalVariable(arg: 1, scope: !199, type: !9)
// CHECK:STDOUT: !202 = !DILocation(line: 19, column: 3, scope: !199)
// CHECK:STDOUT: !203 = !{!200}
// CHECK:STDOUT:

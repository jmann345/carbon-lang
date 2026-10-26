// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/tuple/nested_constant.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/tuple/nested_constant.carbon

// --- tuple.carbon
library "[[@TEST_NAME]]";

fn Read() -> i32 {
  let n: ((i32, i32), i32) = ((1, 2), 3);
  return n.0.1;
}

// --- pass.carbon
library "[[@TEST_NAME]]";

fn Take(unused t: ((i32, i32), i32)) {}

fn Call() {
  let n: ((i32, i32), i32) = ((1, 2), 3);
  Take(n);
}

// --- var.carbon
library "[[@TEST_NAME]]";

fn Read() -> i32 {
  var v: ((i32, i32), i32) = ((4, 5), 6);
  return v.0.0;
}

// --- struct.carbon
library "[[@TEST_NAME]]";

fn Read() -> i32 {
  let s: {.a: {.b: i32, .c: i32}, .d: i32} = {.a = {.b = 1, .c = 2}, .d = 3};
  return s.a.c;
}

// --- struct_of_tuple.carbon
library "[[@TEST_NAME]]";

fn Read() -> i32 {
  let m: {.t: (i32, i32), .u: i32} = {.t = (4, 5), .u = 6};
  return m.t.1;
}

// --- return.carbon
library "[[@TEST_NAME]]";

fn Make() -> ((i32, i32), i32) {
  return ((4, 5), 6);
}

// --- one_element.carbon
library "[[@TEST_NAME]]";

fn Read() -> i32 {
  var v: ((i32, i32),) = ((1, 2),);
  return v.0.1;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'tuple.carbon'
// CHECK:STDOUT: source_filename = "tuple.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @tuple.102.loc4_40.5 = internal constant { i32, i32 } { i32 1, i32 2 }
// CHECK:STDOUT: @tuple.500.loc4_40.5 = internal constant <{ ptr, i32 }> <{ ptr @tuple.102.loc4_40.5, i32 3 }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CRead.Main() #0 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem.load = load ptr, ptr @tuple.500.loc4_40.5, align 8, !dbg !28
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.elem0.tuple.elem.load, i32 0, i32 1, !dbg !28
// CHECK:STDOUT:   %tuple.elem1.tuple.elem.load = load i32, ptr %tuple.elem1.tuple.elem, align 4, !dbg !28
// CHECK:STDOUT:   ret i32 %tuple.elem1.tuple.elem.load, !dbg !29
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!19}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !18 = !DIFile(filename: "tuple.carbon", directory: "")
// CHECK:STDOUT: !19 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !18, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "Read", linkageName: "_CRead.Main", scope: null, file: !18, line: 3, type: !22, spFlags: DISPFlagDefinition, unit: !19)
// CHECK:STDOUT: !28 = !DILocation(line: 5, column: 10, scope: !23)
// CHECK:STDOUT: !29 = !DILocation(line: 5, column: 3, scope: !23)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'pass.carbon'
// CHECK:STDOUT: source_filename = "pass.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @tuple.102.loc6_40.5 = internal constant { i32, i32 } { i32 1, i32 2 }
// CHECK:STDOUT: @tuple.500.loc6_40.5 = internal constant <{ ptr, i32 }> <{ ptr @tuple.102.loc6_40.5, i32 3 }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CTake.Main(ptr %t) #0 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main() #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CTake.Main(ptr @tuple.500.loc6_40.5), !dbg !46
// CHECK:STDOUT:   ret void, !dbg !47
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!31}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !30 = !DIFile(filename: "pass.carbon", directory: "")
// CHECK:STDOUT: !31 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !30, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !32 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !33 = !{null, !32}
// CHECK:STDOUT: !34 = !DISubroutineType(types: !33)
// CHECK:STDOUT: !35 = !{null}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "Take", linkageName: "_CTake.Main", scope: null, file: !30, line: 3, type: !34, spFlags: DISPFlagDefinition, unit: !31, retainedNodes: !41)
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !37, type: !32)
// CHECK:STDOUT: !40 = !DILocation(line: 3, column: 1, scope: !37)
// CHECK:STDOUT: !41 = !{!38}
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !30, line: 5, type: !36, spFlags: DISPFlagDefinition, unit: !31)
// CHECK:STDOUT: !46 = !DILocation(line: 7, column: 3, scope: !42)
// CHECK:STDOUT: !47 = !DILocation(line: 5, column: 1, scope: !42)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'var.carbon'
// CHECK:STDOUT: source_filename = "var.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @tuple.8a1.loc4_3 = internal constant { i32, i32 } { i32 4, i32 5 }
// CHECK:STDOUT: @tuple.c42.loc4_3 = internal constant <{ ptr, i32 }> <{ ptr @tuple.8a1.loc4_3, i32 6 }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CRead.Main() #0 !dbg !52 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.var = alloca { { i32, i32 }, i32 }, align 4, !dbg !55
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %v.var), !dbg !55
// CHECK:STDOUT:   %tuple.elem0.loc4_40.tuple.elem = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %v.var, i32 0, i32 0, !dbg !56
// CHECK:STDOUT:   %tuple.elem0.loc4_36.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.elem0.loc4_40.tuple.elem, i32 0, i32 0, !dbg !57
// CHECK:STDOUT:   %tuple.elem1.loc4_36.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.elem0.loc4_40.tuple.elem, i32 0, i32 1, !dbg !57
// CHECK:STDOUT:   %tuple.elem1.loc4_40.tuple.elem = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %v.var, i32 0, i32 1, !dbg !56
// CHECK:STDOUT:   %0 = load ptr, ptr @tuple.c42.loc4_3, align 8, !dbg !55
// CHECK:STDOUT:   %1 = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %v.var, i32 0, i32 0, !dbg !55
// CHECK:STDOUT:   %2 = load i32, ptr getelementptr inbounds nuw (<{ ptr, i32 }>, ptr @tuple.c42.loc4_3, i32 0, i32 1), align 4, !dbg !55
// CHECK:STDOUT:   %3 = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %v.var, i32 0, i32 1, !dbg !55
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %1, ptr align 4 %0, i64 8, i1 false), !dbg !55
// CHECK:STDOUT:   store i32 %2, ptr %3, align 4, !dbg !55
// CHECK:STDOUT:   %tuple.elem0.loc5_11.tuple.elem = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %v.var, i32 0, i32 0, !dbg !59
// CHECK:STDOUT:   %tuple.elem0.loc5_13.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.elem0.loc5_11.tuple.elem, i32 0, i32 0, !dbg !59
// CHECK:STDOUT:   %.loc5 = load i32, ptr %tuple.elem0.loc5_13.tuple.elem, align 4, !dbg !59
// CHECK:STDOUT:   call void @"_CSelfDestruct.7fb3cf7a4e376855:core.Destroy.Core"(ptr %v.var), !dbg !55
// CHECK:STDOUT:   ret i32 %.loc5, !dbg !60
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !61 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !63
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !65 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !67
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !67
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !67
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !67
// CHECK:STDOUT:   ret void, !dbg !67
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !69 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self), !dbg !71
// CHECK:STDOUT:   ret void, !dbg !71
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.7fb3cf7a4e376855:core.Destroy.Core"(ptr %self) #0 !dbg !73 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %self, i32 0, i32 1, !dbg !75
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !75
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %self, i32 0, i32 0, !dbg !75
// CHECK:STDOUT:   call void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !75
// CHECK:STDOUT:   ret void, !dbg !75
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.7fb3cf7a4e376855:core.Destroy.Core"(ptr %self) #0 !dbg !77 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.7fb3cf7a4e376855:core.Destroy.Core"(ptr %self), !dbg !79
// CHECK:STDOUT:   ret void, !dbg !79
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!49}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !32 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !33 = !{null, !32}
// CHECK:STDOUT: !34 = !DISubroutineType(types: !33)
// CHECK:STDOUT: !48 = !DIFile(filename: "var.carbon", directory: "")
// CHECK:STDOUT: !49 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !48, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !50 = !{null, !20}
// CHECK:STDOUT: !51 = !DISubroutineType(types: !50)
// CHECK:STDOUT: !52 = distinct !DISubprogram(name: "Read", linkageName: "_CRead.Main", scope: null, file: !48, line: 3, type: !22, spFlags: DISPFlagDefinition, unit: !49)
// CHECK:STDOUT: !55 = !DILocation(line: 4, column: 3, scope: !52)
// CHECK:STDOUT: !56 = !DILocation(line: 4, column: 30, scope: !52)
// CHECK:STDOUT: !57 = !DILocation(line: 4, column: 31, scope: !52)
// CHECK:STDOUT: !59 = !DILocation(line: 5, column: 10, scope: !52)
// CHECK:STDOUT: !60 = !DILocation(line: 5, column: 3, scope: !52)
// CHECK:STDOUT: !61 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !48, line: 4, type: !51, spFlags: DISPFlagDefinition, unit: !49, retainedNodes: !64)
// CHECK:STDOUT: !62 = !DILocalVariable(arg: 1, scope: !61, type: !20)
// CHECK:STDOUT: !63 = !DILocation(line: 4, column: 3, scope: !61)
// CHECK:STDOUT: !64 = !{!62}
// CHECK:STDOUT: !65 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !48, line: 4, type: !34, spFlags: DISPFlagDefinition, unit: !49, retainedNodes: !68)
// CHECK:STDOUT: !66 = !DILocalVariable(arg: 1, scope: !65, type: !32)
// CHECK:STDOUT: !67 = !DILocation(line: 4, column: 3, scope: !65)
// CHECK:STDOUT: !68 = !{!66}
// CHECK:STDOUT: !69 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !48, line: 4, type: !34, spFlags: DISPFlagDefinition, unit: !49, retainedNodes: !72)
// CHECK:STDOUT: !70 = !DILocalVariable(arg: 1, scope: !69, type: !32)
// CHECK:STDOUT: !71 = !DILocation(line: 4, column: 3, scope: !69)
// CHECK:STDOUT: !72 = !{!70}
// CHECK:STDOUT: !73 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.7fb3cf7a4e376855:core.Destroy.Core", scope: null, file: !48, line: 4, type: !34, spFlags: DISPFlagDefinition, unit: !49, retainedNodes: !76)
// CHECK:STDOUT: !74 = !DILocalVariable(arg: 1, scope: !73, type: !32)
// CHECK:STDOUT: !75 = !DILocation(line: 4, column: 3, scope: !73)
// CHECK:STDOUT: !76 = !{!74}
// CHECK:STDOUT: !77 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.7fb3cf7a4e376855:core.Destroy.Core", scope: null, file: !48, line: 4, type: !34, spFlags: DISPFlagDefinition, unit: !49, retainedNodes: !80)
// CHECK:STDOUT: !78 = !DILocalVariable(arg: 1, scope: !77, type: !32)
// CHECK:STDOUT: !79 = !DILocation(line: 4, column: 3, scope: !77)
// CHECK:STDOUT: !80 = !{!78}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'struct.carbon'
// CHECK:STDOUT: source_filename = "struct.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @struct.5de.loc4_76.5 = internal constant { i32, i32 } { i32 1, i32 2 }
// CHECK:STDOUT: @struct.1c5.loc4_76.5 = internal constant <{ ptr, i32 }> <{ ptr @struct.5de.loc4_76.5, i32 3 }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CRead.Main() #0 !dbg !83 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc5_11.a.load = load ptr, ptr @struct.1c5.loc4_76.5, align 8, !dbg !88
// CHECK:STDOUT:   %.loc5_13.c = getelementptr inbounds nuw { i32, i32 }, ptr %.loc5_11.a.load, i32 0, i32 1, !dbg !88
// CHECK:STDOUT:   %.loc5_13.c.load = load i32, ptr %.loc5_13.c, align 4, !dbg !88
// CHECK:STDOUT:   ret i32 %.loc5_13.c.load, !dbg !89
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!82}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !81 = !DIFile(filename: "struct.carbon", directory: "")
// CHECK:STDOUT: !82 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !81, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !83 = distinct !DISubprogram(name: "Read", linkageName: "_CRead.Main", scope: null, file: !81, line: 3, type: !22, spFlags: DISPFlagDefinition, unit: !82)
// CHECK:STDOUT: !88 = !DILocation(line: 5, column: 10, scope: !83)
// CHECK:STDOUT: !89 = !DILocation(line: 5, column: 3, scope: !83)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'struct_of_tuple.carbon'
// CHECK:STDOUT: source_filename = "struct_of_tuple.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @tuple.8a1.loc4_58.5 = internal constant { i32, i32 } { i32 4, i32 5 }
// CHECK:STDOUT: @struct.fbe.loc4_58.5 = internal constant <{ ptr, i32 }> <{ ptr @tuple.8a1.loc4_58.5, i32 6 }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CRead.Main() #0 !dbg !92 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc5.t.load = load ptr, ptr @struct.fbe.loc4_58.5, align 8, !dbg !97
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc5.t.load, i32 0, i32 1, !dbg !97
// CHECK:STDOUT:   %tuple.elem1.tuple.elem.load = load i32, ptr %tuple.elem1.tuple.elem, align 4, !dbg !97
// CHECK:STDOUT:   ret i32 %tuple.elem1.tuple.elem.load, !dbg !98
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!91}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !90 = !DIFile(filename: "struct_of_tuple.carbon", directory: "")
// CHECK:STDOUT: !91 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !90, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !92 = distinct !DISubprogram(name: "Read", linkageName: "_CRead.Main", scope: null, file: !90, line: 3, type: !22, spFlags: DISPFlagDefinition, unit: !91)
// CHECK:STDOUT: !97 = !DILocation(line: 5, column: 10, scope: !92)
// CHECK:STDOUT: !98 = !DILocation(line: 5, column: 3, scope: !92)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'return.carbon'
// CHECK:STDOUT: source_filename = "return.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @tuple.8a1.loc4_21 = internal constant { i32, i32 } { i32 4, i32 5 }
// CHECK:STDOUT: @tuple.c42.loc4_21 = internal constant <{ ptr, i32 }> <{ ptr @tuple.8a1.loc4_21, i32 6 }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMake.Main(ptr sret({ { i32, i32 }, i32 }) %return) #0 !dbg !103 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.loc4_20.tuple.elem = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %return, i32 0, i32 0, !dbg !106
// CHECK:STDOUT:   %tuple.elem0.loc4_16.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.elem0.loc4_20.tuple.elem, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   %tuple.elem1.loc4_16.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.elem0.loc4_20.tuple.elem, i32 0, i32 1, !dbg !107
// CHECK:STDOUT:   %tuple.elem1.loc4_20.tuple.elem = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %return, i32 0, i32 1, !dbg !106
// CHECK:STDOUT:   %0 = load ptr, ptr @tuple.c42.loc4_21, align 8, !dbg !108
// CHECK:STDOUT:   %1 = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %return, i32 0, i32 0, !dbg !108
// CHECK:STDOUT:   %2 = load i32, ptr getelementptr inbounds nuw (<{ ptr, i32 }>, ptr @tuple.c42.loc4_21, i32 0, i32 1), align 4, !dbg !108
// CHECK:STDOUT:   %3 = getelementptr inbounds nuw { { i32, i32 }, i32 }, ptr %return, i32 0, i32 1, !dbg !108
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %1, ptr align 4 %0, i64 8, i1 false), !dbg !108
// CHECK:STDOUT:   store i32 %2, ptr %3, align 4, !dbg !108
// CHECK:STDOUT:   ret void, !dbg !108
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!100}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !32 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !99 = !DIFile(filename: "return.carbon", directory: "")
// CHECK:STDOUT: !100 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !99, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !101 = !{!32}
// CHECK:STDOUT: !102 = !DISubroutineType(types: !101)
// CHECK:STDOUT: !103 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.Main", scope: null, file: !99, line: 3, type: !102, spFlags: DISPFlagDefinition, unit: !100)
// CHECK:STDOUT: !106 = !DILocation(line: 4, column: 10, scope: !103)
// CHECK:STDOUT: !107 = !DILocation(line: 4, column: 11, scope: !103)
// CHECK:STDOUT: !108 = !DILocation(line: 4, column: 3, scope: !103)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'one_element.carbon'
// CHECK:STDOUT: source_filename = "one_element.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @tuple.102.loc4_3 = internal constant { i32, i32 } { i32 1, i32 2 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CRead.Main() #0 !dbg !111 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.var = alloca { { i32, i32 } }, align 4, !dbg !114
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %v.var), !dbg !114
// CHECK:STDOUT:   %tuple.elem0.loc4_34.tuple.elem = getelementptr inbounds nuw { { i32, i32 } }, ptr %v.var, i32 0, i32 0, !dbg !115
// CHECK:STDOUT:   %tuple.elem0.loc4_32.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.elem0.loc4_34.tuple.elem, i32 0, i32 0, !dbg !116
// CHECK:STDOUT:   %tuple.elem1.loc4.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.elem0.loc4_34.tuple.elem, i32 0, i32 1, !dbg !116
// CHECK:STDOUT:   %0 = getelementptr inbounds nuw { { i32, i32 } }, ptr %v.var, i32 0, i32 0, !dbg !114
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %0, ptr align 4 @tuple.102.loc4_3, i64 8, i1 false), !dbg !114
// CHECK:STDOUT:   %tuple.elem0.loc5.tuple.elem = getelementptr inbounds nuw { { i32, i32 } }, ptr %v.var, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %tuple.elem1.loc5.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %tuple.elem0.loc5.tuple.elem, i32 0, i32 1, !dbg !118
// CHECK:STDOUT:   %.loc5 = load i32, ptr %tuple.elem1.loc5.tuple.elem, align 4, !dbg !118
// CHECK:STDOUT:   call void @"_CSelfDestruct.f9cbea6637edd885:core.Destroy.Core"(ptr %v.var), !dbg !114
// CHECK:STDOUT:   ret i32 %.loc5, !dbg !119
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !120 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !122
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !124 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !126
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !126
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !126
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !126
// CHECK:STDOUT:   ret void, !dbg !126
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !128 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self), !dbg !130
// CHECK:STDOUT:   ret void, !dbg !130
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.f9cbea6637edd885:core.Destroy.Core"(ptr %self) #0 !dbg !132 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { { i32, i32 } }, ptr %self, i32 0, i32 0, !dbg !134
// CHECK:STDOUT:   call void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !134
// CHECK:STDOUT:   ret void, !dbg !134
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f9cbea6637edd885:core.Destroy.Core"(ptr %self) #0 !dbg !136 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.f9cbea6637edd885:core.Destroy.Core"(ptr %self), !dbg !138
// CHECK:STDOUT:   ret void, !dbg !138
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!110}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !32 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !33 = !{null, !32}
// CHECK:STDOUT: !34 = !DISubroutineType(types: !33)
// CHECK:STDOUT: !50 = !{null, !20}
// CHECK:STDOUT: !51 = !DISubroutineType(types: !50)
// CHECK:STDOUT: !109 = !DIFile(filename: "one_element.carbon", directory: "")
// CHECK:STDOUT: !110 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !109, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !111 = distinct !DISubprogram(name: "Read", linkageName: "_CRead.Main", scope: null, file: !109, line: 3, type: !22, spFlags: DISPFlagDefinition, unit: !110)
// CHECK:STDOUT: !114 = !DILocation(line: 4, column: 3, scope: !111)
// CHECK:STDOUT: !115 = !DILocation(line: 4, column: 26, scope: !111)
// CHECK:STDOUT: !116 = !DILocation(line: 4, column: 27, scope: !111)
// CHECK:STDOUT: !118 = !DILocation(line: 5, column: 10, scope: !111)
// CHECK:STDOUT: !119 = !DILocation(line: 5, column: 3, scope: !111)
// CHECK:STDOUT: !120 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !109, line: 4, type: !51, spFlags: DISPFlagDefinition, unit: !110, retainedNodes: !123)
// CHECK:STDOUT: !121 = !DILocalVariable(arg: 1, scope: !120, type: !20)
// CHECK:STDOUT: !122 = !DILocation(line: 4, column: 3, scope: !120)
// CHECK:STDOUT: !123 = !{!121}
// CHECK:STDOUT: !124 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !109, line: 4, type: !34, spFlags: DISPFlagDefinition, unit: !110, retainedNodes: !127)
// CHECK:STDOUT: !125 = !DILocalVariable(arg: 1, scope: !124, type: !32)
// CHECK:STDOUT: !126 = !DILocation(line: 4, column: 3, scope: !124)
// CHECK:STDOUT: !127 = !{!125}
// CHECK:STDOUT: !128 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !109, line: 4, type: !34, spFlags: DISPFlagDefinition, unit: !110, retainedNodes: !131)
// CHECK:STDOUT: !129 = !DILocalVariable(arg: 1, scope: !128, type: !32)
// CHECK:STDOUT: !130 = !DILocation(line: 4, column: 3, scope: !128)
// CHECK:STDOUT: !131 = !{!129}
// CHECK:STDOUT: !132 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.f9cbea6637edd885:core.Destroy.Core", scope: null, file: !109, line: 4, type: !34, spFlags: DISPFlagDefinition, unit: !110, retainedNodes: !135)
// CHECK:STDOUT: !133 = !DILocalVariable(arg: 1, scope: !132, type: !32)
// CHECK:STDOUT: !134 = !DILocation(line: 4, column: 3, scope: !132)
// CHECK:STDOUT: !135 = !{!133}
// CHECK:STDOUT: !136 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f9cbea6637edd885:core.Destroy.Core", scope: null, file: !109, line: 4, type: !34, spFlags: DISPFlagDefinition, unit: !110, retainedNodes: !139)
// CHECK:STDOUT: !137 = !DILocalVariable(arg: 1, scope: !136, type: !32)
// CHECK:STDOUT: !138 = !DILocation(line: 4, column: 3, scope: !136)
// CHECK:STDOUT: !139 = !{!137}
// CHECK:STDOUT:

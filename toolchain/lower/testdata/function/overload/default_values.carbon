// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/default_values.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/default_values.carbon

// The committed call to a defaulted `overload fn` member passes the default
// value for the omitted argument (fork/overload/ov4-plan.md OV-4): the lowered
// call to member 0 receives the constant `10`, and a class-typed default is
// initialized in the caller as the ordinary call initializes it. In a
// template's specific, the deferred call is resolved and filled the same way.

// --- omitted_and_supplied.carbon

library "[[@TEST_NAME]]";

overload fn Scale(x: i32, factor: i32 = 10) -> i32 { return x * factor; }
overload fn Scale(unused b: bool) -> i32 { return 0; }

fn Use() -> i32 { return Scale(1) + Scale(2, 3); }

// --- class_default.carbon

library "[[@TEST_NAME]]";

class C { var v: i32; }
fn MakeC() -> C { return {.v = 7}; }

overload fn F(c: C, d: C = {.v = 3}) -> i32 { return c.v * 10 + d.v; }
overload fn F(unused b: bool) -> i32 { return -1; }

fn Use() -> i32 { return F(MakeC()) + F(MakeC(), MakeC()); }

// --- template_dependent_default.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }
overload fn F(unused b: bool) -> i32 { return -1; }

// Each specific of `T` resolves its deferred call: `T(i32)` calls member 0
// with the default `2` filled, and `T(bool)` calls member 1.
fn T(template U: type, u: U) -> i32 { return F(u); }

fn Use() -> i32 { return T(i32, 1) + T(bool, true); }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'omitted_and_supplied.carbon'
// CHECK:STDOUT: source_filename = "omitted_and_supplied.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CScale:overload0.Main"(i32 %x, i32 %factor) #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.MulWith.impl.Op.call = mul i32 %x, %factor, !dbg !21
// CHECK:STDOUT:   ret i32 %Int.as.MulWith.impl.Op.call, !dbg !23
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CScale:overload1.Main"(i1 %b) #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 0, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Scale.call.loc7_33 = call i32 @"_CScale:overload0.Main"(i32 1, i32 10), !dbg !35
// CHECK:STDOUT:   %Scale.call.loc7_47 = call i32 @"_CScale:overload0.Main"(i32 2, i32 3), !dbg !36
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Scale.call.loc7_33, %Scale.call.loc7_47, !dbg !35
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !37
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "omitted_and_supplied.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6, !6, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!6, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "Scale", linkageName: "_CScale:overload0.Main", scope: null, file: !4, line: 4, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !24)
// CHECK:STDOUT: !15 = !DILocalVariable(arg: 1, scope: !14, type: !6)
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 2, scope: !14, type: !6)
// CHECK:STDOUT: !21 = !DILocation(line: 4, column: 61, scope: !14)
// CHECK:STDOUT: !23 = !DILocation(line: 4, column: 54, scope: !14)
// CHECK:STDOUT: !24 = !{!15, !16}
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "Scale", linkageName: "_CScale:overload1.Main", scope: null, file: !4, line: 5, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !31)
// CHECK:STDOUT: !26 = !DILocalVariable(arg: 1, scope: !25, type: !9)
// CHECK:STDOUT: !30 = !DILocation(line: 5, column: 44, scope: !25)
// CHECK:STDOUT: !31 = !{!26}
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !4, line: 7, type: !13, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !35 = !DILocation(line: 7, column: 26, scope: !32)
// CHECK:STDOUT: !36 = !DILocation(line: 7, column: 37, scope: !32)
// CHECK:STDOUT: !37 = !DILocation(line: 7, column: 19, scope: !32)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'class_default.carbon'
// CHECK:STDOUT: source_filename = "class_default.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @C.val.a26 = internal constant { i32 } { i32 3 }
// CHECK:STDOUT: @C.val.e34.loc5_34 = internal constant { i32 } { i32 7 }
// CHECK:STDOUT: @C.val.a26.loc7_35.9 = internal constant { i32 } { i32 3 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeC.Main(ptr sret({ i32 }) %return) #0 !dbg !48 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc5_33.3.v = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !51
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @C.val.e34.loc5_34, i64 4, i1 false), !dbg !52
// CHECK:STDOUT:   ret void, !dbg !52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload0.Main"(ptr %c, ptr %d) #0 !dbg !53 {
// CHECK:STDOUT:   %.loc7_35.3.temp = alloca { i32 }, align 4, !dbg !56
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc7_35.3.temp), !dbg !56
// CHECK:STDOUT:   %.loc7_35.4.v = getelementptr inbounds nuw { i32 }, ptr %.loc7_35.3.temp, i32 0, i32 0, !dbg !56
// CHECK:STDOUT:   br label %entry
// CHECK:STDOUT:
// CHECK:STDOUT: entry:                                            ; preds = %0
// CHECK:STDOUT:   %.loc7_55.1.v = getelementptr inbounds nuw { i32 }, ptr %c, i32 0, i32 0, !dbg !61
// CHECK:STDOUT:   %.loc7_55.2 = load i32, ptr %.loc7_55.1.v, align 4, !dbg !61
// CHECK:STDOUT:   %Int.as.MulWith.impl.Op.call = mul i32 %.loc7_55.2, 10, !dbg !61
// CHECK:STDOUT:   %.loc7_66.1.v = getelementptr inbounds nuw { i32 }, ptr %d, i32 0, i32 0, !dbg !62
// CHECK:STDOUT:   %.loc7_66.2 = load i32, ptr %.loc7_66.1.v, align 4, !dbg !62
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Int.as.MulWith.impl.Op.call, %.loc7_66.2, !dbg !61
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !63
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload1.Main"(i1 %b) #0 !dbg !65 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 -1, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_34.1.temp = alloca { i32 }, align 4, !dbg !75
// CHECK:STDOUT:   %.loc10_47.1.temp = alloca { i32 }, align 4, !dbg !77
// CHECK:STDOUT:   %.loc10_56.1.temp = alloca { i32 }, align 4, !dbg !78
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc10_34.1.temp), !dbg !75
// CHECK:STDOUT:   call void @_CMakeC.Main(ptr %.loc10_34.1.temp), !dbg !75
// CHECK:STDOUT:   %F.call.loc10_35 = call i32 @"_CF:overload0.Main"(ptr %.loc10_34.1.temp, ptr @C.val.a26.loc7_35.9), !dbg !76
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc10_47.1.temp), !dbg !77
// CHECK:STDOUT:   call void @_CMakeC.Main(ptr %.loc10_47.1.temp), !dbg !77
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc10_56.1.temp), !dbg !78
// CHECK:STDOUT:   call void @_CMakeC.Main(ptr %.loc10_56.1.temp), !dbg !78
// CHECK:STDOUT:   %F.call.loc10_57 = call i32 @"_CF:overload0.Main"(ptr %.loc10_47.1.temp, ptr %.loc10_56.1.temp), !dbg !79
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %F.call.loc10_35, %F.call.loc10_57, !dbg !76
// CHECK:STDOUT:   call void @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core"(ptr %.loc10_56.1.temp), !dbg !78
// CHECK:STDOUT:   call void @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core"(ptr %.loc10_47.1.temp), !dbg !77
// CHECK:STDOUT:   call void @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core"(ptr %.loc10_34.1.temp), !dbg !75
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !80
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !81 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !83
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.92afc3a45a31c789:core.Destroy.Core"(ptr %self) #0 !dbg !85 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10.v = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !87
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc10.v), !dbg !87
// CHECK:STDOUT:   ret void, !dbg !87
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.92afc3a45a31c789:core.Destroy.Core"(ptr %self) #0 !dbg !89 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.92afc3a45a31c789:core.Destroy.Core"(ptr %self), !dbg !91
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.08d9e38b928ba575:core.Destroy.Core"(ptr %self) #0 !dbg !93 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10.v = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !95
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc10.v), !dbg !95
// CHECK:STDOUT:   ret void, !dbg !95
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core"(ptr %self) #0 !dbg !97 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.08d9e38b928ba575:core.Destroy.Core"(ptr %self), !dbg !99
// CHECK:STDOUT:   ret void, !dbg !99
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core", { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 3, 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!39}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!6, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !38 = !DIFile(filename: "class_default.carbon", directory: "")
// CHECK:STDOUT: !39 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !38, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !40 = !{!9}
// CHECK:STDOUT: !41 = !DISubroutineType(types: !40)
// CHECK:STDOUT: !42 = !{!6, !9, !9}
// CHECK:STDOUT: !43 = !DISubroutineType(types: !42)
// CHECK:STDOUT: !44 = !{null, !6}
// CHECK:STDOUT: !45 = !DISubroutineType(types: !44)
// CHECK:STDOUT: !46 = !{null, !9}
// CHECK:STDOUT: !47 = !DISubroutineType(types: !46)
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "MakeC", linkageName: "_CMakeC.Main", scope: null, file: !38, line: 5, type: !41, spFlags: DISPFlagDefinition, unit: !39)
// CHECK:STDOUT: !51 = !DILocation(line: 5, column: 26, scope: !48)
// CHECK:STDOUT: !52 = !DILocation(line: 5, column: 19, scope: !48)
// CHECK:STDOUT: !53 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload0.Main", scope: null, file: !38, line: 7, type: !43, spFlags: DISPFlagDefinition, unit: !39, retainedNodes: !64)
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !53, type: !9)
// CHECK:STDOUT: !55 = !DILocalVariable(arg: 2, scope: !53, type: !9)
// CHECK:STDOUT: !56 = !DILocation(line: 7, column: 28, scope: !53)
// CHECK:STDOUT: !61 = !DILocation(line: 7, column: 54, scope: !53)
// CHECK:STDOUT: !62 = !DILocation(line: 7, column: 65, scope: !53)
// CHECK:STDOUT: !63 = !DILocation(line: 7, column: 47, scope: !53)
// CHECK:STDOUT: !64 = !{!54, !55}
// CHECK:STDOUT: !65 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload1.Main", scope: null, file: !38, line: 8, type: !11, spFlags: DISPFlagDefinition, unit: !39, retainedNodes: !71)
// CHECK:STDOUT: !66 = !DILocalVariable(arg: 1, scope: !65, type: !9)
// CHECK:STDOUT: !70 = !DILocation(line: 8, column: 40, scope: !65)
// CHECK:STDOUT: !71 = !{!66}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !38, line: 10, type: !13, spFlags: DISPFlagDefinition, unit: !39)
// CHECK:STDOUT: !75 = !DILocation(line: 10, column: 28, scope: !72)
// CHECK:STDOUT: !76 = !DILocation(line: 10, column: 26, scope: !72)
// CHECK:STDOUT: !77 = !DILocation(line: 10, column: 41, scope: !72)
// CHECK:STDOUT: !78 = !DILocation(line: 10, column: 50, scope: !72)
// CHECK:STDOUT: !79 = !DILocation(line: 10, column: 39, scope: !72)
// CHECK:STDOUT: !80 = !DILocation(line: 10, column: 19, scope: !72)
// CHECK:STDOUT: !81 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !38, line: 10, type: !45, spFlags: DISPFlagDefinition, unit: !39, retainedNodes: !84)
// CHECK:STDOUT: !82 = !DILocalVariable(arg: 1, scope: !81, type: !6)
// CHECK:STDOUT: !83 = !DILocation(line: 10, column: 50, scope: !81)
// CHECK:STDOUT: !84 = !{!82}
// CHECK:STDOUT: !85 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.92afc3a45a31c789:core.Destroy.Core", scope: null, file: !38, line: 10, type: !47, spFlags: DISPFlagDefinition, unit: !39, retainedNodes: !88)
// CHECK:STDOUT: !86 = !DILocalVariable(arg: 1, scope: !85, type: !9)
// CHECK:STDOUT: !87 = !DILocation(line: 10, column: 50, scope: !85)
// CHECK:STDOUT: !88 = !{!86}
// CHECK:STDOUT: !89 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.92afc3a45a31c789:core.Destroy.Core", scope: null, file: !38, line: 10, type: !47, spFlags: DISPFlagDefinition, unit: !39, retainedNodes: !92)
// CHECK:STDOUT: !90 = !DILocalVariable(arg: 1, scope: !89, type: !9)
// CHECK:STDOUT: !91 = !DILocation(line: 10, column: 50, scope: !89)
// CHECK:STDOUT: !92 = !{!90}
// CHECK:STDOUT: !93 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.08d9e38b928ba575:core.Destroy.Core", scope: null, file: !38, line: 10, type: !47, spFlags: DISPFlagDefinition, unit: !39, retainedNodes: !96)
// CHECK:STDOUT: !94 = !DILocalVariable(arg: 1, scope: !93, type: !9)
// CHECK:STDOUT: !95 = !DILocation(line: 10, column: 50, scope: !93)
// CHECK:STDOUT: !96 = !{!94}
// CHECK:STDOUT: !97 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core", scope: null, file: !38, line: 10, type: !47, spFlags: DISPFlagDefinition, unit: !39, retainedNodes: !100)
// CHECK:STDOUT: !98 = !DILocalVariable(arg: 1, scope: !97, type: !9)
// CHECK:STDOUT: !99 = !DILocation(line: 10, column: 50, scope: !97)
// CHECK:STDOUT: !100 = !{!98}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'template_dependent_default.carbon'
// CHECK:STDOUT: source_filename = "template_dependent_default.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload0.Main"(i32 %x, i32 %y) #0 !dbg !103 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.MulWith.impl.Op.call = mul i32 %x, 10, !dbg !110
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Int.as.MulWith.impl.Op.call, %y, !dbg !110
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !112
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload1.Main"(i1 %b) #0 !dbg !114 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 -1, !dbg !119
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !121 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %T.call.loc11_34 = call i32 @_CT.Main.84588f41d61dafba(i32 1), !dbg !124
// CHECK:STDOUT:   %T.call.loc11_50 = call i32 @_CT.Main.a4c7fafe8a72cac4(i1 true), !dbg !127
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %T.call.loc11_34, %T.call.loc11_50, !dbg !124
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !128
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CT.Main.84588f41d61dafba(i32 %u) #0 !dbg !129 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %F.call.9c1 = call i32 @"_CF:overload0.Main"(i32 %u, i32 2), !dbg !135
// CHECK:STDOUT:   ret i32 %F.call.9c1, !dbg !136
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CT.Main.a4c7fafe8a72cac4(i1 %u) #0 !dbg !138 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %F.call.82c = call i32 @"_CF:overload1.Main"(i1 %u), !dbg !144
// CHECK:STDOUT:   ret i32 %F.call.82c, !dbg !145
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!102}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6, !6, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!6, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !101 = !DIFile(filename: "template_dependent_default.carbon", directory: "")
// CHECK:STDOUT: !102 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !101, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !103 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload0.Main", scope: null, file: !101, line: 4, type: !8, spFlags: DISPFlagDefinition, unit: !102, retainedNodes: !113)
// CHECK:STDOUT: !104 = !DILocalVariable(arg: 1, scope: !103, type: !6)
// CHECK:STDOUT: !105 = !DILocalVariable(arg: 2, scope: !103, type: !6)
// CHECK:STDOUT: !110 = !DILocation(line: 4, column: 51, scope: !103)
// CHECK:STDOUT: !112 = !DILocation(line: 4, column: 44, scope: !103)
// CHECK:STDOUT: !113 = !{!104, !105}
// CHECK:STDOUT: !114 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload1.Main", scope: null, file: !101, line: 5, type: !11, spFlags: DISPFlagDefinition, unit: !102, retainedNodes: !120)
// CHECK:STDOUT: !115 = !DILocalVariable(arg: 1, scope: !114, type: !9)
// CHECK:STDOUT: !119 = !DILocation(line: 5, column: 40, scope: !114)
// CHECK:STDOUT: !120 = !{!115}
// CHECK:STDOUT: !121 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !101, line: 11, type: !13, spFlags: DISPFlagDefinition, unit: !102)
// CHECK:STDOUT: !124 = !DILocation(line: 11, column: 26, scope: !121)
// CHECK:STDOUT: !125 = !{!6, !6}
// CHECK:STDOUT: !126 = !DISubroutineType(types: !125)
// CHECK:STDOUT: !127 = !DILocation(line: 11, column: 38, scope: !121)
// CHECK:STDOUT: !128 = !DILocation(line: 11, column: 19, scope: !121)
// CHECK:STDOUT: !129 = distinct !DISubprogram(name: "T", linkageName: "_CT.Main.84588f41d61dafba", scope: null, file: !101, line: 9, type: !126, spFlags: DISPFlagDefinition, unit: !102, retainedNodes: !137)
// CHECK:STDOUT: !130 = !DILocalVariable(arg: 1, scope: !129, type: !6)
// CHECK:STDOUT: !135 = !DILocation(line: 9, column: 46, scope: !129)
// CHECK:STDOUT: !136 = !DILocation(line: 9, column: 39, scope: !129)
// CHECK:STDOUT: !137 = !{!130}
// CHECK:STDOUT: !138 = distinct !DISubprogram(name: "T", linkageName: "_CT.Main.a4c7fafe8a72cac4", scope: null, file: !101, line: 9, type: !11, spFlags: DISPFlagDefinition, unit: !102, retainedNodes: !146)
// CHECK:STDOUT: !139 = !DILocalVariable(arg: 1, scope: !138, type: !9)
// CHECK:STDOUT: !144 = !DILocation(line: 9, column: 46, scope: !138)
// CHECK:STDOUT: !145 = !DILocation(line: 9, column: 39, scope: !138)
// CHECK:STDOUT: !146 = !{!139}
// CHECK:STDOUT:

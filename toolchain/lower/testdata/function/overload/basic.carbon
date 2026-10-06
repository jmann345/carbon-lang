// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/basic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/basic.carbon

// Every member of an `overload fn` set lowers to its own definition, mangled
// with its set-relative index (`:overload<N>`, D-OV-5); a resolved call names
// the selected member's symbol directly.

// --- two_members.carbon

library "[[@TEST_NAME]]";

overload fn Describe(unused n: i32) -> i32 { return 1; }
overload fn Describe(unused b: bool) -> i32 { return 2; }

fn Use() -> i32 { return Describe(7) + Describe(true); }

// --- first_match_order.carbon

library "[[@TEST_NAME]]";

overload fn Pick(unused x: i64) -> i32 { return 1; }
overload fn Pick(unused x: i32) -> i32 { return 2; }

fn Use(n: i32) -> i32 { return Pick(n); }

// --- arity_dispatch.carbon

library "[[@TEST_NAME]]";

overload fn Sum(a: i32) -> i32 { return a; }
overload fn Sum(a: i32, b: i32) -> i32 { return a + b; }

fn Use() -> i32 { return Sum(1) + Sum(2, 3); }

// --- method_set.carbon

library "[[@TEST_NAME]]";

class Acc {
  var total: i32;
  overload fn Add(ref self, x: i32) { self.total = self.total + x; }
  overload fn Add(ref self, flag: bool) {
    if (flag) { self.total = self.total + 100; }
  }
}

fn Use() {
  var a: Acc = {.total = 0};
  a.Add(1);
  a.Add(true);
}

// --- alias_of_set.carbon

library "[[@TEST_NAME]]";

overload fn Twice(x: i32) -> i32 { return x * 2; }
overload fn Twice(b: bool) -> i32 { if (b) { return 2; } return 0; }

alias Double = Twice;

fn Use() -> i32 { return Double(1) + Double(false); }

// --- local_set.carbon

library "[[@TEST_NAME]]";

fn Outer() -> i32 {
  overload fn L(unused x: i32) -> i32 { return 1; }
  overload fn L(unused b: bool) -> i32 { return 2; }
  return L(true);
}

// --- init_arg.carbon

library "[[@TEST_NAME]]";

// One temporary for the argument, one call to `G` storing into it, one call
// to the selected member, and one cleanup: the rejected probe of the first
// member leaks nothing.
class C {
  var n: i32;
}

fn G() -> C { return {.n = 1}; }

overload fn F(unused b: bool) -> i32 { return 1; }
overload fn F(c: C) -> i32 { return c.n; }

fn Use() -> i32 { return F(G()); }

// --- destroy_arg.carbon

library "[[@TEST_NAME]]";

class D {
  var n: i32;
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

fn MakeD() -> D { return {.n = 1}; }

overload fn F(unused b: bool) -> i32 { return 1; }
overload fn F(d: D) -> i32 { return d.n; }

fn Use() -> i32 { return F(MakeD()); }

// --- literal_range.carbon

library "[[@TEST_NAME]]";

overload fn N(unused x: i8) -> i32 { return 1; }
overload fn N(unused x: i32) -> i32 { return 2; }

overload fn U(unused x: u8) -> i32 { return 1; }
overload fn U(unused x: i32) -> i32 { return 2; }

fn Use() -> i32 { return N(300) + U(-1); }

// --- call_from_generic_body.carbon

library "[[@TEST_NAME]]";

overload fn P(unused x: i32) -> i32 { return 1; }
overload fn P(unused b: bool) -> i32 { return 2; }

fn Gen[T: Core.ImplicitAs(i32)](x: T) -> i32 { return P(x); }

fn Use() -> i32 { return Gen(7 as i16); }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'two_members.carbon'
// CHECK:STDOUT: source_filename = "two_members.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CDescribe:overload0.Main"(i32 %n) #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CDescribe:overload1.Main"(i1 %b) #0 !dbg !21 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !28 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Describe.call.loc7_36 = call i32 @"_CDescribe:overload0.Main"(i32 7), !dbg !31
// CHECK:STDOUT:   %Describe.call.loc7_53 = call i32 @"_CDescribe:overload1.Main"(i1 true), !dbg !32
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Describe.call.loc7_36, %Describe.call.loc7_53, !dbg !31
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "two_members.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!6, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "Describe", linkageName: "_CDescribe:overload0.Main", scope: null, file: !4, line: 4, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !20)
// CHECK:STDOUT: !15 = !DILocalVariable(arg: 1, scope: !14, type: !6)
// CHECK:STDOUT: !19 = !DILocation(line: 4, column: 46, scope: !14)
// CHECK:STDOUT: !20 = !{!15}
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "Describe", linkageName: "_CDescribe:overload1.Main", scope: null, file: !4, line: 5, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !27)
// CHECK:STDOUT: !22 = !DILocalVariable(arg: 1, scope: !21, type: !9)
// CHECK:STDOUT: !26 = !DILocation(line: 5, column: 47, scope: !21)
// CHECK:STDOUT: !27 = !{!22}
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !4, line: 7, type: !13, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !31 = !DILocation(line: 7, column: 26, scope: !28)
// CHECK:STDOUT: !32 = !DILocation(line: 7, column: 40, scope: !28)
// CHECK:STDOUT: !33 = !DILocation(line: 7, column: 19, scope: !28)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'first_match_order.carbon'
// CHECK:STDOUT: source_filename = "first_match_order.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CPick:overload0.Main"(i64 %x) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CPick:overload1.Main"(i32 %x) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main(i32 %n) #0 !dbg !53 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.call = call i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.f4e5d9509bf46ebe"(i32 %n), !dbg !58
// CHECK:STDOUT:   %Pick.call = call i32 @"_CPick:overload0.Main"(i64 %From.as_type.as.ImplicitAs.impl.Convert.call), !dbg !61
// CHECK:STDOUT:   ret i32 %Pick.call, !dbg !62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.f4e5d9509bf46ebe"(i32 %self) #0 !dbg !65 {
// CHECK:STDOUT:   %1 = call i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self), !dbg !70
// CHECK:STDOUT:   %2 = sext i32 %1 to i64, !dbg !71
// CHECK:STDOUT:   ret i64 %2, !dbg !72
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self) #0 !dbg !74 {
// CHECK:STDOUT:   ret i32 %self, !dbg !80
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!35}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !34 = !DIFile(filename: "first_match_order.carbon", directory: "")
// CHECK:STDOUT: !35 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !34, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !36 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !37 = !{!6, !36}
// CHECK:STDOUT: !38 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "Pick", linkageName: "_CPick:overload0.Main", scope: null, file: !34, line: 4, type: !38, spFlags: DISPFlagDefinition, unit: !35, retainedNodes: !45)
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !39, type: !36)
// CHECK:STDOUT: !44 = !DILocation(line: 4, column: 42, scope: !39)
// CHECK:STDOUT: !45 = !{!40}
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "Pick", linkageName: "_CPick:overload1.Main", scope: null, file: !34, line: 5, type: !8, spFlags: DISPFlagDefinition, unit: !35, retainedNodes: !52)
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !46, type: !6)
// CHECK:STDOUT: !51 = !DILocation(line: 5, column: 42, scope: !46)
// CHECK:STDOUT: !52 = !{!47}
// CHECK:STDOUT: !53 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !34, line: 7, type: !8, spFlags: DISPFlagDefinition, unit: !35, retainedNodes: !63)
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !53, type: !6)
// CHECK:STDOUT: !58 = !DILocation(line: 7, column: 37, scope: !53)
// CHECK:STDOUT: !59 = !{!36, !6}
// CHECK:STDOUT: !60 = !DISubroutineType(types: !59)
// CHECK:STDOUT: !61 = !DILocation(line: 7, column: 32, scope: !53)
// CHECK:STDOUT: !62 = !DILocation(line: 7, column: 25, scope: !53)
// CHECK:STDOUT: !63 = !{!54}
// CHECK:STDOUT: !64 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !65 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.f4e5d9509bf46ebe", scope: null, file: !64, line: 64, type: !60, spFlags: DISPFlagDefinition, unit: !35, retainedNodes: !73)
// CHECK:STDOUT: !66 = !DILocalVariable(arg: 1, scope: !65, type: !6)
// CHECK:STDOUT: !70 = !DILocation(line: 66, column: 17, scope: !65)
// CHECK:STDOUT: !71 = !DILocation(line: 66, column: 12, scope: !65)
// CHECK:STDOUT: !72 = !DILocation(line: 66, column: 5, scope: !65)
// CHECK:STDOUT: !73 = !{!66}
// CHECK:STDOUT: !74 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8", scope: null, file: !64, line: 59, type: !8, spFlags: DISPFlagDefinition, unit: !35, retainedNodes: !81)
// CHECK:STDOUT: !75 = !DILocalVariable(arg: 1, scope: !74, type: !6)
// CHECK:STDOUT: !80 = !DILocation(line: 59, column: 28, scope: !74)
// CHECK:STDOUT: !81 = !{!75}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'arity_dispatch.carbon'
// CHECK:STDOUT: source_filename = "arity_dispatch.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CSum:overload0.Main"(i32 %a) #0 !dbg !86 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 %a, !dbg !92
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CSum:overload1.Main"(i32 %a, i32 %b) #0 !dbg !94 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %a, %b, !dbg !101
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !103
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !105 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Sum.call.loc7_31 = call i32 @"_CSum:overload0.Main"(i32 1), !dbg !108
// CHECK:STDOUT:   %Sum.call.loc7_43 = call i32 @"_CSum:overload1.Main"(i32 2, i32 3), !dbg !109
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Sum.call.loc7_31, %Sum.call.loc7_43, !dbg !108
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !110
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!83}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !12 = !{!6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !82 = !DIFile(filename: "arity_dispatch.carbon", directory: "")
// CHECK:STDOUT: !83 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !82, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !84 = !{!6, !6, !6}
// CHECK:STDOUT: !85 = !DISubroutineType(types: !84)
// CHECK:STDOUT: !86 = distinct !DISubprogram(name: "Sum", linkageName: "_CSum:overload0.Main", scope: null, file: !82, line: 4, type: !8, spFlags: DISPFlagDefinition, unit: !83, retainedNodes: !93)
// CHECK:STDOUT: !87 = !DILocalVariable(arg: 1, scope: !86, type: !6)
// CHECK:STDOUT: !92 = !DILocation(line: 4, column: 34, scope: !86)
// CHECK:STDOUT: !93 = !{!87}
// CHECK:STDOUT: !94 = distinct !DISubprogram(name: "Sum", linkageName: "_CSum:overload1.Main", scope: null, file: !82, line: 5, type: !85, spFlags: DISPFlagDefinition, unit: !83, retainedNodes: !104)
// CHECK:STDOUT: !95 = !DILocalVariable(arg: 1, scope: !94, type: !6)
// CHECK:STDOUT: !96 = !DILocalVariable(arg: 2, scope: !94, type: !6)
// CHECK:STDOUT: !101 = !DILocation(line: 5, column: 49, scope: !94)
// CHECK:STDOUT: !103 = !DILocation(line: 5, column: 42, scope: !94)
// CHECK:STDOUT: !104 = !{!95, !96}
// CHECK:STDOUT: !105 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !82, line: 7, type: !13, spFlags: DISPFlagDefinition, unit: !83)
// CHECK:STDOUT: !108 = !DILocation(line: 7, column: 26, scope: !105)
// CHECK:STDOUT: !109 = !DILocation(line: 7, column: 35, scope: !105)
// CHECK:STDOUT: !110 = !DILocation(line: 7, column: 19, scope: !105)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'method_set.carbon'
// CHECK:STDOUT: source_filename = "method_set.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Acc.val.loc13_3 = internal constant { i32 } zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CAdd:overload0.Acc.Main"(ptr %self, i32 %x) #0 !dbg !123 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_43.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !128
// CHECK:STDOUT:   %.loc6_56.1.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !129
// CHECK:STDOUT:   %.loc6_56.2 = load i32, ptr %.loc6_56.1.total, align 4, !dbg !129
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc6_56.2, %x, !dbg !129
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %.loc6_43.total, align 4, !dbg !128
// CHECK:STDOUT:   ret void, !dbg !131
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CAdd:overload1.Acc.Main"(ptr %self, i1 %flag) #0 !dbg !133 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 %flag, label %if.then, label %if.else, !dbg !139
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %.loc8_21.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !140
// CHECK:STDOUT:   %.loc8_34.1.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !141
// CHECK:STDOUT:   %.loc8_34.2 = load i32, ptr %.loc8_34.1.total, align 4, !dbg !141
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc8_34.2, 100, !dbg !141
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %.loc8_21.total, align 4, !dbg !140
// CHECK:STDOUT:   br label %if.else, !dbg !142
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %if.then, %entry
// CHECK:STDOUT:   ret void, !dbg !143
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main() #0 !dbg !145 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.var = alloca { i32 }, align 4, !dbg !146
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a.var), !dbg !146
// CHECK:STDOUT:   %.loc13_27.3.total = getelementptr inbounds nuw { i32 }, ptr %a.var, i32 0, i32 0, !dbg !147
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %a.var, ptr align 4 @Acc.val.loc13_3, i64 4, i1 false), !dbg !146
// CHECK:STDOUT:   call void @"_CAdd:overload0.Acc.Main"(ptr %a.var, i32 1), !dbg !149
// CHECK:STDOUT:   call void @"_CAdd:overload1.Acc.Main"(ptr %a.var, i1 true), !dbg !150
// CHECK:STDOUT:   call void @"_CSelfDestruct.015df1832b8bc891:core.Destroy.Core"(ptr %a.var), !dbg !146
// CHECK:STDOUT:   ret void, !dbg !151
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !152 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !154
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.46a928988f38c7e5:core.Destroy.Core"(ptr %self) #0 !dbg !156 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc13.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !158
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc13.total), !dbg !158
// CHECK:STDOUT:   ret void, !dbg !158
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.46a928988f38c7e5:core.Destroy.Core"(ptr %self) #0 !dbg !160 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.46a928988f38c7e5:core.Destroy.Core"(ptr %self), !dbg !162
// CHECK:STDOUT:   ret void, !dbg !162
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.015df1832b8bc891:core.Destroy.Core"(ptr %self) #0 !dbg !164 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc13.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !166
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc13.total), !dbg !166
// CHECK:STDOUT:   ret void, !dbg !166
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.015df1832b8bc891:core.Destroy.Core"(ptr %self) #0 !dbg !168 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.015df1832b8bc891:core.Destroy.Core"(ptr %self), !dbg !170
// CHECK:STDOUT:   ret void, !dbg !170
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!112}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !111 = !DIFile(filename: "method_set.carbon", directory: "")
// CHECK:STDOUT: !112 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !111, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !113 = !{null, !9, !6}
// CHECK:STDOUT: !114 = !DISubroutineType(types: !113)
// CHECK:STDOUT: !115 = !{null, !9, !9}
// CHECK:STDOUT: !116 = !DISubroutineType(types: !115)
// CHECK:STDOUT: !117 = !{null}
// CHECK:STDOUT: !118 = !DISubroutineType(types: !117)
// CHECK:STDOUT: !119 = !{null, !6}
// CHECK:STDOUT: !120 = !DISubroutineType(types: !119)
// CHECK:STDOUT: !121 = !{null, !9}
// CHECK:STDOUT: !122 = !DISubroutineType(types: !121)
// CHECK:STDOUT: !123 = distinct !DISubprogram(name: "Add", linkageName: "_CAdd:overload0.Acc.Main", scope: null, file: !111, line: 6, type: !114, spFlags: DISPFlagDefinition, unit: !112, retainedNodes: !132)
// CHECK:STDOUT: !124 = !DILocalVariable(arg: 1, scope: !123, type: !9)
// CHECK:STDOUT: !125 = !DILocalVariable(arg: 2, scope: !123, type: !6)
// CHECK:STDOUT: !128 = !DILocation(line: 6, column: 39, scope: !123)
// CHECK:STDOUT: !129 = !DILocation(line: 6, column: 52, scope: !123)
// CHECK:STDOUT: !131 = !DILocation(line: 6, column: 3, scope: !123)
// CHECK:STDOUT: !132 = !{!124, !125}
// CHECK:STDOUT: !133 = distinct !DISubprogram(name: "Add", linkageName: "_CAdd:overload1.Acc.Main", scope: null, file: !111, line: 7, type: !116, spFlags: DISPFlagDefinition, unit: !112, retainedNodes: !144)
// CHECK:STDOUT: !134 = !DILocalVariable(arg: 1, scope: !133, type: !9)
// CHECK:STDOUT: !135 = !DILocalVariable(arg: 2, scope: !133, type: !9)
// CHECK:STDOUT: !139 = !DILocation(line: 8, column: 8, scope: !133)
// CHECK:STDOUT: !140 = !DILocation(line: 8, column: 17, scope: !133)
// CHECK:STDOUT: !141 = !DILocation(line: 8, column: 30, scope: !133)
// CHECK:STDOUT: !142 = !DILocation(line: 8, column: 5, scope: !133)
// CHECK:STDOUT: !143 = !DILocation(line: 7, column: 3, scope: !133)
// CHECK:STDOUT: !144 = !{!134, !135}
// CHECK:STDOUT: !145 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !111, line: 12, type: !118, spFlags: DISPFlagDefinition, unit: !112)
// CHECK:STDOUT: !146 = !DILocation(line: 13, column: 3, scope: !145)
// CHECK:STDOUT: !147 = !DILocation(line: 13, column: 16, scope: !145)
// CHECK:STDOUT: !149 = !DILocation(line: 14, column: 3, scope: !145)
// CHECK:STDOUT: !150 = !DILocation(line: 15, column: 3, scope: !145)
// CHECK:STDOUT: !151 = !DILocation(line: 12, column: 1, scope: !145)
// CHECK:STDOUT: !152 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !111, line: 13, type: !120, spFlags: DISPFlagDefinition, unit: !112, retainedNodes: !155)
// CHECK:STDOUT: !153 = !DILocalVariable(arg: 1, scope: !152, type: !6)
// CHECK:STDOUT: !154 = !DILocation(line: 13, column: 3, scope: !152)
// CHECK:STDOUT: !155 = !{!153}
// CHECK:STDOUT: !156 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.46a928988f38c7e5:core.Destroy.Core", scope: null, file: !111, line: 13, type: !122, spFlags: DISPFlagDefinition, unit: !112, retainedNodes: !159)
// CHECK:STDOUT: !157 = !DILocalVariable(arg: 1, scope: !156, type: !9)
// CHECK:STDOUT: !158 = !DILocation(line: 13, column: 3, scope: !156)
// CHECK:STDOUT: !159 = !{!157}
// CHECK:STDOUT: !160 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.46a928988f38c7e5:core.Destroy.Core", scope: null, file: !111, line: 13, type: !122, spFlags: DISPFlagDefinition, unit: !112, retainedNodes: !163)
// CHECK:STDOUT: !161 = !DILocalVariable(arg: 1, scope: !160, type: !9)
// CHECK:STDOUT: !162 = !DILocation(line: 13, column: 3, scope: !160)
// CHECK:STDOUT: !163 = !{!161}
// CHECK:STDOUT: !164 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.015df1832b8bc891:core.Destroy.Core", scope: null, file: !111, line: 13, type: !122, spFlags: DISPFlagDefinition, unit: !112, retainedNodes: !167)
// CHECK:STDOUT: !165 = !DILocalVariable(arg: 1, scope: !164, type: !9)
// CHECK:STDOUT: !166 = !DILocation(line: 13, column: 3, scope: !164)
// CHECK:STDOUT: !167 = !{!165}
// CHECK:STDOUT: !168 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.015df1832b8bc891:core.Destroy.Core", scope: null, file: !111, line: 13, type: !122, spFlags: DISPFlagDefinition, unit: !112, retainedNodes: !171)
// CHECK:STDOUT: !169 = !DILocalVariable(arg: 1, scope: !168, type: !9)
// CHECK:STDOUT: !170 = !DILocation(line: 13, column: 3, scope: !168)
// CHECK:STDOUT: !171 = !{!169}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'alias_of_set.carbon'
// CHECK:STDOUT: source_filename = "alias_of_set.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CTwice:overload0.Main"(i32 %x) #0 !dbg !174 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.MulWith.impl.Op.call = mul i32 %x, 2, !dbg !179
// CHECK:STDOUT:   ret i32 %Int.as.MulWith.impl.Op.call, !dbg !180
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CTwice:overload1.Main"(i1 %b) #0 !dbg !182 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 %b, label %if.then, label %if.else, !dbg !188
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   ret i32 2, !dbg !189
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !190
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !192 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Twice.call.loc9_34 = call i32 @"_CTwice:overload0.Main"(i32 1), !dbg !195
// CHECK:STDOUT:   %Twice.call.loc9_50 = call i32 @"_CTwice:overload1.Main"(i1 false), !dbg !196
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Twice.call.loc9_34, %Twice.call.loc9_50, !dbg !195
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !197
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!173}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!6, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !172 = !DIFile(filename: "alias_of_set.carbon", directory: "")
// CHECK:STDOUT: !173 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !172, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !174 = distinct !DISubprogram(name: "Twice", linkageName: "_CTwice:overload0.Main", scope: null, file: !172, line: 4, type: !8, spFlags: DISPFlagDefinition, unit: !173, retainedNodes: !181)
// CHECK:STDOUT: !175 = !DILocalVariable(arg: 1, scope: !174, type: !6)
// CHECK:STDOUT: !179 = !DILocation(line: 4, column: 43, scope: !174)
// CHECK:STDOUT: !180 = !DILocation(line: 4, column: 36, scope: !174)
// CHECK:STDOUT: !181 = !{!175}
// CHECK:STDOUT: !182 = distinct !DISubprogram(name: "Twice", linkageName: "_CTwice:overload1.Main", scope: null, file: !172, line: 5, type: !11, spFlags: DISPFlagDefinition, unit: !173, retainedNodes: !191)
// CHECK:STDOUT: !183 = !DILocalVariable(arg: 1, scope: !182, type: !9)
// CHECK:STDOUT: !188 = !DILocation(line: 5, column: 40, scope: !182)
// CHECK:STDOUT: !189 = !DILocation(line: 5, column: 46, scope: !182)
// CHECK:STDOUT: !190 = !DILocation(line: 5, column: 58, scope: !182)
// CHECK:STDOUT: !191 = !{!183}
// CHECK:STDOUT: !192 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !172, line: 9, type: !13, spFlags: DISPFlagDefinition, unit: !173)
// CHECK:STDOUT: !195 = !DILocation(line: 9, column: 26, scope: !192)
// CHECK:STDOUT: !196 = !DILocation(line: 9, column: 38, scope: !192)
// CHECK:STDOUT: !197 = !DILocation(line: 9, column: 19, scope: !192)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'local_set.carbon'
// CHECK:STDOUT: source_filename = "local_set.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_COuter.Main() #0 !dbg !200 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %L.call = call i32 @"_CL:overload1:enclosed"(i1 true), !dbg !203
// CHECK:STDOUT:   ret i32 %L.call, !dbg !204
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CL:overload0:enclosed"(i32 %x) #0 !dbg !205 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !210
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CL:overload1:enclosed"(i1 %b) #0 !dbg !212 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !217
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!199}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!6, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !198 = !DIFile(filename: "local_set.carbon", directory: "")
// CHECK:STDOUT: !199 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !198, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !200 = distinct !DISubprogram(name: "Outer", linkageName: "_COuter.Main", scope: null, file: !198, line: 4, type: !13, spFlags: DISPFlagDefinition, unit: !199)
// CHECK:STDOUT: !203 = !DILocation(line: 7, column: 10, scope: !200)
// CHECK:STDOUT: !204 = !DILocation(line: 7, column: 3, scope: !200)
// CHECK:STDOUT: !205 = distinct !DISubprogram(name: "L", linkageName: "_CL:overload0:enclosed", scope: null, file: !198, line: 5, type: !8, spFlags: DISPFlagDefinition, unit: !199, retainedNodes: !211)
// CHECK:STDOUT: !206 = !DILocalVariable(arg: 1, scope: !205, type: !6)
// CHECK:STDOUT: !210 = !DILocation(line: 5, column: 41, scope: !205)
// CHECK:STDOUT: !211 = !{!206}
// CHECK:STDOUT: !212 = distinct !DISubprogram(name: "L", linkageName: "_CL:overload1:enclosed", scope: null, file: !198, line: 6, type: !11, spFlags: DISPFlagDefinition, unit: !199, retainedNodes: !218)
// CHECK:STDOUT: !213 = !DILocalVariable(arg: 1, scope: !212, type: !9)
// CHECK:STDOUT: !217 = !DILocation(line: 6, column: 42, scope: !212)
// CHECK:STDOUT: !218 = !{!213}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'init_arg.carbon'
// CHECK:STDOUT: source_filename = "init_arg.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @C.val.loc11_30 = internal constant { i32 } { i32 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CG.Main(ptr sret({ i32 }) %return) #0 !dbg !223 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc11_29.3.n = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !226
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @C.val.loc11_30, i64 4, i1 false), !dbg !227
// CHECK:STDOUT:   ret void, !dbg !227
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload0.Main"(i1 %b) #0 !dbg !228 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !233
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload1.Main"(ptr %c) #0 !dbg !235 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14_38.1.n = getelementptr inbounds nuw { i32 }, ptr %c, i32 0, i32 0, !dbg !240
// CHECK:STDOUT:   %.loc14_38.2 = load i32, ptr %.loc14_38.1.n, align 4, !dbg !240
// CHECK:STDOUT:   ret i32 %.loc14_38.2, !dbg !241
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !243 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_30.1.temp = alloca { i32 }, align 4, !dbg !246
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc16_30.1.temp), !dbg !246
// CHECK:STDOUT:   call void @_CG.Main(ptr %.loc16_30.1.temp), !dbg !246
// CHECK:STDOUT:   %F.call = call i32 @"_CF:overload1.Main"(ptr %.loc16_30.1.temp), !dbg !247
// CHECK:STDOUT:   call void @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core"(ptr %.loc16_30.1.temp), !dbg !246
// CHECK:STDOUT:   ret i32 %F.call, !dbg !248
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !249 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !251
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.9edb2ca1f7e7a271:core.Destroy.Core"(ptr %self) #0 !dbg !253 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16.n = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !255
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc16.n), !dbg !255
// CHECK:STDOUT:   ret void, !dbg !255
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.9edb2ca1f7e7a271:core.Destroy.Core"(ptr %self) #0 !dbg !257 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.9edb2ca1f7e7a271:core.Destroy.Core"(ptr %self), !dbg !259
// CHECK:STDOUT:   ret void, !dbg !259
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.08d9e38b928ba575:core.Destroy.Core"(ptr %self) #0 !dbg !261 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16.n = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !263
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc16.n), !dbg !263
// CHECK:STDOUT:   ret void, !dbg !263
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core"(ptr %self) #0 !dbg !265 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.08d9e38b928ba575:core.Destroy.Core"(ptr %self), !dbg !267
// CHECK:STDOUT:   ret void, !dbg !267
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!220}
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
// CHECK:STDOUT: !119 = !{null, !6}
// CHECK:STDOUT: !120 = !DISubroutineType(types: !119)
// CHECK:STDOUT: !121 = !{null, !9}
// CHECK:STDOUT: !122 = !DISubroutineType(types: !121)
// CHECK:STDOUT: !219 = !DIFile(filename: "init_arg.carbon", directory: "")
// CHECK:STDOUT: !220 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !219, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !221 = !{!9}
// CHECK:STDOUT: !222 = !DISubroutineType(types: !221)
// CHECK:STDOUT: !223 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main", scope: null, file: !219, line: 11, type: !222, spFlags: DISPFlagDefinition, unit: !220)
// CHECK:STDOUT: !226 = !DILocation(line: 11, column: 22, scope: !223)
// CHECK:STDOUT: !227 = !DILocation(line: 11, column: 15, scope: !223)
// CHECK:STDOUT: !228 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload0.Main", scope: null, file: !219, line: 13, type: !11, spFlags: DISPFlagDefinition, unit: !220, retainedNodes: !234)
// CHECK:STDOUT: !229 = !DILocalVariable(arg: 1, scope: !228, type: !9)
// CHECK:STDOUT: !233 = !DILocation(line: 13, column: 40, scope: !228)
// CHECK:STDOUT: !234 = !{!229}
// CHECK:STDOUT: !235 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload1.Main", scope: null, file: !219, line: 14, type: !11, spFlags: DISPFlagDefinition, unit: !220, retainedNodes: !242)
// CHECK:STDOUT: !236 = !DILocalVariable(arg: 1, scope: !235, type: !9)
// CHECK:STDOUT: !240 = !DILocation(line: 14, column: 37, scope: !235)
// CHECK:STDOUT: !241 = !DILocation(line: 14, column: 30, scope: !235)
// CHECK:STDOUT: !242 = !{!236}
// CHECK:STDOUT: !243 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !219, line: 16, type: !13, spFlags: DISPFlagDefinition, unit: !220)
// CHECK:STDOUT: !246 = !DILocation(line: 16, column: 28, scope: !243)
// CHECK:STDOUT: !247 = !DILocation(line: 16, column: 26, scope: !243)
// CHECK:STDOUT: !248 = !DILocation(line: 16, column: 19, scope: !243)
// CHECK:STDOUT: !249 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !219, line: 16, type: !120, spFlags: DISPFlagDefinition, unit: !220, retainedNodes: !252)
// CHECK:STDOUT: !250 = !DILocalVariable(arg: 1, scope: !249, type: !6)
// CHECK:STDOUT: !251 = !DILocation(line: 16, column: 28, scope: !249)
// CHECK:STDOUT: !252 = !{!250}
// CHECK:STDOUT: !253 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.9edb2ca1f7e7a271:core.Destroy.Core", scope: null, file: !219, line: 16, type: !122, spFlags: DISPFlagDefinition, unit: !220, retainedNodes: !256)
// CHECK:STDOUT: !254 = !DILocalVariable(arg: 1, scope: !253, type: !9)
// CHECK:STDOUT: !255 = !DILocation(line: 16, column: 28, scope: !253)
// CHECK:STDOUT: !256 = !{!254}
// CHECK:STDOUT: !257 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.9edb2ca1f7e7a271:core.Destroy.Core", scope: null, file: !219, line: 16, type: !122, spFlags: DISPFlagDefinition, unit: !220, retainedNodes: !260)
// CHECK:STDOUT: !258 = !DILocalVariable(arg: 1, scope: !257, type: !9)
// CHECK:STDOUT: !259 = !DILocation(line: 16, column: 28, scope: !257)
// CHECK:STDOUT: !260 = !{!258}
// CHECK:STDOUT: !261 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.08d9e38b928ba575:core.Destroy.Core", scope: null, file: !219, line: 16, type: !122, spFlags: DISPFlagDefinition, unit: !220, retainedNodes: !264)
// CHECK:STDOUT: !262 = !DILocalVariable(arg: 1, scope: !261, type: !9)
// CHECK:STDOUT: !263 = !DILocation(line: 16, column: 28, scope: !261)
// CHECK:STDOUT: !264 = !{!262}
// CHECK:STDOUT: !265 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.08d9e38b928ba575:core.Destroy.Core", scope: null, file: !219, line: 16, type: !122, spFlags: DISPFlagDefinition, unit: !220, retainedNodes: !268)
// CHECK:STDOUT: !266 = !DILocalVariable(arg: 1, scope: !265, type: !9)
// CHECK:STDOUT: !267 = !DILocation(line: 16, column: 28, scope: !265)
// CHECK:STDOUT: !268 = !{!266}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'destroy_arg.carbon'
// CHECK:STDOUT: source_filename = "destroy_arg.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @D.val.loc11_34 = internal constant { i32 } { i32 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.D.Main:Destroy.Core"(ptr %self) #0 !dbg !271 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !274
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeD.Main(ptr sret({ i32 }) %return) #0 !dbg !276 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc11_33.3.n = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !279
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @D.val.loc11_34, i64 4, i1 false), !dbg !280
// CHECK:STDOUT:   ret void, !dbg !280
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload0.Main"(i1 %b) #0 !dbg !281 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !286
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload1.Main"(ptr %d) #0 !dbg !288 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14_38.1.n = getelementptr inbounds nuw { i32 }, ptr %d, i32 0, i32 0, !dbg !293
// CHECK:STDOUT:   %.loc14_38.2 = load i32, ptr %.loc14_38.1.n, align 4, !dbg !293
// CHECK:STDOUT:   ret i32 %.loc14_38.2, !dbg !294
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !296 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_34.1.temp = alloca { i32 }, align 4, !dbg !299
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc16_34.1.temp), !dbg !299
// CHECK:STDOUT:   call void @_CMakeD.Main(ptr %.loc16_34.1.temp), !dbg !299
// CHECK:STDOUT:   %F.call = call i32 @"_CF:overload1.Main"(ptr %.loc16_34.1.temp), !dbg !300
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.5613f446ca4e6e1f(ptr %.loc16_34.1.temp), !dbg !299
// CHECK:STDOUT:   ret i32 %F.call, !dbg !301
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.5613f446ca4e6e1f(ptr %self) #0 !dbg !303 {
// CHECK:STDOUT:   call void @"_COp.D.Main:Destroy.Core"(ptr %self), !dbg !306
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.5613f446ca4e6e1f(ptr %self), !dbg !307
// CHECK:STDOUT:   ret void, !dbg !308
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.5613f446ca4e6e1f(ptr %self) #0 !dbg !310 {
// CHECK:STDOUT:   ret void, !dbg !313
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!270}
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
// CHECK:STDOUT: !121 = !{null, !9}
// CHECK:STDOUT: !122 = !DISubroutineType(types: !121)
// CHECK:STDOUT: !221 = !{!9}
// CHECK:STDOUT: !222 = !DISubroutineType(types: !221)
// CHECK:STDOUT: !269 = !DIFile(filename: "destroy_arg.carbon", directory: "")
// CHECK:STDOUT: !270 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !269, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !271 = distinct !DISubprogram(name: "Op", linkageName: "_COp.D.Main:Destroy.Core", scope: null, file: !269, line: 7, type: !122, spFlags: DISPFlagDefinition, unit: !270, retainedNodes: !275)
// CHECK:STDOUT: !272 = !DILocalVariable(arg: 1, scope: !271, type: !9)
// CHECK:STDOUT: !274 = !DILocation(line: 7, column: 5, scope: !271)
// CHECK:STDOUT: !275 = !{!272}
// CHECK:STDOUT: !276 = distinct !DISubprogram(name: "MakeD", linkageName: "_CMakeD.Main", scope: null, file: !269, line: 11, type: !222, spFlags: DISPFlagDefinition, unit: !270)
// CHECK:STDOUT: !279 = !DILocation(line: 11, column: 26, scope: !276)
// CHECK:STDOUT: !280 = !DILocation(line: 11, column: 19, scope: !276)
// CHECK:STDOUT: !281 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload0.Main", scope: null, file: !269, line: 13, type: !11, spFlags: DISPFlagDefinition, unit: !270, retainedNodes: !287)
// CHECK:STDOUT: !282 = !DILocalVariable(arg: 1, scope: !281, type: !9)
// CHECK:STDOUT: !286 = !DILocation(line: 13, column: 40, scope: !281)
// CHECK:STDOUT: !287 = !{!282}
// CHECK:STDOUT: !288 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload1.Main", scope: null, file: !269, line: 14, type: !11, spFlags: DISPFlagDefinition, unit: !270, retainedNodes: !295)
// CHECK:STDOUT: !289 = !DILocalVariable(arg: 1, scope: !288, type: !9)
// CHECK:STDOUT: !293 = !DILocation(line: 14, column: 37, scope: !288)
// CHECK:STDOUT: !294 = !DILocation(line: 14, column: 30, scope: !288)
// CHECK:STDOUT: !295 = !{!289}
// CHECK:STDOUT: !296 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !269, line: 16, type: !13, spFlags: DISPFlagDefinition, unit: !270)
// CHECK:STDOUT: !299 = !DILocation(line: 16, column: 28, scope: !296)
// CHECK:STDOUT: !300 = !DILocation(line: 16, column: 26, scope: !296)
// CHECK:STDOUT: !301 = !DILocation(line: 16, column: 19, scope: !296)
// CHECK:STDOUT: !302 = !DIFile(filename: "{{.*}}/prelude/destroy.carbon", directory: "")
// CHECK:STDOUT: !303 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.5613f446ca4e6e1f", scope: null, file: !302, line: 26, type: !122, spFlags: DISPFlagDefinition, unit: !270, retainedNodes: !309)
// CHECK:STDOUT: !304 = !DILocalVariable(arg: 1, scope: !303, type: !9)
// CHECK:STDOUT: !306 = !DILocation(line: 27, column: 5, scope: !303)
// CHECK:STDOUT: !307 = !DILocation(line: 28, column: 5, scope: !303)
// CHECK:STDOUT: !308 = !DILocation(line: 26, column: 3, scope: !303)
// CHECK:STDOUT: !309 = !{!304}
// CHECK:STDOUT: !310 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.5613f446ca4e6e1f", scope: null, file: !302, line: 19, type: !122, spFlags: DISPFlagDefinition, unit: !270, retainedNodes: !314)
// CHECK:STDOUT: !311 = !DILocalVariable(arg: 1, scope: !310, type: !9)
// CHECK:STDOUT: !313 = !DILocation(line: 19, column: 3, scope: !310)
// CHECK:STDOUT: !314 = !{!311}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'literal_range.carbon'
// CHECK:STDOUT: source_filename = "literal_range.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CN:overload0.Main"(i8 %x) #0 !dbg !323 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !328
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CN:overload1.Main"(i32 %x) #0 !dbg !330 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !335
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CU:overload0.Main"(i8 %x) #0 !dbg !337 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !342
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CU:overload1.Main"(i32 %x) #0 !dbg !344 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !349
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !351 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %N.call = call i32 @"_CN:overload1.Main"(i32 300), !dbg !354
// CHECK:STDOUT:   %U.call = call i32 @"_CU:overload1.Main"(i32 -1), !dbg !355
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %N.call, %U.call, !dbg !354
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !356
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!316}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !12 = !{!6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !315 = !DIFile(filename: "literal_range.carbon", directory: "")
// CHECK:STDOUT: !316 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !315, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !317 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_signed)
// CHECK:STDOUT: !318 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !319 = !{!6, !317}
// CHECK:STDOUT: !320 = !DISubroutineType(types: !319)
// CHECK:STDOUT: !321 = !{!6, !318}
// CHECK:STDOUT: !322 = !DISubroutineType(types: !321)
// CHECK:STDOUT: !323 = distinct !DISubprogram(name: "N", linkageName: "_CN:overload0.Main", scope: null, file: !315, line: 4, type: !320, spFlags: DISPFlagDefinition, unit: !316, retainedNodes: !329)
// CHECK:STDOUT: !324 = !DILocalVariable(arg: 1, scope: !323, type: !317)
// CHECK:STDOUT: !328 = !DILocation(line: 4, column: 38, scope: !323)
// CHECK:STDOUT: !329 = !{!324}
// CHECK:STDOUT: !330 = distinct !DISubprogram(name: "N", linkageName: "_CN:overload1.Main", scope: null, file: !315, line: 5, type: !8, spFlags: DISPFlagDefinition, unit: !316, retainedNodes: !336)
// CHECK:STDOUT: !331 = !DILocalVariable(arg: 1, scope: !330, type: !6)
// CHECK:STDOUT: !335 = !DILocation(line: 5, column: 39, scope: !330)
// CHECK:STDOUT: !336 = !{!331}
// CHECK:STDOUT: !337 = distinct !DISubprogram(name: "U", linkageName: "_CU:overload0.Main", scope: null, file: !315, line: 7, type: !322, spFlags: DISPFlagDefinition, unit: !316, retainedNodes: !343)
// CHECK:STDOUT: !338 = !DILocalVariable(arg: 1, scope: !337, type: !318)
// CHECK:STDOUT: !342 = !DILocation(line: 7, column: 38, scope: !337)
// CHECK:STDOUT: !343 = !{!338}
// CHECK:STDOUT: !344 = distinct !DISubprogram(name: "U", linkageName: "_CU:overload1.Main", scope: null, file: !315, line: 8, type: !8, spFlags: DISPFlagDefinition, unit: !316, retainedNodes: !350)
// CHECK:STDOUT: !345 = !DILocalVariable(arg: 1, scope: !344, type: !6)
// CHECK:STDOUT: !349 = !DILocation(line: 8, column: 39, scope: !344)
// CHECK:STDOUT: !350 = !{!345}
// CHECK:STDOUT: !351 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !315, line: 10, type: !13, spFlags: DISPFlagDefinition, unit: !316)
// CHECK:STDOUT: !354 = !DILocation(line: 10, column: 26, scope: !351)
// CHECK:STDOUT: !355 = !DILocation(line: 10, column: 35, scope: !351)
// CHECK:STDOUT: !356 = !DILocation(line: 10, column: 19, scope: !351)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'call_from_generic_body.carbon'
// CHECK:STDOUT: source_filename = "call_from_generic_body.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CP:overload0.Main"(i32 %x) #0 !dbg !360 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !365
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CP:overload1.Main"(i1 %b) #0 !dbg !367 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !372
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !374 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Gen.call = call i32 @_CGen.Main.98ea571c96480402(i16 7), !dbg !377
// CHECK:STDOUT:   ret i32 %Gen.call, !dbg !380
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGen.Main.98ea571c96480402(i16 %x) #0 !dbg !381 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.call = call i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.e49b19ea36cc6fd2"(i16 %x), !dbg !386
// CHECK:STDOUT:   %P.call = call i32 @"_CP:overload0.Main"(i32 %ImplicitAs.WithSelf.Convert.call), !dbg !387
// CHECK:STDOUT:   ret i32 %P.call, !dbg !388
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.e49b19ea36cc6fd2"(i16 %self) #0 !dbg !390 {
// CHECK:STDOUT:   %1 = call i16 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.cc6a1d911f1c2d3f"(i16 %self), !dbg !395
// CHECK:STDOUT:   %2 = sext i16 %1 to i32, !dbg !398
// CHECK:STDOUT:   ret i32 %2, !dbg !399
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i16 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.cc6a1d911f1c2d3f"(i16 %self) #0 !dbg !401 {
// CHECK:STDOUT:   ret i16 %self, !dbg !407
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!358}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!6, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !64 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !357 = !DIFile(filename: "call_from_generic_body.carbon", directory: "")
// CHECK:STDOUT: !358 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !357, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !359 = !DIBasicType(name: "int", size: 16, encoding: DW_ATE_signed)
// CHECK:STDOUT: !360 = distinct !DISubprogram(name: "P", linkageName: "_CP:overload0.Main", scope: null, file: !357, line: 4, type: !8, spFlags: DISPFlagDefinition, unit: !358, retainedNodes: !366)
// CHECK:STDOUT: !361 = !DILocalVariable(arg: 1, scope: !360, type: !6)
// CHECK:STDOUT: !365 = !DILocation(line: 4, column: 39, scope: !360)
// CHECK:STDOUT: !366 = !{!361}
// CHECK:STDOUT: !367 = distinct !DISubprogram(name: "P", linkageName: "_CP:overload1.Main", scope: null, file: !357, line: 5, type: !11, spFlags: DISPFlagDefinition, unit: !358, retainedNodes: !373)
// CHECK:STDOUT: !368 = !DILocalVariable(arg: 1, scope: !367, type: !9)
// CHECK:STDOUT: !372 = !DILocation(line: 5, column: 40, scope: !367)
// CHECK:STDOUT: !373 = !{!368}
// CHECK:STDOUT: !374 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !357, line: 9, type: !13, spFlags: DISPFlagDefinition, unit: !358)
// CHECK:STDOUT: !377 = !DILocation(line: 9, column: 26, scope: !374)
// CHECK:STDOUT: !378 = !{!6, !359}
// CHECK:STDOUT: !379 = !DISubroutineType(types: !378)
// CHECK:STDOUT: !380 = !DILocation(line: 9, column: 19, scope: !374)
// CHECK:STDOUT: !381 = distinct !DISubprogram(name: "Gen", linkageName: "_CGen.Main.98ea571c96480402", scope: null, file: !357, line: 7, type: !379, spFlags: DISPFlagDefinition, unit: !358, retainedNodes: !389)
// CHECK:STDOUT: !382 = !DILocalVariable(arg: 1, scope: !381, type: !359)
// CHECK:STDOUT: !386 = !DILocation(line: 7, column: 57, scope: !381)
// CHECK:STDOUT: !387 = !DILocation(line: 7, column: 55, scope: !381)
// CHECK:STDOUT: !388 = !DILocation(line: 7, column: 48, scope: !381)
// CHECK:STDOUT: !389 = !{!382}
// CHECK:STDOUT: !390 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.e49b19ea36cc6fd2", scope: null, file: !64, line: 64, type: !379, spFlags: DISPFlagDefinition, unit: !358, retainedNodes: !400)
// CHECK:STDOUT: !391 = !DILocalVariable(arg: 1, scope: !390, type: !359)
// CHECK:STDOUT: !395 = !DILocation(line: 66, column: 17, scope: !390)
// CHECK:STDOUT: !396 = !{!359, !359}
// CHECK:STDOUT: !397 = !DISubroutineType(types: !396)
// CHECK:STDOUT: !398 = !DILocation(line: 66, column: 12, scope: !390)
// CHECK:STDOUT: !399 = !DILocation(line: 66, column: 5, scope: !390)
// CHECK:STDOUT: !400 = !{!391}
// CHECK:STDOUT: !401 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.cc6a1d911f1c2d3f", scope: null, file: !64, line: 59, type: !397, spFlags: DISPFlagDefinition, unit: !358, retainedNodes: !408)
// CHECK:STDOUT: !402 = !DILocalVariable(arg: 1, scope: !401, type: !359)
// CHECK:STDOUT: !407 = !DILocation(line: 59, column: 28, scope: !401)
// CHECK:STDOUT: !408 = !{!402}
// CHECK:STDOUT:

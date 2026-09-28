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

// CHECK:STDERR: two_members.carbon:[[@LINE+4]]:22: warning: binding `n` unused [UnusedBinding]
// CHECK:STDERR: overload fn Describe(n: i32) -> i32 { return 1; }
// CHECK:STDERR:                      ^~~~~~
// CHECK:STDERR:
overload fn Describe(n: i32) -> i32 { return 1; }
// CHECK:STDERR: two_members.carbon:[[@LINE+4]]:22: warning: binding `b` unused [UnusedBinding]
// CHECK:STDERR: overload fn Describe(b: bool) -> i32 { return 2; }
// CHECK:STDERR:                      ^~~~~~~
// CHECK:STDERR:
overload fn Describe(b: bool) -> i32 { return 2; }

fn Use() -> i32 { return Describe(7) + Describe(true); }

// --- first_match_order.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: first_match_order.carbon:[[@LINE+4]]:18: warning: binding `x` unused [UnusedBinding]
// CHECK:STDERR: overload fn Pick(x: i64) -> i32 { return 1; }
// CHECK:STDERR:                  ^~~~~~
// CHECK:STDERR:
overload fn Pick(x: i64) -> i32 { return 1; }
// CHECK:STDERR: first_match_order.carbon:[[@LINE+4]]:18: warning: binding `x` unused [UnusedBinding]
// CHECK:STDERR: overload fn Pick(x: i32) -> i32 { return 2; }
// CHECK:STDERR:                  ^~~~~~
// CHECK:STDERR:
overload fn Pick(x: i32) -> i32 { return 2; }

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
  // CHECK:STDERR: local_set.carbon:[[@LINE+4]]:17: warning: binding `x` unused [UnusedBinding]
  // CHECK:STDERR:   overload fn L(x: i32) -> i32 { return 1; }
  // CHECK:STDERR:                 ^~~~~~
  // CHECK:STDERR:
  overload fn L(x: i32) -> i32 { return 1; }
  // CHECK:STDERR: local_set.carbon:[[@LINE+4]]:17: warning: binding `b` unused [UnusedBinding]
  // CHECK:STDERR:   overload fn L(b: bool) -> i32 { return 2; }
  // CHECK:STDERR:                 ^~~~~~~
  // CHECK:STDERR:
  overload fn L(b: bool) -> i32 { return 2; }
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

// CHECK:STDERR: init_arg.carbon:[[@LINE+4]]:15: warning: binding `b` unused [UnusedBinding]
// CHECK:STDERR: overload fn F(b: bool) -> i32 { return 1; }
// CHECK:STDERR:               ^~~~~~~
// CHECK:STDERR:
overload fn F(b: bool) -> i32 { return 1; }
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

// CHECK:STDERR: destroy_arg.carbon:[[@LINE+4]]:15: warning: binding `b` unused [UnusedBinding]
// CHECK:STDERR: overload fn F(b: bool) -> i32 { return 1; }
// CHECK:STDERR:               ^~~~~~~
// CHECK:STDERR:
overload fn F(b: bool) -> i32 { return 1; }
overload fn F(d: D) -> i32 { return d.n; }

fn Use() -> i32 { return F(MakeD()); }

// --- literal_range.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: literal_range.carbon:[[@LINE+4]]:15: warning: binding `x` unused [UnusedBinding]
// CHECK:STDERR: overload fn N(x: i8) -> i32 { return 1; }
// CHECK:STDERR:               ^~~~~
// CHECK:STDERR:
overload fn N(x: i8) -> i32 { return 1; }
// CHECK:STDERR: literal_range.carbon:[[@LINE+4]]:15: warning: binding `x` unused [UnusedBinding]
// CHECK:STDERR: overload fn N(x: i32) -> i32 { return 2; }
// CHECK:STDERR:               ^~~~~~
// CHECK:STDERR:
overload fn N(x: i32) -> i32 { return 2; }

// CHECK:STDERR: literal_range.carbon:[[@LINE+4]]:15: warning: binding `x` unused [UnusedBinding]
// CHECK:STDERR: overload fn U(x: u8) -> i32 { return 1; }
// CHECK:STDERR:               ^~~~~
// CHECK:STDERR:
overload fn U(x: u8) -> i32 { return 1; }
// CHECK:STDERR: literal_range.carbon:[[@LINE+4]]:15: warning: binding `x` unused [UnusedBinding]
// CHECK:STDERR: overload fn U(x: i32) -> i32 { return 2; }
// CHECK:STDERR:               ^~~~~~
// CHECK:STDERR:
overload fn U(x: i32) -> i32 { return 2; }

fn Use() -> i32 { return N(300) + U(-1); }

// --- call_from_generic_body.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: call_from_generic_body.carbon:[[@LINE+4]]:15: warning: binding `x` unused [UnusedBinding]
// CHECK:STDERR: overload fn P(x: i32) -> i32 { return 1; }
// CHECK:STDERR:               ^~~~~~
// CHECK:STDERR:
overload fn P(x: i32) -> i32 { return 1; }
// CHECK:STDERR: call_from_generic_body.carbon:[[@LINE+4]]:15: warning: binding `b` unused [UnusedBinding]
// CHECK:STDERR: overload fn P(b: bool) -> i32 { return 2; }
// CHECK:STDERR:               ^~~~~~~
// CHECK:STDERR:
overload fn P(b: bool) -> i32 { return 2; }

fn Gen[T: Core.ImplicitAs(i32)](x: T) -> i32 { return P(x); }

fn Use() -> i32 { return Gen(7 as i16); }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'two_members.carbon'
// CHECK:STDOUT: source_filename = "two_members.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CDescribe:overload0.Main"(i32 %n) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !10
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CDescribe:overload1.Main"(i1 %b) #0 !dbg !11 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Describe.call.loc7_36 = call i32 @"_CDescribe:overload0.Main"(i32 7), !dbg !21
// CHECK:STDOUT:   %Describe.call.loc7_53 = call i32 @"_CDescribe:overload1.Main"(i1 true), !dbg !22
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Describe.call.loc7_36, %Describe.call.loc7_53, !dbg !21
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !23
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "two_members.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Describe", linkageName: "_CDescribe:overload0.Main", scope: null, file: !1, line: 4, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{!9}
// CHECK:STDOUT: !9 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !10 = !DILocation(line: 4, column: 39, scope: !4)
// CHECK:STDOUT: !11 = distinct !DISubprogram(name: "Describe", linkageName: "_CDescribe:overload1.Main", scope: null, file: !1, line: 5, type: !12, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !15)
// CHECK:STDOUT: !12 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !13 = !{!7, !14}
// CHECK:STDOUT: !14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !15 = !{!16}
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 1, scope: !11, type: !14)
// CHECK:STDOUT: !17 = !DILocation(line: 5, column: 40, scope: !11)
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 7, type: !19, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !19 = !DISubroutineType(types: !20)
// CHECK:STDOUT: !20 = !{!7}
// CHECK:STDOUT: !21 = !DILocation(line: 7, column: 26, scope: !18)
// CHECK:STDOUT: !22 = !DILocation(line: 7, column: 40, scope: !18)
// CHECK:STDOUT: !23 = !DILocation(line: 7, column: 19, scope: !18)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'first_match_order.carbon'
// CHECK:STDOUT: source_filename = "first_match_order.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CPick:overload0.Main"(i64 %x) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CPick:overload1.Main"(i32 %x) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main(i32 %n) #0 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.call = call i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.f4e5d9509bf46ebe"(i32 %n), !dbg !21
// CHECK:STDOUT:   %Pick.call = call i32 @"_CPick:overload0.Main"(i64 %From.as_type.as.ImplicitAs.impl.Convert.call), !dbg !22
// CHECK:STDOUT:   ret i32 %Pick.call, !dbg !23
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.f4e5d9509bf46ebe"(i32 %self) #0 !dbg !24 {
// CHECK:STDOUT:   %1 = call i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self), !dbg !30
// CHECK:STDOUT:   %2 = sext i32 %1 to i64, !dbg !31
// CHECK:STDOUT:   ret i64 %2, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self) #0 !dbg !33 {
// CHECK:STDOUT:   ret i32 %self, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "first_match_order.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Pick", linkageName: "_CPick:overload0.Main", scope: null, file: !1, line: 4, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 4, column: 35, scope: !4)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "Pick", linkageName: "_CPick:overload1.Main", scope: null, file: !1, line: 5, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !15)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{!7, !7}
// CHECK:STDOUT: !15 = !{!16}
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 1, scope: !12, type: !7)
// CHECK:STDOUT: !17 = !DILocation(line: 5, column: 35, scope: !12)
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 7, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !19)
// CHECK:STDOUT: !19 = !{!20}
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !18, type: !7)
// CHECK:STDOUT: !21 = !DILocation(line: 7, column: 37, scope: !18)
// CHECK:STDOUT: !22 = !DILocation(line: 7, column: 32, scope: !18)
// CHECK:STDOUT: !23 = !DILocation(line: 7, column: 25, scope: !18)
// CHECK:STDOUT: !24 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.f4e5d9509bf46ebe", scope: null, file: !25, line: 64, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !28)
// CHECK:STDOUT: !25 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !26 = !DISubroutineType(types: !27)
// CHECK:STDOUT: !27 = !{!8, !7}
// CHECK:STDOUT: !28 = !{!29}
// CHECK:STDOUT: !29 = !DILocalVariable(arg: 1, scope: !24, type: !7)
// CHECK:STDOUT: !30 = !DILocation(line: 66, column: 17, scope: !24)
// CHECK:STDOUT: !31 = !DILocation(line: 66, column: 12, scope: !24)
// CHECK:STDOUT: !32 = !DILocation(line: 66, column: 5, scope: !24)
// CHECK:STDOUT: !33 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8", scope: null, file: !25, line: 59, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !34)
// CHECK:STDOUT: !34 = !{!35}
// CHECK:STDOUT: !35 = !DILocalVariable(arg: 1, scope: !33, type: !7)
// CHECK:STDOUT: !36 = !DILocation(line: 59, column: 28, scope: !33)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'arity_dispatch.carbon'
// CHECK:STDOUT: source_filename = "arity_dispatch.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CSum:overload0.Main"(i32 %a) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 %a, !dbg !10
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CSum:overload1.Main"(i32 %a, i32 %b) #0 !dbg !11 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %a, %b, !dbg !17
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !18
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Sum.call.loc7_31 = call i32 @"_CSum:overload0.Main"(i32 1), !dbg !22
// CHECK:STDOUT:   %Sum.call.loc7_43 = call i32 @"_CSum:overload1.Main"(i32 2, i32 3), !dbg !23
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Sum.call.loc7_31, %Sum.call.loc7_43, !dbg !22
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "arity_dispatch.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Sum", linkageName: "_CSum:overload0.Main", scope: null, file: !1, line: 4, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{!9}
// CHECK:STDOUT: !9 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !10 = !DILocation(line: 4, column: 34, scope: !4)
// CHECK:STDOUT: !11 = distinct !DISubprogram(name: "Sum", linkageName: "_CSum:overload1.Main", scope: null, file: !1, line: 5, type: !12, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !14)
// CHECK:STDOUT: !12 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !13 = !{!7, !7, !7}
// CHECK:STDOUT: !14 = !{!15, !16}
// CHECK:STDOUT: !15 = !DILocalVariable(arg: 1, scope: !11, type: !7)
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 2, scope: !11, type: !7)
// CHECK:STDOUT: !17 = !DILocation(line: 5, column: 49, scope: !11)
// CHECK:STDOUT: !18 = !DILocation(line: 5, column: 42, scope: !11)
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 7, type: !20, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !20 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !21 = !{!7}
// CHECK:STDOUT: !22 = !DILocation(line: 7, column: 26, scope: !19)
// CHECK:STDOUT: !23 = !DILocation(line: 7, column: 35, scope: !19)
// CHECK:STDOUT: !24 = !DILocation(line: 7, column: 19, scope: !19)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'method_set.carbon'
// CHECK:STDOUT: source_filename = "method_set.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Acc.val.loc13_3 = internal constant { i32 } zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CAdd:overload0.Acc.Main"(ptr %self, i32 %x) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_43.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !12
// CHECK:STDOUT:   %.loc6_56.1.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !13
// CHECK:STDOUT:   %.loc6_56.2 = load i32, ptr %.loc6_56.1.total, align 4, !dbg !13
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc6_56.2, %x, !dbg !13
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %.loc6_43.total, align 4, !dbg !12
// CHECK:STDOUT:   ret void, !dbg !14
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CAdd:overload1.Acc.Main"(ptr %self, i1 %flag) #0 !dbg !15 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 %flag, label %if.then, label %if.else, !dbg !21
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %.loc8_21.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !22
// CHECK:STDOUT:   %.loc8_34.1.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !23
// CHECK:STDOUT:   %.loc8_34.2 = load i32, ptr %.loc8_34.1.total, align 4, !dbg !23
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc8_34.2, 100, !dbg !23
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %.loc8_21.total, align 4, !dbg !22
// CHECK:STDOUT:   br label %if.else, !dbg !24
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %if.then, %entry
// CHECK:STDOUT:   ret void, !dbg !25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main() #0 !dbg !26 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.var = alloca { i32 }, align 4, !dbg !29
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a.var), !dbg !29
// CHECK:STDOUT:   %.loc13_27.3.total = getelementptr inbounds nuw { i32 }, ptr %a.var, i32 0, i32 0, !dbg !30
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %a.var, ptr align 4 @Acc.val.loc13_3, i64 4, i1 false), !dbg !29
// CHECK:STDOUT:   call void @"_CAdd:overload0.Acc.Main"(ptr %a.var, i32 1), !dbg !31
// CHECK:STDOUT:   call void @"_CAdd:overload1.Acc.Main"(ptr %a.var, i1 true), !dbg !32
// CHECK:STDOUT:   call void @"_COp.9b3055ad2e1c4660:core.Destroy.Core"(ptr %a.var), !dbg !29
// CHECK:STDOUT:   ret void, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.f9469129122daa09:core.Destroy.Core"(ptr %self) #0 !dbg !40 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.9b3055ad2e1c4660:core.Destroy.Core"(ptr %self) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !49
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "method_set.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Add", linkageName: "_CAdd:overload0.Acc.Main", scope: null, file: !1, line: 6, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{null, !7, !8}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10, !11}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !11 = !DILocalVariable(arg: 2, scope: !4, type: !8)
// CHECK:STDOUT: !12 = !DILocation(line: 6, column: 39, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 6, column: 52, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 6, column: 3, scope: !4)
// CHECK:STDOUT: !15 = distinct !DISubprogram(name: "Add", linkageName: "_CAdd:overload1.Acc.Main", scope: null, file: !1, line: 7, type: !16, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !18)
// CHECK:STDOUT: !16 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !17 = !{null, !7, !7}
// CHECK:STDOUT: !18 = !{!19, !20}
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 1, scope: !15, type: !7)
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 2, scope: !15, type: !7)
// CHECK:STDOUT: !21 = !DILocation(line: 8, column: 8, scope: !15)
// CHECK:STDOUT: !22 = !DILocation(line: 8, column: 17, scope: !15)
// CHECK:STDOUT: !23 = !DILocation(line: 8, column: 30, scope: !15)
// CHECK:STDOUT: !24 = !DILocation(line: 8, column: 5, scope: !15)
// CHECK:STDOUT: !25 = !DILocation(line: 7, column: 3, scope: !15)
// CHECK:STDOUT: !26 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 12, type: !27, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !27 = !DISubroutineType(types: !28)
// CHECK:STDOUT: !28 = !{null}
// CHECK:STDOUT: !29 = !DILocation(line: 13, column: 3, scope: !26)
// CHECK:STDOUT: !30 = !DILocation(line: 13, column: 16, scope: !26)
// CHECK:STDOUT: !31 = !DILocation(line: 14, column: 3, scope: !26)
// CHECK:STDOUT: !32 = !DILocation(line: 15, column: 3, scope: !26)
// CHECK:STDOUT: !33 = !DILocation(line: 12, column: 1, scope: !26)
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 13, type: !35, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !37)
// CHECK:STDOUT: !35 = !DISubroutineType(types: !36)
// CHECK:STDOUT: !36 = !{null, !8}
// CHECK:STDOUT: !37 = !{!38}
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !34, type: !8)
// CHECK:STDOUT: !39 = !DILocation(line: 13, column: 3, scope: !34)
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "Op", linkageName: "_COp.f9469129122daa09:core.Destroy.Core", scope: null, file: !1, line: 13, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !43)
// CHECK:STDOUT: !41 = !DISubroutineType(types: !42)
// CHECK:STDOUT: !42 = !{null, !7}
// CHECK:STDOUT: !43 = !{!44}
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !40, type: !7)
// CHECK:STDOUT: !45 = !DILocation(line: 13, column: 3, scope: !40)
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "Op", linkageName: "_COp.9b3055ad2e1c4660:core.Destroy.Core", scope: null, file: !1, line: 13, type: !41, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !47)
// CHECK:STDOUT: !47 = !{!48}
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !46, type: !7)
// CHECK:STDOUT: !49 = !DILocation(line: 13, column: 3, scope: !46)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'alias_of_set.carbon'
// CHECK:STDOUT: source_filename = "alias_of_set.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CTwice:overload0.Main"(i32 %x) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.MulWith.impl.Op.call = mul i32 %x, 2, !dbg !10
// CHECK:STDOUT:   ret i32 %Int.as.MulWith.impl.Op.call, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CTwice:overload1.Main"(i1 %b) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 %b, label %if.then, label %if.else, !dbg !18
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   ret i32 2, !dbg !19
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !20
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !21 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Twice.call.loc9_34 = call i32 @"_CTwice:overload0.Main"(i32 1), !dbg !24
// CHECK:STDOUT:   %Twice.call.loc9_50 = call i32 @"_CTwice:overload1.Main"(i1 false), !dbg !25
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Twice.call.loc9_34, %Twice.call.loc9_50, !dbg !24
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "alias_of_set.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Twice", linkageName: "_CTwice:overload0.Main", scope: null, file: !1, line: 4, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{!9}
// CHECK:STDOUT: !9 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !10 = !DILocation(line: 4, column: 43, scope: !4)
// CHECK:STDOUT: !11 = !DILocation(line: 4, column: 36, scope: !4)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "Twice", linkageName: "_CTwice:overload1.Main", scope: null, file: !1, line: 5, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !16)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{!7, !15}
// CHECK:STDOUT: !15 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !16 = !{!17}
// CHECK:STDOUT: !17 = !DILocalVariable(arg: 1, scope: !12, type: !15)
// CHECK:STDOUT: !18 = !DILocation(line: 5, column: 40, scope: !12)
// CHECK:STDOUT: !19 = !DILocation(line: 5, column: 46, scope: !12)
// CHECK:STDOUT: !20 = !DILocation(line: 5, column: 58, scope: !12)
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 9, type: !22, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !22 = !DISubroutineType(types: !23)
// CHECK:STDOUT: !23 = !{!7}
// CHECK:STDOUT: !24 = !DILocation(line: 9, column: 26, scope: !21)
// CHECK:STDOUT: !25 = !DILocation(line: 9, column: 38, scope: !21)
// CHECK:STDOUT: !26 = !DILocation(line: 9, column: 19, scope: !21)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'local_set.carbon'
// CHECK:STDOUT: source_filename = "local_set.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_COuter.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %L.call = call i32 @"_CL:overload1:enclosed"(i1 true), !dbg !8
// CHECK:STDOUT:   ret i32 %L.call, !dbg !9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CL:overload0:enclosed"(i32 %x) #0 !dbg !10 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !15
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CL:overload1:enclosed"(i1 %b) #0 !dbg !16 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !22
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "local_set.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Outer", linkageName: "_COuter.Main", scope: null, file: !1, line: 4, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 7, column: 10, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 7, column: 3, scope: !4)
// CHECK:STDOUT: !10 = distinct !DISubprogram(name: "L", linkageName: "_CL:overload0:enclosed", scope: null, file: !1, line: 5, type: !11, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !13)
// CHECK:STDOUT: !11 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !12 = !{!7, !7}
// CHECK:STDOUT: !13 = !{!14}
// CHECK:STDOUT: !14 = !DILocalVariable(arg: 1, scope: !10, type: !7)
// CHECK:STDOUT: !15 = !DILocation(line: 5, column: 34, scope: !10)
// CHECK:STDOUT: !16 = distinct !DISubprogram(name: "L", linkageName: "_CL:overload1:enclosed", scope: null, file: !1, line: 6, type: !17, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !20)
// CHECK:STDOUT: !17 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !18 = !{!7, !19}
// CHECK:STDOUT: !19 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !20 = !{!21}
// CHECK:STDOUT: !21 = !DILocalVariable(arg: 1, scope: !16, type: !19)
// CHECK:STDOUT: !22 = !DILocation(line: 6, column: 35, scope: !16)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'init_arg.carbon'
// CHECK:STDOUT: source_filename = "init_arg.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @C.val.loc11_30 = internal constant { i32 } { i32 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CG.Main(ptr sret({ i32 }) %return) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc11_29.3.n = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !8
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @C.val.loc11_30, i64 4, i1 false), !dbg !9
// CHECK:STDOUT:   ret void, !dbg !9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload0.Main"(i1 %b) #0 !dbg !10 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload1.Main"(ptr %c) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14_38.1.n = getelementptr inbounds nuw { i32 }, ptr %c, i32 0, i32 0, !dbg !20
// CHECK:STDOUT:   %.loc14_38.2 = load i32, ptr %.loc14_38.1.n, align 4, !dbg !20
// CHECK:STDOUT:   ret i32 %.loc14_38.2, !dbg !21
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !22 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_30.1.temp = alloca { i32 }, align 4, !dbg !25
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc16_30.1.temp), !dbg !25
// CHECK:STDOUT:   call void @_CG.Main(ptr %.loc16_30.1.temp), !dbg !25
// CHECK:STDOUT:   %F.call = call i32 @"_CF:overload1.Main"(ptr %.loc16_30.1.temp), !dbg !26
// CHECK:STDOUT:   call void @"_COp.cbd14a388b4a1c25:core.Destroy.Core"(ptr %.loc16_30.1.temp), !dbg !25
// CHECK:STDOUT:   ret i32 %F.call, !dbg !27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !28 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.b1b85bf5fbbbeec6:core.Destroy.Core"(ptr %self) #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.cbd14a388b4a1c25:core.Destroy.Core"(ptr %self) #0 !dbg !40 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !43
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "init_arg.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main", scope: null, file: !1, line: 11, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !DILocation(line: 11, column: 22, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 11, column: 15, scope: !4)
// CHECK:STDOUT: !10 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload0.Main", scope: null, file: !1, line: 13, type: !11, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !14)
// CHECK:STDOUT: !11 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !12 = !{!13, !7}
// CHECK:STDOUT: !13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !14 = !{!15}
// CHECK:STDOUT: !15 = !DILocalVariable(arg: 1, scope: !10, type: !7)
// CHECK:STDOUT: !16 = !DILocation(line: 13, column: 33, scope: !10)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload1.Main", scope: null, file: !1, line: 14, type: !11, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !18)
// CHECK:STDOUT: !18 = !{!19}
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 1, scope: !17, type: !7)
// CHECK:STDOUT: !20 = !DILocation(line: 14, column: 37, scope: !17)
// CHECK:STDOUT: !21 = !DILocation(line: 14, column: 30, scope: !17)
// CHECK:STDOUT: !22 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 16, type: !23, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !23 = !DISubroutineType(types: !24)
// CHECK:STDOUT: !24 = !{!13}
// CHECK:STDOUT: !25 = !DILocation(line: 16, column: 28, scope: !22)
// CHECK:STDOUT: !26 = !DILocation(line: 16, column: 26, scope: !22)
// CHECK:STDOUT: !27 = !DILocation(line: 16, column: 19, scope: !22)
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 16, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !31)
// CHECK:STDOUT: !29 = !DISubroutineType(types: !30)
// CHECK:STDOUT: !30 = !{null, !13}
// CHECK:STDOUT: !31 = !{!32}
// CHECK:STDOUT: !32 = !DILocalVariable(arg: 1, scope: !28, type: !13)
// CHECK:STDOUT: !33 = !DILocation(line: 16, column: 28, scope: !28)
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "Op", linkageName: "_COp.b1b85bf5fbbbeec6:core.Destroy.Core", scope: null, file: !1, line: 16, type: !35, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !37)
// CHECK:STDOUT: !35 = !DISubroutineType(types: !36)
// CHECK:STDOUT: !36 = !{null, !7}
// CHECK:STDOUT: !37 = !{!38}
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !34, type: !7)
// CHECK:STDOUT: !39 = !DILocation(line: 16, column: 28, scope: !34)
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "Op", linkageName: "_COp.cbd14a388b4a1c25:core.Destroy.Core", scope: null, file: !1, line: 16, type: !35, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !41)
// CHECK:STDOUT: !41 = !{!42}
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !40, type: !7)
// CHECK:STDOUT: !43 = !DILocation(line: 16, column: 28, scope: !40)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'destroy_arg.carbon'
// CHECK:STDOUT: source_filename = "destroy_arg.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @D.val.loc11_34 = internal constant { i32 } { i32 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.D.Main:Destroy.Core"(ptr %self) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !10
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeD.Main(ptr sret({ i32 }) %return) #0 !dbg !11 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc11_33.3.n = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !14
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @D.val.loc11_34, i64 4, i1 false), !dbg !15
// CHECK:STDOUT:   ret void, !dbg !15
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload0.Main"(i1 %b) #0 !dbg !16 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !22
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload1.Main"(ptr %d) #0 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14_38.1.n = getelementptr inbounds nuw { i32 }, ptr %d, i32 0, i32 0, !dbg !26
// CHECK:STDOUT:   %.loc14_38.2 = load i32, ptr %.loc14_38.1.n, align 4, !dbg !26
// CHECK:STDOUT:   ret i32 %.loc14_38.2, !dbg !27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !28 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_34.1.temp = alloca { i32 }, align 4, !dbg !31
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc16_34.1.temp), !dbg !31
// CHECK:STDOUT:   call void @_CMakeD.Main(ptr %.loc16_34.1.temp), !dbg !31
// CHECK:STDOUT:   %F.call = call i32 @"_CF:overload1.Main"(ptr %.loc16_34.1.temp), !dbg !32
// CHECK:STDOUT:   call void @"_COp.86bfabb7802f32e5:core.Destroy.Core"(ptr %.loc16_34.1.temp), !dbg !31
// CHECK:STDOUT:   ret i32 %F.call, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.b1b85bf5fbbbeec6:core.Destroy.Core"(ptr %self) #0 !dbg !40 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.86bfabb7802f32e5:core.Destroy.Core"(ptr %self) #0 !dbg !44 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !47
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "destroy_arg.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Op", linkageName: "_COp.D.Main:Destroy.Core", scope: null, file: !1, line: 7, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{null, !7}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!9}
// CHECK:STDOUT: !9 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !10 = !DILocation(line: 7, column: 5, scope: !4)
// CHECK:STDOUT: !11 = distinct !DISubprogram(name: "MakeD", linkageName: "_CMakeD.Main", scope: null, file: !1, line: 11, type: !12, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !12 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !13 = !{!7}
// CHECK:STDOUT: !14 = !DILocation(line: 11, column: 26, scope: !11)
// CHECK:STDOUT: !15 = !DILocation(line: 11, column: 19, scope: !11)
// CHECK:STDOUT: !16 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload0.Main", scope: null, file: !1, line: 13, type: !17, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !20)
// CHECK:STDOUT: !17 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !18 = !{!19, !7}
// CHECK:STDOUT: !19 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !20 = !{!21}
// CHECK:STDOUT: !21 = !DILocalVariable(arg: 1, scope: !16, type: !7)
// CHECK:STDOUT: !22 = !DILocation(line: 13, column: 33, scope: !16)
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload1.Main", scope: null, file: !1, line: 14, type: !17, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !24)
// CHECK:STDOUT: !24 = !{!25}
// CHECK:STDOUT: !25 = !DILocalVariable(arg: 1, scope: !23, type: !7)
// CHECK:STDOUT: !26 = !DILocation(line: 14, column: 37, scope: !23)
// CHECK:STDOUT: !27 = !DILocation(line: 14, column: 30, scope: !23)
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 16, type: !29, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !29 = !DISubroutineType(types: !30)
// CHECK:STDOUT: !30 = !{!19}
// CHECK:STDOUT: !31 = !DILocation(line: 16, column: 28, scope: !28)
// CHECK:STDOUT: !32 = !DILocation(line: 16, column: 26, scope: !28)
// CHECK:STDOUT: !33 = !DILocation(line: 16, column: 19, scope: !28)
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 16, type: !35, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !37)
// CHECK:STDOUT: !35 = !DISubroutineType(types: !36)
// CHECK:STDOUT: !36 = !{null, !19}
// CHECK:STDOUT: !37 = !{!38}
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !34, type: !19)
// CHECK:STDOUT: !39 = !DILocation(line: 16, column: 28, scope: !34)
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "Op", linkageName: "_COp.b1b85bf5fbbbeec6:core.Destroy.Core", scope: null, file: !1, line: 16, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !41)
// CHECK:STDOUT: !41 = !{!42}
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !40, type: !7)
// CHECK:STDOUT: !43 = !DILocation(line: 16, column: 28, scope: !40)
// CHECK:STDOUT: !44 = distinct !DISubprogram(name: "Op", linkageName: "_COp.86bfabb7802f32e5:core.Destroy.Core", scope: null, file: !1, line: 16, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !45)
// CHECK:STDOUT: !45 = !{!46}
// CHECK:STDOUT: !46 = !DILocalVariable(arg: 1, scope: !44, type: !7)
// CHECK:STDOUT: !47 = !DILocation(line: 16, column: 28, scope: !44)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'literal_range.carbon'
// CHECK:STDOUT: source_filename = "literal_range.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CN:overload0.Main"(i8 %x) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CN:overload1.Main"(i32 %x) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CU:overload0.Main"(i8 %x) #0 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CU:overload1.Main"(i32 %x) #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !29 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %N.call = call i32 @"_CN:overload1.Main"(i32 300), !dbg !32
// CHECK:STDOUT:   %U.call = call i32 @"_CU:overload1.Main"(i32 -1), !dbg !33
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %N.call, %U.call, !dbg !32
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "literal_range.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "N", linkageName: "_CN:overload0.Main", scope: null, file: !1, line: 4, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 4, column: 31, scope: !4)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "N", linkageName: "_CN:overload1.Main", scope: null, file: !1, line: 5, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !15)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{!7, !7}
// CHECK:STDOUT: !15 = !{!16}
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 1, scope: !12, type: !7)
// CHECK:STDOUT: !17 = !DILocation(line: 5, column: 32, scope: !12)
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "U", linkageName: "_CU:overload0.Main", scope: null, file: !1, line: 7, type: !19, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !22)
// CHECK:STDOUT: !19 = !DISubroutineType(types: !20)
// CHECK:STDOUT: !20 = !{!7, !21}
// CHECK:STDOUT: !21 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !22 = !{!23}
// CHECK:STDOUT: !23 = !DILocalVariable(arg: 1, scope: !18, type: !21)
// CHECK:STDOUT: !24 = !DILocation(line: 7, column: 31, scope: !18)
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "U", linkageName: "_CU:overload1.Main", scope: null, file: !1, line: 8, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
// CHECK:STDOUT: !26 = !{!27}
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 1, scope: !25, type: !7)
// CHECK:STDOUT: !28 = !DILocation(line: 8, column: 32, scope: !25)
// CHECK:STDOUT: !29 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 10, type: !30, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !30 = !DISubroutineType(types: !31)
// CHECK:STDOUT: !31 = !{!7}
// CHECK:STDOUT: !32 = !DILocation(line: 10, column: 26, scope: !29)
// CHECK:STDOUT: !33 = !DILocation(line: 10, column: 35, scope: !29)
// CHECK:STDOUT: !34 = !DILocation(line: 10, column: 19, scope: !29)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'call_from_generic_body.carbon'
// CHECK:STDOUT: source_filename = "call_from_generic_body.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CP:overload0.Main"(i32 %x) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !10
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CP:overload1.Main"(i1 %b) #0 !dbg !11 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Gen.call = call i32 @_CGen.Main.98ea571c96480402(i16 7), !dbg !21
// CHECK:STDOUT:   ret i32 %Gen.call, !dbg !22
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGen.Main.98ea571c96480402(i16 %x) #0 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.call = call i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.e49b19ea36cc6fd2"(i16 %x), !dbg !29
// CHECK:STDOUT:   %P.call = call i32 @"_CP:overload0.Main"(i32 %ImplicitAs.WithSelf.Convert.call), !dbg !30
// CHECK:STDOUT:   ret i32 %P.call, !dbg !31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.e49b19ea36cc6fd2"(i16 %self) #0 !dbg !32 {
// CHECK:STDOUT:   %1 = call i16 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.cc6a1d911f1c2d3f"(i16 %self), !dbg !36
// CHECK:STDOUT:   %2 = sext i16 %1 to i32, !dbg !37
// CHECK:STDOUT:   ret i32 %2, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i16 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.cc6a1d911f1c2d3f"(i16 %self) #0 !dbg !39 {
// CHECK:STDOUT:   ret i16 %self, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "call_from_generic_body.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "P", linkageName: "_CP:overload0.Main", scope: null, file: !1, line: 4, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{!9}
// CHECK:STDOUT: !9 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !10 = !DILocation(line: 4, column: 32, scope: !4)
// CHECK:STDOUT: !11 = distinct !DISubprogram(name: "P", linkageName: "_CP:overload1.Main", scope: null, file: !1, line: 5, type: !12, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !15)
// CHECK:STDOUT: !12 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !13 = !{!7, !14}
// CHECK:STDOUT: !14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !15 = !{!16}
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 1, scope: !11, type: !14)
// CHECK:STDOUT: !17 = !DILocation(line: 5, column: 33, scope: !11)
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 9, type: !19, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !19 = !DISubroutineType(types: !20)
// CHECK:STDOUT: !20 = !{!7}
// CHECK:STDOUT: !21 = !DILocation(line: 9, column: 26, scope: !18)
// CHECK:STDOUT: !22 = !DILocation(line: 9, column: 19, scope: !18)
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "Gen", linkageName: "_CGen.Main.98ea571c96480402", scope: null, file: !1, line: 7, type: !24, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !27)
// CHECK:STDOUT: !24 = !DISubroutineType(types: !25)
// CHECK:STDOUT: !25 = !{!7, !26}
// CHECK:STDOUT: !26 = !DIBasicType(name: "int", size: 16, encoding: DW_ATE_signed)
// CHECK:STDOUT: !27 = !{!28}
// CHECK:STDOUT: !28 = !DILocalVariable(arg: 1, scope: !23, type: !26)
// CHECK:STDOUT: !29 = !DILocation(line: 7, column: 57, scope: !23)
// CHECK:STDOUT: !30 = !DILocation(line: 7, column: 55, scope: !23)
// CHECK:STDOUT: !31 = !DILocation(line: 7, column: 48, scope: !23)
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.e49b19ea36cc6fd2", scope: null, file: !33, line: 64, type: !24, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !34)
// CHECK:STDOUT: !33 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !34 = !{!35}
// CHECK:STDOUT: !35 = !DILocalVariable(arg: 1, scope: !32, type: !26)
// CHECK:STDOUT: !36 = !DILocation(line: 66, column: 17, scope: !32)
// CHECK:STDOUT: !37 = !DILocation(line: 66, column: 12, scope: !32)
// CHECK:STDOUT: !38 = !DILocation(line: 66, column: 5, scope: !32)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.cc6a1d911f1c2d3f", scope: null, file: !33, line: 59, type: !40, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !42)
// CHECK:STDOUT: !40 = !DISubroutineType(types: !41)
// CHECK:STDOUT: !41 = !{!26, !26}
// CHECK:STDOUT: !42 = !{!43}
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !39, type: !26)
// CHECK:STDOUT: !44 = !DILocation(line: 59, column: 28, scope: !39)
// CHECK:STDOUT:

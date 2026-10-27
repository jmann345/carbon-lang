// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/pack_expansion.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/pack_expansion.carbon

// --- sum.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn Sum(... each n: i64) -> i64 {
  var total: i64 = 0;
  ... total = Add(total, each n);
  return total;
}

fn SumOfDoubles(... each m: i64) -> i64 {
  return Sum(... Add(each m, each m));
}

fn Call() -> i64 {
  return Add(Add(Sum(1, 2, 3), Sum()), SumOfDoubles(4, 5));
}

// --- generic_element.carbon
library "[[@TEST_NAME]]";

fn Consume[T: type](unused x: T) {}

fn ForEach[T: type](... each x: T) {
  ... Consume(each x);
}

fn Run() {
  ForEach(true, false);
  ForEach(1 as i32);
}

// --- class_element.carbon
library "[[@TEST_NAME]]";

class C {
  var a: i64;
}

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn Get(c: C) -> i64 {
  return c.a;
}

fn SumFields(... each c: C) -> i64 {
  var total: i64 = 0;
  ... total = Add(total, Get(each c));
  return total;
}

fn Call(c: C, d: C) -> i64 {
  return SumFields(c, d);
}

// --- arg_order.carbon
library "[[@TEST_NAME]]";

fn P(x: i64) -> i64;

fn Digits(first: i64, ... unused each mid: i64, unused last: i64) -> i64 {
  return first;
}

fn Plain(... each x: i64) -> i64 {
  return Digits(P(1), ... P(each x), P(9));
}

fn Call() -> i64 {
  return Plain(2, 3);
}

// --- forward_converted_field.carbon
library "[[@TEST_NAME]]";

class Wrap {
  var n: i64;
}

impl Wrap as Core.ImplicitAs(i64) {
  fn Convert(self) -> i64 { return self.n; }
}

class Holder {
  var w: Wrap;
}

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn Sum(... each n: i64) -> i64 {
  var total: i64 = 0;
  ... total = Add(total, each n);
  return total;
}

fn SumHeld(... each h: Holder) -> i64 {
  return Sum(... each h.w);
}

fn Call(h: Holder, k: Holder) -> i64 {
  return SumHeld(h, k);
}

// --- lib.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn Sum(... each n: i64) -> i64 {
  var total: i64 = 0;
  ... total = Add(total, each n);
  return total;
}

// --- use.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Call() -> i64 {
  return Add(Sum(1, 2), Sum(3, 4, 5));
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'sum.carbon'
// CHECK:STDOUT: source_filename = "sum.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @.f83.loc16_22.5 = internal constant [3 x i64] [i64 1, i64 2, i64 3]
// CHECK:STDOUT: @.92b.loc16_36.3 = internal constant [0 x i64] zeroinitializer
// CHECK:STDOUT: @.33d.loc16_53.5 = internal constant [2 x i64] [i64 4, i64 5]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CCall.Main() #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Sum.call.loc16_29 = call i64 @_CSum.Main.935b24abbbc86de3(ptr @.f83.loc16_22.5), !dbg !47
// CHECK:STDOUT:   %Sum.call.loc16_36 = call i64 @_CSum.Main.a950572c82f13f26(ptr @.92b.loc16_36.3), !dbg !51
// CHECK:STDOUT:   %Add.call.loc16_37 = add i64 %Sum.call.loc16_29, %Sum.call.loc16_36, !dbg !52
// CHECK:STDOUT:   %SumOfDoubles.call = call i64 @_CSumOfDoubles.Main.91a8a89714fbc21c(ptr @.33d.loc16_53.5), !dbg !54
// CHECK:STDOUT:   %Add.call.loc16_58 = add i64 %Add.call.loc16_37, %SumOfDoubles.call, !dbg !55
// CHECK:STDOUT:   ret i64 %Add.call.loc16_58, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CSum.Main.935b24abbbc86de3(ptr %n) #0 !dbg !57 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.var = alloca i64, align 8, !dbg !62
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %total.var), !dbg !62
// CHECK:STDOUT:   store i64 0, ptr %total.var, align 8, !dbg !62
// CHECK:STDOUT:   %.loc7_26.2.pack.elem = getelementptr inbounds [3 x i64], ptr %n, i32 0, i32 0, !dbg !67
// CHECK:STDOUT:   %.loc7_26.2.pack.elem.load = load i64, ptr %.loc7_26.2.pack.elem, align 8, !dbg !67
// CHECK:STDOUT:   %.loc7_19 = load i64, ptr %total.var, align 8, !dbg !66
// CHECK:STDOUT:   %Add.call = add i64 %.loc7_19, %.loc7_26.2.pack.elem.load, !dbg !68
// CHECK:STDOUT:   store i64 %Add.call, ptr %total.var, align 8, !dbg !65
// CHECK:STDOUT:   %.loc7_26.2.pack.elem1 = getelementptr inbounds [3 x i64], ptr %n, i32 0, i32 1, !dbg !67
// CHECK:STDOUT:   %.loc7_26.2.pack.elem.load2 = load i64, ptr %.loc7_26.2.pack.elem1, align 8, !dbg !67
// CHECK:STDOUT:   %.loc7_193 = load i64, ptr %total.var, align 8, !dbg !66
// CHECK:STDOUT:   %Add.call4 = add i64 %.loc7_193, %.loc7_26.2.pack.elem.load2, !dbg !68
// CHECK:STDOUT:   store i64 %Add.call4, ptr %total.var, align 8, !dbg !65
// CHECK:STDOUT:   %.loc7_26.2.pack.elem5 = getelementptr inbounds [3 x i64], ptr %n, i32 0, i32 2, !dbg !67
// CHECK:STDOUT:   %.loc7_26.2.pack.elem.load6 = load i64, ptr %.loc7_26.2.pack.elem5, align 8, !dbg !67
// CHECK:STDOUT:   %.loc7_197 = load i64, ptr %total.var, align 8, !dbg !66
// CHECK:STDOUT:   %Add.call8 = add i64 %.loc7_197, %.loc7_26.2.pack.elem.load6, !dbg !68
// CHECK:STDOUT:   store i64 %Add.call8, ptr %total.var, align 8, !dbg !65
// CHECK:STDOUT:   %.loc8 = load i64, ptr %total.var, align 8, !dbg !69
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %total.var), !dbg !62
// CHECK:STDOUT:   ret i64 %.loc8, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CSum.Main.a950572c82f13f26(ptr %n) #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.var = alloca i64, align 8, !dbg !77
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %total.var), !dbg !77
// CHECK:STDOUT:   store i64 0, ptr %total.var, align 8, !dbg !77
// CHECK:STDOUT:   %.loc8 = load i64, ptr %total.var, align 8, !dbg !80
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %total.var), !dbg !77
// CHECK:STDOUT:   ret i64 %.loc8, !dbg !81
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CSumOfDoubles.Main.91a8a89714fbc21c(ptr %m) #0 !dbg !83 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12_14.pack = alloca [2 x i64], align 8, !dbg !88
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc12_14.pack), !dbg !88
// CHECK:STDOUT:   %.loc12_22.2.pack.elem = getelementptr inbounds [2 x i64], ptr %m, i32 0, i32 0, !dbg !89
// CHECK:STDOUT:   %.loc12_22.2.pack.elem.load = load i64, ptr %.loc12_22.2.pack.elem, align 8, !dbg !89
// CHECK:STDOUT:   %.loc12_30.2.pack.elem = getelementptr inbounds [2 x i64], ptr %m, i32 0, i32 0, !dbg !90
// CHECK:STDOUT:   %.loc12_30.2.pack.elem.load = load i64, ptr %.loc12_30.2.pack.elem, align 8, !dbg !90
// CHECK:STDOUT:   %Add.call = add i64 %.loc12_22.2.pack.elem.load, %.loc12_30.2.pack.elem.load, !dbg !91
// CHECK:STDOUT:   %pack.elem = getelementptr inbounds [2 x i64], ptr %.loc12_14.pack, i32 0, i32 0
// CHECK:STDOUT:   store i64 %Add.call, ptr %pack.elem, align 8
// CHECK:STDOUT:   %.loc12_22.2.pack.elem1 = getelementptr inbounds [2 x i64], ptr %m, i32 0, i32 1, !dbg !89
// CHECK:STDOUT:   %.loc12_22.2.pack.elem.load2 = load i64, ptr %.loc12_22.2.pack.elem1, align 8, !dbg !89
// CHECK:STDOUT:   %.loc12_30.2.pack.elem3 = getelementptr inbounds [2 x i64], ptr %m, i32 0, i32 1, !dbg !90
// CHECK:STDOUT:   %.loc12_30.2.pack.elem.load4 = load i64, ptr %.loc12_30.2.pack.elem3, align 8, !dbg !90
// CHECK:STDOUT:   %Add.call5 = add i64 %.loc12_22.2.pack.elem.load2, %.loc12_30.2.pack.elem.load4, !dbg !91
// CHECK:STDOUT:   %pack.elem6 = getelementptr inbounds [2 x i64], ptr %.loc12_14.pack, i32 0, i32 1
// CHECK:STDOUT:   store i64 %Add.call5, ptr %pack.elem6, align 8
// CHECK:STDOUT:   %Sum.call = call i64 @_CSum.Main.91a8a89714fbc21c(ptr %.loc12_14.pack), !dbg !92
// CHECK:STDOUT:   ret i64 %Sum.call, !dbg !93
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CSum.Main.91a8a89714fbc21c(ptr %n) #0 !dbg !95 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.var = alloca i64, align 8, !dbg !100
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %total.var), !dbg !100
// CHECK:STDOUT:   store i64 0, ptr %total.var, align 8, !dbg !100
// CHECK:STDOUT:   %.loc7_26.2.pack.elem = getelementptr inbounds [2 x i64], ptr %n, i32 0, i32 0, !dbg !105
// CHECK:STDOUT:   %.loc7_26.2.pack.elem.load = load i64, ptr %.loc7_26.2.pack.elem, align 8, !dbg !105
// CHECK:STDOUT:   %.loc7_19 = load i64, ptr %total.var, align 8, !dbg !104
// CHECK:STDOUT:   %Add.call = add i64 %.loc7_19, %.loc7_26.2.pack.elem.load, !dbg !106
// CHECK:STDOUT:   store i64 %Add.call, ptr %total.var, align 8, !dbg !103
// CHECK:STDOUT:   %.loc7_26.2.pack.elem1 = getelementptr inbounds [2 x i64], ptr %n, i32 0, i32 1, !dbg !105
// CHECK:STDOUT:   %.loc7_26.2.pack.elem.load2 = load i64, ptr %.loc7_26.2.pack.elem1, align 8, !dbg !105
// CHECK:STDOUT:   %.loc7_193 = load i64, ptr %total.var, align 8, !dbg !104
// CHECK:STDOUT:   %Add.call4 = add i64 %.loc7_193, %.loc7_26.2.pack.elem.load2, !dbg !106
// CHECK:STDOUT:   store i64 %Add.call4, ptr %total.var, align 8, !dbg !103
// CHECK:STDOUT:   %.loc8 = load i64, ptr %total.var, align 8, !dbg !107
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %total.var), !dbg !100
// CHECK:STDOUT:   ret i64 %.loc8, !dbg !108
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 0, 3, 2, 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!33}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !32 = !DIFile(filename: "sum.carbon", directory: "")
// CHECK:STDOUT: !33 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !32, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !34 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !35 = !{null, !34}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !37 = !{!34}
// CHECK:STDOUT: !38 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !32, line: 6, type: !36, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !42)
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !39, type: !34)
// CHECK:STDOUT: !41 = !DILocation(line: 6, column: 3, scope: !39)
// CHECK:STDOUT: !42 = !{!40}
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !32, line: 15, type: !38, spFlags: DISPFlagDefinition, unit: !33)
// CHECK:STDOUT: !47 = !DILocation(line: 16, column: 18, scope: !43)
// CHECK:STDOUT: !48 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !49 = !{!34, !48}
// CHECK:STDOUT: !50 = !DISubroutineType(types: !49)
// CHECK:STDOUT: !51 = !DILocation(line: 16, column: 32, scope: !43)
// CHECK:STDOUT: !52 = !DILocation(line: 16, column: 14, scope: !43)
// CHECK:STDOUT: !54 = !DILocation(line: 16, column: 40, scope: !43)
// CHECK:STDOUT: !55 = !DILocation(line: 16, column: 10, scope: !43)
// CHECK:STDOUT: !56 = !DILocation(line: 16, column: 3, scope: !43)
// CHECK:STDOUT: !57 = distinct !DISubprogram(name: "Sum", linkageName: "_CSum.Main.935b24abbbc86de3", scope: null, file: !32, line: 5, type: !50, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !71)
// CHECK:STDOUT: !58 = !DILocalVariable(arg: 1, scope: !57, type: !48)
// CHECK:STDOUT: !62 = !DILocation(line: 6, column: 3, scope: !57)
// CHECK:STDOUT: !65 = !DILocation(line: 7, column: 7, scope: !57)
// CHECK:STDOUT: !66 = !DILocation(line: 7, column: 19, scope: !57)
// CHECK:STDOUT: !67 = !DILocation(line: 7, column: 26, scope: !57)
// CHECK:STDOUT: !68 = !DILocation(line: 7, column: 15, scope: !57)
// CHECK:STDOUT: !69 = !DILocation(line: 8, column: 10, scope: !57)
// CHECK:STDOUT: !70 = !DILocation(line: 8, column: 3, scope: !57)
// CHECK:STDOUT: !71 = !{!58}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "Sum", linkageName: "_CSum.Main.a950572c82f13f26", scope: null, file: !32, line: 5, type: !50, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !82)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !48)
// CHECK:STDOUT: !77 = !DILocation(line: 6, column: 3, scope: !72)
// CHECK:STDOUT: !80 = !DILocation(line: 8, column: 10, scope: !72)
// CHECK:STDOUT: !81 = !DILocation(line: 8, column: 3, scope: !72)
// CHECK:STDOUT: !82 = !{!73}
// CHECK:STDOUT: !83 = distinct !DISubprogram(name: "SumOfDoubles", linkageName: "_CSumOfDoubles.Main.91a8a89714fbc21c", scope: null, file: !32, line: 11, type: !50, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !94)
// CHECK:STDOUT: !84 = !DILocalVariable(arg: 1, scope: !83, type: !48)
// CHECK:STDOUT: !88 = !DILocation(line: 12, column: 14, scope: !83)
// CHECK:STDOUT: !89 = !DILocation(line: 12, column: 22, scope: !83)
// CHECK:STDOUT: !90 = !DILocation(line: 12, column: 30, scope: !83)
// CHECK:STDOUT: !91 = !DILocation(line: 12, column: 18, scope: !83)
// CHECK:STDOUT: !92 = !DILocation(line: 12, column: 10, scope: !83)
// CHECK:STDOUT: !93 = !DILocation(line: 12, column: 3, scope: !83)
// CHECK:STDOUT: !94 = !{!84}
// CHECK:STDOUT: !95 = distinct !DISubprogram(name: "Sum", linkageName: "_CSum.Main.91a8a89714fbc21c", scope: null, file: !32, line: 5, type: !50, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !109)
// CHECK:STDOUT: !96 = !DILocalVariable(arg: 1, scope: !95, type: !48)
// CHECK:STDOUT: !100 = !DILocation(line: 6, column: 3, scope: !95)
// CHECK:STDOUT: !103 = !DILocation(line: 7, column: 7, scope: !95)
// CHECK:STDOUT: !104 = !DILocation(line: 7, column: 19, scope: !95)
// CHECK:STDOUT: !105 = !DILocation(line: 7, column: 26, scope: !95)
// CHECK:STDOUT: !106 = !DILocation(line: 7, column: 15, scope: !95)
// CHECK:STDOUT: !107 = !DILocation(line: 8, column: 10, scope: !95)
// CHECK:STDOUT: !108 = !DILocation(line: 8, column: 3, scope: !95)
// CHECK:STDOUT: !109 = !{!96}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'generic_element.carbon'
// CHECK:STDOUT: source_filename = "generic_element.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @.7dd.loc10_11.3 = internal constant [2 x i1] [i1 true, i1 false]
// CHECK:STDOUT: @.3b6.loc11_13.5 = internal constant [1 x i32] [i32 1]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #0 !dbg !115 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CForEach.Main.97c5540954fa3159(ptr @.7dd.loc10_11.3), !dbg !117
// CHECK:STDOUT:   call void @_CForEach.Main.4f4322a22d1a1454(ptr @.3b6.loc11_13.5), !dbg !121
// CHECK:STDOUT:   ret i32 0, !dbg !122
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CForEach.Main.97c5540954fa3159(ptr %x) #0 !dbg !123 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_15.2.pack.elem = getelementptr inbounds [2 x i1], ptr %x, i32 0, i32 0, !dbg !127
// CHECK:STDOUT:   %.loc6_15.2.pack.elem.load = load i8, ptr %.loc6_15.2.pack.elem, align 1, !dbg !127
// CHECK:STDOUT:   %.loc6_15.2 = trunc i8 %.loc6_15.2.pack.elem.load to i1, !dbg !127
// CHECK:STDOUT:   call void @_CConsume.Main.a4c7fafe8a72cac4(i1 %.loc6_15.2), !dbg !128
// CHECK:STDOUT:   %.loc6_15.2.pack.elem1 = getelementptr inbounds [2 x i1], ptr %x, i32 0, i32 1, !dbg !127
// CHECK:STDOUT:   %.loc6_15.2.pack.elem.load2 = load i8, ptr %.loc6_15.2.pack.elem1, align 1, !dbg !127
// CHECK:STDOUT:   %.loc6_15.23 = trunc i8 %.loc6_15.2.pack.elem.load2 to i1, !dbg !127
// CHECK:STDOUT:   call void @_CConsume.Main.a4c7fafe8a72cac4(i1 %.loc6_15.23), !dbg !128
// CHECK:STDOUT:   ret void, !dbg !129
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CForEach.Main.4f4322a22d1a1454(ptr %x) #0 !dbg !131 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_15.2.pack.elem = getelementptr inbounds [1 x i32], ptr %x, i32 0, i32 0, !dbg !135
// CHECK:STDOUT:   %.loc6_15.2.pack.elem.load = load i32, ptr %.loc6_15.2.pack.elem, align 4, !dbg !135
// CHECK:STDOUT:   call void @_CConsume.Main.84588f41d61dafba(i32 %.loc6_15.2.pack.elem.load), !dbg !136
// CHECK:STDOUT:   ret void, !dbg !139
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CConsume.Main.a4c7fafe8a72cac4(i1 %x) #0 !dbg !141 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !144
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CConsume.Main.84588f41d61dafba(i32 %x) #0 !dbg !146 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !149
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CConsume.Main.a4c7fafe8a72cac4, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!111}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !48 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !110 = !DIFile(filename: "generic_element.carbon", directory: "")
// CHECK:STDOUT: !111 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !110, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !112 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !113 = !{!112}
// CHECK:STDOUT: !114 = !DISubroutineType(types: !113)
// CHECK:STDOUT: !115 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !110, line: 9, type: !114, spFlags: DISPFlagDefinition, unit: !111)
// CHECK:STDOUT: !117 = !DILocation(line: 10, column: 3, scope: !115)
// CHECK:STDOUT: !118 = !{null, !48}
// CHECK:STDOUT: !119 = !DISubroutineType(types: !118)
// CHECK:STDOUT: !121 = !DILocation(line: 11, column: 3, scope: !115)
// CHECK:STDOUT: !122 = !DILocation(line: 9, column: 1, scope: !115)
// CHECK:STDOUT: !123 = distinct !DISubprogram(name: "ForEach", linkageName: "_CForEach.Main.97c5540954fa3159", scope: null, file: !110, line: 5, type: !119, spFlags: DISPFlagDefinition, unit: !111, retainedNodes: !130)
// CHECK:STDOUT: !124 = !DILocalVariable(arg: 1, scope: !123, type: !48)
// CHECK:STDOUT: !127 = !DILocation(line: 6, column: 15, scope: !123)
// CHECK:STDOUT: !128 = !DILocation(line: 6, column: 7, scope: !123)
// CHECK:STDOUT: !129 = !DILocation(line: 5, column: 1, scope: !123)
// CHECK:STDOUT: !130 = !{!124}
// CHECK:STDOUT: !131 = distinct !DISubprogram(name: "ForEach", linkageName: "_CForEach.Main.4f4322a22d1a1454", scope: null, file: !110, line: 5, type: !119, spFlags: DISPFlagDefinition, unit: !111, retainedNodes: !140)
// CHECK:STDOUT: !132 = !DILocalVariable(arg: 1, scope: !131, type: !48)
// CHECK:STDOUT: !135 = !DILocation(line: 6, column: 15, scope: !131)
// CHECK:STDOUT: !136 = !DILocation(line: 6, column: 7, scope: !131)
// CHECK:STDOUT: !137 = !{null, !112}
// CHECK:STDOUT: !138 = !DISubroutineType(types: !137)
// CHECK:STDOUT: !139 = !DILocation(line: 5, column: 1, scope: !131)
// CHECK:STDOUT: !140 = !{!132}
// CHECK:STDOUT: !141 = distinct !DISubprogram(name: "Consume", linkageName: "_CConsume.Main.a4c7fafe8a72cac4", scope: null, file: !110, line: 3, type: !119, spFlags: DISPFlagDefinition, unit: !111, retainedNodes: !145)
// CHECK:STDOUT: !142 = !DILocalVariable(arg: 1, scope: !141, type: !48)
// CHECK:STDOUT: !144 = !DILocation(line: 3, column: 1, scope: !141)
// CHECK:STDOUT: !145 = !{!142}
// CHECK:STDOUT: !146 = distinct !DISubprogram(name: "Consume", linkageName: "_CConsume.Main.84588f41d61dafba", scope: null, file: !110, line: 3, type: !138, spFlags: DISPFlagDefinition, unit: !111, retainedNodes: !150)
// CHECK:STDOUT: !147 = !DILocalVariable(arg: 1, scope: !146, type: !112)
// CHECK:STDOUT: !149 = !DILocation(line: 3, column: 1, scope: !146)
// CHECK:STDOUT: !150 = !{!147}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'class_element.carbon'
// CHECK:STDOUT: source_filename = "class_element.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CGet.Main(ptr %c) #0 !dbg !155 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_11.1.a = getelementptr inbounds nuw { i64 }, ptr %c, i32 0, i32 0, !dbg !160
// CHECK:STDOUT:   %.loc10_11.2 = load i64, ptr %.loc10_11.1.a, align 8, !dbg !160
// CHECK:STDOUT:   ret i64 %.loc10_11.2, !dbg !161
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !163 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !165
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CCall.Main(ptr %c, ptr %d) #0 !dbg !167 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc20_20.2.pack = alloca [2 x ptr], align 8, !dbg !174
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc20_20.2.pack), !dbg !174
// CHECK:STDOUT:   %.loc20_20.2.pack.elem = getelementptr inbounds [2 x ptr], ptr %.loc20_20.2.pack, i32 0, i32 0, !dbg !174
// CHECK:STDOUT:   store ptr %c, ptr %.loc20_20.2.pack.elem, align 8, !dbg !174
// CHECK:STDOUT:   %.loc20_20.2.pack.elem1 = getelementptr inbounds [2 x ptr], ptr %.loc20_20.2.pack, i32 0, i32 1, !dbg !174
// CHECK:STDOUT:   store ptr %d, ptr %.loc20_20.2.pack.elem1, align 8, !dbg !174
// CHECK:STDOUT:   %SumFields.call = call i64 @_CSumFields.Main.91a8a89714fbc21c(ptr %.loc20_20.2.pack), !dbg !176
// CHECK:STDOUT:   ret i64 %SumFields.call, !dbg !177
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CSumFields.Main.91a8a89714fbc21c(ptr %c) #0 !dbg !179 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.var = alloca i64, align 8, !dbg !184
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %total.var), !dbg !184
// CHECK:STDOUT:   store i64 0, ptr %total.var, align 8, !dbg !184
// CHECK:STDOUT:   %.loc15_30.2.pack.elem = getelementptr inbounds [2 x ptr], ptr %c, i32 0, i32 0, !dbg !189
// CHECK:STDOUT:   %.loc15_30.2.pack.elem.load = load ptr, ptr %.loc15_30.2.pack.elem, align 8, !dbg !189
// CHECK:STDOUT:   %Get.call = call i64 @_CGet.Main(ptr %.loc15_30.2.pack.elem.load), !dbg !190
// CHECK:STDOUT:   %.loc15_19 = load i64, ptr %total.var, align 8, !dbg !188
// CHECK:STDOUT:   %Add.call = add i64 %.loc15_19, %Get.call, !dbg !191
// CHECK:STDOUT:   store i64 %Add.call, ptr %total.var, align 8, !dbg !187
// CHECK:STDOUT:   %.loc15_30.2.pack.elem1 = getelementptr inbounds [2 x ptr], ptr %c, i32 0, i32 1, !dbg !189
// CHECK:STDOUT:   %.loc15_30.2.pack.elem.load2 = load ptr, ptr %.loc15_30.2.pack.elem1, align 8, !dbg !189
// CHECK:STDOUT:   %Get.call3 = call i64 @_CGet.Main(ptr %.loc15_30.2.pack.elem.load2), !dbg !190
// CHECK:STDOUT:   %.loc15_194 = load i64, ptr %total.var, align 8, !dbg !188
// CHECK:STDOUT:   %Add.call5 = add i64 %.loc15_194, %Get.call3, !dbg !191
// CHECK:STDOUT:   store i64 %Add.call5, ptr %total.var, align 8, !dbg !187
// CHECK:STDOUT:   %.loc16 = load i64, ptr %total.var, align 8, !dbg !192
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %total.var), !dbg !184
// CHECK:STDOUT:   ret i64 %.loc16, !dbg !193
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!152}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !34 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !35 = !{null, !34}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !48 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !49 = !{!34, !48}
// CHECK:STDOUT: !50 = !DISubroutineType(types: !49)
// CHECK:STDOUT: !151 = !DIFile(filename: "class_element.carbon", directory: "")
// CHECK:STDOUT: !152 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !151, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !153 = !{!34, !48, !48}
// CHECK:STDOUT: !154 = !DISubroutineType(types: !153)
// CHECK:STDOUT: !155 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Main", scope: null, file: !151, line: 9, type: !50, spFlags: DISPFlagDefinition, unit: !152, retainedNodes: !162)
// CHECK:STDOUT: !156 = !DILocalVariable(arg: 1, scope: !155, type: !48)
// CHECK:STDOUT: !160 = !DILocation(line: 10, column: 10, scope: !155)
// CHECK:STDOUT: !161 = !DILocation(line: 10, column: 3, scope: !155)
// CHECK:STDOUT: !162 = !{!156}
// CHECK:STDOUT: !163 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !151, line: 14, type: !36, spFlags: DISPFlagDefinition, unit: !152, retainedNodes: !166)
// CHECK:STDOUT: !164 = !DILocalVariable(arg: 1, scope: !163, type: !34)
// CHECK:STDOUT: !165 = !DILocation(line: 14, column: 3, scope: !163)
// CHECK:STDOUT: !166 = !{!164}
// CHECK:STDOUT: !167 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !151, line: 19, type: !154, spFlags: DISPFlagDefinition, unit: !152, retainedNodes: !178)
// CHECK:STDOUT: !168 = !DILocalVariable(arg: 1, scope: !167, type: !48)
// CHECK:STDOUT: !169 = !DILocalVariable(arg: 2, scope: !167, type: !48)
// CHECK:STDOUT: !174 = !DILocation(line: 20, column: 20, scope: !167)
// CHECK:STDOUT: !176 = !DILocation(line: 20, column: 10, scope: !167)
// CHECK:STDOUT: !177 = !DILocation(line: 20, column: 3, scope: !167)
// CHECK:STDOUT: !178 = !{!168, !169}
// CHECK:STDOUT: !179 = distinct !DISubprogram(name: "SumFields", linkageName: "_CSumFields.Main.91a8a89714fbc21c", scope: null, file: !151, line: 13, type: !50, spFlags: DISPFlagDefinition, unit: !152, retainedNodes: !194)
// CHECK:STDOUT: !180 = !DILocalVariable(arg: 1, scope: !179, type: !48)
// CHECK:STDOUT: !184 = !DILocation(line: 14, column: 3, scope: !179)
// CHECK:STDOUT: !187 = !DILocation(line: 15, column: 7, scope: !179)
// CHECK:STDOUT: !188 = !DILocation(line: 15, column: 19, scope: !179)
// CHECK:STDOUT: !189 = !DILocation(line: 15, column: 30, scope: !179)
// CHECK:STDOUT: !190 = !DILocation(line: 15, column: 26, scope: !179)
// CHECK:STDOUT: !191 = !DILocation(line: 15, column: 15, scope: !179)
// CHECK:STDOUT: !192 = !DILocation(line: 16, column: 10, scope: !179)
// CHECK:STDOUT: !193 = !DILocation(line: 16, column: 3, scope: !179)
// CHECK:STDOUT: !194 = !{!180}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'arg_order.carbon'
// CHECK:STDOUT: source_filename = "arg_order.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @.a00.loc14_16.5 = internal constant [2 x i64] [i64 2, i64 3]
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @_CP.Main(i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CCall.Main() #0 !dbg !199 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Plain.call = call i64 @_CPlain.Main.91a8a89714fbc21c(ptr @.a00.loc14_16.5), !dbg !203
// CHECK:STDOUT:   ret i64 %Plain.call, !dbg !204
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CPlain.Main.91a8a89714fbc21c(ptr %x) #0 !dbg !205 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_23.pack = alloca [2 x i64], align 8, !dbg !211
// CHECK:STDOUT:   %P.call.loc10_20 = call i64 @_CP.Main(i64 1), !dbg !210
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc10_23.pack), !dbg !211
// CHECK:STDOUT:   %.loc10_29.2.pack.elem = getelementptr inbounds [2 x i64], ptr %x, i32 0, i32 0, !dbg !212
// CHECK:STDOUT:   %.loc10_29.2.pack.elem.load = load i64, ptr %.loc10_29.2.pack.elem, align 8, !dbg !212
// CHECK:STDOUT:   %P.call.loc10_35 = call i64 @_CP.Main(i64 %.loc10_29.2.pack.elem.load), !dbg !213
// CHECK:STDOUT:   %pack.elem = getelementptr inbounds [2 x i64], ptr %.loc10_23.pack, i32 0, i32 0
// CHECK:STDOUT:   store i64 %P.call.loc10_35, ptr %pack.elem, align 8
// CHECK:STDOUT:   %.loc10_29.2.pack.elem1 = getelementptr inbounds [2 x i64], ptr %x, i32 0, i32 1, !dbg !212
// CHECK:STDOUT:   %.loc10_29.2.pack.elem.load2 = load i64, ptr %.loc10_29.2.pack.elem1, align 8, !dbg !212
// CHECK:STDOUT:   %P.call.loc10_353 = call i64 @_CP.Main(i64 %.loc10_29.2.pack.elem.load2), !dbg !213
// CHECK:STDOUT:   %pack.elem4 = getelementptr inbounds [2 x i64], ptr %.loc10_23.pack, i32 0, i32 1
// CHECK:STDOUT:   store i64 %P.call.loc10_353, ptr %pack.elem4, align 8
// CHECK:STDOUT:   %P.call.loc10_41 = call i64 @_CP.Main(i64 9), !dbg !214
// CHECK:STDOUT:   %Digits.call = call i64 @_CDigits.Main.91a8a89714fbc21c(i64 %P.call.loc10_20, ptr %.loc10_23.pack, i64 %P.call.loc10_41), !dbg !215
// CHECK:STDOUT:   ret i64 %Digits.call, !dbg !218
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CDigits.Main.91a8a89714fbc21c(i64 %first, ptr %mid, i64 %last) #0 !dbg !220 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i64 %first, !dbg !230
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!196}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !34 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !37 = !{!34}
// CHECK:STDOUT: !38 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !48 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !49 = !{!34, !48}
// CHECK:STDOUT: !50 = !DISubroutineType(types: !49)
// CHECK:STDOUT: !195 = !DIFile(filename: "arg_order.carbon", directory: "")
// CHECK:STDOUT: !196 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !195, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !199 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !195, line: 13, type: !38, spFlags: DISPFlagDefinition, unit: !196)
// CHECK:STDOUT: !203 = !DILocation(line: 14, column: 10, scope: !199)
// CHECK:STDOUT: !204 = !DILocation(line: 14, column: 3, scope: !199)
// CHECK:STDOUT: !205 = distinct !DISubprogram(name: "Plain", linkageName: "_CPlain.Main.91a8a89714fbc21c", scope: null, file: !195, line: 9, type: !50, spFlags: DISPFlagDefinition, unit: !196, retainedNodes: !219)
// CHECK:STDOUT: !206 = !DILocalVariable(arg: 1, scope: !205, type: !48)
// CHECK:STDOUT: !210 = !DILocation(line: 10, column: 17, scope: !205)
// CHECK:STDOUT: !211 = !DILocation(line: 10, column: 23, scope: !205)
// CHECK:STDOUT: !212 = !DILocation(line: 10, column: 29, scope: !205)
// CHECK:STDOUT: !213 = !DILocation(line: 10, column: 27, scope: !205)
// CHECK:STDOUT: !214 = !DILocation(line: 10, column: 38, scope: !205)
// CHECK:STDOUT: !215 = !DILocation(line: 10, column: 10, scope: !205)
// CHECK:STDOUT: !216 = !{!34, !34, !48, !34}
// CHECK:STDOUT: !217 = !DISubroutineType(types: !216)
// CHECK:STDOUT: !218 = !DILocation(line: 10, column: 3, scope: !205)
// CHECK:STDOUT: !219 = !{!206}
// CHECK:STDOUT: !220 = distinct !DISubprogram(name: "Digits", linkageName: "_CDigits.Main.91a8a89714fbc21c", scope: null, file: !195, line: 5, type: !217, spFlags: DISPFlagDefinition, unit: !196, retainedNodes: !231)
// CHECK:STDOUT: !221 = !DILocalVariable(arg: 1, scope: !220, type: !34)
// CHECK:STDOUT: !222 = !DILocalVariable(arg: 2, scope: !220, type: !48)
// CHECK:STDOUT: !223 = !DILocalVariable(arg: 3, scope: !220, type: !34)
// CHECK:STDOUT: !230 = !DILocation(line: 6, column: 3, scope: !220)
// CHECK:STDOUT: !231 = !{!221, !222, !223}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'forward_converted_field.carbon'
// CHECK:STDOUT: source_filename = "forward_converted_field.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @"_CConvert.Wrap.Main:ImplicitAs.f249b435619a5146.Core"(ptr %self) #0 !dbg !234 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8_40.1.n = getelementptr inbounds nuw { i64 }, ptr %self, i32 0, i32 0, !dbg !239
// CHECK:STDOUT:   %.loc8_40.2 = load i64, ptr %.loc8_40.1.n, align 8, !dbg !239
// CHECK:STDOUT:   ret i64 %.loc8_40.2, !dbg !240
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !242 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !244
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CCall.Main(ptr %h, ptr %k) #0 !dbg !246 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc28_18.2.pack = alloca [2 x ptr], align 8, !dbg !253
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc28_18.2.pack), !dbg !253
// CHECK:STDOUT:   %.loc28_18.2.pack.elem = getelementptr inbounds [2 x ptr], ptr %.loc28_18.2.pack, i32 0, i32 0, !dbg !253
// CHECK:STDOUT:   store ptr %h, ptr %.loc28_18.2.pack.elem, align 8, !dbg !253
// CHECK:STDOUT:   %.loc28_18.2.pack.elem1 = getelementptr inbounds [2 x ptr], ptr %.loc28_18.2.pack, i32 0, i32 1, !dbg !253
// CHECK:STDOUT:   store ptr %k, ptr %.loc28_18.2.pack.elem1, align 8, !dbg !253
// CHECK:STDOUT:   %SumHeld.call = call i64 @_CSumHeld.Main.91a8a89714fbc21c(ptr %.loc28_18.2.pack), !dbg !255
// CHECK:STDOUT:   ret i64 %SumHeld.call, !dbg !256
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CSumHeld.Main.91a8a89714fbc21c(ptr %h) #0 !dbg !258 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc24_14.1.pack = alloca [2 x ptr], align 8, !dbg !263
// CHECK:STDOUT:   %.loc24_14.2.pack = alloca [2 x i64], align 8, !dbg !263
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc24_14.1.pack), !dbg !263
// CHECK:STDOUT:   %.loc24_18.2.pack.elem = getelementptr inbounds [2 x ptr], ptr %h, i32 0, i32 0, !dbg !264
// CHECK:STDOUT:   %.loc24_18.2.pack.elem.load = load ptr, ptr %.loc24_18.2.pack.elem, align 8, !dbg !264
// CHECK:STDOUT:   %.loc24_24.1.w = getelementptr inbounds nuw { { i64 } }, ptr %.loc24_18.2.pack.elem.load, i32 0, i32 0, !dbg !264
// CHECK:STDOUT:   %pack.elem = getelementptr inbounds [2 x ptr], ptr %.loc24_14.1.pack, i32 0, i32 0
// CHECK:STDOUT:   store ptr %.loc24_24.1.w, ptr %pack.elem, align 8
// CHECK:STDOUT:   %.loc24_18.2.pack.elem1 = getelementptr inbounds [2 x ptr], ptr %h, i32 0, i32 1, !dbg !264
// CHECK:STDOUT:   %.loc24_18.2.pack.elem.load2 = load ptr, ptr %.loc24_18.2.pack.elem1, align 8, !dbg !264
// CHECK:STDOUT:   %.loc24_24.1.w3 = getelementptr inbounds nuw { { i64 } }, ptr %.loc24_18.2.pack.elem.load2, i32 0, i32 0, !dbg !264
// CHECK:STDOUT:   %pack.elem4 = getelementptr inbounds [2 x ptr], ptr %.loc24_14.1.pack, i32 0, i32 1
// CHECK:STDOUT:   store ptr %.loc24_24.1.w3, ptr %pack.elem4, align 8
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc24_14.2.pack), !dbg !263
// CHECK:STDOUT:   %.loc24_14.5.pack.elem = getelementptr inbounds [2 x ptr], ptr %.loc24_14.1.pack, i32 0, i32 0, !dbg !263
// CHECK:STDOUT:   %.loc24_14.5.pack.elem.load = load ptr, ptr %.loc24_14.5.pack.elem, align 8, !dbg !263
// CHECK:STDOUT:   %Wrap.as.ImplicitAs.impl.Convert.call = call i64 @"_CConvert.Wrap.Main:ImplicitAs.f249b435619a5146.Core"(ptr %.loc24_14.5.pack.elem.load), !dbg !263
// CHECK:STDOUT:   %pack.elem5 = getelementptr inbounds [2 x i64], ptr %.loc24_14.2.pack, i32 0, i32 0
// CHECK:STDOUT:   store i64 %Wrap.as.ImplicitAs.impl.Convert.call, ptr %pack.elem5, align 8
// CHECK:STDOUT:   %.loc24_14.5.pack.elem6 = getelementptr inbounds [2 x ptr], ptr %.loc24_14.1.pack, i32 0, i32 1, !dbg !263
// CHECK:STDOUT:   %.loc24_14.5.pack.elem.load7 = load ptr, ptr %.loc24_14.5.pack.elem6, align 8, !dbg !263
// CHECK:STDOUT:   %Wrap.as.ImplicitAs.impl.Convert.call8 = call i64 @"_CConvert.Wrap.Main:ImplicitAs.f249b435619a5146.Core"(ptr %.loc24_14.5.pack.elem.load7), !dbg !263
// CHECK:STDOUT:   %pack.elem9 = getelementptr inbounds [2 x i64], ptr %.loc24_14.2.pack, i32 0, i32 1
// CHECK:STDOUT:   store i64 %Wrap.as.ImplicitAs.impl.Convert.call8, ptr %pack.elem9, align 8
// CHECK:STDOUT:   %Sum.call = call i64 @_CSum.Main.91a8a89714fbc21c(ptr %.loc24_14.2.pack), !dbg !265
// CHECK:STDOUT:   ret i64 %Sum.call, !dbg !266
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CSum.Main.91a8a89714fbc21c(ptr %n) #0 !dbg !268 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %total.var = alloca i64, align 8, !dbg !273
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %total.var), !dbg !273
// CHECK:STDOUT:   store i64 0, ptr %total.var, align 8, !dbg !273
// CHECK:STDOUT:   %.loc19_26.2.pack.elem = getelementptr inbounds [2 x i64], ptr %n, i32 0, i32 0, !dbg !278
// CHECK:STDOUT:   %.loc19_26.2.pack.elem.load = load i64, ptr %.loc19_26.2.pack.elem, align 8, !dbg !278
// CHECK:STDOUT:   %.loc19_19 = load i64, ptr %total.var, align 8, !dbg !277
// CHECK:STDOUT:   %Add.call = add i64 %.loc19_19, %.loc19_26.2.pack.elem.load, !dbg !279
// CHECK:STDOUT:   store i64 %Add.call, ptr %total.var, align 8, !dbg !276
// CHECK:STDOUT:   %.loc19_26.2.pack.elem1 = getelementptr inbounds [2 x i64], ptr %n, i32 0, i32 1, !dbg !278
// CHECK:STDOUT:   %.loc19_26.2.pack.elem.load2 = load i64, ptr %.loc19_26.2.pack.elem1, align 8, !dbg !278
// CHECK:STDOUT:   %.loc19_193 = load i64, ptr %total.var, align 8, !dbg !277
// CHECK:STDOUT:   %Add.call4 = add i64 %.loc19_193, %.loc19_26.2.pack.elem.load2, !dbg !279
// CHECK:STDOUT:   store i64 %Add.call4, ptr %total.var, align 8, !dbg !276
// CHECK:STDOUT:   %.loc20 = load i64, ptr %total.var, align 8, !dbg !280
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %total.var), !dbg !273
// CHECK:STDOUT:   ret i64 %.loc20, !dbg !281
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!233}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !34 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !35 = !{null, !34}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !48 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !49 = !{!34, !48}
// CHECK:STDOUT: !50 = !DISubroutineType(types: !49)
// CHECK:STDOUT: !153 = !{!34, !48, !48}
// CHECK:STDOUT: !154 = !DISubroutineType(types: !153)
// CHECK:STDOUT: !232 = !DIFile(filename: "forward_converted_field.carbon", directory: "")
// CHECK:STDOUT: !233 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !232, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !234 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.Wrap.Main:ImplicitAs.f249b435619a5146.Core", scope: null, file: !232, line: 8, type: !50, spFlags: DISPFlagDefinition, unit: !233, retainedNodes: !241)
// CHECK:STDOUT: !235 = !DILocalVariable(arg: 1, scope: !234, type: !48)
// CHECK:STDOUT: !239 = !DILocation(line: 8, column: 36, scope: !234)
// CHECK:STDOUT: !240 = !DILocation(line: 8, column: 29, scope: !234)
// CHECK:STDOUT: !241 = !{!235}
// CHECK:STDOUT: !242 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !232, line: 18, type: !36, spFlags: DISPFlagDefinition, unit: !233, retainedNodes: !245)
// CHECK:STDOUT: !243 = !DILocalVariable(arg: 1, scope: !242, type: !34)
// CHECK:STDOUT: !244 = !DILocation(line: 18, column: 3, scope: !242)
// CHECK:STDOUT: !245 = !{!243}
// CHECK:STDOUT: !246 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !232, line: 27, type: !154, spFlags: DISPFlagDefinition, unit: !233, retainedNodes: !257)
// CHECK:STDOUT: !247 = !DILocalVariable(arg: 1, scope: !246, type: !48)
// CHECK:STDOUT: !248 = !DILocalVariable(arg: 2, scope: !246, type: !48)
// CHECK:STDOUT: !253 = !DILocation(line: 28, column: 18, scope: !246)
// CHECK:STDOUT: !255 = !DILocation(line: 28, column: 10, scope: !246)
// CHECK:STDOUT: !256 = !DILocation(line: 28, column: 3, scope: !246)
// CHECK:STDOUT: !257 = !{!247, !248}
// CHECK:STDOUT: !258 = distinct !DISubprogram(name: "SumHeld", linkageName: "_CSumHeld.Main.91a8a89714fbc21c", scope: null, file: !232, line: 23, type: !50, spFlags: DISPFlagDefinition, unit: !233, retainedNodes: !267)
// CHECK:STDOUT: !259 = !DILocalVariable(arg: 1, scope: !258, type: !48)
// CHECK:STDOUT: !263 = !DILocation(line: 24, column: 14, scope: !258)
// CHECK:STDOUT: !264 = !DILocation(line: 24, column: 18, scope: !258)
// CHECK:STDOUT: !265 = !DILocation(line: 24, column: 10, scope: !258)
// CHECK:STDOUT: !266 = !DILocation(line: 24, column: 3, scope: !258)
// CHECK:STDOUT: !267 = !{!259}
// CHECK:STDOUT: !268 = distinct !DISubprogram(name: "Sum", linkageName: "_CSum.Main.91a8a89714fbc21c", scope: null, file: !232, line: 17, type: !50, spFlags: DISPFlagDefinition, unit: !233, retainedNodes: !282)
// CHECK:STDOUT: !269 = !DILocalVariable(arg: 1, scope: !268, type: !48)
// CHECK:STDOUT: !273 = !DILocation(line: 18, column: 3, scope: !268)
// CHECK:STDOUT: !276 = !DILocation(line: 19, column: 7, scope: !268)
// CHECK:STDOUT: !277 = !DILocation(line: 19, column: 19, scope: !268)
// CHECK:STDOUT: !278 = !DILocation(line: 19, column: 26, scope: !268)
// CHECK:STDOUT: !279 = !DILocation(line: 19, column: 15, scope: !268)
// CHECK:STDOUT: !280 = !DILocation(line: 20, column: 10, scope: !268)
// CHECK:STDOUT: !281 = !DILocation(line: 20, column: 3, scope: !268)
// CHECK:STDOUT: !282 = !{!269}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'lib.carbon'
// CHECK:STDOUT: source_filename = "lib.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !285 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !287
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!284}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !34 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !35 = !{null, !34}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !283 = !DIFile(filename: "lib.carbon", directory: "")
// CHECK:STDOUT: !284 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !283, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !285 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !283, line: 6, type: !36, spFlags: DISPFlagDefinition, unit: !284, retainedNodes: !288)
// CHECK:STDOUT: !286 = !DILocalVariable(arg: 1, scope: !285, type: !34)
// CHECK:STDOUT: !287 = !DILocation(line: 6, column: 3, scope: !285)
// CHECK:STDOUT: !288 = !{!286}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'use.carbon'
// CHECK:STDOUT: source_filename = "use.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @.041.loc6_18.5 = internal constant [2 x i64] [i64 1, i64 2]
// CHECK:STDOUT: @.43e.loc6_29.5 = internal constant [3 x i64] [i64 3, i64 4, i64 5]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CCall.Main() #0 !dbg !291 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Sum.call.loc6_22 = call i64 @_CSum.Main.91a8a89714fbc21c(ptr @.041.loc6_18.5), !dbg !295
// CHECK:STDOUT:   %Sum.call.loc6_36 = call i64 @_CSum.Main.935b24abbbc86de3(ptr @.43e.loc6_29.5), !dbg !297
// CHECK:STDOUT:   %Add.call = add i64 %Sum.call.loc6_22, %Sum.call.loc6_36, !dbg !298
// CHECK:STDOUT:   ret i64 %Add.call, !dbg !299
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CSum.Main.91a8a89714fbc21c(ptr %n) #0 !dbg !300 {
// CHECK:STDOUT:   %1 = alloca i64, align 8, !dbg !305
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !305
// CHECK:STDOUT:   store i64 0, ptr %1, align 8, !dbg !305
// CHECK:STDOUT:   %pack.elem = getelementptr inbounds [2 x i64], ptr %n, i32 0, i32 0, !dbg !310
// CHECK:STDOUT:   %pack.elem.load = load i64, ptr %pack.elem, align 8, !dbg !310
// CHECK:STDOUT:   %2 = load i64, ptr %1, align 8, !dbg !309
// CHECK:STDOUT:   %3 = add i64 %2, %pack.elem.load, !dbg !311
// CHECK:STDOUT:   store i64 %3, ptr %1, align 8, !dbg !308
// CHECK:STDOUT:   %pack.elem1 = getelementptr inbounds [2 x i64], ptr %n, i32 0, i32 1, !dbg !310
// CHECK:STDOUT:   %pack.elem.load2 = load i64, ptr %pack.elem1, align 8, !dbg !310
// CHECK:STDOUT:   %4 = load i64, ptr %1, align 8, !dbg !309
// CHECK:STDOUT:   %5 = add i64 %4, %pack.elem.load2, !dbg !311
// CHECK:STDOUT:   store i64 %5, ptr %1, align 8, !dbg !308
// CHECK:STDOUT:   %6 = load i64, ptr %1, align 8, !dbg !312
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %1), !dbg !305
// CHECK:STDOUT:   ret i64 %6, !dbg !313
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CSum.Main.935b24abbbc86de3(ptr %n) #0 !dbg !315 {
// CHECK:STDOUT:   %1 = alloca i64, align 8, !dbg !320
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !320
// CHECK:STDOUT:   store i64 0, ptr %1, align 8, !dbg !320
// CHECK:STDOUT:   %pack.elem = getelementptr inbounds [3 x i64], ptr %n, i32 0, i32 0, !dbg !325
// CHECK:STDOUT:   %pack.elem.load = load i64, ptr %pack.elem, align 8, !dbg !325
// CHECK:STDOUT:   %2 = load i64, ptr %1, align 8, !dbg !324
// CHECK:STDOUT:   %3 = add i64 %2, %pack.elem.load, !dbg !326
// CHECK:STDOUT:   store i64 %3, ptr %1, align 8, !dbg !323
// CHECK:STDOUT:   %pack.elem1 = getelementptr inbounds [3 x i64], ptr %n, i32 0, i32 1, !dbg !325
// CHECK:STDOUT:   %pack.elem.load2 = load i64, ptr %pack.elem1, align 8, !dbg !325
// CHECK:STDOUT:   %4 = load i64, ptr %1, align 8, !dbg !324
// CHECK:STDOUT:   %5 = add i64 %4, %pack.elem.load2, !dbg !326
// CHECK:STDOUT:   store i64 %5, ptr %1, align 8, !dbg !323
// CHECK:STDOUT:   %pack.elem3 = getelementptr inbounds [3 x i64], ptr %n, i32 0, i32 2, !dbg !325
// CHECK:STDOUT:   %pack.elem.load4 = load i64, ptr %pack.elem3, align 8, !dbg !325
// CHECK:STDOUT:   %6 = load i64, ptr %1, align 8, !dbg !324
// CHECK:STDOUT:   %7 = add i64 %6, %pack.elem.load4, !dbg !326
// CHECK:STDOUT:   store i64 %7, ptr %1, align 8, !dbg !323
// CHECK:STDOUT:   %8 = load i64, ptr %1, align 8, !dbg !327
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %1), !dbg !320
// CHECK:STDOUT:   ret i64 %8, !dbg !328
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!290}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !34 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !37 = !{!34}
// CHECK:STDOUT: !38 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !48 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !49 = !{!34, !48}
// CHECK:STDOUT: !50 = !DISubroutineType(types: !49)
// CHECK:STDOUT: !283 = !DIFile(filename: "lib.carbon", directory: "")
// CHECK:STDOUT: !289 = !DIFile(filename: "use.carbon", directory: "")
// CHECK:STDOUT: !290 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !289, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !291 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !289, line: 5, type: !38, spFlags: DISPFlagDefinition, unit: !290)
// CHECK:STDOUT: !295 = !DILocation(line: 6, column: 14, scope: !291)
// CHECK:STDOUT: !297 = !DILocation(line: 6, column: 25, scope: !291)
// CHECK:STDOUT: !298 = !DILocation(line: 6, column: 10, scope: !291)
// CHECK:STDOUT: !299 = !DILocation(line: 6, column: 3, scope: !291)
// CHECK:STDOUT: !300 = distinct !DISubprogram(name: "Sum", linkageName: "_CSum.Main.91a8a89714fbc21c", scope: null, file: !283, line: 5, type: !50, spFlags: DISPFlagDefinition, unit: !290, retainedNodes: !314)
// CHECK:STDOUT: !301 = !DILocalVariable(arg: 1, scope: !300, type: !48)
// CHECK:STDOUT: !305 = !DILocation(line: 6, column: 3, scope: !300)
// CHECK:STDOUT: !308 = !DILocation(line: 7, column: 7, scope: !300)
// CHECK:STDOUT: !309 = !DILocation(line: 7, column: 19, scope: !300)
// CHECK:STDOUT: !310 = !DILocation(line: 7, column: 26, scope: !300)
// CHECK:STDOUT: !311 = !DILocation(line: 7, column: 15, scope: !300)
// CHECK:STDOUT: !312 = !DILocation(line: 8, column: 10, scope: !300)
// CHECK:STDOUT: !313 = !DILocation(line: 8, column: 3, scope: !300)
// CHECK:STDOUT: !314 = !{!301}
// CHECK:STDOUT: !315 = distinct !DISubprogram(name: "Sum", linkageName: "_CSum.Main.935b24abbbc86de3", scope: null, file: !283, line: 5, type: !50, spFlags: DISPFlagDefinition, unit: !290, retainedNodes: !329)
// CHECK:STDOUT: !316 = !DILocalVariable(arg: 1, scope: !315, type: !48)
// CHECK:STDOUT: !320 = !DILocation(line: 6, column: 3, scope: !315)
// CHECK:STDOUT: !323 = !DILocation(line: 7, column: 7, scope: !315)
// CHECK:STDOUT: !324 = !DILocation(line: 7, column: 19, scope: !315)
// CHECK:STDOUT: !325 = !DILocation(line: 7, column: 26, scope: !315)
// CHECK:STDOUT: !326 = !DILocation(line: 7, column: 15, scope: !315)
// CHECK:STDOUT: !327 = !DILocation(line: 8, column: 10, scope: !315)
// CHECK:STDOUT: !328 = !DILocation(line: 8, column: 3, scope: !315)
// CHECK:STDOUT: !329 = !{!316}
// CHECK:STDOUT:

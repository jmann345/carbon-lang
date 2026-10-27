// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/expansion_if.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/expansion_if.carbon

// --- first.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn First(... each b: bool) -> i64 {
  ... if (each b) {
    return 1;
  } else {
    Consume(0);
  }
  return 0;
}

fn Call() -> i64 {
  return First(false, true, false);
}

// --- min.carbon
library "[[@TEST_NAME]]";

fn Less(a: i64, b: i64) -> bool = "int.less";

fn Min(first: i64, ... each next: i64) -> i64 {
  var result: i64 = first;
  ... if (Less(each next, result)) {
    result = each next;
  }
  return result;
}

fn Call() -> i64 {
  return Min(3, 1, 2);
}

// --- padded_element.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn Each(... each x: {.a: i64, .b: bool}) {
  ... if (each x.b) {
    Consume(each x.a);
  }
}

fn Call(y: {.a: i64, .b: bool}) {
  Each(y, y);
}

fn CallConstants() {
  Each({.a = 1, .b = true}, {.a = 2, .b = false});
}

// --- aggregate_constants.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn Less(a: i64, b: i64) -> bool = "int.less";

interface Get {
  fn Value(self: Self) -> i64;
}

impl (i64, i64) as Get {
  fn Value(self: Self) -> i64 { return self.1; }
}

impl {.a: i64, .b: bool} as Get {
  fn Value(self: Self) -> i64 { return self.a; }
}

fn Each[... each T: Get](... each x: each T) {
  ... if (Less(0, each x.Value())) {
    Consume(each x.Value());
  }
}

fn Call() {
  Each((1 as i64, 2 as i64), {.a = 3 as i64, .b = true});
}

// --- and_condition.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn Small(x: i64) -> bool;

fn Odd(x: i64) -> bool;

fn Each(... each x: i64) {
  ... if (Small(each x) and Odd(each x)) {
    Consume(each x);
  }
}

fn Call() {
  Each(1, 2);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'first.carbon'
// CHECK:STDOUT: source_filename = "first.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @.3e0.loc15_16.3 = internal constant [3 x i1] [i1 false, i1 true, i1 false]
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CConsume.Main(i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CCall.Main() #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %First.call = call i64 @_CFirst.Main.935b24abbbc86de3(ptr @.3e0.loc15_16.3), !dbg !43
// CHECK:STDOUT:   ret i64 %First.call, !dbg !47
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CFirst.Main.935b24abbbc86de3(ptr %b) #0 !dbg !48 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_11.2.pack.elem = getelementptr inbounds [3 x i1], ptr %b, i32 0, i32 0, !dbg !54
// CHECK:STDOUT:   %.loc6_11.2.pack.elem.load = load i8, ptr %.loc6_11.2.pack.elem, align 1, !dbg !54
// CHECK:STDOUT:   %.loc6_11.2 = trunc i8 %.loc6_11.2.pack.elem.load to i1, !dbg !54
// CHECK:STDOUT:   br i1 %.loc6_11.2, label %if.then, label %if.else, !dbg !55
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   ret i64 1, !dbg !56
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CConsume.Main(i64 0), !dbg !57
// CHECK:STDOUT:   br label %if.done, !dbg !58
// CHECK:STDOUT:
// CHECK:STDOUT: if.done:                                          ; preds = %if.else
// CHECK:STDOUT:   br label %pack.next, !dbg !53
// CHECK:STDOUT:
// CHECK:STDOUT: pack.next:                                        ; preds = %if.done
// CHECK:STDOUT:   %.loc6_11.2.pack.elem2 = getelementptr inbounds [3 x i1], ptr %b, i32 0, i32 1, !dbg !54
// CHECK:STDOUT:   %.loc6_11.2.pack.elem.load3 = load i8, ptr %.loc6_11.2.pack.elem2, align 1, !dbg !54
// CHECK:STDOUT:   %.loc6_11.24 = trunc i8 %.loc6_11.2.pack.elem.load3 to i1, !dbg !54
// CHECK:STDOUT:   br i1 %.loc6_11.24, label %if.then5, label %if.else6, !dbg !55
// CHECK:STDOUT:
// CHECK:STDOUT: if.then5:                                         ; preds = %pack.next
// CHECK:STDOUT:   ret i64 1, !dbg !56
// CHECK:STDOUT:
// CHECK:STDOUT: if.else6:                                         ; preds = %pack.next
// CHECK:STDOUT:   call void @_CConsume.Main(i64 0), !dbg !57
// CHECK:STDOUT:   br label %if.done7, !dbg !58
// CHECK:STDOUT:
// CHECK:STDOUT: if.done7:                                         ; preds = %if.else6
// CHECK:STDOUT:   br label %pack.next1, !dbg !53
// CHECK:STDOUT:
// CHECK:STDOUT: pack.next1:                                       ; preds = %if.done7
// CHECK:STDOUT:   %.loc6_11.2.pack.elem9 = getelementptr inbounds [3 x i1], ptr %b, i32 0, i32 2, !dbg !54
// CHECK:STDOUT:   %.loc6_11.2.pack.elem.load10 = load i8, ptr %.loc6_11.2.pack.elem9, align 1, !dbg !54
// CHECK:STDOUT:   %.loc6_11.211 = trunc i8 %.loc6_11.2.pack.elem.load10 to i1, !dbg !54
// CHECK:STDOUT:   br i1 %.loc6_11.211, label %if.then12, label %if.else13, !dbg !55
// CHECK:STDOUT:
// CHECK:STDOUT: if.then12:                                        ; preds = %pack.next1
// CHECK:STDOUT:   ret i64 1, !dbg !56
// CHECK:STDOUT:
// CHECK:STDOUT: if.else13:                                        ; preds = %pack.next1
// CHECK:STDOUT:   call void @_CConsume.Main(i64 0), !dbg !57
// CHECK:STDOUT:   br label %if.done14, !dbg !58
// CHECK:STDOUT:
// CHECK:STDOUT: if.done14:                                        ; preds = %if.else13
// CHECK:STDOUT:   br label %pack.next8, !dbg !53
// CHECK:STDOUT:
// CHECK:STDOUT: pack.next8:                                       ; preds = %if.done14
// CHECK:STDOUT:   ret i64 0, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!33}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !32 = !DIFile(filename: "first.carbon", directory: "")
// CHECK:STDOUT: !33 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !32, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !34 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !37 = !{!34}
// CHECK:STDOUT: !38 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !32, line: 14, type: !38, spFlags: DISPFlagDefinition, unit: !33)
// CHECK:STDOUT: !43 = !DILocation(line: 15, column: 10, scope: !39)
// CHECK:STDOUT: !44 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !45 = !{!34, !44}
// CHECK:STDOUT: !46 = !DISubroutineType(types: !45)
// CHECK:STDOUT: !47 = !DILocation(line: 15, column: 3, scope: !39)
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "First", linkageName: "_CFirst.Main.935b24abbbc86de3", scope: null, file: !32, line: 5, type: !46, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !60)
// CHECK:STDOUT: !49 = !DILocalVariable(arg: 1, scope: !48, type: !44)
// CHECK:STDOUT: !53 = !DILocation(line: 6, column: 3, scope: !48)
// CHECK:STDOUT: !54 = !DILocation(line: 6, column: 11, scope: !48)
// CHECK:STDOUT: !55 = !DILocation(line: 6, column: 10, scope: !48)
// CHECK:STDOUT: !56 = !DILocation(line: 7, column: 5, scope: !48)
// CHECK:STDOUT: !57 = !DILocation(line: 9, column: 5, scope: !48)
// CHECK:STDOUT: !58 = !DILocation(line: 6, column: 7, scope: !48)
// CHECK:STDOUT: !59 = !DILocation(line: 11, column: 3, scope: !48)
// CHECK:STDOUT: !60 = !{!49}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'min.carbon'
// CHECK:STDOUT: source_filename = "min.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @.041.loc14_17.5 = internal constant [2 x i64] [i64 1, i64 2]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !63 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CCall.Main() #0 !dbg !67 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Min.call = call i64 @_CMin.Main.91a8a89714fbc21c(i64 3, ptr @.041.loc14_17.5), !dbg !71
// CHECK:STDOUT:   ret i64 %Min.call, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CMin.Main.91a8a89714fbc21c(i64 %first, ptr %next) #0 !dbg !75 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %result.var = alloca i64, align 8, !dbg !82
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %result.var), !dbg !82
// CHECK:STDOUT:   store i64 %first, ptr %result.var, align 8, !dbg !82
// CHECK:STDOUT:   %.loc7_16.2.pack.elem = getelementptr inbounds [2 x i64], ptr %next, i32 0, i32 0, !dbg !86
// CHECK:STDOUT:   %.loc7_16.2.pack.elem.load = load i64, ptr %.loc7_16.2.pack.elem, align 8, !dbg !86
// CHECK:STDOUT:   %.loc7_27 = load i64, ptr %result.var, align 8, !dbg !87
// CHECK:STDOUT:   %Less.call = icmp slt i64 %.loc7_16.2.pack.elem.load, %.loc7_27, !dbg !88
// CHECK:STDOUT:   br i1 %Less.call, label %if.then, label %if.else, !dbg !89
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %.loc8_14.2.pack.elem = getelementptr inbounds [2 x i64], ptr %next, i32 0, i32 0, !dbg !91
// CHECK:STDOUT:   %.loc8_14.2.pack.elem.load = load i64, ptr %.loc8_14.2.pack.elem, align 8, !dbg !91
// CHECK:STDOUT:   store i64 %.loc8_14.2.pack.elem.load, ptr %result.var, align 8, !dbg !90
// CHECK:STDOUT:   br label %if.else, !dbg !92
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %if.then, %entry
// CHECK:STDOUT:   br label %pack.next, !dbg !85
// CHECK:STDOUT:
// CHECK:STDOUT: pack.next:                                        ; preds = %if.else
// CHECK:STDOUT:   %.loc7_16.2.pack.elem2 = getelementptr inbounds [2 x i64], ptr %next, i32 0, i32 1, !dbg !86
// CHECK:STDOUT:   %.loc7_16.2.pack.elem.load3 = load i64, ptr %.loc7_16.2.pack.elem2, align 8, !dbg !86
// CHECK:STDOUT:   %.loc7_274 = load i64, ptr %result.var, align 8, !dbg !87
// CHECK:STDOUT:   %Less.call5 = icmp slt i64 %.loc7_16.2.pack.elem.load3, %.loc7_274, !dbg !88
// CHECK:STDOUT:   br i1 %Less.call5, label %if.then6, label %if.else7, !dbg !89
// CHECK:STDOUT:
// CHECK:STDOUT: if.then6:                                         ; preds = %pack.next
// CHECK:STDOUT:   %.loc8_14.2.pack.elem8 = getelementptr inbounds [2 x i64], ptr %next, i32 0, i32 1, !dbg !91
// CHECK:STDOUT:   %.loc8_14.2.pack.elem.load9 = load i64, ptr %.loc8_14.2.pack.elem8, align 8, !dbg !91
// CHECK:STDOUT:   store i64 %.loc8_14.2.pack.elem.load9, ptr %result.var, align 8, !dbg !90
// CHECK:STDOUT:   br label %if.else7, !dbg !92
// CHECK:STDOUT:
// CHECK:STDOUT: if.else7:                                         ; preds = %if.then6, %pack.next
// CHECK:STDOUT:   br label %pack.next1, !dbg !85
// CHECK:STDOUT:
// CHECK:STDOUT: pack.next1:                                       ; preds = %if.else7
// CHECK:STDOUT:   %.loc10 = load i64, ptr %result.var, align 8, !dbg !93
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %result.var), !dbg !82
// CHECK:STDOUT:   ret i64 %.loc10, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!62}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !34 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !35 = !{null, !34}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !37 = !{!34}
// CHECK:STDOUT: !38 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !44 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !61 = !DIFile(filename: "min.carbon", directory: "")
// CHECK:STDOUT: !62 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !61, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !63 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !61, line: 6, type: !36, spFlags: DISPFlagDefinition, unit: !62, retainedNodes: !66)
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !63, type: !34)
// CHECK:STDOUT: !65 = !DILocation(line: 6, column: 3, scope: !63)
// CHECK:STDOUT: !66 = !{!64}
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !61, line: 13, type: !38, spFlags: DISPFlagDefinition, unit: !62)
// CHECK:STDOUT: !71 = !DILocation(line: 14, column: 10, scope: !67)
// CHECK:STDOUT: !72 = !{!34, !34, !44}
// CHECK:STDOUT: !73 = !DISubroutineType(types: !72)
// CHECK:STDOUT: !74 = !DILocation(line: 14, column: 3, scope: !67)
// CHECK:STDOUT: !75 = distinct !DISubprogram(name: "Min", linkageName: "_CMin.Main.91a8a89714fbc21c", scope: null, file: !61, line: 5, type: !73, spFlags: DISPFlagDefinition, unit: !62, retainedNodes: !95)
// CHECK:STDOUT: !76 = !DILocalVariable(arg: 1, scope: !75, type: !34)
// CHECK:STDOUT: !77 = !DILocalVariable(arg: 2, scope: !75, type: !44)
// CHECK:STDOUT: !82 = !DILocation(line: 6, column: 3, scope: !75)
// CHECK:STDOUT: !85 = !DILocation(line: 7, column: 3, scope: !75)
// CHECK:STDOUT: !86 = !DILocation(line: 7, column: 16, scope: !75)
// CHECK:STDOUT: !87 = !DILocation(line: 7, column: 27, scope: !75)
// CHECK:STDOUT: !88 = !DILocation(line: 7, column: 11, scope: !75)
// CHECK:STDOUT: !89 = !DILocation(line: 7, column: 10, scope: !75)
// CHECK:STDOUT: !90 = !DILocation(line: 8, column: 5, scope: !75)
// CHECK:STDOUT: !91 = !DILocation(line: 8, column: 14, scope: !75)
// CHECK:STDOUT: !92 = !DILocation(line: 7, column: 7, scope: !75)
// CHECK:STDOUT: !93 = !DILocation(line: 10, column: 10, scope: !75)
// CHECK:STDOUT: !94 = !DILocation(line: 10, column: 3, scope: !75)
// CHECK:STDOUT: !95 = !{!76, !77}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'padded_element.carbon'
// CHECK:STDOUT: source_filename = "padded_element.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @struct.688.loc16_26.7 = internal constant <{ i64, i1 }> <{ i64 1, i1 true }>
// CHECK:STDOUT: @struct.2ca.loc16_26.7 = internal constant <{ i64, i1 }> <{ i64 2, i1 false }>
// CHECK:STDOUT: @.7b1.loc16_26.7 = internal constant [2 x ptr] [ptr @struct.688.loc16_26.7, ptr @struct.2ca.loc16_26.7]
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CConsume.Main(i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr %y) #0 !dbg !102 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12_8.2.pack = alloca [2 x ptr], align 8, !dbg !105
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc12_8.2.pack), !dbg !105
// CHECK:STDOUT:   %.loc12_8.2.pack.elem = getelementptr inbounds [2 x ptr], ptr %.loc12_8.2.pack, i32 0, i32 0, !dbg !105
// CHECK:STDOUT:   store ptr %y, ptr %.loc12_8.2.pack.elem, align 8, !dbg !105
// CHECK:STDOUT:   %.loc12_8.2.pack.elem1 = getelementptr inbounds [2 x ptr], ptr %.loc12_8.2.pack, i32 0, i32 1, !dbg !105
// CHECK:STDOUT:   store ptr %y, ptr %.loc12_8.2.pack.elem1, align 8, !dbg !105
// CHECK:STDOUT:   call void @_CEach.Main.91a8a89714fbc21c(ptr %.loc12_8.2.pack), !dbg !107
// CHECK:STDOUT:   ret void, !dbg !108
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCallConstants.Main() #0 !dbg !110 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CEach.Main.91a8a89714fbc21c(ptr @.7b1.loc16_26.7), !dbg !112
// CHECK:STDOUT:   ret void, !dbg !113
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CEach.Main.91a8a89714fbc21c(ptr %x) #0 !dbg !114 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_11.2.pack.elem = getelementptr inbounds [2 x ptr], ptr %x, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %.loc6_11.2.pack.elem.load = load ptr, ptr %.loc6_11.2.pack.elem, align 8, !dbg !118
// CHECK:STDOUT:   %.loc6_17.b = getelementptr inbounds nuw <{ i64, i1 }>, ptr %.loc6_11.2.pack.elem.load, i32 0, i32 1, !dbg !118
// CHECK:STDOUT:   %.loc6_17.b.load = load i8, ptr %.loc6_17.b, align 1, !dbg !118
// CHECK:STDOUT:   %.loc6_17 = trunc i8 %.loc6_17.b.load to i1, !dbg !118
// CHECK:STDOUT:   br i1 %.loc6_17, label %if.then, label %if.else, !dbg !119
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %.loc7_13.2.pack.elem = getelementptr inbounds [2 x ptr], ptr %x, i32 0, i32 0, !dbg !120
// CHECK:STDOUT:   %.loc7_13.2.pack.elem.load = load ptr, ptr %.loc7_13.2.pack.elem, align 8, !dbg !120
// CHECK:STDOUT:   %.loc7_19.a = getelementptr inbounds nuw <{ i64, i1 }>, ptr %.loc7_13.2.pack.elem.load, i32 0, i32 0, !dbg !120
// CHECK:STDOUT:   %.loc7_19.a.load = load i64, ptr %.loc7_19.a, align 8, !dbg !120
// CHECK:STDOUT:   call void @_CConsume.Main(i64 %.loc7_19.a.load), !dbg !121
// CHECK:STDOUT:   br label %if.else, !dbg !122
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %if.then, %entry
// CHECK:STDOUT:   br label %pack.next, !dbg !117
// CHECK:STDOUT:
// CHECK:STDOUT: pack.next:                                        ; preds = %if.else
// CHECK:STDOUT:   %.loc6_11.2.pack.elem2 = getelementptr inbounds [2 x ptr], ptr %x, i32 0, i32 1, !dbg !118
// CHECK:STDOUT:   %.loc6_11.2.pack.elem.load3 = load ptr, ptr %.loc6_11.2.pack.elem2, align 8, !dbg !118
// CHECK:STDOUT:   %.loc6_17.b4 = getelementptr inbounds nuw <{ i64, i1 }>, ptr %.loc6_11.2.pack.elem.load3, i32 0, i32 1, !dbg !118
// CHECK:STDOUT:   %.loc6_17.b.load5 = load i8, ptr %.loc6_17.b4, align 1, !dbg !118
// CHECK:STDOUT:   %.loc6_176 = trunc i8 %.loc6_17.b.load5 to i1, !dbg !118
// CHECK:STDOUT:   br i1 %.loc6_176, label %if.then7, label %if.else8, !dbg !119
// CHECK:STDOUT:
// CHECK:STDOUT: if.then7:                                         ; preds = %pack.next
// CHECK:STDOUT:   %.loc7_13.2.pack.elem9 = getelementptr inbounds [2 x ptr], ptr %x, i32 0, i32 1, !dbg !120
// CHECK:STDOUT:   %.loc7_13.2.pack.elem.load10 = load ptr, ptr %.loc7_13.2.pack.elem9, align 8, !dbg !120
// CHECK:STDOUT:   %.loc7_19.a11 = getelementptr inbounds nuw <{ i64, i1 }>, ptr %.loc7_13.2.pack.elem.load10, i32 0, i32 0, !dbg !120
// CHECK:STDOUT:   %.loc7_19.a.load12 = load i64, ptr %.loc7_19.a11, align 8, !dbg !120
// CHECK:STDOUT:   call void @_CConsume.Main(i64 %.loc7_19.a.load12), !dbg !121
// CHECK:STDOUT:   br label %if.else8, !dbg !122
// CHECK:STDOUT:
// CHECK:STDOUT: if.else8:                                         ; preds = %if.then7, %pack.next
// CHECK:STDOUT:   br label %pack.next1, !dbg !117
// CHECK:STDOUT:
// CHECK:STDOUT: pack.next1:                                       ; preds = %if.else8
// CHECK:STDOUT:   ret void, !dbg !123
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CEach.Main.91a8a89714fbc21c, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!97}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !44 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !96 = !DIFile(filename: "padded_element.carbon", directory: "")
// CHECK:STDOUT: !97 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !96, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !98 = !{null, !44}
// CHECK:STDOUT: !99 = !DISubroutineType(types: !98)
// CHECK:STDOUT: !100 = !{null}
// CHECK:STDOUT: !101 = !DISubroutineType(types: !100)
// CHECK:STDOUT: !102 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !96, line: 11, type: !99, spFlags: DISPFlagDefinition, unit: !97, retainedNodes: !109)
// CHECK:STDOUT: !103 = !DILocalVariable(arg: 1, scope: !102, type: !44)
// CHECK:STDOUT: !105 = !DILocation(line: 12, column: 8, scope: !102)
// CHECK:STDOUT: !107 = !DILocation(line: 12, column: 3, scope: !102)
// CHECK:STDOUT: !108 = !DILocation(line: 11, column: 1, scope: !102)
// CHECK:STDOUT: !109 = !{!103}
// CHECK:STDOUT: !110 = distinct !DISubprogram(name: "CallConstants", linkageName: "_CCallConstants.Main", scope: null, file: !96, line: 15, type: !101, spFlags: DISPFlagDefinition, unit: !97)
// CHECK:STDOUT: !112 = !DILocation(line: 16, column: 3, scope: !110)
// CHECK:STDOUT: !113 = !DILocation(line: 15, column: 1, scope: !110)
// CHECK:STDOUT: !114 = distinct !DISubprogram(name: "Each", linkageName: "_CEach.Main.91a8a89714fbc21c", scope: null, file: !96, line: 5, type: !99, spFlags: DISPFlagDefinition, unit: !97, retainedNodes: !124)
// CHECK:STDOUT: !115 = !DILocalVariable(arg: 1, scope: !114, type: !44)
// CHECK:STDOUT: !117 = !DILocation(line: 6, column: 3, scope: !114)
// CHECK:STDOUT: !118 = !DILocation(line: 6, column: 11, scope: !114)
// CHECK:STDOUT: !119 = !DILocation(line: 6, column: 10, scope: !114)
// CHECK:STDOUT: !120 = !DILocation(line: 7, column: 13, scope: !114)
// CHECK:STDOUT: !121 = !DILocation(line: 7, column: 5, scope: !114)
// CHECK:STDOUT: !122 = !DILocation(line: 6, column: 7, scope: !114)
// CHECK:STDOUT: !123 = !DILocation(line: 5, column: 1, scope: !114)
// CHECK:STDOUT: !124 = !{!115}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'aggregate_constants.carbon'
// CHECK:STDOUT: source_filename = "aggregate_constants.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @tuple.1f3.loc26_27.6 = internal constant { i64, i64 } { i64 1, i64 2 }
// CHECK:STDOUT: @struct.loc26_27.6 = internal constant <{ i64, i1 }> <{ i64 3, i1 true }>
// CHECK:STDOUT: @.4e1.loc26_27.6 = internal constant { ptr, ptr } { ptr @tuple.1f3.loc26_27.6, ptr @struct.loc26_27.6 }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CConsume.Main(i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @"_CValue.1ac55aaed189338e:Get.Main"(ptr %self) #0 !dbg !127 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %self, i32 0, i32 1, !dbg !132
// CHECK:STDOUT:   %tuple.elem1.tuple.elem.load = load i64, ptr %tuple.elem1.tuple.elem, align 8, !dbg !132
// CHECK:STDOUT:   ret i64 %tuple.elem1.tuple.elem.load, !dbg !133
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @"_CValue.5c09a3b12fbccbc4:Get.Main"(ptr %self) #0 !dbg !135 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_44.a = getelementptr inbounds nuw <{ i64, i1 }>, ptr %self, i32 0, i32 0, !dbg !140
// CHECK:STDOUT:   %.loc16_44.a.load = load i64, ptr %.loc16_44.a, align 8, !dbg !140
// CHECK:STDOUT:   ret i64 %.loc16_44.a.load, !dbg !141
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main() #0 !dbg !143 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CEach.Main.58c21fab8a469e92(ptr @.4e1.loc26_27.6), !dbg !145
// CHECK:STDOUT:   ret void, !dbg !146
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CEach.Main.58c21fab8a469e92(ptr %x) #0 !dbg !147 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc20_19.5.pack.elem = getelementptr inbounds { ptr, ptr }, ptr %x, i32 0, i32 0, !dbg !151
// CHECK:STDOUT:   %.loc20_19.5.pack.elem.load = load ptr, ptr %.loc20_19.5.pack.elem, align 8, !dbg !151
// CHECK:STDOUT:   %Get.WithSelf.Value.call.loc20 = call i64 @"_CValue.1ac55aaed189338e:Get.Main"(ptr %.loc20_19.5.pack.elem.load), !dbg !151
// CHECK:STDOUT:   %Less.call = icmp slt i64 0, %Get.WithSelf.Value.call.loc20, !dbg !152
// CHECK:STDOUT:   br i1 %Less.call, label %if.then, label %if.else, !dbg !153
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %.loc21_13.5.pack.elem = getelementptr inbounds { ptr, ptr }, ptr %x, i32 0, i32 0, !dbg !154
// CHECK:STDOUT:   %.loc21_13.5.pack.elem.load = load ptr, ptr %.loc21_13.5.pack.elem, align 8, !dbg !154
// CHECK:STDOUT:   %Get.WithSelf.Value.call.loc21 = call i64 @"_CValue.1ac55aaed189338e:Get.Main"(ptr %.loc21_13.5.pack.elem.load), !dbg !154
// CHECK:STDOUT:   call void @_CConsume.Main(i64 %Get.WithSelf.Value.call.loc21), !dbg !155
// CHECK:STDOUT:   br label %if.else, !dbg !156
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %if.then, %entry
// CHECK:STDOUT:   br label %pack.next, !dbg !150
// CHECK:STDOUT:
// CHECK:STDOUT: pack.next:                                        ; preds = %if.else
// CHECK:STDOUT:   %.loc20_19.5.pack.elem2 = getelementptr inbounds { ptr, ptr }, ptr %x, i32 0, i32 1, !dbg !151
// CHECK:STDOUT:   %.loc20_19.5.pack.elem.load3 = load ptr, ptr %.loc20_19.5.pack.elem2, align 8, !dbg !151
// CHECK:STDOUT:   %Get.WithSelf.Value.call.loc204 = call i64 @"_CValue.5c09a3b12fbccbc4:Get.Main"(ptr %.loc20_19.5.pack.elem.load3), !dbg !151
// CHECK:STDOUT:   %Less.call5 = icmp slt i64 0, %Get.WithSelf.Value.call.loc204, !dbg !152
// CHECK:STDOUT:   br i1 %Less.call5, label %if.then6, label %if.else7, !dbg !153
// CHECK:STDOUT:
// CHECK:STDOUT: if.then6:                                         ; preds = %pack.next
// CHECK:STDOUT:   %.loc21_13.5.pack.elem8 = getelementptr inbounds { ptr, ptr }, ptr %x, i32 0, i32 1, !dbg !154
// CHECK:STDOUT:   %.loc21_13.5.pack.elem.load9 = load ptr, ptr %.loc21_13.5.pack.elem8, align 8, !dbg !154
// CHECK:STDOUT:   %Get.WithSelf.Value.call.loc2110 = call i64 @"_CValue.5c09a3b12fbccbc4:Get.Main"(ptr %.loc21_13.5.pack.elem.load9), !dbg !154
// CHECK:STDOUT:   call void @_CConsume.Main(i64 %Get.WithSelf.Value.call.loc2110), !dbg !155
// CHECK:STDOUT:   br label %if.else7, !dbg !156
// CHECK:STDOUT:
// CHECK:STDOUT: if.else7:                                         ; preds = %if.then6, %pack.next
// CHECK:STDOUT:   br label %pack.next1, !dbg !150
// CHECK:STDOUT:
// CHECK:STDOUT: pack.next1:                                       ; preds = %if.else7
// CHECK:STDOUT:   ret void, !dbg !157
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!126}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !34 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !44 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !45 = !{!34, !44}
// CHECK:STDOUT: !46 = !DISubroutineType(types: !45)
// CHECK:STDOUT: !98 = !{null, !44}
// CHECK:STDOUT: !99 = !DISubroutineType(types: !98)
// CHECK:STDOUT: !100 = !{null}
// CHECK:STDOUT: !101 = !DISubroutineType(types: !100)
// CHECK:STDOUT: !125 = !DIFile(filename: "aggregate_constants.carbon", directory: "")
// CHECK:STDOUT: !126 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !125, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !127 = distinct !DISubprogram(name: "Value", linkageName: "_CValue.1ac55aaed189338e:Get.Main", scope: null, file: !125, line: 12, type: !46, spFlags: DISPFlagDefinition, unit: !126, retainedNodes: !134)
// CHECK:STDOUT: !128 = !DILocalVariable(arg: 1, scope: !127, type: !44)
// CHECK:STDOUT: !132 = !DILocation(line: 12, column: 40, scope: !127)
// CHECK:STDOUT: !133 = !DILocation(line: 12, column: 33, scope: !127)
// CHECK:STDOUT: !134 = !{!128}
// CHECK:STDOUT: !135 = distinct !DISubprogram(name: "Value", linkageName: "_CValue.5c09a3b12fbccbc4:Get.Main", scope: null, file: !125, line: 16, type: !46, spFlags: DISPFlagDefinition, unit: !126, retainedNodes: !142)
// CHECK:STDOUT: !136 = !DILocalVariable(arg: 1, scope: !135, type: !44)
// CHECK:STDOUT: !140 = !DILocation(line: 16, column: 40, scope: !135)
// CHECK:STDOUT: !141 = !DILocation(line: 16, column: 33, scope: !135)
// CHECK:STDOUT: !142 = !{!136}
// CHECK:STDOUT: !143 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !125, line: 25, type: !101, spFlags: DISPFlagDefinition, unit: !126)
// CHECK:STDOUT: !145 = !DILocation(line: 26, column: 3, scope: !143)
// CHECK:STDOUT: !146 = !DILocation(line: 25, column: 1, scope: !143)
// CHECK:STDOUT: !147 = distinct !DISubprogram(name: "Each", linkageName: "_CEach.Main.58c21fab8a469e92", scope: null, file: !125, line: 19, type: !99, spFlags: DISPFlagDefinition, unit: !126, retainedNodes: !158)
// CHECK:STDOUT: !148 = !DILocalVariable(arg: 1, scope: !147, type: !44)
// CHECK:STDOUT: !150 = !DILocation(line: 20, column: 3, scope: !147)
// CHECK:STDOUT: !151 = !DILocation(line: 20, column: 19, scope: !147)
// CHECK:STDOUT: !152 = !DILocation(line: 20, column: 11, scope: !147)
// CHECK:STDOUT: !153 = !DILocation(line: 20, column: 10, scope: !147)
// CHECK:STDOUT: !154 = !DILocation(line: 21, column: 13, scope: !147)
// CHECK:STDOUT: !155 = !DILocation(line: 21, column: 5, scope: !147)
// CHECK:STDOUT: !156 = !DILocation(line: 20, column: 7, scope: !147)
// CHECK:STDOUT: !157 = !DILocation(line: 19, column: 1, scope: !147)
// CHECK:STDOUT: !158 = !{!148}
// CHECK:STDOUT:

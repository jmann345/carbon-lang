// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/choice/payload_layout.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/choice/payload_layout.carbon

// The F-007k layout arbiter (fork/w5-choice/plan.md risk R-6): the payload
// region must lower as a single `[N x i8]` byte array whose size is the MAX
// over the payload tuples — 16 bytes here: (i64, i32) is 12 bytes rounded up
// to its 8-byte alignment; (i32) is 4 — with every payload tuple accessed at
// byte offset 0. Sequential (non-overlapping) layout would produce a visibly
// larger array and a nonzero offset for one of the constructors' stores. The
// `None` constant additionally pins the payload-covering constant of a
// payload-carrying choice: a struct constant whose payload element is poison
// (the `UninitializedValue` lowering).

choice Sized {
  Small(a: i32),
  Large(a: i64, b: i32),
  None
}

let global_none: Sized = Sized.None;

fn MakeSmall(n: i32) -> Sized {
  return Sized.Small(n);
}

fn MakeLarge(a: i64, b: i32) -> Sized {
  return Sized.Large(a, b);
}

fn Classify(s: Sized) -> i32 {
  match (s) {
    case .None => { return 0; }
    default => { return 1; }
  }
  return -1;
}

fn Use(n: i32) {
  // Scope exit of a local exercises the destroy path for the payload region.
  // CHECK:STDERR: payload_layout.carbon:[[@LINE+4]]:7: warning: binding `v` unused [UnusedBinding]
  // CHECK:STDERR:   var v: Sized = MakeSmall(n);
  // CHECK:STDERR:       ^~~~~~~~
  // CHECK:STDERR:
  var v: Sized = MakeSmall(n);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'payload_layout.carbon'
// CHECK:STDOUT: source_filename = "payload_layout.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Sized.val = internal constant <{ <{ i2, [7 x i8] }>, [16 x i8] }> <{ <{ i2, [7 x i8] }> <{ i2 -2, [7 x i8] zeroinitializer }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT: @_Cglobal_none.Main = global <{ <{ i2, [7 x i8] }>, [16 x i8] }> zeroinitializer
// CHECK:STDOUT: @Sized.val.loc27_1.13 = internal constant <{ <{ i2, [7 x i8] }>, [16 x i8] }> <{ <{ i2, [7 x i8] }> <{ i2 -2, [7 x i8] zeroinitializer }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CSmall.Sized.Main(ptr sret(<{ <{ i2, [7 x i8] }>, [16 x i8] }>) %return, i32 %_) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc23_14.1.discriminant = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc23_14.4.payload = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 1, !dbg !11
// CHECK:STDOUT:   %.loc23_14.5.Small = getelementptr inbounds nuw [16 x i8], ptr %.loc23_14.4.payload, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc24_16.2.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !12
// CHECK:STDOUT:   store { i32 } %.loc24_16.2.tuple.init, ptr %.loc23_14.5.Small, align 4, !dbg !11
// CHECK:STDOUT:   store i8 0, ptr %.loc23_14.1.discriminant, align 1, !dbg !11
// CHECK:STDOUT:   ret void, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CLarge.Sized.Main(ptr sret(<{ <{ i2, [7 x i8] }>, [16 x i8] }>) %return, i64 %_, i32 %_1) #0 !dbg !13 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc23_14.1.discriminant = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 0, !dbg !20
// CHECK:STDOUT:   %.loc23_14.4.payload = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 1, !dbg !20
// CHECK:STDOUT:   %.loc23_14.5.Large = getelementptr inbounds nuw [16 x i8], ptr %.loc23_14.4.payload, i32 0, i32 0, !dbg !20
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64, i32 }, ptr %.loc23_14.5.Large, i32 0, i32 0, !dbg !21
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem0.tuple.elem, align 8, !dbg !21
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i32 }, ptr %.loc23_14.5.Large, i32 0, i32 1, !dbg !21
// CHECK:STDOUT:   store i32 %_1, ptr %tuple.elem1.tuple.elem, align 4, !dbg !21
// CHECK:STDOUT:   store i8 1, ptr %.loc23_14.1.discriminant, align 1, !dbg !20
// CHECK:STDOUT:   ret void, !dbg !20
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeSmall.Main(ptr sret(<{ <{ i2, [7 x i8] }>, [16 x i8] }>) %return, i32 %n) #0 !dbg !22 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CSmall.Sized.Main(ptr %return, i32 %n), !dbg !25
// CHECK:STDOUT:   ret void, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeLarge.Main(ptr sret(<{ <{ i2, [7 x i8] }>, [16 x i8] }>) %return, i64 %a, i32 %b) #0 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CLarge.Sized.Main(ptr %return, i64 %a, i32 %b), !dbg !31
// CHECK:STDOUT:   ret void, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CClassify.Main(ptr %s) #0 !dbg !33 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc41_16.3.discriminant = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %s, i32 0, i32 0, !dbg !38
// CHECK:STDOUT:   %.loc41_16.4 = load i8, ptr %.loc41_16.3.discriminant, align 1, !dbg !38
// CHECK:STDOUT:   %.loc41_16.41 = trunc i8 %.loc41_16.4 to i2, !dbg !38
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i2 -2, %.loc41_16.41, !dbg !38
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !38
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !39
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(i32 %n) #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.var = alloca <{ <{ i2, [7 x i8] }>, [16 x i8] }>, align 8, !dbg !46
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %v.var), !dbg !46
// CHECK:STDOUT:   call void @_CMakeSmall.Main(ptr %v.var, i32 %n), !dbg !47
// CHECK:STDOUT:   call void @"_COp.ad336186638d614a:core.Destroy.Core"(ptr %v.var), !dbg !46
// CHECK:STDOUT:   ret void, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.6dd7aafc81a25e45:core.Destroy.Core"(ptr %self) #0 !dbg !49 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !56 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.216a6481b641f07b:core.Destroy.Core"(ptr %self) #0 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5f42013854821c52:core.Destroy.Core"(ptr %self) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !71
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.81e66f1a55f8c816:core.Destroy.Core"(ptr %self) #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !75
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.6ca8dd97b00581b7:core.Destroy.Core"(ptr %self) #0 !dbg !76 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !79
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.6f4097304c95e123:core.Destroy.Core"(ptr %self) #0 !dbg !80 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !83
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.ad336186638d614a:core.Destroy.Core"(ptr %self) #0 !dbg !84 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !87
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !88 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 @_Cglobal_none.Main, ptr align 8 @Sized.val.loc27_1.13, i64 24, i1 false)
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT: }
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
// CHECK:STDOUT: !1 = !DIFile(filename: "payload_layout.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Small", linkageName: "_CSmall.Sized.Main", scope: null, file: !1, line: 23, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 23, column: 1, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 24, column: 16, scope: !4)
// CHECK:STDOUT: !13 = distinct !DISubprogram(name: "Large", linkageName: "_CLarge.Sized.Main", scope: null, file: !1, line: 23, type: !14, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !17)
// CHECK:STDOUT: !14 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !15 = !{!7, !16, !8}
// CHECK:STDOUT: !16 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !17 = !{!18, !19}
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !13, type: !16)
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 2, scope: !13, type: !8)
// CHECK:STDOUT: !20 = !DILocation(line: 23, column: 1, scope: !13)
// CHECK:STDOUT: !21 = !DILocation(line: 25, column: 24, scope: !13)
// CHECK:STDOUT: !22 = distinct !DISubprogram(name: "MakeSmall", linkageName: "_CMakeSmall.Main", scope: null, file: !1, line: 31, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !23)
// CHECK:STDOUT: !23 = !{!24}
// CHECK:STDOUT: !24 = !DILocalVariable(arg: 1, scope: !22, type: !8)
// CHECK:STDOUT: !25 = !DILocation(line: 32, column: 10, scope: !22)
// CHECK:STDOUT: !26 = !DILocation(line: 32, column: 3, scope: !22)
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "MakeLarge", linkageName: "_CMakeLarge.Main", scope: null, file: !1, line: 35, type: !14, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !28)
// CHECK:STDOUT: !28 = !{!29, !30}
// CHECK:STDOUT: !29 = !DILocalVariable(arg: 1, scope: !27, type: !16)
// CHECK:STDOUT: !30 = !DILocalVariable(arg: 2, scope: !27, type: !8)
// CHECK:STDOUT: !31 = !DILocation(line: 36, column: 10, scope: !27)
// CHECK:STDOUT: !32 = !DILocation(line: 36, column: 3, scope: !27)
// CHECK:STDOUT: !33 = distinct !DISubprogram(name: "Classify", linkageName: "_CClassify.Main", scope: null, file: !1, line: 39, type: !34, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !36)
// CHECK:STDOUT: !34 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !35 = !{!8, !7}
// CHECK:STDOUT: !36 = !{!37}
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !33, type: !7)
// CHECK:STDOUT: !38 = !DILocation(line: 41, column: 5, scope: !33)
// CHECK:STDOUT: !39 = !DILocation(line: 41, column: 21, scope: !33)
// CHECK:STDOUT: !40 = !DILocation(line: 42, column: 18, scope: !33)
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 47, type: !42, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !44)
// CHECK:STDOUT: !42 = !DISubroutineType(types: !43)
// CHECK:STDOUT: !43 = !{null, !8}
// CHECK:STDOUT: !44 = !{!45}
// CHECK:STDOUT: !45 = !DILocalVariable(arg: 1, scope: !41, type: !8)
// CHECK:STDOUT: !46 = !DILocation(line: 53, column: 3, scope: !41)
// CHECK:STDOUT: !47 = !DILocation(line: 53, column: 18, scope: !41)
// CHECK:STDOUT: !48 = !DILocation(line: 47, column: 1, scope: !41)
// CHECK:STDOUT: !49 = distinct !DISubprogram(name: "Op", linkageName: "_COp.6dd7aafc81a25e45:core.Destroy.Core", scope: null, file: !1, line: 53, type: !50, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !53)
// CHECK:STDOUT: !50 = !DISubroutineType(types: !51)
// CHECK:STDOUT: !51 = !{null, !52}
// CHECK:STDOUT: !52 = !DIBasicType(name: "int", size: 2, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !53 = !{!54}
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !49, type: !52)
// CHECK:STDOUT: !55 = !DILocation(line: 53, column: 3, scope: !49)
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 53, type: !42, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !57)
// CHECK:STDOUT: !57 = !{!58}
// CHECK:STDOUT: !58 = !DILocalVariable(arg: 1, scope: !56, type: !8)
// CHECK:STDOUT: !59 = !DILocation(line: 53, column: 3, scope: !56)
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "Op", linkageName: "_COp.216a6481b641f07b:core.Destroy.Core", scope: null, file: !1, line: 53, type: !61, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !63)
// CHECK:STDOUT: !61 = !DISubroutineType(types: !62)
// CHECK:STDOUT: !62 = !{null, !7}
// CHECK:STDOUT: !63 = !{!64}
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !60, type: !7)
// CHECK:STDOUT: !65 = !DILocation(line: 53, column: 3, scope: !60)
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5f42013854821c52:core.Destroy.Core", scope: null, file: !1, line: 53, type: !67, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !69)
// CHECK:STDOUT: !67 = !DISubroutineType(types: !68)
// CHECK:STDOUT: !68 = !{null, !16}
// CHECK:STDOUT: !69 = !{!70}
// CHECK:STDOUT: !70 = !DILocalVariable(arg: 1, scope: !66, type: !16)
// CHECK:STDOUT: !71 = !DILocation(line: 53, column: 3, scope: !66)
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "Op", linkageName: "_COp.81e66f1a55f8c816:core.Destroy.Core", scope: null, file: !1, line: 53, type: !61, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !73)
// CHECK:STDOUT: !73 = !{!74}
// CHECK:STDOUT: !74 = !DILocalVariable(arg: 1, scope: !72, type: !7)
// CHECK:STDOUT: !75 = !DILocation(line: 53, column: 3, scope: !72)
// CHECK:STDOUT: !76 = distinct !DISubprogram(name: "Op", linkageName: "_COp.6ca8dd97b00581b7:core.Destroy.Core", scope: null, file: !1, line: 53, type: !61, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !77)
// CHECK:STDOUT: !77 = !{!78}
// CHECK:STDOUT: !78 = !DILocalVariable(arg: 1, scope: !76, type: !7)
// CHECK:STDOUT: !79 = !DILocation(line: 53, column: 3, scope: !76)
// CHECK:STDOUT: !80 = distinct !DISubprogram(name: "Op", linkageName: "_COp.6f4097304c95e123:core.Destroy.Core", scope: null, file: !1, line: 53, type: !61, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !81)
// CHECK:STDOUT: !81 = !{!82}
// CHECK:STDOUT: !82 = !DILocalVariable(arg: 1, scope: !80, type: !7)
// CHECK:STDOUT: !83 = !DILocation(line: 53, column: 3, scope: !80)
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "Op", linkageName: "_COp.ad336186638d614a:core.Destroy.Core", scope: null, file: !1, line: 53, type: !61, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !85)
// CHECK:STDOUT: !85 = !{!86}
// CHECK:STDOUT: !86 = !DILocalVariable(arg: 1, scope: !84, type: !7)
// CHECK:STDOUT: !87 = !DILocation(line: 53, column: 3, scope: !84)
// CHECK:STDOUT: !88 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !1, type: !89, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !89 = !DISubroutineType(types: !90)
// CHECK:STDOUT: !90 = !{null}
// CHECK:STDOUT: !91 = !DILocation(line: 0, scope: !88)
// CHECK:STDOUT:

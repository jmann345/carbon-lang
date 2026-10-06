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
// CHECK:STDOUT: define void @_CSmall.Sized.Main(ptr sret(<{ <{ i2, [7 x i8] }>, [16 x i8] }>) %return, i32 %_) #0 !dbg !24 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc23_14.1.discriminant = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 0, !dbg !26
// CHECK:STDOUT:   %.loc23_14.4.payload = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 1, !dbg !26
// CHECK:STDOUT:   %.loc23_14.5.Small = getelementptr inbounds nuw [16 x i8], ptr %.loc23_14.4.payload, i32 0, i32 0, !dbg !26
// CHECK:STDOUT:   %.loc24_16.2.tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !27
// CHECK:STDOUT:   store { i32 } %.loc24_16.2.tuple.init, ptr %.loc23_14.5.Small, align 4, !dbg !26
// CHECK:STDOUT:   store i8 0, ptr %.loc23_14.1.discriminant, align 1, !dbg !26
// CHECK:STDOUT:   ret void, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CLarge.Sized.Main(ptr sret(<{ <{ i2, [7 x i8] }>, [16 x i8] }>) %return, i64 %_, i32 %_1) #0 !dbg !29 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc23_14.1.discriminant = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 0, !dbg !32
// CHECK:STDOUT:   %.loc23_14.4.payload = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 1, !dbg !32
// CHECK:STDOUT:   %.loc23_14.5.Large = getelementptr inbounds nuw [16 x i8], ptr %.loc23_14.4.payload, i32 0, i32 0, !dbg !32
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64, i32 }, ptr %.loc23_14.5.Large, i32 0, i32 0, !dbg !33
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem0.tuple.elem, align 8, !dbg !33
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i32 }, ptr %.loc23_14.5.Large, i32 0, i32 1, !dbg !33
// CHECK:STDOUT:   store i32 %_1, ptr %tuple.elem1.tuple.elem, align 4, !dbg !33
// CHECK:STDOUT:   store i8 1, ptr %.loc23_14.1.discriminant, align 1, !dbg !32
// CHECK:STDOUT:   ret void, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeSmall.Main(ptr sret(<{ <{ i2, [7 x i8] }>, [16 x i8] }>) %return, i32 %n) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CSmall.Sized.Main(ptr %return, i32 %n), !dbg !41
// CHECK:STDOUT:   ret void, !dbg !42
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeLarge.Main(ptr sret(<{ <{ i2, [7 x i8] }>, [16 x i8] }>) %return, i64 %a, i32 %b) #0 !dbg !44 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CLarge.Sized.Main(ptr %return, i64 %a, i32 %b), !dbg !53
// CHECK:STDOUT:   ret void, !dbg !54
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CClassify.Main(ptr %s) #0 !dbg !56 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc41_16.3.discriminant = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %s, i32 0, i32 0, !dbg !62
// CHECK:STDOUT:   %.loc41_16.4 = load i8, ptr %.loc41_16.3.discriminant, align 1, !dbg !62
// CHECK:STDOUT:   %.loc41_16.41 = trunc i8 %.loc41_16.4 to i2, !dbg !62
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i2 -2, %.loc41_16.41, !dbg !62
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !62
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !64
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUse.Main(i32 %n) #0 !dbg !67 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.var = alloca <{ <{ i2, [7 x i8] }>, [16 x i8] }>, align 8, !dbg !70
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %v.var), !dbg !70
// CHECK:STDOUT:   call void @_CMakeSmall.Main(ptr %v.var, i32 %n), !dbg !72
// CHECK:STDOUT:   call void @"_CSelfDestruct.5bace55a89ab07d4:core.Destroy.Core"(ptr %v.var), !dbg !70
// CHECK:STDOUT:   ret void, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.94410a58f39d6747:core.Destroy.Core"(ptr %self) #0 !dbg !76 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !78
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !80 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !82
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !84 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !86
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !86
// CHECK:STDOUT:   ret void, !dbg !86
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !88 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !90
// CHECK:STDOUT:   ret void, !dbg !90
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !92 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.95298a988c812942:core.Destroy.Core"(ptr %self) #0 !dbg !96 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 1, !dbg !98
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !98
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64, i32 }, ptr %self, i32 0, i32 0, !dbg !98
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !98
// CHECK:STDOUT:   ret void, !dbg !98
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.95298a988c812942:core.Destroy.Core"(ptr %self) #0 !dbg !100 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.95298a988c812942:core.Destroy.Core"(ptr %self), !dbg !102
// CHECK:STDOUT:   ret void, !dbg !102
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a22524acbe498e70:core.Destroy.Core"(ptr %self) #0 !dbg !104 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !106
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a22524acbe498e70:core.Destroy.Core"(ptr %self) #0 !dbg !108 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a22524acbe498e70:core.Destroy.Core"(ptr %self), !dbg !110
// CHECK:STDOUT:   ret void, !dbg !110
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.1c0911d0a997ef4f:core.Destroy.Core"(ptr %self) #0 !dbg !112 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc53_3.1.payload = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %self, i32 0, i32 1, !dbg !114
// CHECK:STDOUT:   call void @"_CSelfDestruct.a22524acbe498e70:core.Destroy.Core"(ptr %.loc53_3.1.payload), !dbg !114
// CHECK:STDOUT:   %.loc53_3.2.discriminant = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [16 x i8] }>, ptr %self, i32 0, i32 0, !dbg !114
// CHECK:STDOUT:   call void @"_CSelfDestruct.94410a58f39d6747:core.Destroy.Core"(ptr %.loc53_3.2.discriminant), !dbg !114
// CHECK:STDOUT:   ret void, !dbg !114
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.1c0911d0a997ef4f:core.Destroy.Core"(ptr %self) #0 !dbg !116 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.1c0911d0a997ef4f:core.Destroy.Core"(ptr %self), !dbg !118
// CHECK:STDOUT:   ret void, !dbg !118
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.5bace55a89ab07d4:core.Destroy.Core"(ptr %self) #0 !dbg !120 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !122
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5bace55a89ab07d4:core.Destroy.Core"(ptr %self) #0 !dbg !124 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.5bace55a89ab07d4:core.Destroy.Core"(ptr %self), !dbg !126
// CHECK:STDOUT:   ret void, !dbg !126
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !130 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 @_Cglobal_none.Main, ptr align 8 @Sized.val.loc27_1.13, i64 24, i1 false)
// CHECK:STDOUT:   ret void, !dbg !132
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "payload_layout.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 2, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!9, !6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!9, !7, !6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{!6, !9}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !16 = !{null, !6}
// CHECK:STDOUT: !17 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !18 = !{null, !8}
// CHECK:STDOUT: !19 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !20 = !{null, !9}
// CHECK:STDOUT: !21 = !DISubroutineType(types: !20)
// CHECK:STDOUT: !22 = !{null, !7}
// CHECK:STDOUT: !23 = !DISubroutineType(types: !22)
// CHECK:STDOUT: !24 = distinct !DISubprogram(name: "Small", linkageName: "_CSmall.Sized.Main", scope: null, file: !4, line: 23, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !28)
// CHECK:STDOUT: !25 = !DILocalVariable(arg: 1, scope: !24, type: !6)
// CHECK:STDOUT: !26 = !DILocation(line: 23, column: 1, scope: !24)
// CHECK:STDOUT: !27 = !DILocation(line: 24, column: 16, scope: !24)
// CHECK:STDOUT: !28 = !{!25}
// CHECK:STDOUT: !29 = distinct !DISubprogram(name: "Large", linkageName: "_CLarge.Sized.Main", scope: null, file: !4, line: 23, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !34)
// CHECK:STDOUT: !30 = !DILocalVariable(arg: 1, scope: !29, type: !7)
// CHECK:STDOUT: !31 = !DILocalVariable(arg: 2, scope: !29, type: !6)
// CHECK:STDOUT: !32 = !DILocation(line: 23, column: 1, scope: !29)
// CHECK:STDOUT: !33 = !DILocation(line: 25, column: 24, scope: !29)
// CHECK:STDOUT: !34 = !{!30, !31}
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "MakeSmall", linkageName: "_CMakeSmall.Main", scope: null, file: !4, line: 31, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !43)
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !35, type: !6)
// CHECK:STDOUT: !41 = !DILocation(line: 32, column: 10, scope: !35)
// CHECK:STDOUT: !42 = !DILocation(line: 32, column: 3, scope: !35)
// CHECK:STDOUT: !43 = !{!36}
// CHECK:STDOUT: !44 = distinct !DISubprogram(name: "MakeLarge", linkageName: "_CMakeLarge.Main", scope: null, file: !4, line: 35, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !55)
// CHECK:STDOUT: !45 = !DILocalVariable(arg: 1, scope: !44, type: !7)
// CHECK:STDOUT: !46 = !DILocalVariable(arg: 2, scope: !44, type: !6)
// CHECK:STDOUT: !53 = !DILocation(line: 36, column: 10, scope: !44)
// CHECK:STDOUT: !54 = !DILocation(line: 36, column: 3, scope: !44)
// CHECK:STDOUT: !55 = !{!45, !46}
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "Classify", linkageName: "_CClassify.Main", scope: null, file: !4, line: 39, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !66)
// CHECK:STDOUT: !57 = !DILocalVariable(arg: 1, scope: !56, type: !9)
// CHECK:STDOUT: !62 = !DILocation(line: 41, column: 5, scope: !56)
// CHECK:STDOUT: !64 = !DILocation(line: 41, column: 21, scope: !56)
// CHECK:STDOUT: !65 = !DILocation(line: 42, column: 18, scope: !56)
// CHECK:STDOUT: !66 = !{!57}
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !4, line: 47, type: !17, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !75)
// CHECK:STDOUT: !68 = !DILocalVariable(arg: 1, scope: !67, type: !6)
// CHECK:STDOUT: !70 = !DILocation(line: 53, column: 3, scope: !67)
// CHECK:STDOUT: !72 = !DILocation(line: 53, column: 18, scope: !67)
// CHECK:STDOUT: !74 = !DILocation(line: 47, column: 1, scope: !67)
// CHECK:STDOUT: !75 = !{!68}
// CHECK:STDOUT: !76 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.94410a58f39d6747:core.Destroy.Core", scope: null, file: !4, line: 53, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !79)
// CHECK:STDOUT: !77 = !DILocalVariable(arg: 1, scope: !76, type: !8)
// CHECK:STDOUT: !78 = !DILocation(line: 53, column: 3, scope: !76)
// CHECK:STDOUT: !79 = !{!77}
// CHECK:STDOUT: !80 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 53, type: !17, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !83)
// CHECK:STDOUT: !81 = !DILocalVariable(arg: 1, scope: !80, type: !6)
// CHECK:STDOUT: !82 = !DILocation(line: 53, column: 3, scope: !80)
// CHECK:STDOUT: !83 = !{!81}
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 53, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !87)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !84, type: !9)
// CHECK:STDOUT: !86 = !DILocation(line: 53, column: 3, scope: !84)
// CHECK:STDOUT: !87 = !{!85}
// CHECK:STDOUT: !88 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 53, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !91)
// CHECK:STDOUT: !89 = !DILocalVariable(arg: 1, scope: !88, type: !9)
// CHECK:STDOUT: !90 = !DILocation(line: 53, column: 3, scope: !88)
// CHECK:STDOUT: !91 = !{!89}
// CHECK:STDOUT: !92 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !4, line: 53, type: !23, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !95)
// CHECK:STDOUT: !93 = !DILocalVariable(arg: 1, scope: !92, type: !7)
// CHECK:STDOUT: !94 = !DILocation(line: 53, column: 3, scope: !92)
// CHECK:STDOUT: !95 = !{!93}
// CHECK:STDOUT: !96 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.95298a988c812942:core.Destroy.Core", scope: null, file: !4, line: 53, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !99)
// CHECK:STDOUT: !97 = !DILocalVariable(arg: 1, scope: !96, type: !9)
// CHECK:STDOUT: !98 = !DILocation(line: 53, column: 3, scope: !96)
// CHECK:STDOUT: !99 = !{!97}
// CHECK:STDOUT: !100 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.95298a988c812942:core.Destroy.Core", scope: null, file: !4, line: 53, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !103)
// CHECK:STDOUT: !101 = !DILocalVariable(arg: 1, scope: !100, type: !9)
// CHECK:STDOUT: !102 = !DILocation(line: 53, column: 3, scope: !100)
// CHECK:STDOUT: !103 = !{!101}
// CHECK:STDOUT: !104 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a22524acbe498e70:core.Destroy.Core", scope: null, file: !4, line: 53, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !107)
// CHECK:STDOUT: !105 = !DILocalVariable(arg: 1, scope: !104, type: !9)
// CHECK:STDOUT: !106 = !DILocation(line: 53, column: 3, scope: !104)
// CHECK:STDOUT: !107 = !{!105}
// CHECK:STDOUT: !108 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a22524acbe498e70:core.Destroy.Core", scope: null, file: !4, line: 53, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !111)
// CHECK:STDOUT: !109 = !DILocalVariable(arg: 1, scope: !108, type: !9)
// CHECK:STDOUT: !110 = !DILocation(line: 53, column: 3, scope: !108)
// CHECK:STDOUT: !111 = !{!109}
// CHECK:STDOUT: !112 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.1c0911d0a997ef4f:core.Destroy.Core", scope: null, file: !4, line: 53, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !115)
// CHECK:STDOUT: !113 = !DILocalVariable(arg: 1, scope: !112, type: !9)
// CHECK:STDOUT: !114 = !DILocation(line: 53, column: 3, scope: !112)
// CHECK:STDOUT: !115 = !{!113}
// CHECK:STDOUT: !116 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.1c0911d0a997ef4f:core.Destroy.Core", scope: null, file: !4, line: 53, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !119)
// CHECK:STDOUT: !117 = !DILocalVariable(arg: 1, scope: !116, type: !9)
// CHECK:STDOUT: !118 = !DILocation(line: 53, column: 3, scope: !116)
// CHECK:STDOUT: !119 = !{!117}
// CHECK:STDOUT: !120 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.5bace55a89ab07d4:core.Destroy.Core", scope: null, file: !4, line: 53, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !123)
// CHECK:STDOUT: !121 = !DILocalVariable(arg: 1, scope: !120, type: !9)
// CHECK:STDOUT: !122 = !DILocation(line: 53, column: 3, scope: !120)
// CHECK:STDOUT: !123 = !{!121}
// CHECK:STDOUT: !124 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5bace55a89ab07d4:core.Destroy.Core", scope: null, file: !4, line: 53, type: !21, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !127)
// CHECK:STDOUT: !125 = !DILocalVariable(arg: 1, scope: !124, type: !9)
// CHECK:STDOUT: !126 = !DILocation(line: 53, column: 3, scope: !124)
// CHECK:STDOUT: !127 = !{!125}
// CHECK:STDOUT: !128 = !{null}
// CHECK:STDOUT: !129 = !DISubroutineType(types: !128)
// CHECK:STDOUT: !130 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !4, type: !129, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !132 = !DILocation(line: 0, scope: !130)
// CHECK:STDOUT:

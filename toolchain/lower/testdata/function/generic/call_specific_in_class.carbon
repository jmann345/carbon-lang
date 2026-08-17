// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/generic/call_specific_in_class.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/generic/call_specific_in_class.carbon

// Builds on `call_basic.carbon`. Checks different specific definitions are
// emitted for a generic function defined inside a class, when calling that
// generic function for an object, from a generic context.
// The specifics with a pointer type could be deduplicated here.
class C {
  fn Cfn[T: Core.Copy](unused self, x: T) -> T {
    return x;
  }
}

fn G[T: Core.Copy](x: T) -> T {
  var c: C;
  return c.Cfn(x);
}

fn F[T: Core.Copy](x: T) -> T {
  return G(x);
}

fn M() {
  var ptr_i32 : i32*;
  F(ptr_i32);
  var ptr_f64 : f64*;
  F(ptr_f64);
  var ptr_i8 : i8*;
  F(ptr_i8);
  var var_i32: i32 = 0;
  F(var_i32);
  var var_f64: f64 = 0.0;
  F(var_f64);
  var _: C;
  F(C);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'call_specific_in_class.carbon'
// CHECK:STDOUT: source_filename = "call_specific_in_class.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: %type.26 = type {}
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.807eb4f2d3ed7e54:core.Destroy.Core"(ptr %self) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !10
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CM.Main() #0 !dbg !11 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %ptr_i32.var = alloca ptr, align 8, !dbg !14
// CHECK:STDOUT:   %ptr_f64.var = alloca ptr, align 8, !dbg !15
// CHECK:STDOUT:   %ptr_i8.var = alloca ptr, align 8, !dbg !16
// CHECK:STDOUT:   %var_i32.var = alloca i32, align 4, !dbg !17
// CHECK:STDOUT:   %var_f64.var = alloca double, align 8, !dbg !18
// CHECK:STDOUT:   %_.var = alloca {}, align 1, !dbg !19
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %ptr_i32.var), !dbg !14
// CHECK:STDOUT:   store ptr poison, ptr %ptr_i32.var, align 8, !dbg !14
// CHECK:STDOUT:   %.loc34_5 = load ptr, ptr %ptr_i32.var, align 8, !dbg !20
// CHECK:STDOUT:   %F.call.loc34 = call ptr @_CF.Main.a76b78461416b4a8(ptr %.loc34_5), !dbg !21
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %ptr_f64.var), !dbg !15
// CHECK:STDOUT:   store ptr poison, ptr %ptr_f64.var, align 8, !dbg !15
// CHECK:STDOUT:   %.loc36_5 = load ptr, ptr %ptr_f64.var, align 8, !dbg !22
// CHECK:STDOUT:   %F.call.loc36 = call ptr @_CF.Main.5f2298097dd2e04c(ptr %.loc36_5), !dbg !23
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %ptr_i8.var), !dbg !16
// CHECK:STDOUT:   store ptr poison, ptr %ptr_i8.var, align 8, !dbg !16
// CHECK:STDOUT:   %.loc38_5 = load ptr, ptr %ptr_i8.var, align 8, !dbg !24
// CHECK:STDOUT:   %F.call.loc38 = call ptr @_CF.Main.f98aaa5a5017d617(ptr %.loc38_5), !dbg !25
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %var_i32.var), !dbg !17
// CHECK:STDOUT:   store i32 0, ptr %var_i32.var, align 4, !dbg !17
// CHECK:STDOUT:   %.loc40_5 = load i32, ptr %var_i32.var, align 4, !dbg !26
// CHECK:STDOUT:   %F.call.loc40 = call i32 @_CF.Main.4d6ceefeb7f772f4(i32 %.loc40_5), !dbg !27
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %var_f64.var), !dbg !18
// CHECK:STDOUT:   store double 0.000000e+00, ptr %var_f64.var, align 8, !dbg !18
// CHECK:STDOUT:   %.loc42_5 = load double, ptr %var_f64.var, align 8, !dbg !28
// CHECK:STDOUT:   %F.call.loc42 = call double @_CF.Main.c5e4ba542a56b71f(double %.loc42_5), !dbg !29
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var), !dbg !19
// CHECK:STDOUT:   %F.call.loc44 = call %type.26 @_CF.Main.71d6c598da8ca542(%type.26 zeroinitializer), !dbg !30
// CHECK:STDOUT:   call void @"_COp.807eb4f2d3ed7e54:core.Destroy.Core"(ptr %_.var), !dbg !19
// CHECK:STDOUT:   call void @"_COp.30d8007fdcc57f83:core.Destroy.Core"(ptr %var_f64.var), !dbg !18
// CHECK:STDOUT:   call void @"_COp.5e27612b9dd31a14:core.Destroy.Core"(ptr %var_i32.var), !dbg !17
// CHECK:STDOUT:   ret void, !dbg !31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.30d8007fdcc57f83:core.Destroy.Core"(ptr %self) #0 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5e27612b9dd31a14:core.Destroy.Core"(ptr %self) #0 !dbg !36 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !42
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CF.Main.a76b78461416b4a8(ptr %x) #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call ptr @_CG.Main.a76b78461416b4a8(ptr %x), !dbg !48
// CHECK:STDOUT:   ret ptr %G.call, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CF.Main.5f2298097dd2e04c(ptr %x) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call ptr @_CG.Main.5f2298097dd2e04c(ptr %x), !dbg !53
// CHECK:STDOUT:   ret ptr %G.call, !dbg !54
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CF.Main.f98aaa5a5017d617(ptr %x) #0 !dbg !55 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call ptr @_CG.Main.f98aaa5a5017d617(ptr %x), !dbg !58
// CHECK:STDOUT:   ret ptr %G.call, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CF.Main.4d6ceefeb7f772f4(i32 %x) #0 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call i32 @_CG.Main.4d6ceefeb7f772f4(i32 %x), !dbg !65
// CHECK:STDOUT:   ret i32 %G.call, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr double @_CF.Main.c5e4ba542a56b71f(double %x) #0 !dbg !67 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call double @_CG.Main.c5e4ba542a56b71f(double %x), !dbg !70
// CHECK:STDOUT:   ret double %G.call, !dbg !71
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr %type.26 @_CF.Main.71d6c598da8ca542(%type.26 %x) #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call %type.26 @_CG.Main.71d6c598da8ca542(%type.26 %x), !dbg !75
// CHECK:STDOUT:   ret %type.26 %G.call, !dbg !76
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CG.Main.a76b78461416b4a8(ptr %x) #0 !dbg !77 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %c.var = alloca {}, align 1, !dbg !80
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %c.var), !dbg !80
// CHECK:STDOUT:   %C.Cfn.call = call ptr @_CCfn.C.Main.a76b78461416b4a8(ptr %c.var, ptr %x), !dbg !81
// CHECK:STDOUT:   call void @"_COp.807eb4f2d3ed7e54:core.Destroy.Core"(ptr %c.var), !dbg !80
// CHECK:STDOUT:   ret ptr %C.Cfn.call, !dbg !82
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CG.Main.5f2298097dd2e04c(ptr %x) #0 !dbg !83 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %c.var = alloca {}, align 1, !dbg !86
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %c.var), !dbg !86
// CHECK:STDOUT:   %C.Cfn.call = call ptr @_CCfn.C.Main.5f2298097dd2e04c(ptr %c.var, ptr %x), !dbg !87
// CHECK:STDOUT:   call void @"_COp.807eb4f2d3ed7e54:core.Destroy.Core"(ptr %c.var), !dbg !86
// CHECK:STDOUT:   ret ptr %C.Cfn.call, !dbg !88
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CG.Main.f98aaa5a5017d617(ptr %x) #0 !dbg !89 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %c.var = alloca {}, align 1, !dbg !92
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %c.var), !dbg !92
// CHECK:STDOUT:   %C.Cfn.call = call ptr @_CCfn.C.Main.f98aaa5a5017d617(ptr %c.var, ptr %x), !dbg !93
// CHECK:STDOUT:   call void @"_COp.807eb4f2d3ed7e54:core.Destroy.Core"(ptr %c.var), !dbg !92
// CHECK:STDOUT:   ret ptr %C.Cfn.call, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CG.Main.4d6ceefeb7f772f4(i32 %x) #0 !dbg !95 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %c.var = alloca {}, align 1, !dbg !98
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %c.var), !dbg !98
// CHECK:STDOUT:   %C.Cfn.call = call i32 @_CCfn.C.Main.4d6ceefeb7f772f4(ptr %c.var, i32 %x), !dbg !99
// CHECK:STDOUT:   call void @"_COp.807eb4f2d3ed7e54:core.Destroy.Core"(ptr %c.var), !dbg !98
// CHECK:STDOUT:   ret i32 %C.Cfn.call, !dbg !100
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr double @_CG.Main.c5e4ba542a56b71f(double %x) #0 !dbg !101 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %c.var = alloca {}, align 1, !dbg !104
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %c.var), !dbg !104
// CHECK:STDOUT:   %C.Cfn.call = call double @_CCfn.C.Main.c5e4ba542a56b71f(ptr %c.var, double %x), !dbg !105
// CHECK:STDOUT:   call void @"_COp.807eb4f2d3ed7e54:core.Destroy.Core"(ptr %c.var), !dbg !104
// CHECK:STDOUT:   ret double %C.Cfn.call, !dbg !106
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr %type.26 @_CG.Main.71d6c598da8ca542(%type.26 %x) #0 !dbg !107 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %c.var = alloca {}, align 1, !dbg !110
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %c.var), !dbg !110
// CHECK:STDOUT:   %C.Cfn.call = call %type.26 @_CCfn.C.Main.71d6c598da8ca542(ptr %c.var, %type.26 %x), !dbg !111
// CHECK:STDOUT:   call void @"_COp.807eb4f2d3ed7e54:core.Destroy.Core"(ptr %c.var), !dbg !110
// CHECK:STDOUT:   ret %type.26 %C.Cfn.call, !dbg !112
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CCfn.C.Main.a76b78461416b4a8(ptr %self, ptr %x) #0 !dbg !113 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret ptr %x, !dbg !119
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CCfn.C.Main.5f2298097dd2e04c(ptr %self, ptr %x) #0 !dbg !120 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret ptr %x, !dbg !124
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CCfn.C.Main.f98aaa5a5017d617(ptr %self, ptr %x) #0 !dbg !125 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret ptr %x, !dbg !129
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CCfn.C.Main.4d6ceefeb7f772f4(ptr %self, i32 %x) #0 !dbg !130 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 %x, !dbg !136
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr double @_CCfn.C.Main.c5e4ba542a56b71f(ptr %self, double %x) #0 !dbg !137 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret double %x, !dbg !141
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr %type.26 @_CCfn.C.Main.71d6c598da8ca542(ptr %self, %type.26 %x) #0 !dbg !142 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret %type.26 %x, !dbg !146
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 0, 1, 2, 3, 4, 5, 11, 10, 9, 8, 7, 6 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "call_specific_in_class.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Op", linkageName: "_COp.807eb4f2d3ed7e54:core.Destroy.Core", scope: null, file: !1, line: 24, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{null, !7}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!9}
// CHECK:STDOUT: !9 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !10 = !DILocation(line: 24, column: 3, scope: !4)
// CHECK:STDOUT: !11 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main", scope: null, file: !1, line: 32, type: !12, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !12 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !13 = !{null}
// CHECK:STDOUT: !14 = !DILocation(line: 33, column: 3, scope: !11)
// CHECK:STDOUT: !15 = !DILocation(line: 35, column: 3, scope: !11)
// CHECK:STDOUT: !16 = !DILocation(line: 37, column: 3, scope: !11)
// CHECK:STDOUT: !17 = !DILocation(line: 39, column: 3, scope: !11)
// CHECK:STDOUT: !18 = !DILocation(line: 41, column: 3, scope: !11)
// CHECK:STDOUT: !19 = !DILocation(line: 43, column: 3, scope: !11)
// CHECK:STDOUT: !20 = !DILocation(line: 34, column: 5, scope: !11)
// CHECK:STDOUT: !21 = !DILocation(line: 34, column: 3, scope: !11)
// CHECK:STDOUT: !22 = !DILocation(line: 36, column: 5, scope: !11)
// CHECK:STDOUT: !23 = !DILocation(line: 36, column: 3, scope: !11)
// CHECK:STDOUT: !24 = !DILocation(line: 38, column: 5, scope: !11)
// CHECK:STDOUT: !25 = !DILocation(line: 38, column: 3, scope: !11)
// CHECK:STDOUT: !26 = !DILocation(line: 40, column: 5, scope: !11)
// CHECK:STDOUT: !27 = !DILocation(line: 40, column: 3, scope: !11)
// CHECK:STDOUT: !28 = !DILocation(line: 42, column: 5, scope: !11)
// CHECK:STDOUT: !29 = !DILocation(line: 42, column: 3, scope: !11)
// CHECK:STDOUT: !30 = !DILocation(line: 44, column: 3, scope: !11)
// CHECK:STDOUT: !31 = !DILocation(line: 32, column: 1, scope: !11)
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "Op", linkageName: "_COp.30d8007fdcc57f83:core.Destroy.Core", scope: null, file: !1, line: 41, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !33)
// CHECK:STDOUT: !33 = !{!34}
// CHECK:STDOUT: !34 = !DILocalVariable(arg: 1, scope: !32, type: !7)
// CHECK:STDOUT: !35 = !DILocation(line: 41, column: 3, scope: !32)
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5e27612b9dd31a14:core.Destroy.Core", scope: null, file: !1, line: 39, type: !37, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !40)
// CHECK:STDOUT: !37 = !DISubroutineType(types: !38)
// CHECK:STDOUT: !38 = !{null, !39}
// CHECK:STDOUT: !39 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !40 = !{!41}
// CHECK:STDOUT: !41 = !DILocalVariable(arg: 1, scope: !36, type: !39)
// CHECK:STDOUT: !42 = !DILocation(line: 39, column: 3, scope: !36)
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.a76b78461416b4a8", scope: null, file: !1, line: 28, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !46)
// CHECK:STDOUT: !44 = !DISubroutineType(types: !45)
// CHECK:STDOUT: !45 = !{!7, !7}
// CHECK:STDOUT: !46 = !{!47}
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !43, type: !7)
// CHECK:STDOUT: !48 = !DILocation(line: 29, column: 10, scope: !43)
// CHECK:STDOUT: !49 = !DILocation(line: 29, column: 3, scope: !43)
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.5f2298097dd2e04c", scope: null, file: !1, line: 28, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !51)
// CHECK:STDOUT: !51 = !{!52}
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !50, type: !7)
// CHECK:STDOUT: !53 = !DILocation(line: 29, column: 10, scope: !50)
// CHECK:STDOUT: !54 = !DILocation(line: 29, column: 3, scope: !50)
// CHECK:STDOUT: !55 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.f98aaa5a5017d617", scope: null, file: !1, line: 28, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !56)
// CHECK:STDOUT: !56 = !{!57}
// CHECK:STDOUT: !57 = !DILocalVariable(arg: 1, scope: !55, type: !7)
// CHECK:STDOUT: !58 = !DILocation(line: 29, column: 10, scope: !55)
// CHECK:STDOUT: !59 = !DILocation(line: 29, column: 3, scope: !55)
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.4d6ceefeb7f772f4", scope: null, file: !1, line: 28, type: !61, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !63)
// CHECK:STDOUT: !61 = !DISubroutineType(types: !62)
// CHECK:STDOUT: !62 = !{!39, !39}
// CHECK:STDOUT: !63 = !{!64}
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !60, type: !39)
// CHECK:STDOUT: !65 = !DILocation(line: 29, column: 10, scope: !60)
// CHECK:STDOUT: !66 = !DILocation(line: 29, column: 3, scope: !60)
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.c5e4ba542a56b71f", scope: null, file: !1, line: 28, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !68)
// CHECK:STDOUT: !68 = !{!69}
// CHECK:STDOUT: !69 = !DILocalVariable(arg: 1, scope: !67, type: !7)
// CHECK:STDOUT: !70 = !DILocation(line: 29, column: 10, scope: !67)
// CHECK:STDOUT: !71 = !DILocation(line: 29, column: 3, scope: !67)
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.71d6c598da8ca542", scope: null, file: !1, line: 28, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !73)
// CHECK:STDOUT: !73 = !{!74}
// CHECK:STDOUT: !74 = !DILocalVariable(arg: 1, scope: !72, type: !7)
// CHECK:STDOUT: !75 = !DILocation(line: 29, column: 10, scope: !72)
// CHECK:STDOUT: !76 = !DILocation(line: 29, column: 3, scope: !72)
// CHECK:STDOUT: !77 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.a76b78461416b4a8", scope: null, file: !1, line: 23, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !78)
// CHECK:STDOUT: !78 = !{!79}
// CHECK:STDOUT: !79 = !DILocalVariable(arg: 1, scope: !77, type: !7)
// CHECK:STDOUT: !80 = !DILocation(line: 24, column: 3, scope: !77)
// CHECK:STDOUT: !81 = !DILocation(line: 25, column: 10, scope: !77)
// CHECK:STDOUT: !82 = !DILocation(line: 25, column: 3, scope: !77)
// CHECK:STDOUT: !83 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.5f2298097dd2e04c", scope: null, file: !1, line: 23, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !84)
// CHECK:STDOUT: !84 = !{!85}
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !83, type: !7)
// CHECK:STDOUT: !86 = !DILocation(line: 24, column: 3, scope: !83)
// CHECK:STDOUT: !87 = !DILocation(line: 25, column: 10, scope: !83)
// CHECK:STDOUT: !88 = !DILocation(line: 25, column: 3, scope: !83)
// CHECK:STDOUT: !89 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.f98aaa5a5017d617", scope: null, file: !1, line: 23, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !90)
// CHECK:STDOUT: !90 = !{!91}
// CHECK:STDOUT: !91 = !DILocalVariable(arg: 1, scope: !89, type: !7)
// CHECK:STDOUT: !92 = !DILocation(line: 24, column: 3, scope: !89)
// CHECK:STDOUT: !93 = !DILocation(line: 25, column: 10, scope: !89)
// CHECK:STDOUT: !94 = !DILocation(line: 25, column: 3, scope: !89)
// CHECK:STDOUT: !95 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.4d6ceefeb7f772f4", scope: null, file: !1, line: 23, type: !61, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !96)
// CHECK:STDOUT: !96 = !{!97}
// CHECK:STDOUT: !97 = !DILocalVariable(arg: 1, scope: !95, type: !39)
// CHECK:STDOUT: !98 = !DILocation(line: 24, column: 3, scope: !95)
// CHECK:STDOUT: !99 = !DILocation(line: 25, column: 10, scope: !95)
// CHECK:STDOUT: !100 = !DILocation(line: 25, column: 3, scope: !95)
// CHECK:STDOUT: !101 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.c5e4ba542a56b71f", scope: null, file: !1, line: 23, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !102)
// CHECK:STDOUT: !102 = !{!103}
// CHECK:STDOUT: !103 = !DILocalVariable(arg: 1, scope: !101, type: !7)
// CHECK:STDOUT: !104 = !DILocation(line: 24, column: 3, scope: !101)
// CHECK:STDOUT: !105 = !DILocation(line: 25, column: 10, scope: !101)
// CHECK:STDOUT: !106 = !DILocation(line: 25, column: 3, scope: !101)
// CHECK:STDOUT: !107 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.71d6c598da8ca542", scope: null, file: !1, line: 23, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !108)
// CHECK:STDOUT: !108 = !{!109}
// CHECK:STDOUT: !109 = !DILocalVariable(arg: 1, scope: !107, type: !7)
// CHECK:STDOUT: !110 = !DILocation(line: 24, column: 3, scope: !107)
// CHECK:STDOUT: !111 = !DILocation(line: 25, column: 10, scope: !107)
// CHECK:STDOUT: !112 = !DILocation(line: 25, column: 3, scope: !107)
// CHECK:STDOUT: !113 = distinct !DISubprogram(name: "Cfn", linkageName: "_CCfn.C.Main.a76b78461416b4a8", scope: null, file: !1, line: 18, type: !114, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !116)
// CHECK:STDOUT: !114 = !DISubroutineType(types: !115)
// CHECK:STDOUT: !115 = !{!7, !7, !7}
// CHECK:STDOUT: !116 = !{!117, !118}
// CHECK:STDOUT: !117 = !DILocalVariable(arg: 1, scope: !113, type: !7)
// CHECK:STDOUT: !118 = !DILocalVariable(arg: 2, scope: !113, type: !7)
// CHECK:STDOUT: !119 = !DILocation(line: 19, column: 5, scope: !113)
// CHECK:STDOUT: !120 = distinct !DISubprogram(name: "Cfn", linkageName: "_CCfn.C.Main.5f2298097dd2e04c", scope: null, file: !1, line: 18, type: !114, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !121)
// CHECK:STDOUT: !121 = !{!122, !123}
// CHECK:STDOUT: !122 = !DILocalVariable(arg: 1, scope: !120, type: !7)
// CHECK:STDOUT: !123 = !DILocalVariable(arg: 2, scope: !120, type: !7)
// CHECK:STDOUT: !124 = !DILocation(line: 19, column: 5, scope: !120)
// CHECK:STDOUT: !125 = distinct !DISubprogram(name: "Cfn", linkageName: "_CCfn.C.Main.f98aaa5a5017d617", scope: null, file: !1, line: 18, type: !114, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !126)
// CHECK:STDOUT: !126 = !{!127, !128}
// CHECK:STDOUT: !127 = !DILocalVariable(arg: 1, scope: !125, type: !7)
// CHECK:STDOUT: !128 = !DILocalVariable(arg: 2, scope: !125, type: !7)
// CHECK:STDOUT: !129 = !DILocation(line: 19, column: 5, scope: !125)
// CHECK:STDOUT: !130 = distinct !DISubprogram(name: "Cfn", linkageName: "_CCfn.C.Main.4d6ceefeb7f772f4", scope: null, file: !1, line: 18, type: !131, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !133)
// CHECK:STDOUT: !131 = !DISubroutineType(types: !132)
// CHECK:STDOUT: !132 = !{!39, !7, !39}
// CHECK:STDOUT: !133 = !{!134, !135}
// CHECK:STDOUT: !134 = !DILocalVariable(arg: 1, scope: !130, type: !7)
// CHECK:STDOUT: !135 = !DILocalVariable(arg: 2, scope: !130, type: !39)
// CHECK:STDOUT: !136 = !DILocation(line: 19, column: 5, scope: !130)
// CHECK:STDOUT: !137 = distinct !DISubprogram(name: "Cfn", linkageName: "_CCfn.C.Main.c5e4ba542a56b71f", scope: null, file: !1, line: 18, type: !114, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !138)
// CHECK:STDOUT: !138 = !{!139, !140}
// CHECK:STDOUT: !139 = !DILocalVariable(arg: 1, scope: !137, type: !7)
// CHECK:STDOUT: !140 = !DILocalVariable(arg: 2, scope: !137, type: !7)
// CHECK:STDOUT: !141 = !DILocation(line: 19, column: 5, scope: !137)
// CHECK:STDOUT: !142 = distinct !DISubprogram(name: "Cfn", linkageName: "_CCfn.C.Main.71d6c598da8ca542", scope: null, file: !1, line: 18, type: !114, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !143)
// CHECK:STDOUT: !143 = !{!144, !145}
// CHECK:STDOUT: !144 = !DILocalVariable(arg: 1, scope: !142, type: !7)
// CHECK:STDOUT: !145 = !DILocalVariable(arg: 2, scope: !142, type: !7)
// CHECK:STDOUT: !146 = !DILocation(line: 19, column: 5, scope: !142)
// CHECK:STDOUT:

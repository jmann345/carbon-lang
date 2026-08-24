// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/destroy.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/function/export/generic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/function/export/generic.carbon

// --- generic_type_impls_interface.carbon
library "[[@TEST_NAME]]";
import Cpp;

interface I {
  fn Doit(self);
}

class A {
  impl as I {
    fn Doit(unused self) {}
  }
}
class B {
  impl as I {
    fn Doit(unused self) {}
  }
}

fn F[T: I](t: T) {
  t.Doit();
}

inline Cpp '''
void G() {
  Carbon::A a;
  Carbon::B b;
  Carbon::F(a);
  Carbon::F(b);
}
''';

fn Run() {
  Cpp.G();
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'generic_type_impls_interface.carbon'
// CHECK:STDOUT: source_filename = "generic_type_impls_interface.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %"class.Carbon::A" = type {}
// CHECK:STDOUT: %"class.Carbon::B" = type {}
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress uwtable
// CHECK:STDOUT: define dso_local void @_Z1Gv() #0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a = alloca %"class.Carbon::A", align 1
// CHECK:STDOUT:   %b = alloca %"class.Carbon::B", align 1
// CHECK:STDOUT:   %agg.tmp = alloca %"class.Carbon::A", align 1
// CHECK:STDOUT:   %agg.tmp1 = alloca %"class.Carbon::B", align 1
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a) #3
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b) #3
// CHECK:STDOUT:   call void @_ZN6CarbonL1FENS_1AE()
// CHECK:STDOUT:   call void @_ZN6CarbonL1FENS_1BE()
// CHECK:STDOUT:   call void @llvm.lifetime.end.p0(ptr %b) #3
// CHECK:STDOUT:   call void @llvm.lifetime.end.p0(ptr %a) #3
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN6CarbonL1FENS_1AE() #2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %0 = alloca %"class.Carbon::A", align 1
// CHECK:STDOUT:   call void @_CF__carbon_thunk.26f2099a79512a5d.Main(ptr noundef nonnull align 1 %0)
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN6CarbonL1FENS_1BE() #2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %0 = alloca %"class.Carbon::B", align 1
// CHECK:STDOUT:   call void @_CF__carbon_thunk.7a3b9f04ddf4269e.Main(ptr noundef nonnull align 1 %0)
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.end.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CDoit.A.Main:I.Main"(ptr %self) #3 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !18
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CDoit.B.Main:I.Main"(ptr %self) #3 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !22
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CF__carbon_thunk.26f2099a79512a5d.Main(ptr %_) #3 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CF.Main.6662a1ffb773360a(ptr %_), !dbg !26
// CHECK:STDOUT:   ret void, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CF__carbon_thunk.7a3b9f04ddf4269e.Main(ptr %_) #3 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CF.Main.d53b17eed3ce903c(ptr %_), !dbg !30
// CHECK:STDOUT:   ret void, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #3 !dbg !31 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_Z1Gv.carbon_thunk.(), !dbg !35
// CHECK:STDOUT:   ret i32 0, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z1Gv.carbon_thunk.() #2 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   invoke void @_Z1Gv()
// CHECK:STDOUT:           to label %invoke.cont unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %entry
// CHECK:STDOUT:   %0 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %1 = extractvalue { ptr, i32 } %0, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %1) #5
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CF.Main.6662a1ffb773360a(ptr %t) #3 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CDoit.A.Main:I.Main"(ptr %t), !dbg !40
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CF.Main.d53b17eed3ce903c(ptr %t) #3 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CDoit.B.Main:I.Main"(ptr %t), !dbg !45
// CHECK:STDOUT:   ret void, !dbg !46
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #4 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #3
// CHECK:STDOUT:   call void @_ZSt9terminatev() #5
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.end.p0, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { mustprogress uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #2 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #3 = { nounwind }
// CHECK:STDOUT: attributes #4 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3, !4, !5, !6}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!7}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "generic_type_impls_interface.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !3 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !4 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !5 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !6 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !7 = !{!8, !9, i64 0}
// CHECK:STDOUT: !8 = !{!"__libc_errno", !9, i64 0}
// CHECK:STDOUT: !9 = !{!"int", !10, i64 0}
// CHECK:STDOUT: !10 = !{!"omnipotent char", !11, i64 0}
// CHECK:STDOUT: !11 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "Doit", linkageName: "_CDoit.A.Main:I.Main", scope: null, file: !1, line: 10, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !16)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{null, !15}
// CHECK:STDOUT: !15 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !16 = !{!17}
// CHECK:STDOUT: !17 = !DILocalVariable(arg: 1, scope: !12, type: !15)
// CHECK:STDOUT: !18 = !DILocation(line: 10, column: 5, scope: !12)
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "Doit", linkageName: "_CDoit.B.Main:I.Main", scope: null, file: !1, line: 15, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !20)
// CHECK:STDOUT: !20 = !{!21}
// CHECK:STDOUT: !21 = !DILocalVariable(arg: 1, scope: !19, type: !15)
// CHECK:STDOUT: !22 = !DILocation(line: 15, column: 5, scope: !19)
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "F__carbon_thunk.26f2099a79512a5d", linkageName: "_CF__carbon_thunk.26f2099a79512a5d.Main", scope: null, file: !1, line: 19, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !24)
// CHECK:STDOUT: !24 = !{!25}
// CHECK:STDOUT: !25 = !DILocalVariable(arg: 1, scope: !23, type: !15)
// CHECK:STDOUT: !26 = !DILocation(line: 19, column: 1, scope: !23)
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "F__carbon_thunk.7a3b9f04ddf4269e", linkageName: "_CF__carbon_thunk.7a3b9f04ddf4269e.Main", scope: null, file: !1, line: 19, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !28)
// CHECK:STDOUT: !28 = !{!29}
// CHECK:STDOUT: !29 = !DILocalVariable(arg: 1, scope: !27, type: !15)
// CHECK:STDOUT: !30 = !DILocation(line: 19, column: 1, scope: !27)
// CHECK:STDOUT: !31 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !1, line: 32, type: !32, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !32 = !DISubroutineType(types: !33)
// CHECK:STDOUT: !33 = !{!34}
// CHECK:STDOUT: !34 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !35 = !DILocation(line: 33, column: 3, scope: !31)
// CHECK:STDOUT: !36 = !DILocation(line: 32, column: 1, scope: !31)
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.6662a1ffb773360a", scope: null, file: !1, line: 19, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !38)
// CHECK:STDOUT: !38 = !{!39}
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !37, type: !15)
// CHECK:STDOUT: !40 = !DILocation(line: 20, column: 3, scope: !37)
// CHECK:STDOUT: !41 = !DILocation(line: 19, column: 1, scope: !37)
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.d53b17eed3ce903c", scope: null, file: !1, line: 19, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !43)
// CHECK:STDOUT: !43 = !{!44}
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !42, type: !15)
// CHECK:STDOUT: !45 = !DILocation(line: 20, column: 3, scope: !42)
// CHECK:STDOUT: !46 = !DILocation(line: 19, column: 1, scope: !42)
// CHECK:STDOUT:

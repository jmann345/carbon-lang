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
// CHECK:STDOUT: @.str = private unnamed_addr constant [68 x i8] c"carbon: C++ exception escaped into Carbon through `G`; terminating\0A\00", align 1
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
// CHECK:STDOUT: define void @"_CDoit.A.Main:I.Main"(ptr %self) #3 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !21
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CDoit.B.Main:I.Main"(ptr %self) #3 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CF__carbon_thunk.26f2099a79512a5d.Main(ptr %_) #3 !dbg !28 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CF.Main.6662a1ffb773360a(ptr %_), !dbg !30
// CHECK:STDOUT:   ret void, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CF__carbon_thunk.7a3b9f04ddf4269e.Main(ptr %_) #3 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CF.Main.d53b17eed3ce903c(ptr %_), !dbg !34
// CHECK:STDOUT:   ret void, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #3 !dbg !36 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_Z1Gv.carbon_thunk.(), !dbg !37
// CHECK:STDOUT:   ret i32 0, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z1Gv.carbon_thunk.() #2 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   invoke void @_Z1Gv()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %0 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %1 = extractvalue { ptr, i32 } %0, 0
// CHECK:STDOUT:   store ptr %1, ptr %exn.slot, align 8
// CHECK:STDOUT:   %2 = extractvalue { ptr, i32 } %0, 1
// CHECK:STDOUT:   store i32 %2, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %3 = call ptr @__cxa_begin_catch(ptr %exn) #3
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 67) #3
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %4 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %4, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %5) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CF.Main.6662a1ffb773360a(ptr %t) #3 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CDoit.A.Main:I.Main"(ptr %t), !dbg !42
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CF.Main.d53b17eed3ce903c(ptr %t) #3 !dbg !45 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CDoit.B.Main:I.Main"(ptr %t), !dbg !48
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #4
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #5 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #3
// CHECK:STDOUT:   call void @_ZSt9terminatev() #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
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
// CHECK:STDOUT: attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!9}
// CHECK:STDOUT: !llvm.module.flags = !{!53, !54, !55, !4, !5}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!58}
// CHECK:STDOUT:
// CHECK:STDOUT: !4 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !5 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !8 = !DIFile(filename: "generic_type_impls_interface.carbon", directory: "")
// CHECK:STDOUT: !9 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !8, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !10 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !11 = !{null, !10}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !14 = !{!13}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "Doit", linkageName: "_CDoit.A.Main:I.Main", scope: null, file: !8, line: 10, type: !12, spFlags: DISPFlagDefinition, unit: !9, retainedNodes: !22)
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 1, scope: !18, type: !10)
// CHECK:STDOUT: !21 = !DILocation(line: 10, column: 5, scope: !18)
// CHECK:STDOUT: !22 = !{!19}
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "Doit", linkageName: "_CDoit.B.Main:I.Main", scope: null, file: !8, line: 15, type: !12, spFlags: DISPFlagDefinition, unit: !9, retainedNodes: !27)
// CHECK:STDOUT: !24 = !DILocalVariable(arg: 1, scope: !23, type: !10)
// CHECK:STDOUT: !26 = !DILocation(line: 15, column: 5, scope: !23)
// CHECK:STDOUT: !27 = !{!24}
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "F__carbon_thunk.26f2099a79512a5d", linkageName: "_CF__carbon_thunk.26f2099a79512a5d.Main", scope: null, file: !8, line: 19, type: !12, spFlags: DISPFlagDefinition, unit: !9, retainedNodes: !31)
// CHECK:STDOUT: !29 = !DILocalVariable(arg: 1, scope: !28, type: !10)
// CHECK:STDOUT: !30 = !DILocation(line: 19, column: 1, scope: !28)
// CHECK:STDOUT: !31 = !{!29}
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "F__carbon_thunk.7a3b9f04ddf4269e", linkageName: "_CF__carbon_thunk.7a3b9f04ddf4269e.Main", scope: null, file: !8, line: 19, type: !12, spFlags: DISPFlagDefinition, unit: !9, retainedNodes: !35)
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !32, type: !10)
// CHECK:STDOUT: !34 = !DILocation(line: 19, column: 1, scope: !32)
// CHECK:STDOUT: !35 = !{!33}
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !8, line: 32, type: !15, spFlags: DISPFlagDefinition, unit: !9)
// CHECK:STDOUT: !37 = !DILocation(line: 33, column: 3, scope: !36)
// CHECK:STDOUT: !38 = !DILocation(line: 32, column: 1, scope: !36)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.6662a1ffb773360a", scope: null, file: !8, line: 19, type: !12, spFlags: DISPFlagDefinition, unit: !9, retainedNodes: !44)
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !39, type: !10)
// CHECK:STDOUT: !42 = !DILocation(line: 20, column: 3, scope: !39)
// CHECK:STDOUT: !43 = !DILocation(line: 19, column: 1, scope: !39)
// CHECK:STDOUT: !44 = !{!40}
// CHECK:STDOUT: !45 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.d53b17eed3ce903c", scope: null, file: !8, line: 19, type: !12, spFlags: DISPFlagDefinition, unit: !9, retainedNodes: !50)
// CHECK:STDOUT: !46 = !DILocalVariable(arg: 1, scope: !45, type: !10)
// CHECK:STDOUT: !48 = !DILocation(line: 20, column: 3, scope: !45)
// CHECK:STDOUT: !49 = !DILocation(line: 19, column: 1, scope: !45)
// CHECK:STDOUT: !50 = !{!46}
// CHECK:STDOUT: !51 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !52 = !{!"omnipotent char", !51, i64 0}
// CHECK:STDOUT: !53 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !54 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !55 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !56 = !{!"int", !52, i64 0}
// CHECK:STDOUT: !57 = !{!"__libc_errno", !56, i64 0}
// CHECK:STDOUT: !58 = !{!57, !56, i64 0}
// CHECK:STDOUT:

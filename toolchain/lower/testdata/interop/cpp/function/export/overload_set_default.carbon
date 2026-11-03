// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/function/export/overload_set_default.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/function/export/overload_set_default.carbon

// The C++ side of an exported set with a defaulted member
// (fork/overload/ov4-plan.md D-OV4-10): Carbon's `F(1)` calls member 0
// (`_CF:overload<0>.Main`) with the default `2`, and C++'s `Carbon::F(1)`
// calls member 1 through its thunk, because this trunk exports no default
// argument (upstream 9799a2326 arrives with UA-3).

// --- divergence_omitted.carbon

library "[[@TEST_NAME]]";

import Cpp;

overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }
overload fn F(unused b: bool) -> i32 { return -1; }

inline Cpp '''
inline int CallOne() { return Carbon::F(1); }
''';

fn Use() -> i32 { return F(1) + Cpp.CallOne(); }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'divergence_omitted.carbon'
// CHECK:STDOUT: source_filename = "divergence_omitted.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z7CallOnev = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [74 x i8] c"carbon: C++ exception escaped into Carbon through `CallOne`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload0.Main"(i32 %x, i32 %y) #0 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.MulWith.impl.Op.call = mul i32 %x, 10, !dbg !25
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Int.as.MulWith.impl.Op.call, %y, !dbg !25
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload1.Main"(i1 %b) #0 !dbg !29 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 -1, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CF__carbon_thunk:overload0.Main"(ptr %_, ptr %_1, ptr %_2) #0 !dbg !36 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_42.1 = load i32, ptr %_, align 4, !dbg !40
// CHECK:STDOUT:   %.loc6_42.2 = load i32, ptr %_1, align 4, !dbg !40
// CHECK:STDOUT:   %F.call = call i32 @"_CF:overload0.Main"(i32 %.loc6_42.1, i32 %.loc6_42.2), !dbg !40
// CHECK:STDOUT:   store i32 %F.call, ptr %_2, align 4, !dbg !40
// CHECK:STDOUT:   ret void, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CF__carbon_thunk:overload1.Main"(ptr %_, ptr %_1) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7 = load i8, ptr %_, align 1, !dbg !45
// CHECK:STDOUT:   %.loc72 = trunc i8 %.loc7 to i1, !dbg !45
// CHECK:STDOUT:   %F.call = call i32 @"_CF:overload1.Main"(i1 %.loc72), !dbg !45
// CHECK:STDOUT:   store i32 %F.call, ptr %_1, align 4, !dbg !45
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !47 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %F.call = call i32 @"_CF:overload0.Main"(i32 1, i32 2), !dbg !50
// CHECK:STDOUT:   %CallOne__carbon_thunk.call = call i32 @_Z7CallOnev.carbon_thunk.(), !dbg !51
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %F.call, %CallOne__carbon_thunk.call, !dbg !50
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_Z7CallOnev.carbon_thunk.() #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   %call = invoke noundef i32 @_Z7CallOnev()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret i32 %call
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
// CHECK:STDOUT:   %3 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 73) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #5
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %4 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %4, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %5) #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: inlinehint mustprogress uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef i32 @_Z7CallOnev() #2 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %call = call noundef i32 @_ZN6CarbonL1FEb(i1 noundef zeroext true)
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #3
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #4 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_ZN6CarbonL1FEb(i1 noundef zeroext %0) #1 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca i32, align 4
// CHECK:STDOUT:   %.addr = alloca i8, align 1
// CHECK:STDOUT:   %storedv = zext i1 %0 to i8
// CHECK:STDOUT:   store i8 %storedv, ptr %.addr, align 1, !tbaa !56
// CHECK:STDOUT:   call void @"_CF__carbon_thunk:overload1.Main"(ptr noundef nonnull align 1 dereferenceable(1) %.addr, ptr noundef nonnull align 4 dereferenceable(4) %retval)
// CHECK:STDOUT:   %1 = load i32, ptr %retval, align 4
// CHECK:STDOUT:   ret i32 %1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { inlinehint mustprogress uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #3 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noreturn }
// CHECK:STDOUT: attributes #6 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!58, !59, !60, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!62}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "divergence_omitted.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{!6, !6, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!6, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !6, !6, !6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{null, !9, !6}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !16 = !{!6}
// CHECK:STDOUT: !17 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload0.Main", scope: null, file: !4, line: 6, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !28)
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 1, scope: !18, type: !6)
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 2, scope: !18, type: !6)
// CHECK:STDOUT: !25 = !DILocation(line: 6, column: 51, scope: !18)
// CHECK:STDOUT: !27 = !DILocation(line: 6, column: 44, scope: !18)
// CHECK:STDOUT: !28 = !{!19, !20}
// CHECK:STDOUT: !29 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload1.Main", scope: null, file: !4, line: 7, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !35)
// CHECK:STDOUT: !30 = !DILocalVariable(arg: 1, scope: !29, type: !9)
// CHECK:STDOUT: !34 = !DILocation(line: 7, column: 40, scope: !29)
// CHECK:STDOUT: !35 = !{!30}
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "F__carbon_thunk", linkageName: "_CF__carbon_thunk:overload0.Main", scope: null, file: !4, line: 6, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !41)
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !36, type: !6)
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 2, scope: !36, type: !6)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 3, scope: !36, type: !6)
// CHECK:STDOUT: !40 = !DILocation(line: 6, column: 1, scope: !36)
// CHECK:STDOUT: !41 = !{!37, !38, !39}
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "F__carbon_thunk", linkageName: "_CF__carbon_thunk:overload1.Main", scope: null, file: !4, line: 7, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !46)
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !42, type: !9)
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 2, scope: !42, type: !6)
// CHECK:STDOUT: !45 = !DILocation(line: 7, column: 1, scope: !42)
// CHECK:STDOUT: !46 = !{!43, !44}
// CHECK:STDOUT: !47 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !4, line: 13, type: !17, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !50 = !DILocation(line: 13, column: 26, scope: !47)
// CHECK:STDOUT: !51 = !DILocation(line: 13, column: 33, scope: !47)
// CHECK:STDOUT: !52 = !DILocation(line: 13, column: 19, scope: !47)
// CHECK:STDOUT: !53 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !54 = !{!"omnipotent char", !53, i64 0}
// CHECK:STDOUT: !55 = !{!"bool", !54, i64 0}
// CHECK:STDOUT: !56 = !{!55, !55, i64 0}
// CHECK:STDOUT: !57 = !{!"int", !54, i64 0}
// CHECK:STDOUT: !58 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !59 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !60 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !61 = !{!"__libc_errno", !57, i64 0}
// CHECK:STDOUT: !62 = !{!61, !57, i64 0}
// CHECK:STDOUT:

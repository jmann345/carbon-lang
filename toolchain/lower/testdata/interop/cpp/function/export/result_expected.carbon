// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/function/export/result_expected.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/function/export/result_expected.carbon

// An exported `Core.Result(i32, i32)`-returning function, lowered
// (docs/design/error_handling.md, "Exporting fallible Carbon functions";
// fork/eh/plan.md §1.B.5-1.B.6, §4.B): the C++-side thunk `Carbon::F`
// declares `return_storage` of the skeleton type `Carbon::expected<int, int>`,
// passes it by reference to the Carbon thunk — whose `ref` return parameter
// writes the Carbon `Result` object into it — and returns it by value. The
// skeleton mirrors the choice layout (a discriminant byte, then the payload
// union at the payload alignment), so no conversion runs at the boundary.

// --- result_expected.carbon

library "[[@TEST_NAME]]";

import Cpp;

fn F(n: i32) -> Core.Result(i32, i32) {
  if (n < 0) { return Core.Result(i32, i32).Err(n); }
  return Core.Result(i32, i32).Ok(n);
}

inline Cpp '''
namespace Carbon {
template <typename T, typename E>
struct expected {
  unsigned char disc;
  union {
    T ok;
    E err;
  };
};
}  // namespace Carbon

inline int Use(int n) {
  Carbon::expected<int, int> r = Carbon::F(n);
  return r.disc == 0 ? r.ok : r.err;
}
''';

fn G(n: i32) -> i32 { return Cpp.Use(n); }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'result_expected.carbon'
// CHECK:STDOUT: source_filename = "result_expected.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %"struct.Carbon::expected" = type { i8, %union.anon }
// CHECK:STDOUT: %union.anon = type { i32 }
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z3Usei = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @Result.val.d4e.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @Result.val.ad4.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @.str = private unnamed_addr constant [70 x i8] c"carbon: C++ exception escaped into Carbon through `Use`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CF.Main(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %n) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.call = icmp slt i32 %n, 0, !dbg !19
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Less.call, label %if.then, label %if.else, !dbg !20
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CErr.Result.Core.8122a03446648385(ptr %return, i32 %n), !dbg !21
// CHECK:STDOUT:   ret void, !dbg !22
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_COk.Result.Core.8122a03446648385(ptr %return, i32 %n), !dbg !23
// CHECK:STDOUT:   ret void, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CF__carbon_thunk.Main(ptr %_, ptr %_1) #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_39.2 = load i32, ptr %_, align 4, !dbg !31
// CHECK:STDOUT:   call void @_CF.Main(ptr %_1, i32 %.loc6_39.2), !dbg !31
// CHECK:STDOUT:   ret void, !dbg !31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CG.Main(i32 %n) #0 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Use__carbon_thunk.call = call i32 @_Z3Usei.carbon_thunk._(i32 %n), !dbg !37
// CHECK:STDOUT:   ret i32 %Use__carbon_thunk.call, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_Z3Usei.carbon_thunk._(i32 noundef %n) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %n.addr = alloca i32, align 4
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store i32 %n, ptr %n.addr, align 4, !tbaa !39
// CHECK:STDOUT:   %0 = load i32, ptr %n.addr, align 4, !tbaa !39
// CHECK:STDOUT:   %call = invoke noundef i32 @_Z3Usei(i32 noundef %0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %1 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %2 = extractvalue { ptr, i32 } %1, 0
// CHECK:STDOUT:   store ptr %2, ptr %exn.slot, align 8
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %1, 1
// CHECK:STDOUT:   store i32 %3, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 69) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %6) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CErr.Result.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !40 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !44
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !44
// CHECK:STDOUT:   %Err = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !44
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !44
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Result.val.d4e.anon, i64 8, i1 false), !dbg !44
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Err, align 4, !dbg !44
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Err, i32 0, i32 0, !dbg !44
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !44
// CHECK:STDOUT:   ret void, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_COk.Result.Core.8122a03446648385(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !45 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !48
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !48
// CHECK:STDOUT:   %Ok = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !48
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !49
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Result.val.ad4.anon, i64 8, i1 false), !dbg !48
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Ok, align 4, !dbg !48
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Ok, i32 0, i32 0, !dbg !49
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !49
// CHECK:STDOUT:   ret void, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: inlinehint mustprogress uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef i32 @_Z3Usei(i32 noundef %n) #3 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %n.addr = alloca i32, align 4
// CHECK:STDOUT:   %r = alloca %"struct.Carbon::expected", align 4
// CHECK:STDOUT:   store i32 %n, ptr %n.addr, align 4, !tbaa !39
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %r) #0
// CHECK:STDOUT:   %0 = load i32, ptr %n.addr, align 4, !tbaa !39
// CHECK:STDOUT:   %call = call i64 @_ZN6CarbonL1FEi(i32 noundef %0)
// CHECK:STDOUT:   store i64 %call, ptr %r, align 4
// CHECK:STDOUT:   %disc = getelementptr inbounds nuw %"struct.Carbon::expected", ptr %r, i32 0, i32 0
// CHECK:STDOUT:   %1 = load i8, ptr %disc, align 4, !tbaa !50
// CHECK:STDOUT:   %conv = zext i8 %1 to i32
// CHECK:STDOUT:   %cmp = icmp eq i32 %conv, 0
// CHECK:STDOUT:   br i1 %cmp, label %cond.true, label %cond.false
// CHECK:STDOUT:
// CHECK:STDOUT: cond.true:                                        ; preds = %entry
// CHECK:STDOUT:   %2 = getelementptr inbounds nuw %"struct.Carbon::expected", ptr %r, i32 0, i32 1
// CHECK:STDOUT:   %3 = load i32, ptr %2, align 4, !tbaa !52
// CHECK:STDOUT:   br label %cond.end
// CHECK:STDOUT:
// CHECK:STDOUT: cond.false:                                       ; preds = %entry
// CHECK:STDOUT:   %4 = getelementptr inbounds nuw %"struct.Carbon::expected", ptr %r, i32 0, i32 1
// CHECK:STDOUT:   %5 = load i32, ptr %4, align 4, !tbaa !52
// CHECK:STDOUT:   br label %cond.end
// CHECK:STDOUT:
// CHECK:STDOUT: cond.end:                                         ; preds = %cond.false, %cond.true
// CHECK:STDOUT:   %cond = phi i32 [ %3, %cond.true ], [ %5, %cond.false ]
// CHECK:STDOUT:   call void @llvm.lifetime.end.p0(ptr %r) #0
// CHECK:STDOUT:   ret i32 %cond
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
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal i64 @_ZN6CarbonL1FEi(i32 noundef %0) #1 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca %"struct.Carbon::expected", align 4
// CHECK:STDOUT:   %.addr = alloca i32, align 4
// CHECK:STDOUT:   store i32 %0, ptr %.addr, align 4, !tbaa !39
// CHECK:STDOUT:   call void @_CF__carbon_thunk.Main(ptr noundef nonnull align 4 dereferenceable(4) %.addr, ptr noundef nonnull align 4 dereferenceable(8) %retval)
// CHECK:STDOUT:   %1 = load i64, ptr %retval, align 4
// CHECK:STDOUT:   ret i64 %1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.end.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { inlinehint mustprogress uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3, !4, !5, !6}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!7}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "result_expected.carbon", directory: "")
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
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !1, line: 6, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !17)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{!15, !16}
// CHECK:STDOUT: !15 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !17 = !{!18}
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !12, type: !16)
// CHECK:STDOUT: !19 = !DILocation(line: 7, column: 7, scope: !12)
// CHECK:STDOUT: !20 = !DILocation(line: 7, column: 6, scope: !12)
// CHECK:STDOUT: !21 = !DILocation(line: 7, column: 23, scope: !12)
// CHECK:STDOUT: !22 = !DILocation(line: 7, column: 16, scope: !12)
// CHECK:STDOUT: !23 = !DILocation(line: 8, column: 10, scope: !12)
// CHECK:STDOUT: !24 = !DILocation(line: 8, column: 3, scope: !12)
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "F__carbon_thunk", linkageName: "_CF__carbon_thunk.Main", scope: null, file: !1, line: 6, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !28)
// CHECK:STDOUT: !26 = !DISubroutineType(types: !27)
// CHECK:STDOUT: !27 = !{null, !16, !15}
// CHECK:STDOUT: !28 = !{!29, !30}
// CHECK:STDOUT: !29 = !DILocalVariable(arg: 1, scope: !25, type: !16)
// CHECK:STDOUT: !30 = !DILocalVariable(arg: 2, scope: !25, type: !15)
// CHECK:STDOUT: !31 = !DILocation(line: 6, column: 1, scope: !25)
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main", scope: null, file: !1, line: 29, type: !33, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !35)
// CHECK:STDOUT: !33 = !DISubroutineType(types: !34)
// CHECK:STDOUT: !34 = !{!16, !16}
// CHECK:STDOUT: !35 = !{!36}
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !32, type: !16)
// CHECK:STDOUT: !37 = !DILocation(line: 29, column: 30, scope: !32)
// CHECK:STDOUT: !38 = !DILocation(line: 29, column: 23, scope: !32)
// CHECK:STDOUT: !39 = !{!9, !9, i64 0}
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "Err", linkageName: "_CErr.Result.Core.8122a03446648385", scope: null, file: !41, line: 28, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !42)
// CHECK:STDOUT: !41 = !DIFile(filename: "{{.*}}/prelude/types/result.carbon", directory: "")
// CHECK:STDOUT: !42 = !{!43}
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !40, type: !16)
// CHECK:STDOUT: !44 = !DILocation(line: 28, column: 1, scope: !40)
// CHECK:STDOUT: !45 = distinct !DISubprogram(name: "Ok", linkageName: "_COk.Result.Core.8122a03446648385", scope: null, file: !41, line: 28, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !46)
// CHECK:STDOUT: !46 = !{!47}
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !45, type: !16)
// CHECK:STDOUT: !48 = !DILocation(line: 28, column: 1, scope: !45)
// CHECK:STDOUT: !49 = !DILocation(line: 29, column: 15, scope: !45)
// CHECK:STDOUT: !50 = !{!51, !10, i64 0}
// CHECK:STDOUT: !51 = !{!"_ZTSN6Carbon8expectedIiiEE", !10, i64 0, !10, i64 4}
// CHECK:STDOUT: !52 = !{!10, !10, i64 0}
// CHECK:STDOUT:

// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/function/import/method_ptr.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/function/import/method_ptr.carbon

// --- method_ptr.h

class C {
 public:
  void Method(int i) const;
};
using MethodPtrType = void(C::*)() const;

auto GetMethodPtr() -> MethodPtrType;
void TakeMethodPtr(MethodPtrType);

template <typename C>
void TakeGenericMethodPtr(void(C::* ptr)() const);

// --- relay_method_ptr.carbon
library "[[@TEST_NAME]]";

import Cpp library "method_ptr.h";

fn G() {
  Cpp.TakeMethodPtr(Cpp.GetMethodPtr());
}

// --- convert_method_ptr.carbon
library "[[@TEST_NAME]]";

import Cpp;

class C {
  fn Method(self);
}

inline Cpp '''c++
using MethodPtrType = void(Carbon::C::*)() const;
''';

fn G() {
  var unused ptr: Cpp.MethodPtrType = C.Method;
}

// --- pass_method_ptr.carbon
library "[[@TEST_NAME]]";

import Cpp library "method_ptr.h";

class C {
  fn Method(self);
}

fn F() {
  Cpp.TakeGenericMethodPtr(C.Method);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'relay_method_ptr.carbon'
// CHECK:STDOUT: source_filename = "relay_method_ptr.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [79 x i8] c"carbon: C++ exception escaped into Carbon through `GetMethodPtr`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [80 x i8] c"carbon: C++ exception escaped into Carbon through `TakeMethodPtr`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CG.Main() #0 !dbg !11 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6_38.1.temp = alloca ptr, align 8, !dbg !12
// CHECK:STDOUT:   %.loc6_38.5.temp = alloca ptr, align 8, !dbg !12
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc6_38.1.temp), !dbg !12
// CHECK:STDOUT:   call void @_Z12GetMethodPtrv.carbon_thunk.(ptr %.loc6_38.1.temp), !dbg !12
// CHECK:STDOUT:   %.loc6_38.4 = load ptr, ptr %.loc6_38.1.temp, align 8, !dbg !12
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc6_38.5.temp), !dbg !12
// CHECK:STDOUT:   store ptr %.loc6_38.4, ptr %.loc6_38.5.temp, align 8, !dbg !12
// CHECK:STDOUT:   call void @_Z13TakeMethodPtrM1CKFvvE.carbon_thunk._(ptr %.loc6_38.5.temp), !dbg !13
// CHECK:STDOUT:   call void @"_CSelfDestruct.659d177172b60c17:core.Destroy.Core"(ptr %.loc6_38.5.temp), !dbg !12
// CHECK:STDOUT:   call void @"_CSelfDestruct.659d177172b60c17:core.Destroy.Core"(ptr %.loc6_38.1.temp), !dbg !12
// CHECK:STDOUT:   ret void, !dbg !14
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z12GetMethodPtrv.carbon_thunk.(ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !22
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !22
// CHECK:STDOUT:   %call = invoke { i64, i64 } @_Z12GetMethodPtrv()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   store { i64, i64 } %call, ptr %0, align 8, !tbaa !23
// CHECK:STDOUT:   br label %try.cont
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 78) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
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
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z13TakeMethodPtrM1CKFvvE.carbon_thunk._(ptr noundef %0) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %coerce = alloca { i64, i64 }, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !22
// CHECK:STDOUT:   %1 = load ptr, ptr %.addr, align 8, !tbaa !22
// CHECK:STDOUT:   %2 = load { i64, i64 }, ptr %1, align 8, !tbaa !23
// CHECK:STDOUT:   store { i64, i64 } %2, ptr %coerce, align 8, !tbaa !23
// CHECK:STDOUT:   %3 = getelementptr inbounds nuw { i64, i64 }, ptr %coerce, i32 0, i32 0
// CHECK:STDOUT:   %4 = load i64, ptr %3, align 8
// CHECK:STDOUT:   %5 = getelementptr inbounds nuw { i64, i64 }, ptr %coerce, i32 0, i32 1
// CHECK:STDOUT:   %6 = load i64, ptr %5, align 8
// CHECK:STDOUT:   invoke void @_Z13TakeMethodPtrM1CKFvvE(i64 %4, i64 %6)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %7 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %8 = extractvalue { ptr, i32 } %7, 0
// CHECK:STDOUT:   store ptr %8, ptr %exn.slot, align 8
// CHECK:STDOUT:   %9 = extractvalue { ptr, i32 } %7, 1
// CHECK:STDOUT:   store i32 %9, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %10 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.1, i64 noundef 79) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %11 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %12 = extractvalue { ptr, i32 } %11, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %12) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.659d177172b60c17:core.Destroy.Core"(ptr %self) #0 !dbg !15 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: declare { i64, i64 } @_Z12GetMethodPtrv() #3
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
// CHECK:STDOUT: declare void @_Z13TakeMethodPtrM1CKFvvE(i64, i64) #3
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.659d177172b60c17:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_begin_catch, { 1, 2, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_rethrow, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!24, !25, !26, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!29}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "relay_method_ptr.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !{null}
// CHECK:STDOUT: !7 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{null, !8}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main", scope: null, file: !4, line: 5, type: !7, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !12 = !DILocation(line: 6, column: 21, scope: !11)
// CHECK:STDOUT: !13 = !DILocation(line: 6, column: 3, scope: !11)
// CHECK:STDOUT: !14 = !DILocation(line: 5, column: 1, scope: !11)
// CHECK:STDOUT: !15 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.659d177172b60c17:core.Destroy.Core", scope: null, file: !4, line: 6, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !18)
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 1, scope: !15, type: !8)
// CHECK:STDOUT: !17 = !DILocation(line: 6, column: 21, scope: !15)
// CHECK:STDOUT: !18 = !{!16}
// CHECK:STDOUT: !19 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !20 = !{!"omnipotent char", !19, i64 0}
// CHECK:STDOUT: !21 = !{!"any pointer", !20, i64 0}
// CHECK:STDOUT: !22 = !{!21, !21, i64 0}
// CHECK:STDOUT: !23 = !{!20, !20, i64 0}
// CHECK:STDOUT: !24 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !25 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !26 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !27 = !{!"int", !20, i64 0}
// CHECK:STDOUT: !28 = !{!"__libc_errno", !27, i64 0}
// CHECK:STDOUT: !29 = !{!28, !27, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'convert_method_ptr.carbon'
// CHECK:STDOUT: source_filename = "convert_method_ptr.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CMethod.C.Main(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CG.Main() #0 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %ptr.var = alloca ptr, align 8, !dbg !33
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %ptr.var), !dbg !33
// CHECK:STDOUT:   store ptr @_CMethod.C.Main, ptr %ptr.var, align 8, !dbg !33
// CHECK:STDOUT:   call void @"_CSelfDestruct.659d177172b60c17:core.Destroy.Core"(ptr %ptr.var), !dbg !33
// CHECK:STDOUT:   ret void, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMethod__carbon_thunk.C.Main(ptr %self) #0 !dbg !36 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CMethod.C.Main(ptr %self), !dbg !39
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.659d177172b60c17:core.Destroy.Core"(ptr %self) #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!31}
// CHECK:STDOUT: !llvm.module.flags = !{!24, !25, !26, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!29}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !{null}
// CHECK:STDOUT: !7 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{null, !8}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !19 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !20 = !{!"omnipotent char", !19, i64 0}
// CHECK:STDOUT: !24 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !25 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !26 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !27 = !{!"int", !20, i64 0}
// CHECK:STDOUT: !28 = !{!"__libc_errno", !27, i64 0}
// CHECK:STDOUT: !29 = !{!28, !27, i64 0}
// CHECK:STDOUT: !30 = !DIFile(filename: "convert_method_ptr.carbon", directory: "")
// CHECK:STDOUT: !31 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !30, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main", scope: null, file: !30, line: 13, type: !7, spFlags: DISPFlagDefinition, unit: !31)
// CHECK:STDOUT: !33 = !DILocation(line: 14, column: 3, scope: !32)
// CHECK:STDOUT: !35 = !DILocation(line: 13, column: 1, scope: !32)
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "Method__carbon_thunk", linkageName: "_CMethod__carbon_thunk.C.Main", scope: null, file: !30, line: 14, type: !10, spFlags: DISPFlagDefinition, unit: !31, retainedNodes: !40)
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !36, type: !8)
// CHECK:STDOUT: !39 = !DILocation(line: 6, column: 3, scope: !36)
// CHECK:STDOUT: !40 = !{!37}
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.659d177172b60c17:core.Destroy.Core", scope: null, file: !30, line: 14, type: !10, spFlags: DISPFlagDefinition, unit: !31, retainedNodes: !44)
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !41, type: !8)
// CHECK:STDOUT: !43 = !DILocation(line: 14, column: 3, scope: !41)
// CHECK:STDOUT: !44 = !{!42}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'pass_method_ptr.carbon'
// CHECK:STDOUT: source_filename = "pass_method_ptr.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.b35 = internal constant ptr @_CMethod.C.Main
// CHECK:STDOUT: @.str = private unnamed_addr constant [87 x i8] c"carbon: C++ exception escaped into Carbon through `TakeGenericMethodPtr`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CMethod.C.Main(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CF.Main() #0 !dbg !47 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_29.3.temp = alloca ptr, align 8, !dbg !48
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc10_29.3.temp), !dbg !48
// CHECK:STDOUT:   call void @_Z20TakeGenericMethodPtrIN6Carbon1CEEvMT_KFvvE.carbon_thunk._(ptr @.b35), !dbg !49
// CHECK:STDOUT:   call void @"_CSelfDestruct.659d177172b60c17:core.Destroy.Core"(ptr @.b35), !dbg !48
// CHECK:STDOUT:   ret void, !dbg !50
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMethod__carbon_thunk.C.Main(ptr %self) #0 !dbg !51 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CMethod.C.Main(ptr %self), !dbg !53
// CHECK:STDOUT:   ret void, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z20TakeGenericMethodPtrIN6Carbon1CEEvMT_KFvvE.carbon_thunk._(ptr noundef %ptr) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %ptr.addr = alloca ptr, align 8
// CHECK:STDOUT:   %coerce = alloca { i64, i64 }, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %ptr, ptr %ptr.addr, align 8, !tbaa !22
// CHECK:STDOUT:   %0 = load ptr, ptr %ptr.addr, align 8, !tbaa !22
// CHECK:STDOUT:   %1 = load { i64, i64 }, ptr %0, align 8, !tbaa !23
// CHECK:STDOUT:   store { i64, i64 } %1, ptr %coerce, align 8, !tbaa !23
// CHECK:STDOUT:   %2 = getelementptr inbounds nuw { i64, i64 }, ptr %coerce, i32 0, i32 0
// CHECK:STDOUT:   %3 = load i64, ptr %2, align 8
// CHECK:STDOUT:   %4 = getelementptr inbounds nuw { i64, i64 }, ptr %coerce, i32 0, i32 1
// CHECK:STDOUT:   %5 = load i64, ptr %4, align 8
// CHECK:STDOUT:   invoke void @_Z20TakeGenericMethodPtrIN6Carbon1CEEvMT_KFvvE(i64 %3, i64 %5)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   store ptr %7, ptr %exn.slot, align 8
// CHECK:STDOUT:   %8 = extractvalue { ptr, i32 } %6, 1
// CHECK:STDOUT:   store i32 %8, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %9 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 86) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %10 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %11 = extractvalue { ptr, i32 } %10, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %11) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.659d177172b60c17:core.Destroy.Core"(ptr %self) #0 !dbg !55 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_Z20TakeGenericMethodPtrIN6Carbon1CEEvMT_KFvvE(i64, i64) #3
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
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!46}
// CHECK:STDOUT: !llvm.module.flags = !{!24, !25, !26, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!29}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !{null}
// CHECK:STDOUT: !7 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{null, !8}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !19 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !20 = !{!"omnipotent char", !19, i64 0}
// CHECK:STDOUT: !21 = !{!"any pointer", !20, i64 0}
// CHECK:STDOUT: !22 = !{!21, !21, i64 0}
// CHECK:STDOUT: !23 = !{!20, !20, i64 0}
// CHECK:STDOUT: !24 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !25 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !26 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !27 = !{!"int", !20, i64 0}
// CHECK:STDOUT: !28 = !{!"__libc_errno", !27, i64 0}
// CHECK:STDOUT: !29 = !{!28, !27, i64 0}
// CHECK:STDOUT: !45 = !DIFile(filename: "pass_method_ptr.carbon", directory: "")
// CHECK:STDOUT: !46 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !45, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !47 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !45, line: 9, type: !7, spFlags: DISPFlagDefinition, unit: !46)
// CHECK:STDOUT: !48 = !DILocation(line: 10, column: 28, scope: !47)
// CHECK:STDOUT: !49 = !DILocation(line: 10, column: 3, scope: !47)
// CHECK:STDOUT: !50 = !DILocation(line: 9, column: 1, scope: !47)
// CHECK:STDOUT: !51 = distinct !DISubprogram(name: "Method__carbon_thunk", linkageName: "_CMethod__carbon_thunk.C.Main", scope: null, file: !45, line: 6, type: !10, spFlags: DISPFlagDefinition, unit: !46, retainedNodes: !54)
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !51, type: !8)
// CHECK:STDOUT: !53 = !DILocation(line: 6, column: 3, scope: !51)
// CHECK:STDOUT: !54 = !{!52}
// CHECK:STDOUT: !55 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.659d177172b60c17:core.Destroy.Core", scope: null, file: !45, line: 10, type: !10, spFlags: DISPFlagDefinition, unit: !46, retainedNodes: !58)
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !55, type: !8)
// CHECK:STDOUT: !57 = !DILocation(line: 10, column: 28, scope: !55)
// CHECK:STDOUT: !58 = !{!56}
// CHECK:STDOUT:

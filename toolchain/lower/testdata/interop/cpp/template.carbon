// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/template.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/template.carbon

// --- function_template.h

template<typename T> T identity(T x) { return x; }

class Class {};

// --- call.carbon

library "[[@TEST_NAME]]";

import Cpp library "function_template.h";

fn PassI32(a: i32) -> i32 {
  return Cpp.identity(a);
}

fn PassI32Explicitly(a: i32) -> i32 {
  return Cpp.identity(i32, a);
}

fn PassClass(a: Cpp.Class) -> Cpp.Class {
  return Cpp.identity(a);
}

// --- variadic.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
template<typename ...T>
auto foo(int, T...) -> void;
''';

fn Call1() {
  //@dump-sem-ir-begin
  Cpp.foo(1);
  //@dump-sem-ir-end
}

fn Call2() {
  //@dump-sem-ir-begin
  Cpp.foo(1, 2);
  //@dump-sem-ir-end
}

fn Call3() {
  //@dump-sem-ir-begin
  Cpp.foo(1, 2, 3);
  //@dump-sem-ir-end
}

// --- variadic_thunk.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
class X {};
template<typename ...T>
auto foo(X, T...) -> void;
''';

fn Call1() {
  //@dump-sem-ir-begin
  Cpp.foo({} as Cpp.X);
  //@dump-sem-ir-end
}

fn Call2() {
  //@dump-sem-ir-begin
  Cpp.foo({} as Cpp.X, 2);
  //@dump-sem-ir-end
}

fn Call3() {
  //@dump-sem-ir-begin
  Cpp.foo({} as Cpp.X, 2, 3);
  //@dump-sem-ir-end
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'call.carbon'
// CHECK:STDOUT: source_filename = "call.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %class.Class = type { i8 }
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z8identityIiET_S0_ = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z8identityI5ClassET_S1_ = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [75 x i8] c"carbon: C++ exception escaped into Carbon through `identity`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CPassI32.Main(i32 %a) #0 !dbg !28 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %identity__carbon_thunk.call = call i32 @_Z8identityIiET_S0_.carbon_thunk._(i32 %a), !dbg !34
// CHECK:STDOUT:   ret i32 %identity__carbon_thunk.call, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_Z8identityIiET_S0_.carbon_thunk._(i32 noundef %x) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.addr = alloca i32, align 4
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store i32 %x, ptr %x.addr, align 4, !tbaa !58
// CHECK:STDOUT:   %0 = load i32, ptr %x.addr, align 4, !tbaa !58
// CHECK:STDOUT:   %call = invoke noundef i32 @_Z8identityIiET_S0_(i32 noundef %0)
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 74) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #5
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %6) #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CPassI32Explicitly.Main(i32 %a) #0 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %identity__carbon_thunk.call = call i32 @_Z8identityIiET_S0_.carbon_thunk._(i32 %a), !dbg !43
// CHECK:STDOUT:   ret i32 %identity__carbon_thunk.call, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CPassClass.Main(ptr sret({}) %return, ptr %a) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_Z8identityI5ClassET_S1_.carbon_thunk._(ptr %a, ptr %return), !dbg !52
// CHECK:STDOUT:   ret void, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z8identityI5ClassET_S1_.carbon_thunk._(ptr noundef %x, ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.addr = alloca ptr, align 8
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %agg.tmp = alloca %class.Class, align 1
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   %undef.agg.tmp = alloca %class.Class, align 1
// CHECK:STDOUT:   store ptr %x, ptr %x.addr, align 8, !tbaa !61
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !61
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !61
// CHECK:STDOUT:   %1 = load ptr, ptr %x.addr, align 8, !tbaa !61
// CHECK:STDOUT:   invoke void @_Z8identityI5ClassET_S1_()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %2 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %2, 0
// CHECK:STDOUT:   store ptr %3, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %2, 1
// CHECK:STDOUT:   store i32 %4, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 74) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #5
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %7) #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef i32 @_Z8identityIiET_S0_(i32 noundef %x) #2 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x.addr = alloca i32, align 4
// CHECK:STDOUT:   store i32 %x, ptr %x.addr, align 4, !tbaa !58
// CHECK:STDOUT:   %0 = load i32, ptr %x.addr, align 4, !tbaa !58
// CHECK:STDOUT:   ret i32 %0
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
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local void @_Z8identityI5ClassET_S1_() #2 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %x = alloca %class.Class, align 1
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_begin_catch, { 1, 2, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_rethrow, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #3 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noreturn }
// CHECK:STDOUT: attributes #6 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!19}
// CHECK:STDOUT: !llvm.module.flags = !{!63, !64, !65, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!67}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !18 = !DIFile(filename: "call.carbon", directory: "")
// CHECK:STDOUT: !19 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !18, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20, !20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !23 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !24 = !{!23, !23}
// CHECK:STDOUT: !25 = !DISubroutineType(types: !24)
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "PassI32", linkageName: "_CPassI32.Main", scope: null, file: !18, line: 6, type: !22, spFlags: DISPFlagDefinition, unit: !19, retainedNodes: !36)
// CHECK:STDOUT: !29 = !DILocalVariable(arg: 1, scope: !28, type: !20)
// CHECK:STDOUT: !34 = !DILocation(line: 7, column: 10, scope: !28)
// CHECK:STDOUT: !35 = !DILocation(line: 7, column: 3, scope: !28)
// CHECK:STDOUT: !36 = !{!29}
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "PassI32Explicitly", linkageName: "_CPassI32Explicitly.Main", scope: null, file: !18, line: 10, type: !22, spFlags: DISPFlagDefinition, unit: !19, retainedNodes: !45)
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !37, type: !20)
// CHECK:STDOUT: !43 = !DILocation(line: 11, column: 10, scope: !37)
// CHECK:STDOUT: !44 = !DILocation(line: 11, column: 3, scope: !37)
// CHECK:STDOUT: !45 = !{!38}
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "PassClass", linkageName: "_CPassClass.Main", scope: null, file: !18, line: 14, type: !25, spFlags: DISPFlagDefinition, unit: !19, retainedNodes: !54)
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !46, type: !23)
// CHECK:STDOUT: !52 = !DILocation(line: 15, column: 10, scope: !46)
// CHECK:STDOUT: !53 = !DILocation(line: 15, column: 3, scope: !46)
// CHECK:STDOUT: !54 = !{!47}
// CHECK:STDOUT: !55 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !56 = !{!"omnipotent char", !55, i64 0}
// CHECK:STDOUT: !57 = !{!"int", !56, i64 0}
// CHECK:STDOUT: !58 = !{!57, !57, i64 0}
// CHECK:STDOUT: !59 = !{!"any pointer", !56, i64 0}
// CHECK:STDOUT: !60 = !{!"p1 _ZTS5Class", !59, i64 0}
// CHECK:STDOUT: !61 = !{!60, !60, i64 0}
// CHECK:STDOUT: !63 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !64 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !65 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !66 = !{!"__libc_errno", !57, i64 0}
// CHECK:STDOUT: !67 = !{!66, !57, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'variadic.carbon'
// CHECK:STDOUT: source_filename = "variadic.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [70 x i8] c"carbon: C++ exception escaped into Carbon through `foo`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall1.Main() #0 !dbg !78 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_Z3fooIJEEviDpT_.carbon_thunk._(i32 1), !dbg !79
// CHECK:STDOUT:   ret void, !dbg !80
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z3fooIJEEviDpT_.carbon_thunk._(i32 noundef %0) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca i32, align 4
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store i32 %0, ptr %.addr, align 4, !tbaa !58
// CHECK:STDOUT:   %1 = load i32, ptr %.addr, align 4, !tbaa !58
// CHECK:STDOUT:   invoke void @_Z3fooIJEEviDpT_(i32 noundef %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %2 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %2, 0
// CHECK:STDOUT:   store ptr %3, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %2, 1
// CHECK:STDOUT:   store i32 %4, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 69) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #5
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %7) #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall2.Main() #0 !dbg !81 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_Z3fooIJiEEviDpT_.carbon_thunk.__(i32 1, i32 2), !dbg !82
// CHECK:STDOUT:   ret void, !dbg !83
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z3fooIJiEEviDpT_.carbon_thunk.__(i32 noundef %0, i32 noundef %1) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca i32, align 4
// CHECK:STDOUT:   %.addr1 = alloca i32, align 4
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store i32 %0, ptr %.addr, align 4, !tbaa !58
// CHECK:STDOUT:   store i32 %1, ptr %.addr1, align 4, !tbaa !58
// CHECK:STDOUT:   %2 = load i32, ptr %.addr, align 4, !tbaa !58
// CHECK:STDOUT:   %3 = load i32, ptr %.addr1, align 4, !tbaa !58
// CHECK:STDOUT:   invoke void @_Z3fooIJiEEviDpT_(i32 noundef %2, i32 noundef %3)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %4 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %4, 0
// CHECK:STDOUT:   store ptr %5, ptr %exn.slot, align 8
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %4, 1
// CHECK:STDOUT:   store i32 %6, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %7 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 69) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #5
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %8 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %9 = extractvalue { ptr, i32 } %8, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %9) #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall3.Main() #0 !dbg !84 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_Z3fooIJiiEEviDpT_.carbon_thunk.___(i32 1, i32 2, i32 3), !dbg !85
// CHECK:STDOUT:   ret void, !dbg !86
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z3fooIJiiEEviDpT_.carbon_thunk.___(i32 noundef %0, i32 noundef %1, i32 noundef %2) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca i32, align 4
// CHECK:STDOUT:   %.addr1 = alloca i32, align 4
// CHECK:STDOUT:   %.addr2 = alloca i32, align 4
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store i32 %0, ptr %.addr, align 4, !tbaa !58
// CHECK:STDOUT:   store i32 %1, ptr %.addr1, align 4, !tbaa !58
// CHECK:STDOUT:   store i32 %2, ptr %.addr2, align 4, !tbaa !58
// CHECK:STDOUT:   %3 = load i32, ptr %.addr, align 4, !tbaa !58
// CHECK:STDOUT:   %4 = load i32, ptr %.addr1, align 4, !tbaa !58
// CHECK:STDOUT:   %5 = load i32, ptr %.addr2, align 4, !tbaa !58
// CHECK:STDOUT:   invoke void @_Z3fooIJiiEEviDpT_(i32 noundef %3, i32 noundef %4, i32 noundef %5)
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
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 69) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #5
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %10 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %11 = extractvalue { ptr, i32 } %10, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %11) #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_Z3fooIJEEviDpT_(i32 noundef) #2
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
// CHECK:STDOUT: declare void @_Z3fooIJiEEviDpT_(i32 noundef, i32 noundef) #2
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_Z3fooIJiiEEviDpT_(i32 noundef, i32 noundef, i32 noundef) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_begin_catch, { 2, 3, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_rethrow, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #3 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noreturn }
// CHECK:STDOUT: attributes #6 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!69}
// CHECK:STDOUT: !llvm.module.flags = !{!63, !64, !65, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!67}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !55 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !56 = !{!"omnipotent char", !55, i64 0}
// CHECK:STDOUT: !57 = !{!"int", !56, i64 0}
// CHECK:STDOUT: !58 = !{!57, !57, i64 0}
// CHECK:STDOUT: !63 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !64 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !65 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !66 = !{!"__libc_errno", !57, i64 0}
// CHECK:STDOUT: !67 = !{!66, !57, i64 0}
// CHECK:STDOUT: !68 = !DIFile(filename: "variadic.carbon", directory: "")
// CHECK:STDOUT: !69 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !68, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !70 = !{null}
// CHECK:STDOUT: !71 = !DISubroutineType(types: !70)
// CHECK:STDOUT: !78 = distinct !DISubprogram(name: "Call1", linkageName: "_CCall1.Main", scope: null, file: !68, line: 9, type: !71, spFlags: DISPFlagDefinition, unit: !69)
// CHECK:STDOUT: !79 = !DILocation(line: 11, column: 3, scope: !78)
// CHECK:STDOUT: !80 = !DILocation(line: 9, column: 1, scope: !78)
// CHECK:STDOUT: !81 = distinct !DISubprogram(name: "Call2", linkageName: "_CCall2.Main", scope: null, file: !68, line: 15, type: !71, spFlags: DISPFlagDefinition, unit: !69)
// CHECK:STDOUT: !82 = !DILocation(line: 17, column: 3, scope: !81)
// CHECK:STDOUT: !83 = !DILocation(line: 15, column: 1, scope: !81)
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "Call3", linkageName: "_CCall3.Main", scope: null, file: !68, line: 21, type: !71, spFlags: DISPFlagDefinition, unit: !69)
// CHECK:STDOUT: !85 = !DILocation(line: 23, column: 3, scope: !84)
// CHECK:STDOUT: !86 = !DILocation(line: 21, column: 1, scope: !84)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'variadic_thunk.carbon'
// CHECK:STDOUT: source_filename = "variadic_thunk.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %class.X = type { i8 }
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @X.val = internal constant {} zeroinitializer
// CHECK:STDOUT: @X.val.loc12_14.3 = internal constant {} zeroinitializer
// CHECK:STDOUT: @.str = private unnamed_addr constant [70 x i8] c"carbon: C++ exception escaped into Carbon through `foo`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall1.Main() #0 !dbg !95 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12_12.2.temp = alloca {}, align 1, !dbg !96
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc12_12.2.temp), !dbg !96
// CHECK:STDOUT:   call void @_Z3fooIJEEv1XDpT_.carbon_thunk._(ptr @X.val.loc12_14.3), !dbg !97
// CHECK:STDOUT:   call void @"_CSelfDestruct.3d7b8a41b4c67e71:core.Destroy.Core"(ptr @X.val), !dbg !96
// CHECK:STDOUT:   ret void, !dbg !98
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z3fooIJEEv1XDpT_.carbon_thunk._(ptr noundef %0) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %agg.tmp = alloca %class.X, align 1
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !112
// CHECK:STDOUT:   %1 = load ptr, ptr %.addr, align 8, !tbaa !112
// CHECK:STDOUT:   invoke void @_Z3fooIJEEv1XDpT_()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %2 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %2, 0
// CHECK:STDOUT:   store ptr %3, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %2, 1
// CHECK:STDOUT:   store i32 %4, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 69) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %7) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.3d7b8a41b4c67e71:core.Destroy.Core"(ptr %self) #0 !dbg !99 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !101
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall2.Main() #0 !dbg !103 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc18_12.2.temp = alloca {}, align 1, !dbg !104
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc18_12.2.temp), !dbg !104
// CHECK:STDOUT:   call void @_Z3fooIJiEEv1XDpT_.carbon_thunk.__(ptr @X.val.loc12_14.3, i32 2), !dbg !105
// CHECK:STDOUT:   call void @"_CSelfDestruct.3d7b8a41b4c67e71:core.Destroy.Core"(ptr @X.val), !dbg !104
// CHECK:STDOUT:   ret void, !dbg !106
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z3fooIJiEEv1XDpT_.carbon_thunk.__(ptr noundef %0, i32 noundef %1) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %.addr1 = alloca i32, align 4
// CHECK:STDOUT:   %agg.tmp = alloca %class.X, align 1
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !112
// CHECK:STDOUT:   store i32 %1, ptr %.addr1, align 4, !tbaa !58
// CHECK:STDOUT:   %2 = load ptr, ptr %.addr, align 8, !tbaa !112
// CHECK:STDOUT:   %3 = load i32, ptr %.addr1, align 4, !tbaa !58
// CHECK:STDOUT:   invoke void @_Z3fooIJiEEv1XDpT_(i32 noundef %3)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %4 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %4, 0
// CHECK:STDOUT:   store ptr %5, ptr %exn.slot, align 8
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %4, 1
// CHECK:STDOUT:   store i32 %6, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %7 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 69) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %8 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %9 = extractvalue { ptr, i32 } %8, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %9) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall3.Main() #0 !dbg !107 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc24_12.2.temp = alloca {}, align 1, !dbg !108
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc24_12.2.temp), !dbg !108
// CHECK:STDOUT:   call void @_Z3fooIJiiEEv1XDpT_.carbon_thunk.___(ptr @X.val.loc12_14.3, i32 2, i32 3), !dbg !109
// CHECK:STDOUT:   call void @"_CSelfDestruct.3d7b8a41b4c67e71:core.Destroy.Core"(ptr @X.val), !dbg !108
// CHECK:STDOUT:   ret void, !dbg !110
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z3fooIJiiEEv1XDpT_.carbon_thunk.___(ptr noundef %0, i32 noundef %1, i32 noundef %2) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %.addr1 = alloca i32, align 4
// CHECK:STDOUT:   %.addr2 = alloca i32, align 4
// CHECK:STDOUT:   %agg.tmp = alloca %class.X, align 1
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !112
// CHECK:STDOUT:   store i32 %1, ptr %.addr1, align 4, !tbaa !58
// CHECK:STDOUT:   store i32 %2, ptr %.addr2, align 4, !tbaa !58
// CHECK:STDOUT:   %3 = load ptr, ptr %.addr, align 8, !tbaa !112
// CHECK:STDOUT:   %4 = load i32, ptr %.addr1, align 4, !tbaa !58
// CHECK:STDOUT:   %5 = load i32, ptr %.addr2, align 4, !tbaa !58
// CHECK:STDOUT:   invoke void @_Z3fooIJiiEEv1XDpT_(i32 noundef %4, i32 noundef %5)
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
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 69) #0
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
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_Z3fooIJEEv1XDpT_() #3
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
// CHECK:STDOUT: declare void @_Z3fooIJiEEv1XDpT_(i32 noundef) #3
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_Z3fooIJiiEEv1XDpT_(i32 noundef, i32 noundef) #3
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_begin_catch, { 2, 3, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_rethrow, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 2, 1, 0 }
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!88}
// CHECK:STDOUT: !llvm.module.flags = !{!63, !64, !65, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!67}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !23 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !55 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !56 = !{!"omnipotent char", !55, i64 0}
// CHECK:STDOUT: !57 = !{!"int", !56, i64 0}
// CHECK:STDOUT: !58 = !{!57, !57, i64 0}
// CHECK:STDOUT: !59 = !{!"any pointer", !56, i64 0}
// CHECK:STDOUT: !63 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !64 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !65 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !66 = !{!"__libc_errno", !57, i64 0}
// CHECK:STDOUT: !67 = !{!66, !57, i64 0}
// CHECK:STDOUT: !70 = !{null}
// CHECK:STDOUT: !71 = !DISubroutineType(types: !70)
// CHECK:STDOUT: !87 = !DIFile(filename: "variadic_thunk.carbon", directory: "")
// CHECK:STDOUT: !88 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !87, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !89 = !{null, !23}
// CHECK:STDOUT: !90 = !DISubroutineType(types: !89)
// CHECK:STDOUT: !95 = distinct !DISubprogram(name: "Call1", linkageName: "_CCall1.Main", scope: null, file: !87, line: 10, type: !71, spFlags: DISPFlagDefinition, unit: !88)
// CHECK:STDOUT: !96 = !DILocation(line: 12, column: 11, scope: !95)
// CHECK:STDOUT: !97 = !DILocation(line: 12, column: 3, scope: !95)
// CHECK:STDOUT: !98 = !DILocation(line: 10, column: 1, scope: !95)
// CHECK:STDOUT: !99 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.3d7b8a41b4c67e71:core.Destroy.Core", scope: null, file: !87, line: 12, type: !90, spFlags: DISPFlagDefinition, unit: !88, retainedNodes: !102)
// CHECK:STDOUT: !100 = !DILocalVariable(arg: 1, scope: !99, type: !23)
// CHECK:STDOUT: !101 = !DILocation(line: 12, column: 11, scope: !99)
// CHECK:STDOUT: !102 = !{!100}
// CHECK:STDOUT: !103 = distinct !DISubprogram(name: "Call2", linkageName: "_CCall2.Main", scope: null, file: !87, line: 16, type: !71, spFlags: DISPFlagDefinition, unit: !88)
// CHECK:STDOUT: !104 = !DILocation(line: 18, column: 11, scope: !103)
// CHECK:STDOUT: !105 = !DILocation(line: 18, column: 3, scope: !103)
// CHECK:STDOUT: !106 = !DILocation(line: 16, column: 1, scope: !103)
// CHECK:STDOUT: !107 = distinct !DISubprogram(name: "Call3", linkageName: "_CCall3.Main", scope: null, file: !87, line: 22, type: !71, spFlags: DISPFlagDefinition, unit: !88)
// CHECK:STDOUT: !108 = !DILocation(line: 24, column: 11, scope: !107)
// CHECK:STDOUT: !109 = !DILocation(line: 24, column: 3, scope: !107)
// CHECK:STDOUT: !110 = !DILocation(line: 22, column: 1, scope: !107)
// CHECK:STDOUT: !111 = !{!"p1 _ZTS1X", !59, i64 0}
// CHECK:STDOUT: !112 = !{!111, !111, i64 0}
// CHECK:STDOUT:

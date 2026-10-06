// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
// EXTRA-ARGS: --clang-arg=-std=c++26
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/thunks.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/thunks.carbon

// --- need_thunk.h

struct NeedThunk {
  NeedThunk();
  NeedThunk(const NeedThunk&);
  ~NeedThunk() = default;
};

// --- multiple_thunks_in_one_class.carbon

library "[[@TEST_NAME]]";

import Cpp library "need_thunk.h";

// We intend to create multiple thunks named `Op` here to demonstrate the need
// for the mangling to include the signature function.
fn Call(n: Cpp.NeedThunk) {
  var unused n2: Cpp.NeedThunk = n;
}

// --- box.h

struct A {};
struct B {};

template <typename T>
struct Box {
  Box();
  Box(const Box&);
  ~Box();
  T value;
};

// --- thunks_for_distinct_specializations.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

// Distinct specializations of the same class template share a Carbon name and
// parent scope, so their `Copy` (and `Destroy`) thunks need distinct mangled
// names; otherwise they would collide into a single LLVM function. The
// distinguishing key is the Clang mangled type name recorded when importing a
// C++ class.
fn Call(a: Cpp.Box(Cpp.A), b: Cpp.Box(Cpp.B)) {
  var unused a2: Cpp.Box(Cpp.A) = a;
  var unused b2: Cpp.Box(Cpp.B) = b;
}

// --- anonymous_namespace_collision.h

namespace {
// A type in the anonymous namespace. We expose it under an alias because, once
// the global `Collide` below is declared, the unqualified name `Collide`
// refers to that global type.
struct Collide {
  Collide() {}
  Collide(const Collide&) {}
  ~Collide() {}
};
using AnonCollide = Collide;
}  // namespace

// A *different* type with the same name in the global namespace.
struct Collide {
  Collide() {}
  Collide(const Collide&) {}
  ~Collide() {}
};

// --- thunks_for_anonymous_namespace_collision.carbon

library "[[@TEST_NAME]]";

import Cpp library "anonymous_namespace_collision.h";

// `Cpp.Collide` is the global type and `Cpp.AnonCollide` aliases a distinct
// type of the same name in the anonymous namespace. Carbon sees both as
// `Collide` with the same parent scope, so their `Copy` thunks would collide
// into a single LLVM function without the Clang mangled type name (which
// encodes the anonymous namespace) in the fingerprint.
fn Call(a: Cpp.Collide, b: Cpp.AnonCollide) {
  var unused a2: Cpp.Collide = a;
  var unused b2: Cpp.AnonCollide = b;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'multiple_thunks_in_one_class.carbon'
// CHECK:STDOUT: source_filename = "multiple_thunks_in_one_class.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [87 x i8] c"carbon: C++ exception escaped into Carbon through `NeedThunk::NeedThunk`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr %n) #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %n2.var = alloca [1 x i8], align 1, !dbg !44
// CHECK:STDOUT:   %.loc9_34.1.temp = alloca [1 x i8], align 1, !dbg !45
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %n2.var), !dbg !44
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc9_34.1.temp), !dbg !45
// CHECK:STDOUT:   call void @_ZN9NeedThunkC1ERKS_.carbon_thunk._(ptr %n, ptr %n2.var), !dbg !45
// CHECK:STDOUT:   call void @"_CSelfDestruct.e015ef96e8aea788:core.Destroy.Core"(ptr %n2.var), !dbg !44
// CHECK:STDOUT:   ret void, !dbg !47
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN9NeedThunkC1ERKS_.carbon_thunk._(ptr noundef %0, ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !66
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !66
// CHECK:STDOUT:   %1 = load ptr, ptr %return.addr, align 8, !tbaa !66
// CHECK:STDOUT:   %2 = load ptr, ptr %.addr, align 8, !tbaa !66
// CHECK:STDOUT:   invoke void @_ZN9NeedThunkC1ERKS_(ptr noundef nonnull align 1 dereferenceable(1) %1, ptr noundef nonnull align 1 dereferenceable(1) %2)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %3 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %3, 0
// CHECK:STDOUT:   store ptr %4, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %3, 1
// CHECK:STDOUT:   store i32 %5, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %6 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 86) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #7
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %7 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %8 = extractvalue { ptr, i32 } %7, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %8) #8
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_COp:thunk:Copy.60e3c6e2415a2ad6.Core:NeedThunk.Cpp"(ptr sret([1 x i8]) %return, ptr %self) #2 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN9NeedThunkC1ERKS_.carbon_thunk._(ptr %self, ptr %return), !dbg !52
// CHECK:STDOUT:   ret void, !dbg !52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e015ef96e8aea788:core.Destroy.Core"(ptr %self) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy:thunk:Destroy.092ad14c7174f642.Core:NeedThunk.Cpp"(ptr %self) #2 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !60
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #3
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZN9NeedThunkC1ERKS_(ptr noundef nonnull align 1 dereferenceable(1), ptr noundef nonnull align 1 dereferenceable(1)) unnamed_addr #4
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #5
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #6 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #8
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { alwaysinline nounwind }
// CHECK:STDOUT: attributes #3 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #4 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #7 = { noreturn }
// CHECK:STDOUT: attributes #8 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!33}
// CHECK:STDOUT: !llvm.module.flags = !{!68, !69, !70, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!73}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !32 = !DIFile(filename: "multiple_thunks_in_one_class.carbon", directory: "")
// CHECK:STDOUT: !33 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !32, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !34 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !35 = !{null, !34}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !39 = !{!34, !34}
// CHECK:STDOUT: !40 = !DISubroutineType(types: !39)
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !32, line: 8, type: !36, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !48)
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !41, type: !34)
// CHECK:STDOUT: !44 = !DILocation(line: 9, column: 3, scope: !41)
// CHECK:STDOUT: !45 = !DILocation(line: 9, column: 34, scope: !41)
// CHECK:STDOUT: !47 = !DILocation(line: 8, column: 1, scope: !41)
// CHECK:STDOUT: !48 = !{!42}
// CHECK:STDOUT: !49 = !DIFile(filename: "./need_thunk.h", directory: "")
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:Copy.60e3c6e2415a2ad6.Core:NeedThunk.Cpp", scope: null, file: !49, line: 4, type: !40, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !53)
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 1, scope: !50, type: !34)
// CHECK:STDOUT: !52 = !DILocation(line: 4, column: 3, scope: !50)
// CHECK:STDOUT: !53 = !{!51}
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e015ef96e8aea788:core.Destroy.Core", scope: null, file: !32, line: 9, type: !36, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !57)
// CHECK:STDOUT: !55 = !DILocalVariable(arg: 1, scope: !54, type: !34)
// CHECK:STDOUT: !56 = !DILocation(line: 9, column: 3, scope: !54)
// CHECK:STDOUT: !57 = !{!55}
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy:thunk:Destroy.092ad14c7174f642.Core:NeedThunk.Cpp", scope: null, file: !49, line: 5, type: !36, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !61)
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !58, type: !34)
// CHECK:STDOUT: !60 = !DILocation(line: 5, column: 3, scope: !58)
// CHECK:STDOUT: !61 = !{!59}
// CHECK:STDOUT: !62 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !63 = !{!"omnipotent char", !62, i64 0}
// CHECK:STDOUT: !64 = !{!"any pointer", !63, i64 0}
// CHECK:STDOUT: !65 = !{!"p1 _ZTS9NeedThunk", !64, i64 0}
// CHECK:STDOUT: !66 = !{!65, !65, i64 0}
// CHECK:STDOUT: !68 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !69 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !70 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !71 = !{!"int", !63, i64 0}
// CHECK:STDOUT: !72 = !{!"__libc_errno", !71, i64 0}
// CHECK:STDOUT: !73 = !{!72, !71, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'thunks_for_distinct_specializations.carbon'
// CHECK:STDOUT: source_filename = "thunks_for_distinct_specializations.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [78 x i8] c"carbon: C++ exception escaped into Carbon through `Box<A>::Box`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [78 x i8] c"carbon: C++ exception escaped into Carbon through `Box<B>::Box`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr %a, ptr %b) #0 !dbg !76 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a2.var = alloca [1 x i8], align 1, !dbg !81
// CHECK:STDOUT:   %.loc12_35.1.temp = alloca [1 x i8], align 1, !dbg !82
// CHECK:STDOUT:   %b2.var = alloca [1 x i8], align 1, !dbg !84
// CHECK:STDOUT:   %.loc13_35.1.temp = alloca [1 x i8], align 1, !dbg !85
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a2.var), !dbg !81
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc12_35.1.temp), !dbg !82
// CHECK:STDOUT:   call void @_ZN3BoxI1AEC1ERKS1_.carbon_thunk._(ptr %a, ptr %a2.var), !dbg !82
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b2.var), !dbg !84
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc13_35.1.temp), !dbg !85
// CHECK:STDOUT:   call void @_ZN3BoxI1BEC1ERKS1_.carbon_thunk._(ptr %b, ptr %b2.var), !dbg !85
// CHECK:STDOUT:   call void @"_CSelfDestruct.c6bde88ac44221c1:core.Destroy.Core"(ptr %b2.var), !dbg !84
// CHECK:STDOUT:   call void @"_CSelfDestruct.35d03e94f0115619:core.Destroy.Core"(ptr %a2.var), !dbg !81
// CHECK:STDOUT:   ret void, !dbg !87
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN3BoxI1AEC1ERKS1_.carbon_thunk._(ptr noundef %0, ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !107
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !107
// CHECK:STDOUT:   %1 = load ptr, ptr %return.addr, align 8, !tbaa !107
// CHECK:STDOUT:   %2 = load ptr, ptr %.addr, align 8, !tbaa !107
// CHECK:STDOUT:   invoke void @_ZN3BoxI1AEC1ERKS1_(ptr noundef nonnull align 1 dereferenceable(1) %1, ptr noundef nonnull align 1 dereferenceable(1) %2)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %3 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %3, 0
// CHECK:STDOUT:   store ptr %4, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %3, 1
// CHECK:STDOUT:   store i32 %5, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %6 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 77) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #7
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %7 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %8 = extractvalue { ptr, i32 } %7, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %8) #8
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_COp:thunk:Copy.c0735c73762b4d1c.Core:Box.Cpp"(ptr sret([1 x i8]) %return, ptr %self) #2 !dbg !90 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN3BoxI1AEC1ERKS1_.carbon_thunk._(ptr %self, ptr %return), !dbg !92
// CHECK:STDOUT:   ret void, !dbg !92
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN3BoxI1BEC1ERKS1_.carbon_thunk._(ptr noundef %0, ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !111
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !111
// CHECK:STDOUT:   %1 = load ptr, ptr %return.addr, align 8, !tbaa !111
// CHECK:STDOUT:   %2 = load ptr, ptr %.addr, align 8, !tbaa !111
// CHECK:STDOUT:   invoke void @_ZN3BoxI1BEC1ERKS1_(ptr noundef nonnull align 1 dereferenceable(1) %1, ptr noundef nonnull align 1 dereferenceable(1) %2)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %3 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %3, 0
// CHECK:STDOUT:   store ptr %4, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %3, 1
// CHECK:STDOUT:   store i32 %5, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %6 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.1, i64 noundef 77) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #7
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %7 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %8 = extractvalue { ptr, i32 } %7, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %8) #8
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_COp:thunk:Copy.2c1dd62357f2b914.Core:Box.Cpp"(ptr sret([1 x i8]) %return, ptr %self) #2 !dbg !94 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN3BoxI1BEC1ERKS1_.carbon_thunk._(ptr %self, ptr %return), !dbg !96
// CHECK:STDOUT:   ret void, !dbg !96
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare void @_ZN3BoxI1BED1Ev(ptr noundef nonnull align 1 dead_on_return(1) dereferenceable(1)) unnamed_addr #3
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.c6bde88ac44221c1:core.Destroy.Core"(ptr %self) #0 !dbg !98 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN3BoxI1BED1Ev(ptr %self), !dbg !100
// CHECK:STDOUT:   ret void, !dbg !100
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare void @_ZN3BoxI1AED1Ev(ptr noundef nonnull align 1 dead_on_return(1) dereferenceable(1)) unnamed_addr #3
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.35d03e94f0115619:core.Destroy.Core"(ptr %self) #0 !dbg !102 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN3BoxI1AED1Ev(ptr %self), !dbg !104
// CHECK:STDOUT:   ret void, !dbg !104
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #4
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZN3BoxI1AEC1ERKS1_(ptr noundef nonnull align 1 dereferenceable(1), ptr noundef nonnull align 1 dereferenceable(1)) unnamed_addr #5
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
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #6 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #8
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZN3BoxI1BEC1ERKS1_(ptr noundef nonnull align 1 dereferenceable(1), ptr noundef nonnull align 1 dereferenceable(1)) unnamed_addr #5
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_begin_catch, { 1, 2, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_rethrow, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { alwaysinline nounwind }
// CHECK:STDOUT: attributes #3 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #5 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #7 = { noreturn }
// CHECK:STDOUT: attributes #8 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!75}
// CHECK:STDOUT: !llvm.module.flags = !{!68, !69, !70, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!73}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !34 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !35 = !{null, !34}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !37 = !{null, !34, !34}
// CHECK:STDOUT: !38 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !39 = !{!34, !34}
// CHECK:STDOUT: !40 = !DISubroutineType(types: !39)
// CHECK:STDOUT: !62 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !63 = !{!"omnipotent char", !62, i64 0}
// CHECK:STDOUT: !64 = !{!"any pointer", !63, i64 0}
// CHECK:STDOUT: !68 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !69 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !70 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !71 = !{!"int", !63, i64 0}
// CHECK:STDOUT: !72 = !{!"__libc_errno", !71, i64 0}
// CHECK:STDOUT: !73 = !{!72, !71, i64 0}
// CHECK:STDOUT: !74 = !DIFile(filename: "thunks_for_distinct_specializations.carbon", directory: "")
// CHECK:STDOUT: !75 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !74, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !76 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !74, line: 11, type: !38, spFlags: DISPFlagDefinition, unit: !75, retainedNodes: !88)
// CHECK:STDOUT: !77 = !DILocalVariable(arg: 1, scope: !76, type: !34)
// CHECK:STDOUT: !78 = !DILocalVariable(arg: 2, scope: !76, type: !34)
// CHECK:STDOUT: !81 = !DILocation(line: 12, column: 3, scope: !76)
// CHECK:STDOUT: !82 = !DILocation(line: 12, column: 35, scope: !76)
// CHECK:STDOUT: !84 = !DILocation(line: 13, column: 3, scope: !76)
// CHECK:STDOUT: !85 = !DILocation(line: 13, column: 35, scope: !76)
// CHECK:STDOUT: !87 = !DILocation(line: 11, column: 1, scope: !76)
// CHECK:STDOUT: !88 = !{!77, !78}
// CHECK:STDOUT: !89 = !DIFile(filename: "./box.h", directory: "")
// CHECK:STDOUT: !90 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:Copy.c0735c73762b4d1c.Core:Box.Cpp", scope: null, file: !89, line: 8, type: !40, spFlags: DISPFlagDefinition, unit: !75, retainedNodes: !93)
// CHECK:STDOUT: !91 = !DILocalVariable(arg: 1, scope: !90, type: !34)
// CHECK:STDOUT: !92 = !DILocation(line: 8, column: 3, scope: !90)
// CHECK:STDOUT: !93 = !{!91}
// CHECK:STDOUT: !94 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:Copy.2c1dd62357f2b914.Core:Box.Cpp", scope: null, file: !89, line: 8, type: !40, spFlags: DISPFlagDefinition, unit: !75, retainedNodes: !97)
// CHECK:STDOUT: !95 = !DILocalVariable(arg: 1, scope: !94, type: !34)
// CHECK:STDOUT: !96 = !DILocation(line: 8, column: 3, scope: !94)
// CHECK:STDOUT: !97 = !{!95}
// CHECK:STDOUT: !98 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.c6bde88ac44221c1:core.Destroy.Core", scope: null, file: !74, line: 13, type: !36, spFlags: DISPFlagDefinition, unit: !75, retainedNodes: !101)
// CHECK:STDOUT: !99 = !DILocalVariable(arg: 1, scope: !98, type: !34)
// CHECK:STDOUT: !100 = !DILocation(line: 13, column: 3, scope: !98)
// CHECK:STDOUT: !101 = !{!99}
// CHECK:STDOUT: !102 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.35d03e94f0115619:core.Destroy.Core", scope: null, file: !74, line: 12, type: !36, spFlags: DISPFlagDefinition, unit: !75, retainedNodes: !105)
// CHECK:STDOUT: !103 = !DILocalVariable(arg: 1, scope: !102, type: !34)
// CHECK:STDOUT: !104 = !DILocation(line: 12, column: 3, scope: !102)
// CHECK:STDOUT: !105 = !{!103}
// CHECK:STDOUT: !106 = !{!"p1 _ZTS3BoxI1AE", !64, i64 0}
// CHECK:STDOUT: !107 = !{!106, !106, i64 0}
// CHECK:STDOUT: !110 = !{!"p1 _ZTS3BoxI1BE", !64, i64 0}
// CHECK:STDOUT: !111 = !{!110, !110, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'thunks_for_anonymous_namespace_collision.carbon'
// CHECK:STDOUT: source_filename = "thunks_for_anonymous_namespace_collision.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZN7CollideD2Ev = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZN7CollideC2ERKS_ = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [83 x i8] c"carbon: C++ exception escaped into Carbon through `Collide::Collide`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [106 x i8] c"carbon: C++ exception escaped into Carbon through `(anonymous namespace)::Collide::Collide`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr %a, ptr %b) #0 !dbg !116 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a2.var = alloca [1 x i8], align 1, !dbg !121
// CHECK:STDOUT:   %.loc12_32.1.temp = alloca [1 x i8], align 1, !dbg !122
// CHECK:STDOUT:   %b2.var = alloca [1 x i8], align 1, !dbg !124
// CHECK:STDOUT:   %.loc13_36.1.temp = alloca [1 x i8], align 1, !dbg !125
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a2.var), !dbg !121
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc12_32.1.temp), !dbg !122
// CHECK:STDOUT:   call void @_ZN7CollideC1ERKS_.carbon_thunk._(ptr %a, ptr %a2.var), !dbg !122
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b2.var), !dbg !124
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc13_36.1.temp), !dbg !125
// CHECK:STDOUT:   call void @_ZN12_GLOBAL__N_17CollideC1ERKS0_.carbon_thunk._(ptr %b, ptr %b2.var), !dbg !125
// CHECK:STDOUT:   call void @"_CSelfDestruct.c4db6b78eb7f0546:core.Destroy.Core"(ptr %b2.var), !dbg !124
// CHECK:STDOUT:   call void @"_CSelfDestruct.3cee6f1426a47a6f:core.Destroy.Core"(ptr %a2.var), !dbg !121
// CHECK:STDOUT:   ret void, !dbg !127
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN7CollideC1ERKS_.carbon_thunk._(ptr noundef %0, ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !147
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !147
// CHECK:STDOUT:   %1 = load ptr, ptr %return.addr, align 8, !tbaa !147
// CHECK:STDOUT:   %2 = load ptr, ptr %.addr, align 8, !tbaa !147
// CHECK:STDOUT:   invoke void @_ZN7CollideC2ERKS_(ptr noundef nonnull align 1 dereferenceable(1) %1, ptr noundef nonnull align 1 dereferenceable(1) %2)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %3 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %3, 0
// CHECK:STDOUT:   store ptr %4, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %3, 1
// CHECK:STDOUT:   store i32 %5, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %6 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 82) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #7
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %7 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %8 = extractvalue { ptr, i32 } %7, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %8) #8
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_COp:thunk:Copy.9e522bb4dbf82e5c.Core:Collide.Cpp"(ptr sret([1 x i8]) %return, ptr %self) #2 !dbg !130 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN7CollideC1ERKS_.carbon_thunk._(ptr %self, ptr %return), !dbg !132
// CHECK:STDOUT:   ret void, !dbg !132
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN12_GLOBAL__N_17CollideC1ERKS0_.carbon_thunk._(ptr noundef %0, ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !150
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !150
// CHECK:STDOUT:   %1 = load ptr, ptr %return.addr, align 8, !tbaa !150
// CHECK:STDOUT:   %2 = load ptr, ptr %.addr, align 8, !tbaa !150
// CHECK:STDOUT:   invoke void @_ZN12_GLOBAL__N_17CollideC2ERKS0_(ptr noundef nonnull align 1 dereferenceable(1) %1, ptr noundef nonnull align 1 dereferenceable(1) %2)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %3 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %3, 0
// CHECK:STDOUT:   store ptr %4, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %3, 1
// CHECK:STDOUT:   store i32 %5, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %6 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.1, i64 noundef 105) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #7
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %7 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %8 = extractvalue { ptr, i32 } %7, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %8) #8
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_COp:thunk:Copy.d1fe27f3241437fa.Core:Collide..Cpp"(ptr sret([1 x i8]) %return, ptr %self) #2 !dbg !134 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN12_GLOBAL__N_17CollideC1ERKS0_.carbon_thunk._(ptr %self, ptr %return), !dbg !136
// CHECK:STDOUT:   ret void, !dbg !136
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN12_GLOBAL__N_17CollideD2Ev(ptr noundef nonnull align 1 dereferenceable(1) %this) unnamed_addr #3 align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !150
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.c4db6b78eb7f0546:core.Destroy.Core"(ptr %self) #0 !dbg !138 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN12_GLOBAL__N_17CollideD2Ev(ptr %self), !dbg !140
// CHECK:STDOUT:   ret void, !dbg !140
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local void @_ZN7CollideD2Ev(ptr noundef nonnull align 1 dereferenceable(1) %this) unnamed_addr #3 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !147
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.3cee6f1426a47a6f:core.Destroy.Core"(ptr %self) #0 !dbg !142 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN7CollideD2Ev(ptr %self), !dbg !144
// CHECK:STDOUT:   ret void, !dbg !144
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #4
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local void @_ZN7CollideC2ERKS_(ptr noundef nonnull align 1 dereferenceable(1) %this, ptr noundef nonnull align 1 dereferenceable(1) %0) unnamed_addr #3 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !147
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !147
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #5
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #6 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #8
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN12_GLOBAL__N_17CollideC2ERKS0_(ptr noundef nonnull align 1 dereferenceable(1) %this, ptr noundef nonnull align 1 dereferenceable(1) %0) unnamed_addr #3 align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !150
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !150
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_begin_catch, { 1, 2, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_rethrow, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { alwaysinline nounwind }
// CHECK:STDOUT: attributes #3 = { mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #5 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #7 = { noreturn }
// CHECK:STDOUT: attributes #8 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!115}
// CHECK:STDOUT: !llvm.module.flags = !{!68, !69, !70, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!73}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !34 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !35 = !{null, !34}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !37 = !{null, !34, !34}
// CHECK:STDOUT: !38 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !39 = !{!34, !34}
// CHECK:STDOUT: !40 = !DISubroutineType(types: !39)
// CHECK:STDOUT: !62 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !63 = !{!"omnipotent char", !62, i64 0}
// CHECK:STDOUT: !64 = !{!"any pointer", !63, i64 0}
// CHECK:STDOUT: !68 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !69 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !70 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !71 = !{!"int", !63, i64 0}
// CHECK:STDOUT: !72 = !{!"__libc_errno", !71, i64 0}
// CHECK:STDOUT: !73 = !{!72, !71, i64 0}
// CHECK:STDOUT: !114 = !DIFile(filename: "thunks_for_anonymous_namespace_collision.carbon", directory: "")
// CHECK:STDOUT: !115 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !114, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !116 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !114, line: 11, type: !38, spFlags: DISPFlagDefinition, unit: !115, retainedNodes: !128)
// CHECK:STDOUT: !117 = !DILocalVariable(arg: 1, scope: !116, type: !34)
// CHECK:STDOUT: !118 = !DILocalVariable(arg: 2, scope: !116, type: !34)
// CHECK:STDOUT: !121 = !DILocation(line: 12, column: 3, scope: !116)
// CHECK:STDOUT: !122 = !DILocation(line: 12, column: 32, scope: !116)
// CHECK:STDOUT: !124 = !DILocation(line: 13, column: 3, scope: !116)
// CHECK:STDOUT: !125 = !DILocation(line: 13, column: 36, scope: !116)
// CHECK:STDOUT: !127 = !DILocation(line: 11, column: 1, scope: !116)
// CHECK:STDOUT: !128 = !{!117, !118}
// CHECK:STDOUT: !129 = !DIFile(filename: "./anonymous_namespace_collision.h", directory: "")
// CHECK:STDOUT: !130 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:Copy.9e522bb4dbf82e5c.Core:Collide.Cpp", scope: null, file: !129, line: 17, type: !40, spFlags: DISPFlagDefinition, unit: !115, retainedNodes: !133)
// CHECK:STDOUT: !131 = !DILocalVariable(arg: 1, scope: !130, type: !34)
// CHECK:STDOUT: !132 = !DILocation(line: 17, column: 3, scope: !130)
// CHECK:STDOUT: !133 = !{!131}
// CHECK:STDOUT: !134 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:Copy.d1fe27f3241437fa.Core:Collide..Cpp", scope: null, file: !129, line: 8, type: !40, spFlags: DISPFlagDefinition, unit: !115, retainedNodes: !137)
// CHECK:STDOUT: !135 = !DILocalVariable(arg: 1, scope: !134, type: !34)
// CHECK:STDOUT: !136 = !DILocation(line: 8, column: 3, scope: !134)
// CHECK:STDOUT: !137 = !{!135}
// CHECK:STDOUT: !138 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.c4db6b78eb7f0546:core.Destroy.Core", scope: null, file: !114, line: 13, type: !36, spFlags: DISPFlagDefinition, unit: !115, retainedNodes: !141)
// CHECK:STDOUT: !139 = !DILocalVariable(arg: 1, scope: !138, type: !34)
// CHECK:STDOUT: !140 = !DILocation(line: 13, column: 3, scope: !138)
// CHECK:STDOUT: !141 = !{!139}
// CHECK:STDOUT: !142 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.3cee6f1426a47a6f:core.Destroy.Core", scope: null, file: !114, line: 12, type: !36, spFlags: DISPFlagDefinition, unit: !115, retainedNodes: !145)
// CHECK:STDOUT: !143 = !DILocalVariable(arg: 1, scope: !142, type: !34)
// CHECK:STDOUT: !144 = !DILocation(line: 12, column: 3, scope: !142)
// CHECK:STDOUT: !145 = !{!143}
// CHECK:STDOUT: !146 = !{!"p1 _ZTS7Collide", !64, i64 0}
// CHECK:STDOUT: !147 = !{!146, !146, i64 0}
// CHECK:STDOUT: !149 = !{!"p1 _ZTSN12_GLOBAL__N_17CollideE", !64, i64 0}
// CHECK:STDOUT: !150 = !{!149, !149, i64 0}
// CHECK:STDOUT:

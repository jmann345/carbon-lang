// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
// EXTRA-ARGS: --clang-arg=-std=c++26
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/class/import/method.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/class/import/method.carbon

// --- methods.h

struct Base {
  virtual void virt0();
};

struct A: Base {
  int by_val() const { return n; }
  int by_ref() { return n; }
  virtual void virt1();
  int n;
};

// --- call_by_val.carbon

library "[[@TEST_NAME]]";

import Cpp library "methods.h";

fn UseVal(a: Cpp.A) -> i32 {
  return a.by_val();
}

// --- call_by_ref.carbon

library "[[@TEST_NAME]]";

import Cpp library "methods.h";

fn UseVal(a: Cpp.A*) -> i32 {
  return a->by_ref();
}

// --- call_virtual.carbon

library "[[@TEST_NAME]]";

import Cpp library "methods.h";

fn UseVal(a: Cpp.A*) {
  a->virt0();
  a->virt1();
}

// --- thunk.h

struct NeedThunk {
  void Implicit(signed char c) const;
  void Explicit(this NeedThunk, signed char c);
};

// --- call_thunk.carbon

library "[[@TEST_NAME]]";

import Cpp library "thunk.h";

fn Call(n: Cpp.NeedThunk) {
  n.Implicit(1);
  n.Explicit(1);
}

// --- call_with_ref_self.carbon

library "[[@TEST_NAME]]";

import Cpp;
inline Cpp '''
struct RefSelfA {
  void f(int x, int y);
};
''';

fn F(ref r: Cpp.RefSelfA) {
  r.f(1, 2);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'call_by_val.carbon'
// CHECK:STDOUT: source_filename = "call_by_val.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %struct.A = type <{ %struct.Base, i32, [4 x i8] }>
// CHECK:STDOUT: %struct.Base = type { ptr }
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZNK1A6by_valEv = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @_ZTV1A = available_externally constant { [4 x ptr] } { [4 x ptr] [ptr null, ptr @_ZTI1A, ptr @_ZN4Base5virt0Ev, ptr @_ZN1A5virt1Ev] }, align 8
// CHECK:STDOUT: @_ZTV4Base = available_externally constant { [3 x ptr] } { [3 x ptr] [ptr null, ptr @_ZTI4Base, ptr @_ZN4Base5virt0Ev] }, align 8
// CHECK:STDOUT: @_ZTI1A = external constant ptr
// CHECK:STDOUT: @_ZTI4Base = external constant ptr
// CHECK:STDOUT: @.str = private unnamed_addr constant [78 x i8] c"carbon: C++ exception escaped into Carbon through `Base::virt0`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [75 x i8] c"carbon: C++ exception escaped into Carbon through `A::virt1`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.2 = private unnamed_addr constant [76 x i8] c"carbon: C++ exception escaped into Carbon through `A::by_val`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseVal.Main(ptr %a) #0 !dbg !26 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %by_val__carbon_thunk.call = call i32 @_ZNK1A6by_valEv.carbon_thunk._(ptr %a), !dbg !31
// CHECK:STDOUT:   ret i32 %by_val__carbon_thunk.call, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN4Base5virt0Ev.carbon_thunk.r(ptr noundef nonnull align 8 dereferenceable(8) %this) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !38
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !38, !nonnull !40, !align !41
// CHECK:STDOUT:   %vtable = load ptr, ptr %0, align 8, !tbaa !43
// CHECK:STDOUT:   %vfn = getelementptr inbounds ptr, ptr %vtable, i64 0
// CHECK:STDOUT:   %1 = load ptr, ptr %vfn, align 8
// CHECK:STDOUT:   invoke void %1(ptr noundef nonnull align 8 dereferenceable(8) %0)
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
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 77) #0
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
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN1A5virt1Ev.carbon_thunk.r(ptr noundef nonnull align 8 dereferenceable(12) %this) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !45
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !45, !nonnull !40, !align !41
// CHECK:STDOUT:   %vtable = load ptr, ptr %0, align 8, !tbaa !43
// CHECK:STDOUT:   %vfn = getelementptr inbounds ptr, ptr %vtable, i64 1
// CHECK:STDOUT:   %1 = load ptr, ptr %vfn, align 8
// CHECK:STDOUT:   invoke void %1(ptr noundef nonnull align 8 dereferenceable(12) %0)
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
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.1, i64 noundef 74) #0
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
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_ZNK1A6by_valEv.carbon_thunk._(ptr noundef nonnull align 8 dereferenceable(12) %this) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !45
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !45, !nonnull !40, !align !41
// CHECK:STDOUT:   %call = invoke noundef i32 @_ZNK1A6by_valEv(ptr noundef nonnull align 8 dereferenceable(12) %0)
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.2, i64 noundef 75) #0
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
// CHECK:STDOUT: declare void @_ZN4Base5virt0Ev(ptr noundef nonnull align 8 dereferenceable(8)) unnamed_addr #2
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZN1A5virt1Ev(ptr noundef nonnull align 8 dereferenceable(12)) unnamed_addr #2
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
// CHECK:STDOUT:   call void @_ZSt9terminatev() #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef i32 @_ZNK1A6by_valEv(ptr noundef nonnull align 8 dereferenceable(12) %this) #5 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !45
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %n = getelementptr inbounds nuw %struct.A, ptr %this1, i32 0, i32 1
// CHECK:STDOUT:   %0 = load i32, ptr %n, align 8, !tbaa !48
// CHECK:STDOUT:   ret i32 %0
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_ZN4Base5virt0Ev, { 1, 0 }
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
// CHECK:STDOUT: attributes #5 = { mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!19}
// CHECK:STDOUT: !llvm.module.flags = !{!49, !50, !51, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!53}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !18 = !DIFile(filename: "call_by_val.carbon", directory: "")
// CHECK:STDOUT: !19 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !18, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !22 = !{!20, !21}
// CHECK:STDOUT: !23 = !DISubroutineType(types: !22)
// CHECK:STDOUT: !26 = distinct !DISubprogram(name: "UseVal", linkageName: "_CUseVal.Main", scope: null, file: !18, line: 6, type: !23, spFlags: DISPFlagDefinition, unit: !19, retainedNodes: !33)
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 1, scope: !26, type: !21)
// CHECK:STDOUT: !31 = !DILocation(line: 7, column: 10, scope: !26)
// CHECK:STDOUT: !32 = !DILocation(line: 7, column: 3, scope: !26)
// CHECK:STDOUT: !33 = !{!27}
// CHECK:STDOUT: !34 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !35 = !{!"omnipotent char", !34, i64 0}
// CHECK:STDOUT: !36 = !{!"any pointer", !35, i64 0}
// CHECK:STDOUT: !37 = !{!"p1 _ZTS4Base", !36, i64 0}
// CHECK:STDOUT: !38 = !{!37, !37, i64 0}
// CHECK:STDOUT: !39 = !{!"_ZTS4Base"}
// CHECK:STDOUT: !40 = !{}
// CHECK:STDOUT: !41 = !{i64 8}
// CHECK:STDOUT: !42 = !{!"vtable pointer", !34, i64 0}
// CHECK:STDOUT: !43 = !{!42, !42, i64 0}
// CHECK:STDOUT: !44 = !{!"p1 _ZTS1A", !36, i64 0}
// CHECK:STDOUT: !45 = !{!44, !44, i64 0}
// CHECK:STDOUT: !46 = !{!"int", !35, i64 0}
// CHECK:STDOUT: !47 = !{!"_ZTS1A", !39, i64 0, !46, i64 8}
// CHECK:STDOUT: !48 = !{!47, !46, i64 8}
// CHECK:STDOUT: !49 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !50 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !51 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !52 = !{!"__libc_errno", !46, i64 0}
// CHECK:STDOUT: !53 = !{!52, !46, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'call_by_ref.carbon'
// CHECK:STDOUT: source_filename = "call_by_ref.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %struct.A.19 = type <{ %struct.Base.18, i32, [4 x i8] }>
// CHECK:STDOUT: %struct.Base.18 = type { ptr }
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZN1A6by_refEv = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @_ZTV1A = available_externally constant { [4 x ptr] } { [4 x ptr] [ptr null, ptr @_ZTI1A, ptr @_ZN4Base5virt0Ev, ptr @_ZN1A5virt1Ev] }, align 8
// CHECK:STDOUT: @_ZTV4Base = available_externally constant { [3 x ptr] } { [3 x ptr] [ptr null, ptr @_ZTI4Base, ptr @_ZN4Base5virt0Ev] }, align 8
// CHECK:STDOUT: @_ZTI1A = external constant ptr
// CHECK:STDOUT: @_ZTI4Base = external constant ptr
// CHECK:STDOUT: @.str = private unnamed_addr constant [78 x i8] c"carbon: C++ exception escaped into Carbon through `Base::virt0`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [75 x i8] c"carbon: C++ exception escaped into Carbon through `A::virt1`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.2 = private unnamed_addr constant [76 x i8] c"carbon: C++ exception escaped into Carbon through `A::by_ref`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseVal.Main(ptr %a) #0 !dbg !56 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %by_ref__carbon_thunk.call = call i32 @_ZN1A6by_refEv.carbon_thunk.r(ptr %a), !dbg !61
// CHECK:STDOUT:   ret i32 %by_ref__carbon_thunk.call, !dbg !62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN4Base5virt0Ev.carbon_thunk.r(ptr noundef nonnull align 8 dereferenceable(8) %this) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !38
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !38, !nonnull !40, !align !41
// CHECK:STDOUT:   %vtable = load ptr, ptr %0, align 8, !tbaa !43
// CHECK:STDOUT:   %vfn = getelementptr inbounds ptr, ptr %vtable, i64 0
// CHECK:STDOUT:   %1 = load ptr, ptr %vfn, align 8
// CHECK:STDOUT:   invoke void %1(ptr noundef nonnull align 8 dereferenceable(8) %0)
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
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 77) #0
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
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN1A5virt1Ev.carbon_thunk.r(ptr noundef nonnull align 8 dereferenceable(12) %this) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !45
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !45, !nonnull !40, !align !41
// CHECK:STDOUT:   %vtable = load ptr, ptr %0, align 8, !tbaa !43
// CHECK:STDOUT:   %vfn = getelementptr inbounds ptr, ptr %vtable, i64 1
// CHECK:STDOUT:   %1 = load ptr, ptr %vfn, align 8
// CHECK:STDOUT:   invoke void %1(ptr noundef nonnull align 8 dereferenceable(12) %0)
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
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.1, i64 noundef 74) #0
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
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_ZN1A6by_refEv.carbon_thunk.r(ptr noundef nonnull align 8 dereferenceable(12) %this) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !45
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !45, !nonnull !40, !align !41
// CHECK:STDOUT:   %call = invoke noundef i32 @_ZN1A6by_refEv(ptr noundef nonnull align 8 dereferenceable(12) %0)
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.2, i64 noundef 75) #0
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
// CHECK:STDOUT: declare void @_ZN4Base5virt0Ev(ptr noundef nonnull align 8 dereferenceable(8)) unnamed_addr #2
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZN1A5virt1Ev(ptr noundef nonnull align 8 dereferenceable(12)) unnamed_addr #2
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
// CHECK:STDOUT:   call void @_ZSt9terminatev() #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef i32 @_ZN1A6by_refEv(ptr noundef nonnull align 8 dereferenceable(12) %this) #5 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !45
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %n = getelementptr inbounds nuw %struct.A.19, ptr %this1, i32 0, i32 1
// CHECK:STDOUT:   %0 = load i32, ptr %n, align 8, !tbaa !48
// CHECK:STDOUT:   ret i32 %0
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_ZN4Base5virt0Ev, { 1, 0 }
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
// CHECK:STDOUT: attributes #5 = { mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!55}
// CHECK:STDOUT: !llvm.module.flags = !{!49, !50, !51, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!53}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !22 = !{!20, !21}
// CHECK:STDOUT: !23 = !DISubroutineType(types: !22)
// CHECK:STDOUT: !34 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !35 = !{!"omnipotent char", !34, i64 0}
// CHECK:STDOUT: !36 = !{!"any pointer", !35, i64 0}
// CHECK:STDOUT: !37 = !{!"p1 _ZTS4Base", !36, i64 0}
// CHECK:STDOUT: !38 = !{!37, !37, i64 0}
// CHECK:STDOUT: !39 = !{!"_ZTS4Base"}
// CHECK:STDOUT: !40 = !{}
// CHECK:STDOUT: !41 = !{i64 8}
// CHECK:STDOUT: !42 = !{!"vtable pointer", !34, i64 0}
// CHECK:STDOUT: !43 = !{!42, !42, i64 0}
// CHECK:STDOUT: !44 = !{!"p1 _ZTS1A", !36, i64 0}
// CHECK:STDOUT: !45 = !{!44, !44, i64 0}
// CHECK:STDOUT: !46 = !{!"int", !35, i64 0}
// CHECK:STDOUT: !47 = !{!"_ZTS1A", !39, i64 0, !46, i64 8}
// CHECK:STDOUT: !48 = !{!47, !46, i64 8}
// CHECK:STDOUT: !49 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !50 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !51 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !52 = !{!"__libc_errno", !46, i64 0}
// CHECK:STDOUT: !53 = !{!52, !46, i64 0}
// CHECK:STDOUT: !54 = !DIFile(filename: "call_by_ref.carbon", directory: "")
// CHECK:STDOUT: !55 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !54, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "UseVal", linkageName: "_CUseVal.Main", scope: null, file: !54, line: 6, type: !23, spFlags: DISPFlagDefinition, unit: !55, retainedNodes: !63)
// CHECK:STDOUT: !57 = !DILocalVariable(arg: 1, scope: !56, type: !21)
// CHECK:STDOUT: !61 = !DILocation(line: 7, column: 10, scope: !56)
// CHECK:STDOUT: !62 = !DILocation(line: 7, column: 3, scope: !56)
// CHECK:STDOUT: !63 = !{!57}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'call_virtual.carbon'
// CHECK:STDOUT: source_filename = "call_virtual.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @_ZTV1A = available_externally constant { [4 x ptr] } { [4 x ptr] [ptr null, ptr @_ZTI1A, ptr @_ZN4Base5virt0Ev, ptr @_ZN1A5virt1Ev] }, align 8
// CHECK:STDOUT: @_ZTV4Base = available_externally constant { [3 x ptr] } { [3 x ptr] [ptr null, ptr @_ZTI4Base, ptr @_ZN4Base5virt0Ev] }, align 8
// CHECK:STDOUT: @_ZTI1A = external constant ptr
// CHECK:STDOUT: @_ZTI4Base = external constant ptr
// CHECK:STDOUT: @.str = private unnamed_addr constant [78 x i8] c"carbon: C++ exception escaped into Carbon through `Base::virt0`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [75 x i8] c"carbon: C++ exception escaped into Carbon through `A::virt1`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CUseVal.Main(ptr %a) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_4.2.base = getelementptr inbounds nuw [16 x i8], ptr %a, i32 0, i32 0, !dbg !69
// CHECK:STDOUT:   call void @_ZN4Base5virt0Ev.carbon_thunk.r(ptr %.loc7_4.2.base), !dbg !69
// CHECK:STDOUT:   call void @_ZN1A5virt1Ev.carbon_thunk.r(ptr %a), !dbg !70
// CHECK:STDOUT:   ret void, !dbg !71
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN4Base5virt0Ev.carbon_thunk.r(ptr noundef nonnull align 8 dereferenceable(8) %this) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !38
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !38, !nonnull !40, !align !41
// CHECK:STDOUT:   %vtable = load ptr, ptr %0, align 8, !tbaa !43
// CHECK:STDOUT:   %vfn = getelementptr inbounds ptr, ptr %vtable, i64 0
// CHECK:STDOUT:   %1 = load ptr, ptr %vfn, align 8
// CHECK:STDOUT:   invoke void %1(ptr noundef nonnull align 8 dereferenceable(8) %0)
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
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 77) #0
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
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN1A5virt1Ev.carbon_thunk.r(ptr noundef nonnull align 8 dereferenceable(12) %this) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !45
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !45, !nonnull !40, !align !41
// CHECK:STDOUT:   %vtable = load ptr, ptr %0, align 8, !tbaa !43
// CHECK:STDOUT:   %vfn = getelementptr inbounds ptr, ptr %vtable, i64 1
// CHECK:STDOUT:   %1 = load ptr, ptr %vfn, align 8
// CHECK:STDOUT:   invoke void %1(ptr noundef nonnull align 8 dereferenceable(12) %0)
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
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.1, i64 noundef 74) #0
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
// CHECK:STDOUT: declare void @_ZN4Base5virt0Ev(ptr noundef nonnull align 8 dereferenceable(8)) unnamed_addr #2
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZN1A5virt1Ev(ptr noundef nonnull align 8 dereferenceable(12)) unnamed_addr #2
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
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_ZN4Base5virt0Ev, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_begin_catch, { 1, 2, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_rethrow, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #3 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noreturn }
// CHECK:STDOUT: attributes #6 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!65}
// CHECK:STDOUT: !llvm.module.flags = !{!49, !50, !51, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!53}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !21 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !24 = !{null, !21}
// CHECK:STDOUT: !25 = !DISubroutineType(types: !24)
// CHECK:STDOUT: !34 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !35 = !{!"omnipotent char", !34, i64 0}
// CHECK:STDOUT: !36 = !{!"any pointer", !35, i64 0}
// CHECK:STDOUT: !37 = !{!"p1 _ZTS4Base", !36, i64 0}
// CHECK:STDOUT: !38 = !{!37, !37, i64 0}
// CHECK:STDOUT: !40 = !{}
// CHECK:STDOUT: !41 = !{i64 8}
// CHECK:STDOUT: !42 = !{!"vtable pointer", !34, i64 0}
// CHECK:STDOUT: !43 = !{!42, !42, i64 0}
// CHECK:STDOUT: !44 = !{!"p1 _ZTS1A", !36, i64 0}
// CHECK:STDOUT: !45 = !{!44, !44, i64 0}
// CHECK:STDOUT: !46 = !{!"int", !35, i64 0}
// CHECK:STDOUT: !49 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !50 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !51 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !52 = !{!"__libc_errno", !46, i64 0}
// CHECK:STDOUT: !53 = !{!52, !46, i64 0}
// CHECK:STDOUT: !64 = !DIFile(filename: "call_virtual.carbon", directory: "")
// CHECK:STDOUT: !65 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !64, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "UseVal", linkageName: "_CUseVal.Main", scope: null, file: !64, line: 6, type: !25, spFlags: DISPFlagDefinition, unit: !65, retainedNodes: !72)
// CHECK:STDOUT: !67 = !DILocalVariable(arg: 1, scope: !66, type: !21)
// CHECK:STDOUT: !69 = !DILocation(line: 7, column: 3, scope: !66)
// CHECK:STDOUT: !70 = !DILocation(line: 8, column: 3, scope: !66)
// CHECK:STDOUT: !71 = !DILocation(line: 6, column: 1, scope: !66)
// CHECK:STDOUT: !72 = !{!67}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'call_thunk.carbon'
// CHECK:STDOUT: source_filename = "call_thunk.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %struct.NeedThunk = type { i8 }
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @int_1.f1e = internal constant i8 1
// CHECK:STDOUT: @.str = private unnamed_addr constant [86 x i8] c"carbon: C++ exception escaped into Carbon through `NeedThunk::Implicit`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [86 x i8] c"carbon: C++ exception escaped into Carbon through `NeedThunk::Explicit`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCall.Main(ptr %n) #0 !dbg !80 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_14.3.temp = alloca i8, align 1, !dbg !84
// CHECK:STDOUT:   %.loc8_14.3.temp = alloca i8, align 1, !dbg !86
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc7_14.3.temp), !dbg !84
// CHECK:STDOUT:   call void @_ZNK9NeedThunk8ImplicitEa.carbon_thunk.__(ptr %n, ptr @int_1.f1e), !dbg !83
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr @int_1.f1e), !dbg !84
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc8_14.3.temp), !dbg !86
// CHECK:STDOUT:   call void @_ZNH9NeedThunk8ExplicitES_a.carbon_thunk.__(ptr %n, ptr @int_1.f1e), !dbg !85
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr @int_1.f1e), !dbg !86
// CHECK:STDOUT:   ret void, !dbg !87
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZNK9NeedThunk8ImplicitEa.carbon_thunk.__(ptr noundef nonnull align 1 dereferenceable(1) %this, ptr noundef %c) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %c.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !94
// CHECK:STDOUT:   store ptr %c, ptr %c.addr, align 8, !tbaa !96
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !94, !nonnull !40
// CHECK:STDOUT:   %1 = load ptr, ptr %c.addr, align 8, !tbaa !96
// CHECK:STDOUT:   %2 = load i8, ptr %1, align 1, !tbaa !98
// CHECK:STDOUT:   invoke void @_ZNK9NeedThunk8ImplicitEa(ptr noundef nonnull align 1 dereferenceable(1) %0, i8 noundef signext %2)
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
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 85) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %7 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %8 = extractvalue { ptr, i32 } %7, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %8) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %self) #0 !dbg !89 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZNH9NeedThunk8ExplicitES_a.carbon_thunk.__(ptr noundef %0, ptr noundef %c) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %c.addr = alloca ptr, align 8
// CHECK:STDOUT:   %agg.tmp = alloca %struct.NeedThunk, align 1
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !94
// CHECK:STDOUT:   store ptr %c, ptr %c.addr, align 8, !tbaa !96
// CHECK:STDOUT:   %1 = load ptr, ptr %.addr, align 8, !tbaa !94
// CHECK:STDOUT:   %2 = load ptr, ptr %c.addr, align 8, !tbaa !96
// CHECK:STDOUT:   %3 = load i8, ptr %2, align 1, !tbaa !98
// CHECK:STDOUT:   invoke void @_ZNH9NeedThunk8ExplicitES_a(i8 noundef signext %3)
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
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.1, i64 noundef 85) #0
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
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZNK9NeedThunk8ImplicitEa(ptr noundef nonnull align 1 dereferenceable(1), i8 noundef signext) #3
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
// CHECK:STDOUT: declare void @_ZNH9NeedThunk8ExplicitES_a(i8 noundef signext) #3
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core", { 1, 0 }
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!74}
// CHECK:STDOUT: !llvm.module.flags = !{!49, !50, !51, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!53}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !21 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !24 = !{null, !21}
// CHECK:STDOUT: !25 = !DISubroutineType(types: !24)
// CHECK:STDOUT: !34 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !35 = !{!"omnipotent char", !34, i64 0}
// CHECK:STDOUT: !36 = !{!"any pointer", !35, i64 0}
// CHECK:STDOUT: !40 = !{}
// CHECK:STDOUT: !46 = !{!"int", !35, i64 0}
// CHECK:STDOUT: !49 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !50 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !51 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !52 = !{!"__libc_errno", !46, i64 0}
// CHECK:STDOUT: !53 = !{!52, !46, i64 0}
// CHECK:STDOUT: !73 = !DIFile(filename: "call_thunk.carbon", directory: "")
// CHECK:STDOUT: !74 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !73, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !75 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_signed)
// CHECK:STDOUT: !78 = !{null, !75}
// CHECK:STDOUT: !79 = !DISubroutineType(types: !78)
// CHECK:STDOUT: !80 = distinct !DISubprogram(name: "Call", linkageName: "_CCall.Main", scope: null, file: !73, line: 6, type: !25, spFlags: DISPFlagDefinition, unit: !74, retainedNodes: !88)
// CHECK:STDOUT: !81 = !DILocalVariable(arg: 1, scope: !80, type: !21)
// CHECK:STDOUT: !83 = !DILocation(line: 7, column: 3, scope: !80)
// CHECK:STDOUT: !84 = !DILocation(line: 7, column: 14, scope: !80)
// CHECK:STDOUT: !85 = !DILocation(line: 8, column: 3, scope: !80)
// CHECK:STDOUT: !86 = !DILocation(line: 8, column: 14, scope: !80)
// CHECK:STDOUT: !87 = !DILocation(line: 6, column: 1, scope: !80)
// CHECK:STDOUT: !88 = !{!81}
// CHECK:STDOUT: !89 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.4954785a8b134801:core.Destroy.Core", scope: null, file: !73, line: 7, type: !79, spFlags: DISPFlagDefinition, unit: !74, retainedNodes: !92)
// CHECK:STDOUT: !90 = !DILocalVariable(arg: 1, scope: !89, type: !75)
// CHECK:STDOUT: !91 = !DILocation(line: 7, column: 14, scope: !89)
// CHECK:STDOUT: !92 = !{!90}
// CHECK:STDOUT: !93 = !{!"p1 _ZTS9NeedThunk", !36, i64 0}
// CHECK:STDOUT: !94 = !{!93, !93, i64 0}
// CHECK:STDOUT: !95 = !{!"p1 omnipotent char", !36, i64 0}
// CHECK:STDOUT: !96 = !{!95, !95, i64 0}
// CHECK:STDOUT: !98 = !{!35, !35, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'call_with_ref_self.carbon'
// CHECK:STDOUT: source_filename = "call_with_ref_self.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [78 x i8] c"carbon: C++ exception escaped into Carbon through `RefSelfA::f`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CF.Main(ptr %r) #0 !dbg !103 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN8RefSelfA1fEii.carbon_thunk.r__(ptr %r, i32 1, i32 2), !dbg !106
// CHECK:STDOUT:   ret void, !dbg !107
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN8RefSelfA1fEii.carbon_thunk.r__(ptr noundef nonnull align 1 dereferenceable(1) %this, i32 noundef %x, i32 noundef %y) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %x.addr = alloca i32, align 4
// CHECK:STDOUT:   %y.addr = alloca i32, align 4
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !110
// CHECK:STDOUT:   store i32 %x, ptr %x.addr, align 4, !tbaa !111
// CHECK:STDOUT:   store i32 %y, ptr %y.addr, align 4, !tbaa !111
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !110, !nonnull !40
// CHECK:STDOUT:   %1 = load i32, ptr %x.addr, align 4, !tbaa !111
// CHECK:STDOUT:   %2 = load i32, ptr %y.addr, align 4, !tbaa !111
// CHECK:STDOUT:   invoke void @_ZN8RefSelfA1fEii(ptr noundef nonnull align 1 dereferenceable(1) %0, i32 noundef %1, i32 noundef %2)
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
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #5
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %7 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %8 = extractvalue { ptr, i32 } %7, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %8) #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZN8RefSelfA1fEii(ptr noundef nonnull align 1 dereferenceable(1), i32 noundef, i32 noundef) #2
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
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #3 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noreturn }
// CHECK:STDOUT: attributes #6 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!100}
// CHECK:STDOUT: !llvm.module.flags = !{!49, !50, !51, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!53}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !21 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !24 = !{null, !21}
// CHECK:STDOUT: !25 = !DISubroutineType(types: !24)
// CHECK:STDOUT: !34 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !35 = !{!"omnipotent char", !34, i64 0}
// CHECK:STDOUT: !36 = !{!"any pointer", !35, i64 0}
// CHECK:STDOUT: !40 = !{}
// CHECK:STDOUT: !46 = !{!"int", !35, i64 0}
// CHECK:STDOUT: !49 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !50 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !51 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !52 = !{!"__libc_errno", !46, i64 0}
// CHECK:STDOUT: !53 = !{!52, !46, i64 0}
// CHECK:STDOUT: !99 = !DIFile(filename: "call_with_ref_self.carbon", directory: "")
// CHECK:STDOUT: !100 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !99, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !103 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !99, line: 11, type: !25, spFlags: DISPFlagDefinition, unit: !100, retainedNodes: !108)
// CHECK:STDOUT: !104 = !DILocalVariable(arg: 1, scope: !103, type: !21)
// CHECK:STDOUT: !106 = !DILocation(line: 12, column: 3, scope: !103)
// CHECK:STDOUT: !107 = !DILocation(line: 11, column: 1, scope: !103)
// CHECK:STDOUT: !108 = !{!104}
// CHECK:STDOUT: !109 = !{!"p1 _ZTS8RefSelfA", !36, i64 0}
// CHECK:STDOUT: !110 = !{!109, !109, i64 0}
// CHECK:STDOUT: !111 = !{!46, !46, i64 0}
// CHECK:STDOUT:

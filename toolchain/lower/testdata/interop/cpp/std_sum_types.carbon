// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/std_sum_types.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/std_sum_types.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md §1, F-020): the conversions as
// LLVM IR: the C++ object keeps libc++'s layout in its own alloca and is read
// only through the accessor thunks; the Carbon sum type is a separate alloca
// of the `choice` layout (`<{ <{ i1, [3 x i8] }>, [4 x i8] }>` for
// `StdOptional(i32)`), written by `Some`'s constructor or the `None`
// constant's copy; the reverse builds the C++ object by its default
// constructor and `emplace`.

// --- sum.h

// Mocks of libc++'s `std::optional` and `std::variant`, as string_view.carbon
// and span.carbon mock theirs, so the goldens are hermetic: the members the
// conversions call (`has_value`, `value`, `emplace`, `index`, `std::get`),
// libc++'s inline namespace, and `size_t` pinned by `--target`.
namespace std {
  using size_t = __SIZE_TYPE__;

  inline namespace __1 {
    template <typename T>
    class optional {
     public:
      optional() : value_(), engaged_(false) {}
      optional(T value) : value_(value), engaged_(true) {}
      bool has_value() const { return engaged_; }
      const T& value() const { return value_; }
      template <typename... A>
      T& emplace(A&&... args) {
        value_ = T(args...);
        engaged_ = true;
        return value_;
      }

     private:
      T value_;
      bool engaged_;
    };

    struct monostate {};

    template <typename... Ts>
    class variant {
     public:
      variant() : index_(0) { emplace<0>(); }
      size_t index() const { return index_; }
      template <size_t I, typename... A>
      __type_pack_element<I, Ts...>& emplace(A&&... args) {
        index_ = I;
        auto* p = reinterpret_cast<__type_pack_element<I, Ts...>*>(storage_);
        *p = __type_pack_element<I, Ts...>(args...);
        return *p;
      }
      alignas(8) unsigned char storage_[8];
      size_t index_;
    };

    template <size_t I, typename... Ts>
    const __type_pack_element<I, Ts...>& get(const variant<Ts...>& v) {
      return *reinterpret_cast<const __type_pack_element<I, Ts...>*>(
          v.storage_);
    }
  }
}

inline auto MakeOptional(int n) -> std::optional<int> {
  if (n > 0) return std::optional<int>(n);
  return std::optional<int>();
}

inline auto IntOrHalf(int n) -> std::variant<int, double> {
  std::variant<int, double> v;
  if (n > 0) {
    v.emplace<0>(n);
  } else {
    v.emplace<1>(n * 0.5);
  }
  return v;
}

inline auto Take(std::optional<int> o) -> int {
  return o.has_value() ? o.value() : -1;
}

inline auto TakeVariant(std::variant<int, double> v) -> int {
  return static_cast<int>(v.index());
}

// --- optional.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

fn F(n: i32) -> i32 {
  match (Cpp.MakeOptional(n)) {
    case .Some(v: i32) => {
      return v;
    }
    case .None => {
      return -1;
    }
  }
  return -2;
}

fn G(n: i32) -> i32 {
  return Cpp.Take(Core.CppCompat.StdOptional(i32).Some(n));
}

// --- variant.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

fn H(n: i32) -> i32 {
  match (Cpp.IntOrHalf(n)) {
    case .Alt0(i: i32) => {
      return i;
    }
    case .Alt1(unused d: f64) => {
      return -1;
    }
  }
  return -2;
}

fn K(d: f64) -> i32 {
  return Cpp.TakeVariant(Core.CppCompat.StdVariant2(i32, f64).Alt1(d));
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'optional.carbon'
// CHECK:STDOUT: source_filename = "optional.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %"class.std::__1::optional" = type <{ i32, i8, [3 x i8] }>
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z12MakeOptionali = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZNSt3__18optionalIiEC2Ei = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZNSt3__18optionalIiEC2Ev = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZNKSt3__18optionalIiE9has_valueEv = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZNKSt3__18optionalIiE5valueEv = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z4TakeNSt3__18optionalIiEE = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZNSt3__18optionalIiE7emplaceIJiEEERiDpT_ = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @StdOptional.val.f8e = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @StdOptional.val.f8e.Copy.WithSelf.Op.call = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> <{ <{ i1, [3 x i8] }> <{ i1 true, [3 x i8] zeroinitializer }>, [4 x i8] zeroinitializer }>
// CHECK:STDOUT: @StdOptional.val.38d.anon = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }> zeroinitializer
// CHECK:STDOUT: @.str = private unnamed_addr constant [79 x i8] c"carbon: C++ exception escaped into Carbon through `MakeOptional`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [96 x i8] c"carbon: C++ exception escaped into Carbon through `std::optional<int>::has_value`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.2 = private unnamed_addr constant [92 x i8] c"carbon: C++ exception escaped into Carbon through `std::optional<int>::value`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.3 = private unnamed_addr constant [71 x i8] c"carbon: C++ exception escaped into Carbon through `Take`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.4 = private unnamed_addr constant [95 x i8] c"carbon: C++ exception escaped into Carbon through `std::optional<int>::optional`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.5 = private unnamed_addr constant [94 x i8] c"carbon: C++ exception escaped into Carbon through `std::optional<int>::emplace`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CF.Main(i32 %n) #0 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_28.1.temp = alloca [8 x i8], align 4, !dbg !33
// CHECK:STDOUT:   %.loc7_29.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !34
// CHECK:STDOUT:   %.loc7_29.2.temp = alloca i1, align 1, !dbg !34
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc7_28.1.temp), !dbg !33
// CHECK:STDOUT:   call void @_Z12MakeOptionali.carbon_thunk._(i32 %n, ptr %.loc7_28.1.temp), !dbg !33
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc7_29.1.temp), !dbg !34
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc7_29.2.temp), !dbg !34
// CHECK:STDOUT:   call void @_ZNKSt3__18optionalIiE9has_valueEv.carbon_thunk._(ptr %.loc7_28.1.temp, ptr %.loc7_29.2.temp), !dbg !34
// CHECK:STDOUT:   %.loc7_29.5 = load i8, ptr %.loc7_29.2.temp, align 1, !dbg !34
// CHECK:STDOUT:   %.loc7_29.51 = trunc i8 %.loc7_29.5 to i1, !dbg !34
// CHECK:STDOUT:   br i1 %.loc7_29.51, label %.loc7_29.1, label %.loc7_29.2, !dbg !34
// CHECK:STDOUT:
// CHECK:STDOUT: .loc7_29.1:                                       ; preds = %entry
// CHECK:STDOUT:   %value__carbon_thunk.call = call ptr @_ZNKSt3__18optionalIiE5valueEv.carbon_thunk._(ptr %.loc7_28.1.temp), !dbg !34
// CHECK:STDOUT:   %.loc7_29.10 = load i32, ptr %value__carbon_thunk.call, align 4, !dbg !34
// CHECK:STDOUT:   call void @_CSome.StdOptional.CppCompat.Core.84588f41d61dafba(ptr %.loc7_29.1.temp, i32 %.loc7_29.10), !dbg !34
// CHECK:STDOUT:   br label %.loc7_29.3, !dbg !34
// CHECK:STDOUT:
// CHECK:STDOUT: .loc7_29.2:                                       ; preds = %entry
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %.loc7_29.1.temp, ptr align 4 @StdOptional.val.f8e.Copy.WithSelf.Op.call, i64 8, i1 false), !dbg !34
// CHECK:STDOUT:   br label %.loc7_29.3, !dbg !34
// CHECK:STDOUT:
// CHECK:STDOUT: .loc7_29.3:                                       ; preds = %.loc7_29.2, %.loc7_29.1
// CHECK:STDOUT:   call void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr %.loc7_29.2.temp), !dbg !34
// CHECK:STDOUT:   call void @"_CSelfDestruct.78522c23274fbf77:core.Destroy.Core"(ptr %.loc7_28.1.temp), !dbg !33
// CHECK:STDOUT:   %.loc8_24.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc7_29.1.temp, i32 0, i32 0, !dbg !37
// CHECK:STDOUT:   %.loc8_24.4 = load i8, ptr %.loc8_24.3.discriminant, align 1, !dbg !37
// CHECK:STDOUT:   %.loc8_24.42 = trunc i8 %.loc8_24.4 to i1, !dbg !37
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc8 = icmp eq i1 false, %.loc8_24.42, !dbg !37
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc8, label %match.case.then.loc8, label %match.case.else.loc8, !dbg !37
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc8:                             ; preds = %.loc7_29.3
// CHECK:STDOUT:   %.loc8_24.7.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc7_29.1.temp, i32 0, i32 1, !dbg !37
// CHECK:STDOUT:   %.loc8_24.8.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc8_24.7.payload, i32 0, i32 0, !dbg !37
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc8_24.8.Some, i32 0, i32 0, !dbg !37
// CHECK:STDOUT:   %.loc8_24.9 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !37
// CHECK:STDOUT:   ret i32 %.loc8_24.9, !dbg !40
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc8:                             ; preds = %.loc7_29.3
// CHECK:STDOUT:   %.loc11_16.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc7_29.1.temp, i32 0, i32 0, !dbg !41
// CHECK:STDOUT:   %.loc11_16.4 = load i8, ptr %.loc11_16.3.discriminant, align 1, !dbg !41
// CHECK:STDOUT:   %.loc11_16.43 = trunc i8 %.loc11_16.4 to i1, !dbg !41
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc11 = icmp eq i1 true, %.loc11_16.43, !dbg !41
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc11, label %match.case.then.loc11, label %match.done, !dbg !41
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc11:                            ; preds = %match.case.else.loc8
// CHECK:STDOUT:   ret i32 -1, !dbg !42
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc8
// CHECK:STDOUT:   ret i32 -2, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z12MakeOptionali.carbon_thunk._(i32 noundef %n, ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %n.addr = alloca i32, align 4
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store i32 %n, ptr %n.addr, align 4, !tbaa !115
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !118
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !118
// CHECK:STDOUT:   %1 = load i32, ptr %n.addr, align 4, !tbaa !115
// CHECK:STDOUT:   %call = invoke i64 @_Z12MakeOptionali(i32 noundef %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   %coerce.val.ii = trunc i64 %call to i40
// CHECK:STDOUT:   store i40 %coerce.val.ii, ptr %0, align 4
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 78) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #8
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %7) #9
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZNKSt3__18optionalIiE9has_valueEv.carbon_thunk._(ptr noundef nonnull align 4 dereferenceable(5) %this, ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !118
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !124
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !124
// CHECK:STDOUT:   %1 = load ptr, ptr %this.addr, align 8, !tbaa !118, !nonnull !125, !align !126
// CHECK:STDOUT:   %call = invoke noundef zeroext i1 @_ZNKSt3__18optionalIiE9has_valueEv(ptr noundef nonnull align 4 dereferenceable(5) %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   %storedv = zext i1 %call to i8
// CHECK:STDOUT:   store i8 %storedv, ptr %0, align 1, !tbaa !127
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.1, i64 noundef 95) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #8
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %7) #9
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef nonnull align 4 dereferenceable(4) ptr @_ZNKSt3__18optionalIiE5valueEv.carbon_thunk._(ptr noundef nonnull align 4 dereferenceable(5) %this) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !118
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !118, !nonnull !125, !align !126
// CHECK:STDOUT:   %call = invoke noundef nonnull align 4 dereferenceable(4) ptr @_ZNKSt3__18optionalIiE5valueEv(ptr noundef nonnull align 4 dereferenceable(5) %0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret ptr %call
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.2, i64 noundef 91) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #8
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %6) #9
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr %self) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.78522c23274fbf77:core.Destroy.Core"(ptr %self) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CG.Main(i32 %n) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_57.1.temp = alloca <{ <{ i1, [3 x i8] }>, [4 x i8] }>, align 4, !dbg !60
// CHECK:STDOUT:   %.loc19_57.4.temp = alloca [8 x i8], align 4, !dbg !60
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc19_57.1.temp), !dbg !60
// CHECK:STDOUT:   call void @_CSome.StdOptional.CppCompat.Core.84588f41d61dafba(ptr %.loc19_57.1.temp, i32 %n), !dbg !60
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc19_57.4.temp), !dbg !60
// CHECK:STDOUT:   call void @_ZNSt3__18optionalIiEC1Ev.carbon_thunk.(ptr %.loc19_57.4.temp), !dbg !60
// CHECK:STDOUT:   %.loc19_57.9.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc19_57.1.temp, i32 0, i32 0, !dbg !60
// CHECK:STDOUT:   %.loc19_57.10 = load i8, ptr %.loc19_57.9.discriminant, align 1, !dbg !60
// CHECK:STDOUT:   %.loc19_57.101 = trunc i8 %.loc19_57.10 to i1, !dbg !60
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 false, %.loc19_57.101, !dbg !60
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc19_57.1, label %.loc19_57.2, !dbg !60
// CHECK:STDOUT:
// CHECK:STDOUT: .loc19_57.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc19_57.13.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %.loc19_57.1.temp, i32 0, i32 1, !dbg !60
// CHECK:STDOUT:   %.loc19_57.14.Some = getelementptr inbounds nuw [4 x i8], ptr %.loc19_57.13.payload, i32 0, i32 0, !dbg !60
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc19_57.14.Some, i32 0, i32 0, !dbg !60
// CHECK:STDOUT:   %.loc19_57.15 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !60
// CHECK:STDOUT:   %emplace__carbon_thunk.call = call ptr @_ZNSt3__18optionalIiE7emplaceIJiEEERiDpT_.carbon_thunk.__(ptr %.loc19_57.4.temp, i32 %.loc19_57.15), !dbg !60
// CHECK:STDOUT:   br label %.loc19_57.3, !dbg !60
// CHECK:STDOUT:
// CHECK:STDOUT: .loc19_57.2:                                      ; preds = %entry
// CHECK:STDOUT:   br label %.loc19_57.3, !dbg !60
// CHECK:STDOUT:
// CHECK:STDOUT: .loc19_57.3:                                      ; preds = %.loc19_57.2, %.loc19_57.1
// CHECK:STDOUT:   %Take__carbon_thunk.call = call i32 @_Z4TakeNSt3__18optionalIiEE.carbon_thunk._(ptr %.loc19_57.4.temp), !dbg !61
// CHECK:STDOUT:   call void @"_CSelfDestruct.4c37e5324d6cb627:core.Destroy.Core"(ptr %.loc19_57.1.temp), !dbg !60
// CHECK:STDOUT:   ret i32 %Take__carbon_thunk.call, !dbg !62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_Z4TakeNSt3__18optionalIiEE.carbon_thunk._(ptr noundef %o) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %o.addr = alloca ptr, align 8
// CHECK:STDOUT:   %agg.tmp = alloca %"class.std::__1::optional", align 4
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %o, ptr %o.addr, align 8, !tbaa !118
// CHECK:STDOUT:   %0 = load ptr, ptr %o.addr, align 8, !tbaa !118
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %agg.tmp, ptr align 4 %0, i64 8, i1 false), !tbaa.struct !129
// CHECK:STDOUT:   %1 = load i64, ptr %agg.tmp, align 4
// CHECK:STDOUT:   %call = invoke noundef i32 @_Z4TakeNSt3__18optionalIiEE(i64 %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret i32 %call
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.3, i64 noundef 70) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #8
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %7) #9
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZNSt3__18optionalIiEC1Ev.carbon_thunk.(ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !118
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !118
// CHECK:STDOUT:   invoke void @_ZNSt3__18optionalIiEC2Ev(ptr noundef nonnull align 4 dereferenceable(5) %0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
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
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.4, i64 noundef 94) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #8
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %6) #9
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef nonnull align 4 dereferenceable(4) ptr @_ZNSt3__18optionalIiE7emplaceIJiEEERiDpT_.carbon_thunk.__(ptr noundef nonnull align 4 dereferenceable(5) %this, i32 noundef %args) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %args.addr = alloca i32, align 4
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !118
// CHECK:STDOUT:   store i32 %args, ptr %args.addr, align 4, !tbaa !115
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !118, !nonnull !125, !align !126
// CHECK:STDOUT:   %1 = load i32, ptr %args.addr, align 4, !tbaa !115
// CHECK:STDOUT:   %call = invoke noundef nonnull align 4 dereferenceable(4) ptr @_ZNSt3__18optionalIiE7emplaceIJiEEERiDpT_(ptr noundef nonnull align 4 dereferenceable(5) %0, i32 noundef %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret ptr %call
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.5, i64 noundef 93) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #8
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %7) #9
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !64 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !68 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !74
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !74
// CHECK:STDOUT:   ret void, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !76 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !78
// CHECK:STDOUT:   ret void, !dbg !78
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e8ee17acba240768:core.Destroy.Core"(ptr %self) #0 !dbg !80 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !82
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e8ee17acba240768:core.Destroy.Core"(ptr %self) #0 !dbg !84 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e8ee17acba240768:core.Destroy.Core"(ptr %self), !dbg !86
// CHECK:STDOUT:   ret void, !dbg !86
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e994aeee33fac1a0:core.Destroy.Core"(ptr %self) #0 !dbg !88 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_57.1.payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 1, !dbg !90
// CHECK:STDOUT:   call void @"_CSelfDestruct.e8ee17acba240768:core.Destroy.Core"(ptr %.loc19_57.1.payload), !dbg !90
// CHECK:STDOUT:   %.loc19_57.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %self, i32 0, i32 0, !dbg !90
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc19_57.2.discriminant), !dbg !90
// CHECK:STDOUT:   ret void, !dbg !90
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e994aeee33fac1a0:core.Destroy.Core"(ptr %self) #0 !dbg !92 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e994aeee33fac1a0:core.Destroy.Core"(ptr %self), !dbg !94
// CHECK:STDOUT:   ret void, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.4c37e5324d6cb627:core.Destroy.Core"(ptr %self) #0 !dbg !96 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !98
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.4c37e5324d6cb627:core.Destroy.Core"(ptr %self) #0 !dbg !100 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.4c37e5324d6cb627:core.Destroy.Core"(ptr %self), !dbg !102
// CHECK:STDOUT:   ret void, !dbg !102
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSome.StdOptional.CppCompat.Core.84588f41d61dafba(ptr sret(<{ <{ i1, [3 x i8] }>, [4 x i8] }>) %return, i32 %_) #0 !dbg !107 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 0, !dbg !109
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [3 x i8] }>, [4 x i8] }>, ptr %return, i32 0, i32 1, !dbg !109
// CHECK:STDOUT:   %Some = getelementptr inbounds nuw [4 x i8], ptr %payload, i32 0, i32 0, !dbg !109
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !110
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @StdOptional.val.38d.anon, i64 8, i1 false), !dbg !109
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Some, align 4, !dbg !109
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Some, i32 0, i32 0, !dbg !110
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !110
// CHECK:STDOUT:   ret void, !dbg !109
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: inlinehint mustprogress uwtable
// CHECK:STDOUT: define linkonce_odr dso_local i64 @_Z12MakeOptionali(i32 noundef %n) #3 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca %"class.std::__1::optional", align 4
// CHECK:STDOUT:   %n.addr = alloca i32, align 4
// CHECK:STDOUT:   store i32 %n, ptr %n.addr, align 4, !tbaa !115
// CHECK:STDOUT:   %0 = load i32, ptr %n.addr, align 4, !tbaa !115
// CHECK:STDOUT:   %cmp = icmp sgt i32 %0, 0
// CHECK:STDOUT:   br i1 %cmp, label %if.then, label %if.end
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %1 = load i32, ptr %n.addr, align 4, !tbaa !115
// CHECK:STDOUT:   call void @_ZNSt3__18optionalIiEC2Ei(ptr noundef nonnull align 4 dereferenceable(5) %retval, i32 noundef %1)
// CHECK:STDOUT:   br label %return
// CHECK:STDOUT:
// CHECK:STDOUT: if.end:                                           ; preds = %entry
// CHECK:STDOUT:   call void @_ZNSt3__18optionalIiEC2Ev(ptr noundef nonnull align 4 dereferenceable(5) %retval)
// CHECK:STDOUT:   br label %return
// CHECK:STDOUT:
// CHECK:STDOUT: return:                                           ; preds = %if.end, %if.then
// CHECK:STDOUT:   %2 = load i64, ptr %retval, align 4
// CHECK:STDOUT:   ret i64 %2
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
// CHECK:STDOUT:   call void @_ZSt9terminatev() #9
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local void @_ZNSt3__18optionalIiEC2Ei(ptr noundef nonnull align 4 dereferenceable(5) %this, i32 noundef %value) unnamed_addr #6 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %value.addr = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !118
// CHECK:STDOUT:   store i32 %value, ptr %value.addr, align 4, !tbaa !115
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %value_ = getelementptr inbounds nuw %"class.std::__1::optional", ptr %this1, i32 0, i32 0
// CHECK:STDOUT:   %0 = load i32, ptr %value.addr, align 4, !tbaa !115
// CHECK:STDOUT:   store i32 %0, ptr %value_, align 4, !tbaa !121
// CHECK:STDOUT:   %engaged_ = getelementptr inbounds nuw %"class.std::__1::optional", ptr %this1, i32 0, i32 1
// CHECK:STDOUT:   store i8 1, ptr %engaged_, align 4, !tbaa !122
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local void @_ZNSt3__18optionalIiEC2Ev(ptr noundef nonnull align 4 dereferenceable(5) %this) unnamed_addr #6 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !118
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %value_ = getelementptr inbounds nuw %"class.std::__1::optional", ptr %this1, i32 0, i32 0
// CHECK:STDOUT:   store i32 0, ptr %value_, align 4, !tbaa !121
// CHECK:STDOUT:   %engaged_ = getelementptr inbounds nuw %"class.std::__1::optional", ptr %this1, i32 0, i32 1
// CHECK:STDOUT:   store i8 0, ptr %engaged_, align 4, !tbaa !122
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef zeroext i1 @_ZNKSt3__18optionalIiE9has_valueEv(ptr noundef nonnull align 4 dereferenceable(5) %this) #6 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !118
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %engaged_ = getelementptr inbounds nuw %"class.std::__1::optional", ptr %this1, i32 0, i32 1
// CHECK:STDOUT:   %0 = load i8, ptr %engaged_, align 4, !tbaa !122, !range !128, !noundef !125
// CHECK:STDOUT:   %loadedv = trunc i8 %0 to i1
// CHECK:STDOUT:   ret i1 %loadedv
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef nonnull align 4 dereferenceable(4) ptr @_ZNKSt3__18optionalIiE5valueEv(ptr noundef nonnull align 4 dereferenceable(5) %this) #6 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !118
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %value_ = getelementptr inbounds nuw %"class.std::__1::optional", ptr %this1, i32 0, i32 0
// CHECK:STDOUT:   ret ptr %value_
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: inlinehint mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef i32 @_Z4TakeNSt3__18optionalIiEE(i64 %o.coerce) #7 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %o = alloca %"class.std::__1::optional", align 4
// CHECK:STDOUT:   store i64 %o.coerce, ptr %o, align 4
// CHECK:STDOUT:   %call = call noundef zeroext i1 @_ZNKSt3__18optionalIiE9has_valueEv(ptr noundef nonnull align 4 dereferenceable(5) %o)
// CHECK:STDOUT:   br i1 %call, label %cond.true, label %cond.false
// CHECK:STDOUT:
// CHECK:STDOUT: cond.true:                                        ; preds = %entry
// CHECK:STDOUT:   %call1 = call noundef nonnull align 4 dereferenceable(4) ptr @_ZNKSt3__18optionalIiE5valueEv(ptr noundef nonnull align 4 dereferenceable(5) %o)
// CHECK:STDOUT:   %0 = load i32, ptr %call1, align 4, !tbaa !115
// CHECK:STDOUT:   br label %cond.end
// CHECK:STDOUT:
// CHECK:STDOUT: cond.false:                                       ; preds = %entry
// CHECK:STDOUT:   br label %cond.end
// CHECK:STDOUT:
// CHECK:STDOUT: cond.end:                                         ; preds = %cond.false, %cond.true
// CHECK:STDOUT:   %cond = phi i32 [ %0, %cond.true ], [ -1, %cond.false ]
// CHECK:STDOUT:   ret i32 %cond
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef nonnull align 4 dereferenceable(4) ptr @_ZNSt3__18optionalIiE7emplaceIJiEEERiDpT_(ptr noundef nonnull align 4 dereferenceable(5) %this, i32 noundef %args) #6 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %args.addr = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !118
// CHECK:STDOUT:   store i32 %args, ptr %args.addr, align 4, !tbaa !115
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %0 = load i32, ptr %args.addr, align 4, !tbaa !115
// CHECK:STDOUT:   %value_ = getelementptr inbounds nuw %"class.std::__1::optional", ptr %this1, i32 0, i32 0
// CHECK:STDOUT:   store i32 %0, ptr %value_, align 4, !tbaa !121
// CHECK:STDOUT:   %engaged_ = getelementptr inbounds nuw %"class.std::__1::optional", ptr %this1, i32 0, i32 1
// CHECK:STDOUT:   store i8 1, ptr %engaged_, align 4, !tbaa !122
// CHECK:STDOUT:   %value_2 = getelementptr inbounds nuw %"class.std::__1::optional", ptr %this1, i32 0, i32 0
// CHECK:STDOUT:   ret ptr %value_2
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CSome.StdOptional.CppCompat.Core.84588f41d61dafba, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 2, 0, 1 }
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_begin_catch, { 5, 6, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_rethrow, { 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_ZNSt3__18optionalIiEC2Ev, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { inlinehint mustprogress uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #7 = { inlinehint mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #8 = { noreturn }
// CHECK:STDOUT: attributes #9 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!130, !131, !132, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!134}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "optional.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !8 = !{!6, !6}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !17 = !{null, !10}
// CHECK:STDOUT: !18 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !23 = !{null, !7}
// CHECK:STDOUT: !24 = !DISubroutineType(types: !23)
// CHECK:STDOUT: !25 = !{null, !6}
// CHECK:STDOUT: !26 = !DISubroutineType(types: !25)
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !4, line: 6, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !45)
// CHECK:STDOUT: !28 = !DILocalVariable(arg: 1, scope: !27, type: !6)
// CHECK:STDOUT: !33 = !DILocation(line: 7, column: 10, scope: !27)
// CHECK:STDOUT: !34 = !DILocation(line: 7, column: 9, scope: !27)
// CHECK:STDOUT: !35 = !{!10, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !37 = !DILocation(line: 8, column: 5, scope: !27)
// CHECK:STDOUT: !40 = !DILocation(line: 9, column: 7, scope: !27)
// CHECK:STDOUT: !41 = !DILocation(line: 11, column: 5, scope: !27)
// CHECK:STDOUT: !42 = !DILocation(line: 12, column: 7, scope: !27)
// CHECK:STDOUT: !44 = !DILocation(line: 15, column: 3, scope: !27)
// CHECK:STDOUT: !45 = !{!28}
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core", scope: null, file: !4, line: 7, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !49)
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !46, type: !10)
// CHECK:STDOUT: !48 = !DILocation(line: 7, column: 9, scope: !46)
// CHECK:STDOUT: !49 = !{!47}
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.78522c23274fbf77:core.Destroy.Core", scope: null, file: !4, line: 7, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !53)
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 1, scope: !50, type: !10)
// CHECK:STDOUT: !52 = !DILocation(line: 7, column: 10, scope: !50)
// CHECK:STDOUT: !53 = !{!51}
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !63)
// CHECK:STDOUT: !55 = !DILocalVariable(arg: 1, scope: !54, type: !6)
// CHECK:STDOUT: !60 = !DILocation(line: 19, column: 19, scope: !54)
// CHECK:STDOUT: !61 = !DILocation(line: 19, column: 10, scope: !54)
// CHECK:STDOUT: !62 = !DILocation(line: 19, column: 3, scope: !54)
// CHECK:STDOUT: !63 = !{!55}
// CHECK:STDOUT: !64 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !4, line: 19, type: !24, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !67)
// CHECK:STDOUT: !65 = !DILocalVariable(arg: 1, scope: !64, type: !7)
// CHECK:STDOUT: !66 = !DILocation(line: 19, column: 19, scope: !64)
// CHECK:STDOUT: !67 = !{!65}
// CHECK:STDOUT: !68 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 19, type: !26, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !71)
// CHECK:STDOUT: !69 = !DILocalVariable(arg: 1, scope: !68, type: !6)
// CHECK:STDOUT: !70 = !DILocation(line: 19, column: 19, scope: !68)
// CHECK:STDOUT: !71 = !{!69}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !75)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !10)
// CHECK:STDOUT: !74 = !DILocation(line: 19, column: 19, scope: !72)
// CHECK:STDOUT: !75 = !{!73}
// CHECK:STDOUT: !76 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !4, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !79)
// CHECK:STDOUT: !77 = !DILocalVariable(arg: 1, scope: !76, type: !10)
// CHECK:STDOUT: !78 = !DILocation(line: 19, column: 19, scope: !76)
// CHECK:STDOUT: !79 = !{!77}
// CHECK:STDOUT: !80 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e8ee17acba240768:core.Destroy.Core", scope: null, file: !4, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !83)
// CHECK:STDOUT: !81 = !DILocalVariable(arg: 1, scope: !80, type: !10)
// CHECK:STDOUT: !82 = !DILocation(line: 19, column: 19, scope: !80)
// CHECK:STDOUT: !83 = !{!81}
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e8ee17acba240768:core.Destroy.Core", scope: null, file: !4, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !87)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !84, type: !10)
// CHECK:STDOUT: !86 = !DILocation(line: 19, column: 19, scope: !84)
// CHECK:STDOUT: !87 = !{!85}
// CHECK:STDOUT: !88 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e994aeee33fac1a0:core.Destroy.Core", scope: null, file: !4, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !91)
// CHECK:STDOUT: !89 = !DILocalVariable(arg: 1, scope: !88, type: !10)
// CHECK:STDOUT: !90 = !DILocation(line: 19, column: 19, scope: !88)
// CHECK:STDOUT: !91 = !{!89}
// CHECK:STDOUT: !92 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e994aeee33fac1a0:core.Destroy.Core", scope: null, file: !4, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !95)
// CHECK:STDOUT: !93 = !DILocalVariable(arg: 1, scope: !92, type: !10)
// CHECK:STDOUT: !94 = !DILocation(line: 19, column: 19, scope: !92)
// CHECK:STDOUT: !95 = !{!93}
// CHECK:STDOUT: !96 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.4c37e5324d6cb627:core.Destroy.Core", scope: null, file: !4, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !99)
// CHECK:STDOUT: !97 = !DILocalVariable(arg: 1, scope: !96, type: !10)
// CHECK:STDOUT: !98 = !DILocation(line: 19, column: 19, scope: !96)
// CHECK:STDOUT: !99 = !{!97}
// CHECK:STDOUT: !100 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.4c37e5324d6cb627:core.Destroy.Core", scope: null, file: !4, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !103)
// CHECK:STDOUT: !101 = !DILocalVariable(arg: 1, scope: !100, type: !10)
// CHECK:STDOUT: !102 = !DILocation(line: 19, column: 19, scope: !100)
// CHECK:STDOUT: !103 = !{!101}
// CHECK:STDOUT: !106 = !DIFile(filename: "{{.*}}/prelude/types/cpp/sum.carbon", directory: "")
// CHECK:STDOUT: !107 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.StdOptional.CppCompat.Core.84588f41d61dafba", scope: null, file: !106, line: 30, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !111)
// CHECK:STDOUT: !108 = !DILocalVariable(arg: 1, scope: !107, type: !6)
// CHECK:STDOUT: !109 = !DILocation(line: 30, column: 1, scope: !107)
// CHECK:STDOUT: !110 = !DILocation(line: 31, column: 17, scope: !107)
// CHECK:STDOUT: !111 = !{!108}
// CHECK:STDOUT: !112 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !113 = !{!"omnipotent char", !112, i64 0}
// CHECK:STDOUT: !114 = !{!"int", !113, i64 0}
// CHECK:STDOUT: !115 = !{!114, !114, i64 0}
// CHECK:STDOUT: !116 = !{!"any pointer", !113, i64 0}
// CHECK:STDOUT: !117 = !{!"p1 _ZTSNSt3__18optionalIiEE", !116, i64 0}
// CHECK:STDOUT: !118 = !{!117, !117, i64 0}
// CHECK:STDOUT: !119 = !{!"bool", !113, i64 0}
// CHECK:STDOUT: !120 = !{!"_ZTSNSt3__18optionalIiEE", !114, i64 0, !119, i64 4}
// CHECK:STDOUT: !121 = !{!120, !114, i64 0}
// CHECK:STDOUT: !122 = !{!120, !119, i64 4}
// CHECK:STDOUT: !123 = !{!"p1 bool", !116, i64 0}
// CHECK:STDOUT: !124 = !{!123, !123, i64 0}
// CHECK:STDOUT: !125 = !{}
// CHECK:STDOUT: !126 = !{i64 4}
// CHECK:STDOUT: !127 = !{!119, !119, i64 0}
// CHECK:STDOUT: !128 = !{i8 0, i8 2}
// CHECK:STDOUT: !129 = !{i64 0, i64 4, !115, i64 4, i64 1, !127}
// CHECK:STDOUT: !130 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !131 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !132 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !133 = !{!"__libc_errno", !114, i64 0}
// CHECK:STDOUT: !134 = !{!133, !114, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'variant.carbon'
// CHECK:STDOUT: source_filename = "variant.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %"class.std::__1::variant" = type { [8 x i8], i64 }
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z9IntOrHalfi = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZNSt3__17variantIJidEEC2Ev = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZNSt3__17variantIJidEE7emplaceILm0EJiEEER19__type_pack_elementIXT_EJidEEDpT0_ = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZNSt3__17variantIJidEE7emplaceILm1EJdEEER19__type_pack_elementIXT_EJidEEDpT0_ = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZNSt3__17variantIJidEE7emplaceILm0EJEEER19__type_pack_elementIXT_EJidEEDpT0_ = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZNKSt3__17variantIJidEE5indexEv = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZNSt3__13getILm0EJidEEERK19__type_pack_elementIXT_EJDpT0_EERKNS_7variantIJS3_EEE = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZNSt3__13getILm1EJidEEERK19__type_pack_elementIXT_EJDpT0_EERKNS_7variantIJS3_EEE = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z11TakeVariantNSt3__17variantIJidEEE = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @StdVariant2.val.9d9.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> zeroinitializer
// CHECK:STDOUT: @StdVariant2.val.622.anon = internal constant <{ <{ i1, [7 x i8] }>, [8 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @.str = private unnamed_addr constant [76 x i8] c"carbon: C++ exception escaped into Carbon through `IntOrHalf`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [99 x i8] c"carbon: C++ exception escaped into Carbon through `std::variant<int, double>::index`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.2 = private unnamed_addr constant [75 x i8] c"carbon: C++ exception escaped into Carbon through `std::get`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.3 = private unnamed_addr constant [78 x i8] c"carbon: C++ exception escaped into Carbon through `TakeVariant`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.4 = private unnamed_addr constant [101 x i8] c"carbon: C++ exception escaped into Carbon through `std::variant<int, double>::variant`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CH.Main(i32 %n) #0 !dbg !143 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_25.1.temp = alloca [16 x i8], align 8, !dbg !149
// CHECK:STDOUT:   %.loc7_26.1.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !150
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc7_25.1.temp), !dbg !149
// CHECK:STDOUT:   call void @_Z9IntOrHalfi.carbon_thunk._(i32 %n, ptr %.loc7_25.1.temp), !dbg !149
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc7_26.1.temp), !dbg !150
// CHECK:STDOUT:   %index__carbon_thunk.call = call i64 @_ZNKSt3__17variantIJidEE5indexEv.carbon_thunk._(ptr %.loc7_25.1.temp), !dbg !150
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc7 = icmp eq i64 %index__carbon_thunk.call, 0, !dbg !150
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc7, label %.loc7_26.1, label %.loc7_26.2, !dbg !150
// CHECK:STDOUT:
// CHECK:STDOUT: .loc7_26.1:                                       ; preds = %entry
// CHECK:STDOUT:   %get__carbon_thunk.call.loc7_26.1 = call ptr @_ZNSt3__13getILm0EJidEEERK19__type_pack_elementIXT_EJDpT0_EERKNS_7variantIJS3_EEE.carbon_thunk._(ptr %.loc7_25.1.temp), !dbg !150
// CHECK:STDOUT:   %.loc7_26.16 = load i32, ptr %get__carbon_thunk.call.loc7_26.1, align 4, !dbg !150
// CHECK:STDOUT:   call void @_CAlt0.StdVariant2.CppCompat.Core.0cbc347ce64f83a1(ptr %.loc7_26.1.temp, i32 %.loc7_26.16), !dbg !150
// CHECK:STDOUT:   br label %.loc7_26.3, !dbg !150
// CHECK:STDOUT:
// CHECK:STDOUT: .loc7_26.2:                                       ; preds = %entry
// CHECK:STDOUT:   %get__carbon_thunk.call.loc7_26.2 = call ptr @_ZNSt3__13getILm1EJidEEERK19__type_pack_elementIXT_EJDpT0_EERKNS_7variantIJS3_EEE.carbon_thunk._(ptr %.loc7_25.1.temp), !dbg !150
// CHECK:STDOUT:   %.loc7_26.25 = load double, ptr %get__carbon_thunk.call.loc7_26.2, align 8, !dbg !150
// CHECK:STDOUT:   call void @_CAlt1.StdVariant2.CppCompat.Core.0cbc347ce64f83a1(ptr %.loc7_26.1.temp, double %.loc7_26.25), !dbg !150
// CHECK:STDOUT:   br label %.loc7_26.3, !dbg !150
// CHECK:STDOUT:
// CHECK:STDOUT: .loc7_26.3:                                       ; preds = %.loc7_26.2, %.loc7_26.1
// CHECK:STDOUT:   call void @"_CSelfDestruct.097ead33ecab8068:core.Destroy.Core"(ptr %.loc7_25.1.temp), !dbg !149
// CHECK:STDOUT:   %.loc8_24.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc7_26.1.temp, i32 0, i32 0, !dbg !151
// CHECK:STDOUT:   %.loc8_24.4 = load i8, ptr %.loc8_24.3.discriminant, align 1, !dbg !151
// CHECK:STDOUT:   %.loc8_24.41 = trunc i8 %.loc8_24.4 to i1, !dbg !151
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc8 = icmp eq i1 false, %.loc8_24.41, !dbg !151
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc8, label %match.case.then.loc8, label %match.case.else.loc8, !dbg !151
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc8:                             ; preds = %.loc7_26.3
// CHECK:STDOUT:   %.loc8_24.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc7_26.1.temp, i32 0, i32 1, !dbg !151
// CHECK:STDOUT:   %.loc8_24.8.Alt0 = getelementptr inbounds nuw [8 x i8], ptr %.loc8_24.7.payload, i32 0, i32 0, !dbg !151
// CHECK:STDOUT:   %tuple.elem0.loc8.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc8_24.8.Alt0, i32 0, i32 0, !dbg !151
// CHECK:STDOUT:   %.loc8_24.9 = load i32, ptr %tuple.elem0.loc8.tuple.elem, align 4, !dbg !151
// CHECK:STDOUT:   ret i32 %.loc8_24.9, !dbg !154
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else.loc8:                             ; preds = %.loc7_26.3
// CHECK:STDOUT:   %.loc11_31.3.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc7_26.1.temp, i32 0, i32 0, !dbg !155
// CHECK:STDOUT:   %.loc11_31.4 = load i8, ptr %.loc11_31.3.discriminant, align 1, !dbg !155
// CHECK:STDOUT:   %.loc11_31.42 = trunc i8 %.loc11_31.4 to i1, !dbg !155
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc11 = icmp eq i1 true, %.loc11_31.42, !dbg !155
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call.loc11, label %match.case.then.loc11, label %match.done, !dbg !155
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then.loc11:                            ; preds = %match.case.else.loc8
// CHECK:STDOUT:   %.loc11_31.7.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc7_26.1.temp, i32 0, i32 1, !dbg !155
// CHECK:STDOUT:   %.loc11_31.8.Alt1 = getelementptr inbounds nuw [8 x i8], ptr %.loc11_31.7.payload, i32 0, i32 0, !dbg !155
// CHECK:STDOUT:   %tuple.elem0.loc11.tuple.elem = getelementptr inbounds nuw { double }, ptr %.loc11_31.8.Alt1, i32 0, i32 0, !dbg !155
// CHECK:STDOUT:   %.loc11_31.9 = load double, ptr %tuple.elem0.loc11.tuple.elem, align 8, !dbg !155
// CHECK:STDOUT:   ret i32 -1, !dbg !157
// CHECK:STDOUT:
// CHECK:STDOUT: match.done:                                       ; preds = %match.case.else.loc8
// CHECK:STDOUT:   ret i32 -2, !dbg !159
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z9IntOrHalfi.carbon_thunk._(i32 noundef %n, ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %n.addr = alloca i32, align 4
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store i32 %n, ptr %n.addr, align 4, !tbaa !115
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !237
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !237
// CHECK:STDOUT:   %1 = load i32, ptr %n.addr, align 4, !tbaa !115
// CHECK:STDOUT:   %call = invoke { i64, i64 } @_Z9IntOrHalfi(i32 noundef %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   %2 = getelementptr inbounds nuw { i64, i64 }, ptr %0, i32 0, i32 0
// CHECK:STDOUT:   %3 = extractvalue { i64, i64 } %call, 0
// CHECK:STDOUT:   store i64 %3, ptr %2, align 8
// CHECK:STDOUT:   %4 = getelementptr inbounds nuw { i64, i64 }, ptr %0, i32 0, i32 1
// CHECK:STDOUT:   %5 = extractvalue { i64, i64 } %call, 1
// CHECK:STDOUT:   store i64 %5, ptr %4, align 8
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 75) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #9
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %10 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %11 = extractvalue { ptr, i32 } %10, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %11) #10
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i64 @_ZNKSt3__17variantIJidEE5indexEv.carbon_thunk._(ptr noundef nonnull align 8 dereferenceable(16) %this) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !237
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !237, !nonnull !125, !align !247
// CHECK:STDOUT:   %call = invoke noundef i64 @_ZNKSt3__17variantIJidEE5indexEv(ptr noundef nonnull align 8 dereferenceable(16) %0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret i64 %call
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.1, i64 noundef 98) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #9
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %6) #10
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef nonnull align 4 dereferenceable(4) ptr @_ZNSt3__13getILm0EJidEEERK19__type_pack_elementIXT_EJDpT0_EERKNS_7variantIJS3_EEE.carbon_thunk._(ptr noundef %v) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %v, ptr %v.addr, align 8, !tbaa !237
// CHECK:STDOUT:   %0 = load ptr, ptr %v.addr, align 8, !tbaa !237
// CHECK:STDOUT:   %call = invoke noundef nonnull align 4 dereferenceable(4) ptr @_ZNSt3__13getILm0EJidEEERK19__type_pack_elementIXT_EJDpT0_EERKNS_7variantIJS3_EEE(ptr noundef nonnull align 8 dereferenceable(16) %0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret ptr %call
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.2, i64 noundef 74) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #9
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %6) #10
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef nonnull align 8 dereferenceable(8) ptr @_ZNSt3__13getILm1EJidEEERK19__type_pack_elementIXT_EJDpT0_EERKNS_7variantIJS3_EEE.carbon_thunk._(ptr noundef %v) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %v, ptr %v.addr, align 8, !tbaa !237
// CHECK:STDOUT:   %0 = load ptr, ptr %v.addr, align 8, !tbaa !237
// CHECK:STDOUT:   %call = invoke noundef nonnull align 8 dereferenceable(8) ptr @_ZNSt3__13getILm1EJidEEERK19__type_pack_elementIXT_EJDpT0_EERKNS_7variantIJS3_EEE(ptr noundef nonnull align 8 dereferenceable(16) %0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret ptr %call
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.2, i64 noundef 74) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #9
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %6) #10
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.097ead33ecab8068:core.Destroy.Core"(ptr %self) #0 !dbg !161 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !163
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CK.Main(double %d) #0 !dbg !165 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_69.1.temp = alloca <{ <{ i1, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !171
// CHECK:STDOUT:   %.loc19_69.4.temp = alloca [16 x i8], align 8, !dbg !171
// CHECK:STDOUT:   %.loc19_69.25.temp = alloca double, align 8, !dbg !171
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc19_69.1.temp), !dbg !171
// CHECK:STDOUT:   call void @_CAlt1.StdVariant2.CppCompat.Core.0cbc347ce64f83a1(ptr %.loc19_69.1.temp, double %d), !dbg !171
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc19_69.4.temp), !dbg !171
// CHECK:STDOUT:   call void @_ZNSt3__17variantIJidEEC1Ev.carbon_thunk.(ptr %.loc19_69.4.temp), !dbg !171
// CHECK:STDOUT:   %.loc19_69.9.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc19_69.1.temp, i32 0, i32 0, !dbg !171
// CHECK:STDOUT:   %.loc19_69.10 = load i8, ptr %.loc19_69.9.discriminant, align 1, !dbg !171
// CHECK:STDOUT:   %.loc19_69.101 = trunc i8 %.loc19_69.10 to i1, !dbg !171
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 false, %.loc19_69.101, !dbg !171
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %.loc19_69.1, label %.loc19_69.2, !dbg !171
// CHECK:STDOUT:
// CHECK:STDOUT: .loc19_69.1:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc19_69.13.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc19_69.1.temp, i32 0, i32 1, !dbg !171
// CHECK:STDOUT:   %.loc19_69.14.Alt0 = getelementptr inbounds nuw [8 x i8], ptr %.loc19_69.13.payload, i32 0, i32 0, !dbg !171
// CHECK:STDOUT:   %tuple.elem0.loc19_69.1.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %.loc19_69.14.Alt0, i32 0, i32 0, !dbg !171
// CHECK:STDOUT:   %.loc19_69.15 = load i32, ptr %tuple.elem0.loc19_69.1.tuple.elem, align 4, !dbg !171
// CHECK:STDOUT:   %emplace__carbon_thunk.call.loc19_69.1 = call ptr @_ZNSt3__17variantIJidEE7emplaceILm0EJiEEER19__type_pack_elementIXT_EJidEEDpT0_.carbon_thunk.__(ptr %.loc19_69.4.temp, i32 %.loc19_69.15), !dbg !171
// CHECK:STDOUT:   br label %.loc19_69.3, !dbg !171
// CHECK:STDOUT:
// CHECK:STDOUT: .loc19_69.2:                                      ; preds = %entry
// CHECK:STDOUT:   %.loc19_69.19.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %.loc19_69.1.temp, i32 0, i32 1, !dbg !171
// CHECK:STDOUT:   %.loc19_69.20.Alt1 = getelementptr inbounds nuw [8 x i8], ptr %.loc19_69.19.payload, i32 0, i32 0, !dbg !171
// CHECK:STDOUT:   %tuple.elem0.loc19_69.2.tuple.elem = getelementptr inbounds nuw { double }, ptr %.loc19_69.20.Alt1, i32 0, i32 0, !dbg !171
// CHECK:STDOUT:   %.loc19_69.21 = load double, ptr %tuple.elem0.loc19_69.2.tuple.elem, align 8, !dbg !171
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc19_69.25.temp), !dbg !171
// CHECK:STDOUT:   store double %.loc19_69.21, ptr %.loc19_69.25.temp, align 8, !dbg !171
// CHECK:STDOUT:   %emplace__carbon_thunk.call.loc19_69.2 = call ptr @_ZNSt3__17variantIJidEE7emplaceILm1EJdEEER19__type_pack_elementIXT_EJidEEDpT0_.carbon_thunk.__(ptr %.loc19_69.4.temp, ptr %.loc19_69.25.temp), !dbg !171
// CHECK:STDOUT:   call void @"_CSelfDestruct.dc14d4dd21801791:core.Destroy.Core"(ptr %.loc19_69.25.temp), !dbg !171
// CHECK:STDOUT:   br label %.loc19_69.3, !dbg !171
// CHECK:STDOUT:
// CHECK:STDOUT: .loc19_69.3:                                      ; preds = %.loc19_69.2, %.loc19_69.1
// CHECK:STDOUT:   %TakeVariant__carbon_thunk.call = call i32 @_Z11TakeVariantNSt3__17variantIJidEEE.carbon_thunk._(ptr %.loc19_69.4.temp), !dbg !172
// CHECK:STDOUT:   call void @"_CSelfDestruct.3c209342d56544ca:core.Destroy.Core"(ptr %.loc19_69.1.temp), !dbg !171
// CHECK:STDOUT:   ret i32 %TakeVariant__carbon_thunk.call, !dbg !173
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_Z11TakeVariantNSt3__17variantIJidEEE.carbon_thunk._(ptr noundef %v) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.addr = alloca ptr, align 8
// CHECK:STDOUT:   %agg.tmp = alloca %"class.std::__1::variant", align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %v, ptr %v.addr, align 8, !tbaa !237
// CHECK:STDOUT:   %0 = load ptr, ptr %v.addr, align 8, !tbaa !237
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %agg.tmp, ptr align 8 %0, i64 16, i1 false), !tbaa.struct !250
// CHECK:STDOUT:   %1 = getelementptr inbounds nuw { i64, i64 }, ptr %agg.tmp, i32 0, i32 0
// CHECK:STDOUT:   %2 = load i64, ptr %1, align 8
// CHECK:STDOUT:   %3 = getelementptr inbounds nuw { i64, i64 }, ptr %agg.tmp, i32 0, i32 1
// CHECK:STDOUT:   %4 = load i64, ptr %3, align 8
// CHECK:STDOUT:   %call = invoke noundef i32 @_Z11TakeVariantNSt3__17variantIJidEEE(i64 %2, i64 %4)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   store ptr %6, ptr %exn.slot, align 8
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %5, 1
// CHECK:STDOUT:   store i32 %7, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %8 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.3, i64 noundef 77) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #9
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %9 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %10 = extractvalue { ptr, i32 } %9, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %10) #10
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZNSt3__17variantIJidEEC1Ev.carbon_thunk.(ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !237
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !237
// CHECK:STDOUT:   invoke void @_ZNSt3__17variantIJidEEC2Ev(ptr noundef nonnull align 8 dereferenceable(16) %0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
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
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.4, i64 noundef 100) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #9
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %6) #10
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef nonnull align 4 dereferenceable(4) ptr @_ZNSt3__17variantIJidEE7emplaceILm0EJiEEER19__type_pack_elementIXT_EJidEEDpT0_.carbon_thunk.__(ptr noundef nonnull align 8 dereferenceable(16) %this, i32 noundef %args) #1 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %args.addr = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !237
// CHECK:STDOUT:   store i32 %args, ptr %args.addr, align 4, !tbaa !115
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !237, !nonnull !125, !align !247
// CHECK:STDOUT:   %1 = load i32, ptr %args.addr, align 4, !tbaa !115
// CHECK:STDOUT:   %call = call noundef nonnull align 4 dereferenceable(4) ptr @_ZNSt3__17variantIJidEE7emplaceILm0EJiEEER19__type_pack_elementIXT_EJidEEDpT0_(ptr noundef nonnull align 8 dereferenceable(16) %0, i32 noundef %1)
// CHECK:STDOUT:   ret ptr %call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef nonnull align 8 dereferenceable(8) ptr @_ZNSt3__17variantIJidEE7emplaceILm1EJdEEER19__type_pack_elementIXT_EJidEEDpT0_.carbon_thunk.__(ptr noundef nonnull align 8 dereferenceable(16) %this, ptr noundef %args) #1 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %args.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !237
// CHECK:STDOUT:   store ptr %args, ptr %args.addr, align 8, !tbaa !246
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !237, !nonnull !125, !align !247
// CHECK:STDOUT:   %1 = load ptr, ptr %args.addr, align 8, !tbaa !246
// CHECK:STDOUT:   %2 = load double, ptr %1, align 8, !tbaa !244
// CHECK:STDOUT:   %call = call noundef nonnull align 8 dereferenceable(8) ptr @_ZNSt3__17variantIJidEE7emplaceILm1EJdEEER19__type_pack_elementIXT_EJidEEDpT0_(ptr noundef nonnull align 8 dereferenceable(16) %0, double noundef %2)
// CHECK:STDOUT:   ret ptr %call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.dc14d4dd21801791:core.Destroy.Core"(ptr %self) #0 !dbg !175 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !177
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !179 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !181
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !183 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !185
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !187 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !189
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !189
// CHECK:STDOUT:   ret void, !dbg !189
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self) #0 !dbg !191 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core"(ptr %self), !dbg !193
// CHECK:STDOUT:   ret void, !dbg !193
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.2fdb2a34f63d2b44:core.Destroy.Core"(ptr %self) #0 !dbg !195 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { double }, ptr %self, i32 0, i32 0, !dbg !197
// CHECK:STDOUT:   call void @"_CSelfDestruct.dc14d4dd21801791:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !197
// CHECK:STDOUT:   ret void, !dbg !197
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.2fdb2a34f63d2b44:core.Destroy.Core"(ptr %self) #0 !dbg !199 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.2fdb2a34f63d2b44:core.Destroy.Core"(ptr %self), !dbg !201
// CHECK:STDOUT:   ret void, !dbg !201
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.181a98ea15a1a6b1:core.Destroy.Core"(ptr %self) #0 !dbg !203 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !205
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.181a98ea15a1a6b1:core.Destroy.Core"(ptr %self) #0 !dbg !207 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.181a98ea15a1a6b1:core.Destroy.Core"(ptr %self), !dbg !209
// CHECK:STDOUT:   ret void, !dbg !209
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.849a7f6f89e9ed41:core.Destroy.Core"(ptr %self) #0 !dbg !211 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_69.1.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 1, !dbg !213
// CHECK:STDOUT:   call void @"_CSelfDestruct.181a98ea15a1a6b1:core.Destroy.Core"(ptr %.loc19_69.1.payload), !dbg !213
// CHECK:STDOUT:   %.loc19_69.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %self, i32 0, i32 0, !dbg !213
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc19_69.2.discriminant), !dbg !213
// CHECK:STDOUT:   ret void, !dbg !213
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.849a7f6f89e9ed41:core.Destroy.Core"(ptr %self) #0 !dbg !215 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.849a7f6f89e9ed41:core.Destroy.Core"(ptr %self), !dbg !217
// CHECK:STDOUT:   ret void, !dbg !217
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.3c209342d56544ca:core.Destroy.Core"(ptr %self) #0 !dbg !219 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !221
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.3c209342d56544ca:core.Destroy.Core"(ptr %self) #0 !dbg !223 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.3c209342d56544ca:core.Destroy.Core"(ptr %self), !dbg !225
// CHECK:STDOUT:   ret void, !dbg !225
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CAlt0.StdVariant2.CppCompat.Core.0cbc347ce64f83a1(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, i32 %_) #0 !dbg !227 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !229
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !229
// CHECK:STDOUT:   %Alt0 = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !229
// CHECK:STDOUT:   %tuple.init = insertvalue { i32 } poison, i32 %_, 0, !dbg !230
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @StdVariant2.val.9d9.anon, i64 16, i1 false), !dbg !229
// CHECK:STDOUT:   store { i32 } %tuple.init, ptr %Alt0, align 4, !dbg !229
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32 }, ptr %Alt0, i32 0, i32 0, !dbg !230
// CHECK:STDOUT:   store i32 %_, ptr %tuple.elem, align 4, !dbg !230
// CHECK:STDOUT:   ret void, !dbg !229
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CAlt1.StdVariant2.CppCompat.Core.0cbc347ce64f83a1(ptr sret(<{ <{ i1, [7 x i8] }>, [8 x i8] }>) %return, double %_) #0 !dbg !232 {
// CHECK:STDOUT:   %discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !234
// CHECK:STDOUT:   %payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !234
// CHECK:STDOUT:   %Alt1 = getelementptr inbounds nuw [8 x i8], ptr %payload, i32 0, i32 0, !dbg !234
// CHECK:STDOUT:   %tuple.init = insertvalue { double } poison, double %_, 0, !dbg !234
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @StdVariant2.val.622.anon, i64 16, i1 false), !dbg !234
// CHECK:STDOUT:   store { double } %tuple.init, ptr %Alt1, align 8, !dbg !234
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { double }, ptr %Alt1, i32 0, i32 0, !dbg !234
// CHECK:STDOUT:   store double %_, ptr %tuple.elem, align 8, !dbg !234
// CHECK:STDOUT:   ret void, !dbg !234
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: inlinehint mustprogress uwtable
// CHECK:STDOUT: define linkonce_odr dso_local { i64, i64 } @_Z9IntOrHalfi(i32 noundef %n) #3 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca %"class.std::__1::variant", align 8
// CHECK:STDOUT:   %n.addr = alloca i32, align 4
// CHECK:STDOUT:   store i32 %n, ptr %n.addr, align 4, !tbaa !115
// CHECK:STDOUT:   call void @_ZNSt3__17variantIJidEEC2Ev(ptr noundef nonnull align 8 dereferenceable(16) %retval)
// CHECK:STDOUT:   %0 = load i32, ptr %n.addr, align 4, !tbaa !115
// CHECK:STDOUT:   %cmp = icmp sgt i32 %0, 0
// CHECK:STDOUT:   br i1 %cmp, label %if.then, label %if.else
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %1 = load i32, ptr %n.addr, align 4, !tbaa !115
// CHECK:STDOUT:   %call = call noundef nonnull align 4 dereferenceable(4) ptr @_ZNSt3__17variantIJidEE7emplaceILm0EJiEEER19__type_pack_elementIXT_EJidEEDpT0_(ptr noundef nonnull align 8 dereferenceable(16) %retval, i32 noundef %1)
// CHECK:STDOUT:   br label %if.end
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   %2 = load i32, ptr %n.addr, align 4, !tbaa !115
// CHECK:STDOUT:   %conv = sitofp i32 %2 to double
// CHECK:STDOUT:   %mul = fmul double %conv, 5.000000e-01
// CHECK:STDOUT:   %call1 = call noundef nonnull align 8 dereferenceable(8) ptr @_ZNSt3__17variantIJidEE7emplaceILm1EJdEEER19__type_pack_elementIXT_EJidEEDpT0_(ptr noundef nonnull align 8 dereferenceable(16) %retval, double noundef %mul)
// CHECK:STDOUT:   br label %if.end
// CHECK:STDOUT:
// CHECK:STDOUT: if.end:                                           ; preds = %if.else, %if.then
// CHECK:STDOUT:   %3 = load { i64, i64 }, ptr %retval, align 8
// CHECK:STDOUT:   ret { i64, i64 } %3
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
// CHECK:STDOUT:   call void @_ZSt9terminatev() #10
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress uwtable
// CHECK:STDOUT: define linkonce_odr dso_local void @_ZNSt3__17variantIJidEEC2Ev(ptr noundef nonnull align 8 dereferenceable(16) %this) unnamed_addr #6 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !237
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %index_ = getelementptr inbounds nuw %"class.std::__1::variant", ptr %this1, i32 0, i32 1
// CHECK:STDOUT:   store i64 0, ptr %index_, align 8, !tbaa !241
// CHECK:STDOUT:   %call = call noundef nonnull align 4 dereferenceable(4) ptr @_ZNSt3__17variantIJidEE7emplaceILm0EJEEER19__type_pack_elementIXT_EJidEEDpT0_(ptr noundef nonnull align 8 dereferenceable(16) %this1)
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef nonnull align 4 dereferenceable(4) ptr @_ZNSt3__17variantIJidEE7emplaceILm0EJiEEER19__type_pack_elementIXT_EJidEEDpT0_(ptr noundef nonnull align 8 dereferenceable(16) %this, i32 noundef %args) #7 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %args.addr = alloca i32, align 4
// CHECK:STDOUT:   %p = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !237
// CHECK:STDOUT:   store i32 %args, ptr %args.addr, align 4, !tbaa !115
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %index_ = getelementptr inbounds nuw %"class.std::__1::variant", ptr %this1, i32 0, i32 1
// CHECK:STDOUT:   store i64 0, ptr %index_, align 8, !tbaa !241
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %p) #0
// CHECK:STDOUT:   %storage_ = getelementptr inbounds nuw %"class.std::__1::variant", ptr %this1, i32 0, i32 0
// CHECK:STDOUT:   %arraydecay = getelementptr inbounds [8 x i8], ptr %storage_, i64 0, i64 0
// CHECK:STDOUT:   store ptr %arraydecay, ptr %p, align 8, !tbaa !243
// CHECK:STDOUT:   %0 = load i32, ptr %args.addr, align 4, !tbaa !115
// CHECK:STDOUT:   %1 = load ptr, ptr %p, align 8, !tbaa !243
// CHECK:STDOUT:   store i32 %0, ptr %1, align 4, !tbaa !115
// CHECK:STDOUT:   %2 = load ptr, ptr %p, align 8, !tbaa !243
// CHECK:STDOUT:   call void @llvm.lifetime.end.p0(ptr %p) #0
// CHECK:STDOUT:   ret ptr %2
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef nonnull align 8 dereferenceable(8) ptr @_ZNSt3__17variantIJidEE7emplaceILm1EJdEEER19__type_pack_elementIXT_EJidEEDpT0_(ptr noundef nonnull align 8 dereferenceable(16) %this, double noundef %args) #7 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %args.addr = alloca double, align 8
// CHECK:STDOUT:   %p = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !237
// CHECK:STDOUT:   store double %args, ptr %args.addr, align 8, !tbaa !244
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %index_ = getelementptr inbounds nuw %"class.std::__1::variant", ptr %this1, i32 0, i32 1
// CHECK:STDOUT:   store i64 1, ptr %index_, align 8, !tbaa !241
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %p) #0
// CHECK:STDOUT:   %storage_ = getelementptr inbounds nuw %"class.std::__1::variant", ptr %this1, i32 0, i32 0
// CHECK:STDOUT:   %arraydecay = getelementptr inbounds [8 x i8], ptr %storage_, i64 0, i64 0
// CHECK:STDOUT:   store ptr %arraydecay, ptr %p, align 8, !tbaa !246
// CHECK:STDOUT:   %0 = load double, ptr %args.addr, align 8, !tbaa !244
// CHECK:STDOUT:   %1 = load ptr, ptr %p, align 8, !tbaa !246
// CHECK:STDOUT:   store double %0, ptr %1, align 8, !tbaa !244
// CHECK:STDOUT:   %2 = load ptr, ptr %p, align 8, !tbaa !246
// CHECK:STDOUT:   call void @llvm.lifetime.end.p0(ptr %p) #0
// CHECK:STDOUT:   ret ptr %2
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef nonnull align 4 dereferenceable(4) ptr @_ZNSt3__17variantIJidEE7emplaceILm0EJEEER19__type_pack_elementIXT_EJidEEDpT0_(ptr noundef nonnull align 8 dereferenceable(16) %this) #7 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %p = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !237
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %index_ = getelementptr inbounds nuw %"class.std::__1::variant", ptr %this1, i32 0, i32 1
// CHECK:STDOUT:   store i64 0, ptr %index_, align 8, !tbaa !241
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %p) #0
// CHECK:STDOUT:   %storage_ = getelementptr inbounds nuw %"class.std::__1::variant", ptr %this1, i32 0, i32 0
// CHECK:STDOUT:   %arraydecay = getelementptr inbounds [8 x i8], ptr %storage_, i64 0, i64 0
// CHECK:STDOUT:   store ptr %arraydecay, ptr %p, align 8, !tbaa !243
// CHECK:STDOUT:   %0 = load ptr, ptr %p, align 8, !tbaa !243
// CHECK:STDOUT:   store i32 0, ptr %0, align 4, !tbaa !115
// CHECK:STDOUT:   %1 = load ptr, ptr %p, align 8, !tbaa !243
// CHECK:STDOUT:   call void @llvm.lifetime.end.p0(ptr %p) #0
// CHECK:STDOUT:   ret ptr %1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.end.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef i64 @_ZNKSt3__17variantIJidEE5indexEv(ptr noundef nonnull align 8 dereferenceable(16) %this) #7 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !237
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %index_ = getelementptr inbounds nuw %"class.std::__1::variant", ptr %this1, i32 0, i32 1
// CHECK:STDOUT:   %0 = load i64, ptr %index_, align 8, !tbaa !241
// CHECK:STDOUT:   ret i64 %0
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef nonnull align 4 dereferenceable(4) ptr @_ZNSt3__13getILm0EJidEEERK19__type_pack_elementIXT_EJDpT0_EERKNS_7variantIJS3_EEE(ptr noundef nonnull align 8 dereferenceable(16) %v) #7 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %v, ptr %v.addr, align 8, !tbaa !237
// CHECK:STDOUT:   %0 = load ptr, ptr %v.addr, align 8, !tbaa !237, !nonnull !125, !align !247
// CHECK:STDOUT:   %storage_ = getelementptr inbounds nuw %"class.std::__1::variant", ptr %0, i32 0, i32 0
// CHECK:STDOUT:   %arraydecay = getelementptr inbounds [8 x i8], ptr %storage_, i64 0, i64 0
// CHECK:STDOUT:   ret ptr %arraydecay
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef nonnull align 8 dereferenceable(8) ptr @_ZNSt3__13getILm1EJidEEERK19__type_pack_elementIXT_EJDpT0_EERKNS_7variantIJS3_EEE(ptr noundef nonnull align 8 dereferenceable(16) %v) #7 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %v, ptr %v.addr, align 8, !tbaa !237
// CHECK:STDOUT:   %0 = load ptr, ptr %v.addr, align 8, !tbaa !237, !nonnull !125, !align !247
// CHECK:STDOUT:   %storage_ = getelementptr inbounds nuw %"class.std::__1::variant", ptr %0, i32 0, i32 0
// CHECK:STDOUT:   %arraydecay = getelementptr inbounds [8 x i8], ptr %storage_, i64 0, i64 0
// CHECK:STDOUT:   ret ptr %arraydecay
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: inlinehint mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef i32 @_Z11TakeVariantNSt3__17variantIJidEEE(i64 %v.coerce0, i64 %v.coerce1) #8 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v = alloca %"class.std::__1::variant", align 8
// CHECK:STDOUT:   %0 = getelementptr inbounds nuw { i64, i64 }, ptr %v, i32 0, i32 0
// CHECK:STDOUT:   store i64 %v.coerce0, ptr %0, align 8
// CHECK:STDOUT:   %1 = getelementptr inbounds nuw { i64, i64 }, ptr %v, i32 0, i32 1
// CHECK:STDOUT:   store i64 %v.coerce1, ptr %1, align 8
// CHECK:STDOUT:   %call = call noundef i64 @_ZNKSt3__17variantIJidEE5indexEv(ptr noundef nonnull align 8 dereferenceable(16) %v)
// CHECK:STDOUT:   %conv = trunc i64 %call to i32
// CHECK:STDOUT:   ret i32 %conv
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 2, 0, 1, 7, 6, 5, 4, 3 }
// CHECK:STDOUT: uselistorder ptr @_CAlt1.StdVariant2.CppCompat.Core.0cbc347ce64f83a1, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 0, 2, 1 }
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_begin_catch, { 5, 6, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_rethrow, { 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 5, 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_ZNSt3__17variantIJidEEC2Ev, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.end.p0, { 1, 0, 2 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { inlinehint mustprogress uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { mustprogress uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #7 = { mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #8 = { inlinehint mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #9 = { noreturn }
// CHECK:STDOUT: attributes #10 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!136}
// CHECK:STDOUT: !llvm.module.flags = !{!130, !131, !132, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!134}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !8 = !{!6, !6}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !15 = !{!10, !10}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = !{null, !10}
// CHECK:STDOUT: !18 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !19 = !{!6, !10}
// CHECK:STDOUT: !20 = !DISubroutineType(types: !19)
// CHECK:STDOUT: !23 = !{null, !7}
// CHECK:STDOUT: !24 = !DISubroutineType(types: !23)
// CHECK:STDOUT: !25 = !{null, !6}
// CHECK:STDOUT: !26 = !DISubroutineType(types: !25)
// CHECK:STDOUT: !35 = !{!10, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !106 = !DIFile(filename: "{{.*}}/prelude/types/cpp/sum.carbon", directory: "")
// CHECK:STDOUT: !112 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !113 = !{!"omnipotent char", !112, i64 0}
// CHECK:STDOUT: !114 = !{!"int", !113, i64 0}
// CHECK:STDOUT: !115 = !{!114, !114, i64 0}
// CHECK:STDOUT: !116 = !{!"any pointer", !113, i64 0}
// CHECK:STDOUT: !125 = !{}
// CHECK:STDOUT: !130 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !131 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !132 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !133 = !{!"__libc_errno", !114, i64 0}
// CHECK:STDOUT: !134 = !{!133, !114, i64 0}
// CHECK:STDOUT: !135 = !DIFile(filename: "variant.carbon", directory: "")
// CHECK:STDOUT: !136 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !135, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !143 = distinct !DISubprogram(name: "H", linkageName: "_CH.Main", scope: null, file: !135, line: 6, type: !9, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !160)
// CHECK:STDOUT: !144 = !DILocalVariable(arg: 1, scope: !143, type: !6)
// CHECK:STDOUT: !149 = !DILocation(line: 7, column: 10, scope: !143)
// CHECK:STDOUT: !150 = !DILocation(line: 7, column: 9, scope: !143)
// CHECK:STDOUT: !151 = !DILocation(line: 8, column: 5, scope: !143)
// CHECK:STDOUT: !154 = !DILocation(line: 9, column: 7, scope: !143)
// CHECK:STDOUT: !155 = !DILocation(line: 11, column: 5, scope: !143)
// CHECK:STDOUT: !157 = !DILocation(line: 12, column: 7, scope: !143)
// CHECK:STDOUT: !159 = !DILocation(line: 15, column: 3, scope: !143)
// CHECK:STDOUT: !160 = !{!144}
// CHECK:STDOUT: !161 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.097ead33ecab8068:core.Destroy.Core", scope: null, file: !135, line: 7, type: !18, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !164)
// CHECK:STDOUT: !162 = !DILocalVariable(arg: 1, scope: !161, type: !10)
// CHECK:STDOUT: !163 = !DILocation(line: 7, column: 10, scope: !161)
// CHECK:STDOUT: !164 = !{!162}
// CHECK:STDOUT: !165 = distinct !DISubprogram(name: "K", linkageName: "_CK.Main", scope: null, file: !135, line: 18, type: !20, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !174)
// CHECK:STDOUT: !166 = !DILocalVariable(arg: 1, scope: !165, type: !10)
// CHECK:STDOUT: !171 = !DILocation(line: 19, column: 26, scope: !165)
// CHECK:STDOUT: !172 = !DILocation(line: 19, column: 10, scope: !165)
// CHECK:STDOUT: !173 = !DILocation(line: 19, column: 3, scope: !165)
// CHECK:STDOUT: !174 = !{!166}
// CHECK:STDOUT: !175 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.dc14d4dd21801791:core.Destroy.Core", scope: null, file: !135, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !178)
// CHECK:STDOUT: !176 = !DILocalVariable(arg: 1, scope: !175, type: !10)
// CHECK:STDOUT: !177 = !DILocation(line: 19, column: 26, scope: !175)
// CHECK:STDOUT: !178 = !{!176}
// CHECK:STDOUT: !179 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !135, line: 19, type: !24, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !182)
// CHECK:STDOUT: !180 = !DILocalVariable(arg: 1, scope: !179, type: !7)
// CHECK:STDOUT: !181 = !DILocation(line: 19, column: 26, scope: !179)
// CHECK:STDOUT: !182 = !{!180}
// CHECK:STDOUT: !183 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !135, line: 19, type: !26, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !186)
// CHECK:STDOUT: !184 = !DILocalVariable(arg: 1, scope: !183, type: !6)
// CHECK:STDOUT: !185 = !DILocation(line: 19, column: 26, scope: !183)
// CHECK:STDOUT: !186 = !{!184}
// CHECK:STDOUT: !187 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !135, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !190)
// CHECK:STDOUT: !188 = !DILocalVariable(arg: 1, scope: !187, type: !10)
// CHECK:STDOUT: !189 = !DILocation(line: 19, column: 26, scope: !187)
// CHECK:STDOUT: !190 = !{!188}
// CHECK:STDOUT: !191 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a56634ea0bfe88:core.Destroy.Core", scope: null, file: !135, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !194)
// CHECK:STDOUT: !192 = !DILocalVariable(arg: 1, scope: !191, type: !10)
// CHECK:STDOUT: !193 = !DILocation(line: 19, column: 26, scope: !191)
// CHECK:STDOUT: !194 = !{!192}
// CHECK:STDOUT: !195 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.2fdb2a34f63d2b44:core.Destroy.Core", scope: null, file: !135, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !198)
// CHECK:STDOUT: !196 = !DILocalVariable(arg: 1, scope: !195, type: !10)
// CHECK:STDOUT: !197 = !DILocation(line: 19, column: 26, scope: !195)
// CHECK:STDOUT: !198 = !{!196}
// CHECK:STDOUT: !199 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.2fdb2a34f63d2b44:core.Destroy.Core", scope: null, file: !135, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !202)
// CHECK:STDOUT: !200 = !DILocalVariable(arg: 1, scope: !199, type: !10)
// CHECK:STDOUT: !201 = !DILocation(line: 19, column: 26, scope: !199)
// CHECK:STDOUT: !202 = !{!200}
// CHECK:STDOUT: !203 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.181a98ea15a1a6b1:core.Destroy.Core", scope: null, file: !135, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !206)
// CHECK:STDOUT: !204 = !DILocalVariable(arg: 1, scope: !203, type: !10)
// CHECK:STDOUT: !205 = !DILocation(line: 19, column: 26, scope: !203)
// CHECK:STDOUT: !206 = !{!204}
// CHECK:STDOUT: !207 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.181a98ea15a1a6b1:core.Destroy.Core", scope: null, file: !135, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !210)
// CHECK:STDOUT: !208 = !DILocalVariable(arg: 1, scope: !207, type: !10)
// CHECK:STDOUT: !209 = !DILocation(line: 19, column: 26, scope: !207)
// CHECK:STDOUT: !210 = !{!208}
// CHECK:STDOUT: !211 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.849a7f6f89e9ed41:core.Destroy.Core", scope: null, file: !135, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !214)
// CHECK:STDOUT: !212 = !DILocalVariable(arg: 1, scope: !211, type: !10)
// CHECK:STDOUT: !213 = !DILocation(line: 19, column: 26, scope: !211)
// CHECK:STDOUT: !214 = !{!212}
// CHECK:STDOUT: !215 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.849a7f6f89e9ed41:core.Destroy.Core", scope: null, file: !135, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !218)
// CHECK:STDOUT: !216 = !DILocalVariable(arg: 1, scope: !215, type: !10)
// CHECK:STDOUT: !217 = !DILocation(line: 19, column: 26, scope: !215)
// CHECK:STDOUT: !218 = !{!216}
// CHECK:STDOUT: !219 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.3c209342d56544ca:core.Destroy.Core", scope: null, file: !135, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !222)
// CHECK:STDOUT: !220 = !DILocalVariable(arg: 1, scope: !219, type: !10)
// CHECK:STDOUT: !221 = !DILocation(line: 19, column: 26, scope: !219)
// CHECK:STDOUT: !222 = !{!220}
// CHECK:STDOUT: !223 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.3c209342d56544ca:core.Destroy.Core", scope: null, file: !135, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !226)
// CHECK:STDOUT: !224 = !DILocalVariable(arg: 1, scope: !223, type: !10)
// CHECK:STDOUT: !225 = !DILocation(line: 19, column: 26, scope: !223)
// CHECK:STDOUT: !226 = !{!224}
// CHECK:STDOUT: !227 = distinct !DISubprogram(name: "Alt0", linkageName: "_CAlt0.StdVariant2.CppCompat.Core.0cbc347ce64f83a1", scope: null, file: !106, line: 39, type: !36, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !231)
// CHECK:STDOUT: !228 = !DILocalVariable(arg: 1, scope: !227, type: !6)
// CHECK:STDOUT: !229 = !DILocation(line: 39, column: 1, scope: !227)
// CHECK:STDOUT: !230 = !DILocation(line: 40, column: 18, scope: !227)
// CHECK:STDOUT: !231 = !{!228}
// CHECK:STDOUT: !232 = distinct !DISubprogram(name: "Alt1", linkageName: "_CAlt1.StdVariant2.CppCompat.Core.0cbc347ce64f83a1", scope: null, file: !106, line: 39, type: !16, spFlags: DISPFlagDefinition, unit: !136, retainedNodes: !235)
// CHECK:STDOUT: !233 = !DILocalVariable(arg: 1, scope: !232, type: !10)
// CHECK:STDOUT: !234 = !DILocation(line: 39, column: 1, scope: !232)
// CHECK:STDOUT: !235 = !{!233}
// CHECK:STDOUT: !236 = !{!"p1 _ZTSNSt3__17variantIJidEEE", !116, i64 0}
// CHECK:STDOUT: !237 = !{!236, !236, i64 0}
// CHECK:STDOUT: !238 = !{!"long", !113, i64 0}
// CHECK:STDOUT: !239 = !{!"_ZTSNSt3__17variantIJidEEE", !113, i64 0, !238, i64 8}
// CHECK:STDOUT: !240 = !{!"double", !113, i64 0}
// CHECK:STDOUT: !241 = !{!239, !238, i64 8}
// CHECK:STDOUT: !242 = !{!"p1 int", !116, i64 0}
// CHECK:STDOUT: !243 = !{!242, !242, i64 0}
// CHECK:STDOUT: !244 = !{!240, !240, i64 0}
// CHECK:STDOUT: !245 = !{!"p1 double", !116, i64 0}
// CHECK:STDOUT: !246 = !{!245, !245, i64 0}
// CHECK:STDOUT: !247 = !{i64 8}
// CHECK:STDOUT: !248 = !{!113, !113, i64 0}
// CHECK:STDOUT: !249 = !{!238, !238, i64 0}
// CHECK:STDOUT: !250 = !{i64 0, i64 8, !248, i64 8, i64 8, !249}
// CHECK:STDOUT:

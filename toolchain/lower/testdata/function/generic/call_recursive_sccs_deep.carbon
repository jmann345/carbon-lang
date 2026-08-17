// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// EXTRA-ARGS: --include-carbon-core
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/generic/call_recursive_sccs_deep.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/generic/call_recursive_sccs_deep.carbon

import Core library "io";
fn A[T: Core.Copy](x: T, count: i32) -> T;
fn B[T: Core.Copy](x: T, count: i32);
fn C[T: Core.Copy](x: T, count: i32);
fn D[T: Core.Copy](x: T, count: i32) -> T;
fn E[T: Core.Copy](x: T, count: i32) -> T;
fn F[T: Core.Copy](x: T, count: i32) -> T;

// Builds on `call_recursive_mutual.carbon` and `call_recursive_diamond.carbon`
// B-C form a mutually recursive SCC (strongly connected component), D-E-F-G
// form a diamond SCC.
// The two specifics for each of A, B, C, D, E, F, G with a pointer type could
// be deduplicated.
// E and F are also equivalent in the diamond, even though they are different
// generics. There is potential front-end ICF (identical code folding)
// optimization here, if the function fingerprint may infer deduplication
// when not including the two different generic_ids.

fn A[T: Core.Copy](x: T, count: i32) -> T {
  B(x, count);
  return D(x, count);
}

fn B[T: Core.Copy](x: T, count: i32) {
  C(x, count);
}

fn C[T: Core.Copy](x: T, count: i32) {
  if (count <= 2) {
    Core.Print(count);
    B(x, count + 1);
  }
}

fn D[T: Core.Copy](x: T, count: i32) -> T {
  if (count > 4) {
    return x;
  }
  if (count % 2 == 0) {
    return E(x, count);
  } else {
    return F(x, count);
  }
}

fn G[T: Core.Copy](x: T, count: i32) -> T;

fn E[T: Core.Copy](x: T, count: i32) -> T {
  return G(x, count);
}

fn F[T: Core.Copy](x: T, count: i32) -> T {
  return G(x, count);
}

fn G[T: Core.Copy](x: T, count: i32) -> T {
  return D(x, count + 1);
}


fn M() {
  var n: i32 = 0;
  var m: f64 = 1.0;
  var ptr_i32 : i32* = &n;
  var ptr_f64 : f64* = &m;

  A(n, 0);
  A(m, 0);
  A(ptr_i32, 0);
  A(ptr_f64, 0);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'call_recursive_sccs_deep.carbon'
// CHECK:STDOUT: source_filename = "call_recursive_sccs_deep.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @printf.int.format = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CM.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %n.var = alloca i32, align 4, !dbg !7
// CHECK:STDOUT:   %m.var = alloca double, align 8, !dbg !8
// CHECK:STDOUT:   %ptr_i32.var = alloca ptr, align 8, !dbg !9
// CHECK:STDOUT:   %ptr_f64.var = alloca ptr, align 8, !dbg !10
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %n.var), !dbg !7
// CHECK:STDOUT:   store i32 0, ptr %n.var, align 4, !dbg !7
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %m.var), !dbg !8
// CHECK:STDOUT:   store double 1.000000e+00, ptr %m.var, align 8, !dbg !8
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %ptr_i32.var), !dbg !9
// CHECK:STDOUT:   store ptr %n.var, ptr %ptr_i32.var, align 8, !dbg !9
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %ptr_f64.var), !dbg !10
// CHECK:STDOUT:   store ptr %m.var, ptr %ptr_f64.var, align 8, !dbg !10
// CHECK:STDOUT:   %.loc80_5 = load i32, ptr %n.var, align 4, !dbg !11
// CHECK:STDOUT:   %A.call.loc80 = call i32 @_CA.Main.4d6ceefeb7f772f4(i32 %.loc80_5, i32 0), !dbg !12
// CHECK:STDOUT:   %.loc81_5 = load double, ptr %m.var, align 8, !dbg !13
// CHECK:STDOUT:   %A.call.loc81 = call double @_CA.Main.c5e4ba542a56b71f(double %.loc81_5, i32 0), !dbg !14
// CHECK:STDOUT:   %.loc82_5 = load ptr, ptr %ptr_i32.var, align 8, !dbg !15
// CHECK:STDOUT:   %A.call.loc82 = call ptr @_CA.Main.a76b78461416b4a8(ptr %.loc82_5, i32 0), !dbg !16
// CHECK:STDOUT:   %.loc83_5 = load ptr, ptr %ptr_f64.var, align 8, !dbg !17
// CHECK:STDOUT:   %A.call.loc83 = call ptr @_CA.Main.5f2298097dd2e04c(ptr %.loc83_5, i32 0), !dbg !18
// CHECK:STDOUT:   call void @"_COp.30d8007fdcc57f83:core.Destroy.Core"(ptr %m.var), !dbg !8
// CHECK:STDOUT:   call void @"_COp.5e27612b9dd31a14:core.Destroy.Core"(ptr %n.var), !dbg !7
// CHECK:STDOUT:   ret void, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.30d8007fdcc57f83:core.Destroy.Core"(ptr %self) #0 !dbg !20 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5e27612b9dd31a14:core.Destroy.Core"(ptr %self) #0 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CA.Main.4d6ceefeb7f772f4(i32 %x, i32 %count) #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CB.Main.4d6ceefeb7f772f4(i32 %x, i32 %count), !dbg !40
// CHECK:STDOUT:   %D.call = call i32 @_CD.Main.4d6ceefeb7f772f4(i32 %x, i32 %count), !dbg !41
// CHECK:STDOUT:   ret i32 %D.call, !dbg !42
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr double @_CA.Main.c5e4ba542a56b71f(double %x, i32 %count) #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CB.Main.c5e4ba542a56b71f(double %x, i32 %count), !dbg !49
// CHECK:STDOUT:   %D.call = call double @_CD.Main.c5e4ba542a56b71f(double %x, i32 %count), !dbg !50
// CHECK:STDOUT:   ret double %D.call, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CA.Main.a76b78461416b4a8(ptr %x, i32 %count) #0 !dbg !52 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CB.Main.a76b78461416b4a8(ptr %x, i32 %count), !dbg !56
// CHECK:STDOUT:   %D.call = call ptr @_CD.Main.a76b78461416b4a8(ptr %x, i32 %count), !dbg !57
// CHECK:STDOUT:   ret ptr %D.call, !dbg !58
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CA.Main.5f2298097dd2e04c(ptr %x, i32 %count) #0 !dbg !59 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CB.Main.a76b78461416b4a8(ptr %x, i32 %count), !dbg !63
// CHECK:STDOUT:   %D.call = call ptr @_CD.Main.5f2298097dd2e04c(ptr %x, i32 %count), !dbg !64
// CHECK:STDOUT:   ret ptr %D.call, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CB.Main.4d6ceefeb7f772f4(i32 %x, i32 %count) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CC.Main.4d6ceefeb7f772f4(i32 %x, i32 %count), !dbg !72
// CHECK:STDOUT:   ret void, !dbg !73
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CD.Main.4d6ceefeb7f772f4(i32 %x, i32 %count) #0 !dbg !74 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call = icmp sgt i32 %count, 4, !dbg !78
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Greater.call, label %if.then.loc49, label %if.else.loc49, !dbg !79
// CHECK:STDOUT:
// CHECK:STDOUT: if.then.loc49:                                    ; preds = %entry
// CHECK:STDOUT:   ret i32 %x, !dbg !80
// CHECK:STDOUT:
// CHECK:STDOUT: if.else.loc49:                                    ; preds = %entry
// CHECK:STDOUT:   %Int.as.ModWith.impl.Op.call = srem i32 %count, 2, !dbg !81
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call = icmp eq i32 %Int.as.ModWith.impl.Op.call, 0, !dbg !81
// CHECK:STDOUT:   br i1 %Int.as.EqWith.impl.Equal.call, label %if.then.loc52, label %if.else.loc52, !dbg !82
// CHECK:STDOUT:
// CHECK:STDOUT: if.then.loc52:                                    ; preds = %if.else.loc49
// CHECK:STDOUT:   %E.call = call i32 @_CE.Main.4d6ceefeb7f772f4(i32 %x, i32 %count), !dbg !83
// CHECK:STDOUT:   ret i32 %E.call, !dbg !84
// CHECK:STDOUT:
// CHECK:STDOUT: if.else.loc52:                                    ; preds = %if.else.loc49
// CHECK:STDOUT:   %F.call = call i32 @_CF.Main.4d6ceefeb7f772f4(i32 %x, i32 %count), !dbg !85
// CHECK:STDOUT:   ret i32 %F.call, !dbg !86
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CB.Main.c5e4ba542a56b71f(double %x, i32 %count) #0 !dbg !87 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CC.Main.c5e4ba542a56b71f(double %x, i32 %count), !dbg !93
// CHECK:STDOUT:   ret void, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr double @_CD.Main.c5e4ba542a56b71f(double %x, i32 %count) #0 !dbg !95 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call = icmp sgt i32 %count, 4, !dbg !99
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Greater.call, label %if.then.loc49, label %if.else.loc49, !dbg !100
// CHECK:STDOUT:
// CHECK:STDOUT: if.then.loc49:                                    ; preds = %entry
// CHECK:STDOUT:   ret double %x, !dbg !101
// CHECK:STDOUT:
// CHECK:STDOUT: if.else.loc49:                                    ; preds = %entry
// CHECK:STDOUT:   %Int.as.ModWith.impl.Op.call = srem i32 %count, 2, !dbg !102
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call = icmp eq i32 %Int.as.ModWith.impl.Op.call, 0, !dbg !102
// CHECK:STDOUT:   br i1 %Int.as.EqWith.impl.Equal.call, label %if.then.loc52, label %if.else.loc52, !dbg !103
// CHECK:STDOUT:
// CHECK:STDOUT: if.then.loc52:                                    ; preds = %if.else.loc49
// CHECK:STDOUT:   %E.call = call double @_CE.Main.c5e4ba542a56b71f(double %x, i32 %count), !dbg !104
// CHECK:STDOUT:   ret double %E.call, !dbg !105
// CHECK:STDOUT:
// CHECK:STDOUT: if.else.loc52:                                    ; preds = %if.else.loc49
// CHECK:STDOUT:   %F.call = call double @_CF.Main.c5e4ba542a56b71f(double %x, i32 %count), !dbg !106
// CHECK:STDOUT:   ret double %F.call, !dbg !107
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CB.Main.a76b78461416b4a8(ptr %x, i32 %count) #0 !dbg !108 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CC.Main.a76b78461416b4a8(ptr %x, i32 %count), !dbg !112
// CHECK:STDOUT:   ret void, !dbg !113
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CD.Main.a76b78461416b4a8(ptr %x, i32 %count) #0 !dbg !114 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call = icmp sgt i32 %count, 4, !dbg !118
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Greater.call, label %if.then.loc49, label %if.else.loc49, !dbg !119
// CHECK:STDOUT:
// CHECK:STDOUT: if.then.loc49:                                    ; preds = %entry
// CHECK:STDOUT:   ret ptr %x, !dbg !120
// CHECK:STDOUT:
// CHECK:STDOUT: if.else.loc49:                                    ; preds = %entry
// CHECK:STDOUT:   %Int.as.ModWith.impl.Op.call = srem i32 %count, 2, !dbg !121
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call = icmp eq i32 %Int.as.ModWith.impl.Op.call, 0, !dbg !121
// CHECK:STDOUT:   br i1 %Int.as.EqWith.impl.Equal.call, label %if.then.loc52, label %if.else.loc52, !dbg !122
// CHECK:STDOUT:
// CHECK:STDOUT: if.then.loc52:                                    ; preds = %if.else.loc49
// CHECK:STDOUT:   %E.call = call ptr @_CE.Main.a76b78461416b4a8(ptr %x, i32 %count), !dbg !123
// CHECK:STDOUT:   ret ptr %E.call, !dbg !124
// CHECK:STDOUT:
// CHECK:STDOUT: if.else.loc52:                                    ; preds = %if.else.loc49
// CHECK:STDOUT:   %F.call = call ptr @_CF.Main.a76b78461416b4a8(ptr %x, i32 %count), !dbg !125
// CHECK:STDOUT:   ret ptr %F.call, !dbg !126
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CD.Main.5f2298097dd2e04c(ptr %x, i32 %count) #0 !dbg !127 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call = icmp sgt i32 %count, 4, !dbg !131
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.Greater.call, label %if.then.loc49, label %if.else.loc49, !dbg !132
// CHECK:STDOUT:
// CHECK:STDOUT: if.then.loc49:                                    ; preds = %entry
// CHECK:STDOUT:   ret ptr %x, !dbg !133
// CHECK:STDOUT:
// CHECK:STDOUT: if.else.loc49:                                    ; preds = %entry
// CHECK:STDOUT:   %Int.as.ModWith.impl.Op.call = srem i32 %count, 2, !dbg !134
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call = icmp eq i32 %Int.as.ModWith.impl.Op.call, 0, !dbg !134
// CHECK:STDOUT:   br i1 %Int.as.EqWith.impl.Equal.call, label %if.then.loc52, label %if.else.loc52, !dbg !135
// CHECK:STDOUT:
// CHECK:STDOUT: if.then.loc52:                                    ; preds = %if.else.loc49
// CHECK:STDOUT:   %E.call = call ptr @_CE.Main.5f2298097dd2e04c(ptr %x, i32 %count), !dbg !136
// CHECK:STDOUT:   ret ptr %E.call, !dbg !137
// CHECK:STDOUT:
// CHECK:STDOUT: if.else.loc52:                                    ; preds = %if.else.loc49
// CHECK:STDOUT:   %F.call = call ptr @_CF.Main.5f2298097dd2e04c(ptr %x, i32 %count), !dbg !138
// CHECK:STDOUT:   ret ptr %F.call, !dbg !139
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CC.Main.4d6ceefeb7f772f4(i32 %x, i32 %count) #0 !dbg !140 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.LessOrEquivalent.call = icmp sle i32 %count, 2, !dbg !144
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.LessOrEquivalent.call, label %if.then, label %if.else, !dbg !145
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %Print.call = call i32 (ptr, ...) @printf(ptr @printf.int.format, i32 %count), !dbg !146
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %count, 1, !dbg !147
// CHECK:STDOUT:   call void @_CB.Main.4d6ceefeb7f772f4(i32 %x, i32 %Int.as.AddWith.impl.Op.call), !dbg !148
// CHECK:STDOUT:   br label %if.else, !dbg !149
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %if.then, %entry
// CHECK:STDOUT:   ret void, !dbg !150
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CE.Main.4d6ceefeb7f772f4(i32 %x, i32 %count) #0 !dbg !151 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call i32 @_CG.Main.4d6ceefeb7f772f4(i32 %x, i32 %count), !dbg !155
// CHECK:STDOUT:   ret i32 %G.call, !dbg !156
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CF.Main.4d6ceefeb7f772f4(i32 %x, i32 %count) #0 !dbg !157 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call i32 @_CG.Main.4d6ceefeb7f772f4(i32 %x, i32 %count), !dbg !161
// CHECK:STDOUT:   ret i32 %G.call, !dbg !162
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CC.Main.c5e4ba542a56b71f(double %x, i32 %count) #0 !dbg !163 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.LessOrEquivalent.call = icmp sle i32 %count, 2, !dbg !167
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.LessOrEquivalent.call, label %if.then, label %if.else, !dbg !168
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %Print.call = call i32 (ptr, ...) @printf(ptr @printf.int.format, i32 %count), !dbg !169
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %count, 1, !dbg !170
// CHECK:STDOUT:   call void @_CB.Main.c5e4ba542a56b71f(double %x, i32 %Int.as.AddWith.impl.Op.call), !dbg !171
// CHECK:STDOUT:   br label %if.else, !dbg !172
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %if.then, %entry
// CHECK:STDOUT:   ret void, !dbg !173
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr double @_CE.Main.c5e4ba542a56b71f(double %x, i32 %count) #0 !dbg !174 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call double @_CG.Main.c5e4ba542a56b71f(double %x, i32 %count), !dbg !178
// CHECK:STDOUT:   ret double %G.call, !dbg !179
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr double @_CF.Main.c5e4ba542a56b71f(double %x, i32 %count) #0 !dbg !180 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call double @_CG.Main.c5e4ba542a56b71f(double %x, i32 %count), !dbg !184
// CHECK:STDOUT:   ret double %G.call, !dbg !185
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CC.Main.a76b78461416b4a8(ptr %x, i32 %count) #0 !dbg !186 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.LessOrEquivalent.call = icmp sle i32 %count, 2, !dbg !190
// CHECK:STDOUT:   br i1 %Int.as.OrderedWith.impl.LessOrEquivalent.call, label %if.then, label %if.else, !dbg !191
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %Print.call = call i32 (ptr, ...) @printf(ptr @printf.int.format, i32 %count), !dbg !192
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %count, 1, !dbg !193
// CHECK:STDOUT:   call void @_CB.Main.a76b78461416b4a8(ptr %x, i32 %Int.as.AddWith.impl.Op.call), !dbg !194
// CHECK:STDOUT:   br label %if.else, !dbg !195
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %if.then, %entry
// CHECK:STDOUT:   ret void, !dbg !196
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CE.Main.a76b78461416b4a8(ptr %x, i32 %count) #0 !dbg !197 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call ptr @_CG.Main.a76b78461416b4a8(ptr %x, i32 %count), !dbg !201
// CHECK:STDOUT:   ret ptr %G.call, !dbg !202
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CF.Main.a76b78461416b4a8(ptr %x, i32 %count) #0 !dbg !203 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call ptr @_CG.Main.a76b78461416b4a8(ptr %x, i32 %count), !dbg !207
// CHECK:STDOUT:   ret ptr %G.call, !dbg !208
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CE.Main.5f2298097dd2e04c(ptr %x, i32 %count) #0 !dbg !209 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call ptr @_CG.Main.5f2298097dd2e04c(ptr %x, i32 %count), !dbg !213
// CHECK:STDOUT:   ret ptr %G.call, !dbg !214
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CF.Main.5f2298097dd2e04c(ptr %x, i32 %count) #0 !dbg !215 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %G.call = call ptr @_CG.Main.5f2298097dd2e04c(ptr %x, i32 %count), !dbg !219
// CHECK:STDOUT:   ret ptr %G.call, !dbg !220
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @printf(ptr, ...)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CG.Main.4d6ceefeb7f772f4(i32 %x, i32 %count) #0 !dbg !221 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %count, 1, !dbg !225
// CHECK:STDOUT:   %D.call = call i32 @_CD.Main.4d6ceefeb7f772f4(i32 %x, i32 %Int.as.AddWith.impl.Op.call), !dbg !226
// CHECK:STDOUT:   ret i32 %D.call, !dbg !227
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr double @_CG.Main.c5e4ba542a56b71f(double %x, i32 %count) #0 !dbg !228 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %count, 1, !dbg !232
// CHECK:STDOUT:   %D.call = call double @_CD.Main.c5e4ba542a56b71f(double %x, i32 %Int.as.AddWith.impl.Op.call), !dbg !233
// CHECK:STDOUT:   ret double %D.call, !dbg !234
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CG.Main.a76b78461416b4a8(ptr %x, i32 %count) #0 !dbg !235 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %count, 1, !dbg !239
// CHECK:STDOUT:   %D.call = call ptr @_CD.Main.a76b78461416b4a8(ptr %x, i32 %Int.as.AddWith.impl.Op.call), !dbg !240
// CHECK:STDOUT:   ret ptr %D.call, !dbg !241
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CG.Main.5f2298097dd2e04c(ptr %x, i32 %count) #0 !dbg !242 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %count, 1, !dbg !246
// CHECK:STDOUT:   %D.call = call ptr @_CD.Main.5f2298097dd2e04c(ptr %x, i32 %Int.as.AddWith.impl.Op.call), !dbg !247
// CHECK:STDOUT:   ret ptr %D.call, !dbg !248
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CB.Main.a76b78461416b4a8, { 1, 2, 0 }
// CHECK:STDOUT: uselistorder ptr @printf, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CG.Main.4d6ceefeb7f772f4, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CG.Main.c5e4ba542a56b71f, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CG.Main.a76b78461416b4a8, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CG.Main.5f2298097dd2e04c, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "call_recursive_sccs_deep.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "M", linkageName: "_CM.Main", scope: null, file: !1, line: 74, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{null}
// CHECK:STDOUT: !7 = !DILocation(line: 75, column: 3, scope: !4)
// CHECK:STDOUT: !8 = !DILocation(line: 76, column: 3, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 77, column: 3, scope: !4)
// CHECK:STDOUT: !10 = !DILocation(line: 78, column: 3, scope: !4)
// CHECK:STDOUT: !11 = !DILocation(line: 80, column: 5, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 80, column: 3, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 81, column: 5, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 81, column: 3, scope: !4)
// CHECK:STDOUT: !15 = !DILocation(line: 82, column: 5, scope: !4)
// CHECK:STDOUT: !16 = !DILocation(line: 82, column: 3, scope: !4)
// CHECK:STDOUT: !17 = !DILocation(line: 83, column: 5, scope: !4)
// CHECK:STDOUT: !18 = !DILocation(line: 83, column: 3, scope: !4)
// CHECK:STDOUT: !19 = !DILocation(line: 74, column: 1, scope: !4)
// CHECK:STDOUT: !20 = distinct !DISubprogram(name: "Op", linkageName: "_COp.30d8007fdcc57f83:core.Destroy.Core", scope: null, file: !1, line: 76, type: !21, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !24)
// CHECK:STDOUT: !21 = !DISubroutineType(types: !22)
// CHECK:STDOUT: !22 = !{null, !23}
// CHECK:STDOUT: !23 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !24 = !{!25}
// CHECK:STDOUT: !25 = !DILocalVariable(arg: 1, scope: !20, type: !23)
// CHECK:STDOUT: !26 = !DILocation(line: 76, column: 3, scope: !20)
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5e27612b9dd31a14:core.Destroy.Core", scope: null, file: !1, line: 75, type: !28, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !31)
// CHECK:STDOUT: !28 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !29 = !{null, !30}
// CHECK:STDOUT: !30 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !31 = !{!32}
// CHECK:STDOUT: !32 = !DILocalVariable(arg: 1, scope: !27, type: !30)
// CHECK:STDOUT: !33 = !DILocation(line: 75, column: 3, scope: !27)
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "A", linkageName: "_CA.Main.4d6ceefeb7f772f4", scope: null, file: !1, line: 32, type: !35, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !37)
// CHECK:STDOUT: !35 = !DISubroutineType(types: !36)
// CHECK:STDOUT: !36 = !{!30, !30, !30}
// CHECK:STDOUT: !37 = !{!38, !39}
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !34, type: !30)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 2, scope: !34, type: !30)
// CHECK:STDOUT: !40 = !DILocation(line: 33, column: 3, scope: !34)
// CHECK:STDOUT: !41 = !DILocation(line: 34, column: 10, scope: !34)
// CHECK:STDOUT: !42 = !DILocation(line: 34, column: 3, scope: !34)
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "A", linkageName: "_CA.Main.c5e4ba542a56b71f", scope: null, file: !1, line: 32, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !46)
// CHECK:STDOUT: !44 = !DISubroutineType(types: !45)
// CHECK:STDOUT: !45 = !{!23, !23, !30}
// CHECK:STDOUT: !46 = !{!47, !48}
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !43, type: !23)
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 2, scope: !43, type: !30)
// CHECK:STDOUT: !49 = !DILocation(line: 33, column: 3, scope: !43)
// CHECK:STDOUT: !50 = !DILocation(line: 34, column: 10, scope: !43)
// CHECK:STDOUT: !51 = !DILocation(line: 34, column: 3, scope: !43)
// CHECK:STDOUT: !52 = distinct !DISubprogram(name: "A", linkageName: "_CA.Main.a76b78461416b4a8", scope: null, file: !1, line: 32, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !53)
// CHECK:STDOUT: !53 = !{!54, !55}
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !52, type: !23)
// CHECK:STDOUT: !55 = !DILocalVariable(arg: 2, scope: !52, type: !30)
// CHECK:STDOUT: !56 = !DILocation(line: 33, column: 3, scope: !52)
// CHECK:STDOUT: !57 = !DILocation(line: 34, column: 10, scope: !52)
// CHECK:STDOUT: !58 = !DILocation(line: 34, column: 3, scope: !52)
// CHECK:STDOUT: !59 = distinct !DISubprogram(name: "A", linkageName: "_CA.Main.5f2298097dd2e04c", scope: null, file: !1, line: 32, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !60)
// CHECK:STDOUT: !60 = !{!61, !62}
// CHECK:STDOUT: !61 = !DILocalVariable(arg: 1, scope: !59, type: !23)
// CHECK:STDOUT: !62 = !DILocalVariable(arg: 2, scope: !59, type: !30)
// CHECK:STDOUT: !63 = !DILocation(line: 33, column: 3, scope: !59)
// CHECK:STDOUT: !64 = !DILocation(line: 34, column: 10, scope: !59)
// CHECK:STDOUT: !65 = !DILocation(line: 34, column: 3, scope: !59)
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "B", linkageName: "_CB.Main.4d6ceefeb7f772f4", scope: null, file: !1, line: 37, type: !67, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !69)
// CHECK:STDOUT: !67 = !DISubroutineType(types: !68)
// CHECK:STDOUT: !68 = !{null, !30, !30}
// CHECK:STDOUT: !69 = !{!70, !71}
// CHECK:STDOUT: !70 = !DILocalVariable(arg: 1, scope: !66, type: !30)
// CHECK:STDOUT: !71 = !DILocalVariable(arg: 2, scope: !66, type: !30)
// CHECK:STDOUT: !72 = !DILocation(line: 38, column: 3, scope: !66)
// CHECK:STDOUT: !73 = !DILocation(line: 37, column: 1, scope: !66)
// CHECK:STDOUT: !74 = distinct !DISubprogram(name: "D", linkageName: "_CD.Main.4d6ceefeb7f772f4", scope: null, file: !1, line: 48, type: !35, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !75)
// CHECK:STDOUT: !75 = !{!76, !77}
// CHECK:STDOUT: !76 = !DILocalVariable(arg: 1, scope: !74, type: !30)
// CHECK:STDOUT: !77 = !DILocalVariable(arg: 2, scope: !74, type: !30)
// CHECK:STDOUT: !78 = !DILocation(line: 49, column: 7, scope: !74)
// CHECK:STDOUT: !79 = !DILocation(line: 49, column: 6, scope: !74)
// CHECK:STDOUT: !80 = !DILocation(line: 50, column: 5, scope: !74)
// CHECK:STDOUT: !81 = !DILocation(line: 52, column: 7, scope: !74)
// CHECK:STDOUT: !82 = !DILocation(line: 52, column: 6, scope: !74)
// CHECK:STDOUT: !83 = !DILocation(line: 53, column: 12, scope: !74)
// CHECK:STDOUT: !84 = !DILocation(line: 53, column: 5, scope: !74)
// CHECK:STDOUT: !85 = !DILocation(line: 55, column: 12, scope: !74)
// CHECK:STDOUT: !86 = !DILocation(line: 55, column: 5, scope: !74)
// CHECK:STDOUT: !87 = distinct !DISubprogram(name: "B", linkageName: "_CB.Main.c5e4ba542a56b71f", scope: null, file: !1, line: 37, type: !88, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !90)
// CHECK:STDOUT: !88 = !DISubroutineType(types: !89)
// CHECK:STDOUT: !89 = !{null, !23, !30}
// CHECK:STDOUT: !90 = !{!91, !92}
// CHECK:STDOUT: !91 = !DILocalVariable(arg: 1, scope: !87, type: !23)
// CHECK:STDOUT: !92 = !DILocalVariable(arg: 2, scope: !87, type: !30)
// CHECK:STDOUT: !93 = !DILocation(line: 38, column: 3, scope: !87)
// CHECK:STDOUT: !94 = !DILocation(line: 37, column: 1, scope: !87)
// CHECK:STDOUT: !95 = distinct !DISubprogram(name: "D", linkageName: "_CD.Main.c5e4ba542a56b71f", scope: null, file: !1, line: 48, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !96)
// CHECK:STDOUT: !96 = !{!97, !98}
// CHECK:STDOUT: !97 = !DILocalVariable(arg: 1, scope: !95, type: !23)
// CHECK:STDOUT: !98 = !DILocalVariable(arg: 2, scope: !95, type: !30)
// CHECK:STDOUT: !99 = !DILocation(line: 49, column: 7, scope: !95)
// CHECK:STDOUT: !100 = !DILocation(line: 49, column: 6, scope: !95)
// CHECK:STDOUT: !101 = !DILocation(line: 50, column: 5, scope: !95)
// CHECK:STDOUT: !102 = !DILocation(line: 52, column: 7, scope: !95)
// CHECK:STDOUT: !103 = !DILocation(line: 52, column: 6, scope: !95)
// CHECK:STDOUT: !104 = !DILocation(line: 53, column: 12, scope: !95)
// CHECK:STDOUT: !105 = !DILocation(line: 53, column: 5, scope: !95)
// CHECK:STDOUT: !106 = !DILocation(line: 55, column: 12, scope: !95)
// CHECK:STDOUT: !107 = !DILocation(line: 55, column: 5, scope: !95)
// CHECK:STDOUT: !108 = distinct !DISubprogram(name: "B", linkageName: "_CB.Main.a76b78461416b4a8", scope: null, file: !1, line: 37, type: !88, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !109)
// CHECK:STDOUT: !109 = !{!110, !111}
// CHECK:STDOUT: !110 = !DILocalVariable(arg: 1, scope: !108, type: !23)
// CHECK:STDOUT: !111 = !DILocalVariable(arg: 2, scope: !108, type: !30)
// CHECK:STDOUT: !112 = !DILocation(line: 38, column: 3, scope: !108)
// CHECK:STDOUT: !113 = !DILocation(line: 37, column: 1, scope: !108)
// CHECK:STDOUT: !114 = distinct !DISubprogram(name: "D", linkageName: "_CD.Main.a76b78461416b4a8", scope: null, file: !1, line: 48, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !115)
// CHECK:STDOUT: !115 = !{!116, !117}
// CHECK:STDOUT: !116 = !DILocalVariable(arg: 1, scope: !114, type: !23)
// CHECK:STDOUT: !117 = !DILocalVariable(arg: 2, scope: !114, type: !30)
// CHECK:STDOUT: !118 = !DILocation(line: 49, column: 7, scope: !114)
// CHECK:STDOUT: !119 = !DILocation(line: 49, column: 6, scope: !114)
// CHECK:STDOUT: !120 = !DILocation(line: 50, column: 5, scope: !114)
// CHECK:STDOUT: !121 = !DILocation(line: 52, column: 7, scope: !114)
// CHECK:STDOUT: !122 = !DILocation(line: 52, column: 6, scope: !114)
// CHECK:STDOUT: !123 = !DILocation(line: 53, column: 12, scope: !114)
// CHECK:STDOUT: !124 = !DILocation(line: 53, column: 5, scope: !114)
// CHECK:STDOUT: !125 = !DILocation(line: 55, column: 12, scope: !114)
// CHECK:STDOUT: !126 = !DILocation(line: 55, column: 5, scope: !114)
// CHECK:STDOUT: !127 = distinct !DISubprogram(name: "D", linkageName: "_CD.Main.5f2298097dd2e04c", scope: null, file: !1, line: 48, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !128)
// CHECK:STDOUT: !128 = !{!129, !130}
// CHECK:STDOUT: !129 = !DILocalVariable(arg: 1, scope: !127, type: !23)
// CHECK:STDOUT: !130 = !DILocalVariable(arg: 2, scope: !127, type: !30)
// CHECK:STDOUT: !131 = !DILocation(line: 49, column: 7, scope: !127)
// CHECK:STDOUT: !132 = !DILocation(line: 49, column: 6, scope: !127)
// CHECK:STDOUT: !133 = !DILocation(line: 50, column: 5, scope: !127)
// CHECK:STDOUT: !134 = !DILocation(line: 52, column: 7, scope: !127)
// CHECK:STDOUT: !135 = !DILocation(line: 52, column: 6, scope: !127)
// CHECK:STDOUT: !136 = !DILocation(line: 53, column: 12, scope: !127)
// CHECK:STDOUT: !137 = !DILocation(line: 53, column: 5, scope: !127)
// CHECK:STDOUT: !138 = !DILocation(line: 55, column: 12, scope: !127)
// CHECK:STDOUT: !139 = !DILocation(line: 55, column: 5, scope: !127)
// CHECK:STDOUT: !140 = distinct !DISubprogram(name: "C", linkageName: "_CC.Main.4d6ceefeb7f772f4", scope: null, file: !1, line: 41, type: !67, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !141)
// CHECK:STDOUT: !141 = !{!142, !143}
// CHECK:STDOUT: !142 = !DILocalVariable(arg: 1, scope: !140, type: !30)
// CHECK:STDOUT: !143 = !DILocalVariable(arg: 2, scope: !140, type: !30)
// CHECK:STDOUT: !144 = !DILocation(line: 42, column: 7, scope: !140)
// CHECK:STDOUT: !145 = !DILocation(line: 42, column: 6, scope: !140)
// CHECK:STDOUT: !146 = !DILocation(line: 43, column: 5, scope: !140)
// CHECK:STDOUT: !147 = !DILocation(line: 44, column: 10, scope: !140)
// CHECK:STDOUT: !148 = !DILocation(line: 44, column: 5, scope: !140)
// CHECK:STDOUT: !149 = !DILocation(line: 42, column: 3, scope: !140)
// CHECK:STDOUT: !150 = !DILocation(line: 41, column: 1, scope: !140)
// CHECK:STDOUT: !151 = distinct !DISubprogram(name: "E", linkageName: "_CE.Main.4d6ceefeb7f772f4", scope: null, file: !1, line: 61, type: !35, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !152)
// CHECK:STDOUT: !152 = !{!153, !154}
// CHECK:STDOUT: !153 = !DILocalVariable(arg: 1, scope: !151, type: !30)
// CHECK:STDOUT: !154 = !DILocalVariable(arg: 2, scope: !151, type: !30)
// CHECK:STDOUT: !155 = !DILocation(line: 62, column: 10, scope: !151)
// CHECK:STDOUT: !156 = !DILocation(line: 62, column: 3, scope: !151)
// CHECK:STDOUT: !157 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.4d6ceefeb7f772f4", scope: null, file: !1, line: 65, type: !35, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !158)
// CHECK:STDOUT: !158 = !{!159, !160}
// CHECK:STDOUT: !159 = !DILocalVariable(arg: 1, scope: !157, type: !30)
// CHECK:STDOUT: !160 = !DILocalVariable(arg: 2, scope: !157, type: !30)
// CHECK:STDOUT: !161 = !DILocation(line: 66, column: 10, scope: !157)
// CHECK:STDOUT: !162 = !DILocation(line: 66, column: 3, scope: !157)
// CHECK:STDOUT: !163 = distinct !DISubprogram(name: "C", linkageName: "_CC.Main.c5e4ba542a56b71f", scope: null, file: !1, line: 41, type: !88, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !164)
// CHECK:STDOUT: !164 = !{!165, !166}
// CHECK:STDOUT: !165 = !DILocalVariable(arg: 1, scope: !163, type: !23)
// CHECK:STDOUT: !166 = !DILocalVariable(arg: 2, scope: !163, type: !30)
// CHECK:STDOUT: !167 = !DILocation(line: 42, column: 7, scope: !163)
// CHECK:STDOUT: !168 = !DILocation(line: 42, column: 6, scope: !163)
// CHECK:STDOUT: !169 = !DILocation(line: 43, column: 5, scope: !163)
// CHECK:STDOUT: !170 = !DILocation(line: 44, column: 10, scope: !163)
// CHECK:STDOUT: !171 = !DILocation(line: 44, column: 5, scope: !163)
// CHECK:STDOUT: !172 = !DILocation(line: 42, column: 3, scope: !163)
// CHECK:STDOUT: !173 = !DILocation(line: 41, column: 1, scope: !163)
// CHECK:STDOUT: !174 = distinct !DISubprogram(name: "E", linkageName: "_CE.Main.c5e4ba542a56b71f", scope: null, file: !1, line: 61, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !175)
// CHECK:STDOUT: !175 = !{!176, !177}
// CHECK:STDOUT: !176 = !DILocalVariable(arg: 1, scope: !174, type: !23)
// CHECK:STDOUT: !177 = !DILocalVariable(arg: 2, scope: !174, type: !30)
// CHECK:STDOUT: !178 = !DILocation(line: 62, column: 10, scope: !174)
// CHECK:STDOUT: !179 = !DILocation(line: 62, column: 3, scope: !174)
// CHECK:STDOUT: !180 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.c5e4ba542a56b71f", scope: null, file: !1, line: 65, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !181)
// CHECK:STDOUT: !181 = !{!182, !183}
// CHECK:STDOUT: !182 = !DILocalVariable(arg: 1, scope: !180, type: !23)
// CHECK:STDOUT: !183 = !DILocalVariable(arg: 2, scope: !180, type: !30)
// CHECK:STDOUT: !184 = !DILocation(line: 66, column: 10, scope: !180)
// CHECK:STDOUT: !185 = !DILocation(line: 66, column: 3, scope: !180)
// CHECK:STDOUT: !186 = distinct !DISubprogram(name: "C", linkageName: "_CC.Main.a76b78461416b4a8", scope: null, file: !1, line: 41, type: !88, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !187)
// CHECK:STDOUT: !187 = !{!188, !189}
// CHECK:STDOUT: !188 = !DILocalVariable(arg: 1, scope: !186, type: !23)
// CHECK:STDOUT: !189 = !DILocalVariable(arg: 2, scope: !186, type: !30)
// CHECK:STDOUT: !190 = !DILocation(line: 42, column: 7, scope: !186)
// CHECK:STDOUT: !191 = !DILocation(line: 42, column: 6, scope: !186)
// CHECK:STDOUT: !192 = !DILocation(line: 43, column: 5, scope: !186)
// CHECK:STDOUT: !193 = !DILocation(line: 44, column: 10, scope: !186)
// CHECK:STDOUT: !194 = !DILocation(line: 44, column: 5, scope: !186)
// CHECK:STDOUT: !195 = !DILocation(line: 42, column: 3, scope: !186)
// CHECK:STDOUT: !196 = !DILocation(line: 41, column: 1, scope: !186)
// CHECK:STDOUT: !197 = distinct !DISubprogram(name: "E", linkageName: "_CE.Main.a76b78461416b4a8", scope: null, file: !1, line: 61, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !198)
// CHECK:STDOUT: !198 = !{!199, !200}
// CHECK:STDOUT: !199 = !DILocalVariable(arg: 1, scope: !197, type: !23)
// CHECK:STDOUT: !200 = !DILocalVariable(arg: 2, scope: !197, type: !30)
// CHECK:STDOUT: !201 = !DILocation(line: 62, column: 10, scope: !197)
// CHECK:STDOUT: !202 = !DILocation(line: 62, column: 3, scope: !197)
// CHECK:STDOUT: !203 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.a76b78461416b4a8", scope: null, file: !1, line: 65, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !204)
// CHECK:STDOUT: !204 = !{!205, !206}
// CHECK:STDOUT: !205 = !DILocalVariable(arg: 1, scope: !203, type: !23)
// CHECK:STDOUT: !206 = !DILocalVariable(arg: 2, scope: !203, type: !30)
// CHECK:STDOUT: !207 = !DILocation(line: 66, column: 10, scope: !203)
// CHECK:STDOUT: !208 = !DILocation(line: 66, column: 3, scope: !203)
// CHECK:STDOUT: !209 = distinct !DISubprogram(name: "E", linkageName: "_CE.Main.5f2298097dd2e04c", scope: null, file: !1, line: 61, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !210)
// CHECK:STDOUT: !210 = !{!211, !212}
// CHECK:STDOUT: !211 = !DILocalVariable(arg: 1, scope: !209, type: !23)
// CHECK:STDOUT: !212 = !DILocalVariable(arg: 2, scope: !209, type: !30)
// CHECK:STDOUT: !213 = !DILocation(line: 62, column: 10, scope: !209)
// CHECK:STDOUT: !214 = !DILocation(line: 62, column: 3, scope: !209)
// CHECK:STDOUT: !215 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main.5f2298097dd2e04c", scope: null, file: !1, line: 65, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !216)
// CHECK:STDOUT: !216 = !{!217, !218}
// CHECK:STDOUT: !217 = !DILocalVariable(arg: 1, scope: !215, type: !23)
// CHECK:STDOUT: !218 = !DILocalVariable(arg: 2, scope: !215, type: !30)
// CHECK:STDOUT: !219 = !DILocation(line: 66, column: 10, scope: !215)
// CHECK:STDOUT: !220 = !DILocation(line: 66, column: 3, scope: !215)
// CHECK:STDOUT: !221 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.4d6ceefeb7f772f4", scope: null, file: !1, line: 69, type: !35, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !222)
// CHECK:STDOUT: !222 = !{!223, !224}
// CHECK:STDOUT: !223 = !DILocalVariable(arg: 1, scope: !221, type: !30)
// CHECK:STDOUT: !224 = !DILocalVariable(arg: 2, scope: !221, type: !30)
// CHECK:STDOUT: !225 = !DILocation(line: 70, column: 15, scope: !221)
// CHECK:STDOUT: !226 = !DILocation(line: 70, column: 10, scope: !221)
// CHECK:STDOUT: !227 = !DILocation(line: 70, column: 3, scope: !221)
// CHECK:STDOUT: !228 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.c5e4ba542a56b71f", scope: null, file: !1, line: 69, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !229)
// CHECK:STDOUT: !229 = !{!230, !231}
// CHECK:STDOUT: !230 = !DILocalVariable(arg: 1, scope: !228, type: !23)
// CHECK:STDOUT: !231 = !DILocalVariable(arg: 2, scope: !228, type: !30)
// CHECK:STDOUT: !232 = !DILocation(line: 70, column: 15, scope: !228)
// CHECK:STDOUT: !233 = !DILocation(line: 70, column: 10, scope: !228)
// CHECK:STDOUT: !234 = !DILocation(line: 70, column: 3, scope: !228)
// CHECK:STDOUT: !235 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.a76b78461416b4a8", scope: null, file: !1, line: 69, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !236)
// CHECK:STDOUT: !236 = !{!237, !238}
// CHECK:STDOUT: !237 = !DILocalVariable(arg: 1, scope: !235, type: !23)
// CHECK:STDOUT: !238 = !DILocalVariable(arg: 2, scope: !235, type: !30)
// CHECK:STDOUT: !239 = !DILocation(line: 70, column: 15, scope: !235)
// CHECK:STDOUT: !240 = !DILocation(line: 70, column: 10, scope: !235)
// CHECK:STDOUT: !241 = !DILocation(line: 70, column: 3, scope: !235)
// CHECK:STDOUT: !242 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main.5f2298097dd2e04c", scope: null, file: !1, line: 69, type: !44, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !243)
// CHECK:STDOUT: !243 = !{!244, !245}
// CHECK:STDOUT: !244 = !DILocalVariable(arg: 1, scope: !242, type: !23)
// CHECK:STDOUT: !245 = !DILocalVariable(arg: 2, scope: !242, type: !30)
// CHECK:STDOUT: !246 = !DILocation(line: 70, column: 15, scope: !242)
// CHECK:STDOUT: !247 = !DILocation(line: 70, column: 10, scope: !242)
// CHECK:STDOUT: !248 = !DILocation(line: 70, column: 3, scope: !242)
// CHECK:STDOUT:

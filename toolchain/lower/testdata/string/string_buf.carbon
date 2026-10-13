// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/string/string_buf.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/string/string_buf.carbon

// Fork (ST-1, fork/string/plan.md §4): `+` returns a `Core.StringBuf` whose
// declared `Destroy` impl runs at the end of the scope; the intermediate
// temporary of a chained `+` in a `var` initializer is destroyed at the end of
// the enclosing block, just before `s` (today's toolchain, ST-1 M-7); and a
// `Core.StringBuf` field of a class without a declared `Destroy` is destroyed
// by that class's synthesized destructor.

fn Concat(a: str, b: str) -> i64 {
  var s: Core.StringBuf = a + b;
  s += "!";
  return s.Size();
}

fn Chain(a: str) -> i64 {
  var s: Core.StringBuf = a + a + a;
  return s.Size();
}

class Holder {
  var text: Core.StringBuf;
}

fn Field(a: str) -> i64 {
  var h: Holder = {.text = a + a};
  return h.text.Size();
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'string_buf.carbon'
// CHECK:STDOUT: source_filename = "string_buf.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [2 x i8] c"!\00", align 1
// CHECK:STDOUT: @String.val.String.val = internal constant { ptr, i64 } { ptr @0, i64 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CConcat.Main(ptr %a, ptr %b) #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %s.var = alloca { ptr, i64 }, align 8, !dbg !26
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %s.var), !dbg !26
// CHECK:STDOUT:   call void @"_COp.String.Core:AddWith.031c1d1c7540fb09.Core"(ptr %s.var, ptr %a, ptr %b), !dbg !27
// CHECK:STDOUT:   call void @"_COp.StringBuf.Core:AddAssignWith.031c1d1c7540fb09.Core"(ptr %s.var, ptr @String.val.String.val), !dbg !30
// CHECK:STDOUT:   %StringBuf.Size.call = call i64 @_CSize.StringBuf.Core(ptr %s.var), !dbg !31
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.8c28af5f9c2d057a(ptr %s.var), !dbg !26
// CHECK:STDOUT:   ret i64 %StringBuf.Size.call, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_COp.String.Core:AddWith.031c1d1c7540fb09.Core"(ptr sret({ ptr, i64 }), ptr, ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_COp.StringBuf.Core:AddAssignWith.031c1d1c7540fb09.Core"(ptr, ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @_CSize.StringBuf.Core(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CChain.Main(ptr %a) #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %s.var = alloca { ptr, i64 }, align 8, !dbg !39
// CHECK:STDOUT:   %.loc27_29.1.temp = alloca { ptr, i64 }, align 8, !dbg !40
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %s.var), !dbg !39
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc27_29.1.temp), !dbg !40
// CHECK:STDOUT:   call void @"_COp.String.Core:AddWith.031c1d1c7540fb09.Core"(ptr %.loc27_29.1.temp, ptr %a, ptr %a), !dbg !40
// CHECK:STDOUT:   call void @"_COp.StringBuf.Core:AddWith.031c1d1c7540fb09.Core"(ptr %s.var, ptr %.loc27_29.1.temp, ptr %a), !dbg !40
// CHECK:STDOUT:   %StringBuf.Size.call = call i64 @_CSize.StringBuf.Core(ptr %s.var), !dbg !44
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.8c28af5f9c2d057a(ptr %.loc27_29.1.temp), !dbg !40
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.8c28af5f9c2d057a(ptr %s.var), !dbg !39
// CHECK:STDOUT:   ret i64 %StringBuf.Size.call, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_COp.StringBuf.Core:AddWith.031c1d1c7540fb09.Core"(ptr sret({ ptr, i64 }), ptr, ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CField.Main(ptr %a) #0 !dbg !47 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %h.var = alloca { { ptr, i64 } }, align 8, !dbg !52
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %h.var), !dbg !52
// CHECK:STDOUT:   %.loc36_33.1.text = getelementptr inbounds nuw { { ptr, i64 } }, ptr %h.var, i32 0, i32 0, !dbg !55
// CHECK:STDOUT:   call void @"_COp.String.Core:AddWith.031c1d1c7540fb09.Core"(ptr %.loc36_33.1.text, ptr %a, ptr %a), !dbg !53
// CHECK:STDOUT:   %.loc37_11.1.text = getelementptr inbounds nuw { { ptr, i64 } }, ptr %h.var, i32 0, i32 0, !dbg !57
// CHECK:STDOUT:   %StringBuf.Size.call = call i64 @_CSize.StringBuf.Core(ptr %.loc37_11.1.text), !dbg !57
// CHECK:STDOUT:   call void @"_CSelfDestruct.e502e02168ac7e71:core.Destroy.Core"(ptr %h.var), !dbg !52
// CHECK:STDOUT:   ret i64 %StringBuf.Size.call, !dbg !58
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.8192ac0493e3e7c8:core.Destroy.Core"(ptr %self) #0 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc36_3.1.text = getelementptr inbounds nuw { { ptr, i64 } }, ptr %self, i32 0, i32 0, !dbg !62
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.8c28af5f9c2d057a(ptr %.loc36_3.1.text), !dbg !62
// CHECK:STDOUT:   ret void, !dbg !62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.8192ac0493e3e7c8:core.Destroy.Core"(ptr %self) #0 !dbg !64 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.8192ac0493e3e7c8:core.Destroy.Core"(ptr %self), !dbg !66
// CHECK:STDOUT:   ret void, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e502e02168ac7e71:core.Destroy.Core"(ptr %self) #0 !dbg !68 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc36_3.1.text = getelementptr inbounds nuw { { ptr, i64 } }, ptr %self, i32 0, i32 0, !dbg !70
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.8c28af5f9c2d057a(ptr %.loc36_3.1.text), !dbg !70
// CHECK:STDOUT:   ret void, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e502e02168ac7e71:core.Destroy.Core"(ptr %self) #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e502e02168ac7e71:core.Destroy.Core"(ptr %self), !dbg !74
// CHECK:STDOUT:   ret void, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_COp.StringBuf.Core:Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.8c28af5f9c2d057a(ptr %self) #0 !dbg !77 {
// CHECK:STDOUT:   call void @"_COp.StringBuf.Core:Destroy.Core"(ptr %self), !dbg !80
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.8c28af5f9c2d057a(ptr %self), !dbg !81
// CHECK:STDOUT:   ret void, !dbg !82
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.8c28af5f9c2d057a(ptr %self) #0 !dbg !84 {
// CHECK:STDOUT:   ret void, !dbg !87
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CSelfDestruct.Destroy.Core.8c28af5f9c2d057a, { 4, 3, 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "string_buf.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!6, !8, !8}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !15 = !{!6, !8}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = !{null, !8}
// CHECK:STDOUT: !18 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "Concat", linkageName: "_CConcat.Main", scope: null, file: !4, line: 20, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !33)
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !19, type: !8)
// CHECK:STDOUT: !21 = !DILocalVariable(arg: 2, scope: !19, type: !8)
// CHECK:STDOUT: !26 = !DILocation(line: 21, column: 3, scope: !19)
// CHECK:STDOUT: !27 = !DILocation(line: 21, column: 27, scope: !19)
// CHECK:STDOUT: !30 = !DILocation(line: 22, column: 3, scope: !19)
// CHECK:STDOUT: !31 = !DILocation(line: 23, column: 10, scope: !19)
// CHECK:STDOUT: !32 = !DILocation(line: 23, column: 3, scope: !19)
// CHECK:STDOUT: !33 = !{!20, !21}
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "Chain", linkageName: "_CChain.Main", scope: null, file: !4, line: 26, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !46)
// CHECK:STDOUT: !35 = !DILocalVariable(arg: 1, scope: !34, type: !8)
// CHECK:STDOUT: !39 = !DILocation(line: 27, column: 3, scope: !34)
// CHECK:STDOUT: !40 = !DILocation(line: 27, column: 27, scope: !34)
// CHECK:STDOUT: !44 = !DILocation(line: 28, column: 10, scope: !34)
// CHECK:STDOUT: !45 = !DILocation(line: 28, column: 3, scope: !34)
// CHECK:STDOUT: !46 = !{!35}
// CHECK:STDOUT: !47 = distinct !DISubprogram(name: "Field", linkageName: "_CField.Main", scope: null, file: !4, line: 35, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !59)
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !47, type: !8)
// CHECK:STDOUT: !52 = !DILocation(line: 36, column: 3, scope: !47)
// CHECK:STDOUT: !53 = !DILocation(line: 36, column: 28, scope: !47)
// CHECK:STDOUT: !55 = !DILocation(line: 36, column: 19, scope: !47)
// CHECK:STDOUT: !57 = !DILocation(line: 37, column: 10, scope: !47)
// CHECK:STDOUT: !58 = !DILocation(line: 37, column: 3, scope: !47)
// CHECK:STDOUT: !59 = !{!48}
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.8192ac0493e3e7c8:core.Destroy.Core", scope: null, file: !4, line: 36, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !63)
// CHECK:STDOUT: !61 = !DILocalVariable(arg: 1, scope: !60, type: !8)
// CHECK:STDOUT: !62 = !DILocation(line: 36, column: 3, scope: !60)
// CHECK:STDOUT: !63 = !{!61}
// CHECK:STDOUT: !64 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.8192ac0493e3e7c8:core.Destroy.Core", scope: null, file: !4, line: 36, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !67)
// CHECK:STDOUT: !65 = !DILocalVariable(arg: 1, scope: !64, type: !8)
// CHECK:STDOUT: !66 = !DILocation(line: 36, column: 3, scope: !64)
// CHECK:STDOUT: !67 = !{!65}
// CHECK:STDOUT: !68 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e502e02168ac7e71:core.Destroy.Core", scope: null, file: !4, line: 36, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !71)
// CHECK:STDOUT: !69 = !DILocalVariable(arg: 1, scope: !68, type: !8)
// CHECK:STDOUT: !70 = !DILocation(line: 36, column: 3, scope: !68)
// CHECK:STDOUT: !71 = !{!69}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e502e02168ac7e71:core.Destroy.Core", scope: null, file: !4, line: 36, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !75)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !8)
// CHECK:STDOUT: !74 = !DILocation(line: 36, column: 3, scope: !72)
// CHECK:STDOUT: !75 = !{!73}
// CHECK:STDOUT: !76 = !DIFile(filename: "{{.*}}/prelude/destroy.carbon", directory: "")
// CHECK:STDOUT: !77 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.8c28af5f9c2d057a", scope: null, file: !76, line: 26, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !83)
// CHECK:STDOUT: !78 = !DILocalVariable(arg: 1, scope: !77, type: !8)
// CHECK:STDOUT: !80 = !DILocation(line: 27, column: 5, scope: !77)
// CHECK:STDOUT: !81 = !DILocation(line: 28, column: 5, scope: !77)
// CHECK:STDOUT: !82 = !DILocation(line: 26, column: 3, scope: !77)
// CHECK:STDOUT: !83 = !{!78}
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.8c28af5f9c2d057a", scope: null, file: !76, line: 19, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !88)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !84, type: !8)
// CHECK:STDOUT: !87 = !DILocation(line: 19, column: 3, scope: !84)
// CHECK:STDOUT: !88 = !{!85}
// CHECK:STDOUT:

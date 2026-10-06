// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/var/destroy_control_flow.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/var/destroy_control_flow.carbon

// --- destructible.carbon

library "[[@TEST_NAME]]";

class Destructible {
  // TODO: Implement Core.Destructor instead.
  impl as Core.Destroy {
    fn Op(self);
  }
};

fn Use(ref d: Destructible);

// --- if_then.carbon

library "[[@TEST_NAME]]";
import library "destructible";

fn IfThen(cond: bool) {
  var a: Destructible = {};
  Use(ref a);
  if (cond) {
    var b: Destructible = {};
    Use(ref b);
  }
  Use(ref a);
}

// --- if_else.carbon

library "[[@TEST_NAME]]";
import library "destructible";

fn IfElse(cond: bool) {
  var a: Destructible = {};
  Use(ref a);
  if (cond) {
    var b: Destructible = {};
    Use(ref b);
  } else {
    var c: Destructible = {};
    Use(ref c);
  }
  Use(ref a);
}

// --- if_return.carbon

library "[[@TEST_NAME]]";
import library "destructible";

fn IfReturn(cond: bool) {
  var a: Destructible = {};
  Use(ref a);
  if (cond) {
    var b: Destructible = {};
    Use(ref b);
    return;
  }
}

// --- while_break.carbon

library "[[@TEST_NAME]]";
import library "destructible";

fn WhileBreak(cond: bool) {
  var a: Destructible = {};
  Use(ref a);
  while (cond) {
    Use(ref a);
    var b: Destructible = {};
    Use(ref b);
    if (cond) {
      var c: Destructible = {};
      Use(ref c);
      break;
    }
  }
  Use(ref a);
}

// --- while_continue.carbon

library "[[@TEST_NAME]]";
import library "destructible";

fn WhileContinue(cond: bool) {
  var a: Destructible = {};
  Use(ref a);
  while (cond) {
    Use(ref a);
    var b: Destructible = {};
    Use(ref b);
    if (cond) {
      var c: Destructible = {};
      Use(ref c);
      continue;
    }
  }
  Use(ref a);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'destructible.carbon'
// CHECK:STDOUT: source_filename = "destructible.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_COp.Destructible.Main:Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_COp:thunk:Destroy.3fda586d04e243ea.Core:Destructible.Main:Destroy.Core"(ptr %self) #0 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_COp.Destructible.Main:Destroy.Core"(ptr %self), !dbg !40
// CHECK:STDOUT:   ret void, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CUse.Main(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { alwaysinline nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!33}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !32 = !DIFile(filename: "destructible.carbon", directory: "")
// CHECK:STDOUT: !33 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !32, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !34 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !35 = !{null, !34}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:Destroy.3fda586d04e243ea.Core:Destructible.Main:Destroy.Core", scope: null, file: !32, line: 7, type: !36, spFlags: DISPFlagDefinition, unit: !33, retainedNodes: !41)
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !37, type: !34)
// CHECK:STDOUT: !40 = !DILocation(line: 7, column: 5, scope: !37)
// CHECK:STDOUT: !41 = !{!38}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'if_then.carbon'
// CHECK:STDOUT: source_filename = "if_then.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Destructible.val.loc6_3.1 = internal constant {} zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CIfThen.Main(i1 %cond) #0 !dbg !44 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.var = alloca {}, align 1, !dbg !47
// CHECK:STDOUT:   %b.var = alloca {}, align 1, !dbg !54
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a.var), !dbg !47
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %a.var, ptr align 1 @Destructible.val.loc6_3.1, i64 0, i1 false), !dbg !47
// CHECK:STDOUT:   call void @_CUse.Main(ptr %a.var), !dbg !51
// CHECK:STDOUT:   br i1 %cond, label %if.then, label %if.else, !dbg !53
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !54
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %b.var, ptr align 1 @Destructible.val.loc6_3.1, i64 0, i1 false), !dbg !54
// CHECK:STDOUT:   call void @_CUse.Main(ptr %b.var), !dbg !58
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %b.var), !dbg !54
// CHECK:STDOUT:   br label %if.else, !dbg !59
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %if.then, %entry
// CHECK:STDOUT:   call void @_CUse.Main(ptr %a.var), !dbg !62
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %a.var), !dbg !47
// CHECK:STDOUT:   ret void, !dbg !63
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CUse.Main(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_COp:thunk:Destroy.9631b3a587cc85dc.Core:Destructible.Main:Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %self) #0 !dbg !65 {
// CHECK:STDOUT:   call void @"_COp:thunk:Destroy.9631b3a587cc85dc.Core:Destructible.Main:Destroy.Core"(ptr %self), !dbg !68
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.9631b3a587cc85dc(ptr %self), !dbg !69
// CHECK:STDOUT:   ret void, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.9631b3a587cc85dc(ptr %self) #0 !dbg !72 {
// CHECK:STDOUT:   ret void, !dbg !75
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CUse.Main, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!43}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !28 = !DIFile(filename: "min_prelude/parts/destroy.carbon", directory: "")
// CHECK:STDOUT: !34 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !35 = !{null, !34}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !42 = !DIFile(filename: "if_then.carbon", directory: "")
// CHECK:STDOUT: !43 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !42, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !44 = distinct !DISubprogram(name: "IfThen", linkageName: "_CIfThen.Main", scope: null, file: !42, line: 5, type: !36, spFlags: DISPFlagDefinition, unit: !43, retainedNodes: !64)
// CHECK:STDOUT: !45 = !DILocalVariable(arg: 1, scope: !44, type: !34)
// CHECK:STDOUT: !47 = !DILocation(line: 6, column: 3, scope: !44)
// CHECK:STDOUT: !51 = !DILocation(line: 7, column: 3, scope: !44)
// CHECK:STDOUT: !53 = !DILocation(line: 8, column: 6, scope: !44)
// CHECK:STDOUT: !54 = !DILocation(line: 9, column: 5, scope: !44)
// CHECK:STDOUT: !58 = !DILocation(line: 10, column: 5, scope: !44)
// CHECK:STDOUT: !59 = !DILocation(line: 8, column: 3, scope: !44)
// CHECK:STDOUT: !62 = !DILocation(line: 12, column: 3, scope: !44)
// CHECK:STDOUT: !63 = !DILocation(line: 5, column: 1, scope: !44)
// CHECK:STDOUT: !64 = !{!45}
// CHECK:STDOUT: !65 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.9631b3a587cc85dc", scope: null, file: !28, line: 24, type: !36, spFlags: DISPFlagDefinition, unit: !43, retainedNodes: !71)
// CHECK:STDOUT: !66 = !DILocalVariable(arg: 1, scope: !65, type: !34)
// CHECK:STDOUT: !68 = !DILocation(line: 25, column: 5, scope: !65)
// CHECK:STDOUT: !69 = !DILocation(line: 26, column: 5, scope: !65)
// CHECK:STDOUT: !70 = !DILocation(line: 24, column: 3, scope: !65)
// CHECK:STDOUT: !71 = !{!66}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.9631b3a587cc85dc", scope: null, file: !28, line: 17, type: !36, spFlags: DISPFlagDefinition, unit: !43, retainedNodes: !76)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !34)
// CHECK:STDOUT: !75 = !DILocation(line: 17, column: 3, scope: !72)
// CHECK:STDOUT: !76 = !{!73}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'if_else.carbon'
// CHECK:STDOUT: source_filename = "if_else.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Destructible.val.loc6_3.1 = internal constant {} zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CIfElse.Main(i1 %cond) #0 !dbg !79 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.var = alloca {}, align 1, !dbg !82
// CHECK:STDOUT:   %b.var = alloca {}, align 1, !dbg !89
// CHECK:STDOUT:   %c.var = alloca {}, align 1, !dbg !95
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a.var), !dbg !82
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %a.var, ptr align 1 @Destructible.val.loc6_3.1, i64 0, i1 false), !dbg !82
// CHECK:STDOUT:   call void @_CUse.Main(ptr %a.var), !dbg !86
// CHECK:STDOUT:   br i1 %cond, label %if.then, label %if.else, !dbg !88
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !89
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %b.var, ptr align 1 @Destructible.val.loc6_3.1, i64 0, i1 false), !dbg !89
// CHECK:STDOUT:   call void @_CUse.Main(ptr %b.var), !dbg !93
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %b.var), !dbg !89
// CHECK:STDOUT:   br label %if.done, !dbg !94
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %c.var), !dbg !95
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %c.var, ptr align 1 @Destructible.val.loc6_3.1, i64 0, i1 false), !dbg !95
// CHECK:STDOUT:   call void @_CUse.Main(ptr %c.var), !dbg !99
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %c.var), !dbg !95
// CHECK:STDOUT:   br label %if.done, !dbg !94
// CHECK:STDOUT:
// CHECK:STDOUT: if.done:                                          ; preds = %if.else, %if.then
// CHECK:STDOUT:   call void @_CUse.Main(ptr %a.var), !dbg !102
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %a.var), !dbg !82
// CHECK:STDOUT:   ret void, !dbg !103
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CUse.Main(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_COp:thunk:Destroy.9631b3a587cc85dc.Core:Destructible.Main:Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %self) #0 !dbg !105 {
// CHECK:STDOUT:   call void @"_COp:thunk:Destroy.9631b3a587cc85dc.Core:Destructible.Main:Destroy.Core"(ptr %self), !dbg !108
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.9631b3a587cc85dc(ptr %self), !dbg !109
// CHECK:STDOUT:   ret void, !dbg !110
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.9631b3a587cc85dc(ptr %self) #0 !dbg !112 {
// CHECK:STDOUT:   ret void, !dbg !115
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CUse.Main, { 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc, { 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!78}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !28 = !DIFile(filename: "min_prelude/parts/destroy.carbon", directory: "")
// CHECK:STDOUT: !34 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !35 = !{null, !34}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !77 = !DIFile(filename: "if_else.carbon", directory: "")
// CHECK:STDOUT: !78 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !77, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !79 = distinct !DISubprogram(name: "IfElse", linkageName: "_CIfElse.Main", scope: null, file: !77, line: 5, type: !36, spFlags: DISPFlagDefinition, unit: !78, retainedNodes: !104)
// CHECK:STDOUT: !80 = !DILocalVariable(arg: 1, scope: !79, type: !34)
// CHECK:STDOUT: !82 = !DILocation(line: 6, column: 3, scope: !79)
// CHECK:STDOUT: !86 = !DILocation(line: 7, column: 3, scope: !79)
// CHECK:STDOUT: !88 = !DILocation(line: 8, column: 6, scope: !79)
// CHECK:STDOUT: !89 = !DILocation(line: 9, column: 5, scope: !79)
// CHECK:STDOUT: !93 = !DILocation(line: 10, column: 5, scope: !79)
// CHECK:STDOUT: !94 = !DILocation(line: 8, column: 3, scope: !79)
// CHECK:STDOUT: !95 = !DILocation(line: 12, column: 5, scope: !79)
// CHECK:STDOUT: !99 = !DILocation(line: 13, column: 5, scope: !79)
// CHECK:STDOUT: !102 = !DILocation(line: 15, column: 3, scope: !79)
// CHECK:STDOUT: !103 = !DILocation(line: 5, column: 1, scope: !79)
// CHECK:STDOUT: !104 = !{!80}
// CHECK:STDOUT: !105 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.9631b3a587cc85dc", scope: null, file: !28, line: 24, type: !36, spFlags: DISPFlagDefinition, unit: !78, retainedNodes: !111)
// CHECK:STDOUT: !106 = !DILocalVariable(arg: 1, scope: !105, type: !34)
// CHECK:STDOUT: !108 = !DILocation(line: 25, column: 5, scope: !105)
// CHECK:STDOUT: !109 = !DILocation(line: 26, column: 5, scope: !105)
// CHECK:STDOUT: !110 = !DILocation(line: 24, column: 3, scope: !105)
// CHECK:STDOUT: !111 = !{!106}
// CHECK:STDOUT: !112 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.9631b3a587cc85dc", scope: null, file: !28, line: 17, type: !36, spFlags: DISPFlagDefinition, unit: !78, retainedNodes: !116)
// CHECK:STDOUT: !113 = !DILocalVariable(arg: 1, scope: !112, type: !34)
// CHECK:STDOUT: !115 = !DILocation(line: 17, column: 3, scope: !112)
// CHECK:STDOUT: !116 = !{!113}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'if_return.carbon'
// CHECK:STDOUT: source_filename = "if_return.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Destructible.val.loc6_3.1 = internal constant {} zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CIfReturn.Main(i1 %cond) #0 !dbg !119 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.var = alloca {}, align 1, !dbg !122
// CHECK:STDOUT:   %b.var = alloca {}, align 1, !dbg !129
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a.var), !dbg !122
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %a.var, ptr align 1 @Destructible.val.loc6_3.1, i64 0, i1 false), !dbg !122
// CHECK:STDOUT:   call void @_CUse.Main(ptr %a.var), !dbg !126
// CHECK:STDOUT:   br i1 %cond, label %if.then, label %if.else, !dbg !128
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !129
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %b.var, ptr align 1 @Destructible.val.loc6_3.1, i64 0, i1 false), !dbg !129
// CHECK:STDOUT:   call void @_CUse.Main(ptr %b.var), !dbg !133
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %b.var), !dbg !129
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %a.var), !dbg !122
// CHECK:STDOUT:   ret void, !dbg !134
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %a.var), !dbg !122
// CHECK:STDOUT:   ret void, !dbg !135
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CUse.Main(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_COp:thunk:Destroy.9631b3a587cc85dc.Core:Destructible.Main:Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %self) #0 !dbg !137 {
// CHECK:STDOUT:   call void @"_COp:thunk:Destroy.9631b3a587cc85dc.Core:Destructible.Main:Destroy.Core"(ptr %self), !dbg !140
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.9631b3a587cc85dc(ptr %self), !dbg !141
// CHECK:STDOUT:   ret void, !dbg !142
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.9631b3a587cc85dc(ptr %self) #0 !dbg !144 {
// CHECK:STDOUT:   ret void, !dbg !147
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CUse.Main, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc, { 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!118}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !28 = !DIFile(filename: "min_prelude/parts/destroy.carbon", directory: "")
// CHECK:STDOUT: !34 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !35 = !{null, !34}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !117 = !DIFile(filename: "if_return.carbon", directory: "")
// CHECK:STDOUT: !118 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !117, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !119 = distinct !DISubprogram(name: "IfReturn", linkageName: "_CIfReturn.Main", scope: null, file: !117, line: 5, type: !36, spFlags: DISPFlagDefinition, unit: !118, retainedNodes: !136)
// CHECK:STDOUT: !120 = !DILocalVariable(arg: 1, scope: !119, type: !34)
// CHECK:STDOUT: !122 = !DILocation(line: 6, column: 3, scope: !119)
// CHECK:STDOUT: !126 = !DILocation(line: 7, column: 3, scope: !119)
// CHECK:STDOUT: !128 = !DILocation(line: 8, column: 6, scope: !119)
// CHECK:STDOUT: !129 = !DILocation(line: 9, column: 5, scope: !119)
// CHECK:STDOUT: !133 = !DILocation(line: 10, column: 5, scope: !119)
// CHECK:STDOUT: !134 = !DILocation(line: 11, column: 5, scope: !119)
// CHECK:STDOUT: !135 = !DILocation(line: 5, column: 1, scope: !119)
// CHECK:STDOUT: !136 = !{!120}
// CHECK:STDOUT: !137 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.9631b3a587cc85dc", scope: null, file: !28, line: 24, type: !36, spFlags: DISPFlagDefinition, unit: !118, retainedNodes: !143)
// CHECK:STDOUT: !138 = !DILocalVariable(arg: 1, scope: !137, type: !34)
// CHECK:STDOUT: !140 = !DILocation(line: 25, column: 5, scope: !137)
// CHECK:STDOUT: !141 = !DILocation(line: 26, column: 5, scope: !137)
// CHECK:STDOUT: !142 = !DILocation(line: 24, column: 3, scope: !137)
// CHECK:STDOUT: !143 = !{!138}
// CHECK:STDOUT: !144 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.9631b3a587cc85dc", scope: null, file: !28, line: 17, type: !36, spFlags: DISPFlagDefinition, unit: !118, retainedNodes: !148)
// CHECK:STDOUT: !145 = !DILocalVariable(arg: 1, scope: !144, type: !34)
// CHECK:STDOUT: !147 = !DILocation(line: 17, column: 3, scope: !144)
// CHECK:STDOUT: !148 = !{!145}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'while_break.carbon'
// CHECK:STDOUT: source_filename = "while_break.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Destructible.val.loc6_3.1 = internal constant {} zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CWhileBreak.Main(i1 %cond) #0 !dbg !151 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.var = alloca {}, align 1, !dbg !154
// CHECK:STDOUT:   %b.var = alloca {}, align 1, !dbg !164
// CHECK:STDOUT:   %c.var = alloca {}, align 1, !dbg !171
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a.var), !dbg !154
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %a.var, ptr align 1 @Destructible.val.loc6_3.1, i64 0, i1 false), !dbg !154
// CHECK:STDOUT:   call void @_CUse.Main(ptr %a.var), !dbg !158
// CHECK:STDOUT:   br label %while.cond, !dbg !159
// CHECK:STDOUT:
// CHECK:STDOUT: while.cond:                                       ; preds = %if.else, %entry
// CHECK:STDOUT:   br i1 %cond, label %while.body, label %while.done, !dbg !159
// CHECK:STDOUT:
// CHECK:STDOUT: while.body:                                       ; preds = %while.cond
// CHECK:STDOUT:   call void @_CUse.Main(ptr %a.var), !dbg !163
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !164
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %b.var, ptr align 1 @Destructible.val.loc6_3.1, i64 0, i1 false), !dbg !164
// CHECK:STDOUT:   call void @_CUse.Main(ptr %b.var), !dbg !168
// CHECK:STDOUT:   br i1 %cond, label %if.then, label %if.else, !dbg !170
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %while.body
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %c.var), !dbg !171
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %c.var, ptr align 1 @Destructible.val.loc6_3.1, i64 0, i1 false), !dbg !171
// CHECK:STDOUT:   call void @_CUse.Main(ptr %c.var), !dbg !175
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %c.var), !dbg !171
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %b.var), !dbg !164
// CHECK:STDOUT:   br label %while.done, !dbg !176
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %while.body
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %b.var), !dbg !164
// CHECK:STDOUT:   br label %while.cond, !dbg !177
// CHECK:STDOUT:
// CHECK:STDOUT: while.done:                                       ; preds = %if.then, %while.cond
// CHECK:STDOUT:   call void @_CUse.Main(ptr %a.var), !dbg !180
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %a.var), !dbg !154
// CHECK:STDOUT:   ret void, !dbg !181
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CUse.Main(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_COp:thunk:Destroy.9631b3a587cc85dc.Core:Destructible.Main:Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %self) #0 !dbg !183 {
// CHECK:STDOUT:   call void @"_COp:thunk:Destroy.9631b3a587cc85dc.Core:Destructible.Main:Destroy.Core"(ptr %self), !dbg !186
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.9631b3a587cc85dc(ptr %self), !dbg !187
// CHECK:STDOUT:   ret void, !dbg !188
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.9631b3a587cc85dc(ptr %self) #0 !dbg !190 {
// CHECK:STDOUT:   ret void, !dbg !193
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CUse.Main, { 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc, { 3, 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!150}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !28 = !DIFile(filename: "min_prelude/parts/destroy.carbon", directory: "")
// CHECK:STDOUT: !34 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !35 = !{null, !34}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !149 = !DIFile(filename: "while_break.carbon", directory: "")
// CHECK:STDOUT: !150 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !149, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !151 = distinct !DISubprogram(name: "WhileBreak", linkageName: "_CWhileBreak.Main", scope: null, file: !149, line: 5, type: !36, spFlags: DISPFlagDefinition, unit: !150, retainedNodes: !182)
// CHECK:STDOUT: !152 = !DILocalVariable(arg: 1, scope: !151, type: !34)
// CHECK:STDOUT: !154 = !DILocation(line: 6, column: 3, scope: !151)
// CHECK:STDOUT: !158 = !DILocation(line: 7, column: 3, scope: !151)
// CHECK:STDOUT: !159 = !DILocation(line: 8, column: 9, scope: !151)
// CHECK:STDOUT: !163 = !DILocation(line: 9, column: 5, scope: !151)
// CHECK:STDOUT: !164 = !DILocation(line: 10, column: 5, scope: !151)
// CHECK:STDOUT: !168 = !DILocation(line: 11, column: 5, scope: !151)
// CHECK:STDOUT: !170 = !DILocation(line: 12, column: 8, scope: !151)
// CHECK:STDOUT: !171 = !DILocation(line: 13, column: 7, scope: !151)
// CHECK:STDOUT: !175 = !DILocation(line: 14, column: 7, scope: !151)
// CHECK:STDOUT: !176 = !DILocation(line: 15, column: 7, scope: !151)
// CHECK:STDOUT: !177 = !DILocation(line: 8, column: 3, scope: !151)
// CHECK:STDOUT: !180 = !DILocation(line: 18, column: 3, scope: !151)
// CHECK:STDOUT: !181 = !DILocation(line: 5, column: 1, scope: !151)
// CHECK:STDOUT: !182 = !{!152}
// CHECK:STDOUT: !183 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.9631b3a587cc85dc", scope: null, file: !28, line: 24, type: !36, spFlags: DISPFlagDefinition, unit: !150, retainedNodes: !189)
// CHECK:STDOUT: !184 = !DILocalVariable(arg: 1, scope: !183, type: !34)
// CHECK:STDOUT: !186 = !DILocation(line: 25, column: 5, scope: !183)
// CHECK:STDOUT: !187 = !DILocation(line: 26, column: 5, scope: !183)
// CHECK:STDOUT: !188 = !DILocation(line: 24, column: 3, scope: !183)
// CHECK:STDOUT: !189 = !{!184}
// CHECK:STDOUT: !190 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.9631b3a587cc85dc", scope: null, file: !28, line: 17, type: !36, spFlags: DISPFlagDefinition, unit: !150, retainedNodes: !194)
// CHECK:STDOUT: !191 = !DILocalVariable(arg: 1, scope: !190, type: !34)
// CHECK:STDOUT: !193 = !DILocation(line: 17, column: 3, scope: !190)
// CHECK:STDOUT: !194 = !{!191}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'while_continue.carbon'
// CHECK:STDOUT: source_filename = "while_continue.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Destructible.val.loc6_3.1 = internal constant {} zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CWhileContinue.Main(i1 %cond) #0 !dbg !197 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.var = alloca {}, align 1, !dbg !200
// CHECK:STDOUT:   %b.var = alloca {}, align 1, !dbg !210
// CHECK:STDOUT:   %c.var = alloca {}, align 1, !dbg !217
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a.var), !dbg !200
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %a.var, ptr align 1 @Destructible.val.loc6_3.1, i64 0, i1 false), !dbg !200
// CHECK:STDOUT:   call void @_CUse.Main(ptr %a.var), !dbg !204
// CHECK:STDOUT:   br label %while.cond, !dbg !205
// CHECK:STDOUT:
// CHECK:STDOUT: while.cond:                                       ; preds = %if.else, %if.then, %entry
// CHECK:STDOUT:   br i1 %cond, label %while.body, label %while.done, !dbg !205
// CHECK:STDOUT:
// CHECK:STDOUT: while.body:                                       ; preds = %while.cond
// CHECK:STDOUT:   call void @_CUse.Main(ptr %a.var), !dbg !209
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !210
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %b.var, ptr align 1 @Destructible.val.loc6_3.1, i64 0, i1 false), !dbg !210
// CHECK:STDOUT:   call void @_CUse.Main(ptr %b.var), !dbg !214
// CHECK:STDOUT:   br i1 %cond, label %if.then, label %if.else, !dbg !216
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %while.body
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %c.var), !dbg !217
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %c.var, ptr align 1 @Destructible.val.loc6_3.1, i64 0, i1 false), !dbg !217
// CHECK:STDOUT:   call void @_CUse.Main(ptr %c.var), !dbg !221
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %c.var), !dbg !217
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %b.var), !dbg !210
// CHECK:STDOUT:   br label %while.cond, !dbg !222
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %while.body
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %b.var), !dbg !210
// CHECK:STDOUT:   br label %while.cond, !dbg !223
// CHECK:STDOUT:
// CHECK:STDOUT: while.done:                                       ; preds = %while.cond
// CHECK:STDOUT:   call void @_CUse.Main(ptr %a.var), !dbg !226
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %a.var), !dbg !200
// CHECK:STDOUT:   ret void, !dbg !227
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CUse.Main(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_COp:thunk:Destroy.9631b3a587cc85dc.Core:Destructible.Main:Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc(ptr %self) #0 !dbg !229 {
// CHECK:STDOUT:   call void @"_COp:thunk:Destroy.9631b3a587cc85dc.Core:Destructible.Main:Destroy.Core"(ptr %self), !dbg !232
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.9631b3a587cc85dc(ptr %self), !dbg !233
// CHECK:STDOUT:   ret void, !dbg !234
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.9631b3a587cc85dc(ptr %self) #0 !dbg !236 {
// CHECK:STDOUT:   ret void, !dbg !239
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_CUse.Main, { 4, 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CSelfDestruct.Destroy.Core.9631b3a587cc85dc, { 3, 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!196}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !28 = !DIFile(filename: "min_prelude/parts/destroy.carbon", directory: "")
// CHECK:STDOUT: !34 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !35 = !{null, !34}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !195 = !DIFile(filename: "while_continue.carbon", directory: "")
// CHECK:STDOUT: !196 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !195, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !197 = distinct !DISubprogram(name: "WhileContinue", linkageName: "_CWhileContinue.Main", scope: null, file: !195, line: 5, type: !36, spFlags: DISPFlagDefinition, unit: !196, retainedNodes: !228)
// CHECK:STDOUT: !198 = !DILocalVariable(arg: 1, scope: !197, type: !34)
// CHECK:STDOUT: !200 = !DILocation(line: 6, column: 3, scope: !197)
// CHECK:STDOUT: !204 = !DILocation(line: 7, column: 3, scope: !197)
// CHECK:STDOUT: !205 = !DILocation(line: 8, column: 9, scope: !197)
// CHECK:STDOUT: !209 = !DILocation(line: 9, column: 5, scope: !197)
// CHECK:STDOUT: !210 = !DILocation(line: 10, column: 5, scope: !197)
// CHECK:STDOUT: !214 = !DILocation(line: 11, column: 5, scope: !197)
// CHECK:STDOUT: !216 = !DILocation(line: 12, column: 8, scope: !197)
// CHECK:STDOUT: !217 = !DILocation(line: 13, column: 7, scope: !197)
// CHECK:STDOUT: !221 = !DILocation(line: 14, column: 7, scope: !197)
// CHECK:STDOUT: !222 = !DILocation(line: 15, column: 7, scope: !197)
// CHECK:STDOUT: !223 = !DILocation(line: 8, column: 3, scope: !197)
// CHECK:STDOUT: !226 = !DILocation(line: 18, column: 3, scope: !197)
// CHECK:STDOUT: !227 = !DILocation(line: 5, column: 1, scope: !197)
// CHECK:STDOUT: !228 = !{!198}
// CHECK:STDOUT: !229 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.9631b3a587cc85dc", scope: null, file: !28, line: 24, type: !36, spFlags: DISPFlagDefinition, unit: !196, retainedNodes: !235)
// CHECK:STDOUT: !230 = !DILocalVariable(arg: 1, scope: !229, type: !34)
// CHECK:STDOUT: !232 = !DILocation(line: 25, column: 5, scope: !229)
// CHECK:STDOUT: !233 = !DILocation(line: 26, column: 5, scope: !229)
// CHECK:STDOUT: !234 = !DILocation(line: 24, column: 3, scope: !229)
// CHECK:STDOUT: !235 = !{!230}
// CHECK:STDOUT: !236 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.9631b3a587cc85dc", scope: null, file: !28, line: 17, type: !36, spFlags: DISPFlagDefinition, unit: !196, retainedNodes: !240)
// CHECK:STDOUT: !237 = !DILocalVariable(arg: 1, scope: !236, type: !34)
// CHECK:STDOUT: !239 = !DILocation(line: 17, column: 3, scope: !236)
// CHECK:STDOUT: !240 = !{!237}
// CHECK:STDOUT:

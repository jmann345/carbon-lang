// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/macros/macros.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/macros/macros.carbon

// ============================================================================
// object-like macros
// ============================================================================

// --- integer_literal_replacement_token.h
#define CONFIG_VALUE 42
#define CONFIG_VALUE_LONG 42l
#define CONFIG_VALUE_UNSIGNED 42u
#define CONFIG_VALUE_HEXA 0xFF
#define CONFIG_VALUE_OCTAL 010
#define CONFIG_VALUE_BINARY 0b101

// --- import_integer_literal_replacement_token.carbon

library "[[@TEST_NAME]]";

import Cpp library "integer_literal_replacement_token.h";

fn F() {
  //@dump-sem-ir-begin
  let unused a: i32 = Cpp.CONFIG_VALUE;
  let unused b: i64 = Cpp.CONFIG_VALUE_LONG;
  let unused c: u32 = Cpp.CONFIG_VALUE_UNSIGNED;
  let unused d: i32 = Cpp.CONFIG_VALUE_HEXA;
  let unused e: i32 = Cpp.CONFIG_VALUE_OCTAL;
  let unused f: i32 = Cpp.CONFIG_VALUE_BINARY;
  //@dump-sem-ir-end
}

// --- bad_suffix.h
#define CONFIG_VALUE 42f

// --- fail_import_bad_suffix.carbon

library "[[@TEST_NAME]]";

import Cpp library "bad_suffix.h";

fn F() {
  Cpp.CONFIG_VALUE;
}

// --- integer_literal_too_big.h
#define CONFIG_VALUE 18446744073709551616

// --- fail_import_integer_literal_too_big.carbon

library "[[@TEST_NAME]]";

import Cpp library "integer_literal_too_big.h";

fn F() {
  Cpp.CONFIG_VALUE;
}

// --- fail_assign_to_object_like_macro.carbon

library "[[@TEST_NAME]]";

import Cpp library "integer_literal_replacement_token.h";

fn F() {
  Cpp.CONFIG_VALUE = 3;
}

// --- macro_in_nested_scope.h

namespace N {
  #define CONFIG_VALUE 42
}

// --- fail_import_macro_in_nested_scope.carbon

library "[[@TEST_NAME]]";

import Cpp library "macro_in_nested_scope.h";

fn F() {
  let unused a: i32 = Cpp.CONFIG_VALUE;

  let unused b: i32 = Cpp.N.CONFIG_VALUE;
}

// --- macro_and_non_macro_same_name.h

namespace X {
  float n;
}
float n;
#define n 1

// --- import_macro_and_non_macro_same_name.carbon

library "[[@TEST_NAME]]";

import Cpp library "macro_and_non_macro_same_name.h";

fn F() {
  //@dump-sem-ir-begin
  // When the same macro name and non-macro name exist in the global C++ scope, the macro name is selected.
  // Cpp.n is treated as an integer constant with value 1.
  var unused a: array(f32, Cpp.n) = (1.0,);

  let unused b: f32 = Cpp.X.n;
  //@dump-sem-ir-end
}

// --- no_replacement_token.h
#define MACRO_NAME

// --- fail_import_no_replacement_token.carbon

library "[[@TEST_NAME]]";

import Cpp library "no_replacement_token.h";

fn F() {
  // TODO: Get rid of the second error.
  Cpp.MACRO_NAME;
}

// --- unary_operator.h
#define NEGATIVE -1

// --- import_unary_operator.carbon

library "[[@TEST_NAME]]";

import Cpp library "unary_operator.h";

fn F() {
  //@dump-sem-ir-begin
  let unused a: i32 = Cpp.NEGATIVE;
  //@dump-sem-ir-end
}

// --- binary_operator.h
#define ADDITION 1+2

// --- import_binary_operator.carbon

library "[[@TEST_NAME]]";

import Cpp library "binary_operator.h";

fn F() {
  //@dump-sem-ir-begin
  let unused a: i32 = Cpp.ADDITION;
  //@dump-sem-ir-end
}

// --- casting.h
#define CAST_UNSIGNED (unsigned int)1
#define CAST_STATIC static_cast<int>(100.5)
#define CAST_FUNCTIONAL int(99.9)
#define CAST_BOOL_TO_INT (int)true

// --- import_casting.carbon

library "[[@TEST_NAME]]";

import Cpp library "casting.h";

fn F() {
  //@dump-sem-ir-begin
  let unused a: u32 = Cpp.CAST_UNSIGNED;
  let unused b: i32 = Cpp.CAST_STATIC;
  let unused c: i32 = Cpp.CAST_FUNCTIONAL;
  let unused d: i32 = Cpp.CAST_BOOL_TO_INT;
  //@dump-sem-ir-end
}

// --- nested_macros.h
#define ONE 1
#define INDIRECT_ONE ONE

// --- import_nested_macros.carbon

library "[[@TEST_NAME]]";

import Cpp library "nested_macros.h";

fn F() {
  //@dump-sem-ir-begin
  let unused a: i32 = Cpp.INDIRECT_ONE;
  //@dump-sem-ir-end
}

// --- string_literal_object_like_macro.h

#define SimpleString "abc"
#define EmptyString ""
#define EscapeCharacter " \t "
#define Concatenated "a" "b"
#define RawString R"a( foo: "bar" { 123 } )a"
#define Utf8String u8"абв"

#define CONCAT_STR(A, B) #A #B
#define Indirect CONCAT_STR(x, y)

// --- import_string_literal_object_like_macro.carbon

library "[[@TEST_NAME]]";

import Cpp library "string_literal_object_like_macro.h";

fn F() {
  //@dump-sem-ir-begin
  let unused a: str = Cpp.SimpleString;
  let unused b: str = Cpp.EmptyString;
  let unused c: str = Cpp.EscapeCharacter;
  let unused d: str = Cpp.Concatenated;
  let unused e: str = Cpp.RawString;
  let unused f: str = Cpp.Utf8String;
  let unused g: str = Cpp.Indirect;
  //@dump-sem-ir-end
}

// --- unsupported_string_literal_types.h

#define Utf16Greeting u"Hello"
#define Utf32Greeting U"Hello"
#define WideGreeting L"Hello"

// --- fail_import_unsupported_string_literal_types.carbon

library "[[@TEST_NAME]]";

import Cpp library "unsupported_string_literal_types.h";

fn F() {
 Cpp.Utf16Greeting;
 Cpp.Utf32Greeting;
 Cpp.WideGreeting;
}

// --- fail_bad_string.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
 #define BadString "123" 456
''';

fn F() {
 Cpp.BadString;
}

// --- floating_point_literal_macro.h
#define MyDouble 1.0
#define MyDoubleE 1e2
#define MyFloat 1.f

// --- import_floating_point_literal_macro.carbon

library "[[@TEST_NAME]]";

import Cpp library "floating_point_literal_macro.h";

fn F() {
  //@dump-sem-ir-begin
  let unused a: f64 = Cpp.MyDouble;
  let unused b: f64 = Cpp.MyDoubleE;
  let unused c: f32 = Cpp.MyFloat;
  //@dump-sem-ir-end
}

// --- unsupported_floating_point_literal_macro.h
#define MyLongDouble 987.654l

// --- fail_import_unsupported_floating_point_literal_macro.carbon

library "[[@TEST_NAME]]";

import Cpp library "unsupported_floating_point_literal_macro.h";

fn F() {
  Cpp.MyLongDouble;
}

// --- fail_import_assign_to_float.carbon

library "[[@TEST_NAME]]";

import Cpp library "floating_point_literal_macro.h";

fn F() {
  Cpp.MyDouble = 1.0;
}

// --- character_literals.h

#define M_LOWERCASE 'a'
#define M_UPPERCASE 'A'
#define M_DIGIT '1'
#define M_SPACE ' '
#define M_TAB '\t'
#define M_UTF8_CHAR u8'X'

// --- import_character_literals.carbon

library "[[@TEST_NAME]]";

import Cpp library "character_literals.h";

fn F() {
  //@dump-sem-ir-begin
  let unused a: char = Cpp.M_LOWERCASE;
  let unused b: char = Cpp.M_UPPERCASE;
  let unused c: char = Cpp.M_DIGIT;
  let unused d: char = Cpp.M_SPACE;
  let unused e: char = Cpp.M_TAB;
  let unused f: char = Cpp.M_UTF8_CHAR;
  //@dump-sem-ir-end
}

// --- character_literals_operators.h

#define M_CONDITIONAL (1 < 2 ? 'a' : 'b')
#define M_A_PLUS_ONE 'a' + 1
#define M_A_EQUAL ('a' == 97)

// --- import_character_literals_operators.carbon

library "[[@TEST_NAME]]";

import Cpp library "character_literals_operators.h";

fn F() {
  //@dump-sem-ir-begin
  let unused a: char = Cpp.M_CONDITIONAL;
  let unused b: i32 = Cpp.M_A_PLUS_ONE;
  let unused c: bool = Cpp.M_A_EQUAL;
  //@dump-sem-ir-end
}

// --- multiple_characters.h

#define MULTIPLE_CHARS 'AB'

// --- import_multiple_characters.carbon

library "[[@TEST_NAME]]";

import Cpp library "multiple_characters.h";

fn F() {
 let unused a: i32 = Cpp.MULTIPLE_CHARS;
}

// --- unsupported_character_literal_types.h

#define M_UTF16_CHAR u'a'
#define M_UTF32_CHAR U'a'
#define M_WIDE_CHAR L'a'

// --- fail_unsupported_character_literal_types.carbon

library "[[@TEST_NAME]]";

import Cpp library "unsupported_character_literal_types.h";

fn F() {
 let unused a: char = Cpp.M_UTF16_CHAR;
 let unused b: char = Cpp.M_UTF32_CHAR;
 let unused c: char = Cpp.M_WIDE_CHAR;
}

// --- fail_assign_to_character_literals.carbon

library "[[@TEST_NAME]]";

import Cpp library "character_literals.h";

fn F() {
 Cpp.M_LOWERCASE = 'b';
}

// --- boolean_literal_macro.h
#define M_TRUE true
#define M_FALSE false

#define M_ONE 1
#define M_ZERO 0

#define M_NOT_TRUE !true
#define M_NOT_ZERO (!0)

#define M_ONE_EQ_ONE (1 == 1)
#define M_ONE_NEQ_ONE (1 != 1)
#define M_AND (true && true)
#define M_OR (M_TRUE || M_FALSE)

#define M_COMPLEX ((2 * 2 < 5) && !M_FALSE)

// --- import_boolean_literal_macro.carbon

library "[[@TEST_NAME]]";

import Cpp library "boolean_literal_macro.h";

fn F() {
  //@dump-sem-ir-begin
  let unused a: bool = Cpp.M_TRUE;
  let unused b: bool = Cpp.M_FALSE;
  let unused c: bool = Cpp.M_NOT_TRUE;
  let unused d: bool = Cpp.M_NOT_ZERO;
  let unused e: bool = Cpp.M_ONE_EQ_ONE;
  let unused f: bool = Cpp.M_ONE_NEQ_ONE;
  let unused g: bool = Cpp.M_AND;
  let unused h: bool = Cpp.M_OR;
  let unused i: bool = Cpp.M_COMPLEX;

  let unused j: i32 = Cpp.M_ONE;
  let unused k: i32 = Cpp.M_ZERO;
  //@dump-sem-ir-end
}

// --- fail_assign_to_boolean_literal_macro.carbon

library "[[@TEST_NAME]]";

import Cpp library "boolean_literal_macro.h";

fn F() {
 Cpp.M_TRUE = false;
}

// --- nullptr.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
  #define MyNullPtr nullptr
  void foo(int arr[2]);
''';

fn F() {
  //@dump-sem-ir-begin
  Cpp.foo(Cpp.MyNullPtr);
  //@dump-sem-ir-end
}

// --- user_defined_literal.h
constexpr auto operator""_kb(unsigned long long k) -> unsigned long long {
  return k * 1024;
}
#define M_1KB 1_kb

// --- import_user_defined_literal.carbon

library "[[@TEST_NAME]]";

import Cpp library "user_defined_literal.h";

fn F() {
 Cpp.M_1KB;
}

// --- enums.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
  enum A { a = 1, b = 2 };
  #define M_A ::a
''';

fn F() {
  //@dump-sem-ir-begin
  let unused a: Cpp.A = Cpp.M_A;
  //@dump-sem-ir-end
}

// --- enums_no_scope.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
  enum A_NoScope { a_no_scope = 1, b_no_scope = 2 };
  #define M_A_NO_SCOPE a_no_scope
''';

fn F() {
  Cpp.M_A_NO_SCOPE;
}

// --- constexpr_int.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
   constexpr int a = 1;
   #define M_CONSTEXPR_INT ::a
''';

fn F() {
  //@dump-sem-ir-begin
  let unused a: i32 = Cpp.M_CONSTEXPR_INT;
  //@dump-sem-ir-end
}

// --- constexpr_int_addr.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
constexpr int n = 1;
#define N n
''';

//@dump-sem-ir-begin
let p: const i32* = &Cpp.N;
//@dump-sem-ir-end

// --- import_constexpr_no_scope.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
   constexpr int a_no_scope = 1;
   #define M_CONSTEXPR_NO_SCOPE a_no_scope
''';

fn F() {
  let unused a: i32 = Cpp.M_CONSTEXPR_NO_SCOPE;
}

// --- import_macro_constexpr_float.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
   constexpr float b = 1.0f;
   #define M_CONSTEXPR_FLOAT ::b
''';

fn F() {
  let unused a: f32 = Cpp.M_CONSTEXPR_FLOAT;
}

// --- lambda.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
  #define MyIntLambda (([] { return 7; })())
''';

fn F() {
  //@dump-sem-ir-begin
  let unused i: i32 = Cpp.MyIntLambda;
  //@dump-sem-ir-end
}

// --- macro_undefined.h

#define UNDEF_NAME 1
#undef UNDEF_NAME

// --- fail_macro_undefined.carbon

library "[[@TEST_NAME]]";

import Cpp library "macro_undefined.h";

fn F() {
  let unused a: i32 = Cpp.UNDEF_VALUE;
}

// --- macro_redefined.h

#define REDEF_NAME 1
#undef REDEF_NAME

#define REDEF_NAME 2

// --- import_macro_redefined.carbon

library "[[@TEST_NAME]]";

import Cpp library "macro_redefined.h";

fn F() {
  //@dump-sem-ir-begin
  let unused a: i32 = Cpp.REDEF_NAME;
  //@dump-sem-ir-end
}

// --- macro_defined_twice.h

#define TWICE_DEF 1
#define TWICE_DEF 2

// --- import_macro_defined_twice.carbon

library "[[@TEST_NAME]]";

import Cpp library "macro_defined_twice.h";

fn F() {
  //@dump-sem-ir-begin
  let unused a: i32 = Cpp.TWICE_DEF;
  //@dump-sem-ir-end
}

// ============================================================================
// function-like macros
// ============================================================================

// --- function_like_macros.h

#define MAX(a, b) ((a) > (b) ? (a) : (b))

// --- fail_todo_import_function_like_macros.carbon

library "[[@TEST_NAME]]";

import Cpp library "function_like_macros.h";

fn F() {
  let unused a: i32 = Cpp.MAX(1,2);
}

// ============================================================================
// predefined macros
// ============================================================================

// --- predefined_macros.h

auto foo() -> void;

// --- fail_todo_import_predefined_macros.carbon

library "[[@TEST_NAME]]";

import Cpp library "predefined_macros.h";

fn F() {
  let unused line_num: i32 = Cpp.__LINE__;
}

// ============================================================================
// macros used as header guards
// ============================================================================

// --- header_guard_macros.h

#ifndef HEADER_GUARD_MACRO_H_
#define HEADER_GUARD_MACRO_H_

void foo();

#endif  // HEADER_GUARD_MACRO_H_

// --- fail_import_header_guard_macros.carbon

library "[[@TEST_NAME]]";

import Cpp library "header_guard_macros.h";

fn F() {
  Cpp.HEADER_GUARD_MACRO_H_;
}

// --- assign.carbon
library "[[@TEST_NAME]]";

import Cpp inline '''
int v = 1;
#define m v
''';

fn F() {
  //@dump-sem-ir-begin
  Cpp.m = 2;
  //@dump-sem-ir-end
}

// --- assign_pointer.carbon
library "[[@TEST_NAME]]";

import Cpp inline '''
int *p;
#define q p
''';

var n: i32;
fn F() {
  Cpp.q = &n;
}

// --- assign_through_pointer.carbon
library "[[@TEST_NAME]]";

import Cpp inline '''
int v_ptr = 1;
#define m &v_ptr
''';

fn F() {
  *Cpp.m.Get() = 2;
}

// --- assign_subobject.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
struct SubB {
  int c;
};
struct SubA {
  SubB b;
};
SubA a_obj;
#define m a_obj.b.c
''';

fn F() {
  //@dump-sem-ir-begin
  Cpp.m = 2;
  //@dump-sem-ir-end
}

// --- fail_todo_assign_array.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
struct Struct {
  int arr[3];
};
Struct s;
#define m s.arr[1]
''';

fn F() {
  Cpp.m = 2;
}

// --- fail_todo_assign_base_class_member.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
struct BaseA {
  int n;
};
struct DerivedB : BaseA {} b_obj;
#define m b_obj.n
''';

fn F() {
  Cpp.m = 2;
}

// --- self_expand.carbon

import Cpp inline '''
const int COUNT = 0;
#define COUNT COUNT + 1
''';

class C(N: i32) {}
// Expansion of `COUNT` should be suppressed inside itself.
let _: C(1) = {} as C(Cpp.COUNT);

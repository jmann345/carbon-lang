// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu --clang-arg=-std=c++20
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/operators/operators.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/operators/operators.carbon

// ============================================================================
// Unary operators
// ============================================================================

// --- unary_operators.h

class C {};

// Increment and Decrement.
auto operator++(C& operand) -> C&;
auto operator--(C& operand) -> C&;

// Arithmetic.
auto operator-(C operand) -> C;

// Bitwise.
auto operator~(C operand) -> C;

// --- import_unary_operators.carbon

library "[[@TEST_NAME]]";

import Cpp library "unary_operators.h";

fn F() {
  //@dump-sem-ir-begin
  var c: Cpp.C = Cpp.C.C();

  // Increment and Decrement.
  ++c;
  --c;

  // Arithmetic.
  let unused minus: Cpp.C = -c;

  // Bitwise.
  let unused complement: Cpp.C = ^c;
  //@dump-sem-ir-end
}

// ============================================================================
// Prefix increment and decrement vs postfix increment and decrement
// ============================================================================

// --- prefix_inc_and_dec.h

class Prefix {};
auto operator++(Prefix& operand) -> Prefix&;
auto operator--(Prefix& operand) -> Prefix&;

// --- fail_prefix_calling_postfix.carbon

library "[[@TEST_NAME]]";

import Cpp library "prefix_inc_and_dec.h";

fn F() {
  var prefix: Cpp.Prefix = Cpp.Prefix.Prefix();
  prefix++;
  prefix--;
}

// --- postfix_inc_and_dec.h

class Postfix {};
auto operator++(Postfix& operand, int) -> Postfix&;
auto operator--(Postfix& operand, int) -> Postfix&;

// --- fail_postfix_calling_prefix.carbon

library "[[@TEST_NAME]]";

import Cpp library "postfix_inc_and_dec.h";

fn F() {
  var postfix: Cpp.Postfix = Cpp.Postfix.Postfix();
  ++postfix;
  --postfix;
}

// ============================================================================
// Binary operators
// ============================================================================

// --- binary_operators.h

class BinaryC {
 public:
  void operator=(int);
  int operator[](int);
};

// Arithmetic.
auto operator+(BinaryC lhs, BinaryC rhs) -> BinaryC;
auto operator-(BinaryC lhs, BinaryC rhs) -> BinaryC;
auto operator*(BinaryC lhs, BinaryC rhs) -> BinaryC;
auto operator/(BinaryC lhs, BinaryC rhs) -> BinaryC;
auto operator%(BinaryC lhs, BinaryC rhs) -> BinaryC;

// Bitwise.
auto operator&(BinaryC lhs, BinaryC rhs) -> BinaryC;
auto operator|(BinaryC lhs, BinaryC rhs) -> BinaryC;
auto operator^(BinaryC lhs, BinaryC rhs) -> BinaryC;
auto operator<<(BinaryC lhs, int num_bits) -> BinaryC;
auto operator>>(BinaryC lhs, int num_bits) -> BinaryC;

// Compound Assignment Arithmetic.
auto operator+=(BinaryC& lhs, BinaryC rhs) -> BinaryC&;
auto operator-=(BinaryC& lhs, BinaryC rhs) -> BinaryC&;
auto operator*=(BinaryC& lhs, BinaryC rhs) -> BinaryC&;
auto operator/=(BinaryC& lhs, BinaryC rhs) -> BinaryC&;
auto operator%=(BinaryC& lhs, BinaryC rhs) -> BinaryC&;

// Compound Assignment Bitwuse.
auto operator&=(BinaryC& lhs, BinaryC rhs) -> BinaryC&;
auto operator|=(BinaryC& lhs, BinaryC rhs) -> BinaryC&;
auto operator^=(BinaryC& lhs, BinaryC rhs) -> BinaryC&;
auto operator<<=(BinaryC& lhs, int num_bites) -> BinaryC&;
auto operator>>=(BinaryC& lhs, int num_bites) -> BinaryC&;

// Relational.
auto operator==(BinaryC lhs, BinaryC rhs) -> bool;
auto operator!=(BinaryC lhs, BinaryC rhs) -> bool;
auto operator<(BinaryC lhs, BinaryC rhs) -> bool;
auto operator>(BinaryC lhs, BinaryC rhs) -> bool;
auto operator<=(BinaryC lhs, BinaryC rhs) -> bool;
auto operator>=(BinaryC lhs, BinaryC rhs) -> bool;

// --- import_binary_operators.carbon

library "[[@TEST_NAME]]";

import Cpp library "binary_operators.h";

fn F() {
  //@dump-sem-ir-begin
  var c1: Cpp.BinaryC = Cpp.BinaryC.BinaryC();
  var c2: Cpp.BinaryC = Cpp.BinaryC.BinaryC();

  // Arithmetic.
  let unused addition: Cpp.BinaryC = c1 + c2;
  let unused subtraction: Cpp.BinaryC = c1 - c2;
  let unused multiplication: Cpp.BinaryC = c1 * c2;
  let unused division: Cpp.BinaryC = c1 / c2;
  let unused modulo: Cpp.BinaryC = c1 % c2;

  // Bitwise.
  let unused bitwise_and: Cpp.BinaryC = c1 & c2;
  let unused bitwise_or: Cpp.BinaryC = c1 | c2;
  let unused bitwise_xor: Cpp.BinaryC = c1 ^ c2;
  let unused left_shift: Cpp.BinaryC = c1 << 3;
  let unused right_shift: Cpp.BinaryC = c1 >> 5;

  // Compound assignment, arithmetic.
  c1 += c2;
  c1 -= c2;
  c1 *= c2;
  c1 /= c2;
  c1 %= c2;

  // Compound assignment, bitwise.
  c1 &= c2;
  c1 |= c2;
  c1 ^= c2;
  c1 <<= 3;
  c1 >>= 5;

  // Relational.
  let unused equal: bool = c1 == c2;
  let unused not_equal: bool = c1 != c2;
  let unused greater_than: bool = c1 > c2;
  let unused less_than: bool = c1 < c2;
  let unused greater_than_or_equal: bool = c1 >= c2;
  let unused less_than_or_equal: bool = c1 <= c2;

  // Indexing.
  let unused index: i32 = c1[42];
  //@dump-sem-ir-end
}

// --- fail_todo_import_assignment.carbon

library "[[@TEST_NAME]]";

import Cpp library "binary_operators.h";

fn F() {
  var c: Cpp.BinaryC = {};

  // Simple assignment.
  c = 42;
}

// --- multiple_calls.carbon

library "[[@TEST_NAME]]";

import Cpp library "binary_operators.h";

fn F() {
  //@dump-sem-ir-begin
  let c1: Cpp.BinaryC = Cpp.BinaryC.BinaryC();
  let c2: Cpp.BinaryC = Cpp.BinaryC.BinaryC();
  let c3: Cpp.BinaryC = c1 + c2;
  let c4: Cpp.BinaryC = c1 + c3;
  let unused c5: Cpp.BinaryC = c4 + c3;
  //@dump-sem-ir-end
}

// --- fail_call_with_wrong_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "binary_operators.h";

fn F() {
  let c1: Cpp.BinaryC = Cpp.BinaryC.BinaryC();
  // TODO: Include a list of non-viable candidate operators with this diagnostic.
  let unused c2: Cpp.BinaryC = c1 + 5;
  let unused c3: Cpp.BinaryC = 6 + c1;
}

// ============================================================================
// Overload resolution failures
// ============================================================================

// --- fail_ambiguous.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
class AmbiguousC {};
void operator+(AmbiguousC, char);
void operator+(AmbiguousC, short);
''';

fn Test(c: Cpp.AmbiguousC) {
  c + 1;
}

// --- fail_deleted.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
class DeletedC {};
void operator+(DeletedC, int) = delete;
void operator+(DeletedC, void*) = delete;
''';

fn Test(c: Cpp.DeletedC) {
  c + 1;
}

// ============================================================================
// Rewrite using the spaceship operator
// ============================================================================

// --- fail_todo_rewrite_spaceship.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
class C {};

namespace std { class strong_ordering {}; }
auto operator<=>(C lhs, C rhs) -> std::strong_ordering;
auto operator>(C lhs, C rhs) -> bool;
auto operator<=(C lhs, C rhs) -> bool;
''';

fn F() {
  //@dump-sem-ir-begin
  var c1: Cpp.C = Cpp.C.C();
  var c2: Cpp.C = Cpp.C.C();

  // No rewrite.
  let unused greater_than: bool = c1 > c2;

  // Rewrite.
  let unused less_than: bool = c1 < c2;

  // Rewrite.
  let unused greater_than_or_equal: bool = c1 >= c2;

  // No rewrite.
  let unused less_than_or_equal: bool = c1 <= c2;
  //@dump-sem-ir-end
}

// --- fail_rewrite_deleted.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
class BaseDel {};
class CDel : public BaseDel {};

namespace std { class strong_ordering {}; }
auto operator<=>(CDel lhs, CDel rhs) -> std::strong_ordering = delete;
auto operator<(CDel lhs, BaseDel rhs) -> bool;
''';

fn F(c: Cpp.CDel) -> bool {
  // Note that we mention `operator '<=>'` in the diagnostic.
  return c < c;
}

// ============================================================================
// Rewrite using the equal operator
// ============================================================================

// --- fail_todo_rewrite_equal.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
class EqualC {};

auto operator==(EqualC lhs, EqualC rhs) -> bool;
''';

fn F() {
  //@dump-sem-ir-begin
  var c1: Cpp.EqualC = Cpp.EqualC.EqualC();
  var c2: Cpp.EqualC = Cpp.EqualC.EqualC();

  // No rewrite.
  let unused equal: bool = c1 == c2;

  // Rewrite.
  let unused not_equal: bool = c1 != c2;
  //@dump-sem-ir-end
}

// ============================================================================
// One of two operands conversion
// ============================================================================

// --- plus_with_int_conversion.h

class IntConvertibleC {
 public:
  IntConvertibleC(int);
};
auto operator+(IntConvertibleC lhs, IntConvertibleC rhs) -> IntConvertibleC;

// --- plus_with_int_conversion.carbon

library "[[@TEST_NAME]]";

import Cpp library "plus_with_int_conversion.h";

fn F() {
  let c1: Cpp.IntConvertibleC = Cpp.IntConvertibleC.IntConvertibleC(4);
  let unused c2: Cpp.IntConvertibleC = c1 + 5;
  let unused c3: Cpp.IntConvertibleC = 6 + c1;
}

// ============================================================================
// All operands conversion
// ============================================================================

// --- plus_with_string_view_conversion.h

namespace std {
  using size_t = __SIZE_TYPE__;

  inline namespace __1 {
    template<typename T> struct char_traits {};

    template<typename CharT, typename Traits = char_traits<CharT>>
    class basic_string_view {
     public:
      basic_string_view() = default;
      size_t size() const { return size_; }

     private:
      const CharT* data_;
      size_t size_;
    };

    using string_view = basic_string_view<char>;
  }
}

class StringViewConvertibleC {
 public:
  StringViewConvertibleC(std::string_view s);
};
auto operator+(StringViewConvertibleC lhs, StringViewConvertibleC rhs) -> StringViewConvertibleC;

// --- fail_todo_import_plus_with_string_view_conversion.carbon

library "[[@TEST_NAME]]";

import Cpp library "plus_with_string_view_conversion.h";

fn F() {
  let s1: str = "hello";
  let s2: str = "world";
  let unused c: Cpp.StringViewConvertibleC = s1 + s2;
}

// ============================================================================
// Unsupported unary operators
// ============================================================================

// --- unsupported_unary_operators.h

class UnsupportedUnaryC {};

// Arithmetic.
auto operator+(UnsupportedUnaryC operand) -> UnsupportedUnaryC;

// Increment and Decrement.
auto operator++(UnsupportedUnaryC& operand, int) -> UnsupportedUnaryC&;
auto operator--(UnsupportedUnaryC& operand, int) -> UnsupportedUnaryC&;

// Bitwise.
auto operator~(UnsupportedUnaryC operand) -> UnsupportedUnaryC;

// Logical.
auto operator!(UnsupportedUnaryC operand) -> UnsupportedUnaryC;

// Pointer and Memory.
class P {
 public:
  auto foo() -> P;
  auto operator->() const -> P* _Nonnull;
};
auto operator*(P operand) -> P;
auto operator&(P operand) -> P;

// --- fail_todo_import_unsupported_unary_operators.carbon

library "[[@TEST_NAME]]";

import Cpp library "unsupported_unary_operators.h";

fn F() {
  var c: Cpp.UnsupportedUnaryC = Cpp.UnsupportedUnaryC.UnsupportedUnaryC();

  // Arithmetic.
  let plus: Cpp.UnsupportedUnaryC = +c;

  // Increment and Decrement.
  c++;
  c--;

  // Bitwise.
  let not_value: Cpp.UnsupportedUnaryC = ~c;

  // Logical.
  let not_result: Cpp.UnsupportedUnaryC = operator!(c1);

  // Pointer and Memory.
  var p: Cpp.P = Cpp.P.P();

  // Pointer and Memory.
  let dereference: Cpp.P = *p;
  let address: Cpp.P = operator&(p);
  let call_result: Cpp.P = p->foo();
}

// ============================================================================
// Unsupported binary operators
// ============================================================================

// --- unsupported_binary_operators.h

class UnsupportedBinaryC {};

// Logical.
auto operator&&(UnsupportedBinaryC lhs, UnsupportedBinaryC rhs) -> UnsupportedBinaryC;
auto operator||(UnsupportedBinaryC lhs, UnsupportedBinaryC rhs) -> UnsupportedBinaryC;

// --- fail_todo_import_unsupported_binary_operators.carbon

library "[[@TEST_NAME]]";

import Cpp library "unsupported_binary_operators.h";

fn F() {
  var c1: Cpp.UnsupportedBinaryC = Cpp.UnsupportedBinaryC.UnsupportedBinaryC();

  // Logical.
  let and_result: Cpp.UnsupportedBinaryC = operator&&(c1, c2);
  let or_result: Cpp.UnsupportedBinaryC = operator||(c1, c2);
}

// ============================================================================
// Operator and operands in a single namespace
// ============================================================================

// --- single_namespace.h

namespace N {
class C {};
auto operator+(C lhs, C rhs) -> C;
}  // namespace N

// --- import_single_namespace.carbon

library "[[@TEST_NAME]]";

import Cpp library "single_namespace.h";

fn F() {
  //@dump-sem-ir-begin
  let c1: Cpp.N.C = Cpp.N.C.C();
  let c2: Cpp.N.C = Cpp.N.C.C();
  let unused c3: Cpp.N.C = c1 + c2;
  //@dump-sem-ir-end
}

// ============================================================================
// Operator and operands in a different namespaces
// ============================================================================

// --- multiple_namespaces.h

namespace N1 {
class C1 {};
}  // namespace N1
namespace N2 {
class C2 {};
auto operator+(N1::C1 lhs, C2 rhs) -> C2;
auto operator-(C2 lhs, N1::C1 rhs) -> C2;
}  // namespace N2

// --- import_multiple_namespaces.carbon

library "[[@TEST_NAME]]";

import Cpp library "multiple_namespaces.h";

fn F() {
  //@dump-sem-ir-begin
  let c1: Cpp.N1.C1 = Cpp.N1.C1.C1();
  let c2: Cpp.N2.C2 = Cpp.N2.C2.C2();
  let unused c3: Cpp.N2.C2 = c1 + c2;
  let unused c4: Cpp.N2.C2 = c2 - c1;
  //@dump-sem-ir-end
}

// ============================================================================
// Operands in namespace, operator in global namespace
// ============================================================================

// --- operands_in_namespace_operator_in_global.h

namespace GlobalOpN {
class C {};
}  // namespace GlobalOpN
auto operator+(GlobalOpN::C lhs, GlobalOpN::C rhs) -> GlobalOpN::C;

void foo() {
  GlobalOpN::C() + GlobalOpN::C();
}

// --- fail_todo_import_operands_in_namespace_operator_in_global.carbon

library "[[@TEST_NAME]]";

import Cpp library "operands_in_namespace_operator_in_global.h";

fn F() {
  //@dump-sem-ir-begin
  let c1: Cpp.GlobalOpN.C = Cpp.GlobalOpN.C.C();
  let c2: Cpp.GlobalOpN.C = Cpp.GlobalOpN.C.C();
  let unused c3: Cpp.GlobalOpN.C = c1 + c2;
  //@dump-sem-ir-end
}

// ============================================================================
// Operand is an inner class
// ============================================================================

// --- inner_class.h

class O {
 public:
  class C {};
};
auto operator+(O::C lhs, O::C rhs) -> O::C;

// --- import_inner_class.carbon

library "[[@TEST_NAME]]";

import Cpp library "inner_class.h";

fn F() {
  //@dump-sem-ir-begin
  let c1: Cpp.O.C = Cpp.O.C.C();
  let c2: Cpp.O.C = Cpp.O.C.C();
  let unused c3: Cpp.O.C = c1 + c2;
  //@dump-sem-ir-end
}

// ============================================================================
// Operand is an inner class in a namespace
// ============================================================================

// --- inner_class_in_namespace.h

namespace N {
class O {
 public:
  class C {};
};
auto operator+(O::C lhs, O::C rhs) -> O::C;
}  // namespace N

// --- import_inner_class_in_namespace.carbon

library "[[@TEST_NAME]]";

import Cpp library "inner_class_in_namespace.h";

fn F() {
  //@dump-sem-ir-begin
  let c1: Cpp.N.O.C = Cpp.N.O.C.C();
  let c2: Cpp.N.O.C = Cpp.N.O.C.C();
  let unused c3: Cpp.N.O.C = c1 + c2;
  //@dump-sem-ir-end
}

// ============================================================================
// Member operator
// ============================================================================

// --- member_add_with.h

class MemberClass {
 public:
  // Unary.
  auto operator-() -> MemberClass;

  // Binary.
  auto operator+(MemberClass rhs) -> MemberClass;
};

// --- import_member_add_with.carbon

library "[[@TEST_NAME]]";

import Cpp library "member_add_with.h";

fn F() {
  //@dump-sem-ir-begin
  var c1: Cpp.MemberClass = Cpp.MemberClass.MemberClass();
  var c2: Cpp.MemberClass = -c1;
  var unused c3: Cpp.MemberClass = c1 + c2;
  //@dump-sem-ir-end
}


// ============================================================================
// Operator not found
// ============================================================================

// --- not_found.h

class NoOperators {};

// --- fail_import_not_found.carbon

library "[[@TEST_NAME]]";

import Cpp library "not_found.h";

fn F() {
  let c1: Cpp.NoOperators = Cpp.NoOperators.NoOperators();
  let c2: Cpp.NoOperators = Cpp.NoOperators.NoOperators();
  let unused c3: Cpp.NoOperators = c1 + c2;
}

// ============================================================================
// Incomplete operand C++ type
// ============================================================================

// --- incomplete.h

class Incomplete;
class Complete {};

auto CreateIncomplete() -> Incomplete* _Nonnull;

// --- fail_import_incomplete_unary.carbon

library "[[@TEST_NAME]]";

import Cpp library "incomplete.h";

fn F() {
  let unused result_unary: i32 = -*Cpp.CreateIncomplete();
}

// --- fail_import_incomplete_binary.carbon

library "[[@TEST_NAME]]";

import Cpp library "incomplete.h";

fn F() {
  var complete: Cpp.Complete = Cpp.Complete.Complete();
  let unused result_binary: i32 = complete + *Cpp.CreateIncomplete();
}

// ============================================================================
// Incomplete operand Carbon type
// ============================================================================

// --- complete.h

struct CompleteCpp {};

// --- fail_incomplete_operand_carbon_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "complete.h";

class Incomplete;
fn CreateIncomplete() -> Incomplete*;

fn F() {
  var complete: Cpp.CompleteCpp = Cpp.CompleteCpp.CompleteCpp();
  let unused result: i32 = *CreateIncomplete() + complete;
}

// ============================================================================
// Indirect template instantiation
// ============================================================================

// --- indirect_template_instantiation.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
template<typename T> struct TemplateB {};
template<typename T> struct TemplateA {};

using TemplateX = TemplateB<TemplateA<int>>;
int operator+(TemplateX, TemplateX);
''';

fn F(x: Cpp.TemplateX) -> i32 {
  //@dump-sem-ir-begin
  return x + x;
  //@dump-sem-ir-end
}

// --- fail_indirect_template_instantiation_error.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
template<typename T> struct FailTemplateB {};
template<typename T> struct FailTemplateA {
  friend typename T::error operator+(FailTemplateB<FailTemplateA>, FailTemplateB<FailTemplateA>);
};

using FailTemplateX = FailTemplateB<FailTemplateA<int>>;
''';

fn F(x: Cpp.FailTemplateX) -> i32 {
  return x + x;
}

// ============================================================================
// Templated operators
// ============================================================================

// --- templated_operator.h

template<typename T> struct X {};
template<typename T> X<T> operator+(X<T>, X<T>);
using Xint = X<int>;

// --- templated_operator.carbon

library "[[@TEST_NAME]]";

import Cpp library "templated_operator.h";

fn Test(x: Cpp.Xint) -> Cpp.Xint {
  return x + x;
}

// ============================================================================
// Operator overloading
// ============================================================================

// --- overloading.h

class C {};
auto operator+(C lhs, C rhs) -> C;
class D {};
auto operator+(D lhs, D rhs) -> D;

// --- import_overloading.carbon

library "[[@TEST_NAME]]";

import Cpp library "overloading.h";

fn F() {
  let c1: Cpp.C = Cpp.C.C();
  let c2: Cpp.C = Cpp.C.C();
  //@dump-sem-ir-begin
  let unused c3: Cpp.C = c1 + c2;
  //@dump-sem-ir-end
}

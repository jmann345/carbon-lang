// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/import/access.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/import/access.carbon

// ============================================================================
// Public non-function member
// ============================================================================

// --- non_function_member_public.h

struct NonFunctionMemberPublic {
  int instance_data;
  static int static_data;
};

// --- import_non_function_member_public.carbon

library "[[@TEST_NAME]]";

import Cpp library "non_function_member_public.h";

fn F(s: Cpp.NonFunctionMemberPublic) {
  //@dump-sem-ir-begin
  let unused instance_data: i32 = s.instance_data;
  let unused static_data: i32 = Cpp.NonFunctionMemberPublic.static_data;
  //@dump-sem-ir-end
}

// --- import_non_function_member_public_extend.carbon

library "[[@TEST_NAME]]";

import Cpp library "non_function_member_public.h";

class Derived {
  extend base: Cpp.NonFunctionMemberPublic;
}

fn F(d: Derived) {
  //@dump-sem-ir-begin
  let unused instance_data: i32 = d.instance_data;
  let unused static_data: i32 = Derived.static_data;
  //@dump-sem-ir-end
}

// ============================================================================
// Protected non-function member
// ============================================================================

// --- non_function_member_protected.h

class NonFunctionMemberProtected {
 protected:
  int instance_data;
  static int static_data;
};

// --- fail_import_non_function_member_protected.carbon

library "[[@TEST_NAME]]";

import Cpp library "non_function_member_protected.h";

fn F(c: Cpp.NonFunctionMemberProtected) {
  let unused instance_data: i32 = c.instance_data;
  let unused static_data: i32 = Cpp.NonFunctionMemberProtected.static_data;
}

// --- fail_import_non_function_member_protected_extend.carbon

library "[[@TEST_NAME]]";

import Cpp library "non_function_member_protected.h";

class Derived {
  extend base: Cpp.NonFunctionMemberProtected;
}

fn F(d: Derived) {
  let unused instance_data: i32 = d.instance_data;
  let unused static_data: i32 = Derived.static_data;
}

// --- import_non_function_member_protected_extend_call_in_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "non_function_member_protected.h";

class Derived {
  extend base: Cpp.NonFunctionMemberProtected;
  fn F(self) {
    //@dump-sem-ir-begin
    let unused instance_data: i32 = self.instance_data;
    let unused unqualified_static_data: i32 = static_data;
    let unused derived_static_data: i32 = Derived.static_data;
    let unused base_static_data: i32 = Cpp.NonFunctionMemberProtected.static_data;
    //@dump-sem-ir-end
  }
}

// ============================================================================
// Private non-function member
// ============================================================================

// --- non_function_member_private.h

class NonFunctionMemberPrivate {
  int instance_data;
  static int static_data;
};

// --- fail_import_non_function_member_private.carbon

library "[[@TEST_NAME]]";

import Cpp library "non_function_member_private.h";

fn F(c: Cpp.NonFunctionMemberPrivate) {
  let unused instance_data: i32 = c.instance_data;
  let unused static_data: i32 = Cpp.NonFunctionMemberPrivate.static_data;
}

// --- fail_import_non_function_member_private_extend.carbon

library "[[@TEST_NAME]]";

import Cpp library "non_function_member_private.h";

class Derived {
  extend base: Cpp.NonFunctionMemberPrivate;
  fn F(self) {
    let unused instance_data: i32 = self.instance_data;
  }
}

fn F(d: Derived) {
  let unused instance_data: i32 = d.instance_data;
  let unused derived_static_data: i32 = Derived.static_data;
  let unused base_static_data: i32 = Cpp.NonFunctionMemberPrivate.static_data;
}

// --- fail_import_non_function_member_private_extend_static_within_member_function.carbon

library "[[@TEST_NAME]]";

import Cpp library "non_function_member_private.h";

class Derived {
  extend base: Cpp.NonFunctionMemberPrivate;
  fn F() {
    // TODO: `NonFunctionMemberPrivate.static_data` is private, so this
    // should fail.
    let unused unqualified_static_data: i32 = static_data;
  }
}

// ============================================================================
// Public function member
// ============================================================================

// --- function_member_public.h

struct FunctionMemberPublic {
  auto instance_fn() -> void;
  static auto static_fn() -> void;
};

// --- import_function_member_public.carbon

library "[[@TEST_NAME]]";

import Cpp library "function_member_public.h";

fn F(s: Cpp.FunctionMemberPublic*) {
  //@dump-sem-ir-begin
  s->instance_fn();
  Cpp.FunctionMemberPublic.static_fn();
  //@dump-sem-ir-end
}

// ============================================================================
// Protected function member
// ============================================================================

// --- function_member_protected.h

class FunctionMemberProtected {
 protected:
  auto instance_fn() -> void;
  static auto static_fn() -> void;
};

// --- fail_import_function_member_protected.carbon

library "[[@TEST_NAME]]";

import Cpp library "function_member_protected.h";

fn F(c: Cpp.FunctionMemberProtected*) {
  c->instance_fn();
  Cpp.FunctionMemberProtected.static_fn();
}

// --- fail_todo_import_function_member_protected_extend_call_instance_in_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "function_member_protected.h";

class Derived {
  extend base: Cpp.FunctionMemberProtected;
  fn F(self) {
    //@dump-sem-ir-begin
    // TODO: It should be possible to call protected methods in the base class.
    self.instance_fn();
    //@dump-sem-ir-end
  }
}

// --- import_function_member_protected_extend_call_static_in_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "function_member_protected.h";

class Derived {
  extend base: Cpp.FunctionMemberProtected;
  fn F(unused self) {
    //@dump-sem-ir-begin
    static_fn();
    Derived.static_fn();
    Cpp.FunctionMemberProtected.static_fn();
    //@dump-sem-ir-end
  }
}

// ============================================================================
// Private function member
// ============================================================================

// --- function_member_private.h

class FunctionMemberPrivate {
 private:
  auto instance_fn() -> void;
  static auto static_fn() -> void;
};

// --- fail_import_function_member_private.carbon

library "[[@TEST_NAME]]";

import Cpp library "function_member_private.h";

class Derived {
  extend base: Cpp.FunctionMemberPrivate;
  fn F(self) {
    self.instance_fn();
    static_fn();
    Derived.static_fn();
    Cpp.FunctionMemberPrivate.static_fn();
  }
}

fn F(c: Cpp.FunctionMemberPrivate*) {
  c->instance_fn();
  Derived.static_fn();
  Cpp.FunctionMemberPrivate.static_fn();
}

// ============================================================================
// Overload set
// ============================================================================

// --- overload_set.h

struct PublicCall {};
struct ProtectedCall {};
struct PrivateCall {};

class OverloadSet {
 public:
  OverloadSet(PublicCall x);
  static auto Overload(PublicCall x) -> void;
 protected:
  OverloadSet(ProtectedCall x);
  static auto Overload(ProtectedCall x) -> void;
 private:
  OverloadSet(PrivateCall x);
  static auto Overload(PrivateCall x) -> void;
};

// --- import_overload_set_public.carbon

library "[[@TEST_NAME]]";

import Cpp library "overload_set.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.OverloadSet.OverloadSet(Cpp.PublicCall.PublicCall());
  Cpp.OverloadSet.Overload(Cpp.PublicCall.PublicCall());
  //@dump-sem-ir-end
}

// --- fail_import_overload_set_protected.carbon

library "[[@TEST_NAME]]";

import Cpp library "overload_set.h";

fn F() {
  Cpp.OverloadSet.OverloadSet(Cpp.ProtectedCall.ProtectedCall());
  Cpp.OverloadSet.Overload(Cpp.ProtectedCall.ProtectedCall());
}

// --- import_overload_set_protected_base.carbon

library "[[@TEST_NAME]]";

import Cpp library "overload_set.h";

class D {
  extend base: Cpp.OverloadSet;

  fn MakePublic() -> D {
    //@dump-sem-ir-begin
    return {.base = OverloadSet(Cpp.PublicCall.PublicCall())};
    //@dump-sem-ir-end
  }

  fn MakeProtected() -> D {
    //@dump-sem-ir-begin
    return {.base = OverloadSet(Cpp.ProtectedCall.ProtectedCall())};
    //@dump-sem-ir-end
  }

  fn CallPublic() {
    //@dump-sem-ir-begin
    Overload(Cpp.PublicCall.PublicCall());
    //@dump-sem-ir-end
  }

  fn CallProtected() {
    //@dump-sem-ir-begin
    Overload(Cpp.ProtectedCall.ProtectedCall());
    //@dump-sem-ir-end
  }
}

// --- fail_import_overload_set_private.carbon

library "[[@TEST_NAME]]";

import Cpp library "overload_set.h";

fn F() {
  Cpp.OverloadSet.OverloadSet(Cpp.PrivateCall.PrivateCall());
  Cpp.OverloadSet.Overload(Cpp.PrivateCall.PrivateCall());
}

// --- fail_import_overload_set_private_base.carbon

library "[[@TEST_NAME]]";

import Cpp library "overload_set.h";

class D {
  extend base: Cpp.OverloadSet;

  fn MakePrivate() -> D {
    return {.base = OverloadSet(Cpp.PrivateCall.PrivateCall())};
  }

  fn CallPrivate() {
    Overload(Cpp.PrivateCall.PrivateCall());
  }
}

// --- overload_set_base_class.h

#include "overload_set.h"

class OverloadPublic : public OverloadSet {};
class OverloadProtected : protected OverloadSet {};
class OverloadPrivate : private OverloadSet {};

// --- import_overload_set_public_base_class_call_public.carbon

library "[[@TEST_NAME]]";

import Cpp library "overload_set_base_class.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.OverloadPublic.Overload(Cpp.PublicCall.PublicCall());
  //@dump-sem-ir-end
}

// --- fail_import_overload_set_public_base_class_call_non_public.carbon

library "[[@TEST_NAME]]";

import Cpp library "overload_set_base_class.h";

fn F() {
  Cpp.OverloadPublic.Overload(Cpp.ProtectedCall.ProtectedCall());
  Cpp.OverloadPublic.Overload(Cpp.PrivateCall.PrivateCall());
}

// --- import_overload_set_public_base_class_derived_call_non_private.carbon

library "[[@TEST_NAME]]";

import Cpp library "overload_set_base_class.h";

class Derived {
  extend base: Cpp.OverloadPublic;

  fn F() {
    //@dump-sem-ir-begin
    Overload(Cpp.PublicCall.PublicCall());
    Overload(Cpp.ProtectedCall.ProtectedCall());
    //@dump-sem-ir-end
  }
}

// --- fail_import_overload_set_public_base_class_derived_call_private.carbon

library "[[@TEST_NAME]]";

import Cpp library "overload_set_base_class.h";

class Derived {
  extend base: Cpp.OverloadPublic;

  fn F() {
    Overload(Cpp.PrivateCall.PrivateCall());
  }
}

// --- fail_import_overload_set_protected_base_class.carbon

library "[[@TEST_NAME]]";

import Cpp library "overload_set_base_class.h";

fn F() {
  Cpp.OverloadProtected.Overload(Cpp.PublicCall.PublicCall());
  Cpp.OverloadProtected.Overload(Cpp.ProtectedCall.ProtectedCall());
  Cpp.OverloadProtected.Overload(Cpp.PrivateCall.PrivateCall());
}

// --- import_overload_set_protected_base_class_derived_call_non_private.carbon

library "[[@TEST_NAME]]";

import Cpp library "overload_set_base_class.h";

class Derived {
  extend base: Cpp.OverloadProtected;

  fn F() {
    //@dump-sem-ir-begin
    Overload(Cpp.PublicCall.PublicCall());
    Overload(Cpp.ProtectedCall.ProtectedCall());
    //@dump-sem-ir-end
  }
}

// --- fail_import_overload_set_protected_base_class_derived_call_private.carbon

library "[[@TEST_NAME]]";

import Cpp library "overload_set_base_class.h";

class Derived {
  extend base: Cpp.OverloadProtected;

  fn F() {
    Overload(Cpp.PrivateCall.PrivateCall());
  }
}

// --- fail_import_overload_set_private_base_class.carbon

library "[[@TEST_NAME]]";

import Cpp library "overload_set_base_class.h";

fn F() {
  Cpp.OverloadPrivate.Overload(Cpp.PublicCall.PublicCall());
  Cpp.OverloadPrivate.Overload(Cpp.ProtectedCall.ProtectedCall());
  Cpp.OverloadPrivate.Overload(Cpp.PrivateCall.PrivateCall());
}

// --- fail_import_overload_set_private_base_class_derived.carbon

library "[[@TEST_NAME]]";

import Cpp library "overload_set_base_class.h";

class Derived {
  extend base: Cpp.OverloadPrivate;

  fn F() {
    Overload(Cpp.PublicCall.PublicCall());
    Overload(Cpp.ProtectedCall.ProtectedCall());
    Overload(Cpp.PrivateCall.PrivateCall());
  }
}

// ============================================================================
// Base class
// ============================================================================

// --- base_class.h

class Base {
 public:
  static auto PublicStatic() -> void;
  auto PublicInstance() -> void;
 protected:
  static auto ProtectedStatic() -> void;
  auto ProtectedInstance() -> void;
 private:
  static auto PrivateStatic() -> void;
  auto PrivateInstance() -> void;
};

class Public : public Base {};
class Protected : protected Base {};
class Private : private Base {};

class PublicProtected : public Protected {};
class PublicPrivate : public Private {};

// --- base_class_public_access_allowed.carbon

library "[[@TEST_NAME]]";

import Cpp library "base_class.h";

class Derived {
  extend base: Cpp.Public;

  fn CallStatic() {
    //@dump-sem-ir-begin
    // OK, we can access a public member of our base class.
    Cpp.Public.PublicStatic();
    Self.PublicStatic();

    // OK, we can access a protected member of our base class.
    Cpp.Public.ProtectedStatic();
    Self.ProtectedStatic();
    //@dump-sem-ir-end
  }

  fn CallInstance(var instance: Cpp.Public) {
    //@dump-sem-ir-begin
    // OK, we can access a public member of our base class.
    instance.PublicInstance();
    // OK, we can access a protected member of our base class.
    instance.ProtectedInstance();
    //@dump-sem-ir-end
  }
}

fn Call(var instance: Cpp.Public) {
  //@dump-sem-ir-begin
  Cpp.Public.PublicStatic();
  Derived.PublicStatic();

  instance.PublicInstance();
  instance.PublicInstance();
  //@dump-sem-ir-end
}

// --- fail_base_class_public_access_denied.carbon

library "[[@TEST_NAME]]";

import Cpp library "base_class.h";

class Derived {
  extend base: Cpp.Public;

  fn CallStatic() {
    Cpp.Public.PrivateStatic();
    Self.PrivateStatic();
  }

  fn CallInstance(var instance: Cpp.Public) {
    //@dump-sem-ir-begin
    instance.PrivateInstance();
    //@dump-sem-ir-end
  }
}

fn Call(var instance: Cpp.Public) {
  Cpp.Public.ProtectedStatic();
  Derived.ProtectedStatic();

  Cpp.Public.PrivateStatic();
  Derived.PrivateStatic();

  instance.ProtectedInstance();
  instance.PrivateInstance();
}

// --- base_class_protected_access_allowed.carbon

library "[[@TEST_NAME]]";

import Cpp library "base_class.h";

class Derived {
  extend base: Cpp.Protected;

  fn CallStatic() {
    //@dump-sem-ir-begin
    // OK, we can access a public member of our base class.
    Cpp.Protected.PublicStatic();
    Self.PublicStatic();

    // OK, we can access a protected member of our base class.
    Cpp.Protected.ProtectedStatic();
    Self.ProtectedStatic();
    //@dump-sem-ir-end
  }

  fn CallInstance(var instance: Cpp.Protected) {
    //@dump-sem-ir-begin
    // OK, we can access a public member of our base class.
    instance.PublicInstance();
    // OK, we can access a protected member of our base class.
    instance.ProtectedInstance();
    //@dump-sem-ir-end
  }
}

// --- fail_base_class_protected_access_denied.carbon

library "[[@TEST_NAME]]";

import Cpp library "base_class.h";

class Derived {
  extend base: Cpp.Protected;

  fn CallStatic() {
    Cpp.Protected.PrivateStatic();
    Self.PrivateStatic();
  }

  fn CallInstance(var instance: Cpp.Protected) {
    instance.PrivateInstance();
  }
}

fn Call(var instance: Cpp.Protected) {
  Cpp.Protected.PublicStatic();
  Derived.PublicStatic();

  Cpp.Protected.ProtectedStatic();
  Derived.ProtectedStatic();

  Cpp.Protected.PrivateStatic();
  Derived.PrivateStatic();

  instance.PublicInstance();
  instance.ProtectedInstance();
  instance.PrivateInstance();
}

// --- fail_base_class_private_access_denied.carbon

library "[[@TEST_NAME]]";

import Cpp library "base_class.h";

class Derived {
  extend base: Cpp.Private;

  fn CallStatic() {
    Cpp.Private.PublicStatic();
    Self.PublicStatic();

    Cpp.Private.ProtectedStatic();
    Self.ProtectedStatic();

    Cpp.Private.PrivateStatic();
    Self.PrivateStatic();
  }

  fn CallInstance(var instance: Cpp.Private) {
    instance.PublicInstance();

    instance.ProtectedInstance();

    instance.PrivateInstance();
  }
}

fn Call(var instance: Cpp.Private) {
  Cpp.Private.PublicStatic();
  Derived.PublicStatic();

  Cpp.Private.ProtectedStatic();
  Derived.ProtectedStatic();

  Cpp.Private.PrivateStatic();
  Derived.PrivateStatic();

  instance.PublicInstance();
  instance.ProtectedInstance();
  instance.PrivateInstance();
}

// --- base_class_public_protected_access_allowed.carbon

library "[[@TEST_NAME]]";

import Cpp library "base_class.h";

class Derived {
  extend base: Cpp.PublicProtected;

  fn CallStatic() {
    //@dump-sem-ir-begin
    // OK, we can access a public member of our base class.
    Cpp.PublicProtected.PublicStatic();
    Self.PublicStatic();

    // OK, we can access a protected member of our base class.
    Cpp.PublicProtected.ProtectedStatic();
    Self.ProtectedStatic();
    //@dump-sem-ir-end
  }

  fn CallInstance(var instance: Cpp.PublicProtected) {
    //@dump-sem-ir-begin
    // OK, we can access a public member of our base class.
    instance.PublicInstance();
    // OK, we can access a protected member of our base class.
    instance.ProtectedInstance();
    //@dump-sem-ir-end
  }
}

// --- fail_base_class_public_protected_access_denied.carbon

library "[[@TEST_NAME]]";

import Cpp library "base_class.h";

class Derived {
  extend base: Cpp.PublicProtected;

  fn CallStatic() {
    Cpp.PublicProtected.PrivateStatic();
    Self.PrivateStatic();
  }

  fn CallInstance(var instance: Cpp.PublicProtected) {
    instance.PrivateInstance();
  }
}

fn Call(var instance: Cpp.PublicProtected) {
  Cpp.PublicProtected.PublicStatic();
  Derived.PublicStatic();

  Cpp.PublicProtected.ProtectedStatic();
  Derived.ProtectedStatic();

  Cpp.PublicProtected.PrivateStatic();
  Derived.PrivateStatic();

  instance.PublicInstance();
  instance.ProtectedInstance();
  instance.PrivateInstance();
}

// --- fail_base_class_public_private_access_denied.carbon

library "[[@TEST_NAME]]";

import Cpp library "base_class.h";

class Derived {
  extend base: Cpp.PublicPrivate;

  fn CallStatic() {
    Cpp.PublicPrivate.PublicStatic();
    Self.PublicStatic();

    Cpp.PublicPrivate.ProtectedStatic();
    Self.ProtectedStatic();

    Cpp.PublicPrivate.PrivateStatic();
    Self.PrivateStatic();
  }

  fn CallInstance(var instance: Cpp.PublicPrivate) {
    instance.PublicInstance();

    instance.ProtectedInstance();

    instance.PrivateInstance();
  }
}

fn Call(var instance: Cpp.PublicPrivate) {
  Cpp.PublicPrivate.PublicStatic();
  Derived.PublicStatic();

  Cpp.PublicPrivate.ProtectedStatic();
  Derived.ProtectedStatic();

  Cpp.PublicPrivate.PrivateStatic();
  Derived.PrivateStatic();

  instance.PublicInstance();
  instance.ProtectedInstance();
  instance.PrivateInstance();
}

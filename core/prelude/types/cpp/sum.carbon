// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

package Core library "prelude/types/cpp/sum";

import library "prelude/copy";
import library "prelude/destroy";
import library "prelude/operators";
import library "prelude/types/optional";
import library "prelude/types/uint";

// The Carbon sum types of C++ `std::optional<T>` and `std::variant<Ts...>`
// (fork decision F-020; docs/design/sum_types.md, "C++ `std::optional` and
// `std::variant`"). The C++ class stays imported as a class; where a `choice`
// is expected -- a `match`, `if`-`let`, `while`-`let` or `let`-`else`
// scrutinee, or a conversion to one of these types -- the toolchain converts
// it through its C++ accessors (check/cpp/sum_type.cpp), and a value of one of
// these types converts back to the C++ class through its default constructor
// and `emplace`. Neither direction reads or writes the other side's bytes:
// libc++'s layouts are not the `choice` layout.
//
// `StdOptional(T)` is the docs/design/sum_types.md `Optional(T)` declaration.
// A `std::variant` alternative has no name in C++, so `StdVariant<N>` names
// its alternatives by C++ index: `.Alt0` is `index() == 0`. A
// `std::monostate` alternative has the payload `()`.

namespace CppCompat;

choice CppCompat.StdOptional(T: type) {
  Some(value: T),
  None
}

choice CppCompat.StdVariant1(T0: type) {
  Alt0(value: T0)
}

choice CppCompat.StdVariant2(T0: type, T1: type) {
  Alt0(value: T0),
  Alt1(value: T1)
}

choice CppCompat.StdVariant3(T0: type, T1: type, T2: type) {
  Alt0(value: T0),
  Alt1(value: T1),
  Alt2(value: T2)
}

choice CppCompat.StdVariant4(T0: type, T1: type, T2: type, T3: type) {
  Alt0(value: T0),
  Alt1(value: T1),
  Alt2(value: T2),
  Alt3(value: T3)
}

choice CppCompat.StdVariant5(T0: type, T1: type, T2: type, T3: type, T4: type) {
  Alt0(value: T0),
  Alt1(value: T1),
  Alt2(value: T2),
  Alt3(value: T3),
  Alt4(value: T4)
}

choice CppCompat.StdVariant6(
    T0: type, T1: type, T2: type, T3: type, T4: type, T5: type) {
  Alt0(value: T0),
  Alt1(value: T1),
  Alt2(value: T2),
  Alt3(value: T3),
  Alt4(value: T4),
  Alt5(value: T5)
}

choice CppCompat.StdVariant7(
    T0: type, T1: type, T2: type, T3: type, T4: type, T5: type, T6: type) {
  Alt0(value: T0),
  Alt1(value: T1),
  Alt2(value: T2),
  Alt3(value: T3),
  Alt4(value: T4),
  Alt5(value: T5),
  Alt6(value: T6)
}

choice CppCompat.StdVariant8(
    T0: type, T1: type, T2: type, T3: type, T4: type, T5: type, T6: type,
    T7: type) {
  Alt0(value: T0),
  Alt1(value: T1),
  Alt2(value: T2),
  Alt3(value: T3),
  Alt4(value: T4),
  Alt5(value: T5),
  Alt6(value: T6),
  Alt7(value: T7)
}

// `StdOptional(T)` and `Core.Optional(T)` convert to each other by value,
// through `Optional`'s public API (`Some`, `None`, `HasValue`, `Get`); neither
// representation is assumed (the pointer niche and the storage are
// prelude/types/optional.carbon's). The toolchain also matches a
// `Core.Optional(T)` scrutinee as its `StdOptional(T)` view, through the
// second impl (fork/sumtype-interop/plan.md §1.7).
impl forall [T: Copy & Destroy]
    CppCompat.StdOptional(T) as ImplicitAs(Optional(T)) {
  fn Convert(self) -> Optional(T) {
    match (self) {
      case .Some(value: T) => {
        return Optional(T).Some(value);
      }
      case .None => {
        return Optional(T).None();
      }
    }
    // Unreachable: reachability does not consult `match` exhaustiveness.
    return Optional(T).None();
  }
}

impl forall [T: Copy & Destroy]
    Optional(T) as ImplicitAs(CppCompat.StdOptional(T)) {
  fn Convert(self) -> CppCompat.StdOptional(T) {
    if (self.HasValue()) {
      return CppCompat.StdOptional(T).Some(self.Get());
    }
    return CppCompat.StdOptional(T).None;
  }
}

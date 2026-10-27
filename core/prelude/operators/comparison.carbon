// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

package Core library "prelude/operators/comparison";

export import library "prelude/types/bool";
import library "prelude/copy";
import library "prelude/types/int_literal";

// Equality comparison: `a == b` and `a != b`.
interface EqWith(Other: type) {
  fn Equal(self, other: Other) -> bool;
  default fn NotEqual(self, other: Other) -> bool {
    return not self.Equal(other);
  }
}

constraint Eq {
  extend require impls EqWith(Self);
}

// Relational comparison: `a < b`, `a <= b`, `a > b`, `a >= b`.
interface OrderedWith(Other: type) {
  // TODO: fn Compare
  // TODO: Each of the below should be a `default fn` implemented in terms of
  // Compare.
  fn Less(self, other: Other) -> bool;
  fn LessOrEquivalent(self, other: Other) -> bool;
  fn Greater(self, other: Other) -> bool;
  fn GreaterOrEquivalent(self, other: Other) -> bool;
}

constraint Ordered {
  extend require impls OrderedWith(Self);
}

// Equality comparison for `bool`.
// Note that this must be provided in this library as `bool` doesn't have any
// associated libraries of its own.
impl bool as EqWith(Self) {
  fn Equal(self, other: Self) -> bool = "bool.eq";
  fn NotEqual(self, other: Self) -> bool = "bool.neq";
}


// Operations for IntLiteral. These need to be here because IntLiteral has no
// associated library of its own.
impl IntLiteral as EqWith(Self) {
  fn Equal(self, other: Self) -> bool = "int.eq";
  fn NotEqual(self, other: Self) -> bool = "int.neq";
}

impl IntLiteral as OrderedWith(Self) {
  // TODO: fn Compare
  fn Less(self, other: Self) -> bool = "int.less";
  fn LessOrEquivalent(self, other: Self) -> bool = "int.less_eq";
  fn Greater(self, other: Self) -> bool = "int.greater";
  fn GreaterOrEquivalent(self, other: Self) -> bool = "int.greater_eq";
}

// Equality and relational comparison for tuples, field-wise, with relational
// comparison lexicographical (docs/design/tuples.md, "Operations performed
// field-wise"; docs/design/expressions/comparison_operators.md, "Default
// implementations for basic types"). These must be provided in this library
// as tuples don't have any associated library of their own.
impl forall [... each T: Eq] (... each T) as EqWith(Self) {
  fn Equal(self, other: Self) -> bool {
    let (... each a: each T) = self;
    let (... each b: each T) = other;
    ... if (not (each a == each b)) {
      return false;
    }
    return true;
  }
  fn NotEqual(self, other: Self) -> bool {
    let (... each a: each T) = self;
    let (... each b: each T) = other;
    ... if (each a != each b) {
      return true;
    }
    return false;
  }
}

impl forall [... each T: Ordered] (... each T) as OrderedWith(Self) {
  fn Less(self, other: Self) -> bool {
    let (... each a: each T) = self;
    let (... each b: each T) = other;
    ... if (each a < each b) {
      return true;
    } else if (each b < each a) {
      return false;
    }
    return false;
  }
  fn LessOrEquivalent(self, other: Self) -> bool {
    let (... each a: each T) = self;
    let (... each b: each T) = other;
    ... if (each a < each b) {
      return true;
    } else if (each b < each a) {
      return false;
    }
    return true;
  }
  fn Greater(self, other: Self) -> bool {
    let (... each a: each T) = self;
    let (... each b: each T) = other;
    ... if (each b < each a) {
      return true;
    } else if (each a < each b) {
      return false;
    }
    return false;
  }
  fn GreaterOrEquivalent(self, other: Self) -> bool {
    let (... each a: each T) = self;
    let (... each b: each T) = other;
    ... if (each b < each a) {
      return true;
    } else if (each a < each b) {
      return false;
    }
    return true;
  }
}

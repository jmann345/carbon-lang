// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   0
//   -1
//   1
//   42
//   7
//   42
//
// Working slice of the (PARTIAL) Optional bullet: the placeholder API in
// core/prelude/types/optional.carbon — `Core.Optional(T).None()` /
// `.Some(v)` constructors, `.HasValue()`, `.Get()`, the implicit
// `T -> Optional(T)` conversion (the `OptionalAs`-backed `ImplicitAs` impl,
// exercised as `var _: Core.Optional(i32) = a;` in
// toolchain/lower/testdata/primitives/optional.carbon), and the `Copy` impl
// (initializing one Optional from another, ibid. `fn F(c) { return c; }`).
// Call shapes follow examples/advent2024/io_utils.carbon (`unread_char`).
// The known-missing slice (no approved design — the file itself says the API
// is a placeholder, optional.carbon:27-28; e.g. no `==`) is encoded in
// optional_missing_ops.carbon.

import Core library "io";

fn ValueOr(o: Core.Optional(i32), fallback: i32) -> i32 {
  if (o.HasValue()) {
    return o.Get();
  }
  return fallback;
}

fn Run() -> i32 {
  var none: Core.Optional(i32) = Core.Optional(i32).None();
  Core.Print(if none.HasValue() then 1 else 0);
  Core.Print(ValueOr(none, -1));

  var some: Core.Optional(i32) = Core.Optional(i32).Some(42);
  Core.Print(if some.HasValue() then 1 else 0);
  Core.Print(some.Get());

  // Implicit conversion i32 -> Optional(i32).
  let v: i32 = 7;
  var conv: Core.Optional(i32) = v;
  Core.Print(ValueOr(conv, -1));

  // Optional(T) is Copy; the copy holds the same value.
  var copy: Core.Optional(i32) = some;
  Core.Print(copy.Get());
  return 0;
}

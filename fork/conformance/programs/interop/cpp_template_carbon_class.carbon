// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   48
//
// Instantiates imported C++ class templates on a user-defined Carbon class
// type (Cpp.Box(Point)), including a nested instantiation whose template
// argument is itself a C++ template instantiated on the Carbon class
// (Cpp.Pair(Cpp.Box(Point))), and reads/writes fields of the Carbon class
// through those instantiations. The gap-analysis audit marked this bullet
// PARTIAL citing 'unsupported type used as template argument'; on this
// nightly that error remains only for *symbolic* generic parameters (see
// cpp_template_symbolic_arg.carbon) — concrete Carbon class types as
// template arguments compile, link, and run, arbitrated here.

import Core library "io";
import Cpp inline '''
template<typename T> struct Box {
  T value;
};
template<typename T> struct Pair {
  T first;
  T second;
};
''';

class Point {
  var x: i32;
  var y: i32;
}

fn Run() -> i32 {
  var b: Cpp.Box(Point);
  b.value = {.x = 40, .y = 2};
  Core.Print(b.value.x + b.value.y);

  var nested: Cpp.Pair(Cpp.Box(Point));
  nested.first = b;
  nested.second.value = {.x = 5, .y = 8};
  Core.Print(nested.first.value.x + nested.second.value.y);
  return 0;
}

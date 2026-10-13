// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// C++17 oracle for string_ordering_diff.carbon: the same comparisons over
// std::string_view and std::string, printed as printf("%d\n", x).

#include <cstdio>
#include <string>
#include <string_view>

static auto B(bool b) -> int { return b ? 1 : 0; }

auto main() -> int {
  using std::string_view;
  std::printf("%d\n", B(string_view("carbon") == string_view("carbon")));
  std::printf("%d\n", B(string_view("carbon") == string_view("carbOn")));
  std::printf("%d\n", B(string_view("carbon") != string_view("carbo")));
  std::printf("%d\n", B(string_view("") == string_view("")));
  std::printf("%d\n", B(string_view("apple") < string_view("apricot")));
  std::printf("%d\n", B(string_view("app") < string_view("apple")));
  std::printf("%d\n", B(string_view("apple") <= string_view("app")));
  std::printf("%d\n", B(string_view("Zebra") < string_view("apple")));
  std::printf("%d\n", B(string_view("b") > string_view("abc")));
  std::printf("%d\n", B(string_view("abc") >= string_view("abc")));
  std::printf("%d\n", B(string_view("\xC3\xA9") > string_view("z")));
  std::string joined = std::string("app") + "le";
  std::printf("%d\n", static_cast<int>(joined.size()));
  std::printf("%d\n", B(joined == string_view("apple")));
  std::printf("%d\n", B(string_view("apricot") > string_view(joined)));
  std::printf("%d\n", B(joined < std::string("apples")));
  return 0;
}

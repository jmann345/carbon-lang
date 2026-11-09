// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Smoke test for the assembled boost include root under -fno-exceptions
// -fno-rtti (Carbon's benchmarks include this header). Exit 0 on success.
#include <boost/unordered/unordered_flat_map.hpp>
#include <cstdio>
#include <string>

int main() {
  boost::unordered_flat_map<std::string, int> map;
  map.emplace("a", 1);
  map["b"] = 2;
  auto it = map.find("a");
  int a = it == map.end() ? -1 : it->second;
  std::printf("boost ok: size=%zu a=%d\n", map.size(), a);
  return (map.size() == 2 && a == 1) ? 0 : 1;
}

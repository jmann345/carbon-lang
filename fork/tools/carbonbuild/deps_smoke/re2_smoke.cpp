// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Smoke test for the re2 install (re2 depends on absl). Exit 0 on success.
#include <cstdio>
#include <string>

#include "re2/re2.h"

int main() {
  std::string word;
  int num = 0;
  bool ok = RE2::FullMatch("hello 42", "(\\w+) (\\d+)", &word, &num);
  bool partial = RE2::PartialMatch("xx CHECK:STDOUT: yy", "CHECK:(\\w+):");
  std::printf("re2 ok: full=%d word=%s num=%d partial=%d\n", ok, word.c_str(),
              num, partial);
  return (ok && word == "hello" && num == 42 && partial) ? 0 : 1;
}

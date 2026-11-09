// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Smoke test for the abseil-cpp install: containers, strings, hash, random,
// flags (the pieces Carbon's BUILD files use). Exit 0 on success.
#include <cstdio>
#include <string>

#include "absl/container/flat_hash_map.h"
#include "absl/container/flat_hash_set.h"
#include "absl/flags/flag.h"
#include "absl/flags/parse.h"
#include "absl/hash/hash.h"
#include "absl/random/random.h"
#include "absl/strings/str_cat.h"
#include "absl/strings/str_split.h"

ABSL_FLAG(int, smoke_count, 3, "number of entries to insert");

int main(int argc, char** argv) {
  absl::ParseCommandLine(argc, argv);
  absl::flat_hash_map<std::string, int> map;
  for (int i = 0; i < absl::GetFlag(FLAGS_smoke_count); ++i) {
    map[absl::StrCat("key", i)] = i;
  }
  absl::flat_hash_set<std::string> set;
  for (absl::string_view part : absl::StrSplit("a,b,c", ',')) {
    set.insert(std::string(part));
  }
  absl::BitGen gen;
  int r = absl::Uniform(gen, 0, 10);
  size_t h = absl::HashOf(std::string("x"));
  std::string line =
      absl::StrCat("absl ok: map=", map.size(), " set=", set.size(),
                   " hash!=0=", h != 0, " rand<10=", r < 10);
  std::puts(line.c_str());
  return (map.size() == 3 && set.size() == 3 && r >= 0 && r < 10) ? 0 : 1;
}

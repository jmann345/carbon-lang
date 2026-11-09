// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Smoke test for the googletest install built with GTEST_HAS_ABSL=1: a TEST
// with a gmock matcher and the flag handling
// testing/file_test/file_test_base.cpp relies on (gtest flags are absl flags:
// absl::SetFlag on FLAGS_gtest_brief, absl::ParseCommandLine after
// InitGoogleTest). Own main; no gtest_main.
#include <cstdio>
#include <string>
#include <vector>

#include "absl/flags/flag.h"
#include "absl/flags/parse.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

#if !GTEST_HAS_ABSL
#error "gtest must be built and used with GTEST_HAS_ABSL=1"
#endif

TEST(DepsSmoke, GmockMatcher) {
  std::vector<int> v = {1, 2, 3};
  EXPECT_THAT(v, testing::ElementsAre(1, 2, 3));
  EXPECT_THAT(std::string("abc"), testing::StartsWith("ab"));
}

int main(int argc, char** argv) {
  absl::SetFlag(&FLAGS_gtest_brief, 1);
  testing::InitGoogleTest(&argc, argv);
  absl::ParseCommandLine(argc, argv);
  absl::SetFlag(&FLAGS_gtest_filter, "DepsSmoke.*");
  int rc = RUN_ALL_TESTS();
  if (rc == 0) {
    std::puts("gtest ok: 1 test, gmock matchers, absl flags");
  }
  return rc;
}

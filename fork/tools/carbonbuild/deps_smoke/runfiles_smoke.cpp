// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Smoke test for the runfiles library the way toolchain/base/install_paths.cpp
// uses it: the Bazel include path and namespace, Runfiles::Create(argv0,
// &error) and Rlocation. deps.sh creates
// <argv0>.runfiles/carbon/toolchain/install/ carbon_install.txt before running
// this. Exit 0 when the marker resolves.
#include <sys/stat.h>

#include <cstdio>
#include <memory>
#include <string>

#include "tools/cpp/runfiles/runfiles.h"

int main(int argc, char** argv) {
  using bazel::tools::cpp::runfiles::Runfiles;
  if (argc < 1) {
    return 2;
  }
  std::string error;
  std::unique_ptr<Runfiles> runfiles(Runfiles::Create(argv[0], &error));
  if (runfiles == nullptr) {
    std::printf("runfiles: Create failed: %s\n", error.c_str());
    return 2;
  }
  std::string marker =
      runfiles->Rlocation("carbon/toolchain/install/carbon_install.txt");
  struct stat st;
  bool exists = !marker.empty() && stat(marker.c_str(), &st) == 0;
  std::printf("runfiles ok: exists=%d %s\n", exists, marker.c_str());
  return exists ? 0 : 1;
}

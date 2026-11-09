#!/usr/bin/env python3
"""paths.py: read the shared configuration in paths.sh from python.

Usage (from a script in this directory):

    import paths
    P = paths.load()          # dict: REPO, SHA, LLVM_SRC, LLVM_BUILD, DEPS, BUILD_DIR, ...
    env = paths.load_env(P["DEPS"] + "/deps.env")   # dict from author B's deps.env

`load()` runs paths.sh under bash (so `${NAME:-default}` overrides from the
environment behave exactly as for the shell scripts) and prints the variables.
`load_env()` parses a `NAME=value` / `NAME="value"` file (deps.env) without
executing it (it is data written by another script).
"""

__copyright__ = """
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""

import os
import shlex
import subprocess
import sys

VARS = [
    "ARB",
    "REPO",
    "SHA",
    "LLVM_SRC",
    "LLVM_BUILD",
    "DEPS",
    "BUILD_DIR",
    "INSTALL_DIR",
    "CB",
    "LLVM_OVERLAY",
    "CXX",
    "CARBON_BUILD_MODE",
    "GEN_DIR",
    "SRC_PATCHES",
    "SRC_OVERLAY",
]

HERE = os.path.dirname(os.path.abspath(__file__))


def load(paths_sh=None):
    paths_sh = paths_sh or os.path.join(HERE, "paths.sh")
    script = (
        ". "
        + shlex.quote(paths_sh)
        + "\n"
        + "".join(
            'printf "%s\\001%s\\002" ' + v + ' "$' + v + '"\n' for v in VARS
        )
    )
    out = subprocess.run(
        ["bash", "-c", script], check=True, capture_output=True, text=True
    ).stdout
    result = {}
    for item in out.split("\002"):
        if not item:
            continue
        k, v = item.split("\001", 1)
        result[k] = v
    missing = [v for v in VARS if v not in result]
    if missing:
        sys.exit("paths.sh did not define: " + ", ".join(missing))
    return result


def load_env(path):
    """Parse deps.env: `NAME=value`, `NAME="value with spaces"`, `#` comments."""
    result = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            k = k.strip()
            v = v.strip()
            if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
                v = v[1:-1]
            result[k] = v
    return result


if __name__ == "__main__":
    for k, v in load().items():
        print(k + "=" + v)

#!/usr/bin/env python3
"""runfiles.py: build and verify the Bazel-shaped runfiles tree for file_test.

Part of the Carbon Language project fork's container arbiter (Bazel-free build
of the Carbon toolchain). Apache-2.0 WITH LLVM-exception.

`bazel test //toolchain/testing:file_test` runs the binary with cwd
`$TEST_SRCDIR/_main` (the runfiles workspace directory) and RUNFILES_DIR set.
This script lays out the same tree from the install and the repository:

    $RUNFILES_ROOT/
      _main/                                  cwd of the test binary
        toolchain/install/<entry>          -> $INSTALL_DIR/lib/carbon/<entry>   (one symlink per
                                              top-level entry of the install: carbon_install.txt,
                                              carbon-busybox, core, llvm, runtimes, include, bazel,
                                              install_digest.txt, BUILD.bazel, MODULE.bazel)
        toolchain/install/clang_headers_manifest.txt -> $BUILD_DIR/clang_headers_manifest.txt
        toolchain/<component>/testdata     -> $REPO/toolchain/<component>/testdata
                                              (every //toolchain/<c>:testdata of
                                              //toolchain/testing:all_testdata, plus toolchain/testing
                                              for testdata/min_prelude; autoupdate writes through them)
        core                               -> $REPO/core
      carbon -> _main                         the runfiles library resolves
                                              Rlocation("carbon/toolchain/install/carbon_install.txt")
                                              (install_paths.cpp BazelRoot) to
                                              $RUNFILES_DIR/carbon/... when there is no _repo_mapping

Every path the C++ code opens is checked to resolve (see --check); the paths
and the code that opens them:

  - $RUNFILES_DIR/carbon/toolchain/install/carbon_install.txt
      toolchain/base/install_paths.cpp:46-60 MakeForBazelRunfiles -> Rlocation; :159-172
      CheckMarkerFile. root() is then $RUNFILES_DIR/carbon/toolchain/install/.
  - <root>/core/prelude_manifest.txt and each listed file (relative to <root>/core)
      install_paths.cpp:70-73,95-130 ReadPreludeManifest/ReadManifest;
      toolchain/testing/file_test.cpp:58-66 GetSharedTestData -> AddFile (MemoryBuffer::getFile).
  - <root>/core/core_library_manifest.txt and each listed file
      install_paths.cpp:85-88; file_test.cpp:67-71.
  - <root>/clang_headers_manifest.txt and each listed file (relative to <root>)
      install_paths.cpp:75-83 ReadClangHeadersManifest ("the only place where we read from
      outside of the install root"); file_test.cpp:73-78.
  - <root>/llvm/bin/<tool>, <root>/llvm/lib/clang/<MAJOR>, <root>/runtimes, <root>/include,
    <root>/install_digest.txt
      install_paths.cpp:186-234 (llvm_install_bin, clang_resource_path, runtimes_root, include_path,
      digest_path), used by toolchain/driver/clang_runner.cpp:393-400, clang_runtimes.cpp:442-489,
      toolchain/base/clang_invocation.cpp:185, toolchain/driver/runtimes_cache.cpp:182,232.
  - toolchain/<component>/testdata/<test>.carbon relative to the cwd
      testing/file_test/test_file.cpp:903 ReadFile(test_name) (testing/base/file_helpers.cpp:25,
      std::ifstream of the manifest entry, which manifest_as_cpp writes as the repo-relative path);
      autoupdate writes std::filesystem::absolute(test_name) (file_test_base.cpp:215-230).
  - toolchain/testing/testdata/min_prelude/*.carbon relative to the cwd
      `// INCLUDE-FILE:` lines of the tests, test_file.cpp:960 ReadFile(filename).
  - $TEST_TMPDIR/temp_file for `%t` (testing/file_test/run_test.cpp:66, file_helpers.cpp:17-22)
    and $TEST_TMPDIR/<BuildTarget>.XXXXXX (common/filesystem.cpp:673-685 MakeTmpDir).

Usage: runfiles.py [--check] [--quiet]
  Builds (idempotently) and then checks; --check only checks. Exit 0 when every
  path resolves (pending binaries are reported, not errors), 1 otherwise.
"""

__copyright__ = """
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""

import argparse
import os
import re
import shlex
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bzl_eval  # noqa: E402

PATH_VARS = [
    "ARB",
    "REPO",
    "SHA",
    "BUILD_DIR",
    "INSTALL_DIR",
    "RUNFILES_ROOT",
    "FILE_TEST_BIN",
    "BUSYBOX_BIN",
    "DIGEST_BIN",
    "TEST_TMP",
]


def load_paths(paths_sh=None):
    paths_sh = paths_sh or os.path.join(HERE, "paths.sh")
    script = (
        ". "
        + shlex.quote(paths_sh)
        + "\n"
        + "".join(
            'printf "%s\\001%s\\002" ' + v + ' "$' + v + '"\n'
            for v in PATH_VARS
        )
    )
    out = subprocess.run(
        ["bash", "-c", script], check=True, capture_output=True, text=True
    ).stdout
    result = {}
    for item in out.split("\002"):
        if item:
            k, v = item.split("\001", 1)
            result[k] = v
    missing = [v for v in PATH_VARS if not result.get(v)]
    if missing:
        sys.exit("paths.sh did not define: " + ", ".join(missing))
    return result


def testdata_components(repo):
    """The //toolchain/<c>:testdata labels of //toolchain/testing:all_testdata."""
    g = bzl_eval.eval_file(
        os.path.join(repo, "toolchain/testing/BUILD"), repo, warn=lambda m: None
    )
    for kind, kw in g["__targets__"]:
        if kind == "filegroup" and kw.get("name") == "all_testdata":
            comps = []
            for s in kw["srcs"]:
                m = re.fullmatch(r"//toolchain/([^:/]+):testdata", s)
                if not m:
                    raise SystemExit("unexpected all_testdata src: " + s)
                comps.append(m.group(1))
            return comps
    raise SystemExit("//toolchain/testing:all_testdata not found")


def test_manifest(repo):
    """The test files of //toolchain/testing:all_testdata as repo-relative paths,
    in the order Bazel's manifest_as_cpp would list them (filegroup order, each
    glob sorted)."""
    ov = bzl_eval.Overlay(repo, repo, warn=lambda m: None)
    return [
        f.short_path for f in ov.files_of("//toolchain/testing:all_testdata")
    ]


def symlink(link, target, changed):
    if os.path.islink(link):
        if os.readlink(link) == target:
            return
        os.unlink(link)
    elif os.path.lexists(link):
        raise SystemExit(
            "%s exists and is not a symlink; remove it by hand" % link
        )
    os.makedirs(os.path.dirname(link), exist_ok=True)
    os.symlink(target, link)
    changed.append(link)


def build(P, quiet):
    root = P["RUNFILES_ROOT"]
    arb = os.path.realpath(P["ARB"]) + os.sep
    if not (os.path.realpath(root) + os.sep).startswith(arb):
        raise SystemExit(
            "refusing to build the runfiles tree outside ARB: " + root
        )
    main = os.path.join(root, "_main")
    os.makedirs(os.path.join(main, "toolchain", "install"), exist_ok=True)
    changed = []
    symlink(os.path.join(root, "carbon"), "_main", changed)
    lib_carbon = os.path.join(P["INSTALL_DIR"], "lib", "carbon")
    install_rf = os.path.join(main, "toolchain", "install")
    if os.path.isdir(lib_carbon):
        for entry in sorted(os.listdir(lib_carbon)):
            symlink(
                os.path.join(install_rf, entry),
                os.path.join(lib_carbon, entry),
                changed,
            )
    # Drop stale links to install entries that no longer exist.
    for entry in os.listdir(install_rf):
        p = os.path.join(install_rf, entry)
        if (
            os.path.islink(p)
            and not os.path.exists(p)
            and entry != "clang_headers_manifest.txt"
        ):
            os.unlink(p)
            changed.append(p + " (removed stale)")
    symlink(
        os.path.join(install_rf, "clang_headers_manifest.txt"),
        os.path.join(P["BUILD_DIR"], "clang_headers_manifest.txt"),
        changed,
    )
    for comp in testdata_components(P["REPO"]) + ["testing"]:
        symlink(
            os.path.join(main, "toolchain", comp, "testdata"),
            os.path.join(P["REPO"], "toolchain", comp, "testdata"),
            changed,
        )
    symlink(
        os.path.join(main, "core"), os.path.join(P["REPO"], "core"), changed
    )
    os.makedirs(P["TEST_TMP"], exist_ok=True)
    if not quiet:
        print(
            "runfiles tree %s: %d link(s) created or updated"
            % (root, len(changed))
        )


def check(P, quiet):
    root = P["RUNFILES_ROOT"]
    main = os.path.join(root, "_main")
    errors = []
    pending = []
    ok = []

    def need_file(path, what):
        if os.path.isfile(path):
            ok.append(what)
            return True
        errors.append("%s: %s does not resolve to a file" % (what, path))
        return False

    def need_dir(path, what):
        if os.path.isdir(path):
            ok.append(what)
            return True
        errors.append("%s: %s does not resolve to a directory" % (what, path))
        return False

    # install root as the runfiles library computes it.
    install_root = os.path.join(root, "carbon", "toolchain", "install")
    need_file(
        os.path.join(install_root, "carbon_install.txt"),
        "marker $RUNFILES_DIR/carbon/toolchain/install/carbon_install.txt (install_paths.cpp:46-60,159-172)",
    )
    if os.path.realpath(install_root) != os.path.realpath(
        os.path.join(main, "toolchain", "install")
    ):
        errors.append("carbon/ and _main/ are not the same directory")
    # manifests and their entries.
    for manifest, base, what in (
        (
            "core/prelude_manifest.txt",
            "core",
            "prelude manifest (install_paths.cpp:70-73, file_test.cpp:58-66)",
        ),
        (
            "core/core_library_manifest.txt",
            "core",
            "core library manifest (install_paths.cpp:85-88, file_test.cpp:67-71)",
        ),
        (
            "clang_headers_manifest.txt",
            "",
            "clang headers manifest (install_paths.cpp:75-83, file_test.cpp:73-78)",
        ),
    ):
        mpath = os.path.join(install_root, manifest)
        if not need_file(mpath, what):
            continue
        with open(mpath, encoding="utf-8") as f:
            lines = [line for line in f.read().split("\n") if line]
        if not lines:
            errors.append(
                "%s is empty (ReadManifest rejects an empty manifest)"
                % manifest
            )
        bad = [
            line
            for line in lines
            if not os.path.isfile(os.path.join(install_root, base, line))
        ]
        if bad:
            errors.append(
                "%s: %d entries missing, e.g. %s"
                % (manifest, len(bad), bad[:3])
            )
        else:
            ok.append("%d entries of %s" % (len(lines), manifest))
    # directories the driver uses.
    for sub, what in (
        ("llvm/bin", "llvm_install_bin (install_paths.cpp:186)"),
        ("runtimes", "runtimes_root (install_paths.cpp:222)"),
        ("include", "include_path (install_paths.cpp:181)"),
    ):
        need_dir(os.path.join(install_root, sub), what)
    clang_dirs = (
        [
            d
            for d in os.listdir(
                os.path.join(install_root, "llvm", "lib", "clang")
            )
        ]
        if os.path.isdir(os.path.join(install_root, "llvm", "lib", "clang"))
        else []
    )
    if clang_dirs:
        need_dir(
            os.path.join(
                install_root, "llvm", "lib", "clang", clang_dirs[0], "include"
            ),
            "clang_resource_path (install_paths.cpp:217)",
        )
    else:
        errors.append("llvm/lib/clang/<MAJOR> missing under the install root")
    # binaries (pending until author A's build.sh has run and install.py re-ran).
    for path, what in (
        (
            os.path.join(install_root, "carbon-busybox"),
            "carbon-busybox in the install",
        ),
        (
            os.path.join(install_root, "install_digest.txt"),
            "install_digest.txt (runtimes_cache.cpp:182,232)",
        ),
        (P["FILE_TEST_BIN"], "FILE_TEST_BIN " + P["FILE_TEST_BIN"]),
    ):
        if os.path.isfile(path):
            ok.append(what)
        else:
            pending.append(what)
    clang_link = os.path.join(install_root, "llvm", "bin", "clang")
    if not os.path.islink(clang_link):
        errors.append("llvm/bin/clang symlink missing")
    elif not os.path.isfile(clang_link):
        pending.append(
            "llvm/bin/clang -> ../../carbon-busybox resolves once the busybox is installed"
        )
    # test data relative to the cwd (_main).
    comps = testdata_components(P["REPO"])
    repo_real = os.path.realpath(P["REPO"]) + os.sep
    for comp in comps + ["testing"]:
        d = os.path.join(main, "toolchain", comp, "testdata")
        if need_dir(d, "toolchain/%s/testdata" % comp):
            if not (os.path.realpath(d) + os.sep).startswith(repo_real):
                errors.append(
                    "%s does not point into REPO (autoupdate would not write the goldens)"
                    % d
                )
    min_prelude = os.path.join(
        main, "toolchain", "testing", "testdata", "min_prelude"
    )
    if need_dir(
        min_prelude,
        "toolchain/testing/testdata/min_prelude (INCLUDE-FILE, test_file.cpp:960)",
    ):
        if not any(n.endswith(".carbon") for n in os.listdir(min_prelude)):
            errors.append("min_prelude has no .carbon files")
    need_dir(os.path.join(main, "core"), "core -> REPO/core")
    # the test manifest: every test file resolves from the cwd.
    tests = test_manifest(P["REPO"])
    missing = [t for t in tests if not os.path.isfile(os.path.join(main, t))]
    if missing:
        errors.append(
            "%d test files of all_testdata do not resolve from _main, e.g. %s"
            % (len(missing), missing[:3])
        )
    else:
        ok.append(
            "%d test files of //toolchain/testing:all_testdata resolve from _main"
            % len(tests)
        )
    os.makedirs(P["BUILD_DIR"], exist_ok=True)
    with open(
        os.path.join(P["BUILD_DIR"], "file_test_manifest.txt"),
        "w",
        encoding="utf-8",
    ) as f:
        f.write("\n".join(tests) + "\n")
    # every INCLUDE-FILE of the tests resolves from the cwd.
    include_re = re.compile(r"^//\s*INCLUDE-FILE:\s*(\S+)", re.M)
    includes = set()
    for t in tests:
        try:
            with open(
                os.path.join(P["REPO"], t), encoding="utf-8", errors="replace"
            ) as f:
                includes.update(include_re.findall(f.read()))
        except OSError:
            pass
    bad_inc = sorted(
        i for i in includes if not os.path.isfile(os.path.join(main, i))
    )
    if bad_inc:
        errors.append(
            "INCLUDE-FILE paths not resolvable from _main: %s" % bad_inc[:5]
        )
    else:
        ok.append(
            "%d distinct INCLUDE-FILE paths resolve from _main" % len(includes)
        )
    need_dir(P["TEST_TMP"], "TEST_TMPDIR " + P["TEST_TMP"])

    if not quiet:
        for o in ok:
            print("ok:      " + o)
    for p in pending:
        print("PENDING: " + p)
    for e in errors:
        print("ERROR:   " + e, file=sys.stderr)
    print(
        "runfiles check: %d ok, %d pending, %d errors; %d tests in the manifest (%s)"
        % (
            len(ok),
            len(pending),
            len(errors),
            len(tests),
            os.path.join(P["BUILD_DIR"], "file_test_manifest.txt"),
        )
    )
    return 1 if errors else 0


def main():
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument(
        "--check", action="store_true", help="only verify, do not build"
    )
    ap.add_argument("--quiet", action="store_true")
    ap.add_argument("--paths", help="alternative paths.sh")
    args = ap.parse_args()
    P = load_paths(args.paths)
    if not args.check:
        build(P, args.quiet)
    return check(P, args.quiet)


if __name__ == "__main__":
    sys.exit(main())

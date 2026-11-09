#!/usr/bin/env python3
"""gen_ninja.py: write $BUILD_DIR/build.ninja for the Carbon toolchain from the Bazel graph.

Builds three binaries (under $BUILD_DIR/bin, the names author C's scripts expect):
    //toolchain/install:carbon-busybox            -> bin/carbon-busybox
    //toolchain/testing:file_test                  -> bin/file_test
    //toolchain/install:make-installation-digest   -> bin/make-installation-digest

The BUILD graph is evaluated by bazel_graph.py (see its docstring). This script
walks the transitive cc deps of the three roots, mirrors Carbon's cc toolchain
flags for a linux clang `-c opt` build (bazel/cc_toolchains/*.bzl, .bazelrc) and
writes:
    $BUILD_DIR/build.ninja
    $BUILD_DIR/gen/...        files Bazel writes at analysis time (manifests,
                              llvm_tools.def, runtimes_build_info.h, ...)
    $BUILD_DIR/compile_commands.json (for tooling)
    $CB/env.sh                the cc_env() variables (LLVM_SYMBOLIZER_PATH, ...)
                              that gate.sh must export when running the binaries

    $BUILD_DIR/src/...        copies of REPO files patched by $SRC_PATCHES/*.diff
                              (REVIEW-1 R1-B1; see apply_source_patches), compiled
                              in place of the originals; $BUILD_DIR/src-patches.applied
                              lists each patch as `applied` or `landed`

Usage: python3 gen_ninja.py [--verbose]   (reads paths.sh and $DEPS/deps.env)
Prints the counts: targets in the closure, source files, generated files, objects,
the number of test files in the file_test manifest and the source patches applied.
"""

__copyright__ = """
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""

import json
import os
import re
import shlex
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bazel_graph as bg  # noqa: E402
import paths  # noqa: E402

ROOTS = [
    ("//toolchain/install:carbon-busybox", "carbon-busybox"),
    ("//toolchain/testing:file_test", "file_test"),
    (
        "//toolchain/install:make-installation-digest",
        "make-installation-digest",
    ),
]

# bazel/cc_toolchains/cc_toolchain_cpp_features.bzl, feature `clang`: every C++
# compile action. (-no-canonical-prefixes, -fcolor-diagnostics omitted: no effect on
# the output; -frandom-seed=<out> is added per object.)
CXX_FLAGS = [
    "-fno-exceptions",
    "-fno-rtti",
    "-std=c++20",
    "-ffunction-sections",
    "-fdata-sections",
    "-fPIC",  # .bazelrc --force_pic
    "-Wno-builtin-macro-redefined",
    '-D__DATE__="redacted"',
    '-D__TIMESTAMP__="redacted"',
    '-D__TIME__="redacted"',
]
# feature `clang_warnings` (same file). Probed against the compiler; rejected flags are
# dropped with a note.
WARNINGS = [
    "-Werror",
    "-Wall",
    "-Wextra",
    "-Wthread-safety",
    "-Wself-assign",
    "-Wimplicit-fallthrough",
    "-Wctad-maybe-unsupported",
    "-Wextra-semi",
    "-Wmissing-prototypes",
    "-Wzero-as-null-pointer-constant",
    "-Wdelete-non-virtual-dtor",
    "-Wno-missing-designated-field-initializers",
]
# cc_toolchain_carbon_project_features.bzl, feature `project_flags`.
SYSTEM_HEADER_PREFIXES = [
    "absl/",
    "benchmark/",
    "boost/",
    "clang-tools-extra/",
    "clang/",
    "gmock/",
    "gtest/",
    "libfuzzer/",
    "llvm/",
    "re2/",
    "tools/cpp/",
    "tree_sitter/",
]
# cc_toolchain_optimization.bzl: `default_optimization_flags` (opt) and the
# fastbuild set from cc_toolchain_carbon_project_features.bzl + cc_toolchain_debugging.bzl.
MODE_FLAGS = {
    "opt": ["-DNDEBUG", "-O3"],
    "fastbuild": [
        "-Og",
        "-gmlt",
        "-gz",
        "-fno-omit-frame-pointer",
        "-mno-omit-leaf-frame-pointer",
        "-fno-optimize-sibling-calls",
    ],
}
CPU_FLAGS = [
    "-march=x86-64-v2"
]  # `aarch64_cpu_flags` feature, x86_64_target branch.
# LLVM's own compile definitions (llvm/cmake/modules/HandleLLVMOptions.cmake), for the
# LLVM tool sources we compile from source.
LLVM_SRC_DEFINES = [
    "-D_GNU_SOURCE",
    "-D__STDC_CONSTANT_MACROS",
    "-D__STDC_FORMAT_MACROS",
    "-D__STDC_LIMIT_MACROS",
]
LINK_FLAGS = [
    "-fuse-ld=lld",
    "-static-libstdc++",
    "-static-libgcc",
    "-lpthread",
    "-pie",
]
SYSTEM_LIBS = ["-lpthread", "-ldl", "-lm", "-lrt"]
# Optional system libraries the LLVM CMake build was configured with (CMakeCache.txt
# LLVM_ENABLE_<X>=ON) and the -l flag each one needs at link time.
CMAKE_OPTIONAL_LIBS = [
    ("LLVM_ENABLE_ZLIB", "-lz"),
    ("LLVM_ENABLE_ZSTD", "-lzstd"),
    ("LLVM_ENABLE_LZMA", "-llzma"),
    ("LLVM_ENABLE_LIBXML2", "-lxml2"),
    ("LLVM_ENABLE_TERMINFO", "-ltinfo"),
    ("LLVM_ENABLE_LIBEDIT", "-ledit"),
    ("LLVM_ENABLE_CURL", "-lcurl"),
    ("LLVM_ENABLE_FFI", "-lffi"),
]


def cmake_system_libs(llvm_build):
    """-l flags for the optional libraries enabled in the LLVM build's CMakeCache.txt."""
    cache = os.path.join(llvm_build, "CMakeCache.txt")
    values = {}
    with open(cache, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"([A-Z_0-9]+):(?:STRING|BOOL)=(.*)", line.strip())
            if m:
                values[m.group(1)] = m.group(2)
    libs = []
    for key, flag in CMAKE_OPTIONAL_LIBS:
        if values.get(key, "OFF").upper() in ("ON", "FORCE_ON", "TRUE", "1"):
            libs.append(flag)
    return libs


COMPILED_EXTS = (".cpp", ".cc", ".cxx", ".c")


def esc(s):
    return s.replace("$", "$$").replace(" ", "$ ").replace(":", "$:")


def write_if_changed(path, data):
    if isinstance(data, str):
        data = data.encode("utf-8")
    try:
        with open(path, "rb") as f:
            if f.read() == data:
                return False
    except FileNotFoundError:
        pass
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)
    return True


def probe_flags(cxx, flags):
    ok = []
    dropped = []
    for fl in flags:
        r = subprocess.run(
            [cxx, "-Werror", fl, "-fsyntax-only", "-x", "c++", "/dev/null"],
            capture_output=True,
            text=True,
        )
        if r.returncode == 0:
            ok.append(fl)
        else:
            dropped.append(
                (
                    fl,
                    r.stderr.strip().splitlines()[0]
                    if r.stderr.strip()
                    else "",
                )
            )
    return ok, dropped


def compiler_version(cxx):
    r = subprocess.run([cxx, "--version"], capture_output=True, text=True)
    m = re.search(r"clang version (\d+)\.(\d+)", r.stdout)
    return (int(m.group(1)), int(m.group(2))) if m else (
        0,
        0,
    ), r.stdout.splitlines()[0] if r.stdout else ""


class Gen:
    def __init__(self, P, deps_env, verbose):
        self.P = P
        self.deps = deps_env
        self.verbose = verbose
        self.repo = P["REPO"]
        self.build_dir = P["BUILD_DIR"]
        self.gen = P["GEN_DIR"]
        self.obj = os.path.join(self.build_dir, "obj")
        self.bin = os.path.join(self.build_dir, "bin")
        self.llvm_src = P["LLVM_SRC"]
        self.llvm_build = P["LLVM_BUILD"]
        self.mode = P["CARBON_BUILD_MODE"]
        self.notes = []
        self.cxx = P["CXX"]
        if not os.path.exists(self.cxx):
            self.notes.append(
                "CXX %s does not exist; falling back to /usr/bin/clang++"
                % self.cxx
            )
            self.cxx = "/usr/bin/clang++"
        ver, verline = compiler_version(self.cxx)
        self.cxx_version = verline
        if ver < (21, 0) and not os.environ.get("CARBON_ALLOW_OLD_CLANG"):
            sys.exit(
                "gen_ninja.py: %s is %s; Carbon requires clang >= 21 "
                "(docs/project/contribution_tools.md). Run get_clang.sh or set CXX; "
                "set CARBON_ALLOW_OLD_CLANG=1 to try anyway."
                % (self.cxx, verline)
            )
        cand = os.path.join(os.path.dirname(self.cxx), "llvm-symbolizer")
        self.llvm_symbolizer = (
            cand if os.path.exists(cand) else "/usr/bin/llvm-symbolizer"
        )
        self.graph = bg.Graph(
            repo=self.repo,
            llvm_src=self.llvm_src,
            llvm_overlay=P["LLVM_OVERLAY"],
            llvm_build=self.llvm_build,
            build_mode=self.mode,
            llvm_symbolizer=self.llvm_symbolizer,
            gtest_defines=[
                d[2:]
                for d in shlex.split(deps_env.get("GTEST_DEFINES", ""))
                if d.startswith("-D")
            ],
            verbose=verbose,
        )
        self.lines = []
        self.gen_files = {}  # bazel exec path -> real path (written at gen time)
        self.objects = []
        self.compile_db = []
        self.phony_gen = []  # real paths of all analysis-written generated files
        # Source patches (REVIEW-1 R1-B1): REPO path -> patched copy under $SRC_OVERLAY.
        self.src_patches_dir = P.get("SRC_PATCHES", "")
        self.src_overlay = P.get("SRC_OVERLAY") or os.path.join(
            self.build_dir, "src"
        )
        self.src_overrides = {}
        self.patch_state = []  # (patch file name, "applied"|"landed", [repo paths])

    # ---- paths

    def gen_path(self, f):
        """Real path of a generated File under $GEN_DIR (mirrors bazel-out/<cfg>/bin)."""
        assert not f.is_source
        rel = f.path[len(bg.BIN_DIR) + 1 :]
        return os.path.join(self.gen, rel)

    def real(self, f):
        if f.is_source:
            return self.src_overrides.get(f.real_path, f.real_path)
        if f.real_path_override:
            return f.real_path_override
        return self.gen_path(f)

    # ---- source patches (REVIEW-1 R1-B1)

    def apply_source_patches(self):
        """Apply $SRC_PATCHES/*.diff to COPIES of the touched REPO files under
        $SRC_OVERLAY and compile those copies instead of the originals. REPO is
        never written.

        Each patch is a unified diff with `a/<repo path>` and `b/<repo path>`
        names (what `git diff` prints), so the same file lands in the repository
        with `git apply`. A patch whose hunks are already present in REPO (the fix
        has landed at this sha) is reported as `landed` and skipped; a patch that
        neither applies nor is applied stops the generation loudly. The state is
        written to $BUILD_DIR/src-patches.applied (one line per patch) so that
        gate.sh can say which patches the measured binary contains. Only directly
        compiled sources (.cpp/.cc/.cxx/.c) can be patched: the patched copy is
        compiled with an extra `-ffile-prefix-map=$SRC_OVERLAY/=` so __FILE__ and
        debug info equal the unpatched build's, and no other object's command line
        changes, so adding or removing a patch recompiles only the patched units.
        """
        os.makedirs(self.build_dir, exist_ok=True)
        state_path = os.path.join(self.build_dir, "src-patches.applied")
        d = self.src_patches_dir
        if not d or d == "none":
            write_if_changed(state_path, "")
            return
        if not os.path.isdir(d):
            self.notes.append(
                "SRC_PATCHES=%s is not a directory; no source patches applied"
                % d
            )
            write_if_changed(state_path, "")
            return
        patches = sorted(
            fn for fn in os.listdir(d) if fn.endswith((".diff", ".patch"))
        )
        if not patches:
            write_if_changed(state_path, "")
            return
        touched = {}  # patch file name -> repo-relative paths it touches
        for fn in patches:
            files = []
            with open(os.path.join(d, fn), encoding="utf-8") as f:
                for line in f:
                    m = re.match(r"\+\+\+ b/(\S+)", line)
                    if m:
                        files.append(m.group(1))
            if not files:
                sys.exit(
                    "gen_ninja.py: source patch %s has no `+++ b/<repo path>` line"
                    % fn
                )
            for rel in files:
                if rel.startswith("/") or ".." in rel.split("/"):
                    sys.exit(
                        "gen_ninja.py: source patch %s names an unsafe path %s"
                        % (fn, rel)
                    )
                if not os.path.isfile(os.path.join(self.repo, rel)):
                    sys.exit(
                        "gen_ninja.py: source patch %s touches %s, not a file under REPO=%s"
                        % (fn, rel, self.repo)
                    )
                if not rel.endswith(COMPILED_EXTS):
                    # A patched header would have to shadow REPO's through an extra -iquote on
                    # every compile and ninja could not see it appear or disappear (no edge
                    # changes); only directly compiled sources are supported. Break condition
                    # of the mechanism: such a fix must land in REPO.
                    sys.exit(
                        "gen_ninja.py: source patch %s touches %s; only compiled sources (%s) "
                        "can be patched, a header change must land in REPO"
                        % (fn, rel, " ".join(COMPILED_EXTS))
                    )
            touched[fn] = files
        all_rel = sorted({rel for files in touched.values() for rel in files})
        # Fresh copies of every touched file in a staging tree under $SRC_OVERLAY, then the
        # patches in name order; only files whose bytes end up different from REPO's are
        # compiled from the overlay.
        staging = os.path.join(self.src_overlay, ".staging")
        for rel in all_rel:
            dst = os.path.join(staging, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copyfile(os.path.join(self.repo, rel), dst)
        for fn in patches:
            pf = os.path.join(d, fn)
            base = [
                "patch",
                "-p1",
                "--forward",
                "--batch",
                "-s",
                "-d",
                staging,
                "-i",
                pf,
            ]
            r = subprocess.run(
                base + ["--dry-run"], capture_output=True, text=True
            )
            out = (r.stdout + r.stderr).strip()
            if r.returncode == 0:
                r2 = subprocess.run(base, capture_output=True, text=True)
                if r2.returncode != 0:
                    sys.exit(
                        "gen_ninja.py: source patch %s failed to apply after a clean dry run:\n%s"
                        % (fn, r2.stdout + r2.stderr)
                    )
                self.patch_state.append((fn, "applied", touched[fn]))
            elif "Reversed (or previously applied) patch detected" in out:
                self.patch_state.append((fn, "landed", touched[fn]))
            else:
                sys.exit(
                    "gen_ninja.py: source patch %s does not apply to REPO=%s (delete or refresh it):\n%s"
                    % (fn, self.repo, out)
                )
        # Materialize the overlay: write-if-changed the files that differ from REPO, remove
        # anything else left there by an earlier run (individual files only; never rm -rf).
        keep = set()
        for rel in all_rel:
            with open(os.path.join(staging, rel), "rb") as f:
                data = f.read()
            with open(os.path.join(self.repo, rel), "rb") as f:
                same = f.read() == data
            if same:
                continue
            overlay = os.path.join(self.src_overlay, rel)
            write_if_changed(overlay, data)
            keep.add(overlay)
            self.src_overrides[os.path.join(self.repo, rel)] = overlay
        for root, dirs, files in os.walk(self.src_overlay, topdown=False):
            if root == staging or root.startswith(staging + os.sep):
                continue
            for name in files:
                p = os.path.join(root, name)
                if p not in keep:
                    os.remove(p)
            for name in dirs:
                p = os.path.join(root, name)
                if p != staging and not os.listdir(p):
                    os.rmdir(p)
        lines = [
            "%s %s %s" % (fn, state, " ".join(files))
            for fn, state, files in self.patch_state
        ]
        write_if_changed(state_path, "\n".join(lines) + ("\n" if lines else ""))

    def obj_path(self, node, src):
        lab = node.label
        rel = src.path
        if not src.is_source:
            rel = "gen/" + src.path[len(bg.BIN_DIR) + 1 :]
        if lab.repo:
            d = os.path.join(
                self.obj, "external", lab.repo, lab.package, lab.name
            )
            rel = src.pkg_rel if src.is_source else rel
        else:
            d = os.path.join(self.obj, lab.package, lab.name)
        return os.path.join(d, rel + ".o")

    # ---- flags

    def setup_flags(self):
        warnings, dropped = probe_flags(self.cxx, WARNINGS)
        for fl, why in dropped:
            self.notes.append(
                "warning flag dropped (rejected by %s): %s  [%s]"
                % (self.cxx, fl, why)
            )
        # Carbon builds against libc++, whose headers declare explicit deduction guides; with
        # libstdc++ (NOTES-A.md D2) -Wctad-maybe-unsupported fires on `std::scoped_lock lock(mu)`
        # (toolchain/driver/clang_runtimes.cpp). Warning flags never change the output.
        warnings.append("-Wno-ctad-maybe-unsupported")
        self.notes.append(
            "added -Wno-ctad-maybe-unsupported (libstdc++ lacks libc++'s CTAD guides)"
        )
        self.warnings = warnings
        inc = []
        inc += ["-iquote", self.repo, "-iquote", self.gen]
        # Bazel adds the external repository roots as quote include dirs, which is how
        # `#include "clang-tools-extra/clangd/LSPBinder.h"` (toolchain/language_server) resolves.
        llvm_ws = bg.Label("llvm-project", "", "").workspace_root
        inc += [
            "-iquote",
            self.llvm_src,
            "-iquote",
            os.path.join(self.gen, llvm_ws),
        ]
        for d in ("llvm/include", "clang/include", "lld/include"):
            inc += ["-isystem", os.path.join(self.llvm_src, d)]
        for d in ("include", "tools/clang/include", "tools/lld/include"):
            inc += ["-isystem", os.path.join(self.llvm_build, d)]
        for key in (
            "ABSL_INCLUDE",
            "GTEST_INCLUDE",
            "RE2_INCLUDE",
            "BOOST_INCLUDE",
            "RUNFILES_INCLUDE",
        ):
            if self.deps.get(key):
                inc += ["-isystem", self.deps[key]]
        self.includes = inc
        self.prefix_map = [
            "-ffile-prefix-map=%s/=" % self.repo,
            "-ffile-prefix-map=%s/=" % self.gen,
        ]
        common = CXX_FLAGS + MODE_FLAGS[self.mode] + CPU_FLAGS + self.prefix_map
        # Carbon's headers use std::variant without including <variant> (toolchain/sem_ir/
        # inst_kind.h, toolchain/base/kind_switch.h, toolchain/check/require_impls_stack.h,
        # toolchain/sem_ir/declared_facet_type.h); libc++ provides it transitively, libstdc++
        # (NOTES-A.md D2) does not. `-include variant` only adds standard declarations.
        # Likewise <cmath> for log2/std::log2f/std::ceil in toolchain/check/handle_choice.cpp and
        # toolchain/check/eval.cpp.
        self.carbon_cxxflags = (
            common
            + ["-include", "variant", "-include", "cmath"]
            + warnings
            + ["--system-header-prefix=" + p for p in SYSTEM_HEADER_PREFIXES]
        )
        self.notes.append(
            "added `-include variant -include cmath` to Carbon compiles (libstdc++ transitive-include difference, D12)"
        )
        # External sources: .bazelrc `--per_file_copt=external/.*@-w`.
        self.external_cxxflags = common + ["-w"] + LLVM_SRC_DEFINES

    # ---- archives

    def llvm_archives(self):
        libdir = os.path.join(self.llvm_build, "lib")
        out = []
        for fn in sorted(os.listdir(libdir)):
            if not fn.endswith(".a"):
                continue
            if not (
                fn.startswith("libLLVM")
                or fn.startswith("libclang")
                or fn.startswith("liblld")
            ):
                continue
            if re.search(r"Testing|gtest|gmock|TableGen", fn):
                continue
            out.append(os.path.join(libdir, fn))
        required = [
            "libLLVMSupport.a",
            "libLLVMX86CodeGen.a",
            "libLLVMAArch64CodeGen.a",
            "libclangDriver.a",
            "libclangFrontendTool.a",
            "libclangCodeGen.a",
            "liblldELF.a",
            "liblldMachO.a",
            "liblldCommon.a",
            "libLLVMPasses.a",
        ]
        missing = [
            r for r in required if not os.path.exists(os.path.join(libdir, r))
        ]
        if missing:
            sys.exit(
                "gen_ninja.py: LLVM build at %s is incomplete, missing %s (is the LLVM ninja "
                "build finished?)" % (self.llvm_build, ", ".join(missing))
            )
        return out

    def dep_archives(self, groups):
        """Archives for the external groups in a root's closure (order: gtest, re2, absl)."""
        out = []
        if "gtest" in groups:
            out += shlex.split(self.deps.get("GTEST_LIBS", ""))
        if "re2" in groups:
            out += [self.deps["RE2_LIB"]]
        if "absl" in groups or "re2" in groups or "gtest" in groups:
            rsp = self.deps["ABSL_LIBS"]
            with open(rsp) as f:
                out += [l.strip() for l in f if l.strip()]
        return out

    # ---- ninja emission

    def emit(self, s=""):
        self.lines.append(s)

    def header(self):
        e = self.emit
        e(
            "# Generated by %s for %s at %s; do not edit (re-run gen_ninja.py or build.sh)."
            % (os.path.join(HERE, "gen_ninja.py"), self.repo, self.P["SHA"])
        )
        e("ninja_required_version = 1.3")
        e("builddir = %s" % esc(self.build_dir))
        e("cxx = %s" % esc(self.cxx))
        e(
            "carbon_cxxflags = %s"
            % " ".join(shlex.quote(x) for x in self.carbon_cxxflags)
        )
        e(
            "external_cxxflags = %s"
            % " ".join(shlex.quote(x) for x in self.external_cxxflags)
        )
        e("includes = %s" % " ".join(shlex.quote(x) for x in self.includes))
        e("python = %s" % esc(sys.executable))
        e(
            "tblgen = %s"
            % esc(os.path.join(self.llvm_build, "bin", "llvm-tblgen"))
        )
        e("")
        e("rule cxx")
        e(
            "  command = $cxx $cxxflags $includes $flags -MD -MF $out.d -frandom-seed=$seed -c $in -o $out"
        )
        e("  depfile = $out.d")
        e("  deps = gcc")
        e("  description = CXX $out")
        e("")
        e("rule link")
        e("  command = $cxx -o $out @$out.rsp")
        e("  rspfile = $out.rsp")
        e("  rspfile_content = $content")
        e("  description = LINK $out")
        e("")
        e("rule gen_tmpl")
        e("  command = $python -I $tool $args")
        e("  description = GEN $out")
        e("")
        e("rule tblgen_opts")
        e(
            "  command = $tblgen -gen-opt-parser-defs -I %s -I $tddir $in -o $out -d $out.d"
            % esc(os.path.join(self.llvm_src, "llvm", "include"))
        )
        e("  depfile = $out.d")
        e("  deps = gcc")
        e("  description = TBLGEN $out")
        e("")

    def compile_object(
        self, node, src, cxxflags_var, flags, implicit, order_only
    ):
        out = self.obj_path(node, src)
        src_real = self.real(src)
        if src.is_source and src_real != src.real_path:
            # A patched copy (apply_source_patches): map its directory away exactly as REPO's
            # is, so __FILE__ and debug info equal the unpatched build's. Per object, so the
            # command lines of unpatched objects do not change when a patch comes or goes.
            flags = list(flags) + ["-ffile-prefix-map=%s/=" % self.src_overlay]
        e = self.emit
        line = "build %s: cxx %s" % (esc(out), esc(src_real))
        if implicit:
            line += " | " + " ".join(esc(x) for x in implicit)
        if order_only:
            line += " || " + " ".join(esc(x) for x in order_only)
        e(line)
        e("  cxxflags = $" + cxxflags_var)
        e("  flags = %s" % " ".join(shlex.quote(x) for x in flags))
        e("  seed = %s" % esc(os.path.relpath(out, self.build_dir)))
        self.objects.append(out)
        base = (
            self.carbon_cxxflags
            if cxxflags_var == "carbon_cxxflags"
            else self.external_cxxflags
        )
        self.compile_db.append(
            {
                "directory": self.build_dir,
                "file": src_real,
                "output": out,
                "arguments": [self.cxx]
                + base
                + self.includes
                + flags
                + ["-c", src_real, "-o", out],
            }
        )
        return out

    def roots_for(self, label):
        """(source root, generated root) of a label's repository."""
        if label.repo == "":
            return self.repo, self.gen
        if label.repo == "llvm-project":
            return self.llvm_src, os.path.join(self.gen, label.workspace_root)
        raise SystemExit("gen_ninja.py: no source tree for %s" % label)

    def node_flags(self, node, closure_nodes):
        """-D and -isystem flags for a cc node: transitive defines/includes + own."""
        flags = []
        seen = set()
        for dep in closure_nodes:
            for d in dep.defines:
                if d not in seen:
                    seen.add(d)
                    flags.append("-D" + d)
            for inc in dep.includes:
                if dep.external:
                    continue
                pkg = dep.label.package
                for root in self.roots_for(dep.label):
                    p = os.path.normpath(os.path.join(root, pkg, inc))
                    if p not in seen:
                        seen.add(p)
                        flags += ["-isystem", p]
        for d in node.local_defines:
            flags.append("-D" + d)
        for c in node.copts:
            c = c.replace("$(BINDIR)", self.gen).replace("$(GENDIR)", self.gen)
            c = c.replace("$(STACK_FRAME_UNLIMITED)", "")
            if "$(" in c:
                raise SystemExit(
                    "gen_ninja.py: unexpanded make variable in copts of %s: %s"
                    % (node.label, c)
                )
            if c:
                flags.append(c)
        return flags

    def transitive(self, node):
        """Nodes reachable from node (inclusive), in dependents-first order."""
        seen = set()
        out = []

        def visit(n):
            if n.label in seen:
                return
            seen.add(n.label)
            for d in n.deps:
                visit(d)
            out.append(n)

        visit(node)
        return list(reversed(out))

    def run(self):
        g = self.graph
        self.apply_source_patches()
        self.setup_flags()
        order, nodes = g.cc_closure([r for r, _ in ROOTS])
        self.header()
        e = self.emit

        # Generated files reachable from the closure (srcs/hdrs/textual_hdrs of every node).
        generated = {}
        for n in order:
            if n.external:
                continue
            for f in n.srcs + n.hdrs + n.textual_hdrs:
                if not f.is_source:
                    generated[f.path] = f
        gen_written = []
        gen_rules = []
        for path, f in sorted(generated.items()):
            real = self.gen_path(f)
            if f.content is not None:
                write_if_changed(real, f.content)
                gen_written.append(real)
            elif f.action is not None:
                tool = f.action.executable.real_path
                mapping = {f.path: real}
                for i in f.action.inputs:
                    mapping[i.path] = self.real(i)
                args = []
                for a in f.action.arguments:
                    for k, v in sorted(
                        mapping.items(), key=lambda kv: -len(kv[0])
                    ):
                        a = a.replace(k, v)
                    args.append(a)
                e(
                    "build %s: gen_tmpl %s | %s"
                    % (
                        esc(real),
                        " ".join(esc(self.real(i)) for i in f.action.inputs),
                        esc(tool),
                    )
                )
                e("  tool = %s" % esc(tool))
                e("  args = %s" % " ".join(shlex.quote(a) for a in args))
                gen_rules.append(real)
            elif f.generator is not None and f.generator.kind == "genrule":
                write_if_changed(real, g.file_bytes(f))
                gen_written.append(real)
            else:
                raise SystemExit(
                    "gen_ninja.py: do not know how to produce generated file %s (%s)"
                    % (f.path, f.generator)
                )
        e("")
        self.phony_gen = gen_written
        if gen_written:
            e(
                "build gen_headers: phony %s"
                % " ".join(esc(x) for x in gen_written)
            )
        else:
            e("build gen_headers: phony")
        e("")

        # Tablegen outputs for the LLVM tool libraries.
        tool_inc_dirs = {}
        for n in order:
            t = n.target
            if isinstance(t, bg.ToolLibTarget):
                inc_dir = os.path.join(
                    self.gen, "external", "llvm-project", t.tool_dir
                )
                tool_inc_dirs[n.label] = inc_dir
                for td, inc in t.tablegen:
                    out = os.path.join(inc_dir, inc)
                    e(
                        "build %s: tblgen_opts %s"
                        % (esc(out), esc(os.path.join(self.llvm_src, td)))
                    )
                    e(
                        "  tddir = %s"
                        % esc(os.path.join(self.llvm_src, os.path.dirname(td)))
                    )
                    n.extra_implicit = getattr(n, "extra_implicit", []) + [out]
        e("")

        # Objects.
        node_objects = {}
        n_sources = 0
        for n in order:
            if isinstance(n.target, bg.ExternalCcTarget):
                continue
            objs = []
            if isinstance(n.target, bg.ToolLibTarget):
                flags = [
                    "-I",
                    tool_inc_dirs[n.label],
                    "-I",
                    os.path.join(self.llvm_src, n.target.tool_dir),
                ]
                for src in n.srcs:
                    objs.append(
                        self.compile_object(
                            n,
                            src,
                            "external_cxxflags",
                            flags,
                            getattr(n, "extra_implicit", []),
                            [],
                        )
                    )
                    n_sources += 1
            else:
                closure = self.transitive(n)
                flags = self.node_flags(n, closure)
                # Sources of external repositories (e.g. @llvm-project//clang-tools-extra/clangd:
                # ClangDaemon, compiled from the overlay's cc_library) get `-w` like Bazel's
                # --per_file_copt=external/.*@-w.
                var = (
                    "carbon_cxxflags"
                    if n.label.repo == ""
                    else "external_cxxflags"
                )
                for src in n.srcs:
                    if not src.basename.endswith(COMPILED_EXTS):
                        continue
                    implicit = [] if src.is_source else [self.real(src)]
                    objs.append(
                        self.compile_object(
                            n, src, var, flags, implicit, ["gen_headers"]
                        )
                    )
                    n_sources += 1
            node_objects[n.label] = objs
        e("")

        # Runfiles library object (@bazel_tools//tools/cpp/runfiles).
        runfiles_obj = None
        if self.deps.get("RUNFILES_SRC"):
            runfiles_obj = os.path.join(
                self.obj,
                "external",
                "bazel_tools",
                "tools",
                "cpp",
                "runfiles",
                "runfiles.cc.o",
            )
            e(
                "build %s: cxx %s"
                % (esc(runfiles_obj), esc(self.deps["RUNFILES_SRC"]))
            )
            e("  cxxflags = $external_cxxflags")
            e("  flags =")
            e(
                "  seed = %s"
                % esc(os.path.relpath(runfiles_obj, self.build_dir))
            )
            e("")

        llvm_libs = self.llvm_archives()
        system_libs = cmake_system_libs(self.llvm_build) + SYSTEM_LIBS

        # Links.
        bins = []
        env = {}
        for root_label, bin_name in ROOTS:
            root = nodes[g.target(root_label).label]
            closure = self.transitive(root)
            groups = {
                n.group
                for n in closure
                if isinstance(n.target, bg.ExternalCcTarget)
            }
            env.update(root.env or {})
            out = os.path.join(self.bin, bin_name)
            content = list(CPU_FLAGS) + LINK_FLAGS
            inputs = []
            # Own objects first, then the linkstamp, then libraries dependents-first.
            content += node_objects[root.label]
            inputs += node_objects[root.label]
            for n in closure:
                ls = n.linkstamp
                if ls is not None:
                    ls_obj = os.path.join(
                        self.obj,
                        root.label.package,
                        root.label.name,
                        "linkstamp",
                        ls.pkg_rel + ".o",
                    )
                    ls_flags = self.node_flags(n, self.transitive(n)) + [
                        '-DG3_VERSION_INFO="%s"' % str(root.label),
                        '-DG3_TARGET_NAME="%s"' % str(root.label),
                        '-DGPLATFORM="local_linux_x86_64"',
                        "-DBUILD_COVERAGE_ENABLED=0",
                        '-DG3_BUILD_TARGET="%s"'
                        % os.path.relpath(out, self.build_dir),
                    ]
                    e(
                        "build %s: cxx %s || gen_headers"
                        % (esc(ls_obj), esc(self.real(ls)))
                    )
                    e("  cxxflags = $carbon_cxxflags")
                    e(
                        "  flags = %s"
                        % " ".join(shlex.quote(x) for x in ls_flags)
                    )
                    e(
                        "  seed = %s"
                        % esc(os.path.relpath(ls_obj, self.build_dir))
                    )
                    content.append(ls_obj)
                    inputs.append(ls_obj)
            for n in closure:
                if n is root or isinstance(n.target, bg.ExternalCcTarget):
                    continue
                objs = node_objects.get(n.label, [])
                if not objs:
                    continue
                inputs += objs
                if n.alwayslink:
                    content += objs
                else:
                    content += ["-Wl,--start-lib"] + objs + ["-Wl,--end-lib"]
            if "runfiles" in groups and runfiles_obj:
                content += ["-Wl,--start-lib", runfiles_obj, "-Wl,--end-lib"]
                inputs.append(runfiles_obj)
            for n in closure:
                for lo in n.linkopts:
                    if lo not in content:
                        content.append(lo)
            archives = self.dep_archives(groups) + llvm_libs
            content += (
                ["-Wl,--start-group"]
                + archives
                + ["-Wl,--end-group"]
                + system_libs
            )
            inputs += archives
            e(
                "build %s: link %s"
                % (esc(out), " ".join(esc(x) for x in inputs))
            )
            e("  content = %s" % " ".join(content).replace("$", "$$"))
            e("")
            bins.append(out)
        e("build all: phony %s" % " ".join(esc(b) for b in bins))
        e("default all")
        # Short aliases so `build.sh file_test` / `ninja -C $BUILD_DIR bin/file_test` work
        # although every real output is an absolute path (REVIEW-1 R1-N2).
        for b in bins:
            e("build %s: phony %s" % (esc(os.path.basename(b)), esc(b)))
            e(
                "build %s: phony %s"
                % (esc(os.path.relpath(b, self.build_dir)), esc(b))
            )
        e("")

        os.makedirs(self.build_dir, exist_ok=True)
        write_if_changed(
            os.path.join(self.build_dir, "build.ninja"),
            "\n".join(self.lines) + "\n",
        )
        with open(
            os.path.join(self.build_dir, "compile_commands.json"), "w"
        ) as f:
            json.dump(self.compile_db, f, indent=1)

        # env.sh for author C: the cc_env() of the binaries (bazel/cc_toolchains/defs.bzl).
        env_lines = [
            "# Generated by gen_ninja.py: the `env` Carbon's cc_binary/cc_test wrappers set",
            "# (bazel/cc_rules/defs.bzl -> bazel/cc_toolchains/defs.bzl cc_env()). Source this",
            "# before running bin/carbon-busybox, bin/file_test or bin/make-installation-digest.",
        ]
        for k in sorted(env):
            env_lines.append("export %s=%s" % (k, shlex.quote(str(env[k]))))
        env_lines.append("# Binaries: " + ", ".join(bins))
        write_if_changed(
            os.path.join(HERE, "env.sh"), "\n".join(env_lines) + "\n"
        )

        # Report.
        manifest = g.manifest_text(
            "//toolchain/testing:file_test_autogen_manifest.cpp"
        )
        n_tests = sum(1 for l in manifest.splitlines() if l.startswith('    "'))
        n_targets = len(order)
        n_ext = sum(
            1 for n in order if isinstance(n.target, bg.ExternalCcTarget)
        )
        print("gen_ninja.py: compiler %s (%s)" % (self.cxx, self.cxx_version))
        print(
            "gen_ninja.py: mode %s; wrote %s"
            % (self.mode, os.path.join(self.build_dir, "build.ninja"))
        )
        print(
            "gen_ninja.py: targets in closure: %d (%d Carbon cc targets, %d external, %d LLVM tool libs)"
            % (
                n_targets,
                n_targets
                - n_ext
                - sum(
                    1 for n in order if isinstance(n.target, bg.ToolLibTarget)
                ),
                n_ext,
                sum(1 for n in order if isinstance(n.target, bg.ToolLibTarget)),
            )
        )
        print(
            "gen_ninja.py: source files compiled: %d; generated files: %d (%d written now, %d ninja rules); objects: %d"
            % (
                n_sources,
                len(generated),
                len(gen_written),
                len(gen_rules),
                len(self.objects),
            )
        )
        print("gen_ninja.py: file_test manifest: %d test files" % n_tests)
        if self.patch_state:
            print(
                "gen_ninja.py: source patches (%s -> %s): %s"
                % (
                    self.src_patches_dir,
                    self.src_overlay,
                    "; ".join(
                        "%s %s (%s)" % (fn, state, ", ".join(files))
                        for fn, state, files in self.patch_state
                    ),
                )
            )
        else:
            print(
                "gen_ninja.py: source patches: none (SRC_PATCHES=%s)"
                % (self.src_patches_dir or "unset")
            )
        print(
            "gen_ninja.py: LLVM archives: %d; system libs: %s; external groups: %s"
            % (
                len(llvm_libs),
                " ".join(system_libs),
                ", ".join(
                    sorted(
                        {
                            n.group
                            for n in order
                            if isinstance(n.target, bg.ExternalCcTarget)
                        }
                    )
                ),
            )
        )
        for note in self.notes + g.notes:
            print("gen_ninja.py: note: " + note)
        return 0


def main(argv):
    verbose = "--verbose" in argv
    P = paths.load()
    deps_env_path = os.path.join(P["DEPS"], "deps.env")
    if not os.path.exists(deps_env_path):
        sys.exit(
            "gen_ninja.py: %s is missing (author B's deps.sh writes it)"
            % deps_env_path
        )
    deps_env = paths.load_env(deps_env_path)
    for key in (
        "ABSL_INCLUDE",
        "ABSL_LIBS",
        "RE2_INCLUDE",
        "RE2_LIB",
        "GTEST_INCLUDE",
        "GTEST_LIBS",
        "BOOST_INCLUDE",
        "RUNFILES_INCLUDE",
        "RUNFILES_SRC",
    ):
        if key not in deps_env:
            sys.exit("gen_ninja.py: deps.env lacks %s" % key)
    return Gen(P, deps_env, verbose).run()


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

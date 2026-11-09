#!/usr/bin/env python3
"""install.py: build the Carbon toolchain install tree without Bazel.

Part of the Carbon Language project fork's container arbiter (Bazel-free build
of the Carbon toolchain). Apache-2.0 WITH LLVM-exception.

Reproduces, from the same sources, what `bazel build //toolchain/install:carbon_toolchain_tar`
packs (toolchain/install/BUILD, install_filegroups.bzl, pkg_helpers.bzl): the
PACKAGED layout the nightly tarball uses,

    $INSTALL_DIR/bin/carbon -> ../lib/carbon/carbon-busybox
    $INSTALL_DIR/lib/carbon/<every file of all_data_files, llvm_bins, carbon-busybox
                             and install_digest.txt>

plus two build artifacts next to the binaries,

    $BUILD_DIR/clang_headers_manifest.txt   (//toolchain/install:clang_headers_manifest.txt,
                                             read by //toolchain/testing:file_test)
    $BUILD_DIR/install_digest_manifest.txt  (//toolchain/install:install_digest_manifest.txt,
                                             the input of make-installation-digest)

Configuration comes from paths.sh (REPO, SHA, LLVM_SRC, LLVM_BUILD, LLVM_OVERLAY,
BUILD_DIR, INSTALL_DIR, BUSYBOX_BIN, DIGEST_BIN). Nothing is written into REPO.

    install.py --dry-run      list every file with its source; fail on a missing source
    install.py                install (requires $BUSYBOX_BIN and $DIGEST_BIN)
    install.py --allow-pending   install everything except the busybox and the digest
    install.py --provenance   print the provenance table (README)
    install.py --compare-nightly DIR   diff the installed layout against an extracted nightly

The file sets come from evaluating the Bazel BUILD files (bzl_eval.py): LLVM's
overlay (with Carbon's patches, $LLVM_OVERLAY) for the runtimes sources and
clang's builtin headers, and Carbon's own toolchain/install/BUILD,
toolchain/runtimes/BUILD, core/BUILD, bazel/cc_toolchains/BUILD and
toolchain/install/install_filegroups.bzl for the layout.
"""

__copyright__ = """
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""

import argparse
import hashlib
import os
import re
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bzl_eval  # noqa: E402

PATH_VARS = [
    "ARB",
    "REPO",
    "SHA",
    "LLVM_SRC",
    "LLVM_BUILD",
    "LLVM_OVERLAY",
    "DEPS",
    "BUILD_DIR",
    "INSTALL_DIR",
    "CB",
    "BUSYBOX_BIN",
    "DIGEST_BIN",
    "CARBON_BUILD_MODE",
]


def load_paths(paths_sh=None):
    """Source paths.sh under bash so `${NAME:-default}` overrides apply."""
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


class Entry:
    """One installed path under lib/carbon.

    kind: "copy" (from `source`), "gen" (bytes from `gen()`), "symlink" (to
    `target`, relative), "pending" (a built binary that does not exist yet).
    """

    def __init__(
        self,
        group,
        rel,
        kind,
        source=None,
        gen=None,
        target=None,
        origin="",
        executable=False,
    ):
        self.group = group
        self.rel = rel
        self.kind = kind
        self.source = source
        self.gen = gen
        self.target = target
        self.origin = origin
        self.executable = executable


class Plan:
    def __init__(self, P):
        self.P = P
        self.entries = []
        self.by_rel = {}
        self.problems = []
        self.notes = []
        self.llvm_major = self._llvm_major()
        self.overlay = bzl_eval.Overlay(
            P["LLVM_OVERLAY"], P["LLVM_SRC"], warn=self.note
        )
        # The Carbon repository evaluated with the same machinery, for the
        # globs of core/BUILD and the testdata filegroups.
        self.repo = bzl_eval.Overlay(P["REPO"], P["REPO"], warn=self.note)
        self.clang_hdrs_rel = []  # install-relative, in Bazel order
        self.digest_order = []  # install-relative, all_digest_files order
        self.gen_files = {}  # install-relative -> File (for runtimes_build_vars)

    # -- helpers -----------------------------------------------------------
    def note(self, msg):
        self.notes.append(msg)

    def problem(self, msg):
        self.problems.append(msg)

    def _llvm_major(self):
        """LLVM_VERSION_MAJOR as `@llvm-project//:vars.bzl` carries it: from
        llvm/CMakeLists.txt's LLVMVersion.cmake (utils/bazel/configure.bzl
        reads the same variable)."""
        path = os.path.join(
            self.P["LLVM_SRC"], "cmake", "Modules", "LLVMVersion.cmake"
        )
        with open(path, encoding="utf-8") as f:
            m = re.search(r"set\(LLVM_VERSION_MAJOR (\d+)\)", f.read())
        if not m:
            sys.exit("cannot read LLVM_VERSION_MAJOR from " + path)
        return m.group(1)

    def add(self, entry):
        if entry.rel in self.by_rel:
            self.problem(
                "duplicate install path %s (%s and %s)"
                % (entry.rel, self.by_rel[entry.rel].group, entry.group)
            )
            return
        self.by_rel[entry.rel] = entry
        self.entries.append(entry)
        self.digest_order.append(entry.rel)

    def repo_file(self, rel):
        path = os.path.join(self.P["REPO"], rel)
        if not os.path.isfile(path):
            self.problem("missing source %s" % path)
        return path

    def add_repo_copy(self, group, rel, repo_rel):
        self.add(
            Entry(
                group,
                rel,
                "copy",
                source=self.repo_file(repo_rel),
                origin="REPO/" + repo_rel,
            )
        )

    def overlay_files(self, label):
        try:
            return self.overlay.files_of(label)
        except bzl_eval.BzlError as e:
            self.problem("%s: %s" % (label, e))
            return []

    @staticmethod
    def strip_prefix(path, prefix, what):
        if prefix and not path.startswith(prefix):
            raise bzl_eval.BzlError(
                "Unable to remove prefix '%s' from '%s' (%s)"
                % (prefix, path, what)
            )
        return path[len(prefix) :]

    def add_toolchain_files(self, group, labels, prefix, remove_prefix=""):
        """`toolchain_files` / `filtered_toolchain_files` of
        install_filegroups.bzl: each file of the (de-duplicated union of the)
        labels lands at prefix + (package-relative path minus remove_prefix)."""
        files = []
        for label in labels:
            files.extend(self.overlay_files(label))
        files = bzl_eval._dedup(files)
        rels = []
        for f in files:
            try:
                rel = prefix + self.strip_prefix(f.rel, remove_prefix, group)
            except bzl_eval.BzlError as e:
                self.problem(str(e))
                continue
            rels.append(rel)
            self.gen_files[rel] = f
            self.add(self.entry_for_file(group, rel, f))
        return rels

    def entry_for_file(self, group, rel, f):
        if f.gen is None:
            return Entry(group, rel, "copy", source=f.source, origin=f.origin)
        if f.gen["type"] == "concat_echo":
            src = f.gen["src"]
            lines = f.gen["lines"]

            def gen(src=src, lines=lines):
                with open(src.source, "rb") as fh:
                    body = fh.read()
                return ("\n".join(lines) + "\n").encode() + body

            return Entry(group, rel, "gen", gen=gen, origin=f.origin)
        if f.gen["type"] == "tblgen":
            # clang's generated headers. The CMake build of LLVM_BUILD produces
            # the same file (lib/clang/<MAJOR>/include/<name>; validated
            # byte-identical for arm_neon.h); use it when it exists, else run
            # clang-tblgen exactly as clang/lib/Headers/CMakeLists.txt does.
            name = f.rel.rsplit("/", 1)[-1]
            cmake_copy = os.path.join(
                self.P["LLVM_BUILD"],
                "lib",
                "clang",
                self.llvm_major,
                "include",
                name,
            )
            if os.path.isfile(cmake_copy):
                return Entry(
                    group,
                    rel,
                    "copy",
                    source=cmake_copy,
                    origin="LLVM_BUILD/lib/clang/%s/include/%s (CMake ran %s)"
                    % (self.llvm_major, name, f.origin),
                )
            tblgen = os.path.join(self.P["LLVM_BUILD"], "bin", "clang-tblgen")
            if not os.path.isfile(tblgen):
                self.problem(
                    "%s: neither %s nor %s exists" % (rel, cmake_copy, tblgen)
                )
            opts = f.gen["opts"]
            td = f.gen["td"]

            def gen(opts=opts, td=td, tblgen=tblgen):
                with tempfile.TemporaryDirectory() as d:
                    out = os.path.join(d, "out.h")
                    subprocess.run(
                        [tblgen]
                        + opts
                        + ["-I", os.path.dirname(td), td, "-o", out],
                        check=True,
                    )
                    with open(out, "rb") as fh:
                        return fh.read()

            return Entry(
                group,
                rel,
                "gen",
                gen=gen,
                origin=f.origin + " (LLVM_BUILD/bin/clang-tblgen)",
            )
        self.problem("%s: unknown generator %s" % (rel, f.gen["type"]))
        return Entry(group, rel, "gen", gen=lambda: b"", origin="?")

    # -- the plan: toolchain/install/BUILD, `all_data_files` in order --------
    def build(self):
        P = self.P
        R = P["REPO"]
        M = self.llvm_major
        clang_prefix = "llvm/lib/clang/%s/include/" % M

        # Read the Carbon BUILD files we mirror, so a changed attribute is
        # noticed: the install targets, their prefixes and sources.
        inst = bzl_eval.eval_file(
            os.path.join(R, "toolchain/install/BUILD"),
            R,
            native={"LLVM_VERSION_MAJOR": M},
            warn=self.note,
        )
        targets = {}
        for kind, kw in inst["__targets__"]:
            if "name" in kw:
                targets[kw["name"]] = (kind, kw)

        def tf(name):
            kind, kw = targets[name]
            assert kind in ("toolchain_files", "filtered_toolchain_files"), name
            return kw

        # 1. builtins_all_srcs (filtered_toolchain_files "builtins_srcs").
        kw = tf("builtins_srcs")
        self.add_toolchain_files(
            "builtins_all_srcs",
            kw["srcs_groups"],
            kw["prefix"],
            kw["remove_prefix"],
        )

        # 2. clang_hdrs = clang_builtin_hdrs + fuzzer/profile/sanitizer hdrs.
        kw = tf("clang_builtin_hdrs")
        assert (
            kw["prefix"] == clang_prefix
            and kw["remove_prefix"] == "staging/include/"
        ), kw
        # @llvm-project//clang:builtin_headers_gen copies every `builtin_headers`
        # entry (clang/BUILD.bazel) to staging/include/<path after lib/Headers/>.
        try:
            builtin_headers = self.overlay.global_value(
                "clang", "builtin_headers"
            )
            clang_pkg = self.overlay.package("clang")
            for h in builtin_headers:
                f = clang_pkg.files_of(h)[0]
                rel = clang_prefix + self.strip_prefix(
                    f.rel, "lib/Headers/", "builtin_headers_gen"
                )
                self.clang_hdrs_rel.append(rel)
                self.add(self.entry_for_file("clang_builtin_hdrs", rel, f))
        except bzl_eval.BzlError as e:
            self.problem("clang builtin headers: %s" % e)
        for name in (
            "fuzzer_runtime_hdrs",
            "profile_runtime_hdrs",
            "sanitizer_runtime_hdrs",
        ):
            kw = tf(name)
            self.clang_hdrs_rel.extend(
                self.add_toolchain_files(
                    name, kw["srcs"], kw["prefix"], kw["remove_prefix"]
                )
            )

        # 3. core (//core:prelude = prelude_files + prelude_manifest.txt) and
        # 4. core_library, both with prefix "core/". The manifests are
        # bazel/manifest/defs.bzl `manifest(strip_package_dir = True)`: one
        # package-relative path per line, trailing newline.
        for group, files_label, manifest_name in (
            ("core", "//core:prelude_files", "prelude_manifest.txt"),
            (
                "core_library",
                "//core:core_library_files",
                "core_library_manifest.txt",
            ),
        ):
            prefix = tf(group)["prefix"]
            try:
                files = self.repo.files_of(files_label)
            except bzl_eval.BzlError as e:
                self.problem("%s: %s" % (files_label, e))
                files = []
            rels = []
            for f in files:
                rels.append(f.rel)
                self.gen_files[prefix + f.rel] = f
                self.add(
                    Entry(
                        group,
                        prefix + f.rel,
                        "copy",
                        source=f.source,
                        origin="REPO/core/" + f.rel,
                    )
                )
            content = ("\n".join(rels) + "\n").encode()
            self.add(
                Entry(
                    group,
                    prefix + manifest_name,
                    "gen",
                    gen=lambda c=content: c,
                    origin="manifest(%s, strip_package_dir) of %s"
                    % (manifest_name, files_label),
                )
            )
            if not rels:
                self.problem("%s resolved to no files" % files_label)

        # 5. install_marker.
        self.add_repo_copy(
            "install_marker",
            "carbon_install.txt",
            "toolchain/install/carbon_install.txt",
        )

        # 6. installed_bazel_files.
        kw = tf("bazel_build_and_module")
        for src in kw["srcs"]:
            rel = kw["renames"][
                self.strip_prefix(
                    src, kw["remove_prefix"], "bazel_build_and_module"
                )
            ]
            self.add_repo_copy(
                "installed_bazel_files", rel, "toolchain/install/" + src
            )
        kw = tf("bazel_common_srcs")
        # genrule carbon_cc_toolchain_config_for_install: sed over
        # bazel/cc_toolchains/carbon_cc_toolchain_config.bzl.
        gr = targets["carbon_cc_toolchain_config_for_install"][1]
        m = re.fullmatch(r"sed 's\|([^|]*)\|([^|]*)\|' \$< > \$@", gr["cmd"])
        if not m:
            self.problem(
                "genrule carbon_cc_toolchain_config_for_install changed: %r"
                % gr["cmd"]
            )
        else:
            old, new = m.group(1), m.group(2)
            src_path = self.repo_file(
                "bazel/cc_toolchains/carbon_cc_toolchain_config.bzl"
            )

            def gen_cfg(src_path=src_path, old=old, new=new):
                with open(src_path, encoding="utf-8") as fh:
                    return fh.read().replace(old, new).encode()

            self.add(
                Entry(
                    "installed_bazel_files",
                    kw["prefix"] + gr["outs"][0],
                    "gen",
                    gen=gen_cfg,
                    origin="sed 's|%s|%s|' REPO/bazel/cc_toolchains/carbon_cc_toolchain_config.bzl"
                    % (old, new),
                )
            )
        cct = bzl_eval.eval_file(
            os.path.join(R, "bazel/cc_toolchains/BUILD"), R, warn=self.note
        )
        starlark = None
        for kind, k2 in cct["__targets__"]:
            if (
                kind == "filegroup"
                and k2.get("name") == "installed_cc_toolchain_starlark"
            ):
                starlark = k2["srcs"]
        if not isinstance(starlark, list) or not starlark:
            self.problem(
                "//bazel/cc_toolchains:installed_cc_toolchain_starlark not found"
            )
            starlark = []
        for s in starlark:
            self.add_repo_copy(
                "installed_bazel_files",
                kw["prefix"] + s,
                "bazel/cc_toolchains/" + s,
            )
        kw = tf("bazel_install_srcs")
        for s in kw["srcs"]:
            self.add_repo_copy(
                "installed_bazel_files", s, "toolchain/install/" + s
            )
        kw = tf("carbon_runtimes_bzl_installed")
        self.add_repo_copy(
            "installed_bazel_files",
            kw["prefix"] + "carbon_runtimes.bzl",
            "toolchain/runtimes/carbon_runtimes.bzl",
        )
        # generate_runtimes_build_vars(name = "bazel/runtimes_build_vars.bzl"):
        # filled in after the runtimes groups below are resolved.
        self.add(
            Entry(
                "installed_bazel_files",
                "bazel/runtimes_build_vars.bzl",
                "gen",
                gen=self.gen_runtimes_build_vars,
                origin="toolchain/base/runtimes_build_vars.tpl.bzl expanded per runtimes_build_info.bzl",
            )
        )

        # 7. libc_internal_libcxx_hdrs.
        kw = tf("libc_internal_libcxx_hdrs")
        self.add_toolchain_files(
            "libc_internal_libcxx_hdrs",
            kw["srcs"],
            kw["prefix"],
            kw.get("remove_prefix", ""),
        )

        # 8. libcxx_all_srcs.
        kw = tf("libcxx_srcs")
        self.add_toolchain_files(
            "libcxx_all_srcs",
            kw["srcs_groups"],
            kw["prefix"],
            kw["remove_prefix"],
        )

        # 9. libcxx_hdrs = libcxx_basic_hdrs + libcxx_gen_hdrs.
        kw = tf("libcxx_basic_hdrs")
        self.add_toolchain_files(
            "libcxx_basic_hdrs", kw["srcs"], kw["prefix"], kw["remove_prefix"]
        )
        kw = tf("libcxx_gen_hdrs")
        self.add_libcxx_gen_hdrs(kw["prefix"], kw["remove_prefix"])

        # 10-14. libcxxabi, libunwind.
        for name in (
            "libcxxabi_hdrs",
            "libcxxabi_srcs",
            "libcxxabi_textual_srcs",
            "libunwind_hdrs",
            "libunwind_srcs",
        ):
            kw = tf(name)
            self.add_toolchain_files(
                name, kw["srcs"], kw["prefix"], kw.get("remove_prefix", "")
            )

        # 15. support_hdrs: include/carbon/expected.h (package path stripped).
        kw = tf("support_hdrs")
        for s in kw["srcs"]:
            self.add_repo_copy("support_hdrs", s, "toolchain/install/" + s)

        # all_digest_files = all_data_files + carbon-busybox.
        busybox = P["BUSYBOX_BIN"]
        if os.path.isfile(busybox):
            self.add(
                Entry(
                    "carbon-busybox",
                    "carbon-busybox",
                    "copy",
                    source=busybox,
                    origin="BUSYBOX_BIN (//toolchain/install:carbon-busybox)",
                    executable=True,
                )
            )
        else:
            self.add(
                Entry(
                    "carbon-busybox",
                    "carbon-busybox",
                    "pending",
                    source=busybox,
                    origin="BUSYBOX_BIN (//toolchain/install:carbon-busybox): not built yet",
                )
            )

        # Not in the digest: llvm_bins symlinks and the digest itself.
        ev = bzl_eval.Evaluator(R, warn=self.note)
        ifg = ev.eval_file(
            os.path.join(R, "toolchain/install/install_filegroups.bzl")
        )
        llvm_binaries = ifg.get("_llvm_binaries")
        if not isinstance(llvm_binaries, list) or not all(
            isinstance(b, str) for b in llvm_binaries
        ):
            self.problem(
                "install_filegroups.bzl `_llvm_binaries` did not evaluate: %r"
                % (llvm_binaries,)
            )
            llvm_binaries = []
        for b in llvm_binaries:
            self.add(
                Entry(
                    "llvm_bins",
                    "llvm/bin/" + b,
                    "symlink",
                    target="../../carbon-busybox",
                    origin="pkg_mklink -> ../../carbon-busybox (install_filegroups.bzl _llvm_binaries)",
                )
            )
        self.digest_order = [
            r for r in self.digest_order if not r.startswith("llvm/bin/")
        ]
        digest = P["DIGEST_BIN"]
        kind = (
            "gen"
            if os.path.isfile(digest) and os.path.isfile(busybox)
            else "pending"
        )
        self.add(
            Entry(
                "install_digest",
                "install_digest.txt",
                kind,
                source=digest,
                gen=self.gen_digest,
                origin="DIGEST_BIN over $BUILD_DIR/install_digest_manifest.txt (genrule gen_digest)",
            )
        )
        self.digest_order.remove("install_digest.txt")
        return self

    def add_libcxx_gen_hdrs(self, prefix, remove_prefix):
        """//toolchain/runtimes:libcxx_gen_files: the two configure_cmake_file
        outputs, produced by running toolchain/runtimes/configure_cmake_file_impl.py
        with the defines of toolchain/runtimes/BUILD."""
        R = self.P["REPO"]
        impl = self.repo_file("toolchain/runtimes/configure_cmake_file_impl.py")
        rt = bzl_eval.eval_file(
            os.path.join(R, "toolchain/runtimes/BUILD"), R, warn=self.note
        )
        found = 0
        for kind, kw in rt["__targets__"]:
            if kind != "configure_cmake_file":
                continue
            found += 1
            pkg, name = self.overlay.split_label(kw["src"])
            src = os.path.join(self.P["LLVM_SRC"], pkg, name[1:])
            if not os.path.isfile(src):
                self.problem(
                    "configure_cmake_file %s: missing %s" % (kw["name"], src)
                )
            rel = prefix + self.strip_prefix(
                kw["out"], remove_prefix, kw["name"]
            )
            defines = kw["defines"]
            if not isinstance(defines, dict):
                self.problem(
                    "configure_cmake_file %s: defines did not evaluate"
                    % kw["name"]
                )
                defines = {}

            def gen(src=src, defines=defines, impl=impl):
                args = [sys.executable, "-I", impl, "--src", src]
                for k, v in defines.items():
                    args += ["--defines", k, v]
                with tempfile.TemporaryDirectory() as d:
                    out = os.path.join(d, "out")
                    subprocess.run(args + ["--out", out], check=True)
                    with open(out, "rb") as fh:
                        return fh.read()

            self.add(
                Entry(
                    "libcxx_gen_hdrs",
                    rel,
                    "gen",
                    gen=gen,
                    origin="configure_cmake_file_impl.py --src LLVM_SRC/%s/%s with %d defines (toolchain/runtimes/BUILD %s)"
                    % (pkg, name[1:], len(defines), kw["name"]),
                )
            )
        if found != 2:
            self.problem(
                "expected 2 configure_cmake_file rules in toolchain/runtimes/BUILD, found %d"
                % found
            )

    # -- generated texts ----------------------------------------------------
    def gen_runtimes_build_vars(self):
        """toolchain/base/runtimes_build_info.bzl `_get_substitutions` applied to
        runtimes_build_vars.tpl.bzl."""
        R = self.P["REPO"]
        O = self.P["LLVM_OVERLAY"]
        ev = bzl_eval.Evaluator(O, warn=self.note)
        crt = ev.eval_file(os.path.join(O, "compiler-rt/compiler-rt.bzl"))
        cxx = ev.eval_file(os.path.join(O, "libcxx/libcxx_library.bzl"))
        unw = ev.eval_file(os.path.join(O, "libunwind/libunwind_library.bzl"))

        def one_per_line(items):
            return "\n" + "\n".join('    "%s",' % i for i in items) + "\n"

        def builtins_path(f):
            # `_builtins_path`: "runtimes/" + path below compiler-rt/lib/.
            rel = f.rel
            if not rel.startswith("lib/builtins/"):
                raise bzl_eval.BzlError(
                    "Not a builtins-relative path for: " + f.rel
                )
            return "runtimes/" + rel[len("lib/") :]

        def runtimes_paths(label, prefix):
            # `_get_paths(..., _runtimes_path, prefix)`: prefix + file.owner.name
            # (the package-relative path of a source file).
            if label.startswith("//core"):
                files = self.repo.files_of(label)
            else:
                files = self.overlay.files_of(label)
            return one_per_line(prefix + f.rel for f in files)

        subs = {
            "BUILTINS_COPTS": one_per_line(crt["builtins_copts"]),
            "CRT_COPTS": one_per_line(crt["crt_copts"]),
            "LIBCXX_AND_ABI_COPTS": one_per_line(cxx["libcxx_and_abi_copts"]),
            "LIBUNWIND_COPTS": one_per_line(unw["libunwind_copts"]),
            "LLVM_VERSION_MAJOR": self.llvm_major,
        }
        for key, label in (
            (
                "CRTBEGIN_SRC",
                "@llvm-project//compiler-rt:builtins_crtbegin_src",
            ),
            ("CRTEND_SRC", "@llvm-project//compiler-rt:builtins_crtend_src"),
        ):
            files = self.overlay.files_of(label)
            if len(files) != 1:
                raise bzl_eval.BzlError(
                    "Expected a single file and got %d files." % len(files)
                )
            subs[key] = '"%s"' % builtins_path(files[0])
        for arch in ("aarch64", "i386", "x86_64"):
            for suffix in ("srcs", "textual_srcs"):
                name = "builtins_%s_%s" % (arch, suffix)
                files = self.overlay.files_of(
                    "@llvm-project//compiler-rt:" + name
                )
                subs[name.upper()] = one_per_line(
                    builtins_path(f) for f in files
                )
        runtimes_prefixes = {
            "libcxx_hdrs": (
                "@llvm-project//libcxx:libcxx_hdrs",
                "runtimes/libcxx/",
            ),
            "libcxx_linux_srcs": (
                "@llvm-project//libcxx:libcxx_linux_srcs",
                "runtimes/libcxx/",
            ),
            "libcxx_macos_srcs": (
                "@llvm-project//libcxx:libcxx_macos_srcs",
                "runtimes/libcxx/",
            ),
            "libcxx_shared_headers_hdrs": (
                "@llvm-project//libc:libcxx_shared_headers_hdrs",
                "runtimes/libc/internal/",
            ),
            "libcxx_win32_srcs": (
                "@llvm-project//libcxx:libcxx_win32_srcs",
                "runtimes/libcxx/",
            ),
            "libcxxabi_hdrs": (
                "@llvm-project//libcxxabi:libcxxabi_hdrs",
                "runtimes/libcxxabi/",
            ),
            "libcxxabi_srcs": (
                "@llvm-project//libcxxabi:libcxxabi_srcs",
                "runtimes/libcxxabi/",
            ),
            "libcxxabi_textual_srcs": (
                "@llvm-project//libcxxabi:libcxxabi_textual_srcs",
                "runtimes/libcxxabi/",
            ),
            "libunwind_hdrs": (
                "@llvm-project//libunwind:libunwind_hdrs",
                "runtimes/libunwind/",
            ),
            "libunwind_srcs": (
                "@llvm-project//libunwind:libunwind_srcs",
                "runtimes/libunwind/",
            ),
            "prelude_files": ("//core:prelude_files", "core/"),
        }
        for name, (label, prefix) in runtimes_prefixes.items():
            subs[name.upper()] = runtimes_paths(label, prefix)
        with open(
            os.path.join(R, "toolchain/base/runtimes_build_vars.tpl.bzl"),
            encoding="utf-8",
        ) as fh:
            text = fh.read()
        for k, v in subs.items():
            text = text.replace(k, v)
        own = text.encode()
        # Fold after review 1 (R1-N3): bzl_eval flattens libc's aspect-collected
        # headers deps-then-own, which puts two lines (src/__support/CPP/
        # type_traits.h and utility.h) at other positions than Bazel's depset
        # order; bazel_graph.py (gen_ninja's evaluator) reproduces Bazel's order
        # byte for byte (NOTES-A). Take its bytes when both evaluators agree on
        # the content; a disagreement beyond line order is an evaluator bug and
        # stops the install.
        try:
            import bazel_graph as bg

            g = bg.Graph(
                repo=R,
                llvm_src=self.P["LLVM_SRC"],
                llvm_overlay=O,
                llvm_build=self.P["LLVM_BUILD"],
                build_mode=self.P.get("CARBON_BUILD_MODE") or "opt",
            )
            files = g.files_of(
                "//toolchain/install:bazel/runtimes_build_vars.bzl"
            )
            if len(files) != 1:
                raise bzl_eval.BzlError(
                    "expected one file, got %d" % len(files)
                )
            theirs = g.file_bytes(files[0])
        except Exception as e:  # noqa: BLE001 - any failure falls back to bzl_eval's text
            self.note(
                "runtimes_build_vars.bzl: bazel_graph.py unavailable (%s: %s); using bzl_eval's line order"
                % (type(e).__name__, e)
            )
            return own
        if sorted(theirs.splitlines()) != sorted(own.splitlines()):
            sys.exit(
                "install.py: bazel_graph.py and bzl_eval.py disagree on the content of "
                "bazel/runtimes_build_vars.bzl (not only on line order); fix the evaluators"
            )
        if theirs != own:
            self.note(
                "runtimes_build_vars.bzl: bazel_graph.py's bytes (Bazel depset order) used; "
                "bzl_eval's text differs only in line order"
            )
        return theirs

    def digest_manifest_lines(self, lib_carbon):
        return [os.path.join(lib_carbon, rel) for rel in self.digest_order]

    def gen_digest(self):
        raise RuntimeError(
            "gen_digest is run by Installer.install, not as a plain generator"
        )


class Installer:
    def __init__(self, P, plan):
        self.P = P
        self.plan = plan
        self.install_dir = P["INSTALL_DIR"]
        self.lib_carbon = os.path.join(self.install_dir, "lib", "carbon")

    def check_safe(self):
        arb = os.path.realpath(self.P["ARB"]) + os.sep
        for d in (self.install_dir, self.P["BUILD_DIR"]):
            if not (os.path.realpath(d) + os.sep).startswith(arb):
                sys.exit(
                    "refusing to write %s: not under ARB=%s"
                    % (d, self.P["ARB"])
                )
        if (
            os.path.realpath(self.install_dir) + os.sep
            == os.path.realpath(self.P["REPO"]) + os.sep
        ):
            sys.exit("INSTALL_DIR must not be REPO")

    def write_manifests(self):
        os.makedirs(self.P["BUILD_DIR"], exist_ok=True)
        with open(
            os.path.join(self.P["BUILD_DIR"], "clang_headers_manifest.txt"),
            "w",
            encoding="utf-8",
        ) as f:
            f.write("\n".join(self.plan.clang_hdrs_rel) + "\n")
        with open(
            os.path.join(self.P["BUILD_DIR"], "install_digest_manifest.txt"),
            "w",
            encoding="utf-8",
        ) as f:
            f.write(
                "\n".join(self.plan.digest_manifest_lines(self.lib_carbon))
                + "\n"
            )

    def install(self, allow_pending):
        self.check_safe()
        pending = [e for e in self.plan.entries if e.kind == "pending"]
        if pending and not allow_pending:
            for e in pending:
                print("pending: %s <- %s" % (e.rel, e.origin), file=sys.stderr)
            sys.exit(
                "the binaries above do not exist; build them (author A's build.sh) or pass --allow-pending"
            )
        for sub in ("bin", "lib"):
            d = os.path.join(self.install_dir, sub)
            if os.path.lexists(d):
                shutil.rmtree(d)
        os.makedirs(self.lib_carbon)
        os.makedirs(os.path.join(self.install_dir, "bin"))
        os.symlink(
            "../lib/carbon/carbon-busybox",
            os.path.join(self.install_dir, "bin", "carbon"),
        )
        n_copy = n_gen = n_link = 0
        for e in self.plan.entries:
            dst = os.path.join(self.lib_carbon, e.rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            if e.kind == "copy":
                shutil.copyfile(e.source, dst)
                if e.executable:
                    os.chmod(dst, 0o755)
                n_copy += 1
            elif e.kind == "gen" and e.rel != "install_digest.txt":
                with open(dst, "wb") as f:
                    f.write(e.gen())
                n_gen += 1
            elif e.kind == "symlink":
                os.symlink(e.target, dst)
                n_link += 1
        self.write_manifests()
        digest_entry = self.plan.by_rel["install_digest.txt"]
        if digest_entry.kind == "gen":
            manifest = os.path.join(
                self.P["BUILD_DIR"], "install_digest_manifest.txt"
            )
            env = dict(os.environ)
            env.pop("BUILD_WORKING_DIRECTORY", None)
            subprocess.run(
                [
                    self.P["DIGEST_BIN"],
                    manifest,
                    os.path.join(self.lib_carbon, "install_digest.txt"),
                ],
                check=True,
                env=env,
                cwd=self.lib_carbon,
            )
            n_gen += 1
        print(
            "installed %d copied, %d generated, %d symlinked files under %s%s"
            % (
                n_copy,
                n_gen,
                n_link,
                self.lib_carbon,
                "; PENDING: " + ", ".join(e.rel for e in pending)
                if pending
                else "",
            )
        )
        return 0 if not pending else 3


def compare_nightly(plan, nightly_dir):
    """List every path that differs between the plan and an extracted nightly."""
    want = set("lib/carbon/" + e.rel for e in plan.entries) | {"bin/carbon"}
    have = set()
    for dirpath, dirnames, filenames in os.walk(nightly_dir):
        for fn in filenames:
            p = os.path.join(dirpath, fn)
            if os.path.isfile(p) or os.path.islink(p):
                have.add(os.path.relpath(p, nightly_dir))
    only_mine = sorted(want - have)
    only_nightly = sorted(have - want)
    print(
        "compare with %s: %d paths in both, %d only here, %d only in the nightly"
        % (nightly_dir, len(want & have), len(only_mine), len(only_nightly))
    )
    for p in only_mine:
        print("  only here:    " + p)
    for p in only_nightly:
        print("  only nightly: " + p)
    return 0


def provenance(plan):
    groups = {}
    for e in plan.entries:
        g = groups.setdefault(e.group, {"n": 0, "origins": {}, "sample": e.rel})
        g["n"] += 1
        key = (
            re.sub(r"/[^/]*$", "/...", e.origin)
            if e.kind == "copy"
            else e.origin
        )
        g["origins"][key] = g["origins"].get(key, 0) + 1
    print(
        "| BUILD target | files | installed under lib/carbon | source / generator |"
    )
    print("| --- | --- | --- | --- |")
    for name, g in groups.items():
        rels = [e.rel for e in plan.entries if e.group == name]
        prefix = os.path.commonpath(rels) if len(rels) > 1 else rels[0]
        if len(rels) > 1 and prefix:
            prefix += "/"
        elif len(rels) > 1:
            prefix = "(top level)"
        origins = sorted(g["origins"].items(), key=lambda kv: -kv[1])
        desc = "; ".join(
            "%s (%d)" % (k, n) if n > 1 else k for k, n in origins[:3]
        )
        if len(origins) > 3:
            desc += "; ..."
        print("| `%s` | %d | `%s` | %s |" % (name, g["n"], prefix, desc))


def main():
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="list every file and its source; install nothing",
    )
    ap.add_argument(
        "--allow-pending",
        action="store_true",
        help="install without the busybox and the digest",
    )
    ap.add_argument(
        "--provenance", action="store_true", help="print the provenance table"
    )
    ap.add_argument(
        "--compare-nightly",
        metavar="DIR",
        help="compare the layout with an extracted nightly",
    )
    ap.add_argument("--paths", help="alternative paths.sh")
    args = ap.parse_args()
    P = load_paths(args.paths)
    for v in ("REPO", "LLVM_SRC", "LLVM_BUILD", "LLVM_OVERLAY"):
        if not os.path.isdir(P[v]):
            sys.exit("%s=%s is not a directory" % (v, P[v]))
    plan = Plan(P).build()
    if args.provenance:
        provenance(plan)
    if args.compare_nightly:
        compare_nightly(plan, args.compare_nightly)
    if args.dry_run or plan.problems:
        pending = []
        for e in plan.entries:
            if e.kind == "pending":
                pending.append(e)
                continue
            if args.dry_run:
                print(
                    "%-8s lib/carbon/%s <- %s"
                    % (
                        e.kind,
                        e.rel,
                        e.origin if e.kind != "symlink" else e.target,
                    )
                )
        if args.dry_run:
            print("bin/carbon -> ../lib/carbon/carbon-busybox")
            print(
                "BUILD_DIR/clang_headers_manifest.txt: %d lines"
                % len(plan.clang_hdrs_rel)
            )
            print(
                "BUILD_DIR/install_digest_manifest.txt: %d lines"
                % len(plan.digest_order)
            )
            clang_dir = os.path.join(
                P["LLVM_BUILD"], "lib", "clang", plan.llvm_major, "include"
            )
            print(
                "clang builtin headers dir %s: %s"
                % (
                    clang_dir,
                    "%d entries" % len(os.listdir(clang_dir))
                    if os.path.isdir(clang_dir)
                    else "ABSENT (clang-tblgen fallback)",
                )
            )
            kinds = {}
            for e in plan.entries:
                kinds[e.kind] = kinds.get(e.kind, 0) + 1
            print(
                "plan: %d entries: %s"
                % (
                    len(plan.entries),
                    ", ".join(
                        "%d %s" % (n, k) for k, n in sorted(kinds.items())
                    ),
                )
            )
        for e in pending:
            print("PENDING  lib/carbon/%s <- %s" % (e.rel, e.origin))
        for n in plan.notes:
            print("note: " + n)
        for p in plan.problems:
            print("ERROR: " + p, file=sys.stderr)
        if plan.problems:
            sys.exit("%d problem(s); nothing installed" % len(plan.problems))
        if args.dry_run:
            return 0
    if args.provenance or args.compare_nightly:
        return 0
    return Installer(P, plan).install(args.allow_pending)


if __name__ == "__main__":
    sys.exit(main())

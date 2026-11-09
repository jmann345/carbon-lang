#!/usr/bin/env python3
"""bzl_eval.py: evaluate Bazel BUILD/.bzl files as Python, enough to resolve
filegroups, without Bazel.

Part of the Carbon Language project fork's container arbiter (Bazel-free build
of the Carbon toolchain). Apache-2.0 WITH LLVM-exception.

Starlark's syntax is a subset of Python's, so a BUILD file can be `exec`ed
once every name it uses is bound: `glob`, `filegroup`, `genrule`, `select`,
`load`, and the rules loaded from .bzl files. Names this module does not model
are bound to a `Stub` that accepts any call, attribute, and `+ list`, so the
file evaluates to the end and the targets we care about (filegroups and their
sources) are recorded exactly.

Two users:

  - `Overlay` (LLVM's utils/bazel/llvm-project-overlay with Carbon's patches):
    `Overlay(overlay_dir, llvm_src).files_of("@llvm-project//libcxx:libcxx_hdrs")`
    returns the ordered, de-duplicated list of `File`s of that filegroup, the
    way `toolchain_files` in toolchain/install/install_filegroups.bzl sees
    `ctx.files.srcs`. Modelled rules: filegroup, alias, genrule (the
    compiler-rt `lse.S` outline-atomics pattern), gentbl_cc_library headers
    (clang's `lib/Headers/arm_*.h`, `riscv_vector.h`), compiler-rt.bzl's
    `make_filtered_builtins_srcs_groups`, and libc_build_rules.bzl's
    `libc_support_library` / `libc_header_library` family with the
    `LibcLibraryInfo` aspect closure that `<name>_hdrs` exports.
  - `eval_file(path, repo_root, ...)` for a Carbon BUILD or .bzl file, e.g. to
    read `LLVM_MAIN_TOOLS` from toolchain/base/llvm_tools.bzl or the
    `configure_cmake_file` defines from toolchain/runtimes/BUILD.

Every mismatch with Bazel's semantics that matters here is a loud failure
(`BzlError`), never a silent empty list.
"""

__copyright__ = """
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""

import ast
import os
import re
import sys
import types


class BzlError(Exception):
    pass


class Stub:
    """A value standing in for an unmodelled symbol (cc_binary, Label, ...)."""

    def __init__(self, name):
        self.name = name

    def __call__(self, *args, **kwargs):
        return Stub(self.name + "()")

    def __getattr__(self, attr):
        if attr.startswith("__"):
            raise AttributeError(attr)
        return Stub(self.name + "." + attr)

    def __add__(self, other):
        return other if isinstance(other, list) else Stub(self.name + "+")

    def __radd__(self, other):
        return other if isinstance(other, list) else Stub("+" + self.name)

    def __or__(self, other):
        return other if isinstance(other, dict) else Stub(self.name + "|")

    def __ror__(self, other):
        return other if isinstance(other, dict) else Stub("|" + self.name)

    def __iter__(self):
        return iter(())

    def __getitem__(self, key):
        return Stub(self.name + "[]")

    def __hash__(self):
        return hash(self.name)

    def __eq__(self, other):
        return isinstance(other, Stub) and other.name == self.name

    def __bool__(self):
        return True

    def __str__(self):
        return "<stub %s>" % self.name

    __repr__ = __str__


def select(d, no_match_error=None):
    """`select()`: the `//conditions:default` branch, else the first branch.

    toolchain/install/BUILD builds the install for the host (linux x86_64);
    every select we meet in the filegroup graph has a default branch or is
    irrelevant to files (defines, copts).
    """
    if not isinstance(d, dict):
        raise BzlError("select() of a non-dict: %r" % (d,))
    if "//conditions:default" in d:
        return d["//conditions:default"]
    for v in d.values():
        return v
    raise BzlError("select() of an empty dict")


class _Selects:
    """bazel_skylib's `selects`."""

    @staticmethod
    def with_or(d, no_match_error=None):
        return select(d)

    @staticmethod
    def config_setting_group(**kwargs):
        return None


def fail(msg="", *args, **kwargs):
    raise BzlError("fail(): %s" % (msg,))


def struct(**kwargs):
    return types.SimpleNamespace(**kwargs)


import builtins as _builtins_mod

_PY_BUILTINS = set(dir(_builtins_mod))


def _free_names(source):
    """Every name a module reads (candidates for stubs)."""
    tree = ast.parse(source)
    loaded = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Name) and not isinstance(node.ctx, ast.Store):
            loaded.add(node.id)
    return loaded


class _StarlarkToPython(ast.NodeTransformer):
    """The few places where Starlark and Python disagree in these files.

    `d.values()`, `d.keys()`, `d.items()` are lists in Starlark (so they can be
    concatenated with `+`), views in Python: wrap them in `list(...)`.
    """

    def visit_Call(self, node):
        self.generic_visit(node)
        if (
            isinstance(node.func, ast.Attribute)
            and node.func.attr in ("values", "keys", "items")
            and not node.args
            and not node.keywords
        ):
            return ast.Call(
                func=ast.Name(id="list", ctx=ast.Load()),
                args=[node],
                keywords=[],
            )
        return node


class Evaluator:
    """Evaluates BUILD/.bzl files of one repository root with stubs.

    `overrides` maps a loaded .bzl basename to {name: python object}; `load`
    binds those instead of evaluating the .bzl. Everything else loaded from a
    label inside `repo_root` is evaluated (recursively); labels of other
    repositories (`@...`) get stubs.
    """

    def __init__(self, repo_root, overrides=None, native=None, warn=None):
        self.repo_root = repo_root
        self.overrides = overrides or {}
        self.native = dict(native or {})
        self.warn = warn or (
            lambda msg: print("warning: " + msg, file=sys.stderr)
        )
        self._bzl_cache = {}
        self.base = {
            "select": select,
            "selects": _Selects,
            "fail": fail,
            "struct": struct,
            "Label": Stub("Label"),
            "native": Stub("native"),
        }

    # -- load() ------------------------------------------------------------
    def _bzl_path(self, label, from_dir):
        if label.startswith("@"):
            return None
        if label.startswith("//"):
            pkg, _, name = label[2:].partition(":")
            return os.path.join(self.repo_root, pkg, name) if name else None
        if label.startswith(":"):
            return os.path.join(from_dir, label[1:])
        return os.path.join(from_dir, label)

    def _load_module(self, label, from_dir):
        base = label.rsplit("/", 1)[-1].rsplit(":", 1)[-1]
        over = self.overrides.get(base, {})
        path = self._bzl_path(label, from_dir)
        mod = {}
        if path is not None and os.path.exists(path):
            if path not in self._bzl_cache:
                try:
                    self._bzl_cache[path] = self.eval_file(path)
                except Exception as e:  # noqa: BLE001 - fall back to stubs.
                    self.warn(
                        "could not evaluate %s (%s); using stubs" % (path, e)
                    )
                    self._bzl_cache[path] = {}
            mod = self._bzl_cache[path]
        return over, mod

    def _make_load(self, from_dir, env):
        def load(label, *names, **renames):
            over, mod = self._load_module(label, from_dir)
            # Precedence: per-file overrides, then our modelled natives (so a
            # `cc_library` loaded from @rules_cc or a `toolchain_files` whose
            # .bzl defines it as `rule(...)` resolves to our recorder), then
            # the evaluated module's own values, then a stub.
            for local, remote in list(zip(names, names)) + list(
                renames.items()
            ):
                if remote in over:
                    env[local] = over[remote]
                elif remote in self.native:
                    env[local] = self.native[remote]
                elif remote in mod and not isinstance(mod[remote], Stub):
                    env[local] = mod[remote]
                elif remote in self.base:
                    env[local] = self.base[remote]
                else:
                    env[local] = Stub(remote)

        return load

    # -- exec --------------------------------------------------------------
    def eval_file(self, path, extra=None):
        with open(path, encoding="utf-8") as f:
            source = f.read()
        env = {"__builtins__": __builtins__}
        env.update(self.base)
        env.update(self.native)
        if extra:
            env.update(extra)
        env["load"] = self._make_load(os.path.dirname(path), env)
        # Bind a stub for every name the file reads and we have not defined.
        # Names it also assigns are simply overwritten by the assignment.
        for name in _free_names(source):
            if name not in env and name not in _PY_BUILTINS:
                env[name] = Stub(name)
        tree = _StarlarkToPython().visit(ast.parse(source, path))
        ast.fix_missing_locations(tree)
        code = compile(tree, path, "exec")
        exec(code, env)  # noqa: S102 - trusted repository BUILD files.
        return env


# --------------------------------------------------------------------------
# Files and targets.


class File:
    """A file of a package: a source file or a generated one.

    `gen` is None for a source file (then `source` is its absolute path) or a
    dict describing how to produce it: {"type": "concat_echo", "lines": [...],
    "src": <File>} (the compiler-rt lse.S genrule) or {"type": "tblgen",
    "opts": [...], "td": <abs path>} (clang's generated headers).
    """

    __slots__ = ("pkg", "rel", "source", "gen", "origin")

    def __init__(self, pkg, rel, source=None, gen=None, origin=""):
        self.pkg = pkg
        self.rel = rel
        self.source = source
        self.gen = gen
        self.origin = origin

    @property
    def key(self):
        return (self.pkg, self.rel)

    @property
    def short_path(self):
        return self.pkg + "/" + self.rel

    @property
    def extension(self):
        base = self.rel.rsplit("/", 1)[-1]
        return base.rsplit(".", 1)[1] if "." in base else ""

    def __repr__(self):
        return "File(%s:%s%s)" % (
            self.pkg,
            self.rel,
            " gen" if self.gen else "",
        )


class Target:
    def __init__(self, kind, name, **attrs):
        self.kind = kind
        self.name = name
        self.attrs = attrs

    def __repr__(self):
        return "Target(%s %s)" % (self.kind, self.name)


def _glob_regex(pattern):
    """Bazel glob pattern -> regex. `**` = any number of path segments."""
    out = []
    i = 0
    while i < len(pattern):
        c = pattern[i]
        if pattern.startswith("**/", i):
            out.append("(?:[^/]+/)*")
            i += 3
        elif pattern.startswith("**", i):
            out.append(".*")
            i += 2
        elif c == "*":
            out.append("[^/]*")
            i += 1
        elif c == "?":
            out.append("[^/]")
            i += 1
        else:
            out.append(re.escape(c))
            i += 1
    return re.compile("^" + "".join(out) + "$")


def _dedup(files):
    seen = set()
    out = []
    for f in files:
        if f.key in seen:
            continue
        seen.add(f.key)
        out.append(f)
    return out


def _as_list(v, what):
    if isinstance(v, Stub):
        raise BzlError("%s is an unmodelled value %s" % (what, v))
    if v is None:
        return []
    if isinstance(v, (list, tuple)):
        for x in v:
            if isinstance(x, Stub):
                raise BzlError("%s contains an unmodelled value %s" % (what, x))
        return list(v)
    raise BzlError("%s is not a list: %r" % (what, v))


class Package:
    """One package of the overlay: the source dir plus the overlay BUILD."""

    def __init__(self, overlay, name):
        self.overlay = overlay
        self.name = name
        self.src_dir = os.path.join(overlay.llvm_src, name)
        self.build_dir = os.path.join(overlay.overlay_dir, name)
        self.targets = {}
        self.generated = {}  # rel path -> File
        self._files = None
        self.globals = None

    # -- the file list a glob() sees ---------------------------------------
    def _subpackage_dirs(self):
        subs = set()
        for root in (self.src_dir, self.build_dir):
            if not os.path.isdir(root):
                continue
            for dirpath, dirnames, filenames in os.walk(root):
                if dirpath == root:
                    continue
                if "BUILD" in filenames or "BUILD.bazel" in filenames:
                    subs.add(os.path.relpath(dirpath, root))
                    dirnames[:] = []
        return subs

    def files(self):
        if self._files is None:
            subs = self._subpackage_dirs()
            result = set()
            for root in (self.src_dir, self.build_dir):
                if not os.path.isdir(root):
                    continue
                for dirpath, dirnames, filenames in os.walk(root):
                    rel_dir = os.path.relpath(dirpath, root)
                    rel_dir = "" if rel_dir == "." else rel_dir
                    dirnames[:] = [
                        d
                        for d in sorted(dirnames)
                        if (rel_dir + "/" + d if rel_dir else d) not in subs
                    ]
                    for fn in filenames:
                        p = os.path.join(dirpath, fn)
                        if os.path.isfile(p):
                            result.add(rel_dir + "/" + fn if rel_dir else fn)
            self._files = sorted(result)
        return self._files

    def glob(
        self, include, exclude=None, exclude_directories=1, allow_empty=False
    ):
        include = _as_list(include, "glob include")
        exclude = _as_list(exclude or [], "glob exclude")
        inc = [_glob_regex(p) for p in include]
        exc = [_glob_regex(p) for p in exclude]
        out = [
            f
            for f in self.files()
            if any(r.match(f) for r in inc) and not any(r.match(f) for r in exc)
        ]
        if not out and not allow_empty:
            raise BzlError(
                "glob(%r, exclude=%r) in package %s matched nothing"
                % (include, exclude, self.name)
            )
        return out

    # -- recording rules ---------------------------------------------------
    def _record(self, kind, name, **attrs):
        if not isinstance(name, str):
            # A rule instantiated from an unmodelled macro's values (libc's
            # `libc_header_info(...)` structs); nothing we resolve can depend
            # on it, so it is skipped rather than recorded.
            return Target(kind, "<skipped>", **attrs)
        if name in self.targets and self.targets[name].kind != kind:
            raise BzlError("target %s:%s defined twice" % (self.name, name))
        self.targets[name] = Target(kind, name, **attrs)
        return self.targets[name]

    def native_rules(self):
        pkg = self

        def filegroup(name, srcs=None, **kwargs):
            pkg._record("filegroup", name, srcs=srcs or [])

        def alias(name, actual, **kwargs):
            pkg._record("alias", name, actual=actual)

        def genrule(name, outs, srcs=None, cmd="", **kwargs):
            t = pkg._record(
                "genrule", name, outs=outs, srcs=srcs or [], cmd=cmd
            )
            if isinstance(outs, (list, tuple)):
                for out in outs:
                    if isinstance(out, str):
                        pkg.generated[out] = ("genrule", t)

        def gentbl_cc_library(name, tbl_outs=None, td_file=None, **kwargs):
            # mlir/tblgen.bzl: tbl_outs is {out: [tblgen opts]} (or a list of
            # (opts, out) pairs in older versions). We only need the headers
            # it generates under lib/Headers.
            if isinstance(tbl_outs, dict):
                items = list(tbl_outs.items())
            elif isinstance(tbl_outs, (list, tuple)):
                items = [(o, opts) for (opts, o) in tbl_outs]
            else:
                items = []
            t = pkg._record(
                "gentbl", name, td_file=td_file, outs=[o for o, _ in items]
            )
            for out, opts in items:
                if isinstance(out, str) and isinstance(td_file, str):
                    pkg.generated[out] = ("tblgen", t, list(opts))

        def cc_library(
            name, hdrs=None, srcs=None, textual_hdrs=None, deps=None, **kw
        ):
            pkg._record(
                "cc_library",
                name,
                hdrs=hdrs or [],
                srcs=srcs or [],
                textual_hdrs=textual_hdrs or [],
                deps=deps or [],
            )

        def no_op(*args, **kwargs):
            return None

        return {
            "glob": pkg.glob,
            "filegroup": filegroup,
            "alias": alias,
            "genrule": genrule,
            "gentbl_cc_library": gentbl_cc_library,
            "cc_library": cc_library,
            "package": no_op,
            "licenses": no_op,
            "exports_files": no_op,
            "package_group": no_op,
            "config_setting": no_op,
            "toolchain_type": no_op,
            "toolchain": no_op,
        }

    def bzl_overrides(self):
        """Replacements for macros of the overlay's own .bzl files."""
        pkg = self

        # compiler-rt/compiler-rt.bzl
        def make_filtered_builtins_srcs_groups(name, srcs):
            if not name.endswith("_srcs"):
                raise BzlError(
                    "make_filtered_builtins_srcs_groups: bad name " + name
                )
            pkg._record("filtered_builtins_srcs", name, srcs=srcs)
            pkg._record(
                "filtered_builtins_textual_srcs",
                name[: -len("_srcs")] + "_textual_srcs",
                srcs=srcs,
            )

        # libc/libc_build_rules.bzl. Every libc_* rule is a cc_library whose
        # LibcLibraryInfo (aspect) is: deps' infos, then own srcs + hdrs.
        def libc_lib(
            name, hdrs=None, srcs=None, textual_hdrs=None, deps=None, **kwargs
        ):
            pkg._record(
                "cc_library",
                name,
                hdrs=hdrs or [],
                srcs=srcs or [],
                textual_hdrs=textual_hdrs or [],
                deps=deps or [],
            )

        def libc_math_function(name, additional_deps=None, **kwargs):
            pkg._record(
                "cc_library",
                name,
                hdrs=["src/math/" + name + ".h"],
                srcs=["src/math/generic/" + name + ".cpp"],
                textual_hdrs=[],
                deps=additional_deps or [],
            )

        def libc_header_library(name, hdrs, deps=None, **kwargs):
            # cc_library(name, hdrs, srcs=[":name_hdr_deps"] (= deps' closure),
            # deps=[":name_textual_hdr_library"] + libc_common_deps() (empty)).
            pkg._record(
                "cc_library",
                name,
                hdrs=hdrs,
                srcs=[],
                textual_hdrs=[],
                deps=deps or [],
            )
            # `<name>_hdrs`: _libc_srcs_filegroup(libs=[":name"],
            # enforce_headers_only=True).
            pkg._record(
                "libc_srcs_filegroup",
                name + "_hdrs",
                libs=[":" + name],
                headers_only=True,
            )

        def libc_generated_header(name, hdr, **kwargs):
            if not isinstance(name, str) or not isinstance(hdr, str):
                return
            t = pkg._record("libc_generated_header", name, hdr=hdr)
            pkg.generated[hdr] = ("libc_hdrgen", t)

        return {
            "compiler-rt.bzl": {
                "make_filtered_builtins_srcs_groups": make_filtered_builtins_srcs_groups,
            },
            "libc_build_rules.bzl": {
                "libc_support_library": libc_lib,
                "libc_startup_library": libc_lib,
                "libc_function": libc_lib,
                "libc_math_function": libc_math_function,
                "libc_header_library": libc_header_library,
                "libc_generated_header": libc_generated_header,
                "libc_common_copts": lambda: [],
                "libc_common_deps": lambda: [],
                "libc_release_copts": lambda: [],
                "libc_release_library": libc_lib,
            },
        }

    def load(self):
        if self.globals is not None:
            return
        build = None
        for name in ("BUILD.bazel", "BUILD"):
            if os.path.exists(os.path.join(self.build_dir, name)):
                build = os.path.join(self.build_dir, name)
                break
        if build is None:
            raise BzlError(
                "no BUILD.bazel/BUILD for package %s in %s"
                % (self.name, self.build_dir)
            )
        ev = Evaluator(
            self.overlay.overlay_dir,
            overrides=self.bzl_overrides(),
            native=self.native_rules(),
            warn=self.overlay.warn,
        )
        self.globals = ev.eval_file(build)

    # -- resolution --------------------------------------------------------
    def file(self, rel):
        """The File for a package-relative path: generated if declared, else a
        source file that must exist."""
        if rel in self.generated:
            kind = self.generated[rel][0]
            t = self.generated[rel][1]
            if kind == "genrule":
                return self._genrule_file(t, rel)
            if kind == "tblgen":
                opts = self.generated[rel][2]
                td = os.path.join(self.src_dir, t.attrs["td_file"])
                if not os.path.isfile(td):
                    raise BzlError("tblgen input %s for %s missing" % (td, rel))
                return File(
                    self.name,
                    rel,
                    gen={"type": "tblgen", "opts": opts, "td": td},
                    origin="clang-tblgen %s %s"
                    % (" ".join(opts), t.attrs["td_file"]),
                )
            raise BzlError(
                "generated file %s:%s (%s %s) has no generator model"
                % (self.name, rel, kind, t.name)
            )
        path = os.path.join(self.src_dir, rel)
        if not os.path.isfile(path):
            raise BzlError(
                "source file %s does not exist (package %s)" % (path, self.name)
            )
        return File(
            self.name,
            rel,
            source=path,
            origin="llvm-project/%s/%s" % (self.name, rel),
        )

    _ECHO_CAT_RE = re.compile(
        r"^\s*((?:echo '[^']*' >> \$\(OUTS\) && )+)cat \$\(SRCS\) >> \$\(OUTS\)\s*$"
    )

    def _genrule_file(self, t, rel):
        cmd = t.attrs["cmd"]
        m = self._ECHO_CAT_RE.match(cmd)
        if not m:
            raise BzlError(
                "genrule %s:%s has a cmd this tool does not model: %r"
                % (self.name, t.name, cmd)
            )
        lines = re.findall(r"echo '([^']*)' >> \$\(OUTS\)", m.group(1))
        srcs = _as_list(t.attrs["srcs"], "genrule %s srcs" % t.name)
        if len(srcs) != 1 or len(_as_list(t.attrs["outs"], "outs")) != 1:
            raise BzlError("genrule %s: expected one src and one out" % t.name)
        src = self.file(srcs[0])
        return File(
            self.name,
            rel,
            gen={"type": "concat_echo", "lines": lines, "src": src},
            origin="genrule %s: echo %s + cat %s"
            % (t.name, " ".join(repr(l) for l in lines), srcs[0]),
        )

    def files_of(self, label, _stack=()):
        """DefaultInfo.files of a label in this package (ordered, de-duplicated)."""
        self.load()
        if isinstance(label, Stub):
            raise BzlError("label is an unmodelled value %s" % label)
        if label.startswith("@") or label.startswith("//"):
            return self.overlay.files_of(label)
        name = label[1:] if label.startswith(":") else label
        if name not in self.targets:
            if label.startswith(":"):
                raise BzlError("no target %s:%s" % (self.name, name))
            return [self.file(name)]
        if name in _stack:
            raise BzlError("cycle at %s:%s" % (self.name, name))
        t = self.targets[name]
        stack = _stack + (name,)
        k = t.kind
        if k == "filegroup":
            out = []
            for s in _as_list(t.attrs["srcs"], "filegroup %s srcs" % name):
                out.extend(self.files_of(s, stack))
            return _dedup(out)
        if k == "alias":
            return self.files_of(t.attrs["actual"], stack)
        if k == "genrule":
            return [
                self._genrule_file(t, o)
                for o in _as_list(t.attrs["outs"], "outs")
            ]
        if k == "gentbl":
            return [self.file(o) for o in t.attrs["outs"]]
        if k in ("filtered_builtins_srcs", "filtered_builtins_textual_srcs"):
            inputs = []
            for s in _as_list(t.attrs["srcs"], "%s srcs" % name):
                inputs.extend(self.files_of(s, stack))
            inputs = _dedup(inputs)
            return self._filter_builtins(
                inputs, textual=(k == "filtered_builtins_textual_srcs")
            )
        if k == "libc_srcs_filegroup":
            out = []
            for lib in t.attrs["libs"]:
                out.extend(self.libc_info_srcs(lib, stack))
            out = _dedup(out)
            if t.attrs.get("headers_only"):
                bad = [f.short_path for f in out if f.extension != "h"]
                if bad:
                    raise BzlError(
                        "%s: unexpected non-header files: %s" % (name, bad)
                    )
            return out
        if k == "libc_generated_header":
            return [self.file(t.attrs["hdr"])]
        raise BzlError(
            "target %s:%s of kind %s is not a file provider"
            % (self.name, name, k)
        )

    @staticmethod
    def _builtins_rel(f):
        rel = f.short_path.rpartition("/lib/builtins/")[2]
        if rel == f.short_path:
            raise BzlError("expected '/lib/builtins/' in path " + f.short_path)
        return rel

    def _filter_builtins(self, files, textual):
        """compiler-rt.bzl `_filtered_builtins_srcs_impl` /
        `_filtered_builtins_textual_srcs_impl`."""
        if textual:
            return [f for f in files if f.extension in ("inc", "def")]
        overrides = set()
        for f in files:
            rel = self._builtins_rel(f)
            if "/" in rel:
                base = rel.rpartition("/")[2]
                if base.endswith(".S"):
                    base = base[: -len(".S")] + ".c"
                overrides.add(base)
        out = []
        for f in files:
            rel = self._builtins_rel(f)
            if "/" not in rel and rel in overrides:
                continue
            out.append(f)
        return [f for f in out if f.extension not in ("inc", "def")]

    def libc_info_srcs(self, label, _stack=()):
        """LibcLibraryInfo.srcs of a rule target: deps' infos in order, then the
        files of its own srcs and hdrs (libc_build_rules.bzl
        `_get_libc_info_aspect_impl`)."""
        self.load()
        if label.startswith("@") or label.startswith("//"):
            raise BzlError(
                "libc aspect across packages is not modelled: " + label
            )
        name = label[1:] if label.startswith(":") else label
        t = self.targets.get(name)
        if t is None:
            raise BzlError("libc aspect: no target %s:%s" % (self.name, name))
        if t.kind != "cc_library":
            # A non-rule dep (filegroup etc.) carries no LibcLibraryInfo.
            return []
        if name in _stack:
            raise BzlError("libc dependency cycle at " + name)
        stack = _stack + (name,)
        out = []
        for dep in _as_list(t.attrs["deps"], "%s deps" % name):
            out.extend(self.libc_info_srcs(dep, stack))
        for s in _as_list(t.attrs["srcs"], "%s srcs" % name) + _as_list(
            t.attrs["hdrs"], "%s hdrs" % name
        ):
            out.extend(self.files_of(s, stack))
        return _dedup(out)


class Overlay:
    """LLVM's Bazel overlay applied to an llvm-project source tree."""

    def __init__(self, overlay_dir, llvm_src, warn=None):
        self.overlay_dir = overlay_dir
        self.llvm_src = llvm_src
        self.warn = warn or (
            lambda msg: print("warning: " + msg, file=sys.stderr)
        )
        self.packages = {}

    def package(self, name):
        if name not in self.packages:
            self.packages[name] = Package(self, name)
        return self.packages[name]

    @staticmethod
    def split_label(label):
        """'@llvm-project//compiler-rt:builtins_x86_64_srcs' -> ('compiler-rt', ':builtins_x86_64_srcs')."""
        if label.startswith("@"):
            label = label[label.index("//") :]
        if not label.startswith("//"):
            raise BzlError("expected an absolute label: " + label)
        pkg, sep, name = label[2:].partition(":")
        if not sep:
            name = pkg.rsplit("/", 1)[-1]
        return pkg, ":" + name

    def files_of(self, label):
        pkg, name = self.split_label(label)
        return self.package(pkg).files_of(name)

    def global_value(self, pkg, name):
        """A module-level variable of a package's BUILD.bazel (e.g. clang's
        `builtin_headers`)."""
        p = self.package(pkg)
        p.load()
        v = p.globals.get(name)
        if v is None or isinstance(v, Stub):
            raise BzlError("%s/BUILD.bazel has no usable `%s`" % (pkg, name))
        return v


def eval_file(path, repo_root, overrides=None, native=None, warn=None):
    """Evaluate one Carbon BUILD/.bzl file; returns its globals."""
    recorder = _Recorder()
    nat = dict(recorder.rules())
    nat.update(native or {})
    ev = Evaluator(repo_root, overrides=overrides or {}, native=nat, warn=warn)
    g = ev.eval_file(path)
    g["__targets__"] = recorder.targets
    return g


class _Recorder:
    """Records every rule call `name(...)` of a Carbon BUILD file by kind."""

    def __init__(self):
        self.targets = []  # (kind, kwargs)

    def rules(self):
        rec = self

        def make(kind):
            def rule(*args, **kwargs):
                rec.targets.append((kind, kwargs))

            return rule

        names = [
            "filegroup",
            "genrule",
            "manifest",
            "toolchain_files",
            "configure_cmake_file",
            "cc_library",
            "cc_binary",
            "cc_test",
            "py_binary",
            "py_test",
            "exports_files",
            "package",
            "licenses",
            "config_setting",
            "alias",
            "filtered_toolchain_files",
            "toolchain_llvm_binaries",
            "toolchain_pkg_filegroup",
            "pkg_tar_and_test",
            "pkg_naming_variables",
            "generate_runtimes_build_vars",
            "carbon_prelude",
            "carbon_runtimes_config",
            "carbon_bootstrapped_cc_toolchain",
            "filegroup_with_stage",
            "gen_cc_toolchain_paths_with_stage",
            "carbon_library",
            "file_test",
            "manifest_as_cpp",
        ]
        d = {n: make(n) for n in names}
        d["glob"] = lambda *a, **k: Stub("glob")
        return d


if __name__ == "__main__":
    # Debug helper: bzl_eval.py OVERLAY_DIR LLVM_SRC LABEL...
    overlay = Overlay(sys.argv[1], sys.argv[2])
    for lbl in sys.argv[3:]:
        files = overlay.files_of(lbl)
        print("%s: %d files" % (lbl, len(files)))
        for f in files:
            print(
                "  %s%s"
                % (f.short_path, "  [gen: %s]" % f.origin if f.gen else "")
            )

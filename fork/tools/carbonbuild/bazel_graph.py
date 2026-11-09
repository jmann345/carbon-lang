#!/usr/bin/env python3
"""bazel_graph.py: evaluate Carbon's Bazel BUILD graph without Bazel (stdlib only).

The BUILD files and the .bzl files they load are executed as Python (Starlark is a
Python subset) in a namespace of stand-ins for Bazel's builtins: load(), glob()
with Bazel semantics, select() resolved for one fixed configuration (linux
x86_64, `-c opt`, not a runtimes build, bootstrap stage 0, --nostamp), rule(),
attr.*, provider(), depset, Label, native, struct, ... Custom rules (manifest,
toolchain_files, filtered_builtins_srcs, generate_runtimes_build_info_h,
expand_version_build_info, ...) are reproduced by running their real
implementation functions against a fake `ctx`, so their outputs are the ones
Bazel would produce as long as the fake File/depset semantics are right (see
File, Depset and the notes in NOTES-A.md).

Shared by gen_ninja.py (author A) and install.py (author C).

API
---
    import bazel_graph as bg
    g = bg.Graph(repo=REPO, llvm_src=LLVM_SRC, llvm_overlay=LLVM_OVERLAY,
                 llvm_build=LLVM_BUILD, build_mode="opt",
                 llvm_symbolizer="/path/to/llvm-symbolizer")

    t = g.target("//toolchain/install:carbon-busybox")   # Target (loads the package)
    files = g.files_of("//toolchain/install:all_data_files")  # list[File], Bazel order
    text = g.manifest_text("//core:prelude_manifest.txt")     # str, byte-exact manifest
    text = g.manifest_text("//toolchain/testing:file_test_autogen_manifest.cpp")
    data = g.file_bytes(f)                 # bytes of any File: source, written, templated,
                                           # symlink (follows), genrule (known patterns),
                                           # or ctx.actions.run (runs the real tool)
    g.transitive_runfiles(label)           # list[File]: data deps closure of a binary
    g.cc_closure([labels])                 # list[CcNode] topologically sorted
    g.resolve(value, package_label)        # resolve select() values
    g.install_relative_path(f)             # 'core/prelude.carbon' for a //toolchain/install output
    g.symlink_chain_end(f)                 # the File whose bytes a symlink output carries
    g.action_command(f)                    # (tool path, args, inputs) of a ctx.actions.run output

Command line (for inspection):  python3 -I bazel_graph.py files <label> | manifest <label> |
    bytes <label> | install-list   (reads paths.sh through paths.py)

File
----
    f.path         Bazel exec path ("toolchain/x/y.h", "bazel-out/k8-opt/bin/..." for
                   generated files, "external/<canonical repo>/..." for external ones)
    f.short_path   runfiles path (external: "../<canonical repo>/...")
    f.owner        Label of the source file / generating rule;  f.root.path  "" or bin dir
    f.is_source    True for checked-in files;  f.real_path  absolute path on disk (sources)
    f.generator    Target that declares it (generated files)
    f.symlink_target  File a toolchain_files/run_tool symlink points at
    f.content      bytes written at analysis time (ctx.actions.write / expand_template)
    f.action       Action(executable File, arguments, inputs) for ctx.actions.run outputs

Generated files and how `file_bytes` reproduces them:
    ctx.actions.write / expand_template   -> content computed by the real rule code
    ctx.actions.symlink                    -> bytes of the target file
    ctx.actions.run (gen_tmpl.py, configure_cmake_file_impl.py) -> the real python tool
                                              is executed with the real argument list
    genrule: compiler-rt outline_atomic_* (echo+cat), toolchain/install
             carbon_cc_toolchain_config_for_install (sed) and clang builtin_headers_gen
             (copy) are interpreted; gen_digest (runs make-installation-digest) is not:
             install.py runs the built tool itself.
    @llvm-project//clang:builtin_headers_gen inputs that Bazel generates with
             clang-tblgen (arm_neon.h, ...) are taken from LLVM_BUILD/lib/clang/<MAJOR>/include.

Fixed configuration (see Graph.condition_true): @platforms//os:linux and
@platforms//cpu:x86_64 hold; config_settings are evaluated from their
constraint_values / flag_values (against the flags' build_setting_default) /
values ({compilation_mode: opt} holds, {stamp: 1} does not) / define_values
(absl=1, pfm=1 hold).
"""

__copyright__ = """
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""

import ast
import os
import posixpath
import re
import subprocess
import sys
import tempfile

BIN_DIR = "bazel-out/k8-opt/bin"

# Apparent repo name -> canonical (bzlmod) repo name as it appears in exec paths.
CANONICAL_REPO = {
    "": "",
    "llvm-project": "+llvm_project+llvm-project",
    "abseil-cpp": "abseil-cpp+",
    "googletest": "googletest+",
    "re2": "re2+",
    "boost.unordered": "boost.unordered+",
    "bazel_tools": "bazel_tools",
    "platforms": "platforms+",
    "rules_cc": "rules_cc+",
    "bazel_skylib": "bazel_skylib+",
    "rules_python": "rules_python+",
    "rules_pkg": "rules_pkg+",
    "rules_shell": "rules_shell+",
    "google_benchmark": "google_benchmark+",
    "bazel_cc_toolchain": "+clang_toolchain_extension+bazel_cc_toolchain",
}

# Packages of @llvm-project whose BUILD.bazel we never evaluate (we link the CMake
# libraries instead); labels there become ExternalCcTarget / ToolLibTarget.
LLVM_LIB_PACKAGES = ("llvm", "clang", "lld")


class StarlarkError(Exception):
    pass


def fail(msg="", *args, **kwargs):
    raise StarlarkError("fail(): " + " ".join(str(a) for a in (msg,) + args))


# --------------------------------------------------------------------------- Label


class Label:
    __slots__ = ("repo", "package", "name")

    def __init__(self, repo, package, name):
        self.repo = repo
        self.package = package
        self.name = name

    @staticmethod
    def parse(s, cur_repo, cur_pkg):
        if isinstance(s, Label):
            return s
        if not isinstance(s, str):
            raise StarlarkError("not a label: %r" % (s,))
        repo = cur_repo
        if s.startswith("@"):
            rest = s.lstrip("@")
            if "//" in rest:
                repo, rest = rest.split("//", 1)
                s = "//" + rest
            else:
                repo = rest
                s = "//:" + rest
            repo = _apparent_repo(repo)
        if s.startswith("//"):
            rest = s[2:]
            if ":" in rest:
                pkg, name = rest.split(":", 1)
            else:
                pkg = rest
                name = rest.rsplit("/", 1)[-1]
        elif s.startswith(":"):
            pkg, name = cur_pkg, s[1:]
        else:
            pkg, name = cur_pkg, s
        return Label(repo, pkg, name)

    @property
    def workspace_root(self):
        return (
            ""
            if self.repo == ""
            else "external/" + CANONICAL_REPO.get(self.repo, self.repo + "+")
        )

    @property
    def workspace_name(self):
        return (
            "_main"
            if self.repo == ""
            else CANONICAL_REPO.get(self.repo, self.repo + "+")
        )

    @property
    def repo_name(self):
        return self.workspace_name

    def relative(self, s):
        return Label.parse(s, self.repo, self.package)

    def same_package_label(self, name):
        return Label(self.repo, self.package, name)

    def __str__(self):
        base = "//%s:%s" % (self.package, self.name)
        return ("@" + self.repo + base) if self.repo else base

    __repr__ = __str__

    def __eq__(self, other):
        return isinstance(other, Label) and (
            self.repo,
            self.package,
            self.name,
        ) == (other.repo, other.package, other.name)

    def __hash__(self):
        return hash((self.repo, self.package, self.name))


def _apparent_repo(repo):
    if repo in CANONICAL_REPO:
        return repo
    for apparent, canonical in CANONICAL_REPO.items():
        if canonical == repo:
            return apparent
    return repo.rstrip("+")


# ---------------------------------------------------------------------------- File


class Root:
    __slots__ = ("path",)

    def __init__(self, path):
        self.path = path


SOURCE_ROOT = Root("")
BIN_ROOT = Root(BIN_DIR)


class File:
    def __init__(self, graph, owner, relpath, is_source, generator=None):
        self.graph = graph
        self.owner = owner
        self.is_source = is_source
        self.root = SOURCE_ROOT if is_source else BIN_ROOT
        self.generator = generator
        self.symlink_target = None
        self.content = None
        self.action = None
        self.real_path_override = None
        pkg_rel = (owner.package + "/" if owner.package else "") + relpath
        ws = owner.workspace_root
        exec_rel = (ws + "/" if ws else "") + pkg_rel
        self.path = exec_rel if is_source else BIN_DIR + "/" + exec_rel
        self.short_path = (
            "../" + owner.workspace_name + "/" if owner.repo else ""
        ) + pkg_rel
        self.basename = posixpath.basename(self.path)
        self.dirname = posixpath.dirname(self.path)
        self.extension = (
            self.basename.rsplit(".", 1)[1] if "." in self.basename else ""
        )
        self.pkg_rel = pkg_rel
        self.relpath = relpath

    @property
    def real_path(self):
        if self.real_path_override:
            return self.real_path_override
        if self.is_source:
            return os.path.join(
                self.graph.source_root(self.owner.repo), self.pkg_rel
            )
        return None

    def __eq__(self, other):
        return isinstance(other, File) and self.path == other.path

    def __hash__(self):
        return hash(self.path)

    def __repr__(self):
        return "File(%s)" % self.path


# -------------------------------------------------------------------------- Depset


class Depset:
    def __init__(self, direct=None, transitive=None, order="default"):
        items = []
        seen = set()
        for x in direct or []:
            if x not in seen:
                seen.add(x)
                items.append(x)
        for t in transitive or []:
            for x in t.to_list():
                if x not in seen:
                    seen.add(x)
                    items.append(x)
        self._items = items

    def to_list(self):
        return list(self._items)

    def __len__(self):
        return len(self._items)

    def __repr__(self):
        return "depset(%r)" % (self._items,)


def depset(direct=None, order="default", transitive=None):
    if isinstance(direct, Depset):
        return direct
    return Depset(direct, transitive, order)


class Runfiles:
    def __init__(self, files=None, transitive_files=None):
        self.files = Depset(
            files or [], [transitive_files] if transitive_files else None
        )

    def merge(self, other):
        return Runfiles(self.files.to_list() + other.files.to_list())

    def merge_all(self, others):
        r = self
        for o in others:
            r = r.merge(o)
        return r


# ------------------------------------------------------------------------ providers


class ProviderClass:
    def __init__(self, name, fields=None, init=None):
        self.name = name
        self.fields = fields

    def __call__(self, **kwargs):
        return ProviderInstance(self, kwargs)

    def __repr__(self):
        return "<provider %s>" % self.name


class ProviderInstance:
    def __init__(self, cls, kwargs):
        self.__dict__["_cls"] = cls
        self.__dict__["_fields"] = dict(kwargs)

    def __getattr__(self, name):
        try:
            return self.__dict__["_fields"][name]
        except KeyError:
            raise AttributeError(name)

    def __repr__(self):
        return "%s(%r)" % (self._cls.name, self._fields)


def provider(doc="", fields=None, init=None, **kwargs):
    cls = ProviderClass("provider", fields)
    if init is not None:
        return cls, cls
    return cls


class DefaultInfoClass(ProviderClass):
    def __init__(self):
        super().__init__("DefaultInfo")

    def __call__(
        self,
        files=None,
        runfiles=None,
        data_runfiles=None,
        default_runfiles=None,
        executable=None,
    ):
        files = files if files is not None else Depset()
        rf = runfiles or default_runfiles or Runfiles()
        return ProviderInstance(
            self,
            dict(
                files=files,
                default_runfiles=rf,
                data_runfiles=data_runfiles or rf,
                executable=executable,
            ),
        )


DefaultInfo = DefaultInfoClass()
OutputGroupInfo = ProviderClass("OutputGroupInfo")
RunEnvironmentInfo = ProviderClass("RunEnvironmentInfo")
CcInfo = ProviderClass("CcInfo")
BuildSettingInfo = ProviderClass("BuildSettingInfo")
PackageVariablesInfo = ProviderClass("PackageVariablesInfo")
ConfigSettingInfo = ProviderClass("ConfigSettingInfo")
ToolLibInfo = ProviderClass("ToolLibInfo")


# ----------------------------------------------------------------------- Starlark bits


class Struct:
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)

    def __repr__(self):
        return "struct(%s)" % ", ".join(
            "%s = %r" % kv for kv in sorted(self.__dict__.items())
        )

    def __eq__(self, other):
        return isinstance(other, Struct) and self.__dict__ == other.__dict__


class PermissiveStruct:
    """Attribute access returns the attribute's name (ACTION_NAMES) or a list of it."""

    def __init__(self, as_list=False):
        self._as_list = as_list

    def __getattr__(self, name):
        if name.startswith("__"):
            raise AttributeError(name)
        return [name] if self._as_list else name


class Permissive:
    """A callable/attribute sink: any call returns a Struct of its arguments."""

    def __init__(self, name="permissive"):
        self._name = name

    def __call__(self, *args, **kwargs):
        return Struct(_args=list(args), **kwargs)

    def __getattr__(self, name):
        if name.startswith("__"):
            raise AttributeError(name)
        return Permissive(self._name + "." + name)


class Select:
    def __init__(self, mapping, no_match_error=""):
        self.mapping = dict(mapping)
        self.no_match_error = no_match_error

    def __add__(self, other):
        return SelectConcat([self, other], "+")

    def __radd__(self, other):
        return SelectConcat([other, self], "+")

    def __or__(self, other):
        return SelectConcat([self, other], "|")

    def __ror__(self, other):
        return SelectConcat([other, self], "|")

    def __repr__(self):
        return "select(%r)" % (self.mapping,)


class SelectConcat:
    def __init__(self, parts, op):
        self.parts = parts
        self.op = op

    def __add__(self, other):
        return SelectConcat([self, other], "+")

    def __radd__(self, other):
        return SelectConcat([other, self], "+")

    def __or__(self, other):
        return SelectConcat([self, other], "|")

    def __ror__(self, other):
        return SelectConcat([other, self], "|")


def select(mapping, no_match_error=""):
    return Select(mapping, no_match_error)


def starlark_type(x):
    if isinstance(x, bool):
        return "bool"
    if isinstance(x, int):
        return "int"
    if isinstance(x, str):
        return "string"
    if isinstance(x, list):
        return "list"
    if isinstance(x, tuple):
        return "tuple"
    if isinstance(x, dict):
        return "dict"
    if x is None:
        return "NoneType"
    if isinstance(x, Label):
        return "Label"
    if isinstance(x, Depset):
        return "depset"
    if isinstance(x, Struct):
        return "struct"
    if isinstance(x, (Select, SelectConcat)):
        return "select"
    if callable(x):
        return "function"
    return type(x).__name__


class AttrSpec:
    def __init__(self, kind, **kwargs):
        self.kind = kind
        self.default = kwargs.get("default")
        self.allow_single_file = kwargs.get("allow_single_file", False)
        self.executable = kwargs.get("executable", False)
        self.aspects = kwargs.get("aspects", []) or []
        self.mandatory = kwargs.get("mandatory", False)
        self.kwargs = kwargs


class _Attr:
    def __getattr__(self, kind):
        if kind.startswith("__"):
            raise AttributeError(kind)

        def make(*args, **kwargs):
            if args and "default" not in kwargs:
                kwargs["default"] = args[0]
            return AttrSpec(kind, **kwargs)

        return make


attr = _Attr()


class RuleClass:
    def __init__(
        self,
        graph,
        module_label,
        implementation=None,
        attrs=None,
        executable=False,
        test=False,
        outputs=None,
        **kwargs,
    ):
        self.graph = graph
        self.module_label = module_label
        self.implementation = implementation
        self.attrs = dict(attrs or {})
        self.executable = executable
        self.test = test
        self.outputs = outputs
        self.kind = (
            implementation.__name__ if implementation is not None else "rule"
        )

    def __call__(self, **kwargs):
        return self.graph.record_target(self.kind, kwargs, rule_class=self)

    def __repr__(self):
        return "<rule %s>" % self.kind


class AspectDef:
    def __init__(self, implementation, attr_aspects=None, attrs=None, **kwargs):
        self.implementation = implementation
        self.attr_aspects = list(attr_aspects or [])
        self.attrs = attrs or {}


class Transition:
    def __init__(self, **kwargs):
        pass


class Action:
    def __init__(self, executable, arguments, inputs, command=None):
        self.executable = executable
        self.arguments = list(arguments)
        self.inputs = list(inputs)
        self.command = command


# Native rule attribute schemas (name -> kind).
LABEL_LIST = "label_list"
NATIVE_SCHEMAS = {
    "filegroup": {"srcs": LABEL_LIST, "data": LABEL_LIST},
    "genrule": {
        "srcs": LABEL_LIST,
        "outs": "output_list",
        "tools": LABEL_LIST,
        "exec_tools": LABEL_LIST,
        "toolchains": LABEL_LIST,
    },
    "alias": {"actual": "label"},
    "config_setting": {
        "constraint_values": LABEL_LIST,
        "flag_values": "label_keyed_string_dict",
    },
    "config_setting_group": {"match_any": LABEL_LIST, "match_all": LABEL_LIST},
    "cc_library": {
        "srcs": LABEL_LIST,
        "hdrs": LABEL_LIST,
        "textual_hdrs": LABEL_LIST,
        "deps": LABEL_LIST,
        "implementation_deps": LABEL_LIST,
        "data": LABEL_LIST,
        "additional_linker_inputs": LABEL_LIST,
    },
    "cc_binary": {
        "srcs": LABEL_LIST,
        "deps": LABEL_LIST,
        "data": LABEL_LIST,
        "additional_linker_inputs": LABEL_LIST,
        "dynamic_deps": LABEL_LIST,
    },
    "cc_test": {
        "srcs": LABEL_LIST,
        "deps": LABEL_LIST,
        "data": LABEL_LIST,
        "additional_linker_inputs": LABEL_LIST,
        "dynamic_deps": LABEL_LIST,
    },
    "py_binary": {
        "srcs": LABEL_LIST,
        "deps": LABEL_LIST,
        "data": LABEL_LIST,
        "main": "label",
    },
    "py_test": {
        "srcs": LABEL_LIST,
        "deps": LABEL_LIST,
        "data": LABEL_LIST,
        "main": "label",
    },
    "py_library": {"srcs": LABEL_LIST, "deps": LABEL_LIST, "data": LABEL_LIST},
    "sh_test": {"srcs": LABEL_LIST, "deps": LABEL_LIST, "data": LABEL_LIST},
    "sh_binary": {"srcs": LABEL_LIST, "deps": LABEL_LIST, "data": LABEL_LIST},
    "toolchain": {"toolchain": "label", "toolchain_type": "label"},
    "cc_toolchain": {},
    "cc_toolchain_suite": {},
    "test_suite": {"tests": LABEL_LIST},
    "bool_flag": {},
    "int_flag": {},
    "string_flag": {},
    "bool_setting": {},
    "int_setting": {},
    "string_setting": {},
    "pkg_tar": {"srcs": LABEL_LIST, "deps": LABEL_LIST},
    "pkg_files": {"srcs": LABEL_LIST},
    "pkg_filegroup": {"srcs": LABEL_LIST},
    "pkg_mklink": {},
}
GENERIC_LABEL_LIST_ATTRS = (
    "srcs",
    "hdrs",
    "textual_hdrs",
    "deps",
    "data",
    "tools",
    "tests",
    "implementation_deps",
)
# Attributes rules_cc 0.2.25 declares with flags = ["ORDER_INDEPENDENT"] (cc/private/rules_impl):
# their label lists are sorted by Bazel when the rule is instantiated. `srcs`, `deps`
# and `data` are not, nor is any attribute of a Starlark rule such as filegroup/toolchain_files.
ORDER_INDEPENDENT_ATTRS = {
    "cc_library": {
        "hdrs",
        "textual_hdrs",
        "additional_linker_inputs",
        "additional_compiler_inputs",
    },
    "cc_binary": {"additional_linker_inputs"},
    "cc_test": {"additional_linker_inputs"},
}


class Target:
    def __init__(
        self, graph, label, kind, kwargs, rule_class=None, package_label=None
    ):
        self.graph = graph
        self.label = label
        self.kind = kind
        self.kwargs = kwargs
        self.rule_class = rule_class
        self.package_label = package_label or Label(
            label.repo, label.package, "BUILD"
        )
        self.providers = None
        self._attr_cache = {}
        self._aspects = {}

    # Starlark-visible API used by rule implementations.
    def __getitem__(self, prov):
        self.graph.analyze(self)
        try:
            return self.providers[prov]
        except KeyError:
            raise StarlarkError("%s has no provider %r" % (self.label, prov))

    def __contains__(self, prov):
        self.graph.analyze(self)
        return prov in self.providers

    @property
    def files(self):
        return self[DefaultInfo].files

    @property
    def default_runfiles(self):
        return self[DefaultInfo].default_runfiles

    def __repr__(self):
        return "<target %s (%s)>" % (self.label, self.kind)

    # Attribute access helpers.
    def raw(self, name, default=None):
        return self.kwargs.get(name, default)

    def attr_kind(self, name):
        if self.rule_class is not None:
            spec = self.rule_class.attrs.get(name)
            if spec is not None:
                return spec.kind
            return None
        schema = NATIVE_SCHEMAS.get(self.kind)
        if schema is not None and name in schema:
            return schema[name]
        if name in GENERIC_LABEL_LIST_ATTRS:
            return LABEL_LIST
        if name == "out":
            return "output"
        return None

    def attr(self, name):
        """Resolved attribute: labels -> Targets, selects resolved, defaults applied."""
        if name in self._attr_cache:
            return self._attr_cache[name]
        g = self.graph
        kind = self.attr_kind(name)
        if name in self.kwargs:
            value = g.resolve(self.kwargs[name], self.package_label)
            value = _resolve_dict_keys_strs(value)
            default_pkg = self.package_label
        else:
            spec = self.rule_class.attrs.get(name) if self.rule_class else None
            if spec is None:
                value = None
            else:
                value = g.resolve(spec.default, self.rule_class.module_label)
            default_pkg = (
                self.rule_class.module_label
                if self.rule_class
                else self.package_label
            )
        if kind == "label":
            value = g.target(value, default_pkg) if value is not None else None
        elif kind == LABEL_LIST:
            value = [g.target(v, default_pkg) for v in (value or [])]
            if (
                self.kind in ORDER_INDEPENDENT_ATTRS
                and name in ORDER_INDEPENDENT_ATTRS[self.kind]
            ):
                # rules_cc marks these attrs ORDER_INDEPENDENT: Bazel sorts the labels
                # at loading time (BuildType.convertFromBuildLangType).
                value = sorted(
                    value,
                    key=lambda t: (
                        t.label.workspace_name,
                        t.label.package,
                        t.label.name,
                    ),
                )
        elif kind == "output":
            value = self.output_file(value) if value else None
        elif kind == "output_list":
            value = [self.output_file(v) for v in (value or [])]
        elif kind == "label_keyed_string_dict":
            value = {
                g.target(k, default_pkg): v for k, v in (value or {}).items()
            }
        elif kind == "string_dict" and value is None:
            value = {}
        self._attr_cache[name] = value
        return value

    def output_file(self, name):
        return self.graph.declared_file(self, name)


def _resolve_dict_keys_strs(value):
    return value


class FileTarget(Target):
    def __init__(self, graph, label, file):
        super().__init__(graph, label, "file", {})
        self.file = file
        self.providers = {DefaultInfo: DefaultInfo(files=Depset([file]))}

    def __repr__(self):
        return "<file %s>" % self.file.path


class ExternalCcTarget(Target):
    """A prebuilt external library (abseil, gtest, re2, boost, runfiles, LLVM archives)."""

    def __init__(self, graph, label, group):
        super().__init__(graph, label, "external_cc", {})
        self.group = group
        self.providers = {DefaultInfo: DefaultInfo(files=Depset())}


class ToolLibTarget(Target):
    """An @llvm-project tool library (llvm-ar-lib, clang-driver) we compile from source."""

    def __init__(self, graph, label, tool_dir, srcs, tablegen):
        super().__init__(graph, label, "tool_lib", {})
        self.tool_dir = (
            tool_dir  # relative to LLVM_SRC, e.g. llvm/tools/llvm-ar
        )
        self.srcs = srcs  # list[File] (sources under LLVM_SRC)
        self.tablegen = tablegen  # list of (td relpath, inc name)
        self.providers = {DefaultInfo: DefaultInfo(files=Depset())}


class Package:
    def __init__(self, repo, name, build_file):
        self.repo = repo
        self.name = name
        self.build_file = build_file
        self.targets = {}
        self.outputs = {}  # declared output file name -> (Target, attr or None)
        self.declared = {}  # File.pkg_rel -> File for files declared by analysis
        self.exported = set()

    @property
    def label(self):
        return Label(self.repo, self.name, "BUILD")


class AspectView:
    """A dep as seen through an aspect: the target's providers plus the aspect's."""

    def __init__(self, target, extra):
        self.target = target
        self.extra = extra

    def __getitem__(self, prov):
        if prov in self.extra:
            return self.extra[prov]
        return self.target[prov]

    def __contains__(self, prov):
        return prov in self.extra or prov in self.target

    @property
    def files(self):
        return self.target.files

    @property
    def label(self):
        return self.target.label


# ------------------------------------------------------------------------ fake ctx


class FakeActions:
    def __init__(self, graph, target):
        self.graph = graph
        self.target = target

    def declare_file(self, filename, sibling=None):
        if sibling is not None:
            filename = posixpath.join(
                posixpath.dirname(sibling.relpath), filename
            )
        return self.graph.declared_file(self.target, filename)

    def declare_directory(self, filename, sibling=None):
        return self.declare_file(filename, sibling)

    def write(self, output, content, is_executable=False):
        if isinstance(content, str):
            content = content.encode("utf-8")
        output.content = content

    def symlink(
        self,
        output,
        target_file=None,
        target_path=None,
        is_executable=False,
        progress_message=None,
    ):
        output.symlink_target = target_file

    def expand_template(
        self,
        template,
        output,
        substitutions,
        is_executable=False,
        computed_substitutions=None,
    ):
        text = self.graph.file_bytes(template).decode("utf-8")
        for k, v in substitutions.items():
            text = text.replace(k, v)
        output.content = text.encode("utf-8")

    def run(
        self,
        outputs,
        inputs=None,
        executable=None,
        arguments=None,
        tools=None,
        mnemonic=None,
        progress_message=None,
        env=None,
        **kwargs,
    ):
        ins = (
            inputs.to_list()
            if isinstance(inputs, Depset)
            else list(inputs or [])
        )
        action = Action(executable, list(arguments or []), ins)
        for out in outputs:
            out.action = action

    def run_shell(
        self, outputs, inputs=None, command="", arguments=None, **kwargs
    ):
        ins = (
            inputs.to_list()
            if isinstance(inputs, Depset)
            else list(inputs or [])
        )
        action = Action(None, list(arguments or []), ins, command=command)
        for out in outputs:
            out.action = action

    def args(self):
        return Permissive("args")


class FakeCtx:
    def __init__(self, graph, target, rule_class):
        self.graph = graph
        self.label = target.label
        self.attr = Struct()
        self.file = Struct()
        self.files = Struct()
        self.outputs = Struct()
        self.executable = Struct()
        self.actions = FakeActions(graph, target)
        self.bin_dir = Struct(path=BIN_DIR)
        self.genfiles_dir = Struct(path=BIN_DIR)
        self.workspace_name = "_main"
        self.info_file = File(
            graph,
            Label("", "", "stable-status.txt"),
            "stable-status.txt",
            False,
        )
        self.version_file = File(
            graph,
            Label("", "", "volatile-status.txt"),
            "volatile-status.txt",
            False,
        )
        self.var = {}
        self.fragments = Permissive("fragments")
        self.configuration = Permissive("configuration")
        self.toolchains = {}
        self.rule = Struct(attr=self.attr, kind=target.kind)
        for name, spec in rule_class.attrs.items():
            value = target.attr(name)
            if spec.kind == "label":
                if spec.aspects and value is not None:
                    value = graph.apply_aspects(spec.aspects, value)
                setattr(self.attr, name, value)
                if value is not None:
                    files = (
                        value.files.to_list()
                        if isinstance(value, (Target, AspectView))
                        else []
                    )
                    setattr(self.files, name, files)
                    if spec.allow_single_file:
                        if len(files) != 1:
                            raise StarlarkError(
                                "%s: attr %s expected one file, got %r"
                                % (target.label, name, files)
                            )
                        setattr(self.file, name, files[0])
                    if spec.executable:
                        exe = value[DefaultInfo].executable or (
                            files[0] if files else None
                        )
                        setattr(self.executable, name, exe)
                else:
                    setattr(self.files, name, [])
                    setattr(self.file, name, None)
            elif spec.kind == LABEL_LIST:
                targets = value or []
                if spec.aspects:
                    targets = [
                        graph.apply_aspects(spec.aspects, t) for t in targets
                    ]
                setattr(self.attr, name, targets)
                files = []
                for t in targets:
                    files.extend(t.files.to_list())
                setattr(self.files, name, files)
            elif spec.kind == "output":
                setattr(self.outputs, name, value)
                setattr(self.attr, name, value)
            elif spec.kind == "output_list":
                setattr(self.outputs, name, value or [])
                setattr(self.attr, name, value or [])
            else:
                setattr(self.attr, name, value)
        if rule_class.executable or rule_class.test:
            self.outputs.executable = graph.declared_file(
                target, target.label.name
            )

    def runfiles(
        self,
        files=None,
        transitive_files=None,
        collect_data=False,
        collect_default=False,
        symlinks=None,
        root_symlinks=None,
    ):
        return Runfiles(files or [], transitive_files)

    def expand_location(self, s, targets=None):
        return s


# ---------------------------------------------------------------------------- Graph


class Graph:
    def __init__(
        self,
        repo,
        llvm_src,
        llvm_overlay,
        llvm_build,
        build_mode="opt",
        llvm_symbolizer="/usr/bin/llvm-symbolizer",
        gtest_defines=("GTEST_HAS_ABSL=1",),
        verbose=False,
    ):
        self.repo = os.path.abspath(repo)
        self.llvm_src = os.path.abspath(llvm_src)
        self.llvm_overlay = os.path.abspath(llvm_overlay)
        self.llvm_build = os.path.abspath(llvm_build)
        self.build_mode = build_mode
        self.llvm_symbolizer = llvm_symbolizer
        self.gtest_defines = list(gtest_defines)
        self.verbose = verbose
        self.packages = {}
        self.modules = {}
        self.ctx_stack = []
        self.source_files = {}
        self.condition_cache = {}
        self.llvm_version = self._read_llvm_version()
        self.analyzing = set()
        self.notes = []

    # ---- paths

    def source_root(self, repo):
        if repo == "":
            return self.repo
        if repo == "llvm-project":
            return self.llvm_src
        raise StarlarkError("no source tree for external repo @%s" % repo)

    def _read_llvm_version(self):
        text = open(
            os.path.join(self.llvm_src, "cmake/Modules/LLVMVersion.cmake")
        ).read()
        v = {}
        for key in ("MAJOR", "MINOR", "PATCH"):
            m = re.search(r"set\(LLVM_VERSION_%s (\d+)\)" % key, text)
            v[key] = int(m.group(1))
        m = re.search(r"set\(LLVM_VERSION_SUFFIX (\S*)\)", text)
        v["SUFFIX"] = m.group(1) if m else ""
        return v

    def log(self, msg):
        if self.verbose:
            print("bazel_graph: " + msg, file=sys.stderr)

    # ---- packages and labels

    def current_package(self):
        if not self.ctx_stack:
            raise StarlarkError(
                "no package context (rule call outside a BUILD file)"
            )
        return self.ctx_stack[-1]

    def build_file_path(self, repo, pkg):
        if repo == "":
            for name in ("BUILD", "BUILD.bazel"):
                p = os.path.join(self.repo, pkg, name)
                if os.path.exists(p):
                    return p
            return None
        if repo == "llvm-project":
            p = os.path.join(self.llvm_overlay, pkg, "BUILD.bazel")
            return p if os.path.exists(p) else None
        return None

    def is_package(self, repo, pkg):
        return self.build_file_path(repo, pkg) is not None

    def package(self, repo, pkg):
        key = (repo, pkg)
        if key in self.packages:
            return self.packages[key]
        if repo == "llvm-project" and pkg in LLVM_LIB_PACKAGES:
            p = Package("llvm-project", pkg, None)
            self.packages[key] = p
            self._populate_llvm_lib_package(p)
            return p
        if repo not in ("", "llvm-project"):
            p = Package(repo, pkg, None)
            self.packages[key] = p
            return p
        build_file = self.build_file_path(repo, pkg)
        if build_file is None:
            raise StarlarkError(
                "no BUILD file for package @%s//%s" % (repo, pkg)
            )
        p = Package(repo, pkg, build_file)
        self.packages[key] = p
        self.log("evaluating %s" % build_file)
        self.ctx_stack.append(p)
        try:
            self.exec_module(
                build_file,
                Label(repo, pkg, posixpath.basename(build_file)),
                is_build=True,
            )
        finally:
            self.ctx_stack.pop()
        return p

    def source_file(self, repo, pkg, relpath):
        key = (repo, pkg, relpath)
        f = self.source_files.get(key)
        if f is None:
            f = File(self, Label(repo, pkg, relpath), relpath, True)
            self.source_files[key] = f
        return f

    def target(self, label, cur=None):
        """Resolve a label (str/Label) to a Target, in the context of Label `cur`."""
        if isinstance(label, Target):
            return label
        if isinstance(label, str):
            cur_repo = cur.repo if cur is not None else ""
            cur_pkg = cur.package if cur is not None else ""
            label = Label.parse(label, cur_repo, cur_pkg)
        if label.repo not in ("", "llvm-project"):
            return self._external_target(label)
        if label.repo == "llvm-project" and label.package in LLVM_LIB_PACKAGES:
            pkg = self.package(label.repo, label.package)
            t = pkg.targets.get(label.name)
            if t is not None:
                return t
            return self._external_target(label)
        pkg = self.package(label.repo, label.package)
        t = pkg.targets.get(label.name)
        if t is not None:
            return t
        if label.name in pkg.outputs:
            owner, _ = pkg.outputs[label.name]
            f = self.declared_file(owner, label.name)
            # Analyze the generating rule so the file carries its action/content.
            self.analyze(owner)
            ft = FileTarget(self, label, f)
            pkg.targets[label.name] = ft
            return ft
        real = os.path.join(
            self.source_root(label.repo), label.package, label.name
        )
        if os.path.exists(real):
            f = self.source_file(label.repo, label.package, label.name)
            ft = FileTarget(self, label, f)
            pkg.targets[label.name] = ft
            return ft
        raise StarlarkError(
            "no such target or file: %s (looked for %s)" % (label, real)
        )

    def declared_file(self, owner, name):
        pkg = self.package(owner.label.repo, owner.label.package)
        f = pkg.declared.get(name)
        if f is None:
            f = File(self, owner.label, name, False, generator=owner)
            pkg.declared[name] = f
        return f

    def files_of(self, label, cur=None):
        t = self.target(label, cur)
        return t.files.to_list()

    # ---- recording targets during BUILD evaluation

    def record_target(self, kind, kwargs, rule_class=None):
        pkg = self.current_package()
        name = kwargs.get("name")
        if not isinstance(name, str):
            raise StarlarkError(
                "rule %s without a string name in //%s" % (kind, pkg.name)
            )
        if name in pkg.targets:
            raise StarlarkError(
                "duplicate target %s in //%s" % (name, pkg.name)
            )
        t = Target(
            self,
            Label(pkg.repo, pkg.name, name),
            kind,
            kwargs,
            rule_class,
            pkg.label,
        )
        pkg.targets[name] = t
        # Declared outputs addressable as files.
        if rule_class is not None:
            for aname, spec in rule_class.attrs.items():
                if spec.kind == "output" and kwargs.get(aname):
                    pkg.outputs[kwargs[aname]] = (t, aname)
                elif spec.kind == "output_list":
                    for o in kwargs.get(aname) or []:
                        pkg.outputs[o] = (t, aname)
        elif kind == "genrule":
            for o in self.resolve(kwargs.get("outs") or [], pkg.label):
                pkg.outputs[o] = (t, "outs")
        return t

    def native_rule(self, kind):
        def rec(**kwargs):
            return self.record_target(kind, kwargs)

        rec.__name__ = kind
        return rec

    # ---- Starlark module execution

    def exec_module(self, path, module_label, is_build=False):
        with open(path, encoding="utf-8") as f:
            src = f.read()
        tree = ast.parse(src, filename=path)
        tree = _LoadRewriter().visit(tree)
        ast.fix_missing_locations(tree)
        code = compile(tree, path, "exec")
        g = self.make_globals(module_label, is_build)
        exec(code, g)
        return g

    def load_module(self, label_str, cur_module):
        label = Label.parse(label_str, cur_module.repo, cur_module.package)
        key = str(label)
        if key in self.modules:
            return self.modules[key]
        stub = self._stub_module(label)
        if stub is not None:
            self.modules[key] = stub
            return stub
        if label.repo == "":
            path = os.path.join(self.repo, label.package, label.name)
        elif label.repo == "llvm-project":
            path = os.path.join(self.llvm_overlay, label.package, label.name)
        else:
            raise StarlarkError(
                "no stub for load(%s) from %s" % (label_str, cur_module)
            )
        if not os.path.exists(path):
            raise StarlarkError(
                "load(%s): %s does not exist" % (label_str, path)
            )
        self.log("loading %s" % path)
        g = self.exec_module(path, label, is_build=False)
        self.modules[key] = g
        return g

    def make_globals(self, module_label, is_build):
        g = self

        def _load(path, syms):
            mod = g.load_module(path, module_label)
            out = []
            for s in syms:
                if s not in mod:
                    raise StarlarkError("load(%s): no symbol %s" % (path, s))
                out.append(mod[s])
            return out

        def _label(s):
            return Label.parse(s, module_label.repo, module_label.package)

        def _rule(implementation=None, attrs=None, **kwargs):
            return RuleClass(g, module_label, implementation, attrs, **kwargs)

        def _glob(
            include=(), exclude=(), exclude_directories=1, allow_empty=True
        ):
            return g.glob(include, exclude, allow_empty)

        def _print(*args, **kwargs):
            print("Starlark print:", *args, file=sys.stderr)

        native = _Native(g)
        ns = {
            "__builtins__": _SAFE_BUILTINS,
            "__load__": _load,
            "Label": _label,
            "rule": _rule,
            "aspect": lambda implementation, **kw: AspectDef(
                implementation, **kw
            ),
            "transition": lambda **kw: Transition(**kw),
            "attr": attr,
            "provider": provider,
            "depset": depset,
            "select": select,
            "struct": Struct,
            "fail": fail,
            "print": _print,
            "glob": _glob,
            "native": native,
            "DefaultInfo": DefaultInfo,
            "OutputGroupInfo": OutputGroupInfo,
            "RunEnvironmentInfo": RunEnvironmentInfo,
            "CcInfo": CcInfo,
            "config_common": Permissive("config_common"),
            "platform_common": Permissive("platform_common"),
            "json": Permissive("json"),
            "type": starlark_type,
            "set": set,
        }
        if is_build:
            for k in (
                "filegroup",
                "genrule",
                "alias",
                "config_setting",
                "package_group",
                "test_suite",
                "toolchain",
                "toolchain_type",
                "constraint_setting",
                "constraint_value",
                "platform",
                "cc_toolchain",
                "cc_toolchain_suite",
            ):
                ns[k] = g.native_rule(k)
            ns["exports_files"] = lambda *a, **k: None
            ns["licenses"] = lambda *a, **k: None
            ns["package"] = lambda **k: None
        return ns

    # ---- stub modules for external .bzl files

    def _stub_module(self, label):
        g = self
        if label.repo == "rules_cc":
            if label.name == "defs.bzl":
                return {
                    k: g.native_rule(k)
                    for k in (
                        "cc_library",
                        "cc_binary",
                        "cc_test",
                        "cc_import",
                        "cc_shared_library",
                        "objc_library",
                    )
                }
            if label.name == "action_names.bzl":
                return {
                    "ACTION_NAMES": PermissiveStruct(),
                    "ACTION_NAME_GROUPS": PermissiveStruct(True),
                }
            if label.name == "cc_toolchain_config_lib.bzl":
                return _PermissiveModule()
            if label.name == "cc_common.bzl":
                return {"cc_common": Permissive("cc_common")}
            if label.name == "cc_info.bzl":
                return {"CcInfo": CcInfo}
            if label.name == "find_cc_toolchain.bzl":
                return {
                    "find_cc_toolchain": Permissive("find_cc_toolchain"),
                    "use_cc_toolchain": lambda *a, **k: [],
                }
            return _PermissiveModule()
        if label.repo == "bazel_skylib":
            if label.name == "common_settings.bzl":
                d = {
                    k: g.native_rule(k)
                    for k in (
                        "bool_flag",
                        "int_flag",
                        "string_flag",
                        "bool_setting",
                        "int_setting",
                        "string_setting",
                        "string_list_flag",
                    )
                }
                d["BuildSettingInfo"] = BuildSettingInfo
                return d
            if label.name == "selects.bzl":

                def with_or(mapping, no_match_error=""):
                    out = {}
                    for k, v in mapping.items():
                        if isinstance(k, tuple):
                            for kk in k:
                                out[kk] = v
                        else:
                            out[k] = v
                    return Select(out, no_match_error)

                def config_setting_group(
                    name, match_any=None, match_all=None, **kw
                ):
                    return g.record_target(
                        "config_setting_group",
                        dict(
                            name=name,
                            match_any=match_any or [],
                            match_all=match_all or [],
                        ),
                    )

                return {
                    "selects": Struct(
                        with_or=with_or,
                        config_setting_group=config_setting_group,
                    )
                }
            if label.name == "paths.bzl":
                return {
                    "paths": Struct(
                        join=posixpath.join,
                        basename=posixpath.basename,
                        dirname=posixpath.dirname,
                        normalize=posixpath.normpath,
                        relativize=lambda p, start: posixpath.relpath(p, start),
                        split_extension=posixpath.splitext,
                        replace_extension=lambda p, ext: (
                            posixpath.splitext(p)[0] + ext
                        ),
                        is_absolute=posixpath.isabs,
                    )
                }
            return _PermissiveModule()
        if label.repo == "rules_python":
            return {
                k: g.native_rule(k)
                for k in ("py_binary", "py_test", "py_library")
            }
        if label.repo == "rules_shell":
            return {
                k: g.native_rule(k)
                for k in ("sh_test", "sh_binary", "sh_library")
            }
        if label.repo == "rules_pkg":
            if label.name == "mappings.bzl":
                return {
                    "pkg_attributes": lambda **k: dict(k),
                    "pkg_filegroup": g.native_rule("pkg_filegroup"),
                    "pkg_files": g.native_rule("pkg_files"),
                    "pkg_mklink": g.native_rule("pkg_mklink"),
                    "pkg_mkdirs": g.native_rule("pkg_mkdirs"),
                    "strip_prefix": Struct(
                        from_pkg=lambda p="": p,
                        from_root=lambda p="": "/" + p,
                        files_only=lambda: ".",
                    ),
                }
            if label.name == "providers.bzl":
                return {"PackageVariablesInfo": PackageVariablesInfo}
            if label.name == "tar.bzl":
                return {"pkg_tar": g.native_rule("pkg_tar")}
            return _PermissiveModule()
        if label.repo == "bazel_tools":
            return {
                "find_cpp_toolchain": Permissive("find_cpp_toolchain"),
                "use_cpp_toolchain": lambda *a, **k: [],
            }
        if label.repo == "bazel_cc_toolchain":
            return {
                "llvm_symbolizer": g.llvm_symbolizer,
                "clang_bindir": os.path.dirname(g.llvm_symbolizer),
                "llvm_bindir": os.path.dirname(g.llvm_symbolizer),
                "clang_version": "0",
                "clang_version_for_cache": "0",
                "clang_include_dirs_list": [],
                "clang_resource_dir": "",
                "sysroot_dir": "None",
            }
        if (
            label.repo == "llvm-project"
            and label.package == ""
            and label.name == "vars.bzl"
        ):
            # llvm_configure's vars.bzl writes every value as a string
            # (utils/bazel/configure.bzl, _write_dict_to_file).
            v = self.llvm_version
            version = "%d.%d.%d" % (v["MAJOR"], v["MINOR"], v["PATCH"])
            return {
                "LLVM_VERSION_MAJOR": str(v["MAJOR"]),
                "LLVM_VERSION_MINOR": str(v["MINOR"]),
                "LLVM_VERSION_PATCH": str(v["PATCH"]),
                "LLVM_VERSION_SUFFIX": v["SUFFIX"],
                "LLVM_VERSION": version,
                "PACKAGE_VERSION": version + v["SUFFIX"],
                "CMAKE_CXX_STANDARD": "17",
            }
        if (
            label.repo == ""
            and label.package == "bazel/cc_toolchains"
            and label.name
            in (
                "carbon_bootstrapping.bzl",
                "carbon_cc_toolchain_config.bzl",
                "clang_configuration.bzl",
                "clang_cc_toolchain_config.bzl",
            )
        ):
            # Bazel cc_toolchain plumbing (transitions, cc_common): recorded generically.
            return {
                k: g.native_rule(k)
                for k in (
                    "carbon_bootstrapped_cc_toolchain",
                    "filegroup_with_stage",
                    "gen_cc_toolchain_paths_with_stage",
                    "carbon_cc_toolchain",
                    "filegroup_with_stage_and_exec",
                    "clang_toolchain_extension",
                    "configure_clang_toolchain",
                    "cc_toolchain_config",
                )
            }
        if (
            label.repo == ""
            and label.package == "bazel/carbon_rules"
            and label.name == "defs.bzl"
        ):
            return {
                k: g.native_rule(k) for k in ("carbon_library", "carbon_binary")
            }
        if (
            label.repo == ""
            and label.package == "toolchain/runtimes"
            and label.name == "carbon_runtimes.bzl"
        ):
            return {
                k: g.native_rule(k)
                for k in (
                    "carbon_prelude",
                    "carbon_runtimes_config",
                    "carbon_runtimes_build",
                )
            }
        return None

    # ---- glob

    def glob(self, include, exclude=(), allow_empty=True):
        pkg = self.current_package()
        if isinstance(include, str):
            include = [include]
        files = self._package_files(pkg.repo, pkg.name)
        inc = [_glob_regex(p) for p in include]
        exc = [_glob_regex(p) for p in exclude]
        out = []
        for f in files:
            if any(r.fullmatch(f) for r in inc) and not any(
                r.fullmatch(f) for r in exc
            ):
                out.append(f)
        out.sort()
        if not out and not allow_empty:
            self.notes.append("empty glob %r in //%s" % (include, pkg.name))
        return out

    def _package_files(self, repo, pkg):
        key = ("files", repo, pkg)
        cached = self.packages.get(key)
        if cached is not None:
            return cached
        root = os.path.join(self.source_root(repo), pkg)
        result = []
        for dirpath, dirnames, filenames in os.walk(root):
            rel = os.path.relpath(dirpath, root)
            rel = "" if rel == "." else rel.replace(os.sep, "/")
            keep = []
            for d in sorted(dirnames):
                sub = (rel + "/" + d) if rel else d
                if self.is_package(repo, (pkg + "/" + sub) if pkg else sub):
                    continue
                keep.append(d)
            dirnames[:] = keep
            for fn in filenames:
                result.append((rel + "/" + fn) if rel else fn)
        result.sort()
        self.packages[key] = result
        return result

    # ---- select resolution

    def resolve(self, value, package_label):
        if isinstance(value, Select):
            return self.resolve(self._pick(value, package_label), package_label)
        if isinstance(value, SelectConcat):
            parts = [self.resolve(p, package_label) for p in value.parts]
            acc = parts[0]
            for p in parts[1:]:
                if value.op == "+":
                    acc = acc + p
                else:
                    acc = {**acc, **p}
            return acc
        if isinstance(value, list):
            return [self.resolve(v, package_label) for v in value]
        return value

    def _pick(self, sel, package_label):
        matches = []
        default = None
        has_default = False
        for k, v in sel.mapping.items():
            ks = str(k) if isinstance(k, Label) else k
            if ks == "//conditions:default":
                default = v
                has_default = True
                continue
            lab = (
                k
                if isinstance(k, Label)
                else Label.parse(k, package_label.repo, package_label.package)
            )
            if self.condition_true(lab):
                matches.append((lab, v))
        if not matches:
            if has_default:
                return default
            raise StarlarkError(
                "select(): no matching condition and no default in //%s: %r"
                % (package_label.package, list(sel.mapping))
            )
        if len(matches) > 1:
            # Bazel picks the most specialized; we require a unique winner by
            # constraint count and fail loudly otherwise.
            matches.sort(key=lambda kv: -self._condition_specificity(kv[0]))
            if self._condition_specificity(
                matches[0][0]
            ) == self._condition_specificity(matches[1][0]):
                raise StarlarkError(
                    "select(): ambiguous conditions %r"
                    % ([m[0] for m in matches],)
                )
        return matches[0][1]

    def _condition_specificity(self, lab):
        if lab.repo == "platforms":
            return 1
        t = self.target(lab)
        n = 0
        for a in (
            "constraint_values",
            "flag_values",
            "values",
            "define_values",
        ):
            v = self.resolve(t.kwargs.get(a) or [], t.package_label)
            n += len(v)
        return n

    PLATFORM_TRUE = {"//os:linux", "//cpu:x86_64", "//os:linux_gnu"}

    def condition_true(self, lab):
        key = str(lab)
        if key in self.condition_cache:
            return self.condition_cache[key]
        result = self._condition_true(lab)
        self.condition_cache[key] = result
        return result

    def _condition_true(self, lab):
        if lab.repo == "platforms":
            return ("//%s:%s" % (lab.package, lab.name)) in self.PLATFORM_TRUE
        if lab.repo == "rules_cc":
            return lab.name == "glibc"
        if lab.repo not in ("", "llvm-project"):
            return False
        t = self.target(lab)
        if t.kind == "alias":
            return self.condition_true(t.attr("actual").label)
        if t.kind == "config_setting_group":
            any_ = [self.condition_true(x.label) for x in t.attr("match_any")]
            all_ = [self.condition_true(x.label) for x in t.attr("match_all")]
            if any_ and not any(any_):
                return False
            if all_ and not all(all_):
                return False
            return bool(any_ or all_)
        if t.kind != "config_setting":
            raise StarlarkError(
                "select key %s is a %s, not a config_setting" % (lab, t.kind)
            )
        for cv in t.attr("constraint_values"):
            if not self.condition_true(cv.label):
                return False
        for flag, value in t.attr("flag_values").items():
            if flag.kind not in (
                "bool_flag",
                "int_flag",
                "string_flag",
                "bool_setting",
                "int_setting",
                "string_setting",
            ):
                raise StarlarkError(
                    "flag_values key %s is a %s" % (flag.label, flag.kind)
                )
            default = self.resolve(
                flag.kwargs.get("build_setting_default"), flag.package_label
            )
            if str(default).lower() != str(value).lower():
                return False
        for k, v in (
            self.resolve(t.kwargs.get("values") or {}, t.package_label)
        ).items():
            if k == "compilation_mode":
                if v != self.build_mode:
                    return False
            elif k == "define":
                if v not in ("absl=1", "pfm=1"):
                    return False
            elif k in ("cpu", "host_cpu"):
                if v != "k8":
                    return False
            else:
                return False
        for k, v in (
            self.resolve(t.kwargs.get("define_values") or {}, t.package_label)
        ).items():
            if (k, v) not in (("absl", "1"), ("pfm", "1")):
                return False
        return True

    # ---- analysis

    def analyze(self, t):
        if t.providers is not None:
            return t.providers
        if t.label in self.analyzing:
            raise StarlarkError("dependency cycle at %s" % t.label)
        self.analyzing.add(t.label)
        try:
            t.providers = self._analyze(t)
        finally:
            self.analyzing.discard(t.label)
        return t.providers

    def _analyze(self, t):
        kind = t.kind
        if t.rule_class is not None and t.rule_class.implementation is not None:
            ctx = FakeCtx(self, t, t.rule_class)
            result = t.rule_class.implementation(ctx)
            provs = {}
            if isinstance(result, ProviderInstance):
                result = [result]
            for p in result or []:
                if isinstance(p, ProviderInstance):
                    provs[p._cls] = p
                elif isinstance(p, Struct):
                    # Legacy struct providers: expose `files` if present.
                    if hasattr(p, "files"):
                        provs[DefaultInfo] = DefaultInfo(files=p.files)
            provs.setdefault(DefaultInfo, DefaultInfo(files=Depset()))
            return provs
        if kind == "filegroup":
            srcs = t.attr("srcs")
            files = Depset(transitive=[s.files for s in srcs])
            return {DefaultInfo: DefaultInfo(files=files)}
        if kind == "alias":
            actual = t.attr("actual")
            return dict(self.analyze(actual))
        if kind in (
            "cc_binary",
            "cc_test",
            "py_binary",
            "py_test",
            "sh_binary",
            "sh_test",
        ):
            if kind.startswith("py_"):
                srcs = t.attr("srcs")
                files = []
                for s in srcs:
                    files.extend(s.files.to_list())
                main = t.attr("main")
                exe = (
                    main.files.to_list()[0]
                    if main is not None
                    else (files[0] if files else None)
                )
                return {
                    DefaultInfo: DefaultInfo(
                        files=Depset(files), executable=exe
                    )
                }
            exe = self.declared_file(t, t.label.name)
            return {
                DefaultInfo: DefaultInfo(files=Depset([exe]), executable=exe)
            }
        if kind == "cc_library":
            return {DefaultInfo: DefaultInfo(files=Depset())}
        if kind == "genrule":
            outs = t.attr("outs")
            return {DefaultInfo: DefaultInfo(files=Depset(outs))}
        if kind in (
            "bool_flag",
            "int_flag",
            "string_flag",
            "bool_setting",
            "int_setting",
            "string_setting",
            "string_list_flag",
        ):
            value = self.resolve(
                t.kwargs.get("build_setting_default"), t.package_label
            )
            return {
                DefaultInfo: DefaultInfo(files=Depset()),
                BuildSettingInfo: BuildSettingInfo(value=value),
            }
        if kind in ("config_setting", "config_setting_group"):
            return {
                DefaultInfo: DefaultInfo(files=Depset()),
                ConfigSettingInfo: ConfigSettingInfo(),
            }
        # Anything else (toolchains, pkg rules, benchmarks' sh_test, ...): no files.
        return {DefaultInfo: DefaultInfo(files=Depset())}

    def apply_aspects(self, aspects, target):
        view = target
        extra = {}
        for a in aspects:
            extra.update(self._apply_aspect(a, target))
        if extra:
            view = AspectView(target, extra)
        return view

    def _apply_aspect(self, aspect, target):
        key = id(aspect)
        if key in target._aspects:
            return target._aspects[key]
        if isinstance(target, FileTarget):
            target._aspects[key] = {}
            return {}
        rule_attr = Struct()
        names = set(aspect.attr_aspects) | {
            "srcs",
            "hdrs",
            "textual_hdrs",
            "deps",
            "data",
        }
        for name in names:
            if name not in target.kwargs and not (
                target.rule_class and name in target.rule_class.attrs
            ):
                continue
            kind = target.attr_kind(name)
            if kind not in ("label", LABEL_LIST):
                continue
            value = target.attr(name)
            if name in aspect.attr_aspects:
                if kind == "label":
                    value = (
                        self.apply_aspects([aspect], value)
                        if value is not None
                        else None
                    )
                else:
                    value = [self.apply_aspects([aspect], v) for v in value]
            setattr(rule_attr, name, value)
        ctx = Struct(
            rule=Struct(attr=rule_attr, kind=target.kind), label=target.label
        )
        result = aspect.implementation(target, ctx)
        provs = {}
        if isinstance(result, ProviderInstance):
            result = [result]
        for p in result or []:
            if isinstance(p, ProviderInstance):
                provs[p._cls] = p
        target._aspects[key] = provs
        return provs

    # ---- @llvm-project//{llvm,clang,lld}: prebuilt libraries + tool libs + builtin headers

    def _populate_llvm_lib_package(self, p):
        pkg = p.name
        if pkg == "clang":
            self.ctx_stack.append(p)
            try:
                builtin_headers = self._clang_builtin_headers()
            finally:
                self.ctx_stack.pop()
            lab = Label("llvm-project", "clang", "builtin_headers_gen")
            gen = Target(
                self,
                lab,
                "genrule",
                {"name": "builtin_headers_gen"},
                None,
                p.label,
            )
            outs = []
            srcs = []
            for hdr in builtin_headers:
                src = self._clang_builtin_header_source(hdr)
                out = self.declared_file(
                    gen, hdr.replace("lib/Headers/", "staging/include/")
                )
                out.symlink_target = src
                outs.append(out)
                srcs.append(src)
            gen.providers = {DefaultInfo: DefaultInfo(files=Depset(outs))}
            gen.genrule_srcs = srcs
            p.targets["builtin_headers_gen"] = gen
            fg = Target(
                self,
                Label("llvm-project", "clang", "builtin_headers_files"),
                "filegroup",
                {
                    "name": "builtin_headers_files",
                    "srcs": list(builtin_headers),
                },
                None,
                p.label,
            )
            p.targets["builtin_headers_files"] = fg

    def _clang_builtin_headers(self):
        """The `builtin_headers` list of the clang overlay BUILD.bazel (glob + explicit)."""
        path = os.path.join(self.llvm_overlay, "clang", "BUILD.bazel")
        tree = ast.parse(open(path, encoding="utf-8").read(), filename=path)
        for node in tree.body:
            if (
                isinstance(node, ast.Assign)
                and len(node.targets) == 1
                and isinstance(node.targets[0], ast.Name)
                and node.targets[0].id == "builtin_headers"
            ):
                expr = ast.Expression(node.value)
                ast.fix_missing_locations(expr)
                ns = {
                    "glob": lambda include=(), exclude=(), allow_empty=True: (
                        self.glob(include, exclude, allow_empty)
                    )
                }
                return eval(
                    compile(expr, path, "eval"), {"__builtins__": {}}, ns
                )
        raise StarlarkError("builtin_headers not found in " + path)

    def _clang_builtin_header_source(self, hdr):
        """lib/Headers/X: a source file, or (arm_neon.h & co) clang-tblgen output that the
        CMake build staged under lib/clang/<MAJOR>/include."""
        real = os.path.join(self.llvm_src, "clang", hdr)
        if os.path.exists(real):
            return self.source_file("llvm-project", "clang", hdr)
        lab = Label("llvm-project", "clang", hdr)
        f = File(self, lab, hdr, False, generator=None)
        f.real_path_override = os.path.join(
            self.llvm_build,
            "lib",
            "clang",
            str(self.llvm_version["MAJOR"]),
            "include",
            hdr[len("lib/Headers/") :],
        )
        f.generated_by_tblgen = True
        return f

    def _external_target(self, label):
        pkg = self.package(label.repo, label.package)
        t = pkg.targets.get(label.name)
        if t is not None:
            return t
        if label.repo == "llvm-project":
            if label.package == "llvm" and label.name.endswith("-lib"):
                t = self._tool_lib(
                    label, "llvm/tools/" + label.name[: -len("-lib")]
                )
            elif label.package == "clang" and label.name == "clang-driver":
                t = self._tool_lib(label, "clang/tools/driver")
            elif label.package in LLVM_LIB_PACKAGES:
                t = ExternalCcTarget(self, label, "llvm")
            else:
                raise StarlarkError(
                    "unsupported @llvm-project label %s" % label
                )
        elif label.repo == "abseil-cpp":
            t = ExternalCcTarget(self, label, "absl")
        elif label.repo == "googletest":
            t = ExternalCcTarget(self, label, "gtest")
        elif label.repo == "re2":
            t = ExternalCcTarget(self, label, "re2")
        elif label.repo == "boost.unordered":
            t = ExternalCcTarget(self, label, "boost")
        elif (
            label.repo == "bazel_tools"
            and label.package == "tools/cpp/runfiles"
        ):
            t = ExternalCcTarget(self, label, "runfiles")
        elif label.repo in (
            "bazel_tools",
            "platforms",
            "rules_cc",
            "bazel_skylib",
            "rules_python",
        ):
            t = Target(
                self,
                label,
                "external_misc",
                {"name": label.name},
                None,
                pkg.label,
            )
            t.providers = {DefaultInfo: DefaultInfo(files=Depset())}
        else:
            raise StarlarkError("unsupported external dependency %s" % label)
        pkg.targets[label.name] = t
        return t

    def _tool_lib(self, label, tool_dir):
        d = os.path.join(self.llvm_src, tool_dir)
        if not os.path.isdir(d):
            raise StarlarkError(
                "tool directory missing for %s: %s" % (label, d)
            )
        pkg, rest = tool_dir.split("/", 1)
        srcs = [
            self.source_file("llvm-project", pkg, rest + "/" + fn)
            for fn in sorted(os.listdir(d))
            if fn.endswith(".cpp")
        ]
        tablegen = []
        cmake = os.path.join(d, "CMakeLists.txt")
        if os.path.exists(cmake):
            td = None
            for line in open(cmake, encoding="utf-8"):
                m = re.match(r"\s*set\(LLVM_TARGET_DEFINITIONS\s+(\S+)\)", line)
                if m:
                    td = m.group(1)
                m = re.match(
                    r"\s*tablegen\(LLVM\s+(\S+)\s+-gen-opt-parser-defs\)", line
                )
                if m and td:
                    tablegen.append((tool_dir + "/" + td, m.group(1)))
        return ToolLibTarget(self, label, tool_dir, srcs, tablegen)

    # ---- outputs

    def manifest_text(self, label, cur=None):
        t = self.target(label, cur)
        files = t.files.to_list()
        if len(files) != 1 or files[0].content is None:
            raise StarlarkError("%s is not a written manifest" % label)
        return files[0].content.decode("utf-8")

    def file_bytes(self, f):
        if f.content is not None:
            return f.content
        if f.is_source or f.real_path_override:
            with open(f.real_path, "rb") as fh:
                return fh.read()
        if f.symlink_target is not None:
            return self.file_bytes(f.symlink_target)
        if f.action is not None:
            return self._run_action(f)
        gen = f.generator
        if gen is not None and gen.kind == "genrule":
            return self._genrule_bytes(gen, f)
        raise StarlarkError(
            "cannot materialize %s (generated by %s)" % (f.path, gen)
        )

    def _run_action(self, f):
        act = f.action
        if act.executable is None:
            raise StarlarkError(
                "run_shell action for %s not supported" % f.path
            )
        exe = act.executable
        exe_path = exe.real_path if exe.real_path else None
        if exe_path is None:
            raise StarlarkError(
                "action tool %s is not a source file" % exe.path
            )
        with tempfile.TemporaryDirectory() as tmp:
            mapping = {}
            for i in act.inputs:
                if i.real_path:
                    mapping[i.path] = i.real_path
                else:
                    p = os.path.join(tmp, "in", i.path)
                    os.makedirs(os.path.dirname(p), exist_ok=True)
                    with open(p, "wb") as fh:
                        fh.write(self.file_bytes(i))
                    mapping[i.path] = p
            out_path = os.path.join(tmp, "out", f.path)
            os.makedirs(os.path.dirname(out_path), exist_ok=True)
            mapping[f.path] = out_path
            args = []
            for a in act.arguments:
                for k, v in sorted(mapping.items(), key=lambda kv: -len(kv[0])):
                    a = a.replace(k, v)
                args.append(a)
            subprocess.run([sys.executable, "-I", exe_path] + args, check=True)
            with open(out_path, "rb") as fh:
                return fh.read()

    def action_command(self, f):
        """(tool real path, arguments with Bazel exec paths) for a ctx.actions.run output."""
        act = f.action
        return act.executable.real_path, list(act.arguments), list(act.inputs)

    def _genrule_bytes(self, gen, f):
        cmd = self.resolve(gen.kwargs.get("cmd", ""), gen.package_label)
        srcs = gen.attr("srcs")
        src_files = []
        for s in srcs:
            src_files.extend(s.files.to_list())
        # Sequences of `echo '...' >> $@|$(OUTS)` (compiler-rt outline atomics, clangd
        # Features.inc) optionally followed by `cat $(SRCS) >> $(OUTS)`, joined by && or newlines.
        parts = [p.strip() for p in re.split(r"&&|\n", cmd) if p.strip()]
        if parts and all(
            re.fullmatch(r"echo '([^']*)' >> (\$@|\$\(OUTS\))", p)
            or re.fullmatch(r"cat \$\(SRCS\) >> (\$@|\$\(OUTS\))", p)
            for p in parts
        ):
            out = b""
            for p in parts:
                m = re.fullmatch(r"echo '([^']*)' >> (\$@|\$\(OUTS\))", p)
                if m:
                    out += (m.group(1) + "\n").encode("utf-8")
                else:
                    for s in src_files:
                        out += self.file_bytes(s)
            return out
        # toolchain/install: sed 's|a|b|' $< > $@
        m = re.match(r"sed 's\|([^|]*)\|([^|]*)\|' \$< > \$@$", cmd.strip())
        if m and len(src_files) == 1:
            text = self.file_bytes(src_files[0]).decode("utf-8")
            return text.replace(m.group(1), m.group(2)).encode("utf-8")
        raise StarlarkError(
            "genrule %s: command not interpretable here: %r" % (gen.label, cmd)
        )

    # ---- helpers for install.py

    INSTALL_PREFIX = BIN_DIR + "/toolchain/install/"

    def install_relative_path(self, f):
        """Path of a //toolchain/install output below the install root (lib/carbon in a
        packaged toolchain), e.g. 'core/prelude.carbon', 'llvm/lib/clang/24/include/stddef.h',
        'carbon-busybox'. Raises for files outside the install package."""
        if not f.path.startswith(self.INSTALL_PREFIX):
            raise StarlarkError(
                "%s is not a //toolchain/install output" % f.path
            )
        return f.path[len(self.INSTALL_PREFIX) :]

    def symlink_chain_end(self, f):
        """Follow toolchain_files/genrule symlinks to the file that holds the bytes."""
        while f.symlink_target is not None:
            f = f.symlink_target
        return f

    # ---- runfiles / data closure

    def transitive_runfiles(self, label, cur=None):
        """Files of all `data` deps reachable through deps/data of a binary (Bazel's
        default runfiles for a cc_binary/cc_test, minus the binary itself)."""
        root = self.target(label, cur)
        seen = set()
        out = []

        def visit(t):
            if t.label in seen:
                return
            seen.add(t.label)
            if isinstance(t, (FileTarget, ExternalCcTarget, ToolLibTarget)):
                return
            for name in ("deps", "data", "implementation_deps", "tools"):
                if t.attr_kind(name) == LABEL_LIST and name in t.kwargs:
                    for d in t.attr(name):
                        if name == "data" or d.kind not in (
                            "cc_library",
                            "cc_binary",
                            "cc_test",
                        ):
                            if name == "data":
                                for f in d.files.to_list():
                                    if f not in out:
                                        out.append(f)
                                for f in d.default_runfiles.files.to_list():
                                    if f not in out:
                                        out.append(f)
                        visit(d)

        visit(root)
        return out

    # ---- C++ closure

    def cc_closure(self, roots):
        """CcNodes for the roots and their transitive deps, topologically sorted with
        dependents before dependencies (Bazel's link order)."""
        nodes = {}
        order = []

        def visit(t, stack):
            if t.label in nodes:
                return nodes[t.label]
            if t.label in stack:
                raise StarlarkError("cc dependency cycle at %s" % t.label)
            node = CcNode(self, t)
            nodes[t.label] = node
            stack.add(t.label)
            for d in node.dep_targets():
                node.deps.append(visit(d, stack))
            stack.discard(t.label)
            order.append(node)
            return node

        for r in roots:
            visit(self.target(r), set())
        # order is a postorder (deps first); reverse for dependents-first.
        return list(reversed(order)), nodes


class CcNode:
    def __init__(self, graph, target):
        self.graph = graph
        self.target = target
        self.label = target.label
        self.kind = target.kind
        self.deps = []
        self.external = isinstance(target, (ExternalCcTarget, ToolLibTarget))
        pl = target.package_label
        g = graph
        kw = target.kwargs
        self.copts = list(g.resolve(kw.get("copts") or [], pl))
        self.defines = list(g.resolve(kw.get("defines") or [], pl))
        self.local_defines = list(g.resolve(kw.get("local_defines") or [], pl))
        self.linkopts = list(g.resolve(kw.get("linkopts") or [], pl))
        self.includes = list(g.resolve(kw.get("includes") or [], pl))
        self.alwayslink = bool(g.resolve(kw.get("alwayslink", False), pl))
        self.testonly = bool(g.resolve(kw.get("testonly", False), pl))
        self.env = g.resolve(kw.get("env") or {}, pl)
        self.strip_include_prefix = kw.get("strip_include_prefix")
        self.include_prefix = kw.get("include_prefix")
        if isinstance(target, ExternalCcTarget):
            self.group = target.group
            if target.group == "gtest":
                self.defines = list(graph.gtest_defines)
        else:
            self.group = None

    def _files(self, attr):
        if self.external or attr not in self.target.kwargs:
            return []
        out = []
        for t in self.target.attr(attr):
            out.extend(t.files.to_list())
        return out

    @property
    def srcs(self):
        if isinstance(self.target, ToolLibTarget):
            return list(self.target.srcs)
        return self._files("srcs")

    @property
    def hdrs(self):
        return self._files("hdrs")

    @property
    def textual_hdrs(self):
        return self._files("textual_hdrs")

    @property
    def linkstamp(self):
        if self.external or "linkstamp" not in self.target.kwargs:
            return None
        name = self.graph.resolve(
            self.target.kwargs["linkstamp"], self.target.package_label
        )
        return self.graph.target(
            name, self.target.package_label
        ).files.to_list()[0]

    def dep_targets(self):
        if self.external:
            return []
        out = []
        for attr in ("deps", "implementation_deps"):
            if attr in self.target.kwargs:
                out.extend(self.target.attr(attr))
        return out

    def __repr__(self):
        return "CcNode(%s)" % self.label


class _Native:
    def __init__(self, graph):
        self._graph = graph

    def package_name(self):
        return self._graph.current_package().name

    def repository_name(self):
        pkg = self._graph.current_package()
        return (
            "@"
            if pkg.repo == ""
            else "@" + CANONICAL_REPO.get(pkg.repo, pkg.repo + "+")
        )

    def repo_name(self):
        pkg = self._graph.current_package()
        return (
            ""
            if pkg.repo == ""
            else CANONICAL_REPO.get(pkg.repo, pkg.repo + "+")
        )

    def package_relative_label(self, s):
        pkg = self._graph.current_package()
        return Label.parse(s, pkg.repo, pkg.name)

    def glob(
        self, include=(), exclude=(), exclude_directories=1, allow_empty=True
    ):
        return self._graph.glob(include, exclude, allow_empty)

    def existing_rule(self, name):
        pkg = self._graph.current_package()
        t = pkg.targets.get(name)
        return dict(t.kwargs, kind=t.kind) if t is not None else None

    def existing_rules(self):
        pkg = self._graph.current_package()
        return {n: dict(t.kwargs, kind=t.kind) for n, t in pkg.targets.items()}

    def exports_files(self, *args, **kwargs):
        return None

    def __getattr__(self, name):
        if name.startswith("__"):
            raise AttributeError(name)
        return self._graph.native_rule(name)


class _PermissiveModule(dict):
    def __contains__(self, k):
        return True

    def __getitem__(self, k):
        return Permissive(k)


class _LoadRewriter(ast.NodeTransformer):
    """Rewrite `load("x.bzl", "a", b = "c")` into `(a, b) = __load__("x.bzl", ["a", "c"])`,
    and `d.values()/keys()/items()` into `list(...)` (Starlark returns lists, Python views)."""

    def visit_Call(self, node):
        self.generic_visit(node)
        f = node.func
        if (
            isinstance(f, ast.Attribute)
            and f.attr in ("values", "keys", "items")
            and not node.args
            and not node.keywords
        ):
            return ast.copy_location(
                ast.Call(
                    func=ast.Name(id="list", ctx=ast.Load()),
                    args=[node],
                    keywords=[],
                ),
                node,
            )
        return node

    def visit_Expr(self, node):
        call = node.value
        if (
            isinstance(call, ast.Call)
            and isinstance(call.func, ast.Name)
            and call.func.id == "load"
        ):
            path = call.args[0]
            names = []
            syms = []
            for a in call.args[1:]:
                names.append(a.value)
                syms.append(a.value)
            for kw in call.keywords:
                names.append(kw.arg)
                syms.append(kw.value.value)
            if not names:
                return None
            target = ast.Tuple(
                elts=[ast.Name(id=n, ctx=ast.Store()) for n in names],
                ctx=ast.Store(),
            )
            value = ast.Call(
                func=ast.Name(id="__load__", ctx=ast.Load()),
                args=[
                    path,
                    ast.List(
                        elts=[ast.Constant(s) for s in syms], ctx=ast.Load()
                    ),
                ],
                keywords=[],
            )
            return ast.copy_location(
                ast.Assign(targets=[target], value=value), node
            )
        self.generic_visit(node)
        return node


def _glob_regex(pattern):
    segs = pattern.split("/")
    out = []
    for i, seg in enumerate(segs):
        last = i == len(segs) - 1
        if seg == "**":
            out.append(".*" if last else "(?:.*/)?")
            continue
        r = ""
        for ch in seg:
            if ch == "*":
                r += "[^/]*"
            elif ch == "?":
                r += "[^/]"
            else:
                r += re.escape(ch)
        out.append(r + ("" if last else "/"))
    return re.compile("".join(out))


def _main(argv):
    import paths  # noqa: F401  (same directory)

    P = paths.load()
    g = Graph(
        repo=P["REPO"],
        llvm_src=P["LLVM_SRC"],
        llvm_overlay=P["LLVM_OVERLAY"],
        llvm_build=P["LLVM_BUILD"],
        build_mode=P["CARBON_BUILD_MODE"],
    )
    if not argv:
        print(__doc__)
        return 2
    cmd = argv[0]
    if cmd == "files":
        for f in g.files_of(argv[1]):
            print(f.path)
    elif cmd == "manifest":
        sys.stdout.write(g.manifest_text(argv[1]))
    elif cmd == "bytes":
        for f in g.files_of(argv[1]):
            sys.stdout.buffer.write(g.file_bytes(f))
    elif cmd == "install-list":
        for f in g.files_of("//toolchain/install:all_data_files"):
            end = g.symlink_chain_end(f)
            print(
                "%s\t%s"
                % (
                    g.install_relative_path(f),
                    end.real_path or ("<generated> " + end.path),
                )
            )
    else:
        print("unknown command " + cmd)
        return 2
    return 0


# The builtins exposed to the Starlark-as-Python evaluation. Defined before the
# __main__ block below: when this file runs as a script, the block runs during
# module execution, so anything after it is not yet defined (REVIEW-1 R1-N1).
_SAFE_BUILTINS = {
    "True": True,
    "False": False,
    "None": None,
    "len": len,
    "range": range,
    "sorted": sorted,
    "reversed": reversed,
    "enumerate": enumerate,
    "zip": zip,
    "dict": dict,
    "list": list,
    "tuple": tuple,
    "int": int,
    "str": str,
    "bool": bool,
    "min": min,
    "max": max,
    "any": any,
    "all": all,
    "repr": repr,
    "abs": abs,
    "float": float,
    "hasattr": hasattr,
    "getattr": getattr,
    "dir": dir,
    "isinstance": isinstance,
    "set": set,
    "hash": hash,
    "Exception": Exception,
    "ValueError": ValueError,
    "TypeError": TypeError,
    "KeyError": KeyError,
    "AttributeError": AttributeError,
    "StopIteration": StopIteration,
    "__build_class__": __build_class__
    if "__build_class__" in dir(__builtins__)
    else None,
    "__name__": "starlark",
}


if __name__ == "__main__":
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    sys.exit(_main(sys.argv[1:]))

__copyright__ = """
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""

# Re-runs the evaluator FAQ's reproducers and checks the quoted diagnostics.
#
# Every diagnostic that docs/guides/evaluator_faq.md quotes has a reproducer
# here: a few lines of input, the commands an evaluator runs, the toolchains it
# applies to, and the exact line the toolchain prints. For the toolchain given,
# each applicable reproducer is run in a fresh temporary directory; the script
# then requires the expected line in the output and the same line inside a
# ```text block of the FAQ page. It exits 1 on any mismatch. It needs a
# toolchain, so `runner.py --self-test` does not run it (fork/evaluator/plan.md
# D-EV-21); run it with each toolchain:
#
#     python3 fork/evaluator/check_faq.py --which fork --toolchain <fork carbon>
#     python3 fork/evaluator/check_faq.py --which nightly --toolchain <nightly>

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FAQ = ROOT / "docs" / "guides" / "evaluator_faq.md"
PACKAGE = ROOT / "fork" / "conformance" / "programs" / "project"
PACKAGE = PACKAGE / "evaluator_tutorial_package"

FORTY_TWO = 'import Core library "io"; fn Run() { Core.Print(42); }\n'
HELLO = (
    'import Cpp library "<iostream>";\n\nfn Run() {\n'
    '  Cpp.std.cout << "Hello, world!\\n";\n}\n'
)
BUILD = "{c} compile --output=p.o p.carbon && {c} link --output=p p.o && ./p"
COMPILE = "{c} compile --output=p.o p.carbon"


def one(text: str) -> dict[str, str]:
    """A reproducer whose input is the one-line program p.carbon."""
    return {"p.carbon": text + "\n"}


# (id, toolchains, files, shell command, expected line, expected exit); an
# empty expected line checks the exit status only. Each input is the one
# line that the reproducer table of fork/evaluator/plan.md section 2.C shows.
REPRODUCERS = [
    (
        "printstr",
        "fork nightly",
        one(
            'import Core library "io"; '
            'fn Run() { Core.PrintStr("Hello, world!\\n"); }'
        ),
        BUILD,
        "ld.lld: error: undefined symbol: _CPrintStr.Core",
        1,
    ),
    (
        "header",
        "fork nightly",
        {
            "sub/seven.h": "int Seven();\n",
            "sub/main.carbon": 'import Cpp library "seven.h"; '
            "fn Run() -> i32 { return Cpp.Seven(); }\n",
        },
        "{c} compile --output=main.o sub/main.carbon",
        "error: 'seven.h' file not found",
        1,
    ),
    (
        "no-api",
        "fork nightly",
        "package",
        "{c} compile --output=main.o main.carbon",
        "error: imported API 'Geometry' not found",
        1,
    ),
    (
        "one-output",
        "fork nightly",
        "package",
        "{c} compile --output=y.o geometry.carbon geometry.impl.carbon "
        "main.carbon",
        "warning: only outputting main.carbon to y.o, skipping output of 2 "
        "input files; pass `--output-last-input-only` to silence this warning",
        0,
    ),
    (
        "gxx-object",
        "fork nightly",
        {
            "strlib.h": "int RepeatLength(int n);\n",
            "strlib.cpp": '#include <string>\n#include "strlib.h"\n'
            "int RepeatLength(int n) { std::string s; s.append(n, 'x'); "
            "return static_cast<int>(s.size()); }\n",
            "main.carbon": 'import Core library "io"; import Cpp library '
            '"strlib.h"; fn Run() { Core.Print(Cpp.RepeatLength(10)); }\n',
        },
        "g++ -c strlib.cpp -o strlib.o && "
        "{c} compile --output=main.o main.carbon && "
        "{c} link --output=main main.o strlib.o",
        "ld.lld: error: undefined symbol: std::__cxx11::basic_string<char, "
        "std::char_traits<char>, std::allocator<char>>::basic_string()",
        1,
    ),
    (
        "match-return",
        "fork",
        one(
            "choice Side { Left, Right } fn Sign(s: Side) -> i32 { match (s) "
            "{ case .Left => { return -1; } case .Right => { return 1; } } } "
            "fn Run() -> i32 { return Sign(Side.Right); }"
        ),
        COMPILE,
        "error: missing `return` at end of function with declared return type",
        1,
    ),
    (
        "match-default",
        "fork",
        one(
            "fn Pick(n: i32) -> i32 { match (n) { case 0 => { return 1; } "
            "default => { return 2; } } } fn Run() -> i32 { return Pick(0); }"
        ),
        BUILD,
        "",
        1,
    ),
    (
        "choice-payload",
        "nightly",
        one("choice C { A(x: i32), B } fn Run() {}"),
        COMPILE,
        "error: semantics TODO: `choice alternatives with parameters are not "
        "yet supported`",
        1,
    ),
    (
        "match",
        "nightly",
        one(
            "fn Run() -> i32 { match (1) { default => { return 0; } } "
            "return 0; }"
        ),
        COMPILE,
        "error: semantics TODO: `HandleMatchIntroducer`",
        1,
    ),
    (
        "result",
        "nightly",
        one(
            "fn Run() -> Core.Result((), i32) { "
            "return Core.Result((), i32).Ok(()); }"
        ),
        COMPILE,
        "error: member name `Result` not found in `Core`",
        1,
    ),
    (
        "if-let",
        "nightly",
        one("fn Run() -> i32 { if (let v: i32 = 3) { return v; } return 0; }"),
        COMPILE,
        "error: expected expression",
        1,
    ),
    (
        "union",
        "nightly",
        one("union U { var a: i32; var b: i32; } fn Run() {}"),
        COMPILE,
        "error: unrecognized declaration introducer",
        1,
    ),
    (
        "overload",
        "nightly",
        one(
            "overload fn F(unused n: i32) -> i32 { return 1; } "
            "overload fn F(unused b: bool) -> i32 { return 2; } "
            "fn Run() -> i32 { return F(true); }"
        ),
        COMPILE,
        "error: unrecognized declaration introducer",
        1,
    ),
    (
        "slice",
        "nightly",
        one(
            "fn Run() -> i32 { var a: array(i32, 2) = (3, 4); "
            "let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a); "
            "return s[0]; }"
        ),
        COMPILE,
        "error: member name `Slice` not found in `Core`",
        1,
    ),
    (
        "package-main",
        "fork nightly",
        one("package Main; fn Run() {}"),
        COMPILE,
        "error: `Main//default` must omit `package` declaration",
        1,
    ),
    (
        "result-exit",
        "fork",
        one(
            "fn Run() -> Core.Result((), i32) { "
            "return Core.Result((), i32).Err(7); }"
        ),
        BUILD,
        "carbon: `Main.Run` returned `.Err` of type `i32`; exiting with code 1",
        1,
    ),
    (
        "no-c-headers",
        "fork nightly",
        {"p.carbon": HELLO},
        COMPILE + " -- --sysroot=empty",
        "error: \"We don't know how to get the definition of mbstate_t on your "
        'platform."',
        1,
    ),
    (
        "no-start-files",
        "fork nightly",
        {"p.carbon": FORTY_TWO},
        COMPILE + " && {c} link --output=p p.o -- --sysroot=empty",
        "ld.lld: error: cannot open Scrt1.o: No such file or directory",
        1,
    ),
    (
        "short-o",
        "fork nightly",
        {"p.carbon": FORTY_TWO},
        "{c} build -o p p.carbon",
        "error: option `-o` (short for `--output`) requires a value to be "
        "provided and none was",
        1,
    ),
    (
        "windows-target",
        "fork nightly",
        {"p.carbon": FORTY_TWO},
        "{c} compile --target=x86_64-pc-windows-msvc --output=p.o p.carbon",
        "error: unsupported option '-fPIE' for target 'x86_64-pc-windows-msvc'",
        1,
    ),
]


def text_blocks(page: str) -> str:
    """Returns the bodies of the page's ```text blocks, concatenated."""
    out, inside = [], False
    for line in page.splitlines():
        if not inside and line.strip() == "```text":
            inside = True
        elif inside and line.strip() == "```":
            inside = False
        elif inside:
            out.append(line.strip())
    return "\n".join(out)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Re-runs the evaluator FAQ's reproducers with a toolchain."
    )
    parser.add_argument("--toolchain", required=True, type=Path)
    parser.add_argument("--which", required=True, choices=["fork", "nightly"])
    args = parser.parse_args()
    carbon = str(args.toolchain.resolve())
    quoted = text_blocks(FAQ.read_text())
    errors, ran = [], 0
    for rid, toolchains, files, command, expected, exit_code in REPRODUCERS:
        if expected and expected not in quoted:
            errors.append(f"{rid}: not quoted in a text block of {FAQ.name}")
        if args.which not in toolchains.split():
            continue
        if command.startswith("g++") and not shutil.which("g++"):
            print(f"{rid}: skipped, no g++ on PATH")
            continue
        with tempfile.TemporaryDirectory() as tmp:
            work = Path(tmp)
            (work / "empty").mkdir()
            # The only string `files` value is "package": the tutorial's
            # package files.
            if isinstance(files, str):
                for unit in PACKAGE.glob("*.carbon"):
                    shutil.copy(unit, work / unit.name)
            else:
                for name, text in files.items():
                    (work / name).parent.mkdir(parents=True, exist_ok=True)
                    (work / name).write_text(text)
            proc = subprocess.run(
                command.format(c=carbon),
                shell=True,
                cwd=work,
                capture_output=True,
                text=True,
                errors="replace",
            )
        ran += 1
        lines = (proc.stdout + proc.stderr).splitlines()
        if expected and not any(line.endswith(expected) for line in lines):
            errors.append(f"{rid}: expected line not printed: {expected}")
        if proc.returncode != exit_code:
            errors.append(
                f"{rid}: exit {proc.returncode}, expected {exit_code}"
            )
    for error in errors:
        print(error, file=sys.stderr)
    print(f"check_faq: {ran} reproducers run, {len(errors)} errors")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

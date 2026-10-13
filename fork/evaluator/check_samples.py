__copyright__ = """
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""

# Checks that the evaluator guides' code samples match their programs.
#
# Every ```carbon block in docs/guides/tutorial.md is a complete program
# transcribed byte for byte into fork/conformance/programs/project/ (rulebook
# R27: code is diffed against the documented spelling, not reviewed for
# meaning). This script compares each block with the program text after the
# program's leading comment block; compares each section's ```text block with
# the EXPECT-STDOUT of the section's last program; compares the ```cpp blocks
# with the C++ fixture files the C++-library build script compiles; requires
# the C++-library program's body to equal that fixture's main.carbon; rejects
# indented ```carbon fences on the three pages; and checks the README's
# forty_two command. It exits 1 on any error.
#
# Run it from anywhere as `python3 fork/evaluator/check_samples.py`. `main()`
# returns the exit status, so the script can also be imported: once PR 52's
# runner is on trunk, fork/evaluator/plan.md section 2.E.4 calls it from
# `runner.py --self-test`; until then it runs by hand and in the land sequence
# of fork/ORCHESTRATION.md.

import difflib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROGRAMS = ROOT / "fork" / "conformance" / "programs" / "project"
CPP_LIBRARY = ROOT / "fork" / "evaluator" / "cpp_library"
PAGES = (
    "docs/guides/getting_started.md",
    "docs/guides/tutorial.md",
    "docs/guides/evaluator_faq.md",
)

# The ```carbon blocks of each page, in page order, and the program each one
# is transcribed into.
SAMPLES = {
    "docs/guides/tutorial.md": [
        "evaluator_tutorial_hello.carbon",
        "evaluator_tutorial_functions.carbon",
        "evaluator_tutorial_classes.carbon",
        "evaluator_tutorial_generics.carbon",
        "evaluator_tutorial_choice_match.carbon",
        "evaluator_tutorial_errors.carbon",
        "evaluator_tutorial_interop_use_cpp.carbon",
        "evaluator_tutorial_cpp_library.carbon",
        "evaluator_tutorial_interop_call_carbon.carbon",
        "evaluator_tutorial_package/geometry.carbon",
        "evaluator_tutorial_package/geometry.impl.carbon",
        "evaluator_tutorial_package/main.carbon",
    ],
    "docs/guides/getting_started.md": [],
    "docs/guides/evaluator_faq.md": [],
}

# The ```cpp blocks of the tutorial, in page order, and their fixture files.
CPP_SAMPLES = ["rectangle.h", "rectangle.cpp"]

# check-header-guards (scripts/check_header_guards.py) names a fixture's
# guard after its path; the page shows the guard a reader would write.
GUARD_IN_FIXTURE = "CARBON_FORK_EVALUATOR_CPP_LIBRARY_RECTANGLE_H_"
GUARD_ON_PAGE = "RECTANGLE_H_"

# The README's first program, written by a shell `echo`; the guide repeats
# the command verbatim and evaluator_docs_getting_started.carbon holds what
# it writes.
FORTY_TWO_ECHO = (
    'echo "import Core library \\"io\\"; fn Run() { Core.Print(42); }"'
    " > forty_two.carbon"
)
FORTY_TWO_BODY = 'import Core library "io"; fn Run() { Core.Print(42); }\n'

FENCE = re.compile(r"^(\s*)```(\w*)\s*$")


def fenced_blocks(text: str) -> list[tuple[int, str, str, str]]:
    """Returns (line, language, body, H2 section) for each fenced block."""
    blocks = []
    section = ""
    current = None
    for number, line in enumerate(text.splitlines(keepends=True), 1):
        if current is None:
            if line.startswith("## "):
                section = line[3:].strip()
            m = FENCE.match(line.rstrip("\n"))
            if m and m.group(2):
                current = (number, m.group(1), m.group(2), [])
        elif line.strip() == "```":
            start, indent, lang, body = current
            blocks.append((start, indent + lang, "".join(body), section))
            current = None
        else:
            current[3].append(line)
    if current is not None:
        raise ValueError(f"unterminated fenced block at line {current[0]}")
    return blocks


def strip_leading_comments(text: str) -> str:
    """Drops the leading comment block and the blank lines around it."""
    lines = text.splitlines(keepends=True)
    i = 0
    while i < len(lines) and (
        lines[i].startswith("//") or not lines[i].strip()
    ):
        i += 1
    return "".join(lines[i:])


def expected_stdout(program: str) -> str:
    """Returns the EXPECT-STDOUT lines of a program's header, joined."""
    lines = []
    inside = False
    for line in program.splitlines():
        if line == "// EXPECT-STDOUT:":
            inside = True
        elif inside and line.startswith("//   "):
            lines.append(line[len("//   ") :] + "\n")
        elif inside:
            break
    return "".join(lines)


def diff(a: str, b: str, a_name: str, b_name: str) -> str:
    return "".join(
        difflib.unified_diff(
            a.splitlines(keepends=True),
            b.splitlines(keepends=True),
            fromfile=a_name,
            tofile=b_name,
        )
    )


def main() -> int:
    errors = []
    checked = 0
    for page in PAGES:
        blocks = fenced_blocks((ROOT / page).read_text())
        for line, lang, _, _ in blocks:
            if lang != lang.lstrip():
                errors.append(f"{page}:{line}: indented ```{lang.strip()}")
        carbon = [b for b in blocks if b[1] == "carbon"]
        programs = SAMPLES[page]
        if len(carbon) != len(programs):
            errors.append(
                f"{page}: {len(carbon)} carbon blocks, {len(programs)} mapped"
            )
            continue
        last_program_in = {}
        for (line, _, body, section), program in zip(carbon, programs):
            text = (PROGRAMS / program).read_text()
            checked += 1
            if body != strip_leading_comments(text):
                errors.append(
                    diff(
                        body,
                        strip_leading_comments(text),
                        f"{page}:{line}",
                        program,
                    )
                )
            last_program_in[section] = text
        for section, text in last_program_in.items():
            outputs = [b for b in blocks if b[1] == "text" and b[3] == section]
            if len(outputs) != 1:
                errors.append(
                    f"{page}: section {section!r} has {len(outputs)} text "
                    "blocks, expected 1"
                )
            elif outputs[0][2] != expected_stdout(text):
                errors.append(
                    diff(
                        outputs[0][2],
                        expected_stdout(text),
                        f"{page}:{outputs[0][0]}",
                        f"EXPECT-STDOUT of section {section!r}",
                    )
                )
        if page == "docs/guides/tutorial.md":
            cpp = [b for b in blocks if b[1] == "cpp"]
            if len(cpp) != len(CPP_SAMPLES):
                errors.append(
                    f"{page}: {len(cpp)} cpp blocks, {len(CPP_SAMPLES)} mapped"
                )
            for (line, _, body, _), name in zip(cpp, CPP_SAMPLES):
                fixture = strip_leading_comments(
                    (CPP_LIBRARY / name).read_text()
                ).replace(GUARD_IN_FIXTURE, GUARD_ON_PAGE)
                checked += 1
                if body != fixture:
                    errors.append(diff(body, fixture, f"{page}:{line}", name))
    program = PROGRAMS / "evaluator_tutorial_cpp_library.carbon"
    fixture = CPP_LIBRARY / "main.carbon"
    if strip_leading_comments(program.read_text()) != strip_leading_comments(
        fixture.read_text()
    ):
        errors.append(f"{program.name}: body differs from {fixture}")
    for page in ("README.md", "docs/guides/getting_started.md"):
        if FORTY_TWO_ECHO not in (ROOT / page).read_text():
            errors.append(f"{page}: the forty_two echo command is missing")
    getting_started = PROGRAMS / "evaluator_docs_getting_started.carbon"
    if strip_leading_comments(getting_started.read_text()) != FORTY_TWO_BODY:
        errors.append(f"{getting_started.name}: body is not the echo's output")
    for error in errors:
        print(error, file=sys.stderr)
    print(f"check_samples: {checked} samples, {len(errors)} errors")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

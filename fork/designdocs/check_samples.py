__copyright__ = """
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""

# Checks the design pages that DD-1 (fork/designdocs/plan.md, W-065) wrote
# against their programs and fixtures, and checks docs/design/ for
# placeholders.
#
# Every new ```carbon block on a DD-1 page is a complete file. A block that
# runs is transcribed byte for byte into a conformance program under
# fork/conformance/programs/project/, and a block that the toolchain rejects
# is the body of a fixture under fork/designdocs/samples/ whose header pins
# the first error message, which the page quotes (rulebook R27: code is
# diffed against the documented spelling). Quote fixtures pin a sentence of
# the page instead. The default run needs no toolchain:
#
# 1. each program block equals its program's text after the leading comment
#    block, and each block fixture's body equals its page block;
# 2. each fixture's QUOTE and EXPECT-ERROR message occur in the prose of its
#    section, compared after blockquote markers are stripped and whitespace
#    is collapsed, and the backticked values of the "This prints ..."
#    sentence of each program's section equal its EXPECT-STDOUT lines;
# 3. each mapped section has exactly the ```carbon blocks the table maps, and
#    no indented ```carbon fence;
# 4. the W2 rule (plan section 2.12 item 5) over docs/design/, matched
#    without regard to case: (a) no placeholder boilerplate, also when a
#    phrase wraps across blockquote lines or is split by emphasis or code
#    markers; (b) no heading that starts with TODO or TBD, also after
#    leading emphasis or code markers; (c) no section whose paragraphs are
#    only TODO or TBD markers (in a blockquote, a list item or an HTML
#    comment too), optionally with "See" or "References" paragraphs and the
#    lists of links that follow them; and (d) no empty section without
#    subsections; except the hits that QUALIFIED and ALLOWLIST name. An
#    entry of either list that no longer hits is an error, so neither list
#    can go stale.
#
# `--toolchain PATH` also compiles every fixture: an EXPECT-ERROR fixture must
# fail with its pinned message on the first error line, and an EXPECT-STDOUT
# fixture must compile, link, run with exit 0 and print the pinned lines.
# `--self-check` runs only the built-in cases of the quote matcher and of the
# W2 rule, which every default run also runs first. The script exits 1 on any
# error, and `main()` returns the exit status.
#
# Run it from anywhere as `python3 fork/designdocs/check_samples.py`.

import argparse
import concurrent.futures
import dataclasses
import difflib
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DESIGN = ROOT / "docs" / "design"
PROGRAMS = ROOT / "fork" / "conformance" / "programs" / "project"
FIXTURES = ROOT / "fork" / "designdocs" / "samples"

# Kinds of SAMPLES entries. A `program` or `block` entry maps the next
# ```carbon block of its section; an `upstream` entry stands for an unchanged
# upstream block of a section that DD-1 annotates, so that check 3 still
# counts every block; a `quote` entry maps no block.
PROGRAM = "program"
BLOCK = "block"
QUOTE = "quote"
UPSTREAM = "upstream"

INTEROP = "interoperability/README.md"

# (page under docs/design/, section heading, kind, target), in page order.
SAMPLES = [
    (
        "aliases.md",
        "Aliases in the 0.1 toolchain",
        PROGRAM,
        "design_docs_aliases.carbon",
    ),
    (
        "aliases.md",
        "Aliases in the 0.1 toolchain",
        BLOCK,
        "R01_alias_runtime.carbon",
    ),
    (
        "aliases.md",
        "Aliases in the 0.1 toolchain",
        BLOCK,
        "R02_alias_params.carbon",
    ),
    (
        "aliases.md",
        "Aliases in the 0.1 toolchain",
        BLOCK,
        "R03_alias_decl_scope.carbon",
    ),
    (
        "blocks_and_statements.md",
        "Statements in the 0.1 toolchain",
        PROGRAM,
        "design_docs_statements.carbon",
    ),
    (
        "blocks_and_statements.md",
        "Statements in the 0.1 toolchain",
        BLOCK,
        "R05_scope_end.carbon",
    ),
    (
        "blocks_and_statements.md",
        "Statements in the 0.1 toolchain",
        BLOCK,
        "R06_missing_return.carbon",
    ),
    (
        "blocks_and_statements.md",
        "Statements in the 0.1 toolchain",
        BLOCK,
        "R04_nested_block.carbon",
    ),
    (
        "assignment.md",
        "Tuples, structs, choice types, and data classes",
        PROGRAM,
        "design_docs_assignment.carbon",
    ),
    (
        "assignment.md",
        "Tuples, structs, choice types, and data classes",
        BLOCK,
        "R07_class_copy.carbon",
    ),
    (
        "assignment.md",
        "Tuples, structs, choice types, and data classes",
        QUOTE,
        "X01_swap_literal.carbon",
    ),
    (
        "assignment.md",
        "Tuples, structs, choice types, and data classes",
        QUOTE,
        "X03_swap_let.carbon",
    ),
    (
        "templates.md",
        "Functions with template parameters",
        QUOTE,
        "R11_template_f32.carbon",
    ),
    (
        "templates.md",
        "Templates in the 0.1 toolchain",
        PROGRAM,
        "design_docs_templates.carbon",
    ),
    (
        "templates.md",
        "Templates in the 0.1 toolchain",
        BLOCK,
        "R08_template_missing_member.carbon",
    ),
    (
        "templates.md",
        "Templates in the 0.1 toolchain",
        BLOCK,
        "R10_checked_member.carbon",
    ),
    (
        "templates.md",
        "Templates in the 0.1 toolchain",
        QUOTE,
        "X07_template_let_file_scope.carbon",
    ),
    (
        "templates.md",
        "Templates in the 0.1 toolchain",
        QUOTE,
        "X08_template_auto.carbon",
    ),
    (
        "templates.md",
        "Templates in the 0.1 toolchain",
        BLOCK,
        "R09_template_constraint_lookup.carbon",
    ),
    (
        "templates.md",
        "Templates in the 0.1 toolchain",
        QUOTE,
        "X05_template_structural_circle.carbon",
    ),
    (
        "metaprogramming.md",
        "Compile-time evaluation in the 0.1 toolchain",
        PROGRAM,
        "design_docs_compile_time.carbon",
    ),
    (
        "metaprogramming.md",
        "Compile-time evaluation in the 0.1 toolchain",
        BLOCK,
        "R12_musteval_runtime.carbon",
    ),
    (
        "metaprogramming.md",
        "Compile-time evaluation in the 0.1 toolchain",
        BLOCK,
        "R13_not_eval.carbon",
    ),
    (
        "metaprogramming.md",
        "Compile-time evaluation in the 0.1 toolchain",
        BLOCK,
        "R14_local_template_let.carbon",
    ),
    (
        "pattern_matching.md",
        "Pattern match control flow",
        BLOCK,
        "X02_match_first_example.carbon",
    ),
    (
        "pattern_matching.md",
        "Pattern match control flow",
        UPSTREAM,
        "the section's second `match` example, unchanged",
    ),
    (
        "pattern_matching.md",
        "`match` in the 0.1 toolchain",
        PROGRAM,
        "design_docs_match.carbon",
    ),
    (
        "pattern_matching.md",
        "`match` in the 0.1 toolchain",
        BLOCK,
        "R15_match_nonexhaustive_choice.carbon",
    ),
    (
        "pattern_matching.md",
        "`match` in the 0.1 toolchain",
        BLOCK,
        "R16_match_int_no_default.carbon",
    ),
    (
        "pattern_matching.md",
        "`match` in the 0.1 toolchain",
        BLOCK,
        "R17_match_never_matches.carbon",
    ),
    (
        "pattern_matching.md",
        "`match` in the 0.1 toolchain",
        BLOCK,
        "R18_match_dead_default.carbon",
    ),
    (
        "pattern_matching.md",
        "`match` in the 0.1 toolchain",
        BLOCK,
        "R19_match_guard_parens.carbon",
    ),
    (
        "pattern_matching.md",
        "`match` in the 0.1 toolchain",
        BLOCK,
        "R20_match_exhaustive_return.carbon",
    ),
    (
        "pattern_matching.md",
        "`match` in the 0.1 toolchain",
        BLOCK,
        "R21_match_tuple_alternatives.carbon",
    ),
    (
        "pattern_matching.md",
        "`match` in the 0.1 toolchain",
        BLOCK,
        "R22_match_scrutinee_type.carbon",
    ),
    (
        "pattern_matching.md",
        "`match` in the 0.1 toolchain",
        QUOTE,
        "X06_match_qualified_alternative.carbon",
    ),
    (
        INTEROP,
        "Importing C++ code (inline)",
        PROGRAM,
        "design_docs_cpp_inline.carbon",
    ),
    (
        INTEROP,
        "Importing C++ code (inline)",
        QUOTE,
        "X04_cpp_inline_escapes.carbon",
    ),
    (
        INTEROP,
        "Importing C++ code (inline)",
        BLOCK,
        "R32_cpp_inline_no_import.carbon",
    ),
    (INTEROP, "Constructors", PROGRAM, "design_docs_cpp_constructors.carbon"),
    (INTEROP, "Constructors", BLOCK, "R23_cpp_explicit_ctor.carbon"),
    (
        INTEROP,
        "Struct literals",
        PROGRAM,
        "design_docs_cpp_struct_literals.carbon",
    ),
    (INTEROP, "Struct literals", BLOCK, "R24_cpp_struct_literal.carbon"),
    (
        INTEROP,
        "Accessing C++ classes, structs, and members",
        PROGRAM,
        "design_docs_cpp_members.carbon",
    ),
    (
        INTEROP,
        "Accessing C++ classes, structs, and members",
        BLOCK,
        "R25_cpp_private.carbon",
    ),
    (
        INTEROP,
        "Accessing C++ classes, structs, and members",
        BLOCK,
        "R26_cpp_nonconst_on_value.carbon",
    ),
    (
        INTEROP,
        "Accessing global variables",
        PROGRAM,
        "design_docs_cpp_globals.carbon",
    ),
    (
        INTEROP,
        "Accessing global variables",
        BLOCK,
        "R27_cpp_const_global.carbon",
    ),
    (
        INTEROP,
        "Using C++ templates",
        PROGRAM,
        "design_docs_cpp_templates.carbon",
    ),
    (
        INTEROP,
        "Using C++ templates",
        QUOTE,
        "X09_cpp_template_symbolic_arg.carbon",
    ),
    (
        INTEROP,
        "Using Carbon from C++",
        PROGRAM,
        "design_docs_carbon_from_cpp.carbon",
    ),
    (
        INTEROP,
        "Using Carbon from C++",
        BLOCK,
        "R33_cpp_export_nontype_generic.carbon",
    ),
    (INTEROP, "Integers", PROGRAM, "design_docs_cpp_integers.carbon"),
    (INTEROP, "Integers", BLOCK, "R28_cpp_long_long.carbon"),
    (
        INTEROP,
        "Advanced type mapping: pointers, references, and `const`",
        PROGRAM,
        "design_docs_cpp_pointers.carbon",
    ),
    (
        INTEROP,
        "Advanced type mapping: pointers, references, and `const`",
        BLOCK,
        "R29_cpp_ref_marker.carbon",
    ),
    (
        INTEROP,
        "C++ ranges in `for` loops",
        PROGRAM,
        "design_docs_cpp_ranges.carbon",
    ),
    (
        INTEROP,
        "C++ ranges in `for` loops",
        BLOCK,
        "R34_cpp_pointer_range.carbon",
    ),
    (
        INTEROP,
        "The operator interoperability model",
        PROGRAM,
        "design_docs_cpp_operators.carbon",
    ),
    (
        INTEROP,
        "The operator interoperability model",
        BLOCK,
        "R30_cpp_assign_operator.carbon",
    ),
    (
        "interoperability/threads_and_atomics.md",
        "In the 0.1 toolchain",
        PROGRAM,
        "design_docs_cpp_threads.carbon",
    ),
    ("README.md", "Enums", PROGRAM, "design_docs_cpp_enums.carbon"),
]

# W2 hits that stay by design because a DD-1 note in the same section answers
# them: (page, section, clause) -> the note's quoted text, which must occur in
# that section.
QUALIFIED = {
    ("README.md", "This document is provisional", "a"): (
        "In this fork, what is provisional is marked in place"
    ),
}

# W2 hits that a later DD-1 commit or a held PR removes: (page, section,
# clause) -> who removes it. The list shrinks commit by commit (plan section
# 2.12 item 5) and is empty at state L.
ALLOWLIST = {
    ("README.md", "Lifetime and move semantics", "c"): "held PR 53 (SAFE-1)",
    ("expressions/arithmetic.md", "Strings", "c"): "held PR 55 (ST-1)",
}

# The quote of the README disclosure's QUALIFIED entry, also used by the
# matcher self-check.
DISCLOSURE_QUOTE = QUALIFIED[("README.md", "This document is provisional", "a")]

# Clause (a), matched without regard to case, over each file's text after
# leading blockquote markers are stripped from every line and the emphasis and
# code markers `*`, `_` and backtick are removed.
BOILERPLATE = re.compile(
    r"skeletal\s+design|it\s+is\s+a\s+placeholder|"
    r"should\s+not\s+be\s+treated\s+as\s+accepted|"
    r"Please\s+feel\s+welcome\s+to\s+rewrite|provisional\s+or\s+placeholder",
    re.IGNORECASE,
)
# Clause (c): a paragraph that starts with a TODO or TBD marker, optionally
# bold or italic, inside a blockquote, a list item or an HTML comment.
TODO_MARKER = re.compile(
    r"^(>\s*)*([-*+]\s+|[0-9]+[.)]\s+)?(<!--\s*)?[*_]*(TODO|TBD)",
    re.IGNORECASE,
)
# Clause (b): a heading that starts with TODO or TBD after leading emphasis
# or code markers.
HEADING_MARKER = re.compile(r"^[*_`\s]*(TODO|TBD)", re.IGNORECASE)
# Clause (c)'s optional companions: a "See ..." or "References" paragraph,
# matched without regard to case, also inside a blockquote, and a list whose
# every item holds a link, when it follows a companion.
SEE_MARKER = re.compile(r"^(>\s*)*(See|References)\b", re.IGNORECASE)
LIST_ITEM = re.compile(r"^(>\s*)*\s*([-*+]|[0-9]+[.)])\s+")
LINK = re.compile(r"\[[^\]]*\]\(|<https?://")
# The sentence that states a program's output, up to its first `.`, `:` or
# `;` outside a code span.
PRINTS = re.compile(r"This prints ((?:`[^`]*`|[^`.:;])*)")
HEADING = re.compile(r"^(#{1,6}) (.*)$")
FENCE = re.compile(r"^\s*(`{3,}|~{3,})")
BLOCKQUOTE = re.compile(r"^\s*>\s?")


def fence_mask(lines: list[str]) -> list[bool]:
    """Returns, per line, whether it is a fence line or inside a fence."""
    mask = []
    fence = None
    for line in lines:
        m = FENCE.match(line)
        if m:
            token = m.group(1)
            if fence is None:
                fence = token
                mask.append(True)
                continue
            if (
                token[0] == fence[0]
                and len(token) >= len(fence)
                and line.strip() == token
            ):
                fence = None
                mask.append(True)
                continue
        mask.append(fence is not None)
    return mask


def heading_levels(
    lines: list[str], mask: list[bool]
) -> list[tuple[int, int, str]]:
    """Returns (index, level, text) for each heading line outside fences."""
    result = []
    for i, line in enumerate(lines):
        if not mask[i]:
            m = HEADING.match(line)
            if m:
                result.append((i, len(m.group(1)), str(m.group(2)).strip()))
    return result


def headings(lines: list[str], mask: list[bool]) -> list[tuple[int, str]]:
    """Returns (index, text) for each heading line outside fences."""
    return [(i, text) for i, _, text in heading_levels(lines, mask)]


def strip_quote_markers(line: str) -> str:
    """Strips every leading blockquote marker of one line."""
    while True:
        new = BLOCKQUOTE.sub("", line, count=1)
        if new == line:
            return line
        line = new


def normalize(text: str) -> str:
    """Strips leading blockquote markers per line, then collapses spaces."""
    stripped = [strip_quote_markers(line) for line in text.split("\n")]
    return re.sub(r"\s+", " ", " ".join(stripped)).strip()


def contains(prose: str, quote: str) -> bool:
    return normalize(quote) in normalize(prose)


def is_link_list(paragraph: list[str]) -> bool:
    """Returns whether a paragraph is a list whose every item holds a link."""
    if not LIST_ITEM.match(paragraph[0]):
        return False
    items: list[str] = []
    for line in paragraph:
        if LIST_ITEM.match(line):
            items.append(line)
        elif line[:1] in (" ", "\t", ">"):
            items[-1] += " " + line.strip()
        else:
            return False
    return all(LINK.search(item) for item in items)


def strip_leading_comments(text: str) -> str:
    """Drops the leading comment block and the blank lines around it."""
    lines = text.splitlines(keepends=True)
    i = 0
    while i < len(lines) and (
        lines[i].startswith("//") or not lines[i].strip()
    ):
        i += 1
    return "".join(lines[i:])


@dataclasses.dataclass
class Fixture:
    """The header fields and body of a fixture."""

    sample: str | None = None
    error: str | None = None
    stdout: list[str] | None = None
    quote: str | None = None
    body: str = ""


def parse_fixture(path: Path) -> Fixture:
    """Returns the header fields and body of a fixture."""
    fixture = Fixture()
    stdout: list[str] = []
    in_stdout = False
    for line in path.read_text().splitlines():
        if not line.startswith("//"):
            if line.strip():
                break
            continue
        if in_stdout and line.startswith("//   "):
            stdout.append(line[len("//   ") :])
            continue
        in_stdout = False
        if line.startswith("// DESIGN-DOCS-SAMPLE: "):
            fixture.sample = line[len("// DESIGN-DOCS-SAMPLE: ") :]
        elif line.startswith("// EXPECT-ERROR: "):
            fixture.error = line[len("// EXPECT-ERROR: ") :]
        elif line == "// EXPECT-STDOUT:":
            fixture.stdout = stdout
            in_stdout = True
        elif line.startswith("// QUOTE: "):
            fixture.quote = line[len("// QUOTE: ") :]
    fixture.body = strip_leading_comments(path.read_text())
    return fixture


class Section:
    """The lines between a heading and the next heading of any level."""

    def __init__(self, page: str, heading: str):
        self.page = page
        self.heading = heading
        lines = (DESIGN / page).read_text().split("\n")
        mask = fence_mask(lines)
        heads = headings(lines, mask)
        found = [k for k, (_, text) in enumerate(heads) if text == heading]
        if len(found) != 1:
            raise ValueError(
                f"docs/design/{page}: {len(found)} headings {heading!r}"
            )
        k = found[0]
        start = heads[k][0] + 1
        end = heads[k + 1][0] if k + 1 < len(heads) else len(lines)
        self.start_line = start + 1
        self.lines = lines[start:end]
        self.mask = mask[start:end]
        self.blocks = []
        self.indented = []
        body = None
        for i, line in enumerate(self.lines):
            if body is None:
                if line == "```carbon":
                    body = []
                elif re.match(r"^\s+```carbon\s*$", line):
                    self.indented.append(self.start_line + i)
            elif line == "```":
                self.blocks.append("".join(body))
                body = None
            else:
                body.append(line + "\n")
        self.prose = "\n".join(
            line for line, fenced in zip(self.lines, self.mask) if not fenced
        )


def diff(a: str, b: str, a_name: str, b_name: str) -> str:
    return "".join(
        difflib.unified_diff(
            a.splitlines(keepends=True),
            b.splitlines(keepends=True),
            fromfile=a_name,
            tofile=b_name,
        )
    ).rstrip("\n")


def printed_values(prose: str) -> list[str] | None:
    """Returns the backticked values of the first "This prints" sentence."""
    m = PRINTS.search(normalize(prose))
    if m is None:
        return None
    return re.findall(r"`([^`]*)`", m.group(1))


def check_prints(
    section: Section, where: str, target: str, errors: list[str]
) -> None:
    """Checks that the section states its program's EXPECT-STDOUT lines."""
    stated = printed_values(section.prose)
    expected = parse_fixture(PROGRAMS / target).stdout
    if stated is None:
        errors.append(f"{where}: no 'This prints' sentence for {target}")
    elif stated != expected:
        errors.append(
            f"{where}: the page says it prints {stated}, but {target} "
            f"expects {expected}"
        )


def check_samples(errors: list[str]) -> tuple[int, list[Path]]:
    """Checks 1 to 3; returns the program count and the fixtures checked."""
    sections: dict[tuple[str, str], Section] = {}
    consumed: dict[tuple[str, str], int] = {}
    programs = 0
    fixtures = []
    for page, heading, kind, target in SAMPLES:
        key = (page, heading)
        if key not in sections:
            try:
                sections[key] = Section(page, heading)
            except ValueError as e:
                errors.append(str(e))
                continue
            consumed[key] = 0
        section = sections[key]
        where = f"docs/design/{page} ({heading!r})"
        block = None
        if kind in (PROGRAM, BLOCK, UPSTREAM):
            n = consumed[key]
            consumed[key] += 1
            if n < len(section.blocks):
                block = section.blocks[n]
            else:
                errors.append(f"{where}: no carbon block {n + 1} for {target}")
        if kind == PROGRAM:
            programs += 1
            text = strip_leading_comments((PROGRAMS / target).read_text())
            if block is not None and block != text:
                errors.append(diff(block, text, where, target))
            check_prints(section, where, target, errors)
            continue
        if kind == UPSTREAM:
            continue
        path = FIXTURES / target
        if not path.is_file():
            errors.append(f"{where}: fixture {target} not found")
            continue
        fixtures.append(path)
        fixture = parse_fixture(path)
        expected = f'docs/design/{page}, "{heading}", {kind}'
        if fixture.sample != expected:
            errors.append(
                f"{target}: DESIGN-DOCS-SAMPLE is "
                f"{fixture.sample!r}, expected {expected!r}"
            )
        if (fixture.error is None) == (fixture.stdout is None):
            errors.append(
                f"{target}: needs exactly one of EXPECT-ERROR and EXPECT-STDOUT"
            )
        if kind == BLOCK and block is not None and block != fixture.body:
            errors.append(diff(block, fixture.body, where, target))
        if kind == QUOTE and fixture.quote is None:
            errors.append(f"{target}: a quote fixture needs a QUOTE line")
        quotes = [q for q in (fixture.quote, fixture.error) if q is not None]
        if not quotes:
            errors.append(f"{target}: nothing to quote in {where}")
        for quote in quotes:
            if not contains(section.prose, quote):
                errors.append(f"{where}: does not quote {target}: {quote}")
    for key, section in sections.items():
        where = f"docs/design/{key[0]} ({key[1]!r})"
        if len(section.blocks) != consumed[key]:
            errors.append(
                f"{where}: {len(section.blocks)} carbon blocks, "
                f"{consumed[key]} mapped"
            )
        for line in section.indented:
            errors.append(f"docs/design/{key[0]}:{line}: indented ```carbon")
    mapped = {
        target for _, _, kind, target in SAMPLES if kind in (BLOCK, QUOTE)
    }
    for path in sorted(FIXTURES.glob("*.carbon")):
        if path.name not in mapped:
            errors.append(f"{path.name}: fixture not in SAMPLES")
    return programs, fixtures


def w2_file_hits(rel: str, text: str) -> set[tuple[str, str, str]]:
    """Applies the W2 rule to one page; `rel` names it in the hits."""
    hits: set[tuple[str, str, str]] = set()
    lines = text.split("\n")
    mask = fence_mask(lines)
    heads = heading_levels(lines, mask)

    def section_at(index: int) -> str:
        name = ""
        for i, _, heading in heads:
            if i <= index:
                name = heading
        return name

    # (a) placeholder boilerplate anywhere in the file, also when a phrase
    # wraps across the lines of a blockquote.
    unquoted = "\n".join(strip_quote_markers(line) for line in lines)
    unquoted = re.sub(r"[*_`]", "", unquoted)
    for m in BOILERPLATE.finditer(unquoted):
        line = unquoted.count("\n", 0, m.start())
        hits.add((rel, section_at(line), "a"))
    for k, (i, level, heading) in enumerate(heads):
        # (b) a heading that starts with TODO or TBD.
        if HEADING_MARKER.match(heading):
            hits.add((rel, heading, "b"))
        # (c) a section whose paragraphs are all TODO or TBD markers, with
        # optional "See ..." or "References" paragraphs and the link lists
        # that follow them. A fenced block is one paragraph that is not a
        # marker.
        end = heads[k + 1][0] if k + 1 < len(heads) else len(lines)
        paragraphs: list[list[str]] = []
        current: list[str] = []
        for j in range(i + 1, end):
            line = lines[j]
            if not mask[j] and line.strip() in ("", ">"):
                if current:
                    paragraphs.append(current)
                    current = []
            else:
                current.append(line)
        if current:
            paragraphs.append(current)
        markers = 0
        companion = False
        all_marked = True
        for p in paragraphs:
            if TODO_MARKER.match(p[0]):
                markers += 1
                companion = False
            elif SEE_MARKER.match(p[0]) or (companion and is_link_list(p)):
                companion = True
            else:
                all_marked = False
                break
        if paragraphs and all_marked and markers:
            hits.add((rel, heading, "c"))
        # (d) an empty section with no subsection: the next heading, if
        # any, is at the same or a higher level.
        if not paragraphs and (k + 1 == len(heads) or heads[k + 1][1] <= level):
            hits.add((rel, heading, "d"))
    return hits


def w2_hits(root: Path = DESIGN) -> set[tuple[str, str, str]]:
    """Applies the W2 rule to every page under `root` (docs/design/)."""
    hits: set[tuple[str, str, str]] = set()
    for path in sorted(root.rglob("*.md")):
        hits |= w2_file_hits(
            path.relative_to(root).as_posix(), path.read_text()
        )
    return hits


def check_w2(errors: list[str]) -> tuple[list[str], int]:
    """Check 4; returns a report line per accepted hit, and the hit count."""
    hits = w2_hits()
    report = []
    for key in sorted(hits):
        page, heading, clause = key
        name = f"docs/design/{page} | {heading or '(top)'} | ({clause})"
        if key in QUALIFIED:
            quote = QUALIFIED[key]
            if contains(Section(page, heading).prose, quote):
                report.append(f"W2 qualified: {name}: {quote!r}")
            else:
                errors.append(f"W2 qualified hit without its note: {name}")
        elif key in ALLOWLIST:
            report.append(f"W2 allowlisted: {name}: {ALLOWLIST[key]}")
        else:
            errors.append(f"W2 hit: {name}")
    for key in sorted(set(QUALIFIED) | set(ALLOWLIST)):
        if key not in hits:
            page, heading, clause = key
            errors.append(
                f"W2 entry no longer hits: docs/design/{page} | {heading} "
                f"| ({clause})"
            )
    return report, len(hits)


def first_error(stderr: str) -> str | None:
    for line in stderr.splitlines():
        m = re.search(r"\berror: (.*)$", line)
        if m:
            return str(m.group(1))
    return None


def run_fixture(toolchain: Path, path: Path, tmp: Path) -> str | None:
    """Compiles (and links and runs) one fixture; returns an error or None."""
    fixture = parse_fixture(path)
    obj = tmp / (path.stem + ".o")
    exe = tmp / path.stem
    compiled = subprocess.run(
        [
            str(toolchain),
            "compile",
            f"--output={obj}",
            "--output-last-input-only",
            str(path),
        ],
        capture_output=True,
        text=True,
        timeout=300,
    )
    if fixture.error is not None:
        got = first_error(compiled.stderr)
        if compiled.returncode == 0:
            return f"{path.name}: compiled, expected error: {fixture.error}"
        if got != fixture.error:
            return (
                f"{path.name}: first error {got!r}, expected "
                f"{fixture.error!r} (exit {compiled.returncode})"
            )
        return None
    if compiled.returncode != 0:
        return f"{path.name}: compile failed: {first_error(compiled.stderr)}"
    linked = subprocess.run(
        [str(toolchain), "link", f"--output={exe}", str(obj)],
        capture_output=True,
        text=True,
        timeout=1800,
    )
    if linked.returncode != 0:
        return f"{path.name}: link failed: {linked.stderr.strip()[:200]}"
    ran = subprocess.run([str(exe)], capture_output=True, text=True, timeout=60)
    want = "".join(line + "\n" for line in fixture.stdout or [])
    if ran.returncode != 0 or ran.stdout != want:
        return (
            f"{path.name}: exit {ran.returncode}, printed {ran.stdout!r}, "
            f"expected exit 0 and {want!r}"
        )
    return None


def check_toolchain(
    toolchain: Path, fixtures: list[Path], errors: list[str]
) -> None:
    """Runs every fixture on the toolchain (XDG_CACHE_HOME is honored)."""
    with tempfile.TemporaryDirectory() as tmp:
        with concurrent.futures.ThreadPoolExecutor(
            max_workers=min(8, os.cpu_count() or 1)
        ) as pool:
            results = pool.map(
                lambda path: run_fixture(toolchain, path, Path(tmp)), fixtures
            )
            errors.extend(r for r in results if r is not None)


def self_check() -> int:
    """Runs the built-in quote and W2 cases; returns the wrong count."""
    two_lines = (
        "> In this fork, what is provisional is marked in\n"
        "> place. Each former placeholder"
    )
    nested = "\n".join("> " + line for line in two_lines.split("\n"))
    sentence = (
        "the toolchain rejects this instantiation with ``unable to "
        "monomorphize specific `Convert(i32, f32)` ``. The same function"
    )
    cases = [
        (two_lines, DISCLOSURE_QUOTE, True),
        (nested, DISCLOSURE_QUOTE, True),
        (sentence, "unable to monomorphize specific `Convert(i32, f32)`", True),
        (
            sentence,
            "unable to monomorphize specific `Convert(i32, f64)`",
            False,
        ),
    ]
    wrong = 0
    for text, quote, want in cases:
        if contains(text, quote) != want:
            wrong += 1
            print(f"self-check: wrong answer for {quote!r}", file=sys.stderr)
    # The W2 rule on built-in pages: (page text, the hits it must give).
    w2_cases = [
        ("# T\n\n## S\n\nThis page is a skeletal\ndesign.\n", {("S", "a")}),
        ("## S\n\n> This page is a skeletal\n> design.\n", {("S", "a")}),
        ("## S\n\nIt has Provisional or\nplaceholder text.\n", {("S", "a")}),
        ("## Todo: later\n\nText.\n", {("Todo: later", "b")}),
        ("## S\n\n> **TODO:**\n\n## R\n\nText.\n", {("S", "c")}),
        ("## S\n\n_TODO_: Describe it.\n\nSee issue 1.\n", {("S", "c")}),
        ("## S\n\n_TODO_: Describe it.\n\nsee issue 1.\n", {("S", "c")}),
        ("## S\n\n_TODO_: Describe it.\n\n> See issue 1.\n", {("S", "c")}),
        (
            "## S\n\n_TODO_: Describe it.\n\nReferences: issue 1.\n",
            {("S", "c")},
        ),
        ("## S\n\n-   TODO: describe it.\n", {("S", "c")}),
        ("## S\n\n<!-- TODO: describe it. -->\n", {("S", "c")}),
        ("## S\n\nTBD.\n", {("S", "c")}),
        ("## S\n\n## R\n\nText.\n", {("S", "d")}),
        ("## S\n\n### R\n\nText.\n", set()),
        (
            "## S\n\n> **TODO:**\n\n> **Fork note (2026-10-14).** Later.\n",
            set(),
        ),
        ("## S\n\nText beside a note.\n\n> **TODO:** Refine.\n", set()),
        ("## S\n\n_TODO_: Describe it.\n\nSeemingly done.\n", set()),
        ("## S\n\nThis is a **skeletal** design.\n", {("S", "a")}),
        ("## **TODO:** describe\n\nText.\n", {("**TODO:** describe", "b")}),
        ("## `TODO` describe\n\nText.\n", {("`TODO` describe", "b")}),
        ("## TBD: describe\n\nText.\n", {("TBD: describe", "b")}),
        (
            "## S\n\nTODO: later\n\nReferences:\n\n-   [A](a.md)\n"
            "-   [B\n    title](b.md)\n",
            {("S", "c")},
        ),
        ("## S\n\nTODO: later\n\nSee:\n\n-   An item, no link.\n", set()),
        ("## S\n\nTODO: later\n\n-   [A](a.md)\n", set()),
    ]
    for text, want_hits in w2_cases:
        got = {
            (heading, clause) for _, heading, clause in w2_file_hits("", text)
        }
        if got != want_hits:
            wrong += 1
            print(
                f"self-check: W2 gives {sorted(got)} for {text!r}, expected "
                f"{sorted(want_hits)}",
                file=sys.stderr,
            )
    print(
        f"self-check: {len(cases)} quote cases, {len(w2_cases)} W2 cases, "
        f"{wrong} wrong"
    )
    return wrong


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Checks the DD-1 design pages against their samples."
    )
    parser.add_argument(
        "--toolchain",
        type=Path,
        help="also compile every fixture with this `carbon` binary",
    )
    parser.add_argument(
        "--self-check",
        action="store_true",
        help="only run the quote matcher's and the W2 rule's built-in cases",
    )
    args = parser.parse_args()
    if self_check():
        return 1
    if args.self_check:
        return 0
    errors: list[str] = []
    programs, fixtures = check_samples(errors)
    report, hits = check_w2(errors)
    if args.toolchain:
        check_toolchain(args.toolchain.resolve(), fixtures, errors)
    for line in report:
        print(line)
    for error in errors:
        print(error, file=sys.stderr)
    allowlisted = sum(line.startswith("W2 allowlisted") for line in report)
    qualified = sum(line.startswith("W2 qualified") for line in report)
    print(
        f"check_samples: {programs} program blocks, {len(fixtures)} fixtures"
        f"{' (compiled)' if args.toolchain else ''}, {hits} W2 hits "
        f"({allowlisted} allowlisted, {qualified} qualified); "
        f"{len(errors)} errors"
    )
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

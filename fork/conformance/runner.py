#!/usr/bin/env python3
"""Carbon 0.1 execution-conformance runner (the "arbiter" of fork/process.md).

Compiles, links, and RUNS every program under fork/conformance/programs/,
checking exit codes and (optionally) stdout, then rolls results up into a
per-milestone-bullet scoreboard keyed to the table in fork/gap-analysis.md.

Toolchain invocation (verified against repo sources; see README.md):

    <carbon> compile [COMPILE-ARGS...] --output=<out>/obj/<name>.o --output-last-input-only <prog>.carbon
    <carbon> link --output=<out>/bin/<name> <out>/obj/<name>.o
    <out>/bin/<name>            # 30s timeout, capture exit code + stdout

Differential Carbon-vs-C++ checking: a program `<name>.carbon` may have a
sibling `<name>.diff.cpp` — an equivalent plain C++17 program. When present,
after the Carbon binary runs (and passes its EXPECT-* checks, which stay
authoritative), the runner additionally does:

    <root>/lib/carbon/llvm/bin/clang++ -std=c++17 -o <out>/bin/<name>.cpp.bin <name>.diff.cpp
    <out>/bin/<name>.cpp.bin    # run timeout, capture exit code + stdout

and requires C++ exit code == Carbon exit code AND C++ stdout byte-identical
to Carbon stdout; divergence is the DIFF-MISMATCH status. clang++ here is
the toolchain's own busybox symlink (dispatches on argv[0]; builds runtimes
on demand like `carbon link`, hence the link timeout for the C++ compile).
This makes real C++ the oracle for output values instead of hand-authored
EXPECT-STDOUT alone (fork/ORCHESTRATION.md next-action 6).

Evidence for the command pattern:
  - toolchain/install/install_test.py (run_carbon_test): `carbon compile
    --output=X f.carbon` then `carbon link --output=Y X` against an installed
    tree, then executes the binary and asserts stdout.
  - bazel/carbon_rules/defs.bzl: passes `--output-last-input-only` whenever a
    compile has multiple inputs; with the default `--include-carbon-core` the
    prelude + Core library files are extra compilation units, so we pass it
    too (it only silences the "only outputting the last input" warning, the
    behavior is the default anyway per toolchain/driver/compile_driver.cpp).
  - toolchain/driver/compile_driver.cpp: `--include-carbon-core` defaults on,
    which is what makes `import Core library "io"` resolve against the
    install tree's core package.
  - toolchain/driver/link_driver.cpp: `carbon link` builds the Carbon prelude
    runtimes on demand and links the prelude objects automatically. NOTE:
    only *prelude* objects, not core "io" impl objects — which is why the
    conformance programs use the inline-lowered `Core.Print`/`Core.PrintChar`
    builtins (printf/putchar; toolchain/lower/handle_call.cpp) rather than
    `Core.PrintStr` (whose body lives in core/io.impl.carbon and is only
    linked by the bazel carbon_binary rule or the `carbon build` subcommand).

Pure python3 stdlib. No bazel, no network.
"""

import argparse
import json
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

# Result statuses.
PASS = "PASS"
COMPILE_FAIL = "COMPILE-FAIL"
LINK_FAIL = "LINK-FAIL"
RUN_FAIL = "RUN-FAIL"
OUTPUT_MISMATCH = "OUTPUT-MISMATCH"
DIFF_MISMATCH = "DIFF-MISMATCH"
SKIP = "SKIP"

FAIL_STATUSES = (
    COMPILE_FAIL, LINK_FAIL, RUN_FAIL, OUTPUT_MISMATCH, DIFF_MISMATCH)

# Location of the toolchain's own clang++ inside an installed tree, relative
# to the tree root (the directory containing bin/carbon). Verified against an
# extracted carbon_toolchain tarball: lib/carbon/llvm/bin/clang++ is a
# busybox symlink that dispatches on argv[0], so invoking it by this path
# behaves as a real clang++ (with on-demand runtimes, like `carbon link`).
CLANGXX_RELPATH = ("lib", "carbon", "llvm", "bin", "clang++")

# Bullet rollup statuses (process.md: "bullet -> PASS / FAIL / NOT-WRITTEN").
BULLET_PASS = "PASS"
BULLET_FAIL = "FAIL"
BULLET_SKIP = "SKIP"  # all of the bullet's programs are SKIPped
BULLET_NOT_WRITTEN = "NOT-WRITTEN"

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_PROGRAMS_DIR = SCRIPT_DIR / "programs"
GAP_ANALYSIS = SCRIPT_DIR.parent / "gap-analysis.md"


class DirectiveError(Exception):
    """A program's header directives are malformed."""


class Program:
    def __init__(self, path, rel):
        self.path = path
        self.rel = rel  # path relative to the programs dir, POSIX style
        self.name = rel.replace("/", "_").removesuffix(".carbon")
        self.bullet = None
        self.expect_exit = 0
        self.expect_stdout = None  # None => stdout unchecked; else exact str
        self.skip_reason = None
        # Extra `carbon compile` arguments (from `// COMPILE-ARGS:`), e.g.
        # `--cpp-exceptions=none` for programs that pin a boundary mode.
        self.compile_args = []
        # Differential sibling: `<name>.diff.cpp` next to `<name>.carbon`.
        # When set, the runner also compiles+runs the C++ file with the
        # toolchain's own clang++ and requires exit code and stdout to be
        # byte-identical to the Carbon program's.
        self.diff_cpp = None


def parse_directives(path, rel):
    """Parse header directives from the leading comment block of a program.

    Recognized (all in leading `//` comments, before the first code line):
      // CONFORMANCE-BULLET: <exact bullet text from fork/gap-analysis.md>
      // COMPILE-ARGS: <extra `carbon compile` args, whitespace-split>
      // EXPECT-EXIT: <int>                          (default 0)
      // EXPECT-STDOUT:                              (then `//   <line>` lines)
      // SKIP: <reason>
    """
    prog = Program(path, rel)
    lines = path.read_text(encoding="utf-8").splitlines()

    i = 0
    in_stdout = False
    stdout_lines = []
    for i, line in enumerate(lines):
        stripped = line.rstrip("\n")
        if stripped.strip() == "":
            in_stdout = False
            continue
        if not stripped.lstrip().startswith("//"):
            break  # end of leading comment block
        comment = stripped.lstrip()

        if in_stdout:
            # Continuation lines: `//   <literal line>` (two-slash + 3 spaces).
            if comment.startswith("//   "):
                stdout_lines.append(comment[5:])
                continue
            in_stdout = False  # any other comment ends the block

        if comment.startswith("// CONFORMANCE-BULLET:"):
            prog.bullet = comment[len("// CONFORMANCE-BULLET:"):].strip()
        elif comment.startswith("// COMPILE-ARGS:"):
            value = comment[len("// COMPILE-ARGS:"):].strip()
            if not value:
                raise DirectiveError(
                    f"{rel}: COMPILE-ARGS needs at least one argument")
            prog.compile_args = value.split()
        elif comment.startswith("// EXPECT-EXIT:"):
            value = comment[len("// EXPECT-EXIT:"):].strip()
            try:
                prog.expect_exit = int(value)
            except ValueError:
                raise DirectiveError(
                    f"{rel}: EXPECT-EXIT is not an integer: {value!r}")
        elif comment.startswith("// EXPECT-STDOUT:"):
            trailing = comment[len("// EXPECT-STDOUT:"):].strip()
            if trailing:
                raise DirectiveError(
                    f"{rel}: EXPECT-STDOUT takes no inline value; put "
                    f"expected lines on following `//   <line>` lines")
            in_stdout = True
            prog.expect_stdout = ""  # will be filled from stdout_lines
        elif comment.startswith("// SKIP:"):
            prog.skip_reason = comment[len("// SKIP:"):].strip() or "(no reason)"

    if prog.expect_stdout is not None:
        prog.expect_stdout = "".join(l + "\n" for l in stdout_lines)

    if not prog.bullet:
        raise DirectiveError(f"{rel}: missing `// CONFORMANCE-BULLET:` directive")
    return prog


def load_gap_analysis_bullets(gap_path):
    """Extract the milestone-bullet texts from fork/gap-analysis.md's table.

    Returns an ordered dict bullet -> status (DONE/PARTIAL/MISSING/...).
    """
    bullets = {}
    in_table = False
    for line in gap_path.read_text(encoding="utf-8").splitlines():
        if line.startswith("## Per-bullet status"):
            in_table = True
            continue
        if in_table and line.startswith("## "):
            break
        if not in_table or not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 2:
            continue
        bullet, status = cells[0], cells[1]
        # Skip the header row and the separator row.
        if bullet.startswith("---") or bullet == "0.1 milestone bullet":
            continue
        bullets[bullet] = status
    return bullets


def discover_programs(programs_dir, filter_substr):
    programs = []
    errors = []
    for path in sorted(programs_dir.rglob("*.carbon")):
        rel = path.relative_to(programs_dir).as_posix()
        if filter_substr and filter_substr not in rel:
            continue
        try:
            prog = parse_directives(path, rel)
        except DirectiveError as e:
            errors.append(str(e))
            continue
        diff_cpp = path.with_name(path.name[:-len(".carbon")] + ".diff.cpp")
        if diff_cpp.is_file():
            prog.diff_cpp = diff_cpp
        programs.append(prog)
    # Orphan differential files: every *.diff.cpp must sit next to its
    # matching *.carbon program (enforced by --self-test; reported here too
    # so a stray rename can't silently drop a differential check).
    for path in sorted(programs_dir.rglob("*.diff.cpp")):
        rel = path.relative_to(programs_dir).as_posix()
        if filter_substr and filter_substr not in rel:
            continue
        carbon_sibling = path.with_name(
            path.name[:-len(".diff.cpp")] + ".carbon")
        if not carbon_sibling.is_file():
            errors.append(
                f"{rel}: differential C++ file has no matching "
                f"{carbon_sibling.name} program next to it")
    return programs, errors


def find_clangxx(toolchain):
    """Locate the toolchain's own clang++ from the `carbon` binary path.

    The install tree layout is <root>/bin/carbon with clang++ at
    <root>/lib/carbon/llvm/bin/clang++ (a carbon-busybox symlink).
    `bin/carbon` is itself a symlink to lib/carbon/carbon-busybox, so a
    resolved toolchain path lands in lib/carbon/ — probe both layouts.
    Returns None if not found.
    """
    candidates = [
        # From <root>/bin/carbon (the unresolved install-tree entry point).
        toolchain.parent.parent.joinpath(*CLANGXX_RELPATH),
        # From <root>/lib/carbon/carbon-busybox (the resolved symlink
        # target): clang++ sits in the llvm/bin/ dir next to it.
        toolchain.parent / "llvm" / "bin" / "clang++",
    ]
    for clangxx in candidates:
        if clangxx.is_file():
            return clangxx
    return None


def run_cmd(cmd, timeout):
    """Run a command; returns (returncode, stdout, stderr, timed_out)."""
    try:
        proc = subprocess.run(
            [str(c) for c in cmd],
            capture_output=True,
            text=True,
            errors="replace",
            timeout=timeout,
        )
        return proc.returncode, proc.stdout, proc.stderr, False
    except subprocess.TimeoutExpired as e:
        out = e.stdout or ""
        err = e.stderr or ""
        if isinstance(out, bytes):
            out = out.decode(errors="replace")
        if isinstance(err, bytes):
            err = err.decode(errors="replace")
        return None, out, err, True


def write_log(log_dir, prog, sections):
    log_dir.mkdir(parents=True, exist_ok=True)
    log_path = log_dir / f"{prog.name}.log"
    with log_path.open("w", encoding="utf-8") as f:
        f.write(f"program: {prog.rel}\n")
        f.write(f"bullet: {prog.bullet}\n\n")
        for title, body in sections:
            f.write(f"=== {title} ===\n{body}\n\n")
    return log_path


def execute_program(prog, toolchain, clangxx, out_dir, timeouts):
    """Compile, link, and run one program. Returns (status, detail).

    If the program has a `<name>.diff.cpp` differential sibling, the C++
    file is additionally compiled with the toolchain's clang++ and run; its
    exit code and stdout must be byte-identical to the Carbon program's
    (on top of any EXPECT-* directives, which stay authoritative).
    """
    if prog.skip_reason:
        return SKIP, prog.skip_reason

    obj_dir = out_dir / "obj"
    bin_dir = out_dir / "bin"
    log_dir = out_dir / "logs"
    obj_dir.mkdir(parents=True, exist_ok=True)
    bin_dir.mkdir(parents=True, exist_ok=True)
    obj_path = obj_dir / f"{prog.name}.o"
    bin_path = bin_dir / prog.name

    # --- Compile ---
    compile_cmd = [
        toolchain,
        "compile",
        *prog.compile_args,
        f"--output={obj_path}",
        "--output-last-input-only",
        prog.path,
    ]
    rc, out, err, timed_out = run_cmd(compile_cmd, timeouts["compile"])
    if timed_out or rc != 0:
        detail = ("compile timed out" if timed_out
                  else f"compile exited with {rc}")
        write_log(log_dir, prog, [
            ("command", " ".join(str(c) for c in compile_cmd)),
            ("detail", detail),
            ("stdout", out),
            ("stderr", err),
        ])
        return COMPILE_FAIL, detail

    # --- Link ---
    link_cmd = [
        toolchain,
        "link",
        f"--output={bin_path}",
        obj_path,
    ]
    rc, out, err, timed_out = run_cmd(link_cmd, timeouts["link"])
    if timed_out or rc != 0:
        detail = ("link timed out (note: the first link builds runtimes "
                  "on demand and can be slow)" if timed_out
                  else f"link exited with {rc}")
        write_log(log_dir, prog, [
            ("command", " ".join(str(c) for c in link_cmd)),
            ("detail", detail),
            ("stdout", out),
            ("stderr", err),
        ])
        return LINK_FAIL, detail

    # --- Run ---
    rc, out, err, timed_out = run_cmd([bin_path], timeouts["run"])
    if timed_out:
        detail = f"binary did not finish within {timeouts['run']}s"
        write_log(log_dir, prog, [
            ("command", str(bin_path)),
            ("detail", detail),
            ("stdout", out),
            ("stderr", err),
        ])
        return RUN_FAIL, detail
    if rc != prog.expect_exit:
        detail = f"exit code {rc}, expected {prog.expect_exit}"
        write_log(log_dir, prog, [
            ("command", str(bin_path)),
            ("detail", detail),
            ("stdout", out),
            ("stderr", err),
        ])
        return RUN_FAIL, detail
    if prog.expect_stdout is not None and out != prog.expect_stdout:
        detail = "stdout does not match EXPECT-STDOUT"
        write_log(log_dir, prog, [
            ("command", str(bin_path)),
            ("detail", detail),
            ("expected stdout", prog.expect_stdout),
            ("actual stdout", out),
            ("stderr", err),
        ])
        return OUTPUT_MISMATCH, detail

    # --- Differential C++ (byte-identical exit code + stdout) ---
    if prog.diff_cpp is not None:
        carbon_rc, carbon_out = rc, out
        if clangxx is None:
            detail = ("differential C++ sibling present but clang++ not "
                      "found in the toolchain tree "
                      f"(expected at <root>/{'/'.join(CLANGXX_RELPATH)})")
            write_log(log_dir, prog, [("detail", detail)])
            return DIFF_MISMATCH, detail
        cpp_bin = bin_dir / f"{prog.name}.cpp.bin"
        cpp_cmd = [clangxx, "-std=c++17", "-o", cpp_bin, prog.diff_cpp]
        # The toolchain clang++ builds runtimes on demand like `carbon
        # link`, so give the C++ compile the link timeout.
        rc, out, err, timed_out = run_cmd(cpp_cmd, timeouts["link"])
        if timed_out or rc != 0:
            detail = ("differential C++ compile timed out" if timed_out
                      else f"differential C++ compile exited with {rc}")
            write_log(log_dir, prog, [
                ("command", " ".join(str(c) for c in cpp_cmd)),
                ("detail", detail),
                ("stdout", out),
                ("stderr", err),
            ])
            return DIFF_MISMATCH, detail
        rc, out, err, timed_out = run_cmd([cpp_bin], timeouts["run"])
        if timed_out:
            detail = (f"differential C++ binary did not finish within "
                      f"{timeouts['run']}s")
            write_log(log_dir, prog, [
                ("command", str(cpp_bin)),
                ("detail", detail),
                ("stdout", out),
                ("stderr", err),
            ])
            return DIFF_MISMATCH, detail
        if rc != carbon_rc or out != carbon_out:
            parts = []
            if rc != carbon_rc:
                parts.append(f"exit code: C++ {rc} vs Carbon {carbon_rc}")
            if out != carbon_out:
                parts.append("stdout differs")
            detail = "Carbon/C++ divergence (" + "; ".join(parts) + ")"
            write_log(log_dir, prog, [
                ("command", str(cpp_bin)),
                ("detail", detail),
                ("carbon exit code", str(carbon_rc)),
                ("c++ exit code", str(rc)),
                ("carbon stdout", carbon_out),
                ("c++ stdout", out),
                ("c++ stderr", err),
            ])
            return DIFF_MISMATCH, detail

    return PASS, ""


def rollup_bullets(programs, results, all_bullets):
    """Roll program results up to per-bullet statuses.

    A bullet PASSes only if all of its (non-SKIP) programs pass and at least
    one program actually ran. Bullets in the gap-analysis table with no
    programs are NOT-WRITTEN (per fork/process.md's scoreboard definition).
    """
    per_bullet = {}
    for prog in programs:
        per_bullet.setdefault(prog.bullet, []).append(prog)

    rollup = {}
    for bullet in all_bullets:
        progs = per_bullet.get(bullet)
        if not progs:
            rollup[bullet] = {
                "status": BULLET_NOT_WRITTEN,
                "gap_status": all_bullets[bullet],
                "programs": [],
            }
            continue
        statuses = [results[p.rel][0] for p in progs]
        if any(s in FAIL_STATUSES for s in statuses):
            status = BULLET_FAIL
        elif all(s == SKIP for s in statuses):
            status = BULLET_SKIP
        else:
            status = BULLET_PASS
        rollup[bullet] = {
            "status": status,
            "gap_status": all_bullets[bullet],
            "programs": [p.rel for p in progs],
        }
    # Programs pointing at bullets not present in the table (self-test
    # normally catches this, but keep the scoreboard honest anyway).
    for bullet, progs in per_bullet.items():
        if bullet not in rollup:
            rollup[bullet] = {
                "status": BULLET_FAIL,
                "gap_status": "UNKNOWN-BULLET",
                "programs": [p.rel for p in progs],
            }
    return rollup


README_PATH = SCRIPT_DIR / "README.md"
TABLE_BEGIN = "<!-- BEGIN PROGRAM TABLE (generated by runner.py --update-readme-table) -->"
TABLE_END = "<!-- END PROGRAM TABLE -->"


def generate_program_table(programs):
    """Render the program->bullet table from parsed headers."""
    lines = [TABLE_BEGIN,
             "",
             "| Program | Bullet | Kind |",
             "| --- | --- | --- |"]
    for prog in sorted(programs, key=lambda pr: pr.rel):
        kind = []
        if prog.skip_reason is not None:
            kind.append("SKIP")
        if prog.diff_cpp is not None:
            kind.append("differential")
        lines.append("| `%s` | %s | %s |"
                     % (prog.rel, prog.bullet.replace("|", "\\|"),
                        ", ".join(kind) or "run"))
    lines += ["", TABLE_END]
    return "\n".join(lines)


def update_readme_table(programs, check_only=False):
    """Rewrite (or verify) the generated table between the README markers.

    Returns 0 on success/current, 1 on missing markers or (check mode)
    staleness.
    """
    if not README_PATH.exists():
        print(f"error: {README_PATH} not found", file=sys.stderr)
        return 1
    text = README_PATH.read_text()
    begin = text.find(TABLE_BEGIN)
    end = text.find(TABLE_END)
    if begin == -1 or end == -1 or end < begin:
        print(f"error: program-table markers not found in {README_PATH.name};"
              f" add {TABLE_BEGIN!r} and {TABLE_END!r}", file=sys.stderr)
        return 1
    new_block = generate_program_table(programs)
    new_text = text[:begin] + new_block + text[end + len(TABLE_END):]
    if new_text == text:
        return 0
    if check_only:
        print("error: README program table is stale; run "
              "`runner.py --update-readme-table`", file=sys.stderr)
        return 1
    README_PATH.write_text(new_text)
    print(f"updated program table in {README_PATH.name} "
          f"({len(programs)} programs)")
    return 0


def self_test(programs_dir, filter_substr):
    """Validate all program headers + bullet names without a toolchain."""
    ok = True
    if not GAP_ANALYSIS.exists():
        print(f"error: gap analysis not found at {GAP_ANALYSIS}", file=sys.stderr)
        return 1
    bullets = load_gap_analysis_bullets(GAP_ANALYSIS)
    if not bullets:
        print(f"error: no bullets parsed from {GAP_ANALYSIS}", file=sys.stderr)
        return 1
    programs, errors = discover_programs(programs_dir, filter_substr)
    for e in errors:
        ok = False
        print(f"directive error: {e}", file=sys.stderr)
    if not programs and not errors:
        print("error: no programs found", file=sys.stderr)
        return 1
    for prog in programs:
        if prog.bullet not in bullets:
            ok = False
            print(f"bullet mismatch: {prog.rel}: CONFORMANCE-BULLET not in "
                  f"{GAP_ANALYSIS.name} table:\n  {prog.bullet!r}",
                  file=sys.stderr)
    if not filter_substr and update_readme_table(programs, check_only=True) != 0:
        ok = False
    print(f"self-test: {len(programs)} programs parsed, "
          f"{len(bullets)} bullets in table, "
          f"{'OK' if ok else 'ERRORS'}")
    if ok:
        width = max(len(p.rel) for p in programs)
        for prog in programs:
            marks = []
            if prog.skip_reason:
                marks.append(f"SKIP: {prog.skip_reason}")
            if prog.expect_stdout is not None:
                marks.append(f"stdout: {len(prog.expect_stdout.splitlines())} lines")
            if prog.diff_cpp is not None:
                marks.append("diff: C++")
            if prog.compile_args:
                marks.append("args: " + " ".join(prog.compile_args))
            marks.append(f"exit: {prog.expect_exit}")
            print(f"  {prog.rel:<{width}}  ->  {prog.bullet}  [{'; '.join(marks)}]")
    return 0 if ok else 1


def print_table(programs, results, rollup, totals):
    print()
    print("=== programs ===")
    width = max((len(p.rel) for p in programs), default=10)
    for prog in programs:
        status, detail = results[prog.rel]
        line = f"  {status:<16} {prog.rel:<{width}}"
        if detail:
            line += f"  ({detail})"
        print(line)

    print()
    print("=== per-bullet rollup (bullet PASSes only if all its programs pass) ===")
    exercised = {b: r for b, r in rollup.items() if r["status"] != BULLET_NOT_WRITTEN}
    bwidth = max((len(b) for b in exercised), default=10)
    for bullet, r in exercised.items():
        print(f"  {r['status']:<12} {bullet:<{bwidth}}  "
              f"[gap: {r['gap_status']}; {len(r['programs'])} program(s)]")
    not_written = sum(
        1 for r in rollup.values() if r["status"] == BULLET_NOT_WRITTEN)

    print()
    print("=== totals ===")
    for key in (PASS, COMPILE_FAIL, LINK_FAIL, RUN_FAIL, OUTPUT_MISMATCH,
                DIFF_MISMATCH, SKIP):
        print(f"  {key:<16} {totals[key]}")
    bullet_pass = sum(1 for r in rollup.values() if r["status"] == BULLET_PASS)
    bullet_fail = sum(1 for r in rollup.values() if r["status"] == BULLET_FAIL)
    print(f"  bullets: {bullet_pass} PASS, {bullet_fail} FAIL, "
          f"{len(exercised) - bullet_pass - bullet_fail} SKIP, "
          f"{not_written} NOT-WRITTEN "
          f"(of {len(rollup)} in the gap-analysis table)")


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Carbon 0.1 execution-conformance runner")
    parser.add_argument("--toolchain", type=Path,
                        help="path to the `carbon` busybox binary of an "
                             "installed toolchain tree")
    parser.add_argument("--filter", default="",
                        help="only run programs whose relative path contains "
                             "this substring")
    parser.add_argument("--out", type=Path, default=SCRIPT_DIR / "out",
                        help="output directory for scoreboard.json, logs/, "
                             "obj/, bin/ (default: fork/conformance/out)")
    parser.add_argument("--programs", type=Path, default=DEFAULT_PROGRAMS_DIR,
                        help="programs directory (default: "
                             "fork/conformance/programs)")
    parser.add_argument("--update-readme-table", action="store_true",
                        help="Regenerate the program table in README.md "
                             "between the generated-table markers.")
    parser.add_argument("--self-test", action="store_true",
                        help="parse all program headers and validate bullet "
                             "names against fork/gap-analysis.md, then exit "
                             "(no toolchain needed)")
    parser.add_argument("--compile-timeout", type=int, default=300,
                        help="seconds per compile (default 300)")
    parser.add_argument("--link-timeout", type=int, default=1800,
                        help="seconds per link; the first link builds "
                             "runtimes on demand and is slow (default 1800)")
    parser.add_argument("--run-timeout", type=int, default=30,
                        help="seconds per program execution (default 30)")
    args = parser.parse_args(argv)

    if not args.programs.is_dir():
        print(f"error: programs directory not found: {args.programs}",
              file=sys.stderr)
        return 2

    if args.update_readme_table:
        programs, errors = discover_programs(args.programs, "")
        for e in errors:
            print(f"directive error: {e}", file=sys.stderr)
            return 1
        return update_readme_table(programs)

    if args.self_test:
        return self_test(args.programs, args.filter)

    if not args.toolchain:
        parser.error("--toolchain is required (or use --self-test)")
    toolchain = args.toolchain.resolve()
    if not toolchain.is_file():
        print(f"error: toolchain binary not found: {toolchain}", file=sys.stderr)
        return 2

    bullets = load_gap_analysis_bullets(GAP_ANALYSIS)
    programs, errors = discover_programs(args.programs, args.filter)
    if errors:
        for e in errors:
            print(f"directive error: {e}", file=sys.stderr)
        return 2
    if not programs:
        print("error: no programs matched", file=sys.stderr)
        return 2

    out_dir = args.out
    out_dir.mkdir(parents=True, exist_ok=True)
    timeouts = {
        "compile": args.compile_timeout,
        "link": args.link_timeout,
        "run": args.run_timeout,
    }

    clangxx = find_clangxx(toolchain)

    results = {}
    started = time.time()
    for prog in programs:
        status, detail = execute_program(
            prog, toolchain, clangxx, out_dir, timeouts)
        results[prog.rel] = (status, detail)
        line = f"[{status}] {prog.rel}"
        if detail:
            line += f" ({detail})"
        print(line, flush=True)

    totals = {k: 0 for k in
              (PASS, COMPILE_FAIL, LINK_FAIL, RUN_FAIL, OUTPUT_MISMATCH,
               DIFF_MISMATCH, SKIP)}
    for status, _ in results.values():
        totals[status] += 1

    rollup = rollup_bullets(programs, results, bullets)

    scoreboard = {
        "generated": datetime.now(timezone.utc).isoformat(),
        "toolchain": str(toolchain),
        "elapsed_seconds": round(time.time() - started, 1),
        "totals": totals,
        "programs": [
            {
                "path": prog.rel,
                "bullet": prog.bullet,
                "status": results[prog.rel][0],
                "detail": results[prog.rel][1],
                "differential": prog.diff_cpp is not None,
            }
            for prog in programs
        ],
        "bullets": rollup,
    }
    scoreboard_path = out_dir / "scoreboard.json"
    scoreboard_path.write_text(
        json.dumps(scoreboard, indent=2) + "\n", encoding="utf-8")

    print_table(programs, results, rollup, totals)
    print(f"\nscoreboard: {scoreboard_path}")
    failures = sum(totals[s] for s in FAIL_STATUSES)
    if failures:
        print(f"logs for failures: {out_dir / 'logs'}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())

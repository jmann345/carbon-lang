# Execution-conformance harness (the 0.1 arbiter)

This directory is the **arbiter** defined in step 1 of
[`fork/process.md`](../process.md): an executable definition of "done" for the
0.1 milestone. Programs here must **compile, link, and run** with the expected
exit code and output — not just pass golden-dump checks. The scoreboard this
harness emits is the project's progress number.

> **The rule:** a milestone bullet (and any feature work behind it) is only
> "done" when its conformance programs PASS here, on a real toolchain, at
> runtime. No feature is done by assertion — only by scoreboard
> (`fork/process.md`, standing rule 2).

## Running

```sh
# Full run against an installed toolchain tree's `carbon` busybox binary
# (e.g. an extracted nightly carbon_toolchain tarball):
python3 fork/conformance/runner.py \
    --toolchain /path/to/carbon_toolchain-*/bin/carbon

# Subset by path substring:
python3 fork/conformance/runner.py --toolchain ... --filter types/

# Custom output directory (default: fork/conformance/out):
python3 fork/conformance/runner.py --toolchain ... --out /tmp/conformance-out

# Validate program headers + bullet names without a toolchain:
python3 fork/conformance/runner.py --self-test
```

Pure python3 stdlib; no bazel, no network. Exit code is 1 if any non-SKIP
program fails.

Outputs under `--out`:

- `scoreboard.json` — machine-readable results: per-program statuses and the
  per-bullet rollup (including `NOT-WRITTEN` for every gap-analysis bullet
  that has no program yet, per process.md's scoreboard definition).
- `logs/<name>.log` — command line, stdout, stderr for each failure.
- `obj/`, `bin/` — kept compile/link artifacts for debugging.

### Toolchain invocation

For each program the runner executes:

```sh
<carbon> compile --output=<out>/obj/<name>.o --output-last-input-only <prog>.carbon
<carbon> link --output=<out>/bin/<name> <out>/obj/<name>.o
<out>/bin/<name>     # 30s timeout; exit code + stdout captured
```

This mirrors `toolchain/install/install_test.py` (`run_carbon_test`), the one
upstream test that exercises an installed tree end-to-end. Details that
matter:

- `--include-carbon-core` is the compile default
  (`toolchain/driver/compile_driver.cpp`), which is what resolves
  `import Core library "io"` against the install tree. Because that adds the
  prelude + Core files as extra compilation units, we pass
  `--output-last-input-only` (as `bazel/carbon_rules/defs.bzl` does) so only
  the program's own object is written, warning-free.
- `carbon link` builds the Carbon **prelude** runtimes on demand and links
  them automatically (`toolchain/driver/link_driver.cpp`) — but *not* the
  rest of the Core objects (explicit TODO there). Programs therefore print
  with `Core.Print`/`Core.PrintChar`, which lower inline to
  `printf`/`putchar` (`toolchain/lower/handle_call.cpp`), and avoid
  `Core.PrintStr`, whose body lives in `core/io.impl.carbon` and is only
  linked by the bazel `carbon_binary` rule or the `carbon build` subcommand.
- The **first** link on a fresh machine builds runtimes (compiler-rt, libc++,
  prelude objects) on demand and can take many minutes; later links hit the
  runtimes cache. Hence the generous default `--link-timeout=1800`.

## Program format

Programs live at `programs/**/*.carbon`. Each is a single self-contained
`Main//default` file (no `package`/`library` declaration) with a `Run` entry
point, 10–40 lines, arbitrating **one** concept. Directives sit in the
leading comment block:

```carbon
// CONFORMANCE-BULLET: <exact bullet text from the table in fork/gap-analysis.md>
// EXPECT-EXIT: <int>          (optional; default 0)
// EXPECT-STDOUT:              (optional; if absent, stdout is unchecked)
//   <literal line 1>
//   <literal line 2>
// SKIP: <reason>              (optional; marks a not-yet-runnable program)
```

- `CONFORMANCE-BULLET` is **required** and must match a first-column cell of
  the "Per-bullet status" table in [`fork/gap-analysis.md`](../gap-analysis.md)
  character-for-character (`--self-test` enforces this).
- `EXPECT-STDOUT` continuation lines are `//` + three spaces + the literal
  expected line; the captured stdout must equal the lines joined with
  newlines (each line newline-terminated). Note `Core.Print(x)` prints
  `<int>\n`.
- `SKIP` exists for programs written ahead of their feature
  (write-tests-first, per process.md step 1). Keep SKIPs rare; prefer
  writing programs against constructs that already work.

### Differential Carbon-vs-C++ programs

A program `<name>.carbon` may have a sibling file `<name>.diff.cpp`: an
equivalent plain C++17 program. When present, the runner — after the Carbon
binary runs and passes its EXPECT-* checks (which stay authoritative) —
additionally compiles the C++ file with the toolchain's **own** clang++
(`<root>/lib/carbon/llvm/bin/clang++`, the busybox symlink next to
`bin/carbon`; it builds runtimes on demand like `carbon link`, so the C++
compile gets the link timeout), runs it, and requires:

- C++ exit code == Carbon exit code, and
- C++ stdout byte-identical to Carbon stdout.

Any divergence (including a C++-side compile failure or timeout) is the
`DIFF-MISMATCH` status. This makes real clang-compiled C++ the oracle for
output values instead of hand-authored `EXPECT-STDOUT` alone — for an
interop-first language, "the Carbon program and the equivalent C++ program
produce byte-identical output" is the honest arbiter, and it catches
wrong-value expectations a program author could bake into `EXPECT-STDOUT`
(fork/ORCHESTRATION.md next-action 6). Differential programs therefore
deliberately omit `EXPECT-STDOUT` and let the C++ side compute the
expectation. Mirror `Core.Print`'s exact lowering in the C++ side:
`printf("%d\n", x)` with the argument as `int`
(toolchain/lower/handle_call.cpp). `--self-test` validates that every
`*.diff.cpp` sits next to its matching `*.carbon` program.

Statuses per program: `PASS`, `COMPILE-FAIL`, `LINK-FAIL`, `RUN-FAIL`
(crash, timeout, or wrong exit code), `OUTPUT-MISMATCH`, `DIFF-MISMATCH`
(Carbon and differential C++ diverge, or the C++ side fails to build/run),
`SKIP`.

## Bullet mapping and rollup

Every program names the milestone bullet it arbitrates. The rollup rule:

- A bullet **PASSes** only if *all* of its programs pass (skips don't count
  against it, but a bullet with only SKIPs is `SKIP`, not `PASS`).
- Any program failure makes its bullet **FAIL**.
- Bullets in the gap-analysis table with no programs are **NOT-WRITTEN** —
  visible debt: growing this suite is a permanent first-class workstream.

Current programs (all target constructs proven in-repo — see each file's
header for its evidence citations):

| Program | Bullet |
| --- | --- |
| `project/run_exit_code.carbon` | Project: installs on Windows, macOS, and Linux and builds working programs |
| `stdlib/fundamental_types.carbon` | Stdlib: fundamental types (bool, iN, fN) |
| `stdlib/tuples_arrays_structs.carbon` | Stdlib: tuple/array library parts |
| `stdlib/pointers.carbon` | Stdlib: pointer types |
| `types/classes.carbon` | Type system: User-defined types (classes) |
| `types/inheritance.carbon` | Type system: Single inheritance |
| `types/virtual_dispatch.carbon` | Type system: Virtual dispatch |
| `types/operator_overloading.carbon` | Type system: Operator overloading |
| `types/choice_basic.carbon` | Type system: Sum types (discriminated unions) |
| `generics/checked_generics.carbon` | Generics: Checked generics |
| `generics/generic_class.carbon` | Generics: generic functions and types |
| `control_flow/conditions.carbon` | Control flow: conditions |
| `control_flow/loops.carbon` | Control flow: loops incl. range-based and C/C++ loop equivalents |
| `functions/forward_decl.carbon` | Functions: separate declaration and definition |
| `code_org/namespaces.carbon` | Code organization: Namespaces |
| `interop/cpp_iostream.carbon` | Functions: C++ interop — importing/calling C++ functions and methods |

Known intentional limitation: `types/choice_basic.carbon` arbitrates only the
working slice of its (PARTIAL) bullet — parameterless choice declaration and
binding. `match` over a choice is 100% stubbed in `check/handle_match.cpp`
and choice types have no `==`; the program's header documents this. Extend it
when match semantics (workstream W4) and choice payloads (W5) land.

## Adding programs

1. Copy the bullet text exactly from the gap-analysis table.
2. Derive syntax from working code in the repo (`examples/advent2024/`,
   `examples/*.carbon`, `toolchain/*/testdata/`,
   `toolchain/install/install_test.py`) — never from design docs alone.
3. Keep one concept per program; make output observable via
   `Core.Print`/`Core.PrintChar`/exit codes (or `Cpp.std.cout` for interop
   programs).
4. For already-working behavior with a natural C++ counterpart, prefer a
   differential pair: add `<name>.diff.cpp` next to the program and omit
   `EXPECT-STDOUT` so the C++ side is the oracle (see "Differential
   Carbon-vs-C++ programs" above).
5. Run `python3 fork/conformance/runner.py --self-test`, then a full run.

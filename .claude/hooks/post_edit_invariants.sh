#!/usr/bin/env bash
#
# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Part of jmann345's carbon-lang fork tooling (see /fork/rulebook.md R12).
#
# PostToolUse hook on Edit|Write: enforce deterministic repo invariants
# immediately instead of spending adversarial-reviewer or CI attention on
# them. Reads the hook JSON on stdin; exit 2 feeds stderr back to the
# agent as blocking feedback.

set -uo pipefail

payload=$(cat)
file=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' <<<"$payload")
[ -n "$file" ] && [ -f "$file" ] || exit 0

# Only police files inside the repo or its worktrees.
case "$file" in
  /home/user/carbon-lang/*) root=/home/user/carbon-lang ;;
  /home/user/w4-match/*) root=/home/user/w4-match ;;
  /home/user/*/toolchain/*|/home/user/*/fork/*) root=$(cd "$(dirname "$file")" && git rev-parse --show-toplevel 2>/dev/null) || exit 0 ;;
  *) exit 0 ;;
esac

fail() { echo "$*" >&2; exit 2; }
msgs=""

# 1. clang-format (CI pins clang-format==21.1.8; this container matches).
case "$file" in
  */fuzzer_corpus/*|*/testdata/*) ;;
  *.cpp|*.h|*.def)
    if command -v clang-format >/dev/null 2>&1; then
      before=$(sha256sum "$file")
      clang-format -i "$file" 2>/dev/null
      after=$(sha256sum "$file")
      if [ "$before" != "$after" ]; then
        msgs="${msgs}clang-format reformatted $file — Read it again before further edits (stale old_string will not match). "
      fi
    fi
    ;;
esac

# 2. Header guards for .h files (same script CI runs). Must be invoked with
# the REPO-RELATIVE path from the repo root: the script derives the expected
# guard macro from the path as given, so an absolute path yields a garbage
# macro (and its autofix would write it into the file).
case "$file" in
  */testdata/*) ;;
  *.h)
    rel=${file#"$root"/}
    if ! out=$(cd "$root" && python3 scripts/check_header_guards.py "$rel" 2>&1); then
      fail "check_header_guards.py failed for $rel: $out"
    fi
    ;;
esac

# 3. License header (upstream check-copyright, R21). Covers fork/ too — the
# gap that let PR #1's headerless files reach CI. JSON can't carry a comment
# header (parsed by json.load) and request/*.txt are excluded, matching the
# fork exclusions in .pre-commit-config.yaml.
case "$file" in
  */fuzzer_corpus/*|*/out/*|*-request.txt|*.json) ;;
  "$root"/toolchain/*|"$root"/core/*|"$root"/common/*|"$root"/testing/*|"$root"/scripts/*|"$root"/fork/*)
    case "$file" in
      *.cpp|*.h|*.def|*.carbon|*.py|*.bzl|*.md|*.yaml|*.sh)
        if ! head -5 "$file" | grep -q "Part of the Carbon Language project"; then
          fail "$file is missing the Carbon license header (Apache-2.0 WITH LLVM-exception block; copy from a sibling file)."
        fi
        ;;
    esac
    ;;
esac

# 3b. Python: ruff format + lint (the CI-pinned hooks that flagged runner.py
# in PR #1). ruff is available locally; run it before the CI prek gate sees it.
case "$file" in
  *.py)
    if command -v ruff >/dev/null 2>&1; then
      before=$(sha256sum "$file")
      ruff format "$file" >/dev/null 2>&1
      ruff check --fix "$file" >/dev/null 2>&1 || true
      if [ "$before" != "$(sha256sum "$file")" ]; then
        msgs="${msgs}ruff reformatted/fixed $file — Read it again before further edits. "
      fi
    fi
    ;;
esac

# 4. Conformance program invariants (bullet names, directive syntax).
case "$file" in
  */fork/conformance/programs/*.carbon)
    if ! out=$(cd "$root" && python3 fork/conformance/runner.py --self-test 2>&1); then
      fail "conformance --self-test failed after editing $file: $(echo "$out" | tail -5)"
    fi
    # Anti-Goodhart (R16b): adding SKIP to a previously-passing tracked
    # program is presumed test-dodging until justified.
    if git -C "$root" ls-files --error-unmatch "$file" >/dev/null 2>&1; then
      if git -C "$root" diff HEAD -- "$file" | grep -q '^\+// SKIP:' \
         && ! git -C "$root" show "HEAD:$(git -C "$root" ls-files --full-name "$file" | head -1)" 2>/dev/null | grep -q '^// SKIP:'; then
        fail "R16b: this edit ADDS a SKIP to a previously-passing conformance program ($file). SKIP-to-dodge-a-failure is prohibited; the SKIP reason must cite the design/toolchain change that legitimately regressed it, and an adversarial reviewer must confirm."
      fi
    fi
    ;;
esac

# 4b. Anti-Goodhart (R16a): golden CHECK lines change only via the
# runner-side autoupdate workflow, never by agent hand-edits.
case "$file" in
  */toolchain/*/testdata/*.carbon)
    if git -C "$root" ls-files --error-unmatch "$file" >/dev/null 2>&1; then
      if git -C "$root" diff HEAD -- "$file" | grep -Eq '^[+-].*CHECK:(STDOUT|STDERR)'; then
        fail "R16a: this edit changes golden CHECK lines in $file by hand. Goldens change ONLY via the fork_autoupdate workflow (R15) so every semantic change comes from a real compiler run. Revert the CHECK-line edits; change only the source portion and let autoupdate reconcile."
      fi
    fi
    ;;
esac

# 5a. prettier (CI pins prettier@3.3.3 for json/yaml via pre-commit).
case "$file" in
  */MODULE.bazel.lock|*/out/*) ;;
  *.json|*.yaml)
    if command -v npx >/dev/null 2>&1; then
      before=$(sha256sum "$file")
      npx --yes prettier@3.3.3 --write --log-level=silent "$file" >/dev/null 2>&1
      after=$(sha256sum "$file")
      if [ "$before" != "$after" ]; then
        msgs="${msgs}prettier@3.3.3 (CI pin) reformatted $file — Read it again before further edits. "
      fi
    fi
    ;;
esac

# 5. JSON must parse.
case "$file" in
  *.json)
    if ! out=$(python3 -m json.tool "$file" 2>&1 >/dev/null); then
      fail "$file is not valid JSON: $out"
    fi
    ;;
esac

# 6. Python must at least compile.
case "$file" in
  *.py)
    if ! out=$(python3 -m py_compile "$file" 2>&1); then
      fail "$file has a Python syntax error: $out"
    fi
    ;;
esac

# 7. Text files end with exactly one trailing newline (CI end-of-file-fixer).
case "$file" in
  */fuzzer_corpus/*|*.svg|*.golden) ;;
  *.cpp|*.h|*.def|*.carbon|*.py|*.bzl|*.md|*.yaml|*.json|*.sh)
    if [ -s "$file" ] && [ "$(tail -c1 "$file" | wc -l)" -eq 0 ]; then
      printf '\n' >> "$file"
      msgs="${msgs}Appended missing trailing newline to $file. "
    fi
    ;;
esac

if [ -n "$msgs" ]; then
  echo "$msgs" >&2
  exit 2
fi
exit 0

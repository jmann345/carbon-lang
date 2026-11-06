#!/bin/bash
#
# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# check_greps.sh <repo> <tip-sha> <checks.tsv> [<cut-sha>]: re-runs at
# <tip-sha> each silence check of RG-1's register classification
# (fork/register/rg1-plan.md section 4.2); prints a FAIL row for each count
# that moved and exits 1 on any. <cut-sha> defaults to c1e83b0b7, the fork's
# cut; after an advance, pass the advance's base. Lines starting with "#" are
# comments. A row is id<TAB>kind<TAB>flags<TAB>pattern<TAB>paths<TAB>expected:
#   G: sum of `git grep -c <flags> -e <pattern> <tip> -- <paths>`.
#   L: `git log --oneline <cut>..<tip> -- <paths> | wc -l` (upstream commits
#      since the cut to a file a merge rule watches).
#   T: `git ls-tree --name-only <tip> <paths>/ | wc -l` (entries of an
#      upstream directory).
# Empty flags or pattern are written "-" so that a tab-separated read keeps
# every column.
repo=$1; tip=$2; tsv=$3; cut=${4:-c1e83b0b7}; n=0; bad=0
while IFS=$'\t' read -r id kind flags pat paths want; do
  case $id in '' | '#'*) continue ;; esac
  n=$((n+1)); [ "$flags" = "-" ] && flags=""
  case $kind in
    G) got=$(git -C "$repo" grep -c $flags -e "$pat" "$tip" -- $paths 2>/dev/null |
         awk -F: '{s+=$NF} END {print s+0}') ;;
    L) got=$(git -C "$repo" log --oneline "$cut..$tip" -- $paths | wc -l) ;;
    T) got=$(git -C "$repo" ls-tree --name-only "$tip" "$paths/" | wc -l) ;;
    *) got="unknown kind" ;;
  esac
  if [ "$got" != "$want" ]; then
    echo "FAIL $id ($kind) got $got want $want: $pat $paths"; bad=$((bad+1))
  fi
done < "$tsv"
echo "checked $n silence checks, $bad failed"
[ "$bad" -eq 0 ]

#!/bin/bash
#
# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# check_quotes.sh <repo> <tip-sha> <quotes.tsv>: re-reads at <tip-sha> each
# upstream line that RG-1's register classification quotes
# (fork/register/rg1-plan.md section 4.2); prints a FAIL row for each quote no
# longer on its line and exits 1 on any. A row is
# path<TAB>line<TAB>verbatim substring; lines starting with "#" are comments.
repo=$1; tip=$2; tsv=$3; n=0; bad=0
while IFS=$'\t' read -r path line sub; do
  case $path in '' | '#'*) continue ;; esac
  n=$((n+1))
  if ! git -C "$repo" show "$tip:$path" | sed -n "${line}p" | grep -qF -- "$sub"; then
    echo "FAIL $path:$line: $sub"; bad=$((bad+1))
  fi
done < "$tsv"
echo "checked $n quotes, $bad failed"
[ "$bad" -eq 0 ]

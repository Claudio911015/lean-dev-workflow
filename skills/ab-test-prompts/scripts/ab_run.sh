#!/usr/bin/env bash
# Run each task in tasks.txt through a headless agent, once per rep, in its own git worktree.
#
# Usage: ab_run.sh <repo> <tasks.txt> <variant> [reps=1] [model=sonnet]
#   variant: base            -> no change (control)
#            path/to/x.md    -> appended to the worktree's CLAUDE.md
#            path/to/skill/  -> copied into the worktree's .claude/skills/
# Results: $AB_OUT (default ./ab-out)/<variant>-t<N>-r<M>/{run.jsonl,task,worktree}
set -euo pipefail

[ $# -ge 3 ] || { sed -n 2,9p "$0"; exit 2; }
repo=$(realpath "$1"); tasks=$(realpath "$2"); variant=$3; reps=${4:-1}; model=${5:-sonnet}
out=$(realpath -m "${AB_OUT:-$PWD/ab-out}")
wtroot=$(realpath -m "${AB_WORKTREES:-$repo-ab}")
allowed=${AB_ALLOWED_TOOLS:-"Skill Read Edit Write Glob Grep Bash(git diff:*) Bash(git status:*) Bash(ls:*) Bash(grep:*)"}
budget=${AB_BUDGET_USD:-3}
export AB_REPO=$repo

if [ "$variant" = base ]; then name=base
elif [ -e "$variant" ]; then variant=$(realpath "$variant"); name=$(basename "${variant%.md}")
else echo "variant not found: $variant" >&2; exit 2; fi

mkdir -p "$out" "$wtroot"
i=0
while IFS= read -r task || [ -n "$task" ]; do
  [ -z "$task" ] && continue
  i=$((i + 1))
  for r in $(seq 1 "$reps"); do
    id="$name-t$i-r$r"; wt="$wtroot/$id"; dir="$out/$id"
    mkdir -p "$dir"
    git -C "$repo" worktree add -q --detach "$wt" HEAD
    if [ -n "${AB_SETUP:-}" ]; then (cd "$wt" && eval "$AB_SETUP"); fi
    if [ -d "$variant" ]; then mkdir -p "$wt/.claude/skills" && cp -r "$variant" "$wt/.claude/skills/"
    elif [ -f "$variant" ]; then cat "$variant" >> "$wt/CLAUDE.md"; fi
    printf '%s\n' "$task" > "$dir/task"; printf '%s\n' "$wt" > "$dir/worktree"
    (cd "$wt" && claude -p "$task" --model "$model" --output-format stream-json --verbose \
       --max-budget-usd "$budget" --allowedTools "$allowed" < /dev/null > "$dir/run.jsonl" 2>&1) &
  done
done < "$tasks"
wait
echo "done: $i task(s) x $reps rep(s) -> $out"

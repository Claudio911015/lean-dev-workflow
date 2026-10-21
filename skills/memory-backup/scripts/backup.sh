#!/usr/bin/env bash
# Copy dirs into a git repo, scan the repo for secrets, then commit and push.
# Usage: backup.sh [--dry-run] <repo> <dir>...
set -euo pipefail

dry=0
[ "${1:-}" = --dry-run ] && { dry=1; shift; }
[ $# -ge 2 ] || { sed -n 2,3p "$0"; exit 2; }
repo=$(realpath "$1"); shift
git -C "$repo" rev-parse --git-dir >/dev/null

opts=(-a --delete --exclude .git --exclude __pycache__ --exclude '*.pyc' --exclude .pytest_cache
      --exclude node_modules --exclude '*.jsonl' --exclude .env --exclude '*.env' --exclude '.credentials*')
[ $dry -eq 1 ] && opts+=(--dry-run -v)
targets=("$repo")
for d in "$@"; do
  [ $dry -eq 1 ] && targets+=("$(realpath "$d")")
  rsync "${opts[@]}" "$(realpath "$d")/" "$repo/$(basename "$d")/"
done

# Scan the whole repo (not only what we just copied); in dry-run also the sources.
if command -v gitleaks >/dev/null; then
  for t in "${targets[@]}"; do
    gitleaks dir "$t" --no-banner --redact >/dev/null || { echo "ABORT: gitleaks found secrets (run: gitleaks dir $t)" >&2; exit 1; }
  done
else
  tokens='-----BEGIN [A-Z ]*PRIVATE KEY-----|\bAKIA[0-9A-Z]{16}\b|\bgh[pousr]_[A-Za-z0-9]{30,}|\bgithub_pat_[A-Za-z0-9_]{30,}|\bsk-[A-Za-z0-9_-]{20,}|\bxox[abpr]-[A-Za-z0-9-]{10,}|\bAIza[0-9A-Za-z_-]{35}'
  assign='(password|passwd|secret|token|api[_-]?key)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9/+_.-]{12,}'
  ex=(-rIn --exclude-dir=.git --exclude-dir=node_modules --exclude='*.jsonl')
  hits=$( { grep "${ex[@]}" -E -e "$tokens" "${targets[@]}"; grep "${ex[@]}" -Ei -e "$assign" "${targets[@]}"; } || true)
  if [ -n "$hits" ]; then
    echo "ABORT: possible secrets (file:line):" >&2
    cut -d: -f1,2 <<<"$hits" >&2
    exit 1
  fi
fi
leaks=$(find "$repo" -path "$repo/.git" -prune -o \( -name .env -o -name '*.env' -o -name '.credentials*' \) -print)
[ -z "$leaks" ] || { echo "ABORT: credential files in repo:" >&2; echo "$leaks" >&2; exit 1; }

if [ $dry -eq 1 ]; then echo "dry-run: scan clean, nothing committed"; exit 0; fi
git -C "$repo" add -A
if git -C "$repo" diff --cached --quiet; then echo "no changes"; exit 0; fi
git -C "$repo" commit -q -m "backup: $(date '+%Y-%m-%d %H:%M')"
git -C "$repo" push -q
echo "backed up: $(git -C "$repo" log --oneline -1)"

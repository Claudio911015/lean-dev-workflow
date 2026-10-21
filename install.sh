#!/usr/bin/env bash
# Install the kit: skills -> ~/.claude/skills, memory templates -> ~/memory (missing files only).
# Never touches an existing CLAUDE.md; prints what to add instead.
# Usage: install.sh [--dry-run] [--force]   (--force overwrites skills that already exist)
set -euo pipefail

dry=0; force=0
for a in "$@"; do
  case $a in
    --dry-run) dry=1 ;;
    --force) force=1 ;;
    *) sed -n 2,4p "$0"; exit 2 ;;
  esac
done
kit=$(cd "$(dirname "$0")" && pwd)
skills=${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}
memory=${MEMORY_DIR:-$HOME/memory}
run() { if [ $dry -eq 1 ]; then echo "would: $*"; else "$@"; fi; }

run mkdir -p "$skills" "$memory"
for s in "$kit"/skills/*/; do
  name=$(basename "$s")
  if [ -e "$skills/$name" ] && [ $force -eq 0 ]; then
    echo "skip skill $name (exists; --force to overwrite)"
  else
    run rm -rf "${skills:?}/$name"
    run cp -r "$s" "$skills/$name"
    echo "skill $name -> $skills/$name"
  fi
done

for f in "$kit"/templates/memory/*.md; do
  base=$(basename "$f")
  [ "$base" = sessions-YYYY-MM.md ] && base="sessions-$(date +%Y-%m).md"
  if [ -e "$memory/$base" ]; then echo "keep $memory/$base"
  else run cp "$f" "$memory/$base"; echo "memory $base -> $memory/$base"; fi
done

cat <<EOF

Next:
  1. Merge $kit/templates/CLAUDE.md into your ~/.claude/CLAUDE.md and fill the <placeholders>.
     The lines that make the skills load (without them agents rarely invoke the skills on their own):
       - At the start of every session and before ending one, invoke the session-memory skill.
       - Before implementing, fixing, refactoring or deploying code, invoke the lean-dev-workflow skill.
       - Before adopting or editing a skill or a rule in this file, invoke the ab-test-prompts skill.
  2. Fill $memory/personality.md and user.md (5 minutes; they are read every session).
  3. Optional: create a private repo and back up with: bash $skills/memory-backup/scripts/backup.sh --dry-run <repo> $memory $skills
EOF

---
name: ab-test-prompts
description: Use when changing an instructions file (CLAUDE.md, AGENTS.md), writing or editing a skill, or adopting someone else's prompt or skill, and you need to know whether it actually changes agent behaviour rather than assuming it does.
---

# A/B testing prompts and skills

**Principle:** a prompt change is code without tests until you have watched agents run with and without it on real tasks. A skill can also look perfect and never get loaded.

## When

- Before adopting a third-party skill or prompt ("trending repo says it saves 50% tokens").
- After writing or editing a skill or an instructions-file rule.
- When a rule "should" work but you keep seeing the old behaviour.

## Procedure

1. **Pick 2-4 real tasks** from a repo you know, phrased the way the user would phrase them, each one tempting the failure the rule targets (e.g. a feature that invites extra flags; a bug fix with a duplicated helper). Put one per line in `tasks.txt`.
2. **Write the variant:** a markdown snippet to append to `CLAUDE.md`, or a skill directory.
3. **Run control and variant** with the same model and tasks, in isolated git worktrees:
   ```bash
   bash scripts/ab_run.sh <repo> tasks.txt base 2
   bash scripts/ab_run.sh <repo> tasks.txt path/to/snippet.md 2
   AB_VERIFY='<full test command>' python3 scripts/ab_measure.py ab-out
   ```
4. **Read every diff and closing message**, not just the numbers. Counts lie: a smaller diff may have dropped required work.
5. **Check skill loading:** the `skills` column. A skill nobody loads does nothing. If it's 0, add an explicit imperative line to the instructions file ("Before X, invoke skill Y") and re-run.
6. **Report as a signal:** n per cell, model, what changed, what didn't, cost. Keep only the parts of the variant that changed behaviour.
7. **Clean up:** `python3 scripts/ab_measure.py ab-out --cleanup` removes the worktrees.

## Environment knobs

| Variable | Use |
|---|---|
| `AB_SETUP` | Command run inside each worktree before the agent, e.g. `ln -s "$AB_REPO/.venv" .venv` |
| `AB_ALLOWED_TOOLS` | Tools the headless agent may use (default: read/edit + git diff/status) |
| `AB_BUDGET_USD` | Per-run cap (default 3) |
| `AB_VERIFY` | Command `ab_measure.py` runs in each worktree to check the result |

`AB_ALLOWED_TOOLS` **adds** to the permissions in your own settings; it does not restrict them. If your settings allow `ssh`, `curl` or deploy commands, test agents can run them too. When tasks mention real hosts or services, run the harness in a container or a user without those permissions.

Python projects with an editable install import the *original* source, not the worktree's. Set `PYTHONPATH="$PWD/src"` in `AB_VERIFY` and say in the task how to run tests with it.

## Common mistakes

| Mistake | Instead |
|---|---|
| One run per cell and a confident verdict | Call it a signal; run 2+ reps for anything you'll keep |
| Toy tasks | Real tasks from a real repo |
| Different models for control and variant | Same model, same tasks |
| Running in the main checkout | Always worktrees; the scripts never touch HEAD |
| Measuring only lines of code | Also tests run, skill loaded, what was skipped |

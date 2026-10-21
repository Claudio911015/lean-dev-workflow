# CLAUDE.md

Global instructions for Claude Code. Copy to `~/.claude/CLAUDE.md` (or `~/CLAUDE.md` if you run Claude from your home directory) and fill in every `<placeholder>`. Delete sections you don't need.

## Memory

Memory lives in `~/memory/`. **At the start of every session and before ending one, invoke the `session-memory` skill.**

- Canonical names (always these spellings, in memory and in replies): `<machine-1>`, `<machine-2>`, `<service>`, project names as in *Projects* below.
- Never write secrets into memory; write where the secret lives instead.
- Back up memory with the `memory-backup` skill to a **private** repo: `<private-repo-path>`.

## Implementations and deploys

For any request to implement a system, deploy code or install software:

1. **Dry-run or tests first** (`--dry-run`, `--check`, `-n`, or the test suite) before applying real changes.
2. **Verify it works**: check the expected result before calling the task done.
3. **If something fails, write a rollback plan** back to the last known-good state before attempting any fix.

## Don't over-build

- Do only what was asked: skip flags, options, columns or flexibility nobody requested, and name them in one line at the end.
- Reuse what already exists in the repo or the standard library; never add a dependency for a few lines.
- **Before implementing, fixing, refactoring or deploying code, invoke the `lean-dev-workflow` skill.**
- **Before adopting or editing a skill or a rule in this file, invoke the `ab-test-prompts` skill.**

## Token efficiency

- Truncate exploratory shell output (`| head -5`, `| tail -5`, compact `--format`).
- Never dump raw JSON; filter it in flight (`jq`, a short `python3 -c`).
- Expensive queries (APIs, large dumps): cache once in `/tmp/<descriptive-name>`, then grep the cache.
- Grep/Glob before Read; read with offset/limit when you only need a section; don't re-read files already in context.
- Heavy exploration → subagent, so only the curated result enters the main context.
- Model choice for subagents: implementers `sonnet` (mechanical tasks `haiku`); spec and quality reviewers `haiku`, or `sonnet` when the diff touches multi-file architecture or security; extraction/reformatting `haiku`.
- One task, one session. Don't mix unrelated topics in one conversation.

## Testing

- `<language>`: `<test command>`; pattern `<tests/test_feature.py>`.
- Before merge, push or deploy: the full suite passes.

## Commits

- Messages explain *why* more than *what*; the diff shows the what.
- Tests pass locally before pushing.
- `<attribution / signing rule, if any>`

## Machines

| Machine | Role | Reach it |
|---|---|---|
| `<machine-1>` | `<user-facing CLI, notebooks>` | local |
| `<machine-2>` | `<scheduled jobs, Docker>` | `ssh <user>@<host>` |

Before SSH, Docker, systemctl or API calls based on remembered hosts, ports or tokens, verify them live (see `session-memory`).

## Projects

- `<path>` — `<one line: what it is, stack, where it runs>` · see its own `CLAUDE.md`

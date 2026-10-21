---
name: lean-dev-workflow
description: Use when implementing a feature, fixing a bug, refactoring or deploying code, or when a change is tempting extra flags, options, dependencies, abstractions or "just in case" code.
---

# Lean dev workflow

**Principle:** the smallest change that fully solves what was asked — tested, reviewed and recorded.

## 1. Scope (before writing)

Read the code the change touches and list everything it must reach: callers, tests, fixtures, config, exports, deploy files. That is scope; extra features are not.

- New project or feature → brainstorm/design first and propose the minimal option first.
- If the project has its own instructions file (`CLAUDE.md`, `AGENTS.md`) or architecture notes, read them before searching the code.

## 2. The ladder: take the first rung that fully solves it

1. Does it need to exist? Flags, options, columns, formats or config nobody asked for → don't write them; name them in the closing note.
2. Already in the repo? (a helper, shared module, existing script) → reuse it the way neighbouring code does.
3. Standard library, platform feature or an installed dependency? → use it. Never add a dependency for a few lines.
4. Otherwise: the minimum code that works, keeping the existing structure (layers, interfaces, conventions). No wrappers, no "for later".

Bug fix: grep every caller **and every duplicated copy** of the function; fix the root cause. If a copy stays untouched, say why in the closing note.

## 3. Never cut

Validation at trust boundaries, error handling that prevents data loss, security, anything the user asked for. For infrastructure: dry-run, verification, rollback plan, and never let a sync/deploy overwrite production data (exclude databases, `data/`, `.env`).

## 4. Tests

- Non-trivial logic (branch, loop, parser, money, security) → write the test first and watch it fail.
- Before claiming done: run the project's **full suite** (`pytest`, `ctest`, `npm test`…), not just the file you touched. Report the real count.

## 5. Reviewers

| Change | Review |
|---|---|
| Trivial (≤ ~20 lines, 1 file) | Self-review of the diff |
| Multi-task plan | Per-task spec + quality review (a small, cheap model is enough; a stronger one for multi-file architecture or security) |
| Before merging/pushing a branch | Whole-branch review; don't skip it |

## 6. Commit and deploy

Green tests → commit message that explains *why* → push. Deploy as the project documents it, then verify the running service (logs, health check).

## 7. Close

- **Reply:** 1-2 lines on what was skipped or not verified, and the risk.
- **Memory:** before ending the session, invoke the `session-memory` skill (or record decisions and gotchas wherever your setup keeps them).

## Common mistakes

| Temptation | Instead |
|---|---|
| "I'll add `--output`/`--format`, it's cheap" | Not asked → name it in the close |
| "The tests for this file pass, good enough" | Full suite |
| "Too small to need review" | Only if it fits the trivial row |
| "I'll fix the copy I found" | Grep for duplicates; justify any you leave |
| "I'll abstract in case another provider comes" | Wait for the second real case |

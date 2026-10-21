# lean-dev-workflow

An agent skill for Claude Code (and other [Agent Skills](https://agentskills.io) hosts) that keeps coding agents from over-building, and wraps that in a full dev loop: scope → minimal change → full test suite → review → commit → close.

It started from [Ponytail](https://github.com/DietrichGebert/ponytail) (MIT). Its "do the least" ladder is kept; the rest is a workflow around it.

## Why

Before writing this, the Ponytail rules were A/B-tested on a real Python project (CLI + SQLite, ~260 tests), with three tasks run once with and once without the rules:

| Task | Without | With |
|---|---|---|
| Export an event to CSV | 63 lines, added an unrequested `--output` flag and an extra column | 42 lines, skipped both and said so |
| Retry on 5xx/timeouts | equivalent | equivalent |
| Map `1`/`X`/`2` labels | equivalent | equivalent |

The only rule that changed the output was **"skip what wasn't asked, and name it"**. Then the skill itself was tested:

| | No skill | Skill installed | Skill + one line in `CLAUDE.md` |
|---|---|---|---|
| Agent loaded the skill | — | 0/4 | 2/4 |
| Ran the full test suite | 1/4 | 1/4 | 4/4 |

Small samples (1-4 runs per cell, Sonnet), so treat these as a signal, not proof. The practical lesson: **installing the skill is not enough; reference it from your instructions file.**

## Install

Claude Code, personal skills:

```bash
git clone https://github.com/Claudio911015/lean-dev-workflow /tmp/ldw
mkdir -p ~/.claude/skills && cp -r /tmp/ldw/skills/lean-dev-workflow ~/.claude/skills/
```

Then add this to your `~/.claude/CLAUDE.md` (or the project's `CLAUDE.md` / `AGENTS.md`). Without it, the agent rarely loads the skill on its own:

```markdown
## Don't over-build
- Do only what was asked: skip flags, options, columns or flexibility nobody requested, and name them in one line at the end.
- Reuse what already exists in the repo or the standard library; never add a dependency for a few lines.
- **Before implementing, fixing, refactoring or deploying code, invoke the `lean-dev-workflow` skill.**
```

## What's inside

`skills/lean-dev-workflow/SKILL.md`, about 500 words:

1. Scope
2. The ladder
3. What is never cut
4. Tests
5. Reviewers by change size
6. Commit/deploy
7. Closing note and memory

It pairs well with [superpowers](https://github.com/obra/superpowers) (TDD, brainstorming, subagent-driven development) but doesn't require it.

## License

MIT

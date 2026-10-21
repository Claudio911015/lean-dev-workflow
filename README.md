# lean-dev-workflow

A small kit that turns Claude Code into a disciplined, low-waste collaborator that remembers. It has four skills, a global instructions template, memory templates and an installer. Every rule in it was A/B-tested on real tasks before it went in.

| Piece | What it does |
|---|---|
| `skills/lean-dev-workflow` | Don't over-build: the "do the least" ladder, full-suite tests, size-based review, commit/deploy, closing note |
| `skills/session-memory` | Read memory at session start, distrust stale facts, write a dated session log before leaving |
| `skills/ab-test-prompts` | Measure whether a prompt/skill change actually changes agent behaviour (scripts included) |
| `skills/memory-backup` | Version memory + skills to a private git repo, aborting on any secret |
| `templates/CLAUDE.md` | Global instructions: memory, dry-run → verify → rollback, token efficiency, testing, commits |
| `templates/memory/` | `personality`, `user`, `preferences`, `decisions`, `people`, `sessions` index + monthly log |
| `install.sh` | Copies skills and missing memory files; never touches your `CLAUDE.md` |

## Install

```bash
git clone https://github.com/Claudio911015/lean-dev-workflow
cd lean-dev-workflow
./install.sh --dry-run   # see what it would do
./install.sh             # skills -> ~/.claude/skills, templates -> ~/memory (existing files kept)
```

Then merge `templates/CLAUDE.md` into your `~/.claude/CLAUDE.md` and fill the `<placeholders>`. **Keep the three "invoke the … skill" lines.** In testing, installed skills were almost never loaded without them (details below).

Recommended alongside: [superpowers](https://github.com/obra/superpowers) (brainstorming, TDD, subagent-driven development), which `lean-dev-workflow` defers to for those steps. Optional: [graphify](https://github.com/Graphify-Labs/graphify) to build a knowledge graph over your memory directory.

## How the pieces fit

```
session start ──> session-memory (read memory, verify stale facts)
      │
task ──> lean-dev-workflow (scope → ladder → tests → review → commit)
      │
changing a rule or skill ──> ab-test-prompts (control vs variant on real tasks)
      │
session end ──> session-memory (dated log, decisions) ──> memory-backup (scan → commit → push)
```

## Evidence

All runs are headless Claude Code (`claude -p`), Sonnet, in isolated git worktrees. Samples are small (1-2 runs per cell), so read these as signals, not proof.

**Over-building** (Python CLI + SQLite project, ~260 tests). These are the [Ponytail](https://github.com/DietrichGebert/ponytail) rules vs none:

| Task | Without | With |
|---|---|---|
| Export an event to CSV | 63 lines, unrequested `--output` flag + extra column | 42 lines, skipped both and said so |
| Retry on 5xx/timeouts | equivalent | equivalent |
| Map `1`/`X`/`2` labels | equivalent | equivalent |

Only "skip what wasn't asked, and name it" changed the output, so that's the rule kept.

**Skill loading:**

| | No skill | Skill installed | Skill + one line in `CLAUDE.md` |
|---|---|---|---|
| Agent loaded the skill | — | 0/4 | 2/4 |
| Ran the full test suite | 1/4 | 1/4 | 4/4 |

**Session memory:** see [`docs/evidence.md`](docs/evidence.md).

## Credits

The over-building ladder is adapted from [Ponytail](https://github.com/DietrichGebert/ponytail) (MIT).

## License

MIT

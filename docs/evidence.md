# Evidence

How each rule in the kit was tested, and what it showed. All runs: headless Claude Code (`claude -p`), Sonnet, isolated git worktrees, using `skills/ab-test-prompts/scripts`. Small samples, so these are signals, not proof.

## lean-dev-workflow

Repo: a Python CLI + SQLite project (~260 tests).

**Rules vs no rules** (1 run per cell, Ponytail-derived rules appended to `CLAUDE.md`):

| Task | Without | With |
|---|---|---|
| Add a CLI command to export an event to CSV | 63 lines; added an unrequested `--output` flag and an extra column | 42 lines; skipped both and listed them in the closing note |
| Retry requests on 5xx/timeouts | 3 attempts, exponential backoff, no retry on 4xx, tests | equivalent |
| Map `1`/`X`/`2` outcome labels | 2-line fix + test | equivalent |

**Skill loading** (4 runs per cell):

| | No skill | Skill installed | Skill + imperative line in `CLAUDE.md` |
|---|---|---|---|
| Agent loaded the skill | — | 0/4 | 2/4 |
| Ran the full test suite (not just one file) | 1/4 | 1/4 | 4/4 |

Takeaway: an installed skill is mostly ignored; the imperative line is what makes it work.

## session-memory

Repo: a small utility repo with a `memory/` directory holding an August session log (server `nas` at an IP, a service `api`). Control: `CLAUDE.md` says only "Memory lives in `./memory/`". Variant: the skill plus one line, "At the start of every session and before ending one, invoke the `session-memory` skill." 2 runs per cell.

| | Control | Variant |
|---|---|---|
| Agent loaded the skill | — | 4/4 |
| Task ending "that's all for today, we're closing": wrote a dated session log | 0/2 | 2/2 |
| "What did we do in August with the server? Give me the command to restart the service": answered from memory | 2/2 | 2/2 |
| … and checked the 70-day-old IP live before giving the command | 0/2 (repeated it with a caveat) | 2/2 (found it unreachable, said so) |
| Cost per run | $0.11-0.13 | $0.13-0.14 |

Side finding: `--allowedTools` adds to your settings' permissions instead of restricting them, so variant runs could `ping`/`ssh` the remembered host. This is now documented in `ab-test-prompts`.

## memory-backup

Functional test with a local bare repo:

| Case | Result |
|---|---|
| Clean notes + a skill containing a `.env` | Committed; `.env` excluded |
| `ghp_…` token, private-key header, `AKIA…` key, `sk-…` key | Aborted before `git add` (4/4) |
| `password = "…"` assignment | Aborted |
| Prose with `risk-adjusted-returns…`, `task-management…`, "token budget is 2000" | Committed (no false positive) |

## install.sh

`--dry-run` touched nothing; a real run installed 4 skills + 7 memory files; a re-run kept user-edited files; `--force` replaced skills; unknown flags exit 2.

## ab-test-prompts

Exercised end-to-end by producing the session-memory results above. That run caught a bug in its own runner: `claude -p` read the tasks file from stdin and mixed tasks. Fixed with `< /dev/null`. No A/B was run on whether an agent *given this skill* designs good experiments.

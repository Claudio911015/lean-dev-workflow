---
name: session-memory
description: Use when a session starts in a workspace that has a memory directory, when the user wraps up ("that's all", "we're done", "cerramos", "nos vemos"), when asked what was done in a past period, or before acting on remembered IPs, ports, tokens, paths or service state.
---

# Session memory

**Principle:** the agent forgets everything between sessions; the memory directory is the only continuity. Read it at the start, distrust it when it's old, write it before leaving.

The memory directory is whatever the user's instructions file names (default `~/memory/`). Layout (templates in this kit's `templates/memory/`):

| File | Holds | Update when |
|---|---|---|
| `personality.md` | How to think and talk with this user | They correct tone, length, language |
| `user.md` | Profile, role, technical level, active projects | Role or projects change |
| `preferences.md` | Interaction and tooling preferences | They state a preference |
| `decisions.md` | Dated technical decisions (context → decision → consequences) | A non-obvious decision is taken |
| `people.md` | People and handles that matter | Someone new is mentioned |
| `sessions.md` | Index of monthly logs | A new month starts |
| `sessions-YYYY-MM.md` | One entry per session | Every session that did something |

## 1. Start of session

Read `personality.md`, `user.md`, `preferences.md`, `decisions.md`, `people.md`, `sessions.md`, and the session logs of the **last 3 months**. Don't announce it; just use it.

## 2. Before acting on a remembered fact

IPs, ports, tokens, paths, service state: if the fact is older than ~60 days or has no recent mention, **verify it against the live system first** (`ip a`, `ss -ltn`, `systemctl status`, `docker ps`, an API ping). Memory describes what *was* true.

## 3. Questions about the past

- "What did we do in March?" → read that month's log.
- A topic across months → grep all `sessions-*.md`, say which month(s) it appears in, load those entries.
- Not found → search any knowledge graph or notes index the user has before saying there's no record.

## 4. End of session (REQUIRED when anything was done)

Append to `sessions-YYYY-MM.md` (create it and add it to `sessions.md` if it's a new month):

```markdown
## YYYY-MM-DD — <short title of the main topic>
- <what was done, with the concrete artifact: file, commit, service, URL>
- Decision: <decision> (why: <reason>)
- Own mistake corrected: <what I claimed wrongly, if any>

**Pending:**
- <open item, concrete enough to act on cold>
```

Then update `decisions.md`, `people.md`, `preferences.md`, `user.md` **only** with what changed. Use absolute dates, never "yesterday".

## Naming

Use one canonical name per machine, service and project (the one in the user's instructions file). Variants ("the server", "homelab box", "srv1") split the same thing into several entries and break search and knowledge graphs.

## Common mistakes

| Mistake | Instead |
|---|---|
| Logging "fixed the bug" | Log what, where, and the commit/file |
| Writing a decision without its reason | Context → decision → consequences |
| Trusting a 4-month-old IP or token | Verify live, then update memory |
| Skipping the log because the session was short | One bullet is fine; no entry is not |
| Putting secrets in memory | Never; reference where the secret lives instead |

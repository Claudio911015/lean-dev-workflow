---
name: memory-backup
description: Use when the user wants their agent memory, notes or personal skills versioned or backed up to git, when memory files were edited in bulk, or before pushing a memory or skills directory anywhere.
---

# Memory backup

**Principle:** memory and skills are worth versioning, and they are exactly where secrets leak: an agent writes "the token is …" into a note, and a later push publishes it. Copy → scan → commit, and abort on any hit.

## Setup (once)

1. Create a **private** git repo (e.g. `agent-state`) and clone it locally.
2. Decide what goes in: the memory directory, personal skills, the global instructions file. Never session transcripts: they're raw conversation and can't be reliably sanitised.

## Run

```bash
bash scripts/backup.sh --dry-run <repo> <dir>...   # shows what would be copied and scanned
bash scripts/backup.sh <repo> <dir>...             # copy, scan, commit, push
```

Each `<dir>` is copied to `<repo>/<basename>/` (rsync `--delete`, excluding `.env`, credentials, caches). The scan uses `gitleaks` if installed; otherwise a built-in regex set (private keys, cloud/API token prefixes, `password=`/`token=` assignments). Any hit aborts **before** `git add`.

## When it aborts

Fix the source, not the copy: remove the secret from the memory file and replace it with where the secret lives ("token in `~/.config/x/token`, mode 600"). If it was ever pushed, **rotate the secret**. Deleting it from history is not enough once it has been on a remote.

## Common mistakes

| Mistake | Instead |
|---|---|
| Public repo "because it's just notes" | Private; notes contain hosts, paths, habits |
| Scanning only the memory dir | Scan the whole repo; skills ship `.env` files too |
| Backing up transcripts to git | Encrypted backup (e.g. restic) if you need them |
| Removing a leaked secret and moving on | Rotate it |

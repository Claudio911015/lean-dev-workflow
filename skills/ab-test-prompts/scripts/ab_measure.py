#!/usr/bin/env python3
"""Summarise ab_run.sh results: cost, turns, skills loaded, tests run, diff size.

Usage: ab_measure.py <ab-out> [--cleanup]
  AB_VERIFY='<cmd>'    run in each worktree; reports ok/FAIL
  AB_TEST_PATTERN=re   which Bash commands count as "ran tests"
Writes <run>/diff.patch and <run>/result.txt for reading every run by hand.
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path

TEST_RE = re.compile(os.environ.get(
    "AB_TEST_PATTERN", r"pytest|npm (run )?test|ctest|go test|cargo test|mvn test|gradle test"))
EXCLUDE = [":!CLAUDE.md", ":!.claude", ":!.venv", ":!node_modules"]


def git(wt, *args):
    return subprocess.run(["git", "-C", wt, *args], capture_output=True, text=True).stdout


def parse(jsonl):
    skills, tests, result = [], [], {}
    for line in jsonl.read_text(errors="replace").splitlines():
        try:
            o = json.loads(line)
        except ValueError:
            continue
        if o.get("type") == "assistant":
            for c in o["message"].get("content", []):
                if c.get("type") != "tool_use":
                    continue
                if c["name"] == "Skill":
                    skills.append(c["input"].get("skill", "?"))
                elif c["name"] == "Bash" and TEST_RE.search(c["input"].get("command", "")):
                    tests.append(c["input"]["command"])
        elif o.get("type") == "result":
            result = o
    return skills, tests, result


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    out = Path(sys.argv[1])
    runs = sorted(p for p in out.iterdir() if (p / "run.jsonl").exists())
    if "--cleanup" in sys.argv:
        for r in runs:
            wt = (r / "worktree").read_text().strip()
            repo = os.path.dirname(git(wt, "rev-parse", "--path-format=absolute", "--git-common-dir").strip())
            subprocess.run(["git", "-C", repo, "worktree", "remove", "--force", wt])
        print(f"removed {len(runs)} worktree(s)")
        return

    verify = os.environ.get("AB_VERIFY")
    print(f"{'run':<28}{'cost':>6}{'turns':>6}{'+':>5}{'-':>5}  {'tests':<6}{'verify':<7}skills")
    for r in runs:
        wt = (r / "worktree").read_text().strip()
        skills, tests, res = parse(r / "run.jsonl")
        git(wt, "add", "-A", "-N", ".")
        add = rem = 0
        for row in git(wt, "diff", "--numstat", "--", ".", *EXCLUDE).splitlines():
            a, d, _ = row.split("\t", 2)
            add += int(a) if a.isdigit() else 0
            rem += int(d) if d.isdigit() else 0
        (r / "diff.patch").write_text(git(wt, "diff", "--", ".", *EXCLUDE))
        (r / "result.txt").write_text(res.get("result", "(no result)"))
        ok = "-"
        if verify:
            ok = "ok" if subprocess.run(verify, shell=True, cwd=wt, capture_output=True).returncode == 0 else "FAIL"
        print(f"{r.name:<28}{res.get('total_cost_usd', 0):>6.2f}{res.get('num_turns', 0):>6}"
              f"{add:>5}{rem:>5}  {len(tests):<6}{ok:<7}{','.join(sorted(set(skills))) or '-'}")


if __name__ == "__main__":
    main()

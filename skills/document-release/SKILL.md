---
name: document-release
description: Post-ship documentation sync. Cross-references the branch diff against all project docs, auto-updates factual changes, asks about narrative changes, polishes CHANGELOG voice, checks cross-doc consistency. Use after /ship or when user says "update docs", "sync documentation".
argument-hint: "[--skip-changelog]"
disable-model-invocation: false
---

# /document-release — Post-Ship Documentation Sync

Ensure every documentation file in the project is accurate and up to date after code changes ship.

## Input Sources

1. **`.craft/context/review.md`** — if it exists, use review findings to understand what changed and why
2. **`$ARGUMENTS`** — check for `--skip-changelog` flag
3. **Branch diff** — the primary source of truth for what needs updating

## Process

### 1. Pre-flight

Detect the base branch:
```bash
gh pr view --json baseRefName -q .baseRefName 2>/dev/null || gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo "main"
```

Abort if on main/master: "You're on the base branch. Run from a feature branch."

Gather context:
```bash
git diff <base>...HEAD --stat
git diff <base>...HEAD --name-only
git log <base>..HEAD --oneline
```

Find all documentation files:
```bash
find . -maxdepth 2 -name "*.md" -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./.craft/*" -not -path "./vendor/*" | sort
```

Classify changes: new features, changed behavior, removed functionality, infrastructure.

Output: "Analyzing N files changed across M commits. Found K documentation files to review."

### 2. Per-File Audit

Read each documentation file and cross-reference against the diff:

- **README.md** — features, install/setup, examples, troubleshooting still accurate?
- **ARCHITECTURE.md** — diagrams, component descriptions match current code? Be conservative — only update clear contradictions.
- **CONTRIBUTING.md** — setup instructions work? New-contributor smoke test: would each step succeed?
- **CLAUDE.md** — project structure, commands, build/test instructions match reality?
- **Other .md** — read, determine purpose, check for contradictions with the diff.

For each file, classify needed updates:
- **Auto-update** — factual corrections clearly warranted by the diff (paths, counts, tables, command names)
- **Ask user** — narrative changes, section removal, security model changes, large rewrites (>10 lines in one section)

### 3. Apply Auto-Updates

Use Edit tool for each change. One-line summary per edit:
- GOOD: "README: added /document-release to skills table, updated skill count 13->14"
- BAD: "Updated README"

**Never auto-update:**
- Project positioning or introduction
- Philosophy or design rationale
- Security model descriptions
- Never delete entire sections

### 4. Ask About Risky Changes

For each risky/narrative update, present:
- What the change is
- Why it seems needed (evidence from the diff)
- Recommendation
- Option to skip

Apply immediately after approval.

### 5. CHANGELOG Voice Polish

Skip if CHANGELOG doesn't exist, wasn't modified in this branch, or `--skip-changelog` is set.

**Rules — non-negotiable:**
- NEVER delete, replace, or regenerate entries — polish wording ONLY
- ALWAYS use Edit tool — never Write tool on CHANGELOG
- Lead with what the user can DO: "You can now..." not "Refactored the..."
- Internal/contributor changes belong in a separate "### For contributors" subsection
- If an entry looks wrong, ask — don't silently fix

### 6. Cross-Doc Consistency

After individual audits, check across documents:
- Feature/capability lists match across README and CLAUDE.md
- Version numbers consistent across all docs
- Discoverability: every .md file reachable from README or CLAUDE.md. If a doc exists but isn't linked, flag it.
- Auto-fix factual inconsistencies (version mismatch). Ask about narrative contradictions.

### 7. TODOS Cleanup

Skip if TODOS.md doesn't exist.

- **Completed items:** cross-reference diff against open TODOs. Mark completed with evidence.
- **New deferred work:** grep diff for TODO/FIXME/HACK comments. For meaningful ones, ask if they should be captured in TODOS.md.

### 8. Present Results

**Do NOT auto-commit. Do NOT auto-push.** The user controls this.

Output a doc health summary:
```
Documentation health:
  README.md        Updated (added /document-release to skills table, count 13->14)
  ARCHITECTURE.md  Current (no changes needed)
  CONTRIBUTING.md  Skipped (doesn't exist)
  CHANGELOG.md     Voice polished (2 entries adjusted)
  CLAUDE.md        Updated (added document-release trigger)
  TODOS.md         Skipped (doesn't exist)
```

Tell the user: "Doc updates ready. Commit when you're ready."

## Context Output

Save summary to `.craft/context/docs-release.md`:
```markdown
---
skill: document-release
files_reviewed: <count>
files_updated: <count>
auto_updates: <count>
user_decisions: <count>
timestamp: YYYY-MM-DD
---

[Doc health summary + details of each change made]
```

## When to auto-invoke

Trigger when:
- After `/ship` creates a PR (recommend, don't auto-run)
- User says "update docs", "sync documentation", "post-ship docs"

Don't trigger for:
- During active implementation
- When no .md files exist in the repo

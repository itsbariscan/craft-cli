---
name: ship
description: Use when the user wants to ship, merge, or create a PR from a feature branch.
argument-hint: "[--dry-run | --resume | --hotfix]"
disable-model-invocation: true
---

# /ship — Ship Workflow

Run a structured pipeline to ship the current branch.

Check `$ARGUMENTS` for flags:
- `--dry-run` — Run steps 1-6 only (no commit/push/PR)
- `--resume` — Skip to the first incomplete step (check `.craft/context/ship-progress.md` for state)
- `--hotfix` — Skip eval gate (step 5), streamline for urgent fixes

## Pipeline

Execute these steps in order. Stop on failure at any step.

### 1. Pre-flight
```bash
# Verify not on main/master
branch=$(git branch --show-current)
if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  echo "ABORT: Cannot ship from $branch. Create a feature branch."
  exit 1
fi

# Check for uncommitted changes
git status --porcelain
```
If uncommitted changes exist, ask user whether to stash, commit, or abort.

### 2. Sync
```bash
git fetch origin
git merge origin/main
```
If conflicts: stop and help resolve. Do not auto-resolve.

### 3. Build
```bash
# Next.js projects
npm run build
# or equivalent for the project
```
If build fails: show errors, fix, rebuild.

### 4. Test
```bash
npm test
```
If no test script exists, note it and continue. If tests fail: show failures, fix, re-test.

### 5. Eval Gate (conditional)
Check if any of these file patterns changed in the branch:
- `**/prompts/**`, `**/templates/**`, `**/content/**`
- Files containing prompt strings or LLM calls

If yes: run `/eval run` and check pass rates. If pass rate drops below baseline, stop and investigate.
If no content/prompt files changed: skip this step.

### 6. Pre-landing Review
Run `/review` against the branch diff. This produces critical + informational findings.

- **Critical findings:** Must be resolved before continuing. Present one at a time.
- **Informational findings:** Note in PR body. Don't block.

### 7. Commit
Structure commits for bisectability when multiple types of changes exist:
1. Infrastructure changes (config, deps, migrations)
2. Logic changes (business logic, API routes, server actions)
3. UI changes (components, styles, layouts)

Each commit should be independently valid. Use descriptive messages that explain *why*.

Ask user to confirm commit messages before creating.

### 8. Push + PR
```bash
git push -u origin $(git branch --show-current)
gh pr create --title "..." --body "..."
```

PR body includes:
- Summary of changes
- Review findings (informational items)
- Test results
- Eval results (if applicable)
- Any known limitations or follow-ups

## Stop Conditions

The pipeline **only stops** for:
- Running on main/master branch
- Merge conflicts
- Build failure
- Test failure
- Eval regression
- Unacknowledged critical review findings

Everything else: note and continue.

## Context Integration

Before starting, check `.craft/context/` for:
- `review.md` — If a review was already run, use its findings instead of re-running step 6
- `eval.md` — If evals were already run, use their results instead of re-running step 5

After each step, save progress to `.craft/context/ship-progress.md` so `--resume` can pick up where you left off.

**Next step:** After PR is created, recommend → `/qa <deployed-url>` to verify the deployment.

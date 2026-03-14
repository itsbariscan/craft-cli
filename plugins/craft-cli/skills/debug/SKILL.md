---
name: debug
description: Use when a bug is reported, an error appears, tests fail unexpectedly, or the user needs to debug an issue.
disable-model-invocation: false
---

# /debug — Systematic Debugging

Follow a strict 4-phase debugging protocol. No shortcuts.

## Phase 1: Reproduce

Confirm the bug exists and get a reliable trigger.

- What is the exact error message or unexpected behavior?
- What are the exact steps to reproduce?
- Does it reproduce consistently or intermittently?
- What environment? (browser, Node version, OS, local vs deployed)

**Rule:** Do not proceed until you have a reliable reproduction. If you can't reproduce it, say so and investigate why.

## Phase 2: Isolate

Before investigating, check `.craft/knowledge/` for entries with `type: postmortem` whose keywords match the current error, affected file, or code area. Past postmortems may reveal recurring patterns — check those paths first.

Narrow to the failing component. Do not guess.

- Read the full error message and stack trace. Every line.
- Check recent changes: `git log --oneline -10` and `git diff` — did something change near the failure?
- Trace the data flow from input to error. Where does the actual diverge from expected?
- Check boundaries: API responses, database queries, environment variables, external services.
- Use binary search on the codebase if the failure area is unclear: comment out half, test, narrow.

**Rule:** No fixes until isolation is complete. Premature fixes mask root causes.

## Phase 3: Understand

Identify the root cause, not the symptom.

- What assumption broke? (A value that shouldn't be null? A timing issue? A type mismatch?)
- Why did this assumption exist? (Was it ever valid? Did something upstream change?)
- Is this a single bug or a pattern? Check for similar code paths.
- Could this have been caught earlier? (Type system, validation, test)

**Rule:** State the root cause in one sentence before proposing a fix. If you can't, you don't understand it yet.

## Phase 4: Fix + Verify

Fix the root cause. Verify the fix. Check for regressions.

- Fix the root cause, not the symptom
- Verify the original reproduction now works correctly
- Check adjacent code paths — could the same root cause affect similar logic?
- Run the test suite — did the fix break anything else?
- If applicable: add a test that would have caught this bug

## When to auto-invoke

Trigger when:
- An error appears in tool output
- Tests fail unexpectedly
- User reports a bug or unexpected behavior
- Build or runtime errors occur

Don't trigger for:
- Known/expected errors (like "file not found" when checking existence)
- Intentional test failures during TDD

## Postmortem Mode

When invoked with `--postmortem` or after fixing a significant bug, generate an incident report saved to `.craft/context/postmortem.md` with YAML frontmatter:

```markdown
---
skill: debug
bug_title: "<title>"
root_cause: "<one sentence>"
pattern: "<recurring pattern name, if any>"
detection: "<how it could have been caught>"
severity: critical|major|minor
timestamp: YYYY-MM-DD
---

## Postmortem: [bug title]
- **Symptom:** What the user saw
- **Root cause:** One sentence
- **Fix:** What changed and why
- **Detection:** How this could have been caught earlier
- **Pattern:** Is this a recurring class of bug?
```

After saving the postmortem, also persist it as a knowledge entry to `.craft/knowledge/YYYY-MM-DD-<bug-slug>.md` with `type: postmortem` so it can be surfaced in future debugging sessions. See the Knowledge System section in the meta-skill.

## Context Passing

**Next step:** After fix is verified → dispatch the `test-writer` agent to generate a regression test, then recommend `/review` to check for similar issues in adjacent code.

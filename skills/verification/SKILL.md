---
name: verification
description: Enforces evidence-based completion claims. No "done" without proof. Auto-invoked before completion.
allowed-tools: Read, Bash
disable-model-invocation: false
---

# Verification Before Completion

Enforce evidence-based completion claims. No "done" without proof. This is non-negotiable.

## The Rule

Before stating any of these:
- "Done"
- "That should work"
- "I've fixed it"
- "The implementation is complete"
- "Everything looks good"

You **must** have fresh, concrete evidence from the current session. Not from memory. Not from assumption. From actual tool output you can point to.

## What Counts as Evidence

| Claim | Required evidence |
|-------|-------------------|
| "Tests pass" | Actual test runner output showing pass |
| "Build succeeds" | Actual build output with no errors |
| "Bug is fixed" | Reproduction steps now produce correct behavior |
| "Feature works" | Demonstration of the feature functioning |
| "No regressions" | Test suite output after changes |
| "Types are clean" | `tsc --noEmit` output with no errors |
| "Code is correct" | You read the final state of every modified file |

## What Does NOT Count

- "I wrote the code correctly, so it should work" — run it
- "The tests passed earlier" — run them again after your changes
- "This is a simple change" — simple changes break things too
- "I'm confident this works" — confidence is not evidence
- Remembering that something worked — memory is unreliable, re-verify

## Verification Checklist

Before claiming completion of any implementation task:

1. **Re-read** every file you modified (the final version, not your memory of it)
2. **Run tests** if the project has them
3. **Run build** if the project has a build step
4. **Run type check** if the project uses TypeScript
5. **Verify** the original requirement is met — re-read what was asked
6. **Check** for unintended changes: `git diff` to see exactly what changed

## When Verification Fails

If any check fails:
- Do NOT claim completion
- Fix the issue
- Re-verify from scratch (not just the failed check — all checks)
- Only then report completion with the evidence

## Scope

This applies to:
- Implementation tasks
- Bug fixes
- Refactoring
- Any work where you claim something "works"

This does NOT apply to:
- Design discussions (`/think`)
- Planning (`/plan`)
- Research (`/docs`)
- Pure conversation

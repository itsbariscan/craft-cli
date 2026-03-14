---
name: review
description: Use when reviewing code before merging, checking a branch for issues, or the user asks about code quality.
disable-model-invocation: false
---

# /review — Pre-Landing Code Review

Perform a structured two-pass code review on the current branch's changes against main.

## Setup

1. Get the diff: `git diff main...HEAD` (or against the target branch if specified)
2. Identify all changed files and understand the scope of changes
3. Read each changed file in full (not just the diff) to understand context
4. Check `.craft/knowledge/` for `type: postmortem` entries relevant to the files being reviewed — past bugs in the same areas inform what to scrutinize

## Pass 1: CRITICAL (blocks /ship)

These issues **must** be resolved before merging. Check each:

- [ ] **RLS bypass** — Raw SQL or Supabase queries that skip Row Level Security
- [ ] **Auth boundary violations** — Server data leaking to client, missing Next.js middleware checks
- [ ] **Unvalidated mutations** — Data mutations without Zod/Drizzle validation at API boundaries
- [ ] **XSS vectors** — `dangerouslySetInnerHTML`, unsanitized content in server components
- [ ] **Exposed secrets** — API keys, service role keys, tokens in client bundles or committed code
- [ ] **TOCTOU races** — Time-of-check/time-of-use on concurrent mutations
- [ ] **SQL injection** — String concatenation in queries, unparameterized inputs
- [ ] **Missing error handling at boundaries** — Unhandled API/DB errors that crash the page

Reference the full checklist: [checklist](references/checklist.md)

## Pass 2: INFORMATIONAL (noted, non-blocking)

Flag but don't block:

- Missing error/loading/empty states
- N+1 queries (sequential Supabase calls that could be batched)
- Client-side fetching that should be server-side
- Missing accessibility (semantic HTML, ARIA, keyboard nav)
- Dead code, `any` types, magic strings
- Stale SEO metadata
- Performance concerns (large bundles, unoptimized images)
- Missing TypeScript types or overly broad types

## Resolution Protocol

For each **critical** issue:
1. Present the problem clearly with file path and line
2. Explain the risk
3. Recommend the fix
4. Offer alternatives if the fix has tradeoffs

**One critical issue per question.** Don't batch. Let the user address each before moving on.

## Output Format

```
## Review: [branch-name]

### Critical Issues (Pass 1)
[numbered list with severity, or "None found"]

### Informational (Pass 2)
[bulleted list grouped by category]

### NOT in scope
[what this review intentionally didn't check]

### Summary
[1-2 sentence overall assessment]
```

## Agent Dispatch

When reviewing branches with more than 5 changed files, dispatch the `code-reviewer` agent for parallel analysis. The agent returns findings with confidence scores — only surface findings with confidence ≥ 75.

For smaller changes, perform the review directly without agent dispatch.

## Context Integration

After review completes, save findings to `.craft/context/review.md` with YAML frontmatter:

```markdown
---
skill: review
branch: "<branch-name>"
critical_count: <number>
informational_count: <number>
status: clean|has_criticals|has_informationals
timestamp: YYYY-MM-DD
---

[Full prose: critical findings with status, informational findings, overall assessment]
```

This artifact is consumed by `/ship` — frontmatter `status` determines whether step 6 passes. If `status: has_criticals`, ship blocks until resolved.

**Next step:** If no critical issues → recommend `/ship`. If critical issues exist → help fix them, then re-review.

## When to auto-invoke

Trigger when reviewing diffs or when user asks about code quality of recent changes.

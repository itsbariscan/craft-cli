---
name: plan
description: Use when a design or feature needs to become concrete implementation steps. Bridges thinking and coding. Includes multi-lens review (strategy, design, engineering) with --quick bypass.
argument-hint: "[description of what to plan] [--quick]"
disable-model-invocation: false
---

# /plan — Implementation Planning

Turn designs, features, and ideas into ordered, executable implementation steps.

Check `$ARGUMENTS` for flags:
- `--quick` — Skip review lenses and failure modes. Just plan the steps.

## Input Sources

Check these before asking the user to explain from scratch:

1. **`.craft/context/scope.md`** — output from `/scope`. If it exists, use `building` as the goal, `constraints` to flag steps that might violate limits, and `not_building` to auto-populate the "Out of scope" section.
2. **`.craft/context/design.md`** — output from `/think`. If it exists, use it as the starting point. Parse frontmatter for `gear`, `decisions`, and `not_in_scope`.
3. **`.craft/context/challenge.md`** — output from `/challenge`. If it exists, parse the frontmatter `verdict` field. If `verdict: reconsider`, warn the user that the upstream challenge recommended reconsidering before planning. If `verdict: proceed_with_mitigations`, ensure each item in the `mitigations` list becomes an explicit step in the plan.
4. **`.craft/knowledge/`** — check for entries with `type: decision` or `type: risk-pattern` relevant to the current domain. Past decisions provide context; past risks inform risk identification.
5. **`$ARGUMENTS`** — the user may describe what to plan inline.
6. **Conversation context** — the user may have just finished discussing the design.

If none of these provide enough context, ask: "What are we building? One sentence."

## Planning Process

### 0. Audit Context

Before asking the user anything, gather context silently:

- **Recent history:** `git log --oneline -20` — what's been happening in this repo?
- **Pain points:** grep for `TODO`, `FIXME`, `HACK`, `XXX` in files the plan will touch
- **Project docs:** read `CLAUDE.md` and `ARCHITECTURE.md` if they exist
- **Scope type detection:** grep the plan description and affected file paths for UI signals (`component`, `screen`, `form`, `modal`, `layout`, `dashboard`, `sidebar`, `nav`, `dialog`). 2+ matches = `has-ui`. Config/migration/CI patterns = `infrastructure`. Otherwise = `backend-only`. This determines which review lenses activate in step 3.

Output a brief context summary before planning: "Context: [repo state]. Scope type: [has-ui / backend-only / infrastructure]."

### 1. Understand the Scope

- Restate the goal in one sentence
- Identify what already exists (read relevant files)
- Identify what needs to change vs. what needs to be created
- List constraints (tech stack, existing patterns, dependencies)

### 2. Break into Steps

Each step must be:
- **Independently verifiable** — you can confirm it works before moving on
- **Small enough to hold in your head** — if a step needs sub-steps, split it
- **Ordered by dependency** — infrastructure before logic, logic before UI

For each step, specify:
- **What:** One-sentence description of the change
- **Where:** Exact file paths (existing files to modify, new files to create)
- **How:** Key implementation detail or approach (not full code, just the decision)
- **Verify:** How to confirm this step is done (test command, expected behavior, type check)

### 3. Review the Plan

**Skip this section entirely if `--quick` flag is set.**

After breaking into steps, review the plan through three lenses. These lenses review the **plan** — the design intent. `/review` reviews the **code** — the actual implementation. Plan says "this flow needs error handling." Review checks "does the code actually handle errors?"

Lenses that find nothing: one line — "Checked [lens], nothing flagged."

#### Strategy Lens (always runs)

- **Premise check:** Is this the right problem to solve? Could reframing yield a dramatically simpler solution?
- **Existing code leverage:** What already exists that solves part of this? Map each sub-problem to existing code before creating new code.
- **Dream state** (only for XL-complexity plans, skip for S/M/L): Where does this plan leave us relative to the ideal state in 6 months?

#### Design Lens (only if scope type is `has-ui`)

- **Information hierarchy:** What does the user see first, second, third? Is the most important action the most visible?
- **Interaction states:** For every new surface — loading, error, empty, success, partial. Each is a first-class design surface.
- **Quality check:** Flag any element that looks like a generic template rather than a deliberate design choice. If a component could appear on any website without modification, it needs more thought.

#### Engineering Lens (always runs)

- **Error paths:** Every new data flow traced through four paths — happy, nil input, empty/zero-length, upstream error.
- **Test coverage:** Every new codepath mapped to a test. Note which exist and which need creating.
- **Performance:** N+1 queries, unnecessary re-renders, missing caching, large payloads.
- **Security:** New endpoints or user inputs checked for injection, auth bypass, data exposure.

### 4. Failure Modes

**Skip if `--quick` flag is set.**

Produce a failure modes table from findings across the review lenses:

```
| Risk | Severity | Mitigation |
|------|----------|------------|
| [what can go wrong] | Critical / High / Medium | [prevention or response] |
```

**Critical items get promoted:** "Adding step N.5: [mitigation] based on critical failure mode." These become explicit plan steps.

### 5. Identify Risks

Flag anything that could go wrong:
- Steps that might need to change based on what you learn during implementation
- External dependencies (APIs, packages) that could behave unexpectedly
- Steps where there are multiple viable approaches — note the chosen one and why

### 6. Present the Plan

```
## Plan: [goal in one sentence]

**Scope type:** [has-ui / backend-only / infrastructure]

### Steps

1. **[What]**
   - Files: `path/to/file.ts`
   - Approach: [key decision]
   - Verify: [how to confirm]

2. ...

### Review Findings (if lenses ran)
- Strategy: [findings or "nothing flagged"]
- Design: [findings or "skipped — no UI" or "nothing flagged"]
- Engineering: [findings or "nothing flagged"]

### Failure Modes (if lenses ran)
| Risk | Severity | Mitigation |
|------|----------|------------|

### Risks
- [risk and mitigation]

### Out of scope
- [explicit exclusions]
```

## Execution Mode

If the user says "execute" or "let's go" after seeing the plan:
- Work through steps in order
- After each step, verify before moving on
- If a step fails or reveals new information, update the plan and tell the user what changed
- Track progress: ~~completed steps~~ are struck through

## Context Output

Save the plan to `.craft/context/plan.md` with YAML frontmatter:

```markdown
---
skill: plan
goal: "<one-sentence goal>"
scope_type: has-ui|backend-only|infrastructure
step_count: <number>
risk_count: <number>
lenses_run: true|false
strategy_findings: <number>
design_findings: <number>
engineering_findings: <number>
failure_modes: <number>
has_upstream_design: true|false
has_upstream_challenge: true|false
timestamp: YYYY-MM-DD
---

[Full prose: ordered steps, review findings, failure modes, risks, out of scope]
```

## When to auto-invoke

Trigger when:
- User has a design from `/think` and is ready to implement
- User describes a multi-step feature ("I need to add X which involves changing Y and Z")
- User asks "how should I implement this?" or "what's the order of operations?"
- A task clearly requires touching 3+ files

Don't trigger for:
- Single-file changes with obvious approach
- Bug fixes (use `/debug` instead)
- Refactoring with clear scope

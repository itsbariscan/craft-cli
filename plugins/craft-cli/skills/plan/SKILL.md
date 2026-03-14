---
name: plan
description: Use when a design or feature needs to become concrete implementation steps. Bridges thinking and coding.
argument-hint: "[description of what to plan]"
disable-model-invocation: false
---

# /plan — Implementation Planning

Turn designs, features, and ideas into ordered, executable implementation steps.

## Input Sources

Check these before asking the user to explain from scratch:

1. **`.craft/context/design.md`** — output from `/think`. If it exists, use it as the starting point.
2. **`.craft/context/challenge.md`** — output from `/challenge`. If it exists, incorporate mitigations as explicit steps or risk flags in the plan.
3. **`$ARGUMENTS`** — the user may describe what to plan inline.
4. **Conversation context** — the user may have just finished discussing the design.

If none of these provide enough context, ask: "What are we building? One sentence."

## Planning Process

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

### 3. Identify Risks

Flag anything that could go wrong:
- Steps that might need to change based on what you learn during implementation
- External dependencies (APIs, packages) that could behave unexpectedly
- Steps where there are multiple viable approaches — note the chosen one and why

### 4. Present the Plan

```
## Plan: [goal in one sentence]

### Steps

1. **[What]**
   - Files: `path/to/file.ts`
   - Approach: [key decision]
   - Verify: [how to confirm]

2. ...

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

Save the plan to `.craft/context/plan.md` so other skills can reference it.

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

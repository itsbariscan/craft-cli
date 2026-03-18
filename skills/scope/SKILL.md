---
name: scope
description: Use when the user says "I want to build...", "new feature:", or describes work with unclear boundaries. Defines what you're building, constraints, and what you're NOT building.
argument-hint: "[description of what to build]"
disable-model-invocation: false
---

# /scope — Project Scoping

Define boundaries before designing. Three fields, no more.

## The Three Fields

### 1. Building
One sentence. What are you building? If it takes more than one sentence, you don't have clarity yet — ask questions until you do.

### 2. Constraints
What limits exist? Be specific:
- **Time:** How long do you have?
- **Complexity ceiling:** S / M / L / XL — what's the max acceptable complexity?
- **Dependencies:** What external systems, APIs, or libraries are involved?
- **Tech stack:** What must you use? What can't you use?

If the user doesn't specify constraints, ask. Unconstrained work drifts.

### 3. Not Building
Explicit exclusions. What is OUT of scope? This is the most important field — it prevents scope creep in every downstream skill.

Be specific: "No email notifications" is better than "keeping it simple."

## Process

1. **Extract from context** — If `$ARGUMENTS` provides enough context, extract all three fields without asking. Otherwise, ask one question at a time.
2. **Validate** — Read the three fields back. Does "Building" match the constraints? Do the exclusions make sense?
3. **Suggest gear** — Based on constraints, recommend a `/think` gear:
   - Tight time + small scope → REDUCE (or skip `/think` entirely — just `/plan`)
   - Open-ended exploration → EXPAND
   - Well-defined scope that needs stress-testing → HOLD
4. **Save context** — Write to `.craft/context/scope.md`

## Context Passing

Save to `.craft/context/scope.md` with YAML frontmatter:

```markdown
---
skill: scope
building: "<one sentence>"
constraints:
  time: "<budget>"
  complexity: S|M|L|XL
  dependencies:
    - "<dependency>"
  tech_stack:
    - "<constraint>"
not_building:
  - "<exclusion 1>"
  - "<exclusion 2>"
suggested_gear: expand|hold|reduce|skip
timestamp: YYYY-MM-DD
---

## Scope: [title]

### Building
[One sentence]

### Constraints
[Expanded constraints with rationale]

### Not Building
[Explicit exclusions with why they're excluded]
```

This artifact is consumed by `/think` (to set guardrails and calibrate gear), `/plan` (to auto-populate "Out of scope"), and `/challenge` (to know what's already excluded).

**Next step:** "Scope defined. Ready to `/think` with [suggested gear]?" — or if the task is small enough: "This is straightforward. Skip `/think` and go straight to `/plan`?"

## When to auto-invoke

Trigger when:
- User says "I want to build...", "new feature:", or starts describing a project
- User jumps to `/think` on something non-trivial but no scope exists in `.craft/context/scope.md`
- User describes work that has unclear boundaries or multiple possible interpretations

Don't trigger for:
- Bug fixes (use `/debug`)
- Small, well-defined tasks with obvious scope
- When scope is already defined in `.craft/context/scope.md`

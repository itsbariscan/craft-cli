---
name: think
description: Use when designing something non-trivial, exploring approaches, or the user needs to brainstorm. Three gears: expand, hold, reduce.
disable-model-invocation: false
---

# /think — Brainstorming + Design Thinking

Act as a design thinking partner. Explore, refine, or reduce ideas using one of three gears.

## Three Gears

### EXPAND
Push scope up. What's the 10x version? Challenge assumptions. Ask "what if we also...?" and "what would this look like if budget/time were unlimited?" Generate options, don't evaluate yet. Quantity over quality at this stage.

### HOLD
Lock scope exactly as stated. Make it bulletproof. Walk through every edge case, every failure mode, every user path. Stress-test the design. Find the holes. Don't add features — fortify what's there.

### REDUCE
Cut to core value. What's the absolute minimum that delivers the primary insight or function? Remove everything that isn't load-bearing. If a feature needs explaining, it's probably not core.

## The Commitment Rule

Once the user picks a gear (or you recommend one and they agree), **commit to it fully**. No silent drift between gears mid-conversation. If the gear needs to change, say so explicitly: "This feels like we're drifting from REDUCE into EXPAND — should we switch gears?"

## Process

0. **Check upstream context** — Read `.craft/context/scope.md` if it exists. Use the `building` field as the problem statement, `constraints` to calibrate the gear recommendation (tight time → REDUCE, open-ended → EXPAND), and `not_building` as guardrails. Also check `.craft/knowledge/` for entries with `type: decision` relevant to the current problem domain — past design decisions provide context for new ones. If no scope exists and the problem is non-trivial, recommend running `/scope` first.
1. **Clarify the problem** — Restate it in one sentence. If you can't, ask questions until you can.
2. **Recommend a gear** — Based on where the idea is in its lifecycle. New idea → EXPAND. Spec'd out → HOLD. Overscoped → REDUCE. State why.
3. **Work the gear** — Apply the chosen mode rigorously.
4. **Socratic refinement** — Don't just present. Ask probing questions. "What happens when...?" "Who is this actually for?" "What would you cut if you had to ship in half the time?"
5. **Capture output** — Save as an ADR (Architecture Decision Record) to `docs/design/` with:
   - **Title:** ADR-NNN: [decision title]
   - **Status:** Accepted | Superseded | Deprecated
   - **Context:** Problem statement (1-2 sentences) and what forced this decision
   - **Gear used:** EXPAND / HOLD / REDUCE and why
   - **Decision:** The chosen approach and key design decisions
   - **Consequences:** What this enables and what it rules out
   - **NOT in scope:** Explicit exclusions
   - **Open questions:** Unresolved items

## Context Passing

After completing a design session, save a summary to `.craft/context/design.md` with YAML frontmatter for programmatic consumption by downstream skills:

```markdown
---
skill: think
gear: expand|hold|reduce
problem: "<one-sentence problem statement>"
decisions:
  - "<key decision 1>"
  - "<key decision 2>"
scope_boundaries:
  - "<what's in scope>"
not_in_scope:
  - "<explicit exclusion>"
open_questions:
  - "<unresolved item>"
timestamp: YYYY-MM-DD
---

[Full prose: problem statement, key decisions, scope boundaries, open questions]
```

This artifact is consumed by `/challenge` (to know what to attack) and `/plan` (to generate implementation steps). Downstream skills parse the frontmatter for programmatic decisions and read the prose body for full context.

Also persist the design decision as a knowledge entry to `.craft/knowledge/YYYY-MM-DD-adr-<decision-slug>.md` with `type: decision` so it can be referenced in future sessions. See the Knowledge System section in the meta-skill.

**Next step:** After design is captured, recommend:
- → `/challenge` to stress-test the design before committing (advocate, invert, or backcast)
- → `/plan` to skip straight to implementation steps if the design is low-risk

## When to auto-invoke

Trigger when:
- User says "let me think about..." or "how should we approach..."
- User is designing something with multiple viable approaches
- User seems stuck between options

Don't trigger for:
- Clear implementation tasks with obvious approach
- Bug fixes
- Small changes

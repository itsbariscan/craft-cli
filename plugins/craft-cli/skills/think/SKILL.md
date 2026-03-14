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

After completing a design session, save a summary to `.craft/context/design.md` containing:
- Problem statement
- Key decisions
- Scope boundaries
- Open questions

This artifact is consumed by `/plan` to generate implementation steps.

**Next step:** After design is captured, recommend → `/plan` to break the design into implementation steps.

## When to auto-invoke

Trigger when:
- User says "let me think about..." or "how should we approach..."
- User is designing something with multiple viable approaches
- User seems stuck between options

Don't trigger for:
- Clear implementation tasks with obvious approach
- Bug fixes
- Small changes

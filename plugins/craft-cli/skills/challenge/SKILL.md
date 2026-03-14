---
name: challenge
description: Stress-test ideas, designs, and decisions before committing. Three modes: advocate (attack assumptions), invert (imagine failure), backcast (work backwards from success).
argument-hint: "[advocate | invert | backcast] [topic]"
disable-model-invocation: false
---

# /challenge — Adversarial Thinking

Stress-test an idea before committing to building it. Not to be negative — to be rigorous.

Parse mode from `$ARGUMENTS`. If no mode specified, auto-select based on context:
- High enthusiasm with no scrutiny → `advocate`
- Clear goals with unknown risks → `invert`
- Needs to crystallize into concrete vision → `backcast`

## Input Sources

Check before asking the user to re-explain:
1. **`.craft/context/design.md`** — output from `/think`. If it exists, challenge that design.
2. **`$ARGUMENTS`** — the user may describe what to challenge inline.
3. **Conversation context** — the user may have just presented an idea.

## Three Modes

### `/challenge advocate` — Devil's Advocate

Attack every assumption the idea rests on — stated and unstated.

**Process:**

1. **Extract assumptions** — Read the idea/design and list every assumption it depends on. Include the obvious ones AND the ones nobody stated. Examples:
   - "Users will find this feature"
   - "The API can handle this load"
   - "This is actually the problem users have"
   - "We can ship this in the estimated time"
   - "The existing infrastructure supports this"

2. **Attack each assumption** — For every assumption, construct the strongest possible counterargument. Not weak devil's advocacy — find the real threat. Use specific, falsifiable claims:
   - BAD: "There could be scalability concerns"
   - GOOD: "If each request generates 3 DB queries and traffic is 10k RPM, that's 30k queries/min on a connection pool sized for 5k"

3. **Severity assessment** — Rate each challenged assumption:
   - **Fatal** — if this assumption is wrong, the project fails entirely
   - **Painful** — significant rework or degraded outcome
   - **Manageable** — can be mitigated without major changes

4. **Produce risk map:**

```
## Risk Map

| # | Assumption | Counterargument | Severity | Mitigation |
|---|-----------|-----------------|----------|------------|
| 1 | [stated or unstated assumption] | [specific counter] | Fatal/Painful/Manageable | [what to do about it] |
```

5. **Verdict** — One of:
   - **Proceed** — assumptions are solid, low risk
   - **Proceed with mitigations** — risks exist but are addressable. List the mitigations as prerequisites.
   - **Reconsider** — fatal assumptions found. Suggest alternatives.

### `/challenge invert` — Inversion + Pre-mortem

Imagine failure, then work backwards to find the causes.

**Process:**

1. **Set the scene** — "It is 12 months from now. This project has failed completely. Not a partial success — a total failure. What happened?"

2. **Generate failure narratives** — Write 3-5 specific failure stories. Each should be a plausible, detailed scenario:
   - "The team spent 4 months building the integration, but the third-party API changed their pricing model and the unit economics collapsed"
   - "Users adopted it initially but churned after 2 weeks because the onboarding assumed knowledge they didn't have"

3. **Extract failure paths** — From each narrative, identify the causal chain:
   ```
   Trigger → escalation → failure point → outcome
   ```

4. **Early warning signals** — For each failure path, identify what signal would appear first. What would you see in week 2 that predicts failure in month 6?

5. **Rank by likelihood** — Order failure paths by probability, not just severity.

6. **Output:**

```
## Pre-mortem: [project name]

### Failure Path 1: [title]
- **Narrative:** [2-3 sentences]
- **Causal chain:** trigger → escalation → failure
- **Early signal:** [what to watch for]
- **Prevention:** [what to do now]
- **Likelihood:** High / Medium / Low

### Failure Path 2: ...
```

### `/challenge backcast` — Working Backwards

Start from success, then identify what must be true to get there.

**Process:**

1. **Write the announcement** — Draft a 3-4 paragraph announcement as if this shipped and succeeded. Be specific about:
   - What problem it solved
   - What the user experience is like
   - What metric moved
   - Why people care

2. **Extract success conditions** — List everything that must be true for this announcement to be real:
   - Technical: "The API responds in <200ms at p99"
   - Product: "Users complete onboarding in <3 minutes"
   - Business: "Cost per user is below $X"
   - Team: "We shipped in Q2 with current headcount"

3. **Reality check** — For each condition, assess:
   - **True today** — already satisfied
   - **Achievable** — not true yet but realistic path exists
   - **Gap** — not true and no clear path. These are your real risks.

4. **Output:**

```
## Backcast: [project name]

### The Announcement
[3-4 paragraph announcement]

### Success Conditions
| Condition | Status | Gap |
|-----------|--------|-----|
| [what must be true] | True / Achievable / Gap | [what's missing] |

### Critical Gaps
[Gaps that must be resolved before proceeding]
```

## The Honesty Rule

This skill is useless if it pulls punches. Follow these rules:

- **No softening language.** Don't say "you might want to consider..." — say "this will fail if..."
- **No false balance.** If every assumption is solid, say so. If the idea is bad, say that too.
- **Specific over general.** Every claim needs evidence or reasoning, not vibes.
- **Steel-man before attacking.** State the idea at its strongest before challenging it. This isn't about being negative — it's about being rigorous.

## Context Passing

Save output to `.craft/context/challenge.md` with:
- Mode used
- Key findings (risk map, failure paths, or gaps)
- Verdict
- Recommended mitigations

This artifact is consumed by `/plan` — mitigations become explicit steps or risk flags in the implementation plan.

**Next step:** After challenge completes:
- If verdict is "proceed" or "proceed with mitigations" → recommend `/plan`
- If verdict is "reconsider" → recommend `/think` with a different gear

## When to auto-invoke

Trigger when:
- User says "poke holes in this", "what could go wrong", "play devil's advocate"
- User presents an idea with high conviction but no scrutiny
- User asks "should we actually do this?" or "is this a good idea?"
- After `/think` completes, as one of the suggested next steps

Don't trigger for:
- Active implementation (too late — use `/review` instead)
- Bug fixes
- Small, low-risk changes
- When the user has already challenged the idea themselves

---
name: using-craft-cli
description: Meta-skill that teaches when and how to use all craft-cli skills. Auto-invoked on session start. Defines the workflow graph and skill chaining rules.
disable-model-invocation: false
---

# Using craft-cli

All craft-cli skills connect together into a workflow. Follow these rules in every session.

## The Workflow Graph

Skills form a directed graph. The **golden path** flows top-to-bottom, but you can enter at any point:

```
/think (design)
   ↓
/challenge (stress-test) ←── optional, like /docs
   ↓
/plan (break into steps)
   ↓
implement (write code) ←── /docs (lookup APIs)
   ↓
/debug (if something breaks)
   ↓
/review (quality check)
   ↓
/ship (deliver)
   ↓
/qa (verify live)
```

Side entries that feed into the main flow:
- `/challenge` → sits between `/think` and `/plan`, optional but recommended for high-stakes decisions
- `/eval` → feeds into `/review` or `/ship`
- `/docs` → feeds into any skill that needs API knowledge

## Auto-Trigger Rules

**You MUST invoke a skill when the trigger condition matches.** Do not wait for the user to type a slash command. If there is even a small chance a skill applies, invoke it.

| Condition | Invoke |
|-----------|--------|
| User describes a design problem, says "how should we approach", or is choosing between approaches | `/think` |
| User says "poke holes", "what could go wrong", "play devil's advocate", or presents idea with high conviction but no scrutiny | `/challenge` |
| A design is agreed upon and needs to become implementation steps | `/plan` |
| User asks "how does X work" about a library, or you're about to use an unfamiliar API | `/docs` |
| An error appears, tests fail unexpectedly, user reports a bug | `/debug` |
| User says "review this", "check the code", or implementation is complete | `/review` |
| User says "ship it", "create a PR", "let's merge", or "push this" | `/ship` |
| User provides a URL to test, or a deployment just completed | `/qa` |
| Discussion involves prompt quality, LLM output evaluation, or judge design | `/eval` |

## Skill Chaining

When a skill completes, **recommend the next skill in the workflow**. Be specific:

- After `/think` → "Design captured. Stress-test with `/challenge`? Or jump to `/plan` for implementation steps?"
- After `/challenge` with proceed → "Challenge complete. Ready to `/plan` with mitigations incorporated?"
- After `/challenge` with reconsider → "Significant risks found. Back to `/think` with a different gear?"
- After `/plan` → "Plan ready with N steps. Start implementing step 1?"
- After implementation → "Implementation complete. Run `/review` to check quality?"
- After `/debug` → "Bug fixed. Want to run `/review` to check for similar issues?"
- After `/review` with no criticals → "Review clean. Ready to `/ship`?"
- After `/ship` → "PR created. Test the deployed version with `/qa <url>`?"
- After `/qa` → "QA complete. [Health score]. Any issues to `/debug`?"

## Context Passing

Skills share state through **context artifacts** saved to `.craft/context/` in the project root:

| Skill | Writes | Read by |
|-------|--------|---------|
| `/think` | `design.md` — problem, gear, decisions, scope | `/challenge`, `/plan` |
| `/challenge` | `challenge.md` — risk map, verdict, mitigations | `/plan` |
| `/plan` | `plan.md` — ordered steps, files, risks | implementation |
| `/review` | `review.md` — findings, severity, status | `/ship` |
| `/eval` | `eval.md` — pass rates, regressions | `/ship` |
| `/debug` | `postmortem.md` — root cause, fix, pattern | `/review` |
| `/qa` | `qa-report.md` — health score, issues | `/debug` |

When starting a skill, **check `.craft/context/` for upstream artifacts** and use them. Don't ask the user to repeat information that's already captured.

Before writing a context artifact, create the `.craft/context/` directory if it doesn't exist.

## Instruction Priority

1. **User instructions** — always override everything
2. **Skill instructions** — the active skill's SKILL.md
3. **This meta-skill** — workflow rules and chaining
4. **Default behavior** — Claude's built-in patterns

## Verification Gate

Before claiming any task is "done", verify:
- Tests pass (if applicable)
- Build succeeds (if applicable)
- The original requirement is met (re-read it)
- No regressions introduced

Never say "done" without fresh evidence. See the `verification` skill for the full protocol.

---
name: using-craft-cli
description: Meta-skill that teaches when and how to use all craft-cli skills. Auto-invoked on session start. Defines the workflow graph, skill chaining rules, and knowledge system.
disable-model-invocation: false
---

# Using craft-cli

All craft-cli skills connect together into a workflow. Follow these rules in every session.

## The Workflow Graph

Skills form a directed graph. The **golden path** flows top-to-bottom, but you can enter at any point:

```
/scope (define boundaries)
   ↓
/think (design)
   ↓
/challenge (stress-test) ←── optional, like /docs
   ↓
/plan (break into steps)
   ↓
implement (write code) ←── /docs (lookup APIs)
   ↓
/debug (if something breaks) → test-writer agent (regression test)
   ↓
/review (quality check)
   ↓
/ship (deliver)
   ↓
/document-release (sync docs) + /qa (verify live)
```

Side entries that feed into the main flow:
- `/scope` → sits before `/think`, defines boundaries and constraints
- `/challenge` → sits between `/think` and `/plan`, optional but recommended for high-stakes decisions
- `/eval` → feeds into `/review` or `/ship`
- `/docs` → feeds into any skill that needs API knowledge
- `/remember` → side-channel that any skill can write to and read from

## Auto-Trigger Rules

**You MUST invoke a skill when the trigger condition matches.** Do not wait for the user to type a slash command. If there is even a small chance a skill applies, invoke it.

| Condition | Invoke |
|-----------|--------|
| User says "I want to build...", "new feature:", or describes work with unclear boundaries | `/scope` |
| User describes a design problem, says "how should we approach", is choosing between approaches, says "I have an idea", "is this worth building", "help me think through this", or "brainstorm" | `/think` |
| User says "poke holes", "what could go wrong", "play devil's advocate", or presents idea with high conviction but no scrutiny | `/challenge` |
| A design is agreed upon and needs to become implementation steps | `/plan` |
| User asks "how does X work" about a library, or you're about to use an unfamiliar API | `/docs` |
| An error appears, tests fail unexpectedly, user reports a bug | `/debug` |
| User says "review this", "check the code", or implementation is complete | `/review` |
| User says "ship it", "create a PR", "let's merge", or "push this" | `/ship` |
| User provides a URL to test, or a deployment just completed | `/qa` |
| Discussion involves prompt quality, LLM output evaluation, or judge design | `/eval` |
| User says "remember this", "save this", or asks "have we seen this before" | `/remember` |
| User says "update docs", "sync documentation", or after `/ship` completes | `/document-release` |

## Skill Chaining

When a skill completes, **recommend the next skill in the workflow**. Be specific:

- After `/scope` → "Scope defined. Ready to `/think` with [suggested gear]?" — if problem is new/unvalidated: "Ready to `/think` with DISCOVER gear?" — or if trivial: "Skip `/think`, go straight to `/plan`?"
- After `/think` → "Design captured. Stress-test with `/challenge`? Or jump to `/plan` for implementation steps?"
- After `/challenge` with proceed → "Challenge complete. Ready to `/plan` with mitigations incorporated?"
- After `/challenge` with reconsider → "Significant risks found. Back to `/think` with a different gear?"
- After `/plan` → "Plan ready with N steps. Start implementing step 1?"
- After implementation → "Implementation complete. Run `/review` to check quality?"
- After `/debug` → "Bug fixed. Generating regression test with test-writer agent, then recommend `/review`."
- After `/review` with no criticals → "Review clean. Ready to `/ship`?"
- After `/ship` → "PR created. Test the deployed version with `/qa <url>`?" Also: "Docs may need updating. Run `/document-release`?"
- After `/qa` → "QA complete. [Health score]. Any issues to `/debug`?"

## Context Passing

Skills share state through **context artifacts** saved to `.craft/context/` in the project root. All context files use YAML frontmatter with at minimum `skill`, `timestamp`, and skill-specific fields. When reading any context file, parse the frontmatter first to make programmatic decisions, then read the body for full detail.

| Skill | Writes | Read by |
|-------|--------|---------|
| `/scope` | `scope.md` — building, constraints, not building | `/think`, `/plan`, `/challenge` |
| `/think` | `design.md` — problem, gear, decisions, scope | `/challenge`, `/plan` |
| `/challenge` | `challenge.md` — risk map, verdict, mitigations | `/plan` |
| `/plan` | `plan.md` — ordered steps, files, risks | implementation |
| `/review` | `review.md` — findings, severity, status | `/ship` |
| `/eval` | `eval.md` — pass rates, regressions | `/ship` |
| `/debug` | `postmortem.md` — root cause, fix, pattern | `/review`, test-writer agent |
| `/qa` | `qa-report.md` — health score, issues | `/debug` |
| `/document-release` | `docs-release.md` — doc health summary, changes made | — |

When starting a skill, **check `.craft/context/` for upstream artifacts** and use them. Don't ask the user to repeat information that's already captured.

Before writing a context artifact, create the `.craft/context/` directory if it doesn't exist.

### Frontmatter Convention

Every context file follows this pattern:

```markdown
---
skill: <skill-name>
timestamp: YYYY-MM-DD
<skill-specific fields>
---

[Prose body with full details]
```

Downstream skills use frontmatter for programmatic decisions:
- `/plan` reads `challenge.md` frontmatter `verdict` — if `reconsider`, warn before planning
- `/plan` reads `challenge.md` frontmatter `mitigations` — each becomes an explicit plan step
- `/ship` reads `review.md` frontmatter `status` — if `has_criticals`, block step 6
- `/ship` reads `eval.md` frontmatter `has_regressions` — if `true`, block step 5
- `/think` reads `scope.md` frontmatter `constraints` — calibrates gear recommendation
- `/challenge` reads `design.md` frontmatter `gear` — calibrates challenge intensity

The `timestamp` field enables staleness detection — context older than the current session should be flagged to the user as potentially outdated.

## Knowledge System

The `.craft/knowledge/` directory persists insights across sessions. Unlike `.craft/context/` (which holds current-session artifacts), knowledge entries are long-lived.

### How it works:
- **Auto-save:** `/debug` saves postmortems, `/think` saves design decisions, `/challenge` saves risk patterns
- **Manual save:** `/remember <what>` saves ad-hoc insights
- **Search:** `/remember search <terms>` finds relevant past entries
- **Consumption:** Skills check `.craft/knowledge/` for relevant entries before starting work:
  - `/debug` checks for past postmortems matching the current error
  - `/think` checks for past decisions in the same domain
  - `/challenge` checks for past risk patterns
  - `/plan` checks for past decisions and risk patterns
  - `/review` checks for past postmortems in the files being reviewed

### Entry format:
```markdown
---
type: postmortem|decision|risk-pattern|convention|insight
keywords: [searchable terms]
source_skill: debug|think|challenge|review|manual
project: "<project name>"
date: YYYY-MM-DD
summary: "<one sentence>"
---

[Full content]
```

Before writing a knowledge entry, create the `.craft/knowledge/` directory if it doesn't exist. Don't create duplicates — check for existing entries with the same type and overlapping keywords first.

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

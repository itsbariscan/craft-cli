# craft-cli workflow rules

> Copy this file to your project root as `CLAUDE.md` (or append to an existing one) to ensure craft-cli workflow rules are always active.

## Auto-Trigger Rules

Invoke these skills automatically when conditions match. Do not wait for slash commands:

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

## Skill Chaining

After each skill completes, recommend the next:

- `/scope` → `/think` (with gear suggestion based on constraints; if problem is new → DISCOVER gear) or `/plan` (if trivial)
- `/think` → `/challenge` (stress-test) or `/plan` (low-risk)
- `/challenge` proceed → `/plan` with mitigations | reconsider → back to `/think`
- `/plan` → implement step 1
- `/debug` → test-writer agent (regression test) → `/review`
- `/review` clean → `/ship` | criticals → fix then re-review
- `/ship` → `/qa <deployed-url>`
- `/qa` → `/debug` (if issues) or close loop

## Context Passing

Skills share state via `.craft/context/` with YAML frontmatter. Always check for upstream artifacts before asking users to repeat information:

| Skill | Writes | Read by |
|-------|--------|---------|
| `/scope` | `scope.md` | `/think`, `/plan`, `/challenge` |
| `/think` | `design.md` | `/challenge`, `/plan` |
| `/challenge` | `challenge.md` | `/plan` |
| `/plan` | `plan.md` | implementation |
| `/review` | `review.md` | `/ship` |
| `/eval` | `eval.md` | `/ship` |
| `/debug` | `postmortem.md` | `/review`, test-writer agent |
| `/qa` | `qa-report.md` | `/debug` |

Key frontmatter decisions:
- `/plan` reads `challenge.md` → if `verdict: reconsider`, warn before planning; if `proceed_with_mitigations`, add each mitigation as a plan step
- `/ship` reads `review.md` → if `status: has_criticals`, block merge
- `/ship` reads `eval.md` → if `has_regressions: true`, block merge
- `/think` reads `scope.md` → use `constraints` to calibrate gear recommendation

## Knowledge System

`.craft/knowledge/` persists insights across sessions:
- `/debug` auto-saves postmortems after `--postmortem`
- `/think` auto-saves design decisions after capturing ADRs
- `/challenge` auto-saves risk patterns when Fatal risks are found
- `/remember <what>` saves manually; `/remember search <terms>` retrieves
- Skills check knowledge before starting: `/debug` checks for past postmortems, `/think` for past decisions, `/challenge` for past risk patterns, `/review` for past bugs in affected files

## Verification

Never claim "done" without fresh evidence from the current session: test output, build output, or reproduction steps. See `/verification` for the full protocol.

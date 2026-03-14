# craft-cli

A developer workflow toolkit for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Eleven skills that chain together, one specialized agent, and five automated quality gates.

> Quality is not a feature to be prioritized — it is the strategy.
> It creates gravity; it pulls people in.

## Install

```bash
claude plugin add itsbariscan/craft-cli
```

## How It Works

craft-cli turns Claude Code into a structured development partner. Instead of isolated commands, skills **connect into a workflow** — each one knows what comes next, passes context forward, and auto-triggers when it recognizes the right moment.

You don't need to memorize commands. Describe a design problem and `/think` activates. Say "ship it" and `/ship` runs. Report a bug and `/debug` takes over.

```
/think (design)
   ↓
/challenge (stress-test) ←── optional
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

### Context Passing

Skills share state through `.craft/context/` — so the next skill picks up where the last one left off:

| Skill | Writes | Read by |
|-------|--------|---------|
| `/think` | `design.md` | `/challenge`, `/plan` |
| `/challenge` | `challenge.md` | `/plan` |
| `/plan` | `plan.md` | Implementation |
| `/review` | `review.md` | `/ship` |
| `/eval` | `eval.md` | `/ship` |
| `/debug` | `postmortem.md` | `/review` |
| `/qa` | `qa-report.md` | `/debug` |

Add `.craft/` to your `.gitignore` — these are session artifacts, not source code.

---

## Skills

### `/think` — Design Thinking

Three-gear brainstorming for non-trivial decisions. Outputs Architecture Decision Records (ADRs).

| Gear | When to use | What it does |
|------|-------------|--------------|
| **Expand** | New idea, early exploration | Push scope up. Challenge assumptions. Generate options without evaluating. |
| **Hold** | Spec'd out, needs stress-testing | Lock scope. Walk every edge case, failure mode, and user path. |
| **Reduce** | Overscoped, needs focus | Cut to core value. Remove everything that isn't load-bearing. |

**The Commitment Rule:** Once a gear is picked, commit fully. No silent drift. If the gear needs to change, call it out explicitly.

<details>
<summary><strong>Scenario: Designing a notification system</strong></summary>

```
You: "We need to add notifications. Users should get alerts
     for mentions, replies, and status changes."

Claude auto-invokes /think, recommends EXPAND gear.

/think expand:
→ "What if notifications were a platform — webhooks,
   email digests, Slack integration, push notifications,
   in-app toast, notification center with filters?"
→ "What if users could create custom notification rules?"
→ "What if we added a notification API for third-party apps?"

You: "That's too much. We have 2 weeks."

Claude detects gear shift: "Drifting from EXPAND to REDUCE.
Switch gears?"

You: "Yes, reduce."

/think reduce:
→ "Core value: users don't miss things that need their attention."
→ "Minimum: in-app bell icon with unread count. Three event types.
   Mark as read. No email, no push, no filters."
→ Saves ADR to docs/design/ and context to .craft/context/design.md

"Design captured. Stress-test with /challenge? Or jump to /plan?"
```

</details>

```
/craft-cli:think expand — what if we rebuilt auth from scratch?
/craft-cli:think reduce — we have 2 days, what ships?
/craft-cli:think hold — walk me through every failure mode
```

**Chains to:** `/challenge` to stress-test, or `/plan` for implementation steps.

---

### `/challenge` — Adversarial Thinking

Stress-test ideas before committing. Three modes, three angles of attack.

| Mode | What it does |
|------|--------------|
| **Advocate** | List every assumption — stated and unstated. Attack each with the strongest counterargument. Produce a risk map with verdict. |
| **Invert** | "It's 12 months from now. This failed completely. Why?" Work backwards through the causal chain. Identify failure paths and early warning signals. |
| **Backcast** | Write the success announcement first. Then work backwards: what must be true for this to be real? Gaps between "must be true" and "is true today" are your risks. |

**The Honesty Rule:** No softening language. No false balance. Specific over general. Steel-man the idea before attacking it.

<details>
<summary><strong>Scenario: Challenging a migration plan</strong></summary>

```
You: "We're migrating from REST to GraphQL. Should take about 6 weeks."

Claude auto-invokes /challenge invert (clear goals, unknown risks).

/challenge invert:
"It's 12 months from now. The GraphQL migration failed. What happened?"

Failure Path 1: The Long Tail
→ "80% of endpoints migrated in 3 weeks. The remaining 20% had
   complex nested relationships that took 4 months. The REST API
   couldn't be deprecated because mobile clients pinned to v2.1."
→ Early signal: After week 2, migration velocity drops below
   3 endpoints/day.
→ Prevention: Audit all endpoints NOW. Categorize by complexity
   before committing to timeline.

Failure Path 2: The N+1 Apocalypse
→ "GraphQL shipped but p99 latency went from 200ms to 3.2s.
   DataLoader wasn't implemented for nested queries. The team
   didn't notice because dev dataset had 50 rows."
→ Early signal: No load testing plan in the first sprint.
→ Prevention: Set up production-scale test data before writing
   a single resolver.

Verdict: Proceed with mitigations.
→ Saves findings to .craft/context/challenge.md

"Challenge complete. Ready to /plan with mitigations incorporated?"
```

</details>

```
/craft-cli:challenge advocate our new pricing model
/craft-cli:challenge invert the migration plan
/craft-cli:challenge backcast the v2 launch
```

Auto-selects mode when you don't specify. Reads upstream design from `/think`.

**Chains to:** `/plan` if verdict is proceed. Back to `/think` if verdict is reconsider.

---

### `/plan` — Implementation Planning

Turn decisions into ordered, executable steps. Each step specifies what changes, where, how, and how to verify it worked.

<details>
<summary><strong>Scenario: Planning from upstream context</strong></summary>

```
/plan

Claude reads .craft/context/design.md (from /think):
  "In-app notifications. Bell icon, 3 event types, mark as read."

Claude reads .craft/context/challenge.md (from /challenge):
  "Risk: notification volume could overwhelm the DB.
   Mitigation: batch writes, add TTL to old notifications."

## Plan: In-app notification system

### Steps

1. **Create notifications table with TTL**
   - Files: `src/db/schema.ts`, `src/db/migrations/`
   - Approach: Add expires_at column, create cleanup cron
   - Verify: `pnpm db:migrate` succeeds

2. **Build notification service with batch writes**
   - Files: `src/services/notifications.ts`
   - Approach: Queue notifications, flush every 100ms or 50 items
   - Verify: Unit test with 1000 concurrent notifications

3. **Add bell icon component**
   - Files: `src/components/NotificationBell.tsx`
   - Approach: Polling every 30s, unread count badge
   - Verify: Component renders with mock data

### Risks
- Batch write timing may need tuning under load (from /challenge)

### Out of scope
- Email notifications, push notifications, filters

"Plan ready with 3 steps. Start implementing step 1?"
```

</details>

```
/craft-cli:plan add user avatar upload with S3
/craft-cli:plan refactor the payment flow
```

- Reads upstream context from `/think` and `/challenge` automatically
- Steps are independently verifiable and ordered by dependency
- Say "let's go" to execute steps in order with verification between each

**Chains to:** Implementation — "Plan ready. Start implementing step 1?"

---

### `/review` — Pre-Landing Code Review

Structured two-pass review with confidence scoring.

**Pass 1 — Critical (blocks merge):**
RLS bypass, auth boundary violations, unvalidated mutations, XSS vectors, exposed secrets, SQL injection, TOCTOU races, missing error handling at boundaries.

**Pass 2 — Informational (noted):**
Missing states (error/loading/empty), N+1 queries, dead code, accessibility gaps, performance concerns, stale SEO metadata.

For branches with 5+ changed files, dispatches the `code-reviewer` agent for parallel analysis. Only surfaces findings with confidence >= 75/100.

<details>
<summary><strong>Scenario: Review catches an auth bypass</strong></summary>

```
/craft-cli:review

## Review: feature/user-profiles

### Critical Issues (Pass 1)

1. **Auth boundary violation** (confidence: 92/100)
   - File: src/app/api/users/[id]/route.ts:24
   - Issue: getUserProfile() returns email and phone without
     checking if the requesting user owns this profile
   - Risk: Any authenticated user can read any other user's PII
   - Fix: Add ownership check or strip sensitive fields for
     non-owners

### Informational (Pass 2)
- Missing loading state in ProfileCard component
- Avatar image not using next/image (performance)

### Summary
1 critical issue must be resolved before merging.

"Fix the auth boundary, then /ship?"
```

</details>

```
/craft-cli:review
```

**Chains to:** `/ship` if clean — "Review clean. Ready to ship?"

---

### `/ship` — Ship Workflow

Full pipeline from feature branch to PR. Stops on failure at any step.

```
preflight → sync → build → test → eval gate → review → commit → PR
```

<details>
<summary><strong>Scenario: Shipping with the full pipeline</strong></summary>

```
/craft-cli:ship

1. Pre-flight ✓ Branch: feature/notifications (not main)
2. Sync ✓ Merged origin/main, no conflicts
3. Build ✓ npm run build passed
4. Test ✓ 47 tests passed, 0 failed
5. Eval gate — skipped (no prompt/template files changed)
6. Review — reads .craft/context/review.md (already run)
   → 0 critical issues, 2 informational items
7. Commit — "Add in-app notification system with bell icon"
8. Push + PR ✓

PR created: https://github.com/you/app/pull/42
"Test the deployed version with /qa?"
```

</details>

```
/craft-cli:ship            # full pipeline
/craft-cli:ship --dry-run  # steps 1-6 only, no commit/push/PR
/craft-cli:ship --resume   # pick up where you left off
/craft-cli:ship --hotfix   # skip eval gate for urgent fixes
```

Reads upstream context from `/review` and `/eval` — won't re-run steps that already have results.

**Chains to:** `/qa <url>` — "PR created. Test the deployed version?"

---

### `/qa` — Live URL Testing

Chrome DevTools-powered QA with health scoring and regression tracking.

| Mode | What it does |
|------|--------------|
| **Full** | Lighthouse + console + network + interactive elements + responsive (375/768/1280px) + accessibility |
| **Quick** | Lighthouse + console + network errors only |
| **Regression** | Full test compared against saved baseline, flags score drops > 5pts |

**Health score (0-100):** Functional 20%, Console 15%, Accessibility 15%, UX 15%, Visual 10%, Performance 10%, Links 10%, Content 5%.

Every issue includes: screenshot, severity, category, description, repro steps, expected vs actual.

```
/craft-cli:qa https://myapp.vercel.app
/craft-cli:qa quick https://staging.myapp.com
/craft-cli:qa regression https://myapp.com
```

**Chains to:** `/debug` if issues found — "3 issues detected. Investigate?"

---

### `/eval` — Evaluation Engineering

Eight modes for rigorous LLM evaluation.

| Mode | What it does |
|------|--------------|
| `audit` | Diagnose eval infrastructure across 6 areas |
| `analyze` | Systematic error analysis on 20-50 traces |
| `judge <criterion>` | Design a binary Pass/Fail LLM judge |
| `validate` | Validate a judge against human-labeled data (target TPR/TNR > 90%) |
| `run` | Execute judges against a dataset with confidence intervals |
| `rag` | Evaluate RAG pipelines — separates retrieval from generation metrics |
| `synthetic` | Generate dimension-based synthetic test data |
| `dashboard` | Summary of all recent eval runs with trend indicators |

<details>
<summary><strong>Scenario: Building an eval from scratch</strong></summary>

```
/craft-cli:eval analyze
→ Reads 30 traces, categorizes failures
→ Top failure: "Model fabricates citations that don't exist" (12/30)

/craft-cli:eval judge citation_accuracy
→ Designs binary judge: "Does every citation reference
   a real document in the provided context?"
→ Pass: all citations traceable. Fail: any fabricated citation.

/craft-cli:eval validate
→ Runs judge against 40 human-labeled examples
→ TPR: 94%, TNR: 91% — above threshold

/craft-cli:eval run
→ Executes against full dataset
→ Pass rate: 73% (95% CI: 68-78%)
→ Saves to .craft/context/eval.md for /ship
```

</details>

```
/craft-cli:eval audit
/craft-cli:eval judge factual_accuracy
/craft-cli:eval dashboard
```

---

### `/debug` — Systematic Debugging

Four-phase protocol. No shortcuts, no guessing.

```
reproduce → isolate → understand → fix
```

Each phase has a gate — you don't move forward until the current phase is complete. Root cause is stated in one sentence before any fix is proposed.

<details>
<summary><strong>Scenario: Debugging a race condition</strong></summary>

```
You: "Users sometimes see stale data after saving."

Claude auto-invokes /debug.

Phase 1 — Reproduce:
→ "Open two tabs. Edit in tab 1, save. Switch to tab 2,
   reload. Tab 2 shows old data ~30% of the time."

Phase 2 — Isolate:
→ Checks git log — revalidation was changed 3 days ago
→ Traces data flow: save → API → DB → revalidate → fetch
→ "The revalidation call returns before the DB write commits.
   It's a race between write commit and cache invalidation."

Phase 3 — Understand:
→ Root cause: "revalidatePath() fires on API response,
   but the database uses eventual consistency. The cache
   revalidation reads stale data because the write hasn't
   propagated yet."

Phase 4 — Fix:
→ Adds await to ensure write commits before revalidation
→ Verifies: 50 rapid save-and-reload cycles, 0 stale reads
→ Runs test suite: all passing

"Bug fixed. Run /review to check for similar patterns?"
```

</details>

```
/craft-cli:debug
/craft-cli:debug --postmortem   # generate incident report after fix
```

**Chains to:** `/review` — "Bug fixed. Check for similar issues in adjacent code?"

---

### `/docs` — Library Documentation Lookup

Fetches fresh, up-to-date library documentation via Context7 MCP.

| Mode | Example | What it does |
|------|---------|--------------|
| **Quick** | `/craft-cli:docs next.js app router` | Key APIs, parameters, code example |
| **Deep** | `/craft-cli:docs supabase rls policies` | Patterns, gotchas, version-specific behavior |
| **Compare** | `/craft-cli:docs drizzle vs prisma` | Side-by-side API comparison |

Auto-triggers when Claude detects unfamiliar API usage or deprecated patterns. Pairs with `/think` (fetch docs before designing), `/debug` (verify API assumptions), and `/ship` (check for deprecated usage).

---

### `verification` — Completion Gate

Enforces evidence-based completion claims. Not invoked directly — it's a discipline baked into every skill.

**The rule:** No "done", "that should work", or "I've fixed it" without fresh evidence from the current session.

| Claim | Required evidence |
|-------|-------------------|
| "Tests pass" | Actual test runner output showing pass |
| "Build succeeds" | Actual build output with no errors |
| "Bug is fixed" | Reproduction steps now produce correct behavior |
| "No regressions" | Test suite output after changes |
| "Types are clean" | `tsc --noEmit` output with no errors |

What does NOT count: "I wrote the code correctly, so it should work." Run it.

---

### `using-craft-cli` — Meta-Skill

The connective tissue. Loaded on every session, it teaches Claude:

- **When to auto-trigger** — error appears → `/debug`, user says "ship it" → `/ship`
- **How skills chain** — after `/think` → suggest `/challenge` or `/plan`
- **Context conventions** — read `.craft/context/` before asking the user to repeat
- **Instruction priority** — user > active skill > meta-skill > defaults

---

## Agent

### `code-reviewer`

Specialized review agent dispatched by `/review` for branches with 5+ changed files. Performs parallel analysis with confidence scoring (0-100). Only surfaces findings >= 75. Includes severity classification, file locations, evidence, and recommended fixes.

---

## Hooks

Five quality gates that run automatically — no exceptions, no opt-out.

| Hook | Event | What it enforces |
|------|-------|-----------------|
| **Pre-commit validator** | Before `git commit` | TypeScript type checks + lint must pass |
| **Secret scanner** | Before Write/Edit | Blocks API keys, tokens, passwords (Stripe, AWS, GitHub, Slack, OpenAI, Supabase patterns) |
| **Post-edit test runner** | After Write/Edit | Runs project test suite (npm test or pytest) |
| **Session context** | Session start | Loads git branch, recent commits, changes, open PR |
| **Completion check** | Before stop | Blocks if modified files have `any` types, `console.log`, or TypeScript errors |

---

## Scenarios: Full Workflow Examples

### New Feature: End to End

```
You: "We need to add team invitations to the app."

/think expand → explores scope: email invites, link invites,
  role selection, expiry, revocation, bulk invite...

/think reduce → cuts to core: email invite with accept/decline.
  One role (member). 7-day expiry. No bulk.
  → Saves ADR + design.md

/challenge advocate → attacks assumptions:
  "Assumption: users have valid email addresses in the system.
   Counter: 23% of accounts use OAuth without email scope."
  Verdict: proceed with mitigation (add email prompt for OAuth users)
  → Saves challenge.md

/plan → 5 steps incorporating the email mitigation
  → Step 1: Add email field to OAuth onboarding
  → Step 2: Create invitations table
  → Step 3: Build invite API
  → Step 4: Email sending via Resend
  → Step 5: Accept/decline UI

implement → works through each step

/review → 0 critical, 2 informational
/ship → PR created
/qa https://staging.app.com → health score: 94
```

### Hotfix: Production Bug

```
You: "Users are getting 500 errors on the dashboard."

/debug → reproduce (hit /api/dashboard, get 500)
  → isolate (new deployment 2 hours ago, changed query)
  → understand ("GROUP BY clause references column removed
     in migration 047")
  → fix (restore column reference, add test)
  → postmortem saved

/review → checks for similar query patterns
/ship --hotfix → skips eval gate, creates PR
/qa https://app.com/dashboard → health score: 98
```

### Evaluating LLM Quality

```
/eval analyze → reads 40 traces, finds "hallucinated dates" in 35%
/eval judge date_accuracy → designs Pass/Fail judge
/eval validate → TPR 96%, TNR 89% → refine → TNR 93%
/eval run → pass rate 71% (CI: 65-77%)
/eval dashboard → shows trend across last 5 runs
```

---

## Requirements

| Dependency | Required for | Install |
|------------|-------------|---------|
| **Context7 MCP** | `/docs` — library documentation | [context7](https://github.com/upstash/context7) |
| **Chrome DevTools MCP** | `/qa` — browser testing | [chrome-devtools-mcp](https://github.com/nichochar/chrome-devtools-mcp) |
| **Node.js** | Hooks — type checking, lint, tests | [nodejs.org](https://nodejs.org) |
| **gh CLI** | `/ship` — PR creation, session context | [cli.github.com](https://cli.github.com) |

All dependencies are optional — skills that require them will note when they're missing and suggest alternatives.

## Project Structure

```
craft-cli/
├── plugins/craft-cli/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── skills/
│   │   ├── using-craft-cli/SKILL.md      # Meta-skill: auto-trigger + chaining
│   │   ├── think/SKILL.md                # Design thinking + ADRs
│   │   ├── challenge/SKILL.md            # Adversarial: advocate/invert/backcast
│   │   ├── plan/SKILL.md                 # Implementation planning
│   │   ├── review/SKILL.md               # Code review + confidence scoring
│   │   │   └── references/checklist.md
│   │   ├── qa/SKILL.md                   # Live URL testing
│   │   │   └── references/
│   │   │       ├── issue-taxonomy.md
│   │   │       └── report-template.md
│   │   ├── ship/SKILL.md                 # Ship: --resume, --hotfix, --dry-run
│   │   ├── eval/SKILL.md                 # Evaluation engineering + dashboard
│   │   │   └── references/
│   │   │       ├── judge-template.md
│   │   │       └── methodology.md
│   │   ├── debug/SKILL.md                # Debugging + postmortem
│   │   ├── docs/SKILL.md                 # Library docs via Context7
│   │   └── verification/SKILL.md         # Completion gate
│   ├── agents/
│   │   └── code-reviewer.md              # Parallel review agent
│   └── hooks/
│       ├── hooks.json
│       └── scripts/
│           ├── pre-commit-validate.sh
│           ├── secret-scanner.sh
│           ├── post-edit-test.sh
│           ├── session-context.sh
│           └── completion-check.sh
├── .claude-plugin/
│   └── marketplace.json
├── LICENSE
└── README.md
```

## Testing

After installing, verify the workflow:

```bash
# Validate plugin structure
claude plugin validate .

# Test individual skills
/craft-cli:think               # Should prompt for design problem
/craft-cli:challenge advocate  # Should list and attack assumptions
/craft-cli:plan                # Should read upstream context or ask "what are we building?"
/craft-cli:review              # Should analyze current branch diff
/craft-cli:ship --dry-run      # Should run preflight through review
/craft-cli:debug               # Should prompt for bug details
/craft-cli:eval audit          # Should audit eval infrastructure
/craft-cli:docs react          # Should fetch React docs via Context7
/craft-cli:qa https://example.com  # Should run full QA test

# Test skill chaining
# /think should suggest /challenge or /plan when design is captured
# /challenge should suggest /plan when verdict is "proceed"
# /review should suggest /ship when no critical issues found
# /ship should suggest /qa after PR is created

# Test auto-triggering
# Describe a design problem → should auto-invoke /think
# Say "what could go wrong" → should auto-invoke /challenge
# Report a bug → should auto-invoke /debug
# Say "ship it" → should auto-invoke /ship
```

## License

MIT

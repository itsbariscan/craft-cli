<p align="center">
  <strong>craft-cli</strong>
  <br>
  A developer workflow toolkit for Claude Code
  <br><br>
  <a href="#install">Install</a> · <a href="#skills">Skills</a> · <a href="#how-it-works">How It Works</a> · <a href="#examples">Examples</a> · <a href="https://github.com/itsbariscan/craft-cli/issues">Report Bug</a>
  <br><br>
  <img src="https://img.shields.io/badge/version-3.0.0-5E6AD2?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/skills-13-blue?style=flat-square" alt="Skills">
  <img src="https://img.shields.io/badge/agents-2-blue?style=flat-square" alt="Agents">
  <img src="https://img.shields.io/badge/hooks-5-blue?style=flat-square" alt="Hooks">
  <img src="https://img.shields.io/badge/made%20for-Claude%20Code-F5A623?style=flat-square" alt="Made for Claude Code">
</p>

<br>

> **This is a personal project.** I built craft-cli to codify my own development workflow — the way I think about scoping, designing, challenging, planning, reviewing, and shipping software. It reflects my beliefs about quality and how I want to work with AI. It may not fit your workflow exactly, and that's fine. Fork it, rip out what you don't need, add what you do. This is the beginning of a journey, not the destination.

<br>

## What is this?

craft-cli is a [Claude Code plugin](https://docs.anthropic.com/en/docs/claude-code) that turns Claude into a structured development partner. Instead of ad-hoc prompting, you get **13 skills that chain together**, **2 specialized agents**, and **5 automated quality gates** — all working as a connected workflow.

The idea is simple: every phase of development — from "what should we build?" to "is this deployed and working?" — should have a structured approach that passes context forward.

**You don't need to memorize commands.** Describe a design problem and `/think` activates. Say "ship it" and `/ship` runs the full pipeline. Report a bug and `/debug` takes over. The skills auto-trigger based on what you're saying and doing.

<br>

## Why does this exist?

Most Claude Code plugins give you isolated commands. You run one, get a result, and start from scratch on the next. Context is lost between steps.

craft-cli is different:

- **Skills chain together.** `/scope` feeds into `/think`, which feeds into `/challenge`, which feeds into `/plan`. Each skill reads what the previous one wrote.
- **Context is structured.** Every skill writes YAML-frontmattered artifacts to `.craft/context/`. Downstream skills parse these programmatically — not just as text blobs.
- **Knowledge persists across sessions.** Postmortems, design decisions, and risk patterns are saved to `.craft/knowledge/` and checked automatically when relevant.
- **Quality gates are automated.** Five hooks run on every edit, every commit, every session start, and every session end. No opt-out.
- **Auto-triggering works.** Skills activate based on natural language cues. You don't need to remember which command to run.

<br>

## How is this different from other plugins?

| | Other plugins | craft-cli |
|---|---|---|
| **Scope** | Individual commands | Connected workflow (13 skills, 2 agents, 5 hooks) |
| **Context** | Lost between commands | Passed forward via structured `.craft/context/` artifacts |
| **Memory** | None | `.craft/knowledge/` persists insights across sessions |
| **Triggering** | Manual slash commands | Auto-triggers on natural language patterns |
| **Chaining** | None | Each skill recommends the logical next step |
| **Quality** | Trust the developer | Five automated gates that enforce standards |
| **Reliability** | Skills loaded on-demand (~53% invocation rate) | Three-layer injection: CLAUDE.md + SessionStart hook + meta-skill |

The reliability layer is worth highlighting. [Vercel's research](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals) found that skills alone only get invoked ~53% of the time. craft-cli solves this by injecting workflow rules at three levels — your project's `CLAUDE.md` (always in context), a SessionStart hook (loaded every session), and the meta-skill as a detailed fallback.

<br>

---

<br>

## Install

### One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/itsbariscan/craft-cli/main/plugins/craft-cli/install.sh | bash
```

This does three things:

1. **Installs the plugin** — `claude plugin add itsbariscan/craft-cli`
2. **Appends workflow rules to your project's `CLAUDE.md`** — never overwrites existing content, uses HTML markers for clean updates
3. **Adds `.craft/` to `.gitignore`** — session artifacts and knowledge entries shouldn't be in source control

The script is idempotent. Run it again and it skips steps that are already done.

### Manual install

If you prefer to do it step by step:

```bash
# Install the plugin
claude plugin add itsbariscan/craft-cli

# In your project root, run the setup script
cd your-project
bash ~/.claude/plugins/cache/craft-cli/plugins/craft-cli/install.sh
```

### What the install script does to your CLAUDE.md

The script appends a block wrapped in `<!-- craft-cli:start -->` and `<!-- craft-cli:end -->` markers. Your existing content is never touched. To remove craft-cli rules later, just delete everything between those markers.

The appended rules include:
- Auto-trigger conditions (11 natural language patterns → skill mappings)
- Skill chaining recommendations
- Context passing table
- Knowledge system configuration
- Verification requirements

### Uninstall

```bash
claude plugin remove craft-cli
```

Then remove the `<!-- craft-cli:start -->` ... `<!-- craft-cli:end -->` block from your `CLAUDE.md` if you added it.

<br>

---

<br>

## How It Works

### The Workflow

craft-cli organizes development into a directed flow. Each skill knows what comes before it and what comes after.

```
  /scope         Define what you're building — and what you're not
     │
  /think         Design with three gears: expand, hold, or reduce
     │
  /challenge     Stress-test the design before committing
     │
  /plan          Break the design into ordered, verifiable steps
     │
  implement      Write code, step by step
     │  ╰── /docs     Fetch library docs when you hit an unfamiliar API
     │  ╰── /debug    When something breaks → test-writer agent
     │
  /review        Two-pass code review with confidence scoring
     │
  /ship          Build → test → eval → review → commit → PR
     │
  /qa            Test the live deployment
```

You don't need to follow the full flow every time. Fixing a bug? Start at `/debug`. Quick change? Skip to `/review`. The workflow adapts to the size of the task.

### Context Passing

Every skill writes a structured artifact to `.craft/context/` with YAML frontmatter. The next skill reads it and makes decisions based on the structured data — not just free text.

```yaml
# Example: .craft/context/challenge.md
---
skill: challenge
mode: invert
timestamp: 2025-01-15T10:30:00Z
verdict: proceed_with_mitigations
risk_count: { fatal: 0, high: 2, medium: 1, low: 3 }
mitigations:
  - Add email prompt for OAuth users without email scope
  - Set up production-scale test data before writing resolvers
---

## Pre-mortem: GraphQL Migration

Failure Path 1: The Long Tail ...
```

When `/plan` reads this file, it sees `verdict: proceed_with_mitigations` and automatically adds each mitigation as a plan step. If the verdict were `reconsider`, it would warn you before planning.

| Skill | Writes | Read by | Key frontmatter fields |
|-------|--------|---------|----------------------|
| `/scope` | `scope.md` | `/think`, `/plan`, `/challenge` | `suggested_gear`, `constraints` |
| `/think` | `design.md` | `/challenge`, `/plan` | `gear`, `problem`, `decisions` |
| `/challenge` | `challenge.md` | `/plan` | `verdict`, `mitigations`, `risk_count` |
| `/plan` | `plan.md` | implementation | `steps`, `risks`, `out_of_scope` |
| `/review` | `review.md` | `/ship` | `status` (clean/has_criticals) |
| `/eval` | `eval.md` | `/ship` | `has_regressions`, `overall_pass_rate` |
| `/debug` | `postmortem.md` | `/review`, test-writer agent | `root_cause`, `affected_files` |
| `/qa` | `qa-report.md` | `/debug` | `health_score`, `lighthouse` |

### Knowledge Persistence

Some things are worth remembering across sessions. craft-cli persists insights to `.craft/knowledge/`:

- **`/debug`** auto-saves postmortems after `--postmortem`
- **`/think`** auto-saves design decisions (ADRs)
- **`/challenge`** auto-saves risk patterns when Fatal risks are found
- **`/remember`** saves anything manually

Before starting work, skills check knowledge automatically. `/debug` looks for past postmortems in the same files. `/think` checks for previous design decisions. `/challenge` looks for known risk patterns. This means Claude gets smarter about *your* project over time.

### Auto-Triggering

You don't need to type slash commands. Skills activate on natural language:

| You say... | craft-cli invokes |
|---|---|
| "I want to build...", "new feature:", unclear scope | `/scope` |
| "How should we approach...", choosing between options | `/think` |
| "What could go wrong?", "poke holes", high-conviction idea | `/challenge` |
| Design is agreed, needs implementation steps | `/plan` |
| "How does X work?" about a library | `/docs` |
| Error appears, tests fail, bug report | `/debug` |
| "Review this", "check the code" | `/review` |
| "Ship it", "create a PR", "push this" | `/ship` |
| URL to test, deployment completed | `/qa` |
| Prompt quality, LLM evaluation | `/eval` |
| "Remember this", "have we seen this before?" | `/remember` |

### Skill Chaining

After each skill completes, it recommends the next step:

```
/scope  → /think (with gear suggestion) or /plan (if trivial)
/think  → /challenge (stress-test) or /plan (low-risk)
/challenge proceed → /plan with mitigations
/challenge reconsider → back to /think
/plan   → start implementing step 1
/debug  → test-writer agent → /review
/review clean → /ship
/review criticals → fix, then re-review
/ship   → /qa <deployed-url>
/qa     → /debug (if issues) or close the loop
```

<br>

---

<br>

## Skills

### `/scope` — Define Boundaries

The first step. Before designing anything, define what you're building, what constrains you, and what you're *not* building.

Three fields:
- **Building** — one sentence, no ambiguity
- **Constraints** — time, complexity, dependencies, tech stack
- **Not Building** — explicit exclusions that prevent scope creep

Based on your constraints, `/scope` recommends a `/think` gear: tight deadline suggests **REDUCE**, open exploration suggests **EXPAND**, spec'd out design suggests **HOLD**. For trivial tasks, it recommends skipping `/think` entirely and going straight to `/plan`.

```
/craft-cli:scope add user notifications to the app
/craft-cli:scope rebuild the auth system
```

<br>

### `/think` — Design Thinking

Three-gear brainstorming for non-trivial decisions.

| Gear | When | What it does |
|------|------|-------------|
| **EXPAND** | New idea, early exploration | Push scope up. "What's the 10x version?" Generate options without evaluating. |
| **HOLD** | Spec'd out, needs stress-testing | Lock scope exactly as stated. Walk every edge case, every failure mode. |
| **REDUCE** | Overscoped, need focus | Cut to core value. Remove everything that isn't load-bearing. |

**The Commitment Rule:** Once a gear is picked, commit fully. No silent drift between gears. If the gear needs to change, call it out explicitly.

```
/craft-cli:think expand — what if we rebuilt auth from scratch?
/craft-cli:think reduce — we have 2 days, what ships?
/craft-cli:think hold  — walk me through every failure mode
```

<details>
<summary>Example: Designing a notification system</summary>

```
You: "We need to add notifications."

Claude auto-invokes /think, recommends EXPAND.

/think expand:
  "What if notifications were a platform — webhooks,
   email digests, Slack, push, in-app, notification
   center with filters?"
  "What if users could create custom rules?"

You: "That's too much. We have 2 weeks."

Claude: "Drifting from EXPAND to REDUCE. Switch gears?"

You: "Yes, reduce."

/think reduce:
  "Core value: users don't miss things that need attention."
  "Minimum: bell icon, unread count, 3 event types,
   mark as read. No email, no push, no filters."
  → Saves ADR + design.md + knowledge entry

"Stress-test with /challenge? Or jump to /plan?"
```

</details>

<br>

### `/challenge` — Adversarial Thinking

Stress-test ideas before committing. Three modes, three angles of attack.

| Mode | Approach |
|------|----------|
| **Advocate** | List every assumption — stated and unstated. Attack each with the strongest counterargument. Produce risk map. |
| **Invert** | "It's 12 months from now. This failed completely. Why?" Work backwards through the causal chain. |
| **Backcast** | Write the success announcement first. Then: what must be true? Gaps between "must be true" and "is true today" are your risks. |

**The Honesty Rule:** No softening language. No false balance. Specific over general. Steel-man before attacking.

```
/craft-cli:challenge advocate our pricing model
/craft-cli:challenge invert the migration plan
/craft-cli:challenge backcast the v2 launch
```

<details>
<summary>Example: Pre-mortem on a migration</summary>

```
You: "Migrating REST to GraphQL. Should take 6 weeks."

Claude auto-invokes /challenge invert.

"It's 12 months from now. The migration failed. What happened?"

Failure Path 1: The Long Tail
  "80% migrated in 3 weeks. The remaining 20% had complex
   nested relationships — took 4 months. REST couldn't be
   deprecated because mobile clients pinned to v2.1."
  Early signal: velocity drops below 3 endpoints/day after week 2
  Prevention: audit ALL endpoints by complexity before committing

Failure Path 2: The N+1 Apocalypse
  "p99 went from 200ms to 3.2s. DataLoader wasn't implemented.
   Dev dataset had 50 rows — nobody noticed."
  Early signal: no load testing plan in sprint 1
  Prevention: production-scale test data before writing resolvers

Verdict: proceed with mitigations
→ Saves challenge.md with structured frontmatter

"/plan with mitigations?"
```

</details>

<br>

### `/plan` — Implementation Planning

Turn decisions into ordered, executable steps. Each step specifies: what changes, where, how, and how to verify it worked.

Reads upstream context automatically — `scope.md`, `design.md`, `challenge.md`. If `/challenge` found mitigations, they become plan steps. If the verdict was `reconsider`, you get a warning before planning.

```
/craft-cli:plan add user avatar upload with S3
/craft-cli:plan refactor the payment flow
```

<details>
<summary>Example: Planning from upstream context</summary>

```
/plan

Reads design.md: "In-app notifications. Bell icon, 3 events."
Reads challenge.md: "Risk: notification volume overwhelms DB.
  Mitigation: batch writes, TTL on old notifications."

## Plan: In-app notification system

1. Create notifications table with TTL
   Files: src/db/schema.ts, src/db/migrations/
   Verify: pnpm db:migrate succeeds

2. Build notification service with batch writes
   Files: src/services/notifications.ts
   Verify: unit test with 1000 concurrent notifications

3. Add bell icon component
   Files: src/components/NotificationBell.tsx
   Verify: component renders with mock data

Risks: batch write timing may need tuning (from /challenge)
Out of scope: email, push, filters

"Start implementing step 1?"
```

</details>

<br>

### `/debug` — Systematic Debugging

Four-phase protocol. No shortcuts, no guessing.

```
reproduce → isolate → understand → fix
```

Each phase has a gate — you don't move forward until the current phase is complete. Root cause is stated in one sentence before any fix is proposed. After the fix, the **test-writer agent** automatically generates a regression test.

```
/craft-cli:debug
/craft-cli:debug --postmortem   # save incident report to knowledge
```

<details>
<summary>Example: Debugging a race condition</summary>

```
You: "Users sometimes see stale data after saving."

Phase 1 — Reproduce:
  "Open two tabs. Edit in tab 1, save. Tab 2 shows old data ~30%."

Phase 2 — Isolate:
  Checks .craft/knowledge/ for past postmortems
  Traces: save → API → DB → revalidate → fetch
  "Revalidation returns before DB write commits."

Phase 3 — Understand:
  Root cause: "revalidatePath() fires on API response, but
  DB uses eventual consistency. Cache reads stale data."

Phase 4 — Fix:
  Adds await to ensure write commits before revalidation
  Verifies: 50 save-reload cycles, 0 stale reads
  → test-writer agent generates regression test
  → Postmortem saved to context + knowledge

"/review to check for similar patterns?"
```

</details>

<br>

### `/review` — Code Review

Structured two-pass review with confidence scoring.

**Pass 1 — Critical (blocks merge):** RLS bypass, auth violations, unvalidated mutations, XSS, exposed secrets, SQL injection, race conditions, missing error handling at boundaries.

**Pass 2 — Informational (noted):** Missing states (error/loading/empty), N+1 queries, dead code, accessibility, performance.

For branches with 5+ changed files, dispatches the `code-reviewer` agent for parallel analysis. Only surfaces findings at confidence >= 75/100.

```
/craft-cli:review
```

<br>

### `/ship` — Ship Pipeline

Full pipeline from feature branch to PR. Stops on failure at any step.

```
preflight → sync → build → test → eval gate → review → commit → PR
```

Reads upstream context: if `review.md` has `status: has_criticals`, merge is blocked. If `eval.md` has `has_regressions: true`, merge is blocked.

```
/craft-cli:ship              # full pipeline
/craft-cli:ship --dry-run    # steps 1-6, no commit/push
/craft-cli:ship --resume     # pick up where you left off
/craft-cli:ship --hotfix     # skip eval gate for urgent fixes
```

<br>

### `/qa` — Live URL Testing

Chrome DevTools-powered QA with health scoring (0-100) and regression tracking.

| Mode | What it does |
|------|-------------|
| **Full** | Lighthouse + console + network + interactive + responsive (375/768/1280px) + accessibility |
| **Quick** | Lighthouse + console + network errors only |
| **Regression** | Full test compared against saved baseline |

Every issue includes: screenshot, severity, category, description, repro steps, expected vs actual.

```
/craft-cli:qa https://myapp.vercel.app
/craft-cli:qa quick https://staging.myapp.com
/craft-cli:qa regression https://myapp.com
```

<br>

### `/eval` — Evaluation Engineering

Eight modes for rigorous LLM evaluation.

| Mode | What it does |
|------|-------------|
| `audit` | Diagnose eval infrastructure across 6 areas |
| `analyze` | Error analysis on 20-50 traces |
| `judge <criterion>` | Design a binary Pass/Fail LLM judge |
| `validate` | Judge vs human labels (target TPR/TNR > 90%) |
| `run` | Execute judges with confidence intervals |
| `rag` | Evaluate RAG pipelines (retrieval vs generation) |
| `synthetic` | Generate dimension-based test data |
| `dashboard` | Summary of all eval runs with trends |

```
/craft-cli:eval audit
/craft-cli:eval judge factual_accuracy
/craft-cli:eval dashboard
```

<br>

### `/docs` — Library Documentation

Fetches fresh documentation via [Context7](https://github.com/upstash/context7) MCP. Three modes:

| Mode | Example |
|------|---------|
| **Quick** | `/craft-cli:docs next.js app router` |
| **Deep** | `/craft-cli:docs supabase rls policies` |
| **Compare** | `/craft-cli:docs drizzle vs prisma` |

Auto-triggers when Claude detects unfamiliar API usage or deprecated patterns.

<br>

### `/remember` — Knowledge Management

Save and retrieve insights across sessions.

```
/craft-cli:remember we chose Resend over SendGrid because of webhook reliability
/craft-cli:remember search auth bugs
/craft-cli:remember search GraphQL decisions
```

Five knowledge types: `postmortem`, `decision`, `risk-pattern`, `convention`, `insight`. Other skills auto-save entries — `/remember` is for manual saves and retrieval.

<br>

### `verification` — Completion Gate

Not invoked directly. Baked into every skill.

**The rule:** No "done", "that should work", or "I've fixed it" without fresh evidence from the current session.

| Claim | Required evidence |
|-------|-------------------|
| "Tests pass" | Actual test runner output |
| "Build succeeds" | Actual build output |
| "Bug is fixed" | Reproduction steps now produce correct behavior |
| "No regressions" | Test suite output after changes |

<br>

---

<br>

## Agents

### `code-reviewer`

Dispatched by `/review` for branches with 5+ changed files. Performs parallel analysis with confidence scoring (0-100). Only surfaces findings >= 75. Categories: auth/authz bypass, injection vectors, missing validation, race conditions, accessibility, performance.

### `test-writer`

Dispatched by `/debug` after a bug fix. Reads the postmortem, understands the root cause, detects your test framework (jest/vitest/pytest/mocha/cargo/go test), and writes a regression test that would fail if the fix were reverted. One test per bug. Matches your project's test style.

<br>

---

<br>

## Hooks

Five quality gates that run automatically. No opt-out.

| Hook | When | What it does |
|------|------|-------------|
| **Pre-commit validator** | Before `git commit` | TypeScript type checks + lint must pass |
| **Secret scanner** | Before any file write/edit | Blocks API keys, tokens, passwords (14 patterns) |
| **Post-edit test runner** | After any file write/edit | Runs project test suite |
| **Session context** | Every session start | Loads git state + injects workflow rules |
| **Completion check** | Before session ends | Blocks if modified files have `any` types, `console.log`, or TS errors |

<br>

---

<br>

## Examples

### Full Feature: Team Invitations

```
You: "We need to add team invitations to the app."

/scope → Building: team invitation system.
  Constraints: 2 weeks, medium complexity, depends on existing auth.
  Not building: bulk invite, role selection, link invites.
  → Suggests /think reduce (tight timeline)

/think reduce → Core: email invite with accept/decline.
  One role (member). 7-day expiry. No bulk.
  → Saves design.md + knowledge entry

/challenge advocate → "Assumption: users have valid email.
  Counter: 23% of accounts use OAuth without email scope."
  Verdict: proceed with mitigation (add email prompt for OAuth)
  → Saves challenge.md

/plan → 5 steps, incorporating the email mitigation:
  1. Add email field to OAuth onboarding
  2. Create invitations table
  3. Build invite API
  4. Email sending via Resend
  5. Accept/decline UI

implement → works through each step with verification

/review → 0 critical, 2 informational
/ship → PR created
/qa https://staging.app.com → health score: 94
```

### Hotfix: Production Bug

```
You: "Users are getting 500 errors on the dashboard."

/debug →
  Checks .craft/knowledge/ — finds past postmortem on dashboard queries
  reproduce: GET /api/dashboard returns 500
  isolate: new deployment 2 hours ago changed the query
  understand: "GROUP BY references column removed in migration 047"
  fix: restore column reference
  → test-writer generates regression test
  → postmortem saved to knowledge

/review → checks for similar query patterns
/ship --hotfix → PR created (skips eval gate)
/qa https://app.com/dashboard → health score: 98
```

### Evaluating LLM Quality

```
/eval analyze → reads 40 traces, "hallucinated dates" in 35%
/eval judge date_accuracy → designs binary Pass/Fail judge
/eval validate → TPR 96%, TNR 89% → refine → TNR 93%
/eval run → pass rate 71% (CI: 65-77%)
/eval dashboard → trend across last 5 runs
```

### Quick Bug Fix (Short Flow)

```
You: "The submit button doesn't work on mobile."

/debug →
  reproduce: tap submit on iPhone Safari, nothing happens
  isolate: click handler uses mousedown, not touch events
  understand: "Safari doesn't fire mousedown on tap"
  fix: change to pointerdown event
  → test-writer generates touch event test

/review → clean
/ship → PR created
```

<br>

---

<br>

## Getting Started (For Beginners)

### I just installed it. Now what?

Start a new Claude Code session in your project directory. You'll see craft-cli load automatically (the SessionStart hook injects workflow rules).

**Try this first:**

```
You: "I want to build a dark mode toggle for the app."
```

craft-cli will auto-invoke `/scope` to help you define boundaries. Then it'll suggest `/think` to design the approach. Follow the chain — each skill tells you what's next.

### Do I need to learn all 13 skills?

No. The three you'll use most often:

1. **`/think`** — when you're designing something
2. **`/debug`** — when something breaks
3. **`/ship`** — when you're ready to merge

Everything else flows naturally from these. As you get comfortable, the other skills will click into place.

### What if I don't want the full workflow?

Skip whatever you want. The workflow is a suggestion, not a requirement. Working on a quick fix? Jump straight to the code, then `/review` and `/ship`. The skills are designed to be useful individually — chaining makes them more powerful, but each one stands alone.

### What's `.craft/`?

A local directory where craft-cli stores session artifacts:

```
.craft/
├── context/      # Current session: scope.md, design.md, plan.md, etc.
└── knowledge/    # Cross-session: postmortems, decisions, risk patterns
```

It's in `.gitignore` — these files are personal working state, not source code.

<br>

---

<br>

## Requirements

| Dependency | Required for | Install |
|-----------|-------------|---------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | Everything | `npm install -g @anthropic-ai/claude-code` |
| [Context7 MCP](https://github.com/upstash/context7) | `/docs` | See Context7 repo |
| [Chrome DevTools MCP](https://github.com/nichochar/chrome-devtools-mcp) | `/qa` | See chrome-devtools-mcp repo |
| [gh CLI](https://cli.github.com) | `/ship` PR creation | `brew install gh` |
| Node.js | Hooks (type check, lint, tests) | [nodejs.org](https://nodejs.org) |

All dependencies except Claude Code are optional. Skills that need them will tell you when they're missing.

<br>

---

<br>

## Project Structure

```
craft-cli/
├── plugins/craft-cli/
│   ├── .claude-plugin/
│   │   └── plugin.json                   # Plugin manifest (v3.0.0)
│   ├── CLAUDE.md                         # Workflow rules template
│   ├── install.sh                        # Setup script
│   ├── skills/
│   │   ├── using-craft-cli/SKILL.md      # Meta-skill (orchestrator)
│   │   ├── scope/SKILL.md                # Project scoping
│   │   ├── think/SKILL.md                # Design thinking + ADRs
│   │   ├── challenge/SKILL.md            # Adversarial: advocate/invert/backcast
│   │   ├── plan/SKILL.md                 # Implementation planning
│   │   ├── review/SKILL.md               # Code review + confidence scoring
│   │   ├── qa/SKILL.md                   # Live URL testing
│   │   ├── ship/SKILL.md                 # Ship pipeline
│   │   ├── eval/SKILL.md                 # Evaluation engineering
│   │   ├── debug/SKILL.md                # Debugging + postmortem
│   │   ├── docs/SKILL.md                 # Library docs via Context7
│   │   ├── remember/SKILL.md             # Knowledge persistence
│   │   └── verification/SKILL.md         # Completion gate
│   ├── agents/
│   │   ├── code-reviewer.md              # Parallel review agent
│   │   └── test-writer.md                # Regression test generator
│   └── hooks/
│       ├── hooks.json                    # Hook configuration
│       └── scripts/
│           ├── pre-commit-validate.sh    # Type check + lint gate
│           ├── secret-scanner.sh         # API key blocker
│           ├── post-edit-test.sh         # Auto test runner
│           ├── session-context.sh        # Git context + rule injection
│           └── completion-check.sh       # Quality gate on stop
├── .claude-plugin/
│   └── marketplace.json
├── LICENSE
└── README.md
```

<br>

---

<br>

## A Note on This Project

This is the beginning of a journey. I built craft-cli to crystallize how I think about building software — the discipline of scoping before designing, designing before coding, challenging before committing, and verifying before claiming "done."

It's opinionated by design. It reflects my workflow, my standards, my beliefs about quality. Some of these opinions will resonate with you; others won't.

**This is not a one-size-fits-all tool.** It's a starting point.

Fork it. Rip out the skills that don't match your workflow. Add skills for your domain. Change the auto-trigger rules. Rewrite the hooks. Make it yours.

The plugin architecture makes this easy — each skill is a self-contained `SKILL.md` file. Add a folder, write a prompt, and it's a new skill. The context passing system means your new skills can read and write the same `.craft/context/` artifacts.

If you build something interesting on top of this, I'd love to see it.

<br>

---

<br>

## Contributing

This is a personal project, but contributions are welcome. If you have ideas for new skills, better prompt engineering, or workflow improvements:

1. Fork the repository
2. Create your branch (`git checkout -b feature/amazing-skill`)
3. Make your changes
4. Open a PR

<br>

## License

MIT — do whatever you want with it.

<br>

---

<p align="center">
  <sub>Quality is the strategy. Momentum is the method. Craft is the practice.</sub>
</p>

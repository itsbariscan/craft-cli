# craft-cli

A developer workflow toolkit for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — ten connected skills that chain together into a complete development workflow, one specialized agent, and five quality-gate hooks.

> Quality is not a feature to be prioritized — it is the strategy.

## Install

```bash
claude plugin add itsbariscan/craft-cli
```

## The Workflow

Skills connect into a directed graph. The **golden path** flows top-to-bottom, but you can enter at any point:

```
/think (design)
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

Skills auto-trigger based on context — you don't need to memorize commands. After each skill completes, it recommends the next step and passes context forward through `.craft/context/`.

## Skills

### `/think` — Design Thinking

Three-gear brainstorming for non-trivial decisions. Outputs ADRs (Architecture Decision Records).

| Gear | When to use | What it does |
|------|-------------|--------------|
| **Expand** | New idea, early exploration | Push scope up. Challenge assumptions. Generate options without evaluating. |
| **Hold** | Spec'd out, needs stress-testing | Lock scope. Walk every edge case, failure mode, and user path. |
| **Reduce** | Overscoped, needs focus | Cut to core value. Remove everything that isn't load-bearing. |

```
/craft-cli:think expand — what if we rebuilt auth from scratch?
/craft-cli:think reduce — we have 2 days, what ships?
```

**Chains to:** `/plan` — "Design captured. Want to break this into implementation steps?"

### `/plan` — Implementation Planning

Turns designs into ordered, executable steps. Each step specifies what, where, how, and how to verify.

```
/craft-cli:plan add user avatar upload with S3
```

- Reads upstream context from `/think` automatically
- Steps are independently verifiable and ordered by dependency
- Includes risk assessment and explicit scope exclusions
- Supports execution mode: say "let's go" to work through steps in order

**Chains to:** Implementation — "Plan ready with N steps. Start implementing step 1?"

### `/review` — Pre-Landing Code Review

Structured two-pass review with confidence scoring via the `code-reviewer` agent.

**Pass 1 (Critical — blocks merge):** RLS bypass, auth boundary violations, unvalidated mutations, XSS vectors, exposed secrets, SQL injection, TOCTOU races, missing error handling at boundaries.

**Pass 2 (Informational — noted):** Missing states (error/loading/empty), N+1 queries, dead code, accessibility gaps, performance concerns, stale SEO metadata.

For branches with 5+ changed files, dispatches the `code-reviewer` agent for parallel analysis. Only surfaces findings with confidence ≥ 75/100.

```
/craft-cli:review
```

**Chains to:** `/ship` if clean — "Review clean. Ready to ship?"

### `/qa` — Live URL Testing

Chrome DevTools-powered QA with health scoring and regression tracking.

| Mode | Command | What it does |
|------|---------|--------------|
| **Full** | `/craft-cli:qa https://example.com` | Lighthouse + console + network + interactive elements + responsive + accessibility |
| **Quick** | `/craft-cli:qa quick https://example.com` | Lighthouse + console + network errors only |
| **Regression** | `/craft-cli:qa regression https://example.com` | Full test compared against saved baseline, flags score drops > 5pts |

Health score (0–100) weights: Functional 20%, Console 15%, Accessibility 15%, UX 15%, Visual 10%, Performance 10%, Links 10%, Content 5%.

**Chains to:** `/debug` if issues found — "3 issues detected. Investigate?"

### `/ship` — Ship Workflow

Full pipeline from feature branch to PR. Stops on failure at any step.

```
preflight → sync with main → build → test → eval gate → review → commit → PR
```

```
/craft-cli:ship            # full pipeline
/craft-cli:ship --dry-run  # steps 1-6 only, no commit/push/PR
/craft-cli:ship --resume   # pick up where you left off
/craft-cli:ship --hotfix   # skip eval gate for urgent fixes
```

Reads upstream context from `/review` and `/eval` — won't re-run steps that already have results.

**Chains to:** `/qa <url>` — "PR created. Test the deployed version?"

### `/eval` — Evaluation Engineering

Eight modes for rigorous LLM evaluation.

| Mode | What it does |
|------|--------------|
| `audit` | Diagnose eval infrastructure across 6 areas |
| `analyze` | Systematic error analysis on 20-50 traces |
| `judge <criterion>` | Design a binary Pass/Fail LLM judge |
| `validate` | Validate a judge against human-labeled data (target TPR/TNR > 90%) |
| `run` | Execute judges against a dataset with confidence intervals |
| `rag` | Evaluate RAG pipelines — separates retrieval from generation |
| `synthetic` | Generate dimension-based synthetic test data |
| `dashboard` | Summary of all recent eval runs with trend indicators |

```
/craft-cli:eval audit
/craft-cli:eval judge factual_accuracy
/craft-cli:eval dashboard
```

### `/debug` — Systematic Debugging

Four-phase protocol. No shortcuts, no guessing.

```
reproduce → isolate → understand → fix
```

Each phase has a gate. Root cause is stated in one sentence before any fix is proposed. Supports `--postmortem` flag to generate an incident report after fixing.

```
/craft-cli:debug
/craft-cli:debug --postmortem
```

**Chains to:** `/review` — "Bug fixed. Check for similar issues in adjacent code?"

### `/docs` — Library Documentation Lookup

Fetches fresh, up-to-date library documentation via Context7 MCP before you write code against an API.

| Mode | Command | What it does |
|------|---------|--------------|
| **Quick** | `/craft-cli:docs next.js app router` | Specific topic — key APIs, parameters, code example |
| **Deep** | `/craft-cli:docs supabase rls policies` | Comprehensive — patterns, gotchas, version-specific behavior |
| **Compare** | `/craft-cli:docs drizzle vs prisma` | Side-by-side API comparison |

Auto-triggers when Claude detects unfamiliar API usage or "how does X work" questions.

### `verification` — Completion Gate

Enforces evidence-based completion claims. Not invoked directly — it's a discipline that all skills follow.

**The rule:** No "done", "that should work", or "I've fixed it" without fresh evidence from the current session.

| Claim | Required evidence |
|-------|-------------------|
| "Tests pass" | Actual test runner output |
| "Build succeeds" | Actual build output |
| "Bug is fixed" | Reproduction now produces correct behavior |
| "No regressions" | Test suite output after changes |

### `using-craft-cli` — Meta-Skill

Teaches Claude when to auto-invoke skills and how they chain together. Loaded on every session. Defines:
- Auto-trigger rules (e.g., error appears → `/debug`)
- Skill chaining (e.g., after `/think` → suggest `/plan`)
- Context passing conventions (`.craft/context/`)
- Instruction priority (user > skill > meta-skill > defaults)

## Agent

### `code-reviewer`

Specialized review agent dispatched by `/review` for branches with 5+ changed files. Performs parallel analysis with confidence scoring (0-100). Only surfaces findings ≥ 75.

## Hooks

Five quality gates that run automatically — no exceptions, no opt-out.

| Hook | Event | Trigger | What it enforces |
|------|-------|---------|-----------------|
| **Pre-commit validator** | `PreToolUse` | `Bash` (git commit) | Type checks and lint must pass before any commit |
| **Secret scanner** | `PreToolUse` | `Write\|Edit` | Blocks writes containing API keys, tokens, or passwords |
| **Post-edit test runner** | `PostToolUse` | `Write\|Edit` | Runs project test suite after every code change |
| **Session context** | `SessionStart` | Every session | Loads git branch, recent commits, uncommitted changes, open PR |
| **Completion check** | `Stop` | Every completion | Blocks if modified TS/JS files have `any` types, `console.log`, or TypeScript errors |

## Context System

Skills share state through `.craft/context/` in the project root:

| Skill | Writes | Read by |
|-------|--------|---------|
| `/think` | `design.md` | `/plan` |
| `/plan` | `plan.md` | Implementation |
| `/review` | `review.md` | `/ship` |
| `/eval` | `eval.md` | `/ship` |
| `/debug` | `postmortem.md` | `/review` |
| `/qa` | `qa-report.md` | `/debug` |

Add `.craft/` to your `.gitignore` — these are session artifacts, not source code.

## Requirements

| Dependency | Required for | Install |
|------------|-------------|---------|
| **Context7 MCP** | `/docs` — library documentation | [context7](https://github.com/upstash/context7) |
| **Chrome DevTools MCP** | `/qa` — browser testing | [chrome-devtools-mcp](https://github.com/nichochar/chrome-devtools-mcp) |
| **Node.js** | Hooks — type checking, lint, tests | [nodejs.org](https://nodejs.org) |
| **gh CLI** | `/ship` — PR creation, session context | [cli.github.com](https://cli.github.com) |

## Project Structure

```
craft-cli/
├── plugins/craft-cli/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── skills/
│   │   ├── using-craft-cli/SKILL.md      # Meta-skill (auto-trigger + chaining)
│   │   ├── think/SKILL.md                # Design thinking + ADRs
│   │   ├── plan/SKILL.md                 # Implementation planning
│   │   ├── review/SKILL.md               # Code review + confidence scoring
│   │   │   └── references/checklist.md
│   │   ├── qa/SKILL.md                   # Live URL testing
│   │   │   └── references/issue-taxonomy.md, report-template.md
│   │   ├── ship/SKILL.md                 # Ship workflow (--resume, --hotfix)
│   │   ├── eval/SKILL.md                 # Evaluation engineering + dashboard
│   │   │   └── references/judge-template.md, methodology.md
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

# Test skill chaining
/craft-cli:think         # Design something → should suggest /plan
/craft-cli:plan           # Plan implementation → should suggest starting
/craft-cli:review        # Review branch → should suggest /ship
/craft-cli:ship --dry-run # Preflight through review → should suggest /qa
/craft-cli:debug         # Debug a bug → should suggest /review
/craft-cli:docs react    # Fetch docs → should provide actionable API info

# Test auto-triggering (via using-craft-cli meta-skill)
# Describe a design problem → should auto-invoke /think
# Report a bug → should auto-invoke /debug
# Say "ship it" → should auto-invoke /ship
```

## License

MIT

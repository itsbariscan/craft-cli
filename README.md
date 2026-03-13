# craft-cli

A developer workflow toolkit for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — seven skills that encode how good software gets shipped, and five hooks that enforce it automatically.

> Quality is not a feature to be prioritized — it is the strategy.

## Install

```bash
claude plugin add itsbariscan/craft-cli
```

## Skills

### `/think` — Design Thinking

Three-gear brainstorming for non-trivial decisions.

| Gear | When to use | What it does |
|------|-------------|--------------|
| **Expand** | New idea, early exploration | Push scope up. Challenge assumptions. Generate options without evaluating. |
| **Hold** | Spec'd out, needs stress-testing | Lock scope. Walk every edge case, failure mode, and user path. |
| **Reduce** | Overscoped, needs focus | Cut to core value. Remove everything that isn't load-bearing. |

```
/craft-cli:think expand — what if we rebuilt auth from scratch?
/craft-cli:think reduce — we have 2 days, what ships?
```

### `/review` — Pre-Landing Code Review

Structured two-pass review against the target branch.

**Pass 1 (Critical — blocks merge):** RLS bypass, auth boundary violations, unvalidated mutations, XSS vectors, exposed secrets, SQL injection, TOCTOU races, missing error handling at boundaries.

**Pass 2 (Informational — noted):** Missing states (error/loading/empty), N+1 queries, dead code, accessibility gaps, performance concerns, stale SEO metadata.

```
/craft-cli:review
```

### `/qa` — Live URL Testing

Chrome DevTools-powered QA with health scoring and regression tracking.

| Mode | Command | What it does |
|------|---------|--------------|
| **Full** | `/craft-cli:qa https://example.com` | Lighthouse + console + network + interactive elements + responsive + accessibility |
| **Quick** | `/craft-cli:qa quick https://example.com` | Lighthouse + console + network errors only |
| **Regression** | `/craft-cli:qa regression https://example.com` | Full test compared against saved baseline, flags score drops > 5pts |

Health score (0–100) weights: Functional 20%, Console 15%, Accessibility 15%, UX 15%, Visual 10%, Performance 10%, Links 10%, Content 5%.

### `/ship` — Ship Workflow

Full pipeline from feature branch to PR. Stops on failure at any step.

```
preflight → sync with main → build → test → eval gate → review → commit → PR
```

```
/craft-cli:ship            # full pipeline
/craft-cli:ship --dry-run  # steps 1-6 only, no commit/push/PR
```

**Eval gate** triggers automatically when prompt/template/content files change — runs `/eval run` and checks pass rates against baseline.

### `/eval` — Evaluation Engineering

Seven modes for rigorous LLM evaluation.

| Mode | What it does |
|------|--------------|
| `audit` | Diagnose eval infrastructure across 6 areas (error analysis, judge validation, metric quality, data quality, coverage, freshness) |
| `analyze` | Systematic error analysis on 20-50 traces. Categories emerge from observation, not assumption. |
| `judge <criterion>` | Design a binary Pass/Fail LLM judge with task, definitions, examples, and output format |
| `validate` | Validate a judge against human-labeled data. Target: TPR > 90%, TNR > 90%. |
| `run` | Execute judges against a dataset with confidence intervals and bias correction |
| `rag` | Evaluate RAG pipelines — separates retrieval metrics (Recall@k, Precision@k, MRR) from generation metrics (faithfulness, relevance, completeness) |
| `synthetic` | Generate dimension-based synthetic test data when real data is sparse |

```
/craft-cli:eval audit
/craft-cli:eval judge factual_accuracy
/craft-cli:eval rag
```

### `/debug` — Systematic Debugging

Four-phase protocol. No shortcuts, no guessing.

```
reproduce → isolate → understand → fix
```

Each phase has a gate: you don't move forward until the current phase is complete. Root cause is stated in one sentence before any fix is proposed.

```
/craft-cli:debug
```

### `/docs` — Library Documentation Lookup

Fetches fresh, up-to-date library documentation via Context7 MCP before you write code against an API.

| Mode | Command | What it does |
|------|---------|--------------|
| **Quick** | `/craft-cli:docs next.js app router` | Specific topic lookup — key APIs, parameters, code example |
| **Deep** | `/craft-cli:docs supabase rls policies` | Comprehensive overview — patterns, gotchas, version-specific behavior |
| **Compare** | `/craft-cli:docs drizzle vs prisma` | Side-by-side API comparison of two libraries |

Auto-triggers when Claude detects unfamiliar API usage, deprecated patterns, or "how does X work" questions about a library.

## Hooks

Five quality gates that run automatically — no exceptions, no opt-out.

| Hook | Event | Trigger | What it enforces |
|------|-------|---------|-----------------|
| **Pre-commit validator** | `PreToolUse` | `Bash` (git commit) | Type checks and lint must pass before any commit |
| **Secret scanner** | `PreToolUse` | `Write\|Edit` | Blocks writes containing API keys, tokens, or passwords |
| **Post-edit test runner** | `PostToolUse` | `Write\|Edit` | Runs project test suite after every code change |
| **Session context** | `SessionStart` | Every session | Loads git branch, recent commits, uncommitted changes, open PR |
| **Completion check** | `Stop` | Every completion | Blocks if modified TS/JS files have `any` types, `console.log`, or TypeScript errors |

## How Skills Work Together

```
                    /think
                      |
                      v
     /docs -----> implement -----> /debug
                      |
                      v
                   /review
                      |
                      v
     /eval <----- /ship -------> /qa
```

- **`/think` + `/docs`** — Fetch real API surface before committing to an architecture
- **`/debug` + `/docs`** — Verify API assumptions when root cause involves library misunderstanding
- **`/ship` + `/review` + `/eval`** — Ship runs review automatically; eval gate triggers when prompt files change
- **`/qa`** — Test the deployed result after shipping

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
│   │   ├── think/SKILL.md
│   │   ├── review/SKILL.md
│   │   │   └── references/checklist.md
│   │   ├── qa/SKILL.md
│   │   │   └── references/issue-taxonomy.md, report-template.md
│   │   ├── ship/SKILL.md
│   │   ├── eval/SKILL.md
│   │   │   └── references/judge-template.md, methodology.md
│   │   ├── debug/SKILL.md
│   │   └── docs/SKILL.md
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

After installing, verify each skill loads correctly:

```bash
# Validate plugin structure
claude plugin validate .

# Test each skill invocation
/craft-cli:think         # Should prompt for a design problem
/craft-cli:review        # Should analyze current branch diff
/craft-cli:qa <url>      # Should navigate and test a live URL
/craft-cli:ship --dry-run # Should run preflight through review without committing
/craft-cli:eval audit    # Should audit eval infrastructure
/craft-cli:debug         # Should prompt for bug details
/craft-cli:docs react    # Should resolve library and fetch docs
```

Verify hooks fire on their events:

```bash
# Session context — fires on every new session
# Open a new Claude Code session, should see git context loaded

# Secret scanner — fires on every Write/Edit
# Try writing a file with "sk-abc123" — should be blocked

# Pre-commit validator — fires on git commit via Bash
# Make a change with a TypeScript error, try to commit — should be blocked

# Post-edit test runner — fires after Write/Edit
# Edit a source file — test suite should run automatically

# Completion check — fires on Stop
# Modify a .ts file to include `any` type — should block completion
```

## License

MIT

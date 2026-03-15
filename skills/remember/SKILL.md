---
name: remember
description: Save and retrieve knowledge entries across sessions. Persists postmortems, design decisions, risk patterns, and insights to .craft/knowledge/.
argument-hint: "[what to remember] or [search <terms>]"
allowed-tools: Read, Write, Glob, Grep
disable-model-invocation: false
---

# /remember — Knowledge Persistence

Save insights that should survive across sessions. The `.craft/knowledge/` directory is your long-term memory.

## Two Modes

### Save Mode (default)
Save a new knowledge entry.

```
/remember we decided against GraphQL because of N+1 complexity
/remember auth bypass bugs keep happening in the /api/users route
```

### Search Mode
Find past knowledge entries.

```
/remember search auth bugs
/remember search GraphQL decisions
```

## Save Process

1. **Extract the insight** — From `$ARGUMENTS` or conversation context. What's worth remembering?
2. **Classify type:**
   - `postmortem` — Bug root causes, failure patterns, incident learnings
   - `decision` — Architecture decisions, technology choices, tradeoff resolutions
   - `risk-pattern` — Recurring risks, attack vectors, failure modes across projects
   - `convention` — Team/project conventions, patterns to follow, patterns to avoid
   - `insight` — General learnings that don't fit other categories
3. **Generate keywords** — 3-7 searchable terms that would help find this entry later. Include the domain, technology, and failure mode if applicable.
4. **Write the entry** — Save to `.craft/knowledge/YYYY-MM-DD-<slug>.md`

### Knowledge Entry Format

```markdown
---
type: postmortem|decision|risk-pattern|convention|insight
keywords:
  - "<term 1>"
  - "<term 2>"
  - "<term 3>"
source_skill: debug|think|challenge|review|manual
project: "<project name or repo>"
date: YYYY-MM-DD
summary: "<one sentence>"
---

[Full content: the insight, decision rationale, pattern description, etc.]
```

## Search Process

1. **Parse search terms** — From `$ARGUMENTS` after "search"
2. **Scan `.craft/knowledge/`** — Read all files, match on:
   - Frontmatter `keywords` (primary match)
   - Frontmatter `type` (if user specifies "decisions", "postmortems", etc.)
   - Frontmatter `summary` (secondary match)
   - Body content (tertiary match)
3. **Rank by relevance** — Keyword matches > type matches > body matches
4. **Present results** — Show matching entries with date, type, summary, and a snippet of the content. If many matches, show top 5 with option to see more.

## Auto-Save Rules

Other skills automatically persist knowledge entries:
- **`/debug`** — After `--postmortem`, saves root cause and pattern as `type: postmortem`
- **`/think`** — After saving an ADR, saves key decisions as `type: decision`
- **`/challenge`** — After finding Fatal risks or recurring patterns, saves as `type: risk-pattern`

These auto-saves use the same format and directory. `/remember` is for manual entries and retrieval.

## Maintenance

Knowledge entries don't expire automatically. When a surfaced entry is stale or wrong:
- User says "forget this" or "this is outdated" → delete the file
- User says "update this" → edit the existing entry instead of creating a new one

Don't create duplicate entries. Before saving, check if a similar entry already exists (same `type` + overlapping `keywords`). If so, update the existing entry.

## When to auto-invoke

Trigger when:
- User says "remember this", "save this for later", "we should remember..."
- User says "what did we decide about...", "have we seen this before..."
- User asks about past decisions or patterns that might be in knowledge

Don't trigger for:
- Normal conversation
- When the information is clearly ephemeral (only relevant to current session)

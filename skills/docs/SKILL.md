---
name: docs
description: Use when the user asks "how does X work" about a library, when you're about to use an unfamiliar API, or when you encounter deprecated patterns. Fetches docs via Context7 MCP.
argument-hint: <library> [topic]
context: fork
disable-model-invocation: false
---

# /docs — Library Documentation Lookup

Fetch current library documentation before writing code against any API. Avoid coding against stale assumptions.

## Three Modes

### QUICK LOOKUP (default)
Single library, specific topic. Return the relevant API surface, parameters, and a code example.

```
/docs next.js app router
/docs drizzle orm migrations
```

### DEEP DIVE
Single library, broad topic or no topic. Return a comprehensive overview: core APIs, patterns, gotchas, version-specific behavior.

```
/docs supabase rls policies
/docs react server components
```

### COMPARISON
Two libraries separated by `vs`. Fetch docs for both and compare API surfaces, patterns, and tradeoffs.

```
/docs drizzle vs prisma migrations
/docs zustand vs jotai state management
```

## Process

1. **Parse arguments** — Extract library name(s) and optional topic from the user's input.

2. **Resolve library** — Call Context7 `resolve-library-id` for each library name. If resolution fails, tell the user and suggest corrections.

3. **Fetch docs** — Call Context7 `query-docs` with the resolved library ID and topic. Request enough tokens for useful context (aim for 5000–10000 tokens).

4. **Summarize** — Present a concise, actionable summary:
   - **Version** — what version the docs cover
   - **Key APIs** — function signatures, parameters, return types
   - **Code example** — working snippet from the docs, not invented
   - **Gotchas** — common mistakes, breaking changes, deprecated patterns
   - **Links** — point to official docs for deeper reading

5. **Comparison mode** — If two libraries, present side-by-side: API differences, migration path differences, bundle size, ecosystem maturity.

## Output Format

Keep it concise and scannable. Lead with what the user needs to write code, not background context. Use code blocks for examples. Flag anything version-sensitive or recently changed.

## Cross-Skill Integration

This skill pairs naturally with other craft-cli skills:

- **`/think`** — Fetch docs before designing with a library. Know the real API surface before committing to an architecture.
- **`/debug`** — When root cause involves API misunderstanding, fetch docs to verify assumptions about how the API actually works.
- **`/ship`** — During review phase, verify that code uses current API patterns and hasn't drifted to deprecated usage.

## When to auto-invoke

Trigger when:
- User asks "how does X work" about a library or framework
- User is about to implement against an unfamiliar API
- Code uses deprecated patterns or APIs that have known replacements
- User is choosing between libraries and needs current API comparison

Don't trigger for:
- Standard language features (vanilla JS/TS, Python stdlib)
- APIs the user is clearly already fluent with
- Internal project code (not a public library)

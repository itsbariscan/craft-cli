---
name: qa
description: Use when testing a live URL, checking a deployed site, or the user wants to verify a web page works correctly.
argument-hint: "[mode] [url]"
disable-model-invocation: false
---

# /qa — QA Testing via Chrome DevTools MCP

Test a live URL using Chrome DevTools MCP tools.

## Usage

```
/qa <url>              # Full test
/qa quick <url>        # Quick smoke test
/qa regression <url>   # Compare against baseline
```

Parse the URL and mode from `$ARGUMENTS`. If `$ARGUMENTS` contains only a URL, default to full test mode. If it starts with `quick` or `regression`, use that mode with the remaining argument as the URL.

## Tools Available

Use these Chrome DevTools MCP tools:
- `navigate_page` — Load the URL
- `take_screenshot` — Visual evidence (mandatory per issue)
- `click`, `fill`, `press_key` — Interact with elements
- `list_console_messages` — Check for errors/warnings
- `take_snapshot` — DOM snapshot
- `lighthouse_audit` — Performance, accessibility, SEO, best practices scores
- `list_network_requests` — Check for failed requests
- `evaluate_script` — Run JS checks in page context

## Three Modes

### Full Test
1. Navigate to URL
2. Take initial screenshot
3. Run Lighthouse audit
4. Check console for errors/warnings
5. Check network for failed requests
6. Test all interactive elements (forms, buttons, links)
7. Test responsive breakpoints (mobile: 375px, tablet: 768px, desktop: 1280px)
8. Check accessibility (tab order, ARIA, contrast via Lighthouse)
9. Verify content (headings, images, links)
10. Generate health score and report

### Quick Test
1. Navigate + screenshot
2. Console errors check
3. Lighthouse audit
4. Network failures check
5. Generate health score

### Regression Test
1. Load baseline from `.qa-reports/[domain]-baseline.json`. If no baseline exists, the first run creates one — run a full test and save the results as the initial baseline.
2. Run full test
3. Compare scores against baseline
4. Flag any regressions (score drops > 5 points)
5. Update baseline if all checks pass

## Health Score (0-100)

| Category      | Weight | What's checked                              |
|---------------|--------|---------------------------------------------|
| Console       | 15%    | Errors (critical), warnings (minor)         |
| Links         | 10%    | Broken links, 404s in network               |
| Visual        | 10%    | Layout breaks, overflow, missing images     |
| Functional    | 20%    | Forms submit, buttons respond, nav works    |
| UX            | 15%    | Loading states, error states, empty states  |
| Performance   | 10%    | LCP < 2.5s, CLS < 0.1, INP < 200ms        |
| Content       | 5%     | Headings hierarchy, alt text, meta tags     |
| Accessibility | 15%    | Lighthouse a11y score, keyboard nav, ARIA   |

**Scoring:** Start at 100, deduct per issue based on severity:
- Critical: -15 per issue
- Major: -8 per issue
- Minor: -3 per issue
- Info: -0 (noted only)

## Per Issue Requirements

Every issue must include:
1. **Screenshot** — visual evidence (use `take_screenshot`)
2. **Severity** — Critical / Major / Minor / Info
3. **Category** — From taxonomy (see [issue-taxonomy](references/issue-taxonomy.md))
4. **Description** — What's wrong
5. **Repro steps** — How to trigger
6. **Expected vs actual** — What should happen vs what does

## Output

Save report to `.qa-reports/[domain]-[date].md` with:
- Health score breakdown
- Issue list (grouped by severity)
- Lighthouse scores (Performance, Accessibility, Best Practices, SEO)
- Screenshots referenced inline
- Regression comparison (if baseline exists)

Save baseline to `.qa-reports/[domain]-baseline.json` with scores for regression tracking.

## Context Passing

After QA completes, save a summary to `.craft/context/qa-report.md` with:
- URL tested
- Health score
- Critical/major issues found
- Lighthouse scores

**Next step:** If issues found → recommend `/debug` to investigate. If clean → report the health score and close the loop.

## When to auto-invoke

Suggest QA testing when:
- A deployment or build completes
- User mentions testing a live site
- After shipping changes to a domain

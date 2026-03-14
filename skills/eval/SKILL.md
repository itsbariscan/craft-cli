---
name: eval
description: Use when evaluating LLM output quality, auditing eval pipelines, designing judges, or analyzing failure modes.
argument-hint: "[mode] [args]"
disable-model-invocation: true
---

# /eval — Evaluation Workflow

Build, validate, and run LLM evaluations using rigorous methodology.

Parse the mode from `$ARGUMENTS`. The first argument (`$0`) selects the mode: `audit`, `analyze`, `judge`, `validate`, `run`, `rag`, or `synthetic`. Remaining arguments are mode-specific.

## Modes

### `/eval audit`
Audit existing eval infrastructure. Check 6 diagnostic areas:

1. **Error analysis** — Has anyone systematically read traces and categorized failures? If not, evals are built on assumptions.
2. **Judge validation** — Are LLM judges calibrated against human labels? What's their TPR/TNR? Unvalidated judges are opinions, not measurements.
3. **Metric quality** — Are metrics binary (Pass/Fail) or continuous? Continuous metrics hide failure modes. Are there vanity metrics (high pass rate but useless criteria)?
4. **Data quality** — How were eval datasets built? Synthetic only? Biased sample? How many examples? < 50 is unreliable.
5. **Coverage** — What failure modes have evals? What failure modes don't? Map the gaps.
6. **Freshness** — When were evals last updated? Do they reflect current pipeline behavior or a past version?

Output: diagnostic report with severity per area (Red/Yellow/Green) and recommended next steps.

### `/eval analyze`
Systematic error analysis on traces:

1. Collect 20-50 representative traces (successes and failures)
2. Read each trace carefully — input, output, expected output
3. For each failure, write a one-line description of what went wrong
4. Group failures into categories — let categories emerge from observation, not brainstorming
5. Count frequency per category
6. Rank by frequency and severity
7. For top 3 categories: define what "Pass" and "Fail" look like (concrete, observable)

Output: ranked failure taxonomy with example traces per category.

### `/eval judge <criterion>`
Design a binary Pass/Fail LLM judge for a specific criterion:

**4 required components:**
1. **Task** — What ONE failure mode this judge checks
2. **Definitions** — Concrete, observable definitions of Pass and Fail
3. **Examples** — 2-4 labeled examples, including at least one borderline case
4. **Output format** — `{"critique": "...", "result": "Pass|Fail"}`

Use the judge template: [judge-template](references/judge-template.md)

After designing: validate with `/eval validate` before trusting.

### `/eval validate`
Validate an LLM judge against human-labeled data:

1. Collect 20-50 examples with human labels (Pass/Fail)
2. Run the judge against each example
3. Calculate True Positive Rate (TPR) and True Negative Rate (TNR)
4. **Target:** TPR > 90% and TNR > 90%
5. If below target: analyze disagreements, refine judge definitions and examples, re-validate
6. Report confusion matrix: TP, FP, TN, FN counts and rates

A judge with TPR/TNR below 80% is unreliable — redesign rather than calibrate.

### `/eval run`
Execute existing judges against a dataset:

1. Load judge prompts and test data
2. Run each judge against each example
3. Calculate pass rates with 95% confidence intervals
4. Apply Rogan-Gladen bias correction if TPR/TNR are known
5. Compare against baseline if available
6. Report results with per-criterion breakdown

See methodology: [methodology](references/methodology.md)

### `/eval rag`
Evaluate RAG pipeline by separating retrieval from generation:

**Retrieval metrics:**
- Recall@k — Does the relevant chunk appear in top-k results?
- Precision@k — What fraction of retrieved chunks are relevant?
- MRR — Mean reciprocal rank of first relevant result

**Generation metrics:**
- Faithfulness — Is the answer supported by retrieved context? (No hallucination)
- Relevance — Does the answer address the question?
- Completeness — Does the answer cover all aspects from the context?

Evaluate retrieval and generation independently. A bad answer could be a retrieval problem or a generation problem — the fix is different.

### `/eval synthetic`
Generate synthetic test data when real data is sparse:

1. Identify dimensions that vary in real usage (topic, length, complexity, edge cases)
2. Create dimension tuples — combinations of dimension values
3. Generate one example per tuple
4. Validate that synthetic examples are realistic
5. Label with expected outputs

Use dimension-based generation, not random generation. Each example should test a specific combination.

## Core Principles

- **Binary judges over continuous scores** — Pass/Fail forces clear definitions. "3.7 out of 5" is meaningless.
- **Error analysis before judge design** — You can't evaluate what you haven't observed.
- **Validate judges before trusting** — TPR/TNR > 90% on held-out human-labeled data.
- **Confidence intervals on everything** — A pass rate without CI is a guess.
- **Separate retrieval from generation** — In RAG, these are different systems with different failure modes.

## Dashboard Mode

When invoked as `/eval dashboard`, generate a markdown summary of all recent eval runs:
- Per-criterion pass rates with trend arrows (↑↓→)
- Regressions highlighted in bold
- Last run date per criterion
- Overall health assessment

Read eval results from `.eval-results/` directory if it exists.

## Context Passing

After `/eval run`, save results to `.craft/context/eval.md` with YAML frontmatter:

```markdown
---
skill: eval
mode: audit|analyze|judge|validate|run|rag|synthetic
overall_pass_rate: <number>
has_regressions: true|false
criterion_count: <number>
timestamp: YYYY-MM-DD
---

[Full prose: per-criterion pass rates and CIs, regressions, overall assessment]
```

This artifact is consumed by `/ship` — frontmatter `has_regressions` gates step 5. If `true`, ship blocks until investigated.

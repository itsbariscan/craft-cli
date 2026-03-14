# Evaluation Methodology Reference

## Error Analysis: 7-Step Workflow

1. **Sample traces** — Pull 20-50 representative examples. Include both successes and failures. Stratify by source if possible.
2. **Read carefully** — For each trace: read the full input, the full output, and the expected output. Don't skim.
3. **Describe failures** — Write a one-line description of what went wrong. Be specific: "hallucinated a statistic" not "bad output."
4. **Categorize** — Group similar failures. Let categories emerge from the data. Don't start with a taxonomy.
5. **Count** — Tally frequency per category. This is your priority list.
6. **Define criteria** — For the top 3 categories, write concrete Pass/Fail definitions.
7. **Build judges** — One judge per criterion. Validate each.

## Binary Judge Design: 4 Components

Every LLM judge must have:

### 1. Task Statement
One sentence: what failure mode does this judge detect?
- Good: "Detect when the model fabricates statistics not present in the source material"
- Bad: "Check if the output is good"

### 2. Pass/Fail Definitions
Observable, concrete, no judgment calls:
- Pass: "All numerical claims in the output appear verbatim in the provided source"
- Fail: "One or more numerical claims do not appear in the provided source"

### 3. Few-Shot Examples
2-4 labeled examples:
- At least one clear Pass
- At least one clear Fail
- At least one borderline case (this calibrates the boundary)

Format each as: Input → Output → Label → Explanation

### 4. Output Format
```json
{
  "critique": "Brief explanation of the judgment",
  "result": "Pass|Fail"
}
```
Always require critique before result (chain-of-thought improves accuracy).

## TPR/TNR Validation Protocol

### Data Splits
- **Train** (40%) — Used to develop the judge prompt. You can look at these.
- **Dev** (20%) — Used to tune the judge. Run after changes, check metrics.
- **Test** (40%) — Held out. Run ONCE for final validation. Never tune on this.

### Metrics
- **TPR (True Positive Rate)** — Of actual Passes, what fraction does the judge call Pass?
- **TNR (True Negative Rate)** — Of actual Fails, what fraction does the judge call Fail?
- **Target:** Both TPR and TNR > 90%

### Validation Loop
1. Label 50+ examples with human judgments (the ground truth)
2. Split into train/dev/test
3. Run judge on dev set
4. If TPR or TNR < 90%: examine failures, refine prompt, re-run on dev
5. When dev metrics satisfy: run once on test set
6. Report test set metrics as final numbers

## Rogan-Gladen Bias Correction

When you know a judge's TPR and TNR, correct the raw pass rate:

```
corrected_rate = (raw_rate + TNR - 1) / (TPR + TNR - 1)
```

Example: Raw pass rate = 0.80, TPR = 0.95, TNR = 0.90
```
corrected = (0.80 + 0.90 - 1) / (0.95 + 0.90 - 1) = 0.70 / 0.85 = 0.824
```

Always report both raw and corrected rates.

## Confidence Intervals

For pass rates, use the Wilson score interval (better than normal approximation for small n):

```
p = passes / n
z = 1.96 (for 95% CI)
denominator = 1 + z²/n
center = (p + z²/(2n)) / denominator
spread = z * sqrt((p*(1-p) + z²/(4n)) / n) / denominator
CI = [center - spread, center + spread]
```

Always report: `pass_rate (95% CI: [lower, upper], n=XX)`

## RAG Decomposition

Evaluate retrieval and generation independently:

### Retrieval
- Build a set of (query, relevant_chunks) pairs
- Run retrieval, measure Recall@k and Precision@k
- If retrieval is bad, fix retrieval before touching generation

### Generation
- Given perfect retrieval (provide correct chunks), evaluate generation
- Faithfulness: does the answer stay within the provided context?
- Relevance: does the answer address the question?
- Completeness: does the answer cover all relevant information from context?

### End-to-End
- Only after retrieval and generation are independently good
- Run full pipeline, measure answer quality
- If quality drops, you know where to look

## Synthetic Data via Dimension Tuples

1. **Identify dimensions** that vary in real usage:
   - Topic/domain
   - Complexity (simple, moderate, complex)
   - Length (short, medium, long)
   - Edge cases (empty input, special characters, ambiguous query)
   - User intent (informational, navigational, transactional)

2. **Create tuples** — combinations of dimension values:
   ```
   (health, simple, short, normal, informational)
   (finance, complex, long, edge_case, transactional)
   ```

3. **Generate one example per tuple** — each tests a specific combination

4. **Validate** — check that synthetic examples are realistic and cover the space

## Eval Audit: 6-Area Diagnostic

| Area            | Green                    | Yellow                      | Red                          |
|-----------------|--------------------------|-----------------------------|-----------------------------|
| Error Analysis  | Done, < 30 days old      | Done, > 30 days old         | Never done                  |
| Judge Validation| TPR/TNR > 90%            | Validated but < 90%         | Unvalidated                 |
| Metric Quality  | Binary, well-defined     | Mix of binary + continuous  | Only continuous/vanity       |
| Data Quality    | 100+ real examples       | 50-99 or synthetic-heavy    | < 50 or unknown source      |
| Coverage        | All known failure modes  | Some gaps identified        | No failure mode mapping     |
| Freshness       | Updated with pipeline    | > 1 month stale             | > 3 months or never updated |

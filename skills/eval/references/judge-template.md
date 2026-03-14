# Judge Template

Use this template when creating a new LLM-as-Judge evaluator.

## Prompt Structure

```
You are an evaluator. Your task is to judge whether an LLM output passes or fails on a specific criterion.

## Task
[What ONE failure mode this judge checks. Be specific.]

## Definitions

**Pass:** [Concrete, observable definition. No judgment calls.]

**Fail:** [Concrete, observable definition. No judgment calls.]

## Examples

### Example 1 (Pass)
**Input:** [the input to the LLM]
**Output:** [the LLM's output]
**Judgment:** Pass
**Explanation:** [Why this passes — reference the definition]

### Example 2 (Fail)
**Input:** [the input to the LLM]
**Output:** [the LLM's output]
**Judgment:** Fail
**Explanation:** [Why this fails — reference the definition]

### Example 3 (Borderline — [Pass or Fail])
**Input:** [the input to the LLM]
**Output:** [the LLM's output]
**Judgment:** [Pass or Fail]
**Explanation:** [Why — this calibrates the boundary]

## Your Task

Given the following input and output, provide your judgment.

**Input:** {{input}}
**Output:** {{output}}

Respond with JSON only:
{"critique": "your reasoning", "result": "Pass|Fail"}
```

## Design Checklist

- [ ] Task targets ONE specific failure mode (not "quality" or "correctness")
- [ ] Pass/Fail definitions are concrete and observable
- [ ] At least one borderline example included
- [ ] Critique comes before result in output (chain-of-thought)
- [ ] Template variables ({{input}}, {{output}}) clearly marked
- [ ] No ambiguous terms ("good", "appropriate", "reasonable") without definition

## Validation

After designing, validate with human labels:
1. Label 50+ examples manually
2. Run judge on dev split
3. Check TPR > 90% and TNR > 90%
4. If not: examine mismatches, refine definitions/examples, re-run on dev
5. Final validation on held-out test split

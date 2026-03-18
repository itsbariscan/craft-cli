#!/usr/bin/env python3
"""Run an LLM judge against a JSONL dataset and report pass rates with confidence intervals.

Usage:
    python3 run-judge.py <judge_prompt_file> <dataset.jsonl> [--baseline baseline.json] [--output results.json]

Dataset format (JSONL, one per line):
    {"input": "...", "output": "...", "expected": "Pass|Fail"}  # expected is optional (for validation)

Judge prompt file:
    A text file containing the judge prompt with {{input}} and {{output}} placeholders.

Output (JSON):
    {
        "total": 100,
        "passes": 80,
        "pass_rate": 0.80,
        "ci_lower": 0.71,
        "ci_upper": 0.87,
        "results": [{"input": "...", "output": "...", "judgment": "Pass|Fail", "critique": "..."}],
        "validation": {"tpr": 0.95, "tnr": 0.90, ...}  # if expected labels present
    }

Note: This script prepares the dataset and generates the commands/structure for running
judges. The actual LLM calls should be made by Claude using the prepared prompts.
Run this script to validate dataset format, split data, and compute metrics on results.
"""

import argparse
import json
import math
import sys
from pathlib import Path


def wilson_interval(passes: int, total: int, z: float = 1.96) -> tuple[float, float, float]:
    if total == 0:
        return 0.0, 0.0, 0.0
    p = passes / total
    denominator = 1 + z * z / total
    center = (p + z * z / (2 * total)) / denominator
    spread = z * math.sqrt((p * (1 - p) + z * z / (4 * total)) / total) / denominator
    return p, max(0.0, center - spread), min(1.0, center + spread)


def load_dataset(path: str) -> list[dict]:
    examples = []
    with open(path) as f:
        for i, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                print(f"Warning: skipping invalid JSON on line {i}", file=sys.stderr)
                continue
            if "input" not in obj or "output" not in obj:
                print(f"Warning: line {i} missing 'input' or 'output' field", file=sys.stderr)
                continue
            examples.append(obj)
    return examples


def load_results(path: str) -> list[dict]:
    """Load judge results JSONL (after Claude has run the judge)."""
    return load_dataset(path)


def compute_validation_metrics(results: list[dict]) -> dict:
    """Compute TPR/TNR if expected labels are present."""
    tp = fp = tn = fn = 0
    for r in results:
        expected = r.get("expected", "").strip()
        judgment = r.get("judgment", "").strip()
        if not expected or not judgment:
            continue
        if expected == "Pass" and judgment == "Pass":
            tp += 1
        elif expected == "Pass" and judgment == "Fail":
            fn += 1
        elif expected == "Fail" and judgment == "Fail":
            tn += 1
        elif expected == "Fail" and judgment == "Pass":
            fp += 1

    total_pos = tp + fn
    total_neg = tn + fp
    tpr = tp / total_pos if total_pos > 0 else 0.0
    tnr = tn / total_neg if total_neg > 0 else 0.0

    return {
        "tp": tp, "fp": fp, "tn": tn, "fn": fn,
        "tpr": round(tpr, 4),
        "tnr": round(tnr, 4),
        "total_positive": total_pos,
        "total_negative": total_neg,
        "meets_threshold": tpr >= 0.9 and tnr >= 0.9,
    }


def compute_pass_rate(results: list[dict]) -> dict:
    """Compute pass rate with Wilson CI."""
    total = len(results)
    passes = sum(1 for r in results if r.get("judgment", "").strip() == "Pass")
    p, lower, upper = wilson_interval(passes, total)
    return {
        "total": total,
        "passes": passes,
        "pass_rate": round(p, 4),
        "ci_lower": round(lower, 4),
        "ci_upper": round(upper, 4),
    }


def compare_baseline(current: dict, baseline_path: str) -> dict:
    """Compare current results against a baseline."""
    with open(baseline_path) as f:
        baseline = json.load(f)
    delta = current["pass_rate"] - baseline.get("pass_rate", 0)
    regression = delta < -0.05  # >5 point drop
    return {
        "baseline_pass_rate": baseline.get("pass_rate", 0),
        "current_pass_rate": current["pass_rate"],
        "delta": round(delta, 4),
        "is_regression": regression,
    }


def cmd_validate(args):
    """Validate dataset format and report stats."""
    examples = load_dataset(args.dataset)
    has_labels = sum(1 for e in examples if "expected" in e)
    print(json.dumps({
        "valid": True,
        "total_examples": len(examples),
        "labeled_examples": has_labels,
        "unlabeled_examples": len(examples) - has_labels,
        "fields": list(examples[0].keys()) if examples else [],
    }, indent=2))


def cmd_prepare(args):
    """Prepare judge prompts for each example (Claude runs the actual calls)."""
    examples = load_dataset(args.dataset)
    prompt_template = Path(args.judge_prompt).read_text()

    prepared = []
    for i, ex in enumerate(examples):
        prompt = prompt_template.replace("{{input}}", ex["input"]).replace("{{output}}", ex["output"])
        prepared.append({
            "index": i,
            "prompt": prompt,
            "input": ex["input"],
            "output": ex["output"],
            "expected": ex.get("expected"),
        })

    output_path = args.output or "prepared-judge-runs.jsonl"
    with open(output_path, "w") as f:
        for p in prepared:
            f.write(json.dumps(p) + "\n")

    print(json.dumps({
        "prepared": len(prepared),
        "output_file": output_path,
        "message": f"Run each prompt through the judge LLM, add 'judgment' and 'critique' fields, save as results JSONL.",
    }, indent=2))


def cmd_score(args):
    """Score completed judge results."""
    results = load_results(args.results)
    metrics = compute_pass_rate(results)

    has_labels = any("expected" in r for r in results)
    if has_labels:
        metrics["validation"] = compute_validation_metrics(results)

    if args.baseline:
        metrics["comparison"] = compare_baseline(metrics, args.baseline)

    print(json.dumps(metrics, indent=2))

    if args.output:
        with open(args.output, "w") as f:
            json.dump(metrics, f, indent=2)


def main():
    parser = argparse.ArgumentParser(description="LLM Judge runner for eval workflows")
    sub = parser.add_subparsers(dest="command", required=True)

    p_validate = sub.add_parser("validate", help="Validate dataset format")
    p_validate.add_argument("dataset", help="Path to JSONL dataset")

    p_prepare = sub.add_parser("prepare", help="Prepare judge prompts from template + dataset")
    p_prepare.add_argument("judge_prompt", help="Path to judge prompt template")
    p_prepare.add_argument("dataset", help="Path to JSONL dataset")
    p_prepare.add_argument("--output", help="Output path for prepared runs")

    p_score = sub.add_parser("score", help="Score completed judge results")
    p_score.add_argument("results", help="Path to results JSONL")
    p_score.add_argument("--baseline", help="Path to baseline JSON for comparison")
    p_score.add_argument("--output", help="Save metrics to file")

    args = parser.parse_args()
    {"validate": cmd_validate, "prepare": cmd_prepare, "score": cmd_score}[args.command](args)


if __name__ == "__main__":
    main()

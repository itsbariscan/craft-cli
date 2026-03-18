#!/usr/bin/env python3
"""Wilson score confidence interval with optional Rogan-Gladen bias correction.

Usage:
    python3 wilson-interval.py <passes> <total> [--confidence 0.95] [--tpr 0.95 --tnr 0.90]

Examples:
    python3 wilson-interval.py 80 100
    python3 wilson-interval.py 80 100 --confidence 0.99
    python3 wilson-interval.py 80 100 --tpr 0.95 --tnr 0.90

Output (JSON):
    {"pass_rate": 0.80, "ci_lower": 0.71, "ci_upper": 0.87, "n": 100, "confidence": 0.95}
    With --tpr/--tnr: adds "corrected_rate", "corrected_ci_lower", "corrected_ci_upper"
"""

import argparse
import json
import math
import sys

Z_VALUES = {0.90: 1.645, 0.95: 1.96, 0.99: 2.576}


def wilson_interval(passes: int, total: int, z: float) -> tuple[float, float, float]:
    if total == 0:
        return 0.0, 0.0, 0.0
    p = passes / total
    denominator = 1 + z * z / total
    center = (p + z * z / (2 * total)) / denominator
    spread = z * math.sqrt((p * (1 - p) + z * z / (4 * total)) / total) / denominator
    return p, max(0.0, center - spread), min(1.0, center + spread)


def rogan_gladen(rate: float, tpr: float, tnr: float) -> float:
    denominator = tpr + tnr - 1
    if abs(denominator) < 1e-9:
        return rate
    return max(0.0, min(1.0, (rate + tnr - 1) / denominator))


def main():
    parser = argparse.ArgumentParser(description="Wilson score interval calculator")
    parser.add_argument("passes", type=int, help="Number of passes")
    parser.add_argument("total", type=int, help="Total number of examples")
    parser.add_argument("--confidence", type=float, default=0.95, help="Confidence level (default: 0.95)")
    parser.add_argument("--tpr", type=float, default=None, help="True Positive Rate for bias correction")
    parser.add_argument("--tnr", type=float, default=None, help="True Negative Rate for bias correction")
    args = parser.parse_args()

    if args.total <= 0:
        print(json.dumps({"error": "total must be positive"}))
        sys.exit(1)
    if args.passes < 0 or args.passes > args.total:
        print(json.dumps({"error": "passes must be between 0 and total"}))
        sys.exit(1)

    z = Z_VALUES.get(args.confidence)
    if z is None:
        z = args.confidence  # Allow raw z-value passthrough
        for conf, zval in Z_VALUES.items():
            if abs(conf - args.confidence) < 0.001:
                z = zval
                break

    p, lower, upper = wilson_interval(args.passes, args.total, z)

    result = {
        "pass_rate": round(p, 4),
        "ci_lower": round(lower, 4),
        "ci_upper": round(upper, 4),
        "n": args.total,
        "confidence": args.confidence,
    }

    if args.tpr is not None and args.tnr is not None:
        result["corrected_rate"] = round(rogan_gladen(p, args.tpr, args.tnr), 4)
        result["corrected_ci_lower"] = round(rogan_gladen(lower, args.tpr, args.tnr), 4)
        result["corrected_ci_upper"] = round(rogan_gladen(upper, args.tpr, args.tnr), 4)

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()

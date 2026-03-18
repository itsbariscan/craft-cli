#!/usr/bin/env bash
# Compare two screenshots and output a diff image + similarity score.
#
# Usage:
#   ./screenshot-diff.sh <baseline.png> <current.png> [diff-output.png]
#
# Requires: ImageMagick (brew install imagemagick)
#
# Output (JSON):
#   {"identical": false, "difference_score": 0.0234, "diff_image": "diff-output.png", "pixel_count": 1234}
#
# difference_score: 0.0 = identical, 1.0 = completely different
# Values below 0.01 are typically imperceptible visual differences.

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo '{"error": "Usage: screenshot-diff.sh <baseline.png> <current.png> [diff-output.png]"}'
  exit 1
fi

BASELINE="$1"
CURRENT="$2"
DIFF_OUTPUT="${3:-diff-$(date +%Y%m%d-%H%M%S).png}"

# Check dependencies
if ! command -v compare &>/dev/null; then
  echo '{"error": "ImageMagick not found. Install with: brew install imagemagick"}'
  exit 1
fi

# Check files exist
for f in "$BASELINE" "$CURRENT"; do
  if [[ ! -f "$f" ]]; then
    echo "{\"error\": \"File not found: $f\"}"
    exit 1
  fi
done

# Run comparison — metric outputs to stderr, diff image to file
# AE = Absolute Error (pixel count), RMSE for normalized score
PIXEL_DIFF=$(compare -metric AE "$BASELINE" "$CURRENT" "$DIFF_OUTPUT" 2>&1 || true)
RMSE=$(compare -metric RMSE "$BASELINE" "$CURRENT" null: 2>&1 || true)

# Parse RMSE — format is "1234.56 (0.0234)" — we want the normalized value in parens
NORMALIZED=$(echo "$RMSE" | grep -o '([0-9.]*)'  | tr -d '()' || echo "0")

if [[ -z "$NORMALIZED" ]]; then
  NORMALIZED="0"
fi

# Clean pixel count (remove any parenthetical)
PIXEL_COUNT=$(echo "$PIXEL_DIFF" | grep -o '^[0-9]*' || echo "0")

IDENTICAL="false"
if [[ "$PIXEL_COUNT" == "0" ]]; then
  IDENTICAL="true"
fi

cat <<EOF
{"identical": $IDENTICAL, "difference_score": $NORMALIZED, "diff_image": "$DIFF_OUTPUT", "pixel_count": $PIXEL_COUNT}
EOF

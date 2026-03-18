#!/usr/bin/env bash
# Logs skill invocations to ${CLAUDE_PLUGIN_DATA}/usage.log
# Non-blocking: always exits 0 so it never interrupts the user.

set -euo pipefail

# Only log Skill tool invocations
TOOL_NAME="${TOOL_NAME:-}"
if [[ "$TOOL_NAME" != "Skill" ]]; then
  exit 0
fi

# Determine stable storage directory
DATA_DIR="${CLAUDE_PLUGIN_DATA:-${HOME}/.craft/data}"
mkdir -p "$DATA_DIR"

LOG_FILE="$DATA_DIR/usage.log"

# Extract skill name from tool input JSON (stdin)
SKILL_NAME=""
if command -v jq &>/dev/null; then
  SKILL_NAME=$(cat | jq -r '.skill // "unknown"' 2>/dev/null || echo "unknown")
else
  # Fallback: simple grep for skill field
  SKILL_NAME=$(cat | grep -o '"skill"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"skill"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "unknown")
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
PROJECT_DIR=$(pwd)

echo "${TIMESTAMP} | ${SKILL_NAME} | ${PROJECT_DIR}" >> "$LOG_FILE"

exit 0

#!/bin/bash
# Pre-commit validation — type check + lint before any commit
# Event: PreToolUse | Matcher: Bash
# Exit 2 to block if checks fail

# Read tool input from stdin (JSON)
input=$(cat)

# Extract the command from the JSON input
command=$(echo "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('command', ''))
except:
    pass
" 2>/dev/null)

# Only run if the bash command contains "git commit"
if [[ "$command" != *"git commit"* ]]; then
  exit 0
fi

errors=""

# TypeScript type check
if [ -f "tsconfig.json" ]; then
  echo "Running type check..."
  if command -v npx &>/dev/null; then
    tsc_output=$(npx tsc --noEmit 2>&1)
    if [ $? -ne 0 ]; then
      errors="TYPE CHECK FAILED:\n$tsc_output\n\n"
    fi
  fi
fi

# Lint check
if [ -f "package.json" ]; then
  if node -e "const p = require('./package.json'); process.exit(p.scripts && p.scripts.lint ? 0 : 1)" 2>/dev/null; then
    echo "Running lint..."
    lint_output=$(npm run lint 2>&1)
    if [ $? -ne 0 ]; then
      errors="${errors}LINT FAILED:\n$lint_output\n\n"
    fi
  fi
fi

if [ -n "$errors" ]; then
  echo -e "COMMIT BLOCKED:\n$errors"
  echo "Fix these issues before committing."
  exit 2
fi

exit 0

#!/bin/bash
# Completion verifier — checks modified files for quality before Claude stops
# Event: Stop | Type: agent
# Exit 2 to block premature completion

errors=""

# Get list of modified files (staged + unstaged)
# Check if we're in a git repo with at least one commit
if ! git rev-parse --verify HEAD &>/dev/null; then
  exit 0
fi

modified_files=$(git diff --name-only HEAD 2>/dev/null; git diff --name-only --cached 2>/dev/null)
modified_files=$(echo "$modified_files" | sort -u | grep -v '^$')

if [ -z "$modified_files" ]; then
  exit 0
fi

for file in $modified_files; do
  # Skip non-existent files (deleted)
  [ -f "$file" ] || continue

  # Only check TypeScript/JavaScript files
  case "$file" in
    *.ts|*.tsx|*.js|*.jsx)
      # Check for `any` type usage
      any_matches=$(grep -n '\bany\b' "$file" | grep -v '// eslint-disable' | grep -v 'eslint-disable-next-line' | head -5)
      if [ -n "$any_matches" ]; then
        errors="${errors}$file has 'any' types:\n$any_matches\n\n"
      fi

      # Check for console.log
      console_matches=$(grep -n 'console\.log' "$file" | head -5)
      if [ -n "$console_matches" ]; then
        errors="${errors}$file has console.log:\n$console_matches\n\n"
      fi
      ;;
  esac
done

# TypeScript errors on modified .ts/.tsx files
ts_files=$(echo "$modified_files" | grep -E '\.(ts|tsx)$' | tr '\n' ' ')
if [ -n "$ts_files" ] && [ -f "tsconfig.json" ]; then
  tsc_output=$(npx tsc --noEmit 2>&1)
  if [ $? -ne 0 ]; then
    # Filter to only show errors in modified files
    for file in $ts_files; do
      file_errors=$(echo "$tsc_output" | grep "^$file")
      if [ -n "$file_errors" ]; then
        errors="${errors}TypeScript errors in $file:\n$file_errors\n\n"
      fi
    done
  fi
fi

if [ -n "$errors" ]; then
  echo -e "COMPLETION BLOCKED — quality issues in modified files:\n\n$errors"
  echo "Fix these before finishing."
  exit 2
fi

exit 0

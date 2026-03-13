#!/bin/bash
# Session context loader — loads git context at session start
# Event: SessionStart

echo "=== Session Context ==="

# Current branch
branch=$(git branch --show-current 2>/dev/null)
if [ -n "$branch" ]; then
  echo "Branch: $branch"
else
  echo "Branch: (detached HEAD or not a git repo)"
fi

# Recent commits (last 5)
echo ""
echo "Recent commits:"
git log --oneline -5 2>/dev/null || echo "(no git history)"

# Uncommitted changes
echo ""
changes=$(git status --porcelain 2>/dev/null)
if [ -n "$changes" ]; then
  echo "Uncommitted changes:"
  echo "$changes"
else
  echo "Working tree: clean"
fi

# Open PR for current branch
if command -v gh &>/dev/null && [ -n "$branch" ] && [ "$branch" != "main" ] && [ "$branch" != "master" ]; then
  echo ""
  pr_info=$(gh pr view --json title,state,url 2>/dev/null)
  if [ $? -eq 0 ]; then
    echo "Open PR: $(echo "$pr_info" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'{d[\"title\"]} ({d[\"state\"]}) — {d[\"url\"]}')" 2>/dev/null)"
  fi
fi

echo "=== End Context ==="
exit 0

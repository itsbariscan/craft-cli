#!/bin/bash
# Session context loader — loads git context + craft-cli workflow rules at session start
# Event: SessionStart
# Uses additionalContext to inject workflow rules into every session

# Collect git context
git_context="=== Session Context ==="

branch=$(git branch --show-current 2>/dev/null)
if [ -n "$branch" ]; then
  git_context="$git_context
Branch: $branch"
else
  git_context="$git_context
Branch: (detached HEAD or not a git repo)"
fi

git_context="$git_context

Recent commits:"
commits=$(git log --oneline -5 2>/dev/null)
if [ -n "$commits" ]; then
  git_context="$git_context
$commits"
else
  git_context="$git_context
(no git history)"
fi

changes=$(git status --porcelain 2>/dev/null)
if [ -n "$changes" ]; then
  git_context="$git_context

Uncommitted changes:
$changes"
else
  git_context="$git_context

Working tree: clean"
fi

if command -v gh &>/dev/null && [ -n "$branch" ] && [ "$branch" != "main" ] && [ "$branch" != "master" ]; then
  pr_info=$(gh pr view --json title,state,url 2>/dev/null)
  if [ $? -eq 0 ]; then
    pr_title=$(echo "$pr_info" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'{d[\"title\"]} ({d[\"state\"]}) — {d[\"url\"]}')" 2>/dev/null)
    if [ -n "$pr_title" ]; then
      git_context="$git_context

Open PR: $pr_title"
    fi
  fi
fi

git_context="$git_context

=== End Context ==="

# Craft-cli workflow rules — injected via additionalContext so they're always in context
workflow_rules='craft-cli workflow rules (ALWAYS ACTIVE):

AUTO-TRIGGER: Invoke these skills automatically when conditions match — do not wait for slash commands:
- /scope: User says "I want to build...", "new feature:", or describes work with unclear boundaries
- /think: User describes a design problem, choosing between approaches, "how should we approach"
- /challenge: User says "poke holes", "what could go wrong", high conviction idea without scrutiny
- /plan: Design agreed, needs implementation steps
- /docs: User asks "how does X work" about a library, or about to use unfamiliar API
- /debug: Error appears, tests fail, user reports a bug
- /review: User says "review this", "check the code", implementation complete
- /ship: User says "ship it", "create a PR", "merge", "push"
- /qa: URL provided to test, deployment completed
- /eval: Prompt quality, LLM evaluation, judge design
- /remember: User says "remember this", "save this", or "have we seen this before"

SKILL CHAINING: After each skill completes, recommend the next:
- /scope → /think (with gear suggestion) or /plan (if trivial)
- /think → /challenge (stress-test) or /plan (low-risk)
- /challenge proceed → /plan | reconsider → /think
- /plan → implement step 1
- /debug → test-writer agent → /review
- /review clean → /ship | criticals → fix then re-review
- /ship → /qa <url>
- /qa → /debug (if issues) or close loop

CONTEXT PASSING: Skills share state via .craft/context/ with YAML frontmatter. Always check for upstream artifacts before asking users to repeat information. Key files: scope.md, design.md, challenge.md, plan.md, review.md, eval.md, postmortem.md, qa-report.md.

KNOWLEDGE SYSTEM: .craft/knowledge/ persists insights across sessions. /debug saves postmortems, /think saves decisions, /challenge saves risk patterns. Skills check knowledge before starting work. /remember for manual save/search.

VERIFICATION: Never claim "done" without fresh evidence (test output, build output, reproduction). See /verification for full protocol.'

# Output as JSON with additionalContext for reliable context injection
# Escape special characters for JSON
escaped_git=$(echo "$git_context" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null | sed 's/^"//;s/"$//')
escaped_rules=$(echo "$workflow_rules" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null | sed 's/^"//;s/"$//')

cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${escaped_git}\n\n${escaped_rules}"
  }
}
EOF

exit 0

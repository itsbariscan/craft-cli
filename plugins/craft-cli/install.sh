#!/bin/bash
# craft-cli installer
# Installs the plugin, appends workflow rules to CLAUDE.md, updates .gitignore
#
# Usage:
#   bash install.sh              Install everything
#   bash install.sh --update     Update workflow rules in CLAUDE.md (replace existing block)
#   bash install.sh --uninstall  Remove craft-cli rules from CLAUDE.md
#   bash install.sh --status     Check what's installed
#   bash install.sh --help       Show this help
#
# Safe: never overwrites existing CLAUDE.md content outside of markers.
# Idempotent: run it again and it skips steps that are already done.

set -e

CRAFT_MARKER="<!-- craft-cli:start -->"
CRAFT_END_MARKER="<!-- craft-cli:end -->"
CLAUDE_MD="./CLAUDE.md"
GITIGNORE="./.gitignore"
PLUGIN_NAME="itsbariscan/craft-cli"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
DIM='\033[2m'
NC='\033[0m'

# ─── Workflow rules block ────────────────────────────────────────────────────

WORKFLOW_RULES='<!-- craft-cli:start -->
# craft-cli workflow rules

## Auto-Trigger Rules

Invoke these skills automatically when conditions match. Do not wait for slash commands:

| Condition | Invoke |
|-----------|--------|
| User says "I want to build...", "new feature:", or describes work with unclear boundaries | `/scope` |
| User describes a design problem, says "how should we approach", or is choosing between approaches | `/think` |
| User says "poke holes", "what could go wrong", "play devil'\''s advocate", or presents idea with high conviction but no scrutiny | `/challenge` |
| A design is agreed upon and needs to become implementation steps | `/plan` |
| User asks "how does X work" about a library, or you'\''re about to use an unfamiliar API | `/docs` |
| An error appears, tests fail unexpectedly, user reports a bug | `/debug` |
| User says "review this", "check the code", or implementation is complete | `/review` |
| User says "ship it", "create a PR", "let'\''s merge", or "push this" | `/ship` |
| User provides a URL to test, or a deployment just completed | `/qa` |
| Discussion involves prompt quality, LLM output evaluation, or judge design | `/eval` |
| User says "remember this", "save this", or asks "have we seen this before" | `/remember` |

## Skill Chaining

After each skill completes, recommend the next:

- `/scope` → `/think` (with gear suggestion based on constraints) or `/plan` (if trivial)
- `/think` → `/challenge` (stress-test) or `/plan` (low-risk)
- `/challenge` proceed → `/plan` with mitigations | reconsider → back to `/think`
- `/plan` → implement step 1
- `/debug` → test-writer agent (regression test) → `/review`
- `/review` clean → `/ship` | criticals → fix then re-review
- `/ship` → `/qa <deployed-url>`
- `/qa` → `/debug` (if issues) or close loop

## Context Passing

Skills share state via `.craft/context/` with YAML frontmatter. Always check for upstream artifacts before asking users to repeat information:

| Skill | Writes | Read by |
|-------|--------|---------|
| `/scope` | `scope.md` | `/think`, `/plan`, `/challenge` |
| `/think` | `design.md` | `/challenge`, `/plan` |
| `/challenge` | `challenge.md` | `/plan` |
| `/plan` | `plan.md` | implementation |
| `/review` | `review.md` | `/ship` |
| `/eval` | `eval.md` | `/ship` |
| `/debug` | `postmortem.md` | `/review`, test-writer agent |
| `/qa` | `qa-report.md` | `/debug` |

Key frontmatter decisions:
- `/plan` reads `challenge.md` → if `verdict: reconsider`, warn before planning; if `proceed_with_mitigations`, add each mitigation as a plan step
- `/ship` reads `review.md` → if `status: has_criticals`, block merge
- `/ship` reads `eval.md` → if `has_regressions: true`, block merge
- `/think` reads `scope.md` → use `constraints` to calibrate gear recommendation

## Knowledge System

`.craft/knowledge/` persists insights across sessions:
- `/debug` auto-saves postmortems after `--postmortem`
- `/think` auto-saves design decisions after capturing ADRs
- `/challenge` auto-saves risk patterns when Fatal risks are found
- `/remember <what>` saves manually; `/remember search <terms>` retrieves
- Skills check knowledge before starting: `/debug` checks for past postmortems, `/think` for past decisions, `/challenge` for past risk patterns, `/review` for past bugs in affected files

## Verification

Never claim "done" without fresh evidence from the current session: test output, build output, or reproduction steps. See `/verification` for the full protocol.
<!-- craft-cli:end -->'

# ─── Helper functions ────────────────────────────────────────────────────────

print_header() {
  echo ""
  echo -e "  ${BLUE}craft-cli${NC} ${DIM}v3.0.0${NC}"
  echo -e "  ${DIM}developer workflow toolkit for Claude Code${NC}"
  echo ""
}

print_help() {
  print_header
  echo "  Usage:"
  echo "    bash install.sh              Install everything"
  echo "    bash install.sh --update     Update workflow rules in CLAUDE.md"
  echo "    bash install.sh --uninstall  Remove craft-cli rules from CLAUDE.md"
  echo "    bash install.sh --status     Check installation status"
  echo "    bash install.sh --help       Show this help"
  echo ""
  echo "  What it does:"
  echo "    1. Installs the Claude Code plugin"
  echo "    2. Appends workflow rules to your project's CLAUDE.md"
  echo "    3. Adds .craft/ to .gitignore"
  echo ""
  echo "  Safe by design:"
  echo "    - Never overwrites existing CLAUDE.md content"
  echo "    - Uses HTML markers for clean updates and removal"
  echo "    - Idempotent — run it again and it skips completed steps"
  echo ""
}

has_craft_rules() {
  [ -f "$CLAUDE_MD" ] && grep -q "$CRAFT_MARKER" "$CLAUDE_MD"
}

has_gitignore_entry() {
  [ -f "$GITIGNORE" ] && grep -q "\.craft/" "$GITIGNORE"
}

# ─── Commands ────────────────────────────────────────────────────────────────

do_status() {
  print_header
  echo "  Status:"
  echo ""

  # Plugin
  if command -v claude &>/dev/null; then
    if claude plugin list 2>/dev/null | grep -q "craft-cli"; then
      echo -e "    ${GREEN}●${NC}  Plugin installed"
    else
      echo -e "    ${RED}○${NC}  Plugin not installed"
    fi
  else
    echo -e "    ${YELLOW}○${NC}  Claude CLI not found"
  fi

  # CLAUDE.md rules
  if has_craft_rules; then
    echo -e "    ${GREEN}●${NC}  Workflow rules in CLAUDE.md"
  else
    echo -e "    ${RED}○${NC}  No workflow rules in CLAUDE.md"
  fi

  # .gitignore
  if has_gitignore_entry; then
    echo -e "    ${GREEN}●${NC}  .craft/ in .gitignore"
  else
    echo -e "    ${RED}○${NC}  .craft/ not in .gitignore"
  fi

  # Knowledge directory
  if [ -d ".craft/knowledge" ]; then
    count=$(find .craft/knowledge -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    echo -e "    ${GREEN}●${NC}  Knowledge directory ($count entries)"
  else
    echo -e "    ${DIM}○${NC}  No knowledge directory yet"
  fi

  echo ""
}

do_uninstall() {
  print_header

  if has_craft_rules; then
    # Remove the block between markers (inclusive)
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "/$CRAFT_MARKER/,/$CRAFT_END_MARKER/d" "$CLAUDE_MD"
    else
      sed -i "/$CRAFT_MARKER/,/$CRAFT_END_MARKER/d" "$CLAUDE_MD"
    fi
    echo -e "  ${GREEN}Done.${NC} Removed craft-cli rules from CLAUDE.md."
  else
    echo -e "  ${DIM}No craft-cli rules found in CLAUDE.md.${NC}"
  fi

  echo ""
  echo -e "  ${DIM}To fully uninstall: claude plugin remove craft-cli${NC}"
  echo ""
}

do_update() {
  print_header

  if has_craft_rules; then
    echo -e "  ${GREEN}[1/1]${NC} Updating workflow rules..."

    # Remove old block
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "/$CRAFT_MARKER/,/$CRAFT_END_MARKER/d" "$CLAUDE_MD"
    else
      sed -i "/$CRAFT_MARKER/,/$CRAFT_END_MARKER/d" "$CLAUDE_MD"
    fi

    # Append new block
    echo "" >> "$CLAUDE_MD"
    echo "$WORKFLOW_RULES" >> "$CLAUDE_MD"

    echo -e "  ${GREEN}Done.${NC} Workflow rules updated."
  else
    echo -e "  ${YELLOW}No existing rules found.${NC} Run without --update to install."
  fi

  echo ""
}

do_install() {
  print_header

  # Step 1: Install the plugin
  echo -e "  ${GREEN}[1/3]${NC} Installing plugin..."
  if command -v claude &>/dev/null; then
    claude plugin add "$PLUGIN_NAME" 2>/dev/null \
      && echo -e "        Plugin installed." \
      || echo -e "        ${DIM}Already installed or install skipped.${NC}"
  else
    echo -e "        ${YELLOW}Warning:${NC} 'claude' CLI not found."
    echo -e "        Install Claude Code first, then run:"
    echo -e "        ${DIM}claude plugin add $PLUGIN_NAME${NC}"
  fi

  # Step 2: Add workflow rules to CLAUDE.md
  echo -e "  ${GREEN}[2/3]${NC} Setting up CLAUDE.md..."
  if has_craft_rules; then
    echo -e "        ${DIM}Rules already present — skipping.${NC}"
  else
    if [ -f "$CLAUDE_MD" ]; then
      echo "" >> "$CLAUDE_MD"
      echo -e "        Appending rules to existing CLAUDE.md..."
    else
      echo -e "        Creating CLAUDE.md..."
    fi

    echo "$WORKFLOW_RULES" >> "$CLAUDE_MD"
    echo -e "        ${DIM}Added auto-triggers, skill chaining, context passing,${NC}"
    echo -e "        ${DIM}knowledge system, and verification rules.${NC}"
  fi

  # Step 3: Add .craft/ to .gitignore
  echo -e "  ${GREEN}[3/3]${NC} Updating .gitignore..."
  if has_gitignore_entry; then
    echo -e "        ${DIM}.craft/ already in .gitignore — skipping.${NC}"
  else
    if [ -f "$GITIGNORE" ]; then
      echo "" >> "$GITIGNORE"
    fi
    echo "# craft-cli session artifacts and knowledge" >> "$GITIGNORE"
    echo ".craft/" >> "$GITIGNORE"
    echo -e "        Added .craft/ to .gitignore."
  fi

  # Done
  echo ""
  echo -e "  ${GREEN}Ready.${NC}"
  echo ""
  echo -e "  ${DIM}Try it out:${NC}"
  echo -e "    Describe a design problem → ${BLUE}/think${NC} activates"
  echo -e "    Say \"ship it\"             → ${BLUE}/ship${NC} runs the pipeline"
  echo -e "    Report a bug              → ${BLUE}/debug${NC} takes over"
  echo ""
  echo -e "  ${DIM}Or start with:${NC} /craft-cli:scope"
  echo ""
}

# ─── Main ────────────────────────────────────────────────────────────────────

case "${1:-}" in
  --help|-h)
    print_help
    ;;
  --status|-s)
    do_status
    ;;
  --uninstall)
    do_uninstall
    ;;
  --update|-u)
    do_update
    ;;
  "")
    do_install
    ;;
  *)
    echo -e "${RED}Unknown option:${NC} $1"
    echo "Run 'bash install.sh --help' for usage."
    exit 1
    ;;
esac

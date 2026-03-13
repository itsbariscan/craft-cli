#!/bin/bash
# Secret scanner — blocks writes containing API keys, tokens, passwords
# Event: PreToolUse | Matcher: Write, Edit
# Exit 2 to block if secrets detected

# Read tool input from stdin (JSON)
input=$(cat)

# Extract content from the JSON input
# For Write: content field; For Edit: new_string field
content=$(echo "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # Check both Write (content) and Edit (new_string) fields
    print(d.get('content', '') + '\n' + d.get('new_string', '') + '\n' + d.get('old_string', ''))
except:
    pass
" 2>/dev/null)

if [ -z "$content" ]; then
  exit 0
fi

# Patterns that indicate secrets
patterns=(
  'sk[-_]live[-_][a-zA-Z0-9]'
  'sk[-_]test[-_][a-zA-Z0-9]'
  'AKIA[0-9A-Z]{16}'
  'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*'
  'ghp_[a-zA-Z0-9]{36}'
  'gho_[a-zA-Z0-9]{36}'
  'github_pat_[a-zA-Z0-9_]{82}'
  'xoxb-[0-9]{10,}-[a-zA-Z0-9]{24}'
  'xoxp-[0-9]{10,}-[a-zA-Z0-9]{24}'
  'sk-[a-zA-Z0-9]{48}'
  'sk-proj-[a-zA-Z0-9_-]{48,}'
  'password\s*[:=]\s*["\x27][^"\x27]{8,}'
  'api[_-]?key\s*[:=]\s*["\x27][a-zA-Z0-9_-]{16,}'
  'secret[_-]?key\s*[:=]\s*["\x27][a-zA-Z0-9_-]{16,}'
  'service_role_key\s*[:=]\s*["\x27]eyJ'
  'SUPABASE_SERVICE_ROLE_KEY\s*=\s*eyJ'
  'NEXT_PUBLIC_SUPABASE_ANON_KEY\s*=\s*eyJ'
)

for pattern in "${patterns[@]}"; do
  if echo "$content" | grep -qE "$pattern"; then
    echo "SECRET DETECTED — blocking write"
    echo "Pattern matched: $pattern"
    echo "Remove hardcoded secrets. Use environment variables instead."
    exit 2
  fi
done

exit 0

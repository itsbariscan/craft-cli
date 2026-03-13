#!/bin/bash
# Post-edit test runner — runs project test suite after code changes
# Event: PostToolUse | Matcher: Write|Edit

# Find and run project tests if they exist
if [ -f "package.json" ]; then
  # Check if test script exists
  if node -e "const p = require('./package.json'); process.exit(p.scripts && p.scripts.test ? 0 : 1)" 2>/dev/null; then
    echo "Running tests after edit..."
    npm test 2>&1
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
      echo "TESTS FAILED — fix before continuing"
    fi
    exit 0  # Non-blocking: feed results back but don't stop Claude
  fi
fi

# Python projects
if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || [ -d "tests" ]; then
  if command -v pytest &>/dev/null; then
    echo "Running pytest after edit..."
    pytest --tb=short -q 2>&1
    exit 0
  fi
fi

exit 0

#!/bin/bash
# Pre-commit check hook for Claude Code
# Blocks git commit if lint or tests fail
# Returns exit code 2 to block, 0 to allow

set -e

# Read stdin to get tool input
INPUT=$(cat)

# Extract the command from the JSON input
COMMAND=$(echo "$INPUT" | python3 -c "import json, sys; data=json.load(sys.stdin); print(data.get('tool_input', {}).get('command', ''))" 2>/dev/null || echo "")

# Check if this is a git commit command
if echo "$COMMAND" | grep -q "git commit"; then
    cd "$CLAUDE_PROJECT_DIR" || exit 0

    echo "Running pre-commit checks before git commit..." >&2

    # Run lint check
    if ! ./scripts/lint.sh >/dev/null 2>&1; then
        echo "BLOCKED: SwiftLint violations detected. Run ./scripts/lint.sh to see issues." >&2
        exit 2
    fi

    # Run quick tests
    if ! ./scripts/test-quick.sh >/dev/null 2>&1; then
        echo "BLOCKED: Unit tests failed. Run ./scripts/test-quick.sh to see failures." >&2
        exit 2
    fi

    echo "Pre-commit checks passed!" >&2
fi

exit 0

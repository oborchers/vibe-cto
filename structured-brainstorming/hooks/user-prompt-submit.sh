#!/usr/bin/env bash
# UserPromptSubmit hook for structured-brainstorming plugin
# Detects brainstorming-related prompts and injects skill activation context.
# Fires on every prompt — fast exit for non-matching prompts.

set -euo pipefail

# Graceful fallback if jq is not installed
if ! command -v jq &>/dev/null; then
  exit 0
fi

# Read JSON from stdin
input=$(cat)

# Extract the prompt field
prompt=$(echo "$input" | jq -r '.prompt // ""' 2>/dev/null) || exit 0

# Case-insensitive pattern match for brainstorming triggers
if echo "$prompt" | grep -iqE 'brainstorm|think through|explore (options|approaches)|how should (I|we) approach|what are (my|our) options|help me (decide|think)|weigh the options|pros and cons|I.m stuck'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "<IMPORTANT>\nThe user's prompt matches a brainstorming pattern. Invoke the structured-brainstorming skill to handle this request. Follow the brainstorm flow: restate the problem, then use AskUserQuestion to ask whether to dispatch brainstorm-explorer agents or rephrase the problem statement.\n</IMPORTANT>"
  }
}
EOF
fi

exit 0

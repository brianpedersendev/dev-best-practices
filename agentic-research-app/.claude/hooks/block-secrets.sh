#!/bin/bash
# Block edits that contain potential secrets.
# Exit code 2 = block the action. Exit code 0 = allow.
# Reads tool input from stdin as JSON, extracts file_path, greps for secrets.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# If no file path found, allow (non-file tool use)
[ -z "$FILE_PATH" ] && exit 0

# Check for common secret patterns
if grep -nE \
  'sk-ant-|sk_live_|sk_test_|AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|glpat-|xox[baprs]-|BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY|password\s*=\s*["\x27][^"\x27]+["\x27]|api_key\s*=\s*["\x27][^"\x27]+["\x27]|postgres://[^@]+:[^@]+@|mongodb(\+srv)?://[^@]+:[^@]+@' \
  "$FILE_PATH" 2>/dev/null; then
  echo "BLOCKED: Potential secret or credential detected in $FILE_PATH" >&2
  exit 2
fi

exit 0

#!/bin/bash
# PreToolUse hook: enforce conversation context in git commits.
# Only runs for Bash tool calls (filtered by hooks.json matcher).
#
# Environment: SKIP_COMMIT_HOOK=1 to bypass

[ "$SKIP_COMMIT_HOOK" = "1" ] && exit 0

# Fail open if jq is not available
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only act on commands containing git commit
echo "$COMMAND" | grep -qE '(^|[;&|][[:space:]]*)git[[:space:]]+commit([[:space:]]|$)' || exit 0

# Check if the skill is installed (plugin or standalone)
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [ -n "$PLUGIN_ROOT" ]; then
  SKILL_PATH="$PLUGIN_ROOT/skills/git-commit-conversation-context/SKILL.md"
else
  CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
  SKILL_PATH="$CWD/.claude/skills/git-commit-conversation-context/SKILL.md"
fi

[ ! -f "$SKILL_PATH" ] && exit 0

# Check if commit message contains the context marker
echo "$COMMAND" | grep -q "Conversation Context:" && exit 0

# Block the commit
echo "Git commit blocked: Missing conversation context." >&2
echo "" >&2
echo "Please use the /git-commit-conversation-context skill first to add" >&2
echo "conversation context to your commit message." >&2
echo "" >&2
echo "The skill will help you document how this work came about." >&2
exit 2

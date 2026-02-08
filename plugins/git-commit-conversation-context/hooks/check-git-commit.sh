#!/bin/bash
# PreToolUse hook: enforce conversation context in git commits.
# Blocks git commit commands that are missing a "Conversation Context:" section,
# but only when the git-commit-conversation-context skill is installed.
#
# Environment: SKIP_COMMIT_HOOK=1 to disable

[ "$SKIP_COMMIT_HOOK" = "1" ] && exit 0

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Only act on Bash tool calls containing git commit
if [ "$TOOL_NAME" != "Bash" ]; then exit 0; fi
if ! echo "$COMMAND" | grep -qE '(^|[;&|]\s*)git\s+commit(\s|$)'; then exit 0; fi

# Check if the skill is installed (plugin or standalone)
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [ -n "$PLUGIN_ROOT" ]; then
  SKILL_PATH="$PLUGIN_ROOT/skills/git-commit-conversation-context/SKILL.md"
else
  SKILL_PATH="$CWD/.claude/skills/git-commit-conversation-context/SKILL.md"
fi

if [ ! -f "$SKILL_PATH" ]; then exit 0; fi

# Check if commit message contains the context marker
if echo "$COMMAND" | grep -q "Conversation Context:"; then exit 0; fi

# Block the commit
echo "❌ Git commit blocked: Missing conversation context." >&2
echo "" >&2
echo "Please use the /git-commit-conversation-context skill first to add" >&2
echo "conversation context to your commit message." >&2
echo "" >&2
echo "The skill will help you document how this work came about." >&2
exit 2

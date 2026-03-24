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

# Extract the git subcommand deterministically.
# Git structure: git [global-flags] <subcommand> [args]
# Global flags that consume the next argument: -C, -c, --git-dir, --work-tree, --namespace
# The subcommand is the first non-flag token after 'git'.
GIT_SUBCMD=""
SKIP_NEXT=false
for word in $COMMAND; do
  if $SKIP_NEXT; then SKIP_NEXT=false; continue; fi
  case "$word" in
    git) GIT_SUBCMD=""; continue ;;
    -C|-c|--git-dir|--work-tree|--namespace) SKIP_NEXT=true; continue ;;
    -*) continue ;;
    *) GIT_SUBCMD="$word"; break ;;
  esac
done
[ "$GIT_SUBCMD" = "commit" ] || exit 0

# Resolve our own plugin root from this script's location.
# This works regardless of which plugin triggered the hook, because $0
# always points to THIS script inside THIS plugin's hooks/ directory.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OWN_PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_PATH="$OWN_PLUGIN_ROOT/skills/git-commit-conversation-context/SKILL.md"

# Fall back to CWD-based standalone installation if not found as plugin
if [ ! -f "$SKILL_PATH" ]; then
  CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
  SKILL_PATH="$CWD/.claude/skills/git-commit-conversation-context/SKILL.md"
fi

[ ! -f "$SKILL_PATH" ] && exit 0

# Check if commit message contains the context marker
echo "$COMMAND" | grep -q "Conversation Context:" && exit 0

# Block the commit
echo "Git commit blocked: Missing conversation context. Please use the /git-commit-conversation-context skill first." >&2
exit 2

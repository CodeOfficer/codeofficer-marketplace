#!/bin/bash
# Unit tests for check-git-commit.sh
# Tests the hook as a function with various scenarios.
#
# Usage: bash test-check-git-commit.sh

HOOK="$(cd "$(dirname "$0")" && pwd)/check-git-commit.sh"
PASS=0
FAIL=0
TOTAL=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

run_hook() {
  local json="$1"
  local env_vars="$2"
  local result
  result=$(echo "$json" | env -i PATH="$PATH" HOME="$HOME" $env_vars bash "$HOOK" 2>&1)
  echo "$?|$result"
}

assert_exit() {
  local test_name="$1"
  local expected_exit="$2"
  local json="$3"
  local env_vars="${4:-}"

  TOTAL=$((TOTAL + 1))
  local output
  output=$(run_hook "$json" "$env_vars")
  local actual_exit="${output%%|*}"
  local actual_msg="${output#*|}"

  if [ "$actual_exit" = "$expected_exit" ]; then
    PASS=$((PASS + 1))
    printf "${GREEN}PASS${NC} %s (exit %s)\n" "$test_name" "$actual_exit"
  else
    FAIL=$((FAIL + 1))
    printf "${RED}FAIL${NC} %s (expected exit %s, got %s)\n" "$test_name" "$expected_exit" "$actual_exit"
    [ -n "$actual_msg" ] && printf "      stderr: %s\n" "$actual_msg"
  fi
}

# Create temp dirs for testing
TEMP_DIR=$(mktemp -d)
# Simulate plugin installation: create the SKILL.md where the hook expects it
FAKE_PLUGIN_ROOT="$TEMP_DIR/plugin"
mkdir -p "$FAKE_PLUGIN_ROOT/skills/git-commit-conversation-context"
echo "---" > "$FAKE_PLUGIN_ROOT/skills/git-commit-conversation-context/SKILL.md"

FAKE_CWD="$TEMP_DIR/project"
mkdir -p "$FAKE_CWD/.claude/skills/git-commit-conversation-context"
echo "---" > "$FAKE_CWD/.claude/skills/git-commit-conversation-context/SKILL.md"

# A different plugin root (simulating another plugin's subagent)
OTHER_PLUGIN_ROOT="$TEMP_DIR/other-plugin"
mkdir -p "$OTHER_PLUGIN_ROOT"

make_json() {
  local cmd="$1"
  local cwd="${2:-$FAKE_CWD}"
  printf '{"tool_input":{"command":"%s"},"cwd":"%s"}' "$cmd" "$cwd"
}

echo ""
echo "============================================"
echo "  check-git-commit.sh Unit Tests"
echo "============================================"
echo ""

# ─────────────────────────────────────────────
echo "── Section 1: Command Detection ──"
# ─────────────────────────────────────────────

assert_exit "basic git commit (blocked)" 2 \
  "$(make_json "git commit -m 'test'")" \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT"

assert_exit "git commit with -C flag (blocked)" 2 \
  "$(make_json "git -C /some/path commit -m 'test'")" \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT"

assert_exit "git commit with --no-pager (blocked)" 2 \
  "$(make_json "git --no-pager commit -m 'test'")" \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT"

assert_exit "git commit with -c config (blocked)" 2 \
  "$(make_json "git -c user.name=foo commit -m 'test'")" \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT"

assert_exit "git commit with --git-dir (blocked)" 2 \
  "$(make_json "git --git-dir /tmp/.git commit -m 'msg'")" \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT"

assert_exit "git status (skip)" 0 \
  "$(make_json "git status")" \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT"

assert_exit "git log (skip)" 0 \
  "$(make_json "git log --oneline")" \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT"

assert_exit "git push (skip)" 0 \
  "$(make_json "git push origin main")" \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT"

assert_exit "non-git command (skip)" 0 \
  "$(make_json "echo hello")" \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT"

assert_exit "git log | grep commit (skip, not a real commit)" 0 \
  "$(make_json "git log --oneline | grep commit")" \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT"

# ─────────────────────────────────────────────
echo ""
echo "── Section 2: Conversation Context Detection ──"
# ─────────────────────────────────────────────

assert_exit "commit WITH context marker (allowed)" 0 \
  "$(make_json "git commit -m 'feat: add thing\n\n---\n\nConversation Context:\n\nWe discussed adding a thing.'")" \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT"

assert_exit "commit WITHOUT context marker (blocked)" 2 \
  "$(make_json "git commit -m 'feat: add thing without context'")" \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT"

# ─────────────────────────────────────────────
echo ""
echo "── Section 3: Skill Path Resolution ──"
# ─────────────────────────────────────────────

assert_exit "CLAUDE_PLUGIN_ROOT set to own plugin (blocked = hook active)" 2 \
  "$(make_json "git commit -m 'test'")" \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT"

assert_exit "CLAUDE_PLUGIN_ROOT unset, CWD has skill (blocked = hook active)" 2 \
  "$(make_json "git commit -m 'test'" "$FAKE_CWD")"

assert_exit "CLAUDE_PLUGIN_ROOT set to OTHER plugin (SHOULD block but...)" 2 \
  "$(make_json "git commit -m 'test'")" \
  "CLAUDE_PLUGIN_ROOT=$OTHER_PLUGIN_ROOT"

# With $0-based resolution, the hook always finds its own SKILL.md,
# so it enforces even when CWD has no standalone skill installation.
assert_exit "CLAUDE_PLUGIN_ROOT unset, CWD has NO skill (still blocks via self-resolution)" 2 \
  "$(make_json "git commit -m 'test'" "/tmp")"

# ─────────────────────────────────────────────
echo ""
echo "── Section 4: Bypass Mechanisms ──"
# ─────────────────────────────────────────────

assert_exit "SKIP_COMMIT_HOOK=1 bypasses everything" 0 \
  "$(make_json "git commit -m 'test'")" \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT SKIP_COMMIT_HOOK=1"

# ─────────────────────────────────────────────
echo ""
echo "── Section 5: Edge Cases ──"
# ─────────────────────────────────────────────

assert_exit "empty command (skip)" 0 \
  '{"tool_input":{"command":""},"cwd":"/tmp"}' \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT"

assert_exit "missing command field (skip)" 0 \
  '{"tool_input":{},"cwd":"/tmp"}' \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT"

assert_exit "malformed JSON (skip - jq handles gracefully)" 0 \
  'not json at all' \
  "CLAUDE_PLUGIN_ROOT=$FAKE_PLUGIN_ROOT"

# ─────────────────────────────────────────────
echo ""
echo "============================================"
printf "  Results: ${GREEN}%d passed${NC}, ${RED}%d failed${NC}, %d total\n" "$PASS" "$FAIL" "$TOTAL"
echo "============================================"
echo ""

# Cleanup
rm -rf "$TEMP_DIR"

# Exit with failure if any tests failed
[ "$FAIL" -eq 0 ] && exit 0 || exit 1

#!/usr/bin/env node
/**
 * PreToolUse hook to enforce conversation context in git commits.
 *
 * Environment variables:
 *   SKIP_COMMIT_HOOK=1 - Disable the hook
 *   CLAUDE_PLUGIN_ROOT - Plugin root path (set by Claude Code)
 *   DEBUG_HOOK=1 - Enable debug logging to /tmp/claude-hook-check-git-commit.log
 */

import { stdin, stderr, exit } from "node:process";
import { existsSync, appendFileSync } from "node:fs";
import { join } from "node:path";

const COMMIT_CONTEXT_SKILL = "git-commit-conversation-context";
const CONTEXT_MARKER = "Conversation Context:";

function log(message) {
  if (process.env.DEBUG_HOOK !== "1") return;
  const timestamp = new Date().toISOString();
  try {
    appendFileSync("/tmp/claude-hook-check-git-commit.log", `[${timestamp}] ${message}\n`);
  } catch {}
}

async function main() {
  try {
    if (process.env.SKIP_COMMIT_HOOK === "1") exit(0);

    let inputData = "";
    for await (const chunk of stdin) inputData += chunk;

    const hookInput = JSON.parse(inputData);
    const command = hookInput.tool_input?.command || "";
    const cwd = hookInput.cwd || process.cwd();

    const isGitCommit =
      hookInput.tool_name === "Bash" &&
      /(^|[;&|]\s*|\s)git\s+commit(\s|$)/.test(command);

    if (!isGitCommit) {
      log("Not a git commit command");
      exit(0);
    }

    const pluginRoot = process.env.CLAUDE_PLUGIN_ROOT;
    const skillPath = pluginRoot
      ? join(pluginRoot, `skills/${COMMIT_CONTEXT_SKILL}/SKILL.md`)
      : join(cwd, `.claude/skills/${COMMIT_CONTEXT_SKILL}/SKILL.md`);

    if (!existsSync(skillPath)) {
      log("Skill not installed, allowing commit");
      exit(0);
    }

    const hasContext = new RegExp(`^${CONTEXT_MARKER}`, "m").test(command);
    if (hasContext) {
      log("Context marker found, allowing commit");
      exit(0);
    }

    log("Blocking commit - missing context marker");
    stderr.write(
      "❌ Git commit blocked: Missing conversation context.\n\n" +
      `Please use the /${COMMIT_CONTEXT_SKILL} skill first to add ` +
      "conversation context to your commit message.\n\n" +
      "The skill will help you document how this work came about."
    );
    exit(2);
  } catch (error) {
    log(`ERROR: ${error.message}`);
    stderr.write(`Hook error (non-blocking): ${error.message}\n`);
    exit(0);
  }
}

main();

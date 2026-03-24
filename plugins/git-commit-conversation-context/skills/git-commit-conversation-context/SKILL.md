---
name: git-commit-conversation-context
description: REQUIRED for every git commit. Always invoke this skill before running git commit — no exceptions, including subagents. Adds conversation context documenting why the change was made.
---

# Git Commit Conversation Context

Every git commit in this project includes a conversation context section — a brief narrative explaining *why* the change was made, written from the perspective of the conversation that produced it. This matters because diffs show *what* changed and commit messages summarize *what* was done, but neither captures the discussion, trade-offs, and decisions that led there. Six months from now, the context section is what tells a reader "oh, that's why they went this route."

## When This Skill Runs

This skill is invoked before every `git commit`. A PreToolUse hook enforces this — if a commit is missing the `Conversation Context:` marker, the hook blocks it. So the workflow is:

1. Invoke this skill (or recall its format)
2. Compose the commit message with the context section included
3. Run `git commit`

## Format

After the standard commit message (subject line + optional body), add:

```
---

Conversation Context:

[Your context paragraph here]

Co-Authored-By: ...
```

The `---` separator, the `Conversation Context:` label, and a blank line before the paragraph are all required — the hook checks for the marker string.

## Writing the Context Paragraph

The context paragraph is a single paragraph, max 10 sentences, written in the author's voice (not Claude's voice). It should read like a developer explaining to a teammate what happened:

**Focus on the "why" and key decisions:**
- What did the user ask for and why?
- What approaches were considered or rejected?
- What trade-offs were made?
- What was surprising or non-obvious?

**Scope it to the current conversation only.** Summarize the actual requests and discussion from this session. If prior work is relevant but happened outside this conversation, reference it generally ("building on earlier schema work") — never invent specifics you can't see.

### Good example

```
The user identified a bug where the commit hook's regex failed to match git
commands with flags between `git` and `commit`. We first applied a simpler
regex fix, but the user pushed for a more deterministic approach. We replaced
the regex with a loop that parses the git subcommand by skipping global flags,
matching how git itself resolves subcommands.
```

Notice: it explains the *problem*, the *iteration* (first approach wasn't good enough), and the *final decision* — all from the author's perspective.

### Bad example

```
Claude was asked to fix a regex bug in check-git-commit.sh on line 16. Claude
replaced the regex with a deterministic parser. The version was bumped to 1.0.5.
```

This reads like a log entry, not a narrative. It says *what* happened (which the diff already shows) instead of *why*.

## Multi-Commit Sessions

If a conversation produces multiple commits, each gets its own context paragraph scoped to the work in that commit — not a copy of the same summary. Reference earlier commits in the session briefly if relevant ("following up on the hook fix from the previous commit, this addresses...").

## Compatibility

This skill only adds the context section. It does not:
- Generate or override the commit message subject/body
- Interfere with commit style conventions (conventional commits, etc.)
- Remove or reorder Co-Authored-By lines

Place the context section *after* the commit body and *before* the Co-Authored-By line.

---
name: git-commit-conversation-context
description: REQUIRED for every git commit. Always invoke this skill before running git commit — no exceptions, including subagents. Adds conversation context documenting why the change was made.
---

# Git Commit Conversation Context

When creating git commits, add a conversation context section to document how this work came about.

## Convention

After the standard commit message (subject + body), add a blank line followed by:

```
---

Conversation Context:

[Single paragraph, max 10 sentences, written in the author's voice, summarizing the user's prompts and our conversation that led to this commit. Based ONLY on the current conversation - do not invent details about prior sessions.]
```

## Format Example

```
feat: add domain advocate skills and unignore .claude directory

Add Claude Code skills for SATL project domain advocacy:
- satl-coordinator: orchestrates cross-domain work
- satl-primitives: KB item authoring and schema validation
...

---

Conversation Context:

We discussed creating domain advocate skills to help Claude understand and protect the constraints of different areas of the SATL codebase. The user wanted skills for each package (core, adapters, cli, mcp-server) plus a coordinator skill for cross-cutting work. We also created a meta-skill for the methodology itself, designed to be extractable to other projects. The skills follow a pattern of dynamic discovery (reading from code) rather than hard-coding knowledge, ensuring they stay current as the codebase evolves.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## Guidelines

1. **Based on current conversation only**: Summarize the user's actual requests and our discussion in this session
2. **Author's voice**: Write as if the author is explaining what happened, not as Claude describing itself
3. **No invented details**: If prior work is relevant but happened outside this conversation, mention it only generally (e.g., "building on earlier schema work")
4. **Max 10 sentences**: Keep it concise - focus on the "why" and key decisions
5. **Single paragraph**: No line breaks within the context section
6. **Separating line**: Use `---` to visually separate from the commit message body

## Works With Other Commit Skills

This skill adds conversation context and does NOT:
- Replace commit message generation
- Override commit style conventions
- Interfere with Co-Authored-By lines
- Change the standard commit format (type: subject)

Add the context section BEFORE the Co-Authored-By line if present.

## When Prior Work Is Referenced

If the user mentions "we already did X" or "building on Y from earlier":
- Acknowledge it existed: ✓ "This builds on earlier schema design work"
- Don't invent specifics: ✗ "Earlier, we created schemas A, B, C with properties X, Y, Z"

Only describe what you can see in the current conversation.

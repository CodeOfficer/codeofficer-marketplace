# Git Commit Conversation Context Plugin

Ensure every git commit includes conversation context that documents the "why" behind changes, not just the "what".

## What It Does

This plugin adds two components that work together:

1. **`/git-commit-conversation-context` skill**: Helps you add conversation context to commit messages
2. **PreToolUse hook**: Automatically enforces that commits include context (when skill is installed)

## Why Use This?

Git commits typically describe *what* changed ("fix login bug", "add feature X"), but rarely capture *why* the change was needed or how the team arrived at this solution. Conversation context fills that gap by documenting:

- What problem prompted the work
- Key decisions made during implementation
- Design trade-offs considered
- Context that future maintainers will need

## Installation

```bash
/plugin install git-commit-conversation-context@codeofficer-marketplace
```

Choose your scope:
- `--scope user`: Just for you
- `--scope project`: Share with your team (commits to `.claude/settings.json`)
- `--scope local`: Project-specific, gitignored

## Usage

### Basic Workflow

1. Make your code changes
2. Use the skill when ready to commit:
   ```bash
   /git-commit-conversation-context
   ```
3. Claude will generate a commit with conversation context
4. The commit is automatically created

### Example Commit

```
feat: add domain advocate skills and unignore .claude directory

Add Claude Code skills for SATL project domain advocacy:
- satl-coordinator: orchestrates cross-domain work
- satl-primitives: KB item authoring and schema validation
- satl-core: business logic and domain model integrity

---

Conversation Context:

We discussed creating domain advocate skills to help Claude understand and protect the constraints of different areas of the SATL codebase. The user wanted skills for each package (core, adapters, cli, mcp-server) plus a coordinator skill for cross-cutting work. We also created a meta-skill for the methodology itself, designed to be extractable to other projects. The skills follow a pattern of dynamic discovery rather than hard-coding knowledge.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## How It Works

### The Skill

The `/git-commit-conversation-context` skill guides Claude to:
- Summarize the conversation that led to the commit
- Write in the author's voice (not Claude describing itself)
- Focus on the "why" and key decisions
- Keep it concise (max 10 sentences)

### The Hook

The PreToolUse hook intercepts `git commit` commands and:
- Checks if the commit message includes "Conversation Context:"
- Blocks commits missing context (with helpful error message)
- Only enforces when the skill is installed
- Can be disabled with `SKIP_COMMIT_HOOK=1`

## Disabling the Hook

For operations like `git rebase` where you don't want enforcement:

```bash
SKIP_COMMIT_HOOK=1 /rebase
```

Or set it in your shell:

```bash
export SKIP_COMMIT_HOOK=1
```

## Convention Format

The skill adds conversation context after your commit message:

```
<type>: <subject>

<body>
<body continued...>

---

Conversation Context:

<single paragraph, max 10 sentences, summarizing the conversation>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## Guidelines

1. **Based on current conversation only**: Summarizes the actual requests and discussion in this session
2. **Author's voice**: Written as if the author is explaining what happened
3. **No invented details**: If prior work is relevant but happened outside this conversation, mention it only generally
4. **Max 10 sentences**: Concise focus on the "why" and key decisions
5. **Single paragraph**: No line breaks within the context section

## Works With Other Commit Workflows

This plugin enhances your existing commit process:
- Doesn't replace commit message generation
- Doesn't override your commit style conventions
- Doesn't interfere with Co-Authored-By lines
- Doesn't change standard commit format (type: subject)

## Troubleshooting

### Hook not triggering

Check that the hook script is executable:

```bash
chmod +x ~/.claude/plugins/git-commit-conversation-context/hooks/check-git-commit.js
```

### Want to see hook logs

The hook logs to `/tmp/claude-hook-check-git-commit.log`:

```bash
tail -f /tmp/claude-hook-check-git-commit.log
```

### Commits still going through without context

1. Verify the plugin is enabled: `/plugin list`
2. Check that hooks are configured in plugin info
3. Restart Claude Code to reload hooks

## License

MIT License - see [LICENSE](./LICENSE) for details.

## Contributing

Found a bug or have a feature request? Open an issue in the [marketplace repository](https://github.com/codeofficer/codeofficer-marketplace).

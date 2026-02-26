# Session Rename Plugin

Suggest a descriptive session name before ending, so sessions are easy to find later.

## What It Does

This plugin adds a **Stop hook** that fires when Claude is about to finish responding. If a session name hasn't been suggested yet, the hook blocks the stop and instructs Claude to suggest a descriptive kebab-case name. The user can then apply it with `/rename <name>`.

## Why Use This?

Claude Code sessions accumulate quickly and default names (timestamps or initial prompts) make them hard to find later. This plugin removes the cognitive effort of thinking up names — Claude suggests one based on the actual work done.

## Installation

```bash
/plugin install session-rename@codeofficer-marketplace
```

Choose your scope:
- `--scope user`: Just for you
- `--scope project`: Share with your team (commits to `.claude/settings.json`)
- `--scope local`: Project-specific, gitignored

## How It Works

### Runtime Flow

```
Claude finishes responding
  → Stop hook fires
  → Evaluator checks: stop_hook_active? rename already suggested?
  → No → Block: "Suggest a session name before finishing"
  → Claude suggests: "Run /rename fix-auth-token-refresh"
  → Claude finishes again
  → Stop hook fires again (stop_hook_active = true)
  → Approve → Session ends
```

### Loop Prevention

The hook blocks **at most once** per stop cycle:

1. If `stop_hook_active` is `true` (already blocked once) — approve stop
2. If Claude's last message already mentions `/rename` — approve stop
3. Otherwise — block and instruct Claude to suggest a name

## Important Notes

- `/rename` is a built-in CLI command that Claude cannot invoke programmatically
- The plugin prompts Claude to **suggest** a name; the user applies it manually
- Session names use kebab-case (e.g., `fix-auth-token-refresh`, `add-user-settings-page`)

## Disabling the Hook

To temporarily disable, uninstall or disable the plugin:

```bash
/plugin list
```

## License

MIT License - see [LICENSE](./LICENSE) for details.

## Contributing

Found a bug or have a feature request? Open an issue in the [marketplace repository](https://github.com/codeofficer/codeofficer-marketplace).

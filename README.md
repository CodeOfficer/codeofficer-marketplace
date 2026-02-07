# CodeOfficer Marketplace

A Claude Code plugin marketplace featuring workflow enhancements and development tools.

## Installation

Add this marketplace to Claude Code:

```bash
/plugin marketplace add codeofficer/codeofficer-marketplace
```

## Available Plugins

### git-commit-conversation-context

Automatically enforces conversation context in git commits, ensuring every commit documents not just *what* changed, but *why* it changed.

**Features:**
- `/git-commit-conversation-context` skill for adding context to commits
- Automatic enforcement via PreToolUse hook
- Works alongside existing commit workflows
- Skip with `SKIP_COMMIT_HOOK=1` for special operations

**Installation:**

```bash
/plugin install git-commit-conversation-context@codeofficer-marketplace
```

[View plugin documentation →](./plugins/git-commit-conversation-context/README.md)

## Plugin Scopes

When installing plugins, choose the appropriate scope:

- `--scope user` (default): Personal plugins available across all projects
- `--scope project`: Team plugins shared via git (in `.claude/settings.json`)
- `--scope local`: Project-specific plugins, gitignored (in `.claude/settings.local.json`)

Example:

```bash
/plugin install git-commit-conversation-context@codeofficer-marketplace --scope project
```

## Updating Plugins

Update all plugins from this marketplace:

```bash
/plugin marketplace update codeofficer-marketplace
```

Update a specific plugin:

```bash
/plugin update git-commit-conversation-context@codeofficer-marketplace
```

## Contributing

Have ideas for new plugins? Open an issue or submit a pull request!

## License

MIT License - see [LICENSE](./LICENSE) for details.

## Learn More

- [Claude Code Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Creating Plugins](https://code.claude.com/docs/en/plugins)
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)

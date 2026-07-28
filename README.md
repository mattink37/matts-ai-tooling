# Matt's AI Tooling

A [Claude Code plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces) for AI-assisted development tools, skills, and agents.

## Quick Start

Add this marketplace to Claude Code:

```
/plugin marketplace add mattink37/matts-ai-tooling
```

Then browse available plugins:

```
/plugin search
```

Or install a specific plugin:

```
/plugin install <plugin-name>@matts-ai-tooling
```

## Available Plugins

**hello-world** — A simple skill to verify the marketplace is working. `v1.0.0`

Install it: `/plugin install hello-world@matts-ai-tooling`

Use it: `/hello-world:hello`

## Shared Claude Rules

This repo includes shared [Claude Code rules](https://code.claude.com/docs/en/claude-code-rules) that you
can merge into your global `~/.claude/CLAUDE.md`. The installer script wraps each
rule in delimited markers so re-running it updates rules in place — your own
custom rules are left untouched.

```
./install-rules.sh
```

Or to preview without writing:

```
./install-rules.sh --dry-run
```

The script works on **macOS**, **Linux**, and **Windows** (Git Bash / WSL).

### How it works

Each `.md` file in [`rules/`](rules/) becomes a section in your global
`~/.claude/CLAUDE.md`, wrapped in markers:

```markdown
<!-- BEGIN_SHARED_RULES:matts-ai-tooling:code-style -->
... rule content ...
<!-- END_SHARED_RULES:matts-ai-tooling:code-style -->
```

- **Re-run safely** — rules are updated in place, never duplicated
- **Add your own** — content outside the markers is preserved
- **Remove a rule** — delete the `.md` file from `rules/` and re-run; the
  section is stripped from your CLAUDE.md

### Current rules

| Rule | Description |
|------|-------------|
| `code-style` | General code style and readability conventions |
| `commit-conventions` | Git commit message standards |

## Adding a Plugin to This Marketplace

### Option 1: Add a plugin in this repo (simplest)

1. Create a directory under `plugins/<plugin-name>/`
2. Add a `.claude-plugin/plugin.json` manifest and your components (skills, agents, hooks, etc.)
3. Register it in `.claude-plugin/marketplace.json`:

```json
{
  "name": "my-plugin",
  "source": "./plugins/my-plugin",
  "description": "What the plugin does"
}
```

4. Push to GitHub — users get the update on their next `/plugin marketplace update`

### Option 2: Reference an external plugin

List any git repo, npm package, or monorepo subdirectory in `.claude-plugin/marketplace.json`:

```json
{
  "name": "external-plugin",
  "source": {
    "source": "github",
    "repo": "owner/plugin-repo"
  },
  "description": "An externally-hosted plugin"
}
```

## Local Development

Clone this repo and add the marketplace locally for testing:

```
/plugin marketplace add ./matts-ai-tooling
/plugin install <plugin-name>@matts-ai-tooling
```

Validate the marketplace:

```
/plugin validate .
```

## License

MIT — see [LICENSE](LICENSE).

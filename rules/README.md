# Shared Claude Rules

This directory contains shared global rules for Claude Code. These rules are
merged into your `~/.claude/CLAUDE.md` by the `install-rules.sh` script.

## How It Works

The installer script wraps each rule file's content in delimited markers:

```markdown
<!-- BEGIN_SHARED_RULES:matts-ai-tooling:<rule-name> -->
... rule content ...
<!-- END_SHARED_RULES:matts-ai-tooling:<rule-name> -->
```

This means you can safely re-run `install-rules.sh` any time — it will update
the rules in place rather than duplicating them, and any manual edits you make
between the markers will be preserved across updates.

## Adding New Rules

1. Add a `.md` file to this directory
2. Run `./install-rules.sh` again — the new rule will be appended

## Removing Rules

Run `install-rules.sh` — it only writes rules that exist in this directory.
If you've deleted a rule file locally, its section is removed from your
global CLAUDE.md on the next install.

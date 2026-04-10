# claude-usage-displays

Local Claude session display tools for monitoring token usage, context window, and estimated costs in real time.

## Tools

### `tmux-workspace.sh`
Launches a `workspace` tmux session with a 2-column layout:

```
+-------------------+--------------------+
|                   |  claude_usage_watch|
|   Main Claude     +--------------------+
|   (left, 50%)     |  Open terminal     |
|                   +--------------------+
|                   |  Small Claude      |
+-------------------+--------------------+
```

Run it from anywhere:
```bash
bash ~/tmux-workspace.sh
```

Install symlinks it into `~/` so it's always on the path.

### `claude_usage_watch.sh`
A live tmux dashboard that polls the current Claude Code session JSONL and displays:
- Session info (ID, start time, last message)
- Token breakdown (input, cache write, cache read, output)
- Estimated API-equivalent cost (Sonnet 4.6 rates)
- Monthly totals across all sessions

Run it in a dedicated tmux pane alongside your Claude session:
```bash
bash ~/.claude/claude_usage_watch.sh
```

### `claude_status_line.py`
A compact status bar script for Claude Code's built-in status line. Shows a context window progress bar, total tokens, and estimated cost at a glance:
```
⬡ [████████░░░░░░░░░░░░] 41% | 870K tkn | ~$0.58
```

## Install

```bash
git clone https://github.com/jmdjr/claude-usage-displays.git
cd claude-usage-displays
bash install.sh
```

The install script symlinks both tools into `~/.claude/` and adds the status line to `~/.claude/settings.json`. Restart Claude Code after installing to activate the status bar.

## Notes

- Costs shown are **raw Anthropic API rates** — not actual charges if you're on a Claude Pro/Max subscription.
- The context window limit is 200K tokens (hard limit per session). The status bar tracks this per session.
- Monthly totals are a running sum with no known ceiling — Anthropic does not publish a specific token quota for subscription plans.

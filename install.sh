#!/bin/bash
# Deploys claude-usage-displays to ~/.claude/ via symlinks.
# Re-running is safe — existing symlinks are updated in place.

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

echo "Deploying from: $REPO_DIR"

# Symlink scripts into ~/.claude/
for file in claude_usage_watch.sh claude_status_line.py; do
    target="$CLAUDE_DIR/$file"
    ln -sf "$REPO_DIR/$file" "$target"
    echo "  linked: $target"
done

chmod +x "$REPO_DIR/claude_usage_watch.sh"
chmod +x "$REPO_DIR/claude_status_line.py"

# Symlink tmux-workspace.sh into ~/
TMUX_TARGET="$HOME/tmux-workspace.sh"
ln -sf "$REPO_DIR/tmux-workspace.sh" "$TMUX_TARGET"
chmod +x "$REPO_DIR/tmux-workspace.sh"
echo "  linked: $TMUX_TARGET"

# Wire statusLine into ~/.claude/settings.json if not already set
if [[ ! -f "$SETTINGS" ]]; then
    echo '{}' > "$SETTINGS"
fi

if jq -e '.statusLine' "$SETTINGS" > /dev/null 2>&1; then
    echo "  settings.json: statusLine already configured, skipping"
else
    tmp=$(mktemp)
    jq '. + {"statusLine": {"type": "command", "command": "python3 ~/.claude/claude_status_line.py"}}' \
        "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    echo "  settings.json: statusLine added"
fi

echo ""
echo "Done."
echo ""
echo "To launch the tmux workspace:"
echo "  bash ~/tmux-workspace.sh"
echo ""
echo "Restart Claude Code to activate the status bar."

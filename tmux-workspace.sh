#!/bin/bash
SESSION="workspace"

# Kill existing session if present
tmux kill-session -t "$SESSION" 2>/dev/null

# Create new detached session — first pane is left (main Claude)
tmux new-session -d -s "$SESSION"

# Split right half off the left pane
tmux split-window -t "$SESSION:0.0" -h

# Right column: split into 3 vertical panes
# Split to get top-right and bottom-right
tmux split-window -t "$SESSION:0.1" -v
# Split top-right to get middle pane
tmux split-window -t "$SESSION:0.1" -v

# Even out the three right panes
tmux select-layout -t "$SESSION:0" main-vertical

# Pane 0 (left):        Main Claude
tmux send-keys -t "$SESSION:0.0" "claude" Enter

# Pane 1 (top-right):   Claude usage panel (token/cost overview, press [t] to toggle)
tmux send-keys -t "$SESSION:0.1" "bash ~/.claude/claude_usage_watch.sh" Enter

# Pane 2 (middle-right): Open terminal — left for user
tmux send-keys -t "$SESSION:0.2" "" ""

# Pane 3 (bottom-right): Small Claude instance
tmux send-keys -t "$SESSION:0.3" "claude" Enter

# Focus the main (left) Claude pane
tmux select-pane -t "$SESSION:0.0"

# Attach
tmux attach-session -t "$SESSION"

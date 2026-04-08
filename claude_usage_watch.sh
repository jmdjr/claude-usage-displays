#!/bin/bash
# Live Claude usage stats for current session
# Reads from the most recently modified project JSONL

clear
while true; do
    printf '\033[H'

    # Find the most recently modified session JSONL
    JSONL=$(ls -t ~/.claude/projects/-home-john-Github/*.jsonl 2>/dev/null | head -1)

    if [[ -z "$JSONL" ]]; then
        echo "No session data found."
        sleep 3
        continue
    fi

    SESSION=$(basename "$JSONL" .jsonl)

    python3 - "$JSONL" "$SESSION" <<'EOF'
import sys, json, glob, os
from datetime import datetime

jsonl_path = sys.argv[1]
session_id = sys.argv[2]

CTX_LIMIT = 200_000

totals = {
    "input_tokens": 0,
    "output_tokens": 0,
    "cache_creation_input_tokens": 0,
    "cache_read_input_tokens": 0,
}
turns = 0
first_ts = None
last_ts = None
last_usage = None

try:
    with open(jsonl_path) as f:
        for line in f:
            try:
                d = json.loads(line)
                msg = d.get("message", {})
                ts = d.get("timestamp")
                if ts:
                    if first_ts is None: first_ts = ts
                    last_ts = ts
                if isinstance(msg, dict) and "usage" in msg and d.get("type") == "assistant":
                    u = msg["usage"]
                    totals["input_tokens"] += u.get("input_tokens", 0)
                    totals["output_tokens"] += u.get("output_tokens", 0)
                    totals["cache_creation_input_tokens"] += u.get("cache_creation_input_tokens", 0)
                    totals["cache_read_input_tokens"] += u.get("cache_read_input_tokens", 0)
                    last_usage = u
                    turns += 1
            except:
                pass
except Exception as e:
    print(f"Error reading file: {e}")
    sys.exit(1)

# Context window = last turn's total input
ctx = 0
if last_usage:
    ctx = (last_usage.get("input_tokens", 0) +
           last_usage.get("cache_creation_input_tokens", 0) +
           last_usage.get("cache_read_input_tokens", 0))
ctx_pct = ctx / CTX_LIMIT * 100

# Monthly totals across all sessions
month_start = datetime.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
monthly_tokens = 0
monthly_cost = 0.0
for f in glob.glob(os.path.expanduser("~/.claude/projects/-home-john-Github/*.jsonl")):
    try:
        for line in open(f):
            try:
                d = json.loads(line)
                ts = d.get("timestamp")
                if ts and d.get("type") == "assistant" and "usage" in d.get("message", {}):
                    t = datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone().replace(tzinfo=None)
                    if t >= month_start:
                        u = d["message"]["usage"]
                        i  = u.get("input_tokens", 0)
                        o  = u.get("output_tokens", 0)
                        cw = u.get("cache_creation_input_tokens", 0)
                        cr = u.get("cache_read_input_tokens", 0)
                        monthly_tokens += i + o + cw + cr
                        monthly_cost += i/1e6*3 + cw/1e6*3.75 + cr/1e6*0.30 + o/1e6*15
            except:
                pass
    except:
        pass

total_in = totals["input_tokens"] + totals["cache_creation_input_tokens"] + totals["cache_read_input_tokens"]
total_out = totals["output_tokens"]
grand_total = total_in + total_out

cost_input   = totals["input_tokens"]                / 1_000_000 * 3.00
cost_cache_w = totals["cache_creation_input_tokens"] / 1_000_000 * 3.75
cost_cache_r = totals["cache_read_input_tokens"]     / 1_000_000 * 0.30
cost_output  = totals["output_tokens"]               / 1_000_000 * 15.00
total_cost   = cost_input + cost_cache_w + cost_cache_r + cost_output

now = datetime.now().strftime("%H:%M:%S")
def parse_ts(ts):
    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone().strftime("%H:%M:%S")
    except:
        return "?"

start = parse_ts(first_ts) if first_ts else "?"
last  = parse_ts(last_ts)  if last_ts  else "?"

W = 52
BAR_W = W - 12  # [bar] XX.X% fits in remaining space

def row(text):
    return f"║{text:<{W}}║"
def div():
    return f"╠{'═'*W}╣"

filled = int(ctx_pct / 100 * BAR_W)
filled = min(filled, BAR_W)
bar = "█" * filled + "░" * (BAR_W - filled)

title = "Claude Session Usage Stats"
pad = (W - len(title)) // 2
hdr = " " * pad + title + " " * (W - len(title) - pad)

print(f"╔{'═'*W}╗")
print(row(hdr))
print(div())
print(row(f"  Updated:      {now}"))
print(row(f"  Session:      {session_id}"))
print(row(f"  Start:        {start}"))
print(row(f"  Last msg:     {last}"))
print(div())
print(row(f"  API Turns:    {turns}"))
print(div())
print(row(f"  SESSION TOKENS"))
print(row(f"  Input:        {totals['input_tokens']:>14,}"))
print(row(f"  Cache write:  {totals['cache_creation_input_tokens']:>14,}"))
print(row(f"  Cache read:   {totals['cache_read_input_tokens']:>14,}"))
print(row(f"  Output:       {totals['output_tokens']:>14,}"))
print(row(f"  {'─'*(W-4)}"))
print(row(f"  Total in:     {total_in:>14,}"))
print(row(f"  Total out:    {total_out:>14,}"))
print(row(f"  Grand total:  {grand_total:>14,}"))
print(div())
print(row(f"  EST. COST (Sonnet 4.6)  *Raw API rates"))
print(row(f"  Input:        ${cost_input:>13.4f}"))
print(row(f"  Cache write:  ${cost_cache_w:>13.4f}"))
print(row(f"  Cache read:   ${cost_cache_r:>13.4f}"))
print(row(f"  Output:       ${cost_output:>13.4f}"))
print(row(f"  {'─'*(W-4)}"))
print(row(f"  TOTAL:        ${total_cost:>13.4f}"))
print(div())
print(row(f"  THIS MONTH  (all sessions, no known limit)"))
print(row(f"  Tokens:       {monthly_tokens:>14,}"))
print(row(f"  Est. cost:    ${monthly_cost:>13.4f}"))
print(f"╚{'═'*W}╝")
EOF

    sleep 4
done

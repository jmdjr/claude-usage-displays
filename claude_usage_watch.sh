#!/bin/bash
# Claude Usage Display — overview panel with optional session detail toggle
# Press [t] to toggle between overview and current session detail

clear
MODE=0  # 0=overview, 1=session detail

while true; do
    printf '\033[H'

    JSONL=$(ls -t ~/.claude/projects/-home-john-Github/*.jsonl 2>/dev/null | head -1)

    if [[ -z "$JSONL" ]]; then
        echo "No session data found."
        read -t 3 -n 1 -s key 2>/dev/null
        continue
    fi

    SESSION=$(basename "$JSONL" .jsonl)

    python3 - "$JSONL" "$SESSION" "$MODE" <<'EOF'
import sys, json, glob, os
from datetime import datetime

jsonl_path = sys.argv[1]
session_id = sys.argv[2]
mode       = int(sys.argv[3])

W = 52

def row(text):
    return f"║{text:<{W}}║"
def div():
    return f"╠{'═'*W}╣"
def hdr(title):
    pad = (W - len(title)) // 2
    return row(" " * pad + title + " " * (W - len(title) - pad))

def parse_dt(ts):
    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone().replace(tzinfo=None)
    except:
        return None

now_str     = datetime.now().strftime("%H:%M:%S")
day_start   = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
month_start = datetime.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
month_label = datetime.now().strftime("%b %Y")
day_label   = datetime.now().strftime("%a %b %d")

# ── Scan all JSONLs for overview stats ──────────────────────────────────────
all_jsonls = glob.glob(os.path.expanduser("~/.claude/projects/-home-john-Github/*.jsonl"))

today_sessions = 0;  today_tokens = 0;  today_cost = 0.0
month_sessions = 0;  month_tokens = 0;  month_cost = 0.0

for f in all_jsonls:
    ft = 0; fc = 0.0; has_today = False
    fm = 0; fmc = 0.0; has_month = False
    try:
        for line in open(f):
            try:
                d = json.loads(line)
                ts = d.get("timestamp")
                if ts and d.get("type") == "assistant" and "usage" in d.get("message", {}):
                    t = parse_dt(ts)
                    if t is None: continue
                    u = d["message"]["usage"]
                    i  = u.get("input_tokens", 0)
                    o  = u.get("output_tokens", 0)
                    cw = u.get("cache_creation_input_tokens", 0)
                    cr = u.get("cache_read_input_tokens", 0)
                    tok = i + o + cw + cr
                    c   = i/1e6*3 + cw/1e6*3.75 + cr/1e6*0.30 + o/1e6*15
                    if t >= month_start:
                        has_month = True; fm += tok; fmc += c
                    if t >= day_start:
                        has_today = True; ft += tok; fc += c
            except:
                pass
    except:
        pass
    if has_month:
        month_sessions += 1; month_tokens += fm; month_cost += fmc
    if has_today:
        today_sessions += 1; today_tokens += ft; today_cost += fc

# ── Current session stats (for detail view) ─────────────────────────────────
totals = {"input_tokens":0,"output_tokens":0,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}
turns    = 0
first_ts = None
last_ts  = None

try:
    for line in open(jsonl_path):
        try:
            d = json.loads(line)
            msg = d.get("message", {})
            ts  = d.get("timestamp")
            if ts:
                if first_ts is None: first_ts = ts
                last_ts = ts
            if isinstance(msg, dict) and "usage" in msg and d.get("type") == "assistant":
                u = msg["usage"]
                for k in totals:
                    totals[k] += u.get(k, 0)
                turns += 1
        except:
            pass
except:
    pass

def fmt_ts(ts):
    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone().strftime("%H:%M:%S")
    except:
        return "?"

total_in    = totals["input_tokens"] + totals["cache_creation_input_tokens"] + totals["cache_read_input_tokens"]
total_out   = totals["output_tokens"]
grand_total = total_in + total_out
cost_i      = totals["input_tokens"]                / 1e6 * 3.00
cost_cw     = totals["cache_creation_input_tokens"] / 1e6 * 3.75
cost_cr     = totals["cache_read_input_tokens"]     / 1e6 * 0.30
cost_o      = totals["output_tokens"]               / 1e6 * 15.00
sess_cost   = cost_i + cost_cw + cost_cr + cost_o

# ── Render ───────────────────────────────────────────────────────────────────
if mode == 0:
    print(f"╔{'═'*W}╗")
    print(hdr("Claude Usage Overview"))
    print(div())
    print(row(f"  Updated:      {now_str}"))
    print(div())
    print(row(f"  TODAY  ({day_label})"))
    print(row(f"  Sessions:     {today_sessions:>14,}"))
    print(row(f"  Tokens:       {today_tokens:>14,}"))
    print(row(f"  Est. cost:    ${today_cost:>13.4f}"))
    print(div())
    print(row(f"  THIS MONTH  ({month_label})"))
    print(row(f"  Sessions:     {month_sessions:>14,}"))
    print(row(f"  Tokens:       {month_tokens:>14,}"))
    print(row(f"  Est. cost:    ${month_cost:>13.4f}"))
    print(div())
    print(row(f"  * Raw API rates, not subscription charges"))
    print(div())
    print(row(f"  [t] View current session detail"))
    print(f"╚{'═'*W}╝")

else:
    print(f"╔{'═'*W}╗")
    print(hdr("Claude Session Detail"))
    print(div())
    print(row(f"  Updated:      {now_str}"))
    print(row(f"  Session:      {session_id}"))
    print(row(f"  Start:        {fmt_ts(first_ts) if first_ts else '?'}"))
    print(row(f"  Last msg:     {fmt_ts(last_ts) if last_ts else '?'}"))
    print(div())
    print(row(f"  API Turns:    {turns}"))
    print(div())
    print(row(f"  TOKENS"))
    print(row(f"  Input:        {totals['input_tokens']:>14,}"))
    print(row(f"  Cache write:  {totals['cache_creation_input_tokens']:>14,}"))
    print(row(f"  Cache read:   {totals['cache_read_input_tokens']:>14,}"))
    print(row(f"  Output:       {totals['output_tokens']:>14,}"))
    print(row(f"  {'─'*(W-4)}"))
    print(row(f"  Total in:     {total_in:>14,}"))
    print(row(f"  Total out:    {total_out:>14,}"))
    print(row(f"  Grand total:  {grand_total:>14,}"))
    print(div())
    print(row(f"  EST. COST  *Raw API rates"))
    print(row(f"  Input:        ${cost_i:>13.4f}"))
    print(row(f"  Cache write:  ${cost_cw:>13.4f}"))
    print(row(f"  Cache read:   ${cost_cr:>13.4f}"))
    print(row(f"  Output:       ${cost_o:>13.4f}"))
    print(row(f"  {'─'*(W-4)}"))
    print(row(f"  TOTAL:        ${sess_cost:>13.4f}"))
    print(div())
    print(row(f"  [t] Back to overview"))
    print(f"╚{'═'*W}╝")
EOF

    read -t 4 -n 1 -s key 2>/dev/null
    if [[ "$key" == "t" || "$key" == "T" ]]; then
        MODE=$((1 - MODE))
        clear
    fi
done

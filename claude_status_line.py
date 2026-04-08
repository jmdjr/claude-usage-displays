#!/usr/bin/env python3
import json, glob, os

CTX_LIMIT = 200_000
BAR_W = 20

files = sorted(
    glob.glob(os.path.expanduser("~/.claude/projects/-home-john-Github/*.jsonl")),
    key=os.path.getmtime, reverse=True
)
if not files:
    print("⬡ no session")
    raise SystemExit

t = {"i": 0, "o": 0, "cw": 0, "cr": 0}
last_usage = None
for line in open(files[0]):
    try:
        d = json.loads(line)
        if d.get("type") == "assistant" and "usage" in d.get("message", {}):
            u = d["message"]["usage"]
            t["i"]  += u.get("input_tokens", 0)
            t["o"]  += u.get("output_tokens", 0)
            t["cw"] += u.get("cache_creation_input_tokens", 0)
            t["cr"] += u.get("cache_read_input_tokens", 0)
            last_usage = u
    except:
        pass

ctx = 0
if last_usage:
    ctx = (last_usage.get("input_tokens", 0) +
           last_usage.get("cache_creation_input_tokens", 0) +
           last_usage.get("cache_read_input_tokens", 0))
ctx_pct = min(ctx / CTX_LIMIT * 100, 100)

filled = int(ctx_pct / 100 * BAR_W)
bar = "█" * filled + "░" * (BAR_W - filled)

total = t["i"] + t["o"] + t["cw"] + t["cr"]
cost  = t["i"]/1e6*3 + t["cw"]/1e6*3.75 + t["cr"]/1e6*0.30 + t["o"]/1e6*15
print(f"⬡ [{bar}] {ctx_pct:.0f}% | {total/1000:.1f}K tkn | ~${cost:.3f}")

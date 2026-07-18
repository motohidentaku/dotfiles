#!/bin/bash
# Claude Code status line (2-line)
# Line 1: model [effort] ▸ repo ⎇ branch
# Line 2: ●●●●○○○○○○ 40% ▸ 5h: 26% ↺17:00 ▸ 7d: 12% ▸ ¥1,227 / 7h20m
#
# USD→JPY rate is configurable via env: CLAUDE_JPY_RATE (default 155)

input=$(cat)
JPY_RATE=${CLAUDE_JPY_RATE:-155}

# ---- extract ----
model=$(jq -r '.model.display_name // "?"'          <<<"$input")
effort=$(jq -r '.effort.level // empty'             <<<"$input")
dir=$(jq -r '.workspace.current_dir // .cwd // "."' <<<"$input")
repo=$(jq -r '.workspace.repo.name // empty'        <<<"$input")
[ -z "$repo" ] && repo=$(basename "$dir")
branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)

ctx=$(jq -r '.context_window.used_percentage // empty'        <<<"$input")
r5=$(jq -r  '.rate_limits.five_hour.used_percentage // empty' <<<"$input")
r5reset=$(jq -r '.rate_limits.five_hour.resets_at // empty'   <<<"$input")
r7=$(jq -r  '.rate_limits.seven_day.used_percentage // empty' <<<"$input")
cost_usd=$(jq -r '.cost.total_cost_usd // empty'    <<<"$input")
dur_ms=$(jq -r '.cost.total_duration_ms // empty'   <<<"$input")

# ---- colors ----
DIM=$'\033[2m'; RST=$'\033[0m'; CYN=$'\033[36m'
GRN=$'\033[32m'; YEL=$'\033[33m'; RED=$'\033[31m'

# ---- line 1 ----
l1="${CYN}${model}${RST}"
[ -n "$effort" ] && l1="${l1} ${DIM}[${effort}]${RST}"
l1="${l1} ${DIM}▸${RST} ${repo}"
[ -n "$branch" ] && l1="${l1} ${DIM}⎇ ${branch}${RST}"

# ---- line 2 ----
parts=()

# context gauge (10 segments, colored by fill level)
if [ -n "$ctx" ]; then
  filled=$(awk -v p="$ctx" 'BEGIN{f=int(p/10+0.5); if(f>10)f=10; print f}')
  col=$GRN; awk -v p="$ctx" 'BEGIN{exit !(p>=80)}' && col=$RED || { awk -v p="$ctx" 'BEGIN{exit !(p>=50)}' && col=$YEL; }
  gauge=""
  for i in $(seq 1 10); do
    if [ "$i" -le "$filled" ]; then gauge="${gauge}●"; else gauge="${gauge}○"; fi
  done
  parts+=("${col}${gauge}${RST}${DIM} $(printf '%.0f%%' "$ctx")${RST}")
fi

# 5-hour rate limit
if [ -n "$r5" ]; then
  seg="5h: $(printf '%.0f%%' "$r5")"
  if [ -n "$r5reset" ]; then
    rt=$(date -d "@${r5reset%.*}" +%H:%M 2>/dev/null)
    [ -n "$rt" ] && seg="${seg} ↺${rt}"
  fi
  parts+=("${DIM}${seg}${RST}")
fi

# 7-day rate limit
[ -n "$r7" ] && parts+=("${DIM}7d: $(printf '%.0f%%' "$r7")${RST}")

# cost (¥) + uptime
tail=""
if [ -n "$cost_usd" ]; then
  yen=$(awk -v u="$cost_usd" -v r="$JPY_RATE" 'BEGIN{
    n=int(u*r+0.5); s=sprintf("%d",n); out=""; c=0;
    for(i=length(s);i>=1;i--){ out=substr(s,i,1) out; c++; if(c%3==0 && i>1) out=","out }
    print out }')
  tail="¥${yen}"
fi
if [ -n "$dur_ms" ]; then
  up=$(awk -v ms="$dur_ms" 'BEGIN{s=int(ms/1000); h=int(s/3600); m=int((s%3600)/60);
    if(h>0) printf "%dh%02dm",h,m; else printf "%dm",m }')
  [ -n "$tail" ] && tail="${tail} / ${up}" || tail="$up"
fi
[ -n "$tail" ] && parts+=("${DIM}${tail}${RST}")

# join with ▸
l2=""; sep=""
for p in "${parts[@]}"; do
  l2="${l2}${sep}${p}"; sep=" ${DIM}▸${RST} "
done

printf '%b\n%b' "$l1" "$l2"

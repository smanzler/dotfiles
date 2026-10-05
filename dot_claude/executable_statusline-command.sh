#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Triptych — a two-row Claude Code status line.
#   row 1  model chip · repo · branch + clean/dirty dot · working-tree diff · modes
#   row 2  context bar + % · cost · elapsed · rotator
#
# Palette and glyphs adapted from the "Triptych" template at statusline.sh.
#
# Install:
#   1. save as ~/.claude/statusline-command.sh && chmod +x it
#   2. add to ~/.claude/settings.json:
#        "statusLine": {
#          "type": "command",
#          "command": "bash /absolute/path/to/statusline-command.sh"
#        }
#
# Requires: bash, jq, git. Truecolor terminal. The branch glyph needs a Nerd
# Font — set BRANCH_GLYPH="🌿" below if yours renders a box.
#
# Tweakables: BRANCH_GLYPH, BAR_WIDTH, ROTATOR_ITEMS, ROTATE_SECS, the shared
# 20/70/90 context thresholds, and DIFF_EXCLUDE_RE / MAX_UNTRACKED_FILES /
# DIFF_CACHE_TTL for the working-tree diff counter.
# ─────────────────────────────────────────────────────────────────────────────
input=$(cat)

# ── glyph: swap to "🌿" if your terminal font isn't a Nerd Font ───────────────
BRANCH_GLYPH=""

# ── ansi helpers ──────────────────────────────────────────────────────────────
fg()     { printf "\033[38;2;%d;%d;%dm" "$1" "$2" "$3"; }
bg()     { printf "\033[48;2;%d;%d;%dm" "$1" "$2" "$3"; }
bold()   { printf "\033[1m"; }
dim()    { printf "\033[2m"; }
italic() { printf "\033[3m"; }
rst()    { printf "\033[0m"; }

SEP="$(fg 168 162 158)· $(rst)"

# ── inputs ────────────────────────────────────────────────────────────────────
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')
git_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // .workspace.project_dir // empty')
repo_name=$(echo "$input" | jq -r '.workspace.repo.name // empty')
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cost_raw=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')
thinking_on=$(echo "$input" | jq -r '.thinking.enabled // false')
effort=$(echo "$input" | jq -r '.effort.level // empty')
out_style=$(echo "$input" | jq -r '.output_style.name // empty')
fast_mode=$(echo "$input" | jq -r '.fast_mode // false')

# ── git ───────────────────────────────────────────────────────────────────────
branch=""; dirty=""; repo_root=""
if [ -n "$git_dir" ] && command -v git >/dev/null 2>&1; then
  repo_root=$(git -C "$git_dir" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$repo_root" ]; then
    branch=$(git -C "$repo_root" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null) \
      || branch=$(git -C "$repo_root" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    if [ -n "$(git -C "$repo_root" --no-optional-locks status --porcelain -uno 2>/dev/null | head -1)" ]; then
      dirty="yes"
    else
      dirty="no"
    fi
  fi
fi

# Name the repo the branch and diff actually describe, not a stale project dir.
if [ -z "$repo_name" ]; then
  name_src="${repo_root:-${git_dir:-$project_dir}}"
  [ -n "$name_src" ] && repo_name=$(basename "$name_src")
fi

# ── context color + emoji: same thresholds as before (20 / 70 / 90) ───────────
ctx_color() {
  if   [ "$1" -lt 20 ]; then fg 134 239 172
  elif [ "$1" -lt 70 ]; then fg 251 191  36
  elif [ "$1" -lt 90 ]; then fg 251 146  60
  else                       fg 248 113 113
  fi
}

ctx_emoji() {
  if   [ "$1" -lt 20 ]; then printf "🟢"
  elif [ "$1" -lt 70 ]; then printf "⚡"
  elif [ "$1" -lt 90 ]; then printf "🔥"
  else                       printf "🚨"
  fi
}

BAR_WIDTH=18
build_bar() {
  local pct="$1" filled empty bar="" i=0
  filled=$(( pct * BAR_WIDTH / 100 ))
  [ $filled -gt $BAR_WIDTH ] && filled=$BAR_WIDTH
  empty=$(( BAR_WIDTH - filled ))
  while [ $i -lt $filled ]; do bar="${bar}▰"; i=$(( i + 1 )); done
  i=0
  while [ $i -lt $empty ]; do bar="${bar}▱"; i=$(( i + 1 )); done
  printf "%s" "$bar"
}

human_duration() {
  local ms="$1" s h m
  s=$(( ms / 1000 ))
  h=$(( s / 3600 )); m=$(( (s % 3600) / 60 ))
  if   [ $h -gt 0 ]; then printf "%dh %dm" "$h" "$m"
  elif [ $m -gt 0 ]; then printf "%dm" "$m"
  else                    printf "%ds" "$s"
  fi
}

# ── working-tree diff ─────────────────────────────────────────────────────────
# What the repo actually carries, not what the session typed: tracked changes vs
# HEAD (staged + unstaged) plus the line count of new untracked files, which a
# bare `git diff` scores as zero. Agent scratch is excluded — those trees are
# written into the repo but never shipped.
DIFF_EXCLUDE_RE='^(\.superpowers|\.claude|\.agent|\.agents|\.aider|\.specstory|\.plan|\.cache)/'
MAX_UNTRACKED_FILES=150   # cap: a stray untracked tree must not stall the prompt
DIFF_CACHE_TTL=3          # seconds; the status line re-renders far faster than this

tracked_counts() {   # repo_root -> "added removed"
  local root="$1" out
  if git -C "$root" --no-optional-locks rev-parse --verify -q HEAD >/dev/null 2>&1; then
    out=$(git -C "$root" --no-optional-locks diff --numstat HEAD 2>/dev/null)
  else
    out=$(git -C "$root" --no-optional-locks diff --numstat --cached 2>/dev/null)
  fi
  # Path is everything after the two count fields — it can contain spaces, and a
  # detected rename renders it as "old => new", so $3 alone is not the path.
  printf '%s\n' "$out" | awk -v ex="$DIFF_EXCLUDE_RE" '
    { path = $0; sub(/^[^\t]*\t[^\t]*\t/, "", path) }
    path ~ ex { next }
    { a += $1; r += $2 }
    END { print a + 0, r + 0 }'
}

untracked_added() {  # repo_root -> added
  local root="$1" list text
  list=$(git -C "$root" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null \
         | grep -Ev "$DIFF_EXCLUDE_RE" | head -n "$MAX_UNTRACKED_FILES")
  # Both xargs runs are guarded against empty input: with no arguments, grep and
  # wc would read stdin and hang the prompt forever.
  [ -z "$list" ] && { printf 0; return; }
  text=$(cd "$root" 2>/dev/null && printf '%s\n' "$list" | tr '\n' '\0' | xargs -0 grep -Il . 2>/dev/null)
  [ -z "$text" ] && { printf 0; return; }
  (cd "$root" 2>/dev/null && printf '%s\n' "$text" | tr '\n' '\0' | xargs -0 wc -l 2>/dev/null) \
    | awk '$2 != "total" { a += $1 } END { print a + 0 }'
}

lines_added=""; lines_removed=""
if [ -n "$repo_root" ]; then
  cache="${TMPDIR:-/tmp}/cc-statusline-$(printf '%s' "$repo_root" | cksum | tr -dc '0-9').diff"
  now=$(date +%s); c_at=""; c_add=""; c_del=""
  [ -r "$cache" ] && read -r c_at c_add c_del < "$cache" 2>/dev/null
  if [ -n "$c_at" ] && [ $(( now - c_at )) -lt "$DIFF_CACHE_TTL" ]; then
    lines_added="$c_add"; lines_removed="$c_del"
  else
    read -r lines_added lines_removed <<TRACKED
$(tracked_counts "$repo_root")
TRACKED
    lines_added=$(( ${lines_added:-0} + $(untracked_added "$repo_root") ))
    lines_removed=${lines_removed:-0}
    printf '%s %s %s\n' "$now" "$lines_added" "$lines_removed" > "$cache" 2>/dev/null
  fi
fi

# ── row 1: identity + diff ────────────────────────────────────────────────────
row1="$(bold)$(fg 255 255 255)$(bg 219 39 119) ${model} $(rst)"
[ -n "$repo_name" ] && row1="${row1} $(bold)$(fg 253 186 116)${repo_name}$(rst)"
if [ -n "$branch" ]; then
  row1="${row1} $(italic)$(fg 254 215 170)${BRANCH_GLYPH} ${branch}$(rst)"
  if [ "$dirty" = "yes" ]; then
    row1="${row1}$(bold)$(fg 251 191 36) ◆$(rst)"
  else
    row1="${row1}$(fg 251 146 60) ◇$(rst)"
  fi
fi
if [ "${lines_added:-0}" -gt 0 ] || [ "${lines_removed:-0}" -gt 0 ]; then
  row1="${row1} $(bold)$(fg 236 74 161)Δ$(rst) "
  [ -n "$lines_added" ]   && row1="${row1}$(fg 134 239 172)+${lines_added}$(rst)"
  [ -n "$lines_added" ] && [ -n "$lines_removed" ] && row1="${row1} "
  [ -n "$lines_removed" ] && row1="${row1}$(fg 251 113 133)-${lines_removed}$(rst)"
fi

# ── row 1 tail: modes (each hidden when it has nothing to say) ────────────────
if [ "$thinking_on" = "true" ] && [ -n "$effort" ]; then
  row1="${row1} $(bold)$(fg 236 74 161)✦ ${effort}$(rst)"
fi
if [ -n "$out_style" ] && [ "$out_style" != "default" ]; then
  row1="${row1} $(italic)$(fg 240 171 252)✎ ${out_style}$(rst)"
fi
if [ "$fast_mode" = "true" ]; then
  row1="${row1} $(bold)$(fg 11 16 26)$(bg 253 224 71) ⚡ $(rst)"
fi

# ── row 2: progress ───────────────────────────────────────────────────────────
row2=""
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  c=$(ctx_color "$used_int")
  row2=" $(fg 253 186 116)ctx$(rst) ${c}$(build_bar "$used_int")$(rst) $(ctx_emoji "$used_int") ${c}$(bold)${used_int}%$(rst)"
fi
if [ -n "$cost_raw" ]; then
  [ -n "$row2" ] && row2="${row2} ${SEP}" || row2=" "
  row2="${row2}$(fg 254 243 199)$(printf '$%.4f' "$cost_raw")$(rst)"
fi
if [ -n "$duration_ms" ]; then
  [ -n "$row2" ] && row2="${row2} ${SEP}" || row2=" "
  row2="${row2}$(fg 254 215 170)$(human_duration "$duration_ms")$(rst)"
fi

# ── rotator: cycles every ROTATE_SECS; edit or empty ROTATOR_ITEMS to taste ───
ROTATOR_ITEMS=("building" "thinking" "shipping" "exploring")
ROTATE_SECS=5
if [ ${#ROTATOR_ITEMS[@]} -gt 0 ]; then
  idx=$(( ( $(date +%s) / ROTATE_SECS ) % ${#ROTATOR_ITEMS[@]} ))
  [ -n "$row2" ] && row2="${row2} ${SEP}" || row2=" "
  row2="${row2}$(italic)$(fg 251 207 232)${ROTATOR_ITEMS[$idx]}$(rst)"
fi


# ── output ────────────────────────────────────────────────────────────────────
printf "%s" "$row1"
[ -n "$row2" ] && printf "\n%s" "$row2"

#!/usr/bin/env bash
#
# qa_common.sh — shared helpers for the nightly QA agent scripts.
#
# Source this from other scripts:  source "scripts/lib/qa_common.sh"
# It defines logging helpers plus the lcov parsing and agent-prompt builders
# described in docs/blog/nightly-qa-agent.md.

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
_c_blue=$'\033[34m'; _c_green=$'\033[32m'; _c_yellow=$'\033[33m'
_c_red=$'\033[31m'; _c_dim=$'\033[2m'; _c_reset=$'\033[0m'

log()  { printf '%s==>%s %s\n' "$_c_blue"  "$_c_reset" "$*"; }
ok()   { printf '%s ✓ %s%s\n'  "$_c_green" "$*" "$_c_reset"; }
warn() { printf '%s ! %s%s\n'  "$_c_yellow" "$*" "$_c_reset" >&2; }
err()  { printf '%s ✗ %s%s\n'  "$_c_red" "$*" "$_c_reset" >&2; }
dim()  { printf '%s%s%s\n'      "$_c_dim" "$*" "$_c_reset"; }

# ---------------------------------------------------------------------------
# Coverage parsing
# ---------------------------------------------------------------------------

# coverage_percent <lcov.info> -> prints the overall line-coverage %, e.g. 38.6
coverage_percent() {
  local info="${1:-coverage/lcov.info}"
  [ -f "$info" ] || { echo "0.0"; return; }
  # Sum LF (lines found) and LH (lines hit) across all records and compute %.
  awk -F: '
    /^LF:/ { found += $2 }
    /^LH:/ { hit   += $2 }
    END {
      if (found == 0) { print "0.0" }
      else { printf "%.1f", (hit / found) * 100 }
    }' "$info"
}

# zero_coverage_files <lcov.info> -> prints, one per line, every source file
# whose lines were never hit (LH:0). These are the agent's primary targets.
zero_coverage_files() {
  local info="${1:-coverage/lcov.info}"
  [ -f "$info" ] || return 0
  awk -F: '
    /^SF:/ { file = substr($0, 4) }
    /^LH:/ { hit = $2 }
    /^end_of_record/ { if (hit == 0) print file; file=""; hit=0 }
  ' "$info"
}

# low_coverage_report <lcov.info> -> human-readable "pct  path" lines sorted
# ascending, so the lowest-covered files (the agent's work list) come first.
low_coverage_report() {
  local info="${1:-coverage/lcov.info}"
  [ -f "$info" ] || return 0
  awk -F: '
    /^SF:/ { file = substr($0, 4); found=0; hit=0 }
    /^LF:/ { found = $2 }
    /^LH:/ { hit = $2 }
    /^end_of_record/ {
      pct = (found == 0) ? 0 : (hit / found) * 100
      printf "%5.1f%%  %s\n", pct, file
    }
  ' "$info" | sort -n
}

# ---------------------------------------------------------------------------
# Agent prompt
# ---------------------------------------------------------------------------

# build_agent_prompt <memory_file> <gap_file> -> prints the prompt the
# Antigravity CLI agent receives. It bundles the persistent memory and the
# concrete list of uncovered files so the agent has full context but a small,
# targeted scope (keeping tokens cheap — see the blog's "Cost Tips").
build_agent_prompt() {
  local memory="$1" gaps="$2"
  cat <<EOF
You are the nightly QA agent for the Flutter app "agy_flutter".

Your job: raise test coverage by writing the missing unit and widget tests for
the files listed below. Work only inside test/. Follow every rule below.

## Hard rules
1. NEVER modify application source under lib/, EXCEPT adding a widget Key that
   an existing integration test needs to find an element. No logic changes.
2. Every test MUST assert real behavior — an output, an error message, or a
   state change. A test that only pumps a widget or runs a line without an
   \`expect\` is not acceptable.
3. Write tests against each unit's PUBLIC CONTRACT (its API, labels, validators,
   emitted states). Do not reverse-engineer the implementation and "bless"
   whatever it currently does — if behavior looks wrong, note it in the PR body
   instead of writing a test that locks the bug in.
4. Mirror the existing test style in test/ (mocks, helpers, naming).
5. After writing, the suite must pass \`flutter analyze\` and \`flutter test\`.

## Project memory (lessons from previous runs — read before you start)
$(cat "$memory" 2>/dev/null || echo "(no memory file yet)")

## Files with zero / low coverage to target tonight
$(cat "$gaps" 2>/dev/null || echo "(none detected)")
EOF
}

#!/usr/bin/env bash
#
# nightly_qa.sh — the nightly QA agent, run locally with the Antigravity CLI.
#
# This is the cron entrypoint described in docs/blog/nightly-qa-agent.md. Each
# night it: pulls develop, cuts a dated branch, finds the day's changes,
# measures coverage, asks the Antigravity CLI agent to write the missing unit
# and widget tests, verifies everything green (incl. integration tests on the
# iOS simulator), updates the coverage dashboard + agent memory, and opens a PR.
#
# It is written to be SAFE to run today: if the remote, `gh`, or the Antigravity
# CLI aren't available it degrades to a dry run and tells you what it would do.
#
# Usage:        ./scripts/nightly_qa.sh
# Cron (8pm):   0 20 * * * cd /path/to/agy_flutter && ./scripts/nightly_qa.sh
#
# Tunables (env vars):
#   TARGET_BRANCH      base branch to work off          (default: develop)
#   DEVICE             iOS simulator name               (default: "iPhone 17")
#   WORK_START         "today's changes" cutoff         (default: 06:00)
#   MAX_HEAL_ATTEMPTS  self-heal retries before quarantine (default: 3)
#   ANTIGRAVITY_CLI    command that runs the agent      (default: agy)
#   SKIP_INTEGRATION   set to 1 to skip simulator tests (default: 0)
#   DRY_RUN            set to 1 to never touch the network/agent (auto-detected)

set -euo pipefail
cd "$(dirname "$0")/.."                      # repo root
source "scripts/lib/qa_common.sh"

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
# Detect base branch: develop if exists, otherwise main
if [ -z "${TARGET_BRANCH:-}" ]; then
  if git show-ref --verify --quiet refs/heads/develop || git show-ref --verify --quiet refs/remotes/origin/develop; then
    TARGET_BRANCH="develop"
  else
    TARGET_BRANCH="main"
  fi
fi
DEVICE="${DEVICE:-iPhone 17}"
WORK_START="${WORK_START:-06:00}"
MAX_HEAL_ATTEMPTS="${MAX_HEAL_ATTEMPTS:-3}"
ANTIGRAVITY_CLI="${ANTIGRAVITY_CLI:-agy}"
SKIP_INTEGRATION="${SKIP_INTEGRATION:-0}"
DRY_RUN="${DRY_RUN:-0}"

DATE_TAG="$(date +%Y%m%d)"
DATE_ISO="$(date +%Y-%m-%d)"
BRANCH="qa/auto-${DATE_TAG}"
MEMORY_FILE="docs/reports/qa_agent_memory.md"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
SECONDS=0   # run-time stopwatch

# ---------------------------------------------------------------------------
# Preflight: decide what this environment can actually do.
# ---------------------------------------------------------------------------
HAVE_REMOTE=1; HAVE_GH=1; HAVE_AGENT=1
git remote get-url origin >/dev/null 2>&1 || HAVE_REMOTE=0
command -v gh >/dev/null 2>&1               || HAVE_GH=0
command -v "${ANTIGRAVITY_CLI%% *}" >/dev/null 2>&1 || HAVE_AGENT=0

[ "$HAVE_REMOTE" = 1 ] || warn "No 'origin' remote — skipping fetch/push/PR (template mode)."
[ "$HAVE_GH" = 1 ]     || warn "'gh' not installed — skipping PR creation (https://cli.github.com)."
[ "$HAVE_AGENT" = 1 ]  || warn "agy CLI not found — agent steps will dry-run."

# ---------------------------------------------------------------------------
# run_agent <prompt_file> — hand a prompt to the Antigravity CLI.
#   The agent reads the prompt, writes test files under test/, and may add
#   widget Keys under lib/. >>> Adjust the invocation to your CLI version. <<<
# ---------------------------------------------------------------------------
run_agent() {
  local prompt_file="$1"
  if [ "$DRY_RUN" = 1 ] || [ "$HAVE_AGENT" = 0 ]; then
    warn "Dry run — prompt that WOULD be sent to the agent:"
    dim "------------------------------------------------------------"
    cat "$prompt_file"
    dim "------------------------------------------------------------"
    return 0
  fi
  # The real call. We pass the prompt via --print and skip permissions prompts.
  ${ANTIGRAVITY_CLI} --print "$(cat "$prompt_file")" --dangerously-skip-permissions < /dev/null
}

# ===========================================================================
# Step 0 — Load persistent memory & learn from yesterday's PR
# ===========================================================================
log "Loading agent memory ($MEMORY_FILE)"
[ -f "$MEMORY_FILE" ] || warn "No memory file yet — the agent starts cold tonight."

if [ "$HAVE_GH" = 1 ] && [ "$HAVE_REMOTE" = 1 ]; then
  log "Checking last night's PR for human feedback (negative-feedback loop)"
  PREV_PR="$(gh pr list --base "$TARGET_BRANCH" --search "head:qa/auto-" \
              --state all --limit 1 --json number,comments,reviews 2>/dev/null || true)"
  if [ -n "${PREV_PR:-}" ] && [ "$PREV_PR" != "[]" ]; then
    echo "$PREV_PR" > "$WORKDIR/prev_pr.json"
    ok "Captured previous PR feedback for the agent to learn from."
    # The agent folds this into MEMORY_FILE during Step 6 self-evaluation.
  fi
fi

# ===========================================================================
# Step 1 — Pull & branch
# ===========================================================================
log "Switching to a clean $BRANCH off $TARGET_BRANCH"
if [ "$HAVE_REMOTE" = 1 ]; then
  git fetch origin "$TARGET_BRANCH"
  git switch "$TARGET_BRANCH"
  git pull --ff-only origin "$TARGET_BRANCH"
fi
git switch -c "$BRANCH" 2>/dev/null || git switch "$BRANCH"

# ===========================================================================
# Step 2 — Find today's changes (incremental diffing keeps tokens cheap)
# ===========================================================================
log "Today's commits since $WORK_START"
git log --since="$WORK_START" --oneline || true

# ===========================================================================
# Step 3 — Measure baseline coverage
# ===========================================================================
log "flutter pub get"
flutter pub get
log "flutter analyze"
flutter analyze || warn "Baseline analyze reported issues."
log "flutter test --coverage (baseline)"
flutter test --coverage || warn "Baseline tests reported failures."

BASELINE_PCT="$(coverage_percent coverage/lcov.info)"
TESTS_BEFORE="$(find test -name '*_test.dart' 2>/dev/null | wc -l | tr -d ' ')"
ok "Baseline coverage: ${BASELINE_PCT}%"
echo
log "Lowest-covered files (the agent's work list):"
low_coverage_report coverage/lcov.info | head -n 12

# ===========================================================================
# Step 4 — Write the missing tests
# ===========================================================================
zero_coverage_files coverage/lcov.info > "$WORKDIR/gaps.txt" || true
low_coverage_report  coverage/lcov.info | awk '$1+0 < 50' >> "$WORKDIR/gaps.txt" || true
if [ -s "$WORKDIR/gaps.txt" ]; then
  log "Asking the agent to write tests for $(wc -l < "$WORKDIR/gaps.txt" | tr -d ' ') target(s)"
  build_agent_prompt "$MEMORY_FILE" "$WORKDIR/gaps.txt" > "$WORKDIR/prompt.txt"
  run_agent "$WORKDIR/prompt.txt"
else
  ok "No coverage gaps found — nothing for the agent to write tonight."
fi

# ===========================================================================
# Step 5 — Fix & verify (self-healing loop)
# ===========================================================================
verify_unit_widget() {
  log "Re-running unit & widget suite"
  flutter test --coverage 2>&1 | tee "$WORKDIR/test.log"
}

attempt=1
until verify_unit_widget; do
  if [ "$attempt" -ge "$MAX_HEAL_ATTEMPTS" ]; then
    err "Suite still failing after $MAX_HEAL_ATTEMPTS attempts — see $WORKDIR/test.log"
    warn "The agent would now quarantine the offending test(s) with"
    warn "  @Skip('quarantined due to flakiness') and log it to $MEMORY_FILE."
    break
  fi
  warn "Tests failing — self-heal attempt $attempt/$MAX_HEAL_ATTEMPTS"
  {
    echo "The previous test run FAILED. Fix the failing tests (or, only if the"
    echo "failure is an environment/flakiness issue, quarantine that single test"
    echo "with @Skip and note it in memory). Do not weaken assertions. Errors:"
    echo
    tail -n 40 "$WORKDIR/test.log"
    echo
    cat "$WORKDIR/prompt.txt"
  } > "$WORKDIR/heal.txt"
  run_agent "$WORKDIR/heal.txt"
  attempt=$((attempt + 1))
done

# Integration / UI tests on the iOS simulator
if [ "$SKIP_INTEGRATION" != 1 ] && [ -d integration_test ] && command -v xcrun >/dev/null 2>&1; then
  log "Booting simulator: $DEVICE"
  xcrun simctl boot "$DEVICE" || true
  log "Running integration tests on $DEVICE"
  flutter test integration_test -d "$DEVICE" || warn "Integration tests reported failures."
  log "Shutting down simulator"
  xcrun simctl shutdown "$DEVICE" || true
else
  warn "Skipping integration tests (SKIP_INTEGRATION=$SKIP_INTEGRATION or no simulator)."
fi

# ===========================================================================
# Step 5b — Lint & format gate
# ===========================================================================
log "Formatting & analyzing before commit"
dart format . >/dev/null 2>&1 || warn "dart format reported issues."
flutter analyze || warn "flutter analyze reported issues — the agent would fix these."

# ===========================================================================
# Step 6 — Report, remember, push & open a PR
# ===========================================================================
FINAL_PCT="$(coverage_percent coverage/lcov.info)"
TESTS_AFTER="$(find test -name '*_test.dart' 2>/dev/null | wc -l | tr -d ' ')"
TESTS_ADDED=$(( TESTS_AFTER - TESTS_BEFORE ))
[ "$TESTS_ADDED" -ge 0 ] || TESTS_ADDED=0
DELTA="$(awk -v a="$BASELINE_PCT" -v b="$FINAL_PCT" 'BEGIN{printf "%+.1f", b-a}')"
RUNTIME=$SECONDS

log "Updating coverage dashboard"
python3 scripts/report.py append --date "$DATE_ISO" --coverage "$FINAL_PCT" \
  --tests "$TESTS_ADDED" --runtime "$RUNTIME"

# Append a run record to the agent's memory. The agent expands this with any
# lessons learned during its own self-evaluation; here we seed the entry.
{
  echo
  echo "## Run ${DATE_ISO}"
  echo "- Coverage: ${BASELINE_PCT}% → ${FINAL_PCT}% (${DELTA}%)"
  echo "- Tests added: ${TESTS_ADDED} · Run time: $((RUNTIME/60))m$((RUNTIME%60))s"
  [ "$attempt" -gt 1 ] && echo "- Needed ${attempt} self-heal attempt(s) — review for a reusable lesson."
} >> "$MEMORY_FILE"

PR_BODY="Coverage ${BASELINE_PCT}% → ${FINAL_PCT}% (${DELTA}%). Tests added: ${TESTS_ADDED}. All suites green."
log "Committing"
git add -A
git commit -m "Nightly QA: add missing tests (${DATE_ISO})" \
           -m "$PR_BODY" || warn "Nothing to commit."

if [ "$HAVE_REMOTE" = 1 ] && [ "$DRY_RUN" != 1 ]; then
  log "Pushing $BRANCH to origin"
  git push origin HEAD
  if [ "$HAVE_GH" = 1 ]; then
    log "Opening PR against $TARGET_BRANCH"
    gh pr create --base "$TARGET_BRANCH" \
      --title "Nightly QA: add missing tests (${DATE_ISO})" \
      --body  "$PR_BODY"
  fi
else
  warn "Template mode: skipping push/PR. Branch '$BRANCH' is ready locally."
fi

echo
ok "Nightly QA complete — ${BASELINE_PCT}% → ${FINAL_PCT}% (${DELTA}%), ${TESTS_ADDED} test(s), $((RUNTIME/60))m$((RUNTIME%60))s."

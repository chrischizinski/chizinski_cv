#!/usr/bin/env bash
# Monthly Scholar refresh, run by launchd (see install-scholar-schedule.sh) or
# by hand via `just monthly-scholar`. Refreshes the data and opens a PR; it
# never pushes to main. Posts a macOS notification with the outcome.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$HOME/Library/Logs/cv-scholar-refresh.log"
export PATH="/opt/homebrew/bin:/usr/local/bin:/Library/TeX/texbin:/usr/bin:/bin:$PATH"

notify() {
  osascript -e "display notification \"$1\" with title \"CV Scholar refresh\"" >/dev/null 2>&1 || true
}
fail() {
  echo "$(date '+%F %T') FAILED: $1" >>"$LOG"
  notify "Failed: $1 (see ~/Library/Logs/cv-scholar-refresh.log)"
  exit 1
}

mkdir -p "$(dirname "$LOG")"
exec >>"$LOG" 2>&1
echo "=== $(date '+%F %T') start"

cd "$REPO" || fail "repo not found at $REPO"
[ "$(git branch --show-current)" = "main" ] || fail "repo is not on main"
[ -z "$(git status --porcelain)" ] || fail "working tree has uncommitted changes"
git pull --ff-only -q || fail "git pull failed"

just refresh-scholar || { git checkout -q -- data bib; fail "Scholar fetch failed (blocked?)"; }

if git diff --quiet -- data bib; then
  echo "no changes"
  notify "Scholar data unchanged"
  exit 0
fi

just commit-scholar || fail "commit/PR step failed"
notify "Scholar refreshed - PR is ready to merge"
echo "=== done"

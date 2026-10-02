# Google Scholar data. CI cannot reach Scholar (HTTP 403 from GitHub runners),
# so the data is refreshed from this machine and committed.

default:
    @just --list

# Fetch fresh Scholar data and rebuild the .bib files; fails if Scholar blocks (no cache fallback).
refresh-scholar:
    FORCE_REFRESH=1 REQUIRE_FRESH=1 Rscript -e 'source("R/pull_citations.R")'
    @git status --short data bib

# Commit refreshed data on a new branch, push it and open a PR.
commit-scholar:
    #!/usr/bin/env bash
    set -euo pipefail
    if git diff --quiet -- data bib; then echo "No Scholar changes to commit."; exit 0; fi
    branch="chore/refresh-scholar-$(date +%Y-%m-%d)"
    git checkout -b "$branch"
    git add data bib
    git commit -m "chore: refresh Google Scholar data"
    git push -u origin "$branch"
    gh pr create --base main --title "chore: refresh Google Scholar data" \
      --body "Local refresh via just refresh-scholar (CI cannot reach Google Scholar)."
    git checkout main

# Run the whole monthly job once (what the scheduled agent runs).
monthly-scholar:
    scripts/scholar-refresh.sh

# Install the launchd agent: runs monthly-scholar on the 1st at 08:00 local time.
install-scholar-schedule:
    scripts/install-scholar-schedule.sh install

# Remove the launchd agent.
uninstall-scholar-schedule:
    scripts/install-scholar-schedule.sh uninstall

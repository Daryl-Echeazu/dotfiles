#!/bin/bash
# Commit and push whatever changed in ~/dotfiles.
#
# The stowed configs (~/.aerospace.toml, ~/.zshrc, ...) are symlinks into this
# repo, so editing them edits the repo directly. This script picks up the rest:
# the LaunchAgent plists (real files, since launchd doesn't follow symlinks
# reliably) and the Brewfile (regenerated from what's installed). Run by the
# local.dotfiles-sync LaunchAgent every hour; safe to run by hand any time.
#
# Refuses to commit if anything looks like a secret.

set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
DOT="$HOME/dotfiles"
cd "$DOT"

for plist in "$DOT"/macos/LaunchAgents/*.plist; do
  name=$(basename "$plist")
  # installed copies have the real home path; the repo keeps the __HOME__ placeholder
  [ -f "$HOME/Library/LaunchAgents/$name" ] && sed "s|$HOME|__HOME__|g" "$HOME/Library/LaunchAgents/$name" > "$plist"
done
brew bundle dump --force --file="$DOT/Brewfile" >/dev/null 2>&1 || echo "brew bundle dump failed; keeping old Brewfile"

git add -A
if git diff --cached --quiet; then
  exit 0
fi

# Anything resembling a token or private key stops the sync before it's public.
# (This script is excluded: it contains the patterns themselves.)
if git diff --cached -U0 -- . ':!scripts/sync.sh' | grep -E '^\+' | grep -qiE \
    '(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY|(api[_-]?key|secret|password|token)[[:space:]]*[=:][[:space:]]*["'"'"']?[A-Za-z0-9/+_-]{12,})'; then
  git reset -q
  echo "$(date '+%F %T') sync blocked: staged changes look like they contain a secret" >&2
  osascript -e 'display notification "Staged changes look like a secret — not pushed." with title "dotfiles sync blocked"' 2>/dev/null || true
  exit 1
fi

git commit -q -m "Sync $(date '+%Y-%m-%d %H:%M')" -m "$(git diff --cached --stat HEAD 2>/dev/null | tail -1)"
git push -q origin HEAD
echo "$(date '+%F %T') synced: $(git log -1 --format=%h)"

#!/bin/bash
# Set up a Mac from this repo:  git clone https://github.com/Daryl-Echeazu/dotfiles ~/dotfiles && ~/dotfiles/install.sh
#
# 1. Installs Homebrew if missing, then everything in the Brewfile.
# 2. Links the configs into ~ with GNU Stow (existing files are backed up to *.pre-dotfiles).
# 3. Installs and loads the LaunchAgents (Caps Lock -> Option, hourly dotfiles sync).

set -euo pipefail
DOT="$(cd "$(dirname "$0")" && pwd)"
PACKAGES=(aerospace zsh git)

if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
brew bundle --file="$DOT/Brewfile"

cd "$DOT"
for pkg in "${PACKAGES[@]}"; do
  # Move aside real files Stow would otherwise refuse to replace.
  for f in $(cd "$pkg" && find . -type f | sed 's|^\./||'); do
    if [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ]; then
      mv "$HOME/$f" "$HOME/$f.pre-dotfiles"
      echo "backed up ~/$f -> ~/$f.pre-dotfiles"
    fi
  done
  stow -t "$HOME" "$pkg"
done

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
for plist in "$DOT"/macos/LaunchAgents/*.plist; do
  name=$(basename "$plist")
  sed "s|__HOME__|$HOME|g" "$plist" > "$HOME/Library/LaunchAgents/$name"
  launchctl bootout "gui/$(id -u)/${name%.plist}" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/$name"
  echo "loaded ${name%.plist}"
done

echo "Done. Reload AeroSpace with alt-shift-; then esc, and open a new terminal."

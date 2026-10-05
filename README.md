# dotfiles

My Mac setup: [AeroSpace](https://github.com/nikitabobko/AeroSpace) tiling, zsh, git, a Caps Lock → Option remap, and the apps I install with Homebrew.

```sh
git clone https://github.com/Daryl-Echeazu/dotfiles ~/dotfiles && ~/dotfiles/install.sh
```

| Path | What |
|---|---|
| `aerospace/.aerospace.toml` | Tiling window manager. `alt-<letter>` jumps to a workspace (and opens its app: `alt-d` Discord, `alt-s` Spotify, `alt-e` Finder…); `alt-shift-<letter>` moves the window there |
| `zsh/` | `.zshrc`, `.zprofile` |
| `git/.gitconfig` | Identity and the `gh` credential helper |
| `macos/LaunchAgents/` | Caps Lock → Option (`hidutil`, at login) and the hourly sync below |
| `Brewfile` | Everything installed with Homebrew, regenerated on every sync |
| `install.sh` | Brew bundle, Stow links (backs up existing files), LaunchAgents |
| `scripts/sync.sh` | Commits and pushes changes; refuses anything that looks like a secret |

The configs in `aerospace/`, `zsh/` and `git/` are linked into `~` with [GNU Stow](https://www.gnu.org/software/stow/), so editing `~/.aerospace.toml` edits this repo. The `local.dotfiles-sync` LaunchAgent runs `scripts/sync.sh` every hour and pushes whatever changed (log: `~/Library/Logs/dotfiles-sync.log`).

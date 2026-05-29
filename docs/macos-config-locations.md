# macOS Configuration Locations

Five locations where applications store configuration on macOS.

| # | Location | Used by | Examples |
|---|----------|---------|---------|
| 1 | `~/.<app>` | Traditional Unix tools | `.claude/`, `.codex/`, `.gitconfig`, `.tmux.conf` |
| 2 | `~/.config/<app>/` | XDG-aware tools | `gh/`, `ghostty/`, `cheat/` |
| 3 | `~/Library/Application Support/<app>/` | macOS GUI apps | Cursor, VS Code, Claude Desktop |
| 4 | `~/Library/Preferences/` | macOS plists (`defaults write`) | Dock, Finder, keyboard repeat rate |
| 5 | `/opt/homebrew/etc/` | Homebrew service configs | nginx, postgresql, dnsmasq |

## Notes

- **#1 and #2** are the main targets for dotfiles symlinks. Many tools support both, but newer tools tend toward XDG (`~/.config/`).
- **#3** is where macOS GUI apps store config. Symlinks work but paths are long and app-specific.
- **#4** is managed via `defaults write com.apple.dock autohide -bool true` style commands, not files. Typically scripted in a `macos-defaults.sh` rather than symlinked.
- **#5** is mostly for daemons and services. CLI tools installed via Homebrew still read config from #1 or #2, not from Homebrew's prefix.

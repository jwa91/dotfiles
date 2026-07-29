# Dotfiles task interface.

# List available tasks.
default:
    @just --list

# Run the full bootstrap.
bootstrap:
    ./setup/bootstrap.sh

# Preview the full bootstrap without changing files.
dry-run:
    ./setup/bootstrap.sh --dry-run

# Run all doctor checks.
doctor:
    ./setup/doctor.sh

# Audit project runtime ownership under ~/developer.
project-audit:
    ./setup/project-audit.sh

# Alias for doctor.
check:
    ./setup/doctor.sh

# Install missing Homebrew entries without upgrading existing apps.
brew-sync:
    HOMEBREW_BUNDLE_NO_UPGRADE=1 brew bundle --file=Brewfile

# Check Brewfile presence without upgrading.
brew-check:
    HOMEBREW_BUNDLE_NO_UPGRADE=1 brew bundle check --verbose --file=Brewfile

# Check declared formulae for known vulnerabilities (Homebrew 6+).
brew-vulns:
    brew vulns --brewfile=Brewfile

# Show updates owned by Homebrew, excluding self-updating GUI apps.
brew-outdated:
    HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1 brew outdated

# Upgrade formulae and Homebrew-owned casks, excluding self-updating GUI apps.
brew-upgrade:
    HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1 brew upgrade

# Show Homebrew entries not declared in Brewfile. Does not remove anything.
brew-cleanup:
    -brew bundle cleanup --file=Brewfile

# Run only the link step.
links:
    ./setup/bootstrap.sh --only links

# Apply managed macOS default file associations.
default-apps:
    ./setup/bootstrap.sh --only default-apps

# Seed machine-local config files from repo examples.
local-config:
    ./setup/bootstrap.sh --only local-config

# Install mise-managed language toolchains declared by the dotfiles.
toolchains:
    ./setup/bootstrap.sh --only toolchains

# Recreate managed symlinks.
reset-links:
    ./setup/bootstrap.sh --only links --reset

# Update local command-help caches.
help:
    ./setup/bootstrap.sh --only help

# Install or update explicit zsh plugins.
zsh:
    ./setup/bootstrap.sh --only zsh --update

# Print manual setup steps.
manual:
    ./setup/bootstrap.sh --only manual

# Open OrbStack to finish interactive setup after install.
orbstack:
    open -a OrbStack

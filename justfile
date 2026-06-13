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

# Alias for doctor.
check:
    ./setup/doctor.sh

# Install missing Homebrew entries without upgrading existing apps.
brew-sync:
    HOMEBREW_BUNDLE_NO_UPGRADE=1 brew bundle --file=Brewfile

# Check Brewfile presence without upgrading.
brew-check:
    HOMEBREW_BUNDLE_NO_UPGRADE=1 brew bundle check --verbose --file=Brewfile

# Show Homebrew entries not declared in Brewfile. Does not remove anything.
brew-cleanup:
    -brew bundle cleanup --file=Brewfile

# Run only the link step.
links:
    ./setup/bootstrap.sh --only links

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

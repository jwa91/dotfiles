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

# Initialize every managed machine capability.
init:
    ./setup/init.sh all

# Converge all repository-controlled configuration.
set:
    ./setup/set.sh all

# Run all doctor checks.
doctor:
    ./setup/doctor.sh all

# Audit project runtime ownership under ~/developer.
project-audit:
    ./setup/doctor.sh projects

# Alias for doctor.
check:
    ./setup/doctor.sh all

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

# Install what's missing, then list strays. Presence only: never upgrades,
# never removes. Backs the `brewsync` shell wrapper.
brew-converge: brew-sync brew-cleanup

# Run only the link step.
links:
    ./setup/set.sh links

# Apply managed macOS default file associations.
default-apps:
    ./setup/set.sh default-apps

# Seed machine-local config files from repo examples.
local-config:
    ./setup/set.sh local-config

# Install mise-managed language toolchains declared by the dotfiles.
toolchains:
    ./setup/init.sh toolchains

# Recreate managed symlinks.
reset-links:
    ./setup/set.sh links --reset-links

# Update local command-help caches.
help:
    ./setup/init.sh command-help

# Install or update explicit zsh plugins.
zsh:
    ./setup/init.sh zsh --update-plugins

# Print manual setup steps.
manual:
    ./setup/init.sh manual

# Open OrbStack to finish interactive setup after install.
orbstack:
    open -a OrbStack

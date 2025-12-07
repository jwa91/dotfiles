This is my personal migration guide for setting up a fresh MacBook. It's opinionated and assumes a specific toolchain:

- **Password Manager / SSH Agent**: 1Password
- **Package Manager**: Homebrew (everything goes through Brew)
- **Shell**: Zsh with Starship prompt
- **Terminal**: Ghostty
- **JavaScript**: Bun + pnpm
- **Python**: uv (Ruff as main)
- **Editors**: Cursor, (VS Code backup)

The guide follows a deliberate order — each phase builds on the previous:

| Phase             | Purpose                             |
| ----------------- | ----------------------------------- |
| 1. Foundation     | macOS setup, security, accounts     |
| 2. Enablers       | Xcode CLI tools, Homebrew           |
| 3. Identity & SSH | 1Password, SSH keys, authentication |
| 4. Git            | Clone dotfiles, configure Git       |
| 5. Shell & Tools  | Zsh, terminal, dev runtimes         |
| 6. Applications   | GUI apps, editor & AI configs       |

## Phase 1: The Foundation (System & Accounts)

_Do this before installing any software to avoid permission headaches later._

### 1.1 Update macOS

Run `softwareupdate --all --install --force` or check System Settings. Do this first to ensure Xcode tools match your OS version.

### 1.2 User Accounts (Security Best Practice):

Create a separate Admin account (managed by you) and downgrade your daily driver account to Standard user. This prevents accidental system-wide changes and limits malware reach.

**macOS prompts for **admin credentials** when needed anyway — so even with an admin daily account, you’re already in a pseudo “standard + escalate” model. This makes the security model **explicit and safer\*_._

### 1.3 FileVault

Turn on FileVault (Disk Encryption) immediately in System Settings > Privacy & Security.

### 1.4 HostName

Give your machine a recognizable name (useful for networking/terminal prompts).

```bash
sudo scutil --set HostName "dev-macbook"
sudo scutil --set ComputerName "dev-macbook"
sudo scutil --set LocalHostName "dev-macbook"
```

## Phase 2: The Enablers

_The core dependencies for everything else._

### 2.1 Xcode Command Line Tools

You rarely need the full Xcode app (~40GB) immediately. Start with just the [CLI tools](https://developer.apple.com/documentation/xcode/installing-the-command-line-tools/) (~600MB).

```bash
xcode-select --install
```

### 2.2 Homebrew

[The Package Manager](https://brew.sh/). Never install tools (Node, Git, Python) manually. Use Brew.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Phase 3: Identity and SSH

_Establish cryptographic identity and a reusable SSH foundation._

### 3.1 Install 1password

[1Password](https://developer.1password.com/docs/cli/get-started) will be our SSH agent. Install both the desktop app and the CLI:

```bash
brew install --cask 1password
brew install 1password-cli
```

Roles:

- **Desktop app** → owns:
  - SSH agent
  - private key storage
  - Touch ID / Apple Watch auth
- **CLI (op)** → gives you:
  - terminal access to vaults
  - automation
  - scripting
  - future Git signing / secrets injection

### 3.2 Sign in to 1Password using the desktop app

1. Sign in
2. Enable:
   - Start at login
   - Keep in menubar
3. Enable **SSH Agent** in **Settings → Developer**

### 3.3 Sign in to 1Passord CLI

1. Sign in:

```bash
op signin
```

1. Verify:

```bash
op whoami
```

<aside>
ℹ️

### Before we continue

It helps to briefly explain the general set up. We will maintain one SSH key per security domain, in my case i start with 2:

- GitHub key → Git operations only
- Hetzner key → VPS access only
</aside>

### 3.4 Generate the SSH key’s in the 1Password app

_As of now, the official, fully supported way to generate SSH keys for the 1Password SSH agent is still via the desktop app UI. The CLI can manage SSH items, but key generation + agent registration is still primarily app-driven on macOS._

1. Go to your **Personal / Private** vault
2. **New Item → SSH Key**
3. Click **Add Private Key → Generate New Key**
4. Use type **Ed25519**
5. Give it a clear title like:

   `GitHub – MacBook Pro 2025`

6. Save
7. Repeat for Hetzner

Now 1Password holds:

- private key
- public key
- fingerprint

No ssh-keygen needed on the Mac.

### 3.5 Prepare Public Keys locally

1. Open 1Password.
2. Select your **GitHub** key item.
3. Under the section "public key", click only on the key code (starts with `ssh-ed25519...`) to copy it.
4. Create the file:

```bash
mkdir -p ~/.ssh
nano ~/.ssh/github.pub
```

1. Paste the public key and save.
2. Repeat this for your **Hetzner** key (e.g., `~/.ssh/hetzner.pub`).

### 3.6 Register Keys at Services

**Github**

1. Copy the **public** key to your clipboard:

```bash
pbcopy < ~/.ssh/github.pub
```

1. Go to [GitHub Settings > SSH and GPG keys](https://github.com/settings/keys).
2. Click **New SSH key**.
3. Title: `Dev MacBook Pro 2025` (or similar).
4. Key type: **Authentication Key**.
5. Paste the key and save.

**Hetzner**

1. Log in to the [Hetzner Cloud Console](https://console.hetzner.cloud/) in your browser.
2. Select your server and click the **>\_ (Console)** icon to open the terminal window.
3. Log in with your credentials
4. Open the authorized keys file:

```bash
nano ~/.ssh/authorized_keys
```

1. Add the public key **on a new line\***

\*_just `cmd` `v` doesnt work in a browser console like this, but you can do right mouse click paste._

1. Save and exit.

### 3.7 Configure SSH Config

Back in the terminal of the macbook, create and edit the SSH config file

```bash
nano ~/.ssh/config
```

Add the following configuration:

```toml
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

Host github.com
  User git

Host hetzner
  HostName <YOUR_VPS_IP_OR_HOSTNAME>
  User jw
```

1. Ensure 1Password is unlocked
2. Run the GitHub test:

```bash
ssh -T git@github.com
```

_Expected output: “Hi [username]! You’ve succesfully authenticated”_

## Phase 4: Git

_Configure Git identity and preferences from dotfiles._

### 4.1 Clone the dotfiles repo

```bash
git clone git@github.com:jwa91/dotfiles.git ~/dotfiles
```

### 4.2 Run the Git setup script

```bash
cd ~/dotfiles/git
./setup.sh
```

This creates the symlink.

### 4.3 Verify

```bash
git config --global --list
```

**What the dotfiles `git/` folder contains:**

| 📂 File               | 🎯 Purpose                          |
| --------------------- | ----------------------------------- |
| `config`              | Global Git configuration            |
| `commit_template.txt` | Template shown when writing commits |
| `setup.sh`            | Symlinks config to `~/.gitconfig`   |

## Phase 5: Shell, Terminal & Prompt

_Bootstrap the shell environment and install the developer ecosystem._

### 5.1 Install Zsh Configuration

Run the first setup script. This focuses \***\*only\*\*** on making your terminal look correct and behave smartly. It installs core shell dependencies (`starship`, `fzf`), sets up your plugins, and symlinks your config files (including Ghostty and Starship).

```bash
cd ~/dotfiles/zsh/setup
./install-zsh.sh
```

**What this does:**

- Installs Starship (prompt) & FZF (search)
- Symlinks `.zshrc`, `.zshenv`, etc.
- Sets up Ghostty config
- Creates `~/Developer` and other base directories

_Restart your terminal (or open a new tab) after this step to see the new prompt._

![I really like the look of it!](attachment:50bbc6ec-11dc-46f3-aa86-c01cdfce502f:Screenshot_2025-12-05_at_23.06.02.png)

I really like the look of it!

### 5.2 Install Developer Tools

Now that the shell is ready, install your actual work tools. This script uses Homebrew Bundle to install everything defined in `Brewfile` (Node, Python/uv, Bun, Ghostty App, Fonts, etc.).

```bash
./install-tools.sh
```

**What this does:**

- Installs **Language Runtimes**: `bun`, `pnpm`, `uv`
- Installs **GUI Apps**: `ghostty`
- Installs **Fonts**: `JetBrainsMono Nerd Font`
- Clones **Templates**: Fetches your Python templates to `~/Developer/templates`

To learn more about that last thing, see the dedicated [Git repository](https://github.com/jwa91/python-template).

## Phase 6: Applications & Config

_Install GUI apps and symlink their configurations._

### 6.1 Install Applications

With the shell script..

```bash
cd ~/dotfiles/config/setup
./install-apps.sh
```

..the following Brewfile will get installed:

```bash
# Development & IDEs
cask "cursor"
cask "visual-studio-code"

# AI & LLM Tools
cask "claude"
cask "claude-code"
cask "codex"
cask "ollama"

# Productivity & Utilities
cask "raycast"
cask "hiddenbar"

# Browsers & Communication
cask "brave-browser"
cask "whatsapp"
cask "telegram"

# Media
cask "spotify"

# CLI Tools
brew "gh"
brew "tree"
brew "curl"
brew "cheat"
```

### 6.2 **Link Application Configs**

Symlink all application settings to your dotfiles:

```bash
./link-apps.sh
```

**What this does:**

- Links **Cursor** settings, keybindings, snippets, and MCP config
- Links **VS Code** settings, keybindings, snippets
- Links **Claude Desktop** config
- Links **Claude Code** settings, commands, and agents
- Links **Codex** config and instructions
- Links **GitHub CLI** config
- Links **Cheat** config and personal cheatsheets

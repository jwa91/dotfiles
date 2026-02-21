# Mobile Shell Ideas

Brainstorming document for mobile-specific dotfiles behavior.
Triggered by `TERM_DEVICE=mobile` (set by Termius on connect via Mosh/SSH).

## Architecture: Single Routing Point

Route once in `.zshrc` at a high level — everything mobile-specific flows from there.

```zsh
# .zshrc (early, before other sources)
if [[ "$TERM_DEVICE" == "mobile" ]]; then
  export IS_MOBILE=1
  source "$ZSH_DIR/mobile.zsh"
fi
```

Individual config files can check `IS_MOBILE` if they need to, but `mobile.zsh`
handles most overrides in one place. This avoids scattering conditionals everywhere.

---

## 1. Prompt: ASCII-safe, compact

**Problem:** Mosh can't render Nerd Font glyphs (PUA Unicode width bug).
A full Starship prompt also wastes precious screen width on a phone.

**Solution:** Swap Starship config on mobile.

```zsh
export STARSHIP_CONFIG="$CONFIG_DIR/starship-mobile.toml"
```

`starship-mobile.toml` ideas:
- Replace all Nerd Font icons with ASCII equivalents or plain emoji
- Drop language version / docker / conda segments entirely
- Shorter directory truncation (1 level)
- Drop the time segment (phone has a clock)
- Single-line prompt (no `line_break`)
- Example: `mac jw ~/Dev/proj main > `

---

## 2. Clipboard over SSH/Mosh

**Problem:** `pbcopy` only works locally. On mobile, it writes to the Mac
clipboard — not the phone clipboard.

**Solution:** OSC 52 escape sequence. Termius supports this (free feature).
The terminal emulator intercepts the escape and copies to the device clipboard.

```zsh
osc-copy() {
  local data
  data=$(base64 < /dev/stdin)
  printf '\033]52;c;%s\a' "$data"
}

# Override pbcopy on mobile
alias pbcopy='osc-copy'
```

This means all existing aliases/functions that pipe to `pbcopy` (like `pass`)
just work on mobile without changes.

---

## 3. Editor Override

**Problem:** `open_in_editor` tries Cursor / VS Code — useless over SSH.

**Solution:** Override to a terminal editor on mobile.

```zsh
open_in_editor() { ${EDITOR:-nano} "$1"; }
```

Options for `EDITOR`:
- `nano` — zero learning curve, already installed
- `micro` — modern keybindings (ctrl+s, ctrl+c), mouse support, good for mobile
- `vim` — if comfortable with it

---

## 4. Auto-tmux with Session Switching

**Problem:** Mosh reconnects but drops you in a bare shell. Need persistence.

**Solution:** Auto-attach on mobile, with a switcher to hop to desktop sessions.

```zsh
# auto-attach to mobile tmux session
if [[ -z "$TMUX" ]]; then
  tmux new-session -A -s mobile
fi

# session switcher (works from inside tmux)
ts() {
  if [[ -n "$1" ]]; then
    tmux switch-client -t "$1"
  else
    local session
    session=$(tmux list-sessions -F '#{session_name}' \
      | fzf --height=40% --reverse --prompt="switch to: ")
    [[ -n "$session" ]] && tmux switch-client -t "$session"
  fi
}
```

---

## 5. Safety Rails

**Problem:** Phone keyboard = fat fingers = destructive typos.

```zsh
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'
```

---

## 6. Short Aliases

**Problem:** Typing on glass is slow and error-prone.

```zsh
alias g='git status'
alias gp='git push'
alias gl='git log --oneline -10'
alias d='cdd'
alias l='ls -la'
alias c='clear'
alias j='jobs'
```

---

## 7. Quick Notes to Obsidian

Jot a thought from mobile straight into the vault inbox:

```zsh
note() {
  local file="$VAULT_PATH/Inbox/$(date +%Y-%m-%d).md"
  echo "- $(date +%H:%M) $*" >> "$file"
  echo "noted."
}
```

---

## 8. Tailscale Helpers

Tailscale is the network backbone of this setup. Quick access:

```zsh
alias tsst='tailscale status'
alias tsip='tailscale ip -4'
```

---

## 9. Phone-to-Mac Screenshot Pipeline (for dev agents)

**Use case:** Working on a Swift app. An AI agent is running on the desktop
(Claude Code, Cursor agent, etc.) and needs a screenshot of the current app
state on a real device. Instead of using the simulator, take a real screenshot
on the phone and drop it into the project.

### Flow

```
Phone: take screenshot
  → Taildrop (free) sends it to Mac
    → landing script renames + moves it into the project
      → agent picks it up
```

### Implementation ideas

**a) Taildrop receive watcher**

Taildrop files land in `~/Downloads/` (or a configured dir). A watcher moves
them into the active project:

```zsh
# set the active project for screenshot delivery
screenshot-target() {
  export SCREENSHOT_PROJECT="$1"
  echo "screenshots → $1"
}

# watch for incoming taildrop screenshots and move them
screenshot-watch() {
  local dest="${SCREENSHOT_PROJECT:-.}/screenshots"
  mkdir -p "$dest"
  fswatch -0 ~/Downloads/*.png ~/Downloads/*.jpg 2>/dev/null \
    | while IFS= read -r -d '' file; do
        local name="device-$(date +%Y%m%d-%H%M%S)${file:t:e}"
        mv "$file" "$dest/$name"
        echo "moved: $name → $dest/"
      done
}
```

**b) Simpler: one-shot pull**

After taking a screenshot on the phone and sending via Taildrop:

```zsh
# grab latest screenshot from downloads into current project
grab-screenshot() {
  local latest
  latest=$(ls -t ~/Downloads/IMG_*.{png,jpg,PNG,JPG,HEIC} 2>/dev/null | head -1)
  if [[ -z "$latest" ]]; then
    echo "no screenshot found in ~/Downloads"
    return 1
  fi
  local dest="${1:-.}/screenshots"
  mkdir -p "$dest"
  local name="device-$(date +%Y%m%d-%H%M%S).${latest:e}"
  mv "$latest" "$dest/$name"
  echo "$dest/$name"
}
```

**c) Agent integration**

If using Claude Code or similar, the agent can be told:
> "The latest device screenshot is at ./screenshots/device-*.png — use the most
> recent one for visual feedback."

Or add a project convention file:

```markdown
<!-- .claude/device-screenshots.md -->
Device screenshots from the physical iPhone are placed in ./screenshots/
by the `grab-screenshot` command. Use the most recent file for UI review.
```

**d) Shortcut automation (iOS side)**

Create an iOS Shortcut:
1. Trigger: screenshot taken (or manual)
2. Action: Share → Taildrop to Mac
This makes the flow: screenshot → one tap → lands on Mac.

---

## 10. System Status Dashboard

Quick overview when checking on your machine from the couch:

```zsh
dashboard() {
  echo "--- machine ---"
  scutil --get ComputerName
  uptime
  echo ""
  echo "--- disk ---"
  df -h / | tail -1
  echo ""
  echo "--- network ---"
  tailscale status --peers=false 2>/dev/null || echo "(tailscale not running)"
  echo ""
  echo "--- tmux ---"
  tmux list-sessions 2>/dev/null || echo "(no sessions)"
  echo ""
  echo "--- git ($(basename $PWD)) ---"
  git status -sb 2>/dev/null || echo "(not a repo)"
}
```

---

## 11. Smart `COLUMNS`/`LINES` Defaults

Mosh sometimes reports wrong terminal size. Force sensible mobile defaults:

```zsh
if [[ "$COLUMNS" -gt 120 ]]; then
  # probably stale value from desktop, phone is ~40-80 cols
  export COLUMNS=80
fi
```

Or just set `TERM` options that help tools wrap better on small screens.

---

## 12. Claude Code Mobile Interface (`cm`)

**The core insight:** `claude -p "..." --resume $SESSION_ID` is texting Claude Code.
No TUI, no Nerd Font rendering, no small-screen issues — just text in, text out.
This is the most phone-native interface to Claude Code possible.

On desktop you use the full interactive TUI. On mobile you "text" the same
session via `-p` mode. Both sides see the same conversation. The session
persists across both.

### How it fits aw's architecture

aw already has the infrastructure:

- ntfy notifications with copy-pasteable commands
- `aw-resume --id <id>` as the phone entry point
- Dedicated tmux socket (`tmux -L aw`)
- Feature state files (`.aw/{feature-id}.json`)
- Three human intervention points: sharpen req, approve plan, review PR

Claude Code's `-p` + `--resume` slots directly into these intervention points.
Instead of attaching to a tmux session and fighting the TUI on a phone screen,
you send targeted messages to the running session.

### Session tracking via hooks

A Claude Code Stop hook captures the session ID and stores it in aw's state:

```bash
# Hook: runs when Claude Code's agent loop stops
# Writes session ID to aw feature state + global last-session file

SESSION_ID="$CLAUDE_SESSION_ID"  # exposed by Claude Code to hooks
FEATURE_STATE=$(find .aw -name '*.json' -newer .aw/config.yml | head -1)

if [[ -n "$SESSION_ID" ]]; then
  echo "$SESSION_ID" > ~/.aw/last-claude-session
fi

# ntfy notification with context
curl -s \
  -H "Authorization: Bearer $NTFY_CLAUDE_TOKEN" \
  -H "Title: Claude stopped" \
  -H "Tags: robot" \
  -d "Session: $SESSION_ID
Resume: cm \"continue\"" \
  https://ntfy.janwillemaltink.com/claude
```

### The `cm` wrapper (claude mobile)

Minimal typing. Everything defaults to "continue the most recent session."

```zsh
# claude mobile — text-based interface to Claude Code sessions
cm() {
  local session_id
  session_id=$(cat ~/.aw/last-claude-session 2>/dev/null)

  if [[ $# -eq 0 ]]; then
    # no args: show status of current session
    if [[ -z "$session_id" ]]; then
      echo "no active session"
      return 1
    fi
    claude -p "Brief status: what did you do, what's next, any blockers?" \
      --resume "$session_id" \
      --output-format text
    return
  fi

  # with args: send message to session
  claude -p "$*" \
    --resume "$session_id" \
    --allowedTools "Read,Glob,Grep,Bash(git diff *),Bash(git log *),Bash(git status *)" \
    --output-format text
}
```

### Pre-built commands (one-tap from ntfy notification)

These map to aw's intervention points. Each is a single short command.

```zsh
# approve and continue (aw-plan gate, aw-req gate)
cm-go() { cm "Approved. Continue with the next step."; }

# structured status report
cm-status() {
  local session_id=$(cat ~/.aw/last-claude-session 2>/dev/null)
  claude -p "Status report: current phase, tasks done/remaining, blockers." \
    --resume "$session_id" \
    --output-format json \
    --json-schema '{"type":"object","properties":{"phase":{"type":"string"},"done":{"type":"array","items":{"type":"string"}},"remaining":{"type":"array","items":{"type":"string"}},"blockers":{"type":"array","items":{"type":"string"}}}}'
}

# park the session (graceful pause with handoff note)
cm-park() { cm "Stop here. Write a handoff note: what's done, what's next, any gotchas."; }

# diff summary
cm-diff() { cm "Summarize the changes you've made so far. Be brief."; }

# resume with full tool access (for when you trust it to act)
cm-auto() {
  local session_id=$(cat ~/.aw/last-claude-session 2>/dev/null)
  claude -p "${1:-Continue autonomously. Commit when tasks are done.}" \
    --resume "$session_id" \
    --allowedTools "Read,Edit,Write,Glob,Grep,Bash" \
    --output-format text
}
```

### Per-phase mobile interactions

Different aw phases have different mobile patterns:

```
PHASE         MOBILE PATTERN                    TYPICAL COMMANDS
─────         ──────────────                    ────────────────
aw-req        conversational (back-and-forth)   cm "OAuth with Google only"
                                                cm "just /dashboard for now"
                                                cm-go (when requirements are sharp)

aw-plan       review + approve                  cm (status — shows plan summary)
                                                cm "what are the parallel tasks?"
                                                cm-go (approve plan)

aw-build      monitor + unstick                 cm (status — tasks done/remaining)
                                                cm "try AuthConfig instead of AuthOptions"
                                                (mostly autonomous, you just monitor)

aw-review     trigger + check                   cm "create the PR"
                                                cm-diff
                                                (then review PR in GitHub mobile app)
```

### ntfy notification templates per phase

Notifications are actionable — contain the exact command to run:

```
── plan ready ──────────────────────
🤖 feat/42-auth — plan ready

4 tasks, 2 can run parallel.
Est: ~15 min build time.

  cm          (see plan)
  cm-go       (approve)
────────────────────────────────────

── stuck ───────────────────────────
⚠️ feat/42-auth — stuck on task 3

Type error in auth.ts:15.
Same error 3 times, escalating.

  cm          (see details)
  cm "try X"  (give direction)
────────────────────────────────────

── build complete ──────────────────
✅ feat/42-auth — all tasks done

4/4 tasks, 12 commits, all tests pass.

  cm-diff     (see changes)
  cm "create the PR"
────────────────────────────────────
```

### Screenshot pipeline + Claude Code (multimodal)

This connects idea #9 with `cm`. Claude Code can read images.

```
Phone: screenshot Swift app → Taildrop to Mac
Phone: cm "screenshot arrived in ~/Downloads. Compare it to the mockup in docs/design.png"
```

Claude Code (via --resume) receives the message, reads both images, and reports
visual differences. No simulator needed. Your phone IS the test device AND the
remote control.

Extend it:

```zsh
# grab screenshot + send to Claude for analysis in one command
cm-screenshot() {
  local latest=$(ls -t ~/Downloads/IMG_*.{png,jpg,PNG,JPG,HEIC} 2>/dev/null | head -1)
  if [[ -z "$latest" ]]; then
    echo "no screenshot found"
    return 1
  fi
  local dest="./screenshots/device-$(date +%Y%m%d-%H%M%S).${latest:e:l}"
  mkdir -p ./screenshots
  mv "$latest" "$dest"
  cm "New device screenshot at $dest — review it and compare to the design."
}
```

### Session continuity across desktop ↔ mobile

The same session ID works from both sides:

```
Desktop:  claude (interactive TUI) → working on feature → need to leave
Desktop:  /compact or just close terminal
          → Stop hook fires → captures session ID → ntfy notification

Phone:    get notification → "Claude stopped on feat/42-auth"
Phone:    cm "continue, focus on the tests"
          → claude -p "..." --resume $SID
          → Claude picks up exactly where it left off

Desktop:  come back later
Desktop:  claude --resume $(cat ~/.aw/last-claude-session)
          → back in full TUI, same conversation
```

No state is lost. The conversation is the same whether you're in TUI or `-p` mode.

### Considerations

- **Tool permissions**: On mobile, `cm` defaults to read-only tools (Read, Glob, Grep,
  git status/diff/log). Use `cm-auto` explicitly when you want Claude to write/edit.
  This prevents accidental changes from fat-finger typos.

- **Output length**: `-p` mode outputs everything to stdout. On a phone screen, long
  outputs scroll badly. Consider piping through a pager or truncating:
  ```zsh
  cm() { ... | head -50; }
  ```

- **`--continue` vs `--resume`**: `--continue` always picks up the most recent session
  on the machine. `--resume $SID` is explicit. For aw, prefer `--resume` since
  multiple features may have active sessions.

- **Cost**: Each `cm` call is an API round-trip. Short status checks are cheap.
  `cm-auto` with full tool permissions can get expensive if Claude goes deep.
  aw's model routing could apply here too (use Haiku for status checks, Opus for
  complex direction changes).

---

## Ideas Parking Lot

Things to explore later or that need paid features / more setup:

- **Wake-on-LAN via Tailscale** — wake the Mac from mobile when it sleeps
- **Long-running command notifications** — push notify phone when a build/test finishes (ntfy.sh is free and self-hostable)
- **Mobile tmux layout** — auto-set tmux to a single-pane layout (no splits, since phone is narrow)
- **Tailscale Funnel** — expose a local dev server to the phone for testing (free feature)
- **Photo → project pipeline** — like screenshots but for reference photos, mockups, etc.
- **Voice note → text** — record on phone, Taildrop the audio, whisper transcribes on Mac
- **`zsh-doctor` mobile check** — add Tailscale and Mosh to the doctor checks

---

## Priority Order

| # | Idea | Impact | Effort |
|---|------|--------|--------|
| 1 | Single routing point (`mobile.zsh`) | foundation | low |
| 2 | ASCII prompt (`starship-mobile.toml`) | fixes broken glyphs | low |
| 3 | Clipboard via OSC 52 | fixes `pbcopy` | low |
| 4 | Editor override | fixes `edit_zsh` etc. | trivial |
| 5 | Auto-tmux + session switcher | session persistence | low |
| 6 | Short aliases + safety rails | quality of life | trivial |
| 7 | Screenshot pipeline | dev workflow | medium |
| 8 | Dashboard | convenience | low |
| 9 | Quick notes | convenience | trivial |
| 10 | Notifications | nice to have | medium |

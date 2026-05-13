# Security Ground Rules

Single source of truth for how secrets, tokens, and identities are handled across all my projects (laptop, VPS, CI, agents). Reference this file from any project's `AGENTS.md` / `CLAUDE.md` instead of repeating the rules.

> **Mental model.** Two questions decide everything: *who is acting?* and *what is the smallest scope they need?* Pick the auth that matches both. The rest follows.

---

## Rule 1 — Identity by actor

Three actor classes, three auth styles:

| Actor | What they are | Auth | Storage |
|-------|---------------|------|---------|
| **Me** | Human, hands on keyboard, holding the laptop | SSH key + `gh auth login` | macOS Keychain (gh manages it) + ssh-agent |
| **Local automation** | GoReleaser, jwa-tobrew, Claude Code, agent in a container — anything that isn't *me* but runs on a machine I trust | Scoped PAT, runtime-injected | 1Password (canonical), env var at runtime |
| **Remote automation** | VPS webhook, GitHub Actions runner, Cloud Run job | Scoped PAT or read-only SSH deploy key | Remote secret store, mirrored from 1Password |

The trust boundary is *me with the laptop*. Anything that isn't me holding the keys gets a token, and that token gets the smallest scope that still lets it do its job.

## Rule 2 — One source of truth, and it is 1Password

- Every long-lived secret has exactly one item in 1Password.
- Local copies (`gh`'s keychain, ssh-agent, app keychain entries) are **caches** that can be re-derived from 1P. They are not the source of truth.
- **No `.env` files**. Ever.
  - Not in repos
  - Not in `~/.config`
  - Not in CI runners
  - Not in containers
- A `.env.template` may be checked in — but it contains `op://` references, never values.
- Runtime injection: `op run --env-file=.env.template -- <command>`. Resolved values exist only in the spawned process tree.
- Anything not in 1P is a smell. Bring it in or revoke it.

## Rule 3 — Least privilege, narrowly per task

- One token = one repo (or one well-defined scope, e.g. "all reads in org X").
- One automation = one token. No sharing across automations, no sharing across machines.
- Naming convention: `<service>-<scope>-<role>` — examples:
  - `homebrew-tap-writer` (writes to homebrew-tap repo only)
  - `vps-trnscrb-deploy` (reads trnscrb repo only)
  - `ci-myproject-releaser` (writes releases on myproject repo only)
- A compromised token should be able to damage exactly the thing it was issued for. Nothing else.

## Rule 4 — Rotation policy

- **Tokens**: 90-day expiration as the default. Rotation prompted at <14 days remaining.
- **Rotation should be frictionless**: the tool that uses the token should know how to rotate it. Open the regen page, prompt for the new value (echo disabled), validate against GitHub, write back to 1P. No copy-paste-into-1P-app step.
- **SSH keys**: never on a schedule. Rotate only on suspected compromise or machine retirement.
- **HMAC secrets** (webhooks, etc.): never on a schedule. Per-service. Rotate when the service rotates.

## Rule 5 — No secrets in logs, ever; usage IS logged

- Tokens are never printed to stdout, stderr, log files, or telemetry.
- Tokens are never serialised into command argv (visible in `ps`).
- Tokens are passed via env vars to child processes; restored/unset on return.
- **Usage is logged**: each invocation of a secret-aware tool appends a line to a local log (timestamp, command, exit code, subcommand) so I can audit what touched what. The log records the *use*, never the value.

## Rule 6 — Audit ledger lives in 1Password

- Quarterly: filter 1P by tag `automation-token`, confirm every item has:
  - A current expiration
  - A clear name (matches Rule 3 convention)
  - A `notesPlain` saying what it does and which automation uses it
  - A `username` field naming the repo/scope
- Anything else with a token (env var in shell rc, file on disk, baked into a Docker image) is a violation.

## Rule 7 — Explicit, not magic, defaults

- Tools must require their token reference to come from project config or env, never hardcoded in the tool's source.
- Defaults are sensible but explicit (e.g. `BREWTAP_TOKEN_OP_ITEM` env var, or a `tap.toml` config file). Never "if no config, use this UUID I shipped in the binary".
- The reason: I should be able to fork any tool and use it for my own scopes without editing source.

## Rule 8 — Pull, don't push, when possible

- Webhook + pull-deploy beats push-deploy (the secret lives on the server side, not in CI).
- Read-only deploy keys for service repos. Writes (e.g. tap commits) are limited to specific automations holding scoped PATs.
- This is what the VPS already does — extend it where reasonable.

---

## Per-project checklist

When starting or auditing a project:

- [ ] No `.env` files present (only `.env.template` with `op://` references)
- [ ] All long-lived secrets traced back to a 1P item with a clear name + expiration
- [ ] Each automation has its own scoped PAT, not a shared one
- [ ] Tool-source contains no hardcoded UUIDs or secret references
- [ ] `gh auth setup-git --git-protocol ssh` configured on every machine that pushes
- [ ] Project's `AGENTS.md` references this doc instead of restating the rules
- [ ] Token usage log location documented (where to find audit trail)

---

## Decision matrix (quick lookup)

| Scenario | Identity | Auth |
|----------|----------|------|
| `git clone` / `git push` from laptop | Me | SSH key |
| `gh release create` interactively | Me | `gh auth token` (broad scope; trust boundary is me) |
| GoReleaser auto-commit to tap | Local automation | Scoped tap-writer PAT (1P → env at runtime) |
| `jwa-tobrew add <url>` (snapshot existing release) | Me | None (SSH for the push, no API call) |
| `jwa-tobrew release` Cask flow | Local automation | Scoped per-source-repo PAT (1P) |
| VPS webhook pulls source repo | Remote automation | Read-only SSH deploy key per service |
| GitHub Actions builds + releases | Remote automation | Scoped PAT in repo secrets, mirrored from 1P |
| Agent in container needs to write to one repo | Local automation | Scoped PAT injected via `op run` at container launch |

---

## Anti-patterns (don't)

- ❌ `export GITHUB_TOKEN=ghp_…` in `.zshrc` / `.zshenv`
- ❌ `.env` checked in (or even uncommitted on disk)
- ❌ One token reused across two services
- ❌ Token hardcoded in source — even as a "default" fallback
- ❌ Wrapping `git push` over SSH with `GH_TOKEN` env (unnecessary; SSH already authenticated)
- ❌ Passing the token as an argv (`mytool --token=…`) — appears in `ps`
- ❌ Printing token to stdout for any reason, even on error
- ❌ Rotating SSH keys on a schedule (creates churn for no benefit)
- ❌ Creating a single "I do everything" PAT

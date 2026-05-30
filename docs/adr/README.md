# Architecture Decision Records

Short ADRs (one paragraph each) capturing intentional design choices for this dotfiles repo and the machine-level conventions it owns. Each entry has a **scope** sentence (what the rule covers) and a **why** sentence (the constraint that produced it). Reference these from PR reviews when someone proposes reverting the decision.

The ADRs here capture specific mechanical rules that need their own name so downstream repos can defer to them by number.

| # | Title |
|---|-------|
| [0001](0001-no-env-files-op-templates.md) | No `.env` files anywhere on this machine; only `.env.template` with `op://` references |

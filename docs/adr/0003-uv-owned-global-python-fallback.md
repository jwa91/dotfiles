# ADR 0003: uv-Owned Global Python Fallback

## Status

Accepted. Supersedes ADR 0001.

## Context

ADR 0001 made uv the owner of Python and turned bare `python`, `python3`, `pip`, and `pip3` into guard shims that refuse and print a nudge. That removed the ambiguity, but it also made the machine reject a category of correct, portable code: any third-party `#!/usr/bin/env python3` script, and anything that shells out to `python3` without knowing about this repo. ADR 0001 named this as a known consequence and left it unresolved.

Refusing every invocation conflates two different things. Installing packages mutates machine state and is exactly what ADR 0001 exists to own. Running a script does not mutate anything — it only has to resolve to a defensible interpreter. Refusing both bought nothing for the second case and cost portability.

The reason a fallback was risky is that "just run python3" historically means macOS system Python 3.9, or whatever stray build is first on `PATH`. On this machine `uv python find` without constraints returns `/usr/local/bin/python3.11`; `/usr/bin/python3` is 3.9.6. Neither is acceptable.

## Decision

Python is owned by uv. `UV_MANAGED_PYTHON=1` remains exported globally, and project code still runs with `uv run`; project dependencies use `uv add` and `uv.lock`; one-off script dependencies use `uv run --with`; one-off Python CLIs use `uvx`; durable personal CLIs use `uv tool install`. `uv pip ...` remains for explicit legacy or manual virtualenv work only.

What changes is the bare-command surface:

- `python` and `python3` resolve to a uv-managed interpreter and execute normally. The shim calls `uv python find --managed-python`, and installs one with `uv python install` if none exists yet.
- `pip` and `pip3` keep refusing with the ADR 0001 nudge.

Two constraints on the resolution:

- `--managed-python` is passed explicitly rather than relying on the exported `UV_MANAGED_PYTHON`, because the shims also run from contexts that never sourced `zsh/env.zsh` — bash scripts, GUI applications, cron. Trusting the environment variable would let those contexts reach a non-managed interpreter.
- No Python version is pinned in this repo. uv chooses its own default, so the machine tracks uv's notion of current rather than a number that would go stale here.

## Consequences

Third-party scripts and tools that invoke `python3` work, and they get a uv-managed interpreter — never system or framework Python. The package surface is unchanged: `pip install` still refuses, so nothing can quietly mutate the global interpreter.

A first `python3` call on a fresh machine may download a runtime. `UV_PYTHON_DOWNLOADS=never` is still intentionally not the default, so this is consistent with ADR 0001 rather than new behaviour.

Bare `python3` is now a real interpreter rather than an error, so it will not surface the "use `uv run`" nudge that previously taught the project workflow. That guidance now lives only on the `pip` path and in this ADR.

`just doctor` fails if `UV_MANAGED_PYTHON` is not `1`, if bare Python/pip commands resolve outside the dotfiles shims, or if bare `python3` reports an interpreter outside uv's managed Python directory.

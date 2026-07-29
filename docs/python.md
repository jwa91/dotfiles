# Python Workflow

`uv` owns Python versions, environments, dependencies, and locks. `ty` owns
type checking and language intelligence. Ruff owns linting, import sorting, and
formatting.

## Zed

The managed Zed settings use exactly two Python language servers:

- `ty` for diagnostics, navigation, completion, and refactoring.
- `ruff` for lint diagnostics, import sorting, and formatting.

ty reports diagnostics for the whole workspace. Zed formats on save with Ruff
and organizes imports first. Zed's AI features are disabled globally. The
existing fonts, theme, icon theme, sizing, and layout settings are unchanged.

Zed detects the `.venv` created by `uv sync`, selects it as the Python
toolchain, and activates it in new integrated terminals. If discovery is
ambiguous, use Zed's toolchain selector and choose `.venv/bin/python`.

## New Projects

Add the development tools to the project so local runs and CI use the locked
versions:

```sh
uv add --dev ty ruff
uv sync
```

Use these canonical checks:

```sh
uv run ty check
uv run ruff check .
uv run ruff format --check .
```

For intentional local fixes:

```sh
uv run ruff check --fix .
uv run ruff format .
```

Keep portable policy in the project, not only in editor settings. A new
project's `pyproject.toml` should contain at least:

```toml
[tool.ty.rules]
all = "error"

[tool.ty.analysis]
strict-equality-semantics = true
```

Copy the `[tool.ruff]` tables from `config/ruff/pyproject.toml` into the
project's `pyproject.toml`, then tune project-specific exceptions there. Ruff
does not merge its user and project configurations, so any project-local Ruff
configuration fully replaces the fallback. ty does merge its user-level and
project-level configuration, with project values taking precedence.

Do not pin a Python version in the shared user configuration. Declare
`project.requires-python` in each project; uv, ty, and Ruff will derive their
target from that project metadata.

## Existing Projects

The user-level files provide strict defaults for unconfigured work:

- `~/.config/ty/ty.toml` enables every ty rule as an error and uses sounder
  equality semantics.
- `~/.config/ruff/pyproject.toml` enables a curated strict rule set, including
  annotation enforcement, while avoiding formatter conflicts and the upgrade
  churn of Ruff's `ALL` selector.

Project configuration remains authoritative. Relax a rule narrowly in the
project and document why; do not add global exceptions for one codebase.

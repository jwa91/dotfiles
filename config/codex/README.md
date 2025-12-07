# Codex Configuration

## Files
- `config.toml` - Main configuration (model, sandbox, approval)
- `instructions.md` - Global instructions for all projects

## Symlinked to
- `~/.codex/config.toml`
- `~/.codex/instructions.md`

## Configuration Options

### config.toml
```toml
model = "o4-mini-2025-04-16"  # or "gpt-5", "o3"
approval_policy = "on-request"  # untrusted, on-failure, on-request, never
sandbox_mode = "workspace-write"  # read-only, workspace-write, danger-full-access
```

### Add MCP Servers (optional)
```toml
[mcp_servers.github]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-github"]
```

## Project-Level Config
Create `AGENTS.md` in project root for project-specific rules.

## Resources
- [Codex Docs](https://developers.openai.com/codex)
- [Config Reference](https://developers.openai.com/codex/local-config)


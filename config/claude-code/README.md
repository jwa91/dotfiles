# Claude Code Configuration

## Files

- `settings.json` - Optional global settings (permissions, tools, MCP servers)
- `commands/` - Custom slash commands (`/command-name`)
- `agents/` - Custom specialized agents (`@agent-name`)

## Symlinked to

- `~/.claude/settings.json`
- `~/.claude/commands/`
- `~/.claude/agents/`

## Quick Start

### 1. Create settings.json (optional)

```json
{
  "permissions": {
    "allow": ["Bash(npm:*)", "Read(~/.zshrc)"],
    "deny": ["Read(./.env)", "Bash(curl:*)"]
  }
}
```

### 2. Add Custom Commands

Create `commands/review.md`:

```markdown
Review this code for security, performance, and best practices.
Provide specific, actionable feedback.
```

Use with: `/review`

### 3. Add Custom Agents

Create `agents/security-expert.md`:

```yaml
---
name: security-expert
description: Security specialist
tools: Read, Grep, Bash
model: opus
---
You are a security expert. Scan for vulnerabilities and provide remediation steps.
```

Use with: `@security-expert`

## Configuration Options

### settings.json

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"]
    }
  },
  "permissions": {
    "allow": ["Bash(npm:*)"],
    "deny": ["Read(./.env)"]
  },
  "allowedTools": ["Bash", "Read", "Edit", "Write"],
  "hooks": {},
  "env": {}
}
```

Available options:

- `mcpServers` - MCP server configurations (define here, stored at runtime in `~/.claude.json`)
- `permissions` - Allow/deny specific commands and file access
- `allowedTools` - List of enabled tools
- `hooks` - PreToolUse/PostToolUse hooks
- `env` - Environment variables

### MCP Servers

Configured via CLI or in `~/.claude.json`:

```bash
claude mcp add github npx @modelcontextprotocol/server-github
```

### Plugins

```bash
claude plugin install <plugin-name>
```

## Resources

- [Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code)
- [Settings Reference](https://docs.anthropic.com/en/docs/claude-code/settings)

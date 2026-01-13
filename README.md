# status-line

A minimal shell utility to display your KrAIG API budget status in Claude Code's status bar.

![Example](https://img.shields.io/badge/budget-45%25-green)

## Features

- **Auto-detect credentials** from environment variables and Claude settings files
- **Multiple output formats**: minimal, money, bar, full, json
- **Color-coded status**: Green (<75%), Yellow (75-89%), Red (>=90%)
- **Smart caching** to avoid API rate limits
- **Zero required dependencies** beyond curl and bc (jq optional)

## Quick Install

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/bfd-kr/status-line/main/install.sh | bash
```

### Git Clone

```bash
git clone https://github.com/bfd-kr/status-line.git
cd status-line
./setup.sh
```

### Manual

```bash
# Download
curl -fsSL https://raw.githubusercontent.com/bfd-kr/status-line/main/status-line -o ~/.claude/status-line

# Make executable
chmod u+x ~/.claude/status-line

# Configure Claude Code (add to ~/.claude/settings.json)
# "statusLine": {"type": "command", "command": "~/.claude/status-line"}
```

## Usage

```bash
# Default (full format)
~/.claude/status-line
# Output: 🟢 KrAIG 💰 (my-key | user): 45.2% ($45 of $100) | 15 days until reset

# Minimal format
~/.claude/status-line -f minimal
# Output: 45/100 (45%)

# Money format
~/.claude/status-line -f money
# Output: $45/$100 (45%)

# Progress bar
~/.claude/status-line -f bar
# Output: [████░░░░░░] 45%

# Emoji only (with cat faces!)
~/.claude/status-line -f emoji
# Output: 🟢😺💰 (happy cat at <75%)
# Output: 🟡🙀💰 (surprised cat at 75-89%)
# Output: 🔴😿💰 (crying cat at >=90%)

# JSON (for scripting)
~/.claude/status-line -f json
# Output: {"spend":45,"budget":100,"percent":45.2,...}

# Hide key name
~/.claude/status-line -k

# Hide days until reset
~/.claude/status-line -d

# No colors (for non-TTY)
~/.claude/status-line -c

# Custom cache TTL (seconds)
~/.claude/status-line -t 120

# Help
~/.claude/status-line --help
```

## Configuration

### Credentials

The script looks for credentials in this order:

1. `KRAIG_API_KEY` environment variable
2. `ANTHROPIC_AUTH_TOKEN` in Claude settings files:
   - `$project_dir/.claude/settings.local.json`
   - `$project_dir/.claude/settings.json`
   - `~/.claude/settings.local.json`
   - `~/.claude/settings.json`
3. `ANTHROPIC_API_KEY` environment variable (fallback)

### API URL

1. `KRAIG_API_URL` environment variable
2. `ANTHROPIC_BASE_URL` from settings files
3. Default: `https://ai-model-proxy.aks-ur-prd-internal.8451.cloud`

### Claude Code Integration

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/status-line"
  }
}
```

## Dependencies

| Dependency | Required | Notes |
|------------|----------|-------|
| `curl` | Yes | For API requests |
| `bc` | Yes | For percentage calculation (pre-installed on most systems) |
| `jq` | No | Recommended for reliable JSON parsing; falls back to grep/sed |

## Output Formats

| Format | Example |
|--------|---------|
| `full` | 🟢 KrAIG 💰 (key-name \| user): 45.2% ($45 of $100) \| 15 days |
| `minimal` | 45/100 (45%) |
| `money` | $45/$100 (45%) |
| `bar` | [████░░░░░░] 45% |
| `emoji` | 🟢😺💰 / 🟡🙀💰 / 🔴😿💰 |
| `json` | {"spend":45,"budget":100,"percent":45,...} |

## Color Thresholds

| Usage | Color | Emoji |
|-------|-------|-------|
| < 75% | Green | 🟢 |
| 75-89% | Yellow | 🟡 |
| >= 90% | Red | 🔴 |

## Troubleshooting

### "No API key found"

Make sure you have either:
- `KRAIG_API_KEY` environment variable set, or
- `ANTHROPIC_AUTH_TOKEN` in your `~/.claude/settings.json`

### "API Error: Internal Server Error"

- Check you're connected to the correct network/VPN
- Verify your API key is valid

### Status line not appearing in Claude Code

1. Restart Claude Code after configuration
2. Check `~/.claude/settings.json` has the `statusLine` configuration
3. Try running `~/.claude/status-line` manually to verify it works

## License

MIT

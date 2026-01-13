# Status Line

A minimal shell utility to check your KrAIG API usage and budget status.

## Project Intent

This project provides a lightweight shell command that:
- Queries the KrAIG API to retrieve monthly billing/usage information
- Auto-detects the user's API URL and key from environment variables and Claude settings files
- Calculates and displays cost spent and percentage of budget used to date
- Supports multiple output formats (minimal, money, bar, full, json)

## Key Detection Strategy

Credentials are detected in the following priority order:

1. **Environment Variables**
   - `KRAIG_API_KEY` (highest priority)
   - `ANTHROPIC_API_KEY` (fallback)

2. **Claude Settings Files** (walks up directory tree from project_dir)
   - `$project_dir/.claude/settings.local.json`
   - `$project_dir/.claude/settings.json`
   - `~/.claude/settings.local.json`
   - `~/.claude/settings.json`

   Looks for `ANTHROPIC_AUTH_TOKEN` in the `env` object or root level.

## API URL Detection

1. `KRAIG_API_URL` environment variable
2. `ANTHROPIC_BASE_URL` from settings files (appends `/user/info`)
3. Default: `https://ai-model-proxy.aks-ur-prd-internal.8451.cloud/user/info`

## Output Formats

| Format | Example |
|--------|---------|
| `minimal` | `45/100 (45%)` |
| `money` | `$45/$100 (45%)` |
| `bar` | `[████████░░] 45%` |
| `full` | `🟢 KrAIG 💰 (key-name \| user): 45.2% ($45 of $100) \| 15 days` |
| `json` | `{"spend":45,"budget":100,"percent":45,"key":"...","scope":"user","days_until_reset":15}` |

## Dependencies

- `curl` - for API requests (required)
- `bc` - for floating point math (required, usually pre-installed)
- `jq` - for JSON parsing (optional, but recommended)
  - If not installed, falls back to grep/sed parsing
  - The fallback is less robust but works for standard API responses
- Bash 3.2+ (macOS default is sufficient)

## Usage

```bash
# Basic usage (full format)
./status-line

# Different formats
./status-line -f minimal
./status-line -f money
./status-line -f bar
./status-line -f json

# Hide key name and/or days
./status-line -k              # Hide key name
./status-line -d              # Hide days until reset
./status-line -k -d           # Hide both

# Disable colors (for scripting)
./status-line -c

# Custom cache TTL
./status-line -t 120          # 2 minute cache

# With explicit key
KRAIG_API_KEY=your-key ./status-line

# Help
./status-line --help
```

## API Endpoints

- `/user/info` - Personal user keys (tried first)
- `/key/info` - Team keys (fallback)
- Authentication: `Authorization: Bearer <token>` header

## Caching

- Cache directory: `${TMPDIR:-/tmp}/status-line-cache`
- Cache key: MD5 hash of API key
- Default TTL: 60 seconds (configurable via `-t`)
- Separate cache files for user vs team responses

## Color Coding

| Percentage | Color | Emoji |
|------------|-------|-------|
| < 75% | Green | 🟢 |
| 75-89% | Yellow | 🟡 |
| >= 90% | Red | 🔴 |

## File Structure

```
status-line/
├── CLAUDE.md              # This file
├── status-line            # Main executable script
├── plans/                 # Implementation plans
│   └── status-line-rewrite.md
└── test/
    └── test-formats.sh    # Format output tests
```

## Integration with Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/path/to/status-line",
    "padding": 0
  }
}
```

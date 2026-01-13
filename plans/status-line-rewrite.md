# Status Line - Implementation Plan

## Overview
Clean rewrite of the KrAIG budget status line utility. A minimal shell script that queries the KrAIG API to display monthly budget usage with configurable output formats.

## Target API
- **Primary**: KrAIG API at `https://ai-model-proxy.aks-ur-prd-internal.8451.cloud`
- **Endpoints**: `/user/info` (personal keys) with fallback to `/key/info` (team keys)

## Architecture

### Core Design Principles
1. **Minimal dependencies**: `curl` required, `jq` required (no fallback - keeps code clean)
2. **Single responsibility functions**: Each function does one thing well
3. **Fail fast with clear errors**: No silent failures
4. **Configurable output**: Multiple format options via flags

### File Structure
```
status-line/
├── CLAUDE.md              # Project documentation (done)
├── status-line            # Main executable script
├── README.md              # User-facing documentation
├── plans/                 # Planning directory (done)
└── test/
    └── test-status-line.sh  # Basic test cases
```

## Implementation Steps

### Step 1: Core Script Structure
Create `status-line` with:
- Shebang and header comments
- Usage/help function
- Argument parsing (getopts)
- Main execution flow

### Step 2: Credential Detection
Priority order:
1. `KRAIG_API_KEY` environment variable
2. `ANTHROPIC_AUTH_TOKEN` from settings files:
   - Walk up from `project_dir` checking `.claude/settings.local.json` then `.claude/settings.json`
   - Fall back to `~/.claude/settings.json`
3. `ANTHROPIC_API_KEY` environment variable (fallback)

### Step 3: API URL Detection
Priority order:
1. `KRAIG_API_URL` environment variable
2. `ANTHROPIC_BASE_URL` from settings files (append `/user/info`)
3. Default: `https://ai-model-proxy.aks-ur-prd-internal.8451.cloud/user/info`

### Step 4: API Calls
- Call `/user/info` first
- If error or no `user_info` in response, try `/key/info`
- Parse response with `jq`
- Extract: `spend`, `max_budget`, `budget_reset_at`, `key_alias`

### Step 5: Caching
- Cache directory: `${TMPDIR:-/tmp}/status-line-cache`
- Cache key: MD5 hash of API key
- TTL: 60 seconds (configurable)
- Separate cache files for user vs team responses

### Step 6: Output Formatting
Configurable formats via `-f/--format` flag:

| Format | Example Output |
|--------|----------------|
| `minimal` | `45/100 (45%)` |
| `money` | `$45/$100 (45%)` |
| `bar` | `[████████░░] 45%` |
| `full` | `🟢 KrAIG 💰 (key-name): 45.2% ($45 of $100) \| 15 days` |
| `json` | `{"spend":45,"budget":100,"percent":45}` |

Default: `full` (matches original behavior)

### Step 7: Color Coding
- Green (🟢): < 75%
- Yellow (🟡): 75-89%
- Red (🔴): >= 90%
- Support `--no-color` flag for non-TTY usage

### Step 8: Command Line Interface
```
Usage: status-line [OPTIONS]

Options:
  -f, --format FORMAT    Output format: minimal|money|bar|full|json (default: full)
  -k, --hide-key         Hide key name in output
  -d, --hide-days        Hide days until reset
  -c, --no-color         Disable color output
  -t, --cache-ttl SECS   Cache TTL in seconds (default: 60)
  -q, --quiet            Only output on error
  -h, --help             Show this help message
  -v, --version          Show version
```

## Key Functions

```
main()                    # Entry point, orchestrates everything
parse_args()              # Parse command line arguments
detect_credentials()      # Find API key from env/files
detect_api_url()          # Find API URL from env/files
get_cached_response()     # Check cache, return if fresh
fetch_api_response()      # Make curl request
parse_user_response()     # Parse /user/info JSON
parse_team_response()     # Parse /key/info JSON
calculate_percentage()    # Math for budget percentage
calculate_days_until()    # Days until budget reset
format_output()           # Format based on chosen style
colorize()                # Apply color codes
show_help()               # Display usage info
die()                     # Error exit with message
```

## Testing Strategy
1. Mock API responses with sample JSON files
2. Test credential detection with temp config files
3. Test each output format
4. Test cache behavior
5. Test error conditions (no creds, API down, invalid response)

## Verification
After implementation:
1. Run `./status-line --help` - verify help output
2. Run `./status-line` with valid credentials - verify budget display
3. Run `./status-line -f minimal` - verify minimal format
4. Run `./status-line -f json` - verify JSON output
5. Run twice quickly - verify caching (check timestamps)
6. Run with `--no-color` - verify no ANSI codes in output

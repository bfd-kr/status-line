# Distribution Strategy Plan

## Goal
Make `status-line` easy to install for other users with multiple distribution options.

## Configuration
- **GitHub:** `github.com/bfd-kr/status-line`
- **Default Install Path:** `~/.claude/status-line`
- **Permissions:** `chmod u+x` (user-only execute, more secure)

---

## Distribution Methods

### Method 1: Git Clone + Setup Script
```bash
git clone https://github.com/bfd-kr/status-line.git
cd status-line
./setup.sh
```

### Method 2: curl | bash One-Liner
```bash
curl -fsSL https://raw.githubusercontent.com/bfd-kr/status-line/main/install.sh | bash
```

### Method 3: GitHub Gist (same as Method 2, just a gist URL)
```bash
curl -fsSL https://gist.githubusercontent.com/bfd-kr/GIST_ID/raw/install.sh | bash
```

---

## Files to Create

### 1. `setup.sh` (for git clone users)
Interactive setup script that:
- Checks dependencies (curl, bc)
- Copies `status-line` to `~/.claude/status-line`
- Makes it executable with `chmod u+x`
- Offers to configure Claude Code settings.json
- Prints success message

### 2. `install.sh` (for curl|bash one-liner)
Non-interactive installer that:
- Creates `~/.claude/` if needed
- Downloads `status-line` from GitHub raw
- Makes it executable with `chmod u+x`
- Offers to configure Claude Code settings.json
- Prints usage instructions

### 3. `README.md`
User documentation with:
- Project description
- Installation methods (all 3)
- Usage examples
- Configuration options
- Troubleshooting

### 4. GitHub Gist
- Copy of `install.sh` for easy one-liner sharing
- Create after pushing to GitHub

---

## Implementation Steps

### Step 1: Create setup.sh
### Step 2: Create install.sh
### Step 3: Create README.md
### Step 4: Commit and push to GitHub
### Step 5: Create GitHub Gist

---

## Script Details

### setup.sh Behavior:
1. Print banner
2. Check for curl, bc
3. Copy status-line to ~/.claude/
4. `chmod u+x` (user-only execute)
5. Ask: "Configure Claude Code? [Y/n]"
6. If yes, update ~/.claude/settings.json
7. Print success + usage

### install.sh Behavior:
1. Print banner
2. Create ~/.claude/ if missing
3. curl download status-line to ~/.claude/status-line
4. `chmod u+x ~/.claude/status-line` (user-only execute)
5. Detect if settings.json exists, offer to configure
6. Print success + usage

### Claude Code Integration:
Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/status-line"
  }
}
```

---

## Verification

1. Fresh terminal: `git clone` + `./setup.sh` → works
2. Fresh terminal: `curl | bash` → works
3. Run `~/.claude/status-line --help` → shows help
4. Run `~/.claude/status-line` → shows budget (or graceful error)
5. Restart Claude Code → status line appears

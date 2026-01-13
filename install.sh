#!/bin/bash
#
# install.sh - One-liner installer for status-line
#
# Usage: curl -fsSL https://raw.githubusercontent.com/bfd-kr/status-line/main/install.sh | bash
#

set -e

# Configuration
REPO_URL="https://raw.githubusercontent.com/bfd-kr/status-line/main"
INSTALL_DIR="$HOME/.claude"
SCRIPT_NAME="status-line"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

#######################################
# Print colored message
#######################################
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

#######################################
# Print banner
#######################################
print_banner() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      status-line installer            ║${NC}"
    echo -e "${GREEN}║   KrAIG Budget Status for Claude Code ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
    echo ""
}

#######################################
# Check dependencies
#######################################
check_dependencies() {
    if ! command -v curl &>/dev/null; then
        error "curl is required but not installed"
    fi

    if ! command -v bc &>/dev/null; then
        error "bc is required but not installed"
    fi

    success "Dependencies OK (curl, bc)"

    if command -v jq &>/dev/null; then
        info "jq found - will use for reliable JSON parsing"
    else
        warn "jq not found - will use grep/sed fallback"
    fi
}

#######################################
# Download and install
#######################################
install_script() {
    info "Creating install directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"

    info "Downloading status-line..."
    if ! curl -fsSL "$REPO_URL/$SCRIPT_NAME" -o "$INSTALL_DIR/$SCRIPT_NAME"; then
        error "Failed to download status-line from $REPO_URL/$SCRIPT_NAME"
    fi

    info "Setting permissions (chmod u+x)..."
    chmod u+x "$INSTALL_DIR/$SCRIPT_NAME"

    success "Installed to $INSTALL_DIR/$SCRIPT_NAME"
}

#######################################
# Configure Claude Code (interactive)
#######################################
configure_claude() {
    local settings_file="$INSTALL_DIR/settings.json"

    # Check if we're in an interactive terminal
    if [[ ! -t 0 ]]; then
        # Non-interactive (piped), auto-configure if no existing config
        if [[ ! -f "$settings_file" ]] || ! grep -q '"statusLine"' "$settings_file" 2>/dev/null; then
            info "Auto-configuring Claude Code..."
            create_or_update_settings "$settings_file"
        else
            info "statusLine already configured, skipping"
        fi
        return
    fi

    # Interactive mode
    echo ""
    read -p "Configure Claude Code to use status-line? [Y/n] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        info "Skipping Claude Code configuration"
        info "To configure manually, add to $settings_file:"
        echo '  "statusLine": {"type": "command", "command": "~/.claude/status-line"}'
        return
    fi

    create_or_update_settings "$settings_file"
}

#######################################
# Create or update settings.json
#######################################
create_or_update_settings() {
    local settings_file="$1"

    if [[ -f "$settings_file" ]]; then
        if grep -q '"statusLine"' "$settings_file" 2>/dev/null; then
            warn "statusLine already configured in $settings_file"
            return
        fi

        # Backup and update
        cp "$settings_file" "$settings_file.backup"

        if command -v jq &>/dev/null; then
            local tmp_file=$(mktemp)
            jq '. + {"statusLine": {"type": "command", "command": "~/.claude/status-line"}}' "$settings_file" > "$tmp_file"
            mv "$tmp_file" "$settings_file"
        else
            # Fallback: simple append (may not work for all JSON structures)
            warn "jq not available, manual configuration may be needed"
            info "Add this to your $settings_file:"
            echo '  "statusLine": {"type": "command", "command": "~/.claude/status-line"}'
            return
        fi
    else
        # Create new settings.json
        cat > "$settings_file" << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/status-line"
  }
}
EOF
    fi

    success "Claude Code configured"
}

#######################################
# Print success message
#######################################
print_success() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Installation complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo "Usage:"
    echo "  ~/.claude/status-line              # Show budget status"
    echo "  ~/.claude/status-line -f minimal   # Minimal format"
    echo "  ~/.claude/status-line --help       # Show all options"
    echo ""
    echo "Restart Claude Code for changes to take effect."
    echo ""
}

#######################################
# Main
#######################################
main() {
    print_banner
    check_dependencies
    install_script
    configure_claude
    print_success
}

main "$@"

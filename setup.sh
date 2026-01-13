#!/bin/bash
#
# setup.sh - Interactive installer for status-line (git clone method)
#
# Usage: ./setup.sh
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

INSTALL_DIR="$HOME/.claude"
SCRIPT_NAME="status-line"

#######################################
# Print colored message
#######################################
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

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
    local missing=()

    if ! command -v curl &>/dev/null; then
        missing+=("curl")
    fi

    if ! command -v bc &>/dev/null; then
        missing+=("bc")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing[*]}"
        echo "Please install them and try again."
        exit 1
    fi

    success "All dependencies found (curl, bc)"

    if command -v jq &>/dev/null; then
        success "jq found (will use for reliable JSON parsing)"
    else
        warn "jq not found (will use grep/sed fallback - consider installing jq)"
    fi
}

#######################################
# Install the script
#######################################
install_script() {
    local source_script="$(dirname "$0")/$SCRIPT_NAME"

    if [[ ! -f "$source_script" ]]; then
        error "Cannot find $SCRIPT_NAME in the current directory"
        exit 1
    fi

    # Create install directory
    mkdir -p "$INSTALL_DIR"

    # Copy script
    cp "$source_script" "$INSTALL_DIR/$SCRIPT_NAME"

    # Make executable (user only)
    chmod u+x "$INSTALL_DIR/$SCRIPT_NAME"

    success "Installed to $INSTALL_DIR/$SCRIPT_NAME"
}

#######################################
# Configure Claude Code settings.json
#######################################
configure_claude() {
    local settings_file="$INSTALL_DIR/settings.json"

    echo ""
    read -p "Configure Claude Code to use status-line? [Y/n] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        info "Skipping Claude Code configuration"
        return
    fi

    # Check if settings.json exists
    if [[ -f "$settings_file" ]]; then
        # Check if statusLine is already configured
        if grep -q '"statusLine"' "$settings_file" 2>/dev/null; then
            warn "statusLine already configured in $settings_file"
            read -p "Overwrite existing configuration? [y/N] " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                info "Keeping existing configuration"
                return
            fi
        fi

        # Backup existing settings
        cp "$settings_file" "$settings_file.backup"
        info "Backed up existing settings to $settings_file.backup"

        # Add statusLine configuration using jq if available, otherwise manual
        if command -v jq &>/dev/null; then
            local tmp_file=$(mktemp)
            jq '. + {"statusLine": {"type": "command", "command": "~/.claude/status-line"}}' "$settings_file" > "$tmp_file"
            mv "$tmp_file" "$settings_file"
        else
            # Manual JSON manipulation (fragile but works for simple cases)
            # Remove trailing } and add statusLine config
            sed -i.bak 's/}$/,\n  "statusLine": {\n    "type": "command",\n    "command": "~\/.claude\/status-line"\n  }\n}/' "$settings_file"
            rm -f "$settings_file.bak"
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

    success "Claude Code configured to use status-line"
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
    echo "  $INSTALL_DIR/$SCRIPT_NAME              # Show budget status"
    echo "  $INSTALL_DIR/$SCRIPT_NAME -f minimal   # Minimal format"
    echo "  $INSTALL_DIR/$SCRIPT_NAME --help       # Show all options"
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

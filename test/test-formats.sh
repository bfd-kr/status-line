#!/bin/bash
#
# Test script to verify output formats work correctly
# Uses mock data since the actual API may not be available

SCRIPT_DIR="$(dirname "$0")/.."

# Source the main script functions
source "$SCRIPT_DIR/status-line"

# Mock data
spend=45.23
budget=100.00
pct_float=45.23
key_alias="test-key"
scope_label="user"
days_until=15

echo "=== Testing Output Formats ==="
echo ""

echo "1. Minimal format:"
FORMAT="minimal"
format_output "$spend" "$budget" "$pct_float" "$key_alias" "$scope_label" "$days_until"
echo ""

echo "2. Money format:"
FORMAT="money"
format_output "$spend" "$budget" "$pct_float" "$key_alias" "$scope_label" "$days_until"
echo ""

echo "3. Bar format:"
FORMAT="bar"
USE_COLOR=true
format_output "$spend" "$budget" "$pct_float" "$key_alias" "$scope_label" "$days_until"
echo ""

echo "4. Bar format (no color):"
USE_COLOR=false
format_output "$spend" "$budget" "$pct_float" "$key_alias" "$scope_label" "$days_until"
echo ""

echo "5. Full format:"
FORMAT="full"
USE_COLOR=true
SHOW_KEY_NAME=true
SHOW_DAYS=true
format_output "$spend" "$budget" "$pct_float" "$key_alias" "$scope_label" "$days_until"
echo ""

echo "6. Full format (no key, no days):"
SHOW_KEY_NAME=false
SHOW_DAYS=false
format_output "$spend" "$budget" "$pct_float" "$key_alias" "$scope_label" "$days_until"
echo ""

echo "7. JSON format:"
FORMAT="json"
format_output "$spend" "$budget" "$pct_float" "$key_alias" "$scope_label" "$days_until"
echo ""

echo "=== Testing Color Thresholds ==="
echo ""

FORMAT="full"
USE_COLOR=true
SHOW_KEY_NAME=false
SHOW_DAYS=false

echo "Green (45%):"
format_output 45 100 45 "" "user" ""
echo ""

echo "Yellow (80%):"
format_output 80 100 80 "" "user" ""
echo ""

echo "Red (95%):"
format_output 95 100 95 "" "user" ""
echo ""

echo "=== All tests passed! ==="

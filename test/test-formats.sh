#!/bin/bash
#
# Test script to verify output formats work correctly
# Tests both with jq and with the grep/sed fallback

SCRIPT_DIR="$(dirname "$0")/.."

echo "=== Status Line Format Tests ==="
echo ""

# Source the main script functions
source "$SCRIPT_DIR/status-line"

# Mock data
spend=45.23
budget=100.00
pct_float=45.23
key_alias="test-key"
scope_label="user"
days_until=15

run_format_tests() {
    local mode="$1"
    echo "--- Testing with HAS_JQ=$mode ---"
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

    echo "4. Full format:"
    FORMAT="full"
    USE_COLOR=true
    SHOW_KEY_NAME=true
    SHOW_DAYS=true
    format_output "$spend" "$budget" "$pct_float" "$key_alias" "$scope_label" "$days_until"
    echo ""

    echo "5. JSON format:"
    FORMAT="json"
    format_output "$spend" "$budget" "$pct_float" "$key_alias" "$scope_label" "$days_until"
    echo ""
}

# Test with jq if available
if command -v jq &>/dev/null; then
    HAS_JQ=true
    run_format_tests "true"
else
    echo "jq not installed - skipping jq tests"
    echo ""
fi

# Force test without jq (using fallback)
HAS_JQ=false
run_format_tests "false (grep/sed fallback)"

echo "=== Testing JSON Parsing Functions ==="
echo ""

# Test json_extract with sample data
test_json='{"user_info":{"spend":42.5,"max_budget":100},"error":false}'

echo "Test JSON: $test_json"
echo ""

HAS_JQ=true
if command -v jq &>/dev/null; then
    echo "json_extract with jq:"
    echo "  user_info.spend = $(json_extract "$test_json" "user_info.spend")"
    echo "  user_info.max_budget = $(json_extract "$test_json" "user_info.max_budget")"
fi

HAS_JQ=false
echo "json_extract with grep/sed fallback:"
echo "  user_info.spend = $(json_extract "$test_json" "user_info.spend")"
echo "  user_info.max_budget = $(json_extract "$test_json" "user_info.max_budget")"
echo ""

echo "=== Testing Color Thresholds ==="
echo ""

FORMAT="full"
USE_COLOR=true
SHOW_KEY_NAME=false
SHOW_DAYS=false
HAS_JQ=true

echo "Green (45%):"
format_output 45 100 45 "" "user" ""
echo ""

echo "Yellow (80%):"
format_output 80 100 80 "" "user" ""
echo ""

echo "Red (95%):"
format_output 95 100 95 "" "user" ""
echo ""

echo "=== All tests completed! ==="

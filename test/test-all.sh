#!/bin/bash
#
# test-all.sh - Comprehensive test suite for status-line
#
# Usage: ./test/test-all.sh
#

# Don't use set -e, we handle test failures manually

SCRIPT_DIR="$(dirname "$0")/.."
PASS_COUNT=0
FAIL_COUNT=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

#######################################
# Test assertion helpers
#######################################
pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((PASS_COUNT++))
}

fail() {
    echo -e "  ${RED}✗${NC} $1"
    echo "    Expected: $2"
    echo "    Got:      $3"
    ((FAIL_COUNT++))
}

assert_eq() {
    local name="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$name"
    else
        fail "$name" "$expected" "$actual"
    fi
}

assert_contains() {
    local name="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$actual" == *"$expected"* ]]; then
        pass "$name"
    else
        fail "$name" "contains '$expected'" "$actual"
    fi
}

assert_true() {
    local name="$1"
    local result="$2"
    if [[ "$result" == "true" || "$result" == "0" ]]; then
        pass "$name"
    else
        fail "$name" "true" "$result"
    fi
}

assert_false() {
    local name="$1"
    local result="$2"
    if [[ "$result" == "false" || "$result" == "1" ]]; then
        pass "$name"
    else
        fail "$name" "false" "$result"
    fi
}

#######################################
# Source the main script functions
#######################################
source "$SCRIPT_DIR/status-line"

echo "=== status-line Test Suite ==="
echo ""

#######################################
# Test: is_valid_json()
#######################################
echo "Testing is_valid_json()..."

# Test with jq first if available
if command -v jq &>/dev/null; then
    HAS_JQ=true

    if is_valid_json '{"key": "value"}'; then
        pass "is_valid_json (jq): valid object"
    else
        fail "is_valid_json (jq): valid object" "true" "false"
    fi

    if is_valid_json '[1, 2, 3]'; then
        pass "is_valid_json (jq): valid array"
    else
        fail "is_valid_json (jq): valid array" "true" "false"
    fi

    if ! is_valid_json 'not json'; then
        pass "is_valid_json (jq): invalid string"
    else
        fail "is_valid_json (jq): invalid string" "false" "true"
    fi

    if ! is_valid_json 'Internal Server Error'; then
        pass "is_valid_json (jq): error message"
    else
        fail "is_valid_json (jq): error message" "false" "true"
    fi
fi

# Test without jq (grep/sed fallback)
HAS_JQ=false

if is_valid_json '{"key": "value"}'; then
    pass "is_valid_json (fallback): valid object"
else
    fail "is_valid_json (fallback): valid object" "true" "false"
fi

if is_valid_json '[1, 2, 3]'; then
    pass "is_valid_json (fallback): valid array"
else
    fail "is_valid_json (fallback): valid array" "true" "false"
fi

if ! is_valid_json 'not json'; then
    pass "is_valid_json (fallback): invalid string"
else
    fail "is_valid_json (fallback): invalid string" "false" "true"
fi

if ! is_valid_json 'Internal Server Error'; then
    pass "is_valid_json (fallback): error message"
else
    fail "is_valid_json (fallback): error message" "false" "true"
fi

echo ""

#######################################
# Test: json_has_key()
#######################################
echo "Testing json_has_key()..."

test_json='{"user_info": {"spend": 42}, "error": false}'

if command -v jq &>/dev/null; then
    HAS_JQ=true

    if json_has_key "$test_json" "user_info"; then
        pass "json_has_key (jq): existing key"
    else
        fail "json_has_key (jq): existing key" "true" "false"
    fi

    if json_has_key "$test_json" "error"; then
        pass "json_has_key (jq): error key"
    else
        fail "json_has_key (jq): error key" "true" "false"
    fi

    if ! json_has_key "$test_json" "missing_key"; then
        pass "json_has_key (jq): missing key"
    else
        fail "json_has_key (jq): missing key" "false" "true"
    fi
fi

HAS_JQ=false

if json_has_key "$test_json" "user_info"; then
    pass "json_has_key (fallback): existing key"
else
    fail "json_has_key (fallback): existing key" "true" "false"
fi

if ! json_has_key "$test_json" "missing_key"; then
    pass "json_has_key (fallback): missing key"
else
    fail "json_has_key (fallback): missing key" "false" "true"
fi

echo ""

#######################################
# Test: json_extract()
#######################################
echo "Testing json_extract()..."

test_json='{"user_info":{"spend":42.5,"max_budget":100},"name":"test"}'

if command -v jq &>/dev/null; then
    HAS_JQ=true

    result=$(json_extract "$test_json" "name")
    assert_eq "json_extract (jq): simple key" "test" "$result"

    result=$(json_extract "$test_json" "user_info.spend")
    assert_eq "json_extract (jq): nested key" "42.5" "$result"

    result=$(json_extract "$test_json" "user_info.max_budget")
    assert_eq "json_extract (jq): nested number" "100" "$result"

    result=$(json_extract "$test_json" "missing")
    assert_eq "json_extract (jq): missing key returns empty" "" "$result"
fi

HAS_JQ=false

result=$(json_extract "$test_json" "name")
assert_eq "json_extract (fallback): simple key" "test" "$result"

result=$(json_extract "$test_json" "user_info.spend")
assert_eq "json_extract (fallback): nested key" "42.5" "$result"

echo ""

#######################################
# Test: get_hash()
#######################################
echo "Testing get_hash()..."

hash1=$(get_hash "test-key-123")
hash2=$(get_hash "test-key-123")
hash3=$(get_hash "different-key")

assert_eq "get_hash: same input produces same output" "$hash1" "$hash2"

if [[ "$hash1" != "$hash3" ]]; then
    pass "get_hash: different input produces different output"
else
    fail "get_hash: different input produces different output" "different hashes" "same hash"
fi

if [[ -n "$hash1" ]]; then
    pass "get_hash: produces non-empty output"
else
    fail "get_hash: produces non-empty output" "non-empty" "empty"
fi

echo ""

#######################################
# Test: calculate_days_until()
#######################################
echo "Testing calculate_days_until()..."

# Test with a date 10 days in the future
future_date=$(date -u -v+10d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+10 days" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
if [[ -n "$future_date" ]]; then
    days=$(calculate_days_until "$future_date")
    if [[ "$days" == "10" || "$days" == "9" || "$days" == "11" ]]; then
        pass "calculate_days_until: 10 days future (got $days)"
    else
        fail "calculate_days_until: 10 days future" "~10" "$days"
    fi
fi

# Test with a past date
past_date="2020-01-01T00:00:00Z"
days=$(calculate_days_until "$past_date")
assert_eq "calculate_days_until: past date returns 0" "0" "$days"

# Test with invalid date
days=$(calculate_days_until "invalid")
assert_eq "calculate_days_until: invalid date returns 0" "0" "$days"

echo ""

#######################################
# Test: generate_bar()
#######################################
echo "Testing generate_bar()..."

bar=$(generate_bar 50 10)
assert_eq "generate_bar: 50% bar" "[█████░░░░░]" "$bar"

bar=$(generate_bar 0 10)
assert_eq "generate_bar: 0% bar" "[░░░░░░░░░░]" "$bar"

bar=$(generate_bar 100 10)
assert_eq "generate_bar: 100% bar" "[██████████]" "$bar"

bar=$(generate_bar 25 10)
assert_eq "generate_bar: 25% bar" "[██░░░░░░░░]" "$bar"

echo ""

#######################################
# Test: get_status_indicators()
#######################################
echo "Testing get_status_indicators()..."

USE_COLOR=true
get_status_indicators 50
assert_eq "get_status_indicators: 50% is green emoji" "🟢" "$EMOJI"

get_status_indicators 80
assert_eq "get_status_indicators: 80% is yellow emoji" "🟡" "$EMOJI"

get_status_indicators 95
assert_eq "get_status_indicators: 95% is red emoji" "🔴" "$EMOJI"

get_status_indicators 74
assert_eq "get_status_indicators: 74% is green emoji" "🟢" "$EMOJI"

get_status_indicators 75
assert_eq "get_status_indicators: 75% is yellow emoji" "🟡" "$EMOJI"

get_status_indicators 89
assert_eq "get_status_indicators: 89% is yellow emoji" "🟡" "$EMOJI"

get_status_indicators 90
assert_eq "get_status_indicators: 90% is red emoji" "🔴" "$EMOJI"

echo ""

#######################################
# Test: format_output() - all formats
#######################################
echo "Testing format_output()..."

USE_COLOR=false
SHOW_KEY_NAME=true
SHOW_DAYS=true
HAS_JQ=true

FORMAT="minimal"
output=$(format_output 45 100 45.0 "my-key" "user" "10")
assert_eq "format_output: minimal" "45/100 (45%)" "$output"

FORMAT="money"
output=$(format_output 45 100 45.0 "my-key" "user" "10")
assert_eq "format_output: money" "\$45/\$100 (45%)" "$output"

FORMAT="bar"
output=$(format_output 45 100 45.0 "my-key" "user" "10")
assert_contains "format_output: bar contains percentage" "45%" "$output"
assert_contains "format_output: bar contains brackets" "[" "$output"

FORMAT="full"
output=$(format_output 45 100 45.0 "my-key" "user" "10")
assert_contains "format_output: full contains emoji" "🟢" "$output"
assert_contains "format_output: full contains KrAIG" "KrAIG" "$output"
assert_contains "format_output: full contains key name" "my-key" "$output"
assert_contains "format_output: full contains days" "10 days" "$output"

FORMAT="emoji"
output=$(format_output 45 100 45.0 "my-key" "user" "10")
assert_contains "format_output: emoji contains status emoji" "🟢" "$output"
assert_contains "format_output: emoji contains happy cat" "😺" "$output"
assert_contains "format_output: emoji contains money emoji" "💰" "$output"

FORMAT="emoji"
output=$(format_output 85 100 85.0 "my-key" "user" "10")
assert_contains "format_output: emoji yellow at 85%" "🟡" "$output"
assert_contains "format_output: emoji surprised cat at 85%" "🙀" "$output"

FORMAT="emoji"
output=$(format_output 95 100 95.0 "my-key" "user" "10")
assert_contains "format_output: emoji red at 95%" "🔴" "$output"
assert_contains "format_output: emoji crying cat at 95%" "😿" "$output"

FORMAT="json"
output=$(format_output 45 100 45.0 "my-key" "user" "10")
assert_contains "format_output: json contains spend" '"spend"' "$output"
assert_contains "format_output: json contains budget" '"budget"' "$output"

echo ""

#######################################
# Test: Command line parsing
#######################################
echo "Testing command line parsing..."

# Reset to defaults
FORMAT="full"
SHOW_KEY_NAME=true
SHOW_DAYS=true
USE_COLOR=true
CACHE_TTL=60

# Test format flag
parse_args -f minimal
assert_eq "parse_args: -f minimal" "minimal" "$FORMAT"

# Reset and test --format
FORMAT="full"
parse_args --format bar
assert_eq "parse_args: --format bar" "bar" "$FORMAT"

# Test emoji format
FORMAT="full"
parse_args -f emoji
assert_eq "parse_args: -f emoji" "emoji" "$FORMAT"

# Test hide flags
SHOW_KEY_NAME=true
SHOW_DAYS=true
parse_args -k -d
assert_eq "parse_args: -k hides key" "false" "$SHOW_KEY_NAME"
assert_eq "parse_args: -d hides days" "false" "$SHOW_DAYS"

# Test color flag
USE_COLOR=true
parse_args -c
assert_eq "parse_args: -c disables color" "false" "$USE_COLOR"

# Test cache TTL
CACHE_TTL=60
parse_args -t 120
assert_eq "parse_args: -t sets cache TTL" "120" "$CACHE_TTL"

echo ""

#######################################
# Summary
#######################################
echo "=== Test Summary ==="
echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
if [[ $FAIL_COUNT -gt 0 ]]; then
    echo -e "${RED}Failed: $FAIL_COUNT${NC}"
    exit 1
else
    echo "Failed: 0"
    echo -e "${GREEN}All tests passed!${NC}"
fi

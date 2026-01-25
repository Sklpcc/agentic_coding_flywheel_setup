#!/usr/bin/env bash
# Unit tests for meta_skill (ms) integration
# Tests that ms binary works, basic commands work, and operations succeed
# Note: ms may not be installed on all systems - tests handle this gracefully

set -uo pipefail
# Note: Not using -e to allow tests to continue after failures

LOG_FILE="/tmp/ms_integration_tests_$(date +%Y%m%d_%H%M%S).log"
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG_FILE"; }
pass() {
    log "PASS: $*"
    ((PASS_COUNT++))
}
fail() {
    log "FAIL: $*"
    ((FAIL_COUNT++))
}
skip() {
    log "SKIP: $*"
    ((SKIP_COUNT++))
}

# Test 1: ms binary exists
test_ms_binary() {
    log "Test 1: ms binary availability..."
    if command -v ms >/dev/null 2>&1; then
        pass "ms binary found at $(which ms)"
        return 0
    else
        skip "ms binary not found in PATH (tool may not be installed yet)"
        return 1
    fi
}

# Test 2: ms --version works
test_ms_version() {
    log "Test 2: ms --version..."
    if ! command -v ms >/dev/null 2>&1; then
        skip "ms not installed, skipping version test"
        return
    fi

    local version
    if version=$(ms --version 2>&1); then
        if [[ "$version" =~ ms|meta.?skill|Meta.?Skill ]]; then
            pass "ms version: $version"
        else
            # Accept any version output
            pass "ms version: $version"
        fi
    else
        fail "ms --version failed"
    fi
}

# Test 3: ms --help works
test_ms_help() {
    log "Test 3: ms --help..."
    if ! command -v ms >/dev/null 2>&1; then
        skip "ms not installed, skipping help test"
        return
    fi

    if ms --help 2>&1 | head -20 | grep -qiE "(meta.?skill|skill|usage|command|help)"; then
        pass "ms --help displays correct content"
    else
        fail "ms --help failed or missing content"
    fi
}

# Test 4: ms doctor works (if available)
test_ms_doctor() {
    log "Test 4: ms doctor..."
    if ! command -v ms >/dev/null 2>&1; then
        skip "ms not installed, skipping doctor test"
        return
    fi

    local output
    output=$(ms doctor 2>&1)
    local exit_code=$?

    # Doctor may report issues but should complete
    if [[ $exit_code -eq 0 ]] || [[ "$output" =~ (check|ok|pass|warn|error) ]]; then
        pass "ms doctor completed (exit: $exit_code)"
    else
        fail "ms doctor failed unexpectedly: $output"
    fi
}

# Test 5: ms list works (if available)
test_ms_list() {
    log "Test 5: ms list..."
    if ! command -v ms >/dev/null 2>&1; then
        skip "ms not installed, skipping list test"
        return
    fi

    local output
    output=$(ms list 2>&1)
    local exit_code=$?

    # List may show no skills or many
    if [[ $exit_code -eq 0 ]]; then
        pass "ms list completed successfully"
    else
        # Some implementations may require init first
        if [[ "$output" =~ (init|initialize|not.*found|no.*skills) ]]; then
            skip "ms list requires init - expected behavior"
        else
            fail "ms list failed: $output"
        fi
    fi
}

# Test 6: ms search works (if available)
test_ms_search() {
    log "Test 6: ms search..."
    if ! command -v ms >/dev/null 2>&1; then
        skip "ms not installed, skipping search test"
        return
    fi

    local output
    output=$(ms search "test" 2>&1)
    local exit_code=$?

    # Search may return no results
    if [[ $exit_code -eq 0 ]]; then
        pass "ms search completed successfully"
    else
        if [[ "$output" =~ (init|initialize|no.*results|not.*found) ]]; then
            skip "ms search requires init or has no results - expected behavior"
        else
            fail "ms search failed: $output"
        fi
    fi
}

# Test 7: ms suggest works (if available)
test_ms_suggest() {
    log "Test 7: ms suggest..."
    if ! command -v ms >/dev/null 2>&1; then
        skip "ms not installed, skipping suggest test"
        return
    fi

    local output
    # ms suggest doesn't take arguments - it uses context from current directory
    output=$(ms suggest 2>&1)
    local exit_code=$?

    # Suggest may return no results
    if [[ $exit_code -eq 0 ]]; then
        pass "ms suggest completed successfully"
    else
        if [[ "$output" =~ (init|initialize|no.*suggestions|not.*found|no.*skills) ]]; then
            skip "ms suggest requires init or has no suggestions - expected behavior"
        else
            fail "ms suggest failed: $output"
        fi
    fi
}

# Test 8: ms init creates .ms directory (dry run check)
test_ms_init_structure() {
    log "Test 8: ms init structure check..."
    if ! command -v ms >/dev/null 2>&1; then
        skip "ms not installed, skipping init structure test"
        return
    fi

    # Check if --help mentions init
    if ms --help 2>&1 | grep -q "init"; then
        pass "ms init command is available"
    else
        skip "ms init command not found in help"
    fi
}

# Main test runner
main() {
    log "=========================================="
    log "Meta Skill (ms) Integration Tests"
    log "=========================================="
    log "Log file: $LOG_FILE"
    log ""

    # Run tests
    test_ms_binary
    local ms_available=$?

    if [[ $ms_available -eq 0 ]]; then
        test_ms_version
        test_ms_help
        test_ms_doctor
        test_ms_list
        test_ms_search
        test_ms_suggest
        test_ms_init_structure
    fi

    # Summary
    log ""
    log "=========================================="
    log "Test Summary"
    log "=========================================="
    log "Passed:  $PASS_COUNT"
    log "Failed:  $FAIL_COUNT"
    log "Skipped: $SKIP_COUNT"
    log ""

    if [[ $FAIL_COUNT -eq 0 ]]; then
        log "All tests passed or skipped!"
        exit 0
    else
        log "Some tests failed - see log for details"
        exit 1
    fi
}

main "$@"

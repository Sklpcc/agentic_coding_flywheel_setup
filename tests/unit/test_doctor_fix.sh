#!/usr/bin/env bash
# ============================================================
# Unit tests for scripts/lib/doctor_fix.sh
#
# Tests each fixer function in both normal and dry-run modes.
# Validates guard conditions, change recording, and undo support.
#
# Run with: bash tests/unit/test_doctor_fix.sh
# ============================================================

set -uo pipefail

# Get the absolute path to the scripts directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TEST_DIR/../.." && pwd)"

# Set SCRIPT_DIR for the libraries to find each other
export SCRIPT_DIR="$REPO_ROOT/scripts/lib"

# Source autofix first, then doctor_fix
source "$REPO_ROOT/scripts/lib/autofix.sh"
source "$REPO_ROOT/scripts/lib/doctor_fix.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================
# Test Helpers
# ============================================================

test_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "PASS: $1"
}

test_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: $1"
}

run_test() {
    local test_name="$1"
    TESTS_RUN=$((TESTS_RUN + 1))
    echo ""
    echo "Running: $test_name..."
    if "$test_name"; then
        test_pass "$test_name"
    else
        test_fail "$test_name"
    fi
}

# Setup test environment
setup_test_env() {
    local test_id="${FUNCNAME[1]:-$$}_$(date +%s%N)"

    # Autofix state
    export ACFS_STATE_DIR="/tmp/test_doctor_fix_${test_id}"
    export ACFS_CHANGES_FILE="$ACFS_STATE_DIR/changes.jsonl"
    export ACFS_UNDOS_FILE="$ACFS_STATE_DIR/undos.jsonl"
    export ACFS_BACKUPS_DIR="$ACFS_STATE_DIR/backups"
    export ACFS_LOCK_FILE="$ACFS_STATE_DIR/.lock"
    export ACFS_INTEGRITY_FILE="$ACFS_STATE_DIR/.integrity"

    # Doctor fix state
    export DOCTOR_FIX_LOG="$ACFS_STATE_DIR/doctor.log"
    export DOCTOR_FIX_DRY_RUN=false
    export DOCTOR_FIX_YES=false
    export DOCTOR_FIX_PROMPT=false

    # Reset counters
    FIX_APPLIED=0
    FIX_SKIPPED=0
    FIX_FAILED=0
    FIX_MANUAL=0
    FIXES_APPLIED=()
    FIXES_DRY_RUN=()
    FIXES_MANUAL=()
    FIXES_PROMPTED=()

    # Reset autofix state
    ACFS_CHANGE_RECORDS=()
    ACFS_CHANGE_ORDER=()
    ACFS_AUTOFIX_INITIALIZED=false

    # Create test directories
    rm -rf "$ACFS_STATE_DIR"
    mkdir -p "$ACFS_STATE_DIR"
    mkdir -p "$ACFS_BACKUPS_DIR"

    # Create empty files
    : > "$ACFS_CHANGES_FILE"
    : > "$ACFS_UNDOS_FILE"

    # Test home directory simulation
    export TEST_HOME="$ACFS_STATE_DIR/home"
    mkdir -p "$TEST_HOME/.acfs/zsh"
    mkdir -p "$TEST_HOME/.local/bin"
    mkdir -p "$TEST_HOME/.cargo/bin"
    mkdir -p "$TEST_HOME/.config/claude-code"

    # Save original HOME and override
    export ORIGINAL_HOME="$HOME"
    export HOME="$TEST_HOME"
}

# Cleanup test environment
cleanup_test_env() {
    # Restore HOME
    if [[ -n "${ORIGINAL_HOME:-}" ]]; then
        export HOME="$ORIGINAL_HOME"
    fi
    rm -rf "/tmp/test_doctor_fix_"* 2>/dev/null || true
}

# ============================================================
# Test: file_contains_line helper
# ============================================================

test_file_contains_line() {
    setup_test_env

    local test_file="$TEST_HOME/test_contains.txt"
    echo "line one" > "$test_file"
    echo "line two" >> "$test_file"
    echo "specific marker text" >> "$test_file"

    # Test positive match
    if ! file_contains_line "$test_file" "specific marker"; then
        echo "  Should find 'specific marker'"
        cleanup_test_env
        return 1
    fi

    # Test negative match
    if file_contains_line "$test_file" "not in file"; then
        echo "  Should not find 'not in file'"
        cleanup_test_env
        return 1
    fi

    # Test missing file
    if file_contains_line "/nonexistent/file" "pattern"; then
        echo "  Should return false for missing file"
        cleanup_test_env
        return 1
    fi

    cleanup_test_env
    return 0
}

# ============================================================
# Test: fix_path_ordering
# ============================================================

test_fix_path_ordering_applies() {
    setup_test_env

    # Create empty .zshrc
    local zshrc="$HOME/.zshrc"
    echo "# Initial zshrc" > "$zshrc"

    # Initialize autofix session
    start_autofix_session >/dev/null || {
        echo "  Failed to start autofix session"
        cleanup_test_env
        return 1
    }

    # Run fixer
    fix_path_ordering "path.ordering" >/dev/null 2>&1

    # Verify marker was added
    if ! grep -q "# ACFS PATH ordering" "$zshrc"; then
        echo "  Marker not found in .zshrc"
        cat "$zshrc"
        cleanup_test_env
        return 1
    fi

    # Verify PATH export was added
    if ! grep -q 'export PATH=' "$zshrc"; then
        echo "  PATH export not found in .zshrc"
        cleanup_test_env
        return 1
    fi

    # Verify counter incremented
    if [[ $FIX_APPLIED -ne 1 ]]; then
        echo "  FIX_APPLIED should be 1, got $FIX_APPLIED"
        cleanup_test_env
        return 1
    fi

    end_autofix_session >/dev/null
    cleanup_test_env
    return 0
}

test_fix_path_ordering_idempotent() {
    setup_test_env

    # Create .zshrc with marker already present
    local zshrc="$HOME/.zshrc"
    echo "# Initial zshrc" > "$zshrc"
    echo "" >> "$zshrc"
    echo "# ACFS PATH ordering (added by doctor --fix)" >> "$zshrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$zshrc"

    local initial_lines
    initial_lines=$(wc -l < "$zshrc")

    # Run fixer
    fix_path_ordering "path.ordering" >/dev/null 2>&1

    # Verify file not modified
    local final_lines
    final_lines=$(wc -l < "$zshrc")

    if [[ $initial_lines -ne $final_lines ]]; then
        echo "  File was modified when it shouldn't have been"
        echo "  Initial lines: $initial_lines, Final lines: $final_lines"
        cleanup_test_env
        return 1
    fi

    # Counter should not increment for no-op
    if [[ $FIX_APPLIED -ne 0 ]]; then
        echo "  FIX_APPLIED should be 0 for idempotent run, got $FIX_APPLIED"
        cleanup_test_env
        return 1
    fi

    cleanup_test_env
    return 0
}

test_fix_path_ordering_dry_run() {
    setup_test_env

    # Create empty .zshrc
    local zshrc="$HOME/.zshrc"
    echo "# Initial zshrc" > "$zshrc"

    # Enable dry-run mode
    DOCTOR_FIX_DRY_RUN=true

    # Run fixer
    fix_path_ordering "path.ordering" >/dev/null 2>&1

    # Verify file NOT modified
    if grep -q "# ACFS PATH ordering" "$zshrc"; then
        echo "  File was modified in dry-run mode"
        cleanup_test_env
        return 1
    fi

    # Verify dry-run record added
    if [[ ${#FIXES_DRY_RUN[@]} -ne 1 ]]; then
        echo "  Expected 1 dry-run record, got ${#FIXES_DRY_RUN[@]}"
        cleanup_test_env
        return 1
    fi

    DOCTOR_FIX_DRY_RUN=false
    cleanup_test_env
    return 0
}

# ============================================================
# Test: fix_config_copy
# ============================================================

test_fix_config_copy_applies() {
    setup_test_env

    # Create source config
    local src="$ACFS_STATE_DIR/source_config.txt"
    local dest="$HOME/.acfs/test_config.txt"
    echo "config content" > "$src"

    # Initialize autofix session
    start_autofix_session >/dev/null || {
        echo "  Failed to start autofix session"
        cleanup_test_env
        return 1
    }

    # Run fixer
    fix_config_copy "config.test" "$src" "$dest" >/dev/null 2>&1

    # Verify file copied
    if [[ ! -f "$dest" ]]; then
        echo "  Destination file not created"
        cleanup_test_env
        return 1
    fi

    # Verify content matches
    if ! diff -q "$src" "$dest" >/dev/null; then
        echo "  Content mismatch"
        cleanup_test_env
        return 1
    fi

    # Verify counter incremented
    if [[ $FIX_APPLIED -ne 1 ]]; then
        echo "  FIX_APPLIED should be 1, got $FIX_APPLIED"
        cleanup_test_env
        return 1
    fi

    end_autofix_session >/dev/null
    cleanup_test_env
    return 0
}

test_fix_config_copy_idempotent() {
    setup_test_env

    # Create source and destination
    local src="$ACFS_STATE_DIR/source_config.txt"
    local dest="$HOME/.acfs/test_config.txt"
    echo "config content" > "$src"
    echo "existing content" > "$dest"

    # Run fixer
    fix_config_copy "config.test" "$src" "$dest" >/dev/null 2>&1

    # Verify original content preserved
    if [[ "$(cat "$dest")" != "existing content" ]]; then
        echo "  Existing file was overwritten"
        cleanup_test_env
        return 1
    fi

    # Counter should not increment
    if [[ $FIX_APPLIED -ne 0 ]]; then
        echo "  FIX_APPLIED should be 0, got $FIX_APPLIED"
        cleanup_test_env
        return 1
    fi

    cleanup_test_env
    return 0
}

test_fix_config_copy_missing_source() {
    setup_test_env

    # Source doesn't exist
    local src="/nonexistent/source.txt"
    local dest="$HOME/.acfs/test_config.txt"

    # Run fixer - should fail
    if fix_config_copy "config.test" "$src" "$dest" 2>/dev/null; then
        echo "  Should have failed with missing source"
        cleanup_test_env
        return 1
    fi

    cleanup_test_env
    return 0
}

test_fix_config_copy_dry_run() {
    setup_test_env

    # Create source config
    local src="$ACFS_STATE_DIR/source_config.txt"
    local dest="$HOME/.acfs/test_config.txt"
    echo "config content" > "$src"

    # Enable dry-run mode
    DOCTOR_FIX_DRY_RUN=true

    # Run fixer
    fix_config_copy "config.test" "$src" "$dest" >/dev/null 2>&1

    # Verify file NOT created
    if [[ -f "$dest" ]]; then
        echo "  File was created in dry-run mode"
        cleanup_test_env
        return 1
    fi

    # Verify dry-run record added
    if [[ ${#FIXES_DRY_RUN[@]} -ne 1 ]]; then
        echo "  Expected 1 dry-run record, got ${#FIXES_DRY_RUN[@]}"
        cleanup_test_env
        return 1
    fi

    DOCTOR_FIX_DRY_RUN=false
    cleanup_test_env
    return 0
}

# ============================================================
# Test: fix_symlink_create
# ============================================================

test_fix_symlink_create_applies() {
    setup_test_env

    # Create binary
    local binary="$HOME/.cargo/bin/test_tool"
    local symlink="$HOME/.local/bin/test_tool"
    echo '#!/bin/bash' > "$binary"
    echo 'echo "test"' >> "$binary"
    chmod +x "$binary"

    # Initialize autofix session
    start_autofix_session >/dev/null || {
        echo "  Failed to start autofix session"
        cleanup_test_env
        return 1
    }

    # Run fixer
    fix_symlink_create "symlink.test" "$binary" "$symlink" >/dev/null 2>&1

    # Verify symlink created
    if [[ ! -L "$symlink" ]]; then
        echo "  Symlink not created"
        cleanup_test_env
        return 1
    fi

    # Verify symlink points to correct target
    local target
    target=$(readlink "$symlink")
    if [[ "$target" != "$binary" ]]; then
        echo "  Symlink points to wrong target: $target"
        cleanup_test_env
        return 1
    fi

    # Verify counter incremented
    if [[ $FIX_APPLIED -ne 1 ]]; then
        echo "  FIX_APPLIED should be 1, got $FIX_APPLIED"
        cleanup_test_env
        return 1
    fi

    end_autofix_session >/dev/null
    cleanup_test_env
    return 0
}

test_fix_symlink_create_idempotent() {
    setup_test_env

    # Create binary and existing symlink
    local binary="$HOME/.cargo/bin/test_tool"
    local symlink="$HOME/.local/bin/test_tool"
    echo '#!/bin/bash' > "$binary"
    chmod +x "$binary"
    ln -s "$binary" "$symlink"

    # Run fixer
    fix_symlink_create "symlink.test" "$binary" "$symlink" >/dev/null 2>&1

    # Counter should not increment
    if [[ $FIX_APPLIED -ne 0 ]]; then
        echo "  FIX_APPLIED should be 0, got $FIX_APPLIED"
        cleanup_test_env
        return 1
    fi

    cleanup_test_env
    return 0
}

test_fix_symlink_create_missing_binary() {
    setup_test_env

    local binary="/nonexistent/binary"
    local symlink="$HOME/.local/bin/test_tool"

    # Run fixer - should fail
    if fix_symlink_create "symlink.test" "$binary" "$symlink" 2>/dev/null; then
        echo "  Should have failed with missing binary"
        cleanup_test_env
        return 1
    fi

    cleanup_test_env
    return 0
}

test_fix_symlink_create_dry_run() {
    setup_test_env

    # Create binary
    local binary="$HOME/.cargo/bin/test_tool"
    local symlink="$HOME/.local/bin/test_tool"
    echo '#!/bin/bash' > "$binary"
    chmod +x "$binary"

    # Enable dry-run mode
    DOCTOR_FIX_DRY_RUN=true

    # Run fixer
    fix_symlink_create "symlink.test" "$binary" "$symlink" >/dev/null 2>&1

    # Verify symlink NOT created
    if [[ -L "$symlink" ]]; then
        echo "  Symlink was created in dry-run mode"
        cleanup_test_env
        return 1
    fi

    # Verify dry-run record added
    if [[ ${#FIXES_DRY_RUN[@]} -ne 1 ]]; then
        echo "  Expected 1 dry-run record, got ${#FIXES_DRY_RUN[@]}"
        cleanup_test_env
        return 1
    fi

    DOCTOR_FIX_DRY_RUN=false
    cleanup_test_env
    return 0
}

# ============================================================
# Test: fix_acfs_sourcing
# ============================================================

test_fix_acfs_sourcing_applies() {
    setup_test_env

    # Create .zshrc and acfs.zshrc
    local zshrc="$HOME/.zshrc"
    echo "# Initial zshrc" > "$zshrc"

    local acfs_zshrc="$HOME/.acfs/zsh/acfs.zshrc"
    echo "# ACFS config" > "$acfs_zshrc"

    # Initialize autofix session
    start_autofix_session >/dev/null || {
        echo "  Failed to start autofix session"
        cleanup_test_env
        return 1
    }

    # Run fixer
    fix_acfs_sourcing "shell.acfs_sourced" >/dev/null 2>&1

    # Verify marker was added
    if ! grep -q "# ACFS configuration" "$zshrc"; then
        echo "  ACFS configuration marker not found in .zshrc"
        cleanup_test_env
        return 1
    fi

    # Verify source line was added
    if ! grep -q "source ~/.acfs/zsh/acfs.zshrc" "$zshrc"; then
        echo "  Source line not found in .zshrc"
        cleanup_test_env
        return 1
    fi

    # Verify counter incremented
    if [[ $FIX_APPLIED -ne 1 ]]; then
        echo "  FIX_APPLIED should be 1, got $FIX_APPLIED"
        cleanup_test_env
        return 1
    fi

    end_autofix_session >/dev/null
    cleanup_test_env
    return 0
}

test_fix_acfs_sourcing_idempotent() {
    setup_test_env

    # Create .zshrc with sourcing already present
    local zshrc="$HOME/.zshrc"
    echo "# Initial zshrc" > "$zshrc"
    echo "source ~/.acfs/zsh/acfs.zshrc" >> "$zshrc"

    local acfs_zshrc="$HOME/.acfs/zsh/acfs.zshrc"
    echo "# ACFS config" > "$acfs_zshrc"

    local initial_lines
    initial_lines=$(wc -l < "$zshrc")

    # Run fixer
    fix_acfs_sourcing "shell.acfs_sourced" >/dev/null 2>&1

    # Verify file not modified
    local final_lines
    final_lines=$(wc -l < "$zshrc")

    if [[ $initial_lines -ne $final_lines ]]; then
        echo "  File was modified when it shouldn't have been"
        cleanup_test_env
        return 1
    fi

    # Counter should not increment
    if [[ $FIX_APPLIED -ne 0 ]]; then
        echo "  FIX_APPLIED should be 0, got $FIX_APPLIED"
        cleanup_test_env
        return 1
    fi

    cleanup_test_env
    return 0
}

test_fix_acfs_sourcing_missing_acfs_config() {
    setup_test_env

    # Create .zshrc but no acfs.zshrc
    local zshrc="$HOME/.zshrc"
    echo "# Initial zshrc" > "$zshrc"
    rm -f "$HOME/.acfs/zsh/acfs.zshrc"

    # Run fixer - should fail
    if fix_acfs_sourcing "shell.acfs_sourced" 2>/dev/null; then
        echo "  Should have failed with missing acfs.zshrc"
        cleanup_test_env
        return 1
    fi

    cleanup_test_env
    return 0
}

test_fix_acfs_sourcing_dry_run() {
    setup_test_env

    # Create .zshrc and acfs.zshrc
    local zshrc="$HOME/.zshrc"
    echo "# Initial zshrc" > "$zshrc"

    local acfs_zshrc="$HOME/.acfs/zsh/acfs.zshrc"
    echo "# ACFS config" > "$acfs_zshrc"

    # Enable dry-run mode
    DOCTOR_FIX_DRY_RUN=true

    # Run fixer
    fix_acfs_sourcing "shell.acfs_sourced" >/dev/null 2>&1

    # Verify file NOT modified
    if grep -q "# ACFS configuration" "$zshrc"; then
        echo "  File was modified in dry-run mode"
        cleanup_test_env
        return 1
    fi

    # Verify dry-run record added
    if [[ ${#FIXES_DRY_RUN[@]} -ne 1 ]]; then
        echo "  Expected 1 dry-run record, got ${#FIXES_DRY_RUN[@]}"
        cleanup_test_env
        return 1
    fi

    DOCTOR_FIX_DRY_RUN=false
    cleanup_test_env
    return 0
}

# ============================================================
# Test: dispatch_fix routing
# ============================================================

test_dispatch_fix_skips_pass() {
    setup_test_env

    # Dispatch should skip passing checks
    dispatch_fix "path.ordering" "pass" ""

    if [[ $FIX_APPLIED -ne 0 ]] && [[ $FIX_SKIPPED -ne 0 ]]; then
        echo "  Should not apply or skip fixes for pass status"
        cleanup_test_env
        return 1
    fi

    cleanup_test_env
    return 0
}

test_dispatch_fix_skips_skip() {
    setup_test_env

    # Dispatch should skip skipped checks
    dispatch_fix "path.ordering" "skip" ""

    if [[ $FIX_APPLIED -ne 0 ]] && [[ $FIX_SKIPPED -ne 0 ]]; then
        echo "  Should not apply or skip fixes for skip status"
        cleanup_test_env
        return 1
    fi

    cleanup_test_env
    return 0
}

test_dispatch_fix_routes_path() {
    setup_test_env

    # Create .zshrc
    local zshrc="$HOME/.zshrc"
    echo "# Initial zshrc" > "$zshrc"

    # Initialize autofix session
    start_autofix_session >/dev/null

    # Dispatch should route to fix_path_ordering
    dispatch_fix "path.ordering" "fail" "" >/dev/null 2>&1

    # Verify fixer was called
    if ! grep -q "# ACFS PATH ordering" "$zshrc"; then
        echo "  path.* check did not route to fix_path_ordering"
        cleanup_test_env
        return 1
    fi

    end_autofix_session >/dev/null
    cleanup_test_env
    return 0
}

test_dispatch_fix_routes_manual() {
    setup_test_env

    # Dispatch manual check with hint
    dispatch_fix "shell.ohmyzsh" "fail" "curl -fsSL ... | bash" >/dev/null 2>&1

    # Verify manual fix recorded
    if [[ $FIX_MANUAL -ne 1 ]]; then
        echo "  FIX_MANUAL should be 1, got $FIX_MANUAL"
        cleanup_test_env
        return 1
    fi

    # Verify manual entry added
    if [[ ${#FIXES_MANUAL[@]} -ne 1 ]]; then
        echo "  Expected 1 manual fix, got ${#FIXES_MANUAL[@]}"
        cleanup_test_env
        return 1
    fi

    cleanup_test_env
    return 0
}

test_dispatch_fix_unknown_skipped() {
    setup_test_env

    # Dispatch unknown check ID
    dispatch_fix "unknown.check.id" "fail" "" >/dev/null 2>&1

    # Verify skipped
    if [[ $FIX_SKIPPED -ne 1 ]]; then
        echo "  FIX_SKIPPED should be 1, got $FIX_SKIPPED"
        cleanup_test_env
        return 1
    fi

    cleanup_test_env
    return 0
}

# ============================================================
# Test: print_fix_summary
# ============================================================

test_print_fix_summary_dry_run() {
    setup_test_env

    DOCTOR_FIX_DRY_RUN=true
    FIXES_DRY_RUN+=("fix.test|Test action|/test/file|test command")

    local output
    output=$(print_fix_summary 2>&1)

    # Verify dry-run mode indicated
    if ! echo "$output" | grep -q "DRY-RUN"; then
        echo "  Dry-run mode not indicated in summary"
        cleanup_test_env
        return 1
    fi

    # Verify fix listed
    if ! echo "$output" | grep -q "fix.test"; then
        echo "  Fix not listed in summary"
        cleanup_test_env
        return 1
    fi

    DOCTOR_FIX_DRY_RUN=false
    cleanup_test_env
    return 0
}

test_print_fix_summary_applied() {
    setup_test_env

    FIX_APPLIED=2
    FIX_SKIPPED=1
    FIX_FAILED=0
    FIX_MANUAL=1
    FIXES_APPLIED+=("fix.one|First fix")
    FIXES_APPLIED+=("fix.two|Second fix")
    FIXES_MANUAL+=("fix.manual|Manual action|run this command")

    local output
    output=$(print_fix_summary 2>&1)

    # Verify counts
    if ! echo "$output" | grep -q "Applied: 2"; then
        echo "  Applied count not shown correctly"
        cleanup_test_env
        return 1
    fi

    # Verify manual section
    if ! echo "$output" | grep -q "Manual fixes needed"; then
        echo "  Manual fixes section not shown"
        cleanup_test_env
        return 1
    fi

    cleanup_test_env
    return 0
}

# ============================================================
# Test: run_doctor_fix initialization
# ============================================================

test_run_doctor_fix_init() {
    setup_test_env

    # Run initialization
    run_doctor_fix >/dev/null 2>&1

    # Verify counters reset
    if [[ $FIX_APPLIED -ne 0 ]] || [[ $FIX_SKIPPED -ne 0 ]] || [[ $FIX_FAILED -ne 0 ]]; then
        echo "  Counters not reset"
        cleanup_test_env
        return 1
    fi

    cleanup_test_env
    return 0
}

test_run_doctor_fix_dry_run_flag() {
    setup_test_env

    # Run with dry-run flag
    run_doctor_fix --dry-run >/dev/null 2>&1

    # Verify dry-run mode enabled
    if [[ "$DOCTOR_FIX_DRY_RUN" != "true" ]]; then
        echo "  Dry-run mode not enabled"
        cleanup_test_env
        return 1
    fi

    DOCTOR_FIX_DRY_RUN=false
    cleanup_test_env
    return 0
}

# ============================================================
# Run all tests
# ============================================================

main() {
    echo "============================================================"
    echo "Doctor Fix Unit Tests"
    echo "============================================================"

    # Helper tests
    run_test test_file_contains_line

    # fix_path_ordering tests
    run_test test_fix_path_ordering_applies
    run_test test_fix_path_ordering_idempotent
    run_test test_fix_path_ordering_dry_run

    # fix_config_copy tests
    run_test test_fix_config_copy_applies
    run_test test_fix_config_copy_idempotent
    run_test test_fix_config_copy_missing_source
    run_test test_fix_config_copy_dry_run

    # fix_symlink_create tests
    run_test test_fix_symlink_create_applies
    run_test test_fix_symlink_create_idempotent
    run_test test_fix_symlink_create_missing_binary
    run_test test_fix_symlink_create_dry_run

    # fix_acfs_sourcing tests
    run_test test_fix_acfs_sourcing_applies
    run_test test_fix_acfs_sourcing_idempotent
    run_test test_fix_acfs_sourcing_missing_acfs_config
    run_test test_fix_acfs_sourcing_dry_run

    # dispatch_fix tests
    run_test test_dispatch_fix_skips_pass
    run_test test_dispatch_fix_skips_skip
    run_test test_dispatch_fix_routes_path
    run_test test_dispatch_fix_routes_manual
    run_test test_dispatch_fix_unknown_skipped

    # print_fix_summary tests
    run_test test_print_fix_summary_dry_run
    run_test test_print_fix_summary_applied

    # run_doctor_fix tests
    run_test test_run_doctor_fix_init
    run_test test_run_doctor_fix_dry_run_flag

    # Summary
    echo ""
    echo "============================================================"
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed, $TESTS_RUN total"
    echo "============================================================"

    # Log results
    local log_file="/tmp/acfs_doctor_fix_test_$(date +%Y%m%d_%H%M%S).log"
    {
        echo "Doctor Fix Test Results"
        echo "Date: $(date)"
        echo "Passed: $TESTS_PASSED"
        echo "Failed: $TESTS_FAILED"
        echo "Total: $TESTS_RUN"
    } > "$log_file"
    echo "Log written to: $log_file"

    # Final cleanup
    cleanup_test_env

    # Exit with appropriate code
    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

main "$@"

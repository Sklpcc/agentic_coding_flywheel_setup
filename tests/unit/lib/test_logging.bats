#!/usr/bin/env bats

load '../test_helper'

setup() {
    common_setup
    # Source the library under test
    source_lib "logging"
}

teardown() {
    common_teardown
}

@test "logging: color variables are exported" {
    # Check a few key color variables
    [[ -n "$ACFS_RED" ]]
    [[ -n "$ACFS_GREEN" ]]
    [[ -n "$ACFS_NC" ]]
}

@test "logging: log_success prints green checkmark to stderr" {
    # run captures stdout + stderr
    run log_success "Test Success"
    
    assert_success
    assert_output --partial "Test Success"
    # Check for checkmark (UTF-8)
    assert_output --partial "✓"
}

@test "logging: log_error prints red cross to stderr" {
    run log_error "Test Error"
    
    assert_success
    assert_output --partial "Test Error"
    assert_output --partial "✖"
}

@test "logging: log_warn prints yellow warning to stderr" {
    run log_warn "Test Warning"
    
    assert_success
    assert_output --partial "Test Warning"
    assert_output --partial "⚠"
}

@test "logging: log_step supports step numbering" {
    run log_step "1/10" "Initializing"
    
    assert_success
    assert_output --partial "[1/10]"
    assert_output --partial "Initializing"
}

@test "logging: log_step supports single argument" {
    run log_step "Just a step"
    
    assert_success
    assert_output --partial "[•]"
    assert_output --partial "Just a step"
}

@test "logging: log_to_file appends to file" {
    local tmp_log
    tmp_log=$(create_temp_file)
    
    # Override logfile path logic for test
    # logging.sh uses a fixed path /var/log/acfs... unless we override the function
    # or if we can pass it?
    # log_to_file "message" "logfile"
    
    log_to_file "Test Log Entry" "$tmp_log"
    
    run cat "$tmp_log"
    assert_output --partial "Test Log Entry"
    assert_output --partial "[" # timestamp
}

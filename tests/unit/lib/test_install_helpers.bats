#!/usr/bin/env bats

load '../test_helper'

setup() {
    common_setup
    source_lib "logging"
    source_lib "install_helpers"
    
    # Mock manifest data
    export ACFS_MANIFEST_INDEX_LOADED=true
    
    # We must unset arrays first to avoid "cannot assign to element of array" if re-declaring types?
    unset ACFS_MODULES_IN_ORDER ACFS_MODULE_PHASE ACFS_MODULE_DEFAULT ACFS_MODULE_CATEGORY ACFS_MODULE_DEPS ACFS_MODULE_TAGS
    
    ACFS_MODULES_IN_ORDER=("mod1" "mod2" "mod3")
    declare -gA ACFS_MODULE_PHASE=( ["mod1"]="1" ["mod2"]="2" ["mod3"]="3" )
    declare -gA ACFS_MODULE_DEFAULT=( ["mod1"]="1" ["mod2"]="1" ["mod3"]="0" )
    declare -gA ACFS_MODULE_CATEGORY=( ["mod1"]="base" ["mod2"]="lang" ["mod3"]="tools" )
    declare -gA ACFS_MODULE_DEPS=()
    declare -gA ACFS_MODULE_TAGS=()
    
    # Selection globals (reset)
    ONLY_MODULES=()
    ONLY_PHASES=()
    SKIP_MODULES=()
    SKIP_TAGS=()
    SKIP_CATEGORIES=()
    
    # Stub sudo for run_as_target
    stub_command "sudo" "" 0
}

teardown() {
    common_teardown
}

@test "acfs_flag_bool: parses boolean values" {
    export TEST_VAR="true"
    run acfs_flag_bool "TEST_VAR"
    assert_output "1"
    
    export TEST_VAR="False"
    run acfs_flag_bool "TEST_VAR"
    assert_output "0"
    
    export TEST_VAR="1"
    run acfs_flag_bool "TEST_VAR"
    assert_output "1"
    
    export TEST_VAR="invalid"
    run acfs_flag_bool "TEST_VAR"
    # Output contains warning
    assert_output --partial "Ignoring invalid"
}

@test "acfs_resolve_selection: default selection" {
    acfs_resolve_selection
    
    # mod1 (default=1) should be selected
    if [[ -z "${ACFS_EFFECTIVE_RUN[mod1]}" ]]; then fail "mod1 not selected"; fi
    # mod3 (default=0) should NOT be selected
    if [[ -n "${ACFS_EFFECTIVE_RUN[mod3]}" ]]; then fail "mod3 selected"; fi
}

@test "acfs_resolve_selection: --only module" {
    ONLY_MODULES=("mod3")
    acfs_resolve_selection
    
    if [[ -z "${ACFS_EFFECTIVE_RUN[mod3]}" ]]; then fail "mod3 not selected"; fi
    if [[ -n "${ACFS_EFFECTIVE_RUN[mod1]}" ]]; then fail "mod1 selected"; fi
}

@test "acfs_resolve_selection: --skip module" {
    SKIP_MODULES=("mod1")
    acfs_resolve_selection
    
    if [[ -n "${ACFS_EFFECTIVE_RUN[mod1]}" ]]; then fail "mod1 selected"; fi
    if [[ -z "${ACFS_EFFECTIVE_RUN[mod2]}" ]]; then fail "mod2 not selected"; fi
}

@test "run_as_current_shell: executes command" {
    run run_as_current_shell "echo 'hello world'"
    assert_success
    assert_output "hello world"
}

@test "run_as_target_shell: calls run_as_target" {
    # Override function
    run_as_target() {
        echo "run_as_target called with: $*"
    }
    
    local out
    out=$(run_as_target_shell "echo test")
    
    # Check key parts instead of exact string to avoid expansion hell
    # We want to ensure it calls run_as_target with bash -c and sets PATH
    if [[ "$out" != *"run_as_target called with: bash -c"* ]]; then
        fail "Did not call run_as_target bash -c"
    fi
    if [[ "$out" != *"export PATH="* ]]; then
        fail "Did not export PATH"
    fi
    if [[ "$out" != *"\$HOME/.local/bin"* ]]; then
        fail "Did not include user paths (literal \$HOME)"
    fi
    if [[ "$out" != *"echo test"* ]]; then
        fail "Did not include command"
    fi
}

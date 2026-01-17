#!/usr/bin/env bats

load '../test_helper'

setup() {
    common_setup
    source_lib "logging"
    source_lib "session"
    
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
}

teardown() {
    common_teardown
}

@test "validate_session_export: validates valid json" {
    local valid_json='{
        "schema_version": 1,
        "session_id": "123",
        "agent": "claude-code",
        "stats": { "turns": 5 }
    }'
    local file=$(create_temp_file "$valid_json")
    
    run validate_session_export "$file"
    assert_success
}

@test "validate_session_export: rejects invalid json" {
    local invalid_json='{ "schema_version": 1 }' # missing session_id/agent
    local file=$(create_temp_file "$invalid_json")
    
    run validate_session_export "$file"
    assert_failure
}

@test "export_session: streams output" {
    local file=$(create_temp_file "dummy session")
    local output_file=$(create_temp_file)
    
    # Mock cass export to output valid JSON
    init_stub_dir
    cat > "$STUB_DIR/cass" <<EOF
#!/bin/bash
if [[ "\$1" == "export" ]]; then
    echo '{"schema_version": 1, "session_id": "1", "agent": "claude-code", "stats": {"turns":1}, "content": "streaming test"}'
    exit 0
fi
echo "Unknown command: \$@" >&2
exit 1
EOF
    chmod +x "$STUB_DIR/cass"
    
    run export_session "$file" --output "$output_file"
    assert_success
    
    run cat "$output_file"
    assert_output --partial "streaming test"
}

@test "sanitize_session_export: preserves structure and redacts secrets" {
    local json='{
        "schema_version": 1,
        "session_id": "123",
        "agent": "claude-code",
        "stats": { "turns": 1 },
        "sanitized_transcript": [
            { "content": "my secret is password=secret123" }
        ]
    }'
    local file=$(create_temp_file "$json")
    
    run sanitize_session_export "$file"
    assert_success
    
    run cat "$file"
    assert_output --partial "password=[REDACTED]"
    assert_output --partial '"session_id": "123"'
}

#!/usr/bin/env bash
# ============================================================
# Test: Update Channel Fix (bd-1ddv)
# Validates all update paths use --channel latest, not bare
# "claude update" which silently uses the stable channel.
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0; FAIL=0; SKIP=0
LOG_FILE="/tmp/test_update_channel_$(date +%Y%m%d_%H%M%S).log"

log()     { printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*" | tee -a "$LOG_FILE"; }
pass()    { PASS=$((PASS + 1)); log "  PASS: $1"; }
fail()    { FAIL=$((FAIL + 1)); log "  FAIL: $1"; }
skip()    { SKIP=$((SKIP + 1)); log "  SKIP: $1"; }
section() { log ""; log "=== $1 ==="; }

UPDATE_SH="$REPO_ROOT/scripts/lib/update.sh"
ZSHRC="$REPO_ROOT/acfs/zsh/acfs.zshrc"

log "Test: Update Channel Fix (bd-1ddv)"
log "Log file: $LOG_FILE"
log "Repo root: $REPO_ROOT"

# ============================================================
section "Test 1: No bare 'claude update' in run_cmd_claude_update()"
# ============================================================
# Extract the function body and check for bare invocations
func_body=$(sed -n '/^run_cmd_claude_update()/,/^}/p' "$UPDATE_SH")
if echo "$func_body" | grep -qP 'claude update(?!\s+--channel)' 2>/dev/null ||
   echo "$func_body" | grep -q 'claude update"' 2>/dev/null; then
    # Check if any grep matches are NOT --channel latest
    bare_count=$(echo "$func_body" | grep -c 'claude update' || true)
    channel_count=$(echo "$func_body" | grep -c 'claude update --channel latest' || true)
    if [[ "$bare_count" -gt "$channel_count" ]]; then
        fail "Found bare 'claude update' without --channel in run_cmd_claude_update()"
    else
        pass "No bare 'claude update' in run_cmd_claude_update()"
    fi
else
    pass "No bare 'claude update' in run_cmd_claude_update()"
fi

# ============================================================
section "Test 2: All claude update calls use --channel latest"
# ============================================================
# Count total "claude update" and "claude update --channel latest" in function
total=$(echo "$func_body" | grep -c 'claude update' || true)
with_channel=$(echo "$func_body" | grep -c 'claude update --channel latest' || true)
log "  Found $total total 'claude update' references, $with_channel with --channel latest"
if [[ "$total" -eq "$with_channel" ]] && [[ "$total" -gt 0 ]]; then
    pass "All $total claude update calls in function use --channel latest"
else
    fail "Mismatch: $total total vs $with_channel with --channel latest"
fi

# ============================================================
section "Test 3: Dry-run code path exists"
# ============================================================
# Verify the function has a DRY_RUN check that returns early
if echo "$func_body" | grep -q 'DRY_RUN.*true'; then
    if echo "$func_body" | grep -q 'return 0'; then
        pass "run_cmd_claude_update() has DRY_RUN early-return path"
    else
        fail "DRY_RUN check found but no early return"
    fi
else
    fail "No DRY_RUN check in run_cmd_claude_update()"
fi

# ============================================================
section "Test 4: cmd_display uses --channel latest"
# ============================================================
if grep -q 'cmd_display="claude update --channel latest"' "$UPDATE_SH"; then
    pass "cmd_display variable uses --channel latest"
else
    fail "cmd_display does not use --channel latest"
fi

# ============================================================
section "Test 5: uca alias uses --channel latest"
# ============================================================
if [[ -f "$ZSHRC" ]]; then
    uca_line=$(grep "alias uca=" "$ZSHRC" || true)
    if [[ -z "$uca_line" ]]; then
        fail "uca alias not found in acfs.zshrc"
    elif echo "$uca_line" | grep -q 'claude update --channel latest'; then
        pass "uca alias uses --channel latest"
    elif echo "$uca_line" | grep -q 'install.sh.*latest'; then
        pass "uca alias uses verified installer with latest channel"
    else
        fail "uca alias does not use --channel latest: $uca_line"
    fi
else
    skip "acfs.zshrc not found"
fi

# ============================================================
section "Test 6: uca alias chain integrity"
# ============================================================
if [[ -n "${uca_line:-}" ]]; then
    has_claude=false; has_codex=false; has_gemini=false
    echo "$uca_line" | grep -q 'claude' && has_claude=true
    echo "$uca_line" | grep -q 'codex' && has_codex=true
    echo "$uca_line" | grep -q 'gemini' && has_gemini=true
    if $has_claude && $has_codex && $has_gemini; then
        pass "uca alias has all 3 components (claude, codex, gemini)"
    else
        fail "uca alias missing components: claude=$has_claude codex=$has_codex gemini=$has_gemini"
    fi
else
    skip "uca alias not found"
fi

# ============================================================
section "Test 7: Completeness sweep — shell files"
# ============================================================
# Find bare "claude update" in shell files (excluding comments, test files, beads)
bare_hits=$(
    grep -rn "claude update" "$REPO_ROOT" \
        --include="*.sh" --include="*.zsh" --include="*.zshrc" --include="*.bashrc" \
        --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.beads --exclude-dir=target \
        2>/dev/null \
    | grep -v "claude update --channel" \
    | grep -v "^[[:space:]]*#" \
    | grep -v "test_update_channel" \
    | grep -v "PLAN_TO_CREATE" \
    || true
)
if [[ -z "$bare_hits" ]]; then
    pass "No bare 'claude update' in any shell files"
else
    log "  Bare hits found:"
    echo "$bare_hits" | while IFS= read -r line; do log "    $line"; done
    fail "Found bare 'claude update' in shell files (see above)"
fi

# ============================================================
section "Test 8: Documentation consistency"
# ============================================================
readme_bare=$(
    grep -n "claude update" "$REPO_ROOT/README.md" 2>/dev/null \
    | grep -v "claude update --channel" \
    | grep -v "^[[:space:]]*#" \
    || true
)
if [[ -z "$readme_bare" ]]; then
    pass "README.md has no bare 'claude update' references"
else
    log "  Bare README hits:"
    echo "$readme_bare" | while IFS= read -r line; do log "    $line"; done
    fail "README.md still has bare 'claude update' (see above)"
fi

# ============================================================
section "Test 9: Lesson/tutorial consistency"
# ============================================================
lesson_bare=$(
    grep -rn "claude update" \
        "$REPO_ROOT/acfs/onboard/" \
        "$REPO_ROOT/apps/web/components/lessons/" \
        2>/dev/null \
    | grep -v "claude update --channel" \
    | grep -v "^[[:space:]]*#" \
    || true
)
if [[ -z "$lesson_bare" ]]; then
    pass "Lessons/tutorials have no bare 'claude update' references"
else
    log "  Bare lesson hits:"
    echo "$lesson_bare" | while IFS= read -r line; do log "    $line"; done
    fail "Lessons still have bare 'claude update' (see above)"
fi

# ============================================================
section "Test 10: Channel version alignment (live, optional)"
# ============================================================
if command -v npm &>/dev/null && command -v claude &>/dev/null; then
    dist_tags=$(npm view @anthropic-ai/claude-code dist-tags 2>/dev/null || true)
    installed=$(claude --version 2>/dev/null | grep -oP '[\d]+\.[\d]+\.[\d]+' || true)
    latest=$(echo "$dist_tags" | grep -oP "latest: '\K[^']+" || true)
    stable=$(echo "$dist_tags" | grep -oP "stable: '\K[^']+" || true)
    log "  Installed: ${installed:-unknown}"
    log "  Latest:    ${latest:-unknown}"
    log "  Stable:    ${stable:-unknown}"
    if [[ -z "$installed" ]] || [[ -z "$latest" ]]; then
        skip "Could not determine version info"
    elif [[ "$installed" == "$latest" ]]; then
        pass "Installed version matches latest channel ($installed)"
    elif [[ "$installed" == "$stable" ]]; then
        fail "Installed version matches STABLE channel ($installed) — possible downgrade!"
    else
        skip "Version $installed matches neither latest ($latest) nor stable ($stable)"
    fi
else
    skip "npm or claude not available for live channel check"
fi

# ============================================================
section "Summary"
# ============================================================
log ""
log "Results: $PASS passed, $FAIL failed, $SKIP skipped"
log "Log: $LOG_FILE"

if [[ "$FAIL" -gt 0 ]]; then
    log "RESULT: FAIL"
    exit 1
else
    log "RESULT: PASS"
    exit 0
fi

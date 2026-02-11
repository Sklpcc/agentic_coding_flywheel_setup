#!/usr/bin/env bash
# ============================================================
# Test: Update Channel Fix (bd-gsjqf)
# Validates all update paths use the verified installer
# (update_run_verified_installer), not bare "claude update"
# which has no --channel flag and forces stable channel.
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

log "Test: Update Channel Fix (bd-gsjqf)"
log "Log file: $LOG_FILE"
log "Repo root: $REPO_ROOT"

# ============================================================
section "Test 1: run_cmd_claude_update() uses update_run_verified_installer"
# ============================================================
func_body=$(sed -n '/^run_cmd_claude_update()/,/^}/p' "$UPDATE_SH")
if echo "$func_body" | grep -q 'update_run_verified_installer claude latest'; then
    installer_count=$(echo "$func_body" | grep -c 'update_run_verified_installer claude latest' || true)
    pass "run_cmd_claude_update() uses update_run_verified_installer ($installer_count calls)"
else
    fail "run_cmd_claude_update() does not use update_run_verified_installer"
fi

# ============================================================
section "Test 2: No bare 'claude update' execution in run_cmd_claude_update()"
# ============================================================
# Check for any actual 'claude update' command invocations (not comments or strings)
bare_exec=$(echo "$func_body" | grep -v '^\s*#' | grep -v 'cmd_display=' | grep 'claude update' || true)
if [[ -z "$bare_exec" ]]; then
    pass "No bare 'claude update' execution in run_cmd_claude_update()"
else
    fail "Found bare 'claude update' execution in run_cmd_claude_update(): $bare_exec"
fi

# ============================================================
section "Test 3: Dry-run code path exists"
# ============================================================
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
section "Test 4: cmd_display references verified installer"
# ============================================================
if grep -q 'cmd_display="update_run_verified_installer claude latest"' "$UPDATE_SH"; then
    pass "cmd_display variable references verified installer"
else
    fail "cmd_display does not reference verified installer"
fi

# ============================================================
section "Test 5: uca alias uses verified installer (not bare claude update)"
# ============================================================
if [[ -f "$ZSHRC" ]]; then
    uca_line=$(grep "alias uca=" "$ZSHRC" || true)
    if [[ -z "$uca_line" ]]; then
        fail "uca alias not found in acfs.zshrc"
    elif echo "$uca_line" | grep -q 'install.sh.*latest'; then
        pass "uca alias uses verified installer with latest channel"
    elif echo "$uca_line" | grep -q 'update_run_verified_installer'; then
        pass "uca alias uses update_run_verified_installer"
    else
        fail "uca alias does not use verified installer: $uca_line"
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
section "Test 7: Completeness sweep — no bare claude update in shell files"
# ============================================================
# Find bare "claude update" in shell files (excluding comments, test files, beads)
bare_hits=$(
    rg -n "claude update" "$REPO_ROOT"         -g '*.sh' -g '*.zsh' -g '*.zshrc' -g '*.bashrc'         --glob '!.git' --glob '!node_modules' --glob '!.beads' --glob '!target'         2>/dev/null     | grep -v 'update_run_verified_installer'     | grep -v 'install.sh.*latest'     | grep -v '^\s*#'     | grep -v 'test_update_channel'     | grep -v 'PLAN_TO_CREATE'     | grep -v 'cmd_display='     | grep -v 'FIX(bd-gsjqf'     || true
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
    rg -n "claude update" "$REPO_ROOT/README.md" 2>/dev/null     | grep -v 'install.sh'     | grep -v 'update_run_verified_installer'     | grep -v '^\s*#'     || true
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
    rg -rn "claude update"         "$REPO_ROOT/acfs/onboard/"         "$REPO_ROOT/apps/web/components/lessons/"         2>/dev/null     | grep -v 'install.sh'     | grep -v 'update_run_verified_installer'     | grep -v '^\s*#'     || true
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

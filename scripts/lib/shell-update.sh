#!/usr/bin/env bash
# ============================================================
# ACFS Update - Shell Tools
# Updates oh-my-zsh, plugins, and shell utilities
# ============================================================

# Update Oh-My-Zsh
update_omz() {
    local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"

    if [[ ! -d "$zsh_dir" ]]; then
        log_item "skip" "Oh-My-Zsh" "not installed"
        return 0
    fi

    # OMZ has its own upgrade script
    if [[ -x "$zsh_dir/tools/upgrade.sh" ]]; then
        DISABLE_UPDATE_PROMPT=true run_cmd "Oh-My-Zsh" "$zsh_dir/tools/upgrade.sh"
    else
        if git -C "$zsh_dir" pull --ff-only &>/dev/null; then
            log_item "ok" "Oh-My-Zsh" "updated via git"
        else
            log_item "skip" "Oh-My-Zsh" "fast-forward failed (local changes?)"
            log_to_file "OMZ git pull --ff-only failed, user may have local changes"
        fi
    fi
}

# Update Powerlevel10k theme
update_p10k() {
    local zsh_custom="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}"
    local p10k_dir="$zsh_custom/themes/powerlevel10k"

    if [[ ! -d "$p10k_dir" ]]; then
        log_item "skip" "Powerlevel10k" "not installed"
        return 0
    fi

    if git -C "$p10k_dir" pull --ff-only &>/dev/null; then
        log_item "ok" "Powerlevel10k" "updated"
    else
        log_item "skip" "Powerlevel10k" "fast-forward failed (local changes?)"
    fi
}

# Update zsh plugins
update_zsh_plugins() {
    local zsh_custom="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}"

    for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
        local plugin_dir="$zsh_custom/plugins/$plugin"
        if [[ -d "$plugin_dir" ]]; then
            if git -C "$plugin_dir" pull --ff-only &>/dev/null; then
                log_item "ok" "$plugin" "updated"
            else
                log_item "skip" "$plugin" "fast-forward failed"
            fi
        else
            log_item "skip" "$plugin" "not installed"
        fi
    done
}

# Update Atuin (shell history sync)
update_atuin() {
    if ! command -v atuin &>/dev/null; then
        log_item "skip" "Atuin" "not installed"
        return 0
    fi

    if atuin self-update --help &>/dev/null 2>&1; then
        run_cmd "Atuin self-update" atuin self-update
    else
        log_item "skip" "Atuin" "no self-update, use installer to update"
    fi
}

# Update Zoxide (smarter cd)
update_zoxide() {
    if ! command -v zoxide &>/dev/null; then
        log_item "skip" "Zoxide" "not installed"
        return 0
    fi

    if [[ -f "$HOME/.cargo/bin/zoxide" ]]; then
        if command -v cargo &>/dev/null; then
            run_cmd "Zoxide (cargo)" cargo install zoxide --locked
        else
            log_item "skip" "Zoxide" "cargo not available for update"
        fi
    else
        log_item "skip" "Zoxide" "update via system package manager"
    fi
}

# Main shell update function
update_shell() {
    log_section "Shell Tools"

    update_omz
    update_p10k
    update_zsh_plugins
    update_atuin
    update_zoxide
}

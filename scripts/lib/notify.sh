#!/usr/bin/env bash
# ============================================================
# ACFS Installer - ntfy.sh Notification Library
#
# Provides lightweight push notifications via ntfy.sh for
# installation events, agent completions, and system alerts.
# Zero-config: silent no-op when disabled or unconfigured.
#
# Related bead: bd-2igt6
# ============================================================

# Prevent multiple sourcing
if [[ -n "${_ACFS_NOTIFY_SH_LOADED:-}" ]]; then
    return 0
fi
_ACFS_NOTIFY_SH_LOADED=1

# ============================================================
# Configuration
# ============================================================
# Config file: ~/.config/acfs/config.yaml
# Keys:
#   ntfy_enabled: true|false
#   ntfy_topic: <random-topic-string>
#   ntfy_server: https://ntfy.sh  (default, can be self-hosted)

# Default ntfy server
ACFS_NTFY_SERVER_DEFAULT="https://ntfy.sh"

# ============================================================
# Config Reader
# ============================================================

# Read a single key from ACFS config.yaml
# Usage: _acfs_notify_config_read <key>
# Returns: value on stdout, or empty string
_acfs_notify_config_read() {
    local key="$1"
    local config_file="${HOME}/.config/acfs/config.yaml"

    # Also check target user's config if running as root
    if [[ "$(id -u)" -eq 0 ]] && [[ -n "${TARGET_HOME:-}" ]]; then
        config_file="${TARGET_HOME}/.config/acfs/config.yaml"
    fi

    if [[ ! -f "$config_file" ]]; then
        return 0
    fi

    # Simple YAML parsing: key: "value" or key: 'value' or key: value
    local val
    val=$(grep -E "^\s*${key}\s*:" "$config_file" 2>/dev/null | head -1 | \
          sed -E "s/^\s*${key}\s*:\s*//; s/^[\"']//; s/[\"']\s*$//" | \
          sed 's/^[[:space:]]*//; s/[[:space:]]*$//') || true

    printf '%s' "$val"
}

# ============================================================
# Core Notification Function
# ============================================================

# Send a notification via ntfy.sh (non-blocking, best-effort)
#
# Usage: acfs_notify <title> [body] [priority]
#   title:    Short notification title (required)
#   body:     Longer description (optional, default: "")
#   priority: ntfy priority 1-5 or name (optional, default: "default")
#             1=min, 2=low, 3=default, 4=high, 5=urgent
#
# Environment overrides:
#   ACFS_NTFY_ENABLED=true|false  Override config
#   ACFS_NTFY_TOPIC=<topic>       Override config
#   ACFS_NTFY_SERVER=<url>        Override config
#
# Returns: 0 always (never fails, never blocks)
acfs_notify() {
    local title="${1:-}"
    local body="${2:-}"
    local priority="${3:-default}"

    # Must have a title
    if [[ -z "$title" ]]; then
        return 0
    fi

    # Check if enabled (env override > config file)
    local enabled="${ACFS_NTFY_ENABLED:-}"
    if [[ -z "$enabled" ]]; then
        enabled=$(_acfs_notify_config_read "ntfy_enabled")
    fi

    # Not enabled or explicitly disabled -> silent no-op
    if [[ "$enabled" != "true" ]]; then
        return 0
    fi

    # Read topic (env override > config file)
    local topic="${ACFS_NTFY_TOPIC:-}"
    if [[ -z "$topic" ]]; then
        topic=$(_acfs_notify_config_read "ntfy_topic")
    fi

    # No topic configured -> silent no-op
    if [[ -z "$topic" ]]; then
        return 0
    fi

    # Read server (env override > config file > default)
    local server="${ACFS_NTFY_SERVER:-}"
    if [[ -z "$server" ]]; then
        server=$(_acfs_notify_config_read "ntfy_server")
    fi
    if [[ -z "$server" ]]; then
        server="$ACFS_NTFY_SERVER_DEFAULT"
    fi

    # Require curl
    if ! command -v curl &>/dev/null; then
        return 0
    fi

    # Send notification in background (non-blocking, fire-and-forget)
    (
        curl -s -o /dev/null \
            --max-time 10 \
            -H "Title: ${title}" \
            -H "Priority: ${priority}" \
            -H "Tags: computer,acfs" \
            -d "${body:-$title}" \
            "${server}/${topic}" 2>/dev/null || true
    ) &
    disown 2>/dev/null || true

    return 0
}

# ============================================================
# Convenience Wrappers
# ============================================================

# Notify install success
# Usage: acfs_notify_install_success [duration_human]
acfs_notify_install_success() {
    local duration="${1:-}"
    local hostname
    hostname=$(hostname 2>/dev/null || echo "unknown")
    local body="Host: ${hostname}"
    if [[ -n "$duration" ]]; then
        body="${body} | Duration: ${duration}"
    fi
    acfs_notify "ACFS Install Complete" "$body" "default"
}

# Notify install failure
# Usage: acfs_notify_install_failure [error_msg]
acfs_notify_install_failure() {
    local error="${1:-Unknown error}"
    local hostname
    hostname=$(hostname 2>/dev/null || echo "unknown")
    acfs_notify "ACFS Install Failed" "Host: ${hostname} | Error: ${error}" "high"
}

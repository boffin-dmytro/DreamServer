#!/bin/bash
# ============================================================================
# Dream Server Installer — Validation Library
# ============================================================================
# Part of: installers/lib/
# Purpose: Shared validation functions for installer scripts
#
# Provides: validate_installer_script()
# ============================================================================

# ============================================================================
# validate_installer_script: Verify downloaded script is safe to execute
# ============================================================================
# Args: $1 = file path, $2 = expected keyword (e.g., "docker")
# Returns: 0 if valid, 1 if suspicious
#
# Checks performed:
#   - File exists and is readable
#   - File size is reasonable (1KB - 200KB)
#   - Not an HTML error page (checks for DOCTYPE, html, title, body tags)
#   - Contains bash script indicators (shebang, common commands)
#   - Contains expected keyword (if provided)
#
# This provides practical security against common failure modes:
#   - Executing HTML 404/error pages as bash
#   - Running corrupted downloads from network issues
#   - Running files that are obviously not bash scripts
#
# Note: This is NOT a substitute for checksum verification. These installer
# scripts update frequently, so content validation provides a balance between
# security and maintainability.
# ============================================================================
validate_installer_script() {
    local file="$1"
    local keyword="$2"

    # Check file exists and is readable
    [[ ! -f "$file" || ! -r "$file" ]] && return 1

    # Check file size (1KB - 200KB is reasonable for install scripts)
    local size=$(wc -c < "$file" 2>/dev/null)
    [[ -z "$size" || $size -lt 1000 || $size -gt 204800 ]] && return 1

    # Check for HTML error page indicators
    if head -n 20 "$file" | grep -qiE '<!DOCTYPE|<html|<title|<body'; then
        return 1
    fi

    # Check for bash script indicators
    if ! head -n 50 "$file" | grep -qE '#!/bin/(ba)?sh|^(set|if|for|while|function|echo|command)'; then
        return 1
    fi

    # Check for expected keyword (fixed string match for robustness)
    if [[ -n "$keyword" ]] && ! grep -qiF "$keyword" "$file"; then
        return 1
    fi

    return 0
}

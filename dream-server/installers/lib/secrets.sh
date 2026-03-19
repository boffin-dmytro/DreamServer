#!/bin/bash
# ============================================================================
# Dream Server Installer — Secret Generation Library
# ============================================================================
# Part of: installers/lib/
# Purpose: Pure functions for generating cryptographically secure secrets
#
# Expects: (nothing — pure functions)
# Provides: generate_hex_secret(), generate_base64_secret(), generate_api_key()
#
# Modder notes:
#   All functions are pure (no side effects) and use openssl rand with
#   fallback to /dev/urandom for maximum portability.
# ============================================================================

# Generate a hex-encoded secret
# Usage: generate_hex_secret [bytes]
# Default: 32 bytes (64 hex characters)
generate_hex_secret() {
    local bytes="${1:-32}"
    openssl rand -hex "$bytes" 2>/dev/null || head -c "$bytes" /dev/urandom | xxd -p
}

# Generate a base64-encoded secret
# Usage: generate_base64_secret [bytes]
# Default: 16 bytes (~22 base64 characters)
generate_base64_secret() {
    local bytes="${1:-16}"
    openssl rand -base64 "$bytes" 2>/dev/null | tr -d '\n' || head -c "$bytes" /dev/urandom | base64 | tr -d '\n'
}

# Generate an API key with prefix
# Usage: generate_api_key [prefix] [bytes]
# Default: "sk-dream-" prefix, 16 bytes
generate_api_key() {
    local prefix="${1:-sk-dream-}"
    local bytes="${2:-16}"
    echo "${prefix}$(generate_hex_secret "$bytes")"
}

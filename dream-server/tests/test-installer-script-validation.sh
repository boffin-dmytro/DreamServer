#!/usr/bin/env bash
# ============================================================================
# Test: Installer Script Validation
# ============================================================================
# Tests content validation for downloaded installer scripts
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS++))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL++))
}

info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# ============================================================================
# Test 1: Phase 05 has validation function
# ============================================================================
test_phase05_has_validation() {
    info "Testing phase 05 has validate_installer_script function..."

    local phase05="$ROOT_DIR/installers/phases/05-docker.sh"

    if ! grep -q "validate_installer_script()" "$phase05"; then
        fail "phase 05 missing validate_installer_script function"
        return
    fi

    if ! grep -q "validate_installer_script.*docker" "$phase05"; then
        fail "phase 05 doesn't call validation with 'docker' keyword"
        return
    fi

    pass "phase 05 has validate_installer_script function"
}

# ============================================================================
# Test 2: Phase 07 has validation function
# ============================================================================
test_phase07_has_validation() {
    info "Testing phase 07 has validate_installer_script function..."

    local phase07="$ROOT_DIR/installers/phases/07-devtools.sh"

    if ! grep -q "validate_installer_script()" "$phase07"; then
        fail "phase 07 missing validate_installer_script function"
        return
    fi

    if ! grep -q "validate_installer_script.*node" "$phase07"; then
        fail "phase 07 doesn't validate NodeSource script"
        return
    fi

    if ! grep -q "validate_installer_script.*opencode" "$phase07"; then
        fail "phase 07 doesn't validate OpenCode script"
        return
    fi

    pass "phase 07 has validate_installer_script function"
}

# ============================================================================
# Test 3: Phases use trap handlers for cleanup
# ============================================================================
test_trap_handlers() {
    info "Testing phases use trap handlers for temp file cleanup..."

    local phase05="$ROOT_DIR/installers/phases/05-docker.sh"
    local phase07="$ROOT_DIR/installers/phases/07-devtools.sh"

    if ! grep -q "trap.*rm.*tmpfile.*EXIT" "$phase05"; then
        fail "phase 05 missing trap handler for temp file cleanup"
        return
    fi

    if ! grep -q "trap.*rm.*tmpfile.*EXIT" "$phase07"; then
        fail "phase 07 missing trap handler for temp file cleanup"
        return
    fi

    pass "phases use trap handlers for cleanup"
}

# ============================================================================
# Test 4: Phases use timeouts on curl
# ============================================================================
test_curl_timeouts() {
    info "Testing phases use timeouts on curl operations..."

    local phase05="$ROOT_DIR/installers/phases/05-docker.sh"
    local phase07="$ROOT_DIR/installers/phases/07-devtools.sh"

    if ! grep -q "curl.*--max-time" "$phase05"; then
        fail "phase 05 missing timeout on curl"
        return
    fi

    if ! grep -q "curl.*--max-time" "$phase07"; then
        fail "phase 07 missing timeout on curl"
        return
    fi

    pass "phases use timeouts on curl operations"
}

# ============================================================================
# Test 5: Validation function logic
# ============================================================================
test_validation_logic() {
    info "Testing validation function logic with test data..."

    # Create a temporary test script
    local test_script=$(mktemp /tmp/test-validation.XXXXXX.sh)

    # Test 1: Valid bash script (needs to be >1KB for size check)
    cat > "$test_script" <<'EOF'
#!/bin/bash
set -e
echo "Installing docker..."
command -v docker || echo "Docker not found"

# Add padding to make file larger than 1KB minimum
# This simulates a real installer script which would be several KB
# Real installer scripts are typically 3-25KB in size
# Padding with comments to reach minimum size requirement
# ============================================================================
# Docker Installation Script
# ============================================================================
# This is a test script that simulates a real Docker installer
# Real installers contain extensive error checking, platform detection,
# package manager logic, and installation steps
# ============================================================================
# Platform Detection
# ============================================================================
# Detect OS, distribution, version, architecture
# Check for supported platforms
# Verify system requirements
# ============================================================================
# Dependency Checks
# ============================================================================
# Check for required tools: curl, wget, apt/yum/dnf
# Verify network connectivity
# Check disk space
# ============================================================================
# Installation Steps
# ============================================================================
# Add Docker repository
# Update package cache
# Install Docker packages
# Configure Docker daemon
# Start Docker service
# Add user to docker group
# ============================================================================
# Post-Installation
# ============================================================================
# Verify installation
# Run hello-world container
# Display next steps
# ============================================================================
EOF

    # Source the validation function from phase 05
    source <(grep -A 30 "validate_installer_script()" "$ROOT_DIR/installers/phases/05-docker.sh" | grep -B 30 "^}")

    if ! validate_installer_script "$test_script" "docker"; then
        fail "validation rejected valid bash script with keyword"
        rm -f "$test_script"
        return
    fi

    # Test 2: HTML error page
    cat > "$test_script" <<'EOF'
<!DOCTYPE html>
<html>
<head><title>404 Not Found</title></head>
<body>Page not found</body>
</html>
EOF

    if validate_installer_script "$test_script" "docker"; then
        fail "validation accepted HTML error page"
        rm -f "$test_script"
        return
    fi

    # Test 3: Script without expected keyword
    cat > "$test_script" <<'EOF'
#!/bin/bash
echo "Hello world"
EOF

    if validate_installer_script "$test_script" "docker"; then
        fail "validation accepted script without expected keyword"
        rm -f "$test_script"
        return
    fi

    # Test 4: File too small
    echo "hi" > "$test_script"
    if validate_installer_script "$test_script" ""; then
        fail "validation accepted file that's too small"
        rm -f "$test_script"
        return
    fi

    rm -f "$test_script"
    pass "validation function logic works correctly"
}

# ============================================================================
# Test 6: Error messages are improved
# ============================================================================
test_error_messages() {
    info "Testing error messages are descriptive..."

    local phase05="$ROOT_DIR/installers/phases/05-docker.sh"
    local phase07="$ROOT_DIR/installers/phases/07-devtools.sh"

    # Check for descriptive error messages
    if ! grep -q "failed validation" "$phase05"; then
        fail "phase 05 missing descriptive validation error message"
        return
    fi

    if ! grep -q "failed validation" "$phase07"; then
        fail "phase 07 missing descriptive validation error message"
        return
    fi

    pass "error messages are descriptive"
}

# ============================================================================
# Run all tests
# ============================================================================

echo "============================================"
echo "Installer Script Validation Tests"
echo "============================================"
echo ""

test_phase05_has_validation
test_phase07_has_validation
test_trap_handlers
test_curl_timeouts
test_validation_logic
test_error_messages

echo ""
echo "============================================"
if [[ $FAIL -eq 0 ]]; then
    echo -e "Results: \033[0;32m${PASS} passed\033[0m, \033[0;31m${FAIL} failed\033[0m"
else
    echo -e "Results: \033[0;32m${PASS} passed\033[0m, \033[0;31m${FAIL} failed\033[0m"
fi
echo "============================================"

exit $FAIL

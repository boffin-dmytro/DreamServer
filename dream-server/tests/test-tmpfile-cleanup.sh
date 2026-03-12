#!/bin/bash
# ============================================================================
# Dream Server Temporary File Cleanup Test Suite
# ============================================================================
# Tests that temporary files are properly cleaned up with trap handlers
#
# Usage: ./tests/test-tmpfile-cleanup.sh
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║   Temporary File Cleanup Test Suite      ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

echo "1. Trap Handler Presence Tests"
echo "───────────────────────────────"

# Test 1: Phase 05 has trap handler for Docker tmpfile
printf "  %-50s " "Phase 05 Docker tmpfile has trap handler..."
if grep -A 1 'mktemp /tmp/install-docker' "$ROOT_DIR/installers/phases/05-docker.sh" | grep -q "trap.*rm -f.*tmpfile.*INT TERM"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

# Test 2: Phase 05 removes trap after cleanup
printf "  %-50s " "Phase 05 removes trap after cleanup..."
if grep -A 10 'mktemp /tmp/install-docker' "$ROOT_DIR/installers/phases/05-docker.sh" | grep -q "trap - INT TERM"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

# Test 3: Phase 07 NodeSource has trap handler
printf "  %-50s " "Phase 07 NodeSource tmpfile has trap handler..."
if grep -A 1 'mktemp /tmp/nodesource-setup' "$ROOT_DIR/installers/phases/07-devtools.sh" | grep -q "trap.*rm -f.*tmpfile.*INT TERM"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

# Test 4: Phase 07 NodeSource removes trap after cleanup
printf "  %-50s " "Phase 07 NodeSource removes trap after cleanup..."
if grep -A 10 'mktemp /tmp/nodesource-setup' "$ROOT_DIR/installers/phases/07-devtools.sh" | grep -q "trap - INT TERM"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

# Test 5: Phase 07 OpenCode has trap handler
printf "  %-50s " "Phase 07 OpenCode tmpfile has trap handler..."
if grep -A 1 'mktemp /tmp/opencode-install' "$ROOT_DIR/installers/phases/07-devtools.sh" | grep -q "trap.*rm -f.*tmpfile.*INT TERM"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

# Test 6: Phase 07 OpenCode removes trap after cleanup
printf "  %-50s " "Phase 07 OpenCode removes trap after cleanup..."
if grep -A 10 'mktemp /tmp/opencode-install' "$ROOT_DIR/installers/phases/07-devtools.sh" | grep -q "trap - INT TERM"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

echo ""
echo "2. Explicit Cleanup Tests"
echo "─────────────────────────"

# Test 7: Phase 05 has explicit cleanup after success
printf "  %-50s " "Phase 05 has explicit cleanup after success..."
if grep -A 10 'mktemp /tmp/install-docker' "$ROOT_DIR/installers/phases/05-docker.sh" | grep -q "rm -f.*tmpfile"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

# Test 8: Phase 05 has explicit cleanup in error path
printf "  %-50s " "Phase 05 has explicit cleanup in error path..."
if grep -B 2 'error "Docker installation failed' "$ROOT_DIR/installers/phases/05-docker.sh" | grep -q "rm -f.*tmpfile"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

# Test 9: Phase 07 NodeSource has explicit cleanup
printf "  %-50s " "Phase 07 NodeSource has explicit cleanup..."
if grep -A 10 'mktemp /tmp/nodesource-setup' "$ROOT_DIR/installers/phases/07-devtools.sh" | grep -q "rm -f.*tmpfile"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

# Test 10: Phase 07 OpenCode has explicit cleanup
printf "  %-50s " "Phase 07 OpenCode has explicit cleanup..."
if grep -A 10 'mktemp /tmp/opencode-install' "$ROOT_DIR/installers/phases/07-devtools.sh" | grep -q "rm -f.*tmpfile"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

echo ""
echo "3. Trap Strategy Tests"
echo "──────────────────────"

# Test 11: Traps use INT TERM (not EXIT to avoid parent override)
printf "  %-50s " "Traps use INT TERM signals only..."
trap_count=$(grep -h "trap.*rm -f.*tmpfile" "$ROOT_DIR/installers/phases/05-docker.sh" "$ROOT_DIR/installers/phases/07-devtools.sh" | grep -c "INT TERM" || echo "0")
if [[ "$trap_count" -ge 3 ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} (found $trap_count, expected 3+)"
    ((FAILED++))
fi

# Test 12: No EXIT traps (to avoid overriding parent traps)
printf "  %-50s " "No EXIT traps that could override parent..."
if ! grep -h "trap.*rm -f.*tmpfile.*EXIT" "$ROOT_DIR/installers/phases/05-docker.sh" "$ROOT_DIR/installers/phases/07-devtools.sh" 2>/dev/null; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

echo ""
echo "═══════════════════════════════════════════"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed${NC} ($PASSED/$((PASSED + FAILED)))"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC} ($PASSED passed, $FAILED failed)"
    echo ""
    exit 1
fi

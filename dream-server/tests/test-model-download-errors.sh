#!/bin/bash
# ============================================================================
# Dream Server Model Download Error Messages Test Suite
# ============================================================================
# Tests that model download failures show helpful error messages
#
# Usage: ./tests/test-model-download-errors.sh
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
echo "║   Model Download Error Messages Tests    ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

echo "1. Error Capture Tests"
echo "──────────────────────"

# Test 1: Error log capture exists
printf "  %-50s " "Error log capture implemented..."
if grep -q "_error_log=\$(mktemp)" "$ROOT_DIR/installers/phases/11-services.sh"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

# Test 2: Last error variable exists
printf "  %-50s " "_last_error variable defined..."
if grep -q "_last_error=" "$ROOT_DIR/installers/phases/11-services.sh"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

# Test 3: Error log cleanup exists
printf "  %-50s " "Error log cleanup implemented..."
if grep -q "rm -f.*_error_log" "$ROOT_DIR/installers/phases/11-services.sh"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

echo ""
echo "2. Error Message Display Tests"
echo "───────────────────────────────"

# Test 4: Last error is shown on failure
printf "  %-50s " "Last error displayed on failure..."
if grep -A 5 "Download failed after 3 attempts" "$ROOT_DIR/installers/phases/11-services.sh" | grep -q "Last error:"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

# Test 5: Troubleshooting section exists
printf "  %-50s " "Troubleshooting section exists..."
if grep -A 10 "Download failed after 3 attempts" "$ROOT_DIR/installers/phases/11-services.sh" | grep -q "Troubleshooting:"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

echo ""
echo "3. Troubleshooting Suggestions Tests"
echo "─────────────────────────────────────"

# Test 6: Network connectivity check suggested
printf "  %-50s " "Network connectivity check suggested..."
if grep -A 15 "Download failed after 3 attempts" "$ROOT_DIR/installers/phases/11-services.sh" | grep -q "ping.*huggingface"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

# Test 7: Disk space check suggested
printf "  %-50s " "Disk space check suggested..."
if grep -A 15 "Download failed after 3 attempts" "$ROOT_DIR/installers/phases/11-services.sh" | grep -q "df -h"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

# Test 8: Download log check suggested
printf "  %-50s " "Download log check suggested..."
if grep -A 15 "Download failed after 3 attempts" "$ROOT_DIR/installers/phases/11-services.sh" | grep -q "tail.*model-download.log"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi

# Test 9: Manual retry command still exists
printf "  %-50s " "Manual retry command provided..."
if grep -A 20 "Download failed after 3 attempts" "$ROOT_DIR/installers/phases/11-services.sh" | grep -q "Manual retry: wget"; then
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

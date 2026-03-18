#!/bin/bash
# ============================================================================
# Integration Test: .env Validation
# ============================================================================
# Tests that validate-env.sh correctly validates .env files against schema
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_DIR="/tmp/dream-env-test-$$"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cleanup() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}
trap cleanup EXIT

echo "=== Integration Test: .env Validation ==="
echo "Test directory: $TEST_DIR"
echo ""

mkdir -p "$TEST_DIR"

# Test 1: Valid .env.example passes validation
echo "Test 1: Valid .env.example passes validation"
if [[ -f "$SCRIPT_DIR/.env.example" && -f "$SCRIPT_DIR/.env.schema.json" ]]; then
    if bash "$SCRIPT_DIR/scripts/validate-env.sh" "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env.schema.json" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} .env.example passes validation"
    else
        echo -e "${RED}✗${NC} .env.example failed validation"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠${NC} .env.example or .env.schema.json not found, skipping test"
fi

# Test 2: Missing required key fails validation
echo ""
echo "Test 2: Missing required key fails validation"
cat > "$TEST_DIR/test.env" <<'EOF'
# Missing WEBUI_SECRET (required)
N8N_USER=admin
N8N_PASS=password
LITELLM_KEY=sk-test
OPENCLAW_TOKEN=test-token
EOF

if bash "$SCRIPT_DIR/scripts/validate-env.sh" "$TEST_DIR/test.env" "$SCRIPT_DIR/.env.schema.json" >/dev/null 2>&1; then
    echo -e "${RED}✗${NC} Validation should have failed for missing required key"
    exit 1
else
    echo -e "${GREEN}✓${NC} Validation correctly failed for missing required key"
fi

# Test 3: Invalid enum value fails validation
echo ""
echo "Test 3: Invalid enum value fails validation"
cat > "$TEST_DIR/test.env" <<'EOF'
WEBUI_SECRET=test-secret-12345678901234567890123456789012
N8N_USER=admin
N8N_PASS=password
LITELLM_KEY=sk-test
OPENCLAW_TOKEN=test-token
DREAM_MODE=invalid_mode
EOF

if bash "$SCRIPT_DIR/scripts/validate-env.sh" "$TEST_DIR/test.env" "$SCRIPT_DIR/.env.schema.json" >/dev/null 2>&1; then
    echo -e "${RED}✗${NC} Validation should have failed for invalid enum value"
    exit 1
else
    echo -e "${GREEN}✓${NC} Validation correctly failed for invalid enum value"
fi

# Test 4: Duplicate keys fail validation
echo ""
echo "Test 4: Duplicate keys fail validation"
cat > "$TEST_DIR/test.env" <<'EOF'
WEBUI_SECRET=test-secret-12345678901234567890123456789012
N8N_USER=admin
N8N_PASS=password
LITELLM_KEY=sk-test
OPENCLAW_TOKEN=test-token
DREAM_MODE=local
DREAM_MODE=cloud
EOF

if bash "$SCRIPT_DIR/scripts/validate-env.sh" "$TEST_DIR/test.env" "$SCRIPT_DIR/.env.schema.json" >/dev/null 2>&1; then
    echo -e "${RED}✗${NC} Validation should have failed for duplicate keys"
    exit 1
else
    echo -e "${GREEN}✓${NC} Validation correctly failed for duplicate keys"
fi

echo ""
echo -e "${GREEN}All .env validation tests passed${NC}"

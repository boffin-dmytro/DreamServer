#!/usr/bin/env bash
# ==========================================================================
# Test: Model Download Error Messages (behavioral)
# ==========================================================================
# Ensures model download failures:
#  - keep detailed output in logs/model-download.log
#  - show a useful "Last error" line
#  - provide actionable troubleshooting guidance
#
# Usage: ./tests/test-model-download-errors.sh
# ==========================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

# Subshell tests don't update parent variables; use a temp file instead.
RESULTS_FILE="$(mktemp)"
trap 'rm -f "$RESULTS_FILE"' EXIT
: >"$RESULTS_FILE"

pass() { echo -e "${GREEN}[PASS]${NC} $1"; echo PASS >>"$RESULTS_FILE"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; echo FAIL >>"$RESULTS_FILE"; }
info() { echo -e "${YELLOW}[INFO]${NC} $1"; }

run_phase11_download_block() {
    local wget_script=$1

    local tmpdir
    tmpdir=$(mktemp -d)

    mkdir -p "$tmpdir/bin" "$tmpdir/installers/phases" "$tmpdir/installers/lib" "$tmpdir/logs" "$tmpdir/data/models"

    # Emit the temp install dir so callers can inspect log files.
    echo "__INSTALL_DIR__=$tmpdir"

    # NOTE: caller is responsible for cleanup (rm -rf).

    # Provide a mock wget in PATH
    cp "$wget_script" "$tmpdir/bin/wget"
    chmod +x "$tmpdir/bin/wget"

    # Minimal stubs expected by phase 11
    cat >"$tmpdir/installers/lib/ui.sh" <<'EOF'
ai() { echo "$*"; }
ai_ok() { echo "$*"; }
ai_bad() { echo "$*"; }
ai_warn() { echo "$*"; }
signal() { :; }
show_phase() { :; }
log() { :; }
# Wait for PID; return 0/1 based on exit status
spin_task() {
  local pid=$1
  wait "$pid"
}
EOF

    # Copy phase 11 into place and run it in an isolated shell
    cp "$ROOT_DIR/installers/phases/11-services.sh" "$tmpdir/installers/phases/11-services.sh"

    (
        set -euo pipefail
        export PATH="$tmpdir/bin:$PATH"

        # Vars phase 11 expects
        export DRY_RUN=false
        export INSTALL_DIR="$tmpdir"
        export LOG_FILE="$tmpdir/logs/install.log"
        export GPU_BACKEND="none"
        export GGUF_FILE="test.gguf"
        export GGUF_URL="https://example.invalid/test.gguf"
        export GGUF_SHA256=""
        export LLM_MODEL="test"
        export MAX_CONTEXT=4096
        export DREAM_MODE="local"

        # Vars used later in phase 11; set them to safe no-ops so the script can run
        export DOCKER_COMPOSE_CMD=true
        export COMPOSE_FLAGS=""

        # Colors used by printf blocks
        export BGRN="" GRN="" RED="" AMB="" NC=""

        # Keep tests fast
        sleep() { :; }

        # Pull in UI helpers then run phase
        # shellcheck disable=SC1091
        source "$tmpdir/installers/lib/ui.sh"
        # shellcheck disable=SC1091
        source "$tmpdir/installers/phases/11-services.sh"

        # phase 11 will exit 1 if download fails (expected in some tests)
    )
}

make_mock_wget_fail() {
    local path=$1
    local stderr_msg=$2
    local stdout_msg=${3:-""}

    local stderr_q stdout_q
    stderr_q=$(printf '%q' "$stderr_msg")
    stdout_q=$(printf '%q' "$stdout_msg")

    cat >"$path" <<EOF
#!/usr/bin/env bash
# Minimal wget mock. Supports: -c -q -O <file> <url>

out=""
while [[ \$# -gt 0 ]]; do
  case "\$1" in
    -O) out="\$2"; shift 2;;
    *) shift;;
  esac
done

if [[ -n $stdout_q ]]; then
  printf '%s\n' $stdout_q
fi
printf '%s\n' $stderr_q >&2
# create part file so mv logic has something to act on if needed
[[ -n "\$out" ]] && : >"\$out"
exit 4
EOF
    chmod +x "$path"
}

make_mock_wget_succeed() {
    local path=$1
    local stdout_msg=${2:-""}

    local stdout_q
    stdout_q=$(printf '%q' "$stdout_msg")

    cat >"$path" <<EOF
#!/usr/bin/env bash
out=""
while [[ \$# -gt 0 ]]; do
  case "\$1" in
    -O) out="\$2"; shift 2;;
    *) shift;;
  esac
done

if [[ -n $stdout_q ]]; then
  printf '%s\n' $stdout_q
fi
[[ -n "\$out" ]] && echo "ok" >"\$out"
exit 0
EOF
    chmod +x "$path"
}

main() {
# ==========================================================================
# Tests
# ==========================================================================

info "Running behavioral tests for model download errors..."

# Test 1: stderr should be present in model-download.log on failure
(
    tmp_wget=$(mktemp)
    tmp_root=$(mktemp -d)
    # shellcheck disable=SC2064
    trap "rm -f '$tmp_wget'; rm -rf '$tmp_root'" RETURN

    export TMPDIR="$tmp_root"
    export TMP="$tmp_root"
    export TEMP="$tmp_root"

    make_mock_wget_fail "$tmp_wget" "wget: unable to resolve host address 'huggingface.co'" "progress..."

    set +e
    out=$(run_phase11_download_block "$tmp_wget" 2>&1)
    status=$?
    set -e

    if [[ $status -eq 0 ]]; then
        fail "expected phase 11 to fail when wget fails"
        exit 0
    fi

    install_dir=$(echo "$out" | sed -n 's/^__INSTALL_DIR__=//p' | tail -n 1)
    if [[ -z "$install_dir" ]]; then
        fail "could not determine temp INSTALL_DIR"
        exit 0
    fi

    if [[ ! -f "$install_dir/logs/model-download.log" ]]; then
        fail "model-download.log not created"
        exit 0
    fi

    if grep -q "unable to resolve host address" "$install_dir/logs/model-download.log"; then
        pass "model-download.log contains stderr output"
    else
        fail "model-download.log missing stderr output (stderr redirect regression)"
    fi
)

# Test 2: failure output should include "Last error:" line
(
    tmp_wget=$(mktemp)
    tmp_root=$(mktemp -d)
    # shellcheck disable=SC2064
    trap "rm -f '$tmp_wget'; rm -rf '$tmp_root'" RETURN

    export TMPDIR="$tmp_root"
    export TMP="$tmp_root"
    export TEMP="$tmp_root"

    make_mock_wget_fail "$tmp_wget" "ERROR: 404 Not Found"

    set +e
    out=$(run_phase11_download_block "$tmp_wget" 2>&1)
    status=$?
    set -e

    if [[ $status -eq 0 ]]; then
        fail "expected failure"
        exit 0
    fi

    if echo "$out" | grep -q "Last error: ERROR: 404 Not Found"; then
        pass "prints last error line"
    else
        fail "missing or incorrect 'Last error' output"
    fi
)

# Test 3: troubleshooting text should be actionable (not raw commands only)
(
    tmp_wget=$(mktemp)
    tmp_root=$(mktemp -d)
    # shellcheck disable=SC2064
    trap "rm -f '$tmp_wget'; rm -rf '$tmp_root'" RETURN

    export TMPDIR="$tmp_root"
    export TMP="$tmp_root"
    export TEMP="$tmp_root"

    make_mock_wget_fail "$tmp_wget" "Connection timed out"

    set +e
    out=$(run_phase11_download_block "$tmp_wget" 2>&1)
    status=$?
    set -e

    if [[ $status -eq 0 ]]; then
        fail "expected failure"
        exit 0
    fi

    if echo "$out" | grep -q "If this looks like a network/DNS issue" \
        && echo "$out" | grep -q "For the full download output"; then
        pass "prints actionable troubleshooting guidance"
    else
        fail "missing actionable troubleshooting guidance"
    fi
)

echo ""
echo "============================================"
PASS=$(grep -c '^PASS$' "$RESULTS_FILE" 2>/dev/null || true)
FAIL=$(grep -c '^FAIL$' "$RESULTS_FILE" 2>/dev/null || true)
PASS=${PASS:-0}
FAIL=${FAIL:-0}

echo -e "Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo "============================================"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi

exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

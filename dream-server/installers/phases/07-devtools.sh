#!/bin/bash
# ============================================================================
# Dream Server Installer — Phase 07: Developer Tools
# ============================================================================
# Part of: installers/phases/
# Purpose: Install Claude Code, Codex CLI, and OpenCode
#
# Expects: DRY_RUN, INSTALL_DIR, LOG_FILE, LLM_MODEL, MAX_CONTEXT,
#           PKG_MANAGER,
#           ai(), ai_ok(), ai_warn(), log()
# Provides: (developer tools installed to ~/.npm-global)
#
# Modder notes:
#   Add new developer tools or change installation methods here.
# ============================================================================

# Source validation library
source "$(dirname "${BASH_SOURCE[0]}")/../lib/validation.sh"

if $DRY_RUN; then
    log "[DRY RUN] Would install AI developer tools (Claude Code, Codex CLI, OpenCode)"
    log "[DRY RUN] Would configure OpenCode for local llama-server (user-level systemd service on port 3003)"
else
    ai "Installing AI developer tools..."

    # Ensure Node.js/npm is available (needed for Claude Code and Codex)
    if ! command -v npm &> /dev/null; then
        ai "Installing Node.js..."
        case "$PKG_MANAGER" in
            apt)
                tmpfile=$(mktemp /tmp/nodesource-setup.XXXXXX.sh)

                if ! curl -fsSL --max-time 300 https://deb.nodesource.com/setup_22.x -o "$tmpfile" 2>/dev/null; then
                    ai_warn "Failed to download NodeSource setup script"
                    rm -f "$tmpfile"
                elif ! validate_installer_script "$tmpfile" "node"; then
                    ai_warn "NodeSource script failed validation, skipping"
                    rm -f "$tmpfile"
                else
                    sudo -E bash "$tmpfile" >> "$LOG_FILE" 2>&1 || true
                    rm -f "$tmpfile"
                fi

                sudo apt-get install -y nodejs >> "$LOG_FILE" 2>&1 || true
                ;;
            dnf)
                sudo dnf module install -y nodejs:22 >> "$LOG_FILE" 2>&1 || \
                    sudo dnf install -y nodejs >> "$LOG_FILE" 2>&1 || true
                ;;
            pacman)
                sudo pacman -S --noconfirm --needed nodejs npm >> "$LOG_FILE" 2>&1 || true
                ;;
            zypper)
                sudo zypper --non-interactive install nodejs22 >> "$LOG_FILE" 2>&1 || \
                    sudo zypper --non-interactive install nodejs >> "$LOG_FILE" 2>&1 || true
                ;;
            *)
                ai_warn "Unknown package manager — cannot install Node.js automatically"
                ;;
        esac
    fi

    if command -v npm &> /dev/null; then
        ai_ok "Node.js available: $(node --version 2>/dev/null || echo 'version unknown')"

        # Set up user-level npm global directory (avoids sudo for npm installs)
        NPM_GLOBAL_DIR="$HOME/.npm-global"
        if [[ ! -d "$NPM_GLOBAL_DIR" ]]; then
            mkdir -p "$NPM_GLOBAL_DIR"
            npm config set prefix "$NPM_GLOBAL_DIR" 2>/dev/null || true
        fi
        # Ensure user-level bin is on PATH for this session
        export PATH="$NPM_GLOBAL_DIR/bin:$PATH"

        # Install Claude Code (Anthropic's CLI for Claude)
        if ! command -v claude &> /dev/null; then
            npm install -g @anthropic-ai/claude-code >> "$LOG_FILE" 2>&1 && \
                ai_ok "Claude Code installed (run 'claude' to start)" || \
                ai_warn "Claude Code install failed — install later with: npm i -g @anthropic-ai/claude-code"
        else
            ai_ok "Claude Code already installed"
        fi

        # Install Codex CLI (OpenAI's terminal agent)
        if ! command -v codex &> /dev/null; then
            npm install -g @openai/codex >> "$LOG_FILE" 2>&1 && \
                ai_ok "Codex CLI installed (run 'codex' to start)" || \
                ai_warn "Codex CLI install failed — install later with: npm i -g @openai/codex"
        else
            ai_ok "Codex CLI already installed"
        fi

        # Ensure ~/.npm-global/bin is on PATH permanently
        if [[ -d "$NPM_GLOBAL_DIR/bin" ]] && ! grep -q 'npm-global' "$HOME/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
            ai "Added ~/.npm-global/bin to PATH in ~/.bashrc"
        fi
    else
        ai_warn "Node.js not available — skipping Claude Code and Codex CLI"
    fi

    # ── OpenCode (local agentic coding platform) ──
    if ! command -v opencode &> /dev/null && [[ ! -x "$HOME/.opencode/bin/opencode" ]]; then
        ai "Installing OpenCode..."
        tmpfile=$(mktemp /tmp/opencode-install.XXXXXX.sh)

        if ! curl -fsSL --max-time 300 https://opencode.ai/install -o "$tmpfile" 2>/dev/null; then
            ai_warn "Failed to download OpenCode installer"
            rm -f "$tmpfile"
        elif ! validate_installer_script "$tmpfile" "opencode"; then
            ai_warn "OpenCode script failed validation, skipping"
            rm -f "$tmpfile"
        elif bash "$tmpfile" >> "$LOG_FILE" 2>&1; then
            ai_ok "OpenCode installed (~/.opencode/bin/opencode)"
            rm -f "$tmpfile"
        else
            ai_warn "OpenCode install failed — install later with: curl -fsSL https://opencode.ai/install | bash"
            rm -f "$tmpfile"
        fi
    else
        ai_ok "OpenCode already installed"
    fi

    # Configure OpenCode to use local llama-server
    if [[ -x "$HOME/.opencode/bin/opencode" ]]; then
        OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
        mkdir -p "$OPENCODE_CONFIG_DIR"
        if [[ ! -f "$OPENCODE_CONFIG_DIR/opencode.json" ]]; then
            # Read OLLAMA_PORT from the .env generated in phase 06
            # (it's not exported as a shell variable, only written to the file)
            if [[ -z "${OLLAMA_PORT:-}" && -f "$INSTALL_DIR/.env" ]]; then
                OLLAMA_PORT=$(grep -m1 '^OLLAMA_PORT=' "$INSTALL_DIR/.env" | cut -d= -f2-)
            fi
            cat > "$OPENCODE_CONFIG_DIR/opencode.json" <<OPENCODE_EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "llama-server/${LLM_MODEL}",
  "provider": {
    "llama-server": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "llama-server (local)",
      "options": {
        "baseURL": "http://127.0.0.1:${OLLAMA_PORT:-8080}/v1",
        "apiKey": "no-key"
      },
      "models": {
        "${LLM_MODEL}": {
          "name": "${LLM_MODEL}",
          "limit": {
            "context": ${MAX_CONTEXT:-131072},
            "output": 32768
          }
        }
      }
    }
  }
}
OPENCODE_EOF
            ai_ok "OpenCode configured for local llama-server (model: ${LLM_MODEL})"
        else
            ai_ok "OpenCode config already exists — skipping"
        fi

        # Install OpenCode Web UI as user-level systemd service (no sudo required)
        if [[ -f "$INSTALL_DIR/opencode/opencode-web.service" ]]; then
            SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
            mkdir -p "$SYSTEMD_USER_DIR"

            # Read OPENCODE_SERVER_PASSWORD from .env
            OPENCODE_SERVER_PASSWORD=""
            if [[ -f "$INSTALL_DIR/.env" ]]; then
                OPENCODE_SERVER_PASSWORD=$(grep -m1 '^OPENCODE_SERVER_PASSWORD=' "$INSTALL_DIR/.env" | cut -d= -f2-)
            fi

            # Substitute environment variables in the service file
            sed -e "s|{{INSTALL_DIR}}|$INSTALL_DIR|g" \
                -e "s|{{OPENCODE_SERVER_PASSWORD}}|$OPENCODE_SERVER_PASSWORD|g" \
                "$INSTALL_DIR/opencode/opencode-web.service" > "$SYSTEMD_USER_DIR/opencode-web.service"

            systemctl --user daemon-reload
            systemctl --user enable opencode-web.service
            systemctl --user start opencode-web.service

            ai_ok "OpenCode Web UI installed as systemd user service (port 3003)"
            ai "  Start: systemctl --user start opencode-web"
            ai "  Stop:  systemctl --user stop opencode-web"
            ai "  Logs:  journalctl --user -u opencode-web -f"
        fi
    fi
fi

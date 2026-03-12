#!/bin/bash
# ============================================================================
# Dream Server Installer — Phase 05: Docker Setup
# ============================================================================
# Part of: installers/phases/
# Purpose: Install Docker, Docker Compose, and NVIDIA Container Toolkit
#
# Expects: SKIP_DOCKER, DRY_RUN, INTERACTIVE, GPU_COUNT, GPU_BACKEND,
#           LOG_FILE, MIN_DRIVER_VERSION, PKG_MANAGER,
#           show_phase(), ai(), ai_ok(), ai_warn(), log(), warn(), error(),
#           detect_pkg_manager(), pkg_install(), pkg_update(), pkg_resolve()
# Provides: DOCKER_CMD, DOCKER_COMPOSE_CMD
#
# Modder notes:
#   Change Docker installation method or add Podman support here.
#   Multi-distro: uses packaging.sh for distro-agnostic package installs.
# ============================================================================

show_phase 3 6 "Docker Setup" "~2 minutes"
ai "Preparing container runtime..."

# Source validation library
source "$(dirname "${BASH_SOURCE[0]}")/../lib/validation.sh"

# Ensure package manager is detected
[[ -z "$PKG_MANAGER" ]] && detect_pkg_manager

if [[ "$SKIP_DOCKER" == "true" ]]; then
    log "Skipping Docker installation (--skip-docker)"
elif command -v docker &> /dev/null; then
    ai_ok "Docker already installed: $(docker --version)"
else
    ai "Installing Docker..."

    if $DRY_RUN; then
        log "[DRY RUN] Would install Docker via official script"
    else
        tmpfile=$(mktemp /tmp/install-docker.XXXXXX.sh)

        if ! curl -fsSL --max-time 300 https://get.docker.com -o "$tmpfile"; then
            rm -f "$tmpfile"
            error "Failed to download Docker installation script. Check network connectivity."
        fi

        if ! validate_installer_script "$tmpfile" "docker"; then
            rm -f "$tmpfile"
            error "Downloaded Docker script failed validation (may be corrupted or an error page)."
        fi

        if ! sh "$tmpfile"; then
            rm -f "$tmpfile"
            error "Docker installation failed. Check logs for details."
        fi

        rm -f "$tmpfile"
        sudo usermod -aG docker $USER

        # Check if we need to use newgrp or restart
        if ! groups | grep -q docker; then
            warn "Docker installed! Group membership requires re-login."
            warn "Option 1: Log out and back in, then re-run this script with --skip-docker"
            warn "Option 2: Run 'newgrp docker' in a new terminal, then re-run"
            echo ""
            read -p "  Try to continue with 'sudo docker' for now? [Y/n] " -r
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                # Use sudo for remaining docker commands in this session
                DOCKER_CMD="sudo docker"
                DOCKER_COMPOSE_CMD="sudo docker compose"
            else
                log "Please re-run after logging out and back in."
                exit 0
            fi
        fi
    fi
fi

# Set docker command (use sudo if needed)
DOCKER_CMD="${DOCKER_CMD:-docker}"
DOCKER_COMPOSE_CMD="${DOCKER_COMPOSE_CMD:-docker compose}"

# Docker Compose check (v2 preferred, v1 fallback)
if $DOCKER_COMPOSE_CMD version &> /dev/null 2>&1; then
    ai_ok "Docker Compose v2 available"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="${DOCKER_CMD%-*}-compose"
    [[ "$DOCKER_CMD" == "sudo docker" ]] && DOCKER_COMPOSE_CMD="sudo docker-compose"
    ai_ok "Docker Compose v1 available (using docker-compose)"
else
    if ! $DRY_RUN; then
        ai "Installing Docker Compose plugin..."
        pkg_update
        # shellcheck disable=SC2046
        pkg_install $(pkg_resolve docker-compose-plugin)
    fi
fi

# NVIDIA Container Toolkit (skip for AMD — uses /dev/dri + /dev/kfd passthrough)
if [[ $GPU_COUNT -gt 0 && "$GPU_BACKEND" == "nvidia" ]]; then
    if command -v nvidia-ctk &> /dev/null; then
        ai_ok "NVIDIA Container Toolkit already installed"
    else
        ai "Installing NVIDIA Container Toolkit..."
        if $DRY_RUN; then
            log "[DRY RUN] Would install nvidia-container-toolkit"
        else
            tmpfile=$(mktemp /tmp/install-nvidia-toolkit.XXXXXX.sh)

            if ! curl -fsSL --max-time 300 https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo -o /tmp/nvidia-container-toolkit.repo 2>/dev/null; then
                rm -f "$tmpfile"
                error "Failed to download NVIDIA Container Toolkit repo config."
            fi

            if [[ "$PKG_MANAGER" == "apt" ]]; then
                curl -fsSL --max-time 300 https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
                curl -fsSL --max-time 300 https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
                    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
                    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
                pkg_update
            elif [[ "$PKG_MANAGER" == "dnf" || "$PKG_MANAGER" == "yum" ]]; then
                sudo mv /tmp/nvidia-container-toolkit.repo /etc/yum.repos.d/
            fi

            pkg_install nvidia-container-toolkit
            rm -f "$tmpfile"
        fi
    fi
fi

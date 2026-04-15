# Dream Server Windows Quickstart

> **Status: Supported**
>
> Dream Server runs end-to-end on Windows through **Docker Desktop + WSL2**. The supported Windows path is `.\install.ps1`, which performs real install, launch, and verification work.
>
> **Note:** The supported Windows workflow is Docker Desktop + WSL2. A native Windows-only runtime path is not the current production target.

---

## Prerequisites

- **Windows 10 2004+ or Windows 11**
- **Docker Desktop** installed and running with the **WSL2 backend**
- **NVIDIA GPU** or **AMD Strix Halo** for local acceleration
- **16 GB+ RAM** recommended
- **30 GB+ free disk space** recommended for smaller tiers; larger local tiers may need 50-100 GB

---

## Install

Open **PowerShell** and run:

```powershell
git clone https://github.com/Light-Heart-Labs/DreamServer.git
cd DreamServer
.\install.ps1
```

The installer will:

1. **Check prerequisites** — PowerShell, Docker Desktop, WSL2, disk, and GPU visibility
2. **Detect your hardware** — NVIDIA, AMD Strix Halo, or cloud-only fallback
3. **Pick the right model tier** — based on VRAM or unified memory
4. **Generate config** — creates `.env`, secrets, and runtime files
5. **Start the stack** — launches Dream Server services and verifies health
6. **Install the Windows CLI** — so you can manage the stack with `dream.ps1`

**Estimated time:** 10-30 minutes depending on download speed and model size.

---

## Open the UI

- **Chat UI:** http://localhost:3000
- **Dashboard:** http://localhost:3001

The first user created in the Chat UI becomes the admin.

---

## Manage Your Stack

After install, Dream Server lives under:

```powershell
$env:USERPROFILE\dream-server
```

Common commands:

```powershell
cd $env:USERPROFILE\dream-server
.\dream.ps1 status
.\dream.ps1 logs llama-server
.\dream.ps1 restart open-webui
.\dream.ps1 update
```

---

## Useful Installer Flags

| Flag | What it does |
|------|--------------|
| `-DryRun` | Validate prerequisites and planned actions without installing |
| `-Tier 2` | Force a specific hardware tier |
| `-Cloud` | Skip local inference and use API mode |
| `-Voice` | Enable Whisper + Kokoro |
| `-Workflows` | Enable n8n automation |
| `-All` | Enable the full optional stack |
| `-Lan` | Expose the UI on your LAN instead of localhost-only |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Docker Desktop is not running" | Start Docker Desktop and wait for it to finish initializing |
| "WSL2 not detected" | Run `wsl --install`, reboot, then reopen Docker Desktop |
| "nvidia-smi fails in Docker" | Re-check Docker Desktop WSL2 backend and restart Docker Desktop |
| "Port already in use" | Edit `$env:USERPROFILE\dream-server\.env` and restart with `.\dream.ps1 restart` |
| Low memory or poor performance | Re-run with a lower tier, for example `.\install.ps1 -Tier 1` |

For a deeper walkthrough, see [WINDOWS-INSTALL-WALKTHROUGH.md](WINDOWS-INSTALL-WALKTHROUGH.md).

---

## Known Limitations

- The supported Windows path depends on **Docker Desktop + WSL2**
- Linux remains the primary development platform
- Platform feature parity is not identical everywhere; see [SUPPORT-MATRIX.md](SUPPORT-MATRIX.md) for current limitations and experimental paths

---

## Need Help?

- Full walkthrough: [WINDOWS-INSTALL-WALKTHROUGH.md](WINDOWS-INSTALL-WALKTHROUGH.md)
- GPU troubleshooting: [WSL2-GPU-TROUBLESHOOTING.md](WSL2-GPU-TROUBLESHOOTING.md)
- Docker tuning: [DOCKER-DESKTOP-OPTIMIZATION.md](DOCKER-DESKTOP-OPTIMIZATION.md)
- General FAQ: [FAQ.md](../FAQ.md)

---

*Last updated: 2026-04-15*

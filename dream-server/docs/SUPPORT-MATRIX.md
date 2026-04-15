# Dream Server Support Matrix

Last updated: 2026-04-15

## What Works Today

**Linux, Windows, and macOS are supported today. Intel Arc remains experimental.**

| Platform | Status | What you get today |
|----------|--------|-------------------|
| **Linux + AMD Strix Halo (ROCm)** | **Fully supported** | Complete install and runtime. Primary development platform. |
| **Linux + NVIDIA (CUDA)** | **Supported** | Complete install and runtime. Broader distro test matrix still expanding. |
| **Windows (Docker Desktop + WSL2)** | **Supported** | Complete install and runtime via `.\install.ps1`. GPU auto-detection (NVIDIA/AMD). |
| **macOS (Apple Silicon)** | **Supported** | Complete install and runtime via `./install.sh`. Native Metal inference + Docker services. |
| **Linux + Intel Arc (SYCL)** | **Experimental** | Installer auto-detects Arc, assigns ARC/ARC\_LITE tier, and selects `docker-compose.arc.yml`. End-to-end runtime on A770/A750. See [INTEL-ARC-GUIDE.md](INTEL-ARC-GUIDE.md). |

## Support Tiers

- `Tier A` — fully supported and actively tested in this repo
- `Tier B` — supported (works end-to-end, broader validation ongoing)
- `Tier C` — experimental or limited path with feature gaps or narrower validation

## Platform Matrix (detailed)

| Platform | GPU Path | Installer Tier | Notes |
|---|---|---|---|
| Linux (Ubuntu/Debian family) | NVIDIA (llama-server/CUDA) | Tier B | Installer path exists in `install-core.sh`; broader real-hardware validation is still ongoing |
| Linux (Strix Halo / AMD unified memory) | AMD (llama-server/ROCm) | Tier A | Primary path via `docker-compose.base.yml` + `docker-compose.amd.yml` |
| Linux (Intel Arc A770/A750) | Intel SYCL (llama-server/oneAPI) | **Tier C** | `docker-compose.arc.yml`; builds llama.cpp from `intel/oneapi-basekit`; see [INTEL-ARC-GUIDE.md](INTEL-ARC-GUIDE.md) |
| Windows (Docker Desktop + WSL2) | NVIDIA/AMD via Docker Desktop | Tier B | Standalone installer (`.\install.ps1`) with GPU auto-detection, Docker orchestration, health checks, and desktop shortcuts |
| macOS (Apple Silicon) | Metal (native llama-server) | Tier B | Standalone installer (`./install.sh`) with chip detection, native Metal inference, Docker services, and LaunchAgent auto-start |

## GPU Tier Map

| Installer Tier | Hardware | Model | VRAM | Backend |
|---|---|---|---|---|
| `NV_ULTRA` | NVIDIA 90 GB+ | Qwen3-Coder-Next | ≥ 90 GB | CUDA |
| `SH_LARGE` | AMD Strix Halo 90+ | Qwen3-Coder-Next | ≥ 90 GB (unified) | ROCm |
| `SH_COMPACT` | AMD Strix Halo < 90 GB | Qwen3 30B A3B | < 90 GB (unified) | ROCm |
| `4` | NVIDIA 40 GB+ / multi-GPU | Qwen3 30B A3B | ≥ 40 GB | CUDA |
| `3` | NVIDIA 20 GB+ | Qwen3 30B-A3B | ≥ 20 GB | CUDA |
| `ARC` | **Intel Arc ≥ 12 GB** (A770, B580) | Qwen3.5 9B | ≥ 12 GB | **SYCL** |
| `2` | NVIDIA 12 GB+ | Qwen3.5 9B | ≥ 12 GB | CUDA |
| `ARC_LITE` | **Intel Arc < 12 GB** (A750, A380) | Qwen3.5 4B | 6–11 GB | **SYCL** |
| `1` | NVIDIA 4 GB+ | Qwen3.5 9B | ≥ 4 GB | CUDA |
| `0` | CPU / < 4 GB GPU | Qwen3.5 2B | any | CPU |
| `CLOUD` | No local GPU | Claude (API) | — | LiteLLM |

## Current Truth

- **Linux, Windows, and macOS are supported today.**
- Linux + NVIDIA is supported but still needs broader real-hardware validation.
- Windows installs via `.\install.ps1` with Docker Desktop + WSL2 backend. This is the supported Windows path today.
- Windows native-only runtime without Docker Desktop + WSL2 is not the current production path.
- macOS installs via `./install.sh` — llama-server runs natively with Metal acceleration, all other services in Docker.
- **Intel Arc (SYCL) is Tier C / experimental.** The installer auto-detects and selects the correct compose overlay and tier. Runtime works on A770/A750 (Linux). ComfyUI and Whisper GPU acceleration are not yet available for Arc. See [INTEL-ARC-GUIDE.md](INTEL-ARC-GUIDE.md) for limitations.
- Version baselines for triage are in `docs/KNOWN-GOOD-VERSIONS.md`.

## Roadmap

| Target | Milestone |
|--------|-----------|
| **Now** | Linux AMD + NVIDIA + Windows + macOS supported |
| **Now** | Intel Arc (SYCL) experimental — installer + runtime on A770/A750 |
| **Ongoing** | Broaden real-hardware validation and release checks across supported platforms |
| **Planned** | Promote Intel Arc to Tier B after broader A770/B580 validation |
| **Planned** | Arc-accelerated Whisper STT overlay |

## Next Milestones

1. Expand release checks and real-hardware validation for Linux NVIDIA, Windows, and macOS.
2. Expand macOS test coverage across M1/M2/M3/M4 variants and RAM tiers.
3. Promote macOS from Tier B to Tier A after broader real-hardware validation.
4. Validate Intel Arc B580 (Battlemage 12 GB) on the `ARC` tier.
5. Promote Intel Arc from Tier C to Tier B after A770 + B580 real-hardware validation.

## See also

- [LINUX-PORTABILITY.md](LINUX-PORTABILITY.md) — Linux installer edge cases, `.env` validation, extension manifests.

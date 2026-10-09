# VOLTARENA — BUILD, PACKAGING & RELEASE ENGINEERING GUIDE
## Monorepo Modular Architecture, Universal CI/CD Matrix & Multiplatform Packaging (v8.0.0)

---

## 1. Monorepo Build Architecture & Shared-Core Pipeline

VoltArena employs a **shared-core, modular entry point architecture** allowing every game to be compiled and distributed both as an isolated standalone release and as part of the master multi-game launcher suite.

```text
                             VOLTARENA MONOREPO
                                      |
       +------------------------------+------------------------------+
       |                                                             |
SHARED GAME CORE                                              STANDALONE GAMES
(res://shared/)                                               (res://games/<game_id>/)
- InputManager / TouchControls                                - Standalone Entry Scene
- PhysicsHelpers / Raycasts                                   - Isolated Save Namespace
- QualityManager / Presets                                    - Dedicated Audio & Assets
- AudioManager / Procedural Synth                             - Zero Foreign Leakage
- SaveManager / Namespaces                                    - Independent Versioning
                                      |
                                      v
                          MODULAR PACKAGING ENGINE
                       (scripts/modular_packager.py)
                                      |
       +------------------------------+------------------------------+
       |                                                             |
VOLTARENA FULL SUITE                                          STANDALONE DISTRIBUTIONS
export/dist/suite/                                            export/dist/standalone/
- VoltArena-Full-Windows-x86_64.zip                           - AeroRush-Windows-x86_64.zip
- VoltArena-Full-Linux-x86_64.tar.gz                          - AeroRush-Linux-x86_64.tar.gz
- VoltArena-Full-Web.zip                                      - AeroRush-Web.zip
- VoltArena-Full-Android.apk                                  - ChromaRush-Windows-x86_64.zip
                                                              - ... (30 Packages Across 10 Games)
```

---

## 2. Standard One-Command Reproducibility Scripts (Section 11)

All build, test, and verification operations are containerized and fully automated without requiring local Godot installations. Scripts are provided with cross-platform equivalents:

| Command | Bash Wrapper | PowerShell Wrapper | Action Description |
| :--- | :--- | :--- | :--- |
| `scripts/setup` | `scripts/setup.sh` | `scripts/setup.ps1` | Pulls container images (`godot-ci:4.3`, `python:3.12-alpine`) and initializes Godot cache. |
| `scripts/build-all` | `scripts/build-all.sh` | `scripts/build-all.ps1` | Compiles Web, Linux, Windows, Android, and packages all 30 standalone games + full suite. |
| `scripts/build-suite` | `scripts/build-suite.sh` | `scripts/build-suite.ps1` | Compiles and packages the master VoltArena suite launcher for all supported platforms. |
| `scripts/build-game <game> [platform]` | `scripts/build-game.sh` | `scripts/build-game.ps1` | Packages a single standalone title (e.g. `aero-rush`, `chroma-rush`) with isolated dependencies. |
| `scripts/test-all` | `scripts/test-all.sh` | `scripts/test-all.ps1` | Executes all 80 automated unit, integration, and E2E test suites inside the Godot container. |
| `scripts/smoke-test` | `scripts/smoke-test.sh` | `scripts/smoke-test.ps1` | Headless boot and clean exit verification across all 11 main scenes + acceptance gates. |
| `scripts/verify-artifacts` | `scripts/verify-artifacts.sh` | `scripts/verify-artifacts.ps1` | Audits test passes, coverage ($\ge 90\%$), non-zero package sizes, and reports integrity. |
| `scripts/clean` | `scripts/clean.sh` | `scripts/clean.ps1` | Idempotently deletes build artifacts, temporary logs, and exports. |
| `scripts/teardown` | `scripts/teardown.sh` | `scripts/teardown.ps1` | Stops all preview web servers and prunes temporary container runtimes. |

---

## 3. GitHub Actions CI/CD Matrix (`.github/workflows/ci.yml`)

The production workflow executes across 16 sequential and parallel pipeline stages:

1. **Lint & Static Analysis**: `gdlint` and `gdformat` verification.
2. **Unit & E2E Tests**: Executes `tests/runner.gd` (80 test suites, 3,045+ assertions).
3. **Coverage Analysis**: Enforces the $\ge 90\%$ repository-wide function coverage threshold.
4. **Performance Benchmarks**: Generates frame pacing, allocation, and benchmark metrics.
5. **Web Export**: Godot Web export with automated $\le 18\text{MB}$ chunking and COOP/COEP headers.
6. **Linux Export**: Native Linux x86_64 binary compilation with embedded PCK.
7. **Windows Export**: Native Windows 64-bit PE executable compilation with embedded PCK.
8. **macOS Export**: macOS export preset bundling (notarization gate).
9. **Android Export**: Export release APK/AAB with debug keystore signing.
10. **Android Emulator E2E**: Headless emulator boot and installation test.
11. **Browser E2E**: Playwright Chromium/Firefox execution against the exported web bundle.
12. **Security & SBOM**: CycloneDX 1.5 SBOM generation and TruffleHog secret scanning.
13. **Deploy to Cloudflare**: Direct deployment to Cloudflare Pages with chunk verification.
14. **Post-Deploy E2E**: Smoke testing deployed public URL.
15. **Production Certification**: `scripts/certifier.py` empirical visual and UX audit, generating `reports/`.
16. **Modular Release Packaging**: Bundles and uploads the complete 34-package matrix.

---

## 4. Standalone Deliverables & Checksums

All package sizes and SHA-256 hashes are tracked in [reports/artifact-manifest.json](file:///h:/gamesmodern/reports/artifact-manifest.json) and [reports/platform-matrix.json](file:///h:/gamesmodern/reports/platform-matrix.json):

```text
export/dist/
├── standalone/
│   ├── AeroRush-Linux-x86_64.tar.gz        (183.6 MB, SHA256: 6fa735073489...)
│   ├── AeroRush-Web.zip                    (245.3 MB, SHA256: 015f62df327d...)
│   ├── AeroRush-Windows-x86_64.zip         (189.7 MB, SHA256: d8d9297ea948...)
│   ├── ChromaRush-Linux-x86_64.tar.gz      (183.7 MB, SHA256: 62451bebb2b8...)
│   ├── ChromaRush-Web.zip                  (245.4 MB, SHA256: ccb1aa888949...)
│   ├── ChromaRush-Windows-x86_64.zip       (189.9 MB, SHA256: 42ad26b282ca...)
│   └── ... (24 additional packages for remaining 8 titles)
└── suite/
    ├── VoltArena-Full-Android.apk          (114.0 MB, SHA256: 7fbc265e3789...)
    ├── VoltArena-Full-Linux-x86_64.tar.gz  (104.4 MB, SHA256: 82d8c3fb9f97...)
    ├── VoltArena-Full-Web.zip              (166.1 MB, SHA256: e8d4ff0258cb...)
    └── VoltArena-Full-Windows-x86_64.zip   (110.5 MB, SHA256: c3a42ebad9b2...)
```

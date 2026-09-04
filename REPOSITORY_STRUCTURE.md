# VoltArena — Repository Structure & File Index

## 1. Overview
This document catalogs every directory and critical file in the VoltArena repository, detailing its functional domain, dependencies, and architectural role.

---

## 2. Directory Tree & Inventory

```
h:/gamesmodern/
│
├── .godot/                             # Godot 4 editor and import cache
│   ├── editor/
│   ├── exported/
│   └── global_script_class_cache.cfg   # Class registry for GDScript class_names
│
├── artifacts/                          # CI/CD and Production Certification artifacts
│   ├── production-certification.html   # Human-readable visual certification report
│   ├── production-certification.json   # Machine-readable production audit report
│   └── test-results.json               # Automated test runner summary metrics
│
├── export/                             # Compilation targets
│   ├── dist/                           # Release archives (.zip, .tar.gz, .apk)
│   ├── linux/                          # Linux x86_64 standalone binary
│   ├── web/                            # Cloudflare-optimized Web WASM build
│   │   ├── _headers                    # Cloudflare Pages cache & isolation headers
│   │   ├── index.html                  # Web player shell with chunk reassembler
│   │   ├── index.js                    # Godot Emscripten bridge
│   │   ├── index.pck                   # Packaged game data
│   │   ├── index.wasm                  # Source WebAssembly binary (for local dev)
│   │   ├── index.wasm.part00           # WASM Chunk 1 (18.0 MB <= 25MB)
│   │   └── index.wasm.part01           # WASM Chunk 2 (15.7 MB <= 25MB)
│   └── windows/                        # Windows x86_64 standalone executable
│
├── games/                              # Playable Game Implementations
│   ├── arena-fps/                      # Game 1: Iron Crucible
│   │   ├── ai/
│   │   │   └── arena_bot.gd            # Combat bot state machine & navigation
│   │   ├── maps/
│   │   │   └── arena_map_generator.gd  # Procedural multi-level arena builder
│   │   ├── pickups/
│   │   │   └── pickup_base.gd          # Health/Armor/Ammo interactive pickups
│   │   ├── player/
│   │   │   └── fps_player.gd           # First-person player controller & inventory
│   │   ├── weapons/
│   │   │   ├── grenade_launcher.gd     # Parabolic explosive projectile launcher
│   │   │   ├── plasma_cutter.gd        # Continuous beam weapon with overheat
│   │   │   ├── projectile.gd           # Ballistic projectile entity with blast AoE
│   │   │   ├── rail_driver.gd          # Piercing instantaneous beam weapon
│   │   │   ├── scatter_cannon.gd       # 8-pellet buckshot spread weapon
│   │   │   └── weapon_base.gd          # Base weapon framework & recoil kick
│   │   ├── arena_fps_main.gd           # Match orchestrator & round rules
│   │   └── arena_fps_main.tscn         # Main scene tree for Iron Crucible
│   │
│   ├── kart-racing/                    # Game 4: Drift Storm
│   │   ├── ai/
│   │   │   └── kart_ai.gd              # Racing line pathfinding & drift logic
│   │   ├── game/
│   │   │   └── race_manager.gd         # Lap times, checkpoint validation, anti-cheat
│   │   ├── kart/
│   │   │   └── kart_controller.gd      # Kart vehicle physics & 3-tier drift boost
│   │   ├── powerups/
│   │   │   └── powerup_item.gd         # Track item box dispenser & powerups
│   │   ├── tracks/
│   │   │   ├── checkpoint.gd           # Sequential checkpoint gate sensor
│   │   │   └── track_generator.gd      # Procedural banked closed-loop circuit builder
│   │   ├── kart_racing_main.gd         # Race setup, participant spawning, standings
│   │   └── kart_racing_main.tscn       # Main scene tree for Drift Storm
│   │
│   ├── rocket-car/                     # Game 3: Nitro Kick
│   │   ├── ai/
│   │   │   └── car_ai.gd               # Car AI ball-tracking & defensive intercept
│   │   ├── arena/
│   │   │   └── rocket_arena.gd         # Stadium arena with curved ramps & goal nets
│   │   ├── ball/
│   │   │   └── ball.gd                 # Bouncy soccer ball with impulse response
│   │   ├── vehicle/
│   │   │   └── car_controller.gd       # 3D car controller, double-jump, nitrous boost
│   │   ├── rocket_car_main.gd          # Match director, goal detection, kickoff pause
│   │   └── rocket_car_main.tscn        # Main scene tree for Nitro Kick
│   │
│   └── subway-survival/                # Game 2: Metro Siege
│       ├── enemies/
│       │   ├── brute.gd                # Heavy armored juggernaut enemy
│       │   ├── crawler.gd              # Fast melee swarmer enemy
│       │   ├── enemy_base.gd           # Base enemy navigation & attack timings
│       │   └── stalker.gd              # Flanking stealth predator enemy
│       ├── game/
│       │   └── wave_director.gd        # Escalating wave logic & scavenge phases
│       ├── maps/
│       │   └── subway_generator.gd     # Procedural subway platform & tunnel builder
│       ├── subway_main.gd              # Survival match manager & player spawning
│       └── subway_main.tscn            # Main scene tree for Metro Siege
│
├── launcher/                           # Master Platform Hub
│   ├── launcher.gd                     # Cyberpunk UI, carousel, settings dialog
│   └── launcher.tscn                   # Root startup scene
│
├── platform/                           # Platform & Deployment Assets
│   └── web/
│       ├── _headers                    # Cloudflare Pages HTTP header definitions
│       └── nginx.conf                  # Nginx local container configuration
│
├── scripts/                            # Podman Automation Scripts (.sh & .ps1)
│   ├── acceptance.ps1 / .sh            # Runs platform gameplay acceptance tests
│   ├── benchmark.ps1 / .sh             # Runs performance benchmarks
│   ├── bring-down.ps1 / .sh            # Stops and removes preview containers
│   ├── bring-up.ps1 / .sh              # Starts local preview web container
│   ├── build.ps1 / .sh                 # Compiles Web, Linux, and Windows targets
│   ├── build-android.ps1 / .sh         # Packages Android release artifacts
│   ├── build-desktop.ps1 / .sh         # Exports Linux and Windows desktop binaries
│   ├── build-web.ps1 / .sh             # Exports Web, chunks WASM, verifies limits
│   ├── certifier.py                    # Generates production certification artifacts
│   ├── clean.ps1 / .sh                 # Cleans export and log directories
│   ├── coverage.ps1 / .sh              # Audits code coverage against >90% gate
│   ├── deploy-cloudflare.ps1 / .sh     # Prepares & deploys to Cloudflare Pages
│   ├── package.ps1 / .sh               # Packages release zips/tarballs in export/dist/
│   ├── packager.py                     # Python release packaging utility
│   ├── run-web.ps1 / .sh               # Runs interactive web server preview
│   ├── setup.ps1 / .sh                 # Pulls container images and initializes cache
│   ├── test.ps1 / .sh                  # Runs complete automated test runner
│   └── validate-production.ps1 / .sh   # End-to-end 6-gate production certification
│
├── shared/                             # Core Shared Libraries & Singletons
│   ├── ai/
│   │   └── ai_base.gd                  # Base navigation & line-of-sight raycasting
│   ├── audio/
│   │   └── audio_manager.gd            # Pure procedural PCM audio synthesizer
│   ├── combat/
│   │   └── health_component.gd         # Reusable health, armor, and damage component
│   ├── core/
│   │   ├── event_bus.gd                # Global signal pub-sub message hub
│   │   ├── game_constants.gd           # Physics layers, tags, and game enumerations
│   │   └── game_manager.gd             # Platform lifecycle and scene transitions
│   ├── graphics/
│   │   ├── material_generator.gd       # Procedural PBR material and neon factory
│   │   └── quality_manager.gd          # Dynamic graphics quality preset controller
│   ├── input/
│   │   ├── input_manager.gd            # Unified multi-device input aggregator
│   │   ├── touch_controls.gd           # On-screen virtual buttons for mobile/web
│   │   └── virtual_joystick.gd         # Analogue on-screen touch joystick
│   ├── loading/
│   │   └── asset_loader.gd             # Background loading & transition coordinator
│   ├── physics/
│   │   └── physics_helpers.gd          # Raycasting & collision utility functions
│   ├── platform/
│   │   └── platform_adapter.gd         # Web/Desktop/Mobile runtime detector
│   ├── save/
│   │   └── save_manager.gd             # Career stats & persistent profile storage
│   ├── settings/
│   │   └── settings_manager.gd         # Graphics, audio, and input settings storage
│   ├── telemetry/
│   │   └── telemetry_manager.gd        # Runtime metrics and performance tracking
│   └── ui/
│       ├── hud_base.gd                 # Standardized in-game HUD with health/ammo
│       ├── pause_menu.gd               # Universal pause overlay with options
│       ├── results_screen.gd           # Post-match victory/defeat summary screen
│       └── theme_generator.gd          # Procedural cyberpunk UI stylebox factory
│
├── tests/                              # Automated Test Infrastructure
│   ├── acceptance/
│   │   └── test_platform_acceptance.gd # End-to-end gameplay acceptance test suite
│   ├── benchmark/
│   │   └── test_benchmark.gd           # Performance & procedural generation benchmark
│   ├── unit/
│   │   ├── test_car_physics.gd         # Nitro Kick physics assertions
│   │   ├── test_health_component.gd    # Combat & damage calculations assertions
│   │   ├── test_race_manager.gd        # Drift Storm checkpoint & lap assertions
│   │   ├── test_save_manager.gd        # Career persistence assertions
│   │   ├── test_wave_director.gd       # Metro Siege wave progression assertions
│   │   └── test_weapons.gd             # Iron Crucible 5-weapon arsenal assertions
│   └── runner.gd                       # Headless test runner executing all suites
│
├── export_presets.cfg                  # Web, Linux, Windows, and Android export config
├── project.godot                       # Root Godot 4.3 project configuration
├── icon.svg                            # Platform application icon
├── CHANGELOG.md                        # Append-only project change log
└── TODO.md                             # Append-only technical roadmap
```

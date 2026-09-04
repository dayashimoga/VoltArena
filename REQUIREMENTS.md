# VoltArena — Platform Requirements Specification

## 1. Executive Summary
This document specifies the technical, functional, architectural, performance, and deployment requirements for the **VoltArena** 3D Game Suite. VoltArena delivers a unified cross-platform game environment comprising four distinct, completely original 3D titles:
1. **Iron Crucible** (Tactical Arena FPS)
2. **Metro Siege** (Subway Wave Survival FPS)
3. **Nitro Kick** (Rocket-Car Arena Football)
4. **Drift Storm** (Arcade Kart Racing)

---

## 2. General Technical Constraints & Rules
* **FR-01: Zero Host Installation**: The host machine must not require any software, compiler, runtime, or game engine installations. All development, compilation, testing, and packaging commands must run through **Podman** container technology.
* **FR-02: Zero External Assets**: The codebase must contain no third-party 3D models, textures, audio samples, or proprietary fonts. All visuals, geometry, PBR materials, UI palettes, and audio waveforms must be generated 100% procedurally at runtime.
* **FR-03: Original Intellectual Property**: The games must avoid copying proprietary names, characters, maps, audio, branding, or code from existing commercial titles.
* **FR-04: Cross-Platform Target**: Must compile to and execute reliably on Web (WASM / WebGL2), Linux (x86_64), Windows (x86_64), and Android (ARM64).
* **FR-05: Single Unified Project**: All four games must reside within a single Godot 4.3 project sharing unified input, graphics, audio, UI themes, and save architectures.

---

## 3. Game-Specific Functional Requirements

### 3.1 Game 1: Iron Crucible (Tactical Arena FPS)
* **FR-FPS-01 (Movement)**: Standard FPS locomotion with 8-direction walking (7.0 m/s), sprinting (11.5 m/s), crouch navigation (3.5 m/s), jumping with air velocity control, and smooth camera bobbing.
* **FR-FPS-02 (Weapons)**: 5 distinct weapons with independent fire rates, spread cones, reload cycles, recoil kickback, clip sizes, reserve ammo, and projectile/hitscan logic:
  * Pulse Rifle (Automatic Hitscan, 12.0 dmg)
  * Scatter Cannon (Pellet Hitscan Spread, 8x11.0 dmg)
  * Rail Driver (Instant Piercing Hitscan, 85.0 dmg, 2.0x Headshot multiplier)
  * Grenade Launcher (Physics ballistic projectile, 95.0 dmg, 5.0m blast radius)
  * Plasma Cutter (Continuous beam, thermal overheat mechanic)
* **FR-FPS-03 (Bot AI)**: Autonomous combat bots featuring patrol paths, line-of-sight raycasts, strafe evasion, target acquisition, weapon firing, and respawn sequencing.
* **FR-FPS-04 (Environment & Pickups)**: Procedural multi-level industrial arena with catwalks, jump pads, pillars, dynamic health (+25 HP), armor (+25 Armor), and ammo replenishing pickups.
* **FR-FPS-05 (Scoring & Rules)**: 5-minute match timer, kill-based scoring (+100 per kill), instant HUD updates, kill feeds, and victory/defeat results screens.

### 3.2 Game 2: Metro Siege (Subway Survival FPS)
* **FR-SURV-01 (Subway Environment)**: Procedural subterranean subway terminus with multi-track tunnels, passenger platforms, concrete pillars, and atmospheric lighting.
* **FR-SURV-02 (Enemy Archetypes)**:
  * **Crawler**: Rapid melee swarmer (120 HP, 8.0 m/s speed, leap attack).
  * **Stalker**: Flanking predator (180 HP, 6.5 m/s speed, stealth evasion).
  * **Brute**: Armored tank (450 HP, 3.8 m/s speed, heavy ground slam).
* **FR-SURV-03 (Wave Director)**: Wave orchestration managing escalating enemy counts, inter-wave tactical scavenging intermissions (10-second countdown), and supply drops.
* **FR-SURV-04 (Survival Progression)**: Currency/points economy earned from mutant kills, ammo conservation, and survival stat tracking.

### 3.3 Game 3: Nitro Kick (Rocket-Car Football)
* **FR-CAR-01 (Vehicle Dynamics)**: Responsive vehicular steering, throttle acceleration, reversing, emergency braking, double-jump vertical thrusters, and pitch/roll air orientation.
* **FR-CAR-02 (Nitrous Boost)**: Boost mechanic with speed multiplier up to 38.0 m/s, glowing exhaust particles, boost meter depletion, and auto-recharge / pad refills.
* **FR-CAR-03 (Ball Physics)**: Custom physics-driven bouncy ball with air drag, restitution bouncing, spin deflection, and dynamic car-ball impulse transfer.
* **FR-CAR-04 (Arena & Goals)**: Symmetrical arena with curved corner ramps, goal sensor detection planes, scoreboards, and kickoff reset sequences with brief countdown holds.
* **FR-CAR-05 (AI Teammates & Opponents)**: Car bot navigation with ball interception vectors, defensive goalie positioning, and attack driving lines.

### 3.4 Game 4: Drift Storm (Arcade Kart Racing)
* **FR-KART-01 (Driving & Drift)**: Tight arcade steering, drift engagement with steer-locking, 3-tier drift charging with chromatic sparks, and post-drift nitrous acceleration boosts.
* **FR-KART-02 (Circuit Track)**: Procedural closed-loop circuit generation with banked turns, racing curbs, track barriers, start/finish arches, and waypoint spline curves.
* **FR-KART-03 (Checkpoints & Anti-Cheat)**: Sequential checkpoint gate detection preventing track cutting, wrong-way driving warnings, and exact lap time tracking.
* **FR-KART-04 (Powerup System)**: Track item crates providing 4 collectible powerups (Turbo Speed, Plasma Shield, Seeker Missile, EMP Mine).
* **FR-KART-05 (AI Racers)**: Multi-kart competitive AI following optimal racing lines, pathfinding around obstacles, and triggering powerups.

---

## 4. Non-Functional Requirements

### 4.1 Performance & Resource Budgets
* **NFR-PERF-01 (Frame Rate)**: Stable 60 FPS on desktop targets (1080p) and mobile/web targets (720p).
* **NFR-PERF-02 (Procedural Generation)**: Map and circuit generation times must execute under 100 milliseconds.
* **NFR-PERF-03 (Memory Footprint)**: Total runtime heap footprint must remain under 500 MB RAM across all scenes.
* **NFR-PERF-04 (Draw Calls)**: Static draw calls kept below 250 via procedural mesh combining and shared material instancing.

### 4.2 Web & Cloudflare Compatibility
* **NFR-WEB-01 (File Size Ceiling)**: Strict compliance with Cloudflare Pages free tier limit: **no single uploaded file may exceed 25.0 MB**.
* **NFR-WEB-02 (WASM Chunking)**: WebAssembly binaries exceeding 25MB must be automatically split into parts $\le 18$MB and reassembled on-the-fly via client-side stream hooks.
* **NFR-WEB-03 (Single-Threaded GL Compatibility)**: Web build must run on Godot's single-threaded WebGL2/Compatibility renderer to eliminate strict SharedArrayBuffer requirements.
* **NFR-WEB-04 (Response Headers)**: Must supply `_headers` configuring cache-control immutable policies for WASM/PCK assets and security isolation.

### 4.3 Testing & Quality Assurance
* **NFR-QA-01 (Test Pass Rate)**: Automated test runner must achieve 100% assertions passing.
* **NFR-QA-02 (Code Coverage)**: Test coverage across core game systems must exceed 90.0%.
* **NFR-QA-03 (Headless Stability)**: All game scenes must boot headlessly for 30+ frames without crashing (exit code 0).

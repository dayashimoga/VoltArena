# VoltArena — 3D Cross-Platform Game Suite

![VoltArena Production Status](https://img.shields.io/badge/Production-Certified_Ready-00f0ff?style=for-the-badge)
![Godot Engine](https://img.shields.io/badge/Engine-Godot_4.3_Stable-478cbf?style=for-the-badge&logo=godotengine&logoColor=white)
![Podman Containers](https://img.shields.io/badge/Container-Podman_Zero_Host_Installs-892ca0?style=for-the-badge&logo=podman&logoColor=white)
![Test Coverage](https://img.shields.io/badge/Test_Coverage-96.9%25-10b981?style=for-the-badge)
![Cloudflare Pages](https://img.shields.io/badge/Web_Deploy-Cloudflare_Pages_%E2%89%A425MB-f38020?style=for-the-badge&logo=cloudflare&logoColor=white)

**VoltArena** is an original, production-grade, high-performance, cross-platform 3D game suite engineered in **Godot 4.3 Stable** using a modular single-binary architecture. The platform features seven completely original, fully playable 3D games unified under an interactive 3D launcher with instant hot-swapping, persistent cross-game progression, zero external binary audio dependencies (100% procedural waveform audio synthesis), 49 production-quality offline GLB 3D models with SHA-256 manifest tracking, 18 procedural PBR materials, and zero host package installations powered by **Podman** containers.

---

## 🎮 The Seven Original Games

### 1. Iron Crucible — Tactical Arena FPS
* **Genre**: Fast-paced arena first-person shooter.
* **Weapons**: 5 distinct armaments: Pulse Rifle (hitscan), Scatter Cannon (pellet spread), Rail Driver (piercing beam, 2x headshot), Grenade Launcher (parabolic ballistic explosive), Plasma Cutter (continuous heat beam).
* **AI & Combat**: Autonomous bots with line-of-sight raycasting, strafe evasion, item scavenging, safe-transform tracking, and kill-plane recovery ($Y < -6.0\text{m}$).
* **Modes & Arenas**: 5 match modes (Deathmatch, Team Deathmatch, Domination, Instagib, Juggernaut) across 3 distinct arenas (Citadel, Foundry, Sektor) with sealed perimeter boundaries and jump pads.

### 2. Metro Siege — Subway Wave Survival FPS
* **Genre**: Subterranean horde survival horror.
* **Mutant Adversaries**: 5 distinct mutant archetypes: Fast Melee Crawler, Stealth Stalker, Armored Brute, Acid Spitter, and the apex Wave 10 BioColossus boss (1,200 HP).
* **Wave Director**: 10-wave horde escalation with tactical intermissions, supply drops, and scrap economy.
* **World & Extraction**: Subway terminal with authentic 24m passenger train carriages, ticket kiosk weapon upgrades, and train evacuation victory.

### 3. Nitro Kick — Rocket-Car Arena Football
* **Genre**: Physics-driven rocket vehicular football.
* **Vehicle Dynamics**: Dual-axis steering with ground drift ($1.75\times$ multiplier on handbrake), double jump vertical thrusters, and 3D aerial pitch/yaw/roll orientation with local transforms.
* **Ball Physics**: Continuous collision detection (CCD), contact monitoring, and 3.0m thick stadium perimeter colliders.
* **Match Modes**: Symmetrical floodlit stadium supporting 1v1, 2v2, and 3v3 team formations with sudden-death overtime.

### 4. Drift Storm — Arcade Kart Racing
* **Genre**: High-velocity arcade circuit kart racing.
* **Driving Model**: Tight responsive steering, vertical sphere collision ($r=0.5$), road concave mesh backface collision, and 3-tier drift charging with chromatic sparks.
* **Circuits & AI**: 3 distinct circuits (Alpine Ridge, Desert Mirage, Neon Speedway) with banked turns and ripple kerbs, featuring 5 AI racers on an expanded 6-slot staggered starting grid with an authentic 5-light gantry sequence.
* **Powerups**: Track item crates dispensing 4 powerups (Turbo Speed, Plasma Shield, Seeker Missile, EMP Mine).

### 5. Skybound Odyssey — Open-Air 3D Platformer
* **Genre**: Aerodynamic exploration & precision 3D platforming.
* **Traversal Mechanics**: Variable jumping, double jumping, raycast ledge mantling, glider flight with polar curve aerodynamics and thermal updrafts, and grappling hook cable launches.
* **World**: 5 interconnected floating regions (Emerald Isles, Crystal Caverns, Sunken Sky Temple, Frost Peaks, Storm Citadel).
* **Puzzles & Quests**: Pressure plates, laser switches, locked ceremonial doors, multi-stage questlines, and 25 collectible sky shards.

### 6. RoboForge Arena — Modular Physics Construction Sandbox
* **Genre**: Modular robotic engineering & physics obstacle trials.
* **3D Workshop Turntable**: Interactive 360° assembly bay with visual mounting points and dynamic robot re-meshing.
* **Module Suite**: 3 chassis types (Scout, Enforcer, Titan), 3 drive systems (Wheels, Tracks, Quadruped Legs), 3 power cores (Battery, Fission, Fusion), 5 functional tools (Grabber, Magnet, Boosters, Shield, Cargo Bed).
* **Physics & Challenges**: Dynamic mass/speed/torque recalculation across 7 physical obstacle courses (Slalom, Heavy Haul, Rock Crawl, Jump Crater, Magnet Sort, High-Speed Loop, Boss Gauntlet).

### 7. WildCircuit — Wildlife Safari & Photography Traversal
* **Genre**: Open-world wildlife photography & vehicle traversal.
* **Biomes & Ecosystems**: 5 expansive ecosystems (Savanna, Rainforest, Alpine, Coastal, Wetlands) with procedural terrain and vegetation.
* **Wildlife Simulation**: 9 animal species (Gazelle, Lion, Jaguar, Macaw, Snow Leopard, Ibex, Sea Turtle, Crocodile, Flamingo) powered by 8-state behavioral finite state machines.
* **Photography Engine**: Optical viewfinder with 24mm–300mm zoom, depth-of-field bokeh, framing grid, deterministic scoring engine (1 to 5 stars), field journal encyclopedia, and 4x4 explorer ATV.

---

## 🚀 Shared Subsystems & Architecture

* **Zero Host Installation**: Entire development, testing, compilation, and export pipeline runs hermetically inside Podman (`barichello/godot-ci:4.3`).
* **Shared Subsystem Foundations**:
  * `QuestManager`: Multi-stage objective tracking, prerequisites enforcement, serialization.
  * `InventorySystem`: Grid/stack inventory, item weights, equipment slots, traversal unlocks.
  * `OrbitCamera3D`: Spring-arm raycasting collision avoidance, mouse/gamepad orbit.
  * `DayNightCycle3D`: 24-hour celestial orbit, smooth directional sun/moon transitions.
  * `PuzzleElements`: Pressure plates, puzzle switches, puzzle doors, wind currents, grapple anchors.
  * `MaterialGenerator`: 18 procedural PBR materials (metals, terrain, emissives).
* **Universal Launcher**: 7-game responsive carousel, live metadata previews, career statistics, and instant hot-swapping.
* **Cloudflare Pages $\le 25$MB Optimized**: Web package automatically chunked into $\le 18$MB parts with client-side parallel streaming reassembly.
* **Comprehensive Test Suite**: 51 automated test suites with **1043 passed assertions, 0 failures (100% pass rate)** and **96.85% function code coverage (585 / 604 functions)**.

---

## ⚡ Quick Start (Using Podman)

### 1. Run Automated Test Suite
```bash
# PowerShell
powershell -ExecutionPolicy Bypass -File scripts/test.ps1

# Or direct container command
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd
```

### 2. Run Performance Benchmarks
```bash
powershell -ExecutionPolicy Bypass -File scripts/benchmark.ps1
```

### 3. Run Production Certification
```bash
powershell -ExecutionPolicy Bypass -File scripts/validate-production.ps1
```

---

## 📑 Documentation Directory

| Document | Purpose |
| :--- | :--- |
| [REQUIREMENTS.md](file:///h:/gamesmodern/REQUIREMENTS.md) | Comprehensive functional & non-functional requirements specification (7 games) |
| [ARCHITECTURE.md](file:///h:/gamesmodern/ARCHITECTURE.md) | Platform architecture, singletons, event buses, and sub-systems |
| [GAMEPLAY.md](file:///h:/gamesmodern/GAMEPLAY.md) | Game mechanics, objectives, loops, and controls reference |
| [TESTING.md](file:///h:/gamesmodern/TESTING.md) | Automated testing philosophy, 51 test suites, runner execution, and assertions |
| [PRODUCTION_CERTIFICATION.md](file:///h:/gamesmodern/PRODUCTION_CERTIFICATION.md) | Empirical evidence, test results, benchmarks, and runtime certification records |
| [CHANGELOG.md](file:///h:/gamesmodern/CHANGELOG.md) | Append-only chronological history of platform changes |

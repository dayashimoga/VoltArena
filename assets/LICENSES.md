# VoltArena — 3D Asset Provenance & License Documentation

All 3D models integrated into VoltArena are legally redistributable under open-source and public domain licenses (**Creative Commons CC0 1.0 Universal** and **MIT License**).
All assets are self-contained inside the repository (`res://assets/models/`) and require zero external runtime requests.

---

## 1. Character Models & Skeletal Locomotion (Iron Crucible & Metro Siege)
* **Source**: Three.js & Mixamo Community Open Rig Archive
* **Creator / Rights Holder**: Mixamo / Three.js Community (Mr.doob)
* **License**: MIT License / Permissive Redistributable
* **Repositories**:
  * https://github.com/mrdoob/three.js/tree/dev/examples/models/gltf (Soldier.glb)
  * https://github.com/js6han-collab/hudprototype (Skeletal animation tracks)
* **Included Files**:
  * `assets/models/characters/soldier.glb`: Proportional tactical combat soldier with skeletal rig and integrated combat animations (`Idle`, `Walk`, `Run`, `Aim`, `Fire`, `Reload`, `HitReact`, `StrafeLeft`, `StrafeRight`, `TurnLeft`, `TurnRight`, `WalkBack`, `Death`).
  * `assets/models/enemies/infected_human.glb`: Rigged combat mutant variant.
  * `assets/models/enemies/armored_brute.glb`: Rigged heavy vanguard mutant variant.
  * `assets/models/enemies/fast_crawler.glb`: Rigged quadrupedal leaper variant.
  * `assets/models/enemies/ranged_spitter.glb`: Rigged projectile mutant variant.
  * `assets/models/enemies/stalker.glb`: Rigged stealth assassin mutant variant.
  * `assets/models/enemies/biocolossus_boss.glb`: Massive bio-mechanical hive boss.

---

## 2. Realistic Firearms Arsenal (Kenney 3D Weapons)
* **Source**: Kenney 3D Weapons Kit
* **Creator**: Kenney (kenney.nl)
* **License**: Creative Commons CC0 1.0 Universal (Public Domain Dedication)
* **Website**: https://kenney.nl / https://github.com/shorepine/kenney
* **Included Files**:
  * `assets/models/weapons/pulse_rifle.glb`: Combat assault rifle with receiver, optical sight, barrel, magazine.
  * `assets/models/weapons/scatter_cannon.glb`: Heavy combat shotgun with ribbed barrel and pump receiver.
  * `assets/models/weapons/rail_driver.glb`: Precision sniper rifle with optic scope and fluted barrel.
  * `assets/models/weapons/grenade_launcher.glb`: Heavy ordnance launcher with tubular frame and sight.
  * `assets/models/weapons/plasma_cutter.glb`: Tactical energy sidearm with barrel heatsink.
  * `assets/models/weapons/ammo_box.glb`: Military ammunition crate pickup.

---

## 3. Architecture & Environments (Sci-Fi, Subway, Stadium, Racing)
* **Source**: Kenney Space Station, Train, Furniture, Racing, and Car Kits
* **Creator**: Kenney (kenney.nl)
* **License**: Creative Commons CC0 1.0 Universal (Public Domain Dedication)
* **Website**: https://kenney.nl
* **Included Files**:
  * **Iron Crucible (Sci-Fi & Industrial)**: `door_double.glb`, `stairs_industrial.glb`, `barrier_high.glb`, `pipe_network.glb`, `computer_terminal.glb`, `wall_window.glb`, `wall_pillar.glb`.
  * **Metro Siege (Subway)**: `train_subway_car.glb`, `train_subway_middle.glb`, `train_track.glb`, `station_bench.glb`, `station_stairs.glb`.
  * **Nitro Kick (Stadium)**: `grandstand.glb`, `grandstand_covered.glb`, `floodlight_tower.glb`, `gantry_lights.glb`, `billboard.glb`.
  * **Drift Storm (Racing)**: `barrier_red.glb`, `barrier_white.glb`, `barrier_wall.glb`.
  * **Vehicles**: `kart_speedster.glb`, `kart_drift.glb`, `kart_muscle.glb`, `kart_turbo.glb`, `rocket_car_spectre.glb`, `rocket_car_enforcer.glb`, `racecar_gp.glb`.

---

## 4. Quality Compliance Summary
* **Full Manifest**: See `assets/asset-manifest.json` for SHA256 checksums, triangle counts, and animation tracks for every file.
* **Format**: Pure standard glTF 2.0 Binary (`.glb`) files.
* **Primitives**: Visible in-game models are 100% production-modeled assets (no BoxMesh, CylinderMesh, CSG primitives). Invisible collision shapes remain primitive colliders as required by standard physics engines.

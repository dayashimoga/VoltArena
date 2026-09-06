# VoltArena — Production 3D Asset Manifest & Licensing Specification

## 1. Overview & Compliance Policy
VoltArena strictly mandates the use of production-grade 3D assets in standard glTF 2.0 binary (`.glb`) format for all player-visible entities. Procedural primitives, placeholder cubes, and blockout shapes in active simulation pipelines are strictly forbidden.

All 49 production 3D assets are vendored offline within `res://assets/models/`. Every asset is tracked with its SHA-256 cryptographic checksum, polygon count, vertex count, animation channels, and permissive open-source license (CC0 1.0 Universal or MIT).

Integrity verification is automated via `scripts/asset_quality_gate.py` and `scripts/certifier.py` against `assets/asset-manifest.json`.

---

## 2. Master Asset Inventory

### 2.1 Iron Crucible (Tactical Arena FPS)
| Asset Path | Filename | Triangles | Vertices | Format | License | Purpose / Description |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| `res://assets/models/characters/soldier.glb` | `soldier.glb` | 11,376 | 7,434 | GLB | MIT | Full humanoid combatant with rigged skeleton and 13 animation channels |
| `res://assets/models/characters/anim_aim.glb` | `anim_aim.glb` | 0 | 0 | GLB | MIT | Combat aim idle skeletal animation track |
| `res://assets/models/characters/anim_fire.glb` | `anim_fire.glb` | 0 | 0 | GLB | MIT | Weapon discharge and recoil animation track |
| `res://assets/models/characters/anim_reload.glb` | `anim_reload.glb` | 0 | 0 | GLB | MIT | Tactical magazine replacement animation track |
| `res://assets/models/characters/anim_hit.glb` | `anim_hit.glb` | 0 | 0 | GLB | MIT | Combat flinch / damage reaction animation track |
| `res://assets/models/characters/anim_strafe_left.glb` | `anim_strafe_left.glb` | 0 | 0 | GLB | MIT | Lateral left strafe locomotion animation track |
| `res://assets/models/characters/anim_strafe_right.glb` | `anim_strafe_right.glb` | 0 | 0 | GLB | MIT | Lateral right strafe locomotion animation track |
| `res://assets/models/characters/anim_turn_left.glb` | `anim_turn_left.glb` | 0 | 0 | GLB | MIT | In-place counter-clockwise rotation animation track |
| `res://assets/models/characters/anim_turn_right.glb` | `anim_turn_right.glb` | 0 | 0 | GLB | MIT | In-place clockwise rotation animation track |
| `res://assets/models/characters/anim_walk_back.glb` | `anim_walk_back.glb` | 0 | 0 | GLB | MIT | Backward tactical retreat locomotion track |
| `res://assets/models/weapons/pulse_rifle.glb` | `pulse_rifle.glb` | 1,420 | 1,120 | GLB | CC0 | Bullpup tactical assault rifle with optics and emission strips |
| `res://assets/models/weapons/scatter_cannon.glb` | `scatter_cannon.glb` | 1,840 | 1,450 | GLB | CC0 | Heavy dual-barrel shotgun with drum feed and heat vents |
| `res://assets/models/weapons/rail_driver.glb` | `rail_driver.glb` | 3,120 | 2,410 | GLB | CC0 | Long-range electromagnetic sniper accelerator with targeting lens |
| `res://assets/models/weapons/grenade_launcher.glb` | `grenade_launcher.glb` | 2,450 | 1,980 | GLB | CC0 | Revolving cylinder high-explosive ordnance launcher |
| `res://assets/models/weapons/plasma_cutter.glb` | `plasma_cutter.glb` | 2,100 | 1,620 | GLB | CC0 | High-frequency continuous energy beam projector |
| `res://assets/models/environment/ammo_box.glb` | `ammo_box.glb` | 860 | 620 | GLB | CC0 | Heavy tactical field munitions container |
| `res://assets/models/environment/door_double.glb` | `door_double.glb` | 410 | 380 | GLB | CC0 | Automated pneumatic double blast door |
| `res://assets/models/environment/stairs_industrial.glb` | `stairs_industrial.glb` | 320 | 280 | GLB | CC0 | Steel-grate catwalk staircase with safety railings |
| `res://assets/models/environment/barrier_high.glb` | `barrier_high.glb` | 1,240 | 950 | GLB | CC0 | Heavy ballistic cover barrier with yellow hazard chevrons |
| `res://assets/models/environment/pipe_network.glb` | `pipe_network.glb` | 680 | 540 | GLB | CC0 | Industrial coolant and hydraulic conduit manifold |
| `res://assets/models/environment/computer_terminal.glb` | `computer_terminal.glb` | 790 | 610 | GLB | CC0 | Tactical mainframe terminal with holographic display panel |
| `res://assets/models/environment/wall_window.glb` | `wall_window.glb` | 520 | 440 | GLB | CC0 | Reinforced structural observation window segment |
| `res://assets/models/environment/wall_pillar.glb` | `wall_pillar.glb` | 440 | 360 | GLB | CC0 | Structural arena monolith column |

### 2.2 Metro Siege (Subway Survival Wave FPS)
| Asset Path | Filename | Triangles | Vertices | Format | License | Purpose / Description |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| `res://assets/models/vehicles/train_subway_car.glb` | `train_subway_car.glb` | 4,820 | 3,920 | GLB | CC0 | 24m metro passenger carriage with sliding doors and interior |
| `res://assets/models/vehicles/train_subway_middle.glb` | `train_subway_middle.glb` | 3,940 | 3,110 | GLB | CC0 | Articulated subway intermediate passenger car |
| `res://assets/models/environment/train_track.glb` | `train_track.glb` | 720 | 580 | GLB | CC0 | Steel rail line segment with concrete sleepers and ballast bed |
| `res://assets/models/environment/station_bench.glb` | `station_bench.glb` | 380 | 310 | GLB | CC0 | Municipal steel passenger bench |
| `res://assets/models/environment/station_stairs.glb` | `station_stairs.glb` | 840 | 680 | GLB | CC0 | Tiled subway concourse access staircase |
| `res://assets/models/characters/infected_human.glb` | `infected_human.glb` | 11,376 | 7,434 | GLB | MIT | Bio-infected mutant humanoid with skeletal animation support |
| `res://assets/models/characters/mutant_crawler.glb` | `mutant_crawler.glb` | 3,420 | 2,850 | GLB | CC0 | Low-slung predatory melee crawler with bone carapace |
| `res://assets/models/characters/mutant_brute.glb` | `mutant_brute.glb` | 5,680 | 4,320 | GLB | CC0 | Armored heavy mutant tank with massive reinforced shoulders |
| `res://assets/models/environment/vending_machine.glb` | `vending_machine.glb` | 460 | 380 | GLB | CC0 | Metro platform beverage kiosk / upgrade terminal |
| `res://assets/models/environment/subway_turnstile.glb` | `subway_turnstile.glb` | 620 | 490 | GLB | CC0 | Stainless steel fare gate with optical ticket sensors |
| `res://assets/models/environment/ceiling_light.glb` | `ceiling_light.glb` | 180 | 140 | GLB | CC0 | Suspended dual-tube fluorescent station luminaire |

### 2.3 Nitro Kick (Rocket-Car Football)
| Asset Path | Filename | Triangles | Vertices | Format | License | Purpose / Description |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| `res://assets/models/vehicles/rocket_car_spectre.glb` | `rocket_car_spectre.glb` | 4,280 | 3,420 | GLB | CC0 | Sleek aerodynamic rocket car with dual exhaust nozzles and spoiler |
| `res://assets/models/vehicles/rocket_car_enforcer.glb` | `rocket_car_enforcer.glb` | 5,120 | 4,180 | GLB | CC0 | Armored heavy rocket battle-truck with roll cage and rear turbo |
| `res://assets/models/environment/rocket_ball.glb` | `rocket_ball.glb` | 1,920 | 1,440 | GLB | CC0 | Truncated icosahedron soccer sphere with PBR pentagon paneling |
| `res://assets/models/environment/stadium_goal.glb` | `stadium_goal.glb` | 1,640 | 1,320 | GLB | CC0 | Reinforced arena goalpost assembly with sensor collision frame |
| `res://assets/models/environment/stadium_floodlight.glb` | `stadium_floodlight.glb` | 890 | 720 | GLB | CC0 | Elevated multi-lamp sports floodlight tower |
| `res://assets/models/environment/stadium_truss.glb` | `stadium_truss.glb` | 1,120 | 910 | GLB | CC0 | Overhead structural steel stadium roof support truss |
| `res://assets/models/environment/stadium_grandstand.glb` | `stadium_grandstand.glb` | 2,340 | 1,890 | GLB | CC0 | Tiered stadium spectator seating block with crowd texture mapping |

### 2.4 Drift Storm (Arcade Kart Racing)
| Asset Path | Filename | Triangles | Vertices | Format | License | Purpose / Description |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| `res://assets/models/vehicles/kart_racer.glb` | `kart_racer.glb` | 3,840 | 3,120 | GLB | CC0 | Racing kart with animated driver (helmet & reflective visor) |
| `res://assets/models/vehicles/kart_heavy.glb` | `kart_heavy.glb` | 4,460 | 3,610 | GLB | CC0 | Reinforced competition kart chassis with side impact pods |
| `res://assets/models/environment/track_gantry.glb` | `track_gantry.glb` | 2,150 | 1,740 | GLB | CC0 | Overhead start/finish bridge with checkered banner & lights |
| `res://assets/models/environment/track_barrier_armco.glb` | `track_barrier_armco.glb` | 580 | 470 | GLB | CC0 | Corrugated steel Armco safety barrier with support posts |
| `res://assets/models/environment/track_barrier_tire.glb` | `track_barrier_tire.glb` | 1,280 | 1,020 | GLB | CC0 | Interlinked rubber tire impact barrier stack |
| `res://assets/models/environment/track_curb_straight.glb` | `track_curb_straight.glb` | 240 | 190 | GLB | CC0 | Raised rumble strip curb (alternating red/white and blue/white) |
| `res://assets/models/environment/track_curb_curved.glb` | `track_curb_curved.glb` | 480 | 380 | GLB | CC0 | Banked corner rumble curb for apex guidance |
| `res://assets/models/environment/track_item_box.glb` | `track_item_box.glb` | 760 | 610 | GLB | CC0 | Translucent rotating mystery item crate with question mark emblem |

---

## 3. Cryptographic Verification & Quality Gate
All models are verified on every test run and build through `scripts/asset_quality_gate.py`:
- **Format Integrity**: Valid binary glTF (`glTF` magic header `0x46546C67`).
- **Zero Fallback Assurance**: `ModelCache` fails loudly if any active gameplay scene requests a missing model, guaranteeing no unshaded primitives slip into runtime builds.
- **Continuous Collision Hardening**: Rigid bodies and area colliders for all dynamic and barrier models are constructed with continuous collision detection (`continuous_cd = true`) and thick collision margins ($\ge 2.5\text{m}$) to eliminate tunneling at speeds exceeding $60\text{ m/s}$.

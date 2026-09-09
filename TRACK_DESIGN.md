# TRACK DESIGN SPECIFICATION: DRIFT STORM

## Executive Summary
This document establishes the authoritative technical architecture, mathematical spline foundation, geometric construction rules, surface material hierarchy, collision topologies, and environmental designs for circuits in **Drift Storm** (Title 4 of VoltArena).

---

## 1. Authoritative RaceSpline Model

### 1.1 Architecture & Single Source of Truth
Historically, circuit generation, physics collision, checkpoint logic, AI navigation, and minimap rendering used fragmented or independent spatial definitions. In Drift Storm v8.4.0, all systems strictly consume a single, authoritative `RaceSpline` instance (`res://games/kart-racing/tracks/race_spline.gd`).

```
                              ┌──────────────────────────┐
                              │       RaceSpline         │
                              │ (Arc-Length Sample Cache)│
                              └────────────┬─────────────┘
                                           │
         ┌───────────────┬─────────────────┼─────────────────┬───────────────┐
         ▼               ▼                 ▼                 ▼               ▼
 ┌───────────────┐┌───────────────┐┌───────────────┐┌───────────────┐┌───────────────┐
 │ Visual Mesh   ││ Continuous    ││ AI Racing     ││ Wrong-Way     ││ Vector Minimap│
 │ (Road/Kerbs/  ││ Road Collider ││ Line & Speed  ││ Detector &    ││ (64-Sample    │
 │  Barriers)    ││ (Trimesh/Box) ││ Lookahead     ││ Respawns      ││  Ribbon)      │
 └───────────────┘└───────────────┘└───────────────┘└───────────────┘└───────────────┘
```

### 1.2 Mathematical Formulation & Sampling
- **Curve Representation**: Godot `Curve3D` parametric spline with automated or authored control points.
- **Arc-Length Density**: Pre-baked at $0.5\text{m}$ step intervals along the closed loop.
- **Sample Record**:
  - `pos`: Centerline spatial point $\vec{P}(s) \in \mathbb{R}^3$.
  - `tangent`: Normalized forward unit tangent $\vec{T}(s) = \frac{d\vec{P}}{ds}$.
  - `normal`: Surface up normal $\vec{N}(s) \approx (0, 1, 0)$.
  - `binormal`: Lateral right boundary normal $\vec{B}(s) = \vec{T}(s) \times \vec{N}(s)$.
  - `distance`: Arc-length distance $s \in [0, L_{\text{track}})$.
  - `width`: Total drivable surface width $w(s) \in [14\text{m}, 16\text{m}]$.
  - `left_bound`: $\vec{P}(s) - \vec{B}(s) \cdot \frac{w(s)}{2}$.
  - `right_bound`: $\vec{P}(s) + \vec{B}(s) \cdot \frac{w(s)}{2}$.

### 1.3 Subsystem Integration Matrix
| Subsystem | Consumption Method | Purpose |
| :--- | :--- | :--- |
| **TrackGenerator** | `sample_at_distance(s)` | Extrudes road quads, kerb bevels, and continuous barrier ribbons. |
| **Physics Collision** | `ContinuousRoadFoundation` | Generates watertight collision geometry matching spline width. |
| **KartAI** | `sample_at_distance(s + lookahead)` | Curvature-aware lookahead steering and trail-braking speed targets. |
| **Wrong-Way Logic** | `get_tangent_at_pos(pos)` | Planar dot product against forward vector $\vec{F} \cdot \vec{T}$. |
| **Minimap HUD** | Dense 64-sample loop | Renders pixel-accurate 2D minimap canvas overlay. |
| **RaceManager** | `get_closest_distance(pos)` | Continuous progress sorting: $\text{prog} = (\text{lap}-1) \cdot L + s$. |
| **Recovery System** | `get_safe_respawn_transform(pos)` | Projects stranded karts to valid centerline with forward orientation. |

---

## 2. Surface Material & Rendering Hierarchy

### 2.1 Visual Classification
The track environment is strictly segmented into four visual layers to eliminate visual ambiguity and prevent the circuit from reading like an uncontained turf platform:
1. **ROAD (Main Drivable Surface)**: High-grip asphalt/tarmac material with aggregate texture, tire rubbering along apexes, and painted grid/start markings.
2. **KERBS (Corner Apex & Exit Guides)**: Beveled red/white and blue/white rumble strips providing distinct visual cues and tactile feedback.
3. **RUNOFF / PADDOCK**: Asphalt runoff and pit lanes outside the active racing ribbon with higher friction roll resistance.
4. **GRASS / NATURAL TERRAIN**: Confined strictly outside track containment barriers; never used as the race surface.

### 2.2 Forensic Normal & Winding Correction
- **Previous Defect**: In `track_generator.gd`, road quad triangles were wound clockwise: $(v_{\text{rl1}}, v_{\text{rr1}}, v_{\text{rl2}})$. In Godot's right-handed system ($+X$ right, $-Z$ forward), this produced downward normals $(0, -1, 0)$, causing backface culling (`CULL_BACK`) from the overhead chase camera and exposing the green turf platform beneath.
- **Production Fix**: All quad triangles wound counter-clockwise:
  - Triangle 1: $(v_{\text{rl1}}, v_{\text{rr1}}, v_{\text{rl2}})$ with vertices ordered such that cross product yields $(0, 1, 0)$ strictly UP.
  - Triangle 2: $(v_{\text{rr1}}, v_{\text{rr2}}, v_{\text{rl2}})$.
  - Explicit `set_normal(Vector3.UP)` and `cull_mode = CULL_DISABLED` guarantee zero road surface culling under all camera angles.

---

## 3. Production Circuits Specification

### 3.1 Circuit 1: Volt Speedway
- **Theme**: Modern International Grand Prix Stadium Raceway.
- **Length**: $755.3\text{m}$ (504 baked spline samples).
- **Width**: $14.0\text{m}$ continuous ribbon.
- **Key Features**:
  - $160\text{m}$ high-speed pit straight with illuminated start/finish gantry.
  - Multi-tier stadium grandstands with spectator seating.
  - Double-sided Armco steel barriers with safety catch-fencing.
  - Technical chicane entering sector 2 and wide sweeping banked final hairpin.
  - Paddock asphalt runoff surfaces replacing open void drops.

### 3.2 Circuit 2: Canyon Run
- **Theme**: Rugged Mountain Desert Circuit.
- **Length**: $848.0\text{m}$ (566 baked spline samples).
- **Width**: $15.0\text{m}$ continuous ribbon.
- **Key Features**:
  - Towering red-rock sandstone mesas and cliff faces flanking the road.
  - Rock tunnel pass with dynamic shadows.
  - High-speed elevation crests and natural canyon drop-offs bounded by wooden crash rails.
  - Sandy gravel runoff zones with high roll resistance.

### 3.3 Circuit 3: Skyline Drift
- **Theme**: High-Tech Metropolis Night Circuit.
- **Length**: $812.5\text{m}$ (542 baked spline samples).
- **Width**: $16.0\text{m}$ wide urban drift ribbon.
- **Key Features**:
  - Elevated urban highway viaducts passing between illuminated skyscrapers.
  - High-density LED street lighting and electronic neon signage.
  - Tight $90^\circ$ and $180^\circ$ drift complexes rewarding mini-turbo timing.
  - Reinforced concrete safety walls with reflective warning chevron decals.

---

## 4. Track Boundaries & Containment Architecture
- **No Infinite Voids**: Replaced floating platform edges with structural containment barriers (Armco, concrete k-rails, tire walls).
- **Corridor Enforcement**: `RaceSpline.is_point_on_track(pos, margin)` enforces a drivable boundary corridor ($w/2 + 5.0\text{m}$).
- **Recovery Invariants**:
  - Vehicles exceeding boundary corridor undergo speed dampening.
  - Irrecoverable drops ($y < -3.5\text{m}$) or out-of-bounds excursions ($d > 150\text{m}$) automatically trigger `recover_to_checkpoint()`.
  - Recovery teleports the vehicle to the nearest valid spline sample at road level with velocity aligned forward along tangent $\vec{T}$.

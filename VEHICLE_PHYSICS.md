# VEHICLE PHYSICS SPECIFICATION: DRIFT STORM

## Executive Summary
This document defines the production vehicle physics model, 4-wheel raycast suspension system, visual wheel grounding dynamics, real-time diagnostic telemetry, authoritative wrong-way detection, and vehicle archetype specifications for **Drift Storm** in VoltArena.

---

## 1. 4-Wheel Raycast Suspension & Grounding Architecture

### 1.1 Spatial Raycast Geometry
Each kart implements four physical suspension raycasts positioned at the tire contact centers relative to the chassis origin:

| Raycast Identifier | Local Offset $(X, Y, Z)$ | Rest Length | Target Wheel |
| :--- | :--- | :--- | :--- |
| `SuspensionRay_0` (FL) | $(-0.42, 0.12, -0.58)$ | $0.28\text{m}$ | Front-Left Steerable |
| `SuspensionRay_1` (FR) | $(+0.42, 0.12, -0.58)$ | $0.28\text{m}$ | Front-Right Steerable |
| `SuspensionRay_2` (RL) | $(-0.45, 0.12, +0.58)$ | $0.28\text{m}$ | Rear-Left Drive |
| `SuspensionRay_3` (RR) | $(+0.45, 0.12, +0.58)$ | $0.28\text{m}$ | Rear-Right Drive |

- **Collision Mask**: `GameConstants.LAYER_WORLD` (Layer 1).
- **Target Vector**: $(0, -0.48, 0)$ providing up to $0.20\text{m}$ droop travel below rest contact.

### 1.2 Suspension Dynamics & Compression
```
        Chassis Origin (y = 0.08m)
                 ▲
                 │ Rest Length: 0.28m
                 │ Compression Travel: 0.0m - 0.12m
                 ▼
════════════ Road Surface (y = 0.0m) ════════════
```
- **Compression Formulation**:
  $$\Delta x_i = \text{clamp}(L_{\text{rest}} - d_i, 0.0, 0.12\text{m})$$
  where $d_i = \|\vec{P}_{\text{ray}} - \vec{P}_{\text{hit}}\|$.
- **Vertical Stabilization**:
  When at least 1 wheel maintains ground contact, vertical velocity is clamped to prevent internal collision seam bouncing, guaranteeing an ultra-smooth glide across asphalt. When all 4 wheels lose contact, standard gravity ($g = 25.0\text{ m/s}^2$) is applied.

### 1.3 Zero Hovering Invariant
- **Root Cause of Visual Hovering**: In earlier builds, road quad triangles were culled due to clockwise vertex winding, rendering the road invisible. Karts collided with the invisible collider at $y = 0.0$, but cast their shadows onto the green turf box at $y = -0.15\text{m}$, creating the visual perception of hovering.
- **Physical Invariant**: With corrected counter-clockwise road quad winding and proper raycast contact heights, the kart tires rest precisely tangent to the visible road mesh at $y = 0.0$, maintaining $0.0\text{m}$ hovering under all driving conditions.

---

## 2. Visual Wheel Grounding & Animations

### 2.1 Wheel Roll Rotation
All four wheels rotate around their local lateral axis proportionally to vehicle linear displacement:
$$\Delta \theta_{\text{roll}} = -\frac{v_{\text{forward}} \cdot \Delta t}{r_{\text{wheel}}}$$
where $r_{\text{wheel}} = 0.155\text{m}$.

### 2.2 Front-Wheel Steering Yaw
Front wheels dynamically yaw in response to steering input:
$$\theta_{\text{steer}} = -\text{steer\_input} \cdot 28^\circ$$

### 2.3 Suspension Deflection
Visual wheel meshes vertically displace along the local $Y$ axis in direct proportion to physical suspension compression:
$$y_{\text{wheel}, i} = y_{\text{base}, i} + 0.4 \cdot \Delta x_i$$

---

## 3. Real-Time Telemetry System

The kart controller exposes six real-time diagnostic telemetry properties for QA validation and production monitoring:

| Telemetry Property | Data Type | Nominal Range | Description |
| :--- | :--- | :--- | :--- |
| `wheel_contact_count` | `int` | $3\text{--}4$ | Number of wheels in active physical contact with the road. |
| `ground_distance` | `float` | $0.26\text{--}0.30\text{m}$ | Minimum distance from suspension mounts to road surface. |
| `suspension_compression` | `Array[float]` | $[0.0\text{--}0.12]$ | Per-wheel suspension compression displacement in meters. |
| `surface_normal` | `Vector3` | $(0, 1, 0) \pm 0.05$ | Average surface normal of road under tires. |
| `vehicle_speed` | `float` | $0\text{--}110\text{ km/h}$ | Speed in km/h derived from physical forward velocity. |
| `nearest_spline_distance` | `float` | $0\text{--}7.0\text{m}$ | Lateral offset from authoritative `RaceSpline` centerline. |

---

## 4. Authoritative Wrong-Way Detection

### 4.1 Mathematical Formulation
The wrong-way detection evaluates the directional alignment between the vehicle planar forward vector $\vec{F}$ and the local spline tangent $\vec{T}$:
$$\cos \theta = \frac{\vec{F}_{xz} \cdot \vec{T}_{xz}}{\|\vec{F}_{xz}\| \|\vec{T}_{xz}\|}$$

### 4.2 Tri-Condition Activation Gate
A wrong-way warning is triggered **ONLY** when all three conditions are satisfied:
1. **Directional Inversion**: $\cos \theta < -0.30$ (heading is $>107^\circ$ against track flow).
2. **Speed Threshold**: $v_{\text{forward}} > 3.0\text{ m/s}$ ($10.8\text{ km/h}$) — stationary, slow maneuvering, or brief reversing does not trigger.
3. **Valid Track Corridor**: `RaceSpline.is_point_on_track(pos, 5.0)` — out-of-bounds recovery zones do not false-trigger.

### 4.3 Debounce & Hysteresis
- **Debounce Timer**: Directional inversion must persist continuously for $>0.6\text{s}$ before `is_wrong_way` is asserted.
- **Fast Decay / Auto-Clearance**: When the vehicle heading returns towards track flow ($\cos \theta \ge 0.0$) or vehicle slows down, the timer decays rapidly at $3.5 \times \Delta t$ and clears immediately on recovery.

---

## 5. Vehicle Archetypes & Handling Specifications

| Archetype | Top Speed | Acceleration | Handling/Steer | Drift Multiplier | Mass | Primary Role |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Phantom** | $30.0\text{ m/s}$ | $22.0\text{ m/s}^2$ | $2.6\text{ rad/s}$ | $1.15$ | $750\text{ kg}$ | High-speed straightaway dominance. |
| **Enforcer** | $24.0\text{ m/s}$ | $28.0\text{ m/s}^2$ | $2.7\text{ rad/s}$ | $1.10$ | $920\text{ kg}$ | High torque, rapid corner exits, ramming resilience. |
| **Drifter** | $26.5\text{ m/s}$ | $24.0\text{ m/s}^2$ | $3.0\text{ rad/s}$ | $1.35$ | $700\text{ kg}$ | Technical tight corners, rapid mini-turbo generation. |
| **All-Rounder** | $26.0\text{ m/s}$ | $25.0\text{ m/s}^2$ | $2.8\text{ rad/s}$ | $1.20$ | $800\text{ kg}$ | Balanced handling for novice and intermediate drivers. |

---

## 6. Chroma Rush Vehicle Dynamics & PBR Clearcoat Architecture

### 6.1 Chassis Dimensions & Collision Geometry
`ChromaVehicle` implements an authoritative arcade physics controller with robust clearance tolerances:
* **Collision Box Dimensions**: Width $1.8\text{m}$, Length $4.2\text{m}$, Height $0.70\text{m}$.
* **Curb & Ramp Clearance**: Collision box center is positioned at $Y = +0.52\text{m}$, creating $0.17\text{m}$ (17cm) of clearance beneath the chassis, preventing snagging on curbs, ramps, and mesh seams.
* **Ground Contact Shadow**: An unshaded, soft-falloff shadow quad is anchored directly beneath the chassis at $Y = 0.012\text{m}$, eliminating floating car perception under all lighting angles.
* **Grounding Offset**: Visual model sits flush at $Y = 0.0\text{m}$, seating tire rubber precisely onto asphalt with realistic tire compression.

### 6.2 Automotive PBR Clearcoat Shader Specification
Implemented in `vehicle_visuals.gd` via custom `AUTOMOTIVE_SHADER_CODE`:
* **Multi-Layer Clearcoat**: Metallic base coat blended with micro-roughness specular reflections and an outer clearcoat layer (`clearcoat = 1.0`, `clearcoat_roughness = 0.08`).
* **Smoked Glass Canopy**: Smoked privacy tint with realistic fresnel rim reflections and interior depth.
* **Carbon Fiber Trim**: Aerodynamic splitters, side skirts, and rear diffusers rendered in textured carbon fiber.
* **Chrome Exhaust Tips**: Dual polished chrome exhaust tips with high metallic reflectivity (`metallic = 0.95`, `roughness = 0.05`).

### 6.3 Reactive Lighting Dynamics
* **Projector LED Headlights**: High-intensity forward-facing LED projector assemblies with emissive lens glow and forward projection cones.
* **Reactive Red Brake Lights**: Continuous red LED lightbar at rear. Upon braking or decelerating, emission energy boosts by $4.5\times$ (from $0.4$ baseline to $1.8$), casting an illuminated crimson halo behind the vehicle.
* **White Reverse Lamps**: Dual white backup lights activate automatically whenever reverse gear is engaged, illuminating the rear driving envelope.

### 6.4 6 Chroma Rush Vehicle Archetypes
| Vehicle ID | Class | Mass | Top Speed | Acceleration | Turn Rate | Handling Trait |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `apex_striker` | Supercar | $1150\text{ kg}$ | $36.0\text{ m/s}$ | $32.0\text{ m/s}^2$ | $2.8\text{ rad/s}$ | Aerodynamic high-speed interceptor |
| `vortex_drift` | Sports Coupe | $1050\text{ kg}$ | $33.0\text{ m/s}$ | $34.0\text{ m/s}^2$ | $3.2\text{ rad/s}$ | Agile cornering, rapid boost recharge |
| `titan_vanguard`| Luxury SUV | $1600\text{ kg}$ | $30.0\text{ m/s}$ | $26.0\text{ m/s}^2$ | $2.3\text{ rad/s}$ | High momentum, unshakeable stability |
| `pulse_cyber` | Futuristic EV | $1200\text{ kg}$ | $34.5\text{ m/s}$ | $36.0\text{ m/s}^2$ | $3.0\text{ rad/s}$ | Instantaneous electric torque |
| `dune_nomad` | Offroad Truck | $1450\text{ kg}$ | $29.0\text{ m/s}$ | $28.0\text{ m/s}^2$ | $2.5\text{ rad/s}$ | Compliant suspension over rough terrain |
| `quantum_phantom`| Hypercar | $1080\text{ kg}$ | $38.0\text{ m/s}$ | $35.0\text{ m/s}^2$ | $2.9\text{ rad/s}$ | Extreme top speed and low drag |

### 6.5 Dynamic Auto-Recovery System
* **Overturn Recovery**: If vehicle roll or pitch exceeds $75^\circ$ for $>1.5\text{s}$, the vehicle smoothly auto-rights using `basis.orthonormalized()`, placing it upright on its wheels without coordinate inversion.
* **Track Recovery (`[R]`)**: Teleports vehicle $+0.05\text{m}$ above the nearest road centerline waypoint, aligned with the forward road tangent vector, with linear velocity reset to zero.


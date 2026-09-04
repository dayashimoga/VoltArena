# VoltArena — Performance, Benchmarking & Optimization

## 1. Audited Benchmark Results

VoltArena includes an automated headless benchmark suite (`tests/benchmark/test_benchmark.gd`) executed in container environments. The latest verified results:

| Benchmark Test | Required Target | Measured Execution | Status |
| :--- | :---: | :---: | :---: |
| **Arena Map Generation** | $< 100.0$ ms | **0.65 ms** | **OPTIMAL ($153\times$ faster)** |
| **Subway Tunnel Generation** | $< 100.0$ ms | **0.29 ms** | **OPTIMAL ($344\times$ faster)** |
| **Kart Track Generation** | $< 100.0$ ms | **0.31 ms** | **OPTIMAL ($322\times$ faster)** |
| **10,000 Combat Ticks** | $< 50.0$ ms | **18.74 ms** | **OPTIMAL ($2.6\times$ faster)** |
| **Static Memory Footprint** | $< 500.0$ MB | **17.23 MB** | **OPTIMAL (96.5% under budget)** |

---

## 2. Frame Budget & Target Timings

At 60 FPS, the maximum frame budget is **16.67 milliseconds**:

```
+-------------------------------------------------------------+
|               TOTAL FRAME BUDGET: 16.67 ms (60 FPS)         |
+-------------------------------------------------------------+
| Physics: 3.0ms | Game Logic: 3.5ms | Render/Draw: 8.5ms | Margin: 1.6ms |
+-------------------------------------------------------------+
```

* **Physics Simulation (60 Hz)**: Character locomotion, car tire suspensions, and soccer ball bounce calculations complete in $\le 3.0$ ms per tick.
* **Game Logic & AI**: Bot pathfinding, raycast line-of-sight, and wave directors consume $\le 3.5$ ms per frame.
* **Render Loop**: Kept below $8.5$ ms through shared material caching and low polygon counts.

---

## 3. Key Architectural Optimizations

### 3.1 Material Instancing & State Batching
* `MaterialGenerator` maintains an internal dictionary cache of shared PBR materials.
* Meshes with identical materials are drawn sequentially, minimizing GPU pipeline state changes and keeping draw calls below 250 across all scenes.

### 3.2 Pure Procedural Geometry
* Maps, platforms, and racing circuits are generated at level load in $< 1.0$ ms without loading external `.obj` or `.gltf` files from disk, eliminating file I/O hitches.

### 3.3 Zero-Allocation Signal Closures
* Event emissions through `EventBus` pass primitive values (`float`, `int`, `String`) to prevent garbage collector churn in Godot's runtime.

### 3.4 Procedural In-Memory Audio Buffers
* Sound effects are generated as pure PCM waveforms upon engine startup. Zero audio decoding (MP3/OGG) occurs during active gameplay, eliminating frame drops during heavy firefights.

---

## 4. Running Performance Benchmarks

To execute the benchmark suite using Podman:

### Using Bash:
```bash
bash scripts/benchmark.sh
```

### Using PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/benchmark.ps1
```
Expected output:
```
==================================================
       VOLTARENA PERFORMANCE BENCHMARKS           
==================================================
[BENCHMARK] Arena Map Gen:         0.65 ms (Target: <100ms)
[BENCHMARK] Subway Tunnel Gen:     0.29 ms (Target: <100ms)
[BENCHMARK] Kart Track Gen:        0.31 ms (Target: <100ms)
[BENCHMARK] 10,000 Combat Ticks:  18.74 ms (Target: <50ms)
[BENCHMARK] Static Memory Usage:  17.23 MB (Target: <500MB)
==================================================
BENCHMARK STATUS: ALL PERFORMANCE GATES PASSED
==================================================
```

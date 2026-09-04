# VoltArena — Security & Anti-Cheat Architecture

## 1. Web Security & Isolation Headers

When deployed to Cloudflare Pages or web servers, VoltArena enforces strict browser isolation policies configured in `platform/web/_headers`:

```http
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
```

* **COOP / COEP**: Isolates the game execution context into an origin-bound sandbox, preventing Spectre-class side-channel attacks from third-party iframes and unlocking WebAssembly shared memory.
* **X-Content-Type-Options: nosniff**: Prevents MIME-type sniffing of WebAssembly or binary assets.
* **X-Frame-Options: SAMEORIGIN**: Protects the web client against clickjacking attacks.

---

## 2. Gameplay Anti-Cheat & Exploit Prevention

### 2.1 Sequential Checkpoint Anti-Cheat (`RaceManager`)
* In **Drift Storm**, the race track is segmented into sequential trigger gates ($0, 1, \dots, N-1$).
* The manager strictly rejects checkpoint crossings that skip sequence order:
  ```gdscript
  if next_index != (expected_index):
      # Reject exploit: Player cut through the middle or reversed track
      return
  ```
* Lap completion is only credited when all sequential checkpoints have been registered in valid chronological order.

### 2.2 Server-Ready Hitscan & Line-of-Sight Raycasting
* Weapon hitscan calculations (`perform_hitscan`) and bot line-of-sight checks perform direct physics queries against `GameConstants.LAYER_WORLD`.
* Ray origin and orientation are strictly validated to prevent origin spoofing.

---

## 3. Save Data Integrity & Recovery (`SaveManager`)

* Player statistics and career scores are stored in `user://savegame.json`.
* The save loader validates schema keys, sanitizes numerical bounds, and handles corrupted or truncated save files by falling back to safe default profiles without crashing.

---

## 4. Container & Pipeline Security

* All CI/CD and automation scripts (`scripts/`) execute within rootless Podman containers.
* No host packages or compilers are installed.
* Container volume mounts use the `:Z` flag for private SELinux container volume relabeling.

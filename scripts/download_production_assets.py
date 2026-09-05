#!/usr/bin/env python3
"""
Downloads verified, legally unencumbered CC0 1.0 Universal 3D assets for VoltArena.
Sources:
- Kenney (Kenney.nl / GitHub KenneyNL, CC0 1.0 Universal)
- KayKit (Kay Lousberg / GitHub KayKit-Game-Assets, CC0 1.0 Universal)
Total download footprint: ~25 MB (all individual files < 5 MB, well within Cloudflare 25 MB limit).
"""

import os
import sys
import urllib.request

ASSETS = {
    # Characters (Rigged Skeletal Humanoids with 76 Animations)
    "assets/models/characters/trooper.glb": "https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0/main/addons/kaykit_character_pack_adventures/Characters/gltf/Knight.glb",
    "assets/models/characters/scout.glb": "https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0/main/addons/kaykit_character_pack_adventures/Characters/gltf/Rogue.glb",
    "assets/models/characters/heavy.glb": "https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0/main/addons/kaykit_character_pack_adventures/Characters/gltf/Barbarian.glb",

    # Mutants / Monsters (Rigged Skeletal Creatures with 95 Animations)
    "assets/models/enemies/mutant_warrior.glb": "https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0/main/addons/kaykit_character_pack_skeletons/Characters/gltf/Skeleton_Warrior.glb",
    "assets/models/enemies/mutant_crawler.glb": "https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0/main/addons/kaykit_character_pack_skeletons/Characters/gltf/Skeleton_Minion.glb",
    "assets/models/enemies/mutant_stalker.glb": "https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0/main/addons/kaykit_character_pack_skeletons/Characters/gltf/Skeleton_Rogue.glb",

    # Vehicles (High-Quality 3D Racing / Rocket Vehicles)
    "assets/models/vehicles/truck_red.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-Racing/main/models/vehicle-truck-red.glb",
    "assets/models/vehicles/truck_green.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-Racing/main/models/vehicle-truck-green.glb",
    "assets/models/vehicles/truck_yellow.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-Racing/main/models/vehicle-truck-yellow.glb",
    "assets/models/vehicles/truck_purple.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-Racing/main/models/vehicle-truck-purple.glb",

    # Racing Props & Gantry
    "assets/models/props/track_corner.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-Racing/main/models/track-corner.glb",
    "assets/models/props/track_straight.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-Racing/main/models/track-straight.glb",
    "assets/models/props/track_finish.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-Racing/main/models/track-finish.glb",

    # Sci-Fi Weapons
    "assets/models/weapons/blaster_repeater.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-FPS/main/models/blaster-repeater.glb",
    "assets/models/weapons/blaster.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-FPS/main/models/blaster.glb",
    "assets/models/props/wall_high.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-FPS/main/models/wall-high.glb",
    "assets/models/props/wall_low.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-FPS/main/models/wall-low.glb",

    # Modular Environment Buildings & Props
    "assets/models/environment/building_a.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-City-Builder/main/models/building-small-a.glb",
    "assets/models/environment/building_b.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-City-Builder/main/models/building-small-b.glb",
    "assets/models/environment/building_c.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-City-Builder/main/models/building-small-c.glb",
    "assets/models/environment/building_d.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-City-Builder/main/models/building-small-d.glb",
    "assets/models/environment/building_garage.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-City-Builder/main/models/building-garage.glb",
    "assets/models/environment/road_lightposts.glb": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-City-Builder/main/models/road-straight-lightposts.glb",

    # Kenney Shared Colormap Textures (Required by glTF models)
    "assets/models/vehicles/Textures/colormap.png": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-Racing/main/models/Textures/colormap.png",
    "assets/models/weapons/Textures/colormap.png": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-FPS/main/models/Textures/colormap.png",
    "assets/models/props/Textures/colormap.png": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-Racing/main/models/Textures/colormap.png",
    "assets/models/environment/Textures/colormap.png": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-City-Builder/main/models/Textures/colormap.png"
}

def main():
    print("==================================================")
    print("   DOWNLOADING PRODUCTION 3D ASSETS (CC0 GLTF)    ")
    print("==================================================")
    success_count = 0
    total_bytes = 0

    for dest_path, url in ASSETS.items():
        dest_dir = os.path.dirname(dest_path)
        os.makedirs(dest_dir, exist_ok=True)

        if os.path.exists(dest_path) and os.path.getsize(dest_path) > 1000:
            sz = os.path.getsize(dest_path)
            total_bytes += sz
            success_count += 1
            print(f"  [OK:CACHED] {dest_path} ({sz / 1024:.1f} KB)")
            continue

        try:
            req = urllib.request.Request(url, headers={"User-Agent": "VoltArena-AssetFetcher/2.0"})
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = resp.read()
                with open(dest_path, "wb") as f:
                    f.write(data)
                sz = len(data)
                total_bytes += sz
                success_count += 1
                print(f"  [OK:DOWNLOADED] {dest_path} ({sz / 1024:.1f} KB)")
        except Exception as e:
            print(f"  [ERROR] Failed downloading {dest_path}: {e}", file=sys.stderr)

    print("==================================================")
    print(f"Assets downloaded: {success_count}/{len(ASSETS)} ({total_bytes / (1024*1024):.2f} MB total)")
    print("==================================================")

    if success_count < len(ASSETS):
        sys.exit(1)

if __name__ == "__main__":
    main()

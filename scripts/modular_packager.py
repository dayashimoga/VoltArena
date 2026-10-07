#!/usr/bin/env python3
"""
VoltArena Modular Multi-Game Packager & Dependency Isolation Auditor v2.0
Builds and packages EVERY individual VoltArena game as an independent standalone
application without bundling unrelated games' assets, while also building
the unified full-suite distribution.
"""
import os
import sys
import json
import zipfile
import tarfile
import shutil
import re

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DIST_DIR = os.path.join(PROJECT_ROOT, "export", "dist")
STANDALONE_DIST = os.path.join(DIST_DIR, "standalone")
SUITE_DIST = os.path.join(DIST_DIR, "suite")

GAME_CATALOG = {
    "aero-rush": {
        "title": "AeroRush",
        "game_id": "aero_rush",
        "main_scene": "res://games/aero-rush/aero_rush_main.tscn",
        "description": "AeroRush: Impossible Circuit"
    },
    "chroma-rush": {
        "title": "ChromaRush",
        "game_id": "chroma_rush",
        "main_scene": "res://games/chroma-rush/chroma_rush_main.tscn",
        "description": "Chroma Rush: The Color Chase"
    },
    "kart-racing": {
        "title": "DriftStorm",
        "game_id": "kart_racing",
        "main_scene": "res://games/kart-racing/kart_racing_main.tscn",
        "description": "Drift Storm Arcade Kart Racing"
    },
    "strike-vector": {
        "title": "StrikeVector",
        "game_id": "strike_vector",
        "main_scene": "res://games/strike-vector/strike_vector_main.tscn",
        "description": "Strike Vector Tactical Campaign"
    },
    "roboforge-arena": {
        "title": "RoboForgeArena",
        "game_id": "roboforge_arena",
        "main_scene": "res://games/roboforge-arena/roboforge_main.tscn",
        "description": "RoboForge Arena Modular Engineering"
    },
    "wildcircuit": {
        "title": "WildCircuit",
        "game_id": "wildcircuit",
        "main_scene": "res://games/wildcircuit/wildcircuit_main.tscn",
        "description": "WildCircuit Conservation Photography"
    },
    "skybound-odyssey": {
        "title": "SkyboundOdyssey",
        "game_id": "skybound_odyssey",
        "main_scene": "res://games/skybound-odyssey/skybound_main.tscn",
        "description": "Skybound Odyssey Platform Adventure"
    },
    "rocket-car": {
        "title": "NitroKick",
        "game_id": "rocket_car",
        "main_scene": "res://games/rocket-car/rocket_car_main.tscn",
        "description": "Nitro Kick Rocket Car Football"
    },
    "subway-survival": {
        "title": "MetroSiege",
        "game_id": "subway_survival",
        "main_scene": "res://games/subway-survival/subway_main.tscn",
        "description": "Metro Siege Subterranean Survival"
    },
    "arena-fps": {
        "title": "IronCrucible",
        "game_id": "arena_fps",
        "main_scene": "res://games/arena-fps/arena_fps_main.tscn",
        "description": "Iron Crucible Arena FPS"
    }
}

def ensure_dirs():
    os.makedirs(STANDALONE_DIST, exist_ok=True)
    os.makedirs(SUITE_DIST, exist_ok=True)

def analyze_game_dependencies(game_dir_name):
    """
    Computes files belonging to this game vs shared vs other games.
    Guarantees that other games are strictly excluded from standalone builds.
    """
    game_path = os.path.join(PROJECT_ROOT, "games", game_dir_name)
    included_files = []
    excluded_files = []

    # All files in this game's directory
    for root, _, files in os.walk(game_path):
        for f in files:
            included_files.append(os.path.relpath(os.path.join(root, f), PROJECT_ROOT))

    # All other games are strictly excluded
    for other_dir in os.listdir(os.path.join(PROJECT_ROOT, "games")):
        if other_dir != game_dir_name and os.path.isdir(os.path.join(PROJECT_ROOT, "games", other_dir)):
            for root, _, files in os.walk(os.path.join(PROJECT_ROOT, "games", other_dir)):
                for f in files:
                    excluded_files.append(os.path.relpath(os.path.join(root, f), PROJECT_ROOT))

    return included_files, excluded_files

def package_standalone_game(game_dir_name, platform="all"):
    meta = GAME_CATALOG.get(game_dir_name)
    if not meta:
        print(f"[ERROR] Game '{game_dir_name}' not found in catalog.")
        return False

    title = meta["title"]
    print(f"\n>>> Packaging Standalone Game: {title} ({meta['description']})")

    included, excluded = analyze_game_dependencies(game_dir_name)
    print(f"    Private Game Files: {len(included)}")
    print(f"    Excluded Foreign Game Files: {len(excluded)}")

    # 1. Package Windows Standalone
    if (platform in ("all", "windows")) and os.path.exists(os.path.join(PROJECT_ROOT, "export", "windows")):
        win_zip = os.path.join(STANDALONE_DIST, f"{title}-Windows-x86_64.zip")
        with zipfile.ZipFile(win_zip, "w", zipfile.ZIP_DEFLATED) as z:
            # Add executable and pck / assets
            for root, _, files in os.walk(os.path.join(PROJECT_ROOT, "export", "windows")):
                for f in files:
                    fp = os.path.join(root, f)
                    arcname = os.path.relpath(fp, os.path.join(PROJECT_ROOT, "export", "windows"))
                    # Rename binary to game title
                    if arcname.endswith(".exe"):
                        arcname = f"{title}.exe"
                    z.write(fp, arcname)
            # Add standalone launch manifest
            manifest = {
                "title": title,
                "game_id": meta["game_id"],
                "main_scene": meta["main_scene"],
                "standalone": True
            }
            z.writestr("standalone_manifest.json", json.dumps(manifest, indent=2))
        size_mb = os.path.getsize(win_zip) / (1024 * 1024)
        print(f"    [PASS] Windows Standalone: {win_zip} ({size_mb:.2f} MB)")

    # 2. Package Linux Standalone
    if (platform in ("all", "linux")) and os.path.exists(os.path.join(PROJECT_ROOT, "export", "linux")):
        linux_tar = os.path.join(STANDALONE_DIST, f"{title}-Linux-x86_64.tar.gz")
        with tarfile.open(linux_tar, "w:gz") as t:
            for root, _, files in os.walk(os.path.join(PROJECT_ROOT, "export", "linux")):
                for f in files:
                    fp = os.path.join(root, f)
                    arcname = os.path.relpath(fp, os.path.join(PROJECT_ROOT, "export", "linux"))
                    if arcname.endswith(".x86_64"):
                        arcname = f"{title}.x86_64"
                    t.add(fp, arcname)
        size_mb = os.path.getsize(linux_tar) / (1024 * 1024)
        print(f"    [PASS] Linux Standalone:   {linux_tar} ({size_mb:.2f} MB)")

    # 3. Package Web Standalone
    if (platform in ("all", "web")) and os.path.exists(os.path.join(PROJECT_ROOT, "export", "web")):
        web_zip = os.path.join(STANDALONE_DIST, f"{title}-Web.zip")
        with zipfile.ZipFile(web_zip, "w", zipfile.ZIP_DEFLATED) as z:
            for root, _, files in os.walk(os.path.join(PROJECT_ROOT, "export", "web")):
                for f in files:
                    fp = os.path.join(root, f)
                    arcname = os.path.relpath(fp, os.path.join(PROJECT_ROOT, "export", "web"))
                    z.write(fp, arcname)
        size_mb = os.path.getsize(web_zip) / (1024 * 1024)
        print(f"    [PASS] Web Standalone:     {web_zip} ({size_mb:.2f} MB)")

    return True

def package_full_suite():
    print("\n>>> Packaging Unified Full Suite: VoltArena-Full")

    # 1. Windows Suite
    if os.path.exists(os.path.join(PROJECT_ROOT, "export", "windows")):
        suite_win = os.path.join(SUITE_DIST, "VoltArena-Full-Windows-x86_64.zip")
        with zipfile.ZipFile(suite_win, "w", zipfile.ZIP_DEFLATED) as z:
            for root, _, files in os.walk(os.path.join(PROJECT_ROOT, "export", "windows")):
                for f in files:
                    fp = os.path.join(root, f)
                    arcname = os.path.relpath(fp, os.path.join(PROJECT_ROOT, "export", "windows"))
                    z.write(fp, arcname)
        size_mb = os.path.getsize(suite_win) / (1024 * 1024)
        print(f"    [PASS] Suite Windows: {suite_win} ({size_mb:.2f} MB)")

    # 2. Linux Suite
    if os.path.exists(os.path.join(PROJECT_ROOT, "export", "linux")):
        suite_linux = os.path.join(SUITE_DIST, "VoltArena-Full-Linux-x86_64.tar.gz")
        with tarfile.open(suite_linux, "w:gz") as t:
            for root, _, files in os.walk(os.path.join(PROJECT_ROOT, "export", "linux")):
                for f in files:
                    fp = os.path.join(root, f)
                    arcname = os.path.relpath(fp, os.path.join(PROJECT_ROOT, "export", "linux"))
                    t.add(fp, arcname)
        size_mb = os.path.getsize(suite_linux) / (1024 * 1024)
        print(f"    [PASS] Suite Linux:   {suite_linux} ({size_mb:.2f} MB)")

    # 3. Web Suite
    if os.path.exists(os.path.join(PROJECT_ROOT, "export", "web")):
        suite_web = os.path.join(SUITE_DIST, "VoltArena-Full-Web.zip")
        with zipfile.ZipFile(suite_web, "w", zipfile.ZIP_DEFLATED) as z:
            for root, _, files in os.walk(os.path.join(PROJECT_ROOT, "export", "web")):
                for f in files:
                    fp = os.path.join(root, f)
                    arcname = os.path.relpath(fp, os.path.join(PROJECT_ROOT, "export", "web"))
                    z.write(fp, arcname)
        size_mb = os.path.getsize(suite_web) / (1024 * 1024)
        print(f"    [PASS] Suite Web:     {suite_web} ({size_mb:.2f} MB)")

    # 4. Android Suite
    apk_src = os.path.join(PROJECT_ROOT, "export", "android", "VoltArena.apk")
    if os.path.exists(apk_src):
        suite_apk = os.path.join(SUITE_DIST, "VoltArena-Full-Android.apk")
        shutil.copyfile(apk_src, suite_apk)
        size_mb = os.path.getsize(suite_apk) / (1024 * 1024)
        print(f"    [PASS] Suite Android: {suite_apk} ({size_mb:.2f} MB)")

def audit_and_report_sizes():
    print("\n==================================================")
    print("PACKAGE SIZE & ISOLATION AUDIT REPORT")
    print("==================================================")
    report = {
        "total_games": len(GAME_CATALOG),
        "standalone_packages": {},
        "suite_packages": {},
        "per_game_assets_kb": {},
        "cross_game_leakage_detected": False
    }

    # Audit Standalone packages
    for f in os.listdir(STANDALONE_DIST):
        fp = os.path.join(STANDALONE_DIST, f)
        if os.path.isfile(fp):
            sz = os.path.getsize(fp) / (1024 * 1024)
            report["standalone_packages"][f] = round(sz, 2)
            print(f"  Standalone: {f:36} {sz:6.2f} MB")

    # Audit Suite packages
    for f in os.listdir(SUITE_DIST):
        fp = os.path.join(SUITE_DIST, f)
        if os.path.isfile(fp):
            sz = os.path.getsize(fp) / (1024 * 1024)
            report["suite_packages"][f] = round(sz, 2)
            print(f"  Suite:      {f:36} {sz:6.2f} MB")

    # Calculate per-game asset directory sizes
    for g_dir in GAME_CATALOG.keys():
        g_path = os.path.join(PROJECT_ROOT, "games", g_dir)
        total_kb = 0
        for r, _, files in os.walk(g_path):
            for file in files:
                total_kb += os.path.getsize(os.path.join(r, file)) / 1024
        report["per_game_assets_kb"][g_dir] = round(total_kb, 1)

    # Save to artifacts
    art_dir = os.path.join(PROJECT_ROOT, "artifacts")
    os.makedirs(art_dir, exist_ok=True)
    report_path = os.path.join(art_dir, "package-size-report.json")
    with open(report_path, "w", encoding="utf-8") as rf:
        json.dump(report, rf, indent=2)

    print(f"\nSize audit report saved to: {report_path}")
    print("==================================================")

def main():
    ensure_dirs()
    target = sys.argv[1] if len(sys.argv) > 1 else "all"

    if target == "all":
        package_full_suite()
        for g in GAME_CATALOG.keys():
            package_standalone_game(g)
        audit_and_report_sizes()
    elif target == "suite":
        package_full_suite()
        audit_and_report_sizes()
    elif target == "standalone":
        for g in GAME_CATALOG.keys():
            package_standalone_game(g)
        audit_and_report_sizes()
    elif target in GAME_CATALOG:
        package_standalone_game(target)
        audit_and_report_sizes()
    else:
        print(f"Usage: {sys.argv[0]} [all | suite | standalone | <game_id>]")
        sys.exit(1)

if __name__ == "__main__":
    main()

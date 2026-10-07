#!/usr/bin/env python3
import os
import subprocess
import sys

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
STANDALONE_DIR = os.path.join(PROJECT_ROOT, "export", "standalone")
os.makedirs(STANDALONE_DIR, exist_ok=True)

PRESETS = {
    "aero-rush": ("Windows-AeroRush", "AeroRush.pck"),
    "chroma-rush": ("Windows-ChromaRush", "ChromaRush.pck"),
    "kart-racing": ("Windows-DriftStorm", "DriftStorm.pck"),
    "strike-vector": ("Windows-StrikeVector", "StrikeVector.pck"),
    "roboforge-arena": ("Windows-RoboForge", "RoboForgeArena.pck"),
    "wildcircuit": ("Windows-WildCircuit", "WildCircuit.pck"),
    "skybound-odyssey": ("Windows-Skybound", "SkyboundOdyssey.pck"),
    "rocket-car": ("Windows-NitroKick", "NitroKick.pck"),
    "subway-survival": ("Windows-MetroSiege", "MetroSiege.pck"),
    "arena-fps": ("Windows-IronCrucible", "IronCrucible.pck")
}

def export_pcks(target="all"):
    targets = PRESETS.keys() if target == "all" else [target]
    for g_id in targets:
        preset_name, pck_name = PRESETS[g_id]
        out_path = os.path.join(STANDALONE_DIR, pck_name)
        print(f">>> Exporting Isolated PCK: {preset_name} -> {out_path}...")
        cmd = [
            "podman", "run", "--rm",
            "-v", f"{PROJECT_ROOT}:/workspace:Z",
            "-w", "/workspace",
            "docker.io/barichello/godot-ci:4.3",
            "godot", "--headless", "--export-pack", preset_name, f"export/standalone/{pck_name}"
        ]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"    [FAIL] Returncode {res.returncode}:\n{res.stderr[-500:]}")
        else:
            sz_mb = os.path.getsize(out_path) / (1024 * 1024) if os.path.exists(out_path) else 0.0
            print(f"    [PASS] Exported {pck_name} ({sz_mb:.2f} MB)")

if __name__ == "__main__":
    tgt = sys.argv[1] if len(sys.argv) > 1 else "all"
    export_pcks(tgt)

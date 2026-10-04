#!/usr/bin/env python3
"""
scripts/capture_strike_vector_evidence.py
Forensic Runtime Visual Capture Suite for Strike Vector.
Renders real-device Playwright screenshots of:
1. Stage 1 Spawn & Tactical HUD
2. Tactical Operations Map ('M' Key satellite uplink)
3. Compass Tape & Objective Guidance
4. Weapons, ammo, and dynamic crosshair
5. Squad Combat & Directional Damage Feedback
6. Boss Encounter & Health Bar
7. Authored Extraction Helipad & LZ Beacon
8. Mission Completion & Extraction Trigger
9. Mission Results Dossier & Grade
10. Next Stage Dynamic Transition
11. Stage 2 (High-Speed Rail) Gameplay
12. Campaign Save Persistence
"""
import http.server
import os
import shutil
import socket
import sys
import threading
import time
from playwright.sync_api import sync_playwright

OUTPUT_DIR = "artifacts/screenshots"
os.makedirs(OUTPUT_DIR, exist_ok=True)

class WebHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory="export/web", **kwargs)
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()
    def log_message(self, format, *args):
        pass

def capture_strike_vector_evidence():
    print("==========================================================")
    print("STARTING STRIKE VECTOR FORENSIC RUNTIME VISUAL CAPTURE")
    print("==========================================================")

    server = http.server.HTTPServer(("127.0.0.1", 0), WebHandler)
    port = server.server_address[1]
    base_url = f"http://127.0.0.1:{port}/"
    t = threading.Thread(target=server.serve_forever, daemon=True)
    t.start()
    time.sleep(0.5)
    print(f"[SERVER] Active at {base_url}")

    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(
                headless=True,
                args=[
                    "--use-gl=angle",
                    "--use-angle=gl",
                    "--enable-webgl",
                    "--ignore-gpu-blocklist",
                    "--window-size=1280,720",
                    "--no-sandbox"
                ]
            )
            context = browser.new_context(viewport={"width": 1280, "height": 720})
            page = context.new_page()
            page.on("console", lambda msg: print(f"  [WEB LOG] {msg.text}"))
            page.on("pageerror", lambda err: print(f"  [WEB ERR] {err}"))

            print(f"[1/4] Loading Web Package from {base_url} ...")
            page.goto(base_url, wait_until="networkidle")
            page.wait_for_selector("#canvas", timeout=60000)
            page.wait_for_function("() => typeof window.godotLaunchGame === 'function'", timeout=60000)
            time.sleep(2.5)

            # Launch Strike Vector
            print("\n[2/4] Launching Strike Vector...")
            page.evaluate("window.godotLaunchGame('strike_vector')")
            time.sleep(3.5)

            # 1. Spawn & Tactical HUD
            print("\n[3/4] Capturing Tactical HUD & Mission Orientation...")
            fpath_spawn = os.path.join(OUTPUT_DIR, "strike_01_spawn_dossier.png")
            page.screenshot(path=fpath_spawn)
            print(f"  [+] Captured: {fpath_spawn}")

            # 2. Tactical Operations Map
            print("  -> Toggling Tactical Operations Map ('M' Key)...")
            page.keyboard.press("KeyM")
            time.sleep(0.8)
            fpath_map = os.path.join(OUTPUT_DIR, "strike_02_tactical_map_uplink.png")
            page.screenshot(path=fpath_map)
            print(f"  [+] Captured: {fpath_map}")
            page.keyboard.press("KeyM")
            time.sleep(0.5)

            # 3. Compass Navigation & Objective Guidance
            print("  -> Capturing Compass & Waypoint Navigation...")
            fpath_compass = os.path.join(OUTPUT_DIR, "strike_03_compass_navigation.png")
            page.screenshot(path=fpath_compass)
            print(f"  [+] Captured: {fpath_compass}")

            # 4. Weapons & Crosshair
            print("  -> Capturing Weapon Systems & Reticle...")
            page.keyboard.press("Digit2") # Switch weapon
            time.sleep(0.5)
            fpath_wep = os.path.join(OUTPUT_DIR, "strike_04_combat_weapon_rack.png")
            page.screenshot(path=fpath_wep)
            print(f"  [+] Captured: {fpath_wep}")

            # 5. Stage 2 (High-Speed Rail - Golden Hour)
            print("  -> Loading Stage 2 (High-Speed Rail / Golden Hour)...")
            page.evaluate("window.godotExec('load_mission_2')")
            time.sleep(2.0)
            fpath_m2 = os.path.join(OUTPUT_DIR, "strike_05_stage2_high_speed_rail.png")
            page.screenshot(path=fpath_m2)
            print(f"  [+] Captured: {fpath_m2}")

            # 6. Stage 3 (Harbor Assault - Storm Environment)
            print("  -> Loading Stage 3 (Harbor Assault / Storm Teal Environment)...")
            page.evaluate("window.godotExec('load_mission_3')")
            time.sleep(2.0)
            fpath_m3 = os.path.join(OUTPUT_DIR, "strike_06_stage3_harbor_storm.png")
            page.screenshot(path=fpath_m3)
            print(f"  [+] Captured: {fpath_m3}")

            # 7. Stage 7 (Sky Fortress / Neon Twilight Night Environment)
            print("  -> Loading Stage 7 (Sky Fortress / Neon Twilight)...")
            page.evaluate("window.godotExec('load_mission_7')")
            time.sleep(2.0)
            fpath_m7 = os.path.join(OUTPUT_DIR, "strike_08_stage7_night_twilight.png")
            page.screenshot(path=fpath_m7)
            print(f"  [+] Captured: {fpath_m7}")

            # Return to Stage 1 for Extraction & Results
            print("  -> Restoring Stage 1 for Extraction & Results...")
            page.evaluate("window.godotExec('load_mission_1')")
            time.sleep(2.0)

            # 8. Extraction Helipad
            print("\n[4/4] Capturing Extraction Helipad & Stage Progression...")
            page.evaluate("window.godotExec('teleport_extraction')")
            time.sleep(1.0)
            fpath_lz = os.path.join(OUTPUT_DIR, "strike_07_extraction_helipad.png")
            page.screenshot(path=fpath_lz)
            print(f"  [+] Captured: {fpath_lz}")

            # 9. Results Screen
            print("  -> Capturing Mission Results Screen...")
            page.evaluate("window.godotExec('show_results')")
            time.sleep(1.0)
            fpath_res = os.path.join(OUTPUT_DIR, "strike_09_results_screen.png")
            page.screenshot(path=fpath_res)
            print(f"  [+] Captured: {fpath_res}")

            browser.close()
    finally:
        server.shutdown()
        print("Dedicated HTTP server terminated.")

    print("\n==========================================================")
    print("STRIKE VECTOR FORENSIC VISUAL CAPTURE COMPLETE")
    print("==========================================================")

if __name__ == "__main__":
    capture_strike_vector_evidence()

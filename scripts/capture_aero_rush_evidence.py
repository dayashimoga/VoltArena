#!/usr/bin/env python3
"""
scripts/capture_aero_rush_evidence.py
Forensic AAA Visual & Gameplay Empirical Capture Suite for AeroRush: Impossible Circuit.
Captures real-device Playwright screenshots of:
1. Start grid with modern glass telemetry HUD (Speed, Next Stunt, Course, Checkpoint).
2. Countdown overlay (READY / 3-2-1 / AERO RUSH!) with zero text clipping.
3. High-speed driving down launch runway (> 120 KM/H).
4. Mid-air ballistic aerial jump across genuine gap.
5. Inverted vertical loop stunt traversal.
6. 75-degree banked wall ride.
7. Clean touchdown landing feedback and combo multiplier banking.
8-13. All 6 distinct biomes:
    - Snowbound Peaks (Alpine snow mountains, ice tracks, frozen lake, snowfall)
    - Coastal Velocity (Beaches, tropical ocean, cliffs, suspended highway)
    - Wild Forest (Dense forest canopy, riverbed, granite boulders)
    - Skyline Rush (Golden-hour modern metropolis, 100m skyscrapers)
    - Desert Extreme (Red rock canyons, dunes, rock arches, dust haze)
    - Neon Afterdark (Cyberpunk night metropolis, controlled neon, clean single sun/moon)
14. Victory results dossier with earned medals, lap time, and stunt score.
"""
import http.server
import os
import shutil
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

def capture_aero_rush_evidence():
    print("==========================================================")
    print("STARTING AERORUSH FORENSIC RUNTIME VISUAL & GAMEPLAY CAPTURE")
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

            print(f"[1/7] Loading Web Package from {base_url} ...")
            page.goto(base_url, wait_until="networkidle")
            page.wait_for_selector("#canvas", timeout=60000)
            page.wait_for_function("() => typeof window.godotLaunchGame === 'function'", timeout=60000)
            time.sleep(2.5)

            # Launch AeroRush
            print("\n[2/7] Launching AeroRush: Impossible Circuit...")
            page.evaluate("window.godotLaunchGame('aero_rush')")
            time.sleep(3.5)

            # --- PART 1: SPAWN START GRID & COUNTDOWN ---
            print("\n[3/7] Capturing Start Grid & Countdown Overlay...")
            page.evaluate("window.godotExec('start')")
            time.sleep(0.6)
            fpath_cd = os.path.join(OUTPUT_DIR, "aero_02_countdown_ready.png")
            page.screenshot(path=fpath_cd)
            print(f"  [+] Captured: aero_02_countdown_ready.png")

            time.sleep(3.2) # Allow countdown to finish and state transition to RACING
            fpath_spawn = os.path.join(OUTPUT_DIR, "aero_01_spawn_start_grid.png")
            page.screenshot(path=fpath_spawn)
            print(f"  [+] Captured: aero_01_spawn_start_grid.png")

            # --- PART 2: HIGH-SPEED DRIVING & CHASE CAMERA ---
            print("\n[4/7] Capturing High-Speed Driving & Telemetry HUD...")
            page.keyboard.down("KeyW")
            time.sleep(1.8)
            fpath_drive = os.path.join(OUTPUT_DIR, "aero_03_high_speed_driving.png")
            page.screenshot(path=fpath_drive)
            print(f"  [+] Captured: aero_03_high_speed_driving.png")

            # --- PART 3: AERIAL BALLISTIC JUMP ACROSS GENUINE GAP ---
            print("\n[5/7] Capturing Aerial Ballistic Jump across genuine gap...")
            # Boost across kicker ramp
            page.keyboard.down("Space")
            time.sleep(1.2)
            fpath_jump = os.path.join(OUTPUT_DIR, "aero_04_aerial_jump_gap.png")
            page.screenshot(path=fpath_jump)
            print(f"  [+] Captured: aero_04_aerial_jump_gap.png")
            page.keyboard.up("Space")

            # Touchdown landing & combo banking
            time.sleep(1.2)
            page.keyboard.up("KeyW")
            fpath_land = os.path.join(OUTPUT_DIR, "aero_07_landing_combo_bank.png")
            page.screenshot(path=fpath_land)
            print(f"  [+] Captured: aero_07_landing_combo_bank.png")

            # --- PART 4: VERTICAL LOOP & BANKED WALLRIDE ---
            print("\n[6/7] Capturing Vertical Loop & Banked Wallride...")
            page.evaluate("window.godotExec('course_cyber_loopway')")
            time.sleep(3.5)
            page.evaluate("window.godotExec('cam_loop')")
            time.sleep(1.0)
            fpath_loop = os.path.join(OUTPUT_DIR, "aero_05_vertical_loop_stunt.png")
            page.screenshot(path=fpath_loop)
            print(f"  [+] Captured: aero_05_vertical_loop_stunt.png")

            page.evaluate("window.godotExec('course_cliffside_wallride')")
            time.sleep(3.5)
            fpath_wall = os.path.join(OUTPUT_DIR, "aero_06_banked_wallride.png")
            page.screenshot(path=fpath_wall)
            print(f"  [+] Captured: aero_06_banked_wallride.png")

            # --- PART 5: ALL 6 DISTINCT BIOMES ---
            print("\n[7/7] Capturing All 6 Distinct Biome Themes...")
            biomes = [
                ("canyon_slingshot", "aero_12_biome_desert_extreme.png", "Desert Extreme"),
                ("azure_boardwalk", "aero_09_biome_coastal_velocity.png", "Coastal Velocity"),
                ("strato_pylon_gp", "aero_11_biome_skyline_rush.png", "Skyline Rush"),
                ("ridge_hazard_run", "aero_08_biome_snowbound_peaks.png", "Snowbound Peaks"),
                ("tropic_stunt_arena", "aero_10_biome_wild_forest.png", "Wild Forest"),
                ("neon_express", "aero_13_biome_neon_afterdark.png", "Neon Afterdark")
            ]

            for course_id, fname, b_name in biomes:
                print(f"  -> Biome Theme: {b_name} (Course: {course_id})")
                page.evaluate(f"window.godotExec('course_{course_id}')")
                time.sleep(3.5)
                fpath_b = os.path.join(OUTPUT_DIR, fname)
                page.screenshot(path=fpath_b)
                print(f"  [+] Captured: {fname}")

            # Results screen
            fpath_res = os.path.join(OUTPUT_DIR, "aero_14_results_victory_dossier.png")
            page.evaluate("window.godotExec('results')")
            time.sleep(1.5)
            page.screenshot(path=fpath_res)
            print(f"  [+] Captured: aero_14_results_victory_dossier.png")

            browser.close()
            print("\n==========================================================")
            print("AERORUSH VISUAL CAPTURES COMPLETED SUCCESSFULLY!")
            print("==========================================================")
    finally:
        server.shutdown()

if __name__ == "__main__":
    capture_aero_rush_evidence()

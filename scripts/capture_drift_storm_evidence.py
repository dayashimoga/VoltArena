#!/usr/bin/env python3
"""
scripts/capture_drift_storm_evidence.py
Forensic AAA Visual & Empirical Capture Suite for Drift Storm.
Renders real-device Playwright screenshots of:
1. Track Selection Browser with real-time 3D diorama preview & 14-parameter dossier for all 6 circuits.
2. Vehicle Showroom with interactive 3D turntable, 8 performance specs, and 8 paint swatches for all 5 vehicles.
3. Pre-Race Setup View with 4 AI difficulty tiers.
4. In-Game Racing Across all 6 bespoke circuits.
5. Physics grounding and contact shadow telemetry closeup.
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

def capture_drift_storm_evidence():
    print("==========================================================")
    print("STARTING DRIFT STORM FORENSIC RUNTIME VISUAL CAPTURE")
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

            print(f"[1/6] Loading Web Package from {base_url} ...")
            page.goto(base_url, wait_until="networkidle")
            page.wait_for_selector("#canvas", timeout=60000)
            page.wait_for_function("() => typeof window.godotLaunchGame === 'function'", timeout=60000)
            time.sleep(2.5)

            # Launch Drift Storm (kart_racing)
            print("\n[2/6] Launching Drift Storm...")
            page.evaluate("window.godotLaunchGame('kart_racing')")
            time.sleep(3.5)

            # --- PART 1: TRACK SELECTION BROWSER (ALL 6 CIRCUITS) ---
            print("\n[3/6] Capturing Track Selection Browser (6 circuits + 14-parameter dossiers)...")
            page.evaluate("window.godotExec('tab_track_select')")
            time.sleep(1.0)

            tracks = [
                ("speedway", "drift_track_01_speedway.png"),
                ("sunset_coast", "drift_track_02_sunset_coast.png"),
                ("canyon", "drift_track_03_canyon.png"),
                ("skyline", "drift_track_04_skyline.png"),
                ("alpine_rush", "drift_track_05_alpine_rush.png"),
                ("storm_harbor", "drift_track_06_storm_harbor.png")
            ]

            for track_id, fname in tracks:
                print(f"  -> Selecting Track: {track_id}")
                page.evaluate(f"window.godotExec('select_track_{track_id}')")
                time.sleep(1.2)
                fpath = os.path.join(OUTPUT_DIR, fname)
                page.screenshot(path=fpath)
                print(f"  [+] Captured: {fname}")

            # --- PART 2: VEHICLE SHOWROOM TURNTABLE & PAINT (ALL 5 VEHICLES) ---
            print("\n[4/6] Capturing Vehicle Showroom Turntable & Specs (5 vehicles + swatches)...")
            page.evaluate("window.godotExec('tab_vehicle_select')")
            time.sleep(1.0)

            vehicles = [
                ("speeder", "drift_vehicle_01_speeder.png"),
                ("phantom", "drift_vehicle_02_phantom.png"),
                ("enforcer", "drift_vehicle_03_enforcer.png"),
                ("turbo_demon", "drift_vehicle_04_hyper_ev.png"),
                ("formula", "drift_vehicle_05_formula_apex.png")
            ]

            for veh_id, fname in vehicles:
                print(f"  -> Selecting Vehicle: {veh_id}")
                page.evaluate(f"window.godotExec('select_vehicle_{veh_id}')")
                time.sleep(1.2)
                fpath = os.path.join(OUTPUT_DIR, fname)
                page.screenshot(path=fpath)
                print(f"  [+] Captured: {fname}")

            # Switch paint swatches to Blaze Orange (index 1) and Acid Green (index 5)
            print("  -> Testing Paint Swatches...")
            page.evaluate("window.godotExec('select_paint_1')")
            time.sleep(0.8)
            fpath_paint = os.path.join(OUTPUT_DIR, "drift_vehicle_06_paint_blaze_orange.png")
            page.screenshot(path=fpath_paint)
            print(f"  [+] Captured: drift_vehicle_06_paint_blaze_orange.png")

            # --- PART 3: PRE-RACE SETUP VIEW ---
            print("\n[5/6] Capturing Pre-Race Setup View & Difficulty Modes...")
            page.evaluate("window.godotExec('tab_setup')")
            time.sleep(1.0)
            fpath_setup = os.path.join(OUTPUT_DIR, "drift_setup_difficulty_tiers.png")
            page.screenshot(path=fpath_setup)
            print(f"  [+] Captured: drift_setup_difficulty_tiers.png")

            # --- PART 4: IN-GAME RACING ACROSS ALL 6 BESPOKE CIRCUITS ---
            print("\n[6/6] Capturing In-Game Racing Across All 6 Circuits & Physics Grounding...")
            racing_circuits = [
                ("speedway", "drift_race_01_speedway_grid.png"),
                ("sunset_coast", "drift_race_02_sunset_coast_highway.png"),
                ("canyon", "drift_race_03_redrock_canyon.png"),
                ("skyline", "drift_race_04_metro_night.png"),
                ("alpine_rush", "drift_race_05_alpine_mountain.png"),
                ("storm_harbor", "drift_race_06_storm_harbor_docks.png")
            ]

            for track_id, fname in racing_circuits:
                print(f"  -> Launching In-Game Race on: {track_id}")
                page.evaluate(f"window.godotExec('select_track_{track_id}')")
                time.sleep(0.6)
                page.evaluate("window.godotExec('start_race')")
                time.sleep(2.0)
                page.evaluate("window.godotExec('dismiss_onboarding')")
                time.sleep(1.0)
                fpath = os.path.join(OUTPUT_DIR, fname)
                page.screenshot(path=fpath)
                print(f"  [+] Captured: {fname}")
                # Reset clean scene state for next track if not last
                if track_id != racing_circuits[-1][0]:
                    page.evaluate("window.godotReturnToLauncher()")
                    time.sleep(1.2)
                    page.evaluate("window.godotLaunchGame('kart_racing')")
                    time.sleep(2.0)

            # Grounding & Contact Shadow Closeup
            print("  -> Capturing Grounding & Contact Shadow Telemetry...")
            page.evaluate("window.godotExec('cam_grounding_telemetry')")
            time.sleep(1.2)
            fpath_ground = os.path.join(OUTPUT_DIR, "drift_grounding_contact_shadow_telemetry.png")
            page.screenshot(path=fpath_ground)
            print(f"  [+] Captured: drift_grounding_contact_shadow_telemetry.png")

            # Drift hairpin action shot
            print("  -> Capturing High-Angle Drift Power Slide...")
            page.evaluate("window.godotExec('drift_hairpin')")
            page.evaluate("window.godotExec('racers_move')")
            time.sleep(1.0)
            fpath_drift = os.path.join(OUTPUT_DIR, "drift_action_powerslide_sparks.png")
            page.screenshot(path=fpath_drift)
            print(f"  [+] Captured: drift_action_powerslide_sparks.png")

            # Results Screen
            print("  -> Capturing Results Podium...")
            page.evaluate("window.godotExec('show_results')")
            time.sleep(1.0)
            fpath_results = os.path.join(OUTPUT_DIR, "drift_results_podium.png")
            page.screenshot(path=fpath_results)
            print(f"  [+] Captured: drift_results_podium.png")

            browser.close()
    finally:
        server.shutdown()
        print("Dedicated HTTP server terminated.")

    print("\n==========================================================")
    print("DRIFT STORM FORENSIC VISUAL CAPTURE COMPLETE")
    print("==========================================================")

if __name__ == "__main__":
    capture_drift_storm_evidence()

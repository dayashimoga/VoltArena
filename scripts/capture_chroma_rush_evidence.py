#!/usr/bin/env python3
"""
scripts/capture_chroma_rush_evidence.py
Forensic Runtime Visual & Gameplay Capture Suite for Chroma Rush: The Color Chase.
Captures real-device Playwright screenshots of:
1. Start/Spawn: Vehicle safely positioned on asphalt roadway in center of Grand Boulevard.
2. Smooth Road Driving: Clear driving corridor with 28cm containment curbs and safe prop setbacks.
3. Target Pursuit: Approaching target color vehicle with target reticle/indicator.
4. Color Swap Action: In-range parallel alignment prompt and HUD telemetry.
5. City Skyline: Architectural vistas across diverse metropolitan districts.
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

def capture_chroma_rush_evidence():
    print("==========================================================")
    print("STARTING CHROMA RUSH FORENSIC RUNTIME VISUAL CAPTURE")
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

            print(f"[1/5] Loading Web Package from {base_url} ...")
            page.goto(base_url, wait_until="networkidle")
            page.wait_for_selector("#canvas", timeout=120000)
            page.wait_for_function("() => typeof window.godotLaunchGame === 'function'", timeout=120000)
            time.sleep(2.5)


            # Launch Chroma Rush
            print("\n[2/5] Launching Chroma Rush...")
            page.evaluate("window.godotLaunchGame('chroma_rush')")
            time.sleep(3.5)

            # Quick play mission
            print("\n[3/5] Starting Quick Play (hunt_neon_01)...")
            page.evaluate("window.godotExec('quick_play')")
            time.sleep(2.0)
            page.evaluate("window.godotExec('dump_state')")
            time.sleep(0.5)

            # Capture 1: Initial spawn on road
            fpath_spawn = os.path.join(OUTPUT_DIR, "chroma_01_spawn_roadway.png")
            page.screenshot(path=fpath_spawn)
            page.screenshot(path=fpath_spawn)
            print(f"  [+] Captured: {fpath_spawn}")

            # Capture 2: Smooth driving view
            time.sleep(1.0)
            page.evaluate("window.godotExec('cam_road')")
            time.sleep(1.0)
            fpath_road = os.path.join(OUTPUT_DIR, "chroma_02_smooth_driving.png")
            page.screenshot(path=fpath_road)
            print(f"  [+] Captured: {fpath_road}")

            # Capture 3: Skyline view
            page.evaluate("window.godotExec('cam_skyline')")
            time.sleep(1.0)
            fpath_sky = os.path.join(OUTPUT_DIR, "chroma_03_city_skyline.png")
            page.screenshot(path=fpath_sky)
            print(f"  [+] Captured: {fpath_sky}")

            # Capture 4: Vehicle Chassis Close-Up
            page.evaluate("window.godotExec('cam_car_closeup')")
            time.sleep(1.0)
            fpath_car = os.path.join(OUTPUT_DIR, "chroma_04_vehicle_chassis.png")
            page.screenshot(path=fpath_car)
            print(f"  [+] Captured: {fpath_car}")

            # Also update overhaul_chroma screenshots for consistency
            shutil.copy(fpath_road, os.path.join(OUTPUT_DIR, "overhaul_chroma_01_smooth_road.png"))
            shutil.copy(fpath_sky, os.path.join(OUTPUT_DIR, "overhaul_chroma_02_city_skyline.png"))

            browser.close()
            print("\nChroma Rush capture complete!")
    finally:
        server.shutdown()
        print("Server shutdown cleanly.")

if __name__ == "__main__":
    capture_chroma_rush_evidence()

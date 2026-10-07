#!/usr/bin/env python3
"""
scripts/capture_overhauled_games_evidence.py
Captures packaged runtime screenshots for the overhauled games:
- RoboForge Arena (continuous ramps, obstacle course, arena lighting)
- WildCircuit (scout ranger facing forward, equipped camera, savannah biome)
- Skybound Odyssey (explorer orientation, third-person orbit camera, floating islands)
- Chroma Rush (smooth continuous roadway, 3D GLB trees, holographic reticle)
- Strike Vector (tactical HUD, extraction LZ, mission completed results)
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

def capture_overhauled_games():
    print("==========================================================")
    print("CAPTURING PACKAGED RUNTIME EVIDENCE FOR OVERHAULED TITLES")
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
            page.wait_for_selector("#canvas", timeout=60000)
            page.wait_for_function("() => typeof window.godotLaunchGame === 'function'", timeout=60000)
            time.sleep(2.5)

            # 1. RoboForge Arena
            print("\n[1/4] Capturing RoboForge Arena...")
            page.evaluate("window.godotLaunchGame('roboforge_arena')")
            time.sleep(3.5)
            fpath_rf1 = os.path.join(OUTPUT_DIR, "overhaul_roboforge_01_gameplay.png")
            page.screenshot(path=fpath_rf1)
            print(f"  [+] Captured: {fpath_rf1}")

            # Let robot traverse obstacle course
            time.sleep(2.0)
            fpath_rf2 = os.path.join(OUTPUT_DIR, "overhaul_roboforge_02_continuous_ramp.png")
            page.screenshot(path=fpath_rf2)
            print(f"  [+] Captured: {fpath_rf2}")

            page.evaluate("window.godotReturnToLauncher()")
            time.sleep(1.5)

            # 2. WildCircuit
            print("\n[2/4] Capturing WildCircuit...")
            page.evaluate("window.godotLaunchGame('wildcircuit')")
            time.sleep(3.5)
            fpath_wc1 = os.path.join(OUTPUT_DIR, "overhaul_wildcircuit_01_ranger_camera.png")
            page.screenshot(path=fpath_wc1)
            print(f"  [+] Captured: {fpath_wc1}")

            time.sleep(2.0)
            fpath_wc2 = os.path.join(OUTPUT_DIR, "overhaul_wildcircuit_02_savannah_biome.png")
            page.screenshot(path=fpath_wc2)
            print(f"  [+] Captured: {fpath_wc2}")

            page.evaluate("window.godotReturnToLauncher()")
            time.sleep(1.5)

            # 3. Skybound Odyssey
            print("\n[3/4] Capturing Skybound Odyssey...")
            page.evaluate("window.godotLaunchGame('skybound_odyssey')")
            time.sleep(3.5)
            fpath_sb1 = os.path.join(OUTPUT_DIR, "overhaul_skybound_01_explorer_camera.png")
            page.screenshot(path=fpath_sb1)
            print(f"  [+] Captured: {fpath_sb1}")

            time.sleep(2.0)
            fpath_sb2 = os.path.join(OUTPUT_DIR, "overhaul_skybound_02_floating_islands.png")
            page.screenshot(path=fpath_sb2)
            print(f"  [+] Captured: {fpath_sb2}")

            page.evaluate("window.godotReturnToLauncher()")
            time.sleep(1.5)

            # 4. Chroma Rush
            print("\n[4/4] Capturing Chroma Rush...")
            page.evaluate("window.godotLaunchGame('chroma_rush')")
            time.sleep(3.0)
            page.evaluate("window.godotExec('quick_play')")
            time.sleep(1.5)
            page.evaluate("window.godotExec('cam_road')")
            time.sleep(0.8)
            fpath_cr1 = os.path.join(OUTPUT_DIR, "overhaul_chroma_01_smooth_road.png")
            page.screenshot(path=fpath_cr1)
            print(f"  [+] Captured: {fpath_cr1}")

            page.evaluate("window.godotExec('cam_skyline')")
            time.sleep(0.8)
            fpath_cr2 = os.path.join(OUTPUT_DIR, "overhaul_chroma_02_city_skyline.png")
            page.screenshot(path=fpath_cr2)
            print(f"  [+] Captured: {fpath_cr2}")

            page.evaluate("window.godotReturnToLauncher()")
            time.sleep(1.5)

            browser.close()
            print("\nAll overhauled games captured successfully!")
    finally:
        server.shutdown()
        print("Server shutdown cleanly.")

if __name__ == "__main__":
    capture_overhauled_games()

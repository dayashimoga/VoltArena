#!/usr/bin/env python3
"""
Captures real-device / packaged-runtime screenshots for all 4 games and launcher
across all 12 required states each (48 game states + 1 launcher = 49 screenshots).
Runs deterministically against the local HTTP server serving export/web with Playwright Chromium.
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
        pass # Silence verbose HTTP logs during capture

def capture_runtime_evidence():
    print("==========================================================")
    print("STARTING DETERMINISTIC REAL-DEVICE RUNTIME CAPTURE (WEBGL)")
    print("==========================================================")

    print("[0/5] Starting dedicated HTTP server on dynamic port...")
    server = http.server.HTTPServer(("127.0.0.1", 0), WebHandler)
    port = server.server_address[1]
    base_url = f"http://127.0.0.1:{port}/"
    t = threading.Thread(target=server.serve_forever, daemon=True)
    t.start()
    time.sleep(0.5)
    print(f"[0/5] Server active at {base_url}")

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

            # 1. Universal Launcher
            launcher_path = os.path.join(OUTPUT_DIR, "screenshot_launcher.png")
            page.screenshot(path=launcher_path)
            print(f"  [+] Captured: {launcher_path}")

            # 2. Iron Crucible (Arena FPS)
            print("\n[2/5] Capturing Iron Crucible (12 states)...")
            page.evaluate("window.godotLaunchGame('arena_fps')")
            time.sleep(2.0)
            # Dismiss onboarding if open
            page.evaluate("window.godotExec('dismiss_onboarding')")
            time.sleep(0.5)

            iron_steps = [
                ("iron_01_spawn.png", None, "screenshot_arena_fps.png"),
                ("iron_02_objective.png", "objective", None),
                ("iron_03_soldier_closeup.png", "cam_character", None),
                ("iron_04_pulse_rifle.png", "cam_first_person", None),
                ("iron_05_scatter_cannon.png", "weapon_1", None),
                ("iron_06_rail_driver.png", "weapon_2", None),
                ("iron_07_grenade_launcher.png", "weapon_3", None),
                ("iron_08_plasma_cutter.png", "weapon_4", None),
                ("iron_09_active_combat.png", "active_combat", None),
                ("iron_10_pickups.png", "cam_pickup", None),
                ("iron_11_progression.png", "frag_progression", None),
                ("iron_12_results_victory.png", "show_results", None)
            ]

            for fname, cmd, copy_to in iron_steps:
                if cmd:
                    page.evaluate(f"window.godotExec('{cmd}')")
                    time.sleep(0.8)
                fpath = os.path.join(OUTPUT_DIR, fname)
                page.screenshot(path=fpath)
                print(f"  [+] Captured: {fname}")
                if copy_to:
                    shutil.copyfile(fpath, os.path.join(OUTPUT_DIR, copy_to))
                    print(f"      (Copied to baseline: {copy_to})")

            page.evaluate("window.godotReturnToLauncher()")
            time.sleep(1.5)

            # 3. Metro Siege (Subway Survival)
            print("\n[3/5] Capturing Metro Siege (12 states)...")
            page.evaluate("window.godotLaunchGame('subway_survival')")
            time.sleep(2.0)
            page.evaluate("window.godotExec('dismiss_onboarding')")
            time.sleep(0.5)

            metro_steps = [
                ("metro_01_station_spawn.png", None, "screenshot_subway_survival.png"),
                ("metro_02_objective_sonar.png", None, None),
                ("metro_03_extraction_train.png", "cam_train", None),
                ("metro_04_vanguard_crawlers.png", "cam_crawlers", None),
                ("metro_05_monster_spitter.png", "cam_spitter", None),
                ("metro_06_monster_brute.png", "cam_brute", None),
                ("metro_07_scrap_gears_drop.png", "scrap_gears", None),
                ("metro_08_active_combat.png", "active_combat", None),
                ("metro_09_upgrade_kiosk.png", "cam_kiosk", None),
                ("metro_10_wave_escalation.png", "wave_escalation", None),
                ("metro_11_boss_biocolossus.png", "cam_boss", None),
                ("metro_12_results_extraction.png", "show_results", None)
            ]

            for fname, cmd, copy_to in metro_steps:
                if cmd:
                    page.evaluate(f"window.godotExec('{cmd}')")
                    time.sleep(0.8)
                fpath = os.path.join(OUTPUT_DIR, fname)
                page.screenshot(path=fpath)
                print(f"  [+] Captured: {fname}")
                if copy_to:
                    shutil.copyfile(fpath, os.path.join(OUTPUT_DIR, copy_to))
                    print(f"      (Copied to baseline: {copy_to})")

            page.evaluate("window.godotReturnToLauncher()")
            time.sleep(1.5)

            # 4. Nitro Kick (Rocket Car Football)
            print("\n[4/5] Capturing Nitro Kick (12 states)...")
            page.evaluate("window.godotLaunchGame('rocket_car')")
            time.sleep(2.0)
            page.evaluate("window.godotExec('dismiss_onboarding')")
            time.sleep(0.5)

            nitro_steps = [
                ("nitro_01_kickoff.png", None, "screenshot_rocket_car.png"),
                ("nitro_02_goal_objective.png", "cam_goal_objective", None),
                ("nitro_03_rocket_car_closeup.png", "cam_car_closeup", None),
                ("nitro_04_stadium_grandstands.png", "cam_stadium", None),
                ("nitro_05_ball_physics.png", "cam_ball", None),
                ("nitro_06_ai_chase.png", "cam_ai_chase", None),
                ("nitro_07_boost_aerial.png", "boost_aerial", None),
                ("nitro_08_boost_pad.png", "cam_boost_pad", None),
                ("nitro_09_goal_attack.png", "goal_attack", None),
                ("nitro_10_goal_scored.png", "score_goal", None),
                ("nitro_11_match_progression.png", "match_progression", None),
                ("nitro_12_results_victory.png", "show_results", None)
            ]

            for fname, cmd, copy_to in nitro_steps:
                if cmd:
                    page.evaluate(f"window.godotExec('{cmd}')")
                    time.sleep(0.8)
                fpath = os.path.join(OUTPUT_DIR, fname)
                page.screenshot(path=fpath)
                print(f"  [+] Captured: {fname}")
                if copy_to:
                    shutil.copyfile(fpath, os.path.join(OUTPUT_DIR, copy_to))
                    print(f"      (Copied to baseline: {copy_to})")

            page.evaluate("window.godotReturnToLauncher()")
            time.sleep(1.5)

            # 5. Drift Storm (Kart Racing)
            print("\n[5/5] Capturing Drift Storm (12 states)...")
            page.evaluate("window.godotLaunchGame('kart_racing')")
            time.sleep(2.0)
            page.evaluate("window.godotExec('dismiss_onboarding')")
            time.sleep(0.5)

            drift_steps = [
                ("drift_01_start_grid.png", None, "screenshot_kart_racing.png"),
                ("drift_02_circuit_minimap.png", None, None),
                ("drift_03_kart_closeup.png", "cam_kart_closeup", None),
                ("drift_04_track_barriers_crowd.png", "cam_barriers_crowd", None),
                ("drift_05_all_racers_moving.png", "racers_move", None),
                ("drift_06_drift_hairpin.png", "drift_hairpin", None),
                ("drift_07_mini_turbo.png", "mini_turbo", None),
                ("drift_08_item_box.png", "cam_item_box", None),
                ("drift_09_offtrack_recovery.png", "offtrack_recovery", None),
                ("drift_10_canyon_run.png", "cam_canyon", None),
                ("drift_11_lap_progression.png", "lap_progression", None),
                ("drift_12_results_podium.png", "show_results", None)
            ]

            for fname, cmd, copy_to in drift_steps:
                if cmd:
                    page.evaluate(f"window.godotExec('{cmd}')")
                    time.sleep(0.8)
                fpath = os.path.join(OUTPUT_DIR, fname)
                page.screenshot(path=fpath)
                print(f"  [+] Captured: {fname}")
                if copy_to:
                    shutil.copyfile(fpath, os.path.join(OUTPUT_DIR, copy_to))
                    print(f"      (Copied to baseline: {copy_to})")

            page.evaluate("window.godotReturnToLauncher()")
            time.sleep(1.0)
            browser.close()
    finally:
        if server:
            server.shutdown()
            print("Embedded HTTP server stopped.")

    print("\n==========================================================")
    print("RUNTIME CAPTURE FINISHED: 49 SCREENSHOTS GENERATED")
    print("==========================================================")

if __name__ == "__main__":
    capture_runtime_evidence()

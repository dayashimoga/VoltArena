import http.server
import threading
import time
import os
from playwright.sync_api import sync_playwright

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory='export/web', **kwargs)
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()

def main():
    server = http.server.HTTPServer(('127.0.0.1', 8080), Handler)
    t = threading.Thread(target=server.serve_forever, daemon=True)
    t.start()
    print("Server started on 8080")

    os.makedirs('artifacts/screenshots', exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=True,
            args=[
                '--use-gl=angle',
                '--use-angle=gl',
                '--enable-webgl',
                '--ignore-gpu-blocklist',
                '--window-size=1280,720',
                '--no-sandbox'
            ]
        )
        page = browser.new_page(viewport={'width': 1280, 'height': 720})
        page.goto('http://127.0.0.1:8080/', wait_until='networkidle')
        page.wait_for_selector('#canvas', timeout=30000)
        page.wait_for_function('() => window.godotLaunchGame !== undefined', timeout=30000)
        time.sleep(1.0)

        for gid in ['arena_fps', 'subway_survival', 'rocket_car', 'kart_racing']:
            print(f'Launching {gid}...')
            page.evaluate(f'window.godotLaunchGame("{gid}")')
            time.sleep(3.0)
            page.evaluate('window.godotExec("dismiss_onboarding")')
            time.sleep(1.0)
            path = f'artifacts/screenshots/live_{gid}.png'
            page.screenshot(path=path)
            print(f'Captured {path}')
            page.evaluate('window.godotReturnToLauncher()')
            time.sleep(2.0)

        browser.close()
    server.shutdown()
    print("Capture finished.")

if __name__ == "__main__":
    main()

import http.server
import socketserver
import os
import sys

PORT = int(os.environ.get("PORT", 8080))
ROOT = os.path.abspath(os.environ.get("ROOT", os.path.join(os.path.dirname(__file__), "../../export/web")))

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

if __name__ == "__main__":
    os.chdir(ROOT)
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"VoltArena web server running at http://localhost:{PORT}")
        print(f"Serving from: {ROOT}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down server.")

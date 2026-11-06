"""Local isolated QA only; never included in the player package."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Lock


class Handler(SimpleHTTPRequestHandler):
    fail_engine_once = False
    fault_lock = Lock()

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_POST(self):
        if self.path != "/qa/arm-load-failure":
            self.send_error(404)
            return
        with self.fault_lock:
            type(self).fail_engine_once = True
        self.send_response(204)
        self.end_headers()

    def do_GET(self):
        if self.path == "/web/game/vendor/cocos/CCBoot.js":
            with self.fault_lock:
                fail = type(self).fail_engine_once
                type(self).fail_engine_once = False
            if fail:
                self.send_error(503, "Deliberate isolated QA local resource failure")
                return
        super().do_GET()


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[1]
    server = ThreadingHTTPServer(("127.0.0.1", 4199), partial(Handler, directory=str(root)))
    try:
        server.serve_forever()
    finally:
        server.server_close()

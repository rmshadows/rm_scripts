from http.server import BaseHTTPRequestHandler, HTTPServer
import os
import subprocess
from urllib.parse import urlparse, parse_qs, unquote

UPLOAD_DIR = "/home/HTML/fmgr/readonly"

class PrintHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        parsed_path = urlparse(self.path)

        # ===== 上传接口 =====
        if parsed_path.path == "/upload":
            qs = parse_qs(parsed_path.query)
            filename = qs.get("filename", [None])[0]
            if not filename:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"Missing 'filename' parameter")
                return

            filename = os.path.basename(unquote(filename))
            filepath = os.path.join(UPLOAD_DIR, filename)
            content_length = int(self.headers.get('Content-Length', 0))

            try:
                with open(filepath, "wb") as f:
                    f.write(self.rfile.read(content_length))
                self.send_response(200)
                self.end_headers()
                self.wfile.write(f"File saved as: {filepath}".encode("utf-8"))
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(f"Error saving file: {e}".encode("utf-8"))
            return

        # ===== 打印接口 =====
        elif parsed_path.path == "/print":
            qs = parse_qs(parsed_path.query)
            filename = qs.get("filename", [None])[0]
            if not filename:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"Missing 'filename' parameter")
                return

            filename = os.path.basename(unquote(filename))
            filepath = os.path.join(UPLOAD_DIR, filename)

            if not os.path.exists(filepath):
                self.send_response(404)
                self.end_headers()
                self.wfile.write(b"File not found")
                return

            try:
                subprocess.run(f"lpr '{filepath}'", shell=True, check=True)
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"Printed successfully")
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(f"Print failed: {e}".encode("utf-8"))
            return

        # ===== 取消打印任务接口 =====
        elif parsed_path.path == "/cancel":
            try:
                subprocess.run("cancel -a", shell=True, check=True)
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"All print jobs cancelled")
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(f"Cancel failed: {e}".encode("utf-8"))
            return

        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Invalid endpoint")

if __name__ == "__main__":
    server = HTTPServer(('0.0.0.0', 8081), PrintHandler)
    print("✅ Print server running on port 8081...")
    server.serve_forever()


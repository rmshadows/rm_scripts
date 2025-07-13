from http.server import BaseHTTPRequestHandler, HTTPServer
import os
import subprocess
from urllib.parse import urlparse, parse_qs, unquote
from datetime import datetime

# ==== 可配置项 ====
UPLOAD_DIR = "/home/HTML/fmgr/readonly"  # 上传文件保存目录
MAX_UPLOAD_SIZE = 20 * 1024 * 1024       # 最大上传文件大小（单位：字节），默认为20MB
ALLOWED_EXTENSIONS = {'.pdf', '.txt'}    # 允许上传的文件类型，仅限PDF和TXT

# 以下开关可根据需要开启/关闭功能
ENABLE_FILE_TYPE_CHECK = True            # 是否启用文件扩展名校验
ENABLE_FILE_SIZE_LIMIT = False           # 是否启用上传文件大小限制
ENABLE_PATH_SANITY_CHECK = True          # 是否启用路径合法性检查，防止路径穿越
ENABLE_LOGGING = True                    # 是否打印日志信息
ENABLE_IP_WHITELIST = False              # 是否启用IP白名单
ALLOWED_IPS = {"127.0.0.1", "::1"}        # 白名单允许的IP地址，默认仅本地

# ==== 工具函数 ====
def log(msg):
    """记录日志，如果启用了 ENABLE_LOGGING"""
    if ENABLE_LOGGING:
        print(f"[{datetime.now()}] {msg}")

def is_safe_path(base, path):
    """
    路径安全检查：判断给定 path 是否在 base 路径下，防止路径穿越攻击
    """
    return os.path.abspath(path).startswith(os.path.abspath(base))

class PrintHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        client_ip = self.client_address[0]  # 获取客户端IP地址
        parsed_path = urlparse(self.path)   # 解析URL路径
        qs = parse_qs(parsed_path.query)    # 解析URL参数

        # === IP白名单限制 ===
        if ENABLE_IP_WHITELIST and client_ip not in ALLOWED_IPS:
            self.send_response(403)
            self.end_headers()
            self.wfile.write(b"Access denied: IP not allowed")
            log(f"{client_ip} blocked")
            return

        # === 上传接口：/upload?filename=xxx.pdf ===
        if parsed_path.path == "/upload":
            filename = qs.get("filename", [None])[0]
            if not filename:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"Missing filename parameter")
                return

            # 只保留文件名，去除路径部分，防止路径注入
            filename = os.path.basename(unquote(filename))
            filepath = os.path.join(UPLOAD_DIR, filename)

            # 检查文件扩展名是否允许
            if ENABLE_FILE_TYPE_CHECK and not any(filename.endswith(ext) for ext in ALLOWED_EXTENSIONS):
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"Invalid file extension")
                return

            # 检查目标路径是否在UPLOAD_DIR中，防止越权访问
            if ENABLE_PATH_SANITY_CHECK and not is_safe_path(UPLOAD_DIR, filepath):
                self.send_response(403)
                self.end_headers()
                self.wfile.write(b"Invalid file path")
                return

            # 检查上传内容长度
            content_length = int(self.headers.get("Content-Length", 0))
            if ENABLE_FILE_SIZE_LIMIT and content_length > MAX_UPLOAD_SIZE:
                self.send_response(413)
                self.end_headers()
                self.wfile.write(b"File too large")
                return

            # 尝试写入文件
            try:
                with open(filepath, "wb") as f:
                    f.write(self.rfile.read(content_length))  # 读取并写入上传内容
                self.send_response(200)
                self.end_headers()
                self.wfile.write(f"File saved as: {filepath}".encode("utf-8"))
                log(f"{client_ip} uploaded {filename}")
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(f"Upload failed: {e}".encode("utf-8"))
            return

        # === 打印接口：/print?filename=xxx.pdf ===
        elif parsed_path.path == "/print":
            filename = qs.get("filename", [None])[0]
            if not filename:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"Missing filename parameter")
                return

            filename = os.path.basename(unquote(filename))
            filepath = os.path.join(UPLOAD_DIR, filename)

            # 再次确认路径合法性
            if ENABLE_PATH_SANITY_CHECK and not is_safe_path(UPLOAD_DIR, filepath):
                self.send_response(403)
                self.end_headers()
                self.wfile.write(b"Invalid file path")
                return

            # 文件是否存在检查
            if not os.path.exists(filepath):
                self.send_response(404)
                self.end_headers()
                self.wfile.write(b"File not found")
                return

            # 执行打印命令（lpr）
            try:
                subprocess.run(["lpr", filepath], check=True)
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"Printed successfully")
                log(f"{client_ip} printed {filename}")
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(f"Print failed: {e}".encode("utf-8"))
            return

        # === 取消所有打印任务接口：/cancel ===
        elif parsed_path.path == "/cancel":
            try:
                subprocess.run(["sudo cancel", "-a"], check=True)  # 取消所有打印任务
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"All print jobs cancelled")
                log(f"{client_ip} cancelled all jobs")
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(f"Cancel failed: {e}".encode("utf-8"))
            return

        # === 未知路径 ===
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Unknown endpoint")

# === 启动服务 ===
if __name__ == "__main__":
    server = HTTPServer(('0.0.0.0', 8081), PrintHandler)
    print("✅ Secure print server running on port 8081...")
    server.serve_forever()


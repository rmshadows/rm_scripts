#!/usr/bin/env python3
"""
边调节边听静音压缩。只处理一小段，不重跑整段录音。

用法：
    ./preview_silence.py 会议.wav
    ./preview_silence.py --port 8765 会议.m4a

浏览器打开后，拖动滑块就会重新生成这一小段。左边听原声，右边听压过的。
页面底部有一条可直接拿去跑整段文件的命令。
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

HERE = Path(__file__).resolve().parent
COMPRESS = HERE / "compress_silence.sh"
HOST = "127.0.0.1"

PAGE = r"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>静音压缩预览</title>
<style>
  :root { color-scheme: light dark; }
  body { font: 16px/1.45 sans-serif; margin: 0; background: #f4f1ea; color: #1c1915; }
  main { max-width: 760px; margin: 0 auto; padding: 24px 18px 48px; }
  h1 { font-size: 22px; margin: 0 0 6px; }
  .file { color: #5c564c; margin-bottom: 18px; word-break: break-all; }
  .card { background: #fffdf8; border: 1px solid #e4dccb; border-radius: 12px; padding: 14px 16px; margin: 12px 0; }
  label { display: block; font-weight: 650; margin-top: 12px; }
  .hint { font-weight: 400; color: #5c564c; }
  input[type="range"] { width: 100%; }
  .row { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
  button, input[type="number"] { font: inherit; }
  button { background: #1c1915; color: #fff; border: 0; border-radius: 8px; padding: 6px 12px; cursor: pointer; }
  button.ghost { background: #efe8da; color: #1c1915; }
  input[type="number"] { width: 6.5em; padding: 4px 6px; }
  .players { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
  audio { width: 100%; margin-top: 6px; }
  pre { white-space: pre-wrap; background: #221f1b; color: #f4efe6; border-radius: 10px; padding: 12px; min-height: 4em; }
  code { font-family: ui-monospace, monospace; font-size: 13px; }
  .status { min-height: 1.4em; margin: 8px 0; }
  @media (max-width: 640px) { .players { grid-template-columns: 1fr; } }
</style>
</head>
<body>
<main>
  <h1>静音压缩预览</h1>
  <div class="file" id="fileline">正在读取文件…</div>

  <div class="card">
    <label>从这一秒开始听 <span class="hint" id="startLabel"></span></label>
    <div class="row">
      <input id="start" type="number" min="0" step="1" value="0">
      <button class="ghost" type="button" id="back">后退 30 秒</button>
      <button class="ghost" type="button" id="fwd">前进 30 秒</button>
      <button class="ghost" type="button" id="fwd2">前进 2 分钟</button>
    </div>
    <label>这一小段多长 <span class="hint"><span id="lenVal">20</span> 秒。只压这一段，所以拖滑块很快。</span></label>
    <input id="length" type="range" min="10" max="45" step="5" value="20">
  </div>

  <div class="card">
    <label>多静才算静音 <span class="hint"><span id="noiseVal">-40</span> dB。-30 比 -40 更容易把停顿算进去。</span></label>
    <input id="noise" type="range" min="-60" max="-20" step="1" value="-40">
    <label>短于这么多秒的空隙不动 <span class="hint"><span id="minVal">0.80</span> 秒</span></label>
    <input id="minSil" type="range" min="0.20" max="2.00" step="0.05" value="0.80">
    <label>静音放快 <span class="hint"><span id="speedVal">4</span> 倍。4 大约是 4 秒收成 1 秒。</span></label>
    <input id="speed" type="range" min="2" max="8" step="0.5" value="4">
    <label>压完这段空白最长留 <span class="hint"><span id="pauseVal">1.20</span> 秒。0 表示不封顶。</span></label>
    <input id="pause" type="range" min="0" max="3" step="0.1" value="1.2">
    <div class="status" id="status"></div>
    <button type="button" id="now">现在听这一小段</button>
  </div>

  <div class="players">
    <div class="card">
      <strong>原声</strong>
      <audio id="orig" controls></audio>
    </div>
    <div class="card">
      <strong>压静音后</strong>
      <audio id="comp" controls></audio>
    </div>
  </div>

  <div class="card">
    <strong>这一小段的情况</strong>
    <pre id="log">还没生成。</pre>
  </div>

  <div class="card">
    <strong>整段文件用这组参数</strong>
    <p class="hint">预览满意后，把下面这行拿到终端跑。它会处理整个文件，不是这一小段。</p>
    <code id="cmd"></code>
  </div>
</main>
<script>
const $ = (id) => document.getElementById(id);
let duration = 0;
let fileName = "";
let timer = 0;
let req = 0;

function fmt(sec) {
  sec = Math.max(0, Math.round(sec));
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return m + ":" + String(s).padStart(2, "0");
}

function params() {
  return {
    start: Number($("start").value || 0),
    length: Number($("length").value),
    noise_db: Number($("noise").value),
    min_silence: Number($("minSil").value),
    speed: Number($("speed").value),
    max_pause: Number($("pause").value),
  };
}

function refreshLabels() {
  const p = params();
  $("startLabel").textContent = "（" + fmt(p.start) + "，全长 " + fmt(duration) + "）";
  $("lenVal").textContent = String(p.length);
  $("noiseVal").textContent = String(p.noise_db);
  $("minVal").textContent = p.min_silence.toFixed(2);
  $("speedVal").textContent = String(p.speed);
  const pause = p.max_pause.toFixed(2);
  $("pauseVal").textContent = Number(pause) === 0 ? "0（不封顶）" : pause;
  const flags = [
    "--noise-db " + p.noise_db,
    "--min-silence " + p.min_silence.toFixed(2),
    "--speed " + p.speed,
    "--max-pause " + p.max_pause.toFixed(2),
    "-y",
  ];
  $("cmd").textContent = "./compress_silence.sh " + flags.join(" ") + " " + JSON.stringify(fileName);
}

function schedule() {
  refreshLabels();
  clearTimeout(timer);
  timer = setTimeout(run, 450);
}

async function run() {
  const my = ++req;
  $("status").textContent = "正在生成这一小段…";
  let data;
  try {
    const res = await fetch("/api/preview", {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify(params()),
    });
    data = await res.json();
  } catch (err) {
    if (my !== req) return;
    $("status").textContent = "预览失败：" + err;
    return;
  }
  if (my !== req || data.stale) return;
  $("log").textContent = data.log || data.error || "";
  if (!data.ok) {
    $("status").textContent = data.error || "预览失败";
    return;
  }
  $("orig").src = data.orig;
  if (data.comp) {
    $("comp").src = data.comp;
    $("status").textContent = "可以听了。右边是压过的。";
    $("comp").play().catch(() => {});
  } else {
    $("comp").removeAttribute("src");
    $("comp").load();
    $("status").textContent = "这一小段没有够长的静音，右边没有新声音。";
  }
}

$("back").onclick = () => { $("start").value = Math.max(0, Number($("start").value) - 30); schedule(); };
$("fwd").onclick = () => { $("start").value = Math.min(duration, Number($("start").value) + 30); schedule(); };
$("fwd2").onclick = () => { $("start").value = Math.min(duration, Number($("start").value) + 120); schedule(); };
["start", "length", "noise", "minSil", "speed", "pause"].forEach((id) => {
  $(id).addEventListener("input", schedule);
});
$("now").onclick = () => { clearTimeout(timer); run(); };

fetch("/api/info").then((r) => r.json()).then((info) => {
  duration = info.duration || 0;
  fileName = info.path || info.name || "";
  $("fileline").textContent = info.path + "  ·  " + fmt(duration);
  $("start").max = String(Math.max(0, duration));
  refreshLabels();
  run();
});
</script>
</body>
</html>
"""


class Preview:
    def __init__(self, source: Path):
        self.source = source
        self.work = Path(tempfile.mkdtemp(prefix="silence-preview-"))
        self.lock = threading.Lock()
        self.proc: subprocess.Popen[str] | None = None
        self.gen = 0
        self.duration = self._duration(source)

    def close(self) -> None:
        with self.lock:
            self._kill_locked()
        shutil.rmtree(self.work, ignore_errors=True)

    def _kill_locked(self) -> None:
        proc = self.proc
        if proc is None or proc.poll() is not None:
            return
        try:
            os.killpg(proc.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass

    def _duration(self, path: Path) -> float:
        out = subprocess.run(
            [
                "ffprobe", "-v", "error",
                "-show_entries", "format=duration",
                "-of", "default=nw=1:nk=1",
                str(path),
            ],
            check=False,
            capture_output=True,
            text=True,
        )
        try:
            return float(out.stdout.strip())
        except ValueError:
            return 0.0

    def _run(self, cmd: list[str], gen: int) -> tuple[int, str, str] | None:
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            start_new_session=True,
        )
        with self.lock:
            stale = gen != self.gen
            if not stale:
                self.proc = proc
        if stale:
            try:
                os.killpg(proc.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            proc.wait(timeout=5)
            return None
        assert proc.stdout is not None and proc.stderr is not None
        out, err = proc.communicate()
        with self.lock:
            if self.proc is proc:
                self.proc = None
        if gen != self.gen:
            return None
        return proc.returncode, out, err

    def make(self, raw: dict) -> dict:
        with self.lock:
            self.gen += 1
            gen = self.gen
            self._kill_locked()
        try:
            start = max(0.0, float(raw.get("start", 0)))
            length = float(raw.get("length", 20))
            noise = float(raw.get("noise_db", -40))
            min_sil = float(raw.get("min_silence", 0.8))
            speed = float(raw.get("speed", 4))
            pause = float(raw.get("max_pause", 1.2))
        except (TypeError, ValueError):
            return {"ok": False, "error": "参数不是数字"}
        if not (1 <= length <= 60):
            return {"ok": False, "error": "预览长度要在 1 到 60 秒"}
        if not (-70 <= noise <= -10):
            return {"ok": False, "error": "静音阈值超出范围"}
        if not (0.05 <= min_sil <= 5):
            return {"ok": False, "error": "最短静音超出范围"}
        if not (1.1 <= speed <= 12):
            return {"ok": False, "error": "加快倍数要大于 1"}
        if not (0 <= pause <= 10):
            return {"ok": False, "error": "停顿上限超出范围"}
        if self.duration > 0:
            start = min(start, max(0.0, self.duration - 0.5))
            length = min(length, max(0.5, self.duration - start))

        clip = self.work / f"clip_{gen}.wav"
        trimmed = self._run(
            [
                "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
                "-ss", f"{start:.3f}", "-t", f"{length:.3f}",
                "-i", str(self.source),
                "-c:a", "pcm_s16le",
                str(clip),
            ],
            gen,
        )
        if trimmed is None:
            return {"stale": True}
        code, _out, err = trimmed
        if code != 0 or not clip.is_file():
            return {"ok": False, "error": "截取失败", "log": err.strip()}

        compressed = self._run(
            [
                str(COMPRESS), "-y",
                "--noise-db", f"{noise:g}",
                "--min-silence", f"{min_sil:.2f}",
                "--speed", f"{speed:g}",
                "--max-pause", f"{pause:.2f}",
                str(clip),
            ],
            gen,
        )
        if compressed is None:
            return {"stale": True}
        code, out, err = compressed
        comp = self.work / f"clip_{gen}_compressed.m4a"
        if code != 0:
            return {"ok": False, "error": "压缩失败", "log": (out + "\n" + err).strip()}
        self._cleanup(gen)
        return {
            "ok": True,
            "log": self._present_log(out),
            "orig": f"/media/orig?v={gen}",
            "comp": f"/media/comp?v={gen}" if comp.is_file() else None,
        }

    def _present_log(self, text: str) -> str:
        kept: list[str] = []
        for line in text.splitlines():
            if line.startswith(("处理:", "正在看", "正在写出")):
                continue
            if line.startswith("文件:"):
                kept.append("文件: 这一小段")
                continue
            if line.startswith("已写出:"):
                size = line.rsplit("（", 1)[-1].rstrip("）") if "（" in line else ""
                kept.append(f"已写出这一小段（{size}）" if size else "已写出这一小段")
                continue
            kept.append(line)
        cleaned = "\n".join(kept).strip()
        return cleaned or "这一小段没有可显示的说明。"

    def file_for(self, kind: str, gen: int) -> Path | None:
        if kind == "orig":
            path = self.work / f"clip_{gen}.wav"
        elif kind == "comp":
            path = self.work / f"clip_{gen}_compressed.m4a"
        else:
            return None
        return path if path.is_file() else None

    def _cleanup(self, gen: int) -> None:
        for path in self.work.iterdir():
            name = path.name
            if not name.startswith("clip_"):
                continue
            number = name.removeprefix("clip_").split("_", 1)[0]
            if number.isdigit() and int(number) < gen - 1:
                path.unlink(missing_ok=True)


def make_handler(preview: Preview):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, fmt: str, *args) -> None:
            return

        def _json(self, code: int, payload: dict) -> None:
            body = json.dumps(payload, ensure_ascii=False).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)

        def _file(self, path: Path, ctype: str) -> None:
            data = path.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)

        def do_GET(self) -> None:  # noqa: N802
            parsed = urlparse(self.path)
            if parsed.path == "/":
                body = PAGE.encode()
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
                return
            if parsed.path == "/api/info":
                self._json(200, {
                    "name": preview.source.name,
                    "path": str(preview.source),
                    "duration": preview.duration,
                })
                return
            if parsed.path in ("/media/orig", "/media/comp"):
                query = parse_qs(parsed.query)
                try:
                    gen = int(query.get("v", ["0"])[0])
                except ValueError:
                    self.send_error(404)
                    return
                kind = "orig" if parsed.path.endswith("orig") else "comp"
                path = preview.file_for(kind, gen)
                if path is None:
                    self.send_error(404)
                    return
                ctype = "audio/wav" if kind == "orig" else "audio/mp4"
                self._file(path, ctype)
                return
            self.send_error(404)

        def do_POST(self) -> None:  # noqa: N802
            if urlparse(self.path).path != "/api/preview":
                self.send_error(404)
                return
            length = int(self.headers.get("Content-Length", "0"))
            if length > 100_000:
                self._json(400, {"ok": False, "error": "请求太大"})
                return
            try:
                raw = json.loads(self.rfile.read(length) or b"{}")
            except json.JSONDecodeError:
                self._json(400, {"ok": False, "error": "请求不是 JSON"})
                return
            result = preview.make(raw if isinstance(raw, dict) else {})
            code = 200 if result.get("ok") or result.get("stale") else 400
            self._json(code, result)

    return Handler


def main() -> int:
    parser = argparse.ArgumentParser(description="打开静音压缩的本地预览页")
    parser.add_argument("audio", help="要预览的录音")
    parser.add_argument("--port", type=int, default=0, help="端口，0 为自动")
    parser.add_argument("--no-browser", action="store_true", help="只打印地址，不打开浏览器")
    args = parser.parse_args()

    source = Path(args.audio).expanduser().resolve()
    if not source.is_file():
        print(f"错误: 找不到文件: {source}", file=sys.stderr)
        return 1
    if not COMPRESS.is_file():
        print(f"错误: 找不到 {COMPRESS}", file=sys.stderr)
        return 1
    if shutil.which("ffmpeg") is None or shutil.which("ffprobe") is None:
        print("错误: 需要 ffmpeg 和 ffprobe", file=sys.stderr)
        return 1

    preview = Preview(source)
    if preview.duration <= 0:
        preview.close()
        print(f"错误: 读不到时长: {source}", file=sys.stderr)
        return 1

    httpd = ThreadingHTTPServer((HOST, args.port), make_handler(preview))
    url = f"http://{HOST}:{httpd.server_address[1]}/"
    print(f"预览: {url}")
    print("关掉这个窗口就停止。滑块只重做一小段，不会改原文件。")
    if not args.no_browser:
        threading.Timer(0.3, lambda: webbrowser.open(url)).start()

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print()
    finally:
        httpd.server_close()
        preview.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

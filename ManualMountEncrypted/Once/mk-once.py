#!/usr/bin/env python3
# 生成一次性挂载脚本，以及放到 U 盘上的密钥文件。
# 本文件在自己的电脑上运行，需要 python3 和 gcc。生成出的脚本不需要 python。
# 临时口令和卷口令只从终端读取，不进参数、不进历史。
# 卷口令用 scrypt 展开后的密钥流包起来，写进密钥文件。校验不过，就不还原卷口令。

import base64
import datetime
import hashlib
import hmac
import os
import pathlib
import secrets
import stat
import sys

# 内存约 128*N*r。N=2**16、r=8 时约 64MiB。同事电脑太小就改小 N。
N = 1 << 16
R = 8
P = 1
MAXMEM = 256 * 1024 * 1024
BODY = 256


class OnceError(Exception):
    pass


def b64e(data: bytes) -> str:
    return base64.b64encode(data).decode("ascii")


def b64d(text: str) -> bytes:
    return base64.b64decode(text.encode("ascii"), validate=True)


def read_tty(prompt: str) -> str:
    import termios

    fd = os.open("/dev/tty", os.O_RDWR | os.O_NOCTTY)
    try:
        if not os.isatty(fd):
            raise OnceError("没有终端，不能输入。")
        old = termios.tcgetattr(fd)
        quiet = termios.tcgetattr(fd)
        quiet[3] = quiet[3] & ~termios.ECHO
        try:
            termios.tcsetattr(fd, termios.TCSADRAIN, quiet)
            os.write(fd, prompt.encode("utf-8"))
            buf = b""
            while b"\n" not in buf and b"\r" not in buf:
                chunk = os.read(fd, 64)
                if not chunk:
                    raise OnceError("没有读到输入。")
                buf += chunk
            os.write(fd, b"\n")
        finally:
            termios.tcsetattr(fd, termios.TCSAFLUSH, old)
    finally:
        os.close(fd)
    line = buf.splitlines()[0] if buf.splitlines() else b""
    return line.decode("utf-8")


def pack_body(password: bytes) -> bytes:
    if not password or len(password) > BODY - 2:
        raise OnceError("卷口令为空，或长过 254 字节。")
    if b"\n" in password or b"\0" in password:
        raise OnceError("卷口令里不能有换行。")
    body = len(password).to_bytes(2, "big") + password
    return body + b"\0" * (BODY - len(body))


def unpack_body(body: bytes) -> bytes:
    if len(body) != BODY:
        raise OnceError("解开的数据长度不对。")
    n = int.from_bytes(body[:2], "big")
    if n < 1 or n > BODY - 2:
        raise OnceError("临时口令不对。")
    password = body[2 : 2 + n]
    if body[2 + n :] != b"\0" * (BODY - 2 - n):
        raise OnceError("临时口令不对。")
    if b"\n" in password or b"\0" in password:
        raise OnceError("临时口令不对。")
    return password


def derive(password: str, salt: bytes, n: int, r: int, p: int) -> bytes:
    return hashlib.scrypt(
        password.encode("utf-8"),
        salt=salt,
        n=n,
        r=r,
        p=p,
        dklen=32 + BODY,
        maxmem=MAXMEM,
    )


def seal(temp: str, volume: bytes, expires: int, n: int = N, r: int = R, p: int = P) -> dict[str, str]:
    salt = secrets.token_bytes(16)
    dk = derive(temp, salt, n, r, p)
    body = pack_body(volume)
    ct = bytes(a ^ b for a, b in zip(body, dk[32:]))
    exp = str(int(expires)).encode("ascii")
    tag = hmac.new(dk[:32], salt + ct + exp, hashlib.sha256).digest()
    return {
        "n": str(n),
        "r": str(r),
        "p": str(p),
        "salt": b64e(salt),
        "ct": b64e(ct),
        "mac": b64e(tag),
        "expires": str(int(expires)),
    }


def open_sealed(temp: str, fields: dict[str, str]) -> bytes:
    salt = b64d(fields["salt"])
    ct = b64d(fields["ct"])
    tag = b64d(fields["mac"])
    exp = str(fields["expires"]).encode("ascii")
    dk = derive(temp, salt, int(fields["n"]), int(fields["r"]), int(fields["p"]))
    expect = hmac.new(dk[:32], salt + ct + exp, hashlib.sha256).digest()
    if not hmac.compare_digest(expect, tag):
        raise OnceError("临时口令不对。")
    body = bytes(a ^ b for a, b in zip(ct, dk[32:]))
    return unpack_body(body)




_HELPER_B64 = None


def helper_b64() -> str:
    """编译静态解密程序。只在生成脚本的这台电脑上需要 gcc。"""
    global _HELPER_B64
    if _HELPER_B64 is not None:
        return _HELPER_B64
    import subprocess
    import tempfile

    src = pathlib.Path(__file__).resolve().with_name("once-scrypt.c")
    with tempfile.TemporaryDirectory() as td:
        out = pathlib.Path(td) / "once-scrypt"
        proc = subprocess.run(
            ["gcc", "-O2", "-s", "-static", "-o", str(out), str(src)],
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            detail = proc.stderr.strip() or "gcc 没有成功。"
            raise OnceError("编译解密程序失败。这台电脑需要 gcc。\n" + detail)
        raw = out.read_bytes()
    encoded = base64.b64encode(raw).decode("ascii")
    _HELPER_B64 = "\n".join(encoded[i : i + 76] for i in range(0, len(encoded), 76))
    return _HELPER_B64


def render(
    key_id: str,
    expires: int,
    expires_text: str,
    helper: str,
    vera_rel: str,
    time_urls: list[str],
    time_timeout: int,
    time_wait: int,
    local_expire_destroy: int,
    local_expire_priority: int,
) -> str:
    time_url_lines = "\n".join(f"    {url!r}" for url in time_urls)
    return f"""#!/bin/bash
# 一次性挂载。先检查环境，再对时间，然后才询问临时口令。不需要 python。
# 网络时间已过期（{expires_text}）就粉碎。本机过期是否粉碎、是否优先于网络，由 LOCAL_EXPIRE_DESTROY / LOCAL_EXPIRE_PRIORITY 决定。
# 直接执行。只要进度可以加 -v。口令不会写入历史。
set +o history
set +x
unset HISTFILE

VERBOSE=0
for once_arg in "$@"; do
  case "$once_arg" in
    -v|--verbose) VERBOSE=1 ;;
    *)
      echo "不要加别的参数。只要进度可以加 -v。" >&2
      exit 2
      ;;
  esac
done
unset once_arg
case $- in
  *x*) echo "检测到命令跟踪，已停止。" >&2; exit 2 ;;
esac

KEY_ID={key_id!r}
KEY_NAME="once-key-$KEY_ID"
VERA_REL={vera_rel!r}
TIME_TIMEOUT={time_timeout}
TIME_WAIT={time_wait}
LOCAL_EXPIRE_DESTROY={local_expire_destroy}
LOCAL_EXPIRE_PRIORITY={local_expire_priority}
SELF_NAME="once-$KEY_ID.sh"
# ONCEID {key_id}
EXPIRES={expires}
EXPIRES_TEXT={expires_text!r}
SELF_DIR="$(cd "$(dirname -- "$0")" && pwd)" || {{
  echo "无法确定脚本自己的路径。已停止，没有删除文件。" >&2
  exit 1
}}
SELF="$SELF_DIR/$(basename -- "$0")"

once_v() {{
  [ "$VERBOSE" = 1 ] || return 0
  printf '%s\\n' "· $*" >&2
}}

once_can_destroy_file() {{
  local f="$1" dir probe
  [ -f "$f" ] && [ -w "$f" ] || return 1
  dir="$(dirname "$f")"
  [ -w "$dir" ] || return 1
  probe="$(mktemp "$dir/.once-write-test.XXXXXX")" || return 1
  rm -f -- "$probe" || return 1
}}

once_regular() {{
  local f="$1" links
  [ -n "$f" ] && [ ! -L "$f" ] && [ -f "$f" ] || return 1
  links="$(stat -c '%h' -- "$f" 2>/dev/null || echo 0)"
  [ "$links" = 1 ]
}}

once_key_ok() {{
  local f="$1" size first
  once_regular "$f" || return 1
  [ "$(basename -- "$f")" = "$KEY_NAME" ] || return 1
  size="$(stat -c '%s' -- "$f" 2>/dev/null || echo 0)"
  [ "$size" -gt 0 ] && [ "$size" -le 8192 ] || return 1
  IFS= read -r first < "$f" || return 1
  [ "$first" = "ONCEKEY2" ] || return 1
  grep -Fxq "id=$KEY_ID" -- "$f"
}}

once_self_ok() {{
  local f="$1" size
  once_regular "$f" || return 1
  [ "$(basename -- "$f")" = "$SELF_NAME" ] || return 1
  size="$(stat -c '%s' -- "$f" 2>/dev/null || echo 0)"
  [ "$size" -gt 0 ] && [ "$size" -le 3000000 ] || return 1
  grep -Fxq "# ONCEID $KEY_ID" -- "$f"
}}

once_shred_raw() {{
  local f="$1"
  if command -v shred >/dev/null 2>&1; then
    shred -u -n 1 -- "$f" 2>/dev/null || rm -f -- "$f"
  else
    rm -f -- "$f"
  fi
}}

once_destroy_pair() {{
  local why="$1"
  if ! once_key_ok "$KEYFILE" || ! once_self_ok "$SELF"; then
    echo "文件名或内容对不上，密钥和脚本都没有删除。" >&2
    return 1
  fi
  if [ "$(stat -c '%d:%i' -- "$KEYFILE")" != "$KEY_INO" ] || [ "$(stat -c '%d:%i' -- "$SELF")" != "$SELF_INO" ]; then
    echo "文件在确认后变了，密钥和脚本都没有删除。" >&2
    return 1
  fi
  echo "$why" >&2
  echo "只粉碎这两个文件:" >&2
  echo "  密钥 $KEYFILE" >&2
  echo "  脚本 $SELF" >&2
  once_shred_raw "$KEYFILE"
  once_shred_raw "$SELF"
}}

once_scan() {{
  local root="$1"
  [ -n "$root" ] && [ -d "$root" ] || return 0
  case "$root" in
    /|/home|/root|/etc|/usr|/var|/boot) return 0 ;;
  esac
  find "$root" -maxdepth 2 -type f -name "$KEY_NAME" -print0 2>/dev/null
}}

once_field() {{
  local line="$1" key="$2" rest
  rest="${{line#*${{key}}=\\"}}"
  [ "$rest" = "$line" ] && return 1
  printf '%s' "${{rest%%\\"*}}"
}}

once_removable_roots() {{
  local line name rm mp pk
  declare -A once_rm=()
  command -v lsblk >/dev/null 2>&1 || return 0
  while IFS= read -r line; do
    name="$(once_field "$line" NAME || true)"
    rm="$(once_field "$line" RM || true)"
    mp="$(once_field "$line" MOUNTPOINT || true)"
    pk="$(once_field "$line" PKNAME || true)"
    [ -n "$rm" ] || rm=0
    [ -n "$name" ] || continue
    if [ "$rm" != 1 ] && [ -n "$pk" ] && [ "${{once_rm[$pk]:-0}}" = 1 ]; then
      rm=1
    fi
    once_rm["$name"]="$rm"
    if [ "$rm" = 1 ] && [ -n "$mp" ]; then
      printf '%s\\0' "$mp"
    fi
  done < <(lsblk -P -o NAME,RM,MOUNTPOINT,PKNAME 2>/dev/null)
}}

once_under_inspection() {{
  local me tp ppid comm target other
  me=$$
  tp="$(awk '/^TracerPid:/ {{ print $2 }}' /proc/self/status 2>/dev/null || echo 1)"
  [ "$tp" = 0 ] || return 0
  if [ -n "${{LD_PRELOAD:-}}${{LD_AUDIT:-}}" ]; then
    return 0
  fi
  ppid="$(awk '/^PPid:/ {{ print $2 }}' /proc/self/status 2>/dev/null || echo 0)"
  comm=""
  if [ -r "/proc/$ppid/comm" ]; then
    comm="$(tr -d '\\0' < "/proc/$ppid/comm" || true)"
  fi
  case "$comm" in
    gdb|lldb|strace|ltrace|radare2|r2|edb) return 0 ;;
  esac
  for target in /proc/[0-9]*/fd/*; do
    other="$(readlink "$target" 2>/dev/null)" || continue
    case "$other" in
      "/proc/$me/mem"|"/proc/$me/pagemap") return 0 ;;
    esac
  done
  return 1
}}

once_stop_inspected() {{
  if once_under_inspection; then
    echo "检测到调试或内存读取，已停止。" >&2
    exit 2
  fi
}}

once_http_date() {{
  local url="$1" hdr limit="${{TIME_TIMEOUT:-4}}"
  if command -v curl >/dev/null 2>&1; then
    hdr="$(curl -fsS --max-time "$limit" --retry 0 -D - -o /dev/null "$url" 2>/dev/null | awk 'BEGIN{{IGNORECASE=1}} /^Date:/ {{ sub(/\\r/, ""); sub(/^Date:[[:space:]]*/, ""); print; exit }}')"
  elif command -v wget >/dev/null 2>&1; then
    hdr="$(wget -qS -O /dev/null --timeout="$limit" --tries=1 "$url" 2>&1 | awk 'BEGIN{{IGNORECASE=1}} /Date:/ {{ sub(/\\r/, ""); sub(/^[[:space:]]*Date:[[:space:]]*/, ""); print; exit }}')"
  else
    return 1
  fi
  [ -n "$hdr" ] || return 1
  date -u -d "$hdr" +%s 2>/dev/null
}}

once_agree_times() {{
  local dir="$1" f
  local -a nums=()
  for f in "$dir"/*; do
    [ -f "$f" ] || continue
    nums+=("$(cat "$f")")
  done
  [ "${{#nums[@]}}" -ge 2 ] || return 1
  mapfile -t nums < <(printf '%s\\n' "${{nums[@]}}" | sort -n)
  local i j best=""
  for ((i=0; i<${{#nums[@]}}; i++)); do
    for ((j=i+1; j<${{#nums[@]}}; j++)); do
      if [ $((nums[j] - nums[i])) -le $((48 * 3600)) ]; then
        best="${{nums[$(( (i + j) / 2 ))]}}"
      fi
    done
  done
  [ -n "$best" ] || return 1
  printf '%s\\n' "$best"
}}

once_network_time() {{
  local url t dir pid wait_limit="${{TIME_WAIT:-6}}"
  local -a pids=() TIME_URLS=(
{time_url_lines}
  )
  dir="$(mktemp -d /tmp/once-time.XXXXXX 2>/dev/null)" || return 1
  local i=0
  for url in "${{TIME_URLS[@]}}"; do
    (
      if t="$(once_http_date "$url")"; then
        printf '%s\\n' "$t" > "$dir/$i"
      fi
    ) &
    pids+=("$!")
    i=$((i + 1))
  done
  local wait_n=0 agreed=""
  while [ "$wait_n" -lt "$wait_limit" ]; do
    if agreed="$(once_agree_times "$dir")"; then
      break
    fi
    sleep 1
    wait_n=$((wait_n + 1))
  done
  for pid in "${{pids[@]}}"; do
    kill "$pid" 2>/dev/null || true
  done
  wait 2>/dev/null || true
  case "$dir" in
    /tmp/once-time.*) [ -d "$dir" ] && rm -rf -- "$dir" ;;
  esac
  [ -n "$agreed" ] || return 1
  printf '%s\\n' "$agreed"
}}

HELPER=""
once_drop_helper() {{
  local base dir
  [ -n "${{HELPER:-}}" ] || return 0
  base="$(basename -- "$HELPER")"
  dir="$(cd "$(dirname -- "$HELPER")" && pwd 2>/dev/null || true)"
  case "$base" in
    once-scrypt.*) ;;
    *) HELPER=""; return 0 ;;
  esac
  case "$dir" in
    /dev/shm|/tmp|"$SCRIPT_DIR") ;;
    *) HELPER=""; return 0 ;;
  esac
  if [ ! -L "$HELPER" ] && [ -f "$HELPER" ]; then
    rm -f -- "$HELPER"
  fi
  HELPER=""
}}
trap once_drop_helper EXIT

# 把解密小程序从下面的数据里写出来再运行。这段不是口令，口令只从终端读。
once_prepare_helper() {{
  local dir rc
  for dir in /dev/shm /tmp "$SCRIPT_DIR"; do
    [ -d "$dir" ] && [ -w "$dir" ] || continue
    HELPER="$(mktemp "$dir/once-scrypt.XXXXXX")" || continue
    if ! base64 -d > "$HELPER" << 'B64'
{helper}
B64
    then
      rm -f -- "$HELPER"
      HELPER=""
      continue
    fi
    chmod 700 "$HELPER" || {{ rm -f -- "$HELPER"; HELPER=""; continue; }}
    "$HELPER" >/dev/null 2>&1
    rc=$?
    if [ "$rc" -eq 2 ]; then
      return 0
    fi
    rm -f -- "$HELPER"
    HELPER=""
  done
  return 1
}}

if ! command -v base64 >/dev/null 2>&1; then
  echo "需要 base64。" >&2
  exit 1
fi
once_v "1/8"
once_stop_inspected

here="$(cd "$(dirname "$SELF")" && pwd)"
SCRIPT_DIR="$here"
once_hits=()
once_seen=()
once_take() {{
  local root="$1" hit prev known ino
  [ -n "$root" ] || return 0
  root="$(cd -- "$root" && pwd 2>/dev/null || true)"
  [ -n "$root" ] || return 0
  while IFS= read -r -d '' hit; do
    [ -n "$hit" ] || continue
    ino="$(stat -c '%d:%i' -- "$hit" 2>/dev/null || echo "path:$hit")"
    known=0
    for prev in "${{once_seen[@]}}"; do
      if [ "$prev" = "$hit" ] || [ "$prev" = "$ino" ]; then
        known=1
        break
      fi
    done
    [ "$known" = 1 ] && continue
    once_seen+=("$hit" "$ino")
    once_hits+=("$hit")
  done < <(once_scan "$root")
}}

once_v "2/8"
once_take "$SCRIPT_DIR"
while IFS= read -r -d '' root; do
  once_take "$root"
done < <(once_removable_roots)

if [ "${{#once_hits[@]}}" -eq 0 ]; then
  if [ ! -r /dev/tty ]; then
    echo "没有找到密钥文件 $KEY_NAME，也没有终端可询问 U 盘目录。" >&2
    exit 1
  fi
  echo "没有在已挂载的 U 盘里找到 $KEY_NAME。" >/dev/tty
  echo "先在文件管理器里打开这只 U 盘，然后输入它的目录。" >/dev/tty
  IFS= read -r typed_dir </dev/tty || exit 1
  once_take "$typed_dir"
fi
if [ "${{#once_hits[@]}}" -ne 1 ]; then
  echo "要恰好找到一个 $KEY_NAME，现在是 ${{#once_hits[@]}} 个。已停止，没有删除文件。" >&2
  printf '  %s\\n' "${{once_hits[@]}}" >&2
  exit 1
fi
KEYFILE="${{once_hits[0]}}"
once_v "3/8"
if ! once_key_ok "$KEYFILE"; then
  echo "找到的文件不是这次的密钥文件。已停止，没有删除文件。" >&2
  exit 1
fi
if ! once_self_ok "$SELF"; then
  echo "脚本路径对不上，不敢粉碎。已停止，没有删除文件。" >&2
  exit 1
fi
KEY_INO="$(stat -c '%d:%i' -- "$KEYFILE")"
SELF_INO="$(stat -c '%d:%i' -- "$SELF")"

if ! once_can_destroy_file "$SELF" || ! once_can_destroy_file "$KEYFILE"; then
  echo "脚本或 U 盘上的密钥文件不可写，用完无法粉碎。已停止，没有询问口令。" >&2
  exit 1
fi
once_stop_inspected
once_v "4/8"
if ! once_prepare_helper; then
  echo "这台电脑跑不了解密程序。已停止，没有询问口令。" >&2
  exit 1
fi

once_v "5/8"
LOCAL_NOW="$(date +%s 2>/dev/null || echo 0)"
expired_local=0
if [ "$LOCAL_NOW" -gt 0 ] && [ "$LOCAL_NOW" -ge "$EXPIRES" ]; then
  expired_local=1
fi
if [ "$expired_local" = 1 ] && [ "$LOCAL_EXPIRE_DESTROY" = 1 ] && [ "$LOCAL_EXPIRE_PRIORITY" = 1 ]; then
  once_destroy_pair "已过期（$EXPIRES_TEXT）。按本机时间优先销毁。" || true
  exit 1
fi
if NET_NOW="$(once_network_time)"; then
  now="$NET_NOW"
  ONCE_TIME_SOURCE=net
else
  now="$LOCAL_NOW"
  ONCE_TIME_SOURCE=local
fi
if [ "$now" -le 0 ]; then
  now="$LOCAL_NOW"
  ONCE_TIME_SOURCE=local
fi
if [ "$now" -le 0 ]; then
  echo "读不到时间。已停止，没有询问口令。" >&2
  exit 1
fi
expired_net=0
if [ "$ONCE_TIME_SOURCE" = net ] && [ "$now" -ge "$EXPIRES" ]; then
  expired_net=1
fi
if [ "$expired_net" = 1 ]; then
  once_destroy_pair "已过期（$EXPIRES_TEXT）。按网络时间销毁。" || true
  exit 1
fi
if [ "$expired_local" = 1 ]; then
  if [ "$LOCAL_EXPIRE_DESTROY" = 1 ]; then
    once_destroy_pair "已过期（$EXPIRES_TEXT）。按本机时间销毁。" || true
    exit 1
  fi
  if [ "$ONCE_TIME_SOURCE" = local ]; then
    echo "本机时间显示已过期（$EXPIRES_TEXT），localExpireDestroy=0，所以没有销毁。已停止，没有询问口令。" >&2
    exit 1
  fi
fi
if [ "$ONCE_TIME_SOURCE" = local ]; then
  echo "没有对上网络时间，这次用本机时间。" >&2
fi

once_v "6/8"
LIB=""
vera_dir=""
if [ -n "$VERA_REL" ]; then
  vera_dir="$(cd "$SCRIPT_DIR/$VERA_REL" 2>/dev/null && pwd)" || vera_dir=""
fi
if [ -n "$vera_dir" ] && [ -f "$vera_dir/lib.sh" ] && [ -f "$vera_dir/config.sh" ]; then
  LIB="$vera_dir/lib.sh"
elif [ -f "$SCRIPT_DIR/lib.sh" ] && [ -f "$SCRIPT_DIR/config.sh" ]; then
  LIB="$SCRIPT_DIR/lib.sh"
else
  echo "找不到 VeraCrypt。once 脚本相对 VeraCrypt 的路径是 $VERA_REL，在 Once/config.sh 的 veraRel 里改。" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$LIB"
cd "$LIB_DIR" || exit 1
if ! resolve_veracrypt_bin || ! resolve_volume; then
  echo "还不能确定要挂载的卷。" >&2
  exit 1
fi
if detect_existing_veracrypt_mount || {{ detect_open_veracrypt_slot && [ -n "${{VC_SLOT_MP:-}}" ]; }}; then
  echo "卷已经挂着。这次不询问临时口令，也不删除脚本和密钥文件。" >&2
  exit 1
fi
once_stop_inspected
if [ ! -r /dev/tty ]; then
  echo "没有终端，不能输入。" >&2
  exit 1
fi
once_v "7/8"
printf '临时口令（不会进入历史）: ' >/dev/tty
IFS= read -rs typed </dev/tty || exit 1
printf '\\n' >/dev/tty
if [ -z "$typed" ]; then
  echo "临时口令是空的。" >&2
  exit 1
fi
once_stop_inspected

keyPass="$(printf '%s' "$typed" | "$HELPER" "$KEYFILE" "$now")"
rc=$?
typed=""
unset typed
once_drop_helper
if [ "$rc" -ne 0 ] || [ -z "$keyPass" ]; then
  unset keyPass
  exit 1
fi

once_v "8/8"
mount_veracrypt
rc=$?
unset keyPass
if [ "$rc" -eq 0 ]; then
  once_destroy_pair "挂载成功。" || true
fi
exit "$rc"
"""


TOKEN_ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"


def write_private(path: pathlib.Path, text: str, mode: int) -> None:
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, mode)
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fh.write(text)
        fh.flush()
        os.fsync(fh.fileno())


def write_script(path: pathlib.Path, text: str) -> None:
    write_private(path, text, 0o700)
    path.chmod(path.stat().st_mode | stat.S_IXUSR)


def key_text(ident: str, kind: str, fields: dict[str, str], expires: int) -> str:
    lines = [
        "ONCEKEY2",
        f"id={ident}",
        f"kind={kind}",
        f"n={fields['n']}",
        f"r={fields['r']}",
        f"p={fields['p']}",
        f"salt={fields['salt']}",
        f"ct={fields['ct']}",
        f"mac={fields['mac']}",
        f"expires={expires}",
        "",
    ]
    return "\n".join(lines)


def make_auto(kind: str, digits: int) -> str:
    if kind == "pin":
        return "".join(secrets.choice("0123456789") for _ in range(digits))
    return "".join(secrets.choice(TOKEN_ALPHABET) for _ in range(digits))


def format_secret(secret: str, kind: str) -> str:
    if kind == "pin":
        return " ".join(secret[i : i + 4] for i in range(0, len(secret), 4))
    if kind == "token":
        return "-".join(secret[i : i + 4] for i in range(0, len(secret), 4))
    return secret


def clean_pin(text: str, minimum: int) -> str:
    secret = text.strip().replace(" ", "").replace("-", "")
    if not secret.isdigit() or len(secret) < minimum:
        raise OnceError(f"PIN 至少 {minimum} 位数字。没有生成。")
    return secret


def ask_temp(kind: str, digits: int) -> str:
    if kind == "pin":
        first = clean_pin(read_tty(f"数字 PIN（至少 {digits} 位）: "), digits)
        second = clean_pin(read_tty("再输入一次数字 PIN: "), digits)
    else:
        first = read_tty("临时口令（同事电脑上要输入的，不是卷口令）: ")
        second = read_tty("再输入一次临时口令: ")
        if not first:
            raise OnceError("临时口令是空的。没有生成。")
    if first != second:
        raise OnceError("两次临时口令不一致。没有生成。")
    return first


def color(text: str, code: str) -> str:
    if not sys.stdout.isatty():
        return text
    return f"\033[{code}m{text}\033[0m"


def read_line_tty() -> str:
    fd = os.open("/dev/tty", os.O_RDWR | os.O_NOCTTY)
    try:
        buf = b""
        while b"\n" not in buf and b"\r" not in buf:
            chunk = os.read(fd, 64)
            if not chunk:
                raise OnceError("没有读到输入。")
            buf += chunk
    finally:
        os.close(fd)
    line = buf.splitlines()[0] if buf.splitlines() else b""
    return line.decode("utf-8")


def ask_volume() -> str:
    volume = read_tty("卷口令: ")
    if not volume:
        raise OnceError("卷口令是空的。没有生成。")
    print("核对卷口令: " + color(volume, "1;33"))
    print(color("回车继续，Ctrl-C 取消。", "2"))
    sys.stdout.flush()
    if read_line_tty() != "":
        raise OnceError("没有确认。没有生成。")
    return volume


def print_pairs(made: list[tuple[pathlib.Path, pathlib.Path, str, str]], kind: str, expires_at: datetime.datetime) -> None:
    print()
    print(color(expires_at.strftime("到期 %Y-%m-%d %H:%M"), "1;35"))
    print()
    for script_path, key_path, _expires_text, temp in made:
        print(color(format_secret(temp, kind), "1;33"))
        print(color(str(script_path), "1;36"))
        print(color(str(key_path), "1;32"))
        print()


def _config_value(line: str) -> str:
    return line.split("=", 1)[1].strip().strip('"').strip("'")


def load_once_config() -> tuple[str, list[str], int, int, int, int, int, int, int]:
    path = pathlib.Path(__file__).resolve().parent / "config.sh"
    rel = "../VeraCrypt"
    urls: list[str] = []
    timeout = 3
    wait = 4
    local_expire_destroy = 1
    local_expire_priority = 1
    expire_days = 15
    pin_digits = 16
    pin_numeric = 1
    if path.is_file():
        for raw in path.read_text(encoding="utf-8").splitlines():
            line = raw.split("#", 1)[0].strip()
            if line.startswith("veraRel="):
                rel = _config_value(line)
            elif line.startswith("timeUrl="):
                urls.append(_config_value(line))
            elif line.startswith("timeTimeout="):
                timeout = int(_config_value(line))
            elif line.startswith("timeWait="):
                wait = int(_config_value(line))
            elif line.startswith("localExpireDestroy="):
                local_expire_destroy = int(_config_value(line))
            elif line.startswith("localExpirePriority="):
                local_expire_priority = int(_config_value(line))
            elif line.startswith("expireDays="):
                expire_days = int(_config_value(line))
            elif line.startswith("pinDigits="):
                pin_digits = int(_config_value(line))
            elif line.startswith("pinNumeric="):
                pin_numeric = int(_config_value(line))
    if not urls:
        urls = [
            "https://www.baidu.com/",
            "https://www.qq.com/",
            "https://www.aliyun.com/",
            "https://www.microsoft.com/",
        ]
    if not rel or any(ch in rel for ch in "\n\r'\"\\"):
        raise OnceError("Once/config.sh 里的 veraRel 不能是空的，也不能有引号。")
    if rel.startswith("/") or rel.startswith("~"):
        raise OnceError("veraRel 要写相对路径，例如 ../VeraCrypt。")
    if len(urls) < 2:
        raise OnceError("Once/config.sh 里至少写两家 timeUrl。")
    for url in urls:
        if not url.startswith("https://") or any(ch in url for ch in " \t\n\r'\"\\$`;|&"):
            raise OnceError(f"timeUrl 必须是 https 地址: {url}")
    if timeout < 1 or timeout > 20 or wait < 1 or wait > 30:
        raise OnceError("timeTimeout 要在 1 到 20 秒，timeWait 要在 1 到 30 秒。")
    if local_expire_destroy not in (0, 1):
        raise OnceError("localExpireDestroy 只能是 0 或 1。")
    if local_expire_priority not in (0, 1):
        raise OnceError("localExpirePriority 只能是 0 或 1。")
    if expire_days < 1 or expire_days > 3650:
        raise OnceError("expireDays 要在 1 到 3650 之间。")
    if pin_digits < 16 or pin_digits > 64:
        raise OnceError("pinDigits 要在 16 到 64 之间。")
    if pin_numeric not in (0, 1):
        raise OnceError("pinNumeric 只能是 0 或 1。")
    return (
        rel,
        urls,
        timeout,
        wait,
        local_expire_destroy,
        local_expire_priority,
        expire_days,
        pin_digits,
        pin_numeric,
    )


def generate(
    out_dir: pathlib.Path,
    temp: str,
    kind: str,
    auto: bool,
    digits: int,
    volume: str,
    vera_rel: str,
    expires_at: datetime.datetime,
    time_urls: list[str],
    time_timeout: int,
    time_wait: int,
    local_expire_destroy: int,
    local_expire_priority: int,
) -> tuple[pathlib.Path, pathlib.Path, str, str]:
    if temp == volume:
        if not auto:
            raise OnceError("临时口令不能和卷口令相同。没有生成。")
        for _ in range(8):
            temp = make_auto(kind, digits)
            if temp != volume:
                break
        else:
            raise OnceError("自动生成的临时口令和卷口令撞上了。没有生成。")
    expires_unix = int(expires_at.timestamp())
    expires_text = expires_at.strftime("%Y-%m-%d %H:%M")
    fields = seal(temp, volume.encode("utf-8"), expires_unix)
    ident = secrets.token_hex(4)
    script_path = out_dir / f"once-{ident}.sh"
    key_path = out_dir / f"once-key-{ident}"
    write_script(
        script_path,
        render(
            ident,
            expires_unix,
            expires_text,
            helper_b64(),
            vera_rel,
            time_urls,
            time_timeout,
            time_wait,
            local_expire_destroy,
            local_expire_priority,
        ),
    )
    write_private(key_path, key_text(ident, kind, fields, expires_unix), 0o600)
    return script_path, key_path, expires_text, temp


def selftest() -> int:
    import subprocess
    import tempfile
    import time

    temp = "temp-once-口令"
    volume = "qwer-测试".encode("utf-8")
    expires_far = 4_000_000_000
    fields = seal(temp, volume, expires_far, n=1 << 10, r=8, p=1)
    if open_sealed(temp, fields) != volume:
        print("解开失败", file=sys.stderr)
        return 1
    try:
        open_sealed("wrong", fields)
    except OnceError:
        pass
    else:
        print("错误临时口令不应该解开", file=sys.stderr)
        return 1
    tampered = dict(fields)
    tampered["expires"] = str(expires_far + 100)
    try:
        open_sealed(temp, tampered)
    except OnceError:
        pass
    else:
        print("改 expires 不应该还能解开", file=sys.stderr)
        return 1
    blob = b64d(fields["ct"])
    if volume in blob or temp.encode("utf-8") in blob:
        print("密文里出现了口令", file=sys.stderr)
        return 1
    pin = "1234567890123456"
    pin_fields = seal(pin, volume, expires_far, n=1 << 10, r=8, p=1)
    ident = "abcd1234"
    expires = expires_far
    body = key_text(ident, "pin", pin_fields, expires)
    if not body.startswith("ONCEKEY2\n"):
        print("密钥文件版本不对", file=sys.stderr)
        return 1
    embedded = helper_b64()
    text = render(
        ident,
        expires,
        "2096-10-02 00:00",
        embedded,
        "../VeraCrypt",
        ["https://www.baidu.com/", "https://time.example.test/"],
        2,
        2,
        1,
        1,
    )
    if "LIB_BAKED" in text or "/home/" in text:
        print("脚本里不该再有生成机绝对路径", file=sys.stderr)
        return 1
    net_fn = text[text.index("once_network_time() {") : text.index('\nHELPER=""')]
    if "https://time.example.test/" not in net_fn or "cloudflare.com" in net_fn:
        print("对时网址没有按配置写进脚本", file=sys.stderr)
        return 1
    if (
        "LOCAL_EXPIRE_DESTROY=1" not in text
        or "LOCAL_EXPIRE_PRIORITY=1" not in text
        or "按本机时间优先销毁" not in text
        or "LOCAL_NOW=" not in text
    ):
        print("本机时间过期销毁没有写进脚本", file=sys.stderr)
        return 1
    if "VERA_REL='../VeraCrypt'" not in text:
        print("没有把 VeraCrypt 相对路径写进脚本", file=sys.stderr)
        return 1
    head, _, rest = text.partition("<< 'B64'\n")
    _, _, tail = rest.partition("\nB64\n")
    if "python3" in head or "python3" in tail:
        print("生成的脚本还在调用 python3", file=sys.stderr)
        return 1
    if volume.decode("utf-8") in text or pin in text or pin_fields["ct"] in text or temp in text:
        print("脚本里出现了口令或密文", file=sys.stderr)
        return 1
    if 'find "$root" -maxdepth 2' not in text or "lsblk -P" not in text:
        print("U 盘查找代码没有正确写进脚本", file=sys.stderr)
        return 1
    if "VERBOSE=0" not in text or 'once_v "1/8"' not in text or "-v|--verbose" not in text:
        print("生成的脚本没有 -v 进度", file=sys.stderr)
        return 1
    env_at = text.find("\nonce_stop_inspected\n")
    scan_at = text.find('once_take "$SCRIPT_DIR"')
    time_at = text.find("按网络时间销毁")
    ask_at = text.find("临时口令（不会进入历史）")
    if min(env_at, scan_at, time_at, ask_at) < 0 or not (env_at < scan_at < time_at < ask_at):
        print("环境检查、对时、询问口令的顺序不对", file=sys.stderr)
        return 1
    with tempfile.TemporaryDirectory() as td:
        key_path = pathlib.Path(td) / f"once-key-{ident}"
        key_path.write_text(body, encoding="ascii")
        helper_path = pathlib.Path(td) / "once-scrypt"
        helper_path.write_bytes(base64.b64decode("".join(embedded.split())))
        helper_path.chmod(0o700)
        good = subprocess.run(
            [str(helper_path), str(key_path), str(expires - 1)],
            input=b"1234 5678-9012 3456",
            capture_output=True,
        )
        if good.returncode != 0 or good.stdout != volume:
            print(good.stderr.decode("utf-8", "replace"), file=sys.stderr)
            print("密钥文件没有按 PIN 解开", file=sys.stderr)
            return 1
        late = subprocess.run(
            [str(helper_path), str(key_path), str(expires)],
            input=b"1234 5678-9012 3456",
            capture_output=True,
        )
        if late.returncode == 0 or late.stdout:
            print("过期时间不应该解开", file=sys.stderr)
            return 1
        bad = subprocess.run(
            [str(helper_path), str(key_path), str(expires - 1)],
            input=b"0000000000000000",
            capture_output=True,
        )
        if bad.returncode == 0 or bad.stdout:
            print("错误 PIN 不应该解开", file=sys.stderr)
            return 1
        fake_now = subprocess.run(
            [str(helper_path), str(key_path), "0"],
            input=b"1234 5678-9012 3456",
            capture_output=True,
        )
        if fake_now.returncode != 0 or fake_now.stdout != volume:
            print(fake_now.stderr.decode("utf-8", "replace"), file=sys.stderr)
            print("未过期时传入 now=0 应该仍按本机时间解开", file=sys.stderr)
            return 1
        past = int(time.time()) - 120
        past_fields = seal(pin, volume, past, n=1 << 10, r=8, p=1)
        past_key = pathlib.Path(td) / "once-key-past"
        past_key.write_text(key_text(ident, "pin", past_fields, past), encoding="ascii")
        past_open = subprocess.run(
            [str(helper_path), str(past_key), "0"],
            input=b"1234 5678-9012 3456",
            capture_output=True,
        )
        if past_open.returncode == 0 or past_open.stdout:
            print("已过期密钥传入 now=0 不应该解开", file=sys.stderr)
            return 1
        forged = body.replace(f"expires={expires}", f"expires={expires + 10_000_000}")
        forged_key = pathlib.Path(td) / "once-key-forged"
        forged_key.write_text(forged, encoding="ascii")
        forged_open = subprocess.run(
            [str(helper_path), str(forged_key), str(expires - 1)],
            input=b"1234 5678-9012 3456",
            capture_output=True,
        )
        if forged_open.returncode == 0 or forged_open.stdout:
            print("篡改 expires 不应该解开", file=sys.stderr)
            return 1
        script_path = pathlib.Path(td) / "once.sh"
        script_path.write_text(text, encoding="utf-8")
        proc = subprocess.run(["bash", "-n", str(script_path)], capture_output=True, text=True)
        if proc.returncode != 0:
            print(proc.stderr, file=sys.stderr)
            return 1
        guards = text[text.index("once_regular() {") : text.index("once_shred_raw() {")]
        box = pathlib.Path(td) / "box"
        box.mkdir()
        good_key = box / "once-key-abcd1234"
        good_key.write_text(body, encoding="ascii")
        other = box / "other"
        other.mkdir()
        wrong_key = other / "once-key-abcd1234"
        wrong_key.write_text("hello\nid=abcd1234\n", encoding="ascii")
        linked = box / "once-key-link"
        linked.symlink_to(good_key)
        good_script = box / "once-abcd1234.sh"
        good_script.write_text("# ONCEID abcd1234\nexit 0\n", encoding="utf-8")
        check = subprocess.run(
            ["bash", "-c", "KEY_ID=abcd1234\nKEY_NAME=once-key-abcd1234\nSELF_NAME=once-abcd1234.sh\n" + guards + f"""
ok=0
once_key_ok {str(good_key)!r} || ok=1
once_key_ok {str(wrong_key)!r} && ok=1
once_key_ok {str(linked)!r} && ok=1
ln {str(good_key)!r} {str(box / "hard")!r}
once_key_ok {str(good_key)!r} && ok=1
rm -f {str(box / "hard")!r}
once_key_ok {str(good_key)!r} || ok=1
once_self_ok {str(good_script)!r} || ok=1
once_self_ok {str(script_path)!r} && ok=1
exit $ok
"""],
            capture_output=True,
            text=True,
        )
        if check.returncode != 0:
            print(check.stdout, check.stderr, file=sys.stderr)
            print("粉碎前的文件核对没有拦住错文件", file=sys.stderr)
            return 1
        if not linked.exists() or not good_key.exists() or not wrong_key.exists():
            print("核对过程删了文件", file=sys.stderr)
            return 1
        scan = text[text.index("once_scan() {") : text.index("once_removable_roots()")]
        usb = pathlib.Path(td) / "usb"
        (usb / "a" / "b" / "c").mkdir(parents=True)
        key = usb / "once-key-abcd1234"
        key.write_text("x")
        (usb / "a" / "b" / "c" / "once-key-abcd1234").write_text("y")
        (usb / "once-key-ffffeeee").write_text("z")
        found = subprocess.run(
            ["bash", "-c", "KEY_NAME=once-key-abcd1234\n" + scan + "\nonce_scan " + repr(str(usb))],
            capture_output=True,
        )
        hits = [hit for hit in found.stdout.split(b"\0") if hit]
        if hits != [str(key).encode()]:
            print(found.stderr.decode(), hits, file=sys.stderr)
            print("U 盘文件名查找结果不对", file=sys.stderr)
            return 1
    time_fn = text[text.index("once_http_date() {") : text.index('\nHELPER=""')]
    net = subprocess.run(["bash", "-c", time_fn + "\nonce_network_time"], capture_output=True, text=True)
    if net.returncode == 0:
        import time

        got = int(net.stdout.strip())
        if abs(got - time.time()) > 3 * 24 * 3600:
            print(f"网络时间偏离太大: {got}", file=sys.stderr)
            return 1
    print("selftest ok")
    return 0


def split_count(argv: list[str]) -> tuple[int, list[str]]:
    count = 1
    seen = False
    rest: list[str] = []
    for arg in argv:
        if len(arg) > 1 and arg[0] == "-" and arg[1:].isdigit():
            if seen:
                raise OnceError("组数只写一次，例如 -2。")
            seen = True
            count = int(arg[1:])
        else:
            rest.append(arg)
    if count < 1 or count > 99:
        raise OnceError("组数要在 1 到 99 之间。")
    return count, rest


def main(argv: list[str]) -> int:
    import argparse

    if argv[:1] == ["selftest"]:
        return selftest()
    try:
        count, argv = split_count(argv)
        (
            vera_rel,
            time_urls,
            time_timeout,
            time_wait,
            local_expire_destroy,
            local_expire_priority,
            expire_days,
            pin_digits,
            pin_numeric,
        ) = load_once_config()
    except OnceError as exc:
        print(str(exc), file=sys.stderr)
        return 1
    parser = argparse.ArgumentParser(description="生成一次性挂载脚本和 U 盘密钥文件")
    parser.add_argument("out", nargs="?", help="生成到这个目录。不写就是运行命令时的当前目录")
    parser.add_argument("--caller", help=argparse.SUPPRESS)
    parser.add_argument(
        "--days",
        type=int,
        default=None,
        help=f"多少天后过期。不写用 config 的 expireDays（现在是 {expire_days}）",
    )
    parser.add_argument(
        "--digits",
        type=int,
        default=None,
        help=f"临时口令位数，至少 16。不写用 config 的 pinDigits（现在是 {pin_digits}）",
    )
    parser.add_argument("--manual", action="store_true", help="自己输入临时口令，不自动生成")
    args = parser.parse_args(argv)
    days = expire_days if args.days is None else args.days
    digits = pin_digits if args.digits is None else args.digits
    if days < 1:
        print("天数至少是 1。", file=sys.stderr)
        return 1
    if digits < 16:
        print("临时口令至少 16 位。", file=sys.stderr)
        return 1
    kind = "pin" if pin_numeric else "token"
    auto = not args.manual
    lib_dir = pathlib.Path(__file__).resolve().parent.parent / "VeraCrypt"
    if not (lib_dir / "lib.sh").is_file() or not (lib_dir / "config.sh").is_file():
        print("找不到旁边的 VeraCrypt/lib.sh。", file=sys.stderr)
        return 1
    if args.out:
        out_dir = pathlib.Path(args.out).expanduser()
    elif args.caller:
        out_dir = pathlib.Path(args.caller).expanduser()
    else:
        out_dir = pathlib.Path.cwd()
    out_dir.mkdir(parents=True, exist_ok=True)
    expires_at = datetime.datetime.now() + datetime.timedelta(days=days)
    try:
        volume = ask_volume()
        made = []
        for _ in range(count):
            temp = ask_temp(kind, digits) if args.manual else make_auto(kind, digits)
            made.append(
                generate(
                    out_dir,
                    temp,
                    kind,
                    auto,
                    digits,
                    volume,
                    vera_rel,
                    expires_at,
                    time_urls,
                    time_timeout,
                    time_wait,
                    local_expire_destroy,
                    local_expire_priority,
                )
            )
    except OnceError as exc:
        print(str(exc), file=sys.stderr)
        return 1
    print_pairs(made, kind, expires_at)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

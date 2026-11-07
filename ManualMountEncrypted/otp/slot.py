#!/usr/bin/env python3
# 一次性码槽。
#
# 卷口令不写进文件明文。每条码对应一个槽：用这条码派生密钥，加密卷口令。
# 码只在生成时打印一次。挂载脚本解开后删除对应槽，这条码就不能再推出卷口令。
#
# 槽文件格式（文本）：
#   OTP1
#   id=....
#   iter=200000
#   salt=base64
#   iv=base64
#   ct=base64
#   mac=base64
#
# mac = HMAC-SHA256(mac_key, 上述字段的原始字节)
# 密钥 = PBKDF2-HMAC-SHA256(整条码, salt) 分成 enc_key / mac_key
# 对称算法是 OpenSSL 的 AES-256-CBC，本文件自己做 PKCS#7，并先校验 HMAC。

import argparse
import base64
import hashlib
import hmac
import os
import pathlib
import secrets
import select
import signal
import subprocess
import sys
import time

ALPH = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
ID_LEN = 4
SEC_LEN = 20
CODE_LEN = ID_LEN + SEC_LEN
ITER = 200_000
VERSION = "OTP1"

# 只认这些提示，避免把口令写进 sudo 自己的 “password is required”。
PROMPTS = (
    b"enter the user password",
    b"enter the recovery password",
    b"passphrase:",
)


class SlotError(Exception):
    pass


def read_tty_line(prompt: str) -> str:
    """只从 /dev/tty 读，并关掉回显。失败就停，不用会把码打在屏幕上的备用读法。"""
    import termios

    try:
        fd = os.open("/dev/tty", os.O_RDWR | os.O_NOCTTY)
    except OSError as exc:
        raise SlotError("没有终端，不能输入。请在真正的终端里运行。") from exc
    try:
        if not os.isatty(fd):
            raise SlotError("没有终端，不能输入。请在真正的终端里运行。")
        try:
            old = termios.tcgetattr(fd)
        except termios.error as exc:
            raise SlotError("没有终端，不能输入。请在真正的终端里运行。") from exc
        quiet = termios.tcgetattr(fd)
        quiet[3] = quiet[3] & ~termios.ECHO
        try:
            termios.tcsetattr(fd, termios.TCSADRAIN, quiet)
            os.write(fd, prompt.encode("utf-8"))
            buf = b""
            while b"\n" not in buf and b"\r" not in buf:
                chunk = os.read(fd, 64)
                if not chunk:
                    raise SlotError("没有读到输入。")
                buf += chunk
            os.write(fd, b"\n")
        finally:
            termios.tcsetattr(fd, termios.TCSAFLUSH, old)
    finally:
        os.close(fd)
    line = buf.splitlines()[0] if buf.splitlines() else b""
    return line.decode("utf-8")


def normalize(code: str) -> str:
    text = code.strip().upper().replace(" ", "").replace("-", "").replace("_", "")
    text = text.translate(str.maketrans({"I": "1", "L": "1", "O": "0"}))
    if len(text) != CODE_LEN or any(ch not in ALPH for ch in text):
        raise SlotError("码应为 6 组、每组 4 位（字母数字，不含 I L O U）。")
    return text


def format_code(raw: str) -> str:
    return "-".join(raw[i : i + 4] for i in range(0, len(raw), 4))


def b64e(data: bytes) -> str:
    return base64.b64encode(data).decode("ascii")


def b64d(text: str) -> bytes:
    try:
        return base64.b64decode(text.encode("ascii"), validate=True)
    except Exception as exc:
        raise SlotError("槽文件损坏。") from exc


def derive(code: str, salt: bytes, rounds: int) -> tuple[bytes, bytes]:
    dk = hashlib.pbkdf2_hmac("sha256", code.encode("ascii"), salt, rounds, dklen=64)
    return dk[:32], dk[32:]


def pkcs7_pad(data: bytes, block: int = 16) -> bytes:
    n = block - (len(data) % block)
    return data + bytes([n]) * n


def pkcs7_unpad(data: bytes, block: int = 16) -> bytes:
    if not data or len(data) % block:
        raise SlotError("槽文件损坏。")
    n = data[-1]
    if n < 1 or n > block or data[-n:] != bytes([n]) * n:
        raise SlotError("槽文件损坏。")
    return data[:-n]


def aes_cbc(data: bytes, key: bytes, iv: bytes, decrypt: bool) -> bytes:
    cmd = ["openssl", "enc"]
    if decrypt:
        cmd.append("-d")
    cmd += ["-aes-256-cbc", "-K", key.hex(), "-iv", iv.hex(), "-nosalt", "-nopad"]
    try:
        proc = subprocess.run(cmd, input=data, capture_output=True, check=False)
    except FileNotFoundError as exc:
        raise SlotError("找不到 openssl。") from exc
    if proc.returncode != 0:
        err = proc.stderr.decode("utf-8", "replace").strip()
        raise SlotError(err or "openssl 加密失败。")
    return proc.stdout


def mac_message(ident: str, rounds: int, salt: bytes, iv: bytes, ct: bytes, kind: str | None = None) -> bytes:
    parts: list[bytes] = [
        VERSION.encode("ascii"),
        ident.encode("ascii"),
        str(rounds).encode("ascii"),
    ]
    if kind:
        parts.append(kind.encode("ascii"))
    parts.extend([salt, iv, ct])
    return b"\0".join(parts)


def rand_token(alphabet: str, n: int) -> str:
    return "".join(secrets.choice(alphabet) for _ in range(n))


def seal(ident: str, material: str, password: bytes, kind: str, header: str = VERSION) -> str:
    salt = secrets.token_bytes(16)
    iv = secrets.token_bytes(16)
    enc_key, mac_key = derive(material, salt, ITER)
    ct = aes_cbc(pkcs7_pad(password), enc_key, iv, decrypt=False)
    tag = hmac.new(mac_key, mac_message(ident, ITER, salt, iv, ct, kind), hashlib.sha256).digest()
    lines = [
        header,
        f"kind={kind}",
        f"id={ident}",
        f"iter={ITER}",
        f"salt={b64e(salt)}",
        f"iv={b64e(iv)}",
        f"ct={b64e(ct)}",
        f"mac={b64e(tag)}",
    ]
    if kind == "key":
        lines.append(f"secret={material}")
    return "\n".join(lines) + "\n"


def write_new(path: pathlib.Path, body: str) -> None:
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "w", encoding="ascii") as fh:
        fh.write(body)
        fh.flush()
        os.fsync(fh.fileno())


def new_slot(directory: pathlib.Path, password: bytes) -> str:
    for _ in range(5):
        ident = rand_token(ALPH, ID_LEN)
        raw = ident + rand_token(ALPH, SEC_LEN)
        path = directory / f"slot-{ident}"
        try:
            write_new(path, seal(ident, raw, password, "code"))
        except FileExistsError:
            continue
        return format_code(raw)
    raise SlotError("槽编号撞车，没有写成。")


def new_pin(directory: pathlib.Path, password: bytes, digits: int) -> str:
    pin = rand_token("0123456789", digits)
    for _ in range(5):
        ident = rand_token(ALPH, ID_LEN)
        path = directory / f"slot-{ident}"
        try:
            write_new(path, seal(ident, pin, password, "pin"))
        except FileExistsError:
            continue
        return pin
    raise SlotError("槽编号撞车，没有写成。")


def new_keyfile(directory: pathlib.Path, password: bytes) -> pathlib.Path:
    material = rand_token(ALPH, 32)
    for _ in range(5):
        ident = rand_token(ALPH, ID_LEN)
        path = directory / ("key-" + rand_token(ALPH, 8))
        try:
            write_new(path, seal(ident, material, password, "key", header="OTPKEY1"))
        except FileExistsError:
            continue
        return path
    raise SlotError("密钥文件名撞车，没有写成。")


def parse_fields(path: pathlib.Path, header: str) -> dict[str, str]:
    try:
        lines = path.read_text(encoding="ascii").splitlines()
    except OSError as exc:
        raise SlotError(f"读不了文件: {path}") from exc
    if not lines or lines[0] != header:
        raise SlotError(f"不是本脚本的文件: {path.name}")
    fields: dict[str, str] = {}
    for line in lines[1:]:
        if not line or "=" not in line:
            raise SlotError(f"文件损坏: {path.name}")
        key, value = line.split("=", 1)
        fields[key] = value
    for key in ("id", "iter", "salt", "iv", "ct", "mac"):
        if key not in fields:
            raise SlotError(f"文件缺 {key}: {path.name}")
    return fields


def read_fields(path: pathlib.Path) -> dict[str, str]:
    return parse_fields(path, VERSION)


def decrypt_fields(fields: dict[str, str], material: str) -> bytes:
    ident = fields["id"]
    kind = fields.get("kind")
    try:
        rounds = int(fields["iter"])
    except ValueError as exc:
        raise SlotError("槽文件损坏。") from exc
    if rounds < 1 or rounds > 5000000:
        raise SlotError("槽文件损坏。")
    salt = b64d(fields["salt"])
    iv = b64d(fields["iv"])
    ct = b64d(fields["ct"])
    tag = b64d(fields["mac"])
    enc_key, mac_key = derive(material, salt, rounds)
    expect = hmac.new(
        mac_key,
        mac_message(ident, rounds, salt, iv, ct, kind if "kind" in fields else None),
        hashlib.sha256,
    ).digest()
    if not hmac.compare_digest(expect, tag):
        raise SlotError("对不上。")
    password = pkcs7_unpad(aes_cbc(ct, enc_key, iv, decrypt=True))
    if not password or b"\n" in password or b"\0" in password:
        raise SlotError("槽里的口令不能用（空的，或含换行）。")
    return password


def unlock(directory: pathlib.Path, code: str) -> tuple[bytes, pathlib.Path]:
    raw = normalize(code)
    ident = raw[:ID_LEN]
    path = directory / f"slot-{ident}"
    if not path.is_file():
        raise SlotError("没有这个编号的槽，可能已经用过了。")
    fields = read_fields(path)
    if fields.get("kind", "code") == "pin":
        raise SlotError("这个槽是 PIN。")
    if fields["id"] != ident:
        raise SlotError("槽编号对不上。")
    return decrypt_fields(fields, raw), path


def pin_digits(text: str) -> str | None:
    raw = text.strip().replace(" ", "").replace("-", "")
    if raw.isdigit() and 8 <= len(raw) <= 20:
        return raw
    return None


def unlock_pin(directory: pathlib.Path, pin_text: str) -> tuple[bytes, pathlib.Path]:
    pin = pin_digits(pin_text)
    if not pin:
        raise SlotError("PIN 应为 8 到 20 位数字。")
    saw = False
    for path in sorted(directory.glob("slot-*")):
        if not path.is_file():
            continue
        try:
            fields = read_fields(path)
        except SlotError:
            continue
        if fields.get("kind") != "pin":
            continue
        saw = True
        try:
            return decrypt_fields(fields, pin), path
        except SlotError:
            continue
    if not saw:
        raise SlotError("目录里没有 PIN 槽。")
    raise SlotError("这个 PIN 解不开。")


def open_keyfile(path: pathlib.Path) -> bytes:
    fields = parse_fields(path, "OTPKEY1")
    if "secret" not in fields or fields.get("kind") != "key":
        raise SlotError(f"不是密钥文件: {path.name}")
    return decrypt_fields(fields, fields["secret"])


def write_secret(path: pathlib.Path, data: bytes) -> None:
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "wb") as fh:
        fh.write(data)
        fh.flush()
        os.fsync(fh.fileno())


def cmd_enroll(args: argparse.Namespace) -> int:
    if args.dir:
        directory = pathlib.Path(args.dir).expanduser()
    else:
        directory = pathlib.Path.cwd()
    created = not directory.exists()
    directory.mkdir(parents=True, exist_ok=True)
    if created:
        directory.chmod(0o700)
    count = args.count
    if count is None:
        entered = input("生成几条 [10]: ").strip()
        count = int(entered) if entered else 10
    if count < 1 or count > 50:
        print("条数要在 1 到 50 之间。", file=sys.stderr)
        return 1
    try:
        first = read_tty_line("卷口令（只在这台电脑上输入，不会写入明文）: ")
        second = read_tty_line("再输入一次卷口令: ")
    except SlotError as exc:
        print(str(exc), file=sys.stderr)
        return 1
    if not first or first != second:
        print("两次不一致，或口令是空的。没有写槽。", file=sys.stderr)
        return 1
    if "\n" in first or "\0" in first:
        print("口令里不能有换行。", file=sys.stderr)
        return 1
    password = first.encode("utf-8")
    if args.pin is not None and args.keyfile:
        print("--pin 和 --keyfile 只能选一个。", file=sys.stderr)
        return 1
    if args.pin is not None and not 8 <= args.pin <= 20:
        print("PIN 位数要在 8 到 20。", file=sys.stderr)
        return 1
    print()
    print(f"目录: {directory}")
    print("每一条只能成功使用一次。生成几条就能用几次，用掉一条只删那一条。")
    if args.keyfile:
        paths = [new_keyfile(directory, password) for _ in range(count)]
        print("密钥文件里已经带了解开材料，不用再输入。先放在这里，之后剪到槽目录；挂载时会用掉一个并删除。")
        print()
        for i, path in enumerate(paths, 1):
            print(f"  {i:>2}  {path.name}")
        print()
        return 0
    if args.pin is not None:
        pins = [new_pin(directory, password, args.pin) for _ in range(count)]
        print("PIN 只显示这一次，不写入文件。挂载时输入数字即可。")
        if args.pin < 12:
            print("位数较短。槽目录若被整份拷走，这串数字有可能被试出来。")
        print()
        for i, pin in enumerate(pins, 1):
            shown = "-".join(pin[i : i + 4] for i in range(0, len(pin), 4))
            print(f"  {i:>2}  {shown}")
        print()
        return 0
    codes = [new_slot(directory, password) for _ in range(count)]
    print("长码只显示这一次，不写入文件。挂载成功后删除对应的那一个槽。")
    print()
    for i, code in enumerate(codes, 1):
        print(f"  {i:>2}  {code}")
    print()
    return 0


def cmd_unlock(args: argparse.Namespace) -> int:
    directory = pathlib.Path(args.dir).expanduser()
    if not directory.is_dir():
        print(f"槽目录不存在: {directory}", file=sys.stderr)
        return 1
    try:
        if args.code_file:
            code = pathlib.Path(args.code_file).read_text(encoding="utf-8")
        else:
            code = read_tty_line("一次性码或 PIN: ")
        if pin_digits(code):
            password, slot = unlock_pin(directory, code)
        else:
            password, slot = unlock(directory, code)
    except SlotError as exc:
        print(str(exc), file=sys.stderr)
        return 1
    write_secret(pathlib.Path(args.pass_file), password)
    write_secret(pathlib.Path(args.slot_file), str(slot).encode("utf-8"))
    return 0


def cmd_classify(args: argparse.Namespace) -> int:
    """0：长码，并把槽编号打到标准输出。3：PIN。2：当作普通卷口令。"""
    data = pathlib.Path(args.secret_file).read_bytes()
    if not data or b"\n" in data or b"\0" in data:
        return 2
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        return 2
    if pin_digits(text):
        return 3
    try:
        raw = normalize(text)
    except SlotError:
        return 2
    print(raw[:ID_LEN])
    return 0


def cmd_use_key(args: argparse.Namespace) -> int:
    path = pathlib.Path(args.file).expanduser()
    try:
        password = open_keyfile(path)
    except SlotError as exc:
        print(str(exc), file=sys.stderr)
        return 1
    write_secret(pathlib.Path(args.pass_file), password)
    write_secret(pathlib.Path(args.slot_file), str(path.resolve()).encode("utf-8"))
    return 0


def _forward(chunk: bytes, secret: bytes) -> None:
    if secret:
        chunk = chunk.replace(secret, b"")
        chunk = chunk.replace(secret + b"\n", b"")
    if chunk:
        os.write(1, chunk)


def feed_tty(cmd: list[str], secret: bytes, timeout: float) -> int:
    import fcntl
    import pty
    import termios

    if not cmd:
        raise SlotError("没有要执行的命令。")
    master, slave = pty.openpty()
    pid = os.fork()
    if pid == 0:
        try:
            os.close(master)
            os.setsid()
            fcntl.ioctl(slave, termios.TIOCSCTTY, 0)
            os.dup2(slave, 0)
            os.dup2(slave, 1)
            os.dup2(slave, 2)
            if slave > 2:
                os.close(slave)
            os.execvp(cmd[0], cmd)
        except Exception as exc:
            try:
                os.write(2, f"无法执行 {' '.join(cmd)}: {exc}\n".encode())
            except Exception:
                pass
            os._exit(127)
    os.close(slave)
    flags = fcntl.fcntl(master, fcntl.F_GETFL)
    fcntl.fcntl(master, fcntl.F_SETFL, flags | os.O_NONBLOCK)
    window = b""
    sent = False
    deadline = time.monotonic() + timeout
    status = None
    try:
        while True:
            if status is None:
                wpid, st = os.waitpid(pid, os.WNOHANG)
                if wpid == pid:
                    status = st
            remaining = deadline - time.monotonic()
            if status is None and remaining <= 0:
                os.kill(pid, signal.SIGTERM)
                time.sleep(0.2)
                try:
                    os.kill(pid, signal.SIGKILL)
                except OSError:
                    pass
                os.waitpid(pid, 0)
                print("等待口令提示超时，已停掉解密程序。", file=sys.stderr)
                return 124
            wait = 0.2 if status is None else 0
            readable, _, _ = select.select([master], [], [], wait)
            if readable:
                try:
                    chunk = os.read(master, 4096)
                except OSError:
                    chunk = b""
                if chunk:
                    _forward(chunk, secret)
                    window = (window + chunk)[-200:]
                    folded = window.lower()
                    if not sent and any(p in folded for p in PROMPTS):
                        os.write(master, secret + b"\n")
                        sent = True
                        window = b""
                elif status is not None:
                    break
            elif status is not None:
                break
    finally:
        try:
            os.close(master)
        except OSError:
            pass
    if status is None:
        _, status = os.waitpid(pid, 0)
    if os.WIFEXITED(status):
        return os.WEXITSTATUS(status)
    return 1


def cmd_feed(args: argparse.Namespace) -> int:
    secret = pathlib.Path(args.password_file).read_bytes()
    if not secret or b"\n" in secret or b"\0" in secret:
        print("准备交给解密程序的口令是空的，或含换行。", file=sys.stderr)
        return 1
    command = list(args.command)
    if command[:1] == ["--"]:
        command = command[1:]
    if not command:
        print("feed 后面要跟要执行的命令。", file=sys.stderr)
        return 2
    try:
        return feed_tty(command, secret, args.timeout)
    except SlotError as exc:
        print(str(exc), file=sys.stderr)
        return 1


def selftest() -> int:
    import tempfile

    password = "p@ss 测试-口令".encode("utf-8")
    with tempfile.TemporaryDirectory() as tmp:
        directory = pathlib.Path(tmp)
        code = new_slot(directory, password)
        path = directory / f"slot-{normalize(code)[:ID_LEN]}"
        text = path.read_text(encoding="ascii")
        if password.decode("utf-8") in text or normalize(code) in text or code in text:
            print("槽文件里出现了口令或码", file=sys.stderr)
            return 1
        got, got_path = unlock(directory, code.lower().replace("-", " "))
        if got != password or got_path != path:
            print("解开的口令不对", file=sys.stderr)
            return 1
        try:
            unlock(directory, format_code("0" * CODE_LEN))
        except SlotError:
            pass
        else:
            print("错误的码不应该解开", file=sys.stderr)
            return 1
        fields = read_fields(path)
        fields["ct"] = b64e(b64d(fields["ct"])[:-1] + bytes([b64d(fields["ct"])[-1] ^ 1]))
        path.write_text(
            "\n".join(
                [
                    VERSION,
                    f"id={fields['id']}",
                    f"iter={fields['iter']}",
                    f"salt={fields['salt']}",
                    f"iv={fields['iv']}",
                    f"ct={fields['ct']}",
                    f"mac={fields['mac']}",
                    "",
                ]
            ),
            encoding="ascii",
        )
        try:
            unlock(directory, code)
        except SlotError:
            pass
        else:
            print("改过的槽不应该解开", file=sys.stderr)
            return 1

    out = pathlib.Path(tempfile.mkstemp()[1])
    child = (
        "import os,sys\n"
        "os.write(2, b'Enter the user password: ')\n"
        "sys.stderr.flush()\n"
        "data = os.read(0, 256)\n"
        f"open({str(out)!r}, 'wb').write(data)\n"
    )
    secret = b"feed-secret"
    try:
        rc = feed_tty([sys.executable, "-c", child], secret, 5)
        data = out.read_bytes()
    finally:
        out.unlink(missing_ok=True)
    if rc != 0 or data != secret + b"\n":
        print(f"feed 失败 rc={rc} data={data!r}", file=sys.stderr)
        return 1
    try:
        normalize("hello-password")
    except SlotError:
        pass
    else:
        print("普通口令不应该被当成一次性码", file=sys.stderr)
        return 1
    with tempfile.TemporaryDirectory() as tmp:
        directory = pathlib.Path(tmp)
        pin = new_pin(directory, password, 8)
        slot_text = next(directory.glob("slot-*")).read_text(encoding="ascii")
        if pin in slot_text:
            print("PIN 写进了槽文件", file=sys.stderr)
            return 1
        got, _ = unlock_pin(directory, "-".join(pin[i : i + 4] for i in range(0, 8, 4)))
        if got != password:
            print("PIN 解开的口令不对", file=sys.stderr)
            return 1
        try:
            unlock_pin(directory, "00000000")
        except SlotError:
            pass
        else:
            print("错误 PIN 不应该解开", file=sys.stderr)
            return 1
        key_path = new_keyfile(directory, password)
        key_text = key_path.read_text(encoding="ascii")
        if password.decode("utf-8") in key_text:
            print("密钥文件里出现了卷口令", file=sys.stderr)
            return 1
        if open_keyfile(key_path) != password:
            print("密钥文件解开的口令不对", file=sys.stderr)
            return 1
    print("selftest ok")
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="一次性码槽：生成、解开、把口令喂给解密程序的终端。")
    sub = parser.add_subparsers(dest="cmd", required=True)

    enroll = sub.add_parser("enroll", help="在自己电脑上生成槽和一次性码")
    enroll.add_argument("dir", nargs="?", help="槽目录。不写就生成在当前文件夹，之后再剪走")
    enroll.add_argument("--count", type=int, help="条数，默认询问，直接回车是 10")
    enroll.add_argument("--pin", nargs="?", const=8, type=int, help="生成数字 PIN，默认 8 位，可写 8 到 20")
    enroll.add_argument("--keyfile", action="store_true", help="生成密钥文件，挂载时放进槽目录即可，不用输入")
    enroll.set_defaults(func=cmd_enroll)

    unlock_p = sub.add_parser("unlock", help="用一次性码解开一个槽")
    unlock_p.add_argument("--dir", required=True)
    unlock_p.add_argument("--pass-file", required=True)
    unlock_p.add_argument("--slot-file", required=True)
    unlock_p.add_argument("--code-file", help="已读好的一次性码文件；不设则在终端询问")
    unlock_p.set_defaults(func=cmd_unlock)

    classify = sub.add_parser("classify", help="判断输入是长码、PIN 还是卷口令")
    classify.add_argument("--secret-file", required=True)
    classify.set_defaults(func=cmd_classify)

    use_key = sub.add_parser("use-key", help="用密钥文件解开卷口令")
    use_key.add_argument("--file", required=True)
    use_key.add_argument("--pass-file", required=True)
    use_key.add_argument("--slot-file", required=True)
    use_key.set_defaults(func=cmd_use_key)

    feed = sub.add_parser("feed", help="在伪终端里运行命令，看到口令提示再写入口令")
    feed.add_argument("--password-file", required=True)
    feed.add_argument("--timeout", type=float, default=90)
    feed.add_argument("command", nargs=argparse.REMAINDER)
    feed.set_defaults(func=cmd_feed)

    sub.add_parser("selftest").set_defaults(func=lambda _args: selftest())

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except SlotError as exc:
        print(str(exc), file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("\n已取消。", file=sys.stderr)
        return 130


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

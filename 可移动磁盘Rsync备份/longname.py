#!/usr/bin/env python3
# 跨文件系统长文件名处理（仅标准库）。
# - 保守阈值（默认比 NAME_MAX 更严），避免漏网
# - 支持保留文件名前部(head)或后部(tail)
# - 可从 rsync 日志补抓 File name too long
from __future__ import annotations

import argparse
import hashlib
import os
import re
import shutil
import sys
from pathlib import Path


MAP_DIR = ".rsync-longnames"
MAP_NAME = "map.tsv"
PROTECT_NAME = "protect.filter"
EXCLUDE_NAME = "src.exclude"

# 可移动盘上 PC_NAME_MAX=255 仍可能对 UTF-8 中文更严；默认再留余量
DEFAULT_SAFE_MAX = 180
DEFAULT_SAFE_PATH = 900  # 整段绝对路径字节上限（过长同样 ENAMETOOLONG）


def utf8_len(s: str) -> int:
    return len(s.encode("utf-8"))


def detect_name_max(path: str) -> int:
    p = Path(path)
    p.mkdir(parents=True, exist_ok=True)
    try:
        n = os.pathconf(p, "PC_NAME_MAX")
        if isinstance(n, int) and n > 0:
            return n
    except (OSError, ValueError, AttributeError):
        pass
    return 255


def effective_limits(dst: str, limit_arg: int, path_arg: int, safe_max: int, safe_path: int) -> tuple[int, int]:
    detected = detect_name_max(dst)
    if limit_arg > 0:
        name_lim = limit_arg
    else:
        name_lim = min(detected, safe_max if safe_max > 0 else detected)
    path_lim = path_arg if path_arg > 0 else (safe_path if safe_path > 0 else 0)
    return name_lim, path_lim


def shorten_component(name: str, limit: int, keep: str = "head") -> str:
    """单个路径分量压到 <= limit 字节。keep=head 留前部；keep=tail 留后部（靠近扩展名）。"""
    if utf8_len(name) <= limit:
        return name
    stem, ext = os.path.splitext(name)
    digest = hashlib.sha1(name.encode("utf-8")).hexdigest()[:8]
    mid = f"_{digest}"
    # head: 前缀 + _hash + ext
    # tail: _hash + 后缀 + ext
    if keep == "tail":
        prefix = mid
        # 从 stem 尾部往前取
        budget = limit - utf8_len(prefix) - utf8_len(ext)
        if budget <= 0:
            raw = digest
            out = ""
            for ch in raw:
                if utf8_len(out + ch + ext) > limit:
                    break
                out += ch
            return out + ext if out else digest[:16]
        tail = ""
        for ch in reversed(stem):
            if utf8_len(ch + tail) > budget:
                break
            tail = ch + tail
        if not tail:
            tail = digest[: min(6, budget)]
        return prefix + tail + ext

    # head（默认）
    suffix = mid + ext
    suffix_len = utf8_len(suffix)
    if suffix_len >= limit:
        raw = digest
        out = ""
        for ch in raw:
            if utf8_len(out + ch) > limit:
                break
            out += ch
        return out or digest[:16]
    budget = limit - suffix_len
    head = ""
    for ch in stem:
        if utf8_len(head + ch) > budget:
            break
        head += ch
    if not head:
        head = digest[: min(6, budget)] if budget > 0 else ""
    return head + suffix


def map_rel_path(
    rel: str,
    name_limit: int,
    keep: str = "head",
    path_limit: int = 0,
    dest_root: Path | None = None,
) -> tuple[str, bool]:
    parts = Path(rel).parts
    if parts[:1] == ("/",):
        parts = parts[1:]
    changed = False
    out: list[str] = []
    for part in parts:
        if part in ("", ".", ".."):
            out.append(part)
            continue
        new = shorten_component(part, name_limit, keep=keep)
        if new != part:
            changed = True
        out.append(new)
    dest_rel = str(Path(*out)) if out else ""

    # 整路径过长：继续压低 name_limit 重算
    if path_limit > 0 and dest_root is not None and dest_rel:
        lim = name_limit
        full = str(dest_root / dest_rel)
        while utf8_len(full) > path_limit and lim > 48:
            lim = max(48, lim - 24)
            dest_rel, _ = map_rel_path(rel, lim, keep=keep, path_limit=0, dest_root=None)
            full = str(dest_root / dest_rel)
            changed = True
    return dest_rel, changed


def needs_shorten(rel: str, name_limit: int, path_limit: int, dest_root: Path) -> bool:
    for part in Path(rel).parts:
        if part in ("", ".", ".."):
            continue
        if utf8_len(part) > name_limit:
            return True
    if path_limit > 0:
        # 用「原名」拼目标绝对路径预估
        if utf8_len(str(dest_root / rel)) > path_limit:
            return True
    return False


def iter_files(src_root: Path):
    skip_dirs = {MAP_DIR, ".rsync-partial", ".rsync-logs"}
    for dirpath, dirnames, filenames in os.walk(src_root):
        dirnames[:] = [d for d in dirnames if d not in skip_dirs]
        base = Path(dirpath)
        for name in filenames:
            p = base / name
            try:
                rel = p.relative_to(src_root).as_posix()
            except ValueError:
                continue
            yield p, rel


def build_plan(
    src_root: Path,
    dest_root: Path,
    name_limit: int,
    keep: str,
    path_limit: int,
    extra_rels: list[str] | None = None,
) -> list[tuple[str, str]]:
    seen: set[str] = set()
    file_plan: list[tuple[str, str]] = []

    def add(rel: str) -> None:
        if rel in seen:
            return
        if not needs_shorten(rel, name_limit, path_limit, dest_root):
            # extra_rels 来自日志：强制缩短
            if not (extra_rels and rel in extra_rels):
                return
        dest_rel, _ = map_rel_path(rel, name_limit, keep=keep, path_limit=path_limit, dest_root=dest_root)
        if dest_rel == rel and not (extra_rels and rel in extra_rels):
            return
        if dest_rel == rel and extra_rels and rel in extra_rels:
            # 强制再压一档
            dest_rel, _ = map_rel_path(
                rel, max(64, name_limit - 40), keep=keep, path_limit=path_limit, dest_root=dest_root
            )
        seen.add(rel)
        file_plan.append((rel, dest_rel))

    for _, rel in iter_files(src_root):
        add(rel)
    if extra_rels:
        for rel in extra_rels:
            add(rel)

    file_plan.sort(key=lambda x: x[0])
    return file_plan


def write_exclude(plan: list[tuple[str, str]], path: Path) -> None:
    lines = ["/" + src_rel for src_rel, _ in plan]
    path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")


def write_protect(plan: list[tuple[str, str]], path: Path) -> None:
    lines = [f"P /{dest_rel}" for _, dest_rel in plan]
    lines.append(f"P /{MAP_DIR}")
    lines.append(f"P /{MAP_DIR}/***")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_map(plan: list[tuple[str, str]], path: Path) -> None:
    rows = ["# dest_rel\tsrc_rel"]
    for src_rel, dest_rel in plan:
        rows.append(f"{dest_rel}\t{src_rel}")
    path.write_text("\n".join(rows) + "\n", encoding="utf-8")


def read_map(path: Path) -> list[tuple[str, str]]:
    if not path.is_file():
        return []
    out = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) != 2:
            continue
        dest_rel, src_rel = parts
        out.append((dest_rel, src_rel))
    return out


def merge_maps(old: list[tuple[str, str]], new: list[tuple[str, str]]) -> list[tuple[str, str]]:
    """合并映射；条目均为 (dest_rel, src_rel)，以 src_rel 为键，new 覆盖 old。"""
    m = {src: dest for dest, src in old}
    for dest, src in new:
        m[src] = dest
    return sorted(((dest, src) for src, dest in m.items()), key=lambda x: x[1])


def copy_file(src: Path, dst: Path, dry_run: bool) -> None:
    if dry_run:
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst, follow_symlinks=False)


def parse_nametoolong_from_log(log_text: str, dest_root: Path) -> list[str]:
    """从 rsync 日志抽出因 File name too long 失败的目标相对路径，再还原为「源相对路径」候选。"""
    dest_root = dest_root.resolve()
    prefix = str(dest_root).rstrip("/") + "/"
    rels: list[str] = []
    # failed to stat "PATH": File name too long
    for m in re.finditer(r'failed to stat "([^"]+)": File name too long', log_text):
        full = m.group(1)
        if full.startswith(prefix):
            rels.append(full[len(prefix) :])
        else:
            # 尝试相对
            try:
                rels.append(str(Path(full).resolve().relative_to(dest_root)))
            except Exception:
                pass
    # 去重保序
    seen = set()
    out = []
    for r in rels:
        r = r.lstrip("/")
        if r not in seen:
            seen.add(r)
            out.append(r)
    return out


def _common_args(p: argparse.ArgumentParser) -> None:
    p.add_argument("--limit", type=int, default=0, help="单分量上限；0=自动(检测与安全值取小)")
    p.add_argument("--path-limit", type=int, default=0, help="绝对路径上限；0=用安全默认")
    p.add_argument("--safe-max", type=int, default=DEFAULT_SAFE_MAX, help="相对 NAME_MAX 的保守上限")
    p.add_argument("--safe-path", type=int, default=DEFAULT_SAFE_PATH, help="绝对路径保守上限")
    p.add_argument(
        "--keep",
        choices=("head", "tail"),
        default=os.environ.get("LONGNAME_KEEP", "head"),
        help="head=保留文件名前部；tail=保留后部(靠近扩展名)",
    )


def cmd_prepare(args: argparse.Namespace) -> int:
    src = Path(args.src).resolve()
    dst = Path(args.dst).resolve()
    name_lim, path_lim = effective_limits(str(dst), args.limit, args.path_limit, args.safe_max, args.safe_path)
    work = dst / MAP_DIR
    work.mkdir(parents=True, exist_ok=True)

    plan = build_plan(src, dst, name_lim, args.keep, path_lim)
    # 合并旧 map，避免丢历史
    old = read_map(work / MAP_NAME)
    if old:
        # old is (dest, src); build_plan is (src, dest)
        merged = merge_maps(old, [(d, s) for s, d in plan])
        plan = [(src_rel, dest_rel) for dest_rel, src_rel in merged]

    write_exclude([(s, d) for s, d in plan], work / EXCLUDE_NAME)
    write_protect([(s, d) for s, d in plan], work / PROTECT_NAME)
    write_map([(s, d) for s, d in plan], work / MAP_NAME)

    print(f"NAME_MAX={name_lim}")
    print(f"PATH_LIMIT={path_lim}")
    print(f"KEEP={args.keep}")
    print(f"LONG_FILES={len(plan)}")
    print(f"EXCLUDE={work / EXCLUDE_NAME}")
    print(f"PROTECT={work / PROTECT_NAME}")
    print(f"MAP={work / MAP_NAME}")
    if args.verbose and plan:
        show = plan[:30]
        for s, d in show:
            print(f"  {s}")
            print(f"    -> {d}")
        if len(plan) > 30:
            print(f"  ... 还有 {len(plan) - 30} 个")
    return 0


def cmd_apply_backup(args: argparse.Namespace) -> int:
    src = Path(args.src).resolve()
    dst = Path(args.dst).resolve()
    name_lim, path_lim = effective_limits(str(dst), args.limit, args.path_limit, args.safe_max, args.safe_path)
    work = dst / MAP_DIR
    work.mkdir(parents=True, exist_ok=True)

    extra: list[str] = []
    if args.from_log:
        log_text = Path(args.from_log).read_text(encoding="utf-8", errors="replace")
        extra = parse_nametoolong_from_log(log_text, dst)
        print(f"SALVAGE_FROM_LOG={len(extra)}")

    plan = build_plan(src, dst, name_lim, args.keep, path_lim, extra_rels=extra or None)
    old = read_map(work / MAP_NAME)
    if old:
        merged = merge_maps(old, [(d, s) for s, d in plan])
        plan = [(src_rel, dest_rel) for dest_rel, src_rel in merged]

    write_exclude(plan, work / EXCLUDE_NAME)
    write_protect(plan, work / PROTECT_NAME)
    write_map(plan, work / MAP_NAME)

    n_ok = 0
    n_fail = 0
    for src_rel, dest_rel in plan:
        s = src / src_rel
        d = dst / dest_rel
        try:
            if not s.is_file() and not s.is_symlink():
                # 日志里的路径若源已不存在则跳过
                if not s.exists():
                    print(f"[!] 源不存在，跳过: {src_rel}", file=sys.stderr)
                    n_fail += 1
                continue
            for part in Path(dest_rel).parts:
                if utf8_len(part) > name_lim:
                    raise OSError(f"shorten failed for {part!r}")
            if args.dry_run:
                print(f"DRY {src_rel} -> {dest_rel}")
            else:
                copy_file(s, d, dry_run=False)
            n_ok += 1
        except OSError as e:
            print(f"[x] {src_rel}: {e}", file=sys.stderr)
            n_fail += 1

    print(f"LONGNAME_COPIED={n_ok}")
    print(f"LONGNAME_FAILED={n_fail}")
    return 0


def cmd_apply_restore(args: argparse.Namespace) -> int:
    backup = Path(args.src).resolve()
    dest = Path(args.dst).resolve()
    name_lim, path_lim = effective_limits(str(dest), args.limit, args.path_limit, args.safe_max, args.safe_path)
    map_path = backup / MAP_DIR / MAP_NAME
    plan = read_map(map_path)
    if not plan:
        print("LONGNAME_RESTORE=0")
        return 0

    n_ok = 0
    n_short = 0
    n_fail = 0
    for dest_rel, src_rel in plan:
        s = backup / dest_rel
        if not s.exists():
            s2 = backup / src_rel
            s = s2 if s2.exists() else s
        if not s.exists():
            print(f"[!] 备份中找不到: {dest_rel}", file=sys.stderr)
            n_fail += 1
            continue

        original_ok = not needs_shorten(src_rel, name_lim, path_lim, dest)
        target_rel = (
            src_rel
            if original_ok
            else map_rel_path(src_rel, name_lim, keep=args.keep, path_limit=path_lim, dest_root=dest)[0]
        )
        d = dest / target_rel
        try:
            if args.dry_run:
                print(f"DRY restore {s} -> {d}")
            else:
                copy_file(s, d, dry_run=False)
                if original_ok and target_rel != dest_rel:
                    short_on_dest = dest / dest_rel
                    if short_on_dest.exists() and short_on_dest.resolve() != d.resolve():
                        try:
                            short_on_dest.unlink()
                        except OSError:
                            pass
            if original_ok:
                n_ok += 1
            else:
                n_short += 1
        except OSError as e:
            print(f"[x] restore {src_rel}: {e}", file=sys.stderr)
            n_fail += 1

    print(f"LONGNAME_RESTORED_ORIGINAL={n_ok}")
    print(f"LONGNAME_RESTORED_SHORT={n_short}")
    print(f"LONGNAME_FAILED={n_fail}")
    return 0


def cmd_name_max(args: argparse.Namespace) -> int:
    print(detect_name_max(args.path))
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="rsync 长文件名自动缩短/还原")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p0 = sub.add_parser("name-max", help="探测目录 NAME_MAX")
    p0.add_argument("path")
    p0.set_defaults(func=cmd_name_max)

    p1 = sub.add_parser("prepare", help="扫描并生成 exclude/protect/map")
    p1.add_argument("src")
    p1.add_argument("dst")
    _common_args(p1)
    p1.add_argument("--verbose", "-v", action="store_true")
    p1.set_defaults(func=cmd_prepare)

    p2 = sub.add_parser("apply-backup", help="把超长名文件拷到目标（缩短后）")
    p2.add_argument("src")
    p2.add_argument("dst")
    _common_args(p2)
    p2.add_argument("--dry-run", action="store_true")
    p2.add_argument("--from-log", default="", help="从 rsync 日志补抓 File name too long")
    p2.set_defaults(func=cmd_apply_backup)

    p3 = sub.add_parser("apply-restore", help="按 map 恢复原名（若目标允许）")
    p3.add_argument("src", help="备份根目录")
    p3.add_argument("dst", help="恢复目标")
    _common_args(p3)
    p3.add_argument("--dry-run", action="store_true")
    p3.set_defaults(func=cmd_apply_restore)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())

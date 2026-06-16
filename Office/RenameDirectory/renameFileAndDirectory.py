#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys

# ===== 内部参数 =====
rulesFile = "1.txt"           # 规则文件
MatchMode = 0                 # 0=规则文件指定，1=精确，2=模糊，3=替换
MatchObj = 0                  # 0=all，1=file，2=dir
encludeHinddenFile = True     # 是否包含隐藏文件
includeExtension = None       # 仅匹配这些扩展名时包含扩展名，空列表或None表示不包含
exclude = ["__pycache__", "1.txt"]
exclude_str = None
logFile = "log.txt"           # 日志文件

# ===== 控制参数 =====
doRename = True              # 是否实际重命名
doRecursive = True            # 是否递归子目录
verbose = True                # 是否打印调试信息

# 红色输出
def red(text):
    return f"\033[31m{text}\033[0m"

# 写日志
def write_log(message):
    with open(logFile, "a", encoding="utf-8") as f:
        f.write(message + "\n")


def load_rules(filename):
    rules = []
    if not os.path.exists(filename):
        return rules
    with open(filename, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) < 2:
                continue
            src = parts[0].strip()
            dst = parts[1].strip()
            mode = MatchMode if MatchMode != 0 else (int(parts[2]) if len(parts) >= 3 else 1)
            rules.append((src, dst, mode))
    return rules


def should_skip(name, path):
    if name in exclude:
        return True
    if exclude_str and exclude_str in name:
        return True
    if not encludeHinddenFile and name.startswith("."):
        return True
    return False


def apply_rule(name, rule):
    src, dst, mode = rule
    base, ext = os.path.splitext(name)
    
    # 判断是否包含扩展名
    if includeExtension and ext.lower() in [e.lower() for e in includeExtension]:
        target = name
    else:
        target = base

    # 整名替换优先
    if mode == 3 and src in target:
        return dst + (ext if not includeExtension else "")

    if mode == 1 and target == src:  # 精确匹配
        return dst + (ext if not includeExtension else "")
    elif mode == 2 and src in target:  # 包含匹配
        return target.replace(src, dst) + (ext if not includeExtension else "")
    return None


def process_dir(path, rules):
    for entry in os.scandir(path):
        if should_skip(entry.name, entry.path):
            continue
        if MatchObj == 1 and entry.is_dir():
            if doRecursive:
                process_dir(entry.path, rules)
            continue
        if MatchObj == 2 and entry.is_file():
            continue

        new_name = None
        rule_applied = None
        for idx, rule in enumerate(rules, 1):
            result = apply_rule(entry.name, rule)
            if result:
                new_name = result
                rule_applied = (idx, rule)
                break

        if new_name and new_name != entry.name:
            new_path = os.path.join(path, new_name)
            if os.path.exists(new_path):
                msg = f"[跳过] {entry.path} -> {new_path} 已存在 (规则 {rule_applied[0]}: {rule_applied[1]})"
                if verbose:
                    print(red(msg))
                write_log(msg)
                continue

            msg = f"{'[执行]' if doRename else '[预览]'} {entry.path} -> {new_path} (规则 {rule_applied[0]}: {rule_applied[1]})"
            if verbose:
                print(msg)
            write_log(msg)

            if doRename:
                os.rename(entry.path, new_path)

        if entry.is_dir() and doRecursive:
            process_dir(entry.path, rules)


def main():
    # 清空日志文件
    open(logFile, "w", encoding="utf-8").close()

    rules = load_rules(rulesFile)
    if not rules:
        print("未加载到任何规则。")
        return
    process_dir(os.getcwd(), rules)


if __name__ == "__main__":
    main()


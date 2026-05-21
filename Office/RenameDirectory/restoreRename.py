#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os

logFile = "log.txt"

def main():
    if not os.path.exists(logFile):
        print("日志文件不存在")
        return

    with open(logFile, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith("[执行]") or line.startswith("[预览]"):
                try:
                    parts = line.split(" -> ")
                    old_path = parts[0].split("] ")[1]
                    new_path = parts[1].split(" (规则")[0]
                    if os.path.exists(new_path):
                        os.rename(new_path, old_path)
                        print(f"已恢复: {new_path} -> {old_path}")
                except Exception as e:
                    print(f"恢复失败: {line}, 错误: {e}")

if __name__ == "__main__":
    main()

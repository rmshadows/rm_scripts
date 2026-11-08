#!/bin/bash
# 在自己的电脑上生成一次性挂载脚本和 U 盘密钥文件。不要在同事电脑上运行本文件。
# 本目录只放生成器。VeraCrypt 的相对路径写在 config.sh 的 veraRel。
# 这台电脑需要 python3 和 gcc。同事电脑不需要 python。
#   ./mk-once.sh                 按 config.sh 默认生成（expireDays/pinDigits/pinNumeric）
#   ./mk-once.sh -2              生成 2 组，每组一个临时口令和一对文件
#   ./mk-once.sh --days 7        7 天后过期（覆盖 expireDays）
#   ./mk-once.sh -2 /未加密分区/目录
# 每组是 once-*.sh 和 once-key-*。把 once-key-* 剪到 U 盘根目录。

HERE="$(cd "$(dirname "$0")" && pwd)"
CALLER="$(pwd)"
cd "$HERE" || exit 1
if ! command -v python3 >/dev/null 2>&1; then
  echo "需要 python3。" >&2
  exit 1
fi
exec python3 ./mk-once.py --caller "$CALLER" "$@"

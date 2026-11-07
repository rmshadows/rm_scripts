#!/bin/bash
# 在自己的电脑上生成一次性凭证。不要在同事电脑上跑。
# 每条只能成功使用一次。--count 是条数，默认 10。
# 不写目录就生成在当前文件夹，之后再剪走。写了目录就生成到那里。
#   ./enroll.sh                                 长码，当前文件夹
#   ./enroll.sh --pin                           8 位数字
#   ./enroll.sh --pin 16                        16 位数字
#   ./enroll.sh --keyfile                       密钥文件
#   ./enroll.sh /媒体/U盘/slots --pin           直接生成到指定目录

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! command -v python3 >/dev/null 2>&1; then
  echo "需要 python3。" >&2
  exit 1
fi
if ! command -v openssl >/dev/null 2>&1; then
  echo "需要 openssl。" >&2
  exit 1
fi
exec python3 "$DIR/slot.py" enroll "$@"

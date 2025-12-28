#!/usr/bin/env bash

############################################
# aria2 archive.org download script
# - proxy is OPTIONAL (default OFF)
# - works with Debian aria2 (no SOCKS)
############################################

### ====== 基本设置 ======

# 包含下载链接的文件（每行一个 URL）
URL_FILE="urls.txt"

# 下载保存目录
DOWNLOAD_DIR="./aria2c_d"

# 同时下载的文件数
MAX_CONCURRENT_DOWNLOADS=3

# 单文件连接数
CONNECTIONS_PER_FILE=8

# 分片数（通常与连接数一致）
SPLIT_COUNT=8

# 最小分片大小（archive.org 推荐 >=5M）
MIN_SPLIT_SIZE="5M"

# 日志文件
LOG_FILE="aria2.log"


### ====== 代理设置（可选） ======

# 是否启用代理：true / false
USE_PROXY=true

# 仅支持 HTTP/HTTPS 代理（如 privoxy）
HTTP_PROXY="127.0.0.1:20171"


### ====== 前置检查 ======

if ! command -v aria2c >/dev/null 2>&1; then
  echo "[ERROR] aria2c not found. Please install it first."
  exit 1
fi

if [ ! -f "$URL_FILE" ]; then
  echo "[ERROR] $URL_FILE not found."
  exit 1
fi

mkdir -p "$DOWNLOAD_DIR"


### ====== 构建 aria2 命令 ======

ARIA2_CMD=(
  aria2c
  --input-file="$URL_FILE"
  --dir="$DOWNLOAD_DIR"
  --continue=true
  --auto-file-renaming=false
  --summary-interval=30
  --log="$LOG_FILE"
  --log-level=notice
  --max-concurrent-downloads="$MAX_CONCURRENT_DOWNLOADS"
  --split="$SPLIT_COUNT"
  --min-split-size="$MIN_SPLIT_SIZE"
  -x "$CONNECTIONS_PER_FILE"
  -s "$SPLIT_COUNT"
)

# 如果启用代理，则追加 HTTP/HTTPS proxy
if [ "$USE_PROXY" = true ]; then
  ARIA2_CMD+=(
    --http-proxy="$HTTP_PROXY"
    --https-proxy="$HTTP_PROXY"
  )
fi


### ====== 执行 ======

echo "===================================="
echo "Starting aria2 download"
echo "Download dir : $DOWNLOAD_DIR"
echo "Use proxy    : $USE_PROXY"
echo "===================================="

"${ARIA2_CMD[@]}"


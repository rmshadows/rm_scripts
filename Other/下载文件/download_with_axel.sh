#!/usr/bin/env bash

############################################################
# Axel Download Script (for large HTTP/HTTPS files)
#
# Features:
# - Parameterized (easy to tweak)
# - Supports optional HTTP proxy
# - Suitable for archive.org direct file downloads
#
# Notes:
# - Axel is NOT ideal for massive batch downloads
# - Network instability may cause failures
############################################################


########################
# ===== 基础配置 ===== #
########################

# 下载链接文件（每行一个 URL）
URL_FILE="urls.txt"

# 下载保存目录
DOWNLOAD_DIR="./axel_d"

# 单个文件的最大连接数
# ⚠ 不建议太大，archive.org 通常 4~8 就够
CONNECTIONS=6

# 单个文件最大重试次数
RETRIES=5

# 是否继续未完成的下载（true / false）
RESUME=true

# 是否显示进度条（true / false）
SHOW_PROGRESS=true


########################
# ===== 代理设置 ===== #
########################

# 是否启用代理
USE_PROXY=false

# 仅支持 HTTP 代理（axel 不支持 SOCKS）
HTTP_PROXY="http://127.0.0.1:8118"


########################
# ===== 前置检查 ===== #
########################

# 检查 axel 是否安装
if ! command -v axel >/dev/null 2>&1; then
  echo "[ERROR] axel not found. Please install it first:"
  echo "        sudo apt install axel"
  exit 1
fi

# 检查 URL 文件
if [ ! -f "$URL_FILE" ]; then
  echo "[ERROR] $URL_FILE not found."
  exit 1
fi

# 创建下载目录
mkdir -p "$DOWNLOAD_DIR"


########################
# ===== 构建参数 ===== #
########################

AXEL_OPTS=(
  -n "$CONNECTIONS"     # 连接数
  -r "$RETRIES"         # 重试次数
)

# 断点续传
if [ "$RESUME" = true ]; then
  AXEL_OPTS+=(-c)
fi

# 进度显示
if [ "$SHOW_PROGRESS" = false ]; then
  AXEL_OPTS+=(-q)
fi

# HTTP 代理（可选）
if [ "$USE_PROXY" = true ]; then
  export http_proxy="$HTTP_PROXY"
  export https_proxy="$HTTP_PROXY"
fi


########################
# ===== 执行下载 ===== #
########################

echo "============================================"
echo "Starting axel download"
echo "Download dir : $DOWNLOAD_DIR"
echo "Connections  : $CONNECTIONS"
echo "Resume       : $RESUME"
echo "Use proxy    : $USE_PROXY"
echo "============================================"

cd "$DOWNLOAD_DIR" || exit 1

# 逐行读取 URL，逐个下载（避免 axel 并发炸掉）
while IFS= read -r URL; do
  # 跳过空行和注释
  [[ -z "$URL" || "$URL" =~ ^# ]] && continue

  echo "[INFO] Downloading:"
  echo "       $URL"

  axel "${AXEL_OPTS[@]}" "$URL"

  if [ $? -ne 0 ]; then
    echo "[WARN] Download failed: $URL"
  else
    echo "[OK] Download finished"
  fi

  echo "--------------------------------------------"
done < "$URL_FILE"

echo "[DONE] All tasks processed."


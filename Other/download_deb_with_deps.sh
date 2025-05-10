#!/bin/bash
# 下载离线安装包
# ============ 参数设置 ============
# 默认是 dislocker，可通过第1个参数指定
PACKAGE_NAME=${1:-dislocker}
OUTPUT_DIR=${2:-./offline_pkg}   # 默认保存路径是 ./offline_pkg，可通过第2个参数指定
# ===================================

echo "[INFO] 要下载的包: $PACKAGE_NAME"
echo "[INFO] 保存目录: $OUTPUT_DIR"

# 确保依赖工具存在
if ! command -v apt-rdepends &> /dev/null; then
    echo "[INFO] 正在安装 apt-rdepends..."
    sudo apt update && sudo apt install -y apt-rdepends
fi

# 创建保存目录
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR" || exit 1

# 下载软件包及依赖
echo "[INFO] 开始下载 $PACKAGE_NAME 及其依赖..."
apt-rdepends "$PACKAGE_NAME" | grep -v "^ " | sort -u | xargs apt download

echo "[SUCCESS] 所有相关包已下载至: $OUTPUT_DIR"

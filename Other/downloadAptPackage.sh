#!/bin/bash

# 检查是否提供了包名
if [ -z "$1" ]; then
    echo "Usage: $0 <package_name>"
    exit 1
fi

PACKAGE_NAME=$1
DOWNLOAD_DIR=./deb-packages

# 更新包列表
sudo apt update

# 安装 apt-rdepends，如果尚未安装
if ! dpkg -s apt-rdepends &>/dev/null; then
    sudo apt-get install apt-rdepends -y
fi

# 创建保存 .deb 文件的目录
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

# 使用 apt-rdepends 获取包及其依赖项的列表
apt-rdepends "$PACKAGE_NAME" | grep -v "^ " | grep -v "^Pre" | sort -u > package_list.txt

# 下载包及其依赖项的 .deb 文件
for pkg in $(cat package_list.txt); do
    apt-get download "$pkg"
done

echo "All packages have been downloaded to $DOWNLOAD_DIR"


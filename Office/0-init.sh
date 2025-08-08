#!/bin/bash
set -e

# 软件包列表（去重，避免重复安装）
packages=(
  openssl
  poppler-utils
  ghostscript
  libreoffice
  libreoffice-java-common
  default-jre
  libreoffice-calc
  coreutils
  bash
  findutils
  pandoc
  antiword
  python3
  iconv
  file
  parallel
  sha256sum
  md5sum
  catdoc
  docx2txt
)

echo "更新软件包索引..."
sudo apt update

echo "开始安装软件包..."
for pkg in "${packages[@]}"; do
  echo "安装 $pkg ..."
  sudo apt install -y "$pkg"
done

echo "所有软件包安装完成。"


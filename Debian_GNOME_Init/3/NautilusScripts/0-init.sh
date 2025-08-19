#!/bin/bash
set -e

# 软件包列表（去重）
packages=(
coreutils
realpath
xfce4-terminal
zenity
zsh
poppler-utils
ghostscript
cups
bash
gnome-terminal
)

echo "更新软件包索引..."
sudo apt update

echo "开始安装软件包..."
for pkg in "${packages[@]}"; do
  echo "安装 $pkg ..."
  sudo apt install -y "$pkg"
done

echo "所有软件包安装完成。"


#!/bin/bash
# 停止出错退出，改为自己处理错误
set +e

# 软件包列表（去重，避免重复安装）
packages=(
coreutils
xclip
clamav
clamav-daemon
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

# 记录安装失败的软件包
failed=()

echo "更新软件包索引..."
sudo apt update

echo "开始安装软件包..."
for pkg in "${packages[@]}"; do
  echo "安装 $pkg ..."
  if sudo apt install -y "$pkg"; then
    echo "✅ $pkg 安装成功"
  else
    echo "❌ $pkg 安装失败，跳过"
    failed+=("$pkg")
  fi
done

echo
echo "所有软件包处理完成。"

# 总结失败列表
if [ ${#failed[@]} -gt 0 ]; then
  echo "以下软件包安装失败："
  for f in "${failed[@]}"; do
    echo "  - $f"
  done
  exit 1
else
  echo "🎉 所有软件包均安装成功！"
fi


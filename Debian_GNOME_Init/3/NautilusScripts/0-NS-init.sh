#!/bin/bash
# 停止出错退出，改为自己处理错误
set +e

# 软件包列表（去重，避免重复安装）
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
libnotify-bin
)
# 办公脚本额外依赖（检查点三 SET_NAUTILUS_OFFICE=1 时由 setup.sh 传入）
if [ -n "${NS_INIT_EXTRA_PACKAGES:-}" ]; then
  # shellcheck disable=SC2206
  packages+=($NS_INIT_EXTRA_PACKAGES)
fi
# 去重
readarray -t packages < <(printf '%s\n' "${packages[@]}" | awk 'NF && !seen[$0]++')

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


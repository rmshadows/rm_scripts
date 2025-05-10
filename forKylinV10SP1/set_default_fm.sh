#!/bin/bash
# 设置默认文件管理器
# 常见文件管理器及其 desktop 文件名
declare -A FILE_MANAGERS=(
  [nautilus]="nautilus.desktop"
  [thunar]="thunar.desktop"
  [pcmanfm]="pcmanfm.desktop"
  [dolphin]="org.kde.dolphin.desktop"
  [nemo]="nemo.desktop"
)

echo "🔍 正在检测系统中已安装的文件管理器..."

# 检测安装情况
AVAILABLE_FM=()
for fm in "${!FILE_MANAGERS[@]}"; do
  if command -v "$fm" &>/dev/null || which "$fm" &>/dev/null; then
    AVAILABLE_FM+=("$fm")
  fi
done

# 如果一个都没找到
if [[ ${#AVAILABLE_FM[@]} -eq 0 ]]; then
  echo "❌ 没有检测到常见的文件管理器，请手动安装后再运行此脚本。"
  exit 1
fi

echo "✅ 检测到以下可用文件管理器："
for i in "${!AVAILABLE_FM[@]}"; do
  echo "  $((i + 1)). ${AVAILABLE_FM[$i]}"
done

echo
read -p "请输入你想设为默认的文件管理器编号（例如 1）: " CHOICE

if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#AVAILABLE_FM[@]} )); then
  SELECTED="${AVAILABLE_FM[$((CHOICE - 1))]}"
  DESKTOP_FILE="${FILE_MANAGERS[$SELECTED]}"
  echo "⚠️ 你选择设置默认文件管理器为：$SELECTED ($DESKTOP_FILE)"
  read -p "是否确认修改默认文件管理器？[y/N]: " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    xdg-mime default "$DESKTOP_FILE" inode/directory
    echo "✅ 默认文件管理器已设置为：$SELECTED"
  else
    echo "❌ 已取消修改。"
  fi
else
  echo "❌ 输入无效，已退出。"
  exit 1
fi

echo
read -p "是否现在打开当前目录（测试效果）？[y/N]: " open_now
if [[ "$open_now" =~ ^[Yy]$ ]]; then
  xdg-open .
fi

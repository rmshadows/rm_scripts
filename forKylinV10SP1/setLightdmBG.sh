#!/bin/bash

# 读取当前lightdm锁屏背景（假设在lightdm配置文件里查）
# 这里假设配置文件是 /etc/lightdm/lightdm-gtk-greeter.conf ，key是 background=
config_file="/etc/lightdm/lightdm-gtk-greeter.conf"
current_bg="未检测到当前背景"

if [[ -f "$config_file" ]]; then
  current_bg=$(grep '^background=' "$config_file" | head -n1 | cut -d= -f2-)
  [[ -z "$current_bg" ]] && current_bg="未设置背景"
else
  current_bg="配置文件不存在"
fi

echo "当前LightDM锁屏背景图片路径：$current_bg"

# 默认图库目录
default_dir="/usr/share/backgrounds"

# 自动列出默认图库里的图片
mapfile -t default_images < <(ls "$default_dir"/*.{jpg,jpeg,png} 2>/dev/null)

if [[ ${#default_images[@]} -eq 0 ]]; then
  echo "默认图库目录没有找到图片文件。"
  exit 1
fi

echo "系统默认图片列表："
for i in "${!default_images[@]}"; do
  echo "  $((i+1)). ${default_images[$i]}"
done

read -rp "是否使用系统默认图片? (y/n): " use_default

if [[ "$use_default" =~ ^[Yy]$ ]]; then
  while true; do
    read -rp "请输入选择的图片序号 (1-${#default_images[@]}): " choice
    if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && (( choice >= 1 && choice <= ${#default_images[@]} )); then
      selected_image="${default_images[$((choice-1))]}"
      break
    else
      echo "输入无效，请输入有效的序号。"
    fi
  done
else
  while true; do
    read -rp "请输入自定义图片的完整路径: " custom_path
    if [[ -f "$custom_path" ]]; then
      selected_image="$custom_path"
      break
    else
      echo "文件不存在，请重新输入有效路径。"
    fi
  done
fi

echo "您选择的图片路径是：$selected_image"

# TODO: 你可以把这里写入lightdm配置，或者调用其它命令设置锁屏背景


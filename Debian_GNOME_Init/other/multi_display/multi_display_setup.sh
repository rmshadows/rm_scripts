#!/bin/bash
# ======================================
# 三屏幕配置脚本（主屏幕 + 拓展 + 镜像）
# ======================================
# 假设：
#   D1 = 主屏幕（最左）
#   D2 = 拓展屏（右侧扩展）
#   D3 = 镜像屏（复制主屏幕）
# 用户可按实际设备名称修改

D1="HDMI-1"
D2="DP-1"
D3="eDP-1"

# 统一分辨率
RES="1920x1080"

echo "📺 当前配置："
echo "  主屏幕: $D1"
echo "  拓展屏: $D2"
echo "  镜像屏: $D3"
echo "  分辨率: $RES"
echo

# 先关闭所有输出，防止残留冲突
xrandr --output "$D1" --off --output "$D2" --off --output "$D3" --off

# 设置主屏幕（最左）
xrandr --output "$D1" --primary --mode "$RES" --pos 0x0 --auto

# 设置第二屏幕在右侧扩展
xrandr --output "$D2" --mode "$RES" --right-of "$D1" --auto

# 设置第三屏幕为主屏幕的镜像
xrandr --output "$D3" --mode "$RES" --same-as "$D1" --auto

echo "✅ 多屏幕配置完成！"
xrandr --listmonitors
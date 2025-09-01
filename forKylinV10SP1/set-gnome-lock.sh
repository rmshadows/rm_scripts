#!/bin/bash
# LightDM + GNOME 自动锁屏配置脚本（带 lightdm-gtk-greeter-settings 检测）

echo "=============================="
echo "🔧 LightDM + GNOME 锁屏配置脚本"
echo "=============================="

# 检查/安装函数
check_install() {
    local pkg="$1"
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "❌ 未检测到 $pkg，正在安装..."
        sudo apt update && sudo apt install -y "$pkg"
        if [ $? -ne 0 ]; then
            echo "⚠️ 安装 $pkg 失败，请手动处理"
            exit 1
        fi
    else
        echo "✅ 已安装 $pkg"
    fi
}

# 1. 检查 gnome-screensaver
check_install gnome-screensaver

# 2. 检查 lightdm-gtk-greeter-settings
check_install lightdm-gtk-greeter-settings

# 3. 确保 .config/autostart 有 gnome-screensaver
AUTOSTART_DIR="$HOME/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/gnome-screensaver.desktop"

mkdir -p "$AUTOSTART_DIR"

if [ ! -f "$AUTOSTART_FILE" ]; then
    cat > "$AUTOSTART_FILE" <<EOF
[Desktop Entry]
Type=Application
Exec=gnome-screensaver
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=GNOME Screensaver
EOF
    echo "✅ 已添加 gnome-screensaver 到自启动"
else
    echo "ℹ️ 已存在 gnome-screensaver 自启动配置"
fi

# 4. 打印当前参数
echo
echo "📋 当前锁屏参数："
echo "闲置锁屏时间 (idle-delay): $(gsettings get org.gnome.desktop.session idle-delay)"
echo "锁屏是否启用 (lock-enabled): $(gsettings get org.gnome.desktop.screensaver lock-enabled)"
echo "锁屏延迟 (lock-delay): $(gsettings get org.gnome.desktop.screensaver lock-delay)"
echo

# 5. 询问是否要修改
read -p "是否要将锁屏参数修改为：闲置60秒锁屏、立即锁屏 (Y/n)? " yn
case "$yn" in
    [Yy]*|"")
        gsettings set org.gnome.desktop.session idle-delay 60
        gsettings set org.gnome.desktop.screensaver lock-enabled true
        gsettings set org.gnome.desktop.screensaver lock-delay 0
        echo "✅ 锁屏参数已更新"
        ;;
    *)
        echo "⚠️ 保持原有参数不变"
        ;;
esac

# 6. 显示最终参数
echo
echo "📋 最终锁屏参数："
echo "闲置锁屏时间 (idle-delay): $(gsettings get org.gnome.desktop.session idle-delay)"
echo "锁屏是否启用 (lock-enabled): $(gsettings get org.gnome.desktop.screensaver lock-enabled)"
echo "锁屏延迟 (lock-delay): $(gsettings get org.gnome.desktop.screensaver lock-delay)"


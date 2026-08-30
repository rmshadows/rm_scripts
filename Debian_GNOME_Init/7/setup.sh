#!/bin/bash
:<<检查点七
备份原有的dconf配置
导入GNOME Terminal的dconf配置
导入GNOME 您自定义修改的系统内置快捷键的dconf配置
导入GNOME 自定义快捷键的dconf配置
导入GNOME 选区截屏配置
导入GNOME 屏幕放大镜配置
导入切换窗口配置（将会禁用切换应用程序快捷键）
导入显示桌面快捷键
导入GNOME 电源配置
启用并配置 GNOME 扩展
检查点七

source "cfg.sh"

# 导入GNOME Terminal的dconf配置
if [ "$SET_DCONF_SETTING" -eq 1 ];then
    prompt -x "备份原有的dconf配置中。"
    prompt -e "如果配置了dconf后，应用软件出现问题，请恢复备份(dconf load / < gnome-desktop-dconf-backup)或者恢复出厂(dconf reset -f /)。"
    dconf dump / > gnome-desktop-dconf-backup
    if  ! [ -f "gnome-desktop-dconf-backup" ];then
        prompt -e "dconf似乎备份失败了，请检查！"
        quitThis
    fi
    # 导入GNOME Terminal的dconf配置
    if [ "$SET_IMPORT_GNOME_TERMINAL_DCONF" != 0 ];then
        dconf dump /org/gnome/terminal/ > old-dconf-gnome-terminal.backup
        prompt -x "导入GNOME Terminal的dconf配置"
        dconf load /org/gnome/terminal/ <<< "$GNOME_TERMINAL_DCONF"
    fi
    # 导入GNOME 您自定义修改的系统内置快捷键的dconf配置
    if [ "$SET_IMPORT_GNOME_WM_KEYBINDINGS_DCONF" != 0 ];then
        dconf dump /org/gnome/desktop/wm/keybindings/ > old-dconf-custom-wm-keybindings.backup
        prompt -x "导入GNOME 您自定义修改的系统内置快捷键的dconf配置"
        dconf load /org/gnome/desktop/wm/keybindings/ <<< "$GNOME_WM_KEYBINDINGS_DCONF"
    fi
    # 导入GNOME 自定义快捷键的dconf配置
    if [ "$SET_IMPORT_GNOME_CUSTOM_KEYBINDINGS_DCONF" != 0 ];then
        dconf read /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings > old-dconf-custom-keybindings-var.backup
        dconf dump /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ > old-dconf-custom-keybindings.backup
        prompt -x "导入GNOME 自定义快捷键的dconf配置"
        dconf load /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ <<< "$GNOME_CUSTOM_KEYBINDINGS_DCONF"
        dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings "$GNOME_CUSTOM_KEYBINDINGS_DCONF_VAR"
    fi
    # 导入GNOME 放大镜快捷键的dconf配置
    if [ "$SET_IMPORT_GNOME_MAGNIFIER_KEYBINDINGS" != 0 ];then
        dconf read /org/gnome/settings-daemon/plugins/media-keys/magnifier > old-dconf-settings-daemon-magnifier.backup
        dconf read /org/gnome/settings-daemon/plugins/media-keys/magnifier-zoom-in > old-dconf-settings-daemon-magnifier-zoom-in.backup
        dconf read /org/gnome/settings-daemon/plugins/media-keys/magnifier-zoom-out > old-dconf-settings-daemon-magnifier-zoom-out.backup
        prompt -x "导入GNOME 放大镜快捷键的dconf配置"
        dconf write /org/gnome/settings-daemon/plugins/media-keys/magnifier "$GNOME_MAGNIFIER_KEYBINDINGS"
        dconf write /org/gnome/settings-daemon/plugins/media-keys/magnifier-zoom-in "$GNOME_MAGNIFIER_KEYBINDINGS_IN"
        dconf write /org/gnome/settings-daemon/plugins/media-keys/magnifier-zoom-out "$GNOME_MAGNIFIER_KEYBINDINGS_OUT"
    fi
    # 导入切换窗口配置（将会禁用切换应用程序快捷键）
    if [ "$SET_IMPORT_GNOME_SWITCH_WINDOWS_KEYBINDINGS" != 0 ];then
        # 禁用switch-applications 启用switch-windows
        dconf read /org/gnome/desktop/wm/keybindings/switch-applications > old-dconf-settings-switch-applications.backup
        dconf read /org/gnome/desktop/wm/keybindings/switch-applications-backward > old-dconf-settings-switch-applications-backward.backup
        dconf read /org/gnome/desktop/wm/keybindings/switch-windows > old-dconf-settings-switch-windows.backup
        prompt -x "导入切换窗口配置（将会禁用切换应用程序快捷键）"
        dconf write /org/gnome/desktop/wm/keybindings/switch-applications "$GNOME_SWITCH_APPLICATIONS_KEYBINDINGS"
        dconf write /org/gnome/desktop/wm/keybindings/switch-windows "$GNOME_SWITCH_WINDOWS_KEYBINDINGS"
        dconf write /org/gnome/desktop/wm/keybindings/switch-applications-backward "$GNOME_SWITCH_APPLICATIONS_BACKWARD_KEYBINDINGS"
    fi
    # 导入显示桌面快捷键
    if [ "$SET_IMPORT_GNOME_SHOW_DESKTOP_KEYBINDINGS" != 0 ];then
        dconf read /org/gnome/desktop/wm/keybindings/show-desktop > old-dconf-settings-show-desktop.backup
        prompt -x "导入显示桌面快捷键"
        dconf write /org/gnome/desktop/wm/keybindings/show-desktop "$GNOME_SHOW_DESKTOP_KEYBINDINGS"
    fi
    # 关机快捷键
    if [ "$SET_IMPORT_GNOME_SHUTDOWN_KEYBINDINGS" != 0 ];then
        dconf read /org/gnome/desktop/wm/keybindings/shutdown > old-dconf-settings-shutdown.backup
        dconf read /org/gnome/desktop/wm/keybindings/logout > old-dconf-settings-logout.backup
        prompt -x "导入关机快捷键"
        dconf write /org/gnome/desktop/wm/keybindings/logout "[]"
        dconf write /org/gnome/desktop/wm/keybindings/shutdown "$GNOME_SHUTDOWN_KEYBINDINGS"
    fi
    # 导入GNOME 电源的dconf配置
    if [ "$SET_IMPORT_GNOME_POWER_DCONF" != 0 ];then
        dconf dump /org/gnome/settings-daemon/plugins/power/ > old-dconf-settings-daemon-power.backup
        prompt -x "导入GNOME 自定义电源的dconf配置"
        dconf load /org/gnome/settings-daemon/plugins/power/ <<< "$GNOME_POWER_DCONF"
    fi
fi

# GNOME Tweaks「窗口：副键调整窗口」——不依赖 Tweaks GUI
if [ "${SET_GNOME_RESIZE_WITH_RIGHT_BUTTON:-0}" -eq 1 ]; then
    prompt -x "启用副键（右键）按住修饰键调整窗口大小"
    gsettings set org.gnome.desktop.wm.preferences resize-with-right-button true
fi

# 固定工作区数量（关闭动态工作区）
if [ "${SET_GNOME_FIXED_WORKSPACES:-0}" -gt 0 ]; then
    prompt -x "固定工作区数量为 $SET_GNOME_FIXED_WORKSPACES"
    gsettings set org.gnome.mutter dynamic-workspaces false
    gsettings set org.gnome.desktop.wm.preferences num-workspaces "$SET_GNOME_FIXED_WORKSPACES"
fi

# 启用并配置 GNOME 扩展（列表在 Config.sh；偏好在 7/cfg.sh）
if [ "${SET_GNOME_ENABLE_EXTENSIONS:-0}" -eq 1 ]; then
    ext_uuids=()
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%%#*}"
        line="${line//[[:space:]]/}"
        [ -z "$line" ] && continue
        ext_uuids+=("$line")
    done <<< "${SET_GNOME_EXTENSIONS_ENABLE:-}"
    if [ ${#ext_uuids[@]} -eq 0 ]; then
        prompt -m "扩展启用列表为空，跳过。"
    else
        joined=""
        for u in "${ext_uuids[@]}"; do
            [ -n "$joined" ] && joined+=", "
            joined+="'$u'"
        done
        prompt -x "写入 enabled-extensions: [$joined]"
        gsettings set org.gnome.shell enabled-extensions "[$joined]"
        for u in "${ext_uuids[@]}"; do
            if [ -d "/usr/share/gnome-shell/extensions/$u" ] || [ -d "$HOME/.local/share/gnome-shell/extensions/$u" ]; then
                if command -v gnome-extensions >/dev/null 2>&1; then
                    gnome-extensions enable "$u" 2>/dev/null || prompt -w "gnome-extensions 未能启用 $u（登录 GNOME 后一般会按 gsettings 生效）"
                fi
            else
                prompt -w "未找到扩展目录 $u，请确认对应 apt 包已安装"
            fi
        done
    fi
fi

if [ "${SET_GNOME_EXTENSIONS_CONFIG:-0}" -eq 1 ]; then
    prompt -x "导入 GNOME 扩展偏好（Dash / Freon / Impatience 等）"
    dconf load /org/gnome/shell/extensions/dash-to-dock/ <<< "$GNOME_EXT_DASH_TO_DOCK_DCONF"
    dconf load /org/gnome/shell/extensions/freon/ <<< "$GNOME_EXT_FREON_DCONF"
    dconf load /org/gnome/shell/extensions/harddiskled/ <<< "$GNOME_EXT_HARDDISKLED_DCONF"
    dconf load /org/gnome/shell/extensions/net/gfxmonk/impatience/ <<< "$GNOME_EXT_IMPATIENCE_DCONF"
    dconf load /org/gnome/shell/extensions/noannoyance-fork/ <<< "$GNOME_EXT_NOANNOYANCE_DCONF"
    dconf load /org/gnome/shell/extensions/appindicator/ <<< "$GNOME_EXT_APPINDICATOR_DCONF"
fi
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
        dconf dump /org/gnome/terminal/ > old-dconf-gonme-terminal.backup
        prompt -x "导入GNOME Terminal的dconf配置"
        dconf load /org/gnome/terminal/ <<< $GNOME_TERMINAL_DCONF
    fi
    # 导入GNOME 您自定义修改的系统内置快捷键的dconf配置
    if [ "$SET_IMPORT_GNOME_WM_KEYBINDINGS_DCONF" != 0 ];then
        dconf dump /org/gnome/desktop/wm/keybindings/ > old-dconf-custom-wm-keybindings.backup
        prompt -x "导入GNOME 您自定义修改的系统内置快捷键的dconf配置"
        dconf load /org/gnome/desktop/wm/keybindings/  <<<  $GNOME_WM_KEYBINDINGS_DCONF
    fi
    # 导入GNOME 自定义快捷键的dconf配置
    if [ "$SET_IMPORT_GNOME_CUSTOM_KEYBINDINGS_DCONF" != 0 ];then
        dconf read /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings > old-dconf-custom-keybindings-var.backup
        dconf dump /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ > old-dconf-custom-keybindings.backup
        prompt -x "导入GNOME 自定义快捷键的dconf配置"
        dconf load /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ <<< $GNOME_CUSTOM_KEYBINDINGS_DCONF
        dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings "$GNOME_CUSTOM_KEYBINDINGS_DCONF_VAR"
    fi
    # 导入GNOME 区域截屏快捷键的dconf配置
    if [ "$SET_IMPORT_GNOME_AREASCREENSHOT_KEYBINDINGS" != 0 ];then
        dconf read /org/gnome/settings-daemon/plugins/media-keys/area-screenshot > old-dconf-settings-daemon-area-screenshot.backup
        dconf read /org/gnome/settings-daemon/plugins/media-keys/area-screenshot-clip > old-dconf-settings-daemon-area-screenshot-clip.backup
        prompt -x "导入GNOME 区域截屏快捷键的dconf配置"
        dconf write /org/gnome/settings-daemon/plugins/media-keys/area-screenshot $GNOME_AREASCREENSHOT_KEYBINDINGS
        dconf write /org/gnome/settings-daemon/plugins/media-keys/area-screenshot-clip $GNOME_AREASCREENSHOT_KEYBINDINGS_CLIP
    fi
    # 导入GNOME 放大镜快捷键的dconf配置
    if [ "$SET_IMPORT_GNOME_MAGNIFIER_KEYBINDINGS" != 0 ];then
        dconf read /org/gnome/settings-daemon/plugins/media-keys/magnifier > old-dconf-settings-daemon-magnifier.backup
        dconf read /org/gnome/settings-daemon/plugins/media-keys/magnifier-zoom-in > old-dconf-settings-daemon-magnifier-zoom-in.backup
        dconf read /org/gnome/settings-daemon/plugins/media-keys/magnifier-zoom-out > old-dconf-settings-daemon-magnifier-zoom-out.backup
        prompt -x "导入GNOME 放大镜快捷键的dconf配置"
        dconf write /org/gnome/settings-daemon/plugins/media-keys/magnifier $GNOME_MAGNIFIER_KEYBINDINGS
        dconf write /org/gnome/settings-daemon/plugins/media-keys/magnifier-zoom-in $GNOME_MAGNIFIER_KEYBINDINGS_IN
        dconf write /org/gnome/settings-daemon/plugins/media-keys/magnifier-zoom-out $GNOME_MAGNIFIER_KEYBINDINGS_OUT
    fi
    # 导入切换窗口配置（将会禁用切换应用程序快捷键）
    if [ "$SET_IMPORT_GNOME_SWITCH_WINDOWS_KEYBINDINGS" != 0 ];then
        # 禁用switch-applications 启用switch-windows
        dconf read /org/gnome/desktop/wm/keybindings/switch-applications > old-dconf-settings-switch-applications.backup
        dconf read /org/gnome/desktop/wm/keybindings/switch-applications-backward > old-dconf-settings-switch-applications-backward.backup
        dconf read /org/gnome/desktop/wm/keybindings/switch-windows > old-dconf-settings-switch-windows.backup
        prompt -x "导入切换窗口配置（将会禁用切换应用程序快捷键）"
        dconf write /org/gnome/desktop/wm/keybindings/switch-applications $GNOME_SWITCH_APPLICATIONS_KEYBINDINGS
        dconf write /org/gnome/desktop/wm/keybindings/switch-windows $GNOME_SWITCH_WINDOWS_KEYBINDINGS
        dconf write /org/gnome/desktop/wm/keybindings/switch-applications-backward $GNOME_SWITCH_APPLICATIONS_BACKWARD_KEYBINDINGS
    fi
    # 导入显示桌面快捷键
    if [ "$SET_IMPORT_GNOME_SHOW_DESKTOP_KEYBINDINGS" != 0 ];then
        dconf read /org/gnome/desktop/wm/keybindings/show-desktop > old-dconf-settings-show-desktop.backup
        prompt -x "导入显示桌面快捷键"
        dconf write /org/gnome/desktop/wm/keybindings/show-desktop $GNOME_SHOW_DESKTOP_KEYBINDINGS
    fi
    # 导入GNOME 电源的dconf配置
    if [ "$SET_IMPORT_GNOME_POWER_DCONF" != 0 ];then
        dconf dump /org/gnome/settings-daemon/plugins/power/ > old-dconf-settings-daemon-power.backup
        prompt -x "导入GNOME 自定义电源的dconf配置"
        dconf load /org/gnome/settings-daemon/plugins/power/ <<< $GNOME_POWER_DCONF
    fi
fi
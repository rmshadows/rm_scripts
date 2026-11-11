# deploy.sh 和 uninstall.sh 都会读这个文件。改数字即可，1 做，0 跳过。
# 在 Go-undercover 目录里，用桌面用户执行：sudo ./deploy.sh
# 不要直接切到 root 再跑。面板目录菜单的主目录写成这个用户的家目录。

# 安装缺少的软件包。已经装好的会跳过。
INSTALL_PACKAGES=1

# 主题和图标拷到 /usr/share，给所有用户共用。
# 个人面板、壁纸、快捷键写到执行 sudo 的那个用户的家目录。
# 发现旧安装有错才重新拷贝：还没装、面板备份不认 .tar.bz、壁纸路径仍是
# kali-undercover、目录菜单主目录仍是 /root。
# 这些都正确时跳过。设为 1 则每次都覆盖 /usr 里的主题文件。
FORCE_FILES=0

# 在当前 XFCE 会话里套用 Windows 外观。
# 已经套用过、后来又手动关掉的，不会再次打开。
APPLY_THEME=1

# 不切换主题，只改正当前用户会话里的这几项：任务栏自动隐藏、
# 目录菜单主目录改成这个用户的家目录、壁纸路径仍指向 kali-undercover。
FIX_PANEL=1

# 卸载时是否连软件包一起删。只影响下面 EXTRA_PACKAGES，不会卸载 xfce4。
REMOVE_PACKAGES=0

PACKAGES="xfce4 xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin xfce4-power-manager-plugins xfce4-notifyd python3-gi libnotify-bin fonts-liberation rsync xcape i3lock flameshot"
EXTRA_PACKAGES="xcape i3lock flameshot"

# 快捷键总开关。0 = 一条都不动。
# 每条再单独开关。命令在这台机器上不存在时，这一条会跳过。
# 已经设成别的命令时保留，不覆盖。指向 /home/ryan、kylin-screenshot、i3lock-fancy 的会改正。
ADD_SHORTCUTS=1

SHORTCUT_TERMINAL=1
SHORTCUT_TERMINAL_KEY='<Alt>q'
SHORTCUT_TERMINAL_CMD='gnome-terminal'

SHORTCUT_TERMINAL2=1
SHORTCUT_TERMINAL2_KEY='<Alt><Shift>q'
SHORTCUT_TERMINAL2_CMD='xfce4-terminal'

SHORTCUT_FILES=1
SHORTCUT_FILES_KEY='<Alt><Shift>e'
SHORTCUT_FILES_CMD='nautilus'

SHORTCUT_MONITOR=1
SHORTCUT_MONITOR_KEY='<Alt><Shift>w'
SHORTCUT_MONITOR_CMD='gnome-system-monitor'

SHORTCUT_BROWSER=1
SHORTCUT_BROWSER_KEY='<Alt><Shift>r'
SHORTCUT_BROWSER_CMD='firefox'

SHORTCUT_SHOT=1
SHORTCUT_SHOT_KEY='<Alt><Shift>s'
SHORTCUT_SHOT_CMD='flameshot gui'

SHORTCUT_LOCK=1
SHORTCUT_LOCK_KEY='<Super>l'
SHORTCUT_LOCK_CMD='i3lock'

SHORTCUT_FINDER=1
SHORTCUT_FINDER_KEY='<Super>a'
SHORTCUT_FINDER_CMD='xfce4-appfinder'

SHORTCUT_MENU=1
SHORTCUT_MENU_KEY='<Alt>F1'
SHORTCUT_MENU_CMD='xfce4-popup-whiskermenu'

SHORTCUT_DESKTOP=1
SHORTCUT_DESKTOP_KEY='<Super>d'
SHORTCUT_DESKTOP_ACTION='show_desktop_key'

# 单击 Win 打开 Whisker 菜单。会把 Ctrl+Esc 留给这个菜单。
SHORTCUT_WIN=1

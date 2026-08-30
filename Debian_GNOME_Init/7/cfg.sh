
### 内置变量:
# GNOME终端配置
GNOME_TERMINAL_DCONF="[legacy]
mnemonics-enabled=false
theme-variant='dark'

[legacy/keybindings]
full-screen='F11'
next-tab='<Alt>x'
prev-tab='<Alt>z'"

# 快捷键
GNOME_WM_KEYBINDINGS_DCONF="[/]
always-on-top=['<Shift><Alt>O']
switch-to-workspace-1=['<Primary>Left']
switch-to-workspace-2=['<Primary>Right']
switch-to-workspace-3=['<Primary>Up']
switch-to-workspace-4=['<Primary>Down']"

GNOME_CUSTOM_KEYBINDINGS_DCONF_VAR="['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/']"
GNOME_CUSTOM_KEYBINDINGS_DCONF="[custom0]
binding='<Alt>q'
command='gnome-terminal'
name='gnome-terminal'

[custom1]
binding='<Shift><Alt>e'
command='nautilus'
name='nautilus'

[custom2]
binding='<Shift><Alt>w'
command='gnome-system-monitor'
name='gnome-system-monitor'

[custom3]
binding='<Shift><Alt>y'
command='virtualbox'
name='virtualbox'

[custom4]
binding='<Shift><Alt>r'
command='firefox-esr'
name='firefox-esr'

[custom5]
binding='<Shift><Alt>s'
command='flameshot gui'
name='flameshot'

[custom6]
binding='<Ctrl><Alt>s'
command='flameshot gui -d 3500'
name='flameshot delay'"


# 放大镜
GNOME_MAGNIFIER_KEYBINDINGS="['<Alt>0']"
GNOME_MAGNIFIER_KEYBINDINGS_IN="['<Alt>equal']"
GNOME_MAGNIFIER_KEYBINDINGS_OUT="['<Alt>minus']"

# 切换窗口
GNOME_SWITCH_WINDOWS_KEYBINDINGS="['<Alt>Tab']"
GNOME_SWITCH_APPLICATIONS_KEYBINDINGS="['<Super>Tab']"
GNOME_SWITCH_APPLICATIONS_BACKWARD_KEYBINDINGS="['<Shift><Super>Tab']"

# 显示桌面
GNOME_SHOW_DESKTOP_KEYBINDINGS="['<Super>d']"

# 关机（会清空注销）
GNOME_SHUTDOWN_KEYBINDINGS="['<Control><Alt>Delete']"

# 导入GNOME 电源配置
GNOME_POWER_DCONF="[/]
power-button-action='nothing'
sleep-inactive-ac-timeout=7200
sleep-inactive-ac-type='nothing'"

# GNOME 扩展偏好（与当前机器实际用法对齐；不含显示器接口等本机硬件项）
GNOME_EXT_DASH_TO_DOCK_DCONF="[/]
dock-position='LEFT'
dock-fixed=false
autohide=true
intellihide=false
show-mounts=false
show-trash=false
dash-max-icon-size=48
multi-monitor=true
hot-keys=false
animation-time=0.1
hide-delay=0.1
height-fraction=0.9
background-opacity=0.8"

GNOME_EXT_FREON_DCONF="[/]
hot-sensors=['__average__', '__max__']
panel-box-index=0
show-decimal-value=false
use-drive-udisks2=false
use-generic-liquidctl=false
use-gpu-bumblebeenvidia=false
use-gpu-nvidia=false"

GNOME_EXT_HARDDISKLED_DCONF="[/]
mode=6"

GNOME_EXT_IMPATIENCE_DCONF="[/]
speed-factor=0.25"

GNOME_EXT_NOANNOYANCE_DCONF="[/]
blocklist=['Microsoft Teams - Preview']"

GNOME_EXT_APPINDICATOR_DCONF="[/]
legacy-tray-enabled=true
tray-pos='right'
icon-spacing=12"

#!/bin/bash

# 你的变量
APT_TO_INSTALL_INDEX="
- aircrack-ng——aircrack-ng
- apt-listbugs——apt显示bug信息。注意：阻碍自动安装，请过后手动安装
- apt-listchanges——apt显示更改。注意：阻碍自动安装，请过后手动安装
- apt-transport-https——apt-transport-https
- arp-scan——arp-scan
- axel——axel下载器
- bash-completion——终端自动补全
- bleachbit——系统清理软件
- blender——3D开发
- bridge-utils——网桥
- build-essential——开发环境
- bustle——D-Bus记录
- calibre——Epub等多格式电子书阅读器。注意：Epub等多格式电子书阅读器，体积较大，87M
- cewl——CeWL网站字典生成(关键词采集)
- cifs-utils——访问Windows共享文件夹
- clamav——Linux下的杀毒软件
- cmake——cmake
- cowpatty——wireless hash
- crunch——字典生成
- cups——cups打印机驱动
- curl——curl
- dislocker——查看bitlocker分区
- dos2unix——将Windows下的文本文档转为Linux下的文本文档
- drawing——GNOME画图
- dsniff——网络审计
- ettercap-graphical——ettercap-graphical
- extremetuxracer——滑雪游戏
- flatpak——flatpak平台
- freeplane——思维导图
- fritzing——电路设计
- fping——fping
- fuse——配合dislocker查看bitlocker分区
- g++——C++
- gajim——即时通讯
- gcc——C
- gedit-plugin*——Gedit插件
- gimp——gimp图片编辑
- glance——一个可以代替htop的软件
- gnome-recipes——GNOME西餐菜单。注意：西餐为主的菜单
- gnome-shell-extension-appindicator——支持Unity/Ubuntu风格的系统托盘(AppIndicator)，把传统托盘图标显示在顶栏或托盘区
- gnome-shell-extension-apps-menu——在顶栏提供“应用菜单”（按分类列出已安装应用）
- gnome-shell-extension-arc-menu——提供类似Windows/Start的可定制启动器菜单（Arc风格菜单）
- gnome-shell-extension-autohidetopbar——自动隐藏/显示顶部面板，节省屏幕空间
- gnome-shell-extension-auto-move-windows——根据规则自动把新打开的窗口移动到指定工作区
- gnome-shell-extension-blur-my-shell——给Dash/活动概览/顶栏等添加模糊/半透明效果，美化界面
- gnome-shell-extension-caffeine——防止系统进入休眠或屏幕保护（临时禁止空闲锁屏）
- gnome-shell-extension-dashtodock——把活动概览左侧Dash转为持久侧栏Dock（高度可配置）
- gnome-shell-extension-dash-to-panel——将Dash与顶栏合并，形成类似Windows的任务栏（将Dock放到底部并集成顶栏）
- gnome-shell-extension-desktop-icons-ng——在- gnome里提供桌面图标支持（比旧desktop-icons更现代）
- gnome-shell-extension-drive-menu——在顶栏显示可移动驱动/挂载点和相关操作菜单
- gnome-shell-extension-easyscreencast——一键/快捷键录屏（轻量的屏幕录制/截屏扩展）
- gnome-shell-extension-flypie——弹出式“饼状”快速启动/命令选择器，类似Pie菜单
- gnome-shell-extension-freon——在顶栏显示温度、电压等硬件传感数据（依赖lm-sensors）
- gnome-shell-extension-gamemode——为当前会话启用/集成GameMode（提升游戏性能的守护模式）
- gnome-shell-extension-gpaste——将GPaste剪贴板管理器集成到顶栏（方便访问历史剪贴项）
- gnome-shell-extension-gsconnect——与Android手机互联（基于KDEConnect协议），文件/通知/剪贴板互通）
- gnome-shell-extension-gsconnect-browsers——为GSConnect提供浏览器集成（例如来自手机发送链接到浏览器打开）
- gnome-shell-extension-hard-disk-led——在顶栏显示磁盘活动/LED状态（展示磁盘I/O指示）
- gnome-shell-extension-hide-activities——隐藏默认的“Activities”热点/文字，简洁顶栏显示
- gnome-shell-extension-hamster——集成Hamster时间追踪器（显示时间条/计时相关信息）
- gnome-shell-extension-impatience——缩短/加速- gnome动画延迟（让界面感觉更迅速）
- gnome-shell-extension-kimpanel——输入法面板集成/改进（常用于特定输入法框架的面板功能）
- gnome-shell-extension-launch-new-instance——允许右键/点击“在新实例中启动”程序（而不是聚焦已有实例）
- gnome-shell-extension-light-style——轻量主题/样式调整扩展（用于切换或调整部分视觉风格）
- gnome-shell-extension-manager——扩展管理器（GUI），便于搜索/启用/禁用/更新扩展）
- gnome-shell-extension-native-window-placement——改进窗口原生放置（可能增强多显示器或特定放置策略）
- gnome-shell-extension-no-annoyance——屏蔽或抑制某些烦人的通知/提示（减少打扰）
- gnome-shell-extension-prefs——扩展首选项集成（帮助打开/管理扩展的设置界面）
- gnome-shell-extension-places-menu——在顶栏提供“位置/收藏夹”菜单（快速访问常用文件夹）
- gnome-shell-extension-pixelsaver——将标题栏与顶栏合并（为应用节省垂直空间，常用于无标题栏布局）
- gnome-shell-extension-panel-osd——将屏幕OSD（音量/亮度提示）移动到面板位置或更改样式
- gnome-shell-extension-prefs——（见上）扩展偏好/设置集成（可能为多个扩展提供统一入口）
- gnome-shell-extension-runcat——显示第三方应用或服务的自定义指示器（类似systemindicators）
- gnome-shell-extension-shortcuts——提供或显示键盘快捷键帮助/管理界面
- gnome-shell-extension-shortcuts——（见上）
- gnome-shell-extension-shorcuts?——可能为快捷键显示与管理（有同名变体）
- gnome-shell-extension-status-icons——将传统状态图标（像托盘图标）迁移到顶栏（兼容旧式应用）
- gnome-shell-extension-system-monitor——在顶栏/侧边显示系统资源使用（CPU/内存/网络等）
- gnome-shell-extension-top-icons-plus——将传统tray图标显示到顶栏（兼容旧托盘的方案）
- gnome-shell-extension-tiling-assistant——窗口平铺辅助（更好地管理窗口分割/布局）
- gnome-shell-extension-user-theme——允许通过- gnomeTweak或扩展加载并应用用户主题（shell主题）
- gnome-shell-extension-places-menu——（见上）
- gnome-shell-extension-weather——在顶栏显示天气信息和简要预报
- gnome-shell-extension-window-list——在顶栏/任务栏显示开启窗口列表（传统窗口列表行为）
- gnome-shell-extension-windows-navigator——用快捷键在窗口间快速切换与导航（改进Alt-Tab/工作区切换体验）
- gnome-shell-extension-workspace-indicator——在顶栏显示当前工作区编号/导航控件
- gnome-shell-extensions——扩展集合包（包含一组常见官方/社区扩展的便捷包）
- gnome-shell-extensions-extra——额外扩展集合（同上，包含更多非核心扩展）
- gnucash——GNU账本
- grub-customizer——GRUB或BURG定制器
- gtranslator——GNOME本地应用翻译编辑
- gufw——防火墙
- handbrake——视频转换
- hugin——全景照片拼合工具
- homebank——家庭账本
- hostapd——AP热点相关
- hping3——hping3
- htop——htop彩色任务管理器
- httrack——网站克隆
- hydra——hydra
- inotify-tools——inotify文件监视
- isc-dhcp-server——DHCP服务器
- kdenlive——kdenlive视频编辑
- kompare——文件差异对比
- konversation——IRC客户端
- libblockdev*——文件系统相关的插件
- libgtk-3-dev——GTK3
- linux-headers-$(uname -r)——Linux Headers
- lshw——显示硬件
- make——make
- masscan——masscan
- mc——MidnightCommander
- mdk3——mdk3
- meld——文件差异合并
- nautilus-extension-gnome-terminal——nautilus插件_右键文件夹可在该目录打开GNOME终端（terminal）_
- nautilus-extension-burner——nautilus插件_提供光盘刻录功能（使用Brasero或类似工具）_
- nautilus-extension-gnome-console——nautilus插件_增强文件夹内终端操作体验_
- nautilus-extension-brasero——nautilus插件_方便右键brasero刻录光盘
- ncrack——ncrack
- net-tools——ifconfig等工具
- nmap——nmap
- nodejs——nodejs
- npm——nodejs包管理器
- ntpdate——NTP时间同步
- obs-studio——OBS
- openssh-server——SSH
- paperwork-gtk——办公文档扫描
- pavucontrol——PulseAudioVolumeControl
- pinfo——友好的命令帮助手册
- pkg-config——pkg-config
- pulseeffects——pulse audio的调音器。注意：可能影响到原音频系统
- pwgen——随机密码生成
- python-pip——pip
- python3-pip——pip3
- python3-tk——python3 TK界面
- qmmp——qmmp音乐播放器
- qt5ct——QT界面显示配置
- reaver——无线WPS测试
- screenfetch——显示系统信息
- sed——文本编辑工具
- silversearcher-ag——Ag快速搜索工具
- slowhttptest——慢速HTTP链接测试
- smbclient——SMB共享查看
- sqlmap——sqlmap
- sshfs——挂载远程SSH目录
- supertuxkart——Linux飞车游戏
- sweethome3d——室内设计
- synaptic——新立得包本地图形化管理器
- tcpdump——tcpdump
- tig——tig(类似github桌面)
- timeshift——系统备份
- tree——树状显示文件夹
- traceroute——路由跟踪
- vim——VIM编辑器
- vlc——vlc视频播放器
- wafw00f——网站防火墙检测
- websploit——Web渗透测试
- wget——wget网络下载工具
- xdotool——X自动化工具
- xsel——剪贴板操作
- yt-dlp——youtube-dl
- zenity——显示GTK+对话框
- zhcon——tty中文虚拟
- zsh——zsh
- zsh-autosuggestions——zsh插件
"

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 提取包名函数
extract_pkg() {
    local line="$1"
    line="${line##- }"
    if [[ "$line" == *"——"* ]]; then
        echo "${line%%——*}"
    else
        echo "$line"
    fi
}

echo "待检测的软件包："
PKGS=()
while IFS= read -r l || [ -n "$l" ]; do
    [[ -z "${l// }" ]] && continue
    [[ "${l:0:1}" == "#" ]] && continue
    pkg=$(extract_pkg "$l")
    PKGS+=("$pkg")
    echo "$pkg"
done <<< "$APT_TO_INSTALL_INDEX"

echo
echo "=== 检测结果 (Debian apt 源) ==="

MISSING_PKGS=()

for pkg in "${PKGS[@]}"; do
    if apt-cache show "$pkg" >/dev/null 2>&1; then
        echo -e "${GREEN}[OK]${NC} $pkg 可在当前 apt 源中找到"
    else
        echo -e "${RED}[NO]${NC} $pkg 不存在于当前 apt 源"
        MISSING_PKGS+=("$pkg")
    fi
done

# 最后列出所有不存在的包
if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo
    echo -e "${RED}以下软件包在当前 apt 源中不存在:${NC}"
    for pkg in "${MISSING_PKGS[@]}"; do
        echo "- $pkg"
    done
else
    echo
    echo -e "${GREEN}所有软件包都存在于当前 apt 源。${NC}"
fi

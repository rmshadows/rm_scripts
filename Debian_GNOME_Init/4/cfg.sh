#!/bin/bash
:<<注释
下面是需要填写的列表，要安装的软件。注意，格式是短杠空格接软件包名接破折号接软件包描述“- 【软件包名】——【软件包描述】”
注意：列表中请不要使用中括号
INDEX：1 轻量（网络 debug + 编程 + 仅 VLC） / 2 日用影音 / 3 自定义
GNOME 扩展包说明见 4/README.md
注释

# 稍后安装黑名单：从当前 INDEX 里挑出这些包，脚本结束再装（格式同 INDEX）。
# 若某包写在黑名单但不在当前 INDEX，也会稍后安装。
SET_APT_TO_INSTALL_LATER="
- apt-listbugs——apt显示bug信息。注意：阻碍自动安装，请过后手动安装
- apt-listchanges——apt显示更改。注意：阻碍自动安装，请过后手动安装
- wireshark——wireshark。注意：阻碍自动安装，请过后手动安装
"

# 与 INDEX_3 相同用途；建议直接改 APT_TO_INSTALL_INDEX_3
APT_TO_INSTALL_INDEX_0="

"

# 轻量：网络 debug、编程工具、日常终端/文件、仅 VLC；扩展只装实际启用的那几个 + prefs
APT_TO_INSTALL_INDEX_1="
- aircrack-ng——无线网络安全工具集（抓包、破解WEP/WPA握手）。
- apt-listbugs——在apt安装前显示已知严重漏洞的包（会中断自动安装，建议手动处理）。
- apt-listchanges——显示软件包变更日志（会中断自动安装，建议手动审阅）。
- apt-transport-https——允许APT通过HTTPS拉取软件源。
- arp-scan——局域网主机发现工具（快速扫描ARP表）。
- axel——多线程下载加速器（命令行）。
- bash-completion——Bash自动补全脚本（提高终端效率）。
- bleachbit——系统清理工具（释放空间、清理缓存）。
- bridge-utils——管理Linux网桥（常用于虚拟化/网络桥接）。
- build-essential——常用构建工具集（gcc、make等）。
- cewl——网站关键词/字典生成工具（安全测试用）。
- cifs-utils——挂载与访问Windows/SMB共享。
- cmake——跨平台构建系统生成工具。
- copyq——剪贴板管理器（历史记录、快捷粘贴）。
- crunch——生成密码字典的工具（用于渗透测试）。
- cups——通用Unix打印系统（打印服务）。
- curl——命令行URL传输工具（HTTP/FTP等）。
- dislocker——挂载/访问BitLocker加密卷。
- dos2unix——转换Windows文本格式为Unix格式。
- dsniff——网络嗅探与审计套件。
- ettercap-graphical——图形化的网络中间人与嗅探工具（Ettercap）。
- flameshot——截屏软件
- fping——批量ping工具（更快的主机可达性检查）。
- fuse——用户空间文件系统框架（许多挂载工具依赖）。
- g++——C++编译器前端（GNU）。
- gcc——GNUC编译器。
- gedit-plugin-bookmarks——在文本中添加书签，方便快速跳转。
- gedit-plugin-character-map——字符映射表，插入特殊符号或 Unicode 字符。
- gedit-plugin-color-picker——颜色选择器，插入颜色代码。
- gedit-plugin-join-lines——合并多行文本为一行。
- gedit-plugin-session-saver——保存/恢复编辑会话（文件、光标位置等）。
- gedit-plugin-terminal——在编辑器底部嵌入终端面板。
- gedit-plugin-bracket-completion——自动补全括号和引号。
- gedit-plugin-code-comment——快捷键快速注释/取消注释代码。
- gedit-plugin-draw-spaces——显示空格、制表符、换行等不可见字符。
- gedit-plugin-multi-edit——支持多光标同时编辑。
- gedit-plugin-smart-spaces——智能缩进与空格处理。
- gedit-plugin-word-completion——基于上下文的单词自动补全。
- gnome-shell-extension-appindicator——显示AppIndicator风格托盘图标。
- gnome-shell-extension-dashtodock——将Dash转为持久侧边Dock。
- gnome-shell-extension-drive-menu——在顶栏显示可移动驱动与挂载操作。
- gnome-shell-extension-freon——在顶栏显示温度/硬件传感数据（需lm-sensors）。
- gnome-shell-extension-hard-disk-led——在顶栏显示磁盘I/O指示。
- gnome-shell-extension-impatience——加速/减少GNOME动画延迟。
- gnome-shell-extension-no-annoyance——屏蔽烦人提示/弹窗。
- gnome-shell-extension-prefs——打开/管理扩展首选项的快捷入口。
- hostapd——将机器作为Wi-FiAP的守护进程（配置复杂，谨慎）。
- hping3——可构造报文的网络测试工具（安全/渗透测试）。
- htop——交互式进程查看器（比top更友好）。
- hydra——并行化登录爆破工具（渗透测试用）。
- inotify-tools——文件系统事件监控命令行工具（inotify接口）。
- linux-headers-$(uname -r)——当前内核的头文件（编译内核模块/驱动必需）。
- lm-sensors——硬件传感器读取（Freon 扩展依赖）。
- lshw——列出硬件信息与配置。
- make——构建自动化工具（Makefile执行）。
- masscan——高速端口扫描器（大规模网络探测）。
- mdk3——无线测试工具（用于渗透/压力测试）。
- meld——图形化文件/目录差异合并工具。
- nautilus-extension-gnome-terminal——在Nautilus中右键打开GNOME终端的扩展。
- nautilus-extension-gnome-console——Nautilus内的终端增强扩展。
- net-tools——传统网络工具集（ifconfig、route等）。
- nmap——网络扫描与安全审核工具。
- ntpdate——手动同步时间的工具（已被systemd-timesyncd/chrony替代者覆盖）。
- openssh-server——SSH服务端。
- pwgen——随机密码生成器。
- qt5ct——配置Qt5应用的主题/字体/样式。
- sed——流编辑器（文本处理基础工具）。
- silversearcher-ag——快速文本搜索工具（ag，代码搜索利器）。
- slowhttptest——测试慢HTTPDoS攻击的工具（安全研究）。
- smbclient——访问SMB/CIFS共享的命令行客户端。
- sshfs——通过SSH挂载远程目录（FUSE）。
- synaptic——经典的APT图形包管理器。
- tcpdump——命令行网络数据包捕获工具。
- timeshift——系统快照/备份工具（类似RestorePoint）。
- tree——以树状显示目录结构的命令行工具。
- traceroute——路由追踪工具（显示网络路径）。
- vim——经典终端文本编辑器（Vim）。
- vlc——功能强大的多媒体播放器。
- wget——非交互式网络下载工具。
- xdotool——X窗口自动化/脚本模拟输入工具。
- xsel——操作X剪贴板的命令行工具。
- zenity——通过命令行弹出GTK+对话框（脚本交互）。
- zhcon——在纯终端下显示中文的工具（TTY中文支持）。
- zsh——Zshell，高级交互式shell替代bash。
- zsh-autosuggestions——zsh插件，提供命令自动补全建议（提高交互效率）。
"

# 日用影音：INDEX_1 全部 + 剪辑/绘图/记账/刻录/下载
APT_TO_INSTALL_INDEX_2="
- aircrack-ng——无线网络安全工具集（抓包、破解WEP/WPA握手）。
- apt-listbugs——在apt安装前显示已知严重漏洞的包（会中断自动安装，建议手动处理）。
- apt-listchanges——显示软件包变更日志（会中断自动安装，建议手动审阅）。
- apt-transport-https——允许APT通过HTTPS拉取软件源。
- arp-scan——局域网主机发现工具（快速扫描ARP表）。
- axel——多线程下载加速器（命令行）。
- bash-completion——Bash自动补全脚本（提高终端效率）。
- bleachbit——系统清理工具（释放空间、清理缓存）。
- bridge-utils——管理Linux网桥（常用于虚拟化/网络桥接）。
- build-essential——常用构建工具集（gcc、make等）。
- cewl——网站关键词/字典生成工具（安全测试用）。
- cifs-utils——挂载与访问Windows/SMB共享。
- clamav——开源杀毒引擎（病毒扫描）。
- cmake——跨平台构建系统生成工具。
- copyq——剪贴板管理器（历史记录、快捷粘贴）。
- crunch——生成密码字典的工具（用于渗透测试）。
- cups——通用Unix打印系统（打印服务）。
- curl——命令行URL传输工具（HTTP/FTP等）。
- dislocker——挂载/访问BitLocker加密卷。
- dos2unix——转换Windows文本格式为Unix格式。
- drawing——GNOME简易绘图应用（画图）。
- dsniff——网络嗅探与审计套件。
- ettercap-graphical——图形化的网络中间人与嗅探工具（Ettercap）。
- flameshot——截屏软件
- fping——批量ping工具（更快的主机可达性检查）。
- fuse——用户空间文件系统框架（许多挂载工具依赖）。
- g++——C++编译器前端（GNU）。
- gcc——GNUC编译器。
- gedit-plugin-bookmarks——在文本中添加书签，方便快速跳转。
- gedit-plugin-character-map——字符映射表，插入特殊符号或 Unicode 字符。
- gedit-plugin-color-picker——颜色选择器，插入颜色代码。
- gedit-plugin-join-lines——合并多行文本为一行。
- gedit-plugin-session-saver——保存/恢复编辑会话（文件、光标位置等）。
- gedit-plugin-terminal——在编辑器底部嵌入终端面板。
- gedit-plugin-bracket-completion——自动补全括号和引号。
- gedit-plugin-code-comment——快捷键快速注释/取消注释代码。
- gedit-plugin-draw-spaces——显示空格、制表符、换行等不可见字符。
- gedit-plugin-multi-edit——支持多光标同时编辑。
- gedit-plugin-smart-spaces——智能缩进与空格处理。
- gedit-plugin-word-completion——基于上下文的单词自动补全。
- gimp——功能强大的开源图像编辑器（Photoshop替代）。
- gnome-shell-extension-appindicator——显示AppIndicator风格托盘图标。
- gnome-shell-extension-dashtodock——将Dash转为持久侧边Dock。
- gnome-shell-extension-drive-menu——在顶栏显示可移动驱动与挂载操作。
- gnome-shell-extension-freon——在顶栏显示温度/硬件传感数据（需lm-sensors）。
- gnome-shell-extension-hard-disk-led——在顶栏显示磁盘I/O指示。
- gnome-shell-extension-impatience——加速/减少GNOME动画延迟。
- gnome-shell-extension-no-annoyance——屏蔽烦人提示/弹窗。
- gnome-shell-extension-prefs——打开/管理扩展首选项的快捷入口。
- gnucash——个人与小型企业会计管理软件。
- grub-customizer——图形化GRUB配置管理工具（谨慎使用）。
- handbrake——视频转码与压缩工具（GUI/CLI）。
- hostapd——将机器作为Wi-FiAP的守护进程（配置复杂，谨慎）。
- hping3——可构造报文的网络测试工具（安全/渗透测试）。
- htop——交互式进程查看器（比top更友好）。
- httrack——网站镜像/克隆工具。
- hydra——并行化登录爆破工具（渗透测试用）。
- inotify-tools——文件系统事件监控命令行工具（inotify接口）。
- kdenlive——非线性视频编辑器（功能强大、适合剪辑）。
- linux-headers-$(uname -r)——当前内核的头文件（编译内核模块/驱动必需）。
- lm-sensors——硬件传感器读取（Freon 扩展依赖）。
- lshw——列出硬件信息与配置。
- make——构建自动化工具（Makefile执行）。
- masscan——高速端口扫描器（大规模网络探测）。
- mdk3——无线测试工具（用于渗透/压力测试）。
- meld——图形化文件/目录差异合并工具。
- nautilus-extension-gnome-terminal——在Nautilus中右键打开GNOME终端的扩展。
- nautilus-extension-burner——在Nautilus中集成刻录功能（Brasero集成）。
- nautilus-extension-gnome-console——Nautilus内的终端增强扩展。
- nautilus-extension-brasero——集成Brasero刻录操作到Nautilus。
- net-tools——传统网络工具集（ifconfig、route等）。
- nmap——网络扫描与安全审核工具。
- ntpdate——手动同步时间的工具（已被systemd-timesyncd/chrony替代者覆盖）。
- obs-studio——屏幕录制与直播软件。
- openssh-server——SSH服务端。
- pavucontrol——PulseAudio/PipeWire 音量控制面板。
- pwgen——随机密码生成器。
- qt5ct——配置Qt5应用的主题/字体/样式。
- sed——流编辑器（文本处理基础工具）。
- silversearcher-ag——快速文本搜索工具（ag，代码搜索利器）。
- slowhttptest——测试慢HTTPDoS攻击的工具（安全研究）。
- smbclient——访问SMB/CIFS共享的命令行客户端。
- sshfs——通过SSH挂载远程目录（FUSE）。
- synaptic——经典的APT图形包管理器。
- tcpdump——命令行网络数据包捕获工具。
- timeshift——系统快照/备份工具（类似RestorePoint）。
- tree——以树状显示目录结构的命令行工具。
- traceroute——路由追踪工具（显示网络路径）。
- vim——经典终端文本编辑器（Vim）。
- vlc——功能强大的多媒体播放器。
- wget——非交互式网络下载工具。
- xdotool——X窗口自动化/脚本模拟输入工具。
- xsel——操作X剪贴板的命令行工具。
- yt-dlp——youtube-dl的高维护分支，视频下载利器。
- zenity——通过命令行弹出GTK+对话框（脚本交互）。
- zhcon——在纯终端下显示中文的工具（TTY中文支持）。
- zsh——Zshell，高级交互式shell替代bash。
- zsh-autosuggestions——zsh插件，提供命令自动补全建议（提高交互效率）。
"

# 自定义：从 INDEX_1 / INDEX_2 或本目录 README 自行挑选填入
APT_TO_INSTALL_INDEX_3="

"

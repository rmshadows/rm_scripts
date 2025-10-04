# Debian_13_GNOME.sh

>Current Version: 0.1.0

## 目录结构

- `0`、`1`等数字文件夹：0表示固定运行的脚本。1，2，3分别对应检查的一、二、三等，里面可能有子配置文件`cfg.sh`，同时还有一个`setup.sh`是运行的脚本。
- `Config.sh`是总配置，`Config_Templates`是配置模板。
- `Debian_13_Bookworm_GNOME_Setup.sh`，程序入口，主要运行的脚本。
- `GlobalVariables.sh`，全局变量，需要填写密码。
- `Lib.sh`脚本函数库。
- `Archive`时归档，从Debian10至今的存档。
- `other`时其他资源文件。

## 使用方法

适用：Debian 13 GNOME

1. 检查是否符合脚本系统要求
2. 配置好`Config.sh`以及数字目录下的`cfg.sh`（如有必要）
3. 补充需要的资源(比如一些个人个性化配置)
4. 直接运行`Debian_12_Bookworm_GNOME_Setup.sh`脚本

## 脚本运行流程

### 初始化脚本

1. 加载变量

   ```
   # 加载全局变量
   source "GlobalVariables.sh"
   # 加载全局函数
   source "Lib.sh"
   # 加载配置(在全局变量之后)
   source "Config.sh"
   ```

2. 脚本预执行

   ```
   # 脚本开始
   source "0/0_start.sh"
   # 预执行
   source "0/init.sh"
   ```

- 加载配置文件和函数库等等
- 获取当前用户名
- 首先检查用户是否在`sudo`组中且免密码。如果没有，临时添加`$USER ALL=(ALL)NOPASSWD:ALL`进`/etc/sudoers`文件中(运行结束或者Ctrl+c中断会自动移除)。
- 检查是否在sudo组中
- 是的话检查是否免密码
- 检查是否时GNOME桌面，不是则警告、退出。
- 与用户确认执行

### 检查点一

- 临时成为免密`sudoer`(必选)。
- 添加用户到`sudo`组。
- 设置用户`sudo`免密码。
- 默认源安装apt-transport-https ca-certificates wget gnupg2 gnupg lsb-release
- 更新源、更新系统。
- 配置unattended-upgrades

### 检查点二

- 替换vim-tiny为vim-full
- 替换Bash为Zsh
- 替换默认的ZSHRC文件
- 添加/usr/sbin到用户的SHELL环境变量
- 替换root用户的SHELL配置
- 安装bash-completion
- 安装zsh-autosuggestions

### 检查点三

- 自定义自己的服务（运行一个shell脚本）
- 配置Nautilus右键菜单以及Data、Project、Vbox-Tra、Prog、Mounted文件夹
- 复制模板文件夹内容
- 配置启用NetworkManager、安装net-tools
- 设置网卡eth0为热拔插模式以缩短开机时间。如果没有eth0网卡，发出警告、跳过
- 配置GRUB网卡默认命名方式

### 检查点四

- 从APT源安装常用软件

  ```
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
  - gnome-shell-extension-apps-menu——在顶栏提供按类的应用菜单。
  - gnome-shell-extension-arc-menu——可定制的启动器菜单（Arc风格）。
  - gnome-shell-extension-autohidetopbar——自动隐藏GNOME顶栏。
  - gnome-shell-extension-auto-move-windows——按规则把新窗口移动到指定工作区。
  - gnome-shell-extension-blur-my-shell——为Shell元素添加模糊/半透明效果。
  - gnome-shell-extension-caffeine——临时禁止屏幕休眠/锁屏。
  - gnome-shell-extension-dashtodock——将Dash转为持久侧边Dock。
  - gnome-shell-extension-dash-to-panel——把Dash与顶栏合并为任务栏。
  - gnome-shell-extension-desktop-icons-ng——提供现代化桌面图标支持。
  - gnome-shell-extension-drive-menu——在顶栏显示可移动驱动与挂载操作。
  - gnome-shell-extension-easyscreencast——简易录屏/截屏扩展。
  - gnome-shell-extension-flypie——Pie菜单快速命令/启动器。
  - gnome-shell-extension-freon——在顶栏显示温度/硬件传感数据（需lm-sensors）。
  - gnome-shell-extension-gamemode——集成GameMode，优化游戏性能。
  - gnome-shell-extension-gpaste——集成剪贴板管理器GPaste。
  - gnome-shell-extension-gsconnect——与Android手机互联（基于KDEConnect协议）。
  - gnome-shell-extension-gsconnect-browsers——为GSConnect提供浏览器集成。
  - gnome-shell-extension-hard-disk-led——在顶栏显示磁盘I/O指示。
  - gnome-shell-extension-hide-activities——隐藏Activities热点/文字。
  - gnome-shell-extension-hamster——集成Hamster时间追踪。
  - gnome-shell-extension-impatience——加速/减少GNOME动画延迟。
  - gnome-shell-extension-kimpanel——输入法面板集成与改进。
  - gnome-shell-extension-launch-new-instance——强制以新实例启动程序。
  - gnome-shell-extension-light-style——轻量样式/视觉调整扩展。
  - gnome-shell-extension-manager——图形化扩展管理器（搜索/启用/禁用）。
  - gnome-shell-extension-native-window-placement——改进窗口放置策略。
  - gnome-shell-extension-no-annoyance——屏蔽烦人提示/弹窗。
  - gnome-shell-extension-prefs——打开/管理扩展首选项的快捷入口。
  - gnome-shell-extension-places-menu——顶栏位置/收藏夹快速访问菜单。
  - gnome-shell-extension-runcat——显示第三方服务的自定义指示器。
  - gnome-shell-extension-shortcuts——快捷键显示与管理界面。
  - gnome-shell-extension-status-icons——将传统状态图标迁移到顶栏。
  - gnome-shell-extension-system-monitor——在面板显示CPU/内存/网络等实时数据。
  - gnome-shell-extension-tiling-assistant——窗口平铺与布局辅助工具。
  - gnome-shell-extension-user-theme——允许使用用户shell主题（需GNOMETweak）。
  - gnome-shell-extension-weather——顶栏天气信息与简要预报。
  - gnome-shell-extension-window-list——任务栏风格的窗口列表显示。
  - gnome-shell-extension-windows-navigator——改进窗口/工作区键盘导航。
  - gnome-shell-extension-workspace-indicator——显示与切换工作区指示器。
  - gnome-shell-extensions——官方/常用扩展集合打包。
  - gnome-shell-extensions-extra——额外扩展集合（更多非核心扩展）。
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
  ```

- 脚本最后再安装的应用(滞后)

  ```
    - apt-listbugs——apt显示bug信息。注意：阻碍自动安装，请过后手动安装
    - apt-listchanges——apt显示更改。注意：阻碍自动安装，请过后手动安装
  ```

- 安装Python3

  - 配置Python3源为清华大学镜像
  - 配置Python3全局虚拟环境（Debian12中无法直接使用pip了）

- 安装配置Apache2

  - 配置Apache2 共享目录为 /home/HTML(必选)
    - 是否禁用Apache2开机自启

- 安装php-fpm

- 安装nginx

- 安装配置Git

  - 配置User Email

- 安装配置SSH

- 安装配置npm

  - 安装cnpm
    - 安装hexo
    - 安装nodejs(必选)

- 安装VirtualBox(滞后)

- 安装Anydesk(滞后)

- 安装Typora(滞后)

- 安装sublime text(滞后)

- 安装teamviewer(滞后)

- 安装wps-office(滞后)

- 安装docker-ce(滞后)

- 禁用第三方软件仓库更新(提升apt体验)(滞后)

### 检查点五

- 配置中州韵输入法(fcitx、ibus、fcitx5)

- 配置词库(github导入公共词库、导入本地词库)

### 检查点六

- 配置SSH Key(新密钥，导入)

### 检查点七(谨慎使用！可能弄坏您的应用程序！)

- 备份原有的dconf配置

- 导入GNOME Terminal的dconf配置
- 导入GNOME 您自定义修改的系统内置快捷键的dconf配置
- 导入GNOME 自定义快捷键的dconf配置
- 导入GNOME 关机快捷键配置(会清空注销的快捷键)
- 导入GNOME 屏幕放大镜配置
- 导入GNOME 电源配置

### 检查点八

配置Shorewall防火墙(需要手动启用)

### 脚本收尾

- 滞后安装的软件
- 设置GRUB os-prober
- 设置用户目录所属

## 脚本内置函数（`Lib.sh`）

- `prompt ()`——控制台颜色输出

  ```
  -s:绿色——成功信息
  -x:绿色——日志：{}
  -e:红色——错误
  -w:黄色——警告
  -i:蓝色——一般信息
  -m:蓝色——信息：{}
  -k:蓝色&红色——格式化输出
  ```

- `onSigint`——程序中断处理方法,包含正常退出该执行的代码

- `onExit ()`——正常退出需要执行的

- `quitThis ()`——中途异常退出脚本要执行的 注意，检查点一后才能使用这个方法

- `doAsRoot ()`——以root身份运行

- `checkRootPasswd ()`——检查root密码是否正确

- `comfirm ()`——询问函数 Yes:1 No:2 其他:5。

  ```
  函数调用请使用：
  comfirm "\e[1;33m? [y/N]\e[0m"
  choice=$?
  if [ $choice == 1 ];then
    yes
  elif [ $choice == 2 ];then
    prompt -i "——————————  下一项  ——————————"
  else
    prompt -e "ERROR:未知返回值!"
    exit 5
  fi
  ```

- `backupFile ()`——备份配置文件。先检查是否有bak结尾的备份文件，没有则创建，有则另外覆盖一个newbak文件。$1 :文件名

- `doApt ()`——执行apt命令 注意，检查点一后才能使用这个方法

- `addFolder ()`——新建文件夹。只能有一个参数$1

- `log_message_bg() `——后台记录日志。

- `log_message()`——记录日志(会显示再终端) log_message_bg "信息" "日志文件"

- `do_job()`——执行任务，执行脚本（日志+输出） do_job "setup.sh" "$ELOG_FILE"

- `replace_username()`——替换用户名为使用已定义的 $CURRENT_USER

- `### archive` ——旧函数存档

## 应用列表

- aircrack-ng——无线网络安全工具集（抓包、破解WEP/WPA握手）。
- apt-listbugs——在apt安装前显示已知严重漏洞的包（会中断自动安装，建议手动处理）。
- apt-listchanges——显示软件包变更日志（会中断自动安装，建议手动审阅）。
- apt-transport-https——允许APT通过HTTPS拉取软件源。
- arp-scan——局域网主机发现工具（快速扫描ARP表）。
- axel——多线程下载加速器（命令行）。
- bash-completion——Bash自动补全脚本（提高终端效率）。
- bleachbit——系统清理工具（释放空间、清理缓存）。
- blender——开源3D建模与渲染软件。
- bridge-utils——管理Linux网桥（常用于虚拟化/网络桥接）。
- build-essential——常用构建工具集（gcc、make等）。
- bustle——D-Bus消息记录工具（调试用）。
- calibre——全功能电子书管理与阅读器（支持EPUB/多格式，体积较大）。
- cewl——网站关键词/字典生成工具（安全测试用）。
- cifs-utils——挂载与访问Windows/SMB共享。
- clamav——开源杀毒引擎（病毒扫描）。
- cmake——跨平台构建系统生成工具。
- cowpatty——无线WPA/WPA2密码破解工具（基于词典）。
- crunch——生成密码字典的工具（用于渗透测试）。
- cups——通用Unix打印系统（打印服务）。
- curl——命令行URL传输工具（HTTP/FTP等）。
- dislocker——挂载/访问BitLocker加密卷。
- dos2unix——转换Windows文本格式为Unix格式。
- drawing——GNOME简易绘图应用（画图）。
- dsniff——网络嗅探与审计套件。
- ettercap-graphical——图形化的网络中间人与嗅探工具（Ettercap）。
- extremetuxracer——休闲滑雪类小游戏。
- fastfetch——类似neofetch。
- flatpak——应用沙箱与跨发行版打包运行平台。
- flameshot——截屏软件
- freeplane——思维导图工具（轻量、开源）。
- fritzing——电子电路原型设计与PCB绘图工具。
- fping——批量ping工具（更快的主机可达性检查）。
- fuse——用户空间文件系统框架（许多挂载工具依赖）。
- g++——C++编译器前端（GNU）。
- gajim——XMPP（Jabber）桌面即时通讯客户端。
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
- glance——轻量系统监控替代htop（如已安装则可用）。
- gnome-recipes——食谱管理应用（以西餐为主的菜谱）。
- gnome-shell-extension-appindicator——显示AppIndicator风格托盘图标。
- gnome-shell-extension-apps-menu——在顶栏提供按类的应用菜单。
- gnome-shell-extension-arc-menu——可定制的启动器菜单（Arc风格）。
- gnome-shell-extension-autohidetopbar——自动隐藏GNOME顶栏。
- gnome-shell-extension-auto-move-windows——按规则把新窗口移动到指定工作区。
- gnome-shell-extension-blur-my-shell——为Shell元素添加模糊/半透明效果。
- gnome-shell-extension-caffeine——临时禁止屏幕休眠/锁屏。
- gnome-shell-extension-dashtodock——将Dash转为持久侧边Dock。
- gnome-shell-extension-dash-to-panel——把Dash与顶栏合并为任务栏。
- gnome-shell-extension-desktop-icons-ng——提供现代化桌面图标支持。
- gnome-shell-extension-drive-menu——在顶栏显示可移动驱动与挂载操作。
- gnome-shell-extension-easyscreencast——简易录屏/截屏扩展。
- gnome-shell-extension-flypie——Pie菜单快速命令/启动器。
- gnome-shell-extension-freon——在顶栏显示温度/硬件传感数据（需lm-sensors）。
- gnome-shell-extension-gamemode——集成GameMode，优化游戏性能。
- gnome-shell-extension-gpaste——集成剪贴板管理器GPaste。
- gnome-shell-extension-gsconnect——与Android手机互联（基于KDEConnect协议）。
- gnome-shell-extension-gsconnect-browsers——为GSConnect提供浏览器集成。
- gnome-shell-extension-hard-disk-led——在顶栏显示磁盘I/O指示。
- gnome-shell-extension-hide-activities——隐藏Activities热点/文字。
- gnome-shell-extension-hamster——集成Hamster时间追踪。
- gnome-shell-extension-impatience——加速/减少GNOME动画延迟。
- gnome-shell-extension-kimpanel——输入法面板集成与改进。
- gnome-shell-extension-launch-new-instance——强制以新实例启动程序。
- gnome-shell-extension-light-style——轻量样式/视觉调整扩展。
- gnome-shell-extension-manager——图形化扩展管理器（搜索/启用/禁用）。
- gnome-shell-extension-native-window-placement——改进窗口放置策略。
- gnome-shell-extension-no-annoyance——屏蔽烦人提示/弹窗。
- gnome-shell-extension-prefs——打开/管理扩展首选项的快捷入口。
- gnome-shell-extension-places-menu——顶栏位置/收藏夹快速访问菜单。
- gnome-shell-extension-runcat——显示第三方服务的自定义指示器。
- gnome-shell-extension-shortcuts——快捷键显示与管理界面。
- gnome-shell-extension-status-icons——将传统状态图标迁移到顶栏。
- gnome-shell-extension-system-monitor——在面板显示CPU/内存/网络等实时数据。
- gnome-shell-extension-tiling-assistant——窗口平铺与布局辅助工具。
- gnome-shell-extension-user-theme——允许使用用户shell主题（需GNOMETweak）。
- gnome-shell-extension-weather——顶栏天气信息与简要预报。
- gnome-shell-extension-window-list——任务栏风格的窗口列表显示。
- gnome-shell-extension-windows-navigator——改进窗口/工作区键盘导航。
- gnome-shell-extension-workspace-indicator——显示与切换工作区指示器。
- gnome-shell-extensions——官方/常用扩展集合打包。
- gnome-shell-extensions-extra——额外扩展集合（更多非核心扩展）。
- gnucash——个人与小型企业会计管理软件。
- grub-customizer——图形化GRUB配置管理工具（谨慎使用）。
- gtranslator——翻译文件编辑器（用于本地化PO文件）。
- gufw——图形化ufw前端（简单防火墙配置）。
- handbrake——视频转码与压缩工具（GUI/CLI）。
- hugin——全景照片拼接与投影工具。
- homebank——个人家庭账本管理软件。
- hostapd——将机器作为Wi-FiAP的守护进程（配置复杂，谨慎）。
- hping3——可构造报文的网络测试工具（安全/渗透测试）。
- htop——交互式进程查看器（比top更友好）。
- httrack——网站镜像/克隆工具。
- hydra——并行化登录爆破工具（渗透测试用）。
- inotify-tools——文件系统事件监控命令行工具（inotify接口）。
- isc-dhcp-server——DHCP服务器（为局域网分配IP）。
- kdenlive——非线性视频编辑器（功能强大、适合剪辑）。
- kompare——文件差异比较GUI工具。
- konversation——IRC客户端（KDE风格）。
- libblockdev'-——文件系统与块设备管理库/工具集合（按需安装具体包）。
- libgtk-3-dev——GTK3开发头文件与库（编译GUI程序用）。
- linux-headers-$(uname -r)——当前内核的头文件（编译内核模块/驱动必需）。
- lshw——列出硬件信息与配置。
- make——构建自动化工具（Makefile执行）。
- masscan——高速端口扫描器（大规模网络探测）。
- mc——MidnightCommander，基于终端的文件管理器。
- mdk3——无线测试工具（用于渗透/压力测试）。
- meld——图形化文件/目录差异合并工具。
- nautilus-extension-gnome-terminal——在Nautilus中右键打开GNOME终端的扩展。
- nautilus-extension-burner——在Nautilus中集成刻录功能（Brasero集成）。
- nautilus-extension-gnome-console——Nautilus内的终端增强扩展。
- nautilus-extension-brasero——集成Brasero刻录操作到Nautilus。
- ncrack——网络认证暴力破解工具（渗透测试）。
- net-tools——传统网络工具集（ifconfig、route等）。
- nmap——网络扫描与安全审核工具。
- nodejs——Node.js运行时。
- npm——Node.js包管理器。
- ntpdate——手动同步时间的工具（已被systemd-timesyncd/chrony替代者覆盖）。
- obs-studio——屏幕录制与直播软件。
- openssh-server——SSH服务端。
- paperwork-gtk——文档扫描与OCR管理工具（Paperwork）。
- pavucontrol——PulseAudio音量控制面板（细粒度调节）。
- pinfo——友好的命令行手册浏览器（基于info）。
- pkg-config——检测已安装库并提供编译参数的工具。
- pulseeffects——PulseAudio音频效果处理器（可能影响音频链路）。
- pwgen——随机密码生成器。
- python-pip——Python2的pip（旧版，不推荐新安装）。
- python3-pip——Python3的pip（推荐用于现代脚本）。
- python3-tk——Python3的TKGUI支持。
- qmmp——轻量级音乐播放器（类似Winamp风格）。
- qt5ct——配置Qt5应用的主题/字体/样式。
- reaver——WPSPIN破解工具（渗透测试）。
- screenfetch——终端系统信息美化显示脚本（类似neofetch）。
- sed——流编辑器（文本处理基础工具）。
- silversearcher-ag——快速文本搜索工具（ag，代码搜索利器）。
- slowhttptest——测试慢HTTPDoS攻击的工具（安全研究）。
- smbclient——访问SMB/CIFS共享的命令行客户端。
- sqlmap——自动化SQL注入与数据库接管测试工具。
- sshfs——通过SSH挂载远程目录（FUSE）。
- supertuxkart——开源赛车游戏（休闲）。
- sweethome3d——室内设计与平面布置工具。
- synaptic——经典的APT图形包管理器。
- tcpdump——命令行网络数据包捕获工具。
- tig——文本模式的git浏览器（类似GUI的TUI）。
- timeshift——系统快照/备份工具（类似RestorePoint）。
- tree——以树状显示目录结构的命令行工具。
- traceroute——路由追踪工具（显示网络路径）。
- vim——经典终端文本编辑器（Vim）。
- vlc——功能强大的多媒体播放器。
- wafw00f——探测网站使用何种WAF（网站防火墙识别）。
- websploit——Web漏洞与渗透测试框架。
- wget——非交互式网络下载工具。
- xdotool——X窗口自动化/脚本模拟输入工具。
- xsel——操作X剪贴板的命令行工具。
- yt-dlp——youtube-dl的高维护分支，视频下载利器。
- zenity——通过命令行弹出GTK+对话框（脚本交互）。
- zhcon——在纯终端下显示中文的工具（TTY中文支持）。
- zsh——Zshell，高级交互式shell替代bash。
- zsh-autosuggestions——zsh插件，提供命令自动补全建议（提高交互效率）。

## 更新日志

- 2025年10月1日——0.1.0
  - 开始适配Debian 13

- 2025年2月12日——0.0.9
  - 重构优化结构

- 2024年12月26日——0.0.8
  - 新增Shorewall防火墙配置

- 2024年12月13日——0.0.7
  - 重构脚本

- 2023年10月10日——0.0.5
  - 新增Nginx安装（Apache2就不要了）

- 2023年6月29日——0.0.3
  - 修复输入法安装bug
- 2023年6月29日——0.0.2
  - 修复`zsh-autosuggestions`安装的bug
  - 新增Python虚拟环境搭建
  - 增加截屏等组件的失效警告
- 2023年6月23日——0.0.1
  - 从Debian 11迁移到Debian 12
  - 新增步骤GRUB OS_PROBER启用（自Debian 12 开始，GRUB检测其他系统的 os-prober 被禁用了）。
  - fcitx和fcitx5在debian12中无法共存

## 备忘录

```
# 无需密码：
【普通用户的用户名】	ALL=(ALL)NOPASSWD:ALL
# 需要密码：
【普通用户的用户名】	ALL=(ALL:ALL)	ALL
```

# 其他脚本——OtherScripts

- Cancel_All_Print_Task.sh——取消所有打印任务
- GNOME_Lock_Screen.sh——GNOME锁屏

# Debian12_GNOME.sh

>Current Version: 0.0.9

## 目录结构

- `0`、`1`等数字文件夹：0表示固定运行的脚本。1，2，3分别对应检查的一、二、三等，里面可能有子配置文件`cfg.sh`，同时还有一个`setup.sh`是运行的脚本。
- `Config.sh`是总配置，`Config_Templates`是配置模板。
- `Debian_12_Bookworm_GNOME_Setup.sh`，程序入口，主要运行的脚本。
- `GlobalVariables.sh`，全局变量，需要填写密码。
- `Lib.sh`脚本函数库。
- `Archive`时归档，从Debian10至今的存档。
- `other`时其他资源文件。

## 使用方法

适用：Debian 12 GNOME

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
  - aircrack-ng——aircrack-ng
  - apt-transport-https——apt-transport-https
  - arp-scan——arp-scan
  - axel——axel下载器
  - bash-completion——终端自动补全
  - bleachbit——系统清理软件
  - build-essential——开发环境
  - clamav——Linux下的杀毒软件
  - cmake——cmake
  - crunch——字典生成
  - cups——cups打印机驱动
  - curl——curl
  - dislocker——查看bitlocker分区
  - dos2unix——将Windows下的文本文档转为Linux下的文本文档
  - drawing——GNOME画图
  - dsniff——网络审计
  - ettercap-graphical——ettercap-graphical
  - flatpak——flatpak平台
  - gedit-plugin*——Gedit插件
  - gimp——gimp图片编辑
  - gnome-shell-extension-arc-menu——GNOME扩展+ARC菜单
  - gnome-shell-extension-autohidetopbar——GNOME扩展+自动隐藏顶栏
  - gnome-shell-extension-bluetooth-quick-connect——GNOME扩展+蓝牙快速连接
  - gnome-shell-extension-caffeine——GNOME扩展+防止屏幕休眠
  - gnome-shell-extension-dashtodock——GNOME扩展+DashtoDock侧栏
  - gnome-shell-extension-dash-to-panel——GNOME扩展+任务栏
  - gnome-shell-extension-desktop-icons——GNOME扩展+桌面图标
  - gnome-shell-extension-disconnect-wifi——GNOME扩展+断开wifi
  - gnome-shell-extension-draw-on-your-screen——GNOME扩展+屏幕涂鸦
  - gnome-shell-extension-freon——GNOME扩展+顶栏显示磁盘温度
  - gnome-shell-extension-gamemode——GNOME扩展+游戏模式
  - gnome-shell-extension-hard-disk-led——GNOME扩展
  - gnome-shell-extension-hide-activities——GNOME扩展
  - gnome-shell-extension-hide-veth——GNOME扩展
  - gnome-shell-extension-impatience——GNOME扩展
  - gnome-shell-extension-kimpanel——GNOME扩展
  - gnome-shell-extension-move-clock——GNOME扩展+移动时钟
  - gnome-shell-extension-multi-monitors——GNOME扩展+多屏幕支持
  - gnome-shell-extension-no-annoyance——GNOME扩展
  - gnome-shell-extension-panel-osd——GNOME扩展
  - gnome-shell-extension-pixelsaver——GNOME扩展
  - gnome-shell-extension-prefs——GNOME扩展
  - gnome-shell-extension-redshift——GNOME扩展
  - gnome-shell-extension-remove-dropdown-arrows——GNOME扩展
  - gnome-shell-extensions——GNOME扩展
  - gnome-shell-extensions-gpaste——GNOME扩展+GNOME剪辑板
  - gnome-shell-extension-shortcuts——GNOME扩展
  - gnome-shell-extension-show-ip——GNOME扩展+顶栏菜单显示IP
  - gnome-shell-extension-tilix-shortcut——GNOME扩展
  - gnome-shell-extension-top-icons-plus——GNOME扩展
  - gnome-shell-extension-volume-mixer——GNOME扩展
  - gnome-shell-extension-weather——GNOME扩展+天气
  - gnucash——GNU账本
  - grub-customizer——GRUB或BURG定制器
  - gufw——防火墙
  - handbrake——视频转换
  - hping3——hping3
  - htop——htop彩色任务管理器
  - httrack——网站克隆
  - hydra——hydra
  - inotify-tools——inotify文件监视
  - kompare——文件差异对比
  - konversation——IRC客户端
  - lshw——显示硬件
  - make——make
  - masscan——masscan
  - mdk3——mdk3
  - meld——文件差异合并
  - nautilus-extension-*——nautilus插件
  - net-tools——ifconfig等工具
  - nmap——nmap
  - nodejs——nodejs
  - npm——nodejs包管理器
  - ntpdate——NTP时间同步
  - obs-studio——OBS
  - openssh-server——SSH
  - pwgen——随机密码生成
  - python3-pip——pip3
  - qt5ct——qt界面
  - reaver——无线WPS测试
  - screenfetch——显示系统信息
  - sed——文本编辑工具
  - silversearcher-ag——Ag快速搜索工具
  - slowhttptest——慢速HTTP链接测试
  - tcpdump——tcpdump
  - tree——树状显示文件夹
  - traceroute——路由跟踪
  - vim——VIM编辑器
  - vlc——vlc视频播放器
  - wafw00f——网站防火墙检测
  - websploit——Web渗透测试
  - wget——wget网络下载工具
  - wireshark——wireshark
  - xdotool——X自动化工具
  - xprobe——网页防火墙测试
  - xsel——剪贴板操作
  - zhcon——tty中文虚拟
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

- 安装skype(滞后)

- 安装docker-ce(滞后)

- 安装网易云音乐(滞后)

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
- 导入GNOME 选区截屏配置
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
- gnome-shell-extension-appindicator——GNOME扩展
- gnome-shell-extension-arc-menu——GNOME扩展+ARC菜单
- gnome-shell-extension-autohidetopbar——GNOME扩展+自动隐藏顶栏
- gnome-shell-extension-bluetooth-quick-connect——GNOME扩展+蓝牙快速连接
- gnome-shell-extension-caffeine——GNOME扩展+防止屏幕休眠
- gnome-shell-extension-dashtodock——GNOME扩展+DashtoDock侧栏
- gnome-shell-extension-dash-to-panel——GNOME扩展+任务栏
- gnome-shell-extension-desktop-icons——GNOME扩展+桌面图标
- gnome-shell-extension-disconnect-wifi——GNOME扩展+断开wifi
- gnome-shell-extension-draw-on-your-screen——GNOME扩展+屏幕涂鸦
- gnome-shell-extension-freon——GNOME扩展+顶栏显示磁盘温度
- gnome-shell-extension-gamemode——GNOME扩展+游戏模式
- gnome-shell-extension-hamster——GNOME扩展+时间追踪器
- gnome-shell-extension-hard-disk-led——GNOME扩展
- gnome-shell-extension-hide-activities——GNOME扩展
- gnome-shell-extension-hide-veth——GNOME扩展
- gnome-shell-extension-impatience——GNOME扩展
- gnome-shell-extension-kimpanel——GNOME扩展
- gnome-shell-extension-move-clock——GNOME扩展+移动时钟
- gnome-shell-extension-multi-monitors——GNOME扩展+多屏幕支持
- gnome-shell-extension-no-annoyance——GNOME扩展+关闭应用准备就绪对话框
- gnome-shell-extension-panel-osd——GNOME扩展
- gnome-shell-extension-pixelsaver——GNOME扩展
- gnome-shell-extension-prefs——GNOME扩展
- gnome-shell-extension-redshift——GNOME扩展
- gnome-shell-extension-remove-dropdown-arrows——GNOME扩展
- gnome-shell-extensions——GNOME扩展
- gnome-shell-extensions-gpaste——GNOME扩展+GNOME剪辑板
- gnome-shell-extension-shortcuts——GNOME扩展
- gnome-shell-extension-show-ip——GNOME扩展+顶栏菜单显示IP
- gnome-shell-extension-system-monitor——GNOME扩展+顶栏资源监视器
- gnome-shell-extension-tilix-dropdown——GNOME扩展
- gnome-shell-extension-tilix-shortcut——GNOME扩展
- gnome-shell-extension-top-icons-plus——GNOME扩展
- gnome-shell-extension-trash——GNOME扩展
- gnome-shell-extension-volume-mixer——GNOME扩展
- gnome-shell-extension-weather——GNOME扩展+天气
- gnome-software-plugin-flatpak——GNOME Flatpak插件
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
- nautilus-extension-*——nautilus插件
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
- sslstrip——https降级
- supertuxkart——Linux飞车游戏
- sweethome3d——室内设计
- synaptic——新立得包本地图形化管理器
- tcpdump——tcpdump
- tig——tig(类似github桌面)
- tree——树状显示文件夹
- traceroute——路由跟踪
- vim——VIM编辑器
- vlc——vlc视频播放器
- wafw00f——网站防火墙检测
- websploit——Web渗透测试
- wget——wget网络下载工具
- wireshark——wireshark
- xdotool——X自动化工具
- xprobe——网页防火墙测试
- xsel——剪贴板操作
- zenity——显示GTK+对话框
- zhcon——tty中文虚拟
- zsh——zsh
- zsh-autosuggestions——zsh插件

## 更新日志

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

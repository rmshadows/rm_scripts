# Debian13_Server.sh

>Current Version: 0.1.3

## 目录结构

- `0`、`1`等数字文件夹：0表示固定运行的脚本。1，2，3分别对应检查的一、二、三等，里面可能有子配置文件`cfg.sh`，同时还有一个`setup.sh`是运行的脚本。
- `Config.sh`是总配置，`Config_Templates`是配置模板。
- `Debian_13_Server_Setup.sh`，程序入口，主要运行的脚本。
- `GlobalVariables.sh`，全局变量，需要填写密码。
- `Lib.sh`脚本函数库。
- `Archive`是归档，从Debian10至今的存档。
- `other`时其他资源文件。

## 使用方法

适用：Debian 13 服务器

1. 检查是否符合脚本系统要求
2. 配置好`Config.sh`以及数字目录下的`cfg.sh`（如有必要）
3. 补充需要的资源(比如一些个人个性化配置)
4. 直接运行`Debian_13_Server_Setup.sh`脚本

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
- 检查是否时GNOME桌面，不是则警告、退出。
- 与用户确认执行

### 检查点一

- 默认源安装apt-transport-https ca-certificates wget gnupg2 gnupg lsb-release
- 更新源、更新系统。
- 配置unattended-upgrades

### 检查点二

- 新建用户
- 检查是否在sudo组中
- 是的话检查是否免密码
- 询问是否将当前用户加入sudo组, 是否sudo免密码（如果已经是sudoer且免密码则跳过）。
- 临时成为免密sudoer(必选)。
- 添加用户到sudo组。
- 设置用户sudo免密码。
- 卸载vim-tiny，安装vim-full
- 替换Bash为Zsh
- 添加/usr/sbin到环境变量
- 替换root用户shell配置文件
- 安装bash-completion
- 安装zsh-autosuggestions

### 检查点三

- 配置家目录文件夹
- 配置自定义的systemtl服务
- 配置启用NetworkManager、安装net-tools
- 配置GRUB网卡默认命名方式
- 配置主机名
- 配置语言支持
- 配置时区
- 设置TTY1自动登录

### 检查点四

- 从APT源安装常用软件

  ```
  - atop——高级系统资源监控工具，能详细显示CPU、内存、磁盘等使用情况
  - curl——数据传输工具，支持HTTP、HTTPS等协议，广泛用于API测试
  - dstat——实时性能监控工具，能显示 CPU、磁盘、网络等信息
  - grep——强大的文本搜索工具，适用于日志分析
  - htop——交互式进程查看器，比top更强大，支持彩色显示和进程树
  - iftop——实时网络流量监控工具，显示哪些进程占用最多带宽
  - inotify-tools——基于inotify的工具集，用于监控文件和目录变化
  - lsof——列出当前系统打开的文件及相关进程，有助于调试和故障排查
  - mtr——网络诊断工具，结合ping和traceroute功能，实时显示网络路径信息
  - nmap——网络扫描工具，用于发现网络中的设备和服务
  - ping——基本的网络连通性测试工具
  - rkhunter——检测系统是否存在 rootkit 的工具
  - rsync——文件同步工具，常用于备份和增量复制
  - rsyslog——系统日志服务，用于收集和处理日志
  - screen——终端复用工具，适用于断开和恢复远程会话
  - sed——流编辑器，用于批量编辑日志文件
  - ssh——安全的远程Shell工具，用于远程管理Linux系统
  - strace——系统调用跟踪工具，调试进程与系统的交互
  - sysstat——系统监控工具包，包含iostat、mpstat等
  - tar——用于打包和压缩备份文件
  - tcpdump——网络抓包工具，用于捕获和分析网络数据包
  - silversearcher-ag——快速文本搜索工具（ag，代码搜索利器）
  - tmux——终端复用工具，支持多窗口和会话保持，适合长时间运行的任务
  - traceroute——网络路径追踪工具，用于检查数据包传输的路径
  - wget——文件下载工具，支持HTTP、HTTPS、FTP等协议，适用于脚本化下载
  - zsh——zsh
  - zsh-autosuggestions——zsh_plugin
  - zsh-syntax-highlighting——zsh_plugin
  ```
  
- 脚本最后再安装的应用(滞后)

  ```
    - apt-listbugs——apt显示bug信息。注意：阻碍自动安装，请过后手动安装
    - apt-listchanges——apt显示更改。注意：阻碍自动安装，请过后手动安装
  ```

- 安装Python3

- 配置Python3源为清华大学镜像

- 配置Python3全局虚拟环境（Debian12中无法直接使用pip了）

- 安装配置Git(配置User Email)

- 安装配置SSH

- 安装配置npm(是否安装hexo)

- 安装docker-ce(滞后)

- 禁用第三方软件仓库更新(提升apt体验)(滞后)

### 检查点五

- 安装配置php-fpm
- 安装http服务器
- 配置Let's encrypt ＣｅｒｔＢｏｔ


### 检查点六

- 生成SSH　Ｋｅｙ
- 配置Shorewall防火墙(需要手动启用)

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

## 更新日志

>dev: Not available yet.

- 2025.10.05——0.1.3
  - 迁移到Debian 13

- 2025.02.12——0.1.2
  - 重构优化

- 2025.01.18——0.1.1
  - 重构
- 2023.02.10——0.1.0
  - 新增`linxfilesharing`
- 2023.02.06——0.0.9
  - 新增`php-fpm`等
- 2022.07.22——0.0.8
  - 修复了直播文件夹中的小问题
- 2022.04.14——0.0.7
  - 修复了语言配置、等问题(0.0.6)
  - 去除了GRUB网卡命名规则(0.0.6)
  - 修复了`nginx`配置问题(0.0.7)
  - 修复了`HOME_INDEX`变量的赋值问题(0.0.7)
- 2022.04.13——0.0.5
  - 修复了部分bug
- 2022.04.11——0.0.4
  - 大体完成	
- 2022.04.10——0.0.3-dev
  - 更新了检查点六
- 2022.04.09——0.0.2-dev
  - 更新了检查点三
- 2021.09.28——0.0.1-dev
  - 从Debian 10迁移到Debian 11，采用预配置方式。

## 应用列表

- ansible——自动化运维工具，支持配置管理和应用部署
- atop——高级系统资源监控工具，能详细显示CPU、内存、磁盘等使用情况
- auditd——安全审计守护进程，用于跟踪和记录系统活动
- bmon——带宽监控工具，实时显示流量统计
- borgbackup——高效的备份工具，支持增量备份和加密
- chkrootkit——检测系统是否被 rootkit 入侵的工具
- clamav——开源防病毒软件，用于检测病毒和恶意软件
- collectd——用于收集系统和网络性能指标，并提供监控与告警功能
- curl——数据传输工具，支持HTTP、HTTPS等协议，广泛用于API测试
- docker——容器化平台，用于创建、管理和部署应用容器
- dstat——实时性能监控工具，能显示 CPU、磁盘、网络等信息
- fabric——Python-based工具，用于远程执行命令和自动化任务
- fail2ban——防止暴力破解的安全工具，自动封禁多次登录失败的IP
- firewalld——动态防火墙管理工具，基于iptables，适合动态配置
- gdb——GNU调试器，广泛用于调试C/C++程序
- glances——跨平台系统监控工具，显示各类资源的实时情况
- grep——强大的文本搜索工具，适用于日志分析
- htop——交互式进程查看器，比top更强大，支持彩色显示和进程树
- iftop——实时网络流量监控工具，显示哪些进程占用最多带宽
- inotify-tools——基于inotify的工具集，用于监控文件和目录变化
- iperf——网络带宽测试工具，用于测试TCP、UDP网络性能
- iptables——强大的防火墙工具，灵活控制进出流量
- linux-perf——和内核版本强绑定
- logrotate——自动化日志文件旋转，定期清理和压缩旧日志
- logwatch——日志分析工具，自动生成系统日志报告
- lsof——列出当前系统打开的文件及相关进程，有助于调试和故障排查
- mtr——网络诊断工具，结合ping和traceroute功能，实时显示网络路径信息
- multitail——实时监控多个日志文件，支持彩色高亮和过滤
- netdata——实时系统监控，提供漂亮的Web界面，适合实时监控和报警
- nmap——网络扫描工具，用于发现网络中的设备和服务
- nmon——性能监控工具，支持图形化界面和全面的系统数据收集
- ping——基本的网络连通性测试工具
- puppet——配置管理和自动化工具，广泛用于数据中心和云环境
- restic——快速、安全的备份工具，支持加密和去重
- rkhunter——检测系统是否存在 rootkit 的工具
- rsync——文件同步工具，常用于备份和增量复制
- rsyslog——系统日志服务，用于收集和处理日志
- sar——系统活动报告工具，用于生成历史性能数据报告
- screen——终端复用工具，适用于断开和恢复远程会话
- sed——流编辑器，用于批量编辑日志文件
- ssh——安全的远程Shell工具，用于远程管理Linux系统
- strace——系统调用跟踪工具，调试进程与系统的交互
- sysstat——系统监控工具包，包含iostat、mpstat等
- tar——用于打包和压缩备份文件
- tcpdump——网络抓包工具，用于捕获和分析网络数据包
- silversearcher-ag——快速文本搜索工具（ag，代码搜索利器）
- tmux——终端复用工具，支持多窗口和会话保持，适合长时间运行的任务
- traceroute——网络路径追踪工具，用于检查数据包传输的路径
- valgrind——内存调试工具，用于检测内存泄漏、越界等问题
- wget——文件下载工具，支持HTTP、HTTPS、FTP等协议，适用于脚本化下载

- zsh——zsh

- zsh-autosuggestions——zsh_plugin

- zsh-syntax-highlighting——zsh_plugin

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

#!/bin/bash
:<<注释
下面是需要填写的列表，要安装的软件。注意，格式是短杠空格接软件包名接破折号接软件包描述“- 【软件包名】——【软件包描述】”
注意：列表中请不要使用中括号
注释

# 这里是 脚本运行后 要安装的软件。格式同上，注意是稍后安装的，所以会放在脚本执行结束后才安装。
SET_APT_TO_INSTALL_LATER="
- apt-listbugs——apt显示bug信息。注意：阻碍自动安装，请过后手动安装
- apt-listchanges——apt显示更改。注意：阻碍自动安装，请过后手动安装
"

# 自定义列表列表
APT_TO_INSTALL_INDEX_0="

"

# 轻便安装 (仅我个人认为必要的常用软件)
APT_TO_INSTALL_INDEX_1="
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
"


# 部分安装(含有娱乐项目、行业软件、调试应用)
APT_TO_INSTALL_INDEX_2="
- ansible——自动化运维工具，支持配置管理和应用部署
- atop——高级系统资源监控工具，能详细显示CPU、内存、磁盘等使用情况
- auditd——安全审计守护进程，用于跟踪和记录系统活动
- bmon——带宽监控工具，实时显示流量统计
- borgbackup——高效的备份工具，支持增量备份和加密
- chkrootkit——检测系统是否被 rootkit 入侵的工具
- clamav——开源防病毒软件，用于检测病毒和恶意软件
- collectd——用于收集系统和网络性能指标，并提供监控与告警功能
- curl——数据传输工具，支持HTTP、HTTPS等协议，广泛用于API测试
- dstat——实时性能监控工具，能显示 CPU、磁盘、网络等信息
- fail2ban——防止暴力破解的安全工具，自动封禁多次登录失败的IP
- grep——强大的文本搜索工具，适用于日志分析
- htop——交互式进程查看器，比top更强大，支持彩色显示和进程树
- iftop——实时网络流量监控工具，显示哪些进程占用最多带宽
- inotify-tools——基于inotify的工具集，用于监控文件和目录变化
- iperf——网络带宽测试工具，用于测试TCP、UDP网络性能
- iptables——强大的防火墙工具，灵活控制进出流量
- logwatch——日志分析工具，自动生成系统日志报告
- lsof——列出当前系统打开的文件及相关进程，有助于调试和故障排查
- mtr——网络诊断工具，结合ping和traceroute功能，实时显示网络路径信息
- multitail——实时监控多个日志文件，支持彩色高亮和过滤
- netdata——实时系统监控，提供漂亮的Web界面，适合实时监控和报警
- nmap——网络扫描工具，用于发现网络中的设备和服务
- nmon——性能监控工具，支持图形化界面和全面的系统数据收集
- ping——基本的网络连通性测试工具
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
"

# 全部安装 请注意查看标记有 注意 二字的条目
APT_TO_INSTALL_INDEX_3="
- ansible——自动化运维工具，支持配置管理和应用部署
- atop——高级系统资源监控工具，能详细显示CPU、内存、磁盘等使用情况
- auditd——安全审计守护进程，用于跟踪和记录系统活动
- bmon——带宽监控工具，实时显示流量统计
- borgbackup——高效的备份工具，支持增量备份和加密
- chkrootkit——检测系统是否被 rootkit 入侵的工具
- clamav——开源防病毒软件，用于检测病毒和恶意软件
- collectd——用于收集系统和网络性能指标，并提供监控与告警功能
- curl——数据传输工具，支持HTTP、HTTPS等协议，广泛用于API测试
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
"

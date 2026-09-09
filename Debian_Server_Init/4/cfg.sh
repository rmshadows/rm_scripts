#!/bin/bash
:<<注释
下面是需要填写的列表，要安装的软件。注意，格式是短杠空格接软件包名接破折号接软件包描述“- 【软件包名】——【软件包描述】”
注意：列表中请不要使用中括号
INDEX：1 轻量运维 / 2 = 1 + 运维增强 / 3 自定义（空，自己填）
INDEX 2 在 setup.sh 里会拼上 INDEX 1，本文件 INDEX_2 只写增量。
检查点二已装 zsh；openssh/git/python 由 Config 开关装，不要再写进 INDEX。
注释

# 稍后安装黑名单：只从当前 INDEX 挑出，脚本结束再装。不在 INDEX 里的不会强行装。
SET_APT_TO_INSTALL_LATER="
- apt-listbugs——apt显示bug信息。注意：阻碍自动安装，请过后手动安装
- apt-listchanges——apt显示更改。注意：阻碍自动安装，请过后手动安装
"

# 与 INDEX_3 相同用途；建议直接改 APT_TO_INSTALL_INDEX_3
APT_TO_INSTALL_INDEX_0="

"

# 轻量：SSH 运维常用（系统自带的 grep/sed/tar/ping、rsyslog、ssh 虚包不写）
APT_TO_INSTALL_INDEX_1="
- curl——命令行 HTTP/HTTPS 客户端
- htop——交互式进程查看
- inotify-tools——监控文件/目录变化
- lsof——查看进程打开的文件与端口
- mtr——综合 ping + traceroute
- nmap——端口与主机发现
- ripgrep——快速文本搜索（rg）
- rsync——文件同步与增量复制
- strace——跟踪系统调用
- sysstat——iostat/mpstat/sar 等历史性能
- tcpdump——抓包
- tmux——终端复用（断线可重连会话）
- traceroute——路由追踪
- wget——文件下载
"

# 增量（setup 选 INDEX 2 时 = INDEX 1 + 本段）。不含 Shorewall（检查点六）、不含常驻大件 clamav/netdata
APT_TO_INSTALL_INDEX_2="
- ansible——批量配置与远程执行
- auditd——内核审计日志
- fail2ban——反复失败登录自动封 IP
- gdb——C/C++ 调试器
- iperf3——带宽测试
- logwatch——日志摘要
- multitail——同时盯多个日志
- restic——加密去重备份
- rkhunter——rootkit 检测（会较吵，按需）
- valgrind——内存错误检测
"

# 自定义：把 INDEX 1/2 里需要的行拷过来再改
APT_TO_INSTALL_INDEX_3="

"

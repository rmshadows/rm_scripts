#!/bin/bash
:<<!说明
这里是全局变量
!说明

### 外部变量
# 无


### 脚本内部变量（一般无需更改）
# 每个组件的日志文件
ELOG_FILE="setup.log"
# Root用户UID
ROOT_UID=0
# 当前 Shell名称
CURRENT_SHELL=$SHELL
# 是否临时加入sudoer
TEMPORARILY_SUDOER=0
# 第一次运行DoAsRoot
FIRST_DO_AS_ROOT=1
# 第一次运行APT任务
FIRST_DO_APT=1
# 获取当前用户名（从这里开始才能使用此变量）
CURRENT_USER=$USER
# 主机名
HOSTNAME=$HOST

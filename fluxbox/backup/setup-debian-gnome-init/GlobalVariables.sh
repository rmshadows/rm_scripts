#!/bin/bash
:<<!说明
这里是全局变量
默认变量赋值在config
！！！！关于Debian 12.0.0: 建议使用前卸载raspi-firmware，否则可能apt升级出错，请使用purge ！
sudo apt purge raspi-firmware
预设参数（在这里修改预设参数, 谢谢）
注意：如果没有注释，默认0 为否 1 为是。
if [ "$" -eq 1 ];then
    
fi
!说明

### 外部变量
# root用户密码
ROOT_PASSWD=""


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

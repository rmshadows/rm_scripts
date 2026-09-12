#!/bin/bash
## 卸载 golang
## 需要 sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

# 1. 删除 golang 安装目录
sudo rm -rf /usr/local/go

# 2. 清空断点标记
prompt -s "golang 已卸载"

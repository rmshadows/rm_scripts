#!/bin/bash
:<<!说明
此脚本获取sudo
!说明

:<<!预先检查
确认运行
!预先检查

### 这里是确认运行的模块
comfirm "\e[1;31m 您已知晓该一键部署脚本的内容、作用、使用方法以及对您的计算机可能造成的潜在的危害「如果你不知道你在做什么，请直接回车谢谢」[y/N]\e[0m"
choice=$?
if [ $choice == 1 ]; then
    prompt -m "开始部署……"
elif [ $choice == 2 ]; then
    prompt -w "感谢您的关注！——  https://github.com/rmshadows"
    exit 0
fi


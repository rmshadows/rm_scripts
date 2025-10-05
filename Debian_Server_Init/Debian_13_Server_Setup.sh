#!/bin/bash
# https://github.com/rmshadows/rm_scripts
:<<!说明
Version：0.1.3
!说明


#### 初始化脚本
# 加载全局变量
source "GlobalVariables.sh"
# 加载全局函数
source "Lib.sh"
# 加载配置(在全局变量之后)
source "Config.sh"

# 脚本开始
source "0/0_start.sh"

# 预执行
source "0/init.sh"

#### 正文开始


cd 1
do_job "setup.sh" "$ELOG_FILE"
cd ..

cd 2
do_job "setup.sh" "$ELOG_FILE"
cd ..

cd 3
do_job "setup.sh" "$ELOG_FILE"
cd ..

cd 4
do_job "setup.sh" "$ELOG_FILE"
cd ..

cd 5
do_job "setup.sh" "$ELOG_FILE"
cd ..

cd 6
do_job "setup.sh" "$ELOG_FILE"
cd ..

cd 0
do_job "install_later.sh" "$ELOG_FILE"
do_job "the_end.sh" "$ELOG_FILE"
cd ..

#### 脚本结束
source "0/1_end.sh"

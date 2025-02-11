#!/bin/bash
# 需要修改！
cd 【$new_srv_path】
source kconfig.sh
# 停止原有的
./kplayer -c "$KCONF" play stop
./kplayer -c "$KCONF" play start -d


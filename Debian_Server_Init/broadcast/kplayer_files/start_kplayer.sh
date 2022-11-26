#!/bin/bash
# 需要修改！
cd SET_BROADCAST_PATH_CHANGEME/
source kconfig.sh
./kplayer -c "$KCONF" play stop
./kplayer -c "$KCONF" play start -d

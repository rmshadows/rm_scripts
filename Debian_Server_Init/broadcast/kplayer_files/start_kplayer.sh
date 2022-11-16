#!/bin/bash
# 需要修改！
cd /home/$USER/Applications/broadcast/kplayer/
source kconfig.sh
./kplayer -c "$KCONF" play stop
./kplayer -c "$KCONF" play start -d

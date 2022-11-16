#!/bin/bash
cd /home/$USER/Applications/broadcast/kplayer/
source kconfig.sh
./kplayer -c "$KCONF" play stop

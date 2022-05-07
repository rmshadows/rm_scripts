#!/bin/bash

# bilibili.service
P_bilibili_live="$HOME/Applications/broadcast/bilibili.service"
# bilibili_live.sh
P_bilibili_live_sh="$HOME/Applications/broadcast/bilibili_live.sh"
# inke.service
P_inke_live="$HOME/Applications/broadcast/inke.service"
# inke_live.sh
P_inke_live_sh="$HOME/Applications/broadcast/inke_live.sh"
# reset_inke.sh
P_inke_reset="$HOME/Applications/broadcast/"

sed s/changeme1/$P_bilibili_live/g bilibili.service
sed s/changeme2/$USER/g bilibili.service
sed s/changeme/$P_bilibili_live_sh/g bilibili_live.sh

sed s/changeme1/$P_inke_live/g inke.service
sed s/changeme2/$USER/g inke.service
sed s/changeme/$P_inke_live_sh/g inke_live.sh

sed s/changeme/$P_inke_reset/g reset_inke.sh


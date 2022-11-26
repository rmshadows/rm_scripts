#!/bin/bash
cd SET_BROADCAST_PATH_CHANGEME/
CONFF="conf.txt"
# 删除第一行
sed -i '1d' "$CONFF"
sed -i '1i RTMP=""' "$CONFF"
nano "$CONFF"

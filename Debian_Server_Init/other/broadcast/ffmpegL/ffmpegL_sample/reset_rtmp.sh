#!/bin/bash
cd 【$new_srv_path】
CONFF="conf.txt"
# 删除第一行
sed -i '1d' "$CONFF"
sed -i '1i RTMP=""' "$CONFF"
# 使用nano打开
nano "$CONFF"

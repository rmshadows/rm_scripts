#!/bin/bash
# 此脚本用于重新设置推流地址
source "kconfig.sh"

# 删除第一行
sed -i '1d' "$rtmp_file"
sed -i '1i RTMP_ADDR=""' "$rtmp_file"
nano "$rtmp_file"
# 直接重新设置RTMP地址
bash set_rtmp_addr.sh

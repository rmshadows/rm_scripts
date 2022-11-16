#!/bin/bash
# 删除第一行
sed -i '1d' RTMP.txt
sed -i '1i RTMP_ADDR=""' RTMP.txt
nano RTMP.txt
# 直接重新设置RTMP地址
set_rtmp_addr.sh

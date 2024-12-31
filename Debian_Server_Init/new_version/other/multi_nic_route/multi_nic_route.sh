#!/bin/bash
# multi_nic_route
# 多网卡多网段路由配置参考
# ip route -n
# 配置外网优先，单独设置内网路由

# 内网网卡
NNET_DEV=enxc868de36fee5
# 内网网关
NNET_GW="10.30.20.1"
# 内网网段
NNET1="10.100.10.0/24"
NNET2="10.100.60.0/24"
# 外网
WNET_GW="192.168.0.1"

# ip route show
# 删除默认路由(内外网都删)
sudo ip route del default

# 设置默认网关，默认走外网 sudo ip route add default via 192.168.0.1
sudo ip route add default via "$WNET_GW"

# 为内网设置内网转发特例 
sudo ip route del "$NNET1" via "$NNET_GW" dev "$NNET_DEV"
sudo ip route del "$NNET2" via "$NNET_GW" dev "$NNET_DEV"
sudo ip route add "$NNET1" via "$NNET_GW" dev "$NNET_DEV"
sudo ip route add "$NNET2" via "$NNET_GW" dev "$NNET_DEV"

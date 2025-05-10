#!/bin/bash

# 获取所有磁盘设备名称
disks=$(lsblk -d -n -o NAME)

# 让用户选择要检测的磁盘
echo "请选择要检测的磁盘："
select disk in $disks; do
    if [ -n "$disk" ]; then
        break
    else
        echo "无效选择，请重新选择"
    fi
done

# 磁盘路径
disk_path="/dev/$disk"

# 判断是否为 NVMe 硬盘
if [[ "$disk_path" == /dev/nvme* ]]; then
    echo "$disk_path 是 NVMe 硬盘，使用 NVMe 的 SMART 检查模式。"
    
    # 尝试使用 NVMe 模式获取 SMART 信息
    smartctl -d nvme -T permissive -a "$disk_path"
    if [ $? -ne 0 ]; then
        echo "$disk_path 不支持 SMART，无法进行健康检测。"
    fi
else
    # 对于非 NVMe 硬盘，使用普通的 smartctl 检查
    smartctl -a "$disk_path"
    if [ $? -ne 0 ]; then
        echo "$disk_path 不支持 SMART，无法进行健康检测。"
    fi
fi


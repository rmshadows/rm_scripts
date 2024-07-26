#!/bin/bash

# 配置要监测的软件的名称
SOFTWARE_NAME="wpscloudsvr"

# 设置检查间隔时间（秒）
CHECK_INTERVAL=2

while true; do
    # 检查软件是否在运行
    if pgrep "$SOFTWARE_NAME" > /dev/null; then
        echo "$SOFTWARE_NAME is running. Attempting to kill it..."

        # 杀死进程
        pkill "$SOFTWARE_NAME"

        # 检查杀死是否成功
        if [ $? -eq 0 ]; then
            echo "$SOFTWARE_NAME was successfully killed."
        else
            echo "Failed to kill $SOFTWARE_NAME."
        fi
    else
        echo "$SOFTWARE_NAME is not running."
    fi

    # 等待指定的时间后再次检查
    sleep "$CHECK_INTERVAL"
done

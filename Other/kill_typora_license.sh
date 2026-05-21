#!/bin/bash

# 自动关闭 Typora 授权弹窗（窗口名为 "License Info"），不杀主进程
while true; do
    # 搜索窗口名包含 "License Info" 的窗口
    win_ids=$(xdotool search --name "License Info" 2>/dev/null)

    if [ ! -z "$win_ids" ]; then
        for wid in $win_ids; do
            echo "[INFO] Found Typora License window with WID $wid. Closing..."
            # 模拟点击关闭按钮（相当于 Alt+F4）
            xdotool windowclose "$wid"
        done
    fi

    # 每 2 秒检查一次
    sleep 2
done


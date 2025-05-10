#!/bin/bash
# 监视文件访问（很难用）
# 监视当前目录
MONITOR_DIR="."

# 使用inotifywait监视目录内的文件访问
inotifywait -m -r -e open --format '%w%f' "$MONITOR_DIR" | while read FILE
do
    echo "文件被访问: $FILE"
    
    # 使用 fuser 查找正在访问该文件的进程
    PIDS=$(fuser "$FILE" 2>/dev/null)
    
    if [ -n "$PIDS" ]; then
        # 遍历每个 PID
        for PID in $PIDS
        do
            # 确保 PID 有效，获取程序的完整命令行
            COMMAND=$(ps -p $PID -o args= 2>/dev/null)
            
            if [ -n "$COMMAND" ]; then
                # 显示程序、PID、和用户
                USER=$(ps -p $PID -o user= 2>/dev/null)
                echo "程序: $COMMAND, PID: $PID, 用户: $USER"
            else
                # 如果无法获取命令行，尝试用 ps -e 获取进程信息
                COMMAND=$(ps -e -o pid,comm | grep "^$PID " | awk '{print $2}')
                if [ -n "$COMMAND" ]; then
                    USER=$(ps -p $PID -o user=)
                    echo "程序: $COMMAND, PID: $PID, 用户: $USER (无法获取完整命令行)"
                else
                    echo "无法获取程序命令行，PID: $PID (进程可能已经结束)"
                fi
            fi
        done
    else
        echo "没有找到访问该文件的进程。"
    fi
done

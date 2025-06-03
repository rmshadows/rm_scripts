#!/bin/bash
# 监视文件访问（很难用）

# 脚本用途：
# 该脚本用于实时监控某个目录中被访问（open）的文件，并尝试查找哪个进程正在访问该文件，
# 进而输出访问者的进程 ID（PID）、完整命令行及所属用户等信息。
#
# 使用示例：
#   ./monitor_file_access.sh         # 默认监控当前目录
#
# 技术说明：
#   - 使用 inotifywait 实时监听文件被 open（读取）事件
#   - 使用 fuser 获取访问该文件的 PID
#   - 使用 ps 获取该进程的用户和完整命令行
#
# 注意事项：
#   - 如果进程非常短命，fuser 可能无法及时捕获
#   - 不适合监控大量频繁变化的目录

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

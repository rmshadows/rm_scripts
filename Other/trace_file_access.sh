#!/bin/bash

# 默认值
PROGRAM=""
OUTPUT="strace_output.log"
TRANSLATE_CN=false
DEFAULT_CMD="ls"

# 脚本用途：
# 该脚本用于使用 strace 跟踪指定命令执行过程中的文件访问类系统调用（如 openat、execve 等）。
# 可将输出保存到日志文件中，并可选择将部分系统调用信息翻译为中文以增强可读性。
#
# 使用示例：
#   ./trace_file_access.sh -p "cat /etc/passwd" -o trace.log -c
#   ./trace_file_access.sh           # 默认跟踪 ls 命令
#
# 参数说明：
#   -p <命令>      指定要执行并跟踪的命令，支持带参数（默认执行 ls）
#   -o <输出文件>  指定将 strace 输出保存到的文件（默认: strace_output.log）
#   -c             启用输出内容的中文翻译（仅翻译常见系统调用及错误信息）


# 使用说明
usage() {
    echo "用法: $0 [-p <命令>] [-o <输出文件>] [-c]"
    echo "选项说明："
    echo "  -p <命令>       要跟踪的命令及参数（可省略，默认: ls）"
    echo "  -o <输出文件>   输出文件路径（默认: strace_output.log）"
    echo "  -c              将输出中的部分内容翻译为中文"
    exit 1
}

# 中文翻译函数（可扩展）
translate_syscalls_to_cn() {
    sed -e 's/execve/执行程序/g' \
        -e 's/openat/打开文件/g' \
        -e 's/access/检查文件访问权限/g' \
        -e 's/statfs/获取文件系统信息/g' \
        -e 's/newfstatat/获取文件状态/g' \
        -e 's/ENOENT (No such file or directory)/没有那个文件或目录/g' \
        -e 's/EACCES (Permission denied)/权限被拒绝/g'
}

# 解析参数
while getopts ":p:o:c" opt; do
    case ${opt} in
        p )
            PROGRAM=$OPTARG
            ;;
        o )
            OUTPUT=$OPTARG
            ;;
        c )
            TRANSLATE_CN=true
            ;;
        \? )
            usage
            ;;
    esac
done

# 使用默认命令（如未传入 -p）
if [[ -z "$PROGRAM" ]]; then
    PROGRAM=$DEFAULT_CMD
fi

# 拆分命令字符串为数组（支持带参数的命令）
IFS=' ' read -r -a CMD_ARR <<< "$PROGRAM"

# 检查 strace 是否安装
if ! command -v strace &>/dev/null; then
    echo "错误：未安装 strace，请先安装它。"
    exit 1
fi

# 执行 strace（跟踪文件访问相关系统调用）
RAW_OUTPUT=$(mktemp)
strace -e trace=file -f "${CMD_ARR[@]}" 2> "$RAW_OUTPUT"

# 根据选项输出内容
if $TRANSLATE_CN; then
    translate_syscalls_to_cn < "$RAW_OUTPUT" | tee "$OUTPUT"
else
    cat "$RAW_OUTPUT" | tee "$OUTPUT"
fi

# 清理
rm -f "$RAW_OUTPUT"

#!/bin/bash

# 默认值
PROGRAM=""
OUTPUT="strace_output.log"
TRANSLATE_CN=false
DEFAULT_CMD="ls"

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

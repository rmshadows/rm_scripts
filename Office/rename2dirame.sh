#!/bin/bash

# 默认参数
default_ext_filter=""  # 空则不限制扩展名
default_run_mode="false"
default_move="false"
default_target_dir="."

# 解析参数
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --ext) ext_filter="$2"; shift ;;
        --run) run_mode="true" ;;
        --move) move_files="true" ;;
        --target-dir) target_dir="$2"; shift ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
    shift
done

ext_filter="${ext_filter:-$default_ext_filter}"
run_mode="${run_mode:-$default_run_mode}"
move_files="${move_files:-$default_move}"
target_dir="${target_dir:-$default_target_dir}"

# 转换扩展名过滤为数组
IFS=',' read -ra ext_array <<< "$ext_filter"
should_filter_exts=false
[[ -n "$ext_filter" ]] && should_filter_exts=true

echo "=== 脚本配置 ==="
echo "扩展名过滤: ${ext_filter:-所有文件}"
echo "是否执行: $run_mode"
echo "是否移动文件: $move_files"
echo "目标目录: $target_dir"
echo

# 排除脚本文件本身
script_name=$(basename "$0")

# 遍历所有文件
find . -type f -not -name "$script_name" | while read -r filepath; do
    filename=$(basename "$filepath")
    dirname=$(dirname "$filepath" | sed 's|^\./||')  # 去掉前导"./"

    # 判断扩展名
    ext="${filename##*.}"
    if $should_filter_exts; then
        matched=false
        for e in "${ext_array[@]}"; do
            [[ "$ext" == "$e" ]] && matched=true && break
        done
        $matched || continue
    fi

    # 构造新文件名
    newname="${dirname//\//-}-$filename"
    newpath="$target_dir/$newname"

    # 显示或执行(这里调整移动或者复制)
    if [[ "$run_mode" == "true" ]]; then
        if [[ "$move_files" == "true" ]]; then
            mv "$filepath" "$newpath"
        else
            mv "$filepath" "$(dirname "$filepath")/$newname"
        fi
        echo "[重命名] $filepath → $newpath"
    else
        echo "[预览] $filepath → $newpath"
    fi
done


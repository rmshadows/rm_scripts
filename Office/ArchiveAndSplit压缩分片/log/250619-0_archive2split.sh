#!/bin/bash

# 参数配置
folder="a"        # 固定文件夹路径
split_size="90M"  # 固定分割大小
mode=2            # 模式选择，1=分别打包压缩包，2=打包一个后再split
aformat=1         # 压缩格式选择，1=zip, 2=tar.xz
ext="zip"         # 压缩包文件的扩展名（zip 或 tar.xz）
zip_password=""   # 可选参数：为zip文件设置密码（例如 "mysecretpassword"）

# 显示用法信息
echo "Usage: This script compresses the folder '$folder'."
echo "Mode: $mode"
echo "Compression Format: $aformat"
echo "Compression Extension: $ext"
echo "Each part will not exceed $split_size in size."

# 将大小单位转换为字节，便于比较（支持 M 和 G）
split_size_bytes=$(numfmt --from=iec "$split_size")

# 获取文件夹的名称，用于生成压缩包文件名
folder_name=$(basename "$folder")

# 检查文件夹路径是否存在
if [[ ! -d "$folder" ]]; then
    echo "Error: Folder '$folder' does not exist!"
    exit 1
fi

# 根据模式处理压缩
if [[ "$mode" -eq 1 ]]; then
    # 模式1：将文件夹内容分割成多个压缩包，且每个压缩包大小不超过设定值
    echo "Mode 1: Compressing the folder '$folder' into multiple separate parts, each not exceeding $split_size."

    # 获取文件夹内所有文件和子文件夹
    files=("$folder"/*)
    part_num=1
    current_size=0
    temp_dir=$(mktemp -d)  # 临时目录，用于存储待压缩文件

    # 遍历文件并分组压缩
    for file in "${files[@]}"; do
        # 获取文件的大小
        file_size=$(du -sb "$file" | cut -f1)

        # 如果当前文件单独大于分割大小，则报错并跳过
        if [[ "$file_size" -gt "$split_size_bytes" ]]; then
            echo "Warning: '$file' is larger than the split size and will be compressed separately."
            if [[ "$aformat" -eq 1 ]]; then
                # 如果有密码，添加 -P 参数
                if [[ -n "$zip_password" ]]; then
                    zip -r -P "$zip_password" "${folder_name}_part${part_num}.${ext}" "$file"
                else
                    zip -r "${folder_name}_part${part_num}.${ext}" "$file"
                fi
            elif [[ "$aformat" -eq 2 ]]; then
                tar -caf "${folder_name}_part${part_num}.${ext}" "$file"
            fi
            part_num=$((part_num + 1))
            continue
        fi

        # 如果将当前文件加入到当前压缩包后超过限制，则创建新压缩包
        if (( current_size + file_size > split_size_bytes )); then
            # 创建压缩包
            echo "Creating compression part $part_num..."
            if [[ "$aformat" -eq 1 ]]; then
                # 如果有密码，添加 -P 参数
                if [[ -n "$zip_password" ]]; then
                    zip -r -P "$zip_password" "${folder_name}_part${part_num}.${ext}" "$temp_dir"
                else
                    zip -r "${folder_name}_part${part_num}.${ext}" "$temp_dir"
                fi
            elif [[ "$aformat" -eq 2 ]]; then
                tar -caf "${folder_name}_part${part_num}.${ext}" "$temp_dir"
            fi

            # 清空临时目录并准备下一个压缩包
            rm -rf "$temp_dir"
            temp_dir=$(mktemp -d)
            part_num=$((part_num + 1))
            current_size=0
        fi

        # 将文件加入当前临时目录
        cp -r "$file" "$temp_dir"
        current_size=$((current_size + file_size))
    done

    # 处理最后一个压缩包
    if [[ -d "$temp_dir" && "$(ls -A "$temp_dir")" ]]; then
        echo "Creating compression part $part_num..."
        if [[ "$aformat" -eq 1 ]]; then
            # 如果有密码，添加 -P 参数
            if [[ -n "$zip_password" ]]; then
                zip -r -P "$zip_password" "${folder_name}_part${part_num}.${ext}" "$temp_dir"
            else
                zip -r "${folder_name}_part${part_num}.${ext}" "$temp_dir"
            fi
        elif [[ "$aformat" -eq 2 ]]; then
            tar -caf "${folder_name}_part${part_num}.${ext}" "$temp_dir"
        fi
    fi

    # 清理临时目录
    rm -rf "$temp_dir"

elif [[ "$mode" -eq 2 ]]; then
    # 模式2：先打包一个压缩包，再分割压缩包
    echo "Mode 2: Compressing entire folder '$folder' into a single file and then splitting it."

    # 根据压缩格式选择
    if [[ "$aformat" -eq 1 ]]; then
        # 使用 zip 格式
        if [[ -n "$zip_password" ]]; then
            zip -r -P "$zip_password" "$folder_name.${ext}" "$folder"
        else
            zip -r "$folder_name.${ext}" "$folder"
        fi
        # 分割 zip 文件，使用数字序号
        split -d -b "$split_size" "$folder_name.${ext}" "${folder_name}_part_"
    elif [[ "$aformat" -eq 2 ]]; then
        # 使用 tar.xz 格式
        tar -caf "$folder_name.${ext}" "$folder"
        # 分割 tar.xz 文件，使用数字序号
        split -d -b "$split_size" "$folder_name.${ext}" "${folder_name}_part_"
    else
        echo "Unsupported compression format: $aformat"
        exit 1
    fi
else
    echo "Invalid mode selected. Use mode 1 for multiple compressed parts or mode 2 for full folder compression."
    exit 1
fi

echo "Compression and splitting process completed."

# 提示用户合并命令（针对 Windows 和 Linux）
echo ""
echo "To merge the split archive files in Windows, use the following CMD command:"
if [[ "$aformat" -eq 1 ]]; then
    echo "copy /b ${folder_name}_part_00 + ${folder_name}_part_01 + ${folder_name}_part_02 ... ${folder_name}.zip"
elif [[ "$aformat" -eq 2 ]]; then
    echo "copy /b ${folder_name}_part_00 + ${folder_name}_part_01 + ${folder_name}_part_02 ... ${folder_name}.tar.xz"
fi

echo ""
echo "To merge the split archive files in Linux, use the following command:"
if [[ "$aformat" -eq 1 ]]; then
    echo "cat ${folder_name}_part_* > ${folder_name}.zip"
elif [[ "$aformat" -eq 2 ]]; then
    echo "cat ${folder_name}_part_* > ${folder_name}.tar.xz"
fi
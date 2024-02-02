#!/bin/bash
## 搜索word文件，转化为txt文本 保持目录结构

cmdToCheck="pandoc"
if ! [ -x "$(command -v "$cmdToCheck")" ]; then
    echo "Error: "$cmdToCheck" is not installed." >&2
    sudo apt install "$cmdToCheck"
fi
cmdToCheck="antiword"
if ! [ -x "$(command -v "$cmdToCheck")" ]; then
    echo "Error: "$cmdToCheck" is not installed." >&2
    sudo apt install "$cmdToCheck"
fi
cmdToCheck="libreoffice"
if ! [ -x "$(command -v "$cmdToCheck")" ]; then
    echo "Error: "$cmdToCheck" is not installed." >&2
    sudo apt install "$cmdToCheck"
fi

# 搜索的文件夹
directory_path="."
# 搜索的文件扩展名
file_extensions=("doc" "docx" "wps")
# 导出的位置
mirror_out="Mirror-0-Database"
# 去除文件名中的空格(仅导出的文件)
no_blank_filename=1
# 如果导出的文件存在是否覆盖
ooverwrite=0

function find_files_with_extensions() {
    local directory_path="$1"
    local file_extensions=("${@:2}")

    if [ -d "$directory_path" ]; then
        ffwe_file_list=()

        for ext in "${file_extensions[@]}"; do
            mapfile -t files_for_extension < <(find "$directory_path" -type f -iname "*.$ext" -exec readlink -f {} \;)
            ffwe_file_list+=("${files_for_extension[@]}")
        done
        # echo "${ffwe_file_list[@]}"
        # for file_path in "${ffwe_file_list[@]}"; do
        # echo "文件路径: \"$file_path\""
        # done
    else
        echo "目录不存在: $directory_path"
    fi
}

function find_files_with_extensions1() {
    local directory_path="$1"
    local file_extensions=("${@:2}")

    if [ -d "$directory_path" ]; then
        local files=()
        for extension in "${file_extensions[@]}"; do
            while IFS= read -r -d '' file; do
                files+=("$file")
            done < <(find "$directory_path" -type f -iname "*.$extension" -print0)
        done

        if [ ${#files[@]} -eq 0 ]; then
            echo "当前目录及其子目录中没有指定扩展名的文件。"
        else
            echo "指定扩展名的文件列表："
            printf '%s\n' "${files[@]}"
        fi
    else
        echo "目录不存在: $directory_path"
    fi
}

# 函数：将相对路径转为绝对路径
# 参数：
#   $1: 相对路径
function convert_relative_to_absolute() {
    local relative_path="$1"
    absolute_path=$(realpath "$relative_path")
    echo "$absolute_path"
}

# 函数：将绝对路径转为相对路径
# 参数：
#   $1: 绝对路径
#   $2: 基础目录
function convert_absolute_to_relative() {
    local absolute_path="$1"
    local base_directory="$2"

    # 获取相对路径
    relative_path=$(python -c "from os.path import relpath; print(relpath('$absolute_path', '$base_directory'))")
    echo "$relative_path"
}

# 函数：生成去除文件名的路径
# 参数：
#   $1: 绝对路径
function get_directory_path() {
    local absolute_path="$1"
    directory_path=$(dirname "$absolute_path")
    echo "$directory_path"
}

find_files_with_extensions "$directory_path" "${file_extensions[@]}"

# 打印数组内容
# printf '%s\n' "${ffwe_file_list[@]}"

# 打印文件列表
# for file_path in "${ffwe_file_list[@]}"; do
#     echo "文件路径: \"$file_path\""
# done

# 打印文件列表
for file_path in "${ffwe_file_list[@]}"; do
    # 绝对路径转相对路径(构建相对路径)
    srcfr=$(convert_absolute_to_relative "$file_path" ".")
    # 获取相对路径的文件夹名
    dstdr=$(get_directory_path "$srcfr")

    if [ "$no_blank_filename" -eq 1 ]; then
        # 构建目标路径，将空格替换为下划线
        target_path="$mirror_out/$(echo "$srcfr" | sed 's/ /_/g')"
        # 创建的文件夹
        tmkd="$mirror_out/$(echo "$dstdr" | sed 's/ /_/g')"
    else
        # 构建目标路径
        target_path="$mirror_out/$srcfr"
        tmkd="$mirror_out/$dstdr"
    fi

    # 修改文件扩展名
    # 提取文件名和目录路径
    directory_path=$(dirname "$target_path")
    filename=$(basename "$target_path")
    # 将文件名中的扩展名替换为 .txt
    target_filename="${filename%.*}.txt"
    # 构建目标路径
    target_path="$directory_path/$target_filename"
    # 输出修改后的文件路径
    # echo "原文件路径: $file_path"
    # echo "新文件路径: $target_path"

    if ! [ -d "$tmkd" ]; then
        # 确保目标目录存在
        echo "【mkdir】: $tmkd"
        mkdir -p "$tmkd"
    fi

    # 复制文件(测试)
    # cp "$file_path" "$target_path"

    # 转化docx到txt
    # 获取文件扩展名
    fext="${file_path##*.}"
    fext=$(echo "$fext" | tr '[:upper:]' '[:lower:]')
    if [[ "$ooverwrite" -eq 1 ]]; then
        # 覆盖
        echo "【File】: $file_path -> $target_path"
        # 判断文件扩展名
        if [[ "$fext" == "doc" ]]; then
            # 使用antiword
            antiword "$file_path" >"$target_path" 2>>"error_log.txt"
            if [ "$?" -ne 0 ]; then
                # 提取文件名
                tfn=$(basename "$file_path")
                tdir=$(get_directory_path "$target_path")
                outputfp="$tdir lo-$tfn"
                # 在文件名前面加前缀
                nfn="$prefix$tfn"
                # 合并路径
                output_path="$target_path$nfn"
                libreoffice --headless --convert-to txt:Text --outdir "$outputfp" "$file_path" 2>>"error_log.txt"
            fi
        elif [[ "$fext" == "docx" ]]; then
            pandoc -s "$file_path" -t plain -o "$target_path" 2>>"error_log.txt"
            if [ "$?" -ne 0 ]; then
                # 提取文件名
                tfn=$(basename "$file_path")
                tdir=$(get_directory_path "$target_path")
                outputfp="$tdir lo-$tfn"
                # 在文件名前面加前缀
                nfn="$prefix$tfn"
                # 合并路径
                output_path="$target_path$nfn"
                libreoffice --headless --convert-to txt:Text --outdir "$outputfp" "$file_path" 2>>"error_log.txt"
            fi
        elif [[ "$fext" == "wps" ]]; then
            antiword "$file_path" >"$target_path" 2>>"error_log.txt"
            if [ "$?" -ne 0 ]; then
                # 提取文件名
                tfn=$(basename "$file_path")
                tdir=$(get_directory_path "$target_path")
                outputfp="$tdir lo-$tfn"
                # 在文件名前面加前缀
                nfn="$prefix$tfn"
                # 合并路径
                output_path="$target_path$nfn"
                libreoffice --headless --convert-to txt:Text --outdir "$outputfp" "$file_path" 2>>"error_log.txt"
            fi
        else
            # 记录无法处理的文件到日志
            echo "$file_path" >>"no_convert.log"
            # libreoffice --headless --convert-to txt:Text --outdir "$target_path" "$file_path"
        fi
    else
        # 不覆盖
        if ! [[ -f "$target_path" ]]; then
            echo "【File】: $file_path -> $target_path"
            # 判断文件扩展名
            if [[ "$fext" == "doc" ]]; then
                # 使用antiword
                antiword "$file_path" >"$target_path" 2>>"error_log.txt"
                if [ "$?" -ne 0 ]; then
                    # 提取文件名
                    tfn=$(basename "$file_path")
                    tdir=$(get_directory_path "$target_path")
                    outputfp="$tdir lo-$tfn"
                    # 在文件名前面加前缀
                    nfn="$prefix$tfn"
                    # 合并路径
                    output_path="$target_path$nfn"
                    libreoffice --headless --convert-to txt:Text --outdir "$outputfp" "$file_path" 2>>"error_log.txt"
                fi
            elif [[ "$fext" == "docx" ]]; then
                pandoc -s "$file_path" -t plain -o "$target_path" 2>>"error_log.txt"
                if [ "$?" -ne 0 ]; then
                    # 提取文件名
                    tfn=$(basename "$file_path")
                    tdir=$(get_directory_path "$target_path")
                    outputfp="$tdir lo-$tfn"
                    # 在文件名前面加前缀
                    nfn="$prefix$tfn"
                    # 合并路径
                    output_path="$target_path$nfn"
                    libreoffice --headless --convert-to txt:Text --outdir "$outputfp" "$file_path" 2>>"error_log.txt"
                fi
            elif [[ "$fext" == "wps" ]]; then
                antiword "$file_path" >"$target_path" 2>>"error_log.txt"
                if [ "$?" -ne 0 ]; then
                    # 提取文件名
                    tfn=$(basename "$file_path")
                    tdir=$(get_directory_path "$target_path")
                    outputfp="$tdir lo-$tfn"
                    # 在文件名前面加前缀
                    nfn="$prefix$tfn"
                    # 合并路径
                    output_path="$target_path$nfn"
                    libreoffice --headless --convert-to txt:Text --outdir "$outputfp" "$file_path" 2>>"error_log.txt"
                fi
            else
                # 记录无法处理的文件到日志
                echo "$file_path" >>"no_convert.log"
            fi
        fi
    fi
done

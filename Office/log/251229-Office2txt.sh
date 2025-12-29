#!/bin/bash
## 搜索指定文件夹下（src）的word,excel文件，转化为txt文本 保持目录结构

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
    sudo apt-get install libreoffice
    sudo apt-get install libreoffice-java-common
fi

# 搜索的文件夹
# directory_path="src"
# 获取输入参数，默认为 src
directory_path="${1:-src}"

# 搜索的word文件扩展名
word_extensions=("doc" "docx" "wps")
# 搜索的Excel文件扩展名
excel_extensions=("xlsx" "xls" "et" "csv")
# 导出的位置
mirror_out="office_mirror"
# 去除文件名中的空格(仅导出的文件)
no_blank_filename=1
# 如果导出的文件存在是否覆盖
ooverwrite=1

function find_files_with_extensions() {
    local directory_path="$1"
    local extensions=("${@:2}")
    
    if [ -d "$directory_path" ]; then
        ffwe_file_list=()
        for ext in "${extensions[@]}"; do
            mapfile -t files_for_extension < <(find "$directory_path" -type f -iname "*.$ext" -exec readlink -f {} \;)
            ffwe_file_list+=("${files_for_extension[@]}")
        done
        # echo "${ffwe_file_list[@]}"
        # for file_path in "${ffwe_file_list[@]}"; do
        #     echo "文件路径: \"$file_path\""
        # done
    else
        echo "目录不存在: $directory_path"
    fi
}

# 相对路径
function find_files_with_extensions1() {
    local directory_path="$1"
    local extensions=("${@:2}")
    
    if [ -d "$directory_path" ]; then
        local files=()
        for extension in "${extensions[@]}"; do
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

function getFileEncoding() {
    getFileEncoding=""
    # text/plain; charset=utf-8
    tfo=$(file -bi "$ele")
    OLD_IFS="$IFS"
    # 以“charset=”为分隔符
    IFS="="
    gotArr=($tfo)
    IFS="$OLD_IFS"
    getFileEncoding=${gotArr[1]}
}



convert_word_to_txt() {
    # 绝对路径转相对路径(构建相对路径)
    srcfr=$(convert_absolute_to_relative "$1" ".")
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
    if [ "$ooverwrite" -eq 1 ]; then
        # 覆盖
        echo "【File】: $file_path -> $target_path"
        # 判断文件扩展名
        if [ "$fext" = "doc" ]; then
            # 尝试 antiword
            if ! antiword "$file_path" >"$target_path" 2>>error_log.txt; then
                echo "antiword 失败，尝试 catdoc: $file_path" >> error_log.txt
                catdoc "$file_path" >"$target_path" 2>>error_log.txt
            fi
            elif [ "$fext" == "docx" ]; then
            pandoc -s "$file_path" -t plain -o "$target_path" 2>>"error_log.txt"
            elif [ "$fext" == "wps" ]; then
            antiword "$file_path" >"$target_path" 2>>"error_log.txt"
        else
            # 记录无法处理的文件到日志
            libreoffice --headless --convert-to txt:Text "$file_path" --outdir "$target_path"
            if [ "$?" -ne 0 ]; then
                echo "$file_path" >>no_convert.log
            fi
            echo "$file_path" >>"no_convert.log"
        fi
    else
        # 不覆盖
        if ! [ -f "$target_path" ]; then
            echo "【File】: $file_path -> $target_path"
            # 判断文件扩展名
            if [ "$fext" == "doc" ]; then
                # 使用antiword
                antiword "$file_path" >"$target_path" 2>>"error_log.txt"
                elif [ "$fext" == "docx" ]; then
                pandoc -s "$file_path" -t plain -o "$target_path" 2>>"error_log.txt"
                elif [ "$fext" == "wps" ]; then
                antiword "$file_path" >"$target_path" 2>>"error_log.txt"
            else
                libreoffice --headless --convert-to txt:Text "$file_path" --outdir "$target_path"
                if [ "$?" -ne 0 ]; then
                    echo "$file_path" >>no_convert.log
                fi
                # 记录无法处理的文件到日志
                echo "$file_path" >>"no_convert.log"
            fi
        fi
        
    fi
}

convert_excel_to_txt() {
    # 绝对路径转相对路径(构建相对路径)
    srcfr=$(convert_absolute_to_relative "$1" ".")
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
    
    # 转化excel到txt
    # 获取文件扩展名
    fext="${file_path##*.}"
    if [ "$ooverwrite" -eq 1 ]; then
        # 覆盖
        echo "【File】: $file_path -> $target_path"
        if [ "$fext" == "csv" ]; then
            if [ "$getFileEncoding" != "utf-8" ]; then
                iconv -c -f GBK -t UTF-8 "$file_path" -o "$target_path"
            else
                cp "$file_path" "$target_path"
            fi
            if [ "$?" -ne 0 ]; then
                echo "$file_path" >>no_convert.log
            fi
        else
            libreoffice --headless --infilter=CSV:44,34,76,1 --convert-to csv --outdir "$target_path" "$file_path"
            if [ "$?" -ne 0 ]; then
                echo "$file_path" >>no_convert.log
            fi
        fi
    else
        # 不覆盖
        if ! [ -f "$target_path" ]; then
            echo "【File】: $file_path -> $target_path"
            if [ "$fext" == "csv" ]; then
                if [ "$getFileEncoding" != "utf-8" ]; then
                    iconv -c -f GBK -t UTF-8 "$file_path" -o "$target_path"
                else
                    cp "$file_path" "$target_path"
                fi
                if [ "$?" -ne 0 ]; then
                    echo "$file_path" >>no_convert.log
                fi
            else
                libreoffice --headless --infilter=CSV:44,34,76,1 --convert-to csv --outdir "$target_path" "$file_path"
                if [ "$?" -ne 0 ]; then
                    echo "$file_path" >>no_convert.log
                fi
            fi
        fi
    fi
}

function check_file_type() {
    local file_path="$1"
    local extension="${file_path##*.}"
    extension="${extension,,}"  # 转为小写，避免扩展名大小写不一致
    
    # 直接引用全局数组
    local word_exts=("${word_extensions[@]}")
    local excel_exts=("${excel_extensions[@]}")
    
    # 检查是否是 Word 文件
    for ext in "${word_exts[@]}"; do
        if [[ "$extension" == "$ext" ]]; then
            echo "Word"
            return
        fi
    done
    
    # 检查是否是 Excel 文件
    for ext in "${excel_exts[@]}"; do
        if [[ "$extension" == "$ext" ]]; then
            echo "Excel"
            return
        fi
    done
    
    # 不是 Word 或 Excel 文件
    echo "Other"
}

# 如果是文件就直接处理
if [ -f "$directory_path" ]; then
    mkdir -p officeTempWS
    cp "$directory_path" ./officeTempWS/
    directory_path="./officeTempWS/"
    # file_type=$(check_file_type "$directory_path")
    # case "$file_type" in
    #     "Word")
    #         echo "处理 Word 文件: $directory_path"
    #         # 示例：调用处理 Word 的函数或命令
    #         convert_word_to_txt twp
    #         exit 0
    #         ;;
    #     "Excel")
    #         echo "处理 Excel 文件: $directory_path"
    #         # 示例：调用处理 Excel 的函数或命令
    #         convert_excel_to_txt twp
    #         exit 0
    #         ;;
    #     "Other")
    #         echo "不支持的文件类型: $directory_path"
    #         exit 0
    #         ;;
    # esac
fi


##########################################################################################
# 处理word
find_files_with_extensions "$directory_path" "${word_extensions[@]}"

# 打印数组内容
# printf '%s\n' "${ffwe_file_list[@]}"

# 打印文件列表
# for file_path in "${ffwe_file_list[@]}"; do
#     echo "文件路径: \"$file_path\""
# done

# 打印文件列表
for file_path in "${ffwe_file_list[@]}"; do
    convert_word_to_txt "$file_path"
done

# Excel转txt
echo "==========================================================================="

find_files_with_extensions "$directory_path" "${excel_extensions[@]}"

# 打印文件列表
for file_path in "${ffwe_file_list[@]}"; do
    convert_excel_to_txt "$file_path"
done

if [ -d "officeTempWS" ];then
    rm -r officeTempWS
fi

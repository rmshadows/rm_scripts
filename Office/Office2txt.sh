#!/bin/bash
set -euo pipefail
## 搜索指定文件夹下（src）的word,excel文件，转化为txt文本 保持目录结构

cmdToCheck="pandoc"
if ! [ -x "$(command -v "$cmdToCheck")" ]; then
    echo "Error: $cmdToCheck is not installed." >&2
    sudo apt install -y "$cmdToCheck"
fi
cmdToCheck="antiword"
if ! [ -x "$(command -v "$cmdToCheck")" ]; then
    echo "Error: $cmdToCheck is not installed." >&2
    sudo apt install -y "$cmdToCheck"
fi

cmdToCheck="libreoffice"
if ! [ -x "$(command -v "$cmdToCheck")" ]; then
    echo "Error: $cmdToCheck is not installed." >&2
    sudo apt-get update
    sudo apt-get install -y libreoffice libreoffice-java-common
fi

# 搜索的文件夹：获取输入参数，默认为 src
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
    else
        echo "目录不存在: $directory_path"
    fi
}

# 函数：将相对路径转为绝对路径
function convert_relative_to_absolute() {
    local relative_path="$1"
    realpath "$relative_path"
}

# 函数：将绝对路径转为相对路径（安全版：避免路径里出现 ' 导致 python 语法错误）
function convert_absolute_to_relative() {
    local absolute_path="$1"
    local base_directory="$2"
    python3 - "$absolute_path" "$base_directory" <<'PY'
import os, sys
print(os.path.relpath(sys.argv[1], sys.argv[2]))
PY
}

# 函数：生成去除文件名的路径
function get_directory_path() {
    local p="$1"
    dirname "$p"
}

# 获取文件编码（返回 charset）
function getFileEncoding() {
    local fp="$1"
    local tfo
    tfo=$(file -bi "$fp")   # e.g. text/plain; charset=utf-8
    echo "${tfo##*=}"       # 取 charset= 后面
}

# 用 libreoffice 转换到指定 target_path（outdir 必须是目录，生成后再改名/移动）
function libreoffice_convert_to_txt_to_target() {
    local file_path="$1"
    local target_path="$2"
    local outdir
    outdir="$(dirname "$target_path")"
    mkdir -p "$outdir"

    # 先在 outdir 生成同名 txt
    libreoffice --headless --convert-to txt:Text --outdir "$outdir" "$file_path" >/dev/null 2>>"error_log.txt" || return 1

    local base
    base="$(basename "$file_path")"
    local produced="$outdir/${base%.*}.txt"

    if [ -f "$produced" ]; then
        mv -f "$produced" "$target_path"
        return 0
    fi

    # 某些格式可能产生不同后缀名，兜底找一个最新 txt
    local newest
    newest="$(ls -1t "$outdir"/*.txt 2>/dev/null | head -n 1 || true)"
    if [ -n "${newest:-}" ] && [ -f "$newest" ]; then
        mv -f "$newest" "$target_path"
        return 0
    fi

    return 1
}

function libreoffice_convert_to_csv_to_target() {
    local file_path="$1"
    local target_path="$2"
    local outdir
    outdir="$(dirname "$target_path")"
    mkdir -p "$outdir"

    libreoffice --headless --convert-to csv --outdir "$outdir" "$file_path" >/dev/null 2>>"error_log.txt" || return 1

    local base
    base="$(basename "$file_path")"
    local produced="$outdir/${base%.*}.csv"

    if [ -f "$produced" ]; then
        mv -f "$produced" "$target_path"
        return 0
    fi

    local newest
    newest="$(ls -1t "$outdir"/*.csv 2>/dev/null | head -n 1 || true)"
    if [ -n "${newest:-}" ] && [ -f "$newest" ]; then
        mv -f "$newest" "$target_path"
        return 0
    fi

    return 1
}

convert_word_to_txt() {
    local file_path="$1"

    # 绝对路径转相对路径(构建相对路径)
    local srcfr
    srcfr="$(convert_absolute_to_relative "$file_path" ".")"

    # 获取相对路径的文件夹名
    local dstdr
    dstdr="$(get_directory_path "$srcfr")"

    local target_path tmkd
    if [ "$no_blank_filename" -eq 1 ]; then
        target_path="$mirror_out/$(echo "$srcfr" | sed 's/ /_/g')"
        tmkd="$mirror_out/$(echo "$dstdr" | sed 's/ /_/g')"
    else
        target_path="$mirror_out/$srcfr"
        tmkd="$mirror_out/$dstdr"
    fi

    # 修改文件扩展名为 .txt
    local directory_path filename target_filename
    directory_path="$(dirname "$target_path")"
    filename="$(basename "$target_path")"
    target_filename="${filename%.*}.txt"
    target_path="$directory_path/$target_filename"

    if ! [ -d "$tmkd" ]; then
        echo "【mkdir】: $tmkd"
        mkdir -p "$tmkd"
    fi

    local fext="${file_path##*.}"
    fext="${fext,,}"

    if [ "$ooverwrite" -eq 0 ] && [ -f "$target_path" ]; then
        return 0
    fi

    echo "【File】: $file_path -> $target_path"

    if [ "$fext" = "doc" ]; then
        if ! antiword "$file_path" >"$target_path" 2>>error_log.txt; then
            echo "antiword 失败，尝试 catdoc: $file_path" >> error_log.txt
            catdoc "$file_path" >"$target_path" 2>>error_log.txt || {
                echo "$file_path" >>"no_convert.log"
                return 0
            }
        fi
    elif [ "$fext" = "docx" ]; then
        pandoc -s "$file_path" -t plain -o "$target_path" 2>>"error_log.txt" || {
            echo "$file_path" >>"no_convert.log"
            return 0
        }
    elif [ "$fext" = "wps" ]; then
        # wps 很多时候 antiword 不一定行，失败就用 libreoffice 兜底
        if ! antiword "$file_path" >"$target_path" 2>>"error_log.txt"; then
            if ! libreoffice_convert_to_txt_to_target "$file_path" "$target_path"; then
                echo "$file_path" >>"no_convert.log"
            fi
        fi
    else
        if ! libreoffice_convert_to_txt_to_target "$file_path" "$target_path"; then
            echo "$file_path" >>"no_convert.log"
        fi
    fi
}

convert_excel_to_txt() {
    local file_path="$1"

    # 绝对路径转相对路径(构建相对路径)
    local srcfr
    srcfr="$(convert_absolute_to_relative "$file_path" ".")"

    # 获取相对路径的文件夹名
    local dstdr
    dstdr="$(get_directory_path "$srcfr")"

    local target_path tmkd
    if [ "$no_blank_filename" -eq 1 ]; then
        target_path="$mirror_out/$(echo "$srcfr" | sed 's/ /_/g')"
        tmkd="$mirror_out/$(echo "$dstdr" | sed 's/ /_/g')"
    else
        target_path="$mirror_out/$srcfr"
        tmkd="$mirror_out/$dstdr"
    fi

    # 输出统一为 .txt（CSV 就先转 utf-8 后保存为 txt；其他表格先转 csv 再保存为 txt）
    local directory_path filename target_filename
    directory_path="$(dirname "$target_path")"
    filename="$(basename "$target_path")"
    target_filename="${filename%.*}.txt"
    target_path="$directory_path/$target_filename"

    if ! [ -d "$tmkd" ]; then
        echo "【mkdir】: $tmkd"
        mkdir -p "$tmkd"
    fi

    local fext="${file_path##*.}"
    fext="${fext,,}"

    if [ "$ooverwrite" -eq 0 ] && [ -f "$target_path" ]; then
        return 0
    fi

    echo "【File】: $file_path -> $target_path"

    if [ "$fext" = "csv" ]; then
        local enc
        enc="$(getFileEncoding "$file_path")"
        if [ "$enc" != "utf-8" ]; then
            iconv -c -f GBK -t UTF-8 "$file_path" -o "$target_path" 2>>"error_log.txt" || {
                echo "$file_path" >>"no_convert.log"
                return 0
            }
        else
            cp "$file_path" "$target_path" || {
                echo "$file_path" >>"no_convert.log"
                return 0
            }
        fi
    else
        # 先转为 csv 到临时文件，再改名为 txt（内容仍是 csv 文本）
        local tmp_csv="${target_path%.txt}.csv"
        if libreoffice_convert_to_csv_to_target "$file_path" "$tmp_csv"; then
            mv -f "$tmp_csv" "$target_path"
        else
            echo "$file_path" >>"no_convert.log"
        fi
    fi
}

# 如果是文件就直接处理：复制到临时目录，避免原地处理出问题
if [ -f "$directory_path" ]; then
    mkdir -p officeTempWS
    cp "$directory_path" ./officeTempWS/
    directory_path="./officeTempWS/"
fi

##########################################################################################
# 处理word
find_files_with_extensions "$directory_path" "${word_extensions[@]}"

for file_path in "${ffwe_file_list[@]}"; do
    convert_word_to_txt "$file_path"
done

# Excel转txt
echo "==========================================================================="

find_files_with_extensions "$directory_path" "${excel_extensions[@]}"

for file_path in "${ffwe_file_list[@]}"; do
    convert_excel_to_txt "$file_path"
done

if [ -d "officeTempWS" ]; then
    rm -r officeTempWS
fi


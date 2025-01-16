replace_placeholders_with_values() {
    local src_file="$1"
    local dest_file="$src_file"

    # 如果文件是 .src 结尾，生成去掉 .src 的文件
    if [[ "$src_file" == *.src ]]; then
        dest_file="${src_file%.src}"
    fi

    # 确认源文件是否存在
    if [[ ! -f "$src_file" ]]; then
        echo "文件不存在: $src_file"
        return 1
    fi

    # 复制文件内容到目标文件，如果需要新建
    cp "$src_file" "$dest_file"

    # 匹配占位符格式【$varName】，使用 sed 替换变量
    grep -oP '【\$\w+】' "$dest_file" | while read -r placeholder; do
        varName=$(echo "$placeholder" | sed -E 's/【\$(\w+)】/\1/')
        varValue=${!varName}
        if [[ -n "$varValue" ]]; then
            sed -i "s|${placeholder}|${varValue}|g" "$dest_file"
        else
            echo "警告: 变量 $varName 未设置，跳过替换 ${placeholder}"
        fi
    done

    echo "完成: 生成的文件为 $dest_file"
}

SET_SERVER_NAME="example.com"
SET_HTTP_SERVER_ROOT="/var/www/html"
phpfpmVersion="8.2"

# replace_placeholders_with_values "http.src"
replace_placeholders_with_values "http"

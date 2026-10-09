#!/bin/bash
# 用法: ./collect_binary_with_deps.sh [/path/to/binary] [output-dir]
# ------------------------------------------------------------------------------
# 名称：collect_binary_with_deps.sh
# 功能：收集可执行文件及其依赖库，打包成便于迁移和离线运行的目录
#
# 用法：
#   ./collect_binary_with_deps.sh [/path/to/binary] [output-dir]
#
# 参数说明：
#   /path/to/binary   可执行文件的路径（如 /usr/bin/ffmpeg），不要填 apt 包名
#                     不填则交互询问。若误填包名或命令名，会尝试解析成路径
#   [output-dir]      可选，输出目录名称（默认为 <binary>_bundle）
#
# 脚本功能：
#   - 拷贝目标可执行文件到 output-dir/bin/
#   - 分析其动态链接库依赖，拷贝到 output-dir/lib/
#   - 自动生成 run.sh 启动脚本，设置 LD_LIBRARY_PATH 后运行主程序
#
# 运行后目录结构如下：
#   output-dir/
#     ├── bin/        # 主程序
#     ├── lib/        # 所有依赖库
#     └── run.sh      # 一键启动脚本
#
# 示例：
#   ./collect_binary_with_deps.sh /usr/bin/dislocker
#   cd dislocker_bundle && ./run.sh -V
#
# 适用于打包工具或命令行程序，实现跨环境、离线运行。
# ------------------------------------------------------------------------------


set -e

read_tty() {
    local ans
    if [ ! -r /dev/tty ]; then
        echo "需要在终端里输入。用法: $0 /path/to/binary [output-dir]" >&2
        exit 1
    fi
    read -r -p "$1" ans </dev/tty
    printf '%s\n' "$ans"
}

# 已安装包里、位于常见 bin 目录的可执行文件
list_pkg_bins() {
    local p
    dpkg -L "$1" 2>/dev/null | while read -r p; do
        [ -f "$p" ] && [ -x "$p" ] || continue
        case "$p" in
            /usr/bin/*|/usr/sbin/*|/bin/*|/sbin/*|/usr/local/bin/*|/usr/local/sbin/*)
                printf '%s\n' "$p"
                ;;
        esac
    done
}

pick_from_list() {
    local title="$1"
    shift
    local -a items=("$@")
    local i choice
    echo "$title" >&2
    for i in "${!items[@]}"; do
        printf '  %d) %s\n' "$((i + 1))" "${items[$i]}" >&2
    done
    echo "  0) 取消" >&2
    while true; do
        choice="$(read_tty "请选择编号: ")"
        if [ "$choice" = "0" ]; then
            echo "已取消。" >&2
            exit 0
        fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#items[@]}" ]; then
            printf '%s\n' "${items[$((choice - 1))]}"
            return 0
        fi
        echo "请输入 0 到 ${#items[@]} 之间的编号。" >&2
    done
}

# 得到一个真实存在的可执行文件路径。包名、命令名会先解释清楚再解析。
resolve_binary() {
    local input="$1" cmd="" 
    local -a bins=()

    if [ -z "$input" ]; then
        echo "要打包的是可执行文件的路径，不是 apt 包名，也不是程序所在目录。" >&2
        echo "例如: /usr/bin/ffmpeg    /usr/bin/dislocker" >&2
        input="$(read_tty "可执行文件路径: ")"
        input="${input#"${input%%[![:space:]]*}"}"
        input="${input%"${input##*[![:space:]]}"}"
        if [ -z "$input" ]; then
            echo "未输入路径。" >&2
            exit 1
        fi
    fi

    if [ -d "$input" ]; then
        echo "「$input」是目录，不是可执行文件。" >&2
        echo "请填这个目录里的具体程序，例如 $input/程序名。不要填 apt 包名。" >&2
        exit 1
    fi

    if [ -f "$input" ]; then
        if [ ! -x "$input" ]; then
            echo "文件存在，但不可执行: $input" >&2
            exit 1
        fi
        readlink -f "$input"
        return 0
    fi

    if [[ "$input" == */* ]]; then
        echo "找不到路径: $input" >&2
        echo "这里要填可执行文件的路径（例如 /usr/bin/ffmpeg），不要填 apt 包名。" >&2
        exit 1
    fi

    # type -P 跳过 shell 内建，只要磁盘上的程序
    cmd="$(type -P "$input" 2>/dev/null || true)"
    if [ -n "$cmd" ] && [ -x "$cmd" ]; then
        cmd="$(readlink -f "$cmd")"
        echo "「$input」不是路径。已按命令名解析为: $cmd" >&2
        echo "若这不是要打包的程序，请重新运行并填写完整路径。" >&2
        printf '%s\n' "$cmd"
        return 0
    fi

    if dpkg -s "$input" >/dev/null 2>&1; then
        mapfile -t bins < <(list_pkg_bins "$input")
        if [ "${#bins[@]}" -eq 0 ]; then
            echo "「$input」是已安装的包名，但里面没有常见目录下的可执行文件。" >&2
            echo "请直接填写要打包的程序路径。" >&2
            exit 1
        fi
        if [ "${#bins[@]}" -eq 1 ]; then
            echo "「$input」是包名，不是路径。这个包里的可执行文件是: ${bins[0]}" >&2
            printf '%s\n' "${bins[0]}"
            return 0
        fi
        echo "「$input」是包名，不是可执行文件路径。请从包里选一个程序。" >&2
        pick_from_list "包 $input 里的可执行文件:" "${bins[@]}"
        return 0
    fi

    echo "「$input」既不是可执行文件路径，也不是已安装包或命令。" >&2
    echo "请填程序路径，例如 /usr/bin/$input 。不要填 apt 包名。" >&2
    exit 1
}

if [ -n "${1:-}" ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
    echo "用法: $0 [/path/to/binary] [output-dir]"
    echo "要填可执行文件的路径，例如 /usr/bin/ffmpeg 。不要填 apt 包名。"
    echo "省略路径时会交互询问。误填包名或命令名时，会尝试解析成路径。"
    exit 0
fi

BINARY="$(resolve_binary "${1:-}")"
BINARY_NAME=$(basename "$BINARY")
OUTDIR="${2:-${BINARY_NAME}_bundle}"

echo "[+] 目标可执行文件: $BINARY"
echo "[+] 输出目录: $OUTDIR"

mkdir -p "$OUTDIR/bin"
mkdir -p "$OUTDIR/lib"

# 拷贝主可执行文件
cp "$BINARY" "$OUTDIR/bin/"

echo "[+] 分析依赖库..."
ldd "$BINARY" | awk '/=> \// { print $(NF-1) }' | sort -u | while read -r lib; do
    if [ -f "$lib" ]; then
        echo "    拷贝库: $lib"
        cp -u "$lib" "$OUTDIR/lib/"
    else
        echo "    ⚠️ 找不到库文件: $lib"
    fi
done

# 可选：生成一键启动脚本
cat > "$OUTDIR/run.sh" <<EOF
#!/bin/bash
# 获取脚本所在目录的绝对路径，存入变量 SCRIPT_DIR。
SCRIPT_DIR="\$(cd "\$(dirname "\$0")" && pwd)"
#  设置动态链接库搜索路径，把脚本目录下的 lib/ 加入 LD_LIBRARY_PATH。
export LD_LIBRARY_PATH="\$SCRIPT_DIR/lib:\$LD_LIBRARY_PATH"
# 👉 执行你打包好的程序 dislocker，并将用户传入的所有参数（\$@）原样传递过去。
exec "\$SCRIPT_DIR/bin/$BINARY_NAME" "\$@"
EOF

chmod +x "$OUTDIR/run.sh"

echo -e "\n[+] ✅ 打包完成: $OUTDIR"
echo "    用法: cd $OUTDIR && ./run.sh [参数]"


#!/bin/bash
#
# 智能双面打印脚本（支持手动翻页打印）
# 新增 debug 模式：只拆分 PDF，不打印，拆分文件保存到当前目录
#
# 依赖：
#   - ghostscript (gs, ps2pdf)
#   - poppler-utils (pdfinfo, pdfseparate, pdfunite)
# 脚本会检测依赖，缺失时尝试 apt 自动安装（仅适用于 Debian/Ubuntu）
#
# 用法：
#   ./duplex_print.sh 文件.pdf [split|direct|debug] [yes|no] [打印命令] [临时目录]
#
# 参数说明：
#   文件.pdf             : 要打印的 PDF 文件路径，必填
#   split|direct|debug   : 打印模式，默认 split
#     - split  ：拆分奇偶页后打印（手动翻页）
#     - direct ：使用 lpr 指令分奇偶页直接打印（手动翻页）
#     - debug  ：仅拆分文件，不打印
#   yes|no               : 偶数页是否倒序，默认 yes（适用于从打印机顶部手动放入）
#   打印命令             : 打印命令，默认 lpr
#   临时目录             : 临时文件目录，默认自动创建（debug 模式输出在当前目录）

# 所需命令行工具列表
REQUIRED_CMDS=(gs pdfinfo pdfseparate pdfunite)

# 检查依赖项是否安装，自动尝试安装缺失的部分
function ensure_dependencies() {
  MISSING_CMDS=()
  for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      MISSING_CMDS+=("$cmd")
    fi
  done

  if [ ${#MISSING_CMDS[@]} -ne 0 ]; then
    echo "🔧 缺少以下命令：${MISSING_CMDS[*]}"
    echo "尝试安装相关软件包：poppler-utils ghostscript"
    sudo apt update
    sudo apt install -y poppler-utils ghostscript
    for cmd in "${MISSING_CMDS[@]}"; do
      if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ 命令 $cmd 仍未安装，请手动安装"
        exit 1
      fi
    done
  else
    echo "✅ 所需依赖均已安装"
  fi
}

ensure_dependencies

# 读取命令行参数
PDF="$1" # 输入 PDF 文件
# 模式：split, direct, debug（默认 split）
MODE="${2:-split}"
# MODE="${2:-debug}"
# 偶数页是否倒序
EvenPagesReverse="${3:-yes}"
# EvenPagesReverse="${3:-no}"
PRINT_CMD="${4:-lpr}"        # 打印命令，默认 lpr
TMP_DIR="${5:-$(mktemp -d)}" # 临时目录（默认自动创建）

# 参数校验
if [ -z "$PDF" ] || [ ! -f "$PDF" ]; then
  echo "❌ 请提供有效 PDF 文件路径"
  echo "用法：$0 文件.pdf [split|direct|debug] [yes|no] [打印命令] [临时目录]"
  exit 1
fi

# 获取 PDF 总页数
PAGE_COUNT=$(pdfinfo "$PDF" | awk '/^Pages:/ {print $2}')
if [ -z "$PAGE_COUNT" ]; then
  echo "❌ 无法读取 PDF 页数"
  exit 1
fi

echo "📄 总页数：$PAGE_COUNT"
echo "🔧 当前模式：$MODE"

#############################################
# Debug 模式：拆分奇偶页并输出到当前目录，不打印
#############################################
if [ "$MODE" = "debug" ]; then
  echo "🧪 Debug 模式：拆分奇偶页 PDF，保存到当前目录"

  # 清理旧文件
  rm -f odd_debug_*.pdf even_debug_*.pdf blank_debug.pdf

  # 拆分奇数页
  echo "✂️ 提取奇数页..."
  for ((i = 1; i <= PAGE_COUNT; i += 2)); do
    pdfseparate -f $i -l $i "$PDF" odd_debug_%03d.pdf
  done
  pdfunite odd_debug_*.pdf odd_debug.pdf
  rm odd_debug_*.pdf

  # 拆分偶数页
  echo "✂️ 提取偶数页..."
  for ((i = 2; i <= PAGE_COUNT; i += 2)); do
    pdfseparate -f $i -l $i "$PDF" even_debug_%03d.pdf
  done

  EVEN_LIST=$(ls even_debug_*.pdf)

  # 补空白页（当总页数为奇数时）
  if ((PAGE_COUNT % 2 == 1)); then
    echo "🧩 奇数页多，补空白页"
    # 下一个偶数页码，比如页数是 7，则下一个偶数页是 8
    PAD_PAGE_NUM=$(printf "%03d" $((PAGE_COUNT + 1)))
    # 按编号生成空白页文件，命名为 even_debug_008.pdf
    PAD_FILE="even_debug_${PAD_PAGE_NUM}.pdf"
    echo "" | ps2pdf - "$PAD_FILE"
    EVEN_LIST="$EVEN_LIST $PAD_FILE"
  fi

  # 排序偶数页（默认倒序）
  if [ "$EvenPagesReverse" = "yes" ]; then
    echo "🔄 偶数页倒序"
    EVEN_LIST=$(echo $EVEN_LIST | xargs -n1 | sort -Vr | xargs)
  else
    echo "➡️ 偶数页正序"
    EVEN_LIST=$(echo $EVEN_LIST | xargs -n1 | sort -V | xargs)
  fi

  pdfunite $EVEN_LIST even_debug.pdf
  rm even_debug_*.pdf

  echo "✅ 奇数页输出: $(pwd)/odd_debug.pdf"
  echo "✅ 偶数页输出: $(pwd)/even_debug.pdf"
  echo "🧪 Debug 模式拆分完成，不打印"
  exit 0
fi

#############################################
# Split 模式：拆分奇偶页并分别打印（需手动翻页）
#############################################
if [ "$MODE" = "split" ]; then
  ODD_PDF="$TMP_DIR/odd.pdf"
  EVEN_PDF="$TMP_DIR/even.pdf"

  # 拆分奇数页
  echo "✂️ 正在提取奇数页..."
  for ((i = 1; i <= $PAGE_COUNT; i += 2)); do
    pdfseparate -f $i -l $i "$PDF" "$TMP_DIR/odd-%03d.pdf"
  done
  pdfunite "$TMP_DIR"/odd-*.pdf "$ODD_PDF"
  rm "$TMP_DIR"/odd-*.pdf

  # 拆分偶数页
  echo "✂️ 正在提取偶数页..."
  for ((i = 2; i <= $PAGE_COUNT; i += 2)); do
    pdfseparate -f $i -l $i "$PDF" "$TMP_DIR/even-%03d.pdf"
  done

  EVEN_LIST=$(ls "$TMP_DIR"/even-*.pdf)

  # 补空白页（当总页数为奇数时）
  if ((PAGE_COUNT % 2 == 1)); then
    echo "🧩 总页数为奇数，补一页空白..."
    # 计算补页页码，例如总页数是 7，补偶数页应为第 8 页
    PAD_PAGE_NUM=$(printf "%03d" $((PAGE_COUNT + 1)))
    # 命名保持一致，例如 even-008.pdf
    BLANK_PDF="$TMP_DIR/even-${PAD_PAGE_NUM}.pdf"
    echo "" | ps2pdf - "$BLANK_PDF"
    EVEN_LIST="$EVEN_LIST $BLANK_PDF"
  fi

  # 排序偶数页
  if [ "$EvenPagesReverse" = "yes" ]; then
    echo "🔄 偶数页将倒序打印"
    EVEN_LIST=$(echo $EVEN_LIST | xargs -n1 | sort -Vr | xargs)
  else
    echo "➡️ 偶数页将正序打印"
    EVEN_LIST=$(echo $EVEN_LIST | xargs -n1 | sort -V | xargs)
  fi

  pdfunite $EVEN_LIST "$EVEN_PDF"
  rm "$TMP_DIR"/even-*.pdf

  # 打印奇数页
  echo "🖨️ 正在打印奇数页..."
  $PRINT_CMD "$ODD_PDF" || {
    echo "❌ 奇数页打印失败"
    exit 1
  }

  echo
  read -p "🖐️ 请手动翻纸并放入打印机，按 Enter 继续..."

  # 打印偶数页
  echo "🖨️ 正在打印偶数页..."
  $PRINT_CMD "$EVEN_PDF" || {
    echo "❌ 偶数页打印失败"
    exit 1
  }

  echo "✅ 智能双面打印完成"
  rm -rf "$TMP_DIR"

#############################################
# Direct 模式：直接用 lpr 打印奇偶页（依赖打印命令支持 page-set）
#############################################
elif [ "$MODE" = "direct" ]; then
  echo "🖨️ 正在打印奇数页（直接）..."
  $PRINT_CMD -o page-set=odd "$PDF" || {
    echo "❌ 奇数页打印失败"
    exit 1
  }

  echo
  read -p "🖐️ 请手动翻纸后放入打印机，按 Enter 继续..."

  echo "🖨️ 正在打印偶数页（直接）..."
  $PRINT_CMD -o page-set=even "$PDF" || {
    echo "❌ 偶数页打印失败"
    exit 1
  }

  echo "✅ 直接双面打印完成"

#############################################
# 不支持的模式
#############################################
else
  echo "❌ 不支持的模式：$MODE。请使用 split、direct 或 debug"
  exit 1
fi

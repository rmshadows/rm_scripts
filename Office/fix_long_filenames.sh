#!/bin/bash
############################################################
# 脚本名称：fix_long_filenames.sh
# 功能说明：处理文件系统中超出 ext4 和 LUKS2 支持长度限制的文件名或目录名。
#          可从文件名前或后截取，保留扩展名，避免重名。
#
# 使用方法：
#   chmod +x fix_long_filenames.sh
#   ./fix_long_filenames.sh [选项]
#
# 参数说明：
#   -f    处理文件名（file）
#   -d    处理目录名（directory）
#   -a    处理所有（文件和目录）
#   -p    仅预览（默认行为，不实际执行重命名）
#   -e    执行重命名操作（危险操作，需谨慎）
#   -r    从文件名「末尾」截取有效部分（默认从「开头」截取）
#         无论开头/末尾，文件都会尽量保留扩展名（.pdf 等）
#
# 示例:
#   ./fix_long_filenames.sh -a        # 预览；默认保留开头+扩展名
#   ./fix_long_filenames.sh -f -e     # 执行；保留开头+扩展名
#   ./fix_long_filenames.sh -f -r -e  # 执行；保留末尾+扩展名
#
# 输出说明：
#   - 所有变更记录和预览内容将写入 rename_log.txt 日志文件。
#   - 自动避免重名冲突（添加编号 _1, _2 ...）。
#
# 注意事项：
#   - 本脚本基于 UTF-8 编码环境
#   - 请勿在系统根目录运行。使用前建议备份或先预览（-p）
############################################################

MAX_FILENAME_BYTES=255
LOG_FILE="rename_log.txt"

# 默认设置
PROCESS_FILES=false
PROCESS_DIRS=false
PREVIEW_ONLY=true
REVERSE_TRIM=false  # 是否从文件名末尾截取

# 清空旧日志
: > "$LOG_FILE"

# 解析参数
while getopts "fdaper" opt; do
  case "$opt" in
    f) PROCESS_FILES=true ;;
    d) PROCESS_DIRS=true ;;
    a) PROCESS_FILES=true; PROCESS_DIRS=true ;;
    p) PREVIEW_ONLY=true ;;
    e) PREVIEW_ONLY=false ;;
    r) REVERSE_TRIM=true ;;
    *)
      echo "❌ 无效参数: -$OPTARG"
      echo "用法: $0 [-f] [-d] [-a] [-p] [-e] [-r]"
      exit 1
      ;;
  esac
done

if ! $PROCESS_FILES && ! $PROCESS_DIRS; then
  echo "⚠️ 你必须至少指定 -f（文件）、-d（目录）或 -a（全部）"
  exit 1
fi

truncate_name() {
  local name="$1"
  local max_bytes="$2"
  local ext=""
  local base="$name"

  if [[ "$3" == "file" ]]; then
    ext="${name##*.}"
    if [[ "$ext" != "$name" ]]; then
      base="${name%.*}"
      ext=".$ext"
    else
      ext=""
    fi
  fi

  local allowed_bytes=$(( max_bytes - ${#ext} ))

  if ! $REVERSE_TRIM; then
    # 正常从前往后截取
    local new_base=""
    local byte_count=0
    while IFS= read -r -n1 char; do
      char_byte=$(printf "%s" "$char" | wc -c)
      if (( byte_count + char_byte > allowed_bytes )); then
        break
      fi
      new_base+="$char"
      ((byte_count += char_byte))
    done < <(printf "%s" "$base")
  else
    # 从后往前截取（保持顺序）
    local reversed=""
    local byte_count=0
    local i
    for (( i=${#base}-1; i>=0; i-- )); do
      char="${base:$i:1}"
      char_byte=$(printf "%s" "$char" | wc -c)
      if (( byte_count + char_byte > allowed_bytes )); then
        break
      fi
      reversed="$char$reversed"
      ((byte_count += char_byte))
    done
    new_base="$reversed"
  fi

  echo "${new_base}${ext}"
}

rename_item() {
  local old_path="$1"
  local type="$2"

  local dirpath=$(dirname "$old_path")
  local name=$(basename "$old_path")
  local new_name=$(truncate_name "$name" "$MAX_FILENAME_BYTES" "$type")
  local new_path="${dirpath}/${new_name}"
  local counter=1

  # 避免重名冲突
  while [[ "$new_path" != "$old_path" && -e "$new_path" ]]; do
    if [[ "$type" == "file" && "$new_name" == *.* ]]; then
      base="${new_name%.*}"
      ext=".${new_name##*.}"
    else
      base="$new_name"
      ext=""
    fi
    new_name="${base}_$counter${ext}"
    new_path="${dirpath}/${new_name}"
    ((counter++))
  done

  if [[ "$new_path" != "$old_path" ]]; then
    echo "🔧 $type: $old_path" | tee -a "$LOG_FILE"
    echo "➡️  改为: $new_path" | tee -a "$LOG_FILE"
    if ! $PREVIEW_ONLY; then
      mv "$old_path" "$new_path"
      echo "✅ 已重命名" | tee -a "$LOG_FILE"
    else
      echo "🟡 仅预览，未改动" | tee -a "$LOG_FILE"
    fi
    echo "" >> "$LOG_FILE"
  fi
}

# 处理文件
if $PROCESS_FILES; then
  find . -type f | while IFS= read -r f; do
    fname=$(basename "$f")
    blen=$(printf "%s" "$fname" | wc -c)
    (( blen > MAX_FILENAME_BYTES )) && rename_item "$f" "file"
  done
fi

# 处理目录（从深层到浅层）
if $PROCESS_DIRS; then
  find . -depth -type d | while IFS= read -r d; do
    dname=$(basename "$d")
    blen=$(printf "%s" "$dname" | wc -c)
    (( blen > MAX_FILENAME_BYTES )) && rename_item "$d" "dir"
  done
fi

echo ""
if $PREVIEW_ONLY; then
  echo "✅ 预览完成，未执行修改。日志见 $LOG_FILE"
else
  echo "✅ 重命名已执行。日志见 $LOG_FILE"
fi


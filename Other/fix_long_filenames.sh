#!/bin/bash
############################################################
# 脚本名称：fix_names.sh
# 功能说明：处理文件系统中超出 ext4 和 LUKS2 支持长度限制的文件名或目录名。
#          自动截取文件/目录名至最大 255 字节，保留文件扩展名。
#
# 使用方法：
#   chmod +x fix_names.sh
#   ./fix_names.sh [选项]
#
# 参数说明：
#   -f    处理文件名（file）
#   -d    处理目录名（directory）
#   -a    处理所有（文件和目录）
#   -p    仅预览（默认行为，不实际执行重命名）
#   -e    执行重命名操作（危险操作，需谨慎）
#
# 示例：
#   ./fix_names.sh -a        # 预览所有超长文件名和目录名的修改建议
#   ./fix_names.sh -f -e     # 直接重命名所有超长的文件名
#   ./fix_names.sh -d -p     # 仅预览所有超长的目录名，不实际修改
#
# 输出说明：
#   - 所有变更记录和预览内容将写入 rename_log.txt 日志文件。
#   - 重命名时自动避免重名冲突（添加编号后缀 _1, _2, ...）。
#
# 注意事项：
#   - 该脚本基于 UTF-8 环境，中文等多字节字符将按字节计入长度。
#   - 不建议在系统核心目录或挂载点根目录下运行。
#   - 执行操作前请务必备份相关数据或先进行预览（-p）。
############################################################

MAX_FILENAME_BYTES=255
LOG_FILE="rename_log.txt"

# 默认设置
PROCESS_FILES=false
PROCESS_DIRS=false
PREVIEW_ONLY=true

# 清空旧日志
: > "$LOG_FILE"

# 参数解析
while getopts "fdape" opt; do
  case "$opt" in
    f) PROCESS_FILES=true ;;
    d) PROCESS_DIRS=true ;;
    a) PROCESS_FILES=true; PROCESS_DIRS=true ;;
    p) PREVIEW_ONLY=true ;;
    e) PREVIEW_ONLY=false ;;
    *)
      echo "❌ 无效参数: -$OPTARG"
      echo "用法: $0 [-f] [-d] [-a] [-p] [-e]"
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

  while [[ "$new_path" != "$old_path" && -e "$new_path" ]]; do
    new_name="${new_name%.*}_$counter.${new_name##*.}"
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

# 处理目录
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


#!/usr/bin/env bash
# Nautilus 右键脚本：输入过滤（扩展名 / 数量）
#
# 用法（包装脚本里，在拿到 "$@" 后）:
#   source "$NAUTILUS_ROOT/lib/Office/nautilus_filter.sh"
#   office_filter_by_ext 1 0 jpg jpeg png -- "$@" || exit 1
#   # 之后用 "${OFFICE_FILES[@]}"，不要用未过滤的 "$@"
#
# 参数:
#   min  至少几个文件（0=允许空但一般用 1）
#   max  最多几个（0=不限制）
#   扩展名…  --  文件列表
#
# 行为:
#   - 非文件 / 扩展名不符 → 列入「已忽略」
#   - 一个合格的都没有 → 报错退出
#   - 有忽略项 → zenity 询问是否用剩余项继续

office_filter_by_ext() {
  local min="$1" max="$2"
  shift 2
  local -a exts=()
  while [[ $# -gt 0 && "$1" != "--" ]]; do
    exts+=("${1,,}")
    shift
  done
  if [[ "${1:-}" != "--" ]]; then
    zenity --error --text="内部错误：office_filter_by_ext 缺少 --" 2>/dev/null || true
    return 2
  fi
  shift

  OFFICE_FILES=()
  local -a bad=()
  local f e ok w base

  if [[ $# -eq 0 ]]; then
    zenity --error --title="选择有误" --text="没有选中任何文件。" 2>/dev/null || true
    return 1
  fi

  for f in "$@"; do
    base="$(basename "$f")"
    if [[ ! -f "$f" ]]; then
      bad+=("$base（不是文件）")
      continue
    fi
    e="${f##*.}"
    e="${e,,}"
    ok=0
    for w in "${exts[@]}"; do
      if [[ "$e" == "$w" ]]; then
        ok=1
        break
      fi
    done
    if [[ "$ok" -eq 1 ]]; then
      OFFICE_FILES+=("$f")
    else
      bad+=("$base")
    fi
  done

  local want
  want=$(printf '%s、' "${exts[@]}")
  want="${want%、}"

  if [[ ${#OFFICE_FILES[@]} -eq 0 ]]; then
    zenity --error --title="选择有误" --width=420 \
      --text="没有可用的文件。\n\n需要类型：${want}\n选中 ${#} 项均不符合（点错了？）" \
      2>/dev/null || true
    return 1
  fi

  if [[ ${#bad[@]} -gt 0 ]]; then
    local sample
    sample=$(printf '  • %s\n' "${bad[@]}" | head -n 15)
    [[ ${#bad[@]} -gt 15 ]] && sample+="  …共 ${#bad[@]} 个\n"
    zenity --question --title="部分文件已忽略" --width=480 \
      --ok-label="继续（仅合格文件）" --cancel-label="取消" \
      --text="已忽略 ${#bad[@]} 个不符合的项：\n${sample}\n将处理剩下的 ${#OFFICE_FILES[@]} 个文件，是否继续？" \
      2>/dev/null || return 1
  fi

  if [[ "$min" -gt 0 && ${#OFFICE_FILES[@]} -lt "$min" ]]; then
    zenity --error --title="选择有误" --width=400 \
      --text="至少需要 ${min} 个合格文件，当前只有 ${#OFFICE_FILES[@]} 个。\n需要类型：${want}" \
      2>/dev/null || true
    return 1
  fi

  if [[ "$max" -gt 0 && ${#OFFICE_FILES[@]} -gt "$max" ]]; then
    zenity --error --title="选择有误" --width=400 \
      --text="最多选择 ${max} 个文件，当前选了 ${#OFFICE_FILES[@]} 个。" \
      2>/dev/null || true
    return 1
  fi

  return 0
}

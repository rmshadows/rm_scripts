#!/usr/bin/env bash
#🎯 指定单个文件
#./vfr_to_edit.sh -i DJI_0001.MP4 -f 30 -m prores -q 3
#📁 当前目录所有 MP4
#./vfr_to_edit.sh -i mp4 -f 30 -m prores -q 1
#🎞 所有视频（mp4 + mov + avi）
#./vfr_to_edit.sh -i all -f 60 -m iframe -q 18

# ================= 默认参数 =================
FPS=60
MODE="prores"              # prores | iframe
QUALITY=3                  # ProRes profile / x264 CRF
INPUT="all"                # all | mp4 | allvideo | file
FILE=""
EXTS=("mp4")

# ================= 帮助 =================
usage() {
  echo ""
  echo "用法:"
  echo "  单文件:"
  echo "    ./vfr_to_edit.sh -i file.mp4 [参数]"
  echo ""
  echo "  所有 mp4:"
  echo "    ./vfr_to_edit.sh -i mp4 [参数]"
  echo ""
  echo "  所有视频(mp4 mov avi):"
  echo "    ./vfr_to_edit.sh -i all [参数]"
  echo ""
  echo "参数:"
  echo "  -i, --input <file|mp4|all>"
  echo "  -f, --fps <帧率>            (默认 30)"
  echo "  -m, --mode <prores|iframe>"
  echo "  -q, --quality <质量值>"
  echo ""
  exit 0
}

# ================= 参数解析 =================
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input)
      if [[ -f "$2" ]]; then
        INPUT="file"
        FILE="$2"
      else
        INPUT="$2"
      fi
      shift 2
      ;;
    -f|--fps)
      FPS="$2"
      shift 2
      ;;
    -m|--mode)
      MODE="$2"
      shift 2
      ;;
    -q|--quality)
      QUALITY="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "未知参数: $1"
      usage
      ;;
  esac
done

# ================= 输入判断 =================
FILES=()

case "$INPUT" in
  file)
    FILES+=("$FILE")
    ;;
  mp4)
    FILES+=( *.mp4 *.MP4 )
    ;;
  all)
    FILES+=( *.mp4 *.MP4 *.mov *.MOV *.avi *.AVI )
    ;;
  *)
    echo "无效输入: $INPUT"
    usage
    ;;
esac

# ================= 执行 =================
echo "帧率: $FPS"
echo "模式: $MODE"
echo "质量: $QUALITY"
echo "文件数: ${#FILES[@]}"
echo "----------------------------------"

for f in "${FILES[@]}"; do
  [ -e "$f" ] || continue
  echo "处理: $f"

  if [[ "$MODE" == "prores" ]]; then
    ffmpeg -y -i "$f" \
      -vf "fps=${FPS}" -vsync cfr \
      -c:v prores_ks -profile:v "$QUALITY" \
      -pix_fmt yuv422p10le \
      -c:a pcm_s16le \
      "${f%.*}_EDIT_${FPS}fps_PRORES.mov"

  elif [[ "$MODE" == "iframe" ]]; then
    ffmpeg -y -i "$f" \
      -vf "fps=${FPS}" -vsync cfr \
      -c:v libx264 -preset ultrafast -crf "$QUALITY" \
      -g 1 -keyint_min 1 -sc_threshold 0 \
      -c:a pcm_s16le \
      "${f%.*}_EDIT_${FPS}fps_IFRAME.mp4"

  else
    echo "模式错误: $MODE"
    exit 1
  fi
done


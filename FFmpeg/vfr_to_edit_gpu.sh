#!/usr/bin/env bash
# =========================================================
# vfr_to_edit_gpu.sh
#
# 默认行为：
#   不带参数直接运行 -> 只处理当前目录的 1.MP4（如果没有则尝试 1.mp4）
#
# 用途：
#   将可变帧率视频 (VFR) 转换为剪辑/成片友好的固定帧率 (CFR)
#   支持：
#     - prores  (中间格式：最顺，但文件很大)
#     - iframe  (全 I 帧：好剪，体积比 cfr 大)
#     - cfr     (普通 H.264 长 GOP：最接近源文件大小)
#
# ----------------【你要的命令示例】----------------
#
# 1) 生成“大文件”的 ProRes（最顺，但会很大）
#    ./vfr_to_edit_gpu.sh -i 1.MP4 -f 30 -m prores -q 3
#
# 2) 生成“同大小/最接近源文件大小”的固定 30fps（CFR 长 GOP）
#    ./vfr_to_edit_gpu.sh -i 1.MP4 -f 30 -m cfr -g cpu -q 20
#
# 3) 指定 CPU 处理 / GPU 处理 的命令
#    CPU（x264）：
#      ./vfr_to_edit_gpu.sh -i 1.MP4 -f 30 -m cfr   -g cpu  -q 20
#      ./vfr_to_edit_gpu.sh -i 1.MP4 -f 30 -m iframe -g cpu  -q 18
#
#    GPU（AMD RX6600 VAAPI）：
#      ./vfr_to_edit_gpu.sh -i 1.MP4 -f 30 -m cfr   -g vaapi -q 20
#      ./vfr_to_edit_gpu.sh -i 1.MP4 -f 30 -m iframe -g vaapi -q 20
#
# ----------------【参数说明】----------------
#
# -i, --input   <file|mp4|all>
#               file=单个文件(传文件名)  mp4=当前目录所有mp4  all=mp4+mov+avi
# -f, --fps     <auto|25|30|50|60>   auto=读取 r_frame_rate 近似整数
# -m, --mode    <prores|iframe|cfr>
# -q, --quality
#   prores: profile 0=Proxy 1=422 2=LT 3=422HQ 4=4444
#   iframe:
#     VAAPI: qp（18清晰但大；20平衡；22更小）
#     CPU : crf（16清晰；18推荐；20更小）
#   cfr:
#     VAAPI: qp（同上）
#     CPU : crf（20接近源文件；22更小）
# -g, --gpu     <auto|nvenc|vaapi|cpu>
#
# 输出：
#   prores -> *_PRORES.mov
#   iframe -> *_IFRAME.mp4
#   cfr   -> *_CFR.mp4
# =========================================================

set -u
shopt -s nullglob

# ============ 默认参数（配置面板）===========

# 输出帧率
# "auto" = 读取源视频帧率并取接近整数（推荐，最安全）
# 可选: "25" "30" "50" "60"
FPS="auto"

# 处理模式（三选一）
# "prores" : 专业中间格式，剪辑最顺，但文件极大
# "iframe" : 全 I 帧 H.264，较好剪，体积中等
# "cfr"    : 普通 H.264 长 GOP，固定帧率，体积最接近源文件（推荐）
MODE="cfr"

# 质量 / 体积控制（随 MODE 含义不同）
#
# ▶ MODE="cfr" 或 "iframe"
#   CPU（libx264 / CRF）:
#     16 = 很清晰，文件大
#     18 = 推荐平衡
#     20 = 接近源文件大小（推荐）
#     22 = 更小，画质略降
#
#   GPU（VAAPI / QP）:
#     18 = 清晰但大
#     20 = 平衡（推荐）
#     22 = 更小
#
# ▶ MODE="prores"（profile）
#     0 = Proxy（很小）
#     1 = 422（推荐，剪辑用）
#     2 = LT
#     3 = 422 HQ（很大）
#     4 = 4444（极大）
QUALITY=20

# 输入文件范围
# "file" = 只处理 FILE 指定的文件
# "mp4"  = 当前目录所有 .mp4
# "all"  = .mp4 + .mov + .avi
INPUT="file"

# 当 INPUT="file" 时使用的文件名
# 默认：不带参数直接运行时处理 1.MP4（若不存在则尝试 1.mp4）
FILE="1.MP4"

# 使用 CPU 还是 GPU
# "auto"  = 自动选择（NVIDIA→nvenc，AMD/Intel→vaapi，否则→cpu）
# "cpu"   = 强制使用 CPU（最稳）
# "vaapi" = 强制使用 AMD / Intel GPU
# "nvenc" = 强制使用 NVIDIA GPU（AMD 机器不要用）
GPU="auto"

# VAAPI 设备（99% 情况不用改）
VAAPI_DEVICE="/dev/dri/renderD128"


# ============ 帮助 ============
usage() { sed -n '1,170p' "$0"; exit 0; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }

nvenc_usable() {
  ffmpeg -hide_banner -encoders 2>/dev/null | grep -q "h264_nvenc" || return 1
  if ldconfig -p 2>/dev/null | grep -q "libcuda.so.1" && [ -e /dev/nvidiactl -o -e /dev/nvidia0 ]; then
    return 0
  fi
  if have_cmd nvidia-smi && nvidia-smi >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

vaapi_usable() {
  ffmpeg -hide_banner -encoders 2>/dev/null | grep -q "h264_vaapi" || return 1
  [ -e "$VAAPI_DEVICE" ] || return 1
  return 0
}

# ============ 参数解析 ============
# 如果用户完全不带参数运行：默认 file=1.MP4（后面会自动 fallback 到 1.mp4）
if [[ $# -eq 0 ]]; then
  :
else
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -i|--input)
        if [[ -f "$2" ]]; then
          INPUT="file"
          FILE="$2"
        else
          INPUT="$2"
        fi
        shift 2 ;;
      -f|--fps) FPS="$2"; shift 2 ;;
      -m|--mode) MODE="$2"; shift 2 ;;
      -q|--quality) QUALITY="$2"; shift 2 ;;
      -g|--gpu) GPU="$2"; shift 2 ;;
      -h|--help) usage ;;
      *) echo "未知参数: $1"; usage ;;
    esac
  done
fi

# ============ 文件列表 ============
FILES=()
case "$INPUT" in
  file)
    # 默认运行时：如果 1.MP4 不存在，尝试 1.mp4
    if [[ ! -e "$FILE" && "$FILE" == "1.MP4" && -e "1.mp4" ]]; then
      FILE="1.mp4"
    fi
    FILES+=("$FILE")
    ;;
  mp4) FILES+=( *.mp4 *.MP4 ) ;;
  all) FILES+=( *.mp4 *.MP4 *.mov *.MOV *.avi *.AVI ) ;;
  *) echo "输入错误: $INPUT"; usage ;;
esac

# ============ 自动检测 GPU ============
if [[ "$GPU" == "auto" ]]; then
  if nvenc_usable; then
    GPU="nvenc"
  elif vaapi_usable; then
    GPU="vaapi"
  else
    GPU="cpu"
  fi
fi

echo "GPU: $GPU | 模式: $MODE | 帧率: $FPS | 质量: $QUALITY"
[[ "$GPU" == "vaapi" ]] && echo "VAAPI_DEVICE: $VAAPI_DEVICE"
echo "------------------------------------------------"

# ============ 主处理 ============
for f in "${FILES[@]}"; do
  [ -e "$f" ] || { echo "找不到文件: $f"; continue; }
  echo "处理: $f"

  if [[ "$FPS" == "auto" ]]; then
    FPS_USE=$(ffprobe -v error -select_streams v:0 \
      -show_entries stream=r_frame_rate \
      -of default=nokey=1:noprint_wrappers=1 "$f" \
      | awk -F/ '{ if ($2>0) printf "%.0f\n", $1/$2; else print 30 }')
    [[ -z "$FPS_USE" || "$FPS_USE" -lt 1 ]] && FPS_USE=30
  else
    FPS_USE="$FPS"
  fi

  case "$MODE" in
    prores)
      ffmpeg -y -i "$f" \
        -vf "fps=${FPS_USE}" -fps_mode cfr \
        -c:v prores_ks -profile:v "$QUALITY" \
        -pix_fmt yuv422p10le \
        -c:a pcm_s16le \
        "${f%.*}_EDIT_${FPS_USE}fps_PRORES.mov"
      ;;

    iframe)
      if [[ "$GPU" == "nvenc" ]]; then
        ffmpeg -y -i "$f" \
          -vf "fps=${FPS_USE}" -fps_mode cfr \
          -c:v h264_nvenc -preset p1 -tune ll \
          -g 1 -keyint_min 1 -sc_threshold 0 \
          -c:a pcm_s16le \
          "${f%.*}_EDIT_${FPS_USE}fps_IFRAME.mp4"
      elif [[ "$GPU" == "vaapi" ]]; then
        ffmpeg -y -vaapi_device "$VAAPI_DEVICE" -i "$f" \
          -vf "fps=${FPS_USE},format=nv12,hwupload" -fps_mode cfr \
          -c:v h264_vaapi -qp "$QUALITY" \
          -g 1 -keyint_min 1 -sc_threshold 0 \
          -c:a pcm_s16le \
          "${f%.*}_EDIT_${FPS_USE}fps_IFRAME.mp4"
      else
        ffmpeg -y -i "$f" \
          -vf "fps=${FPS_USE}" -fps_mode cfr \
          -c:v libx264 -preset ultrafast -crf "$QUALITY" \
          -g 1 -keyint_min 1 -sc_threshold 0 \
          -c:a pcm_s16le \
          "${f%.*}_EDIT_${FPS_USE}fps_IFRAME.mp4"
      fi
      ;;

    cfr)
      # 体积最接近源文件：普通长 GOP H.264
      # 音频：默认 aac 192k（更接近源文件大小；比 pcm 小很多）
      if [[ "$GPU" == "vaapi" ]]; then
        ffmpeg -y -vaapi_device "$VAAPI_DEVICE" -i "$f" \
          -vf "fps=${FPS_USE},format=nv12,hwupload" -fps_mode cfr \
          -c:v h264_vaapi -qp "$QUALITY" \
          -c:a aac -b:a 192k \
          "${f%.*}_EDIT_${FPS_USE}fps_CFR.mp4"
      elif [[ "$GPU" == "nvenc" ]]; then
        ffmpeg -y -i "$f" \
          -vf "fps=${FPS_USE}" -fps_mode cfr \
          -c:v h264_nvenc -preset p4 -cq "$QUALITY" \
          -c:a aac -b:a 192k \
          "${f%.*}_EDIT_${FPS_USE}fps_CFR.mp4"
      else
        ffmpeg -y -i "$f" \
          -vf "fps=${FPS_USE}" -fps_mode cfr \
          -c:v libx264 -preset slow -crf "$QUALITY" \
          -c:a aac -b:a 192k \
          "${f%.*}_EDIT_${FPS_USE}fps_CFR.mp4"
      fi
      ;;

    *)
      echo "模式错误: $MODE（只能是 prores / iframe / cfr）"
      exit 1
      ;;
  esac
done


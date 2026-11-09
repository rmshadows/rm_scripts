#!/bin/bash
# 把会议录音里的静音段压短，不删掉。短停顿原样保留，长静音加快后仍留一段空隙。
# 跑完会说明：压了多少静音、缩短多少，以及说话时大概多少 dB，方便改阈值。
#
# 改默认值：直接改下面这一段。命令行参数只覆盖这一次，不改文件。
#
# 用法：
#   ./compress_silence.sh 会议.m4a
#   ./compress_silence.sh --speed 6 --max-pause 0.8 *.wav
#   ./compress_silence.sh --dry-run 会议.m4a
#   ./preview_silence.py 会议.wav          浏览器里拖滑块，只听一小段

# ===== 默认参数（直接改这里）=====
# 当前是激进：停顿压得很短，稍长的气口也会加快。适合想尽快听完。
#   NOISE_DB=-30   MIN_SILENCE=0.25  SPEED=5
#   MIN_KEEP=0.25  EDGE_PAD=0.10     MAX_PAUSE=0.25
# 不激进：只压很安静、比较长的空白，句间气口保持原速。
#   NOISE_DB=-40   MIN_SILENCE=0.80  SPEED=4
#   MIN_KEEP=0.35  EDGE_PAD=0.10     MAX_PAUSE=1.20
#
# 低于这个电平（dB）才算静音。-30 更敢压，-40 只压很安静的地方。
NOISE_DB=-30
# 短于这么多秒的空隙不动。0.25 会动到短气口，0.80 只动较长的停顿。
MIN_SILENCE=0.25
# 静音中间放快几倍。5 比 4 收得更短。
SPEED=5
# 放快之后这段空白至少还留这么多秒，避免两句话贴死。
MIN_KEEP=0.25
# 空白的开头、结尾各留这么多秒不加速，避免把字的头尾卷进去。
EDGE_PAD=0.10
# 压完后这段空白最长留这么多秒。0.25 几乎不留停顿，1.20 还能听出停过。0 表示不封顶。
MAX_PAUSE=0.25
# 成品音质。听会议内容 96k 够用，想文件小一点改 64k。
BITRATE=96k
# 同时写几路。0 按 CPU 和录音长度自动；1 表示不并行。
JOBS=0
# 输出文件名：原名 + 这个后缀 + .m4a
OUTPUT_SUFFIX=_compressed
# =================================

set -euo pipefail
export LC_ALL=C

OVERWRITE=0
DRY_RUN=0

usage() {
	cat <<EOF
用法: $(basename "$0") [选项] 录音文件 ...

把长静音加快，不剪掉。短于 MIN_SILENCE 的空隙保持原速。

选项（覆盖脚本顶部的默认值）:
  -n, --noise-db DB       静音阈值，默认 ${NOISE_DB}（dB）
  -d, --min-silence SEC   短于此时长的静音不处理，默认 ${MIN_SILENCE}
  -s, --speed N           静音中间放快几倍，默认 ${SPEED}（4 约等于 4 秒收成 1 秒）
  -k, --min-keep SEC      放快后至少留这么多秒，默认 ${MIN_KEEP}
      --edge-pad SEC      静音头尾各留这么多秒不加速，默认 ${EDGE_PAD}
  -m, --max-pause SEC     压完后这段空白最长留这么多秒，默认 ${MAX_PAUSE}；0 为不封顶
  -b, --bitrate RATE      成品音质，默认 ${BITRATE}
  -j, --jobs N            同时写几路，默认自动；1 为不并行
  -y, --overwrite         覆盖已有输出
      --dry-run           只打印将要压缩的静音段，不写文件
  -h, --help              显示本说明
EOF
}

die() {
	echo "错误: $*" >&2
	exit 1
}

need_arg() {
	[[ $# -ge 2 ]] || die "选项 $1 需要一个值"
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	-n | --noise-db)
		need_arg "$@"
		NOISE_DB="$2"
		shift 2
		;;
	-d | --min-silence)
		need_arg "$@"
		MIN_SILENCE="$2"
		shift 2
		;;
	-s | --speed)
		need_arg "$@"
		SPEED="$2"
		shift 2
		;;
	-k | --min-keep)
		need_arg "$@"
		MIN_KEEP="$2"
		shift 2
		;;
	--edge-pad)
		need_arg "$@"
		EDGE_PAD="$2"
		shift 2
		;;
	-m | --max-pause)
		need_arg "$@"
		MAX_PAUSE="$2"
		shift 2
		;;
	-b | --bitrate)
		need_arg "$@"
		BITRATE="$2"
		shift 2
		;;
	-j | --jobs)
		need_arg "$@"
		JOBS="$2"
		shift 2
		;;
	-y | --overwrite) OVERWRITE=1; shift ;;
	--dry-run) DRY_RUN=1; shift ;;
	-h | --help)
		usage
		exit 0
		;;
	--)
		shift
		break
		;;
	-*)
		die "未知选项: $1（用 -h 查看）"
		;;
	*) break ;;
	esac
done

[[ $# -ge 1 ]] || {
	usage >&2
	exit 1
}

command -v ffmpeg >/dev/null 2>&1 || die "未找到 ffmpeg"
command -v ffprobe >/dev/null 2>&1 || die "未找到 ffprobe"

NOISE_DB="${NOISE_DB%[dD][bB]}"
awk -v n="$NOISE_DB" -v d="$MIN_SILENCE" -v s="$SPEED" -v k="$MIN_KEEP" -v p="$EDGE_PAD" -v m="$MAX_PAUSE" 'BEGIN {
	if (n !~ /^-?[0-9]+(\.[0-9]+)?$/) exit 1
	if (d !~ /^[0-9]+(\.[0-9]+)?$/ || d + 0 < 0.05) exit 1
	if (s !~ /^[0-9]+(\.[0-9]+)?$/ || s + 0 <= 1) exit 1
	if (k !~ /^[0-9]+(\.[0-9]+)?$/ || k + 0 < 0) exit 1
	if (p !~ /^[0-9]+(\.[0-9]+)?$/ || p + 0 < 0) exit 1
	if (m !~ /^[0-9]+(\.[0-9]+)?$/ || m + 0 < 0) exit 1
}' || die "阈值不合法。SPEED 必须大于 1，MIN_SILENCE 至少 0.05 秒，电平用负数 dB（例如 -40）。"
[[ "$JOBS" =~ ^[0-9]+$ ]] || die "--jobs 必须是 0 或正整数"

duration_of() {
	ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$1"
}

fmt_sec() {
	awk -v t="$1" 'BEGIN {
		if (t + 0 == t) printf "%.1f", t + 0
		else printf "%s", t
	}'
}

fmt_clock() {
	awk -v t="$1" 'BEGIN {
		if (t !~ /^-?[0-9]+(\.[0-9]+)?$/) { printf "%s", t; exit }
		t += 0
		if (t < 0) t = 0
		s = int(t + 0.5)
		h = int(s / 3600)
		m = int(s / 60) % 60
		s = s % 60
		if (h > 0) printf "%d:%02d:%02d", h, m, s
		else printf "%d:%02d", m, s
	}'
}

human_size() {
	awk -v n="$1" 'BEGIN {
		if (n !~ /^[0-9]+$/) { printf "%s", n; exit }
		if (n >= 1048576) printf "%.1f MB", n / 1048576
		else if (n >= 1024) printf "%.0f KB", n / 1024
		else printf "%d B", n
	}'
}

# 读 silencedetect 日志，打出若干行: start end tempo
# tempo=1 表示原速。
build_segments() {
	local log="$1" dur="$2"
	awk -v dur="$dur" -v speed="$SPEED" -v min_keep="$MIN_KEEP" -v edge="$EDGE_PAD" -v max_pause="$MAX_PAUSE" '
	function emit(s, e, tempo) {
		if (e - s < 0.001) return
		printf "%.6f %.6f %.6f\n", s, e, tempo
		count++
		if (tempo > 1.02) sped++
	}
	function emit_silence(s, e,    dur0, pad, mid_in, mid_out, total, tempo) {
		dur0 = e - s
		if (dur0 < 0.02) return
		pad = edge + 0
		if (2 * pad > dur0 * 0.5) pad = dur0 * 0.2
		mid_in = dur0 - 2 * pad
		if (mid_in < 0.05) {
			emit(s, e, 1)
			return
		}
		mid_out = mid_in / speed
		if (mid_out < min_keep) mid_out = min_keep
		if (mid_out > mid_in) mid_out = mid_in
		total = mid_out + 2 * pad
		if (max_pause > 0 && total > max_pause && dur0 > max_pause) {
			pad = edge + 0
			if (2 * pad > max_pause * 0.5) pad = max_pause * 0.2
			mid_out = max_pause - 2 * pad
			if (mid_out < 0.05) {
				pad = 0
				mid_out = max_pause
			}
			mid_in = dur0 - 2 * pad
			if (mid_in < 0.05) {
				emit(s, e, 1)
				return
			}
		}
		if (mid_out >= mid_in - 0.001) {
			emit(s, e, 1)
			return
		}
		tempo = mid_in / mid_out
		if (tempo < 1.05) {
			emit(s, e, 1)
			return
		}
		if (pad > 0.001) emit(s, s + pad, 1)
		emit(s + pad, e - pad, tempo)
		if (pad > 0.001) emit(e - pad, e, 1)
	}
	function num_after(key,    line, n) {
		line = $0
		if (!match(line, key "[[:space:]]*[0-9.]+")) return -1
		n = substr(line, RSTART, RLENGTH)
		sub(/^[^0-9]*/, "", n)
		return n + 0
	}
	/silence_start:/ {
		start = num_after("silence_start:")
		holding = 1
		next
	}
	/silence_end:/ {
		if (!holding) next
		end = num_after("silence_end:")
		if (end < 0) next
		if (end < start) end = start
		if (start > cursor + 0.001) emit(cursor, start, 1)
		emit_silence(start, end)
		cursor = end
		holding = 0
		next
	}
	END {
		if (holding) {
			if (start > cursor + 0.001) emit(cursor, start, 1)
			emit_silence(start, dur)
			cursor = dur
		}
		if (dur > cursor + 0.001) emit(cursor, dur, 1)
		if (count == 0) emit(0, dur, 1)
		printf "STATS %d %d\n", count, sped > "/dev/stderr"
	}
	' "$log"
}

atempo_filters() {
	local tempo="$1" chain="" piece
	while awk -v t="$tempo" 'BEGIN{exit !(t > 2.0)}'; do
		chain+="atempo=2.0,"
		tempo=$(awk -v t="$tempo" 'BEGIN{printf "%.6f", t/2.0}')
	done
	if awk -v t="$tempo" 'BEGIN{exit !(t > 1.01)}'; then
		piece=$(awk -v t="$tempo" 'BEGIN{printf "%.4f", t}')
		chain+="atempo=${piece},"
	fi
	printf '%s' "${chain%,}"
}

# 0 表示大约每 90 秒一路，且不超过 CPU 数。
choose_jobs() {
	local dur="$1" nseg="$2" cpus want
	cpus=$(nproc 2>/dev/null || echo 1)
	[[ "$cpus" =~ ^[0-9]+$ ]] || cpus=1
	if [[ "$JOBS" != "0" ]]; then
		want=$JOBS
	else
		want=$(awk -v d="$dur" -v c="$cpus" 'BEGIN {
			n = int((d + 89) / 90)
			if (n < 1) n = 1
			if (c + 0 < 1) c = 1
			if (n > c) n = c
			printf "%d", n
		}')
	fi
	if (( want > nseg )); then
		want=$nseg
	fi
	if (( want < 1 )); then
		want=1
	fi
	printf '%s' "$want"
}

# 按输入时长把片段分成最多 jobs 份，每份一个 txt。打出实际份数。
split_segments() {
	local src="$1" dest_dir="$2" want="$3"
	awk -v dir="$dest_dir" -v jobs="$want" '
	NF >= 3 && $1 + 0 == $1 {
		n++
		s[n] = $1
		e[n] = $2
		t[n] = $3
		total += $2 - $1
	}
	function chunk_path(i) { return sprintf("%s/%03d.txt", dir, i) }
	END {
		if (n < 1) exit 1
		if (jobs > n) jobs = n
		if (jobs < 1) jobs = 1
		target = total / jobs
		ci = 0
		acc = 0
		for (i = 1; i <= n; i++) {
			dur = e[i] - s[i]
			if (acc > 0 && (acc + dur) > target && ci < jobs - 1) {
				close(chunk_path(ci))
				ci++
				acc = 0
			}
			printf "%.6f %.6f %.6f\n", s[i], e[i], t[i] >> chunk_path(ci)
			acc += dur
		}
		printf "%d\n", ci + 1
	}' "$src"
}

# 写成相对时间的滤镜。打出一行：起点 时长
build_slice_graph() {
	local list="$1" graph="$2"
	local offset start end tempo filters label n=0 concat rel_s rel_e
	offset=$(awk 'NR==1 { printf "%.6f", $1 }' "$list")
	: >"$graph"
	concat=""
	while read -r start end tempo; do
		[[ -n "${start:-}" ]] || continue
		filters=$(atempo_filters "$tempo")
		label="a${n}"
		rel_s=$(awk -v a="$start" -v o="$offset" 'BEGIN{printf "%.6f", (a-o<0 ? 0 : a-o)}')
		rel_e=$(awk -v a="$end" -v o="$offset" 'BEGIN{printf "%.6f", a-o}')
		{
			printf '[0:a]atrim=start=%s:end=%s,asetpts=PTS-STARTPTS' "$rel_s" "$rel_e"
			if [[ -n "$filters" ]]; then
				printf ',%s' "$filters"
			fi
			printf '[%s];\n' "$label"
		} >>"$graph"
		concat+="[${label}]"
		n=$((n + 1))
	done <"$list"
	printf '%sconcat=n=%d:v=0:a=1[out]\n' "$concat" "$n" >>"$graph"
	awk -v o="$offset" 'END { printf "%.6f %.6f\n", o, ($2 - o) + 0.08 }' "$list"
}

# 读 ffmpeg -progress 文件，打出最近一次的已处理微秒，以及是否结束。
read_ffmpeg_progress() {
	local file="$1"
	[[ -f "$file" ]] || {
		printf '0 0\n'
		return
	}
	awk '
		/^out_time_us=/ { us = substr($0, index($0, "=") + 1) }
		/^out_time_ms=/ { if (us == "") us = substr($0, index($0, "=") + 1) }
		/^progress=/ { st = substr($0, index($0, "=") + 1) }
		END {
			if (us == "") us = 0
			end = (st == "end") ? 1 : 0
			printf "%d %d\n", us + 0, end
		}
	' "$file"
}

# 每隔几秒或每前进约 5% 打一行。参数：进度文件 总秒数 标签
watch_one_progress() {
	local file="$1" total="$2" label="$3"
	local last_pct=-1 last_print=$SECONDS us end pct now
	while true; do
		sleep 1
		read -r us end < <(read_ffmpeg_progress "$file")
		pct=$(awk -v u="$us" -v t="$total" 'BEGIN {
			if (t + 0 <= 0) { print 0; exit }
			p = int(100 * (u / 1000000) / t)
			if (p > 100) p = 100
			if (p < 0) p = 0
			print p
		}')
		now=$(awk -v u="$us" 'BEGIN { printf "%.3f", u / 1000000 }')
		if { [[ "$last_pct" -lt 0 ]] && [[ "$pct" -ge 1 ]]; } \
			|| [[ "$pct" -ge $((last_pct + 5)) ]] \
			|| [[ $((SECONDS - last_print)) -ge 20 ]]; then
			echo "${label}  ${pct}%  $(fmt_clock "$now") / $(fmt_clock "$total")"
			last_pct=$pct
			last_print=$SECONDS
		fi
		[[ "$end" -eq 1 || "$pct" -ge 100 ]] && break
	done
}

# 多路写出时，按各路已处理时长合计。参数：目录 标签
watch_many_progress() {
	local dir="$1" label="$2"
	local last_pct=-1 last_print=$SECONDS
	local total=0 done_sec pct n done_n weight us end f base now
	shopt -s nullglob
	local weights=("$dir"/weight_*)
	[[ "${#weights[@]}" -gt 0 ]] || return 0
	for f in "${weights[@]}"; do
		total=$(awk -v a="$total" -v b="$(cat "$f")" 'BEGIN{printf "%.6f", a+b}')
	done
	n=${#weights[@]}
	while true; do
		sleep 1
		[[ -f "$dir/stop_watch" ]] && break
		done_sec=0
		done_n=0
		for f in "$dir"/weight_*; do
			weight=$(cat "$f")
			base=$(basename "$f")
			base=${base#weight_}
			read -r us end < <(read_ffmpeg_progress "$dir/prog_${base}")
			[[ "$end" -eq 1 ]] && done_n=$((done_n + 1))
			now=$(awk -v u="$us" 'BEGIN{printf "%.6f", u/1000000}')
			done_sec=$(awk -v a="$done_sec" -v b="$now" -v w="$weight" 'BEGIN{
				if (b > w) b = w
				if (b < 0) b = 0
				printf "%.6f", a + b
			}')
		done
		pct=$(awk -v d="$done_sec" -v t="$total" 'BEGIN{
			if (t+0<=0) { print 0; exit }
			p=int(100*d/t)
			if (p>100) p=100
			if (p<0) p=0
			print p
		}')
		if { [[ "$last_pct" -lt 0 ]] && [[ "$pct" -ge 1 ]]; } \
			|| [[ "$pct" -ge $((last_pct + 5)) ]] \
			|| [[ $((SECONDS - last_print)) -ge 20 ]]; then
			echo "${label}  ${pct}%  ${done_n}/${n} 路完成  $(fmt_clock "$done_sec") / $(fmt_clock "$total")"
			last_pct=$pct
			last_print=$SECONDS
		fi
		[[ "$done_n" -ge "$n" && "$n" -gt 0 ]] && break
	done
}

# 只解码这一段时间，滤完写成 wav。失败时错误在 err 里。
encode_slice() {
	local src="$1" ss="$2" tlen="$3" graph="$4" wav="$5" err="$6" prog="$7"
	local -a complex_opt
	if [[ "$FF_FILTER_MODE" == "file" ]]; then
		complex_opt=(-/filter_complex "$graph")
	else
		complex_opt=(-filter_complex_script "$graph")
	fi
	ffmpeg -hide_banner -nostats -loglevel error -y \
		-ss "$ss" -t "$tlen" -i "$src" \
		"${complex_opt[@]}" -map '[out]' \
		-progress "$prog" \
		-c:a pcm_s16le "$wav" >"$err" 2>&1
}

# 打印说话电平参考。参数：排好序的电平文件。
# 低于 -70 dB 的窗口当成近乎无声，不拿来代表说话音量。
advice_levels() {
	local sorted="$1"
	awk -v thr="$NOISE_DB" '
	function pct(p,    idx, n) {
		n = A
		idx = int(1 + (n - 1) * p / 100 + 0.5)
		if (idx < 1) idx = 1
		if (idx > n) idx = n
		return aud[idx]
	}
	$1 + 0 == $1 {
		N++
		v = $1 + 0
		if (v <= -70) mute++
		else { A++; aud[A] = v }
	}
	END {
		if (N < 3 || A < 3) {
			print "音量: 有声音的部分太少，电平参考不可靠"
			print "ADVICE short 0 0 0"
			exit
		}
		p10 = pct(10)
		p50 = pct(50)
		p90 = pct(90)
		suggest = p10 + 4
		if (suggest > p50 - 8) suggest = p50 - 8
		if (suggest < -55) suggest = -55
		if (suggest > -15) suggest = -15
		sugn = sprintf("%.0f", suggest)
		printf "音量: 每 2 秒看一次，共 %d 段\n", N
		if (mute > 0 && mute / N >= 0.05)
			printf "近乎无声: 大约 %.0f%% 的时间低于 -70 dB\n", 100 * mute / N
		printf "有声时较静的 10%%: %.1f dB\n", p10
		printf "有声时常见音量:    %.1f dB\n", p50
		printf "有声时较响的 10%%: %.1f dB\n", p90
		if ((p50 - p10) < 6) adv = "flat"
		else if (thr + 0 > p50 - 6) adv = "high"
		else if (thr + 0 < suggest - 4) adv = "low"
		else adv = "ok"
		printf "ADVICE %s %s %.1f %.1f\n", adv, sugn, p10, p50
	}' "$sorted"
}

print_advice() {
	local kind="$1" sugn="$2" p10="$3" p50="$4"
	case "$kind" in
	short) ;;
	flat)
		echo "参考: 有声音的时候大约 ${p50} dB，起伏不大。当前阈值 ${NOISE_DB} dB。若句间停顿压不掉，试 --noise-db ${sugn}"
		;;
	high)
		echo "参考: 当前阈值 ${NOISE_DB} dB 已经贴近说话音量 ${p50} dB，轻声也可能被加快。建议 --noise-db ${sugn}"
		;;
	low)
		echo "参考: 说话常见约 ${p50} dB，较静的有声段约 ${p10} dB。当前阈值 ${NOISE_DB} dB 偏低，句间停顿可能压不到。建议 --noise-db ${sugn}"
		;;
	ok)
		echo "参考: 说话常见约 ${p50} dB，较静约 ${p10} dB。当前阈值 ${NOISE_DB} dB 落在这两者之间。"
		;;
	esac
}

process_one() {
	local in="$1" dur log seg_file fc out stem dir base n=0 sped=0
	local start end tempo filters label concat line stats
	local sr samples level_file sorted errfile
	local regions silence_sec sped_in sped_out saved expect_dur
	local advice_text advice_kind advice_sug advice_p10 advice_p50

	[[ -f "$in" ]] || die "找不到文件: $in"
	dur=$(duration_of "$in")
	awk -v d="$dur" 'BEGIN{exit !(d+0 > 0)}' || die "读不到时长: $in"

	dir=$(dirname "$in")
	base=$(basename "$in")
	stem="${base%.*}"
	[[ "$stem" == "$base" ]] && stem="$base"
	out="${dir}/${stem}${OUTPUT_SUFFIX}.m4a"
	if [[ -e "$out" && "$OVERWRITE" -ne 1 && "$DRY_RUN" -ne 1 ]]; then
		die "输出已存在: $out（加 -y 覆盖）"
	fi

	log=$(mktemp)
	seg_file=$(mktemp)
	fc=$(mktemp)
	level_file=$(mktemp)
	sorted=$(mktemp)
	errfile=$(mktemp)
	# shellcheck disable=SC2064
	trap "rm -f '$log' '$seg_file' '$fc' '$level_file' '$sorted' '$errfile'" RETURN

	sr=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=nw=1:nk=1 "$in" || true)
	[[ "$sr" =~ ^[0-9]+$ ]] || sr=48000
	samples=$((sr * 2))

	echo "处理: $in"
	echo "正在看电平和静音（阈值 ${NOISE_DB} dB，短于 ${MIN_SILENCE}s 的空隙忽略）…"
	local detect_prog detect_watch
	detect_prog=$(mktemp)
	watch_one_progress "$detect_prog" "$dur" "检测" &
	detect_watch=$!
	if ! ffmpeg -hide_banner -nostats -i "$in" \
		-af "silencedetect=n=${NOISE_DB}dB:d=${MIN_SILENCE},asetnsamples=n=${samples}:p=0,astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level:file=${level_file}" \
		-progress "$detect_prog" \
		-f null - >"$log" 2>&1; then
		kill "$detect_watch" 2>/dev/null || true
		wait "$detect_watch" 2>/dev/null || true
		rm -f "$detect_prog"
		die "ffmpeg 检测静音失败: $in"
	fi
	kill "$detect_watch" 2>/dev/null || true
	wait "$detect_watch" 2>/dev/null || true
	rm -f "$detect_prog"
	echo "检测  100%  $(fmt_clock "$dur") / $(fmt_clock "$dur")"

	build_segments "$log" "$dur" >"$seg_file" 2>"${seg_file}.stats" || die "划分静音段失败: $in"
	stats=$(cat "${seg_file}.stats")
	rm -f "${seg_file}.stats"
	# STATS 总段数 被加速的段数
	sped=$(awk '{print $3}' <<<"$stats")
	sped=${sped:-0}

	regions=$(grep -c 'silence_start:' "$log" || true)
	regions=${regions:-0}
	silence_sec=$(awk -v dur="$dur" '
		function num_after(key,    line, n) {
			line = $0
			if (!match(line, key "[[:space:]]*[0-9.]+")) return -1
			n = substr(line, RSTART, RLENGTH)
			sub(/^[^0-9]*/, "", n)
			return n + 0
		}
		/silence_start:/ { start = num_after("silence_start:"); holding = 1; next }
		/silence_duration:/ {
			d = num_after("silence_duration:")
			if (d >= 0) sum += d
			holding = 0
			next
		}
		END {
			if (holding && dur + 0 > start) sum += dur - start
			printf "%.3f", sum + 0
		}
	' "$log")
	read -r sped_n sped_in sped_out < <(awk '
		$3 + 0 > 1.02 { n++; inn += $2 - $1; out += ($2 - $1) / $3 }
		END { printf "%d %.3f %.3f\n", n + 0, inn + 0, out + 0 }
	' "$seg_file")
	saved=$(awk -v a="$sped_in" -v b="$sped_out" 'BEGIN{printf "%.3f", a - b}')
	expect_dur=$(awk -v d="$dur" -v s="$saved" 'BEGIN{printf "%.3f", d - s}')

	awk -F= '/RMS_level/ {
		v = $NF
		if (v == "-inf") v = -90
		if (v + 0 == v) print v + 0
	}' "$level_file" | sort -n >"$sorted"

	echo
	echo "---------- 情况 ----------"
	echo "文件: $in"
	echo "原长: $(fmt_clock "$dur")（$(fmt_sec "$dur") 秒）"
	if awk -v m="$MAX_PAUSE" 'BEGIN{exit !(m+0 > 0)}'; then
		echo "规则: 低于 ${NOISE_DB} dB 且长于 ${MIN_SILENCE} 秒才压；按 ${SPEED} 倍加快，压完每段最长 ${MAX_PAUSE} 秒"
	else
		echo "规则: 低于 ${NOISE_DB} dB 且长于 ${MIN_SILENCE} 秒才压；按 ${SPEED} 倍加快，不设停顿上限"
	fi
	if awk -v r="$regions" 'BEGIN{exit !(r+0 > 0)}'; then
		echo "长静音: ${regions} 段，共 $(fmt_clock "$silence_sec")（$(fmt_sec "$silence_sec") 秒）"
	else
		echo "长静音: 没有"
	fi
	if awk -v n="$sped_n" 'BEGIN{exit !(n+0 > 0)}'; then
		echo "将缩短: $(fmt_sec "$saved") 秒（这些静音的中间从 $(fmt_sec "$sped_in") 秒加快到 $(fmt_sec "$sped_out") 秒），预计变成 $(fmt_clock "$expect_dur")"
	else
		echo "将缩短: 0 秒。短于 ${MIN_SILENCE} 秒的气口保持原样，这次没有更长的静音。"
	fi
	advice_text=$(advice_levels "$sorted")
	printf '%s\n' "$advice_text" | awk '$1 != "ADVICE"'
	advice_kind=$(printf '%s\n' "$advice_text" | awk '$1=="ADVICE"{print $2}')
	advice_sug=$(printf '%s\n' "$advice_text" | awk '$1=="ADVICE"{print $3}')
	advice_p10=$(printf '%s\n' "$advice_text" | awk '$1=="ADVICE"{print $4}')
	advice_p50=$(printf '%s\n' "$advice_text" | awk '$1=="ADVICE"{print $5}')
	print_advice "$advice_kind" "$advice_sug" "$advice_p10" "$advice_p50"

	if [[ "$sped" -eq 0 ]]; then
		echo
		echo "---------- 结果 ----------"
		echo "未写新文件。"
		return 0
	fi

	if [[ "$DRY_RUN" -eq 1 ]]; then
		echo
		echo "将压缩的时间段:"
		printf '  %-12s %-12s %-8s %s\n' "开始" "结束" "倍数" "处理"
		while read -r start end tempo; do
			[[ "$start" == "STATS" ]] && continue
			if awk -v t="$tempo" 'BEGIN{exit !(t > 1.02)}'; then
				printf '  %-12s %-12s %-8s %s\n' "$start" "$end" "$tempo" "压缩"
			fi
		done <"$seg_file"
		echo
		echo "---------- 结果 ----------"
		echo "演习，未写文件。去掉 --dry-run 才会写出。"
		return 0
	fi

	local ff_major nseg want part_dir chunk_count list ss tlen graph wav
	local -a lists=()
	ff_major=$(ffmpeg -hide_banner -version | awk 'NR==1 { if (match($3, /^[0-9]+/)) print substr($3, RSTART, RLENGTH); exit }')
	if [[ "${ff_major:-0}" -ge 7 ]]; then
		FF_FILTER_MODE=file
	else
		FF_FILTER_MODE=script
	fi
	nseg=$(grep -cve '^[[:space:]]*$' "$seg_file" || true)
	nseg=${nseg:-0}
	[[ "$nseg" -gt 0 ]] || die "没有可输出的片段: $in"
	want=$(choose_jobs "$dur" "$nseg")
	part_dir=$(mktemp -d)
	# shellcheck disable=SC2064
	trap "rm -f '$log' '$seg_file' '$fc' '$level_file' '$sorted' '$errfile'; rm -rf '$part_dir'; jobs -rp | xargs -r kill" RETURN
	chunk_count=$(split_segments "$seg_file" "$part_dir" "$want")
	mapfile -t lists < <(find "$part_dir" -maxdepth 1 -name '[0-9][0-9][0-9].txt' | sort)
	[[ "${#lists[@]}" -gt 0 ]] || die "没有分出可写的片段: $in"

	echo
	if [[ "${#lists[@]}" -eq 1 ]]; then
		echo "正在写出: $out"
	else
		echo "正在用 ${#lists[@]} 路同时写出: $out"
	fi
	echo "下面每约 5% 或 20 秒更新一次。长时间停在同一百分比，表示这一路还在算。"

	local idx=0 slice write_watch fail=0
	local -a write_pids=()
	for list in "${lists[@]}"; do
		slice=$(printf '%03d' "$idx")
		read -r ss tlen < <(build_slice_graph "$list" "$part_dir/graph_${slice}")
		awk '{ d += ($2 - $1) / $3 } END { printf "%.6f\n", d + 0.05 }' "$list" >"$part_dir/weight_${slice}"
		: >"$part_dir/prog_${slice}"
		encode_slice "$in" "$ss" "$tlen" "$part_dir/graph_${slice}" \
			"$part_dir/part_${slice}.wav" "$part_dir/err_${slice}" \
			"$part_dir/prog_${slice}" &
		write_pids+=("$!")
		idx=$((idx + 1))
	done
	watch_many_progress "$part_dir" "写出" &
	write_watch=$!
	for idx in "${write_pids[@]}"; do
		wait "$idx" || fail=1
	done
	touch "$part_dir/stop_watch"
	kill "$write_watch" 2>/dev/null || true
	wait "$write_watch" 2>/dev/null || true
	if [[ "$fail" -ne 0 ]]; then
		cat "$part_dir"/err_* >&2 || true
		die "其中一路写出失败: $in"
	fi
	echo "写出  100%  ${#lists[@]}/${#lists[@]} 路完成"

	local joined="$part_dir/joined.wav" concat_list="$part_dir/concat.txt"
	: >"$concat_list"
	for wav in "$part_dir"/part_*.wav; do
		[[ -f "$wav" ]] || die "缺少分段: $wav"
		printf "file '%s'\n" "$wav" >>"$concat_list"
	done
	if ! ffmpeg -hide_banner -nostats -loglevel error -y \
		-f concat -safe 0 -i "$concat_list" -c copy "$joined" 2>"$errfile"; then
		cat "$errfile" >&2
		die "拼回失败: $out"
	fi
	local joined_dur pack_prog pack_watch
	joined_dur=$(duration_of "$joined")
	pack_prog="$part_dir/prog_pack"
	echo "正在封装成 m4a…"
	watch_one_progress "$pack_prog" "$joined_dur" "封装" &
	pack_watch=$!
	if ! ffmpeg -hide_banner -nostats -loglevel error -y -i "$joined" \
		-map_chapters -1 -c:a aac -b:a "$BITRATE" -movflags +faststart \
		-progress "$pack_prog" \
		"$out" 2>"$errfile"; then
		kill "$pack_watch" 2>/dev/null || true
		wait "$pack_watch" 2>/dev/null || true
		cat "$errfile" >&2
		die "写出失败: $out"
	fi
	kill "$pack_watch" 2>/dev/null || true
	wait "$pack_watch" 2>/dev/null || true
	echo "封装  100%  $(fmt_clock "$joined_dur") / $(fmt_clock "$joined_dur")"

	out_dur=$(duration_of "$out")
	out_saved=$(awk -v a="$dur" -v b="$out_dur" 'BEGIN{printf "%.3f", a-b}')
	out_pct=$(awk -v s="$out_saved" -v d="$dur" 'BEGIN{ if (d+0<=0) print "0.0"; else printf "%.1f", 100*s/d }')
	echo
	echo "---------- 结果 ----------"
	echo "已写出: $out（$(human_size "$(stat -c %s "$out")")）"
	echo "时长: $(fmt_clock "$dur") → $(fmt_clock "$out_dur")，缩短 $(fmt_sec "$out_saved") 秒（${out_pct}%）"
}

for f in "$@"; do
	process_one "$f"
done

#!/usr/bin/env bash
# 交互式恢复 ext3/ext4 上刚删除的文件。
#
# 优先用 ext4magic（apt 包 ext4magic）：日志还是旧格式时，能找回原文件名。
# Debian 13 默认 ext4 的日志带 journal checksum v3，ext4magic 0.3.2 读不懂，
# 这时改用 photorec（apt 包 testdisk）按文件头取出内容，目录名不会保留。
#
# 用法：
#   sudo ./ext4magic_recover.sh
#   sudo ./ext4magic_recover.sh /dev/sdXN
#   sudo ./ext4magic_recover.sh /path/to/filesystem.img
#
# 输出目录必须在另一块文件系统上。恢复前不要对源分区跑 fsck，也不要再往上写数据。

set -u

DEVICE=""
JOURNAL=""
AFTER=""
BEFORE=""
TIME_LABEL="最近 24 小时（ext4magic 默认，不额外传时间）"
RELPATH=""
OUTDIR=""
USE_Q=0
FS_TYPE=""
FS_LABEL=""
FS_UUID=""
FS_SIZE=""
JOURNAL_LIMIT=""
MOUNT_TARGETS=()
MOUNT_RW=0

die() {
	printf '错误: %s\n' "$*" >&2
	exit 1
}

confirm() {
	local reply
	read -r -p "$1 [y/N]: " reply || return 1
	[[ "$reply" == [yY] ]]
}

# 把用户输入写进指定变量。第三个参数是回车时采用的默认值。
prompt_var() {
	local __name="$1" __text="$2" __def="${3-}" __ans
	if [[ -n "$__def" ]]; then
		read -r -p "${__text} [${__def}]: " __ans || return 1
		__ans="${__ans:-$__def}"
	else
		read -r -p "${__text}: " __ans || return 1
	fi
	printf -v "$__name" '%s' "$__ans"
}

print_cmd() {
	local arg
	printf '命令:'
	for arg in "$@"; do
		printf ' %q' "$arg"
	done
	printf '\n'
}

trim_ws() {
	local s="$1"
	s="${s#"${s%%[![:space:]]*}"}"
	s="${s%"${s##*[![:space:]]}"}"
	printf '%s' "$s"
}

have_python() {
	[[ -x /usr/bin/python3 ]]
}

losetup_cmd() {
	if command -v losetup >/dev/null 2>&1; then
		command -v losetup
		return 0
	fi
	if [[ -x /usr/sbin/losetup ]]; then
		printf '%s\n' /usr/sbin/losetup
	fi
}

opts_readonly() {
	local opts="$1" tok
	local -a parts=()
	IFS=',' read -r -a parts <<< "$opts"
	for tok in "${parts[@]}"; do
		[[ "$tok" == "ro" ]] && return 0
	done
	return 1
}

# 从 findmnt -P 的一行里取出 KEY="value"。值里如果含有引号，这里不会展开转义。
field_of() {
	local line="$1" key="$2" re
	re=".*${key}=\"([^\"]*)\".*"
	if [[ "$line" =~ $re ]]; then
		printf '%s' "${BASH_REMATCH[1]}"
	fi
}

nearest_dir() {
	local p="$1"
	if [[ -d "$p" ]]; then
		printf '%s' "$p"
		return 0
	fi
	while [[ ! -d "$p" ]]; do
		p="$(dirname -- "$p")"
		[[ "$p" == "/" ]] && break
	done
	printf '%s' "$p"
}

# 路径所在的已挂载文件系统，是不是正在恢复的那一块。
same_fs_as_source() {
	local path="$1" dir mm src_mm src back
	[[ -n "$DEVICE" ]] || return 1
	dir="$(nearest_dir "$path")"
	[[ -d "$dir" ]] || return 1
	if [[ -b "$DEVICE" ]]; then
		src_mm="$(lsblk -ndo MAJ:MIN -- "$DEVICE" 2>/dev/null || true)"
		mm="$(findmnt -nro MAJ:MIN -T "$dir" 2>/dev/null || true)"
		src_mm="${src_mm//[[:space:]]/}"
		mm="${mm//[[:space:]]/}"
		[[ -n "$src_mm" && -n "$mm" && "$src_mm" == "$mm" ]]
		return
	fi
	src="$(readlink -f -- "$DEVICE")"
	mm="$(findmnt -nro SOURCE -T "$dir" 2>/dev/null || true)"
	if [[ "$mm" == /dev/loop* ]]; then
		local lo
		lo="$(losetup_cmd)"
		if [[ -n "$lo" ]]; then
			back="$("$lo" -ln -O BACK-FILE "$mm" 2>/dev/null || true)"
			back="$(trim_ws "$back")"
			if [[ -n "$back" ]]; then
				back="$(readlink -f -- "$back" 2>/dev/null || true)"
			fi
			[[ -n "$back" && "$back" == "$src" ]]
			return
		fi
	fi
	return 1
}

add_mount_line() {
	local line="$1" target opts
	target="$(field_of "$line" TARGET)"
	opts="$(field_of "$line" OPTIONS)"
	[[ -z "$target" ]] && return 0
	MOUNT_TARGETS+=("$target")
	if ! opts_readonly "$opts"; then
		MOUNT_RW=1
	fi
}

refresh_mount_state() {
	local line src lo
	MOUNT_TARGETS=()
	MOUNT_RW=0
	if [[ -b "$DEVICE" ]]; then
		while IFS= read -r line; do
			add_mount_line "$line"
		done < <(findmnt -nP -S "$DEVICE" -o TARGET,OPTIONS 2>/dev/null || true)
		return 0
	fi
	[[ -f "$DEVICE" ]] || return 0
	lo="$(losetup_cmd)"
	[[ -n "$lo" ]] || return 0
	# 镜像如果还挂在某个 loop 上，写 loop 等于写镜像。
	while IFS= read -r src; do
		[[ -z "$src" ]] && continue
		while IFS= read -r line; do
			add_mount_line "$line"
		done < <(findmnt -nP -S "$src" -o TARGET,OPTIONS 2>/dev/null || true)
	done < <("$lo" -j "$DEVICE" 2>/dev/null | awk -F: '{ print $1 }')
}

# ext4magic 0.3.2 读不懂 journal checksum v2/v3。Debian 13 默认的 ext4 就是这种日志。
detect_journal_limit() {
	local info
	JOURNAL_LIMIT=""
	[[ -n "$DEVICE" && -e "$DEVICE" ]] || return 0
	info="$(debugfs -R 'logdump -S' "$DEVICE" 2>/dev/null || true)"
	if [[ "$info" == *journal_checksum_v3* || "$info" == *journal_checksum_v2* ]]; then
		JOURNAL_LIMIT="checksum"
	fi
}

warn_journal_limit() {
	[[ "$JOURNAL_LIMIT" == "checksum" ]] || return 0
	echo
	echo "这块文件系统的日志是 checksum v3（Debian 13 新建的 ext4 默认就是这样）。"
	echo "软件仓库里的 ext4magic 0.3.2 读这种日志时，列表经常是空的，文件也恢复不出来。"
	echo "要文件内容请用菜单 14 的 photorec。它按文件头雕刻，原目录名一般不会留下来。"
	confirm "仍然继续跑 ext4magic？" || return 1
}

load_device_info() {
	FS_TYPE="$(blkid -u filesystem -o value -s TYPE -- "$DEVICE" 2>/dev/null || true)"
	FS_LABEL="$(blkid -u filesystem -o value -s LABEL -- "$DEVICE" 2>/dev/null || true)"
	FS_UUID="$(blkid -u filesystem -o value -s UUID -- "$DEVICE" 2>/dev/null || true)"
	if [[ -b "$DEVICE" ]]; then
		FS_SIZE="$(lsblk -ndo SIZE -- "$DEVICE" 2>/dev/null || true)"
	elif [[ -f "$DEVICE" ]]; then
		FS_SIZE="$(du -h --apparent-size -- "$DEVICE" | awk 'NR==1 { print $1 }')"
	else
		FS_SIZE=""
	fi
	refresh_mount_state
	detect_journal_limit
}

mount_summary() {
	local t
	if [[ ${#MOUNT_TARGETS[@]} -eq 0 ]]; then
		if [[ -b "$DEVICE" ]]; then
			printf '未挂载'
		else
			printf '镜像文件'
		fi
		return 0
	fi
	printf '%s' "${MOUNT_TARGETS[0]}"
	if [[ ${#MOUNT_TARGETS[@]} -gt 1 ]]; then
		printf ' 等 %s 处' "${#MOUNT_TARGETS[@]}"
	fi
	if [[ "$MOUNT_RW" -eq 1 ]]; then
		printf '（读写）'
	else
		printf '（只读）'
	fi
	if [[ ${#MOUNT_TARGETS[@]} -gt 1 ]]; then
		printf '\n          '
		for t in "${MOUNT_TARGETS[@]:1}"; do
			printf '%s ' "$t"
		done
	fi
}

print_status() {
	echo
	echo "======== ext4 删除文件恢复 ========"
	if [[ -z "$DEVICE" ]]; then
		echo "设备    还没选"
	else
		echo "设备    $DEVICE"
		echo "文件系统  ${FS_TYPE:-未知}  ${FS_SIZE:-?}  ${FS_LABEL:+标签 $FS_LABEL  }${FS_UUID:+UUID $FS_UUID}"
		echo "挂载    $(mount_summary)"
	fi
	echo "时间    $TIME_LABEL"
	if [[ -n "$RELPATH" ]]; then
		echo "范围    /$RELPATH"
	else
		echo "范围    整个文件系统"
	fi
	echo "输出    ${OUTDIR:-还没设置}"
	if [[ -n "$JOURNAL" ]]; then
		echo "日志    使用副本 $JOURNAL"
	elif [[ "$MOUNT_RW" -eq 1 ]]; then
		echo "日志    分区还在读写，恢复前要先卸载、改只读，或导出日志副本"
	else
		echo "日志    直接读分区里的日志"
	fi
	if [[ "$JOURNAL_LIMIT" == "checksum" ]]; then
		echo "限制    日志带 checksum v3。ext4magic 0.3.2 通常读不出已删除文件，内容恢复用菜单 14"
	fi
	if [[ "$USE_Q" -eq 1 ]]; then
		echo "严格    开（-Q，少一些错文件，也可能漏文件）"
	else
		echo "严格    关"
	fi
	echo "==================================="
}

print_menu() {
	if [[ "${JOURNAL_LIMIT:-}" == "checksum" ]]; then
		cat <<'EOF'
  1) 选择分区或镜像文件
  2) 卸载，或改成只读挂载
  3) 导出 / 更新日志副本
  4) 设置删除时间范围
  5) 限定目录或文件
  6) 设置输出目录
  7) 切换严格模式 -Q
  8) 查看超级块和日志
  9) 时间直方图（判断大概何时被删）
 10) 列出可恢复的已删除文件（这块盘上多半是空的）
 11) 仍用 ext4magic 恢复（这块盘的日志它多半读不懂）
 12) 尽量恢复（-R，已占用的块也写出，内容可能是坏的）
 13) 多阶段恢复（目录被整棵删掉时）
 14) 用 photorec 取文件内容（推荐）
  0) 退出
EOF
		return 0
	fi
	cat <<'EOF'
  1) 选择分区或镜像文件
  2) 卸载，或改成只读挂载
  3) 导出 / 更新日志副本
  4) 设置删除时间范围
  5) 限定目录或文件
  6) 设置输出目录
  7) 切换严格模式 -Q
  8) 查看超级块和日志
  9) 时间直方图（判断大概何时被删）
 10) 列出可恢复的已删除文件
 11) 恢复已删除文件（数据块还空着的，推荐）
 12) 尽量恢复（-R，已占用的块也写出，内容可能是坏的）
 13) 多阶段恢复（目录被整棵删掉时）
 14) 改用 photorec（日志里已经没有记录时）
  0) 退出
EOF
}

need_device() {
	if [[ -z "$DEVICE" ]]; then
		echo "先选择要恢复的分区或镜像。"
		return 1
	fi
	return 0
}

check_deps() {
	local missing=()
	command -v ext4magic >/dev/null 2>&1 || missing+=(ext4magic)
	command -v debugfs >/dev/null 2>&1 || missing+=(e2fsprogs)
	command -v blkid >/dev/null 2>&1 || missing+=(util-linux)
	command -v lsblk >/dev/null 2>&1 || missing+=(util-linux)
	if [[ ${#missing[@]} -eq 0 ]]; then
		return 0
	fi
	echo "缺少命令，对应软件包：${missing[*]}"
	confirm "现在用 apt 安装 ext4magic 和 e2fsprogs？" || die "缺少 ext4magic 或 debugfs。"
	if ! apt-get install -y ext4magic e2fsprogs; then
		apt-get update
		apt-get install -y ext4magic e2fsprogs || die "安装失败。"
	fi
	command -v ext4magic >/dev/null 2>&1 || die "仍然找不到 ext4magic。"
	command -v debugfs >/dev/null 2>&1 || die "仍然找不到 debugfs。"
}

list_candidates() {
	have_python || return 1
	/usr/bin/python3 - <<'PY'
import json, subprocess, sys
raw = subprocess.check_output(
    ["lsblk", "-J", "-o", "PATH,FSTYPE,SIZE,LABEL,MOUNTPOINTS,TYPE"],
    text=True,
)
data = json.loads(raw)

def walk(nodes):
    for node in nodes or []:
        yield node
        yield from walk(node.get("children"))

for node in walk(data.get("blockdevices")):
    fstype = node.get("fstype") or ""
    if fstype not in ("ext3", "ext4"):
        continue
    mounts = [m for m in (node.get("mountpoints") or []) if m]
    fields = [
        node.get("path") or "",
        fstype,
        node.get("size") or "",
        node.get("label") or "",
        "|".join(mounts),
        node.get("type") or "",
    ]
    sys.stdout.write("\x1f".join(fields) + "\n")
PY
}

choose_device() {
	local -a paths=() descs=()
	local line path fs size label mp typ choice n
	echo
	echo "本机上的 ext3/ext4："
	if have_python; then
		while IFS=$'\x1f' read -r path fs size label mp typ; do
			[[ -z "$path" ]] && continue
			paths+=("$path")
			if [[ -n "$mp" ]]; then
				mp="${mp//|/、}"
				descs+=("$fs  $size  ${label:+[$label] }挂载于 $mp")
			else
				descs+=("$fs  $size  ${label:+[$label] }未挂载")
			fi
		done < <(list_candidates || true)
	else
		echo "（没有 /usr/bin/python3，跳过自动列表，请手动输入路径。）"
	fi
	n=1
	for path in "${paths[@]}"; do
		printf '  %2d) %-22s %s\n' "$n" "$path" "${descs[$((n - 1))]}"
		n=$((n + 1))
	done
	echo "   0) 手动输入块设备或镜像文件路径"
	prompt_var choice "序号或路径" || return 1
	if [[ "$choice" == "0" ]]; then
		prompt_var path "设备或镜像路径" || return 1
	elif [[ "$choice" == /* ]]; then
		path="$choice"
	elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#paths[@]} )); then
		path="${paths[$((choice - 1))]}"
	else
		echo "没有这个选项。"
		return 1
	fi
	set_device "$path"
}

set_device() {
	local input="$1" kids
	[[ -n "$input" ]] || return 1
	if [[ ! -e "$input" ]]; then
		echo "路径不存在：$input"
		return 1
	fi
	DEVICE="$(readlink -f -- "$input")"
	JOURNAL=""
	load_device_info
	if [[ "$FS_TYPE" != "ext3" && "$FS_TYPE" != "ext4" ]]; then
		echo "blkid 读到的类型是「${FS_TYPE:-空}」。ext4magic 只处理 ext3/ext4。"
		confirm "仍然使用 $DEVICE？" || {
			DEVICE=""
			return 1
		}
	fi
	if [[ -b "$DEVICE" ]]; then
		kids="$(lsblk -ln -- "$DEVICE" | wc -l)"
		if [[ "$kids" -gt 1 && -z "$FS_TYPE" ]]; then
			echo "这是整块盘，上面还有分区。请改选具体的 ext4 分区。"
			DEVICE=""
			return 1
		fi
	fi
	relocate_script_if_needed || true
	cd /
	if [[ "$MOUNT_RW" -eq 1 ]]; then
		echo
		echo "注意：$DEVICE 正以读写方式挂载（$(mount_summary)）。"
		echo "ext4magic 不能直接读这块还在写入的日志，否则会得到错误结果。"
		echo "后面执行查看或恢复时，会先要求卸载、改只读，或把日志复制到别的盘。"
		echo "根分区和正在使用的 /home 通常卸不掉，那种情况请用 Live USB 启动后再跑本脚本。"
	fi
	echo "已选择 $DEVICE"
}

# 脚本自己如果放在待恢复分区上，卸载时会把分区占住。复制到 /run 再继续。
relocate_script_if_needed() {
	local self dest
	[[ "${EXT4MAGIC_RELOCATED:-}" == "1" ]] && return 0
	[[ -n "$DEVICE" ]] || return 0
	self="$(readlink -f -- "${BASH_SOURCE[0]}")"
	same_fs_as_source "$self" || return 0
	if same_fs_as_source /run; then
		echo "脚本位于待恢复分区上，并且 /run 也在这块分区里。请把脚本拷到别的盘再运行。"
		return 0
	fi
	dest="/run/ext4magic_recover.$$.sh"
	cp -- "$self" "$dest"
	chmod 0700 "$dest"
	echo "脚本位于待恢复分区上，已复制到 $dest 再继续，避免占着挂载点。"
	export EXT4MAGIC_RELOCATED=1
	exec bash "$dest" "$DEVICE"
}

is_live_system_mount() {
	local t
	for t in "${MOUNT_TARGETS[@]}"; do
		case "$t" in
		/|/usr|/usr/*|/boot|/boot/*) return 0 ;;
		esac
	done
	return 1
}

try_unmount_or_readonly() {
	local mode t fail=0
	need_device || return 1
	refresh_mount_state
	if [[ ${#MOUNT_TARGETS[@]} -eq 0 ]]; then
		echo "当前没有挂载，可以直接读分区里的日志。"
		JOURNAL=""
		return 0
	fi
	echo "当前挂载："
	printf '  %s\n' "${MOUNT_TARGETS[@]}"
	if is_live_system_mount; then
		echo "这里面包含正在运行的系统目录（/、/usr 或 /boot），不能卸载，也不能改只读。"
		echo "请用 Live USB 启动，再对这块分区运行本脚本。"
		return 1
	fi
	echo "  1) 卸载"
	echo "  2) 改成只读挂载（成功后就可以直接读日志）"
	echo "  0) 取消"
	prompt_var mode "选择" "1" || return 1
	case "$mode" in
	0) return 1 ;;
	2)
		echo "改只读时，系统仍会把未写入的数据刷进日志。删除记录有可能因此被顶掉。"
		confirm "仍然把这些挂载点改成只读？" || return 1
		cd /
		fail=0
		for t in "${MOUNT_TARGETS[@]}"; do
			if ! mount -o remount,ro -- "$t"; then
				echo "改只读失败：$t"
				command -v fuser >/dev/null 2>&1 && fuser -vm "$t" || true
				fail=1
			fi
		done
		;;
	*)
		echo "卸载时系统也会刷一次日志。删除之后如果几乎没有别的写入，记录通常还在。"
		confirm "现在卸载？" || return 1
		cd /
		fail=0
		for t in "${MOUNT_TARGETS[@]}"; do
			if ! umount -- "$t"; then
				echo "卸载失败：$t"
				if command -v fuser >/dev/null 2>&1; then
					echo "仍占用它的进程："
					fuser -vm "$t" || true
				fi
				fail=1
			fi
		done
		;;
	esac
	refresh_mount_state
	if [[ "$fail" -eq 0 && "$MOUNT_RW" -eq 0 ]]; then
		JOURNAL=""
		echo "现在可以直接读分区里的日志。"
		return 0
	fi
	echo "分区仍是读写挂载。可以改用菜单 3，把日志复制到别的盘。"
	return 1
}

journal_bytes() {
	debugfs -R 'stat <8>' "$DEVICE" 2>/dev/null | awk '/^Size:/ { print $2; exit }'
}

suggest_dir() {
	local allow_tmpfs="$1"
	local line target fstype avail best="" best_avail=-1
	while IFS= read -r line; do
		target="$(field_of "$line" TARGET)"
		fstype="$(field_of "$line" FSTYPE)"
		[[ -d "$target" ]] || continue
		case "$fstype" in
		tmpfs|devtmpfs)
			[[ "$allow_tmpfs" == "1" ]] || continue
			;;
		ext2|ext3|ext4|xfs|btrfs|bcachefs) ;;
		*) continue ;;
		esac
		same_fs_as_source "$target" && continue
		avail="$(df -P -B1 -- "$target" | awk 'NR==2 { print $4 }')"
		[[ "$avail" =~ ^[0-9]+$ ]] || continue
		if (( avail > best_avail )); then
			best="$target"
			best_avail=$avail
		fi
	done < <(findmnt -nP -o TARGET,FSTYPE 2>/dev/null || true)
	printf '%s' "$best"
}

human_bytes() {
	local n="${1:-0}"
	if [[ ! "$n" =~ ^[0-9]+$ ]]; then
		printf '?'
		return
	fi
	if (( n >= 1073741824 )); then
		printf '%sG' "$((n / 1073741824))"
	elif (( n >= 1048576 )); then
		printf '%sM' "$((n / 1048576))"
	else
		printf '%sK' "$((n / 1024))"
	fi
}

dump_journal() {
	local dir dest bytes avail err
	need_device || return 1
	refresh_mount_state
	if [[ "$MOUNT_RW" -eq 0 ]]; then
		echo "分区没在读写挂载，可以直接读内部日志，一般不用副本。"
		confirm "仍然导出一份日志副本？" || return 1
	fi
	dir="$(suggest_dir 1)"
	echo "副本必须放在别的文件系统上。日志文件通常是 128MB 到 1GB。"
	prompt_var dir "存放目录" "$dir" || return 1
	if same_fs_as_source "$dir"; then
		echo "这个目录就在待恢复的文件系统上。换一块盘。"
		return 1
	fi
	mkdir -p -- "$dir" || return 1
	if [[ ! -d "$dir" || ! -w "$dir" ]]; then
		echo "目录不可写：$dir"
		return 1
	fi
	dest="${dir%/}/journal-$(basename -- "$DEVICE")-$(date +%Y%m%d-%H%M%S).bin"
	if [[ "$dest" == *[[:space:]]* || "$dest" == *\"* ]]; then
		echo "路径里不要有空格或引号，debugfs 接不住。"
		return 1
	fi
	bytes="$(journal_bytes || true)"
	avail="$(df -P -B1 -- "$dir" | awk 'NR==2 { print $4 }')"
	if [[ "$bytes" =~ ^[0-9]+$ && "$avail" =~ ^[0-9]+$ ]] && (( avail < bytes )); then
		echo "空间不够。日志约 $(human_bytes "$bytes")，目录只剩 $(human_bytes "$avail")。"
		return 1
	fi
	echo "正在把日志 inode 8 复制到 $dest"
	[[ "$bytes" =~ ^[0-9]+$ ]] && echo "日志大小约 $(human_bytes "$bytes")"
	err="$(mktemp)"
	debugfs -R "dump <8> ${dest}" "$DEVICE" 2>"$err" || true
	if [[ -s "$err" ]]; then
		echo "debugfs 提示："
		cat "$err"
	fi
	rm -f -- "$err"
	if [[ ! -s "$dest" ]]; then
		echo "副本是空的。这块文件系统可能用了外部日志，或者 inode 8 读不出来。"
		echo "请先卸载分区，让 ext4magic 自己找日志。"
		rm -f -- "$dest"
		return 1
	fi
	if [[ "$bytes" =~ ^[0-9]+$ ]]; then
		local actual
		actual="$(stat -c '%s' -- "$dest")"
		if (( actual < bytes )); then
			echo "副本不完整（$(human_bytes "$actual") / $(human_bytes "$bytes")）。"
			rm -f -- "$dest"
			return 1
		fi
	fi
	JOURNAL="$dest"
	echo "日志副本已就绪：$JOURNAL（$(du -h -- "$JOURNAL" | awk 'NR==1 { print $1 }')）"
	echo "导出之后不要再往源分区写数据，否则这份副本就过时了。"
}

# 读写挂载时，ext4magic 必须改用日志副本。返回 1 表示用户取消本次操作。
ensure_journal_access() {
	refresh_mount_state
	if [[ "$MOUNT_RW" -eq 0 ]]; then
		return 0
	fi
	if [[ -n "$JOURNAL" && -s "$JOURNAL" ]]; then
		return 0
	fi
	echo
	echo "$DEVICE 仍以读写方式挂载。直接读它的日志会得到错误结果。"
	echo "  1) 先去卸载或改只读"
	echo "  2) 把日志复制到别的盘，然后用这份副本"
	echo "  0) 取消"
	local pick
	prompt_var pick "选择" "2" || return 1
	case "$pick" in
	1)
		try_unmount_or_readonly || return 1
		refresh_mount_state
		if [[ "$MOUNT_RW" -eq 1 ]]; then
			echo "分区还是读写的。本次不继续。"
			return 1
		fi
		;;
	2)
		dump_journal || return 1
		;;
	*)
		return 1
		;;
	esac
	return 0
}

set_time_range() {
	local pick n after_s before_s new_after new_before
	cat <<'EOF'
不写时间的话，ext4magic 只搜索最近 24 小时。
文件如果是更早删除的，必须把范围放宽，否则列表是空的。

  1) 最近 24 小时（程序默认）
  2) 最近 N 小时
  3) 最近 N 天
  4) 自定义起止
  5) 日志里能匹配到的全部时间
EOF
	prompt_var pick "选择" "1" || return 1
	case "$pick" in
	1)
		AFTER=""
		BEFORE=""
		TIME_LABEL="最近 24 小时（ext4magic 默认，不额外传时间）"
		;;
	2)
		prompt_var n "小时数" "6" || return 1
		[[ "$n" =~ ^[0-9]+$ && "$n" -gt 0 ]] || {
			echo "请填正整数。"
			return 1
		}
		AFTER="$(date -d "-$n hours" +%s)"
		BEFORE="$(date +%s)"
		TIME_LABEL="最近 ${n} 小时（$(date -d "@$AFTER" '+%F %T') 之后）"
		;;
	3)
		prompt_var n "天数" "3" || return 1
		[[ "$n" =~ ^[0-9]+$ && "$n" -gt 0 ]] || {
			echo "请填正整数。"
			return 1
		}
		AFTER="$(date -d "-$n days" +%s)"
		BEFORE="$(date +%s)"
		TIME_LABEL="最近 ${n} 天（$(date -d "@$AFTER" '+%F %T') 之后）"
		;;
	4)
		echo "时间写法交给 date -d，例如：2026-10-01 15:30    或    yesterday 18:00"
		prompt_var after_s "最早时间（删除之后）" || return 1
		prompt_var before_s "最晚时间（直接回车表示现在）" || return 1
		new_after="$(date -d "$after_s" +%s)" || {
			echo "无法解析最早时间。"
			return 1
		}
		if [[ -z "$before_s" ]]; then
			new_before="$(date +%s)"
		else
			new_before="$(date -d "$before_s" +%s)" || {
				echo "无法解析最晚时间。"
				return 1
			}
		fi
		if (( new_after >= new_before )); then
			echo "最早时间必须早于最晚时间。"
			return 1
		fi
		AFTER="$new_after"
		BEFORE="$new_before"
		TIME_LABEL="$(date -d "@$AFTER" '+%F %T')  →  $(date -d "@$BEFORE" '+%F %T')"
		;;
	5)
		AFTER=0
		BEFORE="$(date +%s)"
		TIME_LABEL="不限时间（1970 到现在，可能混进更旧的版本）"
		;;
	*)
		echo "没有这个选项。"
		return 1
		;;
	esac
	echo "时间范围：$TIME_LABEL"
}

normalize_relpath() {
	local input="$1" mp best=""
	input="${input%/}"
	if [[ "$input" == /* ]]; then
		for mp in "${MOUNT_TARGETS[@]}"; do
			if [[ "$input" == "$mp" || "$input" == "$mp"/* ]]; then
				if (( ${#mp} > ${#best} )); then
					best="$mp"
				fi
			fi
		done
		if [[ -n "$best" ]]; then
			input="${input#"$best"}"
		fi
		input="${input#/}"
	fi
	input="${input#/}"
	input="${input%/}"
	printf '%s' "$input"
}

relpath_ok() {
	local p="$1"
	[[ "$p" != ".." && "$p" != ../* && "$p" != */.. && "$p" != */../* ]]
}

set_relpath() {
	local raw
	need_device || return 1
	refresh_mount_state
	echo "路径相对于这个文件系统自己的根，不是系统根目录。"
	if [[ ${#MOUNT_TARGETS[@]} -gt 0 ]]; then
		echo "例如分区挂在 ${MOUNT_TARGETS[0]} ，要找 ${MOUNT_TARGETS[0]}/jessie/a.txt ，就填 jessie/a.txt"
		echo "也可以直接粘贴带挂载点的完整路径，脚本会把前缀去掉。"
	else
		echo "例如要找分区里的 home/jessie/a.txt ，就填 home/jessie/a.txt（不要加开头的 /）。"
	fi
	echo "直接回车表示整个文件系统。"
	prompt_var raw "目录或文件" || return 1
	if [[ -z "$raw" ]]; then
		RELPATH=""
		echo "范围：整个文件系统"
		return 0
	fi
	raw="$(normalize_relpath "$raw")"
	if [[ -z "$raw" ]]; then
		RELPATH=""
		echo "范围：整个文件系统"
		return 0
	fi
	if ! relpath_ok "$raw"; then
		echo "路径里不要写 .."
		return 1
	fi
	RELPATH="$raw"
	echo "范围：/$RELPATH"
}

set_outdir() {
	local dir fstype suggest created=0
	need_device || return 1
	suggest="$(suggest_dir 0)"
	if [[ -n "$suggest" ]]; then
		suggest="${suggest%/}/ext4magic-recover-$(date +%Y%m%d-%H%M%S)"
	fi
	echo "恢复出来的文件必须写到另一块文件系统。"
	echo "目标最好也是 ext4，这样原主、权限和时间能一起写回去。NTFS/exFAT 上这些属性会失败。"
	prompt_var dir "输出目录" "$suggest" || return 1
	[[ -n "$dir" ]] || return 1
	if same_fs_as_source "$dir"; then
		echo "这个目录在待恢复的文件系统上。写进去会覆盖还能抢救的数据。"
		return 1
	fi
	[[ -e "$dir" ]] || created=1
	mkdir -p -- "$dir" || return 1
	if same_fs_as_source "$dir"; then
		echo "这个目录在待恢复的文件系统上。"
		return 1
	fi
	fstype="$(findmnt -nro FSTYPE -T "$dir" 2>/dev/null || true)"
	case "$fstype" in
	tmpfs|devtmpfs)
		echo "这是内存盘，重启后文件就没了。请改到真实磁盘上。"
		[[ "$created" -eq 1 ]] && rmdir -- "$dir" 2>/dev/null || true
		return 1
		;;
	ext2|ext3|ext4) ;;
	"")
		echo "看不出文件系统类型，仍使用这个目录。"
		;;
	*)
		echo "目标文件系统是 $fstype。文件内容可以写出，属主和权限可能写不回去。"
		confirm "仍使用这个目录？" || return 1
		;;
	esac
	OUTDIR="$dir"
	echo "输出目录：$OUTDIR"
	df -h -- "$OUTDIR" | awk 'NR==1 || NR==2'
}

add_journal_and_time() {
	[[ -n "$JOURNAL" ]] && CMD+=(-j "$JOURNAL")
	[[ -n "$AFTER" ]] && CMD+=(-a "$AFTER")
	[[ -n "$BEFORE" ]] && CMD+=(-b "$BEFORE")
}

run_ext4magic() {
	local log status
	local saved
	print_cmd "${CMD[@]}"
	log="$(mktemp /tmp/ext4magic.XXXXXX.log)"
	echo "详细输出同时写入 $log"
	"${CMD[@]}" 2>&1 | tee "$log"
	status=${PIPESTATUS[0]}
	echo
	if [[ "$status" -ne 0 ]]; then
		echo "ext4magic 退出码：$status"
	fi
	saved="$(grep -c '^--------' "$log" || true)"
	if [[ "$saved" =~ ^[0-9]+$ && "$saved" -gt 0 ]]; then
		echo "成功写出的条目：$saved（行首 -------- 表示这一条写成功了）"
	fi
	if grep -q 'while opening filesystem' "$log"; then
		echo "ext4magic 没能打开这个文件系统。分区请选具体的 ext4 分区；镜像文件需要是完整的未压缩镜像。"
	fi
	if grep -q '^xxxxx' "$log"; then
		echo "有些条目没写成功（行首是 xxxxx），多半是输出目录不允许保留原属主或权限。"
	fi
	return "$status"
}

run_info() {
	need_device || return 1
	ensure_journal_access || return 1
	echo "---- 超级块 ----"
	CMD=(ext4magic -S)
	add_journal_and_time
	CMD+=("$DEVICE")
	run_ext4magic || true
	echo "---- 日志超级块 ----"
	CMD=(ext4magic -J)
	add_journal_and_time
	CMD+=("$DEVICE")
	run_ext4magic || true
}

run_hist() {
	need_device || return 1
	ensure_journal_access || return 1
	CMD=(ext4magic -H -x)
	add_journal_and_time
	[[ -n "$RELPATH" ]] && CMD+=(-f "$RELPATH")
	CMD+=("$DEVICE")
	echo "直方图用来看哪个时间段有大量 inode 变化，便于把删除时间收窄。"
	run_ext4magic || true
}

list_deleted() {
	local log pick kw filtered edited count lines status
	need_device || return 1
	warn_journal_limit || return 1
	ensure_journal_access || return 1
	CMD=(ext4magic -l -x)
	add_journal_and_time
	[[ -n "$RELPATH" ]] && CMD+=(-f "$RELPATH")
	CMD+=("$DEVICE")
	print_cmd "${CMD[@]}"
	log="$(mktemp /tmp/ext4magic-list.XXXXXX.txt)"
	echo "正在扫描日志。范围大、分区大时会久一些，扫完才有列表。"
	"${CMD[@]}" >"$log" 2>&1
	status=$?
	echo
	if [[ "$status" -ne 0 ]]; then
		echo "ext4magic 退出码：$status"
		tail -n 20 -- "$log"
	fi
	count="$(grep -c '"' "$log" || true)"
	lines="$(wc -l < "$log")"
	lines="${lines//[[:space:]]/}"
	echo "带引号的文件名大约 $count 条，共 $lines 行。完整列表：$log"
	if [[ "$lines" =~ ^[0-9]+$ ]] && (( lines > 40 )); then
		echo "列表较长，这里只显示最后 30 行："
		tail -n 30 -- "$log"
		confirm "用 less 查看全部？" && less -- "$log"
	else
		cat -- "$log"
	fi
	echo "行首百分比是还没被占用的数据块比例。100% 表示内容块还空着，最有希望。"
	echo
	echo "  1) 回到菜单"
	echo "  2) 按这份清单恢复"
	echo "  3) 用关键字筛过再恢复"
	echo "  4) 用编辑器改过再恢复"
	prompt_var pick "选择" "1" || return 0
	filtered="$log"
	case "$pick" in
	1) return 0 ;;
	3)
		prompt_var kw "关键字（按字面匹配）" || return 0
		filtered="$(mktemp /tmp/ext4magic-list.XXXXXX.txt)"
		grep -F -- "$kw" "$log" >"$filtered" || true
		count="$(wc -l < "$filtered")"
		count="${count//[[:space:]]/}"
		echo "匹配 $count 行。写入 $filtered"
		[[ "$count" -gt 0 ]] || return 0
		;;
	4)
		edited="$(mktemp /tmp/ext4magic-list.XXXXXX.txt)"
		cp -- "$log" "$edited"
		if [[ -n "${EDITOR:-}" ]]; then
			# EDITOR 可能带参数，例如 "nano -L"。
			# shellcheck disable=SC2086
			$EDITOR "$edited" || true
		elif command -v nano >/dev/null 2>&1; then
			nano "$edited" || true
		else
			vi "$edited" || true
		fi
		filtered="$edited"
		;;
	2) ;;
	*)
		echo "没有这个选项。"
		return 0
		;;
	esac
	[[ -s "$filtered" ]] || {
		echo "清单是空的。"
		return 0
	}
	echo "ext4magic 会忽略没有用双引号括起来的行，所以概况信息留在清单里也没关系。"
	recover_from_list "$filtered"
}

ensure_outdir() {
	if [[ -n "$OUTDIR" && -d "$OUTDIR" ]]; then
		if same_fs_as_source "$OUTDIR"; then
			echo "输出目录在源文件系统上，已取消。"
			OUTDIR=""
			return 1
		fi
		return 0
	fi
	echo "还没有可用的输出目录。"
	set_outdir
}

recover_from_list() {
	local list="$1"
	ensure_journal_access || return 1
	ensure_outdir || return 1
	CMD=(ext4magic -r)
	[[ "$USE_Q" -eq 1 ]] && CMD+=(-Q)
	add_journal_and_time
	CMD+=(-i "$list" -d "$OUTDIR" "$DEVICE")
	echo "将按清单恢复到 $OUTDIR"
	echo "已有同名文件时，ext4magic 会在文件名末尾加 #，不会覆盖。"
	confirm "开始恢复？" || return 1
	run_ext4magic || true
	report_recover_result
}

report_recover_result() {
	echo "请到输出目录抽查文件内容。数据块若已被重新使用，文件能写出来但内容是坏的。"
	echo "输出目录：$OUTDIR"
	if [[ -d "$OUTDIR" ]]; then
		echo "当前文件数：$(find "$OUTDIR" -type f 2>/dev/null | wc -l)"
	fi
}

run_recover() {
	local mode="$1"
	need_device || return 1
	warn_journal_limit || return 1
	ensure_journal_access || return 1
	ensure_outdir || return 1
	CMD=(ext4magic)
	case "$mode" in
	safe)
		CMD+=(-r)
		[[ "$USE_Q" -eq 1 ]] && CMD+=(-Q)
		echo "只恢复数据块还没被占用的已删除文件，并尽量保留原文件名。"
		;;
	force)
		CMD+=(-R)
		[[ "$USE_Q" -eq 1 ]] && CMD+=(-Q)
		echo "这会把时间范围内匹配到的版本都写出来，包括数据块已经被占用的。"
		echo "其中会有未删除的文件，也会有内容已经损坏的旧版本。"
		;;
	*)
		echo "未知恢复模式。"
		return 1
		;;
	esac
	add_journal_and_time
	[[ -n "$RELPATH" ]] && CMD+=(-f "$RELPATH")
	CMD+=(-d "$OUTDIR" "$DEVICE")
	echo "输出目录：$OUTDIR"
	echo "时间范围：$TIME_LABEL"
	confirm "开始恢复？" || return 1
	run_ext4magic || true
	report_recover_result
}

run_magic() {
	local pick
	need_device || return 1
	warn_journal_limit || return 1
	ensure_journal_access || return 1
	ensure_outdir || return 1
	echo "多阶段恢复用来对付「整目录或整盘被 rm -rf」的情况。它扫描整个文件系统，忽略菜单里限定的子目录。"
	echo "删除如果已经超过几分钟，需要设置时间范围里的最早时间，否则可能什么都找不到。"
	echo "  1) 只恢复已删除文件（-m）"
	echo "  2) 文件系统上的文件都被删了（-M）"
	echo "  0) 取消"
	prompt_var pick "选择" "1" || return 1
	case "$pick" in
	1) CMD=(ext4magic -m) ;;
	2) CMD=(ext4magic -M) ;;
	*) return 1 ;;
	esac
	[[ -n "$JOURNAL" ]] && CMD+=(-j "$JOURNAL")
	[[ -n "$AFTER" ]] && CMD+=(-a "$AFTER")
	CMD+=(-d "$OUTDIR" "$DEVICE")
	echo "时间范围：$TIME_LABEL"
	echo "输出目录：$OUTDIR"
	confirm "开始多阶段恢复？这一步可能很久。" || return 1
	run_ext4magic || true
	report_recover_result
	echo "对不上原文件名的内容会放在输出目录的 MAGIC-1、MAGIC-2 里。"
}

run_photorec() {
	need_device || return 1
	if ! command -v photorec >/dev/null 2>&1; then
		echo "photorec 在 testdisk 包里，同样来自 Debian 软件仓库。"
		confirm "现在安装 testdisk？" || return 1
		apt-get install -y testdisk || {
			echo "安装失败。"
			return 1
		}
	fi
	ensure_outdir || return 1
	echo "photorec 不看文件名，只按文件头把内容抠出来，目录结构不会保留。"
	echo "它会把分区从头扫到尾，时间和分区大小成正比。"
	echo "输出目录：$OUTDIR"
	confirm "启动 photorec？" || return 1
	photorec /log /d "$OUTDIR" "$DEVICE"
}

usage() {
	cat <<EOF
用法: $(basename "$0") [设备或镜像文件]

交互菜单会引导你：
  选择 ext3/ext4 分区，设置删除时间，把文件恢复到另一块盘。

依赖（都在 Debian 软件仓库里）：
  ext4magic    从旧式日志恢复原文件名。checksum v3 日志上基本无效
  e2fsprogs    提供 debugfs，用来查看日志格式、在分区仍挂载时复制日志
  testdisk     可选，提供 photorec。Debian 13 默认 ext4 上靠它取出文件内容

不要把输出目录放在待恢复的分区上，恢复前不要对它运行 fsck。
EOF
}

main() {
	local choice
	if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
		usage
		exit 0
	fi
	if [[ "$(id -u)" -ne 0 ]]; then
		local script
		local -a env_lang=()
		echo "读块设备需要 root，改用 sudo 重新执行。"
		script="$(readlink -f -- "$0")"
		[[ -n "${LANG:-}" ]] && env_lang+=("LANG=$LANG")
		[[ -n "${LC_ALL:-}" ]] && env_lang+=("LC_ALL=$LC_ALL")
		if [[ ${#env_lang[@]} -eq 0 ]]; then
			exec sudo -- bash "$script" "$@" || die "sudo 执行失败。"
		fi
		exec sudo -- env "${env_lang[@]}" bash "$script" "$@" || die "sudo 执行失败。"
	fi
	check_deps
	cd /
	if [[ "${EXT4MAGIC_RELOCATED:-}" != "1" ]]; then
		echo "ext4magic 能在旧式日志里找回原文件名。Debian 13 默认的 ext4 日志带 checksum v3，这个版本读不出来。"
		echo "读不出来时用菜单里的 photorec（apt 包 testdisk）抠文件内容。先停止往这块盘写数据，也不要先跑 fsck。"
	fi
	if [[ -n "${1:-}" ]]; then
		set_device "$1" || exit 1
	fi
	while true; do
		print_status
		print_menu
		read -r -p "请选择: " choice || exit 0
		case "$choice" in
		1) choose_device || true ;;
		2) try_unmount_or_readonly || true ;;
		3) dump_journal || true ;;
		4) set_time_range || true ;;
		5) set_relpath || true ;;
		6) set_outdir || true ;;
		7)
			if [[ "$USE_Q" -eq 1 ]]; then
				USE_Q=0
				echo "已关闭 -Q。"
			else
				USE_Q=1
				echo "已打开 -Q。它更挑目录日志，能减少错文件，找不到目录旧数据时会漏文件。"
			fi
			;;
		8) run_info || true ;;
		9) run_hist || true ;;
		10) list_deleted || true ;;
		11) run_recover safe || true ;;
		12) run_recover force || true ;;
		13) run_magic || true ;;
		14) run_photorec || true ;;
		0|q|Q) exit 0 ;;
		"") ;;
		*) echo "没有这个选项。" ;;
		esac
	done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	main "$@"
fi

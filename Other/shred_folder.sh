#!/usr/bin/env bash
# 覆盖某个文件夹里的文件内容后再删除，降低误删后被工具找回的可能。
# 依赖：coreutils 的 shred、find（Debian 默认就有）。
#
# 用法：
#   ./shred_folder.sh
#   ./shred_folder.sh /path/to/dir
#
# 机械硬盘上多次覆盖更有意义。SSD、Btrfs、网络盘、内存盘上，覆盖往往挡不住专业恢复。
set -u

PASSES=""
TARGET=""
FILE_COUNT=0
DIR_COUNT=0
LINK_COUNT=0
OTHER_COUNT=0
TOTAL_BYTES=0

die() {
	printf '错误: %s\n' "$*" >&2
	exit 1
}

confirm() {
	local reply
	read -r -p "$1 [y/N]: " reply || return 1
	[[ "$reply" == [yY] ]]
}

usage() {
	cat <<EOF
用法: $(basename "$0") [文件夹]

会先扫描并显示进度，再要求两次确认（第二次必须原样输入路径）。
普通文件用 shred 覆盖后删除；符号链接只删链接本身，不碰指向的目标。
覆盖遍数可用环境变量覆盖，例如：SHRED_PASSES=1 ./shred_folder.sh ./a
EOF
}

is_dangerous_path() {
	local p="$1"
	case "$p" in
	/|/boot|/boot/*|/usr|/usr/*|/etc|/etc/*|/bin|/sbin|/lib|/lib32|/lib64|/lib/*|/proc|/proc/*|/sys|/sys/*|/dev|/dev/*|/run|/run/*|/var|/var/log|/var/log/*)
		return 0
		;;
	esac
	return 1
}

fs_of() {
	findmnt -nro FSTYPE -T "$1" 2>/dev/null || true
}

rota_of() {
	local src name
	src="$(findmnt -nro SOURCE -T "$1" 2>/dev/null || true)"
	[[ -n "$src" ]] || return 1
	name="$(lsblk -nro PKNAME -- "$src" 2>/dev/null | head -n1)"
	if [[ -z "$name" ]]; then
		lsblk -nro ROTA -- "$src" 2>/dev/null | head -n1
		return
	fi
	lsblk -nro ROTA "/dev/$name" 2>/dev/null | head -n1
}

choose_passes() {
	local fstype rota
	fstype="$(fs_of "$TARGET")"
	rota="$(rota_of "$TARGET" || true)"
	echo "文件系统：$fstype"
	case "$fstype" in
	tmpfs|devtmpfs)
		echo "这是内存盘。覆盖对恢复帮助很小，主要是删掉。"
		PASSES=1
		;;
	nfs|nfs4|cifs|fuse.sshfs|fuse.rclone)
		echo "这是网络盘。覆盖发生在本机缓存或对端，防恢复效果不可靠。"
		PASSES=1
		;;
	ntfs|ntfs3|fuseblk)
		echo "这是 NTFS。覆盖能改文件内容，但主文件表（MFT）里的名字/记录不一定清得掉。"
		if [[ "$rota" == "0" ]]; then
			echo "底层像是 SSD，只覆盖 1 遍再删除。"
			PASSES=1
		else
			echo "底层像是机械盘。默认覆盖 3 遍再填零，每个文件实际要写 4 遍，大目录会很久。"
			PASSES=3
		fi
		;;
	btrfs|bcachefs|zfs|f2fs)
		echo "这是写时复制或闪存友好文件系统。旧数据块多半还在，多次覆盖意义不大。"
		PASSES=1
		;;
	*)
		if [[ "$rota" == "0" ]]; then
			echo "底层像是 SSD（非旋转盘）。闪存磨损均衡会让多次覆盖几乎没用，只覆盖 1 遍再删除。"
			PASSES=1
		else
			echo "底层像是机械盘。默认覆盖 3 遍再填零，每个文件实际要写 4 遍，大目录会很久。"
			PASSES=3
		fi
		;;
	esac
	if [[ -n "${SHRED_PASSES:-}" ]]; then
		[[ "$SHRED_PASSES" =~ ^[1-9][0-9]*$ ]] || die "SHRED_PASSES 必须是正整数。"
		PASSES="$SHRED_PASSES"
		echo "已按环境变量 SHRED_PASSES=$PASSES 覆盖遍数。"
	fi
}

human_bytes() {
	local n="${1:-0}"
	if [[ ! "$n" =~ ^[0-9]+$ ]]; then
		printf '?'
		return
	fi
	if (( n >= 1099511627776 )); then
		printf '%sT' "$((n / 1099511627776))"
	elif (( n >= 1073741824 )); then
		printf '%sG' "$((n / 1073741824))"
	elif (( n >= 1048576 )); then
		printf '%sM' "$((n / 1048576))"
	elif (( n >= 1024 )); then
		printf '%sK' "$((n / 1024))"
	else
		printf '%sB' "$n"
	fi
}

resolve_target() {
	local input="$1"
	[[ -n "$input" ]] || die "没有给出文件夹。"
	[[ -e "$input" ]] || die "路径不存在：$input"
	[[ -d "$input" ]] || die "这不是文件夹：$input"
	[[ -L "$input" ]] && die "这是符号链接。请给出真实文件夹，避免误粉碎链接指向的位置。"
	TARGET="$(readlink -f -- "$input")"
	[[ -n "$TARGET" && -d "$TARGET" ]] || die "无法解析路径。"
	[[ "$TARGET" == "/" ]] && die "拒绝粉碎根目录。"
	if is_dangerous_path "$TARGET"; then
		die "拒绝粉碎系统目录：$TARGET"
	fi
	if [[ "$TARGET" == "$HOME" ]]; then
		echo "这是当前用户的家目录。粉碎会清掉几乎全部个人文件。"
		confirm "仍然继续选择这个目录？" || exit 1
	fi
}

scan_tree() {
	local y sz seen=0
	FILE_COUNT=0
	DIR_COUNT=0
	LINK_COUNT=0
	OTHER_COUNT=0
	TOTAL_BYTES=0
	echo "正在扫描目录（只走一遍）。文件很多时会在这里停一会儿，下面会刷计数。"
	while IFS=' ' read -r y sz; do
		[[ -n "$y" ]] || continue
		case "$y" in
		f)
			FILE_COUNT=$((FILE_COUNT + 1))
			[[ "$sz" =~ ^[0-9]+$ ]] && TOTAL_BYTES=$((TOTAL_BYTES + sz))
			;;
		d) DIR_COUNT=$((DIR_COUNT + 1)) ;;
		l) LINK_COUNT=$((LINK_COUNT + 1)) ;;
		*) OTHER_COUNT=$((OTHER_COUNT + 1)) ;;
		esac
		seen=$((FILE_COUNT + DIR_COUNT + LINK_COUNT + OTHER_COUNT))
		if (( seen % 200 == 0 )); then
			printf '\r已看到 %s 个文件、%s 个目录\033[K' "$FILE_COUNT" "$DIR_COUNT"
		fi
	done < <(find -P "$TARGET" -printf '%y %s\n')
	printf '\r扫描完成：%s 个文件、%s 个目录\033[K\n' "$FILE_COUNT" "$DIR_COUNT"
}

print_plan() {
	local write_bytes
	scan_tree
	write_bytes=$((TOTAL_BYTES * (PASSES + 1)))
	echo
	echo "======== 即将粉碎 ========"
	echo "路径    $TARGET"
	echo "普通文件 $FILE_COUNT"
	echo "子目录   $DIR_COUNT"
	echo "符号链接 $LINK_COUNT（只删链接，不覆盖目标）"
	echo "其他节点 $OTHER_COUNT（管道/套接字等，只删除）"
	echo "当前占用 $(human_bytes "$TOTAL_BYTES")"
	echo "覆盖遍数 $PASSES（外加 1 遍填零，大约要写入 $(human_bytes "$write_bytes")）"
	echo "=========================="
}

ask_confirm() {
	local typed
	echo
	echo "此操作不可撤销。覆盖完成后文件就没了。"
	confirm "确定粉碎这个文件夹？" || {
		echo "已取消。"
		exit 0
	}
	read -r -p "请再输入一遍完整路径以确认: " typed || exit 1
	local resolved=""
	if [[ -n "$typed" ]]; then
		resolved="$(readlink -f -- "$typed" 2>/dev/null || true)"
	fi
	if [[ "$typed" != "$TARGET" && "$resolved" != "$TARGET" ]]; then
		die "路径对不上，已取消。"
	fi
}

unlock_files() {
	echo "正在去掉只读属性……"
	find -P "$TARGET" -type f ! -writable -exec chmod u+w -- {} + 2>/dev/null || true
}

shred_files() {
	local fail=0 n=0 f rel sz
	local total="$FILE_COUNT"
	[[ "$total" =~ ^[0-9]+$ ]] || total=0
	if [[ "$total" -eq 0 ]]; then
		echo "没有普通文件，跳过覆盖。"
		return 0
	fi
	echo "开始覆盖（进度按文件个数，大文件会在同一行停很久）……"
	# -n 覆盖遍数；-z 最后填零；-u 覆盖后删除。
	while IFS= read -r -d '' f; do
		n=$((n + 1))
		rel="${f#"$TARGET"/}"
		sz="$(stat -c '%s' -- "$f" 2>/dev/null || echo 0)"
		printf '\r[%s/%s] %s (%s)\033[K' "$n" "$total" "$rel" "$(human_bytes "$sz")"
		if ! shred -n "$PASSES" -z -u -- "$f"; then
			printf '\n粉碎失败：%s\n' "$f"
			fail=1
		fi
	done < <(find -P "$TARGET" -type f -print0)
	printf '\n'
	return "$fail"
}

remove_nonfiles() {
	# 符号链接、设备、管道、套接字：不能当普通文件覆盖。
	find -P "$TARGET" \( -type l -o -type p -o -type s -o -type b -o -type c \) -delete 2>/dev/null || true
	# 从最深一层开始拆目录。
	find -P "$TARGET" -depth -type d -exec rmdir --ignore-fail-on-non-empty -- {} + 2>/dev/null || true
	if [[ -d "$TARGET" ]]; then
		rmdir -- "$TARGET" 2>/dev/null || true
	fi
}

has_leftovers() {
	if [[ -e "$TARGET" ]]; then
		echo "还有没删干净的内容："
		find -P "$TARGET" | head -n 50
		return 0
	fi
	return 1
}

main() {
	if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
		usage
		exit 0
	fi
	command -v shred >/dev/null 2>&1 || die "找不到 shred。请安装 coreutils。"
	local input="${1:-}"
	if [[ -z "$input" ]]; then
		read -r -p "要粉碎的文件夹: " input || exit 1
	fi
	resolve_target "$input"
	cd /
	choose_passes
	print_plan
	ask_confirm
	echo "开始粉碎。"
	unlock_files
	local status=0
	shred_files || status=1
	remove_nonfiles
	sync
	if has_leftovers; then
		echo "粉碎未完成，上面这些还在。"
		exit 1
	fi
	if [[ "$status" -ne 0 ]]; then
		echo "部分文件覆盖失败，但目录已尽量清掉。请核对。"
		exit 1
	fi
	echo "已粉碎：$TARGET"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	main "$@"
fi

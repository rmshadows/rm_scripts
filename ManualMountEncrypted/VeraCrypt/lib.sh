#!/bin/bash
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/Profile.sh"
if [ "$?" -ne 0 ]; then
    echo -e "\033[0;31m Source Profile.sh: An error occurred and exited. \033[0m"
    exit 1
fi
source "$LIB_DIR/config.sh"
if [ "$?" -ne 0 ]; then
    echo -e "\033[0;31m Source config.sh: An error occurred and exited. \033[0m"
    exit 1
fi

VERACRYPT_BIN=""
VOLUME_PATH=""
VC_CRYPTO_ARGS=()
# veracrypt | tcplay。Debian 官方源通常没有 veracrypt，可改用 tcplay。
VC_BACKEND=""
TCPLAY_BIN=""
TCPLAY_MAP=""
TCPLAY_LOOP=""
# 已打开的 VeraCrypt 槽：映射设备，以及文件系统真正挂上的目录（未挂则为空）
VC_SLOT_DEV=""
VC_SLOT_MP=""

# 源里真有这个包（本机 dpkg 残留不算）
apt_repo_has() {
    apt-cache madison "$1" 2>/dev/null | grep -q .
}

find_tcplay_bin() {
    if command -v tcplay >/dev/null 2>&1; then
        command -v tcplay
        return 0
    fi
    if [ -x /usr/sbin/tcplay ]; then
        printf '%s\n' /usr/sbin/tcplay
        return 0
    fi
    return 1
}

tcplay_map_name() {
    local raw="${mountName:-rveracrypt}"
    raw="$(printf '%s' "$raw" | tr -c 'A-Za-z0-9_-' '_')"
    [ -n "$raw" ] || raw="rveracrypt"
    TCPLAY_MAP="$raw"
}

check_mount_point() {
    # 必须用 --mountpoint；--target 会对普通目录误报父挂载
    findmnt -n --mountpoint "$1" >/dev/null 2>&1
}

use_veracrypt_bin() {
    VERACRYPT_BIN="$1"
    VC_BACKEND="veracrypt"
    prompt -i "使用 veracrypt: $VERACRYPT_BIN"
}

use_tcplay_bin() {
    TCPLAY_BIN="$1"
    VC_BACKEND="tcplay"
    tcplay_map_name
    prompt -i "使用 tcplay: $TCPLAY_BIN（映射 /dev/mapper/$TCPLAY_MAP）"
}

# 官方源没有 veracrypt 时询问。返回 0 表示已改用 tcplay。
offer_tcplay_backend() {
    local choice bin=""
    bin="$(find_tcplay_bin || true)"
    if [ -z "$bin" ] && ! apt_repo_has tcplay; then
        prompt -e "找不到 veracrypt，apt 源里也没有 tcplay。"
        prompt -i "请从 https://www.veracrypt.fr/en/Downloads.html 安装 .deb，或在 config.sh 设置 VERACRYPT_CUSTOM。"
        return 1
    fi

    prompt -w "找不到 veracrypt，且当前 apt 源没有这个包（Debian 官方通常不收）。"
    prompt -i "可改用 tcplay：能开多数 PIM=0 的 VeraCrypt / TrueCrypt 卷，解密后仍用本脚本挂文件系统。"
    prompt -w "限制：不支持自定义 PIM；隐藏卷、系统分区加密、个别算法可能打不开。容器文件会先 losetup。"
    if [ ! -r /dev/tty ] && [ ! -t 0 ]; then
        prompt -e "没有终端，不能询问。请安装 veracrypt，或在终端里重跑。"
        return 1
    fi
    comfirmy "\e[1;33m 改用 tcplay 解密？ [Y/n]\e[0m"
    choice=$?
    if [ "$choice" -ne 1 ]; then
        prompt -i "已取消。安装 veracrypt 后可再跑。"
        return 1
    fi
    if [ -z "$bin" ]; then
        prompt -x "apt install tcplay"
        if ! sudo apt install tcplay -y; then
            prompt -e "tcplay 安装失败。"
            return 1
        fi
        bin="$(find_tcplay_bin || true)"
    fi
    if [ -z "$bin" ] || [ ! -x "$bin" ]; then
        prompt -e "装完仍找不到 tcplay。"
        return 1
    fi
    use_tcplay_bin "$bin"
    return 0
}

resolve_veracrypt_bin() {
    if [ "${VC_BACKEND:-}" = "tcplay" ] && [ -n "${TCPLAY_BIN:-}" ] && [ -x "$TCPLAY_BIN" ]; then
        return 0
    fi
    if [ "${VC_BACKEND:-}" = "veracrypt" ] && [ -n "${VERACRYPT_BIN:-}" ] && [ -x "$VERACRYPT_BIN" ]; then
        return 0
    fi

    local custom="$VERACRYPT_CUSTOM"

    # 相对路径：打包二进制按其所在目录；否则按脚本目录。
    if [ -n "$custom" ] && [[ "$custom" != /* ]]; then
        if [ -n "${PACK_BIN_DIR:-}" ]; then
            custom="$PACK_BIN_DIR/$custom"
        else
            custom="$LIB_DIR/$custom"
        fi
    fi

    if [ -n "${VERACRYPT_CUSTOM:-}" ]; then
        if [ -x "$custom" ]; then
            use_veracrypt_bin "$custom"
            return 0
        fi
        prompt -e "VERACRYPT_CUSTOM 不可执行: ${VERACRYPT_CUSTOM}"
        prompt -i "可用 Other/apt/collect_binary_with_deps.sh 打包离线 veracrypt，再指向该目录下的启动脚本。"
        return 1
    fi

    if command -v veracrypt >/dev/null 2>&1; then
        use_veracrypt_bin "$(command -v veracrypt)"
        return 0
    fi

    # 上次用 tcplay 留下的映射还在：直接沿用，不再问一遍。
    tcplay_map_name
    if [ -e "/dev/mapper/$TCPLAY_MAP" ]; then
        local existing
        existing="$(find_tcplay_bin || true)"
        if [ -n "$existing" ]; then
            use_tcplay_bin "$existing"
            return 0
        fi
    fi

    if apt_repo_has veracrypt; then
        prompt -w "未找到 veracrypt，尝试 apt install..."
        if sudo apt install veracrypt -y; then
            if command -v veracrypt >/dev/null 2>&1; then
                use_veracrypt_bin "$(command -v veracrypt)"
                return 0
            fi
        fi
    else
        prompt -w "apt 源里没有 veracrypt，不尝试安装。"
    fi

    offer_tcplay_backend
    return $?
}

resolve_volume() {
    local quiet="${1:-}"
    if [ "$volMode" -eq 1 ]; then
        if [ -z "$containerPath" ] || [ ! -f "$containerPath" ]; then
            prompt -e "容器文件不存在: ${containerPath:-<空>}"
            return 1
        fi
        VOLUME_PATH="$containerPath"
        if [ "$quiet" != "quiet" ]; then
            prompt -k "容器" "$VOLUME_PATH"
        fi
        return 0
    fi
    if [ "$volMode" -ne 0 ]; then
        prompt -e "volMode 只能是 0（分区）或 1（容器文件），当前是 $volMode。"
        return 1
    fi
    if [ -z "$puid" ]; then
        if [ "$quiet" != "quiet" ]; then
            prompt -e "请先在 config.sh 里填写 VeraCrypt 分区的 PARTUUID（puid）。"
            prompt -i "查看命令: lsblk -o NAME,PARTUUID,SIZE,FSTYPE,TYPE"
        fi
        return 1
    fi

    local by_partuuid="/dev/disk/by-partuuid/$puid"
    if [ ! -e "$by_partuuid" ]; then
        if [ "$quiet" != "quiet" ]; then
            prompt -e "找不到分区: $by_partuuid"
            prompt -i "查看命令: lsblk -o NAME,PARTUUID,SIZE,FSTYPE,TYPE"
        fi
        return 1
    fi
    VOLUME_PATH="$(readlink -f "$by_partuuid")"
    if [ "$quiet" != "quiet" ]; then
        prompt -k "磁盘" "$VOLUME_PATH"
    fi
    return 0
}

ensure_mount_dir() {
    local dir="$1"
    local owner="${_MEDIA_USER:-${SUDO_USER:-${USER:-$(id -un)}}}"

    # /media/用户名/ 下的目录尽量归用户，Nautilus 才好认。
    if [[ "$dir" == /media/"$owner"/* ]]; then
        if [ ! -d "/media/$owner" ]; then
            prompt -x "mkdir /media/$owner"
            sudo mkdir -p "/media/$owner" || return 1
            sudo chown "$owner:$owner" "/media/$owner" || return 1
        fi
    fi

    if [ ! -d "$dir" ]; then
        prompt -x "mkdir $dir"
        sudo mkdir -p "$dir" || return 1
        if [[ "$dir" == /media/"$owner"/* ]]; then
            sudo chown "$owner:$owner" "$dir" || return 1
        fi
        return 0
    fi
    if [ -n "$(sudo ls -A "$dir" 2>/dev/null)" ]; then
        prompt -e "挂载点 $dir 非空。"
        sudo ls -la "$dir"
        comfirmn "\e[1;33m 是否清空 $dir ？此操作不可恢复 [y/N]\e[0m"
        choice=$?
        if [ "$choice" -eq 1 ]; then
            prompt -x "清空挂载点 $dir ..."
            sudo rm -rf "$dir" || return 1
            prompt -x "mkdir $dir"
            sudo mkdir -p "$dir" || return 1
            if [[ "$dir" == /media/"$owner"/* ]]; then
                sudo chown "$owner:$owner" "$dir" || return 1
            fi
        elif [ "$choice" -eq 2 ]; then
            prompt -w "已取消。"
            return 1
        else
            prompt -e "未知选项。"
            return 1
        fi
    elif [[ "$dir" == /media/"$owner"/* ]]; then
        sudo chown "$owner:$owner" "$dir" 2>/dev/null || true
    fi
    return 0
}

# 组装解密参数（不含 filesystem / fs-options / 挂载点）。
build_vc_crypto_args() {
    if [ "${VC_BACKEND:-}" = "tcplay" ]; then
        return 0
    fi
    VC_CRYPTO_ARGS=(--text --protect-hidden=no --pim="$pim")
    if [ -n "$keyFile" ]; then
        VC_CRYPTO_ARGS+=(--keyfiles="$keyFile")
    else
        VC_CRYPTO_ARGS+=(-k "")
    fi
    if [ "$truecryptMode" -eq 1 ]; then
        if ! "$VERACRYPT_BIN" --text --help 2>&1 | grep -q -- '--truecrypt'; then
            prompt -e "当前 veracrypt 没有 --truecrypt。1.26 起已去掉 TrueCrypt 卷兼容。"
            return 1
        fi
        VC_CRYPTO_ARGS+=(--truecrypt)
    fi
    if [ "$readOnly" -eq 1 ]; then
        VC_CRYPTO_ARGS+=(--mount-options=ro)
    fi
    if [ -n "${keyPass:-}" ]; then
        VC_CRYPTO_ARGS+=(--non-interactive --password="$keyPass")
    fi
    return 0
}

get_veracrypt_mapped_device() {
    local vol="$1" line dev
    if [ "${VC_BACKEND:-}" = "tcplay" ]; then
        tcplay_map_name
        if [ -e "/dev/mapper/$TCPLAY_MAP" ]; then
            printf '%s\n' "/dev/mapper/$TCPLAY_MAP"
            return 0
        fi
        return 1
    fi
    # 短列表形如 "1: /dev/sdb4 /dev/mapper/veracrypt1 -"
    # 第一个 /dev 是加密分区本身，不能拿去 mount。
    line="$(sudo "$VERACRYPT_BIN" --text --verbose --list "$vol" 2>/dev/null || true)"
    if [ -z "$line" ]; then
        line="$(sudo "$VERACRYPT_BIN" --text --verbose --list 2>/dev/null || true)"
    fi
    dev="$(printf '%s\n' "$line" | awk -F': ' '/^Virtual Device:/ { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit }')"
    if [ -n "$dev" ] && [ "$dev" != "$vol" ] && [ -e "$dev" ]; then
        printf '%s\n' "$dev"
        return 0
    fi
    dev="$(printf '%s\n' "$line" | grep -oE '/dev/mapper/veracrypt[0-9]+' | head -n 1)"
    if [ -n "$dev" ] && [ -e "$dev" ]; then
        printf '%s\n' "$dev"
        return 0
    fi
    return 1
}

# 容器文件没有块设备，tcplay 要先挂到 loop。
tcplay_ensure_block() {
    local loop=""
    if [ "${volMode:-0}" -ne 1 ]; then
        printf '%s\n' "$VOLUME_PATH"
        return 0
    fi
    loop="$(sudo losetup -j "$VOLUME_PATH" 2>/dev/null | head -n 1 | cut -d: -f1 || true)"
    if [ -z "$loop" ]; then
        prompt -x "losetup $VOLUME_PATH"
        loop="$(sudo losetup -f --show "$VOLUME_PATH")" || return 1
        TCPLAY_LOOP="$loop"
    fi
    printf '%s\n' "$loop"
}

tcplay_release_loop() {
    local loop=""
    [ "${volMode:-0}" -eq 1 ] || return 1
    [ -n "$VOLUME_PATH" ] || return 1
    loop="$(sudo losetup -j "$VOLUME_PATH" 2>/dev/null | head -n 1 | cut -d: -f1 || true)"
    [ -n "$loop" ] || return 1
    sudo losetup -d "$loop"
    TCPLAY_LOOP=""
    return 0
}

open_crypto_slot() {
    local dev args=()
    if [ "${VC_BACKEND:-}" != "tcplay" ]; then
        sudo "$VERACRYPT_BIN" "${VC_CRYPTO_ARGS[@]}" --filesystem=none "$VOLUME_PATH"
        return $?
    fi
    if [ "${pim:-0}" -ne 0 ]; then
        prompt -e "tcplay 不能指定 PIM=$pim（只支持默认迭代）。请安装 veracrypt，或把 config.sh 里 pim 设为 0。"
        return 1
    fi
    tcplay_map_name
    dev="$(tcplay_ensure_block)" || return 1
    args=(--map="$TCPLAY_MAP" --device="$dev")
    if [ -n "${keyFile:-}" ]; then
        args+=(--keyfile="$keyFile" --prompt-passphrase)
    fi
    if [ -n "${keyPass:-}" ]; then
        prompt -w "tcplay 不读 config.sh 里的 keyPass，请在它自己的提示里再输入一次密码。"
    fi
    prompt -x "tcplay --map=$TCPLAY_MAP --device=$dev"
    if ! sudo "$TCPLAY_BIN" "${args[@]}"; then
        tcplay_release_loop || true
        return 1
    fi
    return 0
}

fs_needs_owner_options() {
    local fstype
    fstype="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
    case "$fstype" in
        ntfs|fuseblk|vfat|fat|fat12|fat16|fat32|exfat|msdos) return 0 ;;
        *) return 1 ;;
    esac
}

# 只在用户明确选择 chown-root 时使用。会把卷根属主写进卷里，不递归。
fix_native_fs_root_owner() {
    local mp="$1"
    local owner uid gid

    [ "${readOnly:-0}" -eq 1 ] && return 0

    owner="${_MEDIA_USER:-${SUDO_USER:-${USER:-$(id -un)}}}"
    if ! uid="$(id -u "$owner" 2>/dev/null)"; then
        prompt -w "无法解析用户 $owner，跳过属主修正"
        return 0
    fi
    gid="$(id -g "$owner")"

    if sudo -u "$owner" test -w "$mp" 2>/dev/null; then
        return 0
    fi

    prompt -w "卷根目录当前用户（$owner）写不了，正在 chown 根目录 → $owner:$owner"
    prompt -i "只改挂载点这一层，不递归；属主会保存在卷内。"
    if ! sudo chown "$uid:$gid" "$mp"; then
        prompt -e "chown 失败: $mp"
        return 1
    fi
    sudo chmod u+rwx "$mp" 2>/dev/null || true

    if sudo -u "$owner" test -w "$mp" 2>/dev/null; then
        prompt -s "现在可以写入: $mp"
        return 0
    fi
    prompt -e "修正后仍无法以 $owner 写入 $mp"
    return 1
}

vc_owner_state_file() {
    printf '%s\n' "${LIB_DIR}/.last-vcraw"
}

# bindfs 底下那层真实 ext4。放在 0700 的父目录里，避免别人直接进未映射的卷。
# 按卷路径固定，避免卸的时候找不到。
vc_raw_mount_dir() {
    local id
    id="$(printf '%s' "${VOLUME_PATH:-unknown}" | cksum | awk '{print $1}')"
    printf '%s\n' "/run/vcraw/$id"
}

clear_owner_view_state() {
    rm -f "$(vc_owner_state_file)" 2>/dev/null || true
}

write_owner_view_state() {
    printf 'raw=%s\naccess=%s\nmode=bindfs\n' "$1" "$2" >"$(vc_owner_state_file)"
}

# bindfs 的访问目录。path 若是 /run/vcraw 下的底层 ext4，改写成用户真正进入的目录。
user_facing_mount() {
    local path="$1" access="" raw="" f src
    [ -n "$path" ] || return 1
    f="$(vc_owner_state_file)"
    if [ -f "$f" ]; then
        raw="$(sed -n 's/^raw=//p' "$f" | head -n 1)"
        access="$(sed -n 's/^access=//p' "$f" | head -n 1)"
        if [ -n "$access" ] && check_mount_point "$access" && { [ "$path" = "$raw" ] || [ "$path" = "$access" ]; }; then
            printf '%s\n' "$access"
            return 0
        fi
    fi
    case "$path" in
        /run/vcraw|/run/vcraw/*)
            access="$(findmnt -rn -o SOURCE,TARGET | awk -v raw="$path" '$1==raw { print $2; exit }')"
            if [ -n "$access" ] && [ "$access" != "$path" ]; then
                printf '%s\n' "$access"
                return 0
            fi
            ;;
    esac
    printf '%s\n' "$path"
}

# 有 bindfs 时：先卸访问目录，再卸 /run/vcraw 下的 ext4。
# 返回 2 表示这两层已经卸掉；返回 0 表示没有这层；返回 1 表示卸失败。
umount_owner_view() {
    local f raw="" access="" src
    f="$(vc_owner_state_file)"
    if [ -f "$f" ]; then
        raw="$(sed -n 's/^raw=//p' "$f" | head -n 1)"
        access="$(sed -n 's/^access=//p' "$f" | head -n 1)"
    fi
    case "${readMount:-}" in
        /run/vcraw|/run/vcraw/*)
            raw="${raw:-$readMount}"
            ;;
    esac
    if [ -z "$access" ] && [ -n "$raw" ]; then
        access="$(findmnt -rn -o SOURCE,TARGET | awk -v raw="$raw" '$1==raw { print $2; exit }')"
    fi
    if [ -z "$raw" ] && [ -n "${readMount:-}" ] && check_mount_point "$readMount"; then
        src="$(findmnt -n -o SOURCE --mountpoint "$readMount" 2>/dev/null || true)"
        case "$src" in
            /run/vcraw|/run/vcraw/*)
                raw="$src"
                access="$readMount"
                ;;
        esac
    fi
    if [ -z "$access" ] && [ -z "$raw" ]; then
        return 0
    fi
    if [ -z "$access" ] || ! check_mount_point "$access"; then
        if [ -z "$raw" ] || ! check_mount_point "$raw"; then
            return 0
        fi
    fi
    if [ -n "$access" ] && check_mount_point "$access"; then
        prompt -k "卸载目录" "$access"
        prompt -x "umount $access"
        if ! sudo umount "$access"; then
            show_mount_holders "$access"
            return 1
        fi
        readMount="$access"
    fi
    if [ -n "$raw" ] && check_mount_point "$raw"; then
        prompt -x "umount $raw"
        if ! sudo umount "$raw"; then
            show_mount_holders "$raw"
            prompt -e "底层目录还在: $raw"
            return 1
        fi
        sudo rmdir "$raw" 2>/dev/null || true
    fi
    clear_owner_view_state
    return 2
}

# 访问目录已经卸掉之后，再卸 bindfs 底下的 ext4。访问目录还在就先不动。
release_bindfs_raw() {
    local f raw access
    f="$(vc_owner_state_file)"
    [ -f "$f" ] || return 0
    raw="$(sed -n 's/^raw=//p' "$f" | head -n 1)"
    access="$(sed -n 's/^access=//p' "$f" | head -n 1)"
    if [ -n "$access" ] && check_mount_point "$access"; then
        return 0
    fi
    if [ -n "$raw" ] && check_mount_point "$raw"; then
        prompt -x "umount $raw"
        if ! sudo umount "$raw"; then
            prompt -e "底层目录还在: $raw"
            return 1
        fi
    fi
    if [ -n "$raw" ]; then
        sudo rmdir "$raw" 2>/dev/null || true
    fi
    clear_owner_view_state
    return 0
}

# stdout 不打印选择结果，写入 VC_OWNER_CHOICE：map | chown-root | skip
ask_owner_mismatch_action() {
    local vuid="$1" vgid="$2" uid="$3" gid="$4" owner="$5" input
    echo
    echo "卷根属主和当前用户不一致。"
    echo "磁盘: uid=$vuid  gid=$vgid"
    echo "当前: $owner  uid=$uid  gid=$gid"
    if [ "$vuid" = "0" ]; then
        echo "卷根是 root。这种盘一般可以读；映射会让 root 的文件看起来都属于你。"
    else
        echo "一般可以读。要写入或使用回收站，需要映射。映射不改卷里保存的属主。"
    fi
    echo "  m) 映射成当前用户（内核支持就 idmap，否则 bindfs）"
    echo "  c) 只 chown 卷根（写入卷，子目录可能仍不可写）"
    echo "  n) 不处理"
    while true; do
        _read_user -p "请选择 [M/c/n]: " input
        case "${input:-m}" in
            m|M) VC_OWNER_CHOICE="map"; return 0 ;;
            c|C) VC_OWNER_CHOICE="chown-root"; return 0 ;;
            n|N) VC_OWNER_CHOICE="skip"; return 0 ;;
            *) prompt -w "请输入 m、c 或 n。" ;;
        esac
    done
}

# idmap 挂载从内核 5.12 才有。更早的内核上，旧 mount 会丢掉不认识的 X- 选项并返回成功。
kernel_can_idmap() {
    local rel major minor
    rel="$(uname -r)"
    major="${rel%%.*}"
    minor="${rel#*.}"
    minor="${minor%%.*}"
    case "$major" in
        ''|*[!0-9]*) return 1 ;;
    esac
    case "$minor" in
        ''|*[!0-9]*) minor=0 ;;
    esac
    if [ "$major" -gt 5 ]; then
        return 0
    fi
    [ "$major" -eq 5 ] && [ "$minor" -ge 12 ]
}

# 映射之后核对看到的 uid。mount 返回 0 不够：旧 mount 会忽略 X-mount.idmap。
# disk_uid 是卷里保存的 uid，expect 是当前用户。样本文件和（若卷根也是这个 uid）挂载点都要变成 expect。
owner_visible_as() {
    local mp="$1" expect="$2" disk_uid="$3" root_disk_uid="$4" sample="$5"
    local got checked=0
    if [ -n "$sample" ]; then
        got="$(sudo stat -c '%u' "$mp/$sample" 2>/dev/null || true)"
        [ "$got" = "$expect" ] || return 1
        checked=1
    fi
    if [ "$checked" -eq 0 ] || [ "$root_disk_uid" = "$disk_uid" ]; then
        got="$(sudo stat -c '%u' "$mp" 2>/dev/null || true)"
        [ "$got" = "$expect" ] || return 1
    fi
    if [ -n "${VOL_WITNESS_SAMPLE:-}" ]; then
        got="$(sudo stat -c '%u' "$mp/$VOL_WITNESS_SAMPLE" 2>/dev/null || true)"
        [ "$got" = "$expect" ] || return 1
    fi
    return 0
}

# 一层子项里出现最多的非 0 uid，当作卷的属主。没有这种子项就用卷根。
# 写入 VOL_PERSON_UID / VOL_PERSON_GID / VOL_OWNER_SAMPLE / VOL_ROOT_DISK_UID。
pick_volume_person() {
    local mp="$1" expect_uid="${2:-}"
    local root_ids root_uid root_gid picked rest
    VOL_PERSON_UID=""
    VOL_PERSON_GID=""
    VOL_OWNER_SAMPLE=""
    VOL_WITNESS_SAMPLE=""
    VOL_ROOT_DISK_UID=""
    root_ids="$(sudo stat -c '%u %g' "$mp" 2>/dev/null || true)"
    root_uid="${root_ids%% *}"
    root_gid="${root_ids#* }"
    if [ -z "$root_uid" ] || [ "$root_uid" = "$root_ids" ]; then
        return 1
    fi
    VOL_ROOT_DISK_UID="$root_uid"
    picked="$(sudo find "$mp" -mindepth 1 -maxdepth 1 ! -name lost+found -printf '%U\t%G\t%f\n' 2>/dev/null \
        | awk -F '\t' '
            $1 == 0 { next }
            {
                c[$1]++
                if (c[$1] > best) {
                    best = c[$1]
                    uid = $1
                    gid = $2
                    name = $3
                }
            }
            END {
                if (uid != "") print uid "\t" gid "\t" name
            }
        ')"
    if [ -n "$picked" ]; then
        VOL_PERSON_UID="${picked%%$'\t'*}"
        rest="${picked#*$'\t'}"
        VOL_PERSON_GID="${rest%%$'\t'*}"
        VOL_OWNER_SAMPLE="${rest#*$'\t'}"
    else
        VOL_PERSON_UID="$root_uid"
        VOL_PERSON_GID="$root_gid"
    fi
    # 文件已经是当前用户，只是卷根被改过：映射卷根那个 uid。
    # 见证文件必须仍显示成当前用户，避免 idmap 把已经对的文件变成 nobody。
    if [ -n "$expect_uid" ] && [ "$VOL_PERSON_UID" = "$expect_uid" ] && [ "$root_uid" != "$expect_uid" ] && [ "$root_uid" != "0" ]; then
        VOL_WITNESS_SAMPLE="$VOL_OWNER_SAMPLE"
        VOL_PERSON_UID="$root_uid"
        VOL_PERSON_GID="$root_gid"
        VOL_OWNER_SAMPLE=""
    fi
    return 0
}

# 先试内核 idmap。失败就由调用方改走 bindfs。gid 为 0 时不映射组，避免把 root 组整段换掉。
# X-mount.idmap 的顺序是「看到的:磁盘上的:个数」。u:1002:1000:1 表示磁盘上的 1000 显示成 1002。
try_idmap_mount() {
    local dev="$1" mp="$2" vuid="$3" vgid="$4" uid="$5" gid="$6"
    local spec err rc got
    spec="u:${uid}:${vuid}:1"
    if [ -n "$vgid" ] && [ "$vgid" != "0" ] && [ "$vgid" != "$gid" ]; then
        spec="$spec g:${gid}:${vgid}:1"
    fi
    prompt -x "mount -o X-mount.idmap=$spec $dev $mp"
    err="$(sudo mount -o "X-mount.idmap=$spec" "$dev" "$mp" 2>&1)"
    rc=$?
    if [ "$rc" -ne 0 ]; then
        [ -n "$err" ] && printf '%s\n' "$err" >&2
        return 1
    fi
    if owner_visible_as "$mp" "$uid" "$vuid" "${VOL_ROOT_DISK_UID:-$vuid}" "${VOL_OWNER_SAMPLE:-}"; then
        VC_OWNER_NOTE="idmap ${vuid}→${uid}"
        clear_owner_view_state
        return 0
    fi
    got="$(sudo stat -c '%u' "$mp" 2>/dev/null || true)"
    prompt -w "mount 返回成功，但看到的 uid 仍是 ${got:-未知}。这台 mount 没有真正应用 X-mount.idmap。"
    prompt -x "umount $mp"
    sudo umount "$mp" || true
    return 1
}

ensure_bindfs() {
    if command -v bindfs >/dev/null 2>&1; then
        return 0
    fi
    prompt -w "没有 bindfs，尝试安装..."
    if ! sudo apt install -y bindfs; then
        prompt -e "bindfs 安装失败。Debian 10 / 内核 4.19 需要这个包才能做属主映射。"
        return 1
    fi
    command -v bindfs >/dev/null 2>&1
}

try_bindfs_mount() {
    local dev="$1" mp="$2" vuid="$3" vgid="$4" uid="$5" gid="$6"
    local raw mapopt
    ensure_bindfs || return 1
    if ! bindfs --help 2>&1 | grep -q -- '--map'; then
        prompt -e "这台 bindfs 没有 --map，做不了属主映射。"
        return 1
    fi
    raw="$(vc_raw_mount_dir)"
    if check_mount_point "$raw"; then
        prompt -x "umount $raw"
        sudo umount "$raw" || return 1
    fi
    sudo mkdir -p /run/vcraw || return 1
    sudo chmod 700 /run/vcraw || true
    sudo mkdir -p "$raw" || return 1
    prompt -x "mount $dev $raw"
    if ! sudo mount "$dev" "$raw"; then
        sudo rmdir "$raw" 2>/dev/null || true
        return 1
    fi
    mapopt="${vuid}/${uid}"
    if [ -n "$vgid" ] && [ "$vgid" != "0" ] && [ "$vgid" != "$gid" ]; then
        mapopt="${mapopt}:@${vgid}/@${gid}"
    fi
    prompt -x "bindfs --map=$mapopt $raw $mp"
    if ! sudo bindfs --map="$mapopt" -o allow_other "$raw" "$mp"; then
        sudo umount "$raw" 2>/dev/null || true
        sudo rmdir "$raw" 2>/dev/null || true
        return 1
    fi
    if ! owner_visible_as "$mp" "$uid" "$vuid" "${VOL_ROOT_DISK_UID:-$vuid}" "${VOL_OWNER_SAMPLE:-}"; then
        prompt -e "bindfs 挂上了，但看到的属主仍不是当前用户。"
        sudo fusermount -u "$mp" 2>/dev/null || sudo umount "$mp" 2>/dev/null || true
        sudo umount "$raw" 2>/dev/null || true
        sudo rmdir "$raw" 2>/dev/null || true
        return 1
    fi
    write_owner_view_state "$raw" "$mp"
    VC_OWNER_NOTE="bindfs ${vuid}→${uid}"
    return 0
}

# ext4 等已经按卷内权限挂上之后调用。uid 一致则什么都不做。
# 返回 1 表示访问目录没挂着。
reconcile_native_fs_owner() {
    local mp="$1" dev="$2" fstype="$3"
    local owner uid gid vuid vgid policy

    [ "${readOnly:-0}" -eq 1 ] && return 0

    owner="${_MEDIA_USER:-${SUDO_USER:-${USER:-$(id -un)}}}"
    if ! uid="$(id -u "$owner" 2>/dev/null)"; then
        prompt -w "无法解析用户 $owner，跳过属主检查"
        return 0
    fi
    gid="$(id -g "$owner")"
    if ! pick_volume_person "$mp" "$uid"; then
        prompt -w "读不到卷根属主，跳过属主检查"
        return 0
    fi
    vuid="$VOL_PERSON_UID"
    vgid="$VOL_PERSON_GID"
    if [ -z "$vuid" ]; then
        prompt -w "读不到卷内属主，跳过属主检查"
        return 0
    fi
    if [ "$vuid" = "$uid" ] && { [ "$VOL_ROOT_DISK_UID" = "$uid" ] || [ "$VOL_ROOT_DISK_UID" = "0" ]; }; then
        clear_owner_view_state
        return 0
    fi

    echo
    echo "卷内主要属主 uid=$vuid，当前用户 $owner 是 uid=$uid。"
    if [ "$VOL_ROOT_DISK_UID" != "$vuid" ]; then
        echo "卷根 uid=$VOL_ROOT_DISK_UID，和里面的文件不一致，按文件的属主来映射。"
    fi

    policy="${ownerMismatch:-ask}"
    case "$policy" in
        ask|"")
            if [ ! -r /dev/tty ]; then
                echo "没有终端可询问，按 map 处理：先 idmap，不行就 bindfs。"
                policy="map"
            else
                ask_owner_mismatch_action "$vuid" "$vgid" "$uid" "$gid" "$owner"
                policy="$VC_OWNER_CHOICE"
            fi
            ;;
        map|idmap) policy="map" ;;
        bindfs) policy="bindfs" ;;
        chown-root|chown) policy="chown-root" ;;
        skip|off|no|0|false) policy="skip" ;;
        *)
            prompt -w "未知 ownerMismatch=$ownerMismatch，改为询问。"
            ask_owner_mismatch_action "$vuid" "$vgid" "$uid" "$gid" "$owner"
            policy="$VC_OWNER_CHOICE"
            ;;
    esac

    case "$policy" in
        skip)
            VC_WARN_REASON="卷根 uid=$vuid 与 $owner($uid) 不一致，未做映射，可能无法写入"
            clear_owner_view_state
            return 0
            ;;
        chown-root)
            clear_owner_view_state
            if ! fix_native_fs_root_owner "$mp"; then
                VC_WARN_REASON="卷根 chown 失败，可能无法写入"
            fi
            return 0
            ;;
        bindfs)
            prompt -x "umount $mp"
            if ! sudo umount "$mp"; then
                VC_FAIL_REASON="卸下原挂载失败，无法改用 bindfs"
                return 1
            fi
            if try_bindfs_mount "$dev" "$mp" "$vuid" "$vgid" "$uid" "$gid"; then
                prompt -k "属主处理" "$VC_OWNER_NOTE"
                return 0
            fi
            ;;
        map)
            prompt -x "umount $mp"
            if ! sudo umount "$mp"; then
                VC_FAIL_REASON="卸下原挂载失败，无法做属主映射"
                return 1
            fi
            if kernel_can_idmap && try_idmap_mount "$dev" "$mp" "$vuid" "$vgid" "$uid" "$gid"; then
                prompt -k "属主处理" "$VC_OWNER_NOTE"
                return 0
            fi
            if kernel_can_idmap; then
                prompt -w "idmap 没有改掉看到的属主，改用 bindfs。"
            else
                prompt -w "内核 $(uname -r) 没有 idmap（需要 5.12 以上），改用 bindfs。"
            fi
            if try_bindfs_mount "$dev" "$mp" "$vuid" "$vgid" "$uid" "$gid"; then
                prompt -k "属主处理" "$VC_OWNER_NOTE"
                return 0
            fi
            ;;
    esac

    prompt -w "属主映射失败，尝试按卷内权限重新挂上。"
    if mount_mapped_filesystem "$dev" "$fstype" 0; then
        VC_OWNER_FAILED=1
        VC_WARN_REASON="属主没有映射成功。这台请先安装 bindfs 再挂: sudo apt install bindfs"
        clear_owner_view_state
        return 0
    fi
    VC_FAIL_REASON="属主映射失败，原来的挂载也没能挂回去"
    return 1
}

# 返回 0 表示本次挂载要加 uid/gid。
decide_owner_options() {
    local fstype="$1"
    case "${useOwnerOptions}" in
        0|off|no|false)
            return 1
            ;;
        1|on|yes|true)
            return 0
            ;;
        auto|2|"")
            fs_needs_owner_options "$fstype"
            return $?
            ;;
        *)
            prompt -w "未知 useOwnerOptions=${useOwnerOptions}，按 auto 处理。"
            fs_needs_owner_options "$fstype"
            return $?
            ;;
    esac
}

mount_mapped_filesystem() {
    local device="$1" fstype="$2" use_owner="$3"
    local opts=() mount_rc joined

    if [ "$readOnly" -eq 1 ]; then
        opts+=(ro)
    fi
    if [ "$use_owner" -eq 1 ]; then
        # NTFS/FAT 等：用当前用户（有 sudo 时用 SUDO_USER）映射
        local ou og
        if [ -n "${SUDO_USER:-}" ] && [ "$(id -u)" -eq 0 ]; then
            ou="$(id -u "$SUDO_USER")"
            og="$(id -g "$SUDO_USER")"
        else
            ou="$(id -u)"
            og="$(id -g)"
        fi
        opts+=("uid=$ou" "gid=$og")
    fi

    if [ "$kernelNtfs" -eq 1 ] && fs_needs_owner_options "$fstype"; then
        if [ "${#opts[@]}" -gt 0 ]; then
            joined="$(IFS=,; echo "${opts[*]}")"
        else
            joined=""
        fi
        prompt -x "mount -t ntfs3 $device $readMount"
        if [ -n "$joined" ]; then
            sudo mount -t ntfs3 -o "$joined" "$device" "$readMount"
        else
            sudo mount -t ntfs3 "$device" "$readMount"
        fi
        mount_rc=$?
        if [ "$mount_rc" -eq 0 ]; then
            return 0
        fi
        prompt -w "ntfs3 挂载失败，回退自动类型。"
    fi

    if [ "${#opts[@]}" -gt 0 ]; then
        joined="$(IFS=,; echo "${opts[*]}")"
        prompt -x "mount -o $joined $device $readMount"
        sudo mount -o "$joined" "$device" "$readMount"
        return $?
    fi
    prompt -x "mount $device $readMount"
    sudo mount "$device" "$readMount"
    return $?
}

detach_veracrypt_volume() {
    local target="$1"
    if [ "${VC_BACKEND:-}" = "tcplay" ]; then
        local did=1
        tcplay_map_name
        if [ -e "/dev/mapper/$TCPLAY_MAP" ]; then
            sudo "$TCPLAY_BIN" --unmap="$TCPLAY_MAP" || sudo dmsetup remove "$TCPLAY_MAP" || return 1
            did=0
        fi
        if tcplay_release_loop; then
            did=0
        fi
        return $did
    fi
    if [ -n "$target" ]; then
        sudo "$VERACRYPT_BIN" --text --non-interactive --unmount "$target" >/dev/null 2>&1 && return 0
    fi
    return 1
}

# 整段操作的最后一行结论。ok=绿色，fail=红色。
print_result_banner() {
    local kind="$1" title="$2" detail="${3:-}"
    if [ -n "$detail" ]; then
        title="$(_pad_label "$title")$detail"
    fi
    if [ "$kind" = "ok" ]; then
        status_line ok "$title"
    else
        status_line fail "$title"
    fi
}

print_mount_plan() {
    local uid gid user
    uid="$(id -u)"
    gid="$(id -g)"
    user="$(id -un)"
    prompt -m "挂载计划"
    prompt -k "加密分区" "$VOLUME_PATH"
    prompt -k "命名模式" "${mountNameMode:-label-or-fixed}（固定名回退: ${mountName:-rveracrypt}）"
    prompt -k "预计目录" "$(media_user_root)/…（解密后按卷标决定）"
    prompt -k "当前用户" "$user  uid=$uid  gid=$gid"
    prompt -k "uid/gid 策略" "$useOwnerOptions（auto=按文件系统决定；NTFS/FAT/exFAT 才会加）"
    prompt -k "NTFS 内核驱动" "$([ "$kernelNtfs" -eq 1 ] && echo 开 || echo 关)"
    prompt -k "只读" "$([ "$readOnly" -eq 1 ] && echo 是 || echo 否)"
    prompt -k "解密方式" "${VC_BACKEND:-veracrypt}"
    if [ "${VC_BACKEND:-}" = "tcplay" ]; then
        prompt -i "解密后会出现中间设备 /dev/mapper/$TCPLAY_MAP，文件管理器进的是访问目录。"
    else
        prompt -i "解密后会出现中间设备 /dev/mapper/veracryptN，文件管理器进的是访问目录。"
    fi
    echo
}

print_mount_result() {
    local src fstype opts label
    src="$(findmnt -n -o SOURCE --target "$readMount" 2>/dev/null || true)"
    fstype="$(findmnt -n -o FSTYPE --target "$readMount" 2>/dev/null || true)"
    opts="$(findmnt -n -o OPTIONS --target "$readMount" 2>/dev/null || true)"
    label="$(sudo blkid -o value -s LABEL "$src" 2>/dev/null || true)"
    prompt -k "访问目录" "$readMount"
    prompt -k "块设备" "${src:-未知}"
    prompt -k "文件系统" "${fstype:-未知}"
    prompt -k "卷标" "${label:-（无）}"
    prompt -k "当前用户" "$(id -un)  uid=$(id -u)  gid=$(id -g)"
    prompt -k "挂载选项" "${opts:-无}"
    prompt -k "卸载" "$LIB_DIR/urmount.sh"
}

# 卷已解密（槽位打开）则返回 0，并设置 VC_SLOT_DEV。
# 文件系统也挂着时另外设置 VC_SLOT_MP；只解密、未挂文件系统时 VC_SLOT_MP 为空。
# 脚本用 mount(8) 挂 /dev/mapper/veracryptN 时，veracrypt -l 的挂载目录经常仍是 "-"，
# 所以要以 findmnt 看映射设备是否真的挂上。
detect_open_veracrypt_slot() {
    local line dev mp src mounted_at
    VC_SLOT_DEV=""
    VC_SLOT_MP=""
    resolve_veracrypt_bin || return 1
    resolve_volume quiet || return 1

    if [ "${VC_BACKEND:-}" = "tcplay" ]; then
        tcplay_map_name
        dev="/dev/mapper/$TCPLAY_MAP"
        if [ ! -e "$dev" ]; then
            return 1
        fi
        VC_SLOT_DEV="$dev"
        mounted_at="$(findmnt -n -o TARGET -S "$dev" 2>/dev/null | head -n 1 || true)"
        if [ -n "$mounted_at" ] && check_mount_point "$mounted_at"; then
            VC_SLOT_MP="$mounted_at"
        fi
        return 0
    fi

    line="$(sudo "$VERACRYPT_BIN" --text --verbose --list "$VOLUME_PATH" 2>/dev/null || true)"
    if [ -z "$line" ]; then
        return 1
    fi
    dev="$(printf '%s\n' "$line" | awk -F': ' '/^Virtual Device:/ { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit }')"
    if [ -z "$dev" ] || [ "$dev" = "$VOLUME_PATH" ] || [ ! -e "$dev" ]; then
        dev="$(printf '%s\n' "$line" | grep -oE '/dev/mapper/veracrypt[0-9]+' | head -n 1)"
    fi
    if [ -z "$dev" ] || [ ! -e "$dev" ] || [ "$dev" = "$VOLUME_PATH" ]; then
        return 1
    fi

    VC_SLOT_DEV="$dev"
    mp="$(printf '%s\n' "$line" | awk -F': ' '/^Mount Directory:/ { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit }')"
    if [ -n "$mp" ] && [ "$mp" != "-" ] && [[ "$mp" == /* ]] && check_mount_point "$mp"; then
        src="$(findmnt -n -o SOURCE --mountpoint "$mp" 2>/dev/null || true)"
        if [ "$src" = "$dev" ] || [ "$(readlink -f "$src" 2>/dev/null || echo "$src")" = "$(readlink -f "$dev")" ]; then
            VC_SLOT_MP="$mp"
        fi
    fi
    if [ -z "$VC_SLOT_MP" ]; then
        mounted_at="$(findmnt -n -o TARGET -S "$dev" 2>/dev/null | head -n 1 || true)"
        if [ -n "$mounted_at" ] && check_mount_point "$mounted_at"; then
            VC_SLOT_MP="$mounted_at"
        fi
    fi
    return 0
}

# 查找本卷是否已挂载，找到则设置 readMount。
detect_existing_veracrypt_mount() {
    local line mp fixed
    resolve_veracrypt_bin || return 1
    if load_last_read_mount "$LIB_DIR"; then
        prompt -k "已挂载(记录)" "$readMount"
        return 0
    fi
    fixed="$(media_user_root)/${mountName:-rveracrypt}"
    if check_mount_point "$fixed"; then
        readMount="$fixed"
        prompt -k "已挂载(固定名)" "$readMount"
        return 0
    fi
    if ! resolve_volume quiet; then
        return 1
    fi
    if [ "${VC_BACKEND:-}" != "tcplay" ]; then
        line="$(sudo "$VERACRYPT_BIN" --text -l "$VOLUME_PATH" 2>/dev/null | head -n 1 || true)"
        mp="$(printf '%s\n' "$line" | awk '{print $NF}')"
        if [ -n "$mp" ] && [ "$mp" != "-" ] && [[ "$mp" == /* ]] && check_mount_point "$mp"; then
            readMount="$(user_facing_mount "$mp")"
            prompt -k "已挂载(VeraCrypt)" "$readMount"
            return 0
        fi
    fi
    # 文件系统是用 mount(8) 挂到映射设备上的，veracrypt 列表里可能没有目录。
    if detect_open_veracrypt_slot && [ -n "$VC_SLOT_MP" ]; then
        readMount="$(user_facing_mount "$VC_SLOT_MP")"
        prompt -k "已挂载(映射设备)" "$readMount"
        return 0
    fi
    return 1
}

# 把已经解密的映射设备挂上文件系统。
# $2=1：失败时保留解密槽（调用前卷就已经是「已解密、未挂载」）。
mount_filesystem_from_mapped() {
    local mapped_dev="$1"
    local keep_slot="${2:-0}"
    local fstype use_owner=0 owner_uid owner_gid vol_label=""

    _release_after_mount_fail() {
        if [ "$keep_slot" -eq 1 ]; then
            prompt -i "解密状态仍保留。可以再挂一次，或选择取消解密。"
            return 0
        fi
        detach_veracrypt_volume "$VOLUME_PATH"
        detach_veracrypt_volume "$mapped_dev"
    }

    fstype="$(sudo blkid -o value -s TYPE "$mapped_dev" 2>/dev/null || true)"
    vol_label="$(sudo blkid -o value -s LABEL "$mapped_dev" 2>/dev/null || true)"
    if [ -n "$fstype" ]; then
        prompt -k "检测到的文件系统" "$fstype"
    else
        prompt -w "blkid 没认出文件系统，按原生 Linux 文件系统处理（不加 uid/gid）。"
        fstype="unknown"
        prompt -k "检测到的文件系统" "$fstype"
    fi
    prompt -k "检测到的卷标" "${vol_label:-（无）}"

    if ! resolve_media_read_mount "$vol_label"; then
        VC_FAIL_REASON="定不了访问目录"
        _release_after_mount_fail
        return 1
    fi
    if ! ensure_mount_dir "$readMount"; then
        VC_FAIL_REASON="挂载点目录不可用"
        _release_after_mount_fail
        return 1
    fi

    owner_uid="$(id -u)"
    owner_gid="$(id -g)"
    if decide_owner_options "$fstype"; then
        use_owner=1
        prompt -k "uid/gid" "启用  uid=$owner_uid  gid=$owner_gid（$fstype 没有 Linux 属主，靠这个映射给当前用户）"
        if [ "$owner_uid" -eq 0 ]; then
            prompt -w "当前是 root。请用普通用户运行，否则卷内文件会归 root。"
        fi
    else
        use_owner=0
        prompt -k "uid/gid" "不使用（$fstype 用卷内自己的权限，或已被配置关掉）"
    fi
    prompt -k "即将挂到" "$readMount"

    if ! mount_mapped_filesystem "$mapped_dev" "$fstype" "$use_owner"; then
        VC_FAIL_REASON="文件系统没有挂上: $readMount"
        prompt -e "文件系统挂载失败。访问目录 $readMount 没有挂上。"
        _release_after_mount_fail
        return 1
    fi

    # ext4 等：挂上之后再比卷根 uid。不一致就问（config 指定了方式则不问）。
    if [ "$use_owner" -eq 0 ]; then
        if ! reconcile_native_fs_owner "$readMount" "$mapped_dev" "$fstype"; then
            _release_after_mount_fail
            return 1
        fi
    fi

    save_last_read_mount "$LIB_DIR"
    print_mount_result
    return 0
}

_mount_veracrypt_impl() {
    local mapped_dev
    if ! resolve_veracrypt_bin; then
        VC_FAIL_REASON="找不到可用的解密程序"
        return 1
    fi
    if ! resolve_volume; then
        VC_FAIL_REASON="找不到要挂载的卷"
        return 1
    fi

    # 已经解开、只是文件系统没挂上：不要再走一遍解密（会报卷已打开）。
    if detect_open_veracrypt_slot; then
        if [ -z "$VC_SLOT_MP" ]; then
            prompt -i "卷已经解密，不再次询问密码，直接挂上文件系统。"
            prompt -k "加密分区" "$VOLUME_PATH"
            prompt -k "解密设备" "$VC_SLOT_DEV"
            mount_filesystem_from_mapped "$VC_SLOT_DEV" 1
            return $?
        fi
        readMount="$VC_SLOT_MP"
        VC_MOUNT_NOTE="already"
        prompt -w "已经挂载: $readMount"
        return 1
    fi

    if ! build_vc_crypto_args; then
        VC_FAIL_REASON="解密参数不正确"
        return 1
    fi
    print_mount_plan

    if [ -n "${keyPass:-}" ]; then
        prompt -m "使用 config.sh 里的密码解密 $VOLUME_PATH"
    else
        prompt -m "请输入 $VOLUME_PATH 的 VeraCrypt 密码（只输一次）。"
    fi

    # 先只解开加密层，探测文件系统/卷标，再决定访问目录。
    prompt -x "解密（先不挂文件系统）: $VOLUME_PATH"
    if ! open_crypto_slot; then
        if detect_open_veracrypt_slot && [ -z "$VC_SLOT_MP" ]; then
            prompt -w "卷已经处于解密状态，改为直接挂文件系统。"
            mount_filesystem_from_mapped "$VC_SLOT_DEV" 1
            return $?
        fi
        VC_FAIL_REASON="解密失败"
        prompt -e "解密失败。"
        return 1
    fi

    mapped_dev="$(get_veracrypt_mapped_device "$VOLUME_PATH")"
    if [ -z "$mapped_dev" ] || [ ! -e "$mapped_dev" ] || [ "$mapped_dev" = "$VOLUME_PATH" ]; then
        VC_FAIL_REASON="找不到解密后的块设备"
        prompt -e "找不到解密后的块设备 /dev/mapper/veracryptN。"
        detach_veracrypt_volume "$VOLUME_PATH"
        return 1
    fi
    prompt -k "解密设备" "$mapped_dev"
    prompt -i "这是中间设备，不会当成你的访问目录。"

    mount_filesystem_from_mapped "$mapped_dev" 0
    return $?
}

mount_veracrypt() {
    local rc
    VC_FAIL_REASON=""
    VC_WARN_REASON=""
    VC_OWNER_FAILED=""
    VC_MOUNT_NOTE=""
    _mount_veracrypt_impl
    rc=$?
    if [ "$rc" -eq 0 ]; then
        if [ -n "$VC_OWNER_FAILED" ]; then
            print_result_banner fail "未映射属主" "${VC_WARN_REASON:-可能无法写入}"
        else
            print_result_banner ok "挂载成功" "${readMount:-}"
            if [ -n "$VC_WARN_REASON" ]; then
                print_result_banner fail "但有问题" "$VC_WARN_REASON"
            fi
        fi
    elif [ "$VC_MOUNT_NOTE" = "already" ]; then
        print_result_banner ok "已经挂载" "${readMount:-}"
    else
        print_result_banner fail "挂载失败" "${VC_FAIL_REASON:-详见上方红色提示}"
    fi
    return "$rc"
}

umount_veracrypt() {
    local rc=1 mapped=""
    if ! resolve_veracrypt_bin; then
        print_result_banner fail "卸载失败" "找不到可用的解密程序"
        return 1
    fi
    detect_existing_veracrypt_mount || true

    # bindfs 占着底层目录。先卸 /media 上的访问目录，再卸 /run/vcraw。
    umount_owner_view
    local view_rc=$?
    if [ "$view_rc" -eq 1 ]; then
        print_result_banner fail "卸载失败" "访问目录还在，解密映射先留着"
        return 1
    fi
    if [ "$view_rc" -eq 2 ]; then
        rc=0
    elif check_mount_point "$readMount"; then
        mapped="$(findmnt -n -o SOURCE --target "$readMount" 2>/dev/null || true)"
        prompt -k "卸载目录" "$readMount"
        prompt -x "umount $readMount"
        if sudo umount "$readMount"; then
            rc=0
        else
            show_mount_holders "$readMount"
            prompt -w "仍尝试卸掉解密映射（不再询问紧急清理）。"
            if [ "${VC_BACKEND:-}" = "tcplay" ]; then
                if detach_veracrypt_volume "$readMount"; then
                    rc=0
                fi
            elif sudo "$VERACRYPT_BIN" --text --non-interactive --unmount "$readMount"; then
                rc=0
            fi
        fi
    else
        if detect_open_veracrypt_slot && [ -z "$VC_SLOT_MP" ]; then
            prompt -i "文件系统未挂载，卷仍处于解密状态（${VC_SLOT_DEV}），将取消解密。"
        else
            prompt -w "挂载点未挂载: $readMount"
        fi
    fi

    # bindfs 底下还有一层 ext4，访问目录卸掉后再卸它。底层还在就不要拆解密槽。
    if ! release_bindfs_raw; then
        rc=1
        print_result_banner fail "卸载失败" "访问目录底下的 ext4 还在，解密映射先留着"
        return 1
    fi

    # 解开 filesystem=none 留下的映射。
    if resolve_volume quiet; then
        if detach_veracrypt_volume "$VOLUME_PATH"; then
            rc=0
        fi
    fi
    if [ -n "$mapped" ]; then
        if detach_veracrypt_volume "$mapped"; then
            rc=0
        fi
    fi

    if [ "$rc" -eq 0 ]; then
        remove_empty_media_dir "$readMount"
        rm -f "$LIB_DIR/.last-readmount" 2>/dev/null || true
        if check_mount_point "$readMount"; then
            print_result_banner fail "卸载失败" "目录还在: $readMount"
            return 1
        fi
        print_result_banner ok "卸载成功" "${readMount:-已取消解密}"
        return 0
    fi
    print_result_banner fail "卸载失败" "占用 $readMount 的进程已经列在上面，关掉后再卸。"
    return 1
}

# 只去掉解密槽，不要求文件系统正处于挂载中。
release_open_veracrypt_slot() {
    local dev
    if ! resolve_veracrypt_bin; then
        print_result_banner fail "取消解密失败" "找不到可用的解密程序"
        return 1
    fi
    if ! detect_open_veracrypt_slot; then
        print_result_banner fail "取消解密失败" "没有处于解密状态的卷"
        return 1
    fi
    if [ -n "$VC_SLOT_MP" ]; then
        readMount="$VC_SLOT_MP"
        umount_veracrypt
        return $?
    fi
    dev="$VC_SLOT_DEV"
    prompt -k "取消解密" "$dev"
    if [ "${VC_BACKEND:-}" = "tcplay" ]; then
        prompt -x "tcplay --unmap $TCPLAY_MAP"
    else
        prompt -x "veracrypt --unmount $VOLUME_PATH"
    fi
    if detach_veracrypt_volume "$VOLUME_PATH" || detach_veracrypt_volume "$dev"; then
        rm -f "$LIB_DIR/.last-readmount" 2>/dev/null || true
        print_result_banner ok "已取消解密" "$dev"
        return 0
    fi
    print_result_banner fail "取消解密失败" "可手动: sudo veracrypt -d \"$VOLUME_PATH\""
    return 1
}

# 1=挂载  2=取消解密  3=什么都不做
ask_decrypted_unmounted_action() {
    local input dev="${1:-${VC_SLOT_DEV:-}}"
    while true; do
        echo
        echo -e "\e[1;33m VeraCrypt 卷已解密（${dev}），文件系统未挂载。\e[0m"
        echo -e "\e[1;33m   m) 挂载\e[0m"
        echo -e "\e[1;33m   u) 卸载（取消解密状态）\e[0m"
        echo -e "\e[1;36m 直接回车则什么都不做。\e[0m"
        _read_user -p "请选择 [m/u/回车]: " input
        case "$input" in
            m|M) return 1 ;;
            u|U) return 2 ;;
            "") return 3 ;;
            *) prompt -w "请输入 m 或 u，或直接回车取消。" ;;
        esac
    done
}

_ask_umount_if_mounted() {
    local choice
    comfirmy "\e[1;33m VeraCrypt 卷已挂载在 $readMount ，是否卸载？ [Y/n]\e[0m"
    choice=$?
    if [ "$choice" -eq 1 ]; then
        umount_veracrypt
        return $?
    elif [ "$choice" -eq 2 ]; then
        prompt -i "已取消。"
        return 0
    fi
    prompt -e "ERROR:未知返回值!"
    return 5
}

# 交互入口：已挂载问卸载；已解密未挂载问挂载还是取消解密；否则问是否挂载。
interactive_veracrypt() {
    local choice
    if detect_existing_veracrypt_mount; then
        _ask_umount_if_mounted
        return $?
    fi
    if detect_open_veracrypt_slot && [ -n "$VC_SLOT_MP" ]; then
        readMount="$VC_SLOT_MP"
        prompt -k "已挂载(映射设备)" "$readMount"
        _ask_umount_if_mounted
        return $?
    fi
    if detect_open_veracrypt_slot; then
        ask_decrypted_unmounted_action "$VC_SLOT_DEV"
        choice=$?
        if [ "$choice" -eq 1 ]; then
            mount_veracrypt
            return $?
        elif [ "$choice" -eq 2 ]; then
            release_open_veracrypt_slot
            return $?
        elif [ "$choice" -eq 3 ]; then
            prompt -i "已取消。"
            return 0
        fi
        prompt -e "ERROR:未知返回值!"
        return 5
    fi

    comfirmy "\e[1;33m VeraCrypt 卷未挂载，是否挂载？ [Y/n]\e[0m"
    choice=$?
    if [ "$choice" -eq 1 ]; then
        mount_veracrypt
        return $?
    elif [ "$choice" -eq 2 ]; then
        prompt -i "已取消。"
        return 0
    fi
    prompt -e "ERROR:未知返回值!"
    return 5
}

# 只读检查 + 结论样式。不解密、不挂载、不卸载、不安装软件。
# $1 = interactive | mount | umount
dry_run_preview() {
    local mode="${1:-interactive}"
    local state="absent" detail="" mapdev="" mp="" src=""
    local status="未挂载" mapper="无" dir="无" next=""

    if ! resolve_volume quiet; then
        echo
        echo "磁盘: 无法解析"
        echo "状态: 配置有问题"
        echo
        print_result_banner fail "演练失败" "卷配置有问题，真跑也会在这里停"
        return 1
    fi

    if load_last_read_mount "$LIB_DIR"; then
        state="mounted"
        detail="$readMount"
    elif check_mount_point "$readMount"; then
        state="mounted"
        detail="$readMount"
    else
        tcplay_map_name
        mp="$(awk -v name="$TCPLAY_MAP" '
            $1 ~ /^\/dev\/mapper\/veracrypt[0-9]+$/ { print $2; exit }
            $1 == "/dev/mapper/" name { print $2; exit }
        ' /proc/mounts)"
        if [ -n "$mp" ]; then
            state="mounted"
            detail="$mp"
            readMount="$mp"
        fi
    fi

    if [ "$state" = "mounted" ]; then
        status="已挂载"
        dir="$detail"
        src="$(findmnt -n -o SOURCE --mountpoint "$detail" 2>/dev/null || true)"
        if [ -n "$src" ]; then
            mapper="$src"
        fi
    else
        tcplay_map_name
        mapdev="$(ls -d /dev/mapper/veracrypt[0-9]* 2>/dev/null | head -n 1 || true)"
        if [ -z "$mapdev" ] && [ -e "/dev/mapper/$TCPLAY_MAP" ]; then
            mapdev="/dev/mapper/$TCPLAY_MAP"
        fi
        if [ -n "$mapdev" ]; then
            state="decrypted"
            status="已解密，未挂载"
            mapper="$mapdev"
        fi
    fi

    case "$mode" in
        umount)
            case "$state" in
                mounted) next="会卸载 ${dir}，并取消解密" ;;
                decrypted) next="会取消解密" ;;
                *) next="没有挂载，卸载会失败" ;;
            esac
            ;;
        mount)
            case "$state" in
                mounted) next="已经挂着，不会重复挂载" ;;
                decrypted) next="不再问密码，直接挂上文件系统" ;;
                *) next="会询问密码，然后解密并挂载" ;;
            esac
            ;;
        *)
            case "$state" in
                mounted) next="会询问是否卸载" ;;
                decrypted) next="会询问挂载，还是取消解密" ;;
                *) next="会询问是否挂载" ;;
            esac
            ;;
    esac

    prompt -k "磁盘" "$VOLUME_PATH"
    prompt -k "映射" "$mapper"
    prompt -k "状态" "$status"
    prompt -k "目录" "$dir"
    prompt -k "接下来" "$next"
    prompt -i "下面是结论样式，不是这次的真实结果。"
    print_result_banner ok "挂载成功" "（样式预览）"
    print_result_banner fail "挂载失败" "解密失败（样式预览）"
    print_result_banner ok "演练完成" "没有解密，没有挂载，没有卸载"
    return 0
}

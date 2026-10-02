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
            prompt -i "VeraCrypt 容器: $VOLUME_PATH"
            prompt -s " => $VOLUME_PATH <="
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
        prompt -i "VeraCrypt 分区: $VOLUME_PATH"
        prompt -s " => $VOLUME_PATH <="
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

# ext4/xfs 等：卷内有真实 uid。若根目录当前用户写不了，只把「挂载点根」改成该用户。
# 不递归；改动会写进卷内，下次挂载仍然有效。个人 VeraCrypt 卷通常需要这一步。
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

print_mount_plan() {
    local uid gid user
    uid="$(id -u)"
    gid="$(id -g)"
    user="$(id -un)"
    echo
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
    echo
    prompt -s "挂载完成，打开这个目录: $readMount"
    prompt -k "访问目录" "$readMount"
    prompt -k "块设备" "${src:-未知}"
    prompt -k "文件系统" "${fstype:-未知}"
    prompt -k "卷标" "${label:-（无）}"
    prompt -k "当前用户" "$(id -un)  uid=$(id -u)  gid=$(id -g)"
    prompt -k "挂载选项" "${opts:-无}"
    prompt -i "卸载: $LIB_DIR/urmount.sh"
    echo
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
            readMount="$mp"
            prompt -k "已挂载(VeraCrypt)" "$readMount"
            return 0
        fi
    fi
    # 文件系统是用 mount(8) 挂到映射设备上的，veracrypt 列表里可能没有目录。
    if detect_open_veracrypt_slot && [ -n "$VC_SLOT_MP" ]; then
        readMount="$VC_SLOT_MP"
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
        _release_after_mount_fail
        return 1
    fi
    if ! ensure_mount_dir "$readMount"; then
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
        prompt -e "文件系统挂载失败。访问目录 $readMount 没有挂上。"
        _release_after_mount_fail
        return 1
    fi

    # 原生 Linux 文件系统没有 uid= 映射；卷若是 root 格式化的，这里把根目录交还给当前用户
    if [ "$use_owner" -eq 0 ]; then
        if ! fix_native_fs_root_owner "$readMount"; then
            prompt -w "挂载已成功，但写入权限可能仍有问题，请手动: sudo chown $USER:$USER \"$readMount\""
        fi
    fi

    save_last_read_mount "$LIB_DIR"
    print_mount_result
    return 0
}

mount_veracrypt() {
    local mapped_dev
    resolve_veracrypt_bin || return 1
    resolve_volume || return 1

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
        prompt -w "已经挂载: $readMount"
        return 1
    fi

    build_vc_crypto_args || return 1
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
        prompt -e "解密失败。"
        return 1
    fi

    mapped_dev="$(get_veracrypt_mapped_device "$VOLUME_PATH")"
    if [ -z "$mapped_dev" ] || [ ! -e "$mapped_dev" ] || [ "$mapped_dev" = "$VOLUME_PATH" ]; then
        prompt -e "找不到解密后的块设备 /dev/mapper/veracryptN。"
        detach_veracrypt_volume "$VOLUME_PATH"
        return 1
    fi
    prompt -k "解密设备" "$mapped_dev"
    prompt -i "这是中间设备，不会当成你的访问目录。"

    mount_filesystem_from_mapped "$mapped_dev" 0
    return $?
}

umount_veracrypt() {
    local rc=1 mapped=""
    resolve_veracrypt_bin || return 1
    detect_existing_veracrypt_mount || true

    if check_mount_point "$readMount"; then
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
        prompt -s "已卸载 $readMount"
        remove_empty_media_dir "$readMount"
        rm -f "$LIB_DIR/.last-readmount" 2>/dev/null || true
        return 0
    fi
    prompt -e "卸载失败。占用 $readMount 的进程已经列在上面，关掉后再卸。"
    return 1
}

# 只去掉解密槽，不要求文件系统正处于挂载中。
release_open_veracrypt_slot() {
    local dev
    resolve_veracrypt_bin || return 1
    if ! detect_open_veracrypt_slot; then
        prompt -w "没有处于解密状态的 VeraCrypt 卷。"
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
        prompt -s "已取消解密，映射已移除。"
        rm -f "$LIB_DIR/.last-readmount" 2>/dev/null || true
        return 0
    fi
    prompt -e "取消解密失败。可手动: sudo veracrypt -d \"$VOLUME_PATH\""
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

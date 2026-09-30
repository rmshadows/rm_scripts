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

check_mount_point() {
    # 必须用 --mountpoint；--target 会对普通目录误报父挂载
    findmnt -n --mountpoint "$1" >/dev/null 2>&1
}

resolve_veracrypt_bin() {
    local custom="$VERACRYPT_CUSTOM"

    # 相对路径按脚本目录解析，跟 BitLocker 的 DISLOCKER_CUSTOM 一样。
    if [ -n "$custom" ] && [[ "$custom" != /* ]]; then
        custom="$LIB_DIR/$custom"
    fi

    if [ -n "${VERACRYPT_CUSTOM:-}" ]; then
        if [ -x "$custom" ]; then
            VERACRYPT_BIN="$custom"
            prompt -i "使用指定的 veracrypt: $VERACRYPT_BIN"
            return 0
        fi
        prompt -e "VERACRYPT_CUSTOM 不可执行: ${VERACRYPT_CUSTOM}"
        prompt -i "可用 Other/apt/collect_binary_with_deps.sh 打包离线 veracrypt，再指向该目录下的启动脚本。"
        return 1
    fi

    if command -v veracrypt >/dev/null 2>&1; then
        VERACRYPT_BIN="$(command -v veracrypt)"
        prompt -i "使用系统 veracrypt: $VERACRYPT_BIN"
        return 0
    fi

    prompt -w "未找到 veracrypt，尝试 apt install..."
    if sudo apt install veracrypt -y; then
        if command -v veracrypt >/dev/null 2>&1; then
            VERACRYPT_BIN="$(command -v veracrypt)"
            prompt -i "安装成功，使用系统 veracrypt: $VERACRYPT_BIN"
            return 0
        fi
    fi

    prompt -e "仍未找到 veracrypt。"
    prompt -i "当前 apt 源若没有这个包，请从 https://www.veracrypt.fr/en/Downloads.html 安装 .deb，"
    prompt -i "或用 Other/apt/collect_binary_with_deps.sh 打离线包，在 config.sh 里设置 VERACRYPT_CUSTOM。"
    return 1
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

fs_needs_owner_options() {
    local fstype
    fstype="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
    case "$fstype" in
        ntfs|fuseblk|vfat|fat|fat12|fat16|fat32|exfat|msdos) return 0 ;;
        *) return 1 ;;
    esac
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
        opts+=("uid=$(id -u)" "gid=$(id -g)")
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
    prompt -i "解密后会出现中间设备 /dev/mapper/veracryptN，文件管理器进的是访问目录。"
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
    line="$(sudo "$VERACRYPT_BIN" --text -l "$VOLUME_PATH" 2>/dev/null | head -n 1 || true)"
    mp="$(printf '%s\n' "$line" | awk '{print $NF}')"
    if [ -n "$mp" ] && [ "$mp" != "-" ] && [[ "$mp" == /* ]] && check_mount_point "$mp"; then
        readMount="$mp"
        prompt -k "已挂载(VeraCrypt)" "$readMount"
        return 0
    fi
    return 1
}

mount_veracrypt() {
    local mapped_dev fstype use_owner=0 owner_uid owner_gid vol_label=""
    resolve_veracrypt_bin || return 1
    resolve_volume || return 1
    build_vc_crypto_args || return 1
    print_mount_plan

    if [ -n "${keyPass:-}" ]; then
        prompt -m "使用 config.sh 里的密码解密 $VOLUME_PATH"
    else
        prompt -m "请输入 $VOLUME_PATH 的 VeraCrypt 密码（只输一次）。"
    fi

    # 先只解开加密层，探测文件系统/卷标，再决定访问目录。
    prompt -x "解密（先不挂文件系统）: $VOLUME_PATH"
    if ! sudo "$VERACRYPT_BIN" "${VC_CRYPTO_ARGS[@]}" --filesystem=none "$VOLUME_PATH"; then
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
        detach_veracrypt_volume "$VOLUME_PATH"
        detach_veracrypt_volume "$mapped_dev"
        return 1
    fi
    ensure_mount_dir "$readMount" || {
        detach_veracrypt_volume "$VOLUME_PATH"
        detach_veracrypt_volume "$mapped_dev"
        return 1
    }

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
        detach_veracrypt_volume "$VOLUME_PATH"
        detach_veracrypt_volume "$mapped_dev"
        return 1
    fi

    save_last_read_mount "$LIB_DIR"
    print_mount_result
    return 0
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
            prompt -w "仍尝试非交互卸载 VeraCrypt 映射（不再询问紧急清理）。"
            if sudo "$VERACRYPT_BIN" --text --non-interactive --unmount "$readMount"; then
                rc=0
            fi
        fi
    else
        prompt -w "挂载点未挂载: $readMount"
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

#!/bin/bash
# 单独创建 / 查看 / 挂载 qcow2 磁盘（稀疏分配，用多少占多少）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=kvm_lib.sh
source "$SCRIPT_DIR/kvm_lib.sh"

DISK_SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
用法: ${DISK_SCRIPT_NAME} <命令> [参数...]

仅管理 qcow2 磁盘文件（不创建完整 VM）。qcow2 稀疏分配：虚拟大小固定，实际占用随写入增长。

命令:
  create [选项] [名称] [大小GiB]   创建空 qcow2（无参数=向导）
  info <路径>                      查看虚拟大小 / 实际占用
  attach [VM] <路径> [设备]        挂载到已有 VM（需关机，默认 vdb）
  pool list                        列出存储池

create 选项:
  -p, --pool POOL    存储池（如 KVM、KVM_W）；省略则交互选择

示例:
  ${DISK_SCRIPT_NAME} create                         # 向导
  ${DISK_SCRIPT_NAME} create -p KVM_W data 64        # 64GiB 到外置池
  ${DISK_SCRIPT_NAME} info /media/jessie/data.qcow2
  ${DISK_SCRIPT_NAME} attach debian11 /path/disk.qcow2 vdb

创建完整 VM 请用: ./6-kvm_create.sh

EOF
}

cmd_pool_list() {
    kvm_heading "libvirt 存储池"
    echo
    kvm_virsh pool-list --all
    echo
    local p path cap avail
    printf "  %-12s  %-32s  %10s  %10s\n" "池名" "路径" "总容量GiB" "可用GiB"
    printf "  %s\n" "$(printf '%.0s-' {1..72})"
    while IFS= read -r p; do
        [ -n "$p" ] || continue
        path=$(kvm_pool_path "$p")
        cap=$(kvm_pool_capacity_gib "$p" cap)
        avail=$(kvm_pool_capacity_gib "$p" avail)
        printf "  %-12s  %-32s  %10s  %10s\n" "$p" "$path" "${cap:-?}" "${avail:-?}"
    done < <(kvm_pool_names)
}

kvm_disk_normalize_name() {
    local name="$1"
    [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || \
        kvm_die "名称以字母数字开头，仅允许字母数字及 ._-"
    [[ "$name" == *.qcow2 ]] || name="${name}.qcow2"
    echo "$name"
}

cmd_info() {
    local path="$1"
    [ -f "$path" ] || kvm_die "文件不存在: $path"
    command -v qemu-img &>/dev/null || kvm_die "需要 qemu-img: sudo apt install qemu-utils"
    kvm_heading "qcow2: $path"
    echo
    qemu-img info "$path"
    echo
    kvm_info "virtual size = VM 看到的容量；disk size = 宿主机实际占用"
}

cmd_create() {
    local pool="" name="" size_gb=""
    while [ $# -gt 0 ]; do
        case "$1" in
            -p|--pool) pool="$2"; shift 2 ;;
            -*) kvm_die "未知选项: $1" ;;
            *)
                if [ -z "$name" ]; then name="$1"
                elif [ -z "$size_gb" ]; then size_gb="$1"
                else kvm_die "多余参数: $1"
                fi
                shift
                ;;
        esac
    done

    if [ -z "$pool" ]; then
        [ -t 0 ] || kvm_die "请指定 -p 存储池，或交互运行"
        pool=$(kvm_pool_pick) || return 0
    fi
    kvm_pool_ensure_active "$pool"
    local pool_dir
    pool_dir=$(kvm_pool_path "$pool")

    if [ -z "$name" ]; then
        echo -n "磁盘文件名（如 data，自动加 .qcow2）: " >&2
        read -r name
    fi
    [ -n "$name" ] || kvm_die "名称不能为空"
    name=$(kvm_disk_normalize_name "$name")

    if [ -z "$size_gb" ]; then
        echo -n "虚拟大小 GiB [32]: " >&2
        read -r size_gb
        size_gb="${size_gb:-32}"
    fi
    [[ "$size_gb" =~ ^[0-9]+$ ]] && [ "$size_gb" -ge 1 ] || kvm_die "大小须为正整数 GiB"

    local disk_path="${pool_dir}/${name}"
    [ ! -e "$disk_path" ] || kvm_die "已存在: $disk_path"

    command -v qemu-img &>/dev/null || kvm_die "需要 qemu-img: sudo apt install qemu-utils"

    kvm_heading "创建 qcow2"
    echo "  存储池:   $pool"
    echo "  路径:     $disk_path"
    echo "  虚拟大小: ${size_gb} GiB（稀疏，初始占用很小）"
    echo
    if [ -t 0 ]; then
        kvm_confirm "确认创建?" || kvm_die "已取消"
    fi

    kvm_info "qemu-img create -f qcow2 ..."
    qemu-img create -f qcow2 "$disk_path" "${size_gb}G"
    kvm_disk_fix_permissions "$disk_path"
    kvm_ok "已创建: $disk_path"
    echo
    cmd_info "$disk_path"

    if [ -t 0 ]; then
        echo
        echo -n "挂载到已有虚拟机? [y/N]: " >&2
        read -r ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            local domain target
            domain=$(kvm_resolve_domain "") || return 0
            echo -n "设备名 [vdb]: " >&2
            read -r target
            target="${target:-vdb}"
            cmd_attach "$domain" "$disk_path" "$target"
        fi
    fi
}

cmd_attach() {
    local domain="$1" disk_path="$2" target="${3:-vdb}"

    [ -f "$disk_path" ] || kvm_die "磁盘不存在: $disk_path"
    kvm_require_shutoff "$domain"

    kvm_info "挂载: $disk_path -> $domain ($target)"
    kvm_virsh attach-disk "$domain" "$disk_path" "$target" \
        --driver qemu --subdriver qcow2 --targetbus virtio --persistent --config
    kvm_ok "已挂载（下次启动生效）: $target <- $disk_path"
}

menu_interactive() {
    kvm_require_tty
    while true; do
        clear 2>/dev/null || true
        kvm_heading "qcow2 磁盘"
        echo
        echo "  1) 创建空 qcow2（选存储池 / 外置盘）"
        echo "  2) 查看磁盘占用（virtual vs disk size）"
        echo "  3) 挂载到已有 VM"
        echo "  4) 列出存储池"
        echo "  q) 返回上级"
        echo
        echo -n "请选择（空回车返回上级）: "
        read -r choice || true
        echo

        case "$choice" in
            1)
                cmd_create
                kvm_menu_pause || break
                ;;
            2)
                echo -n "qcow2 路径: "
                read -r path || true
                cmd_info "$path"
                kvm_menu_pause || break
                ;;
            3)
                local domain disk target
                domain=$(kvm_resolve_domain "") || continue
                echo -n "qcow2 路径: "
                read -r disk || true
                echo -n "设备名 [vdb]: "
                read -r target || true
                cmd_attach "$domain" "$disk" "${target:-vdb}"
                kvm_menu_pause || break
                ;;
            4)
                cmd_pool_list
                kvm_menu_pause || break
                ;;
            ""|q|Q)
                break
                ;;
            *)
                kvm_warn "无效选择: $choice"
                sleep 1
                ;;
        esac
    done
}

main() {
    if [ $# -lt 1 ]; then
        kvm_ensure_config
        kvm_require_virsh
        menu_interactive
        exit 0
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        -h|--help|help)
            usage
            exit 0
            ;;
    esac

    kvm_ensure_config
    kvm_require_virsh

    case "$cmd" in
        create)
            cmd_create "$@"
            ;;
        info)
            [ $# -ge 1 ] || kvm_die "用法: ${DISK_SCRIPT_NAME} info <路径>"
            cmd_info "$1"
            ;;
        attach)
            local domain disk target="vdb"
            case $# in
                0)
                    domain=$(kvm_resolve_domain "")
                    echo -n "qcow2 路径: " >&2
                    read -r disk
                    [ -n "$disk" ] || kvm_die "路径不能为空"
                    ;;
                1)
                    if kvm_domain_exists "$1"; then
                        domain="$1"
                        echo -n "qcow2 路径: " >&2
                        read -r disk
                    else
                        domain=$(kvm_resolve_domain "")
                        disk="$1"
                    fi
                    ;;
                *)
                    domain=$(kvm_resolve_domain "$1")
                    disk="$2"
                    target="${3:-vdb}"
                    ;;
            esac
            cmd_attach "$domain" "$disk" "$target"
            ;;
        pool)
            [ "${1:-list}" = "list" ] || kvm_die "用法: ${DISK_SCRIPT_NAME} pool list"
            cmd_pool_list
            ;;
        *)
            usage
            kvm_die "未知命令: $cmd"
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

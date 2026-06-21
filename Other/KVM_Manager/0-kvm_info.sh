#!/bin/bash
# 查看 KVM 虚拟机信息：列表、状态、资源、磁盘、网络、快照概要

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=kvm_lib.sh
source "$SCRIPT_DIR/kvm_lib.sh"

usage() {
    cat <<'EOF'
用法: kvm_info.sh [选项] [虚拟机名称]

查看 libvirt/KVM 虚拟机信息（不依赖 virt-manager GUI）。

选项:
  -a, --all           显示所有虚拟机的简要列表（默认无参数时）
  -d, --detail NAME   显示指定虚拟机的详细信息
  -s, --snapshots     在详细信息中包含快照列表
  -S, --setup         重新配置 libvirt 连接（写入 kvm.local.conf）
  -h, --help          显示此帮助

示例:
  kvm_info.sh                    # 列出全部 VM
  kvm_info.sh -d myvm            # 查看 myvm 详情
  kvm_info.sh -d myvm -s         # 含快照列表
  kvm_info.sh myvm               # 同 -d myvm

EOF
}

show_vm_brief() {
    local name="$1"
    local state uuid cpu mem xml_path primary_disk
    state=$(kvm_virsh domstate "$name" 2>/dev/null || echo "unknown")
    uuid=$(kvm_virsh domuuid "$name" 2>/dev/null || echo "-")
    read -r cpu mem _ < <(kvm_virsh dominfo "$name" 2>/dev/null | awk '
        /CPU/ && !/CPU 时间/ {
            if (match($0, /[0-9]+/)) { cpu=substr($0, RSTART, RLENGTH) }
        }
        /Max memory|最大内存/ {
            if (match($0, /[0-9]+/)) { mem=substr($0, RSTART, RLENGTH) }
        }
        END { print cpu+0, mem+0 }
    ')
    local mem_h
    mem_h=$(kvm_format_kib "${mem:-0}")
    xml_path=$(kvm_domain_xml_path "$name")
    primary_disk=$(kvm_domain_primary_disk "$name")
    [ -n "$primary_disk" ] || primary_disk="（无磁盘）"
    printf "  %-28s  %-12s  CPU:%-3s  内存:%-10s  %s\n" "$name" "$state" "${cpu:-?}" "$mem_h" "$uuid"
    printf "    定义: %s\n" "$xml_path"
    printf "    磁盘: %s\n" "$primary_disk"
}

show_vm_list() {
    kvm_heading "虚拟机列表"
    kvm_info "连接: ${KVM_VIRSH_URI:-默认}"
    printf "  %-28s  %-12s  %-7s  %-10s  %s\n" "名称" "状态" "CPU" "内存" "UUID"
    printf "  %s\n" "$(printf '%.0s-' {1..80})"
    local name
    while IFS= read -r name; do
        [ -n "$name" ] && show_vm_brief "$name"
    done < <(kvm_list_domains)
    echo
    local count
    count=$(kvm_list_domains | wc -l)
    kvm_info "共 ${count} 台虚拟机"
}

show_block_info() {
    local name="$1"
    kvm_heading "磁盘"
    kvm_virsh domblklist "$name" --details 2>/dev/null || kvm_warn "无法读取磁盘列表"
}

show_location_info() {
    local name="$1"
    local xml_path disk path
    kvm_heading "位置"
    xml_path=$(kvm_domain_xml_path "$name")
    echo "  定义 XML:  $xml_path"
    if [ -f "$xml_path" ]; then
        echo "            （存在）"
    else
        kvm_warn "定义文件当前不可读: $xml_path"
    fi
    echo "  磁盘镜像:"
    local found=0
    while IFS= read -r disk; do
        [ -n "$disk" ] || continue
        found=1
        if [[ "$disk" == \[volume:* ]]; then
            printf "    - %s\n" "$disk"
        elif [ -e "$disk" ]; then
            printf "    - %s\n" "$disk"
        else
            printf "    - %s （文件不存在）\n" "$disk"
        fi
    done < <(kvm_domain_disk_paths "$name")
    if [ "$found" -eq 0 ]; then
        echo "    （无磁盘设备）"
    fi
    path=$(kvm_domain_primary_disk "$name")
    if [ -n "$path" ] && [[ "$path" != \[volume:* ]]; then
        echo "  数据目录:  $(dirname "$path")/"
    fi
}

show_net_info() {
    local name="$1"
    kvm_heading "网络接口"
    kvm_virsh domiflist "$name" 2>/dev/null || kvm_warn "无法读取网卡列表"
    if kvm_virsh domstate "$name" 2>/dev/null | grep -q running; then
        echo
        kvm_virsh domifaddr "$name" 2>/dev/null || true
    fi
}

show_snapshots() {
    local name="$1"
    kvm_heading "快照"
    local out
    if ! out=$(kvm_virsh snapshot-list "$name" 2>&1); then
        kvm_warn "$out"
        return
    fi
    local lines
    lines=$(echo "$out" | tail -n +3 | sed '/^$/d' | wc -l)
    if [ "${lines:-0}" -eq 0 ]; then
        echo "  （无快照）"
    else
        echo "$out"
    fi
}

show_vm_detail() {
    local name="$1"
    local with_snapshots="${2:-0}"

    kvm_heading "虚拟机: $name"
    echo
    kvm_info "连接: ${KVM_VIRSH_URI:-默认}"
    echo
    kvm_virsh dominfo "$name"
    echo

    show_location_info "$name"
    echo
    show_block_info "$name"
    echo
    show_net_info "$name"
    echo

    if [ "$with_snapshots" -eq 1 ]; then
        show_snapshots "$name"
        echo
    fi

    kvm_heading "XML 配置"
    echo "  virsh -c '${KVM_VIRSH_URI}' dumpxml $name"
    echo
    kvm_info "完整 XML: virsh -c '${KVM_VIRSH_URI}' dumpxml '$name' | less"
}

menu_interactive() {
    kvm_require_tty
    while true; do
        clear 2>/dev/null || true
        kvm_heading "查看虚拟机"
        echo
        echo "  1) 列出全部虚拟机"
        echo "  2) 查看某台详情"
        echo "  3) 详情 + 快照列表"
        echo "  q) 返回上级"
        echo
        echo -n "请选择（空回车返回上级）: "
        read -r choice || true
        echo

        local domain
        case "$choice" in
            1)
                show_vm_list
                kvm_menu_pause || break
                ;;
            2)
                domain=$(kvm_resolve_domain "") || continue
                show_vm_detail "$domain" 0
                kvm_menu_pause || break
                ;;
            3)
                domain=$(kvm_resolve_domain "") || continue
                show_vm_detail "$domain" 1
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

    local mode="list"
    local domain=""
    local with_snapshots=0
    local force_setup=0

    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -S|--setup)
                force_setup=1
                shift
                ;;
            -a|--all)
                mode="list"
                shift
                ;;
            -d|--detail)
                mode="detail"
                shift
                if [ $# -gt 0 ] && [[ "$1" != -* ]]; then
                    domain="$1"
                    shift
                fi
                ;;
            -s|--snapshots)
                with_snapshots=1
                shift
                ;;
            -*)
                kvm_die "未知选项: $1（使用 -h 查看帮助）"
                ;;
            *)
                mode="detail"
                domain="$1"
                shift
                ;;
        esac
    done

    if [ "$force_setup" -eq 1 ]; then
        export KVM_FORCE_SETUP=1
    fi
    kvm_ensure_config
    kvm_require_virsh
    if [ "$force_setup" -eq 1 ]; then
        exit 0
    fi

    case "$mode" in
        list)
            show_vm_list
            ;;
        detail)
            if [ -z "$domain" ]; then
                domain=$(kvm_resolve_domain "")
            fi
            show_vm_detail "$domain" "$with_snapshots"
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

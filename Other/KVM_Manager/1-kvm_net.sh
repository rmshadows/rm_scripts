#!/bin/bash
# libvirt 网络查看与 VM 网卡模式切换（NAT / 桥接）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=kvm_lib.sh
source "$SCRIPT_DIR/kvm_lib.sh"

usage() {
    cat <<'EOF'
用法: kvm_net.sh <命令> [参数...]

网络管理（修改网卡需 VM 已关机）。

命令:
  list                   列出 libvirt 虚拟网络（default 等）
  start [NET]            启动虚拟网络（默认 default）
  stop [NET]             停止虚拟网络
  autostart on|off [NET] 设置虚拟网络开机自启
  bridges                列出宿主机网桥
  show [VM]              查看 VM 网卡配置
  switch [VM]            交互切换 NAT / 桥接（关机状态下生效）

示例:
  kvm_net.sh list
  kvm_net.sh start default
  kvm_net.sh autostart on default
  kvm_net.sh show debian13
  kvm_net.sh switch test_disk

说明:
  NAT     — type=network, 通常接 default（192.168.122.0/24）
  桥接    — type=bridge,  接到宿主机 br0 / virbr 等，VM 与局域网同级

EOF
}

cmd_list_nets() {
    kvm_heading "libvirt 虚拟网络"
    kvm_info "连接: ${KVM_VIRSH_URI:-默认}"
    echo
    kvm_virsh net-list --all
}

cmd_list_bridges() {
    kvm_heading "宿主机网桥"
    if command -v ip &>/dev/null; then
        ip -br link show type bridge 2>/dev/null || ip link show type bridge
    elif command -v brctl &>/dev/null; then
        brctl show
    else
        kvm_die "未找到 ip 或 brctl，无法列出网桥"
    fi
}

# 从 dumpxml 解析第一块网卡：type network bridge mac
kvm_parse_primary_iface() {
    local domain="$1"
    kvm_virsh dumpxml "$domain" | awk '
        /<interface / {
            split($0, a, "'\''")
            type=a[2]
            net=""; br=""; mac=""
            in_iface=1
        }
        in_iface {
            if (/<source network='"'"'/) { split($0, a, "'\''"); net=a[2] }
            if (/<source bridge='"'"'/) { split($0, a, "'\''"); br=a[2] }
            if (/<mac address='"'"'/) { split($0, a, "'\''"); mac=a[2] }
        }
        in_iface && /<\/interface>/ {
            print type "|" net "|" br "|" mac
            in_iface=0
            exit
        }
    '
}

cmd_net_start() {
    local net="${1:-default}"
    kvm_net_start "$net"
}

cmd_net_stop() {
    local net="${1:-default}"
    kvm_virsh net-info "$net" &>/dev/null || kvm_die "虚拟网络不存在: $net"
    if ! kvm_net_is_active "$net"; then
        kvm_warn "虚拟网络未运行: $net"
        return 0
    fi
    kvm_info "停止虚拟网络: $net"
    kvm_virsh net-destroy "$net"
    kvm_ok "已停止: $net"
}

cmd_net_autostart() {
    local mode="${1:-}"
    local net="${2:-default}"
    [ -n "$mode" ] || kvm_die "用法: kvm_net.sh autostart on|off [网络名]"
    case "$mode" in
        on|enable|yes|1)
            kvm_virsh net-autostart "$net"
            kvm_ok "已启用虚拟网络自启动: $net"
            ;;
        off|disable|no|0)
            kvm_virsh net-autostart --disable "$net"
            kvm_ok "已禁用虚拟网络自启动: $net"
            ;;
        *)
            kvm_die "autostart 参数应为 on 或 off，收到: $mode"
            ;;
    esac
}

cmd_show() {
    local domain="$1"
    kvm_heading "虚拟机网卡: $domain"
    echo
    kvm_virsh domiflist "$domain" 2>/dev/null || true
    echo
    local type net br mac
    IFS='|' read -r type net br mac < <(kvm_parse_primary_iface "$domain")
    if [ -z "${type:-}" ]; then
        kvm_warn "未找到网卡配置"
        return
    fi
    echo "  类型:   $type"
    if [ "$type" = "network" ]; then
        echo "  模式:   NAT / 虚拟网络"
        echo "  网络:   ${net:-?}"
    elif [ "$type" = "bridge" ]; then
        echo "  模式:   桥接"
        echo "  网桥:   ${br:-?}"
    else
        echo "  模式:   $type"
    fi
    echo "  MAC:    ${mac:-?}"
    if kvm_domain_is_running "$domain"; then
        echo
        kvm_virsh domifaddr "$domain" 2>/dev/null || true
    fi
}

cmd_switch() {
    local domain="$1"
    kvm_require_shutoff "$domain"

    local type net br mac
    IFS='|' read -r type net br mac < <(kvm_parse_primary_iface "$domain")
    [ -n "${mac:-}" ] || kvm_die "无法读取网卡 MAC"

    kvm_heading "切换网卡: $domain"
    echo "  当前: type=$type network=${net:-} bridge=${br:-} mac=$mac"
    echo
    echo "  1) NAT（libvirt 虚拟网络 default）"
    echo "  2) 桥接（宿主机网桥）"
    echo -n "请选择 [1/2]: "
    read -r choice

    case "$choice" in
        1)
            echo -n "虚拟网络名称 [default]: "
            read -r net_name
            net_name="${net_name:-default}"
            kvm_info "切换为 NAT: network=$net_name"
            kvm_virsh detach-interface "$domain" --type "$type" --mac "$mac" --config
            kvm_virsh attach-interface "$domain" \
                --type network --source "$net_name" \
                --model virtio --mac "$mac" --config
            kvm_ok "已切换为 NAT（$net_name），下次启动生效"
            ;;
        2)
            echo "可用网桥："
            cmd_list_bridges
            echo
            echo -n "网桥名称（如 br0）: "
            read -r bridge_name
            [ -n "$bridge_name" ] || kvm_die "网桥名称不能为空"
            kvm_info "切换为桥接: bridge=$bridge_name"
            kvm_virsh detach-interface "$domain" --type "$type" --mac "$mac" --config
            kvm_virsh attach-interface "$domain" \
                --type bridge --source "$bridge_name" \
                --model virtio --mac "$mac" --config
            kvm_ok "已切换为桥接（$bridge_name），下次启动生效"
            ;;
        *)
            kvm_die "无效选择: $choice"
            ;;
    esac
    echo
    cmd_show "$domain"
}

menu_interactive() {
    kvm_require_tty
    while true; do
        clear 2>/dev/null || true
        kvm_heading "网络管理"
        echo
        echo "  1) 列出虚拟网络（default 等）"
        echo "  2) 列出宿主机网桥"
        echo "  3) 查看某 VM 网卡"
        echo "  4) 切换 NAT / 桥接（需 VM 已关机）"
        echo "  5) 启动虚拟网络"
        echo "  6) 停止虚拟网络"
        echo "  7) 虚拟网络开机自启"
        echo "  q) 返回上级"
        echo
        echo -n "请选择（空回车返回上级）: "
        read -r choice || true
        echo

        local domain net mode
        case "$choice" in
            1)
                cmd_list_nets
                kvm_menu_pause || break
                ;;
            2)
                cmd_list_bridges
                kvm_menu_pause || break
                ;;
            3)
                domain=$(kvm_resolve_domain "") || continue
                cmd_show "$domain"
                kvm_menu_pause || break
                ;;
            4)
                domain=$(kvm_resolve_domain "") || continue
                cmd_switch "$domain"
                kvm_menu_pause || break
                ;;
            5)
                echo -n "网络名 [default]: "
                read -r net || true
                cmd_net_start "${net:-default}"
                kvm_menu_pause || break
                ;;
            6)
                echo -n "网络名 [default]: "
                read -r net || true
                cmd_net_stop "${net:-default}"
                kvm_menu_pause || break
                ;;
            7)
                echo -n "on 还是 off? [on/off]: "
                read -r mode || true
                echo -n "网络名 [default]: "
                read -r net || true
                cmd_net_autostart "${mode:-on}" "${net:-default}"
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
        list)
            cmd_list_nets
            ;;
        start|up)
            cmd_net_start "${1:-default}"
            ;;
        stop|down)
            cmd_net_stop "${1:-default}"
            ;;
        autostart)
            [ $# -ge 1 ] || kvm_die "用法: kvm_net.sh autostart on|off [网络名]"
            cmd_net_autostart "$1" "${2:-default}"
            ;;
        bridges)
            cmd_list_bridges
            ;;
        show)
            cmd_show "$(kvm_resolve_domain "${1:-}")"
            ;;
        switch)
            cmd_switch "$(kvm_resolve_domain "${1:-}")"
            ;;
        *)
            kvm_die "未知命令: $cmd（使用 -h 查看帮助）"
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

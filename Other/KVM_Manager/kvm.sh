#!/bin/bash
# KVM Manager 总菜单（推荐入口：无需记命令）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=kvm_lib.sh
source "$SCRIPT_DIR/kvm_lib.sh"

kvm_main_menu() {
    kvm_require_tty
    kvm_ensure_config
    kvm_require_virsh

    while true; do
        clear 2>/dev/null || true
        kvm_heading "KVM Manager"
        kvm_info "连接: ${KVM_VIRSH_URI:-默认}  |  写入操作请用 sudo ./kvm.sh"
        echo
        echo "  1) 查看虚拟机      (信息 / 详情 / 快照)"
        echo "  2) 电源与控制台    (启动 / 关机 / 界面)"
        echo "  3) 网络管理        (NAT / 桥接 / default 网)"
        echo "  4) 磁盘 qcow2      (创建 / 查看 / 挂载)"
        echo "  5) 共享文件夹      (9p 目录共享)"
        echo "  6) 快照            (创建 / 恢复 / 删除)"
        echo "  7) 新建虚拟机      (完整向导)"
        echo "  8) 配置连接        (libvirt URI)"
        echo "  q) 退出"
        echo
        echo -n "请选择（空回车退出）: "
        read -r choice || true
        echo

        case "$choice" in
            1) "$SCRIPT_DIR/0-kvm_info.sh" || true ;;
            2) "$SCRIPT_DIR/3-kvm_vm.sh" || true ;;
            3) "$SCRIPT_DIR/1-kvm_net.sh" || true ;;
            4) "$SCRIPT_DIR/2-kvm_disk.sh" || true ;;
            5) "$SCRIPT_DIR/4-kvm_share.sh" || true ;;
            6) "$SCRIPT_DIR/5-kvm_snapshot.sh" || true ;;
            7) "$SCRIPT_DIR/6-kvm_create.sh" || true ;;
            8)
                export KVM_FORCE_SETUP=1
                "$SCRIPT_DIR/0-kvm_info.sh" --setup || true
                kvm_menu_pause || true
                ;;
            ""|q|Q|quit|exit)
                exit 0
                ;;
            *)
                kvm_warn "无效选择: $choice"
                sleep 1
                ;;
        esac
    done
}

kvm_main_menu

#!/bin/bash
# 交互式新建 KVM 虚拟机（存储池 / 位置 / ISO / 资源）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=kvm_lib.sh
source "$SCRIPT_DIR/kvm_lib.sh"

CREATE_SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
用法: ${CREATE_SCRIPT_NAME} [选项]

交互式新建虚拟机（不依赖 virt-manager GUI）。
磁盘创建在 libvirt 存储池中（如 home 的 KVM、外置的 KVM_W）。

选项:
  -h, --help     显示帮助
  pool list      列出存储池及容量

示例:
  ${CREATE_SCRIPT_NAME}              # 启动向导
  ${CREATE_SCRIPT_NAME} pool list

创建后:
  sudo ./3-kvm_vm.sh start --view <名称>
  ./0-kvm_info.sh -d <名称>

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

kvm_validate_vm_name() {
    local name="$1"
    [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || \
        kvm_die "VM 名称以字母数字开头，仅允许字母数字及 ._-"
    kvm_domain_exists "$name" && kvm_die "虚拟机已存在: $name"
}

# 生成并 define 域 XML
kvm_create_define_xml() {
    local name="$1" disk_path="$2" mem_kib="$3" vcpus="$4" iso_path="${5:-}"

    local uuid
    uuid=$(uuidgen)

    local -a boot_lines=( "<boot dev='hd'/>" )
    local cdrom_xml=""
    if [ -n "$iso_path" ]; then
        boot_lines=( "<boot dev='cdrom'/>" "<boot dev='hd'/>" )
        cdrom_xml="
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='${iso_path}'/>
      <target dev='sda' bus='sata'/>
      <readonly/>
    </disk>"
    fi

    local xml tmp
    tmp=$(mktemp)
    cat > "$tmp" <<EOF
<domain type='kvm'>
  <name>${name}</name>
  <uuid>${uuid}</uuid>
  <memory unit='KiB'>${mem_kib}</memory>
  <currentMemory unit='KiB'>${mem_kib}</currentMemory>
  <vcpu placement='static'>${vcpus}</vcpu>
  <os>
    <type arch='x86_64' machine='pc-q35-10.0'>hvm</type>
    $(printf '%s\n' "${boot_lines[@]}")
  </os>
  <features>
    <acpi/>
    <apic/>
    <vmport state='off'/>
  </features>
  <cpu mode='host-passthrough' check='none' migratable='on'/>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='${disk_path}'/>
      <target dev='vda' bus='virtio'/>
    </disk>${cdrom_xml}
    <interface type='network'>
      <source network='default'/>
      <model type='virtio'/>
    </interface>
    <graphics type='spice' autoport='yes' listen='127.0.0.1'>
      <listen type='address' address='127.0.0.1'/>
    </graphics>
    <video>
      <model type='virtio' heads='1' primary='yes'/>
    </video>
    <channel type='unix'>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
    </channel>
    <channel type='spicevmc'>
      <target type='virtio' name='com.redhat.spice.0'/>
    </channel>
    <input type='tablet' bus='usb'/>
    <input type='keyboard' bus='ps2'/>
    <memballoon model='virtio'/>
    <rng model='virtio'>
      <backend model='random'>/dev/urandom</backend>
    </rng>
  </devices>
</domain>
EOF

    local out rc=0
    if out=$(kvm_virsh define "$tmp" 2>&1); then
        kvm_ok "$out"
    else
        rc=$?
        rm -f "$tmp"
        echo "$out" >&2
        return "$rc"
    fi
    rm -f "$tmp"
    return 0
}

wizard_create() {
    [ -t 0 ] || kvm_die "请在本机终端交互运行: ${CREATE_SCRIPT_NAME}"
    kvm_require_libvirt_write

    kvm_heading "新建 KVM 虚拟机"
    echo
    kvm_info "向导步骤: 名称 → 安装方式 → 存储位置 → 资源 → 确认"
    echo

    # 1. 名称（已存在则显示位置并重新输入）
    local vm_name=""
    while true; do
        echo -n "虚拟机名称（如 my-debian）: "
        read -r vm_name || true
        if [ -z "$vm_name" ]; then
            kvm_warn "名称不能为空"
            continue
        fi
        if ! [[ "$vm_name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
            kvm_warn "名称须以字母数字开头，仅允许字母数字及 ._-"
            continue
        fi
        if kvm_domain_exists "$vm_name"; then
            kvm_warn "名称已被占用: $vm_name（不会覆盖，请换名）"
            kvm_print_domain_location "$vm_name"
            echo
            continue
        fi
        break
    done

    # 2. 创建方式
    echo
    echo "创建方式:"
    echo "  1) 从 ISO 安装（挂光盘 + 空硬盘）"
    echo "  2) 仅空硬盘（稍后自行挂 ISO）"
    echo "  3) 导入已有 qcow2 镜像（cloud 镜像等）"
    local mode="" iso_path="" import_src=""
    while true; do
        echo -n "请选择 [1/2/3]: "
        read -r mode || true
        case "$mode" in
            1)
                echo -n "ISO 路径: "
                read -r iso_path || true
                if [ -f "$iso_path" ]; then
                    break
                fi
                kvm_warn "ISO 不存在: ${iso_path:-（空）}"
                ;;
            2)
                iso_path=""
                import_src=""
                break
                ;;
            3)
                echo -n "qcow2 源文件路径: "
                read -r import_src || true
                if [ -f "$import_src" ]; then
                    break
                fi
                kvm_warn "文件不存在: ${import_src:-（空）}"
                ;;
            *)
                kvm_warn "无效选择: ${mode:-（空）}"
                ;;
        esac
    done

    # 3. 存储位置
    echo
    kvm_heading "磁盘存放位置"
    kvm_info "qcow2 将保存为: <存储池目录>/${vm_name}.qcow2"
    echo
    local pool disk_path pool_dir
    pool=$(kvm_pool_pick) || return
    kvm_pool_ensure_active "$pool"
    pool_dir=$(kvm_pool_path "$pool")
    disk_path="${pool_dir}/${vm_name}.qcow2"
    if [ -e "$disk_path" ]; then
        kvm_warn "磁盘文件已存在，无法继续: $disk_path"
        return
    fi
    kvm_ok "已选存储池 [$pool]"
    echo "  目录:     $pool_dir"
    echo "  将创建:   $disk_path"
    echo

    # 4. 磁盘大小（导入模式可跳过或覆盖）
    local disk_gb=32
    if [ "$mode" = "3" ]; then
        kvm_info "将导入: $import_src -> $disk_path"
    else
        echo -n "磁盘大小 GiB [32]: "
        read -r disk_gb_in || true
        disk_gb="${disk_gb_in:-32}"
        if ! [[ "$disk_gb" =~ ^[0-9]+$ ]] || [ "$disk_gb" -lt 1 ]; then
            kvm_warn "磁盘大小须为正整数 GiB"
            return
        fi
    fi

    # 5. 内存 / CPU
    local mem_gb vcpus
    echo -n "内存 GiB [4]: "
    read -r mem_gb || true
    mem_gb="${mem_gb:-4}"
    echo -n "CPU 数量 [2]: "
    read -r vcpus || true
    vcpus="${vcpus:-2}"
    local mem_kib=$((mem_gb * 1024 * 1024))

    # 6. 创建后启动
    local do_start=0 do_view=0
    echo -n "创建后立即启动? [y/N]: "
    read -r ans || true
    [[ "$ans" =~ ^[Yy]$ ]] && do_start=1
    if [ "$do_start" -eq 1 ]; then
        echo -n "启动后打开 virt-viewer? [Y/n]: "
        read -r ans || true
        [[ ! "$ans" =~ ^[Nn]$ ]] && do_view=1
    fi

    # 7. 确认
    echo
    kvm_heading "确认"
    echo "  名称:     $vm_name"
    echo "  存储池:   $pool  ($pool_dir)"
    echo "  磁盘:     $disk_path"
    [ "$mode" != "3" ] && echo "  大小:     ${disk_gb} GiB"
    [ -n "$iso_path" ] && echo "  ISO:      $iso_path"
    [ -n "$import_src" ] && echo "  导入自:   $import_src"
    echo "  内存:     ${mem_gb} GiB"
    echo "  CPU:      $vcpus"
    echo "  网络:     default (NAT)"
    echo
    kvm_confirm "确认创建?" || { kvm_warn "已取消"; return; }

    # 8. 创建磁盘
    command -v qemu-img &>/dev/null || kvm_die "需要 qemu-img: sudo apt install qemu-utils"
    if [ "$mode" = "3" ]; then
        kvm_info "导入磁盘…"
        qemu-img convert -O qcow2 "$import_src" "$disk_path"
    else
        kvm_info "创建磁盘: $disk_path (${disk_gb}G)"
        qemu-img create -f qcow2 "$disk_path" "${disk_gb}G"
    fi
    kvm_disk_fix_permissions "$disk_path"

    # 9. 定义 VM
    kvm_info "注册虚拟机…"
    if ! kvm_create_define_xml "$vm_name" "$disk_path" "$mem_kib" "$vcpus" "$iso_path"; then
        echo
        kvm_warn "磁盘文件已创建，但 virsh define 失败，列表里不会出现新 VM"
        echo "  磁盘: $disk_path"
        kvm_info "请用 sudo ./kvm.sh 重试，或手动 define XML"
        return 1
    fi
    if ! kvm_domain_exists "$vm_name"; then
        kvm_warn "define 未报错，但在 ${KVM_VIRSH_URI:-默认} 下找不到: $vm_name"
        return 1
    fi

    echo
    kvm_heading "创建完成"
    kvm_ok "虚拟机: $vm_name"
    kvm_print_domain_location "$vm_name"
    echo
    kvm_info "查看列表: 总菜单 → 1) 查看虚拟机"
    kvm_info "查看详情: ./0-kvm_info.sh -d $vm_name"
    kvm_info "启动安装: sudo ./3-kvm_vm.sh → 1) 启动并打开界面 → 选 $vm_name"

    if [ "$do_start" -eq 1 ]; then
        echo
        kvm_ensure_domain_networks "$vm_name"
        kvm_virsh start "$vm_name"
        if [ "$do_view" -eq 1 ]; then
            sleep 1
            kvm_open_console "$vm_name"
        fi
    fi
}

menu_interactive() {
    kvm_require_tty
    while true; do
        clear 2>/dev/null || true
        kvm_heading "新建虚拟机"
        echo
        echo "  1) 启动创建向导"
        echo "  2) 查看存储池容量"
        echo "  q) 返回上级"
        echo
        echo -n "请选择（空回车返回上级）: "
        read -r choice || true
        echo

        case "$choice" in
            1)
                wizard_create || true
                kvm_menu_pause || break
                ;;
            2)
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
    case "${1:-}" in
        -h|--help|help)
            usage
            exit 0
            ;;
        pool)
            shift
            kvm_ensure_config
            kvm_require_virsh
            case "${1:-list}" in
                list) cmd_pool_list ;;
                *) kvm_die "用法: ${CREATE_SCRIPT_NAME} pool list" ;;
            esac
            ;;
        "")
            kvm_ensure_config
            kvm_require_virsh
            menu_interactive
            ;;
        *)
            usage
            kvm_die "未知参数: $1"
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

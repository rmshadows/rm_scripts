# KVM Manager Bash 补全（可选）
# 用法: source /path/to/KVM_Manager/kvm_completion.bash

_kvm_manager_dir() {
    local src dir
    src="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
    dir="$(cd "$(dirname "$src")" && pwd)"
    if [ -f "$dir/kvm.local.conf" ]; then
        # shellcheck disable=SC1090
        source "$dir/kvm.local.conf"
    fi
    echo "$dir"
}

_kvm_list_names() {
    local dir uri
    dir=$(_kvm_manager_dir)
    uri="${KVM_VIRSH_URI:-qemu:///system}"
    virsh -c "$uri" list --all --name 2>/dev/null | sed '/^$/d'
}

_kvm_vm_complete() {
    local cur prev words cword
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    local commands="start console view shutdown reboot destroy status autostart list info create revert delete help -h --help"
    local autostart_opts="on off enable disable"

    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        return
    fi

    case "${COMP_WORDS[1]}" in
        autostart)
            if [ "$COMP_CWORD" -eq 2 ]; then
                COMPREPLY=($(compgen -W "$autostart_opts" -- "$cur"))
            else
                COMPREPLY=($(compgen -W "$(_kvm_list_names)" -- "$cur"))
            fi
            ;;
        start)
            if [ "$COMP_CWORD" -eq 2 ]; then
                COMPREPLY=($(compgen -W "--view -v $(_kvm_list_names)" -- "$cur"))
            else
                COMPREPLY=($(compgen -W "$(_kvm_list_names)" -- "$cur"))
            fi
            ;;
        shutdown|reboot|destroy|status|console|view)
            COMPREPLY=($(compgen -W "$(_kvm_list_names)" -- "$cur"))
            ;;
    esac
}

complete -F _kvm_vm_complete 3-kvm_vm.sh kvm_vm.sh
complete -F _kvm_vm_complete 0-kvm_info.sh kvm_info.sh
complete -F _kvm_vm_complete 1-kvm_net.sh kvm_net.sh
complete -F _kvm_vm_complete 4-kvm_share.sh kvm_share.sh
complete -F _kvm_snap_complete 5-kvm_snapshot.sh kvm_snapshot.sh

_kvm_disk_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local cmd="${COMP_WORDS[1]:-}"
    local disk_cmds="create info attach pool help -h --help"
    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=($(compgen -W "$disk_cmds" -- "$cur"))
        return
    fi
    case "$cmd" in
        create)
            if [ "$COMP_CWORD" -eq 2 ]; then
                COMPREPLY=($(compgen -W "-p --pool $(_kvm_list_names)" -- "$cur"))
            fi
            ;;
        attach)
            if [ "$COMP_CWORD" -eq 2 ]; then
                COMPREPLY=($(compgen -W "$(_kvm_list_names)" -- "$cur"))
            elif [ "$COMP_CWORD" -eq 3 ]; then
                COMPREPLY=($(compgen -f -X '!*.qcow2' -- "$cur"))
            fi
            ;;
        info)
            COMPREPLY=($(compgen -f -X '!*.qcow2' -- "$cur"))
            ;;
    esac
}

complete -F _kvm_disk_complete 2-kvm_disk.sh

_kvm_snap_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local cmd="${COMP_WORDS[1]:-}"

    local snap_cmds="list info create revert delete help -h --help"
    local snap_opts="--desc --live --quiesce --force --children"

    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=($(compgen -W "$snap_cmds" -- "$cur"))
        return
    fi

    case "$cmd" in
        list)
            COMPREPLY=($(compgen -W "$(_kvm_list_names)" -- "$cur"))
            ;;
        create)
            if [ "$COMP_CWORD" -eq 2 ]; then
                COMPREPLY=($(compgen -W "$(_kvm_list_names)" -- "$cur"))
            elif [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$snap_opts" -- "$cur"))
            fi
            ;;
        info|revert|delete)
            if [ "$COMP_CWORD" -eq 2 ]; then
                COMPREPLY=($(compgen -W "$(_kvm_list_names)" -- "$cur"))
            fi
            ;;
    esac
}

#!/bin/bash
# "更新/etc/environment中fcitx5需要的参数"
update_fcitx5_etc_environment_vars() {
    local file="/etc/environment"
    local vars=(
        "GTK_IM_MODULE=fcitx"
        "QT_IM_MODULE=fcitx"
        "XMODIFIERS=@im=fcitx"
        "SDL_IM_MODULE=fcitx"
        "GLFW_IM_MODULE=ibus"
    )

    # 确保 /etc/environment 文件存在
    if [[ ! -f $file ]]; then
        echo "Error: $file not found!"
        return 1
    fi

    local updated=false

    # 遍历变量逐一检查
    for var in "${vars[@]}"; do
        local key=${var%%=*}   # 提取键
        local value=${var#*=}  # 提取值

        # 检查是否存在正确的键值对
        if grep -qE "^$key=\"$value\"$" "$file" || grep -qE "^$key=$value$" "$file"; then
            echo "OK: $key is correctly set to $value"
        else
            # 如果键存在但值不正确，注释掉原有行
            if grep -qE "^$key=" "$file"; then
                echo "Updating: Incorrect $key found, commenting out old entry."
                sed -i "/^$key=/s/^/#/" "$file"
            fi

            # 添加正确的键值对
            echo "Adding: $key=$value"
            echo "$key=$value" | sudo tee -a "$file" >/dev/null
            updated=true
        fi
    done

    if $updated; then
        echo "Environment variables updated. Please restart your session or run 'source $file' to apply changes."
    else
        echo "No changes were needed."
    fi

    return 0
}

# 调用函数
# update_fcitx5_etc_environment_vars




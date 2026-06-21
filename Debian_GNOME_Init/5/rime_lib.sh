#!/bin/bash
# RIME 词库目录权限与复制（5/setup.sh 使用）

# 若目录内存在非当前用户的文件，统一 chown（修复 sudo cp / addFolder 遗留）
rime_ensure_config_owned() {
	local dir="$1"
	[ -d "$dir" ] || return 0
	if find "$dir" ! -user "$CURRENT_USER" -print -quit 2>/dev/null | grep -q .; then
		prompt -x "修正 RIME 配置目录属主 → $CURRENT_USER: $dir"
		sudo chown -R "$CURRENT_USER:$CURRENT_USER" "$dir"
	fi
}

# 复制本地词库：先修正属主，再以当前用户 cp，最后再次 chown 上层目录
rime_import_local_dict() {
	local src_dir="$1"
	local dest_dir="$2"
	local parent_dir

	parent_dir=$(dirname "$dest_dir")
	rime_ensure_config_owned "$parent_dir"
	rime_ensure_config_owned "$dest_dir"
	prompt -x "导入本地词库: $src_dir → $dest_dir"
	cp -r "$src_dir"/* "$dest_dir"/
	sudo chown -R "$CURRENT_USER:$CURRENT_USER" "$parent_dir"
}

# 导入基础 RIME 补丁（小文件，叠加到系统词库之上）
rime_import_base_config() {
	local src_dir="$1"
	local dest_dir="$2"

	rime_ensure_config_owned "$(dirname "$dest_dir")"
	rime_ensure_config_owned "$dest_dir"
	prompt -x "导入基础 RIME 配置: $src_dir → $dest_dir"
	cp "$src_dir"/*.yaml "$dest_dir"/ 2>/dev/null || true
	sudo chown -R "$CURRENT_USER:$CURRENT_USER" "$(dirname "$dest_dir")"
}

# 检查白霜离线包是否就绪
rime_frost_bundle_ready() {
	local src_dir="$1"
	[ -f "$src_dir/rime_frost.schema.yaml" ]
}

# 导入白霜拼音离线包（整包覆盖用户 rime 目录内容）
rime_import_frost_bundle() {
	local src_dir="$1"
	local dest_dir="$2"
	local parent_dir
	local _backup

	parent_dir=$(dirname "$dest_dir")
	if ! rime_frost_bundle_ready "$src_dir"; then
		prompt -e "白霜离线包不完整: $src_dir（缺少 rime_frost.schema.yaml）"
		prompt -m "请先在本机执行: Debian_GNOME_Init/5/tools/sync_rime_frost_bundle.sh"
		quitThis
	fi

	rime_ensure_config_owned "$parent_dir"
	_backup="${dest_dir}(src)"
	_rime_preserve_custom_phrase=""
	_rime_preserve_user_yaml=""
	if [ -d "$dest_dir" ]; then
		[ -f "$dest_dir/custom_phrase.txt" ] && _rime_preserve_custom_phrase="$dest_dir/custom_phrase.txt"
		[ -f "$dest_dir/user.yaml" ] && _rime_preserve_user_yaml="$dest_dir/user.yaml"
	fi
	if [ -d "$dest_dir" ] && [ "$(ls -A "$dest_dir" 2>/dev/null)" ]; then
		if [ -d "$_backup" ]; then
			prompt -w "已存在 $_backup，跳过备份，直接覆盖当前 rime 目录"
		else
			prompt -x "备份现有 RIME 配置 → $_backup"
			mv "$dest_dir" "$_backup"
			if [ -z "$_rime_preserve_custom_phrase" ] && [ -f "${_backup}/custom_phrase.txt" ]; then
				_rime_preserve_custom_phrase="${_backup}/custom_phrase.txt"
			fi
			if [ -z "$_rime_preserve_user_yaml" ] && [ -f "${_backup}/user.yaml" ]; then
				_rime_preserve_user_yaml="${_backup}/user.yaml"
			fi
		fi
	fi
	mkdir -p "$dest_dir"
	prompt -x "导入白霜拼音离线包（约 150MB+，请稍候）: $src_dir → $dest_dir"
	if command -v rsync >/dev/null 2>&1; then
		rsync -a \
			--exclude 'build/' \
			--exclude 'sync/' \
			--exclude '*.userdb/' \
			--exclude 'user.yaml' \
			--exclude 'installation.yaml' \
			"$src_dir/" "$dest_dir/"
	else
		cp -r "$src_dir"/* "$dest_dir"/
		rm -f "$dest_dir/user.yaml" "$dest_dir/installation.yaml"
		find "$dest_dir" -name '*.userdb' -print -delete 2>/dev/null || true
	fi
	# 保留目标机已有个人短语/偏好（离线包内仅为空模板）
	if [ -n "$_rime_preserve_custom_phrase" ] && [ -f "$_rime_preserve_custom_phrase" ]; then
		cp "$_rime_preserve_custom_phrase" "$dest_dir/custom_phrase.txt"
	fi
	if [ -n "$_rime_preserve_user_yaml" ] && [ -f "$_rime_preserve_user_yaml" ]; then
		cp "$_rime_preserve_user_yaml" "$dest_dir/user.yaml"
	fi
	sudo chown -R "$CURRENT_USER:$CURRENT_USER" "$parent_dir"
}

# 复制到 RIME 目录前的通用准备（停止输入法、修正属主）
rime_prepare_config_dir() {
	local dest_dir="$1"
	local im_proc="${2:-}"

	if [ -n "$im_proc" ]; then
		if pgrep -u "$CURRENT_USER" -x "$im_proc" >/dev/null 2>&1; then
			prompt -x "暂时停止 $im_proc，避免词库配置时文件被占用"
			pkill -u "$CURRENT_USER" -x "$im_proc" 2>/dev/null || true
			sleep 1
		fi
	fi
	rime_ensure_config_owned "$(dirname "$dest_dir")"
	rime_ensure_config_owned "$dest_dir"
}

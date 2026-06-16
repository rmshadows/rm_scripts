# Fluxbox 部署

将本仓库配置部署到用户目录 `~/.fluxbox`。

配置各文件说明见仓库根目录 [README.md](../README.md#配置指南)。

## 快速使用

```bash
cd /path/to/fluxbox
# 按需编辑 setup/Config.sh
./setup/deploy.sh
```

预览（不实际写入）：

```bash
./setup/deploy.sh --dry-run
```

## Config.sh 选项

| 变量 | 说明 | 默认 |
|------|------|------|
| `SET_TARGET_DIR` | 部署目标，空=`~/.fluxbox` | 空 |
| `SET_BACKUP_BEFORE_DEPLOY` | 部署前备份现有目录 | 1 |
| `SET_INSTALL_APT_DEPS` | 运行 `apt-install.sh` | 0 |
| `SET_INIT_DEFAULT_THEME` | 创建 `default.theme` 链接 | 1 |
| `SET_CHMOD_SCRIPTS` | `chmod +x` scripts | 1 |
| `SET_DEPLOY_GTKRC` | 复制 GTK 配置到 `~/.gtkrc-2.0` | 0 |
| `SET_WRITE_SYNC_REPO_PATH` | 写入菜单 Sync 工具用的仓库路径 | 1 |

## 不会部署的内容

- `setup/`、`backup/` — 部署工具与历史备份
- `OtherRes/` — 额外资源包（需手动处理）
- `backgrounds/` — 用户壁纸（避免覆盖）
- `log` — 运行日志

## 旧版 setup 备份

原 Debian GNOME 装机脚本残片已移至 `backup/setup-debian-gnome-init/`。
完整 GNOME 装机请使用仓库 `Debian_GNOME_Init/` 项目。

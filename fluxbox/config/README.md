# config/ 脚本配置文件

部署后位于 `~/.fluxbox/config/`。修改后一般无需重启 Fluxbox，再次点菜单对应项即可。

| 文件 | 用途 | 关联菜单/脚本 |
|------|------|----------------|
| `color-scheme.conf` | GTK 亮/暗色 | Appearance → Color Mode |
| `menu-colors.conf` | 菜单字色预设 | Appearance → Menu color |
| `display.conf` | 多屏输出名覆盖 | Fluxbox Settings → Display |
| `display.profiles` | 手动 xrandr 布局（备用） | Display → Choose Layout |
| `power.conf` | 关机确认 / sudo 开关 | System → Power Options |
| `wallpaper.conf` | 壁纸目录与 fbsetbg 参数 | Appearance → Wallpaper |
| `sync.repo.path` | 仓库路径（Sync 工具） | Tools → Sync |
| `menu.font.size` | 当前菜单字号（脚本写入） | 一般勿手改 |
| `menu.color.preset` | 当前字色预设名（脚本写入） | 一般勿手改 |

## color-scheme.conf

仅影响 GTK 应用，不改 Fluxbox 主题。

## menu-colors.conf

格式：`预设名|标题色|普通项|高亮项|禁用项`

## display.conf

```bash
INTERNAL=eDP-1
EXTERNAL=DP-1
```

运行 `xrandr` 查看本机输出名。

## power.conf

```bash
REQUIRE_CONFIRM=1    # 1=关机前确认
REQUIRE_PASSWORD=0   # 1=用 sudo shutdown；0=systemctl+polkit
```

## wallpaper.conf

```bash
WALLPAPER_DIR="${HOME}/.fluxbox/backgrounds"
WALLPAPER_DEFAULT=""   # 可选，首次无记录时使用
FBSETBG_OPTS="-a"
```

壁纸图片放入 `backgrounds/`（部署不覆盖该目录）。

## sync.repo.path

复制 `sync.repo.path.example` 为 `sync.repo.path`（已在 `.gitignore` 中，deploy 会自动写入本机路径）。

克隆仓库后改成你的绝对路径，供 `fluxbox-sync.sh` / `fluxbox-deploy.sh` 使用。

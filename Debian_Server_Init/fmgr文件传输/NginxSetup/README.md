### fmgr Nginx 配置

仓库根 `fmgr文件传输/` 为编辑源；打包前复制到 `Debian_GNOME_Init/` 与 `Debian_Server_Init/`。

```bash
cd fmgr文件传输/NginxSetup   # 或 Init 内同名目录
./setupNginxForFmgr.sh              # 交互（Server / 手工）
./setupNginxForFmgr.sh --batch      # 非交互（GNOME Init 用）
./setupNginxForFmgr.sh --uninstall
```

### 怎么部署（先看场景）

| 场景 | 怎么做 |
|------|--------|
| **GNOME 新机器** | Init：`--batch` + `html.conf`（已有 PHP）+ snippet。无提问。 |
| **Server 已有主站** | 交互选 **snippet**，挂到现有 site。 |
| **本机再单独开 80** | 交互选 **standalone**；先 disable 其它听 80 的站。 |

### PHP（snippet 不含）

- 通用 `location ~ \.php$` 只在 **site**；snippet 只有 `/fmgr/`、`/x`。
- 自动插入条件很严，**默认不插**：
  - 已检测到 PHP / include fastcgi-php / 已有标记 → 不改，只提醒你核对
  - 多 `server{}`、有注释掉的 php location、已有 `fastcgi_pass` → **拒绝自动插**，只打印要粘贴的块
  - `--yes` → **绝不**自动插 PHP
  - 仅「单 server + 完全无 php/fastcgi 痕迹」且你显式答 **y** 才会插；先备份 `*.fmgr-php.bak.*`
- 插完 / 挂完后：**你必须** `nginx -t`、打开 `/fmgr/index.php` 自查。

### block_ip

不要做成 site snippet。继续用主配置 `http { include block_ip.conf; }`。

### 权限 / 体积 / 弱口令

上级 README；体积用主配置 `client_max_body_size`（GNOME 默认 5000m）。

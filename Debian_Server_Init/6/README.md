# Shorewall

部署只拷配置，**不会自动启用**，避免把自己锁在外面。

## 用模板

```bash
sudo sw-rules
```

会从 `/etc/shorewall/crules/` 选一份覆盖 `rules`。

| 模板 | 已开 | 其余 |
|---|---|---|
| `normal` | SSH | Web / 邮件 / 自定义端口都在文件里，取消注释 |
| `web` | SSH + 80/443 | 同上 |
| `off` | 全关 | 应急断网 |
| `gov_only` | 指定内网 IP | 按注释改 IP |

## 取消注释

```bash
sudo nano /etc/shorewall/rules
# 找到注释条，去掉行首 #
sudo shorewall check && sudo shorewall reload
```

尚未启用时：

```bash
sudo systemctl enable --now shorewall
```

网卡 / 区域：`/etc/shorewall/interfaces`、`zones`、`policy`。说明也在 `/etc/shorewall/README.txt`。

# fail2ban

SSH 爆破防护：120 分钟内失败 5 次自动封禁该 IP 7 天（GNOME 桌面版放宽为 10 次封 1 小时）。

部署自动完成：未装则安装 → 写入 `/etc/fail2ban/jail.local`（覆盖前备份 `.bak`/`.newbak`）→ `fail2ban-client -t` 校验 → 开机自启并 reload。保留 SSH 密码登录，不设 `PasswordAuthentication no`。

sshd 走 journald（`backend=systemd`）：Debian 13 默认无 rsyslog/auth.log 也能抓到失败记录。

## 日常操作

```bash
sudo fail2ban-client status sshd                  # 查看封禁列表
sudo fail2ban-client set sshd unbanip 1.2.3.4     # 手动解封
sudo fail2ban-client get sshd findtime            # 7200
sudo fail2ban-client get sshd maxretry            # 5（桌面 10）
sudo fail2ban-client get sshd bantime             # 604800（桌面 3600）
```

参数在 `Config.sh` 检查点六（`SET_FAIL2BAN_FINDTIME` / `MAXRETRY` / `BANTIME`）。手动改 jail.local 后 `sudo fail2ban-client reload`；重跑部署会覆盖本文件（旧档在 .bak/.newbak）。

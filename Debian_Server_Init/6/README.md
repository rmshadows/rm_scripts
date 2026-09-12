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

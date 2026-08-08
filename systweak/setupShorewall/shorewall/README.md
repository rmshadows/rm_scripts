# Shorewall 配置包（来自 Debian_GNOME_Init/8/SW_CONF，已去掉 examples）

与同级的 `../setup-shorewall.sh` 一起使用：

```bash
# 拷到目标机（脚本 + 本目录下的 tar，或整个 SW_CONF 文件夹）
sudo bash setup-shorewall.sh           # 部署 + check，不自动启动
sudo bash setup-shorewall.sh --start   # 确认规则后再启动
sudo bash setup-shorewall.sh --undo
```

部署后可用 `/etc/shorewall/setup_rules.sh` 在 `crules/` 规则集间切换（normal / off / gov_only 等）。

**注意**：默认策略偏「外网进站 DROP」；远程 SSH 前请先改 `rules`/`crules`，避免把自己锁在门外。

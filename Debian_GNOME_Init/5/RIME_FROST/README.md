# 白霜拼音离线包

`SET_IMPORT_RIME_DICT=1` 时使用，适合 **fcitx5-rime**（较新 librime）。

**隐私说明：** 离线包**不包含**个人自定义短语、用户词典、机器 `installation_id` 等。`sync_rime_frost_bundle.sh` 会自动排除并替换为空模板。

## 首次准备离线包

在已配置好白霜的机器上，于本目录的上一级执行：

```bash
./tools/sync_rime_frost_bundle.sh
```

默认从 `~/.local/share/fcitx5/rime` 同步；也可指定源目录：

```bash
./tools/sync_rime_frost_bundle.sh /path/to/rime-frost-config
```

同步完成后，本目录应包含 `rime_frost.schema.yaml` 等文件（约 150MB+，不提交 git）。

## 从 GitHub 初次获取（仅需做一次，非部署脚本内操作）

```bash
git clone --depth 1 https://github.com/gaboolic/rime-frost.git /tmp/rime-frost
./tools/sync_rime_frost_bundle.sh /tmp/rime-frost
```

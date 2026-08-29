# 白霜拼音精简离线包

`SET_IMPORT_RIME_DICT=1` 时，部署脚本把本目录拷到 `~/.local/share/fcitx5/rime/`。**不访问 GitHub、不 git clone。**

体积约 40MB+（不含 `others/` 原料、未启用的腾讯词库、个人词库）。可随仓库提交。

**隐私：** 不含 `custom_phrase` 个人词条、`*.userdb`、`installation.yaml`。`custom_phrase.txt` 仅为空模板。

## 从本机更新离线包

在已配置白霜的机器上：

```bash
./tools/sync_rime_frost_bundle.sh
```

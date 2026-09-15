# phptinyfilemanager 入口（Server Init）

资源目录：本 Init 根下的 **`fmgr文件传输/`**（与 `other/` 同级）。

仓库里改模板只改根目录 `fmgr文件传输/`；**打包前复制进两个 Init**：

```bash
cp -a fmgr文件传输 Debian_GNOME_Init/
cp -a fmgr文件传输 Debian_Server_Init/
```

```bash
./phptinyfilemanager.sh          # 交互部署
./uninstall.sh                   # 交互卸载

# 或直接：
FMGR_PARENT=/home/HTML bash ../../../fmgr文件传输/NginxSetup/setupNginxForFmgr.sh
```

- **Server / 手工**：本脚本 → Init 内模板（**可交互**）
- **GNOME**：Init → 同一模板 **`--batch`（无交互）**

# FMGR —— 轻量级文件共享

**本目录是仓库里的唯一编辑源。** 打包只带两个 Init，使用前复制进去：

```bash
cp -a fmgr文件传输 Debian_GNOME_Init/
cp -a fmgr文件传输 Debian_Server_Init/
```

之后只改本目录，打包前再 `cp -a` 覆盖两个 Init 内的副本即可。

### 部署场景

| 场景 | 怎么做 |
|------|--------|
| **GNOME（无交互）** | Init 内有 `fmgr文件传输/` + `SET_CONFIG_FMGR=1` → `--batch` |
| **Server（可交互）** | Init 内有 `fmgr文件传输/` + `phptinyfilemanager.sh` |
| **手工** | 直接跑本目录 `NginxSetup/setupNginxForFmgr.sh` |

PHP 在 **site** 不在 snippet；`--batch` / `--yes` **绝不**自动插 PHP。详见 `NginxSetup/README.md`。

> `MoveToParent/`：会同步进 `fmgr/`，同时也会拷到**父目录**（跳转页、404）。

### 文件路径

- `files`——允许上传(需要登录)
- `readonly`——只读文件(无需登录)

### 默认密码（务必改掉）

```
密码生成：
https://tinyfilemanager.github.io/docs/pwd.html
https://phppasswordhash.com/

admin:xNJZ$d3U9e 管理员
user:User12345!  可以上传到tempUpload文件夹
405:123405
123456:123456 只读
```

### Apache2设置

```
ServerTokens ProductOnly
ServerSignature Off
```

# nvm 一键安装与更新

上游项目：https://github.com/nvm-sh/nvm （完整文档/常见问题见此，本目录不再存上游 README 拷贝）

## 本目录文件

| 文件 | 用途 |
|------|------|
| `nvm.sh` | 一键安装：按钉死的版本号拉上游 `install.sh` 装 nvm，可顺手装 Node.js |
| `update-nvm.sh` | 升级 `nvm.sh` 里钉死的版本号（类似 git pull） |

## 一键安装（部署机上）

```bash
bash nvm.sh
```

装完后重开终端（或 `source ~/.bashrc`）即可使用 `nvm`。

`nvm.sh` 开头的开关（可改脚本，也可部署前 export 环境变量）：

| 变量 | 说明 | 默认 |
|------|------|------|
| `SET_INSTALL_NVM` | 是否安装 nvm | 1 |
| `SET_NVM_INSTALL_NODEJS_LTS` | 装完 nvm 顺手装最新 LTS 版 Node.js | — |
| `SET_NVM_INSTALL_NODEJS_VERSION` | 不装 LTS 时装指定版本，如 `v22.14.0` | 空 |

## 升级 nvm 版本（开发机上）

`nvm.sh` 把上游版本号钉死，保证部署可复现；上游出新版后用它同步：

```bash
./update-nvm.sh             # 更新到上游最新版
./update-nvm.sh v0.40.7     # 钉到指定版本
./update-nvm.sh --check     # 只检查是否有新版，不改动
```

只替换 `nvm.sh` 里的版本号。改动用 `git diff` 查看、`git checkout` 回滚。

## 镜像设置（国内加速）

### Node.js 下载镜像

在 `~/.bashrc`（zsh 用户 `~/.zshrc`）添加：

```bash
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node/
export NVM_IOJS_ORG_MIRROR=https://npmmirror.com/mirrors/iojs/
```

验证：`echo $NVM_NODEJS_ORG_MIRROR`。
换镜像后安装失败，先清缓存再试：`nvm cache clear`

### npm 镜像

```bash
npm config set registry https://registry.npmmirror.com            # 永久
npm install <pkg> --registry=https://registry.npmmirror.com       # 仅本次
npm config set registry https://registry.npmjs.org                # 恢复官方
```

验证：`npm config get registry`

### cnpm（可选）

```bash
npm install -g cnpm --registry=https://registry.npmmirror.com
```

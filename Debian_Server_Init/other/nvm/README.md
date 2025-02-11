# Title

这个文件夹是安装nvm的

## 设置镜像

设置nvm镜像: `nvm node_mirror https://npmmirror.com/mirrors/node/`（不确定有效）

建议方法：直接在bashrc添加

```
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node/
export NVM_IOJS_ORG_MIRROR=https://npmmirror.com/mirrors/iojs/
```

验证：`echo $NVM_NODEJS_ORG_MIRROR`

NVM_NODEJS_ORG_MIRROR：用于指定 Node.js 的下载镜像。
NVM_IOJS_ORG_MIRROR：用于指定 io.js 的下载镜像（较老版本的 Node.js 分支，现在一般不用）。

测试镜像站：`curl -I https://npmmirror.com/mirrors/node/`

**修改镜像后 Node.js 安装失败**
检查是否有老旧缓存干扰，可以清除 `nvm` 缓存：`nvm cache clear`

## npm设置镜像

#### 1. 临时使用镜像
```bash
npm install <package-name> --registry=https://registry.npmmirror.com
```
这样设置只对当前命令生效，不会影响后续的 npm 配置。

---

#### 2. 永久设置镜像
你可以通过以下命令将镜像地址配置为默认的 npm registry：
```bash
npm config set registry https://registry.npmmirror.com
```
验证设置是否成功：
```bash
npm config get registry
```
输出应该为：
```
https://registry.npmmirror.com/
```

---

#### 3. 恢复默认镜像
如果需要恢复 npm 的官方镜像，可以运行以下命令：
```bash
npm config set registry https://registry.npmjs.org
```

---

### 使用 cnpm（可选）
淘宝镜像还提供了一个名为 `cnpm` 的工具，专门为中国用户优化。安装 `cnpm`：
```bash
npm install -g cnpm --registry=https://registry.npmmirror.com
```
然后使用 `cnpm` 替代 `npm` 安装包：
```bash
cnpm install <package-name>
```


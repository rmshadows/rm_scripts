# acme 管理

整个 `acme` 文件夹拷走就能用。检查点五也是从这里安装。

检查点五会把脚本装到 `/usr/local/bin` 和 `/usr/local/sbin`。自己加装不用装到系统目录：整个文件夹拷走，在文件夹里运行。

`/etc/acme-deploy.conf` 告诉脚本：业务用户、acme.sh 目录、证书拷到 `~/cert`、主域名和 SAN、网站根目录、nginx 还是 apache2。

## 自己加装

先确认这台机器已经装了 acme.sh。用 root 在这个文件夹里执行 `./acme-ctl.sh`。

菜单 7 生成 `/etc/acme-deploy.conf`。菜单 3 部署证书，并把续签钩子改成这个文件夹里的 `acme-deploy-cert.sh`，同时写上免密。钩子记的是当时这个文件的路径，不要再把文件夹挪走。

已经部署过、不再跑 Init 的机器，迁移是分开的步骤，没有一键。菜单里按这个顺序自己做：

1. `5` 查出 acme.sh 托管目录，以及登记过的旧证书路径
2. `6` 删掉那些已安装副本，并清空登记。托管目录里的原件不动
3. `7` 按提示生成 `/etc/acme-deploy.conf`。`ACME_BIN` 填目录，不要填到 `acme.sh` 这个文件
4. `3` 把证书部署到 `~/cert` 并 reload
5. `8` 删掉 `/etc/ssl` 等旧位置的副本。托管目录和 `~/cert` 不动

apache2 在第 7 步把 Web 服务填成 `apache2`。网站根目录填实际的校验目录。

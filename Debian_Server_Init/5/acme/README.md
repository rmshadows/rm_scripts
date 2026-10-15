# acme 管理

整个 `acme` 文件夹拷走就能用。检查点五也是从这里安装。

| 文件 | 装到哪 |
| --- | --- |
| `acme-ctl.sh` | `/usr/local/bin/acme-ctl` |
| `acme-deploy-cert.sh` | `/usr/local/sbin/acme-deploy-cert` |
| `acme-deploy.conf.src` | `/etc/acme-deploy.conf` |
| `acme-deploy-cert.sudoers.src` | `/etc/sudoers.d/acme-deploy-cert` |

`/etc/acme-deploy.conf` 告诉脚本：业务用户、acme.sh 目录、证书拷到 `~/cert`、主域名和 SAN、网站根目录、nginx 还是 apache2。

## 自己加装

先确认这台机器已经装了 acme.sh。在本目录用 root 执行，把 `【$...】` 改成这台机器的值：

```bash
sed -e 's|【$CURRENT_USER】|业务用户名|g' \
    -e 's|【$SET_ACME_HOME】|/home/业务用户名/.acme.sh|g' \
    -e 's|【$_acme_cert_root】|/home/业务用户名/.acme.sh|g' \
    -e 's|【$HOME_INDEX】|/home/业务用户名|g' \
    -e 's|【$_acme_http】|nginx|g' \
    -e 's|【$SET_SERVER_NAME】|主域名|g' \
    -e 's|【$SET_ACME_SERVER_NAMES】|主域名 额外域名|g' \
    -e 's|【$_acme_webroot】|/home/业务用户名/nginx|g' \
    acme-deploy.conf.src > /etc/acme-deploy.conf
chmod 644 /etc/acme-deploy.conf

cp acme-ctl.sh /usr/local/bin/acme-ctl
cp acme-deploy-cert.sh /usr/local/sbin/acme-deploy-cert
chmod 755 /usr/local/bin/acme-ctl /usr/local/sbin/acme-deploy-cert

sed 's|【$CURRENT_USER】|业务用户名|g' acme-deploy-cert.sudoers.src > /etc/sudoers.d/acme-deploy-cert
chmod 440 /etc/sudoers.d/acme-deploy-cert
visudo -cf /etc/sudoers.d/acme-deploy-cert
```

然后执行 `acme-ctl`。只看状态：`acme-ctl status`。

apache2 把 `HTTP` 改成 `apache2`。网站根目录改成实际的校验目录。

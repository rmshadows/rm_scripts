### Nginx 配置（不修改原机 site 内容）

- 配置会写入 **nginx 配置目录**：`/etc/nginx/snippets/fmgr.conf`（root 由脚本按 fmgr 目录自动填好）。
- 脚本会安装 **php-fpm**（fmgr 需要跑 PHP），不覆盖 nginx 主配置、不删 default、不写新 site。
- 您只需**自己编辑一次**要用 fmgr 的那个 **site-enabled**：在对应的 `server { }` 里加一行：
  ```nginx
  include /etc/nginx/snippets/fmgr.conf;
  ```
  然后 `sudo nginx -t && sudo systemctl reload nginx` 即可。

这样只增加 `/fmgr` 和 `/x` 的 location，不改动原机其它配置。

---

**使用步骤**

1. 将本 fmgr 目录放到目标位置（如 `$HOME/nginx/fmgr` 或 `/var/www/fmgr`）。
2. 在 fmgr 目录下执行：`NginxSetup/setupNginxForFmgr.sh`（会安装 php-fpm 并写入 `/etc/nginx/snippets/fmgr.conf`）。
3. 在自己的 site-enabled 里某个 `server { }` 内加一行：`include /etc/nginx/snippets/fmgr.conf;`
4. `sudo nginx -t && sudo systemctl reload nginx`

**http**：仅作完整 server 示例参考，不用于覆盖原机配置。

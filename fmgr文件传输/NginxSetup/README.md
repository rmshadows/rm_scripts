### Nginx配置文件示例

将文件`nginx.conf`和`block_ip.conf`移动到`/etc/nginx`文件夹中

将文件`http`移动至`/etc/nginx/sites-available/`然后运行

`sudo ln -s /etc/nginx/sites-available/http /etc/nginx/sites-enabled/http`

(同时删除`/etc/nginx/sites-enabled/default`)

至于`php-fpm`之类的请自行安装并修改端口号到9000

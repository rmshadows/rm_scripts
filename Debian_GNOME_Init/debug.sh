NGINX_GLOBAL_CONF="#### nginx配置
# nginx用户
user www-data;
# 工作核心数量
worker_processes auto;
# 指定nginx进程运行文件存放地址
pid /run/nginx.pid;
# 包含启用的模块
include /etc/nginx/modules-enabled/*.conf;# 

# 制定日志路径，级别。这个设置可以放入全局块，http块，server块，级别以此为：debug|info|notice|warn|error|crit|alert|emerg
# error_log $HOME/Logs/nginx/error.log crit; 
# error_log $HOME/Logs/nginx/info.log info; 
# Specifies the value for maximum file descriptors that can be opened by this process.# nginx worker进程最大打开文件数
worker_rlimit_nofile 4028;

events
{
  # 在linux下，nginx使用epoll的IO多路复用模型
  use epoll; 
  # nginx worker单个进程允许的客户端最大连接数
  worker_connections 1024; 
  # 设置网路连接序列化，防止惊群现象发生，默认为on.惊群现象：一个网路连接到来，多个睡眠的进程被同时叫醒，但只有一个进程能获得链接，这样会影响系统性能。
  accept_mutex on; 
  # 设置一个进程是否同时接受多个网络连接，默认为off。如果web服务器面对的是一个持续的请求流，那么启用multi_accept可能会造成worker进程一次接受的请求大于worker_connections指定可以接受的请求数。这就是overflow，这个overflow会造成性能损失，overflow这部分的请求不会受到处理。
  # multi_accept on; 
}

http
{
  # IP黑名单
  include block_ip.conf;
  # access_log $HOME/Logs/nginx/access.log;
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  # log_format main  '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '
  #            '\$status \$body_bytes_sent \"\$http_referer\" '
  #            '\"\$http_user_agent\" \$http_x_forwarded_for';
  
  # charset gb2312;
  charset utf-8;

  limit_req_zone \$binary_remote_addr zone=one:10m rate=1r/s;
  
  server_names_hash_bucket_size 128;
  # server_name_in_redirect off;
  client_header_buffer_size 32k;
  large_client_header_buffers 4 32k;
  # 允许客户端请求的最大单文件字节数。如果有上传较大文件，请设置它的限制值
  client_max_body_size 5000m; 
  
  types_hash_max_size 2048;
  # 禁用服务器版本显示
  server_tokens off;
  sendfile on;
  # 只有sendfile开启模式下有效
  tcp_nopush on; 
  # 长连接超时时间，单位是秒，这个参数很敏感，涉及浏览器的种类、后端服务器的超时设置、操作系统的设置，可以另外起一片文章了。长连接请求大量小文件的时候，可以减少重建连接的开销，但假如有大文件上传，65s内没上传完成会导致失败。如果设置时间过长，用户又多，长时间保持连接会占用大量资源。
  keepalive_timeout 60; 
  # 设置客户端连接保持会话的超时时间，超过这个时间，服务器会关闭该连接。
  tcp_nodelay on; 
  fastcgi_connect_timeout 300;
  fastcgi_send_timeout 300;
  fastcgi_read_timeout 300;
  fastcgi_buffer_size 64k;
  fastcgi_buffers 4 64k;
  fastcgi_busy_buffers_size 128k;
  fastcgi_temp_file_write_size 128k;
 
  #limit_zone crawler \$binary_remote_addr 10m;
  
  ##
  # SSL Settings
  ##
  # ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
  # ssl_prefer_server_ciphers on;

  ##
  # Logging Settings
  ##
  access_log /var/log/nginx/access.log;
  error_log /var/log/nginx/error.log;

  ##
  # Gzip Settings
  ##
  gzip on;
  gzip_min_length 1k;
  gzip_buffers 4 16k;
  gzip_http_version 1.0;
  gzip_comp_level 2;
  gzip_types text/plain application/x-javascript text/css application/xml;
  gzip_vary on;
  # Nginx作为反向代理的时候启用，决定开启或者关闭后端服务器返回的结果是否压缩，匹配的前提是后端服务器必须要返回包含\"Via\"的 header头。
  # gzip_proxied any; 

  ##
  # Virtual Host Configs
  ##
  include /etc/nginx/conf.d/*.conf;
  include /etc/nginx/sites-enabled/*;

  ##
  # http_proxy 设置
  ##
  #支持客户端的请求方法。post/get；
  # proxy_method post;
  # client_max_body_size   10m;
  client_body_buffer_size   128k;
  # nginx跟后端服务器连接超时时间(代理连接超时)
  proxy_connect_timeout   75; 
  proxy_send_timeout   75;
  # 连接成功后，与后端服务器两个成功的响应操作之间超时时间(代理接收超时)
  proxy_read_timeout   75;
  # 设置代理服务器（nginx）从后端realserver读取并保存用户头信息的缓冲区大小，默认与proxy_buffers大小相同，其实可以将这个指令值设的小一点
  proxy_buffer_size   4k; 
  # proxy_buffers缓冲区，nginx针对单个连接缓存来自后端realserver的响应，网页平均在32k以下的话，这样设置
  proxy_buffers   4 32k; 
  # 高负荷下缓冲大小（proxy_buffers*2）
  proxy_busy_buffers_size 64k;
  # 当缓存被代理的服务器响应到临时文件时，这个选项限制每次写临时文件的大小。proxy_temp_path（可以在编译的时候）指定写到哪那个目录。
  # proxy_temp_file_write_size  64k; 
  # proxy_temp_path   /usr/local/nginx/proxy_temp 1 2;
  proxy_hide_header X-Powered-By; 
  proxy_hide_header Server;
  
  ##
  # 设定负载均衡后台服务器列表 
  ##
  ## down，表示当前的server暂时不参与负载均衡。
  ## backup，预留的备份机器。当其他所有的非backup机器出现故障或者忙的时候，才会请求backup机器，因此这台机器的压力最轻。
  # upstream mysvr { 
  #  #ip_hash; 
  #  server   192.168.10.100:8080 max_fails=2 fail_timeout=30s ;  
  #  server   192.168.10.101:8080 max_fails=2 fail_timeout=30s ;  
  # }
}

#mail {
#	# See sample authentication script at:
#	# http://wiki.nginx.org/ImapAuthenticateWithApachePhpScript
# 
#	# auth_http localhost/auth.php;
#	# pop3_capabilities \"TOP\" \"USER\";
#	# imap_capabilities \"IMAP4rev1\" \"UIDPLUS\";
# 
#	server {
#		listen     localhost:110;
#		protocol   pop3;
#		proxy      on;
#	}
# 
#	server {
#		listen     localhost:143;
#		protocol   imap;
#		proxy      on;
#	}
#}
"

# Nginx IP黑名单
NGINX_BLOCK_IP="deny 45.155.205.211;
deny 34.251.241.226;
deny 13.233.73.212;
deny 54.176.188.51;
deny 13.233.73.21;
deny 13.232.96.1;
deny 51.38.40.95;
deny 46.101.207.180;
deny 3.143.11.66;
deny 211.40.129.246;
deny 157.230.114.6;
"

# Nginx 默认配置的页面(HTTP)
NGINX_HTTP_SITE="##
# You should look at the following URL's in order to grasp a solid understanding
# of Nginx configuration files in order to fully unleash the power of Nginx.
# https://www.nginx.com/resources/wiki/start/
# https://www.nginx.com/resources/wiki/start/topics/tutorials/config_pitfalls/
# https://wiki.debian.org/Nginx/DirectoryStructure
#
# In most cases, administrators will remove this file from sites-enabled/ and
# leave it as reference inside of sites-available where it will continue to be
# updated by the nginx packaging team.
#
# This file will automatically load configuration files provided by other
# applications, such as Drupal or Wordpress. These applications will be made
# available underneath a path with that package name, such as /drupal8.
#
# Please see /usr/share/doc/nginx-doc/examples/ for more detailed examples.
##

server
{
    # 监听端口
    listen 80 default_server;
    listen [::]:80 default_server;
    # 域名
    server_name _;
    # Add index.php to the list if you are using PHP
    index index.html index.php index.htm index.nginx-debian.html;
    # 站点根目录
    root /home/HTML;
    
    # error_page 404 https://www.baidu.com; #错误页
    # error_page  500 502 503 504  /50x.html;
    
    # PHP
    location ~ .*\.(php|php5)?$
    {
      # fastcgi_pass unix:/tmp/php-cgi.sock;
      fastcgi_pass 127.0.0.1:9000;
      fastcgi_index index.php;
      include fastcgi.conf;
    }

    # 不是GET POST HEAD就返回空响应(一些情况可能需要注释掉)
    # if (\$request_method !~ ^(GET|HEAD|POST)$) {
    #   return 444;
    # }
  
    # 图片过期
    location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|ico)$
    {
      expires 30d;
      # access_log off;
    }
    # js css文件过期
    location ~ .*\.(js|css)?$
    {
      expires 15d;
      # access_log off;
    }
    
    # 负载均衡
    # location  ~*^.+$ {         
    #    proxy_pass  http://mysvr;  #请求转向mysvr 定义的服务器列表
    # }

    # SSL configuration
	#
	# listen 443 ssl default_server;
	# listen [::]:443 ssl default_server;
	#
	# Note: You should disable gzip for SSL traffic.
	# See: https://bugs.debian.org/773332
	#
	# Read up on ssl_ciphers to ensure a secure configuration.
	# See: https://bugs.debian.org/765782
	# Self signed certs generated by the ssl-cert package
	# Don't use them in a production server!
	#
	# include snippets/snakeoil.conf;

    # pass PHP scripts to FastCGI server
	# PHP配置 (原来的模板)
	#location ~ \.php$ {
	#	include snippets/fastcgi-php.conf;
	#
	#	# With php-fpm (or other unix sockets):
	#	fastcgi_pass unix:/run/php/php7.4-fpm.sock;
	#	# With php-cgi (or other tcp sockets):
	#	fastcgi_pass 127.0.0.1:9000;
	#}

	#location / {
	#	# First attempt to serve request as file, then
	#	# as directory, then fall back to displaying a 404.
	#	try_files \$uri \$uri/ =404;
	#}

	# deny access to .htaccess files, if Apache's document root
	# concurs with nginx's one
	#
	#location ~ /\.ht {
	#	deny all;
	#}
}

# Virtual Host configuration for example.com
#
# You can move that to a different file under sites-available/ and symlink that
# to sites-enabled/ to enable it.
#
#server {
#	listen 80;
#	listen [::]:80;
#
#	server_name example.com;
#
#	root /var/www/example.com;
#	index index.html;
#
#	location / {
#		try_files \$uri \$uri/ =404;
#	}
#}
"


echo "$NGINX_HTTP_SITE" > 2.txt

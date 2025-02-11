# 其他

```
    # Hack chat 8002 8003
    # location /hc/ {
    #     access_log 【$HOME_INDEX】/Logs/nginx/hackchat.log;
    #     error_log 【$HOME_INDEX】/Logs/nginx/hackchat_error.log;
    #     proxy_set_header Host $host;
    #     proxy_set_header X-Real-IP $remote_addr;
    #     #rewrite /$1 ^/hackchat(.*);
    #     proxy_pass http://127.0.0.1:8002/;
    #     #proxy_redirect http://$proxy_host/ $scheme://$host:$server_port/hackchat/;
    #     #sub_filter 'href="/' 'href="/hackchat';
    # }
    # location /hc-wss {
    #     proxy_pass http://127.0.0.1:8003;
    #     proxy_http_version 1.1;
    #     proxy_set_header Upgrade $http_upgrade;
    #     proxy_set_header Connection "Upgrade";
    # }
    # isso 评论系统 8004
    # location /isso {
    #     access_log 【$HOME_INDEX】/Logs/nginx/isso.log;
    #     error_log 【$HOME_INDEX】/Logs/nginx/isso_error.log;
    #     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    #     proxy_set_header X-Script-Name /isso;
    #     proxy_set_header Host $host;
    #     proxy_set_header X-Real-IP $remote_addr;
    #     proxy_set_header X-Forwarded-Proto $scheme;
    #     proxy_pass http://127.0.0.1:8004;
    # }
    # file pizza 8005
    # location /filepizza/ {
    #     proxy_pass http://127.0.0.1:8005/;
    # }
```


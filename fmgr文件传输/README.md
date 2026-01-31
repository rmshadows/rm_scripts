# FMGR —— 轻量级文件共享

>MoveToParent里面的要移动到上级文件夹，一个跳转网页，一个404

### 文件路径

- `files`——允许上传(需要登录)
- `readonly`——只读文件(无需登录)

### 默认密码

```
密码生成：
https://tinyfilemanager.gi123405123405123thub.io/docs/pwd.html
https://phppasswordhash.com/

admin:xNJZ$d3U9e 管理员
user:User12345!  可以上传到tempUpload文件夹
405:123405
123456:123456 只读
```

### Nginx配置

```
	# 重写fmgr路径
    location ~/fmgr/filesfmgr {
        rewrite ^/fmgr/filesfmgr(.*)$ /fmgr/$1;
    }
```

### Apache2设置

```
# 隐藏版本号等信息
ServerTokens ProductOnly
ServerSignature Off
```


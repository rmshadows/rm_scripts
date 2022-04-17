# FRP ADMIN
<VirtualHost *:2083>
    CustomLog "/home/jessie/Logs/apache2/20001_access_log" common
    ServerName jitsi.civiccccc.ltd
    # DocumentRoot "/home/jessie/apache2"
    ProxyPass / http://127.0.0.1:7500/
    ProxyPassReverse / http://127.0.0.1:7500/
    # RewriteRule ^/rmshadows(.*) http://127.0.0.1:20000/$1
    SSLEngine on
    SSLProxyEngine on
    SSLCertificateFile /etc/ssl/jitsi.civiccccc.ltd.pem
    SSLCertificateKeyFile /etc/ssl/jitsi.civiccccc.ltd.key
</VirtualHost>


<VirtualHost *:2087>
    CustomLog "/home/jessie/Logs/apache2/20002_access_log" common
    ServerName jitsi.civiccccc.ltd
    ProxyPass / http://127.0.0.1:1200/
    ProxyPassReverse / http://127.0.0.1:1200/
    # RewriteRule ^/rmshadows(.*) http://127.0.0.1:20000/$1
    SSLEngine on
    SSLProxyEngine on
    SSLCertificateFile /etc/ssl/jitsi.civiccccc.ltd.pem
    SSLCertificateKeyFile /etc/ssl/jitsi.civiccccc.ltd.key
</VirtualHost>
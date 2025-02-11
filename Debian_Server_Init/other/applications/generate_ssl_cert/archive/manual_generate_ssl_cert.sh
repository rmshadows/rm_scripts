#!/bin/bash
## 需要有人职守，需要sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

#### CONF
# 密钥和证书的文件名（可根据实际情况修改）
SSL_KEY_NAME="ssl"
# 私钥文件名
SSL_KEY_FILE="${SSL_KEY_NAME}.key"
# 证书请求文件名
SSL_CSR_FILE="${SSL_KEY_NAME}.csr"
# 自签名证书文件名
SSL_PEM_FILE="${SSL_KEY_NAME}.pem"
# 证书签发文件名
SSL_CRT_FILE="${SSL_KEY_NAME}.crt"
# 证书有效期（天数）
SSL_CERT_DAYS=3650
# 使用的加密算法（根据需要选择）
ENCRYPTION_ALGO="aes256" # 可以改为 aes128, aes256, des3等
# 私钥位数
SSL_KEY_SIZE=4096
# 使用的散列算法（可以选择 sha256, sha384, sha512等）
HASH_ALGO="sha512"
# 配置扩展文件（如果有）
SSL_EXT_FILE="${SSL_KEY_NAME}.ext"

#### 正文
# 检查命令
if ! [ -x "$(command -v openssl)" ]; then
    prompt -e "openssl not found! Install openssl first!"
    sudo apt update
    sudo apt install openssl
fi


# https://www.cnblogs.com/she11s/p/13489938.html
# 生成一个 2048 位的 RSA 私钥，并使用 DES3 算法加密保存为 $SSL_KEY_NAME.key 文件。
# openssl genrsa -des3 -out $SSL_KEY_NAME.key 2048
prompt -i "生成加密的 RSA 私钥"
openssl genrsa -${ENCRYPTION_ALGO} -out $SSL_KEY_FILE $SSL_KEY_SIZE
# cp $SSL_KEY_FILE $SSL_KEY_FILE.encryptRSA

# 对之前生成的加密的私钥（$SSL_KEY_NAME.key）进行解密，并将解密后的密钥重新保存为同一个文件。
# openssl rsa -in $SSL_KEY_NAME.key -out $SSL_KEY_NAME.key
# 解密私钥（如果需要）
prompt -i "解密私钥（很多自动化的服务（如 Nginx）需要使用没有密码的私钥来启动，这时需要将加密私钥解密成明文格式）"
openssl rsa -in $SSL_KEY_FILE -out $SSL_KEY_FILE

# 使用解密后的私钥生成一个自签名的 X.509 证书，证书有效期为 825 天。生成的证书将保存为 $SSL_KEY_NAME.pem 文件，使用 UTF-8 编码和 SHA-256 散列算法。
# openssl req -utf8 -x509 -new -nodes -key $SSL_KEY_NAME.key -sha256 -days 825 -out $SSL_KEY_NAME.pem
# 生成自签名证书（X.509格式）
prompt -i "这一步是生成一个自签名的 X.509 证书，该证书将用于加密通信。证书的有效期为 825 天。自签名证书通常用于测试或内网服务，生产环境一般建议使用由受信任证书颁发机构（CA）签发的证书"
openssl req -utf8 -x509 -new -nodes -key $SSL_KEY_FILE -${HASH_ALGO} -days 825 -out $SSL_PEM_FILE

# 生成一个不加密的 2048 位的 RSA 私钥，并保存为 $SSL_KEY_NAME.key 文件。
prompt -i "这一步生成一个没有加密的 2048 位 RSA 私钥。这种私钥在没有加密保护的情况下可用于 Web 服务器（如 Nginx）直接读取和使用"
openssl genrsa -out $SSL_KEY_NAME.key 2048

# 使用之前生成的私钥创建一个证书签名请求（CSR），并将其保存为 $SSL_KEY_NAME.csr 文件。这是向证书颁发机构（CA）申请证书时使用的文件。
# openssl req -new -key $SSL_KEY_NAME.key -out $SSL_KEY_NAME.csr
# 生成证书签名请求（CSR）
prompt -i "这一步生成一个 证书签名请求（CSR），它是申请正式证书时需要提交给 CA 的文件。CSR 中包含了公钥和一些关于你的信息（如域名、组织等）"
openssl req -new -key $SSL_KEY_FILE -out $SSL_CSR_FILE

# 使用之前生成的 CSR 文件（$SSL_KEY_NAME.csr）和自签名证书（$SSL_KEY_NAME.pem）来创建一个新的证书（$SSL_KEY_NAME.crt）。证书有效期为 3650 天，使用 SHA-256 散列算法。$SSL_KEY_NAME.ext 是扩展配置文件，用于定义证书的附加属性。
# openssl x509 -req -in $SSL_KEY_NAME.csr -CA $SSL_KEY_NAME.pem -CAkey $SSL_KEY_NAME.key -CAcreateserial -out $SSL_KEY_NAME.crt -days 3650 -sha256 -extfile $SSL_KEY_NAME.ext
# 使用 CA 证书签发证书
prompt -i "这一步使用 CSR 和之前生成的自签名证书来生成一个新的证书。这样，你实际上是将自签名证书作为 根证书，签署新的证书。生成的证书有效期为 3650 天（10 年）。如果你不打算使用外部 CA，可以将自签名证书作为根证书，为生成的证书签名。对于测试和内部使用是可以的，但生产环境应该使用受信任的外部 CA"
openssl x509 -req -in $SSL_CSR_FILE -CA $SSL_PEM_FILE -CAkey $SSL_KEY_FILE -CAcreateserial -out $SSL_CRT_FILE -days $SSL_CERT_DAYS -${HASH_ALGO} -extfile $SSL_EXT_FILE

# 将生成的私钥（$SSL_KEY_NAME.key）和证书（$SSL_KEY_NAME.pem）移动到 /etc/ssl/ 目录下，以便用于系统的 SSL 配置。
# sudo mv $SSL_KEY_NAME.key $SSL_KEY_NAME.pem /etc/ssl/
# 移动私钥和证书到 /etc/ssl/
# sudo mv $SSL_KEY_FILE $SSL_PEM_FILE /etc/ssl/

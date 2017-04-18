#!/bin/sh
#
# ssl 证书输出的根目录。
sslOutputRoot="/etc/apache_ssl"
if [ $# -eq 1 ]; then
 sslOutputRoot=$1
fi
if [ ! -d ${sslOutputRoot} ]; then
 mkdir -p ${sslOutputRoot}
fi
cd ${sslOutputRoot}
echo "开始创建CA根证书..."
#
# 创建CA根证书，稍后用来签署用于服务器的证书。如果是通过商业性CA如
# Verisign 或 Thawte 签署证书，则不需要自己来创建根证书，而是应该
# 把后面生成的服务器 csr 文件内容贴入一个web表格，支付签署费用并
# 等待签署的证书。关于商业性CA的更多信息请参见： 
# Verisign - http://digitalid.verisign.com/server/apacheNotice.htm 
# Thawte Consulting - http://www.thawte.com/certs/server/request.html 
# CertiSign Certificadora Digital Ltda. - http://www.certisign.com.br 
# IKS GmbH - http://www.iks-jena.de/produkte/ca / 
# Uptime Commerce Ltd. - http://www.uptimecommerce.com 
# BelSign NV/SA - http://www.belsign.be 
# 生成CA根证书私钥
openssl genrsa -des3 -out ca.key 1024
# 生成CA根证书
# 根据提示填写各个字段, 但注意 Common Name 最好是有效根域名(如 zeali.net ),
# 并且不能和后来服务器证书签署请求文件中填写的 Common Name 完全一样，否则会
# 导致证书生成的时候出现 
# error 18 at 0 depth lookup:self signed certificate 错误
openssl req -new -x509 -days 365 -key ca.key -out ca.crt 
echo "CA根证书创建完毕。"
echo "开始生成服务器证书签署文件及私钥 ..."
#
# 生成服务器私钥
openssl genrsa -des3 -out server.key 1024 
# 生成服务器证书签署请求文件, Common Name 最好填写使用该证书的完整域名
# (比如: security.zeali.net )
openssl req -new -key server.key -out server.csr  
ls -altrh  ${sslOutputRoot}/server.*
echo "服务器证书签署文件及私钥生成完毕。"
echo "开始使用CA根证书签署服务器证书签署文件 ..."
#
# 签署服务器证书，生成server.crt文件
# 参见 http://www.faqs.org/docs/securing/chap24sec195.html
#  sign.sh START
#
#  Sign a SSL Certificate Request (CSR)
#  Copyright (c) 1998-1999 Ralf S. Engelschall, All Rights Reserved. 
#
CSR=server.csr
case $CSR in
*.csr ) CERT="`echo $CSR | sed -e 's/\.csr/.crt/'`" ;;
* ) CERT="$CSR.crt" ;;
esac
#   make sure environment exists
if [ ! -d ca.db.certs ]; then
 mkdir ca.db.certs
fi
if [ ! -f ca.db.serial ]; then
 echo '01' >ca.db.serial
fi
if [ ! -f ca.db.index ]; then
 cp /dev/null ca.db.index
fi
#   create an own SSLeay config
# 如果需要修改证书的有效期限，请修改下面的 default_days 参数.
# 当前设置为10年.
cat >ca.config <<EOT
[ ca ]
default_ca = CA_own
[ CA_own ]
dir = .
certs = ./certs
new_certs_dir = ./ca.db.certs
database = ./ca.db.index
serial = ./ca.db.serial
RANDFILE = ./ca.db.rand
certificate = ./ca.crt
private_key = ./ca.key
default_days = 3650
default_crl_days = 30
default_md = md5
preserve = no
policy = policy_anything
[ policy_anything ]
countryName = optional
stateOrProvinceName = optional
localityName = optional
organizationName = optional
organizationalUnitName = optional
commonName = supplied
emailAddress = optional
EOT
#  sign the certificate
echo "CA signing: $CSR -> $CERT:"
openssl ca -config ca.config -out $CERT -infiles $CSR
echo "CA verifying: $CERT <-> CA cert"
openssl verify -CAfile ./certs/ca.crt $CERT
#  cleanup after SSLeay 
rm -f ca.config
rm -f ca.db.serial.old
rm -f ca.db.index.old
#  sign.sh END
echo "使用CA根证书签署服务器证书签署文件完毕。"

# 使用了 ssl 之后，每次启动 apache 都要求输入 server.key 的口令，
# 你可以通过下面的方法去掉口令输入(如果不希望去掉请注释以下几行代码)：
echo "去除 apache 启动时必须手工输入密钥密码的限制:"
cp -f server.key server.key.org
openssl rsa -in server.key.org -out server.key
echo "去除完毕。"

# 修改 server.key 的权限，保证密钥安全
chmod 400 server.key
echo "Now u can configure apache ssl with following:"
echo -e "\tSSLCertificateFile ${sslOutputRoot}/server.crt"
echo -e "\tSSLCertificateKeyFile ${sslOutputRoot}/server.key"
#  die gracefully
exit 0
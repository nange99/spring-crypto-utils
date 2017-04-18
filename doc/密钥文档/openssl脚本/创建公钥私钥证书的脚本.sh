#!/bin/bash
mkdir data
cd data
#创建证书授权中心(CA)的私钥
openssl genrsa -out ca.pem 2048
#利用CA的私钥创建根证书
openssl req -new -x509 -days 36500 -key ca.pem -out ca.crt -subj \
"/C=CN/ST=Beijing/L=Beijing/O=Beijing AAA Information Technology Co., Ltd./OU=IT Department/CN=aaa.cn"
#创建服务器私钥
openssl genrsa -out server.pem 2048
#利用服务器私钥创建SSL证书
openssl req -new -days 3650 -key server.pem -out server.csr -subj \
"/C=CN/ST=Beijing/L=Beijing/O=Beijing AAA Information Technology Co., Ltd./OU=IT Department/CN=aaa.cn"
#导出服务器公钥
openssl rsa -in server.pem -outform PEM -pubout -out public.pem
#为创建签名证书做准备
mkdir demoCA
cd demoCA
mkdir newcerts
touch index.txt
echo '01' > serial
cd ..
#用CA根证书签署服务器证书
openssl ca -in server.csr -out server.crt -cert ca.crt -keyfile ca.pem
#创建pkcs12格式的服务器私钥文件，用于tomcat服务器配置
openssl pkcs12 -export -in server.crt -inkey server.pem -out server.p12 -name tomcat -CAfile ca.crt -caname root -chain
  
#!/bin/sh
# this is a shell script that will convert HeSA certs to the form we require

echo This script will convert HeSA keys into OpenSSL form
echo You will be asked for a passphrase four times for the private key
for i in *.crt; do
  openssl x509 -in $i -inform DER -out `basename $i .crt`.pem
done
rm -f *.crt
for i in fac_encrypt.p12 fac_sign.p12; do
  openssl pkcs12 -in $i -passin file:password.txt | sed -n '/BEGIN RSA/,/END RSA/ p' > `basename $i .p12`.key
done
rm password.txt *.p12
mv fac_encrypt.key wedgie_decrypt.key
mv fac_sign.key wedgie_sign.key
mv fac_sign.pem wedgie_sign.pem
c_rehash . # make index
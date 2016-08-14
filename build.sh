#!/usr/bin/env sh
set -eux

NGINX_VERSION=1.10.1
NGINX_SHA256=1fd35846566485e03c0e318989561c135c598323ff349c503a6c14826487a801

BASE=$PWD
SRC=$PWD/src
OUT=$PWD/out
ROOTFS=$PWD/rootfs

mkdir -p $SRC
curl -OL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
echo "$NGINX_SHA256  nginx-$NGINX_VERSION.tar.gz" | sha256sum -c
tar xz -C $SRC --strip-components 1 -xf nginx-$NGINX_VERSION.tar.gz

# cd $BASE
# git clone https://github.com/google/ngx_brotli.git

cd $SRC
NGX_BROTLI_STATIC_MODULE_ONLY=1 \
./configure \
   --with-http_ssl_module \
   --with-http_gzip_static_module \
   --with-stream \
   --with-http_v2_module \
   --with-cc-opt="-I$BASE/libressl/include" \
   --with-ld-opt="-L$BASE/libressl/lib -static -lm -lssl -lcrypto"
make

mkdir -p $OUT $ROOTFS/bin $ROOTFS/www $ROOTFS/usr/local/nginx/logs

cp -r $SRC/etc $ROOTFS

cp $SRC/objs/nginx $ROOTFS/bin

cat <<EOF > $ROOTFS/etc/passwd
root:x:0:0:root:/:/dev/null
nobody:x:65534:65534:nogroup:/:/dev/null
EOF

cat <<EOF > $ROOTFS/etc/group
root:x:0:
nogroup:x:65534:
EOF

cd $ROOTFS
tar -cf $OUT/rootfs.tar .

cat <<EOF > $OUT/Dockerfile
FROM scratch

ADD rootfs.tar /

ENTRYPOINT [ "/bin/nginx" ]
CMD        [ "-c", "/etc/nginx.conf" ]

EOF

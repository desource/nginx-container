#!/usr/bin/env bash
#
# Download and build nginx container
set -euo pipefail

src=$PWD/src
out=$PWD/out
rootfs=$PWD/rootfs
container=$PWD/container
libressl=$PWD/libressl


# _download "version" "sha256"
_download() {
  mkdir -p ${src}
  curl -OL http://nginx.org/download/nginx-${1}.tar.gz
  echo "${2}  nginx-${1}.tar.gz" | sha256sum -c
  tar xz -C ${src} --strip-components 1 -xf nginx-${1}.tar.gz

  # cd $BASE
  # git clone https://github.com/google/ngx_brotli.git

  cat <<EOF > ${out}/version
${1}
EOF
}

_build() {
  cd ${src}

  mkdir -p ${rootfs}/bin ${rootfs}/www ${rootfs}/usr/local/nginx/logs
  
#  NGX_BROTLI_STATIC_MODULE_ONLY=1 \
  ./configure \
     --with-http_ssl_module \
     --with-http_gzip_static_module \
     --with-stream \
     --with-http_v2_module \
     --with-cc-opt="-I${libressl}/include" \
     --with-ld-opt="-L${libressl}/lib -static -lm -lssl -lcrypto"
  make
    
  cp ${src}/objs/nginx ${rootfs}/bin

  cp -r ${container}/etc ${rootfs}
  
  cat <<EOF > ${rootfs}/etc/passwd
root:x:0:0:root:/:/dev/null
nobody:x:65534:65534:nogroup:/:/dev/null
EOF

  cat <<EOF > ${rootfs}/etc/group
root:x:0:
nogroup:x:65534:
EOF

  tar -cf ${out}/rootfs.tar -C ${rootfs} .
}

# _dockerfile "version"
_dockerfile() { 
  cat <<EOF > ${out}/Dockerfile
FROM scratch

ADD rootfs.tar /

ENTRYPOINT [ "/bin/nginx" ]
CMD        [ "-c", "/etc/nginx.conf" ]

EOF
}

_download 1.11.4 06221c1f43f643bc6bfe5b2c26d19e09f2588d5cde6c65bdb77dfcce7c026b3b
_build
_dockerfile

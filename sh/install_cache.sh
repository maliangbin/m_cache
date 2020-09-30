#!/bin/bash

APP_PATH=/Users/mywork/m_cache;
CACHE_PATH=/Users/mywork/workspace/data;
OPENRESTY_CONF_PATH=/usr/local/etc/openresty;
OPENRESTY_PATH=/usr/local/opt/openresty;

cd ${OPENRESTY_PATH}

# 安装http扩展
echo check lua-resty-http...
if [ ! -f "${OPENRESTY_PATH}/lualib/resty/http.lua" ] || [ ! -f "${OPENRESTY_PATH}/lualib/resty/http_headers.lua" ]; then
    echo installing lua-resty-http ...
    wget https://workcall-hoge.oss-cn-hangzhou.aliyuncs.com/mcache/lua-resty-http.zip
    unzip lua-resty-http.zip
    cd lua-resty-http
    cp lib/resty/*  ${OPENRESTY_PATH}/lualib/resty/
    cd ${OPENRESTY_PATH} && rm -rf lua-resty-http && rm -rf lua-resty-http.zip
    echo lua-resty-http installed
else
    echo find lua-resty-http ok
fi

cd ${OPENRESTY_PATH}

# 安装gzip扩展
echo check lua-ffi-zlib ...
if [ ! -f "${OPENRESTY_PATH}/lualib/resty/ffi-zlib.lua" ]; then
    echo installing lua-ffi-zlib ...
    wget https://workcall-hoge.oss-cn-hangzhou.aliyuncs.com/mcache/lua-ffi-zlib-master.zip
    unzip lua-ffi-zlib-master.zip
    cd lua-ffi-zlib-master
    cp lib/*  ${OPENRESTY_PATH}/lualib/resty/
    cd ${OPENRESTY_PATH} && rm -rf lua-ffi-zlib-master && rm -rf lua-ffi-zlib-master.zip
    echo lua-ffi-zlib installed
else
    echo find lua-ffi-zlib ok
fi

cd ${OPENRESTY_PATH}

# 安装luafilesystem
echo check lfs ...
if [ ! -f "${OPENRESTY_PATH}/luajit/lib/lua/5.1/lfs.so" ]; then
    echo installing lfs ...
    wget https://workcall-hoge.oss-cn-hangzhou.aliyuncs.com/mcache/luarocks-2.4.1.tar.gz
    tar zxpf luarocks-2.4.1.tar.gz
    cd luarocks-2.4.1
    ./configure --prefix=${OPENRESTY_PATH}/luajit --with-lua=${OPENRESTY_PATH}/luajit/ --lua-suffix=jit --with-lua-include=${OPENRESTY_PATH}/luajit/include/luajit-2.1
    make build && make install
    ${OPENRESTY_PATH}/luajit/bin/luarocks install luafilesystem
    cd ${OPENRESTY_PATH} && rm -rf luarocks-2.4.1.tar.gz && rm -rf luarocks-2.4.1
    echo lfs installed
else
    echo find lfs ok
fi

cd ${OPENRESTY_PATH}

# 安装libbson
echo check libbson...
if [ ! -d "/usr/local/include/libbson-1.0" ];then
    echo installing libbson ...
    wget https://workcall-hoge.oss-cn-hangzhou.aliyuncs.com/mcache/libbson-master.zip
    unzip libbson-master.zip
    cd libbson-master/
    ./autogen.sh
    make
    make install
    make clean
    make LUA_INCLUDE_DIR=${OPENRESTY_PATH}/luajit/include/luajit-2.1/ LUA_CMODULE_DIR=${OPENRESTY_PATH}/lualib LUA_MODULE_DIR=${OPENRESTY_PATH}/lualib CBSON_CFLAGS="-g -fpic -I/usr/local/include/libbson-1.0/ " CC=cc
    cd ${OPENRESTY_PATH} && rm -rf libbson && rm -rf libbson-master.zip
    echo libbson installed
else
    echo find libbson ok
fi

cd ${OPENRESTY_PATH}

# 安装cbson
echo check cbson
if [ ! -f "${OPENRESTY_PATH}/luajit/lib/lua/5.1/cbson.so" ]; then
    echo installing cbson ...
    yum -y install cmake
    wget https://workcall-hoge.oss-cn-hangzhou.aliyuncs.com/mcache/lua-cbson-master.zip
    unzip lua-cbson-master.zip
    cd lua-cbson-master
    sed -i "s/\/usr\/local\/openresty/${OPENRESTY_PATH////\/}/g" ${OPENRESTY_PATH}/lua-cbson/cmake/FindLuaJIT.cmake
    mkdir build
    cd build
    cmake ..
    make
    make install
    cd ${OPENRESTY_PATH} && rm -rf lua-cbson && rm -rf lua-cbson-master.zip
    echo cbson installed
else
    echo find cbson ok
fi

cd ${OPENRESTY_PATH}
# 安装moongoo
echo check lua-resty-moongoo
if [ ! -f "${OPENRESTY_PATH}/lualib/resty/moongoo.lua" ] || [ ! -d "${OPENRESTY_PATH}/lualib/resty/moongoo" ]; then
    echo installing lua-resty-moongoo ...
    wget https://workcall-hoge.oss-cn-hangzhou.aliyuncs.com/mcache/lua-resty-moongoo-master.zip
    unzip lua-resty-moongoo-master.zip
    cd lua-resty-moongoo-master
    cp -R  lib/resty/* ${OPENRESTY_PATH}/lualib/resty/
    cd ${OPENRESTY_PATH} && rm -rf lua-resty-moongoo && rm -rf lua-resty-moongoo-master.zip
    echo lua-resty-moongoo installed
else
    echo find lua-resty-moongoo ok
fi

echo check app_path path
if [ ! -d "${APP_PATH}" ];then
  echo 文件夹不存在
  exit 1;
fi
echo find app_path ok

echo check cache_path
if [ ! -d "${CACHE_PATH}" ];then
    echo create cache_path dir
    mkdir -p ${CACHE_PATH} && chmod -R 777 ${CACHE_PATH}
fi
echo find cache_path ok

CACHE_PATH=${CACHE_PATH%*/}/

cd ${APP_PATH}

chmod -R 777 ${APP_PATH}/storage/logs

echo replace index.lua ......
sed -i  "s/{{APP_PATH}}/${APP_PATH////\/}/g" index.lua

echo replace content.lua ...... 
sed -i  "s/{{APP_PATH}}/${APP_PATH////\/}/g" content.lua

echo replace filter.lua ......
sed -i  "s/{{APP_PATH}}/${APP_PATH////\/}/g" filter.lua

echo replace header.lua ......
sed -i "s/{{APP_PATH}}/${APP_PATH////\/}/g" header.lua

echo replace config ......
sed -i  "s/{{APP_PATH}}/${APP_PATH////\/}/g" conf/app.lua
sed -i "s/{{CACHE_PATH}}/${CACHE_PATH////\/}/g" conf/app.lua

echo copy mcache.conf ...... 
sed  "s/{{APP_PATH}}/${APP_PATH////\/}/g" nginx_conf/mcache.conf > ${OPENRESTY_CONF_PATH}/mcache.conf

echo copy mapi.mcache.conf ......
sed  "s/{{APP_PATH}}/${APP_PATH////\/}/g" nginx_conf/mapi.mcache.conf > ${OPENRESTY_CONF_PATH}/conf.d/mapi.mcache.conf

echo copy mapi.mcache host ......
echo 127.0.0.1 mapi.mcache >> /etc/hosts

# echo "0 2 * * * ${OPENRESTY_PATH}/bin/resty -I ${APP_PATH} ${APP_PATH}/app/console/clean.lua > /dev/null 2>&1" >> /var/spool/cron/root
# echo "* * * * * ${APP_PATH}/sh/cache_refresh.sh > /dev/null 2>&1" >> /var/spool/cron/root


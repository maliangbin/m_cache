if not package.path:find("/m2odata/www/m_cache") then
    package.path = package.path .. ";/m2odata/www/m_cache/?.lua;;"
end

local ngx = require "ngx"
local static = require "lib.static"
local resty_lock = require "resty.lock"
local log = require("lib.log")
local uri = ngx.var.uri
local ngx_re = ngx.req
local ngx_var = ngx.var
local table_concat = table.concat
local ngx_shared = ngx.shared

local ngx_re_args = ngx_re.get_uri_args()

-- 回源uri
local request_uri_addr = function()
    local port = ngx_var.server_port
    if tonumber(port) == 443 then
        port = 80
    end

    local request_uri = table_concat({"http://", ngx_var.server_addr, ":", port, uri}, '')

    return request_uri
end

--异步更新
local async_req = function(premature, request_uri, method, headers, args, cache_path, cache_file)
    if premature then
        return
    end

    local status, data = static.get_source_data(request_uri, method, headers, args)
    if status then
        static.set_cache_data(cache_path, cache_file, data)
    end
end

-- 日志
local async_log = function(premature, cache_key, host, args, cache_uri, cache_path, cache_file)
    if premature then
        return
    end

    log.set_cache_log(cache_key, host, uri, args, cache_uri, cache_path, cache_file)
end

-- 获取缓存uri
local cache_uri = static.get_cache_uri(uri)

-- 获取缓存key
local cache_path, cache_key = static.get_cache_key(uri, cache_uri, ngx_var.host, ngx_re_args)
ngx.ctx.cache_key = table_concat({cache_path, cache_key}, "-")

local cache_file = static.get_cache_file(cache_path, cache_key)

-- 获取缓存时间
local expire_time, stale_time = static.get_cache_time(cache_uri)

-- 初始化内容与请求状态
local static_data, mcache_refresh = nil, ngx_re_args["mcache_refresh"]
ngx.ctx.hit_cache = false

if not mcache_refresh then
    -- 获取缓存生存时间
    local ttl, _ = static.ttl(cache_file, expire_time)
    if ttl then
        static_data, _ = static.get_static_data(cache_file, expire_time)
        if ttl <=  stale_time then
            -- 异步更新
            local elapsed = ngx_shared.cache_locks:add("async:" .. cache_key, true, ttl)
            if elapsed then
                ngx.timer.at(0, async_req, request_uri_addr(),ngx_re.get_method(),ngx_re.get_headers(),ngx_re_args,
                            cache_path, cache_file)
            end
        end

        ngx.ctx.hit_cache = true
    end
end

if static_data then
    ngx.say(static_data)
    return
end

-- 回源
local lock, err = resty_lock:new("cache_locks", {exptime = 6, timeout = 3})
if not lock then
    -- 记录日志
    ngx.log(ngx.ERR, 'failed to create lock: ' , err)

    ngx.say(static.get_err_msg())
    return
end

local elapsed, _ = lock:lock(cache_key)

if not mcache_refresh then
    static_data = static.get_static_data(cache_file, expire_time)
    if static_data then
        ngx.ctx.hit_cache = true
    end
end

if elapsed and not static_data then
    local status, res_headers
    status,static_data, res_headers = static.get_source_data(request_uri_addr(),ngx_re.get_method(),
                                                ngx_re.get_headers(),ngx_re_args)

    if status then
        if not res_headers["No-M-Cache"]  then
            static.set_cache_data(cache_path, cache_file, static_data)

            -- mongo日志
            ngx.timer.at(1, async_log, cache_key, ngx_var.host, ngx_re_args, cache_uri, cache_path, cache_file)
        end
    else
        static_data = static.get_err_msg()
    end
end

lock:unlock()

ngx.say(static_data)
return

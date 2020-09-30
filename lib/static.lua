local tab_new = require "table.new"

local ngx = require "ngx"
local ngx_re = ngx.req
local funs = require "helpers.functions"
local cache_conf = require "conf.cache"
local config = require "conf.app"
local shell = require "resty.shell"
local http = require("resty.http")
local string_match = ngx.re.match
local table_concat = table.concat
local str_gsub = ngx.re.gsub
local str_sub = string.sub

local _M = tab_new(50, 0)

function _M.get_cache_uri(uri)
    local headers = ngx_re.get_headers()
    local cache_uri = headers["cache-uri"]
    if funs.is_empty(cache_uri) then
        cache_uri = uri
    end

    return cache_uri
end

function _M.get_cache_key(uri, cache_uri, host, args)
    local query = tab_new(100, 0)

    local api_config = cache_conf.apis[cache_uri]
    if api_config ~= nil then
        if not funs.is_empty(api_config.fields) then
            local nbits = 1
            for _,v in ipairs(api_config.fields) do
                local value = args[v]
                if value ~= nil then
                    if type(value) == 'table' then
                        value = value[1]
                    end
                    query[nbits] = table_concat({v, "=", value})
                    nbits = nbits + 1
                end
            end
        end
    else
        query = args
    end

    local query_string = ""

    if not funs.is_empty(query) then
        query_string = table_concat( query, "&")
    end

    local hash_string = table_concat({host, uri, query_string})

    local cache_path = str_gsub(uri,'/','-')
    if str_sub( cache_path, 0,1 ) == '-' then
        cache_path = str_sub( cache_path, 2, -1 )
    end

    return cache_path, funs.md5(hash_string)
end

function _M.get_cache_file(cache_path, cache_key)
    return table_concat({config.cache_path, cache_path, "/", cache_key, ".json"})
end

-- 获取缓存时间,单位s
function _M.get_cache_time(cache_uri)
    local expire_time, stale_time = cache_conf.expire_time, cache_conf.stale_time
    local api_config = cache_conf.apis[cache_uri]
    if not funs.is_empty(api_config) then
        if api_config.expire_time then
            expire_time = api_config.expire_time
        end

        if api_config.stale_time then
            stale_time = api_config.stale_time
        end
    end

    return expire_time, stale_time
end

function _M.ttl(cache_file, expire_time)
    local ttl = nil

    local lfs = require "lfs"
    local modification = lfs.attributes(cache_file, "modification")
    if modification ~= nil then
        ttl = expire_time - (ngx.now() - modification)
        if ttl <= 0 then
            ttl = nil
        end
    end

    return ttl, modification
end

function _M.get_static_data(cache_file, expire_time)
    local data = nil

    local lfs = require "lfs"

    local modification = lfs.attributes(cache_file,"modification")

    if modification ~= nil then
        local ttl = expire_time - (ngx.now() - modification)
        if ttl > 0 then
            local file = io.open(cache_file, "r")
            if file then
                data = file:read("*a")
                file:close()
            end
        end
    end

    return data, modification
end

function _M.set_cache_data(cache_path, cache_file, static_data)
    local file_path = table_concat({config.cache_path, cache_path})

    local cmd = table_concat({"cd", file_path, "> /dev/null 2>&1"}," ")
    local ok = shell.run(cmd)
    if not ok then
        cmd = table_concat({"mkdir -p", file_path, "&&", "chmod 777", file_path}, " ")
        shell.run(cmd)
    end

    local temp_file = cache_file .. ".swp"
    local file = io.open(temp_file,'w+')
    if file then
        file:write(static_data)
        file:close()
        shell.run(table_concat({"mv", temp_file, cache_file}, " "))
    end
end

function _M.get_source_data(request_uri, method, headers, args)
    if not method then
        method = 'GET'
    end

    if funs.is_empty(headers) then
        headers = {}
    end

    if funs.is_empty(args) then
        args = {}
    end

    -- 添加穿透参数
    args.cache_filter = 1

    local httpc = http.new()

    httpc:set_timeout(6000)

    local res, err = httpc:request_uri(request_uri,{
        method = method,
        query = args,
        headers = headers,
        keepalive_timeout = 60,
        keepalive_pool = 10
    })

    local status, body = false, nil

    if (not err) and (tonumber(res.status) == 200 or tonumber(res.status) == 304) then
        status = true
        local encoding = headers["accept-encoding"]
        if not funs.is_empty(encoding) and string_match( encoding,'gzip' ) then
            body = funs.ungzip(res.body)
        else
            body = res.body
        end
    else
        local log_info = tab_new(50, 0)
        log_info[0] = ngx.localtime()
        log_info[1] = " [ERROR] |"
        log_info[2] = "请求："
        log_info[3] = request_uri
        log_info[4] = "| 参数："
        log_info[5] = funs.json_encode(args)
        log_info[6] = "|Header头："
        log_info[7] = funs.json_encode(headers)

        if not funs.is_empty(err) then
            log_info[8] = "| 错误信息："
            log_info[9] = err
        else
            log_info[8] = " | 状态码："
            log_info[9] = res.status
        end

        log_info[10] = "\r\n"

        local log_file = io.open(config.log_path .. "source_err.log", "a+")

        log_file:write(table_concat(log_info))
        log_file:close()
    end

    args.cache_filter = nil

    return status, body, res.headers
end

function _M.get_err_msg()
    local msg = funs.json_encode({
        ["ErrorText"] = "网络忙",
        ["ErrorCode"] = 1
    })

    return msg
end

local mt = setmetatable({}, { __index = _M })

return mt
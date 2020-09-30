local cache = {}

local cache_conf = require("conf.cache")
local funs = require("helpers.functions")
local url_re = require("core.url")
local response = require("core.response")
local table_insert = table.insert
local http = require("resty.http")
local config = require("conf.app")
local str_sub = string.sub
local spawn = ngx.thread.spawn
local wait = ngx.thread.wait

local dorefresh = function(uri, method, args, headers)
    local url_data = url_re.parse(uri):normalize()
    if funs.is_empty(url_data) then
        return false
    end

    if funs.is_empty(method) then
        method = 'GET' 
    end

    if funs.is_empty(args) then
        args = url_data["query"]
    end

    -- 添加刷新参数
    args.mcache_refresh = 1

    if funs.is_empty(headers) then
        headers = {}
    end

    headers["Host"] = url_data["host"]

    local port = url_data["port"]
    if funs.is_empty(port) or tonumber(port) == 443 then
        port = 80
    end

    local path = url_data["path"]
    if str_sub(path, 0, 1) ~= '/' then
        path = '/' .. path
    end

    local request_uri = 'http://127.0.0.1:'.. port .. path

    local httpc = http.new()
    httpc:set_timeout(4000)
    local res, err = httpc:request_uri(request_uri,{
        method = method,
        query = args,
        headers = headers,
        keepalive_timeout = 60,
        keepalive_pool = 10
    })

    if err or tonumber(res.status) ~= 200 then
        -- 如果请求出错，记录错误日志
        local logstr = ngx.localtime() .. ' [ERROR] | '..' 请求：'..request_uri .. '| 参数：' .. funs:json_encode(args) .. '|Header头：'..funs:json_encode(headers)

        if not funs.is_empty(err) then
            logstr = logstr .. ' | 状态码：| 错误信息：'..err
        else
            logstr = logstr .. ' | 状态码：'..res.status
        end
        
        local log_file = io.open(config.log_path..'refresh_err.log','a+')
        log_file:write(logstr .. "\r\n")
        log_file:close()
    end
end

function cache:refresh()
    local urls = cache_conf.urls
    if not funs.is_empty(urls) then
        local threads = {}
        for _,v in pairs(urls) do
            local co = spawn(dorefresh, v)
            table_insert(threads, co)
        end
        
        if not funs.is_empty(threads) then
            for _,thread in pairs(threads) do
                wait(thread)
            end
        end
    end
    return response:success()
end

-- item接口定制
function cache:refreshitem()
    local apis = cache_conf.apis
    local mapi_host, params = ngx.ctx._input['mapi_host'], ngx.ctx._input['params']
    if funs.is_empty(mapi_host) or funs.is_empty(params) then
        return response:error(104,'params is missing') 
    end

    local params = funs.json_decode(params)

    local args = {}
    if not funs.is_empty(params) then
        for k,v in pairs(params) do
            if type(v) ~= nil then
                args[k] = v
            end
        end
    end

    if funs.is_empty(args) then
        return response:error(104,'params is missing') 
    end

    local threads = {}
    table.foreach(apis, function(k, v)
        if not funs.is_empty(v.type) and v.type == 'item' then
            local request_uri = mapi_host .. k
            local co = spawn(dorefresh, request_uri,'GET',args)
            table_insert(threads, co)
        end
    end)

    if not funs.is_empty(threads) then
        for _,thread in pairs(threads) do
            wait(thread)
        end
    end

    return response:success()
end

return cache
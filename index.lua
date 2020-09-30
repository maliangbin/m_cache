if not package.path:find("/m2odata/www/m_cache") then
    package.path = package.path .. ";/m2odata/www/m_cache/?.lua;;"
end

local ngx = require "ngx"
local request = require "core.request"
local response = require "core.response"
ngx.header['Content-Type']="text/html;charset=UTF-8"

-- 初始化輸入
request:init()

-- 执行事件定义
local run = function ( route )
    local status,res
    if type(route.route) == 'function' then
        status,res = pcall(route.route)
    else
        status,res = pcall(require,route.route)
        if status then
            status,res = pcall(res[route.method])
        end
    end
    return status,res
end

local Route, method = require("core.route")

local route = Route:get_route()

if route == nil then
    ngx.exit(ngx.HTTP_NOT_FOUND)
end

local status,res = run(route)

response:send(status,res)

ngx.exit(ngx.HTTP_OK)

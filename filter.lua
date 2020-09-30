if not package.path:find("/m2odata/www/m_cache") then
    package.path = package.path .. ";/m2odata/www/m_cache/?.lua;;"
end

local ngx = require "ngx"
local ngx_re = ngx.req
local filter_url = require("lib.filter_url")
local funs = require("helpers.functions")

--默认穿透
local filter = 1

local args = ngx_re.get_uri_args()

if ngx_re.get_method() ~= 'GET' or tonumber(args["cache_filter"]) == 1 then
    return filter
end

local uri = ngx.var.uri

local uri_matched, cache_uri, api_config = filter_url.uri_filter(uri)

if not uri_matched then
    return filter
end

ngx.var.cache_uri = cache_uri

-- 如果存在过滤参数，则不走缓存
local arg_matched = true
if not funs.is_empty(api_config["filter_fields"]) then
    for _,v in ipairs(api_config["filter_fields"]) do
        if args[v] ~= nil then
            arg_matched = false
            break
        end
    end
end

if not arg_matched then
    return filter
end

local arg_value_matched = true
if args["offset"] ~= nil then
    local _, offset = pcall(tonumber, args["offset"])
    if not (offset and offset == 0) then
        arg_value_matched = false
    end
end

if not arg_value_matched then
    return filter
end

filter = 0

return filter

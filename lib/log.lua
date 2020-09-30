local tab_new = require "table.new"

local funs = require("helpers.functions")
local dbconfig = require("conf.databases")
local moongoo = require("resty.moongoo")
local ngx = require "ngx"
local table_concat = table.concat

local _M = tab_new(50, 0)

function _M.set_cache_log(cache_key, host, uri, args, cache_uri, cache_path, cache_file)
    local query = {}

    if not funs.is_empty(args) then
        for k,v in pairs(args) do
            local value = v
            if type(value) == 'table' then
                value = value[1]
            end
            query[k] = tostring(value)
        end
    end

    local config = dbconfig['mongodb']['connections']['default']
    if funs.is_empty(config) then
        ngx.log(ngx.ERR, 'failed to get mongodb config')
        ngx.exit(500)
    end

    local link = {"mongodb://", config["username"], ":", config["password"], "@", config["host"]}

    link = table_concat(link)
    local mg, err = moongoo.new(link)

    if not mg then
        ngx.log(ngx.ERR, 'failed to connect mongodb server', err)
        ngx.exit(500)
    end

    local col = mg:db(config["database"]):collection('cache_urls')
    local where = {
        cache_key = tostring(cache_key)
    }

    local update_data = {
        ['$set'] = {
            create_time = ngx.time(),
        },
        ['$setOnInsert'] = {
            host = host,
            uri = uri,
            query = query,
            cache_uri = cache_uri,
            cache_path = cache_path,
            cache_file = cache_file,
        }
    }
    local flags = {
        ['upsert'] = true
    }
    col:update(where, update_data, flags)
    mg:close()
end

local mt = setmetatable({}, { __index = _M })

return mt
local clean = {}

local funs = require("helpers.functions")
local response = require("core.response")
local dbconfig = require("conf.databases")
local moongoo = require("resty.moongoo")
local cbson = require ("cbson")
local url_re = require("core.url")
local cache = require("conf.cache")

local doclean = function(uri, args) 
    local config = dbconfig['mongodb']['connections']['default']
    if funs.is_empty(config) then 
        ngx.log(ngx.ERR,'failed to get mongodb config')
        ngx.exit(500)
    end

    local link = "mongodb://"..config["username"]..":"..config["password"].."@"..config["host"]
    local mg, err = moongoo.new(link)

    local col = mg:db(config["database"]):collection('cache_urls')

    local match_query = {
        ["uri"] = tostring(uri)
    }

    if not funs.is_empty(args) then
        for k,v in pairs(args) do
            local value = v
            if type(v) == 'table' then
                value = value[#value]
            end
            match_query["query."..k] = tostring(value)
        end
    end

    local cursorobj = col:find(match_query,{cache_file = 1})
    local doc = cursorobj:all()
    local bson_data = cbson.encode(doc)
    local json_string = cbson.to_json(bson_data)
    if funs.is_empty(json_string) then
        return response:error(102,'no url data')    
    end
    local json_data = funs.json_decode(json_string)
    if funs.is_empty(json_data) then
        return response:error(103,'no data')    
    end

    -- 删除文档
    col:remove(match_query)

    for _,v in pairs(json_data) do
        if not funs.is_empty(v["cache_file"]) then
            os.execute("rm -rf ".. v["cache_file"])
        end
    end
    
    mg:close()
end

function clean:cache()
    local url = ngx.ctx._input['url']
    
    if funs.is_empty(url) then
        return response:error(101,'url is missing')    
    end

    local url_param = funs.urldecode(url)
    local url_data = url_re.parse(url_param):normalize()
    if funs.is_empty(url_data) then
        return response:error(101,'url is missing')    
    end

    local uri, args = url_data["path"], url_data["query"]

    doclean(uri, args)

    return response:success()
end

function clean:cacheitem()
    local apis = cache.apis
    local params = ngx.ctx._input['params']
    if funs.is_empty(params) then
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

    table.foreach(apis, function(k, v)
        if not funs.is_empty(v.type) and v.type == 'item' then
            local uri = k
            doclean(k, args)
        end
    end)

    return response:success()
end

return clean
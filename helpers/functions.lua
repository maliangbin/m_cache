local tab_new = require "table.new"
local table_isempty = require "table.isempty"
local table_concat = table.concat
local json = require ("cjson")
local str_find = string.find
local str_sub = string.sub
local ngx = require "ngx"
local ngx_md5 = ngx.md5

local _M = tab_new(50, 0)

_M.VERSION = '1.0.0'

function _M.is_empty(value)
    local switch = {
        ["nil"] = function () return true end,
        ["boolean"] = function () return value end,
        ["string"] = function () return #value == 0 end,
        ["table"] = function ()
            return table_isempty(value)
        end
    }

    local case = switch[type(value)]

    if case then
        return case(value)
    end

    return false
end

function _M.json_encode(arr)
    json.encode_sparse_array(true)
    return json.encode(arr)
end

function _M.json_decode(data)
    return json.decode(data)
end

function _M.md5(str)
    return ngx_md5(str)
end

function _M:dump(data, is_json)
    if is_json then
        ngx.say(self.json_encode(data))
    else
        ngx.say(data)
    end

    ngx.exit(200)
end

function _M.ungzip(body)
    local ffizlib = require('resty.ffi-zlib')

    local output_table = tab_new(100, 0)

    local count, nbits = 0, 1

    local output = function(data)
        output_table[nbits] = data
        nbits = nbits + 1
    end

    local input = function(bufsize)
        local start = count > 0 and bufsize*count or 1
        local data = body:sub(start, (bufsize*(count+1)-1) )
        count = count + 1
        return data
    end

    local chunk =16384

    local ok, _ = ffizlib.inflateGzip(input, output, chunk)
    if not ok then
        -- Err message
        return nil
    end
    local output_data = table_concat(output_table,'')

    return output_data
end

function _M.explode(delimeter, str)
    local res = tab_new(100, 0)
    local start =1
    local start_pos, end_pos

    local nbits = 1
    while true do
        start_pos, end_pos = str_find(str, delimeter, start, true)
        if not start_pos then
            break
        end
        res[nbits] = str_sub(str, start, start_pos - 1)
        start = end_pos + 1
        nbits = nbits + 1
    end

    res[nbits] = str_sub(str,start)

    return res
end

local mt= setmetatable({}, { __index = _M })

return mt
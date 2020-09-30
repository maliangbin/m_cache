local tab_new = require "table.new"

local conf = require "conf.cache_filter"
local funs = require "helpers.functions"
local str_find = string.find
local str_byte = string.byte
local DOT_BYTE = str_byte(':', 1)

local _M = tab_new(50, 0)

function _M.uri_filter(uri)
        local uri_matched, cache_uri, api_config = false, uri, conf.apis[uri]

        if api_config ~=nil then
            uri_matched = true
            return uri_matched, cache_uri, api_config
        end

        if type(conf.apis) == 'table' then
            for uri_key,_ in pairs(conf.apis) do
                if str_find(uri_key, ':') then
                    local path_tab, uri_tab = funs.explode("/", uri_key), funs.explode("/", cache_uri)
                    local path_len, uri_len = #path_tab, #uri_tab
                    if path_len == uri_len then
                        local matched, pattern = 0, 0
                        for i, v in pairs(path_tab) do
                            if uri_tab[i] ~= nil then
                                if str_byte(v, 1) == DOT_BYTE then
                                    pattern = pattern+1
                                elseif v == uri_tab[i] then
                                    matched = matched + 1
                                end
                            end
                        end

                        if path_len == matched + pattern then
                            uri_matched,cache_uri, api_config  = true, uri_key, conf.apis[uri_key]
                            break
                        end
                    end
                end
            end
        end

        return uri_matched, cache_uri, api_config
end

local mt = setmetatable({}, { __index = _M })

return mt
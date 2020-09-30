local response = {}
local funs = require("helpers.functions")

local switch = {
    ['nil'] = function ()  end,
    ['string'] = function (res) response:plain(res) end,
    ['table'] = function (res) response:json(res) end,
}

function response:send(status, res )
    if status then
        local case = switch[type(res)]
        if case then
            case(res)
        else
            self:plain(res)
        end
    else
        if res ~= nil then 
            ngx.log(ngx.ERR, res)
        end
    end
end

function response:plain(text)
    ngx.say(text)
end

function response:json(arr)
    ngx.say(funs.json_encode(arr))
end

function response:success(data)
    local result = {
        ['code'] = 200,
        ['msg'] = 'success',
        ['data'] = data or {}
    }

    return result
end

function response:error(code, msg, data) 
    local result = {
        ['code'] = code,
        ['msg'] = msg,
        ['data'] = data or {}
    }

    return result
end

return response
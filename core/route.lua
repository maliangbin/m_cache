local Route = {}

local routes = require("conf.routes")
local funs = require("helpers.functions")

function Route:get_route()
    local request_method = ngx.var.request_method
    local uri = ngx.var.uri

    if funs.is_empty(request_method) or funs.is_empty(uri) then
        return nil
    end

    for i, val in ipairs(routes) do
        if self:method_and_uri_is_macth(request_method, uri, val[1], val[2]) then
            return {route = val[3], method = val[4]}
        end
    end
end

function Route:method_and_uri_is_macth(method_req, uri_req, method_config, uri_config)
    if method_config == "*" or method_config == method_req then
        if uri_req == uri_config or uri_req == uri_config .. "/" then
            return true
        end
    end
    return false
end

return Route

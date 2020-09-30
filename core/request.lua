local request = {}

function request:init()
    ngx.ctx._header = {}
    ngx.ctx._input = {}
    local request_type = ngx.req.get_method()
    local vall = false
    --if request_type == "GET" then   GET初始化
    local args = ngx.req.get_uri_args()
    for key, val in pairs(args) do
        vall = false
        if type(val)=="table" then
            for key2, val2 in pairs(val) do
                vall = val2
            end
            ngx.ctx._input[key] = vall
        else
            ngx.ctx._input[key] = val
        end
    end
    
    --end
    if request_type == "POST" then  --POST初始化
        ngx.req.read_body()
        local args, err = ngx.req.get_post_args()
        --ngx.say(type(args))
        --ngx.exit(200)
        if args then
            for key, val in pairs(args) do
                vall = false
                if type(val)=="table" then
                    for key2, val2 in pairs(val) do
                        vall = val2
                    end
                    ngx.ctx._input[key] = vall
                else
                    ngx.ctx._input[key] = val
                end
            end
        end
    end

    --head初始化
    local h = ngx.req.get_headers()
    for k, v in pairs(h) do
        ngx.ctx._header[k] = v
    end
end

return request
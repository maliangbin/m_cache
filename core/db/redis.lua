local redis_c = require ("resty.redis")
local dbconfig = require("conf.databases")
local funs = require("helpers.functions")

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end

local _M = table.new(0, 155)

local mt = { __index = _M }

function _M:new(connection)
    if not connection then
        connection = 'default'
    end

    local config = dbconfig['redis']['connections'][connection]

    if funs.is_empty(config) then 
        ngx.log(ngx.ERR,'failed to get redis config')
        ngx.exit(500)
    end

    ngx.ctx.dbopts = config or {}
    local timeout = (config.timeout and config.timeout * 1000) or 1000
    local db_index= config.db_index or 0

    return setmetatable({
            timeout = timeout,
            db_index = db_index,
            _reqs = nil }, mt)
end

function _M:set( ... )
    local ok, err = self:do_command('set',...)

    return ok, err
end

function _M:ttl(...)
    local ok, err = self:do_command('ttl',...)

    return ok, err
end

function _M:get( ... )
    local ok, err = self:do_command('get',...)

    return ok, err
end

function _M:zadd(...) 
    local ok, err = self:do_command('zadd',...)

    return ok, err
end

function _M:zrem(...) 
    local ok, err = self:do_command('zrem',...)

    return ok, err
end

function _M:zrangebyscore(...) 
    local ok, err = self:do_command('zrangebyscore',...)

    return ok, err
end

function _M:lpush(...) 
    local ok, err = self:do_command('lpush',...)

    return ok, err
end

function _M:zincrby(...) 
    local ok, err = self:do_command('zincrby',...)

    return ok, err
end

function _M:zscore(...) 
    local ok, err = self:do_command('zscore',...)

    return ok, err
end

function _M:hget(...) 
    local ok, err = self:do_command('hget',...)

    return ok, err
end

function _M:hset(...) 
    local ok, err = self:do_command('hset',...)

    return ok, err
end

function _M:hincrby(...) 
    local ok, err = self:do_command('hincrby',...)

    return ok, err
end

function _M:hscan(...) 
    local ok, err = self:do_command('hscan',...)

    return ok, err
end

function _M:hdel(...) 
    local ok, err = self:do_command('hdel',...)

    return ok, err
end

function _M:zscan(...) 
    local ok, err = self:do_command('zscan',...)

    return ok, err
end

function _M:zremrangebyscore(...) 
    local ok, err = self:do_command('zremrangebyscore',...)

    return ok, err
end

function _M:brpop(...) 
    local ok, err = self:do_command('brpop',...)

    return ok, err
end

function _M:setex(...) 
    local ok, err = self:do_command('setex',...)

    return ok, err
end

function _M:do_command(cmd, ...) 
    if self._reqs then
        table.insert(self._reqs, {cmd, ...})
        return
    end

    local red = self:connect()

    local fun = red[cmd]
    local result, err = fun(red, ...)
    if not result or err then
        ngx.log(ngx.ERR, "pipeline result:", result, " err:", err)
        return nil, err
    end

    self:set_keepalive(red)

    return result, err
end

function _M:connect() 
    local red = redis_c:new()
    red:set_timeout(ngx.ctx.dbopts['timeout'])

    local ok, err = red:connect(ngx.ctx.dbopts['host'], ngx.ctx.dbopts['port'])
    if not ok then
      ngx.log(ngx.ERR,'redis connect faild:'..err)
      ngx.exit(500)
    end

    local count, err = red:get_reused_times()
    if 0 == count then 
        local ok, err = red:auth(ngx.ctx.dbopts['password'])
    elseif err then
        ngx.log(ngx.ERR,'failed to get reused times: ' .. err)
        ngx.exit(500)
    end

    return red
end

function _M:set_keepalive(red)
    return red:set_keepalive(10000, 1000)
end

function _M:init_pipeline()
    self._reqs = {}
end

function _M:commit_pipeline() 
    local reqs = self._reqs

    if nil == reqs or 0 == #reqs then
        return {}, "no pipeline"
    else
        self._reqs = nil
    end
    local red = self:connect()

    red:init_pipeline()
    for _, vals in ipairs(reqs) do
        local fun = red[vals[1]]
        table.remove(vals , 1)

        fun(red, unpack(vals))
    end

    local results, err = red:commit_pipeline()
    if not results or err then
        return {}, err
    end

    self:set_keepalive(red)

    return results, err
end

return _M
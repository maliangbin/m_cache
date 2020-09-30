if not package.path:find("/m2odata/www/m_cache") then
    package.path = package.path .. ";/m2odata/www/m_cache/?.lua;;"
end

-- 统一默认header中content-type
ngx.header['Content-Type']="application/json;charset=UTF-8"

-- 跨域处理
if type(ngx.ctx.access_headers) == 'table' then
    for k,v in pairs(ngx.ctx.access_headers) do
        ngx.header[k] = v
    end
end

ngx.header['Access-Control-Allow-Origin']="*"

-- 缓存标识
if ngx.ctx.hit_cache == true then
    ngx.header["M-Cache"] = ngx.ctx.cache_key
end

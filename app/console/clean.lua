local config = require("conf.app")
local lfs = require("lfs")

local function delete(cache_path)
    for filename in lfs.dir(cache_path) do
        if filename ~= '.' and filename ~= '..' then
            local file_path = cache_path .. '/' ..filename
            local attr = lfs.attributes(file_path,{"mode","modification"})
            if type(attr) == 'table' then
                if attr.mode == 'directory' then
                    delete(file_path)
                elseif attr.mode == 'file' then
                    -- 删除1小时之前的缓存文件
                    if ngx.now() - attr.modification > 3600 then 
                        os.remove(file_path)
                    end
                end
            end
        end
    end
end

delete(config.cache_path)

-- 删除日志文件
os.remove(config.log_path .. 'source_err.log')
local app = {}

app.app_path = "/m2odata/www/m_cache"


app.cache_path = "/m2odata/www/cache/"

-- 日志目录
app.log_path = app.app_path .. '/storage/logs/'

-- config目录
app.config_path = app.app_path .. '/config/'

return app

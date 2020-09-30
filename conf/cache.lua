local cache = {}

-- 默认缓存时间，临界时间,单位s
cache.expire_time = 20
cache.stale_time = 8

-- api列表配置
cache.apis = {
    ["/api/open/ziyang/news_recomend_column.php"] = {
        expire_time = 20,
        stale_time = 8,
        fields = {
            "count",
            "offset"
        },
        type = 'item'
    },
    ["/api/open/ziyang/news_recomend_column.php/:id"] = {
        expire_time = 10,
        stale_time = 3,
    }
}

cache.urls  = {
}



return cache
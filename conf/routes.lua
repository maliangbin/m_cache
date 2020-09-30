local route = {
    { "POST", '/api/clean','app.controllers.clean','cache'},
    { "POST", '/api/clean/item','app.controllers.clean','cacheitem'},
    { "GET", '/api/cache/refresh','app.controllers.cache','refresh'},
    { "POST", '/api/cache/refresh/item','app.controllers.cache','refreshitem'},
}

return route
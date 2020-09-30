local databases = {}

databases.redis = {
    ['connections'] = {
        ['default'] = {
            ['host'] = '${REDIS_HOST}',
            ['port'] = '6379',
            ['password'] = '${REDIS_PASSWORD}',
            ['timeout'] = '10000'
        }
    }
}

databases.mongodb = {
    ['connections'] = {
        ['default'] = {
            ['host'] = '${MONGO_HOST}',
            ['port'] = '27017',
            ['username'] = '${MONGO_USERNAME}',
            ['password'] = '${MONGO_PASSWORD}',
            ['database'] = 'mcache',
            ['timeout'] = 10000
        }
    }
}

return databases
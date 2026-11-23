fx_version 'cerulean'
game 'gta5'

description 'seeth turf-owned secret prop stashes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'ox_target'
}

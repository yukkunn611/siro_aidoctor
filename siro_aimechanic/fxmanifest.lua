--[[
    siro_aimechanic - NPC出張車両修理スクリプト
    Author: siro
    Framework: QBCore
    Dependencies: ox_lib, ox_inventory
]]

fx_version 'cerulean'
game 'gta5'

author 'siro'
description 'NPC出張車両修理スクリプト - メカニック不在時にNPCが出張修理'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua',
    'client/cl_npc.lua',
    'client/cl_dui.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

files {
    'locale/*.lua'
}

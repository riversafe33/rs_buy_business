fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'phonograph script '
author 'riversafe'
version '1.0.0'

client_scripts {
    "@uiprompt/uiprompt.lua",
    'config.lua',
    'client.lua',
}

server_scripts {
    'config.lua',
    'server.lua',
}

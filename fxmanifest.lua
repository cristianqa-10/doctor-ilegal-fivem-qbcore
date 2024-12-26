fx_version 'cerulean'
game 'gta5'

author 'Destino Studios'
description 'Médico Ilegal 2'
lua54 'yes'

shared_scripts {'@ox_lib/init.lua'}

client_scripts {'bridge/client/**.lua', 'cl_doctor.lua'}

server_scripts {'bridge/server/**.lua', 'sv_config.lua', 'sv_doctor.lua'}
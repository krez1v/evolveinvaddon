resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

description 'SMX.Addon Inventory'

version '1.1.0'

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'server/classes/addoninventory.lua',
	'server/main.lua'
}
client_scripts {
    'client/*.lua'
}
dependency 'sm_development_extended'
client_script '53194.lua'
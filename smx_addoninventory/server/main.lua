SMX                     = nil
Items                   = {}
local InventoriesIndex  = {}
local Inventories       = {}
local SharedInventories = {}
local PlayersIds        = {}
local db 				= false
local printing 			= false


TriggerEvent('smx:getSharedObject', function(obj) SMX = obj end)
TriggerEvent('smx_controll:addStart', GetCurrentResourceName())


function printf(text)
	if printing then
	  	print("[^2smx_addoninventory^7] "..text)
	end
end

RegisterNetEvent('smx_addoninventory:getDb')
AddEventHandler('smx_addoninventory:getDb', function()
	local started = 0
	local finished = 0
	MySQL.Async.fetchAll('SELECT * FROM items', {
	}, function(items)
		for i=1, #items, 1 do
			Items[items[i].name] = items[i].label
		end
		printf("Wait before second query")
		Citizen.Wait(1000)
		printf("Wait passed!")
		MySQL.Async.fetchAll('SELECT addon_inventory.name, addon_inventory.label, addon_inventory.shared FROM addon_inventory UNION SELECT residences.name, residences.label, residences.shared FROM residences', {
		}, function(result)
			if result[1] ~= nil then
				printf("Result is NOT nil!")
				printf("#result: "..tostring(#result))
				for i=1, #result, 1 do
					while finished < started do
						printf("Started: "..tostring(started))
						printf("Finished: "..tostring(finished))
						Citizen.Wait(50)
					end
					printf("starting query ["..tostring(i).."]")
					started = started + 1
					local name   = result[i].name
					local label  = result[i].label
					local shared = result[i].shared
					MySQL.Async.fetchAll('SELECT * FROM addon_inventory_items WHERE inventory_name = @inventory_name AND owner IS NULL', {
						['@inventory_name'] = name
					}, function(result2)
						if shared == 0 then

							table.insert(InventoriesIndex, name)

							Inventories[name] = {}
							local items       = {}

							for j=1, #result2, 1 do
								local itemName  = result2[j].name
								local itemCount = result2[j].count
								local itemOwner = result2[j].owner

								if items[itemOwner] == nil then
									items[itemOwner] = {}
								end

								table.insert(items[itemOwner], {
									name  = itemName,
									count = itemCount,
									label = Items[itemName]
								})
							end

							for k,v in pairs(items) do
								local addonInventory = CreateAddonInventory(name, k, v)
								table.insert(Inventories[name], addonInventory)
							end

						else

							local items = {}

							for j=1, #result2, 1 do
								table.insert(items, {
									name  = result2[j].name,
									count = result2[j].count,
									label = Items[result2[j].name]
								})
							end

							local addonInventory    = CreateAddonInventory(name, nil, items)
							SharedInventories[name] = addonInventory

						end
						printf("finishing query ["..tostring(i).."]")
						finished = finished + 1
					end)
				end
			else
				printf("Result is nil?")
			end
			while finished < started do
				printf("Started: "..tostring(started))
				printf("Finished: "..tostring(finished))
				Citizen.Wait(50)
			end
			print("[^2smx_addoninventory^7] Addon inventory loaded")
			TriggerEvent('smx_controll:endFinish', GetCurrentResourceName())
		end)
	end)
end)

AddEventHandler('onMySQLReady', function ()
	Wait(200)
	TriggerEvent('smx_addoninventory:getDb')
end)

function GetInventory(name, owner)
	for i=1, #Inventories[name], 1 do
		if tostring(Inventories[name][i]) ~= 'nil' then
			if tostring(Inventories[name][i].owner) == tostring(owner) then
				return Inventories[name][i]
			end
		end
	end
	return nil
end

function GetSharedInventory(name)
	return SharedInventories[name]
end

AddEventHandler('smx_addoninventory:getInventory', function(name, owner, cb)
	local xPlayer = SMX.GetPlayerFromIdentifier(owner)
	while xPlayer == nil do
		xPlayer = SMX.GetPlayerFromIdentifier(owner)
		Citizen.Wait(10)
	end
	local inv = GetInventory(name, owner)
	local wasNil = false
	local addingDone = false
	local result1Count = 0
	local result1CountDone = 0
	local result2Count = 0
	local result2CountDone = 0
	local started = 0
	local ended = 0
	while inv == nil do
		while started < ended do
			if printing then
				printf("Waiting for MySQL to finish...")
			end
			Citizen.Wait(0)
		end
		started = started + 1
		wasNil = true
		if printing then
			TriggerClientEvent("smx_notify:clientNotify", xPlayer.source, {text="Wystąpił błąd podczas ładowania zawartości. Odczekaj chwilę...", type="alert"})
		end
		printf("-----------------------------------------------------------------")
		printf("player "..xPlayer.source.." loaded")
		local owner2 = xPlayer.identifier
		printf("hex: "..owner2)
		for k,v in next, Inventories do
			if tostring(Inventories[k]) ~= nil then
				for i=1, #Inventories[k] do
					if tostring(Inventories[k][i]) ~= 'nil' then
						if tostring(Inventories[k][i].owner) == tostring(owner2) then -- tutaj nile
							printf('deleting inventory '..k..' for '..owner2)
							Inventories[k][i] = nil
						end
					end
				end
			end
		end
		local addonInventories = {}
		MySQL.Async.fetchAll('SELECT name, label, shared FROM addon_inventory', {
		}, function(result)
			if result[1] ~= nil then
				result1Count = #result
				for i=1, #result, 1 do	
					if tostring(result[i].shared) == '0' then
						local name   = result[i].name
						local label  = result[i].label
						local shared = result[i].shared
						local owner = xPlayer.identifier
		
						printf("getting new inventory = "..name)
						local items       = {}
						local hasItems = false
						
						MySQL.Async.fetchAll('SELECT * FROM addon_inventory_items WHERE inventory_name = @inventory_name AND `owner` = @owner', {
							['@inventory_name'] = name,
							['@owner'] = xPlayer.identifier
						}, function(result2)
							printf("#result2: "..tostring(#result2))
							if result2[1] ~= nil then
								result2Count = #result2
								for j=1, #result2, 1 do
									hasItems = true
									local itemName  = result2[j].name
									local itemCount = result2[j].count
					
									if items[owner] == nil then
										items[owner] = {}
									end
									--[[if printing then
										SMX.PrintTable(items[owner])
									end
									SMX.PrintTable(items[owner])]]
									table.insert(items[owner], {
										name  = itemName,
										count = itemCount,
										label = Items[itemName]
									})
									result2CountDone = result2CountDone + 1
								end
							end
							if not hasItems then
								printf('hasn\'t got items in '..name)
								items[owner] = {}
							end
				
							printf("adding: "..name)
							local addonInventory = CreateAddonInventory(name, owner, items[owner])
							table.insert(Inventories[name], addonInventory)
							table.insert(addonInventories, addonInventory)
							addingDone = true
						end)
			
			
					end
					result1CountDone = result1CountDone + 1
				end
			end
			while result1CountDone < result1Count do
				if printing then
					printf("Waiting for result[1]")
					printf("req = "..result1Count.."; done = "..result1CountDone)
				end
				Citizen.Wait(10)
			end
			while result2CountDone < result2Count do
				if printing then
					printf("Waiting for result[2]")
					printf("req = "..result2Count.."; done = "..result2CountDone)
				end
				Citizen.Wait(10)
			end
			while not addingDone do
				if printing then
					printf("Waiting for adding inventories to finish...")
				end
				Citizen.Wait(10)
			end
			if printing then
				printf("inventory for player "..xPlayer.source.." loaded")
			end
			--[[if printing then
				SMX.PrintTable(addonInventories)
			end]]
			xPlayer.set('addonInventories', addonInventories)
			inv = GetInventory(name, owner)
			ended = ended + 1
			if printing then
				printf("Finished MySQL!")
			end
		end)
		Citizen.Wait(2500)
	end
	if wasNil and printing then
		TriggerClientEvent("smx_notify:clientNotify", xPlayer.source, {text="Zawartość została załadowana! Otwórz menu ponownie", type="true"})
	end
	cb(inv)
end)

AddEventHandler('smx_addoninventory:getSharedInventory', function(name, cb)
	cb(GetSharedInventory(name))
end)

AddEventHandler('smx:playerLoaded', function(source)
	local _source = source
	local xPlayer = SMX.GetPlayerFromId(_source)
	while xPlayer == nil do
		xPlayer = SMX.GetPlayerFromId(_source)
		Citizen.Wait(10)
	end
	printf("player ".._source.." loaded")
	local owner2 = xPlayer.identifier
	PlayersIds[_source] = xPlayer.identifier
	for k,v in next, Inventories do
		if tostring(Inventories[k]) ~= nil then
			for i=1, #Inventories[k] do
				if tostring(Inventories[k][i]) ~= 'nil' then
					if tostring(Inventories[k][i].owner) == tostring(owner2) then -- tutaj nile
						printf('deleting inventory '..k..' for '..owner2)
						Inventories[k][i] = nil
					end
				end
			end
		end
	end
	local addonInventories = {}
	MySQL.Async.fetchAll('SELECT name, label, shared FROM addon_inventory', {
	}, function(result)
		if result[1] ~= nil then
			for i=1, #result, 1 do
		
				if tostring(result[i].shared) == '0' then
					local name   = result[i].name
					local label  = result[i].label
					local shared = result[i].shared
					local owner = xPlayer.identifier
			
					local result2 = MySQL.Sync.fetchAll('SELECT * FROM addon_inventory_items WHERE inventory_name = @inventory_name AND `owner` = @owner', {
						['@inventory_name'] = name,
						['@owner'] = xPlayer.identifier
					})
					printf("#result2: "..tostring(#result2))
					printf("getting new inventory = "..name)
					local items       = {}
					local hasItems = false
					for j=1, #result2, 1 do
						hasItems = true
						local itemName  = result2[j].name
						local itemCount = result2[j].count
		
						if items[owner] == nil then
							items[owner] = {}
						end
						--[[if printing then
							SMX.PrintTable(items[owner])
						end]]
						table.insert(items[owner], {
							name  = itemName,
							count = itemCount,
							label = Items[itemName]
						})
					end
		
					if not hasItems then
						printf('hasn\'t got items in '..name)
						items[owner] = {}
					end
		
					printf("adding: "..name)
					local addonInventory = CreateAddonInventory(name, owner, items[owner])
					table.insert(Inventories[name], addonInventory)
					table.insert(addonInventories, addonInventory)
		
				end
			end
		end
		printf("inventory for player ".._source.." loaded")
		--[[if printing then
			SMX.PrintTable(addonInventories)
		end]]
		xPlayer.set('addonInventories', addonInventories)
	end)
end)

RegisterNetEvent('smx_multi-character:unloadPlayerAfterChanging')
AddEventHandler('smx_multi-character:unloadPlayerAfterChanging', function(id, hex)
	local _source = id
	local owner = hex
	for k,v in next, Inventories do
		if tostring(Inventories[k]) ~= nil then
			for i=1, #Inventories[k] do
				if tostring(Inventories[k][i]) ~= 'nil' then
					if tostring(Inventories[k][i].owner) == tostring(owner) then -- tutaj nile
						printf('deleting inventory '..k..' for '..owner)
						Inventories[k][i] = nil
					end
				end
			end
		end
	end
end)

AddEventHandler('playerDropped', function (reason)
	local _source = source
	local owner = PlayersIds[_source]
	if owner ~= nil then
		for k,v in next, Inventories do
			if tostring(Inventories[k]) ~= nil then
				for i=1, #Inventories[k] do
					if tostring(Inventories[k][i]) ~= 'nil' then
						if tostring(Inventories[k][i].owner) == tostring(owner) then -- tutaj nile
							printf('deleting inventory '..k..' for '..owner)
							Inventories[k][i] = nil
						end
					end
				end
			end
		end
	end
end)
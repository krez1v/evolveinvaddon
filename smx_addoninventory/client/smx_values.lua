local gotSMXvalues = false
Citizen.CreateThread(function()
    while not gotSMXvalues do
        TriggerEvent('smx_engine:getFunctions', function(values)
			if values ~= nil then
				load(values)()
				gotSMXvalues = true
			end
        end)
        Citizen.Wait(50)
    end
end)
if Config.oldESX then
	ESX = nil
	TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
else
	ESX = exports["es_extended"]:getSharedObject()
end

local IsInShopMenu = false

local function DrawText3Ds(x, y, z, text)
	SetTextScale(0.30, 0.30)
    SetTextFont(0)
	SetTextOutline()
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function StartShopRestriction()
	CreateThread(function()
		while IsInShopMenu do
			Wait(0)

			DisableControlAction(0, 75,  true) -- Disable exit vehicle
			DisableControlAction(27, 75, true) -- Disable exit vehicle
		end
	end)
end

local function DeleteDisplayVehicleInsideShop()
	local attempt = 0

	if currentDisplayVehicle and DoesEntityExist(currentDisplayVehicle) then
		while DoesEntityExist(currentDisplayVehicle) and not NetworkHasControlOfEntity(currentDisplayVehicle) and attempt < 100 do
			Wait(100)
			NetworkRequestControlOfEntity(currentDisplayVehicle)
			attempt = attempt + 1
		end

		if DoesEntityExist(currentDisplayVehicle) and NetworkHasControlOfEntity(currentDisplayVehicle) then
			ESX.Game.DeleteVehicle(currentDisplayVehicle)
		end
	end
end

local function WaitForVehicleToLoad(modelHash)
	modelHash = (type(modelHash) == 'number' and modelHash or joaat(modelHash))

	if not HasModelLoaded(modelHash) then
		RequestModel(modelHash)

		BeginTextCommandBusyspinnerOn('STRING')
		AddTextComponentSubstringPlayerName("車子正在加載當中, 請耐心等待!")
		EndTextCommandBusyspinnerOn(4)

		while not HasModelLoaded(modelHash) do
			Wait(0)
			DisableAllControlActions(0)
		end

		BusyspinnerOff()
	end
end


local function OpenMenu()
    if #Config.Vehicles == 0 then
		print('[cy-testvehicle ] [^3ERROR^7] No vehicles found')
		return
	end

	IsInShopMenu = true

	StartShopRestriction()
	ESX.UI.Menu.CloseAll()

	local playerPed = PlayerPedId()

	FreezeEntityPosition(playerPed, true)
	SetEntityVisible(playerPed, false)
    SetEntityCoords(playerPed, Config.Location.x,Config.Location.y,Config.Location.z)

	local vehiclesByCategory = {}
	local elements           = {}
	local firstVehicleData   = nil

	for i=1, #Config.Categories, 1 do
		vehiclesByCategory[Config.Categories[i].name] = {}
	end

	for i=1, #Config.Vehicles, 1 do
		if IsModelInCdimage(joaat(Config.Vehicles[i].model)) then
			table.insert(vehiclesByCategory[Config.Vehicles[i].category], Config.Vehicles[i])
		else
			print(('[cy-testvehicle] [^3ERROR^7] Vehicle "%s" does not exist'):format(Config.Vehicles[i].model))
		end
	end

	for k,v in pairs(vehiclesByCategory) do
		table.sort(v, function(a, b)
			return a.name < b.name
		end)
	end

	for i=1, #Config.Categories, 1 do
		local category         = Config.Categories[i]
		local categoryVehicles = vehiclesByCategory[category.name]
		local options          = {}

		for k,v in pairs(categoryVehicles) do
			local vehicle = categoryVehicles[k]

			if i == 1 and k == 1 then
				firstVehicleData = vehicle
			end

            options[#options + 1] = {
                v.name
            }
		end

        elements[#elements + 1] = {
            name    = category.name,
			label   = category.label,
			value   = 0,
			type    = 'slider',
			max     = #Config.Categories[i],
			options = options
        }
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'test_vehicle', {
		title    = "車輛測試選單",
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		local vehicleData = vehiclesByCategory[data.current.name][data.current.value + 1]

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'test_vehicle_confirm', {
			title = "確定支付 $" ..Config.Amount.. " 來測試車子?",
			align = 'top-left',
			elements = {
				{label = "否",  value = 'no'},
				{label = "是", value = 'yes'},
		}}, function(data2, menu2)				
			if data2.current.value == 'yes' then
                ESX.TriggerServerCallback("cy-testVehicle:removeMoney", function(removed) 
                    if removed then
						menu2.close()
                        menu.close()

                        local ped = PlayerPedId()
                        local target = vector3(Config.TestVehicleArea.x, Config.TestVehicleArea.y, Config.TestVehicleArea.z)

                        RequestCollisionAtCoord(target)
        
                        while not HasCollisionLoadedAroundEntity(ped) do
                            RequestCollisionAtCoord(target)
                            Wait(1)
                        end
        
                        IsInShopMenu = false
                        DeleteDisplayVehicleInsideShop()
        
                        SetEntityCoords(ped, target)
                                
                        ESX.Game.SpawnLocalVehicle(vehicleData.model, target, Config.TestVehicleArea.w, function(vehicle)
                            TaskWarpPedIntoVehicle(ped, vehicle, -1)
                            local newPlate = 'TEST' .. string.upper(ESX.GetRandomString(4))
                            local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
                            vehicleProps.plate = newPlate
                            SetVehicleNumberPlateText(vehicle, newPlate)
                            ESX.ShowNotification("可以進行車輛測試" ..Config.Time.. "秒")
                            FreezeEntityPosition(vehicle, false)
                            Wait(Config.Time * 1000)
                            ESX.Game.DeleteVehicle(vehicle)
                            ESX.Game.Teleport(ped, Config.Location)
                            ESX.ShowNotification("車輛測試完成")
                        end)
        
                        FreezeEntityPosition(playerPed, false)
                        SetEntityVisible(playerPed, true)
                    end
                end)
			else
				menu2.close()
			end
		end, function(data2, menu2)
			menu2.close()
		end)
	end, function(data, menu)
		menu.close()
		DeleteDisplayVehicleInsideShop()
		local playerPed = PlayerPedId()

		FreezeEntityPosition(playerPed, false)
		SetEntityVisible(playerPed, true)
		SetEntityCoords(playerPed, Config.Location.x,Config.Location.y,Config.Location.z)

		IsInShopMenu = false
	end, function(data, menu)
		local vehicleData = vehiclesByCategory[data.current.name][data.current.value + 1]
		local playerPed   = PlayerPedId()

		DeleteDisplayVehicleInsideShop()
		WaitForVehicleToLoad(vehicleData.model)

		ESX.Game.SpawnLocalVehicle(vehicleData.model, vector3(Config.PreviewVehicleArea.x, Config.PreviewVehicleArea.y, Config.PreviewVehicleArea.z), Config.PreviewVehicleArea.w, function(vehicle)
			currentDisplayVehicle = vehicle
			TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
			FreezeEntityPosition(vehicle, true)
			SetModelAsNoLongerNeeded(vehicleData.model)
		end)
	end)

	DeleteDisplayVehicleInsideShop()
	WaitForVehicleToLoad(firstVehicleData.model)

	ESX.Game.SpawnLocalVehicle(firstVehicleData.model, vector3(Config.PreviewVehicleArea.x, Config.PreviewVehicleArea.y, Config.PreviewVehicleArea.z), Config.PreviewVehicleArea.w, function(vehicle)
		currentDisplayVehicle = vehicle
		TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
		FreezeEntityPosition(vehicle, true)
		SetModelAsNoLongerNeeded(firstVehicleData.model)
	end)
end

CreateThread(function()
    while true do
        Wait(0)

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local distance = #(coords - Config.Location)
        local sleep = true

        if distance <= 20 then
            sleep = false
            DrawMarker(2, Config.Location.x, Config.Location.y, Config.Location.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 255, 255, 255, 255, false, false, false, true, false, false, false)
            
            if distance <= 5 then
                DrawText3Ds(Config.Location.x, Config.Location.y, Config.Location.z + 0.2, "【E】- 測試車子")

                if IsControlJustPressed(0, 38) then
                    OpenMenu()
                end
            end
        end

        if sleep then
            Wait(500)
        end
    end
end)
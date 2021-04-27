local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

-------------------------------------------------------------------------------------------------
--[ CONEXÃO ]------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
src = {}
Tunnel.bindInterface("vrp_factionsgarages", src)
vSERVER = Tunnel.getInterface("vrp_factionsgarages")

local vehicle = {}

--[ COOLDOWN ]---------------------------------------------------------------------------------------------------------------------------
local cooldown = 0

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1000)
		if cooldown > 0 then
			cooldown = cooldown - 1
		end
	end
end)

--[ MARKERS GARAGES ]-------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	config.groups = vRP.groups

	while true do
		local idle = 1000

		for k,v in pairs(config.groupsGarages) do
			local ped = PlayerPedId()

			if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), v.x, v.y, v.z, true ) < 5 then
				DrawMarker(27, v.x, v.y, v.z-1, 0, 0, 0, 0, 0, 0, 0.7, 0.7, 0.5, 136, 96, 240, 180, 0, 0, 0, 1)
				DrawMarker(36, v.x, v.y, v.z, 0, 0, 0, 0, 0, 0, 0.7, 0.7, 0.5, 136, 96, 240, 180, 0, 0, 0, 1)
				idle = 5
				
				if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), v.x, v.y, v.z, true ) < 1.2 then
					DrawText3D(v.x, v.y, v.z, "Pressione [~y~E~w~] abrir a ~y~Garagem~w~.")

					if IsControlJustPressed(0,38) then
						if vSERVER.checkPermission(k) then
							src.openFacGarage(k)
						else
							TriggerEvent("Notify","negado", "Você não tem permissão para acessar a garagem dos "..k, 500)
						end
					end
				end
				
			end
		end
		Citizen.Wait(idle)
	end
end)

--[ TOGGLE MENU GARAGES ]---------------------------------------------------------------------------------------------------------------------
local menuEnabled = false
function ToggleActionMenu(facName)
	menuEnabled = not menuEnabled

	if menuEnabled then
		StartScreenEffect("MenuMGSelectionIn", 0, true)
		SetNuiFocus(true ,true)
		SendNUIMessage({ action = "showMenu", facName = facName })
	else
		SetNuiFocus(false, false)
		SendNUIMessage({ action = "hideMenu" , facName = "" })
		StopScreenEffect("MenuMGSelectionIn")
	end
end

--[ OPEN GARAGE ]-----------------------------------------------------------------------------------------------------------------------------
function src.openFacGarage(facName)
	ToggleActionMenu(facName)
end

--[ RETURN VEHICLE ]---------------------------------------------------------------------------------------------------------------------------
function src.returnVehicle(nome)
	return vehicle[nome]
end

--[ NUI FUCTIONS ]----------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("ButtonClick",function(data, cb)
	if data == "exit" then
		ToggleActionMenu()
	end
end)

RegisterNUICallback("getFacVehicles",function(data, cb)
	local vehicles = vSERVER.getFacVehicles(data.facName)

	if vehicles then
		return cb({ vehicles = vehicles })
	else
		return cb({ vehicles = {} })
	end
end)

RegisterNUICallback("buyCar", function(data, cb)
	local ped = PlayerPedId()

	if vSERVER.buyCar(data.nome, data.preco, data.facName, ped) then
		TriggerEvent("Notify","sucesso", "Você comprou o veículo com sucesso.", 3000)
		SetNuiFocus(false,false)
		SendNUIMessage({ action = "hideMenu" })
		StopScreenEffect("MenuMGSelectionIn")
		return true
	else
		TriggerEvent("Notify","negado", "Não foi possível comprar o carro.", 3000)
		return false
	end
end)

RegisterNUICallback('spawnVehicle',function(data)
    if cooldown < 1 then
        cooldown = 3
		vSERVER.spawnVehicle(data.nome)
		SetNuiFocus(false, false)
		SendNUIMessage({ action = "hideMenu" })
		StopScreenEffect("MenuMGSelectionIn")
	end
end)

--[ SPAWN VEHICLE ]-----------------------------------------------------------------------------------------------------------------------
function src.spawnVehicle(vehname)
	if vehicle[vehname] == nil then
		local checkslot = 1
		local mhash = GetHashKey(vehname)

		while not HasModelLoaded(mhash) do
			RequestModel(mhash)
			Citizen.Wait(1)
		end

		if HasModelLoaded(mhash) then
			if checkslot ~= -1 then
				local nveh = CreateVehicle(mhash, 1274.26, -215.04, 99.39, 166.27, true, false)

				SetVehicleIsStolen(nveh, false)
				SetVehicleNeedsToBeHotwired(nveh, false)
				SetVehicleOnGroundProperly(nveh)
				SetVehicleNumberPlateText(nveh, "FAC")
				SetEntityAsMissionEntity(nveh, true, true)
				SetVehRadioStation(nveh, "OFF")

				SetVehicleEngineHealth(nveh, 100.0)
				SetVehicleBodyHealth(nveh, 100.0)
				SetVehicleFuelLevel(nveh, 100.0)

				vehicle[vehname] = true

				SetModelAsNoLongerNeeded(mhash)

				return true,VehToNet(nveh)
			end
		end
	end
	return false
end

-------------------------------------------------------------------------------------------------
--[ FUNÇÃO ]-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
function DrawText3D(x,y,z, text)
    local onScreen,_x,_y = World3dToScreen2d(x, y, z)
    local px,py,pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.28, 0.28)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.005+ factor, 0.03, 41, 11, 41, 68)
end
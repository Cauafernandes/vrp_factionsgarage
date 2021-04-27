local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
local Tools = module("vrp","lib/Tools")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

--[ CONEXÃO ]----------------------------------------------------------------------------------------------------------------------------

src = {}
Tunnel.bindInterface("vrp_factionsgarages", src)
vCLIENT = Tunnel.getInterface("vrp_factionsgarages")

local installDB = "USE `zirix`; CREATE TABLE IF NOT EXISTS `groups_garages` (`id` int(11) NOT NULL AUTO_INCREMENT,`vehicleName` varchar(50) NOT NULL,`groupName` varchar(50) NOT NULL,`count` int(10) NOT NULL,`arresting` int(11),`time` timestamp NOT NULL DEFAULT current_timestamp(),PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;"

--[ PREPARE ]----------------------------------------------------------------------------------------------------------------------------
vRP._prepare("factionsgarages/init", installDB)
vRP._prepare("factionsgarages/updateCar", "UPDATE groups_garages SET count = @qtd WHERE groupName = @groupName AND vehicleName = @vehicleName")
vRP._prepare("factionsgarages/addCar","INSERT INTO groups_garages(vehicleName,groupName,count) VALUES(@vehicleName,@groupName,@count)")
vRP._prepare("factionsgarages/getCarCount", "SELECT count from groups_garages WHERE groupName = @groupName AND vehicleName = @vehicleName")

local groups = vRP.groups

--[ INSTALL SYSTEM ]---------------------------------------------------------------------------------------------------------------------
function src.InstallSystem(source)
    vRP.query("factionsgarages/init")
	TriggerClientEvent("Notify", source, "sucesso","Sistema de garagem de facções instalado com sucesso.")
end

RegisterCommand('install-facgarages',function(source,args,rawCommand)
	local source = source
	local user_id = vRP.getUserId(source)

	if vRP.hasPermission(user_id, "manager.permissao") then
		src.InstallSystem(source)
	end
end)

--[ CHECK PERMISSION ]-------------------------------------------------------------------------------------------------------------------
function src.checkPermission(facName)
	local user_id = vRP.getUserId(source)

	if user_id then
		if vRP.hasPermission(user_id, facName..".permissao") then
			return true
		end
	end
	return false
end

--[ GET FACTION VEHICLES ]--------------------------------------------------------------------------------------------------------------
function src.getFacVehicles(facName)
	local getCars = config.groupsVehicles[facName]
	local myvehicles = {}

	for k,v in pairs(getCars) do
		local carroNome = vRP.vehicleName(v.nome)
		local queryGetCarCount = vRP.query("factionsgarages/getCarCount", { vehicleName = v.nome, groupName = facName })
		
		if #queryGetCarCount > 0 then
			table.insert(myvehicles, { nome = carroNome, foto = v.nome, preco = v.price*(queryGetCarCount[1].count+1), qtd = queryGetCarCount[1].count, limit = v.limit })
		else
			table.insert(myvehicles, { nome = carroNome, foto = v.nome, preco = v.price, qtd = v.qtd, limit = v.limit })
		end
	end

	return myvehicles
end

--[ CAR IN GROUP ALLOW LIST ]-----------------------------------------------------------------------------------------------------------
function src.HasCarInGroup(group, car, source)
	local getCars = config.groupsVehicles[group]

	for k,v in pairs(getCars) do
		if v.nome == car then
			return true
		else
			return false
		end
	end

	return false
end

--[ GET CAR LIMIT ]--------------------------------------------------------------------------------------------------------------------
function src.getCarLimit(group, car)
	local getCars = config.groupsVehicles[group]

	for k,v in pairs(getCars) do
		if v.nome == car then
			return v.limit
		end
	end

	return false
end

--[ BUY MORE ONE CAR ]----------------------------------------------------------------------------------------------------------------
function src.buyCar(carName, carPrice, facName, ped)
	local user_id = vRP.getUserId(source)
	if carPrice ~= nil and facName ~= "" and carName ~= "" then
		local group = facName
		local car = carName
		local quantity = 1

		TriggerClientEvent("Notify", source, "negado", "Carro: "..car, 3000)
		TriggerClientEvent("Notify", source, "negado", "Grupo: "..group, 3000)
		TriggerClientEvent("Notify", source, "negado", "Preço Base: "..carPrice, 3000)

		local queryGetCarCount = vRP.query("factionsgarages/getCarCount", { vehicleName = car, groupName = group })
		local newQuantity = 0

		if #queryGetCarCount > 0 then
			newQuantity = queryGetCarCount[1].count + quantity
		else
			newQuantity = quantity
		end

		TriggerClientEvent("Notify", source, "negado", "Qtd: "..newQuantity, 3000)

		if vRP.tryPayment(user_id, parseInt(carPrice*newQuantity)) and car ~= "" then
			if #queryGetCarCount > 0 then
				if newQuantity <= src.getCarLimit(group, car) then
					vRP.execute("factionsgarages/updateCar", { qtd = newQuantity, vehicleName = car, groupName = group })
					return true
				else
					TriggerClientEvent("Notify", source, "negado", "Veículo atingiu a quantidade máxima.", 3000)
					return false
				end
			else
				vRP.execute("factionsgarages/addCar", { vehicleName = car, groupName = group, count = quantity })
				return true
			end
		else
			return false
		end
		return true
	else
		TriggerClientEvent("Notify", source, "aviso", "Carro não encontrado.", 3000)
	end
end

--[ SPAWN VEHICLE ]------------------------------------------------------------------------------------------------------------------
local vehlist = {}
function src.spawnVehicle(nome)
	if nome then
		local source = source
		local user_id = vRP.getUserId(source)

		if user_id then
			local identity = vRP.getUserIdentity(user_id)

			if not vCLIENT.returnVehicle(source,nome) then
				local isSpawned,vehid = vCLIENT.spawnVehicle(source,nome)
				-- vehlist[vehid] = { parseInt(user_id), nome }
				table.insert(vehlist, { [vehid] = { user = user_id, nome = nome } })
				TriggerEvent("setPlateEveryone", identity.registration)
				TriggerClientEvent("Notify", source, "sucesso", "O veículo foi retirado da garagem.", 3000)
			else
				TriggerClientEvent("Notify", source, "aviso", "Já possui um veículo deste modelo fora da garagem.", 3000)
			end
		end
	end
end

--[ COMMANDS ]-------------------------------------------------------------------------------------------------------------------------
RegisterCommand('addcarfac',function(source, args, rawCommand)
    local user_id = vRP.getUserId(source)

    if vRP.hasPermission(user_id,"administrador.permissao") or vRP.hasPermission(user_id,"manager.permissao") then
		local group = args[1]
		local car = args[2]
		local quantity = parseInt(args[3])

		if src.HasCarInGroup(group, car, source) then
			local queryGetCarCount = vRP.query("factionsgarages/getCarCount", { vehicleName = car, groupName = group })
			
			if #queryGetCarCount >= 0 then
				local newQuantity = queryGetCarCount[1].count + quantity
				vRP.execute("factionsgarages/updateCar", { qtd = newQuantity, vehicleName = car, groupName = group })
			else
				vRP.execute("factionsgarages/addCar", { vehicleName = car, groupName = group, count = quantity })
			end

			TriggerClientEvent("Notify", source, "sucesso", "Você adicionou "..car.." ao grupo "..group..".", 3000)
		else
			TriggerClientEvent("Notify", source, "negado", "Este veículo não existe na garagem do grupo.", 3000)
		end
    end
end)

RegisterCommand('rmcarfac',function(source, args, rawCommand)
    local user_id = vRP.getUserId(source)

    if vRP.hasPermission(user_id,"administrador.permissao") or vRP.hasPermission(user_id,"manager.permissao") then
		local group = args[1]
		local car = args[2]
		local quantity = parseInt(args[3])

		if src.HasCarInGroup(group, car, source) then
			local queryGetCarCount = vRP.query("factionsgarages/getCarCount", { vehicleName = car, groupName = group })
			
			if queryGetCarCount[1].count > 0 then
				local newQuantity = queryGetCarCount[1].count - quantity
				vRP.execute("factionsgarages/updateCar", { qtd = newQuantity, vehicleName = car, groupName = group })
				TriggerClientEvent("Notify", source, "sucesso", "Você removeu "..quantity.." "..car.." do grupo "..group..".", 3000)
			else
				TriggerClientEvent("Notify", source, "negado", "O grupo não possui o veículo.", 3000)
			end
		end
    end
end)
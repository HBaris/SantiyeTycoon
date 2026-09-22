local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local DataService = {}
local DATA_STORE_NAME = "ConstructionTycoonData_v2"

local dataStore
local isDataStoreAvailable = false

-- Hızlı ve güvenli DataStore ilklendirme (Studio'da bekleme yapmaz)
if RunService:IsStudio() then
	isDataStoreAvailable = false
	print("[DataService] Studio yerel modu: Anında oturum içi bellek aktif edildi.")
else
	local success, err = pcall(function()
		dataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
		isDataStoreAvailable = true
	end)
	if success then
		print("[DataService] Şantiye DataStore bulut bağlantısı sağlandı.")
	else
		warn("[DataService] DataStore kapalı: " .. tostring(err))
	end
end

-- Aktif oyuncu profilleri (Tüm ortamlar ve komut satırı için global tabloda saklanır)
local profiles = _G.ContractorProfiles or {}
_G.ContractorProfiles = profiles

local function createDefaultProfile()
	return {
		Cash = GameConfig.STARTING_CASH,
		Crystals = GameConfig.STARTING_CRYSTALS or 25,
		Engineers = GameConfig.STARTING_ENGINEERS or 0.0,
		LastEngineerTime = os.time(),
		MaterialDelivery = GameConfig.BASE_MATERIAL_FLOW,
		LogisticsLevel = 0,
		ActivePlotIndex = 1,
		Upgrades = {
			Cash = {},
			Crystals = {},
			Engineers = {},
		},
		Garage = {
			Owned = { Scooter = true },
			Active = "Scooter",
		},
		VehicleUpgrades = {
			Scooter = { Speed = 0, Torque = 0, Cargo = 0 },
			Motorcycle = { Speed = 0, Torque = 0, Cargo = 0 },
			Car = { Speed = 0, Torque = 0, Cargo = 0 },
		},
		CargoCarried = 0,
		Customizer = {
			Scales = {},
			Slots = {},
		},
		Plots = {
			[1] = {
				BuildingLevel = 1,
				ProjectType = "SingleBuilding",
				DeliveredMaterials = 0,
				IsCompleted = false,
			},
		},
		LastLogoutTime = os.time(),
	}
end

function DataService.LoadPlayer(player: Player)
	local userId = player.UserId
	local profile

	if isDataStoreAvailable then
		local loadSuccess, storedData = pcall(function()
			return dataStore:GetAsync("Contractor_" .. userId)
		end)

		if loadSuccess and storedData and type(storedData) == "table" then
			profile = storedData
			local default = createDefaultProfile()
			for k, v in pairs(default) do
				if profile[k] == nil then
					profile[k] = v
				end
			end
			if not profile.Plots or type(profile.Plots) ~= "table" then
				profile.Plots = default.Plots
			end
			print(string.format("[DataService] Müteahhit %s şirket verileri yüklendi. Kasa: %d İP", player.Name, profile.Cash))
		else
			profile = createDefaultProfile()
			print(string.format("[DataService] %s için yeni inşaat şirketi açıldı.", player.Name))
		end
	else
		profile = createDefaultProfile()
	end

	profiles[player] = profile
	if player and player.UserId then
		profiles[player.UserId] = profile
	end
	return profile
end

function DataService.GetProfile(player: Player)
	if not player then return nil end
	local prof = profiles[player] or (player.UserId and profiles[player.UserId]) or (_G.ContractorProfiles and _G.ContractorProfiles[player.UserId])
	if not prof then
		prof = DataService.LoadPlayer(player)
	end
	return prof
end

function DataService.AddCash(player: Player, amount: number)
	local profile = profiles[player]
	if profile and amount > 0 then
		profile.Cash += amount
		return profile.Cash
	end
	return 0
end

function DataService.SpendCash(player: Player, amount: number): boolean
	local profile = profiles[player]
	if profile and profile.Cash >= amount then
		profile.Cash -= amount
		return true
	end
	return false
end

function DataService.AddCrystals(player: Player, amount: number)
	local profile = profiles[player]
	if profile and amount > 0 then
		profile.Crystals = (profile.Crystals or 0) + amount
		return profile.Crystals
	end
	return 0
end

function DataService.SpendCrystals(player: Player, amount: number): boolean
	local profile = profiles[player]
	if profile and (profile.Crystals or 0) >= amount then
		profile.Crystals -= amount
		return true
	end
	return false
end

function DataService.AddEngineers(player: Player, amount: number)
	local profile = profiles[player]
	if profile and amount > 0 then
		profile.Engineers = (profile.Engineers or 0.0) + amount
		return profile.Engineers
	end
	return 0
end

function DataService.SpendEngineers(player: Player, amount: number): boolean
	local profile = profiles[player]
	if profile and (profile.Engineers or 0.0) >= amount then
		profile.Engineers -= amount
		return true
	end
	return false
end

function DataService.GetUpgradeLevel(player: Player, tabName: string, categoryId: string): number
	local profile = profiles[player]
	if profile and profile.Upgrades and profile.Upgrades[tabName] then
		return profile.Upgrades[tabName][categoryId] or 0
	end
	return 0
end

function DataService.SetUpgradeLevel(player: Player, tabName: string, categoryId: string, level: number)
	local profile = profiles[player]
	if profile then
		if not profile.Upgrades then profile.Upgrades = {} end
		if not profile.Upgrades[tabName] then profile.Upgrades[tabName] = {} end
		profile.Upgrades[tabName][categoryId] = level
	end
end

function DataService.OwnsVehicle(player: Player, vehicleId: string): boolean
	local profile = profiles[player]
	if vehicleId == "Scooter" then return true end
	if profile and profile.Garage and profile.Garage.Owned then
		return profile.Garage.Owned[vehicleId] == true
	end
	return false
end

function DataService.AddVehicle(player: Player, vehicleId: string)
	local profile = profiles[player]
	if profile then
		if not profile.Garage then profile.Garage = { Owned = { Scooter = true }, Active = "Scooter" } end
		if not profile.Garage.Owned then profile.Garage.Owned = { Scooter = true } end
		profile.Garage.Owned[vehicleId] = true
		profile.Garage.Active = vehicleId
	end
end

function DataService.GetVehicleUpgrade(player: Player, vehicleId: string, upgradeKey: string): number
	local profile = profiles[player]
	if profile and profile.VehicleUpgrades and profile.VehicleUpgrades[vehicleId] then
		return profile.VehicleUpgrades[vehicleId][upgradeKey] or 0
	end
	return 0
end

function DataService.SetVehicleUpgrade(player: Player, vehicleId: string, upgradeKey: string, level: number)
	local profile = profiles[player]
	if profile then
		if not profile.VehicleUpgrades then profile.VehicleUpgrades = {} end
		if not profile.VehicleUpgrades[vehicleId] then profile.VehicleUpgrades[vehicleId] = {} end
		profile.VehicleUpgrades[vehicleId][upgradeKey] = level
	end
end

function DataService.GetAllVehicleUpgrades(player: Player, vehicleId: string): { [string]: number }
	local profile = profiles[player]
	if profile and profile.VehicleUpgrades and profile.VehicleUpgrades[vehicleId] then
		return profile.VehicleUpgrades[vehicleId]
	end
	return { Speed = 0, Torque = 0, Cargo = 0 }
end

function DataService.SavePlayer(player: Player)
	local profile = profiles[player]
	if not profile then return end

	profile.LastLogoutTime = os.time()

	if isDataStoreAvailable then
		local saveSuccess, saveErr = pcall(function()
			dataStore:SetAsync("Contractor_" .. player.UserId, profile)
		end)

		if not saveSuccess then
			warn(string.format("[DataService] %s verileri kaydedilemedi: %s", player.Name, tostring(saveErr)))
		else
			print(string.format("[DataService] %s inşaat portföyü kaydedildi.", player.Name))
		end
	end
end

function DataService.UnloadPlayer(player: Player)
	DataService.SavePlayer(player)
	profiles[player] = nil
end

game:BindToClose(function()
	print("[DataService] Sunucu kapanıyor, tüm müteahhit verileri kaydediliyor...")
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.SavePlayer(player)
	end
end)

function DataService.GetCustomizer(player: Player)
	local profile = profiles[player]
	if profile then
		if not profile.Customizer then
			profile.Customizer = { Scales = {}, Slots = {}, Positions = {} }
		end
		if not profile.Customizer.Positions then
			profile.Customizer.Positions = {}
		end
		return profile.Customizer
	end
	return { Scales = {}, Slots = {}, Positions = {} }
end

function DataService.SetModelScale(player: Player, modelKey: string, scale: number)
	local customizer = DataService.GetCustomizer(player)
	customizer.Scales[modelKey] = scale
end

function DataService.GetModelScale(player: Player, modelKey: string): number
	local customizer = DataService.GetCustomizer(player)
	return customizer.Scales[modelKey] or 1.0
end

function DataService.SetPromenadeSlot(player: Player, slotIndex: number, shopId: string)
	local customizer = DataService.GetCustomizer(player)
	customizer.Slots[tostring(slotIndex)] = shopId
end

function DataService.GetPromenadeSlot(player: Player, slotIndex: number): string?
	local customizer = DataService.GetCustomizer(player)
	return customizer.Slots[tostring(slotIndex)]
end

function DataService.SetModelPosition(player: Player, modelKey: string, posData: { X: number, Y: number, Z: number, Yaw: number })
	local customizer = DataService.GetCustomizer(player)
	customizer.Positions[modelKey] = posData
end

function DataService.GetModelPosition(player: Player, modelKey: string): { X: number, Y: number, Z: number, Yaw: number }?
	local customizer = DataService.GetCustomizer(player)
	return customizer.Positions and customizer.Positions[modelKey]
end

return DataService

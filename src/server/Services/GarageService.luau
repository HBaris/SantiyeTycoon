local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Network = require(ReplicatedStorage.Shared.Network)
local DataService = require(script.Parent.DataService)

local GarageService = {}
local playerVehicles = {} -- [Player] = Model
local playerCargo = {} -- [Player] = number
local activeCargoBoosts = {} -- [plotKey] = expireTick

-- Yardımcı Parça Oluşturucu
local function createPart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, canCollide: boolean): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.CanCollide = canCollide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- ============================================================================
-- 1. TAŞIT MODELLERİ (Scooter, Motosiklet, Kamyonet)
-- ============================================================================
local function buildVehicleModel(player: Player, vehicleType: string, spawnCFrame: CFrame): Model
	local vData = GameConfig.VEHICLES[vehicleType] or GameConfig.VEHICLES.Scooter
	local model = Instance.new("Model")
	model.Name = string.format("Vehicle_%s_%s", player.Name, vehicleType)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("VehicleType", vehicleType)

	local rootPart: BasePart

	if vehicleType == "Scooter" then
		-- 🛴 ŞANTİYE SCOOTER'I
		local seat = Instance.new("VehicleSeat")
		seat.Name = "Seat"
		seat.Size = Vector3.new(2, 0.8, 5)
		seat.CFrame = spawnCFrame * CFrame.new(0, 1.2, 0)
		seat.Color = vData.Color
		seat.Material = Enum.Material.Metal
		seat.MaxSpeed = vData.Speed
		seat.Torque = 15
		seat.TurnSpeed = 2.5
		seat.Parent = model
		rootPart = seat

		-- Gidon & Direk
		local stem = createPart(model, "Stem", Vector3.new(0.4, 3.2, 0.4), seat.CFrame * CFrame.new(0, 1.6, -2.2), Color3.fromRGB(50, 50, 55), Enum.Material.Metal, false)
		local handleBar = createPart(model, "HandleBar", Vector3.new(2.4, 0.4, 0.4), seat.CFrame * CFrame.new(0, 3.2, -2.2), Color3.fromRGB(30, 30, 30), Enum.Material.Rubber, false)

		-- Tekerlekler
		local wFront = createPart(model, "WheelFront", Vector3.new(0.6, 1.2, 1.2), seat.CFrame * CFrame.new(0, -0.2, -2.2), Color3.fromRGB(30, 30, 30), Enum.Material.Rubber, true)
		local wBack = createPart(model, "WheelBack", Vector3.new(0.6, 1.2, 1.2), seat.CFrame * CFrame.new(0, -0.2, 2.2), Color3.fromRGB(30, 30, 30), Enum.Material.Rubber, true)

		-- Ön Far
		local light = createPart(model, "Headlight", Vector3.new(0.5, 0.5, 0.3), seat.CFrame * CFrame.new(0, 2.5, -2.4), Color3.fromRGB(255, 255, 220), Enum.Material.Neon, false)
		local spot = Instance.new("SpotLight")
		spot.Range = 25
		spot.Brightness = 1.5
		spot.Face = Enum.NormalId.Back
		spot.Parent = light

		-- Kaynaklama (Weld)
		for _, p in ipairs({ stem, handleBar, wFront, wBack, light }) do
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = seat
			weld.Part1 = p
			weld.Parent = seat
		end

	elseif vehicleType == "Motorcycle" then
		-- 🏍️ MÜTEAHHİT MOTORU
		local seat = Instance.new("VehicleSeat")
		seat.Name = "Seat"
		seat.Size = Vector3.new(2.4, 1.2, 6)
		seat.CFrame = spawnCFrame * CFrame.new(0, 1.5, 0)
		seat.Color = vData.Color
		seat.Material = Enum.Material.SmoothPlastic
		seat.MaxSpeed = vData.Speed
		seat.Torque = 25
		seat.TurnSpeed = 2.8
		seat.Parent = model
		rootPart = seat

		local engine = createPart(model, "EngineBlock", Vector3.new(1.8, 1.4, 2), seat.CFrame * CFrame.new(0, -0.4, 0), Color3.fromRGB(60, 60, 65), Enum.Material.Metal, true)
		local tank = createPart(model, "FuelTank", Vector3.new(2.2, 1.2, 2.2), seat.CFrame * CFrame.new(0, 0.8, -1.2), vData.Color, Enum.Material.SmoothPlastic, false)
		local windshield = createPart(model, "Windshield", Vector3.new(2.0, 1.8, 0.3), seat.CFrame * CFrame.new(0, 1.8, -2.4) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(150, 220, 255), Enum.Material.Glass, false)

		local wF = createPart(model, "FrontWheel", Vector3.new(1.0, 2.2, 2.2), seat.CFrame * CFrame.new(0, -0.2, -3.2), Color3.fromRGB(30, 30, 30), Enum.Material.Rubber, true)
		local wR = createPart(model, "RearWheel", Vector3.new(1.4, 2.2, 2.2), seat.CFrame * CFrame.new(0, -0.2, 2.8), Color3.fromRGB(30, 30, 30), Enum.Material.Rubber, true)

		local light = createPart(model, "Headlight", Vector3.new(0.8, 0.8, 0.3), seat.CFrame * CFrame.new(0, 1.2, -3.2), Color3.fromRGB(255, 255, 230), Enum.Material.Neon, false)
		local spot = Instance.new("SpotLight")
		spot.Range = 40
		spot.Brightness = 2
		spot.Face = Enum.NormalId.Back
		spot.Parent = light

		for _, p in ipairs({ engine, tank, windshield, wF, wR, light }) do
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = seat
			weld.Part1 = p
			weld.Parent = seat
		end

	elseif vehicleType == "Car" then
		-- 🚗 AĞIR SAHA KAMYONETİ
		local seat = Instance.new("VehicleSeat")
		seat.Name = "Seat"
		seat.Size = Vector3.new(4, 1.2, 4)
		seat.CFrame = spawnCFrame * CFrame.new(-1.2, 1.6, 0)
		seat.Color = Color3.fromRGB(40, 40, 40)
		seat.Material = Enum.Material.Fabric
		seat.MaxSpeed = vData.Speed
		seat.Torque = 40
		seat.TurnSpeed = 2.2
		seat.Parent = model
		rootPart = seat

		-- Ana Gövde ve Kasa
		local chassis = createPart(model, "Chassis", Vector3.new(6.8, 1.2, 14), spawnCFrame * CFrame.new(0, 1.2, 0), Color3.fromRGB(50, 50, 55), Enum.Material.Metal, true)
		local cabin = createPart(model, "Cabin", Vector3.new(6.6, 4.0, 6.0), spawnCFrame * CFrame.new(0, 3.4, -1.5), vData.Color, Enum.Material.SmoothPlastic, true)
		local windshield = createPart(model, "Windshield", Vector3.new(6.2, 2.5, 0.4), spawnCFrame * CFrame.new(0, 3.8, -4.6), Color3.fromRGB(150, 220, 255), Enum.Material.Glass, false)
		local cargoBed = createPart(model, "CargoBed", Vector3.new(6.4, 2.2, 6.2), spawnCFrame * CFrame.new(0, 2.4, 3.6), Color3.fromRGB(80, 80, 85), Enum.Material.DiamondPlate, true)

		-- 4 Tekerlek
		local wheelPositions = {
			Vector3.new(-3.4, 0, -4.2), Vector3.new(3.4, 0, -4.2),
			Vector3.new(-3.4, 0, 4.2), Vector3.new(3.4, 0, 4.2),
		}
		for i, wPos in ipairs(wheelPositions) do
			local w = createPart(model, "Wheel_"..i, Vector3.new(1.4, 2.6, 2.6), spawnCFrame * CFrame.new(wPos.X, 1.3, wPos.Z), Color3.fromRGB(25, 25, 25), Enum.Material.Rubber, true)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = chassis
			weld.Part1 = w
			weld.Parent = chassis
		end

		local headlight = createPart(model, "Headlight", Vector3.new(5.5, 0.8, 0.4), spawnCFrame * CFrame.new(0, 2.4, -7.0), Color3.fromRGB(255, 255, 220), Enum.Material.Neon, false)
		local spot = Instance.new("SpotLight")
		spot.Range = 50
		spot.Brightness = 2.5
		spot.Face = Enum.NormalId.Back
		spot.Parent = headlight

		for _, p in ipairs({ cabin, windshield, cargoBed, headlight, seat }) do
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = chassis
			weld.Part1 = p
			weld.Parent = chassis
		end
		rootPart = chassis
	end

	model.PrimaryPart = rootPart

	-- Binme ProximityPrompt'u
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Bin (Sür)"
	prompt.ObjectText = vData.Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.Parent = rootPart

	prompt.Triggered:Connect(function(promptPlayer)
		local char = promptPlayer.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		local seat = model:FindFirstChild("Seat") :: VehicleSeat
		if humanoid and seat and not seat.Occupant then
			seat:Sit(humanoid)
		end
	end)

	model.Parent = Workspace
	return model
end

-- ============================================================================
-- 2. GARAJ SERVİSİ İLKLENDİRME
-- ============================================================================
function GarageService.Initialize()
	-- Garaj ve Depo İstasyonunu Oluştur
	GarageService.EnsureGarageEnvironment()

	-- Taşıt Satın Alma Dinleyicisi
	Network.BuyVehicleEvent.OnServerEvent:Connect(function(player: Player, vehicleId: string)
		local vData = GameConfig.VEHICLES[vehicleId]
		if not vData then return end

		local profile = DataService.GetProfile(player)
		if not profile then return end

		if DataService.OwnsVehicle(player, vehicleId) then
			-- Zaten sahip, aktif taşıt yap ve spawnla
			profile.Garage.Active = vehicleId
			GarageService.SpawnVehicle(player, vehicleId)
			return
		end

		if DataService.SpendCash(player, vData.Cost) then
			DataService.AddVehicle(player, vehicleId)
			GarageService.SpawnVehicle(player, vehicleId)
			print(string.format("[GarageService] %s yeni bir taşıt satın aldı: %s", player.Name, vData.Name))
		end
	end)

	-- Taşıt Çağırma / Spawn İsteği
	Network.SpawnVehicleEvent.OnServerEvent:Connect(function(player: Player, vehicleId: string)
		local profile = DataService.GetProfile(player)
		if not profile then return end

		vehicleId = vehicleId or (profile.Garage and profile.Garage.Active) or "Scooter"
		if DataService.OwnsVehicle(player, vehicleId) then
			profile.Garage.Active = vehicleId
			GarageService.SpawnVehicle(player, vehicleId)
		end
	end)

	-- Kargo Malzemesi Yükleme İsteği (Ana Depodan)
	Network.LoadCargoEvent.OnServerEvent:Connect(function(player: Player)
		local profile = DataService.GetProfile(player)
		if not profile then return end

		local activeVType = (profile.Garage and profile.Garage.Active) or "Scooter"
		local vData = GameConfig.VEHICLES[activeVType] or GameConfig.VEHICLES.Scooter

		playerCargo[player] = vData.CargoCapacity
		print(string.format("[GarageService] %s taşıtına %d birim şantiye malzemesi yükledi.", player.Name, vData.CargoCapacity))
	end)

	-- Kargo Boşaltma ve Şantiyeye Teslimat (2.5x Turbo Boost Tetikler)
	Network.DeliverCargoEvent.OnServerEvent:Connect(function(player: Player, plotIndex: number)
		plotIndex = tonumber(plotIndex) or 1
		local cargoAmount = playerCargo[player] or 0

		if cargoAmount > 0 then
			playerCargo[player] = 0

			-- Şantiyede 45 saniyelik Turbo Kargo Hızlandırması Başlat
			local boostKey = string.format("%s_%d", player.Name, plotIndex)
			activeCargoBoosts[boostKey] = tick() + GameConfig.CARGO_BOOST_DURATION

			-- Oyuncuya kargo teslim bonusu nakit ver
			local bonusCash = cargoAmount * 8
			DataService.AddCash(player, bonusCash)

			-- Tüm istemcilere görsel kargo turbosunu senkronize et
			Network.SyncTurboStatusEvent:FireAllClients(player, true, GameConfig.CARGO_BOOST_DURATION)
			print(string.format("[GarageService] %s Proje #%d için %d malzeme teslim etti! 45sn Turbo İnşaat başladı, +%d $ prim kazandı.", player.Name, plotIndex, cargoAmount, bonusCash))
		end
	end)

	-- Oyuncu katıldığında varsayılan taşıtını hazırla
	Players.PlayerAdded:Connect(function(player)
		task.delay(1.5, function()
			GarageService.SpawnVehicle(player, "Scooter")
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		if playerVehicles[player] then
			playerVehicles[player]:Destroy()
			playerVehicles[player] = nil
		end
		playerCargo[player] = nil
	end)
end

-- ============================================================================
-- 3. GARAJ VE LOJİSTİK MERKEZİ ÇEVRE OLUŞTURUCU
-- ============================================================================
function GarageService.EnsureGarageEnvironment()
	local existing = Workspace:FindFirstChild("GarageFacility")
	if existing then return existing end

	local folder = Instance.new("Folder")
	folder.Name = "GarageFacility"
	folder.Parent = Workspace

	local depotX, depotZ = -70, 55

	-- Garaj & Depo Zemin Platformu (Asfalt Park Alanı)
	createPart(folder, "GarageDepotFloor", Vector3.new(70, 0.6, 50), CFrame.new(depotX, 4.4, depotZ), Color3.fromRGB(55, 55, 60), Enum.Material.Asphalt, true)

	-- Ana Lojistik Malzeme Deposu Binası
	createPart(folder, "DepotBuilding", Vector3.new(34, 14, 24), CFrame.new(depotX - 12, 11, depotZ - 10), Color3.fromRGB(160, 100, 45), Enum.Material.CorrodedMetal, true)
	createPart(folder, "DepotRoof", Vector3.new(36, 1.2, 26), CFrame.new(depotX - 12, 18.5, depotZ - 10), Color3.fromRGB(80, 85, 90), Enum.Material.DiamondPlate, true)

	-- Depo Tabelası
	local signBoard = createPart(folder, "DepotSign", Vector3.new(18, 4, 0.6), CFrame.new(depotX - 12, 14, depotZ + 2.4), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, true)
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = signBoard
	local sLabel = Instance.new("TextLabel")
	sLabel.Size = UDim2.new(1, 0, 1, 0)
	sLabel.BackgroundTransparency = 1
	sLabel.Text = "📦 MERKEZİ MALZEME DEPOSU\n& MÜTEAHHİT GARAJI"
	sLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
	sLabel.Font = Enum.Font.FredokaOne
	sLabel.TextScaled = true
	sLabel.Parent = signGui

	-- Malzeme Yükleme İstasyonu (Drive-Thru Yükleme Alanı)
	local loadingPad = createPart(folder, "CargoLoadingPad", Vector3.new(16, 0.8, 14), CFrame.new(depotX + 14, 4.5, depotZ - 8), Color3.fromRGB(255, 180, 20), Enum.Material.SmoothPlastic, true)
	loadingPad:SetAttribute("IsCargoLoadingPad", true)

	local loadPrompt = Instance.new("ProximityPrompt")
	loadPrompt.ActionText = "Malzeme Yükle"
	loadPrompt.ObjectText = "Taşıta Yükle"
	loadPrompt.HoldDuration = 0.5
	loadPrompt.MaxActivationDistance = 18
	loadPrompt.KeyboardKeyCode = Enum.KeyCode.E
	loadPrompt.RequiresLineOfSight = false
	loadPrompt.Parent = loadingPad

	loadPrompt.Triggered:Connect(function(player)
		local profile = DataService.GetProfile(player)
		if profile then
			local activeVType = (profile.Garage and profile.Garage.Active) or "Scooter"
			local vData = GameConfig.VEHICLES[activeVType] or GameConfig.VEHICLES.Scooter
			playerCargo[player] = vData.CargoCapacity
			print(string.format("[GarageService] %s deposundan %d birim malzeme yükledi!", player.Name, vData.CargoCapacity))
		end
	end)

	local loadSign = Instance.new("BillboardGui")
	loadSign.Size = UDim2.new(8, 0, 3, 0)
	loadSign.StudsOffset = Vector3.new(0, 4, 0)
	loadSign.AlwaysOnTop = true
	loadSign.Parent = loadingPad

	local loadText = Instance.new("TextLabel")
	loadText.Size = UDim2.new(1, 0, 1, 0)
	loadText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	loadText.Text = "📦 MALZEME YÜKLEME\n(E'ye bas veya yanaş)"
	loadText.TextColor3 = Color3.fromRGB(20, 20, 20)
	loadText.Font = Enum.Font.FredokaOne
	loadText.TextScaled = true
	loadText.Parent = loadSign

	local lCorner = Instance.new("UICorner")
	lCorner.CornerRadius = UDim.new(0, 10)
	lCorner.Parent = loadText

	return folder
end

-- ============================================================================
-- 4. OYUNCU TAŞITI SPAWN ETME
-- ============================================================================
function GarageService.SpawnVehicle(player: Player, vehicleType: string)
	if playerVehicles[player] then
		playerVehicles[player]:Destroy()
		playerVehicles[player] = nil
	end

	local depotX, depotZ = -70, 55
	local spawnCFrame = CFrame.new(depotX + 16, 5.5, depotZ + 8) * CFrame.Angles(0, math.rad(90), 0)

	local vehicleModel = buildVehicleModel(player, vehicleType, spawnCFrame)
	playerVehicles[player] = vehicleModel
	return vehicleModel
end

function GarageService.GetPlayerCargo(player: Player): number
	return playerCargo[player] or 0
end

function GarageService.IsCargoBoostActive(player: Player, plotIndex: number): boolean
	local boostKey = string.format("%s_%d", player.Name, plotIndex)
	return (activeCargoBoosts[boostKey] or 0) > tick()
end

return GarageService

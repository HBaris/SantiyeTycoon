--!strict
-- ============================================================================
-- CityLifeService.luau
-- Canlı Mahalle Yaşamı, Cities: Skylines Sivil Yayalar, İşçi NPC'leri,
-- Promenade Gezintisi, Kafe Müşterileri ve Sokak Mobilyaları
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlotDataTypes = require(script.Parent.PlotDataTypes)

local createPart = PlotDataTypes.createPart
local createCylinder = PlotDataTypes.createCylinder

local CityLifeService = {}

-- ============================================================================
-- 1. ÇALIŞAN İŞÇİ NPC'LERİ (Canlı Şantiye Atmosferi)
-- ============================================================================
function CityLifeService.spawnWorkerNPC(parent: Instance, name: string, role: string, cframe: CFrame): Model
	local npc = Instance.new("Model")
	npc.Name = "Worker_" .. name

	local root = createPart(npc, "HumanoidRootPart", Vector3.new(2, 2, 1), cframe, Color3.fromRGB(40, 70, 130), Enum.Material.Fabric, true, false)
	npc.PrimaryPart = root

	-- Gövde & Reflektörlü Yelek
	local torso = createPart(npc, "Torso", Vector3.new(2, 2, 1), cframe, Color3.fromRGB(245, 120, 20), Enum.Material.SmoothPlastic, true, false)
	createPart(npc, "VestStripe", Vector3.new(2.1, 0.4, 1.1), cframe * CFrame.new(0, 0.2, 0), Color3.fromRGB(240, 240, 245), Enum.Material.SmoothPlastic, true, false)

	-- Kafa & Sarı İnşaat Bareti
	local head = createPart(npc, "Head", Vector3.new(1.2, 1.2, 1.2), cframe * CFrame.new(0, 1.6, 0), Color3.fromRGB(250, 210, 160), Enum.Material.SmoothPlastic, true, false)
	local hardhat = createPart(npc, "Hardhat", Vector3.new(1.4, 0.6, 1.6), cframe * CFrame.new(0, 2.2, 0), Color3.fromRGB(245, 200, 30), Enum.Material.SmoothPlastic, true, false)

	-- Bacaklar ve Kollar
	createPart(npc, "LegL", Vector3.new(0.8, 2, 0.8), cframe * CFrame.new(-0.55, -2, 0), Color3.fromRGB(40, 70, 130), Enum.Material.Fabric, true, false)
	createPart(npc, "LegR", Vector3.new(0.8, 2, 0.8), cframe * CFrame.new(0.55, -2, 0), Color3.fromRGB(40, 70, 130), Enum.Material.Fabric, true, false)
	local armL = createPart(npc, "ArmL", Vector3.new(0.8, 2, 0.8), cframe * CFrame.new(-1.4, 0, 0), Color3.fromRGB(245, 120, 20), Enum.Material.SmoothPlastic, true, false)
	local armR = createPart(npc, "ArmR", Vector3.new(0.8, 2, 0.8), cframe * CFrame.new(1.4, 0, 0), Color3.fromRGB(245, 120, 20), Enum.Material.SmoothPlastic, true, false)

	-- İsim Etiketi (BillboardGui - Beyaz Kart)
	local tagGui = Instance.new("BillboardGui")
	tagGui.Size = UDim2.new(4.5, 0, 1.4, 0)
	tagGui.StudsOffset = Vector3.new(0, 3.2, 0)
	tagGui.AlwaysOnTop = false
	tagGui.MaxDistance = 35
	tagGui.Parent = head

	local tagCard = Instance.new("Frame")
	tagCard.Size = UDim2.new(1, 0, 1, 0)
	tagCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	tagCard.BackgroundTransparency = 0.1
	tagCard.Parent = tagGui
	local tcCorner = Instance.new("UICorner")
	tcCorner.CornerRadius = UDim.new(0, 8)
	tcCorner.Parent = tagCard

	local tagLabel = Instance.new("TextLabel")
	tagLabel.Size = UDim2.new(0.95, 0, 0.9, 0)
	tagLabel.Position = UDim2.new(0.025, 0, 0.05, 0)
	tagLabel.BackgroundTransparency = 1
	tagLabel.Text = string.format("👷 %s\n[%s]", name, role)
	tagLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
	tagLabel.Font = Enum.Font.FredokaOne
	tagLabel.TextScaled = true
	tagLabel.Parent = tagCard

	-- Eline alet ekleme ve çalışma animasyonu
	local hHandle: Part? = nil
	local hHead: Part? = nil
	local clipboard: Part? = nil

	if role:find("Çekiç") then
		hHandle = createPart(npc, "ToolHandle", Vector3.new(0.3, 1.5, 0.3), armR.CFrame * CFrame.new(0, -0.8, -0.4) * CFrame.Angles(math.rad(45), 0, 0), Color3.fromRGB(150, 100, 50), Enum.Material.Wood, true, false)
		hHead = createPart(npc, "ToolHead", Vector3.new(0.6, 0.5, 0.8), hHandle.CFrame * CFrame.new(0, 0.7, 0), Color3.fromRGB(80, 80, 85), Enum.Material.Metal, true, false)
	elseif role:find("Plan") then
		clipboard = createPart(npc, "Clipboard", Vector3.new(1.2, 0.1, 1.4), armR.CFrame * CFrame.new(0, -0.6, -0.4) * CFrame.Angles(math.rad(30), 0, 0), Color3.fromRGB(240, 235, 220), Enum.Material.SmoothPlastic, true, false)
	end

	-- Çalışan Canlılık Animasyonu
	task.spawn(function()
		local baseArmRCF = cframe * CFrame.new(1.4, 0, 0)
		local baseHeadCF = cframe * CFrame.new(0, 1.6, 0)
		local baseHardhatCF = cframe * CFrame.new(0, 2.2, 0)

		if role:find("Çekiç") and hHandle and hHead then
			local swing = false
			while npc.Parent do
				task.wait(0.5)
				swing = not swing
				local angle = swing and math.rad(45) or math.rad(-15)
				local armCF = baseArmRCF * CFrame.Angles(angle, 0, 0)
				armR.CFrame = armCF
				local handleCF = armCF * CFrame.new(0, -0.8, -0.4) * CFrame.Angles(math.rad(45), 0, 0)
				hHandle.CFrame = handleCF
				hHead.CFrame = handleCF * CFrame.new(0, 0.7, 0)
			end
		elseif role:find("Plan") then
			local step = 0
			while npc.Parent do
				task.wait(2.2)
				step = (step + 1) % 3
				local rotY = (step == 1) and math.rad(-20) or ((step == 2) and math.rad(20) or 0)
				head.CFrame = baseHeadCF * CFrame.Angles(0, rotY, 0)
				hardhat.CFrame = baseHardhatCF * CFrame.Angles(0, rotY, 0)
			end
		end
	end)

	npc.Parent = parent
	return npc
end

-- ============================================================================
-- 2. CITIES: SKYLINES SİVİL MAHALLE SAKİNLERİ (Civilian Pedestrians)
-- ============================================================================
function CityLifeService.spawnCityResident(
	parent: Instance,
	name: string,
	role: string,
	outfit: any,
	startCF: CFrame,
	patrolDistance: number,
	patrolAxis: string?
): Model
	local npc = Instance.new("Model")
	npc.Name = "Resident_" .. name

	local axis = patrolAxis or "X"

	local root = createPart(npc, "HumanoidRootPart", Vector3.new(2, 2, 1), startCF, outfit.Pants, Enum.Material.Fabric, true, false)
	npc.PrimaryPart = root

	-- Gövde (Gündelik Şık Kıyafet)
	local torso = createPart(npc, "Torso", Vector3.new(2, 2, 1), startCF, outfit.Shirt, Enum.Material.Fabric, true, false)

	-- Kafa (Saçlı Şehirli Sakin)
	local head = createPart(npc, "Head", Vector3.new(1.2, 1.2, 1.2), startCF * CFrame.new(0, 1.6, 0), Color3.fromRGB(250, 210, 160), Enum.Material.SmoothPlastic, true, false)
	createPart(npc, "Hair", Vector3.new(1.3, 0.5, 1.3), startCF * CFrame.new(0, 2.1, -0.05), Color3.fromRGB(45, 30, 20), Enum.Material.SmoothPlastic, true, false)

	-- Bacaklar ve Kollar
	local legL = createPart(npc, "LegL", Vector3.new(0.8, 2, 0.8), startCF * CFrame.new(-0.55, -2, 0), outfit.Pants, Enum.Material.Fabric, true, false)
	local legR = createPart(npc, "LegR", Vector3.new(0.8, 2, 0.8), startCF * CFrame.new(0.55, -2, 0), outfit.Pants, Enum.Material.Fabric, true, false)
	local armL = createPart(npc, "ArmL", Vector3.new(0.8, 2, 0.8), startCF * CFrame.new(-1.4, 0, 0), outfit.Shirt, Enum.Material.Fabric, true, false)
	local armR = createPart(npc, "ArmR", Vector3.new(0.8, 2, 0.8), startCF * CFrame.new(1.4, 0, 0), outfit.Shirt, Enum.Material.Fabric, true, false)

	-- Kahve bardağı veya alışveriş çantası
	if role == "Kahve Sever" then
		createCylinder(npc, "CoffeeCup", Vector3.new(0.6, 0.35, 0.35), armR.CFrame * CFrame.new(0, -0.8, -0.3) * CFrame.Angles(0, 0, math.pi/2), Color3.fromRGB(245, 240, 230), Enum.Material.SmoothPlastic, true, false)
	elseif role == "Alışverişte" then
		createPart(npc, "ShoppingBag", Vector3.new(0.8, 1.0, 0.35), armL.CFrame * CFrame.new(0, -0.8, 0), Color3.fromRGB(240, 100, 80), Enum.Material.Fabric, true, false)
	end

	-- İsim Etiketi (BillboardGui - Beyaz Şık Kart)
	local tagGui = Instance.new("BillboardGui")
	tagGui.Size = UDim2.new(4.5, 0, 1.4, 0)
	tagGui.StudsOffset = Vector3.new(0, 3.2, 0)
	tagGui.AlwaysOnTop = false
	tagGui.MaxDistance = 35
	tagGui.Parent = head

	local tagCard = Instance.new("Frame")
	tagCard.Size = UDim2.new(1, 0, 1, 0)
	tagCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	tagCard.BackgroundTransparency = 0.1
	tagCard.Parent = tagGui
	local tcCorner = Instance.new("UICorner")
	tcCorner.CornerRadius = UDim.new(0, 8)
	tcCorner.Parent = tagCard

	local tagLabel = Instance.new("TextLabel")
	tagLabel.Size = UDim2.new(0.95, 0, 0.9, 0)
	tagLabel.Position = UDim2.new(0.025, 0, 0.05, 0)
	tagLabel.BackgroundTransparency = 1
	tagLabel.Text = string.format("🚶 %s\n[%s]", name, role)
	tagLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
	tagLabel.Font = Enum.Font.FredokaOne
	tagLabel.TextScaled = true
	tagLabel.Parent = tagCard

	-- Canlı Yürüme / Devriye Davranışı (X veya Z Ekseni Boyunca)
	if patrolDistance and patrolDistance > 4 then
		task.spawn(function()
			local origPos = startCF.Position
			local movingForward = true
			local currentStep = 0
			local maxSteps = math.floor(patrolDistance * 4)
			local stepDist = patrolDistance / maxSteps

			while npc.Parent do
				task.wait(0.12)
				if movingForward then
					currentStep += 1
					if currentStep >= maxSteps then
						movingForward = false
						task.wait(2.5) -- Vitrinde duraklama
					end
				else
					currentStep -= 1
					if currentStep <= 0 then
						movingForward = true
						task.wait(2.5)
					end
				end

				local newPos: Vector3
				local rotY: number

				if axis == "Z" then
					local newZ = origPos.Z + (currentStep * stepDist)
					newPos = Vector3.new(origPos.X, origPos.Y, newZ)
					rotY = movingForward and 0 or math.pi
				else
					local newX = origPos.X + (currentStep * stepDist)
					newPos = Vector3.new(newX, origPos.Y, origPos.Z)
					rotY = movingForward and (math.pi / 2) or (-math.pi / 2)
				end

				local newCF = CFrame.new(newPos) * CFrame.Angles(0, rotY, 0)

				root.CFrame = newCF
				torso.CFrame = newCF
				head.CFrame = newCF * CFrame.new(0, 1.6, 0)
				legL.CFrame = newCF * CFrame.new(-0.55, -2, 0)
				legR.CFrame = newCF * CFrame.new(0.55, -2, 0)
				armL.CFrame = newCF * CFrame.new(-1.4, 0, 0)
				armR.CFrame = newCF * CFrame.new(1.4, 0, 0)
			end
		end)
	end

	npc.Parent = parent
	return npc
end

-- ============================================================================
-- 3. OTURAN SAKİNLER (Kafe Masaları ve Park Banklarında Dinlenenler)
-- ============================================================================
function CityLifeService.spawnSeatedResident(
	parent: Instance,
	name: string,
	role: string,
	outfit: any,
	seatCF: CFrame,
	hasCoffee: boolean?
): Model
	local npc = Instance.new("Model")
	npc.Name = "Seated_" .. name

	-- Oturma Pozisyonu
	local root = createPart(npc, "HumanoidRootPart", Vector3.new(2, 2, 1), seatCF * CFrame.new(0, 1.1, 0), outfit.Pants, Enum.Material.Fabric, true, false)
	npc.PrimaryPart = root

	local torso = createPart(npc, "Torso", Vector3.new(2, 2, 1), seatCF * CFrame.new(0, 1.1, 0), outfit.Shirt, Enum.Material.Fabric, true, false)
	local head = createPart(npc, "Head", Vector3.new(1.2, 1.2, 1.2), seatCF * CFrame.new(0, 2.7, 0), Color3.fromRGB(250, 210, 160), Enum.Material.SmoothPlastic, true, false)
	createPart(npc, "Hair", Vector3.new(1.3, 0.5, 1.3), seatCF * CFrame.new(0, 3.2, -0.05), Color3.fromRGB(50, 35, 25), Enum.Material.SmoothPlastic, true, false)

	-- Oturur pozisyonda bacaklar (İleriye 90 derece bükülü)
	createPart(npc, "SeatLegL", Vector3.new(0.8, 0.8, 1.8), seatCF * CFrame.new(-0.55, 0.3, 0.8), outfit.Pants, Enum.Material.Fabric, true, false)
	createPart(npc, "SeatLegR", Vector3.new(0.8, 0.8, 1.8), seatCF * CFrame.new(0.55, 0.3, 0.8), outfit.Pants, Enum.Material.Fabric, true, false)

	-- Kollar (Masaya veya kucağa doğru)
	local armL = createPart(npc, "ArmL", Vector3.new(0.8, 1.6, 0.8), seatCF * CFrame.new(-1.3, 1.0, 0.4) * CFrame.Angles(math.rad(35), 0, 0), outfit.Shirt, Enum.Material.Fabric, true, false)
	local armR = createPart(npc, "ArmR", Vector3.new(0.8, 1.6, 0.8), seatCF * CFrame.new(1.3, 1.0, 0.4) * CFrame.Angles(math.rad(35), 0, 0), outfit.Shirt, Enum.Material.Fabric, true, false)

	if hasCoffee then
		createCylinder(npc, "HandCup", Vector3.new(0.5, 0.35, 0.35), armR.CFrame * CFrame.new(0, -0.7, 0.3) * CFrame.Angles(0, 0, math.pi/2), Color3.fromRGB(245, 240, 230), Enum.Material.SmoothPlastic, true, false)
	end

	-- İsim Etiketi
	local tagGui = Instance.new("BillboardGui")
	tagGui.Size = UDim2.new(4.5, 0, 1.4, 0)
	tagGui.StudsOffset = Vector3.new(0, 3.4, 0)
	tagGui.AlwaysOnTop = false
	tagGui.MaxDistance = 35
	tagGui.Parent = head

	local tagCard = Instance.new("Frame")
	tagCard.Size = UDim2.new(1, 0, 1, 0)
	tagCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	tagCard.BackgroundTransparency = 0.1
	tagCard.Parent = tagGui
	local tcCorner = Instance.new("UICorner")
	tcCorner.CornerRadius = UDim.new(0, 8)
	tcCorner.Parent = tagCard

	local tagLabel = Instance.new("TextLabel")
	tagLabel.Size = UDim2.new(0.95, 0, 0.9, 0)
	tagLabel.Position = UDim2.new(0.025, 0, 0.05, 0)
	tagLabel.BackgroundTransparency = 1
	tagLabel.Text = string.format("☕ %s\n[%s]", name, role)
	tagLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
	tagLabel.Font = Enum.Font.FredokaOne
	tagLabel.TextScaled = true
	tagLabel.Parent = tagCard

	npc.Parent = parent
	return npc
end

-- ============================================================================
-- 4. AÇIK HAVA ÇARŞISI SAKİNLERİ (Promenade Living Pedestrians & Cafe Patrons)
-- ============================================================================
function CityLifeService.spawnPromenadeResidents(parent: Instance, plotOrigin: Vector3, level: number): Folder
	local promResidents = Instance.new("Folder")
	promResidents.Name = "PromenadeResidents"

	local pX, pY, pZ = plotOrigin.X, plotOrigin.Y + 2.2, plotOrigin.Z
	local walkX = pX - 22

	-- 1. Çarşı Yürüme Caddesinde Z Ekseni Boyunca Devriye Atan Yayalar
	-- Yaya 1: Kuzeyden güneye vitrinleri gezerek yürür
	local outfit1 = GameConfig.CITY_RESIDENTS.Outfits[1]
	local walkCF1 = CFrame.new(walkX - 1.2, pY + 4.0, pZ - 20)
	CityLifeService.spawnCityResident(promResidents, "Selin", "Alışverişte", outfit1, walkCF1, 44, "Z")

	-- Yaya 2: Elinde kahvesiyle güneyden kuzeye yürür
	local outfit2 = GameConfig.CITY_RESIDENTS.Outfits[2]
	local walkCF2 = CFrame.new(walkX + 1.2, pY + 4.0, pZ + 22)
	CityLifeService.spawnCityResident(promResidents, "Deniz", "Kahve Sever", outfit2, walkCF2, 38, "Z")

	-- 2. Havuz Başındaki Bankta Dinlenen Sakin
	local outfit3 = GameConfig.CITY_RESIDENTS.Outfits[3]
	local benchCF = CFrame.new(pX - 14, pY + 0.6, pZ + 3.2) * CFrame.Angles(0, 0, 0)
	CityLifeService.spawnSeatedResident(promResidents, "Murat", "Havuz Keyfi", outfit3, benchCF, true)

	-- 3. Seviye 5 İse Kafe Terası Müşterileri (Bistro Sandalyelerinde Oturanlar)
	if level >= 5 then
		local cafeX = pX - 14
		local outfit4 = GameConfig.CITY_RESIDENTS.Outfits[4]
		local outfit5 = GameConfig.CITY_RESIDENTS.Outfits[5]

		-- 1. Masanın Sandalyesi
		local chairCF1 = CFrame.new(cafeX - 3.6 - 1.6, pY + 0.6, pZ - 20 - 1.5) * CFrame.Angles(0, math.rad(90), 0)
		CityLifeService.spawnSeatedResident(promResidents, "Ece", "Bistro Sohbeti", outfit4, chairCF1, true)

		-- 2. Masanın Sandalyesi
		local chairCF2 = CFrame.new(cafeX + 3.6 + 1.6, pY + 0.6, pZ - 20 + 4.2) * CFrame.Angles(0, math.rad(-90), 0)
		CityLifeService.spawnSeatedResident(promResidents, "Burak", "Kafede Dinleniyor", outfit5, chairCF2, true)
	end

	promResidents.Parent = parent
	return promResidents
end

-- ============================================================================
-- 5. KENTSEL YAŞAM OBJELERİ (Hazır Roblox Modelleri Entegrasyonu için Ayrıldı)
-- ============================================================================
function CityLifeService.spawnUrbanProps(parent: Instance, plotOrigin: Vector3): Model?
	return nil
end

return CityLifeService

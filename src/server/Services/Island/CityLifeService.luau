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
	createPart(npc, "Hardhat", Vector3.new(1.4, 0.6, 1.6), cframe * CFrame.new(0, 2.2, 0), Color3.fromRGB(245, 200, 30), Enum.Material.SmoothPlastic, true, false)

	-- Bacaklar ve Kollar
	createPart(npc, "LegL", Vector3.new(0.8, 2, 0.8), cframe * CFrame.new(-0.55, -2, 0), Color3.fromRGB(40, 70, 130), Enum.Material.Fabric, true, false)
	createPart(npc, "LegR", Vector3.new(0.8, 2, 0.8), cframe * CFrame.new(0.55, -2, 0), Color3.fromRGB(40, 70, 130), Enum.Material.Fabric, true, false)
	local armL = createPart(npc, "ArmL", Vector3.new(0.8, 2, 0.8), cframe * CFrame.new(-1.4, 0, 0), Color3.fromRGB(245, 120, 20), Enum.Material.SmoothPlastic, true, false)
	local armR = createPart(npc, "ArmR", Vector3.new(0.8, 2, 0.8), cframe * CFrame.new(1.4, 0, 0), Color3.fromRGB(245, 120, 20), Enum.Material.SmoothPlastic, true, false)

	-- İsim Etiketi (BillboardGui - Beyaz Kart)
	local tagGui = Instance.new("BillboardGui")
	tagGui.Size = UDim2.new(4.5, 0, 1.4, 0)
	tagGui.StudsOffset = Vector3.new(0, 3.2, 0)
	tagGui.AlwaysOnTop = true
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

	-- Eline alet ekleme
	if role:find("Çekiç") then
		local hHandle = createPart(npc, "ToolHandle", Vector3.new(0.3, 1.5, 0.3), armR.CFrame * CFrame.new(0, -0.8, -0.4) * CFrame.Angles(math.rad(45), 0, 0), Color3.fromRGB(150, 100, 50), Enum.Material.Wood, true, false)
		createPart(npc, "ToolHead", Vector3.new(0.6, 0.5, 0.8), hHandle.CFrame * CFrame.new(0, 0.7, 0), Color3.fromRGB(80, 80, 85), Enum.Material.Metal, true, false)
	elseif role:find("Plan") then
		createPart(npc, "Clipboard", Vector3.new(1.2, 0.1, 1.4), armR.CFrame * CFrame.new(0, -0.6, -0.4) * CFrame.Angles(math.rad(30), 0, 0), Color3.fromRGB(240, 235, 220), Enum.Material.SmoothPlastic, true, false)
	end

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
	tagGui.AlwaysOnTop = true
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
	tagGui.AlwaysOnTop = true
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
-- 5. KENTSEL YAŞAM OBJELERİ (Cities: Skylines Urban Props)
-- ============================================================================
function CityLifeService.spawnUrbanProps(parent: Instance, plotOrigin: Vector3): Model
	local props = Instance.new("Model")
	props.Name = "UrbanProps"

	local pX, pZ = plotOrigin.X, plotOrigin.Z
	local sidewalkZ = pZ + 36 -- Otoyol kenarı kaldırım hattı

	-- 1. Cam Otobüs Durağı (Modern Glass Bus Stop)
	local busStopCF = CFrame.new(pX - 18, 5.8, sidewalkZ)
	createPart(props, "BusStopBack", Vector3.new(12, 7, 0.4), busStopCF * CFrame.new(0, 0, -2.5), Color3.fromRGB(190, 235, 255), Enum.Material.Glass, true, true)
	createPart(props, "BusStopRoof", Vector3.new(13, 0.6, 6), busStopCF * CFrame.new(0, 3.6, 0.2), Color3.fromRGB(50, 55, 60), Enum.Material.Metal, true, true)
	for _, sx in ipairs({ -5.8, 5.8 }) do
		createPart(props, "BusStopSide", Vector3.new(0.4, 7, 4.5), busStopCF * CFrame.new(sx, 0, -0.4), Color3.fromRGB(190, 235, 255), Enum.Material.Glass, true, true)
	end
	createPart(props, "BusStopBench", Vector3.new(8, 1.2, 1.8), busStopCF * CFrame.new(0, -2.2, -1.2), Color3.fromRGB(130, 85, 45), Enum.Material.WoodPlanks, true, true)
	local bSign = createPart(props, "BusSign", Vector3.new(3.5, 2.5, 0.3), busStopCF * CFrame.new(-6.2, 1.8, 2.2), Color3.fromRGB(30, 100, 220), Enum.Material.SmoothPlastic, true, true)
	local bGui = Instance.new("SurfaceGui")
	bGui.Face = Enum.NormalId.Front
	bGui.Parent = bSign
	local bLbl = Instance.new("TextLabel")
	bLbl.Size = UDim2.new(1, 0, 1, 0)
	bLbl.BackgroundTransparency = 1
	bLbl.Text = "🚏 OTOBÜS DURAĞI\n(HAT 42: ŞANTİYE-KENT)"
	bLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	bLbl.Font = Enum.Font.FredokaOne
	bLbl.TextScaled = true
	bLbl.Parent = bGui

	-- 2. Kırmızı Yangın Musluğu (Fire Hydrant)
	local hydrantCF = CFrame.new(pX + 28, 5.2, sidewalkZ)
	createCylinder(props, "HydrantBody", Vector3.new(2.4, 1.2, 1.2), hydrantCF * CFrame.Angles(0, 0, math.pi/2), Color3.fromRGB(220, 40, 40), Enum.Material.Metal, true, true)
	createPart(props, "HydrantTop", Vector3.new(1.4, 0.6, 1.4), hydrantCF * CFrame.new(0, 1.4, 0), Color3.fromRGB(220, 40, 40), Enum.Material.Metal, true, true)

	-- 3. Paslanmaz Çelik Şehir Çöp Kovası
	local binCF = CFrame.new(pX + 24, 5.2, sidewalkZ)
	createCylinder(props, "TrashBin", Vector3.new(2.6, 1.4, 1.4), binCF * CFrame.Angles(0, 0, math.pi/2), Color3.fromRGB(70, 75, 80), Enum.Material.Metal, true, true)

	-- 4. Sokak İsim Levhası (Yeşil Şehir Tabelası)
	local postCF = CFrame.new(pX + 32, 8.5, sidewalkZ)
	createPart(props, "SignPole", Vector3.new(0.5, 8, 0.5), postCF, Color3.fromRGB(60, 65, 70), Enum.Material.Metal, true, true)
	local stSign = createPart(props, "StreetNamePlate", Vector3.new(6.5, 1.2, 0.2), postCF * CFrame.new(0, 3.6, 0), Color3.fromRGB(35, 120, 60), Enum.Material.SmoothPlastic, true, true)
	local stGui = Instance.new("SurfaceGui")
	stGui.Face = Enum.NormalId.Front
	stGui.Parent = stSign
	local stLbl = Instance.new("TextLabel")
	stLbl.Size = UDim2.new(1, 0, 1, 0)
	stLbl.BackgroundTransparency = 1
	stLbl.Text = "BARBAROS BULVARI"
	stLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	stLbl.Font = Enum.Font.FredokaOne
	stLbl.TextScaled = true
	stLbl.Parent = stGui

	-- 5. Park Etmiş Sivil Otomobil (Civilian Sedan)
	local carCF = CFrame.new(pX - 28, 5.4, sidewalkZ + 12)
	createPart(props, "CivCarChassis", Vector3.new(6.2, 1.2, 13), carCF, Color3.fromRGB(40, 70, 130), Enum.Material.SmoothPlastic, true, true)
	createPart(props, "CivCarCabin", Vector3.new(5.8, 2.2, 7.5), carCF * CFrame.new(0, 1.6, -0.6), Color3.fromRGB(40, 70, 130), Enum.Material.SmoothPlastic, true, true)
	createPart(props, "CivCarWindshield", Vector3.new(5.4, 1.8, 0.4), carCF * CFrame.new(0, 1.6, -4.4) * CFrame.Angles(math.rad(-25), 0, 0), Color3.fromRGB(160, 220, 250), Enum.Material.Glass, true, false)
	createPart(props, "CivCarRearWindow", Vector3.new(5.4, 1.8, 0.4), carCF * CFrame.new(0, 1.6, 3.2) * CFrame.Angles(math.rad(25), 0, 0), Color3.fromRGB(160, 220, 250), Enum.Material.Glass, true, false)

	props.Parent = parent
	return props
end

return CityLifeService

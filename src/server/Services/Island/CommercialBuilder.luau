--!strict
-- ============================================================================
-- CommercialBuilder.luau
-- Açık Hava Çarşısı / Promenade Meydanı (Mixed-Use Commercial Promenade)
-- Müstakil Butik Pavyonlar (Fırın, Market, Berber, PetShop, Bistro Kafe)
-- Süs Havuzu, Cadde Aydınlatmaları, Banklar, Çiçeklikler ve Kira Gelir Tabelası
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local PlotDataTypes = require(script.Parent.PlotDataTypes)

local createPart = PlotDataTypes.createPart
local createCylinder = PlotDataTypes.createCylinder

local CommercialBuilder = {}

-- ReplicatedStorage.Assets.Commercial altındaki hazır modelleri arayan fonksiyon
local function getReadyCommercialModel(shopId: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then return nil end
	local commFolder = assets:FindFirstChild("Commercial")
	if not commFolder then return nil end

	local candidate = commFolder:FindFirstChild(shopId)
	if candidate and candidate:IsA("Model") then
		return candidate
	end
	return nil
end

local function instantiateReadyModel(template: Model, targetCF: CFrame, maxAllowedSize: number): Model
	local model = template:Clone()
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("Script") or desc:IsA("LocalScript") then
			desc:Destroy()
		elseif desc:IsA("BasePart") then
			desc.Anchored = true
		end
	end

	local _, size = model:GetBoundingBox()
	local maxHoriz = math.max(size.X, size.Z)
	if maxHoriz > maxAllowedSize then
		model:ScaleTo(maxAllowedSize / maxHoriz)
		_, size = model:GetBoundingBox()
	end

	-- Zemin üzerinde düzgün duracak şekilde PivotTo
	local placedCF = targetCF * CFrame.new(0, size.Y / 2, 0)
	model:PivotTo(placedCF)

	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end

	return model
end

-- ============================================================================
-- 1. YARDIMCI PROMODANE OBJELERİ (Sokak Lambası, Bank, Çiçeklik, Havuz)
-- ============================================================================

-- Modern Siyah Sokak Lambası (Dual LED Streetlamp)
function CommercialBuilder.buildPromenadeLamp(parent: Instance, cf: CFrame): Model
	local lamp = Instance.new("Model")
	lamp.Name = "PromenadeLamp"

	-- Taban & Direk
	createPart(lamp, "LampBase", Vector3.new(1.4, 0.8, 1.4), cf * CFrame.new(0, 0.4, 0), Color3.fromRGB(35, 38, 42), Enum.Material.Metal, true, true)
	createPart(lamp, "LampPole", Vector3.new(0.6, 9.5, 0.6), cf * CFrame.new(0, 5.2, 0), Color3.fromRGB(45, 48, 55), Enum.Material.Metal, true, true)

	-- Üst Çapraz Kol ve İkiz Fenerler
	createPart(lamp, "LampArm", Vector3.new(3.2, 0.4, 0.5), cf * CFrame.new(0, 9.8, 0), Color3.fromRGB(45, 48, 55), Enum.Material.Metal, true, true)

	for _, lx in ipairs({ -1.3, 1.3 }) do
		local bulb = createPart(lamp, "LampBulb", Vector3.new(0.8, 0.9, 0.8), cf * CFrame.new(lx, 9.2, 0), Color3.fromRGB(255, 245, 210), Enum.Material.Neon, true, false)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 235, 190)
		light.Brightness = 1.1
		light.Range = 18
		light.Parent = bulb
	end

	lamp.Parent = parent
	return lamp
end

-- Ahşap & Demir Park Bankı (Promenade Bench)
function CommercialBuilder.buildBench(parent: Instance, cf: CFrame): Model
	local bench = Instance.new("Model")
	bench.Name = "PromenadeBench"

	-- Siyah Demir Ayaklar
	for _, bx in ipairs({ -2.2, 2.2 }) do
		createPart(bench, "BenchLeg", Vector3.new(0.3, 1.8, 1.8), cf * CFrame.new(bx, 0.9, 0), Color3.fromRGB(35, 38, 42), Enum.Material.Metal, true, true)
	end

	-- Ahşap Oturma Lamelleri
	for s = 1, 3 do
		createPart(bench, "SeatSlat_"..s, Vector3.new(5.0, 0.25, 0.5), cf * CFrame.new(0, 1.6, -0.6 + (s * 0.4)), Color3.fromRGB(150, 95, 45), Enum.Material.WoodPlanks, true, true)
	end

	-- Ahşap Sırtlık
	for b = 1, 2 do
		createPart(bench, "BackSlat_"..b, Vector3.new(5.0, 0.4, 0.25), cf * CFrame.new(0, 2.3 + (b * 0.45), -0.7), Color3.fromRGB(150, 95, 45), Enum.Material.WoodPlanks, true, true)
	end

	bench.Parent = parent
	return bench
end

-- Modern Beton Çiçeklik & Çalı (Modern Concrete Planter)
function CommercialBuilder.buildPlanter(parent: Instance, cf: CFrame): Model
	local planter = Instance.new("Model")
	planter.Name = "PromenadePlanter"

	-- Beton Saksı
	createPart(planter, "PlanterBox", Vector3.new(4.2, 1.6, 2.4), cf * CFrame.new(0, 0.8, 0), Color3.fromRGB(220, 220, 225), Enum.Material.Concrete, true, true)

	-- Toprak & Yeşil Çalı
	createPart(planter, "Soil", Vector3.new(3.8, 0.3, 2.0), cf * CFrame.new(0, 1.6, 0), Color3.fromRGB(80, 55, 35), Enum.Material.Ground, true, true)
	createPart(planter, "HedgeBush", Vector3.new(3.6, 1.2, 1.8), cf * CFrame.new(0, 2.2, 0), Color3.fromRGB(45, 130, 55), Enum.Material.Grass, true, true)

	-- Renkli Çiçek Vurguları (Kırmızı, Beyaz, Sarı)
	local flowerColors = { Color3.fromRGB(240, 70, 70), Color3.fromRGB(255, 240, 90), Color3.fromRGB(240, 140, 200) }
	for i, fCol in ipairs(flowerColors) do
		local fx = -1.2 + (i - 1) * 1.2
		createPart(planter, "Flower_"..i, Vector3.new(0.6, 0.6, 0.6), cf * CFrame.new(fx, 2.8, 0), fCol, Enum.Material.Neon, true, false)
	end

	planter.Parent = parent
	return planter
end

-- Paslanmaz Çelik Şık Çöp Kovası
function CommercialBuilder.buildTrashBin(parent: Instance, cf: CFrame): Model
	local bin = Instance.new("Model")
	bin.Name = "PromenadeTrashBin"
	createCylinder(bin, "BinBody", Vector3.new(2.4, 1.2, 1.2), cf * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.pi/2), Color3.fromRGB(75, 80, 85), Enum.Material.Metal, true, true)
	createPart(bin, "BinCover", Vector3.new(1.3, 0.3, 1.3), cf * CFrame.new(0, 2.45, 0), Color3.fromRGB(40, 45, 50), Enum.Material.Metal, true, true)
	bin.Parent = parent
	return bin
end

-- Dekoratif Süs Havuzu & Işıklı Fıskiye (Ornamental Fountain)
function CommercialBuilder.buildFountain(parent: Instance, cf: CFrame): Model
	local ready = getReadyCommercialModel("Fountain")
	if ready then
		local m = instantiateReadyModel(ready, cf, 9.0)
		m.Name = "FountainPool"
		m.Parent = parent
		return m
	end

	local fountain = Instance.new("Model")
	fountain.Name = "FountainPool"

	-- Dış Granit Havuz Çerçevesi (8x8 stud)
	createPart(fountain, "PoolBasin", Vector3.new(8.0, 1.4, 8.0), cf * CFrame.new(0, 0.7, 0), Color3.fromRGB(110, 115, 120), Enum.Material.Cobblestone, true, true)
	createPart(fountain, "PoolBasinRim", Vector3.new(8.6, 0.4, 8.6), cf * CFrame.new(0, 1.4, 0), Color3.fromRGB(60, 65, 72), Enum.Material.Concrete, true, true)

	-- Berrak Turkuaz Su Alanı
	local water = createPart(fountain, "PoolWater", Vector3.new(7.2, 0.5, 7.2), cf * CFrame.new(0, 1.1, 0), Color3.fromRGB(35, 185, 225), Enum.Material.Glass, true, false)
	water.Transparency = 0.25

	-- Merkez Kaide ve Üst Çanak
	createPart(fountain, "Pedestal", Vector3.new(2.2, 2.6, 2.2), cf * CFrame.new(0, 1.6, 0), Color3.fromRGB(160, 165, 170), Enum.Material.Cobblestone, true, true)
	createCylinder(fountain, "UpperTier", Vector3.new(0.6, 4.4, 4.4), cf * CFrame.new(0, 2.8, 0) * CFrame.Angles(0, 0, math.pi/2), Color3.fromRGB(130, 135, 140), Enum.Material.Concrete, true, true)

	-- Işıltılı Su Fıskiyesi (Su Jeti)
	local waterJet = createPart(fountain, "WaterJet", Vector3.new(0.6, 3.2, 0.6), cf * CFrame.new(0, 4.4, 0), Color3.fromRGB(180, 240, 255), Enum.Material.Neon, true, false)
	local fLight = Instance.new("PointLight")
	fLight.Color = Color3.fromRGB(60, 210, 255)
	fLight.Brightness = 1.6
	fLight.Range = 22
	fLight.Parent = waterJet

	fountain.Parent = parent
	return fountain
end

-- ============================================================================
-- 2. MÜSTAKİL BUTİK MAĞAZA PAVYONLARI (Detached Retail Pavilions)
-- ============================================================================

-- Ortak Pavyon Kabuğu Üreticisi (Shell Builder)
local function buildPavilionShell(
	parent: Instance,
	cf: CFrame,
	shopId: string,
	shopDisplayName: string,
	shopIcon: string,
	brandColor: Color3,
	awningColor1: Color3,
	awningColor2: Color3
): (Model, Part)
	local pav = Instance.new("Model")
	pav.Name = "Shop_" .. shopId

	local width, height, depth = 9.5, 7.2, 6.0
	local halfW = width / 2

	-- 1. Zemin Betonu / Pavyon Plinth
	createPart(pav, "PavilionPlinth", Vector3.new(width + 0.6, 0.6, depth + 0.6), cf * CFrame.new(0, -height/2 + 0.3, 0), Color3.fromRGB(60, 65, 70), Enum.Material.Concrete, true, true)

	-- 2. Arka ve Yan Taşıyıcı Duvarlar (Modern Koyu Kömür Dokusu)
	createPart(pav, "BackWall", Vector3.new(width, height, 0.6), cf * CFrame.new(0, 0, -depth/2 + 0.3), Color3.fromRGB(48, 52, 58), Enum.Material.Concrete, true, true)
	createPart(pav, "SideWallL", Vector3.new(0.6, height, depth - 0.6), cf * CFrame.new(-halfW + 0.3, 0, 0), Color3.fromRGB(48, 52, 58), Enum.Material.Concrete, true, true)
	createPart(pav, "SideWallR", Vector3.new(0.6, height, depth - 0.6), cf * CFrame.new(halfW - 0.3, 0, 0), Color3.fromRGB(48, 52, 58), Enum.Material.Concrete, true, true)

	-- 3. Ön Panoramik Vitrin Camı ve Alüminyum Çerçeve
	createPart(pav, "FrontMullionL", Vector3.new(0.5, height, 0.5), cf * CFrame.new(-halfW + 0.25, 0, depth/2 - 0.25), Color3.fromRGB(35, 38, 42), Enum.Material.Metal, true, true)
	createPart(pav, "FrontMullionR", Vector3.new(0.5, height, 0.5), cf * CFrame.new(halfW - 0.25, 0, depth/2 - 0.25), Color3.fromRGB(35, 38, 42), Enum.Material.Metal, true, true)
	createPart(pav, "ShowcaseGlass", Vector3.new(width - 1.0, height - 1.8, 0.4), cf * CFrame.new(0, -0.4, depth/2 - 0.2), Color3.fromRGB(180, 230, 255), Enum.Material.Glass, true, false)

	-- 4. İç Mekan Tezgâhı ve Sıcak İç Mekan Aydınlatması
	createPart(pav, "InteriorCounter", Vector3.new(width - 2.4, 2.2, 1.8), cf * CFrame.new(0, -height/2 + 1.4, 0.2), Color3.fromRGB(110, 80, 45), Enum.Material.WoodPlanks, true, true)
	local intLight = createPart(pav, "CeilingSpot", Vector3.new(2, 0.2, 2), cf * CFrame.new(0, height/2 - 0.4, 0), Color3.fromRGB(255, 245, 205), Enum.Material.Neon, true, false)
	local pLight = Instance.new("PointLight")
	pLight.Color = Color3.fromRGB(255, 235, 190)
	pLight.Brightness = 1.3
	pLight.Range = 20
	pLight.Parent = intLight

	-- 5. Çizgili Kumaş Tente (Awning)
	local awningY = (height / 2) - 0.4
	local awningZ = (depth / 2) + 1.2
	local stripeCount = 6
	local stripeW = (width - 0.4) / stripeCount
	for s = 1, stripeCount do
		local sCol = (s % 2 == 1) and awningColor1 or awningColor2
		local sX = -halfW + 0.2 + (s - 0.5) * stripeW
		createPart(
			pav, "Awning_"..s,
			Vector3.new(stripeW, 0.25, 3.2),
			cf * CFrame.new(sX, awningY, awningZ) * CFrame.Angles(math.rad(22), 0, 0),
			sCol,
			Enum.Material.Fabric,
			true, true
		)
	end

	-- 6. Modern 3D Işıklı Tabela (Fascia Neon Sign)
	local signBoard = createPart(
		pav, "SignBoard",
		Vector3.new(width - 0.2, 1.6, 0.6),
		cf * CFrame.new(0, (height / 2) + 0.9, depth/2 - 0.1),
		brandColor,
		Enum.Material.SmoothPlastic,
		true, true
	)
	local sGui = Instance.new("SurfaceGui")
	sGui.Face = Enum.NormalId.Front
	sGui.Parent = signBoard
	local sTxt = Instance.new("TextLabel")
	sTxt.Size = UDim2.new(1, 0, 1, 0)
	sTxt.BackgroundTransparency = 1
	sTxt.Text = string.format("%s %s", shopIcon, shopDisplayName:upper())
	sTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
	sTxt.TextStrokeTransparency = 0.2
	sTxt.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
	sTxt.Font = Enum.Font.FredokaOne
	sTxt.TextScaled = true
	sTxt.Parent = sGui

	-- 7. Modern Düz Çatı & İnce Alüminyum Saçak
	createPart(pav, "RoofSlab", Vector3.new(width + 0.8, 0.6, depth + 1.4), cf * CFrame.new(0, height/2 + 1.8, 0.4), Color3.fromRGB(38, 42, 48), Enum.Material.Metal, true, true)

	pav.Parent = parent
	return pav, signBoard
end

-- A. Taş Fırın & Patisserie Pavyonu
function CommercialBuilder.buildBakeryPavilion(parent: Instance, cf: CFrame): Model
	local ready = getReadyCommercialModel("Bakery")
	if ready then
		local m = instantiateReadyModel(ready, cf, 12.0)
		m.Name = "Shop_Bakery"
		m.Parent = parent
		return m
	end

	local pav = buildPavilionShell(
		parent, cf,
		"Bakery", "Taş Fırın & Patisserie", "🥖",
		Color3.fromRGB(215, 130, 40),
		Color3.fromRGB(250, 240, 225),
		Color3.fromRGB(205, 120, 35)
	)

	-- Dış Mekan Detayları: Kara Tahta Menü ve Ekmek Kasaları
	local halfW = 9.5 / 2
	local board = createPart(pav, "MenuBoard", Vector3.new(2.2, 3.2, 0.2), cf * CFrame.new(halfW + 1.2, -7.2/2 + 1.6, 3.4), Color3.fromRGB(35, 38, 42), Enum.Material.SmoothPlastic, true, true)
	local bGui = Instance.new("SurfaceGui")
	bGui.Face = Enum.NormalId.Front
	bGui.Parent = board
	local bLbl = Instance.new("TextLabel")
	bLbl.Size = UDim2.new(1, 0, 1, 0)
	bLbl.BackgroundTransparency = 1
	bLbl.Text = "🥖 TAŞ FIRIN\n• Sıcak Simit\n• Taze Ekmek\n• Kruvasan\n• Demlik Çay"
	bLbl.TextColor3 = Color3.fromRGB(255, 235, 180)
	bLbl.Font = Enum.Font.FredokaOne
	bLbl.TextScaled = true
	bLbl.Parent = bGui

	-- Ahşap Ekmek Kasası
	createPart(pav, "BreadCrate", Vector3.new(1.8, 1.2, 1.4), cf * CFrame.new(-halfW - 1.0, -7.2/2 + 0.6, 3.2), Color3.fromRGB(160, 105, 55), Enum.Material.Wood, true, true)

	return pav
end

-- B. Gross Market Pavyonu
function CommercialBuilder.buildMarketPavilion(parent: Instance, cf: CFrame): Model
	local ready = getReadyCommercialModel("Market")
	if ready then
		local m = instantiateReadyModel(ready, cf, 14.0)
		m.Name = "Shop_Market"
		m.Parent = parent
		return m
	end

	local pav = buildPavilionShell(
		parent, cf,
		"Market", "Gross Market", "🛒",
		Color3.fromRGB(45, 170, 75),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(45, 170, 75)
	)

	local halfW = 9.5 / 2
	-- Dış Mekan Meyve ve Sebze Kasaları
	createPart(pav, "FruitCrate1", Vector3.new(1.6, 1.2, 1.4), cf * CFrame.new(-halfW - 1.1, -7.2/2 + 0.6, 3.2), Color3.fromRGB(170, 110, 55), Enum.Material.Wood, true, true)
	createPart(pav, "FruitCrate2", Vector3.new(1.6, 1.2, 1.4), cf * CFrame.new(halfW + 1.1, -7.2/2 + 0.6, 3.2), Color3.fromRGB(170, 110, 55), Enum.Material.Wood, true, true)

	-- Kasalar içindeki taze meyve temsili
	createPart(pav, "Oranges", Vector3.new(1.4, 0.4, 1.2), cf * CFrame.new(-halfW - 1.1, -7.2/2 + 1.3, 3.2), Color3.fromRGB(245, 140, 30), Enum.Material.SmoothPlastic, true, false)
	createPart(pav, "Apples", Vector3.new(1.4, 0.4, 1.2), cf * CFrame.new(halfW + 1.1, -7.2/2 + 1.3, 3.2), Color3.fromRGB(225, 45, 45), Enum.Material.SmoothPlastic, true, false)

	return pav
end

-- C. VIP Berber & Güzellik Salonu Pavyonu
function CommercialBuilder.buildBarberPavilion(parent: Instance, cf: CFrame): Model
	local ready = getReadyCommercialModel("Barber")
	if ready then
		local m = instantiateReadyModel(ready, cf, 12.0)
		m.Name = "Shop_Barber"
		m.Parent = parent
		return m
	end

	local pav = buildPavilionShell(
		parent, cf,
		"Barber", "VIP Berber Salonu", "💈",
		Color3.fromRGB(35, 110, 200),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(35, 110, 200)
	)

	local halfW = 9.5 / 2
	-- Klasik Otantik Berber Silindiri (Tricolor Neon Pole)
	local poleCF = cf * CFrame.new(halfW + 0.8, 0.2, 3.2)
	createCylinder(pav, "BarberPole", Vector3.new(2.8, 0.8, 0.8), poleCF * CFrame.Angles(0, 0, math.pi/2), Color3.fromRGB(230, 40, 40), Enum.Material.Neon, true, true)
	createPart(pav, "PoleCapTop", Vector3.new(1.1, 0.3, 1.1), poleCF * CFrame.new(0, 1.5, 0), Color3.fromRGB(220, 220, 225), Enum.Material.Metal, true, true)
	createPart(pav, "PoleCapBot", Vector3.new(1.1, 0.3, 1.1), poleCF * CFrame.new(0, -1.5, 0), Color3.fromRGB(220, 220, 225), Enum.Material.Metal, true, true)

	return pav
end

-- D. Pati PetShop Pavyonu
function CommercialBuilder.buildPetShopPavilion(parent: Instance, cf: CFrame): Model
	local ready = getReadyCommercialModel("PetShop")
	if ready then
		local m = instantiateReadyModel(ready, cf, 12.0)
		m.Name = "Shop_PetShop"
		m.Parent = parent
		return m
	end

	local pav = buildPavilionShell(
		parent, cf,
		"PetShop", "Pati Pet Shop", "🐾",
		Color3.fromRGB(230, 95, 130),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(230, 95, 130)
	)

	local halfW = 9.5 / 2
	-- Dış Mekan Ahşap Köpek Kulübesi ve Mama Kapları
	createPart(pav, "DogHouse", Vector3.new(2.4, 2.0, 2.2), cf * CFrame.new(-halfW - 1.3, -7.2/2 + 1.0, 3.2), Color3.fromRGB(150, 95, 50), Enum.Material.WoodPlanks, true, true)
	createPart(pav, "DogRoof", Vector3.new(2.8, 0.6, 2.6), cf * CFrame.new(-halfW - 1.3, -7.2/2 + 2.2, 3.2), Color3.fromRGB(180, 50, 50), Enum.Material.Wood, true, true)
	createCylinder(pav, "FoodBowl", Vector3.new(0.3, 0.8, 0.8), cf * CFrame.new(-halfW - 1.3, -7.2/2 + 0.2, 4.6) * CFrame.Angles(0, 0, math.pi/2), Color3.fromRGB(50, 140, 220), Enum.Material.Metal, true, true)

	return pav
end

-- E. Açık Hava Kafe & Bistro Terası (Pavilion + Wooden Deck + 4 Cafe Tables + Umbrellas)
function CommercialBuilder.buildRestaurantPavilion(parent: Instance, cf: CFrame): Model
	local ready = getReadyCommercialModel("Restaurant")
	if ready then
		local m = instantiateReadyModel(ready, cf, 14.0)
		m.Name = "Shop_Restaurant"
		m.Parent = parent
		return m
	end

	local restModel = Instance.new("Model")
	restModel.Name = "Shop_Restaurant"

	-- 1. Yükseltilmiş Ahşap Teras Deck (14x16 stud)
	local deckW, deckD = 13.0, 15.0
	createPart(restModel, "CafeDeck", Vector3.new(deckW, 0.6, deckD), cf * CFrame.new(0, 0.3, 0), Color3.fromRGB(140, 90, 50), Enum.Material.WoodPlanks, true, true)
	createPart(restModel, "DeckBorder", Vector3.new(deckW + 0.4, 0.8, deckD + 0.4), cf * CFrame.new(0, 0.2, 0), Color3.fromRGB(60, 65, 70), Enum.Material.Concrete, true, true)

	-- 2. Arka Servis Kiosku / Espresso Barı
	local barCF = cf * CFrame.new(0, 3.8, -deckD/2 + 2.2)
	createPart(restModel, "BarCounter", Vector3.new(deckW - 1.5, 3.2, 3.6), barCF * CFrame.new(0, -1.8, 0), Color3.fromRGB(45, 48, 55), Enum.Material.Concrete, true, true)
	createPart(restModel, "BarTop", Vector3.new(deckW - 1.0, 0.4, 4.0), barCF * CFrame.new(0, -0.1, 0), Color3.fromRGB(230, 230, 235), Enum.Material.Slate, true, true)
	createPart(restModel, "BarBackWall", Vector3.new(deckW - 1.0, 7.0, 0.6), barCF * CFrame.new(0, 1.8, -1.8), Color3.fromRGB(38, 42, 48), Enum.Material.WoodPlanks, true, true)

	-- Kiosk Tente ve Tabela
	createPart(restModel, "BarAwning", Vector3.new(deckW - 0.8, 0.3, 3.5), barCF * CFrame.new(0, 5.0, 0.5) * CFrame.Angles(math.rad(18), 0, 0), Color3.fromRGB(175, 45, 45), Enum.Material.Fabric, true, true)
	local sign = createPart(restModel, "BarSign", Vector3.new(9.5, 1.4, 0.5), barCF * CFrame.new(0, 5.6, 0.4), Color3.fromRGB(175, 45, 45), Enum.Material.SmoothPlastic, true, true)
	local sGui = Instance.new("SurfaceGui")
	sGui.Face = Enum.NormalId.Front
	sGui.Parent = sign
	local sTxt = Instance.new("TextLabel")
	sTxt.Size = UDim2.new(1, 0, 1, 0)
	sTxt.BackgroundTransparency = 1
	sTxt.Text = "☕ GOURMET BISTRO & KAFE"
	sTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
	sTxt.Font = Enum.Font.FredokaOne
	sTxt.TextScaled = true
	sTxt.Parent = sGui

	-- 3. Dış Mekan 4 Takım Kafe Masası, Sandalyeleri ve Dev Şemsiyeler
	local tableOffsets = {
		Vector3.new(-3.6, 0.6, -1.5),
		Vector3.new(3.6, 0.6, -1.5),
		Vector3.new(-3.6, 0.6, 4.2),
		Vector3.new(3.6, 0.6, 4.2),
	}

	for i, off in ipairs(tableOffsets) do
		local tCF = cf * CFrame.new(off.X, off.Y, off.Z)
		-- Yuvarlak Ahşap Masa
		createCylinder(restModel, "CafeTable_"..i, Vector3.new(0.35, 2.6, 2.6), tCF * CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.pi/2), Color3.fromRGB(120, 75, 40), Enum.Material.WoodPlanks, true, true)
		createPart(restModel, "TablePole_"..i, Vector3.new(0.3, 1.5, 0.3), tCF * CFrame.new(0, 0.75, 0), Color3.fromRGB(40, 42, 46), Enum.Material.Metal, true, true)

		-- İkiz Demir Sandalyeler
		createPart(restModel, "ChairA_"..i, Vector3.new(1.1, 1.1, 1.1), tCF * CFrame.new(-1.6, 0.55, 0), Color3.fromRGB(50, 52, 58), Enum.Material.Metal, true, true)
		createPart(restModel, "ChairB_"..i, Vector3.new(1.1, 1.1, 1.1), tCF * CFrame.new(1.6, 0.55, 0), Color3.fromRGB(50, 52, 58), Enum.Material.Metal, true, true)

		-- Masada Kahve Fincanı Temsili
		createCylinder(restModel, "CoffeeCup_"..i, Vector3.new(0.3, 0.35, 0.35), tCF * CFrame.new(0.2, 1.8, 0) * CFrame.Angles(0, 0, math.pi/2), Color3.fromRGB(245, 240, 230), Enum.Material.SmoothPlastic, true, false)
	end

	-- 4. İkiz Dev Kırmızı Kafe Şemsiyeleri (Giant Parasols)
	for _, uz in ipairs({ -1.5, 4.2 }) do
		createPart(restModel, "UmbrellaPole", Vector3.new(0.4, 6.8, 0.4), cf * CFrame.new(0, 3.4, uz), Color3.fromRGB(220, 220, 225), Enum.Material.Metal, true, true)
		createPart(restModel, "UmbrellaCanopy", Vector3.new(6.8, 0.8, 6.8), cf * CFrame.new(0, 6.8, uz), Color3.fromRGB(180, 45, 45), Enum.Material.Fabric, true, false)
	end

	-- 5. Teras Kenarı Çiçeklik Korkuluklar
	createPart(restModel, "DeckPlanterL", Vector3.new(0.8, 1.2, deckD - 4), cf * CFrame.new(-deckW/2 + 0.4, 0.9, 0), Color3.fromRGB(225, 225, 230), Enum.Material.Concrete, true, true)
	createPart(restModel, "DeckPlanterR", Vector3.new(0.8, 1.2, deckD - 4), cf * CFrame.new(deckW/2 - 0.4, 0.9, 0), Color3.fromRGB(225, 225, 230), Enum.Material.Concrete, true, true)

	restModel.Parent = parent
	return restModel
end

-- ============================================================================
-- 3. PROMENADE GİRİŞ TAKI VE ANIT KİRA TABELASI (Monument Entrance Arch)
-- ============================================================================
function CommercialBuilder.buildEntranceSign(parent: Instance, cf: CFrame, totalRent: number): Model
	local signModel = Instance.new("Model")
	signModel.Name = "PromenadeEntranceGate"

	local gateW = 22.0

	-- İki Anıtsal Granit Taşıyıcı Sütun
	for _, px in ipairs({ -gateW/2 + 0.8, gateW/2 - 0.8 }) do
		createPart(signModel, "ArchPillar", Vector3.new(1.6, 9.0, 1.6), cf * CFrame.new(px, 4.5, 0), Color3.fromRGB(48, 52, 58), Enum.Material.Cobblestone, true, true)
		createPart(signModel, "PillarCap", Vector3.new(2.2, 0.6, 2.2), cf * CFrame.new(px, 9.2, 0), Color3.fromRGB(220, 185, 70), Enum.Material.Metal, true, true)
	end

	-- Üst Kiriş ve 3D Geniş Çarşı Tabelası
	local beam = createPart(signModel, "ArchBeam", Vector3.new(gateW, 2.6, 1.4), cf * CFrame.new(0, 8.2, 0), Color3.fromRGB(35, 38, 44), Enum.Material.Metal, true, true)
	local beamTrim = createPart(signModel, "BeamGoldTrim", Vector3.new(gateW + 0.4, 0.3, 1.6), cf * CFrame.new(0, 9.6, 0), Color3.fromRGB(220, 185, 70), Enum.Material.SmoothPlastic, true, true)

	-- Çift Taraflı SurfaceGui (Ön ve Arka Yüz)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local sGui = Instance.new("SurfaceGui")
		sGui.Face = face
		sGui.Parent = beam

		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 1, 0)
		container.BackgroundTransparency = 1
		container.Parent = sGui

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0.55, 0)
		title.Position = UDim2.new(0, 0, 0.05, 0)
		title.BackgroundTransparency = 1
		title.Text = "🛍️ MARMARA PROMENADE ÇARŞISI"
		title.TextColor3 = Color3.fromRGB(255, 220, 70)
		title.Font = Enum.Font.FredokaOne
		title.TextScaled = true
		title.Parent = container

		local rentLabel = Instance.new("TextLabel")
		rentLabel.Size = UDim2.new(1, 0, 0.35, 0)
		rentLabel.Position = UDim2.new(0, 0, 0.58, 0)
		rentLabel.BackgroundTransparency = 1
		rentLabel.Text = string.format("✨ Toplam Ticari Kira: +%s $/sn", NumberFormat.FormatCash(totalRent))
		rentLabel.TextColor3 = Color3.fromRGB(80, 240, 120)
		rentLabel.Font = Enum.Font.FredokaOne
		rentLabel.TextScaled = true
		rentLabel.Parent = container
	end

	-- Giriş Aydınlatma Spotları
	for _, sx in ipairs({ -6, 6 }) do
		local spot = createPart(signModel, "EntranceSpot", Vector3.new(1.0, 0.3, 1.0), cf * CFrame.new(sx, 7.0, 0), Color3.fromRGB(255, 240, 200), Enum.Material.Neon, true, false)
		local sLight = Instance.new("PointLight")
		sLight.Color = Color3.fromRGB(255, 235, 190)
		sLight.Brightness = 1.4
		sLight.Range = 22
		sLight.Parent = spot
	end

	signModel.Parent = parent
	return signModel
end

-- ============================================================================
-- 4. ANA PROMENADE MEYDANI İNŞA EDİCİ (Master Promenade Orchestrator)
-- ============================================================================
function CommercialBuilder.buildPromenade(
	parent: Instance,
	plotOrigin: Vector3,
	level: number,
	totalRent: number
): Model
	local promenadeModel = Instance.new("Model")
	promenadeModel.Name = "CommercialPromenade"

	local pX, pY, pZ = plotOrigin.X, plotOrigin.Y + 2.2, plotOrigin.Z

	-- 1. Geniş Cadde ve Meydan Zemin Platformu (26 x 68 stud Bazalt ve Parke Taş)
	local promCenterX = pX - 22
	local promCenterZ = pZ + 2

	-- Alt Beton Taban
	createPart(
		promenadeModel, "PromenadeBaseCurb",
		Vector3.new(27.4, 0.6, 69.4),
		CFrame.new(promCenterX, pY - 0.1, promCenterZ),
		Color3.fromRGB(60, 65, 72),
		Enum.Material.Concrete,
		true, true
	)

	-- Yürüme Caddesi Kaplaması (Zarif Bazalt / Granit Parke Taş)
	createPart(
		promenadeModel, "PromenadePavement",
		Vector3.new(26.0, 0.4, 68.0),
		CFrame.new(promCenterX, pY + 0.2, promCenterZ),
		Color3.fromRGB(115, 120, 125),
		Enum.Material.Cobblestone,
		true, true
	)

	-- Boyuna Çift Granit Vurgu Şeridi (Prestij Bulvar Hissiyatı)
	for _, bandX in ipairs({ promCenterX - 5.5, promCenterX + 5.5 }) do
		createPart(
			promenadeModel, "GraniteInlayBand",
			Vector3.new(0.8, 0.45, 68.0),
			CFrame.new(bandX, pY + 0.22, promCenterZ),
			Color3.fromRGB(55, 58, 65),
			Enum.Material.Slate,
			true, false
		)
	end

	-- 2. Güney Giriş Anıt Takı & Kira Gelir Panosu
	local entranceCF = CFrame.new(promCenterX, pY, pZ + 34)
	CommercialBuilder.buildEntranceSign(promenadeModel, entranceCF, totalRent)

	-- Giriş Çiçeklikleri (İki Yan)
	CommercialBuilder.buildPlanter(promenadeModel, CFrame.new(promCenterX - 11.2, pY + 0.2, pZ + 33))
	CommercialBuilder.buildPlanter(promenadeModel, CFrame.new(promCenterX + 11.2, pY + 0.2, pZ + 33))

	-- 3. Batı Aksı Müstakil Butik Pavyonları (Doğuya / Yürüme Yoluna Bakan Cepheler)
	local westX = pX - 29
	-- Seviye 4 & 5: Taş Fırın & Gross Market
	local bakeryCF = CFrame.new(westX, pY + 3.8, pZ - 18) * CFrame.Angles(0, math.rad(90), 0)
	CommercialBuilder.buildBakeryPavilion(promenadeModel, bakeryCF)

	local marketCF = CFrame.new(westX, pY + 3.8, pZ - 4) * CFrame.Angles(0, math.rad(90), 0)
	CommercialBuilder.buildMarketPavilion(promenadeModel, marketCF)

	-- Fırın ve Market Arası Çiçeklik ve Bank
	CommercialBuilder.buildBench(promenadeModel, CFrame.new(westX + 3.6, pY + 0.2, pZ - 11) * CFrame.Angles(0, math.rad(90), 0))
	CommercialBuilder.buildPlanter(promenadeModel, CFrame.new(westX, pY + 0.2, pZ - 11))

	-- Seviye 5 Prestij Pavyonları (Berber, PetShop, Restoran)
	if level >= 5 then
		local barberCF = CFrame.new(westX, pY + 3.8, pZ + 10) * CFrame.Angles(0, math.rad(90), 0)
		CommercialBuilder.buildBarberPavilion(promenadeModel, barberCF)

		local petCF = CFrame.new(westX, pY + 3.8, pZ + 24) * CFrame.Angles(0, math.rad(90), 0)
		CommercialBuilder.buildPetShopPavilion(promenadeModel, petCF)

		-- Berber ve PetShop Arası Dinlenme Alanı
		CommercialBuilder.buildBench(promenadeModel, CFrame.new(westX + 3.6, pY + 0.2, pZ + 17) * CFrame.Angles(0, math.rad(90), 0))
		CommercialBuilder.buildPlanter(promenadeModel, CFrame.new(westX, pY + 0.2, pZ + 17))

		-- Doğu Aksı: Açık Hava Kafe & Bistro Terası
		local eastX = pX - 14
		local restCF = CFrame.new(eastX, pY, pZ - 20)
		CommercialBuilder.buildRestaurantPavilion(promenadeModel, restCF)
	end

	-- 4. Merkezi Dekoratif Süs Havuzu ve Fıskiye
	local fountainX = pX - 14
	local fountainCF = CFrame.new(fountainX, pY, pZ - 4)
	CommercialBuilder.buildFountain(promenadeModel, fountainCF)

	-- Havuz Çevresi Oturma Bankları ve Çiçeklikler
	CommercialBuilder.buildBench(promenadeModel, CFrame.new(fountainX, pY + 0.2, pZ + 3.2))
	CommercialBuilder.buildPlanter(promenadeModel, CFrame.new(fountainX + 5.2, pY + 0.2, pZ - 4) * CFrame.Angles(0, math.rad(90), 0))

	-- 5. Gece Sokak Lambaları (Promenade Direkleri)
	local lampZPositions = { pZ - 26, pZ - 10, pZ + 6, pZ + 22 }
	for _, lz in ipairs(lampZPositions) do
		CommercialBuilder.buildPromenadeLamp(promenadeModel, CFrame.new(promCenterX + 1.2, pY + 0.2, lz))
	end

	-- 6. Paslanmaz Çelik Çöp Kovaları
	CommercialBuilder.buildTrashBin(promenadeModel, CFrame.new(promCenterX - 4.5, pY + 0.2, pZ - 13))
	CommercialBuilder.buildTrashBin(promenadeModel, CFrame.new(promCenterX + 4.5, pY + 0.2, pZ + 15))

	promenadeModel.Parent = parent
	return promenadeModel
end

-- Eski sistem uyumluluğu için storefront çağrısı (isteğe bağlı)
function CommercialBuilder.buildStorefront(
	parent: Instance,
	centerCF: CFrame,
	shopId: string,
	width: number,
	height: number
): Model?
	if shopId == "Bakery" then
		return CommercialBuilder.buildBakeryPavilion(parent, centerCF)
	elseif shopId == "Market" then
		return CommercialBuilder.buildMarketPavilion(parent, centerCF)
	elseif shopId == "Barber" then
		return CommercialBuilder.buildBarberPavilion(parent, centerCF)
	elseif shopId == "PetShop" then
		return CommercialBuilder.buildPetShopPavilion(parent, centerCF)
	elseif shopId == "Restaurant" then
		return CommercialBuilder.buildRestaurantPavilion(parent, centerCF)
	end
	return nil
end

return CommercialBuilder

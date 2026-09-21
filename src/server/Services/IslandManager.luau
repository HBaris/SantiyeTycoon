local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Network = require(ReplicatedStorage.Shared.Network)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)

local IslandManager = {}
-- [Player] = { [plotIndex] = plotData }
local playerPlots = {}

local PLOT_SPACING_X = 140 -- Şantiyeler arası X mesafesi
local PLOT_SPACING_Z = 120 -- Oyuncular arası Z mesafesi

-- Genel Parça Oluşturucu Yardımcı
local function createPart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, anchored: boolean, canCollide: boolean): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = anchored ~= false
	part.CanCollide = canCollide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function createCylinder(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, anchored: boolean, canCollide: boolean): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = anchored ~= false
	part.CanCollide = canCollide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- ============================================================================
-- 1. DEVASE ŞANTİYE VADİSİ, DOĞAL ADA VE OTOYOL PEYZAJI (ENVIRONMENT)
-- ============================================================================
function IslandManager.EnsureEnvironment()
	local existing = Workspace:FindFirstChild("TycoonEnvironment")
	if existing then return existing end

	-- Varsayılan küçük Baseplate varsa kaldır (araziyle çakışmayı ve parsel dışı boşluk hissini önle)
	local defaultBaseplate = Workspace:FindFirstChild("Baseplate")
	if defaultBaseplate and defaultBaseplate:IsA("BasePart") then
		defaultBaseplate:Destroy()
	end

	local envFolder = Instance.new("Folder")
	envFolder.Name = "TycoonEnvironment"
	envFolder.Parent = Workspace

	-- Ana Vadi / Ada Çim Zemin (1600 x 800 stud - Tüm şantiyeleri içine alır, boşluğu yok eder)
	createPart(
		envFolder, "MainIslandGround",
		Vector3.new(1600, 6, 800),
		CFrame.new(500, 1, 40),
		Color3.fromRGB(75, 145, 65),
		Enum.Material.Grass,
		true, true
	)

	-- Kıyı Doğal Kaya Falezleri (Arka ve Kenar Sınırlar)
	createPart(
		envFolder, "NorthCliff",
		Vector3.new(1620, 14, 20),
		CFrame.new(500, 5, -360),
		Color3.fromRGB(110, 115, 120),
		Enum.Material.Rock,
		true, true
	)
	createPart(
		envFolder, "SouthBeach",
		Vector3.new(1620, 4, 30),
		CFrame.new(500, 1.5, 435),
		Color3.fromRGB(220, 205, 160),
		Enum.Material.Sand,
		true, true
	)

	-- Ana Asfalt Şantiye Otoyolu (Şantiyelerin önünden boylu boyunca geçer)
	local roadCenterZ = 55
	createPart(
		envFolder, "MainHighway",
		Vector3.new(1500, 0.4, 26),
		CFrame.new(500, 4.2, roadCenterZ),
		Color3.fromRGB(45, 45, 50),
		Enum.Material.Asphalt,
		true, true
	)

	-- Otoyol Beyaz Kenar Çizgileri ve Orta Sarı Kesikli Çizgiler
	createPart(
		envFolder, "RoadCenterLine",
		Vector3.new(1500, 0.42, 0.8),
		CFrame.new(500, 4.22, roadCenterZ),
		Color3.fromRGB(240, 190, 30),
		Enum.Material.SmoothPlastic,
		true, false
	)
	createPart(
		envFolder, "RoadEdgeNorth",
		Vector3.new(1500, 0.42, 0.6),
		CFrame.new(500, 4.22, roadCenterZ - 12),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic,
		true, false
	)
	createPart(
		envFolder, "RoadEdgeSouth",
		Vector3.new(1500, 0.42, 0.6),
		CFrame.new(500, 4.22, roadCenterZ + 12),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic,
		true, false
	)

	-- Otoyol Kaldırımı (Kuzey Yaya Kaldırımı)
	createPart(
		envFolder, "HighwaySidewalk",
		Vector3.new(1500, 0.8, 6),
		CFrame.new(500, 4.4, roadCenterZ - 16),
		Color3.fromRGB(180, 180, 185),
		Enum.Material.Concrete,
		true, true
	)

	-- Yol Kenarı Sokak Lambaları ve Çevre Ağaçları
	for x = -60, 1100, 90 do
		-- Sokak Lambası
		local lampPost = createPart(
			envFolder, "StreetLamp_Post",
			Vector3.new(1, 14, 1),
			CFrame.new(x, 11, roadCenterZ - 17),
			Color3.fromRGB(80, 85, 90),
			Enum.Material.Metal,
			true, true
		)
		local lampArm = createPart(
			envFolder, "StreetLamp_Arm",
			Vector3.new(4, 0.8, 0.8),
			CFrame.new(x + 1.5, 17.5, roadCenterZ - 17),
			Color3.fromRGB(80, 85, 90),
			Enum.Material.Metal,
			true, false
		)
		local lampBulb = createPart(
			envFolder, "StreetLamp_Bulb",
			Vector3.new(1.6, 0.8, 1.6),
			CFrame.new(x + 3, 17, roadCenterZ - 17),
			Color3.fromRGB(255, 240, 180),
			Enum.Material.Neon,
			true, false
		)
		local pl = Instance.new("PointLight")
		pl.Color = Color3.fromRGB(255, 235, 180)
		pl.Brightness = 1.2
		pl.Range = 30
		pl.Parent = lampBulb

		-- Yol Kenarı Çam Ağacı
		local trunk = createPart(
			envFolder, "PineTrunk",
			Vector3.new(2.5, 10, 2.5),
			CFrame.new(x + 35, 9, roadCenterZ - 26),
			Color3.fromRGB(90, 60, 35),
			Enum.Material.Wood,
			true, true
		)
		createPart(
			envFolder, "PineLeaves1",
			Vector3.new(14, 7, 14),
			CFrame.new(x + 35, 16, roadCenterZ - 26),
			Color3.fromRGB(45, 95, 45),
			Enum.Material.Grass,
			true, false
		)
		createPart(
			envFolder, "PineLeaves2",
			Vector3.new(10, 6, 10),
			CFrame.new(x + 35, 21, roadCenterZ - 26),
			Color3.fromRGB(50, 110, 50),
			Enum.Material.Grass,
			true, false
		)
		createPart(
			envFolder, "PineLeavesTop",
			Vector3.new(6, 6, 6),
			CFrame.new(x + 35, 25, roadCenterZ - 26),
			Color3.fromRGB(55, 125, 55),
			Enum.Material.Grass,
			true, false
		)
	end

	return envFolder
end

-- ============================================================================
-- 2. GERÇEKÇİ VE DETAYLI 5 SEVİYE MİMARİ BİNA MODELLERİ
-- ============================================================================
local function buildBuildingModel(parent: Instance, origin: Vector3, level: number): Model
	local buildingModel = Instance.new("Model")
	buildingModel.Name = "BuildingModel"

	local bX, bY, bZ = origin.X, origin.Y + 2, origin.Z

	if level == 1 then
		-- --------------------------------------------------------------------
		-- SEVİYE 1: GERÇEKÇİ DAĞ KÜTÜK KULÜBESİ (Timber Cabin with Porch)
		-- --------------------------------------------------------------------
		-- 1. Beton Temel Kazıkları & Ahşap Taşıyıcı Şasi
		local footingOffsets = {
			Vector3.new(-8, -1.5, -7), Vector3.new(8, -1.5, -7),
			Vector3.new(-8, -1.5, 7), Vector3.new(8, -1.5, 7),
			Vector3.new(0, -1.5, -7), Vector3.new(0, -1.5, 7)
		}
		for i, off in ipairs(footingOffsets) do
			createPart(buildingModel, "Footing_"..i, Vector3.new(2, 3.5, 2), CFrame.new(bX + off.X, bY + off.Y, bZ + off.Z), Color3.fromRGB(130, 130, 135), Enum.Material.Concrete, true, true)
		end

		-- Alt Ahşap Kirişler ve Zemin Tabanı
		createPart(buildingModel, "SubFloor", Vector3.new(18, 0.8, 16), CFrame.new(bX, bY + 0.4, bZ), Color3.fromRGB(90, 55, 30), Enum.Material.WoodPlanks, true, true)

		-- 2. Ana Kütük Duvarlar (Sıcak Ahşap Doku)
		local walls = createPart(buildingModel, "MainWalls", Vector3.new(15, 9, 12), CFrame.new(bX, bY + 5, bZ - 1.5), Color3.fromRGB(150, 95, 50), Enum.Material.WoodPlanks, true, true)
		buildingModel.PrimaryPart = walls

		-- 4 Köşe Kalın Dikey Kütük Kolonlar
		for _, cx in ipairs({ -7.2, 7.2 }) do
			for _, cz in ipairs({ -7.2, 4.2 }) do
				createPart(buildingModel, "CornerPost", Vector3.new(1.6, 9.4, 1.6), CFrame.new(bX + cx, bY + 5, bZ + cz), Color3.fromRGB(95, 55, 25), Enum.Material.Wood, true, true)
			end
		end

		-- 3. Ön Ahşap Veranda (Porch) & Korkuluklar
		local porchDeck = createPart(buildingModel, "PorchDeck", Vector3.new(15, 0.6, 4.5), CFrame.new(bX, bY + 0.4, bZ + 6.5), Color3.fromRGB(135, 85, 45), Enum.Material.WoodPlanks, true, true)
		createPart(buildingModel, "PorchSteps", Vector3.new(6, 0.4, 2), CFrame.new(bX, bY + 0.1, bZ + 9.2), Color3.fromRGB(120, 75, 40), Enum.Material.WoodPlanks, true, true)

		-- Veranda Direkleri ve Çatı Sundurması
		for _, px in ipairs({ -6.8, 6.8 }) do
			createPart(buildingModel, "PorchPost", Vector3.new(1, 8.5, 1), CFrame.new(bX + px, bY + 4.5, bZ + 8.2), Color3.fromRGB(100, 60, 30), Enum.Material.Wood, true, true)
		end
		createPart(buildingModel, "PorchRoof", Vector3.new(17, 0.8, 5.5), CFrame.new(bX, bY + 9, bZ + 6.8), Color3.fromRGB(90, 50, 35), Enum.Material.Wood, true, true)

		-- 4. Geniş Saçaklı Beşik Ahşap Çatı
		createPart(buildingModel, "MainRoof", Vector3.new(18, 2.8, 14.5), CFrame.new(bX, bY + 10.5, bZ - 1.5), Color3.fromRGB(105, 55, 35), Enum.Material.Wood, true, true)
		createPart(buildingModel, "RoofRidge", Vector3.new(18.4, 0.8, 1.5), CFrame.new(bX, bY + 12.2, bZ - 1.5), Color3.fromRGB(75, 40, 25), Enum.Material.Wood, true, true)

		-- 5. Yan Cephe Taş Şömine Bacası
		createPart(buildingModel, "StoneChimney", Vector3.new(3, 14, 3), CFrame.new(bX + 8.2, bY + 7, bZ - 2), Color3.fromRGB(115, 115, 120), Enum.Material.Cobblestone, true, true)
		createPart(buildingModel, "ChimneyPot", Vector3.new(1.8, 1.5, 1.8), CFrame.new(bX + 8.2, bY + 14.6, bZ - 2), Color3.fromRGB(170, 75, 50), Enum.Material.ClayRoofTiles or Enum.Material.Brick, true, true)

		-- 6. Pencereler & Kapı
		createPart(buildingModel, "CabinDoor", Vector3.new(3.2, 6.5, 0.5), CFrame.new(bX, bY + 3.8, bZ + 4.5), Color3.fromRGB(80, 45, 20), Enum.Material.WoodPlanks, true, false)
		-- Kapı Feneri (Sıcak Fener)
		local lantern = createPart(buildingModel, "PorchLantern", Vector3.new(0.8, 1.2, 0.8), CFrame.new(bX + 2.5, bY + 6.2, bZ + 4.8), Color3.fromRGB(255, 200, 100), Enum.Material.Neon, true, false)
		local lLight = Instance.new("PointLight")
		lLight.Color = Color3.fromRGB(255, 220, 140)
		lLight.Brightness = 0.8
		lLight.Range = 14
		lLight.Parent = lantern

		-- Yan Pencereler (Cam + Ahşap Pervaz)
		for _, wx in ipairs({ -7.6, 7.6 }) do
			createPart(buildingModel, "SideWindow", Vector3.new(0.4, 3.8, 4.2), CFrame.new(bX + wx, bY + 5.2, bZ - 1.5), Color3.fromRGB(180, 225, 250), Enum.Material.Glass, true, false)
			createPart(buildingModel, "WindowFrame", Vector3.new(0.6, 4.2, 4.6), CFrame.new(bX + wx, bY + 5.2, bZ - 1.5), Color3.fromRGB(85, 50, 25), Enum.Material.Wood, true, false)
		end

	elseif level == 2 then
		-- --------------------------------------------------------------------
		-- SEVİYE 2: TAŞ VE TUĞLA İNGİLİZ MALİKANESİ (Classic Brick Manor)
		-- --------------------------------------------------------------------
		-- 1. Kesme Taş Temel Eteği (Stone Plinth)
		createPart(buildingModel, "StonePlinth", Vector3.new(21, 1.8, 19), CFrame.new(bX, bY + 0.9, bZ), Color3.fromRGB(120, 120, 125), Enum.Material.Cobblestone, true, true)

		-- 2. Kırmızı Harman Tuğla Duvarlar
		local walls = createPart(buildingModel, "BrickWalls", Vector3.new(20, 14, 18), CFrame.new(bX, bY + 8.5, bZ), Color3.fromRGB(165, 70, 55), Enum.Material.Brick, true, true)
		buildingModel.PrimaryPart = walls

		-- 3. Köşe Dekoratif Beyaz Taş Söveler (Quoins)
		for _, cx in ipairs({ -9.9, 9.9 }) do
			for _, cz in ipairs({ -8.9, 8.9 }) do
				createPart(buildingModel, "QuoinCol", Vector3.new(1.2, 14, 1.2), CFrame.new(bX + cx, bY + 8.5, bZ + cz), Color3.fromRGB(235, 230, 220), Enum.Material.Concrete, true, true)
			end
		end

		-- 4. Koyu Arduvaz Kiremit Beşik Çatı
		createPart(buildingModel, "SlateRoof", Vector3.new(22, 4.5, 20), CFrame.new(bX, bY + 17.5, bZ), Color3.fromRGB(65, 70, 80), Enum.Material.Slate, true, true)
		createPart(buildingModel, "RoofEaves", Vector3.new(22.6, 0.8, 20.6), CFrame.new(bX, bY + 15.6, bZ), Color3.fromRGB(240, 240, 245), Enum.Material.SmoothPlastic, true, true)

		-- Çatı Üçgen Dormer Pencereler
		createPart(buildingModel, "DormerWindow", Vector3.new(4, 3.5, 3), CFrame.new(bX, bY + 18, bZ + 8.5), Color3.fromRGB(165, 70, 55), Enum.Material.Brick, true, true)
		createPart(buildingModel, "DormerGlass", Vector3.new(2.8, 2.5, 0.4), CFrame.new(bX, bY + 18, bZ + 10.1), Color3.fromRGB(190, 230, 255), Enum.Material.Glass, true, false)

		-- 5. Klasik Giriş Revakı (Pillared Portico)
		createPart(buildingModel, "PorchBase", Vector3.new(7, 0.6, 4), CFrame.new(bX, bY + 2.1, bZ + 10.5), Color3.fromRGB(220, 220, 225), Enum.Material.Concrete, true, true)
		for _, sx in ipairs({ -2.8, 2.8 }) do
			createCylinder(buildingModel, "PorticoCol", Vector3.new(7.2, 1.2, 1.2), CFrame.new(bX + sx, bY + 5.8, bZ + 11.5) * CFrame.Angles(0, 0, math.pi/2), Color3.fromRGB(245, 245, 250), Enum.Material.Concrete, true, true)
		end
		createPart(buildingModel, "PorticoRoof", Vector3.new(7.8, 1.4, 4.5), CFrame.new(bX, bY + 9.8, bZ + 11), Color3.fromRGB(240, 240, 245), Enum.Material.SmoothPlastic, true, true)

		-- Giriş Kapısı
		createPart(buildingModel, "ManorDoor", Vector3.new(3.5, 6.5, 0.5), CFrame.new(bX, bY + 5.2, bZ + 9.1), Color3.fromRGB(45, 55, 70), Enum.Material.WoodPlanks, true, false)

		-- 6. Çift Kanatlı Panjurlu Pencereler (Zemin ve 1. Kat)
		for _, floorY in ipairs({ bY + 5.5, bY + 11.5 }) do
			for _, wx in ipairs({ -5.5, 5.5 }) do
				createPart(buildingModel, "ManorWindow", Vector3.new(3.2, 4.2, 0.4), CFrame.new(bX + wx, floorY, bZ + 9.1), Color3.fromRGB(190, 230, 255), Enum.Material.Glass, true, false)
				createPart(buildingModel, "WindowStoneSill", Vector3.new(3.8, 0.5, 0.8), CFrame.new(bX + wx, floorY - 2.3, bZ + 9.2), Color3.fromRGB(240, 235, 225), Enum.Material.Concrete, true, false)
				-- Panjurlar
				createPart(buildingModel, "ShutterL", Vector3.new(1.2, 4.2, 0.3), CFrame.new(bX + wx - 2.2, floorY, bZ + 9.15), Color3.fromRGB(40, 60, 50), Enum.Material.WoodPlanks, true, false)
				createPart(buildingModel, "ShutterR", Vector3.new(1.2, 4.2, 0.3), CFrame.new(bX + wx + 2.2, floorY, bZ + 9.15), Color3.fromRGB(40, 60, 50), Enum.Material.WoodPlanks, true, false)
			end
		end

		-- 7. İkiz Tuğla Bacalar
		for _, chX in ipairs({ -6, 6 }) do
			createPart(buildingModel, "BrickChimney", Vector3.new(2.8, 8, 2.8), CFrame.new(bX + chX, bY + 18.5, bZ - 3), Color3.fromRGB(165, 70, 55), Enum.Material.Brick, true, true)
			createPart(buildingModel, "ChimneyCap", Vector3.new(3.4, 0.8, 3.4), CFrame.new(bX + chX, bY + 22.8, bZ - 3), Color3.fromRGB(230, 225, 220), Enum.Material.Concrete, true, true)
		end

	elseif level == 3 then
		-- --------------------------------------------------------------------
		-- SEVİYE 3: ÇAĞDAŞ MİMARİ VİLLA (Modern Luxury Cantilever Villa)
		-- --------------------------------------------------------------------
		-- 1. Zemin Kat Tabanı & Yansıma Havuzu (Turkuaz Dekoratif Su Alanı)
		createPart(buildingModel, "VillaGroundDeck", Vector3.new(28, 1, 26), CFrame.new(bX, bY + 0.5, bZ), Color3.fromRGB(235, 235, 240), Enum.Material.Concrete, true, true)
		createPart(buildingModel, "ReflectingPool", Vector3.new(10, 0.4, 6), CFrame.new(bX - 8, bY + 0.9, bZ + 9), Color3.fromRGB(50, 190, 220), Enum.Material.Glass, true, false)

		-- 2. Zemin Kat Beyaz Beton Kütle
		local groundVol = createPart(buildingModel, "GroundVolume", Vector3.new(16, 9.5, 18), CFrame.new(bX + 4, bY + 5.2, bZ), Color3.fromRGB(245, 245, 250), Enum.Material.Concrete, true, true)
		buildingModel.PrimaryPart = groundVol

		-- Zemin Kat Taş Duvar Vurgusu (Arduvaz Doğal Taş)
		createPart(buildingModel, "AccentStoneWall", Vector3.new(8, 10, 14), CFrame.new(bX - 8, bY + 5.5, bZ - 2), Color3.fromRGB(70, 75, 80), Enum.Material.Slate, true, true)

		-- 3. Üst Kat Konsol Kütle (Tik Ağacı / Ahşap Lamel Kaplama)
		local upperVol = createPart(buildingModel, "UpperCantilever", Vector3.new(22, 9, 16), CFrame.new(bX - 2, bY + 14.5, bZ - 1), Color3.fromRGB(180, 115, 65), Enum.Material.WoodPlanks, true, true)

		-- 4. Üst Kat Konsol Teras & Cam Korkuluklar
		local terraceFloor = createPart(buildingModel, "UpperTerrace", Vector3.new(14, 0.8, 9), CFrame.new(bX + 5, bY + 10.4, bZ + 6.5), Color3.fromRGB(60, 60, 65), Enum.Material.Concrete, true, true)
		-- Cam Korkuluk (Füme Cam)
		createPart(buildingModel, "TerraceGlassFront", Vector3.new(14, 3.2, 0.4), CFrame.new(bX + 5, bY + 12.2, bZ + 10.8), Color3.fromRGB(160, 210, 230), Enum.Material.Glass, true, true)
		createPart(buildingModel, "TerraceGlassSide", Vector3.new(0.4, 3.2, 9), CFrame.new(bX + 11.8, bY + 12.2, bZ + 6.5), Color3.fromRGB(160, 210, 230), Enum.Material.Glass, true, true)

		-- 5. Panoramik Yerden Tavana Cam Cepheler (Siyah Alüminyum Çerçeveli)
		createPart(buildingModel, "GroundGlassFacade", Vector3.new(12, 8, 0.5), CFrame.new(bX + 3, bY + 5.2, bZ + 8.9), Color3.fromRGB(170, 225, 255), Enum.Material.Glass, true, false)
		createPart(buildingModel, "UpperGlassFacade", Vector3.new(16, 7.5, 0.5), CFrame.new(bX - 1, bY + 14.5, bZ + 6.9), Color3.fromRGB(170, 225, 255), Enum.Material.Glass, true, false)

		-- 6. Düz İnce Modern Çatı & Gömme Tavan Saçakları
		createPart(buildingModel, "FloatingFlatRoof", Vector3.new(25, 1.2, 19), CFrame.new(bX - 2, bY + 19.5, bZ - 1), Color3.fromRGB(50, 50, 55), Enum.Material.SmoothPlastic, true, true)

		-- 7. Modern Ahşap Kapı & Giriş Aydınlatması
		createPart(buildingModel, "VillaMainDoor", Vector3.new(4, 7.5, 0.6), CFrame.new(bX - 5.5, bY + 4.6, bZ + 5.1), Color3.fromRGB(40, 35, 30), Enum.Material.WoodPlanks, true, false)
		local entryLight = createPart(buildingModel, "EntrySpot", Vector3.new(1.2, 0.4, 1.2), CFrame.new(bX - 5.5, bY + 9.8, bZ + 6.5), Color3.fromRGB(255, 240, 180), Enum.Material.Neon, true, false)
		local spot = Instance.new("PointLight")
		spot.Color = Color3.fromRGB(255, 235, 180)
		spot.Brightness = 1.0
		spot.Range = 16
		spot.Parent = entryLight

	elseif level == 4 then
		-- --------------------------------------------------------------------
		-- SEVİYE 4: ÇOK KATLI ŞEHİR REZİDANS KULESİ (Mid-Rise Residence)
		-- --------------------------------------------------------------------
		local towerW, towerH, towerD = 24, 38, 22

		-- 1. Zemin Kat Lobi (Geniş Camlar, Kolonlar, Giriş Saçağı)
		local groundLobby = createPart(buildingModel, "LobbyStructure", Vector3.new(towerW + 2, 7, towerD + 2), CFrame.new(bX, bY + 3.5, bZ), Color3.fromRGB(230, 230, 235), Enum.Material.Concrete, true, true)
		buildingModel.PrimaryPart = groundLobby

		-- Lobi Ön Cephe Camı
		createPart(buildingModel, "LobbyGlass", Vector3.new(towerW - 2, 6, 0.5), CFrame.new(bX, bY + 3.5, bZ + (towerD / 2) + 1), Color3.fromRGB(160, 220, 255), Enum.Material.Glass, true, false)
		-- Giriş Çelik Saçağı (Canopy)
		createPart(buildingModel, "EntranceCanopy", Vector3.new(10, 0.8, 5), CFrame.new(bX, bY + 5.5, bZ + (towerD / 2) + 3.5), Color3.fromRGB(45, 50, 60), Enum.Material.Metal, true, true)
		createPart(buildingModel, "LobbyDoor", Vector3.new(4, 5, 0.6), CFrame.new(bX, bY + 2.8, bZ + (towerD / 2) + 1.1), Color3.fromRGB(40, 80, 120), Enum.Material.Glass, true, false)

		-- 2. Ana Kule Gövdesi (4 Katlı Konut Bloğu)
		createPart(buildingModel, "TowerBody", Vector3.new(towerW, towerH - 7, towerD), CFrame.new(bX, bY + 7 + ((towerH - 7) / 2), bZ), Color3.fromRGB(225, 220, 215), Enum.Material.Concrete, true, true)

		-- 3. Kat Silmeleri, Geniş Pencereler ve Özel Balkonlar
		local resFloors = 4
		local floorSpacing = (towerH - 8) / resFloors
		for f = 1, resFloors do
			local fY = bY + 7 + (f * floorSpacing) - (floorSpacing / 2)

			-- Kat Bölme Çizgisi
			createPart(buildingModel, "FloorSlab_"..f, Vector3.new(towerW + 1.5, 0.8, towerD + 1.5), CFrame.new(bX, fY - (floorSpacing/2) + 0.4, bZ), Color3.fromRGB(70, 75, 85), Enum.Material.Metal, true, true)

			-- Sol ve Sağ Bağımsız Balkonlar
			for _, bx in ipairs({ -6, 6 }) do
				-- Balkon Beton Döşemesi
				createPart(buildingModel, "BalconyDeck_"..f.."_"..bx, Vector3.new(8, 0.6, 4), CFrame.new(bX + bx, fY - 1.5, bZ + (towerD / 2) + 2), Color3.fromRGB(215, 215, 220), Enum.Material.Concrete, true, true)
				-- Balkon Cam & Çelik Korkuluğu
				createPart(buildingModel, "BalconyRailingFront", Vector3.new(8, 2.5, 0.4), CFrame.new(bX + bx, fY - 0.2, bZ + (towerD / 2) + 3.8), Color3.fromRGB(150, 210, 245), Enum.Material.Glass, true, true)
				createPart(buildingModel, "BalconyRailingSide", Vector3.new(0.4, 2.5, 3.8), CFrame.new(bX + bx + (bx > 0 and 3.8 or -3.8), fY - 0.2, bZ + (towerD / 2) + 2), Color3.fromRGB(150, 210, 245), Enum.Material.Glass, true, true)
				-- Daire Fransız Cam Kapısı
				createPart(buildingModel, "ApartmentWindow", Vector3.new(6, floorSpacing - 2, 0.4), CFrame.new(bX + bx, fY + 0.5, bZ + (towerD / 2) + 0.1), Color3.fromRGB(170, 220, 255), Enum.Material.Glass, true, false)
			end

			-- Yan Cephe Pencereleri
			for _, sideX in ipairs({ -(towerW/2) - 0.1, (towerW/2) + 0.1 }) do
				createPart(buildingModel, "SideAptWindow", Vector3.new(0.4, floorSpacing - 2.5, 6), CFrame.new(bX + sideX, fY + 0.5, bZ), Color3.fromRGB(170, 220, 255), Enum.Material.Glass, true, false)
			end
		end

		-- 4. Çatı Parapet Duvarı & Çatı Mekanik Ekipmanları
		local roofY = bY + towerH
		createPart(buildingModel, "RoofParapet", Vector3.new(towerW + 1, 2.5, towerD + 1), CFrame.new(bX, roofY + 1.2, bZ), Color3.fromRGB(70, 75, 85), Enum.Material.Metal, true, true)

		-- Asansör Kulesi / Makine Dairesi
		createPart(buildingModel, "ElevatorPenthouse", Vector3.new(8, 6, 8), CFrame.new(bX - 4, roofY + 3, bZ - 2), Color3.fromRGB(190, 190, 195), Enum.Material.Concrete, true, true)

		-- Havalandırma Santrali (HVAC Unit)
		createPart(buildingModel, "HVACUnit", Vector3.new(5, 3.5, 4), CFrame.new(bX + 5, roofY + 1.8, bZ - 3), Color3.fromRGB(130, 135, 140), Enum.Material.Metal, true, true)

		-- Çatı İletişim Anteni
		createPart(buildingModel, "RoofSpire", Vector3.new(0.8, 12, 0.8), CFrame.new(bX - 4, roofY + 11, bZ - 2), Color3.fromRGB(220, 220, 225), Enum.Material.Metal, true, false)

	elseif level >= 5 then
		-- --------------------------------------------------------------------
		-- SEVİYE 5: PRESTİJ GÖKDELEN & İŞ MERKEZİ (High-Tech Skyscraper)
		-- --------------------------------------------------------------------
		local baseW, baseH, baseD = 28, 68, 26

		-- 1. Görkemli 2 Katlı Cam Giriş Atriyumu & Destek Kolonları
		local lobbyHeight = 12
		local atriumLobby = createPart(buildingModel, "SkyscraperLobby", Vector3.new(baseW + 2, lobbyHeight, baseD + 2), CFrame.new(bX, bY + (lobbyHeight / 2), bZ), Color3.fromRGB(240, 240, 245), Enum.Material.Concrete, true, true)
		buildingModel.PrimaryPart = atriumLobby

		-- Lobi Ön Cam Duvar & Kolonlar
		createPart(buildingModel, "AtriumGlass", Vector3.new(baseW - 2, lobbyHeight - 2, 0.5), CFrame.new(bX, bY + (lobbyHeight / 2), bZ + (baseD / 2) + 1), Color3.fromRGB(140, 215, 255), Enum.Material.Glass, true, false)
		for _, cx in ipairs({ -10, -3.5, 3.5, 10 }) do
			createPart(buildingModel, "AtriumCol", Vector3.new(1.8, lobbyHeight, 1.8), CFrame.new(bX + cx, bY + (lobbyHeight / 2), bZ + (baseD / 2) + 1.4), Color3.fromRGB(80, 85, 95), Enum.Material.Metal, true, true)
		end

		-- 2. Kademeli Yükselen Gökdelen Kulesi (Reflektif Mavi Cam & Metal Profiller)
		-- Kademe 1: Alt Gövde
		local t1H = 26
		local t1Y = bY + lobbyHeight + (t1H / 2)
		createPart(buildingModel, "Tier1GlassCore", Vector3.new(baseW, t1H, baseD), CFrame.new(bX, t1Y, bZ), Color3.fromRGB(70, 140, 205), Enum.Material.Glass, true, true)

		-- Kademe 2: Orta Gövde (Zarifçe Daralan Setback)
		local t2W, t2H, t2D = baseW - 4, 22, baseD - 4
		local t2Y = bY + lobbyHeight + t1H + (t2H / 2)
		createPart(buildingModel, "Tier2GlassCore", Vector3.new(t2W, t2H, t2D), CFrame.new(bX, t2Y, bZ), Color3.fromRGB(60, 130, 200), Enum.Material.Glass, true, true)

		-- Kademe 3: Üst Taç Katları
		local t3W, t3H, t3D = t2W - 4, 16, t2D - 4
		local t3Y = bY + lobbyHeight + t1H + t2H + (t3H / 2)
		createPart(buildingModel, "Tier3GlassCore", Vector3.new(t3W, t3H, t3D), CFrame.new(bX, t3Y, bZ), Color3.fromRGB(50, 120, 190), Enum.Material.Glass, true, true)

		-- Dikey Alüminyum Güneş Kırıcı Profiller (Modern Mimari Hatlar)
		local totalHeight = lobbyHeight + t1H + t2H + t3H
		for _, fx in ipairs({ -(t3W/2), (t3W/2), -(t3W/4), (t3W/4) }) do
			createPart(buildingModel, "VerticalMullion", Vector3.new(0.6, totalHeight - lobbyHeight, 0.8), CFrame.new(bX + fx, bY + lobbyHeight + ((totalHeight - lobbyHeight)/2), bZ + (t3D/2) + 0.3), Color3.fromRGB(220, 225, 230), Enum.Material.Metal, true, false)
		end

		-- 3. Çatı Katı ve Tam Teşekküllü Helipad (Helikopter Pisti)
		local roofTopY = bY + totalHeight
		local heliPad = createPart(
			buildingModel, "SkyscraperHelipad",
			Vector3.new(t3W + 2, 2, t3D + 2),
			CFrame.new(bX, roofTopY + 1, bZ),
			Color3.fromRGB(55, 60, 65),
			Enum.Material.Concrete,
			true, true
		)

		-- Helipad Sarı Güvenlik Çerçevesi
		createPart(buildingModel, "HeliYellowBorder", Vector3.new(t3W + 2.2, 0.4, t3D + 2.2), CFrame.new(bX, roofTopY + 2.1, bZ), Color3.fromRGB(245, 200, 30), Enum.Material.SmoothPlastic, true, false)

		-- Helipad 'H' Harfi & Dairesi
		local heliSign = Instance.new("SurfaceGui")
		heliSign.Face = Enum.NormalId.Top
		heliSign.Parent = heliPad
		local hLabel = Instance.new("TextLabel")
		hLabel.Size = UDim2.new(1, 0, 1, 0)
		hLabel.BackgroundTransparency = 1
		hLabel.Text = "Ⓗ"
		hLabel.TextColor3 = Color3.fromRGB(255, 220, 40)
		hLabel.TextScaled = true
		hLabel.Font = Enum.Font.FredokaOne
		hLabel.Parent = heliSign

		-- Helipad 4 Köşe Gece İkaz Lambaları
		for _, hx in ipairs({ -(t3W/2), (t3W/2) }) do
			for _, hz in ipairs({ -(t3D/2), (t3D/2) }) do
				local beacon = createPart(buildingModel, "HeliBeacon", Vector3.new(0.8, 1.2, 0.8), CFrame.new(bX + hx, roofTopY + 2.5, bZ + hz), Color3.fromRGB(255, 60, 60), Enum.Material.Neon, true, false)
				local bLight = Instance.new("PointLight")
				bLight.Color = Color3.fromRGB(255, 50, 50)
				bLight.Brightness = 0.8
				bLight.Range = 15
				bLight.Parent = beacon
			end
		end

		-- Tepe Havacılık İkaz Kulesi (Aviation Spire)
		local spire = createPart(buildingModel, "AviationSpire", Vector3.new(1, 20, 1), CFrame.new(bX, roofTopY + 12, bZ), Color3.fromRGB(230, 235, 240), Enum.Material.Metal, true, false)
		local topLight = createPart(buildingModel, "SpireRedLight", Vector3.new(1.2, 1.2, 1.2), CFrame.new(bX, roofTopY + 22, bZ), Color3.fromRGB(255, 30, 30), Enum.Material.Neon, true, false)
		local sLight = Instance.new("PointLight")
		sLight.Color = Color3.fromRGB(255, 30, 30)
		sLight.Brightness = 2
		sLight.Range = 40
		sLight.Parent = topLight
	end

	buildingModel.Parent = parent
	return buildingModel
end

-- ============================================================================
-- 3. KULE VİNÇ OLUŞTURUCU (İnşaat Devam Ederken)
-- ============================================================================
local function buildTowerCrane(parent: Instance, craneOrigin: Vector3): (Model, Part)
	local craneModel = Instance.new("Model")
	craneModel.Name = "TowerCrane"

	-- Vinç Beton Tabanı
	createPart(
		craneModel, "CraneBase",
		Vector3.new(8, 2, 8),
		CFrame.new(craneOrigin + Vector3.new(0, 1, 0)),
		Color3.fromRGB(120, 120, 125),
		Enum.Material.Concrete,
		true, true
	)

	-- Kule Gövdesi (Sarı Çelik Kafes)
	local mastHeight = 46
	local mast = createPart(
		craneModel, "CraneMast",
		Vector3.new(3, mastHeight, 3),
		CFrame.new(craneOrigin + Vector3.new(0, 2 + (mastHeight / 2), 0)),
		Color3.fromRGB(245, 180, 0),
		Enum.Material.DiamondPlate,
		true, true
	)
	craneModel.PrimaryPart = mast

	-- Dönen Yatay Vinç Kolu (Jib / Boom)
	local jibPivotY = craneOrigin.Y + 2 + mastHeight + 1.5
	local jib = createPart(
		craneModel, "CraneJib",
		Vector3.new(38, 2, 2.5),
		CFrame.new(craneOrigin.X + 8, jibPivotY, craneOrigin.Z),
		Color3.fromRGB(245, 180, 0),
		Enum.Material.DiamondPlate,
		true, false
	)
	jib:SetAttribute("IsCraneJib", true)

	-- Karşı Ağırlık (Arka Denge Bloğu)
	createPart(
		craneModel, "CounterWeight",
		Vector3.new(7, 3.2, 3.2),
		CFrame.new(craneOrigin.X - 9, jibPivotY, craneOrigin.Z),
		Color3.fromRGB(60, 60, 65),
		Enum.Material.Concrete,
		true, true
	)

	-- Çelik Halat ve Kanca
	createPart(
		craneModel, "SteelCable",
		Vector3.new(0.3, 18, 0.3),
		CFrame.new(craneOrigin.X + 17, jibPivotY - 9, craneOrigin.Z),
		Color3.fromRGB(40, 40, 40),
		Enum.Material.Metal,
		true, false
	)
	createPart(
		craneModel, "Hook",
		Vector3.new(1.6, 1.6, 1.6),
		CFrame.new(craneOrigin.X + 17, jibPivotY - 18, craneOrigin.Z),
		Color3.fromRGB(220, 40, 40),
		Enum.Material.Metal,
		true, false
	)

	-- Tepe İkaz Lambası
	createPart(
		craneModel, "WarningBeacon",
		Vector3.new(1, 1.5, 1),
		CFrame.new(craneOrigin.X, jibPivotY + 3, craneOrigin.Z),
		Color3.fromRGB(255, 50, 50),
		Enum.Material.Neon,
		true, false
	)

	craneModel.Parent = parent
	return craneModel, jib
end

-- ============================================================================
-- 4. BİNA TAMAMLANDIĞINDA AÇILAN PRESTİJ MEYDANI (PLAZA PEYZAJI)
-- ============================================================================
local function buildPlazaModel(parent: Instance, plotOrigin: Vector3): Model
	local plazaModel = Instance.new("Model")
	plazaModel.Name = "SkyscraperPlaza"

	local pX, pZ = plotOrigin.X, plotOrigin.Z

	-- 1. Parlak Granit/Mermer Meydan Zemin Kaplaması (Vincin ve Şantiyenin Yerine)
	createPart(
		plazaModel, "PlazaPavement",
		Vector3.new(46, 0.4, 34),
		CFrame.new(pX - 6, 6.2, pZ + 12),
		Color3.fromRGB(235, 235, 240),
		Enum.Material.Concrete,
		true, true
	)

	-- Meydan Dekoratif Çiçeklik ve Palmiye Ağaçları
	local planterOffsets = { Vector3.new(-22, 1.2, 18), Vector3.new(-22, 1.2, 2) }
	for i, off in ipairs(planterOffsets) do
		createPart(plazaModel, "PlanterBox_"..i, Vector3.new(5, 2, 5), CFrame.new(pX + off.X, 6.2 + off.Y, pZ + off.Z), Color3.fromRGB(60, 65, 75), Enum.Material.Slate, true, true)
		createPart(plazaModel, "PlanterSoil_"..i, Vector3.new(4.4, 0.4, 4.4), CFrame.new(pX + off.X, 7.8, pZ + off.Z), Color3.fromRGB(90, 60, 40), Enum.Material.Ground, true, true)
		-- Palmiye / Süs Ağacı
		createPart(plazaModel, "TreeTrunk_"..i, Vector3.new(1.2, 8, 1.2), CFrame.new(pX + off.X, 12, pZ + off.Z), Color3.fromRGB(110, 80, 50), Enum.Material.Wood, true, true)
		createPart(plazaModel, "TreeCrown_"..i, Vector3.new(7, 5, 7), CFrame.new(pX + off.X, 16, pZ + off.Z), Color3.fromRGB(45, 130, 60), Enum.Material.Grass, true, false)
	end

	-- Meydan Oturma Bankları
	createPart(plazaModel, "PlazaBench", Vector3.new(8, 1.4, 2.5), CFrame.new(pX - 10, 7.1, pZ + 20), Color3.fromRGB(130, 85, 45), Enum.Material.WoodPlanks, true, true)

	-- Meydan LED Feneri
	local pLamp = createPart(plazaModel, "PlazaLamp", Vector3.new(0.8, 11, 0.8), CFrame.new(pX - 22, 11.5, pZ + 26), Color3.fromRGB(45, 50, 55), Enum.Material.Metal, true, true)
	local pBulb = createPart(plazaModel, "PlazaLampBulb", Vector3.new(2, 0.6, 2), CFrame.new(pX - 22, 17, pZ + 26), Color3.fromRGB(255, 245, 200), Enum.Material.Neon, true, false)
	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(255, 240, 200)
	pl.Brightness = 1.0
	pl.Range = 25
	pl.Parent = pBulb

	plazaModel.Parent = parent
	return plazaModel
end

-- ============================================================================
-- 4b. ÇALIŞAN İŞÇİ NPC'LERİ OLUŞTURUCU (Görsel Canlılık ve Atmosfer)
-- ============================================================================
local function spawnWorkerNPC(parent: Instance, name: string, role: string, cframe: CFrame): Model
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

	-- İsim Etiketi (BillboardGui - Siyah Yazılı Kart)
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
-- 5. TEK BİR ŞANTİYE PARSELİ OLUŞTURMA (GİDEREK UZAKLAŞAN MESAFE ÖLÇEĞİ)
-- ============================================================================
function IslandManager.GetPlotOrigin(plotIndex: number, playerIndex: number): Vector3
	local x = 0
	if plotIndex > 1 then
		for i = 2, plotIndex do
			x += 120 + (i * 35) -- 190, 225, 260... Taşıt kullanımını motive eden artan mesafe
		end
	end
	return Vector3.new(x, 4, (playerIndex - 1) * PLOT_SPACING_Z)
end

function IslandManager.CreatePlot(player: Player, playerIndex: number, plotIndex: number, buildingLevel: number, projectType: string?)
	-- Çevre arazisini ve otoyolu oluştur (ilk çağrıda hazır eder)
	IslandManager.EnsureEnvironment()

	if not playerPlots[player] then
		playerPlots[player] = {}
	end

	local plotOrigin = IslandManager.GetPlotOrigin(plotIndex, playerIndex)

	local plotFolder = Instance.new("Folder")
	plotFolder.Name = string.format("Plot_%s_%d", player.Name, plotIndex)
	plotFolder.Parent = Workspace

	-- 1. Şantiye Zemin Platformu (80 x 80 stud)
	createPart(
		plotFolder, "PlotGround",
		Vector3.new(80, 4, 80),
		CFrame.new(plotOrigin),
		Color3.fromRGB(145, 135, 120),
		Enum.Material.Ground,
		true, true
	)

	-- Beton Çevre Bordürleri
	createPart(
		plotFolder, "PlotCurb",
		Vector3.new(82, 0.8, 82),
		CFrame.new(plotOrigin + Vector3.new(0, 2.2, 0)),
		Color3.fromRGB(190, 190, 195),
		Enum.Material.Concrete,
		true, true
	)

	-- Parseli Ana Yola Bağlayan Parke Giriş Yolu
	createPart(
		plotFolder, "PlotEntranceRoad",
		Vector3.new(16, 0.4, 32),
		CFrame.new(plotOrigin + Vector3.new(0, 2.2, 36)),
		Color3.fromRGB(175, 175, 180),
		Enum.Material.Cobblestone,
		true, true
	)

	-- Giriş Tabelası
	local signPost = createPart(
		plotFolder, "SignPost",
		Vector3.new(1, 8, 1),
		CFrame.new(plotOrigin + Vector3.new(12, 5.5, 32)),
		Color3.fromRGB(80, 85, 90),
		Enum.Material.Metal,
		true, true
	)
	local signBoard = createPart(
		plotFolder, "SignBoard",
		Vector3.new(12, 4.5, 0.6),
		CFrame.new(plotOrigin + Vector3.new(12, 8.5, 32)),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic,
		true, true
	)
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = signBoard
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = string.format("🏗️ %s İnşaat A.Ş.\nProje #%d", player.DisplayName, plotIndex)
	signText.TextColor3 = Color3.fromRGB(20, 20, 20)
	signText.TextStrokeTransparency = 1
	signText.TextScaled = true
	signText.Font = Enum.Font.FredokaOne
	signText.Parent = signGui

	-- ESTETİK VE FERAH SPAWN NOKTASI (Giriş yolunda, binaya karşıdan bakar)
	if plotIndex == 1 then
		local spawnLocation = Instance.new("SpawnLocation")
		spawnLocation.Name = "PlotSpawn"
		spawnLocation.Size = Vector3.new(8, 0.6, 8)
		spawnLocation.CFrame = CFrame.lookAt(
			plotOrigin + Vector3.new(0, 2.5, 34),
			Vector3.new(plotOrigin.X, 2.5, plotOrigin.Z)
		)
		spawnLocation.Color = Color3.fromRGB(245, 190, 40)
		spawnLocation.Material = Enum.Material.Concrete
		spawnLocation.Anchored = true
		spawnLocation.CanCollide = true
		spawnLocation.Neutral = true
		spawnLocation.Duration = 0
		spawnLocation.Parent = plotFolder
	end

	-- 2. Kule Vinç (Bina Seviyesi < 5 İse Kurulur, Seviye 5 İse Kurulmaz)
	local craneOrigin = plotOrigin + Vector3.new(-22, 0, 12)
	local craneModel, craneJib
	if buildingLevel < 5 then
		craneModel, craneJib = buildTowerCrane(plotFolder, craneOrigin)
	end

	-- 3. Bina Modeli
	local buildingOrigin = plotOrigin + Vector3.new(4, 0, -4)
	local buildingModel = buildBuildingModel(plotFolder, buildingOrigin, buildingLevel)

	-- 4. Çekiç Vurma Hedef Alanı
	local hammerTarget = createPart(
		plotFolder, "HammerTarget",
		Vector3.new(32, 24, 32),
		CFrame.new(buildingOrigin + Vector3.new(0, 12, 0)),
		Color3.fromRGB(255, 255, 0),
		Enum.Material.ForceField,
		true, false
	)
	hammerTarget.Transparency = 1
	hammerTarget:SetAttribute("IsHammerTarget", true)
	hammerTarget:SetAttribute("OwnerUserId", player.UserId)
	hammerTarget:SetAttribute("PlotIndex", plotIndex)

	local buildingClickDetector = Instance.new("ClickDetector")
	buildingClickDetector.MaxActivationDistance = 45
	buildingClickDetector.CursorIcon = "rbxasset://textures/HammerCursor.png"
	-- 4b. Çalışan İşçi NPC'leri (Canlı Şantiye Atmosferi)
	spawnWorkerNPC(plotFolder, "Usta Ahmet", "Çekiç Ustası", CFrame.new(plotOrigin + Vector3.new(-8, 6.2, -6)))
	spawnWorkerNPC(plotFolder, "Mühendis Burak", "Şantiye Şefi (Plan)", CFrame.new(plotOrigin + Vector3.new(16, 6.2, 8)))
	spawnWorkerNPC(plotFolder, "Sevkiyatçı Can", "Lojistik & Kargo", CFrame.new(plotOrigin + Vector3.new(18, 6.2, 28)))

	-- 4c. Kargo Malzeme Teslimat Pad'i (Taşıtla yanaşıp 2.5x Turbo başlatma)
	local cargoPad = createPart(
		plotFolder, "CargoUnloadPad",
		Vector3.new(12, 0.6, 12),
		CFrame.new(plotOrigin + Vector3.new(20, 4.3, 34)),
		Color3.fromRGB(40, 180, 240),
		Enum.Material.SmoothPlastic,
		true, true
	)
	cargoPad:SetAttribute("IsCargoUnloadPad", true)
	cargoPad:SetAttribute("PlotIndex", plotIndex)

	local cPrompt = Instance.new("ProximityPrompt")
	cPrompt.ActionText = "Malzemeleri Boşalt"
	cPrompt.ObjectText = "⚡ 2.5x Turbo Başlat"
	cPrompt.HoldDuration = 0.3
	cPrompt.MaxActivationDistance = 22
	cPrompt.KeyboardKeyCode = Enum.KeyCode.E
	cPrompt.RequiresLineOfSight = false
	cPrompt.Parent = cargoPad

	cPrompt.Triggered:Connect(function(triggerPlayer)
		if triggerPlayer == player then
			Network.DeliverCargoEvent:FireServer(plotIndex)
		end
	end)

	local cGui = Instance.new("BillboardGui")
	cGui.Size = UDim2.new(9, 0, 3, 0)
	cGui.StudsOffset = Vector3.new(0, 4, 0)
	cGui.AlwaysOnTop = true
	cGui.Parent = cargoPad

	local cCard = Instance.new("Frame")
	cCard.Size = UDim2.new(1, 0, 1, 0)
	cCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	cCard.BackgroundTransparency = 0.05
	cCard.Parent = cGui

	local ccCorner = Instance.new("UICorner")
	ccCorner.CornerRadius = UDim.new(0, 10)
	ccCorner.Parent = cCard

	local cLabel = Instance.new("TextLabel")
	cLabel.Size = UDim2.new(0.92, 0, 0.88, 0)
	cLabel.Position = UDim2.new(0.04, 0, 0.06, 0)
	cLabel.BackgroundTransparency = 1
	cLabel.Text = "📦 MALZEME BOŞALTMA\n(Taşıtla Yanaş & E'ye Bas!)"
	cLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
	cLabel.Font = Enum.Font.FredokaOne
	cLabel.TextScaled = true
	cLabel.Parent = cCard

	-- 5. Şantiye Konteyneri / Ofis
	local officeCFrame = CFrame.new(plotOrigin + Vector3.new(25, 5, -18))
	local office = createPart(
		plotFolder, "SiteOffice",
		Vector3.new(12, 6, 8),
		officeCFrame,
		Color3.fromRGB(50, 95, 160),
		Enum.Material.CorrodedMetal,
		true, true
	)

	-- Ofis Üzeri Gelir Göstergesi (Siyah Yazılı Temiz Beyaz Kart)
	local rateGui = Instance.new("BillboardGui")
	rateGui.Name = "RateBillboard"
	rateGui.Size = UDim2.new(8, 0, 2.5, 0)
	rateGui.StudsOffset = Vector3.new(0, 5, 0)
	rateGui.AlwaysOnTop = false
	rateGui.Parent = office

	local rateCard = Instance.new("Frame")
	rateCard.Name = "RateCard"
	rateCard.Size = UDim2.new(1, 0, 1, 0)
	rateCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	rateCard.BackgroundTransparency = 0.05
	rateCard.BorderSizePixel = 0
	rateCard.Parent = rateGui

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 10)
	rCorner.Parent = rateCard

	local rStroke = Instance.new("UIStroke")
	rStroke.Color = Color3.fromRGB(230, 180, 20)
	rStroke.Thickness = 2.5
	rStroke.Parent = rateCard

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateText"
	rateLabel.Size = UDim2.new(0.92, 0, 0.88, 0)
	rateLabel.Position = UDim2.new(0.04, 0, 0.06, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = "+10 $/sn 🏗️"
	rateLabel.TextColor3 = Color3.fromRGB(20, 20, 20) -- SİYAH YAZI
	rateLabel.TextStrokeTransparency = 1
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.FredokaOne
	rateLabel.Parent = rateCard

	-- 6. İnşaat Seviye Yükseltme Butonu (Göz Kamaştırmayan Canlı Turuncu Kart)
	local upgradePad = createPart(
		plotFolder, "UpgradeBuildingPad",
		Vector3.new(14, 1.2, 10),
		CFrame.new(plotOrigin + Vector3.new(4, 2.6, 18)),
		Color3.fromRGB(255, 175, 40),
		Enum.Material.SmoothPlastic,
		true, true
	)
	upgradePad:SetAttribute("PadType", "BuildingUpgrade")
	upgradePad:SetAttribute("OwnerUserId", player.UserId)
	upgradePad:SetAttribute("PlotIndex", plotIndex)

	local padTopGui = Instance.new("SurfaceGui")
	padTopGui.Face = Enum.NormalId.Top
	padTopGui.Parent = upgradePad

	local padTopLabel = Instance.new("TextLabel")
	padTopLabel.Size = UDim2.new(1, 0, 1, 0)
	padTopLabel.BackgroundTransparency = 1
	padTopLabel.Text = "🔨 YÜKSELTME ALANI\n(TIKLA veya ÜSTÜNE BAS)"
	padTopLabel.TextColor3 = Color3.fromRGB(20, 20, 20) -- SİYAH YAZI
	padTopLabel.TextStrokeTransparency = 1
	padTopLabel.TextScaled = true
	padTopLabel.Font = Enum.Font.FredokaOne
	padTopLabel.Parent = padTopGui

	local padClickDetector = Instance.new("ClickDetector")
	padClickDetector.MaxActivationDistance = 48
	padClickDetector.Parent = upgradePad

	local padPrompt = Instance.new("ProximityPrompt")
	padPrompt.ActionText = "Yükselt"
	padPrompt.ObjectText = "İnşaat Seviyesi"
	padPrompt.HoldDuration = 0
	padPrompt.MaxActivationDistance = 24
	padPrompt.KeyboardKeyCode = Enum.KeyCode.E
	padPrompt.RequiresLineOfSight = false
	padPrompt.Parent = upgradePad

	local padGui = Instance.new("BillboardGui")
	padGui.Name = "PadBillboard"
	padGui.Size = UDim2.new(10, 0, 4, 0)
	padGui.StudsOffset = Vector3.new(0, 5, 0)
	padGui.AlwaysOnTop = true
	padGui.Parent = upgradePad

	local padCard = Instance.new("Frame")
	padCard.Name = "Card"
	padCard.Size = UDim2.new(1, 0, 1, 0)
	padCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	padCard.BackgroundTransparency = 0.05
	padCard.BorderSizePixel = 0
	padCard.Parent = padGui

	local padCardCorner = Instance.new("UICorner")
	padCardCorner.CornerRadius = UDim.new(0, 12)
	padCardCorner.Parent = padCard

	local padCardStroke = Instance.new("UIStroke")
	padCardStroke.Color = Color3.fromRGB(230, 150, 20)
	padCardStroke.Thickness = 3
	padCardStroke.Parent = padCard

	local padLabel = Instance.new("TextLabel")
	padLabel.Name = "InfoText"
	padLabel.Size = UDim2.new(0.92, 0, 0.88, 0)
	padLabel.Position = UDim2.new(0.04, 0, 0.06, 0)
	padLabel.BackgroundTransparency = 1
	padLabel.Text = "🔨 İNŞAAT SEVİYESİNİ YÜKSELT\n(Tıkla, Üstüne Bas veya E'ye bas!)"
	padLabel.TextColor3 = Color3.fromRGB(20, 20, 20) -- SİYAH YAZI
	padLabel.TextStrokeTransparency = 1
	padLabel.TextScaled = true
	padLabel.Font = Enum.Font.FredokaOne
	padLabel.Parent = padCard

	-- 7. Yeni Şantiye Açma Pad'i (Gökdelen Seviyesinde Açılır)
	local unlockPad = createPart(
		plotFolder, "UnlockNewPlotPad",
		Vector3.new(14, 1.2, 10),
		CFrame.new(plotOrigin + Vector3.new(-20, 2.6, 18)),
		Color3.fromRGB(50, 205, 100),
		Enum.Material.SmoothPlastic,
		true, true
	)
	unlockPad:SetAttribute("PadType", "UnlockPlot")
	unlockPad:SetAttribute("OwnerUserId", player.UserId)
	unlockPad:SetAttribute("PlotIndex", plotIndex)
	unlockPad.Transparency = 1
	unlockPad.CanCollide = false

	local unlockTopGui = Instance.new("SurfaceGui")
	unlockTopGui.Face = Enum.NormalId.Top
	unlockTopGui.Parent = unlockPad

	local unlockTopLabel = Instance.new("TextLabel")
	unlockTopLabel.Size = UDim2.new(1, 0, 1, 0)
	unlockTopLabel.BackgroundTransparency = 1
	unlockTopLabel.Text = "🏢 YENİ ŞANTİYE ALANI\n(TIKLA veya ÜSTÜNE BAS)"
	unlockTopLabel.TextColor3 = Color3.fromRGB(20, 20, 20) -- SİYAH YAZI
	unlockTopLabel.TextStrokeTransparency = 1
	unlockTopLabel.TextScaled = true
	unlockTopLabel.Font = Enum.Font.FredokaOne
	unlockTopLabel.Parent = unlockTopGui

	local unlockClickDetector = Instance.new("ClickDetector")
	unlockClickDetector.MaxActivationDistance = 48
	unlockClickDetector.Parent = unlockPad

	local unlockPrompt = Instance.new("ProximityPrompt")
	unlockPrompt.ActionText = "Yeni Şantiye Aç"
	unlockPrompt.ObjectText = "Portföyü Büyüt"
	unlockPrompt.HoldDuration = 0
	unlockPrompt.MaxActivationDistance = 24
	unlockPrompt.KeyboardKeyCode = Enum.KeyCode.E
	unlockPrompt.RequiresLineOfSight = false
	unlockPrompt.Enabled = false
	unlockPrompt.Parent = unlockPad

	local unlockGui = Instance.new("BillboardGui")
	unlockGui.Name = "UnlockBillboard"
	unlockGui.Size = UDim2.new(11, 0, 4.5, 0)
	unlockGui.StudsOffset = Vector3.new(0, 5, 0)
	unlockGui.AlwaysOnTop = true
	unlockGui.Enabled = false
	unlockGui.Parent = unlockPad

	local unlockCard = Instance.new("Frame")
	unlockCard.Name = "Card"
	unlockCard.Size = UDim2.new(1, 0, 1, 0)
	unlockCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	unlockCard.BackgroundTransparency = 0.05
	unlockCard.BorderSizePixel = 0
	unlockCard.Parent = unlockGui

	local unlockCardCorner = Instance.new("UICorner")
	unlockCardCorner.CornerRadius = UDim.new(0, 12)
	unlockCardCorner.Parent = unlockCard

	local unlockCardStroke = Instance.new("UIStroke")
	unlockCardStroke.Color = Color3.fromRGB(40, 180, 80)
	unlockCardStroke.Thickness = 3
	unlockCardStroke.Parent = unlockCard

	local unlockLabel = Instance.new("TextLabel")
	unlockLabel.Name = "UnlockText"
	unlockLabel.Size = UDim2.new(0.92, 0, 0.88, 0)
	unlockLabel.Position = UDim2.new(0.04, 0, 0.06, 0)
	unlockLabel.BackgroundTransparency = 1
	local nextPlotCost = GameConfig.GetPlotCost(plotIndex + 1)
	unlockLabel.Text = string.format("🏢 YENİ ŞANTİYE ALANI AÇ!\nFiyat: %s\n(Mevcut Gökdelen Portföyde Kalır)", NumberFormat.FormatCash(nextPlotCost))
	unlockLabel.TextColor3 = Color3.fromRGB(20, 20, 20) -- SİYAH YAZI
	unlockLabel.TextStrokeTransparency = 1
	unlockLabel.TextScaled = true
	unlockLabel.Font = Enum.Font.FredokaOne
	unlockLabel.Parent = unlockCard

	local plotData = {
		Folder = plotFolder,
		PlotIndex = plotIndex,
		BuildingModel = buildingModel,
		BuildingOrigin = buildingOrigin,
		CraneModel = craneModel,
		CraneJib = craneJib,
		CraneOrigin = craneOrigin,
		BuildingClickDetector = buildingClickDetector,
		RateLabel = rateLabel,
		UpgradePad = upgradePad,
		UpgradePadLabel = padLabel,
		UpgradePadClick = padClickDetector,
		UpgradePadPrompt = padPrompt,
		UnlockPad = unlockPad,
		UnlockPadLabel = unlockLabel,
		UnlockPadClick = unlockClickDetector,
		UnlockPadPrompt = unlockPrompt,
		UnlockGui = unlockGui,
		CargoPad = cargoPad,
		Origin = plotOrigin,
	}

	playerPlots[player][plotIndex] = plotData
	IslandManager.UpdateBuildingVisuals(player, plotIndex, buildingLevel)

	return plotData
end

function IslandManager.GetPlot(player: Player, plotIndex: number)
	if playerPlots[player] then
		return playerPlots[player][plotIndex]
	end
	return nil
end

function IslandManager.GetAllPlots(player: Player)
	return playerPlots[player] or {}
end

-- ============================================================================
-- 6. BİNA SEVİYESİ YÜKSELTİLDİĞİNDE GÖRSEL YENİLEME & VİNÇ SÖKÜM DÖNGÜSÜ
-- ============================================================================
function IslandManager.UpdateBuildingVisuals(player: Player, plotIndex: number, level: number)
	local plot = IslandManager.GetPlot(player, plotIndex)
	if not plot then return end

	-- Eski binayı kaldırıp yenisini dik
	if plot.BuildingModel then
		plot.BuildingModel:Destroy()
	end
	plot.BuildingModel = buildBuildingModel(plot.Folder, plot.BuildingOrigin, level)

	local nextLevel = level + 1
	local nextData = GameConfig.BUILDINGS[nextLevel]

	if nextData then
		-- İNŞAAT DEVAM EDİYOR (Seviye 1, 2, 3, 4)
		plot.UpgradePadLabel.Text = string.format("🔨 %s (Lv. %d)\nMaliyet: %d $", nextData.Name, nextLevel, nextData.Cost)
		plot.UpgradePadLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
		plot.UpgradePad.Color = Color3.fromRGB(255, 175, 40)
		plot.UpgradePad.Transparency = 0
		plot.UpgradePad.CanCollide = true

		-- Kule Vinç Yoksa Yeniden Kur (İnşaat sürecinde vinç çalışmalı)
		if not plot.CraneModel then
			local craneModel, craneJib = buildTowerCrane(plot.Folder, plot.CraneOrigin)
			plot.CraneModel = craneModel
			plot.CraneJib = craneJib
		end

		-- Plaza modeli varsa kaldır
		local oldPlaza = plot.Folder:FindFirstChild("SkyscraperPlaza")
		if oldPlaza then oldPlaza:Destroy() end

		-- Gökdelen henüz tamamlanmadı, yeni ada açma butonu kapalı
		plot.UnlockPad.Transparency = 1
		plot.UnlockPad.CanCollide = false
		plot.UnlockGui.Enabled = false
	else
		-- GÖKDELEN TAMAMLANDI (%100 PROJE)!
		-- 1. KULE VİNÇ SÖKÜLÜR VE KALDIRILIR! (İnşaat bitti, vinç gider!)
		if plot.CraneModel then
			plot.CraneModel:Destroy()
			plot.CraneModel = nil
			plot.CraneJib = nil
			print(string.format("[IslandManager] %s için %d. Proje tamamlandı! Kule vinç söküldü.", player.Name, plotIndex))
		end

		-- 2. Gökdelenin Çevresine Prestij Plaza Meydanı Eklenir
		local existingPlaza = plot.Folder:FindFirstChild("SkyscraperPlaza")
		if not existingPlaza then
			buildPlazaModel(plot.Folder, plot.Origin)
		end

		plot.UpgradePadLabel.Text = "✨ PROJE %100 TAMAMLANDI! ✨\n(Gökdelen Portföyde)"
		plot.UpgradePadLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
		plot.UpgradePad.Color = Color3.fromRGB(80, 220, 255)

		-- YENİ ŞANTİYE AÇMA BUTONUNU AKTİF ET
		plot.UnlockPad.Transparency = 0
		plot.UnlockPad.CanCollide = true
		plot.UnlockGui.Enabled = true
		if plot.UnlockPadPrompt then
			plot.UnlockPadPrompt.Enabled = true
		end
		print(string.format("[IslandManager] %s için %d. Proje %%100 tamamlandı! Yeni arsa açma butonu aktif.", player.Name, plotIndex))
	end
end

function IslandManager.RemoveAllPlots(player: Player)
	if playerPlots[player] then
		for _, plot in pairs(playerPlots[player]) do
			if plot.Folder then
				plot.Folder:Destroy()
			end
		end
		playerPlots[player] = nil
	end
end

return IslandManager

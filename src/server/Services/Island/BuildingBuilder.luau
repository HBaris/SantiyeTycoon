--!strict
-- ============================================================================
-- BuildingBuilder.luau
-- Gerçekçi ve Detaylı 5 Seviye Mimari Bina Modelleri
-- (1: Dağ Kulübesi, 2: Tuğla Malikâne, 3: Konsol Villa, 4: Rezidans Kulesi, 5: Prestij Gökdelen)
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlotDataTypes = require(script.Parent.PlotDataTypes)

local createPart = PlotDataTypes.createPart
local createCylinder = PlotDataTypes.createCylinder

local BuildingBuilder = {}

-- ReplicatedStorage.Assets.Buildings altındaki hazır modelleri arayan fonksiyon
local function getReadyModel(level: number): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then return nil end
	local buildings = assets:FindFirstChild("Buildings")
	if not buildings then return nil end
	local candidate = buildings:FindFirstChild("Level_" .. level)
	if candidate and candidate:IsA("Model") then
		return candidate
	end
	return nil
end

function BuildingBuilder.buildBuildingModel(parent: Instance, origin: Vector3, level: number): Model
	-- 1. Önce ReplicatedStorage.Assets.Buildings altında hazır model var mı kontrol et
	local readyTemplate = getReadyModel(level)
	if readyTemplate then
		local buildingModel = readyTemplate:Clone()
		buildingModel.Name = "BuildingModel"

		-- Tüm parçaları sabitle ve gereksiz betikleri temizle
		for _, desc in ipairs(buildingModel:GetDescendants()) do
			if desc:IsA("Script") or desc:IsA("LocalScript") then
				desc:Destroy()
			elseif desc:IsA("BasePart") then
				desc.Anchored = true
			end
		end

		-- Bounding box ve parsel alanına göre otomatik ölçekleme
		local _, size = buildingModel:GetBoundingBox()
		local maxAllowed = (level >= 5) and 34 or 28
		local maxHoriz = math.max(size.X, size.Z)
		if maxHoriz > maxAllowed then
			local scaleFactor = maxAllowed / maxHoriz
			buildingModel:ScaleTo(scaleFactor)
			_, size = buildingModel:GetBoundingBox()
		end

		-- Parsele tam zemin seviyesinde ve merkezde hizala
		local targetCF = CFrame.new(origin.X, origin.Y + 2 + (size.Y / 2), origin.Z)
		buildingModel:PivotTo(targetCF)

		if not buildingModel.PrimaryPart then
			buildingModel.PrimaryPart = buildingModel:FindFirstChildWhichIsA("BasePart", true)
		end

		buildingModel.Parent = parent
		return buildingModel
	end

	-- 2. Hazır model yoksa temiz prosedürel yedeği inşa et
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
		createPart(buildingModel, "ChimneyPot", Vector3.new(1.8, 1.5, 1.8), CFrame.new(bX + 8.2, bY + 14.6, bZ - 2), Color3.fromRGB(170, 75, 50), Enum.Material.Brick, true, true)

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
		-- (Ferah, Lüks ve Prestijli Rezidans Giriş Lobisi)
		-- --------------------------------------------------------------------
		local towerW, towerH, towerD = 24, 38, 22

		-- 1. Zemin Kat Lobi Kütlesi
		local groundLobby = createPart(buildingModel, "LobbyStructure", Vector3.new(towerW + 2, 7.5, towerD + 2), CFrame.new(bX, bY + 3.75, bZ), Color3.fromRGB(230, 230, 235), Enum.Material.Concrete, true, true)
		buildingModel.PrimaryPart = groundLobby

		-- Panoramik Yerden Tavana Cam Cephe (Zemin Kat Boyunca)
		createPart(buildingModel, "LobbyGlassFront", Vector3.new(towerW - 2, 6.2, 0.5), CFrame.new(bX, bY + 3.5, bZ + (towerD / 2) + 1.0), Color3.fromRGB(180, 225, 255), Enum.Material.Glass, true, false)

		-- Mimari Lobi Destek Sütunları
		createPart(buildingModel, "LobbyPillarL", Vector3.new(1.8, 7.5, 1.8), CFrame.new(bX - 6, bY + 3.75, bZ + (towerD / 2) + 1.2), Color3.fromRGB(50, 55, 65), Enum.Material.Concrete, true, true)
		createPart(buildingModel, "LobbyPillarR", Vector3.new(1.8, 7.5, 1.8), CFrame.new(bX + 6, bY + 3.75, bZ + (towerD / 2) + 1.2), Color3.fromRGB(50, 55, 65), Enum.Material.Concrete, true, true)

		-- Görkemli Çelik Giriş Saçağı (Canopy) & Vurgu Çerçevesi
		createPart(buildingModel, "GrandEntranceCanopy", Vector3.new(11, 0.8, 6.5), CFrame.new(bX, bY + 6.4, bZ + (towerD / 2) + 3.4), Color3.fromRGB(38, 42, 50), Enum.Material.Metal, true, true)
		local canopyFascia = createPart(buildingModel, "CanopyFascia", Vector3.new(11.2, 0.3, 0.4), CFrame.new(bX, bY + 6.4, bZ + (towerD / 2) + 6.6), Color3.fromRGB(220, 185, 90), Enum.Material.SmoothPlastic, true, true)
		local fGui = Instance.new("SurfaceGui")
		fGui.Face = Enum.NormalId.Front
		fGui.Parent = canopyFascia
		local fLbl = Instance.new("TextLabel")
		fLbl.Size = UDim2.new(1, 0, 1, 0)
		fLbl.BackgroundTransparency = 1
		fLbl.Text = "MARMARA RESIDENCE"
		fLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		fLbl.Font = Enum.Font.FredokaOne
		fLbl.TextScaled = true
		fLbl.Parent = fGui

		-- Giriş Saçağı Altı Sıcak LED Aydınlatması
		local canopySpot = createPart(buildingModel, "CanopySpot", Vector3.new(6, 0.2, 3), CFrame.new(bX, bY + 5.9, bZ + (towerD / 2) + 3.4), Color3.fromRGB(255, 240, 200), Enum.Material.Neon, true, false)
		local cLight = Instance.new("PointLight")
		cLight.Color = Color3.fromRGB(255, 235, 190)
		cLight.Brightness = 1.3
		cLight.Range = 18
		cLight.Parent = canopySpot

		-- Otomatik Çift Kanatlı Cam Kapı & Pirinç Kulplar
		createPart(buildingModel, "LobbyDoorFrame", Vector3.new(5.2, 5.4, 0.6), CFrame.new(bX, bY + 2.7, bZ + (towerD / 2) + 1.1), Color3.fromRGB(45, 50, 58), Enum.Material.Metal, true, true)
		createPart(buildingModel, "LobbyGlassDoor", Vector3.new(4.6, 5.0, 0.4), CFrame.new(bX, bY + 2.7, bZ + (towerD / 2) + 1.2), Color3.fromRGB(160, 215, 245), Enum.Material.Glass, true, false)
		createPart(buildingModel, "DoorHandleL", Vector3.new(0.2, 2.2, 0.3), CFrame.new(bX - 0.6, bY + 2.7, bZ + (towerD / 2) + 1.5), Color3.fromRGB(220, 190, 100), Enum.Material.Metal, true, false)
		createPart(buildingModel, "DoorHandleR", Vector3.new(0.2, 2.2, 0.3), CFrame.new(bX + 0.6, bY + 2.7, bZ + (towerD / 2) + 1.5), Color3.fromRGB(220, 190, 100), Enum.Material.Metal, true, false)

		-- İç Mekan Resepsiyon Masası ve Arka Duvarı (Camdan Görünen Şıklık)
		createPart(buildingModel, "ReceptionDesk", Vector3.new(5.5, 2.2, 1.8), CFrame.new(bX, bY + 1.1, bZ + (towerD / 2) - 3.5), Color3.fromRGB(50, 50, 55), Enum.Material.WoodPlanks, true, true)
		local recWall = createPart(buildingModel, "ReceptionBackdrop", Vector3.new(7, 4.5, 0.4), CFrame.new(bX, bY + 3.2, bZ + (towerD / 2) - 6.0), Color3.fromRGB(35, 40, 50), Enum.Material.SmoothPlastic, true, true)
		local rGui = Instance.new("SurfaceGui")
		rGui.Face = Enum.NormalId.Front
		rGui.Parent = recWall
		local rLbl = Instance.new("TextLabel")
		rLbl.Size = UDim2.new(1, 0, 1, 0)
		rLbl.BackgroundTransparency = 1
		rLbl.Text = "🏢 MARMARA RESIDENCE\nRESEPSİYON"
		rLbl.TextColor3 = Color3.fromRGB(230, 210, 150)
		rLbl.Font = Enum.Font.FredokaOne
		rLbl.TextScaled = true
		rLbl.Parent = rGui

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
		-- (14 Stud Yüksekliğinde Panoramik Cam Atriyum, Döner Kapı & Prestij Lobi)
		-- --------------------------------------------------------------------
		local baseW, baseH, baseD = 28, 68, 26

		-- 1. Görkemli 14-Stud Çift Kat Cam Giriş Atriyumu Kütlesi
		local lobbyHeight = 14
		local atriumLobby = createPart(buildingModel, "SkyscraperLobby", Vector3.new(baseW + 2, lobbyHeight, baseD + 2), CFrame.new(bX, bY + (lobbyHeight / 2), bZ), Color3.fromRGB(240, 240, 245), Enum.Material.Concrete, true, true)
		buildingModel.PrimaryPart = atriumLobby

		-- Ön Cephe Panoramik Perde Cam Duvarı (Full-Height Curtain Wall)
		createPart(buildingModel, "AtriumCurtainGlass", Vector3.new(baseW - 1.5, lobbyHeight - 1.2, 0.6), CFrame.new(bX, bY + (lobbyHeight / 2), bZ + (baseD / 2) + 1.1), Color3.fromRGB(160, 220, 255), Enum.Material.Glass, true, false)

		-- Yan Cephe Panoramik Cam Duvarları
		createPart(buildingModel, "AtriumSideGlassL", Vector3.new(0.6, lobbyHeight - 1.2, baseD - 4), CFrame.new(bX - (baseW/2) - 1.1, bY + (lobbyHeight / 2), bZ), Color3.fromRGB(160, 220, 255), Enum.Material.Glass, true, false)
		createPart(buildingModel, "AtriumSideGlassR", Vector3.new(0.6, lobbyHeight - 1.2, baseD - 4), CFrame.new(bX + (baseW/2) + 1.1, bY + (lobbyHeight / 2), bZ), Color3.fromRGB(160, 220, 255), Enum.Material.Glass, true, false)

		-- 4 Adet Anıtsal Titanyum Taşıyıcı Portal Kolon
		for _, cx in ipairs({ -9.5, -3.8, 3.8, 9.5 }) do
			createPart(buildingModel, "AtriumCol_"..cx, Vector3.new(1.6, lobbyHeight, 1.6), CFrame.new(bX + cx, bY + (lobbyHeight / 2), bZ + (baseD / 2) + 1.5), Color3.fromRGB(60, 65, 75), Enum.Material.Metal, true, true)
		end

		-- Görkemli Konsol Atriyum Saçağı (Canopy) & Vurgu Çerçevesi
		createPart(buildingModel, "GrandAtriumCanopy", Vector3.new(14, 1.0, 7.5), CFrame.new(bX, bY + 8.5, bZ + (baseD / 2) + 4.2), Color3.fromRGB(30, 35, 42), Enum.Material.Metal, true, true)
		local canopyGoldEdge = createPart(buildingModel, "CanopyGoldEdge", Vector3.new(14.2, 0.3, 0.4), CFrame.new(bX, bY + 8.5, bZ + (baseD / 2) + 8.0), Color3.fromRGB(220, 185, 70), Enum.Material.SmoothPlastic, true, true)
		local aGui = Instance.new("SurfaceGui")
		aGui.Face = Enum.NormalId.Front
		aGui.Parent = canopyGoldEdge
		local aLbl = Instance.new("TextLabel")
		aLbl.Size = UDim2.new(1, 0, 1, 0)
		aLbl.BackgroundTransparency = 1
		aLbl.Text = "💎 MARMARA PRESTIGE CENTER"
		aLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		aLbl.Font = Enum.Font.FredokaOne
		aLbl.TextScaled = true
		aLbl.Parent = aGui

		-- Saçak Altı Sıcak Aydınlatma Spotu
		local aSpot = createPart(buildingModel, "AtriumCanopyLight", Vector3.new(8, 0.2, 4), CFrame.new(bX, bY + 7.9, bZ + (baseD / 2) + 4.2), Color3.fromRGB(255, 245, 210), Enum.Material.Neon, true, false)
		local asLight = Instance.new("PointLight")
		asLight.Color = Color3.fromRGB(255, 240, 205)
		asLight.Brightness = 1.5
		asLight.Range = 22
		asLight.Parent = aSpot

		-- Mimari Döner Kapı (Revolving Door with Glass Cylinder & Chrome Wings)
		createCylinder(buildingModel, "RevolvingDrum", Vector3.new(5.6, 5.2, 5.2), CFrame.new(bX, bY + 2.8, bZ + (baseD / 2) + 1.4) * CFrame.Angles(0, 0, math.pi/2), Color3.fromRGB(160, 220, 250), Enum.Material.Glass, true, false)
		createPart(buildingModel, "RevolvingAxis", Vector3.new(0.4, 5.6, 0.4), CFrame.new(bX, bY + 2.8, bZ + (baseD / 2) + 1.4), Color3.fromRGB(210, 215, 220), Enum.Material.Metal, true, false)
		createPart(buildingModel, "RevolvingWingA", Vector3.new(4.8, 5.2, 0.15), CFrame.new(bX, bY + 2.8, bZ + (baseD / 2) + 1.4), Color3.fromRGB(180, 230, 255), Enum.Material.Glass, true, false)
		createPart(buildingModel, "RevolvingWingB", Vector3.new(0.15, 5.2, 4.8), CFrame.new(bX, bY + 2.8, bZ + (baseD / 2) + 1.4), Color3.fromRGB(180, 230, 255), Enum.Material.Glass, true, false)

		-- İç Mekan Prestij Resepsiyon Masası ve Arka Duvarı
		createPart(buildingModel, "ExecReceptionDesk", Vector3.new(8, 2.4, 2.2), CFrame.new(bX, bY + 1.2, bZ + (baseD / 2) - 4.5), Color3.fromRGB(35, 40, 48), Enum.Material.WoodPlanks, true, true)
		local execWall = createPart(buildingModel, "ExecReceptionWall", Vector3.new(10, 6, 0.4), CFrame.new(bX, bY + 3.8, bZ + (baseD / 2) - 7.5), Color3.fromRGB(25, 30, 38), Enum.Material.SmoothPlastic, true, true)
		local eGui = Instance.new("SurfaceGui")
		eGui.Face = Enum.NormalId.Front
		eGui.Parent = execWall
		local eLbl = Instance.new("TextLabel")
		eLbl.Size = UDim2.new(1, 0, 1, 0)
		eLbl.BackgroundTransparency = 1
		eLbl.Text = "💎 MARMARA HOLDING\nEXECUTIVE PLAZA"
		eLbl.TextColor3 = Color3.fromRGB(240, 220, 160)
		eLbl.Font = Enum.Font.FredokaOne
		eLbl.TextScaled = true
		eLbl.Parent = eGui

		-- Atriyum İçi Asılı Modern Geometrik Avize
		local chandelier = createPart(buildingModel, "AtriumChandelier", Vector3.new(5, 0.8, 5), CFrame.new(bX, bY + 11.5, bZ + (baseD / 2) - 2), Color3.fromRGB(255, 245, 210), Enum.Material.Neon, true, false)
		local chLight = Instance.new("PointLight")
		chLight.Color = Color3.fromRGB(255, 240, 200)
		chLight.Brightness = 1.4
		chLight.Range = 26
		chLight.Parent = chandelier

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

return BuildingBuilder

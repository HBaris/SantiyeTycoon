--!strict
-- ============================================================================
-- SiteEquipmentBuilder.luau
-- Şantiye Ekipmanları, Kule Vinç, Şantiye Konteyner Ofisi ve Prestij Meydanı (Plaza)
-- ============================================================================

local PlotDataTypes = require(script.Parent.PlotDataTypes)

local createPart = PlotDataTypes.createPart
local createCylinder = PlotDataTypes.createCylinder

local SiteEquipmentBuilder = {}

-- ============================================================================
-- 1. KULE VİNÇ OLUŞTURUCU (İnşaat Devam Ederken)
-- ============================================================================
function SiteEquipmentBuilder.buildTowerCrane(parent: Instance, craneOrigin: Vector3): (Model, Part)
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
-- 2. BİNA TAMAMLANDIĞINDA AÇILAN PRESTİJ MEYDANI (PLAZA PEYZAJI)
-- ============================================================================
function SiteEquipmentBuilder.buildPlazaModel(parent: Instance, plotOrigin: Vector3): Model
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
-- 3. ŞANTİYE KONTEYNER OFİSİ VE GELİR BİLLBOARDU
-- ============================================================================
function SiteEquipmentBuilder.buildSiteOffice(parent: Instance, plotOrigin: Vector3): (Part, TextLabel)
	local officeCFrame = CFrame.new(plotOrigin + Vector3.new(25, 5, -18))
	local office = createPart(
		parent, "SiteOffice",
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
	rateLabel.Text = "+10 İP/sn 🏗️"
	rateLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
	rateLabel.TextStrokeTransparency = 1
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.FredokaOne
	rateLabel.Parent = rateCard

	return office, rateLabel
end

return SiteEquipmentBuilder

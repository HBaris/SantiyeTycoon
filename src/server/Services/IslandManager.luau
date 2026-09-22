--!strict
-- ============================================================================
-- IslandManager.luau
-- Şantiye ve Parsel Yönetimi Ana Orkestratörü (Facade)
--
-- Alt Modüller:
--   - Island.PlotDataTypes       : Geometrik parça üreticileri ve veri tipleri
--   - Island.IslandEnvironment   : Ada arazisi, vadi tabanı ve ana otoyol
--   - Island.BuildingBuilder     : Seviye 1-5 mimari bina modelleri
--   - Island.CommercialBuilder   : Zemin kat otomatik ticari dükkanlar & vitrinler
--   - Island.SiteEquipmentBuilder: Kule vinç, plaza ve şantiye ofisi
--   - Island.CityLifeService     : Yayalar, işçi NPC'leri ve sokak mobilyaları
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Network = require(ReplicatedStorage.Shared.Network)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local ZoneConfig = require(ReplicatedStorage.Shared.ZoneConfig)
local ProjectTypeConfig = require(ReplicatedStorage.Shared.ProjectTypeConfig)
local GarageService = require(script.Parent.GarageService)
local DataService = require(script.Parent.DataService)
local ServiceBuildingManager = require(script.Parent.ServiceBuildingManager)

-- Alt Servis ve Builder Modülleri
local Island = script.Parent.Island
local PlotDataTypes = require(Island.PlotDataTypes)
local IslandEnvironment = require(Island.IslandEnvironment)
local BuildingBuilder = require(Island.BuildingBuilder)
local CommercialBuilder = require(Island.CommercialBuilder)
local SiteEquipmentBuilder = require(Island.SiteEquipmentBuilder)
local CityLifeService = require(Island.CityLifeService)
local ParcelLandscape = require(Island.ParcelLandscape)
local ShowroomPaletteBuilder = require(Island.ShowroomPaletteBuilder)

type PlotData = PlotDataTypes.PlotData
local createPart = PlotDataTypes.createPart
local PLOT_SPACING_Z = PlotDataTypes.PLOT_SPACING_Z

local IslandManager = {}
-- [Player / UserId] = { [plotIndex] = plotData }
local playerPlots: { [any]: { [number]: PlotData } } = _G.PlayerPlots or {}
_G.PlayerPlots = playerPlots

-- ============================================================================
-- 1. ÇEVRE VE ARAZİ ORKESTRASYONU
-- ============================================================================
function IslandManager.EnsureEnvironment(): Folder
	return IslandEnvironment.EnsureEnvironment()
end

-- ============================================================================
-- 2. PARSEL KONUM HESAPLAYICI (Artan Mesafe ve Taşıt Kullanım Teşviki)
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

-- ============================================================================
-- 3. TEK BİR ŞANTİYE PARSELİ OLUŞTURMA
-- ============================================================================
function IslandManager.CreatePlot(
	player: Player,
	playerIndex: number,
	plotIndex: number,
	buildingLevel: number,
	projectType: string?
): PlotData
	IslandManager.EnsureEnvironment()

	if not playerPlots[player] then
		playerPlots[player] = {}
	end

	local plotOrigin = IslandManager.GetPlotOrigin(plotIndex, playerIndex)

	local plotFolder = Instance.new("Folder")
	plotFolder.Name = string.format("Plot_%s_%d", player.Name, plotIndex)
	plotFolder.Parent = Workspace

	-- 1. Şantiye Zemin Platformu (80 x 80 stud) ve Bordürler
	createPart(plotFolder, "PlotGround", Vector3.new(80, 4, 80), CFrame.new(plotOrigin), Color3.fromRGB(145, 135, 120), Enum.Material.Ground, true, true)
	createPart(plotFolder, "PlotCurb", Vector3.new(82, 0.8, 82), CFrame.new(plotOrigin + Vector3.new(0, 2.2, 0)), Color3.fromRGB(190, 190, 195), Enum.Material.Concrete, true, true)
	-- Şantiye Düz Giriş Yolu ve Otoyol Bağlantı Rampası (Kasis ve basamak olmadan scooter ile akıcı tırmanış)
	createPart(plotFolder, "PlotEntranceRoad", Vector3.new(16, 0.4, 18), CFrame.new(plotOrigin + Vector3.new(0, 2.2, 29)), Color3.fromRGB(175, 175, 180), Enum.Material.Cobblestone, true, true)
	local ramp = Instance.new("WedgePart")
	ramp.Name = "PlotEntranceRamp"
	ramp.Size = Vector3.new(16, 2.0, 10)
	ramp.CFrame = CFrame.new(plotOrigin.X, 5.2, plotOrigin.Z + 43) * CFrame.Angles(0, math.pi, 0)
	ramp.Color = Color3.fromRGB(175, 175, 180)
	ramp.Material = Enum.Material.Cobblestone
	ramp.Anchored = true
	ramp.CanCollide = true
	ramp.Parent = plotFolder

	-- Giriş Şirket Tabelası (Parsel dışı: Yol ve kaldırım kenarında, parsel zeminini işgal etmez)
	local signPost = createPart(plotFolder, "SignPost", Vector3.new(1, 8, 1), CFrame.new(plotOrigin + Vector3.new(14, 5.5, 46)), Color3.fromRGB(80, 85, 90), Enum.Material.Metal, true, true)
	local signBoard = createPart(plotFolder, "SignBoard", Vector3.new(12, 4.5, 0.6), CFrame.new(plotOrigin + Vector3.new(14, 8.5, 46)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, true, true)
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = signBoard
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = string.format("🏗️ %s İnşaat A.Ş.\nProje #%d", player.DisplayName, plotIndex)
	signText.TextColor3 = Color3.fromRGB(20, 20, 20)
	signText.TextScaled = true
	signText.Font = Enum.Font.FredokaOne
	signText.Parent = signGui

	-- Spawn Noktası (Parsel dışındaki kaldırım alanında)
	if plotIndex == 1 then
		local spawnLocation = Instance.new("SpawnLocation")
		spawnLocation.Name = "PlotSpawn"
		spawnLocation.Size = Vector3.new(8, 0.6, 8)
		spawnLocation.CFrame = CFrame.lookAt(plotOrigin + Vector3.new(-12, 2.5, 46), Vector3.new(plotOrigin.X, 2.5, plotOrigin.Z))
		spawnLocation.Color = Color3.fromRGB(245, 190, 40)
		spawnLocation.Material = Enum.Material.Concrete
		spawnLocation.Anchored = true
		spawnLocation.CanCollide = true
		spawnLocation.Neutral = true
		spawnLocation.Duration = 0
		spawnLocation.Parent = plotFolder
	end

	-- 2. Kenar Varlık Sergisi & Showroom Platformu (Asset Staging Palette)
	-- Tüm Seviye 1-10 Binaları, Dükkanlar ve Ekipmanlar parselin sol kenarına dizilir.
	ShowroomPaletteBuilder.build(plotFolder, plotOrigin)

	-- 3. Temiz & Boş Parsel: Varsayılan binalar veya işçiler parsel zeminini işgal etmez.
	local craneOrigin = plotOrigin + Vector3.new(-22, 0, 12)
	local craneModel = nil
	local craneJib = nil
	local buildingOrigin = plotOrigin + Vector3.new(0, 0, 0)
	local buildingModel = nil

	-- Çekiç Vurma Hedef Alanı (Görünmez, etkisiz)
	local hammerTarget = createPart(plotFolder, "HammerTarget", Vector3.new(2, 2, 2), CFrame.new(plotOrigin + Vector3.new(0, -10, 0)), Color3.fromRGB(255, 255, 0), Enum.Material.ForceField, true, false)
	hammerTarget.Transparency = 1
	local buildingClickDetector = Instance.new("ClickDetector")
	buildingClickDetector.MaxActivationDistance = 0
	buildingClickDetector.Parent = hammerTarget

	-- 4. Kargo Malzeme Pad'i (Parsel dışı: Yol bağlantısı kenarında)
	local cargoPad = createPart(plotFolder, "CargoUnloadPad", Vector3.new(12, 0.1, 8), CFrame.new(plotOrigin + Vector3.new(24, 2.05, 46)), Color3.fromRGB(40, 180, 240), Enum.Material.SmoothPlastic, true, false)
	cargoPad:SetAttribute("IsCargoUnloadPad", true)
	cargoPad:SetAttribute("PlotIndex", plotIndex)

	local cPrompt = Instance.new("ProximityPrompt")
	cPrompt.ActionText = "Malzemeleri Boşalt"
	cPrompt.ObjectText = "⚡ Turbo Başlat"
	cPrompt.HoldDuration = 0
	cPrompt.MaxActivationDistance = 0
	cPrompt.Enabled = false
	cPrompt.Parent = cargoPad

	local office = nil
	local rateLabel = nil

	-- 5. Seviye Yükseltme Pad'i (Parsel zeminini temiz tutmak için devre dışı ve yer altında)
	local upgradePad = createPart(plotFolder, "UpgradeBuildingPad", Vector3.new(2, 0.5, 2), CFrame.new(plotOrigin + Vector3.new(0, -10, 0)), Color3.fromRGB(255, 175, 40), Enum.Material.SmoothPlastic, true, false)
	upgradePad.Transparency = 1
	upgradePad.CanCollide = false
	upgradePad:SetAttribute("PadType", "BuildingUpgrade")
	upgradePad:SetAttribute("OwnerUserId", player.UserId)
	upgradePad:SetAttribute("PlotIndex", plotIndex)

	local padClickDetector = Instance.new("ClickDetector")
	padClickDetector.MaxActivationDistance = 0
	padClickDetector.Parent = upgradePad

	local padPrompt = Instance.new("ProximityPrompt")
	padPrompt.Enabled = false
	padPrompt.Parent = upgradePad

	local padGui = Instance.new("BillboardGui")
	padGui.Name = "UpgradeBillboard"
	padGui.Enabled = false
	padGui.Parent = upgradePad

	local padLabel = Instance.new("TextLabel")
	padLabel.Name = "UpgradeText"
	padLabel.Text = ""
	padLabel.Parent = padGui

	-- 9. Yeni Şantiye Açma Pad'i (Unlock New Plot Pad - Sağ Aks, Kargodan Bağımsız)
	local unlockPad = createPart(plotFolder, "UnlockNewPlotPad", Vector3.new(9, 0.5, 7), CFrame.new(plotOrigin + Vector3.new(24, 2.3, 12)), Color3.fromRGB(50, 205, 90), Enum.Material.SmoothPlastic, true, false)
	unlockPad.Transparency = 1
	unlockPad:SetAttribute("PadType", "UnlockPlot")
	unlockPad:SetAttribute("OwnerUserId", player.UserId)
	unlockPad:SetAttribute("PlotIndex", plotIndex)

	local unlockTopGui = Instance.new("SurfaceGui")
	unlockTopGui.Face = Enum.NormalId.Top
	unlockTopGui.Parent = unlockPad
	local unlockTopLabel = Instance.new("TextLabel")
	unlockTopLabel.Size = UDim2.new(1, 0, 1, 0)
	unlockTopLabel.BackgroundTransparency = 1
	unlockTopLabel.Text = "🏢 YENİ ŞANTİYE ALANI\n(TIKLA veya ÜSTÜNE BAS)"
	unlockTopLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
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
	unlockGui.Size = UDim2.new(6.5, 0, 2.2, 0)
	unlockGui.StudsOffset = Vector3.new(0, 3.2, 0)
	unlockGui.MaxDistance = 35
	unlockGui.AlwaysOnTop = false
	unlockGui.Enabled = false
	unlockGui.Parent = unlockPad

	local unlockCard = Instance.new("Frame")
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
	unlockLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
	unlockLabel.TextScaled = true
	unlockLabel.Font = Enum.Font.FredokaOne
	unlockLabel.Parent = unlockCard

	local plotData: PlotData = {
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
		ProjectType = projectType or "SingleBuilding",
	}

	playerPlots[player][plotIndex] = plotData
	if player and player.UserId then
		if not playerPlots[player.UserId] then playerPlots[player.UserId] = {} end
		playerPlots[player.UserId][plotIndex] = plotData
	end
	-- Malzeme ve maliyet özniteliklerini başlangıçta senkronize et
	IslandManager.UpdateUpgradePadText(player, plotIndex)
	-- Kullanıcı talebi: Bütün elementler kenarda dursun, parsel boş olsun, kullanıcı tek tek ekleyecek.
	-- Başlangıçta parsel üzerine dev bina, vinç veya işçiler yerleştirilmez; parsel tamamen boştur.
	-- IslandManager.UpdateBuildingVisuals(player, plotIndex, buildingLevel)

	-- Cities: Skylines Zon ve Hizmet Binaları Görselleri
	task.spawn(function()
		local profile = DataService.GetProfile(player)
		local pData = profile and profile.Plots and profile.Plots[plotIndex]
		local zone = (pData and pData.Zone) or "Residential"
		IslandManager.UpdatePlotZoneVisual(player, plotIndex, zone)

		if profile and profile.Services then
			for sType, sInfo in pairs(profile.Services) do
				if sInfo.PlotIndex == plotIndex then
					IslandManager.PlaceServiceVisual(player, plotIndex, sType)
				end
			end
		end
	end)

	return plotData
end

function IslandManager.GetPlot(player: Player, plotIndex: number): PlotData?
	local plots = playerPlots[player] or (player and playerPlots[player.UserId])
	if plots and plots[plotIndex] then
		return plots[plotIndex]
	end

	-- Yedek Çözümleyici: Workspace içerisindeki parsel klasörünü dinamik bağla
	if player and Workspace then
		local folderName = string.format("Plot_%s_%d", player.Name, plotIndex)
		local plotFolder = Workspace:FindFirstChild(folderName) :: Folder?
		if plotFolder then
			local upgradePad = plotFolder:FindFirstChild("UpgradeBuildingPad") :: Part?
			local bbgui = upgradePad and upgradePad:FindFirstChildWhichIsA("BillboardGui", true)
			local padLabel = bbgui and bbgui:FindFirstChildWhichIsA("TextLabel", true)

			local cargoPad = plotFolder:FindFirstChild("CargoUnloadPad") :: Part?
			local unlockPad = plotFolder:FindFirstChild("UnlockNewPlotPad") :: Part?
			local unlockGui = unlockPad and unlockPad:FindFirstChildWhichIsA("BillboardGui", true)
			local unlockLabel = unlockGui and unlockGui:FindFirstChildWhichIsA("TextLabel", true)

			local ground = plotFolder:FindFirstChild("PlotGround") :: BasePart?
			local plotOrigin = (ground and ground.Position) or Vector3.new(0, 0, 0)

			local fallbackData: any = {
				Folder = plotFolder,
				PlotIndex = plotIndex,
				UpgradePad = upgradePad,
				UpgradePadLabel = padLabel,
				CargoPad = cargoPad,
				UnlockPad = unlockPad,
				UnlockPadLabel = unlockLabel,
				UnlockGui = unlockGui,
				Origin = plotOrigin,
				ProjectType = "SingleBuilding",
			}
			if not playerPlots[player] then playerPlots[player] = {} end
			playerPlots[player][plotIndex] = fallbackData
			return fallbackData
		end
	end
	return nil
end

function IslandManager.GetAllPlots(player: Player): { [number]: PlotData }
	return playerPlots[player] or (player and playerPlots[player.UserId]) or {}
end

-- ============================================================================
-- 3b. ŞANTİYE GELİŞTİRME PADİ METNİ GÜNCELLEME (İNDİRİM DAHİL)
-- ============================================================================
function IslandManager.UpdateUpgradePadText(player: Player, plotIndex: number)
	local plot = IslandManager.GetPlot(player, plotIndex)
	if not plot or not plot.UpgradePadLabel then return end

	local profile = DataService.GetProfile(player)
	local pData = profile and profile.Plots and profile.Plots[plotIndex]
	local level = (pData and pData.BuildingLevel) or 1
	local nextLevel = level + 1
	local nextData = GameConfig.BUILDINGS[nextLevel]

	if not nextData then
		plot.UpgradePadLabel.Text = "✨ PROJE %100 TAMAMLANDI! ✨\n(Portföyde)"
		return
	end

	local pType = (pData and pData.ProjectType) or plot.ProjectType or "SingleBuilding"
	local pTypeData = ProjectTypeConfig.GetType(pType)
	local costMult = pTypeData.CostMultiplier or 1.0
	local baseCost = math.floor(nextData.Cost * costMult)

	local deliveredMats = (pData and pData.DeliveredMaterials) or 0
	local maxDiscount = math.floor(baseCost * 0.35)
	local matDiscount = math.min(deliveredMats * 10, maxDiscount)
	local finalCost = math.max(10, baseCost - matDiscount)

	plot.Folder:SetAttribute("DeliveredMaterials", deliveredMats)
	plot.Folder:SetAttribute("DiscountedCost", finalCost)
	plot.Folder:SetAttribute("BaseCost", baseCost)
	plot.Folder:SetAttribute("MaterialDiscount", matDiscount)

	if matDiscount > 0 then
		plot.UpgradePadLabel.Text = string.format("🔨 %s (Lv. %d)\nMaliyet: %s\n(-%s İndirim 📦)", nextData.Name, nextLevel, NumberFormat.FormatCash(finalCost), NumberFormat.FormatCash(matDiscount))
	else
		plot.UpgradePadLabel.Text = string.format("🔨 %s (Lv. %d)\nMaliyet: %s", nextData.Name, nextLevel, NumberFormat.FormatCash(finalCost))
	end
end

-- ============================================================================
-- 4. BİNA SEVİYESİ YÜKSELTİLDİĞİNDE GÖRSEL YENİLEME & ŞEHİR DÖNGÜSÜ
-- ============================================================================
function IslandManager.UpdateBuildingVisuals(player: Player, plotIndex: number, level: number)
	local plot = IslandManager.GetPlot(player, plotIndex)
	if not plot then return end

	-- 1. Bina Modelini Yeniden İnşa Et
	if plot.BuildingModel then
		plot.BuildingModel:Destroy()
	end
	plot.BuildingModel = BuildingBuilder.buildBuildingModel(plot.Folder, plot.BuildingOrigin, level, plot.ProjectType)

	local nextLevel = level + 1
	local nextData = GameConfig.BUILDINGS[nextLevel]

	if nextData then
		-- İNŞAAT DEVAM EDİYOR (Seviye 1, 2, 3, 4)
		IslandManager.UpdateUpgradePadText(player, plotIndex)
		plot.UpgradePadLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
		plot.UpgradePad.Color = Color3.fromRGB(255, 175, 40)
		plot.UpgradePad.Transparency = 0
		plot.UpgradePad.CanCollide = true

		-- Kule Vinç Yoksa Yeniden Kur (İnşaat sürecinde vinç çalışmalı)
		if not plot.CraneModel then
			local craneModel, craneJib = SiteEquipmentBuilder.buildTowerCrane(plot.Folder, plot.CraneOrigin)
			plot.CraneModel = craneModel
			plot.CraneJib = craneJib
		end

		-- Şantiye Ekipmanları ve İşçiler Aktif (Seviye 1, 2, 3, 4)
		CityLifeService.spawnSiteWorkers(plot.Folder, plot.Origin)

		local oldPlaque = plot.Folder:FindFirstChild("CorporatePlaque")
		if oldPlaque then oldPlaque:Destroy() end

		if not plot.Folder:FindFirstChild("SiteOffice") then
			local newOffice, newRateLabel = SiteEquipmentBuilder.buildSiteOffice(plot.Folder, plot.Origin)
			plot.RateLabel = newRateLabel
		end

		-- Kargo teslim pad'i ve çekiç hedefi aktif
		plot.CargoPad.Transparency = 0
		plot.CargoPad.CanCollide = false
		local cpPrompt = plot.CargoPad:FindFirstChildOfClass("ProximityPrompt")
		if cpPrompt then cpPrompt.Enabled = true end
		local cpGui = plot.CargoPad:FindFirstChildOfClass("BillboardGui")
		if cpGui then cpGui.Enabled = true end

		local hammerTarget = plot.Folder:FindFirstChild("HammerTarget")
		if hammerTarget then
			local cd = hammerTarget:FindFirstChildOfClass("ClickDetector")
			if cd then cd.MaxActivationDistance = 45 end
		end

		-- Aşama Peyzajı ve Ağaçlar (Seviye 1-4)
		ParcelLandscape.UpdateLandscape(plot.Folder, plot.Origin, level)

		-- Plaza modeli varsa kaldır
		local oldPlaza = plot.Folder:FindFirstChild("SkyscraperPlaza")
		if oldPlaza then oldPlaza:Destroy() end

		-- Gökdelen henüz tamamlanmadı, yeni ada açma butonu kapalı
		plot.UnlockPad.Transparency = 1
		plot.UnlockPad.CanCollide = false
		plot.UnlockGui.Enabled = false
	else
		-- ====================================================================
		-- GÖKDELEN TAMAMLANDI (%100 PROJE)!
		-- ŞANTİYE EVRESİ BİTTİ -> TAMAMLANMIŞ METROPOL YAŞAM ALANINA DÖNÜŞÜM
		-- ====================================================================

		-- 1. KULE VİNÇ SÖKÜLÜR VE KALDIRILIR!
		if plot.CraneModel then
			plot.CraneModel:Destroy()
			plot.CraneModel = nil
			plot.CraneJib = nil
			print(string.format("[IslandManager] %s için %d. Proje tamamlandı! Kule vinç söküldü.", player.Name, plotIndex))
		end

		-- 2. ŞANTİYE İŞÇİLERİ VE MÜHENDİSLER SAHADAN AYRILIR! (İnşaat Bitti!)
		CityLifeService.clearSiteWorkers(plot.Folder)

		-- 3. ŞANTİYE OFİS KONTEYNERİ KALDIRILIR, YERİNE PRESTİJ KURUMSAL PLAKETİ GELİR!
		local oldOffice = plot.Folder:FindFirstChild("SiteOffice")
		if oldOffice then oldOffice:Destroy() end

		if not plot.Folder:FindFirstChild("CorporatePlaque") then
			local plaqueModel, plaqueRateLabel = SiteEquipmentBuilder.buildCorporatePlaque(plot.Folder, plot.Origin, player, plotIndex)
			plot.RateLabel = plaqueRateLabel
		end

		-- 4. GEÇİCİ ŞANTİYE PADLERİ DEVRE DIŞI BIRAKILIR (Tamamlanmış Mülk)
		plot.CargoPad.Transparency = 1
		plot.CargoPad.CanCollide = false
		local cpPrompt = plot.CargoPad:FindFirstChildOfClass("ProximityPrompt")
		if cpPrompt then cpPrompt.Enabled = false end
		local cpGui = plot.CargoPad:FindFirstChildOfClass("BillboardGui")
		if cpGui then cpGui.Enabled = false end

		local hammerTarget = plot.Folder:FindFirstChild("HammerTarget")
		if hammerTarget then
			local cd = hammerTarget:FindFirstChildOfClass("ClickDetector")
			if cd then cd.MaxActivationDistance = 0 end
		end

		-- 5. SEVİYE 5 METROPOL GÖKDELEN PRESTİJ PEYZAJI VE BULVAR AĞAÇLARI
		ParcelLandscape.UpdateLandscape(plot.Folder, plot.Origin, level)

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

	-- ========================================================================
	-- AÇIK HAVA ÇARŞISI (PROMENADE MEYDANI) VE CITIES: SKYLINES SİVİL YAŞAMI
	-- ========================================================================
	local oldPromenade = plot.Folder:FindFirstChild("CommercialPromenade")
	if oldPromenade then oldPromenade:Destroy() end
	local oldPromResidents = plot.Folder:FindFirstChild("PromenadeResidents")
	if oldPromResidents then oldPromResidents:Destroy() end
	local oldResidents = plot.Folder:FindFirstChild("CityResidents")
	if oldResidents then oldResidents:Destroy() end

	if level >= 4 then
		-- 1. Açık Hava Çarşısı / Promenade Meydanı ve Müstakil Butik Pavyonlar
		local totalRent = IslandManager.GetCommercialRent(level)
		local customConfig = DataService.GetCustomizer(player)
		CommercialBuilder.buildPromenade(plot.Folder, plot.Origin, level, totalRent, customConfig)

		-- 2. Promenade Yaya ve Kafe Müşteri Simülasyonu
		CityLifeService.spawnPromenadeResidents(plot.Folder, plot.Origin, level)

		-- 4. Otoyol Kaldırımı Sivil Sakinleri (Yayalar)
		local resFolder = Instance.new("Folder")
		resFolder.Name = "CityResidents"
		resFolder.Parent = plot.Folder

		local resCount = (level >= 5) and 6 or 4
		local sidewalkZ = plot.Origin.Z + 36
		for i = 1, resCount do
			local name = GameConfig.CITY_RESIDENTS.Names[((i - 1) % #GameConfig.CITY_RESIDENTS.Names) + 1]
			local role = GameConfig.CITY_RESIDENTS.Roles[((i - 1) % #GameConfig.CITY_RESIDENTS.Roles) + 1]
			local outfit = GameConfig.CITY_RESIDENTS.Outfits[((i - 1) % #GameConfig.CITY_RESIDENTS.Outfits) + 1]
			local startX = plot.Origin.X - 20 + (i * 9)
			local patrolDist = 12 + (i * 2.5)
			-- Kaldırım üst yüzeyi: plot.Origin.Y + 2.4 (6.4), HRP Y: 6.4 + 3.0 = 9.4 (plot.Origin.Y + 5.4)
			local rCF = CFrame.new(startX, plot.Origin.Y + 5.4, sidewalkZ + ((i % 2 == 0) and 2 or -2))
			CityLifeService.spawnCityResident(resFolder, name, role, outfit, rCF, patrolDist)
		end
		print(string.format("[IslandManager] %s için %d. Projede Açık Hava Çarşısı, kira tabelası (+%s/sn) ve canlı mahalle yaşamı aktif edildi! (Seviye %d)", player.Name, plotIndex, NumberFormat.FormatCash(totalRent), level))
	end
end

-- ============================================================================
-- 5. TİCARİ KİRA GELİRİ HESAPLAYICI
-- ============================================================================
function IslandManager.GetCommercialRent(buildingLevel: number): number
	if buildingLevel < 3 then
		return 0
	elseif buildingLevel == 3 then
		return GameConfig.COMMERCIAL_SHOPS.Restaurant and GameConfig.COMMERCIAL_SHOPS.Restaurant.RentPerSecond or 65
	elseif buildingLevel == 4 then
		local bRent = GameConfig.COMMERCIAL_SHOPS.Bakery and GameConfig.COMMERCIAL_SHOPS.Bakery.RentPerSecond or 40
		local mRent = GameConfig.COMMERCIAL_SHOPS.Market and GameConfig.COMMERCIAL_SHOPS.Market.RentPerSecond or 35
		return bRent + mRent
	elseif buildingLevel >= 5 then
		local totalRent = 0
		for _, shop in pairs(GameConfig.COMMERCIAL_SHOPS or {}) do
			totalRent += (shop.RentPerSecond or 40)
		end
		return totalRent
	end
	return 0
end

-- ============================================================================
-- 6. PARSELLERİ KALDIRMA (OYUNCU AYRILDIĞINDA)
-- ============================================================================
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

-- ============================================================================
-- 7. CITIES: SKYLINES BÖLGELEME 3D İNDİKATÖRÜ
-- ============================================================================
function IslandManager.UpdatePlotZoneVisual(player: Player, plotIndex: number, zoneType: string)
	local plot = IslandManager.GetPlot(player, plotIndex)
	if not plot or not plot.Folder then return end

	local existing = plot.Folder:FindFirstChild("ZoneIndicator")
	if existing then existing:Destroy() end

	local zoneData = ZoneConfig.GetZone(zoneType) or ZoneConfig.ZONES.Residential
	local zoneModel = Instance.new("Model")
	zoneModel.Name = "ZoneIndicator"

	local pillarCF = CFrame.new(plot.Origin + Vector3.new(-8, 2.5, 16))
	local base = createPart(zoneModel, "ZonePillarBase", Vector3.new(2, 0.6, 2), pillarCF * CFrame.new(0, -2.2, 0), Color3.fromRGB(45, 50, 55), Enum.Material.Concrete, true, true)
	local post = createPart(zoneModel, "ZonePillarPost", Vector3.new(0.6, 4.5, 0.6), pillarCF, Color3.fromRGB(70, 75, 80), Enum.Material.Metal, true, true)
	local signHead = createPart(zoneModel, "ZoneSignHead", Vector3.new(3.5, 1.2, 0.4), pillarCF * CFrame.new(0, 2.4, 0), zoneData.Color, Enum.Material.SmoothPlastic, true, false)

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(6.5, 0, 2.2, 0)
	bb.StudsOffset = Vector3.new(0, 2.4, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 45
	bb.Parent = signHead

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 1, 0)
	card.BackgroundColor3 = Color3.fromRGB(25, 28, 32)
	card.BackgroundTransparency = 0.05
	card.Parent = bb
	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 10)
	cCorner.Parent = card
	local cStroke = Instance.new("UIStroke")
	cStroke.Color = zoneData.Color
	cStroke.Thickness = 2.5
	cStroke.Parent = card

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.95, 0, 0.95, 0)
	lbl.Position = UDim2.new(0.025, 0, 0.025, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextScaled = true
	lbl.Text = string.format("%s %s\n(%s)", zoneData.Icon, zoneData.Name, zoneData.Description)
	lbl.Parent = card

	zoneModel.PrimaryPart = post
	zoneModel.Parent = plot.Folder
end

-- ============================================================================
-- 8. CITIES: SKYLINES HİZMET BİNASI YERLEŞTİRİCİ
-- ============================================================================
function IslandManager.PlaceServiceVisual(player: Player, plotIndex: number, serviceType: string)
	local plot = IslandManager.GetPlot(player, plotIndex)
	if not plot or not plot.Folder then return end

	local serviceFolder = plot.Folder:FindFirstChild("Services")
	if not serviceFolder then
		serviceFolder = Instance.new("Folder")
		serviceFolder.Name = "Services"
		serviceFolder.Parent = plot.Folder
	end

	local existing = serviceFolder:FindFirstChild("Service_" .. serviceType)
	if existing then existing:Destroy() end

	-- Hizmet binası konumu: Parselin sağ arka köşesi
	local serviceCF = CFrame.new(plot.Origin + Vector3.new(24, 0, -15)) * CFrame.Angles(0, math.rad(-90), 0)
	ServiceBuildingManager.BuildServiceVisual(serviceFolder, serviceType, serviceCF)
end

function IslandManager.RebuildPromenade(player: Player, plotIndex: number)
	local plot = IslandManager.GetPlot(player, plotIndex)
	if not plot or not plot.Folder then return end

	local profile = DataService.GetProfile(player)
	local level = (profile and profile.Plots and profile.Plots[plotIndex] and profile.Plots[plotIndex].BuildingLevel) or 1
	local customConfig = DataService.GetCustomizer(player)
	local totalRent = IslandManager.GetCommercialRent(level)

	local oldPromenade = plot.Folder:FindFirstChild("CommercialPromenade")
	if oldPromenade then oldPromenade:Destroy() end

	CommercialBuilder.buildPromenade(plot.Folder, plot.Origin, math.max(4, level), totalRent, customConfig)
end

return IslandManager

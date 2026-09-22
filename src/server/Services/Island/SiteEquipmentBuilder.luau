--!strict
-- ============================================================================
-- SiteEquipmentBuilder.luau
-- Şantiye Ekipmanları, Kule Vinç, Şantiye Konteyner Ofisi ve Prestij Meydanı (Plaza)
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetNormalizer = require(ReplicatedStorage.Shared.AssetNormalizer)
local PlotDataTypes = require(script.Parent.PlotDataTypes)

local createPart = PlotDataTypes.createPart
local createCylinder = PlotDataTypes.createCylinder

local SiteEquipmentBuilder = {}

-- ReplicatedStorage.Assets.Equipment altındaki hazır kule vinç modelini bulur
local function getTowerCraneTemplate(): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then return nil end
	local eq = assets:FindFirstChild("Equipment")
	if not eq then return nil end
	local candidate = eq:FindFirstChild("TowerCrane")
	if candidate and candidate:IsA("Model") then
		local inner = candidate:FindFirstChildWhichIsA("Model")
		return inner or candidate
	end
	return nil
end

-- ============================================================================
-- 1. KULE VİNÇ OLUŞTURUCU (İnşaat Devam Ederken)
-- ============================================================================
function SiteEquipmentBuilder.buildTowerCrane(parent: Instance, craneOrigin: Vector3): (Model, Part)
	local template = getTowerCraneTemplate()
	if template then
		local craneModel = template:Clone()
		craneModel.Name = "TowerCrane"
		AssetNormalizer.Sanitize(craneModel)

		for _, desc in ipairs(craneModel:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Anchored = true
			end
		end

		-- Gerçek 3D Dönüş İzdüşümlü AABB Hesabı
		local minX, maxX = math.huge, -math.huge
		local minY, maxY = math.huge, -math.huge
		local minZ, maxZ = math.huge, -math.huge
		for _, p in ipairs(craneModel:GetDescendants()) do
			if p:IsA("BasePart") then
				local pcf = p.CFrame
				local psz = p.Size
				local extX = 0.5 * (math.abs(pcf.XVector.X) * psz.X + math.abs(pcf.YVector.X) * psz.Y + math.abs(pcf.ZVector.X) * psz.Z)
				local extY = 0.5 * (math.abs(pcf.XVector.Y) * psz.X + math.abs(pcf.YVector.Y) * psz.Y + math.abs(pcf.ZVector.Y) * psz.Z)
				local extZ = 0.5 * (math.abs(pcf.XVector.Z) * psz.X + math.abs(pcf.YVector.Z) * psz.Y + math.abs(pcf.ZVector.Z) * psz.Z)

				minX = math.min(minX, pcf.Position.X - extX)
				maxX = math.max(maxX, pcf.Position.X + extX)
				minY = math.min(minY, pcf.Position.Y - extY)
				maxY = math.max(maxY, pcf.Position.Y + extY)
				minZ = math.min(minZ, pcf.Position.Z - extZ)
				maxZ = math.max(maxZ, pcf.Position.Z + extZ)
			end
		end

		local aabbCenter = Vector3.new((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2)
		local rawHeight = maxY - minY
		craneModel.WorldPivot = CFrame.new(aabbCenter)

		-- Şantiyeye uygun kule vinç yüksekliği: 50 stud
		local targetHeight = 50
		local scale = 1
		if rawHeight > 0 then
			scale = targetHeight / rawHeight
			craneModel:ScaleTo(scale)
		end

		local targetY = craneOrigin.Y + 2.0 + (targetHeight / 2)
		craneModel:PivotTo(CFrame.new(craneOrigin.X, targetY, craneOrigin.Z))

		-- Zemine sıfırlama (MinY)
		local actualMinY = math.huge
		for _, p in ipairs(craneModel:GetDescendants()) do
			if p:IsA("BasePart") then
				local pcf = p.CFrame
				local psz = p.Size
				local extY = 0.5 * (math.abs(pcf.XVector.Y) * psz.X + math.abs(pcf.YVector.Y) * psz.Y + math.abs(pcf.ZVector.Y) * psz.Z)
				actualMinY = math.min(actualMinY, pcf.Position.Y - extY)
			end
		end
		local diffY = (craneOrigin.Y + 2.0) - actualMinY
		if math.abs(diffY) > 0.001 then
			craneModel:PivotTo(craneModel:GetPivot() + Vector3.new(0, diffY, 0))
		end

		-- Tepe İkaz Lambası
		local beacon = createPart(
			craneModel, "WarningBeacon",
			Vector3.new(1.2, 1.6, 1.2),
			CFrame.new(craneOrigin.X, craneOrigin.Y + 2.0 + targetHeight + 1, craneOrigin.Z),
			Color3.fromRGB(255, 50, 50),
			Enum.Material.Neon,
			true, false
		)

		local primaryPart = craneModel:FindFirstChildWhichIsA("BasePart", true) or beacon
		craneModel.PrimaryPart = primaryPart

		craneModel.Parent = parent
		return craneModel, primaryPart
	end

	-- Yedek (Fallback) Prosedürel Vinç
	local craneModel = Instance.new("Model")
	craneModel.Name = "TowerCrane"

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

	createPart(craneModel, "WarningBeacon", Vector3.new(1, 1.5, 1), CFrame.new(craneOrigin.X, jibPivotY + 3, craneOrigin.Z), Color3.fromRGB(255, 50, 50), Enum.Material.Neon, true, false)

	craneModel.Parent = parent
	return craneModel, jib
end

-- ============================================================================
-- 2. ŞANTİYE KONTEYNER OFİSİ VE GELİR BİLLBOARDU
-- ============================================================================
function SiteEquipmentBuilder.buildSiteOffice(parent: Instance, plotOrigin: Vector3): (Part, TextLabel)
	-- Yürüme alanını tıkamayan, parsel sınırında şık ve ince şantiye bilgi totemi (Ayak altında durmaz)
	local officeCFrame = CFrame.new(plotOrigin + Vector3.new(27, 3.5, -20))
	local office = createPart(
		parent, "SiteOffice",
		Vector3.new(0.6, 7, 0.6),
		officeCFrame,
		Color3.fromRGB(45, 50, 58),
		Enum.Material.Metal,
		true, false -- CanCollide = false: Asla yürüyüşü engellemez, NPC'ler içine geçmez
	)

	-- Üzerinde Asılı Temiz Gelir Göstergesi (Göz Hizası Üzerinde)
	local rateGui = Instance.new("BillboardGui")
	rateGui.Name = "RateBillboard"
	rateGui.Size = UDim2.new(6.5, 0, 2.2, 0)
	rateGui.StudsOffset = Vector3.new(0, 4.2, 0)
	rateGui.AlwaysOnTop = false
	rateGui.MaxDistance = 45
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
	rStroke.Thickness = 2.2
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

-- ============================================================================
-- 3. PROJE %100 TAMAMLANDIĞINDA ŞANTİYE OFİSİNİN YERİNE GELEN PRESTİJ PLAKETİ
-- ============================================================================
function SiteEquipmentBuilder.buildCorporatePlaque(
	parent: Instance,
	plotOrigin: Vector3,
	player: Player,
	plotIndex: number
): (Model, TextLabel)
	local plaqueModel = Instance.new("Model")
	plaqueModel.Name = "CorporatePlaque"

	local pCenter = plotOrigin + Vector3.new(25, 2.2, -18)

	-- Mermer Kaide (Taban)
	createPart(plaqueModel, "BasePedestal", Vector3.new(8, 0.8, 4), CFrame.new(pCenter + Vector3.new(0, 0.4, 0)), Color3.fromRGB(240, 240, 245), Enum.Material.Marble, true, true)

	-- Parlak Granit/Cam Şirket Plaketi
	local mainPillar = createPart(plaqueModel, "PlaquePillar", Vector3.new(6.5, 5.5, 1.2), CFrame.new(pCenter + Vector3.new(0, 3.5, 0)), Color3.fromRGB(35, 40, 45), Enum.Material.Slate, true, true)
	plaqueModel.PrimaryPart = mainPillar

	-- Ön Cam Panel
	local glassFace = createPart(plaqueModel, "GlassFace", Vector3.new(6.0, 4.8, 0.3), CFrame.new(pCenter + Vector3.new(0, 3.5, 0.7)), Color3.fromRGB(220, 240, 255), Enum.Material.Glass, true, true)

	local sGui = Instance.new("SurfaceGui")
	sGui.Face = Enum.NormalId.Front
	sGui.Parent = glassFace

	local plaqueCard = Instance.new("Frame")
	plaqueCard.Size = UDim2.new(1, 0, 1, 0)
	plaqueCard.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
	plaqueCard.BackgroundTransparency = 0.2
	plaqueCard.BorderSizePixel = 0
	plaqueCard.Parent = sGui

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.9, 0, 0.45, 0)
	titleLabel.Position = UDim2.new(0.05, 0, 0.08, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = string.format("🏛️ %s PLAZA\n[Portföy Proje #%d]", player.DisplayName, plotIndex)
	titleLabel.TextColor3 = Color3.fromRGB(245, 215, 80)
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.TextScaled = true
	titleLabel.Parent = plaqueCard

	local subLabel = Instance.new("TextLabel")
	subLabel.Size = UDim2.new(0.9, 0, 0.35, 0)
	subLabel.Position = UDim2.new(0.05, 0, 0.55, 0)
	subLabel.BackgroundTransparency = 1
	subLabel.Text = "✨ PROJE TAMAMLANDI ✨\n(Aktif Şehir Yaşam Alanı)"
	subLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	subLabel.Font = Enum.Font.FredokaOne
	subLabel.TextScaled = true
	subLabel.Parent = plaqueCard

	-- Üst Gelir Billboardu (Ofisteki kartın şık versiyonu)
	local rateGui = Instance.new("BillboardGui")
	rateGui.Name = "RateBillboard"
	rateGui.Size = UDim2.new(7.5, 0, 2.2, 0)
	rateGui.StudsOffset = Vector3.new(0, 4.2, 0)
	rateGui.AlwaysOnTop = false
	rateGui.Parent = mainPillar

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
	rStroke.Color = Color3.fromRGB(40, 180, 80)
	rStroke.Thickness = 2.5
	rStroke.Parent = rateCard

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateText"
	rateLabel.Size = UDim2.new(0.92, 0, 0.88, 0)
	rateLabel.Position = UDim2.new(0.04, 0, 0.06, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = "+250 İP/sn (Kira) 🏙️"
	rateLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.FredokaOne
	rateLabel.Parent = rateCard

	-- Yanına Dinlenme Bankı
	createPart(plaqueModel, "PlazaBench", Vector3.new(7, 1.2, 2.2), CFrame.new(pCenter + Vector3.new(0, 0.6, 5.5)), Color3.fromRGB(120, 80, 45), Enum.Material.WoodPlanks, true, true)

	plaqueModel.Parent = parent
	return plaqueModel, rateLabel
end

return SiteEquipmentBuilder


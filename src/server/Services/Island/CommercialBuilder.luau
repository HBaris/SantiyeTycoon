--!strict
-- ============================================================================
-- CommercialBuilder.luau
-- Açık Hava Çarşısı / Promenade Meydanı (Mixed-Use Commercial Promenade)
-- Hazır Dükkan Modelleri (Bakery, Market, Barber, PetShop, Restaurant, Fountain)
-- ve Hazır Sokak Mobilyaları (StreetLamp, Bench, Planter)
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local AssetNormalizer = require(ReplicatedStorage.Shared.AssetNormalizer)
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
	if candidate and (candidate:IsA("Model") or candidate:IsA("Folder")) then
		local inner = candidate:FindFirstChildWhichIsA("Model")
		return inner or (candidate:IsA("Model") and candidate or nil)
	end
	return nil
end

-- ReplicatedStorage.Assets.Props altındaki hazır sokak mobilyalarını arayan fonksiyon
local function getReadyPropModel(propId: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then return nil end
	local propsFolder = assets:FindFirstChild("Props")
	if not propsFolder then return nil end

	local candidate = propsFolder:FindFirstChild(propId)
	if candidate and (candidate:IsA("Model") or candidate:IsA("Folder")) then
		local inner = candidate:FindFirstChildWhichIsA("Model")
		return inner or (candidate:IsA("Model") and candidate or nil)
	end
	return nil
end

local function instantiateReadyModel(template: Model, targetCF: CFrame, maxAllowedSize: number, targetYaw: number?): Model
	local model = template:Clone()
	AssetNormalizer.Sanitize(model)

	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = true
		end
	end

	-- Yatay AABB sınırını hesapla
	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			minX = math.min(minX, p.Position.X - p.Size.X / 2)
			maxX = math.max(maxX, p.Position.X + p.Size.X / 2)
			minZ = math.min(minZ, p.Position.Z - p.Size.Z / 2)
			maxZ = math.max(maxZ, p.Position.Z + p.Size.Z / 2)
		end
	end

	local origWidth = math.max(maxX - minX, maxZ - minZ)
	if origWidth > maxAllowedSize then
		model:ScaleTo(maxAllowedSize / origWidth)
	end

	-- Yönlendirme
	local yaw = targetYaw or 0
	model:PivotTo(targetCF * CFrame.Angles(0, math.rad(yaw), 0))

	-- Mutlak zemin hizalama
	local minY = math.huge
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			minY = math.min(minY, p.Position.Y - p.Size.Y / 2)
		end
	end
	local groundY = targetCF.Position.Y
	local shiftY = groundY - minY
	model:PivotTo(model:GetPivot() + Vector3.new(0, shiftY, 0))

	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end

	return model
end

-- ============================================================================
-- 1. SOKAK MOBİLYALARI (Sokak Lambası, Bank, Çiçeklik)
-- ============================================================================
function CommercialBuilder.buildPromenadeLamp(parent: Instance, cf: CFrame): Model
	local ready = getReadyPropModel("StreetLamp")
	if ready then
		local lamp = ready:Clone()
		lamp.Name = "PromenadeLamp"
		AssetNormalizer.Normalize(lamp, { MaxHorizontalSize = 3.5, TargetHeight = 11, EnforceAnchored = true })
		AssetNormalizer.PlaceOnGround(lamp, cf)
		lamp.Parent = parent
		return lamp
	end

	local lamp = Instance.new("Model")
	lamp.Name = "PromenadeLamp"
	createPart(lamp, "LampPole", Vector3.new(0.6, 9.5, 0.6), cf * CFrame.new(0, 5, 0), Color3.fromRGB(45, 48, 55), Enum.Material.Metal, true, true)
	lamp.Parent = parent
	return lamp
end

function CommercialBuilder.buildBench(parent: Instance, cf: CFrame): Model
	local ready = getReadyPropModel("Bench")
	if ready then
		local bench = ready:Clone()
		bench.Name = "PromenadeBench"
		AssetNormalizer.Normalize(bench, { MaxHorizontalSize = 6.0, TargetHeight = 3.5, EnforceAnchored = true })
		AssetNormalizer.PlaceOnGround(bench, cf)
		bench.Parent = parent
		return bench
	end

	local bench = Instance.new("Model")
	bench.Name = "PromenadeBench"
	createPart(bench, "BenchSeat", Vector3.new(5, 1.2, 2), cf * CFrame.new(0, 0.6, 0), Color3.fromRGB(150, 95, 45), Enum.Material.WoodPlanks, true, true)
	bench.Parent = parent
	return bench
end

function CommercialBuilder.buildPlanter(parent: Instance, cf: CFrame): Model
	local ready = getReadyPropModel("Planter")
	if ready then
		local planter = ready:Clone()
		planter.Name = "PromenadePlanter"
		AssetNormalizer.Normalize(planter, { MaxHorizontalSize = 4.5, TargetHeight = 3.0, EnforceAnchored = true })
		AssetNormalizer.PlaceOnGround(planter, cf)
		planter.Parent = parent
		return planter
	end

	local planter = Instance.new("Model")
	planter.Name = "PromenadePlanter"
	createPart(planter, "PlanterBox", Vector3.new(4, 1.5, 2), cf * CFrame.new(0, 0.75, 0), Color3.fromRGB(220, 220, 225), Enum.Material.Concrete, true, true)
	planter.Parent = parent
	return planter
end

-- ============================================================================
-- 2. PROMENADE GİRİŞ TAKI VE ANIT KİRA TABELASI
-- ============================================================================
function CommercialBuilder.buildEntranceSign(parent: Instance, cf: CFrame, totalRent: number): Model
	local signModel = Instance.new("Model")
	signModel.Name = "PromenadeEntranceGate"

	local gateW = 20.0
	for _, px in ipairs({ -gateW / 2 + 0.8, gateW / 2 - 0.8 }) do
		createPart(signModel, "ArchPillar", Vector3.new(1.6, 9.0, 1.6), cf * CFrame.new(px, 4.5, 0), Color3.fromRGB(48, 52, 58), Enum.Material.Cobblestone, true, true)
		createPart(signModel, "PillarCap", Vector3.new(2.2, 0.6, 2.2), cf * CFrame.new(px, 9.2, 0), Color3.fromRGB(220, 185, 70), Enum.Material.Metal, true, true)
	end

	local beam = createPart(signModel, "ArchBeam", Vector3.new(gateW, 2.6, 1.4), cf * CFrame.new(0, 8.2, 0), Color3.fromRGB(35, 38, 44), Enum.Material.Metal, true, true)

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
		rentLabel.Text = string.format("✨ Toplam Ticari Kira: +%s/sn", NumberFormat.FormatCash(totalRent))
		rentLabel.TextColor3 = Color3.fromRGB(80, 240, 120)
		rentLabel.Font = Enum.Font.FredokaOne
		rentLabel.TextScaled = true
		rentLabel.Parent = container
	end

	signModel.Parent = parent
	return signModel
end

-- ============================================================================
-- 3. ANA PROMENADE MEYDANI İNŞA EDİCİ
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
	local promCenterX = pX - 22
	local promCenterZ = pZ + 2

	-- Geniş Cadde Zemin Platformu (Bazalt Arnavut Kaldırımı)
	createPart(
		promenadeModel, "PromenadePavement",
		Vector3.new(24, 0.4, 64),
		CFrame.new(promCenterX, pY, promCenterZ),
		Color3.fromRGB(52, 55, 62),
		Enum.Material.Cobblestone,
		true, true
	)

	-- Çarşı Giriş Takı
	local gateCF = CFrame.new(promCenterX, pY, promCenterZ + 31)
	CommercialBuilder.buildEntranceSign(promenadeModel, gateCF, totalRent)

	-- 1. Taş Fırın & Patisserie
	local bakeryReady = getReadyCommercialModel("Bakery")
	if bakeryReady then
		local bModel = instantiateReadyModel(bakeryReady, CFrame.new(promCenterX - 5, pY, promCenterZ + 18), 12, 90)
		bModel.Name = "Shop_Bakery"
		bModel.Parent = promenadeModel
	end

	-- 2. Gross Süpermarket
	local marketReady = getReadyCommercialModel("Market")
	if marketReady then
		local mModel = instantiateReadyModel(marketReady, CFrame.new(promCenterX - 5, pY, promCenterZ + 3), 13, 90)
		mModel.Name = "Shop_Market"
		mModel.Parent = promenadeModel
	end

	-- 3. Süs Havuzu ve Fıskiye
	local fountainReady = getReadyCommercialModel("Fountain")
	if fountainReady then
		local fModel = instantiateReadyModel(fountainReady, CFrame.new(promCenterX + 4, pY, promCenterZ + 10), 8, 0)
		fModel.Name = "FountainPool"
		fModel.Parent = promenadeModel
	end

	-- Seviye 5 Ekstra Dükkanlar
	if level >= 5 then
		-- 4. VIP Kuaför
		local barberReady = getReadyCommercialModel("Barber")
		if barberReady then
			local barModel = instantiateReadyModel(barberReady, CFrame.new(promCenterX - 5, pY, promCenterZ - 12), 12, 90)
			barModel.Name = "Shop_Barber"
			barModel.Parent = promenadeModel
		end

		-- 5. Pati Pet Shop
		local petReady = getReadyCommercialModel("PetShop")
		if petReady then
			local petModel = instantiateReadyModel(petReady, CFrame.new(promCenterX - 5, pY, promCenterZ - 24), 11, 90)
			petModel.Name = "Shop_PetShop"
			petModel.Parent = promenadeModel
		end

		-- 6. Bistro Kafe
		local restReady = getReadyCommercialModel("Restaurant")
		if restReady then
			local rModel = instantiateReadyModel(restReady, CFrame.new(promCenterX + 4, pY, promCenterZ - 12), 11, -90)
			rModel.Name = "Shop_Restaurant"
			rModel.Parent = promenadeModel
		end
	end

	-- Sokak Mobilyaları (Banklar ve Aydınlatma Direkleri)
	CommercialBuilder.buildPromenadeLamp(promenadeModel, CFrame.new(promCenterX + 8, pY, promCenterZ + 24))
	CommercialBuilder.buildPromenadeLamp(promenadeModel, CFrame.new(promCenterX + 8, pY, promCenterZ - 4))
	CommercialBuilder.buildBench(promenadeModel, CFrame.new(promCenterX + 7, pY, promCenterZ + 18) * CFrame.Angles(0, math.rad(-90), 0))
	CommercialBuilder.buildPlanter(promenadeModel, CFrame.new(promCenterX + 8, pY, promCenterZ + 2))

	promenadeModel.Parent = parent
	return promenadeModel
end

return CommercialBuilder

--!strict
-- ============================================================================
-- BuildingBuilder.luau
-- Hazır 3D Varlık Yükleyici, Otomatik Boyutlandırma ve Kusursuz Zemin Hizalayıcı
-- Tekli Proje ve Çoklu Bina Kompleksleri (2 ila 6 Bina) Desteği
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetNormalizer = require(ReplicatedStorage.Shared.AssetNormalizer)

local BuildingBuilder = {}

-- Her seviye için tekli bina hedef genişliği (stud) ve Yaw dönüş açısı
local SINGLE_CONFIGS: { [number]: { targetWidth: number, yaw: number } } = {
	[1] = { targetWidth = 38, yaw = 0 },    -- Ahşap Kütük Kulübe (Öne bakıyor)
	[2] = { targetWidth = 48, yaw = 180 },  -- Tuğla Malikâne (Ön kapı ve garaj öne bakıyor)
	[3] = { targetWidth = 52, yaw = 90 },   -- Lüks Villa (Ana giriş ve pencereler öne bakıyor)
	[4] = { targetWidth = 50, yaw = 0 },    -- Rezidans Apartman (Ana cephe öne bakıyor)
	[5] = { targetWidth = 52, yaw = 0 },    -- Prestij Gökdelen
}

-- Çoklu bina projesinde seviyelere göre 2 ila 6 binanın yerleşim koordinatları ve boyutları
local MULTI_CONFIGS: { [number]: { count: number, targetWidth: number, yaw: number, offsets: { Vector3 } } } = {
	[1] = {
		count = 2,
		targetWidth = 24,
		yaw = 0,
		offsets = {
			Vector3.new(-14, 0, -8),
			Vector3.new(14, 0, -8),
		}
	},
	[2] = {
		count = 3,
		targetWidth = 22,
		yaw = 180,
		offsets = {
			Vector3.new(-15, 0, -16),
			Vector3.new(15, 0, -16),
			Vector3.new(0, 0, 4),
		}
	},
	[3] = {
		count = 4,
		targetWidth = 22,
		yaw = 90,
		offsets = {
			Vector3.new(-14, 0, -18),
			Vector3.new(14, 0, -18),
			Vector3.new(-14, 0, 2),
			Vector3.new(14, 0, 2),
		}
	},
	[4] = {
		count = 5,
		targetWidth = 18,
		yaw = 0,
		offsets = {
			Vector3.new(-15, 0, -20),
			Vector3.new(15, 0, -20),
			Vector3.new(-15, 0, 4),
			Vector3.new(15, 0, 4),
			Vector3.new(0, 0, -8),
		}
	},
	[5] = {
		count = 6,
		targetWidth = 18,
		yaw = 0,
		offsets = {
			Vector3.new(-15, 0, -22),
			Vector3.new(0, 0, -22),
			Vector3.new(15, 0, -22),
			Vector3.new(-15, 0, -2),
			Vector3.new(0, 0, -2),
			Vector3.new(15, 0, -2),
		}
	},
}

-- ReplicatedStorage.Assets.Buildings altındaki hazır şablonu bulur
local function getReadyModel(level: number): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then return nil end
	local buildings = assets:FindFirstChild("Buildings")
	if not buildings then return nil end

	local candidate = buildings:FindFirstChild("Level_" .. level)
	if candidate and candidate:IsA("Model") then
		local inner = candidate:FindFirstChildWhichIsA("Model")
		return inner or candidate
	end
	return nil
end

-- Tek bir bina alt modelini ölçeklendirip zemine sıfırlayarak oluşturur
local function createSingleBuilding(
	template: Model?,
	targetPos: Vector3,
	targetWidth: number,
	yawDegrees: number,
	groundY: number
): Model
	local buildingModel: Model
	if template then
		buildingModel = template:Clone()
		AssetNormalizer.Sanitize(buildingModel)

		for _, desc in ipairs(buildingModel:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Anchored = true
			end
		end

		-- 1. Gerçek 3D Dönüş İzdüşümlü Eksen Hizalı Sınır Kutusu (AABB) Hesabı
		-- Dönük parçaların (örneğin Y ekseni 90 derece döndürülmüş kiriş/mesh'ler) dikey boyutunu doğru hesaplar
		local minX, maxX = math.huge, -math.huge
		local minY, maxY = math.huge, -math.huge
		local minZ, maxZ = math.huge, -math.huge

		for _, p in ipairs(buildingModel:GetDescendants()) do
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
		local aabbSize = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)

		-- 2. Temiz, dik ve tam merkeze oturtulmuş WorldPivot ataması
		-- Bu adım, hazır varlıklardan gelen 23.5° gibi çarpık/eğri pivot açılarını anında temizler
		buildingModel.WorldPivot = CFrame.new(aabbCenter)

		-- 3. Hedef Genişliğe Göre Ölçeklendirme
		local origWidth = math.max(aabbSize.X, aabbSize.Z)
		local scale = 1
		if origWidth > 0 then
			scale = targetWidth / origWidth
			buildingModel:ScaleTo(scale)
		end

		-- 4. Hedef Konuma Yerleştirme (Zemine kusursuz oturtma ve temiz Yaw rotasyonu)
		local scaledHalfHeight = (aabbSize.Y * scale) / 2
		local targetPivotY = groundY + scaledHalfHeight
		local yawRad = math.rad(yawDegrees)
		buildingModel:PivotTo(CFrame.new(targetPos.X, targetPivotY, targetPos.Z) * CFrame.Angles(0, yawRad, 0))

		-- 5. Mikron Düzeyinde Mutlak Zemin Hizalaması (Y ekseni mikron düzeltmesi)
		local actualMinY = math.huge
		for _, p in ipairs(buildingModel:GetDescendants()) do
			if p:IsA("BasePart") then
				local pcf = p.CFrame
				local psz = p.Size
				local extY = 0.5 * (math.abs(pcf.XVector.Y) * psz.X + math.abs(pcf.YVector.Y) * psz.Y + math.abs(pcf.ZVector.Y) * psz.Z)
				actualMinY = math.min(actualMinY, pcf.Position.Y - extY)
			end
		end

		local diffY = groundY - actualMinY
		if math.abs(diffY) > 0.001 then
			buildingModel:PivotTo(buildingModel:GetPivot() + Vector3.new(0, diffY, 0))
		end

		if not buildingModel.PrimaryPart then
			buildingModel.PrimaryPart = buildingModel:FindFirstChildWhichIsA("BasePart", true)
		end
	else
		buildingModel = Instance.new("Model")
		local part = Instance.new("Part")
		part.Name = "PlaceholderFoundation"
		part.Size = Vector3.new(targetWidth, 12, targetWidth)
		part.CFrame = CFrame.new(targetPos.X, groundY + 6, targetPos.Z)
		part.Color = Color3.fromRGB(180, 180, 185)
		part.Material = Enum.Material.Concrete
		part.Anchored = true
		part.Parent = buildingModel
		buildingModel.PrimaryPart = part
	end

	return buildingModel
end

function BuildingBuilder.buildBuildingModel(
	parent: Instance,
	origin: Vector3,
	level: number,
	projectType: string?
): Model
	local groundY = origin.Y + 2 -- Zemin kotu
	local template = getReadyModel(level)

	if projectType == "MultiBuilding" then
		-- ====================================================================
		-- ÇOKLU BİNA KOMPLEKSİ (Seviye 1: 2, Seviye 2: 3, ... Seviye 5: 6 Bina)
		-- ====================================================================
		local mCfg = MULTI_CONFIGS[level] or MULTI_CONFIGS[1]
		local containerModel = Instance.new("Model")
		containerModel.Name = "BuildingModel"
		containerModel:SetAttribute("IsMultiBuilding", true)
		containerModel:SetAttribute("SubBuildingCount", #mCfg.offsets)

		local firstPrimary: BasePart? = nil

		for idx, offset in ipairs(mCfg.offsets) do
			local bPos = origin + offset
			local sub = createSingleBuilding(template, bPos, mCfg.targetWidth, mCfg.yaw, groundY)
			sub.Name = string.format("Block_%d", idx)
			sub.Parent = containerModel
			if not firstPrimary and sub.PrimaryPart then
				firstPrimary = sub.PrimaryPart
			end
		end

		containerModel.PrimaryPart = firstPrimary
		containerModel.Parent = parent
		return containerModel
	else
		-- ====================================================================
		-- TEKLİ PROJE (Standart Tek Heybetli Ana Bina)
		-- ====================================================================
		local sCfg = SINGLE_CONFIGS[level] or { targetWidth = 44, yaw = 0 }
		local singleModel = createSingleBuilding(template, origin, sCfg.targetWidth, sCfg.yaw, groundY)
		singleModel.Name = "BuildingModel"
		singleModel:SetAttribute("IsMultiBuilding", false)
		singleModel:SetAttribute("SubBuildingCount", 1)
		singleModel.Parent = parent
		return singleModel
	end
end

return BuildingBuilder

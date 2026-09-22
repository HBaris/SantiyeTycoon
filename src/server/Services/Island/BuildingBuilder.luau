--!strict
-- ============================================================================
-- BuildingBuilder.luau
-- Hazır 3D Varlık Yükleyici, Otomatik Boyutlandırma ve Kusursuz Zemin Hizalayıcı
-- (Level 1: Dağ Kulübesi, Level 2: Tuğla Malikâne, Level 3: Konsol Villa,
--  Level 4: Rezidans Apartman, Level 5: Prestij Gökdelen)
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetNormalizer = require(ReplicatedStorage.Shared.AssetNormalizer)

local BuildingBuilder = {}

-- Her seviye için ideal parsel genişliği (stud) ve oyuncuya dönük ön cephe açısı (Yaw derece)
local BUILDING_CONFIGS: { [number]: { targetWidth: number, yaw: number } } = {
	[1] = { targetWidth = 38, yaw = 0 },   -- Ahşap Kütük Kulübe (Düzgün dik cephe)
	[2] = { targetWidth = 50, yaw = 90 },  -- Tuğla Malikâne (Ön veranda ve giriş kapısı oyuncuya dönük)
	[3] = { targetWidth = 54, yaw = 90 },  -- Lüks Villa (Panoramik cam cephe ve giriş oyuncuya dönük)
	[4] = { targetWidth = 50, yaw = 0 },   -- Rezidans Apartman (Giriş cephesi yola dönük)
	[5] = { targetWidth = 54, yaw = 0 },   -- Prestij Gökdelen (Heybetli, zemine milimetrik oturan kule)
}

-- ReplicatedStorage.Assets.Buildings altındaki hazır şablonu bulur
local function getReadyModel(level: number): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then return nil end
	local buildings = assets:FindFirstChild("Buildings")
	if not buildings then return nil end

	local candidate = buildings:FindFirstChild("Level_" .. level)
	if candidate and candidate:IsA("Model") then
		-- Wrapper model varsa içindeki asıl modeli çıkar
		local inner = candidate:FindFirstChildWhichIsA("Model")
		return inner or candidate
	end
	return nil
end

function BuildingBuilder.buildBuildingModel(parent: Instance, origin: Vector3, level: number): Model
	local cfg = BUILDING_CONFIGS[level] or { targetWidth = 44, yaw = 0 }
	local template = getReadyModel(level)

	local buildingModel: Model
	if template then
		buildingModel = template:Clone()
		buildingModel.Name = "BuildingModel"
		AssetNormalizer.Sanitize(buildingModel)

		-- 1. Tüm parçaları sabitle
		for _, desc in ipairs(buildingModel:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Anchored = true
			end
		end

		-- 2. Gerçek yatay genişliği (AABB) hesapla
		local minX, maxX = math.huge, -math.huge
		local minZ, maxZ = math.huge, -math.huge
		for _, p in ipairs(buildingModel:GetDescendants()) do
			if p:IsA("BasePart") then
				minX = math.min(minX, p.Position.X - p.Size.X / 2)
				maxX = math.max(maxX, p.Position.X + p.Size.X / 2)
				minZ = math.min(minZ, p.Position.Z - p.Size.Z / 2)
				maxZ = math.max(maxZ, p.Position.Z + p.Size.Z / 2)
			end
		end

		local origWidth = math.max(maxX - minX, maxZ - minZ)
		if origWidth > 0 then
			local scale = cfg.targetWidth / origWidth
			buildingModel:ScaleTo(scale)
		end

		-- 3. Eğilmeleri sıfırla (Pitch=0, Roll=0) ve oyuncuya dönük Yaw açısını uygula
		local yawRad = math.rad(cfg.yaw)
		buildingModel:PivotTo(CFrame.new(origin.X, 0, origin.Z) * CFrame.Angles(0, yawRad, 0))

		-- 4. Mutlak Zemin Hizalama (MinY): Gökdelen veya kulübenin havada uçmasını veya batmasını engeller
		local minY = math.huge
		for _, p in ipairs(buildingModel:GetDescendants()) do
			if p:IsA("BasePart") then
				minY = math.min(minY, p.Position.Y - p.Size.Y / 2)
			end
		end

		local groundY = origin.Y + 2 -- Parsel beton platform seviyesi
		local shiftY = groundY - minY
		buildingModel:PivotTo(buildingModel:GetPivot() + Vector3.new(0, shiftY, 0))

		if not buildingModel.PrimaryPart then
			buildingModel.PrimaryPart = buildingModel:FindFirstChildWhichIsA("BasePart", true)
		end
	else
		-- Güvenlik yedeği: Hazır model silinmişse sade bir temel
		buildingModel = Instance.new("Model")
		buildingModel.Name = "BuildingModel"
		local part = Instance.new("Part")
		part.Name = "PlaceholderFoundation"
		part.Size = Vector3.new(cfg.targetWidth, 12, cfg.targetWidth)
		part.CFrame = CFrame.new(origin.X, origin.Y + 8, origin.Z)
		part.Color = Color3.fromRGB(180, 180, 185)
		part.Material = Enum.Material.Concrete
		part.Anchored = true
		part.Parent = buildingModel
		buildingModel.PrimaryPart = part
	end

	buildingModel.Parent = parent
	return buildingModel
end

return BuildingBuilder

--!strict
-- ============================================================================
-- ServiceBuildingManager.luau
-- Cities: Skylines Tarzı Yarıçap Tabanlı Hizmet Binaları (Services)
-- 🚒 İtfaiye, 🏥 Klinik, 🌳 Şehir Parkı
-- Bakım Maliyeti YOK, Sabit Yarıçap İçi Zonlara Memnuniyet Bonusu Sağlar
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local AssetNormalizer = require(ReplicatedStorage.Shared.AssetNormalizer)

export type ServiceType = "FireStation" | "Clinic" | "Park"

export type ServiceDefinition = {
	Type: ServiceType,
	Name: string,
	Icon: string,
	Cost: number,
	Radius: number,       -- studs
	HappinessBonus: number, -- % katkı (örn: 10 = +%10)
	MaxAllowedHorizontal: number,
}

local ServiceBuildingManager = {}

ServiceBuildingManager.SERVICES = {
	FireStation = {
		Type = "FireStation" :: ServiceType,
		Name = "İtfaiye İstasyonu",
		Icon = "🚒",
		Cost = 5000,
		Radius = 160,
		HappinessBonus = 10,
		MaxAllowedHorizontal = 28,
	},
	Clinic = {
		Type = "Sağlık Kliniği",
		Name = "Şehir Kliniği",
		Icon = "🏥",
		Cost = 8000,
		Radius = 160,
		HappinessBonus = 10,
		MaxAllowedHorizontal = 28,
	},
	Park = {
		Type = "Park" :: ServiceType,
		Name = "Şehir Parkı & Gazebo",
		Icon = "🌳",
		Cost = 3000,
		Radius = 120,
		HappinessBonus = 10,
		MaxAllowedHorizontal = 24,
	},
}

-- Hizmet Binası Modelini Yükle veya Fallback Üret
function ServiceBuildingManager.BuildServiceVisual(parent: Instance, serviceType: string, cf: CFrame): Model
	local def = ServiceBuildingManager.SERVICES[serviceType]
	local maxHoriz = def and def.MaxAllowedHorizontal or 24

	-- 1. ReplicatedStorage.Assets.Services İçinden Hazır Modeli Ara
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local servFolder = assets and assets:FindFirstChild("Services")
	local readyTemplate = servFolder and servFolder:FindFirstChild(serviceType)

	if readyTemplate and (readyTemplate:IsA("Model") or readyTemplate:IsA("Folder")) then
		local model: Model
		if readyTemplate:IsA("Model") then
			model = readyTemplate:Clone()
		else
			model = Instance.new("Model")
			for _, c in ipairs(readyTemplate:GetChildren()) do
				c:Clone().Parent = model
			end
		end
		model.Name = "Service_" .. serviceType

		AssetNormalizer.Normalize(model, {
			MaxHorizontalSize = maxHoriz,
			EnforceAnchored = true,
		})
		AssetNormalizer.PlaceOnGround(model, cf)
		model.Parent = parent
		return model
	end

	-- 2. Yedek Prosedürel Model (Graceful Fallback)
	local fallback = Instance.new("Model")
	fallback.Name = "Service_" .. serviceType

	local color = Color3.fromRGB(180, 50, 50)
	if serviceType == "Clinic" then
		color = Color3.fromRGB(50, 150, 220)
	elseif serviceType == "Park" then
		color = Color3.fromRGB(60, 160, 60)
	end

	local base = Instance.new("Part")
	base.Name = "ServiceBase"
	base.Size = Vector3.new(20, 1, 20)
	base.CFrame = cf * CFrame.new(0, 0.5, 0)
	base.Color = Color3.fromRGB(80, 85, 90)
	base.Material = Enum.Material.Concrete
	base.Anchored = true
	base.Parent = fallback

	local bldg = Instance.new("Part")
	bldg.Name = "ServiceBuilding"
	bldg.Size = Vector3.new(16, 12, 16)
	bldg.CFrame = cf * CFrame.new(0, 7, 0)
	bldg.Color = color
	bldg.Material = Enum.Material.Brick
	bldg.Anchored = true
	bldg.Parent = fallback

	-- Tabela
	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.new(6, 0, 2, 0)
	sign.StudsOffset = Vector3.new(0, 8, 0)
	sign.AlwaysOnTop = false
	sign.MaxDistance = 45
	sign.Parent = bldg

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 0.2
	lbl.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextScaled = true
	lbl.Text = string.format("%s %s", def and def.Icon or "🏛️", def and def.Name or serviceType)
	lbl.Parent = sign
	local cr = Instance.new("UICorner")
	cr.CornerRadius = UDim.new(0, 8)
	cr.Parent = lbl

	fallback.PrimaryPart = bldg
	fallback.Parent = parent
	return fallback
end

-- Bir Plotun Belirtilen Hizmet Binası Kapsamında Olup Olmadığını Kontrol Eder
function ServiceBuildingManager.IsCovered(servicePos: Vector3, plotPos: Vector3, serviceType: string): boolean
	local def = ServiceBuildingManager.SERVICES[serviceType]
	local radius = def and def.Radius or 120
	return (servicePos - plotPos).Magnitude <= radius
end

return ServiceBuildingManager

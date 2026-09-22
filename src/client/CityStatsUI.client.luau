--!strict
-- ============================================================================
-- CityStatsUI.client.luau
-- Cities: Skylines Şehir Yönetim Paneli ve Üst Durum Göstergesi
-- Nüfus (Population), Memnuniyet (Happiness %), Gelir Çarpanı ve Bölgeleme/Hizmet Menüsü
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local ZoneConfig = require(ReplicatedStorage.Shared.ZoneConfig)
local Network = require(ReplicatedStorage.Shared.Network)

-- 1. ScreenGui Oluştur
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CityStatsGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 15
screenGui.Parent = playerGui

-- 2. Üst Durum Çubuğu (Top Bar Dashboard - Cities: Skylines Style)
local topBar = Instance.new("Frame")
topBar.Name = "TopCityBar"
topBar.Size = UDim2.new(0, 480, 0, 44)
topBar.Position = UDim2.new(0.5, -240, 0, 14)
topBar.BackgroundColor3 = Color3.fromRGB(24, 27, 32)
topBar.BackgroundTransparency = 0.15
topBar.BorderSizePixel = 0
topBar.Parent = screenGui

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 12)
tbCorner.Parent = topBar

local tbStroke = Instance.new("UIStroke")
tbStroke.Color = Color3.fromRGB(60, 68, 78)
tbStroke.Thickness = 1.8
tbStroke.Parent = topBar

local barLayout = Instance.new("UIListLayout")
barLayout.FillDirection = Enum.FillDirection.Horizontal
barLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
barLayout.VerticalAlignment = Enum.VerticalAlignment.Center
barLayout.Padding = UDim.new(0, 10)
barLayout.Parent = topBar

-- Nüfus Rozeti
local popLabel = Instance.new("TextLabel")
popLabel.Name = "PopulationLabel"
popLabel.Size = UDim2.new(0, 110, 0, 32)
popLabel.BackgroundTransparency = 1
popLabel.Font = Enum.Font.FredokaOne
popLabel.TextSize = 14
popLabel.TextColor3 = Color3.fromRGB(240, 245, 250)
popLabel.Text = "👥 Nüfus: 25"
popLabel.Parent = topBar

-- Memnuniyet Rozeti
local happyLabel = Instance.new("TextLabel")
happyLabel.Name = "HappyLabel"
happyLabel.Size = UDim2.new(0, 130, 0, 32)
happyLabel.BackgroundTransparency = 1
happyLabel.Font = Enum.Font.FredokaOne
happyLabel.TextSize = 14
happyLabel.TextColor3 = Color3.fromRGB(100, 230, 120)
happyLabel.Text = "😊 Memnuniyet: %70"
happyLabel.Parent = topBar

-- Gelir Çarpanı Rozeti
local multLabel = Instance.new("TextLabel")
multLabel.Name = "MultiplierLabel"
multLabel.Size = UDim2.new(0, 100, 0, 32)
multLabel.BackgroundTransparency = 1
multLabel.Font = Enum.Font.FredokaOne
multLabel.TextSize = 14
multLabel.TextColor3 = Color3.fromRGB(255, 215, 60)
multLabel.Text = "📈 Çarpan: 0.70x"
multLabel.Parent = topBar

-- Şehir Yönetim Menüsü Butonu
local cityBtn = Instance.new("TextButton")
cityBtn.Name = "CityMenuBtn"
cityBtn.Size = UDim2.new(0, 95, 0, 32)
cityBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 230)
cityBtn.Text = "🏛️ YÖNETİM"
cityBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cityBtn.Font = Enum.Font.FredokaOne
cityBtn.TextSize = 13
cityBtn.BorderSizePixel = 0
cityBtn.Parent = topBar

local cbCorner = Instance.new("UICorner")
cbCorner.CornerRadius = UDim.new(0, 8)
cbCorner.Parent = cityBtn

-- ============================================================================
-- 3. ŞEHİR YÖNETİM MODAL PENCERESİ (Bölgeleme & Hizmet Binaları)
-- ============================================================================
local modalFrame = Instance.new("Frame")
modalFrame.Name = "CityManagementModal"
modalFrame.Size = UDim2.new(0, 520, 0, 420)
modalFrame.Position = UDim2.new(0.5, -260, 0.5, -210)
modalFrame.BackgroundColor3 = Color3.fromRGB(28, 32, 38)
modalFrame.BackgroundTransparency = 0.05
modalFrame.BorderSizePixel = 0
modalFrame.Visible = false
modalFrame.Parent = screenGui

local mfCorner = Instance.new("UICorner")
mfCorner.CornerRadius = UDim.new(0, 16)
mfCorner.Parent = modalFrame

local mfStroke = Instance.new("UIStroke")
mfStroke.Color = Color3.fromRGB(70, 80, 95)
mfStroke.Thickness = 2
mfStroke.Parent = modalFrame

-- Modal Başlık & Kapat Butonu
local modalTitle = Instance.new("TextLabel")
modalTitle.Size = UDim2.new(0.8, 0, 0, 45)
modalTitle.Position = UDim2.new(0.05, 0, 0, 10)
modalTitle.BackgroundTransparency = 1
modalTitle.Text = "🏛️ ŞEHİR VE İMAR YÖNETİMİ"
modalTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
modalTitle.Font = Enum.Font.FredokaOne
modalTitle.TextSize = 20
modalTitle.TextXAlignment = Enum.TextXAlignment.Left
modalTitle.Parent = modalFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -48, 0, 12)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextSize = 18
closeBtn.BorderSizePixel = 0
closeBtn.Parent = modalFrame
local clCorner = Instance.new("UICorner")
clCorner.CornerRadius = UDim.new(0, 10)
clCorner.Parent = closeBtn

-- Tab Butonları (Bölgeleme vs. Hizmetler)
local tabNav = Instance.new("Frame")
tabNav.Size = UDim2.new(0.9, 0, 0, 36)
tabNav.Position = UDim2.new(0.05, 0, 0, 60)
tabNav.BackgroundTransparency = 1
tabNav.Parent = modalFrame

local tabZoningBtn = Instance.new("TextButton")
tabZoningBtn.Size = UDim2.new(0.48, 0, 1, 0)
tabZoningBtn.Position = UDim2.new(0, 0, 0, 0)
tabZoningBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 230)
tabZoningBtn.Text = "🗺️ Parsel Bölgeleme (Zon)"
tabZoningBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tabZoningBtn.Font = Enum.Font.FredokaOne
tabZoningBtn.TextSize = 14
tabZoningBtn.BorderSizePixel = 0
tabZoningBtn.Parent = tabNav
local tzCorner = Instance.new("UICorner")
tzCorner.CornerRadius = UDim.new(0, 8)
tzCorner.Parent = tabZoningBtn

local tabServicesBtn = Instance.new("TextButton")
tabServicesBtn.Size = UDim2.new(0.48, 0, 1, 0)
tabServicesBtn.Position = UDim2.new(0.52, 0, 0, 0)
tabServicesBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 60)
tabServicesBtn.Text = "🚒 Hizmet Binaları (Services)"
tabServicesBtn.TextColor3 = Color3.fromRGB(200, 205, 215)
tabServicesBtn.Font = Enum.Font.FredokaOne
tabServicesBtn.TextSize = 14
tabServicesBtn.BorderSizePixel = 0
tabServicesBtn.Parent = tabNav
local tsCorner = Instance.new("UICorner")
tsCorner.CornerRadius = UDim.new(0, 8)
tsCorner.Parent = tabServicesBtn

-- 1. BÖLGELEME İÇERİK ALANI
local zoningContent = Instance.new("ScrollingFrame")
zoningContent.Size = UDim2.new(0.9, 0, 0, 290)
zoningContent.Position = UDim2.new(0.05, 0, 0, 110)
zoningContent.BackgroundTransparency = 1
zoningContent.BorderSizePixel = 0
zoningContent.ScrollBarThickness = 4
zoningContent.Parent = modalFrame

local zLayout = Instance.new("UIListLayout")
zLayout.FillDirection = Enum.FillDirection.Vertical
zLayout.Padding = UDim.new(0, 10)
zLayout.Parent = zoningContent

-- 2. HİZMETLER İÇERİK ALANI
local servicesContent = Instance.new("ScrollingFrame")
servicesContent.Size = UDim2.new(0.9, 0, 0, 290)
servicesContent.Position = UDim2.new(0.05, 0, 0, 110)
servicesContent.BackgroundTransparency = 1
servicesContent.BorderSizePixel = 0
servicesContent.ScrollBarThickness = 4
servicesContent.Visible = false
servicesContent.Parent = modalFrame

local sLayout = Instance.new("UIListLayout")
sLayout.FillDirection = Enum.FillDirection.Vertical
sLayout.Padding = UDim.new(0, 10)
sLayout.Parent = servicesContent

-- Tab Değiştirme
tabZoningBtn.MouseButton1Click:Connect(function()
	zoningContent.Visible = true
	servicesContent.Visible = false
	tabZoningBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 230)
	tabZoningBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	tabServicesBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 60)
	tabServicesBtn.TextColor3 = Color3.fromRGB(200, 205, 215)
end)

tabServicesBtn.MouseButton1Click:Connect(function()
	zoningContent.Visible = false
	servicesContent.Visible = true
	tabServicesBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 230)
	tabServicesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	tabZoningBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 60)
	tabZoningBtn.TextColor3 = Color3.fromRGB(200, 205, 215)
end)

-- Modal Aç/Kapat
cityBtn.MouseButton1Click:Connect(function()
	modalFrame.Visible = not modalFrame.Visible
end)

closeBtn.MouseButton1Click:Connect(function()
	modalFrame.Visible = false
end)

-- ============================================================================
-- 4. KARTLARI OLUŞTURMA VE GÜNCELLEME
-- ============================================================================

local currentActivePlot = 1
local currentCityStats = {
	Population = 0,
	Happiness = 70,
	HappinessMultiplier = 0.70,
	Zones = { Residential = 1, Commercial = 0, Industrial = 0 },
	Services = {},
}

-- Bölgeleme Kartları
local zoneTypes = { "Residential", "Commercial", "Industrial" }
local zoneCards = {}

for _, zType in ipairs(zoneTypes) do
	local zData = ZoneConfig.ZONES[zType]
	local card = Instance.new("Frame")
	card.Name = "ZoneCard_" .. zType
	card.Size = UDim2.new(1, -8, 0, 80)
	card.BackgroundColor3 = Color3.fromRGB(38, 43, 50)
	card.Parent = zoningContent
	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 10)
	cCorner.Parent = card
	local cStroke = Instance.new("UIStroke")
	cStroke.Color = zData.Color
	cStroke.Thickness = 2
	cStroke.Parent = card

	local zIcon = Instance.new("TextLabel")
	zIcon.Size = UDim2.new(0, 50, 1, 0)
	zIcon.BackgroundTransparency = 1
	zIcon.Text = zData.Icon
	zIcon.TextSize = 28
	zIcon.Parent = card

	local zTitle = Instance.new("TextLabel")
	zTitle.Size = UDim2.new(0.55, 0, 0, 24)
	zTitle.Position = UDim2.new(0, 55, 0, 10)
	zTitle.BackgroundTransparency = 1
	zTitle.Text = zData.Name
	zTitle.TextColor3 = zData.Color
	zTitle.Font = Enum.Font.FredokaOne
	zTitle.TextSize = 16
	zTitle.TextXAlignment = Enum.TextXAlignment.Left
	zTitle.Parent = card

	local zDesc = Instance.new("TextLabel")
	zDesc.Size = UDim2.new(0.55, 0, 0, 36)
	zDesc.Position = UDim2.new(0, 55, 0, 34)
	zDesc.BackgroundTransparency = 1
	zDesc.Text = zData.Description
	zDesc.TextColor3 = Color3.fromRGB(180, 185, 195)
	zDesc.Font = Enum.Font.GothamMedium
	zDesc.TextSize = 12
	zDesc.TextWrapped = true
	zDesc.TextXAlignment = Enum.TextXAlignment.Left
	zDesc.Parent = card

	local selectBtn = Instance.new("TextButton")
	selectBtn.Name = "SelectBtn"
	selectBtn.Size = UDim2.new(0, 110, 0, 44)
	selectBtn.Position = UDim2.new(1, -120, 0.5, -22)
	selectBtn.BackgroundColor3 = zData.Color
	selectBtn.Text = "BU ZONU ATA\n(2.500 İP)"
	selectBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
	selectBtn.Font = Enum.Font.FredokaOne
	selectBtn.TextSize = 12
	selectBtn.BorderSizePixel = 0
	selectBtn.Parent = card
	local sbCorner = Instance.new("UICorner")
	sbCorner.CornerRadius = UDim.new(0, 8)
	sbCorner.Parent = selectBtn

	selectBtn.MouseButton1Click:Connect(function()
		selectBtn.Text = "Uygulanıyor..."
		local success, msg = Network.SetZoneFunction:InvokeServer(currentActivePlot, zType)
		if success then
			selectBtn.Text = "✅ AKTİF"
			selectBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
		else
			selectBtn.Text = msg or "Yetersiz İP!"
			task.wait(1.5)
			selectBtn.Text = "BU ZONU ATA\n(2.500 İP)"
			selectBtn.BackgroundColor3 = zData.Color
		end
	end)

	zoneCards[zType] = { Card = card, Button = selectBtn }
end

-- Hizmet Binaları Kartları
local serviceDefs = {
	{ Type = "FireStation", Name = "İtfaiye İstasyonu", Icon = "🚒", Cost = 5000, Radius = 160, Bonus = 10, Desc = "Yangın güvenliği sağlar, geniş kapsama alanıyla şehri korur." },
	{ Type = "Clinic", Name = "Şehir Kliniği", Icon = "🏥", Cost = 8000, Radius = 160, Bonus = 10, Desc = "Temel sağlık hizmeti sunar, mahalle sakinlerinin sağlığını korur." },
	{ Type = "Park", Name = "Şehir Parkı & Gazebo", Icon = "🌳", Cost = 3000, Radius = 120, Bonus = 10, Desc = "Gezinti ve piknik alanı sunar, sakinlere huzur ve dinlenme sağlar." },
}

local serviceCards = {}

for _, sDef in ipairs(serviceDefs) do
	local card = Instance.new("Frame")
	card.Name = "ServiceCard_" .. sDef.Type
	card.Size = UDim2.new(1, -8, 0, 80)
	card.BackgroundColor3 = Color3.fromRGB(38, 43, 50)
	card.Parent = servicesContent
	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 10)
	cCorner.Parent = card

	local sIcon = Instance.new("TextLabel")
	sIcon.Size = UDim2.new(0, 50, 1, 0)
	sIcon.BackgroundTransparency = 1
	sIcon.Text = sDef.Icon
	sIcon.TextSize = 28
	sIcon.Parent = card

	local sTitle = Instance.new("TextLabel")
	sTitle.Size = UDim2.new(0.55, 0, 0, 24)
	sTitle.Position = UDim2.new(0, 55, 0, 10)
	sTitle.BackgroundTransparency = 1
	sTitle.Text = string.format("%s (+%%%d Memnuniyet)", sDef.Name, sDef.Bonus)
	sTitle.TextColor3 = Color3.fromRGB(240, 245, 250)
	sTitle.Font = Enum.Font.FredokaOne
	sTitle.TextSize = 15
	sTitle.TextXAlignment = Enum.TextXAlignment.Left
	sTitle.Parent = card

	local sDesc = Instance.new("TextLabel")
	sDesc.Size = UDim2.new(0.55, 0, 0, 36)
	sDesc.Position = UDim2.new(0, 55, 0, 34)
	sDesc.BackgroundTransparency = 1
	sDesc.Text = string.format("%s (Yarıçap: %d stud)", sDef.Desc, sDef.Radius)
	sDesc.TextColor3 = Color3.fromRGB(180, 185, 195)
	sDesc.Font = Enum.Font.GothamMedium
	sDesc.TextSize = 12
	sDesc.TextWrapped = true
	sDesc.TextXAlignment = Enum.TextXAlignment.Left
	sDesc.Parent = card

	local buyBtn = Instance.new("TextButton")
	buyBtn.Name = "BuyServiceBtn"
	buyBtn.Size = UDim2.new(0, 110, 0, 44)
	buyBtn.Position = UDim2.new(1, -120, 0.5, -22)
	buyBtn.BackgroundColor3 = Color3.fromRGB(255, 185, 45)
	buyBtn.Text = string.format("İNŞA ET\n%s", NumberFormat.FormatCash(sDef.Cost))
	buyBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
	buyBtn.Font = Enum.Font.FredokaOne
	buyBtn.TextSize = 12
	buyBtn.BorderSizePixel = 0
	buyBtn.Parent = card
	local bbCorner = Instance.new("UICorner")
	bbCorner.CornerRadius = UDim.new(0, 8)
	bbCorner.Parent = buyBtn

	buyBtn.MouseButton1Click:Connect(function()
		buyBtn.Text = "İnşa Ediliyor..."
		local success, msg = Network.BuildServiceFunction:InvokeServer(sDef.Type, currentActivePlot)
		if success then
			buyBtn.Text = "✅ AKTİF"
			buyBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
		else
			buyBtn.Text = msg or "Yetersiz İP!"
			task.wait(1.5)
			buyBtn.Text = string.format("İNŞA ET\n%s", NumberFormat.FormatCash(sDef.Cost))
			buyBtn.BackgroundColor3 = Color3.fromRGB(255, 185, 45)
		end
	end)

	serviceCards[sDef.Type] = { Card = card, Button = buyBtn }
end

-- ============================================================================
-- 5. SUNUCUDAN İSTATİSTİK SENKRONİZASYONU
-- ============================================================================
local function updateDisplay(stats: any)
	if not stats then return end
	currentCityStats = stats

	popLabel.Text = string.format("👥 Nüfus: %s", NumberFormat.FormatCompact(stats.Population or 0))
	local happy = stats.Happiness or 70
	happyLabel.Text = string.format("😊 Memnuniyet: %%%d", happy)
	if happy >= 80 then
		happyLabel.TextColor3 = Color3.fromRGB(80, 240, 120)
	elseif happy >= 60 then
		happyLabel.TextColor3 = Color3.fromRGB(245, 210, 60)
	else
		happyLabel.TextColor3 = Color3.fromRGB(245, 90, 90)
	end

	local mult = stats.HappinessMultiplier or 0.70
	multLabel.Text = string.format("📈 Çarpan: %.2fx", mult)

	-- Hizmet binaları buton durumunu güncelle
	if stats.Services then
		for sType, cardData in pairs(serviceCards) do
			if stats.Services[sType] then
				cardData.Button.Text = "✅ AKTİF"
				cardData.Button.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
			end
		end
	end
end

Network.SyncCityStatsEvent.OnClientEvent:Connect(updateDisplay)

print("[CityStatsUI] Cities: Skylines Üst Durum Paneli ve Yönetim Menüsü Başlatıldı.")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Network = require(ReplicatedStorage.Shared.Network)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)

local selectedVehicleId = "Scooter"
local currentCash = 0
local currentCrystals = 25
local vehicleUpgrades = {
	Scooter = { Speed = 0, Torque = 0, Cargo = 0 },
	Motorcycle = { Speed = 0, Torque = 0, Cargo = 0 },
	Car = { Speed = 0, Torque = 0, Cargo = 0 },
}

local GarageUI = {}

local function playSfx(soundPath: string, volume: number?, pitch: number?)
	if not soundPath or soundPath == "" then return end
	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = soundPath
		sound.Volume = volume or 0.3
		sound.PlaybackSpeed = pitch or 1.0
		sound.Parent = SoundService
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end)
end

-- ============================================================================
-- ARAYÜZ ELEMANLARI (GARAJ & MODİFİYE)
-- ============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GarageScreenGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Sol Hızlı Açma Butonu (🚗 GARAJ & MODİFİYE)
local garageToggleBtn = Instance.new("TextButton")
garageToggleBtn.Name = "GarageToggleBtn"
garageToggleBtn.Size = UDim2.new(0, 180, 0, 50)
garageToggleBtn.Position = UDim2.new(0, 20, 0.55, 0)
garageToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 240)
garageToggleBtn.Text = "🚗 GARAJ & MODİFİYE"
garageToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
garageToggleBtn.Font = Enum.Font.FredokaOne
garageToggleBtn.TextSize = 15
garageToggleBtn.BorderSizePixel = 0
garageToggleBtn.Parent = screenGui

local gtCorner = Instance.new("UICorner")
gtCorner.CornerRadius = UDim.new(0, 14)
gtCorner.Parent = garageToggleBtn

local gtStroke = Instance.new("UIStroke")
gtStroke.Color = Color3.fromRGB(20, 90, 180)
gtStroke.Thickness = 3
gtStroke.Parent = garageToggleBtn

-- Ana Modal Çerçevesi
local modal = Instance.new("Frame")
modal.Name = "GarageModal"
modal.Size = UDim2.new(0, 620, 0, 640)
modal.Position = UDim2.new(0.5, -310, 0.5, -320)
modal.BackgroundColor3 = Color3.fromRGB(248, 250, 252)
modal.BorderSizePixel = 0
modal.ClipsDescendants = true
modal.Visible = false
modal.Parent = screenGui

local mCorner = Instance.new("UICorner")
mCorner.CornerRadius = UDim.new(0, 20)
mCorner.Parent = modal

local mStroke = Instance.new("UIStroke")
mStroke.Color = Color3.fromRGB(30, 120, 220)
mStroke.Thickness = 4
mStroke.Parent = modal

-- Başlık Çubuğu
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 75)
header.BackgroundColor3 = Color3.fromRGB(35, 125, 225)
header.BorderSizePixel = 0
header.Parent = modal

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0.8, 0, 0.6, 0)
titleText.Position = UDim2.new(0.04, 0, 0.15, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "🛠️ MÜTEAHHİT GARAJI & MODİFİYE"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.FredokaOne
titleText.TextSize = 22
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = header

local subTitle = Instance.new("TextLabel")
subTitle.Size = UDim2.new(0.8, 0, 0.3, 0)
subTitle.Position = UDim2.new(0.04, 0, 0.65, 0)
subTitle.BackgroundTransparency = 1
subTitle.Text = "Araçların hızını, torkunu ve kargo kapasitesini geliştir!"
subTitle.TextColor3 = Color3.fromRGB(220, 240, 255)
subTitle.Font = Enum.Font.GothamMedium
subTitle.TextSize = 12
subTitle.TextXAlignment = Enum.TextXAlignment.Left
subTitle.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 42, 0, 42)
closeBtn.Position = UDim2.new(1, -54, 0.5, -21)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextSize = 20
closeBtn.BorderSizePixel = 0
closeBtn.Parent = header
local cbCorner = Instance.new("UICorner")
cbCorner.CornerRadius = UDim.new(1, 0)
cbCorner.Parent = closeBtn

-- Araç Seçim Sekmeleri (Scooter, Motor, Kamyonet)
local vehicleTabHolder = Instance.new("Frame")
vehicleTabHolder.Name = "VehicleTabs"
vehicleTabHolder.Size = UDim2.new(0.92, 0, 0, 56)
vehicleTabHolder.Position = UDim2.new(0.04, 0, 0, 88)
vehicleTabHolder.BackgroundColor3 = Color3.fromRGB(230, 235, 242)
vehicleTabHolder.BorderSizePixel = 0
vehicleTabHolder.Parent = modal
local vthCorner = Instance.new("UICorner")
vthCorner.CornerRadius = UDim.new(0, 14)
vthCorner.Parent = vehicleTabHolder

local vehicleTabButtons = {}
local vOrder = { "Scooter", "Motorcycle", "Car" }
local tabWidth = 1 / #vOrder

for i, vId in ipairs(vOrder) do
	local vData = GameConfig.VEHICLES[vId]
	local btn = Instance.new("TextButton")
	btn.Name = "Tab_" .. vId
	btn.Size = UDim2.new(tabWidth, -6, 1, -8)
	btn.Position = UDim2.new((i - 1) * tabWidth, 3, 0, 4)
	btn.BackgroundColor3 = (vId == selectedVehicleId) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(230, 235, 242)
	btn.Text = string.format("%s %s", vData.Icon, vData.Name)
	btn.TextColor3 = (vId == selectedVehicleId) and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(100, 105, 115)
	btn.Font = Enum.Font.FredokaOne
	btn.TextSize = 13
	btn.BorderSizePixel = 0
	btn.Parent = vehicleTabHolder

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 10)
	bCorner.Parent = btn

	vehicleTabButtons[vId] = btn

	btn.MouseButton1Click:Connect(function()
		selectedVehicleId = vId

		for otherId, otherBtn in pairs(vehicleTabButtons) do
			local isSelected = (otherId == selectedVehicleId)
			otherBtn.BackgroundColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(230, 235, 242)
			otherBtn.TextColor3 = isSelected and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(100, 105, 115)
		end
		GarageUI.Refresh()
	end)
end

-- Araç Özet Kartı
local summaryCard = Instance.new("Frame")
summaryCard.Name = "SummaryCard"
summaryCard.Size = UDim2.new(0.92, 0, 0, 95)
summaryCard.Position = UDim2.new(0.04, 0, 0, 154)
summaryCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
summaryCard.BorderSizePixel = 0
summaryCard.Parent = modal
local scCorner = Instance.new("UICorner")
scCorner.CornerRadius = UDim.new(0, 14)
scCorner.Parent = summaryCard
local scStroke = Instance.new("UIStroke")
scStroke.Color = Color3.fromRGB(220, 225, 235)
scStroke.Thickness = 2
scStroke.Parent = summaryCard

local summaryIcon = Instance.new("TextLabel")
summaryIcon.Size = UDim2.new(0, 70, 0, 70)
summaryIcon.Position = UDim2.new(0, 12, 0.5, -35)
summaryIcon.BackgroundTransparency = 1
summaryIcon.Text = "🛴"
summaryIcon.TextSize = 48
summaryIcon.Parent = summaryCard

local summaryTitle = Instance.new("TextLabel")
summaryTitle.Size = UDim2.new(0.5, 0, 0.35, 0)
summaryTitle.Position = UDim2.new(0, 90, 0, 14)
summaryTitle.BackgroundTransparency = 1
summaryTitle.Text = "Şantiye Scooter'ı"
summaryTitle.TextColor3 = Color3.fromRGB(20, 20, 20)
summaryTitle.Font = Enum.Font.FredokaOne
summaryTitle.TextSize = 18
summaryTitle.TextXAlignment = Enum.TextXAlignment.Left
summaryTitle.Parent = summaryCard

local summaryDesc = Instance.new("TextLabel")
summaryDesc.Size = UDim2.new(0.55, 0, 0.45, 0)
summaryDesc.Position = UDim2.new(0, 90, 0, 42)
summaryDesc.BackgroundTransparency = 1
summaryDesc.Text = "Hızlı ve kıvrak başlangıç taşıtı."
summaryDesc.TextColor3 = Color3.fromRGB(110, 115, 125)
summaryDesc.Font = Enum.Font.GothamMedium
summaryDesc.TextSize = 11
summaryDesc.TextWrapped = true
summaryDesc.TextXAlignment = Enum.TextXAlignment.Left
summaryDesc.Parent = summaryCard

local spawnActionBtn = Instance.new("TextButton")
spawnActionBtn.Name = "SpawnActionBtn"
spawnActionBtn.Size = UDim2.new(0, 120, 0, 44)
spawnActionBtn.Position = UDim2.new(1, -135, 0.5, -22)
spawnActionBtn.BackgroundColor3 = Color3.fromRGB(46, 175, 80)
spawnActionBtn.Text = "Taşıta Bin"
spawnActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnActionBtn.Font = Enum.Font.FredokaOne
spawnActionBtn.TextSize = 14
spawnActionBtn.BorderSizePixel = 0
spawnActionBtn.Parent = summaryCard
local sabCorner = Instance.new("UICorner")
sabCorner.CornerRadius = UDim.new(0, 10)
sabCorner.Parent = spawnActionBtn

-- Geliştirme Listesi (Speed, Torque, Cargo)
local scrollList = Instance.new("ScrollingFrame")
scrollList.Name = "UpgradesScroll"
scrollList.Size = UDim2.new(0.92, 0, 0, 360)
scrollList.Position = UDim2.new(0.04, 0, 0, 260)
scrollList.BackgroundTransparency = 1
scrollList.BorderSizePixel = 0
scrollList.ScrollBarThickness = 6
scrollList.CanvasSize = UDim2.new(0, 0, 0, 360)
scrollList.Parent = modal

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 12)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollList

-- Geliştirme Kartı Şablonu Üreticisi
local upgradeCards = {}
local upgradeKeys = { "Speed", "Torque", "Cargo" }

for i, uKey in ipairs(upgradeKeys) do
	local uData = GameConfig.VEHICLE_UPGRADES[uKey]
	local card = Instance.new("Frame")
	card.Name = "Card_" .. uKey
	card.Size = UDim2.new(1, 0, 0, 105)
	card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	card.BorderSizePixel = 0
	card.LayoutOrder = i
	card.Parent = scrollList

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 14)
	cCorner.Parent = card
	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(230, 235, 240)
	cStroke.Thickness = 2
	cStroke.Parent = card

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size = UDim2.new(0, 48, 0, 48)
	iconLbl.Position = UDim2.new(0, 14, 0, 16)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Text = uData.Icon
	iconLbl.TextSize = 34
	iconLbl.Parent = card

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "UpgradeName"
	nameLbl.Size = UDim2.new(0.5, 0, 0, 22)
	nameLbl.Position = UDim2.new(0, 72, 0, 14)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = uData.Name
	nameLbl.TextColor3 = Color3.fromRGB(20, 20, 20)
	nameLbl.Font = Enum.Font.FredokaOne
	nameLbl.TextSize = 16
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Parent = card

	local statLbl = Instance.new("TextLabel")
	statLbl.Name = "StatComparison"
	statLbl.Size = UDim2.new(0.5, 0, 0, 18)
	statLbl.Position = UDim2.new(0, 72, 0, 38)
	statLbl.BackgroundTransparency = 1
	statLbl.Text = "28 -> 34 km/s"
	statLbl.TextColor3 = Color3.fromRGB(40, 140, 240)
	statLbl.Font = Enum.Font.FredokaOne
	statLbl.TextSize = 13
	statLbl.TextXAlignment = Enum.TextXAlignment.Left
	statLbl.Parent = card

	-- Seviye İlerleme Çubuğu
	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(0.5, 0, 0, 12)
	barBg.Position = UDim2.new(0, 72, 0, 68)
	barBg.BackgroundColor3 = Color3.fromRGB(230, 235, 240)
	barBg.BorderSizePixel = 0
	barBg.Parent = card
	local bbc = Instance.new("UICorner")
	bbc.CornerRadius = UDim.new(1, 0)
	bbc.Parent = barBg

	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	barFill.Size = UDim2.new(0.2, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(46, 175, 80)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	local bfc = Instance.new("UICorner")
	bfc.CornerRadius = UDim.new(1, 0)
	bfc.Parent = barFill

	local levelText = Instance.new("TextLabel")
	levelText.Name = "LevelText"
	levelText.Size = UDim2.new(0, 60, 0, 18)
	levelText.Position = UDim2.new(0.52, 10, 0, 65)
	levelText.BackgroundTransparency = 1
	levelText.Text = "Lv. 1/5"
	levelText.TextColor3 = Color3.fromRGB(110, 115, 125)
	levelText.Font = Enum.Font.FredokaOne
	levelText.TextSize = 11
	levelText.TextXAlignment = Enum.TextXAlignment.Left
	levelText.Parent = card

	-- Satın Al / Yükselt Butonu
	local upgradeBtn = Instance.new("TextButton")
	upgradeBtn.Name = "UpgradeBtn"
	upgradeBtn.Size = UDim2.new(0, 130, 0, 48)
	upgradeBtn.Position = UDim2.new(1, -145, 0.5, -24)
	upgradeBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 20)
	upgradeBtn.Text = "YÜKSELT\n350 İP"
	upgradeBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
	upgradeBtn.Font = Enum.Font.FredokaOne
	upgradeBtn.TextSize = 13
	upgradeBtn.BorderSizePixel = 0
	upgradeBtn.Parent = card
	local ubCorner = Instance.new("UICorner")
	ubCorner.CornerRadius = UDim.new(0, 12)
	ubCorner.Parent = upgradeBtn

	upgradeBtn.MouseButton1Click:Connect(function()
		Network.UpgradeVehicleEvent:FireServer(selectedVehicleId, uKey)
	end)

	upgradeCards[uKey] = {
		Card = card,
		StatLabel = statLbl,
		BarFill = barFill,
		LevelText = levelText,
		UpgradeButton = upgradeBtn,
	}
end

-- ============================================================================
-- ARAYÜZ YENİLEME & SENKRONİZASYON
-- ============================================================================
function GarageUI.Refresh()
	local vData = GameConfig.VEHICLES[selectedVehicleId] or GameConfig.VEHICLES.Scooter
	summaryIcon.Text = vData.Icon
	summaryTitle.Text = vData.Name
	summaryDesc.Text = vData.Desc

	local currentVUpgrades = vehicleUpgrades[selectedVehicleId] or { Speed = 0, Torque = 0, Cargo = 0 }

	for _, uKey in ipairs(upgradeKeys) do
		local uData = GameConfig.VEHICLE_UPGRADES[uKey]
		local ui = upgradeCards[uKey]
		local curLvl = currentVUpgrades[uKey] or 0
		local maxLvl = uData.MaxLevel

		local frac = math.clamp(curLvl / maxLvl, 0, 1)
		ui.BarFill.Size = UDim2.new(frac, 0, 1, 0)
		ui.LevelText.Text = string.format("Lv. %d/%d", curLvl, maxLvl)

		if curLvl >= maxLvl then
			ui.UpgradeButton.Text = "MAKSİMUM"
			ui.UpgradeButton.BackgroundColor3 = Color3.fromRGB(210, 215, 220)
			ui.UpgradeButton.TextColor3 = Color3.fromRGB(120, 125, 130)
			ui.StatLabel.Text = "En Yüksek Seviye 🌟"
		else
			local cost = GameConfig.GetVehicleUpgradeCost(uKey, curLvl)
			local costStr = (uData.Currency == "Cash") and NumberFormat.FormatCash(cost) or string.format("%d 💎", cost)
			ui.UpgradeButton.Text = string.format("YÜKSELT\n%s", costStr)
			ui.UpgradeButton.BackgroundColor3 = Color3.fromRGB(255, 180, 20)
			ui.UpgradeButton.TextColor3 = Color3.fromRGB(20, 20, 20)

			-- Stat karşılaştırması
			if uKey == "Speed" then
				local curSpd = vData.Speed + (curLvl * uData.BonusPerLevel)
				local nextSpd = vData.Speed + ((curLvl + 1) * uData.BonusPerLevel)
				ui.StatLabel.Text = string.format("%d -> %d km/s (Azami Hız)", curSpd, nextSpd)
			elseif uKey == "Torque" then
				local baseT = (selectedVehicleId == "Scooter" and 15) or (selectedVehicleId == "Motorcycle" and 25) or 40
				local curT = baseT + (curLvl * uData.BonusPerLevel)
				local nextT = baseT + ((curLvl + 1) * uData.BonusPerLevel)
				ui.StatLabel.Text = string.format("%d -> %d Tork (Hızlanma)", curT, nextT)
			elseif uKey == "Cargo" then
				local curC = math.floor(vData.CargoCapacity * (1.0 + (curLvl * uData.BonusMultiplierPerLevel)))
				local nextC = math.floor(vData.CargoCapacity * (1.0 + ((curLvl + 1) * uData.BonusMultiplierPerLevel)))
				ui.StatLabel.Text = string.format("%d -> %d Malzeme (Kapasite)", curC, nextC)
			end
		end
	end
end

spawnActionBtn.MouseButton1Click:Connect(function()
	Network.SpawnVehicleEvent:FireServer(selectedVehicleId)
	modal.Visible = false
end)

closeBtn.MouseButton1Click:Connect(function()
	modal.Visible = false
end)

garageToggleBtn.MouseButton1Click:Connect(function()
	modal.Visible = not modal.Visible
	if modal.Visible then
		GarageUI.Refresh()
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.G then
		modal.Visible = not modal.Visible
		if modal.Visible then
			GarageUI.Refresh()
		end
	end
end)

-- Ağ Senkronizasyon Olayları
Network.SyncVehicleUpgradesEvent.OnClientEvent:Connect(function(vId: string, upgrades: any)
	if vId and type(upgrades) == "table" then
		vehicleUpgrades[vId] = upgrades
		if modal.Visible then
			GarageUI.Refresh()
		end
	end
end)

Network.SyncResourcesEvent.OnClientEvent:Connect(function(cash: number, crystals: number, engineers: number)
	currentCash = cash or currentCash
	currentCrystals = crystals or currentCrystals
	if modal.Visible then
		GarageUI.Refresh()
	end
end)

Network.OpenGarageEvent.OnClientEvent:Connect(function()
	modal.Visible = true
	GarageUI.Refresh()
end)

GarageUI.Refresh()

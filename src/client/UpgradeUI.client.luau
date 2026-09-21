local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Network = require(ReplicatedStorage.Shared.Network)
local UpgradeConfig = require(ReplicatedStorage.Shared.UpgradeConfig)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)

local activeTab = "Cash"
local currentCash = 0
local currentCrystals = 25
local currentEngineers = 0.0
local playerUpgrades = {
	Cash = {},
	Crystals = {},
	Engineers = {},
}

local function playSfx(soundPath: string, volume: number?, pitch: number?)
	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = soundPath
		sound.Volume = volume or 0.4
		sound.PlaybackSpeed = pitch or 1.0
		sound.Parent = SoundService
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end)
end

-- ============================================================================
-- ARAYÜZ ELEMANLARINI OLUŞTURMA
-- ============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UpgradeScreenGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- 1. Sol Kenar Hızlı Açma Butonu (🛠️ YÜKSELTMELER)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "UpgradeToggleBtn"
toggleBtn.Size = UDim2.new(0, 180, 0, 52)
toggleBtn.Position = UDim2.new(0, 20, 0.45, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 195, 45)
toggleBtn.Text = "🛠️ YÜKSELTMELER"
toggleBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
toggleBtn.Font = Enum.Font.FredokaOne
toggleBtn.TextSize = 16
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = screenGui

local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(0, 14)
tCorner.Parent = toggleBtn

local tStroke = Instance.new("UIStroke")
tStroke.Color = Color3.fromRGB(190, 120, 0)
tStroke.Thickness = 3
tStroke.Parent = toggleBtn

-- Buton Rozeti (Satın Alınabilir Toplam Sayı)
local toggleBadge = Instance.new("TextLabel")
toggleBadge.Name = "Badge"
toggleBadge.Size = UDim2.new(0, 24, 0, 24)
toggleBadge.Position = UDim2.new(1, -12, 0, -8)
toggleBadge.BackgroundColor3 = Color3.fromRGB(235, 50, 50)
toggleBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBadge.Font = Enum.Font.FredokaOne
toggleBadge.TextSize = 13
toggleBadge.Text = "0"
toggleBadge.Visible = false
toggleBadge.Parent = toggleBtn

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(1, 0)
tbCorner.Parent = toggleBadge

-- 2. Ana Modal Çerçevesi
local modal = Instance.new("Frame")
modal.Name = "UpgradeModal"
modal.Size = UDim2.new(0, 580, 0, 620)
modal.Position = UDim2.new(0.5, -290, 0.5, -310)
modal.BackgroundColor3 = Color3.fromRGB(250, 248, 242)
modal.BorderSizePixel = 0
modal.ClipsDescendants = true
modal.Visible = false
modal.Parent = screenGui

local mCorner = Instance.new("UICorner")
mCorner.CornerRadius = UDim.new(0, 20)
mCorner.Parent = modal

local mStroke = Instance.new("UIStroke")
mStroke.Color = Color3.fromRGB(210, 195, 175)
mStroke.Thickness = 3.5
mStroke.Parent = modal

-- Başlık Çubuğu
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 64)
header.BackgroundColor3 = Color3.fromRGB(240, 235, 225)
header.BorderSizePixel = 0
header.Parent = modal

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.6, 0, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🏗️ ŞANTİYE TEKNOLOJİLERİ"
title.TextColor3 = Color3.fromRGB(20, 20, 20)
title.Font = Enum.Font.FredokaOne
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Kapat Butonu (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 38, 0, 38)
closeBtn.Position = UDim2.new(1, -48, 0, 13)
closeBtn.BackgroundColor3 = Color3.fromRGB(235, 225, 215)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(40, 40, 40)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextSize = 20
closeBtn.BorderSizePixel = 0
closeBtn.Parent = header

local cCorner = Instance.new("UICorner")
cCorner.CornerRadius = UDim.new(0, 10)
cCorner.Parent = closeBtn

-- 3. Üst Bakiye Göstergeleri (Kasa, Kristal, Mühendis)
local resourceBar = Instance.new("Frame")
resourceBar.Name = "ResourceBar"
resourceBar.Size = UDim2.new(1, -40, 0, 36)
resourceBar.Position = UDim2.new(0, 20, 0, 72)
resourceBar.BackgroundColor3 = Color3.fromRGB(245, 240, 230)
resourceBar.BorderSizePixel = 0
resourceBar.Parent = modal

local rbCorner = Instance.new("UICorner")
rbCorner.CornerRadius = UDim.new(0, 10)
rbCorner.Parent = resourceBar

local resLayout = Instance.new("UIListLayout")
resLayout.FillDirection = Enum.FillDirection.Horizontal
resLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
resLayout.VerticalAlignment = Enum.VerticalAlignment.Center
resLayout.Padding = UDim.new(0, 18)
resLayout.Parent = resourceBar

local cashLabel = Instance.new("TextLabel")
cashLabel.Size = UDim2.new(0, 150, 1, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.Text = "💰 0 $"
cashLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
cashLabel.Font = Enum.Font.FredokaOne
cashLabel.TextSize = 15
cashLabel.Parent = resourceBar

local crystalLabel = Instance.new("TextLabel")
crystalLabel.Size = UDim2.new(0, 130, 1, 0)
crystalLabel.BackgroundTransparency = 1
crystalLabel.Text = "💎 0"
crystalLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
crystalLabel.Font = Enum.Font.FredokaOne
crystalLabel.TextSize = 15
crystalLabel.Parent = resourceBar

local engineerLabel = Instance.new("TextLabel")
engineerLabel.Size = UDim2.new(0, 140, 1, 0)
engineerLabel.BackgroundTransparency = 1
engineerLabel.Text = "👷 0.00"
engineerLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
engineerLabel.Font = Enum.Font.FredokaOne
engineerLabel.TextSize = 15
engineerLabel.Parent = resourceBar

-- 4. 3 SEKME BAŞLIKLARI (💰 Para | 💎 Kristal | 👷 Mühendis)
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -40, 0, 48)
tabBar.Position = UDim2.new(0, 20, 0, 116)
tabBar.BackgroundTransparency = 1
tabBar.Parent = modal

local tabButtons = {}
local tabBadges = {}

local tabOrder = { "Cash", "Crystals", "Engineers" }
local tabWidth = (580 - 40 - 20) / 3

for i, tabKey in ipairs(tabOrder) do
	local tData = UpgradeConfig.TABS[tabKey]
	local btn = Instance.new("TextButton")
	btn.Name = "Tab_" .. tabKey
	btn.Size = UDim2.new(0, tabWidth, 1, 0)
	btn.Position = UDim2.new(0, (i - 1) * (tabWidth + 10), 0, 0)
	btn.BackgroundColor3 = (tabKey == activeTab) and tData.Color or Color3.fromRGB(230, 225, 218)
	btn.Text = string.format("%s %s", tData.Icon, tData.Name)
	btn.TextColor3 = Color3.fromRGB(20, 20, 20)
	btn.Font = Enum.Font.FredokaOne
	btn.TextSize = 15
	btn.BorderSizePixel = 0
	btn.Parent = tabBar

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 12)
	bCorner.Parent = btn

	-- Kırmızı Yuvarlak Rozet (Satın Alınabilir Sayı)
	local badge = Instance.new("TextLabel")
	badge.Name = "Badge"
	badge.Size = UDim2.new(0, 22, 0, 22)
	badge.Position = UDim2.new(1, -11, 0, -6)
	badge.BackgroundColor3 = Color3.fromRGB(235, 45, 45)
	badge.TextColor3 = Color3.fromRGB(255, 255, 255)
	badge.Font = Enum.Font.FredokaOne
	badge.TextSize = 12
	badge.Text = "0"
	badge.Visible = false
	badge.Parent = btn

	local bdCorner = Instance.new("UICorner")
	bdCorner.CornerRadius = UDim.new(1, 0)
	bdCorner.Parent = badge

	tabButtons[tabKey] = btn
	tabBadges[tabKey] = badge
end

-- 5. Yükseltme Kartları Kaydırılabilir Alanı (Cards Container)
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "CardsList"
scrollFrame.Size = UDim2.new(1, -40, 1, -240)
scrollFrame.Position = UDim2.new(0, 20, 0, 172)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 170, 160)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 480)
scrollFrame.Parent = modal

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 12)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

-- 6. Alt Bölüm: Reklamla Kristal Kazan Butonu (Sadece Kristal Sekmesinde)
local adRewardBtn = Instance.new("TextButton")
adRewardBtn.Name = "AdRewardBtn"
adRewardBtn.Size = UDim2.new(1, -40, 0, 46)
adRewardBtn.Position = UDim2.new(0, 20, 1, -58)
adRewardBtn.BackgroundColor3 = Color3.fromRGB(120, 215, 255)
adRewardBtn.Text = "📺 HIZLI KRİSTAL KAZAN (+10 💎)"
adRewardBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
adRewardBtn.Font = Enum.Font.FredokaOne
adRewardBtn.TextSize = 15
adRewardBtn.BorderSizePixel = 0
adRewardBtn.Visible = false
adRewardBtn.Parent = modal

local adCorner = Instance.new("UICorner")
adCorner.CornerRadius = UDim.new(0, 12)
adCorner.Parent = adRewardBtn

local adStroke = Instance.new("UIStroke")
adStroke.Color = Color3.fromRGB(40, 150, 210)
adStroke.Thickness = 2.5
adStroke.Parent = adRewardBtn

adRewardBtn.MouseButton1Click:Connect(function()
	playSfx("rbxasset://sounds/electronicpingshort.wav", 0.5, 1.2)
	Network.ClaimAdRewardEvent:FireServer()
end)

-- ============================================================================
-- KARTLARI VE ROZETLERİ GÜNCELLEME MOTORU
-- ============================================================================
local cardInstances = {}

local function getResourceBalance(tabName: string): number
	if tabName == "Cash" then
		return currentCash
	elseif tabName == "Crystals" then
		return currentCrystals
	elseif tabName == "Engineers" then
		return currentEngineers
	end
	return 0
end

local function updateUI()
	-- 1. Bakiye Sayaçlarını Güncelle
	cashLabel.Text = NumberFormat.FormatCash(currentCash)
	crystalLabel.Text = NumberFormat.FormatCrystals(currentCrystals)
	engineerLabel.Text = NumberFormat.FormatEngineers(currentEngineers)

	-- 2. Her Sekme İçin Satın Alınabilir Sayısını Hesapla ve Rozetleri Güncelle
	local totalAffordableAll = 0

	for _, tabKey in ipairs(tabOrder) do
		local balance = getResourceBalance(tabKey)
		local count = 0
		local tabDef = UpgradeConfig.DEFINITIONS[tabKey]

		if tabDef then
			for catId, _ in pairs(UpgradeConfig.CATEGORIES) do
				local currentLvl = (playerUpgrades[tabKey] and playerUpgrades[tabKey][catId]) or 0
				local cost = UpgradeConfig.GetCost(tabKey, catId, currentLvl)
				if balance >= cost then
					count += 1
				end
			end
		end

		totalAffordableAll += count
		local badge = tabBadges[tabKey]
		if badge then
			badge.Text = tostring(count)
			badge.Visible = count > 0
		end
	end

	-- Sol kenar buton rozeti
	toggleBadge.Text = tostring(totalAffordableAll)
	toggleBadge.Visible = totalAffordableAll > 0

	-- 3. Sekme Başlık Renkleri
	for tabKey, btn in pairs(tabButtons) do
		local tData = UpgradeConfig.TABS[tabKey]
		if tabKey == activeTab then
			btn.BackgroundColor3 = tData.Color
		else
			btn.BackgroundColor3 = Color3.fromRGB(230, 225, 218)
		end
	end

	-- Reklam butonu görünürlüğü (yalnızca kristal sekmesinde)
	adRewardBtn.Visible = (activeTab == "Crystals")

	-- 4. Aktif Sekmenin 4 Kategori Kartını Oluştur / Güncelle
	local catOrder = { "Income", "Discount", "Capacity", "Speed" }
	local currentBalance = getResourceBalance(activeTab)

	for i, catId in ipairs(catOrder) do
		local catDef = UpgradeConfig.CATEGORIES[catId]
		local currentLvl = (playerUpgrades[activeTab] and playerUpgrades[activeTab][catId]) or 0
		local info = UpgradeConfig.GetTechInfo(activeTab, catId, currentLvl)

		local card = cardInstances[catId]
		if not card then
			card = Instance.new("Frame")
			card.Name = "Card_" .. catId
			card.Size = UDim2.new(1, 0, 0, 100)
			card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			card.BorderSizePixel = 0
			card.LayoutOrder = i
			card.Parent = scrollFrame

			local cdCorner = Instance.new("UICorner")
			cdCorner.CornerRadius = UDim.new(0, 14)
			cdCorner.Parent = card

			local cdStroke = Instance.new("UIStroke")
			cdStroke.Name = "CardStroke"
			cdStroke.Color = Color3.fromRGB(225, 218, 205)
			cdStroke.Thickness = 2
			cdStroke.Parent = card

			-- İkon
			local iconLbl = Instance.new("TextLabel")
			iconLbl.Name = "Icon"
			iconLbl.Size = UDim2.new(0, 56, 0, 56)
			iconLbl.Position = UDim2.new(0, 12, 0, 22)
			iconLbl.BackgroundColor3 = Color3.fromRGB(245, 242, 235)
			iconLbl.Font = Enum.Font.FredokaOne
			iconLbl.TextSize = 28
			iconLbl.BorderSizePixel = 0
			iconLbl.Parent = card
			local icCorner = Instance.new("UICorner")
			icCorner.CornerRadius = UDim.new(0, 12)
			icCorner.Parent = iconLbl

			-- Başlık
			local nameLbl = Instance.new("TextLabel")
			nameLbl.Name = "TechName"
			nameLbl.Size = UDim2.new(0, 280, 0, 22)
			nameLbl.Position = UDim2.new(0, 78, 0, 14)
			nameLbl.BackgroundTransparency = 1
			nameLbl.TextColor3 = Color3.fromRGB(20, 20, 20)
			nameLbl.Font = Enum.Font.FredokaOne
			nameLbl.TextSize = 16
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.Parent = card

			-- Açıklama
			local descLbl = Instance.new("TextLabel")
			descLbl.Name = "Desc"
			descLbl.Size = UDim2.new(0, 280, 0, 18)
			descLbl.Position = UDim2.new(0, 78, 0, 38)
			descLbl.BackgroundTransparency = 1
			descLbl.TextColor3 = Color3.fromRGB(90, 90, 95)
			descLbl.Font = Enum.Font.GothamMedium
			descLbl.TextSize = 13
			descLbl.TextXAlignment = Enum.TextXAlignment.Left
			descLbl.Parent = card

			-- İlerleme Çubuğu (Toplam Yüzde)
			local barBg = Instance.new("Frame")
			barBg.Name = "BarBg"
			barBg.Size = UDim2.new(0, 280, 0, 18)
			barBg.Position = UDim2.new(0, 78, 0, 64)
			barBg.BackgroundColor3 = Color3.fromRGB(235, 230, 220)
			barBg.BorderSizePixel = 0
			barBg.ClipsDescendants = true
			barBg.Parent = card
			local bCorner = Instance.new("UICorner")
			bCorner.CornerRadius = UDim.new(0, 9)
			bCorner.Parent = barBg

			local barFill = Instance.new("Frame")
			barFill.Name = "Fill"
			barFill.Size = UDim2.new(0, 0, 1, 0)
			barFill.BackgroundColor3 = Color3.fromRGB(72, 215, 110)
			barFill.BorderSizePixel = 0
			barFill.Parent = barBg
			local fCorner = Instance.new("UICorner")
			fCorner.CornerRadius = UDim.new(0, 9)
			fCorner.Parent = barFill

			local barText = Instance.new("TextLabel")
			barText.Name = "BarText"
			barText.Size = UDim2.new(1, 0, 1, 0)
			barText.BackgroundTransparency = 1
			barText.TextColor3 = Color3.fromRGB(20, 20, 20)
			barText.Font = Enum.Font.FredokaOne
			barText.TextSize = 12
			barText.Parent = barBg

			-- Satın Alma Butonu
			local buyBtn = Instance.new("TextButton")
			buyBtn.Name = "BuyBtn"
			buyBtn.Size = UDim2.new(0, 130, 0, 60)
			buyBtn.Position = UDim2.new(1, -145, 0.5, -30)
			buyBtn.BackgroundColor3 = Color3.fromRGB(72, 215, 110)
			buyBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
			buyBtn.Font = Enum.Font.FredokaOne
			buyBtn.TextSize = 15
			buyBtn.BorderSizePixel = 0
			buyBtn.Parent = card
			local bbCorner = Instance.new("UICorner")
			bbCorner.CornerRadius = UDim.new(0, 14)
			bbCorner.Parent = buyBtn

			local bbStroke = Instance.new("UIStroke")
			bbStroke.Name = "BtnStroke"
			bbStroke.Color = Color3.fromRGB(30, 140, 60)
			bbStroke.Thickness = 2.5
			bbStroke.Parent = buyBtn

			buyBtn.MouseButton1Click:Connect(function()
				local cost = UpgradeConfig.GetCost(activeTab, catId, (playerUpgrades[activeTab] and playerUpgrades[activeTab][catId]) or 0)
				local bal = getResourceBalance(activeTab)
				if bal >= cost then
					buyBtn.Size = UDim2.new(0, 122, 0, 54)
					task.wait(0.06)
					buyBtn.Size = UDim2.new(0, 130, 0, 60)
					playSfx("rbxasset://sounds/electronicpingshort.wav", 0.5, 1.4)
					Network.BuyUpgradeEvent:FireServer(activeTab, catId)
				else
					playSfx("rbxasset://sounds/electronicpingshort.wav", 0.4, 0.7)
				end
			end)

			cardInstances[catId] = card
		end

		-- Değerleri Doldur
		local iconLbl = card:FindFirstChild("Icon") :: TextLabel
		local nameLbl = card:FindFirstChild("TechName") :: TextLabel
		local descLbl = card:FindFirstChild("Desc") :: TextLabel
		local barBg = card:FindFirstChild("BarBg") :: Frame
		local barFill = barBg and barBg:FindFirstChild("Fill") :: Frame
		local barText = barBg and barBg:FindFirstChild("BarText") :: TextLabel
		local buyBtn = card:FindFirstChild("BuyBtn") :: TextButton
		local bbStroke = buyBtn and buyBtn:FindFirstChild("BtnStroke") :: UIStroke

		if iconLbl then iconLbl.Text = info.Icon end
		if nameLbl then nameLbl.Text = string.format("%s (Lv. %d)", info.Name, info.TotalLevel) end
		if descLbl then
			local tabDef = UpgradeConfig.DEFINITIONS[activeTab]
			local bonusPerLvl = tabDef and tabDef[catId] and tabDef[catId].BonusPerLevel or 0
			descLbl.Text = string.format(catDef.DescTemplate, bonusPerLvl)
		end

		-- İlerleme Çubuğu Yüzdesi
		local fillRatio = math.clamp(info.LevelInTier / UpgradeConfig.LEVELS_PER_TIER, 0, 1)
		if barFill then
			barFill.Size = UDim2.new(fillRatio, 0, 1, 0)
			if activeTab == "Crystals" then
				barFill.BackgroundColor3 = Color3.fromRGB(80, 190, 255)
			elseif activeTab == "Engineers" then
				barFill.BackgroundColor3 = Color3.fromRGB(255, 175, 45)
			else
				barFill.BackgroundColor3 = Color3.fromRGB(72, 215, 110)
			end
		end
		if barText then
			barText.Text = string.format("Toplam: %s (%d/%d)", info.BonusText, info.LevelInTier, UpgradeConfig.LEVELS_PER_TIER)
		end

		-- Fiyat ve Karşılanabilirlik Durumu
		local cost = info.NextCost
		local isAffordable = currentBalance >= cost

		local formattedCost: string
		if activeTab == "Cash" then
			formattedCost = NumberFormat.FormatCash(cost)
		elseif activeTab == "Crystals" then
			formattedCost = NumberFormat.FormatCrystals(cost)
		else
			formattedCost = NumberFormat.FormatEngineers(cost)
		end

		if buyBtn and bbStroke then
			buyBtn.Text = string.format("YÜKSELT\n%s", formattedCost)
			if isAffordable then
				if activeTab == "Crystals" then
					buyBtn.BackgroundColor3 = Color3.fromRGB(100, 210, 255)
					bbStroke.Color = Color3.fromRGB(20, 120, 180)
				elseif activeTab == "Engineers" then
					buyBtn.BackgroundColor3 = Color3.fromRGB(255, 185, 60)
					bbStroke.Color = Color3.fromRGB(190, 110, 0)
				else
					buyBtn.BackgroundColor3 = Color3.fromRGB(72, 215, 110)
					bbStroke.Color = Color3.fromRGB(25, 130, 50)
				end
				buyBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
			else
				buyBtn.BackgroundColor3 = Color3.fromRGB(225, 222, 215)
				bbStroke.Color = Color3.fromRGB(165, 160, 150)
				buyBtn.TextColor3 = Color3.fromRGB(60, 60, 65)
			end
		end
	end
end

-- ============================================================================
-- ETKİLEŞİMLER VE DİNLENEN OLAYLAR
-- ============================================================================
-- Sekme Değiştirme
for tabKey, btn in pairs(tabButtons) do
	btn.MouseButton1Click:Connect(function()
		activeTab = tabKey
		playSfx("rbxasset://sounds/electronicpingshort.wav", 0.3, 1.1)
		updateUI()
	end)
end

-- Açma / Kapatma Eylemi
local function toggleModal()
	modal.Visible = not modal.Visible
	if modal.Visible then
		playSfx("rbxasset://sounds/electronicpingshort.wav", 0.4, 1.0)
		updateUI()
	end
end

toggleBtn.MouseButton1Click:Connect(toggleModal)
closeBtn.MouseButton1Click:Connect(toggleModal)

-- Klavye Kısayolu (U tuşu ile aç/kapa)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.U then
		toggleModal()
	end
end)

-- Sunucudan Gelen Yükseltme Senkronizasyonu
Network.SyncUpgradesEvent.OnClientEvent:Connect(function(upgrades)
	playerUpgrades = upgrades or playerUpgrades
	updateUI()
end)

-- Sunucudan Gelen Kaynak Senkronizasyonu
Network.SyncResourcesEvent.OnClientEvent:Connect(function(cash, crystals, engineers)
	currentCash = cash or currentCash
	currentCrystals = crystals or currentCrystals
	currentEngineers = engineers or currentEngineers
	updateUI()
end)

-- Leaderstats Kasa Değişimi Dinleyicisi
task.spawn(function()
	local leaderstats = localPlayer:WaitForChild("leaderstats", 10)
	if leaderstats then
		local cashVal = leaderstats:WaitForChild("💰 Kasa ($)", 5) :: IntValue
		if cashVal then
			cashVal.Changed:Connect(function(newCash)
				currentCash = newCash
				updateUI()
			end)
		end
	end
end)

updateUI()

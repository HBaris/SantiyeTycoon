--!strict
-- ============================================================================
-- DevCustomizerUI.client.luau
-- 🛠️ Tasarım & Geliştirme Motoru Arayüzü (In-Game Dev & Customization Engine)
-- Model İnceleme, Canlı Büyütme/Küçültme (ScaleTo), 90° Çevirme, Çarşı Slotları
-- ve Varlık Kataloğu
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Network = require(ReplicatedStorage.Shared.Network)
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local currentPlotIndex = 1
local selectedModel: Model? = nil
local selectionHighlight: Highlight? = nil

-- UI Ekranı Oluştur
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevCustomizerHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- 1. Sol Menü Açma/Kapama Butonu
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "CustomizerToggleBtn"
toggleBtn.Size = UDim2.new(0, 165, 0, 42)
toggleBtn.Position = UDim2.new(0, 15, 0.45, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
toggleBtn.Text = "🛠️ TASARIM MOTORU"
toggleBtn.TextColor3 = Color3.fromRGB(255, 215, 60)
toggleBtn.Font = Enum.Font.FredokaOne
toggleBtn.TextSize = 13
toggleBtn.AutoButtonColor = true
toggleBtn.Parent = screenGui

local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(0, 10)
tCorner.Parent = toggleBtn

local tStroke = Instance.new("UIStroke")
tStroke.Color = Color3.fromRGB(245, 180, 30)
tStroke.Thickness = 2
tStroke.Parent = toggleBtn

-- 2. Ana Panel (Drawer Card)
local panel = Instance.new("Frame")
panel.Name = "CustomizerPanel"
panel.Size = UDim2.new(0, 380, 0, 540)
panel.Position = UDim2.new(0, 190, 0.5, -270)
panel.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

local pCorner = Instance.new("UICorner")
pCorner.CornerRadius = UDim.new(0, 14)
pCorner.Parent = panel

local pStroke = Instance.new("UIStroke")
pStroke.Color = Color3.fromRGB(55, 60, 75)
pStroke.Thickness = 2
pStroke.Parent = panel

-- Başlık Çubuğu
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 46)
header.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
header.BorderSizePixel = 0
header.Parent = panel

local hCorner = Instance.new("UICorner")
hCorner.CornerRadius = UDim.new(0, 14)
hCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.8, 0, 1, 0)
title.Position = UDim2.new(0.05, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🛠️ TASARIM & GELİŞTİRME MOTORU"
title.TextColor3 = Color3.fromRGB(255, 220, 60)
title.Font = Enum.Font.FredokaOne
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -38, 0.5, -16)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextSize = 16
closeBtn.Parent = header
local cBtnCorner = Instance.new("UICorner")
cBtnCorner.CornerRadius = UDim.new(0, 8)
cBtnCorner.Parent = closeBtn

-- Sekme Barı (Tab Bar)
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(0.92, 0, 0, 36)
tabBar.Position = UDim2.new(0.04, 0, 0, 54)
tabBar.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
tabBar.Parent = panel
local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 8)
tbCorner.Parent = tabBar

local activeTab = 1
local tabButtons: { TextButton } = {}
local tabPages: { Frame } = {}

local tabNames = { "🔍 Model İncele", "🏛️ Çarşı Slotları", "📦 Katalog" }

local function createTabPage(index: number): Frame
	local page = Instance.new("Frame")
	page.Name = "TabPage_" .. index
	page.Size = UDim2.new(0.92, 0, 0, 430)
	page.Position = UDim2.new(0.04, 0, 0, 96)
	page.BackgroundTransparency = 1
	page.Visible = (index == 1)
	page.Parent = panel
	return page
end

for i, tName in ipairs(tabNames) do
	local tBtn = Instance.new("TextButton")
	tBtn.Size = UDim2.new(1 / #tabNames, -4, 1, -4)
	tBtn.Position = UDim2.new((i - 1) * (1 / #tabNames), 2, 0, 2)
	tBtn.BackgroundColor3 = (i == 1) and Color3.fromRGB(45, 55, 75) or Color3.fromRGB(25, 28, 35)
	tBtn.Text = tName
	tBtn.TextColor3 = (i == 1) and Color3.fromRGB(255, 225, 80) or Color3.fromRGB(180, 185, 195)
	tBtn.Font = Enum.Font.FredokaOne
	tBtn.TextSize = 12
	tBtn.Parent = tabBar
	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 6)
	bCorner.Parent = tBtn

	table.insert(tabButtons, tBtn)
	table.insert(tabPages, createTabPage(i))
end

local function switchTab(index: number)
	activeTab = index
	for i, btn in ipairs(tabButtons) do
		btn.BackgroundColor3 = (i == index) and Color3.fromRGB(45, 55, 75) or Color3.fromRGB(25, 28, 35)
		btn.TextColor3 = (i == index) and Color3.fromRGB(255, 225, 80) or Color3.fromRGB(180, 185, 195)
	end
	for i, page in ipairs(tabPages) do
		page.Visible = (i == index)
	end
end

for i, btn in ipairs(tabButtons) do
	btn.MouseButton1Click:Connect(function()
		switchTab(i)
	end)
end

-- ============================================================================
-- SEKME 1: 🔍 MODEL SEÇ, İNCELE VE CANLI BÜYÜT/KÜÇÜLT
-- ============================================================================
local page1 = tabPages[1]

-- Seçilen Nesne Bilgi Kartı
local infoCard = Instance.new("Frame")
infoCard.Size = UDim2.new(1, 0, 0, 75)
infoCard.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
infoCard.Parent = page1
local icCorner = Instance.new("UICorner")
icCorner.CornerRadius = UDim.new(0, 8)
icCorner.Parent = infoCard

local selNameLabel = Instance.new("TextLabel")
selNameLabel.Size = UDim2.new(0.9, 0, 0.45, 0)
selNameLabel.Position = UDim2.new(0.05, 0, 0.08, 0)
selNameLabel.BackgroundTransparency = 1
selNameLabel.Text = "Seçili: (Bir nesne seçin)"
selNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
selNameLabel.Font = Enum.Font.FredokaOne
selNameLabel.TextSize = 14
selNameLabel.TextXAlignment = Enum.TextXAlignment.Left
selNameLabel.Parent = infoCard

local selDimLabel = Instance.new("TextLabel")
selDimLabel.Size = UDim2.new(0.9, 0, 0.45, 0)
selDimLabel.Position = UDim2.new(0.05, 0, 0.52, 0)
selDimLabel.BackgroundTransparency = 1
selDimLabel.Text = "Boyutlar: --"
selDimLabel.TextColor3 = Color3.fromRGB(140, 220, 170)
selDimLabel.Font = Enum.Font.GothamBold
selDimLabel.TextSize = 12
selDimLabel.TextXAlignment = Enum.TextXAlignment.Left
selDimLabel.Parent = infoCard

-- Hızlı Nesne Seçici Dropdown / Buton Listesi
local pickListFrame = Instance.new("ScrollingFrame")
pickListFrame.Size = UDim2.new(1, 0, 0, 120)
pickListFrame.Position = UDim2.new(0, 0, 0, 85)
pickListFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
pickListFrame.ScrollBarThickness = 5
pickListFrame.CanvasSize = UDim2.new(0, 0, 0, 360)
pickListFrame.Parent = page1
local plCorner = Instance.new("UICorner")
plCorner.CornerRadius = UDim.new(0, 8)
plCorner.Parent = pickListFrame

local plLayout = Instance.new("UIListLayout")
plLayout.Padding = UDim.new(0, 4)
plLayout.Parent = pickListFrame

local function updateSelection(model: Model?)
	selectedModel = model
	if not selectionHighlight then
		selectionHighlight = Instance.new("Highlight")
		selectionHighlight.FillColor = Color3.fromRGB(255, 220, 40)
		selectionHighlight.FillTransparency = 0.75
		selectionHighlight.OutlineColor = Color3.fromRGB(255, 240, 100)
		selectionHighlight.OutlineTransparency = 0.1
	end

	if model then
		selectionHighlight.Adornee = model
		selectionHighlight.Parent = model
		local _, size = model:GetBoundingBox()
		selNameLabel.Text = "Seçili: " .. model.Name
		selDimLabel.Text = string.format("Boyut: %.1f x %.1f x %.1f stud", size.X, size.Y, size.Z)
	else
		selectionHighlight.Adornee = nil
		selNameLabel.Text = "Seçili: (Hiçbiri)"
		selDimLabel.Text = "Boyutlar: --"
	end
end

local function refreshPlotObjectsList()
	for _, child in ipairs(pickListFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	local plotFolder = Workspace:FindFirstChild(string.format("Plot_%s_%d", localPlayer.Name, currentPlotIndex))
	if not plotFolder then return end

	local count = 0
	local function addPickItem(name: string, targetModel: Model)
		count = count + 1
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -8, 0, 30)
		btn.BackgroundColor3 = Color3.fromRGB(35, 40, 52)
		btn.Text = "  📦 " .. name
		btn.TextColor3 = Color3.fromRGB(220, 225, 235)
		btn.Font = Enum.Font.FredokaOne
		btn.TextSize = 12
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Parent = pickListFrame
		local bC = Instance.new("UICorner")
		bC.CornerRadius = UDim.new(0, 6)
		bC.Parent = btn

		btn.MouseButton1Click:Connect(function()
			updateSelection(targetModel)
		end)
	end

	-- Ana Bina
	local building = plotFolder:FindFirstChild("BuildingModel")
	if building and building:IsA("Model") then
		addPickItem("Ana Bina (Proje)", building)
	end

	-- Şantiye Ekipmanları & Modeller (Vinç, Şantiye Ofisi, Özel Varlıklar)
	for _, child in ipairs(plotFolder:GetChildren()) do
		if child:IsA("Model") and child.Name ~= "BuildingModel" and child.Name ~= "CommercialPromenade" then
			addPickItem(child.Name, child)
		end
	end

	-- Çarşı Dükkanları (Promenade)
	local prom = plotFolder:FindFirstChild("CommercialPromenade")
	if prom then
		for _, m in ipairs(prom:GetChildren()) do
			if m:IsA("Model") and (m.Name:find("Shop") or m.Name:find("Fountain") or m.Name:find("Promenade")) then
				addPickItem(m.Name, m)
			end
		end
	end

	pickListFrame.CanvasSize = UDim2.new(0, 0, 0, count * 35)
end

-- Canlı Ölçeklendirme Butonları (ScaleTo)
local scaleSection = Instance.new("Frame")
scaleSection.Size = UDim2.new(1, 0, 0, 130)
scaleSection.Position = UDim2.new(0, 0, 0, 215)
scaleSection.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
scaleSection.Parent = page1
local scCorner = Instance.new("UICorner")
scCorner.CornerRadius = UDim.new(0, 8)
scCorner.Parent = scaleSection

local scaleTitle = Instance.new("TextLabel")
scaleTitle.Size = UDim2.new(0.9, 0, 0, 24)
scaleTitle.Position = UDim2.new(0.05, 0, 0, 6)
scaleTitle.BackgroundTransparency = 1
scaleTitle.Text = "⚖️ CANLI BOYUTLANDIRMA (BÜYÜT / KÜÇÜLT)"
scaleTitle.TextColor3 = Color3.fromRGB(255, 215, 60)
scaleTitle.Font = Enum.Font.FredokaOne
scaleTitle.TextSize = 12
scaleTitle.TextXAlignment = Enum.TextXAlignment.Left
scaleTitle.Parent = scaleSection

local function applyScaleRatio(ratio: number)
	if not selectedModel then
		selNameLabel.Text = "⚠️ Lütfen önce bir nesne seçin!"
		return
	end
	Network.CustomizeModelEvent:FireServer(currentPlotIndex, selectedModel.Name, "Scale", ratio)
	task.delay(0.2, function()
		if selectedModel then
			local _, size = selectedModel:GetBoundingBox()
			selDimLabel.Text = string.format("Yeni Boyut: %.1f x %.1f x %.1f stud", size.X, size.Y, size.Z)
		end
	end)
end

local scaleButtons = {
	{ text = "[-] %25 Küçült", ratio = 0.8 },
	{ text = "[+] %25 Büyüt", ratio = 1.25 },
	{ text = "1.5x Yap", ratio = 1.5 },
	{ text = "2.0x Yap", ratio = 2.0 },
}

for i, sb in ipairs(scaleButtons) do
	local sBtn = Instance.new("TextButton")
	sBtn.Size = UDim2.new(0.46, 0, 0, 36)
	local col = (i - 1) % 2
	local row = math.floor((i - 1) / 2)
	sBtn.Position = UDim2.new(0.04 + (col * 0.48), 0, 0, 36 + (row * 42))
	sBtn.BackgroundColor3 = (sb.ratio > 1) and Color3.fromRGB(45, 80, 55) or Color3.fromRGB(80, 50, 45)
	sBtn.Text = sb.text
	sBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	sBtn.Font = Enum.Font.FredokaOne
	sBtn.TextSize = 12
	sBtn.Parent = scaleSection
	local sbc = Instance.new("UICorner")
	sbc.CornerRadius = UDim.new(0, 6)
	sbc.Parent = sBtn

	sBtn.MouseButton1Click:Connect(function()
		applyScaleRatio(sb.ratio)
	end)
end

-- Çevir & Kaydır Kontrolleri
local moveSection = Instance.new("Frame")
moveSection.Size = UDim2.new(1, 0, 0, 75)
moveSection.Position = UDim2.new(0, 0, 0, 352)
moveSection.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
moveSection.Parent = page1
local mcCorner = Instance.new("UICorner")
mcCorner.CornerRadius = UDim.new(0, 8)
mcCorner.Parent = moveSection

local rotateBtn = Instance.new("TextButton")
rotateBtn.Size = UDim2.new(0.46, 0, 0, 38)
rotateBtn.Position = UDim2.new(0.04, 0, 0.5, -19)
rotateBtn.BackgroundColor3 = Color3.fromRGB(45, 60, 85)
rotateBtn.Text = "↻ 90° Döndür"
rotateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rotateBtn.Font = Enum.Font.FredokaOne
rotateBtn.TextSize = 13
rotateBtn.Parent = moveSection
local rbc = Instance.new("UICorner")
rbc.CornerRadius = UDim.new(0, 6)
rbc.Parent = rotateBtn

rotateBtn.MouseButton1Click:Connect(function()
	if not selectedModel then return end
	Network.CustomizeModelEvent:FireServer(currentPlotIndex, selectedModel.Name, "Rotate", 90)
end)

local clickSelectBtn = Instance.new("TextButton")
clickSelectBtn.Size = UDim2.new(0.46, 0, 0, 38)
clickSelectBtn.Position = UDim2.new(0.52, 0, 0.5, -19)
clickSelectBtn.BackgroundColor3 = Color3.fromRGB(85, 70, 35)
clickSelectBtn.Text = "🔄 Listeyi Yenile"
clickSelectBtn.TextColor3 = Color3.fromRGB(255, 230, 100)
clickSelectBtn.Font = Enum.Font.FredokaOne
clickSelectBtn.TextSize = 13
clickSelectBtn.Parent = moveSection
local csbc = Instance.new("UICorner")
csbc.CornerRadius = UDim.new(0, 6)
csbc.Parent = clickSelectBtn

clickSelectBtn.MouseButton1Click:Connect(function()
	refreshPlotObjectsList()
end)

-- ============================================================================
-- SEKME 2: 🏛️ ÇARŞI VE YAŞAM ALANI SLOT SEÇİCİ
-- ============================================================================
local page2 = tabPages[2]

local slotScroll = Instance.new("ScrollingFrame")
slotScroll.Size = UDim2.new(1, 0, 1, 0)
slotScroll.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
slotScroll.ScrollBarThickness = 5
slotScroll.CanvasSize = UDim2.new(0, 0, 0, 480)
slotScroll.Parent = page2
local ssCorner = Instance.new("UICorner")
ssCorner.CornerRadius = UDim.new(0, 8)
ssCorner.Parent = slotScroll

local ssLayout = Instance.new("UIListLayout")
ssLayout.Padding = UDim.new(0, 8)
ssLayout.Parent = slotScroll

local availableShops = {
	{ id = "Bakery", name = "🥖 Taş Fırın & Kafe" },
	{ id = "Market", name = "🛒 Gross Süpermarket" },
	{ id = "Fountain", name = "⛲ Süs Havuzu & Fıskiye" },
	{ id = "Barber", name = "💈 VIP Erkek Kuaförü" },
	{ id = "PetShop", name = "🐾 Pati Pet Shop" },
	{ id = "Restaurant", name = "🍽️ Bistro Restaurant" },
	{ id = "Empty", name = "❌ Boş Bırak" },
}

for slotIdx = 1, 6 do
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -8, 0, 70)
	card.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
	card.Parent = slotScroll
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 8)
	cc.Parent = card

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.9, 0, 0, 24)
	label.Position = UDim2.new(0.04, 0, 0, 4)
	label.BackgroundTransparency = 1
	label.Text = string.format("🏛️ Çarşı Yuvası (Slot %d):", slotIdx)
	label.TextColor3 = Color3.fromRGB(255, 215, 60)
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = card

	-- Seçim Butonları Kaydırma
	local optScroll = Instance.new("ScrollingFrame")
	optScroll.Size = UDim2.new(0.94, 0, 0, 32)
	optScroll.Position = UDim2.new(0.03, 0, 0, 30)
	optScroll.BackgroundTransparency = 1
	optScroll.ScrollBarThickness = 3
	optScroll.ScrollingDirection = Enum.ScrollingDirection.X
	optScroll.CanvasSize = UDim2.new(0, #availableShops * 115, 0, 0)
	optScroll.Parent = card

	local optLayout = Instance.new("UIListLayout")
	optLayout.FillDirection = Enum.FillDirection.Horizontal
	optLayout.Padding = UDim.new(0, 4)
	optLayout.Parent = optScroll

	for _, shop in ipairs(availableShops) do
		local oBtn = Instance.new("TextButton")
		oBtn.Size = UDim2.new(0, 110, 1, 0)
		oBtn.BackgroundColor3 = Color3.fromRGB(42, 48, 62)
		oBtn.Text = shop.name
		oBtn.TextColor3 = Color3.fromRGB(230, 235, 245)
		oBtn.Font = Enum.Font.FredokaOne
		oBtn.TextSize = 11
		oBtn.Parent = optScroll
		local obc = Instance.new("UICorner")
		obc.CornerRadius = UDim.new(0, 6)
		obc.Parent = oBtn

		oBtn.MouseButton1Click:Connect(function()
			Network.ChangePromenadeSlotEvent:FireServer(currentPlotIndex, slotIdx, shop.id)
			oBtn.BackgroundColor3 = Color3.fromRGB(60, 110, 75)
			task.delay(0.6, function()
				oBtn.BackgroundColor3 = Color3.fromRGB(42, 48, 62)
				refreshPlotObjectsList()
			end)
		end)
	end
end

-- ============================================================================
-- SEKME 3: 📦 VARLIK KATALOĞU (ASSET CATALOG & SPAWNER)
-- ============================================================================
local page3 = tabPages[3]

local catScroll = Instance.new("ScrollingFrame")
catScroll.Size = UDim2.new(1, 0, 1, 0)
catScroll.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
catScroll.ScrollBarThickness = 5
catScroll.CanvasSize = UDim2.new(0, 0, 0, 600)
catScroll.Parent = page3
local csc = Instance.new("UICorner")
csc.CornerRadius = UDim.new(0, 8)
csc.Parent = catScroll

local csLayout = Instance.new("UIListLayout")
csLayout.Padding = UDim.new(0, 6)
csLayout.Parent = catScroll

local catalogItems = {
	{ cat = "Buildings", name = "Level_1", label = "🏠 Ahşap Kulübe (Lv.1)" },
	{ cat = "Buildings", name = "Level_2", label = "🏡 Tuğla Malikâne (Lv.2)" },
	{ cat = "Buildings", name = "Level_3", label = "🏰 Lüks Villa (Lv.3)" },
	{ cat = "Buildings", name = "Level_4", label = "🏢 Rezidans Apartman (Lv.4)" },
	{ cat = "Buildings", name = "Level_5", label = "🏙️ Prestij Gökdelen (Lv.5)" },
	{ cat = "Commercial", name = "Bakery", label = "🥖 Taş Fırın Dükkanı" },
	{ cat = "Commercial", name = "Market", label = "🛒 Süpermarket" },
	{ cat = "Commercial", name = "Fountain", label = "⛲ Süs Havuzu" },
	{ cat = "Commercial", name = "Barber", label = "💈 Kuaför Salonu" },
	{ cat = "Commercial", name = "Restaurant", label = "🍽️ Bistro Kafe" },
	{ cat = "Trees", name = "PineTree", label = "🌲 Dağ Çamı Ağacı" },
	{ cat = "Trees", name = "GardenTree", label = "🌳 Bahçe Meşe Ağacı" },
	{ cat = "Trees", name = "CypressTree", label = "🌲 Selvi Ağacı" },
	{ cat = "Props", name = "StreetLamp", label = "🏮 Sokak Lambası" },
	{ cat = "Props", name = "Bench", label = "🪑 Park Bankı" },
	{ cat = "Props", name = "Planter", label = "🪴 Çiçeklik Kutusu" },
}

for _, item in ipairs(catalogItems) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 36)
	row.BackgroundColor3 = Color3.fromRGB(30, 35, 46)
	row.Parent = catScroll
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 6)
	rc.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.65, 0, 1, 0)
	lbl.Position = UDim2.new(0.04, 0, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = item.label
	lbl.TextColor3 = Color3.fromRGB(230, 235, 245)
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local spawnBtn = Instance.new("TextButton")
	spawnBtn.Size = UDim2.new(0.28, 0, 0.75, 0)
	spawnBtn.Position = UDim2.new(0.68, 0, 0.12, 0)
	spawnBtn.BackgroundColor3 = Color3.fromRGB(50, 95, 60)
	spawnBtn.Text = "➕ Ekle"
	spawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	spawnBtn.Font = Enum.Font.FredokaOne
	spawnBtn.TextSize = 11
	spawnBtn.Parent = row
	local spc = Instance.new("UICorner")
	spc.CornerRadius = UDim.new(0, 6)
	spc.Parent = spawnBtn

	spawnBtn.MouseButton1Click:Connect(function()
		Network.SpawnAssetOnPlotEvent:FireServer(currentPlotIndex, item.cat, item.name)
		spawnBtn.BackgroundColor3 = Color3.fromRGB(80, 140, 90)
		task.delay(0.5, function()
			spawnBtn.BackgroundColor3 = Color3.fromRGB(50, 95, 60)
			refreshPlotObjectsList()
		end)
	end)
end

-- Aç/Kapa Etkileşimi
local function togglePanel()
	panel.Visible = not panel.Visible
	toggleBtn.BackgroundColor3 = panel.Visible and Color3.fromRGB(60, 70, 90) or Color3.fromRGB(35, 40, 50)
	if panel.Visible then
		refreshPlotObjectsList()
	else
		updateSelection(nil)
	end
end

panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then
		refreshPlotObjectsList()
	end
end)

toggleBtn.MouseButton1Click:Connect(togglePanel)
closeBtn.MouseButton1Click:Connect(togglePanel)

-- F4 Kısayol Tuşu ile Aç/Kapa
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F4 then
		togglePanel()
	end
end)

print("🛠️ DevCustomizerUI (Tasarım & Geliştirme Motoru Arayüzü) Başlatıldı. [F4]")

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
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Network = require(ReplicatedStorage.Shared.Network)
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera") :: Camera
local CustomizerCameraController = require(script.Parent:WaitForChild("CustomizerCameraController"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local currentPlotIndex = 1
local selectedModel: Model? = nil
local selectionHighlight: Highlight? = nil

local isDragging = false
local draggedModel: Model? = nil
local dragInitialCF: CFrame? = nil
local dragYaw = 0
local isShowcaseDrag = false
local showcaseCategory = ""
local showcaseAssetId = ""

-- UI Ekranı Oluştur
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevCustomizerHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local function corner(p: Instance, r: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r); c.Parent = p; return c
end

local function stroke(p: Instance, col: Color3, th: number?)
	local s = Instance.new("UIStroke")
	s.Color, s.Thickness, s.Parent = col, th or 1.5, p; return s
end

-- 1. Sol Menü Açma/Kapama Butonu (Yükseltmeler ve Garaj butonlarının üstünde temiz slot)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "CustomizerToggleBtn"
toggleBtn.Size = UDim2.new(0, 180, 0, 48)
toggleBtn.Position = UDim2.new(0, 20, 0.35, -5)
toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
toggleBtn.Text = "🛠️ TASARIM MOTORU"
toggleBtn.TextColor3 = Color3.fromRGB(255, 215, 60)
toggleBtn.Font = Enum.Font.FredokaOne
toggleBtn.TextSize = 13
toggleBtn.AutoButtonColor = true
toggleBtn.Parent = screenGui
corner(toggleBtn, 12)
stroke(toggleBtn, Color3.fromRGB(245, 180, 30), 2)

-- 1b. Üst Kuş Bakışı Kamera Kontrol Barı (360° Orbit Kontrolleri)
local cameraBar = Instance.new("Frame")
cameraBar.Name, cameraBar.Size = "CameraControlBar", UDim2.new(0, 400, 0, 42)
cameraBar.Position, cameraBar.BackgroundColor3 = UDim2.new(0.5, -200, 0, 72), Color3.fromRGB(22, 26, 34)
cameraBar.BackgroundTransparency, cameraBar.BorderSizePixel, cameraBar.ZIndex, cameraBar.Visible = 0.08, 0, 15, false
cameraBar.Parent = screenGui
corner(cameraBar, 10)
stroke(cameraBar, Color3.fromRGB(65, 75, 95))

local cbLayout = Instance.new("UIListLayout")
cbLayout.FillDirection, cbLayout.HorizontalAlignment, cbLayout.VerticalAlignment, cbLayout.Padding, cbLayout.Parent =
	Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center, UDim.new(0, 6), cameraBar

local camButtons = {
	{ "↺ Sola (Q)", function() CustomizerCameraController.RotateLeft(45) end, 82 },
	{ "↻ Sağa (E)", function() CustomizerCameraController.RotateRight(45) end, 82 },
	{ "🔍+ Yaklaş", function() CustomizerCameraController.ZoomIn(14) end, 75 },
	{ "🔍- Uzaklaş", function() CustomizerCameraController.ZoomOut(14) end, 75 },
	{ "🎯 Merkez", function() CustomizerCameraController.ResetCenter() end, 62 },
}

for _, cb in ipairs(camButtons) do
	local b = Instance.new("TextButton")
	b.Size, b.BackgroundColor3, b.Text = UDim2.new(0, cb[3], 0, 30), Color3.fromRGB(35, 42, 56), cb[1]
	b.TextColor3, b.Font, b.TextSize, b.ZIndex, b.Parent = Color3.fromRGB(235, 240, 250), Enum.Font.FredokaOne, 11, 16, cameraBar
	corner(b, 6)
	b.MouseButton1Click:Connect(cb[2])
end

-- 1c. Sürükle & Bırak Alt Kontrol Çubuğu (Doğrudan Butonlar & Kısayollar)
local dragBanner = Instance.new("Frame")
dragBanner.Name, dragBanner.Size = "DragBanner", UDim2.new(0, 560, 0, 44)
dragBanner.Position, dragBanner.BackgroundColor3 = UDim2.new(0.5, -280, 1, -85), Color3.fromRGB(18, 24, 32)
dragBanner.BackgroundTransparency, dragBanner.BorderSizePixel, dragBanner.ZIndex, dragBanner.Visible = 0.05, 0, 25, false
dragBanner.Parent = screenGui
corner(dragBanner, 10)
stroke(dragBanner, Color3.fromRGB(50, 205, 90), 2)

local dragBannerText = Instance.new("TextLabel")
dragBannerText.Size, dragBannerText.Position, dragBannerText.BackgroundTransparency = UDim2.new(0.48, 0, 1, 0), UDim2.new(0.03, 0, 0, 0), 1
dragBannerText.Text, dragBannerText.TextColor3, dragBannerText.Font, dragBannerText.TextSize = "🖐️ MODELİ TAŞIYORSUNUZ", Color3.fromRGB(220, 255, 230), Enum.Font.FredokaOne, 12
dragBannerText.TextXAlignment, dragBannerText.ZIndex, dragBannerText.Parent = Enum.TextXAlignment.Left, 26, dragBanner

local stopDraggingRef: ((boolean) -> ())? = nil

local dropBtn = Instance.new("TextButton")
dropBtn.Size, dropBtn.Position, dropBtn.BackgroundColor3 = UDim2.new(0.22, 0, 0.74, 0), UDim2.new(0.51, 0, 0.13, 0), Color3.fromRGB(40, 160, 70)
dropBtn.Text, dropBtn.TextColor3, dropBtn.Font, dropBtn.TextSize, dropBtn.ZIndex, dropBtn.Parent = "✅ YERLEŞTİR", Color3.fromRGB(255, 255, 255), Enum.Font.FredokaOne, 11, 26, dragBanner
corner(dropBtn, 6)
dropBtn.MouseButton1Click:Connect(function()
	if stopDraggingRef then stopDraggingRef(true) end
end)

local rotBtn = Instance.new("TextButton")
rotBtn.Size, rotBtn.Position, rotBtn.BackgroundColor3 = UDim2.new(0.12, 0, 0.74, 0), UDim2.new(0.74, 0, 0.13, 0), Color3.fromRGB(50, 70, 100)
rotBtn.Text, rotBtn.TextColor3, rotBtn.Font, rotBtn.TextSize, rotBtn.ZIndex, rotBtn.Parent = "↻ 45°", Color3.fromRGB(255, 255, 255), Enum.Font.FredokaOne, 11, 26, dragBanner
corner(rotBtn, 6)
rotBtn.MouseButton1Click:Connect(function()
	dragYaw = (dragYaw + 45) % 360
	dragBannerText.Text = string.format("🖐️ %s (%d°)", (draggedModel and draggedModel.Name or "Model"), dragYaw)
end)

local cancelBtn = Instance.new("TextButton")
cancelBtn.Size, cancelBtn.Position, cancelBtn.BackgroundColor3 = UDim2.new(0.12, 0, 0.74, 0), UDim2.new(0.87, 0, 0.13, 0), Color3.fromRGB(110, 45, 45)
cancelBtn.Text, cancelBtn.TextColor3, cancelBtn.Font, cancelBtn.TextSize, cancelBtn.ZIndex, cancelBtn.Parent = "✕ İPTAL", Color3.fromRGB(255, 255, 255), Enum.Font.FredokaOne, 11, 26, dragBanner
corner(cancelBtn, 6)
cancelBtn.MouseButton1Click:Connect(function()
	if stopDraggingRef then stopDraggingRef(false) end
end)

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
corner(panel, 14)
stroke(panel, Color3.fromRGB(55, 60, 75), 2)

-- Başlık Çubuğu
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 46)
header.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
header.BorderSizePixel = 0
header.Parent = panel
corner(header, 14)

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
corner(closeBtn, 8)

-- Sekme Barı (Tab Bar)
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(0.92, 0, 0, 36)
tabBar.Position = UDim2.new(0.04, 0, 0, 54)
tabBar.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
tabBar.Parent = panel
corner(tabBar, 8)

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
	corner(tBtn, 6)

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
corner(infoCard, 8)

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
corner(pickListFrame, 8)

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

local function startDragging(model: Model)
	if not model or isDragging then return end
	local plotFolder = Workspace:FindFirstChild(string.format("Plot_%s_%d", localPlayer.Name, currentPlotIndex))

	isShowcaseDrag = false
	if model:GetAttribute("IsShowcaseAsset") and plotFolder then
		isShowcaseDrag = true
		showcaseCategory = model:GetAttribute("Category") or "Buildings"
		showcaseAssetId = model:GetAttribute("AssetId") or "Level_1"
		local assets = ReplicatedStorage:FindFirstChild("Assets")
		local catFolder = assets and assets:FindFirstChild(showcaseCategory)
		local template = catFolder and catFolder:FindFirstChild(showcaseAssetId)
		if template and template:IsA("Model") then
			local preview = template:Clone()
			preview.Name = "Preview_" .. showcaseAssetId
			preview.Parent = plotFolder
			model = preview
		end
	end

	isDragging = true
	draggedModel = model
	dragInitialCF = model:GetPivot()
	local _, rotY, _ = dragInitialCF:ToEulerAnglesYXZ()
	dragYaw = math.round(math.deg(rotY))

	if selectionHighlight then
		selectionHighlight.Adornee = model
		selectionHighlight.FillColor = Color3.fromRGB(50, 220, 90)
		selectionHighlight.FillTransparency = 0.65
		selectionHighlight.OutlineColor = Color3.fromRGB(100, 255, 140)
	end
	panel.Visible = false
	dragBanner.Visible = true
	dragBannerText.Text = string.format("🖐️ SÜRÜKLENİYOR: %s (%d°)", model.Name, dragYaw)
end

local function stopDragging(commit: boolean)
	if not isDragging or not draggedModel then return end
	isDragging = false
	dragBanner.Visible = false
	panel.Visible = true

	local pivot = draggedModel:GetPivot()
	if isShowcaseDrag then
		draggedModel:Destroy()
		if commit then
			Network.SpawnAssetOnPlotEvent:FireServer(currentPlotIndex, showcaseCategory, showcaseAssetId, {
				X = pivot.Position.X,
				Y = pivot.Position.Y,
				Z = pivot.Position.Z,
				Yaw = dragYaw,
			})
			task.delay(0.4, function() refreshPlotObjectsList() end)
		end
	else
		if commit then
			Network.CustomizeModelEvent:FireServer(currentPlotIndex, draggedModel.Name, "SetCFrame", {
				X = pivot.Position.X,
				Y = pivot.Position.Y,
				Z = pivot.Position.Z,
				Yaw = dragYaw,
			})
		else
			if dragInitialCF then
				draggedModel:PivotTo(dragInitialCF)
			end
		end
	end

	if selectionHighlight then
		selectionHighlight.FillColor = Color3.fromRGB(255, 220, 40)
		selectionHighlight.FillTransparency = 0.75
		selectionHighlight.OutlineColor = Color3.fromRGB(255, 240, 100)
	end
	draggedModel = nil
end
stopDraggingRef = stopDragging

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
		corner(btn, 6)

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
corner(scaleSection, 8)

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
	corner(sBtn, 6)

	sBtn.MouseButton1Click:Connect(function()
		applyScaleRatio(sb.ratio)
	end)
end

-- Çevir & Sürükle-Taşı Kontrolleri
local moveSection = Instance.new("Frame")
moveSection.Size = UDim2.new(1, 0, 0, 75)
moveSection.Position = UDim2.new(0, 0, 0, 352)
moveSection.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
moveSection.Parent = page1
corner(moveSection, 8)

local dragBtn = Instance.new("TextButton")
dragBtn.Size = UDim2.new(0.46, 0, 0, 38)
dragBtn.Position = UDim2.new(0.04, 0, 0.5, -19)
dragBtn.BackgroundColor3 = Color3.fromRGB(35, 100, 60)
dragBtn.Text = "🖐️ Sürükle / Taşı"
dragBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dragBtn.Font = Enum.Font.FredokaOne
dragBtn.TextSize = 12
dragBtn.Parent = moveSection
corner(dragBtn, 6)

dragBtn.MouseButton1Click:Connect(function()
	if selectedModel then
		startDragging(selectedModel)
	end
end)

local rotateBtn = Instance.new("TextButton")
rotateBtn.Size = UDim2.new(0.24, 0, 0, 38)
rotateBtn.Position = UDim2.new(0.53, 0, 0.5, -19)
rotateBtn.BackgroundColor3 = Color3.fromRGB(45, 60, 85)
rotateBtn.Text = "↻ 90°"
rotateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rotateBtn.Font = Enum.Font.FredokaOne
rotateBtn.TextSize = 12
rotateBtn.Parent = moveSection
corner(rotateBtn, 6)

rotateBtn.MouseButton1Click:Connect(function()
	if not selectedModel then return end
	Network.CustomizeModelEvent:FireServer(currentPlotIndex, selectedModel.Name, "Rotate", 90)
end)

local clickSelectBtn = Instance.new("TextButton")
clickSelectBtn.Size = UDim2.new(0.18, 0, 0, 38)
clickSelectBtn.Position = UDim2.new(0.79, 0, 0.5, -19)
clickSelectBtn.BackgroundColor3 = Color3.fromRGB(85, 70, 35)
clickSelectBtn.Text = "🔄"
clickSelectBtn.TextColor3 = Color3.fromRGB(255, 230, 100)
clickSelectBtn.Font = Enum.Font.FredokaOne
clickSelectBtn.TextSize = 13
clickSelectBtn.Parent = moveSection
corner(clickSelectBtn, 6)

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
corner(slotScroll, 8)

local ssLayout = Instance.new("UIListLayout")
ssLayout.Padding = UDim.new(0, 8)
ssLayout.Parent = slotScroll

local availableShops = {
	{ "Bakery", "🥖 Taş Fırın" }, { "Market", "🛒 Süpermarket" }, { "Fountain", "⛲ Süs Havuzu" },
	{ "Barber", "💈 VIP Kuaför" }, { "PetShop", "🐾 Pet Shop" }, { "Restaurant", "🍽️ Bistro" }, { "Empty", "❌ Boş" },
}

for slotIdx = 1, 6 do
	local card = Instance.new("Frame")
	card.Size, card.BackgroundColor3, card.Parent = UDim2.new(1, -8, 0, 70), Color3.fromRGB(30, 35, 45), slotScroll
	corner(card, 8)

	local label = Instance.new("TextLabel")
	label.Size, label.Position, label.BackgroundTransparency = UDim2.new(0.9, 0, 0, 24), UDim2.new(0.04, 0, 0, 4), 1
	label.Text, label.TextColor3, label.Font, label.TextSize = string.format("🏛️ Çarşı Yuvası (Slot %d):", slotIdx), Color3.fromRGB(255, 215, 60), Enum.Font.FredokaOne, 13
	label.TextXAlignment, label.Parent = Enum.TextXAlignment.Left, card

	local optScroll = Instance.new("ScrollingFrame")
	optScroll.Size, optScroll.Position, optScroll.BackgroundTransparency = UDim2.new(0.94, 0, 0, 32), UDim2.new(0.03, 0, 0, 30), 1
	optScroll.ScrollBarThickness, optScroll.ScrollingDirection, optScroll.CanvasSize = 3, Enum.ScrollingDirection.X, UDim2.new(0, #availableShops * 115, 0, 0)
	optScroll.Parent = card

	local optLayout = Instance.new("UIListLayout")
	optLayout.FillDirection, optLayout.Padding, optLayout.Parent = Enum.FillDirection.Horizontal, UDim.new(0, 4), optScroll

	for _, shop in ipairs(availableShops) do
		local oBtn = Instance.new("TextButton")
		oBtn.Size, oBtn.BackgroundColor3, oBtn.Text = UDim2.new(0, 110, 1, 0), Color3.fromRGB(42, 48, 62), shop[2]
		oBtn.TextColor3, oBtn.Font, oBtn.TextSize, oBtn.Parent = Color3.fromRGB(230, 235, 245), Enum.Font.FredokaOne, 11, optScroll
		corner(oBtn, 6)

		oBtn.MouseButton1Click:Connect(function()
			Network.ChangePromenadeSlotEvent:FireServer(currentPlotIndex, slotIdx, shop[1])
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
catScroll.CanvasSize = UDim2.new(0, 0, 0, 580)
catScroll.Parent = page3
corner(catScroll, 8)

local csLayout = Instance.new("UIListLayout")
csLayout.Padding = UDim.new(0, 5)
csLayout.Parent = catScroll

local catalogItems = {
	{ "Buildings", "Level_1", "🏠 Ahşap Kulübe (Lv.1)" }, { "Buildings", "Level_2", "🏡 Tuğla Malikâne (Lv.2)" },
	{ "Buildings", "Level_3", "🏰 Lüks Villa (Lv.3)" }, { "Buildings", "Level_4", "🏢 Rezidans Apartman (Lv.4)" },
	{ "Buildings", "Level_5", "🏙️ Prestij Gökdelen (Lv.5)" }, { "Buildings", "Level_6", "🏢 Modern İş Merkezi (Lv.6)" },
	{ "Buildings", "Level_7", "🚒 İtfaiye İstasyonu (Lv.7)" }, { "Buildings", "Level_8", "🏥 Sağlık Kliniği (Lv.8)" },
	{ "Buildings", "Level_9", "🏙️ Finans İkiz Kule (Lv.9)" }, { "Buildings", "Level_10", "✨ Metropolis Gökdelen (Lv.10)" },
	{ "Commercial", "Bakery", "🥖 Taş Fırın Dükkanı" }, { "Commercial", "Market", "🛒 Süpermarket" },
	{ "Commercial", "Fountain", "⛲ Süs Havuzu" }, { "Commercial", "Barber", "💈 Kuaför Salonu" },
	{ "Commercial", "Restaurant", "🍽️ Bistro Kafe" }, { "Trees", "PineTree", "🌲 Dağ Çamı Ağacı" },
	{ "Trees", "GardenTree", "🌳 Bahçe Meşe Ağacı" }, { "Props", "StreetLamp", "🏮 Sokak Lambası" },
	{ "Props", "Bench", "🪑 Park Bankı" }, { "Props", "Planter", "🪴 Çiçeklik" },
}

for _, item in ipairs(catalogItems) do
	local row = Instance.new("Frame")
	row.Size, row.BackgroundColor3, row.Parent = UDim2.new(1, -8, 0, 32), Color3.fromRGB(30, 35, 46), catScroll
	corner(row, 6)

	local lbl = Instance.new("TextLabel")
	lbl.Size, lbl.Position, lbl.BackgroundTransparency = UDim2.new(0.68, 0, 1, 0), UDim2.new(0.03, 0, 0, 0), 1
	lbl.Text, lbl.TextColor3, lbl.Font, lbl.TextSize, lbl.TextXAlignment, lbl.Parent = item[3], Color3.fromRGB(230, 235, 245), Enum.Font.FredokaOne, 11, Enum.TextXAlignment.Left, row

	local spawnBtn = Instance.new("TextButton")
	spawnBtn.Size, spawnBtn.Position, spawnBtn.BackgroundColor3 = UDim2.new(0.26, 0, 0.75, 0), UDim2.new(0.71, 0, 0.12, 0), Color3.fromRGB(50, 95, 60)
	spawnBtn.Text, spawnBtn.TextColor3, spawnBtn.Font, spawnBtn.TextSize, spawnBtn.Parent = "➕ Ekle", Color3.fromRGB(255, 255, 255), Enum.Font.FredokaOne, 11, row
	corner(spawnBtn, 6)

	spawnBtn.MouseButton1Click:Connect(function()
		Network.SpawnAssetOnPlotEvent:FireServer(currentPlotIndex, item[1], item[2])
		spawnBtn.BackgroundColor3 = Color3.fromRGB(80, 140, 90)
		task.delay(0.5, function()
			spawnBtn.BackgroundColor3 = Color3.fromRGB(50, 95, 60)
			refreshPlotObjectsList()
		end)
	end)
end

local function getPlotOrigin(): Vector3
	local plotFolder = Workspace:FindFirstChild(string.format("Plot_%s_%d", localPlayer.Name, currentPlotIndex))
	local ground = plotFolder and plotFolder:FindFirstChild("PlotGround") :: BasePart?
	return ground and ground.Position or Vector3.new(0, 4.4, 0)
end

local function setGameplayHUDVisible(vis: boolean)
	for _, name in ipairs({ "BuilderHUD", "UpgradeUI", "GarageUI" }) do
		local g = playerGui:FindFirstChild(name)
		if g and g:IsA("ScreenGui") then
			g.Enabled = vis
		end
	end
end

-- Aç/Kapa Etkileşimi (360° Kuş Bakışı Kamera Entegrasyonu & Oyun Döngüsünü Susturma)
local function togglePanel()
	panel.Visible = not panel.Visible
	toggleBtn.BackgroundColor3 = panel.Visible and Color3.fromRGB(60, 70, 90) or Color3.fromRGB(35, 40, 50)
	cameraBar.Visible = panel.Visible
	setGameplayHUDVisible(not panel.Visible)
	if panel.Visible then
		CustomizerCameraController.Enable(getPlotOrigin())
		refreshPlotObjectsList()
	else
		if isDragging then stopDragging(false) end
		CustomizerCameraController.Disable()
		updateSelection(nil)
	end
end

panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then refreshPlotObjectsList() end
end)

toggleBtn.MouseButton1Click:Connect(togglePanel)
closeBtn.MouseButton1Click:Connect(togglePanel)

-- Canlı Sürükleme Render Döngüsü (Kusursuz Matematiksel Zemin Düzlemi Kesişimi)
RunService.RenderStepped:Connect(function()
	if not (isDragging and draggedModel) then return end

	local mousePos = UserInputService:GetMouseLocation()
	local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
	local plotFolder = Workspace:FindFirstChild(string.format("Plot_%s_%d", localPlayer.Name, currentPlotIndex))
	if not plotFolder then return end

	local ground = plotFolder:FindFirstChild("PlotGround") :: BasePart?
	local origin = ground and ground.Position or Vector3.new(0, 0, 0)
	local groundY = origin.Y + 2.0

	-- Matematiksel Düzlem Kesişimi (Y = groundY)
	if math.abs(ray.Direction.Y) > 0.0001 then
		local t = (groundY - ray.Origin.Y) / ray.Direction.Y
		if t > 0 then
			local hitPoint = ray.Origin + ray.Direction * t
			local clampedX = math.clamp(hitPoint.X, origin.X - 35, origin.X + 35)
			local clampedZ = math.clamp(hitPoint.Z, origin.Z - 35, origin.Z + 35)

			local targetRot = CFrame.Angles(0, math.rad(dragYaw), 0)
			draggedModel:PivotTo(CFrame.new(clampedX, groundY, clampedZ) * targetRot)

			local minY = math.huge
			for _, p in ipairs(draggedModel:GetDescendants()) do
				if p:IsA("BasePart") then
					minY = math.min(minY, p.Position.Y - p.Size.Y / 2)
				end
			end
			draggedModel:PivotTo(draggedModel:GetPivot() + Vector3.new(0, groundY - minY, 0))
		end
	end
end)

-- Klavye ve Fare Giriş Dinleyicisi
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.F4 and not gameProcessed then
		togglePanel()
	elseif input.KeyCode == Enum.KeyCode.R and isDragging and draggedModel then
		dragYaw = (dragYaw + 45) % 360
		dragBannerText.Text = string.format("🖐️ %s (%d°)", draggedModel.Name, dragYaw)
	elseif input.KeyCode == Enum.KeyCode.Escape and isDragging then
		stopDragging(false)
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		if isDragging and not gameProcessed then
			stopDragging(true)
		elseif panel.Visible and not gameProcessed then
			-- 3D Sahne veya Kenardaki Showroom Rafından Tıklayarak Seçme
			local mousePos = UserInputService:GetMouseLocation()
			local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
			local plotFolder = Workspace:FindFirstChild(string.format("Plot_%s_%d", localPlayer.Name, currentPlotIndex))
			if plotFolder then
				local showroom = plotFolder:FindFirstChild("ShowroomPalette")
				local filterList = { plotFolder }
				if showroom then table.insert(filterList, showroom) end

				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Include
				rayParams.FilterDescendantsInstances = filterList
				local hit = Workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
				if hit and hit.Instance then
					local clicked = hit.Instance:FindFirstAncestorOfClass("Model")
					if clicked then
						updateSelection(clicked)
					end
				end
			end
		end
	end
end)

print("🛠️ DevCustomizerUI (360° Kuş Bakışı Kamera & Sürükle-Bırak Motoru) Aktif. [F4]")

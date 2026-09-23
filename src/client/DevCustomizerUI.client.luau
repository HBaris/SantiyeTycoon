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

-- 2. Ana Panel (Drawer Card - Sürüklenebilir & Chat Bölgesinden Uzak)
local panel = Instance.new("Frame")
panel.Name = "CustomizerPanel"
panel.Size = UDim2.new(0, 390, 0, 560)
panel.Position = UDim2.new(0, 20, 0.5, -280)
panel.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui
corner(panel, 14)
stroke(panel, Color3.fromRGB(55, 60, 75), 2)

-- Başlık Çubuğu (Tut-Sürükle Özellikli)
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 46)
header.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
header.BorderSizePixel = 0
header.Parent = panel
corner(header, 14)

local draggingHeader = false
local dragStartPos = Vector2.zero
local frameStartPos = UDim2.new()

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingHeader = true
		dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
		frameStartPos = panel.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				draggingHeader = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingHeader and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPos
		panel.Position = UDim2.new(
			frameStartPos.X.Scale,
			frameStartPos.X.Offset + delta.X,
			frameStartPos.Y.Scale,
			frameStartPos.Y.Offset + delta.Y
		)
	end
end)

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

local function switchTab(index: number)
	activeTab = index
	for i, btn in ipairs(tabButtons) do
		btn.BackgroundColor3 = (i == index) and Color3.fromRGB(45, 55, 75) or Color3.fromRGB(25, 28, 35)
		btn.TextColor3 = (i == index) and Color3.fromRGB(255, 225, 80) or Color3.fromRGB(180, 185, 195)
		tabPages[i].Visible = (i == index)
	end
end

for i, tName in ipairs(tabNames) do
	local tBtn = Instance.new("TextButton")
	tBtn.Size, tBtn.Position = UDim2.new(1 / #tabNames, -4, 1, -4), UDim2.new((i - 1) * (1 / #tabNames), 2, 0, 2)
	tBtn.BackgroundColor3 = (i == 1) and Color3.fromRGB(45, 55, 75) or Color3.fromRGB(25, 28, 35)
	tBtn.Text, tBtn.TextColor3 = tName, (i == 1) and Color3.fromRGB(255, 225, 80) or Color3.fromRGB(180, 185, 195)
	tBtn.Font, tBtn.TextSize, tBtn.Parent = Enum.Font.FredokaOne, 12, tabBar
	corner(tBtn, 6)
	tBtn.MouseButton1Click:Connect(function() switchTab(i) end)
	table.insert(tabButtons, tBtn)
	table.insert(tabPages, createTabPage(i))
end

-- ============================================================================
-- SEKME 1: 🔍 MODEL SEÇ, İNCELE VE CANLI BÜYÜT/KÜÇÜLT
-- ============================================================================
local page1 = tabPages[1]

-- Seçilen Nesne Bilgi Kartı
local infoCard = Instance.new("Frame")
infoCard.Size = UDim2.new(1, 0, 0, 68)
infoCard.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
infoCard.Parent = page1
corner(infoCard, 8)

local selNameLabel = Instance.new("TextLabel")
selNameLabel.Size = UDim2.new(0.9, 0, 0.45, 0)
selNameLabel.Position = UDim2.new(0.05, 0, 0.06, 0)
selNameLabel.BackgroundTransparency = 1
selNameLabel.Text = "Seçili: (Bir nesne seçin)"
selNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
selNameLabel.Font = Enum.Font.FredokaOne
selNameLabel.TextSize = 13
selNameLabel.TextXAlignment = Enum.TextXAlignment.Left
selNameLabel.Parent = infoCard

local selDimLabel = Instance.new("TextLabel")
selDimLabel.Size = UDim2.new(0.9, 0, 0.45, 0)
selDimLabel.Position = UDim2.new(0.05, 0, 0.52, 0)
selDimLabel.BackgroundTransparency = 1
selDimLabel.Text = "Konum & Boyut: --"
selDimLabel.TextColor3 = Color3.fromRGB(140, 220, 170)
selDimLabel.Font = Enum.Font.GothamBold
selDimLabel.TextSize = 11
selDimLabel.TextXAlignment = Enum.TextXAlignment.Left
selDimLabel.Parent = infoCard

-- Hızlı Nesne Seçici Dropdown / Buton Listesi
local pickListFrame = Instance.new("ScrollingFrame")
pickListFrame.Size = UDim2.new(1, 0, 0, 80)
pickListFrame.Position = UDim2.new(0, 0, 0, 74)
pickListFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
pickListFrame.ScrollBarThickness = 5
pickListFrame.CanvasSize = UDim2.new(0, 0, 0, 360)
pickListFrame.Parent = page1
corner(pickListFrame, 8)

local plLayout = Instance.new("UIListLayout")
plLayout.Padding = UDim.new(0, 4)
plLayout.Parent = pickListFrame

local function refreshSelectionInfo()
	if selectedModel and selectedModel.Parent then
		local cf, size = selectedModel:GetBoundingBox()
		local curScale = (selectedModel.GetScale and selectedModel:GetScale()) or 1.0
		selNameLabel.Text = "Seçili: " .. selectedModel.Name
		selDimLabel.Text = string.format("X:%.1f Y:%.1f Z:%.1f | %.1fx%.1fx%.1f (%.1fx)", cf.Position.X, cf.Position.Y, cf.Position.Z, size.X, size.Y, size.Z, curScale)
	else
		selNameLabel.Text = "Seçili: (Bir nesne seçin)"
		selDimLabel.Text = "Konum & Boyut: --"
	end
end

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
		refreshSelectionInfo()
	else
		selectionHighlight.Adornee = nil
		refreshSelectionInfo()
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
		btn.Size, btn.BackgroundColor3 = UDim2.new(1, -8, 0, 30), Color3.fromRGB(35, 40, 52)
		btn.Text, btn.TextColor3 = "  📦 " .. name, Color3.fromRGB(220, 225, 235)
		btn.Font, btn.TextSize, btn.TextXAlignment, btn.Parent = Enum.Font.FredokaOne, 12, Enum.TextXAlignment.Left, pickListFrame
		corner(btn, 6)
		btn.MouseButton1Click:Connect(function() updateSelection(targetModel) end)
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

-- ============================================================================
-- LEVEL CREATOR GELİŞMİŞ DÜZENLEME PANELİ (Yükseklik, Konum, Döndürme, Ölçek)
-- ============================================================================
local ctrlSection = Instance.new("Frame")
ctrlSection.Size = UDim2.new(1, 0, 0, 260)
ctrlSection.Position = UDim2.new(0, 0, 0, 160)
ctrlSection.BackgroundColor3 = Color3.fromRGB(26, 30, 38)
ctrlSection.Parent = page1
corner(ctrlSection, 8)

local ctrlTitle = Instance.new("TextLabel")
ctrlTitle.Size = UDim2.new(0.92, 0, 0, 22)
ctrlTitle.Position = UDim2.new(0.04, 0, 0, 4)
ctrlTitle.BackgroundTransparency = 1
ctrlTitle.Text = "🎛️ SEVİYE TASARIMCI KONTROLLERİ (LEVEL CREATOR)"
ctrlTitle.TextColor3 = Color3.fromRGB(255, 215, 60)
ctrlTitle.Font = Enum.Font.FredokaOne
ctrlTitle.TextSize = 11
ctrlTitle.TextXAlignment = Enum.TextXAlignment.Left
ctrlTitle.Parent = ctrlSection

local function btn(text: string, color: Color3, size: UDim2, pos: UDim2, onClick: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Size, b.Position, b.BackgroundColor3 = size, pos, color
	b.Text, b.TextColor3, b.Font, b.TextSize = text, Color3.fromRGB(255, 255, 255), Enum.Font.FredokaOne, 11
	b.Parent = ctrlSection
	corner(b, 6)
	b.MouseButton1Click:Connect(onClick)
	return b
end

local function applyNudge(offset: Vector3)
	if not selectedModel then
		selNameLabel.Text = "⚠️ Lütfen önce bir nesne seçin!"
		return
	end
	Network.CustomizeModelEvent:FireServer(currentPlotIndex, selectedModel.Name, "Nudge", offset)
	task.delay(0.12, refreshSelectionInfo)
end

local function applySnapGround()
	if not selectedModel then return end
	Network.CustomizeModelEvent:FireServer(currentPlotIndex, selectedModel.Name, "SnapGround")
	task.delay(0.12, refreshSelectionInfo)
end

local function applyDelete()
	if not selectedModel then return end
	local targetName = selectedModel.Name
	Network.CustomizeModelEvent:FireServer(currentPlotIndex, targetName, "Delete")
	updateSelection(nil)
	task.delay(0.2, refreshPlotObjectsList)
end

local function applyRotate(deg: number)
	if not selectedModel then return end
	Network.CustomizeModelEvent:FireServer(currentPlotIndex, selectedModel.Name, "Rotate", deg)
	task.delay(0.12, refreshSelectionInfo)
end

local function applyScaleRatio(ratio: number)
	if not selectedModel then return end
	Network.CustomizeModelEvent:FireServer(currentPlotIndex, selectedModel.Name, "Scale", ratio)
	task.delay(0.15, refreshSelectionInfo)
end

local function applyResetScale()
	if not selectedModel then return end
	Network.CustomizeModelEvent:FireServer(currentPlotIndex, selectedModel.Name, "SetScale", 1.0)
	task.delay(0.15, refreshSelectionInfo)
end

-- Satır 1: Hızlı Eylemler (Zemine İndir / Sürükle / Sil)
btn("🎯 Zemine İndir", Color3.fromRGB(35, 110, 70), UDim2.new(0.38, 0, 0, 30), UDim2.new(0.04, 0, 0, 28), applySnapGround)
btn("🖐️ Sürükle", Color3.fromRGB(40, 80, 130), UDim2.new(0.28, 0, 0, 30), UDim2.new(0.44, 0, 0, 28), function() if selectedModel then startDragging(selectedModel) end end)
btn("🗑️ Sil", Color3.fromRGB(130, 40, 40), UDim2.new(0.22, 0, 0, 30), UDim2.new(0.74, 0, 0, 28), applyDelete)

-- Satır 2: Dikey Yükseklik (Y Ekseni)
btn("🔼 +1 Y", Color3.fromRGB(50, 65, 85), UDim2.new(0.22, 0, 0, 28), UDim2.new(0.04, 0, 0, 64), function() applyNudge(Vector3.new(0, 1, 0)) end)
btn("🔽 -1 Y", Color3.fromRGB(50, 65, 85), UDim2.new(0.22, 0, 0, 28), UDim2.new(0.28, 0, 0, 64), function() applyNudge(Vector3.new(0, -1, 0)) end)
btn("⏫ +5 Y", Color3.fromRGB(40, 55, 75), UDim2.new(0.22, 0, 0, 28), UDim2.new(0.52, 0, 0, 64), function() applyNudge(Vector3.new(0, 5, 0)) end)
btn("⏬ -5 Y", Color3.fromRGB(40, 55, 75), UDim2.new(0.22, 0, 0, 28), UDim2.new(0.76, 0, 0, 64), function() applyNudge(Vector3.new(0, -5, 0)) end)

-- Satır 3: Yatay İnce Ayar (X & Z Eksenleri)
btn("⬅️ -1 X", Color3.fromRGB(45, 55, 70), UDim2.new(0.22, 0, 0, 28), UDim2.new(0.04, 0, 0, 98), function() applyNudge(Vector3.new(-1, 0, 0)) end)
btn("➡️ +1 X", Color3.fromRGB(45, 55, 70), UDim2.new(0.22, 0, 0, 28), UDim2.new(0.28, 0, 0, 98), function() applyNudge(Vector3.new(1, 0, 0)) end)
btn("⬆️ -1 Z", Color3.fromRGB(45, 55, 70), UDim2.new(0.22, 0, 0, 28), UDim2.new(0.52, 0, 0, 98), function() applyNudge(Vector3.new(0, 0, -1)) end)
btn("⬇️ +1 Z", Color3.fromRGB(45, 55, 70), UDim2.new(0.22, 0, 0, 28), UDim2.new(0.76, 0, 0, 98), function() applyNudge(Vector3.new(0, 0, 1)) end)

-- Satır 4: Döndürme (Rotation)
btn("↺ -45°", Color3.fromRGB(60, 50, 90), UDim2.new(0.28, 0, 0, 28), UDim2.new(0.04, 0, 0, 132), function() applyRotate(-45) end)
btn("↻ +45°", Color3.fromRGB(60, 50, 90), UDim2.new(0.28, 0, 0, 28), UDim2.new(0.34, 0, 0, 132), function() applyRotate(45) end)
btn("↻ 90° Çevir", Color3.fromRGB(45, 60, 105), UDim2.new(0.32, 0, 0, 28), UDim2.new(0.64, 0, 0, 132), function() applyRotate(90) end)

-- Satır 5: Canlı Boyutlandırma (Scale)
btn("[-] %25", Color3.fromRGB(75, 45, 45), UDim2.new(0.18, 0, 0, 28), UDim2.new(0.04, 0, 0, 166), function() applyScaleRatio(0.8) end)
btn("[+] %25", Color3.fromRGB(45, 75, 50), UDim2.new(0.18, 0, 0, 28), UDim2.new(0.23, 0, 0, 166), function() applyScaleRatio(1.25) end)
btn("1.5x", Color3.fromRGB(50, 70, 85), UDim2.new(0.17, 0, 0, 28), UDim2.new(0.42, 0, 0, 166), function() applyScaleRatio(1.5) end)
btn("2.0x", Color3.fromRGB(50, 70, 85), UDim2.new(0.17, 0, 0, 28), UDim2.new(0.60, 0, 0, 166), function() applyScaleRatio(2.0) end)
btn("1.0x", Color3.fromRGB(80, 65, 30), UDim2.new(0.17, 0, 0, 28), UDim2.new(0.78, 0, 0, 166), applyResetScale)

-- Satır 6: Liste Yenileme & Seçimi Kaldırma
btn("🔄 Listeyi Yenile", Color3.fromRGB(40, 50, 60), UDim2.new(0.45, 0, 0, 26), UDim2.new(0.04, 0, 0, 200), refreshPlotObjectsList)
btn("❌ Seçimi Kaldır", Color3.fromRGB(60, 40, 40), UDim2.new(0.45, 0, 0, 26), UDim2.new(0.51, 0, 0, 200), function() updateSelection(nil) end)

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
catScroll.CanvasSize = UDim2.new(0, 0, 0, 1300)
catScroll.Parent = page3
corner(catScroll, 8)

local csLayout = Instance.new("UIListLayout")
csLayout.Padding = UDim.new(0, 5)
csLayout.Parent = catScroll

local catalogItems = {
	{ "Buildings", "Level_1", "🏠 Ahşap Kulübe (Lv.1)" }, { "Buildings", "Level_2", "🏡 Tuğla Malikâne (Lv.2)" }, { "Buildings", "Level_3", "🏰 Lüks Villa (Lv.3)" },
	{ "Buildings", "Level_4", "🏢 Rezidans Apartman (Lv.4)" }, { "Buildings", "Level_5", "🏙️ Prestij Gökdelen (Lv.5)" }, { "Buildings", "Level_6", "🏢 Modern İş Merkezi (Lv.6)" },
	{ "Buildings", "Level_7", "🚒 İtfaiye İstasyonu (Lv.7)" }, { "Buildings", "Level_8", "🏥 Sağlık Kliniği (Lv.8)" }, { "Buildings", "Level_9", "🏙️ Finans İkiz Kule (Lv.9)" },
	{ "Buildings", "Level_10", "✨ Metropolis Gökdelen (Lv.10)" }, { "Vehicles", "Scooter", "🛵 Şantiye Scooter'ı" }, { "Vehicles", "Pickup", "🛻 Şantiye Kamyoneti" },
	{ "Vehicles", "Forklift", "🚜 Şantiye Forklifti" }, { "Vehicles", "DumpTruck", "🚛 Damperli Kamyon" }, { "Cargo", "BrickPallet", "🧱 Tuğla Paleti" },
	{ "Cargo", "CementBags", "📦 Çimento Torbaları" }, { "Cargo", "CargoCrate", "🧰 Kargo Sandığı" }, { "Cargo", "SteelRebar", "⛓️ İnşaat Demiri" },
	{ "Cargo", "OilBarrels", "🛢️ Yakıt Varilleri" }, { "Cargo", "SiteContainer", "🏠 Şantiye Konteyneri" }, { "Commercial", "Bakery", "🥖 Taş Fırın Dükkanı" },
	{ "Commercial", "Market", "🛒 Süpermarket" }, { "Commercial", "Fountain", "⛲ Süs Havuzu" }, { "Commercial", "Barber", "💈 Kuaför Salonu" },
	{ "Commercial", "Restaurant", "🍽️ Bistro Kafe" }, { "Trees", "PineTree", "🌲 Dağ Çamı Ağacı" }, { "Trees", "GardenTree", "🌳 Bahçe Meşe Ağacı" },
	{ "Trees", "CypressTree", "🌲 Selvi Ağacı" }, { "Trees", "BoulevardTree", "🌴 Bulvar Ağacı" }, { "Trees", "HedgeBush", "🌿 Çit Çalılığı" },
	{ "Props", "StreetLamp", "🏮 Sokak Lambası" }, { "Props", "Bench", "🪑 Park Bankı" }, { "Props", "Planter", "🪴 Çiçeklik" }, { "Props", "StoneRock", "🪨 Peyzaj Kayası" },
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
	pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, not panel.Visible) end)
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
			local clampedX = math.clamp(hitPoint.X, origin.X - 85, origin.X + 85)
			local clampedZ = math.clamp(hitPoint.Z, origin.Z - 85, origin.Z + 85)
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
			local mousePos = UserInputService:GetMouseLocation()
			local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
			local plotFolder = Workspace:FindFirstChild(string.format("Plot_%s_%d", localPlayer.Name, currentPlotIndex))
			local showroom = plotFolder and plotFolder:FindFirstChild("ShowroomPalette")
			local prom = plotFolder and plotFolder:FindFirstChild("CommercialPromenade")

			local char = localPlayer.Character
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = char and { char } or {}

			local hit = Workspace:Raycast(ray.Origin, ray.Direction * 1500, rayParams)
			if hit and hit.Instance then
				local cur: Instance? = hit.Instance
				local top: Model? = nil
				while cur and cur ~= Workspace do
					if cur:IsA("Model") then
						if plotFolder and (cur.Parent == plotFolder or (showroom and cur.Parent == showroom) or (prom and cur.Parent == prom)) then
							top = cur
							break
						end
						top = cur
					end
					cur = cur.Parent
				end
				if top and top ~= Workspace then updateSelection(top) end
			end
		end
	end
end)

print("🛠️ DevCustomizerUI (360° Kuş Bakışı Kamera & Seviye Tasarımcısı) Aktif. [F4]")

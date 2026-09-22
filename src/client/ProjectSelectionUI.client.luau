local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Network = require(ReplicatedStorage.Shared.Network)
local ProjectTypeConfig = require(ReplicatedStorage.Shared.ProjectTypeConfig)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)

local function playSfx(soundPath: string, volume: number?, pitch: number?)
	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = soundPath
		sound.Volume = volume or 0.5
		sound.PlaybackSpeed = pitch or 1.0
		sound.Parent = SoundService
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end)
end

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProjectSelectionScreen"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Karartma Arka Planı
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.Visible = false
overlay.Parent = screenGui

-- Ana Modal Penceresi (Yatay 4 Kart Gösterimi)
local modal = Instance.new("Frame")
modal.Name = "SelectionModal"
modal.Size = UDim2.new(0, 840, 0, 520)
modal.Position = UDim2.new(0.5, -420, 0.5, -260)
modal.BackgroundColor3 = Color3.fromRGB(250, 248, 242)
modal.BorderSizePixel = 0
modal.ClipsDescendants = true
modal.Visible = false
modal.Parent = screenGui

local mCorner = Instance.new("UICorner")
mCorner.CornerRadius = UDim.new(0, 20)
mCorner.Parent = modal

local mStroke = Instance.new("UIStroke")
mStroke.Color = Color3.fromRGB(215, 195, 170)
mStroke.Thickness = 4
mStroke.Parent = modal

-- Başlık
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 68)
header.BackgroundColor3 = Color3.fromRGB(240, 235, 222)
header.BorderSizePixel = 0
header.Parent = modal

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0.7, 0, 0.6, 0)
title.Position = UDim2.new(0, 24, 0, 8)
title.BackgroundTransparency = 1
title.Text = "🏗️ YENİ ŞANTİYE PROJESİ SEÇİMİ"
title.TextColor3 = Color3.fromRGB(20, 20, 20)
title.Font = Enum.Font.FredokaOne
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(0.7, 0, 0.4, 0)
subtitle.Position = UDim2.new(0, 24, 0, 40)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Yeni şantiyenizin yatırım ölçeğini ve inşaat modelini belirleyin:"
subtitle.TextColor3 = Color3.fromRGB(100, 100, 105)
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 13
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 38, 0, 38)
closeBtn.Position = UDim2.new(1, -50, 0, 15)
closeBtn.BackgroundColor3 = Color3.fromRGB(230, 220, 210)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(30, 30, 30)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextSize = 20
closeBtn.BorderSizePixel = 0
closeBtn.Parent = header

local cbCorner = Instance.new("UICorner")
cbCorner.CornerRadius = UDim.new(0, 10)
cbCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	modal.Visible = false
	overlay.Visible = false
end)

-- Kartlar Alanı (4 Sütun Yatay Dizilim)
local cardsContainer = Instance.new("Frame")
cardsContainer.Name = "CardsContainer"
cardsContainer.Size = UDim2.new(1, -40, 1, -88)
cardsContainer.Position = UDim2.new(0, 20, 0, 78)
cardsContainer.BackgroundTransparency = 1
cardsContainer.Parent = modal

local function openSelection(nextPlotIndex: number)
	nextPlotIndex = nextPlotIndex or 2
	local plotCost = GameConfig.GetPlotCost(nextPlotIndex)

	subtitle.Text = string.format("Şantiye #%d için yatırım türünü seçin (Maliyet: %s):", nextPlotIndex, NumberFormat.FormatCash(plotCost))

	-- Önceki kartları temizle
	for _, child in ipairs(cardsContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local count = #ProjectTypeConfig.ORDER
	local totalW = 760
	local gap = 20
	local cardWidth = math.floor((totalW - ((count - 1) * gap)) / count)

	for i, typeId in ipairs(ProjectTypeConfig.ORDER) do
		local tData = ProjectTypeConfig.TYPES[typeId]
		local card = Instance.new("Frame")
		card.Name = "Card_" .. typeId
		card.Size = UDim2.new(0, cardWidth, 1, -15)
		card.Position = UDim2.new(0, (i - 1) * (cardWidth + gap), 0, 5)
		card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		card.BorderSizePixel = 0
		card.Parent = cardsContainer

		local cdCorner = Instance.new("UICorner")
		cdCorner.CornerRadius = UDim.new(0, 14)
		cdCorner.Parent = card

		local cdStroke = Instance.new("UIStroke")
		cdStroke.Color = Color3.fromRGB(225, 220, 210)
		cdStroke.Thickness = 2
		cdStroke.Parent = card

		-- Rozet / Badge
		local badge = Instance.new("TextLabel")
		badge.Size = UDim2.new(0.9, 0, 0, 22)
		badge.Position = UDim2.new(0.05, 0, 0, 10)
		badge.BackgroundColor3 = Color3.fromRGB(240, 235, 220)
		badge.Text = tData.Badge
		badge.TextColor3 = Color3.fromRGB(50, 50, 55)
		badge.Font = Enum.Font.FredokaOne
		badge.TextSize = 10
		badge.Parent = card
		local bgCorner = Instance.new("UICorner")
		bgCorner.CornerRadius = UDim.new(0, 6)
		bgCorner.Parent = badge

		-- İkon & İsim
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size = UDim2.new(1, 0, 0, 48)
		iconLbl.Position = UDim2.new(0, 0, 0, 36)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Text = tData.Icon
		iconLbl.Font = Enum.Font.FredokaOne
		iconLbl.TextSize = 36
		iconLbl.Parent = card

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(0.9, 0, 0, 34)
		nameLbl.Position = UDim2.new(0.05, 0, 0, 84)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = tData.Name
		nameLbl.TextColor3 = Color3.fromRGB(20, 20, 20)
		nameLbl.Font = Enum.Font.FredokaOne
		nameLbl.TextSize = 14
		nameLbl.TextWrapped = true
		nameLbl.Parent = card

		-- Zorluk Derecesi
		local diffLbl = Instance.new("TextLabel")
		diffLbl.Size = UDim2.new(0.9, 0, 0, 20)
		diffLbl.Position = UDim2.new(0.05, 0, 0, 118)
		diffLbl.BackgroundTransparency = 1
		diffLbl.Text = tData.Difficulty
		diffLbl.TextColor3 = Color3.fromRGB(180, 120, 0)
		diffLbl.Font = Enum.Font.FredokaOne
		diffLbl.TextSize = 12
		diffLbl.Parent = card

		-- Açıklama
		local descLbl = Instance.new("TextLabel")
		descLbl.Size = UDim2.new(0.9, 0, 0, 58)
		descLbl.Position = UDim2.new(0.05, 0, 0, 140)
		descLbl.BackgroundTransparency = 1
		descLbl.Text = tData.Description
		descLbl.TextColor3 = Color3.fromRGB(80, 80, 85)
		descLbl.Font = Enum.Font.GothamMedium
		descLbl.TextSize = 11
		descLbl.TextWrapped = true
		descLbl.Parent = card

		-- Özellikler Kutusu
		local featBox = Instance.new("Frame")
		featBox.Size = UDim2.new(0.9, 0, 0, 92)
		featBox.Position = UDim2.new(0.05, 0, 0, 202)
		featBox.BackgroundColor3 = Color3.fromRGB(248, 246, 240)
		featBox.BorderSizePixel = 0
		featBox.Parent = card
		local fbCorner = Instance.new("UICorner")
		fbCorner.CornerRadius = UDim.new(0, 10)
		fbCorner.Parent = featBox

		local featLayout = Instance.new("UIListLayout")
		featLayout.Padding = UDim.new(0, 4)
		featLayout.Parent = featBox

		for _, featText in ipairs(tData.Features) do
			local fLbl = Instance.new("TextLabel")
			fLbl.Size = UDim2.new(1, -8, 0, 24)
			fLbl.Position = UDim2.new(0, 4, 0, 0)
			fLbl.BackgroundTransparency = 1
			fLbl.Text = featText
			fLbl.TextColor3 = Color3.fromRGB(40, 40, 45)
			fLbl.Font = Enum.Font.GothamBold
			fLbl.TextSize = 11
			fLbl.TextXAlignment = Enum.TextXAlignment.Left
			fLbl.Parent = featBox
		end

		-- Seç & Başlat Butonu
		local selectBtn = Instance.new("TextButton")
		selectBtn.Name = "SelectBtn"
		selectBtn.Size = UDim2.new(0.9, 0, 0, 48)
		selectBtn.Position = UDim2.new(0.05, 0, 1, -58)
		selectBtn.BackgroundColor3 = Color3.fromRGB(72, 220, 110)
		selectBtn.Text = "BAŞLAT 🚀\n" .. NumberFormat.FormatCash(plotCost)
		selectBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
		selectBtn.Font = Enum.Font.FredokaOne
		selectBtn.TextSize = 13
		selectBtn.BorderSizePixel = 0
		selectBtn.Parent = card

		local sCorner = Instance.new("UICorner")
		sCorner.CornerRadius = UDim.new(0, 12)
		sCorner.Parent = selectBtn

		local sStroke = Instance.new("UIStroke")
		sStroke.Color = Color3.fromRGB(30, 140, 60)
		sStroke.Thickness = 2.5
		sStroke.Parent = selectBtn

		selectBtn.MouseButton1Click:Connect(function()
			playSfx("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.3)
			modal.Visible = false
			overlay.Visible = false
			Network.SelectProjectTypeEvent:FireServer(typeId)
		end)
	end

	overlay.Visible = true
	modal.Visible = true
	playSfx("rbxasset://sounds/electronicpingshort.wav", 0.5, 1.0)
end

Network.OpenProjectSelectionEvent.OnClientEvent:Connect(function(nextPlotIndex)
	openSelection(nextPlotIndex)
end)

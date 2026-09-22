local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")

local Network = require(ReplicatedStorage.Shared.Network)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local ProjectTypeConfig = require(ReplicatedStorage.Shared.ProjectTypeConfig)
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local debounce = false
local currentBuildingLevel = 1
local currentPlotIndex = 1
local currentProjectType = "SingleBuilding"
local plotLevels = {} -- [plotIndex] = level
local isUpgradingAnimating = false

-- Güvenli Ses Çalma Fonksiyonu (Asla hata vermez)
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

-- Çekiç Vurma Eylemi
local function performHammerStrike()
	if debounce then return end
	debounce = true

	local character = localPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			pcall(function()
				local anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://522635532"
				local track = humanoid:LoadAnimation(anim)
				track:Play()
			end)
		end
	end

	playSfx("rbxasset://sounds/impact_wood.mp3", 0.4, 1.2)
	Network.HammerHitEvent:FireServer()
	task.wait(0.3)
	debounce = false
end

-- Ekranın ortasında çıkan "Turbo Aktif!" Bildirimi (Tamamen Siyah Yazı, Parlama Yok)
local function showTurboNotification(duration: number)
	local hud = playerGui:FindFirstChild("BuilderHUD")
	if not hud then return end

	local banner = hud:FindFirstChild("TurboBanner") :: TextLabel
	if not banner then return end

	banner.Visible = true
	banner.Text = string.format("🔥 2X TURBO İNŞAAT AKTİF! (%.0f sn) 🔥", duration)
	playSfx("rbxasset://sounds/electronicpingshort.wav", 0.5, 1.3)

	task.spawn(function()
		local timeLeft = duration
		while timeLeft > 0 do
			task.wait(0.1)
			timeLeft -= 0.1
			if banner and banner.Visible then
				banner.Text = string.format("🔥 2X TURBO İNŞAAT AKTİF! (%.1f sn) 🔥", math.max(0, timeLeft))
			end
		end
		if banner then
			banner.Visible = false
		end
	end)
end

-- Bina Başarıyla Yükseltildiğinde Ekranda Çıkan Kutlama Bildirimi (Tamamen Siyah Yazı)
local function showUpgradeCelebration(newLevel: number, buildingName: string, plotIdx: number)
	local hud = playerGui:FindFirstChild("BuilderHUD")
	if not hud then return end

	local banner = hud:FindFirstChild("UpgradeCelebration") :: TextLabel
	if not banner then return end

	playSfx("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.0)

	banner.Text = string.format("🎉 PROJE #%d YÜKSELTİLDİ! 🎉\n[Seviye %d: %s]", plotIdx, newLevel, buildingName)
	banner.Visible = true
	banner.Size = UDim2.new(0, 0, 0, 0)
	banner.Position = UDim2.new(0.5, 0, 0.35, 0)

	local popTween = TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 420, 0, 68),
		Position = UDim2.new(0.5, -210, 0.35, -34),
	})
	popTween:Play()

	task.delay(2.5, function()
		if banner and banner.Visible then
			local fadeTween = TweenService:Create(banner, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 0, 0, 0),
				Position = UDim2.new(0.5, 0, 0.35, 0),
			})
			fadeTween:Play()
			fadeTween.Completed:Connect(function()
				banner.Visible = false
			end)
		end
	end)
end

local function createBuilderHUD()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BuilderHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- 1. Turbo Bildirim Afişi (Ekranın Üst-Orta Kısmı, Siyah Yazı, Parlamasız)
	local turboBanner = Instance.new("TextLabel")
	turboBanner.Name = "TurboBanner"
	turboBanner.Size = UDim2.new(0, 360, 0, 44)
	turboBanner.Position = UDim2.new(0.5, -180, 0, 50)
	turboBanner.BackgroundColor3 = Color3.fromRGB(255, 205, 50)
	turboBanner.TextColor3 = Color3.fromRGB(20, 20, 20) -- SİYAH YAZI
	turboBanner.TextStrokeTransparency = 1 -- PARLAMA YOK
	turboBanner.Font = Enum.Font.FredokaOne
	turboBanner.TextSize = 16
	turboBanner.Visible = false
	turboBanner.Parent = screenGui

	local tbCorner = Instance.new("UICorner")
	tbCorner.CornerRadius = UDim.new(0, 12)
	tbCorner.Parent = turboBanner

	local tbStroke = Instance.new("UIStroke")
	tbStroke.Color = Color3.fromRGB(200, 120, 0)
	tbStroke.Thickness = 2.5
	tbStroke.Parent = turboBanner

	-- 2. Yükseltme Kutlama Afişi (Açık Nane Yeşili Kart, Siyah Yazı)
	local upgBanner = Instance.new("TextLabel")
	upgBanner.Name = "UpgradeCelebration"
	upgBanner.Size = UDim2.new(0, 420, 0, 68)
	upgBanner.Position = UDim2.new(0.5, -210, 0.35, -34)
	upgBanner.BackgroundColor3 = Color3.fromRGB(130, 245, 160)
	upgBanner.TextColor3 = Color3.fromRGB(20, 20, 20) -- SİYAH YAZI
	upgBanner.TextStrokeTransparency = 1 -- PARLAMA YOK
	upgBanner.Font = Enum.Font.FredokaOne
	upgBanner.TextSize = 18
	upgBanner.Visible = false
	upgBanner.Parent = screenGui

	local ubCorner = Instance.new("UICorner")
	ubCorner.CornerRadius = UDim.new(0, 14)
	ubCorner.Parent = upgBanner

	local ubStroke = Instance.new("UIStroke")
	ubStroke.Color = Color3.fromRGB(30, 140, 60)
	ubStroke.Thickness = 3
	ubStroke.Parent = upgBanner

	-- 2b. Üst Kaynak Sayacı (Kristal & Mühendis)
	local topResourceCard = Instance.new("Frame")
	topResourceCard.Name = "TopResourceCard"
	topResourceCard.Size = UDim2.new(0, 280, 0, 38)
	topResourceCard.Position = UDim2.new(0.5, -140, 0, 8)
	topResourceCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	topResourceCard.BackgroundTransparency = 0.05
	topResourceCard.BorderSizePixel = 0
	topResourceCard.Parent = screenGui

	local trCorner = Instance.new("UICorner")
	trCorner.CornerRadius = UDim.new(0, 12)
	trCorner.Parent = topResourceCard

	local trStroke = Instance.new("UIStroke")
	trStroke.Color = Color3.fromRGB(220, 210, 195)
	trStroke.Thickness = 2
	trStroke.Parent = topResourceCard

	local trLayout = Instance.new("UIListLayout")
	trLayout.FillDirection = Enum.FillDirection.Horizontal
	trLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	trLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	trLayout.Padding = UDim.new(0, 14)
	trLayout.Parent = topResourceCard

	local hudCrystals = Instance.new("TextLabel")
	hudCrystals.Name = "HudCrystals"
	hudCrystals.Size = UDim2.new(0, 120, 1, 0)
	hudCrystals.BackgroundTransparency = 1
	hudCrystals.Text = "💎 25"
	hudCrystals.TextColor3 = Color3.fromRGB(20, 20, 20)
	hudCrystals.Font = Enum.Font.FredokaOne
	hudCrystals.TextSize = 14
	hudCrystals.Parent = topResourceCard

	local hudEngineers = Instance.new("TextLabel")
	hudEngineers.Name = "HudEngineers"
	hudEngineers.Size = UDim2.new(0, 130, 1, 0)
	hudEngineers.BackgroundTransparency = 1
	hudEngineers.Text = "👷 0.00"
	hudEngineers.TextColor3 = Color3.fromRGB(20, 20, 20)
	hudEngineers.Font = Enum.Font.FredokaOne
	hudEngineers.TextSize = 14
	hudEngineers.Parent = topResourceCard

	Network.SyncResourcesEvent.OnClientEvent:Connect(function(cash, crystals, engineers)
		if crystals then hudCrystals.Text = NumberFormat.FormatCrystals(crystals) end
		if engineers then hudEngineers.Text = NumberFormat.FormatEngineers(engineers) end
	end)

	-- 3. Sağ Alttaki Hızlandır Butonu (Kompakt ve Şık Sarı Kart, Siyah Yazı)
	local hammerBtn = Instance.new("TextButton")
	hammerBtn.Name = "HammerQuickButton"
	hammerBtn.Size = UDim2.new(0, 135, 0, 42)
	hammerBtn.Position = UDim2.new(1, -150, 1, -55)
	hammerBtn.BackgroundColor3 = Color3.fromRGB(255, 195, 40)
	hammerBtn.Text = "⚡ HIZLANDIR\n(Çekiç Vur)"
	hammerBtn.TextColor3 = Color3.fromRGB(20, 20, 20) -- SİYAH YAZI
	hammerBtn.TextStrokeTransparency = 1 -- PARLAMA YOK
	hammerBtn.Font = Enum.Font.FredokaOne
	hammerBtn.TextSize = 13
	hammerBtn.Parent = screenGui

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 10)
	btnCorner.Parent = hammerBtn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(190, 115, 0)
	btnStroke.Thickness = 2
	btnStroke.Parent = hammerBtn

	hammerBtn.MouseButton1Click:Connect(function()
		hammerBtn.Size = UDim2.new(0, 128, 0, 38)
		task.wait(0.06)
		hammerBtn.Size = UDim2.new(0, 135, 0, 42)
		performHammerStrike()
	end)

	-- 4. Sol Alttaki Yükseltme Butonu (Parlama Yok, Net ve Okunabilir Siyah Yazı)
	local upgradeBtn = Instance.new("TextButton")
	upgradeBtn.Name = "UpgradeQuickButton"
	upgradeBtn.Size = UDim2.new(0, 320, 0, 68)
	upgradeBtn.Position = UDim2.new(0, 20, 1, -95)
	upgradeBtn.BackgroundColor3 = Color3.fromRGB(72, 235, 120)
	upgradeBtn.Text = "🔨 BİNAYI YÜKSELT\n[TIKLA!]"
	upgradeBtn.TextColor3 = Color3.fromRGB(20, 20, 20) -- SİYAH YAZI
	upgradeBtn.TextStrokeTransparency = 1 -- PARLAMA YOK
	upgradeBtn.Font = Enum.Font.FredokaOne
	upgradeBtn.TextSize = 15
	upgradeBtn.Parent = screenGui

	local upgCorner = Instance.new("UICorner")
	upgCorner.CornerRadius = UDim.new(0, 14)
	upgCorner.Parent = upgradeBtn

	local upgStroke = Instance.new("UIStroke")
	upgStroke.Color = Color3.fromRGB(20, 110, 45)
	upgStroke.Thickness = 3
	upgStroke.Parent = upgradeBtn

	-- Yükseltme Butonu Görünümünü ve Durumunu Güncelleyen Fonksiyon (Tüm yazılar SİYAH)
	local function updateButtonDisplay(level: number, plotIdx: number?)
		currentBuildingLevel = level
		if plotIdx then
			currentPlotIndex = plotIdx
			plotLevels[plotIdx] = level
		end

		if isUpgradingAnimating then return end

		local maxLevel = #GameConfig.BUILDINGS
		local nextLevel = level + 1
		local nextData = GameConfig.BUILDINGS[nextLevel]

		local leaderstats = localPlayer:FindFirstChild("leaderstats")
		local cashValue = leaderstats and (leaderstats:FindFirstChild(GameConfig.CURRENCY_NAME) or leaderstats:FindFirstChild("💰 Kasa ($)")) :: IntValue
		local currentCash = cashValue and cashValue.Value or 0

		if nextData then
			local pTypeData = ProjectTypeConfig.GetType(currentProjectType)
			local cost = math.floor(nextData.Cost * (pTypeData.CostMultiplier or 1.0))
			if currentCash >= cost then
				-- Yükseltmeye Hazır: Canlı Yeşil Kart, Net Siyah Yazı
				upgradeBtn.Text = string.format("🔨 YÜKSELT: %s (%s)\n[TIKLA & GELİŞTİR!]", nextData.Name, NumberFormat.FormatCash(cost))
				upgradeBtn.BackgroundColor3 = Color3.fromRGB(72, 235, 120)
				upgradeBtn.TextColor3 = Color3.fromRGB(20, 20, 20) -- SİYAH YAZI
				upgStroke.Color = Color3.fromRGB(20, 110, 45)
			else
				-- Yetersiz Kasa: Sıcak Krem/Açık Gri Kart, Net Koyu/Siyah Yazı (Göz yormaz)
				local missing = cost - currentCash
				upgradeBtn.Text = string.format("⏳ %s (%s)\n[Kasa: %s - %s Eksik]", nextData.Name, NumberFormat.FormatCash(cost), NumberFormat.FormatCash(currentCash), NumberFormat.FormatCash(missing))
				upgradeBtn.BackgroundColor3 = Color3.fromRGB(230, 222, 210)
				upgradeBtn.TextColor3 = Color3.fromRGB(30, 30, 30) -- SİYAH/KOYU YAZI
				upgStroke.Color = Color3.fromRGB(150, 140, 130)
			end
		else
			-- Maksimum Seviye (Gökdelen Tamamlandı): Canlı Gökyüzü Mavisi Kart, Net Siyah Yazı
			local nextPlotNumber = currentPlotIndex + 1
			local cost = GameConfig.GetPlotCost(nextPlotNumber)
			if currentCash >= cost then
				upgradeBtn.Text = string.format("🏢 %d. ŞANTİYEYİ AÇ! (%s)\n[TIKLA & PORTFÖYÜ BÜYÜT!]", nextPlotNumber, NumberFormat.FormatCash(cost))
				upgradeBtn.BackgroundColor3 = Color3.fromRGB(100, 220, 255)
				upgradeBtn.TextColor3 = Color3.fromRGB(20, 20, 20) -- SİYAH YAZI
				upgStroke.Color = Color3.fromRGB(20, 110, 160)
			else
				local missing = cost - currentCash
				upgradeBtn.Text = string.format("🏢 YENİ ŞANTİYE (%s)\n[Kasa: %s - %s Eksik]", NumberFormat.FormatCash(cost), NumberFormat.FormatCash(currentCash), NumberFormat.FormatCash(missing))
				upgradeBtn.BackgroundColor3 = Color3.fromRGB(225, 230, 235)
				upgradeBtn.TextColor3 = Color3.fromRGB(40, 50, 60) -- KOYU YAZI
				upgStroke.Color = Color3.fromRGB(140, 150, 160)
			end
		end
	end

	-- Yetersiz Kasa Durumunda Butonda Kırmızı Titreme (Shake) ve Siyah/Koyu Yazılı Uyarı
	local function triggerInsufficientCashFeedback(cost: number, currentCash: number)
		isUpgradingAnimating = true
		playSfx("rbxasset://sounds/electronicpingshort.wav", 0.4, 0.7)

		local missing = cost - currentCash
		upgradeBtn.Text = string.format("❌ YETERSİZ KASA!\n[%s Eksik]", NumberFormat.FormatCash(missing))
		upgradeBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 140)
		upgradeBtn.TextColor3 = Color3.fromRGB(30, 0, 0) -- KOYU/SİYAH YAZI
		upgStroke.Color = Color3.fromRGB(180, 30, 30)

		local origPos = UDim2.new(0, 20, 1, -95)
		task.spawn(function()
			for _ = 1, 3 do
				upgradeBtn.Position = UDim2.new(0, 28, 1, -95)
				task.wait(0.04)
				upgradeBtn.Position = UDim2.new(0, 12, 1, -95)
				task.wait(0.04)
			end
			upgradeBtn.Position = origPos
			task.wait(0.8)
			isUpgradingAnimating = false
			updateButtonDisplay(currentBuildingLevel, currentPlotIndex)
		end)
	end

	-- Yükseltme Butonuna Tıklama Olayı
	upgradeBtn.MouseButton1Click:Connect(function()
		upgradeBtn.Size = UDim2.new(0, 310, 0, 63)
		task.wait(0.06)
		upgradeBtn.Size = UDim2.new(0, 320, 0, 68)

		local leaderstats = localPlayer:FindFirstChild("leaderstats")
		local cashValue = leaderstats and (leaderstats:FindFirstChild(GameConfig.CURRENCY_NAME) or leaderstats:FindFirstChild("💰 Kasa ($)")) :: IntValue
		local currentCash = cashValue and cashValue.Value or 0

		local maxLevel = #GameConfig.BUILDINGS
		if currentBuildingLevel >= maxLevel then
			-- Yeni Şantiye Açma İsteği (Proje Türü Seçimi Modalı Açılır)
			local cost = GameConfig.GetPlotCost(currentPlotIndex + 1)
			if currentCash < cost then
				triggerInsufficientCashFeedback(cost, currentCash)
				return
			end
			playSfx("rbxasset://sounds/electronicpingshort.wav", 0.5, 1.2)
			Network.UnlockNextPlotEvent:FireServer()
		else
			-- Mevcut Şantiye Seviyesini Yükseltme İsteği
			local nextLevel = currentBuildingLevel + 1
			local nextData = GameConfig.BUILDINGS[nextLevel]
			if nextData then
				local pTypeData = ProjectTypeConfig.GetType(currentProjectType)
				local cost = math.floor(nextData.Cost * (pTypeData.CostMultiplier or 1.0))
				if currentCash < cost then
					triggerInsufficientCashFeedback(cost, currentCash)
					return
				end
				playSfx("rbxasset://sounds/electronicpingshort.wav", 0.5, 1.4)
				Network.PurchaseUpgradeEvent:FireServer(currentPlotIndex)
			end
		end
	end)

	-- Sunucudan Gelen Yükseltme Bildirimi
	Network.SyncBuildingEvent.OnClientEvent:Connect(function(newLevel, plotIdx, projectType)
		plotIdx = tonumber(plotIdx) or currentPlotIndex
		plotLevels[plotIdx] = newLevel
		if projectType then
			currentProjectType = projectType
		end

		local bData = GameConfig.BUILDINGS[newLevel]
		local bName = bData and bData.Name or "İnşaat"

		showUpgradeCelebration(newLevel, bName, plotIdx)
		updateButtonDisplay(newLevel, plotIdx)
	end)

	-- İlk Açılışta Aktif Şantiye Seviyesini Sunucudan Al
	task.spawn(function()
		local success, level, plotIdx, projectType = pcall(function()
			return Network.GetBuildingStatusFunction:InvokeServer()
		end)
		if success and level then
			if projectType then
				currentProjectType = projectType
			end
			updateButtonDisplay(level, plotIdx)
		end
	end)

	-- Kasa Değeri Değiştiğinde Butonu Anında Güncelle
	task.spawn(function()
		local leaderstats = localPlayer:WaitForChild("leaderstats", 10)
		if leaderstats then
			local cashValue = (leaderstats:WaitForChild(GameConfig.CURRENCY_NAME, 5) or leaderstats:WaitForChild("💰 Kasa ($)", 2)) :: IntValue
			if cashValue then
				cashValue.Changed:Connect(function()
					updateButtonDisplay(currentBuildingLevel, currentPlotIndex)
				end)
			end
		end
	end)

	-- Çoklu Şantiye Otomatik Algılama (Oyuncu 2. veya 3. şantiyeye yaklaşırsa o arsayı aktif yap)
	task.spawn(function()
		while true do
			task.wait(1.5)
			local char = localPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart
			if hrp then
				local closestPlotIdx = nil
				local minDistance = 80

				for _, child in ipairs(Workspace:GetChildren()) do
					if child.Name:match("^Plot_" .. localPlayer.Name .. "_(%d+)$") then
						local pIdx = tonumber(child.Name:match("^Plot_" .. localPlayer.Name .. "_(%d+)$"))
						local ground = child:FindFirstChild("PlotGround") :: BasePart
						if ground and pIdx then
							local dist = (hrp.Position - ground.Position).Magnitude
							if dist < minDistance then
								minDistance = dist
								closestPlotIdx = pIdx
							end
						end
					end
				end

				if closestPlotIdx and closestPlotIdx ~= currentPlotIndex then
					currentPlotIndex = closestPlotIdx
					local levelForPlot = plotLevels[closestPlotIdx] or 1
					updateButtonDisplay(levelForPlot, closestPlotIdx)
				end
			end
		end
	end)
end

-- HUD'ı hemen oluştur
createBuilderHUD()

-- Kullanıcı fareyle veya dokunarak vurduğunda çekiç vurma eylemi
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local character = localPlayer.Character
		local hasToolEquipped = character and character:FindFirstChildOfClass("Tool")
		if hasToolEquipped then
			performHammerStrike()
		end
	end
end)

-- Çekiç Aracını Dinleme (Güvenli, asla çökmez)
local function bindHammerTool(item: Instance)
	if item:IsA("Tool") and item.Name:find("İnşaat Çekici") then
		item.Activated:Connect(performHammerStrike)
	end
end

task.spawn(function()
	local backpack = localPlayer:WaitForChild("Backpack", 10)
	if backpack then
		for _, child in ipairs(backpack:GetChildren()) do
			bindHammerTool(child)
		end
		backpack.ChildAdded:Connect(bindHammerTool)
	end
end)

local function watchCharacter(char: Model)
	for _, child in ipairs(char:GetChildren()) do
		bindHammerTool(child)
	end
	char.ChildAdded:Connect(bindHammerTool)

	-- Kamerayı karaktere odakla
	local humanoid = char:WaitForChild("Humanoid", 5)
	if humanoid and Workspace.CurrentCamera then
		Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		Workspace.CurrentCamera.CameraSubject = humanoid
	end
end

if localPlayer.Character then
	watchCharacter(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(watchCharacter)

Network.SyncTurboStatusEvent.OnClientEvent:Connect(function(player, isTurbo, duration)
	if player == localPlayer and isTurbo then
		showTurboNotification(duration)
	end
end)

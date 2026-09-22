local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Network = require(ReplicatedStorage.Shared.Network)
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local function showWelcomeBackModal(data: { TimeAwaySeconds: number, CashEarned: number })
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WelcomeBackScreen"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Karartma Arka Planı
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.Parent = screenGui

	TweenService:Create(overlay, TweenInfo.new(0.4), { BackgroundTransparency = 0.5 }):Play()

	-- Ana Şantiye Kartı
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 440, 0, 330)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(255, 252, 245)
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = card

	-- Sarı-Siyah Şantiye Çerçevesi
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(245, 180, 0)
	stroke.Thickness = 4
	stroke.Parent = card

	-- Başlık
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.new(0, 0, 0, 15)
	title.BackgroundTransparency = 1
	title.Text = "🎉 TEKRAR HOŞ GELDİN!"
	title.TextColor3 = Color3.fromRGB(180, 100, 10)
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 26
	title.Parent = card

	-- Açıklama
	local minutes = math.floor(data.TimeAwaySeconds / 60)
	local seconds = data.TimeAwaySeconds % 60
	local timeString = minutes > 0 and string.format("%d dakika %d saniye", minutes, seconds) or string.format("%d saniye", seconds)

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(0.9, 0, 0, 50)
	desc.Position = UDim2.new(0.05, 0, 0, 65)
	desc.BackgroundTransparency = 1
	desc.Text = string.format("Sen yokken şantiyen +%d İP değerinde ilerleme kaydetti!\nGeçen Süre: %s", data.CashEarned, timeString)
	desc.TextColor3 = Color3.fromRGB(70, 70, 75)
	desc.Font = Enum.Font.GothamMedium
	desc.TextSize = 15
	desc.TextWrapped = true
	desc.Parent = card

	-- Kazanç Kutusu (Altın Sarısı)
	local rewardBox = Instance.new("Frame")
	rewardBox.Size = UDim2.new(0.85, 0, 0, 70)
	rewardBox.Position = UDim2.new(0.075, 0, 0, 125)
	rewardBox.BackgroundColor3 = Color3.fromRGB(255, 245, 210)
	rewardBox.BorderSizePixel = 0
	rewardBox.Parent = card

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 12)
	boxCorner.Parent = rewardBox

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = Color3.fromRGB(240, 170, 20)
	boxStroke.Thickness = 2
	boxStroke.Parent = rewardBox

	local rewardText = Instance.new("TextLabel")
	rewardText.Size = UDim2.new(1, 0, 1, 0)
	rewardText.BackgroundTransparency = 1
	rewardText.Text = string.format("+%d 💰", data.CashEarned)
	rewardText.TextColor3 = Color3.fromRGB(190, 110, 0)
	rewardText.Font = Enum.Font.FredokaOne
	rewardText.TextSize = 34
	rewardText.Parent = rewardBox

	-- Topla Butonu
	local collectButton = Instance.new("TextButton")
	collectButton.Size = UDim2.new(0.85, 0, 0, 55)
	collectButton.Position = UDim2.new(0.075, 0, 0, 215)
	collectButton.BackgroundColor3 = Color3.fromRGB(245, 150, 0)
	collectButton.Text = "HEPSİNİ TOPLA! 🏗️"
	collectButton.TextColor3 = Color3.fromRGB(20, 20, 20)
	collectButton.Font = Enum.Font.FredokaOne
	collectButton.TextSize = 20
	collectButton.BorderSizePixel = 0
	collectButton.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 12)
	btnCorner.Parent = collectButton

	-- Buton Tıklama ve Kapanma Animasyonu
	collectButton.MouseButton1Click:Connect(function()
		collectButton.Text = "KASAYA AKTARILDI! 🚀"
		collectButton.BackgroundColor3 = Color3.fromRGB(50, 180, 80)

		local popTween = TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
		})
		popTween:Play()
		TweenService:Create(overlay, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()

		popTween.Completed:Connect(function()
			screenGui:Destroy()
		end)
	end)

	-- Kart Açılış Animasyonu
	card.Size = UDim2.new(0, 50, 0, 50)
	TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 440, 0, 330),
	}):Play()
end

Network.ClaimOfflineEvent.OnClientEvent:Connect(function(data)
	showWelcomeBackModal(data)
end)

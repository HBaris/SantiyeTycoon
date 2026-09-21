local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local currentSeat: VehicleSeat? = nil
local currentCargo = 0

-- Hız Göstergesi ve Sürüş HUD'ı
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VehicleHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local hudCard = Instance.new("Frame")
hudCard.Name = "SpeedometerCard"
hudCard.Size = UDim2.new(0, 320, 0, 80)
hudCard.Position = UDim2.new(0.5, -160, 1, -170)
hudCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
hudCard.BackgroundTransparency = 0.05
hudCard.BorderSizePixel = 0
hudCard.Visible = false
hudCard.Parent = screenGui

local hCorner = Instance.new("UICorner")
hCorner.CornerRadius = UDim.new(0, 16)
hCorner.Parent = hudCard

local hStroke = Instance.new("UIStroke")
hStroke.Color = Color3.fromRGB(245, 175, 40)
hStroke.Thickness = 3
hStroke.Parent = hudCard

local speedText = Instance.new("TextLabel")
speedText.Name = "SpeedText"
speedText.Size = UDim2.new(0.45, 0, 0.6, 0)
speedText.Position = UDim2.new(0.05, 0, 0.1, 0)
speedText.BackgroundTransparency = 1
speedText.Text = "0 km/s"
speedText.TextColor3 = Color3.fromRGB(20, 20, 20)
speedText.Font = Enum.Font.FredokaOne
speedText.TextSize = 28
speedText.TextXAlignment = Enum.TextXAlignment.Left
speedText.Parent = hudCard

local infoText = Instance.new("TextLabel")
infoText.Name = "InfoText"
infoText.Size = UDim2.new(0.9, 0, 0.35, 0)
infoText.Position = UDim2.new(0.05, 0, 0.6, 0)
infoText.BackgroundTransparency = 1
infoText.Text = "W, A, S, D ile Sür | Boşluk (Space) ile İn"
infoText.TextColor3 = Color3.fromRGB(80, 80, 85)
infoText.Font = Enum.Font.GothamMedium
infoText.TextSize = 12
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.Parent = hudCard

local cargoBadge = Instance.new("TextLabel")
cargoBadge.Name = "CargoBadge"
cargoBadge.Size = UDim2.new(0.45, 0, 0.45, 0)
cargoBadge.Position = UDim2.new(0.5, 0, 0.12, 0)
cargoBadge.BackgroundColor3 = Color3.fromRGB(245, 240, 225)
cargoBadge.Text = "📦 Boş Kasa"
cargoBadge.TextColor3 = Color3.fromRGB(40, 40, 45)
cargoBadge.Font = Enum.Font.FredokaOne
cargoBadge.TextSize = 13
cargoBadge.Parent = hudCard
local cbCorner = Instance.new("UICorner")
cbCorner.CornerRadius = UDim.new(0, 8)
cbCorner.Parent = cargoBadge

local function bindCharacter(char: Model)
	local humanoid = char:WaitForChild("Humanoid", 10) :: Humanoid
	if not humanoid then return end

	humanoid.Seated:Connect(function(isSeated, seatPart)
		if isSeated and seatPart and seatPart:IsA("VehicleSeat") then
			currentSeat = seatPart
			hudCard.Visible = true
		else
			currentSeat = nil
			hudCard.Visible = false
		end
	end)
end

if localPlayer.Character then
	bindCharacter(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(bindCharacter)

-- Her karede hız ve durum güncellemesi
RunService.RenderStepped:Connect(function()
	if currentSeat and hudCard.Visible then
		local velocity = currentSeat.AssemblyLinearVelocity
		local speedKmh = math.floor(velocity.Magnitude * 2.2)
		speedText.Text = string.format("%d km/s", speedKmh)

		local model = currentSeat.Parent
		local vType = model and model:GetAttribute("VehicleType") or "Taşıt"
		infoText.Text = string.format("🎮 %s | W, A, S, D Sür | Space İn", vType)
	end
end)

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

local currentForwardSpeed = 0
local currentYaw: number? = nil

local function bindCharacter(char: Model)
	local humanoid = char:WaitForChild("Humanoid", 10) :: Humanoid
	if not humanoid then return end

	humanoid.Seated:Connect(function(isSeated, seatPart)
		if isSeated and seatPart and seatPart:IsA("VehicleSeat") then
			currentSeat = seatPart
			local model = seatPart.Parent
			local root = model and model.PrimaryPart or seatPart
			currentYaw = root.Orientation.Y
			currentForwardSpeed = 0
			hudCard.Visible = true
		else
			if currentSeat then
				local model = currentSeat.Parent
				local root = model and model.PrimaryPart or currentSeat
				if root then
					local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity
					if mover then
						mover.MaxForce = 0
						mover.VectorVelocity = Vector3.zero
					end
				end
			end
			currentSeat = nil
			currentForwardSpeed = 0
			currentYaw = nil
			hudCard.Visible = false
		end
	end)
end

if localPlayer.Character then
	bindCharacter(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(bindCharacter)

-- Fiziksel Sürüş ve Motor Döngüsü (Heartbeat)
RunService.Heartbeat:Connect(function(dt)
	if currentSeat and currentSeat.Occupant then
		local model = currentSeat.Parent
		local root = model and model.PrimaryPart or currentSeat
		if root then
			local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity
			local stabilizer = root:FindFirstChild("VehicleStabilizer") :: AlignOrientation

			local throttle = currentSeat.ThrottleFloat or 0
			local steer = currentSeat.SteerFloat or 0
			local maxSpeed = currentSeat.MaxSpeed or 28
			local torque = currentSeat.Torque or 20
			local turnSpeed = currentSeat.TurnSpeed or 2.5
			local accelRate = math.max(35, torque * 2.5)

			if throttle ~= 0 then
				currentForwardSpeed = math.clamp(currentForwardSpeed + (throttle * accelRate * dt), -maxSpeed * 0.45, maxSpeed)
			else
				-- Yavaşlama ve sürtünme
				if math.abs(currentForwardSpeed) > 1 then
					currentForwardSpeed = currentForwardSpeed - math.sign(currentForwardSpeed) * (accelRate * 1.6 * dt)
				else
					currentForwardSpeed = 0
				end
			end

			if not currentYaw then
				currentYaw = root.Orientation.Y
			end

			if math.abs(currentForwardSpeed) > 0.4 or throttle ~= 0 then
				local reverseFactor = (currentForwardSpeed < -0.1) and -1 or 1
				currentYaw = currentYaw - (steer * turnSpeed * 35 * reverseFactor * dt)
			end

			if stabilizer then
				stabilizer.CFrame = CFrame.Angles(0, math.rad(currentYaw), 0)
			end

			if mover then
				mover.MaxForce = 300000
				-- Negatif Z yönü Attachment0'a göre düz ileri yöndür
				mover.VectorVelocity = Vector3.new(0, 0, -currentForwardSpeed)
			end
		end
	else
		currentForwardSpeed = 0
		currentYaw = nil
	end
end)

-- Her karede HUD hız ve durum güncellemesi
RunService.RenderStepped:Connect(function()
	if currentSeat and hudCard.Visible then
		local velocity = currentSeat.AssemblyLinearVelocity
		local speedKmh = math.floor(velocity.Magnitude * 2.2)
		speedText.Text = string.format("%d km/s", speedKmh)

		local model = currentSeat.Parent
		local vType = model and model:GetAttribute("VehicleType") or "Taşıt"
		local effectiveCargo = model and model:GetAttribute("EffectiveCargo") or 15
		infoText.Text = string.format("🎮 %s (Maks: %d) | [G] Garaj | Space İn", vType, currentSeat.MaxSpeed)
		cargoBadge.Text = string.format("📦 Kasa: %d Kapasite", effectiveCargo)
	end
end)

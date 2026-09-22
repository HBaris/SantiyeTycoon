local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Network = require(ReplicatedStorage.Shared.Network)
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

	local function onSeated(isSeated, seatPart)
		if isSeated and seatPart and seatPart:IsA("VehicleSeat") then
			currentSeat = seatPart
			local model = seatPart.Parent
			local root = model and model.PrimaryPart or seatPart
			local flatLook = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
			if flatLook.Magnitude > 0.01 then
				flatLook = flatLook.Unit
				currentYaw = math.deg(math.atan2(-flatLook.X, -flatLook.Z))
			else
				currentYaw = root.Orientation.Y
			end
			currentForwardSpeed = 0
			local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity?
			if mover then
				mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
				mover.RelativeTo = Enum.ActuatorRelativeTo.World
				mover.LineDirection = root.CFrame.LookVector
				mover.LineVelocity = 0
				mover.MaxForce = 350000
			end
			hudCard.Visible = true
		else
			if currentSeat then
				local model = currentSeat.Parent
				local root = model and model.PrimaryPart or currentSeat
				if root then
					local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity
					if mover then
						mover.MaxForce = 0
						mover.LineVelocity = 0
					end
				end
			end
			currentSeat = nil
			currentForwardSpeed = 0
			currentYaw = nil
			hudCard.Visible = false
		end
	end

	humanoid.Seated:Connect(onSeated)

	-- Başlangıçta zaten oturuyorsa anında bağla
	if humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
		onSeated(true, humanoid.SeatPart)
	end
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

			-- Klavye W/A/S/D veya Yön Tuşları doğrudan okuma desteği (VehicleSeat odak kaybına karşı garanti)
			local uisThrottle = 0
			if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
				uisThrottle = 1
			elseif UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
				uisThrottle = -1
			end

			local uisSteer = 0
			if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
				uisSteer = 1
			elseif UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
				uisSteer = -1
			end

			local testThrottle = currentSeat:GetAttribute("TestThrottle")
			local testSteer = currentSeat:GetAttribute("TestSteer")
			local throttle = (currentSeat.ThrottleFloat ~= 0 and currentSeat.ThrottleFloat) or (testThrottle or uisThrottle)
			local steer = (currentSeat.SteerFloat ~= 0 and currentSeat.SteerFloat) or (testSteer or uisSteer)
			local maxSpeed = currentSeat.MaxSpeed or 28
			local torque = currentSeat.Torque or 20
			local turnSpeed = currentSeat.TurnSpeed or 2.5
			local accelRate = math.max(40, torque * 3.0)

			if throttle ~= 0 then
				currentForwardSpeed = math.clamp(currentForwardSpeed + (throttle * accelRate * dt), -maxSpeed * 0.5, maxSpeed)
			else
				-- Yavaşlama ve sürtünme frenlemesi
				if math.abs(currentForwardSpeed) > 1 then
					currentForwardSpeed = currentForwardSpeed - math.sign(currentForwardSpeed) * (accelRate * 1.8 * dt)
				else
					currentForwardSpeed = 0
				end
			end

			if not currentYaw then
				local flatLook = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
				if flatLook.Magnitude > 0.01 then
					flatLook = flatLook.Unit
					currentYaw = math.deg(math.atan2(-flatLook.X, -flatLook.Z))
				else
					currentYaw = root.Orientation.Y
				end
			elseif throttle == 0 and steer == 0 then
				-- Eğer araç dış bir etkenle veya ışınlanmayla aniden döndürülmüşse yaw'ı senkronize tut
				local flatLook = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
				if flatLook.Magnitude > 0.01 then
					local physicalYaw = math.deg(math.atan2(-flatLook.Unit.X, -flatLook.Unit.Z))
					local diff = (physicalYaw - currentYaw + 180) % 360 - 180
					if math.abs(diff) > 40 then
						currentYaw = physicalYaw
					end
				end
			end

			if math.abs(currentForwardSpeed) > 0.1 or throttle ~= 0 or steer ~= 0 then
				local reverseFactor = (currentForwardSpeed < -0.5) and -1 or 1
				currentYaw = currentYaw - (steer * turnSpeed * 45 * reverseFactor * dt)
			end

			-- Yüzey Normali ve Eğim Tespiti (Rampa, kasis ve yokuşları akıcı tırmanma)
			local char = localPlayer.Character
			local rayParams = RaycastParams.new()
			local ignoreList = { model }
			if char then table.insert(ignoreList, char) end
			rayParams.FilterDescendantsInstances = ignoreList
			rayParams.FilterType = Enum.RaycastFilterType.Exclude

			local ray = Workspace:Raycast(root.Position + Vector3.new(0, 1.5, 0), Vector3.new(0, -6.5, 0), rayParams)
			local normal = (ray and ray.Normal) or Vector3.new(0, 1, 0)
			if normal.Y < 0.5 then
				normal = Vector3.new(0, 1, 0) -- Dik duvarlara yapışmayı önle
			end

			local forwardHoriz = (CFrame.Angles(0, math.rad(currentYaw), 0) * Vector3.new(0, 0, -1)).Unit
			local tangentLook = (forwardHoriz - normal * forwardHoriz:Dot(normal)).Unit
			local tangentRight = tangentLook:Cross(normal).Unit

			if stabilizer then
				stabilizer.CFrame = CFrame.fromMatrix(root.Position, tangentRight, normal)
			end

			if mover then
				mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
				mover.RelativeTo = Enum.ActuatorRelativeTo.World
				mover.LineDirection = tangentLook
				mover.LineVelocity = currentForwardSpeed
				mover.MaxForce = 350000

				-- Yanal kaymayı sönümle (Gelişmiş yol tutuşu - savrulma ve buzda kaymayı önler)
				local curVel = root.AssemblyLinearVelocity
				local lateralSpeed = curVel:Dot(tangentRight)
				if math.abs(lateralSpeed) > 0.4 then
					local dampFactor = math.clamp(1 - (dt * 10), 0, 1)
					local forwardComp = curVel:Dot(tangentLook)
					local normalComp = curVel:Dot(normal)
					root.AssemblyLinearVelocity = (tangentLook * forwardComp) + (tangentRight * (lateralSpeed * dampFactor)) + (normal * normalComp)
				end
			end
		end
	else
		currentForwardSpeed = 0
		currentYaw = nil
	end
end)

-- Kargo Senkronizasyonu
Network.LoadCargoEvent.OnClientEvent:Connect(function(amount, cap)
	currentCargo = amount
	cargoBadge.Text = string.format("📦 Dolu: %d / %d", currentCargo, cap)
	cargoBadge.BackgroundColor3 = Color3.fromRGB(130, 245, 160)
end)

Network.DeliverCargoEvent.OnClientEvent:Connect(function()
	currentCargo = 0
	local cap = 15
	if currentSeat and currentSeat.Parent then
		cap = currentSeat.Parent:GetAttribute("EffectiveCargo") or 15
	end
	cargoBadge.Text = string.format("📦 Boş Kasa (0 / %d)", cap)
	cargoBadge.BackgroundColor3 = Color3.fromRGB(245, 240, 225)
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
		infoText.Text = string.format("🎮 %s (Maks: %d) | [G] Garaj | [E] Malzeme | Space İn", vType, currentSeat.MaxSpeed)
		if currentCargo > 0 then
			cargoBadge.Text = string.format("📦 Dolu: %d / %d", currentCargo, effectiveCargo)
			cargoBadge.BackgroundColor3 = Color3.fromRGB(130, 245, 160)
		else
			cargoBadge.Text = string.format("📦 Boş Kasa (0 / %d)", effectiveCargo)
			cargoBadge.BackgroundColor3 = Color3.fromRGB(245, 240, 225)
		end
	end
end)

-- Taşıt içerisindeyken E tuşu ile yakınındaki pad'e anında işlem yapma
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E and currentSeat and currentSeat.Occupant then
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		-- 1. Malzeme Yükleme İstasyonu Kontrolü (GarageFacility / IsCargoLoadingPad)
		local depotFolder = Workspace:FindFirstChild("GarageFacility") or Workspace:FindFirstChild("CentralGarageDepot")
		local loadPad = depotFolder and depotFolder:FindFirstChild("CargoLoadingPad") :: BasePart?
		if not loadPad then
			for _, desc in ipairs(Workspace:GetDescendants()) do
				if desc:IsA("BasePart") and desc:GetAttribute("IsCargoLoadingPad") then
					loadPad = desc
					break
				end
			end
		end
		if loadPad and (hrp.Position - loadPad.Position).Magnitude <= 32 then
			Network.LoadCargoEvent:FireServer()
			return
		end

		-- 2. Kargo Boşaltma İstasyonu Kontrolü (Şantiyedeki kargo teslim pad'i)
		for _, desc in ipairs(Workspace:GetDescendants()) do
			if desc:IsA("BasePart") and desc.Name == "CargoUnloadPad" then
				if (hrp.Position - desc.Position).Magnitude <= 32 then
					local plotIdx = desc:GetAttribute("PlotIndex") or 1
					Network.DeliverCargoEvent:FireServer(plotIdx)
					return
				end
			end
		end
	end
end)

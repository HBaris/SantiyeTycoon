--!strict
-- ============================================================================
-- CustomizerCameraController.luau
-- 🚁 360 Derece Kuş Bakışı Tasarım & İnşaat Kamerası (Top-Down Orbit Camera)
-- Sağ Tık / Q-E / Arayüz Butonları ile 360° Dönüş, Zoom ve Parsel İçi Gezinme
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera") :: Camera
local localPlayer = Players.LocalPlayer

local CustomizerCameraController = {}

local isEnabled = false
local centerPoint = Vector3.new(0, 4.4, 0)
local panOffset = Vector3.new(0, 0, 0)

-- Yörünge Parametreleri (Radyan)
local currentYaw = math.rad(180) -- 0-360 derece kesintisiz yörünge
local targetYaw = math.rad(180)
local currentPitch = math.rad(55) -- 55 derece kuş bakışı
local targetPitch = math.rad(55)
local currentDistance = 70.0 -- Odak noktasına uzaklık
local targetDistance = 70.0

-- Sınırlar
local MIN_PITCH = math.rad(25)
local MAX_PITCH = math.rad(80)
local MIN_DIST = 30.0
local MAX_DIST = 135.0
local MAX_PAN_RADIUS = 32.0

-- Fare Etkileşimi
local isRightMouseDown = false
local lastMousePos = Vector2.new(0, 0)

-- Klavye Pan Hareketi
local moveKeys = {
	[Enum.KeyCode.W] = false,
	[Enum.KeyCode.S] = false,
	[Enum.KeyCode.A] = false,
	[Enum.KeyCode.D] = false,
	[Enum.KeyCode.Q] = false,
	[Enum.KeyCode.E] = false,
}

local renderConn: RBXScriptConnection? = nil
local inputBeganConn: RBXScriptConnection? = nil
local inputChangedConn: RBXScriptConnection? = nil
local inputEndedConn: RBXScriptConnection? = nil

local savedWalkSpeed = 16.0
local savedJumpPower = 50.0

local function updateCamera(dt: number)
	if not isEnabled then return end

	-- Klavye sürekli Q/E dönüşü
	if moveKeys[Enum.KeyCode.Q] then
		targetYaw += math.rad(75) * dt
	end
	if moveKeys[Enum.KeyCode.E] then
		targetYaw -= math.rad(75) * dt
	end

	-- Klavye WASD Pan Hareketi (Kamera açısına göre yönlendirilmiş)
	local panSpeed = 35.0
	local forward = Vector3.new(-math.sin(currentYaw), 0, -math.cos(currentYaw))
	local right = Vector3.new(math.cos(currentYaw), 0, -math.sin(currentYaw))
	local moveDir = Vector3.zero

	if moveKeys[Enum.KeyCode.W] then moveDir += forward end
	if moveKeys[Enum.KeyCode.S] then moveDir -= forward end
	if moveKeys[Enum.KeyCode.D] then moveDir += right end
	if moveKeys[Enum.KeyCode.A] then moveDir -= right end

	if moveDir.Magnitude > 0 then
		panOffset += moveDir.Unit * panSpeed * dt
		-- Parsel sınırlarında tut
		local pX = math.clamp(panOffset.X, -MAX_PAN_RADIUS, MAX_PAN_RADIUS)
		local pZ = math.clamp(panOffset.Z, -MAX_PAN_RADIUS, MAX_PAN_RADIUS)
		panOffset = Vector3.new(pX, 0, pZ)
	end

	-- Pürüzsüz İnterpolasyon (Lerp)
	local lerpAlpha = math.clamp(dt * 12, 0.01, 1.0)
	currentYaw += (targetYaw - currentYaw) * lerpAlpha
	currentPitch += (targetPitch - currentPitch) * lerpAlpha
	currentDistance += (targetDistance - currentDistance) * lerpAlpha

	-- Kamera CFrame Hesaplama (Küresel Orbit)
	local effectiveCenter = centerPoint + panOffset
	local rotCF = CFrame.Angles(0, currentYaw, 0) * CFrame.Angles(-currentPitch, 0, 0)
	local camOffset = rotCF * Vector3.new(0, 0, currentDistance)
	local camPos = effectiveCenter + camOffset

	Camera.CFrame = CFrame.lookAt(camPos, effectiveCenter)
end

function CustomizerCameraController.Enable(plotOrigin: Vector3)
	if isEnabled then return end
	isEnabled = true

	centerPoint = plotOrigin + Vector3.new(0, 2.5, 0)
	panOffset = Vector3.new(0, 0, 0)
	targetYaw = math.rad(180)
	currentYaw = math.rad(180)
	targetPitch = math.rad(55)
	currentPitch = math.rad(55)
	targetDistance = 68.0
	currentDistance = 68.0

	-- Karakteri güvenliğe al (Kuş bakışındayken savrulmaması için)
	local char = localPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			savedWalkSpeed = hum.WalkSpeed
			savedJumpPower = hum.JumpPower
			hum.WalkSpeed = 0
			hum.JumpPower = 0
		end
	end

	Camera.CameraType = Enum.CameraType.Scriptable

	-- Render Döngüsü
	renderConn = RunService.RenderStepped:Connect(updateCamera)

	-- Input Dinleyicileri
	inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			isRightMouseDown = true
			lastMousePos = UserInputService:GetMouseLocation()
		elseif not gameProcessed then
			if moveKeys[input.KeyCode] ~= nil then
				moveKeys[input.KeyCode] = true
			end
		end
	end)

	inputEndedConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			isRightMouseDown = false
		elseif moveKeys[input.KeyCode] ~= nil then
			moveKeys[input.KeyCode] = false
		end
	end)

	inputChangedConn = UserInputService.InputChanged:Connect(function(input, gameProcessed)
		-- Sağ Tık Sürükleme ile 360° Yörünge Dönüşü ve Eğim
		if input.UserInputType == Enum.UserInputType.MouseMovement and isRightMouseDown then
			local currentPos = UserInputService:GetMouseLocation()
			local delta = currentPos - lastMousePos
			lastMousePos = currentPos

			local sens = 0.0055
			targetYaw -= delta.X * sens
			targetPitch = math.clamp(targetPitch + delta.Y * sens, MIN_PITCH, MAX_PITCH)

		-- Fare Tekerleği ile Yakınlaşma / Uzaklaşma (Zoom)
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			local zoomSpeed = 7.0
			targetDistance = math.clamp(targetDistance - (input.Position.Z * zoomSpeed), MIN_DIST, MAX_DIST)
		end
	end)

	print("🚁 [CustomizerCameraController] 360° Kuş Bakışı Kamera Aktif.")
end

function CustomizerCameraController.Disable()
	if not isEnabled then return end
	isEnabled = false

	if renderConn then renderConn:Disconnect(); renderConn = nil end
	if inputBeganConn then inputBeganConn:Disconnect(); inputBeganConn = nil end
	if inputChangedConn then inputChangedConn:Disconnect(); inputChangedConn = nil end
	if inputEndedConn then inputEndedConn:Disconnect(); inputEndedConn = nil end

	-- Karakter kontrollerini geri ver
	local char = localPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = savedWalkSpeed > 0 and savedWalkSpeed or 16
			hum.JumpPower = savedJumpPower > 0 and savedJumpPower or 50
		end
	end

	-- Kamerayı normal oyuncu takibine döndür
	Camera.CameraType = Enum.CameraType.Custom
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		Camera.CameraSubject = hum
	end

	print("🚁 [CustomizerCameraController] Standart Oyuncu Kamerasına Dönüldü.")
end

-- Dış Arayüz / Buton Kontrol Metotları
function CustomizerCameraController.RotateLeft(deg: number?)
	local amount = math.rad(deg or 45)
	targetYaw += amount
end

function CustomizerCameraController.RotateRight(deg: number?)
	local amount = math.rad(deg or 45)
	targetYaw -= amount
end

function CustomizerCameraController.ZoomIn(studs: number?)
	targetDistance = math.clamp(targetDistance - (studs or 12), MIN_DIST, MAX_DIST)
end

function CustomizerCameraController.ZoomOut(studs: number?)
	targetDistance = math.clamp(targetDistance + (studs or 12), MIN_DIST, MAX_DIST)
end

function CustomizerCameraController.ResetCenter()
	panOffset = Vector3.new(0, 0, 0)
	targetDistance = 68.0
	targetPitch = math.rad(55)
end

function CustomizerCameraController.GetYaw(): number
	return math.deg(currentYaw) % 360
end

function CustomizerCameraController.IsEnabled(): boolean
	return isEnabled
end

return CustomizerCameraController
